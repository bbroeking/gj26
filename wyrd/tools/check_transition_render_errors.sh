#!/usr/bin/env bash
set -euo pipefail

# Regression loop for the Compatibility renderer diagnostic emitted while
# Town/World are released during the real two-Chart transition suite.
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LOG="${TMPDIR:-/tmp}/wyrd-transition-render-errors.log"

WYRD_NO_SAVE=1 godot --headless --path "$ROOT" \
  --script res://test_wyrd_transitions.gd >"$LOG" 2>&1

if rg -q 'Parameter "material" is null' "$LOG"; then
  rg -n -C 1 'Parameter "material" is null' "$LOG" >&2
  echo "FAIL: scene transitions emitted null-material renderer errors" >&2
  exit 1
fi

if ! rg -q -- '--- [0-9]+ passed, 0 failed ---' "$LOG"; then
  tail -n 80 "$LOG" >&2
  echo "FAIL: transition suite did not finish green" >&2
  exit 1
fi

echo "PASS: transition suite is green with no null-material renderer errors"
