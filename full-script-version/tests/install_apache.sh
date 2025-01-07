#!/bin/bash

install_apache() {
    echo "--------------------------------------------------"
    echo "Starting simple Apache installation..."
    echo "--------------------------------------------------"

    sudo mkdir -p /var/lib/phpmyadmin
    sudo touch /var/lib/phpmyadmin/blowfish_secret.inc.php
    sudo chmod 660 /var/lib/phpmyadmin/blowfish_secret.inc.php


    # Update package lists
    sudo apt update -y

    # Install Apache2
    sudo apt install -y apache2

    # Enable Apache to start on boot
    sudo systemctl enable apache2

    # Start Apache service
    sudo systemctl start apache2

    # Check Apache status
    sudo systemctl status apache2

    echo "--------------------------------------------------"
    echo "Apache installation and setup complete."
    echo "--------------------------------------------------"
}

install_apache
