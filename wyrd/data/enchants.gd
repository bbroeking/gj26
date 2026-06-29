class_name EnchantData
extends RefCounted

# Enchant catalogue — the "skills on items" layer. An enchant is a virtue
# BOUND into a piece of gear at the Charm Table (swappable, reagent-cost per
# bind; ADR-style: gear keeps its rolled affixes, enchants live in a SEPARATE
# `enchants` array on the item so the affix covenant — immutable on roll —
# stays intact).
#
# Three kinds, mapped onto the existing engine hooks:
#   stat        → sums into player._derive_stats() exactly like an affix.
#   on_hit      → adds a SkillEffect to EVERY shot the bow looses (reinforces
#                 combat-as-one-verb; weapon-only). Stacks across slots.
#   skill_grant → makes a new hotbar skill slottable in 2-4 while the weapon
#                 is worn (Game.granted_skills / available_skills); the skill
#                 class is registered in player_controller.SKILL_FACTORY.
#
# Tiers gate the SOURCE, not the slot:
#   common → always bindable (pay reagents).
#   rare   → must be DISCOVERED first (drops from elites/bosses), then bindable.
#   unique → boss-only discovery.
# Slot capacity per gear kind lives on items.gd KINDS.enchant_slots.

# Stat keys must already exist in player._derive_stats sums (no new stat
# without a consumer): hp · damage · crit_chance · crit_mult · fire_rate ·
# move_speed · cooldown_reduction · hp_regen · bonus_pierce · gather_speed.
const ENCHANTS := {
	# ---- common · on-hit (weapon) — shape your shot ----
	"emberbind": {
		"name": "Emberbind", "tier": "common", "kind": "on_hit",
		"slots": ["weapon"], "cost": {"emberglass": 2},
		"effect": {"status": "burn", "dur": 2.0, "dpt": 1, "interval": 0.6},
		"color": Color(0.86, 0.42, 0.20),
		"desc": "A coal of bottled summer. Every arrow leaves a small fire behind it.",
	},
	"thornweave": {
		"name": "Thornweave", "tier": "common", "kind": "on_hit",
		"slots": ["weapon"], "cost": {"dewthread": 2},
		"effect": {"status": "bleed", "dur": 2.5, "dpt": 1, "interval": 0.7},
		"color": Color(0.70, 0.22, 0.30),
		"desc": "Barbed thread wound up the stave. What it nicks keeps bleeding.",
	},
	"snarethread": {
		"name": "Snarethread", "tier": "common", "kind": "on_hit",
		"slots": ["weapon"], "cost": {"dewthread": 1, "glimmerdust": 1},
		"effect": {"status": "snared", "dur": 1.0, "slow": 0.7},
		"color": Color(0.40, 0.62, 0.46),
		"desc": "Bramble-string that snags the struck thing's feet for a beat.",
	},
	# ---- common · stat ----
	"keening": {
		"name": "Keening", "tier": "common", "kind": "stat",
		"slots": ["weapon", "ring"], "cost": {"glimmerdust": 2},
		"stat": "crit_chance", "value": 0.06,
		"color": Color(0.88, 0.78, 0.42),
		"desc": "A whetted edge of intent. Your tellings land true more often.",
	},
	"heartoak": {
		"name": "Heartoak", "tier": "common", "kind": "stat",
		"slots": ["helmet", "chest", "boots"], "cost": {"dewthread": 2},
		"stat": "hp", "value": 12,
		"color": Color(0.52, 0.66, 0.40),
		"desc": "Oak-heart sewn into the lining. You carry a little more weather.",
	},
	"swiftsole": {
		"name": "Swiftsole", "tier": "common", "kind": "stat",
		"slots": ["boots", "ring"], "cost": {"glimmerdust": 1, "dewthread": 1},
		"stat": "move_speed", "value": 0.08,
		"color": Color(0.46, 0.70, 0.78),
		"desc": "Feathergrass underfoot. The road runs a touch shorter.",
	},
	"quicknock": {
		"name": "Quicknock", "tier": "common", "kind": "stat",
		"slots": ["weapon", "ring"], "cost": {"glimmerdust": 2},
		"stat": "cooldown_reduction", "value": 0.08,
		"color": Color(0.62, 0.58, 0.84),
		"desc": "A reading-charm for the fingers. Your skills come back sooner.",
	},
	# ---- rare · discovered from elites ----
	"deepmark": {
		"name": "Deepmark", "tier": "rare", "kind": "on_hit",
		"slots": ["weapon"], "cost": {"emberglass": 3, "glimmerdust": 1},
		"effect": {"status": "marked", "dur": 3.0},
		"color": Color(0.92, 0.66, 0.24),
		"desc": "Names the quarry as it strikes. The marked thing takes more from everything that follows.",
	},
	"farsight": {
		"name": "Farsight", "tier": "rare", "kind": "stat",
		"slots": ["weapon", "ring"], "cost": {"glimmerdust": 3},
		"stat": "bonus_pierce", "value": 1,
		"color": Color(0.80, 0.86, 0.92),
		"desc": "The arrow remembers it once flew straight through a thing. It will again.",
	},
	"steadyheart": {
		"name": "Steadyheart", "tier": "rare", "kind": "stat",
		"slots": ["helmet", "chest", "boots"], "cost": {"dewthread": 3},
		"stat": "hp_regen", "value": 2.0,
		"color": Color(0.58, 0.74, 0.52),
		"desc": "A slow green pulse against the skin. Scratches close as you walk.",
	},
	"galebrand": {
		"name": "Galebrand", "tier": "rare", "kind": "skill_grant",
		"slots": ["weapon"], "cost": {"emberglass": 3, "glimmerdust": 2},
		"grant": "Galecall",
		"color": Color(0.50, 0.80, 0.86),
		"desc": "Binds a gale into the stave — loose a fan of five quick arrows that snare where they land. (Grants Galecall.)",
	},
	# ---- unique · boss-only ----
	"wyrdspark": {
		"name": "Wyrdspark", "tier": "unique", "kind": "skill_grant",
		"slots": ["weapon"], "cost": {"glimmerdust": 4, "emberglass": 2},
		"grant": "Wyrdvolley",
		"color": Color(0.74, 0.62, 0.96),
		"desc": "A splinter of the Summit's own light. Looses a burning bolt that punches through a whole rank. (Grants Wyrdvolley.)",
	},
	"summitfrost": {
		"name": "Summitfrost", "tier": "unique", "kind": "on_hit",
		"slots": ["weapon"], "cost": {"glimmerdust": 3, "dewthread": 2},
		"effect": {"status": "burn", "dur": 3.0, "dpt": 2, "interval": 0.5},
		"color": Color(0.66, 0.84, 1.00),
		"desc": "Cold that burns. Every arrow carries a bite of the high white places.",
	},
}

