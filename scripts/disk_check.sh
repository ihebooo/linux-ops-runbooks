#!/usr/bin/env bash
# disk_check.sh - report local filesystems above a usage threshold (space or inodes).
#
# Usage: disk_check.sh [-w WARN%] [-c CRIT%]
# Exit:  0 = all OK, 1 = at least one WARNING, 2 = at least one CRITICAL
set -euo pipefail

warn=80
crit=90

usage() { echo "Usage: $0 [-w WARN%] [-c CRIT%]" >&2; exit 3; }

while getopts ":w:c:h" opt; do
  case "$opt" in
    w) warn=$OPTARG ;;
    c) crit=$OPTARG ;;
    *) usage ;;
  esac
done

[[ $warn =~ ^[0-9]+$ && $crit =~ ^[0-9]+$ && $warn -lt $crit ]] || usage

rc=0
printf '%-8s %-30s %6s %6s\n' STATUS MOUNT SPACE INODES

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
  printf '%-8s %-30s %5s%% %5s%%\n' "$status" "$mount" "$space" "$inodes"
done < <(
  join -j 1 \
    <(df -Pl -x tmpfs -x devtmpfs -x squashfs -x overlay | awk 'NR>1 {print $6, $5}' | sort) \
    <(df -Pli -x tmpfs -x devtmpfs -x squashfs -x overlay | awk 'NR>1 {print $6, $5}' | sort)
)

exit "$rc"
