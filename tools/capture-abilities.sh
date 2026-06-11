#!/bin/bash
# Ability capture pipeline — boots Godot with the Capture scene, lets it
# write frames to user://captures/<slug>/*.png, then stitches each
# ability's frames into a GIF + MP4 via ffmpeg and copies into
# docs/skills/captures/ for the showcase site to embed.
#
# Usage:
#   ./tools/capture-abilities.sh
#
# Requires: Godot 4.6+ (in $PATH or at /Applications/Godot.app), ffmpeg.

set -euo pipefail

GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
PROJ="$(cd "$(dirname "$0")/.." && pwd)/godot"
USER_DATA="$HOME/Library/Application Support/Godot/app_userdata/gj26 — Godot evaluation"
CAPTURE_DIR="$USER_DATA/captures"
OUT_DIR="$(cd "$(dirname "$0")/.." && pwd)/docs/skills/captures"

# Slugs MUST match the ones in capture_rig.gd::ABILITIES.
ABILITIES=(
  # Skills
  "basicshot" "powershot" "multishot" "snare"
  # Statuses
  "burn" "bleed" "snared" "root"
  # Elites
  "brambled" "swift" "sunlit" "briarbound"
  # Boss
  "hedgemother"
)

echo "[capture] launching Godot capture rig…"
echo "[capture] project: $PROJ"
echo "[capture] frames will write to: $CAPTURE_DIR"
echo

# Run the capture scene WINDOWED — Godot 4.x `--headless` skips rendering
# entirely, so get_viewport().get_texture().get_image() returns blank in
# that mode. The window appears briefly; safe to ignore. ~10 seconds.
"$GODOT" --path "$PROJ" res://scenes/Capture.tscn 2>&1 | grep "\[capture\]" || true

echo
echo "[capture] stitching frames…"
mkdir -p "$OUT_DIR"

for slug in "${ABILITIES[@]}"; do
  src="$CAPTURE_DIR/$slug"
  if [ ! -d "$src" ]; then
    echo "[capture] WARN — no frames for $slug (looked in $src)"
    continue
  fi
  frame_count=$(ls "$src"/*.png 2>/dev/null | wc -l | tr -d ' ')
  if [ "$frame_count" -eq 0 ]; then
    echo "[capture] WARN — $slug directory exists but no PNGs"
    continue
  fi

  # GIF — palette + dither for cleaner output. 30fps for a smaller file.
  palette="$src/palette.png"
  ffmpeg -hide_banner -loglevel error -y \
    -framerate 60 -i "$src/%04d.png" \
    -vf "fps=30,scale=640:-1:flags=lanczos,palettegen=stats_mode=diff" \
    "$palette"
  ffmpeg -hide_banner -loglevel error -y \
    -framerate 60 -i "$src/%04d.png" -i "$palette" \
    -filter_complex "fps=30,scale=640:-1:flags=lanczos[x];[x][1:v]paletteuse=dither=bayer:bayer_scale=3" \
    "$OUT_DIR/$slug.gif"

  # MP4 — higher quality, smaller for streaming.
  ffmpeg -hide_banner -loglevel error -y \
    -framerate 60 -i "$src/%04d.png" \
    -vf "scale=960:-2" -c:v libx264 -pix_fmt yuv420p -crf 23 \
    "$OUT_DIR/$slug.mp4"

  echo "[capture] $slug — $frame_count frames → $OUT_DIR/$slug.{gif,mp4}"
done

echo
echo "[capture] done."
echo "[capture] open docs/skills/index.html to view (after embedding the captures)."
