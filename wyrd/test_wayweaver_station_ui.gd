extends SceneTree

# Focused contract for the D8 station UI boundary. The fake Game deliberately
# owns all previews/commits; the panel must never reach into materials or
# campaign fields to make an outcome happen.

const MasteryPanelScript = preload("res://scripts/ui/mastery_panel.gd")
const MasteryStationScript = preload("res://scripts/mastery_station.gd")
const Tokens = preload("res://scripts/ui/foundation/ui_tokens.gd")

var _failures: Array[String] = []


class FakeWayweaverGame:
	extends Node
	var modal_opens := 0
	var modal_closes := 0
	var preview_calls := 0
	var commit_calls := 0
	var last_station := ""
	var last_action := ""
	var last_destination := ""
	var last_rune := ""
	var rune_calls := 0
	var selected_rune := "green_root_rune"
	var commit_ok := false
	var enabled := true
	var show_runes := false

	func modal_opened() -> void:
		modal_opens += 1

	func modal_closed() -> void:
		modal_closes += 1

	func wayweaver_preview(station_id: String, action_id: String) -> Dictionary:
		preview_calls += 1
		return {
			"enabled": enabled and not show_runes,
			"title": "Forge Wayweaver",
			"description": "Hod keeps the fire low and steady.",
			"mastery_gate": "All four Trades at 23",
			"requirements": [
				{"id": "waysteel_frame", "label": "Waysteel Frame", "required": 1, "have": 1},
				{"id": "wayweaver_string", "label": "Wayweaver String", "required": 1, "have": 1},
				{"id": "quiet_tooth_grip", "label": "Quiet-Tooth Grip", "required": 1, "have": 1},
				{"id": "six_runes", "label": "Six Root Runes", "required": 6, "have": 6, "permanent": true},
			],
			"kept_records": ["Map", "Six Root Runes", "Past, Present, and Unwritten Threads"],
			"missing_reason": "Bring the three components together.",
			"final_forge": true,
			"action_label": "Forge Wayweaver",
			"rune_options": ([
				{"id": "green_root_rune", "label": "Green Root Rune", "owned": true,
					"icon_path": "res://assets/ui/items/green_root_rune.png",
					"selected": selected_rune == "green_root_rune"},
				{"id": "mist_root_rune", "label": "Mist Root Rune", "owned": true,
					"icon_path": "res://assets/ui/items/mist_root_rune.png",
					"selected": selected_rune == "mist_root_rune"},
				{"id": "ember_root_rune", "label": "Ember Root Rune", "owned": false,
					"icon_path": "res://assets/ui/items/ember_root_rune.png",
					"selected": false},
			] if show_runes else []),
		}

	func commit_wayweaver(station_id: String, action_id: String, destination: String) -> Dictionary:
		commit_calls += 1
		last_station = station_id
		last_action = action_id
		last_destination = destination
		return {"ok": commit_ok, "reason": "The pack has changed; choose again."}

	func set_wayweaver_cosmetic_rune(rune_id: String) -> Dictionary:
		rune_calls += 1
		last_rune = rune_id
		selected_rune = rune_id
		return {"ok": true, "changed": true, "rune_id": rune_id}


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
	else:
		_failures.append(message)
		push_error("FAIL: %s" % message)


func _frames(count := 3) -> void:
	for _frame in range(count):
		await process_frame


func _panel(game: Node) -> CanvasLayer:
	var panel: CanvasLayer = MasteryPanelScript.new()
	panel.station_id = "master_forge"
	panel.action_id = "wayweaver"
	panel.game_override = game
	root.add_child(panel)
	return panel


