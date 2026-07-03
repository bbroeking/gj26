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
	# Spec 48 — warm parchment header band behind the speaker's name.
	# Gives the name a proper storybook nameplate instead of a bare floating
	# terracotta label. Added before the portrait and name so it renders
	# beneath both; mouse events pass through (MOUSE_FILTER_IGNORE).
	var speaker_band := SpeakerBand.new()
	speaker_band.anchor_right = 1.0
	speaker_band.offset_left = 32
	speaker_band.offset_right = -32
	speaker_band.offset_top = 16
	speaker_band.offset_bottom = 92
	speaker_band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(speaker_band)
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


# Spec 48 — warm parchment nameplate band behind the speaker's name.
# A honey-tinted strip (42 % opacity over the panel cream), top bevel, bottom
# ink rule, sparse parchment grain, a gold ◆ anchor-mark left of the name
# text, an ivy leaf spray at the right corner, and a gold ◆ flourish divider
# between the name header and the portrait / body area.
# Pure vector — no texture loads anywhere in _draw (white-rect-safe).
class SpeakerBand extends Control:
	func _draw() -> void:
		# Warm honey parchment strip — the nameplate face.
		var band := Rect2(Vector2.ZERO, Vector2(size.x, 52.0))
		draw_rect(band, Color(0.90, 0.82, 0.62, 0.42))
		# Top bevel — the band catches the panel's warm light.
		draw_rect(Rect2(band.position, Vector2(band.size.x, 2.0)),
			Color(1.0, 0.97, 0.88, 0.35))
		# Bottom ink rule — divides the nameplate from the body zone.
		draw_rect(Rect2(band.position + Vector2(0.0, band.size.y - 2.0),
			Vector2(band.size.x, 2.0)), Color(WyrdUi.KIT_EDGE, 0.28))
		# Aged-paper grain so the band reads as a physical nameplate.
		WyrdUi.draw_parchment_grain(self, band, 31)
		# Gold ◆ anchor mark — sits to the left of the name text (x ≈ 24 px).
		var mid_y := band.size.y * 0.5
		var d := PackedVector2Array([
			Vector2(14.0, mid_y - 6.0), Vector2(20.0, mid_y),
			Vector2(14.0, mid_y + 6.0), Vector2(8.0, mid_y),
		])
		draw_colored_polygon(d, Color(WyrdUi.GOLD, 0.68))
		draw_polyline(d + PackedVector2Array([d[0]]),
			Color(WyrdUi.GOLD.darkened(0.2), 0.50), 1.0)
		# Ivy leaf spray at the right corner — botanical ornament on the frame.
		_draw_leaf_spray(Vector2(size.x - 48.0, mid_y))
		# Gold ◆ flourish rule below — the visual separator between the name
		# header and the portrait + body zone below.
		WyrdUi.draw_flourish(self, Vector2(size.x * 0.5, band.size.y + 14.0),
			size.x * 0.48)

	func _draw_leaf_spray(origin: Vector2) -> void:
		# Three small ivy leaves fanning upward from a shared stem point.
		var leaf := Color(WyrdUi.SAGE, 0.52)
		var vein := Color(0.26, 0.44, 0.17, 0.62)
		for i in 3:
			var ang := deg_to_rad(-50.0 + float(i) * 50.0)
			var tip := origin + Vector2(cos(ang) * 17.0, sin(ang) * 17.0)
			var mid := origin + Vector2(cos(ang) * 8.5, sin(ang) * 8.5)
			var px := -sin(ang) * 5.5
			var py :=  cos(ang) * 5.5
			var pts := PackedVector2Array([
				origin,
				Vector2(mid.x + px, mid.y + py),
				tip,
				Vector2(mid.x - px, mid.y - py),
			])
			draw_colored_polygon(pts, leaf)
			draw_line(origin, tip, vein, 1.0)
