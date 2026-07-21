class_name DungeonGen
extends RefCounted

const DungeonScoreScript = preload("res://scripts/dungeon_score.gd")
const GatherDefs = preload("res://data/gather.gd")

# Spec 08 — quality procgen.
# Rooms-and-corridors via the Dungeon Forge creation pattern:
#   scatter a varied room cloud → relax overlaps → Delaunay → MST →
#   controlled loops → topology-derived semantics → carve and dress.
# Then generate-and-test: score each layout, keep the first that clears
# the threshold (or the best of MAX_ATTEMPTS).
#
# Returns a Dictionary layout_loader expects, plus `room_edges` (the final
# room graph) and `score` (the DungeonScore breakdown).

# ============================================================
# TUNABLES — every knob lives here.
# ============================================================
# Spec 24 — bigger grid, bigger rooms, 3-wide corridors for readability.
# Spec 29 — bump grid + rooms together so several rooms fit in the camera
#           frustum (Diablo pattern: the frame shows multiple rooms, not one).
const GRID := 48
const ROOM_MIN := 9                   # playtest: a touch larger so rooms breathe
const ROOM_MAX := 14
const SEPARATION_PASSES := 240
const ROOM_PADDING := 1.0
const DECOR_KINDS := ["bones", "torch_wall", "bookshelf"]

const LOOP_EDGE_FRACTION := 0.32      # non-MST Delaunay edges re-added —
                                      # raised (spec 25 Phase 4) for real
                                      # alternate routes, not a near-tree
const MAX_ATTEMPTS := 12              # generate-and-test budget
const SCORE_THRESHOLD := 0.70         # accept the first layout that clears this

# scorer config — target bands re-tuned (spec 24) for the wide-corridor profile
const ROOM_COUNT_MIN := 5
const ROOM_COUNT_MAX := 12
const FLOOR_RATIO_MIN := 0.22
const FLOOR_RATIO_MAX := 0.66
const CORRIDOR_RATIO_MAX := 1.5
const DEAD_END_MAX_FRAC := 0.40
const CRITICAL_PATH_TARGET_FRAC := 0.50

# Per-scope score-band defaults.  Populated here as a top-level const because
# GDScript does not allow const declarations inside static functions.
# Omitted keys fall through to the generic defaults above.
const SCOPE_BANDS := {
	"snug":       {"room_count_min": 3, "room_count_max": 7,
	               "floor_ratio_min": 0.18, "floor_ratio_max": 0.60,
	               "dead_end_max_frac": 0.50},
	"briar_maze": {"dead_end_max_frac": 0.55, "corridor_ratio_max": 2.4},
	"mire":       {"dead_end_max_frac": 0.55, "corridor_ratio_max": 2.0},
	"rootroads":  {"dead_end_max_frac": 0.48, "corridor_ratio_max": 1.8},
	"hollow":     {},
	"crypt":      {},
}

# Spec 28 — room themes are { focal, satellites }: the focal owns the room's
# centre (places first), satellites arrange around it using the existing
# patterns (walls / corners / cluster / scatter). Each room reads as one
# scene anchored on its centerpiece, not a scatter of like decor.
const ROOM_THEMES := {
	"tomb_hall": {
		"focal":      {"kind": "sarcophagus", "pattern": "center", "count": [1, 1]},
		"satellites": [
			{"kind": "sarcophagus", "pattern": "walls", "count": [3, 5]},
			{"kind": "torch_wall",  "pattern": "walls", "count": [2, 3]},
		],
	},
	"ossuary": {
		"focal":      {"kind": "bones", "pattern": "center", "count": [1, 1]},
		"satellites": [
			{"kind": "bones",      "pattern": "cluster", "count": [3, 6]},
			{"kind": "torch_wall", "pattern": "walls",   "count": [1, 2]},
		],
	},
	"archive": {
		"focal":      {"kind": "bookshelf", "pattern": "center", "count": [1, 1]},
		"satellites": [
			{"kind": "bookshelf",  "pattern": "walls", "count": [3, 5]},
			{"kind": "torch_wall", "pattern": "walls", "count": [1, 2]},
		],
	},
	"shrine": {
		"focal":      {"kind": "altar", "pattern": "center", "count": [1, 1]},
		"satellites": [
			{"kind": "rug",     "pattern": "center",  "count": [1, 1]},
			{"kind": "brazier", "pattern": "corners", "count": [2, 4]},
		],
	},
	"vault": {
		"focal":      {"kind": "chest", "pattern": "center", "count": [1, 1]},
		"satellites": [
			{"kind": "pottery", "pattern": "scatter", "count": [2, 4]},
			{"kind": "column",  "pattern": "corners", "count": [2, 4]},
		],
	},
	"antechamber": {
		"focal":      {"kind": "column", "pattern": "corners", "count": [2, 2]},
		"satellites": [
			{"kind": "brazier", "pattern": "walls", "count": [1, 2]},
		],
	},
	# Spec 29 — the rest room. Focal brazier is the interactable Hearth (the
	# layout_loader checks role==rest at the focal cell and swaps the static
	# GLB for Hearth.tscn). Satellites are pottery + wall torches for a cozy
	# hearth-and-home read.
	"hearthroom": {
		"focal":      {"kind": "brazier", "pattern": "center", "count": [1, 1]},
		"satellites": [
			{"kind": "pottery",    "pattern": "scatter", "count": [2, 3]},
			{"kind": "torch_wall", "pattern": "walls",   "count": [2, 3]},
		],
	},
	# Per-scope biome themes — reuse existing GLB kinds so no new models needed.
	# New models are a biomes-decor concern; these rooms read distinct via role
	# and placement pattern, not unique meshes.
	"root_cellar": {
		"focal":      {"kind": "pottery",   "pattern": "center", "count": [1, 1]},
		"satellites": [
			{"kind": "bones",      "pattern": "scatter", "count": [2, 4]},
			{"kind": "torch_wall", "pattern": "walls",   "count": [1, 2]},
		],
	},
	"wine_rack": {
		"focal":      {"kind": "bookshelf", "pattern": "walls",  "count": [2, 3]},
		"satellites": [
			{"kind": "pottery",    "pattern": "scatter", "count": [2, 4]},
		],
	},
	"thorn_bower": {
		"focal":      {"kind": "brazier",   "pattern": "center", "count": [1, 1]},
		"satellites": [
			{"kind": "bones",      "pattern": "scatter", "count": [2, 4]},
			{"kind": "torch_wall", "pattern": "walls",   "count": [1, 2]},
		],
	},
	"glade": {
		"focal":      {"kind": "column",    "pattern": "corners", "count": [2, 2]},
		"satellites": [
			{"kind": "pottery",    "pattern": "scatter", "count": [1, 3]},
		],
	},
	"reed_bed": {
		"focal":      {"kind": "bookshelf", "pattern": "center", "count": [1, 1]},
		"satellites": [
			{"kind": "bookshelf", "pattern": "walls", "count": [3, 5]},
			{"kind": "bones", "pattern": "scatter", "count": [2, 4]},
		],
	},
	"drowned_roots": {
		"focal":      {"kind": "altar", "pattern": "center", "count": [1, 1]},
		"satellites": [
			{"kind": "sarcophagus", "pattern": "walls", "count": [2, 4]},
			{"kind": "brazier", "pattern": "corners", "count": [1, 2]},
		],
	},
	# Spec 71 — First Road room compositions. These are deliberately compact:
	# one recognizable forest anchor plus a restrained supporting rhythm. The
	# graph still chooses and varies authored archetypes; these themes make that
	# choice visible in the room instead of leaving crypt-era theme names in
	# charge of its dressing.
	"first_lantern_landing": {
		"focal":      {"kind": "altar",   "pattern": "walls",   "count": [1, 1]},
		"satellites": [
			{"kind": "brazier", "pattern": "walls",   "count": [2, 3], "visual_scale": 0.62},
			{"kind": "bones",   "pattern": "scatter", "count": [1, 2], "visual_scale": 0.62},
		],
	},
	"first_round_glade": {
		"focal":      {"kind": "bookshelf", "pattern": "cluster", "count": [1, 1]},
		"satellites": [
			{"kind": "bones",   "pattern": "cluster", "count": [2, 4], "visual_scale": 0.62},
			{"kind": "pottery", "pattern": "walls",   "count": [1, 2], "visual_scale": 0.62},
		],
	},
	"first_crooked_bower": {
		"focal":      {"kind": "column",  "pattern": "walls",   "count": [1, 1]},
		"satellites": [
			{"kind": "bones",   "pattern": "cluster", "count": [2, 3], "visual_scale": 0.62},
			{"kind": "brazier", "pattern": "walls",   "count": [1, 2], "visual_scale": 0.62},
		],
	},
	"first_long_clearing": {
		"focal":      {"kind": "sarcophagus", "pattern": "walls",   "count": [1, 1]},
		"satellites": [
			{"kind": "pottery", "pattern": "scatter", "count": [1, 2], "visual_scale": 0.62},
			{"kind": "brazier", "pattern": "walls",   "count": [1, 2], "visual_scale": 0.62},
		],
	},
}
# Crypt fallback combat themes — used for unknown scopes.
const COMBAT_THEMES := ["tomb_hall", "ossuary", "archive"]

# Per-scope theme configuration: which combat themes and which boss room theme
# to use.  Unknown scopes fall back to crypt.
const SCOPE_THEMES := {
	"snug":       {"combat": ["root_cellar", "wine_rack", "ossuary"],
	               "boss":   "hearthroom"},
	"hollow":     {"combat": ["tomb_hall", "ossuary", "archive"],
	               "boss":   "tomb_hall"},
	"briar_maze": {"combat": ["thorn_bower", "glade", "ossuary"],
	               "boss":   "thorn_bower"},
	"mire":        {"combat": ["reed_bed", "drowned_roots", "glade"],
	               "boss":   "drowned_roots"},
	"rootroads":   {"combat": ["root_cellar", "tomb_hall", "shrine"],
	               "boss":   "tomb_hall"},
	"crypt":      {"combat": ["tomb_hall", "ossuary", "archive"],
	               "boss":   "tomb_hall"},
}

# Per-scope setpiece pools — each scope shows its own authored ASCII templates.
# Falls back to crypt pool for unknown scopes.
const SCOPE_SETPIECES := {
	"snug":       ["larder"],
	"hollow":     ["vault", "shrine", "crypt_hall"],
	"briar_maze": ["hedge_circle"],
	"mire":        ["wisp_pool"],
	"rootroads":   ["shrine", "crypt_hall"],
	"crypt":      ["vault", "shrine", "crypt_hall"],
}

# Spec 65 — the First Road is still a generated Chart graph, but each graph
# node resolves to one readable clearing grammar.  Pools are role-aware so a
# seed varies the journey without allowing an entrance, fight, or Hearth to
# lose its spatial job.
const FIRST_HOLLOW_ARCHETYPE_POOLS := {
	"entrance": ["lantern_landing"],
	"combat": ["round_glade", "crooked_bower", "long_clearing"],
	"treasure": ["crooked_bower", "round_glade"],
	"shrine": ["round_glade", "lantern_landing"],
	"rest": ["hearth_court"],
	"setpiece": ["crooked_bower", "long_clearing"],
	"boss": ["hearth_court"],
	"default": ["round_glade", "crooked_bower", "long_clearing"],
}
const FIRST_HOLLOW_ARCHETYPE_SHAPES := {
	"lantern_landing": "rounded",
	"round_glade": "oval",
	"crooked_bower": "irregular",
	"long_clearing": "rounded",
	"hearth_court": "rounded",
}

