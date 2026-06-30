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

# Preloaded (not class_name) so headless runs pick them up without an editor
# rescan of the global class cache.
const HotbarSlot := preload("res://scripts/ui/hotbar_slot.gd")
const HotbarTray := preload("res://scripts/ui/hotbar_tray.gd")
# Spec 52 — the draught (heal) Q-slot rides the end of the bar; ♨ uses the
# default font (IM Fell tofus U+2668). Count sums every drinkable draught.
const CraftingDefs := preload("res://data/crafting.gd")
const DRAUGHT_GLYPH := "♨"

# Short labels for each Skill class name — covers all nine B5 skills.
const SKILL_LABEL := {
	"BasicShot":     "Bow",
	"PowerShot":     "Pow",
	"MultiShot":     "Mlt",
	"BrambleSnare":  "Snr",
	"PiercingBolt":  "Prc",
	"RainOfThorns":  "Thn",
	"Thornburst":    "Bst",
	"HuntersMark":   "Mrk",
	"HeartwoodWard": "Wrd",
	"MercyShot":     "Mcy",
}
# Painted skill icons (ink pass, 2026-06-10) + hover tooltips — combat is
# explained where the buttons live, not in a manual.
const SKILL_ICON := {
	"BasicShot":    "res://assets/ui/icons/skill_basic.png",
	"PowerShot":    "res://assets/ui/icons/skill_power.png",
	"MultiShot":    "res://assets/ui/icons/skill_multi.png",
	"BrambleSnare": "res://assets/ui/icons/skill_snare.png",
}
# Skills without a painted icon yet show a single inked glyph instead of
# bare 3-letter text (the inventory_panel trade-glyph style). A painted
# pass supersedes a glyph by simply adding the SKILL_ICON entry.
const SKILL_GLYPH := {
	"PiercingBolt":  "➸",
	"RainOfThorns":  "❋",
	"Thornburst":    "✺",
	"HuntersMark":   "◎",
	"HeartwoodWard": "❦",
	"MercyShot":     "✜",
}
const SKILL_DESC := {
	"BasicShot":     "A quick arrow. No Focus cost — your bread and butter (also on F).",
	"PowerShot":     "A heavy, slower arrow that hits much harder.",
	"MultiShot":     "A fan of three arrows — crowds and retinues.",
	"BrambleSnare":  "Roots enemies in a bramble patch. Elites marked Briarbound shrug it off.",
	"PiercingBolt":  "A heavy bolt that punches through up to 3 enemies in a line.",
	"RainOfThorns":  "Marks a zone; thorns fall after a breath — damage and bleed.",
	"Thornburst":    "Thorns erupt around you, hurting and briefly snaring everything close.",
	"HuntersMark":   "Name the quarry — it takes +30% from every hit while the mark holds.",
	"HeartwoodWard": "Bark-skin soaks the next 30 damage before your vigor is touched.",
	"MercyShot":     "The clean kill — strikes 3× harder once the quarry staggers below 35% vigor.",
}

var _player: Node = null
var _slots: Array = []           # 4 HotbarSlot nodes — built on bind
var _plate: Control = null       # spec 38 — the carved tray under the row
var _draught_slot: HotbarSlot = null   # spec 52 — the Q draught slot (NOT in _slots)

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
	# Spec 52 — the row is the skill slots PLUS a trailing draught (Q) slot, so
	# the tray + slot x-math budget for n_skills + 1 slots and stay centred.
	var n_skills: int = mini(4, _player.skills.size())
	var total_w := (n_skills + 1) * SLOT_SIZE + n_skills * SLOT_GAP
	# One carved wooden plank under the whole row (HotbarTray._draw), so the
	# slots read as a single crafted piece instead of a flat engine panel.
	var plate := HotbarTray.new()
	plate.name = "Plate"
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
	for i in n_skills:
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
			slot.move_child(tr, 0)   # under the keybind/cost labels
			var nm := slot.get_node_or_null("SkillName")
			if nm != null:
				nm.visible = false   # the icon IS the name now
		elif SKILL_GLYPH.has(skill.name):
			# No painted icon yet — the inked glyph reads as the icon, with
			# the short label tucked beneath it.
			var gl := Label.new()
			gl.name = "Glyph"
			gl.text = String(SKILL_GLYPH[skill.name])
			var ghdr := WyrdUi.font_header()
			if ghdr != null:
				gl.add_theme_font_override("font", ghdr)
			gl.add_theme_font_size_override("font_size", 30)
			gl.add_theme_color_override("font_color", WyrdUi.INK)
			gl.anchor_right = 1.0
			gl.offset_top = 4
			gl.offset_bottom = 44
			gl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			gl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			slot.add_child(gl)
			slot.move_child(gl, 0)   # under the keybind/cost labels
			var nm := slot.get_node_or_null("SkillName")
			if nm != null:
				nm.add_theme_font_size_override("font_size", 13)
				nm.offset_top = SLOT_SIZE - 28
				nm.offset_bottom = SLOT_SIZE - 8
		_slots.append(slot)
		add_child(slot)
	# Spec 52 — the trailing draught (Q) slot. Kept out of _slots so _process's
	# skills[i] indexing never touches it.
	_draught_slot = _make_draught_slot(n_skills, total_w)
	add_child(_draught_slot)
	var game := get_tree().root.get_node_or_null("Game")
	if game != null and game.has_signal("materials_changed") \
			and not game.materials_changed.is_connected(_refresh_draught):
		game.materials_changed.connect(_refresh_draught)
	_refresh_draught()

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
		var slot: HotbarSlot = _slots[i]
		var ratio: float = clampf(cd / max(0.05, base_cd), 0.0, 1.0) if on_cd else 0.0
		slot.set_state(ratio, not (on_cd or no_focus))
		# C8 — the Heartwood Ward slot shows its remaining absorb as a bark arc.
		if String(skill.name) == "HeartwoodWard" and _player.has_method("get_ward_frac"):
			slot.set_ward(_player.get_ward_frac())
		else:
			slot.set_ward(0.0)

