#!/bin/sh

echo "Starting init.sh..."

# Créer le fichier .htpasswd si nécessaire
if [ ! -f /etc/apache2/.htpasswd ]; then
    echo "Creating .htpasswd..."
    htpasswd -cb /etc/apache2/.htpasswd ${HTPASSWD_USER} ${HTPASSWD_PASS}
fi


# Tester Apache avant de le démarrer
echo "Testing Apache configuration..."
apache2ctl configtest

# Démarrer Apache
echo "Starting Apache..."
apache2ctl -D FOREGROUND


