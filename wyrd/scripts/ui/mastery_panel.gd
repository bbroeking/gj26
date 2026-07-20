class_name MasteryPanel
extends CanvasLayer

# D8 Wayweaver station presentation. This is a view + input adapter only:
# Game owns the pure preview/commit policy, placement preflight, persistence,
# inventory, equipment, and campaign mutations. Keep this boundary boring.

const Tokens = preload("res://scripts/ui/foundation/ui_tokens.gd")
const FocusPointer = preload("res://scripts/ui/components/focus_pointer.gd")
const Workbench = preload("res://scripts/ui/components/transaction_workbench.gd")

# Art is intentionally optional for this first UI lane. Consumers can replace
# these paths with authored icons without changing the requirement data shape.
const ICON_PATHS := {
	"waysteel_shard": "res://assets/ui/items/waysteel_shard.png",
	"waysteel_core": "res://assets/ui/items/waysteel_core.png",
	"waysteel_frame": "res://assets/ui/items/waysteel_frame.png",
	"root_sap": "res://assets/ui/items/root_sap.png",
	"root_sap_cord": "res://assets/ui/items/root_sap_cord.png",
	"threefold_draught": "res://assets/ui/items/threefold_draught.png",
	"wayweaver_string": "res://assets/ui/items/wayweaver_string.png",
	"quiet_tooth": "res://assets/ui/items/quiet_tooth.png",
	"quiet_tooth_grip": "res://assets/ui/items/quiet_tooth_grip.png",
	"wayweaver": "res://assets/ui/items/wayweaver.png",
}

const STATION_TITLES := {
	"hod_mastery": "Hod's Master Forge",
	"quill_mastery": "Quill's Rootwork Still",
	"awake_loom": "The Awake Loom",
	"master_hunt": "The Master Hunt",
	"master_forge": "The Master Forge",
}

@export var station_id := "hod_mastery"
@export var action_id := "waysteel_core"

# A test/integration seam. Production leaves this null and the panel finds the
# autoload. It is not an authority replacement.
var game_override: Node = null

var _game: Node = null
var _workbench: TransactionWorkbench
var _components_leaf: VBoxContainer
var _ritual_leaf: VBoxContainer
var _result_leaf: VBoxContainer
var _commit_button: Button
var _keep_button: Button
var _equip_button: Button
var _reason_label: Label
var _preview: Dictionary = {}
var _destination := "keep"
var _committing := false
var _modal_owned := false
var _rune_buttons: Array[Button] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 95
	_game = game_override if game_override != null else get_tree().root.get_node_or_null("Game")
	WyrdUi.make_backdrop(self, _close)
	_build_shell()
	_open_modal()
	tree_exiting.connect(_release_modal)
	_refresh_preview()
	var pointer := FocusPointer.new()
	pointer.name = "TransactionFocusPointer"
	add_child(pointer)


func _open_modal() -> void:
	if _game != null and _game.has_method("modal_opened"):
		_game.modal_opened()
		_modal_owned = true


func _release_modal() -> void:
	if not _modal_owned:
		return
	_modal_owned = false
	if _game != null and is_instance_valid(_game) and _game.has_method("modal_closed"):
		_game.modal_closed()


func _build_shell() -> void:
	_workbench = Workbench.new()
	_workbench.anchor_left = 0.5
	_workbench.anchor_top = 0.5
	_workbench.anchor_right = 0.5
	_workbench.anchor_bottom = 0.5
	_workbench.offset_left = -520.0
	_workbench.offset_top = -325.0
	_workbench.offset_right = 520.0
	_workbench.offset_bottom = 325.0
	_workbench.close_requested.connect(_close)
	add_child(_workbench)
	_components_leaf = _workbench.add_leaf("MasterworkPiecesLeaf", 0.32)
	_ritual_leaf = _workbench.add_leaf("AssemblyLeaf", 0.39)
	_result_leaf = _workbench.add_leaf("FinalMeasureLeaf", 0.29)
	_workbench.add_footer_hint("←→ move  ·  Enter choose  ·  Esc close")


func _refresh_preview() -> void:
	_preview = _request_preview()
	_render()


