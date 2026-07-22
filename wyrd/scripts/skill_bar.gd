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
			slot.move_child(tr, 0)   # under the keybind/cost labels
			var nm := slot.get_node_or_null("SkillName")
			if nm != null:
				nm.visible = false   # the icon IS the name now
		elif SKILL_GLYPH.has(skill.name):
			# Carved sigil plate: a round-well disc with a runic dot ring + the
			# skill glyph drawn as a seal (parchment ghost + ink fill) — more
			# storybook than a plain floating Label.
			var plate2 := _SigilPlate.new()
			plate2.name = "SigilPlate"
			plate2.anchor_right = 1.0
			plate2.offset_top = 4
			plate2.offset_bottom = 44
			plate2.mouse_filter = Control.MOUSE_FILTER_IGNORE
			plate2.setup(String(SKILL_GLYPH[skill.name]), WyrdUi.font_header())
			slot.add_child(plate2)
			slot.move_child(plate2, 0)   # under keybind/cost labels
			var nm := slot.get_node_or_null("SkillName")
			if nm != null:
				nm.add_theme_font_size_override("font_size", 13)
				nm.offset_top = SLOT_SIZE - 28
				nm.offset_bottom = SLOT_SIZE - 8
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
		var slot: HotbarSlot = _slots[i]
		var ratio: float = clampf(cd / max(0.05, base_cd), 0.0, 1.0) if on_cd else 0.0
		slot.set_state(ratio, not (on_cd or no_focus))

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


# Drawn sigil disc that replaces the plain glyph Label for skills without a
# painted icon. Draws: a round-well parchment disc, 8 runic accent dots in a
# ring near the edge, then the unicode glyph with a parchment ghost outline
# behind the ink fill — so it reads as an inked seal, not a floating character.
class _SigilPlate extends Control:
	var _glyph := ""
	var _hdr_font: Font = null

	func setup(glyph: String, hdr: Font) -> void:
		_glyph = glyph
		_hdr_font = hdr
		queue_redraw()

	func _draw() -> void:
		var c := size * 0.5
		var r := minf(c.x, c.y) - 4.0
		WyrdUi.draw_round_well(self, c, r, Color(0.88, 0.82, 0.68))
		# 8 sepia dots in a ring just inside the seal edge.
		for i in 8:
			var a := float(i) * TAU / 8.0
			draw_circle(c + Vector2(cos(a), sin(a)) * (r - 5.5),
				1.4, Color(0.28, 0.20, 0.14, 0.45))
		# Parchment ghost outline behind ink fill.
		var font := _hdr_font if _hdr_font != null else get_theme_default_font()
		draw_string_outline(font, Vector2(0.0, c.y + 9.0), _glyph,
			HORIZONTAL_ALIGNMENT_CENTER, size.x, 26,
			4, Color(0.88, 0.82, 0.67, 0.45))
		draw_string(font, Vector2(0.0, c.y + 9.0), _glyph,
			HORIZONTAL_ALIGNMENT_CENTER, size.x, 26, WyrdUi.INK)
