#!/bin/bash
set -e

mkdir -p /run/mysqld
chown mysql:mysql /run/mysqld

sed -i "s/bind-address.*=.*127.0.0.1/bind-address = 0.0.0.0/" /etc/mysql/mariadb.conf.d/50-server.cnf 2>/dev/null || true

MYSQL_PASSWORD=$(cat /run/secrets/db_password)
MYSQL_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)

if [ ! -f "/var/lib/mysql/.setup_done" ]; then
    mysqld_safe --skip-networking &
    TEMP_PID=$!

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

    touch /var/lib/mysql/.setup_done
    mysqladmin -u root -p"${MYSQL_ROOT_PASSWORD}" shutdown
    wait $TEMP_PID 2>/dev/null || true
fi

exec mysqld_safe
