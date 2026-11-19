# Local DNS cache (Unbound) for chatty servers

## The problem (case study)

Name resolution was moved from standalone DNS servers to DNS servers behind a load balancer.
Afterwards, an ERP platform started failing at peak times: lookups timed out and batch jobs crashed.

Root cause: the ERP back-ends sent a very high rate of DNS queries **from a single IP**.
The load balancer source-NATs each query to a new port; at that rate the **SNAT port pool was
exhausted**, so some queries were silently dropped.

How we proved it: packet captures (`tcpdump -i any port 53`) on the busiest hosts, counting
queries that never got an answer, before and after the fix.

| | before | after |
|---|---|---|
| queries without answer | dozens per 20k | 0 |
| retries to fallback DNS | yes | none |
| job crashes in the window | several | 0 |

## The fix: a local caching resolver

Each server answers repeated lookups from its own cache, so only cache misses leave the host.

```bash
sudo dnf install -y unbound
sudo tee /etc/unbound/conf.d/local-cache.conf >/dev/null <<'EOF'
server:
    interface: 127.0.0.1
    access-control: 127.0.0.0/8 allow
    cache-min-ttl: 60
    prefetch: yes
forward-zone:
    name: "."
    forward-addr: 192.0.2.53      # your upstream DNS
    forward-addr: 192.0.2.54
EOF
sudo unbound-checkconf && sudo systemctl enable --now unbound
dig @127.0.0.1 example.com +short
```

Point the resolver at it (via your config management, not by hand):

```text
# /etc/resolv.conf
nameserver 127.0.0.1
options timeout:1 attempts:3
```

## Don't forget: restart the consumers

Long-running daemons (databases, application servers) read `resolv.conf` **at start-up**.
They keep using the old servers until restarted — plan those restarts like a maintenance window
(see [06](06-erp-maintenance-window.md), standbys first: [05](05-postgresql-standby-restart.md)).

## Measure

```bash
sudo unbound-control stats_noreset | grep -E 'total.num.(queries|cachehits|cachemiss)'
```

A high cache-hit ratio = that much load removed from the central DNS.
