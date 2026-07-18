extends CanvasLayer

# Wyrd — the crafting panel (Cottage Hearth / Hod's Anvil). A pure view
# over Game.craft(): recipe rows with input counts, trade-level gates, and
# a Craft button. Esc closes. Mirrors inscribing_panel's structure.

const CraftingDefs = preload("res://data/crafting.gd")
const GatherDefs = preload("res://data/gather.gd")

var station_id := "cookfire"

var _game: Node
var _panel: Panel
var _recipe_box: VBoxContainer
var _satchel_lbl: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 90
	_game = get_tree().root.get_node_or_null("Game")
	var st: Dictionary = CraftingDefs.station(station_id)

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
	_panel.offset_left = -330
	_panel.offset_top = -300
	_panel.offset_right = 330
	_panel.offset_bottom = 300
	add_child(_panel)

	var title := Label.new()
	title.text = String(st.get("title", "Crafting"))
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

	var col := VBoxContainer.new()
	col.anchor_right = 1.0
	col.anchor_bottom = 1.0
	col.offset_left = 56
	col.offset_top = 84
	col.offset_right = -56
	col.offset_bottom = -56
	col.add_theme_constant_override("separation", 10)
	_panel.add_child(col)

	var section := Label.new()
	section.text = "Recipes"
	WyrdUi.style_section(section)
	col.add_child(section)

	# A7-full grew the forge to 14 recipes — the list scrolls now.
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	_recipe_box = VBoxContainer.new()
	_recipe_box.add_theme_constant_override("separation", 8)
	_recipe_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_recipe_box)

	if station_id == "cookfire":
		# B5 — the town-side kit-swap lives at the Cottage Hearth too.
		var lb := Button.new()
		WyrdUi.style_kit_button(lb)
		lb.text = "Change Loadout (skills)"
		lb.custom_minimum_size = Vector2(0, 36)
		lb.pressed.connect(func():
			var lp: CanvasLayer = load("res://scripts/ui/loadout_panel.gd").new()
			get_tree().current_scene.add_child(lp))
		col.add_child(lb)
	var s2 := Label.new()
	s2.text = "Satchel"
	WyrdUi.style_section(s2)
	col.add_child(s2)
	_satchel_lbl = Label.new()
	WyrdUi.style_body(_satchel_lbl, 13)
	_satchel_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_satchel_lbl)

	get_node("/root/Game").modal_opened()
	_render()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_node("/root/Game").modal_closed()
		queue_free()

func _render() -> void:
	for c in _recipe_box.get_children():
		c.queue_free()
	var st: Dictionary = CraftingDefs.station(station_id)
	var trade := String(st.get("trade", "wilds"))
	var lv: int = 1 if _game == null else _game.trade_lv(trade)
	for rid in st.get("recipes", []):
		var rec: Dictionary = CraftingDefs.recipe(String(rid))
		var locked: bool = lv < int(rec.get("req_lv", 1))
		var affordable: bool = not locked and _game != null \
			and _game.can_afford(rec.inputs)
		var cost_parts: Array = []
		for id in rec.inputs:
			var have: int = 0 if _game == null else _game.material_count(String(id))
			cost_parts.append("%d× %s (%d)" % [int(rec.inputs[id]),
				GatherDefs.material_name(String(id)), have])
		var detail_txt := "%s  ·  %d xp  ·  %s" % [" + ".join(cost_parts),
			int(rec.get("xp", 0)), String(rec.get("desc", ""))]
		var name_txt := "%s — %s %d" % [String(rec.name),
			_game.TRADE_NAMES.get(trade, trade) if _game != null else trade,
			int(rec.req_lv)] if locked else String(rec.name)
		var card := _RecipeCard.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.setup(name_txt, detail_txt, _recipe_glyph(rec),
			_recipe_tint(rec, locked), String(st.get("verb", "Craft")),
			locked, not affordable)
		var rid_s := String(rid)
		card.pressed.connect(func():
			if _game != null and _game.craft(station_id, rid_s):
				_render())
		_recipe_box.add_child(card)

	if _game == null:
		_satchel_lbl.text = ""
		return
	_render_satchel()

# Spec 44 — recipe glyph + tint: materials show their satchel icon, gear
# shows a tool/armor read, draughts a bottle.
func _recipe_glyph(rec: Dictionary) -> String:
	if rec.has("yields_material"):
		return GatherDefs.material_icon(String(rec.yields_material))
	var kind := String((rec.get("yields_item", {}) as Dictionary).get("kind", ""))
	if kind.contains("pickaxe") or kind.contains("axe"):
		return "⚒"
	if kind.contains("bow"):
		return "➳"
	if kind.contains("ring"):
		return "◎"
	return "▣"