func _make_slot(i: int, total_w: int, label: String, cost: int) -> Control:
	# A HotbarSlot draws its own carved face + radial cooldown wedge + ready
	# flash; the icon/keybind/cost children below render over it.
	var s := HotbarSlot.new()
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

# Spec 52 — the draught (heal) slot at the end of the bar: ♨ glyph, ×N count,
# a GOLD "Q" hint, dimmed when empty. Mirrors _make_slot's geometry but is wired
# to the draught count, not a skill, and never enters _slots.
func _make_draught_slot(idx: int, total_w: int) -> HotbarSlot:
	var s := HotbarSlot.new()
	s.name = "DraughtSlot"
	s.anchor_left = 0.5
	s.anchor_right = 0.5
	s.anchor_top = 1.0
	s.anchor_bottom = 1.0
	var x := -total_w / 2.0 + idx * (SLOT_SIZE + SLOT_GAP)
	s.offset_left = x
	s.offset_right = x + SLOT_SIZE
	s.offset_top = -ROW_BOTTOM
	s.offset_bottom = -ROW_BOTTOM + SLOT_SIZE
	s.mouse_filter = Control.MOUSE_FILTER_STOP
	s.tooltip_text = "Draughts — drink to heal (Q). At full vigor it sips a buff."
	# ♨ glyph (default font — IM Fell lacks U+2668).
	var gl := Label.new()
	gl.name = "Glyph"
	gl.text = DRAUGHT_GLYPH
	gl.add_theme_font_size_override("font_size", 30)
	gl.add_theme_color_override("font_color", WyrdUi.INK)
	gl.anchor_right = 1.0
	gl.offset_top = 4
	gl.offset_bottom = 44
	gl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	s.add_child(gl)
	s.move_child(gl, 0)
	# "Q" key hint, top-left, GOLD so it reads as a different verb than 1-4.
	var kb := Label.new()
	kb.name = "Keybind"
	kb.text = "Q"
	kb.add_theme_font_size_override("font_size", 14)
	kb.add_theme_color_override("font_color", WyrdUi.GOLD)
	kb.add_theme_color_override("font_outline_color", Color(0.06, 0.05, 0.04))
	kb.add_theme_constant_override("outline_size", 4)
	kb.position = Vector2(6, 3)
	kb.size = Vector2(20, 18)
	s.add_child(kb)
	# Count, bottom-right (mirrors the Cost label).
	var c := Label.new()
	c.name = "Count"
	c.add_theme_font_size_override("font_size", 13)
	c.add_theme_color_override("font_color", Color(0.32, 0.44, 0.50))
	c.add_theme_color_override("font_outline_color", Color(0.97, 0.93, 0.82))
	c.add_theme_constant_override("outline_size", 4)
	c.anchor_left = 1.0
	c.anchor_right = 1.0
	c.anchor_top = 1.0
	c.anchor_bottom = 1.0
	c.offset_left = -26
	c.offset_top = -18
	c.offset_right = -2
	c.offset_bottom = -2
	c.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	s.add_child(c)
	# Click also drinks (keyboard Q is the primary path; player_controller owns it).
	s.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed \
				and ev.button_index == MOUSE_BUTTON_LEFT:
			var g := get_tree().root.get_node_or_null("Game")
			var pl: Node = g.local_player() if g != null else null
			if pl != null and pl.has_method("_quaff"):
				pl.call("_quaff"))
	return s

func _draught_count() -> int:
	var g := get_tree().root.get_node_or_null("Game")
	if g == null:
		return 0
	var n := 0
	for id in CraftingDefs.DRAUGHT_ORDER:
		n += int(g.material_count(String(id)))
	return n

func _refresh_draught(_arg = null) -> void:
	if _draught_slot == null or not is_instance_valid(_draught_slot):
		return
	var n := _draught_count()
	var c := _draught_slot.get_node_or_null("Count") as Label
	if c != null:
		c.text = "×%d" % n
	# ratio 0 → no cooldown wedge; castable=false dims the carved face at 0.
	_draught_slot.set_state(0.0, n > 0)
