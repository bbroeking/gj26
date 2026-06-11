extends CanvasLayer

# Wyrd — the Inscribing Table modal. Left: chart templates (Wayfinding-
# gated). Middle: ink slots + live affix-odds preview + the Inscribe button.
# Right: ink mixing recipes + the materials satchel. All state lives on the
# Game autoload; this panel is a pure view over it. Esc closes.

const ChartsData = preload("res://data/charts.gd")
const GatherDefs = preload("res://data/gather.gd")

var _game: Node
var _selected_template := "snug"
var _slotted_inks: Array = []        # ink ids, max = template ink_slots
var _slotted_trophy := ""            # boss-den key — guarantees that affix

var _panel: Panel
var _template_box: VBoxContainer
var _slot_box: HBoxContainer
var _trophy_box: HBoxContainer
var _ink_bag_box: VBoxContainer
var _preview_box: VBoxContainer
var _mix_box: VBoxContainer
var _satchel_lbl: Label
var _inscribe_btn: Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 90
	_game = get_tree().root.get_node_or_null("Game")
	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.55)
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
	_panel.offset_left = -520
	_panel.offset_top = -290
	_panel.offset_right = 520
	_panel.offset_bottom = 290
	add_child(_panel)

	var title := Label.new()
	title.text = "The Inscribing Table"
	WyrdUi.style_title(title)
	title.position = Vector2(54, 34)
	_panel.add_child(title)

	var close_hint := Label.new()
	close_hint.text = "Esc — close"
	WyrdUi.style_dim(close_hint)
	close_hint.anchor_left = 1.0
	close_hint.anchor_right = 1.0
	close_hint.offset_left = -130
	close_hint.offset_top = 36
	_panel.add_child(close_hint)

	var columns := HBoxContainer.new()
	columns.anchor_right = 1.0
	columns.anchor_bottom = 1.0
	columns.offset_left = 56
	columns.offset_top = 78
	columns.offset_right = -56
	columns.offset_bottom = -64
	columns.add_theme_constant_override("separation", 22)
	_panel.add_child(columns)

	# -- column 1: templates --
	var col1 := VBoxContainer.new()
	col1.custom_minimum_size = Vector2(225, 0)
	col1.size_flags_horizontal = Control.SIZE_FILL
	columns.add_child(col1)
	col1.add_child(_section_label("Charts"))
	_template_box = VBoxContainer.new()
	_template_box.add_theme_constant_override("separation", 6)
	col1.add_child(_template_box)

	# -- column 2: slots + preview + inscribe --
	var col2 := VBoxContainer.new()
	col2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col2.add_theme_constant_override("separation", 8)
	columns.add_child(col2)
	col2.add_child(_section_label("Ink slots"))
	_slot_box = HBoxContainer.new()
	_slot_box.add_theme_constant_override("separation", 8)
	col2.add_child(_slot_box)
	col2.add_child(_section_label("Trophy (inks a boss den)"))
	_trophy_box = HBoxContainer.new()
	_trophy_box.add_theme_constant_override("separation", 8)
	col2.add_child(_trophy_box)
	col2.add_child(_section_label("The roll"))
	_preview_box = VBoxContainer.new()
	_preview_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_preview_box.add_theme_constant_override("separation", 4)
	col2.add_child(_preview_box)
	_inscribe_btn = Button.new()
	WyrdUi.style_kit_button(_inscribe_btn)
	_inscribe_btn.text = "Inscribe"
	_inscribe_btn.add_theme_font_size_override("font_size", 18)
	_inscribe_btn.custom_minimum_size = Vector2(0, 42)
	_inscribe_btn.pressed.connect(_on_inscribe)
	col2.add_child(_inscribe_btn)

	# -- column 3: ink bag + mixing + satchel --
	var col3 := VBoxContainer.new()
	col3.custom_minimum_size = Vector2(300, 0)
	col3.size_flags_horizontal = Control.SIZE_FILL
	col3.add_theme_constant_override("separation", 8)
	columns.add_child(col3)
	col3.add_child(_section_label("Your inks (click to slot)"))
	_ink_bag_box = VBoxContainer.new()
	_ink_bag_box.add_theme_constant_override("separation", 4)
	col3.add_child(_ink_bag_box)
	col3.add_child(_section_label("Mix ink"))
	_mix_box = VBoxContainer.new()
	_mix_box.add_theme_constant_override("separation", 4)
	col3.add_child(_mix_box)
	col3.add_child(_section_label("Satchel"))
	_satchel_lbl = Label.new()
	WyrdUi.style_body(_satchel_lbl, 13)
	_satchel_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col3.add_child(_satchel_lbl)

	get_tree().paused = true
	_render_all()

func _section_label(text: String) -> Label:
	var l := Label.new()
	l.text = text
	WyrdUi.style_section(l)
	return l

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_close()

func _close() -> void:
	get_tree().paused = false
	queue_free()

# ---- rendering ----

func _render_all() -> void:
	_render_templates()
	_render_slots()
	_render_trophy()
	_render_ink_bag()
	_render_preview()
	_render_mixing()
	_render_satchel()

