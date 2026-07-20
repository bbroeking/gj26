extends SceneTree

# Spec 59 — every workstation follows the same transaction contract: paper
# shell, semantic Buttons, 48px targets, initial focus, and a non-color pointer.

const Charts = preload("res://data/charts.gd")
const Items = preload("res://data/items.gd")
const Tokens = preload("res://scripts/ui/foundation/ui_tokens.gd")
const JournalRow = preload("res://scripts/ui/components/journal_list_row.gd")
const CharmSocketScript = preload("res://scripts/ui/components/charm_socket.gd")
const LoadoutSlotScript = preload("res://scripts/ui/components/loadout_slot.gd")
const LoadoutChoiceScript = preload("res://scripts/ui/components/loadout_choice_row.gd")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
	else:
		_failures.append(message)
		push_error("FAIL: %s" % message)


func _frames(count: int = 3) -> void:
	for _frame in range(count):
		await process_frame


func _exercise(host: Node, path: String, label: String, configure := Callable()) -> void:
	var script := load(path) as Script
	var panel: Node = script.new()
	if configure.is_valid():
		configure.call(panel)
	host.add_child(panel)
	await _frames(4)
	var shell := panel.find_child("TransactionShell", true, false) as Control
	_check(shell != null, "%s uses the shared transaction shell" % label)
	if shell != null:
		var viewport_size := root.get_viewport().get_visible_rect().size
		_check(shell.size.x <= viewport_size.x and shell.size.y <= viewport_size.y,
			"%s stays wholly within the viewport" % label)
	var buttons := panel.find_children("*", "Button", true, false)
	var has_action := false
	var targets_ok := true
	for child in buttons:
		var button := child as Button
		if button.name != "CloseButton":
			has_action = true
			targets_ok = targets_ok and maxf(button.size.y,
				button.custom_minimum_size.y) >= Tokens.HIT_TARGET
	_check(has_action, "%s exposes its workflow as semantic Buttons" % label)
	_check(targets_ok, "%s action targets meet the 48px floor" % label)
	_check(panel.find_child("TransactionFocusPointer", true, false) != null,
		"%s includes the shared non-color focus pointer" % label)
	if label == "Vendor":
		var journal_rows: Array[Button] = []
		for child in buttons:
			var button := child as Button
			if button != null and button.get_script() == JournalRow:
				journal_rows.append(button)
		_check(not journal_rows.is_empty(),
			"Vendor composes wares from the shared JournalListRow")
		for row in journal_rows:
			_check(row.find_child("Title", true, false) is Label,
				"Vendor row exposes semantic title hierarchy")
			_check(row.find_child("IconWell", true, false) is PanelContainer,
				"Vendor row exposes the shared painted icon well")
		var wares_scroll := panel.find_child("WaresScroll", true, false) as ScrollContainer
		var wares_list := panel.find_child("WaresList", true, false) as VBoxContainer
		_check(wares_scroll != null and wares_list != null \
				and wares_list.get_child_count() >= 7,
			"level-8 Vendor keeps the full wares catalogue inside a scroll view")
		var gold_chip := panel.find_child("GoldChip", true, false) as Control
		var close_button := panel.find_child("CloseButton", true, false) as Control
		_check(gold_chip != null and close_button != null \
				and not gold_chip.get_global_rect().intersects(close_button.get_global_rect()),
			"Vendor header keeps currency and close affordances separate")
		var purchase: Button = null
		for row in journal_rows:
			if not row.disabled and not row.is_queued_for_deletion():
				purchase = row
				break
		var game := root.get_node("Game")
		var gold_before := int(game.gold)
		if purchase != null:
			purchase.pressed.emit()
			await _frames(4)
		_check(int(game.gold) < gold_before,
			"Vendor shared row preserves one-press purchase behavior")
		var refreshed_focus := root.gui_get_focus_owner()
		_check(refreshed_focus != null and panel.is_ancestor_of(refreshed_focus) \
				and not refreshed_focus.is_queued_for_deletion(),
			"Vendor purchase restores focus to a live replacement row")
	if label in ["Cookfire", "Forge"]:
		var recipe_leaf := panel.find_child("RecipeIndexLeaf", true, false) as PanelContainer
		var work_leaf := panel.find_child("WorkSurfaceLeaf", true, false) as PanelContainer
		_check(panel.find_child("WorkbenchWalnutMat", true, false) is PanelContainer,
			"%s uses walnut as structural space between paper leaves" % label)
		_check(recipe_leaf != null and work_leaf != null \
				and work_leaf.size.x > recipe_leaf.size.x,
			"%s uses the authored 34/66 recipe-to-work surface composition" % label)
		_check(panel.find_child("IngredientFlow", true, false) is HBoxContainer \
				and panel.find_child("StationFocal", true, false) is PanelContainer \
				and panel.find_child("ResultWell", true, false) is IngredientWell,
			"%s embodies material to station to result flow" % label)
		var recipe_rows := 0
		for child in buttons:
			if (child as Button).get_script() == JournalRow:
				recipe_rows += 1
		_check(recipe_rows >= 3,
			"%s keeps recipe navigation in compact shared rows" % label)
		var primary := panel.find_child("PrimaryCraftAction", true, false) as Button
		_check(primary != null and primary.size.y >= 56.0,
			"%s anchors one dominant station action" % label)
		_check(panel.find_child("Satchel", true, false) == null,
			"%s removes the raw serialized Satchel block" % label)
		if label == "Cookfire" and primary != null and not primary.disabled:
			var game := root.get_node("Game")
			var herb_before: int = game.material_count("wild_herb")
			var draught_before: int = game.material_count("hearth_draught")
			primary.pressed.emit()
			await _frames(4)
			_check(game.material_count("wild_herb") < herb_before \
					and game.material_count("hearth_draught") > draught_before,
				"Cookfire work surface preserves the real craft transaction")
			var craft_focus := root.gui_get_focus_owner()
			_check(craft_focus != null and panel.is_ancestor_of(craft_focus) \
					and not craft_focus.is_queued_for_deletion(),
				"Cookfire craft restores focus to a live workstation control")
	if label == "Charm Table":
		var gear_leaf := panel.find_child("GearRailLeaf", true, false) as PanelContainer
		var binding_leaf := panel.find_child("BindingSurfaceLeaf", true, false) as PanelContainer
		var charm_leaf := panel.find_child("CharmLibraryLeaf", true, false) as PanelContainer
		_check(gear_leaf != null and binding_leaf != null and charm_leaf != null \
				and binding_leaf.size.x > gear_leaf.size.x \
				and binding_leaf.size.x > charm_leaf.size.x \
				and charm_leaf.size.x > gear_leaf.size.x,
			"Charm Table uses the authored 26/39/35 binding altar")
		_check(panel.find_child("BindingSockets", true, false) is VBoxContainer \
				and panel.find_child("ReagentCostStrips", true, false) is HBoxContainer,
			"Charm Table embodies sockets and reagent cost on the central surface")
		var item_art := panel.find_child("SelectedItemArt", true, false) as TextureRect
		_check(item_art != null and item_art.custom_minimum_size.y >= 108.0,
			"Charm Table makes the selected item the central visual focal")
		var cost_strip := panel.find_child("CostStrip_*", true, false) as PanelContainer
		_check(cost_strip != null and cost_strip.custom_minimum_size.x \
				> cost_strip.custom_minimum_size.y * 3.0,
			"Charm Table renders reagent cost as a readable horizontal strip")
		for candidate in panel.find_children("*", "Button", true, false):
			var socket_control := candidate as Button
			if socket_control.get_script() == CharmSocketScript:
				_check(socket_control.custom_minimum_size.x >= 192.0 \
						and socket_control.custom_minimum_size.y >= 64.0,
					"Charm sockets keep labels outside a legible icon well")
		var charm_rows := 0
		for child in buttons:
			if (child as Button).get_script() == JournalRow:
				charm_rows += 1
		_check(charm_rows >= 3,
			"Charm Table keeps gear and charm navigation in compact shared rows")
		var bind_action := panel.find_child("PrimaryBindAction", true, false) as Button
		_check(bind_action != null and bind_action.size.y >= 56.0,
			"Charm Table anchors one dominant binding action")
		var game := root.get_node("Game")
		var weapon = game.equipment.get_slot("weapon")
		var before_bind := (weapon.get("enchants", []) as Array).size()
		if bind_action != null and not bind_action.disabled:
			bind_action.pressed.emit()
			await _frames(4)
		_check((weapon.get("enchants", []) as Array).size() == before_bind + 1,
			"Charm Table central action preserves the real bind transaction")
		var bound_socket: Button = null
		for candidate in panel.find_children("*", "Button", true, false):
			var socket := candidate as Button
			if socket.get_script() == CharmSocketScript \
					and socket.tooltip_text.contains("draw"):
				bound_socket = socket
				break
		_check(bound_socket != null,
			"Charm Table represents bound state as an interactive socket")
		if bound_socket != null:
			bound_socket.pressed.emit()
			await _frames(4)
		_check((weapon.get("enchants", []) as Array).size() == before_bind,
			"Charm Table bound socket preserves the real draw-out transaction")
	if label == "Quill's Still":
		var shelf_leaf := panel.find_child("RemedyShelfLeaf", true, false) as PanelContainer
		var counter_leaf := panel.find_child("ApothecaryCounterLeaf", true, false) as PanelContainer
		_check(shelf_leaf != null and counter_leaf != null \
				and counter_leaf.size.x > shelf_leaf.size.x,
			"Quill's Still uses the authored 35/65 shelf-to-counter composition")
		var shelf := panel.find_child("RemedyShelf", true, false) as VBoxContainer
		_check(shelf != null and shelf.get_child_count() == 3,
			"Quill's Still keeps the complete three-ware shelf visible without scrolling")
		var remedy_art := panel.find_child("RemedyHeroArt", true, false) as Control
		var consequence := panel.find_child("RemedyConsequence", true, false) as Label
		_check(remedy_art != null and remedy_art.custom_minimum_size.y >= 150.0 \
				and consequence != null and consequence.text != "",
			"Quill's counter earns selection with dominant art and a written use")
		var buy_action := panel.find_child("PrimaryBuyAction", true, false) as Button
		_check(buy_action != null and buy_action.size.y >= 56.0,
			"Quill's counter anchors one dominant purchase action")
		var game := root.get_node("Game")
		var herb_before: int = game.material_count("wild_herb")
		var gold_before: int = int(game.gold)
		if buy_action != null and not buy_action.disabled:
			buy_action.pressed.emit()
			await _frames(4)
		_check(game.material_count("wild_herb") == herb_before + 1 \
				and int(game.gold) < gold_before,
			"Quill's counter preserves the real buy transaction")
		_check(root.gui_get_focus_owner() == buy_action,
			"Quill's counter preserves Buy focus for repeat purchases")
	if label == "Loadout":
		var bar_leaf := panel.find_child("FieldBarLeaf", true, false) as PanelContainer
		var library_leaf := panel.find_child("SkillLibraryLeaf", true, false) as PanelContainer
		_check(bar_leaf != null and library_leaf != null \
				and library_leaf.size.x > bar_leaf.size.x,
			"Loadout uses the authored 42/58 Field Bar-to-library composition")
		var loadout_slots: Array[Button] = []
		var choice_rows: Array[Button] = []
		for candidate in panel.find_children("*", "Button", true, false):
			var control := candidate as Button
			if control.get_script() == LoadoutSlotScript:
				loadout_slots.append(control)
			elif control.get_script() == LoadoutChoiceScript:
				choice_rows.append(control)
		_check(loadout_slots.size() == 5,
			"Loadout exposes F, three Focus slots, and Q as readable Controls")
		_check(not choice_rows.is_empty(),
			"Loadout composes quick-use and Skills from semantic library rows")
		_check(panel.find_child("Done", true, false) == null,
			"Loadout removes the fake Done action from its immediate editor")
		var game := root.get_node("Game")
		var multi_row := panel.find_child("SkillChoice_MultiShot", true, false) as Button
		if multi_row != null:
			multi_row.pressed.emit()
			await _frames(4)
		_check((game.loadout as Array).has("MultiShot"),
			"Loadout library click preserves first-open assignment")
		var quick_row := panel.find_child("QuickChoice_quickroot_tonic", true, false) as Button
		if quick_row != null:
			quick_row.pressed.emit()
			await _frames(4)
		_check(String(game.quick_item) == "quickroot_tonic",
			"Loadout quick-use row preserves Q pinning")
		var slot_two := panel.find_child("FieldSlot_1", true, false) as Button
		var slot_three := panel.find_child("FieldSlot_2", true, false) as Button
		if slot_two != null and slot_three != null:
			slot_two.grab_focus()
			var carry := InputEventKey.new()
			carry.keycode = KEY_Y
			carry.pressed = true
			panel.call("_unhandled_input", carry)
			slot_three.grab_focus()
			slot_three.pressed.emit()
			await _frames(4)
		_check((game.loadout as Array) == ["MultiShot", "PowerShot"],
			"Loadout keyboard carry mode preserves slot swapping without a mouse")
		if slot_two != null and slot_three != null:
			slot_two.grab_focus()
			var joy_carry := InputEventJoypadButton.new()
			joy_carry.button_index = JOY_BUTTON_Y
			joy_carry.pressed = true
			panel.call("_unhandled_input", joy_carry)
			slot_three.grab_focus()
			slot_three.pressed.emit()
			await _frames(4)
		_check((game.loadout as Array) == ["PowerShot", "MultiShot"],
			"Loadout controller carry mode preserves slot swapping without a mouse")
	if label == "Waystone Empty":
		var empty_leaf := panel.find_child("WaystoneEmptyState", true, false) as PanelContainer
		var empty_action := panel.find_child("CloseWaystoneButton", true, false) as Button
		_check(empty_leaf != null and empty_action != null \
				and empty_action.text == "Close the Waystone",
			"empty Waystone stays compact and gives its truthful single action")
	if label == "Waystone":
		var case_leaf := panel.find_child("ChartCaseLeaf", true, false) as PanelContainer
		var crossing_leaf := panel.find_child("CrossingFolioLeaf", true, false) as PanelContainer
		_check(case_leaf != null and crossing_leaf != null \
				and crossing_leaf.size.x > case_leaf.size.x,
			"Waystone uses the authored 36/64 Chart Case-to-crossing composition")
		_check(panel.find_child("RouteAndAffixes", true, false) is HBoxContainer,
			"Waystone keeps affixes beside the inked route without vertical overflow")
		var warning := panel.find_child("CrossingConsequence", true, false) as PanelContainer
		var step_action := panel.find_child("StepThroughButton", true, false) as Button
		_check(warning != null and step_action != null and step_action.size.y >= 64.0,
			"Waystone fixes the consumption warning directly above one crossing action")
		var chart_rows: Array[Button] = []
		for candidate in panel.find_children("ChartCaseRow*", "Button", true, false):
			chart_rows.append(candidate as Button)
		_check(chart_rows.size() == 2,
			"Waystone Chart Case uses the complete semantic Chart row set")
		if chart_rows.size() > 1:
			chart_rows[1].pressed.emit()
			await _frames(4)
		var selected_row := panel.find_child("ChartCaseRow1", true, false) as Button
		var crossing_title := panel.find_child("CrossingChartTitle", true, false) as Label
		_check(int(panel.get("_selected")) == 1 and crossing_title != null \
				and crossing_title.text == "Hollow Chart",
			"Waystone comparison keeps selected Chart identity aligned with the folio")
		_check(root.gui_get_focus_owner() == selected_row,
			"Waystone row selection preserves rapid case comparison focus")
	var focus := root.gui_get_focus_owner()
	_check(focus != null and panel.is_ancestor_of(focus),
		"%s assigns initial keyboard/controller focus" % label)
	if panel.has_method("_close"):
		panel.call("_close")
	else:
		panel.queue_free()
	await _frames(3)


