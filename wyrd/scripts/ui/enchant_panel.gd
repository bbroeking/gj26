extends CanvasLayer

# The Charm Table — bind/swap enchants (skills-on-items) onto equipped gear.
# Pure view over Game.bind_enchant / unbind_enchant / can_bind_enchant.
#
# Left column: your enchantable gear (weapon/armour/ring — tools have no
# slots). Right column: the selected piece's bound charms (click to draw one
# out) and the charms you can bind onto it (click to bind; greyed when you
# can't yet — undiscovered, slots full, wrong gear, or short reagents).
# Binding is swappable and costs reagents each time; drawing one out is free.

const ItemsData := preload("res://data/items.gd")
const EnchantDefs := preload("res://data/enchants.gd")
const GatherDefs := preload("res://data/gather.gd")

const REAGENTS := ["glimmerdust", "emberglass", "dewthread"]

var _game: Node
var _panel: Panel
var _sel_item = null
var _reagent_lbl: Label
var _gear_rows: VBoxContainer
var _charm_col: VBoxContainer
# Painted charm icons, drop-in by convention: assets/ui/icons/charm_<id>.png.
# Preloaded in _ready (never load() inside _draw — white-rect gotcha); missing
# icons fall back to the tier swatch, so the art can land incrementally.
var _icon_cache := {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 95
	_game = get_tree().root.get_node_or_null("Game")
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.55)
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
	_panel.offset_left = -370
	_panel.offset_top = -300
	_panel.offset_right = 370
	_panel.offset_bottom = 300
	add_child(_panel)
	var title := Label.new()
	title.text = "The Charm Table"
	WyrdUi.style_title(title)
	title.position = Vector2(54, 36)
	_panel.add_child(title)
	var hint := Label.new()
	hint.text = "Esc — close"
	WyrdUi.style_dim(hint)
	hint.anchor_left = 1.0
	hint.anchor_right = 1.0
	hint.offset_left = -130
	hint.offset_top = 38
	_panel.add_child(hint)
	_reagent_lbl = Label.new()
	WyrdUi.style_body(_reagent_lbl, 14)
	_reagent_lbl.position = Vector2(56, 72)
	_reagent_lbl.custom_minimum_size = Vector2(640, 0)
	_panel.add_child(_reagent_lbl)
	var body := HBoxContainer.new()
	body.anchor_right = 1.0
	body.anchor_bottom = 1.0
	body.offset_left = 56
	body.offset_top = 104
	body.offset_right = -56
	body.offset_bottom = -44
	body.add_theme_constant_override("separation", 16)
	_panel.add_child(body)
	# Left — gear.
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 0.42
	left.add_theme_constant_override("separation", 6)
	body.add_child(left)
	var lsec := Label.new()
	lsec.text = "Your gear"
	WyrdUi.style_section(lsec)
	left.add_child(lsec)
	var lscroll := ScrollContainer.new()
	lscroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lscroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left.add_child(lscroll)
	_gear_rows = VBoxContainer.new()
	_gear_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_gear_rows.add_theme_constant_override("separation", 6)
	lscroll.add_child(_gear_rows)
	# Right — charms.
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.size_flags_stretch_ratio = 0.58
	right.add_theme_constant_override("separation", 6)
	body.add_child(right)
	var rscroll := ScrollContainer.new()
	rscroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rscroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right.add_child(rscroll)
	_charm_col = VBoxContainer.new()
	_charm_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_charm_col.add_theme_constant_override("separation", 6)
	rscroll.add_child(_charm_col)
	# Preload any painted charm icons that exist (white-rect gotcha: in _ready).
	for eid in EnchantDefs.ENCHANT_ORDER:
		var p := "res://assets/ui/icons/charm_%s.png" % String(eid)
		if ResourceLoader.exists(p):
			_icon_cache[String(eid)] = load(p)
	get_node("/root/Game").modal_opened()
	_select_default()
	_render()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_close()

func _close() -> void:
	get_node("/root/Game").modal_closed()
	queue_free()

# Pick the first equipped piece that can hold a charm.
func _select_default() -> void:
	_sel_item = null
	if _game == null or _game.equipment == null:
		return
	for slot in Equipment.SLOT_ORDER:
		var it = _game.equipment.get_slot(slot)
		if it != null and ItemsData.enchant_slots(String(it.get("kind_id", ""))) > 0:
			_sel_item = it
			return

