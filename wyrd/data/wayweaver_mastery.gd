class_name WayweaverMasteryRules
extends RefCounted

# D8 Slice 3's pure mastery transaction policy. This module has no Game,
# inventory, equipment, scene, save, RNG, or generic-crafting dependency. Game
# adapts its current durable facts into the documented context below, asks for a
# fresh commit plan immediately before mutation, then applies that plan
# atomically.
#
# Context contract:
# {
#   "campaign_state": Campaign-normalizable Dictionary,
#   "trades": {"wayfinding": {"lv": 23}, ...},
#   "materials": {"waysteel_shard": 5, ...},
#   "ownership": {"pack": [item], "equipment": {"weapon": item}},
#   "pack": {"wayweaver_fit": {"pos": Vector2i, "rotated": false},
#            "displaced_weapon_fit": {"pos": Vector2i, "rotated": false}},
# }
# `wayweaver_fit` is required for keep; `displaced_weapon_fit` is required for
# equip only when a weapon is already equipped. Neither input is mutated.

const CampaignData = preload("res://data/campaign.gd")
const ItemsData = preload("res://data/items.gd")

const WAYSTEEL_CORE := "waysteel_core"
const WAYSTEEL_FRAME := "waysteel_frame"
const ROOT_SAP_CORD := "root_sap_cord"
const THREEFOLD_DRAUGHT := "threefold_draught"
const WAYWEAVER_STRING := "wayweaver_string"
const QUIET_TOOTH_GRIP := "quiet_tooth_grip"
const WAYWEAVER := "wayweaver"

const KEEP := "keep"
const EQUIP := "equip"
const FINAL_CHOICES := [KEEP, EQUIP]
const ALL_TRADES := ["wayfinding", "earthcraft", "wildcraft", "huntcraft"]
const REQUIRED_THREADS := ["past_thread", "present_thread", "unwritten_thread"]
const ROOT_BELOW_MASTERY_BUDGET := {"waysteel_shard": 5, "root_sap": 5}
const BYPASSED_MASTERY_PERKS := ["keen_eye", "sturdy_swings", "smiths_thrift", "second_pour"]

# The ordered chains make their exact 3+2 source budgets inspectable without
# deriving them from UI copy or Game.craft().
const RECIPES := {
	WAYSTEEL_CORE: {
		"station": "hod_mastery", "trade_id": "earthcraft", "min_level": 22,
		"inputs": {"waysteel_shard": 3}, "material_output": WAYSTEEL_CORE,
	},
	WAYSTEEL_FRAME: {
		"station": "hod_mastery", "trade_id": "earthcraft", "min_level": 23,
		"inputs": {WAYSTEEL_CORE: 1, "waysteel_shard": 2}, "material_output": WAYSTEEL_FRAME,
	},
	ROOT_SAP_CORD: {
		"station": "quill_mastery", "trade_id": "wildcraft", "min_level": 22,
		"inputs": {"root_sap": 3}, "material_output": ROOT_SAP_CORD,
	},
	THREEFOLD_DRAUGHT: {
		"station": "quill_mastery", "trade_id": "wildcraft", "min_level": 23,
		"inputs": {"root_sap": 2}, "material_output": THREEFOLD_DRAUGHT,
	},
	WAYWEAVER_STRING: {
		"station": "awake_loom", "trade_id": "wildcraft", "min_level": 23,
		"inputs": {ROOT_SAP_CORD: 1, THREEFOLD_DRAUGHT: 1},
		"material_output": WAYWEAVER_STRING, "requires_awake_loom": true,
	},
	QUIET_TOOTH_GRIP: {
		"station": "master_hunt", "trade_id": "huntcraft", "min_level": 23,
		"inputs": {"quiet_tooth": 1}, "material_output": QUIET_TOOTH_GRIP,
		"requires_final_clear": true,
	},
}

static func mastery_budget() -> Dictionary:
	return ROOT_BELOW_MASTERY_BUDGET.duplicate(true)

