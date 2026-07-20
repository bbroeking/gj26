extends CanvasLayer

# Spec 59 — the Charm Table as a physical binding workbench: equipped gear
# rail → selected item and visible sockets → known charm library. Domain state
# remains owned by Game.bind_enchant / unbind_enchant / can_bind_enchant.

const ItemsData := preload("res://data/items.gd")
const EnchantDefs := preload("res://data/enchants.gd")
const GatherDefs := preload("res://data/gather.gd")
const Tokens = preload("res://scripts/ui/foundation/ui_tokens.gd")
const FocusPointer = preload("res://scripts/ui/components/focus_pointer.gd")
const JournalRow = preload("res://scripts/ui/components/journal_list_row.gd")
const CharmSocket = preload("res://scripts/ui/components/charm_socket.gd")
const Workbench = preload("res://scripts/ui/components/transaction_workbench.gd")

const CHARM_EMBLEM := preload("res://assets/ui/icons/charm_emberbind.png")
const REAGENTS := ["glimmerdust", "emberglass", "dewthread"]

var _game: Node
var _workbench: TransactionWorkbench
var _sel_item = null
var _selected_enchant_id := ""
var _gear_rows: VBoxContainer
var _charm_rows_box: VBoxContainer
var _socket_row: VBoxContainer
var _cost_row: HBoxContainer
var _item_icon: TextureRect
var _item_glyph: Label
var _item_title: Label
var _item_meta: Label
var _preview_title: Label
var _preview_effect: Label
var _reason_label: Label
var _bind_button: Button
var _resource_labels := {}
var _charm_rows := {}
var _icon_cache := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 95
	_game = get_tree().root.get_node_or_null("Game")
	for enchant_id_v in EnchantDefs.ENCHANT_ORDER:
		var enchant_id := String(enchant_id_v)
		var path := "res://assets/ui/icons/charm_%s.png" % enchant_id
		if ResourceLoader.exists(path):
			_icon_cache[enchant_id] = load(path)

	WyrdUi.make_backdrop(self, _close)
	_workbench = Workbench.new()
	_workbench.anchor_left = 0.5
	_workbench.anchor_top = 0.5
	_workbench.anchor_right = 0.5
	_workbench.anchor_bottom = 0.5
	_workbench.offset_left = -520.0
	_workbench.offset_top = -325.0
	_workbench.offset_right = 520.0
	_workbench.offset_bottom = 325.0
	_workbench.close_requested.connect(_close)
	add_child(_workbench)
	_workbench.setup("The Charm Table",
		"A virtue bound in iron travels where its bearer does.", CHARM_EMBLEM)
	for reagent in REAGENTS:
		var label := _workbench.add_resource_text("")
		_resource_labels[reagent] = label

	_build_gear_leaf(_workbench.add_leaf("GearRailLeaf", 0.26))
	_build_binding_surface(_workbench.add_leaf("BindingSurfaceLeaf", 0.39))
	_build_charm_leaf(_workbench.add_leaf("CharmLibraryLeaf", 0.35))
	_workbench.add_footer_hint("←→ move  ·  Enter choose  ·  Esc close")

	get_node("/root/Game").modal_opened()
	_select_default_item()
	_select_default_charm()
	_render()
	var focus_pointer := FocusPointer.new()
	focus_pointer.name = "TransactionFocusPointer"
	add_child(focus_pointer)
	_focus_first_gear.call_deferred()


func _build_gear_leaf(leaf: VBoxContainer) -> void:
	var heading := Label.new()
	heading.text = "Equipped Gear"
	heading.theme_type_variation = &"SectionTitle"
	leaf.add_child(heading)
	var hint := Label.new()
	hint.text = "Choose what will carry the charm."
	hint.theme_type_variation = &"RowSubtitle"
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	leaf.add_child(hint)
	leaf.add_child(HSeparator.new())
	var scroll := ScrollContainer.new()
	scroll.name = "GearScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	leaf.add_child(scroll)
	_gear_rows = VBoxContainer.new()
	_gear_rows.name = "GearRail"
	_gear_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_gear_rows.add_theme_constant_override("separation", 6)
	scroll.add_child(_gear_rows)


