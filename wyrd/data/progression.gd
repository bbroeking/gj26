extends RefCounted

# Canonical progression contract for ADR 0016.  This file deliberately has no
# dependency on Game or SaveGame: the v2 cutover will make those runtime and
# persistence adapters around these pure functions.

const LEVEL_CAP := 23
const SAVE_VERSION := 2
const TRADE_KEYS := ["wayfinding", "earthcraft", "wildcraft", "huntcraft"]
const TRADE_NAMES := {
	"wayfinding": "Wayfinding",
	"earthcraft": "Earthcraft",
	"wildcraft": "Wildcraft",
	"huntcraft": "Huntcraft",
}

# Compatibility is intentionally one-way.  These keys can be READ from an
# old save during migration, but runtime callers must use TRADE_KEYS.
const LEGACY_TRADE_ALIASES := {
	"carto": "wayfinding",
	"cartography": "wayfinding",
	"earth": "earthcraft",
	"wilds": "wildcraft",
	"hunt": "huntcraft",
}
const LEGACY_DISTINCT_TRADE_KEYS := ["earth", "wilds", "hunt"]

const BASIC_SHOT := "BasicShot"
const GEAR_GRANTED_SKILLS := ["Galecall", "Wyrdvolley"]

# Designed Focus-Skill unlocks. The runtime Skill scripts own combat tuning;
# progression owns only the Trade threshold and presentation. Some late-game
# entries are planned labels without an implemented runtime action yet.
const FOCUS_SKILLS := {
	"PowerShot": {"name": "Power Shot", "trade": "huntcraft", "level": 2,
	},
	"BrambleSnare": {"name": "Bramble Snare", "trade": "huntcraft", "level": 4,
	},
	"MultiShot": {"name": "Multi-Shot", "trade": "huntcraft", "level": 6,
	},
	"HeartwoodWard": {"name": "Heartwood Ward", "trade": "huntcraft", "level": 7,
	},
	"PiercingBolt": {"name": "Piercing Bolt", "trade": "huntcraft", "level": 9,
	},
	"HuntersMark": {"name": "Hunter's Mark", "trade": "huntcraft", "level": 11,
	},
	"RainOfThorns": {"name": "Rain of Thorns", "trade": "huntcraft", "level": 13,
	},
	"Thornburst": {"name": "Thornburst", "trade": "huntcraft", "level": 15,
	},
	"MercyShot": {"name": "Mercy Shot", "trade": "huntcraft", "level": 16,
	},
	"DrivingVolley": {"name": "Driving Volley", "trade": "huntcraft", "level": 18,
	},
	"Threadstep": {"name": "Threadstep", "trade": "huntcraft", "level": 20,
		"focus_cost": 20, "cooldown_sec": 8.0, "max_distance_m": 5.0,
		"cinder_grace_sec": 0.22, "authority": "sender_bound_host_ack",
		"icon_path": "res://assets/ui/icons/skill_threadstep.png",
	},
	"WayfindersMark": {"name": "Wayfinder's Mark", "trade": "huntcraft", "level": 22,
		"focus_cost": 35, "cooldown_sec": 14.0, "range_m": 12.0,
		"reeling_sec": 3.0, "authority": "sender_bound_host_receipt",
		# The named production asset may land independently of this behavior.
		# Do not substitute a glyph: Hunter's Mark already owns that visual read.
		"icon_path": "res://assets/ui/icons/skill_wayfinders_mark.png",
	},
}

const IMPLEMENTED_FOCUS_SKILLS := [
	"PowerShot", "BrambleSnare", "MultiShot", "HeartwoodWard",
	"PiercingBolt", "HuntersMark", "RainOfThorns", "Thornburst", "MercyShot",
	"DrivingVolley", "Threadstep", "WayfindersMark",
]

# Information-only late-Trade features. These declarations are deliberately
# not consumed by drop rolls, elite selection, campaign clues, return logic,
# or boss access. Runtime presentation may read them once the corresponding
# Trade level is reached without gaining permission to mutate RNG.
const INFORMATION_FEATURES := {
	"trophy_sense": {
		"name": "Trophy Sense", "trade": "huntcraft", "level": 19,
		"elite_modifier_readable": true,
		"target_plate_reward_tier_floor": true,
		"seeded_ordinary_trophy_sigil": true,
		"mutates_rng": false, "mutates_drops": false,
		"mutates_campaign_clues": false, "mutates_returns": false,
		"mutates_boss_access": false,
		"icon_path": "res://assets/ui/icons/trophy_sense.png",
	},
	"pack_reader": {
		"name": "Pack Reader", "trade": "huntcraft", "level": 21,
		"elite_manifest_readable": true,
		"first_eligible_elite_readable": true,
		"mutates_rng": false, "mutates_drops": false,
		"mutates_campaign_clues": false, "mutates_returns": false,
		"mutates_boss_access": false,
		"icon_path": "res://assets/ui/icons/pack_reader.png",
	},
}

# One visible unlock per level, per Trade.  IDs are deliberately stable data
# keys rather than UI text, so the Codex/UI may localize labels without moving
# progression gates.  A `skill_id` is present only for a configurable or
# innate combat Skill and is validated below.
const TRADE_UNLOCKS := {
	"wayfinding": [
		{"id": "snug_chart", "label": "Snug Chart"},
		{"id": "maras_marginalia", "label": "Mara's Marginalia"},
		{"id": "practiced_measures", "label": "Practiced Measures"},
		{"id": "bramble_bloom", "label": "Bramble Bloom"},
		{"id": "tyrannical", "label": "Tyrannical"},
		{"id": "sprinting_things", "label": "Sprinting Things"},
		{"id": "wood_grove", "label": "Wood Grove"},
		{"id": "hedgemother_chart", "label": "Hedgemother Boss Chart"},
		{"id": "gilded_hollow", "label": "Gilded Hollow"},
		{"id": "hollow_chart", "label": "Hollow Chart"},
		{"id": "frenzied", "label": "Frenzied"},
		{"id": "sallow_mire_chart", "label": "Sallow Mire"},
		{"id": "wellspring", "label": "Wellspring"},
		{"id": "wolf_alpha_chart", "label": "Wolf Alpha Boss Chart"},
		{"id": "briar_maze", "label": "Briar Maze"},
		{"id": "marked_quarry", "label": "Marked Quarry"},
		{"id": "queen_of_thorns", "label": "Queen of Thorns"},
		{"id": "pale_veins_chart", "label": "Pale Veins Chart"},
		{"id": "skald_archive", "label": "Skald Archive"},
		{"id": "ashen_bough_chart", "label": "Ashen Bough Chart"},
		{"id": "hearth_giant_chart", "label": "Hearth Giant Boss Chart"},
		{"id": "root_below_chart", "label": "Root Below Chart"},
		{"id": "unwritten_chart", "label": "Unwritten Chart"},
	],
	"earthcraft": [
		{"id": "copper_vein", "label": "Copper Vein"},
		{"id": "bogiron_tools", "label": "Bogiron Tools"},
		{"id": "bogiron_vein", "label": "Bogiron Vein"},
		{"id": "glimmerdust_refining", "label": "Glimmerdust Refining"},
		{"id": "bogiron_cap_boots", "label": "Bogiron Cap and Boots"},
		{"id": "bogiron_jerkin", "label": "Bogiron Jerkin"},
		{"id": "palechalk_vein", "label": "Palechalk Vein"},
		{"id": "ringwork", "label": "Copper and Palechalk Ringwork"},
		{"id": "palechalk_longbow", "label": "Palechalk Longbow"},
		{"id": "miners_rhythm", "label": "Miner's Rhythm"},
		{"id": "starsilver_vein", "label": "Starsilver Vein"},
		{"id": "starsilver_tools", "label": "Starsilver Tools"},
		{"id": "rich_seams", "label": "Rich Seams"},
		{"id": "starsilver_longbow", "label": "Starsilver Longbow"},
		{"id": "hedgesteel_vein", "label": "Hedgesteel Vein"},
		{"id": "hedgesteel_armor", "label": "Hedgesteel Armor"},
		{"id": "hedgesteel_warbow", "label": "Hedgesteel Warbow"},
		{"id": "wildgold_vein", "label": "Wildgold Vein"},
		{"id": "wildgold_master_tools", "label": "Wildgold Master Tools"},
		{"id": "wildgold_armor", "label": "Wildgold Armor"},
		{"id": "wildgold_bow", "label": "Wildgold Bow"},
		{"id": "waysteel_core", "label": "Waysteel Core"},
		{"id": "master_forge", "label": "Master Forge"},
	],
	"wildcraft": [
		{"id": "wild_herb", "label": "Wild Herb"},
		{"id": "careful_picking", "label": "Careful Picking"},
		{"id": "bittergrass", "label": "Bittergrass"},
		{"id": "bitter_draught", "label": "Bitter Draught"},
		{"id": "keen_eye", "label": "Keen Eye"},
		{"id": "clearwater_philter", "label": "Clearwater Philter"},
		{"id": "crowsfoot", "label": "Crowsfoot"},
		{"id": "ash_ink", "label": "Ash Ink"},
		{"id": "crowsfoot_cordial", "label": "Crowsfoot Cordial"},
		{"id": "mothmint", "label": "Mothmint"},
		{"id": "hale_draught", "label": "Hale Draught"},
		{"id": "mothmint_mend", "label": "Mothmint Mend"},
		{"id": "foxglove_blue", "label": "Foxglove-Blue"},
		{"id": "mothglow_foxglove_inks", "label": "Mothglow and Foxglove Inks"},
		{"id": "heartsease_draught", "label": "Heartsease Draught"},
		{"id": "stonebreak_tonic", "label": "Stonebreak Tonic"},
		{"id": "second_pour", "label": "Second Pour"},
		{"id": "wellmoss", "label": "Wellmoss"},
		{"id": "wellwater_philter", "label": "Wellwater Philter"},
		{"id": "embersage", "label": "Embersage"},
		{"id": "dawncap", "label": "Dawncap"},
		{"id": "root_sap_cord", "label": "Root-Sap Cord"},
		{"id": "threefold_draught", "label": "Threefold Draught"},
	],
	"huntcraft": [
		{"id": "basic_shot", "label": "Basic Shot", "skill_id": BASIC_SHOT},
		{"id": "power_shot", "label": "Power Shot", "skill_id": "PowerShot"},
		{"id": "weak_point", "label": "Weak-Point Lesson"},
		{"id": "bramble_snare", "label": "Bramble Snare", "skill_id": "BrambleSnare"},
		{"id": "steady_hands", "label": "Steady Hands"},
		{"id": "multi_shot", "label": "Multi-Shot", "skill_id": "MultiShot"},
		{"id": "heartwood_ward", "label": "Heartwood Ward", "skill_id": "HeartwoodWard"},
		{"id": "ward_upgrade", "label": "Ward Upgrade"},
		{"id": "piercing_bolt", "label": "Piercing Bolt", "skill_id": "PiercingBolt"},
		{"id": "hunters_stride", "label": "Hunter's Stride"},
		{"id": "hunters_mark", "label": "Hunter's Mark", "skill_id": "HuntersMark"},
		{"id": "quick_nock", "label": "Quick Nock"},
		{"id": "rain_of_thorns", "label": "Rain of Thorns", "skill_id": "RainOfThorns"},
		{"id": "heavy_draw", "label": "Heavy Draw"},
		{"id": "thornburst", "label": "Thornburst", "skill_id": "Thornburst"},
		{"id": "mercy_shot", "label": "Mercy Shot", "skill_id": "MercyShot"},
		{"id": "even_breath", "label": "Even Breath"},
		{"id": "driving_volley", "label": "Driving Volley", "skill_id": "DrivingVolley"},
		{"id": "trophy_sense", "label": "Trophy Sense"},
		{"id": "threadstep", "label": "Threadstep", "skill_id": "Threadstep"},
		{"id": "pack_reader", "label": "Pack Reader"},
		{"id": "wayfinders_mark", "label": "Wayfinder's Mark", "skill_id": "WayfindersMark"},
		{"id": "master_hunt", "label": "Master Hunt"},
	],
}

# Existing saves have used a few display/spelling forms.  Like Trade aliases,
# these aliases are migration-only and are never emitted by canonicalizers.
const LEGACY_SKILL_ALIASES := {
	"Basic Shot": BASIC_SHOT,
	"basic_shot": BASIC_SHOT,
	"basicshot": BASIC_SHOT,
	"Power Shot": "PowerShot",
	"power_shot": "PowerShot",
	"powershot": "PowerShot",
	"Bramble Snare": "BrambleSnare",
	"bramble_snare": "BrambleSnare",
	"Multi Shot": "MultiShot",
	"multi_shot": "MultiShot",
	"Heartwood Ward": "HeartwoodWard",
	"heartwood_ward": "HeartwoodWard",
	"Piercing Bolt": "PiercingBolt",
	"piercing_bolt": "PiercingBolt",
	"Hunter's Mark": "HuntersMark",
	"Hunters Mark": "HuntersMark",
	"hunters_mark": "HuntersMark",
	"Rain of Thorns": "RainOfThorns",
	"rain_of_thorns": "RainOfThorns",
	"Mercy Shot": "MercyShot",
	"mercy_shot": "MercyShot",
	"Driving Volley": "DrivingVolley",
	"driving_volley": "DrivingVolley",
	"Wayfinder's Mark": "WayfindersMark",
	"wayfinders_mark": "WayfindersMark",
}

static func xp_for_level(level: int) -> int:
	var n := clampi(level, 1, LEVEL_CAP) - 1
	return n * n * 8 + n * 32

static func max_xp() -> int:
	return xp_for_level(LEVEL_CAP)

static func supports_save_version(version: int) -> bool:
	return version >= 0 and version <= SAVE_VERSION

static func level_for_xp(lifetime_xp: int) -> int:
	var xp := clampi(lifetime_xp, 0, max_xp())
	var level := 1
	while level < LEVEL_CAP and xp >= xp_for_level(level + 1):
		level += 1
	return level

static func is_runtime_trade_key(trade_key: String) -> bool:
	return TRADE_KEYS.has(trade_key)

# Use this at any mutation/read boundary in the runtime.  Aliases deliberately
# fail here, so a v2 live state can never acquire an obsolete key by accident.
static func require_runtime_trade_key(trade_key: String) -> String:
	if not is_runtime_trade_key(trade_key):
		push_error("progression: unknown runtime Trade key '%s'" % trade_key)
		return ""
	return trade_key

static func canonical_trade_key_for_migration(raw_key: String) -> String:
	if is_runtime_trade_key(raw_key):
		return raw_key
	return String(LEGACY_TRADE_ALIASES.get(raw_key, ""))

static func fresh_trade_record() -> Dictionary:
	return {"xp": 0, "lv": 1}

static func fresh_trade_state() -> Dictionary:
	var out := {}
	for trade_key in TRADE_KEYS:
		out[trade_key] = fresh_trade_record()
	return out

static func normalize_trade_record(raw_record) -> Dictionary:
	var raw_xp := _record_xp(raw_record)
	var xp := clampi(raw_xp, 0, max_xp())
	return {"xp": xp, "lv": level_for_xp(xp)}

static func _record_xp(raw_record) -> int:
	if not raw_record is Dictionary:
		return 0
	return int((raw_record as Dictionary).get("xp", 0))

static func award_trade_xp(record: Dictionary, amount: int) -> Dictionary:
	var xp := int(record.get("xp", 0)) + maxi(0, amount)
	return normalize_trade_record({"xp": xp})

# Normalize only the four Trade records.  v0 first collapses the historical
# aliases into one unified total; v1 clones Wayfinding exactly; v2 preserves
# each canonical pool independently.  It always emits canonical keys only.
static func normalize_trade_state(raw_trades, source_version: int) -> Dictionary:
	var trades: Dictionary = raw_trades if raw_trades is Dictionary else {}
	if source_version >= 2:
		var independent := fresh_trade_state()
		for trade_key in TRADE_KEYS:
			independent[trade_key] = normalize_trade_record(trades.get(trade_key, {}))
		return independent

	var unified_xp := 0
	if source_version == 1 and trades.has("wayfinding"):
		unified_xp = _record_xp(trades.get("wayfinding", {}))
	else:
		# carto/cartography are synonyms from different historical builds: keep
		# the furthest record, never sum them. Earth/Wild/Hunt were distinct pools.
		var carto_xp := maxi(_record_xp(trades.get("carto", {})),
			_record_xp(trades.get("cartography", {})))
		unified_xp = carto_xp
		for legacy_key in LEGACY_DISTINCT_TRADE_KEYS:
			unified_xp += _record_xp(trades.get(legacy_key, {}))
		# Defensive compatibility for an unversioned save that had already
		# adopted the unified key before its version field was written. Historical
		# family keys win whenever they contribute progress.
		if unified_xp == 0:
			unified_xp = _record_xp(trades.get("wayfinding", {}))
	var cloned := normalize_trade_record({"xp": unified_xp})
	var out := {}
	for trade_key in TRADE_KEYS:
		out[trade_key] = cloned.duplicate()
	return out

static func focus_skill_ids() -> Array:
	return IMPLEMENTED_FOCUS_SKILLS.duplicate()

static func designed_focus_skill_ids() -> Array:
	return FOCUS_SKILLS.keys()

static func skill_metadata(skill_id: String) -> Dictionary:
	if skill_id == BASIC_SHOT:
		return {"name": "Basic Shot", "innate": true, "configurable": false,
			"implemented": true, "trade": "huntcraft", "level": 1}
	if not FOCUS_SKILLS.has(skill_id):
		return {}
	var metadata: Dictionary = (FOCUS_SKILLS[skill_id] as Dictionary).duplicate(true)
	metadata["innate"] = false
	metadata["implemented"] = IMPLEMENTED_FOCUS_SKILLS.has(skill_id)
	metadata["configurable"] = bool(metadata["implemented"])
	return metadata

static func is_focus_skill(skill_id: String) -> bool:
	return IMPLEMENTED_FOCUS_SKILLS.has(skill_id)

static func is_designed_focus_skill(skill_id: String) -> bool:
	return FOCUS_SKILLS.has(skill_id)

static func is_known_skill_id(skill_id: String) -> bool:
	return skill_id == BASIC_SHOT or is_designed_focus_skill(skill_id)

static func is_gear_granted_skill(skill_id: String) -> bool:
	return GEAR_GRANTED_SKILLS.has(skill_id)

static func canonical_skill_id_for_migration(raw_skill: String) -> String:
	if raw_skill == BASIC_SHOT or IMPLEMENTED_FOCUS_SKILLS.has(raw_skill) \
			or GEAR_GRANTED_SKILLS.has(raw_skill):
		return raw_skill
	return String(LEGACY_SKILL_ALIASES.get(raw_skill, ""))

static func canonicalize_owned_skills(raw_owned) -> Array:
	var out: Array = []
	if not raw_owned is Array:
		return out
	for raw_skill in raw_owned:
		var skill_id := canonical_skill_id_for_migration(String(raw_skill))
		# Basic Shot is innate; gear skills and unknown IDs never become a
		# permanent Focus-Skill entitlement.
		if is_focus_skill(skill_id) and not out.has(skill_id):
			out.append(skill_id)
	return out

static func canonicalize_loadout(raw_loadout, owned_skills: Array = [],
		allow_unowned: bool = false) -> Array:
	var out: Array = []
	var canonical_owned := canonicalize_owned_skills(owned_skills)
	if not raw_loadout is Array:
		return out
	for raw_skill in raw_loadout:
		var skill_id := canonical_skill_id_for_migration(String(raw_skill))
		# Gear skills are deliberately dropped here.  The v2 runtime will append
		# transient grants after evaluating equipped gear, never from persistence.
		if is_focus_skill(skill_id) and (allow_unowned or canonical_owned.has(skill_id)) \
				and not out.has(skill_id) and out.size() < 3:
			out.append(skill_id)
	return out

static func tutorial_required_focus_skills(tutorial_step: int) -> Array:
	# The current onboarding's step 6 practice bramble requires Power Shot.
	# Retain this rule when resuming any save that reached that lesson or later.
	return ["PowerShot"] if tutorial_step >= 6 else []

static func unlock_for_trade_level(trade_key: String, level: int) -> Dictionary:
	if not is_runtime_trade_key(trade_key) or level < 1 or level > LEVEL_CAP:
		return {}
	return (TRADE_UNLOCKS[trade_key] as Array)[level - 1].duplicate(true)

static func information_feature_metadata(feature_id: String) -> Dictionary:
	return (INFORMATION_FEATURES.get(feature_id, {}) as Dictionary).duplicate(true)

static func validate_unlock_registry() -> Dictionary:
	var errors: Array = []
	for trade_key in TRADE_KEYS:
		if not TRADE_UNLOCKS.has(trade_key):
			errors.append("missing Trade %s" % trade_key)
			continue
		var unlocks: Array = TRADE_UNLOCKS[trade_key]
		if unlocks.size() != LEVEL_CAP:
			errors.append("%s has %d unlocks" % [trade_key, unlocks.size()])
			continue
		var ids := {}
		for level in range(1, LEVEL_CAP + 1):
			var unlock = unlocks[level - 1]
			if not unlock is Dictionary or String(unlock.get("id", "")) == "":
				errors.append("%s level %d is missing an id" % [trade_key, level])
				continue
			var unlock_id := String(unlock.id)
			if ids.has(unlock_id):
				errors.append("%s repeats %s" % [trade_key, unlock_id])
			ids[unlock_id] = true
			var skill_id := String(unlock.get("skill_id", ""))
			if skill_id != "" and not is_known_skill_id(skill_id):
				errors.append("%s level %d references unknown Skill %s" % [trade_key, level, skill_id])
	return {"ok": errors.is_empty(), "errors": errors}

# Full pure migration surface for SaveGame v2.  It leaves unrelated fields
# untouched, derives levels from XP, removes obsolete Trade keys, and creates
# separate owned/equipped concepts without allowing a gear grant to fossilize.
static func normalize_save_to_v2(raw_save: Dictionary) -> Dictionary:
	var source_version := maxi(0, int(raw_save.get("version", 0)))
	# Never rewrite a newer schema into v2.  SaveGame will use this explicit
	# failure to surface an incompatibility rather than silently losing data.
	if not supports_save_version(source_version):
		return {}
	var out: Dictionary = raw_save.duplicate(true)
	out["version"] = SAVE_VERSION
	out["trades"] = normalize_trade_state(raw_save.get("trades", {}), source_version)

	var owned := canonicalize_owned_skills(raw_save.get("owned_skills", []))
	# v0/v1 stored only a loadout.  Valid legacy picks become owned first, then
	# remain equipped in their original order.
	var equipped: Array = []
	if source_version < SAVE_VERSION:
		var legacy_equipped := canonicalize_loadout(raw_save.get("loadout", []), [], true)
		for skill_id in legacy_equipped:
			if not owned.has(skill_id):
				owned.append(skill_id)
		equipped = canonicalize_loadout(legacy_equipped, owned)
	else:
		equipped = canonicalize_loadout(raw_save.get("loadout", []), owned)
	# A tutorial save at/after the Power Shot lesson must still be able to
	# finish its required practice beat, even if a malformed legacy loadout was
	# empty or contained only a gear-granted skill.
	for skill_id in tutorial_required_focus_skills(int(raw_save.get("tutorial_step", 0))):
		if not owned.has(skill_id):
			owned.append(skill_id)
		if not equipped.has(skill_id):
			if equipped.size() < 3:
				equipped.append(skill_id)
			else:
				# The reached practice lesson has a hard need for Power Shot.  Keep
				# exactly three configurable slots and replace the least-recent pick.
				equipped[2] = skill_id
	out["owned_skills"] = owned
	out["loadout"] = equipped
	return out
