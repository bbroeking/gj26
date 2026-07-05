extends CanvasLayer

# Spec 17 — the Hedgemother boss HP banner. Hidden until she aggros.
# UI scaling is now project-level (canvas_items stretch); the old Spec-35
# per-layer UI_SCALE transform is retired so this banner sizes consistently
# with the rest of the HUD.

const FILL_LEFT := 4.0
const FILL_FULL_W := 592.0

@onready var _fill: ColorRect = $Bar/Fill
@onready var _label: Label = $Bar/Label

var _hp_max := 100

var _bar: BossBarControl = null

func _ready() -> void:
	visible = false
	# Carved wooden banner — same plank grammar as the hotbar tray so the
	# boss bar reads as a crafted object floating above the world, not a
	# flat engine UI. Replaces the plain WyrdUi.make_meter() trough.
	var bar := get_node_or_null("Bar")
	if bar != null:
		bar.visible = false
	_bar = BossBarControl.new()
	_bar.custom_minimum_size = Vector2(600, 46)
	_bar.anchor_left = 0.5
	_bar.anchor_right = 0.5
	_bar.offset_left = -300
	_bar.offset_top = 14
	add_child(_bar)

# Called at build — set max HP and fill the bar.
func prime(mx: int) -> void:
	_hp_max = mx
	_fill.offset_right = FILL_LEFT + FILL_FULL_W
	if _bar != null:
		_bar.update(1.0, "The Hedgemother — Unyielding")

func show_boss() -> void:
	visible = true

func set_hp(cur: int, mx: int) -> void:
	_hp_max = mx
	var f := clampf(float(cur) / float(max(1, mx)), 0.0, 1.0)
	_fill.offset_right = FILL_LEFT + FILL_FULL_W * f
	if _bar != null:
		_bar.update(f, _bar.boss_name)

func set_phase(phase: int) -> void:
	# Spec 31 — "Unyielding" suffix tells the player WHY their snares fizzle
	# on the boss. The Hedgemother is immune to root + snared (and takes burn
	# + bleed at 50% reduced duration); the tag makes that visible without a
	# hidden DR meter.
	_label.text = "The Hedgemother — Phase %d — Unyielding" % phase
	if _bar != null:
		_bar.update(_bar.frac, _label.text)

func hide_boss() -> void:
	visible = false


# Carved wooden banner for the boss HP. Shares the hotbar tray's plank
# grammar: honey top-bevel, ink bottom-shadow, sparse parchment grain,
# ink border + gold inset, end flourishes. The boss name sits above a
# recessed crimson HP trough so the read is immediately legible.
class BossBarControl extends Control:
	var frac := 1.0
	var boss_name := "The Hedgemother — Unyielding"

	const FILL_COL := Color(0.69, 0.30, 0.20, 0.9)
	const BAR_TOP := 30.0
	const BAR_H := 12.0

	func update(p_frac: float, p_name: String) -> void:
		frac = clampf(p_frac, 0.0, 1.0)
		boss_name = p_name
		queue_redraw()

	func _draw() -> void:
		var w := size.x
		var h := size.y
		# Soft drop shadow so the banner sits ON the world, not floating flat.
		draw_rect(Rect2(Vector2(0, 4), size), Color(0, 0, 0, 0.20))
		# Carved plank face (matches hotbar_tray).
		draw_rect(Rect2(Vector2.ZERO, size), WyrdUi.KIT_PLATE.darkened(0.07))
		# Top honey bevel + bottom ink shadow.
		draw_rect(Rect2(Vector2(3, 3), Vector2(w - 6, 3)),
			Color(1.0, 0.97, 0.86, 0.50))
		draw_rect(Rect2(Vector2(3, h - 5), Vector2(w - 6, 3)),
			Color(WyrdUi.KIT_EDGE, 0.35))
		WyrdUi.draw_parchment_grain(self, Rect2(Vector2.ZERO, size), 13)
		# Ink border + burnished gold inset line.
		draw_rect(Rect2(Vector2.ZERO, size), WyrdUi.KIT_EDGE, false, 2.0)
		draw_rect(Rect2(Vector2(4, 4), Vector2(w - 8, h - 8)),
			Color(WyrdUi.GOLD, 0.45), false, 1.0)
		# End flourishes — ── ◆ ── bookend the banner on each side.
		var cy := h * 0.5
		WyrdUi.draw_flourish(self, Vector2(22, cy), 28)
		WyrdUi.draw_flourish(self, Vector2(w - 22, cy), 28)
		# Boss name centred above the HP bar, terracotta header font.
		var hdr := WyrdUi.font_header()
		if hdr == null:
			hdr = get_theme_default_font()
		draw_string(hdr, Vector2(w * 0.5, BAR_TOP - 2.0), boss_name,
			HORIZONTAL_ALIGNMENT_CENTER, w - 110.0, 14, WyrdUi.TERRACOTTA)
		# Recessed HP trough.
		var trough := Rect2(Vector2(48.0, BAR_TOP), Vector2(w - 96.0, BAR_H))
		WyrdUi.draw_well(self, trough, WyrdUi.KIT_WELL)
		if frac > 0.002:
			var fw := (trough.size.x - 4.0) * frac
			var fill_r := Rect2(trough.position + Vector2(2, 2),
				Vector2(fw, trough.size.y - 4.0))
			draw_rect(fill_r, FILL_COL)
			# Warm highlight stripe along the top of the fill.
			draw_rect(Rect2(fill_r.position, Vector2(fw, 2.0)),
				Color(1.0, 0.72, 0.66, 0.38))
