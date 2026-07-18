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
	# Code-drawn lantern icon — matches the panel's "light a fire" theme.
	var crest := _LanternIcon.new()
	crest.position = Vector2(10, 10)
	crest.custom_minimum_size = Vector2(38, 68)
	crest.size = Vector2(38, 68)
	_panel.add_child(crest)
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


# ---- code-drawn lantern icon ----
# A small oil lantern: hanging hook, glass body with warm amber panes,
# a candle flame inside, and a cast-iron base. Pure vector — no texture
# loads inside _draw (white-rect gotcha). Sized for ~38×68 px.
class _LanternIcon extends Control:
	func _draw() -> void:
		var w := size.x
		var h := size.y
		var cx := w * 0.5

		# hanging hook (curved arc at the top)
		var hook_c := Vector2(cx, h * 0.07)
		draw_arc(hook_c, h * 0.065, -PI * 0.9, PI * 0.1, 18,
			WyrdUi.KIT_EDGE, 2.0, true)
		# the chain link that drops from the hook to the cap
		draw_line(Vector2(cx, h * 0.13), Vector2(cx, h * 0.19),
			WyrdUi.KIT_EDGE, 2.0, true)

		# lantern cap (flat iron top)
		var cap_y := h * 0.19
		var cap_w := w * 0.70
		var cap := Rect2(Vector2(cx - cap_w * 0.5, cap_y), Vector2(cap_w, h * 0.055))
		draw_rect(cap, Color(0.30, 0.22, 0.15))
		draw_rect(cap, WyrdUi.KIT_EDGE, false, 1.5)

		# glass body — warm amber panes with a soft glow
		var body_top := cap_y + h * 0.055
		var body_h := h * 0.50
		var body_w := w * 0.78
		var body := Rect2(Vector2(cx - body_w * 0.5, body_top),
			Vector2(body_w, body_h))
		# outer glow so the lantern feels lit
		draw_rect(body.grow(3.0), Color(WyrdUi.GOLD, 0.12))
		draw_rect(body.grow(1.5), Color(WyrdUi.GOLD, 0.10))
		# amber glass fill
		draw_rect(body, Color(0.96, 0.82, 0.44, 0.72))
		# inner flame glow (warm wash behind the flame)
		var glow_c := Vector2(cx, body_top + body_h * 0.55)
		draw_circle(glow_c, body_h * 0.30, Color(1.0, 0.85, 0.30, 0.28))
		draw_circle(glow_c, body_h * 0.18, Color(1.0, 0.90, 0.50, 0.22))

		# iron frame stripes (vertical mullions dividing the panes)
		var stripe_x_left := cx - body_w * 0.25
		var stripe_x_right := cx + body_w * 0.25
		draw_line(Vector2(stripe_x_left, body_top),
			Vector2(stripe_x_left, body_top + body_h),
			Color(WyrdUi.KIT_EDGE, 0.50), 1.5, true)
		draw_line(Vector2(stripe_x_right, body_top),
			Vector2(stripe_x_right, body_top + body_h),
			Color(WyrdUi.KIT_EDGE, 0.50), 1.5, true)
		# horizontal midbar
		draw_line(Vector2(body.position.x, body_top + body_h * 0.5),
			Vector2(body.end.x, body_top + body_h * 0.5),
			Color(WyrdUi.KIT_EDGE, 0.40), 1.2, true)
		# glass border
		draw_rect(body, WyrdUi.KIT_EDGE, false, 2.0)

		# candle flame — a teardrop polygon
		var flame_base := Vector2(cx, body_top + body_h * 0.72)
		var flame_tip := Vector2(cx, body_top + body_h * 0.30)
		var flame_pts := PackedVector2Array([
			flame_base,
			flame_base + Vector2(-w * 0.15, -body_h * 0.18),
			flame_base + Vector2(-w * 0.09, -body_h * 0.36),
			flame_tip + Vector2(0, body_h * 0.06),
			flame_tip,
			flame_base + Vector2(w * 0.09, -body_h * 0.36),
			flame_base + Vector2(w * 0.15, -body_h * 0.18),
		])
		draw_colored_polygon(flame_pts, Color(1.0, 0.82, 0.20, 0.92))
		# inner bright core
		var core_pts := PackedVector2Array([
			flame_base + Vector2(0, -body_h * 0.05),
			flame_base + Vector2(-w * 0.06, -body_h * 0.20),
			flame_tip + Vector2(0, body_h * 0.12),
			flame_base + Vector2(w * 0.06, -body_h * 0.20),
		])
		draw_colored_polygon(core_pts, Color(1.0, 0.97, 0.70, 0.85))

		# base plate (wider than the body, slightly rounded in feel)
		var base_y := body_top + body_h
		var base_w := body_w * 1.15
		var base := Rect2(Vector2(cx - base_w * 0.5, base_y), Vector2(base_w, h * 0.055))
		draw_rect(base, Color(0.30, 0.22, 0.15))
		draw_rect(base, WyrdUi.KIT_EDGE, false, 1.5)
		# foot ring below
		var foot_y := base_y + h * 0.055
		var foot_w := base_w * 0.70
		var foot := Rect2(Vector2(cx - foot_w * 0.5, foot_y), Vector2(foot_w, h * 0.038))
		draw_rect(foot, Color(0.26, 0.19, 0.13))
		draw_rect(foot, WyrdUi.KIT_EDGE, false, 1.2)
