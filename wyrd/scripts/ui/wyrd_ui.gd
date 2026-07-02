class_name WyrdUi
extends RefCounted

# Wyrd — the shared hand-drawn parchment skin for every code-built panel.
# Textures come from the AI-imaging pass (assets/ui/, generated 2026-06-10
# against the docs/UI_BIBLE.md master stem: wobbly sepia ink on aged cream,
# watercolor washes). One place for palette and styleboxes; if the textures
# go missing everything degrades to the old flat-ink look.

# UI bible palette (docs/UI_BIBLE.md).
# Spec 51 — DARK skin (was bright parchment, which floated over the dark dungeon).
# Light-on-dark: INK is now warm CREAM body text; panels darken via PANEL_MOD/
# BTN_MOD modulating the carved-wood ninepatch into deep enamel-teal, with
# leaf-gold (GOLD) filigree on edges/titles. (Direction: Storybook Enamel Night,
# spec 51 — picked over Dark Carved Walnut. Replaces the pale-parchment HUD that
# floated over the dark dungeon.)
const INK := Color(0.937, 0.906, 0.812)  # warm cream — body text on dark panels
const INK_MID := Color(0.624, 0.690, 0.612)  # sage-grey — secondary / hints
const TERRACOTTA := Color(0.835, 0.416, 0.271)  # ember — titles / accents / danger
const SAGE := Color(0.651, 0.761, 0.392)  # good twin / fresh
const GOLD := Color(0.890, 0.722, 0.361)  # leaf-gold filigree
const CREAM := Color(0.953, 0.902, 0.796)

# Back-compat aliases (earlier panels reference these names).
const PARCHMENT := INK                   # body text color ON parchment
const PARCH_DIM := INK_MID
const GREEN := SAGE
const RUST := TERRACOTTA

# Spec 53 (taste pass) — palette-correct semantic colors that callers used to
# improvise off-palette (Focus was stock mana-blue; "magic" rarity was a cold
# SaaS blue). Focus is a luminous teal-cyan, the cool twin to HP's warm ember.
const FOCUS := Color(0.34, 0.74, 0.78)      # luminous teal-cyan — Focus/mana
const NUMERIC := Color(0.71, 0.83, 0.74)    # cool cream — costs / counts on dark
# One rarity ramp for the whole game (pack, loot beam, vendor, tooltips).
const RARITY := {
	"normal": INK_MID,
	"magic": Color(0.45, 0.72, 0.82),       # sky-teal, in-palette (not corporate blue)
	"rare": GOLD,
	"unique": TERRACOTTA,
}

# Spec 53 — TYPE SCALE. Seven named sizes with intent; every call site routes
# through these instead of reaching for a raw 10-24 literal. Reserved hero sizes
# (40/56/72) stay inline for full-screen moments only.
const SIZE_DISPLAY := 30      # screen / level-up titles
const SIZE_TITLE := 22        # panel mastheads
const SIZE_SECTION := 17      # section headers
const SIZE_BODY := 14         # default body copy
const SIZE_LABEL := 13        # labels, costs, numbers
const SIZE_CAPTION := 12      # sub-lines, captions
const SIZE_MICRO := 11        # eyebrows, key-hints

# Spec 53 — SPACING SCALE. A 4/8 rhythm so edges align across panels.
const SPACE_1 := 4
const SPACE_2 := 8
const SPACE_3 := 12
const SPACE_4 := 16
const SPACE_5 := 24
const SPACE_6 := 32

