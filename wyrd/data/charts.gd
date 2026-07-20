class_name Charts
extends RefCounted

const CampaignData = preload("res://data/campaign.gd")
const GatherDefs = preload("res://data/gather.gd")

# Wyrd slice — chart templates, Wayfinding affixes, and the bias-roll engine.
# Ported from the shipped three.js prototype (src/ui/charting.js,
# src/data/affixes.js, src/data/affixWeights.js). Player-facing name is
# "Wayfinding"; the code key stays `carto`.
#
# A crafted chart is a Dictionary:
#   { "template_id": String, "tier": int, "scope": String,
#     "affixes": [{ "id": String, "good": bool, "resolvedId": String }],
#     "seed": int, "name": String }
#
# Only affixes whose dungeon-side effects are implemented are rollable —
# the preview UI must never promise something the run can't deliver.

# ---- templates ----
# gen: the parameter block threaded into DungeonGen.generate(seed, cfg).
const TEMPLATES := {
	"first_road": {
		"tier": 1, "name": "First Road", "req_carto": 1,
		"desc": "A short teaching road whose three Affixes are chosen with Mara.",
		"affix_slots": 3, "ink_slots": 0, "base_cost": {},
		"scope": "snug",
		"gen": {"grid": 30, "room_min": 6, "room_max": 9,
			"room_count_min": 4, "room_count_max": 5,
			"enemy_density": 0.75},
	},
	"snug": {
		"tier": 1, "name": "Snug", "req_carto": 1,
		"desc": "A pocket cellar — no affixes. A quick, clean run.",
		"affix_slots": 0, "ink_slots": 0,   # no affixes → nothing for ink to bias
		"base_cost": {"hedge_ink": 1},
		"scope": "snug",
		"gen": {"grid": 28, "room_min": 6, "room_max": 9,
			"room_count_min": 3, "room_count_max": 7,
			"enemy_density": 0.5},   # tutorial cellar stays gentle
	},
	"tier_1": {
		"tier": 1, "name": "Tier 1 Hollow", "req_carto": 1,
		"desc": "A small, single-floor chart. One affix slot.",
		"affix_slots": 1, "ink_slots": 2,
		"base_cost": {"hedge_ink": 2},
		"scope": "hollow",
		"gen": {"grid": 36, "room_min": 7, "room_max": 11,
			"room_count_min": 4, "room_count_max": 9,
			# Core Trade practice is a biome promise, not an Affix lottery.
			# Gather Affixes still add richer patches on top of this one-node triad.
			"required_biome_gather": ["copper", "wild", "logs"]},
	},
	# Golden Wallow's level-9 route. This is deliberately not named "Gilded
	# Hollow": that name already belongs to the gilded Affix's good twin.
	"mire_shallows": {
		"tier": 1, "name": "Sallow Shallows", "req_carto": 9,
		"desc": "A short reed-road through the Sallow shallows. One Affix, one layer.",
		"affix_slots": 1, "ink_slots": 1,
		"base_cost": {"hedge_ink": 1},
		"scope": "mire",
		"gen": {"grid": 32, "room_min": 6, "room_max": 9,
			"room_count_min": 4, "room_count_max": 7,
			"enemy_density": 0.75, "loop_fraction": 0.45},
	},
	"hollow": {
		"tier": 2, "name": "Hollow", "req_carto": 10,
		"desc": "Multi-room. Larger, richer chest.",
		"affix_slots": 2, "ink_slots": 3,
		"base_cost": {"hedge_ink": 3},
		"scope": "hollow",
		"max_layers": 2,
		"gen": {},   # current dungeon_gen defaults (48 grid, rooms 8-14)
	},
	"briar_maze": {
		"tier": 2, "name": "Briar Maze", "req_carto": 15,
		"desc": "Twisted layout — corridors over rooms.",
		"affix_slots": 2, "ink_slots": 3,
		"base_cost": {"hedge_ink": 3},
		"scope": "briar_maze",
		"gen": {"room_min": 6, "room_max": 10, "loop_fraction": 0.55,
			"corridor_ratio_max": 2.4},
	},
	# A wetland chart — the Sallow Mire (its own biome: data/layout_loader BIOMES.bog).
	# Open, looping reed-and-root layout; sits between Hollow and Briar Maze.
	"mire": {
		"tier": 2, "name": "Sallow Mire", "req_carto": 12,
		"desc": "A drowned hollow of reed and root. Open and looping; the fog keeps secrets.",
		"affix_slots": 2, "ink_slots": 3,
		"base_cost": {"hedge_ink": 3},
		"scope": "mire",
		"max_layers": 3,
		"miniboss_affix": "burrow_boar_den",
		"gen": {"room_min": 7, "room_max": 12, "loop_fraction": 0.5},
	},
	# The endgame: the chart the whole chain builds toward. The Alpha's
	# fang is the only key; the Queen waits at the bottom.
	"summit": {
		"tier": 3, "name": "Chart of the Summit", "req_carto": 16,
		"desc": "The final chart — where the first Hedgemother nests. The fang opens the way.",
		"affix_slots": 0, "ink_slots": 0,
		# Alpha's Fang is a visible Story Seal on newly resolved Summit Charts.
		# Removing it from the opaque base cost does not affect Charts already
		# materialized in saves; it only makes future inscription honest.
		"base_cost": {"hedge_ink": 4, "refined_ink": 1},
		"scope": "summit",
		"gen": {"boss_kind": "hedgemother_queen", "enemy_density": 1.4,
			"loop_fraction": 0.4},
	},
	# The retired Summit remains only for materialized legacy Charts and their
	# frozen handoff. New Table work uses the two separate roads below: the
	# climb may be read without meeting a Queen, while the chapter road carries
	# an explicit campaign contract rather than a boss baked into generation.
	"summit_approach": {
		"tier": 3, "name": "Crownward Ascent", "req_carto": 16,
		"desc": "A cold, thorn-bound climb beneath the lost crown. The road keeps its own counsel.",
		"affix_slots": 0, "ink_slots": 0,
		"base_cost": {"hedge_ink": 4},
		"scope": "summit",
		"gen": {"enemy_density": 1.15, "loop_fraction": 0.42},
	},
	"summit_queen": {
		"tier": 3, "name": "Queen's Summit", "req_carto": 17,
		"desc": "The thorn-crown's high chamber. An old promise waits at its root.",
		"affix_slots": 0, "ink_slots": 0,
		"base_cost": {"hedge_ink": 4},
		"scope": "summit",
		"gen": {"enemy_density": 1.4, "loop_fraction": 0.4},
	},
	# The Pale Oath's two roads share a rooted, bell-haunted scope.  The
	# ordinary road alone can roll an Affix; the boss template stays boss-free
	# until CampaignData attaches the explicit Barrow Jarl contract.
	"pale_veins": {
		"tier": 3, "name": "Pale Veins", "req_carto": 18,
		"desc": "A rootroad through pale stone, where old wells keep their names.",
		"affix_slots": 1, "ink_slots": 0,
		"base_cost": {"hedge_ink": 5},
		"scope": "rootroads",
		"affix_pool": ["stonewake"],
		"gen": {"enemy_density": 1.5, "loop_fraction": 0.46,
			"required_biome_gather": ["wildgold", "wellmoss"]},
	},
	"pale_oath_boss": {
		"tier": 3, "name": "The Pale Oath", "req_carto": 19,
		"desc": "A nailed promise under the rootroads. The Barrow Jarl keeps it.",
		"affix_slots": 0, "ink_slots": 0,
		"base_cost": {"hedge_ink": 5},
		"scope": "rootroads",
		"gen": {"enemy_density": 1.65, "loop_fraction": 0.38,
			"required_biome_gather": ["wildgold", "wellwater"]},
	},
	# Fire in the Bough branches from the already-restored rootroads. The
	# ordinary route alone carries Cinderbound and its optional second depth;
	# the sealed Giant route is intentionally slotless and unvariantable.
	"ashen_bough": {
		"tier": 3, "name": "Ashen Bough", "req_carto": 20,
		"desc": "A hot rootroad under falling ash. One Cinderbound promise may be written into it.",
		"affix_slots": 1, "ink_slots": 0,
		"base_cost": {"hedge_ink": 5}, "scope": "ashen_bough", "max_layers": 1,
		"affix_pool": ["cinderbound"],
		"gen": {"enemy_density": 1.72, "loop_fraction": 0.48,
			"required_biome_gather": ["embersage", "wellwater"]},
	},
	"fire_in_the_bough_boss": {
		"tier": 3, "name": "Fire in the Bough", "req_carto": 21,
		"desc": "A sealed furnace-road where the Hearth Giant keeps the fire banked.",
		"affix_slots": 0, "ink_slots": 0,
		"base_cost": {"hedge_ink": 5}, "scope": "ashen_bough",
		"gen": {"enemy_density": 1.9, "loop_fraction": 0.34,
			"required_biome_gather": ["embersage", "wellwater"]},
	},
	# The first D8 road deliberately reuses the final ritual's renewable
	# component family at its smallest readable grammar.  World generation owns
	# its special rooms in a later slice; this data record only promises the
	# authored road which may bank the next Lost Waymark.
	"root_below": {
		"tier": 3, "name": "Root Below", "req_carto": 22,
		"desc": "A patient road beneath the old bindings. One Lost Waymark may still be read there.",
		"affix_slots": 1, "ink_slots": 0,
		"base_cost": {"hedge_ink": 1}, "scope": "rootroads",
		"affix_pool": ["open_thread"],
		"gen": {"enemy_density": 2.0, "loop_fraction": 0.44,
			"required_biome_gather": ["waysteel", "root_sap"]},
	},
	# The final road is slotless: its ordinary Hedge Ink is an authored ritual
	# cost, not a bias pot.  The Wyrm Scale remains the only escrowed Seal;
	# Map and Runes are represented by the recipe witness field below.
	"unwritten_road_boss": {
		"tier": 3, "name": "The Unwritten Road", "req_carto": 23,
		"desc": "A new road through the old knots, written without owning what it remembers.",
		"affix_slots": 0, "ink_slots": 0,
		"base_cost": {"hedge_ink": 1}, "scope": "rootroads",
		"gen": {"enemy_density": 2.15, "loop_fraction": 0.36},
	},
}
# Legacy template order remains the six shipped tray entries. Sallow Shallows
# is deliberately physical-table-only, so it cannot alter legacy resolution or
# save migration order.
const TEMPLATE_ORDER := ["snug", "tier_1", "hollow", "briar_maze", "mire", "summit"]

# ---- spec 58 Slice A: Chart Recipes ----
#
# Components are semantic authored data in Slice A. The shipped bench still
# presents one template button, which resolve_legacy_template translates into
# the equivalent staged pattern. Slice B makes these components ownable and
# places them on the physical charting grid.
const COMPONENTS := {
	# Bases — page capacity / tier identity.
	"practice_leaf": {"kind": "base", "name": "Practice Leaf", "icon_shape": "leaf"},
	"field_parchment": {"kind": "base", "name": "Field Parchment", "icon_shape": "page"},
	"stitched_parchment": {"kind": "base", "name": "Stitched Parchment", "icon_shape": "stitched_page"},
	"waxed_vellum": {"kind": "base", "name": "Waxed Vellum", "icon_shape": "waxed_page"},
	"atlas_folio": {"kind": "base", "name": "Atlas Folio", "icon_shape": "folio"},
	"ember_folio": {"kind": "base", "name": "Ember Folio", "icon_shape": "ember_folio"},
	# Waymarks — destination / biome identity.
	"hedge_sprig": {"kind": "waymark", "name": "Hedge Sprig", "icon_shape": "sprig"},
	"thorn_rubbing": {"kind": "waymark", "name": "Thorn Rubbing", "icon_shape": "rubbing"},
	"mire_reed": {"kind": "waymark", "name": "Mire Reed", "icon_shape": "reed"},
	"cold_track": {"kind": "waymark", "name": "Cold Track", "icon_shape": "track"},
	"pale_wellmark": {"kind": "waymark", "name": "Pale Wellmark", "icon_shape": "wellmark"},
	"barrow_mark": {"kind": "waymark", "name": "Barrow Mark", "icon_shape": "barrow_mark"},
	"ash_mark": {"kind": "waymark", "name": "Ash Mark", "icon_shape": "ash_mark"},
	"cinder_waymark": {"kind": "waymark", "name": "Cinder Waymark", "icon_shape": "cinder_waymark"},
	"ember_mark": {"kind": "waymark", "name": "Ember Mark", "icon_shape": "ember_mark"},
	"furnace_mark": {"kind": "waymark", "name": "Furnace Mark", "icon_shape": "furnace_mark"},
	"soot_track": {"kind": "waymark", "name": "Soot Track", "icon_shape": "soot_track"},
	# Bindings — route topology.
	"loop_cord": {"kind": "binding", "name": "Loop Cord", "icon_shape": "loop"},
	"hollow_stitch": {"kind": "binding", "name": "Hollow Stitch", "icon_shape": "stitch"},
	"briar_knot": {"kind": "binding", "name": "Briar Knot", "icon_shape": "thorn_knot"},
	"sunk_knot": {"kind": "binding", "name": "Sunk Knot", "icon_shape": "wet_knot"},
	"climbing_cord": {"kind": "binding", "name": "Climbing Cord", "icon_shape": "double_loop"},
	"cinder_binding": {"kind": "binding", "name": "Cinder Binding", "icon_shape": "cinder_binding"},
	# The Unwritten family is renewable physical table stock. Its story truth
	# lives separately in `required_story_inputs`: never add a Rune or Map here.
	"nine_knot_leaf": {"kind": "base", "name": "Nine-Knot Leaf", "icon_shape": "nine_knot_leaf"},
	"lost_waymark_tracing": {"kind": "waymark", "name": "Lost-Waymark Tracing", "icon_shape": "lost_waymark_tracing"},
	"threefold_binding": {"kind": "binding", "name": "Threefold Binding", "icon_shape": "threefold_binding"},
}

const COMPONENT_ORDER := ["practice_leaf", "field_parchment",
	"stitched_parchment", "waxed_vellum", "atlas_folio", "ember_folio", "hedge_sprig",
	"thorn_rubbing", "mire_reed", "cold_track", "loop_cord",
	"pale_wellmark", "barrow_mark", "ash_mark", "cinder_waymark", "ember_mark",
	"furnace_mark", "soot_track", "hollow_stitch", "briar_knot",
	"sunk_knot", "climbing_cord", "cinder_binding", "nine_knot_leaf",
	"lost_waymark_tracing", "threefold_binding"]

# Mara's renewable table-supply drawer. Availability is derived from the
# player's known Chart Recipes, so data — not the panel — owns progression.
const MARA_SUPPLY_PRICES := {
	"practice_leaf": 2, "field_parchment": 4, "stitched_parchment": 8,
	"waxed_vellum": 12, "atlas_folio": 20, "ember_folio": 24,
	"hedge_sprig": 1, "thorn_rubbing": 4, "mire_reed": 5, "cold_track": 8,
	"pale_wellmark": 10, "barrow_mark": 14, "ash_mark": 16,
	"cinder_waymark": 16, "ember_mark": 18, "furnace_mark": 20, "soot_track": 20,
	"loop_cord": 3, "hollow_stitch": 6, "briar_knot": 7,
	"sunk_knot": 8, "climbing_cord": 12, "cinder_binding": 16,
	"nine_knot_leaf": 10, "lost_waymark_tracing": 5,
	"threefold_binding": 7,
}

# The stable slot grammar for the eventual grid. Ink stays on its separate
# rail and the Seal is passed independently to the resolver, matching spec 58.
const COMPONENT_SLOT_KINDS := {
	"nw": "waymark", "n": "waymark", "ne": "waymark",
	"w": "binding", "c": "base", "e": "binding",
	"sw": "relic", "s": "seal", "se": "relic",
}
const TABLE_SLOT_ORDER := ["nw", "n", "ne", "w", "c", "e", "sw", "s", "se"]
const TABLE_SLOT_UNLOCK_LEVELS := {
	"nw": 10, "n": 1, "ne": 19,
	"w": 0, "c": 1, "e": 14,
	"sw": 22, "s": 8, "se": 22,
}
const INK_RAIL_UNLOCK_LEVELS := [1, 4, 10, 17]

