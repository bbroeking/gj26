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
	# A flourish tucked into each end, with ivy leaf clusters flanking it.
	var cy := r.size.y * 0.5
	WyrdUi.draw_flourish(self, Vector2(20, cy), 24)
	_draw_ivy_cluster(Vector2(20, cy), false)
	WyrdUi.draw_flourish(self, Vector2(r.size.x - 20, cy), 24)
	_draw_ivy_cluster(Vector2(r.size.x - 20, cy), true)

# Three small sage-green ivy leaves growing OUTWARD from each end flourish of
# the tray into the 14 px visible margins between the tray edge and the first
# or last slot. One leaf runs along the plank centreline; two fan up/down at
# ~45°. Pure-vector, deterministic — no textures, no drift between redraws.
# facing_right=false → leaves point LEFT (left-end margin);
# facing_right=true  → leaves point RIGHT (right-end margin).
func _draw_ivy_cluster(anchor: Vector2, facing_right: bool) -> void:
	const SAGE_LEAF := Color(0.44, 0.60, 0.26, 0.82)   # muted jade, WyrdUi.SAGE register
	const SAGE_VEIN := Color(0.30, 0.44, 0.18, 0.55)
	const LEAF_STEM := Color(0.36, 0.50, 0.20, 0.60)
	var dx := 1.0 if facing_right else -1.0
	# Each entry: [base_offset, tip_offset, perp_half_width]
	# Offsets are small (≤ 16 px) so leaves stay in the visible 14 px margin.
	var leaf_defs := [
		[Vector2(dx * 4.0,  0.0), Vector2(dx * 16.0,   0.0), 4.5],   # along plank
		[Vector2(dx * 3.0, -4.0), Vector2(dx * 12.0, -12.0), 4.0],   # angled up
		[Vector2(dx * 3.0,  4.0), Vector2(dx * 12.0,  12.0), 4.0],   # angled down
	]
	for ld in leaf_defs:
		var base := anchor + (ld[0] as Vector2)
		var tip := anchor + (ld[1] as Vector2)
		var hw := float(ld[2])
		var dir := (tip - base).normalized()
		var perp := dir.rotated(PI * 0.5) * hw
		draw_colored_polygon(PackedVector2Array([base - perp, tip, base + perp]),
			SAGE_LEAF)
		draw_line(base, tip, SAGE_VEIN, 0.8)
	# Stem knot at the anchor — the cluster's root, matching the flourish centre.
	draw_circle(anchor, 2.0, LEAF_STEM)
