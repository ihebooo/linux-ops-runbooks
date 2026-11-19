# Experience

## Linux & PostgreSQL System Administrator (2nd level) — since June 2026
*Data-center operations team of a global manufacturing company*

Scope: RHEL server fleet managed with Puppet and Red Hat Satellite, a business-critical ERP platform
on PostgreSQL (front-ends, primary/standby database back-ends, NFS), IBM i systems, ServiceNow ITSM.

### Highlights

- **DNS incident on the ERP platform.** After DNS moved behind a load balancer, ERP batch jobs crashed at peak
  times. Took packet captures on the busiest database hosts and counted unanswered queries before/after the fix
  (dozens per ~20k → 0). Root cause: source-NAT port exhaustion on the load balancer caused by the ERP's
  very high query rate. Fix: local Unbound DNS cache on each server, then planned rolling restarts of all
  database and application daemons, standbys first, masters region by region. → [runbook 07](runbooks/07-dns-local-cache-unbound.md)
- **Global ERP maintenance window.** Took part in an overnight downtime of all production ERP servers to
  install four application packages: scheduler paused, instances locked, installs run per instance,
  install-script warnings reviewed and decided, test protocols collected before reopening. → [runbook 06](runbooks/06-erp-maintenance-window.md)
- **Documentation standard.** My change task for a test-server update was cited by the component owner as the
  example of how every colleague should document steps in a ticket.
- **Database access the right way.** Gave a data platform read-only access to the ERP database; found that two
  generations of servers build `pg_hba.conf` from different templates, applied the rule consistently on all
  cluster nodes and proposed moving the manual rules into configuration management. → [runbook 11](runbooks/11-postgresql-access-pg_hba.md)
- **New site server.** Deployed a Linux automation server for a plant: network/VLAN, forward + reverse DNS
  (caught and corrected a hostname typo in the PTR), admin access via directory groups.
- **Batch-job analysis for the business.** Regularly answer "is this job stuck?" with evidence — backend PID,
  runtime, CPU time trend, lock waits, host load — so the job owner can decide to wait or kill. → [runbook 09](runbooks/09-long-running-db-jobs.md)
- **Everyday operations:** test-instance refreshes from production, SELinux policy modules instead of
  permissive mode, SSH/key-based access with approvals, certificate renewals, IBM i profiles and printers,
  Puppet/Satellite checks.

### Learning plan (in progress)
- Red Hat System Administration (RH124) → RHCSA
- PostgreSQL DBA, Puppet & Git workflow, Red Hat Satellite, Veeam backup, enterprise storage

## Before: software development & AI integration
- Web and mobile applications (JavaScript, Flutter) — see my other repositories.
- Built an AI assistant prototype that connects a large language model to an engineering product-data system.
- Final-year engineering project shortlisted for a company "best final-year project" award.
