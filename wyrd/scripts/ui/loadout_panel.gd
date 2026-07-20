extends CanvasLayer

# Spec 59 — the Field Bar replaces the legacy blank Spell Book. Assignments
# apply immediately through Game.set_loadout; rows and slots preserve click and
# drag paths while using normal focusable Controls instead of drawn hitboxes.

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
	"DrivingVolley": "Five arrows in a close 60° fan. Each deals 0.4× damage; drives ordinary quarry once. 26 focus.",
	"Threadstep": "Slip up to five paces along a clear road. 20 focus.",
	"WayfindersMark": "Hold 35 Focus to mark a Reeling Knot-Eater within twelve paces. 14s cooldown.",
	"Galecall": "A granted gust — pushes and staggers. (charm)",
	"Wyrdvolley": "A granted arcane volley. (charm)",
}
const FOCUS := {
	"PowerShot": 20, "MultiShot": 25, "BrambleSnare": 30, "PiercingBolt": 22,
	"RainOfThorns": 32, "Thornburst": 30, "HuntersMark": 15,
	"HeartwoodWard": 25, "MercyShot": 28, "DrivingVolley": 26, "Threadstep": 20,
	"WayfindersMark": 35,
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
	"DrivingVolley": "res://assets/ui/icons/skill_driving_volley.png",
	"Threadstep": "res://assets/ui/icons/skill_threadstep.png",
	"WayfindersMark": "res://assets/ui/icons/skill_wayfinders_mark.png",
}
const BOW_ICON := "res://assets/ui/icons/skill_basic.png"
const CraftingDefs := preload("res://data/crafting.gd")
const GatherDefs := preload("res://data/gather.gd")
const Tokens = preload("res://scripts/ui/foundation/ui_tokens.gd")
const FocusPointer = preload("res://scripts/ui/components/focus_pointer.gd")
const Workbench = preload("res://scripts/ui/components/transaction_workbench.gd")
const FieldSlot = preload("res://scripts/ui/components/loadout_slot.gd")
const ChoiceRow = preload("res://scripts/ui/components/loadout_choice_row.gd")

var _game: Node
var _workbench: TransactionWorkbench
var _picks: Array = []
var _slots: Array = []
var _slot_box: VBoxContainer
var _pool_box: VBoxContainer
var _footer_hint: Label
var _carried_skill := ""
var _carried_from := 0
var _tex_cache := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 95
	_game = get_tree().root.get_node_or_null("Game")
	for path in SKILL_ICON.values():
		_cache_texture(String(path))
	_cache_texture(BOW_ICON)
	for path in GatherDefs.ICON_TEX.values():
		_cache_texture(String(path))
	_picks = (_game.loadout as Array).duplicate() if _game != null \
		and _game.get("loadout") is Array else []
	_ensure_pick_slots()
	WyrdUi.make_backdrop(self, _close)
	_workbench = Workbench.new()
	_workbench.anchor_left = 0.5
	_workbench.anchor_top = 0.5
	_workbench.anchor_right = 0.5
	_workbench.anchor_bottom = 0.5
	_workbench.offset_left = -520.0
	_workbench.offset_top = -325.0
	_workbench.offset_right = 520.0
	_workbench.offset_bottom = 325.0
	_workbench.close_requested.connect(_close)
	add_child(_workbench)
	_workbench.setup("The Field Bar",
		"Keep only the motions you mean to carry into the Hollow.", _tex(BOW_ICON))
	_build_bar(_workbench.add_leaf("FieldBarLeaf", 0.42))
	_build_library(_workbench.add_leaf("SkillLibraryLeaf", 0.58))
	_footer_hint = _workbench.add_footer_hint(
		"Enter/A assign or clear  ·  Y carry  ·  Enter/A place  ·  Esc/B close")
	get_node("/root/Game").modal_opened()
	_render()
	var focus_pointer := FocusPointer.new()
	focus_pointer.name = "TransactionFocusPointer"
	add_child(focus_pointer)
	_focus_loadout.call_deferred()


