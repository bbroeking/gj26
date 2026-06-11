class_name PowerShot
extends ProjectileSkill

# Spec 32b — slot 2. Single arrow, 2.5× damage, visually larger projectile,
# applies Burn on hit (3s / 0.5s ticks / 1 dpt = 6 total ≈ 40% of one
# PowerShot hit per spec 31).

func _init() -> void:
	name = "PowerShot"
	cost = 20.0
	base_cd = 1.5
	damage_mult = 2.5
	skill_type = "power"
	on_hit_effects = [SkillEffect.burn(3.0, 1, 0.5)]
	recoil_amount = -0.6
	bow_pop_mult = 1.35
	sfx_key = "skill_power"
