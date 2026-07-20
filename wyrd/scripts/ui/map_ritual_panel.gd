class_name MapRitualPanel
extends CanvasLayer

# Parchment surface for the later Threefold Loom ritual.  This file only
# presents a Game-owned view and forwards the one explicit host action.  It
# deliberately owns no campaign, Thread, source, multiplayer, or save policy.

const Tokens = preload("res://scripts/ui/foundation/ui_tokens.gd")
const FocusPointer = preload("res://scripts/ui/components/focus_pointer.gd")
const FIELD_THEME := preload("res://themes/wayfinder_theme.tres")

const FALLBACK_REQUIREMENTS := [
	{"id": "fire_in_the_bough", "label": "Fire in the Bough cleared"},
	{"id": "lost_waymarks", "label": "Five Lost Waymarks returned", "required": 5},
	{"id": "past_thread", "label": "Past Thread kept"},
	{"id": "present_thread", "label": "Present Thread kept"},
	{"id": "wayfinding_23", "label": "Wayfinding level 23"},
]

# The physical source can hand us the view it just read. Refresh always asks
# Game again, so a stale world prompt cannot be mistaken for permission.
var initial_view: Dictionary = {}
var game_override: Node = null

var _game: Node = null
var _shell: PanelContainer
var _body: VBoxContainer
var _trace_button: Button
var _status: Label
var _view: Dictionary = {}
var _modal_owned := false
var _tracing := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 95
	_game = game_override if game_override != null else get_tree().root.get_node_or_null("Game")
	WyrdUi.make_backdrop(self, _close)
	_build_shell()
	_open_modal()
	tree_exiting.connect(_release_modal)
	_connect_refreshes()
	_refresh()
	var pointer := FocusPointer.new()
	pointer.name = "MapRitualFocusPointer"
	add_child(pointer)


func _open_modal() -> void:
	if _game != null and _game.has_method("modal_opened"):
		_game.call("modal_opened")
		_modal_owned = true


func _release_modal() -> void:
	if not _modal_owned:
		return
	_modal_owned = false
	if _game != null and is_instance_valid(_game) and _game.has_method("modal_closed"):
		_game.call("modal_closed")


func _connect_refreshes() -> void:
	if _game == null:
		return
	for signal_name in [&"story_changed", &"chart_knowledge_changed"]:
		if _game.has_signal(signal_name):
			var callback := Callable(self, "_refresh")
			if not _game.is_connected(signal_name, callback):
				_game.connect(signal_name, callback)
	var net := get_tree().root.get_node_or_null("NetGame")
	if net != null and net.has_signal("settlement_view_changed"):
		var net_callback := Callable(self, "_refresh")
		if not net.is_connected("settlement_view_changed", net_callback):
			net.connect("settlement_view_changed", net_callback)


func _build_shell() -> void:
	_shell = PanelContainer.new()
	_shell.name = "MapRitualShell"
	_shell.theme = FIELD_THEME
	_shell.theme_type_variation = &"WalnutFrame"
	_shell.anchor_left = 0.5
	_shell.anchor_top = 0.5
	_shell.anchor_right = 0.5
	_shell.anchor_bottom = 0.5
	var viewport := get_viewport().get_visible_rect().size
	var size := Vector2(minf(760.0, viewport.x - Tokens.SAFE_GUTTER * 2.0),
		minf(660.0, viewport.y - Tokens.SAFE_GUTTER * 2.0))
	_shell.offset_left = -size.x * 0.5
	_shell.offset_right = size.x * 0.5
	_shell.offset_top = -size.y * 0.5
	_shell.offset_bottom = size.y * 0.5
	add_child(_shell)
	var paper := PanelContainer.new()
	paper.name = "MapRitualPaper"
	paper.theme_type_variation = &"PaperSurface"
	_shell.add_child(paper)
	_body = VBoxContainer.new()
	_body.name = "MapRitualBody"
	_body.add_theme_constant_override("separation", Tokens.SPACE_3)
	paper.add_child(_body)


func _refresh() -> void:
	_view = _request_view()
	_render()


func _request_view() -> Dictionary:
	var fallback := {
		"phase": "waiting", "read_only": true, "can_trace": false,
		"map_recorded": false, "knowledge_complete": false,
		"loom_state": "dormant", "requirements": FALLBACK_REQUIREMENTS.duplicate(true),
		"reason": "The Loom is quiet for now.",
	}
	if _game == null:
		return fallback
	var raw: Variant = {}
	if _game.has_method("threefold_loom_view"):
		raw = _game.call("threefold_loom_view")
	elif _game.has_method("map_ritual_view"):
		raw = _game.call("map_ritual_view")
	elif not initial_view.is_empty():
		raw = initial_view
	if not raw is Dictionary:
		return fallback
	var view := fallback.duplicate(true)
	view.merge(raw as Dictionary, true)
	if not view.get("requirements", []) is Array or (view.requirements as Array).size() != 5:
		view.requirements = FALLBACK_REQUIREMENTS.duplicate(true)
	return view


