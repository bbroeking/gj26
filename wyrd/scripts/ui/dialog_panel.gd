extends CanvasLayer

# Wyrd — a storybook dialog modal. Pages of text, one at a time; E / Space /
# click advances. Built in code (shrine_choice_modal pattern); pauses the
# tree while open. Emits `finished` after the last page.
#
# 2026-07-01 taste pass — reshaped to the user-picked reference (dialogue_4):
# an ornate gold-framed portrait on the LEFT, a warm CREAM PARCHMENT prose box
# on the right (dark ink — the legible storybook read the reference leans on),
# a gilded serif name header on a plate, and an optional vertical choice-button
# stack. The dark enamel skin still frames it (spec 51) but the reading surface
# is parchment again, the way the reference reads.
#
# Public API (preserve exactly — other NPCs call into this):
#   open(speaker: String, pages: Array) -> void
#   open(speaker: String, pages: Array, portrait: Texture2D) -> void  [art-gated]
#   open(speaker, pages, portrait, choices) -> void  [choices art-gated, optional]
# signal finished
# signal choice_selected(index)   # fires when a choice button is pressed

signal finished
signal choice_selected(index)

# Interior layout (relative to the panel's content box). One place so the
# code-drawn canvas and the overlaid Labels agree on every region.
const MARGIN := 40.0          # inset from panel edge to content
const PORTRAIT := 250.0       # square portrait frame edge
const GAP := 30.0             # portrait → prose gutter
const NAME_H := 52.0          # name plate height
const NAME_GAP := 14.0        # name plate → prose
const FOOT_H := 58.0          # continue-hint / choice band

var _pages: Array = []
var _choices: Array = []      # Array[String]; empty → paged text with continue-hint
var _idx := 0
var _done := false            # finished must fire exactly once (queue_free defers)
var _speaker := ""
var _panel: Panel
var _canvas: DialogCanvas
var _body: Label
var _name_lbl: Label
var _hint: Label
var _choice_box: VBoxContainer
var _lockout := 0.0
var _well: PortraitWell       # set in _ready; used by open() to pass portrait tex

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.5)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)

	_panel = Panel.new()
	# The dialog joins the carved-wood panel language; the prose surface inside
	# is warm cream parchment (dialogue_4). Full-screen presentation so the
	# conversation owns the moment (2026-06-12 ruling). 2026-07-01 — the frame is
	# the MapleStory cream-and-wood panel when the generated kit is present.
	if WyrdUi.has_maple():
		_panel.add_theme_stylebox_override("panel", WyrdUi.maple_panel_stylebox())
	else:
		WyrdUi.style_panel(_panel)
	_panel.anchor_right = 1.0
	_panel.anchor_bottom = 1.0
	_panel.offset_left = 84
	_panel.offset_right = -84
	_panel.offset_top = 64
	_panel.offset_bottom = -64
	add_child(_panel)

	# Code-drawn interior (parchment prose box + framed portrait recess + gold
	# corner flourishes). Anchored to the panel so it tracks any window size.
	_canvas = DialogCanvas.new()
	_canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(_canvas)

	# Portrait well — ghosted silhouette until painted portraits ship. Sits in
	# the top-left portrait region the canvas frames.
	_well = PortraitWell.new()
	_well.position = Vector2(MARGIN + 10.0, MARGIN + 10.0)
	_well.size = Vector2(PORTRAIT - 20.0, PORTRAIT - 20.0)
	_panel.add_child(_well)

	# Name header — gilded serif, sits on the plate the canvas draws.
	_name_lbl = Label.new()
	var hf := WyrdUi.font_header()
	if hf != null:
		_name_lbl.add_theme_font_override("font", hf)
	_name_lbl.add_theme_font_size_override("font_size", 26)
	_name_lbl.add_theme_color_override("font_color", WyrdUi.GOLD)
	_name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_name_lbl.clip_text = true
	_name_lbl.anchor_right = 1.0
	_name_lbl.offset_left = MARGIN + PORTRAIT + GAP + 18.0
	_name_lbl.offset_right = -(MARGIN + 18.0)
	_name_lbl.offset_top = MARGIN
	_name_lbl.offset_bottom = MARGIN + NAME_H
	_panel.add_child(_name_lbl)

	# Body prose — dark ink on the cream parchment box.
	_body = Label.new()
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_body.anchor_right = 1.0
	_body.anchor_bottom = 1.0
	_body.offset_left = MARGIN + PORTRAIT + GAP + 22.0
	_body.offset_top = MARGIN + NAME_H + NAME_GAP + 18.0
	_body.offset_right = -(MARGIN + 22.0)
	_body.offset_bottom = -(FOOT_H + 22.0)
	_body.add_theme_font_size_override("font_size", 21)
	_body.add_theme_color_override("font_color", Color(0.17, 0.12, 0.08))
	_body.add_theme_constant_override("line_spacing", 7)
	_panel.add_child(_body)

	# Choice button stack (art-gated / optional). Hidden until a caller passes
	# choices; then it fills the footer band, right-aligned.
	_choice_box = VBoxContainer.new()
	_choice_box.alignment = BoxContainer.ALIGNMENT_END
	_choice_box.add_theme_constant_override("separation", 8)
	_choice_box.anchor_left = 1.0
	_choice_box.anchor_right = 1.0
	_choice_box.anchor_top = 0.0
	_choice_box.anchor_bottom = 1.0
	_choice_box.offset_left = -360.0
	_choice_box.offset_right = -(MARGIN + 6.0)
	_choice_box.offset_top = MARGIN + NAME_H + NAME_GAP + 18.0
	_choice_box.offset_bottom = -(MARGIN + 6.0)
	_choice_box.visible = false
	_panel.add_child(_choice_box)

	_hint = Label.new()
	_hint.text = "E / Space — continue · Esc — close"
	WyrdUi.style_chip(_hint, 12)
	_hint.anchor_left = 1.0
	_hint.anchor_top = 1.0
	_hint.anchor_right = 1.0
	_hint.anchor_bottom = 1.0
	_hint.offset_left = -318
	_hint.offset_top = -46
	_hint.offset_right = -(MARGIN - 6.0)
	_panel.add_child(_hint)

	get_node("/root/Game").modal_opened()
	_render()

