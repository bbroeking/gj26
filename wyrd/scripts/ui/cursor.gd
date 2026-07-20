extends CanvasLayer

# The storybook cursor (autoload "Cursor"). The OS pointer stays hidden so this
# cursor is captured consistently in native + web builds. It uses the painted
# ink-arrow assets over both the world and UI; panels add the sage hover pip and
# pressable controls add a small pulse. This keeps the pointer legible against
# the cream modal skin, where the old cream/gold ring nearly disappeared.

const CURSOR_DEFAULT: Texture2D = preload("res://assets/ui/cursor_default.png")
const CURSOR_INTERACT: Texture2D = preload("res://assets/ui/cursor_interact.png")
const CURSOR_ATTACK: Texture2D = preload("res://assets/ui/cursor_attack.png")
const HOTSPOT := Vector2(3, 2)


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
	mark.default_texture = CURSOR_DEFAULT
	mark.interact_texture = CURSOR_INTERACT
	mark.attack_texture = CURSOR_ATTACK
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(mark)
	mark.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)


class CursorMark extends Control:
	var classify_hover: Callable
	var default_texture: Texture2D
	var interact_texture: Texture2D
	var attack_texture: Texture2D
	var _player: Node = null

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var m := get_viewport().get_mouse_position()
		var hovered := get_viewport().gui_get_hovered_control()
		var kind := "world"
		if classify_hover.is_valid():
			kind = String(classify_hover.call(hovered))
		# Fire bloom from the local player's bow recoil.
		_player = _find_player()
		var recoil := 0.0
		if _player != null and is_instance_valid(_player):
			var r = _player.get("_fire_recoil")
			if r != null:
				recoil = clampf(absf(float(r)) / 0.2, 0.0, 1.0)
		var texture := default_texture
		if recoil > 0.12:
			texture = attack_texture
		elif kind != "world":
			texture = interact_texture
		if kind in ["interactive", "component", "inspect_result", "codex",
				"codex_page", "action"]:
			var pip := m + Vector2(21, 4)
			draw_circle(pip, 6.0, Color(WyrdUi.SAGE, 0.24))
			draw_arc(pip, 6.0, 0.0, TAU, 20, WyrdUi.MAPLE_WOOD_D, 1.2, true)
		elif kind in ["place_valid", "ghost_stage"]:
			var ok := m + Vector2(21, 4)
			draw_circle(ok, 6.0, Color(WyrdUi.MAPLE_GREEN, 0.80))
			draw_arc(ok, 6.0, 0.0, TAU, 20, WyrdUi.MAPLE_WOOD_D, 1.2, true)
			draw_line(ok + Vector2(-3, 0), ok + Vector2(-1, 3),
				Color.WHITE, 1.5, true)
			draw_line(ok + Vector2(-1, 3), ok + Vector2(4, -3),
				Color.WHITE, 1.5, true)
		elif kind in ["place_invalid", "ghost_unavailable"]:
			var no := m + Vector2(21, 4)
			draw_circle(no, 6.0, Color(WyrdUi.TERRACOTTA, 0.82))
			draw_arc(no, 6.0, 0.0, TAU, 20, WyrdUi.MAPLE_WOOD_D, 1.2, true)
			draw_line(no + Vector2(-3, -3), no + Vector2(3, 3),
				Color.WHITE, 1.5, true)
			draw_line(no + Vector2(3, -3), no + Vector2(-3, 3),
				Color.WHITE, 1.5, true)
		if recoil > 0.12:
			draw_circle(m + Vector2(12, 12), 18.0,
				Color(WyrdUi.TERRACOTTA, 0.12 + recoil * 0.12))
		if texture != null:
			draw_texture(texture, m - HOTSPOT)

	func _find_player() -> Node:
		if _player != null and is_instance_valid(_player):
			return _player
		var game := get_tree().root.get_node_or_null("Game")
		if game != null and game.has_method("local_player"):
			return game.local_player()
		return null
