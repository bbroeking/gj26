extends CanvasLayer

# Dormant mastery-choice presentation. Game fires
# `mastery_choice_ready(trade_key, level)` only when future authored data gives
# one Trade multiple perks at the same level. The current 1–23 ladders contain
# automatic single-perk tiers only, so this panel is intentionally unreachable.
# Built in script and kit-styled via WyrdUi — sibling: shrine_choice_modal.gd.
#
# Self-contained modal accounting, mirroring the shrine modal: open() calls
# Game.modal_opened(); a card press calls Game.modal_closed(). No Esc dismiss.

signal perk_chosen(perk_id: String)

const CARD_W := 212.0
const CARD_H := 188.0
const SEP := 18.0
const FocusPointer = preload("res://scripts/ui/components/focus_pointer.gd")

var _level := 0
var _trade_key := ""
var _panel: Panel
var _hbox: HBoxContainer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.62)
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
	add_child(_panel)
	var title := Label.new()
	title.name = "Title"
	title.anchor_left = 0.0
	title.anchor_right = 1.0
	title.offset_top = 22
	title.offset_bottom = 60
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	WyrdUi.style_title(title)
	_panel.add_child(title)
	var sub := Label.new()
	sub.name = "Sub"
	sub.text = "Choose one path — the others stay closed."
	sub.anchor_left = 0.0
	sub.anchor_right = 1.0
	sub.offset_top = 62
	sub.offset_bottom = 88
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	WyrdUi.style_dim(sub)
	_panel.add_child(sub)
	_hbox = HBoxContainer.new()
	_hbox.add_theme_constant_override("separation", int(SEP))
	_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_hbox.anchor_left = 0.0
	_hbox.anchor_right = 1.0
	_hbox.offset_top = 102
	_hbox.offset_bottom = -28
	_hbox.offset_left = 24
	_hbox.offset_right = -24
	_panel.add_child(_hbox)
	var focus_pointer := FocusPointer.new()
	focus_pointer.name = "MenuFocusPointer"
	add_child(focus_pointer)

# Build the cards for one Trade's multi-perk tier and pause the world. The
# optional key keeps the panel compatible with the current level-only signal;
# when omitted, infer the canonical pending Trade from Game.
func open(level: int, trade_key: String = "") -> void:
	_level = level
	var game := get_node("/root/Game")
	_trade_key = trade_key
	if _trade_key == "":
		for pending in game.pending_mastery_levels():
			if int(pending.get("level", 0)) == level:
				_trade_key = String(pending.get("trade", ""))
				break
	if _trade_key == "":
		queue_free()
		return
	var perks: Array = game.perks_at_level(level, _trade_key)
	# Single-perk levels auto-grant through perk_active; they are not choices and
	# must never strand the player in a modal with an unselectable card.
	if perks.size() < 2:
		queue_free()
		return
	var title: Label = _panel.get_node("Title")
	var trade_name := String(game.TRADE_NAMES.get(_trade_key, _trade_key))
	title.text = "%s mastery — Level %d" % [trade_name, level]
	for c in _hbox.get_children():
		c.queue_free()
	for perk in perks:
		_hbox.add_child(_make_card(perk, String(game.PERK_CATEGORY.get(String(perk.id), ""))))
	if _hbox.get_child_count() > 0:
		(_hbox.get_child(0) as Button).grab_focus.call_deferred()
	# Size the panel to the card row.
	var n: int = perks.size()
	var w: float = float(n) * CARD_W + float(maxi(0, n - 1)) * SEP + 56.0
	w = maxf(w, 360.0)
	var h := 320.0
	_panel.offset_left = -w * 0.5
	_panel.offset_right = w * 0.5
	_panel.offset_top = -h * 0.5
	_panel.offset_bottom = h * 0.5
	game.modal_opened()

func _make_card(perk: Dictionary, category: String) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(CARD_W, CARD_H)
	WyrdUi.style_button(btn)
	btn.pressed.connect(_on_card_pressed.bind(String(perk.id)))
	var vb := VBoxContainer.new()
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_theme_constant_override("separation", 8)
	vb.anchor_right = 1.0
	vb.anchor_bottom = 1.0
	vb.offset_left = 16
	vb.offset_top = 14
	vb.offset_right = -16
	vb.offset_bottom = -14
	btn.add_child(vb)
	var nm := Label.new()
	nm.text = String(perk.name)
	nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	WyrdUi.style_section(nm)
	vb.add_child(nm)
	if category != "":
		var cat := Label.new()
		cat.text = category.to_upper()
		cat.mouse_filter = Control.MOUSE_FILTER_IGNORE
		WyrdUi.style_dim(cat, 14)
		cat.add_theme_color_override("font_color", _cat_color(category))
		vb.add_child(cat)
	var ds := Label.new()
	ds.text = String(perk.desc)
	ds.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ds.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ds.size_flags_vertical = Control.SIZE_EXPAND_FILL
	WyrdUi.style_body(ds, 16)
	vb.add_child(ds)
	return btn

func _cat_color(category: String) -> Color:
	match category:
		"gather": return WyrdUi.SAGE
		"craft": return WyrdUi.GOLD
		"chart": return WyrdUi.TERRACOTTA
		_: return WyrdUi.INK_MID   # combat / fallback

func _on_card_pressed(perk_id: String) -> void:
	var game := get_node("/root/Game")
	if not game.choose_perk(perk_id):
		return
	game.modal_closed()
	perk_chosen.emit(perk_id)
	queue_free()

# No Esc-escape — the player must pick a mastery.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
