extends SceneTree

const Progression = preload("res://data/progression.gd")
const ChartsData = preload("res://data/charts.gd")
const CampaignData = preload("res://data/campaign.gd")

# Wyrd — save / load round-trip test (SAFE — never touches the real save).
#
# Run:
#   WYRD_NO_SAVE=1 godot --headless --path wyrd --script res://test_save_roundtrip.gd
#
# All reads and writes go to a throwaway path in user://.
# The real save (user://wayfinder_save.json) is never created, read, or
# deleted by this suite.
#
# Covers:
#   1. Full round-trip — every persisted field survives save_to / load_from.
#   2. Atomic write — tmp file is cleaned up; real path is present after save.
#   3. .bak fallback — corrupt primary falls back to .bak cleanly.
#   4. NOT_FOUND result when the path does not exist.
#   5. CORRUPT result when the primary is broken and no .bak exists.
#   6. VERSION_MISMATCH result when the version field is wrong.
#   7. _migrate chain — legacy four-trade XP collapses into wayfinding.
#   8. _migrate chain — pre-spec-43 saves missing discovered_inks get backfill.
#   9. Cleanup — temp files are removed; real save path is provably untouched.


# Temp paths — isolated from the real save.
const TEST_PATH := "user://wyrd_test_roundtrip.json"
const TEST_BAK  := "user://wyrd_test_roundtrip.json.bak"
const TEST_TMP  := "user://wyrd_test_roundtrip.json.tmp"

var _pass := 0
var _fail := 0
var _real_save_existed := false
var _real_save_contents := ""

func _check(name: String, ok: bool, detail: String = "") -> void:
	if ok:
		_pass += 1
		print("  ✓ %s" % name)
	else:
		_fail += 1
		print("  ✗ %s %s" % [name, detail])

func _init() -> void:
	if OS.get_environment("WYRD_NO_SAVE") == "":
		push_error("test_save_roundtrip.gd requires WYRD_NO_SAVE=1; refusing to touch the live profile")
		quit(2)
		return
	print("--- save roundtrip check ---")
	_real_save_existed = FileAccess.file_exists(SaveGame.SAVE_PATH)
	if _real_save_existed:
		var preserved := FileAccess.open(SaveGame.SAVE_PATH, FileAccess.READ)
		_real_save_contents = preserved.get_as_text() if preserved != null else ""
	_test_roundtrip()
	_test_atomic_write()
	_test_bak_fallback()
	_test_not_found()
	_test_corrupt_no_bak()
	_test_version_mismatch()
	_test_future_primary_never_falls_back()
	_test_migrate_legacy_trades()
	_test_migrate_pre43_inks()
	_test_chart_table_component_migration()
	_test_chart_recipe_journal_migration()
	_test_chart_source_migration()
	_test_campaign_roundtrip_and_legacy_inference()
	_test_campaign_escrow_recovery()
	_test_seventh_road_and_handoff_roundtrip()
	_test_legacy_summit_fang_credit_recovery()
	_test_pale_oath_escrow_recovery_primary_backup()
	_test_campaign_runtime_settlement()
	_test_real_save_untouched()
	_cleanup_all()
	print("--- %d passed, %d failed ---" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)

# ---- helpers ----

func _new_game() -> Node:
	var g = load("res://scripts/game.gd").new()
	g._ready()   # WYRD_NO_SAVE=1 → persistence_enabled = false; no real load
	return g

func _cleanup_temp() -> void:
	for p: String in [TEST_PATH, TEST_BAK, TEST_TMP]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))

func _legacy_chart_matches(actual: Dictionary, expected: Dictionary) -> bool:
	# JSON restores whole numbers as floats. The live runtime contract casts the
	# numeric Chart fields, so preserve the legacy chart schema and semantics
	# instead of relying on raw Dictionary equality.
	return actual.size() == expected.size() \
		and String(actual.get("template_id", "")) == String(expected.get("template_id", "")) \
		and int(actual.get("tier", 0)) == int(expected.get("tier", 0)) \
		and String(actual.get("scope", "")) == String(expected.get("scope", "")) \
		and String(actual.get("name", "")) == String(expected.get("name", "")) \
		and int(actual.get("seed", 0)) == int(expected.get("seed", 0)) \
		and actual.get("affixes", []) == expected.get("affixes", [])

# ---- test cases ----

