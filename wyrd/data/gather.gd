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
	"quickroot_tonic": {"name": "Quickroot Tonic", "icon": "♨", "group": "verdant",
		"desc": "Quill's brisk brew. Quaff with Q when hale — gathering runs a quarter faster for a while."},
	"clearwater_philter": {"name": "Clearwater Philter", "icon": "♨", "group": "lumen",
		"desc": "Chalk-settled water, clear as a bell. Quaff with Q when hale — Focus pools half again as fast."},
	# Spec 45-wilds — the herb ladder (tiers 2-6, bible's locked list).
	"bittergrass":   {"name": "Bittergrass",   "icon": "❧", "group": "verdant",
		"desc": "Sharp on the tongue, kind after. Quill swears by a bitter start."},
	"crowsfoot":     {"name": "Crowsfoot",     "icon": "⚘", "group": "verdant",
		"desc": "Three-toed leaves from the cracks between stones. Common, once you know where to look."},
	"mothmint":      {"name": "Mothmint",      "icon": "✾", "group": "verdant",
		"desc": "Pale as a moth's wing and blooms at midnight. The fog is fond of it."},
	"foxglove_blue": {"name": "Foxglove-Blue", "icon": "✿", "group": "verdant",
		"desc": "Blue bells with a fierce streak. Steadies the heart — in small doses, mind."},
	"stonebreak":    {"name": "Stonebreak",    "icon": "❁", "group": "verdant",
		"desc": "A root that splits rock, given time. The Summit grows it; almost nowhere else does."},
	# Spec 45-wilds — the heal ladder above Deep.
	"bitter_draught": {"name": "Bitter Draught", "icon": "♨", "group": "verdant",
		"desc": "Bitter going down, warm after. Quaff with Q for 55 vigor."},
	"hale_draught":  {"name": "Hale Draught",  "icon": "♨", "group": "verdant",
		"desc": "Mothmint and woodsmoke — a bottle of even keel. Quaff with Q for 140 vigor."},
	"heartsease_draught": {"name": "Heartsease Draught", "icon": "♨", "group": "verdant",
		"desc": "Foxglove steadies the heart — in small doses, mind. Quaff with Q for 220 vigor."},
	# Spec 45-wilds — Quill's deeper shelf.
	"crowsfoot_cordial": {"name": "Crowsfoot Cordial", "icon": "♨", "group": "verdant",
		"desc": "Quill's road-brew. Quaff with Q when hale — your stride runs a tenth quicker for a while."},
	"mothmint_mend": {"name": "Mothmint Mend", "icon": "♨", "group": "verdant",
		"desc": "Mothmint settled into syrup. Quaff with Q when hale — scratches close as you walk."},
	"stonebreak_tonic": {"name": "Stonebreak Tonic", "icon": "♨", "group": "earthen",
		"desc": "Stone in a bottle, near enough. Quaff with Q when hale — bites land softer for a while."},
	# Spec 45-earth — the deep ores (bible's tier 4/5 metals).
	"starsilver_ore": {"name": "Starsilver Ore", "icon": "▲", "group": "earthen",
		"desc": "Pale lumps flecked like caught starlight. The deep seams hold them close."},
	"starsilver_bar": {"name": "Starsilver Bar", "icon": "▬", "group": "earthen",
		"desc": "Two lumps poured bright. Keeps a shine the forge can't dull."},
	"hedgesteel_ore": {"name": "Hedgesteel Ore", "icon": "▲", "group": "earthen",
		"desc": "Dense as old oak-heart and twice as stubborn. The deepest veins in the Wolds."},
	"hedgesteel_bar": {"name": "Hedgesteel Bar", "icon": "▬", "group": "earthen",
		"desc": "Smelted slow over good logs. Hod calls it honest metal and says no more."},
	"hedge_ink":     {"name": "Hedge Ink",     "icon": "●", "group": "verdant",
		"desc": "The everyday charting ink. Mixed from wild herbs."},
	"stoneground_ink": {"name": "Stoneground Ink", "icon": "◆", "group": "earthen",
		"desc": "Gritty, heavy ink. Pulls charts toward the mineral seams."},
	"refined_ink":   {"name": "Refined Ink",   "icon": "✦", "group": "lumen",
		"desc": "Clarified, steady. Each pot slotted firms up the good twin."},
	"ash_ink":       {"name": "Ash Ink",       "icon": "◉", "group": "verdant",
		"desc": "Char and leaf. Pulls charts toward groves and quick feet."},
	"chalkwash_ink": {"name": "Chalkwash Ink", "icon": "○", "group": "lumen",
		"desc": "Pale and quiet. The deep affixes lean closer to a chalkwashed chart."},
	# Spec 45 — the deeper discoverable inks.
	"mothglow_ink":  {"name": "Mothglow Ink",  "icon": "☽", "group": "lumen",
		"desc": "Moth-pale charting ink. Charts come up quiet — fog and bowstring favor the bearer."},
	"foxglove_ink":  {"name": "Foxglove Ink",  "icon": "❖", "group": "verdant",
		"desc": "Blue-black and faintly fierce. Pulls charts toward the fattened, frenzied, bursting things."},
	"gildleaf_ink":  {"name": "Gildleaf Ink",  "icon": "✧", "group": "lumen",
		"desc": "Ground starlight in a pot. Charts come up golden — chests and festival crowds."},
}

