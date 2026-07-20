extends Control

# Spec 59 — Field Journal Pack. The previous 1,244-line custom canvas manually
# drew tabs, rows, scroll masks, tooltips, and hit rectangles. This replacement
# keeps the Inventory/Equipment data contracts and public open methods while
# using semantic Controls, Containers, focus, and real scrolling.

const Affixes = preload("res://data/affixes.gd")
const ChartsData = preload("res://data/charts.gd")
const GatherDefs = preload("res://data/gather.gd")
const ItemsData = preload("res://data/items.gd")
const Progression = preload("res://data/progression.gd")
const Tokens = preload("res://scripts/ui/foundation/ui_tokens.gd")
const FocusPointer = preload("res://scripts/ui/components/focus_pointer.gd")
const JournalRow = preload("res://scripts/ui/components/journal_list_row.gd")
const FIELD_THEME := preload("res://themes/wayfinder_theme.tres")

const TABS := ["Gear", "Satchel", "Charts", "Trades"]
const EQUIP_ORDER := ["helmet", "chest", "weapon", "ring", "boots", "pickaxe", "axe"]

var inventory: Inventory
var equipment: Equipment

var _tab := 0
var _modal_on := false
var _shell: PanelContainer
var _title: Label
var _tabs: HBoxContainer
var _tab_buttons: Array[Button] = []
var _content: MarginContainer
var _footer: Label


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = FIELD_THEME
	_build_ui()
	get_viewport().size_changed.connect(_layout_shell)
	_layout_shell()


func set_inventory(value: Inventory) -> void:
	inventory = value
	_refresh()


func set_equipment(value: Equipment) -> void:
	if equipment != null and equipment.changed.is_connected(_on_equipment_changed):
		equipment.changed.disconnect(_on_equipment_changed)
	equipment = value
	if equipment != null and not equipment.changed.is_connected(_on_equipment_changed):
		equipment.changed.connect(_on_equipment_changed)
	_refresh()


func toggle() -> void:
	open_tab(0)


func open_tab(next_tab: int) -> void:
	var safe_tab := clampi(next_tab, 0, TABS.size() - 1)
	if visible and _tab == safe_tab:
		_set_open(false)
	else:
		_tab = safe_tab
		_set_open(true)
		_refresh()
		_focus_selected_tab.call_deferred()


func _set_open(opened: bool) -> void:
	if opened == _modal_on:
		visible = opened
		return
	var game := get_node_or_null("/root/Game")
	if opened:
		if game != null:
			game.modal_opened()
	else:
		if game != null:
			game.modal_closed()
	_modal_on = opened
	visible = opened


func _close_pack() -> void:
	if visible:
		_set_open(false)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		_close_pack()
		get_viewport().set_input_as_handled()


func _build_ui() -> void:
	var backdrop := ColorRect.new()
	backdrop.name = "PackBackdrop"
	backdrop.color = Tokens.SCRIM
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	backdrop.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed \
				and event.button_index == MOUSE_BUTTON_LEFT:
			_close_pack())
	add_child(backdrop)

	_shell = PanelContainer.new()
	_shell.name = "PackShell"
	_shell.theme_type_variation = &"JournalFrameContainer"
	_shell.anchor_left = 0.5
	_shell.anchor_right = 0.5
	_shell.anchor_top = 0.5
	_shell.anchor_bottom = 0.5
	add_child(_shell)

	var paper := PanelContainer.new()
	paper.theme_type_variation = &"PaperSurface"
	_shell.add_child(paper)
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", Tokens.SPACE_3)
	paper.add_child(page)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", Tokens.SPACE_3)
	page.add_child(header)
	_title = Label.new()
	_title.name = "PackTitle"
	_title.text = "Adventurer's Pack"
	_title.theme_type_variation = &"PageTitle"
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_title)
	var close := Button.new()
	close.name = "CloseButton"
	close.text = "Close  ×"
	close.theme_type_variation = &"SecondaryButton"
	close.custom_minimum_size = Vector2(112, Tokens.HIT_TARGET)
	close.pressed.connect(_close_pack)
	header.add_child(close)

	_tabs = HBoxContainer.new()
	_tabs.name = "PackTabs"
	_tabs.add_theme_constant_override("separation", Tokens.SPACE_2)
	page.add_child(_tabs)
	var group := ButtonGroup.new()
	for i in TABS.size():
		var button := Button.new()
		button.name = "%sTab" % TABS[i]
		button.text = TABS[i]
		button.theme_type_variation = &"TabButton"
		button.toggle_mode = true
		button.button_group = group
		button.custom_minimum_size = Vector2(0, Tokens.HIT_TARGET)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_select_tab.bind(i))
		_tabs.add_child(button)
		_tab_buttons.append(button)

	var divider := HSeparator.new()
	page.add_child(divider)
	_content = MarginContainer.new()
	_content.name = "PackContent"
	_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(_content)

	var footer_row := HBoxContainer.new()
	page.add_child(footer_row)
	_footer = Label.new()
	_footer.name = "PackFooter"
	_footer.theme_type_variation = &"Caption"
	_footer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer_row.add_child(_footer)
	var hint := Label.new()
	hint.text = "Esc / I — close"
	hint.theme_type_variation = &"Caption"
	footer_row.add_child(hint)

	var focus_pointer := FocusPointer.new()
	focus_pointer.name = "PackFocusPointer"
	add_child(focus_pointer)