func _test_roundtrip() -> void:
	print("[roundtrip — all fields]")
	_cleanup_temp()
	var ItemsData = load("res://data/items.gd")

	var g1: Node = _new_game()
	# _ready() seeds the recoverable first-road components for a live fresh game.
	# This fixture authors an exact satchel snapshot, so remove that boot-time
	# grant before adding the quantities whose round-trip is under test.
	g1.materials = {}
	g1.trades.wayfinding = {"lv": 4, "xp": 250}
	g1.trades.earthcraft = {"lv": 3, "xp": 96}
	g1.trades.wildcraft = {"lv": 4, "xp": 168}
	g1.trades.huntcraft = {"lv": 23, "xp": Progression.max_xp()}
	g1.add_material("wild_herb", 5)
	g1.charts.append({"template_id": "tier_1", "tier": 1, "scope": "hollow",
		"name": "Tier 1 Hollow", "seed": 42, "affixes": [
			{"id": "mineral_vein", "good": true, "resolvedId": "mineral_vein"}]})
	g1.tutorial_step = 6
	g1.player_hp = 17
	g1.gold = 57
	g1.summit_cleared = true
	g1.muted = true
	g1.owned_skills = ["PiercingBolt", "MultiShot", "RainOfThorns"]
	g1.loadout = ["PiercingBolt", "MultiShot", "RainOfThorns"]
	g1.discovered_inks = ["hedge_ink", "ash_ink"]
	g1.chart_recipe_journal = {"rumours": ["mara_first_loop"],
		"discoveries": {"snug": "mara_lesson"}}
	g1.chart_source_unlocks = ["atlas_deep_hollow"]
	g1.campaign_state = CampaignData.empty_state()
	(g1.campaign_state.chapters.first_knot as Dictionary).clue_count = 2
	g1.chart_table_version = SaveGame.CHART_TABLE_VERSION
	g1.seen_hints = {"chart_table_snug_returned": true}
	g1.add_material("practice_leaf", 2)
	g1.add_material("hedge_sprig", 3)
	g1.add_material("loop_cord", 1)
	# Item with Vector2i/Color fields.
	var item: Dictionary = ItemsData.make_item("shortbow", "magic")
	var fit: Dictionary = g1.inventory.find_first_fit(item)
	g1.inventory.try_place(item, fit.pos, fit.rotated)
	# Equipment with Color.
	g1.equipment.slots["helmet"] = ItemsData.make_item("leather_helm", "rare")
	# D8 — the legendary is an ordinary persisted gear instance. Its per-room
	# thread is deliberately Player runtime state and must never enter the save.
	g1.equipment.slots["weapon"] = ItemsData.make_item("wayweaver", "legendary")
	(g1.equipment.slots["weapon"] as Dictionary)["cosmetic_rune_id"] = "mist_root_rune"

	_check("save_to written", SaveGame.save_to(TEST_PATH, g1))
	_check("primary file exists", FileAccess.file_exists(TEST_PATH))
	var saved_file := FileAccess.open(TEST_PATH, FileAccess.READ)
	var saved_text := saved_file.get_as_text() if saved_file != null else ""
	if saved_file != null:
		saved_file.close()
	_check("Wayweaver room thread is absent from durable save state",
		not saved_text.contains("wayweaver_thread")
			and not saved_text.contains("armed_identity")
			and not saved_text.contains("room_presence"))

	var g2: Node = _new_game()
	var result: SaveGame.LOAD_RESULT = SaveGame.load_from(TEST_PATH, g2)
	_check("load_from OK", result == SaveGame.LOAD_RESULT.OK)
	_check("wayfinding level derived from XP", int(g2.trades.wayfinding.lv) == 4)
	_check("four Trade pools round-trip independently",
		int(g2.trades.wayfinding.xp) == 250 and int(g2.trades.earthcraft.xp) == 96
			and int(g2.trades.wildcraft.xp) == 168
			and int(g2.trades.huntcraft.xp) == Progression.max_xp(), str(g2.trades))
	_check("Huntcraft 23 does not grow the restored pack", g2.inventory.rows == 6,
		str(g2.inventory.rows))
	_check("satchel restored", g2.material_count("wild_herb") == 5)
	_check("chart restored", (g2.charts as Array).size() == 1
		and String(g2.charts[0].template_id) == "tier_1")
	_check("tutorial step", int(g2.tutorial_step) == 6)
	_check("player_hp", int(g2.player_hp) == 17)
	_check("gold", int(g2.gold) == 57)
	_check("summit_cleared", bool(g2.summit_cleared))
	_check("muted", bool(g2.muted))
	_check("owned loadout", g2.owned_skills == ["PiercingBolt", "MultiShot", "RainOfThorns", "PowerShot"]
		and g2.loadout == ["PiercingBolt", "MultiShot", "PowerShot"])
	_check("discovered_inks", g2.discovered_inks == ["hedge_ink", "ash_ink"])
	_check("Chart Recipe journal round-trips with provenance",
		g2.chart_recipe_journal == {"rumours": ["mara_first_loop"],
			"discoveries": {"snug": "mara_lesson"}})
	_check("Chart source unlocks round-trip",
		g2.chart_source_unlocks == ["atlas_deep_hollow"])
	_check("campaign state round-trips independently",
		CampaignData.chapter_clue_count(g2.campaign_state) == 2
		and int(g2.campaign_state.next_attempt_id) == 1
		and (g2.campaign_state.escrows as Dictionary).is_empty())
	_check("Chart Table components round-trip",
		g2.material_count("practice_leaf") == 2
		and g2.material_count("hedge_sprig") == 3
		and g2.material_count("loop_cord") == 1)
	_check("Chart Table version + first-return milestone round-trip",
		int(g2.chart_table_version) == SaveGame.CHART_TABLE_VERSION
		and bool(g2.seen_hints.get("chart_table_snug_returned", false)))
	_check("gear item with Vector2i", g2.inventory.items.size() == 1
		and g2.inventory.items[0].size is Vector2i
		and String(g2.inventory.items[0].kind_id) == "shortbow")
	var helm = g2.equipment.get_slot("helmet")
	_check("equipment with Color", helm != null and helm.icon_color is Color)
	var wayweaver = g2.equipment.get_slot("weapon")
	_check("Wayweaver legendary gear round-trips in the weapon slot",
		wayweaver != null and String(wayweaver.get("kind_id", "")) == "wayweaver"
			and String(wayweaver.get("rarity", "")) == "legendary"
			and not bool(wayweaver.get("sellable", true))
			and String(wayweaver.get("cosmetic_rune_id", "")) == "mist_root_rune")

	g1.free()
	g2.free()
	_cleanup_temp()

func _test_atomic_write() -> void:
	print("[atomic write]")
	_cleanup_temp()

	var g: Node = _new_game()
	# First save — no pre-existing file; tmp must be gone after save.
	_check("first save ok", SaveGame.save_to(TEST_PATH, g))
	_check("tmp cleaned up", not FileAccess.file_exists(TEST_TMP))
	_check("primary present", FileAccess.file_exists(TEST_PATH))
	# No .bak yet (first write, nothing to back up).
	# Actually: .bak is created only when an existing primary is overwritten.
	# Second save — primary exists now → .bak should be created.
	_check("second save ok", SaveGame.save_to(TEST_PATH, g))
	_check("bak created after second save", FileAccess.file_exists(TEST_BAK))
	_check("tmp still cleaned up", not FileAccess.file_exists(TEST_TMP))

	g.free()
	_cleanup_temp()

func _test_bak_fallback() -> void:
	print("[bak fallback]")
	_cleanup_temp()

	var g1: Node = _new_game()
	g1.gold = 99
	# Write once → primary; write again → bak contains the first good save.
	_check("first save", SaveGame.save_to(TEST_PATH, g1))
	_check("second save (creates .bak)", SaveGame.save_to(TEST_PATH, g1))
	# Now corrupt the primary.
	var fw := FileAccess.open(TEST_PATH, FileAccess.WRITE)
	fw.store_string("{bad json{{{{")
	fw.close()

	var g2: Node = _new_game()
	var r: SaveGame.LOAD_RESULT = SaveGame.load_from(TEST_PATH, g2)
	_check("load falls back to bak (returns OK)", r == SaveGame.LOAD_RESULT.OK)
	_check("gold restored from bak", int(g2.gold) == 99)

	g1.free()
	g2.free()
	_cleanup_temp()

func _test_not_found() -> void:
	print("[not found]")
	_cleanup_temp()

	var g: Node = _new_game()
	var r: SaveGame.LOAD_RESULT = SaveGame.load_from(TEST_PATH, g)
	_check("NOT_FOUND when file absent", r == SaveGame.LOAD_RESULT.NOT_FOUND)

	g.free()

func _test_corrupt_no_bak() -> void:
	print("[corrupt, no bak]")
	_cleanup_temp()

	# Write a corrupt primary with no .bak.
	var fw := FileAccess.open(TEST_PATH, FileAccess.WRITE)
	fw.store_string("{not valid json at all")
	fw.close()

	var g: Node = _new_game()
	var r: SaveGame.LOAD_RESULT = SaveGame.load_from(TEST_PATH, g)
	_check("CORRUPT when no bak available", r == SaveGame.LOAD_RESULT.CORRUPT)

	g.free()
	_cleanup_temp()

func _test_version_mismatch() -> void:
	print("[version mismatch]")
	_cleanup_temp()

	# Write a valid JSON but wrong version, no .bak.
	var bad := {"version": 9999, "trades": {}, "materials": {}, "charts": [],
		"gold": 0, "summit_cleared": false, "muted": false, "loadout": [],
		"chosen_perks": {}, "ledger": {}, "discovered_inks": [],
		"seen_hints": {}, "tutorial_step": 0, "player_hp": -1,
		"inventory": [], "equipment": {}}
	var fw := FileAccess.open(TEST_PATH, FileAccess.WRITE)
	fw.store_string(JSON.stringify(bad))
	fw.close()

	var g: Node = _new_game()
	var r: SaveGame.LOAD_RESULT = SaveGame.load_from(TEST_PATH, g)
	_check("VERSION_MISMATCH returned", r == SaveGame.LOAD_RESULT.VERSION_MISMATCH)

	g.free()
	_cleanup_temp()

