extends CanvasLayer

# Spec 59 — Quill's Still is an authored apothecary counter: choose a remedy
# from the shelf, read its use and price, then make one deliberate purchase.
# The domain boundary remains Game.buy_ware(); gathering stays the better value.

const GatherDefs = preload("res://data/gather.gd")
const EconomyData = preload("res://data/economy.gd")
const Tokens = preload("res://scripts/ui/foundation/ui_tokens.gd")
const FocusPointer = preload("res://scripts/ui/components/focus_pointer.gd")
const JournalRow = preload("res://scripts/ui/components/journal_list_row.gd")
const Workbench = preload("res://scripts/ui/components/transaction_workbench.gd")

const STILL_EMBLEM := preload("res://assets/ui/items/wild_herb.png")

const QUILL_WARES := [
	{"id": "wild_herb", "price": 5},
	{"id": "hedge_ink", "price": 18},
	{"id": "quickroot_tonic", "price": 14},
]

var _game: Node
var _workbench: TransactionWorkbench
var _selected := 0
var _shelf: VBoxContainer
var _gold_label: Label
var _hero_icon: TextureRect
var _hero_glyph: Label
var _name_label: Label
var _kind_label: Label
var _description: Label
var _owned_label: Label
var _price_label: Label
var _reason_label: Label
var _buy_button: Button
var _texture_cache := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 90
	_game = get_tree().root.get_node_or_null("Game")
	for path in GatherDefs.ICON_TEX.values():
		if ResourceLoader.exists(String(path)):
			_texture_cache[String(path)] = load(String(path))
	WyrdUi.make_backdrop(self, _close)
	_workbench = Workbench.new()
	_workbench.anchor_left = 0.5
	_workbench.anchor_top = 0.5
	_workbench.anchor_right = 0.5
	_workbench.anchor_bottom = 0.5
	_workbench.offset_left = -520.0
	_workbench.offset_top = -325.0
	_workbench.offset_right = 520.0
	_workbench.offset_bottom = 325.0
	_workbench.close_requested.connect(_close)
	add_child(_workbench)
	_workbench.setup("Quill's Still",
		"Herbs and woodsmoke. Take what you need; mind what the hedge gave.",
		STILL_EMBLEM)
	_gold_label = _workbench.add_resource_text("")
	_build_shelf(_workbench.add_leaf("RemedyShelfLeaf", 0.35))
	_build_counter(_workbench.add_leaf("ApothecaryCounterLeaf", 0.65))
	_workbench.add_footer_hint("↑↓ choose ware  ·  Enter inspect  ·  Esc close")
	get_node("/root/Game").modal_opened()
	_render()
	var focus_pointer := FocusPointer.new()
	focus_pointer.name = "TransactionFocusPointer"
	add_child(focus_pointer)
	_focus_selected.call_deferred()


func _build_shelf(leaf: VBoxContainer) -> void:
	var heading := Label.new()
	heading.text = "Quill's Shelf"
	heading.theme_type_variation = &"SectionTitle"
	leaf.add_child(heading)
	var hint := Label.new()
	hint.text = "Quill keeps a short shelf for hurried Wayfinders."
	hint.theme_type_variation = &"RowSubtitle"
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	leaf.add_child(hint)
	leaf.add_child(HSeparator.new())
	_shelf = VBoxContainer.new()
	_shelf.name = "RemedyShelf"
	_shelf.add_theme_constant_override("separation", Tokens.SPACE_2)
	_shelf.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	leaf.add_child(_shelf)
	var note := Label.new()
	note.text = "Bought goods go straight into your Satchel."
	note.theme_type_variation = &"Body"
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.size_flags_vertical = Control.SIZE_EXPAND_FILL
	note.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	leaf.add_child(note)


