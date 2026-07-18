extends Control

# Spec 27c/d — Tetris inventory panel + equipment slots.
# 5×6 grid on the right, 5 equipment slots stacked on the left. Drag/snap/
# rotate (R) within the grid; drag grid ↔ slot to (un)equip; right-click
# an item or slot to quick-(un)equip. Toggled by the player (I key).

const Affixes = preload("res://data/affixes.gd")  # spec 27f tooltip formatter
const CraftingDefs = preload("res://data/crafting.gd")
const ChartsData = preload("res://data/charts.gd")
const GatherDefs = preload("res://data/gather.gd")

const COLS := 5
const ROWS := 6
const CELL := 64
const PAD := 3
const SLOT_SIZE := 72
const SLOT_GAP := 4

# Wyrd Diablo-style rebuild — the pack is a framed window docked right:
# paper-doll equipment up top (helm over chest, weapon/ring at the sides,
# boots below), the Tetris grid beneath, painted item icons with rarity
# glows. All hit-testing/interaction logic is unchanged.
var grid_origin := Vector2(940, 330)
var doll_origin := Vector2(940, 60)         # paper-doll anchor (recomputed)

# Slot offsets relative to doll_origin — a body column beside the grid
# (PoE layout: paper-doll left, grid right) so the window fits a 648-high
# viewport. Helmet over chest over boots; weapon and ring at the side.
const SLOT_OFFSET := {
	"helmet": Vector2(88, 0),
	"ring": Vector2(6, 14),
	"weapon": Vector2(6, 110),
	"chest": Vector2(88, 88),
	"boots": Vector2(88, 176),
	# Spec 38 — the trade-tool row, grouped under the body column.
	"pickaxe": Vector2(6, 268),
	"axe": Vector2(88, 268),
}

# Painted item icons (Meshy ink-style pass, 2026-06-10). Missing kinds
# fall back to the flat color plate.
const ICON_TEX := {
	"shortbow": "res://assets/ui/items/shortbow.png",
	"longbow": "res://assets/ui/items/longbow.png",
	"leather_helm": "res://assets/ui/items/leather_helm.png",
	"leather_chest": "res://assets/ui/items/leather_chest.png",
	"leather_boots": "res://assets/ui/items/leather_boots.png",
	"copper_ring": "res://assets/ui/items/copper_ring.png",
}

func _win_rect() -> Rect2:
	# 116px header band fits the title + tab row above the grid; 64px
	# footer fits the keys hint.
	return Rect2(grid_origin - Vector2(272, 124),
		Vector2(COLS * CELL + 272 + 52, ROWS * CELL + 124 + 96))

func _tab_rect(i: int) -> Rect2:
	var win := _win_rect()
	# Spec 40 — four equal tabs spanning the content width, butt-joined.
	var inset := 52.0
	var tw := (win.size.x - inset * 2.0) / 4.0
	return Rect2(win.position + Vector2(inset + i * tw, 72), Vector2(tw, 32))

func _update_layout() -> void:
	var vp := get_viewport_rect().size
	var grid_w := COLS * CELL
	grid_origin = Vector2(vp.x - grid_w - 70.0,
		clampf(vp.y * 0.5 - (ROWS * CELL) * 0.5 + 30.0, 90.0, vp.y))
	doll_origin = grid_origin + Vector2(-216.0, 40.0)

var inventory: Inventory
var equipment: Equipment
# Wyrd — one window, no split: Gear / Satchel / Charts live as tabs
# (playtest ruling 2026-06-10, mock: docs/ui-refs/mj_pack_tabbed.png).
const TABS := ["Gear", "Satchel", "Charts", "Trades"]
const TAB_ICONS := [
	"res://assets/ui/icons/gear.png",
	"res://assets/ui/icons/satchel.png",
	"res://assets/ui/icons/chart.png",
	"res://assets/ui/icons/trades.png",
]
var _tab := 0

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
	"normal": Color(0.48, 0.40, 0.30),   # quiet ink — normals don't shout
	"magic":  Color(0.25, 0.42, 0.75),
	"rare":   Color(0.82, 0.62, 0.12),
	"unique": Color(0.80, 0.38, 0.10),
}

var _tex_cache := {}

func _ready() -> void:
	visible = false
	mouse_filter = MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Preload every texture _draw needs — a CompressedTexture2D whose first
	# load happens inside _draw renders as a white rect (macOS, Godot 4.6).
	for path in ICON_TEX.values():
		if ResourceLoader.exists(String(path)):
			_tex_cache[String(path)] = load(String(path))
	for path in TAB_ICONS:
		if ResourceLoader.exists(String(path)):
			_tex_cache[String(path)] = load(String(path))
	if ResourceLoader.exists(WyrdUi.PANEL_TEX_PATH):
		_tex_cache[WyrdUi.PANEL_TEX_PATH] = load(WyrdUi.PANEL_TEX_PATH)

func _cached_tex(path: String) -> Texture2D:
	return _tex_cache.get(path, null)

