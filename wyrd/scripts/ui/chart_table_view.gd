class_name ChartTableView
extends Control

# The physical face of Mara's Chart Table. Every actionable surface is a real
# Control; the controller owns the draft and all domain calls.

const SLOT_ORDER := ["nw", "n", "ne", "w", "c", "e", "sw", "s", "se"]
const SLOT_LABELS := {
	"nw": "Waymark", "n": "Waymark", "ne": "Waymark",
	"w": "Binding", "c": "Chart Base", "e": "Binding",
	"sw": "Relic", "s": "Seal", "se": "Relic",
}
const Tokens = preload("res://scripts/ui/foundation/ui_tokens.gd")
const FocusPointer = preload("res://scripts/ui/components/focus_pointer.gd")
const FIELD_THEME := preload("res://themes/wayfinder_theme.tres")

var table: Node
var _source_mode := "supplies"
var _source_buttons: Array[Button] = []
var _slot_buttons: Dictionary = {}
var _ink_buttons: Array[Button] = []
var _region_focus: Array[Control] = []

var _source_scroll: ScrollContainer
var _source_box: VBoxContainer
var _source_header: Label
var _source_hint: Label
var _pot_box: VBoxContainer
var _pot_label: Label
var _supplies_tab: Button
var _mix_tab: Button
var _codex_button: Button
var _preview_state: Label
var _preview_title: Label
var _preview_body: RichTextLabel
var _requirements_box: VBoxContainer
var _feedback: Label
var _action: Button
var _clear: Button
var _level_label: Label
var _close: Button
var _stamp_overlay: Control
var _chart_card: Panel
var _preview_card: Panel
var _mix_center_card: Panel
var _mix_notes_card: Panel
var _mix_pot_sketch: Control
var _mix_pot_label: Label
var _mix_feedback: Label
var _mix_try: Button
var _mix_clear: Button
var _mix_recipe_box: VBoxContainer
var _keys_label: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS
	theme = FIELD_THEME
	if table != null and table.has_method("initial_source_mode"):
		_source_mode = String(table.initial_source_mode())
	_build()


func _build() -> void:
	var leaf_mark := TextureRect.new()
	leaf_mark.name = "JournalLeafMark"
	leaf_mark.position = Vector2(34, 20)
	leaf_mark.size = Vector2(44, 44)
	leaf_mark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	leaf_mark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	leaf_mark.texture = preload("res://assets/ui/field_journal/icons/wild_herb.png")
	leaf_mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(leaf_mark)
	var title := _label("Mara's Chart Table", 28, Tokens.TEXT_ON_PAPER, true)
	title.position = Vector2(78, 24)
	title.size = Vector2(440, 42)
	add_child(title)

	_level_label = _label("Wayfinding 1", 16, Tokens.TEXT_ON_PAPER_DIM, false)
	_level_label.position = Vector2(470, 34)
	_level_label.size = Vector2(180, 28)
	add_child(_level_label)

	_codex_button = _button("Mara's Codex")
	_codex_button.name = "CodexButton"
	_codex_button.position = Vector2(918, 23)
	_codex_button.size = Vector2(176, 42)
	_codex_button.set_meta("cursor_role", "codex")
	_codex_button.pressed.connect(func() -> void:
		set_source_mode("supplies" if _source_mode == "codex" else "codex"))
	add_child(_codex_button)

	_close = _button("×")
	_close.name = "CloseButton"
	_close.theme_type_variation = &"SecondaryButton"
	_close.position = Vector2(1106, 20)
	_close.size = Vector2(48, 48)
	_close.tooltip_text = "Close Chart Table"
	_close.pressed.connect(func() -> void: table.close())
	add_child(_close)

	_build_source_region()
	_build_table_region()
	_build_preview_region()
	_build_mix_regions()

	_keys_label = _label(
		"A / Enter — place  ·  X / Backspace — return  ·  Y — clear  ·  B / Esc — close",
		16, Tokens.TEXT_ON_PAPER_DIM, false)
	_keys_label.position = Vector2(40, 630)
	_keys_label.size = Vector2(900, 24)
	add_child(_keys_label)
	var focus_pointer := FocusPointer.new()
	focus_pointer.name = "ChartFocusPointer"
	add_child(focus_pointer)

	await get_tree().process_frame
	refresh()
	grab_initial_focus()


func _build_source_region() -> void:
	var card := _panel(Vector2(34, 78), Vector2(300, 548))
	add_child(card)
	_source_header = _label("Satchel & Supplies", 18, Tokens.TEXT_ON_PAPER, true)
	_source_header.position = Vector2(16, 13)
	_source_header.size = Vector2(264, 30)
	card.add_child(_source_header)

	_supplies_tab = _small_tab("Supplies")
	_supplies_tab.name = "SuppliesTab"
	_supplies_tab.position = Vector2(14, 48)
	_supplies_tab.size = Vector2(128, 48)
	_supplies_tab.pressed.connect(func() -> void: set_source_mode("supplies"))
	card.add_child(_supplies_tab)
	_mix_tab = _small_tab("Mix Ink")
	_mix_tab.name = "MixTab"
	_mix_tab.position = Vector2(150, 48)
	_mix_tab.size = Vector2(128, 48)
	_mix_tab.pressed.connect(func() -> void: set_source_mode("mix"))
	card.add_child(_mix_tab)

	_source_hint = _label("Compatible supplies appear first.", 16,
		Tokens.TEXT_ON_PAPER_DIM, false)
	_source_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_source_hint.position = Vector2(16, 104)
	_source_hint.size = Vector2(266, 38)
	card.add_child(_source_hint)

	_source_scroll = ScrollContainer.new()
	_source_scroll.name = "SupplyScroll"
	_source_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_source_scroll.position = Vector2(12, 144)
	_source_scroll.size = Vector2(276, 322)
	card.add_child(_source_scroll)
	_source_box = VBoxContainer.new()
	_source_box.name = "SupplyRows"
	_source_box.custom_minimum_size = Vector2(260, 0)
	_source_box.add_theme_constant_override("separation", 8)
	_source_scroll.add_child(_source_box)

func _build_table_region() -> void:
	var card := _panel(Vector2(350, 78), Vector2(480, 548))
	_chart_card = card
	_chart_card.name = "ChartingSurfacePanel"
	add_child(card)
	var header := _label("Charting Surface", 18, Tokens.TEXT_ON_PAPER, true)
	header.position = Vector2(16, 13)
	header.size = Vector2(240, 30)
	card.add_child(header)

	var ink_header := _label("Ink Rail", 16, Tokens.TEXT_ON_PAPER_DIM, true)
	ink_header.position = Vector2(84, 49)
	ink_header.size = Vector2(270, 22)
	ink_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(ink_header)
	var ink_row := HBoxContainer.new()
	ink_row.name = "InkRail"
	ink_row.position = Vector2(100, 72)
	ink_row.size = Vector2(280, 64)
	ink_row.add_theme_constant_override("separation", 8)
	card.add_child(ink_row)
	for index in 4:
		var ink := _ChartSocket.new()
		ink.name = "InkSlot%d" % (index + 1)
		ink.custom_minimum_size = Vector2(64, 64)
		ink.slot_id = "ink_%d" % index
		ink.family_label = "Ink %d" % (index + 1)
		ink.set_meta("draft_kind", "ink")
		ink.set_meta("ink_index", index)
		ink.pressed.connect(func() -> void: table.activate_ink(index))
		ink_row.add_child(ink)
		_ink_buttons.append(ink)

	var grid := GridContainer.new()
	grid.name = "ChartGrid"
	grid.columns = 3
	grid.position = Vector2(83, 145)
	grid.size = Vector2(314, 314)
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	card.add_child(grid)
	for slot in SLOT_ORDER:
		var cell := _ChartSocket.new()
		cell.name = "ChartSlot_%s" % slot
		cell.custom_minimum_size = Vector2(98, 98)
		cell.slot_id = slot
		cell.family_label = String(SLOT_LABELS[slot])
		cell.set_meta("draft_kind", "slot")
		cell.set_meta("slot_id", slot)
		cell.pressed.connect(func() -> void: table.activate_cell(slot))
		grid.add_child(cell)
		_slot_buttons[slot] = cell

	_feedback = _label("Set a Chart Base to begin.", 16, Tokens.TEXT_ON_PAPER, false)
	_feedback.name = "TableFeedback"
	_feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_feedback.position = Vector2(26, 463)
	_feedback.size = Vector2(428, 28)
	card.add_child(_feedback)

	_clear = _small_tab("Clear Table")
	_clear.name = "ClearTableButton"
	_clear.position = Vector2(171, 494)
	_clear.size = Vector2(138, 48)
	_clear.set_meta("cursor_role", "action")
	_clear.pressed.connect(func() -> void: table.clear_draft())
	card.add_child(_clear)


