class_name JournalListRow
extends Button

# Spec 59 — one semantic row for Pack, transactions, Waystone, and Chart
# sources. The Button owns interaction/focus; child Controls only present the
# icon, hierarchy, semantic state, and trailing consequence.

const Tokens = preload("res://scripts/ui/foundation/ui_tokens.gd")

enum RowState { NORMAL, SELECTED, DISABLED }

const ALLOWED_MODEL_KEYS := [
	"title", "subtitle", "detail", "trailing", "badge", "tooltip", "icon", "glyph",
	"state", "trailing_color", "badge_color", "density",
]

var _icon_well: PanelContainer
var _icon: TextureRect
var _glyph: Label
var _title: Label
var _subtitle: Label
var _detail: Label
var _trailing: Label
var _badge: Label
var _state_mark: Label
var _content: MarginContainer


func _init() -> void:
	name = "JournalListRow"
	theme_type_variation = &"JournalRowButton"
	custom_minimum_size = Vector2(0.0, 68.0)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	focus_mode = Control.FOCUS_ALL
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = false
	_build_content()


func _build_content() -> void:
	_content = MarginContainer.new()
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_content.add_theme_constant_override("margin_left", Tokens.SPACE_2)
	_content.add_theme_constant_override("margin_top", Tokens.SPACE_1)
	_content.add_theme_constant_override("margin_right", Tokens.SPACE_2)
	_content.add_theme_constant_override("margin_bottom", Tokens.SPACE_1)
	add_child(_content)

	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", Tokens.SPACE_3)
	_content.add_child(row)

	_icon_well = PanelContainer.new()
	_icon_well.name = "IconWell"
	_icon_well.theme_type_variation = &"ItemWell"
	_icon_well.custom_minimum_size = Vector2(48.0, 48.0)
	_icon_well.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(_icon_well)

	var icon_center := CenterContainer.new()
	icon_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_icon_well.add_child(icon_center)
	_icon = TextureRect.new()
	_icon.name = "Icon"
	_icon.custom_minimum_size = Vector2(38.0, 38.0)
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_center.add_child(_icon)
	_glyph = Label.new()
	_glyph.name = "Glyph"
	_glyph.theme_type_variation = &"SectionTitle"
	_glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_center.add_child(_glyph)

	var copy := VBoxContainer.new()
	copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.alignment = BoxContainer.ALIGNMENT_CENTER
	copy.add_theme_constant_override("separation", 0)
	row.add_child(copy)
	_title = Label.new()
	_title.name = "Title"
	_title.theme_type_variation = &"RowTitle"
	_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.add_child(_title)
	_subtitle = Label.new()
	_subtitle.name = "Subtitle"
	_subtitle.theme_type_variation = &"RowSubtitle"
	_subtitle.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.add_child(_subtitle)
	_detail = Label.new()
	_detail.name = "Detail"
	_detail.theme_type_variation = &"RowSubtitle"
	_detail.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_detail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.add_child(_detail)
	_state_mark = Label.new()
	_state_mark.name = "StateMark"
	_state_mark.theme_type_variation = &"SectionTitle"
	_state_mark.text = "✓"
	_state_mark.tooltip_text = "Selected"
	_state_mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_state_mark.visible = false
	row.add_child(_state_mark)

	var consequence := VBoxContainer.new()
	consequence.name = "Consequence"
	consequence.mouse_filter = Control.MOUSE_FILTER_IGNORE
	consequence.alignment = BoxContainer.ALIGNMENT_CENTER
	consequence.add_theme_constant_override("separation", 0)
	row.add_child(consequence)
	_trailing = Label.new()
	_trailing.name = "Trailing"
	_trailing.theme_type_variation = &"RowTrailing"
	_trailing.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_trailing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	consequence.add_child(_trailing)
	_badge = Label.new()
	_badge.name = "StateBadge"
	_badge.theme_type_variation = &"RowSubtitle"
	_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	consequence.add_child(_badge)


func setup(model: Dictionary) -> void:
	if OS.is_debug_build():
		for key in model:
			assert(ALLOWED_MODEL_KEYS.has(String(key)),
				"Unknown JournalListRow model key: %s" % key)
	_title.text = String(model.get("title", ""))
	_subtitle.text = String(model.get("subtitle", ""))
	_subtitle.visible = _subtitle.text != ""
	_detail.text = String(model.get("detail", ""))
	_detail.visible = _detail.text != ""
	var density := String(model.get("density", "standard"))
	custom_minimum_size.y = 84.0 if _detail.visible else (60.0 if density == "compact" else 68.0)
	_trailing.text = String(model.get("trailing", ""))
	_trailing.visible = _trailing.text != ""
	_badge.text = String(model.get("badge", ""))
	_badge.visible = _badge.text != ""
	tooltip_text = String(model.get("tooltip", ""))
	var texture = model.get("icon", null)
	_icon.texture = texture as Texture2D
	_icon.visible = _icon.texture != null
	_glyph.text = String(model.get("glyph", ""))
	_glyph.visible = not _icon.visible and _glyph.text != ""
	_icon_well.visible = _icon.visible or _glyph.visible
	var state := int(model.get("state", RowState.NORMAL))
	assert(state >= RowState.NORMAL and state <= RowState.DISABLED,
		"Invalid JournalListRow state: %d" % state)
	var selected := state == RowState.SELECTED
	_state_mark.visible = selected
	theme_type_variation = &"JournalRowSelected" if selected else &"JournalRowButton"
	disabled = state == RowState.DISABLED
	_content.modulate = Color.WHITE
	var trailing_color: Color = model.get("trailing_color", Tokens.TEXT_ON_PAPER)
	_trailing.add_theme_color_override("font_color", trailing_color)
	var badge_color: Color = model.get("badge_color", Tokens.TEXT_ON_PAPER_DIM)
	_badge.add_theme_color_override("font_color", badge_color)
