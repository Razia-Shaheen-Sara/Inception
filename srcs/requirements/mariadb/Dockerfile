FROM debian:bullseye

RUN apt-get update && apt-get install -y \
    mariadb-server \
    && rm -rf /var/lib/apt/lists/*

# rm cleans the apt cache (not the install) to keep the image layer small.
    # chained in one RUN so Docker saves an already-clean layer.

