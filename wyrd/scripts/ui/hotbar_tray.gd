extends Control

# The carved wooden plank the hotbar slots sit on. A darkened parchment face
# with a top honey bevel + bottom ink shadow, a gold inner inset line, a pass
# of parchment grain, and a small flourish at each end — so the most-seen HUD
# surface reads as a crafted object, not a flat engine panel.
#
# Artistic pass — carved ivy tendrils branch from each end flourish toward
# the tray edges, evoking Bramblewood woodwork. Design language: leafy ivy on
# frames; sage green; no ornament on body text. Two tendrils per end (up +
# down), each with two leaf-lobes drawn as four-point polygons.

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
	# Central flourish at each end.
	var cy := r.size.y * 0.5
	WyrdUi.draw_flourish(self, Vector2(20, cy), 24)
	WyrdUi.draw_flourish(self, Vector2(r.size.x - 20, cy), 24)
	# Carved ivy tendrils branching from each flourish — up and down the plank
	# face. lean_dir +1 = leans toward tray centre (left-end); -1 = right-end.
	_draw_end_ivy(20.0, cy, 1.0)
	_draw_end_ivy(r.size.x - 20.0, cy, -1.0)


# Two tendrils (upward + downward) rooted at the flourish diamond.
func _draw_end_ivy(cx: float, cy: float, lean: float) -> void:
	_draw_ivy_tendril(cx, cy, lean, -1.0)   # grows toward top edge
	_draw_ivy_tendril(cx, cy, lean,  1.0)   # grows toward bottom edge


# One tendril: two stem nodes in a gentle S-curve with one leaf-lobe at each.
# vy = -1 grows up; +1 grows down. lean = signed inward direction (+1 / -1).
func _draw_ivy_tendril(cx: float, cy: float, lean: float, vy: float) -> void:
	var sage := Color(WyrdUi.SAGE, 0.68)
	# Dark olive stem colour so the vine reads as wood-grain, not floating paint.
	var stem_c := Color(0.28, 0.34, 0.17, 0.58)
	# Two nodes of the stem — slight S-bend, curving inward then outward.
	var p0 := Vector2(cx,               cy + vy * 3.5)
	var p1 := Vector2(cx + lean * 4.5,  cy + vy * 9.0)
	var p2 := Vector2(cx + lean * 6.0,  cy + vy * 16.0)
	draw_line(p0, p1, stem_c, 1.1, true)
	draw_line(p1, p2, stem_c, 1.0, true)
	# First leaf-lobe at p1 — fans away from the stem line on the outer side.
	_draw_ivy_leaf(p1, Vector2(-lean * 5.5, vy * 3.5), sage)
	# Second leaf-lobe at the tip p2 — slightly smaller, a touch lighter.
	_draw_ivy_leaf(p2, Vector2(lean * 3.5, vy * 4.5), sage.lightened(0.06))


# A four-point leaf (almond/teardrop shape). base is the leaf root on the stem;
# tip_off points from base to the leaf tip. Width comes from the perpendicular.
func _draw_ivy_leaf(base: Vector2, tip_off: Vector2, col: Color) -> void:
	var tip := base + tip_off
	# 90° CCW perpendicular scaled to ~40% of tip length → shoulder width.
	var perp := Vector2(-tip_off.y, tip_off.x) * 0.40
	var pts := PackedVector2Array([
		base,
		base + tip_off * 0.5 + perp,
		tip,
		base + tip_off * 0.5 - perp
	])
	draw_colored_polygon(pts, Color(col, 0.70))
	# Faint ink outline so the leaf reads as carved, not a floating wash.
	draw_polyline(pts + PackedVector2Array([pts[0]]),
		Color(col.darkened(0.30), 0.44), 0.8, true)
