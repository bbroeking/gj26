extends CanvasLayer

# The Spell Book (2026-07-01 — drag-and-drop rebuild). Slot 1 is always the Bow;
# slots 2-4 hold three chosen skills. DRAG a spell from the pool onto a slot to
# equip it (applies live via Game.set_loadout — the hotbar updates instantly),
# or drag one slot onto another to swap. Godot drag-drop: _get_drag_data on the
# sources, _can_drop_data / _drop_data on the slots. Opened at the Hearth and the
# Cottage craft panel; a "pure view" over Game.loadout / Game.set_loadout.

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
	"Galecall": "A granted gust — pushes and staggers. (charm)",
	"Wyrdvolley": "A granted arcane volley. (charm)",
}
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
const BOW_ICON := "res://assets/ui/icons/skill_basic.png"
const CraftingDefs := preload("res://data/crafting.gd")
const GatherDefs := preload("res://data/gather.gd")

var _game: Node
var _panel: Panel
var _picks: Array = []          # slots 2-4 (three skill names)
var _slots: Array = []          # 4 _LoadoutSlot (index 0 = Bow, 1-3 = picks)
var _pool_box: VBoxContainer
var _hint2: Label
var _tex_cache := {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 95
	_game = get_tree().root.get_node_or_null("Game")
	for path in SKILL_ICON.values():
		if ResourceLoader.exists(String(path)) and not _tex_cache.has(String(path)):
			_tex_cache[String(path)] = load(String(path))
	_picks = (_game.loadout as Array).duplicate() if _game != null \
		else ["PowerShot", "MultiShot", "BrambleSnare"]
	WyrdUi.make_backdrop(self, _close)
	_panel = Panel.new()
	if WyrdUi.has_maple():
		_panel.add_theme_stylebox_override("panel", WyrdUi.maple_panel_stylebox())
	else:
		WyrdUi.style_panel(_panel)
	_panel.anchor_left = 0.5
	_panel.anchor_top = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_bottom = 0.5
	_panel.offset_left = -350
	_panel.offset_top = -320
	_panel.offset_right = 350
	_panel.offset_bottom = 320
	add_child(_panel)

	var ink_hdr: Color = WyrdUi.MAPLE_INK_DARK if WyrdUi.has_maple() else WyrdUi.GOLD
	var ink_body: Color = WyrdUi.MAPLE_INK_DARK if WyrdUi.has_maple() else WyrdUi.INK

	var title := Label.new()
	title.text = "Spell Book"
	WyrdUi.style_title(title)
	title.add_theme_color_override("font_color", ink_hdr)
	title.position = Vector2(54, 34)
	_panel.add_child(title)

	var hint := Label.new()
	hint.text = "Esc — close"
	WyrdUi.style_dim(hint)
	hint.anchor_left = 1.0
	hint.anchor_right = 1.0
	hint.offset_left = -140
	hint.offset_top = 40
	_panel.add_child(hint)

	# --- the four action-bar slots along the top ---
	var slot_row := HBoxContainer.new()
	slot_row.add_theme_constant_override("separation", 12)
	slot_row.position = Vector2(56, 84)
	_panel.add_child(slot_row)
	for i in 4:
		var slot := _LoadoutSlot.new()
		slot.index = i
		slot.request_assign.connect(_on_assign)
		slot_row.add_child(slot)
		_slots.append(slot)
	# The Q quick-use slot — drop a bag consumable onto it to pin it.
	var qslot := _LoadoutSlot.new()
	qslot.index = 4
	qslot.accepts = "item"
	qslot.request_quick.connect(_on_quick)
	slot_row.add_child(qslot)
	_slots.append(qslot)

	_hint2 = Label.new()
	_hint2.text = "Drag a spell onto slots 2–4 to equip it. Slot 1 is your Bow. Drag a slot onto another to swap."
	WyrdUi.style_body(_hint2, 13)
	_hint2.add_theme_color_override("font_color", ink_body)
	_hint2.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint2.position = Vector2(56, 176)
	_hint2.size = Vector2(588, 40)
	_panel.add_child(_hint2)

	# --- the draggable spell pool ---
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.anchor_left = 0.0
	scroll.anchor_top = 0.0
	scroll.anchor_right = 1.0
	scroll.anchor_bottom = 1.0
	scroll.offset_left = 52
	scroll.offset_top = 224
	scroll.offset_right = -52
	scroll.offset_bottom = -76
	_panel.add_child(scroll)
	_pool_box = VBoxContainer.new()
	_pool_box.add_theme_constant_override("separation", 6)
	_pool_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_pool_box)

	var done := Button.new()
	WyrdUi.style_kit_button(done)
	done.text = "Done"
	done.custom_minimum_size = Vector2(0, 40)
	done.anchor_left = 0.5
	done.anchor_right = 0.5
	done.anchor_top = 1.0
	done.anchor_bottom = 1.0
	done.offset_left = -110
	done.offset_right = 110
	done.offset_top = -62
	done.offset_bottom = -22
	done.pressed.connect(_close)
	_panel.add_child(done)

	get_node("/root/Game").modal_opened()
	_render()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_close()