func _build_bar(leaf: VBoxContainer) -> void:
	var heading := Label.new()
	heading.text = "At Your Hand"
	heading.theme_type_variation = &"SectionTitle"
	leaf.add_child(heading)
	var hint := Label.new()
	hint.text = "F is fixed. Choose three Focus Skills and one quick-use draught."
	hint.theme_type_variation = &"RowSubtitle"
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	leaf.add_child(hint)
	leaf.add_child(HSeparator.new())
	_slot_box = VBoxContainer.new()
	_slot_box.name = "FieldBarSlots"
	_slot_box.add_theme_constant_override("separation", 6)
	_slot_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	leaf.add_child(_slot_box)
	for index in 5:
		if index == 1:
			_slot_box.add_child(_micro_heading("Focus Skills"))
		elif index == 4:
			_slot_box.add_child(HSeparator.new())
		var slot := FieldSlot.new()
		slot.index = index
		if index == 4:
			slot.accepts = "item"
		slot.request_assign.connect(_on_assign)
		slot.request_quick.connect(_on_quick)
		slot.pressed.connect(_on_slot_pressed.bind(index))
		_slot_box.add_child(slot)
		_slots.append(slot)


func _build_library(leaf: VBoxContainer) -> void:
	var heading := Label.new()
	heading.text = "Skills & Satchel"
	heading.theme_type_variation = &"SectionTitle"
	leaf.add_child(heading)
	var hint := Label.new()
	hint.text = "Choose an entry to fill the first open place, or drag it exactly where it belongs."
	hint.theme_type_variation = &"RowSubtitle"
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	leaf.add_child(hint)
	leaf.add_child(HSeparator.new())
	var scroll := ScrollContainer.new()
	scroll.name = "LoadoutLibraryScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	leaf.add_child(scroll)
	_pool_box = VBoxContainer.new()
	_pool_box.name = "LoadoutLibrary"
	_pool_box.add_theme_constant_override("separation", Tokens.SPACE_2)
	_pool_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_pool_box)


func _render() -> void:
	_ensure_pick_slots()
	_slots[0].setup_skill(0, "Bow", _tex(BOW_ICON), "F", true)
	for index in range(1, 4):
		var skill := String(_picks[index - 1])
		_slots[index].setup_skill(index, skill,
			_tex(String(SKILL_ICON.get(skill, ""))), str(index + 1), false,
			_slot_effect(skill))
	var quick_id := String(_game.quick_item) if _game != null else ""
	var quick_name := GatherDefs.material_name(quick_id) if quick_id != "" else ""
	var quick_count := int(_game.material_count(quick_id)) \
		if _game != null and quick_id != "" else 0
	_slots[4].setup_quick(quick_id, quick_name, quick_count,
		_material_texture(quick_id), GatherDefs.material_icon(quick_id))
	_render_library()


func _render_library() -> void:
	for child in _pool_box.get_children():
		_pool_box.remove_child(child)
		child.queue_free()
	_pool_box.add_child(_section_label("Quick-use from the Satchel"))
	var items := _owned_consumables()
	if items.is_empty():
		_pool_box.add_child(_empty_note("No draughts carried. Brew one at the Hearth."))
	for id_v in items:
		var id := String(id_v)
		var pinned: bool = _game != null and String(_game.quick_item) == id
		var texture := _material_texture(id)
		var row := ChoiceRow.new()
		row.name = "QuickChoice_%s" % id
		row.setup_choice({
			"title": GatherDefs.material_name(id),
			"subtitle": _quick_use_line(id),
			"trailing": "×%d" % int(_game.material_count(id)),
			"badge": "Pinned to Q" if pinned else "Choose for Q",
			"icon": texture,
			"glyph": GatherDefs.material_icon(id),
			"state": JournalListRow.RowState.SELECTED if pinned \
				else JournalListRow.RowState.NORMAL,
			"badge_color": Tokens.GOLD_MUTED if pinned else Tokens.SAGE.darkened(0.25),
			"density": "compact",
		}, "item", id, texture)
		row.pressed.connect(_on_quick.bind(id))
		_pool_box.add_child(row)
	_pool_box.add_child(_section_label("Learned Focus Skills"))
	var skills := _available_focus_skills()
	if skills.is_empty():
		_pool_box.add_child(_empty_skills_state())
	for skill_v in skills:
		var skill := String(skill_v)
		var equipped := _picks.has(skill)
		var texture := _tex(String(SKILL_ICON.get(skill, "")))
		var row := ChoiceRow.new()
		row.name = "SkillChoice_%s" % skill
		row.setup_choice({
			"title": skill,
			"subtitle": _trim_focus_sentence(String(DESCS.get(skill, ""))),
			"trailing": "%d Focus" % int(FOCUS.get(skill, 0)) \
				if int(FOCUS.get(skill, 0)) > 0 else "Granted",
			"badge": "Pinned to %d" % _slot_for_skill(skill) if equipped else "Choose",
			"icon": texture,
			"glyph": "✦",
			"state": JournalListRow.RowState.SELECTED if equipped \
				else JournalListRow.RowState.NORMAL,
			"badge_color": Tokens.GOLD_MUTED if equipped else Tokens.SAGE.darkened(0.25),
		}, "skill", skill, texture)
		row.pressed.connect(_equip_first_open.bind(skill))
		_pool_box.add_child(row)


