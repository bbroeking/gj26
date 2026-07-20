extends CanvasLayer

# A shrine is a one-way blessing choice, not a dismissible settings modal.
# The shared Field Journal shell supplies the furniture while this screen keeps
# Shrine/Game authority: setup opens one modal and a committed Button closes it.

signal chosen(buff: Dictionary)

const Tokens = preload("res://scripts/ui/foundation/ui_tokens.gd")
const FocusPointer = preload("res://scripts/ui/components/focus_pointer.gd")
const SystemFolio = preload("res://scripts/ui/components/system_folio.gd")

const BLESSING_ICONS := {
	"vigor": preload("res://assets/ui/field_journal/icons/shrine/vigor_v1.png"),
	"fury": preload("res://assets/ui/field_journal/icons/shrine/fury_v1.png"),
	"precision": preload("res://assets/ui/field_journal/icons/shrine/precision_v1.png"),
	"carnage": preload("res://assets/ui/field_journal/icons/shrine/carnage_v1.png"),
	"swiftness": preload("res://assets/ui/field_journal/icons/shrine/swiftness_v1.png"),
	"haste": preload("res://assets/ui/field_journal/icons/shrine/haste_v1.png"),
	"channeling": preload("res://assets/ui/field_journal/icons/shrine/channeling_v1.png"),
	"resilience": preload("res://assets/ui/field_journal/icons/shrine/resilience_v1.png"),
	"wanderer": preload("res://assets/ui/field_journal/icons/shrine/wanderer_v1.png"),
	"clarity": preload("res://assets/ui/field_journal/icons/shrine/clarity_v1.png"),
}

var _buffs: Array = []
var _folio: SystemFolio
var _choices: HBoxContainer
var _owns_modal := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	_build_backdrop()
	_build_folio()
	var pointer := FocusPointer.new()
	pointer.name = "MenuFocusPointer"
	add_child(pointer)
	if not _buffs.is_empty():
		_populate()


func _build_backdrop() -> void:
	var bg := ColorRect.new()
	bg.color = Tokens.SCRIM
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)


func _build_folio() -> void:
	_folio = SystemFolio.new()
	_folio.anchor_left = 0.5
	_folio.anchor_top = 0.5
	_folio.anchor_right = 0.5
	_folio.anchor_bottom = 0.5
	_folio.set_folio_size(Vector2(960.0, 560.0))
	_folio.setup("An Old Altar Stirs",
		"Choose one blessing. The shrine will not ask twice.", "✦")
	_folio.set_close_visible(false)
	add_child(_folio)

	var instruction := Label.new()
	instruction.name = "BlessingInstruction"
	instruction.text = "Three old promises answer. Carry one until this delve ends."
	instruction.theme_type_variation = &"Body"
	instruction.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_folio.body.add_child(instruction)

	_choices = HBoxContainer.new()
	_choices.name = "BlessingChoices"
	_choices.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_choices.add_theme_constant_override("separation", Tokens.SPACE_4)
	_choices.alignment = BoxContainer.ALIGNMENT_CENTER
	_folio.body.add_child(_choices)
	_folio.add_footer_hint("Left/Right — choose  ·  Enter/A — accept  ·  One blessing only")


# Populate the modal with the three authored offers and pause the world. Setup
# remains callable after add_child (production) or before _ready (test tools).
func setup(buffs: Array) -> void:
	_buffs = buffs.duplicate(true)
	if is_node_ready():
		_populate()
	_open_modal()


func _populate() -> void:
	for child in _choices.get_children():
		child.queue_free()
	var first: Button = null
	for buff in _buffs:
		var card := _make_card(buff)
		_choices.add_child(card)
		if first == null:
			first = card
	if first != null:
		first.grab_focus.call_deferred()


func _make_card(buff: Dictionary) -> Button:
	var id := String(buff.get("id", ""))
	var card := Button.new()
	card.name = "BlessingCard_%s" % id
	card.theme_type_variation = &"ChoiceCardButton"
	card.custom_minimum_size = Vector2(270.0, 310.0)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.tooltip_text = "%s — %s" % [buff.get("name", "Blessing"),
		buff.get("desc", "")]
	card.pressed.connect(_on_pressed.bind(buff))

	var content := VBoxContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 16.0
	content.offset_top = 12.0
	content.offset_right = -16.0
	content.offset_bottom = -14.0
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", Tokens.SPACE_2)
	card.add_child(content)

	var icon := TextureRect.new()
	icon.name = "BlessingIcon"
	icon.custom_minimum_size = Vector2(118.0, 118.0)
	icon.texture = BLESSING_ICONS.get(id) as Texture2D
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(icon)

	var name_label := Label.new()
	name_label.name = "BlessingName"
	name_label.text = String(buff.get("name", "Unnamed Blessing"))
	name_label.theme_type_variation = &"SectionTitle"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(name_label)

	var divider := HSeparator.new()
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(divider)

	var effect := Label.new()
	effect.name = "BlessingEffect"
	effect.text = String(buff.get("desc", ""))
	effect.theme_type_variation = &"RowTitle"
	effect.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	effect.add_theme_color_override("font_color", Tokens.TERRACOTTA)
	effect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(effect)

	var duration := Label.new()
	duration.text = "LASTS THIS DELVE"
	duration.theme_type_variation = &"Caption"
	duration.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	duration.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(duration)
	return card


func _open_modal() -> void:
	if _owns_modal:
		return
	var game := get_node_or_null("/root/Game")
	if game != null and game.has_method("modal_opened"):
		game.modal_opened()
		_owns_modal = true


func _on_pressed(buff: Dictionary) -> void:
	_release_modal()
	chosen.emit(buff)
	queue_free()


func _release_modal() -> void:
	if not _owns_modal:
		return
	var game := get_node_or_null("/root/Game")
	if game != null and game.has_method("modal_closed"):
		game.modal_closed()
	_owns_modal = false


func _exit_tree() -> void:
	_release_modal()


# No Esc escape: praying is the commitment; only a blessing resolves it.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
