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
		# Ink ring + cream inner lip.
		draw_arc(m, rad, 0.0, TAU, 28, ring_c, 2.2, true)
		draw_arc(m, rad - 2.0, 0.0, TAU, 24, Color(WyrdUi.CREAM, 0.7), 1.0, true)
		# Four tiny leaf fronds (NE/NW/SE/SW): filled triangle + faint midrib spine.
		# Organic ivy marks at the diagonals so the cursor reads storybook, not
		# crosshair — the same leaf language the frame corners and bench ornament use.
		for i in 4:
			var a := PI * 0.25 + float(i) * PI * 0.5
			var d := Vector2(cos(a), sin(a))
			var perp := Vector2(-sin(a), cos(a))
			var tip := m + d * (rad + 5.5)
			var base := m + d * (rad + 0.5)
			draw_colored_polygon(
				PackedVector2Array([tip, base + perp * 2.2, base - perp * 2.2]),
				ring_c)
			# Midrib spine — a lighter stroke down the leaf centre.
			draw_line(base, tip, Color(ring_c, 0.40), 0.8)
		# Ghost rune ring — a faint arc just inside the hollow, like an inked rune
		# carved into the cursor disc. The colour follows pip_c (gold idle, sage hover).
		draw_arc(m, rad * 0.42, 0.0, TAU, 16, Color(pip_c, 0.20), 1.0)
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
