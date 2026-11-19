# Refresh a test database from production

**Trigger:** "Please refresh TEST from PROD for stock-take testing."

## 1. Agree first

- Which instance, which date/time of data, how long TEST may be unavailable.
- Anything to keep on TEST (users, config tables)? Anything to anonymise?
- Testers informed that their test data will be overwritten.

## 2. Copy

Logical copy (small/medium DBs):

```bash
pg_dump  -h prod-db -U backup -Fc -d appdb -f /backup/appdb_$(date +%F).dump
dropdb   -h test-db -U postgres --if-exists appdb_test
createdb -h test-db -U postgres -O app appdb_test
pg_restore -h test-db -U postgres -d appdb_test --no-owner -j 4 /backup/appdb_$(date +%F).dump
```

Physical copy (large DBs): restore from the latest base backup + WAL to the test host
(`pg_basebackup` or your backup tool), then start it as a standalone primary.

## 3. Make TEST safe

- Re-apply test-only settings: connection strings, mail relay, interface endpoints pointing to **test** systems.
- Disable jobs that would send real messages (EDI, mail, printing to production printers).
- Reset passwords / grants that must differ from production.
- Copy the application's file area too if the app stores files beside the DB.

## 4. Verify and hand over

```bash
psql -h test-db -d appdb_test -c "select count(*) from <a big table>;"   # compare with prod
```

Tell the requester: *"`<instance>` on TEST refreshed from production (data as of <time>), available for testing."*