func _build_preview_region() -> void:
	var card := _panel(Vector2(846, 78), Vector2(320, 548))
	_preview_card = card
	_preview_card.name = "ChartPreviewPanel"
	add_child(card)
	var header := _label("Chart Preview", 18, Tokens.TEXT_ON_PAPER, true)
	header.position = Vector2(18, 13)
	header.size = Vector2(220, 30)
	card.add_child(header)
	_preview_state = _label("INCOMPLETE", 16, Tokens.TEXT_ON_PAPER_DIM, true)
	_preview_state.name = "PreviewState"
	_preview_state.position = Vector2(18, 53)
	_preview_state.size = Vector2(284, 22)
	card.add_child(_preview_state)
	_preview_title = _label("An unwritten road", 24, Tokens.TEXT_ON_PAPER, true)
	_preview_title.name = "PreviewTitle"
	_preview_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_preview_title.position = Vector2(18, 78)
	_preview_title.size = Vector2(284, 64)
	card.add_child(_preview_title)

	_preview_body = RichTextLabel.new()
	_preview_body.name = "PreviewBody"
	_preview_body.bbcode_enabled = true
	_preview_body.fit_content = false
	_preview_body.scroll_active = true
	_preview_body.focus_mode = Control.FOCUS_ALL
	_preview_body.add_theme_font_size_override("normal_font_size", 16)
	_preview_body.add_theme_font_size_override("bold_font_size", 16)
	_preview_body.add_theme_color_override("default_color", Tokens.TEXT_ON_PAPER)
	_preview_body.position = Vector2(18, 408)
	_preview_body.size = Vector2(284, 64)
	_preview_body.set_meta("cursor_role", "inspect_result")
	card.add_child(_preview_body)

	var sketch := _PreviewSketch.new()
	sketch.name = "PreviewSketch"
	sketch.position = Vector2(18, 144)
	sketch.size = Vector2(284, 108)
	sketch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(sketch)
	var req_title := _label("Requirements", 17, Tokens.TEXT_ON_PAPER, true)
	req_title.position = Vector2(18, 266)
	req_title.size = Vector2(284, 24)
	card.add_child(req_title)
	_requirements_box = VBoxContainer.new()
	_requirements_box.name = "Requirements"
	_requirements_box.position = Vector2(18, 296)
	_requirements_box.size = Vector2(284, 104)
	_requirements_box.add_theme_constant_override("separation", 6)
	card.add_child(_requirements_box)

	_action = _button("Inscribe Chart")
	_action.name = "InscribeChartButton"
	_action.position = Vector2(18, 480)
	_action.size = Vector2(284, 56)
	_action.set_meta("cursor_role", "action")
	_action.pressed.connect(func() -> void: table.inscribe_chart())
	card.add_child(_action)

	_stamp_overlay = _StampMark.new()
	_stamp_overlay.name = "StampOverlay"
	_stamp_overlay.position = Vector2(864, 190)
	_stamp_overlay.size = Vector2(280, 230)
	_stamp_overlay.visible = false
	_stamp_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_stamp_overlay)


func _build_mix_regions() -> void:
	# Mixing is a different verb from chart assembly, so it receives a distinct
	# workspace instead of leaving the 3×3 Chart grid sitting inert beside a tiny
	# footer pot. It occupies the same asymmetric center/right columns and keeps
	# the outer Field Journal composition stable.
	_mix_center_card = _panel(Vector2(350, 78), Vector2(480, 548))
	_mix_center_card.name = "InkMixingWorkspace"
	add_child(_mix_center_card)
	var title := _label("Quill’s Copper Pot", 22, Tokens.TEXT_ON_PAPER, true)
	title.position = Vector2(20, 16)
	title.size = Vector2(300, 32)
	_mix_center_card.add_child(title)
	var subtitle := _label("Measure the makings. Let the pot answer.", 16,
		Tokens.TEXT_ON_PAPER_DIM, false)
	subtitle.position = Vector2(20, 50)
	subtitle.size = Vector2(430, 28)
	_mix_center_card.add_child(subtitle)

	_mix_pot_sketch = _CopperPotSketch.new()
	_mix_pot_sketch.name = "CopperPotIllustration"
	_mix_pot_sketch.position = Vector2(24, 88)
	_mix_pot_sketch.size = Vector2(432, 220)
	_mix_pot_sketch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mix_center_card.add_child(_mix_pot_sketch)

	_pot_box = VBoxContainer.new()
	_pot_box.name = "MixingPotActions"
	_pot_box.position = Vector2(30, 324)
	_pot_box.size = Vector2(420, 118)
	_pot_box.add_theme_constant_override("separation", 10)
	_mix_center_card.add_child(_pot_box)
	_mix_pot_label = _label("The copper pot is empty.", 18,
		Tokens.TEXT_ON_PAPER, true)
	_mix_pot_label.name = "MixingPotContents"
	_mix_pot_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_mix_pot_label.custom_minimum_size.y = 34
	_pot_box.add_child(_mix_pot_label)
	_pot_label = _mix_pot_label
	var pot_actions := HBoxContainer.new()
	pot_actions.add_theme_constant_override("separation", 12)
	_pot_box.add_child(pot_actions)
	_mix_try = _button("Try the Mix")
	_mix_try.name = "TryMixButton"
	_mix_try.custom_minimum_size = Vector2(276, 56)
	_mix_try.set_meta("cursor_role", "action")
	_mix_try.pressed.connect(func() -> void: table.try_pot_mix())
	pot_actions.add_child(_mix_try)
	_mix_clear = _small_tab("Empty Pot")
	_mix_clear.name = "ClearPotButton"
	_mix_clear.custom_minimum_size = Vector2(132, 56)
	_mix_clear.set_meta("cursor_role", "action")
	_mix_clear.pressed.connect(func() -> void: table.clear_pot())
	pot_actions.add_child(_mix_clear)
	_mix_feedback = _label("Choose a making from the pantry.", 16,
		Tokens.TEXT_ON_PAPER_DIM, false)
	_mix_feedback.name = "MixingFeedback"
	_mix_feedback.position = Vector2(30, 462)
	_mix_feedback.size = Vector2(420, 58)
	_mix_feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_mix_center_card.add_child(_mix_feedback)

	_mix_notes_card = _panel(Vector2(846, 78), Vector2(320, 548))
	_mix_notes_card.name = "InkRecipeFolio"
	add_child(_mix_notes_card)
	var notes_title := _label("Ink Notes", 22, Tokens.TEXT_ON_PAPER, true)
	notes_title.position = Vector2(18, 16)
	notes_title.size = Vector2(284, 32)
	_mix_notes_card.add_child(notes_title)
	var notes_intro := _label(
		"Known measures are written plainly.\nUnknown ones must be learned by hand.",
		16, Tokens.TEXT_ON_PAPER_DIM, false)
	notes_intro.position = Vector2(18, 54)
	notes_intro.size = Vector2(284, 64)
	notes_intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_mix_notes_card.add_child(notes_intro)
	var divider := HSeparator.new()
	divider.position = Vector2(18, 126)
	divider.size = Vector2(284, 2)
	_mix_notes_card.add_child(divider)
	var recipes_title := _label("Mara’s Measures", 18, Tokens.TEXT_ON_PAPER, true)
	recipes_title.position = Vector2(18, 144)
	recipes_title.size = Vector2(284, 28)
	_mix_notes_card.add_child(recipes_title)
	var recipe_scroll := ScrollContainer.new()
	recipe_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	recipe_scroll.position = Vector2(14, 180)
	recipe_scroll.size = Vector2(292, 348)
	_mix_notes_card.add_child(recipe_scroll)
	_mix_recipe_box = VBoxContainer.new()
	_mix_recipe_box.custom_minimum_size = Vector2(276, 0)
	_mix_recipe_box.add_theme_constant_override("separation", 10)
	recipe_scroll.add_child(_mix_recipe_box)


