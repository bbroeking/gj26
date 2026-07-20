extends SceneTree

const EchoAuthority := preload("res://scripts/wayweaver_echo_authority.gd")

var _pass := 0
var _fail := 0


func _initialize() -> void:
	print("--- Wayweaver echo authority check ---")
	_test_rejections_and_exact_once()
	_test_reconnect_high_water()
	print("--- %d passed, %d failed ---" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)


func _context(overrides: Dictionary = {}) -> Dictionary:
	var descriptor := {
		"ok": true, "room_key": "77:2:room-a", "identity": "pierce",
		"effect": {"kind": "pierce", "additional_pierces": 1},
	}
	var context := {
		"session_active": true, "body_peer": 7, "dead": false,
		"wayweaver_equipped": true, "real_basic_release": true,
		"basic_aim": Vector3.FORWARD, "basic_body_peer": 7,
		"basic_room_key": "77:2:room-a", "room_key": "77:2:room-a",
		"consume": func(): return descriptor.duplicate(true),
	}
	for key in overrides:
		context[key] = overrides[key]
	if not overrides.has("basic_body_peer"):
		context.basic_body_peer = context.body_peer
	if not overrides.has("basic_room_key"):
		context.basic_room_key = context.room_key
	return context


func _test_rejections_and_exact_once() -> void:
	var rules := EchoAuthority.new()
	var aim := Vector3.FORWARD
	var spoof := rules.request(7, 8, 999999, aim, _context())
	var legitimate_after_spoof := rules.request(7, 7, 1, aim, _context())
	_check("spoofed sender is rejected without poisoning victim nonce ledger",
		String(spoof.reason) == "sender_mismatch" and bool(legitimate_after_spoof.accepted),
		{"spoof": spoof, "legitimate": legitimate_after_spoof})
	_check("wrong body is rejected", String(rules.request(8, 8, 1, aim,
		_context({"body_peer": 7})).reason) == "body_mismatch")
	_check("stale/zero nonce is rejected", String(rules.request(9, 9, 0, aim, _context({"body_peer": 9})).reason) == "rejected")
	_check("wrong room is rejected host-side", String(rules.request(10, 10, 1, aim,
		_context({"body_peer": 10, "room_key": ""})).reason) == "ineligible_room")
	_check("missing weapon and dead body reject", String(rules.request(11, 11, 1, aim,
		_context({"body_peer": 11, "wayweaver_equipped": false})).reason) == "weapon_missing"
		and String(rules.request(12, 12, 1, aim, _context({"body_peer": 12, "dead": true})).reason) == "dead")
	_check("non-finite and non-unit aim reject", String(rules.request(13, 13, 1,
		Vector3.INF, _context({"body_peer": 13})).reason) == "bad_aim"
		and String(rules.request(14, 14, 1, Vector3(3, 0, 0),
			_context({"body_peer": 14})).reason) == "bad_aim")
	_check("echo aim must match the host-observed Basic release", String(rules.request(16, 16, 1,
		Vector3.RIGHT, _context({"body_peer": 16})).reason) == "aim_mismatch")
	_check("an observed Basic cannot cross bodies or rooms", String(rules.request(17, 17, 1,
		aim, _context({"body_peer": 17, "basic_body_peer": 17,
			"basic_room_key": "77:2:old-room"})).reason) == "basic_context_mismatch")
	var accepted := rules.request(15, 15, 1, aim, _context({"body_peer": 15}))
	var duplicate := rules.request(15, 15, 1, aim, _context({"body_peer": 15}))
	_check("host locks descriptor and returns it exactly once",
		bool(accepted.accepted) and String((accepted.descriptor as Dictionary).identity) == "pierce"
		and bool(duplicate.accepted) and bool(duplicate.duplicate)
		and duplicate.descriptor == accepted.descriptor, {"accepted": accepted, "duplicate": duplicate})


func _test_reconnect_high_water() -> void:
	var rules := EchoAuthority.new()
	var first := rules.request(21, 21, 5, Vector3.FORWARD, _context({"body_peer": 21}))
	rules.rebind_peer(21, 31)
	var replay := rules.request(31, 31, 5, Vector3.FORWARD, _context({"body_peer": 31}))
	var stale := rules.request(31, 31, 4, Vector3.FORWARD, _context({"body_peer": 31}))
	var later := rules.request(31, 31, 6, Vector3.FORWARD, _context({"body_peer": 31}))
	_check("reconnect preserves receipt and high-water without a second echo",
		bool(first.accepted) and bool(replay.duplicate) and String(stale.reason) == "stale_nonce"
		and bool(later.accepted), {"replay": replay, "stale": stale, "later": later})


func _check(name: String, ok: bool, detail = "") -> void:
	if ok:
		_pass += 1
		print("  ✓ %s" % name)
	else:
		_fail += 1
		print("  ✗ %s %s" % [name, str(detail)])