func _build_charm_leaf(leaf: VBoxContainer) -> void:
	var heading := Label.new()
	heading.text = "Known Charms"
	heading.theme_type_variation = &"SectionTitle"
	leaf.add_child(heading)
	var hint := Label.new()
	hint.text = "Choose a virtue to read at the surface."
	hint.theme_type_variation = &"RowSubtitle"
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	leaf.add_child(hint)
	leaf.add_child(HSeparator.new())
	var scroll := ScrollContainer.new()
	scroll.name = "CharmScroll"
	scroll.custom_minimum_size.y = 324.0
	scroll.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	leaf.add_child(scroll)
	_charm_rows_box = VBoxContainer.new()
	_charm_rows_box.name = "CharmLibrary"
	_charm_rows_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_charm_rows_box.add_theme_constant_override("separation", 6)
	scroll.add_child(_charm_rows_box)


func _build_binding_surface(leaf: VBoxContainer) -> void:
	leaf.add_theme_constant_override("separation", 5)
	var heading := Label.new()
	heading.text = "Binding Surface"
	heading.theme_type_variation = &"SectionTitle"
	leaf.add_child(heading)
	var hero := HBoxContainer.new()
	hero.name = "SelectedGearHero"
	hero.custom_minimum_size.y = 146.0
	hero.add_theme_constant_override("separation", Tokens.SPACE_2)
	leaf.add_child(hero)
	var item_display := VBoxContainer.new()
	item_display.name = "SelectedItemDisplay"
	item_display.custom_minimum_size.x = 112.0
	item_display.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item_display.alignment = BoxContainer.ALIGNMENT_CENTER
	item_display.add_theme_constant_override("separation", 0)
	hero.add_child(item_display)
	var item_center := CenterContainer.new()
	item_center.custom_minimum_size = Vector2(118.0, 108.0)
	item_display.add_child(item_center)
	_item_icon = TextureRect.new()
	_item_icon.name = "SelectedItemArt"
	_item_icon.custom_minimum_size = Vector2(112.0, 108.0)
	_item_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_item_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	item_center.add_child(_item_icon)
	_item_glyph = Label.new()
	_item_glyph.text = "◇"
	_item_glyph.theme_type_variation = &"SectionTitle"
	item_center.add_child(_item_glyph)
	_item_title = Label.new()
	_item_title.theme_type_variation = &"RowTitle"
	_item_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_item_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	item_display.add_child(_item_title)
	_item_meta = Label.new()
	_item_meta.theme_type_variation = &"RowSubtitle"
	_item_meta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item_display.add_child(_item_meta)

	_socket_row = VBoxContainer.new()
	_socket_row.name = "BindingSockets"
	_socket_row.custom_minimum_size = Vector2(192.0, 134.0)
	_socket_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_socket_row.add_theme_constant_override("separation", 6)
	hero.add_child(_socket_row)
	leaf.add_child(HSeparator.new())
	_preview_title = Label.new()
	_preview_title.theme_type_variation = &"SectionTitle"
	_preview_title.add_theme_font_size_override("font_size", 18)
	leaf.add_child(_preview_title)
	_preview_effect = Label.new()
	_preview_effect.theme_type_variation = &"Body"
	_preview_effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_preview_effect.max_lines_visible = 2
	_preview_effect.custom_minimum_size.y = 40.0
	leaf.add_child(_preview_effect)
	_cost_row = HBoxContainer.new()
	_cost_row.name = "ReagentCostStrips"
	_cost_row.custom_minimum_size.y = 48.0
	_cost_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_cost_row.add_theme_constant_override("separation", Tokens.SPACE_2)
	leaf.add_child(_cost_row)
	_reason_label = Label.new()
	_reason_label.name = "BindingReason"
	_reason_label.theme_type_variation = &"Body"
	_reason_label.custom_minimum_size.y = 20.0
	_reason_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_reason_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	leaf.add_child(_reason_label)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	leaf.add_child(spacer)
	_bind_button = Button.new()
	_bind_button.name = "PrimaryBindAction"
	_bind_button.theme_type_variation = &"PrimaryButton"
	_bind_button.custom_minimum_size = Vector2(0.0, 56.0)
	_bind_button.pressed.connect(_bind_selected)
	leaf.add_child(_bind_button)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_close()


