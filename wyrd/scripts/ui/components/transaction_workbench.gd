class_name TransactionWorkbench
extends PanelContainer

# Spec 59 — shared authored workstation shell. The walnut mat is structural
# negative space between paper leaves; callers supply the station-specific
# rails and working surface without rebuilding header, footer, or close logic.

signal close_requested

const Tokens = preload("res://scripts/ui/foundation/ui_tokens.gd")
const FIELD_THEME := preload("res://themes/wayfinder_theme.tres")

var body: HBoxContainer
var resource_band: HBoxContainer
var footer: HBoxContainer

var _title: Label
var _maxim: Label
var _emblem: TextureRect


func _init() -> void:
	name = "TransactionShell"
	theme = FIELD_THEME
	theme_type_variation = &"JournalFrameContainer"
	custom_minimum_size = Vector2(1040.0, 650.0)
	_build()


func _build() -> void:
	var walnut := PanelContainer.new()
	walnut.name = "WorkbenchWalnutMat"
	walnut.theme_type_variation = &"WalnutFrame"
	add_child(walnut)

	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", Tokens.SPACE_3)
	walnut.add_child(page)

	var header := HBoxContainer.new()
	header.name = "TransactionHeader"
	header.custom_minimum_size.y = 62.0
	header.add_theme_constant_override("separation", Tokens.SPACE_3)
	page.add_child(header)

	_emblem = TextureRect.new()
	_emblem.name = "StationEmblem"
	_emblem.custom_minimum_size = Vector2(54.0, 54.0)
	_emblem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_emblem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_emblem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(_emblem)

	var title_stack := VBoxContainer.new()
	title_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_stack.alignment = BoxContainer.ALIGNMENT_CENTER
	title_stack.add_theme_constant_override("separation", 0)
	header.add_child(title_stack)
	_title = Label.new()
	_title.theme_type_variation = &"PageTitle"
	_title.add_theme_color_override("font_color", Tokens.TEXT_ON_DARK)
	title_stack.add_child(_title)
	_maxim = Label.new()
	_maxim.theme_type_variation = &"Caption"
	_maxim.add_theme_color_override("font_color", Tokens.TEXT_ON_DARK_DIM)
	title_stack.add_child(_maxim)

	resource_band = HBoxContainer.new()
	resource_band.name = "ResourceBand"
	resource_band.alignment = BoxContainer.ALIGNMENT_END
	resource_band.add_theme_constant_override("separation", Tokens.SPACE_4)
	header.add_child(resource_band)

	var close_button := Button.new()
	close_button.name = "CloseButton"
	close_button.text = "×"
	close_button.custom_minimum_size = Vector2(Tokens.HIT_TARGET, Tokens.HIT_TARGET)
	close_button.theme_type_variation = &"SecondaryButton"
	close_button.tooltip_text = "Close workstation"
	close_button.pressed.connect(func(): close_requested.emit())
	header.add_child(close_button)

	body = HBoxContainer.new()
	body.name = "WorkbenchBody"
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", Tokens.SPACE_4)
	page.add_child(body)

	footer = HBoxContainer.new()
	footer.name = "WorkbenchFooter"
	footer.custom_minimum_size.y = 48.0
	footer.add_theme_constant_override("separation", Tokens.SPACE_3)
	page.add_child(footer)


func setup(title: String, maxim: String, emblem: Texture2D = null) -> void:
	_title.text = title
	_maxim.text = maxim
	_emblem.texture = emblem
	_emblem.visible = emblem != null


func add_leaf(leaf_name: String, stretch_ratio: float) -> VBoxContainer:
	var leaf := PanelContainer.new()
	leaf.name = leaf_name
	leaf.theme_type_variation = &"PaperRaised"
	leaf.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	leaf.size_flags_stretch_ratio = stretch_ratio
	body.add_child(leaf)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", Tokens.SPACE_2)
	leaf.add_child(content)
	return content


func add_resource_text(text: String, color: Color = Tokens.TEXT_ON_DARK) -> Label:
	var label := Label.new()
	label.theme_type_variation = &"Body"
	label.text = text
	label.add_theme_color_override("font_color", color)
	resource_band.add_child(label)
	return label


func add_footer_hint(text: String) -> Label:
	var label := Label.new()
	label.theme_type_variation = &"Body"
	label.text = text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Tokens.TEXT_ON_DARK_DIM)
	footer.add_child(label)
	return label