# Spec 53 Tier 3 — modal + disabled tokens (callers used to improvise these:
# scrim alpha drifted 0.45–0.55, disabled inks were hardcoded per card).
const SCRIM := Color(0.0, 0.0, 0.0, 0.55)        # one modal backdrop darkness
const DISABLED_INK := Color(0.46, 0.52, 0.46)    # primary text on a washed card
const DISABLED_DIM := Color(0.40, 0.46, 0.41)    # secondary text on a washed card

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
	# 2026-07-02 — code-drawn panel frames become the MapleStory cream+wood panel
	# when the maple kit is present (ripples to inventory, vendor, craft, enchant…).
	if has_maple():
		return maple_panel_stylebox()
	var sb := StyleBoxTexture.new()
	sb.texture = load(PANEL_TEX_PATH)
	sb.texture_margin_left = PANEL_MARGIN_L
	sb.texture_margin_top = PANEL_MARGIN_T
	sb.texture_margin_right = PANEL_MARGIN_R
	sb.texture_margin_bottom = PANEL_MARGIN_B
	sb.modulate_color = PANEL_MOD   # spec 51 — darken the pale wood into the skin
	return sb
const BUTTON_MARGIN := 18.0

# Spec 51 — modulate tints that recolour the carved-wood ninepatch (panels +
# buttons) into the dark skin, no new art. Swap these to change skin direction.
const PANEL_MOD := Color(0.22, 0.49, 0.47)          # enamel-teal frame tint
const BTN_MOD := Color(0.22, 0.49, 0.47)
const BTN_MOD_HOVER := Color(0.30, 0.64, 0.60)
const BTN_MOD_PRESS := Color(0.15, 0.36, 0.34)
const BTN_MOD_DISABLED := Color(0.20, 0.34, 0.32, 0.5)
const SELECT_MOD := Color(0.34, 0.64, 0.42)         # selected-row glow

# 2026-07-01 taste pass (user: "too many hard edges — softer, pudgy, playful").
# Buttons drop the sharp carved-wood plate for a PUDGY rounded enamel pill: a big
# corner radius, a soft drop shadow so it floats, a warm-light top sheen, and a
# gentle gold rim. One helper (soft_button_box) so every button family softens
# together. Warmer/lighter enamel than the frame tint, to read playful.
const BTN_SOFT := Color(0.118, 0.333, 0.310)
const BTN_SOFT_HOVER := Color(0.176, 0.435, 0.404)
const BTN_SOFT_PRESS := Color(0.086, 0.247, 0.231)
const BTN_SOFT_DISABLED := Color(0.145, 0.267, 0.251, 0.55)
const BTN_RADIUS := 20                               # pudgy corner radius

# MapleStory-tone kit (2026-07-01) — glossy painted 9-patch art generated in the
# palette of the user-picked reference maple_B_4 (tools/gen_maple_ui.gd): a green
# candy pill button, a cream-and-wood panel, a glossy jade slot. Buttons/panels
# use these when present; the soft-flat styleboxes above stay as the fallback.
const MAPLE_BTN := "res://assets/ui/maple/button_9p.png"
const MAPLE_PANEL := "res://assets/ui/maple/panel_9p.png"
const MAPLE_SLOT := "res://assets/ui/maple/slot_9p.png"
const MAPLE_INK := Color(0.99, 0.97, 0.91)       # button label — cream
const MAPLE_INK_DARK := Color(0.22, 0.14, 0.08)  # text outline / dark ink on cream
# Maple palette (matches the generated kit / maple_B_4) — for code-drawn HUD
# pieces (hotbar tray, orbs, compass) so they belong to the same skin.
const MAPLE_WOOD := Color(0.55, 0.37, 0.22)
const MAPLE_WOOD_D := Color(0.29, 0.17, 0.12)
const MAPLE_WOOD_L := Color(0.75, 0.58, 0.39)
const MAPLE_CREAM := Color(0.957, 0.878, 0.690)
const MAPLE_CREAM_D := Color(0.84, 0.75, 0.57)
const MAPLE_JADE := Color(0.31, 0.71, 0.59)
const MAPLE_JADE_HI := Color(0.61, 0.885, 0.825)
const MAPLE_JADE_D := Color(0.165, 0.47, 0.41)
const MAPLE_GREEN := Color(0.47, 0.71, 0.29)

