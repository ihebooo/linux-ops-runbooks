# Roadmap — one small improvement a day

Goal: build small, focused open-source tools for **monitoring and optimizing Linux and
PostgreSQL servers** that any admin can drop in and use, plus the runbooks behind them.

Each item is small enough for one evening (30–60 min) and is a real improvement, not filler.
Ticked items are done. Every new repo gets: MIT license, README with a quick start, CI, and
example output.

## Week 1 — this repo + start `pg-health-report`
- [x] Day 1 — runbooks, scripts, PostgreSQL replication lab, CI
- [x] Day 2 — `disk_check.sh`: `--json` output for monitoring tools + test in CI
- [x] Day 3 — add MIT `LICENSE`, CI badge in README, tag `v0.1.0` with release notes
- [x] Day 4 — new repo `pg-health-report`: skeleton, MIT license, CI with a PostgreSQL 16 service container, `pg_health.sh --help`
- [x] Day 5 — `pg-health-report`: cache hit ratio, connections vs `max_connections`, database sizes (Markdown output)
- [x] Day 6 — `pg-health-report`: table bloat estimate + tables that need `VACUUM`/`ANALYZE` (dead tuples, last autovacuum)
- [x] Day 7 — `pg-health-report`: unused and duplicate indexes, with the space they waste

## Week 2 — finish `pg-health-report`
- [x] Day 8 — `pg-health-report`: top queries from `pg_stat_statements` (total time, calls, mean) when the extension exists
- [x] Day 9 — `pg-health-report`: replication lag, inactive replication slots, transaction ID wraparound age
- [x] Day 10 — `pg-health-report`: each check gets a status (OK / WARN / CRIT) and a "what to do" hint
- [x] Day 11 — `pg-health-report`: `--format html` (single self-contained file) + example report in `docs/`
- [x] Day 12 — `pg-health-report`: CI seeds a demo database with bloat and an unused index and asserts they are reported
- [x] Day 13 — `pg-health-report`: README with screenshot, list of checks, required privileges (`pg_monitor`); tag `v0.1.0`
- [x] Day 14 — new repo [`linux-db-tuning-check`](https://github.com/ihebooo/linux-db-tuning-check): skeleton, MIT license, ShellCheck CI, `--help`

## Week 3 — `linux-db-tuning-check`
- [x] Day 15 — checks: `vm.swappiness`, `vm.dirty_ratio`/`dirty_background_ratio`, overcommit
- [x] Day 16 — checks: Transparent Huge Pages, huge pages vs `shared_buffers`, NUMA
- [x] Day 17 — checks: I/O scheduler per disk, mount options (`noatime`), filesystem type
- [x] Day 18 — checks: ulimits for the DB user, open files, CPU governor / `tuned` profile
- [x] Day 19 — PostgreSQL config advice: `shared_buffers`, `effective_cache_size`, `work_mem`, `max_wal_size` from RAM/CPU, with the reasoning shown
- [x] Day 20 — `--json` output + exit codes, CI runs it in Rocky Linux and Ubuntu containers
- [x] Day 21 — README: every check explained (why it matters, how to fix); tag `v0.1.0`

## Week 4 — `monitoring-in-a-box`
- [x] Day 22 — new repo [`monitoring-in-a-box`](https://github.com/ihebooo/monitoring-in-a-box): Docker Compose with Prometheus, node_exporter, Grafana; CI starts it and checks targets are up
- [x] Day 23 — add postgres_exporter + a demo PostgreSQL; alert rules: PostgreSQL down, replication lag, connections near the limit
- [x] Day 24 — add blackbox_exporter: HTTPS endpoint up + certificate expiry alerts
- [ ] Day 25 — add Alertmanager with an example route (email / webhook), alert rules validated with `promtool` in CI
- [ ] Day 26 — provisioned Grafana dashboards (Linux host + PostgreSQL) committed as JSON
- [ ] Day 27 — README with screenshots and a "monitor your own server in 10 minutes" guide; tag `v0.1.0`

## Week 5 — share and connect
- [ ] Day 28 — new repo `zabbix-templates`: certificate expiry and PostgreSQL replication templates (YAML export) with README
- [ ] Day 29 — new repo `ansible-role-unbound-cache`: local DNS cache role (from runbook 07) with Molecule test in CI
- [ ] Day 30 — profile README: pin the four tools, add "Tools I built" section, link each release

## Every week — done by me, not automated
These carry my name in public, so I write and post them myself:
- one article (LinkedIn / dev.to): e.g. the DNS/SNAT case study, "a PostgreSQL health check in one script"
- one small contribution to an existing open-source project (docs fix, template, issue with a reproduction)