func _on_assign(target_index: int, skill: String, from_slot: int) -> void:
	if target_index < 1 or target_index > 3 or not _can_equip_skill(skill):
		return
	_ensure_pick_slots()
	var before := _picks.duplicate()
	var target := target_index - 1
	if from_slot >= 1:
		var source := from_slot - 1
		if source < 0 or source >= _picks.size():
			return
		var displaced = _picks[target]
		_picks[target] = _picks[source]
		_picks[source] = displaced
	else:
		var old_index := _picks.find(skill)
		if old_index >= 0 and old_index != target:
			_picks[old_index] = _picks[target]
		_picks[target] = skill
	if not _apply():
		_picks = before
		_render()
		return
	_set_updated_status()
	(_slots[target_index] as Control).grab_focus.call_deferred()


func _on_slot_pressed(index: int) -> void:
	if index == 0:
		return
	if index == 4:
		if _game != null and String(_game.quick_item) != "":
			_game.set_quick_item("")
			_render()
			(_slots[4] as Control).grab_focus.call_deferred()
		return
	if _carried_skill != "":
		var carried := _carried_skill
		var source := _carried_from
		_carried_skill = ""
		_carried_from = 0
		_on_assign(index, carried, source)
		return
	_ensure_pick_slots()
	_picks[index - 1] = ""
	if _apply():
		_set_updated_status()
		(_slots[index] as Control).grab_focus.call_deferred()


func _equip_first_open(skill: String) -> void:
	_ensure_pick_slots()
	var target := _picks.find("")
	if target < 0:
		_footer_hint.text = "All Focus slots are filled — clear one, or press Y to carry and swap."
		return
	_on_assign(target + 1, skill, 0)


func _on_quick(item_id: String) -> void:
	if _game == null:
		return
	_game.set_quick_item("" if String(_game.quick_item) == item_id else item_id)
	_render()
	_set_updated_status()
	(_slots[4] as Control).grab_focus.call_deferred()


func _apply() -> bool:
	if _game == null or not _game.has_method("set_loadout"):
		return false
	var equipped: Array = []
	for value in _picks:
		var skill := String(value)
		if skill != "" and not equipped.has(skill):
			equipped.append(skill)
	if not _game.set_loadout(equipped):
		return false
	_picks = (_game.loadout as Array).duplicate()
	_ensure_pick_slots()
	_render()
	return true


func _ensure_pick_slots() -> void:
	while _picks.size() < 3:
		_picks.append("")
	if _picks.size() > 3:
		_picks = _picks.slice(0, 3)


func _can_equip_skill(skill: String) -> bool:
	if skill == "" or _game == null:
		return false
	if _game.has_method("skill_owned") and bool(_game.skill_owned(skill)):
		return true
	return _game.has_method("available_skills") \
		and (_game.available_skills() as Array).has(skill)


func _owned_consumables() -> Array:
	if _game == null:
		return []
	var out: Array = []
	for id in (CraftingDefs.DRAUGHT_ORDER + CraftingDefs.BUFF_DRAUGHT_ORDER):
		if int(_game.material_count(String(id))) > 0:
			out.append(String(id))
	return out