func _close() -> void:
	get_node("/root/Game").modal_closed()
	queue_free()

# A slot received a drop (or a slot was dragged onto another). target_index is
# the slot being dropped ON (1-3); skill is the dragged skill; from_slot is where
# it came from (0 = the pool, 1-3 = another slot).
func _on_assign(target_index: int, skill: String, from_slot: int) -> void:
	if target_index < 1 or target_index > 3:
		return
	var ti := target_index - 1
	if from_slot >= 1:
		# slot → slot: swap the two picks
		var fi := from_slot - 1
		var tmp = _picks[ti]
		_picks[ti] = _picks[fi]
		_picks[fi] = tmp
	else:
		# pool → slot. If the skill is already slotted elsewhere, move the
		# displaced skill there so the three stay distinct.
		var j: int = _picks.find(skill)
		if j >= 0 and j != ti:
			_picks[j] = _picks[ti]
		_picks[ti] = skill
	_apply()

func _apply() -> void:
	if _game != null and _game.set_loadout(_picks):
		pass   # set_loadout rebuilt the live hotbar
	_render()

# A consumable was dropped on the Q slot — pin it (or clear if re-dropped same).
func _on_quick(item_id: String) -> void:
	if _game == null:
		return
	if String(_game.quick_item) == item_id:
		_game.set_quick_item("")     # drop the same one again to unpin (→ auto)
	else:
		_game.set_quick_item(item_id)
	_render()

func _owned_consumables() -> Array:
	if _game == null:
		return []
	var out: Array = []
	for id in (CraftingDefs.DRAUGHT_ORDER + CraftingDefs.BUFF_DRAUGHT_ORDER):
		if int(_game.material_count(String(id))) > 0:
			out.append(String(id))
	return out

func _render() -> void:
	# refresh the four skill slots + the Q quick-use slot
	_slots[0].setup(0, "Bow", _tex(BOW_ICON), false, "F")
	for i in range(1, 4):
		var sk := String(_picks[i - 1]) if i - 1 < _picks.size() else ""
		var locked: bool = _game != null and sk != "" and not _game.skill_unlocked(sk)
		_slots[i].setup(i, sk, _tex(SKILL_ICON.get(sk, "")), locked, str(i + 1))
	var qi := String(_game.quick_item) if _game != null else ""
	var qn := GatherDefs.material_name(qi) if qi != "" else ""
	var qc := int(_game.material_count(qi)) if _game != null and qi != "" else 0
	var qcol := WyrdUi.FOCUS if qi != "" and CraftingDefs.BUFF_DRAUGHT_ORDER.has(qi) \
		else Color(0.74, 0.26, 0.24)
	_slots[4].setup_quick(qi, qn, qc, qcol)
	# rebuild the pool: an ITEMS group (draggable consumables) + a SPELLS group
	for c in _pool_box.get_children():
		c.queue_free()
	var items := _owned_consumables()
	_pool_box.add_child(_group_label("Quick-use items — drag onto the Q slot"))
	if items.is_empty():
		_pool_box.add_child(_group_label(
			"    (no draughts in the satchel — brew some at the hearth)", true))
	for id in items:
		var pinned: bool = _game != null and String(_game.quick_item) == id
		var icol := WyrdUi.FOCUS if CraftingDefs.BUFF_DRAUGHT_ORDER.has(id) \
			else Color(0.74, 0.26, 0.24)
		var icard := _ItemCard.new()
		icard.setup(id, GatherDefs.material_name(id),
			int(_game.material_count(id)), pinned, icol)
		_pool_box.add_child(icard)
	_pool_box.add_child(_group_label("Spells — drag onto slots 2–4"))
	var pool: Array = _game.available_skills() if _game != null \
		and _game.has_method("available_skills") else _game.SKILL_POOL
	for sk in pool:
		var skill := String(sk)
		if _picks.has(skill):
			continue   # already on the bar
		var locked: bool = _game != null and not _game.skill_unlocked(skill)
		var req: int = int(_game.SKILL_REQS.get(skill, 1)) if _game != null else 1
		var card := _SkillCard.new()
		card.setup(skill, String(DESCS.get(skill, "")), int(FOCUS.get(skill, 0)),
			locked, req, _tex(SKILL_ICON.get(skill, "")))
		_pool_box.add_child(card)

