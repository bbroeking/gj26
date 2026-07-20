extends SceneTree

# Integrated Fire route seam: physical Lift knowledge, frozen manifest flow,
# real generated Giant/chain World, exact settlement, and restored Kiln craft.

const CampaignData = preload("res://data/campaign.gd")
const ChartsData = preload("res://data/charts.gd")
const Progression = preload("res://data/progression.gd")
const DungeonGen = preload("res://scripts/dungeon_gen.gd")
const GatherNodeScript = preload("res://scripts/gather_node.gd")

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


func prior_pale_state() -> Dictionary:
	var state := CampaignData.empty_state()
	for chapter_id in [CampaignData.FIRST_KNOT, CampaignData.GOLDEN_WALLOW,
			CampaignData.SEVENTH_ROAD, CampaignData.QUEENS_SUMMIT, CampaignData.PALE_OATH]:
		var chapter: Dictionary = state.chapters[chapter_id]
		chapter.cleared = true
		chapter.clue_count = int(CampaignData.CHAPTERS[chapter_id].clue_target)
		for i in int(chapter.clue_count):
			chapter.banked_chart_ids.append("%s-%d" % [chapter_id, i])
	state.relics = ["green_root_rune", "mist_root_rune", "fang_root_rune",
		"crown_root_rune", "pale_root_rune"]
	state.threads = ["past_thread"]
	state.restorations = ["trophy_hall", "sallow_jetty", "skald_archive",
		"pale_stair", "rootroad_lift"]
	return CampaignData.normalize_campaign_state(state)


