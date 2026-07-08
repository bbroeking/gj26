extends CanvasLayer

# B5 — the loadout picker: slot 1 is always the Bow; pick exactly three
# skills for slots 2-4 from the pool. Opened at the dungeon Hearth and
# from the Cottage Hearth's craft panel. Pure view over Game.set_loadout.
#
# Slice C — the rows are drawn skill cards now (icon + name + focus tag +
# short desc). Picked = a sage ring; locked = dim with a lock glyph. The
# "Bow fixed in slot 1, pick 3" semantics are unchanged.

const DESCS := {
	"PowerShot": "A heavy arrow, 2.5× damage, burns on hit. 20 focus.",
	"MultiShot": "A fan of three arrows that snare. Crowds. 25 focus.",
	"BrambleSnare": "Roots enemies in a bramble patch. 30 focus.",
	"PiercingBolt": "Punches through up to 3 enemies in a line. 22 focus.",
	"RainOfThorns": "Delayed thorn volley on a zone — damage + bleed. 32 focus.",
	"Thornburst": "Thorns erupt around you — damage + snare close by. 30 focus.",
	"HuntersMark": "Mark the quarry: it takes +30% from everything, 8s. 15 focus.",
	"HeartwoodWard": "Bark-skin soaks the next 30 damage, 8s. 25 focus.",
	"MercyShot": "The clean kill — ×3 damage under 35% vigor. 28 focus.",
}

# Short focus-cost tags (lifted from the descs so the card's corner reads at a
# glance) and a skill → painted icon map. Four icons cover the pool; kindred
# verbs share one (thorn skills → snare icon, line/heavy → power).
const FOCUS := {
	"PowerShot": 20, "MultiShot": 25, "BrambleSnare": 30, "PiercingBolt": 22,
	"RainOfThorns": 32, "Thornburst": 30, "HuntersMark": 15,
	"HeartwoodWard": 25, "MercyShot": 28,
}
const SKILL_ICON := {
	"PowerShot": "res://assets/ui/icons/skill_power.png",
	"MultiShot": "res://assets/ui/icons/skill_multi.png",
	"BrambleSnare": "res://assets/ui/icons/skill_snare.png",
	"PiercingBolt": "res://assets/ui/icons/skill_power.png",
	"RainOfThorns": "res://assets/ui/icons/skill_snare.png",
	"Thornburst": "res://assets/ui/icons/skill_snare.png",
	"HuntersMark": "res://assets/ui/icons/skill_basic.png",
	"HeartwoodWard": "res://assets/ui/icons/skill_basic.png",
	"MercyShot": "res://assets/ui/icons/skill_basic.png",
}

var _game: Node
var _panel: Panel
var _picks: Array = []
var _rows: VBoxContainer
var _slots_lbl: Label
var _apply: Button
var _tex_cache := {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 95
	_game = get_tree().root.get_node_or_null("Game")
	# Preload skill icons once (white-rect-in-_draw gotcha).
	for path in SKILL_ICON.values():
		if ResourceLoader.exists(String(path)) \
				and not _tex_cache.has(String(path)):
			_tex_cache[String(path)] = load(String(path))
	_picks = (_game.loadout as Array).duplicate() if _game != null \
		else ["PowerShot", "MultiShot", "BrambleSnare"]
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.55)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)
	_panel = Panel.new()
	WyrdUi.style_panel(_panel)
	_panel.anchor_left = 0.5
	_panel.anchor_top = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_bottom = 0.5
	_panel.offset_left = -330
	_panel.offset_top = -300
	_panel.offset_right = 330
	_panel.offset_bottom = 300
	add_child(_panel)
	var title := Label.new()
	title.text = "Loadout"
	WyrdUi.style_title(title)
	title.position = Vector2(54, 36)
	_panel.add_child(title)
	var hint := Label.new()
	hint.text = "Esc — close"
	WyrdUi.style_dim(hint)
	hint.anchor_left = 1.0
	hint.anchor_right = 1.0
	hint.offset_left = -130
	hint.offset_top = 38
	_panel.add_child(hint)
	# Header ornament: flourish rule + tiny bow icon so the "Loadout" header
	# reads as a storybook panel, not a plain label-over-parchment block.
	var hdr_orn := _HeaderOrn.new()
	hdr_orn.anchor_right = 1.0
	hdr_orn.offset_left = 4.0
	hdr_orn.offset_right = -4.0
	hdr_orn.offset_top = 68.0
	hdr_orn.offset_bottom = 86.0
	_panel.add_child(hdr_orn)
	var col := VBoxContainer.new()
	col.anchor_right = 1.0
	col.anchor_bottom = 1.0
	col.offset_left = 56
	col.offset_top = 86
	col.offset_right = -56
	col.offset_bottom = -52
	col.add_theme_constant_override("separation", 8)
	_panel.add_child(col)
	var sub := Label.new()
	sub.text = "The Bow rides slot 1 always. Pick three for slots 2–4:"
	WyrdUi.style_body(sub, 14)
	col.add_child(sub)
	# The pool can outgrow the panel; the card list scrolls.
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 6)
	_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_rows)
	_slots_lbl = Label.new()
	WyrdUi.style_body(_slots_lbl, 14)
	col.add_child(_slots_lbl)
	_apply = Button.new()
	WyrdUi.style_kit_button(_apply)
	_apply.text = "Take up this kit"
	_apply.custom_minimum_size = Vector2(0, 40)
	_apply.pressed.connect(func():
		if _game != null and _game.set_loadout(_picks):
			_close())
	col.add_child(_apply)
	get_node("/root/Game").modal_opened()
	_render()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_close()

