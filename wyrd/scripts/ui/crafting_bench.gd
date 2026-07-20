extends CanvasLayer

# Mara's physical Chart Table. This node owns only a staged draft and delegates
# every unlock, recipe, cost, discovery, and transaction decision to Charts/Game.

const ChartsData = preload("res://data/charts.gd")
const GatherDefs = preload("res://data/gather.gd")
const ChartTableViewScript = preload("res://scripts/ui/chart_table_view.gd")
const Tokens = preload("res://scripts/ui/foundation/ui_tokens.gd")
const FIELD_THEME := preload("res://themes/wayfinder_theme.tres")
const FIELD_ICON_DIR := "res://assets/ui/field_journal/icons/"

var _game: Node
var _panel: Panel
var _view: Control
var _modal_owned := false
var _closing := false
var _commit_busy := false
var _source_mode := "supplies"
var _codex_selected_id := ""
var _feedback := ""
var _feedback_error := false

var draft: Dictionary = {}
var _preview: Dictionary = {}
var pot: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 90
	_game = get_tree().root.get_node_or_null("Game")
	WyrdUi.make_backdrop(self, close)
	_panel = Panel.new()
	_panel.name = "ChartTablePanel"
	_panel.theme = FIELD_THEME
	_panel.theme_type_variation = &"JournalFrame"
	_panel.anchor_left = 0.5
	_panel.anchor_top = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_bottom = 0.5
	_panel.offset_left = -600
	_panel.offset_top = -340
	_panel.offset_right = 600
	_panel.offset_bottom = 340
	add_child(_panel)

	if _game != null and _game.has_method("ensure_chart_starter_supplies"):
		_game.ensure_chart_starter_supplies()
	if _guided_mode() == "mix":
		_source_mode = "mix"
	draft = ChartsData.empty_table_draft()
	_refresh_preview()
	_view = ChartTableViewScript.new()
	_view.name = "ChartTableView"
	_view.table = self
	_panel.add_child(_view)

	if _game != null:
		_game.modal_opened()
		_modal_owned = true
	tree_exiting.connect(_release_modal)


func _process(_delta: float) -> void:
	if _game != null and _game.has_method("_tick_onboarding_recovery"):
		_game._tick_onboarding_recovery()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_X, KEY_BACKSPACE]:
			return_focused_item()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_Y:
			if _source_mode == "mix":
				clear_pot()
			else:
				clear_draft()
			get_viewport().set_input_as_handled()
	if event is InputEventJoypadButton and event.pressed:
		match event.button_index:
			JOY_BUTTON_X:
				return_focused_item()
				get_viewport().set_input_as_handled()
			JOY_BUTTON_Y:
				if _source_mode == "mix":
					clear_pot()
				else:
					clear_draft()
				get_viewport().set_input_as_handled()
			JOY_BUTTON_LEFT_SHOULDER:
				_view.focus_region(-1)
				get_viewport().set_input_as_handled()
			JOY_BUTTON_RIGHT_SHOULDER:
				_view.focus_region(1)
				get_viewport().set_input_as_handled()


func close() -> void:
	if _closing:
		return
	_closing = true
	_release_modal()
	queue_free()


func _release_modal() -> void:
	if not _modal_owned:
		return
	_modal_owned = false
	var game := get_tree().root.get_node_or_null("Game") if is_inside_tree() else _game
	if game != null and is_instance_valid(game):
		game.modal_closed()


func _context() -> Dictionary:
	if _game != null and _game.has_method("chart_table_context"):
		return _game.chart_table_context()
	return {"level": wayfinding_level(), "known_recipe_ids": []}


func _refresh_preview() -> void:
	_preview = ChartsData.preview_table(draft, _context())
	var normalized: Dictionary = _preview.get("normalized_draft", {})
	if not normalized.is_empty() and String(_preview.get("state", "")) != "invalid":
		draft = normalized.duplicate(true)


