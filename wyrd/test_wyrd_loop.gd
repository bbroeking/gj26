extends SceneTree

# Wyrd slice — headless end-to-end logic check.
# Run: godot --headless --path wyrd --script res://test_wyrd_loop.gd
#
# Covers the chart loop with no UI: materials → mix ink → inscribe →
# run cfg → parameterized dungeon gen (grid size, boss-as-affix, gather
# decor, determinism) → completion XP → tutorial step advancement.

const ChartsData = preload("res://data/charts.gd")
const CampaignData = preload("res://data/campaign.gd")
const GatherDefs = preload("res://data/gather.gd")
const DungeonGenScript = preload("res://scripts/dungeon_gen.gd")
const Progression = preload("res://data/progression.gd")

class SaveCountingGame:
	extends "res://scripts/game.gd"
	var save_calls := 0
	var notify_calls := 0

	func save_now() -> bool:
		save_calls += 1
		return true

	func notify(_msg: String) -> void:
		notify_calls += 1

var _pass := 0
var _fail := 0

func _check(name: String, ok: bool, detail: String = "") -> void:
	if ok:
		_pass += 1
		print("  ✓ %s" % name)
	else:
		_fail += 1
		print("  ✗ %s %s" % [name, detail])

func _set_trade_level(game: Node, trade_key: String, level: int) -> void:
	game.trades[trade_key] = {"xp": Progression.xp_for_level(level), "lv": level}

func _init() -> void:
	print("--- wyrd loop check ---")
	_test_charts_data()
	_test_chart_recipe_resolver()
	_test_chart_table_domain()
	_test_chart_codex_domain()
	_test_campaign_domain()
	_test_d2_chart_domain()
	_test_chart_sources_domain()
	_test_chart_table_transaction()
	_test_chart_depth()
	_test_sallow_mire_package()
	_test_game_flow()
	_test_dungeon_cfg()
	_test_gather_decor()
	_test_determinism()
	_test_chain_and_economy()
	_test_enemy_kinds()
	_test_crafting_perks()
	_test_tools_and_mute()
	_test_loadout()
	_test_ore_tiers()
	_test_b6_affixes()
	_test_huntcraft()
	_test_economy_gate()
	_test_alchemy()
	_test_discovery()
	_test_ladders()
	_test_pack_progression()
	_test_run_completed_signal()
	_test_d14_hints()
	_test_d15_quaff_flag()
	_test_second_hand_state()
	_test_second_hand_layout()
	_test_persistence_status()
	_test_new_game_reset()
	_test_save_roundtrip()
	print("--- %d passed, %d failed ---" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)

func _test_chart_depth() -> void:
	print("[chart depth]")
	var chart := ChartsData.inscribe("hollow", ["hedge_ink"], 12)
	var original_affixes: Array = chart.affixes.duplicate(true)
	var original_seed := int(chart.seed)
	_check("later Hollow declares two layers", int(chart.get("max_layers", 1)) == 2)
	_check("new Chart begins on layer one", int(chart.get("layer", 0)) == 1
		and (chart.get("omens", []) as Array).is_empty())
	_check("layer one may press deeper", ChartsData.can_press_deeper(chart))
	var deeper := ChartsData.deepen(chart)
	_check("pressing deeper preserves committed tier and Affixes",
		int(deeper.tier) == int(chart.tier) and deeper.affixes == original_affixes)
	_check("pressing deeper changes layer and seed", int(deeper.layer) == 2
		and int(deeper.seed) != original_seed)
	_check("pressing deeper visibly adds one Omen",
		(deeper.get("omens", []) as Array).size() == 1
		and String(deeper.omens[0].get("name", "")) != "")
	_check("final layer cannot press deeper", not ChartsData.can_press_deeper(deeper)
		and ChartsData.deepen(deeper).is_empty())
	_check("deeper completion pays more without changing tier",
		ChartsData.completion_xp(deeper) > ChartsData.completion_xp(chart)
		and ChartsData.completion_gold(deeper) > ChartsData.completion_gold(chart))

func _test_sallow_mire_package() -> void:
	print("[Sallow Mire package]")
	var cfg := (ChartsData.TEMPLATES.mire.gen as Dictionary).duplicate()
	cfg["template_id"] = "mire"
	cfg["scope"] = "mire"
	cfg["tier"] = 2
	cfg["affixes"] = [{"id": "fog_of_hedge", "good": true,
		"resolvedId": "fog_of_hedge"}]
	var layout: Dictionary = DungeonGenScript.generate(551055, cfg)
	_check("Mire owns room grammar", DungeonGenScript.SCOPE_THEMES.has("mire")
		and DungeonGenScript.SCOPE_SETPIECES.has("mire"))
	var setpieces: Array = (layout.rooms as Array).filter(func(r):
		return String((r as Dictionary).get("setpiece", "")) == "wisp_pool")
	_check("Mire guarantees its wisp-pool side discovery", not setpieces.is_empty())
	var native_nodes: Array = (layout.decor as Array).filter(func(d):
		return String((d as Dictionary).get("herb_tier", "")) == "mothmint")
	_check("Mire guarantees native Mothmint", native_nodes.size() >= 2,
		str(native_nodes.size()))
	var shrine_nodes: Array = (layout.decor as Array).filter(func(d):
		return (String((d as Dictionary).get("interact_role", "")) == "shrine"
			and bool((d as Dictionary).get("biome_signature", false))))
	_check("wisp pool carries a wayside shrine", not shrine_nodes.is_empty())
	var LayoutLoaderScript = load("res://scripts/layout_loader.gd")
	_check("Mire has a signature ranged bog wisp",
		LayoutLoaderScript.ENEMY_KINDS.has("bog_wisp")
		and bool(LayoutLoaderScript.ENEMY_KINDS.bog_wisp.get("ranged", false))
		and (LayoutLoaderScript.SPAWN_TABLES.mire as Array).any(func(row):
			return String(row[0]) == "bog_wisp"))
	var mire_chart := {"scope": "mire"}
	var presentation := ChartsData.affix_presentation(mire_chart,
		{"id": "fog_of_hedge", "good": true})
	_check("Mire presents biome-specific Affix twins",
		String(presentation.name) == "Wisp-Lit Fog"
		and ChartsData.MIRE_AFFIX_PRESENTATIONS.size() == 3)
	_check("Mire relates to the Burrow Boar den",
		String(ChartsData.TEMPLATES.mire.get("miniboss_affix", "")) == "burrow_boar_den")
	for kind in ["roots", "sunkenlog", "dockpost", "lilypads", "wisp", "mudmound", "reeds"]:
		_check("Mire asset exists: %s" % kind,
			FileAccess.file_exists("res://models/biome_bog_%s_v1.glb" % kind))

func _test_persistence_status() -> void:
	print("[persistence status]")
	var game = load("res://scripts/game.gd").new()
	game._ready()
	game.persistence_enabled = true
	_check("persistence begins available", game.persistence_available)
	game.report_persistence_unavailable("This browser blocks local storage.")
	_check("failed persistence is surfaced", not game.persistence_available
		and game.persistence_warning == "This browser blocks local storage.")
	_check("unavailable persistence refuses saves", not game.save_now())

# The chart chain (trophies → dens → Summit) and the gold economy.
func _test_chain_and_economy() -> void:
	print("[chain + economy]")
	# Dens are out of the random pool even at high level.
	var w99 := ChartsData.compute_weights(3, [], 99)
	_check("no den rolls at random", not w99.has("hedgemother_den")
		and not w99.has("wolf_alpha_den"), str(w99.keys()))
	# A slotted trophy guarantees its den.
	var chart := ChartsData.inscribe("tier_1", [], 99, "thorn_essence")
	var ids: Array = []
	for a in chart.affixes:
		ids.append(String(a.id))
	_check("trophy forces hedgemother_den", ids.has("hedgemother_den"), str(ids))
	# Trophy is charged; snug (no affix slots) never charges it.
	var cost := ChartsData.craft_cost("tier_1", [], "thorn_essence")
	_check("trophy in craft cost", int(cost.get("thorn_essence", 0)) == 1, str(cost))
	var snug_cost := ChartsData.craft_cost("snug", ["hedge_ink"], "thorn_essence")
	_check("slotless chart charges neither ink nor trophy",
		not snug_cost.has("thorn_essence") and int(snug_cost.get("hedge_ink", 0)) == 1,
		str(snug_cost))
	# The Summit names its own boss through the gen block.
	var game = load("res://scripts/game.gd").new()
	game._ready()
	game.active_chart = {"template_id": "summit", "tier": 3, "scope": "crypt",
		"name": "Chart of the Summit", "seed": 7, "affixes": []}
	var cfg: Dictionary = game.run_cfg()
	_check("summit boss is the Queen",
		String(cfg.get("boss_kind", "")) == "hedgemother_queen", str(cfg))
	_check("summit costs the visible fang Seal", int(ChartsData.craft_cost("summit", [],
		"alpha_fang")
		.get("alpha_fang", 0)) == 1)
	# Gold: sell a gear item, buy a ware. Lv 6 so hedge_ink (lv 2) is buyable.
	game.active_chart = {}
	_set_trade_level(game, "wayfinding", 6)
	var ItemsData = load("res://data/items.gd")
	var item: Dictionary = ItemsData.make_item("shortbow", "rare")
	var fit: Dictionary = game.inventory.find_first_fit(item)
	game.inventory.try_place(item, fit.pos, fit.rotated)
	var price: int = game.sell_item(item)
	_check("rare sells for 35", price == 35 and int(game.gold) == 35, str(price))
	_check("sold item left the pack", game.inventory.items.is_empty())
	_check("buy ware", game.buy_ware("hedge_ink", 12)
		and game.material_count("hedge_ink") == 1 and int(game.gold) == 23)
	_check("can't buy broke", not game.buy_ware("refined_ink", 38))
	# Anti-arbitrage: a ware above the player's level is refused outright
	# (hedgesteel_ore needs lv 8; game is lv 6) even when affordable.
	_check("ware level-gated", not game.buy_ware("hedgesteel_ore", 1)
		and game.material_count("hedgesteel_ore") == 0)
	# Chart case caps at CHART_CASE_MAX — inscribing past it is refused.
	game.charts.clear()
	for _c in game.CHART_CASE_MAX:
		game.add_chart({"template_id": "snug", "tier": 1, "scope": "snug",
			"name": "Snug", "seed": 1, "affixes": []})
	_check("chart case fills to cap",
		(game.charts as Array).size() == game.CHART_CASE_MAX
		and game.chart_case_full())
	# C11 — an elite reward_tier_bonus lifts the drop rarity floor (deterministic).
	var Drops = load("res://data/drops.gd")
	_check("tier_bonus 20 floors the roll at tier 9",
		Drops._roll_tier("combat", 0, 20) == 9, str(Drops._roll_tier("combat", 0, 20)))
	_check("tier_bonus 8 always rolls magic+ (>=5)",
		Drops._roll_tier("combat", 0, 8) >= 5, str(Drops._roll_tier("combat", 0, 8)))
	# D12 — the better kinds gate by depth: a depth-0 den never drops a longbow.
	var shallow := {}
	for _i in 60:
		shallow[Drops._pick_kind(0)] = true
	_check("longbow gated from depth 0", not shallow.has("longbow"), str(shallow.keys()))
	_check("copper_ring gated from depth 0", not shallow.has("copper_ring"))
	game.free()

# Pack-size progression — the satchel grows a row at level milestones (6, 12),
# and resize refuses to shrink over an occupied bottom row.
func _test_pack_progression() -> void:
	print("[pack progression]")
	var game = load("res://scripts/game.gd").new()
	game._ready()
	game.persistence_enabled = false
	_check("pack starts at 6 rows", game.inventory.rows == 6, str(game.inventory.rows))
	game.award_xp("earthcraft", 999999)
	game.award_xp("wildcraft", 999999)
	game.award_xp("huntcraft", 999999)
	_check("only Wayfinding may grow the pack", game.inventory.rows == 6,
		str(game.inventory.rows))
	_check("Huntcraft 23 grants implemented Driving Volley and Threadstep but no planned ghost Skill",
		game.owned_skills.has("DrivingVolley")
			and game.owned_skills.has("Threadstep")
			and not game.owned_skills.has("WayfindersMark"), str(game.owned_skills))
	_set_trade_level(game, "wayfinding", 6)
	game.grow_pack_for_level()
	_check("pack grows to 7 at lv 6", game.inventory.rows == 7, str(game.inventory.rows))
	_set_trade_level(game, "wayfinding", 12)
	game.grow_pack_for_level()
	_check("pack grows to 8 at lv 12", game.inventory.rows == 8, str(game.inventory.rows))
	var it := {"size": Vector2i(1, 1)}
	game.inventory.try_place(it, Vector2i(0, 7), false)   # occupy the 8th row
	_check("resize refuses shrink over an occupied row", not game.inventory.resize(6))
	game.free()

# Serialization roundtrip — including the JSON-hostile Vector2i/Color values
# that gear items carry. Cleans up after itself.
# Spec 38 — trade tools in their own slots + tool-scaled channels + mute.
func _test_tools_and_mute() -> void:
	print("[tools + mute]")
	var game = load("res://scripts/game.gd").new()
	game._ready()
	var GatherNode = load("res://scripts/gather_node.gd")
	var ItemsData = load("res://data/items.gd")
	# Craft the pickaxe at the forge (Earthcraft 2 gate).
	game.add_material("bogiron_bar", 1)
	game.add_material("logs", 1)
	_check("pickaxe gated at earth 1", not game.craft("forge", "pickaxe_smith"))
	_set_trade_level(game, "earthcraft", 2)
	_check("pickaxe smiths at earth 2", game.craft("forge", "pickaxe_smith"))
	var pick = null
	for it in game.inventory.items:
		if String(it.get("kind_id", "")) == "bogiron_pickaxe":
			pick = it
	_check("pickaxe landed in the pack", pick != null)
	# A2 — the hedgesteel armour ladder has a chest, not just cap + boots.
	var CD = load("res://data/crafting.gd")
	var jerkin: Dictionary = CD.recipe("hedgesteel_jerkin_smith")
	_check("hedgesteel jerkin recipe yields a chest at lv16",
		not jerkin.is_empty()
		and String((jerkin.get("yields_item", {}) as Dictionary).get("kind", "")) == "leather_chest"
		and int(jerkin.get("req_lv", 0)) == 16, str(jerkin))
	_check("hedgesteel jerkin registered on the forge",
		((CD.station("forge").get("recipes", []) as Array)).has("hedgesteel_jerkin_smith"))
	# Bare-handed vs tooled channel time.
	var bare: float = GatherNode.channel_seconds("ore_rock", game)
	_check("bare mining at base speed", absf(bare - 1.6) < 0.01, str(bare))
	_check("tool equips to its own slot", game.equipment.can_equip(pick))
	game.inventory.remove(pick)
	game.equipment.equip(pick)
	_check("pickaxe in the pickaxe slot",
		game.equipment.get_slot("pickaxe") != null
		and game.equipment.get_slot("weapon") == null)
	var tooled: float = GatherNode.channel_seconds("ore_rock", game)
	_check("pickaxe cuts mining ≥25%", tooled <= bare * 0.75,
		"%.2f vs %.2f" % [tooled, bare])
	_check("axe slot empty → chopping unchanged",
		absf(GatherNode.channel_seconds("log_pile", game) - 1.3) < 0.01)
	_check("foraging never tool-scaled",
		absf(GatherNode.channel_seconds("forage_node", game) - 1.0) < 0.01)
	# Tools never roll as random drops.
	var Drops = load("res://data/drops.gd")
	var saw_tool := false
	for _i in 300:
		var kid: String = Drops._pick_kind()
		if String(ItemsData.KINDS[kid].category) in ["pickaxe", "axe"]:
			saw_tool = true
	_check("tools excluded from drop pool", not saw_tool)
	game.free()

