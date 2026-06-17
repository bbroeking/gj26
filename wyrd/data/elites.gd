class_name Elites
extends RefCounted

# Spec 32 — elite modifier catalogue + factory. Mirrors the data/affixes.gd
# pure-data pattern; consumed by `combatant.gd::apply_elite(modifier_key)`.
# Per-modifier dispatch keys (`on_death`, `on_attack`, `cc_immune_window`,
# `move_mult`, `attack_speed_mult`) drive the combatant's runtime branches
# so modifiers stay data, not code branches.

const MODIFIERS := {
	# brambled — bleeder; thorn-green body, bright-lime ring
	"brambled": {
		"name": "Brambled",
		"hp_mult": 1.25,
		"scale_mult": 1.25,
		"tint": Color(0.55, 0.90, 0.40),
		"ring_color": Color(0.40, 0.85, 0.25),
		"label_color": Color(0.55, 0.95, 0.35),
		"on_death": "bleed_nova",
	},
	# swift — fast; ice-blue body, deep-sky ring
	"swift": {
		"name": "Swift",
		"hp_mult": 1.0,
		"scale_mult": 1.15,
		"tint": Color(0.50, 0.80, 1.0),
		"ring_color": Color(0.30, 0.65, 1.0),
		"label_color": Color(0.55, 0.85, 1.0),
		"move_mult": 1.5,
		"attack_speed_mult": 1.2,
	},
	# sunlit — fire; ember-gold body, hot-orange ring
	"sunlit": {
		"name": "Sunlit",
		"hp_mult": 1.5,
		"scale_mult": 1.25,
		"tint": Color(1.0, 0.70, 0.20),
		"ring_color": Color(1.0, 0.50, 0.10),
		"label_color": Color(1.0, 0.75, 0.20),
		"on_attack": "burn_pulse",
	},
	# briarbound — armored; deep-violet body, vivid-purple ring
	"briarbound": {
		"name": "Briarbound",
		"hp_mult": 1.3,
		"scale_mult": 1.15,
		"tint": Color(0.85, 0.40, 0.90),
		"ring_color": Color(0.70, 0.25, 0.80),
		"label_color": Color(0.90, 0.50, 0.95),
		"cc_immune_window": 4.0,
	},
	# thornshelled — armored tank; olive-green body; fires spine_burst on attack
	# combatant.gd must add _trigger_spine_burst + "spine_burst" arm in _elite_on_attack
	"thornshelled": {
		"name": "Thornshelled",
		"hp_mult": 2.0,
		"scale_mult": 1.35,
		"tint": Color(0.60, 0.80, 0.30),
		"ring_color": Color(0.45, 0.70, 0.20),
		"label_color": Color(0.65, 0.90, 0.35),
		"cc_immune_window": 8.0,
		"on_attack": "spine_burst",
		"reward_tier_bonus": 2,
	},
	# blightwalker — AoE-field; toxic teal body; drops blight_pool on death
	# combatant.gd must add _trigger_blight_pool + "blight_pool" arm in _elite_on_death
	"blightwalker": {
		"name": "Blightwalker",
		"hp_mult": 1.2,
		"scale_mult": 1.2,
		"tint": Color(0.35, 0.80, 0.50),
		"ring_color": Color(0.20, 0.65, 0.35),
		"label_color": Color(0.40, 0.90, 0.55),
		"on_death": "blight_pool",
		"reward_tier_bonus": 1,
	},
}

# Deterministic pick — RNG comes from the caller (layout_loader) so a fixed
# dungeon seed always produces the same elite at the same room.
static func pick_random(rng: RandomNumberGenerator) -> String:
	var keys: Array = MODIFIERS.keys()
	return keys[rng.randi_range(0, keys.size() - 1)]
