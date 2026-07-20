class_name SystemFolio
extends PanelContainer

# Spec 59 — shared shell for focused system tasks. It is deliberately smaller
# than the transaction workbench: one paper task leaf inside journal chrome,
# with consistent title, close, footer hint, focus furniture, and safe sizing.

signal close_requested

const Tokens = preload("res://scripts/ui/foundation/ui_tokens.gd")
const FIELD_THEME := preload("res://themes/wayfinder_theme.tres")

var body: VBoxContainer
var footer: HBoxContainer

var _title: Label
var _subtitle: Label
var _glyph: Label
var _close: Button


func _init() -> void:
	name = "SystemShell"
	theme = FIELD_THEME
	theme_type_variation = &"JournalFrameContainer"
	custom_minimum_size = Vector2(560.0, 480.0)
	_build()


func _build() -> void:
	var walnut := PanelContainer.new()
	walnut.name = "SystemWalnutMat"
	walnut.theme_type_variation = &"WalnutFrame"
	add_child(walnut)

	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", Tokens.SPACE_3)
	walnut.add_child(page)

	var header := HBoxContainer.new()
	header.name = "SystemHeader"
	header.custom_minimum_size.y = 62.0
	header.add_theme_constant_override("separation", Tokens.SPACE_3)
	page.add_child(header)

	_glyph = Label.new()
	_glyph.name = "SystemGlyph"
	_glyph.custom_minimum_size = Vector2(48.0, 48.0)
	_glyph.theme_type_variation = &"PageTitle"
	_glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_glyph.add_theme_color_override("font_color", Tokens.GOLD_MUTED)
	header.add_child(_glyph)

	var title_stack := VBoxContainer.new()
	title_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_stack.alignment = BoxContainer.ALIGNMENT_CENTER
	title_stack.add_theme_constant_override("separation", 0)
	header.add_child(title_stack)
	_title = Label.new()
	_title.theme_type_variation = &"PageTitle"
	_title.add_theme_color_override("font_color", Tokens.TEXT_ON_DARK)
	title_stack.add_child(_title)
	_subtitle = Label.new()
	_subtitle.theme_type_variation = &"Caption"
	_subtitle.add_theme_color_override("font_color", Tokens.TEXT_ON_DARK_DIM)
	title_stack.add_child(_subtitle)

	_close = Button.new()
	_close.name = "CloseButton"
	_close.text = "×"
	_close.tooltip_text = "Close"
	_close.custom_minimum_size = Vector2(Tokens.HIT_TARGET, Tokens.HIT_TARGET)
	_close.theme_type_variation = &"SecondaryButton"
	_close.pressed.connect(func(): close_requested.emit())
	header.add_child(_close)

	var paper := PanelContainer.new()
	paper.name = "SystemPaperLeaf"
	paper.theme_type_variation = &"PaperRaised"
	paper.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(paper)
	body = VBoxContainer.new()
	body.name = "SystemBody"
	body.add_theme_constant_override("separation", Tokens.SPACE_3)
	paper.add_child(body)

	footer = HBoxContainer.new()
	footer.name = "SystemFooter"
	footer.custom_minimum_size.y = 40.0
	footer.add_theme_constant_override("separation", Tokens.SPACE_3)
	page.add_child(footer)


func setup(title: String, subtitle: String, glyph: String = "") -> void:
	_title.text = title
	_subtitle.text = subtitle
	_subtitle.visible = subtitle != ""
	_glyph.text = glyph
	_glyph.visible = glyph != ""


func set_subtitle(text: String) -> void:
	_subtitle.text = text
	_subtitle.visible = text != ""


func set_close_visible(value: bool) -> void:
	_close.visible = value
	_close.focus_mode = Control.FOCUS_ALL if value else Control.FOCUS_NONE


func set_folio_size(size: Vector2) -> void:
	custom_minimum_size = size
	offset_left = -size.x * 0.5
	offset_top = -size.y * 0.5
	offset_right = size.x * 0.5
	offset_bottom = size.y * 0.5


func add_footer_hint(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = &"Body"
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Tokens.TEXT_ON_DARK_DIM)
	footer.add_child(label)
	return label
