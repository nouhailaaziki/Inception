*This project has been created as part of the 42 curriculum by noaziki.*

# Inception

## Project Description

**Inception** is a system administration project from the 42 curriculum focused on learning containerization with **Docker** and **Docker Compose**.

The goal of this project is to build a complete WordPress infrastructure from scratch inside a Linux virtual machine. Each service is isolated in its own container and is built using a custom `Dockerfile` based on **Debian Bookworm Slim**.

The mandatory infrastructure consists of:

* **NGINX** - the only public entry point, providing HTTPS with TLS 1.2/1.3.
* **WordPress + PHP-FPM** - the web application and PHP processing layer.
* **MariaDB** - the relational database used by WordPress.

The project also includes several bonus services:

* **Redis** - WordPress object caching.
* **FTP** - file transfer access to the WordPress volume.
* **Adminer** - web-based database administration.
* **Netdata** - system and container monitoring.
* **Portfolio** - a separate static website served by NGINX.

The infrastructure is connected through a dedicated Docker bridge network. Persistent WordPress and MariaDB data are stored in Docker named volumes.

### Project Sources

The project contains all configuration and source files required to build the infrastructure from scratch:

* `srcs/docker-compose.yml` - defines the services, networks, volumes, secrets and dependencies.
* `srcs/requirements/nginx/` - custom NGINX image, HTTPS configuration and certificate generation.
* `srcs/requirements/wordpress/` - WordPress installation and PHP-FPM configuration.
* `srcs/requirements/mariadb/` - MariaDB installation and database initialization.
* `srcs/requirements/bonus/redis/` - Redis cache service.
* `srcs/requirements/bonus/ftp/` - FTP service.
* `srcs/requirements/bonus/adminer/` - Adminer database administration service.
* `srcs/requirements/bonus/netdata/` - monitoring service.
* `srcs/requirements/bonus/portfolio/` - custom static portfolio website.
* `secrets/` - local Docker secrets containing passwords and other sensitive credentials.
* `.env` - non-sensitive environment variables such as the domain name and service configuration.
* `Makefile` - commands used to build, start, stop and clean the infrastructure.

No ready-made application Docker images are used for the mandatory services. The images are built from the project's own Dockerfiles.

---

## Architecture

The mandatory infrastructure follows a simple three-tier architecture:

```text
                         Host Machine
                              |
                         HTTPS :443
                              |
                           NGINX
                              |
                 +------------+------------+
                 |                         |
           WordPress                  PHP-FPM
                 |
              MariaDB
```

The containers communicate through a dedicated Docker bridge network.

### Mandatory Services

| Service   | Role                             | Internal Port | Public Access |
| --------- | -------------------------------- | ------------: | ------------- |
| NGINX     | HTTPS reverse proxy / web server |           443 | `443`         |
| WordPress | PHP application                  |          9000 | Internal only |
| MariaDB   | Database                         |          3306 | Internal only |

NGINX is the only public entry point for the mandatory WordPress infrastructure.

### Bonus Services

| Service   | Role                    |                Port |
| --------- | ----------------------- | ------------------: |
| Redis     | WordPress object cache  |              `6379` |
| FTP       | WordPress file transfer | `21`, passive range |
| Adminer   | Database administration |              `8080` |
| Netdata   | Monitoring              |             `19999` |
| Portfolio | Static website          |              `8081` |

---

## Design Choices

### Custom Docker Images

Every service is built using a project-specific `Dockerfile`.

The mandatory images use **Debian Bookworm Slim** as their base distribution. This keeps the images relatively small while providing the packages and tools required by each service.

Building the images ourselves also makes the infrastructure reproducible and avoids depending on pre-configured application images.

### One Service Per Container

Each service runs in its own dedicated container.

For example:

* NGINX runs separately from WordPress.
* PHP-FPM runs separately from NGINX.
* MariaDB runs separately from WordPress.
* Redis, FTP, Adminer and Netdata each have their own containers.

