extends SceneTree

# D7 split-gate contract. Entry requirements are checked independently from
# each later boss/making boundary, and Fire's exact XP lane is verified against
# authored completion rewards rather than a max-of-recipes mirror.

const GameScript = preload("res://scripts/game.gd")
const ChartsData = preload("res://data/charts.gd")
const GatherData = preload("res://data/gather.gd")
const CraftingData = preload("res://data/crafting.gd")
const Progression = preload("res://data/progression.gd")

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
	print("--- D7 split progressive production gates ---")
	var game = GameScript.new()
	var expected := {
		"golden_wallow": {"wayfinding": 9, "huntcraft": 1, "earthcraft": 1, "wildcraft": 10},
		"golden_wallow_boss": {"wayfinding": 12, "huntcraft": 1, "earthcraft": 1, "wildcraft": 10},
		"seventh_road": {"wayfinding": 15, "huntcraft": 1, "earthcraft": 3, "wildcraft": 3},
		"seventh_road_boss": {"wayfinding": 15, "huntcraft": 1, "earthcraft": 3, "wildcraft": 14},
		"queens_summit": {"wayfinding": 16, "huntcraft": 1, "earthcraft": 3, "wildcraft": 1},
		"queens_summit_boss": {"wayfinding": 17, "huntcraft": 1, "earthcraft": 3, "wildcraft": 1},
		"pale_oath": {"wayfinding": 18, "huntcraft": 1, "earthcraft": 18, "wildcraft": 18},
		"pale_oath_boss": {"wayfinding": 19, "huntcraft": 1, "earthcraft": 18, "wildcraft": 19},
		"fire_in_the_bough": {"wayfinding": 20, "huntcraft": 1, "earthcraft": 18, "wildcraft": 20},
	}
	var actual := {}
	for stage_v in expected:
		actual[stage_v] = game._d7_progressive_training_targets(String(stage_v))
	check("entry and pre-boss gates stay split", actual == expected, actual)
	check("gate numbers match their individual authored consumers",
		int(ChartsData.CHART_RECIPES.sallow_shallows.req_wayfinding) == 9
			and int(ChartsData.CHART_RECIPES.golden_wallow_boss.req_wayfinding) == 12
			and int(GatherData.INK_RECIPES.mire_ink.req_wildcraft) == 10
			and int(ChartsData.CHART_RECIPES.briar_maze.req_wayfinding) == 15
			and int(ChartsData.CHART_RECIPES.briar_maze.req_earthcraft) == 3
			and int(ChartsData.CHART_RECIPES.briar_maze.req_wildcraft) == 3
			and int(GatherData.INK_RECIPES.mothglow_ink.req_wildcraft) == 14
			and int(ChartsData.CHART_RECIPES.summit_approach.req_wayfinding) == 16
			and int(ChartsData.CHART_RECIPES.queens_summit_boss.req_wayfinding) == 17
			and int(ChartsData.CHART_RECIPES.pale_veins.req_wayfinding) == 18
			and int(ChartsData.CHART_RECIPES.pale_oath_boss.req_wayfinding) == 19)
	check("biome baselines expose native Mire and rootroad resources",
		GatherData.effective_biome_gather("mire") == ["mothmint"]
			and GatherData.effective_biome_gather("rootroads", ["wellwater"]) \
			== ["wildgold", "wellmoss", "wellwater"]
			and GatherData.effective_biome_gather("ashen_bough",
				["embersage", "wellwater"]) \
			== ["wildgold", "wellmoss", "embersage", "wellwater"])
	var refined_gate := GatherData.ink_trade_requirements("refined_ink")
	var nested_gate := GatherData.ink_trade_requirements("nested", {
		"nested": {"inputs": {"refined_ink": 1}, "req_wildcraft": 7},
		"refined_ink": GatherData.INK_RECIPES.refined_ink,
		"hedge_ink": GatherData.INK_RECIPES.hedge_ink,
	})
	var cycle_gate := GatherData.ink_trade_requirements("a", {
		"a": {"inputs": {"b": 1}}, "b": {"inputs": {"a": 1}},
	})
	check("raw and recursive Ink closures are pure and fail closed",
		int(GatherData.raw_material_trade_requirements("wildgold").earthcraft) == 18
			and int(GatherData.raw_material_trade_requirements("wellwater").wildcraft) == 19
			and int(refined_gate.earthcraft) == 3
			and int(nested_gate.earthcraft) == 3 and int(nested_gate.wildcraft) == 7
			and not bool(cycle_gate.valid) and int(cycle_gate.earthcraft) == 23
			and not bool(GatherData.ink_trade_requirements("missing").valid))
	var golden_entry := ChartsData.recipe_production_requirements("sallow_shallows")
	var briar_entry := ChartsData.recipe_production_requirements("briar_maze")
	var pale_entry := ChartsData.recipe_production_requirements("pale_veins")
	var pale_boss := ChartsData.recipe_production_requirements("pale_oath_boss")
	var fire_entry := ChartsData.recipe_production_requirements("ashen_bough")
	check("recipe production contracts fold Ink and generated gather gates",
		golden_entry.valid and int(golden_entry.wildcraft) == 10
			and briar_entry.valid and int(briar_entry.earthcraft) == 3 \
			and int(briar_entry.wildcraft) == 3
			and pale_entry.valid and int(pale_entry.earthcraft) == 18
			and int(pale_entry.wildcraft) == 18
			and int(pale_boss.earthcraft) == 18 and int(pale_boss.wildcraft) == 19
			and int(fire_entry.earthcraft) == 18 and int(fire_entry.wildcraft) == 20,
		{"golden_entry": golden_entry, "briar_entry": briar_entry, "pale_entry": pale_entry,
			"pale_boss": pale_boss, "fire": fire_entry})
	var first_state := Progression.normalize_trade_record({"xp": 75})
	check("Green discovery is the authored Prologue-to-First-Knot bridge",
		ChartsData.recipe_discovery_xp("green_hollow") == 93
			and ChartsData.recipe_discovery_xp("sallow_shallows") == 0
			and ChartsData.recipe_discovery_xp("first_knot_reprise") == 50)
	first_state = Progression.award_trade_xp(first_state,
		ChartsData.recipe_discovery_xp("green_hollow"))
	var first_preview := {"commit_ready": true, "recipe_id": "green_hollow",
		"output": {"template_id": "tier_1", "name": "Green Hollow"},
		"wayfinding_level": 3, "campaign_state_snapshot": game.campaign_state}
	var first_chart := ChartsData.materialize_chart(first_preview, 71001)
	check("first Green materializes before the level-4 clue is eligible",
		not first_chart.has("authored_completion_xp")
			and not first_chart.has("campaign_clue"), first_chart)
	game.trades = Progression.fresh_trade_state()
	game.trades.wayfinding = first_state
	var socketed_first: Dictionary = game._freeze_campaign_clue(first_chart)
	check("socket-time binding adds the missing first clue reward at real WF4",
		int(first_state.xp) == 168 and int(first_state.lv) == 4
			and int(socketed_first.get("authored_completion_xp", -1)) == 149
			and String((socketed_first.get("campaign_clue", {}) as Dictionary).get(
				"clue_id", "")) == "thorn_whisper_1", socketed_first)

	var xp := 75 + ChartsData.recipe_discovery_xp("green_hollow")
	for reward in ChartsData.CAMPAIGN_COMPLETION_XP.green_hollow:
		xp += int(reward)
	var first_boss_floor := xp
	xp += ChartsData.campaign_completion_xp_for("first_knot_boss")
	var first_settlement := xp
	var golden_ledger := [
		ChartsData.campaign_completion_xp_for("sallow_shallows", 0),
		ChartsData.campaign_completion_xp_for("deep_hollow"),
		ChartsData.campaign_completion_xp_for("sallow_shallows", 1),
		ChartsData.campaign_completion_xp_for("sallow_shallows", 2),
	]
	for reward in golden_ledger:
		xp += int(reward)
	var golden_boss_floor := xp
	xp += GatherData.ink_discovery_xp("mire_ink")
	xp += ChartsData.campaign_completion_xp_for("golden_wallow_boss")
	var golden_settlement := xp
	for i in 4:
		xp += ChartsData.campaign_completion_xp_for("briar_maze", i)
	xp += GatherData.ink_discovery_xp("mothglow_ink")
	xp += ChartsData.campaign_completion_xp_for("seventh_road_boss")
	var seventh_settlement := xp
	xp += GatherData.ink_discovery_xp("refined_ink")
	for i in 4:
		xp += ChartsData.campaign_completion_xp_for("summit_approach", i)
	var queen_boss_floor := xp
	xp += ChartsData.campaign_completion_xp_for("queens_summit_boss")
	var queen_settlement := xp
	xp += GatherData.ink_discovery_xp("stoneground_ink")
	for i in 4:
		xp += ChartsData.campaign_completion_xp_for("pale_veins", i)
	var pale_boss_floor := xp
	xp += ChartsData.campaign_completion_xp_for("pale_oath_boss")
	check("authored First Knot through Pale returns land every exact gate",
		first_boss_floor == 616 and first_settlement == 768
			and golden_ledger == [168, 200, 92, 92]
			and golden_boss_floor == 1320 and golden_settlement == 2016
			and seventh_settlement == 2280 and queen_boss_floor == 2560
			and queen_settlement == 2856 and pale_boss_floor == 3168
			and xp == 3496,
		{"first_boss": first_boss_floor, "first": first_settlement,
			"golden_ledger": golden_ledger, "golden_boss": golden_boss_floor,
			"golden": golden_settlement, "seventh": seventh_settlement,
			"queen_boss": queen_boss_floor, "queen": queen_settlement,
			"pale_boss": pale_boss_floor, "fire_entry": xp})
	var fire_entry_ledger: Dictionary = game.d7_fire_entry_wayfinding_ledger()
	var ledger_entries: Array = fire_entry_ledger.get("entries", [])
	var legacy_training_green := ChartsData.legacy_completion_xp({"tier": 1,
		"affixes": [{"id": "barren", "good": false}]})
	check("Fire entry derives 3496 from authored rewards and excludes the 85-XP practice Green",
		int(fire_entry_ledger.get("total", -1)) == 3496
			and int(fire_entry_ledger.get("total", -1)) == xp
			and ledger_entries.size() == 30
			and String((ledger_entries[0] as Dictionary).get("id", "")) == "snug_return"
			and String((ledger_entries[ledger_entries.size() - 1] as Dictionary).get("id", "")) == "pale_oath_boss"
			and legacy_training_green == 85
			and int(fire_entry_ledger.get("total", 0)) + legacy_training_green == 3581,
		{"authored": fire_entry_ledger, "legacy_training_green": legacy_training_green})
	game.web_smoke_d7_enabled = true
	game.trades = Progression.fresh_trade_state()
	game.award_xp("wayfinding", legacy_training_green,
		"chart_return:green_hollow")
	var award_receipts: Array = game.web_smoke_features.get(
		"d7_wayfinding_award_ledger", [])
	check("D7 award receipt exposes an unexpected legacy return by source and exact delta",
		award_receipts.size() == 1
			and award_receipts[0] == {"source": "chart_return:green_hollow",
				"amount": 85, "before_xp": 0, "after_xp": 85,
				"stage": "", "recipe_id": "", "chart_instance_id": "",
				"authored_reward": {}}, award_receipts)
	var deep_preview := {"commit_ready": true, "recipe_id": "deep_hollow",
		"output": {"template_id": "hollow", "name": "Deep Hollow"}}
	var deep := ChartsData.materialize_chart(deep_preview, 71002)
	var legacy_deep := deep.duplicate(true)
	legacy_deep.erase("authored_completion_xp")
	legacy_deep.erase("authored_completion_reward")
	check("new Deep freezes fixed 200 while legacy held Deep keeps ordinary math",
		int(deep.get("authored_completion_xp", -1)) == 200
			and String(ChartsData.authored_completion_reward(deep).get("kind", "")) == "fixed"
			and ChartsData.completion_xp(legacy_deep) \
				== ChartsData.legacy_completion_xp(legacy_deep),
		{"new": deep, "legacy": legacy_deep})
	var verse_rewards: Array = ChartsData.CHART_RECIPES.ashen_bough.campaign_xp.clue_rewards
	var verse_total := 0
	for reward in verse_rewards:
		verse_total += int(reward)
	var boss_reward := int(ChartsData.CHART_RECIPES.fire_in_the_bough_boss.campaign_xp.completion_xp)
	check("Fire exact earned lane is 3496 → 3840 → 4200",
		Progression.xp_for_level(20) == 3496
			and 3496 + verse_total == 3840
			and 3840 + boss_reward == 4200,
		{"verses": verse_rewards, "boss": boss_reward})
	check("Fire entry prepares the generated biome and later Emberleaf gates",
		int(GatherData.INK_RECIPES.emberleaf_ink.req_wildcraft) == 20
			and int(CraftingData.RECIPES.starheart_alloy.req_lv) == 20
			and int(actual.fire_in_the_bough.wildcraft) == 20
			and int(actual.fire_in_the_bough.earthcraft) == 18)
	check("late Ink discovery overrides preserve ordinary 50-XP experiments",
		GatherData.ink_discovery_xp("ash_ink") == 0
			and GatherData.ink_discovery_xp("emberleaf_ink") == 0
			and GatherData.ink_discovery_xp("mire_ink") == 50
			and GatherData.ink_discovery_xp("refined_ink") == 50)
	var runtime_game := root.get_node_or_null("Game")
	runtime_game.persistence_enabled = false
	runtime_game.web_smoke_features = {}
	runtime_game.trades = Progression.fresh_trade_state()
	var manifest := ChartsData.elite_manifest_for_chart(71003, "ashen_bough")
	runtime_game.active_chart = {"recipe_id": "ashen_bough",
		"elite_manifest": manifest.duplicate(true)}
	runtime_game.trades.huntcraft = {"xp": Progression.xp_for_level(20), "lv": 20}
	var deferred_ok: bool = runtime_game._d7_observe_pack_reader_manifest(manifest, 1)
	var plate := Label3D.new()
	plate.add_to_group("pack_reader_manifest")
	root.add_child(plate)
	runtime_game.trades.huntcraft = {"xp": Progression.xp_for_level(21), "lv": 21}
	var reveal_ok: bool = runtime_game._d7_observe_pack_reader_manifest(manifest, 4)
	var pack_receipt: Dictionary = runtime_game.web_smoke_features.get(
		"d7_pack_reader_deferred_reveal", {})
	check("Pack Reader defers while locked then reveals the same frozen manifest",
		deferred_ok and reveal_ok
			and (pack_receipt.get("deferred_worlds", []) as Array) == [1]
			and int(pack_receipt.get("revealed_world", 0)) == 4
			and String(pack_receipt.get("seed_fingerprint", "")) \
				== String(manifest.get("seed_fingerprint", ""))
			and bool(runtime_game.web_smoke_features.get(
				"d7_pack_reader_zero_rng_manifest", false)), pack_receipt)
	plate.queue_free()
	game.web_smoke_features["d7_progressive_training_receipt"] = {"stages_started": 2}
	game._web_smoke_d7_training = {"runs": 2, "world_legs": 2,
		"town_settlements": 2, "forge_crafts": 3, "practice_recipe": "green_hollow"}
	game._d7_complete_progressive_practice_receipt("golden_wallow_boss",
		expected.golden_wallow_boss)
	game._web_smoke_d7_training = {"runs": 1, "world_legs": 1,
		"town_settlements": 1, "forge_crafts": 4, "practice_recipe": "green_hollow"}
	game._d7_complete_progressive_practice_receipt("queens_summit_boss",
		expected.queens_summit_boss)
	var receipt: Dictionary = game.web_smoke_features.d7_progressive_training_receipt
	check("practice receipt remains cumulative across split stages",
		(receipt.practice_stages as Array).size() == 2
			and int(receipt.runs_cumulative) == 3
			and int(receipt.world_legs_cumulative) == 3
			and int(receipt.town_settlements_cumulative) == 3, receipt)
	check("unknown resume stages fail closed", game._d7_progressive_training_targets("unknown").is_empty())
	var invalid_game = GameScript.new()
	invalid_game.persistence_enabled = false
	invalid_game.web_smoke_enabled = true
	invalid_game.web_smoke_d7_enabled = true
	var invalid_targets := {"valid": false, "reason": "synthetic_recipe_cycle",
		"wayfinding": 23, "huntcraft": 23, "earthcraft": 23, "wildcraft": 23}
	check("mapped invalid requirements cannot vacuously complete and fail the route",
		not invalid_game._d7_training_complete(invalid_targets)
			and invalid_game.web_smoke_phase == "failed",
		{"phase": invalid_game.web_smoke_phase})
	check("empty requirements cannot vacuously complete",
		not invalid_game._d7_training_complete({}))
	invalid_game.free()
	game.free()
	print("--- D7 split progressive gates: %d PASS, %d FAIL ---" % [passed, failed])
	quit(1 if failed > 0 else 0)