func _apply_candidate(candidate: Dictionary) -> bool:
	if is_read_only():
		_set_feedback(read_only_reason(), true)
		return false
	var candidate_preview: Dictionary = ChartsData.preview_table(candidate, _context())
	if String(candidate_preview.get("state", "invalid")) == "invalid":
		_set_feedback(String(candidate_preview.get("reason",
			"Those marks do not settle here.")), true)
		return false
	draft = (candidate_preview.get("normalized_draft", candidate) as Dictionary).duplicate(true)
	_preview = candidate_preview
	_set_feedback("", false)
	_refresh_view()
	return true


func place_component(slot: String, component_id: String) -> bool:
	var candidate := draft.duplicate(true)
	var grid: Dictionary = (candidate.get("grid", {}) as Dictionary).duplicate()
	grid[slot] = component_id
	candidate["grid"] = grid
	return _apply_candidate(candidate)


func place_ink(ink_id: String, index: int = -1) -> bool:
	var candidate := draft.duplicate(true)
	var rail: Array = (candidate.get("ink_rail", []) as Array).duplicate()
	if index < 0:
		index = _first_open_ink_index(rail)
	if index < 0:
		_set_feedback("Every open Ink pot is already filled.", true)
		return false
	while rail.size() <= index:
		rail.append("")
	rail[index] = ink_id
	candidate["ink_rail"] = rail
	return _apply_candidate(candidate)


func activate_supply(id: String) -> void:
	if id == "":
		return
	if _source_mode == "mix":
		pot_add(id)
		return
	if is_read_only():
		_set_feedback(read_only_reason(), true)
		return
	if _remaining(id) <= 0:
		if ChartsData.COMPONENTS.has(id) and _game != null \
				and _game.has_method("buy_chart_component"):
			var bought = _game.buy_chart_component(id, 1)
			if not bool(bought):
				_set_feedback("That supply is not in reach just now.", true)
				return
		else:
			_set_feedback("There are none left in the Satchel.", true)
			return
	if ChartsData.INKS.has(id):
		place_ink(id)
		return
	var kind := "seal" if ChartsData.is_chart_seal(id) else \
		String(ChartsData.COMPONENTS.get(id, {}).get("kind", ""))
	var slot := _first_open_slot(kind, id)
	if slot == "":
		_set_feedback("No open %s well can take that." % kind.capitalize(), true)
		return
	place_component(slot, id)


func activate_cell(slot: String) -> void:
	var grid: Dictionary = draft.get("grid", {})
	if not grid.has(slot):
		if _source_mode == "codex" and _codex_selected_id != "" \
				and not _known_ghost_draft().is_empty():
			stage_codex_ghost("grid", slot)
			return
		var state := slot_view_state(slot)
		if not bool(state.get("unlocked", false)):
			_set_feedback("That carving opens at Wayfinding %d." %
				int(state.get("level", 1)), true)
		else:
			_set_feedback("Choose a %s from the Satchel." %
				String(state.get("kind", "supply")).capitalize(), false)
		return
	var candidate := draft.duplicate(true)
	var next_grid: Dictionary = (candidate.get("grid", {}) as Dictionary).duplicate()
	next_grid.erase(slot)
	candidate["grid"] = next_grid
	_apply_candidate(candidate)


func activate_ink(index: int) -> void:
	var rail: Array = draft.get("ink_rail", [])
	if index >= rail.size() or String(rail[index]) == "":
		if _source_mode == "codex" and _codex_selected_id != "" \
				and not _known_ghost_draft().is_empty():
			stage_codex_ghost("ink", index)
			return
		var state := ink_view_state(index)
		if not bool(state.get("unlocked", false)):
			_set_feedback("That Ink pot opens at Wayfinding %d." %
				int(state.get("level", 1)), true)
		else:
			_set_feedback("Choose an Ink from the Satchel.", false)
		return
	var candidate := draft.duplicate(true)
	var next_rail: Array = (candidate.get("ink_rail", []) as Array).duplicate()
	next_rail[index] = ""
	candidate["ink_rail"] = next_rail
	_apply_candidate(candidate)


func return_focused_item() -> void:
	if _view == null:
		return
	var target: Dictionary = _view.focused_draft_target()
	match String(target.get("kind", "")):
		"slot": activate_cell(String(target.get("slot", "")))
		"ink": activate_ink(int(target.get("index", -1)))