func _test_future_primary_never_falls_back() -> void:
	print("[future primary blocks stale backup]")
	_cleanup_temp()
	var backup_game: Node = _new_game()
	backup_game.gold = 7
	_check("valid v2 backup fixture written", SaveGame.save_to(TEST_BAK, backup_game))
	var future := {"version": 3, "gold": 999, "trades": {}}
	var fw := FileAccess.open(TEST_PATH, FileAccess.WRITE)
	fw.store_string(JSON.stringify(future))
	fw.close()
	var target: Node = _new_game()
	target.gold = 41
	var result: SaveGame.LOAD_RESULT = SaveGame.load_from(TEST_PATH, target)
	_check("future primary returns VERSION_MISMATCH despite valid v2 backup",
		result == SaveGame.LOAD_RESULT.VERSION_MISMATCH)
	_check("future-version rejection does not mutate target state", target.gold == 41)
	backup_game.free()
	target.free()
	_cleanup_temp()

func _test_migrate_legacy_trades() -> void:
	print("[migrate: legacy four-trade XP]")
	_cleanup_temp()

	# Build a v0-style save without "wayfinding"; include legacy trade XP.
	# xp_for_level(3) = (3-1)^2*8 + (3-1)*32 = 32+64 = 96 — lv 3 needs 96 xp.
	# Split across legacy keys so total >= 96.
	var legacy := {
		"version": 1,
		"trades": {"carto": {"lv": 1, "xp": 50}, "earth": {"lv": 1, "xp": 50}},
		"materials": {}, "charts": [], "gold": 0, "summit_cleared": false,
		"muted": false, "loadout": [], "chosen_perks": {}, "ledger": {},
		"discovered_inks": ["hedge_ink"], "seen_hints": {},
		"tutorial_step": 0, "player_hp": -1, "inventory": [], "equipment": {}
	}
	var fw := FileAccess.open(TEST_PATH, FileAccess.WRITE)
	fw.store_string(JSON.stringify(legacy))
	fw.close()

	var g: Node = _new_game()
	var r: SaveGame.LOAD_RESULT = SaveGame.load_from(TEST_PATH, g)
	_check("legacy load ok", r == SaveGame.LOAD_RESULT.OK)
	_check("canonical Trade keys present", (g.trades as Dictionary).keys() == Progression.TRADE_KEYS,
		str(g.trades.keys()))
	_check("xp collapsed (>=100)", int(g.trades.wayfinding.xp) >= 100,
		str(g.trades.wayfinding.xp))
	_check("level derived from xp (>=3)",
		int(g.trades.wayfinding.lv) >= 3, str(g.trades.wayfinding.lv))

	g.free()
	_cleanup_temp()

func _test_migrate_pre43_inks() -> void:
	print("[migrate: pre-spec-43 discovered_inks backfill]")
	_cleanup_temp()

	# Write a valid save that lacks the discovered_inks key entirely.
	var old_save := {
		"version": 1,
		"trades": {"wayfinding": {"lv": 2, "xp": 40}},
		"materials": {}, "charts": [], "gold": 0, "summit_cleared": false,
		"muted": false, "loadout": [], "chosen_perks": {}, "ledger": {},
		"seen_hints": {}, "tutorial_step": 0, "player_hp": -1,
		"inventory": [], "equipment": {}
		# "discovered_inks" deliberately absent
	}
	var fw := FileAccess.open(TEST_PATH, FileAccess.WRITE)
	fw.store_string(JSON.stringify(old_save))
	fw.close()

	var g: Node = _new_game()
	var r: SaveGame.LOAD_RESULT = SaveGame.load_from(TEST_PATH, g)
	_check("pre-43 load ok", r == SaveGame.LOAD_RESULT.OK)
	_check("three base inks seeded", g.discovered_inks ==
		["hedge_ink", "stoneground_ink", "refined_ink"],
		str(g.discovered_inks))

	g.free()
	_cleanup_temp()

func _test_chart_table_component_migration() -> void:
	print("[migrate: Chart Table component bundle]")
	_cleanup_temp()
	var known := ["snug", "green_hollow", "queens_summit"]
	var expected: Dictionary = ChartsData.compatibility_component_bundle(known)
	_check("compatibility fixture has ordinary components", not expected.is_empty(), str(expected))
	# This fixture models a legacy player with known recipe access, a living
	# Chart in the case, and consumables that must never be supplied by the
	# component migration. Deliberately omit chart_table_version.
	var legacy_chart := {"template_id": "tier_1", "tier": 1, "scope": "hollow",
		"name": "Tier 1 Hollow", "seed": 42, "affixes": []}
	var old_save := {
		"version": SaveGame.VERSION,
		"trades": {"wayfinding": {"lv": 16,
			"xp": Progression.xp_for_level(16)}},
		"materials": {"hedge_ink": 7, "thorn_essence": 1},
		"charts": [legacy_chart], "gold": 0, "summit_cleared": false,
		"muted": false, "loadout": [], "chosen_perks": {}, "ledger": {},
		"discovered_inks": ["hedge_ink"], "known_chart_recipes": known,
		"seen_hints": {}, "tutorial_step": 0, "player_hp": -1,
		"inventory": [], "equipment": {}
	}
	var fw := FileAccess.open(TEST_PATH, FileAccess.WRITE)
	fw.store_string(JSON.stringify(old_save))
	fw.close()

	var g1: Node = _new_game()
	_check("pre-B Chart Table save loads",
		SaveGame.load_from(TEST_PATH, g1) == SaveGame.LOAD_RESULT.OK)
	var exact_bundle := true
	for id in expected:
		exact_bundle = exact_bundle and g1.material_count(String(id)) == int(expected[id])
	_check("legacy bundle uses ChartsData max-per-recipe quantities", exact_bundle,
		str({"expected": expected, "materials": g1.materials}))
	_check("migration preserves known recipes and legacy Chart exactly",
		g1.known_chart_recipes == known and g1.charts.size() == 1
			and _legacy_chart_matches(g1.charts[0], legacy_chart),
		str({"known": g1.known_chart_recipes, "charts": g1.charts}))
	_check("migration grants no Ink or trophy",
		g1.material_count("hedge_ink") == 7 and g1.material_count("thorn_essence") == 1)
	_check("migration marks the Chart Table version",
		int(g1.chart_table_version) == SaveGame.CHART_TABLE_VERSION)

	# Consume one granted component, persist the marker, then load a second
	# time. The second restore must retain the consumed count rather than
	# re-granting the compatibility bundle.
	var consumed_id := String(expected.keys()[0]) if not expected.is_empty() else ""
	if consumed_id != "":
		g1.materials[consumed_id] = maxi(0, g1.material_count(consumed_id) - 1)
		if g1.materials[consumed_id] == 0:
			g1.materials.erase(consumed_id)
	var after_consumption: Dictionary = g1.materials.duplicate(true)
	_check("migrated save persists", SaveGame.save_to(TEST_PATH, g1))
	var saved_file := FileAccess.open(TEST_PATH, FileAccess.READ)
	var saved: Dictionary = JSON.parse_string(
		saved_file.get_as_text() if saved_file != null else "") as Dictionary
	if saved_file != null:
		saved_file.close()
	_check("Chart Table version marker persists in save",
		int((saved as Dictionary).get("chart_table_version", 0))
			== SaveGame.CHART_TABLE_VERSION)
	var g2: Node = _new_game()
	_check("migrated save reloads", SaveGame.load_from(TEST_PATH, g2) == SaveGame.LOAD_RESULT.OK)
	_check("reloading a marked save does not regrant consumed components",
		g2.materials == after_consumption, str({"expected": after_consumption,
			"actual": g2.materials}))
	_check("reloaded marked save keeps recipes and legacy Chart unchanged",
		g2.known_chart_recipes == known and g2.charts.size() == 1
			and _legacy_chart_matches(g2.charts[0], legacy_chart))

	g1.free()
	g2.free()
	_cleanup_temp()