func set_inventory(inv: Inventory) -> void:
	inventory = inv
	queue_redraw()

func set_equipment(eq: Equipment) -> void:
	equipment = eq
	queue_redraw()

func toggle() -> void:
	open_tab(0)

# Open on a tab; if already open on that tab, close (so I and M both
# toggle naturally).
func open_tab(t: int) -> void:
	if visible and _tab == t:
		visible = false
	else:
		_tab = t
		visible = true
		_update_layout()
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
				for i in TABS.size():
					if _tab_rect(i).has_point(event.position):
						_tab = i
						queue_redraw()
						return
				if _tab == 0:
					_try_pick_up_at(event.position)
			elif _tab == 0:
				_try_drop_at(event.position)
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed \
				and _tab == 0:
			_quick_swap_at(event.position)
		# Spec 45 followup — the list pages scroll on the wheel; eat the
		# event so the camera rig doesn't zoom behind the open pack.
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed \
				and _tab != 0:
			_scroll_tab(SCROLL_STEP)
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed \
				and _tab != 0:
			_scroll_tab(-SCROLL_STEP)
			get_viewport().set_input_as_handled()
	elif event is InputEventPanGesture and _tab != 0:
		# macOS trackpads pan instead of clicking a wheel.
		_scroll_tab((event as InputEventPanGesture).delta.y * 14.0)
		get_viewport().set_input_as_handled()
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
	for name in SLOT_OFFSET:
		var r := Rect2(_slot_top(String(name)), Vector2(SLOT_SIZE, SLOT_SIZE))
		if r.has_point(screen_pos):
			return String(name)
	return ""

func _slot_top(slot_name: String) -> Vector2:
	return doll_origin + (SLOT_OFFSET.get(slot_name, Vector2.ZERO) as Vector2)

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
		Color(0, 0, 0, 0.45))
	# The framed pack window — Midjourney parchment frame behind everything.
	var win := _win_rect()
	if _cached_tex(WyrdUi.PANEL_TEX_PATH) != null:
		# Texture preloaded in _ready (white-texture gotcha); the factory's
		# load() hits the resource cache, so this is safe inside _draw.
		WyrdUi.panel_stylebox().draw(get_canvas_item(), win)
	else:
		draw_rect(win, Color(0.93, 0.88, 0.76, 0.97))
	# Warm parchment wash over the frame's pale page so the window never
	# reads as bare white.
	draw_rect(win.grow(-26), Color(0.91, 0.85, 0.70, 0.45))
	var hdr_font: Font = WyrdUi.font_header()
	if hdr_font == null:
		hdr_font = get_theme_default_font()
	var hint_font: Font = get_theme_default_font()
	# Spec 45 followup — the list pages (Satchel / Charts / Trades) outgrew
	# the fixed window, so they scroll: page content draws first, shifted up
	# by the tab's scroll offset; parchment masks then hide whatever slid
	# under the header / footer bands, and the title + tabs draw back on top.
	if _tab != 0:
		var view := _view_rect(win)
		var scroll := _scroll_offset(_tab, view)
		draw_set_transform(Vector2(0.0, -scroll))
		match _tab:
			1:
				_draw_satchel_tab(win, hint_font, scroll, view)
			2:
				_draw_charts_tab(win, hint_font, scroll, view)
			3:
				_draw_trades_tab(win, hint_font, scroll, view)
		draw_set_transform(Vector2.ZERO)
		_draw_page_masks(win, view)
		_draw_scroll_marker(win, view, hint_font)
		# Content may have shrunk under a stored offset — settle it once.
		var max_s: float = maxf(0.0,
			float(_tab_content_h.get(_tab, 0.0)) - view.size.y)
		if scroll > max_s:
			_tab_scroll[_tab] = max_s
			queue_redraw()
	draw_string(hdr_font, win.position + Vector2(52, 58),
		"Adventurer's Pack", HORIZONTAL_ALIGNMENT_LEFT, win.size.x - 104, 24,
		WyrdUi.TERRACOTTA)
	_draw_tabs(win)
	if _tab == 0:
		# Gold readout lives with the paper-doll — Gear tab only, else it
		# stamps over the other pages' text.
		var game := get_tree().root.get_node_or_null("Game")
		if game != null:
			draw_string(hdr_font, doll_origin + Vector2(-6, 364),
				"%d gold" % int(game.gold), HORIZONTAL_ALIGNMENT_CENTER,
				172.0, 16, WyrdUi.GOLD)
		_draw_slots()
		_draw_grid()
		if _held_item != null:
			_draw_held()
		draw_string(hint_font, grid_origin + Vector2(0, ROWS * CELL + 30),
			"I close · R rotate · right-click quick-equips",
			HORIZONTAL_ALIGNMENT_CENTER, COLS * CELL, 13, WyrdUi.INK_MID)
		# Hover tooltip — drawn last so it sits on top of everything.
		_draw_tooltip()