# Ink-mixing recipes available at the bench pot. Spec 43: recipes are
# DISCOVERED by experiment (Game.discovered_inks gates the pot) — only
# hedge ink is known from the start (Mara teaches it in the tutorial).
# `riddle` shows in the bench codex once `hint_key`'s first-time hint has
# been seen; before that the codex line is a bare "???".
const INK_RECIPES := {
	"hedge_ink": {
		"inputs": {"wild_herb": 3}, "yields": 1,
		"hint_key": "forage_node",
		"riddle": "Mara: 'Three of the same green, crushed together.'",
	},
	"stoneground_ink": {
		"inputs": {"bogiron_ore": 2}, "yields": 1,
		"hint_key": "ore_rock",
		"riddle": "Hod: 'Two lumps grind down heavier than ash.'",
	},
	"refined_ink": {
		"inputs": {"hedge_ink": 2, "bogiron_ore": 1}, "yields": 1,
		"hint_key": "bench",
		"riddle": "Mara: 'Two pots of the everyday and a pinch of iron.'",
	},
	"ash_ink": {
		"inputs": {"logs": 2, "wild_herb": 1}, "yields": 1,
		"hint_key": "log_pile",
		"riddle": "Mara: 'Char from split wood, softened with a leaf.'",
	},
	"chalkwash_ink": {
		"inputs": {"palechalk": 1, "wild_herb": 2}, "yields": 1,
		"hint_key": "still",
		"riddle": "Quill: 'Pale chalk settles into herb-water. The deep places listen.'",
	},
	# Spec 45 — the deep-herb and deep-ore inks.
	"mothglow_ink": {
		"inputs": {"mothmint": 2, "hedge_ink": 1}, "yields": 1,
		"hint_key": "still",
		"riddle": "Quill: 'Two midnight blooms stirred into the everyday. The fog keeps your secrets after.'",
	},
	"foxglove_ink": {
		"inputs": {"foxglove_blue": 2, "bogiron_ore": 1}, "yields": 1,
		"hint_key": "forge",
		"riddle": "Hod: 'Two of the blue bells ground with a lump of my iron. Charts come up mean. Mean pays.'",
	},
	"gildleaf_ink": {
		"inputs": {"starsilver_ore": 1, "wild_herb": 2}, "yields": 1,
		"hint_key": "forge",
		"riddle": "Hod: 'A lump of the starry stuff in plain greens. The hollows come up golden after.'",
	},
}
const INK_RECIPE_ORDER := ["hedge_ink", "stoneground_ink", "refined_ink",
	"ash_ink", "chalkwash_ink", "mothglow_ink", "foxglove_ink", "gildleaf_ink"]

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
	# Spec 45-earth — the deep ores (xp/sec +2.5 per tier, channel +0.4s).
	"starsilver": {"item": "starsilver_ore", "req_lv": 11, "xp": 30,
		"channel_sec": 2.4, "name": "Starsilver Vein",
		"color": Color(0.74, 0.79, 0.90)},
	"hedgesteel": {"item": "hedgesteel_ore", "req_lv": 15, "xp": 42,
		"channel_sec": 2.8, "name": "Hedgesteel Vein",
		"color": Color(0.42, 0.52, 0.45)},
}

