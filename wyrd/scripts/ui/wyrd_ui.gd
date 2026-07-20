class_name WyrdUi
extends RefCounted

const Tokens = preload("res://scripts/ui/foundation/ui_tokens.gd")

# Wyrd — the shared hand-drawn parchment skin for every code-built panel.
# Textures come from the AI-imaging pass (assets/ui/, generated 2026-06-10
# against the docs/UI_BIBLE.md master stem: wobbly sepia ink on aged cream,
# watercolor washes). One place for palette and styleboxes; if the textures
# go missing everything degrades to the old flat-ink look.

# Spec 59 — Field Journal semantic text roles. The previous Enamel Night pass
# changed the single global INK token to cream while the panel factory later
# changed to pale Maple paper. That deterministic seam produced cream-on-cream
# UI. Surface ownership is explicit now; compatibility aliases below point to
# paper roles because the legacy modal shell resolves to paper when Maple exists.
const TEXT_ON_PAPER := Tokens.TEXT_ON_PAPER
const TEXT_ON_PAPER_DIM := Tokens.TEXT_ON_PAPER_DIM
const TEXT_ON_DARK := Tokens.TEXT_ON_DARK
const TEXT_ON_DARK_DIM := Tokens.TEXT_ON_DARK_DIM
const INK := TEXT_ON_PAPER
const INK_MID := TEXT_ON_PAPER_DIM
const TERRACOTTA := Color(0.835, 0.416, 0.271)  # ember — titles / accents / danger
const SAGE := Color(0.651, 0.761, 0.392)  # good twin / fresh
const GOLD := Color(0.890, 0.722, 0.361)  # leaf-gold filigree
const CREAM := TEXT_ON_DARK

# Back-compat aliases (earlier panels reference these names). Unlike the old
# PARCHMENT := cream alias, these are actually readable on paper.
const PARCHMENT := TEXT_ON_PAPER
const PARCH_DIM := TEXT_ON_PAPER_DIM
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
const SIZE_SECTION := Tokens.TYPE_SECTION
const SIZE_BODY := Tokens.TYPE_BODY
const SIZE_LABEL := Tokens.TYPE_BODY
const SIZE_CAPTION := Tokens.TYPE_CAPTION
const SIZE_MICRO := Tokens.TYPE_CAPTION

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
const DISABLED_INK := Color(0.42, 0.38, 0.31)    # primary text on a washed card
const DISABLED_DIM := Color(0.50, 0.46, 0.39)    # secondary text on a washed card

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

# --- Path B: the PAINTED kit (2026-07-02) — hand-painted MJ components sliced to
# alpha, an upgrade over the procedural maple textures. Slots/close/ornaments are
# real art now; the procedural kit stays as the fallback. Preloaded once at boot
# (Game._ready → preload_kit) so draw-time load() never first-loads inside _draw.
const KIT_SLOT := "res://assets/ui/kit/slot.png"
const KIT_BUTTON := "res://assets/ui/kit/button.png"
const KIT_CLOSE := "res://assets/ui/kit/close.png"
const KIT_CREST := "res://assets/ui/kit/crest.png"
const KIT_IVY := "res://assets/ui/kit/ivy.png"
static var _kit_cache: Dictionary = {}

static func has_kit() -> bool:
	return ResourceLoader.exists(KIT_SLOT)

static func preload_kit() -> void:
	for p in [KIT_SLOT, KIT_BUTTON, KIT_CLOSE, KIT_CREST, KIT_IVY]:
		if ResourceLoader.exists(p) and not _kit_cache.has(p):
			_kit_cache[p] = load(p)

static func kit_tex(path: String) -> Texture2D:
	if not _kit_cache.has(path) and ResourceLoader.exists(path):
		_kit_cache[path] = load(path)
	return _kit_cache.get(path, null)

# A candy-pill button stylebox from the generated art, tinted per state.
static func maple_button(mod: Color) -> StyleBoxTexture:
	# The painted candy button is ROUND; it won't 9-slice to wide text buttons
	# (stretches to a squished stripe), so wide buttons keep the procedural pill.
	# The painted button is reserved for square/icon buttons via _kit_icon_button.
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

