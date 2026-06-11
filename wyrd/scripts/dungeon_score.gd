class_name DungeonScore
extends RefCounted

# Spec 08 — layout quality scorer.
# score_layout() takes a generated layout + a config dict of target bands
# and weights, and returns per-metric scores (0..1) plus a weighted total.
#
# connectivity is a HARD GATE: if any floor tile is unreachable from the
# entry, total collapses to the connectivity fraction itself (always < 1).

# layout keys used: grid, rooms, entry, exit, room_edges (Array of [i,j])
# cfg keys used:
#   room_count_min, room_count_max
#   floor_ratio_min, floor_ratio_max
#   corridor_ratio_max
#   dead_end_max_frac          (ceil(rooms * frac) is the dead-end ceiling)
#   critical_path_target_frac  (hops / rooms must reach this)
static func score_layout(layout: Dictionary, cfg: Dictionary) -> Dictionary:
	var grid: Array = layout.grid
	var rooms: Array = layout.rooms
	var room_count := rooms.size()

	var connectivity := _connectivity(grid, layout.entry)
	var floor_tiles := _count_floor(grid)
	var room_tiles := _count_room_tiles(grid, rooms)
	var corridor_tiles: int = max(0, floor_tiles - room_tiles)
	var grid_area := grid.size() * (grid[0] as Array).size()

	# --- soft metric 1: room count in band ---
	var s_rooms := _band_score(
		room_count, cfg.room_count_min, cfg.room_count_max, 0.15)

	# --- soft metric 2: floor ratio ---
	var floor_ratio := float(floor_tiles) / float(max(1, grid_area))
	var s_floor := _band_score_f(
		floor_ratio, cfg.floor_ratio_min, cfg.floor_ratio_max, 0.5)

	# --- soft metric 3: corridor ratio (lower is better, capped) ---
	var corridor_ratio := float(corridor_tiles) / float(max(1, room_tiles))
	var s_corridor: float = clampf(
		1.0 - max(0.0, corridor_ratio - cfg.corridor_ratio_max) / 0.5, 0.0, 1.0)

	# --- soft metric 4: critical path length (entry room → boss room) ---
	var adj := _room_adjacency(room_count, layout.room_edges)
	var entry_room := _room_containing(rooms, layout.entry)
	var boss_room := _room_containing(rooms, layout.exit)
	var hops := _bfs_hops(adj, entry_room, boss_room)
	var path_frac := float(hops) / float(max(1, room_count))
	var s_path: float = clampf(
		path_frac / float(cfg.critical_path_target_frac), 0.0, 1.0)

	# --- soft metric 5: dead ends in a healthy band ---
	var dead_ends := _count_dead_ends(adj)
	var dead_ceiling: int = int(ceil(room_count * float(cfg.dead_end_max_frac)))
	var s_deadends := _band_score(dead_ends, 1, max(1, dead_ceiling), 0.25)

	var soft_avg := (s_rooms + s_floor + s_corridor + s_path + s_deadends) / 5.0

	# connectivity gate.
	var total := soft_avg
	if connectivity < 0.999:
		total = connectivity * 0.5   # never let a broken layout look good

	return {
		"connectivity": connectivity,
		"critical_path": s_path,
		"room_count": s_rooms,
		"floor_ratio": s_floor,
		"corridor_ratio": s_corridor,
		"dead_ends": s_deadends,
		"total": total,
		# raw values for debugging
		"_raw": {
			"rooms": room_count, "floor_tiles": floor_tiles,
			"corridor_ratio": corridor_ratio, "hops": hops,
			"dead_ends": dead_ends,
		},
	}

# ---- connectivity: flood-fill floor tiles from the entry ----
static func _connectivity(grid: Array, entry) -> float:
	var total := _count_floor(grid)
	if total == 0:
		return 0.0
	var h := grid.size()
	var w := (grid[0] as Array).size()
	var seen := {}
	var stack := [Vector2i(int(entry.x), int(entry.y))]
	while not stack.is_empty():
		var p: Vector2i = stack.pop_back()
		if p.x < 0 or p.y < 0 or p.x >= w or p.y >= h:
			continue
		if seen.has(p):
			continue
		if String(grid[p.y][p.x]) != "floor":
			continue
		seen[p] = true
		stack.append(Vector2i(p.x + 1, p.y))
		stack.append(Vector2i(p.x - 1, p.y))
		stack.append(Vector2i(p.x, p.y + 1))
		stack.append(Vector2i(p.x, p.y - 1))
	return float(seen.size()) / float(total)

static func _count_floor(grid: Array) -> int:
	var n := 0
	for row in grid:
		for cell in row:
			if String(cell) == "floor":
				n += 1
	return n

static func _count_room_tiles(grid: Array, rooms: Array) -> int:
	# Floor tiles that fall inside any room rect.
	var n := 0
	for r in rooms:
		for yy in range(r.y, r.y + r.h):
			for xx in range(r.x, r.x + r.w):
				if String(grid[yy][xx]) == "floor":
					n += 1
	return n

# ---- room graph helpers ----
static func _room_adjacency(count: int, edges: Array) -> Array:
	var adj := []
	for _i in count:
		adj.append([])
	for e in edges:
		var a: int = e[0]
		var b: int = e[1]
		if a >= 0 and a < count and b >= 0 and b < count:
			adj[a].append(b)
			adj[b].append(a)
	return adj

static func _room_containing(rooms: Array, tile) -> int:
	var tx := int(tile.x)
	var ty := int(tile.y)
	for i in rooms.size():
		var r: Dictionary = rooms[i]
		if tx >= r.x and tx < r.x + r.w and ty >= r.y and ty < r.y + r.h:
			return i
	return 0

static func _bfs_hops(adj: Array, from_idx: int, to_idx: int) -> int:
	if from_idx == to_idx:
		return 0
	var dist := {}
	dist[from_idx] = 0
	var queue := [from_idx]
	var head := 0
	while head < queue.size():
		var cur: int = queue[head]
		head += 1
		for nb in adj[cur]:
			if dist.has(nb):
				continue
			dist[nb] = dist[cur] + 1
			if nb == to_idx:
				return dist[nb]
			queue.append(nb)
	return 0   # unreachable on the room graph — path metric scores 0

static func _count_dead_ends(adj: Array) -> int:
	var n := 0
	for nbs in adj:
		if (nbs as Array).size() == 1:
			n += 1
	return n

# ---- band-score helpers: 1.0 inside [lo, hi], linear falloff outside ----
static func _band_score(v: int, lo: int, hi: int, falloff: float) -> float:
	if v >= lo and v <= hi:
		return 1.0
	var d: int = lo - v if v < lo else v - hi
	return clampf(1.0 - falloff * d, 0.0, 1.0)

static func _band_score_f(v: float, lo: float, hi: float, falloff: float) -> float:
	if v >= lo and v <= hi:
		return 1.0
	var d: float = lo - v if v < lo else v - hi
	return clampf(1.0 - falloff * d * 10.0, 0.0, 1.0)
