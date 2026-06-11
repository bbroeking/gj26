extends CanvasLayer

# Spec 15 — minimal player HUD: an HP bar + a full-screen damage flash.
# Spec 23 — plus a Pokémon-style death white-out.
# Spec-35 — UI_SCALE knob enlarges the whole HUD without touching the .tscn
# offsets; set as transform.scale on the CanvasLayer in _ready. NOTE: the
# Flash + Whiteout color rects use anchor_right/bottom = 1.0 (full-screen)
# so they don't need to scale — they're applied AFTER the transform scales
# anchored coords back to viewport size. Keep them at the same layer.

const UI_SCALE := 1.5

const FILL_LEFT := 2.0
const FILL_FULL_W := 216.0
# Spec 30 — Focus bar dimensions match the HP bar so the two stack cleanly.
const FOCUS_FILL_LEFT := 2.0
const FOCUS_FILL_FULL_W := 216.0

@onready var _fill: ColorRect = $HPRoot/Fill
@onready var _label: Label = $HPRoot/Label
@onready var _flash: ColorRect = $Flash
@onready var _whiteout: ColorRect = $Whiteout
@onready var _focus_fill: ColorRect = $FocusRoot/Fill
@onready var _focus_label: Label = $FocusRoot/Label

func _ready() -> void:
	# Spec-35: scale up the HP + Focus bars together. Flash and Whiteout
	# need to remain viewport-sized; reset their scale parent on each
	# (they're full-screen ColorRects, anchored to all sides).
	$HPRoot.scale = Vector2(UI_SCALE, UI_SCALE)
	$HPRoot.position *= UI_SCALE
	$FocusRoot.scale = Vector2(UI_SCALE, UI_SCALE)
	$FocusRoot.position *= UI_SCALE

func set_hp(cur: int, mx: int, status_suffix: String = "") -> void:
	var f := clampf(float(cur) / float(max(1, mx)), 0.0, 1.0)
	_fill.offset_right = FILL_LEFT + FILL_FULL_W * f
	# Spec 33a — optional suffix surfaces active player statuses textually
	# (e.g. "HP 25/30 — burning · snared"). Default empty preserves the
	# spec 15 readout shape.
	_label.text = "HP %d / %d%s" % [max(0, cur), mx, status_suffix]

# Spec 30 — Focus is a float (regen is fractional) but displays as int.
func set_focus(cur: float, mx: float) -> void:
	var f := clampf(cur / max(1.0, mx), 0.0, 1.0)
	_focus_fill.offset_right = FOCUS_FILL_LEFT + FOCUS_FILL_FULL_W * f
	_focus_label.text = "Focus %d / %d" % [int(cur), int(mx)]

# A red screen pulse on taking a hit.
func flash() -> void:
	_flash.modulate.a = 0.5
	var t := create_tween()
	t.tween_property(_flash, "modulate:a", 0.0, 0.35)

# Death white-out (spec 23) — the screen fades to white, the respawn
# happens unseen under it, then it fades back.
func whiteout_in() -> void:
	var t := create_tween()
	t.tween_property(_whiteout, "modulate:a", 1.0, 0.5)

func whiteout_out() -> void:
	var t := create_tween()
	t.tween_property(_whiteout, "modulate:a", 0.0, 0.5)