func _close() -> void:
	get_node("/root/Game").modal_closed()
	queue_free()

func _render() -> void:
	for c in _rows.get_children():
		c.queue_free()
	var pool: Array = _game.SKILL_POOL if _game != null else DESCS.keys()
	for sk in pool:
		var skill := String(sk)
		var picked: bool = _picks.has(skill)
		# B5-wave2 — Huntcraft-gated skills stand visible but locked.
		var locked: bool = _game != null and not _game.skill_unlocked(skill)
		var req: int = int(_game.SKILL_REQS.get(skill, 1)) if _game != null else 1
		var path := String(SKILL_ICON.get(skill, ""))
		var card := _SkillCard.new()
		card.setup(skill, String(DESCS.get(skill, "")), int(FOCUS.get(skill, 0)),
			picked, locked, req, _tex_cache.get(path, null))
		var sid := skill
		if not locked:
			card.pressed.connect(func():
				if _picks.has(sid):
					_picks.erase(sid)
				elif _picks.size() < 3:
					_picks.append(sid)
				_render())
		_rows.add_child(card)
	_slots_lbl.text = "Slots 2–4:  %s" % (" · ".join(_picks) \
		if not _picks.is_empty() else "—")
	_apply.disabled = _picks.size() != 3


# ---- the drawn skill card (one row) ----
# A clickable Control: draw_list_row plate (sage accent when picked, terracotta
# when locked, neutral otherwise), a painted skill-icon plate on the left, the
# name + focus-cost tag, and a short desc. Picked = a sage ring; locked = dim
# with a padlock glyph and no click.
class _SkillCard extends Control:
	const ICON_W := 44.0

	var _name := ""
	var _desc := ""
	var _focus := 0
	var _picked := false
	var _locked := false
	var _req := 1
	var _tex: Texture2D = null
	var _hover := false

	signal pressed

	func _init() -> void:
		custom_minimum_size = Vector2(0, 62.0)
		mouse_filter = Control.MOUSE_FILTER_STOP

	func setup(skill_name: String, desc: String, focus: int, picked: bool,
			locked: bool, req: int, tex: Texture2D) -> void:
		_name = skill_name
		# Strip the trailing "N focus." — the cost lives in its own tag now.
		var trimmed := desc
		var cut := trimmed.rfind(". ")
		if cut > 0 and trimmed.substr(cut).contains("focus"):
			trimmed = trimmed.substr(0, cut + 1)
		_desc = trimmed
		_focus = focus
		_picked = picked
		_locked = locked
		_req = req
		_tex = tex
		queue_redraw()

	func _gui_input(event: InputEvent) -> void:
		if _locked:
			return
		if event is InputEventMouseButton and event.pressed \
				and event.button_index == MOUSE_BUTTON_LEFT:
			pressed.emit()
			accept_event()

	func _notification(what: int) -> void:
		if what == NOTIFICATION_MOUSE_ENTER:
			_hover = true
			queue_redraw()
		elif what == NOTIFICATION_MOUSE_EXIT:
			_hover = false
			queue_redraw()

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		var accent: Color = WyrdUi.SAGE if _picked \
			else (WyrdUi.TERRACOTTA if _locked else WyrdUi.INK_MID)
		WyrdUi.draw_list_row(self, r, accent)
		if _locked:
			# wash the whole card down so it reads as out-of-reach
			draw_rect(r.grow(-1.5), Color(0.80, 0.74, 0.62, 0.45))
		elif _hover:
			draw_rect(r.grow(-1.5), Color(1.0, 1.0, 0.90, 0.10))
		var font := get_theme_default_font()
		var ink: Color = WyrdUi.INK if not _locked else Color(0.50, 0.43, 0.34)
		var dim: Color = WyrdUi.INK_MID if not _locked else Color(0.56, 0.49, 0.40)
		# --- icon plate on the left ---
		var ir := Rect2(Vector2(9.0, (size.y - ICON_W) * 0.5),
			Vector2(ICON_W, ICON_W))
		WyrdUi.draw_well(self, ir, Color(0.95, 0.91, 0.80))
		if _tex != null:
			var mod := Color.WHITE
			if _locked:
				mod.a = 0.5
			draw_texture_rect(_tex, ir.grow(-4.0), false, mod)
		# picked = sage ring around the icon (WyrdUi selection language)
		if _picked:
			draw_rect(ir, WyrdUi.SAGE.darkened(0.08), false, 2.5)
		# --- name + focus tag ---
		var tx := ir.end.x + 12.0
		var mark := "✓ " if _picked else ""
		draw_string(font, Vector2(tx, 22.0), mark + _name,
			HORIZONTAL_ALIGNMENT_LEFT, size.x - tx - 92.0, 16, ink)
		if _locked:
			# padlock glyph + the gate, right-aligned
			draw_string(font, Vector2(size.x - 156.0, 22.0),
				"⚿ Huntcraft %d" % _req, HORIZONTAL_ALIGNMENT_RIGHT,
				146.0, 13, WyrdUi.TERRACOTTA)
		elif _focus > 0:
			# focus-cost chip in the top-right corner
			var chip := Rect2(Vector2(size.x - 78.0, 8.0), Vector2(66.0, 18.0))
			draw_rect(chip, Color(0.86, 0.79, 0.66))
			draw_rect(chip, Color(WyrdUi.KIT_EDGE, 0.6), false, 1.0)
			draw_string(font, Vector2(chip.position.x, chip.position.y + 14.0),
				"%d focus" % _focus, HORIZONTAL_ALIGNMENT_CENTER, chip.size.x,
				12, WyrdUi.INK_MID)
		# --- short desc (up to two lines) ---
		draw_multiline_string(font, Vector2(tx, 40.0), _desc,
			HORIZONTAL_ALIGNMENT_LEFT, size.x - tx - 16.0, 12, 2, dim)


