class_name RoomPresence
extends RefCounted

# D8 Slice 3 — World-owned room identity, deliberately separate from the
# Wayweaver reducer.  Layout rooms are authored grid rectangles whose world
# tiles occupy [x, x + w) × [y, y + h).  A point in a corridor has no match;
# a point in overlapping bounds is ambiguous and therefore fails closed.

static func resolve(run_epoch: int, layer: int, world_position: Vector3,
		room_bounds: Array) -> Dictionary:
	var matches: Array = []
	for raw in room_bounds:
		if not raw is Dictionary:
			continue
		var room := raw as Dictionary
		if _contains(room, world_position):
			matches.append(room)
	if matches.size() != 1:
		return _ineligible(run_epoch, layer)
	var match := matches[0] as Dictionary
	var room_id := _room_id(match)
	if room_id == "":
		return _ineligible(run_epoch, layer)
	return {
		"run_epoch": run_epoch,
		"layer": layer,
		"room_id": room_id,
		"eligible": _eligible(match),
	}


static func same_room(a: Dictionary, b: Dictionary) -> bool:
	return int(a.get("run_epoch", -1)) == int(b.get("run_epoch", -2)) \
		and int(a.get("layer", -1)) == int(b.get("layer", -2)) \
		and String(a.get("room_id", "")) == String(b.get("room_id", "")) \
		and String(a.get("room_id", "")) != ""


static func room_key(presence: Dictionary) -> String:
	if not bool(presence.get("eligible", false)):
		return ""
	var room_id := String(presence.get("room_id", ""))
	if room_id == "":
		return ""
	return "%d:%d:%s" % [int(presence.get("run_epoch", -1)),
		int(presence.get("layer", -1)), room_id]


static func _ineligible(run_epoch: int, layer: int) -> Dictionary:
	return {"run_epoch": run_epoch, "layer": layer, "room_id": "", "eligible": false}


static func _contains(room: Dictionary, world_position: Vector3) -> bool:
	if not room.has("x") or not room.has("y") or not room.has("w") or not room.has("h"):
		return false
	var width := int(room.get("w", 0))
	var height := int(room.get("h", 0))
	if width <= 0 or height <= 0:
		return false
	var x := float(room.get("x", 0))
	var y := float(room.get("y", 0))
	return world_position.x >= x and world_position.x < x + float(width) \
		and world_position.z >= y and world_position.z < y + float(height)


static func _room_id(room: Dictionary) -> String:
	# DungeonGen authors `id`; accepting room_id also makes the resolver useful
	# for authored/static layouts without inventing a position-derived identity.
	if room.has("id"):
		return str(room.get("id"))
	if room.has("room_id"):
		return str(room.get("room_id"))
	return ""


static func _eligible(room: Dictionary) -> bool:
	# An explicit authored decision wins.  Otherwise any unique room bound is
	# eligible; corridors are absent from `rooms` and consequently fail closed.
	if room.has("wayweaver_eligible"):
		return bool(room.get("wayweaver_eligible"))
	if room.has("eligible"):
		return bool(room.get("eligible"))
	return String(room.get("role", "")) != "corridor"
