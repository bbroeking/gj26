class_name WyrdUi
extends RefCounted

# Wyrd — the shared hand-drawn parchment skin for every code-built panel.
# Textures come from the AI-imaging pass (assets/ui/, generated 2026-06-10
# against the docs/UI_BIBLE.md master stem: wobbly sepia ink on aged cream,
# watercolor washes). One place for palette and styleboxes; if the textures
# go missing everything degrades to the old flat-ink look.

# UI bible palette (docs/UI_BIBLE.md).
const INK := Color("3a2c20")             # sepia ink — body text on parchment
const INK_MID := Color("6b574a")         # secondary / hints
const TERRACOTTA := Color("b14c33")      # titles / accents / danger
const SAGE := Color("6f8a3f")            # good twin / fresh
const GOLD := Color("b58637")            # burnished gold highlights
const CREAM := Color("f3e6cb")

# Back-compat aliases (earlier panels reference these names).
const PARCHMENT := INK                   # body text color ON parchment
const PARCH_DIM := INK_MID
const GREEN := SAGE
const RUST := TERRACOTTA

# Spec 39 — pale carved wood frame (Midjourney, docs/ui-refs/mj_panel_wood.png).
# Verified by tools/check_ninepatch.py (center std 9.6, margin spread 12%).
const PANEL_TEX_PATH := "res://assets/ui/panel_frame_v2_9p.png"
const BUTTON_TEX_PATH := "res://assets/ui/button_plate_9p.png"
const PANEL_MARGIN_L := 34.0
const PANEL_MARGIN_T := 37.0
const PANEL_MARGIN_R := 32.0
const PANEL_MARGIN_B := 40.0
const PANEL_MARGIN := 40.0               # max side — for symmetric-inset math

# The one place panel styleboxes come from (spec 39 consolidation).
static func panel_stylebox() -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = load(PANEL_TEX_PATH)
	sb.texture_margin_left = PANEL_MARGIN_L
	sb.texture_margin_top = PANEL_MARGIN_T
	sb.texture_margin_right = PANEL_MARGIN_R
	sb.texture_margin_bottom = PANEL_MARGIN_B
	return sb
const BUTTON_MARGIN := 18.0

# UI bible fonts: IM Fell English (body), IM Fell English SC (headers),
# Caveat (hand-jotted notes — toasts, costs, margin scribbles).
const FONT_BODY_PATH := "res://assets/fonts/IMFellEnglish-Regular.ttf"
const FONT_HEADER_PATH := "res://assets/fonts/IMFellEnglishSC-Regular.ttf"
const FONT_HAND_PATH := "res://assets/fonts/Caveat.ttf"

static func font_body() -> Font:
	return load(FONT_BODY_PATH) if ResourceLoader.exists(FONT_BODY_PATH) else null

static func font_header() -> Font:
	return load(FONT_HEADER_PATH) if ResourceLoader.exists(FONT_HEADER_PATH) else null

static func font_hand() -> Font:
	return load(FONT_HAND_PATH) if ResourceLoader.exists(FONT_HAND_PATH) else null

static func _set_font(c: Control, f: Font) -> void:
	if f != null:
		c.add_theme_font_override("font", f)

# Outlined label floating over the 3D world (objective, trades, prompts').
static func style_hud_label(l: Label, size: int = 16,
		color: Color = Color(0.96, 0.92, 0.80)) -> void:
	_set_font(l, font_header())
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0.12, 0.09, 0.06))
	l.add_theme_constant_override("outline_size", 7)

# A parchment meter (HP / Focus / boss bar): button-plate trough + a
# rounded watercolor fill + an ink label. Returns {root, fill, label};
# drive it with set_meter(parts, ratio).
# Spec 41 — kit tokens (the Claude Design 'Wayfinder UI Kit' page).
const KIT_PLATE := Color(0.93, 0.88, 0.74)   # parchment plate
const KIT_WELL := Color(0.80, 0.72, 0.58)    # recessed well / trough
const KIT_EDGE := Color(0.26, 0.19, 0.13)    # ink edge

# Parchment chip — the kit's smallest container (toasts, hints, counters).
static func chip_stylebox(bg := KIT_PLATE) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = KIT_EDGE
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(4)
	# Spec 44 — a soft under-shadow so chips and buttons sit ON the
	# parchment instead of floating flat in it.
	sb.shadow_color = Color(0, 0, 0, 0.16)
	sb.shadow_size = 2
	sb.shadow_offset = Vector2(0, 2)
	sb.content_margin_left = 10.0
	sb.content_margin_right = 10.0
	sb.content_margin_top = 4.0
	sb.content_margin_bottom = 4.0
	return sb

