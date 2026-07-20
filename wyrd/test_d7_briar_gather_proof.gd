extends SceneTree

# Exact authored Wayfinding no longer enters the old generic Green-practice
# detour. Before the first potentially empty Briar, D7 must therefore close any
# missing cumulative gathering evidence through real Town scanner channels.

const EvidenceScript = preload("res://data/d7_prior_saga_harvest_evidence.gd")

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
	print("--- D7 pre-Briar cumulative gather proof ---")
	var game = root.get_node_or_null("Game")
	game.persistence_enabled = false
	game.reset_to_defaults()
	game.persistence_enabled = false
	game.web_smoke_enabled = true
	game.web_smoke_d7_enabled = true
	game.web_smoke_phase = "briar_gather_probe"
	game.web_smoke_history = []
	game.web_smoke_features = {}
	# Keep scene-ready inert; this focused probe invokes only the exact pre-Briar
	# production helper after Town has built its real nodes.
	game._web_smoke_d7_stage = "briar_gather_probe"
	game._web_smoke_d7_training_seen_kinds = {}
	game.materials = {}
	game.seen_hints = {"vignette_arrival": true, "forage_node": true,
		"ore_rock": true, "log_pile": true}
	game.modal_count = 0
	paused = false
	OS.set_environment("WYRD_FAST_CHANNEL", "1")

	change_scene_to_file("res://scenes/Town.tscn")
	for _frame in 4:
		await process_frame
	await game._wait_d7_town_control()
	var materials_before: Dictionary = game.materials.duplicate(true)
	var trades_before: Dictionary = game.trades.duplicate(true)
	var proof_ok: bool = await game._d7_ensure_cumulative_gather_proof_before_briar()
	var receipt: Dictionary = game.web_smoke_features.get(
		"d7_cumulative_gather_proof", {}) as Dictionary
	var witnesses: Dictionary = receipt.get("first_witness_by_kind", {}) as Dictionary
	var evidence: Dictionary = EvidenceScript.evaluate({
		"scope": "briar_maze", "tier": 2,
		"affixes": [{"id": "mineral_vein", "good": false},
			{"id": "bramble_bloom", "good": false}],
	}, 0, 0, game._web_smoke_d7_training_seen_kinds)

	check("missing kinds are earned through one bounded production Town channel each",
		proof_ok and game.material_count("copper_ore") == 1
			and game.material_count("wild_herb") == 1
			and game.material_count("logs") == 1
			and game.materials != materials_before
			and game.trades != trades_before
			and game.web_smoke_phase != "failed",
		{"proof_ok": proof_ok, "materials": game.materials,
			"trades": game.trades, "phase": game.web_smoke_phase})
	check("central scanner completion records bounded first-witness provenance",
		bool(receipt.get("complete", false))
			and String(receipt.get("boundary", "")) == "before_first_briar"
			and (receipt.get("missing_before_boundary", []) as Array).size() == 3
			and witnesses.size() == 3
			and _all_witnesses_are_physical(witnesses), receipt)
	check("the same cumulative proof admits an authored zero-node Briar",
		bool(evidence.get("valid", false))
			and String(evidence.get("reason", "")) == "authored_empty_briar",
		evidence)

	game.web_smoke_d7_enabled = false
	OS.set_environment("WYRD_FAST_CHANNEL", "")
	print("--- D7 pre-Briar cumulative gather proof: %d PASS, %d FAIL ---" % [passed, failed])
	quit(1 if failed > 0 else 0)


func _all_witnesses_are_physical(witnesses: Dictionary) -> bool:
	for kind in EvidenceScript.REQUIRED_SCANNER_KINDS:
		var witness: Dictionary = witnesses.get(kind, {}) as Dictionary
		if String(witness.get("kind", "")) != kind \
				or String(witness.get("provenance", "")) != "d7_scanner_harvest" \
				or int(witness.get("delta", 0)) <= 0:
			return false
	return true