func _layout_shell() -> void:
	if _shell == null:
		return
	var max_size := Tokens.modal_max_size(get_viewport_rect().size)
	var width := minf(1120.0, max_size.x)
	var height := minf(640.0, max_size.y)
	_shell.offset_left = -width * 0.5
	_shell.offset_right = width * 0.5
	_shell.offset_top = -height * 0.5
	_shell.offset_bottom = height * 0.5


func _select_tab(index: int) -> void:
	_tab = clampi(index, 0, TABS.size() - 1)
	_refresh()


func _focus_selected_tab() -> void:
	if _tab >= 0 and _tab < _tab_buttons.size():
		_tab_buttons[_tab].grab_focus()


func _refresh() -> void:
	if _content == null:
		return
	for child in _content.get_children():
		child.free()
	for i in _tab_buttons.size():
		_tab_buttons[i].button_pressed = i == _tab
	match _tab:
		0: _build_gear_page()
		1: _build_satchel_page()
		2: _build_charts_page()
		3: _build_trades_page()
	var game := get_node_or_null("/root/Game")
	_footer.text = "%d gold" % int(game.gold) if game != null else ""


func _build_gear_page() -> void:
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", Tokens.SPACE_4)
	_content.add_child(columns)

	var equipped_shell := PanelContainer.new()
	equipped_shell.theme_type_variation = &"PaperRaised"
	equipped_shell.custom_minimum_size.x = 330
	equipped_shell.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_child(equipped_shell)
	var equipped_col := VBoxContainer.new()
	equipped_col.add_theme_constant_override("separation", Tokens.SPACE_2)
	equipped_shell.add_child(equipped_col)
	equipped_col.add_child(_section_title("Equipped"))
	var equipped_scroll := ScrollContainer.new()
	equipped_scroll.name = "EquipmentScroll"
	equipped_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	equipped_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	equipped_col.add_child(equipped_scroll)
	var equipped_list := VBoxContainer.new()
	equipped_list.add_theme_constant_override("separation", Tokens.SPACE_2)
	equipped_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	equipped_scroll.add_child(equipped_list)
	for slot in EQUIP_ORDER:
		var item = equipment.get_slot(slot) if equipment != null else null
		var row := JournalRow.new()
		row.name = "%sEquipmentSlot" % String(slot).capitalize()
		row.setup({
			"title": String(slot).capitalize(),
			"subtitle": String(item.get("name", "")) if item != null else "Empty",
			"trailing": "Unequip" if item != null else "",
			"trailing_color": Tokens.SAGE.darkened(0.2),
			"icon": _item_icon(item) if item != null else null,
			"state": JournalRow.RowState.DISABLED if item == null \
				else JournalRow.RowState.NORMAL,
			"tooltip": "Unequip %s" % String(item.get("name", "")) \
				if item != null else "No %s equipped" % slot,
		})
		if item != null:
			row.pressed.connect(_quick_unequip.bind(String(slot)))
		equipped_list.add_child(row)

	var pack_shell := PanelContainer.new()
	pack_shell.theme_type_variation = &"PaperRaised"
	pack_shell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pack_shell.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_child(pack_shell)
	var pack_col := VBoxContainer.new()
	pack_col.add_theme_constant_override("separation", Tokens.SPACE_2)
	pack_shell.add_child(pack_col)
	var count := inventory.items.size() if inventory != null else 0
	pack_col.add_child(_section_title("Backpack · %d items" % count))
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pack_col.add_child(scroll)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", Tokens.SPACE_2)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	if inventory == null or inventory.items.is_empty():
		list.add_child(_empty_state("Your pack is empty.",
			"Gear and tools you find will wait here."))
		return
	for item in inventory.items:
		var row := JournalRow.new()
		row.setup({
			"title": String(item.get("name", "Item")),
			"subtitle": "%s %s" % [String(item.get("rarity", "normal")).capitalize(),
				String(item.get("category", "gear")).capitalize()],
			"trailing": "Equip",
			"icon": _item_icon(item),
			"state": JournalRow.RowState.DISABLED \
				if equipment == null or not equipment.can_equip(item) \
				else JournalRow.RowState.NORMAL,
			"tooltip": _item_tooltip(item),
			"trailing_color": Tokens.SAGE.darkened(0.2),
		})
		row.pressed.connect(_quick_equip.bind(item))
		list.add_child(row)