# Spec 66 — a room archetype now owns the rhythm of its living edge as well as
# its floor mask.  These are presentation profiles, not decor spawns: they sit
# on the already-colliding boundary and cannot consume the room's combat stage.
const FIRST_HOLLOW_EDGE_PROFILES := {
	"lantern_landing": ["leaf_bank", "fern_bank", "stone_bank"],
	"round_glade": ["leaf_bank", "fern_bank", "root_bank"],
	"crooked_bower": ["bramble_bank", "root_bank", "leaf_bank"],
	"long_clearing": ["root_bank", "stone_bank", "leaf_bank"],
	"hearth_court": ["root_bank", "leaf_bank", "stone_bank"],
	"default": ["leaf_bank", "root_bank", "stone_bank"],
}
const FIRST_HOLLOW_LANDMARK_PROFILES := {
	"lantern_landing": "lantern_oak",
	"round_glade": "old_oak",
	"crooked_bower": "bramble_oak",
	"long_clearing": "fallen_log",
	"hearth_court": "hearth_oak",
}
const FIRST_HOLLOW_ARCHETYPE_THEMES := {
	"lantern_landing": "first_lantern_landing",
	"round_glade": "first_round_glade",
	"crooked_bower": "first_crooked_bower",
	"long_clearing": "first_long_clearing",
}

# Spec 25 Phase 3 — authored setpieces. ASCII templates in data/rooms/;
# one is stamped into the largest eligible room each run.
const SETPIECES := ["vault", "shrine"]
const SETPIECE_DECOR := {
	"o": "column", "c": "chest", "a": "altar", "b": "brazier",
	"p": "pottery", "s": "sarcophagus", "k": "bones", "r": "rug",
}
# ============================================================

# Wyrd — chart-aware scoring bands. A chart's gen block may shrink the
# grid / room bands; the acceptance bands shift with it or the 0.70 gate
# silently degrades every small chart to a best-of-12 fallback.
static func _score_cfg(cfg: Dictionary = {}) -> Dictionary:
	var scope := String(cfg.get("scope", "crypt"))
	# Per-scope defaults shift the acceptance bands to match the scope's grid
	# profile so snug and briar_maze charts don't silently degrade to best-of-12.
	var sb: Dictionary = SCOPE_BANDS.get(scope, {})
	return {
		"room_count_min":           int(cfg.get("room_count_min",   sb.get("room_count_min",   ROOM_COUNT_MIN))),
		"room_count_max":           int(cfg.get("room_count_max",   sb.get("room_count_max",   ROOM_COUNT_MAX))),
		"floor_ratio_min":          float(cfg.get("floor_ratio_min", sb.get("floor_ratio_min",  FLOOR_RATIO_MIN))),
		"floor_ratio_max":          float(cfg.get("floor_ratio_max", sb.get("floor_ratio_max",  FLOOR_RATIO_MAX))),
		"corridor_ratio_max":       float(cfg.get("corridor_ratio_max", sb.get("corridor_ratio_max", CORRIDOR_RATIO_MAX))),
		"dead_end_max_frac":        float(cfg.get("dead_end_max_frac",  sb.get("dead_end_max_frac",  DEAD_END_MAX_FRAC))),
		"critical_path_target_frac": CRITICAL_PATH_TARGET_FRAC,
	}

# Generate a dungeon. Pass -1 for a random base seed.
# Generate-and-test: returns the first layout to clear SCORE_THRESHOLD,
# else the best of MAX_ATTEMPTS. Always returns a playable layout.
#
# Wyrd — `cfg` is the chart's generation block (Game.run_cfg()):
#   grid / room_min / room_max / room_count_min / room_count_max /
#   loop_fraction / corridor_ratio_max  — layout knobs
#   affixes: [{id, good, resolvedId}]   — good bias twins scatter gather decor
#   boss_kind: "" | "hedgemother"       — boss-as-affix ("" = no boss)
#   campaign_clue: {id, presentation}    — one authored, non-Second-Hand
#                                             clue placed in a valid side room
#   required_biome_gather: [ids]         — exact reachable biome resources;
#                                             invalid attempts are rejected
#   scope / tier / seed                 — passthrough metadata
# An empty cfg reproduces the pre-chart defaults (boss included).
static func generate(seed_value: int = -1, cfg: Dictionary = {}) -> Dictionary:
	var base: int = seed_value
	if base < 0:
		var r := RandomNumberGenerator.new()
		r.randomize()
		base = int(r.seed)

	var best: Dictionary = {}
	var best_total := -1.0
	for attempt in MAX_ATTEMPTS:
		var rng := RandomNumberGenerator.new()
		# Knuth multiplicative hash to decorrelate attempt seeds.
		rng.seed = (base + attempt * 2654435761) & 0x7FFFFFFFFFFFFFFF
		var layout := _generate_one(rng, cfg)
		# Authored rooms, resources, and campaign evidence are promises, not a
		# best-effort budget. A rejected attempt is preferable to returning a
		# Chart that advertised content which did not actually materialize.
		if not bool(layout.get("required_content_valid", true)):
			continue
		var score: Dictionary = DungeonScoreScript.score_layout(layout, _score_cfg(cfg))
		layout["score"] = score
		layout["attempts"] = attempt + 1
		if score.total > best_total:
			best_total = score.total
			best = layout
		if score.total >= SCORE_THRESHOLD:
			best["attempts"] = attempt + 1
			return best
	return best

# ---- one layout ----
static func _generate_one(rng: RandomNumberGenerator, cfg: Dictionary = {}) -> Dictionary:
	var grid_n: int = int(cfg.get("grid", GRID))
	var room_min: int = int(cfg.get("room_min", ROOM_MIN))
	var room_max: int = int(cfg.get("room_max", ROOM_MAX))
	var grid := []
	for y in grid_n:
		var row := []
		for x in grid_n:
			row.append("wall")
		grid.append(row)

	# 1. Scatter a compact cloud, then iteratively separate overlapping rooms.
	# Room-count Affixes now choose the cloud population directly instead of
	# hoping a rejection loop happens to land inside the requested band.
	var count_min := maxi(3, int(cfg.get("room_count_min", ROOM_COUNT_MIN)))
	var count_max := maxi(count_min, int(cfg.get("room_count_max", ROOM_COUNT_MAX)))
	var target_count := rng.randi_range(count_min, count_max)
	var rooms := _scatter_and_separate_rooms(rng, grid_n, room_min, room_max,
		target_count)
	if rooms.size() < 3:
		rooms = _fallback_room_chain(grid_n, room_min)

	# 2. Build the navigation graph before carving. The largest chamber is the
	# boss arena; the entrance is the most distant leaf, so each run has a real
	# approach rather than inheriting whichever room happened to be generated first.
	var centers := PackedVector2Array()
	for r in rooms:
		centers.append(Vector2(
			r.x + r.w / 2.0, r.y + r.h / 2.0))

	var delaunay_edges := _delaunay_edges(centers)
	var mst_edges := _mst(delaunay_edges, centers, rooms.size())
	var loop_edges := _loop_edges(delaunay_edges, mst_edges, rng,
		float(cfg.get("loop_fraction", LOOP_EDGE_FRACTION)))
	var final_edges: Array = mst_edges.duplicate()
	final_edges.append_array(loop_edges)
	var adj := _adjacency(rooms.size(), final_edges)
	var boss_idx := _largest_room(rooms)
	var entry_idx := _farthest_leaf(adj, boss_idx)
	var remapped := _remap_entry_first(rooms, final_edges, entry_idx, boss_idx)
	rooms = remapped.rooms
	final_edges = remapped.edges
	boss_idx = int(remapped.boss_idx)
	adj = _adjacency(rooms.size(), final_edges)

	# 3. Freeze topology-derived pacing and semantics before any geometry or
	# decoration consumes RNG. This makes the critical route inspectable by the
	# loading screen and gives side branches distinct purposes.
	var room_depths: Array = _bfs_depths(adj, 0, rooms.size())
	var critical_room_ids: Array = _room_path(adj, 0, boss_idx)
	var max_room_depth := 1
	for depth_v in room_depths:
		max_room_depth = maxi(max_room_depth, int(depth_v))
	for i in rooms.size():
		rooms[i]["id"] = i
		rooms[i]["depth"] = int(room_depths[i])
		rooms[i]["difficulty"] = float(room_depths[i]) / float(max_room_depth)
		rooms[i]["critical"] = critical_room_ids.has(i)

	var gen_scope := String(cfg.get("scope", "crypt"))
	var required_room_roles: Array = _normalized_required_room_roles(
		cfg.get("required_room_roles", []))
	var required_roles_valid := _assign_rooms(rooms, rng, boss_idx, adj,
		gen_scope, required_room_roles)
	_pick_setpiece(rooms, rng, gen_scope)
	_assign_archetypes(rooms, rng, gen_scope)

	# 4. Carve rooms and route corridors. Critical-route corridors are broad and
	# readable; ordinary links are narrower, while optional treasure spurs may
	# become intimate single-tile discoveries.
	for r in rooms:
		_carve_room(grid, r, rng)
	var critical_edges := _path_edge_keys(critical_room_ids)
	var corridor_widths := {}
	for e_v in final_edges:
		var e: Array = e_v
		var key := _edge_key(int(e[0]), int(e[1]))
		var width := 3 if critical_edges.has(key) else 2
		if width == 2 and _edge_touches_role(rooms, e, "treasure"):
			width = 1
		corridor_widths[key] = width
		_carve_corridor(grid, rooms[int(e[0])], rooms[int(e[1])], width, rng)

	# The boss arena is always a full rectangle; the seal and authored boss
	# encounters require a clean, guaranteed footprint.
	var first: Dictionary = rooms[0]
	var entry := {
		"x": int(first.x + first.w / 2.0),
		"y": int(first.y + first.h / 2.0),
	}
	var boss: Dictionary = rooms[boss_idx]
	for yy in range(int(boss.y), int(boss.y) + int(boss.h)):
		for xx in range(int(boss.x), int(boss.x) + int(boss.w)):
			grid[yy][xx] = "floor"
	_capture_room_footprints(rooms, grid)
	var boundary_cells: Array = _boundary_cells(grid)
	var perimeter_dressing: Array = _first_hollow_perimeter_dressing(
		rooms, boundary_cells, grid, int(rng.seed), gen_scope)
	var exit := {
		"x": int(boss.x + boss.w / 2.0),
		"y": int(boss.y + boss.h / 2.0),
	}

	# 5. Dress the frozen topology and realize all authored contracts.
	var decor: Array = _dress_rooms(rooms, grid, entry, exit, rng)
	# The generator owns both halves of the promise: a role-bearing room and
	# its focal interactable marker. LayoutLoader only realizes this data.
	if required_roles_valid:
		required_roles_valid = _required_roles_are_realized(rooms, decor,
			required_room_roles)
	for r in rooms:
		if r.get("role", "") == "setpiece":
			_stamp_setpiece(grid, r, decor)

	# Wyrd — good bias twins scatter gather nodes (ore / forage / logs)
	# through the dungeon. Bad twins are pure omission.
	_scatter_gather_nodes(rooms, grid, entry, exit, decor, rng,
		cfg.get("affixes", []), boss_idx, int(cfg.get("tier", 1)),
		room_depths, critical_room_ids, gen_scope)
	var resource_result := _scatter_biome_gather(gen_scope, rooms, grid, entry,
		exit, decor, rng, boss_idx, cfg)
	var story_clues: Array = _first_chapter_clues(
		String(cfg.get("template_id", "")), rooms, exit, boss_idx, room_depths)
	# Campaign evidence is deliberately a second layout channel. The older
	# Second Hand marks are atmospheric observations, whereas a campaign clue
	# advances a bounded authored chapter. Never fold the latter into
	# `story_clues`, or a cosmetic reread can accidentally become campaign truth.
	var campaign_clues: Array = _campaign_clues(
		cfg.get("campaign_clue", {}), rooms, boss_idx, room_depths, story_clues)
	var required_resource_manifest: Array = resource_result.get("manifest", [])
	var required_resources_valid := bool(resource_result.get("valid", true)) \
		and _guarantee_rooms_reachable(required_resource_manifest, adj, boss_idx)
	var required_campaign_clue_valid := _campaign_clue_guarantee_valid(
		cfg.get("campaign_clue", {}), campaign_clues, adj, boss_idx)
	var required_content_valid := required_roles_valid and required_resources_valid \
		and required_campaign_clue_valid
	# An authored campaign boss is a contract, not an Affix outcome. Keep this
	# guard at the generator boundary too: direct callers (tests, tooling, and
	# future co-op adapters) cannot accidentally reintroduce the Empty Den path
	# by passing a bad twin alongside a valid contract.
	var campaign_contract: Dictionary = cfg.get("campaign_contract", {}) \
		if cfg.get("campaign_contract", {}) is Dictionary else {}
	var handoff_contract: Dictionary = cfg.get("handoff_contract", {}) \
		if cfg.get("handoff_contract", {}) is Dictionary else {}
	var resolved_boss_kind := String(campaign_contract.get("boss_kind",
		handoff_contract.get("boss_kind", cfg.get("boss_kind", "hedgemother"))))

	return {
		"grid": grid,
		"entry": entry,
		"exit": exit,
		"chestTile": exit,
		"rooms": rooms,
		"room_edges": final_edges,
		"corridor_widths": corridor_widths,
		"generation_pattern": "scatter_separate_delaunay_mst",
		"critical_room_ids": critical_room_ids,
		"entry_room_id": 0,
		"boss_room_id": boss_idx,
		"room_depths": room_depths,
		"decor": decor,
		"boundary_cells": boundary_cells,
		"perimeter_dressing": perimeter_dressing,
		"story_clues": story_clues,
		"campaign_clues": campaign_clues,
		"campaign_contract": campaign_contract.duplicate(true),
		"handoff_contract": handoff_contract.duplicate(true),
		"encounter_contract": (cfg.get("encounter_contract", {}) as Dictionary).duplicate(true),
		"elite_manifest": (cfg.get("elite_manifest", {}) as Dictionary).duplicate(true) \
			if cfg.get("elite_manifest", {}) is Dictionary else {},
		"required_room_roles": required_room_roles.duplicate(),
		"required_roles_valid": required_roles_valid,
		"required_resource_manifest": required_resource_manifest.duplicate(true),
		"required_resources_valid": required_resources_valid,
		"required_campaign_clue_valid": required_campaign_clue_valid,
		"required_content_valid": required_content_valid,
		"bossRoom": boss,
		"bossKind": resolved_boss_kind,
		"scope": String(cfg.get("scope", "crypt")),
		"tier": int(cfg.get("tier", 1)),
		"seed": int(rng.seed),
	}

