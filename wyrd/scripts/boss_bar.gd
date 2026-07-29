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
var _crest_label: Label = null

func _ready() -> void:
	visible = false
	# Boss-name crest: terracotta header + drawn ornament sits above the trough.
	_build_crest()
	# Wyrd UI overhaul — parchment banner over the old flat bar.
	var bar := get_node_or_null("Bar")
	if bar != null:
		bar.visible = false
		_meter = WyrdUi.make_meter(600, 34, Color(0.69, 0.30, 0.20, 0.9))
		var root := _meter.root as Control
		root.anchor_left = 0.5
		root.anchor_right = 0.5
		root.offset_left = -300
		root.offset_top = 46   # shifted down to make room for the name crest
		add_child(root)

# Build the boss-name crest: drawn backdrop + terracotta name label above the bar.
func _build_crest() -> void:
	var art := BossNameArt.new()
	art.anchor_left = 0.5
	art.anchor_right = 0.5
	art.offset_left = -312
	art.offset_right = 312
	art.offset_top = 8
	art.offset_bottom = 43
	add_child(art)
	_crest_label = Label.new()
	_crest_label.anchor_left = 0.5
	_crest_label.anchor_right = 0.5
	_crest_label.offset_left = -300
	_crest_label.offset_right = 300
	_crest_label.offset_top = 9
	_crest_label.offset_bottom = 41
	_crest_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_crest_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var hf := WyrdUi.font_header()
	if hf != null:
		_crest_label.add_theme_font_override("font", hf)
	_crest_label.add_theme_font_size_override("font_size", 19)
	_crest_label.add_theme_color_override("font_color", WyrdUi.TERRACOTTA)
	_crest_label.add_theme_color_override("font_outline_color", Color(WyrdUi.INK, 0.55))
	_crest_label.add_theme_constant_override("outline_size", 4)
	_crest_label.text = "The Hedgemother"
	add_child(_crest_label)

# Called at build — set max HP and fill the bar.
func prime(mx: int) -> void:
	_hp_max = mx
	_fill.offset_right = FILL_LEFT + FILL_FULL_W
	if not _meter.is_empty():
		WyrdUi.set_meter(_meter, 1.0, "Unyielding")
	if _crest_label != null:
		_crest_label.text = "The Hedgemother"

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
		(_meter.label as Label).text = "Phase %d — Unyielding" % phase
	if _crest_label != null:
		_crest_label.text = "The Hedgemother — Phase %d" % phase

func hide_boss() -> void:
	visible = false


# Drawn crest backdrop: faint parchment grain + ── ◆ ── flourish rule below
# the name + ink corner ticks. Frames the boss encounter as a named-danger
# card that reads consistently with the storybook HUD language. Pure-vector
# (_draw only, no load() calls — safe from the white-rect gotcha).
class BossNameArt extends Control:
	func _draw() -> void:
		if size.x < 2.0 or size.y < 2.0:
			return
		var r := Rect2(Vector2.ZERO, size)
		# Faint parchment warmth so the crest reads OFF the canvas-black sky.
		draw_rect(r, Color(WyrdUi.CREAM, 0.07))
		WyrdUi.draw_parchment_grain(self, r, 41)
		# ── ◆ ── separator rule below the name, above the HP trough.
		WyrdUi.draw_flourish(self,
			Vector2(size.x * 0.5, size.y - 4.0), size.x * 0.50)
		# Ink corner ticks — the carved-frame language shared by hotbar slots.
		var tick := 8.0
		var col := Color(WyrdUi.KIT_EDGE, 0.45)
		for cx in [0.0, size.x]:
			for cy in [0.0, size.y]:
				var dx := tick if cx == 0.0 else -tick
				var dy := tick if cy == 0.0 else -tick
				draw_line(Vector2(cx, cy), Vector2(cx + dx, cy), col, 1.5)
				draw_line(Vector2(cx, cy), Vector2(cx, cy + dy), col, 1.5)
