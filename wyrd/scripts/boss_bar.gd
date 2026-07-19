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
var _cur_frac := 1.0
var _t := 0.0

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
		# Warm amber ember overlay — pulses when the boss is near death.
		# Mirrors the GlobeGauge low-resource pulse pattern in player_hud.gd.
		var overlay := ColorRect.new()
		overlay.name = "PulseOverlay"
		overlay.anchor_right = 1.0
		overlay.anchor_bottom = 1.0
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overlay.color = Color(1.0, 0.55, 0.10, 0.0)
		(_meter.fill as Panel).add_child(overlay)

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
	_cur_frac = f
	_fill.offset_right = FILL_LEFT + FILL_FULL_W * f
	if not _meter.is_empty():
		WyrdUi.set_meter(_meter, f, (_meter.label as Label).text)

func _process(delta: float) -> void:
	if _meter.is_empty():
		return
	var overlay := (_meter.fill as Panel).get_node_or_null("PulseOverlay") as ColorRect
	if overlay == null:
		return
	if not visible or _cur_frac >= 0.33:
		overlay.color.a = 0.0
		return
	# Ember throb: deep-orange glow through the fill at danger threshold.
	# Intensity ramps as HP falls — near-death feels urgent.
	var urgency := 1.0 - (_cur_frac / 0.33)
	_t += delta
	overlay.color.a = 0.22 * urgency * (0.5 + 0.5 * sin(_t * 5.5))

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