# Spec 55 — guaranteed evidence, expressed as layout data so the generator test
# can prove it and layout_loader can choose the world presentation. These are
# optional interactions, never objective markers.
static func _first_chapter_clues(template_id: String, rooms: Array,
		exit: Dictionary, boss_idx: int, depths: Array) -> Array:
	if template_id == "snug":
		var boss_room: Dictionary = rooms[boss_idx]
		return [{
			"id": "far_waystone", "presentation": "etched_stone",
			"x": clampi(int(exit.x) + 2, int(boss_room.x) + 1,
				int(boss_room.x) + int(boss_room.w) - 2),
			"y": int(exit.y), "room_id": boss_idx,
		}]
	if template_id != "tier_1":
		return []
	# Prefer a typed/strange room; otherwise the deepest non-boss room still
	# carries a side interaction that the main completion route never requires.
	var best_idx := -1
	var best_score := -1
	for i in rooms.size():
		if i == 0 or i == boss_idx:
			continue
		var role := String((rooms[i] as Dictionary).get("role", "combat"))
		var role_bonus := 100 if role in ["treasure", "setpiece", "shrine"] else 0
		var score := role_bonus + int(depths[i])
		if score > best_score:
			best_score = score
			best_idx = i
	if best_idx < 0:
		return []
	var room: Dictionary = rooms[best_idx]
	return [{
		"id": "inked_scrap", "presentation": "inked_scrap",
		"x": int(room.x) + maxi(1, int(room.w) / 2 - 2),
		"y": int(room.y) + int(room.h) / 2,
		"room_id": best_idx,
	}]


# Slice D1 — a campaign clue is an authored promise rather than a random
# drop. Game supplies this opt-in contract only when the player is missing the
# clue; the generator's responsibility is to give it exactly one reachable
# non-entry/non-boss presentation. Its location can vary with the Chart seed,
# but the story fact cannot disappear behind an elite roll or an Affix twin.
static func _campaign_clues(raw_contract, rooms: Array, boss_idx: int,
		depths: Array, story_clues: Array) -> Array:
	if not raw_contract is Dictionary:
		return []
	var contract: Dictionary = raw_contract
	# CampaignData calls the durable identifier `clue_id`; accept `id` too so
	# presentation tooling can pass its compact form without changing the
	# authored contract. The generated layout always normalizes back to `id`.
	var clue_id := String(contract.get("clue_id", contract.get("id", "")))
	if clue_id == "":
		return []
	var ranked: Array = []
	for i in rooms.size():
		if i == 0 or i == boss_idx:
			continue
		var room: Dictionary = rooms[i]
		var role := String(room.get("role", "combat"))
		var role_bonus := 100 if role in ["treasure", "setpiece", "shrine", "rest"] else 0
		ranked.append({"room_id": i, "score": role_bonus + int(depths[i]), "room": room})
	ranked.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.score) > int(b.score))
	for candidate_v in ranked:
		var candidate: Dictionary = candidate_v
		var room: Dictionary = candidate.room
		var x := int(room.x) + int(room.w) / 2
		var y := int(room.y) + int(room.h) / 2
		var occupied := false
		for existing_v in story_clues:
			var existing: Dictionary = existing_v
			if int(existing.get("x", -1)) == x and int(existing.get("y", -1)) == y:
				occupied = true
				break
		if occupied:
			# Stay within the chosen room but avoid laying campaign evidence on
			# an atmospheric Second Hand mark.
			x = mini(int(room.x) + int(room.w) - 2, x + 2)
		return [{
			"id": clue_id,
			"presentation": String(contract.get("presentation", "thorn_whisper")),
			"x": x, "y": y,
			"room_id": int(candidate.room_id),
			"chapter_id": String(contract.get("chapter_id", "")),
		}]
	return []


static func _room_reachable(adj: Array, room_id: int) -> bool:
	if room_id < 0 or room_id >= adj.size() or adj.is_empty():
		return false
	var seen := {0: true}
	var queue: Array[int] = [0]
	while not queue.is_empty():
		var current: int = queue.pop_front()
		if current == room_id:
			return true
		for next_v in adj[current]:
			var next_id := int(next_v)
			if not seen.has(next_id):
				seen[next_id] = true
				queue.append(next_id)
	return false


static func _guarantee_rooms_reachable(manifest: Array, adj: Array,
		boss_idx: int) -> bool:
	for row_v in manifest:
		if not row_v is Dictionary:
			return false
		var room_id := int((row_v as Dictionary).get("room_id", -1))
		if room_id <= 0 or room_id == boss_idx or not _room_reachable(adj, room_id):
			return false
	return true


static func _campaign_clue_guarantee_valid(raw_contract, clues: Array,
		adj: Array, boss_idx: int) -> bool:
	if not raw_contract is Dictionary:
		return clues.is_empty()
	var clue_id := String((raw_contract as Dictionary).get("clue_id",
		(raw_contract as Dictionary).get("id", "")))
	if clue_id == "":
		return clues.is_empty()
	if clues.size() != 1 or not clues[0] is Dictionary:
		return false
	var clue: Dictionary = clues[0]
	var room_id := int(clue.get("room_id", -1))
	return String(clue.get("id", "")) == clue_id \
		and room_id > 0 and room_id != boss_idx \
		and _room_reachable(adj, room_id)

# ---- Wyrd: chart bias affixes → gather-node decor ----
# Mirrors the shipped three.js consumer (src/scene/dungeon.js:253-303):
# the good twin scatters nodes on random non-entry/non-boss room floor
# tiles; the bad twin simply places nothing.
# B6 — gilded (good twin) hides two extra chests; reuses the gather
# scatter machinery with chest decor instead of nodes.
const GATHER_BY_AFFIX := {
	"gilded": {"kind": "chest", "item": "", "count": [2, 2]},
	"mineral_vein":  {"kind": "ore_rock",    "item": "bogiron_ore", "count": [3, 5]},
	"bramble_bloom": {"kind": "forage_node", "item": "wild_herb",   "count": [4, 6]},
	# herbal_patch is the Lv-14 upgrade over bramble_bloom: same herb, richer
	# yield — otherwise the unlock would be a dressed-up duplicate.
	"herbal_patch":  {"kind": "forage_node", "item": "wild_herb",   "count": [6, 9]},
	"wood_grove":    {"kind": "log_pile",    "item": "logs",        "count": [3, 5]},
}

# D7's fresh-marathon driver normally requires a completed production gather
# on each prior-saga World leg. Briar Maze is the one authored exception: it
# has no native resource manifest, and all of its resource nodes come only
# from *good* gather-bias Affixes. A run with no such twin is meant to be an
# empty road, not a failed generator or scanner. Keep this contract here beside
# the actual scatter table so a future gather Affix cannot silently widen the
# browser driver's exception.
#
# `realized_gather_candidates` is deliberately part of the seam. A World that
# did expose a GatherNode must still prove a normal channel; only an actually
# empty World can be excused.
static func allows_authored_zero_production_gather(cfg: Dictionary,
		realized_gather_candidates: int) -> bool:
	if realized_gather_candidates != 0:
		return false
	if String(cfg.get("scope", "")) != "briar_maze" \
			or int(cfg.get("tier", 0)) != 2:
		return false
	# A template-level biome guarantee always wins over an Affix outcome.
	var required_biome_gather := GatherDefs.effective_biome_gather(
		String(cfg.get("scope", "")), cfg.get("required_biome_gather", []))
	if not required_biome_gather is Array or not (required_biome_gather as Array).is_empty():
		return false
	for affix_v in cfg.get("affixes", []):
		if not affix_v is Dictionary:
			continue
		var affix: Dictionary = affix_v
		if not bool(affix.get("good", false)):
			continue
		var spec: Dictionary = GATHER_BY_AFFIX.get(String(affix.get("id", "")), {})
		# Gilded uses this shared table to scatter chests. It is deliberately not
		# a GatherNode and must not make a real zero-resource Briar fail.
		if String(spec.get("kind", "")) in ["forage_node", "ore_rock", "log_pile"]:
			return false
	return true

# D2 currently authors only Hearth/rest, but normalize defensively here so a
# malformed config cannot make an unverifiable promise or change classic runs.
static func _normalized_required_room_roles(raw) -> Array:
	var out: Array = []
	if not raw is Array:
		return out
	for role_v in raw:
		var role := String(role_v)
		if role in ["rest"] and not out.has(role):
			out.append(role)
	return out

static func _required_roles_are_realized(rooms: Array, decor: Array,
		required_roles: Array) -> bool:
	for role_v in required_roles:
		var role := String(role_v)
		var room_ok := false
		for room_v in rooms:
			if room_v is Dictionary and String((room_v as Dictionary).get("role", "")) == role:
				room_ok = true
				break
		if not room_ok:
			return false
		var focal_ok := false
		for decor_v in decor:
			if decor_v is Dictionary and String((decor_v as Dictionary).get("interact_role", "")) == role:
				focal_ok = true
				break
		if not focal_ok:
			return false
	return true

