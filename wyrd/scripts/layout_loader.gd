extends Node3D

# Spec 07/10 — Godot evaluation.
# Builds the crypt as Node3D primitives + GLB instances, with honest
# collision (spec 10): per-tile floor, walls, boss/enemy/decor colliders,
# a kill-plane that respawns the player, and named collision layers.
#
# Layout source:
#   USE_PROCGEN = true  → fresh seeded dungeon from dungeon_gen.gd
#   USE_PROCGEN = false → static snapshot at res://data/crypt_floor1.json

const DungeonGenScript = preload("res://scripts/dungeon_gen.gd")
const AnimDriverScript = preload("res://scripts/anim_driver.gd")
const CombatantScript = preload("res://scripts/combatant.gd")
const BossScript = preload("res://scripts/boss.gd")
const CreatureAnimScript = preload("res://scripts/creature_anim.gd")
const BreakableScript = preload("res://scripts/breakable.gd")
const GatherNodeScript = preload("res://scripts/gather_node.gd")
const SecondHandClueScript = preload("res://scripts/second_hand_clue.gd")
const CampaignClueScript = preload("res://scripts/campaign_clue.gd")
const PaleStairScript = preload("res://scripts/pale_stair.gd")
const OathRubbingScript = preload("res://scripts/oath_rubbing.gd")
const StonewakeScript = preload("res://scripts/stonewake.gd")
const BarrowJarlScript = preload("res://scripts/barrow_jarl.gd")
const OathboundGuardScript = preload("res://scripts/oathbound_guard.gd")
const OathBellScript = preload("res://scripts/oath_bell.gd")
const BarrowJarlControllerScript = preload("res://scripts/barrow_jarl_controller.gd")
const HearthGiantScript = preload("res://scripts/hearth_giant.gd")
const HearthChainScript = preload("res://scripts/hearth_chain.gd")
const HearthGiantEncounterScript = preload("res://scripts/hearth_giant_encounter.gd")
const KnotEaterScript = preload("res://scripts/knot_eater.gd")
const KnotEaterEncounterScript = preload("res://scripts/knot_eater_encounter.gd")

# Compatibility rendering does not reproduce Forward+'s volumetric depth and
# pushes the post-tonemap Wood Grove highlights into one clipped band. Keep the
# correction small, world-only, and centralized here; Canvas UI is unaffected.
const WEB_GRADE_BRIGHTNESS := 0.82
const WEB_GRADE_CONTRAST := 1.08
const KnotEaterAnchorScript = preload("res://scripts/knot_eater_anchor.gd")
const KnotEaterKnotScript = preload("res://scripts/knot_eater_knot.gd")
const CinderboundVentScript = preload("res://scripts/cinderbound_vent.gd")
const CinderFocusPickupScript = preload("res://scripts/cinder_focus_pickup.gd")
const RootroadGatherNodeScript = preload("res://scripts/rootroad_gather_node.gd")
const CampaignData = preload("res://data/campaign.gd")
const ExitWaystoneScript = preload("res://scripts/exit_waystone.gd")
const GatherDefs = preload("res://data/gather.gd")
const ElitesData = preload("res://data/elites.gd")
const AmbientMotesScript = preload("res://scripts/ambient_motes.gd")
const RoomPresenceScript = preload("res://scripts/room_presence.gd")
const SOFT_CIRCLE_TEX = preload("res://assets/vfx/soft_circle.png")
const VIGNETTE_SHADER = preload("res://shaders/vignette.gdshader")
const FLOOR_SHADER = preload("res://shaders/toon_ground.gdshader")

# (Per-kind enemy/boss HP moved into ENEMY_KINDS / BOSS_KINDS below.)

const USE_PROCGEN := true
const DEBUG_SCORE := true
const DEBUG_SHOT := false   # true → save /tmp/godot_selfshot.png 3s after load
const JSON_PATH := "res://data/crypt_floor1.json"

# Collision layers (bit values). Mirrors project.godot [layer_names].
const LAYER_WORLD := 1     # layer 1 — floor, walls, solid decor
const LAYER_ENEMIES := 4   # layer 3 — boss + enemy blockers

const KILL_PLANE_Y := -6.0

# decor.kind → GLB path under res://models/ (symlink to ../models)
const DECOR_MODEL := {
	"bones":       "res://models/dungeon_crypt_bones_v1.glb",
	"torch_wall":  "res://models/dungeon_crypt_torch-wall_v1.glb",
	"bookshelf":   "res://models/dungeon_crypt_bookshelf_v1.glb",
	"sarcophagus": "res://models/dungeon_crypt_sarcophagus_v1.glb",
	"altar":       "res://models/dungeon_crypt_altar_v1.glb",
	"brazier":     "res://models/dungeon_crypt_brazier_v1.glb",
	"chest":       "res://models/dungeon_crypt_chest_v1.glb",
	"column":      "res://models/dungeon_crypt_column_v1.glb",
	"pottery":     "res://models/dungeon_crypt_pottery_v1.glb",
	"rug":         "res://models/dungeon_crypt_rug_v1.glb",
}
const ROOTROAD_ID_MODEL := {
	"pale_well": "res://models/landmark_pale_well_v1.glb",
	"wildgold_vein": "res://models/prop_wildgold_vein_v1.glb",
	"wellmoss_patch": "res://models/prop_wellmoss_patch_v1.glb",
	"rootroad_lift": "res://models/landmark_rootroad_lift_wellhouse_v1.glb",
	"hod_oathstone": "res://models/landmark_hod_oathstone_v1.glb",
	"pale_oath_settlement_display": "res://models/settlement_pale_oath_display_v1.glb",
}
# ---- biome asset sets (scaffold) ----
# Today every biome reuses the crypt decor GLBs + a palette tint. This registry
# lets a chart `scope` pick a BIOME that supplies its own decor GLB set (and an
# optional floor texture); anything a biome doesn't define falls back to the
# crypt asset, so a biome lights up INCREMENTALLY as its Meshy GLBs land — no
# dungeon_gen changes needed (the biome reskins the existing decor `kind` slots).
# Palette tints stay in _apply_biome_palette (keyed by scope) so per-scope colour
# is unchanged. Mapping is a sensible default; adjust freely (Bog has no scope yet).
const SCOPE_BIOME := {
	"crypt": "crypt",
	"snug": "wood_grove",
	"hollow": "mineral_seam",
	"tier_1": "mineral_seam",
	"briar_maze": "wood_grove",
	"mire": "bog",
	"summit": "summit",
	# Pale Veins is deliberately a distinct build rather than a Summit recolour.
	# Accept both authored template scope and the biome shorthand used by test
	# fixtures; unknown future scopes still retain the safe crypt fallback.
	"pale_veins": "rootroads",
	"rootroads": "rootroads",
	"rootroad": "rootroads",
	"ashen_bough": "ashen_bough",
}
# Each biome: `decor` maps a crypt decor `kind` → that biome's GLB (empty =
# fall back to the crypt DECOR_MODEL); `floor_tex` overrides the floor texture
# (empty = keep the crypt brick). Populate as GLBs arrive — e.g. mineral_seam
# might map "column" → a timber support, "pottery" → ore rubble, "bones" → a
# crystal cluster, "sarcophagus" → a mine cart.
const BIOMES := {
	"crypt":        {"decor": {}, "floor_tex": "res://textures/crypt/dungeon-crypt-floor-brick-v1.png"},
	# Mineral Seam — Meshy lowpoly props (2026-06-28). Each reskins a crypt decor
	# `kind` slot: altar→ore-vein boulder, bones→crystals, sarcophagus→mine cart,
	# column→timber support, brazier→lantern, pottery→ore rubble, bookshelf→cave
	# mushrooms. Unmapped kinds (torch_wall/rug/chest) fall back to crypt.
	"mineral_seam": {"decor": {
		"altar":       "res://models/biome_mineral_seam_orevein_v1.glb",
		"bones":       "res://models/biome_mineral_seam_crystals_v1.glb",
		"sarcophagus": "res://models/biome_mineral_seam_minecart_v1.glb",
		"column":      "res://models/biome_mineral_seam_timber_v1.glb",
		"brazier":     "res://models/biome_mineral_seam_lantern_v1.glb",
		"pottery":     "res://models/biome_mineral_seam_rubble_v1.glb",
		"bookshelf":   "res://models/biome_mineral_seam_mushrooms_v1.glb",
	}, "tints": {
		# Lowpoly Meshy props ship untextured (white). Paint each a single
		# thematic hue + the ink outline — the same treatment the enemy GLBs get.
		"altar":       Color(0.58, 0.46, 0.34),   # ore-vein rock — warm stone
		"bones":       Color(0.52, 0.74, 0.95),   # crystals — cold blue
		"sarcophagus": Color(0.46, 0.33, 0.22),   # mine cart — wood
		"column":      Color(0.50, 0.38, 0.26),   # timber — wood
		"brazier":     Color(0.82, 0.64, 0.30),   # lantern — brass
		"pottery":     Color(0.53, 0.50, 0.45),   # ore rubble — grey rock
		"bookshelf":   Color(0.48, 0.64, 0.88),   # cave mushrooms — glow blue
	}, "floor_tex": ""},
	# Wood Grove — Meshy lowpoly props. altar→hollow stump, sarcophagus→fallen
	# log, column→bramble arch, bones→toadstools, brazier→fern, pottery→mossy
	# boulder, bookshelf→fairy ring. Tinted + ink-outlined (lowpoly = untextured).
	"wood_grove":   {"decor": {
		"altar":       "res://models/biome_wood_grove_stump_v1.glb",
		"sarcophagus": "res://models/biome_wood_grove_log_v1.glb",
		"column":      "res://models/biome_wood_grove_bramblearch_v1.glb",
		"bones":       "res://models/biome_wood_grove_toadstools_v1.glb",
		"brazier":     "res://models/biome_wood_grove_fern_v1.glb",
		"pottery":     "res://models/biome_wood_grove_boulder_v1.glb",
		"bookshelf":   "res://models/biome_wood_grove_fairyring_v1.glb",
	}, "tints": {
		"altar":       Color(0.42, 0.30, 0.20),   # hollow stump — bark
		"sarcophagus": Color(0.34, 0.24, 0.13),   # fallen log — bark, not pale stone
		"column":      Color(0.26, 0.34, 0.20),   # bramble arch — deep briar
		"bones":       Color(0.72, 0.28, 0.24),   # toadstools — red cap
		"brazier":     Color(0.40, 0.60, 0.30),   # fern — fresh green
		"pottery":     Color(0.46, 0.50, 0.40),   # mossy boulder
		"bookshelf":   Color(0.80, 0.74, 0.62),   # fairy ring — pale stone
	}, "floor_tex": ""},
	# Sallow Mire — wetland (scope "mire"). altar→gnarled roots, sarcophagus→
	# sunken log, column→dock post, bones→lily pads, brazier→will-o-wisp,
	# pottery→mud mound, bookshelf→reeds.
	"bog":          {"decor": {
		"altar":       "res://models/biome_bog_roots_v1.glb",
		"sarcophagus": "res://models/biome_bog_sunkenlog_v1.glb",
		"column":      "res://models/biome_bog_dockpost_v1.glb",
		"bones":       "res://models/biome_bog_lilypads_v1.glb",
		"brazier":     "res://models/biome_bog_wisp_v1.glb",
		"pottery":     "res://models/biome_bog_mudmound_v1.glb",
		"bookshelf":   "res://models/biome_bog_reeds_v1.glb",
	}, "tints": {
		"altar":       Color(0.40, 0.36, 0.30),   # gnarled roots — grey-brown
		"sarcophagus": Color(0.34, 0.36, 0.26),   # sunken log — dark moss
		"column":      Color(0.44, 0.40, 0.32),   # dock post — weathered wood
		"bones":       Color(0.34, 0.54, 0.30),   # lily pads — green
		"brazier":     Color(0.60, 0.80, 0.90),   # will-o-wisp — pale glow
		"pottery":     Color(0.36, 0.30, 0.24),   # mud mound — dark mud
		"bookshelf":   Color(0.46, 0.52, 0.30),   # reeds — marsh green
	}, "floor_tex": ""},
	# Summit — the high white places (endgame chart). altar→standing stone,
	# sarcophagus→snow drift, column→wind-bent pine, bones→frost shrub,
	# brazier→ice crystal, pottery→cairn, bookshelf→waystone signpost.
	"summit":       {"decor": {
		"altar":       "res://models/biome_summit_standingstone_v1.glb",
		"sarcophagus": "res://models/biome_summit_snowdrift_v1.glb",
		"column":      "res://models/biome_summit_pine_v1.glb",
		"bones":       "res://models/biome_summit_frostshrub_v1.glb",
		"brazier":     "res://models/biome_summit_icecrystal_v1.glb",
		"pottery":     "res://models/biome_summit_cairn_v1.glb",
		"bookshelf":   "res://models/biome_summit_signpost_v1.glb",
	}, "tints": {
		"altar":       Color(0.55, 0.55, 0.58),   # standing stone — grey
		"sarcophagus": Color(0.86, 0.90, 0.96),   # snow drift — white-blue
		"column":      Color(0.26, 0.40, 0.30),   # pine — dark green
		"bones":       Color(0.60, 0.70, 0.66),   # frost shrub
		"brazier":     Color(0.66, 0.84, 1.00),   # ice crystal — pale ice
		"pottery":     Color(0.52, 0.52, 0.54),   # cairn — grey stone
		"bookshelf":   Color(0.48, 0.40, 0.30),   # signpost — weathered wood
	}, "floor_tex": ""},
	# Rootroads — authored deterministically in models/scripts/build_pale_oath_world_v1.py.
	# They consume normal dungeon decor slots so the generator needs no Pale Oath
	# special case, while dedicated world actors supply the focal well/rubbing.
	"rootroads": {"decor": {
		"altar": "res://models/landmark_pale_well_v1.glb",
		"bones": "res://models/prop_wellmoss_patch_v1.glb",
		"sarcophagus": "res://models/landmark_rootroad_lift_wellhouse_v1.glb",
		"column": "res://models/biome_rootroads_roots_v1.glb",
		"brazier": "res://models/prop_oath_bellpost_1_v1.glb",
		"pottery": "res://models/prop_wildgold_vein_v1.glb",
		"bookshelf": "res://models/prop_oath_rubbing_v1.glb",
	}, "tints": {
		"altar": Color(0.56, 0.76, 0.88), "bones": Color(0.32, 0.60, 0.38),
		"sarcophagus": Color(0.30, 0.22, 0.15), "column": Color(0.26, 0.18, 0.13),
		"brazier": Color(0.72, 0.54, 0.24), "pottery": Color(0.88, 0.63, 0.18),
		"bookshelf": Color(0.68, 0.76, 0.70),
	}, "floor_tex": ""},
	"ashen_bough": {"decor": {
		"altar": "res://models/biome_ashen_bough_landing_v1.glb",
		"bones": "res://models/biome_ashen_bough_roots_v1.glb",
		"sarcophagus": "res://models/biome_ashen_bough_roots_v1.glb",
		"column": "res://models/biome_ashen_bough_roots_v1.glb",
		"brazier": "res://models/biome_ashen_bough_landing_v1.glb",
		"pottery": "res://models/biome_ashen_bough_roots_v1.glb",
		"bookshelf": "res://models/biome_ashen_bough_landing_v1.glb",
	}, "tints": {
		"altar": Color(0.58, 0.27, 0.15), "bones": Color(0.27, 0.16, 0.12),
		"sarcophagus": Color(0.33, 0.18, 0.12), "column": Color(0.24, 0.13, 0.10),
		"brazier": Color(0.92, 0.38, 0.12), "pottery": Color(0.46, 0.22, 0.13),
		"bookshelf": Color(0.70, 0.31, 0.14),
	}, "floor_tex": ""},
}

# Per-biome ENVIRONMENT mood — lighting + fog + airborne motes, the thing that
# actually sells "a different place" at FATE distance (vs just recolored bricks).
# Applied in _resolve_biome by duplicating the WorldEnvironment + tinting the Sun.
# ambient = cool fill hue · fog = distance-tint · sun = key hue · mote_* = the
# signature airborne particle (emission>0 → it blooms via the glow).
const BIOME_ENV := {
	"crypt": {
		"ambient": Color(0.30, 0.34, 0.46), "fog": Color(0.34, 0.28, 0.24),
		"fog_density": 0.012, "glow": 0.8, "sun": Color(1.0, 0.92, 0.85),
		"mote_color": Color(0.72, 0.66, 0.58), "mote_amount": 55,
		"mote_gravity": -0.04, "mote_size": 0.06, "mote_emission": 0.0,
	},
	"mineral_seam": {
		"ambient": Color(0.24, 0.40, 0.54), "fog": Color(0.28, 0.36, 0.44),
		"fog_density": 0.014, "glow": 0.9, "sun": Color(0.86, 0.92, 1.0),
		"mote_color": Color(0.60, 0.82, 1.0), "mote_amount": 70,
		"mote_gravity": 0.0, "mote_size": 0.05, "mote_emission": 1.4,
	},
	"wood_grove": {
		"ambient": Color(0.30, 0.42, 0.32), "fog": Color(0.40, 0.44, 0.30),
		"fog_density": 0.009, "glow": 0.85, "sun": Color(1.0, 0.96, 0.76),
		"mote_color": Color(1.0, 0.86, 0.42), "mote_amount": 48,
		"mote_gravity": 0.05, "mote_size": 0.07, "mote_emission": 2.2,
	},
	"bog": {
		"ambient": Color(0.24, 0.40, 0.40), "fog": Color(0.26, 0.36, 0.30),
		"fog_density": 0.024, "glow": 0.85, "sun": Color(0.76, 0.88, 0.80),
		"mote_color": Color(0.50, 0.88, 0.62), "mote_amount": 44,
		"mote_gravity": -0.02, "mote_size": 0.09, "mote_emission": 1.5,
		"vignette": 0.34, "sat": 1.18, "contrast": 1.06,
	},
	"summit": {
		"ambient": Color(0.42, 0.50, 0.64), "fog": Color(0.80, 0.86, 0.94),
		"fog_density": 0.020, "glow": 0.9, "sun": Color(0.90, 0.95, 1.0),
		"mote_color": Color(0.95, 0.97, 1.0), "mote_amount": 120,
		"mote_gravity": -0.30, "mote_size": 0.06, "mote_emission": 0.0,
		"vignette": 0.18, "sat": 1.06, "contrast": 1.04,
	},
	"rootroads": {
		"ambient": Color(0.29, 0.42, 0.42), "fog": Color(0.46, 0.58, 0.56),
		"fog_density": 0.017, "glow": 0.92, "sun": Color(0.78, 0.88, 0.76),
		"mote_color": Color(0.66, 0.82, 0.68), "mote_amount": 72,
		"mote_gravity": -0.03, "mote_size": 0.055, "mote_emission": 1.1,
		"vignette": 0.22, "sat": 1.03, "contrast": 1.05,
	},
	"ashen_bough": {
		"ambient": Color(0.46, 0.27, 0.22), "fog": Color(0.40, 0.20, 0.15),
		"fog_density": 0.019, "glow": 1.0, "sun": Color(1.0, 0.62, 0.32),
		"mote_color": Color(1.0, 0.40, 0.14), "mote_amount": 96,
		"mote_gravity": -0.12, "mote_size": 0.055, "mote_emission": 1.8,
		"vignette": 0.28, "sat": 1.12, "contrast": 1.07,
	},
}

