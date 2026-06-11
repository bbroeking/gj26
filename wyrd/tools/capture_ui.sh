#!/bin/bash
# Spec 38 — capture every UI surface to /tmp/wyrd_ui_<name>.png in one go.
# Usage: bash tools/capture_ui.sh   (from wyrd/)
set -e
cd "$(dirname "$0")/.."
for mode in hud pack satchel charts trades dialog vendor cook smith inscribe; do
  rm -f /tmp/wyrd_town.png
  env_mode="$mode"
  [ "$mode" = "inscribe" ] && env_mode="table"   # the else-branch opens the table
  WYRD_NO_SAVE=1 WYRD_SHOT=1 WYRD_UI_SHOT="$env_mode" \
    godot --path . --quit-after 700 > /dev/null 2>&1 || true
  if [ -f /tmp/wyrd_town.png ]; then
    cp /tmp/wyrd_town.png "/tmp/wyrd_ui_${mode}.png"
    echo "✓ ${mode}"
  else
    echo "✗ ${mode} (no capture)"
  fi
done
