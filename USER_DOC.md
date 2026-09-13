# User Documentation

This document is for anyone who wants to **use** the running Inception
stack — no development knowledge required.

## 1. What services does this stack provide?

| Service     | What it does                                            | How you reach it |
|-------------|----------------------------------------------------------|-------------------|
| nginx       | Serves the WordPress site over HTTPS                     | `https://noaziki.42.fr` |
| wordpress   | The WordPress site itself (behind nginx)                 | via nginx above |
| mariadb     | Stores the WordPress data (posts, users, settings)        | not directly reachable, internal only |
| redis       | Speeds up WordPress by caching database queries           | automatic, no action needed |
| ftp         | Lets you upload/download WordPress files directly         | any FTP client, port 21 |
| adminer     | A web page to browse/edit the MariaDB database directly   | `http://<server-ip>:8080` |
| portfolio   | A small personal portfolio page (unrelated to WordPress)  | `http://<server-ip>:8081` |

## 2. Starting and stopping the project

From the project's root directory (where the `Makefile` is):

```sh
make          # builds (if needed) and starts every service
make stop     # pauses all containers without removing them
make start    # resumes previously stopped containers
make down     # stops and removes the containers (data is kept)
make re       # full rebuild from a clean state
```

You can check everything is running with:
```sh
make ps
```
All 7 services should show a status of `Up`.

## 3. Accessing the website and the administration panel

- **Public website:** `https://noaziki.42.fr`
  Your browser will warn about the certificate being self-signed — this
  is expected for a local/student setup (there's no public Certificate
  Authority involved); you can safely proceed.
- **WordPress admin panel:** `https://noaziki.42.fr/wp-admin`
  Log in with the administrator account described below.
- **Database admin panel (Adminer):** `http://<server-ip>:8080`
  Use System: *MySQL*, Server: `mariadb`, and the database credentials
  below.
- **Portfolio page:** `http://<server-ip>:8081`

## 4. Locating and managing credentials

All passwords are generated once and stored as plain text files under the
`secrets/` folder at the project root (never committed to git):

| File                          | What it's for                          |
|--------------------------------|-----------------------------------------|
| `secrets/db_root_password.txt` | MariaDB `root` account password         |
| `secrets/db_password.txt`      | MariaDB `wp_user` account password (used by WordPress) |
| `secrets/wp_admin_password.txt`| WordPress administrator account password |
| `secrets/wp_user_password.txt` | Second WordPress account (editor role) password |
| `secrets/ftp_password.txt`     | FTP account password                    |

Usernames (not secret) are set in `srcs/.env`:
- WordPress administrator: `WP_ADMIN_USER` (currently `noaziki_boss`)
- WordPress second user: `WP_USER` (currently `noaziki_editor`)
- FTP user: `FTP_USER` (currently `noaziki_ftp`)
- Database user: `MYSQL_USER` (currently `wpuser`), database name `MYSQL_DATABASE`

To change a password: edit the relevant file in `secrets/`, then recreate
the affected container (e.g. `docker compose -f srcs/docker-compose.yml up -d --build wordpress`)
— note this only changes future logins for services that re-read the
secret; WordPress/MariaDB account passwords already created in the
database itself would need to be updated from within WordPress or via
`wp user update` / SQL, since the secret file only drives the *initial*
creation.

## 5. Checking that the services are running correctly

```sh
make ps          # container status overview
make logs        # live logs from every service (Ctrl+C to exit)
```

Quick manual checks:
- `curl -k https://noaziki.42.fr` should return WordPress HTML.
- `curl http://<server-ip>:8081` should return the portfolio HTML.
- `curl http://<server-ip>:8080` should show the Adminer login page.
- An FTP client connecting to port 21 with the FTP credentials above
  should show the WordPress files.

If a service isn't behaving, `docker compose -f srcs/docker-compose.yml logs <service>`
will show that specific container's output.
