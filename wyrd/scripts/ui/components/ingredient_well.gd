class_name IngredientWell
extends PanelContainer

# Compact semantic material/result well for authored workstation flows.

const Tokens = preload("res://scripts/ui/foundation/ui_tokens.gd")

var _icon: TextureRect
var _glyph: Label
var _name_label: Label
var _count_label: Label


func _init() -> void:
	name = "IngredientWell"
	theme_type_variation = &"ItemWell"
	custom_minimum_size = Vector2(94.0, 110.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()


func _build() -> void:
	var content := VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 0)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(content)
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(center)
	_icon = TextureRect.new()
	_icon.custom_minimum_size = Vector2(38.0, 38.0)
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(_icon)
	_glyph = Label.new()
	_glyph.theme_type_variation = &"SectionTitle"
	_glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(_glyph)
	_name_label = Label.new()
	_name_label.theme_type_variation = &"RowTitle"
	_name_label.add_theme_font_size_override("font_size", 16)
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(_name_label)
	_count_label = Label.new()
	_count_label.theme_type_variation = &"RowSubtitle"
	_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(_count_label)


func setup(model: Dictionary) -> void:
	name = "IngredientWell_%s" % String(model.get("id", "item"))
	custom_minimum_size.x = float(model.get("width", 94.0))
	custom_minimum_size.y = float(model.get("height", 110.0))
	var icon_size := float(model.get("icon_size", 38.0))
	_icon.custom_minimum_size = Vector2(icon_size, icon_size)
	_icon.texture = model.get("icon", null) as Texture2D
	_icon.visible = _icon.texture != null
	_glyph.text = String(model.get("glyph", ""))
	_glyph.visible = not _icon.visible and _glyph.text != ""
	_name_label.text = String(model.get("name", ""))
	_name_label.add_theme_font_size_override("font_size", int(model.get("name_size", 16)))
	_count_label.text = String(model.get("count", ""))
	_count_label.add_theme_font_size_override("font_size", int(model.get("count_size", 13)))
	var sufficient := bool(model.get("sufficient", true))
	_count_label.add_theme_color_override("font_color",
		Tokens.SAGE.darkened(0.25) if sufficient else Tokens.TERRACOTTA)
	tooltip_text = String(model.get("tooltip", ""))
