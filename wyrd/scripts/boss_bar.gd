extends CanvasLayer

# Spec 17 — the Hedgemother boss HP banner. Hidden until she aggros.
# UI scaling is now project-level (canvas_items stretch); the old Spec-35
# per-layer UI_SCALE transform is retired so this banner sizes consistently
# with the rest of the HUD.

const FILL_LEFT := 2.0
const FILL_FULL_W := 216.0

@onready var _fill: ColorRect = $Bar/Fill
@onready var _label: Label = $Bar/Label

var _hp_max := 100
# BossBarGauge replaces the old flat WyrdUi.make_meter trough.
var _gauge: BossBarGauge = null

func _ready() -> void:
	visible = false
	var bar := get_node_or_null("Bar")
	if bar != null:
		bar.visible = false
	_gauge = BossBarGauge.new()
	_gauge.anchor_left = 0.5
	_gauge.anchor_right = 0.5
	_gauge.offset_left = -310
	_gauge.offset_right = 310
	_gauge.offset_top = 10
	add_child(_gauge)

# Called at build — set max HP and fill the bar.
func prime(mx: int) -> void:
	_hp_max = mx
	_fill.offset_right = FILL_LEFT + FILL_FULL_W
	if _gauge != null:
		_gauge.update_to(1.0, "The Hedgemother — Unyielding")

func show_boss() -> void:
	visible = true

func set_hp(cur: int, mx: int) -> void:
	_hp_max = mx
	var f := clampf(float(cur) / float(max(1, mx)), 0.0, 1.0)
	_fill.offset_right = FILL_LEFT + FILL_FULL_W * f
	if _gauge != null:
		_gauge.update_to(f, _gauge.label)

func set_phase(phase: int) -> void:
	_label.text = "The Hedgemother — Phase %d — Unyielding" % phase
	if _gauge != null:
		_gauge.update_to(_gauge.frac, _label.text)

func hide_boss() -> void:
	visible = false


# A carved boss-health banner replacing the flat make_meter trough.
# Layout (top to bottom):
#   NAME_H px — terracotta name strip (boss title in small-caps header font)
#   PLANK_H px — carved wooden plank: honey bevel, grain, gold inset border,
#                recessed HP trough with two-tone fill and low-HP danger pulse,
#                ──◆── end-cap ornaments flanking the trough opening.
class BossBarGauge extends Control:
	const NAME_H := 18.0    # terracotta boss-name header strip height
	const PLANK_H := 34.0   # carved plank housing the HP trough

	var frac: float = 1.0
	var label: String = "The Hedgemother — Unyielding"
	var _low_t: float = 0.0

	func update_to(p_frac: float, p_label: String) -> void:
		frac = clampf(p_frac, 0.0, 1.0)
		label = p_label
		queue_redraw()

	func _process(delta: float) -> void:
		if frac < 0.30:
			_low_t += delta
			queue_redraw()

	func _draw() -> void:
		var w := size.x
		# ── drop shadow under the plank ──
		draw_rect(Rect2(Vector2(4, NAME_H + 4), Vector2(w - 8, PLANK_H)),
			Color(0, 0, 0, 0.20))
		# ── terracotta name header strip ──
		var hdr := Rect2(Vector2(0, 0), Vector2(w, NAME_H))
		draw_rect(hdr, Color(WyrdUi.TERRACOTTA, 0.10))
		var hfont := WyrdUi.font_header()
		if hfont == null:
			hfont = get_theme_default_font()
		draw_string(hfont, Vector2(0, NAME_H - 4.0), label,
			HORIZONTAL_ALIGNMENT_CENTER, w, 12, WyrdUi.TERRACOTTA)
		# ── carved wooden plank ──
		var plank := Rect2(Vector2(0, NAME_H), Vector2(w, PLANK_H))
		draw_rect(plank, WyrdUi.KIT_PLATE.darkened(0.06))
		# top honey bevel
		draw_rect(Rect2(Vector2(4, NAME_H + 3), Vector2(w - 8, 3)),
			Color(1.0, 0.97, 0.86, 0.50))
		# bottom ink shadow
		draw_rect(Rect2(Vector2(4, NAME_H + PLANK_H - 5), Vector2(w - 8, 3)),
			Color(WyrdUi.KIT_EDGE, 0.35))
		WyrdUi.draw_parchment_grain(self, plank, 131)
		draw_rect(plank, WyrdUi.KIT_EDGE, false, 2.0)
		draw_rect(plank.grow(-3.5), Color(WyrdUi.GOLD, 0.45), false, 1.0)
		# ── recessed HP trough ──
		var tmx := 28.0
		var tmy := 6.0
		var tr := Rect2(Vector2(tmx, NAME_H + tmy),
			Vector2(w - tmx * 2.0, PLANK_H - tmy * 2.0))
		WyrdUi.draw_well(self, tr)
		# HP fill — two-tone terracotta body
		if frac > 0.004:
			var fw := maxf(0.0, (tr.size.x - 4.0) * frac)
			var fr := Rect2(tr.position + Vector2(2, 2),
				Vector2(fw, tr.size.y - 4.0))
			draw_rect(fr, Color(0.68, 0.20, 0.14))
			# lighter top stripe — the painted highlight
			draw_rect(Rect2(fr.position + Vector2(1, 1),
				Vector2(maxf(0.0, fw - 2.0), 3.0)),
				Color(0.85, 0.36, 0.22, 0.60))
			# low-HP danger pulse — breathing rim in the liquid's own hue
			if frac < 0.30:
				var pulse := 0.35 + 0.30 * (0.5 + 0.5 * sin(_low_t * 5.5))
				draw_rect(tr, Color(WyrdUi.TERRACOTTA, pulse), false, 2.0)
		# ── ──◆── end-cap ornaments flanking the trough opening ──
		var cy := NAME_H + PLANK_H * 0.5
		WyrdUi.draw_flourish(self, Vector2(tmx * 0.5, cy), 24.0)
		WyrdUi.draw_flourish(self, Vector2(w - tmx * 0.5, cy), 24.0)
