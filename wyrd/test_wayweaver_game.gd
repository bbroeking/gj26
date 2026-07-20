extends SceneTree

# D8 Slice 3 durable-authority contract. Campaign owns only permanent story
# witnesses; the real Game wrapper is the single place that can turn mastery
# components into the one legendary inventory/equipment item.

const GameScript = preload("res://scripts/game.gd")
const CampaignData = preload("res://data/campaign.gd")
const ItemsData = preload("res://data/items.gd")
const Rules = preload("res://data/wayweaver_mastery.gd")

var _pass := 0
var _fail := 0


func _init() -> void:
	print("--- Wayweaver Game authority ---")
	_test_component_chain_uses_exact_game_transactions()
	_test_keep_requires_pack_room_without_mutation()
	_test_equip_empty_slot_needs_no_pack_room()
	_test_equip_displaced_weapon_requires_its_own_fit()
	_test_duplicate_and_sale_guards()
	_test_rune_binding_mutates_only_owned_wayweaver()
	print("--- %d passed, %d failed ---" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)


func _check(label: String, ok: bool, detail = "") -> void:
	if ok:
		_pass += 1
	else:
		_fail += 1
		print("  x %s %s" % [label, str(detail)])


func _ready_campaign() -> Dictionary:
	var state := CampaignData.empty_state()
	for chapter_id_v in CampaignData.CHAPTER_ORDER:
		var chapter_id := String(chapter_id_v)
		var chapter: Dictionary = state.chapters[chapter_id]
		chapter.cleared = true
		chapter.clue_count = int(CampaignData.CHAPTERS[chapter_id].clue_target)
		chapter.banked_chart_ids = ["game-authority-%s" % chapter_id]
	state.relics = CampaignData.ROOT_RUNE_IDS.duplicate()
	state.threads = Rules.REQUIRED_THREADS.duplicate()
	state.restorations = ["master_forge"]
	state.map_of_nine_knots = true
	state.road_name_id = "lantern_path"
	return CampaignData.normalize_campaign_state(state)


func _new_ready_game(materials: Dictionary) -> Node:
	var game: Node = GameScript.new()
	game.persistence_enabled = false
	game._ready()
	game.persistence_enabled = false
	game.reset_to_defaults()
	game.persistence_enabled = false
	game.campaign_state = _ready_campaign()
	for trade_id in Rules.ALL_TRADES:
		game.trades[String(trade_id)] = {"lv": 23, "xp": 0}
	game.materials = materials.duplicate(true)
	return game


func _final_components() -> Dictionary:
	return {Rules.WAYSTEEL_FRAME: 1, Rules.WAYWEAVER_STRING: 1,
		Rules.QUIET_TOOTH_GRIP: 1}


func _fill_pack(game: Node) -> void:
	for y in game.inventory.rows:
		for x in game.inventory.COLS:
			var filler := ItemsData.make_item("copper_ring", "magic")
			var placed: bool = game.inventory.try_place(filler, Vector2i(x, y))
			if not placed:
				push_error("test filler failed at %s,%s" % [x, y])


func _count_kind(items: Array, kind_id: String) -> int:
	var count := 0
	for item_v in items:
		if item_v is Dictionary and String((item_v as Dictionary).get("kind_id", "")) == kind_id:
			count += 1
	return count


func _test_component_chain_uses_exact_game_transactions() -> void:
	var game := _new_ready_game({"waysteel_shard": 5, "root_sap": 5, "quiet_tooth": 1})
	var commits: Array[Dictionary] = []
	for step_v in [
		["hod_mastery", Rules.WAYSTEEL_CORE],
		["hod_mastery", Rules.WAYSTEEL_FRAME],
		["quill_mastery", Rules.ROOT_SAP_CORD],
		["quill_mastery", Rules.THREEFOLD_DRAUGHT],
		["awake_loom", Rules.WAYWEAVER_STRING],
		["master_hunt", Rules.QUIET_TOOTH_GRIP],
	]:
		var step: Array = step_v
		commits.append(game.commit_wayweaver(String(step[0]), String(step[1])))
	var all_ok := true
	var no_generic_craft := true
	for result_v in commits:
		var result: Dictionary = result_v
		var plan: Dictionary = result.get("plan", {}) as Dictionary
		all_ok = all_ok and bool(result.get("ok", false))
		no_generic_craft = no_generic_craft and int(plan.get("trade_xp", -1)) == 0 \
			and not bool(plan.get("uses_generic_craft", true))
	_check("Game applies the authored 3+2 mastery chains with no generic craft output",
		all_ok and game.materials == _final_components() and no_generic_craft,
		{"commits": commits, "materials": game.materials})
	game.free()


