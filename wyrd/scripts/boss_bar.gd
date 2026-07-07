extends CanvasLayer

# Spec 17 — the Hedgemother boss HP banner. Hidden until she aggros.
# UI scaling is now project-level (canvas_items stretch); the old Spec-35
# per-layer UI_SCALE transform is retired so this banner sizes consistently
# with the rest of the HUD.
#
# Art pass — replaced the flat make_meter trough with a storybook carved
# parchment banner: warm KIT_PLATE face + parchment grain, boss name in
# terracotta header font, draw_flourish rule, draw_well HP trough with a
# layered terracotta fill, gold ◆ marks at the bar ends, and paired ivy-leaf
# sprigs so the bar feels rooted in the world rather than floating flat on
# the screen. All drawn in BossBarDisplay._draw() — no textures touched.

const FILL_LEFT := 4.0
const FILL_FULL_W := 592.0

@onready var _fill: ColorRect = $Bar/Fill
@onready var _label: Label = $Bar/Label

var _hp_max := 100
var _boss_display: BossBarDisplay = null

func _ready() -> void:
	visible = false
	var bar := get_node_or_null("Bar")
	if bar != null:
		bar.visible = false
	_boss_display = BossBarDisplay.new()
	_boss_display.anchor_left = 0.5
	_boss_display.anchor_right = 0.5
	_boss_display.custom_minimum_size = Vector2(640, 72)
	_boss_display.size = Vector2(640, 72)
	_boss_display.offset_left = -320
	_boss_display.offset_top = 8
	_boss_display.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_boss_display)

func prime(mx: int) -> void:
	_hp_max = mx
	_fill.offset_right = FILL_LEFT + FILL_FULL_W
	if _boss_display != null:
		_boss_display.update_hp(1.0)

func show_boss() -> void:
	visible = true

func set_hp(cur: int, mx: int) -> void:
	_hp_max = mx
	var f := clampf(float(cur) / float(max(1, mx)), 0.0, 1.0)
	_fill.offset_right = FILL_LEFT + FILL_FULL_W * f
	if _boss_display != null:
		_boss_display.update_hp(f)

func set_phase(phase: int) -> void:
	_label.text = "The Hedgemother — Phase %d — Unyielding" % phase
	if _boss_display != null:
		_boss_display.set_boss_name(_label.text)

func hide_boss() -> void:
	visible = false


