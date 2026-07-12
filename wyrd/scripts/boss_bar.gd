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

# Replaces make_meter — a carved parchment boss bar with bevel, grain, and IM Fell name.
var _bar_view: BossBarArt = null

func _ready() -> void:
	visible = false
	# Wyrd UI overhaul — replace the flat make_meter trough with a drawn art bar.
	var bar := get_node_or_null("Bar")
	if bar != null:
		bar.visible = false
	_bar_view = BossBarArt.new()
	_bar_view.anchor_left = 0.5
	_bar_view.anchor_right = 0.5
	_bar_view.offset_left = -308
	_bar_view.offset_right = 308
	_bar_view.offset_top = 12
	_bar_view.offset_bottom = 52
	add_child(_bar_view)

# Called at build — set max HP and fill the bar.
func prime(mx: int) -> void:
	_hp_max = mx
	_fill.offset_right = FILL_LEFT + FILL_FULL_W
	if _bar_view != null:
		_bar_view.update_to(1.0, "The Hedgemother — Unyielding")

func show_boss() -> void:
	visible = true

func set_hp(cur: int, mx: int) -> void:
	_hp_max = mx
	var f := clampf(float(cur) / float(max(1, mx)), 0.0, 1.0)
	_fill.offset_right = FILL_LEFT + FILL_FULL_W * f
	if _bar_view != null:
		_bar_view.update_to(f, _bar_view.label_text)

func set_phase(phase: int) -> void:
	# Spec 31 — "Unyielding" suffix tells the player WHY their snares fizzle
	# on the boss. The Hedgemother is immune to root + snared (and takes burn
	# + bleed at 50% reduced duration); the tag makes that visible without a
	# hidden DR meter.
	_label.text = "The Hedgemother — Phase %d — Unyielding" % phase
	if _bar_view != null:
		_bar_view.update_to(_bar_view.frac, _label.text)

func hide_boss() -> void:
	visible = false


# ---- Carved parchment boss bar ----
# A 616×40px drawn banner: KIT_PLATE trough with a carved inner shadow, a
# terracotta fill with a warm-light gleam at the top edge, a gold pinstripe
# border, sparse parchment grain, and a draw_flourish ornament at each end.
# The boss name is drawn in IM Fell SC with a dark ink outline so it reads
# over the fill color at any HP level.
class BossBarArt extends Control:
	var frac := 1.0
	var label_text := "The Hedgemother — Unyielding"
	const FILL_COLOR := Color(0.69, 0.30, 0.20, 0.92)

	func update_to(f: float, lbl: String) -> void:
		frac = clampf(f, 0.0, 1.0)
		label_text = lbl
		queue_redraw()

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		# Parchment face — slightly darker than KIT_PLATE so the fill pops.
		draw_rect(r, WyrdUi.KIT_PLATE.darkened(0.06))
		# Top inner shadow — two steps so the trough reads as carved.
		draw_rect(Rect2(r.position + Vector2(3, 2), Vector2(r.size.x - 6, 2)),
			Color(0, 0, 0, 0.16))
		draw_rect(Rect2(r.position + Vector2(2, 2), Vector2(2, r.size.y - 4)),
			Color(0, 0, 0, 0.11))
		# Terracotta fill — a warm light gleam along the top edge of the fill.
		if frac > 0.002:
			var fw := (r.size.x - 6) * frac
			var fr := Rect2(r.position + Vector2(3, 3), Vector2(fw, r.size.y - 6))
			draw_rect(fr, FILL_COLOR)
			draw_rect(Rect2(fr.position, Vector2(fw, 2)),
				Color(1.0, 0.72, 0.58, 0.28))
		# Bottom light lip — the bright underside of the carved edge.
		draw_rect(Rect2(r.position + Vector2(3, r.size.y - 4),
			Vector2(r.size.x - 6, 2)), Color(1.0, 1.0, 0.90, 0.18))
		# Parchment grain across the whole bar face (very faint; seed 31).
		WyrdUi.draw_parchment_grain(self, r.grow(-2), 31)
		# Ink border + gold inner pinstripe (the "burnished plank" language).
		draw_rect(r, WyrdUi.KIT_EDGE, false, 2.0)
		draw_rect(r.grow(-3.5), Color(WyrdUi.GOLD, 0.30), false, 1.0)
		# Flourishes at each end as end-stops — mirrors the hotbar tray ornament.
		var cy := r.size.y * 0.5
		WyrdUi.draw_flourish(self, Vector2(22, cy), 28)
		WyrdUi.draw_flourish(self, Vector2(r.size.x - 22, cy), 28)
		# Boss name centred in the bar: IM Fell SC with a dark outline so it
		# reads cleanly over the fill at any health level.
		var hdr := WyrdUi.font_header()
		var font := get_theme_default_font()
		if hdr == null:
			hdr = font
		draw_string_outline(hdr, Vector2(0, cy + 6), label_text,
			HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 15,
			4, Color(0.12, 0.09, 0.06, 0.9))
		draw_string(hdr, Vector2(0, cy + 6), label_text,
			HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 15,
			Color(0.97, 0.94, 0.86))