# Spec 45-wilds — the herb ladder, mirroring ORE_TIERS (gated by Wildcraft;
# +0.3s channel per tier, xp ~×1.4 per tier off the forage base).
const HERB_TIERS := {
	"wild": {"item": "wild_herb", "req_lv": 1, "xp": 8,
		"channel_sec": 1.0, "name": "Wild Herb Patch",
		"color": Color(0.45, 0.62, 0.34)},
	"bittergrass": {"item": "bittergrass", "req_lv": 3, "xp": 12,
		"channel_sec": 1.2, "name": "Bittergrass Patch",
		"color": Color(0.55, 0.58, 0.30)},
	"crowsfoot": {"item": "crowsfoot", "req_lv": 7, "xp": 18,
		"channel_sec": 1.5, "name": "Crowsfoot Patch",
		"color": Color(0.26, 0.38, 0.24)},
	"mothmint": {"item": "mothmint", "req_lv": 10, "xp": 26,
		"channel_sec": 1.8, "name": "Mothmint Patch",
		"color": Color(0.72, 0.80, 0.74)},
	"foxglove": {"item": "foxglove_blue", "req_lv": 13, "xp": 36,
		"channel_sec": 2.1, "name": "Foxglove Patch",
		"color": Color(0.42, 0.50, 0.78)},
	"stonebreak": {"item": "stonebreak", "req_lv": 16, "xp": 48,
		"channel_sec": 2.4, "name": "Stonebreak Patch",
		"color": Color(0.60, 0.58, 0.50)},
}

# Spec 45 — which node tiers roll per chart tier (weights). Mineral Vein
# pulls from ORE_ROLLS, Bramble Bloom / Herbal Patch from FORAGE_ROLLS
# (herbal_patch weights the band's deepest herb up). Tier-3 ore exists for
# future slotted tier-3 charts — the Summit itself rolls no affixes.
const ORE_ROLLS_BY_TIER := {
	1: {"copper": 55, "bogiron": 45},
	2: {"bogiron": 35, "palechalk": 35, "starsilver": 20, "hedgesteel": 10},
	3: {"palechalk": 25, "starsilver": 40, "hedgesteel": 35},
}
const FORAGE_ROLLS_BY_TIER := {
	1: {"wild": 60, "bittergrass": 40},
	2: {"bittergrass": 30, "crowsfoot": 45, "mothmint": 25},
	3: {"mothmint": 35, "foxglove": 40, "stonebreak": 25},
}
const FORAGE_ROLLS_PATCH := {
	1: {"wild": 40, "bittergrass": 60},
	2: {"bittergrass": 20, "crowsfoot": 40, "mothmint": 40},
	3: {"mothmint": 25, "foxglove": 35, "stonebreak": 40},
}

static func material_name(id: String) -> String:
	return String(MATERIALS.get(id, {}).get("name", id))

static func material_icon(id: String) -> String:
	return String(MATERIALS.get(id, {}).get("icon", "·"))

static func is_ink(id: String) -> bool:
	return INK_RECIPES.has(id) or id == "hedge_ink"