func _draw_grid() -> void:
	var grid_size := Vector2(COLS * CELL, ROWS * CELL)
	# Recessed well behind the cells (Diablo's sunken-grid read).
	draw_rect(Rect2(grid_origin - Vector2(6, 6), grid_size + Vector2(12, 12)),
		Color(0.72, 0.64, 0.50, 0.85))
	for y in ROWS:
		for x in COLS:
			var r := Rect2(grid_origin + Vector2(x * CELL, y * CELL),
				Vector2(CELL, CELL))
			draw_rect(r.grow(-1), Color(0.84, 0.77, 0.62))
			# Inner shadow: dark top/left, light bottom/right → sunken cell.
			draw_line(r.position + Vector2(1, 1),
				r.position + Vector2(CELL - 1, 1), Color(0.45, 0.37, 0.27, 0.7), 2.0)
			draw_line(r.position + Vector2(1, 1),
				r.position + Vector2(1, CELL - 1), Color(0.45, 0.37, 0.27, 0.7), 2.0)
			draw_line(r.position + Vector2(1, CELL - 1),
				r.position + Vector2(CELL - 1, CELL - 1),
				Color(0.97, 0.93, 0.82, 0.8), 1.5)
			draw_line(r.position + Vector2(CELL - 1, 1),
				r.position + Vector2(CELL - 1, CELL - 1),
				Color(0.97, 0.93, 0.82, 0.8), 1.5)
	if inventory != null:
		for it in inventory.items:
			_draw_item_in_grid(it)

func _draw_slots() -> void:
	if equipment == null:
		return
	var font: Font = get_theme_default_font()
	# Spec 41 (Pack design) — the tool pair gets its section label.
	var hdr2: Font = WyrdUi.font_header()
	if hdr2 == null:
		hdr2 = font
	draw_string(hdr2, _slot_top("pickaxe") + Vector2(0, -10), "Trade Tools",
		HORIZONTAL_ALIGNMENT_LEFT, 160.0, 14, WyrdUi.INK)
	for name in SLOT_OFFSET:
		var top := _slot_top(String(name))
		var r := Rect2(top, Vector2(SLOT_SIZE, SLOT_SIZE))
		# Recessed slot well.
		draw_rect(r, Color(0.80, 0.72, 0.58))
		draw_line(r.position + Vector2(1, 1), r.position + Vector2(SLOT_SIZE - 1, 1),
			Color(0.45, 0.37, 0.27, 0.8), 2.0)
		draw_line(r.position + Vector2(1, 1), r.position + Vector2(1, SLOT_SIZE - 1),
			Color(0.45, 0.37, 0.27, 0.8), 2.0)
		draw_rect(r, Color(0.42, 0.34, 0.25, 0.95), false, 2.0)
		var it = equipment.get_slot(String(name))
		if it != null:
			_draw_item_rect_scaled(it, top + Vector2(6, 6),
				Vector2(SLOT_SIZE - 12, SLOT_SIZE - 12), false)
		else:
			# Empty slot — name ghosted in the well, Diablo-style.
			draw_string(font, top + Vector2(0, SLOT_SIZE * 0.5 + 5),
				String(name).capitalize(), HORIZONTAL_ALIGNMENT_CENTER,
				SLOT_SIZE, 12, Color(0.50, 0.42, 0.32, 0.85))

func _draw_item_in_grid(it: Dictionary) -> void:
	var rotated: bool = it.get("rotated", false)
	var fp: Vector2i = Inventory.footprint(it, rotated)
	var top := grid_origin + Vector2(int(it.pos.x) * CELL, int(it.pos.y) * CELL)
	_draw_item_rect_scaled(it, top + Vector2(PAD, PAD),
		Vector2(fp.x * CELL - PAD * 2, fp.y * CELL - PAD * 2), false)