static func source_contract(source_id: String) -> Dictionary:
	if source_id == "waysteel":
		return {"item": "waysteel_shard", "fixed_yield": 1,
			"bypass_gather_perks": ["keen_eye", "sturdy_swings"]}
	if source_id == "root_sap":
		return {"item": "root_sap", "fixed_yield": 1,
			"bypass_gather_perks": ["keen_eye", "sturdy_swings"]}
	return {}

static func preview(action_id: String, facts: Dictionary, choice := "") -> Dictionary:
	var normalized := _normalized_facts(facts)
	var plan := _empty_plan(action_id, choice, normalized)
	if action_id == WAYWEAVER:
		return _preview_wayweaver(plan, normalized, choice)
	if not RECIPES.has(action_id):
		plan.missing_predicates = ["known_mastery_action"]
		return plan
	return _preview_component(plan, normalized, RECIPES[action_id] as Dictionary)

# This intentionally has the same pure behavior as preview. Its name makes the
# required Game integration explicit: call it again against live facts just
# before applying its exact material/item plan.
static func commit_plan(action_id: String, facts: Dictionary, choice := "") -> Dictionary:
	return preview(action_id, facts, choice)

static func _preview_component(plan: Dictionary, facts: Dictionary, recipe: Dictionary) -> Dictionary:
	_add_trade_requirement(plan, facts, String(recipe.trade_id), int(recipe.min_level))
	var campaign: Dictionary = facts.campaign
	if bool(recipe.get("requires_final_clear", false)):
		_add_requirement(plan, "unwritten_road_cleared",
			CampaignData.chapter_cleared(campaign, CampaignData.UNWRITTEN_ROAD))
	if bool(recipe.get("requires_awake_loom", false)):
		_add_requirement(plan, "threefold_loom_awake", CampaignData.loom_state(campaign) == "awake")
		for thread_id_v in REQUIRED_THREADS:
			var thread_id := String(thread_id_v)
			_add_requirement(plan, "thread.%s" % thread_id,
				(facts.threads as Array).has(thread_id))
	var input_ids: Array = (recipe.inputs as Dictionary).keys()
	input_ids.sort()
	for material_id_v in input_ids:
		var material_id := String(material_id_v)
		var needed := int((recipe.inputs as Dictionary)[material_id_v])
		_add_requirement(plan, "materials.%s>=%d" % [material_id, needed],
			int((facts.materials as Dictionary).get(material_id, 0)) >= needed)
	var output_id := String(recipe.material_output)
	_add_requirement(plan, "one_per_chain.%s" % output_id,
		_chain_is_clear(output_id, facts))
	if plan.missing_predicates.is_empty():
		plan.ready = true
		plan.commit_ready = true
		plan.material_delta = _material_delta(recipe.inputs as Dictionary, {output_id: 1})
		plan.material_output = {"material_id": output_id, "count": 1}
	plan.fingerprint = _fingerprint(plan, facts)
	return plan

