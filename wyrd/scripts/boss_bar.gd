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

var _banner: BossHPBanner = null
var _boss_name := "The Hedgemother"

func _ready() -> void:
	visible = false
	var bar := get_node_or_null("Bar")
	if bar != null:
		bar.visible = false
	# Replace the old flat trough with a hand-painted boss banner: carved wood
	# plank, thorn-seal medallion, parchment fill trough, gold endcaps.
	_banner = BossHPBanner.new()
	_banner.custom_minimum_size = Vector2(640, 56)
	_banner.anchor_left = 0.5
	_banner.anchor_right = 0.5
	_banner.offset_left = -320
	_banner.offset_top = 16
	add_child(_banner)

# Called at build — set max HP and fill the bar.
func prime(mx: int) -> void:
	_hp_max = mx
	_fill.offset_right = FILL_LEFT + FILL_FULL_W
	if _banner != null:
		_banner.update_to(1.0, _boss_name)

func show_boss() -> void:
	visible = true

func set_hp(cur: int, mx: int) -> void:
	_hp_max = mx
	var f := clampf(float(cur) / float(max(1, mx)), 0.0, 1.0)
	_fill.offset_right = FILL_LEFT + FILL_FULL_W * f
	if _banner != null:
		_banner.update_to(f, _boss_name)

func set_phase(phase: int) -> void:
	# Spec 31 — "Unyielding" suffix tells the player WHY their snares fizzle
	# on the boss. The Hedgemother is immune to root + snared (and takes burn
	# + bleed at 50% reduced duration); the tag makes that visible without a
	# hidden DR meter.
	_boss_name = "The Hedgemother — Phase %d — Unyielding" % phase
	_label.text = _boss_name
	if _banner != null:
		_banner.update_to(_banner.frac, _boss_name)

func hide_boss() -> void:
	visible = false


# A hand-painted boss HP plank: carved wood housing, thorn-seal medallion
# on the left (6 thorn spikes, parchment disc, sage crown arc, red dot),
# parchment fill trough with bramble-red liquid and bevel treatment, boss
# name in cream with ink outline, and gold ──◆── flourishes flanking the
# trough. All code-drawn via _draw (no textures, safe in CanvasLayer).
class BossHPBanner extends Control:
	var frac := 1.0
	var boss_name := "The Hedgemother"

	const _LIQUID := Color(0.65, 0.22, 0.14)   # bramble-thorn red

	func update_to(p_frac: float, p_name: String) -> void:
		frac = clampf(p_frac, 0.0, 1.0)
		boss_name = p_name
		queue_redraw()

	func _draw() -> void:
		var w := size.x
		var h := size.y
		var cy := h * 0.5

		# Soft drop shadow so the banner sits ON the scene.
		draw_rect(Rect2(Vector2(2, 5), Vector2(w, h)), Color(0, 0, 0, 0.22))

		# Carved wood plank face — same language as the hotbar tray.
		draw_rect(Rect2(Vector2.ZERO, Vector2(w, h)), WyrdUi.KIT_PLATE.darkened(0.06))
		draw_rect(Rect2(Vector2(3, 3), Vector2(w - 6, 3)),
			Color(1.0, 0.97, 0.86, 0.50))
		draw_rect(Rect2(Vector2(3, h - 5), Vector2(w - 6, 3)),
			Color(WyrdUi.KIT_EDGE, 0.35))
		draw_rect(Rect2(Vector2.ZERO, Vector2(w, h)), WyrdUi.KIT_EDGE, false, 2.0)
		draw_rect(Rect2(Vector2(4, 4), Vector2(w - 8, h - 8)),
			Color(WyrdUi.GOLD, 0.50), false, 1.0)
		WyrdUi.draw_parchment_grain(self,
			Rect2(Vector2(6, 6), Vector2(w - 12, h - 12)), 42)

		# Thorn-seal medallion on the left: a carved ring with 6 radiating
		# thorn spikes, a parchment disc, a sage crown arc, and a small red
		# centre dot — the boss reads as "dangerous wild thing" without a
		# texture icon.
		var mr := h * 0.36                     # ring radius
		var mc := Vector2(mr + 6.0, cy)        # medallion centre
		# Honey backing ring.
		draw_circle(mc, mr + 3.0, Color(0.85, 0.74, 0.52))
		# 6 thorn spikes — thin triangles pointing outward.
		for i in 6:
			var a  := float(i) / 6.0 * TAU
			var tip := mc + Vector2(cos(a), sin(a)) * (mr + 9.0)
			var b1  := mc + Vector2(cos(a - 0.36), sin(a - 0.36)) * (mr - 1.0)
			var b2  := mc + Vector2(cos(a + 0.36), sin(a + 0.36)) * (mr - 1.0)
			draw_colored_polygon(PackedVector2Array([tip, b1, b2]),
				Color(WyrdUi.KIT_EDGE, 0.88))
		# Parchment disc interior.
		draw_circle(mc, mr - 2.0, WyrdUi.KIT_PLATE)
		# Sage crown arc — a bramble-green upper crescent so the seal reads
		# as a Bramblewood heraldic mark, not a generic skull.
		draw_arc(mc, mr * 0.60, PI + 0.55, TAU - 0.55, 18,
			WyrdUi.SAGE.darkened(0.20), 2.0, false)
		# Centre dot: ink ring + terracotta core.
		draw_circle(mc, mr * 0.16, Color(WyrdUi.KIT_EDGE, 0.70))
		draw_circle(mc, mr * 0.08, WyrdUi.TERRACOTTA)
		# Outer ink ring seals the medallion.
		draw_arc(mc, mr + 3.0, 0, TAU, 48, WyrdUi.KIT_EDGE, 2.0, true)

		# Parchment fill trough — recessed well, bramble-red liquid.
		var tx := mc.x + mr + 18.0   # trough left edge
		var tw := w - tx - 10.0
		var ty := h * 0.24
		var th := h * 0.52
		WyrdUi.draw_well(self, Rect2(Vector2(tx, ty), Vector2(tw, th)))
		if frac > 0.005:
			var fw := (tw - 6.0) * frac
			var fr := Rect2(Vector2(tx + 3.0, ty + 3.0), Vector2(fw, th - 6.0))
			draw_rect(fr, _LIQUID)
			# Light highlight on top of fill (warm rose) + deep shadow at base.
			draw_rect(Rect2(fr.position, Vector2(fw, 2.0)),
				Color(1.0, 0.72, 0.60, 0.45))
			draw_rect(Rect2(fr.position + Vector2(0.0, th - 9.0),
				Vector2(fw, 2.5)), _LIQUID.darkened(0.30))

		# Boss name — cream with ink outline, centred in the trough.
		var font := get_theme_default_font()
		var name_y := ty + th * 0.5 + 5.0
		draw_string_outline(font, Vector2(tx, name_y), boss_name,
			HORIZONTAL_ALIGNMENT_CENTER, tw, 14, 4, Color(0.10, 0.07, 0.05))
		draw_string(font, Vector2(tx, name_y), boss_name,
			HORIZONTAL_ALIGNMENT_CENTER, tw, 14, WyrdUi.CREAM)

		# Gold ──◆── flourishes flanking the trough.
		WyrdUi.draw_flourish(self, Vector2(tx - 9.0, cy), 12.0)
		WyrdUi.draw_flourish(self, Vector2(w - 12.0, cy), 12.0)
