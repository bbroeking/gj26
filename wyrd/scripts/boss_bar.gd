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
		# Art pass — bramble crest disc flanking the boss HP bar on the left.
		# Thorn-cross symbol on a carved parchment ground, mirroring the
		# crest-disc language used in vendor/loadout/Lantern/pack headers.
		var crest := _BrambleCrest.new()
		crest.anchor_left = 0.5
		crest.anchor_right = 0.5
		crest.offset_left = -354
		crest.offset_top = 11
		crest.offset_right = -306
		crest.offset_bottom = 59
		add_child(crest)

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


# Art pass — parchment medallion with a thorn-cross (four diagonal spokes
# tipped with terracotta barbs) and four knot bumps at the cardinal ring.
# Thematically Hedgemother (bramble/nature). Pure-vector _draw; no textures.
class _BrambleCrest extends Control:
	func _draw() -> void:
		var c := size * 0.5
		var r := minf(c.x, c.y) - 1.5
		# Warm parchment disc.
		draw_circle(c, r, WyrdUi.KIT_PLATE)
		# Inner light-bevel arc — disc catches the warm page light.
		draw_arc(c, r - 3.5, 0, TAU, 40, Color(1.0, 1.0, 0.93, 0.45), 2.5, true)
		# Thorn-cross: four diagonal spokes with terracotta barb triangles.
		var t1 := r * 0.14
		var t2 := r * 0.50
		for i in 4:
			var a := PI * 0.25 + float(i) * PI * 0.5
			var d := Vector2(cos(a), sin(a))
			draw_line(c + d * t1, c + d * t2, WyrdUi.KIT_EDGE, 1.8)
			var perp := Vector2(-sin(a), cos(a))
			draw_colored_polygon(PackedVector2Array([
				c + d * (t2 + 5.0),
				c + d * t2 + perp * 3.0,
				c + d * t2 - perp * 3.0]),
				Color(WyrdUi.TERRACOTTA, 0.88))
		# Knot bumps at N / S / E / W of the outer ring.
		for i in 4:
			var a_k := float(i) * PI * 0.5
			var kp := c + Vector2(cos(a_k), sin(a_k)) * r
			draw_circle(kp, 3.5, WyrdUi.KIT_PLATE)
			draw_arc(kp, 3.5, 0, TAU, 12, WyrdUi.KIT_EDGE, 1.5, true)
		# Outer ink ring + burnished gold inner ring.
		draw_arc(c, r, 0, TAU, 48, WyrdUi.KIT_EDGE, 2.0, true)
		draw_arc(c, r - 7.0, 0, TAU, 40, Color(WyrdUi.GOLD, 0.38), 1.2, true)
