class_name WayweaverThreadRules
extends RefCounted

const RoomPresenceScript := preload("res://scripts/room_presence.gd")

# D8 Slice 3 — session-only Wayweaver room reducer.  This class has no node,
# clock, save, inventory, or networking dependency: callers report facts only
# after their normal skill/host authority path has succeeded.

const FRESH := "fresh"
const ARMED := "armed"
const SPENT := "spent"

const SKILL_IDENTITIES := {
	"PowerShot": "pierce",
	"PiercingBolt": "pierce",
	"MercyShot": "pierce",
	"Wyrdvolley": "pierce",
	"MultiShot": "fan",
	"RainOfThorns": "fan",
	"DrivingVolley": "fan",
	"Galecall": "fan",
	"BrambleSnare": "root",
	"Thornburst": "root",
	"HeartwoodWard": "ward",
	"HuntersMark": "mark",
	"Threadstep": "mark",
	"WayfindersMark": "mark",
}

# Returned descriptors are duplicated before crossing the integration seam.
# Echo implementation must honour every field, especially fan no-recursion.
const EFFECTS := {
	"pierce": {"kind": "pierce", "additional_pierces": 1},
	"fan": {
		"kind": "fan", "arrow_count": 2, "angles_degrees": [-12.0, 12.0],
		"damage_multiplier": 0.25, "can_crit": false, "can_pierce": false,
		"can_execute": false, "carry_effects": false, "carry_enchants": false,
		"can_recurse": false,
	},
	"root": {
		"kind": "root", "duration_seconds": 0.75, "first_hit_only": true,
		"respects_boss_immunity": true, "respects_elite_immunity": true,
	},
	"ward": {
		"kind": "ward", "amount": 8, "duration_seconds": 4.0,
		"max_preserving": true,
	},
	"mark": {"kind": "mark", "duration_seconds": 2.0, "after_basic_damage": true},
}

var _states: Dictionary = {} # room key -> {state, identity}; never serialized
var _active_presence: Dictionary = {}


static func identity_for_skill(skill_id: String) -> String:
	return String(SKILL_IDENTITIES.get(skill_id, ""))


static func effect_for_identity(identity: String) -> Dictionary:
	var effect = EFFECTS.get(identity, {})
	return (effect as Dictionary).duplicate(true) if effect is Dictionary else {}


static func effect_for_skill(skill_id: String) -> Dictionary:
	return effect_for_identity(identity_for_skill(skill_id))


# World calls this whenever it resolves a position.  Leaving an armed room
# burns it; fresh rooms stay fresh, and a spent room can never be re-armed.
func observe_presence(presence: Dictionary) -> Dictionary:
	var previous := _active_presence
	if not previous.is_empty() and not RoomPresenceScript.same_room(previous, presence):
		_burn_key(RoomPresenceScript.room_key(previous))
	_active_presence = presence.duplicate(true)
	return state_for(presence)


# Call only after a Focus Skill has really fired/debited.  Threadstep and
# Wayfinder's Mark pass `host_accepted = true` only after their matching ack.
func arm_after_focus(presence: Dictionary, skill_id: String, succeeded: bool,
		wayweaver_equipped: bool, host_accepted: bool = true) -> Dictionary:
	observe_presence(presence)
	var identity := identity_for_skill(skill_id)
	if not succeeded:
		return _result(false, "focus_not_successful", presence)
	if not host_accepted:
		return _result(false, "host_not_accepted", presence)
	if identity == "":
		return _result(false, "unmapped_skill", presence)
	if not wayweaver_equipped:
		return _result(false, "wayweaver_not_equipped", presence)
	var key: String = RoomPresenceScript.room_key(presence)
	if key == "":
		return _result(false, "ineligible_room", presence)
	var current := _state_at(key)
	if String(current.state) != FRESH:
		return _result(false, "room_%s" % String(current.state), presence)
	_states[key] = {"state": ARMED, "identity": identity}
	return _result(true, "armed", presence)


# Call on a real Basic Shot release, not a keypress/buffer/aim preview.  A miss
# still spends the armed thread; the returned descriptor is the one echo the
# caller must apply.  Weapon loss at release burns without producing an echo.
func consume_basic_release(presence: Dictionary, real_basic_release: bool,
		wayweaver_equipped: bool) -> Dictionary:
	observe_presence(presence)
	if not real_basic_release:
		return _result(false, "not_real_basic_release", presence)
	var key: String = RoomPresenceScript.room_key(presence)
	if key == "":
		return _result(false, "ineligible_room", presence)
	var current := _state_at(key)
	if String(current.state) != ARMED:
		return _result(false, "room_%s" % String(current.state), presence)
	_states[key] = {"state": SPENT, "identity": ""}
	if not wayweaver_equipped:
		return _result(false, "wayweaver_not_equipped", presence)
	var result := _result(true, "released", presence)
	result["identity"] = String(current.identity)
	result["effect"] = effect_for_identity(String(current.identity))
	# The host echo ledger binds this descriptor to the host-computed room key;
	# it is never supplied by a client packet.
	result["room_key"] = key
	return result


# Death/reconnect/run replacement are session boundaries.  Any armed room is
# burned first so no pending echo can cross the boundary; facts are then gone.
func invalidate(reason: String = "invalidated") -> Dictionary:
	var burned := 0
	for key in _states.keys():
		if String((_states[key] as Dictionary).get("state", FRESH)) == ARMED:
			_states[key] = {"state": SPENT, "identity": ""}
			burned += 1
	_states.clear()
	_active_presence.clear()
	return {"ok": true, "reason": reason, "burned": burned}


func on_weapon_lost() -> Dictionary:
	var key: String = RoomPresenceScript.room_key(_active_presence)
	var burned := _burn_key(key)
	return {"ok": burned, "reason": "weapon_lost" if burned else "nothing_armed"}


func state_for(presence: Dictionary) -> Dictionary:
	var key: String = RoomPresenceScript.room_key(presence)
	return _state_at(key).duplicate(true) if key != "" else {"state": FRESH, "identity": ""}


func _state_at(key: String) -> Dictionary:
	if key == "" or not _states.has(key):
		return {"state": FRESH, "identity": ""}
	return _states[key] as Dictionary


func _burn_key(key: String) -> bool:
	if key == "":
		return false
	var current := _state_at(key)
	if String(current.state) != ARMED:
		return false
	_states[key] = {"state": SPENT, "identity": ""}
	return true


func _result(ok: bool, reason: String, presence: Dictionary) -> Dictionary:
	var state := state_for(presence)
	return {"ok": ok, "reason": reason, "state": String(state.state),
		"identity": String(state.identity)}
