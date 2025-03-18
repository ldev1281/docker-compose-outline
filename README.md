# Outline Wiki Docker Compose Deployment (with Caddy Reverse Proxy)

This repository contains a Docker Compose configuration for deploying Outline Wiki with PostgreSQL, Redis, and Caddy as a reverse proxy.

## Setup Instructions

### 1. Clone the Repository

Clone the project to your server in the `/docker/outline/` directory:

```
mkdir -p /docker/outline
cd /docker/outline
git clone https://github.com/jordimock/docker-compose-outline.git .
```

### 2. Create Docker Networks

```
docker network create --driver bridge caddy-outline
```

### 3. Configure `.env` File

Create a `.env` file in the project root with the following content:

```
OUTLINE_POSTGRES_USER=outline
OUTLINE_POSTGRES_PASSWORD=your_postgres_password
OUTLINE_POSTGRES_DB=outline

OUTLINE_APP_URL=https://your-domain.com
OUTLINE_APP_SECRET_KEY=your_outline_secret_key
OUTLINE_APP_UTILS_SECRET=your_outline_utils_secret_key
```

Replace `your-domain.com` and other placeholder values with your actual data.

### 4. Review Docker Compose Configuration

Key services:

- `outline-postgres`: PostgreSQL database
- `outline-redis`: Redis cache
- `outline-app`: Outline Wiki application

The `outline-app` container is only exposed to the `caddy-outline` network and is not directly accessible from the internet.

### 5. Start the Services

```
docker compose up -d
```

### 6. Verify Running Containers

```
docker compose ps
```