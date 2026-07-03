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

	# Header art — drawn first so it sits behind the title and close hint.
	var header_art := _HearthHeaderArt.new()
	header_art.anchor_right = 1.0
	header_art.anchor_bottom = 1.0
	header_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(header_art)

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


# Header art: an amber-warm wash over the title zone, parchment grain, a
# ── ◆ ── flourish divider, and a campfire glyph in the right margin — so
# the Hearth and Forge panels read as warm domestic spaces, not bare forms.
class _HearthHeaderArt extends Control:
	func _draw() -> void:
		# Warm ember wash over the header zone (y 0..88).
		var zone := Rect2(Vector2.ZERO, Vector2(size.x, 88.0))
		draw_rect(zone, Color(0.98, 0.82, 0.55, 0.20))
		WyrdUi.draw_parchment_grain(self, zone, 33)
		# Flourish divider separating the header from the recipe list.
		WyrdUi.draw_flourish(self, Vector2(size.x * 0.5, 88.0), size.x - 108.0)
		# Campfire glyph in the right margin of the header.
		_draw_campfire(size.x - 64.0, 44.0)

	func _draw_campfire(cx: float, cy: float) -> void:
		# Two crossed logs at the base.
		draw_line(Vector2(cx - 14, cy + 14), Vector2(cx + 10, cy + 6),
			Color(0.52, 0.32, 0.15, 0.72), 3.5)
		draw_line(Vector2(cx - 10, cy + 6), Vector2(cx + 14, cy + 14),
			Color(0.52, 0.32, 0.15, 0.72), 3.5)
		# Ember glow at the base of the flames.
		draw_circle(Vector2(cx, cy + 8), 9.0, Color(0.95, 0.55, 0.18, 0.25))
		# Left flame lick — three stacked circles narrowing upward.
		draw_circle(Vector2(cx - 5, cy + 1), 6.0, Color(0.96, 0.58, 0.18, 0.40))
		draw_circle(Vector2(cx - 4, cy - 5), 4.0, Color(0.97, 0.72, 0.26, 0.35))
		draw_circle(Vector2(cx - 3, cy - 10), 2.5, Color(0.99, 0.88, 0.44, 0.28))
		# Right flame lick.
		draw_circle(Vector2(cx + 5, cy + 1), 5.5, Color(0.95, 0.58, 0.18, 0.38))
		draw_circle(Vector2(cx + 4, cy - 4), 3.5, Color(0.97, 0.72, 0.26, 0.32))
		draw_circle(Vector2(cx + 2, cy - 9), 2.0, Color(0.99, 0.88, 0.44, 0.26))
		# Central taller flame — the dominant tongue.
		draw_circle(Vector2(cx, cy - 2), 7.0, Color(0.97, 0.65, 0.22, 0.48))
		draw_circle(Vector2(cx, cy - 8), 5.0, Color(0.98, 0.78, 0.32, 0.42))
		draw_circle(Vector2(cx, cy - 14), 3.0, Color(0.99, 0.90, 0.48, 0.35))
		draw_circle(Vector2(cx, cy - 18), 1.8, Color(1.0, 0.98, 0.72, 0.28))