# UI display order (common → rare → unique, grouped by kind within tier).
const ENCHANT_ORDER := [
	"emberbind", "thornweave", "snarethread",
	"keening", "heartoak", "swiftsole", "quicknock",
	"deepmark", "farsight", "steadyheart", "galebrand",
	"wyrdspark", "summitfrost",
]

# Tier accent colours for the Charm Table list rows (mirror rarity language).
const TIER_COLOR := {
	"common": Color(0.74, 0.72, 0.58),
	"rare":   Color(0.36, 0.52, 0.78),
	"unique": Color(0.72, 0.46, 0.86),
}

static func get_def(id: String) -> Dictionary:
	return ENCHANTS.get(id, {})

static func exists(id: String) -> bool:
	return ENCHANTS.has(id)

static func display_name(id: String) -> String:
	return String(ENCHANTS.get(id, {}).get("name", id))

static func tier(id: String) -> String:
	return String(ENCHANTS.get(id, {}).get("tier", "common"))

static func kind(id: String) -> String:
	return String(ENCHANTS.get(id, {}).get("kind", "stat"))

static func is_common(id: String) -> bool:
	return tier(id) == "common"

# True if this enchant may be bound onto an item of the given gear category.
static func allowed_for(id: String, category: String) -> bool:
	var e: Dictionary = ENCHANTS.get(id, {})
	if e.is_empty():
		return false
	return (e.get("slots", []) as Array).has(category)

static func cost(id: String) -> Dictionary:
	return (ENCHANTS.get(id, {}).get("cost", {}) as Dictionary)

static func granted_skill(id: String) -> String:
	return String(ENCHANTS.get(id, {}).get("grant", ""))

# One-line tooltip readout. Stat enchants reuse the affix formatter so the
# wording matches the rest of the gear UI; on-hit/grant get bespoke lines.
static func format_enchant(id: String) -> String:
	var e: Dictionary = ENCHANTS.get(id, {})
	if e.is_empty():
		return id
	match String(e.get("kind", "")):
		"stat":
			return _Affixes().format_affix({"stat": e.get("stat", ""), "value": e.get("value", 0)})
		"on_hit":
			var fx: Dictionary = e.get("effect", {})
			match String(fx.get("status", "")):
				"burn":   return "Shots set the struck thing alight (Burn)"
				"bleed":  return "Shots leave a wound that bleeds"
				"snared": return "Shots snag the struck thing's feet (Snare)"
				"marked": return "Shots Mark the quarry — it takes more from every hit"
			return "Shots carry an effect on hit"
		"skill_grant":
			return "Grants the %s skill while worn" % _grant_label(id)
	return String(e.get("name", id))

static func _grant_label(id: String) -> String:
	# Human label for the granted skill name (CamelCase → spaced).
	var g := granted_skill(id)
	var out := ""
	for i in g.length():
		var c := g[i]
		if i > 0 and c == c.to_upper() and c != c.to_lower():
			out += " "
		out += c
	return out

static func _Affixes():
	return load("res://data/affixes.gd")
