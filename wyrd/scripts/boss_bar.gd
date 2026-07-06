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
var _name_lbl: Label = null

func _ready() -> void:
	visible = false
	# Wyrd UI overhaul — parchment banner over the old flat bar.
	var bar := get_node_or_null("Bar")
	if bar != null:
		bar.visible = false
		# Decorative parchment backing with ivy-end ornament.
		var banner := BossBarBanner.new()
		banner.anchor_left = 0.5
		banner.anchor_right = 0.5
		banner.offset_left = -330
		banner.offset_right = 330
		banner.offset_top = 10
		banner.offset_bottom = 78
		add_child(banner)
		# Boss name — floated above the trough in IM Fell SC so the player
		# knows at a glance what they're fighting.
		_name_lbl = Label.new()
		var hf := WyrdUi.font_header()
		if hf != null:
			_name_lbl.add_theme_font_override("font", hf)
		_name_lbl.add_theme_font_size_override("font_size", 15)
		_name_lbl.add_theme_color_override("font_color", WyrdUi.TERRACOTTA)
		_name_lbl.add_theme_color_override("font_outline_color",
			Color(0.12, 0.09, 0.06))
		_name_lbl.add_theme_constant_override("outline_size", 4)
		_name_lbl.anchor_left = 0.5
		_name_lbl.anchor_right = 0.5
		_name_lbl.offset_left = -270
		_name_lbl.offset_right = 270
		_name_lbl.offset_top = 15
		_name_lbl.offset_bottom = 37
		_name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(_name_lbl)
		# Health trough (580×24) — narrower than the banner so the ivy ends
		# have clear breathing room on each side.
		_meter = WyrdUi.make_meter(580, 24, Color(0.69, 0.30, 0.20, 0.9))
		var root := _meter.root as Control
		root.anchor_left = 0.5
		root.anchor_right = 0.5
		root.offset_left = -290
		root.offset_top = 44
		add_child(root)
		# Name lives in _name_lbl; meter label is kept as a backing text
		# store so set_hp can read the current name back without drift.
		(_meter.label as Label).visible = false

# Called at build — set max HP and fill the bar.
func prime(mx: int) -> void:
	_hp_max = mx
	_fill.offset_right = FILL_LEFT + FILL_FULL_W
	if not _meter.is_empty():
		WyrdUi.set_meter(_meter, 1.0, "The Hedgemother — Unyielding")
	if _name_lbl != null:
		_name_lbl.text = "The Hedgemother — Unyielding"

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
	if _name_lbl != null:
		_name_lbl.text = _label.text

func hide_boss() -> void:
	visible = false


# Parchment banner backing for the boss bar: warm cream face with a gold
# separator rule between the name row and the health trough, and a small
# ivy cluster at each end so the frame reads as living bramblewood rather
# than a flat HUD chrome strip.
class BossBarBanner extends Control:
	func _ready() -> void:
		resized.connect(queue_redraw)

	func _draw() -> void:
		if size.x < 4.0 or size.y < 4.0:
			return
		# Warm parchment face — slightly richer than body parchment so the
		# boss banner reads as a heavier proclamation.
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.91, 0.84, 0.68, 0.93))
		WyrdUi.draw_parchment_grain(self,
			Rect2(Vector2(2.0, 2.0), size - Vector2(4.0, 4.0)), 53)
		# Top light bevel — the banner catches warm overhead light.
		draw_rect(Rect2(Vector2(1.0, 1.0), Vector2(size.x - 2.0, 2.0)),
			Color(1.0, 1.0, 0.92, 0.40))
		# Bottom shade — grounds it against the game world below.
		draw_rect(Rect2(Vector2(2.0, size.y - 3.0),
			Vector2(size.x - 4.0, 2.0)), Color(WyrdUi.KIT_EDGE, 0.28))
		# Ink border.
		draw_rect(Rect2(Vector2.ZERO, size), WyrdUi.KIT_EDGE, false, 2.0)
		# Gold separator between the name row and the health trough, with a
		# small diamond jewel at its centre (lifted from draw_flourish).
		var sep_y := size.y * 0.51
		draw_line(Vector2(28.0, sep_y), Vector2(size.x - 28.0, sep_y),
			Color(WyrdUi.GOLD, 0.40), 1.0)
		var mid := Vector2(size.x * 0.5, sep_y)
		var pts := PackedVector2Array([
			mid + Vector2(0.0, -3.5), mid + Vector2(3.5, 0.0),
			mid + Vector2(0.0,  3.5), mid + Vector2(-3.5, 0.0),
		])
		draw_colored_polygon(pts, Color(WyrdUi.GOLD, 0.70))
		# Ivy clusters — one on each end so the banner reads as bramblewood.
		_draw_ivy_end(Vector2(22.0, size.y * 0.5), false)
		_draw_ivy_end(Vector2(size.x - 22.0, size.y * 0.5), true)

	func _draw_ivy_end(pivot: Vector2, mirrored: bool) -> void:
		var sx    := -1.0 if mirrored else 1.0
		var c_leaf  := Color(WyrdUi.SAGE.darkened(0.08), 0.68)
		var c_vein  := Color(WyrdUi.SAGE.darkened(0.42), 0.52)
		var c_stem  := Color(WyrdUi.SAGE.darkened(0.28), 0.58)
		var c_berry := Color(WyrdUi.TERRACOTTA.darkened(0.06), 0.52)
		# Thin vine stem pointing inward along the banner.
		draw_line(pivot, pivot + Vector2(sx * 11.0, 0.0), c_stem, 1.5)
		# Leaf A — arching upward from the stem.
		var lf_a := PackedVector2Array([
			pivot + Vector2(sx *  1.0,   0.0),
			pivot + Vector2(sx *  9.0,  -9.0),
			pivot + Vector2(sx * 13.0,  -5.0),
			pivot + Vector2(sx *  5.0,   1.0),
		])
		draw_colored_polygon(lf_a, c_leaf)
		draw_line(pivot + Vector2(sx * 1.0, 0.0),
			pivot + Vector2(sx * 10.0, -6.0), c_vein, 0.8)
		# Leaf B — arching downward from the stem.
		var lf_b := PackedVector2Array([
			pivot + Vector2(sx *  2.0,   0.0),
			pivot + Vector2(sx *  9.0,   9.0),
			pivot + Vector2(sx * 13.0,   5.0),
			pivot + Vector2(sx *  4.0,  -1.0),
		])
		draw_colored_polygon(lf_b, c_leaf)
		draw_line(pivot + Vector2(sx * 2.0, 0.0),
			pivot + Vector2(sx * 10.0, 6.0), c_vein, 0.8)
		# Small terracotta berry at the stem tip.
		draw_circle(pivot + Vector2(sx * 12.0, 0.0), 2.2, c_berry)
		draw_circle(pivot + Vector2(sx * 12.0, 0.0), 1.0,
			Color(1.0, 0.85, 0.70, 0.55))