static func _scatter_gather_nodes(rooms: Array, grid: Array, entry: Dictionary,
		exit: Dictionary, decor: Array, rng: RandomNumberGenerator,
		affixes: Array, boss_idx: int, chart_tier: int = 1,
		room_depths: Array = [], critical_room_ids: Array = [], scope: String = "") -> void:
	for a in affixes:
		if not bool(a.get("good", false)):
			continue
		var affix_id := String(a.get("id", ""))
		var spec: Dictionary = GATHER_BY_AFFIX.get(affix_id, {})
		if spec.is_empty():
			continue
		var n: int = rng.randi_range(int(spec.count[0]), int(spec.count[1]))
		var placed := 0
		var tries := 0
		var room_order := _semantic_gather_room_order(rooms, boss_idx,
			room_depths, critical_room_ids, rng)
		while placed < n and tries < 240 and not room_order.is_empty():
			tries += 1
			# Round-robin through the semantic order before revisiting a room.
			# Side branches and typed rooms lead; the critical road remains readable.
			var ri: int = int(room_order[(tries - 1) % room_order.size()])
			var r: Dictionary = rooms[ri]
			var x := rng.randi_range(int(r.x), int(r.x) + int(r.w) - 1)
			var y := rng.randi_range(int(r.y), int(r.y) + int(r.h) - 1)
			if String(grid[y][x]) != "floor":
				continue
			if String(r.get("role", "")) == "combat" \
					and _inside_protected_aperture(r, x, y):
				continue
			if x == int(entry.x) and y == int(entry.y):
				continue
			if x == int(exit.x) and y == int(exit.y):
				continue
			var occupied := false
			for d in decor:
				if int(d.x) == x and int(d.y) == y:
					occupied = true
					break
			if occupied:
				continue
			var entry_d := {"kind": String(spec.kind), "item": String(spec.item),
				"gather": String(spec.kind) != "chest",
				"x": x, "y": y, "orient": "center", "room_id": ri,
				"room_depth": int(room_depths[ri]) if ri < room_depths.size() else 0,
				"source": "affix", "source_affix": affix_id}
			# A6/45 — gather nodes roll a tier from the data tables; deeper
			# charts carry the richer veins and the rarer herbs. Briar Maze's first
			# node from each good gather Affix is the lowest authored tier in that
			# chart band. This gives that authored road one usable anchor at its
			# support-Trade contract while later nodes remain aspirational rolls.
			var briar_anchor := scope == "briar_maze" and placed == 0
			if affix_id == "mineral_vein":
				entry_d["ore_tier"] = _lowest_roll_tier(
					GatherDefs.ORE_ROLLS_BY_TIER, chart_tier) if briar_anchor else \
					_roll_tier(GatherDefs.ORE_ROLLS_BY_TIER, chart_tier, rng)
			elif affix_id == "bramble_bloom":
				entry_d["herb_tier"] = _lowest_roll_tier(
					GatherDefs.FORAGE_ROLLS_BY_TIER, chart_tier) if briar_anchor else \
					_roll_tier(GatherDefs.FORAGE_ROLLS_BY_TIER, chart_tier, rng)
			elif affix_id == "herbal_patch":
				entry_d["herb_tier"] = _lowest_roll_tier(
					GatherDefs.FORAGE_ROLLS_PATCH, chart_tier) if briar_anchor else \
					_roll_tier(GatherDefs.FORAGE_ROLLS_PATCH, chart_tier, rng)
			decor.append(entry_d)
			placed += 1
	# Spec 45-earth — the Summit is made of the stuff: two fixed hedgesteel
	# veins, the only ore the slotless capstone chart carries.
	if chart_tier >= 3:
		var hs_placed := 0
		var hs_tries := 0
		while hs_placed < 2 and hs_tries < 200:
			hs_tries += 1
			var hri := rng.randi_range(0, rooms.size() - 1)
			if hri == 0 or hri == boss_idx:
				continue
			var hr: Dictionary = rooms[hri]
			var hx := rng.randi_range(int(hr.x), int(hr.x) + int(hr.w) - 1)
			var hy := rng.randi_range(int(hr.y), int(hr.y) + int(hr.h) - 1)
			if String(grid[hy][hx]) != "floor":
				continue
			var hs_occupied := false
			for d in decor:
				if int(d.x) == hx and int(d.y) == hy:
					hs_occupied = true
					break
			if hs_occupied:
				continue
			decor.append({"kind": "ore_rock", "item": "hedgesteel_ore",
				"gather": true, "x": hx, "y": hy, "orient": "center",
				"ore_tier": "hedgesteel"})
			hs_placed += 1
		# Spec 45-wilds — two fixed stonebreak patches to match: the Summit
		# grows it; almost nowhere else does.
		var sb_placed := 0
		var sb_tries := 0
		while sb_placed < 2 and sb_tries < 200:
			sb_tries += 1
			var sri := rng.randi_range(0, rooms.size() - 1)
			if sri == 0 or sri == boss_idx:
				continue
			var sr: Dictionary = rooms[sri]
			var sx := rng.randi_range(int(sr.x), int(sr.x) + int(sr.w) - 1)
			var sy := rng.randi_range(int(sr.y), int(sr.y) + int(sr.h) - 1)
			if String(grid[sy][sx]) != "floor":
				continue
			var sb_occupied := false
			for d in decor:
				if int(d.x) == sx and int(d.y) == sy:
					sb_occupied = true
					break
			if sb_occupied:
				continue
			decor.append({"kind": "forage_node", "item": "stonebreak",
				"gather": true, "x": sx, "y": sy, "orient": "center",
				"herb_tier": "stonebreak"})
			sb_placed += 1


static func _semantic_gather_room_order(rooms: Array, boss_idx: int,
		depths: Array, critical_room_ids: Array,
		rng: RandomNumberGenerator) -> Array:
	var candidates: Array = []
	for i in rooms.size():
		if i == 0 or i == boss_idx:
			continue
		var room: Dictionary = rooms[i]
		var role := String(room.get("role", "combat"))
		var role_bonus := 30 if role in ["treasure", "shrine", "rest", "setpiece"] else 0
		var branch_bonus := 100 if not critical_room_ids.has(i) else 0
		var depth := int(depths[i]) if i < depths.size() else 0
		# Seeded jitter keeps equally suitable rooms varied without losing the
		# side-branch/depth preference.
		candidates.append({"id": i,
			"score": branch_bonus + role_bonus + depth * 3 + rng.randi_range(0, 2)})
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.score) > int(b.score))
	var out: Array = []
	for candidate in candidates:
		out.append(int(candidate.id))
	return out

# A biome's native resource is part of its return reason, not an Affix lottery.
# Mire charts always grow two Mothmint patches away from entry/exit; Affixes may
# add more gathering on top.
static func _scatter_biome_gather(scope: String, rooms: Array, grid: Array,
		entry: Dictionary, exit: Dictionary, decor: Array,
		rng: RandomNumberGenerator, boss_idx: int, cfg: Dictionary = {}) -> Dictionary:
	var result := {"valid": true, "manifest": []}
	var required: Array = GatherDefs.effective_biome_gather(
		scope, cfg.get("required_biome_gather", []))
	if scope == "hollow":
		var resources: Array = []
		if required.has("copper"):
			resources.append({"tier_key": "copper", "kind": "ore_rock",
				"item": "copper_ore", "count": 1})
		if required.has("wild"):
			resources.append({"tier_key": "wild", "kind": "forage_node",
				"item": "wild_herb", "count": 1})
		if required.has("logs"):
			resources.append({"tier_key": "", "kind": "log_pile",
				"item": "logs", "count": 1})
		return _scatter_required_resources(resources, rooms, grid, entry, exit, decor,
			rng, boss_idx)
	if scope in ["rootroads", "ashen_bough"]:
		return _scatter_rootroad_gather(rooms, grid, entry, exit, decor, rng, boss_idx,
			required)
	if scope != "mire":
		return result
	# Native Mire harvest is a run-side production contract, not a decorative
	# best effort. Route it through the same manifest validator as other biome
	# guarantees so a crowded small Shallows retries generation instead of
	# silently shipping without the Mothmint its next ink asks the player to use.
	var mire_resources: Array = []
	if required.has("mothmint"):
		mire_resources.append({
			"guarantee_id": "mire_mothmint", "tier_key": "mothmint",
			"kind": "forage_node", "item": "mothmint", "count": 2,
		})
	return _scatter_required_resources(mire_resources, rooms, grid, entry, exit,
		decor, rng, boss_idx)

# Rootroads have authored, deterministic gathering reasons rather than an
# Affix lottery. Wildgold's starter vein is a normal Earthcraft-18 node (not a
# tool check); later templates add Wellwater and the Ashen Bough's Embersage.
static func _scatter_rootroad_gather(rooms: Array, grid: Array, entry: Dictionary,
		exit: Dictionary, decor: Array, rng: RandomNumberGenerator, boss_idx: int,
		required_resources: Array) -> Dictionary:
	var resources: Array = [
		{"tier_key": "wildgold", "kind": "ore_rock", "item": "wildgold_ore", "count": 1},
		{"tier_key": "wellmoss", "kind": "forage_node", "item": "wellmoss", "count": 2},
	]
	if required_resources.has("wellwater"):
		resources.append({"tier_key": "wellwater", "kind": "forage_node",
			"item": "wellwater", "count": 1})
	if required_resources.has("embersage"):
		resources.append({"tier_key": "embersage", "kind": "forage_node",
			"item": "embersage", "count": 2})
	if required_resources.has("waysteel"):
		resources.append({"guarantee_id": "waysteel", "tier_key": "waysteel",
			"kind": "ore_rock", "item": "waysteel_shard", "count": 1})
	if required_resources.has("root_sap"):
		resources.append({"guarantee_id": "root_sap", "tier_key": "root_sap",
			"kind": "forage_node", "item": "root_sap", "count": 1})
	return _scatter_required_resources(resources, rooms, grid, entry, exit, decor, rng,
		boss_idx)


static func _scatter_required_resources(resources: Array, rooms: Array, grid: Array,
		entry: Dictionary, exit: Dictionary, decor: Array,
		rng: RandomNumberGenerator, boss_idx: int) -> Dictionary:
	var manifest: Array = []
	var valid := true
	for resource_v in resources:
		var resource: Dictionary = resource_v
		var placed := 0
		var tries := 0
		while placed < int(resource.count) and tries < 300:
			tries += 1
			var ri := rng.randi_range(0, rooms.size() - 1)
			if ri == 0 or ri == boss_idx:
				continue
			var room: Dictionary = rooms[ri]
			var x := rng.randi_range(int(room.x), int(room.x) + int(room.w) - 1)
			var y := rng.randi_range(int(room.y), int(room.y) + int(room.h) - 1)
			if String(grid[y][x]) != "floor" or (x == int(entry.x) and y == int(entry.y)) \
					or (x == int(exit.x) and y == int(exit.y)):
				continue
			if String(room.get("role", "")) == "combat" \
					and _inside_protected_aperture(room, x, y):
				continue
			var occupied := (decor as Array).any(func(d):
				return int((d as Dictionary).x) == x and int((d as Dictionary).y) == y)
			if occupied:
				continue
			var node := {"kind": String(resource.kind), "item": String(resource.item),
				"gather": true, "x": x, "y": y, "orient": "center",
				"biome_signature": true, "room_id": ri,
				"guaranteed_resource": true,
				"guarantee_id": String(resource.get("guarantee_id",
					resource.get("tier_key", resource.get("item", ""))))}
			if String(resource.kind) == "ore_rock" and String(resource.tier_key) != "":
				node["ore_tier"] = String(resource.tier_key)
			elif String(resource.kind) == "forage_node" and String(resource.tier_key) != "":
				node["herb_tier"] = String(resource.tier_key)
			decor.append(node)
			manifest.append({
				"id": String(node.guarantee_id),
				"item": String(resource.item),
				"kind": String(resource.kind),
				"tier_key": String(resource.get("tier_key", "")),
				"x": x, "y": y, "room_id": ri,
			})
			placed += 1
		if placed != int(resource.count):
			valid = false
	return {"valid": valid, "manifest": manifest}

# Spec 45 — weighted tier pick from a {chart_tier: {tier_id: weight}}
# table; clamps the chart tier into the table's range.
static func _roll_tier(table: Dictionary, chart_tier: int,
		rng: RandomNumberGenerator) -> String:
	var key := clampi(chart_tier, 1, 3)
	while not table.has(key) and key > 1:
		key -= 1
	var weights: Dictionary = table.get(key, {})
	var total := 0
	for t in weights:
		total += int(weights[t])
	if total <= 0:
		return ""
	var roll := rng.randi_range(1, total)
	for t in weights:
		roll -= int(weights[t])
		if roll <= 0:
			return String(t)
	return String(weights.keys()[0])


