# SSL/TLS certificate renewal

**Trigger:** certificate expiry warning, or a change task "renew certificate on host X".

## 1. Find what is about to expire

```bash
# Remote endpoint
echo | openssl s_client -connect host.example.com:443 -servername host.example.com 2>/dev/null \
  | openssl x509 -noout -subject -enddate

# Local files (see scripts/cert_expiry_check.sh for a reusable version)
sudo find /etc/pki /etc/ssl -name '*.crt' -o -name '*.pem' | xargs -I{} sh -c \
  'openssl x509 -in "{}" -noout -enddate 2>/dev/null | sed "s|^|{}: |"'
```

## 2. Create key + CSR

```bash
openssl req -new -newkey rsa:3072 -nodes \
  -keyout host.example.com.key -out host.example.com.csr \
  -subj "/CN=host.example.com" \
  -addext "subjectAltName=DNS:host.example.com,DNS:alias.example.com"
openssl req -in host.example.com.csr -noout -text | grep -A1 "Subject Alternative Name"
```

Always include **all** names clients use in the SAN — modern clients ignore CN.

## 3. Sign it

- Internal service → internal CA (or ACME/SCEP if available).
- Public service → public CA or ACME (`acme.sh`, `certbot`).

## 4. Install and check

```bash
# key and cert must match
openssl x509 -noout -modulus -in new.crt | openssl md5
openssl rsa  -noout -modulus -in new.key | openssl md5

sudo install -m 600 new.key /etc/pki/tls/private/
sudo install -m 644 new.crt /etc/pki/tls/certs/
sudo nginx -t && sudo systemctl reload nginx     # or httpd / the app
```

Then verify from a client with the `openssl s_client` command above (new `notAfter`, full chain).

## 5. Close the loop

- Ticket: old/new expiry date, SANs, where the cert is installed.
- Same cert on several hosts (cluster, load balancer)? Install everywhere before closing.
- Recurring manual renewals → push for automation (ACME/SCEP + config management).
