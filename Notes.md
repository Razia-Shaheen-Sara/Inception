## DOCKER"
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
Open source database management system

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
- **Check docker in your machine:** docker --version
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
- **create containers and start them:** 1. make a Dockerfile (stay in that directory)  
                                        2. docker build -t <name> . 
                                        3. docker run <name>
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





