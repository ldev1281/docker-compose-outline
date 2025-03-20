#!/bin/bash
set -e

echo "Stopping all containers if running and removing volumes..."
docker compose down -v

echo "Clearing volume data (except Redis config)..."
# Remove all data for Outline Postgres, Outline Tor, and Outline App:
rm -rf vol/outline-postgres
rm -rf vol/outline-tor
rm -rf vol/outline-app
# Also clear the Redis data directory (do not remove the configuration folder)
rm -rf vol/outline-redis/data

echo "Starting containers..."
docker compose up -d

echo "Waiting 60 seconds for services to initialize..."
sleep 60

read -p "Enter your email address for seeding: " USER_EMAIL

echo "Seeding the database..."
docker compose run --rm outline-app node build/server/scripts/seed.js "${USER_EMAIL}"

echo "Seeding complete! Please copy the activation link from the console output and open it in your browser."
