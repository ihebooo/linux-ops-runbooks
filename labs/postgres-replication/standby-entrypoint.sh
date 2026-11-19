#!/usr/bin/env bash
# Standby start-up: on first start, clone the primary with pg_basebackup,
# then run PostgreSQL as a hot standby. On later starts, just start PostgreSQL.
set -euo pipefail

if [[ ! -s "$PGDATA/PG_VERSION" ]]; then
  echo "standby: no data yet, cloning the primary..."
  until pg_isready -h primary -U replicator -q; do sleep 1; done

  # -R writes standby.signal + primary_conninfo, -C -S creates a replication slot
  # so the primary keeps the WAL the standby still needs.
  pg_basebackup -h primary -U replicator -D "$PGDATA" \
    -R -X stream -C -S standby1 --checkpoint=fast --progress
  chmod 700 "$PGDATA"
fi

exec postgres -c hot_standby=on