# Per-biome GROUND COVER — a cheap MultiMesh scatter of tiny chunky bits that
# breaks the identical-tile read (the #1 procedural-box tell) and signs each
# biome on the floor. mscale = the bit's shape (flat pebble / tall shard / flat
# leaf); size = overall; density ~ instances per floor tile; emission>0 glows.
const BIOME_GROUND := {
	"crypt":        {"mscale": Vector3(1.0, 0.5, 1.0),  "color": Color(0.55, 0.52, 0.46), "size": 0.14, "density": 0.45},
	"mineral_seam": {"mscale": Vector3(0.5, 1.3, 0.5),  "color": Color(0.46, 0.64, 0.85), "size": 0.13, "density": 0.45, "emission": 0.7},
	"wood_grove":   {"mscale": Vector3(1.3, 0.08, 1.3), "color": Color(0.19, 0.31, 0.12), "size": 0.13, "density": 0.32},
	"bog":          {"mscale": Vector3(1.2, 0.10, 1.2), "color": Color(0.34, 0.50, 0.30), "size": 0.18, "density": 0.7},
	"summit":       {"mscale": Vector3(1.0, 0.45, 1.0), "color": Color(0.88, 0.92, 0.98), "size": 0.13, "density": 0.6},
	"rootroads":     {"mscale": Vector3(1.2, 0.14, 0.62), "color": Color(0.34, 0.42, 0.27), "size": 0.17, "density": 0.72, "emission": 0.25},
	"ashen_bough":   {"mscale": Vector3(0.62, 0.18, 1.25), "color": Color(0.72, 0.25, 0.10), "size": 0.15, "density": 0.78, "emission": 0.75},
}

# Per-biome uniforms for the procedural toon-ground shader (spec 50). Keys map
# 1:1 onto shaders/toon_ground.gdshader uniforms; STRUCTURE differs per biome
# (hard stone plates vs soft warped dirt/mud vs snow), not just tint. Each biome
# gets a distinct domain_rotation so no two share a lattice orientation.
const FLOOR_BIOME := {
	# Warm candle-lit flagstone — hard cobble plates, deep warm grout.
	"crypt": {
		"base_col": Color(0.55, 0.48, 0.40), "accent_col": Color(0.40, 0.34, 0.28),
		"mortar_col": Color(0.18, 0.14, 0.11),
		"cell_scale": 0.62, "cell_strength": 0.82, "mortar_width": 0.06,
		"noise_amt": 0.35, "mottle_scale": 0.07,
		"snow_blend": 0.0, "wet_blend": 0.0,
		"base_rough": 0.86, "bevel": 0.50, "vein_glow": 0.0, "sparkle_amt": 0.0,
		"warp_amount": 0.45, "warp_freq": 0.35, "domain_rotation": 0.30,
		"rim_amt": 0.25, "rim_tint": 0.40,
	},
	# Cool broken rock plates with faintly glowing crystal-blue veins in the cracks.
	"mineral_seam": {
		"base_col": Color(0.34, 0.40, 0.48), "accent_col": Color(0.42, 0.72, 0.96),
		"mortar_col": Color(0.10, 0.14, 0.20),
		"cell_scale": 0.74, "cell_strength": 0.90, "mortar_width": 0.07,
		"noise_amt": 0.40, "mottle_scale": 0.06,
		"snow_blend": 0.0, "wet_blend": 0.15, "puddle_thresh": 0.62,
		"base_rough": 0.80, "bevel": 0.60, "vein_glow": 0.90, "sparkle_amt": 0.0,
		"warp_amount": 0.55, "warp_freq": 0.40, "domain_rotation": 0.62,
		"rim_amt": 0.30, "rim_tint": 0.50,
	},
	# Forest soil + leaf litter — soft clumps, no hard grout grid, heavy mottle.
	"wood_grove": {
		"base_col": Color(0.30, 0.24, 0.15), "accent_col": Color(0.34, 0.42, 0.19),
		"mortar_col": Color(0.17, 0.12, 0.08),
		"cell_scale": 0.95, "cell_strength": 0.25, "mortar_width": 0.12,
		"noise_amt": 0.85, "mottle_scale": 0.22,
		"snow_blend": 0.0, "wet_blend": 0.06,
		"base_rough": 0.95, "bevel": 0.25, "vein_glow": 0.0, "sparkle_amt": 0.0,
		"warp_amount": 0.75, "warp_freq": 0.40, "domain_rotation": 0.20,
		"rim_amt": 0.22, "rim_tint": 0.35,
	},
	# Murky wet mud with big glossy water pools + cool sky-tinted sheen.
	"bog": {
		"base_col": Color(0.22, 0.22, 0.16), "accent_col": Color(0.26, 0.34, 0.22),
		"mortar_col": Color(0.10, 0.12, 0.10), "wet_tint": Color(0.24, 0.33, 0.30),
		"cell_scale": 1.10, "cell_strength": 0.30, "mortar_width": 0.10,
		"noise_amt": 0.70, "mottle_scale": 0.18,
		"snow_blend": 0.0, "wet_blend": 0.90, "puddle_thresh": 0.42,
		"base_rough": 0.90, "bevel": 0.20, "vein_glow": 0.0, "sparkle_amt": 0.0,
		"warp_amount": 0.85, "warp_freq": 0.35, "domain_rotation": 0.45,
		"rim_amt": 0.28, "rim_tint": 0.45,
	},
	# Packed snow over ice — snow fills the cracks, view-dependent sparkle, blue seams.
	"summit": {
		"base_col": Color(0.82, 0.86, 0.92), "accent_col": Color(0.70, 0.80, 0.92),
		"mortar_col": Color(0.55, 0.60, 0.68), "snow_col": Color(0.97, 0.99, 1.0),
		"cell_scale": 0.85, "cell_strength": 0.35, "mortar_width": 0.08,
		"noise_amt": 0.50, "mottle_scale": 0.06,
		"snow_blend": 0.90, "wet_blend": 0.18, "puddle_thresh": 0.60,
		"base_rough": 0.78, "bevel": 0.30, "vein_glow": 0.0, "sparkle_amt": 2.2,
		"warp_amount": 0.50, "warp_freq": 0.35, "domain_rotation": 0.66,
		"rim_amt": 0.32, "rim_tint": 0.55,
	},
	"rootroads": {
		"base_col": Color(0.25, 0.30, 0.25), "accent_col": Color(0.38, 0.52, 0.36),
		"mortar_col": Color(0.10, 0.13, 0.10), "cell_scale": 0.72, "cell_strength": 0.40,
		"mortar_width": 0.10, "noise_amt": 0.76, "mottle_scale": 0.18,
		"snow_blend": 0.0, "wet_blend": 0.34, "puddle_thresh": 0.58,
		"base_rough": 0.92, "bevel": 0.30, "vein_glow": 0.35, "sparkle_amt": 0.0,
		"warp_amount": 0.82, "warp_freq": 0.34, "domain_rotation": 0.83,
		"rim_amt": 0.28, "rim_tint": 0.46,
	},
	"ashen_bough": {
		"base_col": Color(0.25, 0.15, 0.11), "accent_col": Color(0.58, 0.23, 0.10),
		"mortar_col": Color(0.08, 0.05, 0.04), "cell_scale": 0.78,
		"cell_strength": 0.46, "mortar_width": 0.09, "noise_amt": 0.82,
		"mottle_scale": 0.16, "snow_blend": 0.0, "wet_blend": 0.08,
		"puddle_thresh": 0.70, "base_rough": 0.91, "bevel": 0.34,
		"vein_glow": 0.85, "sparkle_amt": 0.0, "warp_amount": 0.88,
		"warp_freq": 0.38, "domain_rotation": 0.57, "rim_amt": 0.30,
		"rim_tint": 0.50,
	},
}

# Per-biome decal tint — soft moss/grime/frost patches biased into corners +
# spanning tile boundaries, to add lived-in surface story and break the floor.
const BIOME_DECAL := {
	"crypt":        Color(0.16, 0.13, 0.10),   # dark grime
	"mineral_seam": Color(0.14, 0.22, 0.30),   # dark wet mineral stain
	"wood_grove":   Color(0.20, 0.34, 0.16),   # moss green
	"bog":          Color(0.16, 0.30, 0.20),   # algae / moss
	"summit":       Color(0.82, 0.88, 0.95),   # frost
	"rootroads":     Color(0.24, 0.40, 0.26),   # wet moss in root seams
	"ashen_bough":   Color(0.48, 0.16, 0.08),   # ember soot in root seams
}

# decor.kind → collider box size, or null for pass-through decor.
const DECOR_COLLIDER := {
	"bones":       Vector3(0.8, 0.4, 0.8),
	"bookshelf":   Vector3(0.9, 1.8, 0.5),
	"torch_wall":  null,                     # wall-mounted, nothing to bump
	"sarcophagus": Vector3(1.0, 0.9, 1.6),
	"altar":       Vector3(1.1, 1.1, 1.1),
	"brazier":     Vector3(0.6, 1.1, 0.6),
	"chest":       Vector3(0.9, 0.7, 0.9),
	"column":      Vector3(0.8, 2.5, 0.8),
	"pottery":     Vector3(0.5, 0.7, 0.5),
	"rug":         null,                     # flat — walk over it
}
# decor.kind → break colour for the destructible decor (spec 26 follow-up).
# Kinds in this dict get a Breakable wrapper (HP 1, shatters on hit).
const DECOR_BREAKABLE := {
	"pottery": Color(0.65, 0.45, 0.30),
	"bones": Color(0.82, 0.78, 0.65),       # cream bone shards
	"bookshelf": Color(0.34, 0.24, 0.14),   # splintered dark wood
}
# Spec 28 — orient cardinal → Y rotation. layout_loader applies this to the
# decor body (or pass-through instance). "center" leaves rotation at 0.
const ORIENT_RY := {
	"n": 0.0,            # placed on north edge → faces south (+Z)
	"e": -PI / 2.0,      # placed on east edge  → faces west  (-X)
	"s": PI,             # placed on south edge → faces north (-Z)
	"w": PI / 2.0,       # placed on west edge  → faces east  (+X)
	"center": 0.0,
}
# Per-kind GLB facing tweak (radians). Empty for v1 — extend if a kind's
# native model orientation makes it face the wrong way.
const DECOR_FACING_OFFSET := {}

# Wyrd — enemy kinds by name. `scale` = calibrated multiplier (spec 16);
# `fit_h` = GlbFit target height for kinds never calibrated. `bob` =
# procedural hop-bob params [move_bob, move_rate] for unrigged critters.
# B3 — per-kind stats: damage/speed/atk_cd make a rat read different from
# a skeleton in the hands, not just the eyes. Slow hitters hit hard; fast
# ones nip. Tier scaling multiplies HP only — speed stays honest.
#
# Slice A — ARCHETYPE COLOR-CODING. The raw Meshy GLBs ship with NO surface
# materials (Godot falls back to flat grey, so skeleton/ghost/hedge_sprite all
# read as the same grey blob). Every kind now carries a `tint` painted onto a
# material we own, so size + hue = instant ID and the ink outline (next_pass,
# below) actually renders. Hues track the kit palette family:
#   skeleton  = bone-cream high-value     rat     = INK_MID brown
#   ghost     = pale cool blue (ethereal) hedge   = SAGE green
#   bramble   = SAGE green (deeper)       skitter = TERRACOTTA
# `ethereal` adds a faint cool emission + alpha so ghosts read as spirits, not
# painted stone. Pairs with the existing scale spread for two-axis legibility.
const ENEMY_KINDS := {
	"skeleton": {"model": "res://models/enemy_skeleton_v1.glb", "scale": 1.45,
		"hp": 18, "damage": 7, "speed": 1.55, "atk_cd": 1.7,
		"tint": Color(0.86, 0.82, 0.70)},
	"rat": {"model": "res://models/enemy_rat_v1.glb", "scale": 0.55,
		"hp": 10, "damage": 2, "speed": 2.6, "atk_cd": 0.9,
		"tint": Color(0.42, 0.32, 0.24), "bob": [0.14, 13.0]},
	"ghost": {"model": "res://models/enemy_ghost_v1.glb", "scale": 2.00,
		"hp": 14, "damage": 5, "speed": 1.35, "atk_cd": 1.5,
		"tint": Color(0.66, 0.78, 0.90), "ethereal": true,
		"ranged": true, "proj_speed": 9.0, "proj_damage": 5},
	# Sallow Mire signature role — a brighter, faster ranged wisp that forces
	# movement across the wet room while its ground-bound family closes in.
	"bog_wisp": {"model": "res://models/enemy_ghost_v1.glb", "scale": 1.65,
		"hp": 12, "damage": 4, "speed": 1.65, "atk_cd": 1.25,
		"tint": Color(0.48, 0.92, 0.68), "ethereal": true,
		"ranged": true, "proj_speed": 10.5, "proj_damage": 4},
	"hedge_sprite": {"model": "res://models/enemy_hedge_sprite_v1.glb", "scale": 2.00,
		"hp": 22, "damage": 6, "speed": 1.9, "atk_cd": 1.4,
		"tint": Color(0.44, 0.56, 0.27)},
	"bramble_imp": {"model": "res://models/bramble_imp_v4.glb", "fit_h": 1.05,
		"hp": 12, "damage": 4, "speed": 2.2, "atk_cd": 1.1,
		"tint": Color(0.34, 0.46, 0.22), "bob": [0.12, 10.0]},
	"skitterling": {"model": "res://models/skitterling.glb", "fit_h": 0.55,
		"hp": 7, "damage": 2, "speed": 3.0, "atk_cd": 0.8,
		"tint": Color(0.70, 0.30, 0.20), "bob": [0.10, 15.0]},
	# Support archetype — a hedge-sprite reskin that follows and HEALS its pack
	# instead of attacking; greener, slower, low HP. Kill it first or the room
	# never goes down. (combatant.gd reads `support`.)
	"warden": {"model": "res://models/enemy_hedge_sprite_v1.glb", "scale": 1.7,
		"hp": 20, "damage": 3, "speed": 1.6, "atk_cd": 2.2,
		"tint": Color(0.44, 0.72, 0.40), "support": true},
	# Bruiser archetype — a chunky bramble-imp reskin that telegraphs an
	# expanding floor ring (~0.7s) then lands a heavy AoE strike. The first
	# "get out of the circle" tell in the cast. (combatant.gd reads `bruiser`.)
	"barrow_brute": {"model": "res://models/bramble_imp_v4.glb", "fit_h": 1.7,
		"hp": 32, "damage": 14, "speed": 1.0, "atk_cd": 3.0,
		"tint": Color(0.28, 0.22, 0.18), "bruiser": true},
	"bough_watcher": {"model": "res://models/enemy_oathbound_v1.glb", "fit_h": 1.95,
		"hp": 30, "damage": 10, "speed": 1.55, "atk_cd": 1.7,
		"tint": Color(0.52, 0.27, 0.16)},
}

# Slice A — CHUNKY INK OUTLINE. Deep-INK inverted-hull shell, attached as the
# `next_pass` of each enemy's painted material (which is why we paint EVERY kind
# above — next_pass on the materialless GLBs renders nothing). next_pass rides
# the same skinned/animated mesh, so it deforms with the limbs — no separate
# static child-shell. grow_amount is tuned for the FATE camera (zoom ~14,
# telephoto); it is the orchestrator's main tuning knob.
const OUTLINE_INK := Color(0.13, 0.09, 0.06)
const OUTLINE_GROW := 0.05   # orchestrator tuning knob (FATE zoom ~14)

# Per-scope weighted spawn tables (the three.js dungeonSpawns pattern) —
# a Briar Maze run should FEEL different from a Hollow, not just route
# differently. Weights are relative; unknown scopes fall back to crypt.
const SPAWN_TABLES := {
	"snug": [["rat", 70], ["skeleton", 30]],
	"hollow": [["skeleton", 45], ["rat", 20], ["bramble_imp", 20], ["ghost", 15], ["warden", 10]],
	"briar_maze": [["bramble_imp", 50], ["hedge_sprite", 30], ["skitterling", 20]],
	"crypt": [["skeleton", 40], ["rat", 25], ["ghost", 20], ["hedge_sprite", 15], ["warden", 10], ["barrow_brute", 8]],
	# Summit — cold and tough: spectres + heavy brutes, fewer trash.
	"summit": [["skeleton", 30], ["ghost", 30], ["barrow_brute", 22], ["warden", 18]],
	# Sallow Mire — wetland: wisps (ghosts), sprites, imps, skitterers.
	"mire": [["bog_wisp", 32], ["hedge_sprite", 26], ["bramble_imp", 24], ["skitterling", 18]],
}

# Boss kinds (boss-as-affix). The Hedgemother is rigged; the boar and wolf
# are quadrupeds Meshy can't rig (spec 11) — they lumber via the hop-bob.
# `trophy` is the chart-chain drop: each boss yields the key that inks the
# next den at the Inscribing Table (elites drop the first key).
const BOSS_KINDS := {
	"hedgemother": {"name": "The Hedgemother",
		"model": "res://models/hedgemother_v2.glb", "scale": 3.75,
		"hp": 60, "damage": 8, "radius": 0.9, "height": 3.0,
		"trophy": "tusker_tusk"},
	"burrow_boar": {"name": "The Burrow Boar",
		"model": "res://models/burrow_boar_v3.glb", "fit_h": 2.2,
		"hp": 80, "damage": 11, "radius": 1.0, "height": 2.2, "bob": [0.10, 6.0],
		"trophy": "wightpelt"},
	"wolf_alpha": {"name": "The Wolf Alpha",
		"model": "res://models/wolf_alpha_v2.glb", "fit_h": 1.8,
		"hp": 55, "damage": 7, "radius": 0.8, "height": 1.8, "bob": [0.13, 9.5],
		"trophy": "alpha_fang"},
	# The Summit's nest-mother — the final chart's boss. Same silhouette the
	# player learned at level 8, scaled into a monarch.
	"hedgemother_queen": {"name": "The Hedgemother Queen",
		"model": "res://models/hedgemother_v2.glb", "scale": 4.6,
		"hp": 160, "damage": 13, "radius": 1.1, "height": 3.6, "trophy": ""},
	# Blender-authored skinned production boss.  The GLB embeds the Jarl's
	# idle/walk/attack/hit/shield/Reeling/relief/kneel/defeat clips; gameplay
	# ownership remains in BarrowJarl + BarrowJarlController.
	"barrow_jarl": {"name": "The Barrow Jarl",
		"model": "res://models/boss_barrow_jarl_v1.glb", "fit_h": 3.2,
		"hp": 220, "damage": 15, "radius": 1.0, "height": 3.2, "trophy": ""},
	"hearth_giant": {"name": "The Hearth Giant",
		"model": "res://models/boss_hearth_giant_v1.glb", "fit_h": 3.6,
		"hp": 260, "damage": 17, "radius": 1.15, "height": 3.6, "trophy": ""},
	"knot_eater": {"name": "The Knot-Eater",
		"model": "res://models/boss_barrow_jarl_v1.glb", "fit_h": 3.2,
		"hp": 320, "damage": 12, "radius": 1.1, "height": 3.2, "trophy": ""},
}

var _floor_mat: ShaderMaterial
var _wall_mat: StandardMaterial3D
var _scope := "crypt"   # chart scope — recolors the biome palette + filters decor
var _biome_id := "crypt"   # resolved from _scope via SCOPE_BIOME (decor asset set)
var _biome_decor: Dictionary = {}   # kind → biome GLB override (empty → crypt)
var _biome_tints: Dictionary = {}   # kind → tint Color for untextured biome props
var _rng := RandomNumberGenerator.new()
var _wall_seed := 0
var _net_foe_idx := 0          # Phase B — deterministic enemy naming
var net_spawn := Vector3.ZERO  # Phase B — co-op entry spawn for NetGame
var _entry_pos := Vector3.ZERO          # respawn target for the kill-plane