# Boss dens never roll at random — slotting a trophy guarantees its den
# affix in one slot (the stability roll still decides good twin vs empty).
func _render_trophy() -> void:
	for c in _trophy_box.get_children():
		c.queue_free()
	if int(_template().get("affix_slots", 0)) <= 0:
		var l := Label.new()
		l.text = "This chart holds no affixes — no den can be inked in."
		WyrdUi.style_dim(l, 13)
		_trophy_box.add_child(l)
		return
	var any := false
	for trophy_id in ChartsData.TROPHY_TO_AFFIX:
		var have: int = 0 if _game == null else _game.material_count(String(trophy_id))
		var used := 1 if _slotted_trophy == String(trophy_id) else 0
		if have - used <= 0 and used == 0:
			continue
		any = true
		var aff: Dictionary = ChartsData.AFFIXES[ChartsData.TROPHY_TO_AFFIX[trophy_id]]
		var b := Button.new()
		WyrdUi.style_kit_button(b)
		WyrdUi.mark_selected(b, used == 1)
		b.toggle_mode = true
		b.button_pressed = used == 1
		b.text = "%s → %s" % [GatherDefs.material_name(String(trophy_id)),
			String(aff.name)]
		b.tooltip_text = String(aff.good_desc)
		var tid := String(trophy_id)
		b.pressed.connect(func():
			_slotted_trophy = "" if _slotted_trophy == tid else tid
			_render_all())
		_trophy_box.add_child(b)
	if not any:
		var l := Label.new()
		l.text = "No trophies yet. The fiercer things carry the first key."
		WyrdUi.style_dim(l, 13)
		_trophy_box.add_child(l)

func _carto_lv() -> int:
	return 1 if _game == null else _game.trade_lv("carto")

func _render_templates() -> void:
	for c in _template_box.get_children():
		c.queue_free()
	for id in ChartsData.TEMPLATE_ORDER:
		var t: Dictionary = ChartsData.TEMPLATES[id]
		var locked: bool = _carto_lv() < int(t.req_carto)
		var b := Button.new()
		WyrdUi.style_kit_button(b)
		WyrdUi.mark_selected(b, id == _selected_template)
		b.toggle_mode = true
		b.button_pressed = id == _selected_template
		b.disabled = locked
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.clip_text = true
		b.custom_minimum_size = Vector2(225, 0)
		b.text = "%s  (T%d, %d affix)" % [t.name, int(t.tier), int(t.affix_slots)] \
			if not locked else "%s  — Wayfinder %d" % [t.name, int(t.req_carto)]
		b.tooltip_text = String(t.desc)
		var tid := String(id)
		b.pressed.connect(func():
			_selected_template = tid
			_slotted_inks.clear()
			_slotted_trophy = ""
			_render_all())
		_template_box.add_child(b)

func _template() -> Dictionary:
	return ChartsData.TEMPLATES.get(_selected_template, {})

func _render_slots() -> void:
	for c in _slot_box.get_children():
		c.queue_free()
	var n := int(_template().get("ink_slots", 0))
	if n == 0:
		var l := Label.new()
		l.text = "This chart takes no ink — the base pot is the whole cost."
		WyrdUi.style_dim(l, 13)
		_slot_box.add_child(l)
		return
	for i in n:
		var b := Button.new()
		WyrdUi.style_kit_button(b)
		b.custom_minimum_size = Vector2(110, 40)
		if i < _slotted_inks.size():
			var ink_id: String = _slotted_inks[i]
			b.text = "%s %s" % [GatherDefs.material_icon(ink_id),
				GatherDefs.material_name(ink_id)]
			b.tooltip_text = "Click to remove"
			var idx := i
			b.pressed.connect(func():
				_slotted_inks.remove_at(idx)
				_render_all())
		else:
			b.text = "— empty —"
			b.disabled = true
		_slot_box.add_child(b)

func _render_ink_bag() -> void:
	for c in _ink_bag_box.get_children():
		c.queue_free()
	var any := false
	for ink_id in ChartsData.INKS:
		var have: int = 0 if _game == null else _game.material_count(String(ink_id))
		var used: int = _slotted_inks.count(String(ink_id))
		# Base-cost ink is spent too — show remaining honestly.
		var base_used: int = int((_template().get("base_cost", {}) as Dictionary) \
			.get(String(ink_id), 0))
		var remain: int = have - used - base_used
		if remain <= 0:
			continue
		any = true
		var b := Button.new()
		WyrdUi.style_kit_button(b)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.text = "%s %s  ×%d" % [GatherDefs.material_icon(String(ink_id)),
			GatherDefs.material_name(String(ink_id)), remain]
		var iid := String(ink_id)
		b.pressed.connect(func():
			if _slotted_inks.size() < int(_template().get("ink_slots", 0)):
				_slotted_inks.append(iid)
				_render_all())
		_ink_bag_box.add_child(b)
	if not any:
		var l := Label.new()
		l.text = "No inks yet — mix some below."
		WyrdUi.style_dim(l, 13)
		_ink_bag_box.add_child(l)

