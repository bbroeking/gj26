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
	var banner := _SpeakerBanner.new()
	banner.anchor_right = 1.0
	banner.offset_left = WyrdUi.PANEL_MARGIN_L
	banner.offset_right = -WyrdUi.PANEL_MARGIN_R
	banner.offset_top = 34.0
	banner.offset_bottom = 78.0
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(banner)
	_name_lbl = banner._build_label()
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


# Spec 47 — the carved speaker nameplate: a terracotta-tinted wooden plank
# spanning the panel's interior width, with a gold inset line, flourishes at
# each end, and the NPC's name centered in cream IM Fell — so the first thing
# the player reads announces who's speaking, not just where the text starts.
class _SpeakerBanner extends Control:
	func _build_label() -> Label:
		var hf := WyrdUi.font_header()
		var lbl := Label.new()
		if hf != null:
			lbl.add_theme_font_override("font", hf)
		lbl.add_theme_font_size_override("font_size", 22)
		lbl.add_theme_color_override("font_color",
			WyrdUi.CREAM.lerp(WyrdUi.KIT_PLATE, 0.12))
		lbl.anchor_right = 1.0
		lbl.anchor_bottom = 1.0
		lbl.offset_left = 44.0
		lbl.offset_right = -44.0
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		add_child(lbl)
		return lbl

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		if size.x < 4.0 or size.y < 4.0:
			return
		# Terracotta-tinted carved plank — warm, inviting, storybook.
		draw_rect(r, WyrdUi.KIT_PLATE.lerp(WyrdUi.TERRACOTTA, 0.18).darkened(0.04))
		# Top honey bevel + bottom ink shadow (the carved-plank read).
		draw_rect(Rect2(r.position + Vector2(3.0, 2.0),
			Vector2(r.size.x - 6.0, 2.5)), Color(1.0, 0.97, 0.86, 0.45))
		draw_rect(Rect2(r.position + Vector2(3.0, r.size.y - 3.5),
			Vector2(r.size.x - 6.0, 2.5)), Color(WyrdUi.KIT_EDGE, 0.35))
		# Faint parchment grain over the plank face.
		WyrdUi.draw_parchment_grain(self, r, 13)
		# Ink border + burnished gold inner inset.
		draw_rect(r, WyrdUi.KIT_EDGE, false, 2.0)
		draw_rect(r.grow(-4.0), Color(WyrdUi.GOLD, 0.55), false, 1.0)
		# Flourishes tucked into each end — the speaker is announced.
		WyrdUi.draw_flourish(self, Vector2(28.0, r.size.y * 0.5), 32.0)
		WyrdUi.draw_flourish(self, Vector2(r.size.x - 28.0, r.size.y * 0.5), 32.0)
		# Small sage ivy bud pair at the outer tip of each flourish line — the
		# botanical ornament the design language puts on every carved surface.
		# draw_flourish (width=32) extends its ink lines ±16 px from the ◆ centre,
		# so the outer tips sit at x≈12 and x≈(size.x−12), just inside the border.
		var cy2 := r.size.y * 0.5
		for xi in [12.0, r.size.x - 12.0]:
			var sign := 1.0 if xi < r.size.x * 0.5 else -1.0
			for ys in [-1.0, 1.0]:
				draw_colored_polygon(PackedVector2Array([
					Vector2(xi + sign * 1.5, cy2 + ys * 1.5),
					Vector2(xi + sign * 4.5, cy2 + ys * 6.5),
					Vector2(xi + sign * 7.0, cy2 + ys * 2.0)
				]), Color(WyrdUi.SAGE, 0.60))


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