# Wyrd — chart modifier affixes, cached from Game at build time.
# tyrannical good: enemies ×1.5 HP. Erratic (bad twin): per-enemy jitter.
# festival_pace good: ×1.5 room density. Lockstep (bad twin): ×0.75.
var _hp_mult := 1.0
var _hp_jitter := false
var _speed_mult := 1.0
var _burst_on_death := false
var _burst_hits_player := false
var _aggro_mult := 1.0
var _atk_speed_mult := 1.0
var _dmg_mult := 1.0
var _trophy_mult := 1.0
var _density_mult := 1.0
var _elite_chance_mult := 1.0
var _guaranteed_pressure_elite := false
# Queen settlement presentation is intentionally world-local.  Game calls the
# public adapter below after its canonical campaign transition has committed;
# this loader never inspects campaign state or legacy handoff records itself.
var _boss_arena_center := Vector3.ZERO
var _boss_arena_ready := false
var _pale_stair: Node3D = null
var _stonewake: Node3D = null
var _elite_manifest_consumed := false
var _elite_manifest_body: Node = null
# D8 Slice 3 -- authored room rectangles are the sole spatial source for a
# Wayweaver thread.  They are intentionally kept out of Player/Game/save data;
# corridors and ambiguous overlap resolve ineligible in RoomPresence.
var _wayweaver_room_bounds: Array = []
var _wayweaver_run_epoch := -1
var _wayweaver_layer := 0

func _ready() -> void:
	# B8 — the hollows are quiet; the theme belongs to town.
	var sfx0 := get_node_or_null("/root/Sfx")
	if sfx0 != null and sfx0.has_method("stop_music"):
		sfx0.stop_music()
	# Phase B — in a chart run the spawn RNG seeds from the chart, so every
	# co-op peer builds IDENTICAL enemies (same tiles, kinds, elites, jitter)
	# and the host only has to sync state, never spawns. Dev boots without a
	# chart keep the old fully-random flavor.
	var game0 := get_tree().root.get_node_or_null("Game")
	var chart_seed := -1
	if game0 != null and not (game0.active_chart as Dictionary).is_empty():
		chart_seed = int(game0.active_chart.get("seed", -1))
	if chart_seed >= 0:
		_rng.seed = (chart_seed ^ 0x5DEECE66) & 0x7FFFFFFFFFFFFFFF
		_wall_seed = chart_seed
	else:
		_rng.randomize()
		_wall_seed = int(_rng.seed)

	# Floor: a from-first-principles procedural TOON ground shader (spec 50) built
	# per-biome in _make_floor_material(_biome_id) AFTER _resolve_biome runs, drawn
	# on ONE merged seamless mesh (_build_floor_mesh). The old per-tile crypt-brick
	# PlaneMesh is gone — it read as a repeating brick grid in every biome.

	_wall_mat = StandardMaterial3D.new()
	_wall_mat.albedo_color = Color(0.34, 0.31, 0.28)   # warm crypt stone
	_wall_mat.roughness = 0.78
	_wall_mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	_wall_mat.specular_mode = BaseMaterial3D.SPECULAR_TOON
	# Rim brightens grazing edges so dark walls + dark props keep their
	# silhouette in torchlight (reinforces the ink outline from the lit side).
	_wall_mat.rim_enabled = true
	_wall_mat.rim = 0.4
	_wall_mat.rim_tint = 0.4
	# Spec 26 follow-up — procedural noise normal map so the box walls
	# read as carved stone, not flat slabs. (The wall GLBs weren't a real
	# modular kit — wrong-sized pieces — so they're dropped for walls.)
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = 0.16
	noise.fractal_octaves = 4
	var nt := NoiseTexture2D.new()
	nt.noise = noise
	nt.as_normal_map = true
	# Env-quality: a whisper of normal that survives the toon bands, not realistic
	# relief — strong normals shatter the clean cel banding into noise (was 5.0).
	nt.bump_strength = 1.3
	nt.width = 256
	nt.height = 256
	_wall_mat.normal_enabled = true
	_wall_mat.normal_texture = nt

	var layout: Dictionary = _get_layout()
	if layout.is_empty():
		push_error("layout_loader: no layout")
		return
	_configure_wayweaver_room_presence(layout)

	# Biome palette — recolour the walls/floor by scope so a hollow / briar
	# run reads as a different place, not just a different spawn table. Done
	# before _build_grid (which bakes these materials into the tiles).
	_scope = String(layout.get("scope", "crypt"))
	_apply_biome_palette(_scope)            # wall palette only now
	_resolve_biome()                        # sets _biome_id
	_floor_mat = _make_floor_material(_biome_id)   # procedural toon ground (spec 50)
	_read_chart_modifiers()
	_build_first_hollow_forest_underlay(layout.grid)
	_build_grid(layout.grid, layout.get("perimeter_dressing", [])) # walls only now
	_build_floor_mesh(layout.grid)          # one merged seamless floor surface
	_build_bog_reflection(layout.grid)      # interior reflection for the wet bog pools
	_scatter_ground_cover(layout.grid)
	_scatter_seam_dressing(layout.grid)     # rubble softens the wall/floor seam
	_scatter_decals(layout.grid)            # moss/grime patches break the floor + add story
	_build_floor_collision(layout.grid)
	_build_navmesh(layout.grid)
	_build_kill_plane()
	# Spec 29 — _build_decor now needs the full layout dict so it can read
	# room_depths + the dungeon seed when stamping interactables.
	_build_decor(layout)
	_build_story_clues(layout)
	_build_campaign_clues(layout)
	# A Pale Veins return always has a readable Oath-Rubbing presentation.  This
	# is scenery only: the campaign ledger remains host-owned elsewhere, so a
	# reread cannot fake or duplicate an oath_rubbing fact.
	if _is_pale_veins_layout(layout):
		_build_guaranteed_oath_rubbing(layout)
	if _has_stonewake_affix():
		_build_stonewake(layout)
	# Wyrd — boss-as-affix: bossKind "" means no boss this run.
	if String(layout.get("bossKind", "")) != "":
		_build_boss(layout.bossRoom, layout.grid, String(layout.bossKind),
			layout.get("campaign_contract", {}), layout.get("encounter_contract", {}),
			layout.get("handoff_contract", {}))
	else:
		_build_empty_throne(layout)
	var enemy_n := _build_enemies(layout)
	_build_pack_reader_plate(layout)
	_build_cinderbound_vent(layout)
	_build_exit_waystone(layout)
	# Phase B — co-op: one body per peer at the entry; offline keeps the
	# baked player.
	var netr := get_node_or_null("/root/NetGame")
	if netr != null and bool(netr.active):
		net_spawn = Vector3(int(layout.entry.x) + 0.5, 0.0,
			int(layout.entry.y) + 0.5)
		netr.setup_scene(self)
	else:
		_position_player(layout.entry)

	# Dev: when DEBUG_SHOT (or WYRD_SHOT=1 in the env), self-capture a
	# viewport screenshot once the scene settles — lets the camera framing
	# be reviewed without a native-window screenshot. Off by default.
	if DEBUG_SHOT or OS.get_environment("WYRD_SHOT") != "":
		get_tree().create_timer(3.0).timeout.connect(_debug_screenshot)

	var seed_str := str(layout.get("seed", "static"))
	print("[layout_loader] crypt built — %d decor, %d enemies, boss=%s, seed=%s" % [
		(layout.decor as Array).size(), enemy_n, layout.bossKind, seed_str,
	])
	if DEBUG_SCORE and layout.has("score"):
		var s: Dictionary = layout.score
		print("[layout_loader] score=%.2f (conn=%.2f path=%.2f rooms=%.2f floor=%.2f corr=%.2f deadends=%.2f) attempts=%d" % [
			s.total, s.connectivity, s.critical_path, s.room_count,
			s.floor_ratio, s.corridor_ratio, s.dead_ends,
			int(layout.get("attempts", 1)),
		])
	if game0 != null and game0.has_method("web_smoke_scene_ready"):
		game0.web_smoke_scene_ready("World")


func _physics_process(_delta: float) -> void:
	# Feed every local/host-visible Player continuously, including net puppets.
	# Remote transforms arrive through Player's state snapshots; resolving here
	# makes the host's authoritative echo room key independent of a client claim.
	if _wayweaver_room_bounds.is_empty():
		return
	for raw in get_tree().get_nodes_in_group("player"):
		if raw is Node3D and raw.has_method("set_wayweaver_room_presence"):
			var player := raw as Node3D
			var presence := RoomPresenceScript.resolve(_wayweaver_run_epoch,
				_wayweaver_layer, player.global_position, _wayweaver_room_bounds)
			raw.call("set_wayweaver_room_presence", presence)


func _configure_wayweaver_room_presence(layout: Dictionary) -> void:
	_wayweaver_room_bounds = []
	for raw in layout.get("rooms", []):
		if raw is Dictionary:
			_wayweaver_room_bounds.append((raw as Dictionary).duplicate(true))
	var game := get_node_or_null("/root/Game")
	var chart: Dictionary = game.active_chart if game != null and game.active_chart is Dictionary else {}
	var stable := str(chart.get("chart_instance_id", layout.get("seed", "world")))
	# String.hash is deterministic for a chart identity across host/guests and
	# changes on a replacement run even if a debug seed is reused.
	_wayweaver_run_epoch = stable.hash()
	_wayweaver_layer = int(chart.get("layer", chart.get("current_layer", 0)))

# Wyrd — cache the active chart's combat modifiers before any spawns.
func _read_chart_modifiers() -> void:
	var game := get_tree().root.get_node_or_null("Game")
	if game == null:
		return
	if game.affix_good("tyrannical"):
		_hp_mult = 1.5
	if game.affix_good("frail_foes"):
		_hp_mult = 0.65
	if game.affix_good("quiet_halls"):
		_elite_chance_mult = 0.0
	if game.affix_good("elite_signs"):
		_guaranteed_pressure_elite = true
	if game.affix_bad("tyrannical"):
		_hp_jitter = true
	if game.affix_good("festival_pace"):
		_density_mult = 1.5
	if game.affix_bad("festival_pace"):
		_density_mult = 0.75
	# B6 — Sprinting Things: every enemy moves a quarter faster. The bad
	# twin slows the PLAYER instead (applied on the player at spawn).
	if game.affix_good("sprinter"):
		_speed_mult = 1.25
	# B6 — Bursting: corpses pop. Good scorches kin; Volatile (bad) also
	# scorches the player.
	if game.affix_good("bursting") or game.affix_bad("bursting"):
		_burst_on_death = true
		_burst_hits_player = game.affix_bad("bursting")
	# B6 wave 2.
	if game.affix_good("fog_of_hedge"):
		_aggro_mult = 0.65
	if game.affix_bad("fog_of_hedge"):
		_aggro_mult = 1.3
	if game.affix_good("frenzied"):
		_atk_speed_mult = 1.25
	if game.affix_bad("frenzied"):
		_dmg_mult = 1.15
	if game.affix_good("marked_quarry"):
		_trophy_mult = 2.0
	if game.affix_bad("marked_quarry"):
		_trophy_mult = 0.5
	var cfg: Dictionary = game.run_cfg()
	# Template base density (snug's gentle cellar) stacks with the affix.
	_density_mult *= float(cfg.get("enemy_density", 1.0))
	_dmg_mult *= float(cfg.get("enemy_damage_mult", 1.0))
	# ADR 0013 — the den's level scales enemy HP and damage (symmetric with the
	# player's per-level growth, so difficulty tracks level-delta, not absolutes).
	var den_lv: int = int(cfg.get("den_level", 3))
	var den_scale: float = pow(float(game.LEVEL_POWER), float(den_lv - 1))
	_hp_mult *= den_scale
	_dmg_mult *= den_scale

# Recolour the shared wall/floor materials by chart scope so a hollow / briar
# run reads as a different place. Albedo tints only (no texture swaps — keeps
# it crash-safe with the shipped crypt textures); crypt/summit keep defaults.
# Resolve the decor asset set for the active scope, and apply the biome's floor
# texture if it defines one (empty → keep the crypt brick). Behaviour-preserving
# for crypt and for any biome whose GLBs/textures haven't landed yet.
func _resolve_biome() -> void:
	_biome_id = String(SCOPE_BIOME.get(_scope, "crypt"))
	var b: Dictionary = BIOMES.get(_biome_id, {})
	_biome_decor = b.get("decor", {})
	_biome_tints = b.get("tints", {})
	# Floor look now comes from the procedural shader's per-biome uniforms
	# (FLOOR_BIOME / _make_floor_material), not a texture swap.
	_apply_biome_env()
	_build_ambient_motes()
	_build_vignette()

# Per-biome lighting + fog mood. Duplicates the WorldEnvironment's Environment
# (so we never mutate the packed .tscn resource across runs) and tints the Sun.
func _apply_biome_env() -> void:
	var e: Dictionary = BIOME_ENV.get(_biome_id, {})
	if e.is_empty():
		return
	var we := get_node_or_null("WorldEnvironment")
	if we != null and we.environment != null:
		var env: Environment = we.environment.duplicate()   # shallow → keeps the Sky
		env.ambient_light_color = e.ambient
		env.fog_light_color = e.fog
		env.fog_density = float(e.fog_density)
		env.glow_intensity = float(e.glow)
		# Telephoto FATE lens flattens depth — aerial perspective fades far walls
		# into the biome fog tint, sun-scatter glows the fog toward the Sun, and a
		# little height fog hugs the floor (cheap fg/mg/bg separation top-down).
		env.fog_aerial_perspective = 0.55
		env.fog_sun_scatter = 0.25
		env.fog_height = 2.5
		env.fog_height_density = float(e.fog_density) * 1.4
		# Volumetric fog — TRUE light shafts: the warm torches + Sun carve visible
		# god rays through it (the most cinematic atmosphere upgrade, and the one
		# genuinely non-cheap env feature). Moderate density stays readable;
		# forward anisotropy makes the scattering directional (shafts, not haze);
		# temporal reprojection denoises the froxels (the project has no TAA).
		env.volumetric_fog_enabled = true
		env.volumetric_fog_density = clampf(float(e.fog_density) * 2.2, 0.018, 0.055)
		env.volumetric_fog_albedo = e.fog
		env.volumetric_fog_anisotropy = 0.5
		env.volumetric_fog_length = 48.0
		env.volumetric_fog_temporal_reprojection_enabled = true
		# Color grade — a gentle saturation+contrast lift applied AFTER tonemap, so
		# it re-pops the cels Filmic mutes WITHOUT disturbing the glow HDR threshold
		# (Godot adjustments run post-tonemap). Kept gentle (sat ≤ 1.2) so it
		# doesn't reintroduce the wash. Per-biome where the mood wants it.
		env.adjustment_enabled = true
		env.adjustment_saturation = float(e.get("sat", 1.12))
		env.adjustment_contrast = float(e.get("contrast", 1.05))
		apply_web_tonal_grade(env, OS.has_feature("web"),
			OS.get_environment("WYRD_FORCE_WEB_GRADE"))
		we.environment = env
	var sun := get_node_or_null("Sun")
	if sun != null:
		sun.light_color = e.sun


# Public/static so the renderer contract can be tested without booting a full
# dungeon. WYRD_FORCE_WEB_GRADE is dev/test-only and never set by release code.
static func apply_web_tonal_grade(env: Environment, web_feature: bool,
		force_value: String = "") -> bool:
	if env == null or (not web_feature and force_value == ""):
		return false
	env.adjustment_enabled = true
	env.adjustment_brightness = WEB_GRADE_BRIGHTNESS
	env.adjustment_contrast = maxf(env.adjustment_contrast, WEB_GRADE_CONTRAST)
	return true

# One camera-following emitter of the biome's signature airborne mote.
func _build_ambient_motes() -> void:
	var e: Dictionary = BIOME_ENV.get(_biome_id, {})
	if not e.has("mote_amount"):
		return
	var p: GPUParticles3D = AmbientMotesScript.new()
	p.amount = int(e.mote_amount)
	p.lifetime = 9.0
	p.preprocess = 5.0          # pre-fill the box so it isn't empty on entry
	p.local_coords = false
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(8.0, 4.5, 8.0)
	pm.gravity = Vector3(0.0, float(e.mote_gravity), 0.0)
	pm.direction = Vector3(0.2, 0.1, 0.1)
	pm.spread = 80.0
	pm.initial_velocity_min = 0.04
	pm.initial_velocity_max = 0.22
	pm.scale_min = 0.6
	pm.scale_max = 1.3
	pm.color = e.mote_color
	p.process_material = pm
	var qm := QuadMesh.new()
	qm.size = Vector2(float(e.mote_size), float(e.mote_size))
	var mat := StandardMaterial3D.new()
	mat.albedo_color = e.mote_color
	mat.albedo_texture = SOFT_CIRCLE_TEX
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	var em: float = float(e.get("mote_emission", 0.0))
	if em > 0.0:
		mat.emission_enabled = true
		mat.emission = e.mote_color
		mat.emission_energy_multiplier = em
	qm.material = mat
	p.draw_pass_1 = qm
	add_child(p)
	p.emitting = true

# A gentle radial vignette (over the 3D, under the HUD) — pulls the eye to the
# player at frame center, strength driven per-biome from BIOME_ENV.
func _build_vignette() -> void:
	var strength: float = float(BIOME_ENV.get(_biome_id, {}).get("vignette", 0.28))
	var cl := CanvasLayer.new()
	cl.layer = 0   # over the 3D viewport, below the HUD (default CanvasLayer = 1)
	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sm := ShaderMaterial.new()
	sm.shader = VIGNETTE_SHADER
	sm.set_shader_parameter("strength", strength)
	rect.material = sm
	cl.add_child(rect)
	add_child(cl)

# Desaturate + slightly darken a tint so a satellite prop recedes behind the
# room's full-saturation focal (the one-saturation-peak rule).
func _desat(c: Color, sat_mult: float) -> Color:
	return Color.from_hsv(c.h, clampf(c.s * sat_mult, 0.0, 1.0), c.v * 0.92, c.a)

# A soft round contact shadow projected onto the floor under a prop/enemy so it
# visibly TOUCHES the ground — the #1 top-down "floating sticker" tell. As a
# child of a moving body it follows it. Texture preloaded (never load in _draw).
func _make_blob_shadow(radius: float) -> Decal:
	var d := Decal.new()
	d.texture_albedo = SOFT_CIRCLE_TEX
	d.modulate = Color(0.03, 0.04, 0.08)    # near-black, faint cool (matches ambient)
	d.albedo_mix = 0.58
	d.size = Vector3(radius * 2.0, 1.2, radius * 2.0)
	d.position = Vector3(0.0, 0.55, 0.0)
	d.distance_fade_enabled = true
	d.distance_fade_begin = 20.0
	d.distance_fade_length = 6.0
	return d

# The GLB path for a decor `kind` in the active biome: the biome's own override
# if it has one, else the crypt DECOR_MODEL, else "" (skip).
func _decor_model(kind: String) -> String:
	return String(_biome_decor.get(kind, DECOR_MODEL.get(kind, "")))

# Build the procedural toon-ground ShaderMaterial for a biome (spec 50). The
# merged floor receives its inverted-hull overlay at the MeshInstance seam; the
# interior linework is the shader's grout, by design.
func _make_floor_material(biome_id: String) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = FLOOR_SHADER
	var p: Dictionary = FLOOR_BIOME.get(biome_id, FLOOR_BIOME["crypt"])
	for k in p:
		m.set_shader_parameter(k, p[k])   # Color → vec4 source_color, float → float
	# Spec 69 — the First Road is a walked forest clearing, not another stone
	# dungeon wearing green light. Keep the shared one-draw-call shader, but push
	# its existing morph controls toward broad dirt-and-moss clumps with almost
	# no grout. Other wood-grove scopes retain their accepted material contract.
	if _scope == "snug":
		var first_road_ground := {
			"base_col": Color(0.50, 0.25, 0.11),
			"accent_col": Color(0.17, 0.32, 0.095),
			"mortar_col": Color(0.18, 0.15, 0.085),
			"cell_scale": 1.25,
			"cell_strength": 0.04,
			"mortar_width": 0.18,
			"noise_amt": 0.85,
			"mottle_scale": 0.16,
			"bevel": 0.05,
			"warp_amount": 1.10,
			"warp_freq": 0.28,
			"domain_rotation": 0.37,
		}
		for k in first_road_ground:
			m.set_shader_parameter(k, first_road_ground[k])
	return m

