extends Control

# Persistent map-loading presentation shared by the title, Town returns, Chart
# entry, and deeper-layer transitions. The composition borrows the useful
# Warcraft III grammar (painted destination + chapter plaque + heavy progress
# trough) while all materials and language remain Wayfinder's Field Journal.

const ChartsData = preload("res://data/charts.gd")
const Tokens = preload("res://scripts/ui/foundation/ui_tokens.gd")
const FIELD_THEME := preload("res://themes/wayfinder_theme.tres")

const TOWN_ART := "res://assets/ui/loading/bramblewood_panorama.png"
const DUNGEON_ART := "res://assets/ui/loading/charted_hollow.png"

var _art: TextureRect
var _eyebrow: Label
var _title: Label
var _lore: Label
var _seed: Label
var _seed_base := ""
var _affix_box: VBoxContainer
var _chart_sketch: Control
var _progress: ProgressBar
var _status: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = FIELD_THEME
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build()
	visible = false


static func card_for(scene_path: String, game: Node) -> Dictionary:
	if scene_path.ends_with("Town.tscn"):
		return {
			"art": TOWN_ART,
			"eyebrow": "THE CHARTMAKER'S YARD",
			"title": "Bramblewood",
			"lore": "Where the wagon road ends, every deeper road begins.",
			"seed": "HOME ROAD",
			"affixes": [],
			"empty_affixes": "Kettle warm · lamps lit · neighbors near",
		}
	var chart: Dictionary = {}
	if game != null and game.get("active_chart") is Dictionary:
		chart = (game.get("active_chart") as Dictionary).duplicate(true)
	if chart.is_empty():
		return {
			"art": DUNGEON_ART,
			"eyebrow": "AN UNCHARTED ROAD",
			"title": "The Hollow",
			"lore": "Stone, root, and old lantern-light wait beyond the Waystone.",
			"seed": "UNWRITTEN SEED",
			"affixes": [],
			"empty_affixes": "No Affixes are visible on this road.",
		}
	var template_id := String(chart.get("template_id", ""))
	var template: Dictionary = ChartsData.TEMPLATES.get(template_id, {})
	var layer := maxi(1, int(chart.get("layer", 1)))
	var max_layers := maxi(layer, int(chart.get("max_layers", layer)))
	var affix_rows: Array = []
	for affix_v in chart.get("affixes", []):
		if not affix_v is Dictionary:
			continue
		var affix := affix_v as Dictionary
		var presentation := ChartsData.affix_presentation(chart, affix)
		affix_rows.append({
			"badge": "GOOD TWIN" if bool(affix.get("good", false)) else "BAD TWIN",
			"tone": "good" if bool(affix.get("good", false)) else "bad",
			"name": String(presentation.get("name", "Unnamed Affix")),
			"desc": String(presentation.get("desc", "")),
		})
	for omen_v in chart.get("omens", []):
		if omen_v is Dictionary:
			affix_rows.append({
				"badge": "DEPTH OMEN", "tone": "omen",
				"name": String((omen_v as Dictionary).get("name", "The road deepens")),
				"desc": String((omen_v as Dictionary).get("desc", "The next layer asks a dearer price.")),
			})
	var title := String(template.get("name", chart.get("name", "Charted Hollow")))
	return {
		"art": DUNGEON_ART,
		"eyebrow": "CHARTED ROAD · LAYER %d OF %d" % [layer, max_layers],
		"title": title,
		"lore": String(template.get("desc",
			"A road written by hand, with consequences written beside it.")),
		"seed": "CHART SEED %d" % int(chart.get("seed", 0)),
		"affixes": affix_rows,
		"empty_affixes": "A quiet Chart · no Affixes written",
	}


func show_card(card: Dictionary) -> void:
	if not is_node_ready():
		await ready
	var art_path := String(card.get("art", TOWN_ART))
	_art.texture = load(art_path) if ResourceLoader.exists(art_path) else null
	_eyebrow.text = String(card.get("eyebrow", "THE ROAD AHEAD"))
	_title.text = String(card.get("title", "Wayfinder"))
	_lore.text = String(card.get("lore", ""))
	_seed_base = String(card.get("seed", ""))
	_seed.text = _seed_base
	_chart_sketch.visible = false
	_rebuild_affixes(card.get("affixes", []),
		String(card.get("empty_affixes", "No Affixes are visible.")))
	_progress.value = 0.0
	_status.text = "Reading the Chart…"
	modulate = Color.WHITE
	visible = true


