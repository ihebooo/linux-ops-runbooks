# Changelog

All notable changes to this project. Format: [Keep a Changelog](https://keepachangelog.com/),
versions: [Semantic Versioning](https://semver.org/).

## [0.1.0] — 2026-11-20

First release.

### Added
- 13 runbooks from day-to-day Linux & PostgreSQL operations: full filesystem, SSL renewal,
  SSH access, SELinux modules, standby restart, ERP maintenance window, local DNS cache
  (Unbound), Puppet & patching, long-running DB jobs, test DB refresh, `pg_hba` read access,
  CUPS printers, IBM i daily ops.
- Scripts with monitoring-style exit codes (0 OK / 1 WARN / 2 CRIT / 3 bad arguments):
  - `disk_check.sh` — space **and** inode usage, `--json` output
  - `cert_expiry_check.sh` — days left on endpoint or PEM certificates
  - `pg_long_queries.sh` — long sessions/transactions with blockers
  - `pg_replication_status.sh` — primary/standby view with lag
- PostgreSQL 16 primary/standby lab (Docker Compose): streaming replication,
  verification script and failover with `pg_promote()`.
- CI: ShellCheck, script tests (including JSON validation), and the replication lab
  (start → verify → restart standby → verify → failover) on every push.
- MIT license.

[0.1.0]: https://github.com/ihebooo/linux-ops-runbooks/releases/tag/v0.1.0
