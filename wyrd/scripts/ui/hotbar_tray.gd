extends Control

# The plank the hotbar slots sit on. 2026-07-01 — the MapleStory tray: a rounded
# cream tray with a chunky wood-brown frame and a soft drop shadow (matches C_2 /
# maple_B_4). Falls back to the carved-enamel plank when the maple kit is absent.

func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	if WyrdUi.has_maple():
		# soft under-shadow
		var sh := StyleBoxFlat.new()
		sh.bg_color = Color(0, 0, 0, 0.22)
		sh.set_corner_radius_all(18)
		sh.corner_detail = 8
		draw_style_box(sh, Rect2(r.position + Vector2(0, 5), r.size))
		# cream tray with a wood-brown frame + a gold inner seam
		var tray := StyleBoxFlat.new()
		tray.bg_color = WyrdUi.MAPLE_CREAM
		tray.set_corner_radius_all(18)
		tray.corner_detail = 8
		tray.anti_aliasing = true
		tray.set_border_width_all(7)
		tray.border_color = WyrdUi.MAPLE_WOOD
		draw_style_box(tray, r)
		# inner light lip + gold seam
		draw_rect(Rect2(r.position + Vector2(7, 6), Vector2(r.size.x - 14, 2)),
			Color(1, 1, 0.94, 0.5))
		return
	# --- fallback: the carved-enamel plank ---
	draw_rect(Rect2(r.position + Vector2(0, 4), r.size), Color(0, 0, 0, 0.18))
	draw_rect(r, WyrdUi.KIT_PLATE.darkened(0.06))
	draw_rect(Rect2(r.position + Vector2(3, 3), Vector2(r.size.x - 6, 3)),
		Color(1.0, 0.97, 0.86, 0.5))
	draw_rect(Rect2(r.position + Vector2(3, r.size.y - 5), Vector2(r.size.x - 6, 3)),
		Color(WyrdUi.KIT_EDGE, 0.35))
	WyrdUi.draw_parchment_grain(self, r, 71)
	draw_rect(r, WyrdUi.KIT_EDGE, false, 2.0)
	draw_rect(r.grow(-4.0), Color(WyrdUi.GOLD, 0.5), false, 1.0)
	var cy := r.size.y * 0.5
	WyrdUi.draw_flourish(self, Vector2(20, cy), 24)
	WyrdUi.draw_flourish(self, Vector2(r.size.x - 20, cy), 24)