# The six current templates are represented one-for-one as recipe outputs.
# Pattern order does not matter; slot identity does.
const CHART_RECIPES := {
	"snug": {
		"req_wayfinding": 1,
		"pattern": {"n": "hedge_sprig", "c": "practice_leaf"},
		"required_inks": ["hedge_ink"],
		"output": {"template_id": "snug", "biome_id": "bramblewood",
			"topology_id": "snug"},
		"rumour_id": "mara_first_leaf",
	},
	"green_hollow": {
		"req_wayfinding": 1,
		"pattern": {"n": "hedge_sprig", "c": "field_parchment",
			"w": "loop_cord"},
		"deepening_variant": {"variant_id": "green_hollow_deepening",
			"binding_slot": "e", "binding_id": "loop_cord",
			"min_wayfinding": 17},
		"output": {"template_id": "tier_1", "biome_id": "bramblewood",
			"topology_id": "hollow"},
		"rumour_id": "mara_first_loop",
	},
	# Slice D1 — the First Knot uses the familiar Green Hollow route grammar,
	# but the Seal makes this a distinct, clue-gated authored Boss Chart. It is
	# selected only by the physical table; legacy template resolution keeps its
	# historical boss-affix behavior.
	"first_knot_boss": {
		"req_wayfinding": 8,
		"pattern": {"n": "hedge_sprig", "c": "field_parchment",
			"w": "loop_cord"},
		"required_inks": ["hedge_ink"],
		"required_seal": "thorn_essence",
		"campaign_chapter": "first_knot",
		"output": {"template_id": "tier_1", "biome_id": "bramblewood",
			"topology_id": "hollow", "name": "Hedgemother's Den"},
		"rumour_id": "mara_first_knot",
	},
	"sallow_shallows": {
		"req_wayfinding": 9,
		"pattern": {"n": "mire_reed", "c": "field_parchment",
			"w": "loop_cord"},
		"required_inks": ["hedge_ink"],
		"requires_first_knot_clear": true,
		"output": {"template_id": "mire_shallows", "biome_id": "sallow_mire",
			"topology_id": "mire"},
		"rumour_id": "atlas_sallow_shallows",
	},
	"deep_hollow": {
		"req_wayfinding": 10,
		"pattern": {"n": "hedge_sprig", "c": "stitched_parchment",
			"w": "hollow_stitch"},
		"deepening_variant": {"variant_id": "deep_hollow_deepening",
			"binding_slot": "e", "binding_id": "hollow_stitch",
			"min_wayfinding": 17},
		"output": {"template_id": "hollow", "biome_id": "bramblewood",
			"topology_id": "hollow"},
		"rumour_id": "atlas_deep_hollow",
	},
	"briar_maze": {
		"req_wayfinding": 15,
		# A good Mineral Vein can be one of this recipe's first two Affixes.
		# Earthcraft 3 is a production/support-planning contract matching the
		# guaranteed Bogiron anchor. (The physical Table does not yet present an
		# Earthcraft gate.) Wildcraft 3 is its player-facing Bittergrass twin.
		"req_earthcraft": 3,
		"req_wildcraft": 3,
		"pattern": {"n": "thorn_rubbing", "c": "stitched_parchment",
			"w": "briar_knot"},
		"deepening_variant": {"variant_id": "briar_maze_deepening",
			"binding_slot": "e", "binding_id": "briar_knot",
			"min_wayfinding": 17},
		"output": {"template_id": "briar_maze", "biome_id": "bramblewood",
			"topology_id": "briar_maze"},
		"rumour_id": "atlas_briar_knot",
	},
	"sallow_mire": {
		"req_wayfinding": 12,
		"pattern": {"n": "mire_reed", "c": "waxed_vellum",
			"w": "sunk_knot"},
		"deepening_variant": {"variant_id": "sallow_mire_deepening",
			"binding_slot": "e", "binding_id": "sunk_knot",
			"min_wayfinding": 17},
		"output": {"template_id": "mire", "biome_id": "sallow_mire",
			"topology_id": "mire"},
		"rumour_id": "mara_sallow_reed",
	},
	# The Tusker Tusk Seal selects this authored contract over ordinary Sallow
	# Mire. The campaign contract, not a good/bad den Affix, guarantees Boar.
	"golden_wallow_boss": {
		"req_wayfinding": 12,
		"pattern": {"n": "mire_reed", "c": "waxed_vellum",
			"w": "sunk_knot"},
		"required_inks": ["mire_ink"],
		"preparation_notes": ["Mire Ink — mixed at Wildcraft 10."],
		"required_seal": "tusker_tusk",
		"campaign_chapter": "golden_wallow",
		"output": {"template_id": "mire", "biome_id": "sallow_mire",
			"topology_id": "mire", "name": "Burrow Boar's Wallow"},
		"rumour_id": "golden_wallow_boss",
	},
	# The same Briar marks as an ordinary Maze become one named road only when
	# Mothglow and the protected Wightpelt are present. CampaignData, rather than
	# the legacy Wolf-den Affix, guarantees the Alpha in the deepest room.
	"seventh_road_boss": {
		"req_wayfinding": 15,
		"req_earthcraft": 3,
		"req_wildcraft": 14,
		"pattern": {"n": "thorn_rubbing", "c": "stitched_parchment",
			"w": "briar_knot"},
		"required_inks": ["mothglow_ink"],
		"preparation_notes": ["Mothglow Ink — mixed at Wildcraft 14."],
		"required_seal": "wightpelt",
		"campaign_chapter": "seventh_road",
		"output": {"template_id": "briar_maze", "biome_id": "bramblewood",
			"topology_id": "briar_maze", "name": "Wolf Alpha's Seventh Road"},
		"rumour_id": "seventh_road_boss",
	},
	"queens_summit": {
		"req_wayfinding": 16,
		"pattern": {"nw": "cold_track", "n": "cold_track",
			"c": "atlas_folio", "w": "climbing_cord", "e": "climbing_cord"},
		"required_seal": "alpha_fang",
		"handoff_contract": "legacy_summit_handoff",
		"output": {"template_id": "summit", "biome_id": "summit",
			"topology_id": "summit"},
		"rumour_id": "atlas_crown_road",
	},
	# The first half of the authored Summit chapter. It deliberately has no
	# Seal and no baked boss: four ordinary returned Charts bank the Crown-Thorn
	# facts in CampaignData before the Queen's contract may be written.
	"summit_approach": {
		"req_wayfinding": 16,
		"pattern": {"nw": "cold_track", "n": "cold_track",
			"c": "atlas_folio", "w": "climbing_cord", "e": "climbing_cord"},
		"required_inks": ["refined_ink"],
		"output": {"template_id": "summit_approach", "biome_id": "summit",
			"topology_id": "summit", "name": "Crownward Ascent"},
		"rumour_id": "skald_crownward_ascent",
	},
	# The second road is a distinct physical grammar. Only the immutable
	# campaign contract forces the Queen; the generation template itself remains
	# boss-free so ordinary and historical Summit Charts cannot inherit her.
	"queens_summit_boss": {
		"req_wayfinding": 17,
		"pattern": {"nw": "cold_track", "n": "thorn_rubbing",
			"c": "atlas_folio", "w": "climbing_cord", "e": "climbing_cord"},
		"required_inks": ["refined_ink"],
		"required_seal": "alpha_fang",
		"campaign_chapter": CampaignData.QUEENS_SUMMIT,
		"output": {"template_id": "summit_queen", "biome_id": "summit",
			"topology_id": "summit", "name": "Queen's Summit"},
		"rumour_id": "queens_summit_boss",
	},
	# The four Oath-Rubbings are campaign-ledger facts, never marks placed on
	# the Table. This ordinary road merely guarantees the next authored room.
	"pale_veins": {
		"req_wayfinding": 18,
		"requires_chapter_clear": CampaignData.QUEENS_SUMMIT,
		"pattern": {"n": "pale_wellmark", "c": "atlas_folio",
			"w": "climbing_cord", "e": "climbing_cord"},
		"required_inks": ["stoneground_ink"],
		"output": {"template_id": "pale_veins", "biome_id": "rootroads",
			"topology_id": "rootroads", "name": "Pale Veins"},
		"rumour_id": "skald_pale_oath",
	},
	"pale_oath_boss": {
		"req_wayfinding": 19,
		"requires_chapter_clear": CampaignData.QUEENS_SUMMIT,
		"requires_chapter_clue_count": {"chapter_id": CampaignData.PALE_OATH,
			"count": 4},
		"pattern": {"nw": "barrow_mark", "n": "pale_wellmark",
			"ne": "cold_track", "c": "atlas_folio", "w": "climbing_cord",
			"e": "climbing_cord"},
		"required_inks": ["stoneground_ink"],
		"required_seal": "oath_nail",
		"campaign_chapter": CampaignData.PALE_OATH,
		"output": {"template_id": "pale_oath_boss", "biome_id": "rootroads",
			"topology_id": "rootroads", "name": "The Pale Oath"},
		"rumour_id": "skald_pale_oath_boss",
	},
	# Fire in the Bough: five returned ordinary Charts bank Ember Verses. The
	# east Cinder Binding is the sole Deepening II grammar and is deliberately
	# absent from the boss pattern, so no Seal road can resolve as a variant.
	"ashen_bough": {
		"req_wayfinding": 20,
		"requires_chapter_clear": CampaignData.PALE_OATH,
		"pattern": {"nw": "ash_mark", "n": "cinder_waymark", "ne": "ember_mark",
			"w": "cinder_binding", "c": "ember_folio"},
		"deepening_variant": {"variant_id": "ashen_bough.deepening_variant",
			"binding_slot": "e", "binding_id": "cinder_binding",
			"min_wayfinding": 21},
		"required_inks": ["ash_ink"],
		# A campaign clue return pays its authored total, frozen on the
		# physical Chart.  It deliberately replaces (rather than augments) the
		# ordinary tier/Affix formula, so Cinderbound can never move the
		# late-game level gates.  Recipe discovery is a source/table fact, not
		# another way to grind this campaign lane.
		"campaign_xp": {"kind": "clue", "clue_rewards": [68, 69, 69, 69, 69],
			"discovery_xp": 0},
		"output": {"template_id": "ashen_bough", "biome_id": "ashen_bough",
			"topology_id": "ashen_bough", "name": "Ashen Bough"},
		"rumour_id": "rootroad_lift_ashen_bough",
	},
	"fire_in_the_bough_boss": {
		"req_wayfinding": 21,
		"requires_chapter_clear": CampaignData.PALE_OATH,
		"requires_chapter_clue_count": {"chapter_id": CampaignData.FIRE_IN_THE_BOUGH,
			"count": 5},
		"pattern": {"nw": "furnace_mark", "n": "cinder_waymark", "ne": "soot_track",
			"w": "cinder_binding", "c": "ember_folio"},
		"required_inks": ["emberleaf_ink"],
		"required_seal": "starheart_coal",
		"campaign_chapter": CampaignData.FIRE_IN_THE_BOUGH,
		"campaign_xp": {"kind": "boss", "completion_xp": 360,
			"discovery_xp": 0},
		"output": {"template_id": "fire_in_the_bough_boss", "biome_id": "ashen_bough",
			"topology_id": "ashen_bough", "name": "Fire in the Bough"},
		"rumour_id": "fire_in_the_bough_boss",
	},
	# Root Below is the level-22 clue road. The first small arrangement teaches
	# that the final ritual is made from renewable paper, tracings, and bindings;
	# the five Lost Waymarks themselves stay in CampaignData's ledger.
	"root_below": {
		"req_wayfinding": 22,
		"requires_chapter_clear": CampaignData.FIRE_IN_THE_BOUGH,
		"pattern": {"n": "lost_waymark_tracing", "c": "nine_knot_leaf",
			"w": "threefold_binding"},
		"required_inks": ["hedge_ink"],
		"campaign_xp": {"kind": "clue", "clue_rewards": [75, 75, 75, 75, 76],
			"discovery_xp": 0},
		"output": {"template_id": "root_below", "biome_id": "rootroads",
			"topology_id": "rootroads", "name": "Root Below"},
		"rumour_id": "threefold_loom_root_below",
	},
	# The capstone spends only renewable table stock plus the physical Wyrm
	# Scale Seal. Map and Runes are a read-only Campaign witness: they never
	# enter this pattern, component_cost, reagent_cost, or escrow arithmetic.
	"unwritten_road_boss": {
		"req_wayfinding": 23,
		"pattern": {"nw": "lost_waymark_tracing", "n": "lost_waymark_tracing",
			"ne": "lost_waymark_tracing", "w": "threefold_binding",
			"c": "nine_knot_leaf", "e": "threefold_binding"},
		"required_inks": ["hedge_ink"],
		"required_seal": "wyrm_scale",
		"required_story_inputs": CampaignData.UNWRITTEN_REQUIRED_STORY_INPUTS,
		"campaign_chapter": CampaignData.UNWRITTEN_ROAD,
		"campaign_xp": {"kind": "boss", "completion_xp": 0,
			"discovery_xp": 0},
		"output": {"template_id": "unwritten_road_boss", "biome_id": "rootroads",
			"topology_id": "rootroads", "name": "The Unwritten Road"},
		"rumour_id": "unwritten_road_boss",
	},
	# Slice D2 — a post-clear replay is a separately entitled Chart, never a
	# campaign attempt. Its repeated Loop Cord makes the authored second layer.
	"first_knot_reprise": {
		"req_wayfinding": 21,
		"pattern": {"n": "hedge_sprig", "c": "field_parchment",
			"w": "loop_cord", "e": "loop_cord"},
		"required_inks": ["hedge_ink"],
		"required_seal": "thorn_essence",
		"requires_first_knot_clear": true,
		"output": {"template_id": "tier_1", "biome_id": "bramblewood",
			"topology_id": "hollow", "name": "First Knot Reprise"},
		"rumour_id": "first_knot_reprise",
	},
}

# Pure production contract for a Chart recipe. This folds together the Table's
# direct Trade gates, the full ingredient closure of every required Ink, and
# every resource the generated biome guarantees. Route automation and Codex
# readers can therefore ask one data owner instead of mirroring late-game gates.
static func recipe_production_requirements(recipe_id: String) -> Dictionary:
	var recipe: Dictionary = CHART_RECIPES.get(recipe_id, {})
	if recipe.is_empty():
		return _failed_production_requirements("unknown_recipe:%s" % recipe_id)
	var out := {
		"valid": true,
		"wayfinding": maxi(1, int(recipe.get("req_wayfinding", 1))),
		"huntcraft": maxi(1, int(recipe.get("req_huntcraft", 1))),
		"earthcraft": maxi(1, int(recipe.get("req_earthcraft", 1))),
		"wildcraft": maxi(1, int(recipe.get("req_wildcraft", 1))),
		"required_inks": [],
		"effective_biome_gather": [],
	}
	for ink_id_v in recipe.get("required_inks", []):
		var ink_id := String(ink_id_v)
		var ink_requirement := GatherDefs.ink_trade_requirements(ink_id)
		(out.required_inks as Array).append(ink_id)
		if not bool(ink_requirement.get("valid", false)):
			return _failed_production_requirements("%s:%s" % [recipe_id,
				String(ink_requirement.get("reason", "invalid_ink"))])
		out.earthcraft = maxi(int(out.earthcraft),
			int(ink_requirement.get("earthcraft", 1)))
		out.wildcraft = maxi(int(out.wildcraft),
			int(ink_requirement.get("wildcraft", 1)))
	var output: Dictionary = recipe.get("output", {})
	var template_id := String(output.get("template_id", ""))
	var template: Dictionary = TEMPLATES.get(template_id, {})
	if template.is_empty():
		return _failed_production_requirements(
			"%s:unknown_template:%s" % [recipe_id, template_id])
	var generation: Dictionary = template.get("gen", {})
	var effective := GatherDefs.effective_biome_gather(
		String(template.get("scope", "")),
		generation.get("required_biome_gather", []))
	out.effective_biome_gather = effective
	for material_id_v in effective:
		var material_id := String(material_id_v)
		var gather_requirement := GatherDefs.raw_material_trade_requirements(material_id)
		if not bool(gather_requirement.get("valid", false)):
			return _failed_production_requirements("%s:%s" % [recipe_id,
				String(gather_requirement.get("reason", "invalid_biome_gather"))])
		out.earthcraft = maxi(int(out.earthcraft),
			int(gather_requirement.get("earthcraft", 1)))
		out.wildcraft = maxi(int(out.wildcraft),
			int(gather_requirement.get("wildcraft", 1)))
	return out


static func _failed_production_requirements(reason: String) -> Dictionary:
	return {"valid": false, "wayfinding": 23, "huntcraft": 23,
		"earthcraft": 23, "wildcraft": 23, "reason": reason,
		"required_inks": [], "effective_biome_gather": []}

# D8 — campaign returns use authored totals, not Affix-sensitive ordinary
# completion XP.  Existing recipes carry the same record inline so their
# intent remains legible at the Table.  The compatibility registry lets the
# Campaign-v6 owner add Root Below / Unwritten recipes independently: older
# builds can already answer their XP/discovery contract without inventing a
# duplicate campaign or progression system.
#
# `completion_xp: 0` is meaningful for the Unwritten finale.  Never infer
# absence from zero: only a materialized Chart that explicitly carries
# `authored_completion_xp` replaces legacy completion math.
const CAMPAIGN_COMPLETION_XP := {
	"green_hollow": [149, 149, 150],
	"first_knot_boss": 152,
	"sallow_shallows": [168, 92, 92],
	"deep_hollow": 200,
	"golden_wallow_boss": 646,
	"briar_maze": [32, 32, 32, 32],
	"seventh_road_boss": 86,
	"summit_approach": [57, 57, 58, 58],
	"queens_summit_boss": 296,
	"pale_veins": [65, 65, 66, 66],
	"pale_oath_boss": 328,
	"ashen_bough": [68, 69, 69, 69, 69],
	"fire_in_the_bough_boss": 360,
	"root_below": [75, 75, 75, 75, 76],
	"unwritten_road_boss": 0,
}

# Mandatory campaign roads must not require an off-route gold grind between
# authored clue returns. Pale Oath bridges into the first Ashen purchase; each
# Ashen return then replaces the exact 90g renewable component layout for the
# next Verse. Other Charts retain the ordinary tier/Affix purse formula.
const CAMPAIGN_COMPLETION_GOLD := {
	"pale_veins": 54,
	"pale_oath_boss": 46,
	"ashen_bough": 90,
}

# The public reward registry above intentionally stays a terse id ->
# Array/int contract for the progression simulator and Codex tooling.  This
# companion metadata owns the eligibility/discovery interpretation without
# asking those readers to understand the runtime's materialization details.
const CAMPAIGN_COMPLETION_METADATA := {
	"green_hollow": {"kind": "clue", "discovery_xp": 93},
	"first_knot_boss": {"kind": "boss", "discovery_xp": 0},
	"sallow_shallows": {"kind": "clue", "discovery_xp": 0},
	# Deep Hollow is the one non-ledger Golden bridge. New materializations
	# freeze this fixed production total; legacy/Memory Charts without the field
	# retain ordinary Affix-sensitive completion math.
	"deep_hollow": {"kind": "fixed", "discovery_xp": 0},
	"golden_wallow_boss": {"kind": "boss", "discovery_xp": 0},
	"briar_maze": {"kind": "clue", "discovery_xp": 0},
	"seventh_road_boss": {"kind": "boss", "discovery_xp": 0},
	"summit_approach": {"kind": "clue", "discovery_xp": 0},
	"queens_summit_boss": {"kind": "boss", "discovery_xp": 0},
	"pale_veins": {"kind": "clue", "discovery_xp": 0},
	"pale_oath_boss": {"kind": "boss", "discovery_xp": 0},
	"ashen_bough": {"kind": "clue", "discovery_xp": 0},
	"fire_in_the_bough_boss": {"kind": "boss", "discovery_xp": 0},
	"root_below": {"kind": "clue", "discovery_xp": 0},
	"unwritten_road_boss": {"kind": "boss", "discovery_xp": 0},
}

# These names are compatibility-only until Campaign v6 writes its finalized
# physical recipe ids.  They keep older tooling and save-adapter tests honest
# without making an alternate route resolvable at the Chart Table.
const CAMPAIGN_COMPLETION_XP_ALIASES := {
	"root_below_chart": "root_below",
	"unwritten_chart": "unwritten_road_boss",
	"unwritten_road": "unwritten_road_boss",
}

static func campaign_completion_xp_definition(recipe_id: String) -> Dictionary:
	var canonical_id := String(CAMPAIGN_COMPLETION_XP_ALIASES.get(recipe_id, recipe_id))
	var recipe: Dictionary = CHART_RECIPES.get(recipe_id, {})
	var inline: Dictionary = recipe.get("campaign_xp", {})
	if not inline.is_empty():
		var authored := inline.duplicate(true)
		# A future recipe may only need to name its reward shape inline. Keep
		# zero-discovery semantics and kind classification centralized here so a
		# content addition cannot accidentally reopen the exact XP lane.
		var default_meta: Dictionary = CAMPAIGN_COMPLETION_METADATA.get(canonical_id, {})
		for key_v in default_meta:
			var key := String(key_v)
			if not authored.has(key):
				authored[key] = default_meta[key_v]
		return authored
	if not CAMPAIGN_COMPLETION_XP.has(canonical_id):
		return {}
	var compatibility: Dictionary = CAMPAIGN_COMPLETION_METADATA.get(canonical_id, {})
	var out := compatibility.duplicate(true)
	var reward = CAMPAIGN_COMPLETION_XP[canonical_id]
	if reward is Array:
		out["clue_rewards"] = (reward as Array).duplicate()
	else:
		out["completion_xp"] = int(reward)
	return out

