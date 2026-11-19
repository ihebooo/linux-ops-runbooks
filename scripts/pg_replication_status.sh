#!/usr/bin/env bash
# pg_replication_status.sh - show the replication role of a PostgreSQL server and its replication state.
#
# On a primary: lists connected standbys and their lag.
# On a standby: shows the WAL receiver status and replay delay.
#
# Usage: pg_replication_status.sh [psql connection options...]
set -euo pipefail

run() { psql "$@" -X -v ON_ERROR_STOP=1 -P pager=off; }

in_recovery=$(psql "$@" -X -Atc "select pg_is_in_recovery();")

if [[ $in_recovery == "f" ]]; then
  echo "Role: PRIMARY"
  run "$@" <<'SQL'
select application_name,
       client_addr,
       state,
       sync_state,
       pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), replay_lsn)) as replay_lag
from pg_stat_replication
order by application_name;
SQL
else
  echo "Role: STANDBY"
  run "$@" <<'SQL'
select status,
       sender_host,
       sender_port,
       date_trunc('second', now() - last_msg_receipt_time) as last_msg_ago,
       date_trunc('second', now() - pg_last_xact_replay_timestamp()) as replay_delay
from pg_stat_wal_receiver;
SQL
fi
