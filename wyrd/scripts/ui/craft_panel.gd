extends CanvasLayer

# Spec 59 — Cottage Hearth / Hod's Anvil transaction workbench. Recipes are a
# compact navigation rail; the selected work, materials, result, consequence,
# and stable primary action live on an authored station surface.

const CraftingDefs = preload("res://data/crafting.gd")
const GatherDefs = preload("res://data/gather.gd")
const ItemsData = preload("res://data/items.gd")
const Tokens = preload("res://scripts/ui/foundation/ui_tokens.gd")
const FocusPointer = preload("res://scripts/ui/components/focus_pointer.gd")
const JournalRow = preload("res://scripts/ui/components/journal_list_row.gd")
const IngredientWell = preload("res://scripts/ui/components/ingredient_well.gd")
const Workbench = preload("res://scripts/ui/components/transaction_workbench.gd")

const COPPER_POT := preload("res://assets/ui/field_journal/icons/copper_pot.png")
const ANVIL := preload("res://assets/ui/field_journal/icons/anvil_v1.png")

const OUTPUT_ART := {
	"hearth_draught": "res://assets/ui/field_journal/icons/hearth_draught.png",
	"quickroot_tonic": "res://assets/ui/field_journal/icons/quickroot_tonic.png",
}

const STATION_MAXIMS := {
	"cookfire": "Warm hands, sound provisions, a steadier road.",
	"forge": "Measure twice. Strike true. Carry the work yourself.",
}

var station_id := "cookfire"

var _game: Node
var _workbench: TransactionWorkbench
var _recipe_box: VBoxContainer
var _ingredient_flow: HBoxContainer
var _hero_icon: TextureRect
var _hero_glyph: Label
var _hero_title: Label
var _hero_desc: Label
var _outcome_label: Label
var _xp_label: Label
var _reason_label: Label
var _craft_button: Button
var _selected_recipe_id := ""
var _rows := {}
var _texture_cache := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 90
	_game = get_tree().root.get_node_or_null("Game")
	var station: Dictionary = CraftingDefs.station(station_id)

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
	_workbench.setup(String(station.get("title", "Crafting")),
		String(STATION_MAXIMS.get(station_id, "Good work makes a safer road.")),
		COPPER_POT if station_id == "cookfire" else ANVIL)

	var trade := String(station.get("trade", "wildcraft"))
	var trade_name := trade.capitalize()
	var trade_level := 1
	if _game != null:
		trade_name = String(_game.TRADE_NAMES.get(trade, trade_name))
		trade_level = _game.trade_lv(trade)
	_workbench.add_resource_text("%s  %d" % [trade_name, trade_level], Tokens.GOLD_MUTED.lightened(0.35))

	_build_recipe_leaf(_workbench.add_leaf("RecipeIndexLeaf", 0.34))
	_build_work_surface(_workbench.add_leaf("WorkSurfaceLeaf", 0.66))
	_workbench.add_footer_hint("↑↓ choose  ·  Enter work  ·  Esc close")
	if station_id == "cookfire":
		var loadout := Button.new()
		loadout.name = "ChangeSkillsButton"
		loadout.text = "Change skills"
		loadout.flat = true
		loadout.custom_minimum_size = Vector2(160.0, Tokens.HIT_TARGET)
		loadout.add_theme_color_override("font_color", Tokens.TEXT_ON_DARK_DIM)
		loadout.add_theme_color_override("font_hover_color", Tokens.TEXT_ON_DARK)
		loadout.add_theme_color_override("font_pressed_color", Tokens.GOLD_MUTED.lightened(0.3))
		loadout.pressed.connect(_open_loadout)
		_workbench.footer.add_child(loadout)

	get_node("/root/Game").modal_opened()
	_select_initial_recipe()
	_render_recipe_index()
	_render_detail()
	var focus_pointer := FocusPointer.new()
	focus_pointer.name = "TransactionFocusPointer"
	add_child(focus_pointer)
	_focus_selected_row.call_deferred()


