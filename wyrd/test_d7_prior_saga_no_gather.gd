extends SceneTree

# D7 release regression: a Briar Maze can correctly realize no GatherNodes
# when every gather-bias Affix resolves to its bad twin (or to a non-gather
# modifier).  That is not a scanner failure.  The narrow exception must never
# hide a missing native biome guarantee or a failed real node interaction.

const EvidenceScript = preload("res://data/d7_prior_saga_harvest_evidence.gd")
const DungeonGen = preload("res://scripts/dungeon_gen.gd")
const ChartsData = preload("res://data/charts.gd")

var passed := 0
var failed := 0
var all_scanner_kinds := {"ore_rock": true, "forage_node": true, "log_pile": true}


func check(label: String, condition: bool, detail = null) -> void:
	if condition:
		passed += 1
		print("  PASS  ", label)
	else:
		failed += 1
		push_error("  FAIL  %s :: %s" % [label, str(detail)])


func _init() -> void:
	print("\n=== D7 prior-saga no-gather contract ===")
	var all_bad_briar := {
		"scope": "briar_maze", "tier": 2,
		"affixes": [{"id": "mineral_vein", "good": false},
			{"id": "bramble_bloom", "good": false}],
	}
	var empty_briar := EvidenceScript.evaluate(all_bad_briar, 0, 0, all_scanner_kinds)
	check("zero-node bad-twin Briar passes and records its authored empty leg",
		bool(empty_briar.get("valid", false)) \
			and bool(empty_briar.get("record_authored_no_gather", false)), empty_briar)
	var first_receipt := EvidenceScript.append_authored_empty_briar_receipt([], \
		{"recipe_id": "briar_maze"}, all_bad_briar, 0, 0)
	var second_receipt := EvidenceScript.append_authored_empty_briar_receipt(first_receipt, \
		{"recipe_id": "briar_maze_repeat"}, all_bad_briar, 0, 0)
	check("empty Briar receipts append instead of overwriting prior-leg evidence",
		second_receipt.size() == 2 \
			and String((second_receipt[0] as Dictionary).get("recipe_id", "")) == "briar_maze" \
			and String((second_receipt[1] as Dictionary).get("recipe_id", "")) == "briar_maze_repeat",
		second_receipt)
	var visible_unharvested := EvidenceScript.evaluate(all_bad_briar, 1, 0, all_scanner_kinds)
	check("a visible GatherNode with zero material delta still fails",
		not bool(visible_unharvested.get("valid", true)) \
			and String(visible_unharvested.get("reason", "")) == "visible_gather_uncompleted",
		visible_unharvested)
	var missing_cumulative := EvidenceScript.evaluate(all_bad_briar, 0, 0,
		{"ore_rock": true, "forage_node": true})
	check("zero-node Briar without earlier scanner gathering proof fails",
		not bool(missing_cumulative.get("valid", true)) \
			and String(missing_cumulative.get("reason", "")) == "missing_cumulative_gather_proof",
		missing_cumulative)

	var good_gather_briar := all_bad_briar.duplicate(true)
	good_gather_briar.affixes = [{"id": "mineral_vein", "good": true},
		{"id": "echoing", "good": false}]
	var good_affix_zero := EvidenceScript.evaluate(good_gather_briar, 0, 0, all_scanner_kinds)
	check("a zero-node Briar with a good gather Affix fails",
		not bool(good_affix_zero.get("valid", true)) \
			and String(good_affix_zero.get("reason", "")) == "not_authored_empty",
		good_affix_zero)

	var chest_only_briar := all_bad_briar.duplicate(true)
	chest_only_briar.affixes = [{"id": "gilded", "good": true},
		{"id": "echoing", "good": false}]
	var chest_only := EvidenceScript.evaluate(chest_only_briar, 0, 0, all_scanner_kinds)
	check("a Gilded chest is not mistaken for a GatherNode",
		bool(chest_only.get("valid", false)) \
			and bool(chest_only.get("record_authored_no_gather", false)), chest_only)

	var native_hollow := all_bad_briar.duplicate(true)
	native_hollow.scope = "hollow"
	native_hollow.required_biome_gather = ["copper", "wild", "logs"]
	var native_zero := EvidenceScript.evaluate(native_hollow, 0, 0, all_scanner_kinds)
	check("a native biome resource promise blocks the exception",
		not bool(native_zero.get("valid", true)) \
			and String(native_zero.get("reason", "")) == "not_authored_empty",
		native_zero)

	var mire := all_bad_briar.duplicate(true)
	mire.scope = "mire"
	var mire_zero := EvidenceScript.evaluate(mire, 0, 0, all_scanner_kinds)
	check("Mire's authored Mothmint promise blocks the exception",
		not bool(mire_zero.get("valid", true)) \
			and String(mire_zero.get("reason", "")) == "not_authored_empty", mire_zero)

	var completed := EvidenceScript.evaluate(good_gather_briar, 1, 1, {})
	check("a completed production gather passes without the empty-road record",
		bool(completed.get("valid", false)) \
			and not bool(completed.get("record_authored_no_gather", true)), completed)

	var briar_gen: Dictionary = (ChartsData.TEMPLATES.briar_maze.gen as Dictionary).duplicate(true)
	briar_gen.merge({"scope": "briar_maze", "tier": 2}, true)
	var affix_anchor_cases := {
		"mineral_vein": {"tier_key": "ore_tier", "tier": "bogiron",
			"min_count": 3, "max_count": 5},
		"bramble_bloom": {"tier_key": "herb_tier", "tier": "bittergrass",
			"min_count": 4, "max_count": 6},
	}
	for affix_id_v in affix_anchor_cases:
		var affix_id := String(affix_id_v)
		var expected: Dictionary = affix_anchor_cases[affix_id]
		var cfg := briar_gen.duplicate(true)
		cfg["affixes"] = [{"id": affix_id, "good": true}]
		var layout := DungeonGen.generate(73000 + affix_id.length(), cfg)
		var nodes: Array = (layout.get("decor", []) as Array).filter(func(entry_v):
			return entry_v is Dictionary \
				and String((entry_v as Dictionary).get("source_affix", "")) == affix_id)
		check("a good %s keeps its authored count and deterministic accessible anchor" % affix_id,
			nodes.size() >= int(expected.min_count) and nodes.size() <= int(expected.max_count) \
				and String((nodes[0] as Dictionary).get(String(expected.tier_key), "")) \
					== String(expected.tier), nodes)

	print("=== %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)
