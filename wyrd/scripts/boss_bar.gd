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
var _dressing: Control = null

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
		# Ornamental endcaps drawn on top of the meter trough.
		_dressing = BossBarDressing.new()
		_dressing.anchor_left = 0.5
		_dressing.anchor_right = 0.5
		_dressing.offset_left = -320
		_dressing.offset_right = 320
		_dressing.offset_top = 14
		_dressing.offset_bottom = 58
		_dressing.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_dressing)

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


# Storybook endcap dressing — wax seal at left, gold ◆ at right, parchment
# grain over the trough — so the most dramatic HUD moment reads as a crafted
# object rather than a raw health bar.
class BossBarDressing extends Control:
	func _draw() -> void:
		var w := size.x
		# Parchment grain across the trough interior.
		WyrdUi.draw_parchment_grain(self,
			Rect2(Vector2(20.0, 4.0), Vector2(w - 40.0, 36.0)), 41)
		# Left endcap — terracotta wax seal (two concentric circles + ink ring).
		var lc := Vector2(10.0, 22.0)
		draw_circle(lc, 8.0, Color(0.62, 0.20, 0.16))
		draw_circle(lc, 5.0, Color(0.72, 0.28, 0.22))
		draw_arc(lc, 8.0, 0.0, TAU, 24, Color(0.40, 0.12, 0.10), 1.5, true)
		# Right endcap — burnished gold ◆ diamond pip.
		var rc := Vector2(w - 10.0, 22.0)
		var s := 6.0
		draw_colored_polygon(PackedVector2Array([
			rc + Vector2(0.0, -s), rc + Vector2(s, 0.0),
			rc + Vector2(0.0, s),  rc + Vector2(-s, 0.0)]),
			Color(WyrdUi.GOLD, 0.85))
		draw_polyline(PackedVector2Array([
			rc + Vector2(0.0, -s), rc + Vector2(s, 0.0),
			rc + Vector2(0.0, s),  rc + Vector2(-s, 0.0),
			rc + Vector2(0.0, -s)]),
			WyrdUi.INK, 1.0)