func _render_preview() -> void:
	for c in _preview_box.get_children():
		c.queue_free()
	var t := _template()
	var slots := int(t.get("affix_slots", 0))
	if slots == 0:
		var l := Label.new()
		l.text = "Snug — a guaranteed clean run, no affixes."
		WyrdUi.style_body(l, 13)
		_preview_box.add_child(l)
	else:
		var weights := ChartsData.compute_weights(int(t.tier), _slotted_inks, _carto_lv())
		var stab_bonus := ChartsData.ink_stability_bonus(_slotted_inks)
		var ids := weights.keys()
		ids.sort_custom(func(a, b): return weights[a] > weights[b])
		# All eligible affixes (at most 7 exist) — a capped list would hide
		# exactly the low-weight boss affix the player most needs to see.
		for id in ids:
			var aff: Dictionary = ChartsData.AFFIXES[id]
			var stab := ChartsData.effective_stability(String(id), _carto_lv(), stab_bonus)
			var row := Label.new()
			row.text = "%s — %d%% to land · %d%% good twin" % [
				String(aff.name), roundi(weights[id]), stab]
			row.tooltip_text = "%s\nBad twin: %s — %s" % [String(aff.good_desc),
				String(aff.bad_name), String(aff.bad_desc)]
			WyrdUi.style_body(row, 13)
			_preview_box.add_child(row)
		var note := Label.new()
		note.text = "%d of these will land. Inks tilt the odds — they don't promise." % slots
		WyrdUi.style_dim(note)
		_preview_box.add_child(note)
	# Guaranteed den line (trophy slotted).
	if _slotted_trophy != "" and slots > 0:
		var den: Dictionary = ChartsData.AFFIXES[ChartsData.TROPHY_TO_AFFIX[_slotted_trophy]]
		var stab2 := ChartsData.effective_stability(
			String(ChartsData.TROPHY_TO_AFFIX[_slotted_trophy]), _carto_lv(),
			ChartsData.ink_stability_bonus(_slotted_inks))
		var g := Label.new()
		g.text = "★ Guaranteed: %s — %d%% her den holds" % [String(den.name), stab2]
		g.add_theme_font_size_override("font_size", 13)
		g.add_theme_color_override("font_color", WyrdUi.GOLD)
		_preview_box.add_child(g)
	# Cost line + button state.
	var cost := ChartsData.craft_cost(_selected_template, _slotted_inks, _slotted_trophy)
	var parts: Array = []
	for id in cost:
		var have: int = 0 if _game == null else _game.material_count(String(id))
		parts.append("%d× %s (%d)" % [int(cost[id]), GatherDefs.material_name(String(id)), have])
	var cost_lbl := Label.new()
	cost_lbl.text = "Cost: " + ", ".join(parts)
	WyrdUi.style_body(cost_lbl, 13)
	_preview_box.add_child(cost_lbl)
	_inscribe_btn.disabled = _game == null or not _game.can_afford(cost)

func _render_mixing() -> void:
	for c in _mix_box.get_children():
		c.queue_free()
	for ink_id in GatherDefs.INK_RECIPE_ORDER:
		var recipe: Dictionary = GatherDefs.INK_RECIPES[ink_id]
		var parts: Array = []
		for input_id in recipe.inputs:
			parts.append("%d× %s" % [int(recipe.inputs[input_id]),
				GatherDefs.material_name(String(input_id))])
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var lbl := Label.new()
		lbl.text = "%s ← %s" % [GatherDefs.material_name(ink_id), " + ".join(parts)]
		WyrdUi.style_body(lbl, 13)
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(lbl)
		var b := Button.new()
		WyrdUi.style_kit_button(b)
		b.text = "Mix"
		b.disabled = _game == null or not _game.can_afford(recipe.inputs)
		var iid := String(ink_id)
		b.pressed.connect(func():
			if _game != null and _game.mix_ink(iid):
				_render_all())
		row.add_child(b)
		_mix_box.add_child(row)

func _render_satchel() -> void:
	if _game == null:
		_satchel_lbl.text = ""
		return
	var parts: Array = []
	for id in _game.materials:
		parts.append("%s %s ×%d" % [GatherDefs.material_icon(String(id)),
			GatherDefs.material_name(String(id)), int(_game.materials[id])])
	_satchel_lbl.text = "empty" if parts.is_empty() else "  ·  ".join(parts)

# ---- the inscribe ----

func _on_inscribe() -> void:
	if _game == null:
		return
	var cost := ChartsData.craft_cost(_selected_template, _slotted_inks, _slotted_trophy)
	if not _game.spend_materials(cost):
		return
	var chart := ChartsData.inscribe(_selected_template, _slotted_inks,
		_carto_lv(), _slotted_trophy)
	if chart.is_empty():
		return
	_game.add_chart(chart)
	_slotted_inks.clear()
	_slotted_trophy = ""
	_render_all()
