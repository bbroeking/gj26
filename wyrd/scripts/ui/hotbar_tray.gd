extends Control

# The carved wooden plank the hotbar slots sit on. A darkened parchment face
# with a top honey bevel + bottom ink shadow, a gold inner inset line, a pass
# of parchment grain, and a small flourish at each end — so the most-seen HUD
# surface reads as a crafted object, not a flat engine panel.

func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	# Soft drop shadow so the tray sits ON the world, not flat against it.
	draw_rect(Rect2(r.position + Vector2(0, 4), r.size), Color(0, 0, 0, 0.18))
	# Plank face.
	draw_rect(r, WyrdUi.KIT_PLATE.darkened(0.06))
	# Top honey bevel + bottom ink shadow.
	draw_rect(Rect2(r.position + Vector2(3, 3), Vector2(r.size.x - 6, 3)),
		Color(1.0, 0.97, 0.86, 0.5))
	draw_rect(Rect2(r.position + Vector2(3, r.size.y - 5), Vector2(r.size.x - 6, 3)),
		Color(WyrdUi.KIT_EDGE, 0.35))
	WyrdUi.draw_parchment_grain(self, r, 71)
	# Ink border + a gold inner inset line (the "burnished" read).
	draw_rect(r, WyrdUi.KIT_EDGE, false, 2.0)
	draw_rect(r.grow(-4.0), Color(WyrdUi.GOLD, 0.5), false, 1.0)
	# A flourish tucked into each end.
	var cy := r.size.y * 0.5
	WyrdUi.draw_flourish(self, Vector2(20, cy), 24)
	WyrdUi.draw_flourish(self, Vector2(r.size.x - 20, cy), 24)
	# Ivy leaf sprigs at the top corners — vine ornament on the plank's carved
	# frame; they live in the 12 px band above the slots so they never clip gear.
	_draw_corner_sprig(Vector2(5.0, 4.0), 1.0)
	_draw_corner_sprig(Vector2(r.size.x - 5.0, 4.0), -1.0)

# A small bramble sprig: a short vine tendril + two paired leaf strokes + a bud.
# dir +1 grows rightward (left corner), -1 grows leftward (right corner).
func _draw_corner_sprig(origin: Vector2, dir: float) -> void:
	var vine  := Color(WyrdUi.SAGE.darkened(0.40), 0.55)
	var leaf_a := Color(WyrdUi.SAGE, 0.68)
	var leaf_b := Color(WyrdUi.SAGE.darkened(0.18), 0.52)
	var tip := origin + Vector2(dir * 17.0, 8.0)
	draw_line(origin, tip, vine, 1.2)
	var s0 := origin + Vector2(dir * 5.5, 2.5)
	draw_line(s0, s0 + Vector2(dir * 3.5, -4.5), leaf_a, 1.0)
	draw_line(s0, s0 + Vector2(dir * 1.5,  4.5), leaf_b, 0.8)
	var s1 := origin + Vector2(dir * 11.5, 5.5)
	draw_line(s1, s1 + Vector2(dir * 4.0, -5.0), leaf_a, 1.0)
	draw_line(s1, s1 + Vector2(dir * 2.0,  4.0), leaf_b, 0.8)
	draw_circle(tip, 1.8, Color(WyrdUi.SAGE.darkened(0.05), 0.52))