func _request_preview() -> Dictionary:
	var fallback := {
		"ok": false,
		"enabled": false,
		"station_id": station_id,
		"action_id": action_id,
		"title": STATION_TITLES.get(station_id, "Masterwork"),
		"description": "This work awaits its proper record.",
		"requirements": [],
		"kept_records": [],
		"missing_reason": "This station is not ready yet.",
	}
	if _game == null or not _game.has_method("wayweaver_preview"):
		return fallback
	var raw = _game.call("wayweaver_preview", station_id, action_id)
	if not raw is Dictionary:
		return fallback
	var preview := fallback.duplicate(true)
	preview.merge(raw as Dictionary, true)
	# API implementors may call this either enabled, can_commit, or available;
	# normalize it once at the presentation edge without inventing policy.
	if preview.has("can_commit"):
		preview.enabled = bool(preview.can_commit)
	elif preview.has("available"):
		preview.enabled = bool(preview.available)
	else:
		preview.enabled = bool(preview.get("enabled", preview.get("ok", false)))
	return preview


func _render() -> void:
	_keep_button = null
	_equip_button = null
	_commit_button = null
	_rune_buttons.clear()
	for leaf in [_components_leaf, _ritual_leaf, _result_leaf]:
		for child in leaf.get_children():
			leaf.remove_child(child)
			child.queue_free()
	_workbench.setup(String(STATION_TITLES.get(station_id, "Masterwork")),
		"Tend the Root Runes" if _is_tending() \
		else String(_preview.get("title", "A masterwork waits at the bench.")), _result_texture())
	_build_components_leaf()
	_build_ritual_leaf()
	_build_result_leaf()
	_focus_initial.call_deferred()


func _build_components_leaf() -> void:
	var requirements_title := Label.new()
	requirements_title.text = "In Your Keeping" if _is_tending() else "The Offering"
	requirements_title.theme_type_variation = &"SectionTitle"
	_components_leaf.add_child(requirements_title)
	var requirements_hint := Label.new()
	requirements_hint.text = "The three pieces have become one Wayweaver." if _is_tending() \
		else "These pieces are spent when the work is sealed."
	requirements_hint.theme_type_variation = &"RowSubtitle"
	requirements_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_components_leaf.add_child(requirements_hint)
	_components_leaf.add_child(HSeparator.new())
	if not _is_tending():
		var requirements := VBoxContainer.new()
		requirements.name = "ComponentRequirements"
		requirements.add_theme_constant_override("separation", 6)
		_components_leaf.add_child(requirements)
		for requirement_value in _preview.get("requirements", []):
			if requirement_value is Dictionary \
					and not _is_kept_requirement(requirement_value as Dictionary) \
					and _is_component_requirement(requirement_value as Dictionary):
				requirements.add_child(_requirement_row(requirement_value as Dictionary))
		if requirements.get_child_count() == 0:
			var none := Label.new()
			none.text = "The station has not listed its components yet."
			none.theme_type_variation = &"Body"
			requirements.add_child(none)

	_components_leaf.add_child(HSeparator.new())
	var witness_title := Label.new()
	witness_title.text = "Kept Witnesses"
	witness_title.theme_type_variation = &"SectionTitle"
	_components_leaf.add_child(witness_title)
	var kept := _kept_records()
	var kept_row := Label.new()
	kept_row.name = "KeptRecordRow"
	kept_row.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	kept_row.theme_type_variation = &"RowSubtitle"
	kept_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	kept_row.custom_minimum_size.x = 260.0
	kept_row.text = "Kept record — None named yet." if kept.is_empty() \
		else "Kept record\n✓ %s" % "\n✓ ".join(kept)
	var kept_scroll := ScrollContainer.new()
	kept_scroll.name = "KeptRecordScroll"
	kept_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	kept_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	kept_scroll.add_child(kept_row)
	_components_leaf.add_child(kept_scroll)


