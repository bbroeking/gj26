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
var _hdr_font: Font = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 90
	_game = get_tree().root.get_node_or_null("Game")
	# Preload header font once so cards can receive it without loading in _draw.
	_hdr_font = WyrdUi.font_header()
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
	_recipe_box.add_theme_constant_override("separation", 6)
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
	var trade_name: String = (_game.TRADE_NAMES.get(trade, trade) \
		if _game != null else trade) as String
	for rid in st.get("recipes", []):
		var rec: Dictionary = CraftingDefs.recipe(String(rid))
		var locked: bool = lv < int(rec.get("req_lv", 1))
		var can_afford: bool = not locked and _game != null \
			and bool(_game.can_afford(rec.inputs))
		# Per-ingredient affordability for colour-coded cost pills.
		var cost_parts: Array = []
		for id in rec.inputs:
			var have: int = 0 if _game == null else _game.material_count(String(id))
			var need: int = int(rec.inputs[id])
			cost_parts.append({
				"text": "%d× %s (%d)" % [need, GatherDefs.material_name(String(id)), have],
				"ok": have >= need
			})
		var card := _RecipeCard.new()
		card.setup(
			String(rec.name),
			String(rec.get("desc", "")),
			int(rec.get("xp", 0)),
			_recipe_glyph(rec),
			locked,
			int(rec.get("req_lv", 1)),
			trade_name,
			can_afford,
			cost_parts,
			String(st.get("verb", "Craft")),
			_hdr_font
		)
		var rid_s := String(rid)
		card.craft_pressed.connect(func():
			if _game != null and bool(_game.craft(station_id, rid_s)):
				_render())
		_recipe_box.add_child(card)

	if _game == null:
		_satchel_lbl.text = ""
		return
	_render_satchel()

# Spec 44 — recipe glyph: materials show their satchel icon, gear a tool
# or bow read, draughts a bottle.
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

func _render_satchel() -> void:
	var parts: Array = []
	for id in _game.materials:
		parts.append("%s %s ×%d" % [GatherDefs.material_icon(String(id)),
			GatherDefs.material_name(String(id)), int(_game.materials[id])])
	_satchel_lbl.text = "empty" if parts.is_empty() else "  ·  ".join(parts)


