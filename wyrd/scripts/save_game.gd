class_name SaveGame
extends RefCounted

const Progression = preload("res://data/progression.gd")
const CampaignData = preload("res://data/campaign.gd")

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

# Spec 58 Slice B — an optional, independently versioned migration marker.
# It is deliberately separate from SAVE_VERSION: older saves remain readable
# through the normal optional-field policy, while this marker prevents the
# one-time component compatibility bundle from being granted again.
const CHART_TABLE_VERSION := 1

# LOAD_RESULT — used by load_from/save_to overloads and the test harness.
# load_into preserves its original bool return for backward-compat with game.gd.
enum LOAD_RESULT { OK, CORRUPT, VERSION_MISMATCH, NOT_FOUND }

const VERSION := Progression.SAVE_VERSION

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
	var json_str := _snapshot_json(game)
	if json_str == "":
		return false
	return _write_atomic(path, json_str, true)


static func _snapshot_json(game: Node) -> String:
	var data := {
		"version": VERSION,
		"trades": Progression.normalize_trade_state(game.trades, VERSION),
		"materials": game.materials,
		"charts": game.charts,
		"gold": game.gold,
		"summit_cleared": game.summit_cleared,
		"muted": game.muted,
		"loadout": game.loadout,
		"owned_skills": game.owned_skills,
		"quick_item": game.quick_item,
		"chosen_perks": game.chosen_perks,
		"ledger": game.ledger.slots if game.ledger != null else {},
		"discovered_inks": game.discovered_inks,
		"known_chart_recipes": game.known_chart_recipes,
		"chart_recipe_journal": game.chart_recipe_journal,
		"chart_source_unlocks": game.chart_source_unlocks,
		"campaign_state": CampaignData.normalize_campaign_state(game.campaign_state),
		"chart_table_version": game.chart_table_version,
		"discovered_enchants": game.discovered_enchants,
		"seen_hints": game.seen_hints,
		"second_hand_clues": game.second_hand_clues,
		"pending_run_debrief": game.pending_run_debrief,
		"tutorial_step": game.tutorial_step,
		"player_hp": game.player_hp,
		"inventory": _items_out(game.inventory.items if game.inventory != null else []),
		"equipment": _equipment_out(game.equipment),
	}
	data = Progression.normalize_save_to_v2(data)
	if data.is_empty():
		return ""
	return JSON.stringify(_encode(data))


static func _write_atomic(path: String, json_str: String,
		backup_existing: bool) -> bool:
	var tmp_path: String = path + ".tmp"
	var f := FileAccess.open(tmp_path, FileAccess.WRITE)
	if f == null:
		push_warning("save_game: cannot open %s for write" % tmp_path)
		return false
	f.store_string(json_str)
	f.close()
	# Back up the existing save before replacing it.
	if backup_existing and FileAccess.file_exists(path):
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
## Loads from path; a corrupt primary may fall back to path+".bak". A valid
## future schema is authoritative and returns VERSION_MISMATCH without fallback.
static func load_from(path: String, game: Node) -> LOAD_RESULT:
	if not FileAccess.file_exists(path):
		return LOAD_RESULT.NOT_FOUND
	var result: LOAD_RESULT = _try_load_file(path, game)
	if result == LOAD_RESULT.OK:
		_persist_campaign_recovery(path, game)
		return LOAD_RESULT.OK
	# Only corruption may fall back. A valid future schema is authoritative and
	# must not be silently replaced by a stale v2 backup.
	if result != LOAD_RESULT.CORRUPT:
		return result
	var bak_path: String = path + ".bak"
	if FileAccess.file_exists(bak_path):
		var bak_result: LOAD_RESULT = _try_load_file(bak_path, game)
		if bak_result == LOAD_RESULT.OK:
			push_warning("save_game: primary corrupt — restored from .bak")
			_persist_campaign_recovery(path, game)
			return LOAD_RESULT.OK
	return result

static func _persist_campaign_recovery(path: String, game: Node) -> void:
	if not bool(game.get("_campaign_recovery_dirty")):
		return
	# Recovery is a one-time value transition, so the ordinary "previous primary
	# becomes backup" policy is unsafe here: it would preserve the unresolved
	# escrow in .bak and allow a later corrupt-primary fallback to refund twice.
	# Write the reconciled snapshot to the backup first and then the primary. A
	# crash at either boundary leaves at least one reconciled copy, and loading an
	# older primary simply repeats the idempotent reconciliation against the good
	# backup on the next boot.
	var json_str := _snapshot_json(game)
	if json_str != "" \
			and _write_atomic(path + ".bak", json_str, false) \
			and _write_atomic(path, json_str, false):
		game.set("_campaign_recovery_dirty", false)


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
	# Run the migration chain before the version check so v0/v1 state is
	# normalized once, purely, before touching runtime state.
	data = _migrate(data)
	if int(data.get("version", 0)) != VERSION:
		push_warning("save_game: version mismatch at %s (got %d, want %d)" % [
			path, int(data.get("version", 0)), VERSION])
		return LOAD_RESULT.VERSION_MISMATCH
	_restore_into(data, game)
	return LOAD_RESULT.OK