func _build_ritual_leaf() -> void:
	var heading := Label.new()
	heading.text = "The Wayweaver" if _is_tending() else "The Masterwork"
	heading.theme_type_variation = &"SectionTitle"
	_ritual_leaf.add_child(heading)
	var art_center := CenterContainer.new()
	art_center.custom_minimum_size.y = 226.0
	_ritual_leaf.add_child(art_center)
	var art := TextureRect.new()
	art.name = "MasterworkArt"
	art.custom_minimum_size = Vector2(230.0, 220.0)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.texture = _result_texture()
	art_center.add_child(art)
	var title := Label.new()
	title.name = "Title"
	title.text = "Wayweaver in Your Keeping" if _is_tending() \
		else String(_preview.get("title", "Masterwork"))
	title.theme_type_variation = &"PageTitle"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ritual_leaf.add_child(title)
	var description := Label.new()
	description.name = "Description"
	description.text = "One Root Rune may color its strand without changing its road." if _is_tending() \
		else String(_preview.get("description", ""))
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description.theme_type_variation = &"Body"
	_ritual_leaf.add_child(description)
	var gate := Label.new()
	gate.name = "MasteryGate"
	gate.text = "◆ Root Runes are kept, never spent." if _is_tending() \
		else "◆ %s" % _gate_text()
	gate.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	gate.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gate.theme_type_variation = &"RowSubtitle"
	_ritual_leaf.add_child(gate)
	var witness_count := Label.new()
	witness_count.name = "WitnessCount"
	witness_count.text = "Witnesses kept · %d" % _kept_records().size()
	witness_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	witness_count.theme_type_variation = &"RowSubtitle"
	witness_count.add_theme_color_override("font_color", Tokens.GOLD_MUTED.darkened(0.18))
	_ritual_leaf.add_child(witness_count)


func _build_result_leaf() -> void:
	var heading := Label.new()
	heading.text = "Root Rune" if _is_tending() else ("The Keeping" if _is_final_forge() else "The Making")
	heading.theme_type_variation = &"SectionTitle"
	_result_leaf.add_child(heading)
	var hint := Label.new()
	hint.text = "Changes strand color and motes only; no Skill or weapon effect." if _is_tending() \
		else ("Choose where the finished bow will rest." if _is_final_forge() \
		else "The station rechecks every piece before it begins.")
	hint.theme_type_variation = &"RowSubtitle"
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_result_leaf.add_child(hint)
	_result_leaf.add_child(HSeparator.new())
	if _is_tending():
		_build_rune_choice()
	elif _is_final_forge():
		_build_destination_choice()

	_reason_label = Label.new()
	_reason_label.name = "MissingReason"
	_reason_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_reason_label.theme_type_variation = &"Body"
	var ready := bool(_preview.get("enabled", false))
	_reason_label.add_theme_color_override("font_color",
		Tokens.SAGE.darkened(0.28) if ready else Tokens.TERRACOTTA)
	_reason_label.visible = not _is_tending()
	_reason_label.text = "Ready — the offered pieces will be spent." if ready \
		else String(_preview.get("missing_reason", _preview.get("reason", "")))
	_result_leaf.add_child(_reason_label)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_result_leaf.add_child(spacer)
	if _is_tending():
		return
	_commit_button = Button.new()
	_commit_button.name = "CommitButton"
	_commit_button.text = String(_preview.get("action_label", "Make the masterwork"))
	_commit_button.tooltip_text = "Recheck every requirement, then complete this work."
	_commit_button.custom_minimum_size = Vector2(0, Tokens.HIT_TARGET)
	_commit_button.theme_type_variation = &"PrimaryButton"
	_commit_button.disabled = not bool(_preview.get("enabled", false)) or _committing
	_commit_button.pressed.connect(_on_commit)
	_commit_button.custom_minimum_size.y = 64.0
	_result_leaf.add_child(_commit_button)


func _result_texture() -> Texture2D:
	var path := String(ICON_PATHS.get(action_id, ""))
	return load(path) as Texture2D if path != "" and ResourceLoader.exists(path) else null


func _focus_initial() -> void:
	if _commit_button != null and not _commit_button.disabled:
		if _keep_button != null:
			_keep_button.grab_focus()
		else:
			_commit_button.grab_focus()
	elif not _rune_buttons.is_empty():
		for rune_button in _rune_buttons:
			if not rune_button.disabled:
				rune_button.grab_focus()
				return
	elif _keep_button != null:
		_keep_button.grab_focus()
	elif _workbench != null:
		var close := _workbench.find_child("CloseButton", true, false) as Button
		if close != null:
			close.grab_focus()