func _group_label(text: String, dim := false) -> Label:
	var l := Label.new()
	l.text = text
	WyrdUi.style_section(l)
	l.add_theme_color_override("font_color",
		WyrdUi.MAPLE_WOOD_D if not dim and WyrdUi.has_maple() else WyrdUi.INK_MID)
	l.add_theme_font_size_override("font_size", 14 if dim else 15)
	return l

func _tex(path) -> Texture2D:
	return _tex_cache.get(String(path), null)


# ---- a round action-bar slot (drop target + drag source) ----
class _LoadoutSlot extends Control:
	signal request_assign(target_index: int, skill: String, from_slot: int)
	signal request_quick(item_id: String)
	var index := 0                 # 0 = Bow, 1-3 = skill slots, 4 = Q quick-use
	var accepts := "skill"         # "skill" (slots 1-3) or "item" (Q slot)
	var skill_name := ""
	var _tex: Texture2D = null
	var _locked := false
	var _key := ""
	var _item_id := ""
	var _item_name := ""
	var _count := 0

	func _init() -> void:
		custom_minimum_size = Vector2(84, 84)
		mouse_filter = Control.MOUSE_FILTER_STOP

	func setup(idx: int, sk: String, tex: Texture2D, locked: bool, key: String) -> void:
		index = idx
		skill_name = sk
		_tex = tex
		_locked = locked
		_key = key
		tooltip_text = sk
		queue_redraw()

	var _item_color := Color(0.74, 0.26, 0.24)
	func setup_quick(item_id: String, item_name: String, count: int,
			color := Color(0.74, 0.26, 0.24)) -> void:
		_item_id = item_id
		_item_name = item_name
		_count = count
		_item_color = color
		_key = "Q"
		tooltip_text = "Quick-use (Q): %s" % (item_name if item_id != "" \
			else "auto — best draught")
		queue_redraw()

	func _get_drag_data(_pos: Vector2) -> Variant:
		if accepts != "skill" or index == 0 or skill_name == "":
			return null            # Bow + Q + empty slots aren't drag sources
		var prev := TextureRect.new()
		prev.custom_minimum_size = Vector2(64, 64)
		prev.size = Vector2(64, 64)
		prev.texture = _tex
		prev.modulate = Color(1, 1, 1, 0.85)
		set_drag_preview(prev)
		return {"kind": "skill", "name": skill_name, "from_slot": index}

	func _can_drop_data(_pos: Vector2, data: Variant) -> bool:
		return index >= 1 and typeof(data) == TYPE_DICTIONARY \
			and data.get("kind", "") == accepts

	func _drop_data(_pos: Vector2, data: Variant) -> void:
		if accepts == "item":
			request_quick.emit(String(data.get("name", "")))
		else:
			request_assign.emit(index, String(data.get("name", "")),
				int(data.get("from_slot", 0)))

	func _draw() -> void:
		var c := size * 0.5
		var rad := minf(size.x, size.y) * 0.5 - 4.0
		var maple := WyrdUi.has_maple()
		if maple:
			draw_circle(c + Vector2(0, 2.5), rad + 5.0, Color(0, 0, 0, 0.18))
			draw_arc(c, rad + 3.0, 0, TAU, 44, WyrdUi.MAPLE_WOOD_D, 6.0, true)
			draw_arc(c, rad + 2.0, 0, TAU, 44, WyrdUi.MAPLE_WOOD, 4.0, true)
			draw_circle(c, rad, WyrdUi.MAPLE_JADE if index > 0 else WyrdUi.MAPLE_JADE_D)
			draw_circle(c - Vector2(0, rad * 0.34), rad * 0.62, Color(WyrdUi.MAPLE_JADE_HI, 0.4))
			draw_circle(c - Vector2(rad * 0.26, rad * 0.40), rad * 0.20, Color(1, 1, 1, 0.5))
			draw_arc(c, rad, 0, TAU, 44, Color(WyrdUi.GOLD, 0.7), 1.5, true)
		else:
			WyrdUi.draw_round_well(self, c, rad, WyrdUi.KIT_PLATE)
		if _tex != null and skill_name != "":
			var isz := rad * 1.15
			var mod := Color.WHITE
			if _locked:
				mod = Color(0.6, 0.62, 0.6, 0.7)
			draw_texture_rect(_tex, Rect2(c - Vector2(isz, isz) * 0.5,
				Vector2(isz, isz)), false, mod)
		if index == 4:
			# quick-use: a pinned draught bottle (+ count), else a faint auto bottle
			var bcol: Color = _item_color if _item_id != "" \
				else Color(0.55, 0.58, 0.55, 0.5)
			WyrdUi.draw_ink_bottle(self, c + Vector2(0, rad * 0.12), rad * 1.15, bcol)
			if _item_id != "":
				var cf := WyrdUi.font_body()
				if cf == null:
					cf = get_theme_default_font()
				draw_string_outline(cf, Vector2(size.x - 34, size.y - 7),
					"×%d" % _count, HORIZONTAL_ALIGNMENT_RIGHT, 30, 13, 4,
					Color(0.06, 0.05, 0.04))
				draw_string(cf, Vector2(size.x - 34, size.y - 7), "×%d" % _count,
					HORIZONTAL_ALIGNMENT_RIGHT, 30, 13,
					WyrdUi.MAPLE_INK if WyrdUi.has_maple() else WyrdUi.INK)
		# key hint, top-left
		var f := WyrdUi.font_header()
		if f == null:
			f = get_theme_default_font()
		draw_string_outline(f, Vector2(6, 20), _key, HORIZONTAL_ALIGNMENT_LEFT,
			-1, 13, 4, Color(0.06, 0.05, 0.04))
		draw_string(f, Vector2(6, 20), _key, HORIZONTAL_ALIGNMENT_LEFT,
			-1, 13, WyrdUi.MAPLE_INK if WyrdUi.has_maple() else WyrdUi.INK)
		if index == 0:
			# a small padlock corner so the Bow reads as fixed
			draw_string(f, Vector2(size.x - 20, 20), "⚿",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(WyrdUi.GOLD, 0.8))


