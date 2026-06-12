class_name MercyShot
extends ProjectileSkill

# B5-wave2 — the clean kill: a single deliberate arrow that strikes three
# times as hard when the quarry is already staggering (vigor under 35%).
# The huntsman's finisher; Huntcraft 9.

func _init() -> void:
	name = "MercyShot"
	cost = 28.0
	base_cd = 5.0
	damage_mult = 1.2
	skill_type = "power"
	execute_mult = 3.0
	execute_below = 0.35
	recoil_amount = -0.5
	bow_pop_mult = 1.3
	sfx_key = "skill_power"
