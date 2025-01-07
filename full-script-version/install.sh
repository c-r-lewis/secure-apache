#!/bin/bash

# Source the config.env file to load environment variables
source ./config.env

# Variables
SITE1_DOMAIN="site1.local"
SITE2_DOMAIN="site2.local"
PHP_DOMAIN="phpmyadmin.local"
LOG_FILE="installation_log.txt"
SILENT_MODE=false
CLEAR_LOG=false

progress_bar() {
    local pid=$1
    local delay=0.5
    local width=100
    local char="-"
    local progress=0

    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local progress=$((progress + 1))
        local bar=$(printf "%-${width}s" | tr ' ' "$char")
        echo -ne "\rProgress: [${bar:0:$((progress % (width + 1)))}]"
        sleep $delay
    done
    echo # Move to the next line
    echo "Everything is installed!"
}

# Function to forcefully release dpkg lock
force_release_lock() {
    echo "Forcefully releasing dpkg lock..."
    sudo rm -f /var/lib/dpkg/lock-frontend
    sudo rm -f /var/lib/dpkg/lock
    sudo rm -f /var/cache/apt/archives/lock
    sudo dpkg --configure -a
    sudo apt-get update
}

# Function to wait for dpkg lock to be released
wait_for_lock() {
    for i in {1..10}; do
        if ! sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; then
            return 0
        fi
        echo "Waiting for dpkg lock to be released... ($i/10)"
        sleep 5
    done
    echo "dpkg lock not released. Forcefully releasing..."
    force_release_lock
}

# Function to install Apache
install_apache() {
    echo "Installing Apache..."
    wait_for_lock

    # Update package list and install required packages
    sudo apt-get update
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y apache2 apache2-utils ssl-cert apache2-bin

    # Enable necessary Apache modules
    sudo a2enmod ssl headers rewrite proxy proxy_http proxy_fcgi

    # Ensure SSL certificate exists
    if [ ! -f /etc/ssl/certs/ssl-cert-snakeoil.pem ]; then
        echo "SSL certificate file does not exist. Generating it..."
        sudo make-ssl-cert generate-default-snakeoil --force-overwrite
    fi

    # Copy configuration files
    echo "Copying configuration files..."
    CONFIG_DIR="./config"
    SITE_DIR="./html"
    if [ -d "$CONFIG_DIR" ]; then
        sudo cp "$CONFIG_DIR/apache2.conf" /etc/apache2/apache2.conf
        sudo cp "$CONFIG_DIR/ports.conf" /etc/apache2/ports.conf
        sudo cp "$CONFIG_DIR/000-default.conf" /etc/apache2/sites-available/000-default.conf
        sudo cp "$CONFIG_DIR/default-ssl.conf" /etc/apache2/sites-available/default-ssl.conf
        sudo cp "$CONFIG_DIR/site1.conf" /etc/apache2/sites-available/site1.conf
        sudo cp "$CONFIG_DIR/site2.conf" /etc/apache2/sites-available/site2.conf
        sudo cp "$CONFIG_DIR/database.conf" /etc/apache2/sites-available/database.conf
        sudo cp "$CONFIG_DIR/.htaccess" /var/www/html/.htaccess
    else
        echo "Configuration directory $CONFIG_DIR not found!"
        exit 1
    fi

    # Copy site files
    echo "Copying site files..."
    if [ -d "$SITE_DIR" ]; then
        sudo cp -r "$SITE_DIR/site1" /var/www/site1
        sudo cp -r "$SITE_DIR/site2" /var/www/site2
    else
        echo "Site directory $SITE_DIR not found!"
        exit 1
    fi

    # Ensure log directory exists
    sudo mkdir -p /var/log/apache2
    sudo chown www-data:www-data /var/log/apache2

    # Enable sites
    echo "Enabling Apache sites..."
    sudo a2ensite 000-default.conf default-ssl.conf site1.conf site2.conf database.conf

    # Reload systemd configuration and restart Apache
    echo "Reloading systemd configuration and restarting Apache..."
    sudo systemctl daemon-reload
    sudo systemctl restart apache2

    # Create .htpasswd file non-interactively
    echo "Creating .htpasswd..."
    HTPASSWD_FILE="/etc/apache2/.htpasswd"
    if [ ! -f "$HTPASSWD_FILE" ]; then
        sudo htpasswd -bc "$HTPASSWD_FILE" admin adminpassword
    else
        sudo htpasswd -b "$HTPASSWD_FILE" admin adminpassword
    fi

    # Test Apache configuration
    echo "Testing Apache configuration..."
    if ! sudo apache2ctl configtest; then
        echo "Apache configuration test failed. Please review the configuration files."
        exit 1
    fi

    # Reload Apache to apply changes
    echo "Reloading Apache to apply changes..."
    sudo systemctl reload apache2

    echo "Apache installation and configuration completed successfully."
}


# Function to install PHP
install_php() {
    echo "Installing PHP..."
    wait_for_lock
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y php libapache2-mod-php php-mysql
    sudo systemctl restart apache2
}

# Function to install phpMyAdmin
install_phpmyadmin() {
    echo "Installing phpMyAdmin..."
    wait_for_lock
    sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/dbconfig-install boolean true"
    sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/app-password-confirm password adminpassword"
    sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/admin-pass password adminpassword"
    sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/app-pass password adminpassword"
    sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2"
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y phpmyadmin
    sudo phpenmod mbstring
    sudo systemctl restart apache2
}

# Function to update /etc/hosts
update_hosts_file() {
    echo "Updating /etc/hosts file..."
    sudo sed -i "/$SITE1_DOMAIN/d" /etc/hosts
    sudo sed -i "/$SITE2_DOMAIN/d" /etc/hosts
    sudo sed -i "/$PHP_DOMAIN/d" /etc/hosts
    echo "127.0.0.1 $SITE1_DOMAIN $SITE2_DOMAIN $PHP_DOMAIN" | sudo tee -a /etc/hosts
    echo "/etc/hosts file updated successfully."
}

is_installed() {
    dpkg -l | grep -q "$1"
}

check_already_installed() {
    # Check if Apache is already installed
    if is_installed "apache2"; then
        echo "Apache is already installed. Please run the uninstallation script first."
        exit 1
    fi

    # Check if MySQL is already installed
    if is_installed "mysql-server"; then
        echo "Mysql is already installed. Please run the uninstallation script first."
        exit 1
    fi

    # Check if phpMyAdmin is already installed
    if is_installed "phpmyadmin"; then
        echo "At least one of the apps is already installed. Please run the uninstallation script first."
        exit 1
    fi
}

# Main script
main() {
    # Add a separator line if the -c option is not set
    echo "--------------------------------------------------"
    echo "Starting new installation at $(date)"
    echo "--------------------------------------------------"

    install_apache
    #install_php
    #install_phpmyadmin
    #install_mysql
    #update_hosts_file
    echo "Install script completed successfully."
}

# Parse command-line options
while getopts "sc" opt; do
  case ${opt} in
    s )
      SILENT_MODE=true
      ;;
    c )
      CLEAR_LOG=true
      ;;
    \? )
      echo "Usage: $0 [-s] [-c]"
      exit 1
      ;;
  esac
done

# Clear the log file if the -c option is set
if [ "$CLEAR_LOG" = true ]; then
    > "$LOG_FILE"
fi

# Run installation checks
#check_already_installed

# Run the main script
if [ "$SILENT_MODE" = true ]; then
    (main >> "$LOG_FILE" 2>&1) &
    progress_bar $!
else
    main 2>&1 | tee -a "$LOG_FILE"
fi
