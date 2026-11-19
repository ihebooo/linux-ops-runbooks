# Add / change / troubleshoot a CUPS printer

## Add or change

```bash
lpinfo -m | grep -i zebra                       # available drivers (or use raw for label printers)
sudo lpadmin -p LBL01 -E -v socket://192.0.2.40:9100 -m raw -D "Label printer, hall 2"
sudo lpadmin -p LBL01 -v socket://192.0.2.41:9100   # IP change
lpstat -p LBL01 -v
```

## Test

```bash
echo "test $(date)" | lp -d LBL01
lpstat -o LBL01                                  # queued jobs
```

## Hanging jobs

```bash
lpstat -o                                        # what is stuck
sudo cupsenable LBL01                            # printer was disabled after an error
cancel -a LBL01                                  # only with the user's OK
sudo tail -50 /var/log/cups/error_log
nc -zv 192.0.2.40 9100                           # can the server reach the printer?
```

Typical causes: printer IP changed, printer offline/paper out, queue disabled after one failed job,
firewall between server and printer VLAN.