func set_layout_summary(layout: Dictionary) -> void:
	var room_count := (layout.get("rooms", []) as Array).size()
	var edge_count := (layout.get("room_edges", []) as Array).size()
	var loop_count := maxi(0, edge_count - maxi(0, room_count - 1))
	var harvest_count := 0
	for decor_v in layout.get("decor", []):
		if decor_v is Dictionary and bool((decor_v as Dictionary).get("gather", false)):
			harvest_count += 1
	_seed.text = "%s · %d ROOMS · %d LOOP%s · %d HARVEST%s" % [
		_seed_base, room_count, loop_count, "" if loop_count == 1 else "S",
		harvest_count, "" if harvest_count == 1 else "S"]
	_chart_sketch.call("set_layout", layout)
	_chart_sketch.visible = true


func set_progress(amount: float) -> void:
	var normalized := clampf(amount, 0.0, 1.0)
	_progress.value = maxf(float(_progress.value), normalized * 100.0)
	if normalized < 0.28:
		_status.text = "Reading the Chart…"
	elif normalized < 0.62:
		_status.text = "Laying the rooms and crossings…"
	elif normalized < 0.94:
		_status.text = "Placing lanterns, harvests, and denizens…"
	else:
		_status.text = "The road is ready."


func finish_progress() -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_method(func(value: float) -> void: set_progress(value),
		float(_progress.value) / 100.0, 1.0, 0.65)
	await tween.finished


func fade_out() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.22)
	await tween.finished
	visible = false
	modulate = Color.WHITE


func _rebuild_affixes(raw_rows, empty_text: String) -> void:
	for child in _affix_box.get_children():
		child.queue_free()
	if not raw_rows is Array or (raw_rows as Array).is_empty():
		var empty := Label.new()
		empty.text = empty_text
		empty.theme_type_variation = &"Body"
		empty.add_theme_color_override("font_color", Tokens.TEXT_ON_DARK_DIM)
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_affix_box.add_child(empty)
		return
	for row_v in raw_rows:
		if row_v is Dictionary:
			_affix_box.add_child(_affix_row(row_v as Dictionary))


func _affix_row(row: Dictionary) -> Control:
	var panel := PanelContainer.new()
	var tone := String(row.get("tone", "bad"))
	var accent := Tokens.SAGE if tone == "good" else Tokens.TERRACOTTA \
		if tone == "bad" else Tokens.GOLD_MUTED
	var style := StyleBoxFlat.new()
	style.bg_color = Color(Tokens.WALNUT_DEEP, 0.93)
	style.border_color = accent
	style.border_width_left = 5
	style.set_corner_radius_all(4)
	style.content_margin_left = 12.0
	style.content_margin_right = 10.0
	style.content_margin_top = 7.0
	style.content_margin_bottom = 7.0
	panel.add_theme_stylebox_override("panel", style)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	panel.add_child(col)
	var badge := Label.new()
	badge.text = String(row.get("badge", "AFFIX"))
	badge.theme_type_variation = &"Caption"
	badge.add_theme_font_size_override("font_size", 14)
	badge.add_theme_color_override("font_color", accent)
	col.add_child(badge)
	var name_label := Label.new()
	name_label.text = String(row.get("name", "Unnamed Affix"))
	name_label.theme_type_variation = &"SectionTitle"
	name_label.add_theme_color_override("font_color", Tokens.TEXT_ON_DARK)
	col.add_child(name_label)
	var desc := Label.new()
	desc.text = String(row.get("desc", ""))
	desc.theme_type_variation = &"Caption"
	desc.add_theme_color_override("font_color", Tokens.TEXT_ON_DARK_DIM)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(desc)
	return panel


