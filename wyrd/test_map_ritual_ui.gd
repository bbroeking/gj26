extends SceneTree

# Presentation contract for the later use of the single Threefold Loom.  The
# fake owns the only mutable facts; these tests prove the world/UI layer does
# not infer them, create a second Loom, or offer a guest a local transaction.

const LoomSourceScript = preload("res://scripts/threefold_loom_source.gd")
const MapRitualPanelScript = preload("res://scripts/ui/map_ritual_panel.gd")
const Tokens = preload("res://scripts/ui/foundation/ui_tokens.gd")

var _failures: Array[String] = []


class FakeLoomGame:
	extends Node
	signal story_changed
	signal chart_knowledge_changed
	var modal_opens := 0
	var modal_closes := 0
	var trace_calls := 0
	var guest := false
	var recorded := false
	var repairable := false

	func modal_opened() -> void:
		modal_opens += 1

	func modal_closed() -> void:
		modal_closes += 1

	func chart_source_status(_source_id: String) -> Dictionary:
		return {"valid": true, "source_id": "threefold_loom_root_below",
			"state": "resolved", "known": true, "heard": true,
			"recipe_id": "root_below", "rumour_id": "root_below"}

	func read_chart_source(_source_id: String) -> Dictionary:
		return {"ok": true, "changed": false}

	func threefold_loom_view() -> Dictionary:
		return {
			"phase": "map_recorded" if recorded else "ritual_ready",
			"read_only": guest,
			"can_trace": not guest and not recorded,
			"map_recorded": recorded,
			"knowledge_complete": recorded and not repairable,
			"can_repair_knowledge": recorded and repairable and not guest,
			"loom_state": "stirring",
			"requirements": [
				{"id": "fire_in_the_bough", "label": "Fire in the Bough cleared", "met": true},
				{"id": "lost_waymarks", "label": "Five Lost Waymarks returned", "current": 5, "required": 5},
				{"id": "past_thread", "label": "Past Thread remembered", "met": true},
				{"id": "present_thread", "label": "Present Thread remembered", "met": true},
				{"id": "wayfinding_23", "label": "Wayfinding", "current": 23, "required": 23},
			],
		}

	func trace_threefold_loom_map() -> Dictionary:
		trace_calls += 1
		if guest:
			return {"ok": false, "changed": false, "reason": "host_only"}
		recorded = true
		repairable = false
		story_changed.emit()
		chart_knowledge_changed.emit()
		return {"ok": true, "changed": true, "view": threefold_loom_view()}


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
	var panel: CanvasLayer = MapRitualPanelScript.new()
	panel.game_override = game
	root.add_child(panel)
	return panel


func _run() -> void:
	root.size = Vector2i(1366, 768)
	var game := FakeLoomGame.new()
	root.add_child(game)
	var panel := _panel(game)
	await _frames()
	_check(game.modal_opens == 1, "opening the Map parchment owns exactly one modal")
	var requirements := panel.find_child("MapRequirements", true, false) as Control
	_check(requirements != null and requirements.get_child_count() == 5,
		"Map parchment renders the five and only five ritual requirements")
	var trace := panel.find_child("TraceMapButton", true, false) as Button
	var close := panel.find_child("CloseButton", true, false) as Button
	_check(trace != null and not trace.disabled and trace.text == "Trace the Map"
		and close != null and close.custom_minimum_size.y >= Tokens.HIT_TARGET,
		"host sees a real accessible Trace the Map button and an explicit close")
	trace.pressed.emit()
	await _frames()
	trace = panel.find_child("TraceMapButton", true, false) as Button
	_check(game.trace_calls == 1 and game.recorded and trace != null and trace.disabled
		and trace.text.contains("Chart Table"),
		"the one host click uses the Game transaction then directs the player to Mara's Chart Table: %s" % str({
			"calls": game.trace_calls, "recorded": game.recorded,
			"text": trace.text if trace != null else "", "disabled": trace.disabled if trace != null else false}))
	panel.call("_close")
	await _frames()
	_check(game.modal_closes == 1, "closing releases exactly the Map modal")

	# A trusted v6 Map can survive with only its final Codex provenance missing.
	# That one repair must remain available through the exact same physical
	# button/transaction, while a wholly complete Map remains inert.
	game.guest = false
	game.recorded = true
	game.repairable = true
	var repair_panel := _panel(game)
	await _frames()
	var repair_trace := repair_panel.find_child("TraceMapButton", true, false) as Button
	_check(repair_trace != null and not repair_trace.disabled
		and repair_trace.text == "Restore the Map's Codex entry",
		"host can repair a trusted recorded Map whose final Codex entry is incomplete")
	repair_trace.pressed.emit()
	await _frames()
	repair_trace = repair_panel.find_child("TraceMapButton", true, false) as Button
	_check(game.trace_calls == 2 and not game.repairable and repair_trace != null
		and repair_trace.disabled and repair_trace.text.contains("Chart Table"),
		"repair converges through the sole Map transaction then returns to the inert recorded state")
	repair_panel.call("_close")
	await _frames()

	game.guest = true
	game.recorded = true
	game.repairable = true
	var guest_panel := _panel(game)
	await _frames()
	var guest_trace := guest_panel.find_child("TraceMapButton", true, false) as Button
	var status := guest_panel.find_child("RitualStatus", true, false) as Label
	_check(guest_trace != null and guest_trace.disabled and guest_trace.text == "Host traces the Map"
		and status != null and status.text.contains("fire-keeper"),
		"guest gets a read-only CTA with no local ritual or Codex-repair affordance")
	guest_trace.pressed.emit()
	await _frames()
	_check(game.trace_calls == 2, "guest button cannot issue a ritual or Codex-repair transaction/RPC")
	guest_panel.call("_close")
	await _frames()

	# The later Map uses the same interactive node, and repeated interaction may
	# only reveal the already-open parchment once; it cannot mount another Loom.
	var fixture := Node3D.new()
	fixture.name = "LoomTownFixture"
	root.add_child(fixture)
	current_scene = fixture
	var loom: Node3D = LoomSourceScript.new()
	loom.name = "ThreefoldLoomSource"
	loom.game_override = game
	fixture.add_child(loom)
	await _frames()
	game.guest = false
	game.recorded = false
	game.repairable = false
	loom.interact(null)
	loom.interact(null)
	await _frames()
	_check(fixture.find_children("ThreefoldLoomSource", "", true, false).size() == 1
		and get_nodes_in_group("MapRitualPanel").size() == 1,
		"the Town's one Loom remains one scanner target while its ritual panel is open")
	var loom_panel := get_first_node_in_group("MapRitualPanel")
	if loom_panel != null:
		loom_panel.call("_close")
	await _frames()
	fixture.queue_free()
	game.queue_free()
	if _failures.is_empty():
		print("MAP RITUAL UI: PASS")
		quit(0)
	else:
		print("MAP RITUAL UI: FAIL (%d failures)" % _failures.size())
		quit(1)