# B5/0B — owned Focus Skills are distinct from the three configurable slots.
func _test_loadout() -> void:
	print("[loadout]")
	var game = load("res://scripts/game.gd").new()
	game._ready()
	_check("fresh game has Basic Shot only", game.owned_skills.is_empty()
		and game.loadout.is_empty() and game.skill_unlocked("BasicShot"))
	_check("rejects unowned Focus Skill", not game.set_loadout(["PowerShot"]))
	game.grant_skill("PowerShot")
	game.grant_skill("MultiShot")
	game.grant_skill("BrambleSnare")
	game.grant_skill("PiercingBolt")
	game.grant_skill("RainOfThorns")
	_check("rejects unknown skill",
		not game.set_loadout(["PowerShot", "MultiShot", "FrostNova"]))
	_check("rejects duplicates",
		not game.set_loadout(["PowerShot", "PowerShot", "MultiShot"]))
	_check("rejects more than three slots", not game.set_loadout(
		["PowerShot", "MultiShot", "BrambleSnare", "PiercingBolt"]))
	_check("accepts a new kit",
		game.set_loadout(["PiercingBolt", "RainOfThorns", "BrambleSnare"]))
	_check("loadout stored", game.loadout ==
		["PiercingBolt", "RainOfThorns", "BrambleSnare"])
	# New skill classes instantiate with sane numbers.
	var pb = load("res://scripts/skills/piercing_bolt.gd").new()
	_check("piercing bolt: pierce 3, costs focus",
		int(pb.pierce) == 3 and float(pb.cost) > 0.0)
	var rt = load("res://scripts/skills/rain_of_thorns.gd").new()
	_check("rain of thorns: cd + cost set",
		float(rt.base_cd) > 0.0 and float(rt.cost) > 0.0)
	_check("pool lists Focus Skill definitions", (game.SKILL_POOL as Array).size() >= 9)
	var paths := {"Thornburst": "thornburst", "HuntersMark": "hunters_mark",
		"HeartwoodWard": "heartwood_ward", "MercyShot": "mercy_shot"}
	for sk in paths:
		var inst = load("res://scripts/skills/%s.gd" % paths[sk]).new()
		_check("%s: cd + cost set" % sk,
			float(inst.base_cd) > 0.0 and float(inst.cost) > 0.0)
	_check("mercy shot executes under 35%",
		absf(float(load("res://scripts/skills/mercy_shot.gd").new().execute_below)
		- 0.35) < 0.001)
	# Huntcraft level unlocks grant owned Skills, but do not auto-equip them.
	_check("mark locked at hunt 1",
		not game.set_loadout(["HuntersMark", "PowerShot", "MultiShot"]))
	_set_trade_level(game, "huntcraft", 10)
	game.award_xp("huntcraft", Progression.xp_for_level(11) - Progression.xp_for_level(10))
	_check("mark opens at Huntcraft 11",
		game.set_loadout(["HuntersMark", "PowerShot", "MultiShot"]))
	_check("mercy remains locked before Huntcraft 16",
		not game.set_loadout(["MercyShot", "PowerShot", "MultiShot"]))
	_set_trade_level(game, "huntcraft", 15)
	game.award_xp("huntcraft", Progression.xp_for_level(16) - Progression.xp_for_level(15))
	_check("mercy opens at Huntcraft 16",
		game.set_loadout(["MercyShot", "PowerShot", "MultiShot"]))
	_check("thornburst remains locked before its Huntcraft lesson",
		not game.skill_owned("Thornburst"))
	game.free()

# A6 — ore tiers: data sanity, level gating, chart-tier vein mixes.
func _test_ore_tiers() -> void:
	print("[ore tiers]")
	var tiers: Dictionary = GatherDefs.ORE_TIERS
	_check("three tiers, reqs ascend",
		int(tiers.copper.req_lv) < int(tiers.bogiron.req_lv)
		and int(tiers.bogiron.req_lv) < int(tiers.palechalk.req_lv))
	for tid in tiers:
		_check("%s item is a real material" % tid,
			GatherDefs.MATERIALS.has(String(tiers[tid].item)))
	var GatherNode = load("res://scripts/gather_node.gd")
	var game = load("res://scripts/game.gd").new()
	game._ready()
	var node = GatherNode.new()
	node.setup("ore_rock", "copper_ore", false)
	node.setup_ore_tier("palechalk")
	_check("palechalk locked at earth 1", node.locked(game))
	_set_trade_level(game, "earthcraft", 7)
	_check("palechalk opens at earth 7", not node.locked(game))
	_check("tier channel overrides kind default",
		absf(GatherNode.channel_seconds("ore_rock", game, 2.0) - 2.0) < 0.01)
	# Cinderbloom tool stacks with the tier channel.
	var ItemsData = load("res://data/items.gd")
	var pick: Dictionary = ItemsData.make_item("cinderbloom_pickaxe", "normal")
	game.equipment.equip(pick)
	var t: float = GatherNode.channel_seconds("ore_rock", game, 2.0)
	_check("cinderbloom pickaxe cuts 45%", absf(t - 1.1) < 0.02, str(t))
	# Copper chain: ore -> bar -> ring.
	game.equipment.unequip("pickaxe")
	game.add_material("copper_ore", 2)
	_check("smelt copper bar", game.craft("forge", "copper_bar"))
	game.add_material("copper_bar", 1)
	_set_trade_level(game, "earthcraft", 8)
	_check("ring takes copper bars now", game.craft("forge", "bogiron_ring"))
	# Chart-tier vein mixes (deterministic seeds).
	var t1 := DungeonGenScript.generate(4242, {"grid": 36, "room_min": 7,
		"room_max": 11, "boss_kind": "", "tier": 1,
		"affixes": [{"id": "mineral_vein", "good": true}]})
	var t2 := DungeonGenScript.generate(4242, {"grid": 36, "room_min": 7,
		"room_max": 11, "boss_kind": "", "tier": 2,
		"affixes": [{"id": "mineral_vein", "good": true}]})
	var ok1 := true
	for d in t1.decor:
		if bool(d.get("gather", false)) and String(d.kind) == "ore_rock":
			if not String(d.get("ore_tier", "")) in ["copper", "bogiron"]:
				ok1 = false
	_check("tier-1 charts: copper/bogiron only", ok1)
	var saw_deep := false
	var ok2 := true
	for d in t2.decor:
		if bool(d.get("gather", false)) and String(d.kind) == "ore_rock":
			var ot := String(d.get("ore_tier", ""))
			if not ot in ["bogiron", "palechalk", "starsilver", "hedgesteel"]:
				ok2 = false
			if ot in ["palechalk", "starsilver", "hedgesteel"]:
				saw_deep = true
	_check("tier-2 charts: bogiron and deeper only", ok2)
	_check("tier-2 carries a deep ore (seed 4242)", saw_deep)
	game.free()

# B6 — both waves: wave 1 (sprinter/gilded/bursting) + wave 2 (quiver/
# fog_of_hedge/frenzied/wellspring/echoing/marked_quarry).
func _test_b6_affixes() -> void:
	print("[b6 affixes]")
	for aid in ["sprinter", "gilded", "bursting", "quiver", "fog_of_hedge",
			"frenzied", "wellspring", "echoing", "marked_quarry"]:
		_check("%s defined + weighted" % aid,
			ChartsData.AFFIXES.has(aid) and ChartsData.BASE_WEIGHTS.has(aid))
	# High-carto weights include every rollable affix (dens stay out).
	var w := ChartsData.compute_weights(2, [], 20)
	_check("new affixes roll at high carto", w.has("sprinter")
		and w.has("gilded") and w.has("bursting"), str(w.keys()))
	_check("15 affixes rollable at carto 20", w.size() == 15, str(w.size()))
	_check("dens never in the random pool", not w.has("hedgemother_den")
		and not w.has("burrow_boar_den") and not w.has("wolf_alpha_den"))
	# Gilded scatters one extra chest (not a gather node). Ordinary layouts own
	# one treasure-room chest, so this caps the readable map total at two.
	var lay := DungeonGenScript.generate(909, {"grid": 36, "room_min": 7,
		"room_max": 11, "boss_kind": "", "tier": 2,
		"affixes": [{"id": "gilded", "good": true}]})
	var chests := 0
	var gilded_chests_are_interactable := true
	for d in lay.decor:
		if String(d.get("kind", "")) == "chest" and not bool(d.get("gather", true)):
			chests += 1
			gilded_chests_are_interactable = gilded_chests_are_interactable \
				and String(d.get("interact_role", "")) == "treasure"
	_check("gilded adds 1 chest", chests == 1, str(chests))
	_check("gilded chest uses the production treasure interaction",
		gilded_chests_are_interactable)
	# Wave-2 behaviors reachable without a scene: the affix twins feed the
	# player/loader mults, and Barren Veins taxes the channel.
	var game = load("res://scripts/game.gd").new()
	game._ready()
	game.in_dungeon = true
	game.active_chart = {"affixes": [
		{"id": "quiver", "good": true},
		{"id": "wellspring", "good": false},
	]}
	_check("affix twins read by side", game.affix_good("quiver")
		and game.affix_bad("wellspring") and not game.affix_good("wellspring"))
	var GatherNode = load("res://scripts/gather_node.gd")
	var t: float = GatherNode.channel_seconds("forage_node", game)
	_check("barren veins channel ×1.33", absf(t - 1.33) < 0.01, str(t))
	game.active_chart = {"affixes": [{"id": "wellspring", "good": true}]}
	_check("wellspring good drops the channel tax",
		absf(GatherNode.channel_seconds("forage_node", game) - 1.0) < 0.01)
	game.free()

# B7/ADR 0005 — Huntcraft: the one combat trade. The kill-side award is
# checked in the dungeon scene suite; this is the trade plumbing.
func _test_huntcraft() -> void:
	print("[Huntcraft]")
	var game = load("res://scripts/game.gd").new()
	game._ready()
	_check("Huntcraft is a canonical Trade",
		String(game.TRADE_NAMES.get("huntcraft", "")) == "Huntcraft")
	_check("steady hands off at lv 1",
		not game.perk_active("huntcraft", "steady_hands"))
	_set_trade_level(game, "huntcraft", 5)
	_check("steady hands on at Huntcraft 5", game.perk_active("huntcraft", "steady_hands"))
	_check("hunters stride waits for 10",
		not game.perk_active("huntcraft", "hunters_stride"))
	_set_trade_level(game, "huntcraft", 10)
	_check("hunters stride on at lv 10",
		game.perk_active("huntcraft", "hunters_stride"))
	game.award_xp("wayfinding", 40)
	_check("Wayfinding XP stays separate from Huntcraft",
		int(game.trades.wayfinding.xp) == 40 and game.trade_lv("huntcraft") == 10)
	game.free()
	var independent = load("res://scripts/game.gd").new()
	independent._ready()
	independent.award_xp("wayfinding", 40)
	independent.award_xp("earthcraft", 96)
	independent.award_xp("wildcraft", 168)
	independent.award_xp("huntcraft", 256)
	_check("all four runtime XP pools remain independent",
		int(independent.trades.wayfinding.xp) == 40
			and int(independent.trades.earthcraft.xp) == 96
			and int(independent.trades.wildcraft.xp) == 168
			and int(independent.trades.huntcraft.xp) == 256,
		str(independent.trades))
	var authored_choice := false
	for trade_key in Progression.TRADE_KEYS:
		for level in range(1, Progression.LEVEL_CAP + 1):
			authored_choice = authored_choice \
				or independent.perks_at_level(level, trade_key).size() > 1
	_check("mastery choice machinery is honestly dormant",
		not authored_choice and independent.pending_mastery_levels().is_empty())
	independent.free()

# A7-full — the economy gate: smithed gear must never sell back to Hod for
# more than its Hod-buyable input cost (no vendor→forge→vendor gold loop).
# Inputs Hod doesn't sell (copper, palechalk) can't be farmed with gold, so
# a recipe carrying one is safe by construction.
func _test_economy_gate() -> void:
	print("[economy gate]")
	var prices := {}
	for w in EconomyData.WARES:
		prices[String(w.id)] = int(w.price)
	var gear := 0
	for rid in CraftingData.STATIONS.forge.recipes:
		var rec: Dictionary = CraftingData.recipe(String(rid))
		if not rec.has("yields_item"):
			continue
		gear += 1
		var sell: int = int(EconomyData.SELL_BY_RARITY.get(
			String((rec.yields_item as Dictionary).get("rarity", "normal")), 4))
		var cost := 0
		var buyable := true
		for mid in rec.inputs:
			var c: int = _buy_cost(String(mid), prices)
			if c < 0:
				buyable = false
				break
			cost += c * int(rec.inputs[mid])
		if buyable:
			_check("%s sells %dg < costs %dg" % [String(rid), sell, cost],
				sell < cost)
		else:
			_check("%s has an unbuyable input — no loop" % String(rid), true)
	_check("forge carries the full gear ladder", gear >= 12, str(gear))
	# The new recipes smith end-to-end with their gates and rarities.
	var game = load("res://scripts/game.gd").new()
	game._ready()
	game.add_material("bogiron_bar", 2)
	game.add_material("logs", 1)
	_check("cap gated at earth 1", not game.craft("forge", "bogiron_cap_smith"))
	_set_trade_level(game, "earthcraft", 5)
	_check("cap smiths at earth 5", game.craft("forge", "bogiron_cap_smith"))
	var helm = null
	for it in game.inventory.items:
		if String(it.get("kind_id", "")) == "leather_helm":
			helm = it
	_check("cap is a magic leather_helm", helm != null
		and String(helm.rarity) == "magic" and (helm.affixes as Array).size() == 1)
	_set_trade_level(game, "earthcraft", 9)
	game.add_material("palechalk", 2)
	game.add_material("copper_bar", 1)
	_check("palechalk ring smiths at earth 9",
		game.craft("forge", "palechalk_ring_smith"))
	var ring = null
	for it in game.inventory.items:
		if String(it.get("kind_id", "")) == "copper_ring":
			ring = it
	_check("ring rolls rare w/ 3 affixes", ring != null
		and String(ring.rarity) == "rare" and (ring.affixes as Array).size() == 3)
	game.free()

# A8-full — Quill's still: buff draughts + the timed-buff engine.
func _test_alchemy() -> void:
	print("[alchemy]")
	var st: Dictionary = CraftingData.station("still")
	_check("still station exists (Wildcraft, 5 brews + dewthread reagent)",
		String(st.get("trade", "")) == "wildcraft"
		and (st.get("recipes", []) as Array).size() == 6
		and (st.get("recipes", []) as Array).has("dewthread"), str(st))
	_check("still has a first-use hint",
		(load("res://scripts/game.gd").SKILL_HINTS as Dictionary).has("still"))
	var game = load("res://scripts/game.gd").new()
	game._ready()
	game.add_material("wild_herb", 3)
	_check("tonic gated at wilds 1", not game.craft("still", "quickroot_tonic"))
	_set_trade_level(game, "wildcraft", 3)
	_check("tonic brews at wilds 3", game.craft("still", "quickroot_tonic"))
	_check("tonic in satchel", game.material_count("quickroot_tonic") == 1)
	# Quaffing the buff shelf: bottle spent, buff live, channels run faster.
	var GatherNode = load("res://scripts/gather_node.gd")
	var bare: float = GatherNode.channel_seconds("forage_node", game)
	_check("quaff the tonic", game.quaff_buff_draught())
	_check("bottle spent", game.material_count("quickroot_tonic") == 0)
	_check("gather buff live",
		absf(float(game.buff_value("gather_speed")) - 0.25) < 0.001)
	var quick: float = GatherNode.channel_seconds("forage_node", game)
	_check("channels run a quarter faster", absf(quick - bare * 0.75) < 0.01,
		"%.2f vs %.2f" % [quick, bare])
	# The sip ticks down and fades (90s duration).
	game._process(60.0)
	_check("still humming at 60s", game.buff_value("gather_speed") > 0.0)
	game._process(31.0)
	_check("faded after 91s", game.buff_value("gather_speed") < 0.001)
	_check("fade restores the channel",
		absf(GatherNode.channel_seconds("forage_node", game) - bare) < 0.01)
	# Clearwater: palechalk-gated focus philter.
	game.add_material("wild_herb", 2)
	game.add_material("palechalk", 1)
	_check("philter gated at wilds 3",
		not game.craft("still", "clearwater_philter"))
	_set_trade_level(game, "wildcraft", 6)
	_check("philter brews at wilds 6", game.craft("still", "clearwater_philter"))
	_check("quaff the philter", game.quaff_buff_draught())
	_check("focus buff live",
		absf(float(game.buff_value("focus_regen")) - 0.5) < 0.001)
	# Empty shelf refuses politely; the heal shelf stays its own verb.
	_check("empty buff shelf returns false", not game.quaff_buff_draught())
	game.add_material("hearth_draught", 1)
	_check("heal shelf untouched by the still", game.quaff_draught() == 35)
	_check("can't brew at the hearth", not game.craft("cookfire", "quickroot_tonic"))
	game.free()

