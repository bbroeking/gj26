extends SceneTree

# Regression for the D7 Golden source acknowledgement boundary. A retiring
# source dialog may remain in the shared group until its queued free settles.
# The strict scanner receipt proves which physical source owned the new press;
# D7 must acknowledge that source's dialog, never the first global group member.

const ChartsData = preload("res://data/charts.gd")
const Progression = preload("res://data/progression.gd")

var passed := 0
var failed := 0


class StaleSourceDialog extends CanvasLayer:
	var finish_calls := 0

	func _finish() -> void:
		finish_calls += 1


class DelayedDebriefPublisher extends Node:
	var town: Node = null
	var observed_frames := 0

	func _process(_delta: float) -> void:
		observed_frames += 1
		if observed_frames < 5:
			return
		set_process(false)
		if town != null and town.has_method("_show_pending_run_debrief"):
			town.call("_show_pending_run_debrief")


func check(label: String, ok: bool, detail = "") -> void:
	if ok:
		passed += 1
		print("  ✓ %s" % label)
	else:
		failed += 1
		print("  ✗ %s %s" % [label, str(detail)])


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	print("--- D7 Golden source dialog ownership ---")
	var game = root.get_node_or_null("Game")
	game.persistence_enabled = false
	game.reset_to_defaults()
	game.persistence_enabled = false
	game.web_smoke_enabled = true
	game.web_smoke_d7_enabled = true
	game.web_smoke_phase = ""
	game.web_smoke_history = []
	game.web_smoke_features = {}
	game.modal_count = 0
	paused = false
	game.trades["wayfinding"] = {
		"xp": Progression.xp_for_level(12), "lv": 12,
	}
	game.chart_source_unlocks = ChartsData.normalize_chart_source_unlocks(
		["mara_sallow_reed"])
	game.chart_recipe_journal = ChartsData.fresh_recipe_journal()
	game.materials = {}

	change_scene_to_file("res://scenes/Town.tscn")
	for _frame in 4:
		await process_frame
	var scene := current_scene
	var smoke_clock = game.get("_web_smoke_d7_clock")
	var clock_began := bool(smoke_clock.begin(true, true, "fresh_campaign"))
	game.pending_run_debrief = {
		"found": "a deep road", "rose": "+200 Wayfinding XP · Wayfinding 11",
		"opened": "Mara's rain-stained note", "template_id": "hollow",
		"preparation": false,
	}
	var publisher := DelayedDebriefPublisher.new()
	publisher.town = scene
	scene.add_child(publisher)
	await game._wait_d7_town_control()
	check("the active-clock waiter keeps pending debrief ownership before its deferred panel exists",
		clock_began and publisher.observed_frames >= 5
			and game.pending_run_debrief.is_empty()
			and get_nodes_in_group("run_debrief").is_empty()
			and game.modal_count == 0 and not paused
			and game.web_smoke_phase != "failed",
		{"clock_began": clock_began, "frames": publisher.observed_frames,
			"pending": game.pending_run_debrief, "modal_count": game.modal_count,
			"paused": paused, "phase": game.web_smoke_phase})
	await process_frame
	var note := scene.get_node_or_null("MaraSallowRumourSource") as Node3D
	var stale := StaleSourceDialog.new()
	stale.name = "RetiringChartRumourSourceDialog"
	stale.add_to_group("ChartRumourSourceDialog")
	scene.add_child(stale)
	var read_ok: bool = await game._d7_read_golden_source(note, "mara_sallow_reed")
	var status: Dictionary = game.chart_source_status("mara_sallow_reed")
	check("the exact physical source owns the acknowledged read transaction",
		read_ok and String(status.get("state", "")) == "read"
			and stale.finish_calls == 0
			and (game.chart_recipe_journal.get("rumours", []) as Array).has("mara_sallow_reed")
			and game.material_count("waxed_vellum") == 1
			and game.web_smoke_phase != "failed",
		{"read_ok": read_ok, "state": status.get("state", ""),
			"stale_finish_calls": stale.finish_calls,
			"phase": game.web_smoke_phase,
			"dialogs": get_nodes_in_group("ChartRumourSourceDialog").size()})

	game.web_smoke_d7_enabled = false
	smoke_clock.restore("focused_test")
	print("--- D7 Golden source dialog ownership: %d PASS, %d FAIL ---" % [passed, failed])
	quit(1 if failed > 0 else 0)
