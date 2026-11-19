# Allow an application under SELinux (custom policy module)

**Trigger:** an application works with `setenforce 0` but fails in enforcing mode
(example: a web app that runs a helper binary from PHP).

**Rule:** never leave SELinux permissive as the "fix". Build a minimal module instead.

## 1. Reproduce and capture denials

```bash
getenforce                                    # must be Enforcing
sudo ausearch -m AVC,USER_AVC -ts recent      # trigger the feature first
sudo ausearch -m AVC -ts recent | audit2why   # why was it denied?
```

Check booleans first — often there is already a switch:

```bash
getsebool -a | grep httpd
sudo setsebool -P httpd_can_network_connect on    # example
```

Wrong file label? Fix the context, not the policy:

```bash
sudo semanage fcontext -a -t httpd_sys_content_t '/srv/app(/.*)?'
sudo restorecon -Rv /srv/app
```

## 2. Generate, review, install a module

```bash
sudo ausearch -m AVC -ts recent | audit2allow -m app_local > app_local.te
cat app_local.te                              # READ IT: only the rules you expect
checkmodule -M -m -o app_local.mod app_local.te
semodule_package -o app_local.pp -m app_local.mod
sudo semodule -i app_local.pp
sudo semodule -l | grep app_local
```

## 3. Verify

- Test the feature again in **enforcing** mode.
- `sudo ausearch -m AVC -ts recent` shows no new denials.
- Ask the requester to confirm, then close.

## 4. Close the loop

Store the `.te` file in version control / config management so the module is reproducible on rebuilds.