func _test_keep_requires_pack_room_without_mutation() -> void:
	var game := _new_ready_game(_final_components())
	_fill_pack(game)
	var before_materials: Dictionary = game.materials.duplicate(true)
	var before_items: Array = game.inventory.items.duplicate(true)
	var result: Dictionary = game.commit_wayweaver("master_forge", Rules.WAYWEAVER, Rules.KEEP)
	_check("Keep preflights a 2x4 Pack fit and leaves every durable field untouched on failure",
		not bool(result.get("ok", true)) and game.materials == before_materials
			and game.inventory.items == before_items and game.equipment.get_slot("weapon") == null
			and _count_kind(game.inventory.items, Rules.WAYWEAVER) == 0,
		{"result": result, "materials": game.materials, "items": game.inventory.items.size()})
	game.free()


func _test_equip_empty_slot_needs_no_pack_room() -> void:
	var game := _new_ready_game(_final_components())
	_fill_pack(game)
	var item_count: int = game.inventory.items.size()
	var result: Dictionary = game.commit_wayweaver("master_forge", Rules.WAYWEAVER, Rules.EQUIP)
	var equipped = game.equipment.get_slot("weapon")
	_check("Equip succeeds into an empty weapon slot even when the Pack has no 2x4 space",
		bool(result.get("ok", false)) and equipped is Dictionary
			and String((equipped as Dictionary).get("kind_id", "")) == Rules.WAYWEAVER
			and game.inventory.items.size() == item_count and game.materials.is_empty(),
		{"result": result, "weapon": equipped, "materials": game.materials})
	game.free()


func _test_equip_displaced_weapon_requires_its_own_fit() -> void:
	var game := _new_ready_game(_final_components())
	_fill_pack(game)
	var old_weapon := ItemsData.make_item("warbow", "rare")
	game.equipment.slots["weapon"] = old_weapon
	var before_materials: Dictionary = game.materials.duplicate(true)
	var result: Dictionary = game.commit_wayweaver("master_forge", Rules.WAYWEAVER, Rules.EQUIP)
	_check("Equip rejects a displaced weapon when the full Pack cannot take it, without consuming components",
		not bool(result.get("ok", true)) and game.materials == before_materials
			and game.equipment.get_slot("weapon") == old_weapon
			and _count_kind(game.inventory.items, Rules.WAYWEAVER) == 0,
		{"result": result, "materials": game.materials})
	game.free()


func _test_duplicate_and_sale_guards() -> void:
	var game := _new_ready_game(_final_components())
	var first: Dictionary = game.commit_wayweaver("master_forge", Rules.WAYWEAVER, Rules.KEEP)
	var item: Dictionary = game.inventory.items[0] if not game.inventory.items.is_empty() else {}
	game.materials = _final_components()
	var duplicate: Dictionary = game.commit_wayweaver("master_forge", Rules.WAYWEAVER, Rules.KEEP)
	var gold_before: int = int(game.gold)
	var sale: int = int(game.sell_item(item))
	_check("Wayweaver is unique across durable ownership and its non-sellable item cannot leave the Pack",
		bool(first.get("ok", false)) and not bool(duplicate.get("ok", true))
			and game.materials == _final_components() and sale == 0 and game.gold == gold_before
			and game.inventory.items.has(item) and _count_kind(game.inventory.items, Rules.WAYWEAVER) == 1
			and not bool(item.get("sellable", true)),
		{"first": first, "duplicate": duplicate, "sale": sale, "item": item})
	game.free()


func _test_rune_binding_mutates_only_owned_wayweaver() -> void:
	var game := _new_ready_game(_final_components())
	var forged: Dictionary = game.commit_wayweaver("master_forge", Rules.WAYWEAVER, Rules.EQUIP)
	var materials_before: Dictionary = game.materials.duplicate(true)
	var campaign_before: Dictionary = game.campaign_state.duplicate(true)
	var options: Array = game.wayweaver_rune_options()
	var set_green: Dictionary = game.set_wayweaver_cosmetic_rune("green_root_rune")
	var selected = game.equipment.get_slot("weapon")
	var invalid: Dictionary = game.set_wayweaver_cosmetic_rune("forged_root_rune")
	_check("Game alone binds one owned Root Rune to Wayweaver without spending a Rune, material, or stat",
		bool(forged.ok) and options.size() == 6 and bool(set_green.ok)
			and String((selected as Dictionary).get("cosmetic_rune_id", "")) == "green_root_rune"
			and game.materials == materials_before and game.campaign_state == campaign_before
			and not bool(invalid.ok) and game.campaign_settlement_view().wayweaver_mount
				== {"state": "full", "cosmetic_rune_id": "green_root_rune"},
		{"set": set_green, "invalid": invalid, "options": options})
	game.free()
