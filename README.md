# Outline Docker Compose Deployment (with Caddy Reverse Proxy & SMTP Support)

This repository provides a production-ready Docker Compose setup for deploying [Outline](https://github.com/outline/outline) — a self-hosted team knowledge base.  
The stack includes PostgreSQL, Redis, and optional SMTP proxying via `socat`, along with `Caddy` reverse proxy support for automatic HTTPS.

## Setup Instructions

### 1. Clone the Repository

Clone the project to your server in the `/docker/outline/` directory:

```bash
mkdir -p /docker/firefly
cd /docker/firefly

# Clone the main Outline project
git clone https://github.com/ldev1281/docker-compose-outline.git .
```
## 2. Create Docker Network and Set Up Reverse Proxy

This project is designed to work with the reverse proxy configuration provided by [`docker-compose-caddy`](https://github.com/ldev1281/docker-compose-caddy). To enable this integration, follow these steps:

1. **Create the shared Docker network** (if it doesn't already exist):

   ```bash
   docker network create --driver bridge caddy-outline
   ```
2. **Set up the Caddy reverse proxy** by following the instructions in the [`docker-compose-caddy`](https://github.com/ldev1281/docker-compose-caddy). repository.
   Once Caddy is installed, it will automatically detect the Firefly III container via the caddy-firefly network and route traffic accordingly.

## 3. Configure and Start the Application

Configuration Variables:

| Variable Name                          | Description                                                    | Default Value                            |
|----------------------------------------|----------------------------------------------------------------|------------------------------------------|
| OUTLINE_APP_VERSION                    | Docker image tag for Outline                                   | 0.82.0                                   |
| OUTLINE_APP_URL                        | Public domain name for Outline                                 | https://wiki.example.com                 |
| OUTLINE_APP_SECRET_KEY                 | Application secret for signing sessions                        | (auto-generated)                         |
| OUTLINE_APP_UTILS_SECRET               | Secret key for utility scripts (e.g. seeding)                  | (auto-generated)                         |
| OUTLINE_POSTGRES_VERSION               | Docker image tag for PostgreSQL                                | 14                                       |
| OUTLINE_POSTGRES_USER                  | PostgreSQL username                                            | outline                                  |
| OUTLINE_POSTGRES_PASSWORD              | PostgreSQL password                                            | (auto-generated or input manually)       |
| OUTLINE_POSTGRES_DB                    | PostgreSQL database name                                       | outline                                  |
| OUTLINE_REDIS_VERSION                  | Docker image tag for Redis                                     | 6                                        |
| OUTLINE_SMTP_USER                      | SMTP username for sending email sign-in links                  | postmaster@sandbox123.mailgun.org        |
| OUTLINE_SMTP_PASS                      | SMTP password or app-password                                  | password                                 |
| OUTLINE_SMTP_FROM                      | SMTP sender address                                            | outline@sandbox123.mailgun.org           |
| OUTLINE_SMTP_SECURE                    | Whether to use TLS/SSL (`true`) or STARTTLS (`false`)          | false                                    |
| OUTLINE_SOCAT_SMTP_HOST                | Target SMTP host (used by socat proxy container)               | smtp.mailgun.org                         |
| OUTLINE_SOCAT_SMTP_PORT                | SMTP port and proxy listen port                                | 587                                      |
| OUTLINE_SOCAT_SMTP_SOCKS5H_HOST        | SOCKS5h proxy host (optional)                                  | (empty)                                  |
| OUTLINE_SOCAT_SMTP_SOCKS5H_PORT        | SOCKS5h proxy port (optional)                                  | (empty)                                  |
| OUTLINE_SOCAT_SMTP_SOCKS5H_USER        | SOCKS5h proxy username (optional)                              | (empty)                                  |
| OUTLINE_SOCAT_SMTP_SOCKS5H_PASSWORD    | SOCKS5h proxy password (optional)                              | (empty)                                  |

To configure and launch all required services, run the provided script:

    ./tools/init.bash

The script will:

- Prompt you to enter configuration values (press Enter to accept defaults).
- Generate secure random secrets automatically.
- Save all settings to the `.env` file located at the project root.
- Stop and reinitialize containers with clean volumes.

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

Outline stores important runtime data, uploaded files, Redis and PostgreSQL database data using Docker volumes.

- `./vol/outline-postgres` – PostgreSQL database volume
- `./vol/outline-redis` –  Redis data
-  `./vol/outline-app` – Outline uploads and persistent storage

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



## License

Licensed under the Prostokvashino License. See [LICENSE](LICENSE) for details.