func set_source_mode(mode: String) -> void:
	_source_mode = mode
	if table != null and table.has_method("set_source_mode"):
		table.set_source_mode(mode)
	refresh()
	grab_initial_focus()


func refresh() -> void:
	if table == null or not is_instance_valid(table):
		return
	_level_label.text = "Wayfinding %d" % int(table.wayfinding_level())
	_refresh_sources()
	_refresh_draft()
	_refresh_preview()
	_refresh_mix_regions()
	_rebuild_focus_graph()


func _refresh_mix_regions() -> void:
	var mixing := _source_mode == "mix"
	_keys_label.text = (
		"A / Enter — add making  ·  Y — empty pot  ·  B / Esc — close"
		if mixing else
		"A / Enter — place  ·  X / Backspace — return  ·  Y — clear  ·  B / Esc — close")
	_chart_card.visible = not mixing
	_preview_card.visible = not mixing
	_stamp_overlay.visible = false if mixing else _stamp_overlay.visible
	_mix_center_card.visible = mixing
	_mix_notes_card.visible = mixing
	if not mixing:
		return
	var description := String(table.pot_description())
	_mix_pot_label.text = "The copper pot is empty." if description.ends_with("empty") \
		else description.replace("Mixing pot:", "In the copper pot:")
	var pot_count := int(table.pot_total()) if table.has_method("pot_total") else 0
	_mix_pot_sketch.set("makings", pot_count)
	_mix_pot_sketch.queue_redraw()
	_mix_try.disabled = pot_count == 0 or table.is_read_only()
	_mix_clear.disabled = pot_count == 0 or table.is_read_only()
	var feedback := String(table.mix_feedback()) \
		if table.has_method("mix_feedback") else ""
	_mix_feedback.text = feedback if feedback != "" else (
		"Choose a making from the pantry. Three Wild Herbs settle into Hedge Ink."
		if pot_count == 0 else "The measure is in. Add another making or try the mix.")
	_mix_feedback.add_theme_color_override("font_color",
		Tokens.TERRACOTTA if table.feedback_is_error() else Tokens.TEXT_ON_PAPER_DIM)
	for child in _mix_recipe_box.get_children():
		child.queue_free()
	for row_v in table.mix_recipe_rows():
		var row: Dictionary = row_v
		var note := PanelContainer.new()
		note.theme_type_variation = &"PaperRaised"
		note.custom_minimum_size = Vector2(268, 72)
		_mix_recipe_box.add_child(note)
		var copy := VBoxContainer.new()
		copy.add_theme_constant_override("separation", 2)
		note.add_child(copy)
		var recipe_name := _label(String(row.get("name", "Unrecorded mixture")),
			17, Tokens.TEXT_ON_PAPER, true)
		copy.add_child(recipe_name)
		var measure := _label(String(row.get("measure", "Experiment at the pot.")),
			15, Tokens.TEXT_ON_PAPER_DIM, false)
		measure.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		copy.add_child(measure)


func _refresh_sources() -> void:
	for child in _source_box.get_children():
		# This region can refresh twice in one input frame (page → detail, or
		# detail → Back). Detach synchronously so stable accessibility names do
		# not collide, but defer destruction because `child` may be the Button
		# currently emitting `pressed`.
		_source_box.remove_child(child)
		child.queue_free()
	_source_buttons.clear()
	var mode := _source_mode
	var codex_open := mode == "codex"
	_source_header.text = "Mara's Codex" if codex_open else (
		"Ink Makings" if mode == "mix" else "Satchel & Supplies")
	_supplies_tab.visible = not codex_open
	_mix_tab.visible = not codex_open
	_source_hint.position.y = 48 if codex_open else 104
	_source_hint.size.y = 36 if codex_open else 38
	_source_scroll.position.y = 88 if codex_open else 144
	_source_scroll.size.y = 438 if codex_open else (382 if mode == "mix" else 322)
	_source_hint.text = "Compatible supplies appear first."
	_pot_box.visible = mode == "mix"
	if mode == "mix":
		_source_hint.text = "Choose a making to tip into the copper pot."
	elif mode == "codex":
		_source_hint.text = "Roads remembered, rumoured, and still unwritten."
		var selected: Dictionary = table.selected_codex_page()
		if not selected.is_empty():
			_build_codex_detail(selected)
			_pot_label.text = table.pot_description()
			_codex_button.button_pressed = true
			return
	for row_v in table.source_rows(mode):
		var row: Dictionary = row_v
		if mode == "codex":
			var page := _button("%s  ·  %s" % [
				String(row.get("state", "unknown")).capitalize(),
				String(row.get("label", "Unknown road"))])
			var recipe_id := String(row.get("recipe_id", row.get("id", "")))
			page.name = "CodexPage_%s" % recipe_id
			page.custom_minimum_size = Vector2(238, 54)
			page.alignment = HORIZONTAL_ALIGNMENT_LEFT
			page.add_theme_font_size_override("font_size", 16)
			page.set_meta("cursor_role", "codex_page")
			page.tooltip_text = String(row.get("summary", page.text))
			page.pressed.connect(func() -> void:
				table.open_codex_page(recipe_id)
				grab_initial_focus())
			_source_box.add_child(page)
			_source_buttons.append(page)
			continue
		var supply := _SupplyButton.new()
		supply.name = "Supply_%s" % String(row.get("id", "unknown"))
		supply.setup(row)
		var supply_id := String(row.get("id", ""))
		supply.pressed.connect(func() -> void: table.activate_supply(supply_id))
		_source_box.add_child(supply)
		_source_buttons.append(supply)
	if _source_box.get_child_count() == 0:
		var empty := _label("Nothing useful is tucked here yet.", 16,
			Tokens.TEXT_ON_PAPER_DIM, false)
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty.custom_minimum_size = Vector2(238, 54)
		_source_box.add_child(empty)
	_pot_label.text = table.pot_description()
	_supplies_tab.toggle_mode = true
	_mix_tab.toggle_mode = true
	_supplies_tab.button_pressed = mode == "supplies"
	_mix_tab.button_pressed = mode == "mix"
	_codex_button.toggle_mode = true
	_codex_button.button_pressed = mode == "codex"


