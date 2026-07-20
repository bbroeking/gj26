extends SceneTree

# Regression for D7's scanner-action boundary: a GatherNode and a Second Hand
# clue deliberately overlap the player scanner. The released InputMap action
# must still reach the intended GatherNode, never read/record the optional
# mark or leave its dialog modal behind.

const SecondHandClueScript = preload("res://scripts/second_hand_clue.gd")
const GatherNodeScript = preload("res://scripts/gather_node.gd")

var passed := 0
var failed := 0


# These probes release a real GatherNode on the two scanner yield boundaries.
# They do not alter the scanner or PlayerController: each observes a production
# receipt/material transaction and asks Godot to free the node on its normal
# deferred deletion edge.
class ReleaseTargetAfterReceipt:
	extends Node
	var player: Node3D
	var target: Node3D
	var released := false

	func _physics_process(_delta: float) -> void:
		if released or player == null or target == null or not is_instance_valid(player) \
				or not is_instance_valid(target):
			return
		var receipt: Dictionary = player.call("last_interact_receipt") \
			if player.has_method("last_interact_receipt") else {}
		if String(receipt.get("status", "")) == "actual" and receipt.get("actual") == target:
			released = true
			target.queue_free()
			set_physics_process(false)


class ReleaseTargetAfterHarvest:
	extends Node
	var game: Node
	var target: Node3D
	var item_id := ""
	var material_before := 0
	var released := false

	func _process(_delta: float) -> void:
		if released or game == null or target == null or not is_instance_valid(target):
			return
		if game.material_count(item_id) > material_before:
			released = true
			target.queue_free()
			set_process(false)


# A deliberately inert production-Interactable seam for the scanner test. It
# has the same Area3D/PlayerController path as an Atlas or GatherNode, without
# consuming a Town resource or mutating campaign state when its released E edge
# is accepted.
class StrictScanProbe:
	extends Interactable
	var interact_count := 0

	func get_prompt_text() -> String:
		return "[E] Inspect the scanner probe"

	func get_collision_radius() -> float:
		return 0.9

	func get_collision_offset() -> Vector3:
		return Vector3(0.0, 0.2, 0.0)

	func get_solid_radius() -> float:
		return 0.0

	func interact(_player: Node) -> void:
		interact_count += 1


