class_name SaveGame
extends RefCounted

# Wyrd — session persistence. Serializes the Game autoload's cross-scene
# state (trades, satchel, chart case, tutorial step, hp, Tetris inventory,
# equipment) to user://wayfinder_save.json and back. Item dicts carry Vector2i
# and Color values that JSON can't hold — those round-trip through small
# typed wrappers ({"__v2": [x,y]}, {"__col": [r,g,b,a]}).
#
# Atomic write: save_to writes to path+".tmp" then renames over path, so a
# crash mid-write never leaves a partial file. The previous save is copied to
# path+".bak" first; load_from falls back to the .bak when the primary is
# corrupt or unparseable.
#
# VERSION increment policy:
#   - New optional field with a default: add a backfill in _migrate, no bump.
#   - Rename or remove an existing field (breaking): bump VERSION, add a
#     _migrate_to_v<N> function, call it from _migrate when version < N.

const SAVE_PATH := "user://wayfinder_save.json"

# LOAD_RESULT — used by load_from/save_to overloads and the test harness.
# load_into preserves its original bool return for backward-compat with game.gd.
enum LOAD_RESULT { OK, CORRUPT, VERSION_MISMATCH, NOT_FOUND }

const VERSION := 1

# ---- public API (signatures preserved exactly) ----

## save(game) -> bool
## Writes game state to SAVE_PATH atomically (tmp+rename). Returns false on
## write failure. Delegates to save_to.
static func save(game: Node) -> bool:
	return save_to(SAVE_PATH, game)

## load_into(game) -> bool
## Returns true iff the save was found and loaded successfully (including via
## the .bak fallback). Preserves the original bool signature so game.gd
## callers (`elif SaveGame.load_into(self):`) continue to work unchanged.
static func load_into(game: Node) -> bool:
	return load_from(SAVE_PATH, game) == LOAD_RESULT.OK

## has_save() -> bool — unchanged.
static func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

## clear() — deletes SAVE_PATH and its .bak.
static func clear() -> void:
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	var bak: String = SAVE_PATH + ".bak"
	if FileAccess.file_exists(bak):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(bak))

# ---- path-parametric overloads (used by test harness + internal) ----

## save_to(path, game) -> bool
## Writes atomically: path+".tmp" → rename to path. Copies the current file
## at path to path+".bak" before the rename so the previous save is always
## recoverable.
static func save_to(path: String, game: Node) -> bool:
	var data := {
		"version": VERSION,
		"trades": game.trades,
		"materials": game.materials,
		"charts": game.charts,
		"gold": game.gold,
		"summit_cleared": game.summit_cleared,
		"muted": game.muted,
		"loadout": game.loadout,
		"chosen_perks": game.chosen_perks,
		"ledger": game.ledger.slots if game.ledger != null else {},
		"discovered_inks": game.discovered_inks,
		"discovered_enchants": game.discovered_enchants,
		"seen_hints": game.seen_hints,
		"tutorial_step": game.tutorial_step,
		"player_hp": game.player_hp,
		"inventory": _items_out(game.inventory.items if game.inventory != null else []),
		"equipment": _equipment_out(game.equipment),
	}
	var json_str: String = JSON.stringify(_encode(data))
	var tmp_path: String = path + ".tmp"
	var f := FileAccess.open(tmp_path, FileAccess.WRITE)
	if f == null:
		push_warning("save_game: cannot open %s for write" % tmp_path)
		return false
	f.store_string(json_str)
	f.close()
	# Back up the existing save before replacing it.
	if FileAccess.file_exists(path):
		DirAccess.copy_absolute(
			ProjectSettings.globalize_path(path),
			ProjectSettings.globalize_path(path + ".bak"))
	# Atomic rename: tmp → real path.
	var err: int = DirAccess.rename_absolute(
		ProjectSettings.globalize_path(tmp_path),
		ProjectSettings.globalize_path(path))
	if err != OK:
		push_warning("save_game: rename failed (%d) — removing tmp" % err)
		DirAccess.remove_absolute(ProjectSettings.globalize_path(tmp_path))
		return false
	return true

## load_from(path, game) -> LOAD_RESULT
## Loads from path; on CORRUPT or VERSION_MISMATCH tries path+".bak" before
## returning the failure code. NOT_FOUND is returned only when both are absent.
static func load_from(path: String, game: Node) -> LOAD_RESULT:
	if not FileAccess.file_exists(path):
		return LOAD_RESULT.NOT_FOUND
	var result: LOAD_RESULT = _try_load_file(path, game)
	if result == LOAD_RESULT.OK:
		return LOAD_RESULT.OK
	# Primary failed — try the .bak fallback.
	var bak_path: String = path + ".bak"
	if FileAccess.file_exists(bak_path):
		var bak_result: LOAD_RESULT = _try_load_file(bak_path, game)
		if bak_result == LOAD_RESULT.OK:
			push_warning("save_game: primary corrupt — restored from .bak")
			return LOAD_RESULT.OK
	return result

# ---- internal helpers ----

## _try_load_file — parse and restore one file; return LOAD_RESULT.
static func _try_load_file(path: String, game: Node) -> LOAD_RESULT:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return LOAD_RESULT.NOT_FOUND
	var text: String = f.get_as_text()
	f.close()
	var parsed = JSON.parse_string(text)
	if parsed == null or not parsed is Dictionary:
		push_warning("save_game: corrupt save at %s" % path)
		return LOAD_RESULT.CORRUPT
	var data: Dictionary = _decode(parsed)
	# Run the migration chain before the version check so migrations can
	# update the version field.
	data = _migrate(data)
	if int(data.get("version", 0)) != VERSION:
		push_warning("save_game: version mismatch at %s (got %d, want %d)" % [
			path, int(data.get("version", 0)), VERSION])
		return LOAD_RESULT.VERSION_MISMATCH
	_restore_into(data, game)
	return LOAD_RESULT.OK

