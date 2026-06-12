class_name HuntersMark
extends ProjectileSkill

# B5-wave2 — the hunter names the quarry: a quick gold bolt that does
# little itself but leaves a Mark. The marked thing takes +30% from every
# hit while it holds (combatant.take_damage reads the status). Unlocked
# at Huntcraft 4 — the first thing kills teach you.

func _init() -> void:
	name = "HuntersMark"
	cost = 15.0
	base_cd = 6.0
	damage_mult = 0.5
	skill_type = "mark"
	on_hit_effects = [SkillEffect.marked(8.0)]
	recoil_amount = -0.3
	bow_pop_mult = 1.1
	sfx_key = "fire"
