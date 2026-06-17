extends RefCounted
class_name Inventory

# Spec 27c — the Tetris inventory data model.
# A COLS × ROWS grid. Each item carries a Vector2i `size` (its native
# footprint), a `pos` (top-left cell once placed), and a `rotated` flag
# (when true the footprint axes swap). The grid stores per-cell references
# back to the item dict so collision checks are O(footprint).

const COLS := 5
const BASE_ROWS := 6
var rows: int = BASE_ROWS   # runtime — the pack grows a row at level milestones

var cells: Array        # cells[y][x] = item dict or null
var items: Array = []   # all placed items, for iteration

func _init() -> void:
	cells = []
	for y in rows:
		var row: Array = []
		for x in COLS:
			row.append(null)
		cells.append(row)

# Effective footprint — rotation swaps the axes.
static func footprint(item: Dictionary, rotated: bool) -> Vector2i:
	var s: Vector2i = item.size
	return Vector2i(s.y, s.x) if rotated else s

# Can the item be placed at pos with the given rotation?
# `ignore_item` exempts an item from collision (used by move/rotate-in-place).
func can_place(item: Dictionary, pos: Vector2i, rotated: bool, ignore_item = null) -> bool:
	var fp := footprint(item, rotated)
	if pos.x < 0 or pos.y < 0:
		return false
	if pos.x + fp.x > COLS or pos.y + fp.y > rows:
		return false
	for j in fp.y:
		for i in fp.x:
			var c = cells[pos.y + j][pos.x + i]
			if c != null and c != ignore_item:
				return false
	return true

func try_place(item: Dictionary, pos: Vector2i, rotated: bool = false) -> bool:
	if not can_place(item, pos, rotated):
		return false
	item["pos"] = pos
	item["rotated"] = rotated
	var fp := footprint(item, rotated)
	for j in fp.y:
		for i in fp.x:
			cells[pos.y + j][pos.x + i] = item
	if not items.has(item):
		items.append(item)
	return true

func remove(item: Dictionary) -> void:
	if not item.has("pos"):
		return
	var fp := footprint(item, item.get("rotated", false))
	var pos: Vector2i = item.pos
	for j in fp.y:
		for i in fp.x:
			cells[pos.y + j][pos.x + i] = null
	items.erase(item)

# Grow (or shrink) the pack to `new_rows`. Expansion appends empty rows;
# shrink refuses if any soon-to-be-removed bottom row is occupied.
func resize(new_rows: int) -> bool:
	if new_rows == rows:
		return true
	if new_rows < rows:
		for y in range(new_rows, rows):
			for x in COLS:
				if cells[y][x] != null:
					return false
		cells.resize(new_rows)
		rows = new_rows
		return true
	for _y in range(rows, new_rows):
		var row: Array = []
		for _x in COLS:
			row.append(null)
		cells.append(row)
	rows = new_rows
	return true

# First grid position where the item fits — non-rotated first, then rotated
# if the footprint isn't square. Returns {} if there's no fit.
func find_first_fit(item: Dictionary) -> Dictionary:
	for y in rows:
		for x in COLS:
			if can_place(item, Vector2i(x, y), false):
				return {"pos": Vector2i(x, y), "rotated": false}
	var s: Vector2i = item.size
	if s.x != s.y:
		for y in rows:
			for x in COLS:
				if can_place(item, Vector2i(x, y), true):
					return {"pos": Vector2i(x, y), "rotated": true}
	return {}

# Move the item at `from` to `to` (with optional rotation). On collision,
# the item snaps back to its original position + rotation. Returns true on
# a successful move.
func move(from_pos: Vector2i, to_pos: Vector2i, rotated: bool) -> bool:
	if from_pos.x < 0 or from_pos.y < 0 \
			or from_pos.x >= COLS or from_pos.y >= rows:
		return false
	var item = cells[from_pos.y][from_pos.x]
	if item == null:
		return false
	var orig_rot: bool = item.get("rotated", false)
	remove(item)
	if try_place(item, to_pos, rotated):
		return true
	# snap back
	try_place(item, from_pos, orig_rot)
	return false