# Hod's effective price for a material, following smelt recipes one level
# down (bogiron_bar = 2× bogiron_ore). -1 = not buyable at any price.
func _buy_cost(id: String, prices: Dictionary) -> int:
	if prices.has(id):
		return int(prices[id])
	for rid in CraftingData.RECIPES:
		var rec: Dictionary = CraftingData.RECIPES[rid]
		if String(rec.get("yields_material", "")) != id:
			continue
		var total := 0
		for mid in rec.inputs:
			var c: int = _buy_cost(String(mid), prices)
			if c < 0:
				return -1
			total += c * int(rec.inputs[mid])
		return ceili(float(total) / float(rec.get("yields_n", 1)))
	return -1

# Spec 43 — recipe discovery: the experiment resolver.
func _test_discovery() -> void:
	print("[discovery]")
	var game = load("res://scripts/game.gd").new()
	game._ready()
	_check("fresh game knows only hedge ink",
		game.discovered_inks == ["hedge_ink"], str(game.discovered_inks))
	var meta_ok := true
	for rid in GatherDefs.INK_RECIPE_ORDER:
		if not (GatherDefs.INK_RECIPES[rid].has("riddle")
				and GatherDefs.INK_RECIPES[rid].has("hint_key")):
			meta_ok = false
	_check("riddle + hint key on every recipe", meta_ok)
	for iid in ["ash_ink", "chalkwash_ink"]:
		_check("%s defined end-to-end" % iid, GatherDefs.MATERIALS.has(iid)
			and ChartsData.INKS.has(iid) and GatherDefs.INK_RECIPES.has(iid))
	var w := ChartsData.compute_weights(1, ["ash_ink"], 9)
	var w0 := ChartsData.compute_weights(1, [], 9)
	_check("ash ink raises wood_grove share",
		float(w.get("wood_grove", 0.0)) > float(w0.get("wood_grove", 0.0)))
	# Exact match + undiscovered → discovery: mix, learn, +50 carto.
	game.add_material("bogiron_ore", 2)
	var xp0: int = int(game.trades.wayfinding.xp)
	var r: Dictionary = game.try_pot_mix({"bogiron_ore": 2})
	_check("try discovers stoneground",
		String(r.get("outcome", "")) == "discovery"
		and game.ink_discovered("stoneground_ink")
		and game.material_count("stoneground_ink") == 1
		and game.material_count("bogiron_ore") == 0, str(r))
	_check("discovery pays 50 carto", int(game.trades.wayfinding.xp) - xp0 == 50)
	# The same recipe again is a plain mix — no second bonus.
	game.add_material("bogiron_ore", 2)
	xp0 = int(game.trades.wayfinding.xp)
	r = game.try_pot_mix({"bogiron_ore": 2})
	_check("known recipe just mixes", String(r.get("outcome", "")) == "mix"
		and int(game.trades.wayfinding.xp) == xp0)
	# A junk pot: consumed minus the cheapest consolation, +5 carto, and
	# one of the three miss outcomes.
	game.add_material("wild_herb", 1)
	game.add_material("bogiron_ore", 1)
	xp0 = int(game.trades.wayfinding.xp)
	var inks0 := 0
	for id in GatherDefs.INK_RECIPE_ORDER:
		inks0 += game.material_count(String(id))
	r = game.try_pot_mix({"wild_herb": 1, "bogiron_ore": 1})
	var outcome := String(r.get("outcome", ""))
	_check("junk pot resolves to a miss",
		outcome in ["smudge", "wild", "serendipity"], outcome)
	_check("herb kept back, ore spent",
		game.material_count("wild_herb") == 1
		and game.material_count("bogiron_ore") == 0)
	_check("the failed experiment teaches 5 carto",
		int(game.trades.wayfinding.xp) - xp0 == 5)
	var inks1 := 0
	for id in GatherDefs.INK_RECIPE_ORDER:
		inks1 += game.material_count(String(id))
	_check("an ink bottle lands iff not a smudge",
		(inks1 - inks0) == (0 if outcome == "smudge" else 1),
		"%s: %d new" % [outcome, inks1 - inks0])
	game.free()

# Spec 45 — the trade ladders to the level-17 cap (ADR 0006).
func _test_ladders() -> void:
	print("[trade ladders]")
	var game = load("res://scripts/game.gd").new()
	game._ready()
	_check("level cap is 23", int(game.LEVEL_CAP) == 23)
	_set_trade_level(game, "earthcraft", 22)
	game.award_xp("earthcraft", 100000)
	_check("award clamps at the cap", game.trade_lv("earthcraft") == 23,
		str(game.trade_lv("earthcraft")))
	# Herb ladder: six tiers, reqs ascend 1/3/7/10/13/16, real materials.
	var ht: Dictionary = GatherDefs.HERB_TIERS
	_check("six herb tiers", ht.size() == 6)
	var reqs: Array = []
	for tid in ["wild", "bittergrass", "crowsfoot", "mothmint", "foxglove",
			"stonebreak"]:
		_check("%s herb is a real material" % tid,
			ht.has(tid) and GatherDefs.MATERIALS.has(String(ht[tid].item)))
		reqs.append(int(ht[tid].req_lv))
	_check("herb reqs run 1/3/7/10/13/16", reqs == [1, 3, 7, 10, 13, 16],
		str(reqs))
	# Ore ladder grew to five.
	_check("five ore tiers", (GatherDefs.ORE_TIERS as Dictionary).size() == 5
		and int(GatherDefs.ORE_TIERS.starsilver.req_lv) == 11
		and int(GatherDefs.ORE_TIERS.hedgesteel.req_lv) == 15)
	# Herb-tier node gating mirrors ore (Wildcraft gates it).
	var GatherNode = load("res://scripts/gather_node.gd")
	var node = GatherNode.new()
	node.setup("forage_node", "mothmint", false)
	node.setup_herb_tier("mothmint")
	_set_trade_level(game, "wildcraft", 1)
	_check("mothmint locked at lv 1", node.locked(game))
	_set_trade_level(game, "wildcraft", 10)
	_check("mothmint opens at lv 10", not node.locked(game))
	_check("perks are owned by their actual Trades",
		(game.PERKS.wayfinding as Array).size() == 6
			and (game.PERKS.earthcraft as Array).size() == 4
			and (game.PERKS.wildcraft as Array).size() == 4
			and (game.PERKS.huntcraft as Array).size() == 5)
	# The heal ladder quaffs smallest-first: 35/55/80/140/220.
	game.add_material("hale_draught", 1)
	game.add_material("bitter_draught", 1)
	_check("bitter quaffs before hale", game.quaff_draught() == 55)
	_check("then the hale bottle", game.quaff_draught() == 140)
	# New brews carry their stats.
	_check("deep brews defined", String(CraftingData.BUFF_DRAUGHTS
		.crowsfoot_cordial.stat) == "move_speed"
		and String(CraftingData.BUFF_DRAUGHTS.mothmint_mend.stat) == "vigor_regen"
		and String(CraftingData.BUFF_DRAUGHTS.stonebreak_tonic.stat) == "grit")
	# Ten discoverable inks now include the Ashen Bough's level-20 Emberleaf.
	_check("ten ink recipes include Wildcraft-gated Mire and Emberleaf Inks",
		(GatherDefs.INK_RECIPE_ORDER as Array).size() == 10
		and GatherDefs.INK_RECIPE_ORDER.has("mire_ink")
		and int(GatherDefs.INK_RECIPES.mire_ink.req_wildcraft) == 10
		and GatherDefs.INK_RECIPE_ORDER.has("emberleaf_ink")
		and int(GatherDefs.INK_RECIPES.emberleaf_ink.req_wildcraft) == 20)
	var wg := ChartsData.compute_weights(2, ["gildleaf_ink"], 20)
	var w0g := ChartsData.compute_weights(2, [], 20)
	_check("gildleaf raises gilded share",
		float(wg.get("gilded", 0.0)) > float(w0g.get("gilded", 0.0)))
	# Carto perk math: Sure Lines +5 stability, Thrifty Quill −1 hedge.
	_check("sure lines leans 5 points",
		ChartsData.effective_stability("mineral_vein", 1, 0.0, 0.05)
		== ChartsData.effective_stability("mineral_vein", 1, 0.0) + 5)
	_check("thrifty quill trims the base hedge cost",
		int(ChartsData.craft_cost("tier_1", [], "", 1).get("hedge_ink", 0))
		== int(ChartsData.craft_cost("tier_1", []).get("hedge_ink", 0)) - 1)
	_check("the trim floors at one pot",
		int(ChartsData.craft_cost("snug", [], "", 1).get("hedge_ink", 99)) >= 1)
	# Light Hands: forage channels a quarter faster at wilds 13.
	_set_trade_level(game, "wildcraft", 13)
	_check("light hands cuts the forage channel",
		absf(GatherNode.channel_seconds("forage_node", game) - 0.75) < 0.01)
	# Tier-2 charts grow tier-2..4 herbs (deterministic seed).
	var lay := DungeonGenScript.generate(4242, {"grid": 36, "room_min": 7,
		"room_max": 11, "boss_kind": "", "tier": 2,
		"affixes": [{"id": "bramble_bloom", "good": true,
			"resolvedId": "bramble_bloom"}]})
	var herbs_ok := true
	var saw_herb := false
	for d in lay.decor:
		if bool(d.get("gather", false)) and String(d.kind) == "forage_node":
			saw_herb = true
			if not String(d.get("herb_tier", "")) in \
					["bittergrass", "crowsfoot", "mothmint", "foxglove"]:
				herbs_ok = false
	_check("tier-2 blooms grow herb tiers 2-5", saw_herb and herbs_ok)
	# The Summit carries two fixed hedgesteel veins (tier-3, no affixes).
	var summit_lay := DungeonGenScript.generate(7, {"grid": 44, "room_min": 7,
		"room_max": 12, "boss_kind": "hedgemother_queen", "tier": 3,
		"affixes": []})
	var hs := 0
	var sb := 0
	for d in summit_lay.decor:
		if String(d.get("ore_tier", "")) == "hedgesteel":
			hs += 1
		if String(d.get("herb_tier", "")) == "stonebreak":
			sb += 1
	_check("summit holds 2 fixed hedgesteel veins", hs == 2, str(hs))
	_check("summit grows 2 fixed stonebreak patches", sb == 2, str(sb))
	# The capstone gear never drops as random loot.
	var Drops = load("res://data/drops.gd")
	var saw_capstone := false
	for _i in 400:
		if String(Drops._pick_kind()) in ["warbow", "starsilver_band"]:
			saw_capstone = true
	_check("capstone gear excluded from the drop pool", not saw_capstone)
	game.free()

func _test_save_roundtrip() -> void:
	print("[save/load]")
	# Throwaway path — NEVER the real SAVE_PATH. This suite once wrote then
	# clear()'d the player's actual save (CLAUDE.md footgun); save_to/load_from
	# overloads let us round-trip against a temp file instead.
	const RT_PATH := "user://wyrd_test_loop_roundtrip.json"
	var game = load("res://scripts/game.gd").new()
	game._ready()
	_set_trade_level(game, "wayfinding", 4)
	game.add_material("wild_herb", 5)
	var legacy_chart := {"template_id": "tier_1", "tier": 1, "scope": "hollow",
		"name": "Tier 1 Hollow", "seed": 42, "affixes": [
			{"id": "mineral_vein", "good": true, "resolvedId": "mineral_vein"}]}
	game.charts.append(legacy_chart.duplicate(true))
	game.tutorial_step = 6
	game.player_hp = 17
	game.gold = 57
	game.summit_cleared = true
	game.muted = true   # spec 38 — the mute preference rides the save
	game.owned_skills = ["PiercingBolt", "MultiShot", "RainOfThorns"]
	game.loadout = ["PiercingBolt", "MultiShot", "RainOfThorns"]
	# ADR 0012 — the save now carries a single Wayfinding skill.
	game.discovered_inks = ["hedge_ink", "ash_ink"]   # spec 43 rides the save
	game.known_chart_recipes = ["snug"]
	game.chart_source_unlocks = ["atlas_deep_hollow"]
	game.second_hand_clues = ["far_waystone", "inked_scrap"]
	var ItemsData = load("res://data/items.gd")
	var item: Dictionary = ItemsData.make_item("shortbow", "magic")
	var fit: Dictionary = game.inventory.find_first_fit(item)
	game.inventory.try_place(item, fit.pos, fit.rotated)
	game.equipment.slots["helmet"] = ItemsData.make_item("leather_helm", "rare")
	_check("save written", SaveGame.save_to(RT_PATH, game))
	var game2 = load("res://scripts/game.gd").new()
	game2._ready()
	_check("load ok", SaveGame.load_from(RT_PATH, game2) == SaveGame.LOAD_RESULT.OK)
	_check("trade restored", game2.trade_lv("wayfinding") == 4)
	_check("satchel restored", game2.material_count("wild_herb") == 5)
	var restored_chart: Dictionary = game2.charts[0] if not game2.charts.is_empty() else {}
	_check("legacy Chart restores without recipe/component fields",
		(game2.charts as Array).size() == 1
		and restored_chart.size() == legacy_chart.size()
		and String(restored_chart.template_id) == "tier_1"
		and int(restored_chart.tier) == 1
		and String(restored_chart.scope) == "hollow"
		and int(restored_chart.seed) == 42
		and not restored_chart.has("recipe_id")
		and not restored_chart.has("placed_components"), str(restored_chart))
	_check("tutorial step restored", int(game2.tutorial_step) == 6)
	_check("hp restored", int(game2.player_hp) == 17)
	_check("gold restored", int(game2.gold) == 57)
	_check("summit flag restored", bool(game2.summit_cleared))
	_check("muted restored", bool(game2.muted))
	_check("gear item restored w/ Vector2i", game2.inventory.items.size() == 1
		and game2.inventory.items[0].size is Vector2i
		and String(game2.inventory.items[0].kind_id) == "shortbow")
	var helm = game2.equipment.get_slot("helmet")
	_check("equipment restored w/ Color", helm != null and helm.icon_color is Color)
	_check("tutorial repair retains Power Shot in the loadout", game2.loadout ==
		["PiercingBolt", "MultiShot", "PowerShot"])
	_check("all canonical Trades restore",
		(game2.trades as Dictionary).keys() == Progression.TRADE_KEYS
			and game2.trade_lv("wayfinding") == 4)
	_check("discovered inks restored",
		game2.discovered_inks == ["hedge_ink", "ash_ink"])
	_check("known Chart Recipes restored exactly",
		game2.known_chart_recipes == ["snug"], str(game2.known_chart_recipes))
	_check("Chart source unlocks restored exactly",
		game2.chart_source_unlocks == ["atlas_deep_hollow"],
		str(game2.chart_source_unlocks))
	_check("second hand clues restored",
		game2.second_hand_clues == ["far_waystone", "inked_scrap"])
	# Spec 43 — a save from before discovery (no key) keeps all three
	# original inks: doctor the file, reload, assert the backfill.
	var fdoc := FileAccess.open(RT_PATH, FileAccess.READ)
	var raw: Dictionary = JSON.parse_string(fdoc.get_as_text())
	fdoc.close()
	raw.erase("discovered_inks")
	raw.erase("known_chart_recipes")
	# A pre-Slice-A level-16 save had every current template unlocked. Its
	# recipe backfill must preserve that access rather than resetting to level 1.
	raw.trades.wayfinding = {"lv": 16, "xp": game.xp_for_level(16)}
	fdoc = FileAccess.open(RT_PATH, FileAccess.WRITE)
	fdoc.store_string(JSON.stringify(raw))
	fdoc.close()
	var game3 = load("res://scripts/game.gd").new()
	game3._ready()
	_check("pre-43 load ok", SaveGame.load_from(RT_PATH, game3) == SaveGame.LOAD_RESULT.OK)
	_check("pre-43 save keeps its three inks", game3.discovered_inks ==
		["hedge_ink", "stoneground_ink", "refined_ink"],
		str(game3.discovered_inks))
	_check("pre-58 level-16 save receives all six legacy recipes",
		game3.known_chart_recipes == ChartsData.legacy_recipe_ids_for_level(16),
		str(game3.known_chart_recipes))
	game3.free()
	# Clean up ONLY the temp file (+ its .bak/.tmp), never the real save.
	for ext in ["", ".bak", ".tmp"]:
		var gp := ProjectSettings.globalize_path(RT_PATH + ext)
		if FileAccess.file_exists(RT_PATH + ext):
			DirAccess.remove_absolute(gp)
	_check("save file cleaned up", not FileAccess.file_exists(RT_PATH))
	game.free()
	game2.free()

