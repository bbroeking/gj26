extends RefCounted

# Spec 27a — affix pool + roll/compose helpers. Pure static data.
# Stat keys: hp · damage · crit_chance · crit_mult · fire_rate · move_speed.

const PREFIXES := {
	"sharp":     {"display": "Sharp",     "stat": "damage",      "value_range": Vector2(1, 3)},
	"heavy":     {"display": "Heavy",     "stat": "damage",      "value_range": Vector2(3, 6)},
	"hardened":  {"display": "Hardened",  "stat": "hp",          "value_range": Vector2(3, 8)},
	"fortified": {"display": "Fortified", "stat": "hp",          "value_range": Vector2(8, 15)},
	"fierce":    {"display": "Fierce",    "stat": "crit_chance", "value_range": Vector2(0.02, 0.05)},
	"swift":     {"display": "Swift",     "stat": "fire_rate",   "value_range": Vector2(0.02, 0.06)},
}

const SUFFIXES := {
	"of_health":    {"display": "of Health",    "stat": "hp",                 "value_range": Vector2(4, 10)},
	"of_vigor":     {"display": "of Vigor",     "stat": "hp",                 "value_range": Vector2(10, 20)},
	"of_fury":      {"display": "of Fury",      "stat": "damage",             "value_range": Vector2(2, 5)},
	"of_carnage":   {"display": "of Carnage",   "stat": "crit_mult",          "value_range": Vector2(0.10, 0.30)},
	"of_haste":     {"display": "of Haste",     "stat": "move_speed",         "value_range": Vector2(0.05, 0.15)},
	"of_precision": {"display": "of Precision", "stat": "crit_chance",        "value_range": Vector2(0.01, 0.04)},
	# Spec 30 — scales skill 2-4 cooldowns; capped at 0.80 in derived_stats.
	"of_swiftness": {"display": "of Swiftness", "stat": "cooldown_reduction", "value_range": Vector2(0.05, 0.20)},
}

# Roll n affixes for the given rarity.
#  magic (n=1) → 50/50 one prefix OR one suffix.
#  rare  (n=3) → ≥1 prefix + ≥1 suffix, the third side picked at random.
static func roll_affixes(n: int, _rarity: String) -> Array:
	var out: Array = []
	var pref_keys: Array = PREFIXES.keys()
	var suff_keys: Array = SUFFIXES.keys()
	pref_keys.shuffle()
	suff_keys.shuffle()
	var n_pref := 0
	var n_suff := 0
	if n == 1:
		if randf() < 0.5:
			n_pref = 1
		else:
			n_suff = 1
	elif n == 3:
		n_pref = 1
		n_suff = 1
		if randf() < 0.5:
			n_pref += 1
		else:
			n_suff += 1
	else:
		n_pref = n / 2
		n_suff = n - n_pref
	for i in range(mini(n_pref, pref_keys.size())):
		out.append(_make_entry("prefix", pref_keys[i]))
	for i in range(mini(n_suff, suff_keys.size())):
		out.append(_make_entry("suffix", suff_keys[i]))
	return out

static func _make_entry(side: String, key: String) -> Dictionary:
	var pool: Dictionary = PREFIXES if side == "prefix" else SUFFIXES
	var aff: Dictionary = pool[key]
	var lo: float = aff.value_range.x
	var hi: float = aff.value_range.y
	var v := randf_range(lo, hi)
	# Integer stats get rounded; fractional stats snap to 0.01.
	var stat := String(aff.stat)
	if stat == "hp" or stat == "damage":
		v = round(v)
	else:
		v = snappedf(v, 0.01)
	return {
		"id": key,
		"side": side,
		"display": String(aff.display),
		"stat": stat,
		"value": v,
	}

# Compose a display name: magic uses "<Prefix> <Kind> <Suffix>"; rare/unique
# stay as the kind name (rare carries its readout in the tooltip).
static func compose_name(kind_name: String, affixes: Array, rarity: String) -> String:
	if rarity != "magic":
		return kind_name
	var pref := ""
	var suff := ""
	for a in affixes:
		if a.side == "prefix" and pref == "":
			pref = String(a.display) + " "
		elif a.side == "suffix" and suff == "":
			suff = " " + String(a.display)
	return "%s%s%s" % [pref, kind_name, suff]

# One-line tooltip readout for an affix entry.
static func format_affix(a: Dictionary) -> String:
	var v = a.value
	var stat := String(a.stat)
	match stat:
		"hp":                 return "+%d Maximum Health" % int(v)
		"damage":             return "+%d Damage" % int(v)
		"crit_chance":        return "+%d%% Critical Strike Chance" % int(round(float(v) * 100.0))
		"crit_mult":          return "+%d%% Critical Strike Multiplier" % int(round(float(v) * 100.0))
		"fire_rate":          return "+%d%% Attack Speed" % int(round(float(v) * 100.0))
		"move_speed":         return "+%d%% Movement Speed" % int(round(float(v) * 100.0))
		"cooldown_reduction": return "+%d%% Skill Cooldown Reduction" % int(round(float(v) * 100.0))
	return "+%s %s" % [str(v), stat]
