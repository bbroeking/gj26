extends CanvasLayer

# Spec 17 — the Hedgemother boss HP banner. Hidden until she aggros.
# UI scaling is now project-level (canvas_items stretch); the old Spec-35
# per-layer UI_SCALE transform is retired so this banner sizes consistently
# with the rest of the HUD.
# Art pass — a carved parchment nameplate header sits above the HP meter:
# warm KIT_PLATE face, ink border + gold inset, ◆ flourish at the lower edge,
# and sage leaf-diamond pips at each end. The boss name moves from text-over-
# fill to its own terracotta label on the header — reads as a storybook
# 'royal proclamation' banner rather than a flat progress-bar caption.

const FILL_LEFT := 4.0
const FILL_FULL_W := 592.0

@onready var _fill: ColorRect = $Bar/Fill
@onready var _label: Label = $Bar/Label

var _hp_max := 100
var _meter: Dictionary = {}
var _boss_name_lbl: Label = null

func _ready() -> void:
	visible = false
	var bar := get_node_or_null("Bar")
	if bar != null:
		bar.visible = false
		# Decorative nameplate banner above the HP meter.
		var hdr := BossHeaderArt.new()
		hdr.anchor_left = 0.5
		hdr.anchor_right = 0.5
		hdr.offset_left = -300
		hdr.offset_top = 8
		hdr.custom_minimum_size = Vector2(600, 32)
		add_child(hdr)
		# Boss name label floating over the header band.
		_boss_name_lbl = Label.new()
		var hf := WyrdUi.font_header()
		if hf != null:
			_boss_name_lbl.add_theme_font_override("font", hf)
		_boss_name_lbl.add_theme_font_size_override("font_size", 17)
		_boss_name_lbl.add_theme_color_override("font_color", WyrdUi.TERRACOTTA)
		_boss_name_lbl.anchor_left = 0.5
		_boss_name_lbl.anchor_right = 0.5
		_boss_name_lbl.offset_left = -290
		_boss_name_lbl.offset_top = 8
		_boss_name_lbl.custom_minimum_size = Vector2(580, 32)
		_boss_name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_boss_name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		add_child(_boss_name_lbl)
		# HP meter below the nameplate (28px instead of 34px; no text in fill).
		_meter = WyrdUi.make_meter(600, 28, Color(0.69, 0.30, 0.20, 0.9))
		var root := _meter.root as Control
		root.anchor_left = 0.5
		root.anchor_right = 0.5
		root.offset_left = -300
		root.offset_top = 42
		add_child(root)

func prime(mx: int) -> void:
	_hp_max = mx
	_fill.offset_right = FILL_LEFT + FILL_FULL_W
	if not _meter.is_empty():
		WyrdUi.set_meter(_meter, 1.0, "")
	if _boss_name_lbl != null:
		_boss_name_lbl.text = "The Hedgemother — Unyielding"

func show_boss() -> void:
	visible = true

func set_hp(cur: int, mx: int) -> void:
	_hp_max = mx
	var f := clampf(float(cur) / float(max(1, mx)), 0.0, 1.0)
	_fill.offset_right = FILL_LEFT + FILL_FULL_W * f
	if not _meter.is_empty():
		WyrdUi.set_meter(_meter, f, "")

func set_phase(phase: int) -> void:
	_label.text = "The Hedgemother — Phase %d — Unyielding" % phase
	if _boss_name_lbl != null:
		_boss_name_lbl.text = _label.text

func hide_boss() -> void:
	visible = false


# Carved parchment nameplate — the boss bar's decorative header. Warm
# parchment face, ink border + gold inset, ◆ flourish at the bottom edge,
# and sage leaf-diamond pips at each end so the banner reads as a storybook
# proclamation rather than a flat progress-bar label.
class BossHeaderArt extends Control:
	func _ready() -> void:
		resized.connect(queue_redraw)

	func _draw() -> void:
		if size.x < 2.0 or size.y < 2.0:
			return
		var r := Rect2(Vector2.ZERO, size)
		# Warm parchment face.
		draw_rect(r, WyrdUi.KIT_PLATE)
		# Top light bevel (catches the warm page light from above).
		draw_rect(Rect2(r.position + Vector2(2.0, 2.0),
			Vector2(r.size.x - 4.0, 2.0)), Color(1.0, 0.98, 0.88, 0.50))
		# Bottom shade — the banner sits on the HP trough; shadow reads as depth.
		draw_rect(Rect2(r.position + Vector2(2.0, r.size.y - 3.0),
			Vector2(r.size.x - 4.0, 2.0)), Color(WyrdUi.KIT_EDGE, 0.22))
		WyrdUi.draw_parchment_grain(self, r, 31)
		# Ink border + a gold inner inset (burnished proclamation read).
		draw_rect(r, WyrdUi.KIT_EDGE, false, 1.5)
		draw_rect(r.grow(-3.5), Color(WyrdUi.GOLD, 0.45), false, 1.0)
		# ◆ flourish centred at the lower edge — divides the banner from the bar.
		WyrdUi.draw_flourish(self, Vector2(r.size.x * 0.5, r.size.y - 4.0), 110.0)
		# Sage leaf-diamond pips bracketing each end of the banner.
		_draw_leaf_pip(Vector2(16.0, r.size.y * 0.5))
		_draw_leaf_pip(Vector2(r.size.x - 16.0, r.size.y * 0.5))

	func _draw_leaf_pip(center: Vector2) -> void:
		# Outline first (slightly larger), then the sage fill on top.
		draw_colored_polygon(PackedVector2Array([
			center + Vector2(0.0, -7.5),
			center + Vector2(8.5, 0.0),
			center + Vector2(0.0, 7.5),
			center + Vector2(-8.5, 0.0),
		]), Color(WyrdUi.SAGE.darkened(0.25), 0.85))
		draw_colored_polygon(PackedVector2Array([
			center + Vector2(0.0, -6.0),
			center + Vector2(7.0, 0.0),
			center + Vector2(0.0, 6.0),
			center + Vector2(-7.0, 0.0),
		]), Color(WyrdUi.SAGE, 0.65))
