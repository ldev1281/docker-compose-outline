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

Copy the example environment file and update the required values:

```
cp .env.example .env
```

Edit the `.env` file and replace placeholders with your actual data:

```
#
#
# postgres
OUTLINE_POSTGRES_USER=outline
OUTLINE_POSTGRES_PASSWORD=your_postgres_password
OUTLINE_POSTGRES_DB=outline

#
#
# SMTP settings
OUTLINE_SOCAT_SMTP_HOST=smtp.mailgun.org
OUTLINE_SOCAT_SMTP_PORT=587

#
#
# otline app
OUTLINE_APP_URL=https://your-domain.com

OUTLINE_APP_SECRET_KEY=your_outline_secret_key
OUTLINE_APP_UTILS_SECRET=your_outline_utils_secret_key

# SMTP
OUTLINE_APP_SMTP_USERNAME=your_smtp_username
OUTLINE_APP_SMTP_PASSWORD=your_smtp_password
OUTLINE_APP_SMTP_FROM_EMAIL=noreply@your-domain.com
OUTLINE_APP_SMTP_SECURE=false
```

#### Generate Secure Secret Keys

Use the following commands to generate strong random secrets:

```
# Generate a 64-character secret key for OUTLINE_APP_SECRET_KEY and another one for OUTLINE_APP_UTILS_SECRET
openssl rand -hex 32
```

Replace `your-domain.com` and the other placeholder values with your actual data.

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

