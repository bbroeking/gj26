class_name LoadoutChoiceRow
extends JournalListRow

# Shared Journal row with an optional drag payload for the loadout library.

var payload_kind := ""
var payload_id := ""
var payload_texture: Texture2D


func setup_choice(model: Dictionary, kind: String, id: String,
		texture: Texture2D = null) -> void:
	setup(model)
	payload_kind = kind
	payload_id = id
	payload_texture = texture


func _get_drag_data(_position: Vector2) -> Variant:
	if payload_kind == "" or payload_id == "":
		return null
	var preview := TextureRect.new()
	preview.custom_minimum_size = Vector2(56.0, 56.0)
	preview.size = Vector2(56.0, 56.0)
	preview.texture = payload_texture
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	set_drag_preview(preview)
	return {"kind": payload_kind, "name": payload_id, "from_slot": 0}