# Public pure lookup for the exact campaign lane.  A clue index is zero-based;
# passing an invalid index is deliberately not a hidden reward source.
static func campaign_completion_xp_for(recipe_id: String, clue_index: int = -1) -> int:
	var definition := campaign_completion_xp_definition(recipe_id)
	if definition.is_empty():
		return 0
	if String(definition.get("kind", "")) == "clue":
		var rewards: Array = definition.get("clue_rewards", [])
		if clue_index < 0 or clue_index >= rewards.size():
			return 0
		return maxi(0, int(rewards[clue_index]))
	return maxi(0, int(definition.get("completion_xp", 0)))

# Rebind a still-unused materialized Chart to the exact next clue reward. This
# is deliberately data-owned because the clue index selects an authored total,
# not a runtime formula. CampaignData has already established Chart-instance
# eligibility before callers reach this seam.
static func campaign_completion_reward_for_clue(recipe_id: String,
		clue: Dictionary) -> Dictionary:
	var definition := campaign_completion_xp_definition(recipe_id)
	if String(definition.get("kind", "")) != "clue":
		return {}
	var chapter_id := String(clue.get("chapter_id", ""))
	if chapter_id == "" or CampaignData.chapter_for_recipe(recipe_id) != chapter_id:
		return {}
	var chapter: Dictionary = CampaignData.CHAPTERS.get(chapter_id, {})
	var clue_index := (chapter.get("clue_ids", []) as Array).find(
		String(clue.get("clue_id", "")))
	if clue_index < 0:
		return {}
	return {"kind": "clue", "recipe_id": recipe_id,
		"chapter_id": chapter_id, "clue_id": String(clue.get("clue_id", "")),
		"presentation": String(clue.get("presentation", "")),
		"xp": campaign_completion_xp_for(recipe_id, clue_index)}

# First discovery defaults to the shipped 50 Wayfinding XP.  Campaign roads
# opt out in authored data; this keeps source lessons and table experiments
# from disturbing the exact level-20-to-23 lane.
static func recipe_discovery_xp(recipe_id: String) -> int:
	var definition := campaign_completion_xp_definition(recipe_id)
	if definition.is_empty():
		return 50
	return maxi(0, int(definition.get("discovery_xp", 50)))
const CHART_RECIPE_ORDER := ["snug", "green_hollow", "first_knot_boss", "sallow_shallows",
	"deep_hollow", "briar_maze", "sallow_mire", "golden_wallow_boss",
	"seventh_road_boss", "summit_approach", "queens_summit_boss",
	"pale_veins", "pale_oath_boss", "ashen_bough", "fire_in_the_bough_boss",
	"root_below", "unwritten_road_boss", "first_knot_reprise", "queens_summit"]
# The ordinary physical Table never resolves the retired handoff recipe.
# Keep it in the Codex order above so players with an already-materialized
# Chart retain its historical record, and in the compatibility order below so
# the frozen template-tray adapter can finish its old lifecycle.
const TABLE_RECIPE_ORDER := ["snug", "green_hollow", "first_knot_boss", "sallow_shallows",
	"deep_hollow", "briar_maze", "sallow_mire", "golden_wallow_boss",
	"seventh_road_boss", "summit_approach", "queens_summit_boss",
	"pale_veins", "pale_oath_boss", "ashen_bough", "fire_in_the_bough_boss",
	"root_below", "unwritten_road_boss", "first_knot_reprise"]

# Slice C1 — authored presentation for every current Chart Recipe. A rumour
# may name materials and relationships, but never carries the exact pattern;
# exact ghost layouts are exposed only through known_draft().
const CHART_RUMOURS := {
	"mara_first_leaf": {
		"recipe_id": "snug",
		"source": "Mara's first lesson",
		"summary": "Three small makings draw one kind road.",
		"riddle": "A little leaf, a green heading, and the gentlest ink.",
		"clues": ["a small leaf", "a green heading", "one gentle Ink"],
	},
	"mara_first_loop": {
		"recipe_id": "green_hollow",
		"source": "Mara's marginal note",
		"summary": "A familiar heading can wander when the page and cord allow it.",
		"riddle": "Keep the hedge above you. Give it a broader page, then loop the road at its left hand.",
		"clues": ["the same green heading", "a broader page", "a looped cord"],
	},
	"mara_first_knot": {
		"recipe_id": "first_knot_boss",
		"source": "Three Thorn Whispers",
		"summary": "A familiar green road can be pressed toward one named den.",
		"riddle": "Lay the kind green road again. Set the thorn's essence beneath it, where Mara's seal wakes.",
		"clues": ["the familiar green road", "the Seal cell", "thorn essence"],
	},
	"atlas_sallow_shallows": {
		"recipe_id": "sallow_shallows",
		"source": "The Living Atlas wet-road mark",
		"summary": "A short wet road has begun to show beyond the First Knot.",
		"riddle": "Set a mire reed above a field page. Loop the road left, and keep it green enough to read.",
		"clues": ["a mire reed", "a field page", "a looped cord", "one Hedge Ink"],
	},
	"atlas_deep_hollow": {
		"recipe_id": "deep_hollow",
		"source": "A faded Atlas panel",
		"summary": "Stitching holds a longer Bramblewood road together.",
		"riddle": "The hedge stays true, but the page is sewn and the road is stitched deep.",
		"clues": ["a hedge heading", "a stitched page", "a hollow stitch"],
	},
	"atlas_briar_knot": {
		"recipe_id": "briar_maze",
		"source": "A thorn-scratched Atlas panel",
		"summary": "A thorn mark and a hard knot draw a tangled road.",
		"riddle": "Rub the thorn's memory onto a sewn page. Let a briar knot choose every turning.",
		"clues": ["a thorn rubbing", "a stitched page", "a briar knot"],
	},
	"mara_sallow_reed": {
		"recipe_id": "sallow_mire",
		"source": "Mara's rain-stained note",
		"summary": "Wax, reed, and a sunken knot keep a road through wet ground.",
		"riddle": "A mire reed points where dry ink cannot. Wax the page and sink the binding low.",
		"clues": ["a mire reed", "a waxed page", "a sunken knot"],
	},
	"golden_wallow_boss": {
		"recipe_id": "golden_wallow_boss",
		"source": "Three Gilt Bristles",
		"summary": "Three bristles point to one wallow rooted around bright old nails.",
		"riddle": "Wax the wet road, sink its knot, and lay the old tusk in Mara's Seal. Wildcraft 10 can stir the Mire Ink that keeps the promise from running.",
		"clues": ["a mire reed", "a waxed page", "a sunken knot", "Mire Ink at Wildcraft 10", "the Tusker Tusk Seal"],
	},
	"seventh_road_boss": {
		"recipe_id": "seventh_road_boss",
		"source": "Four Cold Tracks",
		"summary": "Four cold signs agree on a seventh road through the briars.",
		"riddle": "Set the Briar road as the Atlas taught it. Mothglow keeps the seventh turning visible; the Wightpelt asks its guardian to wait there.",
		"clues": ["a thorn rubbing", "a stitched page", "a briar knot",
			"Mothglow Ink at Wildcraft 14", "the Wightpelt Seal"],
	},
	"atlas_crown_road": {
		"recipe_id": "queens_summit",
		"source": "The Atlas crown panel",
		"summary": "The Summit road repeats its track and binding before it climbs.",
		"riddle": "Two cold tracks climb one heavy folio. Bind the ascent at both hands, and set the Alpha's Fang where the Seal wakes.",
		"clues": ["two matching cold tracks", "a heavy folio", "two climbing cords",
			"the Alpha's Fang Seal"],
	},
	"skald_crownward_ascent": {
		"recipe_id": "summit_approach",
		"source": "The Skald Archive",
		"summary": "The Archive's cold folio names a climb beyond the Wolf's keeping.",
		"riddle": "Lay two cold tracks over the heavy folio and bind them at either hand. A single Refined Ink keeps the crown-road from closing behind you.",
		"clues": ["two matching cold tracks", "a heavy folio", "two climbing cords",
			"one Refined Ink"],
	},
	"queens_summit_boss": {
		"recipe_id": "queens_summit_boss",
		"source": "Four Shed Crown-Thorns",
		"summary": "Four thorn-sheddings agree that the old crown has a keeper.",
		"riddle": "Keep the first cold track at the northwest. A thorn rubbing takes the north; the folio and paired climbing cords hold the rest. Refined Ink and the Alpha's Fang make the promise answer.",
		"clues": ["a cold track at the northwest", "a thorn rubbing to the north",
			"a heavy folio", "two climbing cords", "one Refined Ink",
			"the Alpha's Fang Seal"],
	},
	"skald_pale_oath": {
		"recipe_id": "pale_veins",
		"source": "The Skald Archive's pale folio",
		"summary": "A wellmark and paired cords lead beneath the roots.",
		"riddle": "Set the Pale Wellmark above the Atlas Folio. Bind the road at both hands, and let one Stoneground Ink hold the line.",
		"clues": ["a Pale Wellmark", "an Atlas Folio", "two climbing cords",
			"one Stoneground Ink"],
	},
	"skald_pale_oath_boss": {
		"recipe_id": "pale_oath_boss",
		"source": "The Skald Archive's second pale folio",
		"summary": "Four returned rubbings name the barrow's nailed promise.",
		"riddle": "Keep the Barrow Mark northwest. The Pale Wellmark holds north and the Cold Track northeast; the Nail wakes in the Seal.",
		"clues": ["a Barrow Mark", "a Pale Wellmark", "a Cold Track",
			"an Atlas Folio", "two climbing cords", "one Stoneground Ink",
		"the Oath Nail Seal"],
	},
	"rootroad_lift_ashen_bough": {
		"recipe_id": "ashen_bough",
		"source": "The Rootroad Lift's lower landing",
		"summary": "The relit lift opens onto a branch that remembers a banked fire.",
		"riddle": "Ash at the northwest, cinder at the north, ember at the northeast. Bind the west of an Ember Folio; one Ash Ink keeps the branch from cooling shut.",
		"clues": ["an Ash Mark", "a Cinder Waymark", "an Ember Mark",
			"a Cinder Binding", "an Ember Folio", "one Ash Ink"],
	},
	"fire_in_the_bough_boss": {
		"recipe_id": "fire_in_the_bough_boss",
		"source": "Five Ember Verses",
		"summary": "Five returned verses name the hearth where a giant still guards the banked fire.",
		"riddle": "Furnace northwest, cinder north, soot northeast. Bind the west of the Ember Folio; Emberleaf Ink and the Starheart Coal make the old hearth answer.",
		"clues": ["a Furnace Mark", "a Cinder Waymark", "a Soot Track",
			"a Cinder Binding", "an Ember Folio", "one Emberleaf Ink",
			"the Starheart Coal Seal"],
	},
	"threefold_loom_root_below": {
		"recipe_id": "root_below",
		"source": "The Threefold Loom's first stirring",
		"summary": "One remembered tracing can be laid beneath the old knots without fixing the road forever.",
		"riddle": "Set one Lost-Waymark Tracing above a Nine-Knot Leaf. A Threefold Binding at the west and one ordinary Hedge Ink leave room for what has not yet been named.",
		"clues": ["a Nine-Knot Leaf", "a Lost-Waymark Tracing",
			"a Threefold Binding", "one Hedge Ink"],
	},
	"unwritten_road_boss": {
		"recipe_id": "unwritten_road_boss",
		"source": "The Map of Nine Knots",
		"summary": "The whole arrangement does not own the roads it remembers; it only gives one new road leave to exist.",
		"riddle": "Three Lost-Waymark Tracings crown the Nine-Knot Leaf. Bind both hands with Threefold Bindings, set the Wyrm Scale in the Seal, and let one ordinary Hedge Ink hold the line. The Map and all six Root Runes must answer from their own keeping.",
		"clues": ["a Nine-Knot Leaf", "three Lost-Waymark Tracings",
			"two Threefold Bindings", "one Hedge Ink", "the Wyrm Scale Seal",
			"the Map of Nine Knots", "all six Root Runes"],
	},
	"first_knot_reprise": {
		"recipe_id": "first_knot_reprise",
		"source": "The First Knot, remembered",
		"summary": "A cleared thorn-road can be walked again, deeper than before.",
		"riddle": "Set the familiar green road between two looped cords. The thorn waits beneath, but no debt follows.",
		"clues": ["the familiar green road", "two matching loop cords", "a spent thorn essence"],
	},
}
const CHART_RUMOUR_ORDER := ["mara_first_leaf", "mara_first_loop", "mara_first_knot",
	"atlas_sallow_shallows", "atlas_deep_hollow", "atlas_briar_knot",
	"mara_sallow_reed", "golden_wallow_boss", "seventh_road_boss",
	"skald_crownward_ascent", "queens_summit_boss", "first_knot_reprise",
	"skald_pale_oath", "skald_pale_oath_boss", "rootroad_lift_ashen_bough",
	"fire_in_the_bough_boss", "threefold_loom_root_below", "unwritten_road_boss",
	"atlas_crown_road"]

# The campaign ledger owns these clue ids; this content registry owns their
# four distinct world-reading identities. They deliberately do not use the
# physical `cold_track` component id, so a banked fact can never masquerade as
# a spendable Waymark in the Satchel or at the Table.
const SEVENTH_ROAD_COLD_TRACK_PRESENTATIONS := {
	"seventh_road_cold_track_1": {
		"presentation": "cold_track_clue", "title": "A Cold Track — First Sign",
		"pages": ["Frost rims one heel-mark where the briars have not been bent.",
			"It points between two roads the Atlas already knows."],
	},
	"seventh_road_cold_track_2": {
		"presentation": "cold_track_clue", "title": "A Cold Track — Second Sign",
		"pages": ["A wolf's print crosses the old path, then carries on over bare stone.",
			"Linnet circles once above the place where it vanishes."],
	},
	"seventh_road_cold_track_3": {
		"presentation": "cold_track_clue", "title": "A Cold Track — Third Sign",
		"pages": ["Six scratches mark six ordinary turnings. A seventh has gathered frost.",
			"The pale line shows only while the fog is looking elsewhere."],
	},
	"seventh_road_cold_track_4": {
		"presentation": "cold_track_clue", "title": "A Cold Track — The Road Agrees",
		"pages": ["The four signs settle into one patient trail.",
			"Whatever waits there has been guarding the turning, not hunting the village."],
	},
}

# The Crown-Thorns are campaign ledger facts, not a fifth kind of physical
# table Waymark. Each reading is distinct copy, while CampaignData owns the
# bounded four-return banking rule and the host-only settlement transition.
const QUEENS_SUMMIT_SHED_CROWN_THORN_PRESENTATIONS := {
	"shed_crown_thorn_1": {
		"presentation": "shed_crown_thorn", "title": "A Shed Crown-Thorn — First",
		"pages": ["A thorn as pale as old bone has fallen where no branch reaches.",
			"Its hollow points uphill, as if the crown itself had been climbing."],
	},
	"shed_crown_thorn_2": {
		"presentation": "shed_crown_thorn", "title": "A Shed Crown-Thorn — Second",
		"pages": ["Frost gathers inside the thorn's split, though the stone around it is dry.",
			"A thin root runs from the split toward the summit's closed door."],
	},
	"shed_crown_thorn_3": {
		"presentation": "shed_crown_thorn", "title": "A Shed Crown-Thorn — Third",
		"pages": ["The thorn's barbs are filed smooth on one side, worn by a patient hand.",
			"The Archive's margin calls that hand a keeper, never a king."],
	},
	"shed_crown_thorn_4": {
		"presentation": "shed_crown_thorn", "title": "A Shed Crown-Thorn — The Crown Answers",
		"pages": ["Four pale thorns settle into a circle on the folio's blank crown.",
			"At its centre, a road opens for the Fang and the promise it remembers."],
	},
}

# Lost Waymarks are campaign-ledger readings, never physical Tracings or a
# second award. Their renewable Table counterpart has its own material id.
const UNWRITTEN_LOST_WAYMARK_PRESENTATIONS := {
	"lost_waymark_1": {
		"presentation": "lost_waymark", "title": "A Lost Waymark — First Thread",
		"pages": ["A pale mark waits beneath the root, its line still open.",
			"The Loom remembers the road without taking it from you."],
	},
	"lost_waymark_2": {
		"presentation": "lost_waymark", "title": "A Lost Waymark — Second Thread",
		"pages": ["Three old turns meet here and none has tightened shut.",
			"A tracing may follow the mark; the mark itself remains."],
	},
	"lost_waymark_3": {
		"presentation": "lost_waymark", "title": "A Lost Waymark — Third Thread",
		"pages": ["Root-sap has sealed the edge of a road no atlas carried.",
			"Its patient line points onward, not back to a prize."],
	},
	"lost_waymark_4": {
		"presentation": "lost_waymark", "title": "A Lost Waymark — Fourth Thread",
		"pages": ["A knot loosens when you read it aloud beneath the old roots.",
			"The road asks only to be kept, not spent."],
	},
	"lost_waymark_5": {
		"presentation": "lost_waymark", "title": "A Lost Waymark — The Loom Stirs",
		"pages": ["Five remembered lines settle around one unfinished centre.",
			"Somewhere above, the Threefold Loom begins to stir."],
	},
}