static func style_chip(l: Label, size: int = 14) -> void:
	l.add_theme_stylebox_override("normal", chip_stylebox())
	l.add_theme_color_override("font_color", INK)
	l.add_theme_font_size_override("font_size", size)

static func style_kit_button(b: Button) -> void:
	b.add_theme_font_size_override("font_size", 15)
	b.add_theme_color_override("font_color", INK)
	b.add_theme_color_override("font_hover_color", TERRACOTTA)
	b.add_theme_color_override("font_pressed_color", TERRACOTTA)
	# Use the painted wood button plate so kit buttons read as carved objects
	# (HUD action bar + craft/vendor/loadout rows), not flat parchment chips.
	if ResourceLoader.exists(BUTTON_TEX_PATH):
		b.add_theme_stylebox_override("normal", _btn_tex(Color.WHITE))
		b.add_theme_stylebox_override("hover", _btn_tex(Color(1.06, 1.03, 0.95)))
		b.add_theme_stylebox_override("pressed", _btn_tex(Color(0.88, 0.84, 0.76)))
	else:
		b.add_theme_stylebox_override("normal", chip_stylebox())
		b.add_theme_stylebox_override("hover", chip_stylebox(KIT_PLATE.lightened(0.06)))
		b.add_theme_stylebox_override("pressed", chip_stylebox(KIT_WELL))

static func make_meter(width: float, height: float, fill_color: Color) -> Dictionary:
	var root := Panel.new()
	root.custom_minimum_size = Vector2(width, height)
	root.size = Vector2(width, height)
	# Spec 41 — kit treatment: flat trough + ink border (boss bar et al).
	var sb := StyleBoxFlat.new()
	sb.bg_color = KIT_WELL
	sb.border_color = KIT_EDGE
	sb.set_border_width_all(2)
	root.add_theme_stylebox_override("panel", sb)
	var fill := Panel.new()
	fill.name = "MeterFill"
	var fb := StyleBoxFlat.new()
	fb.bg_color = fill_color
	fb.set_corner_radius_all(2)
	fill.add_theme_stylebox_override("panel", fb)
	fill.position = Vector2(3, 3)
	fill.size = Vector2(width - 6, height - 6)
	root.add_child(fill)
	var label := Label.new()
	label.name = "MeterLabel"
	_set_font(label, font_header())
	label.add_theme_font_size_override("font_size", int(height * 0.52))
	label.add_theme_color_override("font_color", INK)
	label.anchor_right = 1.0
	label.anchor_bottom = 1.0
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	root.add_child(label)
	return {"root": root, "fill": fill, "label": label,
		"full_w": width - 14.0}

static func set_meter(parts: Dictionary, ratio: float, text: String) -> void:
	(parts.fill as Control).size.x = maxf(0.0, parts.full_w * clampf(ratio, 0.0, 1.0))
	(parts.label as Label).text = text

static func style_panel(p: Panel) -> void:
	if ResourceLoader.exists(PANEL_TEX_PATH):
		var sb := panel_stylebox()
		sb.set_content_margin_all(PANEL_MARGIN * 0.8)
		p.add_theme_stylebox_override("panel", sb)
		return
	var fb := StyleBoxFlat.new()
	fb.bg_color = Color(0.135, 0.110, 0.085, 0.97)
	fb.border_color = Color(0.58, 0.47, 0.30)
	fb.set_border_width_all(2)
	fb.set_corner_radius_all(8)
	fb.set_content_margin_all(10)
	p.add_theme_stylebox_override("panel", fb)

