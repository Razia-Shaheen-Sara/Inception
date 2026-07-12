## DOCKER
Docker is an open-source **containerization** platform that simplifies application deployment by packaging software and its dependencies into a standardized unit called a container.
Unlike traditional virtual machines(?), Docker containers share the host OS kernel, making them more efficient and lightweight.  
Why it exist:  
-Reduce compatability issues  
-enhances portability across various platforms

## DOCKER IMAGE
Docker images are the fundamental building blocks of containers.They are read-only "templates" containing everything needed to run an application, 
including the operating system, application code, runtime, and dependencies.

Images are built using a Dockerfile, which defines the instructions for creating an image layer by layer.


## DOCKER CONTAINER
A Docker container is a "running instance" of a Docker image. Containers provide an "isolated runtime environment" where applications can run without 
interfering with each other or the host system.Each container has its own filesystem, networking, and process space but shares the host kernel(core manager inside OS).
Containers share kernel(?) only, not OS or memory directly


## DOCKER COMPOSE
Docker Compose is a tool that simplifies the management of "multi-container" applications.Instead of running multiple docker run commands, you can define an entire application stack 
using a docker-compose.yml file and deploy it with a single command.

## DOCKER HUB
Docker Hub is a cloud-based "public image registry" service for finding, storing, and distributing container images. Users can push custom images to Docker Hub 
and share them publicly or privately.

## nginx
engine x is a open source high performance "WEB SERVER, REVERSE PROXY & LOAD BALANCER" designed to handle 10,000 concurrent connections smoothly.
- WEB SERVER (The Fetcher): Takes requests from a browser and pulls files (text/images) directly from its own local storage to send back.
- REVERSE PROXY (The Middleman): Does not own the files. It intercepts requests and forwards them to a separate backend application/server to get the answer.
- LOAD BALANCER (The Traffic Cop): Distributes network traffic across multiple different servers so no single machine crashes.

## Why container is used in Inception:
- isolation (each service separated)
- reproducibility (same setup everywhere)
- easy networking between services (containers talk to each other)

## yml
A .yml (or .yaml) file is just a text file used for configuration.It defines your three mandatory services (NGINX, WordPress, and MariaDB) and 
gives instructions on how to build them.

## MariaDB
Open source database management system.  
### mysqld_safe 
It is a wrapper script that starts the MariaDB/MySQL server (mysqld) safely. It can:restart the server if it crashes, set up logging
 and handle some startup checks

## Inception Data Flow Architecture

The infrastructure processes requests through a bi-directional, multi-container pipeline. 
The flow changes depending on whether the request is static or dynamic:

### 1. Static Content Flow (HTML, CSS, Images)
NGINX acts purely as a **Web Server**, reading directly from the shared storage disk.

```text
[User Browser] ────(Port 443: HTTPS Request)────► [NGINX Container]
[User Browser] ◄────(Port 443: Static Files)───── [NGINX Container]
```

### 2. Dynamic Content Flow (WordPress/PHP)
NGINX acts as a **Reverse Proxy**, passing the request down the chain to be processed, which then travels all the way back to the user.

```text
  [User Browser]
       │   ▲
(Port 443) │   │ (Port 443)
       ▼   │
  [NGINX Container]
       │   ▲
(Port 9000) │   │ (Port 9000 via FastCGI)
       ▼   │
[WordPress Container]
       │   ▲
(Port 3306) │   │ (Port 3306 via SQL)
       ▼   │
 [MariaDB Container]
```

### Component Breakdown

* **NGINX (Port 443):** Operates simultaneously as a **Web Server** and a **Reverse Proxy**. 
  * **As a Web Server:** reads and delivers static files (`.html`, `.css`, images) directly from the disk 
  * **As a Reverse Proxy:** When it encounters a `.php` request, it stops reading from the disk and forwards the request to WordPress.

* **WordPress (Port 9000):** Operates as the **Code Execution Engine** (running PHP-FPM).  
  * Its sole function is to run the PHP website logic. When NGINX forwards a request, this container reads the instructions, commands MariaDB to hand over the required raw data, assembles that data into a completed HTML page, and passes it back up to NGINX.

* **MariaDB (Port 3306):** Operates as the **Relational Database Management System (RDBMS)**. 
  * It is completely locked down and only communicates with the WordPress container. 
  * It holds zero code, images, or web design layouts. It functions purely as an indexed storage vault that reads, writes, and returns the raw text data (user credentials, layout configurations, and post text) whenever WordPress requests it via SQL queries.

### Summary
Browser hits port 443 → NGINX → passes PHP to WordPress on port 9000 → WordPress reads/writes MariaDB on port 3306

### Why WordPress Uses Dynamic Content (PHP + MariaDB)?

Unlike static content (`.html`, `.css`), which delivers unchangeable, pre-made files from disk to every user, dynamic content is assembled on demand by PHP code pulling real-time data from MariaDB. reasons to use **Dynamic Content**:

