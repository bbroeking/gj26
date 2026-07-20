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
	# Slice B Chart Table components. These deliberately carry shape metadata
	# instead of font glyphs; the table draws stable sketch silhouettes until
	# painted component icons replace them through ICON_TEX.
	"practice_leaf": {"name": "Practice Leaf", "icon": "", "icon_shape": "leaf",
		"group": "chart_base", "desc": "A small practice page for the kindest road."},
	"field_parchment": {"name": "Field Parchment", "icon": "", "icon_shape": "page",
		"group": "chart_base", "desc": "A broad page with room for a proper hollow."},
	"stitched_parchment": {"name": "Stitched Parchment", "icon": "", "icon_shape": "stitched_page",
		"group": "chart_base", "desc": "A deeper page, stitched to hold more dangerous lines."},
	"waxed_vellum": {"name": "Waxed Vellum", "icon": "", "icon_shape": "waxed_page",
		"group": "chart_base", "desc": "A rain-slick page that keeps a mire road legible."},
	"atlas_folio": {"name": "Atlas Folio", "icon": "", "icon_shape": "folio",
		"group": "chart_base", "desc": "A heavy folio made for the road to the Summit."},
	"hedge_sprig": {"name": "Hedge Sprig", "icon": "", "icon_shape": "sprig",
		"group": "waymark", "desc": "A Bramblewood heading pressed green and true."},
	"thorn_rubbing": {"name": "Thorn Rubbing", "icon": "", "icon_shape": "rubbing",
		"group": "waymark", "desc": "A thorn-road copied from an older Chart."},
	"mire_reed": {"name": "Mire Reed", "icon": "", "icon_shape": "reed",
		"group": "waymark", "desc": "A wet Waymark that points into the Sallow Mire."},
	"cold_track": {"name": "Cold Track", "icon": "", "icon_shape": "track",
		"group": "waymark", "desc": "A pale track taken from the Summit approach."},
	"pale_wellmark": {"name": "Pale Wellmark", "icon": "", "icon_shape": "wellmark",
		"group": "waymark", "desc": "A well's pale sign, pressed into a route folio."},
	"barrow_mark": {"name": "Barrow Mark", "icon": "", "icon_shape": "barrow_mark",
		"group": "waymark", "desc": "A grave-hill mark that names the Jarl's old barrow."},
	"ash_mark": {"name": "Ash Mark", "icon": "", "icon_shape": "ash_mark",
		"group": "waymark", "desc": "A charcoal heading pressed from the lower rootroad."},
	"cinder_waymark": {"name": "Cinder Waymark", "icon": "", "icon_shape": "cinder_waymark",
		"group": "waymark", "desc": "A warm mark that keeps an Ashen Bough road from cooling shut."},
	"ember_mark": {"name": "Ember Mark", "icon": "", "icon_shape": "ember_mark",
		"group": "waymark", "desc": "A small coal-bright sign for a branch that remembers fire."},
	"furnace_mark": {"name": "Furnace Mark", "icon": "", "icon_shape": "furnace_mark",
		"group": "waymark", "desc": "A soot-dark mark naming the Giant's old hearth."},
	"soot_track": {"name": "Soot Track", "icon": "", "icon_shape": "soot_track",
		"group": "waymark", "desc": "A blackened track that points where the fire was banked."},
	"ember_folio": {"name": "Ember Folio", "icon": "", "icon_shape": "ember_folio",
		"group": "chart_base", "desc": "A heat-stiff folio broad enough to hold the Ashen Bough."},
	"nine_knot_leaf": {"name": "Nine-Knot Leaf", "icon": "", "icon_shape": "nine_knot_leaf",
		"group": "chart_base", "desc": "A many-folded leaf made to witness the last unfinished road."},
	"lost_waymark_tracing": {"name": "Lost-Waymark Tracing", "icon": "",
		"icon_shape": "lost_waymark_tracing", "group": "waymark",
		"desc": "A renewable tracing copied from a Lost Waymark without spending the remembered clue."},
	"loop_cord": {"name": "Loop Cord", "icon": "", "icon_shape": "loop",
		"group": "binding", "desc": "A simple loop that gives a road room to wander."},
	"hollow_stitch": {"name": "Hollow Stitch", "icon": "", "icon_shape": "stitch",
		"group": "binding", "desc": "A firm stitch for a deeper Hollow."},
	"briar_knot": {"name": "Briar Knot", "icon": "", "icon_shape": "thorn_knot",
		"group": "binding", "desc": "A snagged knot that twists a road into a maze."},
	"sunk_knot": {"name": "Sunk Knot", "icon": "", "icon_shape": "wet_knot",
		"group": "binding", "desc": "A dark, wet knot for roads under reed and root."},
	"climbing_cord": {"name": "Climbing Cord", "icon": "", "icon_shape": "double_loop",
		"group": "binding", "desc": "A doubled cord that holds the Summit climb."},
	"cinder_binding": {"name": "Cinder Binding", "icon": "", "icon_shape": "cinder_binding",
		"group": "binding", "desc": "A warm binding that holds a branch through falling ash."},
	"threefold_binding": {"name": "Threefold Binding", "icon": "",
		"icon_shape": "threefold_binding", "group": "binding",
		"desc": "Three patient turns that hold a road open without fixing its ending."},
	"thorn_essence": {"name": "Thorn Essence", "icon": "✶", "group": "echo",
		"desc": "A bead of bramble-light from the fiercer things. Slot it at the table to ink the Hedgemother's Den."},
	"tusker_tusk": {"name": "Tusker Tusk", "icon": "◣", "group": "gristle",
		"desc": "A boar tusk the Hedgemother kept as a trophy. Fresh enough to bait the Wallow."},
	"wightpelt": {"name": "Wightpelt", "icon": "♒", "group": "gristle",
		"desc": "A wight-pelt snagged on the great boar's tusks. The pack will come looking for it."},
	"alpha_fang": {"name": "Alpha's Fang", "icon": "▼", "group": "echo",
		"desc": "The pack-leader's fang. The Summit's lock has exactly one key."},
	"oath_nail": {"name": "Oath Nail", "icon": "", "icon_shape": "oath_nail",
		"group": "echo", "desc": "A protected iron nail from the Queen's old promise. It belongs only in the Pale Oath's Seal."},
	"starheart_coal": {"name": "Starheart Coal", "icon": "",
		"group": "echo", "desc": "A coal-black ember split by a living gold star. The Jarl kept it past his oath."},
	"wyrm_scale": {"name": "Wyrm Scale", "icon": "", "group": "echo",
		"desc": "A heat-dark scale banked from the Giant's fire. The Unwritten Road will ask for it."},
	"starheart_alloy": {"name": "Starheart Alloy", "icon": "", "group": "earthen",
		"desc": "Wildgold and emberglass tempered after the Giant's fire is safely banked."},
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
	"wildgold_ore": {"name": "Wildgold Ore", "icon": "", "group": "earthen",
		"desc": "Warm gold threaded through rootstone. The Pale Veins yield it to an Earthcraft hand."},
	"wildgold_bar": {"name": "Wildgold Bar", "icon": "", "group": "earthen",
		"desc": "A bright bar smelted slow from renewable Wildgold."},
	"wellmoss": {"name": "Wellmoss", "icon": "", "group": "verdant",
		"desc": "Soft pale moss gathered where the rootroad wells breathe."},
	"wellmoss_salve": {"name": "Wellmoss Salve", "icon": "", "group": "verdant",
		"desc": "A cool green salve from the well's own moss."},
	"wellwater": {"name": "Wellwater", "icon": "", "group": "lumen",
		"desc": "Clear water drawn from a Pale Well. It belongs to the rootroads, not a campaign toll."},
	"wellwater_philter": {"name": "Wellwater Philter", "icon": "", "group": "lumen",
		"desc": "A measured philter that carries the well's steady cool."},
	"embersage": {"name": "Embersage", "icon": "", "group": "verdant",
		"desc": "A smoke-soft herb that keeps one living coal at the heart of every leaf."},
	"waysteel_shard": {"name": "Waysteel Shard", "icon": "", "group": "earthen",
		"desc": "A blue-grey shard drawn from the oldest rootroad seam."},
	"root_sap": {"name": "Root Sap", "icon": "", "group": "verdant",
		"desc": "Clear, patient sap gathered where the deep roots still remember their roads."},
	# D8 Wayweaver mastery components. These are physical, non-stack-authority
	# inputs for the pure mastery lane; Wayweaver itself is deliberately absent
	# because it is a gear item, never a material.
	"waysteel_core": {"name": "Waysteel Core", "icon": "", "group": "earthen",
		"desc": "Three Waysteel Shards drawn together at Hod's patient fire."},
	"waysteel_frame": {"name": "Waysteel Frame", "icon": "", "group": "earthen",
		"desc": "A dark crescent frame waiting for cord, tooth, and a road to carry."},
	"root_sap_cord": {"name": "Root-Sap Cord", "icon": "", "group": "verdant",
		"desc": "Three patient measures of Root Sap spun into a warm, unbroken cord."},
	"threefold_draught": {"name": "Threefold Draught", "icon": "", "group": "verdant",
		"desc": "A two-measure draught Quill keeps ready for the Loom's deep work."},
	"wayweaver_string": {"name": "Wayweaver String", "icon": "", "group": "echo",
		"desc": "Cord and draught woven awake through the three remembered Threads."},
	"quiet_tooth": {"name": "Quiet Tooth", "icon": "", "group": "echo",
		"desc": "The Knot-Eater's one quiet trophy. Master Hunt knows its proper grip."},
	"quiet_tooth_grip": {"name": "Quiet-Tooth Grip", "icon": "", "group": "echo",
		"desc": "A pale grip shaped once from the Quiet Tooth for the final bow."},
	# Enchant reagents — the makings the Charm Table drinks to bind a virtue
	# into gear (data/enchants.gd). Craftable at the forge/still AND a delving
	# drop (the two faucets, per the mixed-source design).
	"glimmerdust":   {"name": "Glimmerdust",   "icon": "✦", "group": "lumen",
		"desc": "Bright filings caught on cloth. The whetting charms — keen edges, quick fingers — drink it up."},
	"emberglass":    {"name": "Emberglass",    "icon": "◈", "group": "echo",
		"desc": "Bog-iron fired to a red glass. The fierce charms are forged on it — fire, blood, the mark."},
	"dewthread":     {"name": "Dewthread",     "icon": "≈", "group": "verdant",
		"desc": "Dew-heavy hedge-green, spun fine. The gentle charms — snares, swift soles, steady hearts — take it gladly."},
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
	"mire_ink":      {"name": "Mire Ink",      "icon": "≈", "group": "verdant",
		"desc": "Bittergrass and mothmint ground into a wet, steady charting ink."},
	"emberleaf_ink": {"name": "Emberleaf Ink", "icon": "", "group": "verdant",
		"desc": "Embersage and wellwater held in ash. The Giant's sealed fire recognizes it."},
}