# ---- a draggable pool card (one known spell) ----
class _SkillCard extends Control:
	const ICON_W := 44.0
	var _name := ""
	var _desc := ""
	var _focus := 0
	var _locked := false
	var _req := 1
	var _tex: Texture2D = null
	var _hover := false

	func _init() -> void:
		custom_minimum_size = Vector2(0, 62.0)
		mouse_filter = Control.MOUSE_FILTER_STOP

	func setup(skill_name: String, desc: String, focus: int, locked: bool,
			req: int, tex: Texture2D) -> void:
		_name = skill_name
		var trimmed := desc
		var cut := trimmed.rfind(". ")
		if cut > 0 and trimmed.substr(cut).contains("focus"):
			trimmed = trimmed.substr(0, cut + 1)
		_desc = trimmed
		_focus = focus
		_locked = locked
		_req = req
		_tex = tex
		queue_redraw()

	func _get_drag_data(_pos: Vector2) -> Variant:
		if _locked:
			return null
		var prev := TextureRect.new()
		prev.custom_minimum_size = Vector2(56, 56)
		prev.size = Vector2(56, 56)
		prev.texture = _tex
		prev.modulate = Color(1, 1, 1, 0.85)
		set_drag_preview(prev)
		return {"kind": "skill", "name": _name, "from_slot": 0}

	func _notification(what: int) -> void:
		if what == NOTIFICATION_MOUSE_ENTER:
			_hover = true
			queue_redraw()
		elif what == NOTIFICATION_MOUSE_EXIT:
			_hover = false
			queue_redraw()

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		var accent: Color = WyrdUi.TERRACOTTA if _locked else WyrdUi.SAGE
		WyrdUi.draw_list_row(self, r, accent)
		if _locked:
			draw_rect(r.grow(-1.5), Color(WyrdUi.KIT_PLATE, 0.45))
		elif _hover:
			draw_rect(r.grow(-1.5), Color(1.0, 1.0, 0.90, 0.12))
		var font: Font = WyrdUi.font_body()
		if font == null:
			font = get_theme_default_font()
		var ink: Color = WyrdUi.INK if not _locked else WyrdUi.DISABLED_INK
		var dim: Color = WyrdUi.INK_MID if not _locked else WyrdUi.DISABLED_DIM
		var ir := Rect2(Vector2(9.0, (size.y - ICON_W) * 0.5), Vector2(ICON_W, ICON_W))
		WyrdUi.draw_well(self, ir)
		if _tex != null:
			var mod := Color.WHITE
			if _locked:
				mod.a = 0.5
			draw_texture_rect(_tex, ir.grow(-4.0), false, mod)
		var tx := ir.end.x + 12.0
		draw_string(font, Vector2(tx, 22.0), _name, HORIZONTAL_ALIGNMENT_LEFT,
			size.x - tx - 92.0, 16, ink)
		if _locked:
			draw_string(font, Vector2(size.x - 156.0, 22.0), "⚿ Huntcraft %d" % _req,
				HORIZONTAL_ALIGNMENT_RIGHT, 146.0, 13, WyrdUi.TERRACOTTA)
		elif _focus > 0:
			var chip := Rect2(Vector2(size.x - 78.0, 8.0), Vector2(66.0, 18.0))
			draw_rect(chip, WyrdUi.KIT_WELL)
			draw_rect(chip, Color(WyrdUi.KIT_EDGE, 0.55), false, 1.0)
			draw_string(font, Vector2(chip.position.x, chip.position.y + 14.0),
				"%d focus" % _focus, HORIZONTAL_ALIGNMENT_CENTER, chip.size.x, 12,
				WyrdUi.INK_MID)
		else:
			# a drag affordance hint
			draw_string(font, Vector2(size.x - 92.0, 22.0), "⠿ drag",
				HORIZONTAL_ALIGNMENT_RIGHT, 82.0, 12, WyrdUi.INK_MID)
		draw_multiline_string(font, Vector2(tx, 40.0), _desc,
			HORIZONTAL_ALIGNMENT_LEFT, size.x - tx - 16.0, 12, 2, dim)