This provides isolation and allows each service to be restarted or replaced independently.

### Persistent Storage

MariaDB and WordPress use named Docker volumes:

* `srcs_db_data` -> `/var/lib/mysql`
* `srcs_wp_data` -> WordPress files

This allows important data to survive container recreation.

### Docker Network

All services communicate through a dedicated Docker bridge network.

Services use Docker's internal DNS and service names, for example:

```text
wordpress -> mariadb
nginx     -> wordpress
```

No `network: host`, Docker `links`, or legacy `--link` mechanism is used.

### Restart Policy

Containers use a restart policy so that services can automatically recover from unexpected failures.

---

## Security

### HTTPS

NGINX terminates HTTPS connections on port `443`.

Only **TLS 1.2** are enabled.

The project does not expose WordPress PHP-FPM or MariaDB directly to the host.

### Credentials

Passwords are not stored directly inside Dockerfiles or committed to Git.

Sensitive credentials are provided through Docker secrets:

```text
secrets/
├── db_password.txt
├── db_root_password.txt
├── ftp_password.txt
├── wp_admin_password.txt
└── wp_user_password.txt
```

The `secrets/` directory is excluded from Git.

Non-sensitive configuration is stored in:

```text
srcs/.env
```

For example:

```env
DOMAIN_NAME=noaziki.42.fr
MYSQL_DATABASE=wordpress
MYSQL_USER=wpuser
```

### WordPress Users

The WordPress installation contains:

* one administrator account
* one regular user account

The administrator username does not contain `admin`, `Admin`, `administrator`, or `Administrator`, as required by the subject.

---

## Architectural Comparisons

### Virtual Machines vs Docker

| Virtual Machines                                | Docker Containers                       |
| ----------------------------------------------- | --------------------------------------- |
| Each VM runs a complete guest operating system. | Containers share the host Linux kernel. |
| Higher memory and storage overhead.             | Lightweight process isolation.          |
| Slower startup.                                 | Fast startup and recreation.            |
| Stronger OS-level separation.                   | Efficient application-level isolation.  |

For this project, Docker is appropriate because each service only needs its own isolated process environment rather than a complete operating system.

---

### Environment Variables vs Docker Secrets

| Environment Variables                                         | Docker Secrets                                                  |
| ------------------------------------------------------------- | --------------------------------------------------------------- |
| Convenient for configuration.                                 | Designed for sensitive information.                             |
| Values can be exposed through process/environment inspection. | Secrets can be provided separately from ordinary configuration. |
| Suitable for non-sensitive settings.                          | Better suited for passwords and credentials.                    |

Therefore, this project uses `.env` for configuration such as the domain name and Docker secrets for passwords.

---

### Host Network vs Docker Network

With host networking, a container shares the host's network namespace and loses much of Docker's network isolation.

With a dedicated Docker bridge network:

* containers have their own network interfaces,
* services can communicate using service names,
* internal ports do not need to be publicly exposed,
* communication between services is isolated from the host network.

For this project, the Docker network is therefore preferable to host networking.

---

### Bind Mounts vs Docker Volumes

A bind mount directly maps a specific host directory into a container.

A Docker named volume is managed by Docker and provides a more portable abstraction for persistent application data.

This project uses named volumes for MariaDB and WordPress data:

```text
srcs_db_data
srcs_wp_data
```

Docker's data root is configured on the project environment so that persistent Docker data is stored under:

```text
/home/noaziki/data
```

---

## Instructions

### Requirements

The project requires:

* Linux environment / 42 VM
* Docker
* Docker Compose
* `make`
* sufficient disk space for Docker images and volumes

### Build and Start

From the project root:

```bash
make
```

This builds the required Docker images and starts the infrastructure.

The WordPress website is available at:

```text
https://noaziki.42.fr
```

### Stop the Infrastructure

```bash
make down
```

### Rebuild the Infrastructure

```bash
make re
```

### Check Running Containers

```bash
docker compose -f srcs/docker-compose.yml ps
```