# Slice C2 — deterministic world-source contracts. World adapters name only a
# source id; this registry owns its rumour, read threshold, target recipe, and
# bounded one-attempt lesson kit. Kits contain ordinary Chart components only.
const CHART_SOURCES := {
	"atlas_sallow_shallows": {
		"rumour_id": "atlas_sallow_shallows", "recipe_id": "sallow_shallows",
		"min_wayfinding": 9, "requires_first_knot_clear": true,
		"lesson_components": {
			"field_parchment": 1, "mire_reed": 1, "loop_cord": 1,
		},
		"toast": "The Atlas shows a wet road through the Sallow shallows.",
	},
	"atlas_deep_hollow": {
		"rumour_id": "atlas_deep_hollow", "recipe_id": "deep_hollow",
		"min_wayfinding": 6,
		"lesson_components": {
			"hedge_sprig": 1, "stitched_parchment": 1, "hollow_stitch": 1,
		},
		"toast": "A faded Atlas note settles into the Codex.",
	},
	"mara_sallow_reed": {
		"rumour_id": "mara_sallow_reed", "recipe_id": "sallow_mire",
		"min_wayfinding": 12,
		"lesson_components": {
			"waxed_vellum": 1, "mire_reed": 1, "sunk_knot": 1,
		},
		"toast": "Mara's rain-stained note settles into the Codex.",
	},
	"atlas_briar_knot": {
		"rumour_id": "atlas_briar_knot", "recipe_id": "briar_maze",
		"min_wayfinding": 15, "requires_golden_wallow_clear": true,
		# Game applies this declarative kit as a top-up, never an unconditional
		# award. Keeping the policy beside the authored amounts makes that promise
		# inspectable without giving this registry mutation authority.
		"lesson_grant_policy": "missing_only",
		"lesson_components": {
			"thorn_rubbing": 1, "stitched_parchment": 1, "briar_knot": 1,
		},
		"toast": "The Atlas finds a thorn-road beyond the relit Jetty.",
	},
	"skald_queens_summit": {
		"rumour_id": "skald_crownward_ascent", "recipe_id": "summit_approach",
		"min_wayfinding": 16, "requires_seventh_road_clear": true,
		"lesson_grant_policy": "missing_only",
		"lesson_components": {
			"atlas_folio": 1, "cold_track": 2, "climbing_cord": 2,
		},
		"toast": "The Skald Archive lays out a crownward climb beyond the Wolf's keeping.",
	},
	# Both Archive folios are host-side, canonical-Queen gated source
	# transactions. `lesson_components` is a missing-only target kit: it tops up
	# a complete attempt but never grants an additional Oath Nail.
	"skald_pale_oath": {
		"rumour_id": "skald_pale_oath", "recipe_id": "pale_veins",
		"min_wayfinding": 18,
		"requires_chapter_clear": CampaignData.QUEENS_SUMMIT,
		"lesson_grant_policy": "missing_only",
		"lesson_components": {"pale_wellmark": 1, "atlas_folio": 1,
			"climbing_cord": 2},
		"lesson_inks": {"stoneground_ink": 1},
		"toast": "The Archive opens a pale folio beneath the roots.",
	},
	"skald_pale_oath_boss": {
		"rumour_id": "skald_pale_oath_boss", "recipe_id": "pale_oath_boss",
		"min_wayfinding": 19,
		"requires_chapter_clear": CampaignData.QUEENS_SUMMIT,
		"requires_chapter_clue_count": {"chapter_id": CampaignData.PALE_OATH,
			"count": 4},
		"lesson_grant_policy": "missing_only",
		"lesson_components": {"barrow_mark": 1, "pale_wellmark": 1,
			"cold_track": 1, "atlas_folio": 1, "climbing_cord": 2},
		"lesson_inks": {"stoneground_ink": 1},
		"toast": "The fourth rubbing resolves into the Barrow Jarl's folio.",
	},
	# The Lift is a physical lesson, not a supply drawer. Its controller owns
	# the lower-landing animation and the host-only exact-once read; this source
	# carries no components, Inks, or Chart grant and remains generic to Game.
	"rootroad_lift_ashen_bough": {
		"rumour_id": "rootroad_lift_ashen_bough", "recipe_id": "ashen_bough",
		"min_wayfinding": 20,
		"requires_chapter_clear": CampaignData.PALE_OATH,
		"grant_recipe_knowledge": true,
		"discovery_provenance": "source_lesson",
		"lesson_grant_policy": "none",
		"lesson_components": {}, "lesson_inks": {},
		"toast": "The Rootroad Lift lowers into an ash-warm branch.",
	},
	"rootroad_lift_hearth_giant": {
		"rumour_id": "fire_in_the_bough_boss", "recipe_id": "fire_in_the_bough_boss",
		"min_wayfinding": 21,
		"requires_chapter_clear": CampaignData.PALE_OATH,
		"requires_chapter_clue_count": {"chapter_id": CampaignData.FIRE_IN_THE_BOUGH,
		"count": 5},
		"grant_recipe_knowledge": true,
		"discovery_provenance": "source_lesson",
		"lesson_grant_policy": "none",
		"lesson_components": {}, "lesson_inks": {},
		"toast": "The fifth ember verse settles into a furnace folio.",
	},
	"threefold_loom_root_below": {
		"rumour_id": "threefold_loom_root_below", "recipe_id": "root_below",
		"min_wayfinding": 22,
		"requires_chapter_clear": CampaignData.FIRE_IN_THE_BOUGH,
		"grant_recipe_knowledge": true,
		"discovery_provenance": "source_lesson",
		"lesson_grant_policy": "missing_only",
		"lesson_components": {"nine_knot_leaf": 1,
			"lost_waymark_tracing": 1, "threefold_binding": 1},
		"lesson_inks": {},
		"toast": "The Threefold Loom opens one patient road below.",
	},
}
const CHART_SOURCE_ORDER := ["atlas_sallow_shallows", "atlas_deep_hollow",
	"mara_sallow_reed", "atlas_briar_knot", "skald_queens_summit",
	"skald_pale_oath", "skald_pale_oath_boss", "rootroad_lift_ashen_bough",
	"rootroad_lift_hearth_giant", "threefold_loom_root_below"]
const CHART_DISCOVERY_PROVENANCE := ["mara_lesson", "source_lesson", "table_experiment", "legacy"]
const CHART_DISCOVERY_SOURCE := {
	"mara_lesson": "Mara's lesson",
	"source_lesson": "Read from an authored world source",
	"table_experiment": "Found by experiment",
	"legacy": "Known before Mara reopened the Codex",
}
const CHART_DISCOVERY_HISTORY := {
	"mara_lesson": "Learned in Mara's first lesson.",
	"source_lesson": "Learned from an authored folio in the world.",
	"table_experiment": "First set down at Mara's table.",
	"legacy": "Earlier working.",
}

static func empty_recipe_journal() -> Dictionary:
	return {"rumours": [], "discoveries": {}}

static func fresh_recipe_journal() -> Dictionary:
	return {"rumours": [], "discoveries": {"snug": "mara_lesson"}}

# Optional-save normalizer for unlocked-but-unread world sources. Unknown,
# malformed, and duplicate ids are discarded in authored order.
static func normalize_chart_source_unlocks(raw_unlocks) -> Array:
	var seen := {}
	if raw_unlocks is Array:
		for source_id_v in raw_unlocks:
			var source_id := String(source_id_v)
			if CHART_SOURCES.has(source_id):
				seen[source_id] = true
	var out: Array = []
	for source_id in CHART_SOURCE_ORDER:
		if seen.has(source_id):
			out.append(source_id)
	return out

# Pure, bounded save normalizer. known_recipe_ids remains the sole authority:
# journal records are retained only for known recipes and missing provenance is
# filled as legacy without ever changing the supplied knowledge set.
static func normalize_recipe_journal(raw_journal, known_recipe_ids: Array) -> Dictionary:
	var raw: Dictionary = raw_journal if raw_journal is Dictionary else {}
	var rumours: Array = []
	var seen_rumours := {}
	var raw_rumours = raw.get("rumours", [])
	if raw_rumours is Array:
		for rumour_id_v in raw_rumours:
			var rumour_id := String(rumour_id_v)
			if CHART_RUMOURS.has(rumour_id) and not seen_rumours.has(rumour_id):
				rumours.append(rumour_id)
				seen_rumours[rumour_id] = true
	var known := {}
	for recipe_id_v in known_recipe_ids:
		var recipe_id := String(recipe_id_v)
		if CHART_RECIPES.has(recipe_id):
			known[recipe_id] = true
	var raw_discoveries = raw.get("discoveries", {})
	var discoveries := {}
	for recipe_id in CHART_RECIPE_ORDER:
		if not known.has(recipe_id):
			continue
		var provenance := ""
		if raw_discoveries is Dictionary:
			provenance = String((raw_discoveries as Dictionary).get(recipe_id, ""))
		if provenance not in CHART_DISCOVERY_PROVENANCE:
			provenance = "legacy"
		discoveries[recipe_id] = provenance
	return {"rumours": rumours, "discoveries": discoveries}

static func journal_with_rumour(journal: Dictionary, rumour_id: String,
		known_recipe_ids: Array) -> Dictionary:
	var out := normalize_recipe_journal(journal, known_recipe_ids)
	if CHART_RUMOURS.has(rumour_id) and not (out.rumours as Array).has(rumour_id):
		(out.rumours as Array).append(rumour_id)
	return out

static func journal_with_discovery(journal: Dictionary, recipe_id: String,
		provenance: String, known_recipe_ids: Array) -> Dictionary:
	var out := normalize_recipe_journal(journal, known_recipe_ids)
	if CHART_RECIPES.has(recipe_id) and known_recipe_ids.has(recipe_id) \
			and provenance in CHART_DISCOVERY_PROVENANCE:
		(out.discoveries as Dictionary)[recipe_id] = provenance
	return out

static func _recipe_rumour_ids(recipe_id: String) -> Array:
	var out: Array = []
	for rumour_id in CHART_RUMOUR_ORDER:
		if String((CHART_RUMOURS[rumour_id] as Dictionary).recipe_id) == recipe_id:
			out.append(rumour_id)
	return out

static func _recipe_has_makings(recipe_id: String, context: Dictionary) -> bool:
	if not CHART_RECIPES.has(recipe_id):
		return false
	var recipe: Dictionary = CHART_RECIPES[recipe_id]
	var level := int(context.get("level", 1))
	if level < int(recipe.req_wayfinding):
		return false
	if int(context.get("wildcraft_level", 1)) < int(recipe.get("req_wildcraft", 1)):
		return false
	if bool(recipe.get("requires_first_knot_clear", false)) \
			and not CampaignData.chapter_cleared(context.get("campaign_state", {}),
				CampaignData.FIRST_KNOT):
		return false
	var unlocks := table_unlocks(context)
	for slot_v in (recipe.pattern as Dictionary):
		var slot := String(slot_v)
		if not bool((unlocks.grid[slot] as Dictionary).unlocked):
			return false
	var required := {}
	for component_id_v in (recipe.pattern as Dictionary).values():
		var component_id := String(component_id_v)
		required[component_id] = int(required.get(component_id, 0)) + 1
	for ink_id_v in recipe.get("required_inks", []):
		var ink_id := String(ink_id_v)
		required[ink_id] = int(required.get(ink_id, 0)) + 1
	var required_seal := String(recipe.get("required_seal", ""))
	if required_seal != "":
		required[required_seal] = int(required.get(required_seal, 0)) + 1
		if not _seal_use_allowed(context, required_seal, recipe_id):
			return false
		if not CampaignData.can_inscribe_boss(context.get("campaign_state", {}),
			recipe_id, level, int(context.get("wildcraft_level", 1))):
			return false
	var materials: Dictionary = context.get("material_counts", {})
	for material_id in required:
		if int(materials.get(material_id, 0)) < int(required[material_id]):
			return false
	return true

# Knowledge and readiness are deliberately separate. `state` is convenient
# presentation, while knowledge_state is the durable Unknown/Rumoured/Known
# truth and makings_in_hand is a transient ownership calculation.
static func recipe_status(recipe_id: String, context: Dictionary) -> Dictionary:
	if not CHART_RECIPES.has(recipe_id):
		return {"state": "unknown", "knowledge_state": "unknown",
			"makings_in_hand": false}
	var known := (context.get("known_recipe_ids", []) as Array).has(recipe_id)
	var journal := normalize_recipe_journal(context.get("recipe_journal", {}),
		context.get("known_recipe_ids", []))
	var rumoured := false
	for rumour_id in _recipe_rumour_ids(recipe_id):
		if (journal.rumours as Array).has(rumour_id):
			rumoured = true
			break
	var makings := _recipe_has_makings(recipe_id, context)
	var knowledge_state := "known" if known else "rumoured" if rumoured else "unknown"
	var state := knowledge_state
	if state == "unknown" and makings:
		state = "attemptable"
	return {"state": state, "knowledge_state": knowledge_state,
		"makings_in_hand": makings}

static func known_draft(recipe_id: String, context: Dictionary) -> Dictionary:
	if not CHART_RECIPES.has(recipe_id) \
			or not (context.get("known_recipe_ids", []) as Array).has(recipe_id):
		return {}
	var recipe: Dictionary = CHART_RECIPES[recipe_id]
	var grid: Dictionary = (recipe.pattern as Dictionary).duplicate(true)
	var required_seal := String(recipe.get("required_seal", ""))
	if required_seal != "":
		grid["s"] = required_seal
	return {"grid": grid,
		"ink_rail": (recipe.get("required_inks", []) as Array).duplicate()}

static func codex_entry(recipe_id: String, context: Dictionary) -> Dictionary:
	var status := recipe_status(recipe_id, context)
	var state := String(status.state)
	var entry := {
		"id": recipe_id, "recipe_id": recipe_id,
		"state": state, "knowledge_state": String(status.knowledge_state),
		"makings_in_hand": bool(status.makings_in_hand),
		"label": "Unknown road", "title": "Unknown road", "summary": "",
		"source": "", "history": "", "provenance": "", "clues": [], "output": {},
		"ghost_draft": {}, "pattern": {}, "required_inks": [],
	}
	if state == "attemptable":
		entry.label = "A road is taking shape"
		entry.title = "A road is taking shape"
		entry.summary = "The makings are in hand, but the arrangement is still yours to find."
		return entry
	if state == "rumoured":
		for rumour_id in _recipe_rumour_ids(recipe_id):
			if not ((normalize_recipe_journal(context.get("recipe_journal", {}),
					context.get("known_recipe_ids", [])).rumours as Array).has(rumour_id)):
				continue
			var rumour: Dictionary = CHART_RUMOURS[rumour_id]
			entry.label = "Rumoured road"
			entry.title = "Rumoured road"
			entry.summary = String(rumour.riddle)
			entry.source = String(rumour.source)
			entry.history = "A note in Mara's Codex."
			entry.clues = (rumour.clues as Array).duplicate()
			break
		return entry
	if state != "known":
		return entry
	var recipe: Dictionary = CHART_RECIPES[recipe_id]
	var template_id := String((recipe.output as Dictionary).template_id)
	var title := String((recipe.output as Dictionary).get("name",
		(TEMPLATES.get(template_id, {}) as Dictionary)
			.get("name", recipe_id.capitalize())))
	var journal := normalize_recipe_journal(context.get("recipe_journal", {}),
		context.get("known_recipe_ids", []))
	var provenance := String((journal.discoveries as Dictionary).get(recipe_id, "legacy"))
	var draft := known_draft(recipe_id, context)
	entry.label = title
	entry.title = title
	entry.summary = String((TEMPLATES.get(template_id, {}) as Dictionary).get("desc", ""))
	entry.source = String(CHART_DISCOVERY_SOURCE.get(provenance, ""))
	entry.history = String(CHART_DISCOVERY_HISTORY.get(provenance, ""))
	entry.provenance = provenance
	entry.output = (recipe.output as Dictionary).duplicate(true)
	entry.ghost_draft = draft.duplicate(true)
	entry.pattern = (draft.get("grid", {}) as Dictionary).duplicate(true)
	entry.required_inks = (recipe.get("required_inks", []) as Array).duplicate()
	return entry

static func codex_entries(context: Dictionary) -> Array:
	var out: Array = []
	for recipe_id in CHART_RECIPE_ORDER:
		out.append(codex_entry(recipe_id, context))
	return out

const LEGACY_TEMPLATE_TO_RECIPE := {
	"snug": "snug",
	"tier_1": "green_hollow",
	"hollow": "deep_hollow",
	"briar_maze": "briar_maze",
	"mire": "sallow_mire",
	"summit": "queens_summit",
}

static func recipe_id_for_template(template_id: String) -> String:
	return String(LEGACY_TEMPLATE_TO_RECIPE.get(template_id, ""))

static func legacy_recipe_ids_for_level(wayfinding_level: int) -> Array:
	var out: Array = []
	for template_id in TEMPLATE_ORDER:
		var recipe_id := recipe_id_for_template(String(template_id))
		if recipe_id == "":
			continue
		var recipe: Dictionary = CHART_RECIPES[recipe_id]
		if wayfinding_level >= int(recipe.req_wayfinding):
			out.append(recipe_id)
	return out

static func starting_recipe_ids() -> Array:
	# Slice B starts with one readable road. Green Hollow is learned by making
	# the first-return arrangement, not granted merely for being level 1.
	return ["snug"]

static func empty_table_draft() -> Dictionary:
	return {"grid": {}, "ink_rail": []}

static func table_unlocks(wayfinding_context: Dictionary) -> Dictionary:
	var level := int(wayfinding_context.get("level", 1))
	var first_returned := bool(wayfinding_context.get("first_snug_returned", false))
	var grid := {}
	for slot in TABLE_SLOT_ORDER:
		var req := int(TABLE_SLOT_UNLOCK_LEVELS[slot])
		var milestone := ""
		var unlocked := level >= req
		if slot == "w":
			milestone = "first_snug_return"
			unlocked = first_returned
		if bool(wayfinding_context.get("compatibility_mode", false)):
			unlocked = true
		grid[slot] = {
			"kind": String(COMPONENT_SLOT_KINDS[slot]),
			"unlocked": unlocked,
			"level": req,
			"milestone": milestone,
		}
	var rail: Array = []
	for index in INK_RAIL_UNLOCK_LEVELS.size():
		rail.append({"index": index,
			"unlocked": bool(wayfinding_context.get("compatibility_mode", false)) \
				or level >= int(INK_RAIL_UNLOCK_LEVELS[index]),
			"level": int(INK_RAIL_UNLOCK_LEVELS[index])})
	return {"grid": grid, "ink_rail": rail}

static func component_supply_price(component_id: String) -> int:
	return int(MARA_SUPPLY_PRICES.get(component_id, 0))

static func component_supply_ids(wayfinding_context: Dictionary) -> Array:
	var allowed := {}
	for recipe_id_v in wayfinding_context.get("known_recipe_ids", []):
		var recipe_id := String(recipe_id_v)
		if not CHART_RECIPES.has(recipe_id):
			continue
		for component_id_v in (CHART_RECIPES[recipe_id].pattern as Dictionary).values():
			var component_id := String(component_id_v)
			if COMPONENTS.has(component_id) and MARA_SUPPLY_PRICES.has(component_id):
				allowed[component_id] = true
	var out: Array = []
	for component_id in COMPONENT_ORDER:
		if allowed.has(component_id):
			out.append(component_id)
	return out