func _render() -> void:
	if _body == null:
		return
	for child in _body.get_children():
		_body.remove_child(child)
		child.queue_free()
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", Tokens.SPACE_3)
	_body.add_child(header)
	var title := Label.new()
	title.name = "Title"
	title.text = "The Map of Nine Knots"
	title.theme_type_variation = &"PageTitle"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close := Button.new()
	close.name = "CloseButton"
	close.text = "Close"
	close.tooltip_text = "Close the Loom"
	close.custom_minimum_size = Vector2(Tokens.HIT_TARGET, Tokens.HIT_TARGET)
	close.theme_type_variation = &"SecondaryButton"
	close.pressed.connect(_close)
	header.add_child(close)
	_body.add_child(HSeparator.new())
	var copy := Label.new()
	copy.name = "RitualCopy"
	copy.text = _ritual_copy()
	copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.theme_type_variation = &"Body"
	_body.add_child(copy)
	var heading := Label.new()
	heading.name = "RequirementsHeading"
	heading.text = "What the Loom remembers"
	heading.theme_type_variation = &"SectionTitle"
	_body.add_child(heading)
	var requirements := VBoxContainer.new()
	requirements.name = "MapRequirements"
	requirements.add_theme_constant_override("separation", Tokens.SPACE_2)
	_body.add_child(requirements)
	for entry_value in _view.get("requirements", FALLBACK_REQUIREMENTS):
		if entry_value is Dictionary:
			requirements.add_child(_requirement_row(entry_value as Dictionary))
	_status = Label.new()
	_status.name = "RitualStatus"
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.theme_type_variation = &"Body"
	_status.add_theme_color_override("font_color", Tokens.TERRACOTTA)
	_status.text = _status_copy()
	_status.visible = not _status.text.is_empty()
	_body.add_child(_status)
	_trace_button = Button.new()
	_trace_button.name = "TraceMapButton"
	_trace_button.custom_minimum_size = Vector2(0.0, Tokens.HIT_TARGET)
	_trace_button.theme_type_variation = &"PrimaryButton"
	_trace_button.text = _button_copy()
	# Permission is a Game-projected fact.  Never inspect NetGame here or issue
	# a guest RPC; the sole click is forwarded only when this view permits it.
	_trace_button.disabled = _tracing or bool(_view.get("read_only", true)) \
		or not _action_allowed()
	_trace_button.pressed.connect(_on_trace_map)
	_body.add_child(_trace_button)
	if _trace_button.is_inside_tree():
		_trace_button.grab_focus()


func _requirement_row(entry: Dictionary) -> Control:
	var row := PanelContainer.new()
	row.name = "Requirement_%s" % String(entry.get("id", "record"))
	row.theme_type_variation = &"PaperRaised"
	var contents := HBoxContainer.new()
	contents.add_theme_constant_override("separation", Tokens.SPACE_3)
	row.add_child(contents)
	var label := Label.new()
	label.name = "RequirementLabel"
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.theme_type_variation = &"Body"
	var text := String(entry.get("label", entry.get("id", "A remembered mark")))
	var have: Variant = entry.get("have", entry.get("current", null))
	var required: Variant = entry.get("required", entry.get("need", null))
	if have != null and required != null:
		text += " — %d/%d" % [int(have), int(required)]
	elif entry.has("met"):
		text += " — %s" % ("kept" if bool(entry.met) else "awaiting")
	label.text = text
	contents.add_child(label)
	return row


func _ritual_copy() -> String:
	match String(_view.get("phase", "waiting")):
		"map_recorded":
			if bool(_view.get("can_repair_knowledge", false)):
				return "The Map is safe in the Loom, but Mara's Codex entry needs its proper line restored."
			return "The nine roads hold together. Mara's Chart Table now keeps their final witness."
		"ritual_ready":
			return "The five roads, two Threads, and your Wayfinding now meet at one quiet line."
		_:
			return "The first folio has settled. The Loom waits for the roads that can be remembered together."


func _status_copy() -> String:
	if bool(_view.get("read_only", false)):
		return "Only the fire-keeper may trace this Map."
	if bool(_view.get("can_repair_knowledge", false)):
		return "Restore the Map's proper Codex entry before you return to Mara's Chart Table."
	if bool(_view.get("map_recorded", false)):
		return "Recorded. Go to Mara's Chart Table to set the final road."
	return String(_view.get("reason", _view.get("missing_reason", "")))


func _button_copy() -> String:
	if bool(_view.get("read_only", false)):
		return "Host traces the Map"
	if bool(_view.get("can_repair_knowledge", false)):
		return "Restore the Map's Codex entry"
	if bool(_view.get("map_recorded", false)):
		return "Map recorded — visit Mara's Chart Table"
	return "Trace the Map"


func _on_trace_map() -> void:
	if _tracing or bool(_view.get("read_only", true)) or not _action_allowed():
		return
	if _game == null or not _game.has_method("trace_threefold_loom_map"):
		_refresh()
		return
	_tracing = true
	var result: Variant = _game.call("trace_threefold_loom_map")
	_tracing = false
	if result is Dictionary and not bool((result as Dictionary).get("ok", false)):
		_view["reason"] = String((result as Dictionary).get("reason", "The Loom needs another look."))
	_refresh()


# A trusted old Map with a missing final Codex entry is the one intentional
# post-record action. It reuses Game's convergent transaction; normal recorded
# Maps stay inert and never save/notify/publish again.
func _action_allowed() -> bool:
	return bool(_view.get("can_trace", false)) \
		or bool(_view.get("can_repair_knowledge", false))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not _tracing:
		_close()
		get_viewport().set_input_as_handled()


func _close() -> void:
	if _tracing:
		return
	queue_free()
