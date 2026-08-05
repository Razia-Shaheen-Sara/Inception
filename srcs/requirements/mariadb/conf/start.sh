#!/bin/bash
set -e
# Exit immediately if any command fails.

#create a directory for the MySQL socket file and set the correct permissions
mkdir -p /run/mysqld
chown mysql:mysql /run/mysqld

#sed == stream editor
# Allow MariaDB to accept connections from other containers.
# By default it may only listen on localhost (127.0.0.1).
# The "|| true" prevents failure if the configuration line is not found.
# dev/null is used to suppress error messages if the file doesn't exist or the line isn't found.
sed -i "s/bind-address.*=.*127.0.0.1/bind-address = 0.0.0.0/" /etc/mysql/mariadb.conf.d/50-server.cnf 2>/dev/null || true

# Add a line to the MariaDB configuration to specify the port number for incoming connections.
sed -i "/\[mysqld\]/a port = 3306" /etc/mysql/mariadb.conf.d/50-server.cnf


MYSQL_PASSWORD=$(cat /run/secrets/db_password)
MYSQL_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)

# Only perform initial database setup once.
# The marker file remains in the database volume after container restarts.
if [ ! -f "/var/lib/mysql/.setup_done" ]; then
    # Start MariaDB temporarily without accepting network connections.
     # This allows us to create users and databases securely during initialization.
    mysqld_safe --skip-networking &
    TEMP_PID=$!
    # Wait until the temporary MariaDB server is ready to accept SQL commands.
    until mysql -u root -e "SELECT 1" &>/dev/null; do
        sleep 1
    done

    mysql -u root <<SQL
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
SQL
     # Create a marker so initialization is not repeated on every restart.
    touch /var/lib/mysql/.setup_done
    # Stop the temporary MariaDB instance cleanly.
    mysqladmin -u root -p"${MYSQL_ROOT_PASSWORD}" shutdown
    # Wait for the background MariaDB process to finish.
    wait $TEMP_PID 2>/dev/null || true
fi
# Start MariaDB normally as the main container process.
# exec replaces the shell process with MariaDB, making it PID 1.
exec mysqld_safe
