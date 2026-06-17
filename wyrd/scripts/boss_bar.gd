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
var _boss_name := "The Hedgemother"   # set per-kind by layout_loader before prime()

var _meter: Dictionary = {}

# Set the boss's display name (e.g. "The Burrow Boar"). Call before prime().
# Not `set_name` — that's Node's built-in node-rename method.
func set_boss_name(n: String) -> void:
	if n != "":
		_boss_name = n

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

# Called at build — set max HP and fill the bar.
func prime(mx: int) -> void:
	_hp_max = mx
	_fill.offset_right = FILL_LEFT + FILL_FULL_W
	if not _meter.is_empty():
		WyrdUi.set_meter(_meter, 1.0, "%s — Unyielding" % _boss_name)

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
	_label.text = "%s — Phase %d — Unyielding" % [_boss_name, phase]
	if not _meter.is_empty():
		(_meter.label as Label).text = _label.text

func hide_boss() -> void:
	visible = false
