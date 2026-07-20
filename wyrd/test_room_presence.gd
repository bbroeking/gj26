extends SceneTree

const RoomPresenceScript := preload("res://scripts/room_presence.gd")

var _pass := 0
var _fail := 0

func _initialize() -> void:
	print("--- Room presence check ---")
	var rooms := [
		{"id": 4, "x": 0, "y": 0, "w": 5, "h": 4, "role": "combat"},
		{"id": 9, "x": 8, "y": 0, "w": 4, "h": 4, "wayweaver_eligible": false},
	]
	var inside: Dictionary = RoomPresenceScript.resolve(12, 2, Vector3(1.5, 0, 2.5), rooms)
	_check("unique authored room resolves stable identity", inside == {
		"run_epoch": 12, "layer": 2, "room_id": "4", "eligible": true}, str(inside))
	_check("half-open bounds retain final interior tile", bool(RoomPresenceScript.resolve(
		12, 2, Vector3(4.999, 0, 3.999), rooms).eligible))
	_check("corridor resolves ineligible", not bool(RoomPresenceScript.resolve(
		12, 2, Vector3(6.0, 0, 1.0), rooms).eligible))
	_check("explicit ineligible room stays ineligible", not bool(RoomPresenceScript.resolve(
		12, 2, Vector3(9.0, 0, 1.0), rooms).eligible))
	var overlap := rooms.duplicate(true)
	overlap.append({"id": 10, "x": 3, "y": 0, "w": 4, "h": 4})
	_check("overlap fails closed rather than choosing an array order", not bool(
		RoomPresenceScript.resolve(12, 2, Vector3(3.5, 0, 1.0), overlap).eligible))
	_check("room key includes run and layer", RoomPresenceScript.room_key(inside) == "12:2:4")
	print("--- %d passed, %d failed ---" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)

func _check(name: String, ok: bool, detail: String = "") -> void:
	if ok:
		_pass += 1
		print("  ✓ %s" % name)
	else:
		_fail += 1
		print("  ✗ %s %s" % [name, detail])
