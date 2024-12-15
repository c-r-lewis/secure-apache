#!/bin/bash

# Variables
DOCKER_COMPOSE_FILE="docker-compose.yml"
CONTAINER_NAME="secure-apache"
SITE1_DOMAIN="site1.local"
SITE2_DOMAIN="site2.local"
PHP_DOMAIN="phpmyadmin.local"

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

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --user)
            HTPASSWD_USER="$2"
            shift 2
            ;;
        --pass)
            HTPASSWD_PASS="$2"
            shift 2
            ;;
        *)
            echo "Unknown argument: $1"
            exit 1
            ;;
    esac
done

# Run the main script
main
