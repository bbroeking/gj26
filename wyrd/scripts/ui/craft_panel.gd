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

	# Drawn header band: parchment grain + station crest + flourish divider.
	# Added before the title so it draws behind all labels.
	var hdr := _CraftHeaderArt.new()
	hdr.station_id = station_id
	hdr.anchor_right = 1.0
	hdr.offset_bottom = 82.0
	hdr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(hdr)

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
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)

		# Spec 44 — a painted icon chip in front of every recipe row.
		var chip := Label.new()
		chip.text = _recipe_glyph(rec)
		chip.custom_minimum_size = Vector2(36, 36)
		chip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		chip.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		chip.add_theme_font_size_override("font_size", 17)
		chip.add_theme_color_override("font_color",
			WyrdUi.INK if not locked else WyrdUi.INK_MID)
		chip.add_theme_stylebox_override("normal",
			WyrdUi.chip_stylebox(_recipe_tint(rec, locked)))
		row.add_child(chip)

		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var name_lbl := Label.new()
		if locked:
			name_lbl.text = "%s — %s %d" % [String(rec.name),
				_game.TRADE_NAMES.get(trade, trade) if _game != null else trade,
				int(rec.req_lv)]
			WyrdUi.style_dim(name_lbl, 14)
		else:
			name_lbl.text = String(rec.name)
			WyrdUi.style_body(name_lbl, 14)
		info.add_child(name_lbl)
		var cost_parts: Array = []
		for id in rec.inputs:
			var have: int = 0 if _game == null else _game.material_count(String(id))
			cost_parts.append("%d× %s (%d)" % [int(rec.inputs[id]),
				GatherDefs.material_name(String(id)), have])
		var detail := Label.new()
		detail.text = "%s  ·  %d xp  ·  %s" % [" + ".join(cost_parts),
			int(rec.get("xp", 0)), String(rec.get("desc", ""))]
		WyrdUi.style_dim(detail, 12)
		detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info.add_child(detail)
		row.add_child(info)

		var b := Button.new()
		WyrdUi.style_kit_button(b)
		b.text = String(st.get("verb", "Craft"))
		b.custom_minimum_size = Vector2(96, 40)
		b.disabled = locked or _game == null or not _game.can_afford(rec.inputs)
		var rid_s := String(rid)
		b.pressed.connect(func():
			if _game != null and _game.craft(station_id, rid_s):
				_render())
		row.add_child(b)
		_recipe_box.add_child(row)

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


# ---- drawn header band ----
# Parchment grain across the title zone, a station crest to the left of the
# title text, and a flourish ── ◆ ── at the foot — so each station reads as a
# distinct proclamation rather than a flat label. Pure-vector; no textures.
class _CraftHeaderArt extends Control:
	var station_id := "cookfire"

	func _draw() -> void:
		if size.x < 8.0 or size.y < 8.0:
			return
		# Warm parchment grain (inset off the carved-wood frame margins).
		WyrdUi.draw_parchment_grain(self,
			Rect2(Vector2(36.0, 8.0), Vector2(size.x - 72.0, size.y - 16.0)), 41)
		# Flourish ── ◆ ── at the foot of the header, closing the title band.
		WyrdUi.draw_flourish(self, Vector2(size.x * 0.5, size.y - 9.0),
			size.x * 0.48)
		# Station crest — a carved roundel just left of the title text.
		_draw_crest(Vector2(43.0, size.y * 0.5 - 2.0), 15.0)

	func _draw_crest(c: Vector2, r: float) -> void:
		# Parchment face with a double ink ring — the "carved seal" read.
		draw_circle(c, r, WyrdUi.KIT_PLATE)
		draw_arc(c, r - 3.0, 0, TAU, 36, Color(WyrdUi.KIT_EDGE, 0.22), 2.0, true)
		draw_arc(c, r, 0, TAU, 36, WyrdUi.KIT_EDGE, 2.0, true)
		match station_id:
			"cookfire", "still":
				_draw_leaf_sprig(c, r * 0.58)
			_:  # forge and any future station
				_draw_hammer_mark(c, r * 0.58)

	func _draw_leaf_sprig(c: Vector2, s: float) -> void:
		# A jade-green diamond leaf with midrib + stem — Wildcraft / hearth trade.
		var pts := PackedVector2Array([
			c + Vector2(0.0, -s),
			c + Vector2(s * 0.60, -s * 0.05),
			c + Vector2(0.0, s * 0.65),
			c + Vector2(-s * 0.60, -s * 0.05),
		])
		draw_colored_polygon(pts, Color(WyrdUi.SAGE, 0.78))
		draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[3], pts[0]]),
			Color(WyrdUi.SAGE.darkened(0.30), 0.85), 1.0, true)
		draw_line(c + Vector2(0.0, -s), c + Vector2(0.0, s * 0.65),
			Color(WyrdUi.SAGE.darkened(0.35), 0.65), 1.0)
		draw_line(c + Vector2(0.0, s * 0.65), c + Vector2(0.0, s * 1.05),
			Color(WyrdUi.SAGE.darkened(0.20), 0.75), 1.5)

	func _draw_hammer_mark(c: Vector2, s: float) -> void:
		# A hammer head + handle — Earthcraft / forge trade read.
		var hw := s * 0.90
		var hh := s * 0.42
		var hy := c.y - s * 0.35
		# Head: wide steel rectangle with a thin top highlight.
		draw_rect(Rect2(Vector2(c.x - hw, hy - hh * 0.5), Vector2(hw * 2.0, hh)),
			Color(0.52, 0.50, 0.48))
		draw_rect(Rect2(Vector2(c.x - hw + 1.5, hy - hh * 0.5 + 1.5),
			Vector2(hw * 2.0 - 3.0, 2.0)), Color(1.0, 1.0, 1.0, 0.22))
		draw_rect(Rect2(Vector2(c.x - hw, hy - hh * 0.5), Vector2(hw * 2.0, hh)),
			Color(WyrdUi.KIT_EDGE, 0.65), false, 1.0)
		# Handle: warm-wood rectangle, joined below the head.
		var handle_w := s * 0.24
		var handle_h := s * 0.90
		draw_rect(Rect2(Vector2(c.x - handle_w * 0.5, hy + hh * 0.5 - 1.0),
			Vector2(handle_w, handle_h)), Color(0.62, 0.46, 0.30))
		draw_rect(Rect2(Vector2(c.x - handle_w * 0.5, hy + hh * 0.5 - 1.0),
			Vector2(handle_w, handle_h)), Color(WyrdUi.KIT_EDGE, 0.55), false, 1.0)
