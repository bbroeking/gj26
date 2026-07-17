extends CanvasLayer

# Spec 46 Phase A — the Lantern: Esc opens it when nothing else is. Host a
# fire, join a friend's by IP, see who's in the yard, leave. Offline it
# pauses like every modal; in a session the world keeps breathing.

var _game: Node
var _panel: Panel
var _status: Label
var _ip_edit: LineEdit
var _roster: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 96
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
	_panel.offset_left = -260
	_panel.offset_top = -220
	_panel.offset_right = 260
	_panel.offset_bottom = 220
	add_child(_panel)
	var title := Label.new()
	title.text = "The Lantern"
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
	# Drawn iron lantern crest left of the title — the Lantern panel's named
	# object as a header ornament, matching the crest treatment on vendor,
	# craft, loadout, and waystone panels.
	var crest := _LanternIcon.new()
	crest.custom_minimum_size = Vector2(40, 52)
	crest.size = Vector2(40, 52)
	crest.position = Vector2(8, 7)
	_panel.add_child(crest)
	# Flourish rule between header and action rows (── ◆ ──).
	var rule := _HeaderRule.new()
	rule.anchor_right = 1.0
	rule.offset_left = 52
	rule.offset_right = -52
	rule.offset_top = 76
	rule.offset_bottom = 84
	_panel.add_child(rule)
	var col := VBoxContainer.new()
	col.anchor_right = 1.0
	col.anchor_bottom = 1.0
	col.offset_left = 56
	col.offset_top = 92
	col.offset_right = -56
	col.offset_bottom = -48
	col.add_theme_constant_override("separation", 10)
	_panel.add_child(col)

	_status = Label.new()
	WyrdUi.style_body(_status, 14)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_status)

	_roster = Label.new()
	WyrdUi.style_body(_roster, 14)
	col.add_child(_roster)

	if NetGame.active:
		if NetGame.is_host():
			_build_address_invite(col)
		var leave := Button.new()
		WyrdUi.style_kit_button(leave)
		leave.text = "Leave the party"
		leave.custom_minimum_size = Vector2(0, 40)
		leave.pressed.connect(func():
			NetGame.leave()
			_close())
		col.add_child(leave)
	else:
		var host := Button.new()
		WyrdUi.style_kit_button(host)
		host.text = "Light a fire — host (port %d)" % NetGame.DEFAULT_PORT
		host.custom_minimum_size = Vector2(0, 40)
		host.pressed.connect(_on_host)
		col.add_child(host)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		_ip_edit = LineEdit.new()
		_ip_edit.placeholder_text = "friend's address (IP or IP:port)"
		_ip_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_ip_edit.custom_minimum_size = Vector2(0, 40)
		row.add_child(_ip_edit)
		var join := Button.new()
		WyrdUi.style_kit_button(join)
		join.text = "Join"
		join.custom_minimum_size = Vector2(96, 40)
		join.pressed.connect(_on_join)
		row.add_child(join)
		col.add_child(row)
		var note := Label.new()
		note.text = "Paste your friend's address (they copy it from their Lantern). Same network or a VPN — Tailscale works well. Friends join while you keep playing."
		WyrdUi.style_dim(note, 12)
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		col.add_child(note)

	NetGame.roster_changed.connect(_refresh)
	NetGame.reconnecting.connect(func(attempt: int, total: int):
		_status.text = "Lost the host — trying the door again (%d/%d)…" \
			% [attempt, total])
	if _game != null:
		_game.modal_opened()
	_refresh()

# Host invite: show the shareable address(es) and a one-click copy. The host
# opens the Lantern (Esc), copies, and sends it to a friend.
func _build_address_invite(col: VBoxContainer) -> void:
	var addrs: Array = NetGame.local_addresses()
	var addr_lbl := Label.new()
	WyrdUi.style_body(addr_lbl, 14)
	addr_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if addrs.is_empty():
		addr_lbl.text = "Share your address with a friend (port %d)." \
			% NetGame.DEFAULT_PORT
		col.add_child(addr_lbl)
		return
	var primary := "%s:%d" % [String(addrs[0]), NetGame.DEFAULT_PORT]
	addr_lbl.text = "Your address:  %s" % primary
	col.add_child(addr_lbl)
	var copy := Button.new()
	WyrdUi.style_kit_button(copy)
	copy.text = "Copy address"
	copy.custom_minimum_size = Vector2(0, 40)
	copy.pressed.connect(func():
		DisplayServer.clipboard_set(primary)
		_status.text = "Copied %s — send it to a friend." % primary)
	col.add_child(copy)
	if addrs.size() > 1:
		var more := Label.new()
		WyrdUi.style_dim(more, 12)
		more.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		more.text = "Other addresses: %s" % ", ".join(addrs.slice(1))
		col.add_child(more)

func _refresh() -> void:
	if NetGame.active:
		_status.text = ("You keep the fire (host). Friends join at your address, port %d."
			% NetGame.DEFAULT_PORT) if NetGame.is_host() \
			else "You're a guest at a friend's fire."
		var names: Array = []
		for id in NetGame.players:
			names.append(NetGame.peer_name(int(id)))
		_roster.text = "In the yard:  %s" % " · ".join(names)
	else:
		_status.text = "Playing alone. Light a fire and friends can step in."
		_roster.text = ""