func _build_recipe_leaf(leaf: VBoxContainer) -> void:
	var heading := Label.new()
	heading.text = "Recipe Book"
	heading.theme_type_variation = &"SectionTitle"
	leaf.add_child(heading)
	var instruction := Label.new()
	instruction.text = "Choose the work. The surface shows what it asks."
	instruction.theme_type_variation = &"RowSubtitle"
	instruction.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	leaf.add_child(instruction)
	var divider := HSeparator.new()
	leaf.add_child(divider)
	var scroll := ScrollContainer.new()
	scroll.name = "RecipeScroll"
	scroll.custom_minimum_size.y = 324.0
	scroll.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	leaf.add_child(scroll)
	_recipe_box = VBoxContainer.new()
	_recipe_box.name = "RecipeIndex"
	_recipe_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_recipe_box.add_theme_constant_override("separation", 6)
	scroll.add_child(_recipe_box)


func _build_work_surface(leaf: VBoxContainer) -> void:
	leaf.add_theme_constant_override("separation", 6)
	var heading := Label.new()
	heading.text = "At the Hearth" if station_id == "cookfire" else "On the Anvil"
	heading.theme_type_variation = &"SectionTitle"
	leaf.add_child(heading)

	var hero := HBoxContainer.new()
	hero.name = "SelectedRecipeHero"
	hero.custom_minimum_size.y = 96.0
	hero.add_theme_constant_override("separation", Tokens.SPACE_4)
	leaf.add_child(hero)
	var hero_well := PanelContainer.new()
	hero_well.theme_type_variation = &"ItemWell"
	hero_well.custom_minimum_size = Vector2(92.0, 92.0)
	hero.add_child(hero_well)
	var hero_center := CenterContainer.new()
	hero_well.add_child(hero_center)
	_hero_icon = TextureRect.new()
	_hero_icon.custom_minimum_size = Vector2(70.0, 70.0)
	_hero_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_hero_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hero_center.add_child(_hero_icon)
	_hero_glyph = Label.new()
	_hero_glyph.theme_type_variation = &"Display"
	_hero_glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hero_glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hero_center.add_child(_hero_glyph)
	var hero_copy := VBoxContainer.new()
	hero_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hero_copy.alignment = BoxContainer.ALIGNMENT_CENTER
	hero_copy.add_theme_constant_override("separation", Tokens.SPACE_1)
	hero.add_child(hero_copy)
	_hero_title = Label.new()
	_hero_title.theme_type_variation = &"PageTitle"
	_hero_title.add_theme_font_size_override("font_size", 26)
	hero_copy.add_child(_hero_title)
	_hero_desc = Label.new()
	_hero_desc.theme_type_variation = &"Body"
	_hero_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hero_desc.max_lines_visible = 3
	hero_copy.add_child(_hero_desc)
	var hero_outcome := HBoxContainer.new()
	hero_outcome.add_theme_constant_override("separation", Tokens.SPACE_4)
	hero_copy.add_child(hero_outcome)
	_outcome_label = Label.new()
	_outcome_label.theme_type_variation = &"Body"
	_outcome_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_outcome_label.add_theme_color_override("font_color", Tokens.SAGE.darkened(0.25))
	hero_outcome.add_child(_outcome_label)
	_xp_label = Label.new()
	_xp_label.theme_type_variation = &"Body"
	_xp_label.add_theme_color_override("font_color", Tokens.GOLD_MUTED.darkened(0.12))
	hero_outcome.add_child(_xp_label)

	var divider := HSeparator.new()
	leaf.add_child(divider)
	var flow_title := Label.new()
	flow_title.text = "Ingredients into the work"
	flow_title.theme_type_variation = &"SectionTitle"
	flow_title.add_theme_font_size_override("font_size", 18)
	leaf.add_child(flow_title)
	_ingredient_flow = HBoxContainer.new()
	_ingredient_flow.name = "IngredientFlow"
	_ingredient_flow.custom_minimum_size.y = 116.0
	_ingredient_flow.alignment = BoxContainer.ALIGNMENT_CENTER
	_ingredient_flow.add_theme_constant_override("separation", Tokens.SPACE_2)
	leaf.add_child(_ingredient_flow)

	_reason_label = Label.new()
	_reason_label.name = "CraftReason"
	_reason_label.theme_type_variation = &"Body"
	_reason_label.custom_minimum_size.y = 20.0
	_reason_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	leaf.add_child(_reason_label)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	leaf.add_child(spacer)
	_craft_button = Button.new()
	_craft_button.name = "PrimaryCraftAction"
	_craft_button.theme_type_variation = &"PrimaryButton"
	_craft_button.custom_minimum_size = Vector2(0.0, 56.0)
	_craft_button.pressed.connect(_craft_selected)
	leaf.add_child(_craft_button)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_close()


