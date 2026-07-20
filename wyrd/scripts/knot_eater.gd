class_name KnotEater
extends "res://scripts/boss.gd"

var _ritual_pacified := false

# The final ritual is never a kill. Combatant's central floor catches direct,
# status, crit, and replicated damage before `died` can become a settlement.
func _damage_floor() -> int:
	return 1 if not dead else 0


func _on_damage_floor_reached() -> void:
	set_meta("knot_eater_state", "bound")


func set_ritual_pacified(value: bool) -> void:
	_ritual_pacified = value
	if not value:
		return
	velocity = Vector3.ZERO
	_telegraphing = false
	_charging = false
	_lunges_left = 0
	if _telegraph_node != null:
		_telegraph_node.queue_free()
		_telegraph_node = null


func _tick_ai(delta: float) -> void:
	if _ritual_pacified:
		velocity = Vector3.ZERO
		return
	super(delta)


func reset_fight() -> void:
	_ritual_pacified = false
	super()
