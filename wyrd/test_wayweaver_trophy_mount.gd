extends SceneTree

# D8 Slice 3 — the Trophy Hall never becomes a second inventory/campaign
# authority.  Host Game derives a compact mount record; guests render that
# record exactly; the Hall only reconciles named, inert geometry.

const CampaignData = preload("res://data/campaign.gd")
const ItemsData = preload("res://data/items.gd")
const TrophyHallScript = preload("res://scripts/trophy_hall.gd")

var _pass := 0
var _fail := 0


func _initialize() -> void:
	call_deferred("_run")


func _check(label: String, ok: bool, detail = "") -> void:
	if ok:
		_pass += 1
		print("  ✓ %s" % label)
	else:
		_fail += 1
		print("  ✗ %s %s" % [label, str(detail)])


func _frames(count := 3) -> void:
	for _frame in count:
		await process_frame


func _final_campaign() -> Dictionary:
	var state := CampaignData.empty_state()
	for chapter_id_v in CampaignData.CHAPTER_ORDER:
		var chapter_id := String(chapter_id_v)
		var chapter: Dictionary = state.chapters[chapter_id]
		chapter.cleared = true
		chapter.clue_count = int(CampaignData.CHAPTERS[chapter_id].clue_target)
		chapter.banked_chart_ids = ["trophy-mount-%s" % chapter_id]
	state.relics = CampaignData.ROOT_RUNE_IDS.duplicate()
	state.threads = ["past_thread", "present_thread", "unwritten_thread"]
	state.restorations = ["trophy_hall", "sallow_jetty", "skald_archive", "pale_stair",
		"rootroad_lift", "ember_kiln", "master_forge"]
	state.map_of_nine_knots = true
	state.road_name_id = "lantern_path"
	return CampaignData.normalize_campaign_state(state)


func _wayweaver(rune_id := "") -> Dictionary:
	var item := ItemsData.make_item("wayweaver", "legendary")
	item["cosmetic_rune_id"] = rune_id
	return item


