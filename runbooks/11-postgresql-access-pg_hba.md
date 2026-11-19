# Give an application read access to PostgreSQL

**Trigger:** "Tool X (reporting / data platform) needs read access to database Y."

## 1. Role with only what is needed

```sql
create role report_ro login password '…' connection limit 5;
grant connect on database appdb to report_ro;
\c appdb
grant usage on schema public to report_ro;
grant select on all tables in schema public to report_ro;
alter default privileges in schema public grant select on tables to report_ro;
```

Prefer one role per consuming application — easy to audit and to remove.

## 2. Allow the connection in `pg_hba.conf`

```text
# TYPE  DATABASE  USER       ADDRESS          METHOD
host    appdb     report_ro  198.51.100.20/32 scram-sha-256
```

```bash
sudo -u postgres psql -c "select pg_reload_conf();"
sudo -u postgres psql -c "select * from pg_hba_file_rules where user_name @> '{report_ro}';"
```

## 3. Keep config management the source of truth

- If `pg_hba.conf` is generated (Puppet/Ansible template), add the rule **to the template**,
  promote it through the stages, then regenerate — and check the diff is only your line.
- If a host is an exception and you must edit by hand: do it on **every** cluster node
  (primary and standbys — after a failover the standby becomes primary), note it in the ticket,
  and open a follow-up to move the rule into the template.

## 4. Test from the client side

```text
JDBC URL:     jdbc:postgresql://db.example.com:5432/appdb
Driver class: org.postgresql.Driver      <- a common mistake is putting the connection name here
```

```bash
psql "host=db.example.com dbname=appdb user=report_ro" -c "select 1;"
```
