class_name RoadNamingPanel
extends CanvasLayer

# The Knot-Eater's final road name is irreversible but mechanically cosmetic.
# It reuses the same commitment-card language as Shrines while Encounter keeps
# the only settlement authority.

const Tokens = preload("res://scripts/ui/foundation/ui_tokens.gd")
const FocusPointer = preload("res://scripts/ui/components/focus_pointer.gd")
const SystemFolio = preload("res://scripts/ui/components/system_folio.gd")

const CHOICES := [
	{
		"id": "lantern_path", "name": "Lantern Path",
		"copy": "A warm light kept between wayfarers.",
		"icon": preload("res://assets/ui/field_journal/icons/lantern_path_waystone_v1.png"),
	},
	{
		"id": "mended_way", "name": "Mended Way",
		"copy": "An old break stitched kindly closed.",
		"icon": preload("res://assets/ui/field_journal/icons/loop_cord.png"),
	},
	{
		"id": "open_footpath", "name": "Open Footpath",
		"copy": "A road left free for any careful tread.",
		"icon": preload("res://assets/ui/field_journal/icons/route_signpost.png"),
	},
]

var encounter: Node
var _status: Label
var _accounted := false


func configure(controller: Node) -> void:
	encounter = controller


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 96
	var backdrop := ColorRect.new()
	backdrop.color = Tokens.SCRIM
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(backdrop)

	var folio := SystemFolio.new()
	folio.anchor_left = 0.5
	folio.anchor_top = 0.5
	folio.anchor_right = 0.5
	folio.anchor_bottom = 0.5
	folio.set_folio_size(Vector2(900.0, 540.0))
	folio.setup("Name the New Road",
		"The Knot-Eater waits. This name becomes part of Bramblewood.", "✦")
	folio.set_close_visible(false)
	add_child(folio)

	_status = Label.new()
	_status.name = "NamingStatus"
	_status.text = "Only the fire-keeper may choose. All three names are cosmetic."
	_status.theme_type_variation = &"Body"
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	folio.body.add_child(_status)

	var row := HBoxContainer.new()
	row.name = "RoadChoices"
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", Tokens.SPACE_4)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	folio.body.add_child(row)
	var first: Button = null
	for choice in CHOICES:
		var card := _make_card(choice)
		row.add_child(card)
		if first == null:
			first = card
	folio.add_footer_hint("Left/Right — choose  ·  Enter/A — name the road  ·  One name only")
	if first != null:
		first.grab_focus.call_deferred()

	var pointer := FocusPointer.new()
	pointer.name = "MenuFocusPointer"
	add_child(pointer)
	var game := get_node_or_null("/root/Game")
	if game != null:
		game.modal_opened()
		_accounted = true


func _make_card(choice: Dictionary) -> Button:
	var id := String(choice.id)
	var button := Button.new()
	button.name = "RoadChoice_%s" % id
	button.theme_type_variation = &"ChoiceCardButton"
	button.custom_minimum_size = Vector2(248.0, 280.0)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.tooltip_text = "%s — %s" % [choice.name, choice.copy]
	button.pressed.connect(_choose.bind(id))

	var content := VBoxContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 16.0
	content.offset_top = 14.0
	content.offset_right = -16.0
	content.offset_bottom = -14.0
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", Tokens.SPACE_2)
	button.add_child(content)
	var icon := TextureRect.new()
	icon.name = "RoadChoiceIcon"
	icon.texture = choice.icon
	icon.custom_minimum_size = Vector2(104.0, 104.0)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(icon)
	var title := Label.new()
	title.text = String(choice.name)
	title.theme_type_variation = &"SectionTitle"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(title)
	content.add_child(HSeparator.new())
	var copy := Label.new()
	copy.text = String(choice.copy)
	copy.theme_type_variation = &"Body"
	copy.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(copy)
	var consequence := Label.new()
	consequence.text = "COSMETIC NAME"
	consequence.theme_type_variation = &"Caption"
	consequence.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	consequence.add_theme_color_override("font_color", Tokens.TERRACOTTA)
	consequence.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(consequence)
	return button


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()


func _choose(choice: String) -> void:
	if encounter == null:
		return
	encounter.call("press", &"name", StringName(choice))
	if bool(encounter.call("view").get("settled", false)):
		_close()
	else:
		_status.text = "The road will not take that name yet."
		_status.add_theme_color_override("font_color", Tokens.TERRACOTTA)


func _close() -> void:
	if _accounted:
		var game := get_node_or_null("/root/Game")
		if game != null:
			game.modal_closed()
		_accounted = false
	queue_free()


func _exit_tree() -> void:
	if _accounted:
		var game := get_node_or_null("/root/Game")
		if game != null:
			game.modal_closed()
		_accounted = false
