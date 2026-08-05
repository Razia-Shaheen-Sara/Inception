## Services
- **NGINX** — HTTPS entrypoint (TLS 1.2/1.3), port 443.
- **WordPress** — the site (php-fpm).
- **MariaDB** — the database.

## Start / stop the project
- go to inception: cd inception
- to Start: `make`
- to Stop: `make clean`
- Full reset (containers, images, volumes): `make fclean`

## Access
- Site: `https://rshaheen.42.fr`
- Admin: `https://rshaheen.42.fr/wp-admin`

## Credentials
- Admin/user passwords: `secrets/credentials.txt`
- DB passwords: `secrets/db_password.txt`, `secrets/db_root_password.txt`
- Usernames/config: `srcs/.env`


## Checking services
docker-compose ps
(The NGINX, WordPress, and MariaDB containers should show the status Up)