func _recipe_tint(rec: Dictionary, locked: bool) -> Color:
	if locked:
		return Color(0.85, 0.80, 0.68)
	if rec.has("yields_material"):
		var mid := String(rec.yields_material)
		var group := String((GatherDefs.MATERIALS.get(mid, {}) as Dictionary)
			.get("group", ""))
		match group:
			"verdant": return Color(0.82, 0.87, 0.68)
			"earthen": return Color(0.85, 0.80, 0.70)
			"lumen":   return Color(0.92, 0.90, 0.78)
		return WyrdUi.KIT_PLATE
	var rarity := String((rec.get("yields_item", {}) as Dictionary)
		.get("rarity", "normal"))
	match rarity:
		"magic": return Color(0.78, 0.83, 0.90)
		"rare":  return Color(0.93, 0.86, 0.62)
	return Color(0.88, 0.83, 0.72)

func _render_satchel() -> void:
	var parts: Array = []
	for id in _game.materials:
		parts.append("%s %s ×%d" % [GatherDefs.material_icon(String(id)),
			GatherDefs.material_name(String(id)), int(_game.materials[id])])
	_satchel_lbl.text = "empty" if parts.is_empty() else "  ·  ".join(parts)


# ---- drawn recipe card (one row in the list) ----
# Replaces the plain HBoxContainer rows: a KIT_PLATE face via draw_list_row,
# a small icon well on the left with the recipe glyph, name + ingredient line
# drawn in ink/dim, and a carved Craft button on the right.
# Locked rows show terracotta accent + dim text; unaffordable shows INK_MID
# accent and a greyed button. Clicking anywhere on an enabled card crafts.
class _RecipeCard extends Control:
	const WELL_W := 46.0
	const BTN_W  := 82.0

	var _name := ""
	var _detail := ""
	var _glyph := "▣"
	var _glyph_tint: Color = Color(0.93, 0.88, 0.74)
	var _verb := "Craft"
	var _locked := false
	var _unaffordable := false
	var _hover := false

	signal pressed

	func _init() -> void:
		custom_minimum_size = Vector2(0, 56.0)
		mouse_filter = Control.MOUSE_FILTER_STOP

	func setup(p_name: String, p_detail: String, p_glyph: String,
			p_tint: Color, p_verb: String, p_locked: bool,
			p_unaffordable: bool) -> void:
		_name        = p_name
		_detail      = p_detail
		_glyph       = p_glyph
		_glyph_tint  = p_tint
		_verb        = p_verb
		_locked      = p_locked
		_unaffordable = p_unaffordable
		queue_redraw()

	func _gui_input(event: InputEvent) -> void:
		if _locked or _unaffordable:
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
		# Accent: sage = ready to craft, terracotta = locked, mid = can't afford.
		var accent: Color = WyrdUi.SAGE if (not _locked and not _unaffordable) \
			else (WyrdUi.TERRACOTTA if _locked else WyrdUi.INK_MID)
		WyrdUi.draw_list_row(self, r, accent)
		if _hover and not _locked and not _unaffordable:
			draw_rect(r.grow(-1.5), Color(1.0, 1.0, 0.90, 0.08))
		# Icon well — tinted by recipe group (verdant/earthen/lumen/item rarity).
		var ir := Rect2(Vector2(8.0, (size.y - WELL_W) * 0.5),
			Vector2(WELL_W, WELL_W))
		WyrdUi.draw_well(self, ir, _glyph_tint.darkened(0.08))
		var font := get_theme_default_font()
		draw_string(font, ir.position + Vector2(0.0, WELL_W * 0.5 + 7.0),
			_glyph, HORIZONTAL_ALIGNMENT_CENTER, WELL_W, 18,
			WyrdUi.INK if not _locked else WyrdUi.INK_MID)
		# Name + ingredient detail.
		var tx  := ir.end.x + 10.0
		var btn_x := size.x - BTN_W - 8.0
		var tw  := maxf(0.0, btn_x - tx - 6.0)
		var nc: Color = WyrdUi.INK if not _locked else WyrdUi.INK_MID
		draw_string(font, Vector2(tx, size.y * 0.5 - 2.0), _name,
			HORIZONTAL_ALIGNMENT_LEFT, tw, 14, nc)
		draw_string(font, Vector2(tx, size.y * 0.5 + 14.0), _detail,
			HORIZONTAL_ALIGNMENT_LEFT, tw, 11, WyrdUi.INK_MID)
		# Craft button — carved plate on the right.
		var br := Rect2(Vector2(btn_x, 8.0), Vector2(BTN_W, size.y - 16.0))
		WyrdUi.draw_carved_button(self, br, not _locked and not _unaffordable)
		var bc: Color = WyrdUi.INK if not _locked and not _unaffordable \
			else Color(WyrdUi.INK_MID, 0.55)
		draw_string(font, Vector2(btn_x, size.y * 0.5 + 5.0), _verb,
			HORIZONTAL_ALIGNMENT_CENTER, BTN_W, 13, bc)
