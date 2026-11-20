# linux-ops-runbooks

[![CI](https://github.com/ihebooo/linux-ops-runbooks/actions/workflows/ci.yml/badge.svg)](https://github.com/ihebooo/linux-ops-runbooks/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Release](https://img.shields.io/github/v/release/ihebooo/linux-ops-runbooks)](https://github.com/ihebooo/linux-ops-runbooks/releases)

The runbooks, scripts and labs I use as a **2nd-level Linux & PostgreSQL administrator** —
written from real day-to-day operations, made generic (no company names, hosts or data).

👉 **New here? Read the [user guide](USAGE.md)** — install, options, examples, monitoring integration.

👉 What I have actually done with these: [EXPERIENCE.md](EXPERIENCE.md)

## 🚀 Quick start

```bash
git clone https://github.com/ihebooo/linux-ops-runbooks.git && cd linux-ops-runbooks
./scripts/disk_check.sh                          # disk space + inodes, exit 0/1/2
./scripts/cert_expiry_check.sh example.com:443   # days left on a certificate
```

## 📘 Runbooks

| # | Runbook | When |
|---|---|---|
| 01 | [Filesystem almost full](runbooks/01-filesystem-full.md) | monitoring alert, disk > 90 % |
| 02 | [SSL/TLS certificate renewal](runbooks/02-ssl-certificate-renewal.md) | expiry warning, change task |
| 03 | [SSH access request](runbooks/03-ssh-access-request.md) | "give user X access to server Y" |
| 04 | [SELinux custom policy module](runbooks/04-selinux-custom-module.md) | app works only with SELinux off |
| 05 | [Restart a PostgreSQL standby](runbooks/05-postgresql-standby-restart.md) | config change on read replicas |
| 06 | [ERP maintenance window checklist](runbooks/06-erp-maintenance-window.md) | planned downtime, package install |
| 07 | [Local DNS cache with Unbound](runbooks/07-dns-local-cache-unbound.md) | DNS timeouts behind a load balancer |
| 08 | [Daily Puppet & patching checks](runbooks/08-puppet-and-patching.md) | failed runs, certs, reboots |
| 09 | [Long-running database job](runbooks/09-long-running-db-jobs.md) | "is this job stuck?" |
| 10 | [Refresh a test DB from production](runbooks/10-test-db-refresh-from-prod.md) | testers need fresh data |
| 11 | [Read access to PostgreSQL (pg_hba)](runbooks/11-postgresql-access-pg_hba.md) | reporting tool needs data |
| 12 | [CUPS printer](runbooks/12-cups-printer.md) | add / change / stuck print jobs |
| 13 | [IBM i (AS/400) daily ops](runbooks/13-ibm-i-daily-ops.md) | checks, profiles, printers |

## 🧰 Scripts

| Script | What it does |
|---|---|
| [`disk_check.sh`](scripts/disk_check.sh) | local filesystems above a space **or inode** threshold, monitoring-style exit codes, `--json` output |
| [`cert_expiry_check.sh`](scripts/cert_expiry_check.sh) | days left on certificates of endpoints (`host:port`) or PEM files |
| [`pg_long_queries.sh`](scripts/pg_long_queries.sh) | sessions running / in a transaction longer than N minutes, with blockers |
| [`pg_replication_status.sh`](scripts/pg_replication_status.sh) | primary: standbys + lag · standby: WAL receiver + replay delay |

All scripts pass ShellCheck in CI.

## 🧪 Labs

- [**PostgreSQL streaming replication**](labs/postgres-replication/) — primary + hot standby in Docker Compose:
  verify, restart the standby, create lag, fail over, rebuild. Tested end to end in GitHub Actions.

## Routine I follow

**Every day:** monitoring alerts (disk, services, hardware) · certificates close to expiry ·
Puppet failed runs / unregistered nodes · servers waiting for a reboot after patching ·
ERP file systems and daemons · long batch jobs · ticket queue.

**On request:** access (SSH, groups, DB roles) · DNS records · test-from-prod refreshes · printers ·
ERP transports · logs for developers · server deploy / decommission.

**Planned:** maintenance windows · patching of servers excluded from auto-patching · major upgrades.

## License

[MIT](LICENSE) — use, copy and adapt freely. Changes are listed in [CHANGELOG.md](CHANGELOG.md).
