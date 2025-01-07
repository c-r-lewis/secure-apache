#!/bin/bash

# Source the config.env file to load environment variables
source ./config.env

# Variables
SITE1_DOMAIN="site1.local"
SITE2_DOMAIN="site2.local"
PHP_DOMAIN="phpmyadmin.local"
UNINSTALL_LOG_FILE="uninstall_log.txt"
SILENT_MODE=false
CLEAR_LOG=false

# Progress bar function
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
    echo "Everything is uninstalled!"
}

# Function to check for locks
check_locks() {
    if fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; then
        echo "Package manager is locked by another process. Please resolve the lock and try again."
        exit 1
    fi
}

# Function to preconfigure dbconfig-common
preconfigure_dbconfig_common() {
    echo "Preconfiguring dbconfig-common..."
    echo "phpmyadmin phpmyadmin/dbconfig-remove boolean true" | sudo debconf-set-selections
    echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect none" | sudo debconf-set-selections
    echo "phpmyadmin phpmyadmin/app-password-confirm password " | sudo debconf-set-selections
    echo "phpmyadmin phpmyadmin/mysql/admin-pass password " | sudo debconf-set-selections
    echo "phpmyadmin phpmyadmin/mysql/app-pass password " | sudo debconf-set-selections
    echo "phpmyadmin phpmyadmin/dbconfig-reinstall boolean false" | sudo debconf-set-selections
    echo "phpmyadmin phpmyadmin/remove boolean true" | sudo debconf-set-selections
    echo "phpmyadmin phpmyadmin/purge boolean true" | sudo debconf-set-selections
}

# Function to uninstall Apache
uninstall_apache() {
    echo "Uninstalling Apache..."
    sudo systemctl stop apache2 --quiet
    if ! sudo apt-get remove --purge -y apache2 apache2-bin apache2-data apache2-utils ssl-cert; then
        echo "Error uninstalling Apache. Attempting to force remove..."
        sudo dpkg --force-all -r apache2 apache2-bin apache2-data apache2-utils ssl-cert
        sudo apt-get install -f -y
    fi
    sudo apt-get autoremove -y
    sudo apt-get clean

    # Remove Apache configuration files
    sudo rm -rf /etc/apache2
    sudo rm -rf /var/www
    sudo rm -rf /var/log/apache2

    echo "Apache uninstalled successfully."
}

# Function to uninstall MySQL
uninstall_mysql() {
    echo "Uninstalling MySQL..."
    sudo systemctl stop mysql --quiet
    if ! sudo apt-get remove --purge -y mysql-server; then
        echo "Error uninstalling MySQL. Attempting to force remove..."
        sudo dpkg --force-all -r mysql-server
        sudo apt-get install -f -y
    fi
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

    # Preconfigure dbconfig-common to avoid any interaction with MySQL
    echo "phpmyadmin phpmyadmin/dbconfig-remove boolean true" | sudo debconf-set-selections
    echo "phpmyadmin phpmyadmin/mysql/admin-pass password " | sudo debconf-set-selections
    echo "phpmyadmin phpmyadmin/mysql/app-pass password " | sudo debconf-set-selections
    echo "phpmyadmin phpmyadmin/dbconfig-reinstall boolean false" | sudo debconf-set-selections
    echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect none" | sudo debconf-set-selections
    echo "phpmyadmin phpmyadmin/dbconfig-commited boolean true" | sudo debconf-set-selections # Disable database dump

    # Check if MySQL service is active and installed
    if ! systemctl is-active --quiet mysql && ! dpkg-query -W -f='${Status}' mysql-server 2>/dev/null | grep -q "install ok installed"; then
        echo "MySQL is not installed or not running. Skipping MySQL-related steps..."
        
        # Skip all database-related actions if MySQL is not running
        echo "phpmyadmin phpmyadmin/dbconfig-remove boolean true" | sudo debconf-set-selections
        echo "phpmyadmin phpmyadmin/mysql/admin-pass password " | sudo debconf-set-selections
        echo "phpmyadmin phpmyadmin/mysql/app-pass password " | sudo debconf-set-selections
        echo "phpmyadmin phpmyadmin/dbconfig-reinstall boolean false" | sudo debconf-set-selections
        echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect none" | sudo debconf-set-selections
    else
        # Ensure MySQL server is stopped if installed and running
        sudo systemctl stop mysql --quiet
    fi

    # Force remove phpmyadmin if it fails
    if ! sudo apt-get remove --purge -y phpmyadmin; then
        echo "Error uninstalling phpMyAdmin. Attempting to force remove..."
        sudo dpkg --force-all -r phpmyadmin
        sudo apt-get install -f -y
    fi

    # Additional cleanup for phpmyadmin
    sudo rm -rf /etc/phpmyadmin
    sudo rm -rf /usr/share/phpmyadmin
    sudo rm -rf /var/lib/phpmyadmin

    sudo apt-get autoremove -y
    sudo apt-get clean

    # Remove Composer-related files and directories
    sudo rm -rf /usr/share/phpmyadmin/vendor
    sudo rm -rf /usr/share/phpmyadmin/composer.json
    sudo rm -rf /usr/share/phpmyadmin/composer.lock

    # Remove any additional phpMyAdmin-related files
    sudo rm -rf /etc/phpmyadmin
    sudo rm -rf /var/lib/phpmyadmin

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
    # Add a separator line if the -c option is not set
    echo "--------------------------------------------------"
    echo "Starting new uninstallation at $(date)"
    echo "--------------------------------------------------"
    check_locks
    uninstall_phpmyadmin
    uninstall_apache
    uninstall_mysql
    update_hosts_file
    echo "Uninstall script completed successfully."
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
    > "$UNINSTALL_LOG_FILE"
fi

# Prompt the user for confirmation
read -p "Are you sure you want to uninstall the applications? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo "Uninstallation aborted."
    exit 1
fi

# Run the main script
if [ "$SILENT_MODE" = true ]; then
    (main >> "$UNINSTALL_LOG_FILE" 2>&1) &
    progress_bar $!
else
    main 2>&1 | tee -a "$UNINSTALL_LOG_FILE"
fi