func _build() -> void:
	_art = TextureRect.new()
	_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_art)

	var wash := ColorRect.new()
	wash.color = Color(0.07, 0.045, 0.025, 0.22)
	wash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(wash)

	var frame := Panel.new()
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.offset_left = 18.0
	frame.offset_top = 18.0
	frame.offset_right = -18.0
	frame.offset_bottom = -18.0
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var frame_style := StyleBoxFlat.new()
	frame_style.bg_color = Color.TRANSPARENT
	frame_style.border_color = Tokens.WALNUT_DEEP
	frame_style.set_border_width_all(12)
	frame_style.set_corner_radius_all(10)
	frame_style.shadow_color = Color(0.02, 0.01, 0.0, 0.8)
	frame_style.shadow_size = 16
	frame.add_theme_stylebox_override("panel", frame_style)
	add_child(frame)

	var inner_frame := Panel.new()
	inner_frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inner_frame.offset_left = 29.0
	inner_frame.offset_top = 29.0
	inner_frame.offset_right = -29.0
	inner_frame.offset_bottom = -29.0
	inner_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var inner_style := StyleBoxFlat.new()
	inner_style.bg_color = Color.TRANSPARENT
	inner_style.border_color = Color(Tokens.GOLD_MUTED, 0.92)
	inner_style.set_border_width_all(3)
	inner_style.set_corner_radius_all(6)
	inner_frame.add_theme_stylebox_override("panel", inner_style)
	add_child(inner_frame)

	_chart_sketch = ChartSketch.new()
	_chart_sketch.anchor_left = 0.055
	_chart_sketch.anchor_right = 0.57
	_chart_sketch.anchor_top = 0.075
	_chart_sketch.anchor_bottom = 0.51
	_chart_sketch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_chart_sketch.visible = false
	add_child(_chart_sketch)

	var plaque := PanelContainer.new()
	plaque.anchor_left = 0.055
	plaque.anchor_right = 0.57
	plaque.anchor_top = 0.54
	plaque.anchor_bottom = 0.79
	var plaque_style := _dark_plate_style(0.92)
	plaque_style.content_margin_left = 28.0
	plaque_style.content_margin_right = 28.0
	plaque_style.content_margin_top = 16.0
	plaque_style.content_margin_bottom = 16.0
	plaque.add_theme_stylebox_override("panel", plaque_style)
	add_child(plaque)
	var copy := VBoxContainer.new()
	copy.add_theme_constant_override("separation", 2)
	plaque.add_child(copy)
	_eyebrow = Label.new()
	_eyebrow.theme_type_variation = &"Caption"
	_eyebrow.add_theme_color_override("font_color", Tokens.GOLD_MUTED)
	copy.add_child(_eyebrow)
	_title = Label.new()
	_title.theme_type_variation = &"PageTitle"
	_title.add_theme_font_size_override("font_size", 38)
	_title.add_theme_color_override("font_color", Tokens.TEXT_ON_DARK)
	copy.add_child(_title)
	_lore = Label.new()
	_lore.theme_type_variation = &"Body"
	_lore.add_theme_color_override("font_color", Tokens.TEXT_ON_DARK_DIM)
	_lore.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(_lore)
	_seed = Label.new()
	_seed.theme_type_variation = &"Caption"
	_seed.add_theme_color_override("font_color", Tokens.GOLD_MUTED)
	copy.add_child(_seed)

	var affix_plate := PanelContainer.new()
	affix_plate.anchor_left = 0.61
	affix_plate.anchor_right = 0.945
	affix_plate.anchor_top = 0.09
	affix_plate.anchor_bottom = 0.79
	var affix_style := _dark_plate_style(0.91)
	affix_style.content_margin_left = 16.0
	affix_style.content_margin_right = 16.0
	affix_style.content_margin_top = 14.0
	affix_style.content_margin_bottom = 14.0
	affix_plate.add_theme_stylebox_override("panel", affix_style)
	add_child(affix_plate)
	var affix_col := VBoxContainer.new()
	affix_col.add_theme_constant_override("separation", 8)
	affix_plate.add_child(affix_col)
	var affix_heading := Label.new()
	affix_heading.text = "WHAT THE CHART HAS WRITTEN"
	affix_heading.theme_type_variation = &"SectionTitle"
	affix_heading.add_theme_color_override("font_color", Tokens.TEXT_ON_DARK)
	affix_col.add_child(affix_heading)
	var rule := HSeparator.new()
	affix_col.add_child(rule)
	_affix_box = VBoxContainer.new()
	_affix_box.add_theme_constant_override("separation", 8)
	affix_col.add_child(_affix_box)

	var loading_plate := PanelContainer.new()
	loading_plate.anchor_left = 0.055
	loading_plate.anchor_right = 0.945
	loading_plate.anchor_top = 0.83
	loading_plate.anchor_bottom = 0.955
	var loading_style := _dark_plate_style(0.97)
	loading_style.content_margin_left = 20.0
	loading_style.content_margin_right = 20.0
	loading_style.content_margin_top = 10.0
	loading_style.content_margin_bottom = 10.0
	loading_plate.add_theme_stylebox_override("panel", loading_style)
	add_child(loading_plate)
	var load_col := VBoxContainer.new()
	load_col.add_theme_constant_override("separation", 5)
	loading_plate.add_child(load_col)
	_status = Label.new()
	_status.theme_type_variation = &"Body"
	_status.add_theme_color_override("font_color", Tokens.TEXT_ON_DARK)
	load_col.add_child(_status)
	_progress = ProgressBar.new()
	_progress.custom_minimum_size = Vector2(0.0, 24.0)
	_progress.show_percentage = false
	var trough := StyleBoxFlat.new()
	trough.bg_color = Color("17110d")
	trough.border_color = Tokens.WALNUT
	trough.set_border_width_all(3)
	trough.set_corner_radius_all(3)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Tokens.SAGE
	fill.border_color = Tokens.GOLD_MUTED
	fill.set_border_width_all(2)
	fill.set_corner_radius_all(2)
	_progress.add_theme_stylebox_override("background", trough)
	_progress.add_theme_stylebox_override("fill", fill)
	load_col.add_child(_progress)