func clear_draft() -> void:
	if is_read_only() or draft_is_empty():
		return
	draft = ChartsData.empty_table_draft()
	_refresh_preview()
	_set_feedback("The loose makings return to the Satchel.", false)
	_refresh_view()


func inscribe_chart() -> bool:
	if _commit_busy or _game == null:
		return false
	if is_read_only():
		_set_feedback(read_only_reason(), true)
		return false
	_commit_busy = true
	var result: Dictionary = _game.try_inscribe_chart(draft,
		String(_preview.get("fingerprint", "")))
	_commit_busy = false
	if not bool(result.get("ok", false)):
		if result.has("preview"):
			_preview = (result.preview as Dictionary).duplicate(true)
		_set_feedback(String(result.get("reason", "The line would not take.")), true)
		return false
	if _view != null and _view.has_method("play_stamp"):
		_view.play_stamp(String((result.get("chart", {}) as Dictionary)
			.get("name", "Chart")))
	draft = ChartsData.empty_table_draft()
	_refresh_preview()
	_set_feedback("The seal settles. The finished Chart slips into your Case.", false)
	_refresh_view()
	return true


# Compatibility name for older callers while the physical verb is now
# consistently presented as Inscribe Chart.
func craft() -> bool:
	return inscribe_chart()


func _first_open_slot(kind: String, component_id: String = "") -> String:
	var unlocks: Dictionary = _preview.get("unlocks", ChartsData.table_unlocks(_context()))
	var grid_unlocks: Dictionary = unlocks.get("grid", {})
	var placed: Dictionary = draft.get("grid", {})
	for slot_v in ChartsData.TABLE_SLOT_ORDER:
		var slot := String(slot_v)
		var rule: Dictionary = grid_unlocks.get(slot, {})
		if bool(rule.get("unlocked", false)) and String(rule.get("kind", "")) == kind \
				and not placed.has(slot):
			# Later milestones can open a second cell of the same kind before any
			# current recipe can use it. Prefer the first placement that keeps a
			# valid experiment possible instead of letting visual grid order make
			# an ordinary supply press snap back (WF10: nw before Deep Hollow's n).
			if component_id == "":
				return slot
			var candidate := draft.duplicate(true)
			var candidate_grid := placed.duplicate()
			candidate_grid[slot] = component_id
			candidate["grid"] = candidate_grid
			var candidate_preview := ChartsData.preview_table(candidate, _context())
			if String(candidate_preview.get("state", "invalid")) != "invalid":
				return slot
	return ""


func _first_open_ink_index(rail: Array) -> int:
	var unlocks: Dictionary = _preview.get("unlocks", ChartsData.table_unlocks(_context()))
	var records: Array = unlocks.get("ink_rail", [])
	for record_v in records:
		var record: Dictionary = record_v
		var index := int(record.get("index", -1))
		if bool(record.get("unlocked", false)) \
				and (index >= rail.size() or String(rail[index]) == ""):
			return index
	return -1


func slot_view_state(slot: String) -> Dictionary:
	var unlocks: Dictionary = _preview.get("unlocks", ChartsData.table_unlocks(_context()))
	var rule: Dictionary = (unlocks.get("grid", {}) as Dictionary).get(slot, {})
	var id := String((draft.get("grid", {}) as Dictionary).get(slot, ""))
	var metadata: Dictionary = ChartsData.COMPONENTS.get(id, {})
	if ChartsData.TROPHY_TO_AFFIX.has(id):
		metadata = {"name": GatherDefs.material_name(id), "kind": "seal",
			"icon_shape": "seal"}
	var state := {
		"id": id,
		"name": String(metadata.get("name", "")),
		"kind": String(rule.get("kind", "")),
		"icon_shape": String(metadata.get("icon_shape", rule.get("kind", "unknown"))),
		"unlocked": bool(rule.get("unlocked", false)),
		"level": int(rule.get("level", 1)),
		"milestone": String(rule.get("milestone", "")),
		"tooltip": String(metadata.get("description", "")),
	}
	if id == "":
		var ghost_grid: Dictionary = _known_ghost_draft().get("grid", {})
		var ghost_id := String(ghost_grid.get(slot, ""))
		if ghost_id != "":
			var ghost_meta: Dictionary = ChartsData.COMPONENTS.get(ghost_id, {})
			state["ghost"] = true
			state["ghost_id"] = ghost_id
			state["ghost_name"] = String(ghost_meta.get("name", supply_name(ghost_id)))
			state["icon_shape"] = String(ghost_meta.get("icon_shape", state.icon_shape))
			state["ghost_available"] = bool(state.unlocked) and not is_read_only() \
				and _remaining(ghost_id) > 0
			state["tooltip"] = _ghost_tooltip(ghost_id, bool(state.ghost_available),
				bool(state.unlocked), int(state.level))
	return state