static func style_button(b: Button) -> void:
	# Buttons are read, not admired — clean default font (usability pass).
	b.add_theme_font_size_override("font_size", 15)
	b.add_theme_color_override("font_color", INK)
	b.add_theme_color_override("font_hover_color", TERRACOTTA)
	b.add_theme_color_override("font_pressed_color", TERRACOTTA)
	b.add_theme_color_override("font_disabled_color", Color(INK_MID, 0.55))
	if ResourceLoader.exists(BUTTON_TEX_PATH):
		b.add_theme_stylebox_override("normal", _btn_tex(Color.WHITE))
		b.add_theme_stylebox_override("hover", _btn_tex(Color(1.05, 1.02, 0.94)))
		b.add_theme_stylebox_override("pressed", _btn_tex(Color(0.90, 0.86, 0.78)))
		b.add_theme_stylebox_override("disabled", _btn_tex(Color(1.0, 1.0, 1.0, 0.45)))
	else:
		b.add_theme_stylebox_override("normal", _btn_flat(Color(0.20, 0.165, 0.125)))
		b.add_theme_stylebox_override("hover", _btn_flat(Color(0.26, 0.215, 0.16)))
		b.add_theme_stylebox_override("pressed", _btn_flat(Color(0.165, 0.135, 0.10)))
		b.add_theme_stylebox_override("disabled", _btn_flat(Color(0.155, 0.13, 0.105, 0.6)))
	var focus := StyleBoxFlat.new()
	focus.draw_center = false
	focus.border_color = GOLD
	focus.set_border_width_all(1)
	focus.set_corner_radius_all(6)
	b.add_theme_stylebox_override("focus", focus)

static func _btn_tex(mod: Color) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = load(BUTTON_TEX_PATH)
	sb.texture_margin_left = BUTTON_MARGIN
	sb.texture_margin_right = BUTTON_MARGIN
	sb.texture_margin_top = BUTTON_MARGIN
	sb.texture_margin_bottom = BUTTON_MARGIN
	sb.content_margin_left = 12.0
	sb.content_margin_right = 12.0
	sb.content_margin_top = 5.0
	sb.content_margin_bottom = 5.0
	sb.modulate_color = mod
	return sb