# A soft rounded box (cards, chips, buttons). One place for the maple card look.
static func _round_box(bg: Color, border: Color, radius: int, border_w := 2,
		shadow := 0.22) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(radius)
	sb.corner_detail = 8
	sb.anti_aliasing = true
	sb.set_border_width_all(border_w)
	sb.border_color = border
	if shadow > 0.0:
		sb.shadow_color = Color(0, 0, 0, shadow)
		sb.shadow_size = 4
		sb.shadow_offset = Vector2(0, 2)
	return sb

# A round teal close ✕ pinned to a panel's top-right corner — the obvious dismiss
# (shop/list-page references all have one). Wire it to the panel's _close.
static func add_close_button(host: Control, on_close: Callable) -> Button:
	var b := Button.new()
	# Modal close controls must participate in the same keyboard/controller
	# graph as their body controls. Panels that do not explicitly link it still
	# retain mouse behavior; focusable panels can wire it as their final stop.
	b.name = "CloseButton"
	b.focus_mode = Control.FOCUS_ALL
	b.tooltip_text = "Close"
	b.set_meta("cursor_role", "action")
	if has_kit():
		# painted teal ✕ sprite
		var t := kit_tex(KIT_CLOSE)
		var n := StyleBoxTexture.new(); n.texture = t
		var h := StyleBoxTexture.new(); h.texture = t; h.modulate_color = Color(1.14, 1.14, 1.14)
		var p := StyleBoxTexture.new(); p.texture = t; p.modulate_color = Color(0.86, 0.9, 0.86)
		b.add_theme_stylebox_override("normal", n)
		b.add_theme_stylebox_override("hover", h)
		b.add_theme_stylebox_override("pressed", p)
		b.offset_left = -62
		b.offset_right = -6
		b.offset_top = 8
		b.offset_bottom = 64
	else:
		b.text = "✕"
		b.add_theme_font_size_override("font_size", 18)
		b.add_theme_color_override("font_color", MAPLE_INK)
		b.add_theme_color_override("font_hover_color", Color(1, 1, 1))
		b.add_theme_color_override("font_pressed_color", MAPLE_INK)
		b.add_theme_color_override("font_outline_color", MAPLE_INK_DARK)
		b.add_theme_constant_override("outline_size", 4)
		b.add_theme_stylebox_override("normal", _round_box(MAPLE_JADE, MAPLE_WOOD, 13))
		b.add_theme_stylebox_override("hover", _round_box(MAPLE_JADE_HI, MAPLE_WOOD, 13))
		b.add_theme_stylebox_override("pressed", _round_box(MAPLE_JADE_D, MAPLE_WOOD, 13, 2, 0.1))
		b.offset_left = -54
		b.offset_right = -14
		b.offset_top = 14
		b.offset_bottom = 54
	b.anchor_left = 1.0
	b.anchor_right = 1.0
	b.anchor_top = 0.0
	b.anchor_bottom = 0.0
	b.pressed.connect(on_close)
	host.add_child(b)
	return b

# Focusable twin of draw_quiet_cell. Chart Table sockets are real Buttons so
# controller navigation, semantic cursor roles, and accessibility do not rely
# on a custom-drawn hit-test rectangle.
static func quiet_cell_stylebox(fill := MAPLE_CELL, border := Color(MAPLE_WOOD, 0.34),
		border_width := 2) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.set_corner_radius_all(11)
	sb.corner_detail = 6
	sb.anti_aliasing = true
	sb.set_border_width_all(border_width)
	sb.border_color = border
	sb.shadow_color = Color(0, 0, 0, 0.10)
	sb.shadow_size = 2
	sb.shadow_offset = Vector2(0, 1)
	sb.content_margin_left = 5.0
	sb.content_margin_right = 5.0
	sb.content_margin_top = 5.0
	sb.content_margin_bottom = 5.0
	return sb

static func style_chart_socket(button: Button, unlocked: bool, occupied: bool = false) -> void:
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", SIZE_LABEL)
	button.add_theme_color_override("font_color", MAPLE_WOOD_D)
	button.add_theme_color_override("font_hover_color", MAPLE_WOOD_D)
	button.add_theme_color_override("font_pressed_color", MAPLE_WOOD_D)
	button.add_theme_color_override("font_disabled_color", Color(MAPLE_WOOD_D, 0.68))
	var face := MAPLE_CREAM_D.lightened(0.06) if occupied else MAPLE_CELL
	if not unlocked:
		face = MAPLE_CELL_D.darkened(0.10)
	button.add_theme_stylebox_override("normal", quiet_cell_stylebox(face))
	button.add_theme_stylebox_override("hover", quiet_cell_stylebox(
		face.lightened(0.08), GOLD.darkened(0.12), 2))
	button.add_theme_stylebox_override("pressed", quiet_cell_stylebox(
		face.darkened(0.05), MAPLE_WOOD, 2))
	button.add_theme_stylebox_override("disabled", quiet_cell_stylebox(face,
		Color(MAPLE_WOOD, 0.22), 1))
	var focus := quiet_cell_stylebox(Color(0, 0, 0, 0), GOLD, 3)
	focus.draw_center = false
	button.add_theme_stylebox_override("focus", focus)

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

