### Serveur Apache Sécurisé

Ce projet configure un serveur Apache sécurisé avec deux méthodes :
1. Utilisation de Docker Compose.
2. Utilisation d'un script complet pour une installation directe sur un système Linux.

## Structure du Projet

### Docker Version

```
.
├── apache
│   ├── Dockerfile
│   ├── config
│   │   ├── apache2.conf
│   │   ├── ports.conf
│   │   ├── 000-default.conf
│   │   ├── default-ssl.conf
│   │   ├── phpmyadmin.conf
│   │   ├── site1.conf
│   │   ├── site2.conf
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

### Full-Script Version

```
.
├── config
│   ├── apache2.conf
│   ├── ports.conf
│   ├── 000-default.conf
│   ├── default-ssl.conf
│   ├── phpmyadmin.conf
│   ├── site1.conf
│   ├── site2.conf
│   └── .htaccess
├── html
│   ├── site1
│   └── site2
├── config.env
├── install.sh
└── uninstall.sh
```

## Prérequis

### Docker Version

- Docker
- Docker Compose

### Full-Script Version

- Un système Linux (Ubuntu/Debian recommandé)

## Configuration

### `config.env`

Le fichier `config.env` contient les variables d'environnement pour les services :

```plaintext
HTPASSWD_USER=admin
HTPASSWD_PASS=password
MYSQL_ROOT_PASSWORD=rootpassword
MYSQL_DATABASE=database
MYSQL_USER=user
MYSQL_PASSWORD=password
PMA_HOST=mysql
```

### Docker Version

#### `docker-compose.yml`

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

#### Configuration Apache

Les fichiers de configuration Apache se trouvent dans le répertoire `apache/config`. Ces fichiers configurent le serveur Apache, y compris les hôtes virtuels et les paramètres SSL.

#### `init.sh`

Le script `init.sh` initialise le serveur Apache, crée le fichier `.htpasswd` s'il n'existe pas, et démarre le service Apache.

### Full-Script Version

#### Configuration Apache

Les fichiers de configuration Apache se trouvent dans le répertoire `config`. Ces fichiers configurent le serveur Apache, y compris les hôtes virtuels et les paramètres SSL.

#### `install.sh`

Le script `install.sh` installe et configure Apache, MySQL, et phpMyAdmin sur un système Linux. Il crée également le fichier `.htpasswd` et démarre le service Apache.

**Options de `install.sh` :**
- `-s` : Exécute le script en mode silencieux (les logs ne sont pas affichés dans le terminal mais sont écrits dans `installation_log.txt`).
- `-c` : Efface le fichier de log `installation_log.txt` avant de commencer l'installation.

**Fichier de log :**
- `installation_log.txt` : Contient les logs de l'installation. Une ligne de séparation avec la date est ajoutée au début du fichier de log avant de commencer l'installation.

#### `uninstall.sh`

Le script `uninstall.sh` désinstalle Apache, MySQL, et phpMyAdmin, et nettoie les configurations associées.

**Options de `uninstall.sh` :**
- `-s` : Exécute le script en mode silencieux (les logs ne sont pas affichés dans le terminal mais sont écrits dans `uninstall_log.txt`).
- `-c` : Efface le fichier de log `uninstall_log.txt` avant de commencer la désinstallation.

**Fichier de log :**
- `uninstall_log.txt` : Contient les logs de la désinstallation. Une ligne de séparation avec la date est ajoutée au début du fichier de log avant de commencer la désinstallation.

## Utilisation

### Docker Version

1. **Cloner le Dépôt**

   Clonez le dépôt sur votre machine locale :

   ```bash
   git clone git@github.com:c-r-lewis/secure-apache.git
   cd docker-version
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

### Full-Script Version

1. **Cloner le Dépôt**

   Clonez le dépôt sur votre machine locale :

   ```bash
   git clone git@github.com:c-r-lewis/secure-apache.git
   cd full-script-version
   ```

2. **Installer les Services**

   Exécutez le script `install.sh` pour installer et configurer les services :

   ```bash
   sudo ./install.sh
   ```

   Le script va :
   - Installer Apache, MySQL, et phpMyAdmin.
   - Configurer les services.
   - Créer le fichier `.htpasswd`.
   - Démarrer le service Apache.
   - Mettre à jour le fichier `/etc/hosts` pour les domaines `site1.local` et `site2.local`.

3. **Accéder aux Services**

   - **Serveur Apache** : Accédez au serveur Apache à l'adresse `http://localhost` ou `https://localhost`.
   - **Sites web**: Accédez au sites web à l'adresse `site1.local`ou `site2.local`. Vous serez invité à entrer le nom d'utilisateur et le mot de passe définis dans le fichier `config.env`.
   - **phpMyAdmin** : Accédez à phpMyAdmin à l'adresse `phpmyadmin.local`. Vous serez invité à entrer le nom d'utilisateur et le mot de passe définis dans le fichier `config.env`.

4. **Désinstaller les Services**

   Exécutez le script `uninstall.sh` pour désinstaller les services et nettoyer les configurations :

   ```bash
   sudo ./uninstall.sh
   ```

## Accès Restreint

Le serveur Apache est configuré pour restreindre l'accès en utilisant l'authentification HTTP de base. Le fichier `.htaccess` et le fichier `.htpasswd` sont utilisés pour appliquer cette restriction. Le script `init.sh` (Docker version) ou `install.sh` (Full-Script version) crée le fichier `.htpasswd` avec les identifiants définis dans le fichier `config.env`.

## Personnalisation

- **Variables d'Environnement** : Modifiez le fichier `config.env` pour changer les variables d'environnement des services.
- **Configuration Apache** : Personnalisez les fichiers de configuration Apache dans le répertoire `apache/config` (Docker version) ou `config` (Full-Script version) selon vos besoins.
- **Contenu HTML** : Ajoutez ou modifiez le contenu HTML dans le répertoire `apache/html` (Docker version) ou `html` (Full-Script version) pour `site1` et `site2`.