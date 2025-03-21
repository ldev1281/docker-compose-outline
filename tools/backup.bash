#!/bin/bash

# Usage:
#   ./backup.bash /target/path [recipient-fingerprint]
#
# Arguments:
#   /target/path            - Absolute or relative path to the directory where the backup archive will be saved.
#   [recipient-fingerprint] - (Optional) GPG recipient fingerprint. If provided, the backup archive will be encrypted.
#
# Description:
#   This script performs the following steps:
#     1. Stops Docker containers located in the parent directory of this script.
#     2. Creates a backup archive containing the .env file and vol directory.
#     3. Restarts Docker containers.
#     4. Optionally encrypts the archive using the provided GPG recipient fingerprint.

TARGET_PATH="$1"
GPG_FINGERPRINT="$2"

# Validate arguments
if [ -z "$TARGET_PATH" ]; then
    echo "Usage: $0 /target/path [recipient-fingerprint]"
    echo "  /target/path            - Directory where the backup archive will be saved."
    echo "  [recipient-fingerprint] - (Optional) GPG recipient fingerprint for encryption."
    echo
    echo "Available GPG keys:"
    gpg --list-keys --with-colons | grep '^fpr' | cut -d: -f10
    exit 1
fi

# Validate GPG fingerprint if provided
if [ -n "$GPG_FINGERPRINT" ]; then
    gpg --list-keys "$GPG_FINGERPRINT" > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "Error: GPG key with fingerprint '$GPG_FINGERPRINT' not found in keyring."
        echo
        echo "Available GPG keys:"
        gpg --list-keys --with-colons | grep '^fpr' | cut -d: -f10
        exit 1
    fi
fi

# Initialize variables after validation
DATE=$(date +"%Y%m%d")
ARCHIVE_NAME="outline-${DATE}.tar.gz"
ENCRYPTED_NAME="outline-${DATE}.${GPG_FINGERPRINT}.gpg"

# Get the absolute path of script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${SCRIPT_DIR}/.."
ENV_FILE="${PROJECT_ROOT}/.env"
VOL_DIR="${PROJECT_ROOT}/vol"

# Stop Docker containers
echo "Stopping containers..."
docker compose --project-directory "$PROJECT_ROOT" down

# Create backup archive
echo "Creating archive ${ARCHIVE_NAME}..."
tar -czf "${TARGET_PATH}/${ARCHIVE_NAME}" -C "$PROJECT_ROOT" .env vol

# Restart Docker containers
echo "Starting containers..."
docker compose --project-directory "$PROJECT_ROOT" up -d


# Check if archive was created
if [ ! -f "${TARGET_PATH}/${ARCHIVE_NAME}" ]; then
    echo "Error: Backup archive was not created." >&2
    exit 1
fi

# Encrypt archive if GPG key is provided
if [ -n "$GPG_KEY" ]; then
    echo "Encrypting archive with recipient fingerprint ${GPG_KEY}..."
    gpg --output "${TARGET_PATH}/${ENCRYPTED_NAME}" --encrypt --recipient "$GPG_KEY" "${TARGET_PATH}/${ARCHIVE_NAME}"

    if [ $? -eq 0 ]; then
        rm "${TARGET_PATH}/${ARCHIVE_NAME}"
        echo "Archive successfully encrypted as ${ENCRYPTED_NAME}."
    else
        echo "Error encrypting the archive."
        exit 1
    fi
fi

echo "Backup completed successfully."
