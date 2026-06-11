extends Control

# Spec 27c/d — Tetris inventory panel + equipment slots.
# 5×6 grid on the right, 5 equipment slots stacked on the left. Drag/snap/
# rotate (R) within the grid; drag grid ↔ slot to (un)equip; right-click
# an item or slot to quick-(un)equip. Toggled by the player (I key).

const Affixes = preload("res://data/affixes.gd")  # spec 27f tooltip formatter

const COLS := 5
const ROWS := 6
const CELL := 64
const PAD := 3
const SLOT_SIZE := 72
const SLOT_GAP := 4

var grid_origin := Vector2(940, 200)
var slot_origin := Vector2(854, 200)        # 80 px left of the grid

var inventory: Inventory
var equipment: Equipment

# Drag state. _held_source describes where the held item came from:
#   {"type": "grid", "pos": Vector2i, "rotated": bool}
#   {"type": "slot", "name": "weapon"}
var _held_item = null
var _held_source: Dictionary = {}
var _held_rotated: bool
var _cursor_cell: Vector2i = Vector2i(-1, -1)
var _cursor_slot: String = ""
var _cursor_screen: Vector2 = Vector2.ZERO

const RARITY_COLOR := {
	"normal": Color(1.00, 0.96, 0.82),
	"magic":  Color(0.42, 0.62, 1.00),
	"rare":   Color(1.00, 0.80, 0.20),
	"unique": Color(1.00, 0.55, 0.20),
}

func _ready() -> void:
	visible = false
	mouse_filter = MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func set_inventory(inv: Inventory) -> void:
	inventory = inv
	queue_redraw()

func set_equipment(eq: Equipment) -> void:
	equipment = eq
	queue_redraw()

func toggle() -> void:
	visible = not visible
	if visible:
		queue_redraw()
	# Spec 27f — UI open/close SFX (no-op until the file is generated).
	var sfx := get_node_or_null("/root/Sfx")
	if sfx != null:
		sfx.play("inv_open")

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_R and _held_item != null:
			_held_rotated = not _held_rotated
			queue_redraw()
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_try_pick_up_at(event.position)
			else:
				_try_drop_at(event.position)
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			_quick_swap_at(event.position)
	elif event is InputEventMouseMotion:
		_cursor_screen = event.position
		_cursor_cell = _cell_at(event.position)
		_cursor_slot = _slot_at(event.position)
		queue_redraw()         # spec 27f — tooltip + ghost both follow the cursor

# ---- hit-testing helpers ----
func _cell_at(screen_pos: Vector2) -> Vector2i:
	var local := screen_pos - grid_origin
	if local.x < 0 or local.y < 0 \
			or local.x >= COLS * CELL or local.y >= ROWS * CELL:
		return Vector2i(-1, -1)
	return Vector2i(int(local.x / CELL), int(local.y / CELL))

func _slot_at(screen_pos: Vector2) -> String:
	for i in Equipment.SLOT_ORDER.size():
		var top := slot_origin + Vector2(0, i * (SLOT_SIZE + SLOT_GAP))
		var r := Rect2(top, Vector2(SLOT_SIZE, SLOT_SIZE))
		if r.has_point(screen_pos):
			return Equipment.SLOT_ORDER[i]
	return ""

func _slot_top(slot_name: String) -> Vector2:
	var idx := Equipment.SLOT_ORDER.find(slot_name)
	return slot_origin + Vector2(0, idx * (SLOT_SIZE + SLOT_GAP))

# ---- click / drag ----
func _try_pick_up_at(pos: Vector2) -> void:
	# Slot click first (slots sit left of the grid, no overlap, but check
	# slots before grid for clarity).
	var slot := _slot_at(pos)
	if slot != "" and equipment != null:
		var it = equipment.get_slot(slot)
		if it != null:
			_held_item = it
			_held_source = {"type": "slot", "name": slot}
			_held_rotated = it.get("rotated", false)
			equipment.unequip(slot)
			queue_redraw()
			return
	if inventory == null:
		return
	var cell := _cell_at(pos)
	if cell.x < 0:
		return
	var item = inventory.cells[cell.y][cell.x]
	if item == null:
		return
	_held_item = item
	_held_source = {"type": "grid", "pos": item.pos,
		"rotated": item.get("rotated", false)}
	_held_rotated = item.get("rotated", false)
	inventory.remove(item)
	queue_redraw()

func _try_drop_at(pos: Vector2) -> void:
	if _held_item == null:
		return
	var slot := _slot_at(pos)
	if slot != "":
		_drop_on_slot(slot)
	else:
		var cell := _cell_at(pos)
		_drop_on_grid(cell)
	_held_item = null
	_held_source = {}
	_cursor_cell = Vector2i(-1, -1)
	queue_redraw()

