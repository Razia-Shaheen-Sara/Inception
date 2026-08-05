*This project has been created as part of the 42 curriculum by rshaheen.*

## Description
Inception sets up NGINX, WordPress (with php-fpm), and MariaDB in separate Docker containers. Each container is created using a custom Debian Bookworm Dockerfile and managed with Docker Compose.

NGINX is the only entrypoint and uses TLS on port 443. It forwards PHP requests to WordPress (php-fpm) on port 9000. 
WordPress connects to MariaDB on port 3306 through a private Docker network. 
WordPress files and the database are stored in two named volumes, keeping the data after restarts.

**Design choices**
- **VMs vs Docker**: VMs virtualize a full OS per service; containers are just processes, so they're lighter and faster to start.
- **Secrets vs env vars**: `.env` values become plain environment variables inside the container, so anything reading that container's config can see them. Secrets are mounted as private files under `/run/secrets`, readable only inside the container that needs them. Passwords use secrets, non-sensitive config uses `.env`.
- **Docker network vs host network**: Using the host network removes container isolation and exposes services directly on the machine. A private bridge network (inception) allows containers to communicate safely while only exposing NGINX to the outside.
- **Volumes vs bind mounts**: Bind mounts depend on specific host paths and permissions. Named volumes are managed by Docker and keep data safe even when containers are removed or recreated

## Instructions
1. Create `secrets/`in the root of inception
2. `make` to build and start.
4. Visit `https://rshaheen.42.fr` in the vm
5. `make clean` stops containers, `make fclean` removes images/volumes, `make re` rebuilds from scratch.

## Resources
- https://devabdilah.medium.com/inception-42-a-comprehensive-guide-to-dockerizing-your-first-infrastructure-part-iii-a10e93e9d922
- https://dev.to/alejiri/docker-nginx-wordpress-mariadb-tutorial-inception42-1eok
**AI usage**: AI tools (Claude and ChatGPT) were used for debugging help, understanding concepts, and improving documentation.