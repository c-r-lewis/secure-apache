#!/bin/bash

# Source the config.env file to load environment variables
source ./config.env

# Variables
SITE1_DOMAIN="site1.local"
SITE2_DOMAIN="site2.local"
PHP_DOMAIN="phpmyadmin.local"

# Function to uninstall Apache
uninstall_apache() {
    echo "Uninstalling Apache..."
    sudo systemctl stop apache2 --quiet
    sudo apt-get remove --purge -y apache2 apache2-bin apache2-data libapache2-mod-security2 php-mysql php libapache2-mod-php
    sudo apt-get autoremove -y
    sudo apt-get clean

    # Remove Apache configuration files
    sudo rm -rf /etc/apache2/sites-available/site1.conf
    sudo rm -rf /etc/apache2/sites-available/site2.conf
    sudo rm -rf /etc/apache2/sites-available/phpmyadmin.conf
    sudo rm -rf /etc/apache2/sites-available/000-default.conf
    sudo rm -rf /etc/apache2/sites-available/default-ssl.conf
    sudo rm -rf /etc/apache2/.htpasswd
    sudo rm -rf /var/www/site1
    sudo rm -rf /var/www/site2

    echo "Apache uninstalled successfully."
}

# Function to uninstall MySQL
uninstall_mysql() {
    echo "Uninstalling MySQL..."
    sudo systemctl stop mysql --quiet
    sudo apt-get remove --purge -y mysql-server
    sudo apt-get autoremove -y
    sudo apt-get clean

    # Remove MySQL data directory
    sudo rm -rf /var/lib/mysql

    echo "MySQL uninstalled successfully."
}

# Function to uninstall phpMyAdmin
uninstall_phpmyadmin() {
    echo "Uninstalling phpMyAdmin..."
    export DEBIAN_FRONTEND=noninteractive
    sudo apt-get remove --purge -y phpmyadmin
    sudo apt-get autoremove -y
    sudo apt-get clean

    echo "phpMyAdmin uninstalled successfully."
}

# Function to update /etc/hosts
update_hosts_file() {
    echo "Updating /etc/hosts file..."
    sudo sed -i -s "/$SITE1_DOMAIN/d" /etc/hosts
    sudo sed -i -s "/$SITE2_DOMAIN/d" /etc/hosts
    sudo sed -i -s "/$PHP_DOMAIN/d" /etc/hosts

    echo "/etc/hosts file updated successfully."
}

# Main script
main() {
    uninstall_apache
    uninstall_mysql
    uninstall_phpmyadmin
    update_hosts_file
    echo "Uninstall script completed successfully."
}

# Run the main script
main
