extends CanvasLayer

# Wyrd — a storybook dialog modal. Pages of text, one at a time; E / Space /
# click advances. Built in code (shrine_choice_modal pattern); pauses the
# tree while open. Emits `finished` after the last page.

signal finished

var _pages: Array = []
var _idx := 0
var _done := false        # finished must fire exactly once (queue_free defers)
var _speaker := ""
var _panel: Panel
var _body: Label
var _name_lbl: Label
var _hint: Label
var _lockout := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.45)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)
	_panel = Panel.new()
	# Spec 39 — the dialog joins the carved-wood panel language. The old
	# Midjourney scroll art was atmospheric but buried the text (user:
	# "completely illegible"); a clean wood frame + cream interior wins.
	# 2026-06-12 — full-screen presentation (user): the conversation owns
	# the moment instead of strapping to the bottom edge.
	WyrdUi.style_panel(_panel)
	_panel.anchor_right = 1.0
	_panel.anchor_bottom = 1.0
	_panel.offset_left = 90
	_panel.offset_right = -90
	_panel.offset_top = 70
	_panel.offset_bottom = -70
	add_child(_panel)
	# Portrait well (spec 41) — ghosted silhouette until painted portraits.
	var well := PortraitWell.new()
	well.position = Vector2(48, 104)
	well.size = Vector2(120, 120)
	_panel.add_child(well)
	_name_lbl = Label.new()
	var hf := WyrdUi.font_header()
	if hf != null:
		_name_lbl.add_theme_font_override("font", hf)
	_name_lbl.add_theme_font_size_override("font_size", 24)
	_name_lbl.add_theme_color_override("font_color", WyrdUi.TERRACOTTA)
	_name_lbl.anchor_right = 1.0
	_name_lbl.offset_left = 56
	_name_lbl.offset_right = -56
	_name_lbl.offset_top = 38
	_panel.add_child(_name_lbl)
	_body = Label.new()
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.anchor_right = 1.0
	_body.anchor_bottom = 1.0
	_body.offset_left = 200
	_body.offset_top = 104
	_body.offset_right = -72
	_body.offset_bottom = -64
	_body.add_theme_font_size_override("font_size", 21)
	_body.add_theme_color_override("font_color", Color(0.20, 0.15, 0.11))
	_body.add_theme_constant_override("line_spacing", 7)
	_panel.add_child(_body)
	_hint = Label.new()
	_hint.text = "E / Space — continue · Esc — close"
	WyrdUi.style_chip(_hint, 12)
	_hint.anchor_left = 1.0
	_hint.anchor_top = 1.0
	_hint.anchor_right = 1.0
	_hint.anchor_bottom = 1.0
	_hint.offset_left = -310
	_hint.offset_top = -48
	_panel.add_child(_hint)
	# Flourish rule — ── ◆ ── under the speaker name (matches section headers
	# on the bench; gives the name a storybook title-plate feel).
	var sep := _NameFlourishLine.new()
	sep.anchor_right = 1.0
	sep.offset_left = 56
	sep.offset_right = -56
	sep.offset_top = 78
	sep.custom_minimum_size = Vector2(0, 12)
	_panel.add_child(sep)
	get_node("/root/Game").modal_opened()
	_render()

func open(speaker: String, pages: Array) -> void:
	_speaker = speaker
	_pages = pages
	_idx = 0

func _render() -> void:
	_name_lbl.text = _speaker
	if _idx < _pages.size():
		_body.text = String(_pages[_idx])

func _process(delta: float) -> void:
	_lockout += delta
	if _lockout < 0.25:
		return
	# 2026-06-12 — Esc closes the whole conversation (user: "I've always
	# dismissed them"). Still emits finished so tutorial beats advance.
	if Input.is_action_just_pressed("ui_cancel"):
		_finish()
		return
	if Input.is_action_just_pressed("interact") \
			or Input.is_action_just_pressed("roll") \
			or Input.is_action_just_pressed("ui_accept"):
		_advance()

