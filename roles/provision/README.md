# Role: provision

Bootstraps the target host for running ASA containers:

1. Installs base dependencies: `htop`, `git`, `curl`, `lsof`, `bzip2`, `ca-certificates`, `jq`, `tar`.
2. Creates the asa server user (`{{ asa_user }}`, default `asa`) with home `{{ asa_home }}`, pinned to uid/gid 25000 so its uid matches the container's internal `gameserver` user.
3. Drops a NOPASSWD sudo rule into `/etc/sudoers.d/{{ asa_user }}` (gated on `manage_sudoers`).
4. Purges UFW (gated on `manage_firewall`).

The `asa` user is added to the `docker` group by the `docker` role (after `docker-ce` installs and creates the group).

## Why uid 25000?

The `mschnitzer/asa-linux-server` image runs as an internal user `gameserver` (uid 25000). All host bind-mounts (`{{ asa_data_root }}/<map>/`) must be owned by uid 25000 or the server can't read/write `/home/gameserver` inside the container. Pinning the host `asa` user to uid 25000 makes the mapping 1:1 and avoids needing user-namespace remapping.

## Variables

| Variable | Default | Source | Purpose |
|---|---|---|---|
| `asa_user` | `asa` | `group_vars/all.yml` | System user that owns the install |
| `asa_home` | `/home/{{ asa_user }}` | `group_vars/all.yml` | Home directory |
| `manage_sudoers` | `true` | `defaults/main.yml` | Create `/etc/sudoers.d/<asa_user>` NOPASSWD entry |
| `manage_docker_group` | `true` | `defaults/main.yml` | Add `asa` to the `docker` group |
| `manage_firewall` | `true` | `defaults/main.yml` | Apt-remove UFW (legacy default) |