# Painted inventory art for materials that appear as first-chapter objects in
# dedicated icon wells. Text-heavy recipe lines still use the compact glyph in
# MATERIALS; cards and pickers should prefer material_icon_path() so unsupported
# font glyphs never become tofu squares.
const ICON_TEX := {
	"wild_herb": "res://assets/ui/items/wild_herb.png",
	"logs": "res://assets/ui/items/logs.png",
	"bogiron_ore": "res://assets/ui/items/bogiron_ore.png",
	"bogiron_bar": "res://assets/ui/field_journal/icons/bogiron_bar_v1.png",
	"copper_bar": "res://assets/ui/field_journal/icons/copper_bar_v1.png",
	"hedge_ink": "res://assets/ui/items/hedge_ink.png",
	"hearth_draught": "res://assets/ui/field_journal/icons/hearth_draught.png",
	"quickroot_tonic": "res://assets/ui/field_journal/icons/quickroot_tonic.png",
	"stoneground_ink": "res://assets/ui/items/stoneground_ink.png",
	"refined_ink": "res://assets/ui/items/refined_ink.png",
	"hedgesteel_ore": "res://assets/ui/items/hedgesteel_ore.png",
	"pale_wellmark": "res://assets/ui/components/pale_wellmark.png",
	"barrow_mark": "res://assets/ui/components/barrow_mark.png",
	"oath_nail": "res://assets/ui/items/oath_nail.png",
	"starheart_coal": "res://assets/ui/items/starheart_coal.png",
	"wildgold_ore": "res://assets/ui/items/wildgold_ore.png",
	"wildgold_bar": "res://assets/ui/items/wildgold_bar.png",
	"wellmoss": "res://assets/ui/items/wellmoss.png",
	"wellmoss_salve": "res://assets/ui/items/wellmoss_salve.png",
	"wellwater": "res://assets/ui/items/wellwater.png",
	"wellwater_philter": "res://assets/ui/items/wellwater_philter.png",
	"embersage": "res://assets/ui/items/embersage.png",
	"ash_mark": "res://assets/ui/components/ash_mark.png",
	"cinder_waymark": "res://assets/ui/components/cinder_waymark.png",
	"ember_mark": "res://assets/ui/components/ember_mark.png",
	"furnace_mark": "res://assets/ui/components/furnace_mark.png",
	"soot_track": "res://assets/ui/components/soot_track.png",
	"ember_folio": "res://assets/ui/components/ember_folio.png",
	"cinder_binding": "res://assets/ui/components/cinder_binding.png",
	"emberleaf_ink": "res://assets/ui/items/emberleaf_ink.png",
	"wyrm_scale": "res://assets/ui/items/wyrm_scale.png",
	"starheart_alloy": "res://assets/ui/items/starheart_alloy.png",
	# D8 — every Mastery-panel input/output has authored inventory art. Keep
	# these in the shared material icon authority so shops, rewards, the Codex,
	# and future station views do not each grow a private path table.
	"waysteel_shard": "res://assets/ui/items/waysteel_shard.png",
	"waysteel_core": "res://assets/ui/items/waysteel_core.png",
	"waysteel_frame": "res://assets/ui/items/waysteel_frame.png",
	"root_sap": "res://assets/ui/items/root_sap.png",
	"root_sap_cord": "res://assets/ui/items/root_sap_cord.png",
	"threefold_draught": "res://assets/ui/items/threefold_draught.png",
	"wayweaver_string": "res://assets/ui/items/wayweaver_string.png",
	"quiet_tooth": "res://assets/ui/items/quiet_tooth.png",
	"quiet_tooth_grip": "res://assets/ui/items/quiet_tooth_grip.png",
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
		"discovery_xp": 0,
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
		"req_wildcraft": 14, "hint_key": "still",
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
	"mire_ink": {
		"inputs": {"bittergrass": 1, "mothmint": 1, "hedge_ink": 1}, "yields": 1,
		"req_wildcraft": 10, "hint_key": "still",
		"riddle": "Quill: 'One bitter blade, one moth-pale bloom, and the everyday. Stir slow; wet roads dislike a hurry.'",
	},
	"emberleaf_ink": {
		"inputs": {"embersage": 2, "wellwater": 1, "ash_ink": 1}, "yields": 1,
		"discovery_xp": 0,
		"req_wildcraft": 20, "hint_key": "ember_verse_2",
		"riddle": "The second verse: two ember leaves, a well's measure, and ash enough to remember the heat.",
	},
}
const INK_RECIPE_ORDER := ["hedge_ink", "stoneground_ink", "refined_ink",
	"ash_ink", "chalkwash_ink", "mothglow_ink", "foxglove_ink", "gildleaf_ink",
	"mire_ink", "emberleaf_ink"]