func ink_view_state(index: int) -> Dictionary:
	var unlocks: Dictionary = _preview.get("unlocks", ChartsData.table_unlocks(_context()))
	var records: Array = unlocks.get("ink_rail", [])
	var rule: Dictionary = records[index] if index >= 0 and index < records.size() else {}
	var rail: Array = draft.get("ink_rail", [])
	var id := String(rail[index]) if index >= 0 and index < rail.size() else ""
	var metadata: Dictionary = ChartsData.INKS.get(id, {})
	var state := {
		"id": id,
		"name": String(metadata.get("name", "")),
		"kind": "ink",
		"icon_shape": String(metadata.get("icon_shape", "ink")),
		"unlocked": bool(rule.get("unlocked", false)),
		"level": int(rule.get("level", 1)),
		"tooltip": String(metadata.get("desc", "")),
	}
	if id == "":
		var ghost_rail: Array = _known_ghost_draft().get("ink_rail", [])
		var ghost_id := String(ghost_rail[index]) if index >= 0 \
			and index < ghost_rail.size() else ""
		if ghost_id != "":
			state["ghost"] = true
			state["ghost_id"] = ghost_id
			state["ghost_name"] = supply_name(ghost_id)
			state["icon_shape"] = "ink"
			state["ghost_available"] = bool(state.unlocked) and not is_read_only() \
				and _remaining(ghost_id) > 0
			state["tooltip"] = _ghost_tooltip(ghost_id, bool(state.ghost_available),
				bool(state.unlocked), int(state.level))
	return state


# Slice C adapter: the data module owns every knowledge-state classification,
# redaction decision, and exact known draft. The panel only renders the result.
func codex_pages() -> Array:
	return ChartsData.codex_entries(_context())


func open_codex_page(recipe_id: String) -> bool:
	for page_v in codex_pages():
		var page: Dictionary = page_v
		if String(page.get("recipe_id", page.get("id", ""))) == recipe_id:
			_codex_selected_id = recipe_id
			_refresh_view()
			return true
	return false


func close_codex_page() -> void:
	_codex_selected_id = ""
	_refresh_view()


func selected_codex_page() -> Dictionary:
	if _codex_selected_id == "":
		return {}
	return ChartsData.codex_entry(_codex_selected_id, _context())


func _known_ghost_draft() -> Dictionary:
	var page := selected_codex_page()
	if String(page.get("state", "unknown")) != "known":
		return {}
	var ghost: Dictionary = page.get("ghost_draft", {})
	if not ghost.is_empty():
		return ghost.duplicate(true)
	return ChartsData.known_draft(_codex_selected_id, _context())