func _draw_item_rect_scaled(it: Dictionary, top: Vector2, size: Vector2, ghost: bool) -> void:
	var r := Rect2(top, size)
	var rc: Color = RARITY_COLOR.get(String(it.rarity), Color.WHITE)
	# Rarity glow behind magic+ items (Diablo's pickup language).
	if String(it.rarity) != "normal" and not ghost:
		for i in 3:
			var g := rc
			g.a = 0.10 + 0.06 * float(2 - i)
			draw_rect(r.grow(2.0 + i * 3.0), g)
	var tex_path := String(ICON_TEX.get(String(it.get("kind_id", "")), ""))
	var tex: Texture2D = _cached_tex(tex_path)
	if tex != null:
		# Parchment plate under the painted icon.
		var plate := Color(0.95, 0.91, 0.80)
		if ghost:
			plate.a = 0.55
		draw_rect(r, plate)
		var mod := Color.WHITE
		if ghost:
			mod.a = 0.6
		draw_texture_rect(tex, r.grow(-2), false, mod)
	else:
		var fill: Color = it.get("icon_color", Color.WHITE)
		if ghost:
			fill.a = 0.55
		draw_rect(r, fill)
	if ghost:
		rc.a = 0.7
	draw_rect(r, rc, false, 3.0)

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
		"color": Color(0.42, 0.36, 0.30), "size": 11})
	lines.append({"text": "", "color": Color.WHITE, "size": 11})
	var base_stat := String(item.get("base_stat", ""))
	if base_stat != "":
		var base_aff := {"stat": base_stat, "value": item.get("base_value", 0),
			"side": "base", "display": "Base", "id": "base"}
		lines.append({"text": Affixes.format_affix(base_aff),
			"color": Color(0.23, 0.17, 0.13), "size": 12})
	for a in item.get("affixes", []):
		lines.append({"text": Affixes.format_affix(a),
			"color": Color(0.30, 0.42, 0.50), "size": 12})
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
	draw_rect(Rect2(pos, Vector2(w, h)), Color(0.93, 0.88, 0.76, 0.97))
	draw_rect(Rect2(pos, Vector2(w, h)),
		Color(0.42, 0.34, 0.25, 0.95), false, 2.0)
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
			else Color(1.00, 0.35, 0.30, 0.28)
		for dy in fp.y:
			for dx in fp.x:
				var cr := Rect2(grid_origin + Vector2((_cursor_cell.x + dx) * CELL,
					(_cursor_cell.y + dy) * CELL), Vector2(CELL, CELL))
				draw_rect(cr, pc)
	# The ghost follows the cursor.
	var ghost_top := _cursor_screen - Vector2(fp.x * CELL * 0.5, fp.y * CELL * 0.5)
	_draw_item_rect_scaled(_held_item, ghost_top + Vector2(PAD, PAD),
		Vector2(fp.x * CELL - PAD * 2, fp.y * CELL - PAD * 2), true)

# ---- Wyrd: tabs + the Satchel / Charts pages ----
func _draw_tabs(win: Rect2) -> void:
	var font: Font = WyrdUi.font_header()
	if font == null:
		font = get_theme_default_font()
	# Painted tab icons — preloaded in _ready, safe to draw_texture_rect here.
	# Icons were always cached but never rendered; wiring them up now so the
	# row reads as storybook glyphs, not a plain text menu.
	const ICON_SZ := 18.0
	for i in TABS.size():
		var r := _tab_rect(i)
		var active := i == _tab
		# Spec 40 — plates with painted icons; active = brighter + terracotta underline.
		draw_rect(r, Color(0.95, 0.91, 0.80) if active else Color(0.85, 0.78, 0.64))
		draw_rect(r, Color(0.42, 0.34, 0.25, 0.95), false, 1.5)
		if active:
			draw_line(r.position + Vector2(2, r.size.y - 2),
				r.position + Vector2(r.size.x - 2, r.size.y - 2),
				WyrdUi.TERRACOTTA, 3.0)
		var tex: Texture2D = _cached_tex(TAB_ICONS[i])
		if tex != null:
			var iy := r.position.y + (r.size.y - ICON_SZ) * 0.5
			var ix := r.position.x + 8.0
			draw_texture_rect(tex,
				Rect2(Vector2(ix, iy), Vector2(ICON_SZ, ICON_SZ)),
				false, Color(1, 1, 1, 1.0 if active else 0.55))
			draw_string(font, Vector2(ix + ICON_SZ + 3.0, r.position.y + 22.0),
				String(TABS[i]), HORIZONTAL_ALIGNMENT_CENTER,
				r.end.x - (ix + ICON_SZ + 3.0) - 6.0, 16,
				WyrdUi.INK if active else WyrdUi.INK_MID)
		else:
			draw_string(font, r.position + Vector2(0, 22), String(TABS[i]),
				HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 16,
				WyrdUi.INK if active else WyrdUi.INK_MID)

# ---- Spec 45 followup: drawn-page scrolling (Satchel / Charts / Trades) ----
# The pack window is a fixed 644×604 panel but the list pages grew past it
# (the trades' unlock grids, a mid-game satchel). Each page scrolls: content
# draws translated by -scroll, spans fully outside the page are skipped, and
# parchment strips repainted from the ninepatch hide the partial rows that
# slide under the header / footer bands.
const SCROLL_STEP := 44.0
var _tab_scroll: Dictionary = {}      # tab index -> scroll offset (px)
var _tab_content_h: Dictionary = {}   # tab index -> content height (set in draw)

# The scrolled-page viewport between the tab row and the footer band. The
# bands above/below stay deeper (72px+) than the tallest single element a
# page draws (the trade emblem cluster) so skipped spans never peek past.
func _view_rect(win: Rect2) -> Rect2:
	return Rect2(win.position.x + 40.0, win.position.y + 110.0,
		win.size.x - 84.0, win.size.y - 222.0)

func _scroll_offset(tab: int, view: Rect2) -> float:
	var max_s: float = maxf(0.0,
		float(_tab_content_h.get(tab, 0.0)) - view.size.y)
	var s: float = clampf(float(_tab_scroll.get(tab, 0.0)), 0.0, max_s)
	_tab_scroll[tab] = s
	return s

