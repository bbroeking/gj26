class_name Threadstep
extends Skill

# Threadstep is intentionally a marker Skill.  PlayerController dispatches it
# over the dedicated request/ack path; `fire` must never be reached through the
# generic Focus-spending Skill path.

func _init() -> void:
	name = "Threadstep"
	cost = 20.0
	base_cd = 8.0


func fire(player: Node) -> void:
	if player != null and player.has_method("try_threadstep"):
		player.try_threadstep(player.aim_dir())
