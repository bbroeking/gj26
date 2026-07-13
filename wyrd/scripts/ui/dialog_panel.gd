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
var _hint: Control
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
	_hint = _HintBand.new()
	_hint.anchor_left = 1.0
	_hint.anchor_top = 1.0
	_hint.anchor_right = 1.0
	_hint.anchor_bottom = 1.0
	_hint.offset_left = -310
	_hint.offset_top = -44
	_hint.offset_right = -4
	_hint.offset_bottom = -10
	_panel.add_child(_hint)
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


# Spec 41 — the round portrait well: parchment disc, ink ring, ghosted
# silhouette placeholder until painted portraits exist.
class PortraitWell extends Control:
	func _draw() -> void:
		var c := size * 0.5
		var r := minf(c.x, c.y)
		draw_circle(c, r, Color(0.88, 0.82, 0.67))
		draw_circle(c + Vector2(0, r * 0.28), r * 0.34, Color(0.55, 0.47, 0.36, 0.55))
		draw_circle(c - Vector2(0, r * 0.18), r * 0.22, Color(0.55, 0.47, 0.36, 0.55))
		draw_arc(c, r, 0, TAU, 48, Color(0.26, 0.19, 0.13), 2.5, true)
		draw_arc(c, r - 4.0, 0, TAU, 48, Color(0.26, 0.19, 0.13, 0.35), 1.2, true)


# Spec 41 followup — the advance hint as drawn key wafers. Instead of a flat
# chip label ("E / Space — continue · Esc — close") the band shows each key
# as a small WyrdUi.draw_well socket so the prompt reads as carved wood rather
# than printed text — consistent with the hotbar slot language.
class _HintBand extends Control:
	func _init() -> void:
		custom_minimum_size = Vector2(306, 34)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var font := get_theme_default_font()
		var r := Rect2(Vector2.ZERO, size)
		# Parchment backing strip — same cream as the chip stylebox but drawn so
		# the wafers inside share a unified background without a double border.
		draw_rect(r, Color(WyrdUi.CREAM, 0.82))
		draw_rect(r, Color(WyrdUi.KIT_EDGE, 0.45), false, 1.0)
		var cy := size.y * 0.5
		var kh := 20.0          # key-wafer height
		var ky := cy - kh * 0.5
		var tx := ky + kh - 3.0  # text baseline (cap-height offset from bottom of wafer)
		# "E" key wafer.
		var ew := Rect2(Vector2(8.0, ky), Vector2(18.0, kh))
		WyrdUi.draw_well(self, ew, Color(0.90, 0.84, 0.70))
		draw_string(font, Vector2(ew.position.x, tx), "E",
			HORIZONTAL_ALIGNMENT_CENTER, ew.size.x, 11, WyrdUi.INK)
		# "Space" key wafer (wider).
		var sw := Rect2(Vector2(30.0, ky), Vector2(42.0, kh))
		WyrdUi.draw_well(self, sw, Color(0.90, 0.84, 0.70))
		draw_string(font, Vector2(sw.position.x, tx), "Space",
			HORIZONTAL_ALIGNMENT_CENTER, sw.size.x, 10, WyrdUi.INK)
		# "— continue" label.
		draw_string(font, Vector2(76.0, tx), "— continue",
			HORIZONTAL_ALIGNMENT_LEFT, 90.0, 12,
			Color(WyrdUi.INK, 0.60))
		# Gold ◆ divider.
		draw_string(font, Vector2(170.0, tx), "◆",
			HORIZONTAL_ALIGNMENT_CENTER, 16.0, 10,
			Color(WyrdUi.GOLD, 0.65))
		# "Esc" key wafer.
		var escw := Rect2(Vector2(192.0, ky), Vector2(30.0, kh))
		WyrdUi.draw_well(self, escw, Color(0.90, 0.84, 0.70))
		draw_string(font, Vector2(escw.position.x, tx), "Esc",
			HORIZONTAL_ALIGNMENT_CENTER, escw.size.x, 10, WyrdUi.INK)
		# "— close" label.
		draw_string(font, Vector2(226.0, tx), "— close",
			HORIZONTAL_ALIGNMENT_LEFT, 76.0, 12,
			Color(WyrdUi.INK, 0.60))