func _scroll_tab(delta: float) -> void:
	if _tab == 0:
		return
	var view := _view_rect(_win_rect())
	var s := _scroll_offset(_tab, view)
	var max_s: float = maxf(0.0,
		float(_tab_content_h.get(_tab, 0.0)) - view.size.y)
	var next := clampf(s + delta, 0.0, max_s)
	if next != s:
		_tab_scroll[_tab] = next
		queue_redraw()

# True when a content-space span [y0, y1] intersects the view — anything
# fully outside is skipped; the page masks hide partial leaks at the edges.
func _span_visible(y0: float, y1: float, scroll: float, view: Rect2) -> bool:
	return y1 - scroll >= view.position.y and y0 - scroll <= view.end.y

# Repaint the page's own parchment over the bands above/below the view —
# each strip maps back into the ninepatch centre so it lands pixel-identical
# to what the stylebox drew there, warm wash included.
func _draw_page_masks(win: Rect2, view: Rect2) -> void:
	var l := win.position.x + 36.0
	var w := win.size.x - 72.0
	_draw_page_patch(win, Rect2(l, win.position.y + WyrdUi.PANEL_MARGIN_T,
		w, view.position.y - (win.position.y + WyrdUi.PANEL_MARGIN_T)))
	_draw_page_patch(win, Rect2(l, view.end.y,
		w, (win.end.y - WyrdUi.PANEL_MARGIN_B) - view.end.y))

func _draw_page_patch(win: Rect2, r: Rect2) -> void:
	var tex: Texture2D = _cached_tex(WyrdUi.PANEL_TEX_PATH)
	if tex == null:
		draw_rect(r, Color(0.93, 0.88, 0.76, 1.0))
	else:
		# Same mapping the stylebox uses: window centre -> texture centre.
		var dst := Rect2(
			win.position + Vector2(WyrdUi.PANEL_MARGIN_L, WyrdUi.PANEL_MARGIN_T),
			win.size - Vector2(WyrdUi.PANEL_MARGIN_L + WyrdUi.PANEL_MARGIN_R,
				WyrdUi.PANEL_MARGIN_T + WyrdUi.PANEL_MARGIN_B))
		var src := Rect2(
			Vector2(WyrdUi.PANEL_MARGIN_L, WyrdUi.PANEL_MARGIN_T),
			Vector2(float(tex.get_width()) - (WyrdUi.PANEL_MARGIN_L
					+ WyrdUi.PANEL_MARGIN_R),
				float(tex.get_height()) - (WyrdUi.PANEL_MARGIN_T
					+ WyrdUi.PANEL_MARGIN_B)))
		var px_ratio := src.size / dst.size
		draw_texture_rect_region(tex, r,
			Rect2(src.position + (r.position - dst.position) * px_ratio,
				r.size * px_ratio))
	# Re-apply the warm wash the page carries (drawn at win.grow(-26)).
	draw_rect(r, Color(0.91, 0.85, 0.70, 0.45))

# A slim sage runner along the right edge marks the place in the page, and
# the footer carries the hint — both only when there is more to read.
func _draw_scroll_marker(win: Rect2, view: Rect2, font: Font) -> void:
	var content_h: float = float(_tab_content_h.get(_tab, 0.0))
	if content_h <= view.size.y:
		return
	var track := Rect2(Vector2(win.end.x - 52.0, view.position.y),
		Vector2(4.0, view.size.y))
	draw_rect(track, Color(WyrdUi.KIT_EDGE, 0.18))
	var th: float = maxf(34.0, track.size.y * view.size.y / content_h)
	var max_s: float = maxf(1.0, content_h - view.size.y)
	var s: float = float(_tab_scroll.get(_tab, 0.0))
	var thumb := Rect2(Vector2(track.position.x - 1.5,
		track.position.y + (track.size.y - th) * (s / max_s)),
		Vector2(7.0, th))
	draw_rect(thumb, WyrdUi.SAGE.darkened(0.08))
	draw_rect(thumb, Color(WyrdUi.KIT_EDGE, 0.7), false, 1.0)
	draw_string(font, Vector2(view.position.x, view.end.y + 34.0),
		"scroll to read on · I close", HORIZONTAL_ALIGNMENT_CENTER,
		view.size.x, 13, WyrdUi.INK_MID)