# A candy-pill button stylebox from the generated art, tinted per state.
static func maple_button(mod: Color) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = load(MAPLE_BTN)
	sb.texture_margin_left = 30.0
	sb.texture_margin_right = 30.0
	sb.texture_margin_top = 20.0
	sb.texture_margin_bottom = 22.0
	sb.content_margin_left = 18.0
	sb.content_margin_right = 18.0
	sb.content_margin_top = 7.0
	sb.content_margin_bottom = 9.0
	sb.modulate_color = mod
	return sb

# True once the generated maple kit exists — gates every maple-vs-fallback branch.
static func has_maple() -> bool:
	return ResourceLoader.exists(MAPLE_BTN)

# The cream-and-wood panel from the generated art (9-patch; ~15px wood frame
# holds at any panel size). Used for the framed modals (dialogue, menu plate).
static func maple_panel_stylebox() -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = load(MAPLE_PANEL)
	sb.texture_margin_left = 42.0
	sb.texture_margin_right = 42.0
	sb.texture_margin_top = 42.0
	sb.texture_margin_bottom = 42.0
	sb.set_content_margin_all(30.0)
	return sb

# The glossy jade slot from the generated art (9-patch; item icons draw on top).
static func maple_slot_stylebox() -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = load(MAPLE_SLOT)
	sb.texture_margin_left = 20.0
	sb.texture_margin_right = 20.0
	sb.texture_margin_top = 20.0
	sb.texture_margin_bottom = 20.0
	return sb

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

# Spec 53 — the single highest-leverage taste fix: make IM Fell English the
# project default so every Label / draw_string that doesn't override its font
# stops falling back to the engine's Open-Sans. Called once at boot (Game._ready).
static func apply_defaults() -> void:
	var f := font_body()
	if f != null:
		ThemeDB.fallback_font = f
		ThemeDB.fallback_font_size = SIZE_BODY

# Spec 53 — ONE keybind-badge treatment (was terracotta / gold / ink across the
# three slot families). Cream micro-caps with a dark halo, reads on any plate.
static func style_keyhint(l: Label) -> void:
	l.add_theme_font_size_override("font_size", SIZE_MICRO)
	l.add_theme_color_override("font_color", INK)
	l.add_theme_color_override("font_outline_color", Color(0.06, 0.05, 0.04))
	l.add_theme_constant_override("outline_size", 4)

# Spec 53 Tier 3 — the one modal backdrop. A full-rect SCRIM that dims the world
# AND dismisses on a click outside the panel (clicking the scrim calls on_dismiss).
# Every modal builds its scrim through here so the darkness + dismiss gesture are
# identical, and click-outside-to-close stops being a per-panel afterthought.
static func make_backdrop(host: Node, on_dismiss: Callable) -> ColorRect:
	var bg := ColorRect.new()
	bg.color = SCRIM
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	if on_dismiss.is_valid():
		bg.gui_input.connect(func(e: InputEvent):
			if e is InputEventMouseButton and e.pressed \
					and e.button_index == MOUSE_BUTTON_LEFT:
				on_dismiss.call())
	host.add_child(bg)
	return bg

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
const KIT_PLATE := Color(0.075, 0.231, 0.212)  # deep enamel face
const KIT_WELL := Color(0.043, 0.149, 0.137)   # recessed groove / trough
const KIT_EDGE := Color(0.890, 0.722, 0.361)   # gold filigree edge

# Parchment chip — the kit's smallest container (toasts, hints, counters).
static func chip_stylebox(bg := KIT_PLATE) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = KIT_EDGE
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(12)      # 2026-07-01 — rounder, softer chips
	sb.corner_detail = 8
	sb.anti_aliasing = true
	# Spec 44 — a soft under-shadow so chips and buttons sit ON the
	# parchment instead of floating flat in it.
	sb.shadow_color = Color(0, 0, 0, 0.16)
	sb.shadow_size = 3
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

