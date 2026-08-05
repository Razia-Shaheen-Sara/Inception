## Prerequisites
- Docker + Docker Compose on the VM.
- `rshaheen.42.fr` resolving to the VM's local IP.

## Setup from scratch
1. Clone the repo.
2. Create secrets (gitignored, one value per file):
   - `secrets/db_password.txt`
   - `secrets/db_root_password.txt`
   - `secrets/credentials.txt` → `WP_ADMIN_PASSWORD=...` / `WP_USER_PASSWORD=...`

## Build & launch
- `make` — builds the three images and starts the stack.
- `make clean` — stops containers, removes the project's network.
- `make fclean` — `clean` + removes this project's images and volumes.
- `make re` — `fclean` + `all`.

## Managing containers & volumes
Run Docker Compose commands from the directory containing the docker-compose.yml file.
- Check running containers: docker compose ps
- View container logs: docker compose logs <service>
- List Docker volumes: docker volume ls
- Access the MariaDB database: docker exec -it mariadb mysql -u root -p

## Data persistence
- `wordpress_data` and `mariadb_data` are named volumes, mapped to `/home/rshaheen/data/` on the host.
- Data survives `make clean` and rebuilds; only `make fclean` removes it

