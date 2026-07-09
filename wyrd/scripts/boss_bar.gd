extends CanvasLayer

# Spec 17 — the Hedgemother boss HP banner. Hidden until she aggros.
# UI scaling is now project-level (canvas_items stretch); the old Spec-35
# per-layer UI_SCALE transform is retired so this banner sizes consistently
# with the rest of the HUD.
#
# Art pass — a drawn _BossNamePlate chip now sits above the HP fill bar
# instead of squeezing the name into the 34px trough. The plate shows the
# boss name (terracotta, left-aligned), an Unyielding / Phase-N status tag
# (ink, right-aligned), and phase pip markers at the far right so the player
# can see at a glance how far through the fight they are. The fill bar itself
# runs without a text overlay — cleaner PoE-style read.

const FILL_LEFT := 4.0
const FILL_FULL_W := 592.0

@onready var _fill: ColorRect = $Bar/Fill
@onready var _label: Label = $Bar/Label

var _hp_max := 100

var _meter: Dictionary = {}
var _name_plate: Control = null

func _ready() -> void:
	visible = false
	var bar := get_node_or_null("Bar")
	if bar != null:
		bar.visible = false
	# Boss name plate chip above the HP bar (28px tall, 4px gap).
	_name_plate = _BossNamePlate.new()
	_name_plate.anchor_left = 0.5
	_name_plate.anchor_right = 0.5
	_name_plate.offset_left = -300
	_name_plate.offset_right = 300
	_name_plate.offset_top = 10
	_name_plate.offset_bottom = 38
	_name_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_name_plate)
	# HP fill bar — 4px below the name plate's bottom edge (was at y=18).
	_meter = WyrdUi.make_meter(600, 34, Color(0.69, 0.30, 0.20, 0.9))
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
	if _name_plate != null:
		(_name_plate as _BossNamePlate).set_info("The Hedgemother", 0)

func show_boss() -> void:
	visible = true

func set_hp(cur: int, mx: int) -> void:
	_hp_max = mx
	var f := clampf(float(cur) / float(max(1, mx)), 0.0, 1.0)
	_fill.offset_right = FILL_LEFT + FILL_FULL_W * f
	if not _meter.is_empty():
		WyrdUi.set_meter(_meter, f, "")

func set_phase(phase: int) -> void:
	# Keep the legacy label text for back-compat (it's on the hidden $Bar/Label).
	_label.text = "The Hedgemother — Phase %d — Unyielding" % phase
	if not _meter.is_empty():
		(_meter.label as Label).text = ""   # name plate owns the text now
	if _name_plate != null:
		(_name_plate as _BossNamePlate).set_info("The Hedgemother", phase)

func hide_boss() -> void:
	visible = false


# ---- Boss name plate chip ----
# Parchment-plate face (draw_list_row with a terracotta left-stripe so the
# banner registers as "danger"). Left side: boss name in terracotta. Right
# side: Unyielding tag (or "Phase N · Unyielding" when in a named phase).
# Far right: three phase pip circles — lit=terracotta, unlit=kit well —
# so the player can see progress through the fight at a glance.
class _BossNamePlate extends Control:
	var _boss_name := ""
	var _phase := 0        # 0 = not yet in a named phase; 1-3 = active phase

	func set_info(boss_name: String, phase: int) -> void:
		_boss_name = boss_name
		_phase = phase
		queue_redraw()

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		# Parchment plate face with terracotta left-stripe (boss/danger register).
		WyrdUi.draw_list_row(self, r, WyrdUi.TERRACOTTA)
		var f := get_theme_default_font()
		# Vertical center baseline for 16pt text.
		var cy := size.y * 0.5 + 7.0
		# Boss name — terracotta, left-aligned, leaving room for the right tag.
		var name_w := size.x - 90.0
		draw_string(f, Vector2(14.0, cy), _boss_name,
			HORIZONTAL_ALIGNMENT_LEFT, name_w, 16, WyrdUi.TERRACOTTA)
		# Status tag — ink, right-aligned within the same bounding box.
		var tag := "Phase %d · Unyielding" % _phase if _phase > 0 else "Unyielding"
		draw_string(f, Vector2(14.0, cy), tag,
			HORIZONTAL_ALIGNMENT_RIGHT, name_w, 13, WyrdUi.INK_MID)
		# Phase pips at the far right: 3 circles, lit up to _phase.
		var pip_cx := size.x - 70.0
		for i in 3:
			var pc := Vector2(pip_cx + i * 19.0, size.y * 0.5)
			var lit := _phase > 0 and i < _phase
			draw_circle(pc, 6.5,
				WyrdUi.TERRACOTTA.darkened(0.05) if lit else WyrdUi.KIT_WELL)
			draw_arc(pc, 6.5, 0.0, TAU, 16, WyrdUi.KIT_EDGE, 1.5, true)
