#!/bin/bash

# Variables
DOCKER_COMPOSE_FILE="docker-compose.yml"
CONTAINER_NAME="secure-apache"
SITE1_DOMAIN="site1.local"
SITE2_DOMAIN="site2.local"
PHP_DOMAIN="phpmyadmin.local"
LOG_FILE="installation_log.txt"
SILENT_MODE=false
CLEAR_LOG=false
HTPASSWD_USER=""
HTPASSWD_PASS=""

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

# Function to launch Docker Compose with forced image recreation
launch_docker_compose() {
    echo "Building and launching Docker Compose..."
    docker compose -f "$DOCKER_COMPOSE_FILE" up -d --build
}

# Function to get the IP address of the container
get_container_ip() {
    echo "Getting the IP address of the container..."
    CONTAINER_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$CONTAINER_NAME")
    echo "Container IP: $CONTAINER_IP"
}

# Function to update /etc/hosts
update_hosts_file() {
    echo "Updating /etc/hosts file if necessary..."
    CURRENT_IP=$(grep "$SITE1_DOMAIN" /etc/hosts | awk '{print $1}')

    if [ -z "$CURRENT_IP" ] || [ "$CURRENT_IP" != "$CONTAINER_IP" ]; then
        echo "Updating /etc/hosts with new IP address..."
        sudo sed -i "/$SITE1_DOMAIN/d" /etc/hosts
        sudo sed -i "/$SITE2_DOMAIN/d" /etc/hosts
        sudo sed -i "/$PHP_DOMAIN/d" /etc/hosts
        echo "$CONTAINER_IP $SITE1_DOMAIN $SITE2_DOMAIN $PHP_DOMAIN" | sudo tee -a /etc/hosts
    else
        echo "/etc/hosts is already up to date."
    fi
}

# Main script
main() {
    launch_docker_compose
    get_container_ip
    update_hosts_file
    echo "Script completed successfully."
}

# Parse command-line options
while getopts "scu:p:" opt; do
  case ${opt} in
    s )
      SILENT_MODE=true
      ;;
    c )
      CLEAR_LOG=true
      ;;
    u )
      HTPASSWD_USER="$OPTARG"
      ;;
    p )
      HTPASSWD_PASS="$OPTARG"
      ;;
    \? )
      echo "Usage: $0 [-s] [-c] [--user username] [--pass password]"
      exit 1
      ;;
  esac
done

# Clear the log file if the -c option is set
if [ "$CLEAR_LOG" = true ]; then
    > "$LOG_FILE"
fi

# Run the main script
if [ "$SILENT_MODE" = true ]; then
    (main >> "$LOG_FILE" 2>&1) &
    progress_bar $!
else
    main 2>&1 | tee -a "$LOG_FILE"
fi