# open() — primary public API. The two-argument form is used by every existing
# NPC and is preserved exactly. The optional third argument (portrait texture)
# is art-gated. The optional fourth (choices) turns the footer into a branching
# choice stack; existing callers omit it, so paged text is unchanged.
func open(speaker: String, pages: Array, portrait: Texture2D = null,
		choices: Array = []) -> void:
	_speaker = speaker
	_pages = pages
	_choices = choices
	_idx = 0
	if _well != null:
		_well.portrait_texture = portrait
	if is_node_ready():
		_render()

func _render() -> void:
	if _name_lbl == null:
		return
	_name_lbl.text = _speaker
	if _idx < _pages.size():
		_body.text = String(_pages[_idx])
	# Choices only surface on the LAST page (classic VN cadence): read the line,
	# then pick. Before that, the continue-hint carries the flow.
	var on_last := _idx >= _pages.size() - 1
	var show_choices := not _choices.is_empty() and on_last
	if _choice_box != null:
		_choice_box.visible = show_choices
		if show_choices and _choice_box.get_child_count() != _choices.size():
			_build_choices()
	if _hint != null:
		_hint.visible = not show_choices

func _build_choices() -> void:
	for c in _choice_box.get_children():
		c.queue_free()
	for i in _choices.size():
		var b := Button.new()
		WyrdUi.style_kit_button(b)
		b.text = String(_choices[i])
		b.custom_minimum_size = Vector2(300, 42)
		b.pressed.connect(_on_choice.bind(i))
		_choice_box.add_child(b)

func _on_choice(index: int) -> void:
	if _done:
		return
	choice_selected.emit(index)
	_finish()

func _process(delta: float) -> void:
	_lockout += delta
	if _lockout < 0.25:
		return
	# Esc closes the whole conversation (user: "I've always dismissed them").
	# Still emits finished so tutorial beats advance.
	if Input.is_action_just_pressed("ui_cancel"):
		_finish()
		return
	# While a choice stack is up, the keyboard advance is disabled — the player
	# must pick a button (else E would skip the decision).
	if not _choices.is_empty() and _idx >= _pages.size() - 1:
		return
	if Input.is_action_just_pressed("interact") \
			or Input.is_action_just_pressed("roll") \
			or Input.is_action_just_pressed("ui_accept"):
		_advance()

func _input(event: InputEvent) -> void:
	if _lockout < 0.25:
		return
	# Don't let a click chew past a pending choice.
	if not _choices.is_empty() and _idx >= _pages.size() - 1:
		return
	# Left click only — wheel notches and right-drag (camera orbit) must not
	# chew through pages.
	if event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT:
		_advance()

func _advance() -> void:
	if _done:
		return
	_lockout = 0.0
	_idx += 1
	if _idx >= _pages.size():
		# Last page done — if there are choices, hold on the last page for the
		# pick; otherwise finish.
		if not _choices.is_empty():
			_idx = _pages.size() - 1
			_render()
			return
		_finish()
	else:
		_render()

func _finish() -> void:
	if _done:
		return
	_done = true
	get_node("/root/Game").modal_closed()
	finished.emit()
	queue_free()


