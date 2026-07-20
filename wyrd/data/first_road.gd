class_name FirstRoad
extends RefCounted

# The bounded vertical-slice choice. These are authored Charts, not difficulty
# modes: each profile writes three ordinary Affix records into one seeded road.
const PROFILE_ORDER := ["kind", "bold"]
const PROFILES := {
	"kind": {
		"name": "The Kind Road",
		"short": "Frail foes · few elites · lush forage",
		"affixes": ["frail_foes", "quiet_halls", "bramble_bloom"],
	},
	"bold": {
		"name": "The Bold Road",
		"short": "Hardy foes · an elite sign · hidden treasure",
		"affixes": ["tyrannical", "elite_signs", "gilded"],
	},
}


static func profile_id_for_choice(choice: int) -> String:
	return String(PROFILE_ORDER[choice]) if choice >= 0 and choice < PROFILE_ORDER.size() else ""


static func profile(profile_id: String) -> Dictionary:
	return (PROFILES.get(profile_id, {}) as Dictionary).duplicate(true)


static func make_chart(profile_id: String, seed: int = 26072026) -> Dictionary:
	var definition := profile(profile_id)
	if definition.is_empty():
		return {}
	var affixes: Array = []
	for affix_id in definition.affixes:
		affixes.append({"id": String(affix_id), "good": true,
			"resolvedId": String(affix_id)})
	return {
		"template_id": "first_road",
		"recipe_id": "first_road_%s" % profile_id,
		"chart_instance_id": "first-road-%s-%d" % [profile_id, seed],
		"tier": 1,
		"scope": "snug",
		"layer": 1,
		"max_layers": 1,
		"seed": maxi(1, seed),
		"name": String(definition.name),
		"first_road_profile": profile_id,
		"affixes": affixes,
	}
