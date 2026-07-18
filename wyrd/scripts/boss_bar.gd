extends CanvasLayer

# Spec 17 — the Hedgemother boss HP banner. Hidden until she aggros.
# UI scaling is now project-level (canvas_items stretch); the old Spec-35
# per-layer UI_SCALE transform is retired so this banner sizes consistently
# with the rest of the HUD.

const FILL_LEFT := 4.0
const FILL_FULL_W := 592.0

@onready var _fill: ColorRect = $Bar/Fill
@onready var _label: Label = $Bar/Label

var _hp_max := 100

var _meter: Dictionary = {}

func _ready() -> void:
	visible = false
	# Wyrd UI overhaul — parchment banner over the old flat bar.
	var bar := get_node_or_null("Bar")
	if bar != null:
		bar.visible = false
		_meter = WyrdUi.make_meter(600, 34, Color(0.69, 0.30, 0.20, 0.9))
		var root := _meter.root as Control
		root.anchor_left = 0.5
		root.anchor_right = 0.5
		root.offset_left = -300
		root.offset_top = 18
		add_child(root)
		# Phase threshold marks overlay — terracotta diamond pips at the 66% and
		# 33% HP thresholds where the boss escalates (PHASE2_FRAC / PHASE3_FRAC).
		var marks := _PhaseMarks.new()
		marks.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		marks.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(marks)

# Called at build — set max HP and fill the bar.
func prime(mx: int) -> void:
	_hp_max = mx
	_fill.offset_right = FILL_LEFT + FILL_FULL_W
	if not _meter.is_empty():
		WyrdUi.set_meter(_meter, 1.0, "The Hedgemother — Unyielding")

func show_boss() -> void:
	visible = true

func set_hp(cur: int, mx: int) -> void:
	_hp_max = mx
	var f := clampf(float(cur) / float(max(1, mx)), 0.0, 1.0)
	_fill.offset_right = FILL_LEFT + FILL_FULL_W * f
	if not _meter.is_empty():
		WyrdUi.set_meter(_meter, f, (_meter.label as Label).text)

func set_phase(phase: int) -> void:
	# Spec 31 — "Unyielding" suffix tells the player WHY their snares fizzle
	# on the boss. The Hedgemother is immune to root + snared (and takes burn
	# + bleed at 50% reduced duration); the tag makes that visible without a
	# hidden DR meter.
	_label.text = "The Hedgemother — Phase %d — Unyielding" % phase
	if not _meter.is_empty():
		(_meter.label as Label).text = _label.text

func hide_boss() -> void:
	visible = false


# Drawn phase-threshold marks for the boss HP trough. Two terracotta diamond
# pips + faint seam lines at the 66% and 33% fill positions — the two HP
# thresholds where the Hedgemother escalates her attack pattern.
class _PhaseMarks extends Control:
	func _draw() -> void:
		var fill_l := 3.0
		var full_w := size.x - 14.0
		for frac in [0.66, 0.33]:
			var x := fill_l + full_w * frac
			# Faint ink seam through the trough height.
			draw_line(Vector2(x, 3.5), Vector2(x, size.y - 3.5),
				Color(WyrdUi.KIT_EDGE, 0.40), 1.5)
			# Terracotta diamond pip on the top rim — the phase boundary cue.
			var tc := Vector2(x, 3.0)
			draw_colored_polygon(PackedVector2Array([
				tc + Vector2(0.0, -2.5), tc + Vector2(4.0, 0.0),
				tc + Vector2(0.0, 2.5), tc + Vector2(-4.0, 0.0)]),
				Color(WyrdUi.TERRACOTTA, 0.90))
