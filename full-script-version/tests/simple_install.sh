#!/bin/bash

# Exit on any error
set -e

echo "Updating package list and upgrading system..."
sudo apt update && sudo apt upgrade -y

echo "Installing MySQL Server..."
sudo apt install -y mysql-server

echo "Securing MySQL installation..."
sudo mysql_secure_installation

echo "Installing Apache and PHP..."
sudo apt install -y apache2 php libapache2-mod-php php-mysql

echo "Installing phpMyAdmin..."
sudo apt install -y phpmyadmin

echo "Enabling required Apache modules..."
sudo a2enmod php7.4 # Adjust this version if necessary
sudo systemctl restart apache2

echo "Checking status of Apache and MySQL..."
sudo systemctl status apache2
sudo systemctl status mysql

echo "Installation completed. You can access phpMyAdmin at http://localhost/phpmyadmin."
