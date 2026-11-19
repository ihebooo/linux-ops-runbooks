# Long-running database job: is it stuck or working?

**Trigger:** "Job X has been running since yesterday, can you check?" — and the business wants
to know whether to wait or kill it.

## 1. Find the backend

```sql
select pid, usename, state, wait_event_type, wait_event,
       now() - query_start   as running_for,
       now() - state_change  as in_state_for,
       left(query, 80)       as query
from pg_stat_activity
where state <> 'idle' or now() - xact_start > interval '1 hour'
order by query_start;
```

`scripts/pg_long_queries.sh` wraps this query.

## 2. Is it progressing?

| Signal | How |
|---|---|
| CPU time increasing | `ps -o pid,etime,time,pcpu -p <pid>` twice, a minute apart |
| I/O happening | `sudo cat /proc/<pid>/io` twice — `read_bytes`/`write_bytes` grow |
| Waiting on a lock | `wait_event_type = 'Lock'` → find the blocker: `select pg_blocking_pids(<pid>);` |
| Idle in transaction | `state = 'idle in transaction'` → the client stopped talking; holds locks |

Report facts, not guesses:

> Job is still running (PID 12345), started 11.11 19:00, ~19 h 40 min. State: active (SELECT).
> CPU time is increasing → it is progressing. Host CPU ~435 %. No lock waits.
> Do you want an intervention, or do we wait?

## 3. If the owner decides to stop it

```sql
select pg_cancel_backend(<pid>);      -- cancel the current query (gentle)
select pg_terminate_backend(<pid>);   -- end the session (if cancel is ignored)
```

If the scheduler restarts the job, ask the job owner to remove it from the schedule first.
Check front-end and back-end for leftover processes afterwards.

## 4. Close the loop

Note in the ticket: PID, runtime, evidence, decision and who decided.
