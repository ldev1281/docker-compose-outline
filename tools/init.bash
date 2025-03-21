#!/bin/bash
set -e

# Get the absolute path of script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/../.env"

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
    echo ""
    
    echo "postgres:"

    read -p "OUTLINE_POSTGRES_USER [${OUTLINE_POSTGRES_USER:-outline}]: " input
    OUTLINE_POSTGRES_USER=${input:-${OUTLINE_POSTGRES_USER:-outline}}

    read -p "OUTLINE_POSTGRES_PASSWORD [${OUTLINE_POSTGRES_PASSWORD:-$POSTGRES_PASSWORD}]: " input
    OUTLINE_POSTGRES_PASSWORD=${input:-${OUTLINE_POSTGRES_PASSWORD:-$POSTGRES_PASSWORD}}

    read -p "OUTLINE_POSTGRES_DB [${OUTLINE_POSTGRES_DB:-outline}]: " input
    OUTLINE_POSTGRES_DB=${input:-${OUTLINE_POSTGRES_DB:-outline}}

    echo "socat-smtp:"
    echo ""
    
    read -p "OUTLINE_SOCAT_SMTP_HOST [${OUTLINE_SOCAT_SMTP_HOST:-smtp.mailgun.org}]: " input
    OUTLINE_SOCAT_SMTP_HOST=${input:-${OUTLINE_SOCAT_SMTP_HOST:-smtp.mailgun.org}}

    read -p "OUTLINE_SOCAT_SMTP_PORT [${OUTLINE_SOCAT_SMTP_PORT:-587}]: " input
    OUTLINE_SOCAT_SMTP_PORT=${input:-${OUTLINE_SOCAT_SMTP_PORT:-587}}

    echo ""
    echo "app-smtp:"
    
    read -p "OUTLINE_APP_SMTP_USERNAME [${OUTLINE_APP_SMTP_USERNAME:-your_smtp_username}]: " input
    OUTLINE_APP_SMTP_USERNAME=${input:-${OUTLINE_APP_SMTP_USERNAME:-your_smtp_username}}

    read -p "OUTLINE_APP_SMTP_PASSWORD [${OUTLINE_APP_SMTP_PASSWORD:-your_smtp_password}]: " input
    OUTLINE_APP_SMTP_PASSWORD=${input:-${OUTLINE_APP_SMTP_PASSWORD:-your_smtp_password}}

    read -p "OUTLINE_APP_SMTP_FROM_EMAIL [${OUTLINE_APP_SMTP_FROM_EMAIL:-noreply@your-domain.com}]: " input
    OUTLINE_APP_SMTP_FROM_EMAIL=${input:-${OUTLINE_APP_SMTP_FROM_EMAIL:-noreply@your-domain.com}}

    read -p "OUTLINE_APP_SMTP_SECURE [${OUTLINE_APP_SMTP_SECURE:-false}]: " input
    OUTLINE_APP_SMTP_SECURE=${input:-${OUTLINE_APP_SMTP_SECURE:-false}}

    echo ""
    echo "app:"
    
    read -p "OUTLINE_APP_VERSION [${OUTLINE_APP_VERSION:-0.82.0}]: " input
    OUTLINE_APP_VERSION=${input:-${OUTLINE_APP_VERSION:-0.82.0}}

    read -p "OUTLINE_APP_URL [${OUTLINE_APP_URL:-https://your-domain.com}]: " input
    OUTLINE_APP_URL=${input:-${OUTLINE_APP_URL:-https://your-domain.com}}

    read -p "OUTLINE_APP_SECRET_KEY [${OUTLINE_APP_SECRET_KEY:-$SECRET_KEY}]: " input
    OUTLINE_APP_SECRET_KEY=${input:-${OUTLINE_APP_SECRET_KEY:-$SECRET_KEY}}

    read -p "OUTLINE_APP_UTILS_SECRET [${OUTLINE_APP_UTILS_SECRET:-$UTILS_SECRET}]: " input
    OUTLINE_APP_UTILS_SECRET=${input:-${OUTLINE_APP_UTILS_SECRET:-$UTILS_SECRET}}
}

# Display configuration nicely and ask for user confirmation
confirm_and_save_configuration() {
    CONFIG_LINES=(
        "# postgres"
        "OUTLINE_POSTGRES_USER=${OUTLINE_POSTGRES_USER}"
        "OUTLINE_POSTGRES_PASSWORD=${OUTLINE_POSTGRES_PASSWORD}"
        "OUTLINE_POSTGRES_DB=${OUTLINE_POSTGRES_DB}"
        ""
        "# SMTP settings"
        "OUTLINE_SOCAT_SMTP_HOST=${OUTLINE_SOCAT_SMTP_HOST}"
        "OUTLINE_SOCAT_SMTP_PORT=${OUTLINE_SOCAT_SMTP_PORT}"
        ""
        "# SMTP"
        "OUTLINE_APP_SMTP_USERNAME=${OUTLINE_APP_SMTP_USERNAME}"
        "OUTLINE_APP_SMTP_PASSWORD=${OUTLINE_APP_SMTP_PASSWORD}"
        "OUTLINE_APP_SMTP_FROM_EMAIL=${OUTLINE_APP_SMTP_FROM_EMAIL}"
        "OUTLINE_APP_SMTP_SECURE=${OUTLINE_APP_SMTP_SECURE}"
        ""
        "# Outline app"
        "OUTLINE_APP_VERSION=${OUTLINE_APP_VERSION}"
        "OUTLINE_APP_URL=${OUTLINE_APP_URL}"
        ""
        "# Secrets"
        "OUTLINE_APP_SECRET_KEY=${OUTLINE_APP_SECRET_KEY}"
        "OUTLINE_APP_UTILS_SECRET=${OUTLINE_APP_UTILS_SECRET}"
    )

    echo ""
    echo "The following environment configuration will be saved:"
    echo "-----------------------------------------------------"

    for line in "${CONFIG_LINES[@]}"; do
        echo "$line"
    done

    echo "-----------------------------------------------------"
    echo "" 

    #
    read -p "Proceed with this configuration? (y/n): " CONFIRM
    echo "" 
    if [[ "$CONFIRM" != "y" ]]; then
        echo "Configuration aborted by user."
        echo "" 
        exit 1
    fi

    #
    printf "%s\n" "${CONFIG_LINES[@]}" > "$ENV_FILE"
    echo ".env file saved to $ENV_FILE"
    echo "" 
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
    echo "" 

    echo "Seeding complete. Please copy the activation link from the console output and open it in your browser."
    echo "" 
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

# Ask user confirmation and save
confirm_and_save_configuration

# Run container setup
setup_containers