# The code-drawn interior — parchment prose box, framed portrait recess, and
# gilded corner flourishes. Pure vector draws; no textures loaded here (the
# _draw/load white-rect gotcha stays impossible). Regions mirror the constants
# the overlaid Labels use, computed from the live panel size each redraw.
class DialogCanvas extends Control:
	func _draw() -> void:
		var s := size
		var gold := WyrdUi.KIT_EDGE
		# The portrait region (top-left) — a ROUNDED recessed enamel frame.
		var pr := Rect2(MARGIN, MARGIN, PORTRAIT, PORTRAIT)
		_rounded(pr, WyrdUi.KIT_WELL, 24, Color(gold, 0.85), 2.0, 0.22)
		_ring(pr.grow(-6.0), 18, Color(gold, 0.45), 1.0)

		# The name plate — a soft rounded enamel bar to the right of the portrait.
		var nx := MARGIN + PORTRAIT + GAP
		var nw := s.x - nx - MARGIN
		var np := Rect2(nx, MARGIN, nw, NAME_H)
		_rounded(np, WyrdUi.KIT_PLATE.lightened(0.04), 20, Color(gold, 0.6), 2.0, 0.20)

		# The prose box — warm cream parchment, ROUNDED, with a sparse grain and a
		# gold edge. THIS is the reference's reading surface (dark ink lands here).
		var py := MARGIN + NAME_H + NAME_GAP
		var prose := Rect2(nx, py, nw, s.y - py - MARGIN)
		_rounded(prose, Color(0.945, 0.900, 0.792), 22,
			Color(0.62, 0.48, 0.30), 1.5, 0.18)
		_ring(prose.grow(2.0), 24, Color(gold, 0.7), 2.0)
		WyrdUi.draw_parchment_grain(self, prose.grow(-12.0), 13)

		# Soft fiddlehead-swirl flourishes on the outer content box corners.
		var inner := Rect2(MARGIN * 0.5, MARGIN * 0.5, s.x - MARGIN, s.y - MARGIN)
		_swirl(inner.position, 1.0, 1.0)
		_swirl(Vector2(inner.end.x, inner.position.y), -1.0, 1.0)
		_swirl(Vector2(inner.position.x, inner.end.y), 1.0, -1.0)
		_swirl(inner.end, -1.0, -1.0)

	# Filled rounded box with a border and an optional soft drop shadow.
	func _rounded(r: Rect2, fill: Color, radius: int, border_col: Color,
			border_w: float, shadow := 0.0) -> void:
		var sb := StyleBoxFlat.new()
		sb.bg_color = fill
		sb.set_corner_radius_all(radius)
		sb.corner_detail = 10
		sb.anti_aliasing = true
		sb.set_border_width_all(int(border_w))
		sb.border_color = border_col
		if shadow > 0.0:
			sb.shadow_color = Color(0, 0, 0, shadow)
			sb.shadow_size = 6
			sb.shadow_offset = Vector2(0, 3)
		draw_style_box(sb, r)

	# Rounded rectangular outline (hollow).
	func _ring(r: Rect2, radius: int, col: Color, width: float) -> void:
		var sb := StyleBoxFlat.new()
		sb.draw_center = false
		sb.set_border_width_all(int(width))
		sb.border_color = col
		sb.set_corner_radius_all(radius)
		sb.corner_detail = 10
		sb.anti_aliasing = true
		draw_style_box(sb, r)

	# A gilded fiddlehead curl tucked into a corner — soft swirl, not a hard L.
	func _swirl(p: Vector2, sx: float, sy: float) -> void:
		var gold := WyrdUi.GOLD
		var core := p + Vector2(26.0 * sx, 26.0 * sy)
		var pts := PackedVector2Array()
		var steps := 46
		for i in steps + 1:
			var t := float(i) / float(steps)
			var ang := lerpf(-PI * 0.78, PI * 1.15, t)
			var rad := lerpf(20.0, 2.2, t)
			pts.append(core + Vector2(cos(ang) * rad * sx, sin(ang) * rad * sy))
		draw_polyline(pts, Color(gold, 0.8), 2.2, true)
		draw_circle(pts[pts.size() - 1], 2.0, Color(gold, 0.85))


# The portrait well — now a framed rectangular portrait (dialogue_4), not the
# old round disc. Parchment/enamel fill, ghosted silhouette until painted
# portraits exist. Phase 5 (art-gated): set portrait_texture before adding to
# the tree (or queue_redraw() after). NEVER set portrait_texture inside _draw()
# — that triggers the white-rect bug (memory: godot-draw-load-white-texture).
class PortraitWell extends Control:
	var portrait_texture: Texture2D = null   # null → silhouette; set by NPC

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		if portrait_texture != null:
			draw_texture_rect(portrait_texture, r, false)
			_ring(r, 18, Color(0.26, 0.19, 0.13), 2.5)
			return
		# Silhouette fallback (no portrait yet) — a bust on a rounded enamel field.
		var bg := StyleBoxFlat.new()
		bg.bg_color = Color(0.10, 0.24, 0.22)
		bg.set_corner_radius_all(18)
		bg.corner_detail = 10
		bg.anti_aliasing = true
		draw_style_box(bg, r)
		var c := size * 0.5
		var rad := minf(c.x, c.y) * 0.9
		draw_circle(c + Vector2(0, rad * 0.30), rad * 0.34, Color(0.30, 0.40, 0.36))
		draw_circle(c - Vector2(0, rad * 0.16), rad * 0.22, Color(0.30, 0.40, 0.36))
		_ring(r, 18, Color(WyrdUi.KIT_EDGE, 0.55), 2.0)

	func _ring(r: Rect2, radius: int, col: Color, width: float) -> void:
		var sb := StyleBoxFlat.new()
		sb.draw_center = false
		sb.set_border_width_all(int(width))
		sb.border_color = col
		sb.set_corner_radius_all(radius)
		sb.corner_detail = 10
		sb.anti_aliasing = true
		draw_style_box(sb, r)