# Storybook boss HP banner — drawn entirely in code so no texture loads
# can turn white inside _draw. The banner is a warm parchment plate (the
# same KIT_PLATE + KIT_WELL vocabulary as every other code-drawn panel)
# dressed with a boss name, a flourish rule, a carved HP trough, gold
# diamond terminals, and ivy-leaf sprigs — turning a combat-critical bar
# into a piece of fairytale illustration.
class BossBarDisplay extends Control:
	var _frac := 1.0
	var _boss_name := "The Hedgemother — Unyielding"

	# Layout constants (pixels, within the 640×72 frame).
	const BAR_H   := 20.0   # HP trough height
	const BAR_Y   := 46.0   # trough top-edge Y
	const BAR_PAD := 32.0   # horizontal inset from plate edge to trough

	func update_hp(f: float) -> void:
		_frac = clampf(f, 0.0, 1.0)
		queue_redraw()

	func set_boss_name(txt: String) -> void:
		_boss_name = txt
		queue_redraw()

	func _draw() -> void:
		var w := size.x
		var h := size.y

		# ── parchment plate ───────────────────────────────────────────────
		var plate := Rect2(Vector2.ZERO, Vector2(w, h))
		draw_rect(plate, WyrdUi.KIT_PLATE)
		# top-light bevel — the plate catches the page's warm light
		draw_rect(Rect2(Vector2(2, 2), Vector2(w - 4, 2)),
			Color(1.0, 1.0, 0.93, 0.48))
		# bottom shade so the banner sits ON the HUD, not floating flat
		draw_rect(Rect2(Vector2(2, h - 3), Vector2(w - 4, 2)),
			Color(WyrdUi.KIT_EDGE, 0.24))
		# ink border + inner pinstripe (the carved-panel language)
		draw_rect(plate, WyrdUi.KIT_EDGE, false, 2.0)
		draw_rect(plate.grow(-4.0), Color(WyrdUi.KIT_EDGE, 0.22), false, 1.0)
		# faint parchment grain over the face
		WyrdUi.draw_parchment_grain(self, plate.grow(-6.0), 42)

		# ── boss name ─────────────────────────────────────────────────────
		var font := WyrdUi.font_header()
		if font == null:
			font = get_theme_default_font()
		draw_string(font, Vector2(w * 0.5, 22.0), _boss_name,
			HORIZONTAL_ALIGNMENT_CENTER, w - 40.0, 16, WyrdUi.TERRACOTTA)

		# ── flourish rule beneath the name ────────────────────────────────
		WyrdUi.draw_flourish(self, Vector2(w * 0.5, 33.0), 240.0)

		# ── HP trough (carved well) ───────────────────────────────────────
		var bar_r := Rect2(Vector2(BAR_PAD, BAR_Y), Vector2(w - BAR_PAD * 2, BAR_H))
		WyrdUi.draw_well(self, bar_r)

		# ── HP fill (layered for depth, not flat) ─────────────────────────
		var fill_w := (bar_r.size.x - 6.0) * _frac
		if fill_w > 1.0:
			var fill := Rect2(bar_r.position + Vector2(3, 3),
				Vector2(fill_w, bar_r.size.y - 6.0))
			# base terracotta body
			draw_rect(fill, Color(0.64, 0.22, 0.13))
			# warmer left half — creates a subtle left-to-right gradient
			draw_rect(Rect2(fill.position,
				Vector2(fill.size.x * 0.48, fill.size.y)),
				Color(0.76, 0.30, 0.18, 0.50))
			# top highlight edge — the liquid surface catching the light
			draw_rect(Rect2(fill.position, Vector2(fill.size.x, 3.0)),
				Color(0.88, 0.50, 0.34, 0.58))

		# ── gold ◆ terminals at bar ends ─────────────────────────────────
		var bar_cy := BAR_Y + BAR_H * 0.5
		for mc in [Vector2(BAR_PAD - 10.0, bar_cy),
				Vector2(w - BAR_PAD + 10.0, bar_cy)]:
			var pts := PackedVector2Array([
				mc + Vector2(0, -5.5), mc + Vector2(5.5, 0),
				mc + Vector2(0,  5.5), mc + Vector2(-5.5, 0),
			])
			draw_colored_polygon(pts, Color(WyrdUi.GOLD, 0.82))
			draw_polyline(PackedVector2Array([
				mc + Vector2(0, -5.5), mc + Vector2(5.5, 0),
				mc + Vector2(0,  5.5), mc + Vector2(-5.5, 0),
				mc + Vector2(0, -5.5),
			]), Color(WyrdUi.KIT_EDGE, 0.55), 1.0)

		# ── ivy-leaf sprigs flanking the bar ─────────────────────────────
		# Left sprig (leaves open right-and-inward, berry on the far left).
		_draw_sprig(Vector2(BAR_PAD - 20.0, bar_cy), false)
		# Right sprig (mirrored).
		_draw_sprig(Vector2(w - BAR_PAD + 20.0, bar_cy), true)

	# A paired ivy-leaf motif: two almond leaves + a midrib line + a berry dot.
	# `base` is the attachment point (the ◆ tip); `flip` mirrors the X axis.
	func _draw_sprig(base: Vector2, flip: bool) -> void:
		var m := 1.0 if flip else -1.0

		# Upper leaf — tilts up-and-outward from the bar.
		var ul := PackedVector2Array([
			base,
			base + Vector2(m * 5.5, -9.5),
			base + Vector2(m * 12.0, -4.5),
			base + Vector2(m * 7.5,  1.0),
		])
		draw_colored_polygon(ul, Color(WyrdUi.SAGE, 0.83))
		draw_polyline(PackedVector2Array([ul[0], ul[1], ul[2], ul[3], ul[0]]),
			Color(WyrdUi.SAGE.darkened(0.36), 0.88), 1.0)
		# midrib
		draw_line(base, base + Vector2(m * 9.0, -5.5),
			Color(WyrdUi.SAGE.darkened(0.50), 0.52), 1.0)

		# Lower leaf — tilts down-and-outward, a touch darker.
		var ll := PackedVector2Array([
			base,
			base + Vector2(m * 5.5,  9.5),
			base + Vector2(m * 12.0,  4.5),
			base + Vector2(m * 7.5, -1.0),
		])
		draw_colored_polygon(ll, Color(WyrdUi.SAGE.darkened(0.12), 0.76))
		draw_polyline(PackedVector2Array([ll[0], ll[1], ll[2], ll[3], ll[0]]),
			Color(WyrdUi.SAGE.darkened(0.40), 0.85), 1.0)
		draw_line(base, base + Vector2(m * 9.0, 5.5),
			Color(WyrdUi.SAGE.darkened(0.50), 0.48), 1.0)

		# Tiny terracotta berry at the tip — a punch of warm colour in the foliage.
		var bc := base + Vector2(m * 14.5, 0.0)
		draw_circle(bc, 2.8, Color(WyrdUi.TERRACOTTA, 0.74))
		draw_arc(bc, 2.8, 0, TAU, 10, Color(WyrdUi.KIT_EDGE, 0.40), 1.0, true)
		# tiny specular highlight on the berry
		draw_circle(bc + Vector2(-m * 0.8, -0.9), 0.9, Color(1.0, 1.0, 1.0, 0.45))
