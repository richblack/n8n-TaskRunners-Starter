#!/bin/bash
set -e

# Check if the database has been initialized
if [ ! -s "$PGDATA/PG_VERSION" ]; then
    echo "Initializing database..."
    PGPASSWORD="$PGPASSWORD" gosu postgres initdb --username="$POSTGRES_USER" --auth-local=trust --auth-host=md5
fi

# Execute the original PostgreSQL entrypoint
exec docker-entrypoint.sh "$@"