func _draw_satchel_tab(win: Rect2, font: Font, scroll: float, view: Rect2) -> void:
	var game := get_tree().root.get_node_or_null("Game")
	if game == null:
		return
	var x := win.position.x + 76.0
	var w := win.size.x - 146.0
	var y := win.position.y + 114.0
	# Header.
	var hdr: Font = WyrdUi.font_header()
	if hdr == null:
		hdr = font
	if _span_visible(y - 14.0, y + 4.0, scroll, view):
		draw_string(hdr, Vector2(x, y), "Materials",
			HORIZONTAL_ALIGNMENT_LEFT, w, 18, WyrdUi.TERRACOTTA)
	y += 24.0
	var mats := (game.materials as Dictionary)
	var sorted_mats := mats.keys()
	sorted_mats.sort_custom(func(a, b): return GatherDefs.material_name(String(a)) \
		< GatherDefs.material_name(String(b)))
	for mid in sorted_mats:
		var cnt: int = int(mats[mid])
		if cnt <= 0:
			continue
		if not _span_visible(y, y + MAT_ROW_H, scroll, view):
			y += MAT_ROW_H
			continue
		var r := Rect2(Vector2(x, y), Vector2(w, MAT_ROW_H - 4.0))
		WyrdUi.draw_list_row(self, r, WyrdUi.SAGE)
		# Material glyph + name (left) and count chip (right).
		var icon := GatherDefs.material_icon(String(mid))
		draw_string(font, Vector2(r.position.x + 12.0, r.position.y + 18.0),
			"%s  %s" % [icon, GatherDefs.material_name(String(mid))],
			HORIZONTAL_ALIGNMENT_LEFT, w * 0.72, 14, WyrdUi.INK)
		draw_string(font, Vector2(r.position.x, r.position.y + 18.0),
			"×%d" % cnt, HORIZONTAL_ALIGNMENT_RIGHT, w - 12.0, 15, WyrdUi.GOLD)
		y += MAT_ROW_H
	if mats.is_empty():
		if _span_visible(y, y + MAT_ROW_H, scroll, view):
			draw_string(font, Vector2(x, y + 18.0),
				"Your pack is empty. The hollows provide.",
				HORIZONTAL_ALIGNMENT_LEFT, w, 14, WyrdUi.INK_MID)
		y += MAT_ROW_H
	y += 16.0
	# Inks section.
	if _span_visible(y - 14.0, y + 4.0, scroll, view):
		draw_string(hdr, Vector2(x, y), "Inks",
			HORIZONTAL_ALIGNMENT_LEFT, w, 18, WyrdUi.TERRACOTTA)
	y += 24.0
	var inks_found := false
	for ink_id in ChartsData.INKS:
		var n: int = game.material_count(String(ink_id))
		if n <= 0:
			continue
		inks_found = true
		if not _span_visible(y, y + MAT_ROW_H, scroll, view):
			y += MAT_ROW_H
			continue
		var r := Rect2(Vector2(x, y), Vector2(w, MAT_ROW_H - 4.0))
		WyrdUi.draw_list_row(self, r, WyrdUi.GOLD)
		draw_string(font, Vector2(r.position.x + 12.0, r.position.y + 18.0),
			GatherDefs.material_name(String(ink_id)),
			HORIZONTAL_ALIGNMENT_LEFT, w * 0.72, 14, WyrdUi.INK)
		draw_string(font, Vector2(r.position.x, r.position.y + 18.0),
			"×%d" % n, HORIZONTAL_ALIGNMENT_RIGHT, w - 12.0, 15, WyrdUi.GOLD)
		y += MAT_ROW_H
	if not inks_found:
		if _span_visible(y, y + MAT_ROW_H, scroll, view):
			draw_string(font, Vector2(x, y + 18.0),
				"No inks. Mix some at the Inscribing Table.",
				HORIZONTAL_ALIGNMENT_LEFT, w, 14, WyrdUi.INK_MID)
		y += MAT_ROW_H
	y += 16.0
	# Trophies section.
	if _span_visible(y - 14.0, y + 4.0, scroll, view):
		draw_string(hdr, Vector2(x, y), "Boss Trophies",
			HORIZONTAL_ALIGNMENT_LEFT, w, 18, WyrdUi.TERRACOTTA)
	y += 24.0
	var trophies_found := false
	for trophy_id in ChartsData.TROPHY_TO_AFFIX:
		var n2: int = game.material_count(String(trophy_id))
		if n2 <= 0:
			continue
		trophies_found = true
		if not _span_visible(y, y + MAT_ROW_H, scroll, view):
			y += MAT_ROW_H
			continue
		var r2 := Rect2(Vector2(x, y), Vector2(w, MAT_ROW_H - 4.0))
		WyrdUi.draw_list_row(self, r2, WyrdUi.TERRACOTTA)
		draw_string(font, Vector2(r2.position.x + 12.0, r2.position.y + 18.0),
			GatherDefs.material_name(String(trophy_id)),
			HORIZONTAL_ALIGNMENT_LEFT, w * 0.72, 14, WyrdUi.INK)
		draw_string(font, Vector2(r2.position.x, r2.position.y + 18.0),
			"×%d" % n2, HORIZONTAL_ALIGNMENT_RIGHT, w - 12.0, 15, WyrdUi.GOLD)
		y += MAT_ROW_H
	if not trophies_found:
		if _span_visible(y, y + MAT_ROW_H, scroll, view):
			draw_string(font, Vector2(x, y + 18.0),
				"No trophies yet. Best the dens.",
				HORIZONTAL_ALIGNMENT_LEFT, w, 14, WyrdUi.INK_MID)
		y += MAT_ROW_H
	_tab_content_h[1] = y - view.position.y

const MAT_ROW_H := 30.0

