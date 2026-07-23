extends CanvasLayer

# Spec 59 — Field Journal dialogue vertical slice. Public API and signals stay
# compatible with every existing NPC; layout is now semantic Controls and
# Containers instead of a full-screen custom-drawn canvas.

signal finished
signal choice_selected(index)

const Tokens = preload("res://scripts/ui/foundation/ui_tokens.gd")
const FocusPointer = preload("res://scripts/ui/components/focus_pointer.gd")
const THEME_PATH := "res://themes/wayfinder_theme.tres"

var _pages: Array = []
var _choices: Array = []
var _idx := 0
var _done := false
var _modal_owned := false
var _speaker := ""
var _lockout := 0.0
var _portrait_texture: Texture2D

var _panel: PanelContainer
var _portrait_shell: PanelContainer
var _well: PortraitWell
var _name_lbl: Label
var _body: Label
var _hint: Label
var _continue_button: Button
var _choice_shell: PanelContainer
var _choice_box: VBoxContainer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100

	var bg := ColorRect.new()
	bg.color = Color(Tokens.SCRIM, 0.34)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)

	_panel = PanelContainer.new()
	_panel.name = "DialogueShell"
	_panel.theme = load(THEME_PATH) as Theme
	_panel.theme_type_variation = &"JournalFrameContainer"
	_panel.anchor_right = 1.0
	_panel.anchor_top = 1.0
	_panel.anchor_bottom = 1.0
	add_child(_panel)

	var columns := HBoxContainer.new()
	columns.name = "DialogueColumns"
	columns.add_theme_constant_override("separation", Tokens.SPACE_3)
	_panel.add_child(columns)

	_portrait_shell = PanelContainer.new()
	_portrait_shell.name = "PortraitWell"
	_portrait_shell.theme_type_variation = &"MossWell"
	_portrait_shell.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_child(_portrait_shell)
	_well = PortraitWell.new()
	_well.portrait_texture = _portrait_texture
	_well.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_portrait_shell.add_child(_well)

	var prose_shell := PanelContainer.new()
	prose_shell.name = "ProsePaper"
	prose_shell.theme_type_variation = &"PaperSurface"
	prose_shell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	prose_shell.size_flags_stretch_ratio = 2.4
	columns.add_child(prose_shell)

	var prose := VBoxContainer.new()
	prose.name = "VBoxContainer"
	prose.add_theme_constant_override("separation", Tokens.SPACE_2)
	prose_shell.add_child(prose)

	_name_lbl = Label.new()
	_name_lbl.name = "Speaker"
	_name_lbl.theme_type_variation = &"SectionTitle"
	_name_lbl.clip_text = true
	prose.add_child(_name_lbl)

	var divider := HSeparator.new()
	prose.add_child(divider)

	var prose_scroll := ScrollContainer.new()
	prose_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	prose_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	prose.add_child(prose_scroll)
	_body = Label.new()
	_body.name = "Prose"
	_body.theme_type_variation = &"DialogueBody"
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.add_theme_constant_override("line_spacing", 6)
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	prose_scroll.add_child(_body)

	_continue_button = Button.new()
	_continue_button.name = "ContinueButton"
	_continue_button.theme_type_variation = &"PrimaryButton"
	_continue_button.custom_minimum_size = Vector2(188.0, Tokens.HIT_TARGET)
	_continue_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	_continue_button.pressed.connect(_advance)
	prose.add_child(_continue_button)

	_hint = Label.new()
	_hint.name = "AdvanceHint"
	_hint.text = "Click Continue · E / Space    Esc — close"
	_hint.theme_type_variation = &"Caption"
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	prose.add_child(_hint)

	_choice_shell = PanelContainer.new()
	_choice_shell.name = "ChoicePaper"
	_choice_shell.theme_type_variation = &"PaperSurface"
	_choice_shell.custom_minimum_size.x = 320.0
	_choice_shell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_choice_shell.size_flags_stretch_ratio = 1.0
	columns.add_child(_choice_shell)
	var choice_scroll := ScrollContainer.new()
	choice_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_choice_shell.add_child(choice_scroll)
	_choice_box = VBoxContainer.new()
	_choice_box.name = "Choices"
	_choice_box.add_theme_constant_override("separation", Tokens.SPACE_3)
	_choice_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	choice_scroll.add_child(_choice_box)
	_choice_shell.visible = false

	var focus_pointer := FocusPointer.new()
	focus_pointer.name = "FocusPointer"
	add_child(focus_pointer)

	get_viewport().size_changed.connect(_layout_dialog)
	_layout_dialog()
	get_node("/root/Game").modal_opened()
	_modal_owned = true
	_render()


