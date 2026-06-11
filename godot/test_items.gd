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
	var all: Array = Items.kind_ids()
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