# Wall palette per scope (the floor is the procedural toon-ground shader now).
func _apply_biome_palette(scope: String) -> void:
	match scope:
		"hollow", "tier_1":
			_wall_mat.albedo_color = Color(0.28, 0.32, 0.24)     # dark earth
		"briar_maze":
			_wall_mat.albedo_color = Color(0.20, 0.26, 0.18)     # deep briar green
		"snug":
			_wall_mat.albedo_color = Color(0.44, 0.38, 0.30)     # rough clay
		"summit":
			_wall_mat.albedo_color = Color(0.42, 0.46, 0.52)     # cold grey rock
		"mire":
			_wall_mat.albedo_color = Color(0.24, 0.28, 0.22)     # dark bog stone
		"ashen_bough":
			_wall_mat.albedo_color = Color(0.25, 0.13, 0.10)     # charred rootstone
		_:
			pass   # crypt keeps the warm stone defaults

func _get_layout() -> Dictionary:
	if USE_PROCGEN:
		# Wyrd — a chart run hands its gen block + seed to the generator;
		# a dev boot of World.tscn (no Game / no active chart) keeps the
		# pre-chart defaults: random seed, full 48-grid, boss included.
		var game := get_tree().root.get_node_or_null("Game")
		var cfg: Dictionary = game.run_cfg() if game != null else {}
		print("[layout_loader] chart cfg: %s" % str(cfg))
		if game != null and game.has_method("take_pending_run_layout"):
			var prepared: Dictionary = game.take_pending_run_layout()
			if not prepared.is_empty():
				return prepared
		return DungeonGenScript.generate(int(cfg.get("seed", -1)), cfg)
	var f := FileAccess.open(JSON_PATH, FileAccess.READ)
	if f == null:
		push_error("layout_loader: %s not found" % JSON_PATH)
		return {}
	var raw := f.get_as_text()
	f.close()
	var parsed = JSON.parse_string(raw)
	if parsed == null:
		push_error("layout_loader: JSON parse failed")
		return {}
	return parsed

# ---- grid: visual floor planes + wall blocks ----
# Per-biome ground-cover scatter — ONE MultiMesh of tiny tinted bits across the
# floor tiles with per-instance rotation + scale + colour jitter, so the grid
# stops reading as identical tiles and each biome is signed on the ground.
# Shadow-casting off, no collider, no ink outline — pure cheap dressing.
func _scatter_ground_cover(grid: Array) -> void:
	var e: Dictionary = BIOME_GROUND.get(_biome_id, {})
	if e.is_empty():
		return
	var tiles: Array = []
	for y in grid.size():
		var row: Array = grid[y]
		for x in row.size():
			if String(row[x]) == "floor":
				tiles.append(Vector2i(x, y))
	var count: int = clampi(int(tiles.size() * float(e.density)), 0, 600)
	if count <= 0:
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = BoxMesh.new()
	mm.instance_count = count
	var base: Color = e.color
	var msc: Vector3 = e.mscale
	for i in count:
		var t: Vector2i = tiles[_rng.randi_range(0, tiles.size() - 1)]
		var px := float(t.x) + _rng.randf()
		var pz := float(t.y) + _rng.randf()
		var s := float(e.size) * _rng.randf_range(0.65, 1.35)
		var b := Basis().rotated(Vector3.UP, _rng.randf() * TAU).scaled(msc * s)
		mm.set_instance_transform(i, Transform3D(b,
			Vector3(px, 0.02 + msc.y * s * 0.5, pz)))
		var j := _rng.randf_range(-0.07, 0.07)
		mm.set_instance_color(i, Color(clampf(base.r + j, 0.0, 1.0),
			clampf(base.g + j, 0.0, 1.0), clampf(base.b + j, 0.0, 1.0)))
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.85
	mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	var em: float = float(e.get("emission", 0.0))
	if em > 0.0:
		mat.emission_enabled = true
		mat.emission = base
		mat.emission_energy_multiplier = em
	mmi.material_override = mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)

# Edge/corner seam dressing — chunky rubble piled against wall-adjacent floor
# tiles, offset toward the wall, to soften the hard 90° wall/floor seam (the
# worst box-dungeon tell). One MultiMesh, shadow off, biome-tinted (darker/greyer
# than the ground cover). Inner corners (2+ walls) naturally get denser piles.
func _scatter_seam_dressing(grid: Array) -> void:
	var e: Dictionary = BIOME_GROUND.get(_biome_id, {})
	if e.is_empty():
		return
	var seams: Array = []
	const NB := [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]
	for y in grid.size():
		var row: Array = grid[y]
		for x in row.size():
			if String(row[x]) != "floor":
				continue
			var dir := Vector2.ZERO
			var touch := false
			for off in NB:
				var nx: int = x + off.x
				var ny: int = y + off.y
				if ny >= 0 and ny < grid.size() and nx >= 0 and nx < grid[ny].size() \
						and String(grid[ny][nx]) == "wall":
					dir += Vector2(off.x, off.y)
					touch = true
			if touch:
				seams.append([x, y, dir])
	if seams.is_empty():
		return
	var per := 1 if _scope == "snug" else 2
	var count: int = mini(seams.size() * per, 700)
	if count <= 0:
		return
	var base: Color = Color(0.20, 0.24, 0.14) if _scope == "snug" else \
		_desat(e.color, 0.7).darkened(0.18)   # rubble = darker, greyer
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	if _scope == "snug":
		var moss_mesh := SphereMesh.new()
		moss_mesh.radial_segments = 6
		moss_mesh.rings = 3
		moss_mesh.radius = 0.5
		moss_mesh.height = 1.0
		mm.mesh = moss_mesh
	else:
		mm.mesh = BoxMesh.new()
	mm.instance_count = count
	var msc := Vector3(1.0, 0.6, 1.0)
	var i := 0
	for s in seams:
		var d: Vector2 = s[2]
		if d.length() > 0.01:
			d = d.normalized()
		for _k in per:
			if i >= count:
				break
			var px := float(s[0]) + 0.5 + d.x * 0.36 + _rng.randf_range(-0.18, 0.18)
			var pz := float(s[1]) + 0.5 + d.y * 0.36 + _rng.randf_range(-0.18, 0.18)
			var sz := float(e.size) * _rng.randf_range(0.9, 1.8)   # chunkier than ground cover
			var b := Basis().rotated(Vector3.UP, _rng.randf() * TAU).scaled(msc * sz)
			mm.set_instance_transform(i, Transform3D(b,
				Vector3(px, 0.02 + msc.y * sz * 0.5, pz)))
			var j := _rng.randf_range(-0.06, 0.06)
			mm.set_instance_color(i, Color(clampf(base.r + j, 0.0, 1.0),
				clampf(base.g + j, 0.0, 1.0), clampf(base.b + j, 0.0, 1.0)))
			i += 1
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.9
	mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	mmi.material_override = mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)

# Soft moss/grime/frost decal patches, biased into wall corners and spanning tile
# boundaries so they break the floor grid and add lived-in story. Reuses the
# soft-circle texture; Forward+ clusters decals cheaply. Built with the room
# (runtime decal creation mid-play can hitch, per Godot forum).
func _scatter_decals(grid: Array) -> void:
	var tint: Color = BIOME_DECAL.get(_biome_id, Color(0.16, 0.13, 0.10))
	var seams: Array = []
	var floors: Array = []
	const NB := [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]
	for y in grid.size():
		var row: Array = grid[y]
		for x in row.size():
			if String(row[x]) != "floor":
				continue
			floors.append(Vector2i(x, y))
			for off in NB:
				var nx: int = x + off.x
				var ny: int = y + off.y
				if ny >= 0 and ny < grid.size() and nx >= 0 and nx < grid[ny].size() \
						and String(grid[ny][nx]) == "wall":
					seams.append(Vector2i(x, y))
					break
	if floors.is_empty():
		return
	var count: int = clampi(int(floors.size() * 0.10), 4, 28)
	for _i in count:
		# 70% biased into corners/edges where grime gathers, else anywhere.
		var pool: Array = seams if (not seams.is_empty() and _rng.randf() < 0.7) else floors
		var t: Vector2i = pool[_rng.randi_range(0, pool.size() - 1)]
		var d := Decal.new()
		d.texture_albedo = SOFT_CIRCLE_TEX
		d.modulate = tint
		d.albedo_mix = _rng.randf_range(0.55, 0.8)
		var sz := _rng.randf_range(1.3, 2.6)
		d.size = Vector3(sz, 1.0, sz)
		d.rotation.y = _rng.randf() * TAU
		d.position = Vector3(float(t.x) + 0.5 + _rng.randf_range(-0.4, 0.4), 0.5,
			float(t.y) + 0.5 + _rng.randf_range(-0.4, 0.4))
		d.distance_fade_enabled = true
		d.distance_fade_begin = 22.0
		d.distance_fade_length = 6.0
		add_child(d)

# Faked bog-water reflection — the procedural floor's wet pools are glossy
# (roughness 0.12), but in an enclosed cave they'd mirror the bright procedural
# SKY (wrong). One Interior ReflectionProbe over the play area gives the pools a
# dark cavern reflection instead — cheap, art-directed, NOT global SSR. Bog only.
func _build_bog_reflection(grid: Array) -> void:
	# The WebGL Compatibility path faults while resolving this one-shot cubemap
	# capture's depth/stencil buffer. The probe is optional bog-water polish;
	# preserve it for native renderers and let the Web floor keep its authored
	# wetness without a browser console error.
	if OS.has_feature("web"):
		return
	if _biome_id != "bog":
		return
	var minx := 1.0e9
	var maxx := -1.0e9
	var minz := 1.0e9
	var maxz := -1.0e9
	for y in grid.size():
		var row: Array = grid[y]
		for x in row.size():
			if String(row[x]) == "floor":
				minx = minf(minx, float(x))
				maxx = maxf(maxx, float(x))
				minz = minf(minz, float(y))
				maxz = maxf(maxz, float(y))
	if maxx < minx:
		return
	var rp := ReflectionProbe.new()
	rp.position = Vector3((minx + maxx) * 0.5 + 0.5, 2.5, (minz + maxz) * 0.5 + 0.5)
	rp.size = Vector3((maxx - minx) + 8.0, 8.0, (maxz - minz) + 8.0)
	rp.interior = true                                  # don't blend the sky into a cave
	rp.update_mode = ReflectionProbe.UPDATE_ONCE        # bake once at load
	rp.ambient_mode = ReflectionProbe.AMBIENT_DISABLED  # reflection only; ambient is ours
	rp.max_distance = 64.0
	add_child(rp)

func _build_grid(grid: Array, perimeter_dressing: Array = []) -> void:
	var perimeter_by_cell := {}
	for profile_v in perimeter_dressing:
		if not profile_v is Dictionary:
			continue
		var profile: Dictionary = profile_v
		perimeter_by_cell["%d:%d" % [int(profile.get("x", -1)),
			int(profile.get("y", -1))]] = profile
	for y in grid.size():
		var row: Array = grid[y]
		for x in row.size():
			if String(row[x]) == "wall" \
					and (_scope != "snug" or _is_floor_boundary(grid, x, y)):
				_place_wall(x, y, grid,
					perimeter_by_cell.get("%d:%d" % [x, y], {}))


# Spec 68 — one presentation-only forest bed beneath the First Road. The
# playable merged floor remains the only visible surface at y=0 and the only
# source of collision/nav truth; this lower matte merely prevents gaps beyond
# the authored boundary from falling directly to the black clear color.
func _build_first_hollow_forest_underlay(grid: Array) -> void:
	if _scope != "snug" or grid.is_empty() or (grid[0] as Array).is_empty():
		return
	var width := float((grid[0] as Array).size())
	var depth := float(grid.size())
	var plane := PlaneMesh.new()
	plane.size = Vector2(width + 24.0, depth + 24.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.055, 0.105, 0.050)
	mat.roughness = 1.0
	mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	var underlay := MeshInstance3D.new()
	underlay.name = "FirstHollowForestUnderlay"
	underlay.mesh = plane
	underlay.material_override = mat
	underlay.position = Vector3(width * 0.5, -0.22, depth * 0.5)
	underlay.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	underlay.set_meta("presentation_only", true)
	underlay.set_meta("grid_size", Vector2(width, depth))
	add_child(underlay)

func _is_floor_boundary(grid: Array, x: int, y: int) -> bool:
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			if _is_floor(grid, x + dx, y + dy):
				return true
	return false

# ONE merged surface for the whole walkable floor = ONE draw call. The procedural
# ground shader samples WORLD XZ, so the merged 1x1 quads share one continuous
# seamless field (no per-tile UV, non-rectangular footprints just work).
# Collision/navmesh stay their own passes — this is the VISUAL floor only.
func _build_floor_mesh(grid: Array) -> void:
	var unit := PlaneMesh.new()
	unit.size = Vector2(1.0, 1.0)          # XZ plane, +Y normal
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var any := false
	for y in grid.size():
		var row: Array = grid[y]
		for x in row.size():
			if String(row[x]) == "floor":
				st.append_from(unit, 0,
					Transform3D(Basis(), Vector3(x + 0.5, 0.0, y + 0.5)))
				any = true
	if not any:
		return
	var mi := MeshInstance3D.new()
	mi.name = "FloorMerged"
	mi.mesh = st.commit()
	mi.material_override = _floor_mat
	mi.material_overlay = _make_outline_pass()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF   # floor receives, doesn't cast
	add_child(mi)

# Walls (spec 24) — raised to 3.6 m so zones read as enclosed rooms, not a
# low-walled topographic maze (playtest: "zones feel tight"). Camera-occlusion
# fade (group "wall") keeps the near walls from blocking the view.
const WALL_HEIGHT := 3.6

const WALL_GLB := {
	"straight":    preload("res://models/dungeon_crypt_wall-straight_v1.glb"),
	"cornerInner": preload("res://models/dungeon_crypt_wall-corner-inner_v1.glb"),
	"cornerOuter": preload("res://models/dungeon_crypt_wall-corner-outer_v1.glb"),
}
# Native GLB extents (probed) — used to scale each piece into a 1×H×1 tile.
const WALL_NATIVE := {
	"straight":    Vector3(1.90, 1.23, 0.40),
	"cornerInner": Vector3(1.51, 1.90, 1.50),
	"cornerOuter": Vector3(1.69, 1.91, 1.79),
}

func _place_wall(x: int, y: int, grid: Array,
		perimeter_profile: Dictionary = {}) -> void:
	var body := StaticBody3D.new()
	body.position = Vector3(x + 0.5, WALL_HEIGHT * 0.5, y + 0.5)
	body.collision_layer = LAYER_WORLD
	body.collision_mask = 0
	body.add_to_group("wall")          # camera occlusion fades these

	if _scope == "snug":
		_place_first_hollow_wall_visual(body, x, y, perimeter_profile)
	else:
		_place_box_wall_visual(body)

	# Collision stays a plain box: presentation can vary without changing the
	# authoritative walkable boundary or opening diagonal corner leaks.
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.0, WALL_HEIGHT, 1.0)
	var col := CollisionShape3D.new()
	col.shape = shape
	body.add_child(col)
	add_child(body)


func _wall_material(jit: float) -> StandardMaterial3D:
	var wmat: StandardMaterial3D = _wall_mat.duplicate()
	wmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var base: Color = _wall_mat.albedo_color
	wmat.albedo_color = Color(
		clampf(base.r + jit, 0.0, 1.0),
		clampf(base.g + jit, 0.0, 1.0),
		clampf(base.b + jit, 0.0, 1.0), 1.0)
	return wmat


func _place_box_wall_visual(body: StaticBody3D) -> void:
	# Preserve the established wall treatment outside the bounded First Road
	# proof until its native and Web result earns biome-wide propagation.
	var mesh := BoxMesh.new()
	mesh.size = Vector3(1.0, WALL_HEIGHT, 1.0)
	var mi := MeshInstance3D.new()
	mi.name = "WallMesh"
	mi.mesh = mesh
	mi.material_override = _wall_material(_rng.randf_range(-0.05, 0.05))
	body.add_child(mi)


func _place_first_hollow_wall_visual(body: StaticBody3D, x: int, y: int,
		perimeter_profile: Dictionary = {}) -> void:
	# Coordinate-derived variation remains stable even though deep exterior
	# cells no longer consume RNG or instantiate nodes.
	var local_rng := RandomNumberGenerator.new()
	local_rng.seed = (_wall_seed ^ (x * 73856093) ^ (y * 19349663)) \
		& 0x7FFFFFFFFFFFFFFF
	var visual := Node3D.new()
	visual.name = "WallMesh"
	# Profiles orient from generated floor truth. Individual pieces carry their
	# own jitter; rotating the root would rotate its outward backdrop back toward
	# the playable floor at corners.
	visual.rotation.y = 0.0
	visual.scale = Vector3(local_rng.randf_range(0.88, 1.12), 1.0,
		local_rng.randf_range(0.88, 1.12))
	var profile_id := String(perimeter_profile.get("profile", "leaf_bank"))
	visual.set_meta("perimeter_profile", profile_id)
	visual.set_meta("room_id", int(perimeter_profile.get("room_id", -1)))
	visual.set_meta("landmark", bool(perimeter_profile.get("landmark", false)))
	body.set_meta("perimeter_profile", profile_id)
	body.set_meta("perimeter_room_id", int(perimeter_profile.get("room_id", -1)))
	body.set_meta("perimeter_landmark", bool(perimeter_profile.get("landmark", false)))
	body.add_child(visual)

	_add_first_hollow_bank_base(visual, local_rng, profile_id)
	var inward := Vector3(float(perimeter_profile.get("inward_x", 0)), 0.0,
		float(perimeter_profile.get("inward_y", 1)))
	if inward.length_squared() < 0.1:
		inward = Vector3.FORWARD
	_add_first_hollow_backdrop(visual, local_rng, -inward.normalized())
	match profile_id:
		"root_bank":
			_add_first_hollow_roots(visual, local_rng, false)
		"stone_bank":
			_add_first_hollow_stones(visual, local_rng)
		"fern_bank":
			_add_first_hollow_ferns(visual, local_rng)
		"bramble_bank":
			_add_first_hollow_bramble(visual, local_rng)
		"fallen_log":
			_add_first_hollow_landmark(visual, local_rng, profile_id)
		"lantern_oak", "old_oak", "bramble_oak", "hearth_oak":
			_add_first_hollow_landmark(visual, local_rng, profile_id)
		_:
			_add_first_hollow_leaves(visual, local_rng, false)


func _first_hollow_material(color: Color) -> StandardMaterial3D:
	var mat := _wall_material(0.0)
	mat.albedo_color = color
	mat.roughness = 0.9
	return mat


func _first_hollow_sphere(parent: Node3D, node_name: String, position: Vector3,
		radius: float, height: float, color: Color, scale: Vector3 = Vector3.ONE,
		outline: bool = false) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radial_segments = 7
	mesh.rings = 4
	mesh.radius = radius
	mesh.height = maxf(height, radius * 2.0)
	var mi := MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = mesh
	mi.position = position
	mi.scale = scale
	mi.material_override = _first_hollow_material(color)
	if outline:
		mi.material_overlay = _make_outline_pass()
	parent.add_child(mi)
	return mi