# Components the player may stage right now. Renewable stock remains gated by
# component_supply_ids(); this broader list lets an owned lesson piece stay
# visible before its arrangement has been discovered.
static func component_stageable_ids(wayfinding_context: Dictionary) -> Array:
	var allowed := {}
	for component_id_v in component_supply_ids(wayfinding_context):
		allowed[String(component_id_v)] = true
	for component_id_v in wayfinding_context.get("owned_component_ids", []):
		var component_id := String(component_id_v)
		if COMPONENTS.has(component_id):
			allowed[component_id] = true
	if bool(wayfinding_context.get("first_snug_returned", false)):
		for component_id_v in (CHART_RECIPES.green_hollow.pattern as Dictionary).values():
			var component_id := String(component_id_v)
			if COMPONENTS.has(component_id):
				allowed[component_id] = true
	var out: Array = []
	for component_id in COMPONENT_ORDER:
		if allowed.has(component_id):
			out.append(component_id)
	return out


# Chart components, deliberate encounter seals, and non-Ink template costs
# belong on the Chart Table, never in Quill's experiment pot. Deriving the last
# group from authored base costs keeps story keys such as Alpha's Fang protected
# when future Chart families add their own nonrenewable keys.
static func is_protected_chart_supply(material_id: String) -> bool:
	if COMPONENTS.has(material_id) or TROPHY_TO_AFFIX.has(material_id) \
			or STORY_SEALS.has(material_id):
		return true
	if INKS.has(material_id):
		return false
	for template_id in TEMPLATE_ORDER:
		var base_cost: Dictionary = TEMPLATES[template_id].get("base_cost", {})
		if base_cost.has(material_id):
			return true
	return false


static func is_chart_seal(material_id: String) -> bool:
	return TROPHY_TO_AFFIX.has(material_id) or STORY_SEALS.has(material_id)

# One compatibility craft per already-known legacy recipe. Repeated inputs use
# the maximum needed by any one recipe, not a sum across the catalogue.
static func compatibility_component_bundle(recipe_ids: Array) -> Dictionary:
	var bundle := {}
	for recipe_id_v in recipe_ids:
		var recipe_id := String(recipe_id_v)
		if not CHART_RECIPES.has(recipe_id):
			continue
		var in_recipe := {}
		for component_id_v in (CHART_RECIPES[recipe_id].pattern as Dictionary).values():
			var component_id := String(component_id_v)
			if not COMPONENTS.has(component_id):
				continue
			var kind := String(COMPONENTS[component_id].kind)
			if kind not in ["base", "waymark", "binding"]:
				continue
			in_recipe[component_id] = int(in_recipe.get(component_id, 0)) + 1
		for component_id in in_recipe:
			bundle[component_id] = maxi(int(bundle.get(component_id, 0)),
				int(in_recipe[component_id]))
	return bundle

static func _invalid_resolution(reason: String) -> Dictionary:
	return {
		"valid": false,
		"commit_ready": false,
		"state": "invalid",
		"recipe_id": "",
		"known": false,
		"output": {},
		"component_cost": {},
		"reagent_cost": {},
		"costs": {},
		"ordinary_costs": {},
		"requires_seal": false,
		"guaranteed": [],
		"affix_weights": {},
		"stability": {},
		"returned_on_failure": [],
		"campaign_contract": {},
		"handoff_contract": {},
		"depth_contract": {},
		"encounter_contract": {},
		"preparation_notes": [],
		"required_inks": [],
		"bias_inks": [],
		"bias_capacity": 0,
		"required_story_inputs": [],
		"present_story_inputs": [],
		"missing_story_inputs": [],
		"story_input_snapshot": [],
		"story_input_fingerprint": "",
		"story_witness_fingerprint": "",
		"story_witnesses": [],
		"fingerprint": "",
		"normalized_draft": empty_table_draft(),
		"unlocks": {},
		"reason": reason,
	}

static func _patterns_equal(a: Dictionary, b: Dictionary) -> bool:
	if a.size() != b.size():
		return false
	for slot in a:
		if not b.has(slot) or String(a[slot]) != String(b[slot]):
			return false
	return true

static func _pattern_is_subset(placed: Dictionary, authored: Dictionary) -> bool:
	for slot in placed:
		if not authored.has(slot) or String(placed[slot]) != String(authored[slot]):
			return false
	return true

# Deepening is a recipe-owned exact extension, rather than a generic
# same-Binding rule. Queen's Summit deliberately has no variant here: its two
# Climbing Cords are its base identity, not permission to add a layer.
static func _variant_pattern(recipe: Dictionary) -> Dictionary:
	var variant: Dictionary = recipe.get("deepening_variant", {})
	var out: Dictionary = (recipe.get("pattern", {}) as Dictionary).duplicate(true)
	if variant.is_empty():
		return out
	var slot := String(variant.get("binding_slot", ""))
	var binding_id := String(variant.get("binding_id", ""))
	if slot != "" and binding_id != "":
		out[slot] = binding_id
	return out

static func _depth_contract(recipe: Dictionary, template: Dictionary,
		variant: Dictionary = {}) -> Dictionary:
	var base_max_layers := int(template.get("max_layers", 1))
	if variant.is_empty():
		return {}
	var max_layers := base_max_layers + 1
	return {
		"variant_id": String(variant.get("variant_id", "")),
		"base_max_layers": base_max_layers,
		"max_layers": max_layers,
		"added_layer": max_layers,
		"hearth_layer": max_layers,
	}

static func _reprise_depth_contract(template: Dictionary) -> Dictionary:
	var base_max_layers := int(template.get("max_layers", 1))
	return {
		"variant_id": "first_knot_reprise",
		"base_max_layers": base_max_layers,
		"max_layers": 2,
		"added_layer": 2,
		"hearth_layer": 2,
	}

static func _reprise_encounter_contract() -> Dictionary:
	return {
		"boss_kind": "hedgemother",
		"boss_layer": 2,
		"reward_family_id": "first_knot_heirlooms",
		"suppress_chain_trophy": true,
	}

static func _normalize_table_draft(draft: Dictionary) -> Dictionary:
	var grid := {}
	var raw_grid: Dictionary = draft.get("grid", {})
	for slot_v in raw_grid:
		var component_id := String(raw_grid[slot_v])
		if component_id != "":
			grid[String(slot_v)] = component_id
	var rail: Array = []
	for ink_id_v in draft.get("ink_rail", []):
		rail.append(String(ink_id_v))
	while not rail.is_empty() and String(rail.back()) == "":
		rail.pop_back()
	return {"grid": grid, "ink_rail": rail}

# Campaign owns which permanent records are true. The Chart Table owns only
# this presentation-shaped projection, so a Map/Rune can never accidentally
# enter a grid cell or a material-cost map while the UI still has a stable,
# inspectable witness model to render.
static func _story_witness_fingerprint(required: Array, present: Array,
		missing: Array) -> String:
	return ("chart-story-witness-v1|required=%s|present=%s|missing=%s" % [
		",".join(required), ",".join(present), ",".join(missing),
	]).sha256_text()

static func _story_witness_row(row_id: String, label: String, required: Array,
		present: Array) -> Dictionary:
	var count := 0
	for story_id_v in required:
		if present.has(String(story_id_v)):
			count += 1
	return {
		"id": row_id,
		"kind": "story_witness",
		"name": label,
		"label": "%s · %d/%d" % [label, count, required.size()],
		"current": count,
		"required": required.size(),
		"complete": count == required.size(),
		"story_inputs": required.duplicate(),
	}

# A recipe declares permanent requirements by id. The Campaign is still the
# authority for their truth. The final recipe currently uses these two Rune
# groups plus the Map, but keeping the array data-shaped means later stories
# can adopt the same read-only interface without a second table protocol.
static func _story_witness_payload(recipe: Dictionary, context: Dictionary) -> Dictionary:
	var required: Array = (recipe.get("required_story_inputs", []) as Array).duplicate()
	if required.is_empty():
		return {
			"required_story_inputs": [], "present_story_inputs": [],
			"missing_story_inputs": [], "story_input_snapshot": [],
			"story_input_fingerprint": "", "story_witness_fingerprint": "",
			"story_witnesses": [],
		}
	var campaign_witness := CampaignData.required_story_inputs(
		context.get("campaign_state", {}))
	var present: Array = []
	for story_id_v in required:
		var story_id := String(story_id_v)
		if (campaign_witness.get("present_story_inputs", []) as Array).has(story_id):
			present.append(story_id)
	var missing: Array = []
	for story_id_v in required:
		var story_id := String(story_id_v)
		if not present.has(story_id):
			missing.append(story_id)
	var older_roads := ["green_root_rune", "mist_root_rune", "fang_root_rune"]
	var deeper_roads := ["crown_root_rune", "pale_root_rune", "ember_root_rune"]
	var map_row := ["map_of_nine_knots"]
	var rows := [
		_story_witness_row("older_roads", "Older Roads", older_roads, present),
		_story_witness_row("deeper_roads", "Deeper Roads", deeper_roads, present),
		_story_witness_row("map_of_nine_knots", "Map of Nine Knots", map_row, present),
	]
	var eligible := missing.is_empty()
	var snapshot: Array = required.duplicate() if eligible else []
	return {
		"required_story_inputs": required,
		"present_story_inputs": present,
		"missing_story_inputs": missing,
		"story_input_snapshot": snapshot,
		# Campaign's canonical snapshot fingerprint is what the final escrow
		# stores. The witness fingerprint also changes while the snapshot is
		# incomplete, ensuring every Map/Rune mutation stales a Table preview.
		"story_input_fingerprint": String(campaign_witness.get("story_input_fingerprint", "")),
		"story_witness_fingerprint": _story_witness_fingerprint(required, present, missing),
		"story_witnesses": rows,
	}

static func _table_fingerprint(draft: Dictionary, context: Dictionary) -> String:
	var parts: Array[String] = ["chart-table-v1"]
	var grid: Dictionary = draft.get("grid", {})
	for slot in TABLE_SLOT_ORDER:
		parts.append("%s=%s" % [slot, String(grid.get(slot, ""))])
	parts.append("inks=" + ",".join(draft.get("ink_rail", [])))
	parts.append("level=%d" % int(context.get("level", 1)))
	parts.append("first_return=%d" % int(bool(context.get("first_snug_returned", false))))
	parts.append("discount=%d" % int(context.get("hedge_discount", 0)))
	parts.append("stability=%0.6f" % float(context.get("stability_perk_bonus", 0.0)))
	parts.append("extra_inks=%d" % int(context.get("extra_ink_slots", 0)))
	parts.append("revision=%d" % int(context.get("revision", 0)))
	var known: Array = []
	for recipe_id in context.get("known_recipe_ids", []):
		known.append(String(recipe_id))
	known.sort()
	parts.append("known=" + ",".join(known))
	parts.append("campaign=" + CampaignData.campaign_fingerprint(
		context.get("campaign_state", {})))
	var story_witness := CampaignData.required_story_inputs(context.get("campaign_state", {}))
	parts.append("story-witness=" + _story_witness_fingerprint(
		story_witness.get("required_story_inputs", []),
		story_witness.get("present_story_inputs", []),
		story_witness.get("missing_story_inputs", [])))
	return "|".join(parts).sha256_text()

static func _merged_cost(a: Dictionary, b: Dictionary) -> Dictionary:
	var out := a.duplicate()
	for id in b:
		out[String(id)] = int(out.get(String(id), 0)) + int(b[id])
	return out

static func _required_and_bias_inks(rail: Array, required: Array) -> Dictionary:
	var remaining: Array = []
	for ink_id_v in rail:
		var ink_id := String(ink_id_v)
		if ink_id != "":
			remaining.append(ink_id)
	var missing: Array = []
	for required_id_v in required:
		var required_id := String(required_id_v)
		var index := remaining.find(required_id)
		if index < 0:
			missing.append(required_id)
		else:
			remaining.remove_at(index)
	return {"missing": missing, "bias": remaining}


static func _boss_display_name(boss_kind: String) -> String:
	match boss_kind:
		"burrow_boar": return "The Burrow Boar"
		"wolf_alpha": return "The Wolf Alpha"
		"hedgemother": return "The Hedgemother"
		"hedgemother_queen": return "The Hedgemother Queen"
		_: return boss_kind.replace("_", " ").capitalize()

# CampaignData owns whether a physical Seal is temporarily held for an authored
# chapter. Legacy resolvers sometimes pass only Wayfinding data, so omitting
# campaign_state intentionally keeps their historical behavior unchanged.
static func _seal_use_allowed(context: Dictionary, seal_id: String,
		recipe_id: String) -> bool:
	if seal_id == "" or not context.has("campaign_state"):
		return true
	var normalized := CampaignData.normalize_campaign_state(
		context.get("campaign_state", {}))
	return bool(CampaignData.seal_use_allowed(normalized, seal_id, recipe_id))

static func _validate_component_pattern(placed_components: Dictionary) -> String:
	for slot_v in placed_components:
		var slot := String(slot_v)
		var component_id := String(placed_components[slot_v])
		if not COMPONENT_SLOT_KINDS.has(slot):
			return "Unknown Chart Table slot: %s." % slot
		if not COMPONENTS.has(component_id):
			return "Unknown chart component: %s." % component_id
		var expected_kind := String(COMPONENT_SLOT_KINDS[slot])
		var actual_kind := String(COMPONENTS[component_id].kind)
		if expected_kind != actual_kind:
			return "%s does not belong in the %s slot." % [
				String(COMPONENTS[component_id].name), expected_kind]
	return ""