func _requirement_row(requirement: Dictionary) -> Control:
	var row := PanelContainer.new()
	row.name = "Component_%s" % String(requirement.get("id", requirement.get("key", "record")))
	row.theme_type_variation = &"PaperRaised"
	var contents := HBoxContainer.new()
	contents.add_theme_constant_override("separation", Tokens.SPACE_3)
	row.add_child(contents)
	var icon_path := _requirement_icon_path(requirement)
	if icon_path != "" and ResourceLoader.exists(icon_path):
		var icon := TextureRect.new()
		icon.name = "ComponentIcon"
		icon.custom_minimum_size = Vector2(Tokens.HIT_TARGET, Tokens.HIT_TARGET)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture = load(icon_path)
		contents.add_child(icon)
	var label := Label.new()
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.theme_type_variation = &"Body"
	var label_text := String(requirement.get("label", requirement.get("name", requirement.get("id", "Component"))))
	var required := int(requirement.get("required", requirement.get("need", requirement.get("count", 1))))
	var have := int(requirement.get("have", requirement.get("owned", 0)))
	label_text = label_text.trim_suffix(" ×%d" % required)
	label.text = "%s\nHeld %d · Need %d" % [label_text, have, required]
	contents.add_child(label)
	var spent := Label.new()
	spent.text = "SPENDS"
	spent.theme_type_variation = &"RowSubtitle"
	spent.add_theme_color_override("font_color", Tokens.TERRACOTTA)
	spent.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	contents.add_child(spent)
	return row


func _is_component_requirement(requirement: Dictionary) -> bool:
	if String(requirement.get("material_id", "")) != "":
		return true
	var id := String(requirement.get("id", requirement.get("key", "")))
	return ICON_PATHS.has(id)


func _requirement_icon_path(requirement: Dictionary) -> String:
	var provided := String(requirement.get("icon_path", ""))
	if provided != "":
		return provided
	var id := String(requirement.get("material_id",
		requirement.get("id", requirement.get("key", ""))))
	return String(ICON_PATHS.get(id, ""))


func _kept_records() -> Array[String]:
	var values: Array[String] = []
	for key in ["kept_records", "witnesses", "permanent_records"]:
		for value in _preview.get(key, []):
			if value is Dictionary:
				values.append(String((value as Dictionary).get("label", (value as Dictionary).get("name", "Record"))))
			else:
				values.append(String(value))
	for requirement_value in _preview.get("requirements", []):
		if requirement_value is Dictionary and _is_kept_requirement(requirement_value as Dictionary):
			values.append(String((requirement_value as Dictionary).get("label", (requirement_value as Dictionary).get("id", "Record"))))
	return values


func _is_kept_requirement(requirement: Dictionary) -> bool:
	return bool(requirement.get("kept", false)) or bool(requirement.get("permanent", false)) \
		or String(requirement.get("kind", "")) == "record"


func _gate_text() -> String:
	var gate = _preview.get("mastery_gate", _preview.get("gate", ""))
	if gate is Dictionary:
		return String((gate as Dictionary).get("label", (gate as Dictionary).get("reason", "Awaiting mastery.")))
	return String(gate) if not String(gate).is_empty() else "The station will recheck this before work begins."


func _is_final_forge() -> bool:
	return station_id == "master_forge" or bool(_preview.get("final_forge", false))


func _is_tending() -> bool:
	return _is_final_forge() and not (_preview.get("rune_options", []) as Array).is_empty()


func _build_destination_choice() -> void:
	var heading := Label.new()
	heading.name = "DestinationHeading"
	heading.text = "When it is ready"
	heading.theme_type_variation = &"SectionTitle"
	_result_leaf.add_child(heading)
	var choices := VBoxContainer.new()
	choices.name = "DestinationChoices"
	choices.add_theme_constant_override("separation", 6)
	_result_leaf.add_child(choices)
	_keep_button = _destination_button("KeepButton", "Keep in pack",
		"Needs a clear 2×4 place.", "keep")
	_equip_button = _destination_button("EquipButton", "Equip now",
		"The displaced weapon needs room.", "equip")
	choices.add_child(_keep_button)
	choices.add_child(_equip_button)
	_set_destination(_destination)


