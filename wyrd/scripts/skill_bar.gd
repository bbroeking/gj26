extends CanvasLayer

# Spec 30/32b — the 4-skill hotbar HUD. Slots build lazily on `bind_to_player`
# so the labels/costs come from the player's `skills: Array[Skill]` instance
# directly — no more drift between a const data table and the live Skills.

# Spec 38 — the bar sits between the HP/Focus globes in the bottom-center
# cluster. NO layer transform: anchors resolve against the raw window, and
# a scaled CanvasLayer pushes anchored children off-screen (the spec-35
# UI_SCALE transform had been rendering this bar below the viewport).
const SLOT_SIZE := 72
const SLOT_GAP := 8
const ROW_BOTTOM := 114           # pixels from the bottom of the viewport

# Short labels for each Skill class name. Skills shipped in v1 are the four
# below; future spec adds class-paths can extend this dict.
const SKILL_LABEL := {
	"BasicShot":    "Bow",
	"PowerShot":    "Pow",
	"MultiShot":    "Mlt",
	"BrambleSnare": "Snr",
}
# Painted skill icons (ink pass, 2026-06-10) + hover tooltips — combat is
# explained where the buttons live, not in a manual.
const SKILL_ICON := {
	"BasicShot":    "res://assets/ui/icons/skill_basic.png",
	"PowerShot":    "res://assets/ui/icons/skill_power.png",
	"MultiShot":    "res://assets/ui/icons/skill_multi.png",
	"BrambleSnare": "res://assets/ui/icons/skill_snare.png",
}
const SKILL_DESC := {
	"BasicShot":    "A quick arrow. No Focus cost — your bread and butter (also on F).",
	"PowerShot":    "A heavy, slower arrow that hits much harder.",
	"MultiShot":    "A fan of three arrows — crowds and retinues.",
	"BrambleSnare": "Roots enemies in a bramble patch. Elites marked Briarbound shrug it off.",
}

var _player: Node = null
var _slots: Array = []           # 4 Control nodes — built on bind
var _plate: Panel = null         # spec 38 — the tray under the row

func _ready() -> void:
	layer = 50

# Called once the player exists; reads skill data and builds the slot row.
func bind_to_player(p: Node) -> void:
	_player = p
	# Tear down any pre-existing slot nodes (shouldn't normally be any).
	for s in _slots:
		if is_instance_valid(s):
			s.queue_free()
	_slots.clear()
	if _plate != null and is_instance_valid(_plate):
		_plate.queue_free()
		_plate = null
	if _player == null or _player.get("skills") == null:
		return
	var total_w := 4 * SLOT_SIZE + 3 * SLOT_GAP
	# Spec 38 style pass — one parchment plate under the whole row (the
	# mock's slot tray), so the slots read as a single carved piece.
	var plate := Panel.new()
	plate.name = "Plate"
	if true:
		# Spec 41 — the kit's carved tray: flat parchment + ink border.
		var psb := StyleBoxFlat.new()
		psb.bg_color = WyrdUi.KIT_PLATE.darkened(0.04)
		psb.border_color = WyrdUi.KIT_EDGE
		psb.set_border_width_all(2)
		plate.add_theme_stylebox_override("panel", psb)
	plate.anchor_left = 0.5
	plate.anchor_right = 0.5
	plate.anchor_top = 1.0
	plate.anchor_bottom = 1.0
	plate.offset_left = -total_w / 2.0 - 14
	plate.offset_right = total_w / 2.0 + 14
	plate.offset_top = -ROW_BOTTOM - 12
	plate.offset_bottom = -ROW_BOTTOM + SLOT_SIZE + 12
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(plate)
	_plate = plate
	for i in 4:
		if i >= _player.skills.size():
			break
		var skill = _player.skills[i]
		var label: String = SKILL_LABEL.get(skill.name, skill.name.substr(0, 3))
		var slot := _make_slot(i, total_w, label, int(skill.cost))
		slot.tooltip_text = "%s — %s\nCost %d Focus · %.1fs cooldown" % [
			skill.name, String(SKILL_DESC.get(skill.name, "")),
			int(skill.cost), float(skill.base_cd)]
		slot.mouse_filter = Control.MOUSE_FILTER_STOP
		var icon_path := String(SKILL_ICON.get(skill.name, ""))
		if ResourceLoader.exists(icon_path):
			var tr := TextureRect.new()
			tr.texture = load(icon_path)
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr.anchor_right = 1.0
			tr.anchor_bottom = 1.0
			tr.offset_left = 8
			tr.offset_top = 8
			tr.offset_right = -8
			tr.offset_bottom = -8
			tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
			slot.add_child(tr)
			slot.move_child(tr, 1)   # above bg, under sweep/labels
			var nm := slot.get_node_or_null("SkillName")
			if nm != null:
				nm.visible = false   # the icon IS the name now
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
	# Background — parchment plate (UI overhaul); flat ink fallback.
	var bg := Panel.new()
	bg.name = "Bg"
	if true:
		# Spec 41 — kit slot: lighter parchment well, thin ink border.
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.95, 0.91, 0.79)
		sb.border_color = WyrdUi.KIT_EDGE
		sb.set_border_width_all(2)
		bg.add_theme_stylebox_override("panel", sb)
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
	kb.add_theme_font_size_override("font_size", 14)
	kb.add_theme_color_override("font_color", WyrdUi.TERRACOTTA)
	kb.add_theme_color_override("font_outline_color", Color(0.97, 0.93, 0.82))
	kb.add_theme_constant_override("outline_size", 4)
	kb.position = Vector2(6, 3)
	kb.size = Vector2(20, 18)
	s.add_child(kb)
	# Skill name (centered).
	var nm := Label.new()
	nm.name = "SkillName"
	nm.text = label
	var hdr := WyrdUi.font_header()
	if hdr != null:
		nm.add_theme_font_override("font", hdr)
	nm.add_theme_font_size_override("font_size", 18)
	nm.add_theme_color_override("font_color", WyrdUi.INK)
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
		c.add_theme_color_override("font_color", Color(0.32, 0.44, 0.50))
		c.add_theme_color_override("font_outline_color", Color(0.97, 0.93, 0.82))
		c.add_theme_constant_override("outline_size", 4)
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
