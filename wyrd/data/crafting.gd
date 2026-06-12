class_name CraftingData
extends RefCounted

# Wyrd — crafting stations (A7-lite smithing, A8-lite cooking). Each
# station owns a recipe list; recipes are gated by the station's trade
# level and consume satchel materials. A recipe yields either a stackable
# material (back into the satchel) or a gear item (into the Tetris pack).
# Game.craft() is the single mutation point; panels are pure views.

const STATIONS := {
	"cookfire": {
		"title": "The Cottage Hearth",
		"prompt": "Cook at the Cottage Hearth",
		"trade": "wilds",
		"verb": "Cook",
		"recipes": ["hearth_draught", "deep_draught"],
	},
	"forge": {
		"title": "Hod's Anvil",
		"prompt": "Smith at Hod's Anvil",
		"trade": "earth",
		"verb": "Smith",
		"recipes": ["copper_bar", "bogiron_bar", "shortbow_smith",
			"pickaxe_smith", "axe_smith", "longbow_smith",
			"bogiron_cap_smith", "bogiron_boots_smith", "bogiron_jerkin_smith",
			"cinder_pickaxe_smith", "cinder_axe_smith", "bogiron_ring",
			"palechalk_ring_smith", "palechalk_longbow_smith"],
	},
}

# yields_material → satchel stack; yields_item → make_item() into the pack.
const RECIPES := {
	"hearth_draught": {
		"name": "Hearth Draught", "req_lv": 1, "xp": 15,
		"inputs": {"wild_herb": 2, "logs": 1},
		"yields_material": "hearth_draught", "yields_n": 1,
		"desc": "Restores 35 vigor. Quaff with Q.",
	},
	"deep_draught": {
		"name": "Deep Draught", "req_lv": 8, "xp": 35,
		"inputs": {"wild_herb": 4, "logs": 2},
		"yields_material": "deep_draught", "yields_n": 1,
		"desc": "Restores 80 vigor. Quaff with Q.",
	},
	"copper_bar": {
		"name": "Copper Bar", "req_lv": 1, "xp": 8,
		"inputs": {"copper_ore": 2},
		"yields_material": "copper_bar", "yields_n": 1,
		"desc": "The first bar every smith pours.",
	},
	"bogiron_bar": {
		"name": "Bogiron Bar", "req_lv": 1, "xp": 12,
		"inputs": {"bogiron_ore": 2},
		"yields_material": "bogiron_bar", "yields_n": 1,
		"desc": "Smelted clean. Every forge recipe starts here.",
	},
	"pickaxe_smith": {
		"name": "Bogiron Pickaxe", "req_lv": 2, "xp": 18,
		"inputs": {"bogiron_bar": 1, "logs": 1},
		"yields_item": {"kind": "bogiron_pickaxe", "rarity": "normal"},
		"desc": "Mining goes a third faster with iron in your hands.",
	},
	"axe_smith": {
		"name": "Bogiron Axe", "req_lv": 2, "xp": 18,
		"inputs": {"bogiron_bar": 1, "logs": 1},
		"yields_item": {"kind": "bogiron_axe", "rarity": "normal"},
		"desc": "Chopping goes a third faster. Also reassuring to hold.",
	},
	"longbow_smith": {
		"name": "Longbow", "req_lv": 4, "xp": 25,
		"inputs": {"bogiron_bar": 1, "logs": 2},
		"yields_item": {"kind": "longbow", "rarity": "normal"},
		"desc": "Bogiron-backed yew. Hits harder than the shortbow.",
	},
	"bogiron_ring": {
		"name": "Copper Ring", "req_lv": 8, "xp": 40,
		"inputs": {"copper_bar": 2},
		"yields_item": {"kind": "copper_ring", "rarity": "magic"},
		"desc": "A cold band with a keen edge to it. Rolls a magic affix.",
	},
	# A6 — tier-2 tools, gated with the palechalk they're made from.
	"cinder_pickaxe_smith": {
		"name": "Cinderbloom Pickaxe", "req_lv": 7, "xp": 30,
		"inputs": {"palechalk": 2, "bogiron_bar": 1, "logs": 1},
		"yields_item": {"kind": "cinderbloom_pickaxe", "rarity": "normal"},
		"desc": "Palechalk-edged. Mining at nearly half time.",
	},
	"cinder_axe_smith": {
		"name": "Cinderbloom Axe", "req_lv": 7, "xp": 30,
		"inputs": {"palechalk": 2, "bogiron_bar": 1, "logs": 1},
		"yields_item": {"kind": "cinderbloom_axe", "rarity": "normal"},
		"desc": "Palechalk-edged. Chopping at nearly half time.",
	},
	# A7-full — the gear ladder. Selling smithed gear back to Hod always
	# loses gold vs buying the inputs (the economy gate test asserts it);
	# the point of the forge is wearing the work, not flipping it.
	"shortbow_smith": {
		"name": "Shortbow", "req_lv": 1, "xp": 14,
		"inputs": {"copper_bar": 1, "logs": 2},
		"yields_item": {"kind": "shortbow", "rarity": "normal"},
		"desc": "Copper-tipped and honest. Every wayfinder's first bow.",
	},
	"bogiron_cap_smith": {
		"name": "Bogiron Cap", "req_lv": 5, "xp": 28,
		"inputs": {"bogiron_bar": 2, "logs": 1},
		"yields_item": {"kind": "leather_helm", "rarity": "magic"},
		"desc": "Iron-banded leather. Rolls a magic affix.",
	},
	"bogiron_boots_smith": {
		"name": "Bogiron Boots", "req_lv": 5, "xp": 26,
		"inputs": {"bogiron_bar": 2},
		"yields_item": {"kind": "leather_boots", "rarity": "magic"},
		"desc": "Iron-shod soles for the deep hollows. Rolls a magic affix.",
	},
	"bogiron_jerkin_smith": {
		"name": "Bogiron Jerkin", "req_lv": 6, "xp": 34,
		"inputs": {"bogiron_bar": 3, "logs": 1},
		"yields_item": {"kind": "leather_chest", "rarity": "magic"},
		"desc": "Plated where it counts. Rolls a magic affix.",
	},
	"palechalk_ring_smith": {
		"name": "Palechalk Ring", "req_lv": 9, "xp": 50,
		"inputs": {"palechalk": 2, "copper_bar": 1},
		"yields_item": {"kind": "copper_ring", "rarity": "rare"},
		"desc": "Bone-white inlay on copper. Rolls three affixes.",
	},
	"palechalk_longbow_smith": {
		"name": "Palechalk Longbow", "req_lv": 9, "xp": 50,
		"inputs": {"palechalk": 2, "bogiron_bar": 1, "logs": 2},
		"yields_item": {"kind": "longbow", "rarity": "magic"},
		"desc": "Chalk-cured yew, strung tight. Rolls a magic affix.",
	},
}

# Quaffables — heal amounts, checked smallest-first so a scratch doesn't
# drink the good bottle.
const DRAUGHTS := {
	"hearth_draught": 35,
	"deep_draught": 80,
}
const DRAUGHT_ORDER := ["hearth_draught", "deep_draught"]

static func station(id: String) -> Dictionary:
	return STATIONS.get(id, {})

static func recipe(id: String) -> Dictionary:
	return RECIPES.get(id, {})
