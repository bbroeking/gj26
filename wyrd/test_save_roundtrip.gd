extends SceneTree

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

func _check(name: String, ok: bool, detail: String = "") -> void:
	if ok:
		_pass += 1
		print("  ✓ %s" % name)
	else:
		_fail += 1
		print("  ✗ %s %s" % [name, detail])

func _init() -> void:
	print("--- save roundtrip check ---")
	_test_roundtrip()
	_test_atomic_write()
	_test_bak_fallback()
	_test_not_found()
	_test_corrupt_no_bak()
	_test_version_mismatch()
	_test_migrate_legacy_trades()
	_test_migrate_pre43_inks()
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

# ---- test cases ----

func _test_roundtrip() -> void:
	print("[roundtrip — all fields]")
	_cleanup_temp()
	var ItemsData = load("res://data/items.gd")

	var g1: Node = _new_game()
	g1.trades.wayfinding = {"lv": 3, "xp": 250}
	g1.add_material("wild_herb", 5)
	g1.charts.append({"template_id": "tier_1", "tier": 1, "scope": "hollow",
		"name": "Tier 1 Hollow", "seed": 42, "affixes": [
			{"id": "mineral_vein", "good": true, "resolvedId": "mineral_vein"}]})
	g1.tutorial_step = 6
	g1.player_hp = 17
	g1.gold = 57
	g1.summit_cleared = true
	g1.muted = true
	g1.loadout = ["PiercingBolt", "MultiShot", "RainOfThorns"]
	g1.discovered_inks = ["hedge_ink", "ash_ink"]
	# Item with Vector2i/Color fields.
	var item: Dictionary = ItemsData.make_item("shortbow", "magic")
	var fit: Dictionary = g1.inventory.find_first_fit(item)
	g1.inventory.try_place(item, fit.pos, fit.rotated)
	# Equipment with Color.
	g1.equipment.slots["helmet"] = ItemsData.make_item("leather_helm", "rare")

	_check("save_to written", SaveGame.save_to(TEST_PATH, g1))
	_check("primary file exists", FileAccess.file_exists(TEST_PATH))

	var g2: Node = _new_game()
	var result: SaveGame.LOAD_RESULT = SaveGame.load_from(TEST_PATH, g2)
	_check("load_from OK", result == SaveGame.LOAD_RESULT.OK)
	_check("wayfinding level", int(g2.trades.wayfinding.lv) == 3)
	_check("satchel restored", g2.material_count("wild_herb") == 5)
	_check("chart restored", (g2.charts as Array).size() == 1
		and String(g2.charts[0].template_id) == "tier_1")
	_check("tutorial step", int(g2.tutorial_step) == 6)
	_check("player_hp", int(g2.player_hp) == 17)
	_check("gold", int(g2.gold) == 57)
	_check("summit_cleared", bool(g2.summit_cleared))
	_check("muted", bool(g2.muted))
	_check("loadout", g2.loadout == ["PiercingBolt", "MultiShot", "RainOfThorns"])
	_check("discovered_inks", g2.discovered_inks == ["hedge_ink", "ash_ink"])
	_check("gear item with Vector2i", g2.inventory.items.size() == 1
		and g2.inventory.items[0].size is Vector2i
		and String(g2.inventory.items[0].kind_id) == "shortbow")
	var helm = g2.equipment.get_slot("helmet")
	_check("equipment with Color", helm != null and helm.icon_color is Color)

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
	_check("wayfinding key present", (g.trades as Dictionary).has("wayfinding"),
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

func _test_real_save_untouched() -> void:
	print("[real save path untouched]")
	_check("real save absent after all tests",
		not FileAccess.file_exists(SaveGame.SAVE_PATH),
		"REAL SAVE PATH WAS TOUCHED: " + SaveGame.SAVE_PATH)

func _cleanup_all() -> void:
	_cleanup_temp()
