# Roadmap — one small improvement a day

Each item is small enough for one evening (30–60 min) and is a real improvement, not filler.
Ticked items are done.

## Week 1 — make this repo solid
- [x] Day 1 — runbooks, scripts, PostgreSQL replication lab, CI
- [ ] Day 2 — `disk_check.sh`: `--json` output for monitoring tools + test in CI
- [ ] Day 3 — lab: add a second standby and show `sync_state` (async vs sync with `synchronous_standby_names`)
- [ ] Day 4 — runbook 14: rebuild a failed primary as standby with `pg_rewind` + lab exercise
- [ ] Day 5 — `pg_backup_check.sh`: last successful `pg_dump`/base backup age, exit codes
- [ ] Day 6 — lab: backup & point-in-time recovery (base backup + WAL archive) exercise
- [ ] Day 7 — README: architecture diagram + "how I use this" section; tag `v0.1.0`

## Week 2 — security & certificates
- [ ] Day 8 — `cert_expiry_check.sh`: read targets from a file, CSV output
- [ ] Day 9 — runbook 15: SSH hardening checklist (keys only, `AllowGroups`, fail2ban)
- [ ] Day 10 — `user_audit.sh`: local users with UID ≥ 1000, last login, sudo rights, expired passwords
- [ ] Day 11 — runbook 16: firewalld basics for a new server
- [ ] Day 12 — lab: PostgreSQL with TLS (self-signed CA) + `hostssl` in `pg_hba.conf`
- [ ] Day 13 — runbook 17: OpenSCAP scan and reading the report
- [ ] Day 14 — CI: add `markdownlint` and a link checker for the runbooks

## Week 3 — new repo `ansible-rhel-baseline`
- [ ] Day 15 — repo skeleton, inventory, `ansible-lint` in CI
- [ ] Day 16 — role `common`: timezone, NTP (chrony), packages
- [ ] Day 17 — role `users`: admin group, SSH keys, sudo
- [ ] Day 18 — role `unbound_cache`: local DNS cache (from runbook 07)
- [ ] Day 19 — role `hardening`: sshd config, firewalld, SELinux enforcing
- [ ] Day 20 — Molecule tests on Rocky Linux in CI
- [ ] Day 21 — README with "before/after" and tag `v0.1.0`

## Week 4 — RHCSA notes & monitoring
- [ ] Day 22 — new repo `rhcsa-notes`: structure by exam objective
- [ ] Day 23 — notes: users, groups, permissions, ACLs (+ practice tasks)
- [ ] Day 24 — notes: storage (partitions, LVM, swap, fstab)
- [ ] Day 25 — notes: systemd, journald, tuned, boot targets
- [ ] Day 26 — notes: SELinux and networking (nmcli)
- [ ] Day 27 — new repo `monitoring-stack`: Prometheus + node_exporter + Grafana compose
- [ ] Day 28 — alert rules: disk, cert expiry (blackbox exporter), PostgreSQL up
- [ ] Day 29 — dashboard JSON + screenshots in README
- [ ] Day 30 — pin the best repos, update profile README, write a LinkedIn post about the month
