#!/usr/bin/env bash
# failover.sh - simulate losing the primary and promote the standby.
set -euo pipefail
cd "$(dirname "$0")"

s() { docker compose exec -T standby psql -U postgres -d appdb -Atc "$1"; }

echo "Stopping the primary (simulated failure)..."
docker compose stop primary

echo "Promoting the standby..."
[[ $(s "select pg_promote(wait => true)") == "t" ]] || { echo "FAILED: promote" >&2; exit 1; }

[[ $(s "select pg_is_in_recovery()") == "f" ]] || { echo "FAILED: still in recovery" >&2; exit 1; }
echo "ok: standby is now a primary"

id=$(s "insert into heartbeat default values returning id")
echo "ok: new primary accepts writes (inserted heartbeat id $id)"

cat <<'TXT'

Next steps in real life:
  - point the application / service IP / DNS to the new primary
  - rebuild the old primary as a standby of the new one (pg_rewind or a fresh pg_basebackup)
  - in this lab:  docker compose down -v && docker compose up -d --wait
TXT
