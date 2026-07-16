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

var _meter: Dictionary = {}

func _ready() -> void:
	visible = false
	# Wyrd UI overhaul — parchment banner over the old flat bar.
	var bar := get_node_or_null("Bar")
	if bar != null:
		bar.visible = false
		_meter = WyrdUi.make_meter(600, 34, Color(0.69, 0.30, 0.20, 0.9))
		var root := _meter.root as Control
		root.anchor_left = 0.5
		root.anchor_right = 0.5
		root.offset_left = -300
		root.offset_top = 18
		add_child(root)
		# Carved-wood sheen: top honey bevel + bottom ink shadow + ornamental
		# end wells, so the boss bar matches the hotbar tray's language.
		var sheen := _BossBarSheen.new()
		sheen.set_anchors_preset(Control.PRESET_FULL_RECT)
		sheen.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(sheen)

# Called at build — set max HP and fill the bar.
func prime(mx: int) -> void:
	_hp_max = mx
	_fill.offset_right = FILL_LEFT + FILL_FULL_W
	if not _meter.is_empty():
		WyrdUi.set_meter(_meter, 1.0, "The Hedgemother — Unyielding")

func show_boss() -> void:
	visible = true

func set_hp(cur: int, mx: int) -> void:
	_hp_max = mx
	var f := clampf(float(cur) / float(max(1, mx)), 0.0, 1.0)
	_fill.offset_right = FILL_LEFT + FILL_FULL_W * f
	if not _meter.is_empty():
		WyrdUi.set_meter(_meter, f, (_meter.label as Label).text)

func set_phase(phase: int) -> void:
	# Spec 31 — "Unyielding" suffix tells the player WHY their snares fizzle
	# on the boss. The Hedgemother is immune to root + snared (and takes burn
	# + bleed at 50% reduced duration); the tag makes that visible without a
	# hidden DR meter.
	_label.text = "The Hedgemother — Phase %d — Unyielding" % phase
	if not _meter.is_empty():
		(_meter.label as Label).text = _label.text

func hide_boss() -> void:
	visible = false


# Drawn overlay giving the flat make_meter trough the carved-wood read:
# a honey catch-light along the top, an ink shadow along the bottom, and
# small ornamental wells pressed into each end of the bar.
class _BossBarSheen extends Control:
	func _draw() -> void:
		var w := size.x
		var h := size.y
		# Top honey bevel — the specular hit the hotbar tray carries.
		draw_line(Vector2(6.0, 4.5), Vector2(w - 6.0, 4.5),
			Color(1.0, 0.97, 0.86, 0.42), 2.0)
		# Bottom ink shadow — anchors the bar on the screen.
		draw_line(Vector2(6.0, h - 4.5), Vector2(w - 6.0, h - 4.5),
			Color(0.26, 0.19, 0.13, 0.28), 1.5)
		# End ornamental wells — the carved-wood end-cap motif.
		var cy := h * 0.5
		WyrdUi.draw_round_well(self, Vector2(5.5, cy), 4.5, Color(0.93, 0.88, 0.74))
		WyrdUi.draw_round_well(self, Vector2(w - 5.5, cy), 4.5, Color(0.93, 0.88, 0.74))
