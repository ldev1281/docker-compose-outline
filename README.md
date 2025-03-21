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

# Clone the backup tool into ./backup-tool/
git clone https://github.com/jordimock/backup-tool.git ./backup-tool
```

`backup-tool` is used for automated backups of important volumes, including configs and persistent data.


### 2. Create Docker Networks

```
docker network create --driver bridge caddy-outline
```

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