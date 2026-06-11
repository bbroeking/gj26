class_name GatherData
extends RefCounted

# Wyrd slice — material defs + gather-node defs. Materials are stackable
# reagents living in the Game.materials satchel (keyed id -> count), NOT
# the Tetris inventory (which has no stacking and is for gear).

# Material id -> display data. `group` follows the three.js taxonomy
# (verdant / earthen / lumen / gristle / echo) — flavor, not mechanics.
const MATERIALS := {
	"wild_herb":     {"name": "Wild Herb",     "icon": "❀", "group": "verdant",
		"desc": "Hedge-row green. Three crush down into a pot of hedge ink."},
	"copper_ore":    {"name": "Copper Ore",    "icon": "▲", "group": "earthen",
		"desc": "Soft entry-tier ore. Two lumps smelt to a copper bar."},
	"bogiron_ore":   {"name": "Bogiron Ore",   "icon": "▲", "group": "earthen",
		"desc": "Rust-heavy lumps. Needs Earthcraft 3 to win from the vein."},
	"palechalk":     {"name": "Palechalk",     "icon": "▲", "group": "earthen",
		"desc": "Bone-white and dense — only the deeper charts carry it. Cinderbloom tools start here."},
	"copper_bar":    {"name": "Copper Bar",    "icon": "▬", "group": "earthen",
		"desc": "Two copper lumps smelted clean. Rings start here."},
	"logs":          {"name": "Logs",          "icon": "▤", "group": "verdant",
		"desc": "Split and stacked. Wood Grove charts grow them thick."},
	"thorn_essence": {"name": "Thorn Essence", "icon": "✶", "group": "echo",
		"desc": "A bead of bramble-light from the fiercer things. Slot it at the table to ink the Hedgemother's Den."},
	"tusker_tusk": {"name": "Tusker Tusk", "icon": "◣", "group": "gristle",
		"desc": "A boar tusk the Hedgemother kept as a trophy. Fresh enough to bait the Wallow."},
	"wightpelt": {"name": "Wightpelt", "icon": "♒", "group": "gristle",
		"desc": "A wight-pelt snagged on the great boar's tusks. The pack will come looking for it."},
	"alpha_fang": {"name": "Alpha's Fang", "icon": "▼", "group": "echo",
		"desc": "The pack-leader's fang. The Summit's lock has exactly one key."},
	"bogiron_bar":   {"name": "Bogiron Bar",   "icon": "▬", "group": "earthen",
		"desc": "Two lumps smelted clean at the forge. Gear starts here."},
	"hearth_draught": {"name": "Hearth Draught", "icon": "♨", "group": "verdant",
		"desc": "Herbs and woodsmoke in a bottle. Quaff with Q for 35 vigor."},
	"deep_draught":  {"name": "Deep Draught",  "icon": "♨", "group": "verdant",
		"desc": "The strong batch. Quaff with Q for 80 vigor."},
	"hedge_ink":     {"name": "Hedge Ink",     "icon": "●", "group": "verdant",
		"desc": "The everyday charting ink. Mixed from wild herbs."},
	"stoneground_ink": {"name": "Stoneground Ink", "icon": "◆", "group": "earthen",
		"desc": "Gritty, heavy ink. Pulls charts toward the mineral seams."},
	"refined_ink":   {"name": "Refined Ink",   "icon": "✦", "group": "lumen",
		"desc": "Clarified, steady. Each pot slotted firms up the good twin."},
}

# Ink-mixing recipes available at the Inscribing Table (slice-simplified —
# no mortar/grindstone stations yet).
const INK_RECIPES := {
	"hedge_ink":       {"inputs": {"wild_herb": 3},                 "yields": 1},
	"stoneground_ink": {"inputs": {"bogiron_ore": 2},               "yields": 1},
	"refined_ink":     {"inputs": {"hedge_ink": 2, "bogiron_ore": 1}, "yields": 1},
}
const INK_RECIPE_ORDER := ["hedge_ink", "stoneground_ink", "refined_ink"]

# Gather-node kinds. Mirrors the three.js dungeon decor kinds
# (ore_rock / forage_node / log_pile) plus their verb, trade, and XP.
const NODE_KINDS := {
	"ore_rock": {
		"verb": "Mine", "trade": "earth", "xp": 10, "channel_sec": 1.6,
		"color": Color(0.55, 0.42, 0.30), "shape": "rock",
		"log": "You chip out a %s.",
	},
	"forage_node": {
		"verb": "Forage", "trade": "wilds", "xp": 8, "channel_sec": 1.0,
		"color": Color(0.45, 0.62, 0.34), "shape": "bush",
		"log": "You gather a %s.",
	},
	"log_pile": {
		"verb": "Chop", "trade": "wilds", "xp": 12, "channel_sec": 1.3,
		"color": Color(0.48, 0.34, 0.22), "shape": "pile",
		"log": "You split a %s from the pile.",
	},
}

# A6 — ore vein tiers: higher Earthcraft opens richer veins. A locked
# vein is visible and names its level (coveted, not hidden). Channel/xp
# override the ore_rock kind defaults; tools and perks still multiply.
const ORE_TIERS := {
	"copper": {"item": "copper_ore", "req_lv": 1, "xp": 6,
		"channel_sec": 1.2, "name": "Copper Vein",
		"color": Color(0.72, 0.45, 0.25)},
	"bogiron": {"item": "bogiron_ore", "req_lv": 3, "xp": 12,
		"channel_sec": 1.6, "name": "Bogiron Vein",
		"color": Color(0.55, 0.42, 0.30)},
	"palechalk": {"item": "palechalk", "req_lv": 7, "xp": 20,
		"channel_sec": 2.0, "name": "Palechalk Vein",
		"color": Color(0.84, 0.81, 0.72)},
}

static func material_name(id: String) -> String:
	return String(MATERIALS.get(id, {}).get("name", id))

static func material_icon(id: String) -> String:
	return String(MATERIALS.get(id, {}).get("icon", "·"))

static func is_ink(id: String) -> bool:
	return INK_RECIPES.has(id) or id == "hedge_ink"
