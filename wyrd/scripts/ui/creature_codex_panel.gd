extends CanvasLayer

const CreatureCodexData = preload("res://data/creature_codex.gd")
const FocusPointer = preload("res://scripts/ui/components/focus_pointer.gd")
const SystemFolio = preload("res://scripts/ui/components/system_folio.gd")
const Tokens = preload("res://scripts/ui/foundation/ui_tokens.gd")

var _folio: SystemFolio
var _detail: RichTextLabel
var _first_button: Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 98
	_folio = SystemFolio.new()
	_folio.anchor_left = 0.5
	_folio.anchor_top = 0.5
	_folio.anchor_right = 0.5
	_folio.anchor_bottom = 0.5
	_folio.set_folio_size(Vector2(960.0, 640.0))
	_folio.setup("Creature Codex", "Every known life along the remembered roads.", "✦")
	_folio.close_requested.connect(_close)
	add_child(_folio)
	_build_pages()
	var pointer := FocusPointer.new()
	pointer.name = "CreatureCodexFocusPointer"
	add_child(pointer)
	if _first_button != null:
		_first_button.grab_focus.call_deferred()

func _build_pages() -> void:
	var split := HSplitContainer.new()
	split.name = "CreatureCodexSplit"
	split.split_offset = 310
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_folio.body.add_child(split)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.x = 300.0
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_child(scroll)
	var rail := VBoxContainer.new()
	rail.name = "CreatureCodexRail"
	rail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rail.add_theme_constant_override("separation", 7)
	scroll.add_child(rail)
	var previous_group := ""
	for row_v in CreatureCodexData.ordered_entries():
		var row: Dictionary = row_v
		var group := String(row.group)
		if group != previous_group:
			var heading := Label.new()
			heading.text = group
			heading.theme_type_variation = &"SectionTitle"
			rail.add_child(heading)
			previous_group = group
		var button := Button.new()
		button.name = "CreaturePage_%s" % String(row.id)
		button.text = String(row.name)
		button.theme_type_variation = &"QuietButton"
		button.custom_minimum_size = Vector2(0.0, 44.0)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_show_entry.bind(String(row.id)))
		rail.add_child(button)
		if _first_button == null:
			_first_button = button
	_detail = RichTextLabel.new()
	_detail.name = "CreatureCodexDetail"
	_detail.bbcode_enabled = true
	_detail.fit_content = false
	_detail.scroll_active = true
	_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_detail.theme_type_variation = &"Body"
	_detail.add_theme_color_override("default_color", Tokens.TEXT_ON_PAPER)
	split.add_child(_detail)
	_show_entry(String(CreatureCodexData.ORDER[0]))
	_folio.add_footer_hint("Up/Down choose a creature  ·  Enter/A open  ·  Esc/B close")

func _show_entry(id: String) -> void:
	var row := CreatureCodexData.entry(id)
	if row.is_empty() or _detail == null:
		return
	_detail.text = "[font_size=28][b]%s[/b][/font_size]\n[color=#80633c]%s[/color]\n\n[b]Nature[/b]  %s\n[b]Roads[/b]  %s\n\n[b]Battle sign[/b]\n%s\n\n[i]“%s”[/i]" % [
		String(row.name), String(row.group), String(row.role), String(row.region),
		String(row.projectile), String(row.quote)]

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_close()
		get_viewport().set_input_as_handled()

func _close() -> void:
	queue_free()