func _render() -> void:
	if _game == null:
		return
	# Reagent header.
	var parts: Array = []
	for r in REAGENTS:
		parts.append("%s %s ×%d" % [GatherDefs.material_icon(r),
			GatherDefs.material_name(r), _game.material_count(r)])
	_reagent_lbl.text = "Reagents:    " + "      ".join(parts)
	# Gear list.
	for c in _gear_rows.get_children():
		c.queue_free()
	var any := false
	for slot in Equipment.SLOT_ORDER:
		var it = _game.equipment.get_slot(slot)
		if it == null:
			continue
		var cap: int = ItemsData.enchant_slots(String(it.get("kind_id", "")))
		if cap <= 0:
			continue
		any = true
		var used: int = (it.get("enchants", []) as Array).size()
		var sel: bool = it == _sel_item
		var card := _Card.new()
		card.setup(String(it.get("name", it.get("kind_name", ""))),
			"%s · %d/%d charms" % [String(slot).capitalize(), used, cap],
			"", WyrdUi.GOLD if sel else WyrdUi.INK_MID, true, sel)
		var ref = it
		card.pressed.connect(func(): _sel_item = ref; _render())
		_gear_rows.add_child(card)
	if not any:
		var none := Label.new()
		none.text = "No enchantable gear equipped."
		WyrdUi.style_dim(none)
		_gear_rows.add_child(none)
	# Charm column.
	for c in _charm_col.get_children():
		c.queue_free()
	if _sel_item == null:
		var pick := Label.new()
		pick.text = "Equip a bow, some armour, or a ring to begin."
		WyrdUi.style_body(pick, 14)
		_charm_col.add_child(pick)
		return
	var cat := String(_sel_item.get("category", ""))
	var cap2: int = ItemsData.enchant_slots(String(_sel_item.get("kind_id", "")))
	var cur: Array = _sel_item.get("enchants", [])
	var head := Label.new()
	head.text = "%s — %d/%d charm slots" % [String(_sel_item.get("name", "")), cur.size(), cap2]
	WyrdUi.style_section(head)
	_charm_col.add_child(head)
	# Bound charms (click to draw out).
	if cur.is_empty():
		var em := Label.new()
		em.text = "No charms bound yet."
		WyrdUi.style_dim(em)
		_charm_col.add_child(em)
	else:
		for i in cur.size():
			var eid := String(cur[i])
			var bc := _Card.new()
			bc.setup(EnchantDefs.display_name(eid), EnchantDefs.format_enchant(eid),
				"✕ draw out", EnchantDefs.TIER_COLOR.get(EnchantDefs.tier(eid), WyrdUi.SAGE),
				true, false, _icon_cache.get(eid))
			var idx := i
			bc.pressed.connect(func(): _game.unbind_enchant(_sel_item, idx); _render())
			_charm_col.add_child(bc)
	# Bindable charms.
	var sec := Label.new()
	sec.text = "Bindable charms"
	WyrdUi.style_section(sec)
	_charm_col.add_child(sec)
	var listed := false
	for eid_v in _game.known_enchant_ids():
		var eid := String(eid_v)
		if not EnchantDefs.allowed_for(eid, cat):
			continue
		listed = true
		var chk: Dictionary = _game.can_bind_enchant(_sel_item, eid)
		var card := _Card.new()
		card.setup(EnchantDefs.display_name(eid), EnchantDefs.format_enchant(eid),
			_cost_text(eid), EnchantDefs.TIER_COLOR.get(EnchantDefs.tier(eid), WyrdUi.INK_MID),
			bool(chk.ok), false, _icon_cache.get(eid))
		if bool(chk.ok):
			card.pressed.connect(func(): _game.bind_enchant(_sel_item, eid); _render())
		_charm_col.add_child(card)
	if not listed:
		var em2 := Label.new()
		em2.text = "No charms will take on this yet — craft or find more."
		WyrdUi.style_dim(em2)
		_charm_col.add_child(em2)

func _cost_text(id: String) -> String:
	var parts: Array = []
	for mid in EnchantDefs.cost(id):
		parts.append("%s×%d" % [GatherDefs.material_icon(String(mid)),
			int(EnchantDefs.cost(id)[mid])])
	return " ".join(parts)

# ---- one drawn row (gear or charm) ----
class _Card extends Control:
	var _title := ""
	var _sub := ""
	var _tag := ""
	var _accent: Color = Color.WHITE
	var _enabled := true
	var _sel := false
	var _hover := false
	var _tex: Texture2D = null

	signal pressed

	func _init() -> void:
		custom_minimum_size = Vector2(0, 56.0)
		mouse_filter = Control.MOUSE_FILTER_STOP

	func setup(title: String, sub: String, tag: String, accent: Color,
			enabled: bool, selected: bool, tex: Texture2D = null) -> void:
		_title = title
		_sub = sub
		_tag = tag
		_accent = accent
		_enabled = enabled
		_sel = selected
		_tex = tex
		queue_redraw()

	func _gui_input(event: InputEvent) -> void:
		if not _enabled:
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
		WyrdUi.draw_list_row(self, r, _accent)
		if not _enabled:
			draw_rect(r.grow(-1.5), Color(WyrdUi.KIT_PLATE, 0.45))
		elif _hover:
			draw_rect(r.grow(-1.5), Color(1.0, 1.0, 0.90, 0.12))
		if _sel:
			draw_rect(r.grow(-1.5), WyrdUi.GOLD, false, 2.0)
		var font: Font = WyrdUi.font_body()
		if font == null:
			font = get_theme_default_font()
		var ink: Color = WyrdUi.INK if _enabled else Color(0.50, 0.43, 0.34)
		var dim: Color = WyrdUi.INK_MID if _enabled else Color(0.56, 0.49, 0.40)
		# A painted charm icon if one exists (drop-in), else a tier swatch.
		var tx := 30.0
		if _tex != null:
			var iw := 40.0
			var ir := Rect2(Vector2(8.0, (size.y - iw) * 0.5), Vector2(iw, iw))
			WyrdUi.draw_well(self, ir)
			draw_texture_rect(_tex, ir.grow(-3.0), false,
				Color.WHITE if _enabled else Color(1.0, 1.0, 1.0, 0.5))
			tx = ir.end.x + 10.0
		else:
			draw_rect(Rect2(Vector2(10.0, (size.y - 18.0) * 0.5), Vector2(10.0, 18.0)), _accent)
		draw_string(font, Vector2(tx, 22.0), _title, HORIZONTAL_ALIGNMENT_LEFT,
			size.x - tx - 96.0, 16, ink)
		draw_string(font, Vector2(tx, 42.0), _sub, HORIZONTAL_ALIGNMENT_LEFT,
			size.x - tx - 96.0, 12, dim)
		if _tag != "":
			draw_string(font, Vector2(size.x - 94.0, 30.0), _tag,
				HORIZONTAL_ALIGNMENT_RIGHT, 86.0, 13,
				WyrdUi.TERRACOTTA if _tag.begins_with("✕") else WyrdUi.INK_MID)