### Check Logs

For example:

```bash
docker compose -f srcs/docker-compose.yml logs nginx
docker compose -f srcs/docker-compose.yml logs wordpress
docker compose -f srcs/docker-compose.yml logs mariadb
```

### Access the Website

Open:

```text
https://noaziki.42.fr
```

Because the project uses a self-signed certificate, a browser may display a certificate warning during development.

---

## Verification

Useful checks include:

### Check Docker Containers

```bash
docker ps
```

### Check Images

```bash
docker images
```

### Check Volumes

```bash
docker volume ls
```

### Check Network

```bash
docker network ls
```

### Test HTTPS

```bash
curl -k -I https://noaziki.42.fr
```

### Test TLS 1.2

```bash
curl -k --tlsv1.2 --tls-max 1.2 -I https://noaziki.42.fr
```

### Verify TLS 1.1 Is Disabled

```bash
curl -k --tlsv1.1 --tls-max 1.1 -I https://noaziki.42.fr
```

The TLS 1.1 request should fail because the NGINX configuration only permits TLS 1.2 and TLS 1.3.

---

## Project Structure

```text
.
├── Makefile
├── README.md
├── DEV_DOC.md
├── USER_DOC.md
├── .gitignore
├── secrets/
│   ├── db_password.txt
│   ├── db_root_password.txt
│   ├── ftp_password.txt
│   ├── wp_admin_password.txt
│   └── wp_user_password.txt
└── srcs/
    ├── .env
    ├── docker-compose.yml
    ├── requirements/
    │   ├── mariadb/
    │   ├── nginx/
    │   ├── wordpress/
    │   └── bonus/
    │       ├── adminer/
    │       ├── ftp/
    │       ├── netdata/
    │       ├── portfolio/
    │       └── redis/
```

Sensitive files under `secrets/` and the `.env` file are excluded from Git.

---

## Resources

### Docker

1. https://docs.docker.com/
2. https://docs.docker.com/reference/compose-file/
3. https://docs.docker.com/reference/compose-file/version-and-name/
4. https://hub.docker.com/_/debian

### NGINX

5. https://nginx.org/en/docs/beginners_guide.html
6. https://wiki.alpinelinux.org/wiki/Nginx

### MariaDB

7. https://wiki.alpinelinux.org/wiki/MariaDB

### WordPress

8. https://developer.wordpress.org/advanced-administration/before-install/howto-install/
9. https://developer.wordpress.org/advanced-administration/wordpress/wp-config/
10. https://developer.wordpress.org/apis/wp-config-php/
11. https://make.wordpress.org/cli/handbook/guides/
12. https://make.wordpress.org/cli/handbook/guides/installing/
13. https://api.wordpress.org/secret-key/1.1/salt/

### WordPress and Redis

14. https://servebolt.com/help/wordpress/configuring-wordpress-with-redis-from-the-command-line/
15. https://www.fastcomet.com/kb/how-to-setup-wordpress-caching-with-redis-on-centos-6-and-cpanel

### Additional References

16. https://fr.wordpress.org/themes/
17. https://alpinelinux.org/releases/
18. https://www.ibm.com/docs/en/api-connect/software/10.0.x_cd?
19. https://blog.o2switch.fr/configurer-wp-config-php-wordpress/
20. https://wp-staging.com/docs/the-wordpress-database-structure/
21. https://artbees.net/blog/configuring-wordpress-in-wpconfig-php-file/
22. https://ebooks.karbust.me/Technology/Docker%20Deep%20Dive%20-%20Nigel%20Poulton.pdf

---

## AI Usage

The project was implemented independently.

AI tools were used only as a learning and assistance resource during the development process. They were mainly used to clarify technical concepts, understand unfamiliar behavior, and discuss possible test cases.

AI suggestions were treated as explanations or possible approaches, not as implementation instructions. I made the final decisions, wrote the project configuration and code myself, and verified the behavior in the actual project environment.