func _close() -> void:
	get_node("/root/Game").modal_closed()
	queue_free()


func _open_loadout() -> void:
	var panel: CanvasLayer = load("res://scripts/ui/loadout_panel.gd").new()
	var host := get_tree().current_scene
	if host == null:
		host = get_parent()
	host.add_child(panel)


func _select_initial_recipe() -> void:
	var station: Dictionary = CraftingDefs.station(station_id)
	var recipes: Array = station.get("recipes", [])
	if recipes.is_empty():
		_selected_recipe_id = ""
		return
	_selected_recipe_id = String(recipes[0])
	for recipe_id_v in recipes:
		var recipe_id := String(recipe_id_v)
		var recipe: Dictionary = CraftingDefs.recipe(recipe_id)
		if _recipe_available(recipe):
			_selected_recipe_id = recipe_id
			return


func _render_recipe_index() -> void:
	for child in _recipe_box.get_children():
		_recipe_box.remove_child(child)
		child.queue_free()
	_rows.clear()
	var station: Dictionary = CraftingDefs.station(station_id)
	for recipe_id_v in station.get("recipes", []):
		var recipe_id := String(recipe_id_v)
		var row := JournalRow.new()
		row.name = "Recipe_%s" % recipe_id
		row.custom_minimum_size.y = 64.0
		var selected := recipe_id == _selected_recipe_id
		row.setup(_recipe_row_model(recipe_id, selected))
		row.pressed.connect(_select_recipe.bind(recipe_id, true))
		row.focus_entered.connect(_select_recipe.bind(recipe_id, false))
		row.mouse_entered.connect(_select_recipe.bind(recipe_id, false))
		_recipe_box.add_child(row)
		_rows[recipe_id] = row


func _recipe_row_model(recipe_id: String, selected: bool) -> Dictionary:
	var recipe: Dictionary = CraftingDefs.recipe(recipe_id)
	var status := _recipe_status(recipe)
	var trailing := "●"
	var trailing_color := Tokens.SAGE.darkened(0.25)
	if status == "locked":
		trailing = "Lv %d" % int(recipe.get("req_lv", 1))
		trailing_color = Tokens.GOLD_MUTED.darkened(0.15)
	elif status == "missing":
		trailing = "•"
		trailing_color = Tokens.TERRACOTTA
	if selected and status == "ready":
		trailing = ""
	return {
		"title": String(recipe.get("name", recipe_id)),
		"subtitle": _recipe_kind_line(recipe),
		"trailing": trailing,
		"icon": _recipe_icon(recipe),
		"glyph": _recipe_glyph(recipe),
		"state": JournalRow.RowState.SELECTED if selected else JournalRow.RowState.NORMAL,
		"trailing_color": trailing_color,
		"tooltip": String(recipe.get("desc", "")),
		"density": "compact",
	}


func _select_recipe(recipe_id: String, grab_action: bool = false) -> void:
	if recipe_id == "" or not CraftingDefs.RECIPES.has(recipe_id):
		return
	_selected_recipe_id = recipe_id
	for id_v in _rows:
		var id := String(id_v)
		var row := _rows[id] as JournalListRow
		if row != null and not row.is_queued_for_deletion():
			row.setup(_recipe_row_model(id, id == recipe_id))
	_render_detail()
	if grab_action:
		_craft_button.grab_focus()


