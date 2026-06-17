extends RefCounted

# Plan.md B0 — central game-feel tunables. One home for the magic numbers that
# govern how actions FEEL, so a playtest pass is one-file-fast. Not an autoload
# and not class_name (headless --script doesn't register class_name); consumers
# `const Feel = preload("res://data/feel.gd")` and read `Feel.X`.
#
# Each block is consumed by the system named in the comment; constants land here
# as their consumer ships (so nothing is a dead literal). See Plan.md Part B.

# ---- Toasts / banners (player_hud) ----
const TOAST_HOLD_SEC := 2.4              # info chip dwell before fade
const TOAST_FADE_SEC := 0.6              # fade-out duration
const TOAST_LEVELUP_HOLD_SEC := 3.5      # the level-up banner lingers longer
const TOAST_DEDUP_WINDOW_SEC := 1.0      # collapse identical chips fired in a burst

# ---- Level-up "moment" (player_hud, Plan.md B3) ----
const LEVELUP_FLASH_SEC := 0.4           # how long the trade readout glows gold
const LEVELUP_PUNCH_SCALE := 1.10        # scale-punch peak on the readout
const LEVELUP_PUNCH_UP_SEC := 0.08       # anticipation→peak
const LEVELUP_PUNCH_DOWN_SEC := 0.12     # settle back to 1.0
