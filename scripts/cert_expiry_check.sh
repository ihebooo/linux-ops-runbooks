#!/usr/bin/env bash
# cert_expiry_check.sh - warn about TLS certificates that expire soon.
#
# Checks remote endpoints (host:port) and/or local PEM files.
#
# Usage: cert_expiry_check.sh [-d DAYS] target...
#   target = host:port  (e.g. example.com:443)  or  /path/to/cert.pem
# Exit:  0 = all OK, 1 = at least one expires within DAYS, 2 = expired or unreadable
set -euo pipefail

days=30

usage() { echo "Usage: $0 [-d DAYS] host:port|file.pem ..." >&2; exit 3; }

while getopts ":d:h" opt; do
  case "$opt" in
    d) days=$OPTARG ;;
    *) usage ;;
  esac
done
shift $((OPTIND - 1))
(( $# > 0 )) || usage
[[ $days =~ ^[0-9]+$ ]] || usage

get_cert() {
  local target=$1
  if [[ -f $target ]]; then
    cat "$target"
  else
    local host=${target%:*}
    timeout 10 openssl s_client -connect "$target" -servername "$host" </dev/null 2>/dev/null
  fi
}

rc=0
now=$(date +%s)

for target in "$@"; do
  if ! enddate=$(get_cert "$target" | openssl x509 -noout -enddate 2>/dev/null); then
    printf '%-8s %-40s %s\n' ERROR "$target" "cannot read certificate"
    rc=2
    continue
  fi
  enddate=${enddate#notAfter=}
  end=$(date -d "$enddate" +%s)
  left=$(( (end - now) / 86400 ))

  if (( left < 0 )); then
    status=EXPIRED; rc=2
  elif (( left <= days )); then
    status=WARN; (( rc < 1 )) && rc=1
  else
    status=OK
  fi
  printf '%-8s %-40s %5s days  (%s)\n' "$status" "$target" "$left" "$enddate"
done

exit "$rc"
