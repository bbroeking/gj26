class_name SaveGame
extends RefCounted

# Wyrd — session persistence. Serializes the Game autoload's cross-scene
# state (trades, satchel, chart case, tutorial step, hp, Tetris inventory,
# equipment) to user://wyrd_save.json and back. Item dicts carry Vector2i
# and Color values that JSON can't hold — those round-trip through small
# typed wrappers ({"__v2": [x,y]}, {"__col": [r,g,b,a]}).

const SAVE_PATH := "user://wayfinder_save.json"
const VERSION := 1

static func save(game: Node) -> bool:
	var data := {
		"version": VERSION,
		"trades": game.trades,
		"materials": game.materials,
		"charts": game.charts,
		"gold": game.gold,
		"summit_cleared": game.summit_cleared,
		"muted": game.muted,
		"seen_hints": game.seen_hints,
		"tutorial_step": game.tutorial_step,
		"player_hp": game.player_hp,
		"inventory": _items_out(game.inventory.items if game.inventory != null else []),
		"equipment": _equipment_out(game.equipment),
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_warning("save_game: cannot open %s for write" % SAVE_PATH)
		return false
	f.store_string(JSON.stringify(_encode(data)))
	f.close()
	return true

static func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

static func load_into(game: Node) -> bool:
	if not has_save():
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return false
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if parsed == null or not parsed is Dictionary:
		push_warning("save_game: corrupt save — starting fresh")
		return false
	var data: Dictionary = _decode(parsed)
	if int(data.get("version", 0)) != VERSION:
		push_warning("save_game: version mismatch — starting fresh")
		return false
	# Plain state.
	for key in game.trades:
		var saved: Dictionary = (data.get("trades", {}) as Dictionary).get(key, {})
		if not saved.is_empty():
			game.trades[key] = {"lv": int(saved.get("lv", 1)), "xp": int(saved.get("xp", 0))}
	game.materials = {}
	for id in data.get("materials", {}):
		game.materials[String(id)] = int(data.materials[id])
	game.charts = []
	for c in data.get("charts", []):
		game.charts.append(c)
	game.tutorial_step = int(data.get("tutorial_step", 0))
	game.player_hp = int(data.get("player_hp", -1))
	game.gold = int(data.get("gold", 0))
	game.muted = bool(data.get("muted", false))
	game.summit_cleared = bool(data.get("summit_cleared", false))
	game.seen_hints = data.get("seen_hints", {})
	# Inventory — re-place each item so the grid cells rebuild.
	game.inventory = Inventory.new()
	for item in data.get("inventory", []):
		var pos = item.get("pos", null)
		var rotated: bool = bool(item.get("rotated", false))
		item.erase("pos")
		if pos is Vector2i and game.inventory.can_place(item, pos, rotated):
			game.inventory.try_place(item, pos, rotated)
		else:
			var fit: Dictionary = game.inventory.find_first_fit(item)
			if not fit.is_empty():
				game.inventory.try_place(item, fit.pos, fit.rotated)
	# Equipment — set slots directly; one changed signal at the end.
	for slot_name in Equipment.SLOT_ORDER:
		var it = (data.get("equipment", {}) as Dictionary).get(slot_name, null)
		game.equipment.slots[slot_name] = it
	game.equipment.changed.emit()
	return true

static func clear() -> void:
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))

# ---- item serialization helpers ----

static func _items_out(items: Array) -> Array:
	var out: Array = []
	for item in items:
		out.append((item as Dictionary).duplicate(true))
	return out

static func _equipment_out(equipment) -> Dictionary:
	var out := {}
	if equipment == null:
		return out
	for slot_name in Equipment.SLOT_ORDER:
		var it = equipment.get_slot(slot_name)
		out[slot_name] = null if it == null else (it as Dictionary).duplicate(true)
	return out

# ---- JSON-safe encode/decode (Vector2i + Color wrappers) ----

static func _encode(value):
	if value is Vector2i:
		return {"__v2": [value.x, value.y]}
	if value is Color:
		return {"__col": [value.r, value.g, value.b, value.a]}
	if value is Dictionary:
		var d := {}
		for k in value:
			d[String(k)] = _encode(value[k])
		return d
	if value is Array:
		var a := []
		for v in value:
			a.append(_encode(v))
		return a
	return value

static func _decode(value):
	if value is Dictionary:
		if value.has("__v2"):
			var v: Array = value["__v2"]
			return Vector2i(int(v[0]), int(v[1]))
		if value.has("__col"):
			var c: Array = value["__col"]
			return Color(float(c[0]), float(c[1]), float(c[2]), float(c[3]))
		var d := {}
		for k in value:
			d[String(k)] = _decode(value[k])
		return d
	if value is Array:
		var a := []
		for v in value:
			a.append(_decode(v))
		return a
	return value