func _on_host() -> void:
	if NetGame.host():
		if _game != null:
			_game.notify("The fire is lit — reopen the Lantern (Esc) to copy your address for a friend.")
		NetGame.setup_scene(get_tree().current_scene)
		_close()
	else:
		_status.text = "Couldn't open port %d — is another fire burning?" \
			% NetGame.DEFAULT_PORT

func _on_join() -> void:
	var raw := _ip_edit.text.strip_edges()
	if raw == "":
		_status.text = "Type your friend's address first."
		return
	var ip := raw
	var port := NetGame.DEFAULT_PORT
	if ":" in raw:
		var parts := raw.split(":")
		ip = parts[0]
		port = int(parts[1])
	if NetGame.join(ip, port):
		_status.text = "Knocking on %s…" % raw
		# The roster lands when the host answers; the scene re-populates then.
		NetGame.roster_changed.connect(func():
			NetGame.setup_scene(get_tree().current_scene), CONNECT_ONE_SHOT)
		_close()
	else:
		_status.text = "That address doesn't look right."

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_close()

func _close() -> void:
	if _game != null:
		_game.modal_closed()
	queue_free()


# ---- drawn header ornaments ----

# An iron cage lantern with amber glow and candle flame. Pure vector — no
# textures in _draw, so the white-rect-on-load gotcha is impossible here.
class _LanternIcon extends Control:
	func _draw() -> void:
		var cx := size.x * 0.5
		# Hook chain at the very top.
		draw_line(Vector2(cx, 0.0), Vector2(cx, size.y * 0.12),
			WyrdUi.KIT_EDGE, 1.5)
		# Top cap (wider than the cage body, the "crown" of the lantern).
		var cap_y := size.y * 0.14
		var cap_h := size.y * 0.10
		var cap_w := size.x * 0.80
		draw_rect(Rect2(Vector2(cx - cap_w * 0.5, cap_y), Vector2(cap_w, cap_h)),
			WyrdUi.KIT_PLATE.darkened(0.12))
		draw_rect(Rect2(Vector2(cx - cap_w * 0.5, cap_y), Vector2(cap_w, cap_h)),
			WyrdUi.KIT_EDGE, false, 1.5)
		# Cage body — amber glow fill with a brighter inner wash.
		var body_y := cap_y + cap_h
		var body_w := size.x * 0.60
		var body_h := size.y * 0.52
		var bx := cx - body_w * 0.5
		var body := Rect2(Vector2(bx, body_y), Vector2(body_w, body_h))
		draw_rect(body, Color(0.96, 0.84, 0.52, 0.80))
		draw_rect(Rect2(body.position + Vector2(2.0, 2.0),
			body.size - Vector2(4.0, 4.0)), Color(1.0, 0.93, 0.62, 0.50))
		# Three vertical cage struts.
		for i in 3:
			var sx := bx + body_w * float(i + 1) / 4.0
			draw_line(Vector2(sx, body_y), Vector2(sx, body_y + body_h),
				Color(WyrdUi.KIT_EDGE, 0.55), 1.0)
		# Two horizontal cage bands.
		for j in 2:
			var band_y := body_y + body_h * float(j + 1) / 3.0
			draw_line(Vector2(bx, band_y), Vector2(bx + body_w, band_y),
				Color(WyrdUi.KIT_EDGE, 0.55), 1.0)
		# Body ink border + warm gold glow ring outside it.
		draw_rect(body, WyrdUi.KIT_EDGE, false, 1.5)
		draw_rect(body.grow(2.5), Color(WyrdUi.GOLD, 0.25), false, 2.0)
		# Base cap (slightly wider, echoes the crown).
		var base_y := body_y + body_h
		var base_h := size.y * 0.10
		var base_w := size.x * 0.84
		draw_rect(Rect2(Vector2(cx - base_w * 0.5, base_y),
			Vector2(base_w, base_h)), WyrdUi.KIT_PLATE.darkened(0.12))
		draw_rect(Rect2(Vector2(cx - base_w * 0.5, base_y),
			Vector2(base_w, base_h)), WyrdUi.KIT_EDGE, false, 1.5)
		# Candle flame inside the cage: amber base circle + orange tip triangle
		# + warm highlight dot.
		var fc := Vector2(cx, body_y + body_h * 0.60)
		var fr := size.x * 0.10
		draw_circle(fc + Vector2(0.0, fr * 0.3), fr, Color(0.98, 0.70, 0.22))
		var tip := PackedVector2Array([
			fc + Vector2(-fr * 0.60, 0.0),
			fc + Vector2( fr * 0.60, 0.0),
			fc + Vector2(0.0, -fr * 1.80),
		])
		draw_colored_polygon(tip, Color(1.0, 0.58, 0.12))
		draw_circle(fc + Vector2(0.0, -fr * 0.20), fr * 0.40,
			Color(1.0, 0.94, 0.62, 0.85))


# A thin ── ◆ ── flourish rule that divides the header from the action rows.
class _HeaderRule extends Control:
	func _draw() -> void:
		WyrdUi.draw_flourish(self, Vector2(size.x * 0.5, size.y * 0.5),
			size.x - 20.0)
