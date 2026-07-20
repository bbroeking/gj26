class_name UiFocusPointer
extends Control

# Spec 59 — non-color focus cue paired with the Theme's 3px focus ring. Add one
# pointer overlay to a modal/screen root; it follows the viewport focus owner and
# never participates in hit testing.

const FOCUS_LEAF := preload("res://assets/ui/field_journal/chrome/focus_leaf_v2.png")

var _target: Control = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	get_viewport().gui_focus_changed.connect(_on_focus_changed)
	_on_focus_changed(get_viewport().gui_get_focus_owner())


func _exit_tree() -> void:
	if get_viewport() != null and get_viewport().gui_focus_changed.is_connected(_on_focus_changed):
		get_viewport().gui_focus_changed.disconnect(_on_focus_changed)


func _process(_delta: float) -> void:
	if is_instance_valid(_target):
		queue_redraw()


func _on_focus_changed(control: Control) -> void:
	_target = control
	visible = is_instance_valid(_target)
	queue_redraw()


func _draw() -> void:
	if not is_instance_valid(_target) or not _target.is_visible_in_tree():
		return
	var target_rect := _target.get_global_rect()
	var pointer_size := Vector2(30.0, 23.0)
	var pointer_rect := Rect2(
		Vector2(target_rect.position.x - global_position.x - pointer_size.x + 4.0,
			target_rect.get_center().y - global_position.y - pointer_size.y * 0.5),
		pointer_size)
	draw_texture_rect(FOCUS_LEAF, pointer_rect, false)