static func _btn_flat(bg: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = Color(0.45, 0.37, 0.25)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 10.0
	sb.content_margin_right = 10.0
	sb.content_margin_top = 6.0
	sb.content_margin_bottom = 6.0
	return sb

# Selected list entry (toggled template / chart / trophy buttons) — a sage
# ink ring over the parchment plate.
static func mark_selected(b: Button, selected: bool) -> void:
	if not selected:
		return
	if ResourceLoader.exists(BUTTON_TEX_PATH):
		var sb := _btn_tex(Color(0.94, 1.0, 0.88))
		b.add_theme_stylebox_override("normal", sb)
		b.add_theme_stylebox_override("hover", sb)
		b.add_theme_color_override("font_color", SAGE.darkened(0.25))
	else:
		var fb := _btn_flat(Color(0.28, 0.23, 0.15))
		fb.border_color = GOLD
		fb.set_border_width_all(2)
		b.add_theme_stylebox_override("normal", fb)
		b.add_theme_stylebox_override("hover", fb)

static func style_title(l: Label) -> void:
	_set_font(l, font_header())
	l.add_theme_font_size_override("font_size", 30)
	l.add_theme_color_override("font_color", TERRACOTTA)

static func style_section(l: Label) -> void:
	_set_font(l, font_header())
	l.add_theme_font_size_override("font_size", 17)
	l.add_theme_color_override("font_color", TERRACOTTA)

static func style_body(l: Label, size: int = 13) -> void:
	# Clean default font for body text (usability pass) — IM Fell stays on
	# titles and section headers only.
	l.add_theme_font_size_override("font_size", size + 1)
	l.add_theme_color_override("font_color", INK)

static func style_dim(l: Label, size: int = 12) -> void:
	l.add_theme_font_size_override("font_size", size + 1)
	l.add_theme_color_override("font_color", INK_MID)

# ---- spec 44: drawn-detail primitives (the UI detail pass) ----
# Shared by code-drawn panels (bench, pack, trades) so every recessed well,
# carved button, and parchment face reads the same. Pure vector draws — no
# textures touched (the _draw/load white-rect gotcha stays impossible).

# Spec C — the shared list-row plate. Every code-drawn modal list (vendor
# wares, loadout skills, the pack's satchel + charts) sits a row on this so the
# panels read as carved cards, not a flat spreadsheet. A KIT_PLATE face, a top
# light bevel, a KIT_EDGE border, and a 3px accent stripe down the LEFT edge.
# Accent convention: SAGE = good/available, TERRACOTTA = locked/danger,
# GOLD = selected, INK_MID = neutral. Template: crafting_bench _tray_row.
static func draw_list_row(c: CanvasItem, r: Rect2, accent: Color) -> void:
	c.draw_rect(r, KIT_PLATE)
	# top light bevel — the card catches the page's warm light
	c.draw_rect(Rect2(r.position + Vector2(1.0, 1.0),
		Vector2(r.size.x - 2.0, 1.5)), Color(1.0, 1.0, 0.93, 0.40))
	# soft bottom shade so the card sits ON the parchment
	c.draw_rect(Rect2(r.position + Vector2(2.0, r.size.y - 2.5),
		Vector2(r.size.x - 4.0, 1.5)), Color(KIT_EDGE, 0.22))
	c.draw_rect(r, KIT_EDGE, false, 1.5)
	# accent stripe down the left edge — the row's state at a glance
	c.draw_rect(Rect2(r.position + Vector2(1.5, 1.5),
		Vector2(3.0, r.size.y - 3.0)), accent)

# A recessed rectangular well: stepped inner shadow top-left, light lip
# bottom — the socket reads as carved INTO the bench, not painted on.
static func draw_well(c: CanvasItem, r: Rect2, fill := KIT_WELL) -> void:
	c.draw_rect(r, fill)
	for i in 3:
		var a := 0.16 - 0.05 * float(i)
		var inset := 1.0 + float(i) * 1.5
		c.draw_rect(Rect2(r.position + Vector2(inset, inset),
			Vector2(r.size.x - inset * 2.0, 2.0)), Color(0, 0, 0, a))
		c.draw_rect(Rect2(r.position + Vector2(inset, inset),
			Vector2(2.0, r.size.y - inset * 2.0)), Color(0, 0, 0, a))
	c.draw_rect(Rect2(r.position + Vector2(2.0, r.size.y - 3.0),
		Vector2(r.size.x - 4.0, 2.0)), Color(1.0, 1.0, 0.92, 0.35))
	c.draw_rect(r, KIT_EDGE, false, 2.0)

# Round well — ink sockets, pot rims.
static func draw_round_well(c: CanvasItem, center: Vector2, radius: float,
		fill := KIT_WELL) -> void:
	c.draw_circle(center, radius, fill)
	c.draw_arc(center, radius - 2.5, PI * 0.78, PI * 1.95, 22,
		Color(0, 0, 0, 0.18), 3.0, true)
	c.draw_arc(center, radius - 2.5, -PI * 0.22, PI * 0.30, 16,
		Color(1.0, 1.0, 0.92, 0.30), 2.0, true)
	c.draw_arc(center, radius, 0, TAU, 40, KIT_EDGE, 2.0, true)

# A carved button face: plate, light top bevel, dark bottom bevel, inner
# pinstripe. Callers draw their own label on top.
static func draw_carved_button(c: CanvasItem, r: Rect2, enabled := true) -> void:
	c.draw_rect(r, KIT_PLATE if enabled else Color(0.84, 0.78, 0.65))
	c.draw_rect(Rect2(r.position + Vector2(2.0, 2.0),
		Vector2(r.size.x - 4.0, 2.0)), Color(1.0, 1.0, 0.93, 0.55))
	c.draw_rect(Rect2(r.position + Vector2(2.0, r.size.y - 4.0),
		Vector2(r.size.x - 4.0, 2.0)), Color(KIT_EDGE, 0.35))
	c.draw_rect(r, KIT_EDGE, false, 2.0)
	c.draw_rect(r.grow(-3.0), Color(KIT_EDGE, 0.30), false, 1.0)

# Sparse parchment grain — short sepia fibre strokes, deterministic seed
# (no Math.random drift between redraws).
static func draw_parchment_grain(c: CanvasItem, r: Rect2, seed_v: int = 7) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	var n := int(r.size.x * r.size.y / 2600.0)
	for _i in n:
		var p := r.position + Vector2(rng.randf() * r.size.x,
			rng.randf() * r.size.y)
		var ln := 3.0 + rng.randf() * 7.0
		c.draw_line(p, p + Vector2(ln, rng.randf_range(-1.2, 1.2)),
			Color(0.62, 0.52, 0.38, 0.05 + rng.randf() * 0.05), 1.0)

# Section flourish: ── ◆ ── centred under a header.
static func draw_flourish(c: CanvasItem, center: Vector2, width: float) -> void:
	var col := Color(KIT_EDGE, 0.45)
	c.draw_line(center - Vector2(width * 0.5, 0), center - Vector2(7, 0), col, 1.0)
	c.draw_line(center + Vector2(7, 0), center + Vector2(width * 0.5, 0), col, 1.0)
	var pts := PackedVector2Array([center + Vector2(0, -3.5),
		center + Vector2(3.5, 0), center + Vector2(0, 3.5),
		center + Vector2(-3.5, 0)])
	c.draw_colored_polygon(pts, Color(GOLD, 0.8))

# A little hand-blown ink bottle — glass body, ink fill, neck, cork, and a
# glass highlight. Replaces the bare text glyphs in sockets and trays.
static func draw_ink_bottle(c: CanvasItem, center: Vector2, h: float,
		ink: Color) -> void:
	var w := h * 0.62
	var body := Rect2(center + Vector2(-w * 0.5, -h * 0.18),
		Vector2(w, h * 0.62))
	c.draw_rect(body, Color(0.88, 0.92, 0.90, 0.55))
	c.draw_rect(Rect2(body.position + Vector2(1.5, body.size.y * 0.28),
		Vector2(body.size.x - 3.0, body.size.y * 0.72 - 1.5)), ink)
	c.draw_rect(body, KIT_EDGE, false, 1.5)
	var neck := Rect2(center + Vector2(-w * 0.18, -h * 0.42),
		Vector2(w * 0.36, h * 0.26))
	c.draw_rect(neck, Color(0.88, 0.92, 0.90, 0.7))
	c.draw_rect(neck, KIT_EDGE, false, 1.5)
	c.draw_rect(Rect2(center + Vector2(-w * 0.24, -h * 0.54),
		Vector2(w * 0.48, h * 0.13)), Color(0.62, 0.46, 0.30))
	c.draw_line(body.position + Vector2(2.5, 2.0),
		body.position + Vector2(2.5, body.size.y - 3.0),
		Color(1, 1, 1, 0.45), 1.5)

# A rolled parchment scroll with a wax seal — the chart-in-a-socket read.
static func draw_scroll(c: CanvasItem, r: Rect2, sealed := true) -> void:
	var face := Rect2(r.position + Vector2(r.size.x * 0.08, r.size.y * 0.12),
		Vector2(r.size.x * 0.84, r.size.y * 0.76))
	c.draw_rect(face, Color(0.96, 0.91, 0.78))
	# rolled ends — darker cylinders at left + right
	var roll_w := r.size.x * 0.07
	c.draw_rect(Rect2(face.position - Vector2(roll_w * 0.6, 2.0),
		Vector2(roll_w, face.size.y + 4.0)), Color(0.86, 0.78, 0.62))
	c.draw_rect(Rect2(Vector2(face.end.x - roll_w * 0.4, face.position.y - 2.0),
		Vector2(roll_w, face.size.y + 4.0)), Color(0.86, 0.78, 0.62))
	c.draw_rect(face, KIT_EDGE, false, 1.5)
	# faint chart scratches
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for _i in 4:
		var y := face.position.y + face.size.y * (0.25 + rng.randf() * 0.5)
		c.draw_line(Vector2(face.position.x + 6.0, y),
			Vector2(face.position.x + 6.0 + rng.randf() * face.size.x * 0.5, y),
			Color(KIT_EDGE, 0.25), 1.0)
	if sealed:
		var sc := Vector2(face.end.x - 10.0, face.end.y - 8.0)
		c.draw_circle(sc, 7.5, Color(0.62, 0.20, 0.16))
		c.draw_circle(sc, 4.5, Color(0.72, 0.28, 0.22))
		# Pressed compass-cross sigil — the Wayfinder's mark stamped in the wax.
		var imp := Color(0.40, 0.12, 0.10, 0.72)
		c.draw_line(sc + Vector2(-2.5, 0.0), sc + Vector2(2.5, 0.0), imp, 1.2)
		c.draw_line(sc + Vector2(0.0, -2.5), sc + Vector2(0.0, 2.5), imp, 1.2)
		# Wax glint — upper-left moon where the warm light catches the pooled surface.
		c.draw_arc(sc + Vector2(-1.5, -1.5), 2.8, PI * 1.0, PI * 1.45, 7,
			Color(0.90, 0.56, 0.42, 0.48), 1.5, true)
		c.draw_arc(sc, 7.5, 0, TAU, 20, Color(0.40, 0.12, 0.10), 1.5, true)
