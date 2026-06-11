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

func setup(node: Node3D) -> void:
	_node = node
	if node != null:
		_base_y = node.position.y

func update(delta: float, moving: bool) -> void:
	if _node == null:
		return
	var rate := MOVE_RATE if moving else IDLE_RATE
	var bob := MOVE_BOB if moving else IDLE_BOB
	_phase += delta * rate
	# abs(sin) → a hopping bounce that never dips below the floor.
	_node.position.y = _base_y + absf(sin(_phase)) * bob
