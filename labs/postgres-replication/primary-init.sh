#!/usr/bin/env bash
# Runs once, when the primary is initialised: create the replication role
# and allow it to connect for streaming replication.
set -euo pipefail

psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" <<'SQL'
create role replicator with replication login password 'replicator';
SQL

# 'all' in the database column does not match replication connections,
# so replication needs its own pg_hba line.
echo "host replication replicator all scram-sha-256" >> "$PGDATA/pg_hba.conf"
