extends CanvasLayer

# Small, in-engine storybook vignettes for onboarding. They borrow the live
# camera, hide gameplay HUD through Game's existing modal seam, and interpolate
# a handful of authored frames. No video asset or second scene load is needed.
#
# Public API:
#   play(camera_rig, frames, actor_track)
# Each target frame accepts:
#   focus: Vector3, yaw: radians, pitch: degrees, zoom: float,
#   duration: seconds, caption: String.

signal finished(skipped: bool)

const MIN_SKIP_DELAY := 0.35
const Tokens = preload("res://scripts/ui/foundation/ui_tokens.gd")
const FIELD_THEME := preload("res://themes/wayfinder_theme.tres")

var _rig: Node = null
var _frames: Array = []
var _from: Dictionary = {}
var _to: Dictionary = {}
var _frame_index := 0
var _elapsed := 0.0
var _age := 0.0
var _running := false
var _owns_modal := false
var _actor_track: Dictionary = {}
var _cinematic_wanderers: Array[Node] = []

var _root: Control = null
var _caption: Label = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 85
	_build_overlay()
	if _running:
		_begin()

func play(camera_rig: Node, target_frames: Array, actor_track: Dictionary = {}) -> void:
	_rig = camera_rig
	_frames = target_frames.duplicate(true)
	_actor_track = actor_track.duplicate()
	_running = _rig != null and not _frames.is_empty()
	if is_node_ready() and _running:
		_begin()

func _begin() -> void:
	if not _running or _owns_modal:
		return
	if not _rig.has_method("cinematic_frame") \
			or not _rig.has_method("begin_cinematic") \
			or not _rig.has_method("apply_cinematic_frame"):
		_finish(true)
		return
	var start: Dictionary = _rig.cinematic_frame()
	_frames.push_front(start)
	_from = _frames[0]
	_frame_index = 1
	_to = _frames[_frame_index]
	_elapsed = 0.0
	_age = 0.0
	_rig.begin_cinematic()
	_rig.apply_cinematic_frame(_from)
	_begin_actor_track()
	for wanderer in get_tree().get_nodes_in_group("wandering_npc"):
		var controller := wanderer.get_node_or_null("NpcWander")
		if controller == null:
			for child in wanderer.get_children():
				if child.has_method("set_cinematic_motion"):
					controller = child
					break
		if controller != null and controller.has_method("set_cinematic_motion"):
			controller.set_cinematic_motion(true)
			_cinematic_wanderers.append(controller)
	var game := get_node_or_null("/root/Game")
	if game != null and game.has_method("modal_opened"):
		game.modal_opened()
		_owns_modal = true
	_set_caption(String(_to.get("caption", "")))

func _process(delta: float) -> void:
	if not _running or _rig == null:
		return
	_age += delta
	_update_actor_track()
	_elapsed += delta
	if _root != null:
		_root.modulate.a = clampf(_age / 0.22, 0.0, 1.0)
	var duration := maxf(0.05, float(_to.get("duration", 1.0)))
	var raw_t := clampf(_elapsed / duration, 0.0, 1.0)
	# Smoothstep keeps the tiny pans feeling authored instead of mechanical.
	var t := raw_t * raw_t * (3.0 - 2.0 * raw_t)
	_rig.apply_cinematic_frame(_blend_frame(_from, _to, t))
	if raw_t < 1.0:
		return
	_from = _to
	_frame_index += 1
	if _frame_index >= _frames.size():
		_finish(false)
		return
	_to = _frames[_frame_index]
	_elapsed = 0.0
	_set_caption(String(_to.get("caption", "")))

func _blend_frame(a: Dictionary, b: Dictionary, t: float) -> Dictionary:
	var af: Vector3 = a.get("focus", Vector3.ZERO)
	var bf: Vector3 = b.get("focus", af)
	var ay := float(a.get("yaw", 0.0))
	var by := float(b.get("yaw", ay))
	return {
		"focus": af.lerp(bf, t),
		"yaw": lerp_angle(ay, by, t),
		"pitch": lerpf(float(a.get("pitch", 38.0)),
			float(b.get("pitch", 38.0)), t),
		"zoom": lerpf(float(a.get("zoom", 16.5)),
			float(b.get("zoom", 16.5)), t),
	}

func _begin_actor_track() -> void:
	var actor: Node3D = _actor_track.get("actor") as Node3D
	if actor == null or not is_instance_valid(actor):
		_actor_track.clear()
		return
	var start: Vector3 = _actor_track.get("start", actor.global_position)
	var finish: Vector3 = _actor_track.get("end", actor.global_position)
	actor.global_position = start
	if actor.has_method("begin_cinematic_walk"):
		actor.begin_cinematic_walk(finish - start)

func _update_actor_track() -> void:
	var actor: Node3D = _actor_track.get("actor") as Node3D
	if actor == null or not is_instance_valid(actor):
		return
	var duration := maxf(0.05, float(_actor_track.get("duration", 1.0)))
	var t := clampf(_age / duration, 0.0, 1.0)
	t = t * t * (3.0 - 2.0 * t)
	var start: Vector3 = _actor_track.get("start", actor.global_position)
	var finish: Vector3 = _actor_track.get("end", actor.global_position)
	actor.global_position = start.lerp(finish, t)