static func _preview_wayweaver(plan: Dictionary, facts: Dictionary, choice: String) -> Dictionary:
	var campaign: Dictionary = facts.campaign
	_add_requirement(plan, "final_choice", FINAL_CHOICES.has(choice))
	_add_requirement(plan, "unwritten_road_cleared",
		CampaignData.chapter_cleared(campaign, CampaignData.UNWRITTEN_ROAD))
	_add_requirement(plan, "master_forge_restored", (facts.restorations as Array).has("master_forge"))
	var witness: Dictionary = CampaignData.required_story_inputs(campaign)
	for story_id_v in (witness.required_story_inputs as Array):
		var story_id := String(story_id_v)
		_add_requirement(plan, "story.%s" % story_id,
			not (witness.missing_story_inputs as Array).has(story_id))
	for thread_id_v in REQUIRED_THREADS:
		var thread_id := String(thread_id_v)
		_add_requirement(plan, "thread.%s" % thread_id,
			(facts.threads as Array).has(thread_id))
	for trade_id_v in ALL_TRADES:
		_add_trade_requirement(plan, facts, String(trade_id_v), 23)
	for material_id_v in [WAYSTEEL_FRAME, WAYWEAVER_STRING, QUIET_TOOTH_GRIP]:
		var material_id := String(material_id_v)
		_add_requirement(plan, "materials.%s>=1" % material_id,
			int((facts.materials as Dictionary).get(material_id, 0)) >= 1)
	_add_requirement(plan, "wayweaver_not_owned", not _owns_wayweaver(facts))
	var weapon = (facts.equipment as Dictionary).get("weapon", null)
	if choice == KEEP:
		_add_requirement(plan, "pack_fits_wayweaver_2x4", _has_fit(facts.pack, "wayweaver_fit"))
	elif choice == EQUIP and weapon != null:
		_add_requirement(plan, "pack_fits_displaced_weapon", _has_fit(facts.pack, "displaced_weapon_fit"))
	if plan.missing_predicates.is_empty():
		plan.ready = true
		plan.commit_ready = true
		plan.material_delta = _material_delta({WAYSTEEL_FRAME: 1, WAYWEAVER_STRING: 1,
			QUIET_TOOTH_GRIP: 1}, {})
		plan.item_output = _wayweaver_descriptor()
		plan.placement = _wayweaver_placement(choice, facts.pack, weapon)
	plan.fingerprint = _fingerprint(plan, facts)
	return plan

static func _normalized_facts(raw: Dictionary) -> Dictionary:
	var campaign_raw = raw.get("campaign_state", raw.get("campaign", {}))
	var campaign: Dictionary = CampaignData.normalize_campaign_state(campaign_raw)
	var ownership: Dictionary = raw.get("ownership", {}) as Dictionary
	var equipment: Dictionary = raw.get("equipment", ownership.get("equipment", {})) as Dictionary
	return {
		"campaign": campaign,
		"trades": (raw.get("trades", {}) as Dictionary).duplicate(true),
		"materials": (raw.get("materials", raw.get("material_counts", {})) as Dictionary).duplicate(true),
		"pack": (raw.get("pack", {}) as Dictionary).duplicate(true),
		"pack_items": _array_value(raw.get("pack_items", ownership.get("pack", raw.get("inventory_items", [])))),
		"equipment": equipment.duplicate(true),
		"threads": (campaign.threads as Array).duplicate(),
		"restorations": (campaign.restorations as Array).duplicate(),
	}

static func _empty_plan(action_id: String, choice: String, facts: Dictionary) -> Dictionary:
	return {
		"action_id": action_id, "choice": choice, "ready": false, "commit_ready": false,
		"requirements": [], "missing_predicates": [], "material_delta": {},
		"material_output": {}, "item_output": {}, "placement": {},
		"uses_generic_craft": false, "trade_xp": 0,
		"bypassed_perks": BYPASSED_MASTERY_PERKS.duplicate(),
		"campaign_fingerprint": CampaignData.campaign_fingerprint(facts.campaign), "fingerprint": "",
	}

static func _add_requirement(plan: Dictionary, id: String, met: bool) -> void:
	(plan.requirements as Array).append({"id": id, "met": met})
	if not met:
		(plan.missing_predicates as Array).append(id)

static func _add_trade_requirement(plan: Dictionary, facts: Dictionary, trade_id: String, minimum: int) -> void:
	_add_requirement(plan, "trade.%s>=%d" % [trade_id, minimum],
		_trade_level(facts.trades as Dictionary, trade_id) >= minimum)

static func _trade_level(trades: Dictionary, trade_id: String) -> int:
	var value = trades.get(trade_id, 0)
	return int((value as Dictionary).get("lv", value.get("level", 0))) if value is Dictionary else int(value)

static func _material_delta(consumed: Dictionary, produced: Dictionary) -> Dictionary:
	var delta := {}
	for material_id_v in consumed.keys():
		var material_id := String(material_id_v)
		delta[material_id] = -int(consumed[material_id_v])
	for material_id_v in produced.keys():
		var material_id := String(material_id_v)
		delta[material_id] = int(delta.get(material_id, 0)) + int(produced[material_id_v])
	return delta

