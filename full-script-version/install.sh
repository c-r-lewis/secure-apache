#!/bin/bash

# Source the config.env file to load environment variables
source ./config.env

# Variables
SITE1_DOMAIN="site1.local"
SITE2_DOMAIN="site2.local"
PHP_DOMAIN="phpmyadmin.local"

# Function to install Apache
install_apache() {
    echo "Installing Apache..."
    sudo apt-get update
    sudo apt-get install -y apache2 apache2-bin apache2-data libapache2-mod-security2 php-mysql php libapache2-mod-php
    sudo apt-get clean

    # Configure timezone
    sudo ln -snf /usr/share/zoneinfo/Europe/Paris /etc/localtime
    echo "Europe/Paris" | sudo tee /etc/timezone

    # Enable necessary modules
    sudo a2enmod ssl
    sudo a2enmod headers
    sudo a2enmod rewrite
    sudo a2enmod security2
    sudo a2enmod proxy proxy_http proxy_fcgi

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

    # Create the .htpasswd file if necessary
    if [ ! -f /etc/apache2/.htpasswd ]; then
        echo "Creating .htpasswd..."
        sudo htpasswd -cb /etc/apache2/.htpasswd ${HTPASSWD_USER} ${HTPASSWD_PASS}
    fi

    # Test Apache configuration before starting it
    echo "Testing Apache configuration..."
    sudo apache2ctl configtest

    # Start Apache
    echo "Starting Apache..."
    sudo systemctl restart apache2
}

# Function to install MySQL
install_mysql() {
    echo "Installing MySQL..."
    sudo apt-get update
    sudo apt-get install -y mysql-server
    sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${MYSQL_ROOT_PASSWORD}'; FLUSH PRIVILEGES;"
    sudo systemctl restart mysql
}

# Function to install phpMyAdmin
install_phpmyadmin() {
    echo "Installing phpMyAdmin..."
    sudo apt-get update
    sudo apt-get install -y phpmyadmin
    sudo phpenmod mbstring
    sudo systemctl restart apache2

    # Configure phpMyAdmin
    sudo mysql -e "CREATE DATABASE phpmyadmin DEFAULT CHARACTER SET utf8 COLLATE utf8_bin;"
    sudo mysql -e "GRANT ALL PRIVILEGES ON phpmyadmin.* TO 'pma'@'localhost' IDENTIFIED BY '${PHP_MYADMIN_PASSWORD}';"
    sudo mysql -e "FLUSH PRIVILEGES;"
}

# Function to update /etc/hosts
update_hosts_file() {
    echo "Updating /etc/hosts file..."
    LOCAL_IP=$(hostname -I | awk '{print $1}')
    sudo sed -i "/$SITE1_DOMAIN/d" /etc/hosts
    sudo sed -i "/$SITE2_DOMAIN/d" /etc/hosts
    sudo sed -i "/$PHP_DOMAIN/d" /etc/hosts
    echo "$LOCAL_IP $SITE1_DOMAIN $SITE2_DOMAIN $PHP_DOMAIN" | sudo tee -a /etc/hosts
}

# Main script
main() {
    install_apache
    install_mysql
    install_phpmyadmin
    update_hosts_file
    echo "Script completed successfully."
}

# Run the main script
main