func _build_satchel_page() -> void:
	var root := _scrolling_page("Satchel", "Gathered supplies and charting materials.")
	var list := root.list as VBoxContainer
	var game := get_node_or_null("/root/Game")
	if game == null or (game.materials as Dictionary).is_empty():
		list.add_child(_empty_state("The satchel is empty.",
			"The yard's herb patches regrow — start there."))
		return
	for id in game.materials:
		var definition: Dictionary = GatherDefs.MATERIALS.get(String(id), {})
		var card := PanelContainer.new()
		card.theme_type_variation = &"PaperRaised"
		card.custom_minimum_size.y = 64
		var row := VBoxContainer.new()
		card.add_child(row)
		var title := Label.new()
		title.theme_type_variation = &"Body"
		title.text = "%s  ×%d" % [String(definition.get("name", id)),
			int(game.materials[id])]
		row.add_child(title)
		var desc := Label.new()
		desc.theme_type_variation = &"Caption"
		desc.text = String(definition.get("desc", ""))
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(desc)
		list.add_child(card)


func _build_charts_page() -> void:
	var root := _scrolling_page("Charts", "Finished roads waiting in your Chart Case.")
	var list := root.list as VBoxContainer
	var game := get_node_or_null("/root/Game")
	if game == null or (game.charts as Array).is_empty():
		list.add_child(_empty_state("No Charts inscribed.",
			"Mara's Chart Table awaits your first clear mark."))
		return
	for chart in game.charts:
		var card := PanelContainer.new()
		card.theme_type_variation = &"PaperRaised"
		var col := VBoxContainer.new()
		card.add_child(col)
		var title := Label.new()
		title.theme_type_variation = &"SectionTitle"
		title.text = ChartsData.chart_label(chart)
		col.add_child(title)
		for affix in chart.get("affixes", []):
			var definition: Dictionary = ChartsData.AFFIXES.get(String(affix.get("id", "")), {})
			if definition.is_empty():
				continue
			var good := bool(affix.get("good", false))
			var line := Label.new()
			line.theme_type_variation = &"Body"
			line.text = ("✓ " + String(definition.name)) if good \
				else ("✕ " + String(definition.bad_name))
			line.add_theme_color_override("font_color", Tokens.SAGE.darkened(0.22) \
				if good else Tokens.TERRACOTTA)
			col.add_child(line)
		list.add_child(card)