func _available_focus_skills() -> Array:
	if _game == null or not _game.has_method("available_skills"):
		return []
	var out: Array = []
	for raw_skill in (_game.available_skills() as Array):
		var skill := String(raw_skill)
		if skill != "BasicShot" and DESCS.has(skill) and _can_equip_skill(skill):
			out.append(skill)
	return out


func _section_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = &"SectionTitle"
	label.add_theme_font_size_override("font_size", 18)
	return label


func _micro_heading(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = &"RowSubtitle"
	return label


func _empty_note(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = &"Body"
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.y = 48.0
	return label


func _empty_skills_state() -> PanelContainer:
	var note := PanelContainer.new()
	note.name = "NoLearnedSkillsState"
	note.theme_type_variation = &"PaperSurface"
	note.custom_minimum_size.y = 126.0
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", Tokens.SPACE_4)
	note.add_child(row)
	var emblem := Label.new()
	emblem.text = "✦"
	emblem.theme_type_variation = &"PageTitle"
	emblem.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	emblem.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	emblem.custom_minimum_size.x = 72.0
	row.add_child(emblem)
	var copy := VBoxContainer.new()
	copy.alignment = BoxContainer.ALIGNMENT_CENTER
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(copy)
	var title := Label.new()
	title.text = "No Focus Skills learned yet"
	title.theme_type_variation = &"SectionTitle"
	copy.add_child(title)
	var body := Label.new()
	body.text = "Huntcraft lessons will be written here."
	body.theme_type_variation = &"Body"
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(body)
	return note


func _quick_use_line(id: String) -> String:
	if id == "quickroot_tonic":
		return "Gathering runs faster for 90 seconds."
	return String(GatherDefs.MATERIALS.get(id, {}).get("desc", "A draught for the road."))


func _trim_focus_sentence(description: String) -> String:
	var cut := description.rfind(". ")
	if cut > 0 and description.substr(cut).to_lower().contains("focus"):
		return description.substr(0, cut + 1)
	return description


func _slot_effect(skill: String) -> String:
	if skill == "":
		return ""
	return _trim_focus_sentence(String(DESCS.get(skill, "Focus Skill")))


func _slot_for_skill(skill: String) -> int:
	var index := _picks.find(skill)
	return index + 2 if index >= 0 else 0


func _set_updated_status() -> void:
	_footer_hint.text = "✓ Field Bar updated.  ·  Y carry  ·  Enter/A place  ·  Esc/B close"


func _material_texture(id: String) -> Texture2D:
	return _tex(GatherDefs.material_icon_path(id))


func _cache_texture(path: String) -> void:
	if path != "" and ResourceLoader.exists(path) and not _tex_cache.has(path):
		_tex_cache[path] = load(path)


func _tex(path: String) -> Texture2D:
	return _tex_cache.get(path, null) as Texture2D


func _focus_loadout() -> void:
	if _slots.size() > 1 and is_instance_valid(_slots[1]):
		(_slots[1] as Control).grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if _carried_skill != "":
			_carried_skill = ""
			_carried_from = 0
			_footer_hint.text = "Carry cancelled.  ·  Changes take effect at once."
			get_viewport().set_input_as_handled()
			return
		_close()
		return
	var carry_pressed: bool = event is InputEventKey and event.pressed \
		and not event.echo and event.keycode == KEY_Y
	carry_pressed = carry_pressed or (event is InputEventJoypadButton \
		and event.pressed and event.button_index == JOY_BUTTON_Y)
	if not carry_pressed:
		return
	var focused := get_viewport().gui_get_focus_owner()
	if focused == null or focused.get_script() != FieldSlot \
		or int(focused.index) < 1 or int(focused.index) > 3 \
		or String(focused.skill_name) == "":
		return
	_carried_skill = String(focused.skill_name)
	_carried_from = int(focused.index)
	_footer_hint.text = "Carrying %s — choose slot 2–4 and press Enter/A.  ·  Esc cancels" \
		% _carried_skill
	get_viewport().set_input_as_handled()


func _close() -> void:
	get_node("/root/Game").modal_closed()
	queue_free()
