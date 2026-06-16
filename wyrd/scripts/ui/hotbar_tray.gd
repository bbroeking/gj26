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
