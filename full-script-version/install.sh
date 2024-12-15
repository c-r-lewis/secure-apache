#!/bin/bash

# Source the config.env file to load environment variables
source ./config.env

# Variables
SITE1_DOMAIN="site1.local"
SITE2_DOMAIN="site2.local"
PHP_DOMAIN="phpmyadmin.local"

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
    sudo cp ./config/phpmyadmin.conf /etc/apache2/sites-available/phpmyadmin.conf
    sudo cp ./config/.htaccess /var/www/html/.htaccess

    # Copy site files
    sudo cp -r ./html/site1 /var/www/site1
    sudo cp -r ./html/site2 /var/www/site2

    # Enable sites
    sudo a2ensite site1.conf
    sudo a2ensite site2.conf
    sudo a2ensite phpmyadmin.conf
    sudo a2ensite 000-default.conf
    sudo a2ensite default-ssl.conf

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
    echo "Installing phpMyAdmin..."
    wait_for_lock
    export DEBIAN_FRONTEND=noninteractive
    sudo apt-get install -y phpmyadmin
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

# Main script
main() {
    install_apache
    install_mysql
    install_phpmyadmin
    update_hosts_file
    echo "Install script completed successfully."
}

# Run the main script
main
