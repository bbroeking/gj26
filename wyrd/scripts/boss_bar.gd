extends CanvasLayer

# Spec 17 — the Hedgemother boss HP banner. Hidden until she aggros.
# UI scaling is now project-level (canvas_items stretch); the old Spec-35
# per-layer UI_SCALE transform is retired so this banner sizes consistently
# with the rest of the HUD.
#
# UI art pass — replaces bare make_meter with a _BossBarView that draws:
#   • a carved parchment name-plate (KIT_PLATE face, gold inner ring,
#     parchment grain, draw_flourish ornaments flanking the boss name)
#   • a recessed health trough (draw_well + watercolor fill stripe)
# This makes the boss encounter read as meeting a named creature from a
# storybook, not clearing a health bar on a flat engine panel.

const FILL_LEFT := 4.0
const FILL_FULL_W := 592.0

@onready var _fill: ColorRect = $Bar/Fill
@onready var _label: Label = $Bar/Label

var _hp_max := 100
var _view: Control   # _BossBarView instance; properties set via dynamic access


func _ready() -> void:
	visible = false
	var bar := get_node_or_null("Bar")
	if bar != null:
		bar.visible = false
	var v := _BossBarView.new()
	v.anchor_left = 0.5
	v.anchor_right = 0.5
	v.offset_left = -340
	v.offset_top = 8
	v.custom_minimum_size = Vector2(680, 68)
	v.size = Vector2(680, 68)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(v)
	_view = v


func prime(mx: int) -> void:
	_hp_max = mx
	_fill.offset_right = FILL_LEFT + FILL_FULL_W
	if _view != null:
		_view._ratio = 1.0
		_view.queue_redraw()


func show_boss() -> void:
	visible = true


func set_hp(cur: int, mx: int) -> void:
	_hp_max = mx
	var f := clampf(float(cur) / float(max(1, mx)), 0.0, 1.0)
	_fill.offset_right = FILL_LEFT + FILL_FULL_W * f
	if _view != null:
		_view._ratio = f
		_view.queue_redraw()


func set_phase(phase: int) -> void:
	_label.text = "The Hedgemother — Phase %d — Unyielding" % phase
	if _view != null:
		_view._boss_name = _label.text
		_view.queue_redraw()


func hide_boss() -> void:
	visible = false


# ---- drawn boss banner ----
# A carved parchment name plate above a recessed health trough. The plate
# reads as a "named creature card" — the same design language as vendor
# cards and skill cards, but scaled to a dramatic boss moment: wider, with
# prominent draw_flourish ornaments flanking the name in header font.
class _BossBarView extends Control:
	var _boss_name := "The Hedgemother — Unyielding"
	var _ratio := 1.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var w := size.x
		var font := get_theme_default_font()
		var hdr := WyrdUi.font_header()
		if hdr == null:
			hdr = font

		# ── name plate ─────────────────────────────────────────────────────────
		# KIT_PLATE face, top honey bevel, bottom ink shadow, ink border,
		# gold inner ring, sparse parchment grain, boss name in TERRACOTTA
		# IM Fell SC with draw_flourish ── ◆ ── ornaments on each side.
		var np_h := 36.0
		var np_r := Rect2(Vector2.ZERO, Vector2(w, np_h))
		draw_rect(np_r, WyrdUi.KIT_PLATE)
		draw_rect(Rect2(Vector2(2.0, 2.0), Vector2(w - 4.0, 2.5)),
			Color(1.0, 1.0, 0.93, 0.45))
		draw_rect(Rect2(Vector2(2.0, np_h - 4.0), Vector2(w - 4.0, 2.5)),
			Color(WyrdUi.KIT_EDGE, 0.28))
		draw_rect(np_r, WyrdUi.KIT_EDGE, false, 2.0)
		# gold inner ring shared with the hotbar tray "burnished" read
		draw_rect(np_r.grow(-4.0), Color(WyrdUi.GOLD, 0.35), false, 1.0)
		WyrdUi.draw_parchment_grain(self, np_r, 13)
		# flourishes (named-creature card language); their outer reach is ~103 px
		# from each edge, so the name text is clear within x=108..w-108.
		WyrdUi.draw_flourish(self, Vector2(58.0, np_h * 0.5), 92.0)
		WyrdUi.draw_flourish(self, Vector2(w - 58.0, np_h * 0.5), 92.0)
		# boss name centred within the inner column, clear of the flourishes
		draw_string(hdr, Vector2(108.0, np_h - 9.0), _boss_name,
			HORIZONTAL_ALIGNMENT_CENTER, w - 216.0, 18, WyrdUi.TERRACOTTA)

		# ── health trough ──────────────────────────────────────────────────────
		# draw_well gives the stepped inner-shadow so the bar reads as carved
		# INTO the parchment, not painted on. Fill uses a watercolor highlight
		# stripe at the top so the remaining HP reads as a wet ink wash.
		var bar_y := np_h + 4.0
		var bar_h := 26.0
		WyrdUi.draw_well(self, Rect2(Vector2(0.0, bar_y), Vector2(w, bar_h)),
			WyrdUi.KIT_WELL)
		var fill_w := maxf(0.0, (w - 8.0) * clampf(_ratio, 0.0, 1.0))
		if fill_w > 0.0:
			var fill_r := Rect2(Vector2(4.0, bar_y + 3.0),
				Vector2(fill_w, bar_h - 6.0))
			draw_rect(fill_r, Color(0.69, 0.30, 0.20, 0.92))
			# top highlight stripe — the watercolor wash read
			draw_rect(Rect2(fill_r.position + Vector2(2.0, 1.0),
				Vector2(fill_w - 4.0, 4.0)), Color(0.84, 0.46, 0.30, 0.40))
			draw_rect(fill_r, Color(0.44, 0.16, 0.12, 0.55), false, 1.5)
