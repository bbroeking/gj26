extends SceneTree

# Generator/production proof for deferred Pack Reader. These are real World
# instantiations: LayoutLoader chooses and configures every Combatant, and the
# assertion sums the exact Huntcraft award Combatant._die would pay.

const ChartsData = preload("res://data/charts.gd")
const Progression = preload("res://data/progression.gd")

const PRE_FIRE_HUNTCRAFT_XP_LOWER_BOUND := 2867
const SEEDS := [72001, 72002, 72003]

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
	print("--- D7 Ashen Huntcraft lower bound ---")
	var game := root.get_node_or_null("Game")
	game.persistence_enabled = false
	var awards: Array = []
	var world_scene: PackedScene = load("res://scenes/World.tscn")
	for seed_v in SEEDS:
		var seed := int(seed_v)
		var manifest := ChartsData.elite_manifest_for_chart(seed, "ashen_bough")
		game.active_chart = {"template_id": "ashen_bough", "recipe_id": "ashen_bough",
			"tier": 3, "den_level": 20, "scope": "ashen_bough",
			"name": "Ashen Bough", "seed": seed, "layer": 1, "max_layers": 1,
			"affixes": [{"id": "cinderbound", "good": true,
				"resolvedId": "cinderbound__good"}], "elite_manifest": manifest}
		var world := world_scene.instantiate()
		root.add_child(world)
		await process_frame
		await process_frame
		await physics_frame
		var award := 0
		for foe in get_nodes_in_group("enemy"):
			if foe != null and is_instance_valid(foe) \
					and String(foe.get("role")) != "boss":
				award += maxi(2, int(foe.get("hp_max")) / 3)
		awards.append(award)
		world.queue_free()
		await process_frame
		await process_frame
	var minimum_award := int(awards.min()) if not awards.is_empty() else 0
	check("three production Ashen packs earn Huntcraft 21 before World four",
		minimum_award >= 336
			and PRE_FIRE_HUNTCRAFT_XP_LOWER_BOUND + minimum_award * 3 \
				>= Progression.xp_for_level(21),
		{"awards": awards, "minimum": minimum_award,
			"before_four": PRE_FIRE_HUNTCRAFT_XP_LOWER_BOUND + minimum_award * 3,
			"level_21": Progression.xp_for_level(21)})
	game.active_chart = {}
	print("--- D7 Ashen Huntcraft lower bound: %d PASS, %d FAIL ---" % [passed, failed])
	quit(1 if failed > 0 else 0)
