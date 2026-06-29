extends RefCounted

# Spec 27a — item kind catalogue + instance maker. Pure data, no nodes.
# Every later subspec (27b-f) consumes the dict shape returned by make_item.

const Affixes = preload("res://data/affixes.gd")

const KINDS := {
	"shortbow": {
		"name": "Shortbow", "category": "weapon",
		"size": Vector2i(2, 4), "base_stat": "damage", "base_value": 6,
		"icon_color": Color(0.55, 0.38, 0.24),
	},
	"longbow": {
		"name": "Longbow", "category": "weapon",
		"size": Vector2i(2, 4), "base_stat": "damage", "base_value": 8,
		"icon_color": Color(0.45, 0.30, 0.20),
	},
	"leather_helm": {
		"name": "Leather Cap", "category": "helmet",
		"size": Vector2i(2, 2), "base_stat": "hp", "base_value": 4,
		"icon_color": Color(0.62, 0.45, 0.32),
	},
	"leather_chest": {
		"name": "Leather Jerkin", "category": "chest",
		"size": Vector2i(2, 3), "base_stat": "hp", "base_value": 10,
		"icon_color": Color(0.55, 0.40, 0.28),
	},
	"leather_boots": {
		"name": "Leather Boots", "category": "boots",
		"size": Vector2i(2, 2), "base_stat": "hp", "base_value": 3,
		"icon_color": Color(0.50, 0.35, 0.25),
	},
	"copper_ring": {
		"name": "Copper Ring", "category": "ring",
		"size": Vector2i(1, 1), "base_stat": "crit_chance", "base_value": 0.04,
		"icon_color": Color(0.85, 0.55, 0.30),
	},
	# Spec 38/A6 — trade tools. Own equip slots (category = slot), never in
	# the combat-stat sums (gather_speed is read by GatherNode).
	"bogiron_pickaxe": {
		"name": "Bogiron Pickaxe", "category": "pickaxe",
		"size": Vector2i(1, 3), "base_stat": "gather_speed", "base_value": 0.30,
		"icon_color": Color(0.45, 0.42, 0.40),
	},
	"bogiron_axe": {
		"name": "Bogiron Axe", "category": "axe",
		"size": Vector2i(1, 3), "base_stat": "gather_speed", "base_value": 0.30,
		"icon_color": Color(0.52, 0.38, 0.26),
	},
	"cinderbloom_pickaxe": {
		"name": "Cinderbloom Pickaxe", "category": "pickaxe",
		"size": Vector2i(1, 3), "base_stat": "gather_speed", "base_value": 0.45,
		"icon_color": Color(0.82, 0.74, 0.62),
	},
	"cinderbloom_axe": {
		"name": "Cinderbloom Axe", "category": "axe",
		"size": Vector2i(1, 3), "base_stat": "gather_speed", "base_value": 0.45,
		"icon_color": Color(0.80, 0.70, 0.58),
	},
	# Spec 45-earth — the deep ladder's kinds.
	"starsilver_pickaxe": {
		"name": "Starsilver Pickaxe", "category": "pickaxe",
		"size": Vector2i(1, 3), "base_stat": "gather_speed", "base_value": 0.55,
		"icon_color": Color(0.74, 0.79, 0.90),
	},
	"starsilver_axe": {
		"name": "Starsilver Axe", "category": "axe",
		"size": Vector2i(1, 3), "base_stat": "gather_speed", "base_value": 0.55,
		"icon_color": Color(0.70, 0.76, 0.88),
	},
	"starsilver_band": {
		"name": "Starsilver Band", "category": "ring",
		"size": Vector2i(1, 1), "base_stat": "crit_mult", "base_value": 0.15,
		"icon_color": Color(0.78, 0.82, 0.92),
	},
	"warbow": {
		"name": "Hedgesteel Warbow", "category": "weapon",
		"size": Vector2i(2, 4), "base_stat": "damage", "base_value": 11,
		"icon_color": Color(0.36, 0.46, 0.40),
	},
}

