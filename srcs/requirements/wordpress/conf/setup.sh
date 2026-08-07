#!/bin/bash
set -e
# Exit immediately if any command fails.

# WordPress installation directory
WP_DIR="/var/www/html"
DB_PASSWORD=$(cat /run/secrets/db_password)
#cut -d '=' -f2 means to split the line at the '=' character and take the second part (the value after the '='). This is used to extract the password from the credentials file.
WP_ADMIN_PASSWORD=$(grep WP_ADMIN_PASSWORD /run/secrets/credentials | cut -d '=' -f2)
WP_USER_PASSWORD=$(grep WP_USER_PASSWORD /run/secrets/credentials | cut -d '=' -f2)

# Wait until MariaDB is reachable before configuring WordPress.
# This prevents WordPress setup from failing if the database container
# is still starting.
until wp db check --path="$WP_DIR" --allow-root &>/dev/null 2>&1 || \
      mysqladmin ping -h mariadb -P 3306 -u"${MYSQL_USER}" -p"${DB_PASSWORD}" --silent; do
    echo "Waiting for MariaDB..."
    sleep 2
done

# Only install WordPress if it has not been configured yet.
# wp-config.php acts as a marker that WordPress setup is complete.
if [ ! -f "$WP_DIR/wp-config.php" ]; then
    # Download WordPress core files into the web root directory.
    wp core download --path="$WP_DIR" --allow-root

    # Create wp-config.php with database connection information.
    wp config create \
        --path="$WP_DIR" \
        --dbname="${MYSQL_DATABASE}" \
        --dbuser="${MYSQL_USER}" \
        --dbpass="${DB_PASSWORD}" \
        --dbhost=mariadb:3306 \
        --allow-root
    # Set the WordPress home and site URL dynamically based on the HTTP_HOST header or the DOMAIN_NAME environment variable.
    wp config set WP_HOME 'isset($_SERVER["HTTP_HOST"]) ? "https://".$_SERVER["HTTP_HOST"] : "https://".getenv("DOMAIN_NAME")' --raw --path="$WP_DIR" --allow-root
    wp config set WP_SITEURL 'isset($_SERVER["HTTP_HOST"]) ? "https://".$_SERVER["HTTP_HOST"] : "https://".getenv("DOMAIN_NAME")' --raw --path="$WP_DIR" --allow-root
    wp core install \
        --path="$WP_DIR" \
        --url="https://${DOMAIN_NAME}" \
        --title="Inception" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASSWORD}" \
        --admin_email="${WP_ADMIN_EMAIL}" \
        --allow-root

    # Create a regular user account.
    wp user create "${WP_USER}" "${WP_USER_EMAIL}" \
        --role=subscriber \
        --user_pass="${WP_USER_PASSWORD}" \
        --path="$WP_DIR" \
        --allow-root
    # Give the web server user ownership of WordPress files.
    chown -R www-data:www-data "$WP_DIR"
fi

#change the PHP-FPM socket to listen on port 9000 instead of a Unix socket.
#A Unix socket is a way for two programs on the same operating system to communicate.
#Nginx connects to PHP-FPM through wordpress:9000.
sed -i 's|listen = /run/php/php8.2-fpm.sock|listen = 9000|' \
    /etc/php/8.2/fpm/pool.d/www.conf

mkdir -p /run/php
#exec replaces the current shell process with PHP-FPM so that it becomes the main process of the container (PID 1).
# -nodaemonize stops PHP-FPM from running in the background, which is necessary for Docker containers to keep the main process running in the foreground.
exec php-fpm8.2 --nodaemonize