func _test_chart_recipe_journal_migration() -> void:
	print("[migrate: Chart Recipe journal]")
	_cleanup_temp()
	var before_materials := {"practice_leaf": 2, "hedge_sprig": 3,
		"field_parchment": 1, "loop_cord": 1, "hedge_ink": 4}
	var g1: Node = _new_game()
	g1.materials = before_materials.duplicate(true)
	g1.known_chart_recipes = ["snug", "green_hollow"]
	g1.chart_recipe_journal = ChartsData.fresh_recipe_journal()
	g1.chart_table_version = SaveGame.CHART_TABLE_VERSION
	_check("marked Slice-B fixture saves", SaveGame.save_to(TEST_PATH, g1))
	var source_file := FileAccess.open(TEST_PATH, FileAccess.READ)
	var raw: Dictionary = JSON.parse_string(
		source_file.get_as_text() if source_file != null else "") as Dictionary
	if source_file != null:
		source_file.close()
	raw.erase("chart_recipe_journal")
	var old_file := FileAccess.open(TEST_PATH, FileAccess.WRITE)
	old_file.store_string(JSON.stringify(raw))
	old_file.close()

	var g2: Node = _new_game()
	_check("save missing only the C1 journal loads",
		SaveGame.load_from(TEST_PATH, g2) == SaveGame.LOAD_RESULT.OK)
	_check("missing journal backfills known provenance without granting knowledge",
		g2.known_chart_recipes == ["snug", "green_hollow"]
		and g2.chart_recipe_journal == {"rumours": [], "discoveries": {
			"snug": "legacy", "green_hollow": "legacy"}})
	_check("journal backfill does not regrant Slice-B components",
		g2.materials == before_materials,
		str({"expected": before_materials, "actual": g2.materials}))
	_check("normalized journal persists", SaveGame.save_to(TEST_PATH, g2))
	var persisted := FileAccess.open(TEST_PATH, FileAccess.READ)
	var persisted_size := persisted.get_length() if persisted != null else 1 << 30
	if persisted != null:
		persisted.close()
	_check("save remains below the 256 KB budget", persisted_size < 256 * 1024,
		str(persisted_size))
	var g3: Node = _new_game()
	_check("journal migration is idempotent across a second restore",
		SaveGame.load_from(TEST_PATH, g3) == SaveGame.LOAD_RESULT.OK
		and g3.chart_recipe_journal == g2.chart_recipe_journal
		and g3.materials == before_materials)

	g1.free()
	g2.free()
	g3.free()
	_cleanup_temp()

func _test_chart_source_migration() -> void:
	print("[migrate: Chart source unlocks]")
	_cleanup_temp()
	var before_materials := {"hedge_ink": 4, "hedge_sprig": 2,
		"stitched_parchment": 1, "hollow_stitch": 1}
	var g1: Node = _new_game()
	g1.trades = Progression.fresh_trade_state()
	g1.trades.wayfinding = {"xp": Progression.xp_for_level(12), "lv": 12}
	g1.materials = before_materials.duplicate(true)
	g1.known_chart_recipes = ["snug", "green_hollow", "deep_hollow"]
	g1.chart_recipe_journal = ChartsData.fresh_recipe_journal()
	g1.chart_source_unlocks = []
	g1.chart_table_version = SaveGame.CHART_TABLE_VERSION
	g1.seen_hints = {"tier1_completed": true}
	var xp_before := int(g1.trades.wayfinding.xp)
	_check("explicit-empty source fixture saves", SaveGame.save_to(TEST_PATH, g1))

	# Presence is authoritative: a current save may deliberately have no source
	# unlocks even when compatibility evidence could otherwise derive them.
	var explicit: Node = _new_game()
	_check("explicit-empty source save loads",
		SaveGame.load_from(TEST_PATH, explicit) == SaveGame.LOAD_RESULT.OK)
	_check("explicit empty source unlocks are respected",
		explicit.chart_source_unlocks.is_empty())
	explicit.free()

	# Removing only the optional field models a pre-C2 save. Compatibility
	# derives availability, never the read rumour, kit, recipe, or XP.
	var source_file := FileAccess.open(TEST_PATH, FileAccess.READ)
	var raw: Dictionary = JSON.parse_string(
		source_file.get_as_text() if source_file != null else "") as Dictionary
	if source_file != null:
		source_file.close()
	raw.erase("chart_source_unlocks")
	var old_file := FileAccess.open(TEST_PATH, FileAccess.WRITE)
	old_file.store_string(JSON.stringify(raw))
	old_file.close()
	var migrated: Node = _new_game()
	_check("save missing only source unlocks loads",
		SaveGame.load_from(TEST_PATH, migrated) == SaveGame.LOAD_RESULT.OK)
	_check("missing field derives Atlas and rain-note compatibility unlocks",
		migrated.chart_source_unlocks == ["atlas_deep_hollow", "mara_sallow_reed"])
	_check("source migration grants no rumour, kit, recipe, or XP",
		(migrated.chart_recipe_journal.rumours as Array).is_empty()
		and migrated.materials == before_materials
		and migrated.known_chart_recipes == ["snug", "green_hollow", "deep_hollow"]
		and int(migrated.trades.wayfinding.xp) == xp_before)
	_check("source migration does not bump the save version",
		SaveGame.VERSION == Progression.SAVE_VERSION)
	_check("derived source unlocks persist", SaveGame.save_to(TEST_PATH, migrated))
	var reloaded: Node = _new_game()
	_check("persisted source unlocks reload without re-derivation",
		SaveGame.load_from(TEST_PATH, reloaded) == SaveGame.LOAD_RESULT.OK
		and reloaded.chart_source_unlocks == migrated.chart_source_unlocks
		and reloaded.materials == before_materials
		and (reloaded.chart_recipe_journal.rumours as Array).is_empty())

	g1.free()
	migrated.free()
	reloaded.free()
	_cleanup_temp()

