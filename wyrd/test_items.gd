extends SceneTree

# Spec 27a — item / affix / drop distribution evals. Pure data, no scene.
#   godot --headless --path godot --script res://test_items.gd

const Items = preload("res://data/items.gd")
const Affixes = preload("res://data/affixes.gd")
const Drops = preload("res://data/drops.gd")

var _pass := 0
var _fail := 0

func _initialize() -> void:
	print("--- spec 27a item evals ---")
	_check_magic_has_1_affix()
	_check_rare_has_3_affixes()
	_check_unique_returns_predefined()
	_check_all_kinds_reachable()
	_check_boss_always_rare_plus()
	_check_distribution_sensible()
	_check_affix_format()
	# Task 2 — rare composed names.
	_check_rare_suffix_compose()
	# Task 8 — 6 new uniques.
	_check_new_uniques()
	# Task 9 — new affix pool entries + format_affix for gather_speed / hp_regen.
	_check_new_affix_formats()
	print("--- items evals: %d PASS, %d FAIL ---" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)

func _check(id: String, ok: bool, detail: String) -> void:
	if ok:
		_pass += 1
		print("  PASS  %s — %s" % [id, detail])
	else:
		_fail += 1
		print("  FAIL  %s — %s" % [id, detail])

func _check_magic_has_1_affix() -> void:
	var it := Items.make_item("shortbow", "magic")
	_check("I1", it.affixes.size() == 1,
		"magic shortbow has %d affix" % it.affixes.size())

func _check_rare_has_3_affixes() -> void:
	var it := Items.make_item("shortbow", "rare")
	_check("I2", it.affixes.size() == 3,
		"rare shortbow has %d affixes" % it.affixes.size())

func _check_unique_returns_predefined() -> void:
	var it := Items.make_item("shortbow", "unique")
	_check("I3", String(it.name) == "Whispering Yew",
		"unique shortbow name = %s" % it.name)

func _check_all_kinds_reachable() -> void:
	var seen := {}
	for _i in 400:
		var d := Drops.roll_drop("combat", 4)
		for it in d:
			seen[it.kind_id] = true
	var all: Array = Drops.droppable_kinds()   # craft-only tools never roll (Spec 38/E17)
	var missing := []
	for k in all:
		if not seen.has(k):
			missing.append(k)
	_check("I4", missing.is_empty(),
		"all %d kinds rolled at least once (missing: %s)" % [all.size(), str(missing)])

func _check_boss_always_rare_plus() -> void:
	var ok := true
	for _i in 60:
		var d := Drops.roll_drop("boss", 0)
		for it in d:
			if String(it.rarity) != "rare" and String(it.rarity) != "unique":
				ok = false
				break
		if not ok:
			break
	_check("I5", ok, "boss drops are all rare+")

func _check_distribution_sensible() -> void:
	var counts := {"normal": 0, "magic": 0, "rare": 0, "unique": 0}
	var n := 0
	for _i in 1000:
		var d := Drops.roll_drop("combat", 0)
		for it in d:
			counts[String(it.rarity)] += 1
			n += 1
	# Combat-tier distribution: normal dominates, magic next, rare+unique rare.
	var ok: bool = n > 0 \
		and int(counts.normal) > int(counts.magic) \
		and int(counts.magic) > int(counts.rare) + int(counts.unique)
	_check("I6", ok, "rarity dist over %d drops: %s" % [n, str(counts)])

func _check_affix_format() -> void:
	var aff := {"stat": "hp", "value": 12.0,
		"side": "suffix", "display": "of Health", "id": "of_health"}
	var line := Affixes.format_affix(aff)
	_check("I7", line == "+12 Maximum Health",
		"format_affix(hp +12) = '%s'" % line)

