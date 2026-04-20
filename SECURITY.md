# Security notes

## What this playbook does that you should know about

### NOPASSWD sudo for the asa user

`roles/provision` creates `/etc/sudoers.d/asa` with:

```
asa ALL=(ALL) NOPASSWD: ALL
```

The lifecycle scripts under `~asa/bin/` invoke `docker compose` and `crontab`, both of which need broad privilege. NOPASSWD removes an interactive prompt from automated crons.

If your site has its own sudoers management, set `manage_sudoers: false` in `group_vars/gameservers.yml`.

### Docker group membership

`roles/provision` adds the `asa` user to the `docker` group so the cron jobs can run `docker compose` without `sudo`. This is functionally equivalent to root: anyone with `asa` shell access can launch privileged containers and bind-mount the host filesystem. Treat the asa user as a privileged account.

If you'd rather not, set `manage_docker_group: false` and edit the rendered crontab to call `sudo docker compose ...`.

### UFW removal

`roles/provision` apt-removes UFW. This is legacy behaviour retained so existing deployments don't suddenly block game traffic on upgrade.

If you manage your own firewall (UFW, nftables, hardware firewall), set `manage_firewall: false`. Required open ports per map:

- `map_game_port` (UDP, e.g. 7777) — game traffic
- `map_query_port` (UDP, e.g. 27015) — Steam server query
- `map_rcon_port` (TCP, e.g. 27020) — RCON; internal only unless you're RCON'ing from off-box

### The playbook runs with `become: true`

`main.yml` uses `connection: local` and `become: true`, writing to `/etc/sudoers.d/`, `/etc/asa-cluster/`, `/etc/logrotate.d/`, and `/home/asa/`. It's expected to run on the target host as root (or via sudo).

### Container image trust

The default image is `mschnitzer/asa-linux-server:latest` from Docker Hub. It's a community image — you're trusting its maintainer with code that runs as the `asa` user inside the container. Pin to a specific digest in `group_vars/all.yml` (`asa_image: mschnitzer/asa-linux-server@sha256:...`) for reproducibility and to opt out of surprise upgrades.

## Reporting a vulnerability

Open a private security advisory on the repository, or email the maintainer directly. Do not disclose in a public channel first.

## What you should check before going public

- **`map_admin_password`** in `group_vars/gameservers.yml` — never commit. The file is gitignored.
- **`/etc/asa-cluster/env/<map>.env`** on the host — contains the same admin password. Mode 0600.
- **Discord webhook URL** — if posted publicly, anyone can spam your channel. Store in `gameservers.yml`, not in a tracked file.
- **CI deploy secrets** — any SSH key that grants root on your ASA host. Treat the repo's admin access accordingly.

## Known limitations

- No encryption at rest for save files.
- No log shipping — logs live on disk under `~asa/instances/<map>/server-files/ShooterGame/Saved/Logs/`, rotated by `logrotate`.
- No RBAC — anyone with the admin password can cheat on the server.