func _close() -> void:
	get_node("/root/Game").modal_closed()
	queue_free()


func _select_default_item() -> void:
	_sel_item = null
	if _game == null or _game.equipment == null:
		return
	for slot in Equipment.SLOT_ORDER:
		var item = _game.equipment.get_slot(slot)
		if item != null and ItemsData.enchant_slots(String(item.get("kind_id", ""))) > 0:
			_sel_item = item
			return


func _select_default_charm() -> void:
	_selected_enchant_id = ""
	if _game == null or _sel_item == null:
		return
	var category := String(_sel_item.get("category", ""))
	for enchant_id_v in _game.known_enchant_ids():
		var enchant_id := String(enchant_id_v)
		if not EnchantDefs.allowed_for(enchant_id, category):
			continue
		if _selected_enchant_id == "":
			_selected_enchant_id = enchant_id
		if bool(_game.can_bind_enchant(_sel_item, enchant_id).get("ok", false)):
			_selected_enchant_id = enchant_id
			return


func _render() -> void:
	if _game == null:
		return
	_render_resources()
	_render_gear()
	_render_charms()
	_render_binding_surface()


func _render_resources() -> void:
	for reagent in REAGENTS:
		var label := _resource_labels.get(reagent, null) as Label
		if label != null:
			label.text = "%s %s %d" % [GatherDefs.material_icon(reagent),
				GatherDefs.material_name(reagent), _game.material_count(reagent)]


func _render_gear() -> void:
	for child in _gear_rows.get_children():
		_gear_rows.remove_child(child)
		child.queue_free()
	var any := false
	for slot in Equipment.SLOT_ORDER:
		var item = _game.equipment.get_slot(slot)
		if item == null:
			continue
		var capacity := ItemsData.enchant_slots(String(item.get("kind_id", "")))
		if capacity <= 0:
			continue
		any = true
		var used := (item.get("enchants", []) as Array).size()
		var selected: bool = item == _sel_item
		var row := JournalRow.new()
		row.name = "Gear_%s" % String(slot)
		row.setup({
			"title": String(item.get("name", item.get("kind_name", "Gear"))),
			"subtitle": "%s · %d/%d sockets" % [String(slot).capitalize(), used, capacity],
			"icon": _item_texture(item),
			"glyph": "◇",
			"state": JournalRow.RowState.SELECTED if selected else JournalRow.RowState.NORMAL,
			"density": "compact",
		})
		var item_ref = item
		row.pressed.connect(_select_item.bind(item_ref))
		_gear_rows.add_child(row)
	if not any:
		var empty := Label.new()
		empty.text = "No enchantable gear equipped."
		empty.theme_type_variation = &"Body"
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_gear_rows.add_child(empty)


func _render_charms() -> void:
	for child in _charm_rows_box.get_children():
		_charm_rows_box.remove_child(child)
		child.queue_free()
	_charm_rows.clear()
	if _sel_item == null:
		return
	var category := String(_sel_item.get("category", ""))
	for enchant_id_v in _game.known_enchant_ids():
		var enchant_id := String(enchant_id_v)
		if not EnchantDefs.allowed_for(enchant_id, category):
			continue
		var row := JournalRow.new()
		row.name = "Charm_%s" % enchant_id
		row.setup(_charm_row_model(enchant_id))
		row.pressed.connect(_select_charm.bind(enchant_id, true))
		row.focus_entered.connect(_select_charm.bind(enchant_id, false))
		row.mouse_entered.connect(_select_charm.bind(enchant_id, false))
		_charm_rows_box.add_child(row)
		_charm_rows[enchant_id] = row
	if _charm_rows.is_empty():
		var empty := Label.new()
		empty.text = "No known charms will take on this gear."
		empty.theme_type_variation = &"Body"
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_charm_rows_box.add_child(empty)


