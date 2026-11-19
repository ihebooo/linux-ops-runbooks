# Restart a PostgreSQL standby (read replica) safely

**Typical reasons:** pick up a changed OS setting (e.g. new `/etc/resolv.conf`), apply a
`postgresql.conf` change that needs a restart, minor version update.

A standby is read-only (reports, analytics), so restarting it has no impact on writes —
but readers lose their sessions for a few seconds. Try it in [the lab](../labs/postgres-replication/).

## 1. Make sure you are on the standby

```bash
sudo -u postgres psql -Atc "select pg_is_in_recovery();"     # t = standby, f = primary!
```

On the primary, check who replicates from it:

```sql
select application_name, client_addr, state, sync_state,
       pg_wal_lsn_diff(pg_current_wal_lsn(), replay_lsn) as lag_bytes
from pg_stat_replication;
```

## 2. (Optional) silence monitoring

Set a short downtime in the monitoring tool so the restart does not page anyone.

## 3. Restart

```bash
sudo systemctl restart postgresql-16        # or: pg_ctl -D "$PGDATA" -m fast restart
sudo systemctl status postgresql-16 --no-pager
```

`-m fast` disconnects clients and stops cleanly — never use `immediate` unless you have to.

## 4. Verify

```bash
# on the standby: still in recovery, WAL receiver streaming again
sudo -u postgres psql -Atc "select pg_is_in_recovery();"
sudo -u postgres psql -c  "select status, sender_host, last_msg_receipt_time from pg_stat_wal_receiver;"

# start time is after your change
sudo -u postgres psql -Atc "select pg_postmaster_start_time();"
```

On the primary, `pg_stat_replication` shows the standby again with `state = streaming`
and the lag going back towards 0.

## 5. Close the loop

Ticket: host, time, reason, `pg_postmaster_start_time()`, replication state after restart.