func _draw_charts_tab(win: Rect2, font: Font, scroll: float, view: Rect2) -> void:
	var game := get_tree().root.get_node_or_null("Game")
	if game == null:
		return
	var x := win.position.x + 76.0
	var w := win.size.x - 146.0
	var y := win.position.y + 114.0
	var hdr: Font = WyrdUi.font_header()
	if hdr == null:
		hdr = font
	if _span_visible(y - 14.0, y + 4.0, scroll, view):
		draw_string(hdr, Vector2(x, y), "Chart Case",
			HORIZONTAL_ALIGNMENT_LEFT, w, 18, WyrdUi.TERRACOTTA)
	y += 24.0
	var charts: Array = game.charts if game.has("charts") else []
	for chart in charts:
		if not _span_visible(y, y + CHART_ROW_H, scroll, view):
			y += CHART_ROW_H
			continue
		var r := Rect2(Vector2(x, y), Vector2(w, CHART_ROW_H - 4.0))
		# Accent by affix balance — good > bad → sage, bad > good → terracotta,
		# even → gold, no affixes → neutral.
		var goods := 0
		var bads := 0
		for a in chart.get("affixes", []):
			if bool(a.get("good", false)):
				goods += 1
			else:
				bads += 1
		var accent: Color = WyrdUi.INK_MID
		if goods > bads:
			accent = WyrdUi.SAGE
		elif bads > goods:
			accent = WyrdUi.TERRACOTTA
		elif goods > 0:
			accent = WyrdUi.GOLD
		WyrdUi.draw_list_row(self, r, accent)
		var label := ChartsData.chart_label(chart)
		draw_string(font, Vector2(r.position.x + 12.0, r.position.y + 19.0),
			label, HORIZONTAL_ALIGNMENT_LEFT, w - 24.0, 14, WyrdUi.INK)
		var tier_str := "T%d" % int(chart.get("tier", 1))
		draw_string(font, Vector2(r.position.x, r.position.y + 19.0),
			tier_str, HORIZONTAL_ALIGNMENT_RIGHT, w - 12.0, 13, WyrdUi.INK_MID)
		y += CHART_ROW_H
	if charts.is_empty():
		if _span_visible(y, y + CHART_ROW_H, scroll, view):
			draw_string(font, Vector2(x, y + 19.0),
				"Your chart case is empty. Inscribe one at the table.",
				HORIZONTAL_ALIGNMENT_LEFT, w, 14, WyrdUi.INK_MID)
		y += CHART_ROW_H
	_tab_content_h[2] = y - view.position.y

const CHART_ROW_H := 32.0

const TRADE_ROWS := [
	{"key": "wilds", "name": "Wildcraft", "glyph": "🌿",
		"color": Color(0.42, 0.62, 0.28)},
	{"key": "earth", "name": "Earthcraft", "glyph": "⛏",
		"color": Color(0.58, 0.44, 0.28)},
	{"key": "carto", "name": "Wayfinding", "glyph": "🗺",
		"color": Color(0.38, 0.52, 0.72)},
]

const CARD_H := 68.0
const CARD_GAP := 4.0

