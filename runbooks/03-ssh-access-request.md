# SSH access request for a Linux server

**Trigger:** request "give user X access to server Y".

## 1. Collect before doing anything

1. **Approval** from the server/application owner or the user's team lead.
2. **Which account / role** is needed (personal login, shared service account, admin with sudo).
3. For key-based access: the user's **public** key in OpenSSH format (`ssh-ed25519 …` or `ssh-rsa …`).
   Never accept or handle a private key.

Message template:

> I'm handling your request for SSH access to `<server>`. Please send me:
> 1. your **public** SSH key (generated with PuTTYgen or `ssh-keygen -t ed25519`, protected by a passphrase) — never the private key;
> 2. confirmation from your team lead of the account you need.

## 2a. Directory-based access (preferred)

If servers are joined to AD/LDAP (SSSD), access is a group membership, not a local user:

```bash
id username                                  # does the server see the user and groups?
sudo sss_cache -E                            # flush cache after a group change
grep -E '^(simple_allow_groups|access_provider)' /etc/sssd/sssd.conf
```

Add the user to the right access group in the directory; no change on the server.
Don't create local users by hand where configuration management owns them.

## 2b. Key-based access for a shared/service account

```bash
sudo install -d -m 700 -o svcuser -g svcuser ~svcuser/.ssh
echo 'ssh-ed25519 AAAA… user@laptop' | sudo tee -a ~svcuser/.ssh/authorized_keys
sudo chmod 600 ~svcuser/.ssh/authorized_keys
sudo chown svcuser:svcuser ~svcuser/.ssh/authorized_keys
sudo restorecon -Rv ~svcuser/.ssh            # SELinux labels
```

## 3. Test and troubleshoot

```bash
ssh -v svcuser@server                        # from the user side
sudo journalctl -u sshd --since "-10 min"    # "Connection closed" after password = check sssd/access rules
sudo tail -f /var/log/secure
```

## 4. Close the loop

- Ticket: who, which server, which account, approval reference.
- Removal: same path in reverse (group removal or delete the key line).
