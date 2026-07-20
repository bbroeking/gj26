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

# Storybook carved banner (BossBarArt inner class below) — replaces the
# plain make_meter() trough that shipped with spec 17.
var _art: BossBarArt = null

func _ready() -> void:
	visible = false
	# Wyrd UI overhaul — the old scene-tscn flat bar gives way to the
	# storybook carved banner.  Keep the Bar node hidden; its @onready refs
	# still resolve and store phase text / hp values as before.
	var bar := get_node_or_null("Bar")
	if bar != null:
		bar.visible = false
	_art = BossBarArt.new()
	_art.anchor_left = 0.5
	_art.anchor_right = 0.5
	_art.anchor_top = 0.0
	_art.anchor_bottom = 0.0
	_art.offset_left = -350
	_art.offset_right = 350
	_art.offset_top = 10
	_art.offset_bottom = 94
	add_child(_art)

# Called at build — set max HP and fill the bar.
func prime(mx: int) -> void:
	_hp_max = mx
	_fill.offset_right = FILL_LEFT + FILL_FULL_W
	if _art != null:
		_art.update_to(1.0, "The Hedgemother — Unyielding")

func show_boss() -> void:
	visible = true

func set_hp(cur: int, mx: int) -> void:
	_hp_max = mx
	var f := clampf(float(cur) / float(max(1, mx)), 0.0, 1.0)
	_fill.offset_right = FILL_LEFT + FILL_FULL_W * f
	if _art != null:
		_art.update_to(f, _art.boss_text)

func set_phase(phase: int) -> void:
	# Spec 31 — "Unyielding" suffix tells the player WHY their snares fizzle
	# on the boss. The Hedgemother is immune to root + snared (and takes burn
	# + bleed at 50% reduced duration); the tag makes that visible without a
	# hidden DR meter.
	_label.text = "The Hedgemother — Phase %d — Unyielding" % phase
	if _art != null:
		_art.update_to(_art.frac, _label.text)

func hide_boss() -> void:
	visible = false


# Storybook boss HP banner: a carved parchment backing band with ivy-leaf
# knot ornaments at each end, the boss name in small-caps above the blood-red
# trough, and a burnished gold top edge. Matches the mj_hud_bramble.png
# reference language (chunky warm frames, ivy/vine ornament, jade accents).
# All drawn in _draw — no textures (white-rect-in-draw gotcha stays safe).
class BossBarArt extends Control:
	var frac := 1.0
	var boss_text := "The Hedgemother — Unyielding"
	var liquid := Color(0.69, 0.30, 0.20, 0.9)  # blood-red fill

	const LEAF_ZONE := 68.0   # px at each end reserved for ivy ornament

	func update_to(p_frac: float, p_text: String) -> void:
		frac = clampf(p_frac, 0.0, 1.0)
		boss_text = p_text
		queue_redraw()

	func _draw() -> void:
		var W := size.x
		var H := size.y

		# --- carved parchment backing band ---
		var backing := Rect2(Vector2.ZERO, size)
		draw_rect(backing, Color(0.86, 0.78, 0.62))
		WyrdUi.draw_parchment_grain(self, backing, 17)

		# --- burnished gold top edge (the frame's catch-light) ---
		draw_rect(Rect2(0.0, 0.0, W, 2.5), Color(WyrdUi.GOLD, 0.72))

		# --- boss name in small-caps, terracotta ---
		var f := WyrdUi.font_header()
		if f == null:
			f = get_theme_default_font()
		draw_string(f, Vector2(0.0, 20.0), boss_text,
			HORIZONTAL_ALIGNMENT_CENTER, W, 15, WyrdUi.TERRACOTTA)

		# --- flourish ── ◆ ── beneath the name ---
		WyrdUi.draw_flourish(self, Vector2(W * 0.5, 29.0), 240.0)

		# --- recessed trough well ---
		var tr := Rect2(LEAF_ZONE, 36.0, W - LEAF_ZONE * 2.0, 32.0)
		WyrdUi.draw_well(self, tr)

		# --- blood-red fill with a highlight gleam ---
		if frac > 0.001:
			var fr := Rect2(tr.position + Vector2(3.0, 3.0),
				Vector2(maxf(2.0, (tr.size.x - 6.0) * frac), tr.size.y - 6.0))
			draw_rect(fr, liquid)
			draw_rect(Rect2(fr.position, Vector2(fr.size.x, 1.5)),
				Color(1.0, 0.45, 0.30, 0.30))

		# --- ink outer border ---
		draw_rect(backing, WyrdUi.KIT_EDGE, false, 2.0)

		# --- ivy-leaf knot ornaments at each horizontal end ---
		_draw_ivy(Vector2(0.0, H * 0.5),  1.0)
		_draw_ivy(Vector2(W,   H * 0.5), -1.0)

	# One ivy cluster: a short vine spine, two leaf branches, and a berry bud.
	# dir =+1 grows rightward (left end); dir =-1 grows leftward (right end).
	func _draw_ivy(anchor: Vector2, dir: float) -> void:
		var leaf_col := WyrdUi.SAGE
		var vine_col := Color(WyrdUi.SAGE.darkened(0.30), 0.75)
		var tip := anchor + Vector2(dir * 56.0, 0.0)
		draw_line(anchor, tip, vine_col, 1.5, true)
		_draw_leaf(anchor + Vector2(dir * 16.0, 0.0),
			Vector2(dir * 0.55, -0.84).normalized(), 15.0, leaf_col)
		_draw_leaf(anchor + Vector2(dir * 36.0, 0.0),
			Vector2(dir * 0.42,  0.91).normalized(), 13.0, leaf_col)
		# Berry bud at the vine tip
		draw_circle(tip, 3.5, leaf_col)
		draw_arc(tip, 3.5, 0.0, TAU, 12, vine_col, 1.0, true)

	# A pointed oval leaf polygon along `dir` from `base`.
	func _draw_leaf(base: Vector2, dir: Vector2, length: float,
			color: Color) -> void:
		var hw := length * 0.36
		var perp := Vector2(-dir.y, dir.x)
		var pts := PackedVector2Array()
		for i in 10:
			var t := float(i) / 9.0
			pts.append(base + dir * length * t + perp * hw * sin(PI * t))
		for i in range(9, -1, -1):
			var t := float(i) / 9.0
			pts.append(base + dir * length * t - perp * hw * sin(PI * t))
		draw_colored_polygon(pts, color)
		# Ink midrib — gives the leaf definition without an outline
		draw_line(base, base + dir * length, Color(WyrdUi.KIT_EDGE, 0.28), 1.0, true)
