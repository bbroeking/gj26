extends SceneTree

# Wyrd slice — headless end-to-end logic check.
# Run: godot --headless --path wyrd --script res://test_wyrd_loop.gd
#
# Covers the chart loop with no UI: materials → mix ink → inscribe →
# run cfg → parameterized dungeon gen (grid size, boss-as-affix, gather
# decor, determinism) → completion XP → tutorial step advancement.

const ChartsData = preload("res://data/charts.gd")
const GatherDefs = preload("res://data/gather.gd")
const DungeonGenScript = preload("res://scripts/dungeon_gen.gd")

var _pass := 0
var _fail := 0

func _check(name: String, ok: bool, detail: String = "") -> void:
	if ok:
		_pass += 1
		print("  ✓ %s" % name)
	else:
		_fail += 1
		print("  ✗ %s %s" % [name, detail])

func _init() -> void:
	print("--- wyrd loop check ---")
	_test_charts_data()
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
	_test_save_roundtrip()
	print("--- %d passed, %d failed ---" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)

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
	_check("summit costs the fang", int(ChartsData.craft_cost("summit", [])
		.get("alpha_fang", 0)) == 1)
	# Gold: sell a gear item, buy a ware.
	game.active_chart = {}
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
	game.trades.earth.lv = 2
	_check("pickaxe smiths at earth 2", game.craft("forge", "pickaxe_smith"))
	var pick = null
	for it in game.inventory.items:
		if String(it.get("kind_id", "")) == "bogiron_pickaxe":
			pick = it
	_check("pickaxe landed in the pack", pick != null)
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

# B5 — loadout: pool validation + persistence + skill instantiation.
func _test_loadout() -> void:
	print("[loadout]")
	var game = load("res://scripts/game.gd").new()
	game._ready()
	_check("default loadout is the classic trio",
		game.loadout == ["PowerShot", "MultiShot", "BrambleSnare"])
	_check("rejects wrong count", not game.set_loadout(["PowerShot"]))
	_check("rejects unknown skill",
		not game.set_loadout(["PowerShot", "MultiShot", "FrostNova"]))
	_check("rejects duplicates",
		not game.set_loadout(["PowerShot", "PowerShot", "MultiShot"]))
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
	game.trades.earth.lv = 7
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
	game.trades.earth.lv = 8
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
			if not ot in ["bogiron", "palechalk"]:
				ok2 = false
			if ot == "palechalk":
				saw_deep = true
	_check("tier-2 charts: bogiron/palechalk only", ok2)
	_check("tier-2 carries palechalk (seed 4242)", saw_deep)
	game.free()

# B6 — sprinter / gilded / bursting.
func _test_b6_affixes() -> void:
	print("[b6 affixes]")
	for aid in ["sprinter", "gilded", "bursting"]:
		_check("%s defined + weighted" % aid,
			ChartsData.AFFIXES.has(aid) and ChartsData.BASE_WEIGHTS.has(aid))
	# High-carto weights now include the new three.
	var w := ChartsData.compute_weights(2, [], 20)
	_check("new affixes roll at high carto", w.has("sprinter")
		and w.has("gilded") and w.has("bursting"), str(w.keys()))
	# Gilded scatters exactly two extra chests (not gather nodes).
	var lay := DungeonGenScript.generate(909, {"grid": 36, "room_min": 7,
		"room_max": 11, "boss_kind": "", "tier": 2,
		"affixes": [{"id": "gilded", "good": true}]})
	var chests := 0
	for d in lay.decor:
		if String(d.get("kind", "")) == "chest" and not bool(d.get("gather", true)):
			chests += 1
	_check("gilded adds 2 chests", chests >= 2, str(chests))

