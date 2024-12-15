# Utiliser une image de base Debian
FROM debian:bullseye-slim

# Mettre à jour les paquets et installer Apache sans interaction utilisateur
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y apache2 apache2-bin apache2-data libapache2-mod-security2 \
    php-mysql php libapache2-mod-php && \
    apt-get clean

# Configurer le fuseau horaire (par exemple, Europe/Paris)
ENV TZ=Europe/Paris
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Activer les modules nécessaires
RUN a2enmod ssl
RUN a2enmod headers
RUN a2enmod rewrite
RUN a2enmod security2
RUN a2enmod proxy proxy_http proxy_fcgi

# Copier les fichiers de configuration
COPY ./config/apache2.conf /etc/apache2/apache2.conf
COPY ./config/ports.conf /etc/apache2/ports.conf
COPY ./config/000-default.conf /etc/apache2/sites-available/000-default.conf
COPY ./config/default-ssl.conf /etc/apache2/sites-available/default-ssl.conf
COPY ./config/site1.conf /etc/apache2/sites-available/site1.conf
COPY ./config/site2.conf /etc/apache2/sites-available/site2.conf
COPY ./config/phpmyadmin.conf /etc/apache2/sites-available/phpmyadmin.conf
COPY ./config/.htaccess /var/www/html/.htaccess

# Copier les fichiers des sites
COPY ./html/site1 /var/www/site1
COPY ./html/site2 /var/www/site2

# Activer les sites
RUN a2ensite site1.conf
RUN a2ensite site2.conf
RUN a2ensite phpmyadmin.conf
RUN a2ensite 000-default.conf
RUN a2ensite default-ssl.conf

# Copier le script d'initialisation
COPY ./scripts/init.sh /usr/local/bin/init.sh
RUN chmod +x /usr/local/bin/init.sh

# Démarrer Apache et MySQL
CMD ["/usr/local/bin/init.sh"]
