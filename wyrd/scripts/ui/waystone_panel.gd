extends CanvasLayer

# Spec 59 — the Waystone is a physical crossing folio: choose a Chart from its
# case, read the road and its consequences, then spend it by stepping through.

const ChartsData = preload("res://data/charts.gd")
const Tokens = preload("res://scripts/ui/foundation/ui_tokens.gd")
const FocusPointer = preload("res://scripts/ui/components/focus_pointer.gd")
const JournalRow = preload("res://scripts/ui/components/journal_list_row.gd")
const Workbench = preload("res://scripts/ui/components/transaction_workbench.gd")

const WAYSTONE_EMBLEM := preload("res://assets/ui/field_journal/icons/waystone.png")
const CHART_CASE_ICON := preload("res://assets/ui/field_journal/icons/chart_case.png")
const CHART_ICON := preload("res://assets/ui/icons/chart.png")

var player: Node = null
var _game: Node
var _selected := 0
var _workbench: TransactionWorkbench
var _list_box: VBoxContainer
var _detail_box: VBoxContainer
var _go_button: Button
var _modal_owned := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 90
	_game = get_tree().root.get_node_or_null("Game")
	WyrdUi.make_backdrop(self, _close)
	var count := 0 if _game == null else (_game.charts as Array).size()
	_build_workbench(count)
	if _game != null:
		_game.modal_opened()
		_modal_owned = true
	tree_exiting.connect(_release_modal)
	var focus_pointer := FocusPointer.new()
	focus_pointer.name = "TransactionFocusPointer"
	add_child(focus_pointer)


func _build_workbench(chart_count: int) -> void:
	_workbench = Workbench.new()
	_workbench.anchor_left = 0.5
	_workbench.anchor_top = 0.5
	_workbench.anchor_right = 0.5
	_workbench.anchor_bottom = 0.5
	_workbench.close_requested.connect(_close)
	add_child(_workbench)
	_workbench.setup("The Waystone",
		"A written road opens once. The crossing spends the Chart.",
		_waystone_emblem_texture())
	if chart_count == 0:
		_workbench.custom_minimum_size = Vector2(780.0, 420.0)
		_workbench.offset_left = -390.0
		_workbench.offset_top = -210.0
		_workbench.offset_right = 390.0
		_workbench.offset_bottom = 210.0
		_build_empty_state(_workbench.add_leaf("WaystoneEmptyState", 1.0))
		_workbench.add_footer_hint("Esc/B close")
		return
	_workbench.offset_left = -520.0
	_workbench.offset_top = -325.0
	_workbench.offset_right = 520.0
	_workbench.offset_bottom = 325.0
	_build_chart_case(_workbench.add_leaf("ChartCaseLeaf", 0.36))
	_build_crossing_folio(_workbench.add_leaf("CrossingFolioLeaf", 0.64))
	_workbench.add_footer_hint("↑↓ choose Chart  ·  →/Tab Step Through  ·  Esc/B close")
	_selected = clampi(_selected, 0, chart_count - 1)
	_render_chart_case()


func _build_empty_state(leaf: VBoxContainer) -> void:
	var center := CenterContainer.new()
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	leaf.add_child(center)
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(620.0, 190.0)
	row.add_theme_constant_override("separation", Tokens.SPACE_5)
	center.add_child(row)
	var case_art := TextureRect.new()
	case_art.name = "PaintedChartCase"
	case_art.texture = CHART_CASE_ICON
	case_art.custom_minimum_size = Vector2(150.0, 150.0)
	case_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	case_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	case_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(case_art)
	var copy := VBoxContainer.new()
	copy.alignment = BoxContainer.ALIGNMENT_CENTER
	copy.add_theme_constant_override("separation", Tokens.SPACE_3)
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(copy)
	var heading := Label.new()
	heading.text = "No Charts Waiting"
	heading.theme_type_variation = &"PageTitle"
	copy.add_child(heading)
	var body := Label.new()
	body.text = "Inscribe a road with Mara, then return to socket it here."
	body.theme_type_variation = &"Body"
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(body)
	var visit := Button.new()
	visit.name = "CloseWaystoneButton"
	visit.text = "Close the Waystone"
	visit.tooltip_text = "Close the Waystone."
	visit.custom_minimum_size = Vector2(290.0, Tokens.HIT_TARGET)
	visit.theme_type_variation = &"PrimaryButton"
	visit.pressed.connect(_close)
	copy.add_child(visit)
	visit.grab_focus.call_deferred()