func _first_hollow_cylinder(parent: Node3D, node_name: String,
		position: Vector3, height: float, radius: float, color: Color,
		rotation: Vector3 = Vector3.ZERO, top_scale: float = 0.78,
		outline: bool = false) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.radial_segments = 7
	mesh.rings = 1
	mesh.height = height
	mesh.bottom_radius = radius
	mesh.top_radius = maxf(0.01, radius * top_scale)
	var mi := MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = mesh
	mi.position = position
	mi.rotation = rotation
	mi.material_override = _first_hollow_material(color)
	if outline:
		mi.material_overlay = _make_outline_pass()
	parent.add_child(mi)
	return mi


func _add_first_hollow_bank_base(visual: Node3D,
		local_rng: RandomNumberGenerator, profile_id: String) -> void:
	var tone := local_rng.randf_range(-0.025, 0.025)
	var base_color := Color(0.18 + tone, 0.27 + tone, 0.12 + tone * 0.5)
	if profile_id in ["root_bank", "fallen_log"]:
		base_color = Color(0.25 + tone, 0.24 + tone, 0.13)
	elif profile_id == "stone_bank":
		base_color = Color(0.29 + tone, 0.31 + tone, 0.24 + tone)
	_first_hollow_sphere(visual, "Rootstone", Vector3(0.0, -1.13, 0.0),
		0.64, local_rng.randf_range(1.28, 1.48), base_color,
		Vector3(local_rng.randf_range(1.05, 1.32), 1.0,
			local_rng.randf_range(0.82, 1.10)), true)
	_first_hollow_sphere(visual, "BrambleShoulder",
		Vector3(local_rng.randf_range(-0.36, 0.36), -1.23,
			local_rng.randf_range(-0.28, 0.28)), 0.42,
		local_rng.randf_range(0.84, 1.02), base_color.lightened(0.035),
		Vector3(local_rng.randf_range(0.9, 1.2), 1.0,
			local_rng.randf_range(0.9, 1.2)))


func _add_first_hollow_backdrop(visual: Node3D,
		local_rng: RandomNumberGenerator, outward: Vector3) -> void:
	# A dark, non-colliding two-tier shoulder extends behind the real boundary.
	# It supplies the concept's continuous forest depth without rebuilding the
	# deleted exterior wall field. Both tiers still lower with WallMesh.
	var tangent := Vector3(-outward.z, 0.0, outward.x)
	for i in 2:
		var far_tier := i == 1
		var tier_depth := 1.72 if far_tier else 0.92
		var side := (0.38 if far_tier else -0.32) \
			+ local_rng.randf_range(-0.16, 0.16)
		var color := Color(0.055, 0.135, 0.040) if far_tier \
			else Color(0.085, 0.185, 0.060)
		var mass := _first_hollow_sphere(visual, "RearFoliage%d" % i,
			outward * (tier_depth + local_rng.randf_range(-0.10, 0.14)) \
				+ tangent * side \
				+ Vector3(0.0, local_rng.randf_range(-1.08, -0.88), 0.0),
			0.58 if far_tier else 0.45,
			local_rng.randf_range(1.30, 1.55) if far_tier \
				else local_rng.randf_range(0.96, 1.18),
			color,
			Vector3(local_rng.randf_range(0.94, 1.10), 1.0,
				local_rng.randf_range(0.94, 1.10)))
		mass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mass.set_meta("presentation_only", true)
		mass.set_meta("depth_tier", i)


func _add_first_hollow_leaves(visual: Node3D,
		local_rng: RandomNumberGenerator, dark: bool) -> void:
	var colors := [Color(0.16, 0.28, 0.10), Color(0.21, 0.35, 0.12),
		Color(0.27, 0.40, 0.14)]
	if dark:
		colors = [Color(0.11, 0.21, 0.07), Color(0.15, 0.27, 0.09),
			Color(0.19, 0.31, 0.10)]
	for i in 3:
		var side := float(i - 1) * 0.34 + local_rng.randf_range(-0.08, 0.08)
		_first_hollow_sphere(visual, "LeafCluster%d" % i,
			Vector3(side, -0.80 + local_rng.randf_range(-0.08, 0.18),
				local_rng.randf_range(-0.20, 0.20)),
			local_rng.randf_range(0.35, 0.48),
			local_rng.randf_range(0.78, 1.12), colors[i],
			Vector3(local_rng.randf_range(1.05, 1.34),
				local_rng.randf_range(0.68, 0.84),
				local_rng.randf_range(0.88, 1.16)))


func _add_first_hollow_roots(visual: Node3D,
		local_rng: RandomNumberGenerator, brambled: bool) -> void:
	var root_color := Color(0.30, 0.20, 0.11) if not brambled else Color(0.23, 0.14, 0.09)
	for i in 2:
		_first_hollow_cylinder(visual, "Root%d" % i,
			Vector3(local_rng.randf_range(-0.24, 0.24), -1.18,
				local_rng.randf_range(-0.18, 0.18)),
			local_rng.randf_range(1.15, 1.55), local_rng.randf_range(0.08, 0.13),
			root_color, Vector3(0.0, 0.0,
				local_rng.randf_range(-1.25, 1.25)), 0.55)
	_add_first_hollow_leaves(visual, local_rng, brambled)


func _add_first_hollow_stones(visual: Node3D,
		local_rng: RandomNumberGenerator) -> void:
	_add_first_hollow_prop(visual, "MossBoulder",
		"res://models/biome_wood_grove_boulder_v1.glb",
		Vector3(0.0, -1.80, 0.0), Vector3(0.72, 0.72, 0.72),
		Color(0.32, 0.36, 0.27))
	for i in 2:
		_first_hollow_sphere(visual, "MossStone%d" % i,
			Vector3(float(i * 2 - 1) * 0.27, -1.04,
				local_rng.randf_range(-0.12, 0.16)),
			local_rng.randf_range(0.28, 0.38),
			local_rng.randf_range(0.62, 0.84),
			Color(0.36, 0.38, 0.30).darkened(float(i) * 0.06),
			Vector3(1.15, 1.0, 0.92))
	_first_hollow_sphere(visual, "StoneMoss", Vector3(0.0, -0.78, 0.04),
		0.28, 0.58, Color(0.28, 0.43, 0.18), Vector3(1.25, 1.0, 0.9))


func _add_first_hollow_ferns(visual: Node3D,
		local_rng: RandomNumberGenerator) -> void:
	_add_first_hollow_prop(visual, "FernCluster",
		"res://models/biome_wood_grove_fern_v1.glb",
		Vector3(0.0, -1.80, 0.0),
		Vector3.ONE * local_rng.randf_range(0.78, 1.04),
		Color(0.24, 0.46, 0.16))
	_first_hollow_sphere(visual, "FernMoss", Vector3(0.18, -1.16, 0.05),
		0.30, 0.62, Color(0.18, 0.34, 0.11), Vector3(1.5, 0.55, 1.0))


func _add_first_hollow_bramble(visual: Node3D,
		local_rng: RandomNumberGenerator) -> void:
	_add_first_hollow_roots(visual, local_rng, true)
	for i in 2:
		_first_hollow_cylinder(visual, "Bramble%d" % i,
			Vector3(float(i * 2 - 1) * 0.24, -0.44,
				local_rng.randf_range(-0.14, 0.14)), 1.08, 0.07,
			Color(0.22, 0.13, 0.09), Vector3(0.0, 0.0,
				(-0.42 if i == 0 else 0.42)), 0.35)


func _add_first_hollow_landmark(visual: Node3D,
		local_rng: RandomNumberGenerator, profile_id: String) -> void:
	var landmark := Node3D.new()
	landmark.name = "PerimeterLandmark"
	landmark.set_meta("profile", profile_id)
	visual.add_child(landmark)
	if profile_id == "fallen_log":
		_add_first_hollow_prop(landmark, "FallenLog",
			"res://models/biome_wood_grove_log_v1.glb",
			Vector3(0.0, -1.80, 0.0), Vector3(0.88, 0.88, 0.88),
			Color(0.32, 0.25, 0.13))
		_first_hollow_sphere(landmark, "LogMoss", Vector3(0.0, -0.64, 0.0),
			0.30, 0.62, Color(0.27, 0.43, 0.16), Vector3(1.55, 0.55, 0.9))
		return

	var trunk_color := Color(0.31, 0.20, 0.11)
	if profile_id == "bramble_oak":
		trunk_color = Color(0.23, 0.14, 0.09)
	_first_hollow_cylinder(landmark, "Trunk", Vector3(0.0, -0.34, 0.0),
		2.60, local_rng.randf_range(0.20, 0.27), trunk_color,
		Vector3(0.0, 0.0, local_rng.randf_range(-0.10, 0.10)), 0.72, true)
	var canopy_colors := [Color(0.13, 0.25, 0.08), Color(0.18, 0.32, 0.10),
		Color(0.25, 0.39, 0.12)]
	if profile_id == "bramble_oak":
		canopy_colors = [Color(0.12, 0.22, 0.08), Color(0.17, 0.29, 0.10),
			Color(0.24, 0.35, 0.11)]
	elif profile_id == "hearth_oak":
		canopy_colors = [Color(0.22, 0.31, 0.11), Color(0.34, 0.42, 0.12),
			Color(0.47, 0.47, 0.13)]
	for i in 5:
		_first_hollow_sphere(landmark, "Canopy%d" % i,
			Vector3(float(i - 2) * 0.26, 0.96 + float(i % 2) * 0.18,
				local_rng.randf_range(-0.18, 0.18)),
			0.48, local_rng.randf_range(1.02, 1.26), canopy_colors[i % 3],
			Vector3(local_rng.randf_range(0.92, 1.18), 1.0,
				local_rng.randf_range(0.88, 1.14)), i == 2)
	if profile_id == "lantern_oak":
		var glow := _first_hollow_sphere(landmark, "LanternGlow",
			Vector3(0.36, 0.18, 0.10), 0.10, 0.22,
			Color(1.0, 0.68, 0.20), Vector3.ONE)
		var glow_mat := glow.material_override as StandardMaterial3D
		glow_mat.emission_enabled = true
		glow_mat.emission = Color(1.0, 0.52, 0.12)
		glow_mat.emission_energy_multiplier = 2.0


func _add_first_hollow_prop(parent: Node3D, node_name: String, path: String,
		position: Vector3, scale: Vector3, color: Color) -> Node3D:
	if not ResourceLoader.exists(path):
		return null
	var packed: PackedScene = load(path)
	if packed == null:
		return null
	var prop := packed.instantiate() as Node3D
	if prop == null:
		return null
	prop.name = node_name
	prop.position = position
	prop.scale = scale
	parent.add_child(prop)
	_unmetal(prop)
	_tint(prop, color)
	return prop

func _is_floor(grid: Array, x: int, y: int) -> bool:
	if y < 0 or y >= grid.size() or x < 0 or x >= grid[0].size():
		return false
	return String(grid[y][x]) == "floor"

# ---- floor collision: one thin box per floor tile, top surface at y=0 ----
func _build_floor_collision(grid: Array) -> void:
	var body := StaticBody3D.new()
	body.name = "FloorCollision"
	body.collision_layer = LAYER_WORLD
	body.collision_mask = 0
	for y in grid.size():
		var row: Array = grid[y]
		for x in row.size():
			if String(row[x]) != "floor":
				continue
			var shape := BoxShape3D.new()
			shape.size = Vector3(1.0, 0.2, 1.0)
			var col := CollisionShape3D.new()
			col.shape = shape
			col.position = Vector3(x + 0.5, -0.1, y + 0.5)
			body.add_child(col)
	add_child(body)

# ---- navmesh: one quad per walkable tile, assembled into a connected
# NavigationMesh so enemies route around walls (spec 19) ----
func _build_navmesh(grid: Array) -> void:
	var verts := PackedVector3Array()
	var index := {}                      # grid-corner Vector2i → vertex idx
	var polys: Array = []
	for y in grid.size():
		var row: Array = grid[y]
		for x in row.size():
			if String(row[x]) != "floor":
				continue
			var poly := PackedInt32Array()
			# corners CCW-from-above so the polygon faces +Y
			for c in [Vector2i(x, y), Vector2i(x, y + 1),
					Vector2i(x + 1, y + 1), Vector2i(x + 1, y)]:
				if not index.has(c):
					index[c] = verts.size()
					verts.append(Vector3(c.x, 0.05, c.y))
				poly.append(index[c])
			polys.append(poly)
	var nav := NavigationMesh.new()
	nav.vertices = verts
	for p in polys:
		nav.add_polygon(p)
	var region := NavigationRegion3D.new()
	region.name = "CryptNav"
	region.navigation_mesh = nav
	add_child(region)
	print("[layout_loader] navmesh — %d tiles, %d verts" % [polys.size(), verts.size()])

# ---- kill-plane: fall off the floor → respawn at entry ----
func _build_kill_plane() -> void:
	var area := Area3D.new()
	area.name = "KillPlane"
	var shape := WorldBoundaryShape3D.new()
	shape.plane = Plane(Vector3.UP, KILL_PLANE_Y)
	var col := CollisionShape3D.new()
	col.shape = shape
	area.add_child(col)
	add_child(area)
	area.body_entered.connect(_on_kill_plane_entered)

func _on_kill_plane_entered(body: Node) -> void:
	if body.is_in_group("player") and body is Node3D:
		(body as Node3D).global_position = _entry_pos
		if body is CharacterBody3D:
			(body as CharacterBody3D).velocity = Vector3.ZERO

# ---- decor ----
# Spec 29 — decor entries with `interact_role` get the typed-room
# interactable scene (Chest / Shrine / Hearth) at the focal cell instead of
# the static GLB. Everything else is the spec 25/28 themed-dressing path.
const ChestScene := preload("res://scenes/Chest.tscn")
const ShrineScene := preload("res://scenes/Shrine.tscn")
const HearthScene := preload("res://scenes/Hearth.tscn")

func _build_decor(layout: Dictionary) -> void:
	var decor: Array = layout.get("decor", [])
	var depths: Array = layout.get("room_depths", [])
	var dungeon_seed: int = int(layout.get("seed", 0))
	for d in decor:
		# Spec 73 — generator reservations can preserve downstream seeded
		# placement without realizing an obstructive setpiece support mesh.
		if bool(d.get("presentation_hidden", false)):
			continue
		# The authored rootroad IDs are not aliases for crypt dressing.  Consume
		# them directly when a future pale_veins layout emits them, keeping static
		# landmark identity stable while gather/campaign ownership stays external.
		if _biome_id == "rootroads" and ROOTROAD_ID_MODEL.has(String(d.get("kind", ""))):
			_build_rootroad_id_prop(d)
			continue
		# Wyrd — gather nodes (chart bias affixes) fork before everything.
		if bool(d.get("gather", false)):
			var rootroad_ore := String(d.get("ore_tier", "")) in ["wildgold", "waysteel"]
			var rootroad_herb := String(d.get("herb_tier", "")) in [
				"wellmoss", "wellwater", "embersage", "root_sap"]
			var is_rootroad_gather := _biome_id in ["rootroads", "ashen_bough"] \
				and (rootroad_ore or rootroad_herb)
			var gn: Node3D = RootroadGatherNodeScript.new() if is_rootroad_gather else GatherNodeScript.new()
			gn.setup(String(d.kind), String(d.get("item", "wild_herb")))
			if d.has("ore_tier"):
				gn.setup_ore_tier(String(d.ore_tier))
			elif d.has("herb_tier"):
				gn.setup_herb_tier(String(d.herb_tier))
			gn.position = Vector3(int(d.x) + 0.5, 0.0, int(d.y) + 0.5)
			add_child(gn)
			continue
		# Spec 29 — typed-room focal interactables fork before the GLB path.
		var ir := String(d.get("interact_role", ""))
		if ir != "":
			_build_interactable(ir, d, depths, dungeon_seed)
			continue
		var kind := String(d.kind)
		var model_path := _decor_model(kind)
		if model_path == "":
			continue
		# Biome filter — crypt sarcophagi don't belong in a hollow / briar run,
		# UNLESS the active biome remaps the sarcophagus slot to its own prop
		# (e.g. mineral_seam → mine cart).
		if kind == "sarcophagus" and not _biome_decor.has("sarcophagus") \
				and _scope != "crypt" and _scope != "summit":
			continue
		var packed: PackedScene = load(model_path)
		if packed == null:
			continue
		var inst: Node3D = packed.instantiate()
		# Spec 72 — composition data owns support-prop hierarchy.  Scale only
		# the rendered model; established conservative collision boxes remain
		# gameplay truth and now align more closely with the visible footprint.
		var visual_scale := clampf(float(d.get("visual_scale", 1.0)), 0.5, 1.0)
		inst.scale = Vector3.ONE * visual_scale
		# Biome props ship untextured (white) — paint them like the enemy GLBs
		# (single thematic tint + ink outline) so they read as chunky toon, not
		# flat-grey blobs. Crypt decor keeps its own baked GLB materials.
		if _biome_decor.has(kind):
			_unmetal(inst)
			if _biome_tints.has(kind):
				# Saturation hierarchy: the room's focal prop keeps full
				# saturation (the eye's anchor); satellites recede so the screen
				# doesn't read as candy mush (one saturation peak per room).
				var tcol: Color = _biome_tints[kind]
				if not bool(d.get("focal", false)):
					tcol = _desat(tcol, 0.6)
				_tint(inst, tcol)
			else:
				_outline_only(inst)
		var box = DECOR_COLLIDER.get(kind, null)
		# Spec 28 — read the orient cardinal placed by dungeon_gen; rotate
		# the body (or pass-through instance) so wall-edge decor faces the
		# room interior. Symmetric kinds (column/pottery/bones) are visually
		# unaffected by Y rotation — harmless to apply uniformly.
		var orient := String(d.get("orient", "center"))
		var ry: float = ORIENT_RY.get(orient, 0.0) \
			+ float(DECOR_FACING_OFFSET.get(kind, 0.0))
		if box == null:
			# Pass-through decor — plain instance.
			inst.position = Vector3(int(d.x) + 0.5, 0.05, int(d.y) + 0.5)
			inst.rotation.y = ry
			add_child(inst)
			# Torches cast a warm pool of light (spec 16 dramatic lighting).
			if kind == "torch_wall":
				_add_torch_light(int(d.x) + 0.5, int(d.y) + 0.5)
		else:
			# Breakable decor (spec 26) — wrap in a Breakable that also has a
			# Hurtbox the player's arrows can hit. Otherwise: plain StaticBody3D.
			var breakable := DECOR_BREAKABLE.has(kind)
			var body: StaticBody3D = BreakableScript.new() if breakable else StaticBody3D.new()
			body.position = Vector3(int(d.x) + 0.5, 0.0, int(d.y) + 0.5)
			body.rotation.y = ry        # rotates the GLB AND the box collider
			body.collision_layer = LAYER_WORLD
			body.collision_mask = 0
			inst.position = Vector3(0.0, 0.05, 0.0)
			body.add_child(inst)
			var shape := BoxShape3D.new()
			shape.size = box
			var col := CollisionShape3D.new()
			col.shape = shape
			col.position = Vector3(0.0, box.y * 0.5, 0.0)
			body.add_child(col)
			body.add_child(_make_blob_shadow(maxf(box.x, box.z) * 0.7))   # grounds the prop
			add_child(body)
			if breakable:
				var bsize: Vector3 = box
				(body as Node).call("setup", 1, DECOR_BREAKABLE[kind],
					maxf(bsize.x, bsize.z) * 0.55, bsize.y)


func _build_rootroad_id_prop(d: Dictionary) -> void:
	var model_path := String(ROOTROAD_ID_MODEL.get(String(d.get("kind", "")), ""))
	if model_path == "" or not ResourceLoader.exists(model_path):
		return
	var packed: PackedScene = load(model_path)
	if packed == null:
		return
	var prop: Node3D = packed.instantiate()
	prop.name = "Rootroad_%s" % String(d.get("kind", "prop"))
	prop.position = Vector3(float(d.get("x", 0)) + 0.5, 0.02, float(d.get("y", 0)) + 0.5)
	_unmetal(prop)
	_outline_only(prop)
	add_child(prop)

