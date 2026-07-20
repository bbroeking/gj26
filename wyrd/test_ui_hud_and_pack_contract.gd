extends SceneTree

# Spec 59 — the always-on HUD and Pack must remain semantic, readable, and
# keyboard/controller operable as their visual treatment evolves.

const Items = preload("res://data/items.gd")
const Tokens = preload("res://scripts/ui/foundation/ui_tokens.gd")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
	else:
		_failures.append(message)
		push_error("FAIL: %s" % message)


func _wait_frames(count: int = 2) -> void:
	for _frame in range(count):
		await process_frame


func _find_button_with_text(parent: Node, prefix: String) -> Button:
	for child in parent.find_children("*", "Button", true, false):
		var button := child as Button
		if button != null and button.text.begins_with(prefix):
			return button
		if button != null:
			var title := button.find_child("Title", true, false) as Label
			if title != null and title.text.begins_with(prefix):
				return button
	return null


func _run() -> void:
	var hud_scene := load("res://scenes/PlayerHUD.tscn") as PackedScene
	var hud := hud_scene.instantiate()
	root.add_child(hud)
	await _wait_frames(3)
	var objective := hud.find_child("Objective", true, false) as Label
	_check(objective != null, "HUD exposes the quest objective as a semantic Label")
	if objective != null:
		_check(objective.get_theme_font_size("font_size") >= Tokens.TYPE_BODY,
			"HUD objective preserves the 16px body-text floor")
	var action_bar := hud.find_child("ActionBar", true, false) as HBoxContainer
	_check(action_bar != null and action_bar.get_child_count() >= 3,
		"HUD exposes persistent Pack actions as real Controls")
	if action_bar != null:
		for child in action_bar.get_children():
			if child is Button:
				_check((child as Button).custom_minimum_size.y >= Tokens.HIT_TARGET,
					"%s meets the 48px target floor" % child.name)
	_check(hud.find_child("VitalHp", true, false) != null,
		"HUD presents HP as a named horizontal meter")
	_check(hud.find_child("VitalFocus", true, false) != null,
		"HUD presents Focus as a named horizontal meter")
	_check(hud.find_child("HudFocusPointer", true, false) != null,
		"HUD has a non-color keyboard focus pointer")
	hud.queue_free()
	await _wait_frames()

	var skill_bar_scene := load("res://scenes/SkillBar.tscn") as PackedScene
	var skill_bar := skill_bar_scene.instantiate()
	root.add_child(skill_bar)
	var player_scene := load("res://scenes/Player.tscn") as PackedScene
	var player := player_scene.instantiate()
	root.add_child(player)
	await _wait_frames(4)
	skill_bar.call("bind_to_player", player)
	await _wait_frames(3)
	var first_slot := skill_bar.find_child("Slot1", true, false)
	_check(first_slot is Button, "hotbar skills use real focusable Buttons")
	if first_slot is Button:
		_check((first_slot as Button).focus_mode == Control.FOCUS_ALL,
			"hotbar skills support keyboard/controller focus")
		_check((first_slot as Button).custom_minimum_size.y >= Tokens.HIT_TARGET,
			"hotbar skills meet the 48px target floor")
	skill_bar.queue_free()
	player.queue_free()
	await _wait_frames()

	var inventory := Inventory.new()
	var equipment := Equipment.new()
	var bow := Items.make_item("shortbow", "normal")
	_check(inventory.try_place(bow, Vector2i.ZERO), "test gear is placed in the Pack")
	var pack_scene := load("res://scenes/InventoryPanel.tscn") as PackedScene
	var pack_layer := pack_scene.instantiate()
	root.add_child(pack_layer)
	var pack := pack_layer.get_node("Root")
	pack.call("set_inventory", inventory)
	pack.call("set_equipment", equipment)
	pack.call("open_tab", 0)
	await _wait_frames(4)
	var shell := pack.find_child("PackShell", true, false) as Control
	_check(shell != null, "Pack uses the shared framed semantic shell")
	if shell != null:
		var viewport_size := root.get_viewport().get_visible_rect().size
		_check(shell.size.x <= viewport_size.x - Tokens.SPACE_4 * 2 + 1.0,
			"Pack stays inside the responsive viewport margin")
		_check(shell.size.y <= viewport_size.y - Tokens.SPACE_4 * 2 + 1.0,
			"Pack stays inside the responsive viewport margin vertically")
		for fixture in [Vector2i(1280, 720), Vector2i(1366, 768),
				Vector2i(1920, 1080), Vector2i(2560, 1080)]:
			root.size = fixture
			await _wait_frames(3)
			var rect := shell.get_global_rect()
			_check(rect.position.x >= 0 and rect.position.y >= 0 \
					and rect.end.x <= fixture.x and rect.end.y <= fixture.y,
				"Pack remains on-screen at %d×%d" % [fixture.x, fixture.y])
		root.size = Vector2i(1366, 768)
		await _wait_frames(3)
	var tabs := pack.find_child("PackTabs", true, false) as HBoxContainer
	_check(tabs != null and tabs.get_child_count() == 4,
		"Pack exposes Gear, Satchel, Charts, and Trades as real tabs")
	if tabs != null:
		for child in tabs.get_children():
			_check(child is Button and (child as Button).custom_minimum_size.y >= Tokens.HIT_TARGET,
				"%s is a 48px semantic tab target" % child.name)
	var gear_button := pack.find_child("GearTab", true, false) as Button
	_check(gear_button != null and gear_button.has_focus(),
		"Pack assigns initial focus to its selected tab")
	_check(pack.find_child("PackFocusPointer", true, false) != null,
		"Pack pairs focus styling with a non-color pointer")
	var bow_button := _find_button_with_text(pack, "Shortbow")
	_check(bow_button != null and not bow_button.disabled,
		"backpack gear is an actionable semantic Button")
	if bow_button != null:
		bow_button.pressed.emit()
		await _wait_frames(4)
		_check(equipment.get_slot("weapon") == bow and inventory.items.is_empty(),
			"Pack quick-equip preserves Inventory and Equipment data contracts")
		var weapon_slot := pack.find_child("WeaponEquipmentSlot", true, false) as Button
		var weapon_subtitle := weapon_slot.find_child("Subtitle", true, false) as Label \
			if weapon_slot != null else null
		_check(weapon_subtitle != null and weapon_subtitle.text.contains("Shortbow"),
			"deferred Pack rebuild shows the equipped item safely")

	for index in range(1, 4):
		pack.call("open_tab", index)
		await _wait_frames(3)
		_check(pack.visible, "%s route opens its Pack page" % ["Satchel", "Charts", "Trades"][index - 1])
	pack.call("_close_pack")
	await _wait_frames()
	_check(not pack.visible, "Pack close action releases the modal")
	pack_layer.queue_free()
	await _wait_frames()
	_finish()


func _finish() -> void:
	if _failures.is_empty():
		print("UI HUD + PACK CONTRACT: PASS")
		quit(0)
	else:
		print("UI HUD + PACK CONTRACT: FAIL (%d failures)" % _failures.size())
		quit(1)