func _build_codex_detail(page: Dictionary) -> void:
	var back := _small_tab("← All Codex Pages")
	back.name = "CodexBackButton"
	back.custom_minimum_size = Vector2(238, 40)
	back.set_meta("cursor_role", "codex_page")
	back.pressed.connect(func() -> void:
		table.close_codex_page()
		grab_initial_focus())
	_source_box.add_child(back)
	_source_buttons.append(back)

	var state := String(page.get("state", "unknown"))
	var title := _label(String(page.get("title", page.get("label", "An unmarked page"))),
		18, Tokens.TEXT_ON_PAPER, true)
	title.custom_minimum_size = Vector2(238, 50)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_source_box.add_child(title)
	var state_label := _label(state.to_upper(), 13,
		Tokens.TERRACOTTA if state in ["rumoured", "attemptable"] else Tokens.TEXT_ON_PAPER_DIM,
		true)
	state_label.custom_minimum_size = Vector2(238, 24)
	_source_box.add_child(state_label)

	var copy_parts: Array[String] = []
	var summary := String(page.get("summary", ""))
	if summary != "": copy_parts.append(summary)
	for clue_v in page.get("clues", []):
		copy_parts.append("• %s" % String(clue_v))
	var source := String(page.get("source", ""))
	if source != "": copy_parts.append("Source: %s" % source)
	var history = page.get("history", "")
	if history is Array:
		for history_v in history:
			var history_text := String(history_v)
			if "_" in history_text:
				history_text = history_text.replace("_", " ").capitalize()
			copy_parts.append("History: %s" % history_text)
	elif String(history) != "":
		var history_text := String(history)
		if "_" in history_text:
			history_text = history_text.replace("_", " ").capitalize()
		copy_parts.append("History: %s" % history_text)
	if state == "known":
		var ghost: Dictionary = page.get("ghost_draft", {})
		var making_names: Array[String] = []
		for making_id_v in (ghost.get("grid", {}) as Dictionary).values():
			var making_name := String(table.supply_name(String(making_id_v)))
			if not making_names.has(making_name):
				making_names.append(making_name)
		for making_id_v in ghost.get("ink_rail", []):
			var making_name := String(table.supply_name(String(making_id_v)))
			if making_name != "" and not making_names.has(making_name):
				making_names.append(making_name)
		if not making_names.is_empty():
			copy_parts.append("Known makings: %s" % " · ".join(making_names))
		copy_parts.append("Choose a pale ghost on the table to set one making.")
	elif state == "attemptable":
		copy_parts.append("The road will name itself only after you set the marks.")
	elif state == "unknown" and copy_parts.is_empty():
		copy_parts.append("Mara has left this page blank.")
	var detail := RichTextLabel.new()
	detail.name = "CodexDetail"
	detail.bbcode_enabled = false
	detail.fit_content = true
	detail.scroll_active = false
	detail.focus_mode = Control.FOCUS_ALL
	detail.custom_minimum_size = Vector2(238, 150)
	detail.add_theme_font_size_override("normal_font_size", 16)
	detail.add_theme_color_override("default_color", Tokens.TEXT_ON_PAPER)
	detail.text = "\n".join(copy_parts)
	detail.set_meta("cursor_role", "codex_page")
	_source_box.add_child(detail)

	if state == "known":
		var stage_all := _button("Stage All" if table.wayfinding_level() >= 3 \
			else "Stage All · Wayfinding 3")
		stage_all.name = "CodexStageAllButton"
		stage_all.custom_minimum_size = Vector2(238, 46)
		stage_all.disabled = not table.can_offer_stage_all()
		stage_all.tooltip_text = table.read_only_reason() if table.is_read_only() \
			else ("Practiced Measures opens at Wayfinding 3." \
			if table.wayfinding_level() < 3 else "Set every required known measure.")
		stage_all.set_meta("cursor_role", "ghost_stage" if not stage_all.disabled \
			else "ghost_unavailable")
		stage_all.pressed.connect(func() -> void:
			table.stage_all_known_recipe()
			grab_initial_focus())
		_source_box.add_child(stage_all)
		_source_buttons.append(stage_all)


func _refresh_draft() -> void:
	for slot in SLOT_ORDER:
		var cell: _ChartSocket = _slot_buttons[slot]
		var state: Dictionary = table.slot_view_state(slot)
		cell.set_state(state)
	for index in 4:
		var ink: _ChartSocket = _ink_buttons[index]
		ink.set_state(table.ink_view_state(index))
	_feedback.text = table.table_feedback()
	_feedback.add_theme_color_override("font_color",
		Tokens.TERRACOTTA if table.feedback_is_error() else Tokens.TEXT_ON_PAPER)
	_clear.disabled = table.draft_is_empty() or table.is_read_only()


func play_stamp(chart_name: String) -> void:
	if _stamp_overlay == null:
		return
	_stamp_overlay.set("chart_name", chart_name)
	_stamp_overlay.visible = true
	_stamp_overlay.modulate = Color(1, 1, 1, 0)
	_stamp_overlay.pivot_offset = _stamp_overlay.size * 0.5
	_stamp_overlay.scale = Vector2(0.78, 0.78)
	_stamp_overlay.queue_redraw()
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_parallel(true)
	tween.tween_property(_stamp_overlay, "modulate", Color.WHITE, 0.16)
	tween.tween_property(_stamp_overlay, "scale", Vector2.ONE, 0.22) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.set_parallel(false)
	tween.tween_interval(0.42)
	tween.tween_property(_stamp_overlay, "modulate", Color(1, 1, 1, 0), 0.24)
	tween.tween_callback(func() -> void: _stamp_overlay.visible = false)


func _refresh_preview() -> void:
	var preview: Dictionary = table.current_preview()
	var state := String(preview.get("state", "incomplete"))
	_preview_state.text = state.to_upper()
	var output: Dictionary = preview.get("output", {})
	if state == "known":
		_preview_title.text = String(output.get("name", "Known Chart"))
	elif state == "attemptable":
		_preview_title.text = "A road is taking shape"
	elif state == "invalid":
		_preview_title.text = "The marks do not settle"
	else:
		_preview_title.text = "An unwritten road"
	_preview_body.text = _preview_copy(preview)
	_refresh_requirements()
	_action.disabled = not table.can_commit_current()
	_action.tooltip_text = table.action_block_reason()


func _refresh_requirements() -> void:
	if _requirements_box == null:
		return
	for child in _requirements_box.get_children():
		child.free()
	var grid: Dictionary = table.draft.get("grid", {})
	var rail: Array = table.draft.get("ink_rail", [])
	var base_count := 1 if String(grid.get("c", "")) != "" else 0
	var waymark_count := 0
	for slot in SLOT_ORDER:
		var state: Dictionary = table.slot_view_state(slot)
		if String(state.get("kind", "")) == "waymark" \
				and String(state.get("id", "")) != "":
			waymark_count += 1
	var ink_count := 0
	for ink_id in rail:
		if String(ink_id) != "":
			ink_count += 1
	_add_requirement("Chart Base", base_count, 1)
	_add_requirement("Waymark", waymark_count, 1)
	_add_requirement("Ink", ink_count, 1)
	# A Seal is not another anonymous material. Once a campaign preview asks
	# for one, make the physical requirement explicit in the same focusable view
	# that explains the other four component families.
	var preview: Dictionary = table.current_preview()
	var seal_id := String((grid as Dictionary).get("s", ""))
	var returned_raw = preview.get("returned_on_failure", {})
	var has_returned_seal := (returned_raw is Dictionary and not (returned_raw as Dictionary).is_empty()) \
		or (returned_raw is Array and not (returned_raw as Array).is_empty())
	if seal_id != "" or bool(preview.get("requires_seal", false)) or has_returned_seal:
		_add_requirement("Seal", 1 if seal_id != "" else 0, 1)


