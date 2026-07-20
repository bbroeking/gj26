extends SceneTree

# Focused regression for the strict D7 browser failure at Queen settlement:
# the same live Pale Stair must open its production DialogPanel on two
# consecutive PlayerController scanner/input interactions.  This deliberately
# calls the real D5 driver seam rather than PaleStair.read_now(), because the
# latter bypasses the failed scanner -> interact -> dialog lifecycle.

const PaleStairScript = preload("res://scripts/pale_stair.gd")

var _passed := 0
var _failed := 0


func _check(label: String, ok: bool, detail = {}) -> void:
	if ok:
		_passed += 1
		print("  ✓ %s" % label)
	else:
		_failed += 1
		print("  ✗ %s %s" % [label, str(detail)])


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	print("--- D7 Pale Stair repeatable production dialog ---")
	var game := root.get_node_or_null("Game")
	game.persistence_enabled = false
	game.reset_to_defaults()
	game.persistence_enabled = false
	game.web_smoke_enabled = true
	game.web_smoke_d5_enabled = true
	game.web_smoke_d7_enabled = true
	game.web_smoke_phase = "pale_stair_repeatable_probe"
	game.modal_count = 0
	paused = false

	change_scene_to_file("res://scenes/Town.tscn")
	await process_frame
	await process_frame
	var scene := current_scene
	var player := game.local_player() as Node3D
	_check("real Town player is available", scene != null and player != null,
		{"scene": scene, "player": player})
	if scene == null or player == null:
		_finish()
		return

	var stair: Node3D = PaleStairScript.new()
	stair.name = "PaleStairRepeatableProbe"
	stair.set_campaign_settlement_view({"canonical_queen": true, "pale_stair": true})
	scene.add_child(stair)
	# The Queen driver restores the player to a point still inside the broad
	# authored interaction overlap, then begins its next cardinal scan at 3.8m.
	# Pin that overlap -> scan-edge transition so the stale-target race is
	# deterministic instead of depending on Town frame ordering.
	stair.global_position = player.global_position + Vector3(2.0, 0.0, 0.0)
	await physics_frame
	await process_frame
	# Start read one from the driver's normal no-selection boundary.  Read one
	# then leaves the production scanner's own post-interact reacquisition in
	# place, which is the load-bearing state presented to read two.
	player.set("_active_interactable", null)

	var dialog_open_count := [0]
	var tree_child_added := func(node: Node) -> void:
		if node.is_in_group("PaleStairDialog"):
			dialog_open_count[0] += 1
	node_added.connect(tree_child_added)
	var campaign_before: Dictionary = game.campaign_state.duplicate(true)
	var materials_before: Dictionary = game.materials.duplicate(true)
	var receipts: Array = []
	var reads: Array = []
	var repeated := true
	for read_index in 2:
		if not bool(await game._d5_scanner_interact(stair)):
			repeated = false
			break
		var receipt: Dictionary = player.call("last_interact_receipt")
		receipts.append(receipt)
		var dialog := get_first_node_in_group("PaleStairDialog")
		if dialog == null or not dialog.has_method("_finish"):
			repeated = false
			break
		dialog.call("_finish")
		await process_frame
		reads.append(stair.call("read_now"))
	if node_added.is_connected(tree_child_added):
		node_added.disconnect(tree_child_added)

	_check("two scanner interactions each open a production Pale Stair dialog",
		repeated and dialog_open_count[0] == 2 and receipts.size() == 2
			and reads.size() == 2 and game.web_smoke_phase != "failed", {
			"driver_result": repeated,
			"dialog_open_count": dialog_open_count[0],
			"phase": game.web_smoke_phase,
			"receipts": receipts,
			"reads": reads,
			"modal_count": game.modal_count,
			"paused": paused,
			"stair_dialog_open": stair.get("_dialog_open"),
		})
	var exact_receipts := receipts.size() == 2
	for receipt_v in receipts:
		var receipt: Dictionary = receipt_v
		exact_receipts = exact_receipts and String(receipt.get("status", "")) == "actual" \
			and receipt.get("expected") == stair and receipt.get("actual") == stair
	_check("both shipped input edges carry exact-target actual receipts",
		exact_receipts, receipts)
	var copy_only := reads.size() == 2
	for read_v in reads:
		var read: Dictionary = read_v
		copy_only = copy_only and bool(read.get("ok", false)) \
			and bool(read.get("repeatable", false)) and not bool(read.get("changed", true)) \
			and String(read.get("route", "")) == "pale_oath_not_yet_walkable"
	_check("repeatable reads are copy-only and release all ownership",
		copy_only and game.campaign_state == campaign_before \
			and game.materials == materials_before and not bool(stair.get("_dialog_open")) \
			and game.modal_count == 0 and not paused, {
			"campaign_changed": game.campaign_state != campaign_before,
			"materials_changed": game.materials != materials_before,
			"stair_dialog_open": stair.get("_dialog_open"),
			"modal_count": game.modal_count,
			"paused": paused,
		})

	if is_instance_valid(stair):
		stair.queue_free()
	await process_frame
	if is_instance_valid(scene):
		scene.queue_free()
	var sfx := root.get_node_or_null("Sfx")
	if sfx != null and sfx.has_method("shutdown"):
		sfx.call("shutdown")
	for _settle_frame in 4:
		await process_frame
	# MP3 playback releases its AudioServer handle on the audio thread.  Give
	# that short-lived worker a bounded teardown window before SceneTree exits.
	await create_timer(0.15, true).timeout
	_finish()


func _finish() -> void:
	print("--- D7 Pale Stair repeatable: %d PASS, %d FAIL ---" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)