# The clue begins well outside the scanner, then enters on the first settle
# physics edge after the strict scan has chosen its point. This reproduces the
# Atlas failure mode without bypassing PlayerController or calling interact
# directly.
class DelayedCompetitor:
	extends Node
	var clue: Node3D
	var destination := Vector3.ZERO
	var armed := false
	var moved := false

	func _physics_process(_delta: float) -> void:
		if not armed or moved or clue == null or not is_instance_valid(clue):
			return
		clue.global_position = destination
		moved = true
		set_physics_process(false)


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
	print("--- D7 scanner target-integrity ---")
	Engine.time_scale = 6.0
	var game = root.get_node_or_null("Game")
	game.persistence_enabled = false
	game.reset_to_defaults()
	game.persistence_enabled = false
	game.web_smoke_enabled = true
	game.web_smoke_d7_enabled = true
	game.web_smoke_phase = "target_integrity_probe"
	game.modal_count = 0
	paused = false
	# The test is about competing targets, not the normal first-forage lesson.
	game.seen_hints = {"forage_node": true}

	change_scene_to_file("res://scenes/Town.tscn")
	await process_frame
	await process_frame
	await game._wait_d7_town_control()
	var player := game.local_player() as Node3D
	var target: Node3D = find_live_herb([])
	if player == null or target == null:
		check("Town exposes a live player and production Wild Herb target", false)
		await shutdown_runtime()
		quit(1)
		return

	# All legal positions here start with no competitor, which means every scan
	# sample has an INF margin. The selector must choose the close (0.85m) end,
	# not the first 3.8m boundary. A delayed mark then appears on the opposite
	# side during the final settle; it is genuinely present but still farther than
	# the probe, so PlayerController should accept only the intended released E.
	var strict_probe := StrictScanProbe.new()
	strict_probe.name = "D7StrictMarginTieProbe"
	current_scene.add_child(strict_probe)
	strict_probe.global_position = target.global_position + Vector3(50.0, 0.0, 50.0)
	await physics_frame
	await process_frame
	var delayed_mark: Node3D = SecondHandClueScript.new()
	delayed_mark.name = "D7DelayedStrictMarginMark"
	delayed_mark.setup("far_waystone", "etched_stone")
	current_scene.add_child(delayed_mark)
	delayed_mark.global_position = strict_probe.global_position + Vector3(20.0, 0.0, 20.0)
	var delayed_competitor := DelayedCompetitor.new()
	delayed_competitor.clue = delayed_mark
	delayed_competitor.destination = strict_probe.global_position + Vector3(-0.35, 0.0, 0.0)
	current_scene.add_child(delayed_competitor)
	var strict_probe_home := player.global_position
	player.global_position.y = strict_probe.global_position.y - 0.2
	await physics_frame
	await process_frame
	var tie_position: Dictionary = await game._d7_find_strict_target_position(
		player, strict_probe, player.global_position)
	var tie_distance := player.global_position.distance_to(strict_probe.global_position)
	delayed_competitor.armed = true
	var tie_action_accepted: bool = await game._d7_press_interact_for_target(player, strict_probe)
	await process_frame
	check("INF-margin scan chooses the close legal point and survives a delayed farther mark",
		bool(tie_position.get("found", false)) and is_inf(float(tie_position.get("margin", 0.0)))
			and tie_distance <= 0.95
			and delayed_competitor.moved and tie_action_accepted
			and strict_probe.interact_count == 1
			and not game.has_second_hand_clue("far_waystone")
			and game.modal_count == 0 and not paused,
		{"position": tie_position, "distance": tie_distance,
			"moved": delayed_competitor.moved,
			"receipt": player.call("last_interact_receipt") if player.has_method("last_interact_receipt") else {},
			"probe_interactions": strict_probe.interact_count,
			"second_hand": game.second_hand_clues})
	player.global_position = strict_probe_home
	if player is CharacterBody3D:
		(player as CharacterBody3D).velocity = Vector3.ZERO
	strict_probe.queue_free()
	delayed_mark.queue_free()
	delayed_competitor.queue_free()
	await physics_frame
	await process_frame

	var mark: Node3D = SecondHandClueScript.new()
	mark.name = "D7CompetingSecondHandMark"
	mark.setup("far_waystone", "etched_stone")
	current_scene.add_child(mark)
	# This offset makes the mark overlap the same scanner volume while leaving a
	# legitimate approach side where the herb is strictly nearer.
	mark.global_position = target.global_position + Vector3(0.35, 0.0, 0.0)
	await physics_frame
	await process_frame
	target.set("_tier_channel", 0.01)
	var natural_home := player.global_position
	var strict_position: Dictionary = await game._d7_find_strict_target_position(
		player, target, player.global_position)
	check("scanner finds a legal side where the GatherNode is strictly nearest",
		bool(strict_position.get("found", false)),
		{"position": strict_position, "active": player.get("_active_interactable"),
			"player_position": player.global_position, "target": target,
			"target_position": target.global_position,
			"overlaps": player.get("_overlapping_interactables")})
	# The integrated harvest must begin from its ordinary outside position, not
	# from the helper's already-selected safe side.
	player.global_position = natural_home
	if player is CharacterBody3D:
		(player as CharacterBody3D).velocity = Vector3.ZERO
	await physics_frame
	await process_frame
	var before: int = game.material_count("wild_herb")
	var harvested: bool = await game._d7_scanner_harvest(target, "wild_herb", 1500)
	await process_frame

	check("InputMap interaction reaches only the strictly-nearest GatherNode",
		harvested and game.material_count("wild_herb") == before + 1
			and player.has_method("last_interacted") and player.call("last_interacted") == target,
		{"active": player.get("_active_interactable"),
			"last": player.call("last_interacted") if player.has_method("last_interacted") else null})
	check("competing Second Hand mark stays unread and opens no modal",
		not game.has_second_hand_clue("far_waystone") and game.modal_count == 0 and not paused,
		{"second_hand": game.second_hand_clues, "modal_count": game.modal_count,
			"paused": paused})

	# Force the final input-edge race: an exactly coincident mark has just become
	# the scanner's active target after D7 armed the herb expectation. This still
	# sends the released InputMap action through PlayerController; the guard must
	# refuse before either object's `interact` callback can mutate campaign/UI.
	var edge_mark: Node3D = SecondHandClueScript.new()
	edge_mark.name = "D7ExactCoincidentSecondHandMark"
	edge_mark.setup("far_waystone", "etched_stone")
	current_scene.add_child(edge_mark)
	edge_mark.global_position = target.global_position
	await physics_frame
	await process_frame
	var materials_before_edge: int = game.material_count("wild_herb")
	player.set("_active_interactable", edge_mark)
	var armed := bool(player.call("arm_expected_interact", target)) \
		if player.has_method("arm_expected_interact") else false
	Input.action_press(&"interact")
	await physics_frame
	Input.action_release(&"interact")
	await process_frame
	var edge_receipt: Dictionary = player.call("last_interact_receipt") \
		if player.has_method("last_interact_receipt") else {}
	check("exact-coincident retarget is refused before it can read the mark",
		armed and String(edge_receipt.get("status", "")) == "refused_target_mismatch"
			and edge_receipt.get("actual") == edge_mark
			and not game.has_second_hand_clue("far_waystone")
			and game.material_count("wild_herb") == materials_before_edge
			and game.modal_count == 0 and not paused,
		{"receipt": edge_receipt, "second_hand": game.second_hand_clues,
			"modal_count": game.modal_count})

	# The expected target can disappear after D7 arms it but before PlayerController
	# consumes the InputMap edge. Keep the clue active to prove this is fail-closed
	# rather than falling through to a legitimate-looking current prompt.
	var doomed_target: Node3D = SecondHandClueScript.new()
	doomed_target.name = "D7FreedExpectedTarget"
	doomed_target.setup("inked_scrap", "etched_stone")
	current_scene.add_child(doomed_target)
	await process_frame
	var materials_before_freed: int = game.material_count("wild_herb")
	var armed_freed := bool(player.call("arm_expected_interact", doomed_target)) \
		if player.has_method("arm_expected_interact") else false
	doomed_target.queue_free()
	await process_frame
	player.set("_active_interactable", edge_mark)
	Input.action_press(&"interact")
	await physics_frame
	Input.action_release(&"interact")
	await process_frame
	var freed_receipt: Dictionary = player.call("last_interact_receipt") \
		if player.has_method("last_interact_receipt") else {}
	check("freed expected target refuses the InputMap edge before the active mark",
		armed_freed and String(freed_receipt.get("status", "")) == "refused_expected_invalid"
			and not game.has_second_hand_clue("far_waystone")
			and not game.has_second_hand_clue("inked_scrap")
			and game.material_count("wild_herb") == materials_before_freed
			and game.modal_count == 0 and not paused,
		{"receipt": freed_receipt, "second_hand": game.second_hand_clues,
			"modal_count": game.modal_count})

	# Regression: the action helper itself yields through its input/process
	# boundary.  Release a real herb after PlayerController records the intended
	# action, but before `_d7_scanner_harvest` resumes.  The scanner must label
	# that exact post-await release invalid rather than downgrading it to an
	# ordinary unaccepted input.
	var post_press_target: Node3D = find_live_herb([target])
	if post_press_target != null:
		post_press_target.set("_tier_channel", 0.01)
		var release_after_receipt := ReleaseTargetAfterReceipt.new()
		release_after_receipt.player = player
		release_after_receipt.target = post_press_target
		current_scene.add_child(release_after_receipt)
		player.global_position = natural_home
		await physics_frame
		var post_press_harvested: bool = await game._d7_scanner_harvest(
			post_press_target, "wild_herb", 1200)
		await process_frame
		var post_press_detail: Dictionary = game._web_smoke_d7_last_harvest_detail
		check("freed immediately after the press helper yields fails scanner closed",
			release_after_receipt.released and not post_press_harvested
				and String(post_press_detail.get("outcome", "")) == "scanner_target_invalid"
				and game.modal_count == 0 and not paused,
			{"detail": post_press_detail, "released": release_after_receipt.released,
				"modal_count": game.modal_count})
	else:
		check("Town exposes a second live Wild Herb for post-press release coverage", false)

	# Regression: after a genuine GatherNode transaction, the scanner returns to
	# its home position and yields one final physics edge.  Release the node only
	# after its material appears; the result must still be false/invalid rather
	# than returning a stale `completed` success.
	var post_return_target: Node3D = find_live_herb([target])
	if post_return_target != null:
		post_return_target.set("_tier_channel", 0.01)
		var post_return_before: int = game.material_count("wild_herb")
		var release_after_harvest := ReleaseTargetAfterHarvest.new()
		release_after_harvest.game = game
		release_after_harvest.target = post_return_target
		release_after_harvest.item_id = "wild_herb"
		release_after_harvest.material_before = post_return_before
		current_scene.add_child(release_after_harvest)
		player.global_position = natural_home
		await physics_frame
		var post_return_harvested: bool = await game._d7_scanner_harvest(
			post_return_target, "wild_herb", 1200)
		await process_frame
		var post_return_detail: Dictionary = game._web_smoke_d7_last_harvest_detail
		check("freed on final return physics overrides a completed gather result",
			release_after_harvest.released and not post_return_harvested
				and game.material_count("wild_herb") == post_return_before + 1
				and String(post_return_detail.get("outcome", "")) == "scanner_target_invalid"
				and game.modal_count == 0 and not paused,
			{"detail": post_return_detail, "released": release_after_harvest.released,
				"materials": game.material_count("wild_herb"), "before": post_return_before,
				"modal_count": game.modal_count})
	else:
		check("Town exposes a second live Wild Herb for final-return release coverage", false)

	# A correctly targeted but Trade-locked node is an authored refusal, not a
	# cancelled channel. Keep the released InputMap receipt and report the exact
	# tier/gate immediately so a browser World with several locked veins cannot
	# collapse into three opaque timeouts.
	var locked_vein: Node3D = GatherNodeScript.new()
	locked_vein.name = "D7LockedBogironDiagnostic"
	locked_vein.setup("ore_rock", "bogiron_ore")
	locked_vein.setup_ore_tier("bogiron")
	current_scene.add_child(locked_vein)
	# Stay on Town's authored ground; placing a probe beyond the yard makes the
	# real CharacterBody fall and correctly interrupts a long mining channel.
	locked_vein.global_position = target.global_position + Vector3(4.0, 0.0, 0.0)
	await physics_frame
	await process_frame
	var bogiron_before: int = game.material_count("bogiron_ore")
	var locked_harvested: bool = await game._d7_scanner_harvest(
		locked_vein, "bogiron_ore", 5000)
	var locked_detail: Dictionary = game._web_smoke_d7_last_harvest_detail
	var locked_pre: Dictionary = locked_detail.get("target_pre", {})
	var locked_post: Dictionary = locked_detail.get("post_receipt", {})
	check("locked production target keeps its real E receipt and exact Trade diagnostic",
		not locked_harvested and game.material_count("bogiron_ore") == bogiron_before \
			and String(locked_detail.get("outcome", "")) == "locked_by_trade" \
			and bool(locked_pre.get("locked", false)) \
			and String(locked_pre.get("ore_tier", "")) == "bogiron" \
			and int(locked_pre.get("req_lv", 0)) == 3 \
			and String(locked_pre.get("gate_trade", "")) == "earthcraft" \
			and int(locked_pre.get("trade_level", 0)) == 1 \
			and bool(locked_post.get("press_accepted", false)) \
			and not bool(locked_vein.call("is_used")), locked_detail)
	game.trades.earthcraft = {"xp": game.xp_for_level(3), "lv": 3}
	game.seen_hints["ore_rock"] = true
	var anchor_before: int = game.material_count("bogiron_ore")
	var anchor_harvested: bool = await game._d7_scanner_harvest(
		locked_vein, "bogiron_ore", 1500)
	check("the same Briar anchor completes through scanner/channel at planned EC3",
		anchor_harvested and game.material_count("bogiron_ore") == anchor_before + 1 \
			and bool(locked_vein.call("is_used")) \
			and String(game._web_smoke_d7_last_harvest_detail.get("outcome", "")) \
				== "completed", game._web_smoke_d7_last_harvest_detail)
	locked_vein.queue_free()

	game.web_smoke_d7_enabled = false
	await shutdown_runtime()
	print("--- D7 scanner target-integrity: %d PASS, %d FAIL ---" % [passed, failed])
	quit(1 if failed > 0 else 0)