## _migrate — apply all versioned transforms in sequence.
## v0/v1→v2: delegate Trade and Skill ownership normalization to Progression.
## Optional fields retain their historical backfills around that pure transform.
## Future migrations: add _migrate_to_vN(data) and call here when version < N.
static func _migrate(data: Dictionary) -> Dictionary:
	var source_version := int(data.get("version", 0))
	if not Progression.supports_save_version(source_version):
		return data
	# v0 → v1b: seed three base inks for pre-spec-43 saves.
	if not data.has("discovered_inks"):
		data["discovered_inks"] = ["hedge_ink", "stoneground_ink", "refined_ink"]
	# Spec 58 Slice A — a pre-recipe save knows every legacy template its
	# restored Wayfinding level had already opened. Resolve this after Trades so
	# legacy four-trade migration and current one-Trade saves share one path.
	if not data.has("known_chart_recipes"):
		data["known_chart_recipes"] = []
		data["_backfill_chart_recipes"] = true
	# Slice C1 — supplemental recipe provenance. Missing is safe and is
	# normalized after canonical recipe knowledge has been restored.
	if not data.has("chart_recipe_journal"):
		data["chart_recipe_journal"] = {}
	# Slice C2 — only a missing field receives compatibility source unlocks.
	# An explicit empty list is meaningful and must remain empty.
	if not data.has("chart_source_unlocks"):
		data["chart_source_unlocks"] = []
		data["_backfill_chart_source_unlocks"] = true
	# Slice D1 — campaign_state is optional and independently normalized. Only a
	# missing field may infer legacy completion from durable boss-ledger proof;
	# an explicit empty/current state remains authoritative.
	if not data.has("campaign_state"):
		data["campaign_state"] = CampaignData.empty_state()
		data["_backfill_campaign_state"] = true
	# Spec 58 Slice B — absent means this save predates physical Chart Table
	# components, so restoration grants the compatibility bundle exactly once.
	if not data.has("chart_table_version"):
		data["chart_table_version"] = 0
	if not data.has("second_hand_clues"):
		data["second_hand_clues"] = []
	if not data.has("pending_run_debrief"):
		data["pending_run_debrief"] = {}
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
	return Progression.normalize_save_to_v2(data)