func _test_campaign_roundtrip_and_legacy_inference() -> void:
	print("[campaign state: optional migration + truthful inference]")
	_cleanup_temp()
	var explicit: Node = _new_game()
	explicit.campaign_state = CampaignData.empty_state()
	explicit.ledger.apply("tusker_tusk")
	explicit.summit_cleared = true
	_check("explicit campaign fixture saves", SaveGame.save_to(TEST_PATH, explicit))
	var explicit_loaded: Node = _new_game()
	_check("explicit campaign state loads",
		SaveGame.load_from(TEST_PATH, explicit_loaded) == SaveGame.LOAD_RESULT.OK)
	_check("explicit uncleared state remains authoritative despite legacy proofs",
		not CampaignData.chapter_cleared(explicit_loaded.campaign_state)
		and (explicit_loaded.campaign_state.relics as Array).is_empty()
		and (explicit_loaded.campaign_state.restorations as Array).is_empty())
	explicit_loaded.free()

	# Removing only the optional field models a pre-D1 save. Either a claimed
	# Tusker Ledger slot or the later Summit clear is durable completion proof.
	var source := FileAccess.open(TEST_PATH, FileAccess.READ)
	var raw: Dictionary = JSON.parse_string(
		source.get_as_text() if source != null else "") as Dictionary
	if source != null:
		source.close()
	raw.erase("campaign_state")

	var ledger_only_raw := raw.duplicate(true)
	ledger_only_raw.summit_cleared = false
	var old_file := FileAccess.open(TEST_PATH, FileAccess.WRITE)
	old_file.store_string(JSON.stringify(ledger_only_raw))
	old_file.close()
	var ledger_inferred: Node = _new_game()
	_check("legacy Ledger-only campaign save loads",
		SaveGame.load_from(TEST_PATH, ledger_inferred) == SaveGame.LOAD_RESULT.OK)
	_check("legacy Ledger proof infers one First Knot clear",
		CampaignData.chapter_cleared(ledger_inferred.campaign_state)
		and CampaignData.chapter_clue_count(ledger_inferred.campaign_state) == 3)

	var summit_only_raw := raw.duplicate(true)
	summit_only_raw.ledger = {}
	summit_only_raw.summit_cleared = true
	old_file = FileAccess.open(TEST_PATH, FileAccess.WRITE)
	old_file.store_string(JSON.stringify(summit_only_raw))
	old_file.close()
	var summit_inferred: Node = _new_game()
	_check("legacy Summit-only campaign save loads",
		SaveGame.load_from(TEST_PATH, summit_inferred) == SaveGame.LOAD_RESULT.OK)
	_check("legacy Summit proof infers one First Knot clear",
		CampaignData.chapter_cleared(summit_inferred.campaign_state)
		and (summit_inferred.campaign_state.relics as Array) == ["green_root_rune"]
		and (summit_inferred.campaign_state.restorations as Array) == ["trophy_hall"])

	var neither_raw := summit_only_raw.duplicate(true)
	neither_raw.summit_cleared = false
	old_file = FileAccess.open(TEST_PATH, FileAccess.WRITE)
	old_file.store_string(JSON.stringify(neither_raw))
	old_file.close()
	var not_inferred: Node = _new_game()
	_check("legacy save without durable proof stays uncleared",
		SaveGame.load_from(TEST_PATH, not_inferred) == SaveGame.LOAD_RESULT.OK
		and not CampaignData.chapter_cleared(not_inferred.campaign_state))
	_check("legacy inference never mints physical boss rewards",
		ledger_inferred.material_count("tusker_tusk") == 0
		and summit_inferred.material_count("tusker_tusk") == 0
		and not_inferred.material_count("tusker_tusk") == 0)
	explicit.free()
	ledger_inferred.free()
	summit_inferred.free()
	not_inferred.free()
	_cleanup_temp()

func _test_campaign_escrow_recovery() -> void:
	print("[campaign escrow: crash recovery + tombstone]")
	_cleanup_temp()
	var source_game: Node = _new_game()
	source_game.materials = {}
	(source_game.campaign_state.chapters.first_knot as Dictionary).clue_count = 3
	var begun := CampaignData.begin_boss_escrow(source_game.campaign_state,
		"chart-recovery-fixture", CampaignData.FIRST_KNOT)
	var marked := CampaignData.mark_escrow_in_run(begun.state,
		String(begun.attempt_id), "chart-recovery-fixture",
		CampaignData.FIRST_KNOT)
	source_game.campaign_state = marked.state
	_check("in-run escrow fixture saves", bool(begun.ok) and bool(marked.ok)
		and SaveGame.save_to(TEST_PATH, source_game))

	var recovered: Node = _new_game()
	_check("in-run campaign save loads and reconciles",
		SaveGame.load_from(TEST_PATH, recovered) == SaveGame.LOAD_RESULT.OK)
	var recovered_record: Dictionary = recovered.campaign_state.escrows[
		String(begun.attempt_id)]
	_check("unresumable attempt refunds exact Seal and keeps terminal tombstone",
		recovered.material_count("thorn_essence") == 1
		and String(recovered_record.phase) == "refunded"
		and int(recovered.campaign_state.next_attempt_id) == 2)
	_check("load path immediately persists recovery tombstone",
		not bool(recovered.get("_campaign_recovery_dirty")))
	# The recovery write must replace the backup too. Otherwise corrupting the
	# reconciled primary could fall back to the old in-run snapshot and replay the
	# unique Seal refund.
	var corrupt := FileAccess.open(TEST_PATH, FileAccess.WRITE)
	corrupt.store_string("{corrupt after campaign recovery")
	corrupt.close()
	var fallback: Node = _new_game()
	_check("corrupt-primary fallback uses the reconciled escrow tombstone",
		SaveGame.load_from(TEST_PATH, fallback) == SaveGame.LOAD_RESULT.OK
		and fallback.material_count("thorn_essence") == 1
		and String(fallback.campaign_state.escrows[
			String(begun.attempt_id)].phase) == "refunded")

	var second_load: Node = _new_game()
	_check("reconciled save loads a second time",
		SaveGame.load_from(TEST_PATH, second_load) == SaveGame.LOAD_RESULT.OK)
	_check("terminal refund cannot replay across another boot",
		second_load.material_count("thorn_essence") == 1
		and String(second_load.campaign_state.escrows[
			String(begun.attempt_id)].phase) == "refunded")
	source_game.free()
	recovered.free()
	fallback.free()
	second_load.free()
	_cleanup_temp()

func _test_seventh_road_and_handoff_roundtrip() -> void:
	print("[Seventh Road save: frozen Summit handoff recovery]")
	_cleanup_temp()
	var source_game: Node = _new_game()
	source_game.materials = {}
	var settled := CampaignData.normalize_campaign_state({
		"version": CampaignData.STATE_VERSION,
		"next_attempt_id": 4,
		"chapters": {
			CampaignData.FIRST_KNOT: {"cleared": true, "clue_count": 3,
				"banked_chart_ids": ["first-a", "first-b", "first-c"]},
			CampaignData.GOLDEN_WALLOW: {"cleared": true, "clue_count": 3,
				"banked_chart_ids": ["gold-a", "gold-b", "gold-c"]},
			CampaignData.SEVENTH_ROAD: {"cleared": true, "clue_count": 4,
				"banked_chart_ids": ["briar-a", "briar-b", "briar-c", "briar-d"]},
		},
		"relics": ["green_root_rune", "mist_root_rune", "fang_root_rune"],
		"restorations": ["trophy_hall", "sallow_jetty", "skald_archive"],
	})
	var legacy_attempt_id := "legacy_summit_handoff-4"
	settled.escrows = {
		legacy_attempt_id: {
			"attempt_id": legacy_attempt_id,
			"chart_instance_id": "summit-save-fixture",
			"kind": "handoff",
			"contract_id": CampaignData.LEGACY_SUMMIT_HANDOFF,
			"phase": "in_run",
			"items": {"alpha_fang": 1},
		},
	}
	source_game.campaign_state = CampaignData.normalize_campaign_state(settled)
	source_game.chart_source_unlocks = ["skald_queens_summit"]
	_check("settled Seventh Road with frozen entered Summit handoff saves",
		SaveGame.save_to(TEST_PATH, source_game))

	var recovered: Node = _new_game()
	_check("Seventh Road handoff save loads and reconciles",
		SaveGame.load_from(TEST_PATH, recovered) == SaveGame.LOAD_RESULT.OK)
	var chapter: Dictionary = recovered.campaign_state.chapters.seventh_road
	var record: Dictionary = recovered.campaign_state.escrows[legacy_attempt_id]
	_check("Seventh settlement, ledger, relic, restoration, and source survive",
		bool(chapter.cleared) and int(chapter.clue_count) == 4
		and (chapter.banked_chart_ids as Array).size() == 4
		and (recovered.campaign_state.relics as Array).has("fang_root_rune")
		and (recovered.campaign_state.restorations as Array).has("skald_archive")
		and recovered.chart_source_unlocks.has("skald_queens_summit"))
	_check("unresumable Summit handoff refunds Alpha Fang once",
		String(record.phase) == "refunded"
		and recovered.material_count("alpha_fang") == 1)

	var second_load: Node = _new_game()
	_check("persisted handoff tombstone prevents a second Fang refund",
		SaveGame.load_from(TEST_PATH, second_load) == SaveGame.LOAD_RESULT.OK
		and second_load.material_count("alpha_fang") == 1
		and String(second_load.campaign_state.escrows[
			legacy_attempt_id].phase) == "refunded")
	source_game.free()
	recovered.free()
	second_load.free()
	_cleanup_temp()

func _write_legacy_summit_credit_fixture(phase: String, materials: Dictionary = {},
		campaign_version: int = 2, contract_id: String = CampaignData.LEGACY_SUMMIT_HANDOFF) -> void:
	_cleanup_temp()
	var source: Node = _new_game()
	source.materials = materials.duplicate(true)
	SaveGame.save_to(TEST_PATH, source)
	var file := FileAccess.open(TEST_PATH, FileAccess.READ)
	var raw: Dictionary = JSON.parse_string(file.get_as_text() if file != null else "") as Dictionary
	if file != null:
		file.close()
	raw.materials = materials.duplicate(true)
	raw.campaign_state = {
		"version": campaign_version,
		"next_attempt_id": 2,
		"escrows": {
			"legacy_summit_handoff-1": {
				"attempt_id": "legacy_summit_handoff-1",
				"chart_instance_id": "legacy-summit-chart",
				"kind": "handoff",
				"contract_id": contract_id,
				"phase": phase,
				"items": {"alpha_fang": 1},
			},
		},
	}
	file = FileAccess.open(TEST_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(raw))
	file.close()
	source.free()

func _test_legacy_summit_fang_credit_recovery() -> void:
	print("[Queen v3: legacy consumed Summit Fang credit]")
	_write_legacy_summit_credit_fixture("consumed")
	var credited: Node = _new_game()
	_check("consumed v2 handoff missing Fang loads with the exact one-time credit",
		SaveGame.load_from(TEST_PATH, credited) == SaveGame.LOAD_RESULT.OK
		and credited.material_count("alpha_fang") == 1
		and bool(credited.campaign_state.legacy_summit_alpha_fang_credit)
		and not bool(credited.get("_campaign_recovery_dirty")))
	var second_load: Node = _new_game()
	_check("persisted v3 marker prevents a second legacy credit on another boot",
		SaveGame.load_from(TEST_PATH, second_load) == SaveGame.LOAD_RESULT.OK
		and second_load.material_count("alpha_fang") == 1
		and bool(second_load.campaign_state.legacy_summit_alpha_fang_credit))
	var corrupt := FileAccess.open(TEST_PATH, FileAccess.WRITE)
	corrupt.store_string("{corrupt after Fang credit")
	corrupt.close()
	var fallback: Node = _new_game()
	_check("corrupt primary falls back to the reconciled credit marker and Fang",
		SaveGame.load_from(TEST_PATH, fallback) == SaveGame.LOAD_RESULT.OK
		and fallback.material_count("alpha_fang") == 1
		and bool(fallback.campaign_state.legacy_summit_alpha_fang_credit))
	credited.free()
	second_load.free()
	fallback.free()

	_write_legacy_summit_credit_fixture("consumed", {"alpha_fang": 1})
	var owned: Node = _new_game()
	_check("already-owned Fang is not duplicated while the qualifying marker still persists",
		SaveGame.load_from(TEST_PATH, owned) == SaveGame.LOAD_RESULT.OK
		and owned.material_count("alpha_fang") == 1
		and bool(owned.campaign_state.legacy_summit_alpha_fang_credit))
	owned.free()

	var exclusion_ok := true
	for phase in ["case", "in_run", "refunded"]:
		_write_legacy_summit_credit_fixture(phase)
		var excluded: Node = _new_game()
		exclusion_ok = exclusion_ok \
			and SaveGame.load_from(TEST_PATH, excluded) == SaveGame.LOAD_RESULT.OK \
			and not bool(excluded.campaign_state.legacy_summit_alpha_fang_credit)
		excluded.free()
	_write_legacy_summit_credit_fixture("consumed", {}, 2, "not_a_handoff")
	var non_handoff: Node = _new_game()
	exclusion_ok = exclusion_ok \
		and SaveGame.load_from(TEST_PATH, non_handoff) == SaveGame.LOAD_RESULT.OK \
		and not bool(non_handoff.campaign_state.legacy_summit_alpha_fang_credit) \
		and non_handoff.material_count("alpha_fang") == 0
	non_handoff.free()
	_check("case/in-run/refunded/non-handoff records never receive the v3 credit",
		exclusion_ok)

	# The new Queen attempt is v3 campaign truth and its in-run refund remains a
	# separate recovery concern; it must not gain the legacy marker or credit.
	_cleanup_temp()
	var queen_source: Node = _new_game()
	queen_source.materials = {}
	queen_source.campaign_state = CampaignData.normalize_campaign_state({
		"version": 3,
		"next_attempt_id": 2,
		"escrows": {
			"queens_summit-1": {
				"attempt_id": "queens_summit-1",
				"chart_instance_id": "queen-in-run",
				"chapter_id": CampaignData.QUEENS_SUMMIT,
				"phase": "in_run",
				"items": {"alpha_fang": 1},
			},
		},
	})
	SaveGame.save_to(TEST_PATH, queen_source)
	var queen_recovered: Node = _new_game()
	_check("new Queen in-run refund coexists without a legacy credit marker",
		SaveGame.load_from(TEST_PATH, queen_recovered) == SaveGame.LOAD_RESULT.OK
		and queen_recovered.material_count("alpha_fang") == 1
		and String(queen_recovered.campaign_state.escrows["queens_summit-1"].phase)
			== "refunded"
		and not bool(queen_recovered.campaign_state.legacy_summit_alpha_fang_credit))
	queen_source.free()
	queen_recovered.free()
	_cleanup_temp()

func _test_pale_oath_escrow_recovery_primary_backup() -> void:
	print("[Pale Oath escrow recovery: primary and backup]")
	_cleanup_temp()
	var source: Node = _new_game()
	source.materials = {}
	var state := CampaignData.empty_state()
	for chapter_id in [CampaignData.FIRST_KNOT, CampaignData.GOLDEN_WALLOW,
		CampaignData.SEVENTH_ROAD, CampaignData.QUEENS_SUMMIT]:
		var chapter: Dictionary = state.chapters[chapter_id]
		chapter.cleared = true
		chapter.clue_count = int(CampaignData.CHAPTERS[chapter_id].clue_target)
	var pale: Dictionary = state.chapters[CampaignData.PALE_OATH]
	pale.clue_count = int(CampaignData.CHAPTERS[CampaignData.PALE_OATH].clue_target)
	pale.banked_chart_ids = ["pale-1", "pale-2", "pale-3", "pale-4"]
	state = CampaignData.normalize_campaign_state(state)
	var begun := CampaignData.begin_boss_escrow(state, "pale-save-in-run",
		CampaignData.PALE_OATH)
	var entered := CampaignData.mark_escrow_in_run(begun.state, begun.attempt_id,
		"pale-save-in-run", CampaignData.PALE_OATH)
	source.campaign_state = entered.state
	var saved := SaveGame.save_to(TEST_PATH, source)
	var primary: Node = _new_game()
	var primary_ok: bool = saved \
		and SaveGame.load_from(TEST_PATH, primary) == SaveGame.LOAD_RESULT.OK \
		and primary.material_count("oath_nail") == 1 \
		and String(primary.campaign_state.escrows[begun.attempt_id].phase) == "refunded" \
		and FileAccess.file_exists(TEST_BAK)
	# The recovery writes the reconciled backup before the primary.  A later
	# corrupt-primary fallback must read that tombstone and never refund again.
	var corrupt := FileAccess.open(TEST_PATH, FileAccess.WRITE)
	if corrupt != null:
		corrupt.store_string("{not valid json")
		corrupt.close()
	var fallback: Node = _new_game()
	var fallback_ok: bool = SaveGame.load_from(TEST_PATH, fallback) == SaveGame.LOAD_RESULT.OK \
		and fallback.material_count("oath_nail") == 1 \
		and String(fallback.campaign_state.escrows[begun.attempt_id].phase) == "refunded"
	_check("Pale in-run Oath Nail recovers once from primary and reconciled backup",
		primary_ok and fallback_ok)
	source.free()
	primary.free()
	fallback.free()
	_cleanup_temp()

func _test_campaign_runtime_settlement() -> void:
	print("[campaign runtime: clues, refund, boss reward]")
	var game: Node = _new_game()
	game.materials = {}
	game.campaign_state = CampaignData.empty_state()
	game.trades.wayfinding = {"xp": Progression.xp_for_level(4), "lv": 4}
	var green_one := {"recipe_id": "green_hollow",
		"chart_instance_id": "chart-green-return-1", "template_id": "tier_1",
		"seed": 401, "affixes": []}
	var green_two := green_one.duplicate(true)
	green_two.chart_instance_id = "chart-green-return-2"
	green_two.seed = 402
	var green_three := green_one.duplicate(true)
	green_three.chart_instance_id = "chart-green-return-3"
	green_three.seed = 403
	game.active_chart = green_one
	var green_cfg: Dictionary = game.run_cfg()
	_check("run config publishes the next authored clue without mutating state",
		String((green_cfg.get("campaign_clue", {}) as Dictionary).get("clue_id", ""))
			== "thorn_whisper_1"
		and CampaignData.chapter_clue_count(game.campaign_state) == 0)
	game.active_chart = {}
	game._record_campaign_chart_return(green_one)
	var state_after_first := CampaignData.campaign_fingerprint(game.campaign_state)
	game._record_campaign_chart_return(green_one)
	var unidentified_green := green_two.duplicate(true)
	unidentified_green.erase("chart_instance_id")
	game._record_campaign_chart_return(unidentified_green)
	_check("repeated or unidentified Green returns are campaign-inert",
		CampaignData.campaign_fingerprint(game.campaign_state) == state_after_first
		and CampaignData.chapter_clue_count(game.campaign_state) == 1)
	game._record_campaign_chart_return(green_two)
	var before_third: Dictionary = game.materials.duplicate(true)
	game._record_campaign_chart_return(green_three)
	_check("three proven Green returns bank exactly three clues",
		CampaignData.chapter_clue_count(game.campaign_state) == 3)
	_check("third clue tops missing Seal once and records Mara's rumour",
		not before_third.has("thorn_essence")
		and game.material_count("thorn_essence") == 1
		and (game.chart_recipe_journal.rumours as Array).has("mara_first_knot"))
	var state_after_three := CampaignData.campaign_fingerprint(game.campaign_state)
	var green_four := green_one.duplicate(true)
	green_four.chart_instance_id = "chart-green-return-4"
	green_four.seed = 404
	game._record_campaign_chart_return(green_four)
	_check("fourth return cannot bank or replenish the chapter",
		CampaignData.campaign_fingerprint(game.campaign_state) == state_after_three
		and game.material_count("thorn_essence") == 1)
	_check("legacy elite trophy RNG stays closed before the authored clear",
		not game.campaign_elite_trophy_eligible())
	var campaign_before_legacy := CampaignData.campaign_fingerprint(
		game.campaign_state)
	var legacy_chart := {"template_id": "tier_1", "seed": 777,
		"affixes": [{"id": "hedgemother_den", "good": true}]}
	var legacy_run: Dictionary = game._mark_campaign_chart_in_run(legacy_chart)
	game.active_chart = legacy_chart
	var legacy_cfg: Dictionary = game.run_cfg()
	game.active_chart = {}
	var legacy_resolve: Dictionary = game.resolve_campaign_boss_death(legacy_chart)
	_check("legacy boss-den Charts remain playable and campaign-inert",
		bool(legacy_run.ok) and not legacy_run.chart.has("attempt_id")
		and String(legacy_resolve.get("reason", "")) == "not_campaign_boss"
		and CampaignData.campaign_fingerprint(game.campaign_state)
			== campaign_before_legacy
		and not legacy_cfg.has("campaign_contract")
		and String(legacy_cfg.get("boss_kind", "")) == "hedgemother")

	# Author a case escrow, move it in-run, then simulate the old boss-death
	# callback having already paid its Tusker before the return transaction.
	game.trades.wayfinding = {"xp": Progression.xp_for_level(8), "lv": 8}
	var chart := {"recipe_id": CampaignData.FIRST_KNOT_BOSS_RECIPE,
		"chart_instance_id": "chart-runtime-clear", "template_id": "tier_1",
		"seed": 801, "affixes": [],
		"campaign_contract": CampaignData.boss_contract(
			CampaignData.FIRST_KNOT_BOSS_RECIPE)}
	game.active_chart = chart
	var boss_cfg: Dictionary = game.run_cfg()
	_check("run config publishes the authored boss contract",
		boss_cfg.get("campaign_contract", {}) == chart.campaign_contract
		and String(boss_cfg.get("boss_kind", "")) == "hedgemother")
	game.active_chart = {}
	var case_result: Dictionary = game._begin_campaign_case_escrow(chart)
	game.campaign_state = case_result.state
	chart = case_result.chart
	# The live inscription commit spends the physical Seal after escrow begins.
	game.materials.erase("thorn_essence")
	var mismatched_socket_chart := chart.duplicate(true)
	mismatched_socket_chart.chart_instance_id = "chart-runtime-forged-socket"
	var mismatched_socket: Dictionary = game._mark_campaign_chart_in_run(
		mismatched_socket_chart)
	_check("socket rejects an attempt bound to a different physical Chart",
		not bool(mismatched_socket.get("ok", false))
		and String(game.campaign_state.escrows[String(chart.attempt_id)].phase)
			== "case")
	var run_result: Dictionary = game._mark_campaign_chart_in_run(chart)
	game.campaign_state = run_result.state
	chart = run_result.chart
	var before_mismatch := CampaignData.campaign_fingerprint(game.campaign_state)
	var mismatched_abandon_chart := chart.duplicate(true)
	mismatched_abandon_chart.attempt_id = "first_knot-999999"
	var mismatched_abandon: Dictionary = game._refund_campaign_attempt(
		mismatched_abandon_chart)
	_check("abandon rejects a Chart bound to a different attempt",
		not bool(mismatched_abandon.get("ok", false))
		and CampaignData.campaign_fingerprint(game.campaign_state) == before_mismatch
		and game.material_count("thorn_essence") == 0)
	var forged_contract_chart := chart.duplicate(true)
	forged_contract_chart.campaign_contract = (chart.campaign_contract as Dictionary) \
		.duplicate(true)
	forged_contract_chart.campaign_contract.boss_kind = "burrow_boar"
	game.active_chart = forged_contract_chart
	var forged_contract_cfg: Dictionary = game.run_cfg()
	game.active_chart = {}
	var forged_contract_death: Dictionary = game.resolve_campaign_boss_death(
		forged_contract_chart)
	var forged_recipe_chart := chart.duplicate(true)
	forged_recipe_chart.recipe_id = "green_hollow"
	var forged_recipe_death: Dictionary = game.resolve_campaign_boss_death(
		forged_recipe_chart)
	_check("boss death rejects forged contract and recipe bindings",
		not bool(forged_contract_death.get("ok", false))
		and not bool(forged_recipe_death.get("ok", false))
		and not forged_contract_cfg.has("campaign_contract")
		and String(forged_contract_cfg.get("boss_kind", "")) == ""
		and CampaignData.campaign_fingerprint(game.campaign_state) == before_mismatch
		and not CampaignData.chapter_cleared(game.campaign_state))
	game._record_campaign_chart_return(chart)
	_check("successful return bookkeeping cannot clear a campaign boss",
		not CampaignData.chapter_cleared(game.campaign_state)
		and String(game.campaign_state.escrows[String(chart.attempt_id)].phase)
			== "in_run"
		and game.material_count("tusker_tusk") == 0)
	game.materials["tusker_tusk"] = 1
	var clear_result: Dictionary = game.resolve_campaign_boss_death(chart)
	var tusks_after_clear: int = game.material_count("tusker_tusk")
	var repeated_clear: Dictionary = game.resolve_campaign_boss_death(chart)
	_check("named boss death consumes escrow and clears the First Knot once",
		bool(case_result.ok) and bool(run_result.ok) and bool(clear_result.changed)
		and CampaignData.chapter_cleared(game.campaign_state)
		and String(game.campaign_state.escrows[String(chart.attempt_id)].phase)
			== "consumed")
	_check("boss reward is missing-only/idempotent across old callback + repeat",
		tusks_after_clear == 1 and game.material_count("tusker_tusk") == 1
		and not bool(repeated_clear.get("changed", false))
		and game.ledger.slots.has("tusker_tusk"))
	_check("clear records Root Rune, Trophy Hall, and opens legacy elite RNG",
		(game.campaign_state.relics as Array) == ["green_root_rune"]
		and (game.campaign_state.restorations as Array) == ["trophy_hall"]
		and game.campaign_elite_trophy_eligible())
	var settled_fingerprint := CampaignData.campaign_fingerprint(game.campaign_state)
	game.active_chart = chart
	game.return_to_town(null, false)
	_check("post-boss successful return preserves the consumed settlement",
		CampaignData.campaign_fingerprint(game.campaign_state) == settled_fingerprint
		and String(game.campaign_state.escrows[String(chart.attempt_id)].phase)
			== "consumed"
		and game.material_count("tusker_tusk") == 1
		and (game.campaign_state.relics as Array) == ["green_root_rune"]
		and (game.campaign_state.restorations as Array) == ["trophy_hall"])
	game.active_chart = chart
	game.return_to_town(null, true)
	_check("post-boss abandon cannot refund a consumed Seal",
		CampaignData.campaign_fingerprint(game.campaign_state) == settled_fingerprint
		and game.material_count("thorn_essence") == 0
		and String(game.campaign_state.escrows[String(chart.attempt_id)].phase)
			== "consumed")
	game.free()

	var abandon: Node = _new_game()
	abandon.materials = {}
	abandon.campaign_state = CampaignData.empty_state()
	(abandon.campaign_state.chapters.first_knot as Dictionary).clue_count = 3
	abandon.trades.wayfinding = {"xp": Progression.xp_for_level(8), "lv": 8}
	var abandoned_chart := chart.duplicate(true)
	abandoned_chart.erase("attempt_id")
	abandoned_chart.chart_instance_id = "chart-runtime-abandon"
	var abandon_case: Dictionary = abandon._begin_campaign_case_escrow(abandoned_chart)
	abandon.campaign_state = abandon_case.state
	abandoned_chart = abandon_case.chart
	var abandon_run: Dictionary = abandon._mark_campaign_chart_in_run(abandoned_chart)
	abandon.campaign_state = abandon_run.state
	abandoned_chart = abandon_run.chart
	var refunded: Dictionary = abandon._refund_campaign_attempt(abandoned_chart)
	var refund_count: int = abandon.material_count("thorn_essence")
	var repeated_refund: Dictionary = abandon._refund_campaign_attempt(abandoned_chart)
	_check("abandon refunds the unique Seal exactly once",
		bool(refunded.changed) and refund_count == 1
		and abandon.material_count("thorn_essence") == 1
		and not bool(repeated_refund.get("changed", false))
		and String(abandon.campaign_state.escrows[
			String(abandoned_chart.attempt_id)].phase) == "refunded")
	abandon.free()

func _test_real_save_untouched() -> void:
	print("[real save path untouched]")
	var exists_now := FileAccess.file_exists(SaveGame.SAVE_PATH)
	var contents_now := ""
	if exists_now:
		var preserved := FileAccess.open(SaveGame.SAVE_PATH, FileAccess.READ)
		contents_now = preserved.get_as_text() if preserved != null else ""
	_check("real save path preserved", exists_now == _real_save_existed
		and contents_now == _real_save_contents, "REAL SAVE PATH WAS TOUCHED")

func _cleanup_all() -> void:
	_cleanup_temp()
