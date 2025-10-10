#!/usr/bin/env bash
set -Eeuo pipefail

# -------------------------------------
# Outline setup script
# -------------------------------------

# Get the absolute path of script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/../.env"
VOL_DIR="${SCRIPT_DIR}/../vol"

OUTLINE_POSTGRES_VERSION=14
OUTLINE_REDIS_VERSION=6
OUTLINE_APP_VERSION="0.82.0"

# Generate secure random defaults
generate_defaults() {
    OUTLINE_POSTGRES_PASSWORD=$(openssl rand -hex 32)
    OUTLINE_APP_SECRET_KEY=$(openssl rand -hex 32)
    OUTLINE_APP_UTILS_SECRET=$(openssl rand -hex 32)
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

    echo "PostgreSQL settings:"
    read -p "OUTLINE_POSTGRES_USER [${OUTLINE_POSTGRES_USER:-outline}]: " input
    OUTLINE_POSTGRES_USER=${input:-${OUTLINE_POSTGRES_USER:-outline}}

    read -p "OUTLINE_POSTGRES_PASSWORD [${OUTLINE_POSTGRES_PASSWORD:-$OUTLINE_POSTGRES_PASSWORD}]: " input
    OUTLINE_POSTGRES_PASSWORD=${input:-${OUTLINE_POSTGRES_PASSWORD:-$OUTLINE_POSTGRES_PASSWORD}}

    read -p "OUTLINE_POSTGRES_DB [${OUTLINE_POSTGRES_DB:-outline}]: " input
    OUTLINE_POSTGRES_DB=${input:-${OUTLINE_POSTGRES_DB:-outline}}

    echo ""
    echo "Outline settings:"
    read -p "OUTLINE_APP_HOSTNAME [${OUTLINE_APP_HOSTNAME:-outline.example.com}]: " input
    OUTLINE_APP_HOSTNAME=${input:-${OUTLINE_APP_HOSTNAME:-outline.example.com}}

    read -p "OUTLINE_APP_SECRET_KEY [${OUTLINE_APP_SECRET_KEY:-$OUTLINE_APP_SECRET_KEY}]: " input
    OUTLINE_APP_SECRET_KEY=${input:-${OUTLINE_APP_SECRET_KEY:-$OUTLINE_APP_SECRET_KEY}}

    read -p "OUTLINE_APP_UTILS_SECRET [${OUTLINE_APP_UTILS_SECRET:-$OUTLINE_APP_UTILS_SECRET}]: " input
    OUTLINE_APP_UTILS_SECRET=${input:-${OUTLINE_APP_UTILS_SECRET:-$OUTLINE_APP_UTILS_SECRET}}

    read -p "OUTLINE_FORCE_HTTPS [${OUTLINE_FORCE_HTTPS:-true}]: " input
    OUTLINE_FORCE_HTTPS=${input:-${OUTLINE_FORCE_HTTPS:-true}}

    read -p "OUTLINE_NODE_ENV [${OUTLINE_NODE_ENV:-production}]: " input
    OUTLINE_NODE_ENV=${input:-${OUTLINE_NODE_ENV:-production}}

    echo ""
    echo "SMTP settings:"
    read -p "OUTLINE_SMTP_HOST [${OUTLINE_SMTP_HOST:-smtp.mailgun.org}]: " input
    OUTLINE_SMTP_HOST=${input:-${OUTLINE_SMTP_HOST:-smtp.mailgun.org}}

    read -p "OUTLINE_SMTP_SECURE [${OUTLINE_SMTP_SECURE:-true}]: " input
    OUTLINE_SMTP_SECURE=${input:-${OUTLINE_SMTP_SECURE:-true}}    

    read -p "OUTLINE_SMTP_PORT [${OUTLINE_SMTP_PORT:-587}]: " input
    OUTLINE_SMTP_PORT=${input:-${OUTLINE_SMTP_PORT:-587}}

    read -p "OUTLINE_SMTP_USER [${OUTLINE_SMTP_USER:-postmaster@sandbox123.mailgun.org}]: " input
    OUTLINE_SMTP_USER=${input:-${OUTLINE_SMTP_USER:-postmaster@sandbox123.mailgun.org}}

    read -p "OUTLINE_SMTP_FROM [${OUTLINE_SMTP_FROM:-outline@sandbox123.mailgun.org}]: " input
    OUTLINE_SMTP_FROM=${input:-${OUTLINE_SMTP_FROM:-outline@sandbox123.mailgun.org}}

    read -p "OUTLINE_SMTP_PASS [${OUTLINE_SMTP_PASS:-password}]: " input
    OUTLINE_SMTP_PASS=${input:-${OUTLINE_SMTP_PASS:-password}}


    echo ""
    # OAuth (Authentik)
    echo "Authentik OIDC settings:"
    read -p "OUTLINE_AUTHENTIK_CLIENT_ID [${OUTLINE_AUTHENTIK_CLIENT_ID:-outline}]: " input
    OUTLINE_AUTHENTIK_CLIENT_ID=${input:-${OUTLINE_AUTHENTIK_CLIENT_ID:-outline}}

    read -p "OUTLINE_AUTHENTIK_CLIENT_SECRET [${OUTLINE_AUTHENTIK_CLIENT_SECRET:-}]: " input
    OUTLINE_AUTHENTIK_CLIENT_SECRET=${input:-${OUTLINE_AUTHENTIK_CLIENT_SECRET:-}}

    read -p "OUTLINE_AUTHENTIK_URL [${OUTLINE_AUTHENTIK_URL:-https://auth.example.com}]: " input
    OUTLINE_AUTHENTIK_URL=${input:-${OUTLINE_AUTHENTIK_URL:-https://auth.example.com}}
}

# Display configuration and ask user to confirm
confirm_and_save_configuration() {
    CONFIG_LINES=(
        "# PostgreSQL"
        "OUTLINE_POSTGRES_VERSION=${OUTLINE_POSTGRES_VERSION}"
        "OUTLINE_POSTGRES_USER=${OUTLINE_POSTGRES_USER}"
        "OUTLINE_POSTGRES_PASSWORD=${OUTLINE_POSTGRES_PASSWORD}"
        "OUTLINE_POSTGRES_DB=${OUTLINE_POSTGRES_DB}"
        ""
        "# Redis"
        "OUTLINE_REDIS_VERSION=${OUTLINE_REDIS_VERSION}"
        ""
        "# Outline"
        "OUTLINE_APP_VERSION=${OUTLINE_APP_VERSION}"
        "OUTLINE_APP_HOSTNAME=${OUTLINE_APP_HOSTNAME}"
        "OUTLINE_APP_SECRET_KEY=${OUTLINE_APP_SECRET_KEY}"
        "OUTLINE_APP_UTILS_SECRET=${OUTLINE_APP_UTILS_SECRET}"
        "OUTLINE_FORCE_HTTPS=${OUTLINE_FORCE_HTTPS}"
        "OUTLINE_NODE_ENV=${OUTLINE_NODE_ENV}"
        ""
        "# SMTP Outline"
        "OUTLINE_SMTP_HOST=${OUTLINE_SMTP_HOST}"
        "OUTLINE_SMTP_PORT=${OUTLINE_SMTP_PORT}"
        "OUTLINE_SMTP_USER='${OUTLINE_SMTP_USER}'"
        "OUTLINE_SMTP_PASS='${OUTLINE_SMTP_PASS}'"
        "OUTLINE_SMTP_FROM=${OUTLINE_SMTP_FROM}"
        "OUTLINE_SMTP_SECURE=${OUTLINE_SMTP_SECURE}"
        ""
        "# Outline Authentik OIDC settings"
        "OUTLINE_AUTHENTIK_CLIENT_ID=${OUTLINE_AUTHENTIK_CLIENT_ID}"
        "OUTLINE_AUTHENTIK_CLIENT_SECRET=${OUTLINE_AUTHENTIK_CLIENT_SECRET}"
        "OUTLINE_AUTHENTIK_URL=${OUTLINE_AUTHENTIK_URL}"
    )

    echo ""
    echo "The following environment configuration will be saved:"
    echo "-----------------------------------------------------"
    for line in "${CONFIG_LINES[@]}"; do
        echo "$line"
    done
    echo "-----------------------------------------------------"
    echo ""

    read -p "Proceed with this configuration? (y/n): " CONFIRM
    echo ""
    if [[ "$CONFIRM" != "y" ]]; then
        echo "Configuration aborted by user."
        echo ""
        exit 1
    fi

    printf "%s\n" "${CONFIG_LINES[@]}" >"$ENV_FILE"
    echo ".env file saved to $ENV_FILE"
    echo ""
}

# Set up containers and initialize the database
setup_containers() {
    echo "Stopping all containers and removing volumes..."
    docker compose down -v || true

       if [ -d "$VOL_DIR" ]; then
        echo "The 'vol' directory exists:"
        echo " - In case of a new install type 'y' to clear its contents. WARNING! This will remove all previous configuration files and stored data."
        echo " - In case of an upgrade/installing a new application type 'n' (or press Enter)."
        read -p "Clear it now? (y/N): " CONFIRM
        echo ""
        if [[ "$CONFIRM" == "y" ]]; then
            echo "Clearing 'vol' directory..."
            rm -rf "${VOL_DIR:?}"/*
        fi
    fi

    mkdir -p "${VOL_DIR}/outline-app/var/lib/outline/data" && chown 1001:1001 "${VOL_DIR}/outline-app/var/lib/outline/data"

    echo "Starting containers..."
    docker compose up -d

    echo "Waiting 60 seconds for services to initialize..."
    sleep 60

    echo "Seeding the database with email: ${OUTLINE_SMTP_FROM}"
    docker compose run --rm outline-app node build/server/scripts/seed.js "${OUTLINE_SMTP_FROM}"
    echo ""
    echo "Seeding complete. Please copy the activation link from the console output and open it in your browser."
    echo ""
}

# -----------------------------------
# Main logic
# -----------------------------------

if [ -f "$ENV_FILE" ]; then
    echo ".env file found. Loading existing configuration."
    load_existing_env
else
    echo ".env file not found. Generating defaults."
    generate_defaults
fi

prompt_for_configuration
confirm_and_save_configuration
setup_containers