# Slice B's deep domain seam. It owns table normalization, unlocks, pattern
# state, required-vs-bias Ink, costs, and the immutable preview fingerprint.
static func preview_table(draft: Dictionary, wayfinding_context: Dictionary) -> Dictionary:
	var normalized := _normalize_table_draft(draft)
	var unlocks := table_unlocks(wayfinding_context)
	var fingerprint := _table_fingerprint(normalized, wayfinding_context)
	# A small reference wrapper lets the invalid-preview closure see the recipe
	# witness once an exact road has resolved below (GDScript closures capture a
	# local's initial binding rather than later rebinding it).
	var story_payload_ref := {"value": _story_witness_payload({}, wayfinding_context)}
	var invalid := func(reason: String) -> Dictionary:
		var out := _invalid_resolution(reason)
		out.normalized_draft = normalized.duplicate(true)
		out.unlocks = unlocks.duplicate(true)
		out.fingerprint = fingerprint
		var story_payload: Dictionary = story_payload_ref.value
		for key_v in story_payload:
			var key := String(key_v)
			var value = story_payload[key_v]
			out[key] = value.duplicate(true) if value is Array or value is Dictionary else value
		return out
	var grid: Dictionary = normalized.grid
	var structural := {}
	var seal_id := ""
	for slot_v in grid:
		var slot := String(slot_v)
		var component_id := String(grid[slot_v])
		if not COMPONENT_SLOT_KINDS.has(slot):
			return invalid.call("Unknown Chart Table slot: %s." % slot)
		var slot_info: Dictionary = unlocks.grid[slot]
		if not bool(slot_info.unlocked):
			var unlock_copy := "after the first Snug return" if slot == "w" \
				else "at Wayfinding %d" % int(slot_info.level)
			return invalid.call("That %s cell opens %s." % [slot_info.kind, unlock_copy])
		if slot == "s":
			if not is_chart_seal(component_id):
				return invalid.call("That is not a Chart Seal.")
			seal_id = component_id
			continue
		if not COMPONENTS.has(component_id):
			return invalid.call("Unknown chart component: %s." % component_id)
		var expected_kind := String(COMPONENT_SLOT_KINDS[slot])
		var actual_kind := String(COMPONENTS[component_id].kind)
		if expected_kind != actual_kind:
			return invalid.call("%s does not belong in the %s slot." % [
				String(COMPONENTS[component_id].name), expected_kind])
		structural[slot] = component_id
	var rail: Array = normalized.ink_rail
	if rail.size() > INK_RAIL_UNLOCK_LEVELS.size():
		return invalid.call("The Ink rail holds four pots.")
	for index in rail.size():
		var ink_id := String(rail[index])
		if ink_id == "":
			continue
		if not bool((unlocks.ink_rail[index] as Dictionary).unlocked):
			return invalid.call("Ink pot %d opens at Wayfinding %d." % [index + 1,
				int((unlocks.ink_rail[index] as Dictionary).level)])
		if not INKS.has(ink_id):
			return invalid.call("Unknown ink: %s." % ink_id)
	var level := int(wayfinding_context.get("level", 1))
	var exact_id := ""
	var matched_variant: Dictionary = {}
	var locked_variant: Dictionary = {}
	var exact_candidates: Array = []
	var partial_ids: Array = []
	# `queens_summit` is frozen legacy data. It is visible to journal/Codex
	# readers, but must never win a normal physical-Table resolution. The
	# template compatibility adapter may name that exact recipe explicitly for
	# existing Charts, avoiding an ambiguous shared Crownward pattern.
	var candidate_order: Array = TABLE_RECIPE_ORDER
	var forced_legacy_recipe := String(wayfinding_context.get("legacy_recipe_id", ""))
	if forced_legacy_recipe != "" and CHART_RECIPES.has(forced_legacy_recipe):
		candidate_order = [forced_legacy_recipe]
	elif bool(wayfinding_context.get("compatibility_mode", false)):
		candidate_order = CHART_RECIPE_ORDER
	for candidate_id in candidate_order:
		var candidate: Dictionary = CHART_RECIPES[candidate_id]
		var pattern: Dictionary = candidate.pattern
		if _patterns_equal(structural, pattern):
			exact_candidates.append(String(candidate_id))
			continue
		var variant: Dictionary = candidate.get("deepening_variant", {})
		if not variant.is_empty() and _patterns_equal(structural,
				_variant_pattern(candidate)):
			if level >= int(variant.get("min_wayfinding", 1)):
				exact_candidates.append(String(candidate_id))
				matched_variant = variant.duplicate(true)
			else:
				locked_variant = variant.duplicate(true)
			continue
		if _pattern_is_subset(structural, pattern):
			partial_ids.append(String(candidate_id))
	# More than one authored road may share the structural marks. The physical
	# Seal selects the campaign recipe; compatibility callers deliberately keep
	# the first unsealed legacy recipe so their historical affix path is stable.
	if bool(wayfinding_context.get("compatibility_mode", false)):
		for candidate_id in exact_candidates:
			if String((CHART_RECIPES[candidate_id] as Dictionary)
					.get("required_seal", "")) == "":
				exact_id = String(candidate_id)
				break
		# A legacy template must still prefer its historical unsealed road, but
		# a structurally unique authored Seal road (the reprise) remains usable
		# through the pure resolver for tooling and tests.
		if exact_id == "":
			for candidate_id in exact_candidates:
				if String((CHART_RECIPES[candidate_id] as Dictionary)
						.get("required_seal", "")) == seal_id:
					exact_id = String(candidate_id)
					break
	else:
		for candidate_id in exact_candidates:
			if String((CHART_RECIPES[candidate_id] as Dictionary)
					.get("required_seal", "")) == seal_id:
				exact_id = String(candidate_id)
				break
		if exact_id == "" and seal_id != "":
			for candidate_id in exact_candidates:
				if String((CHART_RECIPES[candidate_id] as Dictionary)
						.get("required_seal", "")) == "":
					exact_id = String(candidate_id)
					break
	# A structurally unique Story-Seal road remains identifiable before the
	# Seal is staged. This keeps old Codex/preview readers compatible while the
	# live Table honestly reports that the newly resolved recipe is incomplete.
	if exact_id == "" and seal_id == "" and exact_candidates.size() == 1 \
			and locked_variant.is_empty():
		exact_id = String(exact_candidates[0])
	if exact_id == "":
		if not locked_variant.is_empty():
			return invalid.call("Wayfinding %d is required to deepen this road." %
				int(locked_variant.get("min_wayfinding", 17)))
		if partial_ids.is_empty() and exact_candidates.is_empty():
			return invalid.call("Those marks do not form a road.")
		var incomplete := _invalid_resolution("A road is taking shape.")
		incomplete.state = "incomplete"
		incomplete.normalized_draft = normalized.duplicate(true)
		incomplete.unlocks = unlocks.duplicate(true)
		incomplete.fingerprint = fingerprint
		return incomplete
	var recipe: Dictionary = CHART_RECIPES[exact_id]
	story_payload_ref["value"] = _story_witness_payload(recipe, wayfinding_context)
	if level < int(recipe.req_wayfinding):
		return invalid.call("Wayfinding %d is required." % int(recipe.req_wayfinding))
	var required_wildcraft := int(recipe.get("req_wildcraft", 1))
	if int(wayfinding_context.get("wildcraft_level", 1)) < required_wildcraft:
		return invalid.call("Wildcraft %d is required to prepare this road." %
			required_wildcraft)
	var required_seal := String(recipe.get("required_seal", ""))
	if required_seal != "" and seal_id != required_seal:
		var incomplete := _invalid_resolution("This road is waiting for its named Seal.")
		incomplete.state = "incomplete"
		incomplete.recipe_id = exact_id
		incomplete.known = (wayfinding_context.get("known_recipe_ids", []) as Array) \
			.has(exact_id)
		incomplete.requires_seal = true
		incomplete.normalized_draft = normalized.duplicate(true)
		incomplete.unlocks = unlocks.duplicate(true)
		incomplete.fingerprint = fingerprint
		return incomplete
	if seal_id != "" and not _seal_use_allowed(wayfinding_context, seal_id, exact_id) \
			and not bool(wayfinding_context.get("legacy_frozen_compatibility", false)):
		return invalid.call("That Seal is being held for another chapter road.")
	if bool(recipe.get("requires_first_knot_clear", false)) \
			and not CampaignData.chapter_cleared(wayfinding_context.get("campaign_state", {}),
				CampaignData.FIRST_KNOT):
		return invalid.call("The First Knot must be cleared before this road can be recalled.")
	var required_chapter := String(recipe.get("requires_chapter_clear", ""))
	if required_chapter != "" and not CampaignData.chapter_cleared(
			wayfinding_context.get("campaign_state", {}), required_chapter):
		return invalid.call("The previous chapter must be settled before this road can be read.")
	var clue_requirement: Dictionary = recipe.get("requires_chapter_clue_count", {})
	if not clue_requirement.is_empty():
		var clue_chapter := String(clue_requirement.get("chapter_id", ""))
		var required_count := int(clue_requirement.get("count", 0))
		var chapter_state: Dictionary = (CampaignData.normalize_campaign_state(
			wayfinding_context.get("campaign_state", {})).get("chapters", {}) as Dictionary) \
			.get(clue_chapter, {})
		if int(chapter_state.get("clue_count", 0)) < required_count:
			return invalid.call("More authored signs must be returned before this folio opens.")
	var campaign_chapter := String(recipe.get("campaign_chapter", ""))
	var campaign_contract := {}
	if campaign_chapter != "":
		if not CampaignData.can_inscribe_boss(
				wayfinding_context.get("campaign_state", {}), exact_id, level,
				int(wayfinding_context.get("wildcraft_level", 1)),
				int(wayfinding_context.get("huntcraft_level", 1))):
			return invalid.call("Three Thorn Whispers must be banked before this road can be sealed.")
		campaign_contract = CampaignData.boss_contract(exact_id)
	var handoff_contract_id := String(recipe.get("handoff_contract", ""))
	var handoff_contract := {}
	if handoff_contract_id != "":
		if not CampaignData.can_inscribe_handoff(
				wayfinding_context.get("campaign_state", {}), exact_id) \
				and not bool(wayfinding_context.get("legacy_frozen_compatibility", false)):
			return invalid.call("The Summit handoff is already waiting in the Chart Case.")
		handoff_contract = CampaignData.handoff_contract(exact_id)
		if String(handoff_contract.get("contract_id", "")) != handoff_contract_id:
			return invalid.call("The Summit handoff has no authored contract.")
	var output: Dictionary = (recipe.output as Dictionary).duplicate(true)
	var template_id := String(output.get("template_id", ""))
	var template: Dictionary = TEMPLATES.get(template_id, {})
	if template.is_empty():
		return invalid.call("The recipe has no Chart template.")
	var depth_contract := _depth_contract(recipe, template, matched_variant)
	var encounter_contract := {}
	if exact_id == "first_knot_reprise":
		depth_contract = _reprise_depth_contract(template)
		encounter_contract = _reprise_encounter_contract()
	var required_inks: Array = (recipe.get("required_inks", []) as Array).duplicate()
	var split := _required_and_bias_inks(rail, required_inks)
	if not (split.missing as Array).is_empty():
		var incomplete := _invalid_resolution("The page is waiting for %s." %
			String(INKS[String(split.missing[0])].name))
		incomplete.state = "incomplete"
		incomplete.recipe_id = exact_id
		incomplete.known = (wayfinding_context.get("known_recipe_ids", []) as Array).has(exact_id)
		incomplete.required_inks = required_inks
		incomplete.preparation_notes = (recipe.get("preparation_notes", []) as Array).duplicate()
		incomplete.normalized_draft = normalized.duplicate(true)
		incomplete.unlocks = unlocks.duplicate(true)
		incomplete.fingerprint = fingerprint
		return incomplete
	var bias_inks: Array = split.bias
	var bias_capacity := int(template.get("ink_slots", 0))
	if bias_capacity > 0:
		bias_capacity += maxi(0, int(wayfinding_context.get("extra_ink_slots", 0)))
	if bias_inks.size() > bias_capacity:
		return invalid.call("This page cannot hold that many bias Inks.")
	if seal_id != "":
		if TROPHY_TO_AFFIX.has(seal_id):
			if int(template.get("affix_slots", 0)) <= 0:
				return invalid.call("That Seal has no place on this Chart.")
			var den: Dictionary = AFFIXES.get(String(TROPHY_TO_AFFIX[seal_id]), {})
			if level < int(den.get("req_carto", 1)):
				return invalid.call("Wayfinding %d is required for that Seal." %
					int(den.get("req_carto", 1)))
		else:
			var story_seal: Dictionary = STORY_SEALS.get(seal_id, {})
			if level < int(story_seal.get("req_wayfinding", 1)):
				return invalid.call("Wayfinding %d is required for that Seal." %
					int(story_seal.get("req_wayfinding", 1)))
	output["tier"] = int(template.tier)
	output["scope"] = String(template.scope)
	output["name"] = String(output.get("name", template.name))
	output["affix_slots"] = int(template.affix_slots)
	output["ink_slots"] = bias_capacity
	output["max_layers"] = int(depth_contract.get("max_layers",
		template.get("max_layers", 1)))
	output["gen"] = (template.get("gen", {}) as Dictionary).duplicate(true)
	var weights: Dictionary = {}
	var stability: Dictionary = {}
	var perk_bonus := float(wayfinding_context.get("stability_perk_bonus", 0.0))
	if int(template.affix_slots) > 0:
		weights = template_weights(template, bias_inks, level)
		var ink_bonus := ink_stability_bonus(bias_inks)
		for affix_id in weights:
			stability[String(affix_id)] = effective_stability(String(affix_id),
				level, ink_bonus, perk_bonus)
	var guaranteed: Array = []
	if not encounter_contract.is_empty():
		guaranteed.append({"type": "hearth", "layer": int(depth_contract.hearth_layer),
			"name": "Hearth", "guaranteed": true})
		guaranteed.append({"type": "boss", "id": String(encounter_contract.boss_kind),
			"layer": int(encounter_contract.boss_layer), "name": "The Hedgemother",
			"guaranteed": true})
	elif not depth_contract.is_empty():
		guaranteed.append({"type": "hearth", "layer": int(depth_contract.hearth_layer),
			"name": "Hearth", "guaranteed": true})
	if not campaign_contract.is_empty():
		guaranteed.append({"type": "boss",
			"id": String(campaign_contract.boss_kind),
			"name": _boss_display_name(String(campaign_contract.boss_kind)),
			"guaranteed": true})
	elif not handoff_contract.is_empty():
		guaranteed.append({"type": "boss",
			"id": String(handoff_contract.boss_kind),
			"name": _boss_display_name(String(handoff_contract.boss_kind)),
			"guaranteed": true})
	elif seal_id != "" and encounter_contract.is_empty() \
			and TROPHY_TO_AFFIX.has(seal_id):
		var sealed_affix := String(TROPHY_TO_AFFIX[seal_id])
		guaranteed.append({"type": "sealed_affix", "id": sealed_affix,
			"name": String(AFFIXES[sealed_affix].name)})
	var boss_kind := String((template.get("gen", {}) as Dictionary).get("boss_kind", ""))
	if boss_kind != "" and campaign_contract.is_empty() and handoff_contract.is_empty():
		guaranteed.append({"type": "boss", "id": boss_kind})
	var component_cost := {}
	for component_id_v in structural.values():
		var component_id := String(component_id_v)
		component_cost[component_id] = int(component_cost.get(component_id, 0)) + 1
	var reagent_cost := craft_cost(template_id, bias_inks, seal_id,
		maxi(0, int(wayfinding_context.get("hedge_discount", 0))))
	var required_counts := {}
	for required_id_v in required_inks:
		var required_id := String(required_id_v)
		required_counts[required_id] = int(required_counts.get(required_id, 0)) + 1
	for required_id in required_counts:
		reagent_cost[required_id] = maxi(int(reagent_cost.get(required_id, 0)),
			int(required_counts[required_id]))
	var known := (wayfinding_context.get("known_recipe_ids", []) as Array).has(exact_id)
	var returned_on_failure: Dictionary = {}
	if not campaign_contract.is_empty():
		returned_on_failure = (campaign_contract.escrow_items as Dictionary) \
			.duplicate(true)
	elif not handoff_contract.is_empty():
		returned_on_failure = (handoff_contract.escrow_items as Dictionary) \
			.duplicate(true)
	var all_costs := _merged_cost(component_cost, reagent_cost)
	var ordinary_costs := all_costs.duplicate(true)
	for escrow_id_v in returned_on_failure:
		var escrow_id := String(escrow_id_v)
		var remainder := int(ordinary_costs.get(escrow_id, 0)) \
			- int(returned_on_failure[escrow_id_v])
		if remainder > 0:
			ordinary_costs[escrow_id] = remainder
		else:
			ordinary_costs.erase(escrow_id)
	var preview := {
		"valid": true, "commit_ready": true,
		"state": "known" if known else "attemptable",
		"recipe_id": exact_id, "known": known, "output": output,
		"component_cost": component_cost,
		"reagent_cost": reagent_cost,
		"costs": all_costs, "ordinary_costs": ordinary_costs,
		"requires_seal": required_seal != "",
		"required_inks": required_inks, "bias_inks": bias_inks,
		"bias_capacity": bias_capacity,
		"guaranteed": guaranteed, "affix_weights": weights,
		"stability": stability, "returned_on_failure": returned_on_failure,
		"campaign_contract": campaign_contract.duplicate(true),
		"handoff_contract": handoff_contract.duplicate(true),
		"preparation_notes": (recipe.get("preparation_notes", []) as Array).duplicate(),
		"depth_contract": depth_contract.duplicate(true),
		"encounter_contract": encounter_contract.duplicate(true), "reason": "",
		"fingerprint": fingerprint,
		"normalized_draft": normalized.duplicate(true),
		"unlocks": unlocks.duplicate(true),
		"placed_components": structural.duplicate(true),
		"ink_ids": bias_inks.duplicate(),
		"required_ink_ids": required_inks.duplicate(),
		"seal_id": seal_id, "wayfinding_level": level,
		# Inscription is the only point at which a clue Chart can honestly be
		# frozen.  The commit fingerprint already includes this state, and the
		# materialized Chart retains only the resolved reward/clue — never this
		# mutable campaign snapshot.
		"campaign_state_snapshot": CampaignData.normalize_campaign_state(
			wayfinding_context.get("campaign_state", {})),
		"stability_perk_bonus": perk_bonus,
	}
	var story_payload: Dictionary = story_payload_ref.value
	for key_v in story_payload:
		var key := String(key_v)
		var value = story_payload[key_v]
		preview[key] = value.duplicate(true) if value is Array or value is Dictionary else value
	return preview

# Pure preview/resolution seam. It reads authored data and returns a new
# dictionary; it never mutates the supplied pattern/state and never rolls RNG.
static func resolve_chart_recipe(placed_components: Dictionary, ink_ids: Array,
		seal_id: String, wayfinding_state: Dictionary) -> Dictionary:
	var pattern_error := _validate_component_pattern(placed_components)
	if pattern_error != "":
		return _invalid_resolution(pattern_error)
	var recipe_id := ""
	for candidate_id in CHART_RECIPE_ORDER:
		if _patterns_equal(placed_components, CHART_RECIPES[candidate_id].pattern):
			recipe_id = String(candidate_id)
			break
	if recipe_id == "":
		return _invalid_resolution("Those marks do not form a known road.")
	var rail: Array = (CHART_RECIPES[recipe_id].get("required_inks", []) as Array).duplicate()
	rail.append_array(ink_ids)
	var grid := placed_components.duplicate(true)
	if seal_id != "":
		grid["s"] = seal_id
	var context := wayfinding_state.duplicate(true)
	context["compatibility_mode"] = true
	var out := preview_table({"grid": grid, "ink_rail": rail}, context)
	# Slice-A callers staged semantic components for free. Preserve that adapter
	# until every caller has moved to Game.try_inscribe_chart.
	if bool(out.get("valid", false)):
		out.component_cost = {}
		out.costs = (out.reagent_cost as Dictionary).duplicate(true)
		out.ink_ids = ink_ids.duplicate()
	return out

# Compatibility adapter for the shipped template tray. A selected template
# stands for the canonical components that Slice B will expose individually.
static func resolve_legacy_template(template_id: String, ink_ids: Array,
		seal_id: String, wayfinding_state: Dictionary) -> Dictionary:
	var recipe_id := recipe_id_for_template(template_id)
	if recipe_id == "" or not CHART_RECIPES.has(recipe_id):
		return _invalid_resolution("Unknown Chart base: %s." % template_id)
	var recipe: Dictionary = CHART_RECIPES[recipe_id]
	var grid: Dictionary = (recipe.pattern as Dictionary).duplicate(true)
	if seal_id != "":
		grid["s"] = seal_id
	var rail: Array = (recipe.get("required_inks", []) as Array).duplicate()
	rail.append_array(ink_ids)
	var context := wayfinding_state.duplicate(true)
	# Preserve the precise old recipe when its structural marks now overlap a
	# new authored road. This is compatibility-only; live Table callers never
	# receive this escape hatch.
	context["legacy_recipe_id"] = recipe_id
	context["legacy_frozen_compatibility"] = true
	context["compatibility_mode"] = true
	var out := preview_table({"grid": grid, "ink_rail": rail}, context)
	# The old template tray staged semantic marks for free. Preserve that
	# compatibility payload for frozen Charts only; the live physical Table
	# continues to expose and charge every placed component through preview_table.
	if bool(out.get("valid", false)):
		out.component_cost = {}
		out.costs = (out.reagent_cost as Dictionary).duplicate(true)
		out.ink_ids = ink_ids.duplicate()
	return out

# Phase 3 — a multi-layer Chart may take one explicit Omen at its far
# Waystone. Omens remain separate from the Affixes committed at inscription.
const DEPTH_OMENS := [
	{"id": "thornwake", "name": "Thornwake",
		"desc": "The next hollow stirs: foes gather 25% thicker.",
		"enemy_density_mult": 1.25},
	{"id": "hungry_ink", "name": "Hungry Ink",
		"desc": "The lines drink deeper: foes gather 15% thicker and strike 10% harder.",
		"enemy_density_mult": 1.15, "enemy_damage_mult": 1.10},
]

# Same mechanical twins, written through the Mire's material language. This
# gives the biome Affix identity without forking the underlying balance rules.
const MIRE_AFFIX_PRESENTATIONS := {
	"fog_of_hedge": {"good_name": "Wisp-Lit Fog", "bad_name": "Drowning Fog",
		"good_desc": "Bog-wisps mark the safe sightlines; foes notice you a third later.",
		"bad_desc": "The fog closes over the reeds; foes notice you from further out."},
	"sprinter": {"good_name": "Fenstriders", "bad_name": "Sucking Mud",
		"good_desc": "Everything learns the reed-paths and moves a quarter faster.",
		"bad_desc": "The mire catches your boots; you move 10% slower."},
	"wellspring": {"good_name": "Sallow Plenty", "bad_name": "Brackish Roots",
		"good_desc": "The wet ground fattens every gather node by one.",
		"bad_desc": "Roots clutch the harvest; gathering takes a third longer."},
}

# Rootroad-only encounter twins. The runtime owns the bell telegraph and hit
# resolution; this registry deliberately declares no RNG, reward, clue, boss,
# or gathering mutation for either side.
const ROOTROADS_AFFIX_PRESENTATIONS := {
	"stonewake": {
		"good_name": "Stonewake", "bad_name": "Stone's Rebuke",
		"good_desc": "Marked bell-stones ring for at least a breath, then cast enemies outward and trouble their Poise. You stand untouched.",
		"bad_desc": "The same marked ring and bell wake the stone, but its rebuke catches you as well.",
	},
	"open_thread": {
		"good_name": "Open Thread", "bad_name": "Snagged Thread",
		"good_desc": "The road gives underfoot; you move 8% faster in this Chart.",
		"bad_desc": "The road catches at your heels; you move 8% slower in this Chart.",
	},
}