func _drop_on_slot(slot: String) -> void:
	# Reject if categories don't match.
	if not equipment.can_equip(_held_item) \
			or String(_held_item.category) != slot:
		_snap_back()
		return
	# Pre-check the displacement — if a swap would leave the previous gear
	# homeless, abort and snap back.
	var prev = equipment.get_slot(slot)
	if prev != null:
		var fit := inventory.find_first_fit(prev)
		if fit.is_empty():
			_snap_back()
			return
		equipment.equip(_held_item)
		inventory.try_place(prev, fit.pos, fit.rotated)
	else:
		equipment.equip(_held_item)

func _drop_on_grid(cell: Vector2i) -> void:
	if cell.x < 0:
		_snap_back()
		return
	var placed := inventory.try_place(_held_item, cell, _held_rotated)
	if not placed:
		_snap_back()

func _snap_back() -> void:
	if _held_source.is_empty():
		return
	if _held_source.type == "grid":
		inventory.try_place(_held_item, _held_source.pos, _held_source.rotated)
	elif _held_source.type == "slot":
		equipment.equip(_held_item)

# ---- right-click quick-swap ----
func _quick_swap_at(pos: Vector2) -> void:
	if _held_item != null:
		return                              # ignore while dragging
	var slot := _slot_at(pos)
	if slot != "" and equipment != null:
		_quick_unequip(slot)
		return
	if inventory == null:
		return
	var cell := _cell_at(pos)
	if cell.x < 0:
		return
	var item = inventory.cells[cell.y][cell.x]
	if item != null:
		_quick_equip(item)

func _quick_equip(item: Dictionary) -> void:
	if not equipment.can_equip(item):
		return
	var slot := String(item.category)
	var prev = equipment.get_slot(slot)
	if prev != null:
		# Need a home for the displaced item — without removing the new one
		# first, find_first_fit will count its cells; so remove it first.
		inventory.remove(item)
		var fit := inventory.find_first_fit(prev)
		if fit.is_empty():
			# Put both back where they were.
			inventory.try_place(item, item.pos, item.get("rotated", false))
			return
		equipment.equip(item)
		inventory.try_place(prev, fit.pos, fit.rotated)
	else:
		inventory.remove(item)
		equipment.equip(item)
	queue_redraw()

func _quick_unequip(slot: String) -> void:
	var it = equipment.get_slot(slot)
	if it == null:
		return
	var fit := inventory.find_first_fit(it)
	if fit.is_empty():
		return                              # inventory full — silent no-op
	equipment.unequip(slot)
	inventory.try_place(it, fit.pos, fit.rotated)
	queue_redraw()

# ---- rendering ----
func _draw() -> void:
	if not visible:
		return
	# Dim backdrop over the whole screen.
	draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size),
		Color(0, 0, 0, 0.35))
	_draw_slots()
	_draw_grid()
	if _held_item != null:
		_draw_held()
	# Header.
	var font := get_theme_default_font()
	draw_string(font, grid_origin + Vector2(0, -14),
		"Inventory  (I close · R rotate · right-click to quick-(un)equip)",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.95, 0.92, 0.88))
	# Hover tooltip — drawn last so it sits on top of everything.
	_draw_tooltip()

func _draw_grid() -> void:
	var grid_size := Vector2(COLS * CELL, ROWS * CELL)
	draw_rect(Rect2(grid_origin - Vector2(10, 10), grid_size + Vector2(20, 20)),
		Color(0.10, 0.08, 0.09, 0.95))
	for y in ROWS:
		for x in COLS:
			var r := Rect2(grid_origin + Vector2(x * CELL, y * CELL),
				Vector2(CELL, CELL))
			draw_rect(r, Color(0.18, 0.15, 0.16, 0.60))
			draw_rect(r, Color(0.30, 0.26, 0.24, 0.90), false, 1.0)
	if inventory != null:
		for it in inventory.items:
			_draw_item_in_grid(it)

func _draw_slots() -> void:
	if equipment == null:
		return
	var font := get_theme_default_font()
	for i in Equipment.SLOT_ORDER.size():
		var name := String(Equipment.SLOT_ORDER[i])
		var top := slot_origin + Vector2(0, i * (SLOT_SIZE + SLOT_GAP))
		var r := Rect2(top, Vector2(SLOT_SIZE, SLOT_SIZE))
		draw_rect(r, Color(0.14, 0.11, 0.12, 0.95))
		draw_rect(r, Color(0.35, 0.30, 0.28, 0.95), false, 2.0)
		# label
		draw_string(font, top + Vector2(4, 14), name.capitalize(),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.70, 0.66, 0.62))
		# equipped item
		var it = equipment.get_slot(name)
		if it != null:
			_draw_item_rect_scaled(it, top + Vector2(8, 18),
				Vector2(SLOT_SIZE - 16, SLOT_SIZE - 26), false)

func _draw_item_in_grid(it: Dictionary) -> void:
	var rotated: bool = it.get("rotated", false)
	var fp: Vector2i = Inventory.footprint(it, rotated)
	var top := grid_origin + Vector2(int(it.pos.x) * CELL, int(it.pos.y) * CELL)
	_draw_item_rect_scaled(it, top + Vector2(PAD, PAD),
		Vector2(fp.x * CELL - PAD * 2, fp.y * CELL - PAD * 2), false)

