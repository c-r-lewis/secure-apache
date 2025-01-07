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
    sudo apt-get update
    sudo apt-get install -y apache2 apache2-utils ssl-cert

    # Ensure Apache2 utilities are installed
    sudo apt-get install -y apache2-bin

    # Enable necessary modules
    sudo a2enmod ssl
    sudo a2enmod headers
    sudo a2enmod rewrite
    sudo a2enmod security
    sudo a2enmod proxy proxy_http proxy_fcgi

    # Ensure SSL certificate file exists
    if [ ! -f /etc/ssl/certs/ssl-cert-snakeoil.pem ]; then
        echo "SSL certificate file does not exist. Generating it..."
        sudo mkdir -p /etc/ssl/private
        sudo chmod 700 /etc/ssl/private
        sudo make-ssl-cert generate-default-snakeoil --force-overwrite
    fi

    # Copy configuration files
    sudo cp ./config/apache2.conf /etc/apache2/apache2.conf
    sudo cp ./config/ports.conf /etc/apache2/ports.conf
    sudo cp ./config/000-default.conf /etc/apache2/sites-available/000-default.conf
    sudo cp ./config/default-ssl.conf /etc/apache2/sites-available/default-ssl.conf
    sudo cp ./config/site1.conf /etc/apache2/sites-available/site1.conf
    sudo cp ./config/site2.conf /etc/apache2/sites-available/site2.conf
    sudo cp ./config/database.conf /etc/apache2/sites-available/database.conf
    sudo cp ./config/database.conf /etc/apache2/sites-available/database.conf
    sudo cp ./config/.htaccess /var/www/html/.htaccess

    # Copy site files
    sudo cp -r ./html/site1 /var/www/site1
    sudo cp -r ./html/site2 /var/www/site2

    # Enable sites
    sudo a2ensite site1.conf
    sudo a2ensite site2.conf
    sudo a2ensite database.conf
    sudo a2ensite database.conf
    sudo a2ensite 000-default.conf
    sudo a2ensite default-ssl.conf

    # Reload systemd manager configuration
    sudo systemctl daemon-reload

    # Reload systemd manager configuration
    sudo systemctl daemon-reload

    # Create .htpasswd file non-interactively
    echo "Creating .htpasswd..."
    if [ ! -f /etc/apache2/.htpasswd ]; then
        echo "admin:adminpassword" | sudo htpasswd -bc /etc/apache2/.htpasswd admin adminpassword
    else
        echo "admin:adminpassword" | sudo htpasswd -b /etc/apache2/.htpasswd admin adminpassword
    fi

    # Test Apache configuration
    echo "Testing Apache configuration..."
    sudo apache2ctl configtest

    # Start Apache
    echo "Starting Apache..."
    sudo systemctl reload apache2
    sudo systemctl reload apache2
    sudo systemctl restart apache2
}


# Function to install MySQL
install_mysql() {
    echo "Installing MySQL..."
    wait_for_lock
    sudo apt-get install -y mysql-server
    sudo systemctl start mysql
}

# Function to install phpMyAdmin
install_phpmyadmin() {
    echo 'Not completed'
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
    install_mysql
    #install_phpmyadmin
    update_hosts_file
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
check_already_installed

# Run the main script
if [ "$SILENT_MODE" = true ]; then
    (main >> "$LOG_FILE" 2>&1) &
    progress_bar $!
else
    main 2>&1 | tee -a "$LOG_FILE"
fi
