extends RefCounted

# Spec 21 — procedural rat animation. The rat is a static quadruped GLB
# (Meshy's humanoid auto-rig can't touch it). A whole-mesh hop-bob reads as
# a live scurrying critter and works regardless of the GLB's node structure.
# Owned by the rat's Combatant, ticked from its AI update.

const IDLE_BOB := 0.04        # metres — gentle resting twitch
const MOVE_BOB := 0.14        # metres — scurry hop
const IDLE_RATE := 3.5        # phase rad/sec at rest
const MOVE_RATE := 13.0       # phase rad/sec while moving

var _node: Node3D
var _base_y := 0.0
var _phase := 0.0
# Wyrd — tunable per creature (defaults preserve the rat's scurry). A boar
# lumbers (big slow bob), a wolf lopes, a skitterling skitters.
var _move_bob := MOVE_BOB
var _move_rate := MOVE_RATE
var _idle_bob := IDLE_BOB
var _idle_rate := IDLE_RATE

func setup(node: Node3D, move_bob: float = MOVE_BOB, move_rate: float = MOVE_RATE,
		idle_bob: float = IDLE_BOB, idle_rate: float = IDLE_RATE) -> void:
	_node = node
	_move_bob = move_bob
	_move_rate = move_rate
	_idle_bob = idle_bob
	_idle_rate = idle_rate
	if node != null:
		_base_y = node.position.y

func update(delta: float, moving: bool) -> void:
	if _node == null:
		return
	var rate := _move_rate if moving else _idle_rate
	var bob := _move_bob if moving else _idle_bob
	_phase += delta * rate
	# abs(sin) → a hopping bounce that never dips below the floor.
	_node.position.y = _base_y + absf(sin(_phase)) * bob