func _run() -> void:
	root.size = Vector2i(1366, 768)
	var game := FakeWayweaverGame.new()
	root.add_child(game)
	var panel: CanvasLayer = _panel(game)
	await _frames()
	_check(game.modal_opens == 1, "opening owns exactly one modal")
	_check(game.preview_calls >= 1, "panel asks Game for its preview")
	var shell := panel.find_child("TransactionShell", true, false) as Control
	_check(shell != null and shell.size.x >= 1000.0 and shell.size.y <= 650.0,
		"Mastery uses the shared wide workbench without exceeding the 768p safe height")
	for leaf_name in ["MasterworkPiecesLeaf", "AssemblyLeaf", "FinalMeasureLeaf"]:
		_check(panel.find_child(leaf_name, true, false) != null,
			"forge mode keeps Offering, Masterwork, and Keeping in separate leaves")
	var focus := root.gui_get_focus_owner()
	_check(focus != null and panel.is_ancestor_of(focus), "panel assigns keyboard/controller focus")
	for control in [panel.find_child("CloseButton", true, false) as Control,
		panel.find_child("KeepButton", true, false) as Control,
		panel.find_child("EquipButton", true, false) as Control,
		panel.find_child("CommitButton", true, false) as Control]:
		_check(control != null and maxf(control.size.y, control.custom_minimum_size.y) >= Tokens.HIT_TARGET,
			"every station control meets the 48px target floor")
	var kept := panel.find_child("KeptRecordRow", true, false) as Label
	_check(kept != null and kept.text.begins_with("Kept record") and kept.text.contains("Map") \
		and kept.text.contains("Six Root Runes"),
		"permanent witnesses are shown as kept records, not a cost")
	var requirements := panel.find_child("ComponentRequirements", true, false) as Control
	_check(requirements != null and requirements.get_child_count() == 3,
		"panel shows the exact physical components from the preview")
	_check(panel.find_children("ComponentIcon", "TextureRect", true, false).size() == 3,
		"every listed Mastery component uses authored icon art")
	_check(panel.find_child("RuneBindingChoices", true, false) == null,
		"pre-ownership forge mode does not invent the later Root Rune tending state")
	if OS.get_environment("WYRD_SHOT") != "":
		var texture := root.get_viewport().get_texture()
		var image := texture.get_image() if texture != null else null
		if image != null:
			image.save_png("/tmp/wayweaver_mastery_ui.png")

	var previews_before := game.preview_calls
	panel.call("_set_destination", "equip")
	panel.call("_on_commit")
	await _frames()
	_check(game.preview_calls >= previews_before + 2, "commit requeries stale preview before and after failure")
	_check(game.commit_calls == 1 and game.last_station == "master_forge" \
		and game.last_action == "wayweaver" and game.last_destination == "equip",
		"final choice forwards the exact station, action, and destination")
	_check(not panel.is_queued_for_deletion(), "failed commit keeps the station open")
	_check(game.modal_closes == 0, "failed commit does not release the modal")

	panel.set("_committing", true)
	var cancel := InputEventAction.new()
	cancel.action = "ui_cancel"
	cancel.pressed = true
	panel.call("_unhandled_input", cancel)
	_check(not panel.is_queued_for_deletion(), "Escape cannot close during a synchronous commit")
	panel.set("_committing", false)
	panel.call("_close")
	await _frames()
	_check(game.modal_closes == 1, "close releases exactly the modal it opened")

	var tending_game := FakeWayweaverGame.new()
	tending_game.show_runes = true
	root.add_child(tending_game)
	var tending_panel: CanvasLayer = _panel(tending_game)
	await _frames()
	var rune_choices := tending_panel.find_child("RuneBindingChoices", true, false) as GridContainer
	var mist_rune := tending_panel.find_child("Rune_mist_root_rune", true, false) as Button
	var ember_rune := tending_panel.find_child("Rune_ember_root_rune", true, false) as Button
	_check(rune_choices != null and rune_choices.columns == 3 and mist_rune != null
		and ember_rune != null and not mist_rune.disabled and ember_rune.disabled,
		"post-ownership tending mode presents a 3-column Root Rune surface and locks missing Runes")
	_check(tending_panel.find_child("KeepButton", true, false) == null
		and tending_panel.find_child("EquipButton", true, false) == null
		and tending_panel.find_child("CommitButton", true, false) == null,
		"tending mode removes obsolete placement choices and the impossible Forge action")
	_check(mist_rune.find_child("RuneIcon", true, false) is TextureRect
		and (mist_rune.find_child("RuneIcon", true, false) as TextureRect).texture != null
		and ember_rune.find_child("RuneIcon", true, false) is TextureRect
		and (ember_rune.find_child("RuneIcon", true, false) as TextureRect).texture != null,
		"Root Rune choices use the shared authored story icons")
	mist_rune.pressed.emit()
	await _frames()
	_check(tending_game.rune_calls == 1 and tending_game.last_rune == "mist_root_rune"
		and (tending_panel.find_child("Rune_mist_root_rune", true, false) as Button).disabled,
		"Rune selection remains a Game-authoritative transaction and refreshes its selection")
	tending_panel.call("_close")
	await _frames()
	tending_game.free()

	var station: Node = MasteryStationScript.new()
	station.station_id = "awake_loom"
	_check(station.resolved_action_id() == "wayweaver_string",
		"awake Loom has an explicit string action adapter")
	station.free()
	game.free()
	if _failures.is_empty():
		print("WAYWEAVER STATION UI: PASS")
		quit(0)
	else:
		print("WAYWEAVER STATION UI: FAIL (%d failures)" % _failures.size())
		quit(1)