func _build_counter(leaf: VBoxContainer) -> void:
	leaf.add_theme_constant_override("separation", Tokens.SPACE_3)
	var heading := Label.new()
	heading.text = "Quill's Counter"
	heading.theme_type_variation = &"SectionTitle"
	leaf.add_child(heading)
	var hero := HBoxContainer.new()
	hero.name = "SelectedRemedyHero"
	hero.custom_minimum_size.y = 156.0
	hero.add_theme_constant_override("separation", Tokens.SPACE_4)
	leaf.add_child(hero)
	var center := CenterContainer.new()
	center.name = "RemedyHeroArt"
	center.custom_minimum_size = Vector2(150.0, 150.0)
	hero.add_child(center)
	_hero_icon = TextureRect.new()
	_hero_icon.custom_minimum_size = Vector2(118.0, 118.0)
	_hero_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_hero_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	center.add_child(_hero_icon)
	_hero_glyph = Label.new()
	_hero_glyph.theme_type_variation = &"PageTitle"
	_hero_glyph.add_theme_font_size_override("font_size", 42)
	_hero_glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hero_glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	center.add_child(_hero_glyph)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.alignment = BoxContainer.ALIGNMENT_CENTER
	copy.add_theme_constant_override("separation", Tokens.SPACE_1)
	hero.add_child(copy)
	_name_label = Label.new()
	_name_label.theme_type_variation = &"PageTitle"
	_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(_name_label)
	_kind_label = Label.new()
	_kind_label.theme_type_variation = &"SectionTitle"
	copy.add_child(_kind_label)
	_description = Label.new()
	_description.name = "RemedyConsequence"
	_description.theme_type_variation = &"Body"
	_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_description.custom_minimum_size.y = 68.0
	copy.add_child(_description)
	leaf.add_child(HSeparator.new())
	var terms := HBoxContainer.new()
	terms.name = "PurchaseTerms"
	terms.add_theme_constant_override("separation", Tokens.SPACE_3)
	leaf.add_child(terms)
	_owned_label = _make_term_plate(terms, "In your Satchel")
	_price_label = _make_term_plate(terms, "Quill asks")
	_reason_label = Label.new()
	_reason_label.name = "PurchaseReason"
	_reason_label.theme_type_variation = &"Body"
	_reason_label.custom_minimum_size.y = 24.0
	_reason_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_reason_label.add_theme_color_override("font_color", Tokens.TERRACOTTA)
	leaf.add_child(_reason_label)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	leaf.add_child(spacer)
	_buy_button = Button.new()
	_buy_button.name = "PrimaryBuyAction"
	_buy_button.theme_type_variation = &"PrimaryButton"
	_buy_button.custom_minimum_size.y = 56.0
	_buy_button.pressed.connect(_buy_selected)
	leaf.add_child(_buy_button)


func _make_term_plate(parent: HBoxContainer, caption: String) -> Label:
	var plate := PanelContainer.new()
	plate.theme_type_variation = &"PaperSurface"
	plate.custom_minimum_size = Vector2(190.0, 64.0)
	plate.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(plate)
	var stack := VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	plate.add_child(stack)
	var heading := Label.new()
	heading.text = caption
	heading.theme_type_variation = &"RowSubtitle"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(heading)
	var value := Label.new()
	value.theme_type_variation = &"SectionTitle"
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(value)
	return value


func _render() -> void:
	if _game == null:
		return
	_gold_label.text = "◆ %d gold" % int(_game.gold)
	_selected = clampi(_selected, 0, QUILL_WARES.size() - 1)
	_render_shelf()
	_render_counter()