# Header ornament for the loadout panel: a ◆ flourish rule (spanning the
# title's content zone) and a small bow-and-arrow icon in the left margin —
# the same storybook header treatment as the crafting bench view. Drawn in
# _draw so it requires no assets and scales with the panel.
class _HeaderOrn extends Control:
	func _draw() -> void:
		var cy := size.y * 0.5
		# Flourish rule: from the title's left edge (panel x=54, this control's
		# offset_left=4 → local x=50) to the right content margin.
		var title_x := 50.0
		var fw := size.x - title_x - 8.0
		WyrdUi.draw_flourish(self, Vector2(title_x + fw * 0.5, cy), fw)
		# Bow-and-arrow icon in the 50 px left margin.
		# Stave: a "(" arc from ~108° to ~252° (opening rightward); string:
		# the chord across that opening; arrow: a gold shaft + arrowhead.
		var bx := 13.0
		var bh := minf(cy - 1.5, 7.0)
		draw_arc(Vector2(bx, cy), bh, PI * 0.6, PI * 1.4, 12,
			Color(WyrdUi.KIT_EDGE, 0.60), 2.0, false)
		var str_x := bx + bh * cos(PI * 0.6)   # x of the arc's chord
		var str_dy := bh * sin(PI * 0.6)        # half-height of the chord
		draw_line(Vector2(str_x, cy - str_dy), Vector2(str_x, cy + str_dy),
			Color(WyrdUi.KIT_EDGE, 0.38), 1.0)
		# Gold arrow shaft from the string to the right, plus arrowhead barbs.
		var shaft_r := bx + bh * 1.8
		draw_line(Vector2(str_x - 2.0, cy), Vector2(shaft_r, cy),
			Color(WyrdUi.GOLD, 0.68), 1.5)
		var ah := 3.0
		draw_line(Vector2(shaft_r, cy), Vector2(shaft_r - ah, cy - ah * 0.55),
			Color(WyrdUi.GOLD, 0.68), 1.5)
		draw_line(Vector2(shaft_r, cy), Vector2(shaft_r - ah, cy + ah * 0.55),
			Color(WyrdUi.GOLD, 0.68), 1.5)