1. **Personalization:** adapts instantly based on user(e.g., displaying unique user dashboards and user data).
2. **Real-Time Data Integration:** Ensures the content matches the exact state of the database at the millisecond of the request (e.g., live blog comments, updating post counts, or inventory tracking).
3. **Scalability (The Template System):** Eliminates the need to create thousands of unique HTML files(e.g for 1000 pages for 1000 blog articles). A single PHP template file can dynamically generate an infinite number of unique pages by injecting different data fetched from the database on the fly.

## Volume
A volume is a folder outside the container that keeps data even after the container is removed. It is in the host machine. inception needs 2 volumes  
- WordPress volume: stores WordPress Files
- MariaDB volume: stores database

## DOCKERFILE BASICS
A Dockerfile is a text file that tells Docker how to build an image step by step. Example Dockerfile content
FROM debian:bullseye  (means the base image from linux's debian)
RUN apt-get update && apt-get install -y curl  (run means"build the image with this installed inside" This runs during build time, not runtime)
CMD ["curl", "--version"]  (CMD runs when you start a container)  

then: be in the folder containing Dockerfile?

### docker build -t mytest .
1. Docker reads Dockerfile  
2. pulls debian image  
3. runs RUN commands (during building time creates image layers)  
4. saves final result as "mytest image"  
5. each RUN creates a new layer in the image  

### docker run mytest
1. create container from image
2. start CMD
3. CMD runs as main process (PID 1) because docker does not manage multiple processes 
    like a full OS it only runs as main program(PID 1). CMD finishes → PID 1 exits → container stops

### Dockerfile vs docker-compose.yml
Dockerfile builds one image vs docker-compose Run MULTIPLE containers together, connect networks + volumes


## DOCKER COMMANDS
### Basic commands:
- **Check docker in your machine:** docker --version
- **Check docker images:** docker images or docker image ls
- **Test if it works:** docker run hello-world
                    it checks if hello- world image exist, if not, downloads from Docker hub, makes a container from that image, 
                      Inside that container, there is a tiny program whose only job is: print the hello message and exit
- **run nginx:** docker run -p 8080:80 nginx  ("docker run nginx" also works)
              -- 80 = port inside container (nginx default)  
              -- 8080 = port on my computer  
              -- open browser and type http://localhost:8080  
- **Show running containers:** docker ps 
- **Show running+stopped containers:** docker ps -a
- **pause running container:** docker stop <id>
- **delete container:** docker rm <id>

### Building and running
- **create images:** 1. make a Dockerfile (stay in that directory)  
                    2. docker build -t <name> . 
-**check if image created:** docker images or docker image ls
- **create container from image and start it:**docker run <name> (it will start and die immediately)(Every run create new container)
- **Show running containers:** docker ps 
- **Show running+stopped containers:** docker ps -a
- **create multiple containers and start them:** (make a .yml file be in the .yml file containing directory) docker compose up
                                  up means build + create + start for everything described in the compose file.
- **Pull and run a simple container:** docker run -it debian:bullseye bash  
docker run    -> create and start a container  
-it           -> give me an interactive terminal  
debian:bullseye -> use Debian image  
bash          -> start bash shell  
- **Inside that container install curl**:apt-get update && apt-get install -y curl
- **Check if curl installed**:curl --version
- **exit container**:exit
- **start a process inside a running container** docker exec ...


## Mariadb

- MariaDB -the database server(OLD name- MySQL)
- What it does: stores the WordPress database. Runs in its own container. WordPress connects to it on port 3306.
- Why we initialize at all:
- - MariaDB needs a database and a user to exist before WordPress can connect. The start.sh script does this automatically on first container startup using the env vars from .env.  

- what start.sh does on first startup:  
- - starts MariaDB temporarily in background
- - creates database and user from env vars
- - stops it, restarts as PID 1 with exec  

- Key concepts:
- - mysqld = the actual database server process that IS MariaDB running (PID 1 in container)
- - mysql = client tool to send SQL commands to the server
- - /var/lib/mysql = where all database data lives → this is what the named volume saves
- - SQL - the language of those commands
- - mysqld_safe - old wrapper script that starts mysqld

- **create mariadb image**: write Dockerfile(FROM, RUN, ...) in the srcs/requirements/mairadb   
                    cd srcs/requirements/mariadb(has to read Dockerfile)  
                    docker build -t <name> .  
- **Check if install worked:** docker image ls (or) docker images 
- **Create/Check container** docker run -it <name> bash  
(Here, bash is running **INSIDE** mariadb container. these both commands are put together cause container keeps dying if there is nothing keeping it alive)
This command overrides the CMD[.sh] part in Dockerfile, means it does not need that CMD option. it just explores the filesystem to see if the software run.  

(P.S. Every run create new container)  
- - **just see what is inside container**: ls

- - **Key idea**
  These manual commands = what will later become an automatic entrypoint script in Docker.
  Without this step WordPress cannot connect to MariaDB.

### MariaDB container test

### Terminal 1 — start the container
- docker build -t <name> .
- docker run -e MYSQL_DATABASE=wordpress -e MYSQL_USER=wpuser -e MYSQL_PASSWORD=pass -e MYSQL_ROOT_PASSWORD=rootpass <name>

### Terminal 2 — verify it works
- docker ps                          # get container id
- docker exec -it <id> mysql -u wpuser -ppass wordpress -e "SHOW DATABASES;"
- expected: wordpress database listed, no errors

- What this confirmed:  

Dockerfile installs MariaDB correctly  
start.sh runs, creates the database and user from env vars  
Container stays alive (MariaDB running as PID 1 via exec)  
A client can connect to the server inside the same container  


## ARE WE DREAMING?

| Level | Prompt Example | Where You Are | How You Got There | How to Exit |
|---------|---------|---------|---------|---------|
| **Host Machine** | `sara@MacBook %` | Your Mac/Linux host system | Open Terminal | Close terminal or `exit` |
| **Container Shell** | `root@a3f9c12b8d01:/#` | Inside a Docker container | `docker exec -it <container> bash` | `exit` |
| **Process Inside Container** | `MariaDB [(none)]>` | Inside a program running in the container (MySQL, MariaDB, etc.) | Run the program (`mysql`, `mariadb`, etc.) | `EXIT;`, `quit`, or `Ctrl+C` depending on the program |

## WordPress
- What it does in Inception:  

Runs the actual website. Uses php-fpm to execute PHP code. Listens on port 9000.  
- What php-fpm is:
PHP is the language WordPress is written in. php-fpm is the process that runs PHP files. 

- What wp-cli is:  

A command line tool that installs and configures WordPress automatically. Without it you'd have to click through the browser installer manually every time.
- What setup.sh does on first startup:  
Waits for MariaDB to be ready  
Downloads WordPress files  
Creates wp-config.php (database connection settings)  
Installs WordPress with admin user and regular user from env vars  

- For eval, one sentence:

"WordPress runs php-fpm on port 9000. On first startup, setup.sh downloads WordPress and creates two users — an admin and a subscriber — from environment variables."

- Set up:
- - Step 1 — Add the Dockerfile at:  
srcs/requirements/wordpress/Dockerfile   
It installs php-fpm, php mysql extensions, and wp-cli.  
- - Step 2 — Add setup.sh at:  
srcs/requirements/wordpress/conf/setup.sh  
- - Step 3 — Build and test   
cd srcs/requirements/wordpress    
docker build -t test-wordpress .  
docker image ls  


### Wordpress test only after make

### Terminal 1
docker run -e MYSQL_DATABASE=wordpress \
           -e MYSQL_USER=wpuser \
           -e MYSQL_PASSWORD=pass \
           -e MYSQL_ROOT_PASSWORD=rootpass \
           -e DOMAIN_NAME=yourlogin.42.fr \
           -e WP_ADMIN_USER=webmaster \
           -e WP_ADMIN_PASSWORD=wpAdminPass42 \
           -e WP_ADMIN_EMAIL=webmaster@test.fr \
           -e WP_USER=subscriber \
           -e WP_USER_PASSWORD=subPass42 \
           -e WP_USER_EMAIL=sub@test.fr \
           test-wordpress

### Terminal 2
docker ps                    # get container id
docker exec -it <id> bash
ps aux                       # you should see php-fpm running

## NGINX
- What it does in Inception:  

It's the only entry point into your infrastructure. The browser connects to NGINX on port 443 (HTTPS). NGINX either serves static files directly, or forwards PHP requests to WordPress on port 9000. Nothing else is exposed to the outside.
- What TLS is:  
The S in HTTPS. Encrypts the connection between browser and server. Requires a certificate. We generate a self-signed one (browser will warn "not secure" — that's normal and expected for a local project).
- What the certificate is:  

Two files — a .crt (certificate) and a .key (private key). Generated once during docker build using openssl. They live inside the container.
- What nginx.conf does:  

listen 443 ssl → accept HTTPS connections  
ssl_protocols TLSv1.2 TLSv1.3 → subject requirement, no older protocols  
fastcgi_pass wordpress:9000 → forward PHP files to WordPress container  
try_files $uri $uri/ /index.php?$args → if file not found, send to WordPress  

- For eval, one sentence:

"NGINX is the only entrypoint on port 443. It handles TLS termination and forwards PHP requests to WordPress via fastcgi on port 9000."

- How to add NGINX files to your project
- - Step 1 — make srcs/requirements/nginx/conf/nginx.conf and put yourlogin.42.fr 
- - Step 2 — make srcs/requirements/nginx/Dockerfile put yourlogin.42.fr  
- - Step 3 — Build and test  
cd srcs/requirements/nginx  
docker build -t test-nginx .  
Then verify: docker image ls    # test-nginx should appear

- Test after building docker compose, not separately now
docker run -p 443:443 test-nginx 
