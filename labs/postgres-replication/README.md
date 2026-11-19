# PostgreSQL streaming replication lab

A primary and a hot standby in Docker Compose, to practise the things I do on real
database servers: check replication, restart a standby, fail over, rebuild.

```text
 ┌──────────────┐   WAL stream (slot standby1)   ┌──────────────┐
 │   primary    │ ─────────────────────────────▶ │   standby    │
 │ read / write │                                │  read only   │
 │ :5432        │                                │ :5433        │
 └──────────────┘                                └──────────────┘
```

Tested on every push by GitHub Actions (start → verify → restart standby → verify → fail over).

## Start

```bash
cd labs/postgres-replication
docker compose up -d --wait
./verify.sh
```

`verify.sh` checks the roles, waits for `pg_stat_wal_receiver.status = streaming`,
writes a row on the primary, waits until the standby has it, and checks that the standby refuses writes.

## Exercises

1. **Watch replication** — `../../scripts/pg_replication_status.sh -h 127.0.0.1 -p 5432 -U postgres`
   (password `postgres`), then the same on port 5433.
2. **Restart the standby** (what you do after a config / resolv.conf change):
   `docker compose restart standby && ./verify.sh` — see [runbook 05](../../runbooks/05-postgresql-standby-restart.md).
3. **Create lag** — `docker compose pause standby`, insert rows on the primary, look at `replay_lag`,
   then `docker compose unpause standby` and watch it catch up.
4. **Find a long query** — open a session on the primary and run `select pg_sleep(600);`,
   then `../../scripts/pg_long_queries.sh -m 0 -h 127.0.0.1 -U postgres -d appdb`.
5. **Fail over** — `./failover.sh` stops the primary and promotes the standby.
6. **Rebuild** — `docker compose down -v && docker compose up -d --wait`.

## How it works

- `primary-init.sh` creates the `replicator` role and adds a `replication` line to `pg_hba.conf`
  (the `all` keyword does not cover replication connections).
- `standby-entrypoint.sh` clones the primary once with `pg_basebackup -R -C -S standby1`
  (`-R` writes `standby.signal` + `primary_conninfo`, `-C -S` creates a replication slot), then starts PostgreSQL.

> Lab only: simple passwords, ports bound to `127.0.0.1`.