func _draw_item_rect_scaled(it: Dictionary, top: Vector2, size: Vector2, ghost: bool) -> void:
	var fill: Color = it.get("icon_color", Color.WHITE)
	if ghost:
		fill.a = 0.55
	draw_rect(Rect2(top, size), fill)
	var rc: Color = RARITY_COLOR.get(String(it.rarity), Color.WHITE)
	if ghost:
		rc.a = 0.7
	draw_rect(Rect2(top, size), rc, false, 3.0)

# ---- Spec 27f: hover tooltip ----
func _hovered_item():
	if _held_item != null:
		return null
	if _cursor_cell.x >= 0 and inventory != null:
		return inventory.cells[_cursor_cell.y][_cursor_cell.x]
	if _cursor_slot != "" and equipment != null:
		return equipment.get_slot(_cursor_slot)
	return null

func _tooltip_lines(item: Dictionary) -> Array:
	var rc: Color = RARITY_COLOR.get(String(item.rarity), Color.WHITE)
	var lines: Array = []
	lines.append({"text": String(item.name), "color": rc, "size": 14})
	lines.append({
		"text": "%s %s" % [String(item.rarity).capitalize(),
			String(item.category).capitalize()],
		"color": Color(0.70, 0.66, 0.62), "size": 11})
	lines.append({"text": "", "color": Color.WHITE, "size": 11})
	var base_stat := String(item.get("base_stat", ""))
	if base_stat != "":
		var base_aff := {"stat": base_stat, "value": item.get("base_value", 0),
			"side": "base", "display": "Base", "id": "base"}
		lines.append({"text": Affixes.format_affix(base_aff),
			"color": Color(0.88, 0.84, 0.78), "size": 12})
	for a in item.get("affixes", []):
		lines.append({"text": Affixes.format_affix(a),
			"color": Color(0.55, 0.80, 1.00), "size": 12})
	return lines

func _draw_tooltip() -> void:
	var item = _hovered_item()
	if item == null:
		return
	var lines: Array = _tooltip_lines(item)
	var line_h := 18
	var ipad := 8
	var w := 280.0
	var h: float = ipad * 2 + lines.size() * line_h
	var pos := _cursor_screen + Vector2(16, 16)
	var screen := get_viewport_rect().size
	if pos.x + w > screen.x:
		pos.x = _cursor_screen.x - w - 16
	if pos.y + h > screen.y:
		pos.y = screen.y - h - 8
	if pos.x < 0:
		pos.x = 0
	if pos.y < 0:
		pos.y = 0
	draw_rect(Rect2(pos, Vector2(w, h)), Color(0.06, 0.04, 0.05, 0.96))
	draw_rect(Rect2(pos, Vector2(w, h)),
		Color(0.35, 0.30, 0.28, 0.95), false, 2.0)
	var font := get_theme_default_font()
	var y := pos.y + ipad + 14
	for line in lines:
		draw_string(font, Vector2(pos.x + ipad, y), String(line.text),
			HORIZONTAL_ALIGNMENT_LEFT, w - ipad * 2, int(line.size), line.color)
		y += line_h

func _draw_held() -> void:
	var fp: Vector2i = Inventory.footprint(_held_item, _held_rotated)
	# Grid-cell preview (green/red).
	if _cursor_cell.x >= 0 and inventory != null:
		var valid := inventory.can_place(_held_item, _cursor_cell, _held_rotated)
		var pc: Color = Color(0.40, 1.00, 0.50, 0.32) if valid \
			else Color(1.00, 0.30, 0.30, 0.32)
		var top := grid_origin + Vector2(_cursor_cell.x * CELL, _cursor_cell.y * CELL)
		var clamped := Vector2i(
			mini(fp.x, COLS - _cursor_cell.x),
			mini(fp.y, ROWS - _cursor_cell.y))
		if clamped.x > 0 and clamped.y > 0:
			draw_rect(Rect2(top, Vector2(clamped.x * CELL, clamped.y * CELL)), pc)
	# Slot preview (green/red) if the cursor is over a slot.
	if _cursor_slot != "" and equipment != null:
		var ok := equipment.can_equip(_held_item) \
			and String(_held_item.category) == _cursor_slot
		var pc2: Color = Color(0.40, 1.00, 0.50, 0.32) if ok \
			else Color(1.00, 0.30, 0.30, 0.32)
		var top2 := _slot_top(_cursor_slot)
		draw_rect(Rect2(top2, Vector2(SLOT_SIZE, SLOT_SIZE)), pc2)
	# Ghost item under the cursor.
	var hp := _cursor_screen - Vector2(fp.x * CELL, fp.y * CELL) * 0.5
	_draw_item_rect_scaled(_held_item, hp, Vector2(fp.x * CELL, fp.y * CELL), true)
