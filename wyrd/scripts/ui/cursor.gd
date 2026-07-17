extends CanvasLayer

# The storybook cursor (autoload "Cursor"). Replaces the generic OS arrow with
# a hand-drawn guiding mark: ink ring + cream lip + four thorn-bud diamonds
# (NE/NW/SE/SW) + burnished-gold center pip + soft glow. Follows the mouse,
# blooms gold when the bow fires (combat feedback — NOT an aim reticle),
# and turns sage over a clickable Button. Pure-vector via the kit, top layer.

func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		return
	layer = 200
	var mark := CursorMark.new()
	mark.set_anchors_preset(Control.PRESET_FULL_RECT)
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(mark)
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)


class CursorMark extends Control:
	var _bloom := 0.0          # 0..1, fire flash
	var _player: Node = null

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var m := get_viewport().get_mouse_position()
		# Are we over a pressable control? → clickable (sage) read.
		var hov := get_viewport().gui_get_hovered_control()
		var on_button := hov is Button or hov is LineEdit
		# Fire bloom from the local player's bow recoil.
		_player = _find_player()
		var recoil := 0.0
		if _player != null and is_instance_valid(_player):
			var r = _player.get("_fire_recoil")
			if r != null:
				recoil = clampf(absf(float(r)) / 0.2, 0.0, 1.0)
		var ring_c := WyrdUi.SAGE.darkened(0.1) if on_button else WyrdUi.INK
		var pip_c := WyrdUi.SAGE if on_button else WyrdUi.GOLD
		var rad := 7.5 + recoil * 5.0
		# Soft glow (blooms on fire).
		draw_circle(m, rad + 5.0, Color(WyrdUi.GOLD, 0.10 + recoil * 0.22))
		# Ink ring + cream inner lip.
		draw_arc(m, rad, 0.0, TAU, 28, ring_c, 2.2, true)
		draw_arc(m, rad - 2.0, 0.0, TAU, 24, Color(WyrdUi.CREAM, 0.7), 1.0, true)
		# Four thorn-bud diamonds (NE/NW/SE/SW): outward-pointing leaf thorns that
		# rhyme with the center pip and evoke Bramblewood's vine motif. Never reads
		# as a cardinal crosshair; the inward base sits just off the ring.
		for i in 4:
			var a := PI * 0.25 + float(i) * PI * 0.5
			var d := Vector2(cos(a), sin(a))
			var dc := m + d * (rad + 2.5)
			var perp := Vector2(-d.y, d.x)
			draw_colored_polygon(PackedVector2Array([
				dc + d * 3.0,
				dc + perp * 1.5,
				dc - d * 2.0,
				dc - perp * 1.5,
			]), ring_c)
		# Burnished center pip — a tiny gold diamond.
		var s := 2.6 + recoil * 1.6
		draw_colored_polygon(PackedVector2Array([
			m + Vector2(0, -s), m + Vector2(s, 0),
			m + Vector2(0, s), m + Vector2(-s, 0)]), pip_c)
		draw_polyline(PackedVector2Array([
			m + Vector2(0, -s), m + Vector2(s, 0), m + Vector2(0, s),
			m + Vector2(-s, 0), m + Vector2(0, -s)]), WyrdUi.INK, 1.0)

	func _find_player() -> Node:
		if _player != null and is_instance_valid(_player):
			return _player
		var game := get_tree().root.get_node_or_null("Game")
		if game != null and game.has_method("local_player"):
			return game.local_player()
		return get_tree().get_first_node_in_group("player")
