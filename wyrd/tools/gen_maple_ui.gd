extends SceneTree

# Generates the MapleStory-tone UI kit (2026-07-01) — clean glossy 9-patch
# textures matching the user-picked reference sheet maple_B_4: a green candy
# pill button, a cream-and-wood panel, and a glossy jade item slot. Rendered on
# the CPU with analytic anti-aliased rounded-rect SDFs (no supersample, no GPU),
# so it runs headless and produces smooth edges with correct alpha (no halos).
# Run once after editing:
#   godot --headless --path . --script res://tools/gen_maple_ui.gd
# Output → assets/ui/maple/*.png  (then re-import + reference from wyrd_ui.gd).

const OUT := "res://assets/ui/maple/"

# Palette sampled from maple_B_4.
const WOOD_D := Color8(69, 40, 30)
const WOOD_M := Color8(140, 92, 54)
const WOOD_L := Color8(190, 148, 100)
const GRN_T  := Color8(182, 216, 112)
const GRN_M  := Color8(120, 182, 74)
const GRN_D  := Color8(84, 140, 52)
const JADE_T := Color8(156, 226, 210)
const JADE_M := Color8(80, 182, 150)
const JADE_D := Color8(42, 120, 104)
const CREAM  := Color8(244, 224, 176)
const CREAM_D := Color8(214, 192, 146)
const GOLD   := Color8(216, 190, 120)

func _init() -> void:
	var dir := ProjectSettings.globalize_path(OUT)
	DirAccess.make_dir_recursive_absolute(dir)
	_gen_button()
	_gen_panel()
	_gen_slot()
	print("[maple] textures written to ", OUT)
	quit()

# Signed distance to a rounded rectangle centred at origin.
func _rr(p: Vector2, half: Vector2, r: float) -> float:
	var q := p.abs() - (half - Vector2(r, r))
	return Vector2(maxf(q.x, 0.0), maxf(q.y, 0.0)).length() + minf(maxf(q.x, q.y), 0.0) - r

func _img(w: int, h: int) -> Image:
	return Image.create(w, h, false, Image.FORMAT_RGBA8)

# The green candy pill button.
func _gen_button() -> void:
	var w := 132
	var h := 66
	var img := _img(w, h)
	var c := Vector2(w, h) * 0.5
	var half := c - Vector2(2.0, 2.0)
	var R := 26.0
	var bt := 5.5           # wood rim thickness
	for y in h:
		for x in w:
			var p := Vector2(x + 0.5, y + 0.5) - c
			var d := _rr(p, half, R)
			var fy := float(y) / float(h)
			# interior candy fill: bright gloss top → darker bottom
			var fill := GRN_T.lerp(GRN_D, clampf(fy * 1.05, 0.0, 1.0))
			var gloss := clampf(1.0 - fy / 0.44, 0.0, 1.0)
			fill = fill.lerp(Color(1, 1, 1), 0.34 * gloss * gloss)
			if fy > 0.74:
				fill = fill.darkened(0.12 * (fy - 0.74) / 0.26)
			# wood rim: light at the outer lip → dark inside
			var rim := WOOD_L.lerp(WOOD_D, clampf(-d / bt, 0.0, 1.0))
			var interior := clampf((-bt - d) + 0.5, 0.0, 1.0)   # 1 fill · 0 rim
			var col := rim.lerp(fill, interior)
			col.a = clampf(0.5 - d, 0.0, 1.0)                   # analytic edge AA
			img.set_pixel(x, y, col)
	img.save_png(OUT + "button_9p.png")

# The cream-and-wood panel (rounded, gold seam between wood and cream).
func _gen_panel() -> void:
	var w := 160
	var h := 160
	var img := _img(w, h)
	var c := Vector2(w, h) * 0.5
	var half := c - Vector2(2.0, 2.0)
	var R := 30.0
	var bt := 15.0
	for y in h:
		for x in w:
			var p := Vector2(x + 0.5, y + 0.5) - c
			var d := _rr(p, half, R)
			var fy := float(y) / float(h)
			var cream := CREAM.lerp(CREAM_D, clampf((fy - 0.15) * 0.6, 0.0, 1.0))
			var rim := WOOD_L.lerp(WOOD_D, clampf(-d / bt, 0.0, 1.0))
			var interior := clampf((-bt - d) + 0.5, 0.0, 1.0)
			var col := rim.lerp(cream, interior)
			# soft gold seam right at the wood→cream boundary
			var seam := 1.0 - clampf(absf(d + bt) / 2.2, 0.0, 1.0)
			col = col.lerp(GOLD, 0.55 * seam)
			col.a = clampf(0.5 - d, 0.0, 1.0)
			img.set_pixel(x, y, col)
	img.save_png(OUT + "panel_9p.png")

# The glossy jade item slot (wood frame + recessed candy-jade well).
func _gen_slot() -> void:
	var w := 96
	var h := 96
	var img := _img(w, h)
	var c := Vector2(w, h) * 0.5
	var half := c - Vector2(2.0, 2.0)
	var R := 22.0
	var bt := 8.0
	for y in h:
		for x in w:
			var p := Vector2(x + 0.5, y + 0.5) - c
			var d := _rr(p, half, R)
			var fy := float(y) / float(h)
			# jade well: glossy top → deep bottom
			var jade := JADE_T.lerp(JADE_D, clampf(fy * 1.1, 0.0, 1.0))
			var gloss := clampf(1.0 - fy / 0.4, 0.0, 1.0)
			jade = jade.lerp(Color(1, 1, 1), 0.30 * gloss * gloss)
			# inner recess shadow hugging the frame
			var recess := clampf((d + bt + 6.0) / 6.0, 0.0, 1.0)  # ~1 near frame
			jade = jade.darkened(0.22 * recess)
			var rim := WOOD_L.lerp(WOOD_D, clampf(-d / bt, 0.0, 1.0))
			var interior := clampf((-bt - d) + 0.5, 0.0, 1.0)
			var col := rim.lerp(jade, interior)
			col.a = clampf(0.5 - d, 0.0, 1.0)
			img.set_pixel(x, y, col)
	img.save_png(OUT + "slot_9p.png")