# ---- a draggable quick-use item card (one owned consumable) ----
class _ItemCard extends Control:
	var _id := ""
	var _name := ""
	var _count := 0
	var _pinned := false
	var _color := Color(0.74, 0.26, 0.24)
	var _hover := false

	func _init() -> void:
		custom_minimum_size = Vector2(0, 46.0)
		mouse_filter = Control.MOUSE_FILTER_STOP

	func setup(id: String, item_name: String, count: int, pinned: bool,
			color := Color(0.74, 0.26, 0.24)) -> void:
		_id = id
		_name = item_name
		_count = count
		_pinned = pinned
		_color = color
		tooltip_text = "%s ×%d — drag onto the Q slot" % [item_name, count]
		queue_redraw()

	func _get_drag_data(_pos: Vector2) -> Variant:
		var prev := Panel.new()
		prev.size = Vector2(150, 28)
		var lbl := Label.new()
		lbl.text = _name
		lbl.add_theme_color_override("font_color", WyrdUi.INK)
		lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		prev.add_child(lbl)
		set_drag_preview(prev)
		return {"kind": "item", "name": _id}

	func _notification(what: int) -> void:
		if what == NOTIFICATION_MOUSE_ENTER:
			_hover = true
			queue_redraw()
		elif what == NOTIFICATION_MOUSE_EXIT:
			_hover = false
			queue_redraw()

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		WyrdUi.draw_list_row(self, r, WyrdUi.GOLD if _pinned else WyrdUi.SAGE)
		if _hover:
			draw_rect(r.grow(-1.5), Color(1, 1, 0.9, 0.12))
		if _pinned:
			draw_rect(r.grow(-1.5), WyrdUi.GOLD, false, 2.0)
		WyrdUi.draw_ink_bottle(self, Vector2(26, size.y * 0.5), size.y * 0.6, _color)
		var font := WyrdUi.font_body()
		if font == null:
			font = get_theme_default_font()
		draw_string(font, Vector2(52, size.y * 0.5 + 6), _name,
			HORIZONTAL_ALIGNMENT_LEFT, size.x - 200, 15, WyrdUi.INK)
		draw_string(font, Vector2(size.x - 158, size.y * 0.5 + 6), "×%d" % _count,
			HORIZONTAL_ALIGNMENT_LEFT, 60, 14, WyrdUi.NUMERIC)
		var hint := "pinned to Q ✓" if _pinned else "⠿ drag to Q"
		draw_string(font, Vector2(size.x - 132, size.y * 0.5 + 6), hint,
			HORIZONTAL_ALIGNMENT_RIGHT, 120, 12,
			WyrdUi.GOLD if _pinned else WyrdUi.INK_MID)
