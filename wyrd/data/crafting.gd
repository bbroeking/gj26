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
		"recipes": ["bogiron_bar", "pickaxe_smith", "axe_smith",
			"longbow_smith", "bogiron_ring"],
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
		"name": "Bogiron Ring", "req_lv": 8, "xp": 40,
		"inputs": {"bogiron_bar": 2},
		"yields_item": {"kind": "copper_ring", "rarity": "magic"},
		"desc": "A cold band with a keen edge to it. Rolls a magic affix.",
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
