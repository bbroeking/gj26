class_name DungeonGen
extends RefCounted

const DungeonScoreScript = preload("res://scripts/dungeon_score.gd")
const GatherDefs = preload("res://data/gather.gd")

# Spec 08 — quality procgen.
# Rooms-and-corridors via the "TinyKeep" pipeline:
#   place rooms → Delaunay triangulation of centers → MST → re-add ~15%
#   of edges for loops → carve corridors along the final edge set.
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
const ROOM_MIN := 8
const ROOM_MAX := 14
const ROOM_TRIES := 90
const CORRIDOR_HALF := 1              # corridors carve 3 tiles wide (centre ±1)
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
}
const COMBAT_THEMES := ["tomb_hall", "ossuary", "archive"]

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
	return {
		"room_count_min": int(cfg.get("room_count_min", ROOM_COUNT_MIN)),
		"room_count_max": int(cfg.get("room_count_max", ROOM_COUNT_MAX)),
		"floor_ratio_min": float(cfg.get("floor_ratio_min", FLOOR_RATIO_MIN)),
		"floor_ratio_max": float(cfg.get("floor_ratio_max", FLOOR_RATIO_MAX)),
		"corridor_ratio_max": float(cfg.get("corridor_ratio_max", CORRIDOR_RATIO_MAX)),
		"dead_end_max_frac": DEAD_END_MAX_FRAC,
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

	# 1. Place non-overlapping rooms.
	var rooms: Array = []
	for _i in ROOM_TRIES:
		var w := rng.randi_range(room_min, room_max)
		var h := rng.randi_range(room_min, room_max)
		var rx := rng.randi_range(1, grid_n - w - 2)
		var ry := rng.randi_range(1, grid_n - h - 2)
		var overlaps := false
		for r in rooms:
			if rx < r.x + r.w + 1 and rx + w + 1 > r.x \
			and ry < r.y + r.h + 1 and ry + h + 1 > r.y:
				overlaps = true
				break
		if not overlaps:
			rooms.append({ "x": rx, "y": ry, "w": w, "h": h })

	if rooms.size() < 2:
		rooms = [
			{ "x": 2, "y": 2, "w": 6, "h": 6 },
			{ "x": grid_n - 9, "y": grid_n - 9, "w": 6, "h": 6 },
		]

	# 2. Assign room shapes + carve floors per shape (Phase 2).
	_assign_shapes(rooms, rng)
	for r in rooms:
		_carve_room(grid, r, rng)

	# 3. Connection graph: Delaunay → MST → re-add loop edges.
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

	# 4. Carve corridors along the final edge set.
	for e in final_edges:
		var a: Dictionary = rooms[e[0]]
		var b: Dictionary = rooms[e[1]]
		var ax := int(a.x + a.w / 2.0)
		var ay := int(a.y + a.h / 2.0)
		var bx := int(b.x + b.w / 2.0)
		var by := int(b.y + b.h / 2.0)
		_carve_h(grid, ax, bx, ay)
		_carve_v(grid, ay, by, bx)

	# 5. Entry = room 0; boss/exit = farthest room by BFS hops.
	var adj := _adjacency(rooms.size(), final_edges)
	var first: Dictionary = rooms[0]
	var entry := {
		"x": int(first.x + first.w / 2.0),
		"y": int(first.y + first.h / 2.0),
	}
	var boss_idx := _farthest_room(adj, 0)
	var boss: Dictionary = rooms[boss_idx]
	# The boss room is always a full rectangle — the arena seal needs it.
	for yy in range(int(boss.y), int(boss.y) + int(boss.h)):
		for xx in range(int(boss.x), int(boss.x) + int(boss.w)):
			grid[yy][xx] = "floor"
	var exit := {
		"x": int(boss.x + boss.w / 2.0),
		"y": int(boss.y + boss.h / 2.0),
	}

	# 6. Tag every room with its array index (spec 29 — the shrine RNG seeds
	#    from (dungeon seed + room id), and layout_loader uses it to find the
	#    focal interactable later).
	for i in rooms.size():
		rooms[i]["id"] = i
	# 7. Roles + themes (1/4), pick a setpiece (3), then dress by rule.
	_assign_rooms(rooms, rng, boss_idx, adj)
	_pick_setpiece(rooms, rng)
	var decor: Array = _dress_rooms(rooms, grid, entry, exit, rng)
	for r in rooms:
		if r.get("role", "") == "setpiece":
			_stamp_setpiece(grid, r, decor)

	# Wyrd — good bias twins scatter gather nodes (ore / forage / logs)
	# through the dungeon. Bad twins are pure omission.
	_scatter_gather_nodes(rooms, grid, entry, exit, decor, rng,
		cfg.get("affixes", []), boss_idx, int(cfg.get("tier", 1)))

	return {
		"grid": grid,
		"entry": entry,
		"exit": exit,
		"chestTile": exit,
		"rooms": rooms,
		"room_edges": final_edges,
		"room_depths": _bfs_depths(adj, 0, rooms.size()),
		"decor": decor,
		"bossRoom": boss,
		"bossKind": String(cfg.get("boss_kind", "hedgemother")),
		"scope": String(cfg.get("scope", "crypt")),
		"tier": int(cfg.get("tier", 1)),
		"seed": int(rng.seed),
	}

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

static func _scatter_gather_nodes(rooms: Array, grid: Array, entry: Dictionary,
		exit: Dictionary, decor: Array, rng: RandomNumberGenerator,
		affixes: Array, boss_idx: int, chart_tier: int = 1) -> void:
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
		while placed < n and tries < 200:
			tries += 1
			var ri := rng.randi_range(0, rooms.size() - 1)
			if ri == 0 or ri == boss_idx:
				continue                       # entrance + boss/exit room stay clear
			var r: Dictionary = rooms[ri]
			var x := rng.randi_range(int(r.x), int(r.x) + int(r.w) - 1)
			var y := rng.randi_range(int(r.y), int(r.y) + int(r.h) - 1)
			if String(grid[y][x]) != "floor":
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
				"x": x, "y": y, "orient": "center"}
			# A6/45 — gather nodes roll a tier from the data tables; deeper
			# charts carry the richer veins and the rarer herbs.
			if affix_id == "mineral_vein":
				entry_d["ore_tier"] = _roll_tier(
					GatherDefs.ORE_ROLLS_BY_TIER, chart_tier, rng)
			elif affix_id == "bramble_bloom":
				entry_d["herb_tier"] = _roll_tier(
					GatherDefs.FORAGE_ROLLS_BY_TIER, chart_tier, rng)
			elif affix_id == "herbal_patch":
				entry_d["herb_tier"] = _roll_tier(
					GatherDefs.FORAGE_ROLLS_PATCH, chart_tier, rng)
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