# ── Task 2 — rare items get a composed suffix name ──────────────────────────
func _check_rare_suffix_compose() -> void:
	# Force a rare shortbow; roll_affixes is random — run 50 times to guarantee
	# we see at least one suffix affix (rare always gets ≥1 suffix).
	var composed := false
	var example_name := ""
	for _i in 50:
		var it := Items.make_item("shortbow", "rare")
		# Check compose_name logic directly: find first suffix affix and verify.
		var has_suffix := false
		var suffix_display := ""
		for a in it.affixes:
			if String(a.side) == "suffix":
				has_suffix = true
				suffix_display = String(a.display)
				break
		if has_suffix:
			var expected := "Shortbow " + suffix_display
			example_name = String(it.name)
			if String(it.name) == expected:
				composed = true
				break
	_check("R1", composed,
		"rare shortbow composes suffix name (last example='%s')" % example_name)

# ── Task 8 — 6 new uniques ───────────────────────────────────────────────────
func _check_new_uniques() -> void:
	const EXPECTED := {
		"longbow":        {"name": "Thornwood Longbow",      "n_affixes": 2},
		"leather_chest":  {"name": "Bramble Jerkin",         "n_affixes": 2},
		"leather_boots":  {"name": "Mudwarden Boots",        "n_affixes": 2},
		"copper_ring":    {"name": "Glintband of the Fox",   "n_affixes": 2},
		"starsilver_band":{"name": "Wyrdstar Signet",        "n_affixes": 2},
		"warbow":         {"name": "Hedgesteel Sovereign",   "n_affixes": 3},
	}
	for kind_id in EXPECTED.keys():
		var exp: Dictionary = EXPECTED[kind_id]
		var it := Items.make_item(kind_id, "unique")
		var id_label := "U_%s" % kind_id
		_check(id_label + "_rarity", String(it.rarity) == "unique",
			"%s rarity = '%s'" % [kind_id, it.rarity])
		_check(id_label + "_name", String(it.name) == String(exp.name),
			"%s name = '%s' (want '%s')" % [kind_id, it.name, exp.name])
		_check(id_label + "_name_ne_kind", String(it.name) != String(it.kind_name),
			"%s name != kind_name" % kind_id)
		_check(id_label + "_affixes", it.affixes.size() == int(exp.n_affixes),
			"%s affix count = %d (want %d)" % [kind_id, it.affixes.size(), exp.n_affixes])

# ── Task 9 — new format_affix stat keys ─────────────────────────────────────
func _check_new_affix_formats() -> void:
	var gs_aff := {"stat": "gather_speed", "value": 0.15,
		"side": "prefix", "display": "Honed", "id": "honed"}
	var gs_line := Affixes.format_affix(gs_aff)
	_check("A1", gs_line != "" and gs_line != "+0.15 gather_speed",
		"format_affix(gather_speed 0.15) = '%s'" % gs_line)
	# 0.15 * 100 = 15 → "+15% Gather Speed"
	_check("A1b", gs_line == "+15% Gather Speed",
		"gather_speed exact: '%s'" % gs_line)

	var hr_aff := {"stat": "hp_regen", "value": 2.0,
		"side": "prefix", "display": "Vigorous", "id": "vigorous"}
	var hr_line := Affixes.format_affix(hr_aff)
	_check("A2", hr_line != "" and hr_line != "+2.0 hp_regen",
		"format_affix(hp_regen 2.0) = '%s'" % hr_line)
	_check("A2b", hr_line == "+2 HP per Second",
		"hp_regen exact: '%s'" % hr_line)

	# Verify honed and vigorous are present in PREFIXES pool.
	_check("A3", Affixes.PREFIXES.has("honed"),
		"PREFIXES contains 'honed'")
	_check("A4", Affixes.PREFIXES.has("vigorous"),
		"PREFIXES contains 'vigorous'")
	_check("A5", Affixes.SUFFIXES.has("of_the_bramble"),
		"SUFFIXES contains 'of_the_bramble'")
	_check("A6", Affixes.SUFFIXES.has("of_swiftness_ii"),
		"SUFFIXES contains 'of_swiftness_ii'")
