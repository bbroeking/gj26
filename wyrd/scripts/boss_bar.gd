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

var _banner: BossBanner = null
var _boss_name := "The Hedgemother — Unyielding"
var _boss_frac := 1.0

func _ready() -> void:
	visible = false
	# Wyrd UI overhaul — hand-drawn parchment banner with boss-name header,
	# gold flourish rule, carved HP well, and ivy-thorn sprigs at the bar ends.
	var bar := get_node_or_null("Bar")
	if bar != null:
		bar.visible = false
	_banner = BossBanner.new()
	_banner.anchor_left = 0.5
	_banner.anchor_right = 0.5
	_banner.offset_left = -320
	_banner.offset_right = 320
	_banner.offset_top = 8
	_banner.offset_bottom = 72
	add_child(_banner)

# Called at build — set max HP and fill the bar.
func prime(mx: int) -> void:
	_hp_max = mx
	_fill.offset_right = FILL_LEFT + FILL_FULL_W
	_boss_frac = 1.0
	_boss_name = "The Hedgemother — Unyielding"
	if _banner != null:
		_banner.update_bar(1.0, _boss_name)

func show_boss() -> void:
	visible = true

func set_hp(cur: int, mx: int) -> void:
	_hp_max = mx
	var f := clampf(float(cur) / float(max(1, mx)), 0.0, 1.0)
	_fill.offset_right = FILL_LEFT + FILL_FULL_W * f
	_boss_frac = f
	if _banner != null:
		_banner.update_bar(f, _boss_name)

func set_phase(phase: int) -> void:
	_label.text = "The Hedgemother — Phase %d — Unyielding" % phase
	_boss_name = _label.text
	if _banner != null:
		_banner.update_bar(_boss_frac, _boss_name)

func hide_boss() -> void:
	visible = false


# A hand-drawn boss HP banner: warm parchment face with bevel + grain, boss
# name in TERRACOTTA IM Fell SC, a gold flourish rule below the name, a carved
# HP well that fills left-to-right, and ivy-thorn sprig ornaments at the bar
# ends — the frame/header ornament language from the rest of the kit, finally
# applied to the most dramatic HUD element.
class BossBanner extends Control:
	var _name := "The Hedgemother — Unyielding"
	var _frac := 1.0

	const BAR_X := 26.0
	const BAR_Y := 36.0
	const BAR_H := 20.0

	func update_bar(f: float, name_text: String) -> void:
		_frac = clampf(f, 0.0, 1.0)
		_name = name_text
		queue_redraw()

	func _draw() -> void:
		var hdr := WyrdUi.font_header()
		var fnt := get_theme_default_font()
		if hdr == null:
			hdr = fnt
		var bar_w := size.x - BAR_X * 2.0

		# --- parchment face with warm bevel ---
		var face := Rect2(Vector2.ZERO, size)
		draw_rect(face, Color(0.92, 0.85, 0.70, 0.97))
		draw_rect(Rect2(Vector2(1.5, 1.5), Vector2(size.x - 3.0, 2.5)),
			Color(1.0, 1.0, 0.90, 0.52))
		draw_rect(Rect2(Vector2(2.0, size.y - 4.0), Vector2(size.x - 4.0, 2.5)),
			Color(WyrdUi.KIT_EDGE, 0.22))
		draw_rect(face, WyrdUi.KIT_EDGE, false, 2.0)
		WyrdUi.draw_parchment_grain(self, face.grow(-4.0), 29)

		# --- boss name header ---
		draw_string(hdr, Vector2(0.0, 24.0), _name,
			HORIZONTAL_ALIGNMENT_CENTER, size.x, 16, WyrdUi.TERRACOTTA)
		WyrdUi.draw_flourish(self, Vector2(size.x * 0.5, 32.0), 260.0)

		# --- carved HP well ---
		var well_r := Rect2(Vector2(BAR_X, BAR_Y), Vector2(bar_w, BAR_H))
		WyrdUi.draw_well(self, well_r)

		# --- fill bar ---
		if _frac > 0.003:
			var fill_w := (bar_w - 8.0) * _frac
			var fr := Rect2(Vector2(BAR_X + 4.0, BAR_Y + 4.0),
				Vector2(fill_w, BAR_H - 8.0))
			draw_rect(fr, Color(0.69, 0.30, 0.20, 0.95))
			draw_rect(Rect2(fr.position, Vector2(fill_w, 2.5)),
				Color(1.0, 0.60, 0.50, 0.45))
			draw_rect(Rect2(fr.position + Vector2(0.0, fr.size.y - 2.0),
				Vector2(fill_w, 2.0)), Color(WyrdUi.KIT_EDGE, 0.28))

		# --- ivy-thorn sprig ornaments at each bar end ---
		var bar_mid_y := BAR_Y + BAR_H * 0.5
		_draw_ivy_sprig(Vector2(BAR_X - 4.0, bar_mid_y), -1.0)
		_draw_ivy_sprig(Vector2(BAR_X + bar_w + 4.0, bar_mid_y), 1.0)

	# A tiny ivy-thorn sprig: vertical stem, three leaf-bearing branches
	# growing outward in the direction of `side` (-1 = left, +1 = right),
	# with a gold filigree dot at the stem tip — consistent with the
	# ivy/vine ornament language used on panel frames and section headers.
	func _draw_ivy_sprig(ctr: Vector2, side: float) -> void:
		var sage := WyrdUi.SAGE.darkened(0.22)
		var stem_top := ctr - Vector2(0.0, 10.0)
		var stem_bot := ctr + Vector2(0.0, 10.0)
		draw_line(stem_top, stem_bot, sage, 1.5)
		for i in 3:
			var fy := float(i) / 2.0
			var stem_pt := stem_top.lerp(stem_bot, 0.12 + fy * 0.72)
			# Branch grows outward (side direction) with slight vertical spread.
			var branch_dir := Vector2(side * 9.0, -3.5 + float(i) * 3.5)
			var tip := stem_pt + branch_dir
			draw_line(stem_pt, tip, sage, 1.0)
			# Leaf: small diamond elongated along the branch direction.
			var along := branch_dir.normalized()
			var perp := Vector2(-along.y, along.x)
			var leaf := PackedVector2Array([
				tip + along * 4.5,
				tip + perp * 3.0,
				tip - along * 2.0,
				tip - perp * 3.0,
			])
			draw_colored_polygon(leaf, sage)
		# Gold filigree accent dot at the very top of the stem.
		draw_circle(stem_top - Vector2(0.0, 2.5), 2.0, Color(WyrdUi.GOLD, 0.80))
