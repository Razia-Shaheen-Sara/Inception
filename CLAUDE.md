# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

42 school "Inception" project: a WordPress stack built from scratch as three containers — NGINX, WordPress (php-fpm), MariaDB — each from a hand-written `debian:bookworm` Dockerfile. No prebuilt application images, no `latest` tags. There is no application code and no test suite; the deliverable is the infrastructure itself.

## Commands

All commands run from the repo root. The Makefile wraps `docker-compose -f srcs/docker-compose.yml`.

```bash
make          # mkdir the host data dirs, build images, start detached
make clean    # compose down (containers + network)
make fclean   # clean + remove this project's images AND volumes (destroys data)
make re       # fclean + all
```

Verification and debugging:

```bash
docker compose -f srcs/docker-compose.yml ps
docker compose -f srcs/docker-compose.yml logs -f nginx     # or wordpress / mariadb
docker exec -it mariadb mysql -u root -p
docker exec -it wordpress wp core is-installed --path=/var/www/html --allow-root
```

Note the Makefile calls `docker-compose` (Compose v1 binary name) while the docs use both spellings. On a v2-only host, `make` fails until the Makefile is updated to `docker compose`.

## Architecture

Request path: browser → NGINX `:443` (TLS only, no port 80) → `fastcgi_pass wordpress:9000` → php-fpm → MariaDB `:3306`. Only 443 is published; the other two talk over the private `inception` bridge network and are unreachable from the host.

NGINX and WordPress **share the `wordpress_data` volume** at `/var/www/html`. WordPress writes the core files there; NGINX serves them as static content and only hands `.php` off over FastCGI. Editing where WordPress installs means editing NGINX's `root` too.

Both app containers are driven by an entrypoint script rather than a stock image entrypoint, and each `exec`s its daemon in the foreground so it becomes PID 1:

- [srcs/requirements/mariadb/conf/start.sh](srcs/requirements/mariadb/conf/start.sh) — patches `bind-address` to `0.0.0.0`, boots a temporary `--skip-networking` server to create the DB and users, then `exec mysqld_safe`.
- [srcs/requirements/wordpress/conf/setup.sh](srcs/requirements/wordpress/conf/setup.sh) — polls MariaDB until reachable, then wp-cli `core download` / `config create` / `core install` / `user create`, then `exec php-fpm8.2 --nodaemonize`.

There are no healthchecks. Startup ordering is `depends_on` plus the wait loop at the top of `setup.sh` — that loop is the only thing preventing a race, so don't remove it.

### Init is guarded by marker files — the important gotcha

Both scripts run on every container start but do their setup work exactly once:

- MariaDB checks `/var/lib/mysql/.setup_done`
- WordPress checks for `wp-config.php`

Both markers live **inside the persistent volumes**. So a change to the DB-creation SQL or the wp-cli install flags will silently not take effect on a rebuild — the guard sees the marker and skips the block. To exercise changed init logic you must destroy the volumes (`make fclean`), not just `make re`'s rebuild step.

The `sed` that switches php-fpm from a Unix socket to TCP `:9000` sits *outside* the guard in `setup.sh`, so it re-applies on every start. That is intentional — NGINX depends on it.

### Configuration split

Two mechanisms, and they are read differently:

| Source | Contents | How scripts read it |
|---|---|---|
| `srcs/.env` (via `env_file`) | `DOMAIN_NAME`, `MYSQL_DATABASE`, `MYSQL_USER`, `WP_ADMIN_USER`/`_EMAIL`, `WP_USER`/`_EMAIL` | plain shell env vars |
| `secrets/*.txt` (via Docker secrets → `/run/secrets/`) | all passwords | read from file at runtime |

The secret files are not uniform: `db_password.txt` and `db_root_password.txt` hold a **bare value** (`cat`), while `credentials.txt` holds **`KEY=VALUE` lines** parsed with `grep ... | cut -d '=' -f2` for `WP_ADMIN_PASSWORD` and `WP_USER_PASSWORD`. Adding a password means matching the format its consumer expects.

Passwords must never be baked into a Dockerfile or `.env` — that is an explicit 42 requirement, which is why the secrets indirection exists at all.

## Host-specific assumptions

- [srcs/docker-compose.yml](srcs/docker-compose.yml) declares both volumes as `driver_opts` bind mounts pinned to `/home/rshaheen/data/mariadb` and `/home/rshaheen/data/wordpress`. This path is hardcoded in the compose file *and* in the Makefile's `mkdir -p`. The stack will not start on a host where that path can't be created — changing hosts means changing both places.
- `rshaheen.42.fr` is hardcoded in `.env`, the NGINX `server_name`, and the self-signed cert's CN (generated at image build time in the Dockerfile). Changing the domain means updating all three, plus `/etc/hosts` on the host: `127.0.0.1 rshaheen.42.fr`.
- The cert is self-signed, so browsers will warn; that is expected for this project.

## Repository state

`.gitignore` lists `secrets/`, but the three files under `secrets/` were committed before that rule was added and are still tracked — `git ls-files secrets/` confirms it. Real password values are therefore in the public history. Adding the path to `.gitignore` again will not untrack them, and untracking them now will not remove them from history.