func _input(event: InputEvent) -> void:
	if _lockout < 0.25:
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


# Portrait medallion — a painted storybook portrait frame: aged parchment
# disc, cloaked-figure silhouette, gold filigree inner ring, and four gold
# diamond pips at the cardinal points (compass-rose / illuminated-manuscript
# language). Moves the dialog from "generic avatar circle" toward the
# hand-crafted cozy storybook feel of the reference art (mj_dialog_ribbon).
class PortraitWell extends Control:
	func _draw() -> void:
		var c := size * 0.5
		var r := minf(c.x, c.y)

		# ── background disc: amber outer zone fading to cream centre ──────
		draw_circle(c, r, Color(0.78, 0.68, 0.48))           # warm amber rim
		draw_circle(c, r * 0.87, Color(0.91, 0.85, 0.69))    # parchment face

		# ── sparse parchment grain (deterministic seed) ───────────────────
		var rng := RandomNumberGenerator.new()
		rng.seed = 17
		for _i in 14:
			var a := rng.randf() * TAU
			var d := sqrt(rng.randf()) * r * 0.81
			var p := c + Vector2(cos(a), sin(a)) * d
			var ln := 2.5 + rng.randf() * 5.5
			draw_line(p, p + Vector2(ln, rng.randf_range(-0.9, 0.9)),
				Color(0.60, 0.50, 0.36, 0.05 + rng.randf() * 0.04), 1.0)

		# ── silhouette — cloaked NPC figure: hood arc + shoulders ─────────
		var hc := c + Vector2(0.0, -r * 0.16)
		var hr := r * 0.21
		draw_circle(hc, hr, Color(0.50, 0.42, 0.32, 0.58))   # head
		# hood: wide arc swept over the head (polygon)
		var hood_pts := PackedVector2Array()
		for i in 14:
			var ang := deg_to_rad(-200.0 + float(i) * (200.0 / 13.0))
			hood_pts.append(hc + Vector2(cos(ang), sin(ang)) * hr * 1.45)
		hood_pts.append(hc + Vector2(0.0, hr * 1.05))
		draw_colored_polygon(hood_pts, Color(0.48, 0.40, 0.30, 0.46))
		# body / cloak — wide oval below
		draw_circle(c + Vector2(0.0, r * 0.23), r * 0.38, Color(0.50, 0.42, 0.32, 0.46))
		# base shadow deepens the lower cloak
		draw_circle(c + Vector2(0.0, r * 0.47), r * 0.27, Color(0.40, 0.33, 0.23, 0.28))

		# ── gold filigree inner ring ───────────────────────────────────────
		draw_arc(c, r - 5.5, 0.0, TAU, 64, Color(0.71, 0.52, 0.22, 0.55), 1.5, true)

		# ── outer ink border ──────────────────────────────────────────────
		draw_arc(c, r, 0.0, TAU, 64, WyrdUi.KIT_EDGE, 2.5, true)

		# ── gold diamond pips at N / E / S / W on the filigree ring ───────
		# reads as compass-rose points on an illuminated portrait medallion.
		for i in 4:
			var a := float(i) * (PI * 0.5) - (PI * 0.5)   # start at top
			var norm := Vector2(cos(a), sin(a))
			var perp := Vector2(-sin(a), cos(a))
			var pc := c + norm * (r - 5.5)
			draw_colored_polygon(PackedVector2Array([
				pc + norm * 4.5,
				pc + perp * 2.5,
				pc - norm * 4.5,
				pc - perp * 2.5,
			]), Color(0.71, 0.52, 0.22, 0.85))


# Thin `── ◆ ──` rule drawn under the speaker name (spec C flourish language).
class _NameFlourishLine extends Control:
	func _draw() -> void:
		WyrdUi.draw_flourish(self, size * 0.5, size.x - 20.0)
