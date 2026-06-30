extends CanvasLayer

# Wyrd — Quill's Still. Buy-only convenience shelf; no sell column.
# Wares are priced ~1.5× Hod's rates — gathering is always cheaper.
# Quill's "pre-rolled chart" line is wired to dialog-only until
# game.gd gains a buy_chart() verb (deferred: impl-system-economy task 11).
#
# Kit-styled to match vendor_panel (WyrdUi tokens + drawn cards).
# No class_name — headless-safe (GDScript class_name not registered headless).

const GatherDefs = preload("res://data/gather.gd")
const EconomyData = preload("res://data/economy.gd")

# Quill's wares — convenience markup over Hod to keep gathering valuable.
# "common_chart_snug" is stubbed as a dialog hint until buy_chart() ships.
const QUILL_WARES := [
	{"id": "wild_herb",  "price": 5},
	{"id": "hedge_ink",  "price": 18},
	{"id": "quickroot_tonic", "price": 14, "label": "Quickroot Tonic (brew)"},
]

var _game: Node
var _panel: Panel
var _gold_lbl: Label
var _buy_box: VBoxContainer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 90
	_game = get_tree().root.get_node_or_null("Game")
	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.50)
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
	_panel.offset_left = -240
	_panel.offset_top = -220
	_panel.offset_right = 240
	_panel.offset_bottom = 220
	add_child(_panel)

	var title := Label.new()
	title.text = "Quill's Still"
	WyrdUi.style_title(title)
	title.position = Vector2(54, 34)
	_panel.add_child(title)

	var sub := Label.new()
	sub.text = "\"Herbs and woodsmoke. Take what you need, leave the seeds.\""
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

	var col := VBoxContainer.new()
	col.anchor_right = 1.0
	col.anchor_bottom = 1.0
	col.offset_left = 52
	col.offset_top = 94
	col.offset_right = -52
	col.offset_bottom = -56
	col.add_theme_constant_override("separation", 6)
	_panel.add_child(col)

	var buy_hdr := Label.new()
	buy_hdr.text = "Tonics & Herbs"
	WyrdUi.style_section(buy_hdr)
	col.add_child(buy_hdr)

	_buy_box = VBoxContainer.new()
	_buy_box.add_theme_constant_override("separation", 5)
	_buy_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(_buy_box)

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
	for c in _buy_box.get_children():
		c.queue_free()
	for ware in QUILL_WARES:
		var id := String(ware.id)
		var price := int(ware.price)
		var label: String = ware.get("label", GatherDefs.material_name(id))
		var have: int = _game.material_count(id)
		var lv_ok: bool = _game.trade_lv() >= EconomyData.ware_min_lv(id)
		var affordable: bool = int(_game.gold) >= price and lv_ok
		var min_lv: int = EconomyData.ware_min_lv(id)
		var card := _QuillCard.new()
		card.setup(label, price, have, affordable, lv_ok,
			GatherDefs.material_icon(id), min_lv)
		var bid := id
		var bprice := price
		var blv_ok := lv_ok
		card.pressed.connect(func():
			if blv_ok and _game.buy_ware(bid, bprice):
				_render())
		_buy_box.add_child(card)


# ---- drawn buy card (buy-only, no rarity ring) ----
# Mirrors _VendorCard from vendor_panel but stripped to the buy case.
# Locked wares are dimmed with a level note; never emit pressed when locked.
class _QuillCard extends Control:
	const ICON_W := 40.0

	var _name := ""
	var _price := 0
	var _price_red := false
	var _sub := ""
	var _glyph := ""
	var _locked := false
	var _min_lv := 1   # stored so _draw() doesn't need to look it up by name
	var _hover := false

	signal pressed

	func _init() -> void:
		custom_minimum_size = Vector2(0, 54.0)
		mouse_filter = Control.MOUSE_FILTER_STOP

	func setup(mat_name: String, price: int, have: int, affordable: bool,
			lv_ok: bool, glyph: String, min_lv: int = 1) -> void:
		_name = mat_name
		_price = price
		_price_red = not affordable
		_sub = "have %d" % have
		_glyph = glyph
		_locked = not lv_ok
		_min_lv = min_lv
		queue_redraw()

	func _gui_input(event: InputEvent) -> void:
		if _locked:
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
		var accent: Color = WyrdUi.SAGE if not _locked else WyrdUi.INK_MID
		WyrdUi.draw_list_row(self, r, accent)
		if _hover and not _locked:
			draw_rect(r.grow(-1.5), Color(1.0, 1.0, 0.90, 0.10))
		# icon plate
		var ir := Rect2(Vector2(9.0, (size.y - ICON_W) * 0.5),
			Vector2(ICON_W, ICON_W))
		WyrdUi.draw_well(self, ir)
		var font := get_theme_default_font()
		if _glyph != "":
			var glyph_col: Color = WyrdUi.INK_MID if _locked else WyrdUi.INK
			draw_string(font, ir.position + Vector2(0, ICON_W * 0.5 + 6.0),
				_glyph, HORIZONTAL_ALIGNMENT_CENTER, ICON_W, 18, glyph_col)
		# name
		var tx := ir.end.x + 12.0
		var name_col: Color = WyrdUi.INK_MID if _locked else WyrdUi.INK
		draw_string(font, Vector2(tx, size.y * 0.5 - 2.0), _name,
			HORIZONTAL_ALIGNMENT_LEFT, size.x - tx - 86.0, 16, name_col)
		# sub (have N) — or lock note when below required level
		var sub_text := _sub
		if _locked:
			sub_text = "Wayfinding %d" % _min_lv
		if sub_text != "":
			draw_string(font, Vector2(tx, size.y * 0.5 + 16.0), sub_text,
				HORIZONTAL_ALIGNMENT_LEFT, size.x - tx - 86.0, 12, WyrdUi.INK_MID)
		# price
		var price_col: Color = WyrdUi.TERRACOTTA if _price_red else WyrdUi.GOLD
		if _locked:
			price_col = WyrdUi.INK_MID
		draw_string(font, Vector2(size.x - 84.0, size.y * 0.5 + 5.0),
			"%dg" % _price, HORIZONTAL_ALIGNMENT_RIGHT, 74.0, 17, price_col)
