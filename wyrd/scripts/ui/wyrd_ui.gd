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
	sb.set_corner_radius_all(3)
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
	b.add_theme_stylebox_override("normal", chip_stylebox())
	b.add_theme_stylebox_override("hover", chip_stylebox(KIT_PLATE.lightened(0.06)))
	b.add_theme_stylebox_override("pressed", chip_stylebox(KIT_WELL))
	b.add_theme_font_size_override("font_size", 15)
	b.add_theme_color_override("font_color", INK)

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
