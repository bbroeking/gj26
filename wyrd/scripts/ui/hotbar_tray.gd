extends Control

# The carved wooden plank the hotbar slots sit on. A darkened parchment face
# with a top honey bevel + bottom ink shadow, a gold inner inset line, a pass
# of parchment grain, flourishes at each end, and ivy/vine corner clusters —
# so the most-seen HUD surface reads as a living, botanical crafted object
# rather than a plain carved plank. The ivy echoes the globe-cradle bramble
# knots that flank the bar on either side.

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
	# Ivy corner clusters — three-sprig vine ornament in the frame zone above
	# the slot row. xdir = +1 sprouts rightward (left corner), -1 leftward.
	_draw_ivy_corner(Vector2(8.0, 7.0), 1.0)
	_draw_ivy_corner(Vector2(r.size.x - 8.0, 7.0), -1.0)
	# A flourish tucked into each end.
	var cy := r.size.y * 0.5
	WyrdUi.draw_flourish(self, Vector2(20, cy), 24)
	WyrdUi.draw_flourish(self, Vector2(r.size.x - 20, cy), 24)


# Three ivy sprigs fanning from a top corner of the plank. The longest arm
# reaches diagonally inward, a shorter arm drops steeply, and a side branchlet
# curls toward the frame edge. All within the ~12 px frame strip above the
# slot row, so the drawing stays in the ornament zone, not the content zone.
func _draw_ivy_corner(origin: Vector2, xdir: float) -> void:
	var sepia := Color(WyrdUi.KIT_EDGE, 0.55)
	# Sprig A — main diagonal arm (longest; the eye goes here first).
	var a_tip := origin + Vector2(xdir * 11.0, 9.0)
	draw_line(origin, a_tip, sepia, 1.4)
	_draw_leaf(a_tip, xdir * 0.78, 0.63)
	# Sprig B — steeper downward arm (inner; shows the vine has weight).
	var b_tip := origin + Vector2(xdir * 5.0, 14.0)
	draw_line(origin, b_tip, sepia, 1.2)
	_draw_leaf(b_tip, xdir * 0.34, 0.94)
	# Branchlet off the mid of sprig A — curls back toward the frame top.
	var amid := origin + Vector2(xdir * 5.5, 4.5)
	var c_tip := amid + Vector2(xdir * 5.0, -5.0)
	draw_line(amid, c_tip, sepia, 0.9)
	_draw_leaf(c_tip, xdir * 0.70, -0.72)
	# Terracotta berry at the branch junction — the bramble's "alive" mark.
	draw_circle(amid, 2.0, Color(WyrdUi.TERRACOTTA, 0.62))
	draw_arc(amid, 2.0, 0.0, TAU, 10, sepia, 0.8, true)


# A 4-point sage-green leaf diamond at tip, oriented along axis (dx, dy).
# Vein line from base to tip gives it botanical depth without extra weight.
func _draw_leaf(tip: Vector2, dx: float, dy: float) -> void:
	var leaf_col := Color(WyrdUi.SAGE, 0.52)
	var s := 4.0
	var ax := Vector2(dx, dy).normalized()
	var px := Vector2(-ax.y, ax.x)
	draw_colored_polygon(PackedVector2Array([
		tip + ax * s,
		tip + px * (s * 0.56),
		tip - ax * (s * 0.36),
		tip - px * (s * 0.56)
	]), leaf_col)
	draw_line(tip - ax * (s * 0.36), tip + ax * s,
		Color(WyrdUi.SAGE.darkened(0.30), 0.40), 0.8)