func _add_requirement(label_text: String, have: int, needed: int) -> void:
	var row := HBoxContainer.new()
	_requirements_box.add_child(row)
	var mark := Label.new()
	mark.text = "✓" if have >= needed else "○"
	mark.theme_type_variation = &"Body"
	mark.add_theme_color_override("font_color", Tokens.SAGE.darkened(0.25) \
		if have >= needed else Tokens.TERRACOTTA)
	row.add_child(mark)
	var label := Label.new()
	label.text = label_text
	label.theme_type_variation = &"Body"
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	var count := Label.new()
	count.text = "%d/%d" % [have, needed]
	count.theme_type_variation = &"Numeric"
	count.add_theme_color_override("font_color", Tokens.SAGE.darkened(0.25) \
		if have >= needed else Tokens.TERRACOTTA)
	row.add_child(count)


func _preview_copy(preview: Dictionary) -> String:
	var state := String(preview.get("state", "incomplete"))
	var lines: Array[String] = []
	if table.is_read_only():
		# Guests retain the full data-owned preview—including a Deepening
		# promise—while the controller keeps the mutation action disabled.
		lines.append("[b]Read-only visit[/b]")
		lines.append(table.read_only_reason())
		lines.append("You may inspect the arrangement, but only the fire-keeper can inscribe it.")
	if table.draft_is_empty():
		lines.append("Lay down a Chart Base. The first Waymark and Ink pot will answer.")
		return "\n\n".join(lines)
	var reason := String(preview.get("reason", ""))
	if reason != "":
		lines.append(reason)
	if state == "invalid":
		lines.append("[b]Nothing will be spent.[/b]")
		return "\n\n".join(lines)
	var output: Dictionary = preview.get("output", {})
	if state == "known":
		var biome := String(output.get("biome_id", "")).replace("_", " ").capitalize()
		var topology := String(output.get("topology_id", "")).replace("_", " ").capitalize()
		if biome != "": lines.append("[b]Destination[/b]  %s" % biome)
		if topology != "": lines.append("[b]Road shape[/b]  %s" % topology)
	var preparation_notes: Array = preview.get("preparation_notes", [])
	if not preparation_notes.is_empty():
		lines.append("[b]Preparation[/b]")
		for note_v in preparation_notes:
			lines.append("  %s" % String(note_v))
	var guaranteed: Array = preview.get("guaranteed", [])
	if not guaranteed.is_empty():
		lines.append("[b]Guaranteed[/b]")
		for guarantee_v in guaranteed:
			var guarantee: Dictionary = guarantee_v
			lines.append("  %s" % String(guarantee.get("name",
				guarantee.get("id", "A promised encounter"))))
	_append_depth_contract_copy(lines, preview)
	_append_encounter_contract_copy(lines, preview)
	var returned = preview.get("returned_on_failure", {})
	if (returned is Dictionary and not (returned as Dictionary).is_empty()) \
			or (returned is Array and not (returned as Array).is_empty()):
		# A loss in the arena resets the encounter; it does not quietly refund a
		# unique story Seal. Only an explicit abandon before victory—or recovery
		# from a road that cannot resume—returns it. State that distinction here
		# because this is the player’s pre-commit decision point.
		lines.append("[b]Seal safeguard[/b]")
		lines.append("Abandon before victory—or an unresumable road—returns:")
		if returned is Dictionary:
			for item_id_v in (returned as Dictionary):
				var item_id := String(item_id_v)
				lines.append("  Returns: %d× %s" % [int((returned as Dictionary)[item_id_v]),
					table.supply_name(item_id)])
		else:
			for returned_v in (returned as Array):
				if returned_v is Dictionary:
					var item: Dictionary = returned_v
					lines.append("  Returns: %d× %s" % [int(item.get("count", 1)),
						table.supply_name(String(item.get("id", "Seal")))])
				else:
					lines.append("  Returns: %s" % table.supply_name(String(returned_v)))
		lines.append("A fall or full-party wipe resets the fight; the Seal stays staked.")
	var weights: Dictionary = preview.get("affix_weights", {})
	if state == "known" and not weights.is_empty():
		lines.append("[b]The ink may call[/b]")
		var ids: Array = weights.keys()
		if table.has_method("affix_roll_order"):
			ids = table.affix_roll_order()
		var stability: Dictionary = preview.get("stability", {})
		for id_v in ids:
			var id := String(id_v)
			if not weights.has(id):
				continue
			var name := id.replace("_", " ").capitalize()
			if table.has_method("affix_name"):
				name = table.affix_name(id)
			lines.append("  %s — roll %d%% · good twin %d%%" % [name,
				roundi(float(weights[id])), int(stability.get(id, 0))])
	# D1 previews distinguish the repeatable spend from the protected Seal. A
	# core seam that has not yet supplied `ordinary_costs` still falls back to
	# the established all-costs preview without hiding any information.
	var costs: Dictionary = preview.get("ordinary_costs", preview.get("costs", {}))
	if not costs.is_empty():
		lines.append("[b]Spent to make this road[/b]")
		for id_v in costs:
			var id := String(id_v)
			lines.append("  %d× %s  ·  have %d" % [int(costs[id_v]),
				table.supply_name(id), table.supply_count(id)])
	if bool(preview.get("commit_ready", false)):
		lines.append("\nThe line is ready for Mara's seal.")
	return "\n".join(lines)


# D2's authored-depth promise is deliberately projection-only: Charts has
# already resolved the eligible matching Binding, layer count, and final-room
# requirement. The Table must not infer any of those facts from slots or IDs.
func _append_depth_contract_copy(lines: Array[String], preview: Dictionary) -> void:
	var contract: Dictionary = preview.get("depth_contract", {})
	if contract.is_empty():
		return
	var total_layers := int(contract.get("max_layers", 0))
	var base_layers := int(contract.get("base_max_layers", 0))
	var added_layers := int(contract.get("added_layer", 0))
	var hearth_layer := int(contract.get("hearth_layer", 0))
	if total_layers <= 0 or base_layers <= 0 or added_layers <= 0 or hearth_layer <= 0:
		return
	lines.append("[b]Road depth[/b]")
	lines.append("  %d layers — base %d, added layer %d." % [
		total_layers, base_layers, added_layers])
	lines.append("  Hearth: terminal layer %d." % hearth_layer)
	lines.append("  Far Waystone: Deeper adds 1 Omen.")
	if total_layers >= 4:
		lines.append("  Four layers: a longer commitment once sealed.")


# The First Knot reprise is a normal replay, not a second campaign attempt.
# Its boss/reward wording is read from the frozen preview contract so a UI
# refresh can never invent a boss, family, refund, or trophy rule of its own.
func _append_encounter_contract_copy(lines: Array[String], preview: Dictionary) -> void:
	var contract: Dictionary = preview.get("encounter_contract", {})
	if contract.is_empty():
		return
	var boss_kind := String(contract.get("boss_kind", ""))
	var boss_layer := int(contract.get("boss_layer", 0))
	var reward_family := String(contract.get("reward_family_id", ""))
	if boss_kind != "":
		var boss_name := boss_kind.replace("_", " ").capitalize()
		if boss_kind == "hedgemother":
			boss_name = "The Hedgemother"
		lines.append("[b]Reprise encounter[/b]")
		lines.append("  Layer %d guarantees %s." % [boss_layer, boss_name])
	if reward_family != "":
		var family_name := reward_family.replace("_", " ").capitalize()
		if reward_family == "first_knot_heirlooms":
			family_name = "First-Knot Heirlooms"
		lines.append("  %s — one seeded heirloom joins the ordinary boss drops." % family_name)
	# D2's contract fixes these booleans in the domain. Copy is intentionally
	# explicit because the earlier First Knot Seal taught the opposite rule.
	if bool(contract.get("suppress_chain_trophy", false)):
		lines.append("  Thorn Essence is spent normally. This replay has no story-Seal refund or First-Knot trophy settlement.")