# UI bible fonts: IM Fell English (body), IM Fell English SC (headers).
const FONT_BODY_PATH := "res://assets/fonts/IMFellEnglish-Regular.ttf"
const FONT_HEADER_PATH := "res://assets/fonts/IMFellEnglishSC-Regular.ttf"

static func font_body() -> Font:
	return load(FONT_BODY_PATH) if ResourceLoader.exists(FONT_BODY_PATH) else null

static func font_header() -> Font:
	return load(FONT_HEADER_PATH) if ResourceLoader.exists(FONT_HEADER_PATH) else null

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
	l.add_theme_color_override("font_color", TEXT_ON_DARK)
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
	l.add_theme_color_override("font_color", TEXT_ON_DARK)
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
	_field_button_theme(b)

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
	label.add_theme_color_override("font_color", TEXT_ON_DARK)
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
	var fb := StyleBoxFlat.new()
	fb.bg_color = Tokens.PAPER
	fb.border_color = Tokens.WALNUT
	fb.set_border_width_all(4)
	fb.set_corner_radius_all(14)
	fb.set_content_margin_all(16)
	fb.shadow_color = Color(0, 0, 0, 0.28)
	fb.shadow_size = 8
	fb.shadow_offset = Vector2(0, 4)
	p.add_theme_stylebox_override("panel", fb)

static func style_button(b: Button) -> void:
	_field_button_theme(b)

static func _field_button_theme(b: Button) -> void:
	b.add_theme_font_size_override("font_size", Tokens.TYPE_BODY)
	b.add_theme_color_override("font_color", Tokens.TEXT_ON_DARK)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_pressed_color", Tokens.TEXT_ON_DARK)
	b.add_theme_color_override("font_disabled_color", Tokens.DISABLED_TEXT_ON_PAPER)
	for state in ["normal", "hover", "pressed", "disabled"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Tokens.MOSS_HOVER if state == "hover" else \
			(Tokens.MOSS_PRESSED if state == "pressed" else \
			(Tokens.DISABLED_SURFACE if state == "disabled" else Tokens.MOSS))
		sb.border_color = Tokens.SAGE if state == "hover" else Tokens.WALNUT
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(10)
		sb.content_margin_left = 16
		sb.content_margin_right = 16
		sb.content_margin_top = 10
		sb.content_margin_bottom = 10
		b.add_theme_stylebox_override(state, sb)
	var focus := StyleBoxFlat.new()
	focus.draw_center = false
	focus.border_color = Tokens.SAGE
	focus.set_border_width_all(3)
	focus.set_corner_radius_all(12)
	focus.set_expand_margin_all(3)
	b.add_theme_stylebox_override("focus", focus)

# Selected list entry (toggled template / chart / trophy buttons) — a sage
# ink ring over the parchment plate.
static func mark_selected(b: Button, selected: bool) -> void:
	if not selected:
		return
	var sb := soft_button_box(Tokens.SAGE.darkened(0.18))
	sb.border_color = Tokens.GOLD_MUTED
	sb.set_border_width_all(3)
	var sb2 := soft_button_box(Tokens.SAGE.darkened(0.10))
	sb2.border_color = Tokens.GOLD_MUTED
	sb2.set_border_width_all(3)
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", sb2)
	b.add_theme_color_override("font_color", Tokens.TEXT_ON_DARK)

static func style_title(l: Label) -> void:
	_set_font(l, font_header())
	l.add_theme_font_size_override("font_size", SIZE_DISPLAY)
	l.add_theme_color_override("font_color", TEXT_ON_PAPER)

static func style_section(l: Label) -> void:
	_set_font(l, font_header())
	l.add_theme_font_size_override("font_size", SIZE_SECTION)
	l.add_theme_color_override("font_color", TEXT_ON_PAPER)

static func style_body(l: Label, size: int = SIZE_BODY) -> void:
	# Body copy inherits the project default face (IM Fell, set by apply_defaults)
	# and never drops below the Spec 59 readability floor, even when a legacy
	# call site still passes the old 13–15px token.
	l.add_theme_font_size_override("font_size", maxi(Tokens.TYPE_BODY, size))
	l.add_theme_color_override("font_color", TEXT_ON_PAPER)

static func style_dim(l: Label, size: int = SIZE_LABEL) -> void:
	l.add_theme_font_size_override("font_size", maxi(Tokens.TYPE_CAPTION, size))
	l.add_theme_color_override("font_color", TEXT_ON_PAPER_DIM)

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
	# The current compatibility shell is pale Maple paper. Use the paper row
	# treatment there so the semantic paper text roles remain readable; dark
	# enamel rows are retained only for the legacy no-Maple fallback.
	if has_maple():
		draw_cream_row(c, r, accent)
		return
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

# Maple list-row (2026-07-02) — a raised warm-parchment card with a soft shadow
# and a colour accent stripe on the left. The cream twin of draw_list_row; used
# by the Satchel-List pack so rows read as calm cards and the item text/rarity
# carries the colour. Separate from draw_list_row to keep the classic-skin
# panels (vendor / loadout / craft…) untouched.
static func draw_cream_row(c: CanvasItem, r: Rect2, accent: Color) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.925, 0.855, 0.66)
	sb.set_corner_radius_all(9)
	sb.corner_detail = 6
	sb.anti_aliasing = true
	sb.set_border_width_all(2)
	sb.border_color = Color(MAPLE_WOOD, 0.32)
	sb.shadow_color = Color(0, 0, 0, 0.12)
	sb.shadow_size = 3
	sb.shadow_offset = Vector2(0, 2)
	c.draw_style_box(sb, r)
	c.draw_rect(Rect2(r.position + Vector2(3.0, 5.0),
		Vector2(3.5, r.size.y - 10.0)), accent)