func _build_chart_case(leaf: VBoxContainer) -> void:
	var heading := Label.new()
	heading.text = "Chart Case"
	heading.theme_type_variation = &"SectionTitle"
	leaf.add_child(heading)
	var hint := Label.new()
	hint.text = "Choose the written road to offer the stone."
	hint.theme_type_variation = &"RowSubtitle"
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	leaf.add_child(hint)
	leaf.add_child(HSeparator.new())
	var scroll := ScrollContainer.new()
	scroll.name = "ChartCaseScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	leaf.add_child(scroll)
	_list_box = VBoxContainer.new()
	_list_box.name = "ChartCaseList"
	_list_box.add_theme_constant_override("separation", Tokens.SPACE_2)
	_list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list_box)


func _build_crossing_folio(leaf: VBoxContainer) -> void:
	leaf.add_theme_constant_override("separation", Tokens.SPACE_2)
	var heading := Label.new()
	heading.text = "The Crossing"
	heading.theme_type_variation = &"SectionTitle"
	leaf.add_child(heading)
	leaf.add_child(HSeparator.new())
	_detail_box = VBoxContainer.new()
	_detail_box.name = "CrossingDetail"
	_detail_box.add_theme_constant_override("separation", Tokens.SPACE_2)
	_detail_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	leaf.add_child(_detail_box)


func _render_chart_case() -> void:
	if _game == null or (_game.charts as Array).is_empty():
		return
	_selected = clampi(_selected, 0, (_game.charts as Array).size() - 1)
	for child in _list_box.get_children():
		_list_box.remove_child(child)
		child.queue_free()
	for index in (_game.charts as Array).size():
		var chart: Dictionary = _game.charts[index]
		var affix_count := (chart.get("affixes", []) as Array).size()
		var den_level: int = _game.den_level_for_tier(int(chart.get("tier", 1)))
		var band: Dictionary = _game.difficulty_band(chart)
		var row := JournalRow.new()
		row.name = "ChartCaseRow%d" % index
		row.setup({
			"title": ChartsData.chart_label(chart),
			"subtitle": "Tier %d · Den Level %d" % [int(chart.get("tier", 1)), den_level],
			"trailing": String(band.get("label", "Fair")),
			"badge": "Clean" if affix_count == 0 else "%d marks" % affix_count,
			"icon": CHART_ICON,
			"state": JournalRow.RowState.SELECTED if index == _selected \
				else JournalRow.RowState.NORMAL,
			"trailing_color": _difficulty_color(String(band.get("tone", "fair"))),
			"badge_color": Tokens.SAGE.darkened(0.25),
		})
		row.pressed.connect(_select_chart.bind(index))
		_list_box.add_child(row)
	_render_crossing(_game.charts[_selected])
	_focus_selected_chart.call_deferred()