func _render_shelf() -> void:
	for child in _shelf.get_children():
		_shelf.remove_child(child)
		child.queue_free()
	for index in QUILL_WARES.size():
		var ware: Dictionary = QUILL_WARES[index]
		var id := String(ware.id)
		var price := int(ware.price)
		var have: int = _game.material_count(id)
		var level_needed := EconomyData.ware_min_lv(id)
		var level_ok: bool = _game.trade_lv("wayfinding") >= level_needed
		var affordable: bool = int(_game.gold) >= price and level_ok
		var row := JournalRow.new()
		row.name = "Remedy_%s" % id
		row.setup({
			"title": GatherDefs.material_name(id),
			"subtitle": "Owned ×%d" % have,
			"trailing": "%dg" % price,
			"badge": "Ready" if affordable else ("Lv %d" % level_needed \
				if not level_ok else "Need %dg" % (price - int(_game.gold))),
			"icon": _material_texture(id),
			"glyph": GatherDefs.material_icon(id),
			"state": JournalRow.RowState.SELECTED if index == _selected \
				else (JournalRow.RowState.NORMAL if affordable else JournalRow.RowState.DISABLED),
			"trailing_color": Tokens.GOLD_MUTED,
			"badge_color": Tokens.SAGE.darkened(0.25) if affordable else Tokens.TERRACOTTA,
			"tooltip": "Inspect %s. In Satchel: %d." % [GatherDefs.material_name(id), have],
		})
		row.disabled = false
		row.pressed.connect(_select_ware.bind(index))
		_shelf.add_child(row)


func _render_counter() -> void:
	var ware: Dictionary = QUILL_WARES[_selected]
	var id := String(ware.id)
	var price := int(ware.price)
	var have: int = _game.material_count(id)
	var level_needed := EconomyData.ware_min_lv(id)
	var level_ok: bool = _game.trade_lv("wayfinding") >= level_needed
	var gold_ok: bool = int(_game.gold) >= price
	_hero_icon.texture = _material_texture(id)
	_hero_icon.visible = _hero_icon.texture != null
	_hero_glyph.text = GatherDefs.material_icon(id)
	_hero_glyph.visible = not _hero_icon.visible
	_name_label.text = GatherDefs.material_name(id)
	_kind_label.text = _kind_line(id)
	_description.text = String(GatherDefs.MATERIALS.get(id, {}).get("desc", "A useful thing for the road."))
	_owned_label.text = "%d owned" % have
	_price_label.text = "%dg · %dg remains" % [price, maxi(0, int(_game.gold) - price)]
	_buy_button.text = "Buy %s — %dg" % [GatherDefs.material_name(id), price]
	_buy_button.disabled = not (level_ok and gold_ok)
	if not level_ok:
		_reason_label.text = "Requires Wayfinding %d." % level_needed
	elif not gold_ok:
		_reason_label.text = "Quill needs %d more gold." % (price - int(_game.gold))
	else:
		_reason_label.text = ""


func _select_ware(index: int) -> void:
	_selected = clampi(index, 0, QUILL_WARES.size() - 1)
	_render()
	_buy_button.grab_focus.call_deferred()


func _buy_selected() -> void:
	if _game == null:
		return
	var ware: Dictionary = QUILL_WARES[_selected]
	if _game.buy_ware(String(ware.id), int(ware.price)):
		_render()
		_buy_button.grab_focus.call_deferred()


func _focus_selected() -> void:
	if _shelf == null or _shelf.get_child_count() == 0:
		return
	var row := _shelf.get_child(clampi(_selected, 0, _shelf.get_child_count() - 1)) as Button
	if row != null and not row.is_queued_for_deletion():
		row.grab_focus()


func _kind_line(id: String) -> String:
	match id:
		"wild_herb": return "Pressed from the hedgerow"
		"hedge_ink": return "For the first written roads"
		"quickroot_tonic": return "A brisk ninety-second brew"
		_: return "Quill's shelf"


func _material_texture(id: String) -> Texture2D:
	if id == "quickroot_tonic":
		var tonic_path := "res://assets/ui/field_journal/icons/quickroot_tonic.png"
		if not _texture_cache.has(tonic_path) and ResourceLoader.exists(tonic_path):
			_texture_cache[tonic_path] = load(tonic_path)
		return _texture_cache.get(tonic_path, null) as Texture2D
	return _texture_cache.get(GatherDefs.material_icon_path(id), null) as Texture2D


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_close()


func _close() -> void:
	get_node("/root/Game").modal_closed()
	queue_free()