func run() -> void:
	print("--- Fire in the Bough integrated World ---")
	var game := root.get_node_or_null("Game")
	game.persistence_enabled = false
	game.reset_to_defaults()
	game.persistence_enabled = false
	game.materials = {}
	game.campaign_state = prior_pale_state()
	game.trades.wayfinding = {"xp": Progression.xp_for_level(20), "lv": 20}
	game.trades.huntcraft = {"xp": Progression.xp_for_level(21), "lv": 21}
	game._sync_campaign_chart_sources()

	var before_materials: Dictionary = game.materials.duplicate(true)
	var ordinary_read: Dictionary = game.read_chart_source("rootroad_lift_ashen_bough")
	check("eligible Lift read teaches the ordinary folio exactly once with no supplies",
		bool(ordinary_read.changed) and String(ordinary_read.recipe_granted) == "ashen_bough"
			and game.chart_recipe_known("ashen_bough") and game.materials == before_materials
			and String(game.chart_recipe_journal.discoveries.get("ashen_bough", "")) \
				== "source_lesson", ordinary_read)
	var repeat_read: Dictionary = game.read_chart_source("rootroad_lift_ashen_bough")
	check("ordinary Lift reread is mutation-free", not bool(repeat_read.changed))

	var fire: Dictionary = game.campaign_state.chapters[CampaignData.FIRE_IN_THE_BOUGH]
	fire.clue_count = 5
	for i in 5:
		fire.banked_chart_ids.append("ashen-return-%d" % i)
	game.campaign_state = CampaignData.normalize_campaign_state(game.campaign_state)
	game.trades.wayfinding = {"xp": Progression.xp_for_level(21), "lv": 21}
	game._sync_campaign_chart_sources()
	# The fifth real return records the boss rumour before the player reaches
	# the Lift. Its physical folio must remain actionable from that `read` state.
	game._remember_chart_rumour(CampaignData.FIRE_IN_THE_BOUGH_RUMOUR)
	var heard_boss_status: Dictionary = game.chart_source_status(
		"rootroad_lift_hearth_giant")
	var boss_read: Dictionary = game.read_chart_source("rootroad_lift_hearth_giant")
	check("Verse V's already-heard rumour remains actionable at the physical Giant folio",
		String(heard_boss_status.state) == "read" and bool(boss_read.changed) \
			and String(boss_read.recipe_granted) \
			== "fire_in_the_bough_boss" and game.chart_recipe_known("fire_in_the_bough_boss")
			and game.materials == before_materials, boss_read)

	var manifest := ChartsData.elite_manifest_for_chart(202107, "ashen_bough")
	game.active_chart = {"template_id": "ashen_bough", "recipe_id": "ashen_bough",
		"tier": 3, "scope": "ashen_bough", "name": "Ashen Bough", "seed": 202107,
		"affixes": [{"id": "cinderbound", "good": true,
			"resolvedId": "cinderbound__good"}], "elite_manifest": manifest}
	game.materials = {}
	var first_required: String = String(game._d7_required_harvest_item())
	game.materials = {"embersage": 2}
	var second_required: String = String(game._d7_required_harvest_item())
	game.materials = {"embersage": 2, "wellwater": 1}
	var third_required: String = String(game._d7_required_harvest_item())
	game.materials = {"embersage": 2, "wellwater": 1, "wildgold_ore": 2}
	var fourth_required: String = String(game._d7_required_harvest_item())
	game.materials = {"embersage": 2, "wellwater": 1,
		"wildgold_ore": 2, "wildgold_bar": 1}
	var finished_required: String = String(game._d7_required_harvest_item())
	check("release harvesting prioritizes every renewable Fire input across real roads",
		first_required == "embersage" and second_required == "wellwater"
			and third_required == "wildgold_ore"
			and fourth_required == "wildgold_ore" and finished_required == "",
		{"first": first_required, "second": second_required,
			"third": third_required, "fourth": fourth_required,
			"finished": finished_required})
	var cfg: Dictionary = game.run_cfg()
	var layout: Dictionary = DungeonGen.generate(202107, cfg)
	check("run config and generator preserve the frozen manifest byte-for-byte",
		cfg.elite_manifest == manifest and layout.elite_manifest == manifest
			and (layout.decor as Array).filter(func(d):
				return String(d.get("item", "")) == "embersage").size() == 2
			and (layout.decor as Array).filter(func(d):
				return String(d.get("item", "")) == "wellwater").size() == 1)
	check("Pack Reader reveals that manifest without changing it",
		game.pack_reader_view().duplicate(true).get("modifier_id", "") == manifest.modifier_id
			and game.active_chart.elite_manifest == manifest)

	# Open the real protected attempt and let the generated World own the
	# non-lethal Giant-to-settlement callback.
	var chart_id := "fire-world-chart"
	var begun: Dictionary = CampaignData.begin_boss_escrow(
		game.campaign_state, chart_id, CampaignData.FIRE_IN_THE_BOUGH)
	var entered: Dictionary = CampaignData.mark_escrow_in_run(
		begun.state, String(begun.attempt_id), chart_id, CampaignData.FIRE_IN_THE_BOUGH)
	game.campaign_state = entered.state
	game.materials = {"starheart_coal": 3}
	game.active_chart = {
		"template_id": "fire_in_the_bough_boss", "recipe_id": "fire_in_the_bough_boss",
		"chart_instance_id": chart_id, "attempt_id": String(begun.attempt_id),
		"tier": 3, "scope": "ashen_bough", "name": "Fire in the Bough",
		"seed": 212300, "affixes": [],
		"campaign_contract": CampaignData.boss_contract("fire_in_the_bough_boss"),
	}
	game.in_dungeon = true
	var world_scene: PackedScene = load("res://scenes/World.tscn")
	var world := world_scene.instantiate()
	root.add_child(world)
	current_scene = world
	await process_frame
	await process_frame
	await physics_frame
	var giant := get_first_node_in_group("enemy")
	for enemy in get_nodes_in_group("enemy"):
		if String(enemy.get("kind")) == "hearth_giant":
			giant = enemy
			break
	var controller := world.get_node_or_null("HearthGiantEncounter")
	var chains := get_nodes_in_group("hearth_chain")
	check("generated Fire World mounts the real Giant controller and three physical chains",
		giant != null and controller != null and chains.size() == 3,
		{"giant": giant, "controller": controller, "chains": chains.size()})
	var player := game.local_player() as Node3D
	var all_banked := giant != null and controller != null and player != null
	if all_banked:
		for phase in 3:
			giant.take_damage(99999, Vector3.FORWARD)
			var expected_id := String(controller.CHAIN_ORDER[phase])
			var chain: Node3D = controller.chains[expected_id]
			if phase == 0:
				var wrong_chain: Node3D = controller.chains["braided_link"]
				var wrong_mask_before := int(controller.bank_mask)
				all_banked = await game._d6_scanner_interact(wrong_chain) and all_banked
				all_banked = int(controller.bank_mask) == wrong_mask_before and all_banked
			all_banked = await game._d6_scanner_interact(chain) and all_banked
			await process_frame
	check("scanner/InputMap banks all three exact physical chains after one recoverable wrong choice",
		all_banked and bool(giant.get("kneeling")) and not bool(giant.get("dead"))
			and (controller.chains.values() as Array).all(func(chain):
				return bool(chain.call("is_used")))
			and CampaignData.chapter_cleared(game.campaign_state, CampaignData.FIRE_IN_THE_BOUGH)
			and game.material_count("starheart_coal") == 0
			and game.material_count("wyrm_scale") == 1
			and (game.campaign_state.relics as Array).has("ember_root_rune")
			and (game.campaign_state.threads as Array).has("present_thread")
			and (game.campaign_state.restorations as Array).has("ember_kiln"),
		game._web_smoke_d7_last_chain_action_detail)

	game.trades.earthcraft = {"xp": Progression.xp_for_level(20), "lv": 20}
	game.seen_hints["ore_rock"] = true
	var vein: Node3D = GatherNodeScript.new()
	vein.setup("ore_rock", "wildgold_ore")
	vein.setup_ore_tier("wildgold")
	root.add_child(vein)
	var ore_before: int = game.material_count("wildgold_ore")
	vein._harvest(player)
	var ore_delta: int = game.material_count("wildgold_ore") - ore_before
	check("Rich Seams makes every renewable Wildgold harvest worth at least two ore",
		ore_delta >= 2, {"delta": ore_delta, "materials": game.materials})
	vein.queue_free()
	game.materials["wildgold_bar"] = 2
	game.materials["emberglass"] = 2
	var alloy_before: int = int(game.material_count("starheart_alloy"))
	var crafted: bool = bool(game.craft("ember_kiln", "starheart_alloy"))
	check("restored Ember Kiln makes renewable Alloy through the normal craft mutation",
		crafted and game.material_count("starheart_alloy") == alloy_before + 1)

	world.queue_free()
	await process_frame
	await _shutdown_runtime()
	print("--- Fire World: %d PASS, %d FAIL ---" % [passed, failed])
	quit(1 if failed > 0 else 0)


func _shutdown_runtime() -> void:
	# Headless SceneTree.quit() does not wait for active SFX playback or a
	# real-time hitstop timer. Drain both after the World has left the tree.
	var sfx := root.get_node_or_null("Sfx")
	if sfx != null and sfx.has_method("shutdown"):
		sfx.call("shutdown")
	Engine.time_scale = 1.0
	await create_timer(0.25, true, false, true).timeout
	await process_frame
