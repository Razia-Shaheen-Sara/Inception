#!/bin/bash
# This script initializes the MariaDB data directory if it's empty, 
# starts the MariaDB server temporarily to set up database and user, 
# runs MariaDB in the foreground (PID 1 process for Docker).


#exit immediately if any command fails
set -e

# Initialize the data directory if it's empty
# (only runs on first container startup)
if [ ! -d "/var/lib/mysql/mysql" ]; then
    mysql_install_db --user=mysql --datadir=/var/lib/mysql
fi

# Start MariaDB temporarily in background to perform setup SQL
# mysqld_safe = wrapper that starts MariaDB server
# --skip-networking = disables external TCP connections during setup (security)
# & = runs process in background so script can continue

mysqld_safe --skip-networking &
TEMP_PID=$!

# Wait until MariaDB is ready to accept connections
# (server might take a few seconds to start)
# &>/dev/null suppresses output because 
# we only need the exit status of the command to know if it's ready
until mysql -u root -e "SELECT 1" &>/dev/null; do
    sleep 1
done

# Create database and users using env vars (no credentials in Dockerfiles)
mysql -u root <<EOF
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
EOF

# Stop the temporary mariadbinstance
kill $TEMP_PID
## Wait for the process to fully terminate before starting the main server
wait $TEMP_PID 2>/dev/null || true

# Start MariaDB(PID 1)as the main process of the container
# exec replaces shell with mariadbd process → keeps container alive
exec mysqld_safe


#flow: start MariaDB temporarily → use the mysql client to run SQL commands 
#that create the database and user → stop it 
#→ restart MariaDB properly as PID 1.