func _build_trades_page() -> void:
	var root := _scrolling_page("Trades", "Your four working disciplines, level 1–23.")
	var list := root.list as VBoxContainer
	var game := get_node_or_null("/root/Game")
	if game == null:
		return
	for key in ["wayfinding", "earthcraft", "wildcraft", "huntcraft"]:
		var level: int = game.trade_lv(key)
		var xp: int = int(game.trades[key].xp)
		var cap: int = int(game.LEVEL_CAP)
		var next_xp: int = game.xp_for_level(mini(level + 1, cap))
		var card := PanelContainer.new()
		card.theme_type_variation = &"PaperRaised"
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", Tokens.SPACE_2)
		card.add_child(col)
		var heading := HBoxContainer.new()
		col.add_child(heading)
		var name := Label.new()
		name.theme_type_variation = &"SectionTitle"
		name.text = String(Progression.TRADE_NAMES.get(key, key.capitalize()))
		name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		heading.add_child(name)
		var lv := Label.new()
		lv.theme_type_variation = &"Numeric"
		lv.text = "Level %d" % level
		heading.add_child(lv)
		var meter := ProgressBar.new()
		meter.show_percentage = false
		meter.min_value = 0
		meter.max_value = max(1, next_xp)
		meter.value = min(xp, next_xp)
		meter.custom_minimum_size.y = 18
		col.add_child(meter)
		var progress := Label.new()
		progress.theme_type_variation = &"Caption"
		progress.text = "Mastered" if level >= cap else "%d / %d XP" % [xp, next_xp]
		col.add_child(progress)
		var next_unlock: Dictionary = Progression.unlock_for_trade_level(key,
			mini(level + 1, cap))
		var next_line := Label.new()
		next_line.theme_type_variation = &"Body"
		next_line.text = "Next: %s" % String(next_unlock.get("label", "Mastery"))
		col.add_child(next_line)
		list.add_child(card)


func _scrolling_page(title_text: String, subtitle_text: String) -> Dictionary:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", Tokens.SPACE_2)
	_content.add_child(col)
	col.add_child(_section_title(title_text))
	var subtitle := Label.new()
	subtitle.theme_type_variation = &"Body"
	subtitle.text = subtitle_text
	col.add_child(subtitle)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(scroll)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", Tokens.SPACE_3)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	return {"root": col, "list": list}


func _section_title(text: String) -> Label:
	var label := Label.new()
	label.theme_type_variation = &"SectionTitle"
	label.text = text
	return label


func _empty_state(title_text: String, body_text: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.theme_type_variation = &"PaperRaised"
	panel.custom_minimum_size.y = 120
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(col)
	var title := Label.new()
	title.theme_type_variation = &"SectionTitle"
	title.text = title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)
	var body := Label.new()
	body.theme_type_variation = &"Body"
	body.text = body_text
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(body)
	return panel


func _item_icon(item: Dictionary) -> Texture2D:
	var icon_path := String(ItemsData.ICON_TEX.get(String(item.get("kind_id", "")), ""))
	return load(icon_path) as Texture2D if ResourceLoader.exists(icon_path) else null


func _item_tooltip(item: Dictionary) -> String:
	var lines := [String(item.get("name", "Item"))]
	var stat := String(item.get("base_stat", ""))
	if stat != "":
		lines.append("%s: %.1f" % [stat.capitalize(), float(item.get("base_value", 0))])
	for affix in item.get("affixes", []):
		lines.append(Affixes.format_affix(affix))
	return "\n".join(lines)


func _quick_equip(item: Dictionary) -> void:
	if equipment == null or inventory == null or not equipment.can_equip(item):
		return
	var slot := String(item.category)
	var previous = equipment.get_slot(slot)
	var original_pos: Vector2i = item.get("pos", Vector2i.ZERO)
	var original_rotated := bool(item.get("rotated", false))
	inventory.remove(item)
	if previous != null:
		var fit := inventory.find_first_fit(previous)
		if fit.is_empty():
			inventory.try_place(item, original_pos, original_rotated)
			return
		equipment.equip(item)
		inventory.try_place(previous, fit.pos, fit.rotated)
	else:
		equipment.equip(item)
	# Equipment emits synchronously. Rebuild after the pressed callback returns so
	# the button delivering this action is never freed mid-signal.
	_refresh.call_deferred()


func _quick_unequip(slot: String) -> void:
	if equipment == null or inventory == null:
		return
	var item = equipment.get_slot(slot)
	if item == null:
		return
	var fit := inventory.find_first_fit(item)
	if fit.is_empty():
		return
	equipment.unequip(slot)
	inventory.try_place(item, fit.pos, fit.rotated)
	_refresh.call_deferred()


func _on_equipment_changed() -> void:
	if visible:
		_refresh.call_deferred()