# The one pudgy-button factory (2026-07-01 taste pass). A rounded enamel pill
# with a soft drop shadow (floats), a gold rim, and — via expand margins + a
# large radius — a puffy, playful read. `press` sinks the shadow so the button
# feels pushed. Every button family routes through here so they soften together.
static func soft_button_box(bg: Color, pressed := false) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(BTN_RADIUS)
	sb.corner_detail = 10
	sb.anti_aliasing = true
	sb.anti_aliasing_size = 1.0
	sb.set_border_width_all(2)
	sb.border_color = Color(GOLD, 0.5 if pressed else 0.62)
	# Soft under-shadow so the pill sits ON the surface, not cut into it.
	sb.shadow_color = Color(0.0, 0.0, 0.0, 0.14 if pressed else 0.30)
	sb.shadow_size = 3 if pressed else 7
	sb.shadow_offset = Vector2(0, 1 if pressed else 3)
	sb.content_margin_left = 16.0
	sb.content_margin_right = 16.0
	sb.content_margin_top = 8.0
	sb.content_margin_bottom = 8.0
	# Puff the fill a hair past its box for the pudgy bulge.
	sb.expand_margin_left = 1.0
	sb.expand_margin_right = 1.0
	sb.expand_margin_top = 1.0 if not pressed else 0.0
	sb.expand_margin_bottom = 3.0 if not pressed else 0.0
	return sb

# The MapleStory candy-pill theme: cream OUTLINED label (reads on the green
# gradient) + the glossy button art in four states. Shared by both button styles.
static func _maple_button_theme(b: Button) -> void:
	b.add_theme_color_override("font_color", MAPLE_INK)
	b.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	b.add_theme_color_override("font_pressed_color", MAPLE_INK)
	b.add_theme_color_override("font_disabled_color", Color(MAPLE_INK, 0.6))
	b.add_theme_color_override("font_outline_color", MAPLE_INK_DARK)
	b.add_theme_constant_override("outline_size", 5)
	b.add_theme_stylebox_override("normal", maple_button(Color.WHITE))
	b.add_theme_stylebox_override("hover", maple_button(Color(1.12, 1.12, 1.10)))
	b.add_theme_stylebox_override("pressed", maple_button(Color(0.86, 0.90, 0.84)))
	b.add_theme_stylebox_override("disabled", maple_button(Color(0.72, 0.74, 0.70, 0.7)))

static func style_kit_button(b: Button) -> void:
	b.add_theme_font_size_override("font_size", 15)
	if has_maple():
		_maple_button_theme(b)
		return
	b.add_theme_color_override("font_color", INK)
	b.add_theme_color_override("font_hover_color", GOLD)
	b.add_theme_color_override("font_pressed_color", GOLD)
	# Pudgy rounded enamel pills (the carved-wood plate read too hard).
	b.add_theme_stylebox_override("normal", soft_button_box(BTN_SOFT))
	b.add_theme_stylebox_override("hover", soft_button_box(BTN_SOFT_HOVER))
	b.add_theme_stylebox_override("pressed", soft_button_box(BTN_SOFT_PRESS, true))
	b.add_theme_stylebox_override("disabled", soft_button_box(BTN_SOFT_DISABLED))

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
	label.add_theme_constant_override("outline_size", 4)
	label.add_theme_color_override("font_outline_color", KIT_WELL)
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
	fb.bg_color = Color(0.075, 0.231, 0.212, 0.97)
	fb.border_color = GOLD
	fb.set_border_width_all(2)
	fb.set_corner_radius_all(8)
	fb.set_content_margin_all(10)
	p.add_theme_stylebox_override("panel", fb)