func _layout_dialog() -> void:
	if _panel == null:
		return
	var vp := get_viewport().get_visible_rect().size
	var gutter := clampf(vp.x * 0.035, Tokens.SAFE_GUTTER, 56.0)
	var height := clampf(vp.y * 0.38, 250.0, 320.0)
	_panel.offset_left = gutter
	_panel.offset_right = -gutter
	_panel.offset_top = -height - Tokens.SAFE_GUTTER
	_panel.offset_bottom = -Tokens.SAFE_GUTTER
	_portrait_shell.custom_minimum_size.x = clampf(height - 44.0, 160.0, 260.0)


# Public API. Choices appear only on the final page, preserving classic paged
# dialogue cadence and existing caller behavior.
func open(speaker: String, pages: Array, portrait: Texture2D = null,
		choices: Array = []) -> void:
	_speaker = speaker
	_pages = pages
	_choices = choices
	_portrait_texture = portrait
	_idx = 0
	if _well != null:
		_well.portrait_texture = portrait
	if is_node_ready():
		_render()


func _render() -> void:
	if _name_lbl == null:
		return
	_name_lbl.text = _speaker
	_body.text = String(_pages[_idx]) if _idx < _pages.size() else ""
	_portrait_shell.visible = _portrait_texture != null
	var on_last := _idx >= _pages.size() - 1
	var show_choices := not _choices.is_empty() and on_last
	_choice_shell.visible = show_choices
	_hint.visible = not show_choices
	_continue_button.visible = not show_choices
	if not show_choices:
		_continue_button.text = ("Finish  ·  %d of %d" if on_last \
			else "Continue  ·  %d of %d  →") % [_idx + 1, _pages.size()]
	if show_choices and _choice_box.get_child_count() != _choices.size():
		_build_choices()


func _build_choices() -> void:
	for child in _choice_box.get_children():
		child.free()
	var first: Button = null
	for i in _choices.size():
		var button := Button.new()
		button.text = String(_choices[i])
		button.theme_type_variation = &"PrimaryButton" if i == 0 else &"SecondaryButton"
		button.custom_minimum_size = Vector2(0.0, Tokens.HIT_TARGET)
		button.focus_mode = Control.FOCUS_ALL
		button.pressed.connect(_on_choice.bind(i))
		_choice_box.add_child(button)
		if first == null:
			first = button
	if first != null:
		first.call_deferred("grab_focus")


func _on_choice(index: int) -> void:
	if _done:
		return
	choice_selected.emit(index)
	_finish()


func _process(delta: float) -> void:
	_lockout += delta
	if _lockout < 0.25:
		return
	if Input.is_action_just_pressed("ui_cancel"):
		_finish()
		return
	if not _choices.is_empty() and _idx >= _pages.size() - 1:
		return
	if Input.is_action_just_pressed("interact") \
			or Input.is_action_just_pressed("roll") \
			or Input.is_action_just_pressed("ui_accept"):
		_advance()


func _input(event: InputEvent) -> void:
	if _lockout < 0.25:
		return
	if not _choices.is_empty() and _idx >= _pages.size() - 1:
		return
	if event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT:
		_advance()


func _advance() -> void:
	if _done:
		return
	_lockout = 0.0
	_idx += 1
	if _idx >= _pages.size():
		if not _choices.is_empty():
			_idx = _pages.size() - 1
			_render()
			return
		_finish()
	else:
		_render()


func _finish() -> void:
	if _done:
		return
	_done = true
	_release_modal_ownership()
	finished.emit()
	queue_free()


# A dialogue can be legitimately freed by a Town↔World scene handoff before a
# player advances it. Its modal token belongs to this panel, so always release
# it exactly once on either normal finish or tree exit; otherwise an outgoing
# lesson leaves the incoming scene permanently paused with no visible dialog.
func _exit_tree() -> void:
	_release_modal_ownership()


func _release_modal_ownership() -> void:
	if not _modal_owned:
		return
	_modal_owned = false
	var game := get_node_or_null("/root/Game")
	if game != null and game.has_method("modal_closed"):
		game.modal_closed()


class PortraitWell extends Control:
	var portrait_texture: Texture2D = null:
		set(value):
			portrait_texture = value
			queue_redraw()

	func _draw() -> void:
		var rect := Rect2(Vector2.ZERO, size)
		if portrait_texture != null:
			draw_texture_rect(portrait_texture, rect, false)
		else:
			draw_rect(rect, Tokens.MOSS)
			var center := size * 0.5
			var radius := minf(center.x, center.y) * 0.9
			draw_circle(center + Vector2(0, radius * 0.30), radius * 0.34,
				Color(Tokens.SAGE, 0.52))
			draw_circle(center - Vector2(0, radius * 0.16), radius * 0.22,
				Color(Tokens.SAGE, 0.52))
