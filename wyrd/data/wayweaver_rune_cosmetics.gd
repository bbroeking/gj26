class_name WayweaverRuneCosmetics
extends RefCounted

# D8 presentation-only Root Rune profiles.  Root Runes are durable campaign
# records, never inventory materials: choosing one decorates the unique bow
# but does not alter damage, Skills, Affixes, or campaign state.

const ROOT_RUNE_IDS := [
	"green_root_rune",
	"mist_root_rune",
	"fang_root_rune",
	"crown_root_rune",
	"pale_root_rune",
	"ember_root_rune",
]

const PROFILES := {
	"green_root_rune": {
		"label": "Green Root Rune", "color": Color("5fd884"),
		"icon_path": "res://assets/ui/items/green_root_rune.png",
		"particle_color": Color("b7ffd1"), "sfx": "wayweaver_rune_green", "sfx_pitch": 0.94,
	},
	"mist_root_rune": {
		"label": "Mist Root Rune", "color": Color("72c9e8"),
		"icon_path": "res://assets/ui/items/mist_root_rune.png",
		"particle_color": Color("d4f4ff"), "sfx": "wayweaver_rune_mist", "sfx_pitch": 1.13,
	},
	"fang_root_rune": {
		"label": "Fang Root Rune", "color": Color("e3a35c"),
		"icon_path": "res://assets/ui/items/fang_root_rune.png",
		"particle_color": Color("ffe0a6"), "sfx": "wayweaver_rune_fang", "sfx_pitch": 0.84,
	},
	"crown_root_rune": {
		"label": "Crown Root Rune", "color": Color("d9b64f"),
		"icon_path": "res://assets/ui/items/crown_root_rune.png",
		"particle_color": Color("fff0ac"), "sfx": "wayweaver_rune_crown", "sfx_pitch": 1.04,
	},
	"pale_root_rune": {
		"label": "Pale Root Rune", "color": Color("d2c5f0"),
		"icon_path": "res://assets/ui/items/pale_root_rune.png",
		"particle_color": Color("f3edff"), "sfx": "wayweaver_rune_pale", "sfx_pitch": 0.90,
	},
	"ember_root_rune": {
		"label": "Ember Root Rune", "color": Color("ee6c42"),
		"icon_path": "res://assets/ui/items/ember_root_rune.png",
		"particle_color": Color("ffd09a"), "sfx": "wayweaver_rune_ember", "sfx_pitch": 1.10,
	},
}

const THREAD_COLORS := {
	"pierce": Color("6ebee8"),
	"fan": Color("e4bc5a"),
	"root": Color("6dcc76"),
	"ward": Color("ad8ee8"),
	"mark": Color("ef8192"),
}

const FRESH_FALLBACK := Color("55e69d")
const SPENT_COLOR := Color("667674")


static func profile_for(rune_id: String) -> Dictionary:
	var raw: Variant = PROFILES.get(rune_id, {})
	return (raw as Dictionary).duplicate(true) if raw is Dictionary else {}


static func is_valid_rune(rune_id: String) -> bool:
	return PROFILES.has(rune_id)


static func is_owned_rune(rune_id: String, campaign_state: Dictionary) -> bool:
	return is_valid_rune(rune_id) and (campaign_state.get("relics", []) as Array).has(rune_id)


# One authoritative presentation descriptor for the GLB material seam. Fresh
# takes the selected Rune's color, armed takes the gameplay-neutral thread
# identity color, and spent visibly cools to ash. No descriptor has a stat.
static func strand_style(rune_id: String, thread_state: String,
		thread_identity: String = "") -> Dictionary:
	var profile := profile_for(rune_id)
	var rune_color: Color = profile.get("color", FRESH_FALLBACK) as Color
	var particle_color: Color = profile.get("particle_color", rune_color) as Color
	var color := rune_color
	var emission := 1.5
	if thread_state == "armed":
		color = THREAD_COLORS.get(thread_identity, rune_color) as Color
		emission = 2.5
	elif thread_state == "spent":
		color = SPENT_COLOR
		particle_color = SPENT_COLOR
		emission = 0.25
	return {
		"rune_id": rune_id, "thread_state": thread_state,
		"thread_identity": thread_identity, "strand_color": color,
		"strand_emission": emission, "particle_color": particle_color,
		"sfx": String(profile.get("sfx", "wayweaver_rune_green")),
		"sfx_pitch": float(profile.get("sfx_pitch", 1.0)),
	}
