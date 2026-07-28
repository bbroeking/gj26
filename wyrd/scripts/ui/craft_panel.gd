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

	# Spec 48 — station header: cream wash + station pip + flourish rule so
	# every craft station reads as its own named place, not a generic list.
	var station_hdr := _StationHeader.new()
	station_hdr.station_id = station_id
	station_hdr.set_anchors_preset(Control.PRESET_TOP_WIDE)
	station_hdr.offset_bottom = 84
	_panel.add_child(station_hdr)

	var title := Label.new()
	title.text = String(st.get("title", "Crafting"))
	WyrdUi.style_title(title)
	title.position = Vector2(62, 34)
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


# Spec 48 — the station header drawn behind the title label. A cream wash
# fading downward, a station-keyed identity pip left of the title, and a
# flourish rule closing the header zone — the same header language used by
# the vendor (smith mark), waystone (compass), and dialog (portrait well).
class _StationHeader extends Control:
	var station_id := ""

	func _draw() -> void:
		# Warm cream wash — firelight / forge-glow pooled behind the title.
		for i in 4:
			var a := 0.07 - 0.015 * float(i)
			draw_rect(Rect2(0.0, float(i) * 18.0, size.x, 22.0),
				Color(0.97, 0.92, 0.78, a))
		# Flourish rule — the header / body boundary.
		WyrdUi.draw_flourish(self, Vector2(size.x * 0.5, 78.0), size.x - 116.0)
		# Station pip to the left of the title (centre at x=38, y=49).
		_draw_pip(Vector2(38.0, 49.0), 16.0)

	func _draw_pip(center: Vector2, r: float) -> void:
		match station_id:
			"cookfire":
				_draw_flame(center, r)
			"still":
				_draw_alembic(center, r)
			"forge":
				_draw_anvil(center, r)
			_:
				# Fallback: a small gold disc.
				draw_circle(center, r * 0.42, Color(WyrdUi.GOLD, 0.65))
				draw_arc(center, r * 0.42, 0.0, TAU, 14, WyrdUi.KIT_EDGE, 1.2, true)

	# A small amber flame teardrop: warm glow, orange body, bright inner core.
	func _draw_flame(center: Vector2, r: float) -> void:
		# Amber halo behind the flame.
		draw_circle(center + Vector2(0.0, r * 0.18), r * 0.70,
			Color(0.95, 0.70, 0.22, 0.28))
		# Flame body — teardrop polygon pointing upward.
		var pts := PackedVector2Array([
			center + Vector2( 0.0,       -r * 1.15),
			center + Vector2( r * 0.50,  -r * 0.28),
			center + Vector2( r * 0.52,   r * 0.38),
			center + Vector2( 0.0,        r * 0.55),
			center + Vector2(-r * 0.52,   r * 0.38),
			center + Vector2(-r * 0.50,  -r * 0.28),
		])
		draw_colored_polygon(pts, Color(0.96, 0.56, 0.16))
		# Bright inner core.
		var ipts := PackedVector2Array([
			center + Vector2( 0.0,       -r * 0.65),
			center + Vector2( r * 0.24,   r * 0.10),
			center + Vector2( 0.0,        r * 0.28),
			center + Vector2(-r * 0.24,   r * 0.10),
		])
		draw_colored_polygon(ipts, Color(1.0, 0.92, 0.58, 0.80))
		# Ink arc at the flame's base — grounds it.
		draw_arc(center + Vector2(0.0, r * 0.18), r * 0.52, 0.0, TAU, 18,
			Color(WyrdUi.KIT_EDGE, 0.42), 1.5, true)

	# A small glass alembic with sage brew — the still / brew station pip.
	func _draw_alembic(center: Vector2, r: float) -> void:
		# Glass flask body (pale teal).
		draw_circle(center + Vector2(0.0, r * 0.32), r * 0.62,
			Color(0.80, 0.90, 0.84, 0.68))
		# Sage brew liquid in the lower flask.
		draw_circle(center + Vector2(0.0, r * 0.52), r * 0.38,
			Color(0.52, 0.76, 0.52, 0.78))
		# Glass catch-light arc (upper-left).
		draw_arc(center + Vector2(-r * 0.22, r * 0.08), r * 0.36,
			PI * 0.85, PI * 1.55, 10, Color(1.0, 1.0, 0.98, 0.48), 2.0, true)
		# Neck.
		draw_rect(Rect2(center + Vector2(-r * 0.16, -r * 0.30),
			Vector2(r * 0.32, r * 0.60)), Color(0.80, 0.88, 0.83, 0.68))
		# Ink outlines.
		draw_arc(center + Vector2(0.0, r * 0.32), r * 0.62, 0.0, TAU, 26,
			WyrdUi.KIT_EDGE, 1.5, true)
		draw_rect(Rect2(center + Vector2(-r * 0.16, -r * 0.30),
			Vector2(r * 0.32, r * 0.60)), WyrdUi.KIT_EDGE, false, 1.5)
		# Sage bubble rising.
		draw_circle(center + Vector2(r * 0.24, r * 0.20), r * 0.11,
			Color(0.85, 0.96, 0.88, 0.55))

	# A three-rect ink anvil silhouette with gold sparks — the forge pip.
	func _draw_anvil(center: Vector2, r: float) -> void:
		# Top face (wide).
		draw_rect(Rect2(center + Vector2(-r * 0.72, -r * 0.58),
			Vector2(r * 1.44, r * 0.38)), WyrdUi.INK)
		# Waist (narrow).
		draw_rect(Rect2(center + Vector2(-r * 0.34, -r * 0.20),
			Vector2(r * 0.68, r * 0.32)), WyrdUi.INK)
		# Base (wide).
		draw_rect(Rect2(center + Vector2(-r * 0.56, r * 0.12),
			Vector2(r * 1.12, r * 0.38)), WyrdUi.INK)
		# Gold sparks off the working face.
		var sv := center + Vector2(r * 0.22, -r * 0.58)
		draw_line(sv, sv + Vector2(r * 0.32, -r * 0.48), Color(WyrdUi.GOLD, 0.80), 1.0)
		draw_line(sv, sv + Vector2(r * 0.52, -r * 0.18), Color(WyrdUi.GOLD, 0.80), 1.0)
		draw_circle(sv + Vector2(r * 0.46, -r * 0.38), r * 0.09, Color(WyrdUi.GOLD, 0.88))
