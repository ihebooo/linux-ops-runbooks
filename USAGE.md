# User guide

How to install and use the scripts, plug them into your monitoring, run the lab and use the runbooks.

- [Requirements](#requirements)
- [Install](#install)
- [Exit codes (all scripts)](#exit-codes-all-scripts)
- [disk_check.sh](#disk_checksh--disk-space-and-inodes)
- [cert_expiry_check.sh](#cert_expiry_checksh--certificate-expiry)
- [pg_long_queries.sh](#pg_long_queriessh--long-running-postgresql-sessions)
- [pg_replication_status.sh](#pg_replication_statussh--postgresql-replication)
- [Plug into monitoring](#plug-into-monitoring)
- [PostgreSQL replication lab](#postgresql-replication-lab)
- [Using the runbooks](#using-the-runbooks)
- [Troubleshooting](#troubleshooting)

## Requirements

| Script | Needs |
|---|---|
| `disk_check.sh` | Bash 4+, GNU coreutils (`df`, `join`, `sort`), `awk` |
| `cert_expiry_check.sh` | Bash 4+, `openssl`, `timeout` |
| `pg_long_queries.sh`, `pg_replication_status.sh` | Bash 4+, `psql` client, a role with `pg_monitor` (or superuser) |
| Lab | Docker with Compose v2 |

Tested on Ubuntu (CI); written for RHEL / Rocky / Alma / Debian as well.

## Install

Whole repository:

```bash
git clone https://github.com/ihebooo/linux-ops-runbooks.git
cd linux-ops-runbooks
./scripts/disk_check.sh
```

Or just one script, system-wide:

```bash
sudo curl -fsSL -o /usr/local/bin/disk_check.sh \
  https://raw.githubusercontent.com/ihebooo/linux-ops-runbooks/v0.1.0/scripts/disk_check.sh
sudo chmod 755 /usr/local/bin/disk_check.sh
```

Pin a release tag (`v0.1.0`) rather than `main` on servers, so updates are a deliberate choice.

## Exit codes (all scripts)

Same convention as Nagios / Icinga / Zabbix checks:

| Code | Meaning |
|---|---|
| `0` | OK |
| `1` | WARNING |
| `2` | CRITICAL (or target unreadable) |
| `3` | bad arguments / usage |

So `if ! disk_check.sh; then ...` works, and so does any monitoring agent that reads exit codes.

---

## disk_check.sh — disk space and inodes

Checks every **local** filesystem (tmpfs, devtmpfs, squashfs and overlay are skipped) for space **and**
inode usage, and reports the worse of the two. A disk can be "full" with free space left when it holds
millions of tiny files — that is the inode case.

```text
disk_check.sh [-w WARN%] [-c CRIT%] [-j|--json]
```

| Option | Default | Meaning |
|---|---|---|
| `-w` | `80` | warning threshold in % |
| `-c` | `90` | critical threshold in % (must be greater than `-w`) |
| `-j`, `--json` | off | one JSON object instead of the table |

Table output:

```text
$ ./scripts/disk_check.sh -w 80 -c 90
STATUS   MOUNT                           SPACE INODES
OK       /                                 42%    12%
WARN     /var                              85%    20%
$ echo $?
1
```

JSON output (for scripts and monitoring):

```json
{"host":"srv1","warn":80,"crit":90,"status":"WARN",
 "filesystems":[{"mount":"/","space_pct":42,"inode_pct":12,"status":"OK"},
                {"mount":"/var","space_pct":85,"inode_pct":20,"status":"WARN"}]}
```

```bash
# only the filesystems that are not OK
./scripts/disk_check.sh --json | jq -r '.filesystems[] | select(.status != "OK") | "\(.mount) \(.space_pct)%"'
```

Next step when it fires: [runbook 01 — Filesystem almost full](runbooks/01-filesystem-full.md).

---

## cert_expiry_check.sh — certificate expiry

Shows how many days are left on TLS certificates — of live endpoints (`host:port`) or of PEM files on disk.

```text
cert_expiry_check.sh [-d DAYS] target...
```

| Option | Default | Meaning |
|---|---|---|
| `-d` | `30` | warn when a certificate expires within this many days |
| `target` | — | `host:port` (e.g. `example.com:443`) or a path to a `.pem` / `.crt` file; several allowed |

```bash
./scripts/cert_expiry_check.sh -d 30 example.com:443 mail.example.com:993 /etc/pki/tls/certs/app.pem
```

- `1` (WARNING): at least one certificate expires within `DAYS`.
- `2` (CRITICAL): one has expired, or could not be read (wrong port, firewall, not a certificate).
- SNI is sent automatically, so virtual hosts on a shared IP are checked correctly.

Next step when it fires: [runbook 02 — SSL/TLS certificate renewal](runbooks/02-ssl-certificate-renewal.md).

---

## pg_long_queries.sh — long-running PostgreSQL sessions

Lists sessions whose **query** or **open transaction** is older than N minutes, with what they wait on
and which sessions block them. An old open transaction (often `idle in transaction`) is worth finding
even when it does nothing: it holds locks and stops VACUUM from cleaning up.

```text
pg_long_queries.sh [-m MINUTES] [psql connection options...]
```

`-m` (default `60`) must come **first**; everything after it is passed to `psql`.

```bash
./scripts/pg_long_queries.sh -m 30 -h db.example.com -U monitor -d appdb

# or with the usual libpq environment variables
PGHOST=db.example.com PGUSER=monitor PGDATABASE=appdb ./scripts/pg_long_queries.sh -m 30
```

Columns: `pid`, `user`, `state`, `waiting_on`, `running_for`, `in_xact_for`, `blocked_by` (PIDs),
`query` (first 80 characters).

To stop one (check with the owner first): `select pg_cancel_backend(<pid>);` cancels the query,
`select pg_terminate_backend(<pid>);` ends the session.
See [runbook 09 — Long-running database job](runbooks/09-long-running-db-jobs.md).

The monitoring role needs: `create role monitor login password '...' in role pg_monitor;`

---

## pg_replication_status.sh — PostgreSQL replication

Detects whether the server is a primary or a standby and shows the matching view.

```bash
./scripts/pg_replication_status.sh -h db1.example.com -U monitor -d postgres
```

On a **primary** — one line per connected standby:

```text
Role: PRIMARY
 application_name | client_addr  |   state   | sync_state | replay_lag
 standby1         | 192.0.2.21   | streaming | async      | 0 bytes
```

On a **standby** — the WAL receiver:

```text
Role: STANDBY
  status   | sender_host | sender_port | last_msg_ago | replay_delay
 streaming | 192.0.2.20  |        5432 | 00:00:01     | 00:00:00
```

What to look at: `state` / `status` must be `streaming`; `replay_lag` and `replay_delay` should stay
small. A standby missing from the primary's list, or a status other than `streaming`, means replication
is broken. `replay_delay` also grows when the primary simply has no writes — compare with `last_msg_ago`.

---

## Plug into monitoring

**cron + mail** — alert only when something is wrong:

```cron
# /etc/cron.d/ops-checks
*/15 * * * * root /usr/local/bin/disk_check.sh -w 85 -c 95 >/tmp/disk_check.out || mail -s "disk $(hostname)" ops@example.com </tmp/disk_check.out
0 8 * * *    root /usr/local/bin/cert_expiry_check.sh -d 30 example.com:443 >/tmp/cert.out || mail -s "certs" ops@example.com </tmp/cert.out
```

**Zabbix agent** — return the JSON and use dependent items / JSONPath preprocessing:

```ini
# /etc/zabbix/zabbix_agentd.d/ops-checks.conf
UserParameter=ops.disk.json,/usr/local/bin/disk_check.sh --json; true
```

The trailing `; true` keeps the agent from treating WARN/CRIT exit codes as an item error; trigger on
`$.status` instead.

**Nagios / Icinga / NRPE** — the exit codes already follow the plugin convention:

```ini
command[check_disk_ops]=/usr/local/bin/disk_check.sh -w 85 -c 95
command[check_certs]=/usr/local/bin/cert_expiry_check.sh -d 21 example.com:443
```

**Prometheus (node_exporter textfile collector)**:

```bash
/usr/local/bin/disk_check.sh --json \
  | jq -r '.filesystems[] | "ops_disk_used_percent{mount=\"\(.mount)\",type=\"space\"} \(.space_pct)\nops_disk_used_percent{mount=\"\(.mount)\",type=\"inodes\"} \(.inode_pct)"' \
  > /var/lib/node_exporter/textfile/ops_disk.prom.tmp \
  && mv /var/lib/node_exporter/textfile/ops_disk.prom.tmp /var/lib/node_exporter/textfile/ops_disk.prom
```

---

## PostgreSQL replication lab

A primary and a standby on your own machine, to practise without touching a real server.

```bash
cd labs/postgres-replication
docker compose up -d --wait    # start primary (:5432) and standby (:5433)
./verify.sh                    # prove replication works
./failover.sh                  # kill the primary, promote the standby
docker compose down -v         # remove everything
```

Exercises (lag, long queries, restarts) and how it works: [labs/postgres-replication](labs/postgres-replication/).
Lab only — simple passwords, ports bound to `127.0.0.1`.

---

## Using the runbooks

Each runbook in [`runbooks/`](runbooks/) is a numbered list of steps, from **confirming the problem** to
**closing the loop** (verify, document, close the ticket). Commands use placeholders (`example.com`, `192.0.2.x`, `appdb`):
replace them with your values and read each step before running it — they are written for an operator,
not to be pasted blindly.

Copy them into your own wiki and adapt them to your environment — that is what the MIT license is for.

---

## Troubleshooting

| Symptom | Cause / fix |
|---|---|
| `Permission denied` when running a script | `chmod +x scripts/*.sh`, or run it with `bash scripts/<name>.sh` |
| `$'\r': command not found` | the file got Windows line endings — `sed -i 's/\r$//' script.sh` (the repo itself enforces LF) |
| `disk_check.sh` shows no filesystems | only local filesystems are checked; NFS/CIFS mounts are skipped on purpose (`df -l`) |
| `cert_expiry_check.sh` says `cannot read certificate` | port closed or filtered, not TLS on that port, or STARTTLS protocol (SMTP 25/587) — test with `openssl s_client -connect host:port` |
| `psql: FATAL: no pg_hba.conf entry` | the monitoring host is not allowed — see [runbook 11](runbooks/11-postgresql-access-pg_hba.md) |
| PostgreSQL columns empty or `<insufficient privilege>` | the role is missing `pg_monitor` |
| Exit code `3` | wrong options — the usage line is printed, and is also at the top of each script |

Found a bug or have an idea? [Open an issue](https://github.com/ihebooo/linux-ops-runbooks/issues).