func stage_codex_ghost(kind: String, key) -> bool:
	if is_read_only():
		_set_feedback(read_only_reason(), true)
		return false
	var ghost := _known_ghost_draft()
	if ghost.is_empty():
		return false
	var candidate := draft.duplicate(true)
	var ghost_id := ""
	if kind == "grid":
		var slot := String(key)
		ghost_id = String((ghost.get("grid", {}) as Dictionary).get(slot, ""))
		var candidate_grid: Dictionary = (candidate.get("grid", {}) as Dictionary).duplicate()
		if ghost_id == "" or candidate_grid.has(slot):
			return false
		candidate_grid[slot] = ghost_id
		candidate["grid"] = candidate_grid
	elif kind == "ink":
		var index := int(key)
		var ghost_rail: Array = ghost.get("ink_rail", [])
		ghost_id = String(ghost_rail[index]) if index >= 0 and index < ghost_rail.size() else ""
		var candidate_rail: Array = (candidate.get("ink_rail", []) as Array).duplicate()
		if ghost_id == "":
			return false
		while candidate_rail.size() <= index:
			candidate_rail.append("")
		if String(candidate_rail[index]) != "":
			return false
		candidate_rail[index] = ghost_id
		candidate["ink_rail"] = candidate_rail
	else:
		return false
	if not _candidate_stock_available(candidate):
		_set_feedback("The Satchel lacks %s. Nothing has moved." % supply_name(ghost_id), true)
		return false
	return _apply_candidate(candidate)


func stage_all_known_recipe() -> bool:
	if is_read_only():
		_set_feedback(read_only_reason(), true)
		return false
	if wayfinding_level() < 3:
		_set_feedback("Practiced Measures opens at Wayfinding 3.", true)
		return false
	var ghost := _known_ghost_draft()
	if ghost.is_empty():
		return false
	var candidate := draft.duplicate(true)
	var candidate_grid: Dictionary = (candidate.get("grid", {}) as Dictionary).duplicate()
	for slot_v in (ghost.get("grid", {}) as Dictionary):
		var slot := String(slot_v)
		var wanted := String((ghost.grid as Dictionary)[slot_v])
		var present := String(candidate_grid.get(slot, ""))
		if present != "" and present != wanted:
			_set_feedback("%s already holds another choice. Nothing has moved." %
				String(slot).to_upper(), true)
			return false
		candidate_grid[slot] = wanted
	candidate["grid"] = candidate_grid
	var candidate_rail: Array = (candidate.get("ink_rail", []) as Array).duplicate()
	var ghost_rail: Array = ghost.get("ink_rail", [])
	for ink_id_v in ghost_rail:
		var ink_id := String(ink_id_v)
		if ink_id == "":
			continue
		var already_needed := candidate_rail.count(ink_id)
		var target_needed := ghost_rail.count(ink_id)
		if already_needed >= target_needed:
			continue
		var open_index := _first_open_ink_index(candidate_rail)
		if open_index < 0:
			_set_feedback("No open Ink pot can take the known measure. Nothing has moved.", true)
			return false
		while candidate_rail.size() <= open_index:
			candidate_rail.append("")
		candidate_rail[open_index] = ink_id
	candidate["ink_rail"] = candidate_rail
	if not _candidate_stock_available(candidate):
		_set_feedback("The Satchel is missing part of the known measure. Nothing has moved.", true)
		return false
	var candidate_preview: Dictionary = ChartsData.preview_table(candidate, _context())
	if String(candidate_preview.get("state", "invalid")) == "invalid":
		_set_feedback(String(candidate_preview.get("reason",
			"The known measure will not fit. Nothing has moved.")), true)
		return false
	if not _apply_candidate(candidate):
		return false
	_set_feedback("Mara lays out the known measures. The seal is still yours to press.", false)
	return true


func can_offer_stage_all() -> bool:
	return not is_read_only() and wayfinding_level() >= 3 \
		and not _known_ghost_draft().is_empty()


func _candidate_stock_available(candidate: Dictionary) -> bool:
	var claimed := pot.duplicate()
	for id_v in (candidate.get("grid", {}) as Dictionary).values():
		var id := String(id_v)
		claimed[id] = int(claimed.get(id, 0)) + 1
	for id_v in candidate.get("ink_rail", []):
		var id := String(id_v)
		if id != "":
			claimed[id] = int(claimed.get(id, 0)) + 1
	for id_v in claimed:
		var id := String(id_v)
		if int(claimed[id_v]) > supply_count(id):
			return false
	return true


func _ghost_tooltip(id: String, available: bool, unlocked: bool, level: int) -> String:
	if is_read_only():
		return read_only_reason()
	if not unlocked:
		return "This carving opens at Wayfinding %d." % level
	if available:
		return "Set %s from the Satchel." % supply_name(id)
	return "The Satchel lacks %s." % supply_name(id)