func _render_detail() -> void:
	if _selected_recipe_id == "":
		return
	var station: Dictionary = CraftingDefs.station(station_id)
	var recipe: Dictionary = CraftingDefs.recipe(_selected_recipe_id)
	_hero_icon.texture = _recipe_icon(recipe)
	_hero_icon.visible = _hero_icon.texture != null
	_hero_glyph.text = _recipe_glyph(recipe)
	_hero_glyph.visible = not _hero_icon.visible
	_hero_title.text = String(recipe.get("name", _selected_recipe_id))
	_hero_desc.text = String(recipe.get("desc", ""))
	for child in _ingredient_flow.get_children():
		_ingredient_flow.remove_child(child)
		child.queue_free()
	var input_count := (recipe.get("inputs", {}) as Dictionary).size()
	var well_width := 126.0 if input_count == 1 else (104.0 if input_count == 2 else 86.0)
	for material_id_v in recipe.get("inputs", {}):
		var material_id := String(material_id_v)
		_add_ingredient(material_id, int(recipe.inputs[material_id]), well_width)
		if input_count > 1:
			_add_flow_mark("+")
	if input_count > 1 and _ingredient_flow.get_child_count() > 0:
		var last := _ingredient_flow.get_child(_ingredient_flow.get_child_count() - 1)
		_ingredient_flow.remove_child(last)
		last.queue_free()
	_add_flow_mark("→")
	_add_station_focal()
	_add_flow_mark("→")
	var result := IngredientWell.new()
	result.setup({
		"id": "result",
		"name": "Result",
		"count": "Makes %d" % int(recipe.get("yields_n", 1)),
		"icon": _recipe_icon(recipe),
		"glyph": _recipe_glyph(recipe),
		"width": 104.0,
		"height": 110.0,
		"sufficient": true,
	})
	result.name = "ResultWell"
	_ingredient_flow.add_child(result)
	_outcome_label.text = "Makes %d · %s" % [int(recipe.get("yields_n", 1)),
		String(recipe.get("name", "result"))]
	_xp_label.text = "+%d XP" % int(recipe.get("xp", 0))
	var status := _recipe_status(recipe)
	_craft_button.text = "%s %s" % [String(station.get("verb", "Craft")),
		String(recipe.get("name", ""))]
	_craft_button.disabled = status != "ready"
	match status:
		"locked":
			var trade := String(station.get("trade", "wildcraft"))
			var trade_name := trade.capitalize() if _game == null \
				else String(_game.TRADE_NAMES.get(trade, trade.capitalize()))
			_reason_label.text = "Requires %s %d." % [trade_name,
				int(recipe.get("req_lv", 1))]
			_reason_label.add_theme_color_override("font_color", Tokens.TERRACOTTA)
		"missing":
			_reason_label.text = _missing_material_reason(recipe)
			_reason_label.add_theme_color_override("font_color", Tokens.TERRACOTTA)
		_:
			_reason_label.text = ""


func _add_ingredient(material_id: String, need: int, width: float) -> void:
	var have: int = 0 if _game == null else _game.material_count(material_id)
	var well := IngredientWell.new()
	well.setup({
		"id": material_id,
		"name": GatherDefs.material_name(material_id),
		"count": "Have %d\nNeed %d" % [have, need],
		"icon": _load_texture(GatherDefs.material_icon_path(material_id)),
		"glyph": GatherDefs.material_icon(material_id),
		"width": width,
		"sufficient": have >= need,
		"tooltip": "%s: have %d, need %d" % [GatherDefs.material_name(material_id), have, need],
	})
	_ingredient_flow.add_child(well)


func _add_flow_mark(mark: String) -> void:
	var label := Label.new()
	label.text = mark
	label.theme_type_variation = &"SectionTitle"
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Tokens.GOLD_MUTED)
	_ingredient_flow.add_child(label)


func _add_station_focal() -> void:
	var well := PanelContainer.new()
	well.name = "StationFocal"
	well.theme_type_variation = &"ItemWell"
	well.custom_minimum_size = Vector2(112.0, 112.0)
	_ingredient_flow.add_child(well)
	var center := CenterContainer.new()
	well.add_child(center)
	if station_id == "cookfire":
		var icon := TextureRect.new()
		icon.texture = COPPER_POT
		icon.custom_minimum_size = Vector2(88.0, 88.0)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		center.add_child(icon)
	else:
		var icon := TextureRect.new()
		icon.texture = ANVIL
		icon.custom_minimum_size = Vector2(88.0, 88.0)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		center.add_child(icon)