func shutdown_runtime() -> void:
	if current_scene != null:
		current_scene.queue_free()
		await process_frame
	var sfx := root.get_node_or_null("Sfx")
	if sfx != null and sfx.has_method("shutdown"):
		sfx.call("shutdown")
	Engine.time_scale = 1.0
	await create_timer(0.2, true, false, true).timeout


func find_live_herb(excluded: Array) -> Node3D:
	var best: Node3D = null
	var best_clearance := -INF
	for candidate_v in get_nodes_in_group("interactable"):
		if not (candidate_v is Node3D) or candidate_v in excluded or not is_instance_valid(candidate_v):
			continue
		var candidate := candidate_v as Node3D
		var kind = candidate.get("kind")
		var item_id = candidate.get("item_id")
		if kind == null or item_id == null or String(kind) != "forage_node" \
				or String(item_id) != "wild_herb" \
				or not candidate.has_method("is_used") or bool(candidate.call("is_used")):
			continue
		var clearance := INF
		for other_v in get_nodes_in_group("interactable"):
			if other_v == candidate or not (other_v is Node3D) or not is_instance_valid(other_v):
				continue
			clearance = minf(clearance, candidate.global_position.distance_to(
				(other_v as Node3D).global_position))
		if clearance > best_clearance:
			best_clearance = clearance
			best = candidate
	return best