func _dark_plate_style(alpha: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(Tokens.WALNUT_DEEP, alpha)
	style.border_color = Color(Tokens.GOLD_MUTED, 0.88)
	style.set_border_width_all(3)
	style.set_corner_radius_all(7)
	style.shadow_color = Color(0.02, 0.01, 0.0, 0.62)
	style.shadow_size = 10
	return style


# Non-interactive interpretive Chart art. It deliberately shows the topology's
# rhythm without exposing exact tiles: pale side roads, the gold critical road,
# and role knots from entrance to deepest room.
class ChartSketch extends Control:
	var _layout: Dictionary = {}

	func set_layout(layout: Dictionary) -> void:
		_layout = layout.duplicate(true)
		queue_redraw()

	func _draw() -> void:
		if _layout.is_empty():
			return
		var rooms: Array = _layout.get("rooms", [])
		if rooms.is_empty():
			return
		draw_rect(Rect2(Vector2.ZERO, size), Color(Tokens.WALNUT_DEEP, 0.74), true)
		draw_rect(Rect2(Vector2(1, 1), size - Vector2(2, 2)),
			Color(Tokens.GOLD_MUTED, 0.64), false, 2.0)
		var centers := {}
		var min_p := Vector2(INF, INF)
		var max_p := Vector2(-INF, -INF)
		for room_v in rooms:
			if not room_v is Dictionary:
				continue
			var room := room_v as Dictionary
			var point := Vector2(float(room.get("x", 0)) + float(room.get("w", 1)) * 0.5,
				float(room.get("y", 0)) + float(room.get("h", 1)) * 0.5)
			centers[int(room.get("id", centers.size()))] = point
			min_p.x = minf(min_p.x, point.x)
			min_p.y = minf(min_p.y, point.y)
			max_p.x = maxf(max_p.x, point.x)
			max_p.y = maxf(max_p.y, point.y)
		var span := max_p - min_p
		span.x = maxf(span.x, 1.0)
		span.y = maxf(span.y, 1.0)
		var pad := Vector2(34, 26)
		var usable := size - pad * 2.0
		var plotted := {}
		for id_v in centers:
			var normalized: Vector2 = (centers[id_v] - min_p) / span
			plotted[id_v] = pad + normalized * usable
		var critical: Array = _layout.get("critical_room_ids", [])
		var critical_edges := {}
		for i in range(maxi(0, critical.size() - 1)):
			critical_edges[_edge_key(int(critical[i]), int(critical[i + 1]))] = true
		for edge_v in _layout.get("room_edges", []):
			if not edge_v is Array or (edge_v as Array).size() < 2:
				continue
			var a := int(edge_v[0])
			var b := int(edge_v[1])
			if not plotted.has(a) or not plotted.has(b):
				continue
			var on_road := critical_edges.has(_edge_key(a, b))
			draw_line(plotted[a], plotted[b],
				Color(Tokens.GOLD_MUTED, 0.96) if on_road \
				else Color(Tokens.TEXT_ON_DARK_DIM, 0.54),
				4.0 if on_road else 2.0, true)
		for room_v in rooms:
			if not room_v is Dictionary:
				continue
			var room := room_v as Dictionary
			var id := int(room.get("id", -1))
			if not plotted.has(id):
				continue
			var role := String(room.get("role", "combat"))
			var color := Tokens.TEXT_ON_DARK_DIM
			if role == "entrance":
				color = Tokens.SAGE
			elif role == "boss":
				color = Tokens.TERRACOTTA
			elif role in ["treasure", "shrine", "rest"]:
				color = Tokens.GOLD_MUTED
			var radius := 8.0 if role in ["entrance", "boss"] else 6.0
			draw_circle(plotted[id] + Vector2(2, 3), radius + 2.0,
				Color(0.02, 0.01, 0.0, 0.62))
			draw_circle(plotted[id], radius, color)
			draw_circle(plotted[id], maxf(2.0, radius - 3.0),
				Color(Tokens.WALNUT_DEEP, 0.82))

	func _edge_key(a: int, b: int) -> String:
		return "%d:%d" % [mini(a, b), maxi(a, b)]
