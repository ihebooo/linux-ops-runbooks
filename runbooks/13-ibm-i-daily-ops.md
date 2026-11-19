# IBM i (AS/400) – daily operations cheat sheet

Many manufacturing ERPs still run on IBM i. These are the CL commands I use most.

## Daily checks

| Check | Command |
|---|---|
| System operator messages waiting for a reply | `DSPMSG QSYSOPR` |
| Active jobs / stuck batch jobs | `WRKACTJOB SBS(QBATCH)` |
| Job queues | `WRKJOBQ` |
| Output queues / spool | `WRKOUTQ`, `WRKSPLF` |
| Disk usage | `WRKSYSSTS` (% system ASP used) |
| Printer writers | `WRKWTR` — a stopped writer = nothing prints |

## User profile requests

```text
WRKUSRPRF USRPRF(JDOE)                                  /* status, last sign-on */
CHGUSRPRF USRPRF(JDOE) PASSWORD(xxxxxxxx) PWDEXP(*YES)  /* reset: user must change at sign-on */
CHGUSRPRF USRPRF(JDOE) STATUS(*ENABLED)                 /* re-enable after too many attempts */
CHGUSRPRF USRPRF(JDOE) LMTCPB(*NO)                      /* allow command line (only if approved) */
```

Good practice for password resets:
- always set `PWDEXP(*YES)` so the temporary password is changed at first sign-on;
- send the temporary password through a separate channel from the user name;
- never reuse a predictable pattern (e.g. a date) as the temporary password.

## Printer on IBM i

```text
WRKDEVD DEVD(PRT01)         /* check IP / config */
STRPRTWTR DEV(PRT01)        /* writer stopped -> start it */
```
