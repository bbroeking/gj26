#!/bin/bash
# Capture every stable UI surface to /tmp/wyrd_ui_<name>.png in one go.
# Usage: bash tools/capture_ui.sh   (from wyrd/)
set -u
cd "$(dirname "$0")/.."
failures=0

node --check tools/validate_capture_manifest.js

for mode in hud pack satchel charts trades dialog vendor cook smith inscribe enchant feedback; do
  rm -f /tmp/wyrd_town.png
  env_mode="$mode"
  [ "$mode" = "inscribe" ] && env_mode="table"   # the else-branch opens the table
  WYRD_NO_SAVE=1 WYRD_SHOT=1 WYRD_UI_SHOT="$env_mode" \
    # The Town capture callback waits for the scene and UI route to settle.
    # 700 frames can expire before that callback on fast/headless startup;
    # 1000 keeps the capture completion deterministic across local machines.
    godot --path . --resolution 1366x768 --quit-after 1000 > /dev/null 2>&1 || true
  if [ -f /tmp/wyrd_town.png ]; then
    cp /tmp/wyrd_town.png "/tmp/wyrd_ui_${mode}.png"
    echo "✓ ${mode}"
  else
    echo "✗ ${mode} (no capture)"
    failures=$((failures + 1))
  fi
done

# Spec 58 Slice C1 — deterministic Codex states use a standalone render
# harness, so visual QA does not require capture-only branches in Town/Game/UI.
for route in codex_index codex_rumoured codex_attemptable codex_known_ghost \
  codex_stage_all_sufficient codex_stage_all_insufficient codex_guest \
  codex_deep_rumoured_kit codex_sallow_rumoured_kit; do
  capture_path="/tmp/wyrd_ui_${route}.png"
  capture_log="/tmp/wyrd_ui_${route}.log"
  rm -f "$capture_path" "${capture_path%.png}.json" "$capture_log"
  if WYRD_NO_SAVE=1 WYRD_CODEX_CAPTURE="$route" WYRD_CAPTURE_PATH="$capture_path" \
      godot --path . --resolution 1366x768 --script \
      res://tools/capture_chart_codex.gd > "$capture_log" 2>&1; then
    if [ -f "$capture_path" ] && node tools/validate_capture_manifest.js \
        codex "${capture_path%.png}.json" "$route"; then
      echo "✓ ${route}"
    else
      echo "✗ ${route} (capture/manifest validation failed; see ${capture_log})"
      failures=$((failures + 1))
    fi
  else
    echo "✗ ${route} (runner failed; see ${capture_log})"
    failures=$((failures + 1))
  fi
done


# Slice C2 — the real Town source Interactables and their real DialogPanel.
# These routes deliberately fail until both the domain source API and stable
# world Controls are integrated; the harness never substitutes fixture UI.
for route in atlas_deep_eligible atlas_deep_read \
  mara_sallow_eligible mara_sallow_read; do
  capture_path="/tmp/wyrd_ui_${route}.png"
  capture_log="/tmp/wyrd_ui_${route}.log"
  rm -f "$capture_path" "${capture_path%.png}.json" "$capture_log"
  if WYRD_NO_SAVE=1 WYRD_SOURCE_CAPTURE="$route" WYRD_CAPTURE_PATH="$capture_path" \
      godot --path . --resolution 1366x768 --script \
      res://tools/capture_chart_sources.gd > "$capture_log" 2>&1; then
    if [ -f "$capture_path" ] && node tools/validate_capture_manifest.js \
        source "${capture_path%.png}.json" "$route"; then
      echo "✓ ${route}"
    else
      echo "✗ ${route} (capture/manifest validation failed; see ${capture_log})"
      failures=$((failures + 1))
    fi
  else
    echo "✗ ${route} (runner failed; see ${capture_log})"
    failures=$((failures + 1))
  fi
done

# Slice D2 — the physical Table renders resolved depth contracts through the
# same preview used for inscription. These native routes make the added layer,
# terminal Hearth, far-Waystone Omen, and First Knot reprise copy reviewable.
for route in deepening_green deepening_sallow first_knot_reprise; do
  capture_path="/tmp/wyrd_ui_${route}.png"
  capture_log="/tmp/wyrd_ui_${route}.log"
  rm -f "$capture_path" "$capture_log"
  if WYRD_NO_SAVE=1 WYRD_D2_CAPTURE="$route" WYRD_CAPTURE_PATH="$capture_path" \
      godot --path . --resolution 1366x768 --script \
      res://tools/capture_chart_deepening.gd > "$capture_log" 2>&1 \
      && [ -f "$capture_path" ]; then
    echo "✓ ${route}"
  else
    echo "✗ ${route} (runner failed; see ${capture_log})"
    failures=$((failures + 1))
  fi
done

if [ "$failures" -ne 0 ]; then
  echo "Capture gate failed: ${failures} route(s)."
  exit 1
fi

echo "Capture gate passed."
