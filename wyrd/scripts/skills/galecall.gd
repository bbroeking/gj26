class_name Galecall
extends ProjectileSkill

# Skills-on-items — GRANTED only by the Galebrand weapon enchant
# (data/enchants.gd), never in Game.SKILL_POOL. A wide fan of five quick
# arrows that snare where they land; the wayfinder's answer to a pack. Reuses
# MultiShot's "multi" visual identity (focal centre arrow, dimmed outer fan).

func _init() -> void:
	name = "Galecall"
	cost = 24.0
	base_cd = 4.0
	damage_mult = 1.1
	projectile_count = 5
	spread_deg = 52.0
	skill_type = "multi"
	on_hit_effects = [SkillEffect.snared(1.2, 0.6)]
	recoil_amount = -0.5
	bow_pop_mult = 1.30
	sfx_key = "skill_multi"
