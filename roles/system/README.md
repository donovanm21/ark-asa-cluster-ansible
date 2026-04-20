# Role: system

Lifecycle automation — what makes the cluster self-sustaining once deployed.

## What it installs

Under `{{ asa_home }}/bin/`:

- `asa_rcon.sh` — wrapper that runs an RCON command against one map or `@all`. Reads passwords from the per-map env files; uses the `outdead/rcon` Docker image as a one-shot client.
- `asa_dino_wipe.sh` — invoked by the dino-wipe cron; sends `destroywilddinos` and a list of fertilized-egg `destroyall` commands via `asa_rcon.sh`.
- `asa_map_start.sh` — invoked at `@reboot`, runs `docker compose up -d` for every configured map with a 30 s stagger.
- `asa_watchdog.sh` — invoked every `watchdog_interval_minutes` (default 5), checks `docker inspect` for each map's container and brings any dead one back up.
- `asa_update_checker.sh` — hourly cron, runs `docker pull` and triggers `asa_system_update.sh` if the image digest changed.
- `asa_system_update.sh` — daily restart-update: broadcast → RCON saveworld + doexit → compose down → tar saves → docker pull → staggered start.

Under `{{ asa_home }}/backups/`:

- `cluster_<date>.tar` and `<map>_saves_<date>.tar` — daily snapshots written by the system update.

Under `/etc/logrotate.d/asa`:

- Rotates each map's `server-files/ShooterGame/Saved/Logs/*.log` daily (14 days, compressed).

## Cron schedule

```
@reboot                                  asa_map_start.sh         # boot-time startup
59 * * * *                               asa_update_checker.sh    # hourly image-update check
*/5 * * * *                              asa_watchdog.sh          # crash recovery (5 min)
30 (update_hour-1) * * *                 asa_system_update.sh     # daily restart + pull
30/45/55 (wipe_hour-1) + 0 wipe_hour     dino-wipe broadcasts + wipe (optional)
```

## Variables

| Variable | Default | Purpose |
|---|---|---|
| `enable_daily_restart` | `true` | Daily restart + image pull |
| `daily_update_hour` | `4` | Hour (24h) at which the daily pipeline runs |
| `enable_dino_wipe` | `false` | Scheduled wild dino wipes |
| `dino_wipe_hours` | `[0, 12]` | Hours at which wild dinos are wiped |
| `enable_watchdog` | `true` | Crash-recovery cron |
| `watchdog_interval_minutes` | `5` | How often the watchdog runs |
| `enable_update_checker` | `true` | Hourly image-update check |
| `asa_rcon_image` | `outdead/rcon:latest` | RCON client image used by the wrapper |

## Watchdog behaviour

1. Skips its own window if `date +%H` is `(daily_update_hour - 1)` or `daily_update_hour` — don't fight the planned stop.
2. For each configured map, runs `docker inspect -f '{{.State.Running}}'` against `asa-<map>`.
3. If not running, posts to Discord (if `discord_webhook_url` is set) and backgrounds `docker compose up -d`.
4. Logs via `logger -t asa-watchdog` to syslog.