# ---- drawn recipe card (one row) ----
# Replaces the old HBoxContainer rows with a carved card: draw_list_row
# plate + draw_well icon socket + IM Fell recipe name + colour-coded
# ingredient pills (SAGE = have enough, TERRACOTTA = missing) + carved
# Craft button. Accent stripe: SAGE=affordable, TERRACOTTA=locked,
# INK_MID=costly.
class _RecipeCard extends Control:
	const ICON_W := 44.0
	const BTN_W := 92.0
	const CARD_H := 72.0

	var _name := ""
	var _desc := ""
	var _xp := 0
	var _glyph := ""
	var _locked := false
	var _req_lv := 1
	var _trade_name := ""
	var _can_afford := false
	# Array of {text: String, ok: bool} — one per ingredient.
	var _cost_parts: Array = []
	var _verb := "Craft"
	var _hdr: Font = null
	var _hover := false

	signal craft_pressed

	func _init() -> void:
		custom_minimum_size = Vector2(0, CARD_H)
		mouse_filter = Control.MOUSE_FILTER_STOP

	func setup(name: String, desc: String, xp: int, glyph: String,
			locked: bool, req_lv: int, trade_name: String, can_afford: bool,
			cost_parts: Array, verb: String, hdr_font: Font) -> void:
		_name = name
		_desc = desc
		_xp = xp
		_glyph = glyph
		_locked = locked
		_req_lv = req_lv
		_trade_name = trade_name
		_can_afford = can_afford
		_cost_parts = cost_parts
		_verb = verb
		_hdr = hdr_font
		queue_redraw()

	func _btn_rect() -> Rect2:
		return Rect2(Vector2(size.x - BTN_W - 8.0, (size.y - 34.0) * 0.5),
			Vector2(BTN_W, 34.0))

	func _gui_input(event: InputEvent) -> void:
		if _locked:
			return
		if event is InputEventMouseButton and event.pressed \
				and event.button_index == MOUSE_BUTTON_LEFT:
			if _can_afford and _btn_rect().has_point(event.position):
				craft_pressed.emit()
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
		var accent: Color
		if _locked:
			accent = WyrdUi.TERRACOTTA
		elif _can_afford:
			accent = WyrdUi.SAGE
		else:
			accent = WyrdUi.INK_MID
		WyrdUi.draw_list_row(self, r, accent)
		if _hover and not _locked:
			draw_rect(r.grow(-1.5), Color(1.0, 1.0, 0.90, 0.08))

		var hdr := _hdr if _hdr != null else get_theme_default_font()
		var font := get_theme_default_font()

		# Icon socket — recessed well, quiet when locked, sage ring when ready.
		var ir := Rect2(Vector2(9.0, (size.y - ICON_W) * 0.5), Vector2(ICON_W, ICON_W))
		var plate := Color(0.95, 0.91, 0.80) if not _locked else Color(0.86, 0.81, 0.70)
		WyrdUi.draw_well(self, ir, plate)
		if _can_afford:
			draw_rect(ir, Color(WyrdUi.SAGE, 0.65), false, 1.5)
		if _glyph != "":
			draw_string(font, ir.position + Vector2(0.0, ICON_W * 0.54 + 6.0), _glyph,
				HORIZONTAL_ALIGNMENT_CENTER, ICON_W, 18,
				WyrdUi.INK if not _locked else WyrdUi.INK_MID)

		var tx := ir.end.x + 10.0
		var content_w := size.x - tx - BTN_W - 20.0

		if _locked:
			# Dim name + trade gate so the row reads as out-of-reach.
			draw_string(hdr, Vector2(tx, 26.0),
				"%s — %s %d" % [_name, _trade_name, _req_lv],
				HORIZONTAL_ALIGNMENT_LEFT, content_w, 13,
				Color(0.50, 0.43, 0.34))
			draw_string(font, Vector2(tx, 48.0), "⚿  locked",
				HORIZONTAL_ALIGNMENT_LEFT, content_w, 11,
				Color(WyrdUi.TERRACOTTA, 0.65))
		else:
			# Recipe name in IM Fell header.
			draw_string(hdr, Vector2(tx, 22.0), _name,
				HORIZONTAL_ALIGNMENT_LEFT, content_w, 16, WyrdUi.INK)
			# Ingredient cost pills on one line, coloured by affordability.
			var cx := tx
			var cy := 42.0
			for i in _cost_parts.size():
				if i > 0:
					var plus_w := font.get_string_size(" + ", HORIZONTAL_ALIGNMENT_LEFT,
						-1, 12).x
					if cx + plus_w > tx + content_w:
						cx = tx
						cy += 14.0
					draw_string(font, Vector2(cx, cy), " + ",
						HORIZONTAL_ALIGNMENT_LEFT, plus_w + 2.0, 12, WyrdUi.INK_MID)
					cx += plus_w
				var part = _cost_parts[i]
				var txt := String(part.text)
				var ok := bool(part.ok)
				var col: Color = WyrdUi.SAGE.darkened(0.15) if ok \
					else WyrdUi.TERRACOTTA
				var tw := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT,
					-1, 12).x
				if cx + tw > tx + content_w:
					cx = tx
					cy += 14.0
				draw_string(font, Vector2(cx, cy), txt,
					HORIZONTAL_ALIGNMENT_LEFT, tw + 2.0, 12, col)
				cx += tw
			# Short desc + xp on the bottom line.
			if _desc != "":
				var dtext := _desc
				if _xp > 0:
					dtext += "  ·  %d xp" % _xp
				draw_string(font, Vector2(tx, 62.0), dtext,
					HORIZONTAL_ALIGNMENT_LEFT, content_w, 11, WyrdUi.INK_MID)
			# Carved Craft button on the right.
			var br := _btn_rect()
			WyrdUi.draw_carved_button(self, br, _can_afford)
			draw_string(hdr, br.position + Vector2(0.0, br.size.y * 0.68), _verb,
				HORIZONTAL_ALIGNMENT_CENTER, br.size.x, 13,
				WyrdUi.INK if _can_afford else WyrdUi.INK_MID)
