extends SceneTree

# Acceptance gate for the bounded 5–10 minute First Road slice.
# Run: WYRD_NO_SAVE=1 godot --headless --path . --script res://test_first_road_slice.gd

const FirstRoadData = preload("res://data/first_road.gd")
const ChartsData = preload("res://data/charts.gd")
const CraftingBenchScript = preload("res://scripts/ui/crafting_bench.gd")

var passed := 0
var failed := 0


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
	print("--- First Road vertical-slice acceptance ---")
	var game := root.get_node("Game")
	game.persistence_enabled = false
	game.reset_to_defaults()
	game.start_first_road()
	check("fresh journey waits on one authored choice", game.first_road_active()
		and game.tutorial_step == 0 and game.charts.is_empty())
	check("fresh control names movement and talk without revealing the needle",
		game.objective_hint() == "WASD move · E talk"
		and not game.onboarding_compass_available(), game.objective_hint())
	game._onboarding_progress_msec = Time.get_ticks_msec() - 21000
	game._onboarding_recovery_poll_msec = 0
	game._tick_onboarding_recovery()
	check("20-second recovery names Mara's landmark without the needle",
		game.onboarding_hint_stage() == 1
		and "teal worktable" in game.objective_hint()
		and not game.onboarding_compass_available(), game.objective_hint())
	game._onboarding_progress_msec = Time.get_ticks_msec() - 36000
	game._onboarding_recovery_poll_msec = 0
	game._tick_onboarding_recovery()
	check("35-second recovery adds the direct destination needle",
		game.onboarding_hint_stage() == 2
		and "gold needle" in game.objective_hint()
		and game.onboarding_compass_available(), game.objective_hint())
	check("invalid choice cannot mutate the case", not game.choose_first_road(9)
		and game.charts.is_empty())
	check("Kind Road choice opens the hands-on Chart lesson",
		game.choose_first_road(0) and game.tutorial_step == 3
		and game.charts.is_empty()
		and game.first_chart_walkthrough_active())
	check("choice alone cannot silently create a Chart",
		game.charts.is_empty(), game.charts)
	check("choice is one-shot", not game.choose_first_road(1)
		and game.charts.is_empty())
	var table := CraftingBenchScript.new()
	root.add_child(table)
	await process_frame
	check("first Chart lesson opens on its first Space screen",
		table.first_chart_walkthrough_screen() == 0)
	for expected_screen in range(1, 5):
		check("Space advances first Chart screen %d" % expected_screen,
			table.advance_first_chart_walkthrough()
			and table.first_chart_walkthrough_screen() == expected_screen)
	check("fifth Space performs the real inscription",
		table.advance_first_chart_walkthrough()
		and table.first_chart_walkthrough_screen() == 5
		and game.charts.size() == 1)
	var chosen: Dictionary = game.charts[0] if not game.charts.is_empty() else {}
	check("chosen Chart carries exactly three stable Affixes",
		(chosen.get("affixes", []) as Array).size() == 3
		and String(chosen.get("first_road_profile", "")) == "kind", chosen)
	check("completion screen also advances with Space",
		table.advance_first_chart_walkthrough())
	await process_frame

	var template: Dictionary = ChartsData.TEMPLATES.first_road
	check("layout stays inside the short 4–5 room budget",
		int(template.gen.room_count_min) == 4
		and int(template.gen.room_count_max) == 5, template.gen)
	for profile_id in FirstRoadData.PROFILE_ORDER:
		var chart := FirstRoadData.make_chart(profile_id)
		check("%s profile has three presentable Affixes" % profile_id,
			(chart.affixes as Array).size() == 3
			and (chart.affixes as Array).all(func(a):
				return not ChartsData.affix_presentation(chart, a).is_empty()), chart)

	# Build both real World scenes. Kind suppresses all random elites; Bold
	# guarantees a readable marked company beyond the normalized lesson rat.
	var kind_stats := await build_world_stats(game, FirstRoadData.make_chart("kind"))
	var bold_stats := await build_world_stats(game, FirstRoadData.make_chart("bold"))
	check("Kind Road keeps the pressure pack elite-free",
		int(kind_stats.elites) == 0 and int(kind_stats.enemies) >= 2, kind_stats)
	check("Bold Road guarantees an elite pressure state",
		int(bold_stats.elites) >= 1 and int(bold_stats.enemies) > int(kind_stats.enemies),
		bold_stats)
	check("vigor choice is mechanically meaningful",
		float(bold_stats.average_hp) > float(kind_stats.average_hp),
		{"kind": kind_stats.average_hp, "bold": bold_stats.average_hp})

	# Successful-return state projects one physical, lit village payoff.
	game.active_chart = FirstRoadData.make_chart("kind")
	game.in_dungeon = true
	game.tutorial_step = 5
	game._capture_run_start()
	game.return_to_town(null, false)
	await process_frame
	await process_frame
	await process_frame
	check("successful return records payoff and grants Power Shot",
		bool(game.seen_hints.get("first_road_completed", false))
		and game.skill_owned("PowerShot"), game.seen_hints)
	check("returned Town contains the physical First Road lamp",
		get_nodes_in_group("first_road_payoff").size() == 1,
		get_nodes_in_group("first_road_payoff").size())
	check("debrief names the changed yard",
		String(game.pending_run_debrief.get("opened", "")).contains("changed yard"),
		game.pending_run_debrief)

	print("--- First Road: %d PASS, %d FAIL ---" % [passed, failed])
	quit(1 if failed > 0 else 0)


func build_world_stats(game: Node, chart: Dictionary) -> Dictionary:
	game.active_chart = chart
	game.in_dungeon = true
	game.tutorial_step = 5
	change_scene_to_file("res://scenes/World.tscn")
	await process_frame
	await process_frame
	await process_frame
	var enemies := get_nodes_in_group("enemy")
	var elites := 0
	var hp_total := 0
	for enemy in enemies:
		if bool(enemy.get("is_elite")):
			elites += 1
		hp_total += int(enemy.get("hp_max"))
	return {"enemies": enemies.size(), "elites": elites,
		"average_hp": float(hp_total) / float(maxi(1, enemies.size()))}
