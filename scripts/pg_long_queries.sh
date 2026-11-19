#!/usr/bin/env bash
# pg_long_queries.sh - list PostgreSQL sessions running (or holding a transaction) longer than N minutes.
#
# Usage: pg_long_queries.sh [-m MINUTES] [psql connection options...]
#   e.g. pg_long_queries.sh -m 30 -h db.example.com -U postgres -d appdb
# Uses the normal libpq environment (PGHOST, PGUSER, ...) when no options are given.
set -euo pipefail

minutes=60
if [[ ${1:-} == "-m" ]]; then
  minutes=${2:?missing minutes}
  shift 2
fi
[[ $minutes =~ ^[0-9]+$ ]] || { echo "minutes must be a number" >&2; exit 3; }

psql "$@" -X -v ON_ERROR_STOP=1 -v minutes="$minutes" -P pager=off <<'SQL'
select pid,
       usename                                        as "user",
       state,
       coalesce(wait_event_type || ':' || wait_event, '-') as waiting_on,
       date_trunc('second', now() - query_start)      as running_for,
       date_trunc('second', now() - xact_start)       as in_xact_for,
       pg_blocking_pids(pid)                          as blocked_by,
       left(regexp_replace(query, '\s+', ' ', 'g'), 80) as query
from pg_stat_activity
where pid <> pg_backend_pid()
  and backend_type = 'client backend'
  and (   (state <> 'idle' and now() - query_start > make_interval(mins => :minutes))
       or now() - xact_start > make_interval(mins => :minutes))
order by query_start;
SQL
