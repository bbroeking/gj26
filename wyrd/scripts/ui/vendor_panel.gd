extends CanvasLayer

# Wyrd — Hod's counter. Left: your gear (click to sell — he melts it down).
# Right: his wares (click to buy). Gold readout updates live. Esc closes.
#
# Slice C — the rows are no longer text pills. Each is a drawn item card
# (WyrdUi.draw_list_row plate + painted icon plate + name + price + rarity
# ring) so the counter reads as a carved shelf, not a spreadsheet.

const GatherDefs = preload("res://data/gather.gd")

# Painted item icons (shared with the pack). Preloaded in _ready and handed to
# each card — a CompressedTexture2D whose first load() lands inside _draw
# renders as a white rect (macOS, Godot 4.6).
const ICON_TEX := {
	"shortbow": "res://assets/ui/items/shortbow.png",
	"longbow": "res://assets/ui/items/longbow.png",
	"leather_helm": "res://assets/ui/items/leather_helm.png",
	"leather_chest": "res://assets/ui/items/leather_chest.png",
	"leather_boots": "res://assets/ui/items/leather_boots.png",
	"copper_ring": "res://assets/ui/items/copper_ring.png",
}

# Rarity tints — lifted from inventory_panel.gd so cards glow the same.
const RARITY_COLOR := {
	"normal": Color(0.48, 0.40, 0.30),   # quiet ink — normals don't shout
	"magic":  Color(0.25, 0.42, 0.75),
	"rare":   Color(0.82, 0.62, 0.12),
	"unique": Color(0.80, 0.38, 0.10),
}

