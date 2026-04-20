#!/bin/bash
# asa_dino_wipe.sh — wild dino + fertilized egg wipe across every map.
# Invoked by cron; uses the asa_rcon.sh helper.

set -uo pipefail

RCON="$(dirname "$0")/asa_rcon.sh"

# Fertilized eggs that snowball if left alone (Wyverns, Crystal Wyverns,
# Rock Drakes, Magmasaurs, Deinonychus). Class names verified against
# ASA — keep this list short; a stale entry is a no-op, not a failure.
EGG_CLASSES=(
    "droppeditemgeneric_fertilizedegg_nophysicswyvern_c"
    "droppeditemgeneric_fertilizedegg_nophysicscrystalwyvern_c"
    "droppeditemgeneric_fertilizedegg_nophysicsrockdrake_c"
    "droppeditemgeneric_fertilizedegg_nophysicscherufe_c"
    "droppeditemgeneric_fertilizedegg_nophysicsdeinonychus_c"
)

for cls in "${EGG_CLASSES[@]}"; do
    "$RCON" @all "destroyall $cls" || true
done

"$RCON" @all "destroywilddinos" || true