# Lowest tier in the same authored weighted band used by `_roll_tier`.
# Dictionary insertion order is the data table's progression order, but choose
# by the actual Trade requirement so a future reorder cannot deepen the anchor.
static func _lowest_roll_tier(table: Dictionary, chart_tier: int) -> String:
	var key := clampi(chart_tier, 1, 3)
	while not table.has(key) and key > 1:
		key -= 1
	var weights: Dictionary = table.get(key, {})
	var lowest := ""
	var lowest_requirement := 1 << 30
	for tier_v in weights:
		var tier := String(tier_v)
		var requirement := 1 << 29
		if GatherDefs.ORE_TIERS.has(tier):
			requirement = int((GatherDefs.ORE_TIERS[tier] as Dictionary).get("req_lv", 1))
		elif GatherDefs.HERB_TIERS.has(tier):
			requirement = int((GatherDefs.HERB_TIERS[tier] as Dictionary).get("req_lv", 1))
		if requirement < lowest_requirement:
			lowest = tier
			lowest_requirement = requirement
	return lowest


# Dungeon Forge-inspired spatial phase. Rooms begin as a compact, deliberately
# overlapping cloud and push one another apart. Several bounded passes are
# cheaper and more predictable than the old unbounded rejection lottery.
static func _scatter_and_separate_rooms(rng: RandomNumberGenerator, grid_n: int,
		room_min: int, room_max: int, target_count: int) -> Array:
	var best: Array = []
	for retry in 4:
		var requested := maxi(3, target_count - retry)
		var candidate := _scatter_cloud_once(rng, grid_n, room_min, room_max,
			requested)
		if candidate.size() > best.size():
			best = candidate
		if candidate.size() >= requested:
			return candidate
	return best


static func _scatter_cloud_once(rng: RandomNumberGenerator, grid_n: int,
		room_min: int, room_max: int, target_count: int) -> Array:
	var cloud: Array = []
	var centre := Vector2(grid_n * 0.5, grid_n * 0.5)
	var radius := minf(grid_n * 0.31, sqrt(float(target_count)) *
		(float(room_min) * 0.72 + 1.5))
	var split_a := room_min + maxi(0, (room_max - room_min) / 3)
	var split_b := room_min + maxi(1, ((room_max - room_min) * 2) / 3)
	for i in target_count:
		var roll := rng.randf()
		var lo := room_min
		var hi := maxi(room_min, split_a)
		var archetype := "small"
		# Guarantee two landmark-scale chambers when the room budget permits.
		if i < mini(2, target_count):
			roll = 1.0
		if roll >= 0.85:
			lo = mini(room_max, split_b)
			hi = room_max
			archetype = "large"
		elif roll >= 0.45:
			lo = mini(room_max, split_a)
			hi = maxi(lo, split_b)
			archetype = "medium"
		var w := rng.randi_range(lo, hi)
		var h := rng.randi_range(lo, hi)
		var angle := rng.randf_range(0.0, TAU)
		var radial := radius * sqrt(rng.randf())
		var p := centre + Vector2(cos(angle), sin(angle)) * radial
		cloud.append({"cx": p.x, "cy": p.y, "w": w, "h": h,
			"archetype": archetype})

	for _pass in SEPARATION_PASSES:
		var moved := false
		for i in cloud.size():
			for j in range(i + 1, cloud.size()):
				var a: Dictionary = cloud[i]
				var b: Dictionary = cloud[j]
				var dx := float(b.cx) - float(a.cx)
				var dy := float(b.cy) - float(a.cy)
				var overlap_x := (float(a.w + b.w) * 0.5 + ROOM_PADDING) - absf(dx)
				var overlap_y := (float(a.h + b.h) * 0.5 + ROOM_PADDING) - absf(dy)
				if overlap_x <= 0.0 or overlap_y <= 0.0:
					continue
				moved = true
				if overlap_x < overlap_y:
					var sx := 1.0 if dx >= 0.0 else -1.0
					if absf(dx) < 0.001:
						sx = 1.0 if ((i + j + _pass) % 2 == 0) else -1.0
					var push_x := overlap_x * 0.51
					a.cx = float(a.cx) - sx * push_x
					b.cx = float(b.cx) + sx * push_x
				else:
					var sy := 1.0 if dy >= 0.0 else -1.0
					if absf(dy) < 0.001:
						sy = 1.0 if ((i + j + _pass) % 2 == 0) else -1.0
					var push_y := overlap_y * 0.51
					a.cy = float(a.cy) - sy * push_y
					b.cy = float(b.cy) + sy * push_y
				cloud[i] = a
				cloud[j] = b
		for i in cloud.size():
			var r: Dictionary = cloud[i]
			var half_w := float(r.w) * 0.5
			var half_h := float(r.h) * 0.5
			r.cx = clampf(float(r.cx), 1.0 + half_w,
				float(grid_n - 2) - half_w)
			r.cy = clampf(float(r.cy), 1.0 + half_h,
				float(grid_n - 2) - half_h)
			cloud[i] = r
		if not moved:
			break

	var rooms: Array = []
	for cloud_v in cloud:
		var c: Dictionary = cloud_v
		var room := {
			"x": clampi(roundi(float(c.cx) - float(c.w) * 0.5), 1,
				grid_n - int(c.w) - 2),
			"y": clampi(roundi(float(c.cy) - float(c.h) * 0.5), 1,
				grid_n - int(c.h) - 2),
			"w": int(c.w), "h": int(c.h),
			"archetype": String(c.archetype),
		}
		var overlaps := false
		for placed_v in rooms:
			if _rooms_overlap(room, placed_v, 1):
				overlaps = true
				break
		if not overlaps:
			rooms.append(room)
	return rooms


static func _rooms_overlap(a: Dictionary, b: Dictionary, padding: int = 0) -> bool:
	return int(a.x) < int(b.x) + int(b.w) + padding \
		and int(a.x) + int(a.w) + padding > int(b.x) \
		and int(a.y) < int(b.y) + int(b.h) + padding \
		and int(a.y) + int(a.h) + padding > int(b.y)


static func _fallback_room_chain(grid_n: int, room_min: int) -> Array:
	var size := clampi(room_min, 5, maxi(5, (grid_n - 8) / 3))
	var y_top := 2
	var y_bottom := grid_n - size - 2
	return [
		{"x": 2, "y": y_top, "w": size, "h": size, "archetype": "medium"},
		{"x": grid_n - size - 2, "y": y_top, "w": size, "h": size,
			"archetype": "large"},
		{"x": int((grid_n - size) * 0.5), "y": y_bottom, "w": size,
			"h": size, "archetype": "large"},
	]

# ---- Delaunay: unique edge set from triangle triples ----
static func _delaunay_edges(centers: PackedVector2Array) -> Array:
	var edges: Array = []
	if centers.size() < 3:
		# Degenerate — nearest-neighbour chain so we never die.
		for i in range(1, centers.size()):
			edges.append([i - 1, i])
		return edges
	var tris := Geometry2D.triangulate_delaunay(centers)
	if tris.is_empty():
		for i in range(1, centers.size()):
			edges.append([i - 1, i])
		return edges
	var seen := {}
	var idx := 0
	while idx < tris.size():
		var a: int = tris[idx]
		var b: int = tris[idx + 1]
		var c: int = tris[idx + 2]
		idx += 3
		for pair in [[a, b], [b, c], [c, a]]:
			var lo: int = min(pair[0], pair[1])
			var hi: int = max(pair[0], pair[1])
			var key := lo * 100000 + hi
			if not seen.has(key):
				seen[key] = true
				edges.append([lo, hi])
	return edges

# ---- Kruskal MST over the Delaunay edges ----
static func _mst(edges: Array, centers: PackedVector2Array, count: int) -> Array:
	var weighted: Array = []
	for e in edges:
		var d := centers[e[0]].distance_to(centers[e[1]])
		weighted.append({ "e": e, "w": d })
	weighted.sort_custom(func(p, q): return p.w < q.w)

	var parent: Array = []
	for i in count:
		parent.append(i)

	var mst: Array = []
	for item in weighted:
		var e: Array = item.e
		var ra := _find(parent, e[0])
		var rb := _find(parent, e[1])
		if ra != rb:
			parent[ra] = rb
			mst.append(e)
	return mst

static func _find(parent: Array, i: int) -> int:
	var cur := i
	while parent[cur] != cur:
		cur = parent[cur]
	return cur

