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
	title.position = Vector2(64, 34)   # shifted right — the crest disc sits at x:20
	_panel.add_child(title)
	# Station-crest disc: a small drawn emblem beside the title. Flame = cookfire,
	# flask = still, hammer = forge. Matches the disc language in vendor/waystone.
	var crest := _StationCrest.new()
	crest.station_id = station_id
	crest.position = Vector2(20, 22)
	crest.size = Vector2(36, 36)
	_panel.add_child(crest)

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
	# Flourish rule: ── ◆ ── storybook chapter-separator under the header.
	var fl := _Flourish.new()
	fl.custom_minimum_size = Vector2(0, 12)
	fl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(fl)

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


# ── ◆ ── drawn section-rule flourish centred at half-height.
class _Flourish extends Control:
	func _draw() -> void:
		WyrdUi.draw_flourish(self,
			Vector2(size.x * 0.5, size.y * 0.5), size.x - 24.0)


# Drawn station-crest disc: parchment face + ink ring + trade emblem.
# Matches the disc language used in vendor_panel and waystone_panel.
class _StationCrest extends Control:
	var station_id := "cookfire"

	func _draw() -> void:
		var c := size * 0.5
		var r := minf(c.x, c.y) - 1.5
		draw_circle(c, r, WyrdUi.KIT_PLATE)
		draw_arc(c, r, 0, TAU, 40, WyrdUi.KIT_EDGE, 2.0, true)
		draw_arc(c, r - 3.5, 0, TAU, 40, Color(WyrdUi.KIT_EDGE, 0.28), 1.0, true)
		match station_id:
			"cookfire":
				_draw_flame(c, r)
			"still":
				_draw_flask(c, r)
			_:
				_draw_hammer(c, r)

	func _draw_flame(c: Vector2, r: float) -> void:
		# Three stacked ovals: warm orange base → amber mid → gold tip.
		draw_circle(c + Vector2(0.0, r * 0.14), r * 0.44,
			Color(0.87, 0.40, 0.12, 0.88))
		draw_circle(c - Vector2(0.0, r * 0.04), r * 0.30,
			Color(0.96, 0.63, 0.18, 0.82))
		draw_circle(c - Vector2(0.0, r * 0.22), r * 0.17,
			Color(0.98, 0.88, 0.42, 0.78))

	func _draw_flask(c: Vector2, r: float) -> void:
		# Alchemy flask: sage-tinted round belly, narrow neck, flat stopper.
		var belly_r := r * 0.38
		draw_circle(c + Vector2(0.0, r * 0.15), belly_r,
			Color(0.70, 0.82, 0.68, 0.80))
		draw_rect(Rect2(c + Vector2(-belly_r * 0.32, -r * 0.42),
			Vector2(belly_r * 0.64, r * 0.30)),
			Color(0.75, 0.84, 0.72, 0.80))
		draw_rect(Rect2(c + Vector2(-belly_r * 0.44, -r * 0.52),
			Vector2(belly_r * 0.88, r * 0.12)), Color(0.55, 0.46, 0.36, 0.88))
		draw_arc(c + Vector2(0.0, r * 0.15), belly_r, 0, TAU, 28,
			Color(WyrdUi.KIT_EDGE, 0.65), 1.5, true)
		# Glass highlight on the belly.
		draw_line(c + Vector2(-belly_r * 0.50, r * 0.02),
			c + Vector2(-belly_r * 0.50, r * 0.30),
			Color(1.0, 1.0, 0.88, 0.38), 1.0)

	func _draw_hammer(c: Vector2, r: float) -> void:
		# Hammer: rectangular head + tapered handle in warm sepia.
		var hw := r * 0.66
		var hh := r * 0.30
		draw_rect(Rect2(c + Vector2(-hw * 0.5, -r * 0.46),
			Vector2(hw, hh)), Color(0.48, 0.39, 0.28, 0.88))
		draw_rect(Rect2(c + Vector2(-r * 0.10, -r * 0.16),
			Vector2(r * 0.20, r * 0.52)), Color(0.57, 0.46, 0.33, 0.88))
		draw_rect(Rect2(c + Vector2(-hw * 0.5, -r * 0.46),
			Vector2(hw, hh)), Color(WyrdUi.KIT_EDGE, 0.55), false, 1.0)
