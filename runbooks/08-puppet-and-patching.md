# Daily Puppet & patching checks

Configuration management only helps if every node actually applies it.
These are the daily checks I do on a Puppet-managed RHEL fleet.

## 1. Nodes that failed or stopped reporting

```bash
# PuppetDB query (puppet-query from the puppetdb-cli package)
puppet query 'nodes[certname, report_timestamp, latest_report_status] { latest_report_status = "failed" }'
puppet query 'nodes[certname, report_timestamp] { report_timestamp < "2026-01-01T00:00:00Z" }'  # stale nodes
```

On a failed node:

```bash
sudo puppet agent --test --noop      # what would change, which resource fails?
sudo puppet agent --disable --help   # is it disabled on purpose? check the message
cat "$(puppet config print agent_disabled_lockfile)" 2>/dev/null
```

## 2. Certificates

```bash
sudo puppetserver ca list --all | grep -i -E 'expir|revoked'
# re-register a rebuilt node
sudo puppetserver ca clean --certname host.example.com     # on the server
sudo rm -rf /etc/puppetlabs/puppet/ssl && sudo puppet agent -t   # on the node
```

Decommissioned host? Remove it from the CA **and** PuppetDB (`puppet node deactivate`),
and from the patch server / inventory too.

## 3. Hiera changes

- Change data in Hiera, not in modules, for per-node or per-site values.
- Promote the same commit through stages: development → testing → production.
- Some legacy hosts are excluded from a template: if you change one by hand, note it in the ticket
  **and** open a follow-up to bring it into Puppet — manual changes are lost on the next regeneration.

## 4. Patching

```bash
sudo dnf check-update --security
sudo needs-restarting -r ; echo "reboot needed: $?"     # 1 = reboot required
```

- Servers on automatic patching: list the ones that need a reboot and agree a slot with the service owner.
- Servers excluded from auto-patching: patch through a change, with a tested roll-back (snapshot).