func _test_charts_data() -> void:
	print("[charts data]")
	# Weight gating: carto 1 only sees mineral_vein (req 1).
	var w1 := ChartsData.compute_weights(1, [], 1)
	_check("carto-1 weights = mineral_vein only",
		w1.size() == 1 and w1.has("mineral_vein"), str(w1.keys()))
	var w9 := ChartsData.compute_weights(1, [], 9)
	# req ≤ 9: mineral_vein 1, bramble_bloom 4, tyrannical 5, sprinter 6,
	# wood_grove 7, festival_pace 7, quiver 8, gilded 9. Boss dens never
	# roll at random (trophy slot only).
	_check("carto-9 unlocks 8 random affixes", w9.size() == 8, str(w9.keys()))
	# Ink bias multiplies and renormalizes.
	var wb := ChartsData.compute_weights(1, ["hedge_ink"], 9)
	_check("hedge ink raises bramble_bloom share",
		wb.get("bramble_bloom", 0.0) > w9.get("bramble_bloom", 0.0))
	_check("refined ink stability bonus = 0.10",
		absf(ChartsData.ink_stability_bonus(["refined_ink"]) - 0.10) < 0.001)
	_check("stability caps at 95",
		ChartsData.effective_stability("mineral_vein", 99, 0.5) == 95)
	# Inscribe shapes.
	var snug := ChartsData.inscribe("snug", [], 1)
	_check("snug chart has 0 affixes", (snug.affixes as Array).is_empty())
	_check("snug scope", String(snug.scope) == "snug")
	var t1 := ChartsData.inscribe("tier_1", [], 1)
	_check("tier_1 rolls 1 affix", (t1.affixes as Array).size() == 1, str(t1))
	# Completion XP: tier×75 + good×40 + bad×10.
	var fake := {"tier": 2, "affixes": [
		{"id": "a", "good": true}, {"id": "b", "good": false}]}
	_check("completion xp 2/1good/1bad = 200",
		ChartsData.completion_xp(fake) == 200,
		str(ChartsData.completion_xp(fake)))
	_check("Snug completion pays 8 gold",
		ChartsData.completion_gold(snug) == 8)
	_check("Tier 1 with one affix pays 12 gold",
		ChartsData.completion_gold(t1) == 12)
	# Costs: base + slotted inks.
	var cost := ChartsData.craft_cost("tier_1", ["hedge_ink", "refined_ink"])
	_check("tier_1 + 2 inks cost", int(cost.get("hedge_ink", 0)) == 3
		and int(cost.get("refined_ink", 0)) == 1, str(cost))

func _test_chart_recipe_resolver() -> void:
	print("[Chart Recipe resolver]")
	_check("six legacy templates retain mappings beside authored chapter recipes",
		ChartsData.TEMPLATE_ORDER.size() == 6
		and ChartsData.CHART_RECIPES.size() == ChartsData.CHART_RECIPE_ORDER.size()
		and ChartsData.CHART_RECIPES.has("sallow_shallows")
		and ChartsData.CHART_RECIPES.has("golden_wallow_boss")
		and ChartsData.LEGACY_TEMPLATE_TO_RECIPE.size() == 6)
	var all_recipe_ids := ChartsData.legacy_recipe_ids_for_level(99)
	_check("legacy recipe order excludes the clue-gated campaign recipe",
		all_recipe_ids.size() == 6
		and not all_recipe_ids.has("first_knot_boss")
		and ChartsData.CHART_RECIPE_ORDER.has("first_knot_boss"),
		str(all_recipe_ids))
	var all_unsealed_mapped := true
	for template_id in ChartsData.TEMPLATE_ORDER:
		if String(template_id) == "summit":
			continue
		var resolution: Dictionary = ChartsData.resolve_legacy_template(
			String(template_id), [], "", {
				"level": 99,
				"wildcraft_level": 99,
				"known_recipe_ids": all_recipe_ids,
			})
		var template: Dictionary = ChartsData.TEMPLATES[template_id]
		all_unsealed_mapped = all_unsealed_mapped and bool(resolution.valid) \
			and bool(resolution.known) \
			and String(resolution.output.template_id) == String(template_id) \
			and int(resolution.output.tier) == int(template.tier) \
			and String(resolution.output.scope) == String(template.scope) \
			and resolution.costs == ChartsData.craft_cost(String(template_id), [])
	_check("five unsealed compatibility recipes preserve template output and base cost",
		all_unsealed_mapped)
	var summit_compat: Dictionary = ChartsData.resolve_legacy_template("summit", [], "", {
		"level": 99, "known_recipe_ids": all_recipe_ids,
	})
	_check("legacy Summit preview now waits for its visible Story Seal",
		String(summit_compat.state) == "incomplete"
		and String(summit_compat.recipe_id) == "queens_summit"
		and bool(summit_compat.requires_seal))
	# Resolver purity: no mutation, no RNG/seed in the preview.
	var pattern: Dictionary = (ChartsData.CHART_RECIPES.green_hollow.pattern \
		as Dictionary).duplicate(true)
	var before := pattern.duplicate(true)
	var plain: Dictionary = ChartsData.resolve_chart_recipe(pattern, [], "", {
		"level": 9, "known_recipe_ids": []})
	_check("resolver is pure over placed components",
		pattern == before and not plain.output.has("seed"), str(pattern))
	_check("an attemptable unknown recipe resolves without becoming known",
		bool(plain.valid) and not bool(plain.known)
		and String(plain.recipe_id) == "green_hollow")
	var known: Dictionary = ChartsData.resolve_chart_recipe(pattern,
		["hedge_ink"], "", {
			"level": 9, "known_recipe_ids": ["green_hollow"]})
	_check("known state and Ink-biased odds ride one preview",
		bool(known.valid) and bool(known.known)
		and float(known.affix_weights.get("bramble_bloom", 0.0))
			> float(plain.affix_weights.get("bramble_bloom", 0.0))
		and not (known.stability as Dictionary).is_empty())
	_check("resolver cost matches the shipped helper",
		known.costs == ChartsData.craft_cost("tier_1", ["hedge_ink"]),
		str(known.costs))
	# Invalid patterns and level gates return no spendable preview.
	var impossible := ChartsData.resolve_chart_recipe({
		"n": "mire_reed", "c": "field_parchment", "w": "loop_cord",
	}, [], "", {"level": 99})
	_check("invalid arrangement spends nothing",
		not bool(impossible.valid) and (impossible.costs as Dictionary).is_empty()
		and String(impossible.reason) != "")
	var locked := ChartsData.resolve_legacy_template("hollow", [], "", {"level": 1})
	_check("resolver owns the Wayfinding gate",
		not bool(locked.valid) and String(locked.reason).contains("Wayfinding 10"))
	# A current trophy still guarantees the same den Affix and cost; inscription
	# consumes the exact resolved inputs through the compatibility seam.
	var sealed := ChartsData.resolve_legacy_template("tier_1", [],
		"thorn_essence", {
			"level": 99, "known_recipe_ids": all_recipe_ids,
		})
	_check("Seal preview owns guarantee and cost",
		bool(sealed.valid) and (sealed.guaranteed as Array).size() == 1
		and String(sealed.guaranteed[0].id) == "hedgemother_den"
		and int(sealed.costs.get("thorn_essence", 0)) == 1)
	var sealed_chart := ChartsData.inscribe_resolved(sealed)
	_check("resolved inscription preserves the shipped Chart shape",
		String(sealed_chart.template_id) == "tier_1"
		and int(sealed_chart.tier) == 1
		and String(sealed_chart.scope) == "hollow"
		and (sealed_chart.affixes as Array).size() == 1
		and String(sealed_chart.affixes[0].id) == "hedgemother_den"
		and sealed_chart.has("seed"))

func _test_chart_table_domain() -> void:
	print("[Chart Table Slice B domain]")
	var fresh_context := {
		"level": 1, "known_recipe_ids": ["snug"],
		"first_snug_returned": false,
	}
	var blank := ChartsData.preview_table(ChartsData.empty_table_draft(), fresh_context)
	_check("blank table is incomplete, not spendable",
		String(blank.state) == "incomplete" and not bool(blank.commit_ready)
		and (blank.costs as Dictionary).is_empty())
	var unlocks: Dictionary = blank.unlocks
	_check("fresh table reveals only Base, first Waymark, and Ink 1",
		bool(unlocks.grid.c.unlocked) and bool(unlocks.grid.n.unlocked)
		and bool(unlocks.ink_rail[0].unlocked)
		and not bool(unlocks.grid.w.unlocked)
		and not bool(unlocks.grid.s.unlocked)
		and not bool(unlocks.ink_rail[1].unlocked))
	var returned_context := fresh_context.duplicate(true)
	returned_context.first_snug_returned = true
	var returned_unlocks := ChartsData.table_unlocks(returned_context)
	_check("first Snug return opens Binding W independent of level",
		bool(returned_unlocks.grid.w.unlocked))
	var milestone_context := returned_context.duplicate(true)
	milestone_context.level = 22
	var milestone_unlocks := ChartsData.table_unlocks(milestone_context)
	_check("level gates reveal all four Inks, Seal, Waymarks, Binding E, and Relics",
		(milestone_unlocks.ink_rail as Array).all(func(x): return bool(x.unlocked))
		and bool(milestone_unlocks.grid.s.unlocked)
		and bool(milestone_unlocks.grid.ne.unlocked)
		and bool(milestone_unlocks.grid.e.unlocked)
		and bool(milestone_unlocks.grid.sw.unlocked)
		and bool(milestone_unlocks.grid.se.unlocked))
	var snug_grid := {"n": "hedge_sprig", "c": "practice_leaf"}
	var dry := ChartsData.preview_table({"grid": snug_grid, "ink_rail": []},
		fresh_context)
	_check("Snug waits visibly for its required Hedge Ink",
		String(dry.state) == "incomplete" and String(dry.recipe_id) == "snug"
		and dry.required_inks == ["hedge_ink"] and (dry.costs as Dictionary).is_empty())
	var snug_draft := {"grid": snug_grid, "ink_rail": ["hedge_ink"]}
	var snug := ChartsData.preview_table(snug_draft, fresh_context)
	var snug_again := ChartsData.preview_table(snug_draft, fresh_context)
	_check("Snug has one required Ink, zero bias capacity, and zero odds",
		bool(snug.commit_ready) and String(snug.state) == "known"
		and snug.required_inks == ["hedge_ink"]
		and (snug.bias_inks as Array).is_empty() and int(snug.bias_capacity) == 0
		and (snug.affix_weights as Dictionary).is_empty())
	_check("Snug charges physical pieces and Hedge Ink exactly once",
		int(snug.component_cost.practice_leaf) == 1
		and int(snug.component_cost.hedge_sprig) == 1
		and int(snug.reagent_cost.hedge_ink) == 1
		and int(snug.costs.hedge_ink) == 1)
	_check("same draft and context have a stable preview fingerprint",
		String(snug.fingerprint) != "" and snug == snug_again)
	var too_much_ink := ChartsData.preview_table({"grid": snug_grid,
		"ink_rail": ["hedge_ink", "refined_ink"]}, fresh_context)
	_check("locked or excess Ink is invalid and costs nothing",
		String(too_much_ink.state) == "invalid"
		and (too_much_ink.costs as Dictionary).is_empty())
	var wrong_kind := ChartsData.preview_table({"grid": {
		"n": "practice_leaf", "c": "hedge_sprig"}, "ink_rail": []}, fresh_context)
	_check("wrong component kind is invalid and costs nothing",
		String(wrong_kind.state) == "invalid"
		and (wrong_kind.costs as Dictionary).is_empty())
	var green_draft := {"grid": {"n": "hedge_sprig", "c": "field_parchment",
		"w": "loop_cord"}, "ink_rail": []}
	var green_context := returned_context.duplicate(true)
	green_context.level = 4   # Bramble Bloom is present, so Hedge Ink can lean it.
	var green := ChartsData.preview_table(green_draft, green_context)
	_check("exact unknown arrangement is attemptable",
		bool(green.commit_ready) and String(green.state) == "attemptable"
		and not bool(green.known) and String(green.recipe_id) == "green_hollow")
	var green_inked_draft := green_draft.duplicate(true)
	green_inked_draft.ink_rail = ["hedge_ink"]
	var green_inked := ChartsData.preview_table(green_inked_draft, green_context)
	_check("Ink changes odds but never Chart identity",
		green.output == green_inked.output
		and float(green_inked.affix_weights.get("bramble_bloom", 0.0))
			> float(green.affix_weights.get("bramble_bloom", 0.0)))
	var seeded_a := ChartsData.materialize_chart(green_inked, 424242)
	var seeded_a_again := ChartsData.materialize_chart(green_inked, 424242)
	var seeded_b := ChartsData.materialize_chart(green_inked, 424243)
	_check("same preview and seed materialize deep-equal Charts",
		seeded_a == seeded_a_again)
	_check("different seeds preserve deterministic Chart identity",
		int(seeded_a.seed) != int(seeded_b.seed)
		and String(seeded_a.template_id) == String(seeded_b.template_id)
		and int(seeded_a.tier) == int(seeded_b.tier)
		and String(seeded_a.scope) == String(seeded_b.scope))
	var bundle := ChartsData.compatibility_component_bundle(
		["snug", "queens_summit", "unknown"])
	_check("legacy bundle uses maximum ordinary component multiplicity only",
		int(bundle.get("practice_leaf", 0)) == 1
		and int(bundle.get("cold_track", 0)) == 2
		and int(bundle.get("climbing_cord", 0)) == 2
		and not bundle.has("hedge_ink") and not bundle.has("alpha_fang"))
	var shapes_registered := true
	for component_id in ChartsData.COMPONENT_ORDER:
		shapes_registered = shapes_registered \
			and GatherDefs.MATERIALS.has(component_id) \
			and GatherDefs.material_icon_shape(component_id) != "" \
			and GatherDefs.material_icon(component_id) == ""
	_check("component materials expose shape metadata rather than glyph icons",
		shapes_registered)

func _new_table_test_game() -> Node:
	var game = load("res://scripts/game.gd").new()
	game.persistence_enabled = false
	game.trades = Progression.fresh_trade_state()
	game.materials = {}
	game.charts = []
	game.known_chart_recipes = ["snug"]
	game.seen_hints = {}
	game.tutorial_step = 0
	return game

