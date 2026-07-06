extends CanvasLayer

# The storybook cursor (autoload "Cursor"). Replaces the generic OS arrow with
# a hand-drawn guiding mark: an ink ring + cream lip + a burnished-gold center
# pip and a soft glow. It follows the mouse, blooms gold when the bow fires
# (real combat feedback — aim is WASD/soft-aim, so this is NOT an aim reticle),
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
		# Organic ink ring + cream inner lip — wobbly polylines so the cursor reads
		# as a hand-stamped wayfinder's mark rather than a geometric engine circle.
		var n_ring := 34
		var ring_pts := PackedVector2Array()
		var lip_pts := PackedVector2Array()
		for i in n_ring + 1:
			var a := TAU * float(i) / float(n_ring)
			var dr := sin(a * 3.0) * 0.55 + cos(a * 5.0) * 0.35
			ring_pts.append(m + Vector2(cos(a), sin(a)) * (rad + dr))
			lip_pts.append(m + Vector2(cos(a), sin(a)) * (rad - 2.0 + dr))
		draw_polyline(ring_pts, ring_c, 2.2, true)
		draw_polyline(lip_pts, Color(WyrdUi.CREAM, 0.7), 1.0, true)
		# Four diagonal ticks (NE/NW/SE/SW — not a crosshair) each tipped with a
		# tiny ivy-leaf bud: a filled teardrop that reads as botanical, not targety.
		for i in 4:
			var a := PI * 0.25 + float(i) * PI * 0.5
			var d := Vector2(cos(a), sin(a))
			var perp := Vector2(-d.y, d.x)
			draw_line(m + d * (rad + 1.5), m + d * (rad + 4.5), ring_c, 1.6, true)
			var bud_tip := m + d * (rad + 8.0)
			var bud_base := m + d * (rad + 4.5)
			draw_colored_polygon(PackedVector2Array([
				bud_base - perp * 2.2, bud_tip, bud_base + perp * 2.2]), ring_c)
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
