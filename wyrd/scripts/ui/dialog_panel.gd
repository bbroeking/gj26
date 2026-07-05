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
var _banner: SpeakerBanner
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
	_banner = SpeakerBanner.new()
	_banner.anchor_right = 1.0
	_banner.offset_left = 36
	_banner.offset_right = -36
	_banner.offset_top = 34
	_banner.custom_minimum_size = Vector2(0, 60)
	_panel.add_child(_banner)
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
	_banner.speaker_name = _speaker
	_banner.queue_redraw()
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


# Storybook speaker-name banner: a warm parchment plaque spanning the top of
# the dialog, with a honey bevel, gold inner frame, a flourish-diamond
# separator, and ivy sprigs at each end. Replaces the plain name label so the
# speaker's entrance reads as "announced" rather than typed.
class SpeakerBanner extends Control:
	var speaker_name := ""

	func _draw() -> void:
		if size.x < 30:
			return
		var hdr := WyrdUi.font_header()
		if hdr == null:
			hdr = get_theme_default_font()
		# Warm honey-cream plaque strip — slightly richer than the main parchment
		var sr := Rect2(Vector2(0, 5), Vector2(size.x, size.y - 8))
		draw_rect(sr, Color(0.96, 0.90, 0.74))
		# Top honey bevel: the plaque catches the warm overhead light
		draw_rect(Rect2(sr.position + Vector2(4, 1.5),
			Vector2(sr.size.x - 8, 2.0)), Color(1.0, 0.97, 0.88, 0.55))
		# Bottom ink shadow: grounds the plaque onto the parchment face
		draw_rect(Rect2(Vector2(4, sr.end.y - 3),
			Vector2(sr.size.x - 8, 2.0)), Color(WyrdUi.KIT_EDGE, 0.28))
		# Ink border + gold inner inset line (the "burnished" read)
		draw_rect(sr, WyrdUi.KIT_EDGE, false, 1.5)
		draw_rect(sr.grow(-4.5), Color(WyrdUi.GOLD, 0.42), false, 1.0)
		# Speaker name centred in the plaque
		if speaker_name != "":
			var name_y := sr.position.y + sr.size.y * 0.60
			draw_string(hdr, Vector2(0.0, name_y), speaker_name,
				HORIZONTAL_ALIGNMENT_CENTER, size.x, 24, WyrdUi.TERRACOTTA)
		# Flourish-diamond separator below the name
		WyrdUi.draw_flourish(self,
			Vector2(size.x * 0.5, sr.position.y + sr.size.y * 0.86),
			size.x * 0.50)
		# Ivy sprigs at each end — the design language's leafy ornament
		var sprig_y := sr.position.y + sr.size.y * 0.74
		WyrdUi.draw_leaf_sprig(self, Vector2(30.0, sprig_y), 18.0)
		WyrdUi.draw_leaf_sprig(self, Vector2(size.x - 30.0, sprig_y), 18.0)


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