func _test_chart_codex_domain() -> void:
	print("[Chart Table Slice C1 domain]")
	var records_valid := true
	for rumour_id in ChartsData.CHART_RUMOUR_ORDER:
		var record: Dictionary = ChartsData.CHART_RUMOURS.get(rumour_id, {})
		records_valid = records_valid \
			and ChartsData.CHART_RECIPES.has(String(record.get("recipe_id", ""))) \
			and String(record.get("source", "")) != "" \
			and String(record.get("riddle", "")) != "" \
			and (record.get("clues", []) as Array).size() >= 2
	_check("every authored recipe has rumour presentation",
		ChartsData.CHART_RUMOURS.size() == ChartsData.CHART_RECIPES.size()
		and ChartsData.CHART_RUMOUR_ORDER.size() == ChartsData.CHART_RUMOURS.size()
		and records_valid)
	var known := ["snug", "green_hollow"]
	var malformed := {"rumours": ["mara_first_loop", "unknown",
		"mara_first_loop", "atlas_deep_hollow"], "discoveries": {
			"snug": "mara_lesson", "green_hollow": "forged",
			"deep_hollow": "table_experiment"}}
	var normalized := ChartsData.normalize_recipe_journal(malformed, known)
	_check("journal normalization validates, deduplicates, and preserves rumour order",
		normalized.rumours == ["mara_first_loop", "atlas_deep_hollow"])
	_check("journal normalization is fill-only and cannot grant knowledge",
		String(normalized.discoveries.snug) == "mara_lesson"
		and String(normalized.discoveries.green_hollow) == "legacy"
		and not (normalized.discoveries as Dictionary).has("deep_hollow")
		and known == ["snug", "green_hollow"])
	_check("journal normalization is idempotent",
		ChartsData.normalize_recipe_journal(normalized, known) == normalized)

	var fresh_context := {"level": 1, "known_recipe_ids": ["snug"],
		"recipe_journal": ChartsData.fresh_recipe_journal(),
		"material_counts": {"practice_leaf": 1, "hedge_sprig": 1,
			"hedge_ink": 1}, "first_snug_returned": false}
	var fresh_pages := ChartsData.codex_entries(fresh_context)
	var snug_page: Dictionary = fresh_pages[0]
	var later_unknown := true
	for index in range(1, fresh_pages.size()):
		later_unknown = later_unknown \
			and String((fresh_pages[index] as Dictionary).state) == "unknown"
	_check("fresh Codex knows Snug from Mara and leaves later records Unknown",
		fresh_pages.size() == ChartsData.CHART_RECIPE_ORDER.size()
		and String(snug_page.state) == "known"
		and String(snug_page.provenance) == "mara_lesson"
		and String(snug_page.history) == "Learned in Mara's first lesson."
		and later_unknown)
	_check("known page alone exposes an exact ghost draft",
		snug_page.ghost_draft == {"grid": {"n": "hedge_sprig",
			"c": "practice_leaf"}, "ink_rail": ["hedge_ink"]}
		and snug_page.pattern == {"n": "hedge_sprig", "c": "practice_leaf"}
		and snug_page.required_inks == ["hedge_ink"])

	var attempt_context := {"level": 2, "known_recipe_ids": ["snug"],
		"recipe_journal": ChartsData.fresh_recipe_journal(),
		"material_counts": {"field_parchment": 1, "hedge_sprig": 1,
			"loop_cord": 1}, "first_snug_returned": true}
	var attempt: Dictionary = ChartsData.codex_entry("green_hollow", attempt_context)
	_check("makings in hand create a redacted transient Attemptable record",
		String(attempt.state) == "attemptable"
		and String(attempt.knowledge_state) == "unknown"
		and bool(attempt.makings_in_hand)
		and (attempt.pattern as Dictionary).is_empty()
		and (attempt.ghost_draft as Dictionary).is_empty()
		and (attempt.output as Dictionary).is_empty()
		and (attempt.required_inks as Array).is_empty())
	var rumour_context := attempt_context.duplicate(true)
	rumour_context.recipe_journal = ChartsData.journal_with_rumour(
		ChartsData.fresh_recipe_journal(), "mara_first_loop", ["snug"])
	var rumoured: Dictionary = ChartsData.codex_entry("green_hollow", rumour_context)
	_check("rumour knowledge and makings readiness remain separate",
		String(rumoured.state) == "rumoured"
		and String(rumoured.knowledge_state) == "rumoured"
		and bool(rumoured.makings_in_hand)
		and (rumoured.clues as Array).size() == 3
		and (rumoured.pattern as Dictionary).is_empty()
		and (rumoured.ghost_draft as Dictionary).is_empty())
	_check("unknown recipe cannot request its canonical draft",
		ChartsData.known_draft("green_hollow", rumour_context).is_empty())
	var draft_copy: Dictionary = ChartsData.known_draft("snug", fresh_context)
	draft_copy.grid.erase("n")
	_check("known drafts are deep copies of authored recipe data",
		(ChartsData.CHART_RECIPES.snug.pattern as Dictionary).has("n"))

func _test_campaign_domain() -> void:
	print("[Slice D1 First Knot domain]")
	var malformed := {
		"version": 99, "next_attempt_id": -4,
		"chapters": {"first_knot": {"clue_count": 88, "cleared": false,
			"banked_chart_ids": ["chart-z", "chart-a", "chart-a", "",
				"chart-b", "chart-c"]},
			"invented": {"clue_count": 9, "cleared": true}},
		"relics": ["invented", "green_root_rune", "green_root_rune"],
		"restorations": ["trophy_hall", "invented"],
		"escrows": {"bad": {"chapter_id": "invented", "phase": "case"}},
	}
	var normalized := CampaignData.normalize_campaign_state(malformed)
	_check("campaign normalization is bounded and versioned",
		int(normalized.version) == CampaignData.STATE_VERSION
		and int(normalized.next_attempt_id) == 1
		and int(normalized.chapters.first_knot.clue_count) == 3
		and normalized.chapters.first_knot.banked_chart_ids \
			== ["chart-a", "chart-b", "chart-c"]
		and not bool(normalized.chapters.first_knot.cleared)
		and normalized.relics == ["green_root_rune"]
		and normalized.restorations == ["trophy_hall"]
		and (normalized.escrows as Dictionary).is_empty())
	_check("campaign normalization is idempotent",
		CampaignData.normalize_campaign_state(normalized) == normalized)
	var pre_correction := CampaignData.normalize_campaign_state({
		"chapters": {"first_knot": {"clue_count": 2, "cleared": false}}})
	_check("pre-correction D1 clue counts migrate to stable reserved tombstones",
		int(pre_correction.chapters.first_knot.clue_count) == 2
		and pre_correction.chapters.first_knot.banked_chart_ids \
			== ["legacy-banked-first-knot-1", "legacy-banked-first-knot-2"]
		and CampaignData.normalize_campaign_state(pre_correction) == pre_correction)

	var state := CampaignData.empty_state()
	var first_clue := CampaignData.next_clue_for_chart(
		state, "green_hollow", "chart-green-a", 4)
	var no_early_clue := CampaignData.next_clue_for_chart(
		state, "green_hollow", "chart-early", 3)
	var no_legacy_clue := CampaignData.next_clue_for_chart(state, "", "", 8)
	_check("generator query exposes only the next physical Green Hollow clue",
		String(first_clue.chapter_id) == "first_knot"
		and String(first_clue.clue_id) == "thorn_whisper_1"
		and String(first_clue.presentation) == "thorn_whisper"
		and no_early_clue.is_empty() and no_legacy_clue.is_empty()
		and CampaignData.chapter_clue_count(state) == 0)
	var early := CampaignData.record_successful_chart_return(
		state, "green_hollow", "chart-early", 3, {})
	var missing_id := CampaignData.record_successful_chart_return(
		state, "green_hollow", "", 8, {})
	var legacy := CampaignData.record_successful_chart_return(
		state, "", "", 8, {})
	_check("only provenance-marked Green returns at post-XP Wayfinding 4 count",
		not bool(early.changed) and not bool(missing_id.changed)
		and not bool(legacy.changed)
		and CampaignData.chapter_clue_count(state) == 0)
	var one := CampaignData.record_successful_chart_return(
		state, "green_hollow", "chart-green-a", 4, {})
	state = one.state
	var state_after_one := state.duplicate(true)
	var second_clue := CampaignData.next_clue_for_chart(
		state, "green_hollow", "chart-green-b", 4)
	var repeated := CampaignData.record_successful_chart_return(
		state, "green_hollow", "chart-green-a", 4, {})
	var two := CampaignData.record_successful_chart_return(
		state, "green_hollow", "chart-green-b", 4, {})
	state = two.state
	var three := CampaignData.record_successful_chart_return(
		state, "green_hollow", "chart-green-c", 4, {})
	state = three.state
	_check("three successful Green returns bank three authored Thorn Whispers",
		String(one.clue_id) == "thorn_whisper_1"
		and String(second_clue.clue_id) == "thorn_whisper_2"
		and not bool(repeated.changed) and repeated.state == state_after_one
		and String(two.clue_id) == "thorn_whisper_2"
		and String(three.clue_id) == "thorn_whisper_3"
		and CampaignData.chapter_clue_count(state) == 3)
	_check("third Whisper awards the missing Seal and boss rumour once",
		three.material_awards == {"thorn_essence": 1}
		and three.rumour_ids == ["mara_first_knot"])
	var capped := CampaignData.record_successful_chart_return(
		state, "green_hollow", "chart-green-d", 8, {})
	_check("First Knot clue progress caps without repeat rewards",
		not bool(capped.changed) and (capped.material_awards as Dictionary).is_empty()
		and (capped.rumour_ids as Array).is_empty()
		and CampaignData.next_clue_for_chart(
			state, "green_hollow", "chart-green-d", 8).is_empty())
	var with_seal := CampaignData.empty_state()
	for i in 2:
		with_seal = CampaignData.record_successful_chart_return(
			with_seal, "green_hollow", "chart-seal-%d" % i, 4,
			{"thorn_essence": 1}).state
	var no_duplicate_seal := CampaignData.record_successful_chart_return(
		with_seal, "green_hollow", "chart-seal-2", 4, {"thorn_essence": 1})
	_check("third Whisper lesson is missing-only for Thorn Essence",
		(no_duplicate_seal.material_awards as Dictionary).is_empty()
		and no_duplicate_seal.rumour_ids == ["mara_first_knot"])

	var boss_grid := {"n": "hedge_sprig", "c": "field_parchment",
		"w": "loop_cord", "s": "thorn_essence"}
	var boss_context := {"level": 8, "first_snug_returned": true,
		"known_recipe_ids": ["snug", "green_hollow"],
		"recipe_journal": ChartsData.journal_with_rumour(
			ChartsData.fresh_recipe_journal(), "mara_first_knot",
			["snug", "green_hollow"]),
		"material_counts": {"field_parchment": 1, "hedge_sprig": 1,
			"loop_cord": 1, "thorn_essence": 1, "hedge_ink": 2},
		"campaign_state": state,
	}
	var dry_boss := ChartsData.preview_table(
		{"grid": boss_grid, "ink_rail": []}, boss_context)
	var boss_draft := {"grid": boss_grid, "ink_rail": ["hedge_ink"]}
	var boss_preview := ChartsData.preview_table(boss_draft, boss_context)
	_check("WF8 Seal pattern resolves the distinct clue-gated Boss Recipe",
		bool(boss_preview.commit_ready)
		and String(boss_preview.recipe_id) == "first_knot_boss"
		and String(boss_preview.output.name) == "Hedgemother's Den"
		and int(boss_preview.costs.get("thorn_essence", 0)) == 1
		and int(boss_preview.costs.get("hedge_ink", 0)) == 2
		and boss_preview.required_inks == ["hedge_ink"]
		and String(dry_boss.state) == "incomplete"
		and not bool(dry_boss.commit_ready))
	_check("Boss preview promises the Hedgemother and its exact failure return",
		(boss_preview.guaranteed as Array).size() == 1
		and String(boss_preview.guaranteed[0].id) == "hedgemother"
		and bool(boss_preview.guaranteed[0].guaranteed)
		and boss_preview.returned_on_failure == {"thorn_essence": 1}
		and bool(boss_preview.requires_seal)
		and not (boss_preview.ordinary_costs as Dictionary).has("thorn_essence")
		and String(boss_preview.campaign_contract.chapter_id) == "first_knot")
	var boss_chart := ChartsData.materialize_chart(boss_preview, 818181)
	var boss_chart_again := ChartsData.materialize_chart(boss_preview, 818181)
	var has_old_den_affix := (boss_chart.affixes as Array).any(func(affix):
		return String((affix as Dictionary).get("id", "")) == "hedgemother_den")
	_check("materialized Boss Chart carries stable provenance and escrow metadata",
		boss_chart == boss_chart_again
		and String(boss_chart.recipe_id) == "first_knot_boss"
		and String(boss_chart.chart_instance_id) \
			== ChartsData.chart_instance_id("first_knot_boss", 818181)
		and String(boss_chart.campaign_contract.boss_kind) == "hedgemother"
		and String(boss_chart.seal_id) == "thorn_essence"
		and boss_chart.returned_on_failure == {"thorn_essence": 1})
	_check("authored Boss guarantee bypasses Empty-Den Affix RNG",
		not has_old_den_affix)
	var early_context := boss_context.duplicate(true)
	early_context.level = 7
	var early_boss := ChartsData.preview_table(boss_draft, early_context)
	_check("First Knot Boss Recipe is not spendable before Wayfinding 8",
		not bool(early_boss.commit_ready)
		and (early_boss.costs as Dictionary).is_empty())
	var stale_context := boss_context.duplicate(true)
	stale_context.campaign_state = CampaignData.empty_state()
	var stale_boss := ChartsData.preview_table(boss_draft, stale_context)
	_check("missing campaign progress rejects the Seal pattern without cost",
		not bool(stale_boss.commit_ready)
		and (stale_boss.costs as Dictionary).is_empty()
		and String(stale_boss.fingerprint) != String(boss_preview.fingerprint))
	var legacy_sealed := ChartsData.resolve_legacy_template("tier_1", [],
		"thorn_essence", {"level": 8, "known_recipe_ids": ["green_hollow"]})
	_check("legacy resolver remains campaign-inert and keeps den-Affix behavior",
		String(legacy_sealed.recipe_id) == "green_hollow"
		and (legacy_sealed.campaign_contract as Dictionary).is_empty()
		and String(legacy_sealed.guaranteed[0].id) == "hedgemother_den")

	var unknown_boss_context := boss_context.duplicate(true)
	unknown_boss_context.campaign_state = CampaignData.empty_state()
	unknown_boss_context.recipe_journal = ChartsData.fresh_recipe_journal()
	var unknown_page := ChartsData.codex_entry("first_knot_boss",
		unknown_boss_context)
	var rumoured_page := ChartsData.codex_entry("first_knot_boss", boss_context)
	_check("campaign recipe stays redacted until its earned rumour",
		String(unknown_page.state) == "unknown"
		and (unknown_page.pattern as Dictionary).is_empty()
		and String(rumoured_page.state) == "rumoured"
		and String(rumoured_page.source) == "Three Thorn Whispers"
		and (rumoured_page.pattern as Dictionary).is_empty())
	var known_boss_context := boss_context.duplicate(true)
	known_boss_context.known_recipe_ids = ["snug", "green_hollow", "first_knot_boss"]
	known_boss_context.recipe_journal = ChartsData.journal_with_discovery(
		boss_context.recipe_journal, "first_knot_boss", "table_experiment",
		known_boss_context.known_recipe_ids)
	var known_boss_draft := ChartsData.known_draft("first_knot_boss",
		known_boss_context)
	_check("Known Boss Recipe alone exposes its exact Seal ghost",
		String(known_boss_draft.grid.s) == "thorn_essence"
		and String(known_boss_draft.grid.c) == "field_parchment"
		and known_boss_draft.ink_rail == ["hedge_ink"])

	var boss_chart_id := String(boss_chart.chart_instance_id)
	var escrow_begin := CampaignData.begin_boss_escrow(state, boss_chart_id)
	var escrow_state: Dictionary = escrow_begin.state
	_check("inscription opens one monotonic Case escrow",
		bool(escrow_begin.ok) and bool(escrow_begin.changed)
		and String(escrow_begin.attempt_id) == "first_knot-1"
		and int(escrow_state.next_attempt_id) == 2
		and String(escrow_state.escrows[escrow_begin.attempt_id].phase) == "case")
	var blocked_second := CampaignData.begin_boss_escrow(
		escrow_state, "chart-other")
	var case_refund := CampaignData.refund_escrow(
		escrow_state, String(escrow_begin.attempt_id), boss_chart_id)
	_check("an unopened Case Chart neither duplicates nor refunds its Seal",
		not bool(blocked_second.ok) and not bool(case_refund.ok)
		and (case_refund.material_refunds as Dictionary).is_empty())
	var wrong_enter_chart := CampaignData.mark_escrow_in_run(
		escrow_state, String(escrow_begin.attempt_id), "chart-wrong")
	var wrong_enter_chapter := CampaignData.mark_escrow_in_run(
		escrow_state, String(escrow_begin.attempt_id), boss_chart_id, "wrong_chapter")
	_check("escrow entry rejects mismatched Chart and chapter identity",
		not bool(wrong_enter_chart.ok) and not bool(wrong_enter_chart.changed)
		and not bool(wrong_enter_chapter.ok) and not bool(wrong_enter_chapter.changed))
	var entered := CampaignData.mark_escrow_in_run(
		escrow_state, String(escrow_begin.attempt_id), boss_chart_id)
	var wrong_refund := CampaignData.refund_escrow(
		entered.state, String(escrow_begin.attempt_id), "chart-wrong")
	var wrong_refund_chapter := CampaignData.refund_escrow(
		entered.state, String(escrow_begin.attempt_id), boss_chart_id, "wrong_chapter")
	var refunded := CampaignData.refund_escrow(
		entered.state, String(escrow_begin.attempt_id), boss_chart_id)
	var refund_again := CampaignData.refund_escrow(
		refunded.state, String(escrow_begin.attempt_id), boss_chart_id)
	_check("unresolved entered attempt refunds the Seal exactly once",
		not bool(wrong_refund.ok) and not bool(wrong_refund_chapter.ok)
		and refunded.material_refunds == {"thorn_essence": 1}
		and bool(refund_again.ok) and not bool(refund_again.changed)
		and (refund_again.material_refunds as Dictionary).is_empty())
	var retry_begin := CampaignData.begin_boss_escrow(
		refunded.state, "chart-retry")
	var retry_enter := CampaignData.mark_escrow_in_run(
		retry_begin.state, String(retry_begin.attempt_id), "chart-retry")
	var wrong_defeat := CampaignData.resolve_boss_death(
		retry_enter.state, String(retry_begin.attempt_id), "chart-wrong")
	var wrong_defeat_chapter := CampaignData.resolve_boss_death(
		retry_enter.state, String(retry_begin.attempt_id), "chart-retry",
		"wrong_chapter")
	var defeated := CampaignData.resolve_boss_death(
		retry_enter.state, String(retry_begin.attempt_id), "chart-retry")
	var defeated_again := CampaignData.resolve_boss_death(
		defeated.state, String(retry_begin.attempt_id), "chart-retry")
	_check("boss death consumes escrow and grants chapter rewards once",
		not bool(wrong_defeat.ok) and not bool(wrong_defeat_chapter.ok)
		and defeated.material_awards == {"tusker_tusk": 1}
		and defeated.relic_awards == ["green_root_rune"]
		and defeated.restoration_awards == ["trophy_hall"]
		and CampaignData.chapter_cleared(defeated.state)
		and (defeated_again.material_awards as Dictionary).is_empty()
		and (defeated_again.relic_awards as Array).is_empty())
	var reused_chart := CampaignData.begin_boss_escrow(refunded.state, boss_chart_id)
	var invalid_chapter_begin := CampaignData.begin_boss_escrow(
		refunded.state, "chart-new", "wrong_chapter")
	_check("escrow begin rejects reused Chart identity and unknown chapter",
		not bool(reused_chart.ok) and not bool(invalid_chapter_begin.ok))
	var ledger_inferred := CampaignData.infer_legacy_clear(
		CampaignData.empty_state(), {"tusker_tusk": {"stat": "hp", "value": 12.0}})
	var summit_inferred := CampaignData.infer_legacy_clear(
		CampaignData.empty_state(), {}, true)
	var neither_inferred := CampaignData.infer_legacy_clear(
		CampaignData.empty_state(), {}, false)
	_check("legacy clear inference accepts Ledger-only or Summit-only evidence",
		bool(ledger_inferred.changed)
		and CampaignData.chapter_cleared(ledger_inferred.state)
		and bool(summit_inferred.changed)
		and CampaignData.chapter_cleared(summit_inferred.state)
		and not bool(neither_inferred.changed))

