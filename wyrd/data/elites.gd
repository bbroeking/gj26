class_name Elites
extends RefCounted

# Spec 32 — elite modifier catalogue + factory. Mirrors the data/affixes.gd
# pure-data pattern; consumed by `combatant.gd::apply_elite(modifier_key)`.
# Per-modifier dispatch keys (`on_death`, `on_attack`, `cc_immune_window`,
# `move_mult`, `attack_speed_mult`) drive the combatant's runtime branches
# so modifiers stay data, not code branches.

const MODIFIERS := {
	"brambled": {
		"name": "Brambled",
		"hp_mult": 1.25,
		"scale_mult": 1.25,
		"tint": Color(1.0, 0.92, 0.55),
		"on_death": "bleed_nova",
	},
	"swift": {
		"name": "Swift",
		"hp_mult": 1.0,
		"scale_mult": 1.15,
		"tint": Color(1.0, 0.92, 0.55),
		"move_mult": 1.5,
		"attack_speed_mult": 1.2,
	},
	"sunlit": {
		"name": "Sunlit",
		"hp_mult": 1.5,
		"scale_mult": 1.25,
		"tint": Color(1.0, 0.92, 0.55),
		"on_attack": "burn_pulse",
	},
	"briarbound": {
		"name": "Briarbound",
		"hp_mult": 1.3,
		"scale_mult": 1.15,
		"tint": Color(1.0, 0.92, 0.55),
		"cc_immune_window": 4.0,
	},
}

# Deterministic pick — RNG comes from the caller (layout_loader) so a fixed
# dungeon seed always produces the same elite at the same room.
static func pick_random(rng: RandomNumberGenerator) -> String:
	var keys: Array = MODIFIERS.keys()
	return keys[rng.randi_range(0, keys.size() - 1)]