func source_rows(mode: String) -> Array:
	var rows: Array = []
	if mode == "codex":
		return codex_pages()
	if mode == "mix":
		for id_v in GatherDefs.MATERIALS:
			var id := String(id_v)
			if (GatherDefs.is_ink(id) and not _is_authored_ink_ingredient(id)) \
					or ChartsData.is_protected_chart_supply(id) \
					or _remaining(id) <= 0:
				continue
			rows.append(_source_row(id, GatherDefs.material_name(id),
				GatherDefs.material_icon_path(id), "material"))
		return rows
	var renewable_component_ids := ChartsData.component_supply_ids(_context())
	for id_v in ChartsData.component_stageable_ids(_context()):
		var id := String(id_v)
		var metadata: Dictionary = ChartsData.COMPONENTS.get(id, {})
		var price := int(ChartsData.component_supply_price(id))
		var label := String(metadata.get("name", id.capitalize()))
		if _remaining(id) <= 0 and renewable_component_ids.has(id) and price > 0:
			label += " · %dg" % price
		rows.append(_source_row(id, label, "",
			String(metadata.get("icon_shape", metadata.get("kind", "unknown")))))
	for id_v in ChartsData.INKS:
		var id := String(id_v)
		if _remaining(id) > 0:
			rows.append(_source_row(id, String(ChartsData.INKS[id].name), "", "ink"))
	for id_v in ChartsData.TROPHY_TO_AFFIX:
		var id := String(id_v)
		if _remaining(id) > 0:
			rows.append(_source_row(id, GatherDefs.material_name(id), "", "seal"))
	for id_v in ChartsData.STORY_SEALS:
		var id := String(id_v)
		if _remaining(id) > 0:
			rows.append(_source_row(id, String(ChartsData.STORY_SEALS[id].name), "", "seal"))
	return rows


func _is_authored_ink_ingredient(material_id: String) -> bool:
	for ink_id_v in GatherDefs.INK_RECIPE_ORDER:
		var recipe: Dictionary = GatherDefs.INK_RECIPES.get(String(ink_id_v), {})
		if (recipe.get("inputs", {}) as Dictionary).has(material_id):
			return true
	return false


func _source_row(id: String, label: String, _texture_path: String,
		icon_shape: String) -> Dictionary:
	var count := _remaining(id)
	var purchasable := ChartsData.component_supply_ids(_context()).has(id) \
		and int(ChartsData.component_supply_price(id)) > 0
	return {
		"id": id,
		"label": label,
		"count": maxi(0, count),
		"available": not is_read_only() and (count > 0 or purchasable),
		"icon_shape": icon_shape,
		"icon_path": _field_icon_path(id, _texture_path),
		"description": String(ChartsData.COMPONENTS.get(id, {}).get("description",
			ChartsData.INKS.get(id, {}).get("desc", ""))),
	}


func _field_icon_path(id: String, fallback: String = "") -> String:
	var icon_name: String = String({
		"wild_herb": "wild_herb",
		"bogiron_ore": "bogiron_ore",
		"logs": "logs",
		"hearth_draught": "hearth_draught",
		"quickroot_tonic": "quickroot_tonic",
		"hedge_ink": "hedge_ink",
		"stoneground_ink": "hedge_ink",
		"refined_ink": "refined_ink",
		"practice_leaf": "chart_base",
		"field_parchment": "chart_base",
		"stitched_parchment": "chart_base",
		"waxed_vellum": "chart_base",
		"atlas_folio": "codex",
		"hedge_sprig": "hedge_sprig",
		"loop_cord": "loop_cord",
	}.get(id, ""))
	if icon_name == "" and ChartsData.is_chart_seal(id):
		icon_name = "wax_seal"
	var candidate := FIELD_ICON_DIR + String(icon_name) + ".png" \
		if icon_name != "" else fallback
	return candidate if candidate != "" and ResourceLoader.exists(candidate) else fallback


