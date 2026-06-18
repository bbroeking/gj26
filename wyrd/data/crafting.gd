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
		"recipes": ["hearth_draught", "bitter_draught", "deep_draught",
			"hale_draught", "heartsease_draught"],
	},
	# A8-full — Quill's still: draughts that sharpen, not just feed.
	"still": {
		"title": "Quill's Still",
		"prompt": "Brew at Quill's still",
		"trade": "wilds",
		"verb": "Brew",
		"recipes": ["quickroot_tonic", "clearwater_philter",
			"crowsfoot_cordial", "mothmint_mend", "stonebreak_tonic"],
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
			"palechalk_ring_smith", "palechalk_longbow_smith",
			"palechalk_jerkin_smith", "starsilver_bar",
			"starsilver_pickaxe_smith", "starsilver_axe_smith",
			"starsilver_band_smith", "starsilver_longbow_smith",
			"hedgesteel_bar", "hedgesteel_cap_smith", "hedgesteel_boots_smith",
			"hedgesteel_jerkin_smith", "warbow_smith"],
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
	# Spec 45-wilds — the heal ladder above Deep.
	"bitter_draught": {
		"name": "Bitter Draught", "req_lv": 4, "xp": 22,
		"inputs": {"bittergrass": 2, "wild_herb": 1, "logs": 1},
		"yields_material": "bitter_draught", "yields_n": 1,
		"desc": "Restores 55 vigor. Bitter going down, warm after. Quaff with Q.",
	},
	"hale_draught": {
		"name": "Hale Draught", "req_lv": 11, "xp": 45,
		"inputs": {"mothmint": 2, "wild_herb": 2, "logs": 2},
		"yields_material": "hale_draught", "yields_n": 1,
		"desc": "Restores 140 vigor. Mothmint and woodsmoke — a bottle of even keel. Quaff with Q.",
	},
	"heartsease_draught": {
		"name": "Heartsease Draught", "req_lv": 15, "xp": 60,
		"inputs": {"foxglove_blue": 2, "mothmint": 2, "logs": 2},
		"yields_material": "heartsease_draught", "yields_n": 1,
		"desc": "Restores 220 vigor. Foxglove steadies the heart — in small doses, mind. Quaff with Q.",
	},
	# Spec 45-wilds — Quill's deeper shelf.
	"crowsfoot_cordial": {
		"name": "Crowsfoot Cordial", "req_lv": 9, "xp": 40,
		"inputs": {"crowsfoot": 2, "bittergrass": 1},
		"yields_material": "crowsfoot_cordial", "yields_n": 1,
		"desc": "Your stride runs a tenth quicker for a while. Quaff with Q when hale.",
	},
	"mothmint_mend": {
		"name": "Mothmint Mend", "req_lv": 12, "xp": 50,
		"inputs": {"mothmint": 2, "crowsfoot": 1},
		"yields_material": "mothmint_mend", "yields_n": 1,
		"desc": "Scratches close as you walk, for a while. Quaff with Q when hale.",
	},
	"stonebreak_tonic": {
		"name": "Stonebreak Tonic", "req_lv": 16, "xp": 70,
		"inputs": {"stonebreak": 2, "foxglove_blue": 1},
		"yields_material": "stonebreak_tonic", "yields_n": 1,
		"desc": "Bites land softer for a while. Quaff with Q when hale.",
	},
	# A8-full — Quill's tonics. Materials like the draughts, but Q drinks
	# them only when vigor is full (the hearth shelf keeps priority).
	"quickroot_tonic": {
		"name": "Quickroot Tonic", "req_lv": 3, "xp": 20,
		"inputs": {"wild_herb": 3},
		"yields_material": "quickroot_tonic", "yields_n": 1,
		"desc": "Gathering runs a quarter faster for a while. Quaff with Q when hale.",
	},
	"clearwater_philter": {
		"name": "Clearwater Philter", "req_lv": 6, "xp": 30,
		"inputs": {"wild_herb": 2, "palechalk": 1},
		"yields_material": "clearwater_philter", "yields_n": 1,
		"desc": "Focus pools half again as fast for a while. Quaff with Q when hale.",
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
	# Spec 45-earth — the deep ladder, E10→17. Every gear piece up here
	# rolls rare; every recipe carries an unbuyable deep input (gate-safe).
	"palechalk_jerkin_smith": {
		"name": "Palechalk Jerkin", "req_lv": 10, "xp": 55,
		"inputs": {"palechalk": 3, "bogiron_bar": 2, "logs": 1},
		"yields_item": {"kind": "leather_chest", "rarity": "rare"},
		"desc": "Chalk-plated over oiled leather. Rolls three affixes.",
	},
	"starsilver_bar": {
		"name": "Starsilver Bar", "req_lv": 11, "xp": 35,
		"inputs": {"starsilver_ore": 2},
		"yields_material": "starsilver_bar", "yields_n": 1,
		"desc": "Two lumps poured bright. Keeps a shine the forge can't dull.",
	},
	"starsilver_pickaxe_smith": {
		"name": "Starsilver Pickaxe", "req_lv": 12, "xp": 45,
		"inputs": {"starsilver_bar": 2, "logs": 1},
		"yields_item": {"kind": "starsilver_pickaxe", "rarity": "normal"},
		"desc": "Starsilver-tipped. Mining in less than half the time.",
	},
	"starsilver_axe_smith": {
		"name": "Starsilver Axe", "req_lv": 12, "xp": 45,
		"inputs": {"starsilver_bar": 2, "logs": 1},
		"yields_item": {"kind": "starsilver_axe", "rarity": "normal"},
		"desc": "Starsilver-edged. Chopping in less than half the time.",
	},
	"starsilver_band_smith": {
		"name": "Starsilver Band", "req_lv": 13, "xp": 60,
		"inputs": {"starsilver_bar": 1, "copper_bar": 1},
		"yields_item": {"kind": "starsilver_band", "rarity": "rare"},
		"desc": "A pale band that catches light that isn't there. Rolls three affixes.",
	},
	"starsilver_longbow_smith": {
		"name": "Starsilver Longbow", "req_lv": 14, "xp": 65,
		"inputs": {"starsilver_bar": 2, "logs": 2},
		"yields_item": {"kind": "longbow", "rarity": "rare"},
		"desc": "Starsilver-backed yew, strung with intent. Rolls three affixes.",
	},
	"hedgesteel_bar": {
		"name": "Hedgesteel Bar", "req_lv": 15, "xp": 55,
		"inputs": {"hedgesteel_ore": 2, "logs": 1},
		"yields_material": "hedgesteel_bar", "yields_n": 1,
		"desc": "Smelted slow over good logs. The stubbornest bar this side of the Summit.",
	},
	"hedgesteel_cap_smith": {
		"name": "Hedgesteel Cap", "req_lv": 16, "xp": 75,
		"inputs": {"hedgesteel_bar": 2, "logs": 1},
		"yields_item": {"kind": "leather_helm", "rarity": "rare"},
		"desc": "Hedgesteel-banded, light as a worry you've put down. Rolls three affixes.",
	},
	"hedgesteel_boots_smith": {
		"name": "Hedgesteel Boots", "req_lv": 16, "xp": 70,
		"inputs": {"hedgesteel_bar": 2},
		"yields_item": {"kind": "leather_boots", "rarity": "rare"},
		"desc": "Soled for the deepest hollows. Rolls three affixes.",
	},
	"hedgesteel_jerkin_smith": {
		"name": "Hedgesteel Jerkin", "req_lv": 16, "xp": 80,
		"inputs": {"hedgesteel_bar": 3, "logs": 1},
		"yields_item": {"kind": "leather_chest", "rarity": "rare"},
		"desc": "Hedgesteel scales over oiled leather — the top of the armour ladder. Rolls three affixes.",
	},
	"warbow_smith": {
		"name": "Hedgesteel Warbow", "req_lv": 17, "xp": 100,
		"inputs": {"hedgesteel_bar": 2, "starsilver_bar": 1, "logs": 2},
		"yields_item": {"kind": "warbow", "rarity": "rare"},
		"desc": "The bow Hod won't admit he's proud of. Rolls three affixes.",
	},
}