# ---- loop edges: ~loop_fraction of the non-MST Delaunay edges ----
static func _loop_edges(all_edges: Array, mst_edges: Array,
		rng: RandomNumberGenerator,
		loop_fraction: float = LOOP_EDGE_FRACTION) -> Array:
	var mst_keys := {}
	for e in mst_edges:
		mst_keys[e[0] * 100000 + e[1]] = true
	var extras: Array = []
	for e in all_edges:
		if not mst_keys.has(e[0] * 100000 + e[1]):
			extras.append(e)
	# Fisher-Yates shuffle, take a fraction.
	for i in range(extras.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = extras[i]
		extras[i] = extras[j]
		extras[j] = tmp
	var take := int(floor(extras.size() * loop_fraction))
	return extras.slice(0, take)

# ---- room graph helpers ----
static func _adjacency(count: int, edges: Array) -> Array:
	var adj: Array = []
	for _i in count:
		adj.append([])
	for e in edges:
		adj[e[0]].append(e[1])
		adj[e[1]].append(e[0])
	return adj

# BFS hop-depth of every room from a start room (spec 25 Phase 5 — pacing).
static func _bfs_depths(adj: Array, from_idx: int, count: int) -> Array:
	var depth: Array = []
	depth.resize(count)
	depth.fill(-1)
	depth[from_idx] = 0
	var queue := [from_idx]
	var head := 0
	while head < queue.size():
		var cur: int = queue[head]
		head += 1
		for nb in adj[cur]:
			if nb < count and depth[nb] < 0:
				depth[nb] = depth[cur] + 1
				queue.append(nb)
	for i in count:
		if depth[i] < 0:
			depth[i] = 0
	return depth

static func _farthest_room(adj: Array, from_idx: int) -> int:
	var dist := {}
	dist[from_idx] = 0
	var queue := [from_idx]
	var head := 0
	var farthest := from_idx
	var far_d := 0
	while head < queue.size():
		var cur: int = queue[head]
		head += 1
		for nb in adj[cur]:
			if dist.has(nb):
				continue
			dist[nb] = dist[cur] + 1
			if dist[nb] > far_d:
				far_d = dist[nb]
				farthest = nb
			queue.append(nb)
	return farthest


static func _largest_room(rooms: Array) -> int:
	var best_idx := 0
	var best_area := -1
	for i in rooms.size():
		var room: Dictionary = rooms[i]
		var area := int(room.w) * int(room.h)
		if area > best_area:
			best_area = area
			best_idx = i
	return best_idx


# Pick the deepest leaf from the boss so the main route spans the graph. Loops
# can consume every leaf in very small layouts, hence the farthest-node fallback.
static func _farthest_leaf(adj: Array, boss_idx: int) -> int:
	var depths := _bfs_depths(adj, boss_idx, adj.size())
	var best_idx := -1
	var best_depth := -1
	for i in adj.size():
		if i == boss_idx or adj[i].size() != 1:
			continue
		if int(depths[i]) > best_depth:
			best_idx = i
			best_depth = int(depths[i])
	return best_idx if best_idx >= 0 else _farthest_room(adj, boss_idx)


# Preserve the long-standing layout contract that entrance room id is zero.
# Graph indices are remapped with the room array, keeping every downstream
# consumer (co-op, saves, story clues, gathers) ignorant of generation order.
static func _remap_entry_first(rooms: Array, edges: Array, entry_idx: int,
		boss_idx: int) -> Dictionary:
	if entry_idx == 0:
		return {"rooms": rooms, "edges": edges, "boss_idx": boss_idx}
	var order: Array = [entry_idx]
	for i in rooms.size():
		if i != entry_idx:
			order.append(i)
	var old_to_new := {}
	var remapped_rooms: Array = []
	for new_idx in order.size():
		var old_idx := int(order[new_idx])
		old_to_new[old_idx] = new_idx
		remapped_rooms.append(rooms[old_idx])
	var remapped_edges: Array = []
	for edge_v in edges:
		var edge: Array = edge_v
		remapped_edges.append([int(old_to_new[int(edge[0])]),
			int(old_to_new[int(edge[1])])])
	return {"rooms": remapped_rooms, "edges": remapped_edges,
		"boss_idx": int(old_to_new[boss_idx])}


static func _room_path(adj: Array, from_idx: int, to_idx: int) -> Array:
	var parent := {from_idx: -1}
	var queue := [from_idx]
	var head := 0
	while head < queue.size() and not parent.has(to_idx):
		var cur: int = queue[head]
		head += 1
		for nb_v in adj[cur]:
			var nb := int(nb_v)
			if parent.has(nb):
				continue
			parent[nb] = cur
			queue.append(nb)
	if not parent.has(to_idx):
		return [from_idx]
	var reversed: Array = []
	var cursor := to_idx
	while cursor >= 0:
		reversed.append(cursor)
		cursor = int(parent.get(cursor, -1))
	reversed.reverse()
	return reversed

# A corridor uses a straight overlap-aligned cut when room projections permit;
# otherwise it uses a seeded L bend. Width is semantic rather than global.
static func _carve_corridor(grid: Array, a: Dictionary, b: Dictionary,
		width: int, rng: RandomNumberGenerator) -> void:
	var ax := int(a.x + a.w / 2.0)
	var ay := int(a.y + a.h / 2.0)
	var bx := int(b.x + b.w / 2.0)
	var by := int(b.y + b.h / 2.0)
	var overlap_y0 := maxi(int(a.y) + 1, int(b.y) + 1)
	var overlap_y1 := mini(int(a.y + a.h) - 2, int(b.y + b.h) - 2)
	if overlap_y0 <= overlap_y1:
		var cut_y := clampi(roundi((ay + by) * 0.5), overlap_y0, overlap_y1)
		_carve_h(grid, ax, bx, cut_y, width)
		return
	var overlap_x0 := maxi(int(a.x) + 1, int(b.x) + 1)
	var overlap_x1 := mini(int(a.x + a.w) - 2, int(b.x + b.w) - 2)
	if overlap_x0 <= overlap_x1:
		var cut_x := clampi(roundi((ax + bx) * 0.5), overlap_x0, overlap_x1)
		_carve_v(grid, ay, by, cut_x, width)
		return
	if rng.randf() < 0.5:
		_carve_h(grid, ax, bx, ay, width)
		_carve_v(grid, ay, by, bx, width)
	else:
		_carve_v(grid, ay, by, ax, width)
		_carve_h(grid, ax, bx, by, width)


static func _corridor_offsets(width: int) -> Array:
	if width <= 1:
		return [0]
	if width == 2:
		return [0, 1]
	return [-1, 0, 1]


static func _carve_h(grid: Array, x0: int, x1: int, y: int,
		width: int = 3) -> void:
	for x in range(min(x0, x1), max(x0, x1) + 1):
		for dy in _corridor_offsets(width):
			_carve_tile(grid, x, y + dy)

static func _carve_v(grid: Array, y0: int, y1: int, x: int,
		width: int = 3) -> void:
	for y in range(min(y0, y1), max(y0, y1) + 1):
		for dx in _corridor_offsets(width):
			_carve_tile(grid, x + dx, y)


static func _edge_key(a: int, b: int) -> String:
	return "%d:%d" % [mini(a, b), maxi(a, b)]


static func _path_edge_keys(path: Array) -> Dictionary:
	var keys := {}
	for i in range(1, path.size()):
		keys[_edge_key(int(path[i - 1]), int(path[i]))] = true
	return keys


static func _edge_touches_role(rooms: Array, edge: Array, role: String) -> bool:
	return String((rooms[int(edge[0])] as Dictionary).get("role", "")) == role \
		or String((rooms[int(edge[1])] as Dictionary).get("role", "")) == role

# Set a floor tile, keeping the 1-tile outer border as wall.
static func _carve_tile(grid: Array, x: int, y: int) -> void:
	if y >= 1 and y < grid.size() - 1 and x >= 1 and x < grid[0].size() - 1:
		grid[y][x] = "floor"

# ---- Phase 3 (spec 25): authored setpieces ----
# Tag the largest eligible room (still "combat", ≥8×8) as a setpiece.
# Spec 29 — skip rooms already promoted to a role contract (rest/treasure/shrine);
# we don't want a setpiece to clobber a typed-room interactable.
static func _pick_setpiece(rooms: Array, rng: RandomNumberGenerator,
		scope: String = "crypt") -> void:
	# Use the scope-specific pool; fall back to crypt's pool for unknown scopes.
	var pool: Array = SCOPE_SETPIECES.get(scope, SCOPE_SETPIECES["crypt"])
	if pool.is_empty():
		return
	var best := -1
	var best_area := 0
	for i in rooms.size():
		var r: Dictionary = rooms[i]
		var role: String = r.get("role", "")
		if role != "combat":
			continue
		var min_edge := 7 if scope == "mire" else 8
		if int(r.w) < min_edge or int(r.h) < min_edge:
			continue
		var area := int(r.w) * int(r.h)
		if area > best_area:
			best_area = area
			best = i
	if best >= 0:
		rooms[best]["role"] = "setpiece"
		rooms[best]["setpiece"] = pool[rng.randi_range(0, pool.size() - 1)]
		if scope == "mire":
			rooms[best]["optional_discovery"] = "wisp_pool"

# Stamp an ASCII template into a room — '#' interior wall, '.' floor,
# decor letters → floor + a decor entry. Template is centred in the room.
static func _stamp_setpiece(grid: Array, room: Dictionary, decor: Array) -> void:
	var lines := _load_template(String(room.get("setpiece", "")))
	if lines.is_empty():
		return
	var th: int = lines.size()
	var tw: int = String(lines[0]).length()
	var ax: int = int(room.x) + (int(room.w) - tw) / 2
	var ay: int = int(room.y) + (int(room.h) - th) / 2
	for j in th:
		var line: String = lines[j]
		for i in mini(tw, line.length()):
			var gx := ax + i
			var gy := ay + j
			if gy < 1 or gy >= grid.size() - 1 or gx < 1 or gx >= grid[0].size() - 1:
				continue
			var ch := line[i]
			if ch == "#":
				grid[gy][gx] = "wall"
			elif ch == ".":
				grid[gy][gx] = "floor"
			elif SETPIECE_DECOR.has(ch):
				grid[gy][gx] = "floor"
				# Spec 73 — the First Road larder is still an authored discovery,
				# but its old pottery ring remaps to large forest boulders.  Keep
				# those supports below landmark scale and out of every approach.
				var d := {"kind": SETPIECE_DECOR[ch], "x": gx, "y": gy}
				if _is_first_hollow_room(room):
					d["visual_scale"] = 0.62
					d["setpiece_support"] = true
					if _inside_room_approach(room, gx, gy, grid):
						# Preserve the occupied-cell contract consumed by later enemy
						# placement while omitting only the obstructive presentation.
						d["presentation_hidden"] = true
				if String(room.get("setpiece", "")) == "wisp_pool" and ch == "a":
					d["interact_role"] = "shrine"
					d["room_id"] = int(room.get("id", -1))
					d["biome_signature"] = true
				decor.append(d)

static func _load_template(name: String) -> Array:
	if name == "":
		return []
	var path := "res://data/rooms/" + name + ".txt"
	if not FileAccess.file_exists(path):
		return []
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return []
	var lines: Array = []
	while not f.eof_reached():
		var l := f.get_line()
		if l.strip_edges() != "":
			lines.append(l)
	f.close()
	return lines

# ---- Phase 2 (spec 25/65): varied room shapes and authored clearings ----
static func _assign_archetypes(rooms: Array, rng: RandomNumberGenerator,
		scope: String) -> void:
	if scope != "snug":
		_assign_shapes(rooms, rng)
		return
	for i in rooms.size():
		var r: Dictionary = rooms[i]
		var role := String(r.get("role", "default"))
		var pool: Array = FIRST_HOLLOW_ARCHETYPE_POOLS.get(role,
			FIRST_HOLLOW_ARCHETYPE_POOLS["default"])
		var archetype := String(pool[rng.randi_range(0, pool.size() - 1)])
		r["archetype"] = archetype
		r["shape"] = String(FIRST_HOLLOW_ARCHETYPE_SHAPES[archetype])
		# Typed reward rooms keep their established focal interaction contract.
		# Arrival and ordinary fights can safely expose the archetype wholesale.
		if role == "entrance" or role == "combat":
			r["theme"] = String(FIRST_HOLLOW_ARCHETYPE_THEMES.get(
				archetype, r.get("theme", "")))
		r["footprint_variant"] = rng.randi_range(0, 3)
		var cx := float(r.x) + float(r.w) * 0.5
		var cy := float(r.y) + float(r.h) * 0.5
		# The aperture is intentionally smaller than the room so perimeter
		# dressing still has authored territory.  It protects roughly a 5x5
		# combat stage in ordinary First Road rooms.
		r["protected_aperture"] = {
			"cx": cx, "cy": cy,
			"rx": minf(3.5, maxf(2.25, float(r.w) * 0.38)),
			"ry": minf(3.5, maxf(2.25, float(r.h) * 0.38)),
		}


static func _assign_shapes(rooms: Array, rng: RandomNumberGenerator) -> void:
	for i in rooms.size():
		var r: Dictionary = rooms[i]
		if i == 0:
			r["shape"] = "rect"            # entrance stays clean
			continue
		var roll := rng.randf()
		if roll < 0.25:
			r["shape"] = "circle"
		elif roll < 0.45:
			r["shape"] = "irregular"
		else:
			r["shape"] = "rect"

static func _carve_room(grid: Array, r: Dictionary, rng: RandomNumberGenerator) -> void:
	var rx := int(r.x)
	var ry := int(r.y)
	var rw := int(r.w)
	var rh := int(r.h)
	match r.get("shape", "rect"):
		"oval":
			var cx := rx + rw / 2.0
			var cy := ry + rh / 2.0
			var rad_x := maxf(1.0, rw / 2.0 - 0.35)
			var rad_y := maxf(1.0, rh / 2.0 - 0.35)
			for yy in range(ry, ry + rh):
				for xx in range(rx, rx + rw):
					var nx := (xx + 0.5 - cx) / rad_x
					var ny := (yy + 0.5 - cy) / rad_y
					if nx * nx + ny * ny <= 1.0:
						grid[yy][xx] = "floor"
		"rounded":
			var chamfer := 1 + int(r.get("footprint_variant", 0)) % 2
			for yy in range(ry, ry + rh):
				for xx in range(rx, rx + rw):
					var lx := xx - rx
					var ly := yy - ry
					var edge_x := mini(lx, rw - 1 - lx)
					var edge_y := mini(ly, rh - 1 - ly)
					if edge_x + edge_y >= chamfer:
						grid[yy][xx] = "floor"
		"circle":
			var cx := rx + rw / 2.0
			var cy := ry + rh / 2.0
			var rad: float = minf(rw, rh) / 2.0 - 0.5
			for yy in range(ry, ry + rh):
				for xx in range(rx, rx + rw):
					if Vector2(xx + 0.5 - cx, yy + 0.5 - cy).length() <= rad:
						grid[yy][xx] = "floor"
		"irregular":
			for yy in range(ry, ry + rh):
				for xx in range(rx, rx + rw):
					grid[yy][xx] = "floor"
			# Bite 1–2 corners back to wall for an uneven footprint.
			var corners := [[rx, ry, 1, 1], [rx + rw - 1, ry, -1, 1],
				[rx, ry + rh - 1, 1, -1], [rx + rw - 1, ry + rh - 1, -1, -1]]
			_shuffle(corners, rng)
			for b in range(rng.randi_range(1, 2)):
				var c: Array = corners[b]
				for i in range(rng.randi_range(2, 3)):
					for j in range(rng.randi_range(2, 3)):
						var tx: int = c[0] + i * int(c[2])
						var ty: int = c[1] + j * int(c[3])
						if ty >= 0 and ty < grid.size() and tx >= 0 and tx < grid[0].size():
							grid[ty][tx] = "wall"
		_:
			for yy in range(ry, ry + rh):
				for xx in range(rx, rx + rw):
					grid[yy][xx] = "floor"


static func _capture_room_footprints(rooms: Array, grid: Array) -> void:
	for r_v in rooms:
		var r: Dictionary = r_v
		var cells: Array = []
		for yy in range(int(r.y), int(r.y) + int(r.h)):
			for xx in range(int(r.x), int(r.x) + int(r.w)):
				if yy >= 0 and yy < grid.size() and xx >= 0 and xx < grid[0].size() \
						and String(grid[yy][xx]) == "floor":
					cells.append({"x": xx, "y": yy})
		r["footprint_cells"] = cells


static func _boundary_cells(grid: Array) -> Array:
	var cells: Array = []
	for y in grid.size():
		for x in grid[y].size():
			if String(grid[y][x]) != "wall":
				continue
			var adjacent := false
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					if dx == 0 and dy == 0:
						continue
					var nx: int = int(x) + int(dx)
					var ny: int = int(y) + int(dy)
					if ny >= 0 and ny < grid.size() and nx >= 0 and nx < grid[ny].size() \
							and String(grid[ny][nx]) == "floor":
						adjacent = true
						break
				if adjacent:
					break
			if adjacent:
				cells.append({"x": x, "y": y})
	return cells


# Spec 66 — bind each visible boundary cell to the room footprint it actually
# touches, then select one archetype-owned landmark per room.  Cell hashing is
# independent of iteration order, so later removal of an unrelated wall cannot
# shuffle the rest of the edge.
static func _first_hollow_perimeter_dressing(rooms: Array,
		boundary_cells: Array, grid: Array, seed: int, scope: String) -> Array:
	if scope != "snug":
		return []
	var footprint_owners := {}
	for room_v in rooms:
		var room: Dictionary = room_v
		var room_id := int(room.get("id", -1))
		for cell_v in room.get("footprint_cells", []):
			var cell: Dictionary = cell_v
			var key := "%d:%d" % [int(cell.x), int(cell.y)]
			if not footprint_owners.has(key):
				footprint_owners[key] = []
			(footprint_owners[key] as Array).append(room_id)

	var manifest: Array = []
	var indices_by_room := {}
	for cell_v in boundary_cells:
		var cell: Dictionary = cell_v
		var x := int(cell.x)
		var y := int(cell.y)
		var owner_id := _first_hollow_boundary_owner(
			x, y, rooms, footprint_owners)
		var archetype := ""
		var role := "corridor"
		if owner_id >= 0 and owner_id < rooms.size():
			var owner: Dictionary = rooms[owner_id]
			archetype = String(owner.get("archetype", ""))
			role = String(owner.get("role", "default"))
		var pool: Array = FIRST_HOLLOW_EDGE_PROFILES.get(archetype,
			FIRST_HOLLOW_EDGE_PROFILES["default"])
		var cell_hash := _first_hollow_cell_hash(seed, x, y, owner_id)
		var inward := _first_hollow_inward_direction(x, y, grid)
		# Spec 74 — a real room connection gets a low, concave visual shoulder.
		# The grid cell remains the same colliding wall; only its authored edge
		# profile changes, so procedural connectivity and physical truth stay put.
		var passage := _first_hollow_passage_shoulder(x, y, rooms, grid)
		var row := {
			"x": x, "y": y,
			"room_id": owner_id,
			"archetype": archetype,
			"role": role,
			"profile": "passage_bank" if passage \
				else String(pool[cell_hash % pool.size()]),
			"passage": passage,
			"landmark": false,
			"variant": (cell_hash / 17) % 4,
			"inward_x": int(inward.x),
			"inward_y": int(inward.y),
		}
		manifest.append(row)
		# Landmarks identify rooms; placing one on a doorway shoulder would turn
		# the new opening back into an obstruction.
		if owner_id >= 0 and not passage:
			if not indices_by_room.has(owner_id):
				indices_by_room[owner_id] = []
			(indices_by_room[owner_id] as Array).append(manifest.size() - 1)

	for room_v in rooms:
		var room: Dictionary = room_v
		var room_id := int(room.get("id", -1))
		var candidates: Array = indices_by_room.get(room_id, [])
		if candidates.is_empty():
			continue
		candidates.sort_custom(func(a_v, b_v) -> bool:
			var a: Dictionary = manifest[int(a_v)]
			var b: Dictionary = manifest[int(b_v)]
			return _first_hollow_cell_hash(seed ^ 0x4C495645,
				int(a.x), int(a.y), room_id) < _first_hollow_cell_hash(
				seed ^ 0x4C495645, int(b.x), int(b.y), room_id))
		var landmark_idx := int(candidates[0])
		var landmark: Dictionary = manifest[landmark_idx]
		var archetype := String(room.get("archetype", ""))
		landmark["profile"] = String(FIRST_HOLLOW_LANDMARK_PROFILES.get(
			archetype, "old_oak"))
		landmark["landmark"] = true
		manifest[landmark_idx] = landmark
	return manifest


# A passage shoulder is a real boundary wall within two tiles of a room-edge
# floor cell that continues outside the room rectangle. The five-wide taper
# gives 1–3-wide generated corridors a readable concave frame without lowering
# unrelated perimeter runs or inventing a second source of connectivity truth.
static func _first_hollow_passage_shoulder(x: int, y: int,
		rooms: Array, grid: Array) -> bool:
	for room_v in rooms:
		var room: Dictionary = room_v
		var rx0 := int(room.x)
		var rx1 := int(room.x) + int(room.w) - 1
		var ry0 := int(room.y)
		var ry1 := int(room.y) + int(room.h) - 1
		for mx in range(rx0, rx1 + 1):
			for my in [ry0, ry1]:
				if _is_corridor_mouth(room, mx, my, grid) \
						and maxi(absi(x - mx), absi(y - my)) <= 2:
					return true
		for my in range(ry0 + 1, ry1):
			for mx in [rx0, rx1]:
				if _is_corridor_mouth(room, mx, my, grid) \
						and maxi(absi(x - mx), absi(y - my)) <= 2:
					return true
	return false


static func _first_hollow_inward_direction(x: int, y: int,
		grid: Array) -> Vector2i:
	var sum := Vector2i.ZERO
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			var nx := x + dx
			var ny := y + dy
			if ny >= 0 and ny < grid.size() and nx >= 0 and nx < grid[ny].size() \
					and String(grid[ny][nx]) == "floor":
				sum += Vector2i(dx, dy)
	if sum == Vector2i.ZERO:
		return Vector2i(0, 1)
	return Vector2i(signi(sum.x), signi(sum.y))


static func _first_hollow_boundary_owner(x: int, y: int, rooms: Array,
		footprint_owners: Dictionary) -> int:
	var owners := {}
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			var key := "%d:%d" % [x + dx, y + dy]
			for owner_v in footprint_owners.get(key, []):
				owners[int(owner_v)] = true
	var best_id := -1
	var best_distance := INF
	for owner_v in owners:
		var owner_id := int(owner_v)
		if owner_id < 0 or owner_id >= rooms.size():
			continue
		var room: Dictionary = rooms[owner_id]
		var dx := float(x) + 0.5 - (float(room.x) + float(room.w) * 0.5)
		var dy := float(y) + 0.5 - (float(room.y) + float(room.h) * 0.5)
		var distance := dx * dx + dy * dy
		if distance < best_distance or (is_equal_approx(distance, best_distance) \
				and owner_id < best_id):
			best_distance = distance
			best_id = owner_id
	return best_id


static func _first_hollow_cell_hash(seed: int, x: int, y: int,
		room_id: int) -> int:
	return int((seed ^ (x * 73856093) ^ (y * 19349663) \
		^ ((room_id + 2) * 83492791)) & 0x7FFFFFFF)

# ---- Phase 1 (spec 25): room roles, themes, themed dressing ----
# Spec 29 — every dungeon gets entrance + boss + at least MIN_COMBAT_ROOMS
# combat rooms (so there's always a real fight), THEN rest > treasure > shrine
# in priority order if room count permits. Small dungeons drop the lowest-
# priority typed rooms first rather than starving combat.
const MIN_COMBAT_ROOMS := 2

static func _assign_rooms(rooms: Array, rng: RandomNumberGenerator,
		boss_idx: int, adj: Array, scope: String = "crypt",
		required_roles: Array = []) -> bool:
	var stheme: Dictionary = SCOPE_THEMES.get(scope, SCOPE_THEMES["crypt"])
	var boss_theme: String = String(stheme.get("boss", "tomb_hall"))
	var ctlist: Array = stheme.get("combat", COMBAT_THEMES)
	# 1) Fixed roles: entrance + boss.
	rooms[0]["role"] = "entrance"
	rooms[0]["theme"] = "antechamber"
	if boss_idx != 0:
		rooms[boss_idx]["role"] = "boss"
		rooms[boss_idx]["theme"] = boss_theme
	# 2) Hard contracts reserve their role before the ordinary pacing budget.
	# This may consume a combat slot in a deliberately tiny layout; that is the
	# honest outcome for an explicitly authored terminal Hearth.
	for role_v in required_roles:
		var required_role := String(role_v)
		if required_role != "rest":
			return false
		var required_idx := _pick_rest_room(rooms, boss_idx, adj)
		if required_idx < 0:
			return false
		rooms[required_idx]["role"] = "rest"
		rooms[required_idx]["theme"] = "hearthroom"
	# 3) Budget. After entrance + boss are reserved, we can spend the rest
	#    on typed-room roles, but always keep MIN_COMBAT_ROOMS in reserve.
	var fixed_count: int = 1 + (1 if boss_idx != 0 else 0) + required_roles.size()
	var slots_left: int = max(0, rooms.size() - fixed_count - MIN_COMBAT_ROOMS)
	# 4) Rest room (priority 1) — prefer one adjacent to the boss on the
	#    graph (Hades pacing: the last room before the boss is heal+save).
	if slots_left > 0 and not required_roles.has("rest"):
		var rest_idx := _pick_rest_room(rooms, boss_idx, adj)
		if rest_idx >= 0:
			rooms[rest_idx]["role"] = "rest"
			rooms[rest_idx]["theme"] = "hearthroom"
			slots_left -= 1
	# 5) Treasure room (priority 2) — deepest optional leaf first. Treasure
	# should reward leaving the critical road, not appear in the first free room.
	if slots_left > 0:
		var treasure_idx := -1
		var treasure_score := -100000
		for i in rooms.size():
			if rooms[i].has("role"):
				continue
			var is_leaf: bool = i < adj.size() and adj[i].size() <= 1
			var off_critical: bool = not bool(rooms[i].get("critical", false))
			var score := int(rooms[i].get("depth", 0)) * 10 \
				+ (100 if is_leaf else 0) + (50 if off_critical else 0)
			if score > treasure_score:
				treasure_score = score
				treasure_idx = i
		if treasure_idx >= 0:
			rooms[treasure_idx]["role"] = "treasure"
			rooms[treasure_idx]["theme"] = "vault"
			slots_left -= 1
	# 6) Shrine room (priority 3) — favor an off-route, mid-depth chamber.
	if slots_left > 0:
		var shrine_idx := -1
		var shrine_score := -100000.0
		for i in rooms.size():
			if rooms[i].has("role"):
				continue
			var midpoint_fit := 1.0 - absf(float(rooms[i].get("difficulty", 0.0)) - 0.5)
			var off_route_bonus := 2.0 if not bool(rooms[i].get("critical", false)) else 0.0
			var score := midpoint_fit + off_route_bonus + rng.randf_range(0.0, 0.01)
			if score > shrine_score:
				shrine_score = score
				shrine_idx = i
		if shrine_idx >= 0:
			rooms[shrine_idx]["role"] = "shrine"
			rooms[shrine_idx]["theme"] = "shrine"
			slots_left -= 1
	# 7) Everyone else: combat with a random scope-appropriate combat theme.
	for i in rooms.size():
		var r: Dictionary = rooms[i]
		if not r.has("role"):
			r["role"] = "combat"
			r["theme"] = ctlist[rng.randi_range(0, ctlist.size() - 1)]
	return true

static func _pick_rest_room(rooms: Array, boss_idx: int, adj: Array) -> int:
	if boss_idx >= 0 and boss_idx < adj.size():
		for nb in adj[boss_idx]:
			if int(nb) != 0 and int(nb) != boss_idx and not rooms[int(nb)].has("role"):
				return int(nb)
	var depths: Array = _bfs_depths(adj, 0, rooms.size())
	var best_idx := -1
	var best_depth := -1
	for i in rooms.size():
		if i == 0 or i == boss_idx or rooms[i].has("role"):
			continue
		if int(depths[i]) > best_depth:
			best_depth = int(depths[i])
			best_idx = i
	return best_idx

# Build the decor list by walking each room's theme — focal first (owns the
# centre cell), then satellites arrange around it (spec 28). Spec 29 — the
# focal decor of a treasure / shrine / rest room is tagged with `interact_role`
# so layout_loader can swap the static GLB for the matching interactable scene.
static func _dress_rooms(rooms: Array, grid: Array, entry: Dictionary,
		exit: Dictionary, rng: RandomNumberGenerator) -> Array:
	var decor: Array = []
	const INTERACT_ROLES := ["treasure", "shrine", "rest"]
	for r in rooms:
		var role: String = r.get("role", "")
		if role == "boss" or role == "setpiece":
			continue        # boss → layout_loader; setpiece → its template
		var theme: Dictionary = ROOM_THEMES.get(r.get("theme", ""), {})
		if theme.is_empty():
			continue
		# Spec 29 — per-room occupied set so satellites can't stamp on top of
		# the focal (or each other). Was the actual cause of the spec 28
		# T3 misses — focal placed correctly, satellite overlapped, the
		# overlap was visually ambiguous and broke T3's at-by-cell index.
		var occupied: Dictionary = {}
		var focal = theme.get("focal", null)
		if focal != null:
			# Spec 29 — only the focal carries the interact_role; satellites
			# stay static decor even in role-contract rooms.
			var ir := role if role in INTERACT_ROLES else ""
			_apply_rule(focal, r, grid, entry, exit, rng, decor, occupied, ir, true)
		for rule in theme.get("satellites", []):
			_apply_rule(rule, r, grid, entry, exit, rng, decor, occupied, "", false)
	return decor

static func _apply_rule(rule: Dictionary, r: Dictionary, grid: Array,
		entry: Dictionary, exit: Dictionary, rng: RandomNumberGenerator,
		decor: Array, occupied: Dictionary,
		interact_role: String = "", is_focal: bool = false) -> void:
	var n: int = rng.randi_range(int(rule.count[0]), int(rule.count[1]))
	var protect_approach := not is_focal \
		and String(r.get("theme", "")).begins_with("first_")
	var tiles: Array = _pattern_tiles(r, String(rule.pattern), n, grid, rng,
		false, occupied, protect_approach)
	# Spec 28 — never silently drop a focal (n≥1) just because every
	# preferred candidate happened to be filtered. Fall back to any free
	# in-room floor tile.
	if is_focal and tiles.is_empty() and n >= 1:
		tiles = _pattern_tiles(r, "scatter", 1, grid, rng, false, occupied)
	# Spec 29 — last-resort fallback: in long thin rooms wedged between two
	# corridors, EVERY floor tile is a corridor mouth and the previous
	# scatter still returns empty. Accept a near-mouth tile rather than
	# silently dropping the focal — chest/altar/hearth must always exist.
	if is_focal and tiles.is_empty() and n >= 1:
		tiles = _pattern_tiles(r, "scatter", 1, grid, rng, true, occupied)
	for t in tiles:
		if int(t.x) == int(entry.x) and int(t.y) == int(entry.y):
			continue
		if int(t.x) == int(exit.x) and int(t.y) == int(exit.y):
			continue
		var d := {"kind": String(rule.kind), "x": int(t.x), "y": int(t.y),
			"orient": String(t.get("orient", "center"))}
		# Saturation hierarchy — the room's focal prop stays full-saturation
		# (the eye's anchor); layout_loader desaturates the satellites.
		if is_focal:
			d["focal"] = true
		elif rule.has("visual_scale"):
			# Spec 72 — supporting forest props are authored below landmark
			# scale.  Keep this in generated composition data so the renderer
			# does not need to guess which instances are satellites.
			d["visual_scale"] = float(rule.visual_scale)
		# Spec 29 — flag this decor as the interactable focal for a typed room.
		# layout_loader will swap the static GLB for Chest/Shrine/Hearth.tscn.
		# Plus carry the room id so the shrine RNG can seed deterministically
		# from (dungeon seed + room id) per the spec's open-decision lean.
		if interact_role != "":
			d["interact_role"] = interact_role
			d["room_id"] = int(r.get("id", -1))
		occupied[int(t.x) * 10000 + int(t.y)] = true
		decor.append(d)

# Up to n in-room floor tiles, chosen by placement pattern.
# Spec 28 — bounds are the ACTUAL room edge tiles (decor sits flush against
# the wall, not 1-tile inboard), every candidate carries an `orient` cardinal
# telling layout_loader which way it faces (away from its wall, toward the
# room interior), and corridor-mouth tiles are filtered out so decor never
# blocks the only entry to a room.
static func _pattern_tiles(r: Dictionary, pattern: String, n: int,
		grid: Array, rng: RandomNumberGenerator,
		allow_corridor_mouths: bool = false,
		occupied: Dictionary = {},
		protect_approach: bool = false) -> Array:
	var ix0: int = int(r.x)
	var ix1: int = int(r.x) + int(r.w) - 1
	var iy0: int = int(r.y)
	var iy1: int = int(r.y) + int(r.h) - 1
	if ix1 < ix0 or iy1 < iy0:
		return []
	var cand: Array = []
	match pattern:
		"walls":
			for x in range(ix0, ix1 + 1):
				cand.append({"x": x, "y": iy0, "orient": "n"})    # north edge → faces south
				cand.append({"x": x, "y": iy1, "orient": "s"})    # south edge → faces north
			for y in range(iy0 + 1, iy1):
				cand.append({"x": ix0, "y": y, "orient": "w"})    # west edge  → faces east
				cand.append({"x": ix1, "y": y, "orient": "e"})    # east edge  → faces west
		"corners":
			cand = [
				{"x": ix0, "y": iy0, "orient": "center"},
				{"x": ix1, "y": iy0, "orient": "center"},
				{"x": ix0, "y": iy1, "orient": "center"},
				{"x": ix1, "y": iy1, "orient": "center"},
			]
		"center":
			# Spec 28 — widened to a 3×3 cluster around the centre so the
			# focal still lands even when the centre cell is a corridor
			# mouth or otherwise filtered.
			var cx := (ix0 + ix1) / 2
			var cy := (iy0 + iy1) / 2
			for dy in [0, -1, 1]:
				for dx in [0, -1, 1]:
					cand.append({"x": cx + dx, "y": cy + dy, "orient": "center"})
		"cluster":
			var bx := rng.randi_range(ix0, ix1)
			var by := rng.randi_range(iy0, iy1)
			for dx in range(-2, 3):
				for dy in range(-2, 3):
					cand.append({"x": bx + dx, "y": by + dy, "orient": "center"})
		_:                                 # scatter
			for x in range(ix0, ix1 + 1):
				for y in range(iy0, iy1 + 1):
					cand.append({"x": x, "y": y, "orient": "center"})
	_shuffle(cand, rng)
	var seen := {}
	var out: Array = []
	for c in cand:
		var cx: int = int(c.x)
		var cy: int = int(c.y)
		if cx < ix0 or cx > ix1 or cy < iy0 or cy > iy1:
			continue
		if String(grid[cy][cx]) != "floor":
			continue
		# Spec 65 — First Road combat dressing belongs to the perimeter.  Keep
		# its central movement/aiming stage clear regardless of theme pattern.
		if String(r.get("role", "")) == "combat" \
				and _inside_protected_aperture(r, cx, cy):
			continue
		# Spec 28 — never sit on a tile whose 4-neighbour is floor OUTSIDE the
		# room (= a corridor mouth). Decor there blocks the room's entry.
		# Spec 29 — last-resort fallback can opt out (long thin rooms where
		# every candidate is a corridor mouth; better a focal that pinches
		# the path than no focal at all).
		if not allow_corridor_mouths and _is_corridor_mouth(r, cx, cy, grid):
			continue
		# Spec 72 — First Road satellites leave a three-wide, two-deep landing
		# inside every room entrance.  Two-tile-wide source meshes can no longer
		# create a visual or physical barricade immediately beyond a mouth.
		if protect_approach and _inside_room_approach(r, cx, cy, grid):
			continue
		var key: int = cx * 10000 + cy
		if seen.has(key) or occupied.has(key):
			continue
		seen[key] = true
		out.append(c)
		if out.size() >= n:
			break
	return out


static func _inside_protected_aperture(r: Dictionary, x: int, y: int) -> bool:
	var aperture = r.get("protected_aperture", null)
	if not aperture is Dictionary or (aperture as Dictionary).is_empty():
		return false
	var a := aperture as Dictionary
	var rx := maxf(0.01, float(a.get("rx", 0.0)))
	var ry := maxf(0.01, float(a.get("ry", 0.0)))
	var nx := (float(x) + 0.5 - float(a.get("cx", 0.0))) / rx
	var ny := (float(y) + 0.5 - float(a.get("cy", 0.0))) / ry
	return nx * nx + ny * ny <= 1.0

static func _is_corridor_mouth(r: Dictionary, x: int, y: int, grid: Array) -> bool:
	var rx0: int = int(r.x)
	var rx1: int = int(r.x) + int(r.w) - 1
	var ry0: int = int(r.y)
	var ry1: int = int(r.y) + int(r.h) - 1
	for d in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
		var nx: int = x + d.x
		var ny: int = y + d.y
		if nx < rx0 or nx > rx1 or ny < ry0 or ny > ry1:
			if ny >= 0 and ny < grid.size() and nx >= 0 and nx < grid[0].size():
				if String(grid[ny][nx]) == "floor":
					return true
	return false


# A mouth plus the first in-room row, widened one tile to either side.  This is
# deliberately directional rather than a radial exclusion so compact rooms
# retain useful perimeter dressing away from their actual travel lane.
static func _inside_room_approach(r: Dictionary, x: int, y: int, grid: Array) -> bool:
	var rx0: int = int(r.x)
	var rx1: int = int(r.x) + int(r.w) - 1
	var ry0: int = int(r.y)
	var ry1: int = int(r.y) + int(r.h) - 1
	for mx in range(rx0, rx1 + 1):
		if _is_corridor_mouth(r, mx, ry0, grid) \
				and y <= ry0 + 1 and absi(x - mx) <= 1:
			return true
		if _is_corridor_mouth(r, mx, ry1, grid) \
				and y >= ry1 - 1 and absi(x - mx) <= 1:
			return true
	for my in range(ry0, ry1 + 1):
		if _is_corridor_mouth(r, rx0, my, grid) \
				and x <= rx0 + 1 and absi(y - my) <= 1:
			return true
		if _is_corridor_mouth(r, rx1, my, grid) \
				and x >= rx1 - 1 and absi(y - my) <= 1:
			return true
	return false


static func _is_first_hollow_room(r: Dictionary) -> bool:
	return FIRST_HOLLOW_ARCHETYPE_SHAPES.has(String(r.get("archetype", "")))

static func _shuffle(arr: Array, rng: RandomNumberGenerator) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp
