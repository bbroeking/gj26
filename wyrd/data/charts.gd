class_name Charts
extends RefCounted

# Wyrd slice — chart templates, Wayfinding affixes, and the bias-roll engine.
# Ported from the shipped three.js prototype (src/ui/charting.js,
# src/data/affixes.js, src/data/affixWeights.js). Player-facing name is
# "Wayfinding"; the code key stays `carto`.
#
# A crafted chart is a Dictionary:
#   { "template_id": String, "tier": int, "scope": String,
#     "affixes": [{ "id": String, "good": bool, "resolvedId": String }],
#     "seed": int, "name": String }
#
# Only affixes whose dungeon-side effects are implemented are rollable —
# the preview UI must never promise something the run can't deliver.

# ---- templates ----
# gen: the parameter block threaded into DungeonGen.generate(seed, cfg).
const TEMPLATES := {
	"snug": {
		"tier": 1, "name": "Snug", "req_carto": 1,
		"desc": "A pocket cellar — no affixes. A quick, clean run.",
		"affix_slots": 0, "ink_slots": 0,   # no affixes → nothing for ink to bias
		"base_cost": {"hedge_ink": 1},
		"scope": "snug",
		"gen": {"grid": 28, "room_min": 6, "room_max": 9,
			"room_count_min": 3, "room_count_max": 7,
			"enemy_density": 0.5},   # tutorial cellar stays gentle
	},
	"tier_1": {
		"tier": 1, "name": "Tier 1 Hollow", "req_carto": 1,
		"desc": "A small, single-floor chart. One affix slot.",
		"affix_slots": 1, "ink_slots": 2,
		"base_cost": {"hedge_ink": 2},
		"scope": "hollow",
		"gen": {"grid": 36, "room_min": 7, "room_max": 11,
			"room_count_min": 4, "room_count_max": 9},
	},
	"hollow": {
		"tier": 2, "name": "Hollow", "req_carto": 10,
		"desc": "Multi-room. Larger, richer chest.",
		"affix_slots": 2, "ink_slots": 3,
		"base_cost": {"hedge_ink": 3},
		"scope": "hollow",
		"gen": {},   # current dungeon_gen defaults (48 grid, rooms 8-14)
	},
	"briar_maze": {
		"tier": 2, "name": "Briar Maze", "req_carto": 15,
		"desc": "Twisted layout — corridors over rooms.",
		"affix_slots": 2, "ink_slots": 3,
		"base_cost": {"hedge_ink": 3},
		"scope": "briar_maze",
		"gen": {"room_min": 6, "room_max": 10, "loop_fraction": 0.55,
			"corridor_ratio_max": 2.4},
	},
	# The endgame: the chart the whole chain builds toward. The Alpha's
	# fang is the only key; the Queen waits at the bottom.
	"summit": {
		"tier": 3, "name": "Chart of the Summit", "req_carto": 16,
		"desc": "The final chart — where the first Hedgemother nests. The fang opens the way.",
		"affix_slots": 0, "ink_slots": 0,
		"base_cost": {"hedge_ink": 4, "refined_ink": 1, "alpha_fang": 1},
		"scope": "crypt",
		"gen": {"boss_kind": "hedgemother_queen", "enemy_density": 1.4,
			"loop_fraction": 0.4},
	},
}
const TEMPLATE_ORDER := ["snug", "tier_1", "hollow", "briar_maze", "summit"]

# ---- affixes (v1 — implemented effects only) ----
# stability: effective = min(95, base_stab + carto_lv * 0.6 + ink_bonus*100).
const AFFIXES := {
	"mineral_vein": {
		"name": "Mineral Vein", "bad_name": "Barren",
		"good_desc": "Ore deposits seam through the dungeon. 3-5 mineable rocks appear inside.",
		"bad_desc": "The ink ran dry. The dungeon comes up barren — no ore.",
		"kind": "bias", "req_carto": 1, "base_stab": 55,
	},
	"bramble_bloom": {
		"name": "Bramble Bloom", "bad_name": "Wilted",
		"good_desc": "The hollow blooms with bramble — 4-6 forage spawns appear inside.",
		"bad_desc": "The vines have withered to nothing. No forage in this run.",
		"kind": "bias", "req_carto": 4, "base_stab": 55,
	},
	"wood_grove": {
		"name": "Wood Grove", "bad_name": "Stripped Grove",
		"good_desc": "A trapper has been chopping. 3-5 log piles wait inside the chart.",
		"bad_desc": "The grove is stripped bare — no logs.",
		"kind": "bias", "req_carto": 7, "base_stab": 55,
	},
	"herbal_patch": {
		"name": "Herbal Patch", "bad_name": "Frostbit Patch",
		"good_desc": "A wild herb patch crowns the chart — 6-9 herb spawns.",
		"bad_desc": "The patch is frost-bit. No herbs this run.",
		"kind": "bias", "req_carto": 14, "base_stab": 55,
	},
	"tyrannical": {
		"name": "Tyrannical", "bad_name": "Erratic",
		"good_desc": "Enemies are fattened up — +50% HP, +30% chart XP on completion.",
		"bad_desc": "Each enemy rolls its own size and vigor. Chaotic.",
		"kind": "modifier", "req_carto": 5, "base_stab": 52,
	},
	"sprinter": {
		"name": "Sprinting Things", "bad_name": "Mired Boots",
		"good_desc": "Everything inside moves a quarter faster — and pays +40 chart xp like any good twin.",
		"bad_desc": "The mud finds YOUR boots — you move 10% slower in this chart.",
		"kind": "modifier", "req_carto": 6, "base_stab": 52,
	},
	"gilded": {
		"name": "Gilded Hollow", "bad_name": "Picked Clean",
		"good_desc": "Two extra treasure chests hide in the rooms.",
		"bad_desc": "Someone got here first — no extra chests.",
		"kind": "bias", "req_carto": 9, "base_stab": 55,
	},
	"bursting": {
		"name": "Bursting", "bad_name": "Volatile",
		"good_desc": "Slain enemies burst, scorching their nearby kin.",
		"bad_desc": "The bursts don't care who's standing close — including you.",
		"kind": "modifier", "req_carto": 12, "base_stab": 50,
	},
	"quiver": {
		"name": "Quiver", "bad_name": "Damp Strings",
		"good_desc": "Your bow sings — +20% fire rate inside this chart.",
		"bad_desc": "The damp gets into the string — 10% slower firing.",
		"kind": "modifier", "req_carto": 8, "base_stab": 54,
	},
	"fog_of_hedge": {
		"name": "Fog of Hedge", "bad_name": "Blinding Fog",
		"good_desc": "A low fog dulls their senses — enemies notice you a third later.",
		"bad_desc": "The fog favors THEM — enemies notice you from further out.",
		"kind": "modifier", "req_carto": 10, "base_stab": 52,
	},
	"frenzied": {
		"name": "Frenzied", "bad_name": "Seething",
		"good_desc": "Everything attacks a quarter faster — bring your footwork.",
		"bad_desc": "The anger settles deep — enemies hit 15% harder.",
		"kind": "modifier", "req_carto": 11, "base_stab": 50,
	},
	"wellspring": {
		"name": "Wellspring", "bad_name": "Barren Veins",
		"good_desc": "Every gather node in the chart yields one extra.",
		"bad_desc": "Thin pickings — gathering takes a third longer.",
		"kind": "bias", "req_carto": 13, "base_stab": 55,
	},
	"echoing": {
		"name": "Echoing Steps", "bad_name": "Hollow Echo",
		"good_desc": "The hollow gives back — Focus regenerates half again as fast.",
		"bad_desc": "The hollow drinks it in — Focus regen drops by a quarter.",
		"kind": "modifier", "req_carto": 15, "base_stab": 52,
	},
	"marked_quarry": {
		"name": "Marked Quarry", "bad_name": "Skittish Prey",
		"good_desc": "Elites here carry trophies twice as often.",
		"bad_desc": "The fiercer things hide their prizes — half the trophy odds.",
		"kind": "modifier", "req_carto": 16, "base_stab": 50,
	},
	"festival_pace": {
		"name": "Festival Pace", "bad_name": "Lockstep",
		"good_desc": "+50% enemy density inside. The hollow is thick with them.",
		"bad_desc": "The halls fall quiet — fewer enemies, thinner haul.",
		"kind": "pacing", "req_carto": 7, "base_stab": 52,
	},
	# Boss dens never roll at random — they are inked in deliberately by
	# slotting the matching trophy at the table (the chart chain: elites →
	# Hedgemother → Boar → Wolf → the Summit). Stability still rolls.
	"hedgemother_den": {
		"name": "Hedgemother's Den", "bad_name": "Empty Throne",
		"good_desc": "The deepest room becomes her thorn-arena.",
		"bad_desc": "You find her empty bramble-throne. Whatever lived here has gone.",
		"kind": "boss", "req_carto": 8, "base_stab": 50,
		"trophy": "thorn_essence",
	},
	"burrow_boar_den": {
		"name": "Burrow Boar's Wallow", "bad_name": "Empty Wallow",
		"good_desc": "A great Burrow Boar takes the deepest room. Heavier, meaner, slower.",
		"bad_desc": "The wallow is fresh-dug but empty. Whatever rooted here has moved on.",
		"kind": "boss", "req_carto": 12, "base_stab": 48,
		"trophy": "tusker_tusk",
	},
	"wolf_alpha_den": {
		"name": "Wolf Alpha's Roost", "bad_name": "Cold Trail",
		"good_desc": "A pack-leader wolf haunts the deepest room. Fast, sharp, glow-eyed.",
		"bad_desc": "Only fur and a cold trail — the pack moved on hours ago.",
		"kind": "boss", "req_carto": 14, "base_stab": 46,
		"trophy": "wightpelt",
	},
}

# Trophy material → the den it inks in.
const TROPHY_TO_AFFIX := {
	"thorn_essence": "hedgemother_den",
	"tusker_tusk": "burrow_boar_den",
	"wightpelt": "wolf_alpha_den",
}

# Base roll weights (relative likelihood per slot, before ink bias).
# Random-roll weights. Boss dens are absent on purpose — a boss is a
# deliberate inscription (trophy slot), never a surprise roll.
const BASE_WEIGHTS := {
	"mineral_vein": 10,
	"bramble_bloom": 8,
	"wood_grove": 8,
	"herbal_patch": 8,
	"tyrannical": 8,
	"festival_pace": 7,
	"sprinter": 7,
	"gilded": 6,
	"bursting": 6,
	"quiver": 7,
	"fog_of_hedge": 6,
	"frenzied": 6,
	"wellspring": 7,
	"echoing": 6,
	"marked_quarry": 5,
}

# ---- inks ----
# bias: affix_id -> weight multiplier. "_stability" -> flat good-twin bonus
# (fraction; 0.10 = +10 percentage points), capped at +0.5 total.
const INKS := {
	"hedge_ink": {
		"name": "Hedge Ink", "icon": "●",
		"desc": "Pulls the roll toward green affixes — blooms, groves, patches.",
		"bias": {"bramble_bloom": 2.0, "herbal_patch": 2.0, "wood_grove": 2.0},
	},
	"stoneground_ink": {
		"name": "Stoneground Ink", "icon": "◆",
		"desc": "Heavy and gritty — pulls hard toward the mineral seams.",
		"bias": {"mineral_vein": 2.5},
	},
	"refined_ink": {
		"name": "Refined Ink", "icon": "✦",
		"desc": "Steadies the hand — +10% toward each affix's good twin.",
		"bias": {"_stability": 0.10},
	},
	# Spec 43 — discovered inks. Ash leans green-and-fast; chalkwash
	# leans toward the deep wave-2 affixes.
	"ash_ink": {
		"name": "Ash Ink", "icon": "◉",
		"desc": "Char and leaf — pulls hard toward groves and quick feet.",
		"bias": {"wood_grove": 2.5, "sprinter": 1.8},
	},
	"chalkwash_ink": {
		"name": "Chalkwash Ink", "icon": "○",
		"desc": "Pale and quiet — wellsprings, echoes, and quarry marks lean closer.",
		"bias": {"wellspring": 1.8, "echoing": 1.8, "marked_quarry": 1.8},
	},
}

# ---- the bias-roll engine ----

# Weight table for (tier, slotted inks, carto level), normalized to percent.
static func compute_weights(_tier: int, ink_ids: Array, carto_lv: int) -> Dictionary:
	var weights := {}
	for id in BASE_WEIGHTS:
		var aff: Dictionary = AFFIXES.get(id, {})
		if aff.is_empty():
			continue
		if int(aff.req_carto) > carto_lv:
			continue
		weights[id] = float(BASE_WEIGHTS[id])
	for ink_id in ink_ids:
		var ink: Dictionary = INKS.get(ink_id, {})
		var bias: Dictionary = ink.get("bias", {})
		for affix_id in bias:
			if String(affix_id).begins_with("_"):
				continue
			if weights.has(affix_id):
				weights[affix_id] *= float(bias[affix_id])
	var total := 0.0
	for id in weights:
		total += weights[id]
	if total <= 0.0:
		return {}
	var out := {}
	for id in weights:
		out[id] = weights[id] / total * 100.0
	return out

# Flat stability bonus from slotted inks (capped +0.5 = +50 points).
static func ink_stability_bonus(ink_ids: Array) -> float:
	var bonus := 0.0
	for ink_id in ink_ids:
		var ink: Dictionary = INKS.get(ink_id, {})
		bonus += float(ink.get("bias", {}).get("_stability", 0.0))
	return minf(0.5, bonus)

static func effective_stability(affix_id: String, carto_lv: int, ink_bonus: float) -> int:
	var aff: Dictionary = AFFIXES.get(affix_id, {})
	var base := float(aff.get("base_stab", 50))
	return mini(95, roundi(base + carto_lv * 0.6 + ink_bonus * 100.0))

# Roll N distinct affixes from a weight table.
static func roll_affix_ids(weights: Dictionary, count: int, rng: RandomNumberGenerator) -> Array:
	var picks: Array = []
	var remaining := weights.duplicate()
	for _i in count:
		var id := _weighted_pick(remaining, rng)
		if id == "":
			break
		picks.append(id)
		remaining.erase(id)
	return picks

static func _weighted_pick(weights: Dictionary, rng: RandomNumberGenerator) -> String:
	var total := 0.0
	for id in weights:
		total += float(weights[id])
	if total <= 0.0:
		return ""
	var r := rng.randf() * total
	var last := ""
	for id in weights:
		r -= float(weights[id])
		last = String(id)
		if r <= 0.0:
			return last
	return last

# Inscribe: spend nothing here (caller spends), just roll the chart dict.
# A slotted trophy GUARANTEES its boss-den affix in one slot (the gamble
# that remains is the stability roll — the den can still come up empty).
static func inscribe(template_id: String, ink_ids: Array, carto_lv: int,
		trophy_id: String = "") -> Dictionary:
	var t: Dictionary = TEMPLATES.get(template_id, {})
	if t.is_empty():
		return {}
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var resolved: Array = []
	var slots := int(t.affix_slots)
	if slots > 0:
		var picks: Array = []
		if trophy_id != "" and TROPHY_TO_AFFIX.has(trophy_id):
			picks.append(String(TROPHY_TO_AFFIX[trophy_id]))
		var weights := compute_weights(int(t.tier), ink_ids, carto_lv)
		picks.append_array(roll_affix_ids(weights, slots - picks.size(), rng))
		var stab_bonus := ink_stability_bonus(ink_ids)
		for affix_id in picks:
			var stab := effective_stability(affix_id, carto_lv, stab_bonus)
			var good := rng.randf() * 100.0 < stab
			resolved.append({
				"id": affix_id,
				"good": good,
				"resolvedId": affix_id if good else affix_id + "__bad",
			})
	return {
		"template_id": template_id,
		"tier": int(t.tier),
		"scope": String(t.scope),
		"name": String(t.name),
		"affixes": resolved,
		"seed": int(rng.randi()) & 0x7FFFFFFF,
	}

# Total cost for a craft: template base cost + one of each slotted ink +
# the slotted trophy. A template with no affix slots has nothing for ink
# (or a trophy) to bias — never charge for them, whatever the caller passed.
static func craft_cost(template_id: String, ink_ids: Array,
		trophy_id: String = "") -> Dictionary:
	var t: Dictionary = TEMPLATES.get(template_id, {})
	var cost: Dictionary = (t.get("base_cost", {}) as Dictionary).duplicate()
	if int(t.get("affix_slots", 0)) <= 0:
		return cost
	for ink_id in ink_ids:
		cost[ink_id] = int(cost.get(ink_id, 0)) + 1
	if trophy_id != "" and TROPHY_TO_AFFIX.has(trophy_id):
		cost[trophy_id] = int(cost.get(trophy_id, 0)) + 1
	return cost

# Shipped completion formula: tier × 75 + good × 40 + bad × 10.
# Tyrannical's good twin pays its "+30% chart XP" promise here — the slice
# has no per-kill XP, so completion is the only honest channel.
static func completion_xp(chart: Dictionary) -> int:
	var tier := int(chart.get("tier", 1))
	var good := 0
	var bad := 0
	var tyrannical := false
	for a in chart.get("affixes", []):
		if bool(a.get("good", false)):
			good += 1
			if String(a.get("id", "")) == "tyrannical":
				tyrannical = true
		else:
			bad += 1
	var xp := tier * 75 + good * 40 + bad * 10
	if tyrannical:
		xp = roundi(xp * 1.3)
	return xp

# Display line for a chart ("Tier 1 Hollow — Mineral Vein, Barren").
static func chart_label(chart: Dictionary) -> String:
	var parts: Array = []
	for a in chart.get("affixes", []):
		var aff: Dictionary = AFFIXES.get(String(a.get("id", "")), {})
		if aff.is_empty():
			continue
		parts.append(String(aff.name) if bool(a.get("good", false)) else String(aff.bad_name))
	var label := String(chart.get("name", "Chart"))
	if not parts.is_empty():
		label += " — " + ", ".join(parts)
	return label
