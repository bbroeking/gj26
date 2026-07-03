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
		# Art nameplate — added before the meter so it draws behind the trough.
		# The thorn branches are visible in the 40 px side margins; the bevel +
		# gold inset frame shows above + below the trough as a carved surround.
		var art := _BossNameplateArt.new()
		art.anchor_left = 0.5
		art.anchor_right = 0.5
		art.offset_left = -340
		art.offset_right = 340
		art.offset_top = 12
		art.offset_bottom = 62
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(art)
		add_child(root)

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


# A carved parchment nameplate that sits BEHIND the meter trough (drawn first,
# so the trough renders on top). The 40 px side margins show thorn-branch
# ornament in sepia + sage — the Hedgemother's bramble motif, pulled from
# mj_hud_bramble.png. The cream bevel + gold inset peeks above/below the
# trough as a "this is a carved proclamation" surround.
class _BossNameplateArt extends Control:
	func _ready() -> void:
		resized.connect(queue_redraw)

	func _draw() -> void:
		if size.x < 2.0 or size.y < 2.0:
			return
		var r := Rect2(Vector2.ZERO, size)
		var cy := size.y * 0.5
		# Cream parchment face — slightly cooler than KIT_PLATE to read as
		# ancient carved stone rather than warm workshop parchment.
		draw_rect(r, WyrdUi.KIT_PLATE.darkened(0.04))
		# Top light bevel (catches the page's warm overhead light).
		draw_rect(Rect2(r.position + Vector2(3, 2), Vector2(r.size.x - 6, 2.5)),
			Color(1.0, 0.97, 0.88, 0.50))
		# Bottom ink shadow — grounds the banner so it sits ON the world.
		draw_rect(Rect2(r.position + Vector2(3, r.size.y - 4.5),
			Vector2(r.size.x - 6, 2.5)), Color(WyrdUi.KIT_EDGE, 0.30))
		# Ink border.
		draw_rect(r, WyrdUi.KIT_EDGE, false, 1.5)
		# Gold inner inset — the "burnished proclamation" read.
		draw_rect(r.grow(-4.0), Color(WyrdUi.GOLD, 0.40), false, 1.0)
		# Sparse parchment grain across the full face.
		WyrdUi.draw_parchment_grain(self, r.grow(-6.0), 88)
		# Thorn-branch ornament at each end — the bramble motif.
		_draw_thorn_branch(Vector2(6.0, cy), 1.0)
		_draw_thorn_branch(Vector2(r.size.x - 6.0, cy), -1.0)

	# Draws a thorny bramble branch from `origin` in direction `dir` (+1 = right).
	# All draw_* calls are on self (this Control), valid inside _draw call chain.
	func _draw_thorn_branch(origin: Vector2, dir: float) -> void:
		var col := Color(WyrdUi.KIT_EDGE, 0.65)
		var leaf_col := Color(WyrdUi.SAGE, 0.52)
		# Main horizontal stem — 28 px long, inward from the edge.
		draw_line(origin, origin + Vector2(dir * 28.0, 0.0), col, 1.5)
		# Three thorns branching alternately up and down from points on the stem.
		var stem_offsets: Array = [6.0, 14.0, 22.0]
		for i in stem_offsets.size():
			var p := origin + Vector2(dir * stem_offsets[i], 0.0)
			if i % 2 == 0:
				# Upper thorn — angles up and outward.
				draw_line(p, p + Vector2(dir * 3.5, -8.0), col, 1.2)
			else:
				# Lower thorn — angles down and outward.
				draw_line(p, p + Vector2(dir * 3.0, 7.5), col, 1.2)
		# Small sage leaf at the far tip of the stem — the living end of the bramble.
		var tip := origin + Vector2(dir * 28.0, 0.0)
		var pts := PackedVector2Array([
			tip + Vector2(dir * 8.0, 0.0),
			tip + Vector2(dir * 3.5, -5.5),
			tip + Vector2(dir * -1.0, 0.0),
			tip + Vector2(dir * 3.5, 5.5),
		])
		draw_colored_polygon(pts, leaf_col)
		# Faint leaf-vein line.
		draw_line(tip + Vector2(dir * 2.0, 0.0),
			tip + Vector2(dir * 7.0, 0.0),
			Color(WyrdUi.SAGE.darkened(0.25), 0.38), 0.8)
