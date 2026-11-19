# Maintenance window for a database-backed ERP platform

Generic checklist for a planned downtime on a classic ERP stack:
**application front-ends** (user sessions, print/interface daemons) + **database back-ends**
(primary + standby) + shared NFS. Used for package installs, OS/DB updates and restarts.

## Before (days ahead)

- [ ] Change approved, downtime announced to business (date, time zone, affected sites).
- [ ] Backups of all affected databases verified (restore point exists and is recent).
- [ ] Batch-job owners agree: which scheduled jobs may be paused, which must finish.
- [ ] Runbook and roll-back plan written in the change ticket; team call scheduled.

## 1 hour before

- [ ] Monitoring downtime set for all hosts (+ buffer before/after).
- [ ] Application health checks disabled (avoid false alarms).
- [ ] Snapshot of process lists for troubleshooting: `ps -ef > /tmp/ps.$(hostname).before.txt`
- [ ] Scheduler paused: automatic jobs switched to "paused" so no new long job starts.

## 5 minutes before

- [ ] No batch job still running — if one is, ask its owner whether it can be killed.
- [ ] Interfaces paused (EDI, cutting-room/CAD connectors, etc.) via their stop flags.

## Downtime

1. **Lock the application** — no new logins; kill remaining user sessions until the count is 0.
2. **Stop application daemons** on front-ends and back-ends; check no process is left.
3. **Do the work** (package install / update / restart databases).
   - Restart DBs one instance at a time; check each one comes back (`pg_isready`, logs).
   - Service IPs bound again? Replication streaming again?
4. **Start daemons** in the right order (DB → server daemons → scheduler → GUI/front-end).
5. **Resume** the scheduler (paused → automatic) and remove interface stop flags.
6. **Unlock the application.** Re-enable health checks.

## After

- [ ] Key users / application team test and confirm (test protocols attached to the change).
- [ ] Monitoring downtime removed; no new alerts.
- [ ] Change ticket documented step by step (who, what, when, result) — detailed tickets
      make the next window faster and are easy to audit.
- [ ] Closure mail to the distribution list: done, tested, production reopened.

## Lessons I keep

- Pause the scheduler **an hour** early — the job that blocks a downtime is the one that started 5 min before.
- Install scripts that stop on "possible error lines" need a human decision: read the log, decide
  *ignore / continue / abort*, and write the decision in the ticket.
- Restarts are not "no-ops": check every daemon and every replica afterwards.
