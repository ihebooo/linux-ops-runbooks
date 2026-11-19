# Filesystem almost full

**Trigger:** monitoring alert such as `FS [/var]: Space is critically low (used > 90%)`.
**Goal:** free or add space before the service fails, and find out *why* it grew.

## 1. Confirm and size the problem

```bash
df -hT /var                       # usage + filesystem type
df -i /var                        # inodes can run out too
sudo du -xh --max-depth=2 /var 2>/dev/null | sort -h | tail -20
```

`-x` keeps `du` on one filesystem, so mounted NFS shares do not pollute the result.

## 2. Quick, safe wins

| Where | Command | Notes |
|---|---|---|
| Package cache | `sudo dnf clean all` | Only cached metadata/RPMs. Check `keepcache` in `/etc/dnf/dnf.conf`. |
| Journal | `sudo journalctl --vacuum-size=200M` | Keeps the newest 200 MB. |
| Rotated logs | `sudo find /var/log -name '*.gz' -mtime +30 -delete` | Only compressed, old files. |
| Core dumps | `sudo coredumpctl list` / `ls /var/lib/systemd/coredump` | Tell the app owner before deleting — they may need them. |

## 3. Deleted-but-open files

Space is not freed while a process still holds a deleted file:

```bash
sudo lsof +L1 | sort -k7 -n | tail
```

Restart (or ask the owner to restart) the process, or truncate the file through `/proc/<pid>/fd/<fd>`.

## 4. Extend with LVM (if growth is legitimate)

```bash
sudo vgs                                   # free space in the volume group?
sudo lvextend -r -L +5G /dev/<vg>/<lv>     # -r grows the filesystem too (xfs/ext4)
```

No free extents → add a disk (`pvcreate`, `vgextend`) or request storage.

## 5. Close the loop

- Write in the ticket: usage before/after, what was removed or extended, root cause.
- Growth not normal (runaway log, debug trace left on)? Inform the application owner.
- Recurring? Fix the cause (log rotation, `keepcache=False`, a cron cleanup) instead of extending again.