# Spec 55 — layout data guarantees the clues; the loader turns each one into a
# restrained optional Interactable without adding it to the objective tracker.
func _build_story_clues(layout: Dictionary) -> void:
	for clue in layout.get("story_clues", []):
		var mark: Node3D = SecondHandClueScript.new()
		mark.setup(String(clue.get("id", "")), String(clue.get("presentation", "")))
		mark.position = Vector3(float(clue.get("x", 0)) + 0.5, 0.02,
			float(clue.get("y", 0)) + 0.5)
		add_child(mark)


# Slice D1 — campaign clues use their own Interactable and group. Do not reuse
# the Second Hand object or its optional observation state: this record is the
# deterministic chapter-progress promise carried by an eligible Green Hollow.
func _build_campaign_clues(layout: Dictionary) -> void:
	for clue_v in layout.get("campaign_clues", []):
		if not clue_v is Dictionary:
			continue
		var clue: Dictionary = clue_v
		var mark: Node3D = CampaignClueScript.new()
		mark.setup(clue)
		mark.position = Vector3(float(clue.get("x", 0)) + 0.5, 0.02,
			float(clue.get("y", 0)) + 0.5)
		add_child(mark)


func _is_pale_veins_layout(layout: Dictionary) -> bool:
	return String(layout.get("scope", "")) in ["pale_veins", "rootroads", "rootroad"] \
		or String(layout.get("template_id", "")) == "pale_veins"


func _build_guaranteed_oath_rubbing(layout: Dictionary) -> void:
	# Prefer the deep destination, then the entry in minimal test layouts.
	var anchor: Dictionary = layout.get("exit", layout.get("entry", {}))
	var rubbing := OathRubbingScript.new()
	var chart_id := "oath_rubbing_1"
	var game := get_tree().root.get_node_or_null("Game")
	if game != null and game.get("active_chart") is Dictionary:
		chart_id = String((game.get("active_chart") as Dictionary).get("oath_rubbing_id", chart_id))
	rubbing.setup(chart_id)
	rubbing.name = "GuaranteedOathRubbing"
	rubbing.position = Vector3(float(anchor.get("x", 0)) + 0.5, 0.02,
		float(anchor.get("y", 0)) + 0.5)
	add_child(rubbing)


func _has_stonewake_affix() -> bool:
	var game := get_tree().root.get_node_or_null("Game")
	return game != null and ((game.has_method("affix_good") and bool(game.affix_good("stonewake"))) \
		or (game.has_method("affix_bad") and bool(game.affix_bad("stonewake"))))


func _build_stonewake(layout: Dictionary) -> void:
	if _stonewake != null:
		return
	var wake := StonewakeScript.new()
	var game := get_tree().root.get_node_or_null("Game")
	var rebuke := game != null and game.has_method("affix_bad") and bool(game.affix_bad("stonewake"))
	wake.setup(rebuke)
	var anchor: Dictionary = layout.get("exit", layout.get("entry", {}))
	wake.name = "StonesRebuke" if rebuke else "Stonewake"
	wake.position = Vector3(float(anchor.get("x", 0)) + 0.5, 0.02,
		float(anchor.get("y", 0)) + 0.5)
	add_child(wake)
	_stonewake = wake
	# Start only after the world is present so the >=1s marked ring is visible.
	wake.call_deferred("begin_cycle")

# Spec 29 — instantiate the typed-room interactable for a focal-tagged decor
# entry. The interactable handles its own visual (it carries the GLB inside)
# + detection (Area3D on INTERACT_LAYER for the player's scanner).
func _build_interactable(role: String, d: Dictionary,
		depths: Array, dungeon_seed: int) -> void:
	var x: int = int(d.x)
	var y: int = int(d.y)
	var rid: int = int(d.get("room_id", -1))
	var depth: int = 0
	if rid >= 0 and rid < depths.size():
		depth = int(depths[rid])
	var pos := Vector3(x + 0.5, 0.0, y + 0.5)
	match role:
		"treasure":
			var c := ChestScene.instantiate()
			c.depth = depth
			add_child(c)
			c.global_position = pos
		"shrine":
			var s := ShrineScene.instantiate()
			# (dungeon_seed XOR room_id) — same dungeon seed → same 3 buffs
			# at this shrine, but a different shrine in the same dungeon
			# offers a different mix.
			s.seed_value = dungeon_seed ^ ((rid + 1) * 2654435761)
			add_child(s)
			s.global_position = pos
		"rest":
			var h := HearthScene.instantiate()
			h.room_id = rid
			add_child(h)
			h.global_position = pos

# A warm point light at a torch, ~1.6 m up the wall — pools of light in
# darkness (spec 16).
const FlickerLightScript = preload("res://scripts/flicker_light.gd")

func _add_torch_light(wx: float, wz: float) -> void:
	# Tighter falloff + shorter range → a discrete warm POOL (was a broad even
	# wash); the FlickerLight breathes the energy for living firelight.
	var lamp: OmniLight3D = FlickerLightScript.new()
	lamp.position = Vector3(wx, 1.6, wz)
	lamp.light_color = Color(1.0, 0.74, 0.42)   # warm flame
	lamp.light_energy = 2.2
	lamp.omni_range = 6.0
	lamp.omni_attenuation = 2.0
	lamp.light_volumetric_fog_energy = 1.6      # the torch glows a warm pool in the fog
	add_child(lamp)
	# A small emissive flame core that crosses the glow HDR threshold (>1.0) so
	# the fire itself blooms — selective glow makes only the lit things bloom.
	var core := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.11
	sm.height = 0.22
	core.mesh = sm
	var cmat := StandardMaterial3D.new()
	cmat.albedo_color = Color(1.0, 0.82, 0.45)
	cmat.emission_enabled = true
	cmat.emission = Color(1.0, 0.72, 0.34)
	cmat.emission_energy_multiplier = 2.6
	cmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	core.material_override = cmat
	core.position = Vector3(wx, 1.62, wz)
	add_child(core)

# Prefer the Meshy-rigged variant (<name>_rigged.glb) when it exists,
# else the static _v1 GLB (spec 11 fallback — e.g. the rat never rigged).
func _resolve_model(base_path: String) -> String:
	var rigged := base_path.trim_suffix(".glb") + "_rigged.glb"
	if ResourceLoader.exists(rigged):
		return rigged
	return base_path

# ---- boss (spec 17) ----
var _gates: Array = []                  # arena-seal wall blocks
var _boss_body: CharacterBody3D = null  # Wyrd — exit waystone waits on her death
var _hearth_encounter: Node3D = null
var _knot_eater_encounter: Node3D = null
var _hearth_exit_position := Vector3.ZERO
var _hearth_exit_ready := false
var _hearth_exit_spawned := false

# Boss-approach vista — the boss den is the run's lit CLIMAX. A warm-amber
# beacon pokes above the arena gates so the player sees the den glow through the
# fog on approach (warm boss vs the cool exit beacon), and a strong warm light
# charges the arena brighter than the dim run-up corridors (interest-curve
# release). Only boss dens get it.
func _build_boss_vista(cx: int, cy: int) -> void:
	var pos := Vector3(cx + 0.5, 0.0, cy + 0.5)
	var amber := Color(1.0, 0.66, 0.32)
	var lamp := OmniLight3D.new()
	lamp.position = pos + Vector3(0.0, 2.0, 0.0)
	lamp.light_color = amber
	lamp.light_energy = 2.6
	lamp.omni_range = 14.0
	lamp.omni_attenuation = 1.3
	lamp.light_volumetric_fog_energy = 2.0
	add_child(lamp)
	var beam := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.10
	cyl.bottom_radius = 0.42
	cyl.height = 6.0
	beam.mesh = cyl
	beam.position = pos + Vector3(0.0, 3.2, 0.0)
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = Color(amber.r, amber.g, amber.b, 0.6)
	bmat.emission_enabled = true
	bmat.emission = amber
	bmat.emission_energy_multiplier = 1.8
	bmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bmat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD   # glow, never darken
	bmat.cull_mode = BaseMaterial3D.CULL_DISABLED
	beam.material_override = bmat
	add_child(beam)

func _build_boss(boss_room, grid: Array, boss_kind: String = "hedgemother",
		campaign_contract: Dictionary = {}, encounter_contract: Dictionary = {},
		handoff_contract: Dictionary = {}) -> void:
	if boss_room == null:
		return
	var def: Dictionary = BOSS_KINDS.get(boss_kind, BOSS_KINDS["hedgemother"])
	var cx: int = int(boss_room.x) + int(int(boss_room.w) / 2.0)
	var cy: int = int(boss_room.y) + int(int(boss_room.h) / 2.0)
	_boss_arena_center = Vector3(cx + 0.5, 0.0, cy + 0.5)
	_boss_arena_ready = true
	_build_boss_vista(cx, cy)
	var model := _resolve_model(String(def.model))
	if not ResourceLoader.exists(model) and boss_kind == "hearth_giant":
		model = "res://models/boss_barrow_jarl_v1.glb"
	var packed: PackedScene = load(model)
	if packed == null:
		return
	var inst: Node3D = packed.instantiate()
	if def.has("scale"):
		inst.scale = Vector3.ONE * float(def.scale)   # calibrated (spec 16)
	else:
		GlbFit.normalize_height(inst, float(def.fit_h))
	_unmetal(inst)
	# Slice A — keep the boss's own GLB textures but chain on the ink rim so she
	# matches the enemy silhouette language (no flat tint over her painted skin).
	_outline_only(inst)
	var boss_hp: int = int(def.hp)
	var boss_script = HearthGiantScript if boss_kind == "hearth_giant" else KnotEaterScript if boss_kind == "knot_eater" else \
		BarrowJarlScript if boss_kind == "barrow_jarl" else BossScript
	var boss := _spawn_character(inst, cx, cy, float(def.radius),
		float(def.height), boss_hp, boss_script)
	# Spec 27b — boss drops the boss loot pile.
	boss.role = "boss"
	boss.depth = 9
	boss.damage = int(def.get("damage", 8))
	boss.kind = boss_kind              # B4a — selects the moveset (boar charges)
	_boss_body = boss                  # Wyrd — exit waystone keys off her death
	var is_campaign_boss := bool(campaign_contract.get("guaranteed", false)) \
		and String(campaign_contract.get("boss_kind", "")) == boss_kind
	var is_handoff_boss := bool(handoff_contract.get("guaranteed", false)) \
		and bool(handoff_contract.get("campaign_inert", false)) \
		and String(handoff_contract.get("boss_kind", "")) == boss_kind
	var is_reprise_boss := bool(encounter_contract.get("suppress_chain_trophy", false)) \
		and String(encounter_contract.get("boss_kind", "")) == boss_kind \
		and String(encounter_contract.get("reward_family_id", "")) == "first_knot_heirlooms"
	# The chart chain — her death yields the trophy that inks the next den.
	var trophy := String(def.get("trophy", ""))
	if trophy != "" and not is_campaign_boss and not is_reprise_boss \
			and not is_handoff_boss:
		boss.died.connect(_on_boss_trophy_died.bind(trophy))
	# Slice D1 — only a Chart carrying the explicit authored contract can settle
	# the campaign on boss death. Legacy Hedgemother-den Affixes retain their
	# ordinary trophy loop and remain campaign-inert, including their bad twins.
	if is_campaign_boss and boss_kind not in ["hearth_giant", "knot_eater"]:
		# Bind stable copies into a named instance callback. The former inline
		# lambda captured `_build_boss` locals by reference; a later test/runtime
		# death signal could call it after those locals had been released.
		boss.died.connect(_on_campaign_boss_died.bind(boss_kind,
			campaign_contract.duplicate(true)))
	# The safe Summit handoff consumes Alpha Fang through its own persistent
	# tombstone without minting Queen campaign truth. Existing materialized
	# Summit Charts carry no contract and retain their legacy behavior.
	if is_handoff_boss:
		boss.died.connect(_on_handoff_boss_died.bind(handoff_contract.duplicate(true)))
	# D2 replay reward is separate from both the D1 settlement and normal boss
	# chain trophy. Combatant still supplies the ordinary boss pile first.
	if is_reprise_boss:
		boss.died.connect(_on_reprise_boss_died.bind(encounter_contract.duplicate(true), boss))
	# Every boss breathes/sways at idle and bobs when moving (Meshy can't rig
	# these). Quadrupeds pass their lumbering bob; humanoid bosses get the
	# gentle default so they're never frozen.
	var qa = CreatureAnimScript.new()
	if def.has("bob"):
		qa.setup(inst, float(def.bob[0]), float(def.bob[1]))
	else:
		qa.setup(inst)
	boss._proc_anim = qa
	AnimDriverScript.play_idle(inst)
	if boss_kind == "barrow_jarl":
		_build_barrow_jarl_reliefs(boss as BarrowJarl, cx, cy)
	elif boss_kind == "hearth_giant":
		_build_hearth_giant_encounter(boss as HearthGiant, cx, cy)
	elif boss_kind == "knot_eater":
		_build_knot_eater_encounter(boss, cx, cy)

	# Arena seal — gate blocks at the boss-room openings, raised on aggro.
	_gates = _make_arena_gates(boss_room, grid)
	boss.aggroed.connect(_raise_gates)
	boss.died.connect(_drop_gates)
	# C10 — the Queen calls a thorn-guard at phase 3.
	boss.summon_wave.connect(_on_boss_summon_wave.bind(cx, cy))

	# Wire the boss bar (spec 17).
	var bossbar := get_node_or_null("BossBar")
	if bossbar != null:
		bossbar.set_boss_name(String(def.get("name", "The Hedgemother")))   # per-kind label
		boss.aggroed.connect(bossbar.show_boss)
		boss.boss_hp_changed.connect(bossbar.set_hp)
		boss.phase_changed.connect(bossbar.set_phase)
		boss.died.connect(bossbar.hide_boss)
		bossbar.prime(boss_hp)

	# Wyrd — dying to her must not seal the run forever (the exit waystone
	# only rises on her death). Offline, any death resets the encounter; in
	# co-op only a full party wipe does (spec 46 Phase B). Deferred wiring —
	# in a session the per-peer bodies spawn after this builder runs.
	_wire_party_reset.call_deferred(boss, bossbar)
	var party_net := get_node_or_null("/root/NetGame")
	if party_net != null and party_net.has_signal("player_body_spawned"):
		var spawn_hook := _wire_spawned_player_for_reset.bind(boss, bossbar)
		if not party_net.player_body_spawned.is_connected(spawn_hook):
			party_net.player_body_spawned.connect(spawn_hook)


func _on_campaign_boss_died(expected_boss_kind: String,
		expected_contract: Dictionary) -> void:
	var game := get_tree().root.get_node_or_null("Game")
	if game == null or not game.has_method("resolve_campaign_boss_death"):
		return
	var active: Dictionary = game.get("active_chart")
	var active_contract = active.get("campaign_contract", {})
	if not active_contract is Dictionary \
			or not bool((active_contract as Dictionary).get("guaranteed", false)) \
			or String((active_contract as Dictionary).get("boss_kind", "")) != expected_boss_kind \
			or (active_contract as Dictionary) != expected_contract:
		return
	var settlement: Dictionary = game.call("resolve_campaign_boss_death", active)
	# This World owns the arena-local presentation. Consume only the exact
	# authoritative transition returned by Game; never infer a Stair from a
	# Queen-shaped boss, an old Summit flag, or campaign state inspection.
	if bool(settlement.get("changed", false)) \
			and String((active_contract as Dictionary).get("chapter_id", "")) \
				== CampaignData.QUEENS_SUMMIT \
			and (settlement.get("restoration_awards", []) as Array).has("pale_stair"):
		reveal_pale_stair_from_campaign_settlement({
			"canonical_queen": true, "pale_stair": true,
		})


func _on_boss_trophy_died(trophy: String) -> void:
	var game := get_tree().root.get_node_or_null("Game")
	if game == null:
		return
	game.add_material(trophy, 1)
	if game.ledger != null:
		game.ledger.apply(trophy) # ADR 0013 — trophy → permanent stat
	game.notify("Trophy claimed: %s. Slot it at the Inscribing Table." %
		GatherDefs.material_name(trophy))


func _on_boss_summon_wave(count: int, center_x: int, center_y: int) -> void:
	_spawn_queen_summons(center_x, center_y, count)


func _on_handoff_boss_died(expected_contract: Dictionary) -> void:
	var game := get_tree().root.get_node_or_null("Game")
	if game == null or not game.has_method("resolve_handoff_boss_death"):
		return
	var active: Dictionary = game.get("active_chart")
	var active_contract = active.get("handoff_contract", {})
	if not active_contract is Dictionary or (active_contract as Dictionary) != expected_contract:
		return
	game.call("resolve_handoff_boss_death", active)


func _on_reprise_boss_died(contract: Dictionary, boss: Node3D) -> void:
	if boss != null and is_instance_valid(boss):
		_spawn_reprise_heirloom(contract, boss.global_position)


# Builds the authored encounter shell around the dedicated Jarl controller.
# Guard/bell state lives entirely in these actors; no campaign settlement is
# attempted until Jarl.died emits after the controller's three reliefs.
func _build_barrow_jarl_reliefs(jarl: BarrowJarl, cx: int, cy: int) -> void:
	if jarl == null:
		return
	var controller: Node3D = BarrowJarlControllerScript.new()
	controller.name = "BarrowJarlReliefController"
	add_child(controller)
	var guards: Array = []
	var bells: Array = []
	var offsets := [Vector3(-3.0, 0.0, -1.8), Vector3(3.0, 0.0, -1.8), Vector3(0.0, 0.0, 3.0)]
	for i in 3:
		var packed: PackedScene = load("res://models/enemy_oathbound_v1.glb")
		if packed == null:
			continue
		var guard_inst: Node3D = packed.instantiate()
		GlbFit.normalize_height(guard_inst, 1.8)
		_unmetal(guard_inst)
		_outline_only(guard_inst)
		var guard: CharacterBody3D = _spawn_character(guard_inst,
			cx + int(offsets[i].x), cy + int(offsets[i].z), 0.55, 1.8, 44, OathboundGuardScript)
		guard.name = "Oathbound%d" % (i + 1)
		# Spawned guards are real Combatants, so hiding alone is unsafe: the
		# dormant contract also suspends physics, AI, hurtbox, and body collision.
		if guard.has_method("set_vow_dormant"):
			guard.call("set_vow_dormant")
		guards.append(guard)
		var bell: Node3D = OathBellScript.new()
		bell.name = "OathBell%d" % (i + 1)
		# Configure before entering the tree so _ready_interactable() loads the
		# matching 1/2/3 bellpost, not the default phase-one GLB.
		bell.set_controller(controller, i + 1)
		bell.position = Vector3(cx + 0.5, 0.0, cy + 0.5) + offsets[i] * 1.22
		add_child(bell)
		bells.append(bell)
	controller.configure(jarl, guards, bells)
	jarl.set_relief_controller(controller)