func _remaining(id: String) -> int:
	var have := supply_count(id)
	var claimed := 0
	for placed_id in (draft.get("grid", {}) as Dictionary).values():
		if String(placed_id) == id:
			claimed += 1
	for placed_id in draft.get("ink_rail", []):
		if String(placed_id) == id:
			claimed += 1
	claimed += int(pot.get(id, 0))
	return have - claimed


func supply_count(id: String) -> int:
	return 0 if _game == null else int(_game.material_count(id))


func supply_name(id: String) -> String:
	if ChartsData.COMPONENTS.has(id):
		return String(ChartsData.COMPONENTS[id].name)
	if ChartsData.INKS.has(id):
		return String(ChartsData.INKS[id].name)
	return GatherDefs.material_name(id)


func affix_name(id: String) -> String:
	return String(ChartsData.AFFIXES.get(id, {}).get("name",
		id.replace("_", " ").capitalize()))


func affix_roll_order() -> Array:
	return ChartsData.AFFIX_ROLL_ORDER


func current_preview() -> Dictionary:
	return _preview


func can_commit_current() -> bool:
	if is_read_only() or _game == null or not bool(_preview.get("commit_ready", false)):
		return false
	if _game.chart_case_full():
		return false
	return bool(_game.can_afford(_preview.get("costs", {})))


func action_block_reason() -> String:
	if is_read_only():
		return read_only_reason()
	if not bool(_preview.get("commit_ready", false)):
		return String(_preview.get("reason", "The road is unfinished."))
	if _game != null and _game.chart_case_full():
		return "Your Chart Case is full."
	if _game != null and not bool(_game.can_afford(_preview.get("costs", {}))):
		return "The Satchel is missing part of the arrangement."
	return "Press Mara's seal into this Chart."


func draft_is_empty() -> bool:
	return (draft.get("grid", {}) as Dictionary).is_empty() \
		and (draft.get("ink_rail", []) as Array).is_empty()


func wayfinding_level() -> int:
	return 1 if _game == null else int(_game.trade_lv("wayfinding"))


func is_read_only() -> bool:
	var context := _context()
	if bool(context.get("read_only", false)):
		return true
	var net := get_tree().root.get_node_or_null("NetGame") if is_inside_tree() else null
	var shared := _game != null and _game.has_method("net_active") \
		and bool(_game.net_active())
	return shared and net != null and net.has_method("is_host") \
		and not bool(net.is_host())


func read_only_reason() -> String:
	return String(_context().get("read_only_reason",
		"Only the fire-keeper may move supplies while you travel together."))


func table_feedback() -> String:
	if _feedback != "":
		return _feedback
	if draft_is_empty():
		return "Set a Chart Base to begin."
	var grid: Dictionary = draft.get("grid", {})
	var rail: Array = draft.get("ink_rail", [])
	if _guided_mode() == "snug":
		if not grid.has("c"):
			return "Set the Practice Leaf in the center."
		if not grid.has("n"):
			return "Now lay the Hedge Sprig above it."
		if rail.is_empty():
			return "Finish the line with Hedge Ink."
	var reason := String(_preview.get("reason", ""))
	return reason if reason != "" else "The table is listening."


func feedback_is_error() -> bool:
	return _feedback_error


func _set_feedback(value: String, error: bool) -> void:
	_feedback = value
	_feedback_error = error
	_refresh_view()


func _refresh_view() -> void:
	if _view != null and is_instance_valid(_view):
		_view.refresh()


func set_source_mode(mode: String) -> void:
	if mode != "codex":
		_codex_selected_id = ""
	_source_mode = mode


func initial_source_mode() -> String:
	return _source_mode


func _guided_mode() -> String:
	var step := 0 if _game == null else int(_game.tutorial_step)
	match step:
		2: return "mix"
		3: return "snug"
		6: return "binding"
	return ""


func _tutorial_target() -> String:
	if _game != null and _game.has_method("onboarding_hint_stage") \
			and int(_game.onboarding_hint_stage()) < 1:
		return ""
	match _guided_mode():
		"mix": return "pot"
		"snug":
			var grid: Dictionary = draft.get("grid", {})
			if not grid.has("c"): return "base"
			if not grid.has("n"): return "waymark"
			if (draft.get("ink_rail", []) as Array).is_empty(): return "ink"
			return "result"
		"binding": return "binding"
	return ""


