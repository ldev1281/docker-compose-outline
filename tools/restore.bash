#!/bin/bash
set -e

# Usage:
#   ./restore.bash /path/to/backup-file

BACKUP_FILE="$1"

# Validate backup file exists
if [ ! -f "$BACKUP_FILE" ]; then
    echo "Usage: $0 /path/to/backup-file"
    echo "Error: Backup file '$BACKUP_FILE' not found."
    exit 1
fi

# Get absolute paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${SCRIPT_DIR}/.."

# Determine backup type
FILENAME="$(basename -- "$BACKUP_FILE")"

# Generate unique temp directory
TMP_DIR=$(mktemp -d -t restore-test-XXXXXXXXXXXXXXXX)
TMP_ARCHIVE="${TMP_DIR}/${FILENAME%.gpg}"

echo "Created temporary directory: $TMP_DIR"

# Step 1: Decrypt if necessary
if [[ "$BACKUP_FILE" == *.gpg ]]; then
    echo "Backup file is encrypted. Decryption..."

    if ! gpg --output "$TMP_ARCHIVE" --decrypt "$BACKUP_FILE"; then
        echo "Error: Failed to decrypt backup. Check your private key and passphrase." >&2
        rm -rf "$TMP_DIR"
        exit 1
    fi
    ARCHIVE_FILE="$TMP_ARCHIVE"
else
    ARCHIVE_FILE="$BACKUP_FILE"
fi

# Step 2: Test archive extraction
echo "Extraction to temporary directory..."

if tar -xzf "$ARCHIVE_FILE" -C "$TMP_DIR"; then
    echo "Archive extracted successfully"
else
    echo "Error: Failed to extract archive." >&2
    rm -rf "$TMP_DIR"
    exit 1
fi

# Cleanup temp directory after successful test
rm -rf "$TMP_DIR"
echo "Temporary files cleaned up."

echo "Backup file is valid and ready for restore"
