class_name PiercingBolt
extends ProjectileSkill

# B5 — a heavy line shot that punches through up to 3 enemies. The corridor
# skill: rewards lining a pack up, the counterweight to MultiShot's fan.

func _init() -> void:
	name = "PiercingBolt"
	cost = 22.0
	base_cd = 2.4
	damage_mult = 1.6
	pierce = 3
	skill_type = "power"
	recoil_amount = -0.7
	bow_pop_mult = 1.3
	sfx_key = "skill_power"
