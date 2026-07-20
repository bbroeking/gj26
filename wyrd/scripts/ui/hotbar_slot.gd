extends Button

const Tokens = preload("res://scripts/ui/foundation/ui_tokens.gd")

# A hotbar slot. MapleStory (2026-07-01): a ROUND glossy jade slot in a wood
# ring — the same round family as the HP/Focus orbs, so the whole bottom row
# reads as one cluster (references: hud2_cradle_3 et al). Falls back to the
# carved-enamel square slot when the maple kit is absent. Draws a radial cooldown
# wedge + a Heartwood-Ward arc + a gold ready-flash; the icon/keybind/cost are
# children rendered over this _draw. Pure-vector (gotcha-safe).

var cd_ratio: float = 0.0      # 1 = just cast (full dark wedge) → 0 = ready
var ward_frac: float = 0.0     # C8 — Heartwood Ward absorb remaining (0..1)
var castable: bool = true
var _flash: float = 0.0        # gold rim pulse, 0..1, on coming off cooldown
var _seed: int = 7
var _last_ratio: float = -1.0
var _last_castable: bool = true
var _maple: bool = false

func _ready() -> void:
	_seed = int(position.x) ^ 0x2b3c
	_maple = false
	flat = true
	focus_mode = Control.FOCUS_ALL

func set_state(ratio: float, can_cast: bool) -> void:
	if cd_ratio > 0.001 and ratio <= 0.001:
		_flash = 1.0           # just came off cooldown — fire the ready flash
	cd_ratio = ratio
	castable = can_cast
	if not is_equal_approx(ratio, _last_ratio) or can_cast != _last_castable \
			or _flash > 0.0:
		_last_ratio = ratio
		_last_castable = can_cast
		queue_redraw()

func set_ward(frac: float) -> void:
	var f := clampf(frac, 0.0, 1.0)
	if not is_equal_approx(f, ward_frac):
		ward_frac = f
		queue_redraw()

func _process(delta: float) -> void:
	if _flash > 0.0:
		_flash = maxf(0.0, _flash - delta * 2.6)
		queue_redraw()

func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	var face := StyleBoxFlat.new()
	face.bg_color = Tokens.MOSS if castable else Tokens.DISABLED_SURFACE.darkened(0.25)
	face.set_corner_radius_all(10)
	face.set_border_width_all(3 if has_focus() else 2)
	face.border_color = Tokens.SAGE if has_focus() else Tokens.WALNUT
	face.shadow_color = Color(0, 0, 0, 0.24)
	face.shadow_size = 4
	face.shadow_offset = Vector2(0, 2)
	draw_style_box(face, r.grow(-2.0))
	var well := StyleBoxFlat.new()
	well.bg_color = Color(Tokens.WALNUT_DEEP, 0.42)
	well.set_corner_radius_all(7)
	draw_style_box(well, r.grow(-7.0))
	_draw_cd_square()
	_draw_ward_flash(r)

# MapleStory round jade slot + a circular cooldown sector.
func _draw_round(r: Rect2) -> void:
	var c := size * 0.5
	var rad := minf(size.x, size.y) * 0.5 - 3.0
	# soft drop shadow
	draw_circle(c + Vector2(0, 2.5), rad + 5.0, Color(0, 0, 0, 0.18))
	# chunky wood ring + gold seam
	draw_arc(c, rad + 3.0, 0, TAU, 44, WyrdUi.MAPLE_WOOD_D, 6.0, true)
	draw_arc(c, rad + 2.0, 0, TAU, 44, WyrdUi.MAPLE_WOOD, 4.0, true)
	# glossy jade well: base fill, upper gloss, hard specular
	var base: Color = WyrdUi.MAPLE_JADE if castable else WyrdUi.MAPLE_JADE_D.darkened(0.1)
	draw_circle(c, rad, base)
	draw_circle(c + Vector2(0, rad * 0.55), rad * 0.7, WyrdUi.MAPLE_JADE_D.lerp(base, 0.4))
	draw_circle(c - Vector2(0, rad * 0.34), rad * 0.62, Color(WyrdUi.MAPLE_JADE_HI, 0.45))
	draw_circle(c - Vector2(rad * 0.26, rad * 0.40), rad * 0.20, Color(1, 1, 1, 0.55))
	draw_arc(c, rad, 0, TAU, 44, Color(WyrdUi.GOLD, 0.7), 1.5, true)
	# circular cooldown sector from 12 o'clock
	if cd_ratio > 0.001:
		var a0 := -PI * 0.5
		var a1 := a0 + TAU * clampf(cd_ratio, 0.0, 1.0)
		var pts := PackedVector2Array([c])
		var steps := 40
		for i in steps + 1:
			var a := lerpf(a0, a1, float(i) / float(steps))
			pts.append(c + Vector2(cos(a), sin(a)) * rad)
		draw_colored_polygon(pts, Color(0.06, 0.05, 0.04, 0.55))
	if ward_frac > 0.001:
		var a0w := -PI * 0.5
		draw_arc(c, rad - 1.0, a0w, a0w + TAU * ward_frac, 40,
			Color(0.46, 0.33, 0.18, 0.95), 4.0, true)
	if _flash > 0.0:
		draw_arc(c, rad + 1.0, 0, TAU, 44, Color(WyrdUi.GOLD, _flash * 0.9), 3.0, true)

func _draw_cd_square() -> void:
	if cd_ratio <= 0.001:
		return
	var c := size * 0.5
	var h := size.x * 0.5
	var a0 := -PI * 0.5
	var a1 := a0 + TAU * clampf(cd_ratio, 0.0, 1.0)
	var pts := PackedVector2Array([c])
	var steps := 40
	for i in steps + 1:
		var a := lerpf(a0, a1, float(i) / float(steps))
		var dx := cos(a)
		var dy := sin(a)
		var d := h / maxf(absf(dx), absf(dy))
		pts.append(c + Vector2(dx, dy) * d)
	draw_colored_polygon(pts, Color(0.10, 0.08, 0.07, 0.52))

func _draw_ward_flash(r: Rect2) -> void:
	if ward_frac > 0.001:
		var c := size * 0.5
		var rad := size.x * 0.5 - 2.5
		var a0 := -PI * 0.5
		draw_arc(c, rad, a0, a0 + TAU * ward_frac, 40,
			Color(0.46, 0.33, 0.18, 0.95), 4.0, true)
	if _flash > 0.0:
		draw_rect(r.grow(-1.5), Color(WyrdUi.GOLD, _flash * 0.85), false, 3.0)