static func style_button(b: Button) -> void:
	# Buttons are read, not admired — clean default font (usability pass).
	# 2026-07-01 — same pudgy rounded pill as style_kit_button, so the menu,
	# dialogue choices, and panel actions all share the soft, playful read.
	b.add_theme_font_size_override("font_size", 15)
	if has_maple():
		_maple_button_theme(b)
		var mf := StyleBoxFlat.new()
		mf.draw_center = false
		mf.border_color = GOLD
		mf.set_border_width_all(2)
		mf.set_corner_radius_all(BTN_RADIUS + 4)
		mf.corner_detail = 10
		b.add_theme_stylebox_override("focus", mf)
		return
	b.add_theme_color_override("font_color", INK)
	b.add_theme_color_override("font_hover_color", GOLD)
	b.add_theme_color_override("font_pressed_color", GOLD)
	b.add_theme_color_override("font_disabled_color", Color(INK_MID, 0.55))
	b.add_theme_stylebox_override("normal", soft_button_box(BTN_SOFT))
	b.add_theme_stylebox_override("hover", soft_button_box(BTN_SOFT_HOVER))
	b.add_theme_stylebox_override("pressed", soft_button_box(BTN_SOFT_PRESS, true))
	b.add_theme_stylebox_override("disabled", soft_button_box(BTN_SOFT_DISABLED))
	var focus := StyleBoxFlat.new()
	focus.draw_center = false
	focus.border_color = GOLD
	focus.set_border_width_all(2)
	focus.set_corner_radius_all(BTN_RADIUS + 2)
	focus.corner_detail = 10
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
	if has_maple():
		# Warm gold-tinted candy pill = "this one's chosen".
		b.add_theme_stylebox_override("normal", maple_button(Color(1.16, 1.02, 0.70)))
		b.add_theme_stylebox_override("hover", maple_button(Color(1.22, 1.08, 0.76)))
		b.add_theme_color_override("font_color", MAPLE_INK)
		return
	# Soft sage-enamel pill with a full gold rim — the "this one's chosen" read.
	var sb := soft_button_box(Color(0.176, 0.404, 0.290))
	sb.border_color = GOLD
	sb.set_border_width_all(3)
	var sb2 := soft_button_box(Color(0.204, 0.451, 0.325))
	sb2.border_color = GOLD
	sb2.set_border_width_all(3)
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", sb2)
	b.add_theme_color_override("font_color", GOLD)

static func style_title(l: Label) -> void:
	_set_font(l, font_header())
	l.add_theme_font_size_override("font_size", SIZE_DISPLAY)
	l.add_theme_color_override("font_color", GOLD)

static func style_section(l: Label) -> void:
	_set_font(l, font_header())
	l.add_theme_font_size_override("font_size", SIZE_SECTION)
	l.add_theme_color_override("font_color", GOLD)

static func style_body(l: Label, size: int = SIZE_BODY) -> void:
	# Body copy inherits the project default face (IM Fell, set by apply_defaults)
	# — spec 53 removed the silent +1 fudge so the token IS the rendered size.
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", INK)

static func style_dim(l: Label, size: int = SIZE_LABEL) -> void:
	l.add_theme_font_size_override("font_size", size)
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
	# Maple: a glossy jade slot (only the DEFAULT recessed wells — i.e. item /
	# gear slots; callers passing a custom fill keep the carved-enamel well).
	if has_maple() and fill == KIT_WELL:
		var sb := StyleBoxFlat.new()
		sb.bg_color = MAPLE_JADE
		sb.set_corner_radius_all(mini(12, int(minf(r.size.x, r.size.y) * 0.26)))
		sb.corner_detail = 8
		sb.anti_aliasing = true
		sb.set_border_width_all(3)
		sb.border_color = MAPLE_WOOD
		c.draw_style_box(sb, r)
		var m := minf(r.size.x, r.size.y)
		c.draw_circle(r.position + Vector2(r.size.x * 0.5, r.size.y * 0.30),
			m * 0.32, Color(MAPLE_JADE_HI, 0.32))
		c.draw_circle(r.position + Vector2(r.size.x * 0.30, r.size.y * 0.26),
			m * 0.11, Color(1, 1, 1, 0.45))
		return
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
	c.draw_rect(r, KIT_PLATE if enabled else Color(0.20, 0.34, 0.32))
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
		c.draw_arc(sc, 7.5, 0, TAU, 20, Color(0.40, 0.12, 0.10), 1.5, true)
