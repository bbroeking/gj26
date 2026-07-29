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
		var craftable: bool = not locked and _game != null \
			and _game.can_afford(rec.inputs)
		var cost_parts: Array = []
		for id in rec.inputs:
			var have: int = 0 if _game == null else _game.material_count(String(id))
			cost_parts.append("%d× %s (%d)" % [int(rec.inputs[id]),
				GatherDefs.material_name(String(id)), have])
		var detail_str: String
		if locked:
			detail_str = "Requires %s %d" % [
				_game.TRADE_NAMES.get(trade, trade) if _game != null else trade,
				int(rec.get("req_lv", 1))]
		else:
			detail_str = "%s  ·  %d xp" % [" + ".join(cost_parts),
				int(rec.get("xp", 0))]
		var card := _RecipeCard.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var rid_s := String(rid)
		card.setup(String(rec.name), detail_str, _recipe_glyph(rec),
			_recipe_tint(rec, locked), locked, craftable,
			String(st.get("verb", "Craft")))
		if not locked:
			card.craft_pressed.connect(func():
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


# ---- drawn recipe card (one row) ----
# draw_list_row plate: sage stripe when craftable, terracotta when locked,
# neutral ink when ingredient-starved. Icon well on the left (group-tinted);
# name + material/gate detail in ink; craft button anchored to the right edge.
# Matches the vendor (_VendorCard) and loadout (_SkillCard) card language so
# every code-drawn list reads as the same carved parchment shelf.
class _RecipeCard extends Control:
	const ICON_W := 44.0

	var _name := ""
	var _detail := ""
	var _glyph := ""
	var _tint: Color = WyrdUi.KIT_PLATE
	var _locked := false
	var _craftable := false
	var _hover := false

	signal craft_pressed

	func _init() -> void:
		custom_minimum_size = Vector2(0, 68.0)
		mouse_filter = Control.MOUSE_FILTER_PASS

	func setup(recipe_name: String, detail: String, glyph: String, tint: Color,
			locked: bool, craftable: bool, verb: String) -> void:
		_name = recipe_name
		_detail = detail
		_glyph = glyph
		_tint = tint
		_locked = locked
		_craftable = craftable
		for c in get_children():
			c.queue_free()
		if not locked:
			var btn := Button.new()
			WyrdUi.style_kit_button(btn)
			btn.text = verb
			btn.disabled = not craftable
			btn.anchor_left = 1.0
			btn.anchor_right = 1.0
			btn.anchor_top = 0.5
			btn.anchor_bottom = 0.5
			btn.offset_left = -104.0
			btn.offset_right = -8.0
			btn.offset_top = -19.0
			btn.offset_bottom = 19.0
			btn.pressed.connect(func(): craft_pressed.emit())
			add_child(btn)
		queue_redraw()

	func _notification(what: int) -> void:
		if what == NOTIFICATION_MOUSE_ENTER:
			_hover = true
			queue_redraw()
		elif what == NOTIFICATION_MOUSE_EXIT:
			_hover = false
			queue_redraw()

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		var accent: Color = WyrdUi.SAGE if _craftable \
			else (WyrdUi.TERRACOTTA if _locked else WyrdUi.INK_MID)
		WyrdUi.draw_list_row(self, r, accent)
		if _hover and not _locked:
			draw_rect(r.grow(-1.5), Color(1.0, 1.0, 0.90, 0.10))
		var font := get_theme_default_font()
		# Icon well — tinted by material group or item rarity, carved into the card.
		var ir := Rect2(Vector2(9.0, (size.y - ICON_W) * 0.5),
			Vector2(ICON_W, ICON_W))
		WyrdUi.draw_well(self, ir, _tint)
		draw_string(font, ir.position + Vector2(0.0, ICON_W * 0.5 + 8.0),
			_glyph, HORIZONTAL_ALIGNMENT_CENTER, ICON_W, 20,
			WyrdUi.INK if not _locked else Color(WyrdUi.INK_MID, 0.6))
		# Name + detail text — button occupies the rightmost 112px on unlocked rows.
		var tx := ir.end.x + 12.0
		var btn_space := 112.0 if not _locked else 0.0
		var avail_w := size.x - tx - btn_space - 8.0
		var ink: Color = WyrdUi.INK if not _locked else Color(WyrdUi.INK_MID, 0.75)
		draw_string(font, Vector2(tx, size.y * 0.5 - 4.0), _name,
			HORIZONTAL_ALIGNMENT_LEFT, avail_w, 16, ink)
		draw_string(font, Vector2(tx, size.y * 0.5 + 14.0), _detail,
			HORIZONTAL_ALIGNMENT_LEFT, avail_w, 12, WyrdUi.INK_MID)