const ASHEN_BOUGH_AFFIX_PRESENTATIONS := {
	"cinderbound": {
		"good_name": "Cinderbound", "bad_name": "Cinder's Rebuke",
		"good_desc": "A three-pip vent warns for a full breath, breaks nearby enemies' Poise, then leaves one host-claimed Focus ember.",
		"bad_desc": "The same three-pip vent warns for a full breath, then catches the Wayfinder in heat and a brief slow.",
	},
}

# ---- affixes (v1 — implemented effects only) ----
# stability: effective = min(95, base_stab + carto_lv * 0.6 + ink_bonus*100).
const AFFIXES := {
	# First Road-only authored Affixes. They are intentionally absent from
	# AFFIX_ROLL_ORDER, so later stochastic Charts cannot roll tutorial tuning.
	"frail_foes": {
		"name": "Paper-Thin Foes", "bad_name": "Knotted Vigor",
		"good_desc": "Foes have 35% less health; their smaller silhouettes tell the truth.",
		"bad_desc": "Foes take longer to bring down.",
		"kind": "first_road", "req_carto": 1, "base_stab": 100,
	},
	"quiet_halls": {
		"name": "Quiet Halls", "bad_name": "Crowded Signs",
		"good_desc": "No random elites appear on this first road.",
		"bad_desc": "Elite signs gather in the deeper rooms.",
		"kind": "first_road", "req_carto": 1, "base_stab": 100,
	},
	"elite_signs": {
		"name": "Marked Company", "bad_name": "Hidden Marks",
		"good_desc": "One elite and its retinue wait in the deepest combat room.",
		"bad_desc": "Elite signs are harder to read.",
		"kind": "first_road", "req_carto": 1, "base_stab": 100,
	},
	"mineral_vein": {
		"name": "Mineral Vein", "bad_name": "Barren",
		"good_desc": "Ore deposits seam through the dungeon. 3-5 mineable rocks appear inside.",
		"bad_desc": "The ink ran dry. The dungeon comes up barren — no ore.",
		"kind": "bias", "req_carto": 1, "base_stab": 55,
	},
	"bramble_bloom": {
		"name": "Bramble Bloom", "bad_name": "Wilted",
		"good_desc": "The hollow blooms with bramble — 4-6 forage spawns appear inside.",
		"bad_desc": "The vines have withered to nothing. No forage in this run.",
		# Spec 57: opens on the first Snug return (normally Wayfinding 3) so
		# Hedge Ink can visibly shift the player's first Affix roll.
		"kind": "bias", "req_carto": 3, "base_stab": 55,
	},
	"wood_grove": {
		"name": "Wood Grove", "bad_name": "Stripped Grove",
		"good_desc": "A trapper has been chopping. 3-5 log piles wait inside the chart.",
		"bad_desc": "The grove is stripped bare — no logs.",
		"kind": "bias", "req_carto": 7, "base_stab": 55,
	},
	"herbal_patch": {
		"name": "Herbal Patch", "bad_name": "Frostbit Patch",
		"good_desc": "A wild herb patch crowns the chart — 6-9 herb spawns.",
		"bad_desc": "The patch is frost-bit. No herbs this run.",
		"kind": "bias", "req_carto": 14, "base_stab": 55,
	},
	"tyrannical": {
		"name": "Tyrannical", "bad_name": "Erratic",
		"good_desc": "Enemies are fattened up — +50% HP, +30% chart XP on completion.",
		"bad_desc": "Each enemy rolls its own size and vigor. Chaotic.",
		"kind": "modifier", "req_carto": 5, "base_stab": 52,
	},
	"sprinter": {
		"name": "Sprinting Things", "bad_name": "Mired Boots",
		"good_desc": "Everything inside moves a quarter faster — and pays +40 chart xp like any good twin.",
		"bad_desc": "The mud finds YOUR boots — you move 10% slower in this chart.",
		"kind": "modifier", "req_carto": 6, "base_stab": 52,
	},
	"gilded": {
		"name": "Gilded Hollow", "bad_name": "Picked Clean",
		"good_desc": "Two extra treasure chests hide in the rooms.",
		"bad_desc": "Someone got here first — no extra chests.",
		"kind": "bias", "req_carto": 9, "base_stab": 55,
	},
	"bursting": {
		"name": "Bursting", "bad_name": "Volatile",
		"good_desc": "Slain enemies burst, scorching their nearby kin.",
		"bad_desc": "The bursts don't care who's standing close — including you.",
		"kind": "modifier", "req_carto": 12, "base_stab": 50,
	},
	"quiver": {
		"name": "Quiver", "bad_name": "Damp Strings",
		"good_desc": "Your bow sings — +20% fire rate inside this chart.",
		"bad_desc": "The damp gets into the string — 10% slower firing.",
		"kind": "modifier", "req_carto": 8, "base_stab": 54,
	},
	"fog_of_hedge": {
		"name": "Fog of Hedge", "bad_name": "Blinding Fog",
		"good_desc": "A low fog dulls their senses — enemies notice you a third later.",
		"bad_desc": "The fog favors THEM — enemies notice you from further out.",
		"kind": "modifier", "req_carto": 10, "base_stab": 52,
	},
	"frenzied": {
		"name": "Frenzied", "bad_name": "Seething",
		"good_desc": "Everything attacks a quarter faster — bring your footwork.",
		"bad_desc": "The anger settles deep — enemies hit 15% harder.",
		"kind": "modifier", "req_carto": 11, "base_stab": 50,
	},
	"wellspring": {
		"name": "Wellspring", "bad_name": "Barren Veins",
		"good_desc": "Every gather node in the chart yields one extra.",
		"bad_desc": "Thin pickings — gathering takes a third longer.",
		"kind": "bias", "req_carto": 13, "base_stab": 55,
	},
	"echoing": {
		"name": "Echoing Steps", "bad_name": "Hollow Echo",
		"good_desc": "The hollow gives back — Focus regenerates half again as fast.",
		"bad_desc": "The hollow drinks it in — Focus regen drops by a quarter.",
		"kind": "modifier", "req_carto": 15, "base_stab": 52,
	},
	"marked_quarry": {
		"name": "Marked Quarry", "bad_name": "Skittish Prey",
		"good_desc": "Elites here carry trophies twice as often.",
		"bad_desc": "The fiercer things hide their prizes — half the trophy odds.",
		"kind": "modifier", "req_carto": 16, "base_stab": 50,
	},
	"stonewake": {
		"name": "Stonewake", "bad_name": "Stone's Rebuke",
		"good_desc": "Bell-stones telegraph, then knock enemies outward and deal Poise damage while leaving you safe.",
		"bad_desc": "The same bell-stones also damage and displace you.",
		"kind": "encounter_metadata", "req_carto": 18, "base_stab": 50,
		"scope": "rootroads", "telegraph_sec": 1.0,
		"effect": {"ring": "bell_stone", "enemy_knockback": true,
			"enemy_poise_damage": true, "player_safe_when_good": true,
			"player_damage_and_displace_when_bad": true},
		"icon_path": "res://assets/ui/affixes/stonewake.png",
	},
	"cinderbound": {
		"name": "Cinderbound", "bad_name": "Cinder's Rebuke",
		"good_desc": "A 1.25-second, three-pip vent harms and Poise-breaks nearby enemies, then leaves one claimed Focus ember.",
		"bad_desc": "The same vent damages and briefly slows the player.",
		"kind": "encounter_metadata", "req_carto": 20, "base_stab": 50,
		"chart_scoped": true,
		"scope": "ashen_bough", "telegraph_sec": 1.25,
		"effect": {"ring": "cinder_vent", "pip_count": 3,
			"enemy_damage": true, "enemy_poise_damage": true,
			"host_claimed_focus_pickup": true,
			"player_damage_and_slow_when_bad": true,
			"mutates_campaign": false, "mutates_gather": false,
			"mutates_boss": false},
		"icon_path": "res://assets/ui/affixes/cinderbound.png",
	},
	"open_thread": {
		"name": "Open Thread", "bad_name": "Snagged Thread",
		"good_desc": "You move 8% faster inside this Chart.",
		"bad_desc": "You move 8% slower inside this Chart.",
		"kind": "modifier", "req_carto": 22, "base_stab": 50,
		"chart_scoped": true, "scope": "rootroads",
		"effect": {"player_speed_mult_good": 1.08,
			"player_speed_mult_bad": 0.92, "mutates_campaign": false,
			"mutates_gather": false, "mutates_boss": false},
	},
	"festival_pace": {
		"name": "Festival Pace", "bad_name": "Lockstep",
		"good_desc": "+50% enemy density inside. The hollow is thick with them.",
		"bad_desc": "The halls fall quiet — fewer enemies, thinner haul.",
		"kind": "pacing", "req_carto": 7, "base_stab": 52,
	},
	# Boss dens never roll at random — they are inked in deliberately by
	# slotting the matching trophy at the table (the chart chain: elites →
	# Hedgemother → Boar → Wolf → the Summit). Stability still rolls.
	"hedgemother_den": {
		"name": "Hedgemother's Den", "bad_name": "Empty Throne",
		"good_desc": "The deepest room becomes her thorn-arena.",
		"bad_desc": "You find her empty bramble-throne. Whatever lived here has gone.",
		"kind": "boss", "req_carto": 8, "base_stab": 50,
		"trophy": "thorn_essence",
	},
	"burrow_boar_den": {
		"name": "Burrow Boar's Wallow", "bad_name": "Empty Wallow",
		"good_desc": "A great Burrow Boar takes the deepest room. Heavier, meaner, slower.",
		"bad_desc": "The wallow is fresh-dug but empty. Whatever rooted here has moved on.",
		"kind": "boss", "req_carto": 12, "base_stab": 48,
		"trophy": "tusker_tusk",
	},
	"wolf_alpha_den": {
		"name": "Wolf Alpha's Roost", "bad_name": "Cold Trail",
		"good_desc": "A pack-leader wolf haunts the deepest room. Fast, sharp, glow-eyed.",
		"bad_desc": "Only fur and a cold trail — the pack moved on hours ago.",
		"kind": "boss", "req_carto": 14, "base_stab": 46,
		"trophy": "wightpelt",
	},
}

# Trophy material → the den it inks in.
const TROPHY_TO_AFFIX := {
	"thorn_essence": "hedgemother_den",
	"tusker_tusk": "burrow_boar_den",
	"wightpelt": "wolf_alpha_den",
}

# Story Seals authorize deterministic authored contracts without becoming an
# Affix or entering good/bad-twin stability. Oath Nail is awarded by the Queen
# chapter but remains a protected, named future Seal rather than loose loot.
const STORY_SEALS := {
	"alpha_fang": {"name": "Alpha's Fang", "req_wayfinding": 16},
	"oath_nail": {"name": "Oath Nail", "req_wayfinding": 19},
	"starheart_coal": {"name": "Starheart Coal", "req_wayfinding": 21},
	"wyrm_scale": {"name": "Wyrm Scale", "req_wayfinding": 23},
}

# Base roll weights (relative likelihood per slot, before ink bias).
# Random-roll weights. Boss dens are absent on purpose — a boss is a
# deliberate inscription (trophy slot), never a surprise roll.
const BASE_WEIGHTS := {
	"mineral_vein": 10,
	"bramble_bloom": 8,
	"wood_grove": 8,
	"herbal_patch": 8,
	"tyrannical": 8,
	"festival_pace": 7,
	"sprinter": 7,
	"gilded": 6,
	"bursting": 6,
	"quiver": 7,
	"fog_of_hedge": 6,
	"frenzied": 6,
	"wellspring": 7,
	"echoing": 6,
	"marked_quarry": 5,
	"cinderbound": 1,
	"open_thread": 1,
}
const AFFIX_ROLL_ORDER := ["mineral_vein", "bramble_bloom", "wood_grove",
	"herbal_patch", "tyrannical", "festival_pace", "sprinter", "gilded",
	"bursting", "quiver", "fog_of_hedge", "frenzied", "wellspring",
	"echoing", "marked_quarry", "cinderbound", "open_thread"]

# ---- inks ----
# bias: affix_id -> weight multiplier. "_stability" -> flat good-twin bonus
# (fraction; 0.10 = +10 percentage points), capped at +0.5 total.
const INKS := {
	"hedge_ink": {
		"name": "Hedge Ink", "icon": "●",
		"desc": "Pulls the roll toward green affixes — blooms, groves, patches.",
		"bias": {"bramble_bloom": 2.0, "herbal_patch": 2.0, "wood_grove": 2.0},
	},
	"stoneground_ink": {
		"name": "Stoneground Ink", "icon": "◆",
		"desc": "Heavy and gritty — pulls hard toward the mineral seams.",
		"bias": {"mineral_vein": 2.5},
	},
	"refined_ink": {
		"name": "Refined Ink", "icon": "✦",
		"desc": "Steadies the hand — +10% toward each affix's good twin.",
		"bias": {"_stability": 0.10},
	},
	# Spec 43 — discovered inks. Ash leans green-and-fast; chalkwash
	# leans toward the deep wave-2 affixes.
	"ash_ink": {
		"name": "Ash Ink", "icon": "◉",
		"desc": "Char and leaf — pulls hard toward groves and quick feet.",
		"bias": {"wood_grove": 2.5, "sprinter": 1.8},
	},
	"chalkwash_ink": {
		"name": "Chalkwash Ink", "icon": "○",
		"desc": "Pale and quiet — wellsprings, echoes, and quarry marks lean closer.",
		"bias": {"wellspring": 1.8, "echoing": 1.8, "marked_quarry": 1.8},
	},
	# Spec 45 — every rollable affix now has at least one ink that courts it.
	"mothglow_ink": {
		"name": "Mothglow Ink", "icon": "☽",
		"desc": "Pale and night-sweet — the fog leans friendly and the bowstring stays dry.",
		"bias": {"fog_of_hedge": 2.2, "quiver": 1.8},
	},
	"foxglove_ink": {
		"name": "Foxglove Ink", "icon": "❖",
		"desc": "Blue-black and fierce — pulls the roll toward the mean affixes. Mean pays.",
		"bias": {"tyrannical": 2.0, "frenzied": 1.8, "bursting": 1.8},
	},
	"gildleaf_ink": {
		"name": "Gildleaf Ink", "icon": "✧",
		"desc": "Ground starlight — chests come gilded and the halls fill festival-thick.",
		"bias": {"gilded": 2.2, "festival_pace": 1.8},
	},
	"mire_ink": {
		"name": "Mire Ink", "icon": "≈",
		"desc": "Bitter, mint-pale ink. Holds a wet promise steady through the reeds.",
		"bias": {"fog_of_hedge": 1.5, "wellspring": 1.5},
	},
	"emberleaf_ink": {
		"name": "Emberleaf Ink", "icon": "",
		"desc": "Embersage, wellwater, and ash held together for a fire that refuses to die.",
		"bias": {},
	},
}

# ---- the bias-roll engine ----

# Weight table for (tier, slotted inks, carto level), normalized to percent.
static func compute_weights(_tier: int, ink_ids: Array, carto_lv: int) -> Dictionary:
	var weights := {}
	for id in AFFIX_ROLL_ORDER:
		var aff: Dictionary = AFFIXES.get(id, {})
		if aff.is_empty():
			continue
		if bool(aff.get("chart_scoped", false)):
			continue
		if int(aff.req_carto) > carto_lv:
			continue
		weights[id] = float(BASE_WEIGHTS[id])
	for ink_id in ink_ids:
		var ink: Dictionary = INKS.get(ink_id, {})
		var bias: Dictionary = ink.get("bias", {})
		for affix_id in bias:
			if String(affix_id).begins_with("_"):
				continue
			if weights.has(affix_id):
				weights[affix_id] *= float(bias[affix_id])
	var total := 0.0
	for id in weights:
		total += weights[id]
	if total <= 0.0:
		return {}
	var out := {}
	for id in weights:
		out[id] = weights[id] / total * 100.0
	return out

# A template may narrow its roll to one authored encounter twin. Filtering is
# performed after the ordinary weight calculation so Inks cannot smuggle an
# out-of-scope Affix into a fixed branch. Empty pools retain the legacy table.
static func template_weights(template: Dictionary, ink_ids: Array,
		carto_lv: int) -> Dictionary:
	var weights := compute_weights(int(template.get("tier", 1)), ink_ids, carto_lv)
	var pool = template.get("affix_pool", [])
	if not pool is Array or (pool as Array).is_empty():
		return weights
	var allowed := {}
	for affix_id_v in pool:
		allowed[String(affix_id_v)] = true
	var out := {}
	for affix_id in weights:
		if allowed.has(String(affix_id)):
			out[String(affix_id)] = float(weights[affix_id])
	for affix_id_v in pool:
		var affix_id := String(affix_id_v)
		var aff: Dictionary = AFFIXES.get(affix_id, {})
		if not aff.is_empty() and int(aff.get("req_carto", 1)) <= carto_lv \
				and not out.has(affix_id):
			out[affix_id] = float(BASE_WEIGHTS.get(affix_id, 1))
	# The roll helper only needs relative weights. Do not renormalize here so the
	# public preview remains clear that this is a one-entry authored pool.
	return out

# Flat stability bonus from slotted inks (capped +0.5 = +50 points).
static func ink_stability_bonus(ink_ids: Array) -> float:
	var bonus := 0.0
	for ink_id in ink_ids:
		var ink: Dictionary = INKS.get(ink_id, {})
		bonus += float(ink.get("bias", {}).get("_stability", 0.0))
	return minf(0.5, bonus)

# Spec 45-carto — perk_bonus carries Sure Lines (+0.05 toward the good
# twin); the 95 cap holds whatever stacks.
static func effective_stability(affix_id: String, carto_lv: int,
		ink_bonus: float, perk_bonus: float = 0.0) -> int:
	var aff: Dictionary = AFFIXES.get(affix_id, {})
	var base := float(aff.get("base_stab", 50))
	return mini(95, roundi(base + carto_lv * 0.6
		+ (ink_bonus + perk_bonus) * 100.0))

# Roll N distinct affixes from a weight table.
static func roll_affix_ids(weights: Dictionary, count: int, rng: RandomNumberGenerator) -> Array:
	var picks: Array = []
	var remaining := weights.duplicate()
	for _i in count:
		var id := _weighted_pick(remaining, rng)
		if id == "":
			break
		picks.append(id)
		remaining.erase(id)
	return picks

static func _weighted_pick(weights: Dictionary, rng: RandomNumberGenerator) -> String:
	var total := 0.0
	for id in AFFIX_ROLL_ORDER:
		if weights.has(id):
			total += float(weights[id])
	if total <= 0.0:
		return ""
	var r := rng.randf() * total
	var last := ""
	for id in AFFIX_ROLL_ORDER:
		if not weights.has(id):
			continue
		r -= float(weights[id])
		last = String(id)
		if r <= 0.0:
			return last
	return last