# Quaffables — heal amounts, checked smallest-first so a scratch doesn't
# drink the good bottle.
const DRAUGHTS := {
	"hearth_draught": 35,
	"bitter_draught": 55,
	"deep_draught": 80,
	"hale_draught": 140,
	"heartsease_draught": 220,
}
const DRAUGHT_ORDER := ["hearth_draught", "bitter_draught", "deep_draught",
	"hale_draught", "heartsease_draught"]

# A8-full — Quill's shelf: timed buffs, quaffed by Q at full vigor.
# Runtime-only (a sip doesn't outlive the session).
const BUFF_DRAUGHTS := {
	"quickroot_tonic": {
		"stat": "gather_speed", "value": 0.25, "duration": 90.0,
		"toast": "Quickroot hums in your arms — gathering runs quicker.",
	},
	"clearwater_philter": {
		"stat": "focus_regen", "value": 0.5, "duration": 90.0,
		"toast": "Clearwater settles the mind — Focus pools faster.",
	},
	# Spec 45-wilds — the deeper shelf.
	"crowsfoot_cordial": {
		"stat": "move_speed", "value": 0.10, "duration": 90.0,
		"toast": "Crowsfoot quickens the step — the road runs shorter.",
	},
	"mothmint_mend": {
		"stat": "vigor_regen", "value": 1.0, "duration": 120.0,
		"toast": "Mothmint settles in — scratches close as you walk.",
	},
	"stonebreak_tonic": {
		"stat": "grit", "value": 0.15, "duration": 90.0,
		"toast": "Stonebreak sits heavy in the blood — the bites land softer.",
	},
}
const BUFF_DRAUGHT_ORDER := ["quickroot_tonic", "clearwater_philter",
	"crowsfoot_cordial", "mothmint_mend", "stonebreak_tonic"]

static func station(id: String) -> Dictionary:
	return STATIONS.get(id, {})

static func recipe(id: String) -> Dictionary:
	return RECIPES.get(id, {})
