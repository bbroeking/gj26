class_name Wyrdvolley
extends ProjectileSkill

# Skills-on-items — GRANTED only by the Wyrdspark unique enchant
# (data/enchants.gd), never in Game.SKILL_POOL. A heavy burning bolt that
# punches through a whole rank (pierce 4) and sets each one alight. The
# capstone reward for clearing a boss that drops the Wyrdspark charm. Reuses
# PowerShot's "power" ember-brick visual.

func _init() -> void:
	name = "Wyrdvolley"
	cost = 28.0
	base_cd = 5.0
	damage_mult = 2.2
	projectile_count = 1
	pierce = 4
	skill_type = "power"
	on_hit_effects = [SkillEffect.burn(3.0, 2, 0.5)]
	recoil_amount = -0.7
	bow_pop_mult = 1.40
	sfx_key = "skill_power"