func _draw_trades_tab(win: Rect2, font: Font, scroll: float, view: Rect2) -> void:
	var game := get_tree().root.get_node_or_null("Game")
	if game == null:
		return
	var hdr: Font = WyrdUi.font_header()
	if hdr == null:
		hdr = font
	var x := win.position.x + 64.0
	var w := win.size.x - 122.0
	var y := win.position.y + 114.0
	for i in TRADE_ROWS.size():
		var row: Dictionary = TRADE_ROWS[i]
		var key := String(row.key)
		var lv: int = game.trade_lv(key)
		var cx := x + 68.0
		# The divider + emblem + name + xp-bar cluster draws as one unit; its
		# span (y-14 .. y+58) stays within the page masks' reach when skipped.
		if _span_visible(y - 14.0, y + 58.0, scroll, view):
			if i > 0:
				draw_line(Vector2(x, y - 12.0), Vector2(x + w, y - 12.0),
					Color(0.52, 0.42, 0.30, 0.45), 1.5)
			# --- emblem (60px disc, double ink ring — spec 40) ---
			var ec := Vector2(x + 26.0, y + 30.0)
			draw_circle(ec, 26.0, (row.color as Color))
			draw_arc(ec, 26.0, 0, TAU, 48, Color(0.25, 0.18, 0.12), 2.5, true)
			draw_arc(ec, 21.0, 0, TAU, 48, Color(0.97, 0.93, 0.82, 0.55), 1.2, true)
			draw_string(hdr, Vector2(ec.x - 26.0, ec.y + 8.0), String(row.glyph),
				HORIZONTAL_ALIGNMENT_CENTER, 52.0, 22, Color(0.98, 0.95, 0.86))
			# --- name + level (ink, per the design — terracotta is title-only) ---
			draw_string(hdr, Vector2(cx, y + 18.0), String(row.name),
				HORIZONTAL_ALIGNMENT_LEFT, w - 78.0, 21, WyrdUi.INK)
			draw_string(hdr, Vector2(cx, y + 20.0), "Lv %d" % lv,
				HORIZONTAL_ALIGNMENT_RIGHT, w - 78.0, 16, WyrdUi.INK)
			# --- xp bar ---
			var xp: int = int(game.trades[key].xp)
			var lo: int = game.xp_for_level(lv)
			var hi: int = game.xp_for_level(lv + 1)
			var frac := clampf(float(xp - lo) / float(max(1, hi - lo)), 0.0, 1.0)
			var bar := Rect2(Vector2(cx, y + 26.0), Vector2(w * 0.56, 12.0))
			draw_rect(bar, Color(0.80, 0.72, 0.58))
			draw_rect(Rect2(bar.position + Vector2(1, 1),
				Vector2((bar.size.x - 2.0) * frac, bar.size.y - 2.0)),
				(row.color as Color).lightened(0.12))
			draw_rect(bar, Color(0.42, 0.34, 0.25, 0.9), false, 1.5)
			draw_string(font, Vector2(bar.end.x + 10.0, y + 37.0),
				"%d / %d xp" % [xp, hi],
				HORIZONTAL_ALIGNMENT_LEFT, 120.0, 13, Color(0.30, 0.24, 0.19))
		# --- the mastery ladder (level 1→17): every perk, locked or earned ---
		var perks: Array = (game.PERKS as Dictionary).get(key, []).duplicate()
		perks.sort_custom(func(a, b): return int(a.lv) < int(b.lv))
		var earned := 0
		for p in perks:
			if lv >= int(p.lv):
				earned += 1
		var sy := y + 72.0
		if _span_visible(sy - 18.0, sy + 4.0, scroll, view):
			draw_string(hdr, Vector2(cx, sy), "Masteries",
				HORIZONTAL_ALIGNMENT_LEFT, w - 78.0, 18, WyrdUi.TERRACOTTA)
			draw_string(font, Vector2(cx, sy),
				"%d / %d earned" % [earned, perks.size()],
				HORIZONTAL_ALIGNMENT_RIGHT, w - 78.0, 13, Color(0.40, 0.34, 0.27))
		# cards march down a spine in the left gutter; the disc lights when earned
		var lx := x + 18.0
		var card_x := x + 42.0
		var card_w := w - 50.0
		var cardy := sy + 18.0
		for p in perks:
			var pl: int = int(p.lv)
			var ok: bool = lv >= pl
			if _span_visible(cardy - CARD_GAP, cardy + CARD_H + CARD_GAP, scroll, view):
				# spine segment (left gutter — cards sit to its right, never cover it)
				draw_line(Vector2(lx, cardy - CARD_GAP),
					Vector2(lx, cardy + CARD_H + CARD_GAP),
					Color(0.55, 0.62, 0.40, 0.65), 3.0)
				var cr := Rect2(Vector2(card_x, cardy), Vector2(card_w, CARD_H))
				if ok:
					draw_rect(cr, Color(0.93, 0.88, 0.74))
					draw_rect(cr, WyrdUi.SAGE.darkened(0.12), false, 2.0)
				else:
					draw_rect(cr, Color(0.78, 0.72, 0.60, 0.85))
					draw_rect(cr, Color(0.50, 0.42, 0.32, 0.7), false, 1.5)
				# node disc on the spine
				var dc := Vector2(lx, cardy + CARD_H * 0.5)
				draw_circle(dc, 12.0, WyrdUi.SAGE.darkened(0.05) if ok \
					else Color(0.62, 0.55, 0.45))
				draw_arc(dc, 12.0, 0.0, TAU, 24, Color(0.25, 0.18, 0.12), 1.5, true)
				draw_string(hdr, Vector2(dc.x - 12.0, dc.y + 6.0),
					"❖" if ok else "⚿", HORIZONTAL_ALIGNMENT_CENTER, 24.0, 13,
					Color(0.97, 0.95, 0.86) if ok else Color(0.86, 0.81, 0.73))
				# name + state tag
				draw_string(hdr, Vector2(cr.position.x + 12.0, cardy + 23.0),
					String(p.name), HORIZONTAL_ALIGNMENT_LEFT, card_w - 96.0, 16,
					WyrdUi.INK if ok else Color(0.44, 0.38, 0.31))
				draw_string(font, Vector2(cr.position.x, cardy + 21.0),
					"✓ earned" if ok else "Lv %d" % pl,
					HORIZONTAL_ALIGNMENT_RIGHT, card_w - 12.0, 13,
					WyrdUi.SAGE.darkened(0.2) if ok else Color(0.50, 0.42, 0.32))
				# description (up to two lines)
				draw_multiline_string(font, Vector2(cr.position.x + 12.0, cardy + 41.0),
					String(p.desc), HORIZONTAL_ALIGNMENT_LEFT, card_w - 24.0, 12, 2,
					Color(0.34, 0.28, 0.22) if ok else Color(0.52, 0.46, 0.39))
			cardy += CARD_H + CARD_GAP
		y = cardy + 12.0
	_tab_content_h[3] = y - view.position.y
