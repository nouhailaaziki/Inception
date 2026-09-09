<!--
*This project has been created as part of the 42 curriculum by noaziki.*
-->
# Inception

## Description
Inception is a system administration project designed to expand practical knowledge of containerization using **Docker** and **Docker Compose** within a dedicated Linux Virtual Machine. The project requires building a secure, isolated multi-container infrastructure from scratch using custom `Dockerfile`s based on Debian or Alpine Linux distributions.

The core objective is to host a WordPress website running under PHP-FPM, backed by a MariaDB database, and served securely via an NGINX reverse proxy restricted to TLS v1.2 or TLS v1.3 protocols over port 443.

## Architectural Overview & Conceptual Comparisons

### Design Choices
- **Custom Base Images:** Each service runs inside a lightweight Alpine/Debian container created from custom Dockerfiles to avoid reliance on pre-built application images from public registries.
- **Service Separation:** Every daemon runs in its own dedicated container (one process per container) to ensure isolation and fault tolerance.
- **Custom Bridge Network:** All container communications occur over an isolated internal Docker network, leaving NGINX as the sole entry point exposed to the host machine.

### Architectural Comparisons

| Architecture Concept | System A | System B | Key Differences & Project Justification |
| :--- | :--- | :--- | :--- |
| **VMs vs. Docker** | **Virtual Machines** | **Docker Containers** | VMs virtualize the entire hardware layer and run full guest OS instances, consuming significant overhead. Docker shares the host kernel and isolates applications at the process level, allowing fast boot times and minimal resource usage. |
| **Credentials Storage** | **Environment Variables** | **Docker Secrets** | Plain environment variables can leak through process tables (`env`, `ps`) or container inspection (`docker inspect`). Docker secrets store sensitive data securely in memory or encrypted mounts, protecting passwords from version control. |
| **Networking** | **Host Network** | **Docker Network** | `--net=host` removes network isolation between container and host. A dedicated Docker bridge network enforces strict communication boundaries, allowing only intended containers to talk to each other across internal ports. |
| **Storage Persistence** | **Bind Mounts** | **Docker Volumes** | Bind mounts tie container paths directly to specific host file paths, reducing portability. Named Docker volumes are fully managed by the Docker engine while storing persistent data in a controlled host location (`/home/<login>/data`). |

---

## Service Infrastructure

The infrastructure consists of three mandatory containers configured under a private network:

1. **NGINX:** Acts as the single security gate handling external requests over port 443 using TLSv1.2/TLSv1.3.
2. **WordPress + PHP-FPM:** Processes dynamic web application logic on port 9000 without an embedded web server.
3. **MariaDB:** Relational database running on port 3306 with isolated volumes for persistent storage.

## Resources

1. https://docs.docker.com/
2. https://fr.wordpress.org/themes/
3. https://alpinelinux.org/releases/
4. https://wiki.alpinelinux.org/wiki/Nginx
5. https://wiki.alpinelinux.org/wiki/MariaDB
6. https://api.wordpress.org/secret-key/1.1/salt/
7. https://nginx.org/en/docs/beginners_guide.html
8. https://make.wordpress.org/cli/handbook/guides/
9. https://docs.docker.com/reference/compose-file/
10. https://developer.wordpress.org/apis/wp-config-php/
11. https://make.wordpress.org/cli/handbook/guides/installing/
12. https://www.ibm.com/docs/en/api-connect/software/10.0.x_cd?
13. https://blog.o2switch.fr/configurer-wp-config-php-wordpress/
14. https://wp-staging.com/docs/the-wordpress-database-structure/
15. https://make.wordpress.org/cli/handbook/how-to/how-to-install/
16. https://docs.docker.com/reference/compose-file/version-and-name/
17. https://hub.docker.com/_/debian?xk=ShowRecommendedBadge&xt=Disabled
18. https://artbees.net/blog/configuring-wordpress-in-wpconfig-php-file/
19. https://developer.wordpress.org/advanced-administration/wordpress/wp-config/
20. https://ebooks.karbust.me/Technology/Docker%20Deep%20Dive%20-%20Nigel%20Poulton.pdf
21. https://developer.wordpress.org/advanced-administration/before-install/howto-install/
22. https://servebolt.com/help/wordpress/configuring-wordpress-with-redis-from-the-command-line/
23. https://www.fastcomet.com/kb/how-to-setup-wordpress-caching-with-redis-on-centos-6-and-cpanel

### AI Usage

AI was treated as a development aid, not as an implementation source.

The project decisions, configurations, implementation, testing, and final
validation were carried out independently. AI was occasionally consulted
to investigate unfamiliar behavior, compare possible approaches, or
clarify technical concepts.

Before being adopted, any AI-provided suggestion was tested and checked
against official documentation or other reliable technical references.
The final result therefore reflects verified implementation choices rather
than unvalidated AI-generated content.