# Predefined uniques (a unique drop of these kinds replaces the kind name +
# rolls a fixed affix set). Kinds without an entry fall back to rare on a
# unique roll — graceful.
const UNIQUES := {
	"shortbow": {
		"name": "Whispering Yew",
		"affixes": [
			{"id": "unique_dmg",      "side": "unique", "display": "Unique Damage",
				"stat": "damage",      "value": 5.0},
			{"id": "unique_crit",     "side": "unique", "display": "Unique Crit",
				"stat": "crit_chance", "value": 0.10},
			{"id": "unique_critmult", "side": "unique", "display": "Unique Crit Mult",
				"stat": "crit_mult",   "value": 0.40},
		],
	},
	"leather_helm": {
		"name": "Coatcap of the Bramble",
		"affixes": [
			{"id": "unique_hp",   "side": "unique", "display": "Unique HP",
				"stat": "hp",         "value": 20.0},
			{"id": "unique_move", "side": "unique", "display": "Unique Move",
				"stat": "move_speed", "value": 0.10},
		],
	},
	# Phase 4 — 6 new uniques (impl-system-items-affixes task 8).
	"longbow": {
		"name": "Thornwood Longbow",
		"affixes": [
			{"id": "unique_dmg",  "side": "unique", "display": "Unique Damage",
				"stat": "damage",    "value": 7.0},
			{"id": "unique_fire", "side": "unique", "display": "Unique Speed",
				"stat": "fire_rate", "value": 0.12},
		],
	},
	"leather_chest": {
		"name": "Bramble Jerkin",
		"affixes": [
			{"id": "unique_hp",   "side": "unique", "display": "Unique HP",
				"stat": "hp",         "value": 18.0},
			{"id": "unique_move", "side": "unique", "display": "Unique Move",
				"stat": "move_speed", "value": 0.08},
		],
	},
	"leather_boots": {
		"name": "Mudwarden Boots",
		"affixes": [
			{"id": "unique_speed", "side": "unique", "display": "Unique Speed",
				"stat": "move_speed",         "value": 0.15},
			{"id": "unique_cdr",   "side": "unique", "display": "Unique CDR",
				"stat": "cooldown_reduction", "value": 0.10},
		],
	},
	"copper_ring": {
		"name": "Glintband of the Fox",
		"affixes": [
			{"id": "unique_crit",     "side": "unique", "display": "Unique Crit",
				"stat": "crit_chance", "value": 0.08},
			{"id": "unique_critmult", "side": "unique", "display": "Unique Mult",
				"stat": "crit_mult",   "value": 0.25},
		],
	},
	"starsilver_band": {
		"name": "Wyrdstar Signet",
		"affixes": [
			{"id": "unique_critmult", "side": "unique", "display": "Unique Mult",
				"stat": "crit_mult", "value": 0.45},
			{"id": "unique_hp",      "side": "unique", "display": "Unique HP",
				"stat": "hp",        "value": 12.0},
		],
	},
	"warbow": {
		"name": "Hedgesteel Sovereign",
		"affixes": [
			{"id": "unique_dmg",  "side": "unique", "display": "Unique Damage",
				"stat": "damage",      "value": 9.0},
			{"id": "unique_fire", "side": "unique", "display": "Unique Speed",
				"stat": "fire_rate",   "value": 0.08},
			{"id": "unique_crit", "side": "unique", "display": "Unique Crit",
				"stat": "crit_chance", "value": 0.06},
		],
	},
}

# Rarity → affix count. -1 = predefined (read from UNIQUES).
const N_AFFIXES := {"normal": 0, "magic": 1, "rare": 3, "unique": -1}

# Enchant slot capacity by gear category (the "skills on items" layer; see
# data/enchants.gd). Capacity is orthogonal to rarity — every item of a
# category shares the same count. Weapons get two so a bow can carry an
# on-hit charm AND a skill-granting one; tools take none (combat-stat
# enchants would do nothing on a pickaxe).
const ENCHANT_SLOTS_BY_CATEGORY := {
	"weapon": 2, "helmet": 1, "chest": 1, "boots": 1, "ring": 1,
	"pickaxe": 0, "axe": 0,
}

static func kind_ids() -> Array:
	return KINDS.keys()

# How many enchants a piece of this kind can hold. Read by category so it
# works for items already sitting in old saves (capacity isn't stored on the
# item dict — it's a property of the kind).
static func enchant_slots(kind_id: String) -> int:
	var cat := String(KINDS.get(kind_id, {}).get("category", ""))
	return int(ENCHANT_SLOTS_BY_CATEGORY.get(cat, 0))

# Build a concrete item instance for the given kind + rarity. Returns an
# empty dict for an unknown kind (graceful — the caller logs and skips).
static func make_item(kind_id: String, rarity: String) -> Dictionary:
	if not KINDS.has(kind_id):
		push_warning("items: unknown kind %s" % kind_id)
		return {}
	var kind: Dictionary = KINDS[kind_id]
	var item := {
		"kind_id": kind_id,
		"kind_name": String(kind.name),
		"category": String(kind.category),
		"size": kind.size,
		"base_stat": String(kind.base_stat),
		"base_value": kind.base_value,
		"rarity": rarity,
		"affixes": [],
		# Skills-on-items layer: bound at the Charm Table, swappable, separate
		# from the (immutable) rolled affixes. Empty at creation; capacity is
		# enchant_slots(kind_id). Old-save items without the field read as [].
		"enchants": [],
		"icon_color": kind.icon_color,
		"name": String(kind.name),
	}
	if rarity == "unique":
		if UNIQUES.has(kind_id):
			item.affixes = (UNIQUES[kind_id].affixes as Array).duplicate(true)
			item.name = String(UNIQUES[kind_id].name)
		else:
			# Graceful fallback — no unique for this kind, treat as rare.
			item.rarity = "rare"
			item.affixes = Affixes.roll_affixes(3, "rare")
			item.name = Affixes.compose_name(kind.name, item.affixes, "rare")
	elif rarity == "magic" or rarity == "rare":
		var n: int = N_AFFIXES.get(rarity, 0)
		item.affixes = Affixes.roll_affixes(n, rarity)
		item.name = Affixes.compose_name(kind.name, item.affixes, rarity)
	return item