var _game: Node
var _panel: Panel
var _gold_lbl: Label
var _sell_box: VBoxContainer
var _buy_box: VBoxContainer
var _tex_cache := {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 90
	_game = get_tree().root.get_node_or_null("Game")
	# Preload painted icons once (white-rect-in-_draw gotcha).
	for path in ICON_TEX.values():
		if ResourceLoader.exists(String(path)):
			_tex_cache[String(path)] = load(String(path))
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
	_panel.offset_left = -380
	_panel.offset_top = -260
	_panel.offset_right = 380
	_panel.offset_bottom = 260
	add_child(_panel)

	var title := Label.new()
	title.text = "Hod's Counter"
	WyrdUi.style_title(title)
	title.position = Vector2(54, 34)
	_panel.add_child(title)

	var sub := Label.new()
	sub.text = "\"Sparks like to find sleeves. Mind the anvil, state your business.\""
	WyrdUi.style_dim(sub, 13)
	sub.position = Vector2(54, 66)
	_panel.add_child(sub)

	_gold_lbl = Label.new()
	WyrdUi.style_chip(_gold_lbl, 15)
	_gold_lbl.add_theme_color_override("font_color", WyrdUi.GOLD)
	_gold_lbl.anchor_left = 1.0
	_gold_lbl.anchor_right = 1.0
	_gold_lbl.offset_left = -200
	_gold_lbl.offset_top = 36
	_panel.add_child(_gold_lbl)

	var close_hint := Label.new()
	close_hint.text = "Esc — close"
	WyrdUi.style_dim(close_hint)
	close_hint.anchor_left = 1.0
	close_hint.anchor_right = 1.0
	close_hint.anchor_top = 1.0
	close_hint.anchor_bottom = 1.0
	close_hint.offset_left = -110
	close_hint.offset_top = -28
	_panel.add_child(close_hint)

	var columns := HBoxContainer.new()
	columns.anchor_right = 1.0
	columns.anchor_bottom = 1.0
	columns.offset_left = 52
	columns.offset_top = 94
	columns.offset_right = -52
	columns.offset_bottom = -56
	columns.add_theme_constant_override("separation", 26)
	_panel.add_child(columns)

	var col1 := VBoxContainer.new()
	col1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col1.add_theme_constant_override("separation", 6)
	columns.add_child(col1)
	var sell_hdr := Label.new()
	sell_hdr.text = "Sell (he melts it down)"
	WyrdUi.style_section(sell_hdr)
	col1.add_child(sell_hdr)
	# A full pack outgrows the panel — the sell list scrolls now.
	var sell_scroll := ScrollContainer.new()
	sell_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sell_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col1.add_child(sell_scroll)
	_sell_box = VBoxContainer.new()
	_sell_box.add_theme_constant_override("separation", 5)
	_sell_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sell_scroll.add_child(_sell_box)

	var col2 := VBoxContainer.new()
	col2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col2.add_theme_constant_override("separation", 6)
	columns.add_child(col2)
	var buy_hdr := Label.new()
	buy_hdr.text = "Wares"
	WyrdUi.style_section(buy_hdr)
	col2.add_child(buy_hdr)
	_buy_box = VBoxContainer.new()
	_buy_box.add_theme_constant_override("separation", 5)
	_buy_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col2.add_child(_buy_box)

	get_node("/root/Game").modal_opened()
	_render()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_node("/root/Game").modal_closed()
		queue_free()

func _render() -> void:
	if _game == null:
		return
	_gold_lbl.text = "%d gold" % int(_game.gold)
	for c in _sell_box.get_children():
		c.queue_free()
	var items: Array = _game.inventory.items if _game.inventory != null else []
	if items.is_empty():
		var l := Label.new()
		l.text = "Your pack holds no gear. The hollows provide."
		WyrdUi.style_dim(l, 13)
		_sell_box.add_child(l)
	for item in items:
		var it: Dictionary = item
		var rarity := String(it.get("rarity", "normal"))
		var rc: Color = RARITY_COLOR.get(rarity, WyrdUi.INK_MID)
		var path := String(ICON_TEX.get(String(it.get("kind_id", "")), ""))
		var card := _VendorCard.new()
		card.setup_sell(String(it.get("name", "?")), EconomyData.sell_value(it),
			rarity, rc, _tex_cache.get(path, null))
		card.tooltip_text = "%s · %s" % [rarity.capitalize(),
			String(it.get("category", "")).capitalize()]
		card.pressed.connect(func():
			var price: int = _game.sell_item(it)
			if price > 0:
				_game.notify("Sold %s for %dg." % [String(it.get("name", "it")), price])
			_render())
		_sell_box.add_child(card)
	for c in _buy_box.get_children():
		c.queue_free()
	for ware in EconomyData.wares_for_level(_game.trade_lv()):
		var id := String(ware.id)
		if id == "repair_all":
			continue   # gold-sink ware needs a durability system first — skip
		var price := int(ware.price)
		var have: int = _game.material_count(id)
		var affordable: bool = int(_game.gold) >= price
		var card := _VendorCard.new()
		card.setup_buy(GatherDefs.material_name(id), price, have, affordable,
			GatherDefs.material_icon(id))
		var bid := id
		var bprice := price
		card.pressed.connect(func():
			if _game.buy_ware(bid, bprice):
				_render())
		_buy_box.add_child(card)


# ---- the drawn item card (one row) ----
# A small clickable Control: draw_list_row plate, a painted icon plate on the
# left, the name in ink, and the price in gold (red when unaffordable on buy).
# Magic+ items get a rarity ring + a faint glow, the pack's pickup language.
# Fully self-contained — callers hand it everything it draws (rarity color,
# texture) so it never reaches back into the outer script's const tables.
class _VendorCard extends Control:
	const ICON_W := 40.0

	var _name := ""
	var _price := 0
	var _price_red := false        # unaffordable buy → red price
	var _sub := ""                 # right-side note (e.g. "have 3")
	var _rarity := "normal"
	var _rc: Color = Color(0.48, 0.40, 0.30)   # rarity tint (handed in)
	var _tex: Texture2D = null     # painted item icon (sell), else null
	var _glyph := ""               # material glyph (buy)
	var _hover := false

	signal pressed

	func _init() -> void:
		custom_minimum_size = Vector2(0, 54.0)
		mouse_filter = Control.MOUSE_FILTER_STOP

	func setup_sell(item_name: String, value: int, rarity: String,
			rarity_color: Color, tex: Texture2D) -> void:
		_name = item_name
		_price = value
		_rarity = rarity
		_rc = rarity_color
		_tex = tex
		queue_redraw()

	func setup_buy(mat_name: String, price: int, have: int, affordable: bool,
			glyph: String) -> void:
		_name = mat_name
		_price = price
		_price_red = not affordable
		_sub = "have %d" % have
		_glyph = glyph
		_rarity = "normal"
		queue_redraw()

	func _gui_input(event: InputEvent) -> void:
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
		# Accent stripe: rarity tint carries the card's read (gold/blue/orange
		# for magic+, quiet ink for normals).
		var accent: Color = _rc if _rarity != "normal" else WyrdUi.INK_MID
		WyrdUi.draw_list_row(self, r, accent)
		if _hover:
			draw_rect(r.grow(-1.5), Color(1.0, 1.0, 0.90, 0.10))
		# --- icon plate on the left ---
		var ir := Rect2(Vector2(9.0, (size.y - ICON_W) * 0.5),
			Vector2(ICON_W, ICON_W))
		WyrdUi.draw_well(self, ir)
		if _rarity != "normal":
			# faint rarity glow inside the plate (pickup language)
			for i in 2:
				var g := _rc
				g.a = 0.12 + 0.06 * float(1 - i)
				draw_rect(ir.grow(-2.0 - i * 2.0), g)
		var font := get_theme_default_font()
		if _tex != null:
			draw_texture_rect(_tex, ir.grow(-4.0), false)
		elif _glyph != "":
			draw_string(font, ir.position + Vector2(0, ICON_W * 0.5 + 6.0),
				_glyph, HORIZONTAL_ALIGNMENT_CENTER, ICON_W, 18, WyrdUi.INK)
		# rarity ring around the icon plate
		if _rarity != "normal":
			draw_rect(ir, _rc, false, 2.0)
		# --- name (ink; rarity-tinted for magic+) ---
		var tx := ir.end.x + 12.0
		var name_col: Color = _rc if _rarity != "normal" else WyrdUi.INK
		draw_string(font, Vector2(tx, size.y * 0.5 - 2.0), _name,
			HORIZONTAL_ALIGNMENT_LEFT, size.x - tx - 86.0, 16, name_col)
		if _sub != "":
			draw_string(font, Vector2(tx, size.y * 0.5 + 16.0), _sub,
				HORIZONTAL_ALIGNMENT_LEFT, size.x - tx - 86.0, 12, WyrdUi.INK_MID)
		# --- price (gold, right-aligned; red when unaffordable on buy) ---
		var price_col: Color = WyrdUi.TERRACOTTA if _price_red else WyrdUi.GOLD
		draw_string(font, Vector2(size.x - 84.0, size.y * 0.5 + 5.0),
			"%dg" % _price, HORIZONTAL_ALIGNMENT_RIGHT, 74.0, 17, price_col)
