# Outline Wiki Docker Compose Deployment (with Caddy Reverse Proxy)

This repository contains a Docker Compose configuration for deploying Outline Wiki with PostgreSQL, Redis, and Caddy as a reverse proxy.

## Setup Instructions

### 1. Clone the Repository

Clone the project to your server in the `/docker/outline/` directory:

```
mkdir -p /docker/outline
cd /docker/outline

# Clone the main Outline project
git clone https://github.com/jordimock/docker-compose-outline.git .
```


### 2. Create Docker Network and Set Up Reverse Proxy

This project is designed to work with the reverse proxy configuration provided by [docker-compose-caddy](https://github.com/jordimock/docker-compose-caddy). To enable this integration, follow these steps:

1. **Create the shared Docker network** (if it doesn't already exist):

   ```bash
   docker network create --driver bridge caddy-outline
   ```

2. **Set up the Caddy reverse proxy** by following the instructions in the [`docker-compose-caddy` repository](https://github.com/jordimock/docker-compose-caddy).  

Once Caddy is installed, it will automatically detect the Outline container via the `caddy-outline` network and route traffic accordingly.


### 3. Configure and Start the Application

To configure and launch all required services, run the provided script:

```bash
./tools/init.bash
```

The script will:

- Prompt you to enter configuration values (press `Enter` to accept defaults).
- Generate secure random secrets automatically.
- Save all settings to the `.env` file located at the project root.

**Important:**  
Make sure to securely store your `.env` file locally for future reference or redeployment.


### 4. Verify Running Containers

Check if all containers are running properly:

```bash
docker ps
```

Your Outline instance should now be operational.


## Backup instructions

To back up your Outline deployment located at `/docker/outline`, follow these steps:

1. **Stop the application:**

   ```bash
   cd /docker/outline
   docker compose down
   ```

2. **Copy the following to your backup directory:**

   ```bash
   cp -a .env /path/to/backup/dir/
   cp -a vol/ /path/to/backup/dir/vol/
   ```

   Replace `/path/to/backup/dir/` with your actual backup location.

3. **Start the application again:**

   ```bash
   docker compose up -d
   ```

You can automate this process using the [`backup-tool`](https://github.com/jordimock/backup-tool), which is already included in this project.