func grab_initial_focus() -> void:
	await get_tree().process_frame
	if not _source_buttons.is_empty() and is_instance_valid(_source_buttons[0]):
		_source_buttons[0].grab_focus()
	elif _slot_buttons.has("c"):
		(_slot_buttons.c as Control).grab_focus()


func focused_draft_target() -> Dictionary:
	var focused := get_viewport().gui_get_focus_owner()
	if focused == null or not is_ancestor_of(focused):
		return {}
	if focused.has_meta("slot_id"):
		return {"kind": "slot", "slot": String(focused.get_meta("slot_id"))}
	if focused.has_meta("ink_index"):
		return {"kind": "ink", "index": int(focused.get_meta("ink_index"))}
	return {}


func focus_region(delta: int) -> void:
	_rebuild_focus_graph()
	if _region_focus.is_empty():
		return
	var owner := get_viewport().gui_get_focus_owner()
	var index := 0
	for i in _region_focus.size():
		var root := _region_focus[i]
		if owner == root or (owner != null and root.is_ancestor_of(owner)):
			index = i
			break
	index = posmod(index + delta, _region_focus.size())
	_region_focus[index].grab_focus()


func _rebuild_focus_graph() -> void:
	var active_tab: Control = _codex_button if _source_mode == "codex" \
		else (_mix_tab if _source_mode == "mix" else _supplies_tab)
	var first_source: Control = active_tab
	if not _source_buttons.is_empty() and is_instance_valid(_source_buttons[0]):
		first_source = _source_buttons[0]
	var first_table: Control = _mix_try if _source_mode == "mix" \
		else _slot_buttons.get("c", _clear)
	var final_action: Control = _mix_clear if _source_mode == "mix" else _action
	_region_focus = [active_tab, first_table, final_action, _codex_button]
	_link(_supplies_tab, _codex_button, first_source, _close, _mix_tab)
	_link(_mix_tab, _codex_button, first_source, _supplies_tab, first_table)
	for i in _source_buttons.size():
		var current := _source_buttons[i]
		var up: Control = active_tab if i == 0 else _source_buttons[i - 1]
		var down: Control = _source_buttons[mini(_source_buttons.size() - 1, i + 1)]
		_link(current, up, down, current, first_table)
	if _source_mode == "mix":
		_link(_mix_try, _mix_tab, _mix_clear, first_source, _mix_clear)
		_link(_mix_clear, _mix_try, _mix_try, _mix_try, _codex_button)
		_link(_codex_button, _mix_clear, _mix_try, _mix_clear, _close)
		_link(_close, _codex_button, _mix_try, _codex_button, first_source)
		return
	for row in 3:
		for col in 3:
			var index := row * 3 + col
			var current: Control = _slot_buttons[SLOT_ORDER[index]]
			var up: Control = _ink_buttons[col] if row == 0 \
				else _slot_buttons[SLOT_ORDER[(row - 1) * 3 + col]]
			var down: Control = _clear if row == 2 \
				else _slot_buttons[SLOT_ORDER[(row + 1) * 3 + col]]
			var left: Control = first_source if col == 0 \
				else _slot_buttons[SLOT_ORDER[index - 1]]
			var right: Control = _action if col == 2 \
				else _slot_buttons[SLOT_ORDER[index + 1]]
			_link(current, up, down, left, right)
	for i in _ink_buttons.size():
		var current := _ink_buttons[i]
		var left: Control = first_source if i == 0 else _ink_buttons[i - 1]
		var right: Control = _action if i == _ink_buttons.size() - 1 else _ink_buttons[i + 1]
		_link(current, _codex_button, _slot_buttons[SLOT_ORDER[mini(2, i)]], left, right)
	_link(_clear, _slot_buttons.s, _slot_buttons.s, first_source, _action)
	_link(_action, _preview_body, _action, _slot_buttons.c, _codex_button)
	_link(_codex_button, _action, _action, _slot_buttons.n, _close)
	_link(_close, _codex_button, _action, _codex_button, first_source)


func _link(control: Control, up: Control, down: Control, left: Control,
		right: Control) -> void:
	if control == null or not is_instance_valid(control):
		return
	control.focus_neighbor_top = control.get_path_to(up)
	control.focus_neighbor_bottom = control.get_path_to(down)
	control.focus_neighbor_left = control.get_path_to(left)
	control.focus_neighbor_right = control.get_path_to(right)


func _panel(pos: Vector2, panel_size: Vector2) -> Panel:
	var p := Panel.new()
	p.position = pos
	p.size = panel_size
	var sb := StyleBoxFlat.new()
	sb.bg_color = Tokens.PAPER
	sb.border_color = Color(Tokens.WALNUT_DEEP, 0.60)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(18)
	sb.corner_detail = 8
	sb.shadow_color = Color(0, 0, 0, 0.10)
	sb.shadow_size = 4
	sb.shadow_offset = Vector2(0, 2)
	p.add_theme_stylebox_override("panel", sb)
	return p


func _label(value: String, font_size: int, color: Color, header: bool) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", maxi(Tokens.TYPE_BODY, font_size))
	label.add_theme_color_override("font_color", color)
	var font := WyrdUi.font_header() if header else WyrdUi.font_body()
	if font != null:
		label.add_theme_font_override("font", font)
	return label


func _button(value: String) -> Button:
	var button := Button.new()
	button.text = value
	button.focus_mode = Control.FOCUS_ALL
	button.theme_type_variation = &"PrimaryButton"
	button.custom_minimum_size.y = Tokens.HIT_TARGET
	return button


func _small_tab(value: String) -> Button:
	var button := _button(value)
	button.theme_type_variation = &"TabButton"
	button.add_theme_font_size_override("font_size", Tokens.TYPE_BODY)
	button.custom_minimum_size.y = Tokens.HIT_TARGET
	button.set_meta("cursor_role", "action")
	return button