# 3-wide corridors (spec 24) — brush ±CORRIDOR_HALF perpendicular to the run.
static func _carve_h(grid: Array, x0: int, x1: int, y: int) -> void:
	for x in range(min(x0, x1), max(x0, x1) + 1):
		for dy in range(-CORRIDOR_HALF, CORRIDOR_HALF + 1):
			_carve_tile(grid, x, y + dy)

static func _carve_v(grid: Array, y0: int, y1: int, x: int) -> void:
	for y in range(min(y0, y1), max(y0, y1) + 1):
		for dx in range(-CORRIDOR_HALF, CORRIDOR_HALF + 1):
			_carve_tile(grid, x + dx, y)

# Set a floor tile, keeping the 1-tile outer border as wall.
static func _carve_tile(grid: Array, x: int, y: int) -> void:
	if y >= 1 and y < grid.size() - 1 and x >= 1 and x < grid[0].size() - 1:
		grid[y][x] = "floor"

# ---- Phase 3 (spec 25): authored setpieces ----
# Tag the largest eligible room (still "combat", ≥8×8) as a setpiece.
# Spec 29 — skip rooms already promoted to a role contract (rest/treasure/shrine);
# we don't want a setpiece to clobber a typed-room interactable.
static func _pick_setpiece(rooms: Array, rng: RandomNumberGenerator) -> void:
	var best := -1
	var best_area := 0
	for i in rooms.size():
		var r: Dictionary = rooms[i]
		var role: String = r.get("role", "")
		if role != "combat":
			continue
		if int(r.w) < 8 or int(r.h) < 8:
			continue
		var area := int(r.w) * int(r.h)
		if area > best_area:
			best_area = area
			best = i
	if best >= 0:
		rooms[best]["role"] = "setpiece"
		rooms[best]["setpiece"] = SETPIECES[rng.randi_range(0, SETPIECES.size() - 1)]

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
				decor.append({"kind": SETPIECE_DECOR[ch], "x": gx, "y": gy})

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

# ---- Phase 2 (spec 25): varied room shapes ----
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

# ---- Phase 1 (spec 25): room roles, themes, themed dressing ----
# Spec 29 — every dungeon gets entrance + boss + at least MIN_COMBAT_ROOMS
# combat rooms (so there's always a real fight), THEN rest > treasure > shrine
# in priority order if room count permits. Small dungeons drop the lowest-
# priority typed rooms first rather than starving combat.
const MIN_COMBAT_ROOMS := 2