func _charm_row_model(enchant_id: String) -> Dictionary:
	var bound := (_sel_item.get("enchants", []) as Array).has(enchant_id)
	var check: Dictionary = _game.can_bind_enchant(_sel_item, enchant_id)
	var selected := enchant_id == _selected_enchant_id
	var trailing := "Bound" if bound else ("✓" if bool(check.get("ok", false)) else "•")
	var trailing_color := Tokens.GOLD_MUTED.darkened(0.1) if bound \
		else (Tokens.SAGE.darkened(0.25) if bool(check.get("ok", false)) else Tokens.TERRACOTTA)
	return {
		"title": EnchantDefs.display_name(enchant_id),
		"subtitle": _charm_short_line(enchant_id),
		"trailing": "" if selected and not bound else trailing,
		"icon": _charm_icon(enchant_id),
		"glyph": "✦",
		"state": JournalRow.RowState.SELECTED if selected else JournalRow.RowState.NORMAL,
		"trailing_color": trailing_color,
		"tooltip": EnchantDefs.format_enchant(enchant_id),
		"density": "compact",
	}


func _select_item(item) -> void:
	_sel_item = item
	_select_default_charm()
	_render_gear()
	_render_charms()
	_render_binding_surface()


func _select_charm(enchant_id: String, grab_action: bool = false) -> void:
	if enchant_id == "" or not EnchantDefs.exists(enchant_id):
		return
	_selected_enchant_id = enchant_id
	for id_v in _charm_rows:
		var id := String(id_v)
		var row := _charm_rows[id] as JournalListRow
		if row != null and not row.is_queued_for_deletion():
			row.setup(_charm_row_model(id))
	_render_binding_surface()
	if grab_action and not _bind_button.disabled:
		_bind_button.grab_focus()


func _render_binding_surface() -> void:
	for child in _socket_row.get_children():
		_socket_row.remove_child(child)
		child.queue_free()
	for child in _cost_row.get_children():
		_cost_row.remove_child(child)
		child.queue_free()
	if _sel_item == null:
		_item_title.text = "No gear selected"
		_item_meta.text = "Equip a bow, armour, or ring to begin."
		_item_icon.texture = null
		_item_icon.visible = false
		_item_glyph.visible = true
		_preview_title.text = ""
		_preview_effect.text = ""
		_reason_label.text = ""
		_bind_button.text = "Bind Charm"
		_bind_button.disabled = true
		return
	_item_icon.texture = _item_texture(_sel_item)
	_item_icon.visible = _item_icon.texture != null
	_item_glyph.visible = not _item_icon.visible
	_item_title.text = String(_sel_item.get("name", _sel_item.get("kind_name", "Gear")))
	var capacity := ItemsData.enchant_slots(String(_sel_item.get("kind_id", "")))
	var current: Array = _sel_item.get("enchants", [])
	_item_meta.text = "%s · %d/%d charm sockets" % [
		String(_sel_item.get("category", "Gear")).capitalize(), current.size(), capacity]
	for index in range(capacity):
		var socket := CharmSocket.new()
		if index < current.size():
			var enchant_id := String(current[index])
			socket.setup({
				"index": index,
				"title": "Bound: %s" % EnchantDefs.display_name(enchant_id),
				"status": "Draw out",
				"icon": _charm_icon(enchant_id),
				"glyph": "✦",
				"tooltip": "%s\nPress to draw this charm out." % EnchantDefs.format_enchant(enchant_id),
			})
			socket.pressed.connect(_unbind_socket.bind(index))
		else:
			socket.setup({"index": index, "title": "Empty socket", "status": "Available", "glyph": "◇"})
			socket.focus_mode = Control.FOCUS_NONE
			socket.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_socket_row.add_child(socket)
	if _selected_enchant_id == "":
		_preview_title.text = "Choose a known charm"
		_preview_effect.text = "Its effect and cost will be read here."
		_reason_label.text = ""
		_bind_button.text = "Bind Charm"
		_bind_button.disabled = true
		return
	_preview_title.text = EnchantDefs.display_name(_selected_enchant_id)
	_preview_effect.text = EnchantDefs.format_enchant(_selected_enchant_id)
	for reagent_v in EnchantDefs.cost(_selected_enchant_id):
		var reagent := String(reagent_v)
		var need := int(EnchantDefs.cost(_selected_enchant_id)[reagent])
		var have: int = _game.material_count(reagent)
		_cost_row.add_child(_make_cost_strip(reagent, have, need))
	var check: Dictionary = _game.can_bind_enchant(_sel_item, _selected_enchant_id)
	var can_bind := bool(check.get("ok", false))
	_bind_button.text = "Bind %s" % EnchantDefs.display_name(_selected_enchant_id)
	_bind_button.disabled = not can_bind
	_reason_label.text = "" if can_bind else String(check.get("reason", "Unavailable"))
	_reason_label.add_theme_color_override("font_color", Tokens.TERRACOTTA)


func _bind_selected() -> void:
	if _game == null or _sel_item == null or _selected_enchant_id == "":
		return
	if _game.bind_enchant(_sel_item, _selected_enchant_id):
		_render_resources()
		_render_charms()
		_render_binding_surface()
		_focus_first_gear.call_deferred()


func _unbind_socket(index: int) -> void:
	if _game != null and _sel_item != null and _game.unbind_enchant(_sel_item, index):
		_render_resources()
		_render_charms()
		_render_binding_surface()
		_focus_first_gear.call_deferred()


func _focus_first_gear() -> void:
	for child in _gear_rows.get_children():
		if child is Button and not child.is_queued_for_deletion():
			(child as Button).grab_focus()
			return
	for child in _charm_rows_box.get_children():
		if child is Button and not child.is_queued_for_deletion():
			(child as Button).grab_focus()
			return


func _charm_kind_label(enchant_id: String) -> String:
	match EnchantDefs.kind(enchant_id):
		"on_hit": return "On hit"
		"skill_grant": return "Skill"
		_: return "Stat"


func _charm_short_line(enchant_id: String) -> String:
	match EnchantDefs.kind(enchant_id):
		"on_hit":
			var effect := EnchantDefs.format_enchant(enchant_id).to_lower()
			if effect.contains("burn"): return "Burn on hit"
			if effect.contains("bleed"): return "Bleed on hit"
			if effect.contains("snare"): return "Snare on hit"
			return "Effect on hit"
		"skill_grant": return "Grants a field skill"
		_: return EnchantDefs.format_enchant(enchant_id)


func _make_cost_strip(reagent: String, have: int, need: int) -> PanelContainer:
	var strip := PanelContainer.new()
	strip.name = "CostStrip_%s" % reagent
	strip.theme_type_variation = &"PaperSurface"
	strip.custom_minimum_size = Vector2(172.0, 48.0)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 4)
	strip.add_child(margin)
	var content := HBoxContainer.new()
	content.add_theme_constant_override("separation", 7)
	margin.add_child(content)
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(30.0, 30.0)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = _load_texture(GatherDefs.material_icon_path(reagent))
	content.add_child(icon)
	if icon.texture == null:
		var glyph := Label.new()
		glyph.text = GatherDefs.material_icon(reagent)
		glyph.theme_type_variation = &"RowTitle"
		glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		glyph.custom_minimum_size = Vector2(30.0, 30.0)
		content.add_child(glyph)
		icon.visible = false
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.alignment = BoxContainer.ALIGNMENT_CENTER
	copy.add_theme_constant_override("separation", 0)
	content.add_child(copy)
	var title := Label.new()
	title.text = GatherDefs.material_name(reagent)
	title.theme_type_variation = &"RowTitle"
	title.add_theme_font_size_override("font_size", 14)
	copy.add_child(title)
	var count := Label.new()
	count.text = "Have %d · Need %d" % [have, need]
	count.theme_type_variation = &"RowSubtitle"
	count.add_theme_font_size_override("font_size", 14)
	if have < need:
		count.add_theme_color_override("font_color", Tokens.TERRACOTTA)
	copy.add_child(count)
	return strip


func _charm_icon(enchant_id: String) -> Texture2D:
	return _icon_cache.get(enchant_id, null) as Texture2D


func _item_texture(item: Dictionary) -> Texture2D:
	var path := String(ItemsData.ICON_TEX.get(String(item.get("kind_id", "")), ""))
	return _load_texture(path)


func _load_texture(path: String) -> Texture2D:
	if path == "" or not ResourceLoader.exists(path):
		return null
	if not _icon_cache.has(path):
		_icon_cache[path] = load(path)
	return _icon_cache[path] as Texture2D