## _restore_into — write the decoded+migrated dict back into game state.
static func _restore_into(data: Dictionary, game: Node) -> void:
	# Trades are canonical v2 records by this point: exactly four independent
	# pools with level derived from XP.
	game.trades = Progression.normalize_trade_state(data.get("trades", {}), VERSION)
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
	game.owned_skills = Progression.canonicalize_owned_skills(data.get("owned_skills", []))
	game.loadout = Progression.canonicalize_loadout(data.get("loadout", []), game.owned_skills)
	game.quick_item = String(data.get("quick_item", ""))
	game.summit_cleared = bool(data.get("summit_cleared", false))
	# ADR 0012 mastery picks. Old saves (pre-mastery) auto-grant the first
	# perk at each choice tier already reached, so no perk is silently lost;
	# a retroactive re-pick flow is a follow-up.
	game.chosen_perks = _normalize_chosen_perks(data.get("chosen_perks", {}), game)
	# ADR 0013 — restore the boss-trophy ledger.
	if game.ledger != null and data.has("ledger"):
		game.ledger.load_slots(data.get("ledger", {}))
	# Keep the pre-normalization record through material restoration.  v3 has
	# one narrowly scoped repair for an already-consumed v2 legacy Summit
	# handoff; after normalize() the source version is intentionally gone, so
	# calling the pure transition later would make its one-time boundary
	# ambiguous.
	var raw_campaign_state = data.get("campaign_state", {})
	var restored_campaign := CampaignData.normalize_campaign_state(
		raw_campaign_state)
	var legacy_fang_credit := CampaignData.apply_legacy_summit_alpha_fang_credit(
		raw_campaign_state, game.materials)
	var inventory_target_changed := false
	for material_id_v in (legacy_fang_credit.get("material_set", {}) as Dictionary):
		var material_id := String(material_id_v)
		var target := int((legacy_fang_credit.material_set as Dictionary)[material_id_v])
		if int(game.materials.get(material_id, 0)) != target:
			game.materials[material_id] = target
			inventory_target_changed = true
	# The pure transition owns the marker and returned normalization.  It is
	# installed even when inert; missing-field First Knot inference runs after it
	# as a separate historical migration and therefore cannot be erased.
	restored_campaign = legacy_fang_credit.state
	if bool(data.get("_backfill_campaign_state", false)):
		restored_campaign = CampaignData.infer_legacy_clear(restored_campaign,
			game.ledger.slots if game.ledger != null else {},
			bool(game.summit_cleared)).state
	# Persist both a changed marker and any exact material target before the
	# normal unresumable-run reconciliation, so primary/.bak fallbacks cannot
	# replay the credit.
	if bool(legacy_fang_credit.changed) or inventory_target_changed:
		game.set("_campaign_recovery_dirty", true)
	game.campaign_state = restored_campaign
	game.seen_hints = data.get("seen_hints", {})
	game.second_hand_clues = []
	for clue_id in data.get("second_hand_clues", []):
		if game.SECOND_HAND_CLUE_IDS.has(String(clue_id)):
			game.second_hand_clues.append(String(clue_id))
	game.pending_run_debrief = data.get("pending_run_debrief", {})
	# Spec 43 — discovered_inks (backfill already applied by _migrate).
	game.discovered_inks = []
	for id in data.discovered_inks:
		game.discovered_inks.append(String(id))
	game.known_chart_recipes = []
	if bool(data.get("_backfill_chart_recipes", false)):
		var ChartsData = load("res://data/charts.gd")
		game.known_chart_recipes = ChartsData.legacy_recipe_ids_for_level(
		game.trade_lv("wayfinding"))
	else:
		var ChartsData = load("res://data/charts.gd")
		for recipe_id in data.get("known_chart_recipes", []):
			if ChartsData.CHART_RECIPES.has(String(recipe_id)) \
					and not game.known_chart_recipes.has(String(recipe_id)):
				game.known_chart_recipes.append(String(recipe_id))
	# The journal is deliberately normalized against the restored knowledge set;
	# malformed or future records cannot grant a recipe. Existing known recipes
	# without provenance receive a fill-only `legacy` marker.
	var ChartsForJournal = load("res://data/charts.gd")
	game.chart_recipe_journal = ChartsForJournal.normalize_recipe_journal(
		data.get("chart_recipe_journal", {}), game.known_chart_recipes)
	# Source unlock compatibility is entitlement, not fabricated history: it
	# never records a rumour, grants a lesson kit, teaches a recipe, or pays XP.
	var source_unlocks = data.get("chart_source_unlocks", [])
	if bool(data.get("_backfill_chart_source_unlocks", false)):
		var derived: Array = []
		var wayfinding_level: int = int(game.trade_lv("wayfinding"))
		if bool(game.seen_hints.get("tier1_completed", false)) \
				or (wayfinding_level >= 6 \
				and game.known_chart_recipes.has("green_hollow")):
			derived.append("atlas_deep_hollow")
		if wayfinding_level >= 12 and game.known_chart_recipes.has("deep_hollow"):
			derived.append("mara_sallow_reed")
		source_unlocks = derived
	game.chart_source_unlocks = ChartsForJournal.normalize_chart_source_unlocks(
		source_unlocks)
	# active_chart is intentionally not persisted, so every restored in-run
	# campaign attempt is unresumable. Refund it once and retain its terminal
	# tombstone; load_from immediately persists the reconciled state.
	if game.has_method("reconcile_unresumable_campaign_attempts"):
		game.reconcile_unresumable_campaign_attempts()
	# Existing saves had recipe knowledge but no physical Base / Waymark /
	# Binding stacks. The data authority owns the component classification and
	# returns max-per-recipe quantities, not the sum of all known recipes. It
	# excludes ink, seals/trophies, relics, and unknown recipes by contract.
	game.chart_table_version = int(data.get("chart_table_version", 0))
	if game.chart_table_version < CHART_TABLE_VERSION:
		var ChartsData = load("res://data/charts.gd")
		var bundle: Dictionary = ChartsData.compatibility_component_bundle(
			game.known_chart_recipes)
		for component_id in bundle:
			var id := String(component_id)
			game.materials[id] = int(game.materials.get(id, 0)) + int(bundle[id])
		game.chart_table_version = CHART_TABLE_VERSION
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

# v1 stored choices as {perk_id: true} because the game had one unified
# ladder. v2 nests them under their actual Trade. Preserve every valid legacy
# selection; current single-perk tiers auto-apply, but retaining the record
# keeps future multi-choice tiers and old completion data stable.
static func _normalize_chosen_perks(raw, game: Node) -> Dictionary:
	var out: Dictionary = {}
	if not raw is Dictionary:
		return out
	for trade_key in Progression.TRADE_KEYS:
		var known := {}
		for perk in game.PERKS.get(trade_key, []):
			known[String(perk.get("id", ""))] = true
		var selections: Dictionary = {}
		var nested = (raw as Dictionary).get(trade_key, {})
		if nested is Dictionary:
			for perk_id in (nested as Dictionary):
				if known.has(String(perk_id)) and bool((nested as Dictionary)[perk_id]):
					selections[String(perk_id)] = true
		# Flat v1 shape. This deliberately runs even when a trade has no nested
		# selections so an old choice cannot disappear during migration.
		for perk_id in raw:
			if known.has(String(perk_id)) and bool((raw as Dictionary)[perk_id]):
				selections[String(perk_id)] = true
		if not selections.is_empty():
			out[trade_key] = selections
	return out

# ---- item serialization helpers ----

static func _items_out(items: Array) -> Array:
	var out: Array = []
	for item: Dictionary in items:
		out.append((item as Dictionary).duplicate(true))
	return out

static func _equipment_out(equipment: Equipment) -> Dictionary:
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
