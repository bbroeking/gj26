extends CanvasLayer

# Wyrd — the Waystone socket modal. Lists the chart case; picking one and
# pressing "Step through" consumes it and crosses into the dungeon it
# describes. Esc closes.
#
# Preview block (Tasks 1–3, 6 from impl-system-charts-wayfinding):
#   • per-affix Labels, SAGE for good twins, TERRACOTTA for bad twins
#   • tier badge "T<n>" prefixed to each chart button
#   • expected-XP line below the affix block
#   • boss-den-resolved-bad warning line

const ChartsData = preload("res://data/charts.gd")

var player: Node = null

var _game: Node
var _selected := -1
var _panel: Panel
var _list_box: VBoxContainer
var _detail_box: VBoxContainer  # replaces old _detail Label — one Label per affix
var _go_btn: Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 90
	_game = get_tree().root.get_node_or_null("Game")
	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.55)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)
	_panel = Panel.new()
	WyrdUi.style_panel(_panel)
	_panel.anchor_left = 0.5
	_panel.anchor_top = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_bottom = 0.5
	_panel.offset_left = -300
	_panel.offset_top = -230
	_panel.offset_right = 300
	_panel.offset_bottom = 230
	add_child(_panel)

	var title := Label.new()
	title.text = "The Waystone"
	WyrdUi.style_title(title)
	title.position = Vector2(54, 34)
	_panel.add_child(title)

	var sub := Label.new()
	sub.text = "Socket a chart. The crossing spends it."
	WyrdUi.style_dim(sub, 13)
	sub.position = Vector2(54, 66)
	_panel.add_child(sub)

	# A full chart case outgrows the panel — the list scrolls now,
	# bounded above the detail block.
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.anchor_right = 1.0
	scroll.anchor_bottom = 1.0
	scroll.offset_left = 52
	scroll.offset_top = 92
	scroll.offset_right = -52
	scroll.offset_bottom = -160
	_panel.add_child(scroll)
	_list_box = VBoxContainer.new()
	_list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list_box.add_theme_constant_override("separation", 6)
	scroll.add_child(_list_box)

	# Detail block: a VBoxContainer of per-affix Labels (colour-coded) plus
	# an XP estimate and an optional boss-den warning.  Replaces the single
	# flat _detail Label that was here before (impl Task 1).
	_detail_box = VBoxContainer.new()
	_detail_box.add_theme_constant_override("separation", 4)
	_detail_box.anchor_right = 1.0
	_detail_box.anchor_top = 1.0
	_detail_box.anchor_bottom = 1.0
	_detail_box.offset_left = 52
	_detail_box.offset_right = -52
	_detail_box.offset_top = -150
	_detail_box.offset_bottom = -64
	_panel.add_child(_detail_box)

	_go_btn = Button.new()
	WyrdUi.style_button(_go_btn)
	_go_btn.text = "Step through"
	_go_btn.add_theme_font_size_override("font_size", 17)
	_go_btn.custom_minimum_size = Vector2(200, 40)
	_go_btn.anchor_left = 0.5
	_go_btn.anchor_top = 1.0
	_go_btn.anchor_right = 0.5
	_go_btn.anchor_bottom = 1.0
	_go_btn.offset_left = -100
	_go_btn.offset_top = -54
	_go_btn.offset_bottom = -14
	_go_btn.pressed.connect(_on_go)
	_panel.add_child(_go_btn)

	get_node("/root/Game").modal_opened()
	_render()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_close()

func _close() -> void:
	get_node("/root/Game").modal_closed()
	queue_free()

func _render() -> void:
	for c in _list_box.get_children():
		c.queue_free()
	var n := 0 if _game == null else (_game.charts as Array).size()
	if n == 0:
		var l := Label.new()
		l.text = "Your chart case is empty. Inscribe one at the table."
		WyrdUi.style_body(l, 14)
		_list_box.add_child(l)
	for i in n:
		var chart: Dictionary = _game.charts[i]
		var b := Button.new()
		WyrdUi.style_button(b)
		WyrdUi.mark_selected(b, i == _selected)
		b.toggle_mode = true
		b.button_pressed = i == _selected
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		# Task 2: prefix tier badge so the player reads difficulty at a glance.
		b.text = "T%d  %s" % [int(chart.get("tier", 1)), ChartsData.chart_label(chart)]
		var idx := i
		b.pressed.connect(func():
			_selected = idx
			_render())
		_list_box.add_child(b)
	# Clear the detail block before repopulating it.
	for c in _detail_box.get_children():
		c.queue_free()
	# Detail + button state.
	if _selected >= 0 and _selected < n:
		var chart: Dictionary = _game.charts[_selected]
		_build_detail_preview(chart)
		_go_btn.disabled = false
	else:
		_go_btn.disabled = true

# Build the colour-coded affix preview inside _detail_box for the given chart.
# Tasks 1, 3, 6 from impl-system-charts-wayfinding.
func _build_detail_preview(chart: Dictionary) -> void:
	var affixes: Array = chart.get("affixes", [])
	var has_lines := false
	var boss_bad_den := false  # tracks Task 6 warning condition

	for a in affixes:
		var aff_id := String(a.get("id", ""))
		var aff: Dictionary = ChartsData.AFFIXES.get(aff_id, {})
		if aff.is_empty():
			continue
		var is_good := bool(a.get("good", false))
		# Stability % for this affix — computed from base + level contribution.
		# We don't store carto level on the chart dict; show base_stab for now.
		var stab := int(aff.get("base_stab", 50))

		var row := Label.new()
		row.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if is_good:
			row.text = "✓ %s — %s  (%d%% stable)" % [
				String(aff.name), String(aff.good_desc), stab]
			WyrdUi.style_body(row, 13)
			row.add_theme_color_override("font_color", WyrdUi.SAGE)
		else:
			row.text = "✗ %s — %s" % [String(aff.bad_name), String(aff.bad_desc)]
			WyrdUi.style_body(row, 13)
			row.add_theme_color_override("font_color", WyrdUi.TERRACOTTA)
			# Task 6: boss-den affix resolved bad → show warning below.
			if String(aff.get("kind", "")) == "boss":
				boss_bad_den = true
		_detail_box.add_child(row)
		has_lines = true

	if not has_lines:
		var clean := Label.new()
		clean.text = "A clean chart. Nothing inked in but the way there and back."
		WyrdUi.style_body(clean, 13)
		_detail_box.add_child(clean)

	# Task 6: warn the player when a boss-den affix resolved to the bad twin.
	if boss_bad_den:
		var warn := Label.new()
		warn.text = "⚠ Den affix resolved bad — boss won't appear."
		WyrdUi.style_dim(warn, 13)
		warn.add_theme_color_override("font_color", WyrdUi.TERRACOTTA)
		_detail_box.add_child(warn)

	# Task 3: expected XP estimate — dim scribe-note below the affix block.
	var xp := ChartsData.completion_xp(chart)
	var xp_label := Label.new()
	xp_label.text = "≈ %d xp on completion" % xp
	WyrdUi.style_dim(xp_label, 13)
	_detail_box.add_child(xp_label)

func _on_go() -> void:
	if _game == null or _selected < 0 or _selected >= (_game.charts as Array).size():
		return
	var chart: Dictionary = _game.charts[_selected]
	get_node("/root/Game").modal_closed()
	_game.enter_dungeon(chart, player)
	queue_free()
