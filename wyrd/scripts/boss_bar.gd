extends CanvasLayer

# Spec 17 — the Hedgemother boss HP banner. Hidden until she aggros.
# Artistic pass — the plain make_meter() trough is replaced by _BossBarArt:
# a carved parchment banner with a surface-light fill and thorn-cross knot
# ornaments at each end, fitting for a bramble/thorn boss.

const FILL_LEFT := 4.0
const FILL_FULL_W := 592.0

@onready var _fill: ColorRect = $Bar/Fill
@onready var _label: Label = $Bar/Label

var _hp_max := 100
var _boss_bar: _BossBarArt = null

func _ready() -> void:
	visible = false
	var bar := get_node_or_null("Bar")
	if bar != null:
		bar.visible = false
		_boss_bar = _BossBarArt.new()
		_boss_bar.anchor_left = 0.5
		_boss_bar.anchor_right = 0.5
		_boss_bar.offset_left = -320
		_boss_bar.offset_top = 10
		_boss_bar.size = Vector2(640, 56)
		_boss_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_boss_bar)

# Called at build — set max HP and fill the bar.
func prime(mx: int) -> void:
	_hp_max = mx
	_fill.offset_right = FILL_LEFT + FILL_FULL_W
	if _boss_bar != null:
		_boss_bar.set_boss_label("The Hedgemother — Unyielding")
		_boss_bar.set_frac(1.0)

func show_boss() -> void:
	visible = true

func set_hp(cur: int, mx: int) -> void:
	_hp_max = mx
	var f := clampf(float(cur) / float(max(1, mx)), 0.0, 1.0)
	_fill.offset_right = FILL_LEFT + FILL_FULL_W * f
	if _boss_bar != null:
		_boss_bar.set_frac(f)

func set_phase(phase: int) -> void:
	# Spec 31 — "Unyielding" suffix tells the player WHY their snares fizzle.
	var txt := "The Hedgemother — Phase %d — Unyielding" % phase
	_label.text = txt
	if _boss_bar != null:
		_boss_bar.set_boss_label(txt)

func hide_boss() -> void:
	visible = false


# A drawn boss-HP banner: carved parchment border, terracotta fill with a
# surface-light stripe, and thorn-cross knot ornaments at each trough end.
# The thorn motif echoes the Hedgemother's bramble-boss identity without
# needing a texture (pure vector, so no load-inside-_draw white-rect risk).
class _BossBarArt extends Control:
	var _frac := 1.0
	var _label_text := "The Hedgemother — Unyielding"

	const FILL_COL := Color(0.69, 0.30, 0.20, 0.92)

	func set_frac(f: float) -> void:
		_frac = clampf(f, 0.0, 1.0)
		queue_redraw()

	func set_boss_label(t: String) -> void:
		_label_text = t
		queue_redraw()

	func _draw() -> void:
		var w := size.x
		var h := size.y

		# --- carved parchment banner (frame + warm bevel + ink border) ---
		draw_rect(Rect2(Vector2.ZERO, size), WyrdUi.KIT_PLATE)
		draw_rect(Rect2(Vector2(2.0, 1.0), Vector2(w - 4.0, 2.5)),
			Color(1.0, 1.0, 0.93, 0.55))
		draw_rect(Rect2(Vector2(2.0, h - 3.5), Vector2(w - 4.0, 2.5)),
			Color(WyrdUi.KIT_EDGE, 0.28))
		draw_rect(Rect2(Vector2.ZERO, size), WyrdUi.KIT_EDGE, false, 2.0)
		draw_rect(Rect2(Vector2(3.5, 3.5), size - Vector2(7.0, 7.0)),
			Color(WyrdUi.KIT_EDGE, 0.22), false, 1.0)

		# --- boss name: IM Fell with ink outline so it reads over any fill ---
		var font: Font = WyrdUi.font_header()
		if font == null:
			font = get_theme_default_font()
		var label_y := 21.0
		draw_string_outline(font, Vector2(w * 0.5, label_y), _label_text,
			HORIZONTAL_ALIGNMENT_CENTER, w - 32.0, 14,
			4, Color(0.10, 0.07, 0.04, 0.9))
		draw_string(font, Vector2(w * 0.5, label_y), _label_text,
			HORIZONTAL_ALIGNMENT_CENTER, w - 32.0, 14, WyrdUi.TERRACOTTA)

		# --- HP trough below the label ---
		var trough_y := label_y + 5.0
		var trough := Rect2(Vector2(14.0, trough_y),
			Vector2(w - 28.0, h - trough_y - 6.0))
		WyrdUi.draw_well(self, trough)
		var fill_w := (trough.size.x - 6.0) * _frac
		if fill_w > 2.0:
			var fr := Rect2(trough.position + Vector2(3.0, 3.0),
				Vector2(fill_w, trough.size.y - 6.0))
			draw_rect(fr, FILL_COL)
			# Surface-light stripe: the fill "catches the light" at the top.
			draw_rect(Rect2(fr.position, Vector2(fr.size.x, 3.0)),
				Color(1.0, 0.62, 0.52, 0.45))

		# --- thorn-cross knot ornaments at the trough ends ---
		_draw_thorn_knot(Vector2(trough.position.x - 1.0,
			trough.position.y + trough.size.y * 0.5))
		_draw_thorn_knot(Vector2(trough.end.x + 1.0,
			trough.position.y + trough.size.y * 0.5))

	# A crossed-thorn bracket knot: horizontal arm + two diagonal upward spurs +
	# circle tips + a central gold pip. Identifies the bar as a bramble boss's
	# health, echoing the Hedgemother's thorn-crown motif.
	func _draw_thorn_knot(center: Vector2) -> void:
		var edge := Color(WyrdUi.KIT_EDGE, 0.60)
		var gold := Color(WyrdUi.GOLD, 0.75)
		draw_line(center - Vector2(5.5, 0), center + Vector2(5.5, 0), edge, 1.5)
		for dx in [-3.5, 3.5]:
			var base := center + Vector2(dx, 0)
			draw_line(base, base + Vector2(0, -5.0), edge, 1.2)
			draw_circle(base + Vector2(0, -5.5), 1.3, edge)
		draw_circle(center, 2.8, gold)
		draw_arc(center, 2.8, 0, TAU, 12, edge, 1.0, true)
