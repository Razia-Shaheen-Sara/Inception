FROM debian:bullseye

RUN apt-get update && apt-get install -y \
    mariadb-server \
    && rm -rf /var/lib/apt/lists/*
# rm cleans the apt cache (not the install) to keep the image layer small.
# chained in one RUN so Docker saves an already-clean layer.

COPY conf/start.sh /start.sh
# copy the start script to the container. 
# This script will start the MariaDB server and keep the container running.

RUN chmod +x /start.sh
# change the permissions of the start script to make it executable.

EXPOSE 3306
# open the default MariaDB port to allow external connections to the database server.
CMD ["/start.sh"]
#run this command at the start of the container