func _render_crossing(chart: Dictionary) -> void:
	for child in _detail_box.get_children():
		_detail_box.remove_child(child)
		child.queue_free()
	var heading := HBoxContainer.new()
	heading.custom_minimum_size.y = 68.0
	_detail_box.add_child(heading)
	var names := VBoxContainer.new()
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(names)
	var title := Label.new()
	title.name = "CrossingChartTitle"
	title.text = ChartsData.chart_label(chart)
	title.theme_type_variation = &"PageTitle"
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	names.add_child(title)
	var band: Dictionary = _game.difficulty_band(chart)
	var den_level: int = _game.den_level_for_tier(int(chart.get("tier", 1)))
	var den := Label.new()
	den.text = "Den Level %d  ·  %s" % [den_level, String(band.get("label", "Fair"))]
	den.theme_type_variation = &"SectionTitle"
	den.add_theme_color_override("font_color",
		_difficulty_color(String(band.get("tone", "fair"))))
	names.add_child(den)
	var emblem := _RouteEmblem.new()
	emblem.custom_minimum_size = Vector2(68.0, 68.0)
	emblem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	heading.add_child(emblem)

	var middle := HBoxContainer.new()
	middle.name = "RouteAndAffixes"
	middle.custom_minimum_size.y = 168.0
	middle.size_flags_vertical = Control.SIZE_EXPAND_FILL
	middle.add_theme_constant_override("separation", Tokens.SPACE_3)
	_detail_box.add_child(middle)
	var affix_scroll := ScrollContainer.new()
	affix_scroll.name = "AffixScroll"
	affix_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	affix_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	affix_scroll.size_flags_stretch_ratio = 0.45
	affix_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	middle.add_child(affix_scroll)
	var affix_copy := VBoxContainer.new()
	affix_copy.add_theme_constant_override("separation", Tokens.SPACE_2)
	affix_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	affix_scroll.add_child(affix_copy)
	_build_affix_copy(affix_copy, chart)
	var sketch := _RouteSketch.new()
	sketch.custom_minimum_size = Vector2(0.0, 168.0)
	sketch.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sketch.size_flags_stretch_ratio = 0.55
	sketch.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sketch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	middle.add_child(sketch)

	var consequence := PanelContainer.new()
	consequence.name = "CrossingConsequence"
	consequence.theme_type_variation = &"PaperSurface"
	consequence.custom_minimum_size.y = 54.0
	_detail_box.add_child(consequence)
	var terms := HBoxContainer.new()
	terms.add_theme_constant_override("separation", Tokens.SPACE_3)
	consequence.add_child(terms)
	var spend := Label.new()
	spend.text = "✕  Crossing spends this Chart. It leaves your Chart Case."
	spend.theme_type_variation = &"Body"
	spend.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	spend.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spend.add_theme_color_override("font_color", Tokens.TERRACOTTA)
	terms.add_child(spend)
	var xp := Label.new()
	xp.text = "Return · %d XP" % ChartsData.completion_xp(chart)
	xp.theme_type_variation = &"SectionTitle"
	xp.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	terms.add_child(xp)
	_go_button = Button.new()
	_go_button.name = "StepThroughButton"
	_go_button.text = "Step Through"
	_go_button.theme_type_variation = &"PrimaryButton"
	_go_button.custom_minimum_size.y = 64.0
	_go_button.pressed.connect(_on_go)
	_detail_box.add_child(_go_button)


func _build_affix_copy(parent: VBoxContainer, chart: Dictionary) -> void:
	var affixes: Array = chart.get("affixes", [])
	if affixes.is_empty():
		var clean := Label.new()
		clean.text = "○  A clean road — nothing inked in but the way there and back."
		clean.theme_type_variation = &"Body"
		clean.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		parent.add_child(clean)
		return
	for raw_affix in affixes:
		var affix: Dictionary = raw_affix
		var definition: Dictionary = ChartsData.AFFIXES.get(String(affix.get("id", "")), {})
		if definition.is_empty():
			continue
		var good := bool(affix.get("good", false))
		var presentation: Dictionary = ChartsData.affix_presentation(chart, affix)
		var row := Label.new()
		row.theme_type_variation = &"Body"
		row.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.text = "%s  %s — %s" % ["✓" if good else "✕",
			String(presentation.get("name", "Affix")),
			String(presentation.get("desc", ""))]
		row.add_theme_color_override("font_color", Tokens.SAGE.darkened(0.25) \
			if good else Tokens.TERRACOTTA)
		parent.add_child(row)


func _select_chart(index: int) -> void:
	_selected = clampi(index, 0, (_game.charts as Array).size() - 1)
	_render_chart_case()


func _focus_selected_chart() -> void:
	if _list_box == null or _list_box.get_child_count() == 0:
		return
	var row := _list_box.get_child(_selected) as Button
	if row != null and not row.is_queued_for_deletion():
		row.grab_focus()


func _difficulty_color(tone: String) -> Color:
	if tone == "easy":
		return Tokens.SAGE.darkened(0.25)
	if tone in ["hard", "deadly"]:
		return Tokens.TERRACOTTA
	return Tokens.TEXT_ON_PAPER


func _waystone_emblem_texture() -> Texture2D:
	# The source atlas contains a detached shadow fleck below the painted stone;
	# crop it at presentation time rather than letting it read as a stray dash.
	var cropped := AtlasTexture.new()
	cropped.atlas = WAYSTONE_EMBLEM
	cropped.region = Rect2(0.0, 0.0, 256.0, 224.0)
	return cropped


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_close()
		get_viewport().set_input_as_handled()