static func _assign_rooms(rooms: Array, rng: RandomNumberGenerator,
		boss_idx: int, adj: Array) -> void:
	# 1) Fixed roles: entrance + boss.
	rooms[0]["role"] = "entrance"
	rooms[0]["theme"] = "antechamber"
	if boss_idx != 0:
		rooms[boss_idx]["role"] = "boss"
		rooms[boss_idx]["theme"] = "tomb_hall"
	# 2) Budget. After entrance + boss are reserved, we can spend the rest
	#    on typed-room roles, but always keep MIN_COMBAT_ROOMS in reserve.
	var fixed_count: int = 1 + (1 if boss_idx != 0 else 0)
	var slots_left: int = max(0, rooms.size() - fixed_count - MIN_COMBAT_ROOMS)
	# 3) Rest room (priority 1) — prefer one adjacent to the boss on the
	#    graph (Hades pacing: the last room before the boss is heal+save).
	if slots_left > 0:
		var rest_idx := -1
		if boss_idx >= 0 and boss_idx < adj.size():
			for nb in adj[boss_idx]:
				if int(nb) != 0 and int(nb) != boss_idx and not rooms[int(nb)].has("role"):
					rest_idx = int(nb)
					break
		if rest_idx < 0:
			var depths: Array = _bfs_depths(adj, 0, rooms.size())
			var best_d := -1
			for i in rooms.size():
				if i == 0 or i == boss_idx or rooms[i].has("role"):
					continue
				if int(depths[i]) > best_d:
					best_d = int(depths[i])
					rest_idx = i
		if rest_idx >= 0:
			rooms[rest_idx]["role"] = "rest"
			rooms[rest_idx]["theme"] = "hearthroom"
			slots_left -= 1
	# 4) Treasure room (priority 2) — prefer a dead-end (Phase 4 pattern).
	if slots_left > 0:
		var treasure_idx := -1
		for i in rooms.size():
			if rooms[i].has("role"):
				continue
			if i < adj.size() and adj[i].size() <= 1:
				treasure_idx = i
				break
		if treasure_idx < 0:
			for i in rooms.size():
				if not rooms[i].has("role"):
					treasure_idx = i
					break
		if treasure_idx >= 0:
			rooms[treasure_idx]["role"] = "treasure"
			rooms[treasure_idx]["theme"] = "vault"
			slots_left -= 1
	# 5) Shrine room (priority 3) — random pick so it isn't always the same
	#    topological slot.
	if slots_left > 0:
		var pending: Array = []
		for i in rooms.size():
			if not rooms[i].has("role"):
				pending.append(i)
		if not pending.is_empty():
			var shrine_idx: int = pending[rng.randi_range(0, pending.size() - 1)]
			rooms[shrine_idx]["role"] = "shrine"
			rooms[shrine_idx]["theme"] = "shrine"
			slots_left -= 1
	# 6) Everyone else: combat with a random combat theme.
	for i in rooms.size():
		var r: Dictionary = rooms[i]
		if not r.has("role"):
			r["role"] = "combat"
			r["theme"] = COMBAT_THEMES[rng.randi_range(0, COMBAT_THEMES.size() - 1)]

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
			_apply_rule(focal, r, grid, entry, exit, rng, decor, occupied, ir)
		for rule in theme.get("satellites", []):
			_apply_rule(rule, r, grid, entry, exit, rng, decor, occupied, "")
	return decor

static func _apply_rule(rule: Dictionary, r: Dictionary, grid: Array,
		entry: Dictionary, exit: Dictionary, rng: RandomNumberGenerator,
		decor: Array, occupied: Dictionary,
		interact_role: String = "") -> void:
	var n: int = rng.randi_range(int(rule.count[0]), int(rule.count[1]))
	var tiles: Array = _pattern_tiles(r, String(rule.pattern), n, grid, rng,
		false, occupied)
	# Spec 28 — never silently drop a focal (n≥1) just because every
	# preferred candidate happened to be filtered. Fall back to any free
	# in-room floor tile.
	if tiles.is_empty() and n >= 1:
		tiles = _pattern_tiles(r, "scatter", 1, grid, rng, false, occupied)
	# Spec 29 — last-resort fallback: in long thin rooms wedged between two
	# corridors, EVERY floor tile is a corridor mouth and the previous
	# scatter still returns empty. Accept a near-mouth tile rather than
	# silently dropping the focal — chest/altar/hearth must always exist.
	if tiles.is_empty() and n >= 1:
		tiles = _pattern_tiles(r, "scatter", 1, grid, rng, true, occupied)
	for t in tiles:
		if int(t.x) == int(entry.x) and int(t.y) == int(entry.y):
			continue
		if int(t.x) == int(exit.x) and int(t.y) == int(exit.y):
			continue
		var d := {"kind": String(rule.kind), "x": int(t.x), "y": int(t.y),
			"orient": String(t.get("orient", "center"))}
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
		occupied: Dictionary = {}) -> Array:
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
		# Spec 28 — never sit on a tile whose 4-neighbour is floor OUTSIDE the
		# room (= a corridor mouth). Decor there blocks the room's entry.
		# Spec 29 — last-resort fallback can opt out (long thin rooms where
		# every candidate is a corridor mouth; better a focal that pinches
		# the path than no focal at all).
		if not allow_corridor_mouths and _is_corridor_mouth(r, cx, cy, grid):
			continue
		var key: int = cx * 10000 + cy
		if seen.has(key) or occupied.has(key):
			continue
		seen[key] = true
		out.append(c)
		if out.size() >= n:
			break
	return out

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

static func _shuffle(arr: Array, rng: RandomNumberGenerator) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp
