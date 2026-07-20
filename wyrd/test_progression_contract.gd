extends SceneTree

# Pure ADR-0016 contract tests.  This suite intentionally does not instantiate
# Game or SaveGame: 0A proves the seam before 0B changes live persistence.

const Progression = preload("res://data/progression.gd")

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
	print("--- progression contract check ---")
	_test_fresh_state_and_cap()
	_test_runtime_keys_and_aliases()
	_test_unlock_registry()
	_test_trade_migrations()
	_test_skill_ownership_migration()
	print("--- %d passed, %d failed ---" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)

func _test_fresh_state_and_cap() -> void:
	print("[fresh state + cap]")
	var state := Progression.fresh_trade_state()
	_check("four canonical Trade keys", state.keys() == Progression.TRADE_KEYS,
		str(state.keys()))
	state.wayfinding.xp = 40
	_check("fresh Trades are independent dictionaries",
		int(state.earthcraft.xp) == 0 and int(state.wildcraft.xp) == 0)
	_check("level 23 XP is 4576", Progression.xp_for_level(23) == 4576,
		str(Progression.xp_for_level(23)))
	var capped := Progression.award_trade_xp({"xp": Progression.max_xp() - 1}, 99)
	_check("XP clamps at level-23 maximum", int(capped.xp) == 4576, str(capped))
	_check("capped XP derives level 23", int(capped.lv) == 23, str(capped))
	var stale := Progression.normalize_trade_record({"xp": 40, "lv": 23})
	_check("level is always derived from XP", int(stale.lv) == 2, str(stale))
	var negative := Progression.normalize_trade_record({"xp": -999, "lv": 9})
	_check("negative XP normalizes to fresh state", negative == {"xp": 0, "lv": 1}, str(negative))

func _test_runtime_keys_and_aliases() -> void:
	print("[key contract]")
	_check("Wayfinding is a runtime key", Progression.is_runtime_trade_key("wayfinding"))
	_check("legacy carto is not a runtime key", not Progression.is_runtime_trade_key("carto"))
	_check("migration reads carto alias",
		Progression.canonical_trade_key_for_migration("carto") == "wayfinding")
	_check("migration reads cartography alias",
		Progression.canonical_trade_key_for_migration("cartography") == "wayfinding")
	_check("unknown migration key remains invalid",
		Progression.canonical_trade_key_for_migration("alchemy") == "")

func _test_unlock_registry() -> void:
	print("[1–23 unlock registry]")
	var validation := Progression.validate_unlock_registry()
	_check("all four Trade ladders validate", bool(validation.ok), str(validation.errors))
	var cells := 0
	for trade_key in Progression.TRADE_KEYS:
		for level in range(1, 24):
			var unlock := Progression.unlock_for_trade_level(trade_key, level)
			if not unlock.is_empty():
				cells += 1
	_check("all 92 level cells exist", cells == 92, str(cells))
	_check("Huntcraft level 2 names Power Shot",
		String(Progression.unlock_for_trade_level("huntcraft", 2).skill_id) == "PowerShot")
	_check("invalid Trade/level has no unlock",
		Progression.unlock_for_trade_level("carto", 2).is_empty()
		and Progression.unlock_for_trade_level("huntcraft", 24).is_empty())

func _test_trade_migrations() -> void:
	print("[trade migrations]")
	var v1_xp := Progression.xp_for_level(12) + 17
	var from_v1 := Progression.normalize_save_to_v2({
		"version": 1,
		"trades": {"wayfinding": {"xp": v1_xp, "lv": 1}},
	})
	var v1_trades: Dictionary = from_v1.trades
	var cloned := true
	for key in Progression.TRADE_KEYS:
		cloned = cloned and int(v1_trades[key].xp) == v1_xp \
			and int(v1_trades[key].lv) == Progression.level_for_xp(v1_xp)
	_check("v1 Wayfinding XP clones exactly into all four Trades", cloned, str(v1_trades))
	_check("v1 migration emits no aliases", not v1_trades.has("carto")
		and not v1_trades.has("earth") and not v1_trades.has("wilds"))
	var malformed_v1 := Progression.normalize_save_to_v2({
		"version": 1, "trades": {"wayfinding": "not-a-record"},
	})
	_check("malformed v1 Trade record normalizes safely",
		int(malformed_v1.trades.wayfinding.xp) == 0
		and int(malformed_v1.trades.huntcraft.lv) == 1, str(malformed_v1.trades))
	var capped_v1 := Progression.normalize_save_to_v2({
		"version": 1, "trades": {"wayfinding": {"xp": 999999}},
	})
	_check("v1 migration clamps XP beyond the cap",
		int(capped_v1.trades.wildcraft.xp) == Progression.max_xp()
		and int(capped_v1.trades.wildcraft.lv) == 23)

	var from_v0 := Progression.normalize_save_to_v2({
		"version": 0,
		"trades": {
			"carto": {"xp": 50}, "earth": {"xp": 75},
			"wilds": {"xp": 25}, "hunt": {"xp": 10},
		},
	})
	var v0_total := 160
	var collapsed := true
	for key in Progression.TRADE_KEYS:
		collapsed = collapsed and int(from_v0.trades[key].xp) == v0_total
	_check("pre-v1 aliases collapse before cloning", collapsed, str(from_v0.trades))
	var synonyms := Progression.normalize_save_to_v2({
		"version": 0,
		"trades": {"carto": {"xp": 50}, "cartography": {"xp": 90},
			"earth": {"xp": 10}, "wilds": {"xp": 20}, "hunt": {"xp": 30}},
	})
	_check("v0 cartography synonyms use max XP rather than sum",
		int(synonyms.trades.wayfinding.xp) == 150, str(synonyms.trades))
	var malformed_synonym := Progression.normalize_save_to_v2({
		"version": 0,
		"trades": {"carto": "bad", "cartography": {"xp": 90}},
	})
	_check("malformed synonym deterministically preserves the valid furthest record",
		int(malformed_synonym.trades.wayfinding.xp) == 90)

	var v2 := {
		"version": 2,
		"trades": {
			"wayfinding": {"xp": 40}, "earthcraft": {"xp": 96},
			"wildcraft": {"xp": 168}, "huntcraft": {"xp": 256},
			"carto": {"xp": 4576},
		},
	}
	var normalized_v2 := Progression.normalize_save_to_v2(v2)
	_check("v2 keeps independent Wayfinding XP", int(normalized_v2.trades.wayfinding.xp) == 40)
	_check("v2 keeps independent Earthcraft XP", int(normalized_v2.trades.earthcraft.xp) == 96)
	_check("v2 ignores stale aliases", int(normalized_v2.trades.wayfinding.xp) != 4576)
	var twice := Progression.normalize_save_to_v2(normalized_v2)
	_check("migration is idempotent", JSON.stringify(twice) == JSON.stringify(normalized_v2))
	_check("migration ordering is deterministic", JSON.stringify(
		Progression.normalize_save_to_v2(v2)) == JSON.stringify(normalized_v2))
	_check("future save versions are unsupported", not Progression.supports_save_version(3))
	_check("future save is never downgraded or rewritten",
		Progression.normalize_save_to_v2({"version": 3, "future": true}).is_empty())

func _test_skill_ownership_migration() -> void:
	print("[Skill ownership]")
	var fresh := Progression.normalize_save_to_v2({"version": 2, "trades": {}})
	_check("fresh save owns no Focus Skills", (fresh.owned_skills as Array).is_empty(),
		str(fresh.owned_skills))
	_check("fresh save has no configurable loadout", (fresh.loadout as Array).is_empty(),
		str(fresh.loadout))
	_check("Basic Shot is innate not configurable",
		bool(Progression.skill_metadata("BasicShot").innate)
		and not bool(Progression.skill_metadata("BasicShot").configurable))

	var legacy := Progression.normalize_save_to_v2({
		"version": 1,
		"trades": {"wayfinding": {"xp": 0}},
		"loadout": ["Power Shot", "Galecall", "NoSuchSkill", "MultiShot"],
	})
	_check("valid legacy Skills become owned in order",
		legacy.owned_skills == ["PowerShot", "MultiShot"], str(legacy.owned_skills))
	_check("valid legacy Skills remain equipped in order",
		legacy.loadout == ["PowerShot", "MultiShot"], str(legacy.loadout))
	_check("gear-only and unknown Skills do not become permanent",
		not legacy.owned_skills.has("Galecall") and not legacy.owned_skills.has("NoSuchSkill"))
	var partial_v2 := Progression.normalize_save_to_v2({
		"version": 2,
		"owned_skills": ["PowerShot"],
		"loadout": ["PowerShot", "MultiShot"],
		"trades": {},
	})
	_check("v2 loadout filters to persisted ownership",
		partial_v2.owned_skills == ["PowerShot"]
		and partial_v2.loadout == ["PowerShot"])
	var forged_v2 := Progression.normalize_save_to_v2({
		"version": 2, "owned_skills": [], "loadout": ["MercyShot"], "trades": {},
	})
	_check("v2 loadout cannot grant unowned Skills",
		forged_v2.owned_skills.is_empty() and forged_v2.loadout.is_empty(), str(forged_v2))
	var late_v2 := Progression.normalize_save_to_v2({
		"version": 2, "trades": {},
		"owned_skills": ["DrivingVolley", "Threadstep", "WayfindersMark"],
		"loadout": ["DrivingVolley", "Threadstep", "WayfindersMark"],
	})
	_check("all three authored late Skills persist in canonical order",
		late_v2.owned_skills == ["DrivingVolley", "Threadstep", "WayfindersMark"]
		and late_v2.loadout == ["DrivingVolley", "Threadstep", "WayfindersMark"],
		str(late_v2))
	_check("Fire Skills and Wayfinder's Mark are configurable",
		Progression.is_focus_skill("DrivingVolley")
			and bool(Progression.skill_metadata("DrivingVolley").configurable)
			and Progression.is_focus_skill("Threadstep")
			and bool(Progression.skill_metadata("Threadstep").configurable)
			and Progression.is_focus_skill("WayfindersMark")
			and bool(Progression.skill_metadata("WayfindersMark").configurable))

	var tutorial := Progression.normalize_save_to_v2({
		"version": 1, "tutorial_step": 6,
		"trades": {"wayfinding": {"xp": 0}},
		"loadout": ["Galecall"],
	})
	_check("Power Shot is preserved for the reached tutorial lesson",
		tutorial.owned_skills == ["PowerShot"] and tutorial.loadout == ["PowerShot"],
		str(tutorial))
	var full_tutorial := Progression.normalize_save_to_v2({
		"version": 1, "tutorial_step": 6,
		"trades": {"wayfinding": {"xp": 0}},
		"loadout": ["MultiShot", "BrambleSnare", "MercyShot"],
	})
	_check("tutorial repair keeps a three-Skill loadout",
		full_tutorial.loadout == ["MultiShot", "BrambleSnare", "PowerShot"],
		str(full_tutorial.loadout))