# Inscribe: spend nothing here (caller spends), just roll the chart dict.
# A slotted trophy GUARANTEES its boss-den affix in one slot (the gamble
# that remains is the stability roll — the den can still come up empty).
static func inscribe(template_id: String, ink_ids: Array, carto_lv: int,
		trophy_id: String = "", perk_bonus: float = 0.0,
		explicit_seed: int = 0) -> Dictionary:
	var t: Dictionary = TEMPLATES.get(template_id, {})
	if t.is_empty():
		return {}
	var rng := RandomNumberGenerator.new()
	var seed := explicit_seed
	if seed == 0:
		rng.randomize()
		seed = int(rng.randi()) & 0x7FFFFFFF
		if seed == 0:
			seed = 1
	rng.seed = seed
	var resolved: Array = []
	var slots := int(t.affix_slots)
	if slots > 0:
		var picks: Array = []
		if trophy_id != "" and TROPHY_TO_AFFIX.has(trophy_id):
			picks.append(String(TROPHY_TO_AFFIX[trophy_id]))
		var weights := template_weights(t, ink_ids, carto_lv)
		picks.append_array(roll_affix_ids(weights, slots - picks.size(), rng))
		var stab_bonus := ink_stability_bonus(ink_ids)
		for affix_id in picks:
			var stab := effective_stability(affix_id, carto_lv, stab_bonus,
				perk_bonus)
			var good := rng.randf() * 100.0 < stab
			resolved.append({
				"id": affix_id,
				"good": good,
				"resolvedId": affix_id if good else affix_id + "__bad",
			})
	return {
		"template_id": template_id,
		"tier": int(t.tier),
		"scope": String(t.scope),
		"name": String(t.name),
		"affixes": resolved,
		"seed": seed,
		"layer": 1,
		"max_layers": int(t.get("max_layers", 1)),
		"omens": [],
	}

# Ashen Bough's first eligible elite is frozen before World generation. This
# deliberately uses a separate hash domain from rooms, drops, and presentation:
# Pack Reader may reveal this record at Huntcraft 21 without consuming a roll
# or changing the run. Other routes explicitly have no eligible manifest.
static func elite_manifest_for_chart(chart_seed: int, recipe_id: String) -> Dictionary:
	var seed := maxi(1, chart_seed)
	if recipe_id != "ashen_bough":
		return {"schema": "elite-manifest-v1", "eligible": false,
			"recipe_id": recipe_id, "slot_id": "", "elite_id": "",
			"modifier_id": "", "seed_fingerprint": ""}
	var digest := ("wayfinder/ashen-bough/elite-manifest/v1/%d" % seed).sha256_text()
	var modifier_index := int(digest.substr(0, 8).hex_to_int()) % 3
	var modifiers := ["cinderclad", "smokefoot", "banked_ember"]
	return {"schema": "elite-manifest-v1", "eligible": true,
		"recipe_id": recipe_id, "slot_id": "ashen_first_eligible",
		"elite_id": "bough_watcher", "modifier_id": String(modifiers[modifier_index]),
		"seed_fingerprint": digest.substr(0, 16)}

# Consume the exact inputs captured by a successful pure resolution. The
# existing RNG/affix engine remains the single inscription implementation.
static func inscribe_resolved(resolution: Dictionary) -> Dictionary:
	if not bool(resolution.get("valid", false)):
		return {}
	var output: Dictionary = resolution.get("output", {})
	var template_id := String(output.get("template_id", ""))
	if template_id == "" or not TEMPLATES.has(template_id):
		return {}
	return inscribe(template_id, resolution.get("ink_ids", []),
		int(resolution.get("wayfinding_level", 1)),
		String(resolution.get("seal_id", "")),
		float(resolution.get("stability_perk_bonus", 0.0)))

static func chart_instance_id(recipe_id: String, seed: int) -> String:
	if recipe_id == "" or seed <= 0:
		return ""
	return "chart-" + ("%s:%d" % [recipe_id, seed]).sha256_text().substr(0, 24)

static func _is_campaign_inert_chart(chart: Dictionary) -> bool:
	var recipe_id := String(chart.get("recipe_id", ""))
	return bool(chart.get("campaign_inert", false)) \
		or bool(chart.get("memory_chart", false)) \
		or recipe_id.begins_with("memory_")

# Resolve the authored late-game reward at the same boundary as every other
# Chart promise: materialization.  A clue needs the exact next-ledger fact at
# that instant; a Boss needs the canonical contract accepted by the Table.
# The returned record is copied onto the Chart, so later Affix RNG, World
# generation, source reads, and campaign mutations cannot alter its value.
static func _frozen_campaign_completion_reward(chart: Dictionary,
		resolution: Dictionary) -> Dictionary:
	if _is_campaign_inert_chart(chart):
		return {}
	var recipe_id := String(resolution.get("recipe_id", chart.get("recipe_id", "")))
	var definition := campaign_completion_xp_definition(recipe_id)
	if definition.is_empty():
		return {}
	var kind := String(definition.get("kind", ""))
	if kind == "fixed":
		return {"kind": "fixed", "recipe_id": recipe_id,
			"xp": campaign_completion_xp_for(recipe_id)}
	if kind == "boss":
		var contract = resolution.get("campaign_contract", {})
		var expected := CampaignData.boss_contract(recipe_id)
		if not contract is Dictionary or (contract as Dictionary).is_empty() \
				or expected.is_empty() or (contract as Dictionary) != expected:
			return {}
		return {"kind": "boss", "recipe_id": recipe_id,
			"chapter_id": String(expected.get("chapter_id", "")),
			"xp": campaign_completion_xp_for(recipe_id)}
	if kind != "clue":
		return {}
	var raw_snapshot = resolution.get("campaign_state_snapshot", {})
	if not raw_snapshot is Dictionary:
		return {}
	var instance_id := String(chart.get("chart_instance_id", ""))
	if instance_id == "":
		return {}
	var clue := CampaignData.next_clue_for_chart(raw_snapshot, recipe_id,
		instance_id, int(resolution.get("wayfinding_level", 1)))
	if clue.is_empty():
		return {}
	return campaign_completion_reward_for_clue(recipe_id, clue)

# A frozen reward is intentionally a small, inspectable materialized record.
# Callers must use field presence rather than truthiness: the final Unwritten
# return carries a real `0` replacement reward.
static func authored_completion_reward(chart: Dictionary) -> Dictionary:
	if not chart.has("authored_completion_xp"):
		return {}
	var raw = chart.get("authored_completion_reward", {})
	if not raw is Dictionary or (raw as Dictionary).is_empty():
		return {}
	var out: Dictionary = (raw as Dictionary).duplicate(true)
	out["xp"] = maxi(0, int(chart.get("authored_completion_xp", 0)))
	return out

static func _attach_resolution_provenance(chart: Dictionary,
		resolution: Dictionary) -> Dictionary:
	if chart.is_empty():
		return {}
	var out := chart.duplicate(true)
	var recipe_id := String(resolution.get("recipe_id", ""))
	if recipe_id != "":
		out["recipe_id"] = recipe_id
		out["chart_instance_id"] = chart_instance_id(recipe_id, int(out.seed))
		var frozen_reward := _frozen_campaign_completion_reward(out, resolution)
		if not frozen_reward.is_empty():
			out["authored_completion_xp"] = int(frozen_reward.get("xp", 0))
			out["authored_completion_reward"] = frozen_reward.duplicate(true)
			# A frozen clue is a generation promise as well as a reward promise.
			# Runtime will revalidate it before entry, so charts held through a
			# later ledger change cannot claim a stale authored payout.
			if String(frozen_reward.get("kind", "")) == "clue":
				out["campaign_clue"] = {
					"chapter_id": String(frozen_reward.get("chapter_id", "")),
					"clue_id": String(frozen_reward.get("clue_id", "")),
					"presentation": String(frozen_reward.get("presentation", "")),
				}
		# This is authored at inscription, not regenerated by World. A late join
		# therefore receives the same first-elite descriptor the host sees. Keep
		# older Chart records byte-compatible by omitting the field outside Ashen.
		if recipe_id == "ashen_bough":
			out["elite_manifest"] = elite_manifest_for_chart(int(out.seed), recipe_id)
		# The capstone's permanent records are a frozen witness, not inventory.
		# Recompute it from the preview's Campaign snapshot rather than trusting a
		# caller-supplied array, then copy it so later state/UI mutation cannot
		# alter the materialized Chart or its eventual host attempt.
		if recipe_id == "unwritten_road_boss":
			var story_witness := CampaignData.required_story_inputs(
				resolution.get("campaign_state_snapshot", {}))
			var canonical_snapshot: Array = story_witness.get("story_input_snapshot", [])
			var preview_snapshot: Array = resolution.get("story_input_snapshot", [])
			if bool(story_witness.get("eligible", false)) \
					and preview_snapshot == canonical_snapshot:
				out["story_input_snapshot"] = canonical_snapshot.duplicate()
				out["story_input_fingerprint"] = String(
					story_witness.get("story_input_fingerprint", ""))
				out["story_witness_fingerprint"] = String(
					resolution.get("story_witness_fingerprint", ""))
	var campaign_contract: Dictionary = resolution.get("campaign_contract", {})
	if not campaign_contract.is_empty():
		out["campaign_contract"] = campaign_contract.duplicate(true)
		out["seal_id"] = String(campaign_contract.get("seal_id", ""))
		out["returned_on_failure"] = (resolution.get("returned_on_failure", {}) \
			as Dictionary).duplicate(true)
	var handoff_contract: Dictionary = resolution.get("handoff_contract", {})
	if not handoff_contract.is_empty():
		out["handoff_contract"] = handoff_contract.duplicate(true)
		out["seal_id"] = String(handoff_contract.get("seal_id", ""))
		out["returned_on_failure"] = (resolution.get("returned_on_failure", {}) \
			as Dictionary).duplicate(true)
	var depth_contract: Dictionary = resolution.get("depth_contract", {})
	if not depth_contract.is_empty():
		out["depth_contract"] = depth_contract.duplicate(true)
		out["max_layers"] = int(depth_contract.max_layers)
	var encounter_contract: Dictionary = resolution.get("encounter_contract", {})
	if not encounter_contract.is_empty():
		var frozen_encounter := encounter_contract.duplicate(true)
		# The reward is determined at inscription time, independent of later
		# dungeon rolls or replay callbacks. Keep the seed non-zero for the
		# deterministic drop helper's explicit-seed contract.
		var reward_seed := (int(out.seed) * 1103515245 + 1013904223) & 0x7FFFFFFF
		if reward_seed == 0:
			reward_seed = 1
		frozen_encounter["reward_seed"] = reward_seed
		out["encounter_contract"] = frozen_encounter
	return out

# Pure finalizer: an accepted preview plus an explicit seed always yields the
# same Chart, including authored-order Affix selection and good/bad twins.
static func materialize_chart(preview: Dictionary, seed: int) -> Dictionary:
	if seed <= 0 or not bool(preview.get("commit_ready", preview.get("valid", false))):
		return {}
	var output: Dictionary = preview.get("output", {})
	var template_id := String(output.get("template_id", ""))
	if template_id == "" or not TEMPLATES.has(template_id):
		return {}
	var campaign_contract: Dictionary = preview.get("campaign_contract", {})
	# Campaign bosses are an authored guarantee, never a good/bad den Affix.
	# The Seal remains in the cost/escrow contract but does not enter Affix RNG.
	var encounter_contract: Dictionary = preview.get("encounter_contract", {})
	var handoff_contract: Dictionary = preview.get("handoff_contract", {})
	var affix_seal := "" if not campaign_contract.is_empty() \
		or not encounter_contract.is_empty() or not handoff_contract.is_empty() \
		else String(preview.get("seal_id", ""))
	var chart := inscribe(template_id,
		preview.get("bias_inks", preview.get("ink_ids", [])),
		int(preview.get("wayfinding_level", 1)), affix_seal,
		float(preview.get("stability_perk_bonus", 0.0)), seed)
	# Recipes may share a generation template while retaining an authored,
	# player-facing identity (campaign Boss Charts and Reprise in particular).
	chart["name"] = String(output.get("name", chart.get("name", "Chart")))
	return _attach_resolution_provenance(chart, preview)

static func can_press_deeper(chart: Dictionary) -> bool:
	return int(chart.get("layer", 1)) < int(chart.get("max_layers", 1))

static func next_omen(chart: Dictionary) -> Dictionary:
	if not can_press_deeper(chart):
		return {}
	var omen_index := (int(chart.get("layer", 1)) - 1) % DEPTH_OMENS.size()
	return (DEPTH_OMENS[omen_index] as Dictionary).duplicate(true)

static func deepen(chart: Dictionary) -> Dictionary:
	if not can_press_deeper(chart):
		return {}
	var out := chart.duplicate(true)
	out["layer"] = int(chart.get("layer", 1)) + 1
	var omens: Array = out.get("omens", [])
	omens.append(next_omen(chart))
	out["omens"] = omens
	# Generate another deterministic place without silently changing the
	# committed tier, scope, or Affixes.
	out["seed"] = (int(chart.get("seed", 1)) * 1103515245
		+ int(out.layer) * 12345 + 1013904223) & 0x7FFFFFFF
	return out

# Total cost for a craft: template base cost + one of each slotted ink +
# the slotted trophy. A template with no affix slots has nothing for ink
# (or a trophy) to bias — never charge for them, whatever the caller passed.
# Spec 45-carto — hedge_discount carries Thrifty Quill (−1 hedge ink base
# cost, never below one pot).
static func craft_cost(template_id: String, ink_ids: Array,
		trophy_id: String = "", hedge_discount: int = 0) -> Dictionary:
	var t: Dictionary = TEMPLATES.get(template_id, {})
	var cost: Dictionary = (t.get("base_cost", {}) as Dictionary).duplicate()
	if hedge_discount > 0 and cost.has("hedge_ink"):
		cost["hedge_ink"] = maxi(1, int(cost["hedge_ink"]) - hedge_discount)
	if int(t.get("affix_slots", 0)) > 0:
		for ink_id in ink_ids:
			cost[ink_id] = int(cost.get(ink_id, 0)) + 1
	# A deliberate Seal is a cost even on a slotless authored Chart. Story
	# Seals never bias Affixes; their lifecycle is frozen separately in the
	# campaign/handoff contract.
	if trophy_id != "" and is_chart_seal(trophy_id) \
			and (int(t.get("affix_slots", 0)) > 0 or STORY_SEALS.has(trophy_id)):
		cost[trophy_id] = int(cost.get(trophy_id, 0)) + 1
	return cost

# Shipped completion formula: tier × 75 + good × 40 + bad × 10.
# Tyrannical's good twin pays its "+30% chart XP" promise here — the slice
# has no per-kill XP, so completion is the only honest channel.
# Display name for a single chart-affix entry ({id, good, ...}): the good
# twin's name or the bad twin's. "" when the id is unknown.
static func affix_display_name(a: Dictionary) -> String:
	var aff: Dictionary = AFFIXES.get(String(a.get("id", "")), {})
	if aff.is_empty():
		return ""
	return String(aff.name) if bool(a.get("good", false)) else String(aff.bad_name)

static func affix_presentation(chart: Dictionary, a: Dictionary) -> Dictionary:
	var aff: Dictionary = AFFIXES.get(String(a.get("id", "")), {})
	if aff.is_empty():
		return {}
	var good := bool(a.get("good", false))
	var variant: Dictionary = {}
	if String(chart.get("scope", "")) == "mire":
		variant = MIRE_AFFIX_PRESENTATIONS.get(String(a.get("id", "")), {})
	elif String(chart.get("scope", "")) == "rootroads":
		variant = ROOTROADS_AFFIX_PRESENTATIONS.get(String(a.get("id", "")), {})
	elif String(chart.get("scope", "")) == "ashen_bough":
		variant = ASHEN_BOUGH_AFFIX_PRESENTATIONS.get(String(a.get("id", "")), {})
	return {
		"name": String(variant.get("good_name" if good else "bad_name",
			aff.get("name" if good else "bad_name", ""))),
		"desc": String(variant.get("good_desc" if good else "bad_desc",
			aff.get("good_desc" if good else "bad_desc", ""))),
	}

static func legacy_completion_xp(chart: Dictionary) -> int:
	var tier := int(chart.get("tier", 1))
	var good := 0
	var bad := 0
	var tyrannical := false
	for a in chart.get("affixes", []):
		if bool(a.get("good", false)):
			good += 1
			if String(a.get("id", "")) == "tyrannical":
				tyrannical = true
		else:
			bad += 1
	var xp := tier * 75 + good * 40 + bad * 10
	xp += maxi(0, int(chart.get("layer", 1)) - 1) * 50
	if tyrannical:
		xp = roundi(xp * 1.3)
	return xp

# Materialized campaign Charts carry an authored replacement total.  Field
# presence (not value) is the compatibility contract: old Fire Charts without
# it keep their historical tier/Affix formula, while the Unwritten finale can
# explicitly award zero without falling through to generic XP.
static func completion_xp(chart: Dictionary) -> int:
	if chart.has("authored_completion_xp"):
		return maxi(0, int(chart.get("authored_completion_xp", 0)))
	return legacy_completion_xp(chart)

# A small completion purse makes Chart-running itself a gold faucet without
# turning enemy kills into progression. Eight for a clean tier, four more for
# each Affix accepted; deeper tiers multiply the clean purse.
static func completion_gold(chart: Dictionary) -> int:
	var recipe_id := String(chart.get("recipe_id", ""))
	if CAMPAIGN_COMPLETION_GOLD.has(recipe_id):
		return int(CAMPAIGN_COMPLETION_GOLD[recipe_id])
	return int(chart.get("tier", 1)) * 8 \
		+ (chart.get("affixes", []) as Array).size() * 4 \
		+ maxi(0, int(chart.get("layer", 1)) - 1) * 6

# Display line for a chart ("Tier 1 Hollow — Mineral Vein, Barren").
static func chart_label(chart: Dictionary) -> String:
	var parts: Array = []
	for a in chart.get("affixes", []):
		var nm := String(affix_presentation(chart, a).get("name", ""))
		if nm != "":
			parts.append(nm)
	var label := String(chart.get("name", "Chart"))
	if int(chart.get("max_layers", 1)) > 1:
		label += " · Layer %d/%d" % [int(chart.get("layer", 1)),
			int(chart.get("max_layers", 1))]
	if not parts.is_empty():
		label += " — " + ", ".join(parts)
	return label
