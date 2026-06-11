extends CanvasLayer

# Spec 30/32b — the 4-skill hotbar HUD. Slots build lazily on `bind_to_player`
# so the labels/costs come from the player's `skills: Array[Skill]` instance
# directly — no more drift between a const data table and the live Skills.

# Spec-35 — single UI_SCALE knob bumps the whole HUD's rendered size
# without touching anchors. Applied as the CanvasLayer's transform.scale
# in _ready, so layout math stays in pixel-space but the final pixels
# scale up. Bump this constant (1.5 → 2.0) to enlarge the entire HUD.
const UI_SCALE := 1.5

const SLOT_SIZE := 60
const SLOT_GAP := 8
const ROW_BOTTOM := 96            # pixels from the bottom of the viewport

# Short labels for each Skill class name. Skills shipped in v1 are the four
# below; future spec adds class-paths can extend this dict.
const SKILL_LABEL := {
	"BasicShot":    "Bow",
	"PowerShot":    "Pow",
	"MultiShot":    "Mlt",
	"BrambleSnare": "Snr",
}

var _player: Node = null
var _slots: Array = []           # 4 Control nodes — built on bind

func _ready() -> void:
	layer = 50
	transform = Transform2D().scaled(Vector2(UI_SCALE, UI_SCALE))

# Called once the player exists; reads skill data and builds the slot row.
func bind_to_player(p: Node) -> void:
	_player = p
	# Tear down any pre-existing slot nodes (shouldn't normally be any).
	for s in _slots:
		if is_instance_valid(s):
			s.queue_free()
	_slots.clear()
	if _player == null or _player.get("skills") == null:
		return
	var total_w := 4 * SLOT_SIZE + 3 * SLOT_GAP
	for i in 4:
		if i >= _player.skills.size():
			break
		var skill = _player.skills[i]
		var label: String = SKILL_LABEL.get(skill.name, skill.name.substr(0, 3))
		var slot := _make_slot(i, total_w, label, int(skill.cost))
		_slots.append(slot)
		add_child(slot)

func _process(_delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	var cds: Dictionary = _player.get("_skill_cooldowns")
	var focus: float = float(_player.get("focus"))
	if cds == null:
		return
	for i in _slots.size():
		var slot_idx := i + 1
		var skill = _player.skills[i]
		var cd: float = float(cds.get(slot_idx, 0.0))
		var base_cd: float = float(skill.base_cd)
		var cost: float = float(skill.cost)
		var on_cd := cd > 0.01
		var no_focus := focus < cost
		var slot: Control = _slots[i]
		slot.modulate.a = 0.45 if (on_cd or no_focus) else 1.0
		var sweep: ColorRect = slot.get_node("Sweep")
		if on_cd:
			sweep.visible = true
			sweep.modulate.a = clampf(cd / max(0.05, base_cd), 0.0, 1.0) * 0.65
		else:
			sweep.visible = false

func _make_slot(i: int, total_w: int, label: String, cost: int) -> Control:
	var s := Control.new()
	s.name = "Slot%d" % (i + 1)
	# Anchor to bottom-centre; pixel-offset relative to that.
	s.anchor_left = 0.5
	s.anchor_right = 0.5
	s.anchor_top = 1.0
	s.anchor_bottom = 1.0
	var x := -total_w / 2.0 + i * (SLOT_SIZE + SLOT_GAP)
	s.offset_left = x
	s.offset_right = x + SLOT_SIZE
	s.offset_top = -ROW_BOTTOM
	s.offset_bottom = -ROW_BOTTOM + SLOT_SIZE
	# Background.
	var bg := ColorRect.new()
	bg.name = "Bg"
	bg.color = Color(0.10, 0.08, 0.09, 0.85)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	s.add_child(bg)
	# Cooldown overlay (simple fading alpha — proper radial sweep is a followup).
	var sweep := ColorRect.new()
	sweep.name = "Sweep"
	sweep.color = Color(0.0, 0.0, 0.0, 0.65)
	sweep.anchor_right = 1.0
	sweep.anchor_bottom = 1.0
	sweep.visible = false
	s.add_child(sweep)
	# Keybind label (top-left).
	var kb := Label.new()
	kb.name = "Keybind"
	kb.text = str(i + 1)
	kb.add_theme_font_size_override("font_size", 16)
	kb.position = Vector2(4, 0)
	kb.size = Vector2(20, 18)
	s.add_child(kb)
	# Skill name (centered).
	var nm := Label.new()
	nm.name = "SkillName"
	nm.text = label
	nm.add_theme_font_size_override("font_size", 18)
	nm.anchor_left = 0.0
	nm.anchor_right = 1.0
	nm.offset_top = SLOT_SIZE / 2.0 - 12
	nm.offset_bottom = SLOT_SIZE / 2.0 + 8
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	s.add_child(nm)
	# Focus cost (bottom-right, only if non-zero).
	if cost > 0:
		var c := Label.new()
		c.name = "Cost"
		c.text = "%d" % cost
		c.add_theme_font_size_override("font_size", 13)
		c.modulate = Color(0.85, 0.64, 0.37)
		c.anchor_left = 1.0
		c.anchor_right = 1.0
		c.anchor_top = 1.0
		c.anchor_bottom = 1.0
		c.offset_left = -22
		c.offset_top = -18
		c.offset_right = -2
		c.offset_bottom = -2
		s.add_child(c)
	return s
