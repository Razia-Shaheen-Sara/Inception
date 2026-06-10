## DOCKER
Docker is an open-source **containerization** platform that simplifies application deployment by packaging software and its dependencies into a standardized unit called a container.
Unlike traditional virtual machines, Docker containers share the host OS kernel, making them more efficient and lightweight.  
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
Containers share kernel only, not OS or memory directly


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


### Mariadb
- MariaDB -the database server(OLD name- MySQL)
- mysqld -the process/database that IS MariaDB running
- mysql - the client tool to connect and send commands
- SQL - the language of those commands
- mysqld_safe - old wrapper script that starts mysqld

- **create mariadb image**: write Dockerfile in the srcs/requirements/mairadb 
                    cd srcs/requirements/mariadb  
                    docker build -t test-mariadb .  
- **Check if install worked** docker image ls
- **Create container and start bash**:docker run -it test-mariadb bash  (Here, bash is running **INSIDE** mariadb container. these both commands are put together cause container keeps dying if there is nothing keeping it alive)(P.S. Every run create new container)  


- - **INSIDE MARIADB CONTAINER**

- - **Layer model (important understanding)**
 [1] FILESYSTEM LAYER (data on disk)
      /var/lib/mysql
      → database files stored here (inside container path)
      → physically stored on HOST via Docker filesystem

  [2] SERVER LAYER (database engine)
      mariadbd (or mysqld)
      → runs database system
      → reads/writes /var/lib/mysql
      → handles SQL requests

  [3] CLIENT LAYER (user tool)
      mysql -u root
      → connects to server
      → sends SQL queries

  **Flow:**
      mysql (client) → mariadbd (server) → /var/lib/mysql (data)  

- - **just see what is inside**: ls

- - **Check if MariaDB data directory is initialized**
  ls /var/lib/mysql
  (If you see folders like mysql, performance_schema → it is initialized)
  (If empty → not initialized)
  {/var/lib/mysql contains MariaDB system databases and engine files.
  It is created and populated during database initialization (mysql_install_db or first server startup).}
- - **Find system database tools**(users, permissions): which mysqld_safe  
  (which = search for a command in the current system PATH)
- - **Show configaration files** cat /etc/mysql/my.cnf
- - - - **START SERVER (MUST RUN BEFORE CLIENT)** mysqld_safe--skip-networking &
(mysqld_safe = wrapper that starts MariaDB server
--skip-networking = disables remote TCP connections (only local socket)
& = run in background so terminal stays usable) - So it Starts Mariadb in the background

- - **CONNECT CLIENT TO SERVER**

  mysql -u root

  → opens SQL shell; now we are inside sql shell
  → connects the client "mysql" to running mariadbd server


- - **TEST CONNECTION (inside SQL shell)**

  SHOW DATABASES;
  SELECT 1;
  EXIT;(exit sql shell only)

- - **INSIDE MARIADB CONTAINER: DATABASE + USER SETUP (MANUAL TEST)**

- - **Purpose of this step**
  This simulates what the Inception entrypoint script will automate.
  On container startup, the script will:
  → create database
  → create users
  → set permissions
  → allow WordPress connection

`` --- (Still inside the running container) 
mysql -u root <<EOF
CREATE DATABASE mydb;
CREATE USER 'wpuser'@'%' IDENTIFIED BY 'somepassword';
GRANT ALL PRIVILEGES ON mydb.* TO 'wpuser'@'%';
ALTER USER 'root'@'localhost' IDENTIFIED BY 'rootpass';
FLUSH PRIVILEGES;
EOF

- - **Verify it worked**
mysql -u wpuser -psomepassword mydb -e "SHOW TABLES;" ``

- - - **Open MariaDB shell as root**
  mysql -u root

- - - **Create database**
  CREATE DATABASE IF NOT EXISTS mydb;

  (mydb = database WordPress will use)

- - - **Create WordPress user**
  CREATE USER 'wpuser'@'%' IDENTIFIED BY 'somepassword';

  ('%' = allow connections from any host inside Docker network)

- - - **Give permissions**
  GRANT ALL PRIVILEGES ON mydb.* TO 'wpuser'@'%';

  (allows full access to only this database)

- - - **Change root password**
  ALTER USER 'root'@'localhost' IDENTIFIED BY 'rootpass';

- - -**Apply changes**
  FLUSH PRIVILEGES;

- - **Test new user login**
  mysql -u wpuser -psomepassword mydb -e "SHOW TABLES;"

- - **Key idea**
  These manual commands = what will later become an automatic entrypoint script in Docker.
  Without this step WordPress cannot connect to MariaDB.



## MariaDB container test
- Build the image:  
cd srcs/requirements/mariadb
docker build -t test-mariadb .
- Run it with env vars:  
docker run -e MYSQL_DATABASE=wordpress \  
           -e MYSQL_USER=wpuser \  
           -e MYSQL_PASSWORD=pass \  
           -e MYSQL_ROOT_PASSWORD=rootpass \  
           test-mariadb  
- Leave this terminal open — MariaDB is running here.  
- In a second terminal, verify it works:  
docker ps                               # get the container id  
docker exec -it <container_id> bash  # open a shell inside it  
mysql -u wpuser -ppass wordpress -e "SHOW DATABASES;"  # connect as wp user  
Expected result: you see the wordpress database listed. No errors.  

What this confirmed:  

Dockerfile installs MariaDB correctly  
start.sh runs, creates the database and user from env vars  
Container stays alive (MariaDB running as PID 1 via exec)  
A client can connect to the server inside the same container  