func _close() -> void:
	_release_modal()
	queue_free()


func _release_modal() -> void:
	if not _modal_owned:
		return
	_modal_owned = false
	if _game != null and is_instance_valid(_game):
		_game.modal_closed()


func _on_go() -> void:
	if _game == null or _selected < 0 or _selected >= (_game.charts as Array).size():
		return
	if _go_button != null:
		_go_button.disabled = true
	var chart: Dictionary = _game.charts[_selected]
	_release_modal()
	_game.enter_dungeon(chart, player)
	queue_free()


class _RouteEmblem extends Control:
	func _draw() -> void:
		var center := size * 0.5
		var radius := minf(size.x, size.y) * 0.42
		draw_circle(center, radius, Tokens.MOSS)
		draw_arc(center, radius, 0, TAU, 40, Tokens.WALNUT, 3.0, true)
		draw_line(center + Vector2(-18, 16), center + Vector2(-6, 1),
			Tokens.TEXT_ON_DARK, 4.0, true)
		draw_line(center + Vector2(-6, 1), center + Vector2(7, 7),
			Tokens.TEXT_ON_DARK, 4.0, true)
		draw_line(center + Vector2(7, 7), center + Vector2(18, -16),
			Tokens.TEXT_ON_DARK, 4.0, true)


class _RouteSketch extends Control:
	func _draw() -> void:
		var page := StyleBoxFlat.new()
		page.bg_color = Tokens.PAPER.darkened(0.025)
		page.border_color = Color(Tokens.WALNUT, 0.35)
		page.set_border_width_all(2)
		page.set_corner_radius_all(8)
		draw_style_box(page, Rect2(Vector2.ZERO, size))
		# A deterministic hand-inked route: a soft under-stroke and a slightly
		# wandering sepia line, rather than a rigid developer polyline.
		var anchors := PackedVector2Array([
			Vector2(size.x * 0.12, size.y * 0.82),
			Vector2(size.x * 0.35, size.y * 0.60),
			Vector2(size.x * 0.58, size.y * 0.68),
			Vector2(size.x * 0.82, size.y * 0.26),
		])
		var road := PackedVector2Array()
		for segment in range(anchors.size() - 1):
			for step in 7:
				var t := float(step) / 7.0
				var point := anchors[segment].lerp(anchors[segment + 1], t)
				point.y += sin(float(segment * 7 + step) * 1.7) * 1.8
				road.append(point)
		road.append(anchors[anchors.size() - 1])
		draw_polyline(road, Color(Tokens.GOLD_MUTED.darkened(0.25), 0.18), 8.0, true)
		draw_polyline(road, Color(Tokens.WALNUT, 0.64), 3.2, true)
		for anchor in anchors:
			draw_circle(anchor, 5.0, Tokens.PAPER_RAISED)
			draw_arc(anchor, 5.0, 0, TAU, 18, Color(Tokens.WALNUT, 0.7), 1.5, true)
		for point in [Vector2(0.18, 0.34), Vector2(0.28, 0.30),
				Vector2(0.68, 0.34), Vector2(0.76, 0.44)]:
			var p: Vector2 = Vector2(point) * size
			draw_line(p + Vector2(0, 14), p + Vector2(0, -2), Tokens.WALNUT, 2.5, true)
			draw_circle(p + Vector2(-5, -5), 7.0, Color(Tokens.SAGE, 0.58))
			draw_circle(p + Vector2(3, -9), 8.0, Color(Tokens.SAGE.darkened(0.08), 0.62))
			draw_circle(p + Vector2(7, -3), 6.0, Color(Tokens.SAGE, 0.52))
		var stone := Vector2(size.x * 0.82, size.y * 0.24)
		var standing := PackedVector2Array([
			stone + Vector2(-10, 19), stone + Vector2(-8, -14),
			stone + Vector2(0, -22), stone + Vector2(9, -13), stone + Vector2(10, 19)])
		draw_colored_polygon(standing, Color(Tokens.WALNUT, 0.72))
		draw_polyline(PackedVector2Array([
			stone + Vector2(-3, -9), stone + Vector2(3, -3), stone + Vector2(-2, 5)]),
			Tokens.GOLD_MUTED, 1.8, true)