func _new_source_test_game(level: int = 1) -> SaveCountingGame:
	var game := SaveCountingGame.new()
	game.trades = Progression.fresh_trade_state()
	_set_trade_level(game, "wayfinding", level)
	game.materials = {}
	game.charts = []
	game.known_chart_recipes = ["snug", "green_hollow"]
	game.chart_recipe_journal = ChartsData.fresh_recipe_journal()
	game.chart_source_unlocks = []
	game.seen_hints = {}
	game.tutorial_step = 7
	return game

func _test_d2_chart_domain() -> void:
	print("[Slice D2 Table Deepening domain]")
	var context := {
		"level": 17, "wildcraft_level": 3, "first_snug_returned": true,
		"known_recipe_ids": ["snug", "green_hollow", "deep_hollow",
			"briar_maze", "sallow_mire"],
		"campaign_state": CampaignData.empty_state(),
	}
	var variant_cases := [
		{"recipe_id": "green_hollow", "grid": {"n": "hedge_sprig",
			"c": "field_parchment", "w": "loop_cord", "e": "loop_cord"},
			"binding": "loop_cord", "base": 1, "max": 2},
		{"recipe_id": "deep_hollow", "grid": {"n": "hedge_sprig",
			"c": "stitched_parchment", "w": "hollow_stitch", "e": "hollow_stitch"},
			"binding": "hollow_stitch", "base": 2, "max": 3},
		{"recipe_id": "briar_maze", "grid": {"n": "thorn_rubbing",
			"c": "stitched_parchment", "w": "briar_knot", "e": "briar_knot"},
			"binding": "briar_knot", "base": 1, "max": 2},
		{"recipe_id": "sallow_mire", "grid": {"n": "mire_reed",
			"c": "waxed_vellum", "w": "sunk_knot", "e": "sunk_knot"},
			"binding": "sunk_knot", "base": 3, "max": 4},
	]
	var all_variants_exact := true
	var all_variant_materializations_frozen := true
	for entry_v in variant_cases:
		var entry: Dictionary = entry_v
		var preview := ChartsData.preview_table({"grid": entry.grid, "ink_rail": []},
			context)
		var depth: Dictionary = preview.get("depth_contract", {})
		var chart := ChartsData.materialize_chart(preview, 71300 + int(entry.max))
		all_variants_exact = all_variants_exact \
			and bool(preview.commit_ready) \
			and String(preview.recipe_id) == String(entry.recipe_id) \
			and String(depth.variant_id) == "%s_deepening" % String(entry.recipe_id) \
			and int(depth.base_max_layers) == int(entry.base) \
			and int(depth.max_layers) == int(entry.max) \
			and int(depth.added_layer) == int(entry.max) \
			and int(depth.hearth_layer) == int(entry.max) \
			and int(preview.output.max_layers) == int(entry.max) \
			and int(preview.component_cost.get(String(entry.binding), 0)) == 2
		all_variant_materializations_frozen = all_variant_materializations_frozen \
			and int(chart.max_layers) == int(entry.max) \
			and chart.depth_contract == depth \
			and not chart.has("encounter_contract")
	_check("only the four authored matching-Binding variants deepen their recipes",
		all_variants_exact)
	_check("variant materialization freezes the terminal Hearth depth contract",
		all_variant_materializations_frozen)
	var early_context := context.duplicate(true)
	early_context.level = 16
	var early := ChartsData.preview_table({"grid": variant_cases[0].grid, "ink_rail": []},
		early_context)
	_check("a doubled Binding below Wayfinding 17 is invalid and spends nothing",
		String(early.state) == "invalid" and not bool(early.commit_ready)
		and (early.costs as Dictionary).is_empty()
		and String(early.reason).contains("Wayfinding 17"))
	var summit_state := CampaignData.empty_state()
	for chapter_id in [CampaignData.FIRST_KNOT, CampaignData.GOLDEN_WALLOW,
			CampaignData.SEVENTH_ROAD]:
		var chapter: Dictionary = summit_state.chapters[chapter_id]
		chapter.cleared = true
		chapter.clue_count = int(CampaignData.CHAPTERS[chapter_id].clue_target)
	var queen_chapter: Dictionary = summit_state.chapters[CampaignData.QUEENS_SUMMIT]
	queen_chapter.clue_count = int(CampaignData.CHAPTERS[CampaignData.QUEENS_SUMMIT].clue_target)
	queen_chapter.banked_chart_ids = ["crown-a", "crown-b", "crown-c", "crown-d"]
	summit_state = CampaignData.normalize_campaign_state(summit_state)
	var summit := ChartsData.preview_table({"grid": {
		"nw": "cold_track", "n": "thorn_rubbing", "c": "atlas_folio",
		"w": "climbing_cord", "e": "climbing_cord", "s": "alpha_fang"},
		"ink_rail": ["refined_ink"]}, {
		"level": 17, "first_snug_returned": true,
		"known_recipe_ids": ["queens_summit_boss"],
		"campaign_state": summit_state,
	})
	_check("Queen's physical road uses its Thorn, Refined Ink, and forced authored contract",
		bool(summit.commit_ready) and String(summit.recipe_id) == "queens_summit_boss"
		and (summit.depth_contract as Dictionary).is_empty()
		and int(summit.output.max_layers) == 1
		and String((summit.campaign_contract as Dictionary).boss_kind)
			== "hedgemother_queen"
		and int((summit.returned_on_failure as Dictionary).get("alpha_fang", 0)) == 1
		and int((summit.costs as Dictionary).get("refined_ink", 0)) == 1)

	var cleared := CampaignData.empty_state()
	(cleared.chapters.first_knot as Dictionary)["cleared"] = true
	(cleared.chapters.first_knot as Dictionary)["clue_count"] = 3
	var reprise_grid := {"n": "hedge_sprig", "c": "field_parchment",
		"w": "loop_cord", "e": "loop_cord", "s": "thorn_essence"}
	var reprise_context := {
		"level": 21, "first_snug_returned": true,
		"known_recipe_ids": ["snug", "green_hollow", "first_knot_reprise"],
		"campaign_state": cleared,
	}
	var reprise_draft := {"grid": reprise_grid, "ink_rail": ["hedge_ink"]}
	var reprise := ChartsData.preview_table(reprise_draft, reprise_context)
	var reprise_again := ChartsData.preview_table(reprise_draft, reprise_context)
	var replay_chart := ChartsData.materialize_chart(reprise, 912345)
	var replay_again := ChartsData.materialize_chart(reprise, 912345)
	var replay_den_affix := (replay_chart.get("affixes", []) as Array).any(func(a):
		return String((a as Dictionary).get("id", "")) == "hedgemother_den")
	_check("WF21 clear unlocks a distinct known First Knot reprise with exact makings",
		bool(reprise.commit_ready) and String(reprise.state) == "known"
		and String(reprise.recipe_id) == "first_knot_reprise"
		and String(reprise.output.name) == "First Knot Reprise"
		and int(reprise.component_cost.loop_cord) == 2
		and int(reprise.costs.thorn_essence) == 1
		and int(reprise.ordinary_costs.thorn_essence) == 1
		and reprise.required_inks == ["hedge_ink"] and bool(reprise.requires_seal))
	_check("reprise has neither campaign contract nor escrow/refund semantics",
		(reprise.campaign_contract as Dictionary).is_empty()
		and (reprise.returned_on_failure as Dictionary).is_empty()
		and String(reprise.encounter_contract.reward_family_id) == "first_knot_heirlooms"
		and bool(reprise.encounter_contract.suppress_chain_trophy)
		and int(reprise.encounter_contract.boss_layer) == 2)
	_check("reprise materialization freezes two layers, terminal Hearth, boss, and reward seed",
		replay_chart == replay_again and int(replay_chart.max_layers) == 2
		and String(replay_chart.name) == "First Knot Reprise"
		and ChartsData.chart_label(replay_chart).begins_with("First Knot Reprise · Layer 1/2")
		and replay_chart.depth_contract == reprise.depth_contract
		and String(replay_chart.encounter_contract.boss_kind) == "hedgemother"
		and String(replay_chart.encounter_contract.reward_family_id) == "first_knot_heirlooms"
		and bool(replay_chart.encounter_contract.suppress_chain_trophy)
		and int(replay_chart.encounter_contract.reward_seed) > 0
		and not replay_chart.has("campaign_contract")
		and not replay_chart.has("returned_on_failure") and not replay_den_affix)
	_check("reprise preview is deterministic and fingerprint-safe",
		reprise == reprise_again and String(reprise.fingerprint) != ""
		and ChartsData.materialize_chart(early, 912345).is_empty())
	var uncleared_context := reprise_context.duplicate(true)
	uncleared_context.campaign_state = CampaignData.empty_state()
	var uncleared := ChartsData.preview_table(reprise_draft, uncleared_context)
	var underleveled_context := reprise_context.duplicate(true)
	underleveled_context.level = 20
	var underleveled := ChartsData.preview_table(reprise_draft, underleveled_context)
	_check("uncleared or underleveled reprise attempts spend nothing",
		not bool(uncleared.commit_ready) and (uncleared.costs as Dictionary).is_empty()
		and not bool(underleveled.commit_ready) and (underleveled.costs as Dictionary).is_empty()
		and String(uncleared.fingerprint) != String(reprise.fingerprint))

