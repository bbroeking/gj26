class_name CharmSocket
extends Button

# Dedicated binding-surface socket. The socket well is the icon; its readable
# state sits beside it inside the same focusable Control.

var _icon: TextureRect
var _glyph: Label
var _title: Label
var _status: Label


func _init() -> void:
	name = "CharmSocket"
	theme_type_variation = &"CharmSocketButton"
	custom_minimum_size = Vector2(192.0, 64.0)
	focus_mode = Control.FOCUS_ALL
	_build()


func _build() -> void:
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 7)
	margin.add_theme_constant_override("margin_top", 5)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 5)
	add_child(margin)
	var content := HBoxContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_theme_constant_override("separation", 9)
	margin.add_child(content)
	var center := CenterContainer.new()
	center.custom_minimum_size = Vector2(52.0, 52.0)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(center)
	_icon = TextureRect.new()
	_icon.custom_minimum_size = Vector2(48.0, 48.0)
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
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.alignment = BoxContainer.ALIGNMENT_CENTER
	copy.add_theme_constant_override("separation", 0)
	copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(copy)
	_title = Label.new()
	_title.theme_type_variation = &"RowTitle"
	_title.add_theme_font_size_override("font_size", 14)
	_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.add_child(_title)
	_status = Label.new()
	_status.theme_type_variation = &"RowSubtitle"
	_status.add_theme_font_size_override("font_size", 14)
	_status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.add_child(_status)


func setup(model: Dictionary) -> void:
	var socket_index := int(model.get("index", 0))
	name = "CharmSocket_%d" % socket_index
	_icon.texture = model.get("icon", null) as Texture2D
	_icon.visible = _icon.texture != null
	_glyph.text = String(model.get("glyph", "◇"))
	_glyph.visible = not _icon.visible
	_title.text = String(model.get("title", "Empty socket"))
	_status.text = String(model.get("status", "Available"))
	tooltip_text = String(model.get("tooltip", ""))