func _build_rune_choice() -> void:
	var options: Array = _preview.get("rune_options", []) as Array
	if options.is_empty():
		return
	var rows := GridContainer.new()
	rows.name = "RuneBindingChoices"
	rows.columns = 3
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rows.add_theme_constant_override("separation", 6)
	_result_leaf.add_child(rows)
	for option_v in options:
		if not option_v is Dictionary:
			continue
		var option := option_v as Dictionary
		var rune_id := String(option.get("id", ""))
		var button := Button.new()
		button.name = "Rune_%s" % rune_id
		var selected := bool(option.get("selected", false))
		var owned := bool(option.get("owned", false))
		var full_label := String(option.get("label", rune_id.replace("_", " ").capitalize()))
		var short_label := full_label.replace(" Root Rune", "")
		var icon_path := String(option.get("icon_path", ""))
		var icon_texture: Texture2D = null
		if icon_path != "" and ResourceLoader.exists(icon_path):
			icon_texture = load(icon_path) as Texture2D
		button.tooltip_text = "Set this cosmetic Root Rune in Wayweaver." if owned else "This Rune has not settled into your keeping."
		button.disabled = not owned or selected
		button.custom_minimum_size = Vector2(78.0, 78.0)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.theme_type_variation = &"JournalRowSelected" if selected else &"SecondaryButton"
		button.pressed.connect(_on_select_rune.bind(rune_id))
		var rune_content := VBoxContainer.new()
		rune_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rune_content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		rune_content.alignment = BoxContainer.ALIGNMENT_CENTER
		rune_content.add_theme_constant_override("separation", 0)
		button.add_child(rune_content)
		var icon_center := CenterContainer.new()
		icon_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rune_content.add_child(icon_center)
		var icon := TextureRect.new()
		icon.name = "RuneIcon"
		icon.texture = icon_texture
		icon.custom_minimum_size = Vector2(28.0, 28.0)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_center.add_child(icon)
		var label := Label.new()
		label.text = "%s\n%s" % [short_label, "Set" if selected else ("Bind" if owned else "Locked")]
		label.theme_type_variation = &"RowSubtitle"
		label.add_theme_color_override("font_color", Tokens.TEXT_ON_DARK)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rune_content.add_child(label)
		if not owned:
			rune_content.modulate = Color(0.72, 0.70, 0.65, 1.0)
		rows.add_child(button)
		_rune_buttons.append(button)


func _on_select_rune(rune_id: String) -> void:
	if _committing or _game == null or not _game.has_method("set_wayweaver_cosmetic_rune"):
		return
	_committing = true
	var raw = _game.call("set_wayweaver_cosmetic_rune", rune_id)
	_committing = false
	var result := raw as Dictionary if raw is Dictionary else {"ok": false,
		"reason": "The Rune could not settle into Wayweaver."}
	_preview = _request_preview()
	if not bool(result.get("ok", false)):
		_preview["missing_reason"] = String(result.get("reason", "The Rune did not answer."))
	_render()


func _destination_button(node_name: String, label_text: String, description: String,
		destination: String) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = "%s\n%s" % [label_text, description]
	button.tooltip_text = description
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.custom_minimum_size = Vector2(0, 76.0)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.theme_type_variation = &"SecondaryButton"
	button.pressed.connect(_set_destination.bind(destination))
	return button


func _set_destination(destination: String) -> void:
	_destination = destination
	if _keep_button != null:
		_keep_button.text = "%s Keep in pack\nNeeds a clear 2×4 place." % ("✓" if destination == "keep" else "○")
		_keep_button.theme_type_variation = &"JournalRowSelected" if destination == "keep" else &"JournalRowButton"
	if _equip_button != null:
		_equip_button.text = "%s Equip now\nThe displaced weapon needs room." % ("✓" if destination == "equip" else "○")
		_equip_button.theme_type_variation = &"JournalRowSelected" if destination == "equip" else &"JournalRowButton"


func _on_commit() -> void:
	if _committing:
		return
	# A preview is advisory. Requery immediately before every commit so a stale
	# panel cannot promise materials, gates, or pack space that just changed.
	_refresh_preview()
	if not bool(_preview.get("enabled", false)) or _game == null \
			or not _game.has_method("commit_wayweaver"):
		return
	_committing = true
	if _commit_button != null:
		_commit_button.disabled = true
	var raw = _game.call("commit_wayweaver", station_id, action_id, _destination)
	_committing = false
	var result := raw as Dictionary if raw is Dictionary else {"ok": false,
		"reason": "The station could not confirm that work."}
	if bool(result.get("ok", false)):
		_close()
		return
	# Failed commits remain visible, explain the newly authoritative result, and
	# refresh again for its current requirements. No optimistic local mutation.
	_preview = _request_preview()
	if result.has("reason"):
		_preview.missing_reason = String(result.reason)
	_render()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if not _committing:
			_close()
		get_viewport().set_input_as_handled()


func _close() -> void:
	if _committing:
		return
	_release_modal()
	queue_free()


func is_committing() -> bool:
	return _committing
