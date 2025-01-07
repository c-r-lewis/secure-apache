#!/bin/bash

# Update the system
echo "Updating the system..."
sudo apt update -y
sudo apt upgrade -y

# Install required packages
echo "Installing Apache, PHP, and MySQL..."
sudo apt install -y apache2 php libapache2-mod-php php-mysql mysql-server unzip

# Secure MySQL installation
echo "Securing MySQL installation..."
sudo mysql_secure_installation <<EOF

Y
yourpassword
yourpassword
Y
Y
Y
Y
EOF

# Create a database and user for phpMyAdmin
echo "Creating database and user for phpMyAdmin..."
sudo mysql -u root -pyourpassword <<EOF
CREATE DATABASE phpmyadmin;
CREATE USER 'phpmyadminuser'@'localhost' IDENTIFIED BY 'yourpassword';
GRANT ALL PRIVILEGES ON phpmyadmin.* TO 'phpmyadminuser'@'localhost';
FLUSH PRIVILEGES;
EXIT;
EOF

# Download phpMyAdmin
echo "Downloading phpMyAdmin..."
cd /tmp
wget https://files.phpmyadmin.net/phpMyAdmin/5.2.0/phpMyAdmin-5.2.0-all-languages.zip

# Extract the archive
echo "Extracting phpMyAdmin..."
unzip phpMyAdmin-5.2.0-all-languages.zip

# Move phpMyAdmin to the web directory
echo "Moving phpMyAdmin to the web directory..."
sudo mv phpMyAdmin-5.2.0-all-languages /usr/share/phpmyadmin

# Configure phpMyAdmin
echo "Configuring phpMyAdmin..."
sudo mv /usr/share/phpmyadmin/config.sample.inc.php /usr/share/phpmyadmin/config.inc.php
sudo chmod 660 /usr/share/phpmyadmin/config.inc.php
sudo chown -R www-data:www-data /usr/share/phpmyadmin

# Edit the configuration file
echo "Editing the configuration file..."
sudo sed -i 's/\$cfg\['\''Servers'\''\]\[$i\]\['\''auth_type'\''\]\s*=\s*'\''cookie'\''\;/&\n\$cfg\['\''Servers'\''\]\[$i\]\['\''host'\''\]\s*=\s*'\''localhost'\''\; \n\$cfg\['\''Servers'\''\]\[$i\]\['\''connect_type'\''\]\s*=\s*'\''tcp'\''\; \n\$cfg\['\''Servers'\''\]\[$i\]\['\''compress'\''\]\s*=\s*false\; \n\$cfg\['\''Servers'\''\]\[$i\]\['\''AllowNoPassword'\''\]\s*=\s*false\;/' /usr/share/phpmyadmin/config.inc.php

# Create a symbolic link
echo "Creating a symbolic link..."
sudo ln -s /usr/share/phpmyadmin /var/www/html/phpmyadmin

# Restart Apache
echo "Restarting Apache..."
sudo systemctl restart apache2

echo "phpMyAdmin installation completed. Access it at http://your_server_ip/phpmyadmin"
