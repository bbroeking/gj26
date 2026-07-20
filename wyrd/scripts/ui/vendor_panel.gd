extends CanvasLayer

# Wyrd — Hod's counter. Left: your gear (click to sell — he melts it down).
# Right: his wares (click to buy). Gold readout updates live. Esc closes.
#
# Spec 59 — Hod is the transaction-family pilot for the shared semantic
# JournalListRow. Rows keep one-click buy/sell behavior while presenting icon,
# identity, owned count/rarity, price, affordability, and focus consistently.

const GatherDefs = preload("res://data/gather.gd")
const ItemsData = preload("res://data/items.gd")
const Tokens = preload("res://scripts/ui/foundation/ui_tokens.gd")
const FocusPointer = preload("res://scripts/ui/components/focus_pointer.gd")
const JournalRow = preload("res://scripts/ui/components/journal_list_row.gd")
const FIELD_THEME := preload("res://themes/wayfinder_theme.tres")

# Painted item icons come from the item catalogue (ItemsData.ICON_TEX) — the
# same map the pack draws from. Preloaded in _ready and handed to each card;
# a CompressedTexture2D whose first load() lands inside _draw renders as a
# white rect (macOS, Godot 4.6).

# Rarity tints route through the one game-wide ramp (WyrdUi.RARITY) so the
# counter glows the same as the pack, loot beam, and tooltips.

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
	for path in ItemsData.ICON_TEX.values():
		if ResourceLoader.exists(String(path)):
			_tex_cache[String(path)] = load(String(path))
	for path in GatherDefs.ICON_TEX.values():
		if ResourceLoader.exists(String(path)):
			_tex_cache[String(path)] = load(String(path))
	WyrdUi.make_backdrop(self, _close)   # spec 53 — one scrim + click-outside dismiss
	_panel = Panel.new()
	_panel.name = "TransactionShell"
	_panel.theme = FIELD_THEME
	_panel.theme_type_variation = &"JournalFrame"
	_panel.anchor_left = 0.5
	_panel.anchor_top = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_bottom = 0.5
	_panel.offset_left = -460
	_panel.offset_top = -270
	_panel.offset_right = 460
	_panel.offset_bottom = 270
	add_child(_panel)

	var header := HBoxContainer.new()
	header.name = "TransactionHeader"
	header.anchor_right = 1.0
	header.offset_left = 54.0
	header.offset_top = 28.0
	header.offset_right = -28.0
	header.offset_bottom = 82.0
	header.add_theme_constant_override("separation", Tokens.SPACE_3)
	_panel.add_child(header)
	var heading := VBoxContainer.new()
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_theme_constant_override("separation", 0)
	header.add_child(heading)
	var title := Label.new()
	title.text = "Hod's Counter"
	title.theme_type_variation = &"PageTitle"
	heading.add_child(title)
	var sub := Label.new()
	sub.text = "\"Sparks like to find sleeves. Mind the anvil, state your business.\""
	sub.theme_type_variation = &"Body"
	sub.add_theme_color_override("font_color", Tokens.TEXT_ON_PAPER_DIM)
	heading.add_child(sub)
	_gold_lbl = Label.new()
	_gold_lbl.name = "GoldChip"
	WyrdUi.style_chip(_gold_lbl, WyrdUi.SIZE_SECTION)
	_gold_lbl.add_theme_color_override("font_color", WyrdUi.GOLD)
	_gold_lbl.custom_minimum_size = Vector2(150.0, Tokens.HIT_TARGET)
	_gold_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_gold_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(_gold_lbl)
	var close_button := Button.new()
	close_button.name = "CloseButton"
	close_button.text = "×"
	close_button.tooltip_text = "Close Hod's Counter"
	close_button.custom_minimum_size = Vector2(Tokens.HIT_TARGET, Tokens.HIT_TARGET)
	close_button.theme_type_variation = &"SecondaryButton"
	close_button.pressed.connect(_close)
	header.add_child(close_button)

	var columns := HBoxContainer.new()
	columns.anchor_right = 1.0
	columns.anchor_bottom = 1.0
	columns.offset_left = 52
	columns.offset_top = 104
	columns.offset_right = -52
	columns.offset_bottom = -42
	columns.add_theme_constant_override("separation", 26)
	_panel.add_child(columns)

	var sell_panel := PanelContainer.new()
	sell_panel.name = "SellSourcePanel"
	sell_panel.theme_type_variation = &"PaperRaised"
	sell_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sell_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sell_panel.size_flags_stretch_ratio = 0.9
	columns.add_child(sell_panel)
	var col1 := VBoxContainer.new()
	col1.add_theme_constant_override("separation", Tokens.SPACE_2)
	sell_panel.add_child(col1)
	var sell_hdr := Label.new()
	sell_hdr.text = "Your Pack"
	sell_hdr.theme_type_variation = &"SectionTitle"
	col1.add_child(sell_hdr)
	var sell_note := Label.new()
	sell_note.text = "Choose gear for Hod to melt down."
	sell_note.theme_type_variation = &"Caption"
	col1.add_child(sell_note)
	# A full pack outgrows the panel — the sell list scrolls now.
	var sell_scroll := ScrollContainer.new()
	sell_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sell_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col1.add_child(sell_scroll)
	_sell_box = VBoxContainer.new()
	_sell_box.add_theme_constant_override("separation", Tokens.SPACE_2)
	_sell_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sell_scroll.add_child(_sell_box)

	var buy_panel := PanelContainer.new()
	buy_panel.name = "WaresPanel"
	buy_panel.theme_type_variation = &"PaperRaised"
	buy_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buy_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	buy_panel.size_flags_stretch_ratio = 1.1
	columns.add_child(buy_panel)
	var col2 := VBoxContainer.new()
	col2.add_theme_constant_override("separation", Tokens.SPACE_2)
	buy_panel.add_child(col2)
	var buy_hdr := Label.new()
	buy_hdr.text = "Hod's Wares"
	buy_hdr.theme_type_variation = &"SectionTitle"
	col2.add_child(buy_hdr)
	var buy_note := Label.new()
	buy_note.text = "Supplies for the road and workbench."
	buy_note.theme_type_variation = &"Caption"
	col2.add_child(buy_note)
	var buy_scroll := ScrollContainer.new()
	buy_scroll.name = "WaresScroll"
	buy_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	buy_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col2.add_child(buy_scroll)
	_buy_box = VBoxContainer.new()
	_buy_box.name = "WaresList"
	_buy_box.add_theme_constant_override("separation", Tokens.SPACE_2)
	_buy_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buy_scroll.add_child(_buy_box)

	get_node("/root/Game").modal_opened()
	_render()
	var focus_pointer := FocusPointer.new()
	focus_pointer.name = "TransactionFocusPointer"
	add_child(focus_pointer)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_close()