func _build_hearth_giant_encounter(giant: HearthGiant, cx: int, cy: int) -> void:
	if giant == null:
		return
	var controller: Node3D = HearthGiantEncounterScript.new()
	controller.name = "HearthGiantEncounter"
	add_child(controller)
	var chains: Array = []
	var offsets := [Vector3(-3.1, 0.0, -1.8), Vector3(3.1, 0.0, -1.8),
		Vector3(0.0, 0.0, 3.2)]
	for i in HearthGiantEncounterScript.CHAIN_ORDER.size():
		var chain: Node3D = HearthChainScript.new()
		chain.name = "HearthChain%d" % (i + 1)
		chain.configure(String(HearthGiantEncounterScript.CHAIN_ORDER[i]))
		chain.position = Vector3(cx + 0.5, 0.0, cy + 0.5) + offsets[i]
		add_child(chain)
		chains.append(chain)
	controller.configure(giant, chains)
	_hearth_encounter = controller
	var game := get_tree().root.get_node_or_null("Game")
	var active: Dictionary = game.get("active_chart") if game != null else {}
	var chart_instance := String(active.get("chart_instance_id", ""))
	var attempt := String(active.get("attempt_id", ""))
	var net := get_node_or_null("/root/NetGame")
	if net != null and bool(net.active) and not bool(net.is_host()):
		controller.begin_guest_world_ready(chart_instance, attempt)
	else:
		controller.begin_attempt(chart_instance, attempt)
	controller.connect("giant_banked", _on_hearth_giant_banked.bind(controller, giant))
	controller.connect("settled_snapshot_applied", _present_hearth_giant_settlement)
	controller.call_deferred("report_world_ready", chart_instance, attempt)


func _build_knot_eater_encounter(eater: Node3D, cx: int, cy: int) -> void:
	if eater == null:
		return
	var controller: Node3D = KnotEaterEncounterScript.new()
	controller.name = "KnotEaterEncounter"
	add_child(controller)
	_knot_eater_encounter = controller
	var anchors: Array = []
	var knots: Array = []
	var offsets := [Vector3(-3.2, 0, -1.8), Vector3(3.2, 0, -1.8), Vector3(0, 0, 3.1)]
	for i in 3:
		var anchor: Node3D = KnotEaterAnchorScript.new()
		anchor.name = "KnotEaterAnchor%d" % (i + 1)
		anchor.configure("anchor_%d" % (i + 1), controller)
		anchor.position = Vector3(cx + 0.5, 0, cy + 0.5) + offsets[i]
		add_child(anchor)
		anchors.append(anchor)
		var knot: Node3D = KnotEaterKnotScript.new()
		knot.name = "KnotEaterKnot%d" % (i + 1)
		knot.configure("knot_%d" % (i + 1), controller)
		knot.position = Vector3(cx + 0.5, 0, cy + 0.5) + offsets[i] * 0.58
		add_child(knot)
		knots.append(knot)
	controller.configure(eater, anchors, knots)
	var game := get_node_or_null("/root/Game")
	var active: Dictionary = game.get("active_chart") if game != null else {}
	var chart_id := String(active.get("chart_instance_id", ""))
	var attempt := String(active.get("attempt_id", ""))
	if controller.begin_attempt(chart_id, attempt):
		controller.call_deferred("report_world_ready", chart_id, attempt)
	controller.connect("settled", _present_knot_eater_settlement.bind(controller))


func _present_knot_eater_settlement(_controller: Node) -> void:
	_drop_gates()
	var bossbar := get_node_or_null("BossBar")
	if bossbar != null:
		bossbar.hide_boss()
	# The nonlethal boss never emits `died`, so the ordinary boss-waystone hook
	# cannot authorize the exit. Settlement is the sole terminal signal.
	if get_node_or_null("KnotEaterExitWaystone") == null and _boss_body != null:
		var waystone: Node3D = ExitWaystoneScript.new()
		waystone.name = "KnotEaterExitWaystone"
		waystone.position = _boss_body.global_position + Vector3(0.0, 0.0, 2.2)
		add_child(waystone)


func _on_hearth_giant_banked(controller: Node, giant: Node) -> void:
	if controller != _hearth_encounter or giant != _boss_body:
		return
	_present_hearth_giant_settlement()
	var game := get_tree().root.get_node_or_null("Game")
	if game == null or not game.has_method("resolve_campaign_boss_death"):
		return
	var active: Dictionary = game.get("active_chart")
	var contract = active.get("campaign_contract", {})
	if not contract is Dictionary \
			or String((contract as Dictionary).get("chapter_id", "")) \
				!= CampaignData.FIRE_IN_THE_BOUGH \
			or String((contract as Dictionary).get("boss_kind", "")) != "hearth_giant":
		return
	game.call("resolve_campaign_boss_death", active)


# This is intentionally presentation-only: the host's `giant_banked` signal
# and a guest's accepted settled snapshot take the same visual route, but only
# the host callback below invokes Game's settlement transaction. A late join
# can therefore see the dropped gates and usable exit without rerunning escrow.
func _present_hearth_giant_settlement() -> void:
	_drop_gates()
	var bossbar := get_node_or_null("BossBar")
	if bossbar != null:
		bossbar.hide_boss()
	if not _hearth_exit_ready or _hearth_exit_spawned:
		return
	var ws: Node3D = ExitWaystoneScript.new()
	ws.position = _hearth_exit_position
	add_child(ws)
	_hearth_exit_spawned = true


# Queen's Summit presentation adapter.  Game is the only caller allowed to
# hand this loader the explicit post-settlement token, immediately after a
# successful *canonical* Queen resolution.  This intentionally does not accept
# generic `summit_cleared`, a loose Alpha Fang, a legacy Chart, or any handoff
# phase: none of those are campaign truth.
#
# Expected token: {"canonical_queen": true, "pale_stair": true}.  Keeping it
# small and explicit prevents a future presentation caller from inferring the
# Root Saga out of an old save shape.  It is safe to call repeatedly.
func reveal_pale_stair_from_campaign_settlement(token: Dictionary) -> bool:
	if not bool(token.get("canonical_queen", false)) \
			or not bool(token.get("pale_stair", false)):
		return false
	if _pale_stair != null and is_instance_valid(_pale_stair):
		return true
	# World origin is a valid generated arena centre.  Readiness must be explicit;
	# using Vector3.ZERO as a sentinel made a canonical origin-centred Queen
	# settle correctly while silently withholding her Pale Stair.
	if not _boss_arena_ready and _boss_arena_center == Vector3.ZERO:
		# The landmark belongs to the authored Queen arena only.  A direct World
		# boot and a boss-free Crownward Ascent therefore cannot manufacture it.
		return false
	var stair: Node3D = PaleStairScript.new()
	stair.name = "PaleStair"
	# Sit just beyond the arena's centre; it faces down the visible root-road
	# but does not block the exit or constitute a collision/transition gate.
	stair.position = _boss_arena_center + Vector3(0.0, 0.02, -2.05)
	stair.rotation.y = PI
	stair.set_campaign_settlement_view(token)
	add_child(stair)
	_pale_stair = stair
	return true


# Narrow read-only test/integration seam.  Root's Queen death callback should
# call `reveal_pale_stair_from_campaign_settlement` with the explicit token;
# callers can use this accessor to prove repeated settlement cannot duplicate
# the prop without looking at loader-private fields.
func pale_stair_landmark() -> Node3D:
	return _pale_stair if _pale_stair != null and is_instance_valid(_pale_stair) else null

func _spawn_reprise_heirloom(encounter_contract: Dictionary, pos: Vector3) -> void:
	var game := get_tree().root.get_node_or_null("Game")
	if game == null or not game.has_method("claim_first_knot_reprise_reward"):
		return
	# Guest bosses are puppets. Their local death replay must never mint a
	# second reward; the host below broadcasts the one concrete item instead.
	var net := get_node_or_null("/root/NetGame")
	if net != null and bool(net.active) and not bool(net.is_host()):
		return
	var active: Dictionary = game.get("active_chart")
	if active.get("encounter_contract", {}) != encounter_contract:
		return
	var item: Dictionary = game.call("claim_first_knot_reprise_reward", active)
	if item.is_empty():
		return
	if net != null and bool(net.active):
		net.unique_drop_event(item, pos)
	else:
		ItemPickup.spawn_scattered(self, item, pos)

func _wire_party_reset(boss: Node, bossbar: Node) -> void:
	for p in get_tree().get_nodes_in_group("player"):
		_wire_spawned_player_for_reset(p as Node, boss, bossbar)

func _wire_spawned_player_for_reset(player: Node, boss: Node, bossbar: Node) -> void:
	if player == null or not player.has_signal("died"):
		return
	var callback := _party_reset_check.bind(boss, bossbar)
	if not player.died.is_connected(callback):
		player.died.connect(callback)

func _party_reset_check(boss: Node, bossbar: Node) -> void:
	var net := get_node_or_null("/root/NetGame")
	if net != null and bool(net.active):
		if not bool(net.is_host()):
			return
		for p in get_tree().get_nodes_in_group("player"):
			if not bool((p as Node).get("dead")):
				return   # someone still stands — the fight goes on
	_drop_gates()
	if boss == _boss_body and _knot_eater_encounter != null \
			and is_instance_valid(_knot_eater_encounter) \
			and _knot_eater_encounter.has_method("reset_for_retry"):
		_knot_eater_encounter.call("reset_for_retry")
	elif boss == _boss_body and _hearth_encounter != null \
			and is_instance_valid(_hearth_encounter) \
			and _hearth_encounter.has_method("reset_for_retry"):
		_hearth_encounter.call("reset_for_retry")
	elif is_instance_valid(boss) and boss.has_method("reset_fight"):
		boss.reset_fight()
	if bossbar != null and is_instance_valid(bossbar):
		bossbar.hide_boss()

# Gate blocks at every "floor" tile on the boss-room perimeter — the
# openings. Built lowered/inert; raised when the boss aggros.
func _make_arena_gates(boss_room, grid: Array) -> Array:
	var gates: Array = []
	var bx := int(boss_room.x)
	var by := int(boss_room.y)
	var bw := int(boss_room.w)
	var bh := int(boss_room.h)
	var edge: Array = []
	for x in range(bx, bx + bw):
		edge.append(Vector2i(x, by))
		edge.append(Vector2i(x, by + bh - 1))
	for y in range(by, by + bh):
		edge.append(Vector2i(bx, y))
		edge.append(Vector2i(bx + bw - 1, y))
	for t in edge:
		if t.y < 0 or t.y >= grid.size():
			continue
		var row: Array = grid[t.y]
		if t.x < 0 or t.x >= row.size():
			continue
		if String(row[t.x]) != "floor":
			continue
		gates.append(_make_gate(t.x, t.y))
	return gates

func _make_gate(x: int, y: int) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = Vector3(x + 0.5, WALL_HEIGHT * 0.5, y + 0.5)
	body.collision_layer = LAYER_WORLD
	body.collision_mask = 0
	var mesh := BoxMesh.new()
	mesh.size = Vector3(1.0, WALL_HEIGHT, 1.0)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	var gmat := StandardMaterial3D.new()
	gmat.albedo_color = Color(0.22, 0.30, 0.20)   # mossy bramble gate
	mi.material_override = gmat
	body.add_child(mi)
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.0, WALL_HEIGHT, 1.0)
	var col := CollisionShape3D.new()
	col.name = "GateCol"
	col.shape = shape
	col.disabled = true
	body.add_child(col)
	body.visible = false
	add_child(body)
	return body

func _raise_gates() -> void:
	for g in _gates:
		if is_instance_valid(g):
			var body := g as StaticBody3D
			body.visible = true
			var c: Node = body.get_node_or_null("GateCol")
			if c != null:
				(c as CollisionShape3D).disabled = false

func _drop_gates() -> void:
	for g in _gates:
		if is_instance_valid(g):
			var body := g as StaticBody3D
			body.visible = false
			var c: Node = body.get_node_or_null("GateCol")
			if c != null:
				(c as CollisionShape3D).disabled = true

# ---- enemies ----
# Spec 25 Phase 5 — enemies spawn per room, by role + BFS depth: the crypt
# escalates from a calm entrance toward a dense run-up to the boss.
func _build_enemies(layout: Dictionary) -> int:
	var grid: Array = layout.grid
	var rooms: Array = layout.get("rooms", [])
	var depths: Array = layout.get("room_depths", [])
	var entry = layout.entry
	var exit = layout.exit
	var elite_manifest: Dictionary = layout.get("elite_manifest", {}) as Dictionary \
		if layout.get("elite_manifest", {}) is Dictionary else {}
	var manifest_pending := bool(elite_manifest.get("eligible", false)) \
		and String(elite_manifest.get("slot_id", "")) == "ashen_first_eligible"
	_elite_manifest_consumed = false
	_elite_manifest_body = null
	var is_snug_lesson := String(layout.get("scope", "")) == "snug"
	var lesson_room_idx := -1
	var lesson_depth := 999999
	var pressure_room_idx := -1
	var pressure_depth := -1
	if is_snug_lesson:
		for candidate_i in rooms.size():
			var candidate: Dictionary = rooms[candidate_i]
			if String(candidate.get("role", "")) != "combat":
				continue
			var candidate_depth: int = depths[candidate_i] \
				if candidate_i < depths.size() else 0
			if candidate_depth < lesson_depth:
				lesson_depth = candidate_depth
				lesson_room_idx = candidate_i
		# A valid small Snug can occasionally contain no room explicitly tagged
		# `combat`. The opening still promises one normalized teaching rat, so use
		# the shallowest ordinary room rather than letting layout grammar erase the
		# lesson for that seed.
		if lesson_room_idx < 0:
			for candidate_i in rooms.size():
				var candidate: Dictionary = rooms[candidate_i]
				if String(candidate.get("role", "")) in ["entrance", "boss"]:
					continue
				var candidate_depth: int = depths[candidate_i] \
					if candidate_i < depths.size() else 0
				if candidate_depth < lesson_depth:
					lesson_depth = candidate_depth
					lesson_room_idx = candidate_i
	if _guaranteed_pressure_elite:
		for candidate_i in rooms.size():
			var candidate: Dictionary = rooms[candidate_i]
			if candidate_i == lesson_room_idx or String(candidate.get("role", "")) != "combat":
				continue
			var candidate_depth: int = depths[candidate_i] if candidate_i < depths.size() else 0
			if candidate_depth > pressure_depth:
				pressure_depth = candidate_depth
				pressure_room_idx = candidate_i
		# Compact four-room seeds may spend their only combat tag on the lesson.
		# The authored pressure promise outranks decorative room grammar.
		if pressure_room_idx < 0:
			for candidate_i in rooms.size():
				var candidate: Dictionary = rooms[candidate_i]
				if candidate_i == lesson_room_idx \
						or String(candidate.get("role", "")) in ["entrance", "boss"]:
					continue
				var candidate_depth: int = depths[candidate_i] if candidate_i < depths.size() else 0
				if candidate_depth > pressure_depth:
					pressure_depth = candidate_depth
					pressure_room_idx = candidate_i
	# Wyrd — the chart's scope picks the spawn table (briar mazes crawl with
	# imps; snug cellars get rats). Unknown scopes read as crypt.
	var table: Array = SPAWN_TABLES.get(String(layout.get("scope", "crypt")),
		SPAWN_TABLES["crypt"])
	var ei := 0
	for ri in rooms.size():
		var r: Dictionary = rooms[ri]
		var role: String = r.get("role", "combat")
		# Spec 32 — boss room stays elite-free + enemy-free (the boss is the
		# whole encounter). Entrance never has enemies.
		if role == "entrance" or role == "boss":
			continue
		var depth: int = depths[ri] if ri < depths.size() else 0
		var n := 0
		match role:
			# Spec 32 — combat rooms now scale 4–10 trash per depth (was 2–5).
			"combat":   n = 4 + clampi(depth / 2, 0, 6)
			"treasure": n = 1                              # a guard
			"shrine":   n = _rng.randi_range(0, 1)
			"setpiece": n = 2
		if ri == lesson_room_idx:
			n = 1
		# Wyrd — festival_pace density twins scale every populated room.
		if n > 0 and _density_mult != 1.0:
			n = maxi(1, roundi(n * _density_mult))
		var tiles := _room_floor_tiles(grid, r, entry, exit)
		if tiles.is_empty():
			continue
		# Spec 32 — elite roll. Combat rooms only; ~1 elite per 8 trash.
		# Picks which spawn index gets the elite + which modifier, then
		# adds 2–3 same-kind retinue alongside.
		var elite_idx := -1
		var elite_modifier: String = ""
		var elite_kind: String = ""
		# C11 — deeper dens are eliter: the base chance rises with depth (capped).
		if role == "combat" and ri != lesson_room_idx and manifest_pending:
			elite_idx = 0
			elite_modifier = String(elite_manifest.get("modifier_id", ""))
			elite_kind = String(elite_manifest.get("elite_id", "bough_watcher"))
			manifest_pending = false
		elif ri != lesson_room_idx and (ri == pressure_room_idx \
				or (role == "combat" and _rng.randf() < minf(0.6,
				(float(n) / 8.0 + float(depth) * 0.02) * _elite_chance_mult))):
			elite_idx = _rng.randi_range(0, n - 1)
			elite_modifier = ElitesData.pick_random(_rng)
			elite_kind = _pick_kind(table)
		elif role == "combat":
			# Retained for the ordinary random-elite branch without consuming a
			# kind roll merely to present Pack Reader's frozen manifest.
			elite_kind = _pick_kind(table)
		for k in n:
			var t: Vector2i = tiles[_rng.randi_range(0, tiles.size() - 1)]
			if ri == lesson_room_idx:
				var lesson_enemy = _spawn_enemy(ei, t.x, t.y, role, depth, "rat")
				ei += 1
				if lesson_enemy != null:
					lesson_enemy.add_to_group("snug_lesson_enemy")
					lesson_enemy.damage = 1
					lesson_enemy.move_speed = minf(float(lesson_enemy.move_speed), 1.15)
					lesson_enemy.attack_cooldown = maxf(
						float(lesson_enemy.attack_cooldown), 2.4)
					lesson_enemy.aggro_radius = minf(float(lesson_enemy.aggro_radius), 5.0)
				continue
			if k == elite_idx:
				# Spawn the elite (forced to elite_kind so we can match the
				# retinue against the same enemy kind).
				var elite_body = _spawn_enemy(ei, t.x, t.y, role, depth, elite_kind)
				ei += 1
				if elite_body != null and elite_body.has_method("apply_elite"):
					elite_body.apply_elite(elite_modifier)
					if bool(elite_manifest.get("eligible", false)) \
							and String(elite_modifier) == String(elite_manifest.get("modifier_id", "")) \
							and String(elite_kind) == String(elite_manifest.get("elite_id", "")) \
							and not _elite_manifest_consumed:
						_elite_manifest_consumed = true
						_elite_manifest_body = elite_body
						elite_body.add_to_group("ashen_manifest_elite")
						elite_body.set_meta("elite_manifest_slot",
							String(elite_manifest.get("slot_id", "")))
					# Slice D1 — generic elite essence must not shortcut the
					# authored first chapter. Game owns the campaign decision so
					# this world adapter never reads campaign state or makes a
					# co-op authority decision itself. Keep the seeded roll only
					# after the Hedgemother has been cleared.
					var game := get_tree().root.get_node_or_null("Game")
					var trophy_eligible := game == null \
						or not game.has_method("campaign_elite_trophy_eligible") \
						or bool(game.call("campaign_elite_trophy_eligible", "thorn_essence"))
					# B6 — marked_quarry doubles/halves the trophy odds. Roll
					# from the seeded layout RNG so every co-op peer agrees on
					# which eligible elites carry one.
					var drops_trophy: bool = trophy_eligible \
						and _rng.randf() < 0.25 * _trophy_mult
					if drops_trophy and elite_body.has_method("set_seeded_trophy_sigil"):
						# Trophy Sense reads this already-seeded fact. It never
						# participates in the roll or the death award below.
						elite_body.call("set_seeded_trophy_sigil",
							GatherDefs.material_name("thorn_essence"))
					elite_body.died.connect(_on_elite_trophy_died.bind(drops_trophy))
				# Retinue — 2–3 same-kind trash within ~2.5m of the elite.
				var retinue_count := _rng.randi_range(2, 2 + clampi(depth / 3, 0, 3))  # C11 — bigger packs deeper
				var elite_pos := Vector2(t.x, t.y)
				var near: Array = []
				for cand in tiles:
					if cand == t:
						continue
					if Vector2(cand.x, cand.y).distance_to(elite_pos) <= 2.5:
						near.append(cand)
				if near.is_empty():
					# Fall back: any tiles, sorted by distance to elite (nearest).
					near = tiles.duplicate()
					near.erase(t)
					near.sort_custom(func(a, b):
						return Vector2(a.x, a.y).distance_to(elite_pos) \
							< Vector2(b.x, b.y).distance_to(elite_pos))
				for ri_k in mini(retinue_count, near.size()):
					var rt: Vector2i = near[ri_k]
					_spawn_enemy(ei, rt.x, rt.y, role, depth, elite_kind)
					ei += 1
			else:
				_spawn_enemy(ei, t.x, t.y, role, depth, _pick_kind(table))
				ei += 1
	return ei