# Empty-cell colour for the maple skin: a warm parchment recess. Quiet on
# purpose (2026-07-02) — a grid of empty slots should RECEDE so the filled
# items carry the colour, not read as a wall of bright turquoise boxes.
const MAPLE_CELL := Color(0.836, 0.741, 0.556)     # recessed cell face
const MAPLE_CELL_D := Color(0.640, 0.520, 0.360)   # inner recess shadow

# A quiet recessed cell — warm parchment socket, soft inner shadow top, a
# light lip below, a whisper of a wood rim. The empty-slot read for the maple
# skin: calm, so items pop against it (see _draw_item_rect_scaled backings).
static func draw_quiet_cell(c: CanvasItem, r: Rect2) -> void:
	var rad := mini(11, int(minf(r.size.x, r.size.y) * 0.24))
	var sb := StyleBoxFlat.new()
	sb.bg_color = MAPLE_CELL
	sb.set_corner_radius_all(rad)
	sb.corner_detail = 6
	sb.anti_aliasing = true
	sb.set_border_width_all(2)
	sb.border_color = Color(MAPLE_WOOD, 0.34)
	c.draw_style_box(sb, r)
	# inner recess: a soft shadow band along the top + left, a light lip below.
	var inset := r.grow(-3.0)
	c.draw_rect(Rect2(inset.position, Vector2(inset.size.x, 2.0)),
		Color(MAPLE_CELL_D, 0.45))
	c.draw_rect(Rect2(inset.position, Vector2(2.0, inset.size.y)),
		Color(MAPLE_CELL_D, 0.28))
	c.draw_rect(Rect2(inset.position + Vector2(2.0, inset.size.y - 2.0),
		Vector2(inset.size.x - 2.0, 2.0)), Color(1.0, 0.97, 0.86, 0.42))

# A recessed rectangular well: stepped inner shadow top-left, light lip
# bottom — the socket reads as carved INTO the bench, not painted on.
static func draw_well(c: CanvasItem, r: Rect2, fill := KIT_WELL) -> void:
	# Maple/kit: a quiet parchment recess (item + gear cells). Callers passing a
	# custom fill keep the carved-enamel well below.
	if fill == KIT_WELL and (has_maple() or has_kit()):
		draw_quiet_cell(c, r)
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