# ---- Quill's existing ink-mixing pot ----

func pot_add(mat_id: String) -> bool:
	if is_read_only() or ChartsData.is_protected_chart_supply(mat_id) \
			or _remaining(mat_id) <= 0:
		return false
	pot[mat_id] = int(pot.get(mat_id, 0)) + 1
	for ink_id_v in GatherDefs.INK_RECIPE_ORDER:
		var ink_id := String(ink_id_v)
		var inputs: Dictionary = GatherDefs.INK_RECIPES[ink_id].inputs
		if _dict_eq(pot, inputs):
			if _game != null and _game.has_method("ink_recipe_status"):
				var status: Dictionary = _game.ink_recipe_status(ink_id)
				if not bool(status.get("unlocked", false)):
					_set_feedback("Wildcraft %d is required to settle %s." % [
						int(status.get("required_wildcraft", 1)),
						GatherDefs.material_name(ink_id)], true)
					break
			if _game != null and bool(_game.ink_discovered(ink_id)) \
					and bool(_game.mix_ink(ink_id)):
				pot.clear()
				_set_feedback("A fresh pot of %s settles." %
					GatherDefs.material_name(ink_id), false)
			break
	_refresh_view()
	return true


func try_pot_mix() -> Dictionary:
	return pot_try()


func pot_try() -> Dictionary:
	if pot.is_empty() or _game == null or is_read_only():
		return {}
	var result: Dictionary = _game.try_pot_mix(pot)
	if result.is_empty():
		return {}
	if String(result.get("outcome", "")) == "locked":
		_set_feedback("Wildcraft %d is required; the makings remain in the pot." %
			int(result.get("required_wildcraft", 1)), true)
		return result
	pot.clear()
	_set_feedback("The pot answers: %s." %
		String(result.get("outcome", "a quiet lesson")).replace("_", " "), false)
	return result


func clear_pot() -> void:
	pot.clear()
	_refresh_view()


func pot_clear() -> void:
	clear_pot()


func pot_description() -> String:
	if pot.is_empty():
		return "Mixing pot: empty"
	var parts: Array[String] = []
	for id_v in pot:
		var id := String(id_v)
		parts.append("%s ×%d" % [GatherDefs.material_name(id), int(pot[id_v])])
	return "Mixing pot: %s" % ", ".join(parts)


func pot_total() -> int:
	var total := 0
	for count_v in pot.values():
		total += int(count_v)
	return total


func mix_feedback() -> String:
	if _feedback != "":
		return _feedback
	if pot.is_empty():
		return "Choose a making from the pantry. Three Wild Herbs settle into Hedge Ink."
	return "The measure is in. Add another making or try the mix."


func mix_recipe_rows() -> Array:
	var rows: Array = []
	var hidden_count := 0
	for ink_id_v in GatherDefs.INK_RECIPE_ORDER:
		var ink_id := String(ink_id_v)
		var known := ink_id == "hedge_ink" or (_game != null \
			and bool(_game.ink_discovered(ink_id)))
		if not known:
			hidden_count += 1
			continue
		var recipe: Dictionary = GatherDefs.INK_RECIPES.get(ink_id, {})
		var measures: Array[String] = []
		for material_id_v in (recipe.get("inputs", {}) as Dictionary):
			var material_id := String(material_id_v)
			var count := int((recipe.inputs as Dictionary)[material_id_v])
			measures.append("%d× %s" % [count,
				GatherDefs.material_name(material_id)])
		rows.append({
			"name": GatherDefs.material_name(ink_id),
			"measure": " + ".join(measures),
		})
	if hidden_count > 0:
		rows.append({
			"name": "%d unrecorded mixture%s" % [hidden_count,
				"" if hidden_count == 1 else "s"],
			"measure": "Experiment carefully; the page fills when the pot answers.",
		})
	return rows


static func _dict_eq(a: Dictionary, b: Dictionary) -> bool:
	if a.size() != b.size():
		return false
	for key in b:
		if int(a.get(key, -1)) != int(b[key]):
			return false
	return true
