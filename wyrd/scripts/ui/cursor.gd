extends CanvasLayer

# The storybook cursor (autoload "Cursor"). The OS pointer stays hidden so this
# cursor is captured consistently in native + web builds. The source art stays
# 48px for clean high-DPI edges, but is drawn at a restrained 32px game scale.
# Actionable hover gets a small eased lift and glow; semantic pips preserve the
# chart-table states without swapping the pointer's silhouette.

const CURSOR_WAYFINDER: Texture2D = preload("res://assets/ui/cursor_wayfinder_v2.png")
const HOTSPOT := Vector2(2, 2)
const BASE_DISPLAY_SCALE := 0.66
const HOVER_DISPLAY_SCALE := 0.72


func cursor_click_scale(press_amount: float) -> float:
	return lerpf(1.0, 0.84, clampf(press_amount, 0.0, 1.0))

func cursor_display_scale(is_actionable: bool) -> float:
	return HOVER_DISPLAY_SCALE if is_actionable else BASE_DISPLAY_SCALE


func cursor_kind_for(hovered: Control) -> String:
	if hovered == null:
		return "world"
	var node: Node = hovered
	while node is Control:
		# Complex crafting surfaces attach a semantic role to their real Controls.
		# The cursor keeps the same painted bitmaps; small code-drawn badges below
		# communicate the finer state without multiplying pointer assets.
		if node.has_meta("cursor_role"):
			return String(node.get_meta("cursor_role"))
		if node is BaseButton or node is LineEdit or node is TextEdit \
				or node is Range or node is ItemList or node is Tree:
			return "interactive"
		node = node.get_parent()
	return "panel"

func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		return
	layer = 1000
	var mark := CursorMark.new()
	mark.classify_hover = cursor_kind_for
	mark.click_scale = cursor_click_scale
	mark.cursor_texture = CURSOR_WAYFINDER
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(mark)
	mark.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)


class CursorMark extends Control:
	var classify_hover: Callable
	var click_scale: Callable
	var cursor_texture: Texture2D
	var _player: Node = null
	var _press_amount := 0.0
	var _hover_amount := 0.0
	var _click_age := 1.0
	var _was_pressed := false
	var _kind := "world"

	func _process(delta: float) -> void:
		var pressed := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
		if pressed and not _was_pressed:
			_click_age = 0.0
		_was_pressed = pressed
		_press_amount = move_toward(_press_amount, 1.0 if pressed else 0.0,
			delta * (16.0 if pressed else 10.0))
		var hovered := get_viewport().gui_get_hovered_control()
		_kind = String(classify_hover.call(hovered)) if classify_hover.is_valid() else "world"
		var actionable := _is_actionable(_kind)
		_hover_amount = move_toward(_hover_amount, 1.0 if actionable else 0.0,
			delta * (9.0 if actionable else 12.0))
		_click_age += delta
		queue_redraw()

	func _draw() -> void:
		var m := get_viewport().get_mouse_position()
		# Fire bloom from the local player's bow recoil.
		_player = _find_player()
		var recoil := 0.0
		if _player != null and is_instance_valid(_player):
			var r = _player.get("_fire_recoil")
			if r != null:
				recoil = clampf(absf(float(r)) / 0.2, 0.0, 1.0)
		if _click_age < 0.30:
			var ring_t := clampf(_click_age / 0.30, 0.0, 1.0)
			draw_arc(m, lerpf(5.0, 17.0, ring_t), 0.0, TAU, 24,
				Color(WyrdUi.MAPLE_GREEN, (1.0 - ring_t) * 0.62), 1.7, true)
		# Hover feedback begins at the hotspot, not beyond the cursor silhouette:
		# a quiet halo makes controls feel magnetic without obscuring their art.
		if _hover_amount > 0.01:
			draw_circle(m + Vector2(2, 2), lerpf(5.0, 8.0, _hover_amount),
				Color(WyrdUi.MAPLE_CREAM, 0.12 * _hover_amount))
		if _kind in ["interactive", "component", "inspect_result", "codex",
				"codex_page", "action"]:
			var pip := m + Vector2(20, 5)
			draw_circle(pip, 4.0, Color(WyrdUi.SAGE, 0.18 + 0.16 * _hover_amount))
			draw_arc(pip, 4.0, 0.0, TAU, 16, WyrdUi.MAPLE_WOOD_D, 1.0, true)
		elif _kind in ["place_valid", "ghost_stage"]:
			var ok := m + Vector2(20, 5)
			draw_circle(ok, 4.5, Color(WyrdUi.MAPLE_GREEN, 0.80))
			draw_arc(ok, 4.5, 0.0, TAU, 16, WyrdUi.MAPLE_WOOD_D, 1.0, true)
			draw_line(ok + Vector2(-2.5, 0), ok + Vector2(-0.5, 2),
				Color.WHITE, 1.2, true)
			draw_line(ok + Vector2(-0.5, 2), ok + Vector2(3, -2.5),
				Color.WHITE, 1.2, true)
		elif _kind in ["place_invalid", "ghost_unavailable"]:
			var no := m + Vector2(20, 5)
			draw_circle(no, 4.5, Color(WyrdUi.TERRACOTTA, 0.82))
			draw_arc(no, 4.5, 0.0, TAU, 16, WyrdUi.MAPLE_WOOD_D, 1.0, true)
			draw_line(no + Vector2(-2.2, -2.2), no + Vector2(2.2, 2.2),
				Color.WHITE, 1.2, true)
			draw_line(no + Vector2(2.2, -2.2), no + Vector2(-2.2, 2.2),
				Color.WHITE, 1.2, true)
		if recoil > 0.12:
			draw_circle(m + Vector2(8, 8), 12.0,
				Color(WyrdUi.TERRACOTTA, 0.12 + recoil * 0.12))
		if cursor_texture != null:
			var scale_amount := lerpf(BASE_DISPLAY_SCALE, HOVER_DISPLAY_SCALE,
				_hover_amount)
			if click_scale.is_valid():
				scale_amount *= float(click_scale.call(_press_amount))
			draw_set_transform(m, -0.025 * _hover_amount - 0.04 * _press_amount,
				Vector2(scale_amount, scale_amount))
			draw_texture(cursor_texture, -HOTSPOT,
				Color(WyrdUi.TERRACOTTA).lerp(Color.WHITE, 0.72)
					if recoil > 0.12 else Color.WHITE)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	func _is_actionable(kind: String) -> bool:
		return kind in ["interactive", "component", "inspect_result", "codex",
			"codex_page", "action", "place_valid", "ghost_stage",
			"place_invalid", "ghost_unavailable"]

	func _find_player() -> Node:
		if _player != null and is_instance_valid(_player):
			return _player
		var game := get_tree().root.get_node_or_null("Game")
		if game != null and game.has_method("local_player"):
			return game.local_player()
		return null
