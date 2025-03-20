#!/bin/bash
set -e

ENV_FILE="../.env"

# -------------------------------------
# Outline setup script
# -------------------------------------

# Generate secure random defaults
generate_defaults() {
    POSTGRES_PASSWORD=$(openssl rand -hex 32)
    SECRET_KEY=$(openssl rand -hex 32)
    UTILS_SECRET=$(openssl rand -hex 32)
}

# Load existing configuration from .env file
load_existing_env() {
    set -o allexport
    source "$ENV_FILE"
    set +o allexport
}

# Prompt user to confirm or update configuration
prompt_for_configuration() {
    echo "Please enter configuration values (press Enter to keep current/default value):"

    read -p "OUTLINE_POSTGRES_USER [${OUTLINE_POSTGRES_USER:-outline}]: " input
    OUTLINE_POSTGRES_USER=${input:-${OUTLINE_POSTGRES_USER:-outline}}

    read -p "OUTLINE_POSTGRES_PASSWORD [${OUTLINE_POSTGRES_PASSWORD:-$POSTGRES_PASSWORD}]: " input
    OUTLINE_POSTGRES_PASSWORD=${input:-${OUTLINE_POSTGRES_PASSWORD:-$POSTGRES_PASSWORD}}

    read -p "OUTLINE_POSTGRES_DB [${OUTLINE_POSTGRES_DB:-outline}]: " input
    OUTLINE_POSTGRES_DB=${input:-${OUTLINE_POSTGRES_DB:-outline}}

    read -p "OUTLINE_SOCAT_SMTP_HOST [${OUTLINE_SOCAT_SMTP_HOST:-smtp.mailgun.org}]: " input
    OUTLINE_SOCAT_SMTP_HOST=${input:-${OUTLINE_SOCAT_SMTP_HOST:-smtp.mailgun.org}}

    read -p "OUTLINE_SOCAT_SMTP_PORT [${OUTLINE_SOCAT_SMTP_PORT:-587}]: " input
    OUTLINE_SOCAT_SMTP_PORT=${input:-${OUTLINE_SOCAT_SMTP_PORT:-587}}

    read -p "OUTLINE_APP_URL [${OUTLINE_APP_URL:-https://your-domain.com}]: " input
    OUTLINE_APP_URL=${input:-${OUTLINE_APP_URL:-https://your-domain.com}}

    read -p "OUTLINE_APP_SECRET_KEY [${OUTLINE_APP_SECRET_KEY:-$SECRET_KEY}]: " input
    OUTLINE_APP_SECRET_KEY=${input:-${OUTLINE_APP_SECRET_KEY:-$SECRET_KEY}}

    read -p "OUTLINE_APP_UTILS_SECRET [${OUTLINE_APP_UTILS_SECRET:-$UTILS_SECRET}]: " input
    OUTLINE_APP_UTILS_SECRET=${input:-${OUTLINE_APP_UTILS_SECRET:-$UTILS_SECRET}}

    read -p "OUTLINE_APP_SMTP_USERNAME [${OUTLINE_APP_SMTP_USERNAME:-your_smtp_username}]: " input
    OUTLINE_APP_SMTP_USERNAME=${input:-${OUTLINE_APP_SMTP_USERNAME:-your_smtp_username}}

    read -p "OUTLINE_APP_SMTP_PASSWORD [${OUTLINE_APP_SMTP_PASSWORD:-your_smtp_password}]: " input
    OUTLINE_APP_SMTP_PASSWORD=${input:-${OUTLINE_APP_SMTP_PASSWORD:-your_smtp_password}}

    read -p "OUTLINE_APP_SMTP_FROM_EMAIL [${OUTLINE_APP_SMTP_FROM_EMAIL:-noreply@your-domain.com}]: " input
    OUTLINE_APP_SMTP_FROM_EMAIL=${input:-${OUTLINE_APP_SMTP_FROM_EMAIL:-noreply@your-domain.com}}

    read -p "OUTLINE_APP_SMTP_SECURE [${OUTLINE_APP_SMTP_SECURE:-false}]: " input
    OUTLINE_APP_SMTP_SECURE=${input:-${OUTLINE_APP_SMTP_SECURE:-false}}
}

# Display configuration and ask user confirmation
confirm_configuration() {
    echo ""
    echo "-------------------------------------------"
    echo "         Current Configuration:"
    echo "-------------------------------------------"
    echo "OUTLINE_POSTGRES_USER = $OUTLINE_POSTGRES_USER"
    echo "OUTLINE_POSTGRES_PASSWORD = $OUTLINE_POSTGRES_PASSWORD"
    echo "OUTLINE_POSTGRES_DB = $OUTLINE_POSTGRES_DB"
    echo "OUTLINE_SOCAT_SMTP_HOST = $OUTLINE_SOCAT_SMTP_HOST"
    echo "OUTLINE_SOCAT_SMTP_PORT = $OUTLINE_SOCAT_SMTP_PORT"
    echo "OUTLINE_APP_URL = $OUTLINE_APP_URL"
    echo "OUTLINE_APP_SECRET_KEY = $OUTLINE_APP_SECRET_KEY"
    echo "OUTLINE_APP_UTILS_SECRET = $OUTLINE_APP_UTILS_SECRET"
    echo "OUTLINE_APP_SMTP_USERNAME = $OUTLINE_APP_SMTP_USERNAME"
    echo "OUTLINE_APP_SMTP_PASSWORD = $OUTLINE_APP_SMTP_PASSWORD"
    echo "OUTLINE_APP_SMTP_FROM_EMAIL = $OUTLINE_APP_SMTP_FROM_EMAIL"
    echo "OUTLINE_APP_SMTP_SECURE = $OUTLINE_APP_SMTP_SECURE"
    echo "-------------------------------------------"

    read -p "Proceed with this configuration? (y/n): " CONFIRM
    if [[ "$CONFIRM" != "y" ]]; then
        echo "Configuration aborted by user."
        exit 1
    fi
}

# Save configuration to .env file
save_to_env_file() {
    {
        echo "# postgres"
        echo "OUTLINE_POSTGRES_USER=${OUTLINE_POSTGRES_USER}"
        echo "OUTLINE_POSTGRES_PASSWORD=${OUTLINE_POSTGRES_PASSWORD}"
        echo "OUTLINE_POSTGRES_DB=${OUTLINE_POSTGRES_DB}"

        echo -e "\n# SMTP settings"
        echo "OUTLINE_SOCAT_SMTP_HOST=${OUTLINE_SOCAT_SMTP_HOST}"
        echo "OUTLINE_SOCAT_SMTP_PORT=${OUTLINE_SOCAT_SMTP_PORT}"

        echo -e "\n# Outline app"
        echo "OUTLINE_APP_URL=${OUTLINE_APP_URL}"

        echo -e "\n# Secrets"
        echo "OUTLINE_APP_SECRET_KEY=${OUTLINE_APP_SECRET_KEY}"
        echo "OUTLINE_APP_UTILS_SECRET=${OUTLINE_APP_UTILS_SECRET}"

        echo -e "\n# SMTP"
        echo "OUTLINE_APP_SMTP_USERNAME=${OUTLINE_APP_SMTP_USERNAME}"
        echo "OUTLINE_APP_SMTP_PASSWORD=${OUTLINE_APP_SMTP_PASSWORD}"
        echo "OUTLINE_APP_SMTP_FROM_EMAIL=${OUTLINE_APP_SMTP_FROM_EMAIL}"
        echo "OUTLINE_APP_SMTP_SECURE=${OUTLINE_APP_SMTP_SECURE}"
    } > "$ENV_FILE"

    echo ".env file saved to $ENV_FILE"
}

# Set up containers and initialize the database
setup_containers() {
    echo "Stopping all containers and removing volumes..."
    docker compose down -v

    echo "Clearing volume data..."
    rm -rf vol/outline-postgres vol/outline-tor vol/outline-app vol/outline-redis/data

    echo "Starting containers..."
    docker compose up -d

    echo "Waiting 60 seconds for services to initialize..."
    sleep 60

    echo "Seeding the database with email: ${OUTLINE_APP_SMTP_FROM_EMAIL}"
    docker compose run --rm outline-app node build/server/scripts/seed.js "${OUTLINE_APP_SMTP_FROM_EMAIL}"

    echo "Seeding complete. Please copy the activation link from the console output and open it in your browser."
}

# -----------------------------------
# Main logic
# -----------------------------------

# Check if .env file exists, load or generate defaults accordingly
if [ -f "$ENV_FILE" ]; then
    echo ".env file found. Loading existing configuration."
    load_existing_env
else
    echo ".env file not found. Generating defaults."
    generate_defaults
fi

# Always prompt user for configuration confirmation
prompt_for_configuration

# Ask user confirmation before saving and proceeding
confirm_configuration

# Save confirmed configuration
save_to_env_file

# Run container setup
setup_containers
