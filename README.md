# Outline Docker Compose Deployment (with Caddy Reverse Proxy)

This repository provides a production-ready Docker Compose configuration for deploying [Outline](https://github.com/outline/outline) — a self-hosted team knowledge base.  
The stack includes PostgreSQL, Redis, SMTP forwarding via `socat` (with optional SOCKS5h proxy support), and Caddy reverse proxy for automatic HTTPS.

## Setup Instructions

### 1. Clone the Repository

Clone the project to your server in the `/docker/outline/` directory:

```
    mkdir -p /docker/outline
    cd /docker/outline
    git clone https://github.com/ldev1281/docker-compose-outline.git .
```    

### 2. Create Docker Network and Set Up Reverse Proxy

This project is designed to work with the reverse proxy configuration provided by [`docker-compose-caddy`](https://github.com/ldev1281/docker-compose-caddy). To enable this integration, follow these steps:

1. **Create the shared Docker network** (if it doesn't already exist):

        docker network create --driver bridge --internal proxy-client-outline

2. **Set up the Caddy reverse proxy** by following the instructions in the [`docker-compose-caddy`](https://github.com/ldev1281/docker-compose-caddy) repository.  

Once Caddy is installed, it will automatically detect the Outline container via the `caddy-outline` network and route traffic accordingly.

### 3. Configure and Start the Application

Configuration Variables:

| Variable Name                     | Description                                                    | Default Value                            |
|----------------------------------|----------------------------------------------------------------|------------------------------------------|
| `OUTLINE_APP_VERSION`            | Docker image tag for Outline                                   | `0.82.0`                                 |
| `OUTLINE_APP_HOSTNAME`           | Public domain name for Outline                                 | `wiki.example.com`                       |
| `OUTLINE_APP_SECRET_KEY`         | Application secret for signing sessions                        | *(auto-generated)*                       |
| `OUTLINE_APP_UTILS_SECRET`       | Secret key for utility scripts                                 | *(auto-generated)*                       |
| `OUTLINE_FORCE_HTTPS`            | Whether to enforce HTTPS inside the app (`true` or `false`)    | `false`                                  |
| `OUTLINE_NODE_ENV`               | Node.js environment (`production`, `development`, etc.)        | `production`                             |
| `OUTLINE_POSTGRES_VERSION`       | Docker image tag for PostgreSQL                                | `14`                                     |
| `OUTLINE_POSTGRES_USER`          | PostgreSQL username                                            | `outline`                                |
| `OUTLINE_POSTGRES_PASSWORD`      | PostgreSQL password                                            | *(auto-generated or manual)*             |
| `OUTLINE_POSTGRES_DB`            | PostgreSQL database name                                       | `outline`                                |
| `OUTLINE_REDIS_VERSION`          | Docker image tag for Redis                                     | `6`                                      |
| `OUTLINE_SMTP_HOST`              | SMTP server hostname                                           | `smtp.mailgun.org`                       |
| `OUTLINE_SMTP_PORT`              | SMTP port (587 for STARTTLS, 465 for SSL)                      | `587`                                    |
| `OUTLINE_SMTP_USER`              | SMTP username for sending email sign-in links                  | `postmaster@sandbox123.mailgun.org`      |
| `OUTLINE_SMTP_PASS`              | SMTP password or app-password                                  | `password`                               |
| `OUTLINE_SMTP_FROM`              | SMTP sender address                                            | `outline@sandbox123.mailgun.org`         |
| `OUTLINE_SMTP_SECURE`            | Whether to use TLS/SSL (`true`) or STARTTLS (`false`)          | `false`                                  |
| `OUTLINE_AUTHENTIK_CLIENT_ID`    | Authentik OAuth2 Client ID                                     | `outline`                                |
| `OUTLINE_AUTHENTIK_CLIENT_SECRET`| Authentik OAuth2 Client Secret                                 | *(manual from Authentik UI)*             |
| `OUTLINE_AUTHENTIK_URL`          | Public base URL of Authentik instance                          | `https://auth.example.com`               |


To configure and launch all required services, run the provided script:

```
    ./tools/init.bash
```

The script will:

- Prompt you to enter configuration values (press `Enter` to accept defaults).
- Generate the `.env` file.
- Clean up volumes and start the containers.

**Important:**  
Make sure to securely store your `.env` file locally for future reference or redeployment.

### 4. Start the Outline Service


```
    docker compose up -d
```

This will start Outline and make your configured domains available.

### 5. Verify Running Containers

```
    docker compose ps
```

You should see the `outline-app` container running.

### 6. Persistent Data Storage

Outline and its dependencies use the following bind-mounted volumes for data persistence:

- `./vol/outline-postgres:/var/lib/postgresql/data` – PostgreSQL database
- `./vol/outline-redis:/data` – Redis data
- `./vol/outline-app:/data` – Outline runtime uploads and persistent files

---

### Example Directory Structure



```
/docker/outline/
├── docker-compose.yml
├── .env
├── tools/
│   └── init.bash
├── vol/
│   ├── outline-postgres/
│   ├── outline-redis/
│   └── outline-app/
```


## Creating a Backup Task for Outline

To create a backup task for your Outline deployment using [`backup-tool`](https://github.com/jordimock/backup-tool), add a new task file to `/etc/limbo-backup/rsync.conf.d/`:

```bash
sudo nano /etc/limbo-backup/rsync.conf.d/10-outline.conf.bash
```

Paste the following contents:

```bash
CMD_BEFORE_BACKUP="docker compose --project-directory /docker/outline down"
CMD_AFTER_BACKUP="docker compose --project-directory /docker/outline up -d"

CMD_BEFORE_RESTORE="docker compose --project-directory /docker/outline down || true"
CMD_AFTER_RESTORE=(
"docker network create --driver bridge --internal proxy-client-outline || true"
"docker compose --project-directory /docker/outline up -d"
)

INCLUDE_PATHS=(
  "/docker/outline"
)
```
## License

Licensed under the Prostokvashino License. See [LICENSE](LICENSE) for details.