class _SupplyButton extends Button:
	var shape := "unknown"
	var available := true

	func setup(row: Dictionary) -> void:
		text = "%s     ×%d" % [String(row.get("label", row.get("id", "Supply"))),
			int(row.get("count", 0))]
		shape = String(row.get("icon_shape", "unknown"))
		available = bool(row.get("available", true))
		disabled = not available
		custom_minimum_size = Vector2(238, 54)
		# An unavailable component is explanatory inventory, not a focus stop.
		# Keeping it focusable made Godot combine disabled + focus colours and
		# washed the label out against the paper card.
		focus_mode = Control.FOCUS_ALL if available else Control.FOCUS_NONE
		alignment = HORIZONTAL_ALIGNMENT_LEFT
		add_theme_font_size_override("font_size", Tokens.TYPE_BODY)
		var icon_path := String(row.get("icon_path", ""))
		var faces := {
			"normal": Tokens.PAPER_RAISED,
			"hover": Tokens.PAPER_RAISED.lightened(0.04),
			"pressed": Tokens.SAGE.lightened(0.22),
			# Keep unavailable stock visibly distinct from the paper page. Godot
			# applies disabled text treatment after Button overrides, so a pale
			# disabled face can collapse to cream-on-cream.
			"disabled": Tokens.DISABLED_SURFACE,
		}
		for state_name in faces:
			var style := StyleBoxFlat.new()
			style.bg_color = faces[state_name]
			style.border_color = Tokens.SAGE if state_name in ["hover", "pressed"] \
				else Color(Tokens.WALNUT, 0.42)
			style.set_border_width_all(2)
			style.set_corner_radius_all(10)
			style.content_margin_left = 12 if icon_path != "" else 58
			add_theme_stylebox_override(state_name, style)
		var focus := StyleBoxFlat.new()
		focus.draw_center = false
		focus.border_color = Tokens.SAGE
		focus.set_border_width_all(3)
		focus.set_corner_radius_all(12)
		focus.set_expand_margin_all(2)
		add_theme_stylebox_override("focus", focus)
		for color_name in ["font_color", "font_hover_color", "font_pressed_color",
				"font_focus_color"]:
			add_theme_color_override(color_name, Tokens.TEXT_ON_PAPER)
		add_theme_color_override("font_disabled_color", Tokens.DISABLED_TEXT_ON_PAPER)
		set_meta("supply_id", String(row.get("id", "")))
		set_meta("cursor_role", "component" if available else "place_invalid")
		tooltip_text = String(row.get("description", text))
		if icon_path != "" and ResourceLoader.exists(icon_path):
			self.icon = load(icon_path)
			expand_icon = true
			icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
			add_theme_constant_override("icon_max_width", 40)
			add_theme_constant_override("h_separation", 12)
			for color_name in ["icon_normal_color", "icon_hover_color",
					"icon_pressed_color", "icon_focus_color"]:
				add_theme_color_override(color_name, Color.WHITE)
			add_theme_color_override("icon_disabled_color", Color(1, 1, 1, 0.58))
		else:
			var icon := _ShapeIcon.new()
			icon.position = Vector2(11, 9)
			icon.size = Vector2(36, 36)
			icon.shape = shape
			icon.color = Tokens.TEXT_ON_PAPER if available else Tokens.DISABLED_TEXT_ON_PAPER
			icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(icon)


class _ChartSocket extends Button:
	var slot_id := ""
	var family_label := ""
	var shape := "unknown"
	var occupied := false
	var unlocked := false
	var shape_icon: _ShapeIcon
	var item_label: Label

	func set_state(state: Dictionary) -> void:
		unlocked = bool(state.get("unlocked", false))
		occupied = String(state.get("id", "")) != ""
		var ghost := bool(state.get("ghost", false)) and not occupied
		var ghost_available := bool(state.get("ghost_available", false))
		var compact_ink := slot_id.begins_with("ink_") and (occupied or ghost)
		shape = String(state.get("icon_shape", "unknown"))
		var level := int(state.get("level", 0))
		if not unlocked:
			var milestone := String(state.get("milestone", ""))
			if milestone == "first_snug_return":
				text = "%s\nFirst Snug return" % family_label
			elif slot_id.begins_with("ink_"):
				text = "%s\nLv %d" % [family_label, level]
			else:
				text = "%s\nWayfinding %d" % [family_label, level]
		elif occupied and not compact_ink:
			text = "\n\n%s" % String(state.get("name", family_label)).replace(" ", "\n")
		elif ghost and not compact_ink:
			text = "\n\n%s" % String(state.get("ghost_name", family_label)).replace(" ", "\n")
		elif compact_ink:
			# A 64px Ink pot cannot safely share Button's vertically-centered
			# multiline text with its bottle. A fixed two-line label reserves the
			# lower half, retaining the 16px accessibility floor and the full name.
			text = ""
		else:
			text = "\n\n%s" % family_label
		add_theme_font_size_override("font_size", Tokens.TYPE_BODY)
		disabled = not unlocked and not ghost
		var base_face := Tokens.MOSS if occupied else Tokens.PAPER_RAISED
		if ghost:
			base_face = Tokens.SAGE.darkened(0.08)
		if not unlocked and not ghost:
			base_face = Tokens.DISABLED_SURFACE.lightened(0.08)
		for state_name in ["normal", "hover", "pressed", "disabled"]:
			var style := StyleBoxFlat.new()
			style.bg_color = base_face.lightened(0.06) if state_name == "hover" \
				else (base_face.darkened(0.06) if state_name == "pressed" else base_face)
			style.border_color = Tokens.SAGE if ghost else Tokens.WALNUT
			style.set_border_width_all(2)
			style.set_corner_radius_all(10)
			add_theme_stylebox_override(state_name, style)
		var focus_style := StyleBoxFlat.new()
		focus_style.draw_center = false
		focus_style.border_color = Tokens.SAGE
		focus_style.set_border_width_all(3)
		focus_style.set_corner_radius_all(12)
		focus_style.set_expand_margin_all(3)
		add_theme_stylebox_override("focus", focus_style)
		var text_color := Tokens.TEXT_ON_DARK if occupied or ghost else Tokens.TEXT_ON_PAPER
		add_theme_color_override("font_color", text_color)
		add_theme_color_override("font_hover_color", text_color)
		add_theme_color_override("font_pressed_color", text_color)
		add_theme_color_override("font_disabled_color", Tokens.TEXT_ON_PAPER)
		set_meta("cursor_role", ("ghost_stage" if ghost_available else "ghost_unavailable") \
			if ghost else ("place_valid" if unlocked else "place_invalid"))
		tooltip_text = String(state.get("tooltip", text.replace("\n", " ")))
		if shape_icon == null:
			shape_icon = _ShapeIcon.new()
			shape_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(shape_icon)
		shape_icon.visible = occupied or unlocked
		shape_icon.shape = shape if occupied or ghost else family_label.to_lower()
		shape_icon.color = Tokens.TEXT_ON_DARK if occupied else \
			(Tokens.TEXT_ON_PAPER if ghost_available else Tokens.TEXT_ON_PAPER_DIM)
		shape_icon.size = Vector2(24, 24) if compact_ink else \
			(Vector2(34, 34) if occupied or ghost else Vector2(30, 30))
		shape_icon.position = Vector2(size.x * 0.5 - shape_icon.size.x * 0.5,
			3 if compact_ink else (6 if occupied or ghost else 16))
		shape_icon.queue_redraw()
		if item_label == null:
			item_label = Label.new()
			item_label.name = "SocketItemLabel"
			item_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			item_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			item_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			item_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			item_label.add_theme_font_size_override("font_size", Tokens.TYPE_BODY)
			var label_font := WyrdUi.font_body()
			if label_font != null:
				item_label.add_theme_font_override("font", label_font)
			add_child(item_label)
		item_label.visible = compact_ink
		if compact_ink:
			var item_name := String(state.get("name", state.get("ghost_name", family_label)))
			item_label.text = "%s\nInk" % item_name.trim_suffix(" Ink") \
				if item_name.ends_with(" Ink") else item_name.replace(" ", "\n")
			item_label.position = Vector2(3, 29)
			item_label.size = Vector2(size.x - 6, 34)
			item_label.add_theme_color_override("font_color", text_color)
			item_label.tooltip_text = item_name
			set_meta("semantic_name", item_name)