func _craft_selected() -> void:
	if _game == null or _selected_recipe_id == "":
		return
	if _game.craft(station_id, _selected_recipe_id):
		_render_recipe_index()
		_render_detail()
		_craft_button.grab_focus.call_deferred()


func _recipe_status(recipe: Dictionary) -> String:
	if _game == null:
		return "missing"
	var station: Dictionary = CraftingDefs.station(station_id)
	var trade := String(station.get("trade", "wildcraft"))
	if _game.trade_lv(trade) < int(recipe.get("req_lv", 1)):
		return "locked"
	if not _game.can_afford(recipe.get("inputs", {})):
		return "missing"
	return "ready"


func _recipe_available(recipe: Dictionary) -> bool:
	return _recipe_status(recipe) == "ready"


func _missing_material_reason(recipe: Dictionary) -> String:
	var missing: Array[String] = []
	for material_id_v in recipe.get("inputs", {}):
		var material_id := String(material_id_v)
		var need := int(recipe.inputs[material_id])
		var have: int = 0 if _game == null else _game.material_count(material_id)
		if have < need:
			missing.append("%s %d/%d" % [GatherDefs.material_name(material_id), have, need])
	return "Still needed: %s." % ", ".join(missing)


func _recipe_kind_line(recipe: Dictionary) -> String:
	if recipe.has("yields_material"):
		var name := String(recipe.get("name", ""))
		var material_id := String(recipe.get("yields_material", ""))
		if name.contains("Draught"):
			return "Draught · %s" % String(recipe.get("desc", "")).get_slice(".", 0)
		if name.contains("Tonic") or name.contains("Philter") \
				or name.contains("Cordial") or name.contains("Mend"):
			return "Tonic · %s" % String(recipe.get("desc", "")).get_slice(".", 0)
		if material_id.ends_with("_bar"):
			return "Metal bar · Earthcraft"
		if material_id in ["glimmerdust", "emberglass", "dewthread"]:
			return "Charm reagent · Earthcraft"
		return "Crafting material"
	var kind := String((recipe.get("yields_item", {}) as Dictionary).get("kind", ""))
	if kind.contains("bow"):
		return "Weapon · bow"
	if kind.contains("pickaxe") or kind.contains("axe"):
		return "Trade tool"
	if kind.contains("ring") or kind.contains("band"):
		return "Ring · enchanted"
	return "Armour · enchanted"


func _recipe_icon(recipe: Dictionary) -> Texture2D:
	var path := ""
	if recipe.has("yields_material"):
		var material_id := String(recipe.yields_material)
		path = GatherDefs.material_icon_path(material_id)
		if path == "":
			path = String(OUTPUT_ART.get(material_id, ""))
	else:
		var item := recipe.get("yields_item", {}) as Dictionary
		path = String(ItemsData.ICON_TEX.get(String(item.get("kind", "")), ""))
	return _load_texture(path)


func _recipe_glyph(recipe: Dictionary) -> String:
	if recipe.has("yields_material"):
		return GatherDefs.material_icon(String(recipe.yields_material))
	var kind := String((recipe.get("yields_item", {}) as Dictionary).get("kind", ""))
	if kind.contains("pickaxe") or kind.contains("axe"):
		return "⚒"
	if kind.contains("bow"):
		return "➳"
	if kind.contains("ring"):
		return "◎"
	return "▣"


func _load_texture(path: String) -> Texture2D:
	if path == "" or not ResourceLoader.exists(path):
		return null
	if not _texture_cache.has(path):
		_texture_cache[path] = load(path)
	return _texture_cache[path] as Texture2D


func _focus_selected_row() -> void:
	var row := _rows.get(_selected_recipe_id, null) as Button
	if row != null and not row.is_queued_for_deletion():
		row.grab_focus()
		return
	_craft_button.grab_focus()
