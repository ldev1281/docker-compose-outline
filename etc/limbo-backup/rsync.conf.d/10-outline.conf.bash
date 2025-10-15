CMD_BEFORE_BACKUP="docker compose --project-directory /docker/outline down"
CMD_AFTER_BACKUP="docker compose --project-directory /docker/outline up -d"

CMD_BEFORE_RESTORE="docker compose --project-directory /docker/outline down || true"
CMD_AFTER_RESTORE=(
"docker network create --driver bridge proxy-client-outline || true"
"docker compose --project-directory /docker/outline up -d"
)

INCLUDE_PATHS=(
  "/docker/outline"
)