func _on_elite_trophy_died(drops_trophy: bool) -> void:
	if not drops_trophy:
		return
	var death_game := get_tree().root.get_node_or_null("Game")
	if death_game == null:
		return
	death_game.add_material("thorn_essence", 1)
	death_game.notify("A thorn essence gleams in the wreckage.")


func elite_manifest_runtime_view() -> Dictionary:
	return {"consumed": _elite_manifest_consumed,
		"body": _elite_manifest_body,
		"slot_id": String(_elite_manifest_body.get_meta("elite_manifest_slot", "")) \
			if _elite_manifest_body != null and is_instance_valid(_elite_manifest_body) else ""}


# Pack Reader is presentation-only. It reads the already-materialized Chart
# descriptor through Game and creates no RNG, spawn, drop, or campaign call.
func _build_pack_reader_plate(layout: Dictionary) -> void:
	var game := get_tree().root.get_node_or_null("Game")
	if game == null or not game.has_method("pack_reader_view"):
		return
	var view = game.call("pack_reader_view")
	if not view is Dictionary or not bool((view as Dictionary).get("available", false)) \
			or not bool((view as Dictionary).get("eligible", false)):
		return
	var entry = layout.get("entry", null)
	if entry == null:
		return
	var modifier_id := String((view as Dictionary).get("modifier_id", ""))
	var elite_id := String((view as Dictionary).get("elite_id", ""))
	var elite_name := elite_id.replace("_", " ").capitalize()
	var modifier_name := String((ElitesData.MODIFIERS.get(
		modifier_id, {}) as Dictionary).get("name", modifier_id.replace("_", " ").capitalize()))
	var plate := Label3D.new()
	plate.name = "PackReaderManifest"
	plate.add_to_group("pack_reader_manifest")
	plate.text = "PACK READER\nFirst sign: %s · %s" % [elite_name, modifier_name]
	plate.position = Vector3(int(entry.x) + 0.5, 2.15, int(entry.y) + 0.5)
	plate.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	plate.no_depth_test = true
	plate.font_size = 22
	plate.pixel_size = 0.004
	plate.modulate = Color(1.0, 0.68, 0.34)
	plate.outline_size = 8
	plate.outline_modulate = Color(0.08, 0.04, 0.03, 0.95)
	var font := WyrdUi.font_header()
	if font != null:
		plate.font = font
	add_child(plate)


func _build_cinderbound_vent(layout: Dictionary) -> void:
	var game := get_tree().root.get_node_or_null("Game")
	if game == null:
		return
	var outcome := "cinderbound" if bool(game.call("affix_good", "cinderbound")) \
		else "cinders_rebuke" if bool(game.call("affix_bad", "cinderbound")) else ""
	if outcome == "":
		return
	var rooms: Array = layout.get("rooms", [])
	var depths: Array = layout.get("room_depths", [])
	var chosen: Dictionary = {}
	var best_depth := -1
	for i in rooms.size():
		var room: Dictionary = rooms[i]
		if String(room.get("role", "")) != "combat":
			continue
		var depth := int(depths[i]) if i < depths.size() else 0
		if depth > best_depth:
			best_depth = depth
			chosen = room
	if chosen.is_empty():
		return
	var pos := Vector3(float(chosen.x) + float(chosen.w) * 0.5, 0.05,
		float(chosen.y) + float(chosen.h) * 0.5)
	var vent: Node3D = CinderboundVentScript.new()
	vent.name = "CinderboundVent"
	add_child(vent)
	var active: Dictionary = game.get("active_chart")
	vent.call("arm_world", outcome, String(active.get("attempt_id",
		active.get("chart_instance_id", "ordinary-ashen"))), pos)
	vent.call_deferred("report_world_ready", String(active.get("attempt_id",
		active.get("chart_instance_id", "ordinary-ashen"))))
	vent.connect("focus_pickup_spawned", func(nonce: int, pickup_pos: Vector3) -> void:
		var pickup: Node3D = CinderFocusPickupScript.new()
		pickup.name = "CinderFocusPickup%d" % nonce
		pickup.configure(vent, nonce)
		pickup.position = pickup_pos
		add_child(pickup))
	vent.connect("focus_pickup_cleared", func(nonce: int) -> void:
		var pickup := get_node_or_null("CinderFocusPickup%d" % nonce)
		if pickup != null:
			pickup.queue_free())

# Weighted pick from a [[kind, weight], ...] spawn table.
func _pick_kind(table: Array) -> String:
	var total := 0
	for row in table:
		total += int(row[1])
	var r := _rng.randi_range(1, maxi(1, total))
	for row in table:
		r -= int(row[1])
		if r <= 0:
			return String(row[0])
	return String(table[0][0])

func _room_floor_tiles(grid: Array, r: Dictionary, entry, exit) -> Array:
	var tiles: Array = []
	for yy in range(int(r.y), int(r.y) + int(r.h)):
		for xx in range(int(r.x), int(r.x) + int(r.w)):
			if yy < 0 or yy >= grid.size() or xx < 0 or xx >= grid[0].size():
				continue
			if String(grid[yy][xx]) != "floor":
				continue
			if xx == int(entry.x) and yy == int(entry.y):
				continue
			if xx == int(exit.x) and yy == int(exit.y):
				continue
			tiles.append(Vector2i(xx, yy))
	return tiles

# C10 — the Queen's phase-3 thorn-guard: a handful of skeleton adds around her.
# Host/offline only — dynamically-spawned adds don't ride the seed-build, so
# co-op guests don't see them yet (noted followup); no desync, just host-side.
func _spawn_queen_summons(cx: int, cy: int, count: int) -> void:
	var netb := get_node_or_null("/root/NetGame")
	if netb != null and bool(netb.active) and not bool(netb.is_host()):
		return
	var offsets := [Vector2i(-2, 1), Vector2i(2, 1), Vector2i(0, -2), Vector2i(-2, -1)]
	for i in mini(count, offsets.size()):
		var o: Vector2i = offsets[i]
		_spawn_enemy(900 + i, cx + o.x, cy + o.y, "combat", 9, "skeleton")

func _spawn_enemy(ei: int, tx: int, ty: int, role: String = "combat",
		depth: int = 0, forced_kind: String = "") -> CharacterBody3D:
	# Spec 32 — `forced_kind` lets the elite's retinue use the SAME kind as
	# the elite leader (Brambled skeleton → skeleton retinue).
	var kind := forced_kind if forced_kind != "" else "skeleton"
	var def: Dictionary = ENEMY_KINDS.get(kind, ENEMY_KINDS["skeleton"])
	var model: String = _resolve_model(String(def.model))
	var packed: PackedScene = load(model)
	if packed == null:
		return null
	var inst: Node3D = packed.instantiate()
	# Wyrd — tyrannical twins: good fattens every enemy ×1.5; the bad twin
	# (Erratic) rolls each enemy its own vigor — one factor drives BOTH the
	# visual scale and the HP so the variance is readable at a glance.
	var jitter := _rng.randf_range(0.7, 1.4) if _hp_jitter else 1.0
	if def.has("scale"):
		inst.scale = Vector3.ONE * float(def.scale) * jitter
	else:
		GlbFit.normalize_height(inst, float(def.fit_h) * jitter)
	_unmetal(inst)
	# Slice A — paint every kind with its archetype hue + ink outline so each
	# reads instantly (the raw GLBs are materialless grey otherwise). The elite
	# golden tint (combatant.gd) overrides on top of this — intended.
	if def.has("tint"):
		_tint(inst, def.tint, bool(def.get("ethereal", false)))
	var hp := maxi(4, roundi(int(def.hp) * _hp_mult * jitter))
	var body := _spawn_character(inst, tx, ty, 0.4, 1.4, hp)
	# B3 — per-kind feel: how hard it hits, how fast it closes, how often.
	body.damage = int(round(float(def.get("damage", 5)) * _dmg_mult))
	body.move_speed = float(def.get("speed", 1.8)) * _speed_mult
	body.attack_cooldown = float(def.get("atk_cd", 1.5)) / _atk_speed_mult
	body.aggro_radius = body.AGGRO_RADIUS * _aggro_mult
	# Phase 3 — ranged casters (the ghost lobs slow spectral orbs).
	body.is_ranged = bool(def.get("ranged", false))
	body.is_support = bool(def.get("support", false))   # warden heals its pack
	body.is_bruiser = bool(def.get("bruiser", false))   # barrow brute — AoE ring
	body.proj_speed = float(def.get("proj_speed", 9.0))
	body.proj_damage = int(def.get("proj_damage", body.damage))
	# B6 — bursting corpses.
	body.burst_on_death = _burst_on_death
	body.burst_hits_player = _burst_hits_player
	# Spec 27b — drop context (room role + BFS depth) drives the loot roll.
	body.role = role
	body.depth = depth
	# Unrigged critters scurry via the procedural hop-bob (spec 21 pattern).
	# Every enemy gets procedural life — breathing/sway at idle, a hop-bob when
	# moving — so the un-rigged cast (skeleton/ghost/hedge_sprite/Hedgemother)
	# no longer slides frozen in bind pose. Scurriers pass their own bob.
	var ra = CreatureAnimScript.new()
	if def.has("bob"):
		ra.setup(inst, float(def.bob[0]), float(def.bob[1]))
	else:
		ra.setup(inst)
	body._proc_anim = ra
	AnimDriverScript.play_idle(inst)
	return body

# Slice A — paint a kind with its archetype hue AND attach the ink outline.
# We build ONE shared painted material per call and override every mesh with
# it; each skinned mesh receives its own renderer-safe overlay.
# `ethereal` makes ghosts read as spirits: faint cool emission + light alpha.
func _tint(root: Node, color: Color, ethereal: bool = false) -> void:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.85
	m.metallic = 0.0
	if ethereal:
		# Spirit cast — glows faintly and you can half-see through it. Kept
		# below the glow_hdr_threshold (1.0) so it shimmers without blooming out.
		m.emission_enabled = true
		m.emission = Color(0.40, 0.55, 0.78)
		m.emission_energy_multiplier = 0.45
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.albedo_color = Color(color.r, color.g, color.b, 0.72)
	for vi in _all_visual_instances(root):
		if vi is MeshInstance3D:
			var mi := vi as MeshInstance3D
			mi.material_override = m
			mi.material_overlay = _make_outline_pass()

# Slice A — the inverted-hull outline shell as a StandardMaterial3D, returned
# fresh so callers can attach it as `next_pass` on a material they own. Front
# faces are culled and the hull is grown along normals, so what remains is a
# dark rim hugging the silhouette. UNSHADED keeps the ink flat at any light.
func _make_outline_pass() -> StandardMaterial3D:
	var o := StandardMaterial3D.new()
	o.grow = true
	o.grow_amount = OUTLINE_GROW
	o.cull_mode = BaseMaterial3D.CULL_FRONT
	o.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	o.albedo_color = OUTLINE_INK
	return o

# Slice A — give the boss the same ink rim WITHOUT flattening its own GLB
# textures. A GeometryInstance overlay keeps the imported surface materials
# intact and remains valid when multiple instances share the same mesh.
func _outline_only(root: Node) -> void:
	for vi in _all_visual_instances(root):
		if vi is MeshInstance3D:
			(vi as MeshInstance3D).material_overlay = _make_outline_pass()

# Wrap a character GLB in a Combatant (CharacterBody3D, spec 15) — a moving
# body on the ENEMIES layer + HP + hurtbox + chase/attack AI. Group "enemy".
# `char_script` lets the boss spawn as a Boss (spec 17). Returns the body.
func _spawn_character(inst: Node3D, tx: int, ty: int, radius: float, height: float, hp: int, char_script := CombatantScript) -> CharacterBody3D:
	var body: CharacterBody3D = char_script.new()
	# Phase B — deterministic names: builds are seed-identical per peer, so
	# "NetFoe<N>" is the same body everywhere; the host's state snapshots
	# address puppets by this name.
	_net_foe_idx += 1
	body.name = "NetFoe%d" % _net_foe_idx
	var netb := get_node_or_null("/root/NetGame")
	if netb != null and bool(netb.active) and not multiplayer.is_server():
		body.set("net_puppet", true)
	body.position = Vector3(tx + 0.5, 0.0, ty + 0.5)
	body.collision_layer = LAYER_ENEMIES
	# Collide with world (walls/floor) + the player; enemy↔enemy passes through.
	body.collision_mask = 1 | 2
	body.add_to_group("enemy")
	body.add_child(inst)
	# Blocking capsule (player can't walk through the body).
	var shape := CapsuleShape3D.new()
	shape.radius = radius
	shape.height = height
	var col := CollisionShape3D.new()
	col.shape = shape
	col.position = Vector3(0.0, height * 0.5, 0.0)
	body.add_child(col)
	body.add_child(_make_blob_shadow(radius * 1.6))   # grounds the foe
	add_child(body)
	# Combatant init — caches meshes for the flash, builds the hurtbox.
	body.cache_meshes()
	body.setup(hp, radius, height)
	return body

# ---- Wyrd: the far waystone (the run's exit) ----
# No boss → it stands ready at the exit tile from the start, with a reward
# chest beside it (the chest replaces the boss as the deep room's payoff).
# With a boss, the waystone rises only when she falls — the boss loot pile
# is the reward and the arena seal owns the room until then.
func _build_exit_waystone(layout: Dictionary) -> void:
	var exit = layout.get("exit", null)
	if exit == null:
		return
	var pos := Vector3(int(exit.x) + 0.5, 0.0, int(exit.y) + 0.5)
	if String(layout.get("bossKind", "")) != "" and _boss_body != null:
		if String(layout.get("bossKind", "")) == "hearth_giant" \
				and _hearth_encounter != null:
			_hearth_exit_position = pos
			_hearth_exit_ready = true
			_hearth_exit_spawned = false
			_hearth_encounter.connect("giant_banked", _present_hearth_giant_settlement)
		else:
			# A bound callback retains a stable value copy of the exit position.
			# The old lambda captured `_build_exit_waystone`'s local `pos` by
			# reference and faulted when a later boss-death signal arrived.
			_boss_body.died.connect(_on_boss_exit_spawned.bind(pos))
	else:
		var ws: Node3D = ExitWaystoneScript.new()
		ws.position = pos
		add_child(ws)
		_build_exit_chest(layout, exit)
	# Spec 45-gaps — the way you came in always works: an abandon stone at
	# the entry pays nothing but ends the run. Without it an inked boss
	# chart soft-locked anyone who couldn't fell the boss.
	var entry = layout.get("entry", null)
	if entry != null:
		var home: Node3D = ExitWaystoneScript.new()
		home.abandoning = true
		home.position = Vector3(int(entry.x) + 0.5 + 1.6, 0.0,
			int(entry.y) + 0.5 + 1.6)
		add_child(home)


func _on_boss_exit_spawned(exit_position: Vector3) -> void:
	var ws: Node3D = ExitWaystoneScript.new()
	ws.position = exit_position
	add_child(ws)

# A depth-scaled reward chest on a floor tile beside the exit waystone.
func _build_exit_chest(layout: Dictionary, exit) -> void:
	var grid: Array = layout.grid
	var depth := 0
	for d in layout.get("room_depths", []):
		depth = maxi(depth, int(d))
	for off in [Vector2i(2, 0), Vector2i(-2, 0), Vector2i(0, 2), Vector2i(0, -2),
			Vector2i(1, 1), Vector2i(-1, -1)]:
		var x: int = int(exit.x) + off.x
		var y: int = int(exit.y) + off.y
		if y < 1 or y >= grid.size() - 1 or x < 1 or x >= grid[0].size() - 1:
			continue
		if String(grid[y][x]) != "floor":
			continue
		var c := ChestScene.instantiate()
		c.depth = depth
		add_child(c)
		c.global_position = Vector3(x + 0.5, 0.0, y + 0.5)
		return

# Wyrd — a boss-den's bad twin promises a visible abandoned lair (empty
# throne / fresh-dug wallow / cold roost); stamp a sarcophagus off-centre
# so the den isn't bare.
func _build_empty_throne(layout: Dictionary) -> void:
	var game := get_tree().root.get_node_or_null("Game")
	if game == null:
		return
	if not (game.affix_bad("hedgemother_den") or game.affix_bad("burrow_boar_den")
			or game.affix_bad("wolf_alpha_den")):
		return
	var boss_room = layout.get("bossRoom", null)
	if boss_room == null:
		return
	var grid: Array = layout.grid
	var cx: int = int(boss_room.x) + int(int(boss_room.w) / 2.0)
	var cy: int = int(boss_room.y) + int(int(boss_room.h) / 2.0) - 2
	if cy < 1 or cy >= grid.size() - 1 or String(grid[cy][cx]) != "floor":
		return
	var packed: PackedScene = load(_decor_model("sarcophagus"))
	if packed == null:
		return
	var inst: Node3D = packed.instantiate()
	inst.position = Vector3(cx + 0.5, 0.05, cy + 0.5)
	add_child(inst)

func _position_player(entry) -> void:
	_entry_pos = Vector3(int(entry.x) + 0.5, 0.0, int(entry.y) + 0.5)
	var game := get_node_or_null("/root/Game")
	var player: Node = game.local_player() if game != null else null
	if player != null and player is Node3D:
		(player as Node3D).position = _entry_pos
		# Hand the player its spawn so death can respawn it here (spec 15).
		if player.has_method("set_spawn"):
			player.set_spawn(_entry_pos)

func _debug_screenshot() -> void:
	if OS.get_environment("WYRD_DEV_FIRST_ROAD") == "bold":
		var player := get_tree().get_first_node_in_group("player") as Node3D
		for enemy in get_tree().get_nodes_in_group("enemy"):
			if player != null and bool(enemy.get("is_elite")) and enemy is Node3D:
				player.global_position = (enemy as Node3D).global_position + Vector3(0.0, 0.0, 4.5)
				break
	await get_tree().create_timer(0.6).timeout
	var path := OS.get_environment("WYRD_SHOT_PATH")
	if path == "":
		path = "/tmp/godot_selfshot.png"
	var img := get_viewport().get_texture().get_image()
	var err := img.save_png(path)
	print("[layout_loader] debug screenshot → %s (err=%d)" % [path, err])

# Meshy GLB materials carry a metallic value the web Compatibility renderer
# blows out into chrome — zero it so they render matte in both renderers.
func _unmetal(root: Node) -> void:
	for vi in _all_visual_instances(root):
		if vi is MeshInstance3D:
			var m: Mesh = (vi as MeshInstance3D).mesh
			if m == null:
				continue
			for s in range(m.get_surface_count()):
				var mat := m.surface_get_material(s)
				if mat is BaseMaterial3D:
					(mat as BaseMaterial3D).metallic = 0.0
					(mat as BaseMaterial3D).metallic_specular = 0.2

func _all_visual_instances(node: Node) -> Array:
	var out := []
	if node is VisualInstance3D:
		out.append(node)
	for c in node.get_children():
		out.append_array(_all_visual_instances(c))
	return out