func _run() -> void:
	root.size = Vector2i(1366, 768)
	var game := root.get_node("Game")
	game.reset_to_defaults()
	game.gold = 250
	game.trades["wayfinding"] = {"lv": 8, "xp": game.xp_for_level(8)}
	game.ensure_chart_starter_supplies()
	game.add_material("wild_herb", 6)
	game.add_material("logs", 4)
	game.add_material("bogiron_ore", 4)
	var host := Node.new()
	root.add_child(host)

	await _exercise(host, "res://scripts/ui/vendor_panel.gd", "Vendor")
	await _exercise(host, "res://scripts/ui/craft_panel.gd", "Cookfire",
		func(panel: Node): panel.set("station_id", "cookfire"))
	await _exercise(host, "res://scripts/ui/craft_panel.gd", "Forge",
		func(panel: Node): panel.set("station_id", "forge"))
	game.equipment.equip(Items.make_item("shortbow", "normal"))
	game.add_material("emberglass", 4)
	game.add_material("glimmerdust", 4)
	game.add_material("dewthread", 4)
	await _exercise(host, "res://scripts/ui/enchant_panel.gd", "Charm Table")
	await _exercise(host, "res://scripts/ui/quill_panel.gd", "Quill's Still")

	await _exercise(host, "res://scripts/ui/waystone_panel.gd", "Waystone Empty")
	game.charts.append({"template_id": "snug", "name": "Snug Chart",
		"tier": 1, "scope": "snug", "affixes": []})
	game.charts.append({"template_id": "hollow", "name": "Hollow Chart",
		"tier": 1, "scope": "hollow", "affixes": []})
	await _exercise(host, "res://scripts/ui/waystone_panel.gd", "Waystone")
	game.owned_skills = ["PowerShot", "MultiShot", "BrambleSnare"]
	game.loadout = ["PowerShot"]
	game.add_material("quickroot_tonic", 3)
	await _exercise(host, "res://scripts/ui/loadout_panel.gd", "Loadout")

	host.queue_free()
	await _frames()
	if _failures.is_empty():
		print("UI TRANSACTION CONTRACT: PASS")
		quit(0)
	else:
		print("UI TRANSACTION CONTRACT: FAIL (%d failures)" % _failures.size())
		quit(1)
