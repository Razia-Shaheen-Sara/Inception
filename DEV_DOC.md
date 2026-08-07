## Prerequisites
- Docker + Docker Compose on the VM.
- open `sudo nano /etc/hosts`
- Add: 127.0.0.1 rshaheen.42.fr

## Setup from scratch
1. Clone the repo.
2. Create secrets (gitignored, one value per file):
   - `secrets/db_password.txt`
   - `secrets/db_root_password.txt`
   - `secrets/credentials.txt` → `WP_ADMIN_PASSWORD=...` / `WP_USER_PASSWORD=...`

## Build & launch with Makefile
- `make` — builds the three images and starts the stack.
- `make clean` — stops containers, removes the project's network.
- `make fclean` — `clean` + removes this project's images and volume objects
- `make re` — `fclean` + `all`

## Build and launch with Docker Compose
Docker Compose can also be used directly from the directory containing docker-compose.yml:
- `docker-compose up --build` — Start containers with building images
- `docker-compose up -d` — Start containers
- `docker-compose down` — Stop the stack

## Managing containers & volumes
Run Docker Compose commands from the directory containing the docker-compose.yml file.
- Check running containers: docker compose ps
- View container logs: docker compose logs <service>
- List Docker volumes: docker volume ls
- Access the MariaDB database: docker exec -it mariadb mysql -u root -p

## Data persistence
- `wordpress_data` and `mariadb_data` are named volumes, mapped to `/home/rshaheen/data/` on the host.
- Data survives `make clean`, and `make fclean` and rebuilds. 
- `make fclean` removes the docker volume objects but not the files living in /home/rshaheen/data/
