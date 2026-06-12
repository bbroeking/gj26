extends CanvasLayer

# Wyrd — Hod's counter. Left: your gear (click to sell — he melts it down).
# Right: his wares (click to buy). Gold readout updates live. Esc closes.

const GatherDefs = preload("res://data/gather.gd")

var _game: Node
var _panel: Panel
var _gold_lbl: Label
var _sell_box: VBoxContainer
var _buy_box: VBoxContainer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 90
	_game = get_tree().root.get_node_or_null("Game")
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
	_sell_box.add_theme_constant_override("separation", 4)
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
	_buy_box.add_theme_constant_override("separation", 4)
	col2.add_child(_buy_box)

	get_tree().paused = true
	_render()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().paused = false
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
		var b := Button.new()
		WyrdUi.style_kit_button(b)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.text = "%s  —  %dg" % [String(item.get("name", "?")),
			EconomyData.sell_value(item)]
		b.tooltip_text = "%s · %s" % [String(item.get("rarity", "normal")),
			String(item.get("category", "")) ]
		var it: Dictionary = item
		b.pressed.connect(func():
			var price: int = _game.sell_item(it)
			if price > 0:
				_game.notify("Sold %s for %dg." % [String(it.get("name", "it")), price])
			_render())
		_sell_box.add_child(b)
	for c in _buy_box.get_children():
		c.queue_free()
	for ware in EconomyData.WARES:
		var id := String(ware.id)
		var price := int(ware.price)
		var b := Button.new()
		WyrdUi.style_kit_button(b)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var have: int = _game.material_count(id)
		b.text = "%s %s  —  %dg   (have %d)" % [GatherDefs.material_icon(id),
			GatherDefs.material_name(id), price, have]
		b.disabled = int(_game.gold) < price
		b.pressed.connect(func():
			if _game.buy_ware(id, price):
				_render())
		_buy_box.add_child(b)