func _finish_actor_track() -> void:
	var actor: Node3D = _actor_track.get("actor") as Node3D
	if actor != null and is_instance_valid(actor):
		actor.global_position = _actor_track.get("end", actor.global_position)
		if actor.has_method("end_cinematic_walk"):
			actor.end_cinematic_walk()
	_actor_track.clear()
	for controller in _cinematic_wanderers:
		if is_instance_valid(controller) and controller.has_method("set_cinematic_motion"):
			controller.set_cinematic_motion(false)
	_cinematic_wanderers.clear()

func _unhandled_input(event: InputEvent) -> void:
	if not _running or _age < MIN_SKIP_DELAY:
		return
	var pressed := false
	if event is InputEventKey:
		pressed = event.pressed and not event.echo
	elif event is InputEventMouseButton:
		pressed = event.pressed
	elif event is InputEventJoypadButton:
		pressed = event.pressed
	if pressed:
		get_viewport().set_input_as_handled()
		_finish(true)

func _finish(skipped: bool) -> void:
	if not _running and not _owns_modal:
		queue_free()
		return
	_running = false
	_finish_actor_track()
	if _rig != null and is_instance_valid(_rig):
		# Land on the final authored frame even when skipped so returning to the
		# follow camera never jumps through an intermediate composition.
		if not _frames.is_empty():
			_rig.apply_cinematic_frame(_frames.back())
		if _rig.has_method("end_cinematic"):
			_rig.end_cinematic()
	var game := get_node_or_null("/root/Game")
	if _owns_modal and game != null and game.has_method("modal_closed"):
		_owns_modal = false
		game.modal_closed()
	finished.emit(skipped)
	queue_free()

func _exit_tree() -> void:
	# Scene changes and dev tools may free the vignette early. Never leave the
	# shared modal counter or camera rig captured.
	if _rig != null and is_instance_valid(_rig) and _rig.has_method("end_cinematic"):
		_rig.end_cinematic()
	_finish_actor_track()
	var game := get_node_or_null("/root/Game")
	if _owns_modal and game != null and game.has_method("modal_closed"):
		_owns_modal = false
		game.modal_closed()

func _build_overlay() -> void:
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.modulate.a = 0.0
	add_child(_root)

	# A restrained top matte keeps the borrowed camera feeling cinematic. The
	# caption itself is real Field Journal furniture rather than a generic black
	# letterbox, so onboarding no longer becomes an orphan visual language.
	var top_matte := ColorRect.new()
	top_matte.color = Color(Tokens.WALNUT_DEEP, 0.90)
	top_matte.anchor_right = 1.0
	top_matte.offset_bottom = 28.0
	top_matte.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(top_matte)

	var rail := PanelContainer.new()
	rail.name = "StoryCaptionRail"
	rail.theme = FIELD_THEME
	rail.theme_type_variation = &"JournalFrameContainer"
	rail.anchor_left = 0.14
	rail.anchor_right = 0.86
	rail.anchor_top = 1.0
	rail.anchor_bottom = 1.0
	rail.offset_top = -144.0
	rail.offset_bottom = -24.0
	rail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(rail)

	var walnut := PanelContainer.new()
	walnut.theme_type_variation = &"WalnutFrame"
	walnut.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rail.add_child(walnut)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", Tokens.SPACE_4)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	walnut.add_child(row)

	var glyph := Label.new()
	glyph.text = "✦"
	glyph.custom_minimum_size.x = 36.0
	glyph.theme_type_variation = &"PageTitle"
	glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	glyph.add_theme_color_override("font_color", Tokens.GOLD_MUTED)
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(glyph)

	_caption = Label.new()
	_caption.name = "StoryCaption"
	_caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_caption.theme_type_variation = &"DialogueBody"
	_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_caption.add_theme_color_override("font_color", Tokens.TEXT_ON_DARK)
	_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(_caption)

	var skip_stack := VBoxContainer.new()
	skip_stack.custom_minimum_size.x = 142.0
	skip_stack.alignment = BoxContainer.ALIGNMENT_CENTER
	skip_stack.add_theme_constant_override("separation", 0)
	skip_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(skip_stack)
	var skip_title := Label.new()
	skip_title.text = "SKIP"
	skip_title.theme_type_variation = &"Caption"
	skip_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	skip_title.add_theme_color_override("font_color", Tokens.GOLD_MUTED)
	skip_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	skip_stack.add_child(skip_title)
	var skip := Label.new()
	skip.name = "SkipLabel"
	skip.text = "Space / Esc"
	skip.theme_type_variation = &"Body"
	skip.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	skip.add_theme_color_override("font_color", Tokens.TEXT_ON_DARK_DIM)
	skip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	skip_stack.add_child(skip)

func _set_caption(text: String) -> void:
	if _caption != null:
		_caption.text = text
