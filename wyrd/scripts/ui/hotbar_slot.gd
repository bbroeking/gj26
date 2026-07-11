extends Control

# A carved storybook hotbar slot. Draws its own face (carved button + recessed
# icon well + parchment grain), a true RADIAL cooldown wedge (square-clamped so
# it never bulges past the slot), and a gold ready-flash when a skill comes off
# cooldown. The icon/glyph/keybind/cost are children added by skill_bar.gd and
# render over this _draw. Pure-vector (no texture in _draw — gotcha-safe).

var cd_ratio: float = 0.0      # 1 = just cast (full dark wedge) → 0 = ready
var castable: bool = true
var _flash: float = 0.0        # gold rim pulse, 0..1, on coming off cooldown
var _seed: int = 7
var _last_ratio: float = -1.0
var _last_castable: bool = true

func _ready() -> void:
	_seed = int(position.x) ^ 0x2b3c

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

func _process(delta: float) -> void:
	if _flash > 0.0:
		_flash = maxf(0.0, _flash - delta * 2.6)
		queue_redraw()

func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	WyrdUi.draw_carved_button(self, r, castable)
	WyrdUi.draw_well(self, r.grow(-7.0), WyrdUi.KIT_PLATE.lightened(0.05))
	WyrdUi.draw_parchment_grain(self, r, _seed)
	# Radial cooldown wedge — a square-clamped pie from 12 o'clock clockwise,
	# shrinking as the skill cools. Drawn as a two-layer ink wash so it reads
	# as pigment (a storybook "sealed with ink" cover) rather than a flat
	# engine mask. A thin brush-tip arc at the leading edge marks the frontier.
	if cd_ratio > 0.001:
		var c := size * 0.5
		var h := size.x * 0.5
		var a0 := -PI * 0.5
		var a1 := a0 + TAU * clampf(cd_ratio, 0.0, 1.0)
		var steps := 40
		# --- outer wash: full depth, pooled at the rim ---
		var pts := PackedVector2Array()
		pts.append(c)
		for i in steps + 1:
			var a := lerpf(a0, a1, float(i) / float(steps))
			var dx := cos(a)
			var dy := sin(a)
			var d := h / maxf(absf(dx), absf(dy))
			pts.append(c + Vector2(dx, dy) * d)
		draw_colored_polygon(pts, Color(0.10, 0.08, 0.07, 0.48))
		# --- inner wash: the watercolour bleed from the centre, lighter ---
		# A smaller pie at 65% radius gives the "ink pooling at the rim,
		# thinning toward the centre" read of a real watercolour wash.
		var inner := PackedVector2Array()
		inner.append(c)
		var inner_r := h * 0.65
		for i in steps + 1:
			var a := lerpf(a0, a1, float(i) / float(steps))
			inner.append(c + Vector2(cos(a), sin(a)) * inner_r)
		draw_colored_polygon(inner, Color(0.14, 0.11, 0.09, 0.18))
		# --- brush-tip arc at the leading edge ---
		# A short sepia stroke spanning ≈15° before the frontier — the
		# "last brushstroke" that tells the eye the wedge is sweeping, not
		# static. Fades as cd_ratio approaches 1 (full wash, no frontier).
		var arc_span := minf(0.26, TAU * cd_ratio * 0.22)
		if arc_span > 0.04:
			var arc_pts := PackedVector2Array()
			for i in 8:
				var a := lerpf(a1 - arc_span, a1, float(i) / 7.0)
				var dx := cos(a)
				var dy := sin(a)
				var d := h / maxf(absf(dx), absf(dy))
				arc_pts.append(c + Vector2(dx, dy) * (d - 1.5))
			draw_polyline(arc_pts, Color(WyrdUi.INK, 0.50), 2.0, true)
	if _flash > 0.0:
		draw_rect(r.grow(-1.5), Color(WyrdUi.GOLD, _flash * 0.85), false, 3.0)