func _close() -> void:
	get_node("/root/Game").modal_closed()
	queue_free()

func _render() -> void:
	if _game == null:
		return
	_gold_lbl.text = "%d gold" % int(_game.gold)
	for c in _sell_box.get_children():
		c.queue_free()
	var items: Array = []
	if _game.inventory != null:
		for item_v in _game.inventory.items:
			if item_v is Dictionary and bool((item_v as Dictionary).get("sellable", true)):
				items.append(item_v)
	if items.is_empty():
		var empty := JournalRow.new()
		empty.name = "EmptySellRow"
		empty.setup({
			"title": "Nothing to melt down",
			"subtitle": "Gear in your Pack will appear here.",
			"glyph": "⚒",
			"state": JournalRow.RowState.DISABLED,
		})
		_sell_box.add_child(empty)
	for item_index in items.size():
		var item = items[item_index]
		var it: Dictionary = item
		var rarity := String(it.get("rarity", "normal"))
		var rc: Color = WyrdUi.RARITY.get(rarity, WyrdUi.INK_MID)
		var path := String(ItemsData.ICON_TEX.get(String(it.get("kind_id", "")), ""))
		var card := JournalRow.new()
		card.name = "SellRow%d" % item_index
		# Keep the row's production transaction target inspectable.  The strict
		# release driver uses this same bound Dictionary to prove that the exact
		# ground pickup carried home is the item Hod melts; ordinary UI code still
		# owns the sale through this row's pressed signal.
		card.set_meta("inventory_item", it)
		card.setup({
			"title": String(it.get("name", "?")),
			"subtitle": "%s %s" % [rarity.capitalize(),
				String(it.get("category", "gear")).capitalize()],
			"trailing": "+%dg" % EconomyData.sell_value(it),
			"badge": "Sell",
			"icon": _tex_cache.get(path, null),
			"tooltip": "Sell %s. Hod melts it down." % String(it.get("name", "item")),
			"trailing_color": rc if rarity != "normal" else Tokens.GOLD_MUTED,
			"badge_color": Tokens.TEXT_ON_PAPER_DIM,
		})
		card.pressed.connect(func():
			var price: int = _game.sell_item(it)
			if price > 0:
				_game.notify("Sold %s for %dg." % [String(it.get("name", "it")), price])
			_render())
		_sell_box.add_child(card)
	for c in _buy_box.get_children():
		c.queue_free()
	for ware in EconomyData.wares_for_level(_game.trade_lv("wayfinding")):
		var id := String(ware.id)
		if id == "repair_all":
			continue   # gold-sink ware needs a durability system first — skip
		var price := int(ware.price)
		var have: int = _game.material_count(id)
		var affordable: bool = int(_game.gold) >= price
		var icon_path := GatherDefs.material_icon_path(id)
		var card := JournalRow.new()
		card.setup({
			"title": GatherDefs.material_name(id),
			"subtitle": "In Satchel: %d" % have,
			"trailing": "%dg" % price,
			"badge": "Buy" if affordable else "Need %dg" % (price - int(_game.gold)),
			"icon": _tex_cache.get(icon_path, null),
			"glyph": GatherDefs.material_icon(id),
			"state": JournalRow.RowState.NORMAL if affordable \
				else JournalRow.RowState.DISABLED,
			"tooltip": "Buy %s for %d gold." % [GatherDefs.material_name(id), price],
			"trailing_color": Tokens.GOLD_MUTED if affordable else Tokens.TERRACOTTA,
			"badge_color": Tokens.SAGE.darkened(0.2) if affordable else Tokens.TERRACOTTA,
		})
		var bid := id
		var bprice := price
		card.pressed.connect(func():
			if _game.buy_ware(bid, bprice):
				_render())
		_buy_box.add_child(card)
	_focus_first_action.call_deferred()


func _focus_first_action() -> void:
	for box in [_sell_box, _buy_box]:
		for child in box.get_children():
			if child is Button and not child.is_queued_for_deletion() \
					and not (child as Button).disabled:
				(child as Button).grab_focus()
				return
