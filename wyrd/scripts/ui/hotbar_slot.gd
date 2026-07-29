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
	# Carved rune-mount corners: eight tiny L-shaped gold braces (2 per corner)
	# just inside the slot face. They sit under the cooldown wedge and emerge as
	# it shrinks — when fully ready all four glow at 55 % gold; the ready-flash
	# surges them to near-full, giving each slot a jeweled-artifact quality.
	var brace_a := 0.55 if castable else 0.22
	if _flash > 0.0:
		brace_a = lerpf(brace_a, 1.0, _flash)
	var brace_c := Color(WyrdUi.GOLD, brace_a)
	var face := r.grow(-2.5)
	for corner in 4:
		var px := face.position.x if (corner & 1) == 0 else face.end.x
		var py := face.position.y if (corner & 2) == 0 else face.end.y
		var dx := 1.0 if (corner & 1) == 0 else -1.0
		var dy := 1.0 if (corner & 2) == 0 else -1.0
		draw_line(Vector2(px, py), Vector2(px + dx * 6.0, py), brace_c, 1.6)
		draw_line(Vector2(px, py), Vector2(px, py + dy * 6.0), brace_c, 1.6)
	# Radial cooldown wedge — a square-clamped pie from 12 o'clock clockwise,
	# shrinking as the skill cools. Vertices ride the slot's own edge so it
	# reads as the slot face darkening, with no overshoot into the gaps.
	if cd_ratio > 0.001:
		var c := size * 0.5
		var h := size.x * 0.5
		var a0 := -PI * 0.5
		var a1 := a0 + TAU * clampf(cd_ratio, 0.0, 1.0)
		var pts := PackedVector2Array()
		pts.append(c)
		var steps := 40
		for i in steps + 1:
			var a := lerpf(a0, a1, float(i) / float(steps))
			var dx := cos(a)
			var dy := sin(a)
			var d := h / maxf(absf(dx), absf(dy))
			pts.append(c + Vector2(dx, dy) * d)
		draw_colored_polygon(pts, Color(0.10, 0.08, 0.07, 0.52))
	if _flash > 0.0:
		draw_rect(r.grow(-1.5), Color(WyrdUi.GOLD, _flash * 0.85), false, 3.0)
