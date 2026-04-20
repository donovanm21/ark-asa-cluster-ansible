# Role: maps

Renders per-map docker-compose + env files and per-map config files for ASA:

- `{{ asa_compose_dir }}/<map>.yml` — docker-compose definition (image, ports, volumes, start params)
- `{{ asa_env_dir }}/<map>.env` — passwords and per-map identity (mode 0600)
- `{{ asa_data_root }}/<map>/server-files/ShooterGame/Saved/Config/WindowsServer/GameUserSettings.ini`
- `{{ asa_data_root }}/<map>/server-files/ShooterGame/Saved/Config/WindowsServer/Game.ini`
- `{{ asa_data_root }}/<map>/server-files/ShooterGame/Saved/AllowedCheaterSteamIDs.txt`
- Brings each map's container up via `docker compose up -d`

ASA's built-in mod system downloads CurseForge mods on container start when `map_mods_enabled` is set; no separate update step is required.

## Required variables

Set in `group_vars/gameservers.yml` (see [docs/examples/](../../docs/examples/) for full examples):

- `location`, `server_tag`, `server_mode` (`PvE` or `PvP`)
- `maps:` list, each entry with `map_name_ark` (UE map name, e.g. `TheIsland_WP`), `map_name` (short label), `map_game_port`, `map_query_port`, `map_rcon_port`, `map_admin_password`, `map_max_players`, `map_mods_enabled` (CurseForge IDs, comma-separated), `cluster_name`
- `admins:` list of 17-digit SteamIDs (may be empty)

## Tunable gameplay defaults

`taming_speed_multiplier`, `harvest_amount_multiplier`, `harvest_health_multiplier`, `xp_multiplier`, `max_tamed_dinos`, `override_official_difficulty`, `player_damage_multiplier`, `pve_dino_decay_period_multiplier`, `pve_structure_decay_period_multiplier`, `resources_respawn_period_multiplier`, `motd_duration`, `motd_message`, `asa_extra_start_flags`.

## Overlays: bring your own .ini

Drop files into a local `config/` directory at the playbook root:

```
config/
  Game.ini                               # cluster-wide (applied to every map)
  maps/
    <MapName>/GameUserSettings.ini       # per-map
```

Renders happen first; overlays copy on top. `config/` is gitignored.

## Reconciliation: removing maps

The role discovers existing per-map compose files on disk and compares against the current `maps:` list on every run. Any map on disk but not in the config is treated as an **orphan** and:

1. Stopped via `docker compose -f .../<map>.yml down`.
2. Its compose file at `{{ asa_compose_dir }}/<map>.yml` is deleted.
3. Its env file at `{{ asa_env_dir }}/<map>.env` is deleted.

Save data under `{{ asa_data_root }}/<map>/server-files/ShooterGame/Saved/` is preserved, so re-adding a map later resumes from the last save.

## Handlers

- `restart map` — runs `docker compose up -d --force-recreate` for every currently-configured map. Notified when any of the compose, env, or ini files change.

## Notes on the bundled INI templates

The bundled [Game.ini.j2](templates/Game.ini.j2) and [GameUserSettings.ini.j2](templates/GameUserSettings.ini.j2) ship a deliberately minimal preset — multipliers, breeding feel, MOTD, PvE/PvP toggles. No supply-crate or item-stack overrides. If you want a heavier preset, ship one via the `config/` overlay.