static func _wayweaver_descriptor() -> Dictionary:
	var kind: Dictionary = ItemsData.KINDS[WAYWEAVER]
	return {
		"kind_id": WAYWEAVER, "rarity": "legendary", "category": "weapon",
		"size": kind.size, "base_stat": String(kind.base_stat),
		"base_value": kind.base_value, "sellable": false,
	}

static func _wayweaver_placement(choice: String, pack: Dictionary, weapon) -> Dictionary:
	if choice == KEEP:
		return {"target": "pack", "fit": _fit_copy(pack, "wayweaver_fit")}
	if weapon == null:
		return {"target": "equipment.weapon", "displaced_weapon": {}}
	var displaced: Dictionary = weapon.duplicate(true) if weapon is Dictionary else {}
	return {"target": "equipment.weapon", "displaced_weapon": displaced,
		"displaced_weapon_fit": _fit_copy(pack, "displaced_weapon_fit")}

static func _has_fit(pack: Dictionary, key: String) -> bool:
	var fit = pack.get(key, {})
	return fit is Dictionary and not (fit as Dictionary).is_empty()

static func _fit_copy(pack: Dictionary, key: String) -> Dictionary:
	var fit = pack.get(key, {})
	return (fit as Dictionary).duplicate(true) if fit is Dictionary else {}

static func _array_value(value) -> Array:
	return (value as Array).duplicate(true) if value is Array else []

static func _owns_wayweaver(facts: Dictionary) -> bool:
	for item_v in facts.pack_items as Array:
		if item_v is Dictionary and String((item_v as Dictionary).get("kind_id", "")) == WAYWEAVER:
			return true
	for item_v in (facts.equipment as Dictionary).values():
		if item_v is Dictionary and String((item_v as Dictionary).get("kind_id", "")) == WAYWEAVER:
			return true
	return false

static func _chain_is_clear(output_id: String, facts: Dictionary) -> bool:
	var downstream := {
		WAYSTEEL_CORE: [WAYSTEEL_CORE, WAYSTEEL_FRAME],
		WAYSTEEL_FRAME: [WAYSTEEL_FRAME],
		ROOT_SAP_CORD: [ROOT_SAP_CORD, WAYWEAVER_STRING],
		THREEFOLD_DRAUGHT: [THREEFOLD_DRAUGHT, WAYWEAVER_STRING],
		WAYWEAVER_STRING: [WAYWEAVER_STRING],
		QUIET_TOOTH_GRIP: [QUIET_TOOTH_GRIP],
	}.get(output_id, [output_id]) as Array
	for material_id_v in downstream:
		if int((facts.materials as Dictionary).get(String(material_id_v), 0)) > 0:
			return false
	return not _owns_wayweaver(facts)

static func _fingerprint(plan: Dictionary, facts: Dictionary) -> String:
	var parts: Array[String] = [String(plan.action_id), String(plan.choice),
		String(plan.campaign_fingerprint), "owned=%d" % int(_owns_wayweaver(facts))]
	for trade_id_v in ALL_TRADES:
		var trade_id := String(trade_id_v)
		parts.append("%s=%d" % [trade_id, _trade_level(facts.trades as Dictionary, trade_id)])
	var materials: Dictionary = facts.materials
	var ids: Array = materials.keys()
	ids.sort()
	for material_id_v in ids:
		var material_id := String(material_id_v)
		parts.append("m:%s=%d" % [material_id, int(materials[material_id_v])])
	parts.append("pack=%d/%d" % [int(_has_fit(facts.pack, "wayweaver_fit")),
		int(_has_fit(facts.pack, "displaced_weapon_fit"))])
	var weapon = (facts.equipment as Dictionary).get("weapon", null)
	var weapon_id := String((weapon as Dictionary).get("kind_id", "")) if weapon is Dictionary else ""
	parts.append("weapon=%s" % weapon_id)
	parts.append("missing=" + ",".join(plan.missing_predicates as Array))
	return "|".join(parts).sha256_text()
