#!/usr/bin/env bash
# verify.sh - prove that replication works end to end:
#   1. roles are right (primary writable, standby in recovery)
#   2. the standby's WAL receiver is streaming
#   3. a row written on the primary shows up on the standby
#   4. writes on the standby are refused
set -euo pipefail
cd "$(dirname "$0")"

p() { docker compose exec -T primary psql -U postgres -d appdb -Atc "$1"; }
s() { docker compose exec -T standby psql -U postgres -d appdb -Atc "$1"; }

wait_for() {  # wait_for <description> <command...>
  local what=$1; shift
  for _ in $(seq 1 30); do
    if "$@"; then echo "ok: $what"; return 0; fi
    sleep 1
  done
  echo "FAILED: $what" >&2
  return 1
}

ready() { docker compose exec -T "$1" pg_isready -U postgres -d appdb -q; }
wait_for "primary accepts connections" ready primary
wait_for "standby accepts connections" ready standby

[[ $(p "select pg_is_in_recovery()") == "f" ]] || { echo "FAILED: primary is in recovery" >&2; exit 1; }
echo "ok: primary accepts writes"
[[ $(s "select pg_is_in_recovery()") == "t" ]] || { echo "FAILED: standby is not in recovery" >&2; exit 1; }
echo "ok: standby is in recovery (read-only)"

streaming() { [[ $(s "select status from pg_stat_wal_receiver") == "streaming" ]]; }
wait_for "standby WAL receiver is streaming" streaming

p "create table if not exists heartbeat (id bigserial primary key, ts timestamptz default now())" >/dev/null
marker=$(p "insert into heartbeat default values returning id")
replicated() { [[ $(s "select coalesce(max(id), 0) from heartbeat") -ge $marker ]]; }
wait_for "row $marker written on primary is visible on standby" replicated

if s "insert into heartbeat default values" >/dev/null 2>&1; then
  echo "FAILED: standby accepted a write" >&2
  exit 1
fi
echo "ok: standby refuses writes"

echo
echo "Replication seen from the primary:"
docker compose exec -T primary psql -U postgres -d appdb -c \
  "select application_name, state, sync_state,
          pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), replay_lsn)) as replay_lag
     from pg_stat_replication;"