func _test_chart_sources_domain() -> void:
	print("[Chart Table Slice C2 sources]")
	var records_valid := true
	for source_id in ChartsData.CHART_SOURCE_ORDER:
		var source: Dictionary = ChartsData.CHART_SOURCES.get(source_id, {})
		records_valid = records_valid \
			and ChartsData.CHART_RUMOURS.has(String(source.get("rumour_id", ""))) \
			and ChartsData.CHART_RECIPES.has(String(source.get("recipe_id", ""))) \
			and int(source.get("min_wayfinding", 0)) > 0
		for component_id_v in source.get("lesson_components", {}):
			var component_id := String(component_id_v)
			records_valid = records_valid and ChartsData.COMPONENTS.has(component_id) \
				and not ChartsData.INKS.has(component_id) \
				and not ChartsData.TROPHY_TO_AFFIX.has(component_id)
		for ink_id_v in source.get("lesson_inks", {}):
			records_valid = records_valid and ChartsData.INKS.has(String(ink_id_v))
	_check("ten data-owned sources carry validated physical lesson records",
		ChartsData.CHART_SOURCES.size() == 10
		and ChartsData.CHART_SOURCE_ORDER.size() == 10 and records_valid)
	var source_toasts := "%s %s" % [
		String(ChartsData.CHART_SOURCES.atlas_deep_hollow.toast),
		String(ChartsData.CHART_SOURCES.mara_sallow_reed.toast)]
	_check("source toast never reveals either Rumoured recipe identity",
		not "Deep Hollow" in source_toasts and not "Sallow Mire" in source_toasts)
	_check("source unlock normalization is bounded, deduplicated, and authored-order",
		ChartsData.normalize_chart_source_unlocks(["mara_sallow_reed", "unknown",
			"atlas_deep_hollow", "mara_sallow_reed"])
			== ["atlas_deep_hollow", "mara_sallow_reed"])

	var game := _new_source_test_game(5)
	var untouched := game.materials.duplicate(true)
	var invalid: Dictionary = game.read_chart_source("not_a_source")
	_check("malformed source is an inert invalid result",
		not bool(invalid.ok) and String(invalid.state) == "invalid"
		and game.materials == untouched and game.save_calls == 0
		and game.notify_calls == 0)
	_check("Tier-1 completion unlocks Atlas once",
		game._unlock_chart_sources_for_completed_chart({"template_id": "tier_1"})
		and not game._unlock_chart_sources_for_completed_chart({"template_id": "tier_1"})
		and game.chart_source_unlocks == ["atlas_deep_hollow"])
	var premature: Dictionary = game.read_chart_source("atlas_deep_hollow")
	_check("unlocked Atlas below Wayfinding 6 is copy-only",
		bool(premature.ok) and not bool(premature.changed)
		and String(premature.state) == "locked" and game.materials == untouched
		and game.save_calls == 0 and game.notify_calls == 0)
	_set_trade_level(game, "wayfinding", 6)
	game.materials = {"hedge_sprig": 3, "stitched_parchment": 1}
	var signal_counts := {"knowledge": 0, "materials": 0}
	game.chart_knowledge_changed.connect(func(): signal_counts.knowledge += 1)
	game.materials_changed.connect(func(): signal_counts.materials += 1)
	var xp_before := int(game.trades.wayfinding.xp)
	var first: Dictionary = game.read_chart_source("atlas_deep_hollow")
	_check("eligible Atlas read atomically records rumour and missing-only kit",
		bool(first.ok) and bool(first.changed) and String(first.state) == "read"
		and first.granted == {"hollow_stitch": 1}
		and game.material_count("hedge_sprig") == 3
		and game.material_count("stitched_parchment") == 1
		and game.material_count("hollow_stitch") == 1
		and (game.chart_recipe_journal.rumours as Array).has("atlas_deep_hollow"))
	_check("successful source read signals/toasts/saves once and pays no XP",
		int(signal_counts.knowledge) == 1 and int(signal_counts.materials) == 1
		and game.notify_calls == 1 and game.save_calls == 1
		and int(game.trades.wayfinding.xp) == xp_before)
	var first_snapshot := game.materials.duplicate(true)
	var repeated: Dictionary = game.read_chart_source("atlas_deep_hollow")
	_check("repeat read is inert and cannot refill its kit",
		bool(repeated.ok) and not bool(repeated.changed) and String(repeated.state) == "read"
		and game.materials == first_snapshot and int(signal_counts.knowledge) == 1
		and int(signal_counts.materials) == 1
		and game.notify_calls == 1 and game.save_calls == 1)

	# The clue arrives at 6, but the authored full Hollow stays at 10. A failed
	# early attempt and an invalid arrangement both leave the lesson kit intact.
	var deep_draft := {"grid": {"n": "hedge_sprig", "c": "stitched_parchment",
		"w": "hollow_stitch"}, "ink_rail": []}
	_set_trade_level(game, "wayfinding", 9)
	var early_preview: Dictionary = ChartsData.preview_table(deep_draft,
		game.chart_table_context())
	var before_early := game.materials.duplicate(true)
	var early: Dictionary = game.try_inscribe_chart(deep_draft,
		String(early_preview.fingerprint), 6001)
	_check("Deep Hollow remains Wayfinding-10 and early commit loses nothing",
		not bool(early.ok) and "Wayfinding 10" in String(early.reason)
		and game.materials == before_early)
	var wrong_draft := {"grid": {"n": "hedge_sprig", "c": "stitched_parchment",
		"w": "loop_cord"}, "ink_rail": []}
	var wrong_preview: Dictionary = ChartsData.preview_table(wrong_draft,
		game.chart_table_context())
	var wrong: Dictionary = game.try_inscribe_chart(wrong_draft,
		String(wrong_preview.fingerprint), 6002)
	_check("invalid lesson-kit arrangement consumes nothing",
		not bool(wrong.ok) and game.materials == before_early)
	_set_trade_level(game, "wayfinding", 10)
	game.add_material("hedge_ink", 3)
	var deep_preview: Dictionary = ChartsData.preview_table(deep_draft,
		game.chart_table_context())
	var deep_result: Dictionary = game.try_inscribe_chart(deep_draft,
		String(deep_preview.fingerprint), 6003)
	var deep_supply: Array = ChartsData.component_supply_ids(game.chart_table_context())
	_check("discovering Deep makes its lesson components renewable",
		bool(deep_result.ok) and bool(deep_result.discovered)
		and deep_supply.has("hedge_sprig") and deep_supply.has("stitched_parchment")
		and deep_supply.has("hollow_stitch"))
	game.free()

	var mire := _new_source_test_game(11)
	mire.known_chart_recipes.append("deep_hollow")
	_check("abandoned Deep unlocks no note",
		not mire._unlock_chart_sources_for_completed_chart(
			{"template_id": "hollow"}, true) and mire.chart_source_unlocks.is_empty())
	_check("successful Deep completion unlocks the rain note",
		mire._unlock_chart_sources_for_completed_chart({"template_id": "hollow"})
		and mire.chart_source_unlocks == ["mara_sallow_reed"])
	var early_note: Dictionary = mire.read_chart_source("mara_sallow_reed")
	_check("rain note below Wayfinding 12 is inert",
		String(early_note.state) == "locked" and not bool(early_note.changed)
		and mire.save_calls == 0 and mire.notify_calls == 0)
	_set_trade_level(mire, "wayfinding", 12)
	mire.materials = {"waxed_vellum": 2, "sunk_knot": 1}
	var note: Dictionary = mire.read_chart_source("mara_sallow_reed")
	_check("eligible rain note tops only missing Sallow components",
		bool(note.changed) and note.granted == {"mire_reed": 1}
		and mire.material_count("waxed_vellum") == 2
		and mire.material_count("sunk_knot") == 1)
	var mire_draft := {"grid": {"n": "mire_reed", "c": "waxed_vellum",
		"w": "sunk_knot"}, "ink_rail": []}
	mire.add_material("hedge_ink", 3)
	var mire_preview: Dictionary = ChartsData.preview_table(mire_draft,
		mire.chart_table_context())
	var mire_result: Dictionary = mire.try_inscribe_chart(mire_draft,
		String(mire_preview.fingerprint), 6012)
	var mire_supply: Array = ChartsData.component_supply_ids(mire.chart_table_context())
	_check("discovering Sallow makes all three lesson components renewable",
		bool(mire_result.ok) and bool(mire_result.discovered)
		and mire_supply.has("waxed_vellum") and mire_supply.has("mire_reed")
		and mire_supply.has("sunk_knot"))
	mire.free()

	var resolved := _new_source_test_game(12)
	resolved.known_chart_recipes.append("deep_hollow")
	resolved._unlock_chart_source("atlas_deep_hollow")
	resolved.save_calls = 0
	resolved.notify_calls = 0
	var resolved_materials := resolved.materials.duplicate(true)
	var known_read: Dictionary = resolved.read_chart_source("atlas_deep_hollow")
	_check("already-known source resolves without rumour, kit, toast, or save",
		String(known_read.state) == "resolved" and not bool(known_read.changed)
		and resolved.materials == resolved_materials
		and not (resolved.chart_recipe_journal.rumours as Array).has("atlas_deep_hollow")
		and resolved.save_calls == 0 and resolved.notify_calls == 0)
	resolved.free()

func _test_chart_table_transaction() -> void:
	print("[Chart Table Slice B transaction]")
	var snug_draft := {"grid": {"n": "hedge_sprig", "c": "practice_leaf"},
		"ink_rail": ["hedge_ink"]}
	var game := _new_table_test_game()
	var starter: Dictionary = game.ensure_chart_starter_supplies()
	_check("starter recovery tops up one Practice Leaf and Hedge Sprig",
		starter == {"practice_leaf": 1, "hedge_sprig": 1}
		and game.material_count("practice_leaf") == 1
		and game.material_count("hedge_sprig") == 1)
	_check("starter recovery is idempotent while supplies remain",
		(game.ensure_chart_starter_supplies() as Dictionary).is_empty())
	game.add_material("hedge_ink", 1)
	var preview: Dictionary = ChartsData.preview_table(snug_draft,
		game.chart_table_context())
	var before_invalid: Dictionary = game.materials.duplicate(true)
	var missing_fingerprint: Dictionary = game.try_inscribe_chart(snug_draft, "", 10)
	_check("commit requires a non-empty live preview fingerprint",
		not bool(missing_fingerprint.ok)
		and "live Chart" in String(missing_fingerprint.reason)
		and game.materials == before_invalid and (game.charts as Array).is_empty())
	var incomplete_draft := {"grid": {"c": "practice_leaf"}, "ink_rail": []}
	var incomplete_preview: Dictionary = ChartsData.preview_table(incomplete_draft,
		game.chart_table_context())
	var invalid: Dictionary = game.try_inscribe_chart(incomplete_draft,
		String(incomplete_preview.fingerprint), 11)
	_check("incomplete commit mutates nothing",
		not bool(invalid.ok) and game.materials == before_invalid
		and (game.charts as Array).is_empty())
	var stale: Dictionary = game.try_inscribe_chart(snug_draft, "stale-fingerprint", 12)
	_check("stale preview mutates nothing",
		not bool(stale.ok) and game.materials == before_invalid
		and (game.charts as Array).is_empty())
	var bad_seed: Dictionary = game.try_inscribe_chart(snug_draft,
		String(preview.fingerprint), -1)
	_check("invalid materialization seed mutates nothing",
		not bool(bad_seed.ok) and game.materials == before_invalid
		and (game.charts as Array).is_empty())
	game._chart_inscription_active = true
	var reentrant: Dictionary = game.try_inscribe_chart(snug_draft,
		String(preview.fingerprint), 13)
	game._chart_inscription_active = false
	_check("re-entrant commit mutates nothing",
		not bool(reentrant.ok) and game.materials == before_invalid
		and (game.charts as Array).is_empty())
	game.materials.erase("hedge_ink")
	var poor_before: Dictionary = game.materials.duplicate(true)
	var poor: Dictionary = game.try_inscribe_chart(snug_draft,
		String(preview.fingerprint), 14)
	_check("unaffordable commit mutates nothing",
		not bool(poor.ok) and game.materials == poor_before
		and (game.charts as Array).is_empty())
	var return_grant: Dictionary = game.grant_first_return_chart_supplies()
	_check("first Snug return grants the Green Hollow lesson once and opens W",
		return_grant == {"field_parchment": 1, "loop_cord": 1, "hedge_sprig": 1}
		and bool(game.chart_table_context().first_snug_returned)
		and bool(ChartsData.table_unlocks(game.chart_table_context()).grid.w.unlocked)
		and (game.grant_first_return_chart_supplies() as Dictionary).is_empty())
	_check("first Snug return records Green Hollow's rumour in the same lesson",
		(game.chart_recipe_journal.rumours as Array) == ["mara_first_loop"]
		and (game.chart_recipe_journal.discoveries as Dictionary) == {
			"snug": "mara_lesson"})
	var stageable: Array = ChartsData.component_stageable_ids(game.chart_table_context())
	var renewable: Array = ChartsData.component_supply_ids(game.chart_table_context())
	_check("owned first-return lesson pieces are stageable but not renewable yet",
		stageable.has("field_parchment") and stageable.has("loop_cord")
		and not renewable.has("field_parchment") and not renewable.has("loop_cord"))
	game.add_material("thorn_essence", 1)
	game.add_material("alpha_fang", 1)
	var protected_before: Dictionary = game.materials.duplicate(true)
	var component_pot: Dictionary = game.try_pot_mix({"field_parchment": 1})
	var seal_pot: Dictionary = game.try_pot_mix({"thorn_essence": 1})
	var story_key_pot: Dictionary = game.try_pot_mix({"alpha_fang": 1})
	_check("protected Chart components, Seals, and story keys cannot enter the pot",
		component_pot.is_empty() and seal_pot.is_empty() and story_key_pot.is_empty()
		and game.materials == protected_before)
	game.free()

	var full_game := _new_table_test_game()
	full_game.ensure_chart_starter_supplies()
	full_game.add_material("hedge_ink", 1)
	for i in full_game.CHART_CASE_MAX:
		full_game.charts.append({"template_id": "snug", "seed": i + 1})
	var full_preview := ChartsData.preview_table(snug_draft,
		full_game.chart_table_context())
	var full_before: Dictionary = full_game.materials.duplicate(true)
	var full: Dictionary = full_game.try_inscribe_chart(snug_draft,
		String(full_preview.fingerprint), 15)
	_check("full chart case mutates nothing",
		not bool(full.ok) and full_game.materials == full_before
		and (full_game.charts as Array).size() == full_game.CHART_CASE_MAX)
	full_game.free()

	var double_game := _new_table_test_game()
	double_game.materials = {"practice_leaf": 2, "hedge_sprig": 2, "hedge_ink": 2}
	var double_preview := ChartsData.preview_table(snug_draft,
		double_game.chart_table_context())
	var first: Dictionary = double_game.try_inscribe_chart(snug_draft,
		String(double_preview.fingerprint), 101)
	var second: Dictionary = double_game.try_inscribe_chart(snug_draft,
		String(double_preview.fingerprint), 102)
	_check("successful commit deducts once and appends one deterministic Chart",
		bool(first.ok) and int(first.chart.seed) == 101
		and double_game.material_count("practice_leaf") == 1
		and double_game.material_count("hedge_sprig") == 1
		and double_game.material_count("hedge_ink") == 1
		and (double_game.charts as Array).size() == 1)
	_check("double-click fingerprint is rejected without a second mutation",
		not bool(second.ok) and (double_game.charts as Array).size() == 1)
	double_game.free()

	var discovery_game := _new_table_test_game()
	discovery_game.seen_hints["chart_table_snug_returned"] = true
	discovery_game.materials = {"field_parchment": 2, "hedge_sprig": 2,
		"loop_cord": 2, "hedge_ink": 4}
	var green_draft := {"grid": {"n": "hedge_sprig", "c": "field_parchment",
		"w": "loop_cord"}, "ink_rail": []}
	var xp_before := int(discovery_game.trades.wayfinding.xp)
	var discovery_preview: Dictionary = ChartsData.preview_table(green_draft,
		discovery_game.chart_table_context())
	var discovered: Dictionary = discovery_game.try_inscribe_chart(green_draft,
		String(discovery_preview.fingerprint), 201)
	var xp_after := int(discovery_game.trades.wayfinding.xp)
	var repeat_preview: Dictionary = ChartsData.preview_table(green_draft,
		discovery_game.chart_table_context())
	var repeated: Dictionary = discovery_game.try_inscribe_chart(green_draft,
		String(repeat_preview.fingerprint), 202)
	_check("first Green discovery pays its authored 93-XP chapter bridge once",
		bool(discovered.ok) and bool(discovered.discovered)
		and discovery_game.known_chart_recipes.has("green_hollow")
		and String(discovery_game.chart_recipe_journal.discoveries.get(
			"green_hollow", "")) == "table_experiment"
		and xp_after - xp_before == 93)
	_check("known repeat inscribes without repeat discovery XP",
		bool(repeated.ok) and not bool(repeated.discovered)
		and int(discovery_game.trades.wayfinding.xp) == xp_after)
	var grant: Dictionary = discovery_game.grant_first_return_chart_supplies()
	_check("already-recorded first return never grants twice", grant.is_empty())
	_check("hearing a rumour validates and records it once",
		not discovery_game.hear_chart_rumour("unknown")
		and discovery_game.hear_chart_rumour("mara_first_loop")
		and not discovery_game.hear_chart_rumour("mara_first_loop")
		and (discovery_game.chart_recipe_journal.rumours as Array) == [
			"mara_first_loop"]
		and String(discovery_game.chart_recipe_journal.discoveries.get(
			"green_hollow", "")) == "table_experiment")
	discovery_game.free()

	var supply_game := _new_table_test_game()
	supply_game.gold = 3
	var bought: bool = supply_game.buy_chart_component("practice_leaf", 1)
	var supply_before: Dictionary = supply_game.materials.duplicate(true)
	var unavailable: bool = supply_game.buy_chart_component("loop_cord", 1)
	_check("Mara supply purchase uses authored price and material stack",
		bought and supply_game.gold == 1
		and supply_game.material_count("practice_leaf") == 1)
	_check("unlearned supply cannot be bought and mutates nothing",
		not unavailable and supply_game.materials == supply_before
		and supply_game.gold == 1)
	supply_game.free()

