#!/usr/bin/env bash
# disk_check.sh - report local filesystems above a usage threshold (space or inodes).
#
# Usage: disk_check.sh [-w WARN%] [-c CRIT%] [-j|--json]
#   -j, --json   machine-readable output for monitoring tools (one JSON object)
# Exit:  0 = all OK, 1 = at least one WARNING, 2 = at least one CRITICAL, 3 = bad arguments
set -euo pipefail

warn=80
crit=90
json=0

usage() { echo "Usage: $0 [-w WARN%] [-c CRIT%] [-j|--json]" >&2; exit 3; }

# translate the long option so getopts can handle it
args=()
for a in "$@"; do
  if [[ $a == "--json" ]]; then args+=("-j"); else args+=("$a"); fi
done
set -- "${args[@]+"${args[@]}"}"

while getopts ":w:c:jh" opt; do
  case "$opt" in
    w) warn=$OPTARG ;;
    c) crit=$OPTARG ;;
    j) json=1 ;;
    *) usage ;;
  esac
done

[[ $warn =~ ^[0-9]+$ && $crit =~ ^[0-9]+$ && $warn -lt $crit ]] || usage

json_escape() { local s=${1//\/\\}; printf '%s' "${s//\"/\\\"}"; }

rc=0
items=()
(( json )) || printf '%-8s %-30s %6s %6s\n' STATUS MOUNT SPACE INODES

# -P: POSIX output (one line per fs), -l: local only, skip pseudo filesystems
while read -r mount space inodes; do
  space=${space%\%}
  inodes=${inodes%\%}
  [[ $inodes == "-" ]] && inodes=0
  worst=$(( space > inodes ? space : inodes ))

  status=OK
  if (( worst >= crit )); then
    status=CRIT; rc=2
  elif (( worst >= warn )); then
    status=WARN; (( rc < 1 )) && rc=1
  fi

  if (( json )); then
    items+=("$(printf '{"mount":"%s","space_pct":%d,"inode_pct":%d,"status":"%s"}' \
      "$(json_escape "$mount")" "$space" "$inodes" "$status")")
  else
    printf '%-8s %-30s %5s%% %5s%%\n' "$status" "$mount" "$space" "$inodes"
  fi
done < <(
  join -j 1 \
    <(df -Pl -x tmpfs -x devtmpfs -x squashfs -x overlay | awk 'NR>1 {print $6, $5}' | sort) \
    <(df -Pli -x tmpfs -x devtmpfs -x squashfs -x overlay | awk 'NR>1 {print $6, $5}' | sort)
)

if (( json )); then
  overall=(OK WARN CRIT)
  list=$(IFS=,; echo "${items[*]+"${items[*]}"}")
  printf '{"host":"%s","warn":%d,"crit":%d,"status":"%s","filesystems":[%s]}\n' \
    "$(json_escape "$(hostname)")" "$warn" "$crit" "${overall[$rc]}" "$list"
fi

exit "$rc"
