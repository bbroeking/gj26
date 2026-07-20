class_name LoadoutSlot
extends Button

# One readable field-bar slot. The Button owns click, focus, and drag/drop;
# child Controls only present the key, icon, assignment, and clearing rule.

signal request_assign(target_index: int, skill: String, from_slot: int)
signal request_quick(item_id: String)

const Tokens = preload("res://scripts/ui/foundation/ui_tokens.gd")

var index := 0
var accepts := "skill"
var skill_name := ""
var _item_id := ""
var _icon: TextureRect
var _glyph: Label
var _key: Label
var _title: Label
var _status: Label
var _mark: Label


func _init() -> void:
	name = "LoadoutSlot"
	theme_type_variation = &"JournalRowButton"
	custom_minimum_size = Vector2(0.0, 68.0)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	focus_mode = Control.FOCUS_ALL
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build()


func _build() -> void:
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", Tokens.SPACE_2)
	margin.add_theme_constant_override("margin_top", Tokens.SPACE_1)
	margin.add_theme_constant_override("margin_right", Tokens.SPACE_2)
	margin.add_theme_constant_override("margin_bottom", Tokens.SPACE_1)
	add_child(margin)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", Tokens.SPACE_3)
	margin.add_child(row)
	var key_plate := PanelContainer.new()
	key_plate.name = "KeyPlate"
	key_plate.theme_type_variation = &"PaperSurface"
	key_plate.custom_minimum_size = Vector2(48.0, 48.0)
	key_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(key_plate)
	_key = Label.new()
	_key.theme_type_variation = &"SectionTitle"
	_key.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_key.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_key.mouse_filter = Control.MOUSE_FILTER_IGNORE
	key_plate.add_child(_key)
	var well := PanelContainer.new()
	well.name = "SlotIconWell"
	well.theme_type_variation = &"ItemWell"
	well.custom_minimum_size = Vector2(52.0, 52.0)
	well.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(well)
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	well.add_child(center)
	_icon = TextureRect.new()
	_icon.custom_minimum_size = Vector2(42.0, 42.0)
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
	row.add_child(copy)
	_title = Label.new()
	_title.theme_type_variation = &"RowTitle"
	_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.add_child(_title)
	_status = Label.new()
	_status.theme_type_variation = &"RowSubtitle"
	_status.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.add_child(_status)
	_mark = Label.new()
	_mark.theme_type_variation = &"RowSubtitle"
	_mark.custom_minimum_size.x = 48.0
	_mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(_mark)


func setup_skill(idx: int, title: String, texture: Texture2D, key_text: String,
		fixed: bool = false, effect: String = "") -> void:
	index = idx
	accepts = "skill"
	skill_name = "" if fixed else title
	_item_id = ""
	name = "FieldSlot_%d" % idx
	_key.text = key_text
	_icon.texture = texture
	_icon.visible = texture != null
	_glyph.text = "◇" if title == "" else "✦"
	_glyph.visible = not _icon.visible
	_title.text = "Empty Focus slot" if title == "" else title
	_status.text = "Fixed basic attack" if fixed else ("Drop or choose a Skill" \
		if title == "" else effect)
	_mark.text = "Fixed" if fixed else ("Clear" if title != "" else "Open")
	tooltip_text = "%s [%s]" % [_title.text, key_text]
	theme_type_variation = &"JournalRowSelected" if fixed or title != "" \
		else &"JournalRowButton"


func setup_quick(item_id: String, item_name: String, count: int,
		texture: Texture2D, glyph: String) -> void:
	index = 4
	accepts = "item"
	skill_name = ""
	_item_id = item_id
	name = "QuickUseSlot"
	_key.text = "Q"
	_icon.texture = texture
	_icon.visible = texture != null
	_glyph.text = glyph if item_id != "" else "♨"
	_glyph.visible = not _icon.visible
	_title.text = item_name if item_id != "" else "Automatic draught"
	_status.text = "×%d pinned · Press to clear" % count if item_id != "" \
		else "Uses the best fitting draught"
	_mark.text = "Pinned" if item_id != "" else "Auto"
	tooltip_text = "Quick-use [Q]: %s" % _title.text
	theme_type_variation = &"JournalRowSelected" if item_id != "" \
		else &"JournalRowButton"


func _get_drag_data(_position: Vector2) -> Variant:
	if accepts != "skill" or index == 0 or skill_name == "":
		return null
	var preview := Label.new()
	preview.text = skill_name
	preview.theme_type_variation = &"RowTitle"
	preview.custom_minimum_size = Vector2(180.0, 48.0)
	preview.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	set_drag_preview(preview)
	return {"kind": "skill", "name": skill_name, "from_slot": index}


func _can_drop_data(_position: Vector2, data: Variant) -> bool:
	return index >= 1 and typeof(data) == TYPE_DICTIONARY \
		and String(data.get("kind", "")) == accepts


func _drop_data(_position: Vector2, data: Variant) -> void:
	if accepts == "item":
		request_quick.emit(String(data.get("name", "")))
	else:
		request_assign.emit(index, String(data.get("name", "")),
			int(data.get("from_slot", 0)))