func _run() -> void:
	print("--- Wayweaver Trophy Hall mount projection ---")
	var game: Node = root.get_node("Game")
	var net: Node = root.get_node("NetGame")
	var campaign_saved: Dictionary = game.campaign_state.duplicate(true)
	var inventory_saved = game.inventory
	var equipment_saved = game.equipment
	var persistence_saved := bool(game.persistence_enabled)
	var active_saved := bool(net.active)
	var peer_saved: MultiplayerPeer = net.multiplayer.multiplayer_peer
	var settlement_saved: Dictionary = (net.get("_settlement_view") as Dictionary).duplicate(true)
	game.persistence_enabled = false
	game.campaign_state = _final_campaign()
	game.inventory = Inventory.new()
	game.equipment = Equipment.new()

	var pack_item := _wayweaver("crown_root_rune")
	game.inventory.try_place(pack_item, Vector2i(0, 0))
	var pack_view: Dictionary = game.campaign_settlement_view()
	_check("host projection finds a Pack Wayweaver and its cosmetic rune",
		pack_view.wayweaver_mount == {"state": "full", "cosmetic_rune_id": "crown_root_rune"},
		pack_view.get("wayweaver_mount", {}))
	game.inventory.remove(pack_item)
	var equip_item := _wayweaver("pale_root_rune")
	game.equipment.slots.weapon = equip_item
	var equip_view: Dictionary = game.campaign_settlement_view()
	_check("host projection finds an equipped Wayweaver without a Pack copy",
		equip_view.wayweaver_mount == {"state": "full", "cosmetic_rune_id": "pale_root_rune"},
		equip_view.get("wayweaver_mount", {}))
	game.equipment.slots.weapon = null
	var empty_view: Dictionary = game.campaign_settlement_view()
	_check("a final-clear settlement leaves the mount empty until Wayweaver is owned",
		empty_view.wayweaver_mount == {"state": "empty", "cosmetic_rune_id": ""},
		empty_view.get("wayweaver_mount", {}))
	game.campaign_state = CampaignData.empty_state()
	var covered_view: Dictionary = game.campaign_settlement_view()
	_check("before final clear the original covered bow-rest remains the truthful projection",
		covered_view.wayweaver_mount == {"state": "covered", "cosmetic_rune_id": ""},
		covered_view.get("wayweaver_mount", {}))

	# A guest may only read the host snapshot. Give the local guest a conflicting
	# empty campaign and no equipment; its result must retain host full/rune truth.
	game.campaign_state = _final_campaign()
	game.equipment.slots.weapon = _wayweaver("ember_root_rune")
	var host_view: Dictionary = game.campaign_settlement_view()
	net.join("127.0.0.1", 7777)
	var guest_before := String((game.equipment.get_slot("weapon") as Dictionary).get("cosmetic_rune_id", ""))
	var guest_mutation: Dictionary = game.set_wayweaver_cosmetic_rune("mist_root_rune")
	_check("a guest cannot mutate its local Wayweaver cosmetic before host projection arrives",
		not bool(guest_mutation.get("ok", true))
			and guest_before == String((game.equipment.get_slot("weapon") as Dictionary).get("cosmetic_rune_id", "")),
		guest_mutation)
	game.campaign_state = CampaignData.empty_state()
	game.equipment.slots.weapon = null
	net._sync_settlement_view(host_view)
	var guest_view: Dictionary = game.campaign_settlement_view()
	_check("guest copies the host mount snapshot and never infers local equipment",
		bool(guest_view.get("guest", false)) and bool(guest_view.get("read_only", false))
			and guest_view.wayweaver_mount == {"state": "full", "cosmetic_rune_id": "ember_root_rune"},
		guest_view.get("wayweaver_mount", {}))
	net._end("trophy mount test cleanup")

	# The Hall is an inert visual adapter.  Its transitions must neither mutate
	# the source view nor use Game campaign/inventory state.
	var hall: Node3D = TrophyHallScript.new()
	hall.set_homecoming_view({"visible": true, "restoration_visible": true,
		"covered_bow_rest_visible": true})
	root.add_child(hall)
	await _frames()
	var view := {"available": true, "wayweaver_mount": {"state": "covered",
		"cosmetic_rune_id": ""}}
	var source_before: Dictionary = view.duplicate(true)
	hall.set_settlement_view(view)
	await _frames()
	_check("Hall preserves the named inert covered rest before final clear",
		hall.get_node_or_null("WayweaverMountCovered") != null
			and hall.get_node_or_null("CoveredBowRest") != null, hall.get_children())
	view.wayweaver_mount = {"state": "empty", "cosmetic_rune_id": ""}
	hall.set_settlement_view(view)
	await _frames()
	_check("Hall swaps the cover for a named empty rest without an interactable",
		hall.get_node_or_null("WayweaverMountEmpty") != null
			and hall.get_node_or_null("CoveredBowRest") == null
			and not hall.get_node_or_null("WayweaverMountEmpty").is_in_group("interactable"))
	view.wayweaver_mount = {"state": "full", "cosmetic_rune_id": "mist_root_rune"}
	hall.set_settlement_view(view)
	await _frames()
	var full := hall.get_node_or_null("WayweaverMountFull")
	var rune_label := full.get_node_or_null("WayweaverMountRuneLabel") if full != null else null
	_check("Hall mounts the rigid Wayweaver display and its cosmetic rune read-only",
		full != null and full.get_node_or_null("WayweaverDisplay") != null and rune_label != null
			and String(rune_label.text) == "Mist Root Rune")
	_check("Hall reconciliation never changes its caller-owned view",
		source_before.wayweaver_mount == {"state": "covered", "cosmetic_rune_id": ""}
			and String(view.wayweaver_mount.cosmetic_rune_id) == "mist_root_rune")
	hall.queue_free()
	await _frames()

	game.campaign_state = campaign_saved
	game.inventory = inventory_saved
	game.equipment = equipment_saved
	game.persistence_enabled = persistence_saved
	net.active = active_saved
	net.multiplayer.multiplayer_peer = peer_saved
	net._sync_settlement_view(settlement_saved)
	print("--- Wayweaver Trophy Hall mount: %d PASS, %d FAIL ---" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)