# Wayfinding signature — the run_completed contract the town debrief subscribes
# to. (return_to_town's own emit isn't unit-tested here: it ends in a deferred
# get_tree().change_scene that's unsafe to fire mid-suite; the emit is one line,
# verified at the source + by the end-of-feature boot review.)
# D15 — quaffing a tonic sets the flag Quill reacts to.
func _test_d15_quaff_flag() -> void:
	print("[d15 quaff flag]")
	var game = load("res://scripts/game.gd").new()
	game._ready()
	game.add_material("quickroot_tonic", 1)
	var ok: bool = game.quaff_buff_draught()
	_check("D15 quaff a tonic → tonic_quaffed flag",
		ok and bool(game.seen_hints.get("tonic_quaffed", false)),
		"ok=%s flag=%s" % [str(ok), str(game.seen_hints.get("tonic_quaffed", false))])
	game.free()

# D14 — contextual first-contact hints (shrine / bleed / slow / affix).
func _test_d14_hints() -> void:
	print("[d14 hints]")
	var game = load("res://scripts/game.gd").new()
	game._ready()
	_check("D14 new hint keys exist",
		game.SKILL_HINTS.has("shrine") and game.SKILL_HINTS.has("status_bleed")
		and game.SKILL_HINTS.has("status_slow") and game.SKILL_HINTS.has("affix_reading"))
	game.first_time_hint("shrine")
	_check("D14 first_time_hint sets seen", bool(game.seen_hints.get("shrine", false)))
	# add_chart with affixes fires the affix-reading hint.
	game.add_chart({"template_id": "tier_1", "tier": 1, "scope": "hollow",
		"name": "T1", "seed": 3, "affixes": [{"id": "mineral_vein", "good": true}]})
	_check("D14 affix chart fires affix_reading hint",
		bool(game.seen_hints.get("affix_reading", false)))
	game.free()

func _test_run_completed_signal() -> void:
	print("[run_completed contract]")
	var game = load("res://scripts/game.gd").new()
	game._ready()
	_check("run_completed signal exists", game.has_signal("run_completed"))
	var got := {"hit": false, "xp": -1, "n_affixes": -1}
	game.run_completed.connect(func(chart: Dictionary, xp: int):
		got.hit = true
		got.xp = xp
		got.n_affixes = (chart.get("affixes", []) as Array).size())
	var chart := {"template_id": "tier_1", "tier": 1, "scope": "hollow",
		"name": "T1", "seed": 9,
		"affixes": [{"id": "mineral_vein", "good": true, "resolvedId": "mineral_vein"}]}
	var xp: int = ChartsData.completion_xp(chart)
	game.run_completed.emit(chart, xp)
	_check("run_completed delivers chart+xp to subscriber",
		got.hit and got.xp == xp and got.n_affixes == 1, str(got))
	game.free()

# Spec 55 — the Second Hand is observed through the Game seam: idempotent,
# queryable, and persisted with the rest of the first-chapter state.
func _test_second_hand_state() -> void:
	print("[second hand chapter state]")
	var game = load("res://scripts/game.gd").new()
	game._ready()
	_check("fresh chapter has no clues", game.second_hand_clue_count() == 0)
	_check("first clue records once", game.observe_second_hand("far_waystone")
		and game.has_second_hand_clue("far_waystone"))
	_check("observing the same clue is idempotent",
		not game.observe_second_hand("far_waystone")
		and game.second_hand_clue_count() == 1)
	_check("second presentation records separately",
		game.observe_second_hand("inked_scrap")
		and game.second_hand_clue_count() == 2)
	game.free()

# The generator is the public contract for guaranteed story placement. The
# first clue sits beside the far Waystone; the second uses a different
# presentation in a non-entry/non-boss room.
func _test_second_hand_layout() -> void:
	print("[second hand layout contract]")
	var snug: Dictionary = DungeonGenScript.generate(5501, {
		"scope": "snug", "template_id": "snug", "grid": 28,
		"room_min": 6, "room_max": 9})
	var snug_clues: Array = snug.get("story_clues", [])
	_check("Snug guarantees the far-Waystone clue", snug_clues.size() == 1
		and String(snug_clues[0].id) == "far_waystone")
	if not snug_clues.is_empty():
		var sc: Dictionary = snug_clues[0]
		var dx := absf(float(sc.x) - float(snug.exit.x))
		var dy := absf(float(sc.y) - float(snug.exit.y))
		_check("first clue is beside the far Waystone", dx + dy <= 3.0,
			"offset=(%.1f, %.1f)" % [dx, dy])
	var tier1: Dictionary = DungeonGenScript.generate(5502, {
		"scope": "hollow", "template_id": "tier_1", "grid": 36,
		"room_min": 7, "room_max": 11})
	var t_clues: Array = tier1.get("story_clues", [])
	_check("Tier 1 guarantees the inked-scrap clue", t_clues.size() == 1
		and String(t_clues[0].id) == "inked_scrap")
	if not t_clues.is_empty():
		var tc: Dictionary = t_clues[0]
		var room_id := int(tc.get("room_id", -1))
		var boss_id := int((tier1.bossRoom as Dictionary).get("id", -1))
		_check("second clue is a side discovery", room_id > 0
			and room_id != boss_id and String(tc.presentation) == "inked_scrap",
			str(tc))

# New Game — reset_to_defaults wipes progress to a fresh start. (Safe headless:
# WYRD_NO_SAVE → persistence_enabled false → SaveGame.clear() is skipped.)
func _test_new_game_reset() -> void:
	print("[new game reset]")
	var game = load("res://scripts/game.gd").new()
	game._ready()
	_set_trade_level(game, "wayfinding", 9)
	game.gold = 200
	game.add_material("wild_herb", 7)
	game.charts.append({"template_id": "tier_1", "tier": 1, "scope": "hollow",
		"name": "T1", "seed": 1, "affixes": []})
	game.summit_cleared = true
	game.tutorial_step = 7
	game.second_hand_clues = ["far_waystone", "inked_scrap"]
	game.chart_source_unlocks = ["atlas_deep_hollow", "mara_sallow_reed"]
	game.discovered_inks = ["hedge_ink", "ash_ink", "refined_ink"]
	var old_inv = game.inventory
	game.reset_to_defaults()
	_check("reset: trade back to lv1",
		game.trade_lv("wayfinding") == 1 and int(game.trades.wayfinding.xp) == 0)
	_check("reset: gold/charts/satchel cleared", int(game.gold) == 0
		and (game.charts as Array).is_empty()
		and game.material_count("wild_herb") == 0)
	_check("reset: flags cleared",
		not game.summit_cleared and int(game.tutorial_step) == 0
		and game.second_hand_clue_count() == 0)
	_check("reset: inks back to default", game.discovered_inks == ["hedge_ink"])
	_check("reset: starting Chart Recipes restored",
		game.known_chart_recipes == ChartsData.starting_recipe_ids()
		and game.chart_recipe_journal == ChartsData.fresh_recipe_journal()
		and game.chart_source_unlocks.is_empty())
	_check("reset: fresh inventory instance",
		game.inventory != null and game.inventory != old_inv)
	_check("reset: Basic Shot only",
		game.owned_skills.is_empty() and game.loadout.is_empty()
			and game.skill_unlocked("BasicShot"))
	game.free()

func _test_game_flow() -> void:
	print("[game autoload logic]")
	var game = load("res://scripts/game.gd").new()
	game._ready()   # builds inventory/equipment without entering the tree
	_check("xp curve lv2 = 40", game.xp_for_level(2) == 40)
	_check("xp curve lv10 = 936", game.xp_for_level(10) == 936,
		str(game.xp_for_level(10)))
	game.add_material("wild_herb", 3)
	_check("satchel add", game.material_count("wild_herb") == 3)
	_check("tutorial advanced by 3 herbs (1→2 path: starts 0, no talk yet)",
		game.tutorial_step == 0)   # step gate: only advances FROM step 1
	game.tutorial_step = 1
	game.add_material("wild_herb", 0)
	game._tutorial_check_materials()
	_check("tutorial 1→2 once herbs ≥3", game.tutorial_step == 2)
	_check("mix hedge ink", game.mix_ink("hedge_ink"))
	_check("herbs spent", game.material_count("wild_herb") == 0)
	_check("ink gained", game.material_count("hedge_ink") == 1)
	_check("tutorial 2→3 on mix", game.tutorial_step == 3)
	var chart := ChartsData.inscribe("snug", [], 1)
	game.add_chart(chart)
	_check("tutorial 3→4 on snug inscribe", game.tutorial_step == 4)
	_check("chart in case", (game.charts as Array).size() == 1)
	# run_cfg for the snug chart.
	game.active_chart = chart
	var cfg: Dictionary = game.run_cfg()
	_check("snug cfg grid 28", int(cfg.get("grid", 0)) == 28, str(cfg))
	_check("snug cfg no boss", String(cfg.get("boss_kind", "x")) == "")
	# D13 — the sub-objective names the chart while delving, empty in town.
	game.in_dungeon = true
	_check("D13 sub-objective names the chart",
		game.objective_sub() == ChartsData.chart_label(chart), game.objective_sub())
	game.in_dungeon = false
	_check("D13 no sub-objective in town", game.objective_sub() == "")
	game.free()

# B3 — per-kind enemy stats: every kind has damage+speed, and the two
# poles (rat, skeleton) differ on both axes.
func _test_enemy_kinds() -> void:
	print("[per-kind enemy stats]")
	var LL = load("res://scripts/layout_loader.gd")
	var kinds: Dictionary = LL.ENEMY_KINDS
	var all_have := true
	for k in kinds:
		if not (kinds[k].has("damage") and kinds[k].has("speed")
				and kinds[k].has("atk_cd")):
			all_have = false
	_check("every kind has damage/speed/atk_cd", all_have)
	var rat: Dictionary = kinds["rat"]
	var skel: Dictionary = kinds["skeleton"]
	_check("rat nips, skeleton slams (damage)",
		int(rat.damage) < int(skel.damage),
		"%d vs %d" % [int(rat.damage), int(skel.damage)])
	_check("rat darts, skeleton lumbers (speed)",
		float(rat.speed) > float(skel.speed),
		"%.2f vs %.2f" % [float(rat.speed), float(skel.speed)])

# A7/A8-lite stations + A9 perks + the Q-quaff sustain verb.
func _test_crafting_perks() -> void:
	print("[crafting + perks]")
	var game = load("res://scripts/game.gd").new()
	game._ready()
	# Cooking: 2 herbs + 1 log -> draught + 15 wilds xp.
	game.add_material("wild_herb", 2)
	game.add_material("logs", 1)
	var crafted_sid := {"v": ""}   # dict capture — a lambda's captured String won't escape
	game.crafted.connect(func(sid): crafted_sid.v = sid, CONNECT_ONE_SHOT)
	_check("cook hearth draught", game.craft("cookfire", "hearth_draught"))
	_check("craft emits crafted(cookfire)", String(crafted_sid.v) == "cookfire",
		String(crafted_sid.v))
	_check("draught in satchel", game.material_count("hearth_draught") == 1)
	_check("inputs spent", game.material_count("wild_herb") == 0
		and game.material_count("logs") == 0)
	_check("cook pays Wildcraft XP", int(game.trades.wildcraft.xp) == 15,
		str(game.trades.wildcraft.xp))
	# Quaffing: smallest bottle first, consumed, heal amount returned.
	game.add_material("deep_draught", 1)
	_check("quaff drinks the hearth bottle first", game.quaff_draught() == 35)
	_check("hearth bottle spent", game.material_count("hearth_draught") == 0)
	_check("second quaff drinks the deep", game.quaff_draught() == 80)
	_check("empty quaff returns 0", game.quaff_draught() == 0)
	# Smithing chain: ore -> bar -> gear item in the pack.
	game.add_material("bogiron_ore", 2)
	_check("smelt bogiron bar", game.craft("forge", "bogiron_bar"))
	_check("bar in satchel", game.material_count("bogiron_bar") == 1)
	game.add_material("logs", 2)
	_check("longbow gated at earth 1", not game.craft("forge", "longbow_smith"))
	_check("gate spends nothing", game.material_count("bogiron_bar") == 1)
	_set_trade_level(game, "earthcraft", 4)
	_check("longbow smiths at earth 4", game.craft("forge", "longbow_smith"))
	var found := false
	for it in game.inventory.items:
		if String(it.get("kind_id", "")) == "longbow":
			found = true
	_check("longbow landed in the pack", found)
	_check("bar consumed", game.material_count("bogiron_bar") == 0)
	_check("can't cook at the anvil", not game.craft("forge", "hearth_draught"))
	# Perks (A9).
	_check("keen_eye off at Wildcraft 1", game.gather_bonus("forage_node") == 0)
	_set_trade_level(game, "wildcraft", 5)
	_check("keen_eye on at wilds 5", game.gather_bonus("forage_node") == 1)
	_check("clean_splits still off", game.gather_bonus("log_pile") == 0)
	_set_trade_level(game, "wildcraft", 10)
	_check("clean_splits on at wilds 10", game.gather_bonus("log_pile") == 1)
	_set_trade_level(game, "earthcraft", 5)
	var doubles := 0
	for _i in 200:
		doubles += game.gather_bonus("ore_rock")
	_check("double_ore rolls near 25%", doubles > 20 and doubles < 90,
		str(doubles))
	game.free()

func _test_dungeon_cfg() -> void:
	print("[dungeon gen cfg]")
	# Default (dev) path keeps the old contract.
	var legacy := DungeonGenScript.generate(12345)
	_check("legacy grid 48", (legacy.grid as Array).size() == 48)
	_check("legacy boss", String(legacy.bossKind) == "hedgemother")
	_check("legacy connected", float(legacy.score.connectivity) >= 0.999)
	# Snug-sized cfg.
	var cfg := {"grid": 28, "room_min": 6, "room_max": 9,
		"room_count_min": 3, "room_count_max": 7, "boss_kind": "",
		"scope": "snug", "tier": 1}
	var snug := DungeonGenScript.generate(777, cfg)
	_check("snug grid 28", (snug.grid as Array).size() == 28)
	_check("snug no boss", String(snug.bossKind) == "")
	_check("snug scope tag", String(snug.scope) == "snug")
	_check("snug connected", float(snug.score.connectivity) >= 0.999,
		str(snug.score))
	_check("snug scored ≥ 0.5", float(snug.score.total) >= 0.5,
		str(snug.score.total))

func _test_gather_decor() -> void:
	print("[gather decor]")
	var cfg := {"boss_kind": "", "affixes": [
		{"id": "mineral_vein", "good": true, "resolvedId": "mineral_vein"},
		{"id": "bramble_bloom", "good": false, "resolvedId": "bramble_bloom__bad"},
		{"id": "wood_grove", "good": true, "resolvedId": "wood_grove"},
	]}
	var layout := DungeonGenScript.generate(4242, cfg)
	var ore := 0
	var forage := 0
	var piles := 0
	for d in layout.decor:
		if not bool(d.get("gather", false)):
			continue
		match String(d.kind):
			"ore_rock": ore += 1
			"forage_node": forage += 1
			"log_pile": piles += 1
	_check("mineral_vein good → 3-5 ore rocks", ore >= 3 and ore <= 5, str(ore))
	_check("bramble_bloom bad → 0 forage", forage == 0, str(forage))
	_check("wood_grove good → 3-5 log piles", piles >= 3 and piles <= 5, str(piles))
	# Gather decor carries the item id for the satchel.
	for d in layout.decor:
		if bool(d.get("gather", false)) and String(d.kind) == "ore_rock":
			_check("ore node item carried", String(d.get("item", "")) != "")
			break

func _test_determinism() -> void:
	print("[determinism]")
	var cfg := {"grid": 36, "room_min": 7, "room_max": 11, "boss_kind": ""}
	var a := DungeonGenScript.generate(999, cfg)
	var b := DungeonGenScript.generate(999, cfg)
	_check("same seed+cfg → same room count",
		(a.rooms as Array).size() == (b.rooms as Array).size())
	_check("same seed+cfg → same entry",
		int(a.entry.x) == int(b.entry.x) and int(a.entry.y) == int(b.entry.y))
	_check("same seed+cfg → same decor count",
		(a.decor as Array).size() == (b.decor as Array).size())