func _test_save_roundtrip() -> void:
	print("[save/load]")
	var game = load("res://scripts/game.gd").new()
	game._ready()
	game.trades.carto = {"lv": 3, "xp": 250}
	game.add_material("wild_herb", 5)
	game.charts.append({"template_id": "tier_1", "tier": 1, "scope": "hollow",
		"name": "Tier 1 Hollow", "seed": 42, "affixes": [
			{"id": "mineral_vein", "good": true, "resolvedId": "mineral_vein"}]})
	game.tutorial_step = 6
	game.player_hp = 17
	game.gold = 57
	game.summit_cleared = true
	game.muted = true   # spec 38 — the mute preference rides the save
	game.loadout = ["PiercingBolt", "MultiShot", "RainOfThorns"]
	var ItemsData = load("res://data/items.gd")
	var item: Dictionary = ItemsData.make_item("shortbow", "magic")
	var fit: Dictionary = game.inventory.find_first_fit(item)
	game.inventory.try_place(item, fit.pos, fit.rotated)
	game.equipment.slots["helmet"] = ItemsData.make_item("leather_helm", "rare")
	_check("save written", SaveGame.save(game))
	var game2 = load("res://scripts/game.gd").new()
	game2._ready()
	_check("load ok", SaveGame.load_into(game2))
	_check("trade restored", game2.trade_lv("carto") == 3)
	_check("satchel restored", game2.material_count("wild_herb") == 5)
	_check("chart restored", (game2.charts as Array).size() == 1
		and String(game2.charts[0].template_id) == "tier_1")
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
	_check("loadout restored", game2.loadout ==
		["PiercingBolt", "MultiShot", "RainOfThorns"])
	SaveGame.clear()
	_check("save file cleaned up", not SaveGame.has_save())
	game.free()
	game2.free()

func _test_charts_data() -> void:
	print("[charts data]")
	# Weight gating: carto 1 only sees mineral_vein (req 1).
	var w1 := ChartsData.compute_weights(1, [], 1)
	_check("carto-1 weights = mineral_vein only",
		w1.size() == 1 and w1.has("mineral_vein"), str(w1.keys()))
	var w9 := ChartsData.compute_weights(1, [], 9)
	# req ≤ 9: mineral_vein 1, bramble_bloom 4, tyrannical 5, wood_grove 7,
	# festival_pace 7. Boss dens never roll at random (trophy slot only).
	_check("carto-9 unlocks 7 random affixes", w9.size() == 7, str(w9.keys()))
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
	# Costs: base + slotted inks.
	var cost := ChartsData.craft_cost("tier_1", ["hedge_ink", "refined_ink"])
	_check("tier_1 + 2 inks cost", int(cost.get("hedge_ink", 0)) == 3
		and int(cost.get("refined_ink", 0)) == 1, str(cost))

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
	_check("cook hearth draught", game.craft("cookfire", "hearth_draught"))
	_check("draught in satchel", game.material_count("hearth_draught") == 1)
	_check("inputs spent", game.material_count("wild_herb") == 0
		and game.material_count("logs") == 0)
	_check("cook pays wilds xp", int(game.trades.wilds.xp) == 15,
		str(game.trades.wilds.xp))
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
	game.trades.earth.lv = 4
	_check("longbow smiths at earth 4", game.craft("forge", "longbow_smith"))
	var found := false
	for it in game.inventory.items:
		if String(it.get("kind_id", "")) == "longbow":
			found = true
	_check("longbow landed in the pack", found)
	_check("bar consumed", game.material_count("bogiron_bar") == 0)
	_check("can't cook at the anvil", not game.craft("forge", "hearth_draught"))
	# Perks (A9).
	_check("keen_eye off at wilds 1", game.gather_bonus("forage_node") == 0)
	game.trades.wilds.lv = 5
	_check("keen_eye on at wilds 5", game.gather_bonus("forage_node") == 1)
	_check("clean_splits still off", game.gather_bonus("log_pile") == 0)
	game.trades.wilds.lv = 10
	_check("clean_splits on at wilds 10", game.gather_bonus("log_pile") == 1)
	game.trades.earth.lv = 5
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
