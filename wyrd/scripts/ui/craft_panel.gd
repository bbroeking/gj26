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
	# Station header art — parchment grain + flourish rule + station emblem.
	# Follows the PortraitWell / QuestScrollArt inner-class pattern: a Control
	# overlay added before the label children so it sits behind the text.
	var header_art := StationHeaderArt.new()
	header_art.station = station_id
	header_art.anchor_right = 1.0
	header_art.offset_bottom = 82.0
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


# ---- drawn header ornament (spec C — station-specific emblem + grain + flourish) ----
# Renders behind the title/close-hint labels as an overlay anchored to the
# top of the panel. Pure-vector (_draw only, no texture loads — white-rect safe).
# Trade-color flourish: SAGE for wilds stations (hearth, still), TERRACOTTA for earth.
class StationHeaderArt extends Control:
	var station := "cookfire"

	func _ready() -> void:
		resized.connect(queue_redraw)

	func _draw() -> void:
		if size.x < 4.0 or size.y < 4.0:
			return
		# Parchment grain across the header band (behind the labels).
		WyrdUi.draw_parchment_grain(self,
			Rect2(Vector2(18.0, 12.0), Vector2(size.x - 36.0, 64.0)), 37)
		# Flourish centred under the title bar. Trade-tinted: wilds = SAGE, earth = TERRACOTTA.
		var accent := WyrdUi.SAGE if station != "forge" else WyrdUi.TERRACOTTA
		WyrdUi.draw_flourish(self, Vector2(size.x * 0.5, 68.0), size.x - 96.0)
		# A subtle accent wash along the top of the flourish line.
		draw_rect(Rect2(Vector2(18.0, 66.5), Vector2(size.x - 36.0, 1.5)),
			Color(accent, 0.28))
		# Station emblem tucked into the top-left, left of the title (title starts at x=54).
		_draw_badge(Vector2(30.0, 43.0), 21.0, accent)

	func _draw_badge(c: Vector2, r: float, accent: Color) -> void:
		match station:
			"forge":
				_draw_anvil(c, r, accent)
			"still":
				_draw_flask(c, r, accent)
			_:
				_draw_cauldron(c, r)

	# A small copper cauldron with side handles and steam wisps.
	func _draw_cauldron(c: Vector2, r: float) -> void:
		var copper := Color(0.66, 0.40, 0.24)
		var copper_lit := Color(0.85, 0.56, 0.34)
		draw_circle(c, r, copper)
		draw_arc(c, r - 2.5, PI * 0.85, PI * 1.85, 18, copper_lit, 3.5, true)
		draw_circle(c, r * 0.55, Color(0.20, 0.14, 0.10))
		draw_arc(c, r * 0.55, 0, TAU, 22, Color(0.10, 0.07, 0.05), 1.2, true)
		for hside in [-1.0, 1.0]:
			draw_arc(c + Vector2(hside * (r + 3.5), 0.0), 4.0,
				PI * (0.5 - 0.5 * hside) - PI * 0.5,
				PI * (0.5 - 0.5 * hside) + PI * 0.5,
				8, WyrdUi.KIT_EDGE, 2.0, true)
		draw_arc(c, r, 0, TAU, 36, WyrdUi.KIT_EDGE, 1.5, true)
		# Two light steam wisps rising above the brew.
		for wx in [-5.0, 5.0]:
			draw_arc(Vector2(c.x + wx, c.y - r - 7.0), 4.0,
				PI * 0.2, PI * 1.0, 8, Color(0.93, 0.91, 0.85, 0.38), 1.5, true)

	# A round-bottomed alchemist flask — slender neck, fat belly, sage-tinted glass.
	func _draw_flask(c: Vector2, r: float, tint: Color) -> void:
		var glass := Color(tint.r * 0.70 + 0.22, tint.g * 0.55 + 0.34,
			tint.b * 0.40 + 0.48, 0.65)
		var neck_half := r * 0.24
		var neck_top := c.y - r * 1.10
		var belly_c := c + Vector2(0.0, r * 0.18)
		var belly_r := r * 0.80
		# Glass belly.
		draw_circle(belly_c, belly_r, glass)
		# Brew fill (lower half of belly — a darker pool).
		var brew := Color(tint.r * 0.50 + 0.05, tint.g * 0.60 + 0.18,
			tint.b * 0.45 + 0.20, 0.85)
		var brew_pts := PackedVector2Array()
		for i in 22:
			var t := lerpf(0.0, PI, float(i) / 21.0)
			brew_pts.append(belly_c + Vector2(cos(t), sin(t)) * belly_r)
		brew_pts.append(belly_c + Vector2(0, -belly_r * 0.1))
		draw_colored_polygon(brew_pts, brew)
		# Glass highlight arc (top-left specular).
		draw_arc(belly_c + Vector2(-belly_r * 0.35, -belly_r * 0.30),
			belly_r * 0.25, PI * 0.7, PI * 1.45, 10, Color(1, 1, 1, 0.48), 2.0, true)
		# Belly ink border.
		draw_arc(belly_c, belly_r, 0, TAU, 36, WyrdUi.KIT_EDGE, 1.5, true)
		# Neck (narrow rectangle above belly).
		var neck := Rect2(c + Vector2(-neck_half, neck_top - (c.y - belly_c.y + belly_r * 0.6)),
			Vector2(neck_half * 2.0, belly_r * 0.85))
		draw_rect(neck, glass)
		draw_rect(neck, WyrdUi.KIT_EDGE, false, 1.2)
		# Cork stopper.
		var cork := Rect2(neck.position - Vector2(neck_half * 0.4, r * 0.22),
			Vector2(neck.size.x + neck_half * 0.8, r * 0.22))
		draw_rect(cork, Color(0.62, 0.46, 0.30))
		draw_rect(cork, WyrdUi.KIT_EDGE, false, 1.0)

	# Stylized side-view anvil: flat top face, tapered body, horn right, gold sparks.
	func _draw_anvil(c: Vector2, r: float, _accent: Color) -> void:
		var iron := Color(0.38, 0.34, 0.30)
		var iron_lit := Color(0.54, 0.49, 0.43)
		# Anvil body (trapezoid below the top face).
		var body := PackedVector2Array([
			c + Vector2(-r * 0.72, r * 0.12),
			c + Vector2(r * 0.78, r * 0.12),
			c + Vector2(r * 0.62, r * 0.62),
			c + Vector2(-r * 0.62, r * 0.62),
		])
		draw_colored_polygon(body, iron)
		# Top working face (lighter).
		var top_face := PackedVector2Array([
			c + Vector2(-r * 0.60, -r * 0.36),
			c + Vector2(r * 0.68, -r * 0.36),
			c + Vector2(r * 0.78, r * 0.12),
			c + Vector2(-r * 0.72, r * 0.12),
		])
		draw_colored_polygon(top_face, iron_lit)
		# Bick / horn (right taper — the pointy end).
		var horn := PackedVector2Array([
			c + Vector2(r * 0.78, -r * 0.08),
			c + Vector2(r * 1.22, -r * 0.28),
			c + Vector2(r * 1.24, r * 0.04),
			c + Vector2(r * 0.78, r * 0.12),
		])
		draw_colored_polygon(horn, iron_lit)
		# Ink borders.
		draw_polyline(body + PackedVector2Array([body[0]]), WyrdUi.KIT_EDGE, 1.5, true)
		draw_polyline(horn + PackedVector2Array([horn[0]]),
			Color(WyrdUi.KIT_EDGE, 0.55), 1.0, true)
		# Three gold sparks scattered above the top face (deterministic seed).
		var rng := RandomNumberGenerator.new()
		rng.seed = 29
		for _i in 3:
			var sp := c + Vector2(rng.randf_range(-r * 0.35, r * 0.55),
				rng.randf_range(-r * 0.85, -r * 0.45))
			var dl := rng.randf_range(3.5, 6.0)
			draw_line(sp, sp + Vector2(dl, -dl), Color(WyrdUi.GOLD, 0.82), 1.5)
