# Role: docker

Installs Docker Engine + the compose v2 plugin from the upstream Docker apt repository, enables the daemon, and pre-pulls `{{ asa_image }}`.

The distro-packaged `docker.io` is too old for `docker compose` (the v2 CLI plugin we drive from cron), so we use Docker's official repo on every supported platform.

## Why pre-pull?

The first `docker compose up` for a freshly-deployed map can hang for several minutes pulling ~5 GB of image layers. Pulling at provision time means the wait happens during `ansible-playbook`, where you can see it, not the first time the watchdog fires.

## Variables

| Variable | Default | Source | Purpose |
|---|---|---|---|
| `asa_image` | `mschnitzer/asa-linux-server:latest` | `group_vars/all.yml` | Image to pull |
