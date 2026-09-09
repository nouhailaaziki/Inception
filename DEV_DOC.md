# Developer Documentation

This document is for anyone who wants to **build, modify, or extend** the
Inception project.

## 1. Setting up the environment from scratch

### Prerequisites
- A Linux VM (per subject requirement) with:
  - Docker Engine
  - The Docker Compose plugin (`docker compose version` should work)
  - `openssl` (already used at image-build/runtime, not needed on the host)
- Your own username in place of `noaziki` if you fork this for yourself
  (search-and-replace `noaziki` across `Makefile`, `srcs/.env`, and this
  documentation).

### Configuration files
- `srcs/.env` — all **non-secret** configuration: domain name, database
  name/username, WordPress titles/usernames/emails, bonus service ports,
  and `DATA_PATH` (the host path backing the two named volumes).
- `secrets/*.txt` — the five **secret** password files consumed as Docker
  secrets. They are `.gitignore`d. To (re)generate them locally:
  ```sh
  cd secrets
  for f in db_root_password db_password wp_admin_password wp_user_password ftp_password; do
      openssl rand -base64 18 | tr -d '/+=' | cut -c1-20 > "${f}.txt"
  done
  chmod 600 *.txt
  ```

### DNS / hosts
Add an entry pointing `noaziki.42.fr` at the VM's IP, either in the VM's
own `/etc/hosts` (for testing from inside the VM) and/or on the host
machine you browse from:
```
<VM_IP>  noaziki.42.fr
```

## 2. Building and launching with the Makefile / Docker Compose

```sh
make            # = make prepare + make up
make build      # build images only, no start
make up         # (re)build + start in detached mode
make down       # stop and remove containers (volumes/data untouched)
make stop/start # pause/resume without removing containers
make restart    # down + up
make clean      # down -v (drops the Docker-side volume metadata; host
                #  data under /home/noaziki/data is NOT deleted)
make fclean     # clean + remove built images + delete host data
                #  (asks for sudo to remove /home/noaziki/data)
make re         # fclean + all
```

The Makefile's `prepare` target creates the two host directories the
named volumes bind to (`/home/noaziki/data/mariadb`,
`/home/noaziki/data/wordpress`) before Compose runs, since Docker won't
create nested host paths for bind-backed named volumes on its own.

Everything is driven from `srcs/docker-compose.yml`; the Makefile is a
thin wrapper (`docker compose -f srcs/docker-compose.yml --env-file
srcs/.env ...`).

## 3. Managing containers and volumes directly

```sh
docker compose -f srcs/docker-compose.yml ps
docker compose -f srcs/docker-compose.yml logs -f <service>
docker compose -f srcs/docker-compose.yml exec wordpress bash
docker volume ls                     # shows db_data, wp_data
docker volume inspect wp_data        # shows the bind Mountpoint on host
docker network inspect inception     # shows all 7 containers attached
```

Each service builds from its own Dockerfile under
`srcs/requirements/<service>/` (bonus services under
`srcs/requirements/bonus/<service>/`). Rebuilding a single service after
editing its Dockerfile or entrypoint script:
```sh
docker compose -f srcs/docker-compose.yml up -d --build <service>
```

### How each service starts (idempotent entrypoints)
- **mariadb** (`tools/init_db.sh`): on first run (empty datadir) runs
  `mariadb-install-db`, boots a temporary socket-only `mariadbd`, creates
  the database/users from the secrets + `.env`, shuts it down, then
  `exec`s the real `mariadbd` in the foreground as PID 1. On subsequent
  runs it skips straight to `exec mariadbd`.
- **wordpress** (`tools/setup_wp.sh`): waits for MariaDB, and on first run
  (no `wp-config.php`) downloads WordPress core via WP-CLI, writes
  `wp-config.php`, runs `wp core install`, creates the second user, wires
  up the Redis object-cache plugin (best-effort), then `exec`s
  `php-fpm8.2 -F` (foreground) as PID 1.
- **nginx** (`tools/start_nginx.sh`): generates a self-signed certificate
  on first run if none exists, renders `nginx.conf` from
  `nginx.conf.template` via `envsubst` (only substituting `$DOMAIN_NAME`),
  then `exec`s `nginx -g "daemon off;"`.
- **redis**: `exec`s `redis-server` directly with a minimal config.
- **ftp** (`tools/setup_ftp.sh`): creates/updates the local FTP system
  user from `.env`/secret on every start, then `exec`s `vsftpd` in the
  foreground.
- **adminer**: single-file Adminer served by PHP's built-in server
  (`php -S 0.0.0.0:8080`), which is itself the foreground PID 1 process.
- **portfolio**: static files served by a dedicated nginx instance
  (`nginx -g "daemon off;"`), no PHP involved.

None of the entrypoints use `tail -f`, `sleep infinity`, `while true`, or
similar — every container's PID 1 is the actual service daemon running in
the foreground, so `docker stop`/crash signals are handled correctly and
`restart: on-failure` behaves as expected.

## 4. Where the data lives and how it persists

Two Docker **named volumes**, both using the `local` driver with
`driver_opts.o=bind`, so Docker manages the volume lifecycle while the
data is guaranteed to live at a fixed, inspectable host path:

| Volume    | Container mount point   | Host path (via `DATA_PATH` in `.env`) |
|-----------|--------------------------|-----------------------------------------|
| `db_data` | `/var/lib/mysql` (mariadb) | `/home/noaziki/data/mariadb` |
| `wp_data` | `/var/www/html` (wordpress, mounted read-only in nginx, read-write in ftp) | `/home/noaziki/data/wordpress` |

Because these are real named volumes (not raw bind mounts), `make down`
(without `-v`) leaves both the Docker volume objects and the underlying
host data intact — restarting the stack re-attaches to the same data
without re-running the first-run install logic (the entrypoint scripts
detect existing data and skip initialization). Only `make fclean` removes
the host data, and only after an explicit `sudo rm -rf`.
