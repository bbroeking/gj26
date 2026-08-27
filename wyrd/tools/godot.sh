#!/bin/sh
set -eu

# Use the project-matched editor when it is installed alongside newer Godot
# releases. CI and non-macOS environments can override this with
# WYRD_GODOT_BIN or fall back to the first `godot` on PATH.
if [ -n "${WYRD_GODOT_BIN:-}" ]; then
  exec "$WYRD_GODOT_BIN" "$@"
fi

macos_godot='/Applications/Godot 4.6.2.app/Contents/MacOS/Godot'
if [ -x "$macos_godot" ]; then
  exec "$macos_godot" "$@"
fi

exec godot "$@"