class _ShapeIcon extends Control:
	var shape := "unknown"
	var color := Color.WHITE

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		var c := r.get_center()
		var s := minf(r.size.x, r.size.y)
		var key := shape.to_lower()
		if "ink" in key or "bottle" in key:
			WyrdUi.draw_ink_bottle(self, c + Vector2(0, 3), s * 0.82,
				Color(0.30, 0.50, 0.34))
		elif "base" in key or "leaf" in key or "page" in key or "parchment" in key \
				or "folio" in key:
			WyrdUi.draw_scroll(self, r.grow(-3), false)
		elif "waymark" in key or "sprig" in key or "reed" in key or "track" in key \
				or "rubbing" in key:
			draw_line(c + Vector2(-s * 0.25, s * 0.28),
				c + Vector2(s * 0.18, -s * 0.28), color, 3.0, true)
			for off in [Vector2(-0.12, 0.08), Vector2(0.06, -0.08), Vector2(0.18, -0.22)]:
				draw_circle(c + off * s, s * 0.105, Color(WyrdUi.MAPLE_GREEN, 0.86))
		elif "binding" in key or "cord" in key or "knot" in key or "stitch" in key \
				or "loop" in key:
			draw_arc(c, s * 0.28, 0.2, TAU - 0.4, 24, color, 3.0, true)
			draw_arc(c + Vector2(s * 0.12, 0), s * 0.16, PI, TAU + PI,
				16, color, 2.5, true)
		elif "seal" in key or "trophy" in key:
			draw_circle(c, s * 0.30, Color(WyrdUi.TERRACOTTA, 0.90))
			draw_circle(c, s * 0.18, Color(WyrdUi.GOLD, 0.75))
			draw_arc(c, s * 0.30, 0, TAU, 24, color, 2.0, true)
		else:
			var points := PackedVector2Array([
				c + Vector2(0, -s * 0.30), c + Vector2(s * 0.25, 0),
				c + Vector2(0, s * 0.30), c + Vector2(-s * 0.25, 0),
			])
			draw_colored_polygon(points, Color(color, 0.35))
			draw_polyline(points + PackedVector2Array([points[0]]), color, 2.0, true)


class _CopperPotSketch extends Control:
	const Tokens = preload("res://scripts/ui/foundation/ui_tokens.gd")
	const POT_TEXTURE = preload("res://assets/ui/field_journal/icons/copper_pot.png")
	var makings := 0

	func _draw() -> void:
		var well := StyleBoxFlat.new()
		well.bg_color = Tokens.PAPER_RAISED.darkened(0.035)
		well.border_color = Color(Tokens.WALNUT, 0.34)
		well.set_border_width_all(2)
		well.set_corner_radius_all(12)
		draw_style_box(well, Rect2(Vector2.ZERO, size))
		var center := Vector2(size.x * 0.5, size.y * 0.50)
		# Steam and two wooden spoon strokes keep the silhouette readable as a
		# working pot even before bespoke painted art exists.
		for x_off in [-42.0, 0.0, 42.0]:
			var steam := PackedVector2Array([
				center + Vector2(x_off - 6, -76),
				center + Vector2(x_off + 5, -92),
				center + Vector2(x_off - 2, -110),
			])
			draw_polyline(steam, Color(Tokens.TEXT_ON_PAPER_DIM, 0.38), 3.0, true)
		var pot_rect := Rect2(center + Vector2(-90, -78), Vector2(180, 180))
		draw_texture_rect(POT_TEXTURE, pot_rect, false)
		# Each claimed making becomes a visible leaf/ore measure in the brew.
		for i in mini(makings, 7):
			var angle := float(i) * 1.7
			var p := center + Vector2(cos(angle) * 42.0, 6 + sin(angle) * 11.0)
			draw_circle(p, 7.0, Tokens.GOLD_MUTED if i % 3 == 2 else Tokens.SAGE)
		var measure_text := "EMPTY" if makings == 0 else "%d MAKING%s" % [
			makings, "" if makings == 1 else "S"]
		var font := WyrdUi.font_header()
		if font == null:
			font = get_theme_default_font()
		draw_string(font, Vector2(20, size.y - 18), measure_text,
			HORIZONTAL_ALIGNMENT_CENTER, size.x - 40, 14, Tokens.TEXT_ON_PAPER_DIM)


class _PreviewSketch extends Control:
	const Tokens = preload("res://scripts/ui/foundation/ui_tokens.gd")

	func _draw() -> void:
		var paper := StyleBoxFlat.new()
		paper.bg_color = Tokens.PAPER_RAISED.darkened(0.025)
		paper.border_color = Color(Tokens.WALNUT, 0.32)
		paper.set_border_width_all(2)
		paper.set_corner_radius_all(8)
		draw_style_box(paper, Rect2(Vector2.ZERO, size))
		var road := PackedVector2Array([
			Vector2(size.x * 0.08, size.y * 0.76),
			Vector2(size.x * 0.32, size.y * 0.52),
			Vector2(size.x * 0.52, size.y * 0.62),
			Vector2(size.x * 0.78, size.y * 0.24),
			Vector2(size.x * 0.92, size.y * 0.34),
		])
		draw_polyline(road, Color(Tokens.WALNUT, 0.52), 4.0, true)
		for point in [Vector2(0.18, 0.30), Vector2(0.28, 0.25),
				Vector2(0.68, 0.30), Vector2(0.84, 0.58)]:
			var p: Vector2 = Vector2(point) * size
			draw_line(p + Vector2(0, 12), p, Tokens.WALNUT, 2.5, true)
			draw_colored_polygon(PackedVector2Array([
				p + Vector2(-8, 3), p + Vector2(0, -14), p + Vector2(8, 3)]),
				Color(Tokens.SAGE, 0.64))
		var sign := Vector2(size.x * 0.78, size.y * 0.24)
		draw_line(sign, sign + Vector2(0, 28), Tokens.WALNUT, 4.0, true)
		draw_line(sign + Vector2(-12, 4), sign + Vector2(14, 4),
			Tokens.WALNUT, 5.0, true)


class _StampMark extends Control:
	var chart_name := "Chart"

	func _draw() -> void:
		var box := StyleBoxFlat.new()
		box.bg_color = Color(0.965, 0.905, 0.74, 0.98)
		box.border_color = WyrdUi.MAPLE_WOOD
		box.set_border_width_all(3)
		box.set_corner_radius_all(18)
		box.shadow_color = Color(0, 0, 0, 0.26)
		box.shadow_size = 10
		box.shadow_offset = Vector2(0, 6)
		draw_style_box(box, Rect2(Vector2.ZERO, size))
		# Folded parchment corners and the binding string crossing the face.
		draw_line(Vector2(26, 34), Vector2(size.x - 26, size.y - 34),
			Color(WyrdUi.MAPLE_WOOD, 0.24), 2.0, true)
		draw_line(Vector2(size.x - 26, 34), Vector2(26, size.y - 34),
			Color(WyrdUi.MAPLE_WOOD, 0.16), 2.0, true)
		draw_line(Vector2(18, size.y * 0.52), Vector2(size.x - 18, size.y * 0.52),
			Color(0.39, 0.23, 0.12, 0.72), 4.0, true)
		var seal := Vector2(size.x * 0.5, size.y * 0.52)
		draw_circle(seal, 34, Color(0.62, 0.20, 0.16))
		draw_circle(seal, 25, Color(0.76, 0.30, 0.22))
		draw_arc(seal, 34, 0, TAU, 40, Color(0.40, 0.12, 0.10), 2.5, true)
		var font := WyrdUi.font_header()
		if font == null:
			font = get_theme_default_font()
		draw_string(font, Vector2(20, 42), chart_name,
			HORIZONTAL_ALIGNMENT_CENTER, size.x - 40, 21, WyrdUi.MAPLE_WOOD_D)
		draw_string(font, Vector2(20, size.y - 24), "SEALED FOR THE CHART CASE",
			HORIZONTAL_ALIGNMENT_CENTER, size.x - 40, 13, WyrdUi.MAPLE_WOOD_D)