static func ink_discovery_xp(ink_id: String) -> int:
	var recipe: Dictionary = INK_RECIPES.get(ink_id, {})
	return maxi(0, int(recipe.get("discovery_xp", 50))) if not recipe.is_empty() else 0

# Gather-node kinds. Mirrors the three.js dungeon decor kinds
# (ore_rock / forage_node / log_pile) plus their verb, trade, and XP.
const NODE_KINDS := {
	"ore_rock": {
		"verb": "Mine", "trade": "earthcraft", "xp": 10, "channel_sec": 1.6,
		"color": Color(0.55, 0.42, 0.30), "shape": "rock",
		"log": "You chip out a %s.",
	},
	"forage_node": {
		"verb": "Forage", "trade": "wildcraft", "xp": 8, "channel_sec": 1.0,
		"color": Color(0.45, 0.62, 0.34), "shape": "bush",
		"log": "You gather a %s.",
	},
	"log_pile": {
		"verb": "Chop", "trade": "wildcraft", "xp": 12, "channel_sec": 1.3,
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
	2: {"bittergrass": 25, "crowsfoot": 40, "mothmint": 25, "foxglove": 10},
	3: {"mothmint": 35, "foxglove": 40, "stonebreak": 25},
}
const FORAGE_ROLLS_PATCH := {
	1: {"wild": 40, "bittergrass": 60},
	2: {"bittergrass": 15, "crowsfoot": 35, "mothmint": 35, "foxglove": 15},
	3: {"mothmint": 25, "foxglove": 35, "stonebreak": 40},
}

# Rootroad-only tiers stay outside the legacy five/six-tier roll tables. The
# existing generic GatherNode can still carry their item ids; a rootroad
# adapter may read these explicit gates without altering older biome rolls.
const ROOTROAD_ORE_TIERS := {
	"wildgold": {"item": "wildgold_ore", "req_lv": 18, "xp": 56,
		"channel_sec": 3.0, "name": "Wildgold Vein",
		"color": Color(0.92, 0.72, 0.28), "starter_requires_tool": false},
	"waysteel": {"item": "waysteel_shard", "req_lv": 22, "xp": 76,
		"channel_sec": 3.2, "name": "Waysteel Seam",
		"color": Color(0.43, 0.58, 0.67), "starter_requires_tool": false,
		# Root Below's mastery source is exactly one raw shard. Its fixed yield
		# intentionally ignores Keen Eye and Sturdy Swings.
		"fixed_yield": 1, "bypass_gather_perks": ["keen_eye", "sturdy_swings"]},
}
const ROOTROAD_HERB_TIERS := {
	"wellmoss": {"item": "wellmoss", "req_lv": 18, "xp": 60,
		"channel_sec": 2.7, "name": "Wellmoss Patch",
		"color": Color(0.55, 0.78, 0.60)},
	"wellwater": {"item": "wellwater", "req_lv": 19, "xp": 64,
		"channel_sec": 2.9, "name": "Pale Well",
		"color": Color(0.64, 0.86, 0.92)},
	"embersage": {"item": "embersage", "req_lv": 20, "xp": 70,
		"channel_sec": 3.0, "name": "Embersage Patch",
		"color": Color(0.84, 0.36, 0.17)},
	"root_sap": {"item": "root_sap", "req_lv": 22, "xp": 76,
		"channel_sec": 3.2, "name": "Root-Sap Well",
		"color": Color(0.72, 0.64, 0.38),
		# Root Below's mastery source is exactly one raw sap. Its fixed yield
		# intentionally ignores Keen Eye and Sturdy Swings.
		"fixed_yield": 1, "bypass_gather_perks": ["keen_eye", "sturdy_swings"]},
}

# Rootroad generation has always placed these two native resources even when a
# template listed only its chapter-specific additions. Expose that production
# truth as data so generation and Trade-gate planning cannot drift apart.
const BIOME_GATHER_BASELINES := {
	"mire": ["mothmint"],
	"rootroads": ["wildgold", "wellmoss"],
	"ashen_bough": ["wildgold", "wellmoss"],
}
const SUPPORT_TRADE_LEVEL_CAP := 23


static func effective_biome_gather(scope: String, authored = []) -> Array:
	var out: Array = (BIOME_GATHER_BASELINES.get(scope, []) as Array).duplicate()
	if authored is Array:
		for id_v in authored:
			var id := String(id_v)
			if id != "" and not out.has(id):
				out.append(id)
	return out


static func raw_material_trade_requirements(material_or_tier_id: String) -> Dictionary:
	if material_or_tier_id == "logs":
		return {"valid": true, "earthcraft": 1, "wildcraft": 1,
			"source": "log_pile", "material_id": "logs"}
	for table_v in [[ORE_TIERS, "earthcraft"], [ROOTROAD_ORE_TIERS, "earthcraft"],
			[HERB_TIERS, "wildcraft"], [ROOTROAD_HERB_TIERS, "wildcraft"]]:
		var tiers: Dictionary = table_v[0]
		var trade := String(table_v[1])
		for tier_id_v in tiers:
			var tier_id := String(tier_id_v)
			var tier: Dictionary = tiers[tier_id_v]
			if material_or_tier_id != tier_id \
					and material_or_tier_id != String(tier.get("item", "")):
				continue
			return {"valid": true,
				"earthcraft": int(tier.get("req_lv", 1)) if trade == "earthcraft" else 1,
				"wildcraft": int(tier.get("req_lv", 1)) if trade == "wildcraft" else 1,
				"source": tier_id, "material_id": String(tier.get("item", ""))}
	return _failed_trade_requirements("unknown_raw_material:%s" % material_or_tier_id)


static func ink_trade_requirements(ink_id: String,
		recipes: Dictionary = INK_RECIPES) -> Dictionary:
	return _ink_trade_requirements(ink_id, {}, recipes)


static func _ink_trade_requirements(ink_id: String, visiting: Dictionary,
		recipes: Dictionary) -> Dictionary:
	if visiting.has(ink_id):
		return _failed_trade_requirements("ink_cycle:%s" % ink_id)
	var recipe: Dictionary = recipes.get(ink_id, {})
	if recipe.is_empty():
		return _failed_trade_requirements("unknown_ink:%s" % ink_id)
	var next_visiting := visiting.duplicate()
	next_visiting[ink_id] = true
	var out := {"valid": true, "earthcraft": 1,
		"wildcraft": maxi(1, int(recipe.get("req_wildcraft", 1))),
		"source": ink_id, "inputs": []}
	for input_id_v in (recipe.get("inputs", {}) as Dictionary):
		var input_id := String(input_id_v)
		var requirement: Dictionary = _ink_trade_requirements(
			input_id, next_visiting, recipes) \
			if recipes.has(input_id) else raw_material_trade_requirements(input_id)
		(out.inputs as Array).append({"id": input_id, "requirement": requirement})
		if not bool(requirement.get("valid", false)):
			return _failed_trade_requirements("%s->%s" % [ink_id,
				String(requirement.get("reason", "invalid_input"))])
		out.earthcraft = maxi(int(out.earthcraft), int(requirement.earthcraft))
		out.wildcraft = maxi(int(out.wildcraft), int(requirement.wildcraft))
	return out


static func _failed_trade_requirements(reason: String) -> Dictionary:
	# Invalid production data must never under-gate a route. Level 23 is the
	# playable cap and `valid=false` lets callers report the authored defect.
	return {"valid": false, "earthcraft": SUPPORT_TRADE_LEVEL_CAP,
		"wildcraft": SUPPORT_TRADE_LEVEL_CAP, "reason": reason}

static func material_name(id: String) -> String:
	return String(MATERIALS.get(id, {}).get("name", id))

static func material_icon(id: String) -> String:
	return String(MATERIALS.get(id, {}).get("icon", "·"))

static func material_icon_path(id: String) -> String:
	return String(ICON_TEX.get(id, ""))

static func material_icon_shape(id: String) -> String:
	return String(MATERIALS.get(id, {}).get("icon_shape", ""))

static func is_ink(id: String) -> bool:
	return INK_RECIPES.has(id) or id == "hedge_ink"
