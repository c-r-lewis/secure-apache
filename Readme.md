# Serveur Apache Sécurisé avec Docker Compose

Ce projet configure un serveur Apache sécurisé avec Docker Compose, incluant les services MySQL et phpMyAdmin. Le serveur Apache est configuré pour servir plusieurs sites avec un accès restreint utilisant l'authentification HTTP de base.

## Structure du Projet

```
.
├── apache
│   ├── Dockerfile
│   ├── config
│   │   ├── apache2.conf
│   │   ├── ports.conf
│   │   ├── 000-default.conf
│   │   ├── default-ssl.conf
|   |   ├── phpmyadmin.conf
|   |   ├── site1.conf
|   |   ├── site2.conf
│   │   └── .htaccess
│   ├── html
│   │   ├── site1
│   │   └── site2
│   └── scripts
│       └── init.sh
├── config.env
├── docker-compose.yml
└── main.sh
```

## Prérequis

- Docker
- Docker Compose

## Configuration

### `config.env`

Le fichier `config.env` contient les variables d'environnement pour les services Docker :

```plaintext
HTPASSWD_USER=admin
HTPASSWD_PASS=password
MYSQL_ROOT_PASSWORD=rootpassword
MYSQL_DATABASE=database
MYSQL_USER=user
MYSQL_PASSWORD=password
PMA_HOST=mysql
```

### `docker-compose.yml`

Le fichier `docker-compose.yml` définit les services et leurs configurations :

```yaml
services:
  secure-apache:
    build: ./apache
    ports:
      - "8090:8090"
      - "443:443"
    env_file:
      - config.env
    container_name: secure-apache
    depends_on:
      - mysql
      - phpmyadmin
    networks:
      - app_network

  mysql:
    image: mysql:5.7
    env_file:
      - config.env
    container_name: mysql
    volumes:
      - mysql-data:/var/lib/mysql
    networks:
      - app_network

  phpmyadmin:
    image: phpmyadmin/phpmyadmin
    env_file:
      - config.env
    container_name: phpmyadmin
    networks:
      - app_network

networks:
  app_network:
    driver: bridge

volumes:
  mysql-data:
```

### Configuration Apache

Les fichiers de configuration Apache se trouvent dans le répertoire `apache/config`. Ces fichiers configurent le serveur Apache, y compris les hôtes virtuels et les paramètres SSL.

### `init.sh`

Le script `init.sh` initialise le serveur Apache, crée le fichier `.htpasswd` s'il n'existe pas, et démarre le service Apache.

## Utilisation

1. **Cloner le Dépôt**

   Clonez le dépôt sur votre machine locale :

   ```bash
   git clone <repository-url>
   cd <repository-directory>
   ```

2. **Construire et Exécuter les Services**

   Exécutez le script `main.sh` pour construire et démarrer les services Docker :

   ```bash
   sudo ./main.sh
   ```

   Le script va :
   - Lancer Docker Compose.
   - Obtenir l'adresse IP du conteneur `secure-apache`.
   - Mettre à jour le fichier `/etc/hosts` avec l'adresse IP du conteneur pour les domaines `site1.local` et `site2.local`.

3. **Accéder aux Services**

   - **Serveur Apache** : Accédez au serveur Apache à l'adresse `http://localhost:8090` ou `https://localhost`.
   - **Sites web**: Accédez au sites web à l'adresse `site1.local`ou `site2.local`. Vous serez invité à entrer le nom d'utilisateur et le mot de passe définis dans le fichier `config.env`.
   - **phpMyAdmin** : Accédez à phpMyAdmin à l'adresse `phpmyadmin.local`. Vous serez invité à entrer le nom d'utilisateur et le mot de passe définis dans le fichier `config.env`.

## Accès Restreint

Le serveur Apache est configuré pour restreindre l'accès en utilisant l'authentification HTTP de base. Le fichier `.htaccess` et le fichier `.htpasswd` sont utilisés pour appliquer cette restriction. Le script `init.sh` crée le fichier `.htpasswd` avec les identifiants définis dans le fichier `config.env`.

## Personnalisation

- **Variables d'Environnement** : Modifiez le fichier `config.env` pour changer les variables d'environnement des services Docker.
- **Configuration Apache** : Personnalisez les fichiers de configuration Apache dans le répertoire `apache/config` selon vos besoins.
- **Contenu HTML** : Ajoutez ou modifiez le contenu HTML dans le répertoire `apache/html` pour `site1` et `site2`.

