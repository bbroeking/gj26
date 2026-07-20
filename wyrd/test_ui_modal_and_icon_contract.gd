extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
	else:
		_failures.append(message)
		push_error("FAIL: %s" % message)


func _gameplay_hud_layers() -> Array[CanvasLayer]:
	var layers: Array[CanvasLayer] = []
	for node in get_nodes_in_group("gameplay_hud"):
		if node is CanvasLayer:
			layers.append(node as CanvasLayer)
	return layers


func _all_layers_have_visibility(expected: bool) -> bool:
	var layers := _gameplay_hud_layers()
	if layers.is_empty():
		return false
	for layer in layers:
		if layer.visible != expected:
			return false
	return true


func _wait_frames(count: int = 2) -> void:
	for _frame in range(count):
		await process_frame


func _run() -> void:
	var town_scene := load("res://scenes/Town.tscn") as PackedScene
	_check(town_scene != null, "town scene loads")
	if town_scene == null:
		_finish()
		return

	var town := town_scene.instantiate()
	root.add_child(town)
	await _wait_frames(5)

	_check(not _gameplay_hud_layers().is_empty(), "gameplay HUD layers identify themselves")
	_check(_all_layers_have_visibility(true), "gameplay HUD starts visible")

	var vendor_script := load("res://scripts/ui/vendor_panel.gd") as Script
	var vendor: Node = vendor_script.new()
	town.add_child(vendor)
	await _wait_frames()
	_check(_all_layers_have_visibility(false), "vendor modal suppresses gameplay HUD")
	vendor.call("_close")
	await _wait_frames(3)
	_check(_all_layers_have_visibility(true), "gameplay HUD returns after vendor closes")

	var dialogue_script := load("res://scripts/ui/dialog_panel.gd") as Script
	var dialogue: Node = dialogue_script.new()
	dialogue.call("open", "Mara Linnet", ["A chart begins with one clear mark."])
	town.add_child(dialogue)
	await _wait_frames()
	_check(_all_layers_have_visibility(false), "dialogue modal suppresses gameplay HUD")
	var dialogue_shell := dialogue.get_node_or_null("DialogueShell") as Control
	_check(dialogue_shell != null, "dialogue uses the shared semantic shell")
	if dialogue_shell != null:
		_check(dialogue_shell.size.y <= root.get_viewport().get_visible_rect().size.y * 0.40 + 1.0,
			"ordinary dialogue stays within the lower 40 percent")
	var portrait_shell := dialogue.find_child("PortraitWell", true, false) as Control
	_check(portrait_shell != null and not portrait_shell.visible,
		"no-portrait dialogue gives its space back to prose")
	dialogue.call("_finish")
	await _wait_frames(3)
	_check(_all_layers_have_visibility(true), "gameplay HUD returns after dialogue closes")

	var choice_dialogue: Node = dialogue_script.new()
	choice_dialogue.call("open", "Mara Linnet", ["Which mark do you make?"], null,
		["A clear waymark.", "Not just yet."])
	town.add_child(choice_dialogue)
	await _wait_frames(4)
	var choice_box := choice_dialogue.find_child("Choices", true, false) as VBoxContainer
	_check(choice_box != null and choice_box.get_child_count() == 2,
		"dialogue builds one semantic Control per choice")
	if choice_box != null and choice_box.get_child_count() == 2:
		var first_choice := choice_box.get_child(0) as Button
		_check(first_choice.custom_minimum_size.y >= 48.0,
			"dialogue choices meet the 48px target floor")
		_check(first_choice.has_focus(),
			"dialogue gives initial focus to the first choice")
	var focus_pointer := choice_dialogue.find_child("FocusPointer", true, false) as Control
	_check(focus_pointer != null and focus_pointer.visible,
		"dialogue pairs the focus ring with a non-color pointer")
	choice_dialogue.call("_finish")
	await _wait_frames(3)
	_check(_all_layers_have_visibility(true),
		"gameplay HUD returns after choice dialogue closes")

	for item_id in ["wild_herb", "logs", "bogiron_ore", "hedge_ink",
			"stoneground_ink", "refined_ink", "hedgesteel_ore"]:
		var icon_path := "res://assets/ui/items/%s.png" % item_id
		_check(ResourceLoader.exists(icon_path), "%s has a real inventory icon" % item_id)

	var cursor_script := load("res://scripts/ui/cursor.gd") as Script
	var cursor_probe: Node = cursor_script.new()
	var panel := Panel.new()
	var button := Button.new()
	panel.add_child(button)
	_check(cursor_probe.has_method("cursor_kind_for"),
		"cursor exposes a shared UI-hover classifier")
	if cursor_probe.has_method("cursor_kind_for"):
		_check(String(cursor_probe.call("cursor_kind_for", null)) == "world",
			"empty hover uses the world cursor")
		_check(String(cursor_probe.call("cursor_kind_for", panel)) == "panel",
			"panel hover uses a visible UI cursor")
		_check(String(cursor_probe.call("cursor_kind_for", button)) == "interactive",
			"button hover uses the interactive cursor")
		button.set_meta("cursor_role", "place_valid")
		_check(String(cursor_probe.call("cursor_kind_for", button)) == "place_valid",
			"semantic valid-cell cursor overrides the generic button role")
		button.set_meta("cursor_role", "place_invalid")
		_check(String(cursor_probe.call("cursor_kind_for", button)) == "place_invalid",
			"semantic invalid-cell cursor is explicit")
	for cursor_name in ["cursor_default", "cursor_interact"]:
		var cursor_path := "res://assets/ui/%s.png" % cursor_name
		_check(ResourceLoader.exists(cursor_path), "%s texture exists" % cursor_name)
		if ResourceLoader.exists(cursor_path):
			var cursor_tex := load(cursor_path) as Texture2D
			_check(cursor_tex != null and cursor_tex.get_width() == 32 \
				and cursor_tex.get_height() == 32,
				"%s stays at the 32px UI cursor scale" % cursor_name)
	panel.free()
	cursor_probe.free()

	var charts_data = load("res://data/charts.gd")
	var component_shapes_complete := true
	for component_id in charts_data.COMPONENTS:
		var shape := String(charts_data.COMPONENTS[component_id].get("icon_shape", ""))
		component_shapes_complete = component_shapes_complete and shape != ""
	_check(component_shapes_complete,
		"every Chart component has registered icon-shape metadata")

	var app_icon_path := String(ProjectSettings.get_setting("application/config/icon", ""))
	_check(app_icon_path == "res://assets/brand/wayfinder_icon.png",
		"application and Web export use the Wayfinder brand icon")
	_check(ResourceLoader.exists(app_icon_path), "Wayfinder brand icon is importable")

	town.queue_free()
	await _wait_frames()
	_finish()


func _finish() -> void:
	if _failures.is_empty():
		print("UI MODAL + ICON CONTRACT: PASS")
		quit(0)
	else:
		print("UI MODAL + ICON CONTRACT: FAIL (%d failures)" % _failures.size())
		quit(1)