## _migrate — apply all versioned transforms in sequence.
## v0→v1a: collapse legacy four-trade XP into wayfinding.
## v0→v1b: seed three base inks for pre-spec-43 saves.
## Future migrations: add _migrate_to_vN(data) and call here when version < N.
static func _migrate(data: Dictionary) -> Dictionary:
	# v0 → v1a: collapse legacy four-trade XP into wayfinding.
	var trades_d: Dictionary = data.get("trades", {}) as Dictionary
	if not trades_d.has("wayfinding"):
		var total := 0
		for legacy: String in ["carto", "earth", "wilds", "hunt"]:
			total += int((trades_d.get(legacy, {}) as Dictionary).get("xp", 0))
		# Store raw XP; _restore_into re-derives the level via game.xp_for_level.
		data["_legacy_wayfinding_xp"] = total
	# v0 → v1b: seed three base inks for pre-spec-43 saves.
	if not data.has("discovered_inks"):
		data["discovered_inks"] = ["hedge_ink", "stoneground_ink", "refined_ink"]
	# v0 → v1c: backfill the skills-on-items `enchants` array on items from
	# pre-spec-47 saves. Consumers all read .get("enchants", []) so this is
	# belt-and-braces, but it keeps the invariant explicit (save policy:
	# optional field + default → backfill in _migrate, no VERSION bump).
	for item in (data.get("inventory", []) as Array):
		if item is Dictionary and not (item as Dictionary).has("enchants"):
			(item as Dictionary)["enchants"] = []
	for slot_v in (data.get("equipment", {}) as Dictionary).values():
		if slot_v is Dictionary and not (slot_v as Dictionary).has("enchants"):
			(slot_v as Dictionary)["enchants"] = []
	return data

## _restore_into — write the decoded+migrated dict back into game state.
static func _restore_into(data: Dictionary, game: Node) -> void:
	# Trades.
	for key: String in game.trades:
		var saved: Dictionary = (data.get("trades", {}) as Dictionary).get(key, {})
		if not saved.is_empty():
			game.trades[key] = {"lv": int(saved.get("lv", 1)), "xp": int(saved.get("xp", 0))}
	# Apply the legacy-trade migration if flagged by _migrate.
	if data.has("_legacy_wayfinding_xp"):
		var total: int = int(data["_legacy_wayfinding_xp"])
		var w: Dictionary = game.trades["wayfinding"]
		w.xp = total
		w.lv = 1
		while w.lv < int(game.LEVEL_CAP) and total >= int(game.xp_for_level(w.lv + 1)):
			w.lv += 1
	game.materials = {}
	for id: String in data.get("materials", {}):
		game.materials[String(id)] = int(data.materials[id])
	game.charts = []
	for c in data.get("charts", []):
		game.charts.append(c)
	game.tutorial_step = int(data.get("tutorial_step", 0))
	game.player_hp = int(data.get("player_hp", -1))
	game.gold = int(data.get("gold", 0))
	game.muted = bool(data.get("muted", false))
	var lo: Array = data.get("loadout", [])
	if lo.size() == 3:
		game.loadout = lo
	game.summit_cleared = bool(data.get("summit_cleared", false))
	# ADR 0012 mastery picks. Old saves (pre-mastery) auto-grant the first
	# perk at each choice tier already reached, so no perk is silently lost;
	# a retroactive re-pick flow is a follow-up.
	game.chosen_perks = {}
	if data.has("chosen_perks"):
		for id: String in data.get("chosen_perks", {}):
			game.chosen_perks[String(id)] = bool(data.chosen_perks[id])
	else:
		var lv: int = int(game.trades[game.SKILL].lv)
		for cl in game.MASTERY_CHOICE_LVS:
			if lv >= int(cl):
				var at: Array = game.perks_at_level(int(cl))
				if not at.is_empty():
					game.chosen_perks[String(at[0].id)] = true
	# ADR 0013 — restore the boss-trophy ledger.
	if game.ledger != null and data.has("ledger"):
		game.ledger.load_slots(data.get("ledger", {}))
	game.seen_hints = data.get("seen_hints", {})
	# Spec 43 — discovered_inks (backfill already applied by _migrate).
	game.discovered_inks = []
	for id in data.discovered_inks:
		game.discovered_inks.append(String(id))
	# Skills-on-items — discovered rare/unique charms. Optional field (default
	# []), so old saves load clean without a version bump.
	game.discovered_enchants = []
	for id in data.get("discovered_enchants", []):
		game.discovered_enchants.append(String(id))
	# Inventory — re-place each item so the grid cells rebuild. Grow the pack to
	# the loaded level FIRST so items saved in the extra row(s) place correctly.
	game.inventory = Inventory.new()
	if game.has_method("grow_pack_for_level"):
		game.grow_pack_for_level()
	for item: Dictionary in data.get("inventory", []):
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
	for slot_name: String in Equipment.SLOT_ORDER:
		var it = (data.get("equipment", {}) as Dictionary).get(slot_name, null)
		game.equipment.slots[slot_name] = it
	game.equipment.changed.emit()

# ---- item serialization helpers ----

static func _items_out(items: Array) -> Array:
	var out: Array = []
	for item: Dictionary in items:
		out.append((item as Dictionary).duplicate(true))
	return out

static func _equipment_out(equipment) -> Dictionary:
	var out := {}
	if equipment == null:
		return out
	for slot_name: String in Equipment.SLOT_ORDER:
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
