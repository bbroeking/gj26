class_name Campaign
extends RefCounted

# Slice D1 domain authority for the authored Root Saga. Runtime and save code
# are adapters around these pure transitions; this module never touches Game,
# the scene tree, inventory, or disk.

const STATE_VERSION := 6
const FIRST_KNOT := "first_knot"
const GOLDEN_WALLOW := "golden_wallow"
const SEVENTH_ROAD := "seventh_road"
const QUEENS_SUMMIT := "queens_summit"
const PALE_OATH := "pale_oath"
const FIRE_IN_THE_BOUGH := "fire_in_the_bough"
const UNWRITTEN_ROAD := "unwritten_road"
const FIRST_KNOT_BOSS_RECIPE := "first_knot_boss"
const GOLDEN_WALLOW_BOSS_RECIPE := "golden_wallow_boss"
const SEVENTH_ROAD_BOSS_RECIPE := "seventh_road_boss"
const QUEENS_SUMMIT_BOSS_RECIPE := "queens_summit_boss"
const PALE_OATH_BOSS_RECIPE := "pale_oath_boss"
const FIRE_IN_THE_BOUGH_BOSS_RECIPE := "fire_in_the_bough_boss"
const UNWRITTEN_ROAD_BOSS_RECIPE := "unwritten_road_boss"
const FIRST_KNOT_RUMOUR := "mara_first_knot"
const GOLDEN_WALLOW_RUMOUR := "golden_wallow_boss"
const SEVENTH_ROAD_RUMOUR := "seventh_road_boss"
const QUEENS_SUMMIT_RUMOUR := "queens_summit_boss"
const PALE_OATH_RUMOUR := "pale_oath_boss"
const FIRE_IN_THE_BOUGH_RUMOUR := "fire_in_the_bough_boss"
const UNWRITTEN_ROAD_RUMOUR := "unwritten_road_boss"
const LEGACY_SUMMIT_HANDOFF := "legacy_summit_handoff"
const FIRST_KNOT_CLUES := [
	"thorn_whisper_1", "thorn_whisper_2", "thorn_whisper_3",
]
const GOLDEN_WALLOW_CLUES := [
	"gilt_bristle_1", "gilt_bristle_2", "gilt_bristle_3",
]
const SEVENTH_ROAD_CLUES := [
	"seventh_road_cold_track_1", "seventh_road_cold_track_2",
	"seventh_road_cold_track_3", "seventh_road_cold_track_4",
]
const QUEENS_SUMMIT_CLUES := [
	"shed_crown_thorn_1", "shed_crown_thorn_2",
	"shed_crown_thorn_3", "shed_crown_thorn_4",
]
const PALE_OATH_CLUES := [
	"oath_rubbing_1", "oath_rubbing_2", "oath_rubbing_3", "oath_rubbing_4",
]
const FIRE_IN_THE_BOUGH_CLUES := [
	"ember_verse_1", "ember_verse_2", "ember_verse_3", "ember_verse_4",
	"ember_verse_5",
]
const UNWRITTEN_ROAD_CLUES := [
	"lost_waymark_1", "lost_waymark_2", "lost_waymark_3", "lost_waymark_4",
	"lost_waymark_5",
]
# The Unwritten Chart witnesses these permanent campaign records. They are not
# materials, are never reserved, and do not participate in refund arithmetic.
const UNWRITTEN_REQUIRED_STORY_INPUTS := [
	"crown_root_rune", "ember_root_rune", "fang_root_rune", "green_root_rune",
	"map_of_nine_knots", "mist_root_rune", "pale_root_rune",
]
const ROOT_RUNE_IDS := [
	"green_root_rune", "mist_root_rune", "fang_root_rune", "crown_root_rune",
	"pale_root_rune", "ember_root_rune",
]
const ROAD_NAMES := {
	"lantern_path": "Lantern Path",
	"mended_way": "Mended Way",
	"open_footpath": "Open Footpath",
}
const ESCROW_PHASES := ["case", "in_run", "consumed", "refunded"]
const OPEN_ESCROW_PHASES := ["case", "in_run"]

const CHAPTERS := {
	FIRST_KNOT: {
		"name": "The First Knot",
		"min_wayfinding_clue": 4,
		"clue_recipe_id": "green_hollow",
		"clue_ids": FIRST_KNOT_CLUES,
		"clue_presentation": "thorn_whisper",
		"clue_target": 3,
		"boss_recipe_id": FIRST_KNOT_BOSS_RECIPE,
		"boss_rumour_id": FIRST_KNOT_RUMOUR,
		"min_wayfinding_boss": 8,
		"seal_id": "thorn_essence",
		"boss_kind": "hedgemother",
		"returned_on_failure": {"thorn_essence": 1},
		"boss_material_awards": {"tusker_tusk": 1},
		"relic_id": "green_root_rune",
		"restoration_id": "trophy_hall",
	},
	GOLDEN_WALLOW: {
		"name": "The Golden Wallow",
		"requires_chapter_clear": FIRST_KNOT,
		"min_wayfinding_clue": 9,
		"clue_recipe_id": "sallow_shallows",
		"clue_ids": GOLDEN_WALLOW_CLUES,
		"clue_presentation": "gilt_bristle",
		"clue_target": 3,
		"boss_recipe_id": GOLDEN_WALLOW_BOSS_RECIPE,
		"boss_rumour_id": GOLDEN_WALLOW_RUMOUR,
		"min_wayfinding_boss": 12,
		"seal_id": "tusker_tusk",
		"boss_kind": "burrow_boar",
		"returned_on_failure": {"tusker_tusk": 1},
		"boss_material_awards": {"wightpelt": 1},
		"relic_id": "mist_root_rune",
		"restoration_id": "sallow_jetty",
	},
	SEVENTH_ROAD: {
		"name": "The Seventh Road",
		"requires_chapter_clear": GOLDEN_WALLOW,
		"min_wayfinding_clue": 15,
		"clue_recipe_id": "briar_maze",
		"clue_ids": SEVENTH_ROAD_CLUES,
		"clue_presentation": "cold_track_clue",
		"clue_target": 4,
		"boss_recipe_id": SEVENTH_ROAD_BOSS_RECIPE,
		"boss_rumour_id": SEVENTH_ROAD_RUMOUR,
		"min_wayfinding_boss": 15,
		"min_wildcraft_boss": 14,
		"seal_id": "wightpelt",
		"boss_kind": "wolf_alpha",
		"returned_on_failure": {"wightpelt": 1},
		"boss_material_awards": {"alpha_fang": 1},
		"relic_id": "fang_root_rune",
		"restoration_id": "skald_archive",
	},
	QUEENS_SUMMIT: {
		"name": "Queen's Summit",
		"requires_chapter_clear": SEVENTH_ROAD,
		"min_wayfinding_clue": 16,
		"clue_recipe_id": "summit_approach",
		"clue_ids": QUEENS_SUMMIT_CLUES,
		"clue_presentation": "shed_crown_thorn",
		"clue_target": 4,
		"boss_recipe_id": QUEENS_SUMMIT_BOSS_RECIPE,
		"boss_rumour_id": QUEENS_SUMMIT_RUMOUR,
		"min_wayfinding_boss": 17,
		"seal_id": "alpha_fang",
		# Alpha Fang is settled by the Seventh Road, never reminted by Crownward
		# clue completion if a malformed/save-repaired pack happens to lack it.
		"award_seal_from_clues": false,
		"boss_kind": "hedgemother_queen",
		"returned_on_failure": {"alpha_fang": 1},
		"boss_material_awards": {"oath_nail": 1},
		"relic_id": "crown_root_rune",
		"restoration_id": "pale_stair",
	},
	PALE_OATH: {
		"name": "The Pale Oath",
		"requires_chapter_clear": QUEENS_SUMMIT,
		"min_wayfinding_clue": 18,
		"clue_source_id": "skald_pale_oath",
		"clue_recipe_id": "pale_veins",
		"clue_ids": PALE_OATH_CLUES,
		"clue_presentation": "oath_rubbing",
		"clue_target": 4,
		"boss_recipe_id": PALE_OATH_BOSS_RECIPE,
		"boss_rumour_id": PALE_OATH_RUMOUR,
		"boss_source_id": "skald_pale_oath_boss",
		"min_wayfinding_boss": 19,
		"seal_id": "oath_nail",
		# The Oath Nail is Queen's exact award.  Oath-Rubbings reveal the folio
		# but can never replace a missing or already-spent Nail.
		"award_seal_from_clues": false,
		"boss_kind": "barrow_jarl",
		"returned_on_failure": {"oath_nail": 1},
		"boss_material_awards": {"starheart_coal": 1},
		"relic_id": "pale_root_rune",
		"thread_awards": ["past_thread"],
		# The Lift and Hod's oath-stone are one settlement truth, not separate
		# restoration records.
		"restoration_id": "rootroad_lift",
	},
	FIRE_IN_THE_BOUGH: {
		"name": "Fire in the Bough",
		"requires_chapter_clear": PALE_OATH,
		"min_wayfinding_clue": 20,
		"clue_source_id": "rootroad_lift_ashen_bough",
		"clue_recipe_id": "ashen_bough",
		"clue_ids": FIRE_IN_THE_BOUGH_CLUES,
		"clue_presentation": "ember_verse",
		"clue_target": 5,
		"boss_recipe_id": FIRE_IN_THE_BOUGH_BOSS_RECIPE,
		"boss_rumour_id": FIRE_IN_THE_BOUGH_RUMOUR,
		"boss_source_id": "rootroad_lift_hearth_giant",
		"min_wayfinding_boss": 21,
		"seal_id": "starheart_coal",
		"award_seal_from_clues": false,
		"boss_kind": "hearth_giant",
		"returned_on_failure": {"starheart_coal": 1},
		"boss_material_awards": {"wyrm_scale": 1},
		"relic_id": "ember_root_rune",
		"thread_awards": ["present_thread"],
		"restoration_id": "ember_kiln",
	},
	UNWRITTEN_ROAD: {
		"name": "The Unwritten Road",
		"requires_chapter_clear": FIRE_IN_THE_BOUGH,
		"min_wayfinding_clue": 22,
		"clue_source_id": "threefold_loom_root_below",
		"clue_recipe_id": "root_below",
		"clue_ids": UNWRITTEN_ROAD_CLUES,
		"clue_presentation": "lost_waymark",
		"clue_target": 5,
		"boss_recipe_id": UNWRITTEN_ROAD_BOSS_RECIPE,
		"boss_rumour_id": UNWRITTEN_ROAD_RUMOUR,
		"min_wayfinding_boss": 23,
		"min_huntcraft_boss": 22,
		"seal_id": "wyrm_scale",
		"award_seal_from_clues": false,
		"boss_kind": "knot_eater",
		"returned_on_failure": {"wyrm_scale": 1},
		"boss_material_awards": {"quiet_tooth": 1},
		# The final road has no seventh Rune. Its settlement instead grants the
		# final Thread and lights the Master Forge.
		"relic_id": "",
		"thread_awards": ["unwritten_thread"],
		"restoration_id": "master_forge",
	},
}
const CHAPTER_ORDER := [FIRST_KNOT, GOLDEN_WALLOW, SEVENTH_ROAD, QUEENS_SUMMIT,
	PALE_OATH, FIRE_IN_THE_BOUGH, UNWRITTEN_ROAD]

# One protected legacy bridge is deliberately not campaign truth.  It exists
# solely to finish the lifecycle of already-materialized Summit Charts.  New
# inscription is retired in v3; the phase validation below remains so a frozen
# old Chart can still resolve, refund, or recover without being reclassified.
const HANDOFFS := {
	LEGACY_SUMMIT_HANDOFF: {
		"recipe_id": "queens_summit",
		"seal_id": "alpha_fang",
		"boss_kind": "hedgemother_queen",
		"returned_on_failure": {"alpha_fang": 1},
	},
}

# A Story Seal becomes reserved when its preceding authored settlement has
# occurred, before its own clue ledger is complete.  This keeps canonical
# awards out of newly committed legacy routes without interpreting an old Chart
# or loose material as campaign truth.
const FUTURE_SEAL_RECIPES := {
	"wightpelt": "seventh_road_boss",
	"alpha_fang": QUEENS_SUMMIT_BOSS_RECIPE,
	"oath_nail": "pale_oath_boss",
	"starheart_coal": "fire_in_the_bough_boss",
	"wyrm_scale": "unwritten_road_boss",
}
const FUTURE_SEAL_UNLOCK_CHAPTERS := {
	"wightpelt": GOLDEN_WALLOW,
	"alpha_fang": SEVENTH_ROAD,
	"oath_nail": QUEENS_SUMMIT,
	"starheart_coal": PALE_OATH,
	"wyrm_scale": FIRE_IN_THE_BOUGH,
}

# Painted records for chapter awards that are deliberately not ordinary loose
# materials.  Presentation layers can use this registry without reclassifying
# a permanent Thread or Root Rune into the satchel.
const STORY_ICON_PATHS := {
	"green_root_rune": "res://assets/ui/items/green_root_rune.png",
	"mist_root_rune": "res://assets/ui/items/mist_root_rune.png",
	"fang_root_rune": "res://assets/ui/items/fang_root_rune.png",
	"crown_root_rune": "res://assets/ui/items/crown_root_rune.png",
	"pale_root_rune": "res://assets/ui/items/pale_root_rune.png",
	"past_thread": "res://assets/ui/items/past_thread.png",
	"ember_root_rune": "res://assets/ui/items/ember_root_rune.png",
	"present_thread": "res://assets/ui/items/present_thread.png",
}

static func story_icon_path(id: String) -> String:
	return String(STORY_ICON_PATHS.get(id, ""))

static func empty_state() -> Dictionary:
	return {
		"version": STATE_VERSION,
		"next_attempt_id": 1,
		"chapters": _empty_chapters(),
		"relics": [],
		# Threads are permanent chapter awards, never materials or relics.
		"threads": [],
		# Lost Waymarks are durable Root Below ledger facts, not physical items.
		"lost_waymarks": [],
		# The Loom records this permanent Map; it is a story reference, never an
		# inventory item, Chart component, or escrow payload.
		"map_of_nine_knots": false,
		# A successful host naming action chooses one cosmetic road name. It is
		# intentionally outside the campaign fingerprint and all reward policy.
		"road_name_id": "",
		"restorations": [],
		# v3 migration marker.  A consumed legacy Summit handoff may receive
		# exactly one alpha-fang repair through the explicit pure transition
		# below; no other old Summit evidence can set this marker or award it.
		"legacy_summit_alpha_fang_credit": false,
		# Escrows are an append-only attempt ledger. Phase may only move
		# case -> in_run -> consumed/refunded; terminal records remain as
		# idempotence tombstones so recovery can never refund twice.
		"escrows": {},
	}

static func _empty_chapters() -> Dictionary:
	var out := {}
	for chapter_id in CHAPTER_ORDER:
		out[chapter_id] = {"clue_count": 0, "cleared": false,
			"banked_chart_ids": []}
	return out

static func _authored_array(raw, authored: Array) -> Array:
	var seen := {}
	if raw is Array:
		for id_v in raw:
			var id := String(id_v)
			if authored.has(id):
				seen[id] = true
	var out: Array = []
	for id in authored:
		if seen.has(id):
			out.append(id)
	return out

static func _chapter_def(chapter_id: String) -> Dictionary:
	return (CHAPTERS.get(chapter_id, {}) as Dictionary).duplicate(true)

static func _protected_contract_def(contract_id: String) -> Dictionary:
	if CHAPTERS.has(contract_id):
		return (CHAPTERS[contract_id] as Dictionary).duplicate(true)
	return (HANDOFFS.get(contract_id, {}) as Dictionary).duplicate(true)

static func _escrow_contract_id(record: Dictionary) -> String:
	return String(record.get("contract_id", record.get("chapter_id", "")))

static func _chapter_for_recipe(recipe_id: String, field: String) -> String:
	for chapter_id in CHAPTER_ORDER:
		var chapter_def: Dictionary = CHAPTERS[chapter_id]
		if recipe_id == String(chapter_def.get(field, "")):
			return chapter_id
	return ""

# Public resolver for adapters that have only a physical Chart recipe id.  This
# deliberately recognizes only authored campaign routes; legacy templates and
# ordinary boss-affix Charts remain campaign-inert.
static func chapter_for_recipe(recipe_id: String) -> String:
	var clue_chapter := _chapter_for_recipe(recipe_id, "clue_recipe_id")
	return clue_chapter if clue_chapter != "" \
		else _chapter_for_recipe(recipe_id, "boss_recipe_id")

static func _chapter_prerequisites_met(state: Dictionary, chapter_id: String) -> bool:
	var chapter_def: Dictionary = CHAPTERS.get(chapter_id, {})
	var required := String(chapter_def.get("requires_chapter_clear", ""))
	return required == "" or (state.chapters as Dictionary).has(required) \
		and bool((state.chapters[required] as Dictionary).get("cleared", false))

static func _canonical_story_input_snapshot(raw_snapshot) -> Array:
	var seen := {}
	if raw_snapshot is Array:
		for id_v in raw_snapshot:
			var id := String(id_v)
			if UNWRITTEN_REQUIRED_STORY_INPUTS.has(id):
				seen[id] = true
	var snapshot: Array = seen.keys()
	snapshot.sort()
	# An incomplete or forged witness must remain unable to settle. The escrow is
	# still retained so its physical Wyrm Scale can be recovered normally.
	return snapshot if snapshot == UNWRITTEN_REQUIRED_STORY_INPUTS else []

static func _story_input_fingerprint(snapshot: Array) -> String:
	return ("story-inputs-v1|" + ",".join(snapshot)).sha256_text()

static func _map_prerequisites_met(state: Dictionary) -> bool:
	var chapters: Dictionary = state.get("chapters", {})
	var road: Dictionary = chapters.get(UNWRITTEN_ROAD, {})
	var fire: Dictionary = chapters.get(FIRE_IN_THE_BOUGH, {})
	return bool(fire.get("cleared", false)) \
		and int(road.get("clue_count", 0)) >= int(CHAPTERS[UNWRITTEN_ROAD].clue_target) \
		and (state.get("lost_waymarks", []) as Array).size() \
			>= int(CHAPTERS[UNWRITTEN_ROAD].clue_target) \
		and (state.get("threads", []) as Array).has("past_thread") \
		and (state.get("threads", []) as Array).has("present_thread")

static func normalize_campaign_state(raw_state) -> Dictionary:
	var raw: Dictionary = raw_state if raw_state is Dictionary else {}
	var source_version := int(raw.get("version", 1))
	var out := empty_state()
	out.next_attempt_id = maxi(1, int(raw.get("next_attempt_id", 1)))
	var raw_chapters = raw.get("chapters", {})
	if raw_chapters is Dictionary:
		for chapter_id in CHAPTER_ORDER:
			# The entire Unwritten Road is additive in v6. A v1-v5 record may
			# contain loose Wyrm Scales, Rune-like values, or even forged future
			# keys, but none can synthesize this new chapter's truth.
			if chapter_id == UNWRITTEN_ROAD and source_version < STATE_VERSION:
				continue
			var chapter_raw = (raw_chapters as Dictionary).get(chapter_id, {})
			if chapter_raw is Dictionary:
				var chapter_def: Dictionary = CHAPTERS[chapter_id]
				var target := int(chapter_def.clue_target)
				var cleared := bool((chapter_raw as Dictionary).get("cleared", false))
				var legacy_count := clampi(int((chapter_raw as Dictionary)
					.get("clue_count", 0)), 0, target)
				var banked_seen := {}
				var raw_banked = (chapter_raw as Dictionary).get("banked_chart_ids", [])
				if raw_banked is Array:
					for chart_id_v in raw_banked:
						var chart_id := String(chart_id_v)
						if chart_id != "":
							banked_seen[chart_id] = true
				var banked: Array = banked_seen.keys()
				banked.sort()
				if banked.size() > target:
					banked.resize(target)
				# Compatibility for a pre-correction D1 save: its bounded clue_count
				# was durable before physical Chart IDs were recorded. Reserved stable
				# tombstones preserve that earned progress without pretending a legacy
				# Tier-1 Chart is newly campaign-eligible.
				var preserved_count := target if cleared else legacy_count
				var tombstone_index := 1
				while banked.size() < preserved_count:
					var tombstone := "legacy-banked-%s-%d" % [chapter_id.replace("_", "-"), tombstone_index]
					tombstone_index += 1
					if banked.has(tombstone):
						continue
					banked.append(tombstone)
				banked.sort()
				(out.chapters[chapter_id] as Dictionary)["clue_count"] = target \
					if cleared else mini(banked.size(), target)
				(out.chapters[chapter_id] as Dictionary)["cleared"] = cleared
				(out.chapters[chapter_id] as Dictionary)["banked_chart_ids"] = banked
	out.relics = _authored_array(raw.get("relics", []),
		ROOT_RUNE_IDS)
	out.threads = _authored_array(raw.get("threads", []),
		["past_thread", "present_thread", "unwritten_thread"])
	var unwritten_chapter: Dictionary = out.chapters[UNWRITTEN_ROAD]
	if source_version < STATE_VERSION or not bool(unwritten_chapter.cleared):
		(out.threads as Array).erase("unwritten_thread")
	# Lost Waymarks are a projection of the authored Root Below return ledger.
	# Canonicalizing from that ledger prevents a loose/forged field from becoming
	# a second authority while preserving all earned v6 progress.
	if source_version >= STATE_VERSION:
		var waymark_count := int(unwritten_chapter.clue_count)
		out.lost_waymarks = UNWRITTEN_ROAD_CLUES.slice(0, waymark_count)
	if source_version >= STATE_VERSION and bool(raw.get("map_of_nine_knots", false)) \
			and _map_prerequisites_met(out):
		out.map_of_nine_knots = true
	if source_version >= STATE_VERSION and bool(unwritten_chapter.cleared) \
			and ROAD_NAMES.has(String(raw.get("road_name_id", ""))):
		out.road_name_id = String(raw.get("road_name_id", ""))
	out.restorations = _authored_array(raw.get("restorations", []),
		["trophy_hall", "sallow_jetty", "skald_archive", "pale_stair",
			"rootroad_lift", "ember_kiln", "master_forge"])
	if source_version < STATE_VERSION or not bool(unwritten_chapter.cleared):
		(out.restorations as Array).erase("master_forge")
	out.legacy_summit_alpha_fang_credit = bool(
		raw.get("legacy_summit_alpha_fang_credit", false))
	var raw_escrows = raw.get("escrows", {})
	var max_seen_attempt := 0
	if raw_escrows is Dictionary:
		var ids: Array = (raw_escrows as Dictionary).keys()
		ids.sort()
		for attempt_id_v in ids:
			var attempt_id := String(attempt_id_v)
			var record = (raw_escrows as Dictionary)[attempt_id_v]
			if attempt_id == "" or not record is Dictionary:
				continue
			var chapter_id := String((record as Dictionary).get("chapter_id", ""))
			var contract_id := String((record as Dictionary).get("contract_id", chapter_id))
			if contract_id == UNWRITTEN_ROAD and source_version < STATE_VERSION:
				continue
			var phase := String((record as Dictionary).get("phase", ""))
			var chart_instance_id := String((record as Dictionary)
				.get("chart_instance_id", ""))
			var contract_def := _protected_contract_def(contract_id)
			if contract_def.is_empty() or phase not in ESCROW_PHASES \
					or chart_instance_id == "":
				continue
			var expected: Dictionary = contract_def.returned_on_failure
			var normalized_record := {
				"attempt_id": attempt_id,
				"chart_instance_id": chart_instance_id,
				"phase": phase,
				"items": expected.duplicate(true),
			}
			if CHAPTERS.has(contract_id):
				# Preserve the public First/Golden campaign-record shape.
				normalized_record["chapter_id"] = contract_id
				if contract_id == UNWRITTEN_ROAD:
					var snapshot := _canonical_story_input_snapshot(
						(record as Dictionary).get("story_input_snapshot", []))
					normalized_record["story_input_snapshot"] = snapshot
					normalized_record["story_input_fingerprint"] = \
						_story_input_fingerprint(snapshot) if not snapshot.is_empty() else ""
			else:
				normalized_record["kind"] = "handoff"
				normalized_record["contract_id"] = contract_id
			out.escrows[attempt_id] = normalized_record
			var prefix := contract_id + "-"
			if attempt_id.begins_with(prefix):
				max_seen_attempt = maxi(max_seen_attempt,
					int(attempt_id.trim_prefix(prefix)))
	out.next_attempt_id = maxi(int(out.next_attempt_id), max_seen_attempt + 1)
	return out

# v3 compatibility repair for the one player who had consumed the formerly
# campaign-inert Summit handoff before the Queen chapter existed.  This is a
# pure transition: the save adapter passes its *pre-normalization* campaign
# record plus its material counts, persists the returned state and marker, and
# sets the named material to the supplied target before accepting input.
#
# Only a v2 consumed handoff qualifies.  A case/in-run/refunded handoff, a
# materialized old Summit Chart, loose Alpha Fang, boss flags, and all new v3
# state deliberately produce no transition.  Marking a qualifying record even
# when a Fang is already present makes a later corrupt-save fallback unable to
# replay the repair.
static func apply_legacy_summit_alpha_fang_credit(raw_state,
		material_counts: Dictionary) -> Dictionary:
	var raw: Dictionary = raw_state if raw_state is Dictionary else {}
	var out := normalize_campaign_state(raw)
	var result := {
		"ok": true,
		"changed": false,
		"eligible": false,
		"state": out,
		"material_set": {},
	}
	if int(raw.get("version", 1)) != 2 \
			or bool(out.legacy_summit_alpha_fang_credit):
		return result
	for record_v in (out.escrows as Dictionary).values():
		var record: Dictionary = record_v
		if _escrow_contract_id(record) == LEGACY_SUMMIT_HANDOFF \
				and String(record.phase) == "consumed":
			result.eligible = true
			break
	if not bool(result.eligible):
		return result
	out.legacy_summit_alpha_fang_credit = true
	result.changed = true
	if int(material_counts.get("alpha_fang", 0)) <= 0:
		# This is a target rather than an increment: adapters restore exactly one
		# Fang even if a malformed legacy count was negative.
		result.material_set = {"alpha_fang": 1}
	return result

static func campaign_fingerprint(state) -> String:
	var normalized := normalize_campaign_state(state)
	var parts: Array[String] = ["campaign-v%d" % STATE_VERSION,
		"next=%d" % int(normalized.next_attempt_id)]
	for chapter_id in CHAPTER_ORDER:
		var chapter: Dictionary = normalized.chapters[chapter_id]
		var banked_ids: Array = chapter.banked_chart_ids
		parts.append("%s=%d:%d:%s" % [chapter_id, int(chapter.clue_count),
			int(chapter.cleared), ",".join(banked_ids)])
	var escrow_ids: Array = normalized.escrows.keys()
	escrow_ids.sort()
	for attempt_id_v in escrow_ids:
		var attempt_id := String(attempt_id_v)
		var record: Dictionary = normalized.escrows[attempt_id]
		parts.append("%s:%s:%s:%s" % [attempt_id, _escrow_contract_id(record),
			String(record.chart_instance_id), String(record.phase)])
	parts.append("legacy-summit-alpha-credit=%d" % int(
		bool(normalized.legacy_summit_alpha_fang_credit)))
	parts.append("relics=%s" % ",".join(normalized.relics as Array))
	parts.append("threads=%s" % ",".join(normalized.threads as Array))
	parts.append("lost-waymarks=%s" % ",".join(normalized.lost_waymarks as Array))
	parts.append("map-of-nine-knots=%d" % int(bool(normalized.map_of_nine_knots)))
	# road_name_id is deliberately excluded: it is a cosmetic host choice and
	# cannot stale a Chart preview or affect progression/rewards.
	return "|".join(parts).sha256_text()

static func chapter_clue_count(state, chapter_id: String = FIRST_KNOT) -> int:
	var normalized := normalize_campaign_state(state)
	if not CHAPTERS.has(chapter_id):
		return 0
	return int((normalized.chapters[chapter_id] as Dictionary).clue_count)

static func chapter_cleared(state, chapter_id: String = FIRST_KNOT) -> bool:
	var normalized := normalize_campaign_state(state)
	return CHAPTERS.has(chapter_id) \
		and bool((normalized.chapters[chapter_id] as Dictionary).cleared)

# Data-owned final Chart witness contract. The Table uses this single pure
# projection for preview/commit freshness; adapters may display its required
# and missing lists but must never turn any value into a material cost.
static func required_story_inputs(state) -> Dictionary:
	var normalized := normalize_campaign_state(state)
	var present: Array = []
	for story_id_v in UNWRITTEN_REQUIRED_STORY_INPUTS:
		var story_id := String(story_id_v)
		if story_id == "map_of_nine_knots":
			if bool(normalized.map_of_nine_knots):
				present.append(story_id)
		elif (normalized.relics as Array).has(story_id):
			present.append(story_id)
	var missing: Array = []
	for story_id_v in UNWRITTEN_REQUIRED_STORY_INPUTS:
		var story_id := String(story_id_v)
		if not present.has(story_id):
			missing.append(story_id)
	var eligible := missing.is_empty()
	var snapshot: Array = UNWRITTEN_REQUIRED_STORY_INPUTS.duplicate() if eligible else []
	return {
		"eligible": eligible,
		"required_story_inputs": UNWRITTEN_REQUIRED_STORY_INPUTS.duplicate(),
		"present_story_inputs": present,
		"missing_story_inputs": missing,
		"story_input_snapshot": snapshot,
		# Present references (not just a complete snapshot) participate in
		# freshness, so different missing-witness states cannot share a preview.
		"story_input_fingerprint": _story_input_fingerprint(present),
	}

static func can_record_map_of_nine_knots(state, wayfinding_level: int) -> bool:
	var normalized := normalize_campaign_state(state)
	return not bool(normalized.map_of_nine_knots) \
		and wayfinding_level >= 23 and _map_prerequisites_met(normalized)

# Read-only Map ritual projection for the one physical Threefold Loom.  This
# names the Loom's presentation stages without creating a second Map policy:
# `record_map_of_nine_knots` remains the only function that can change Map
# truth.  The first folio is a source-knowledge stage, not a Map prerequisite;
# once it is settled, the five rows below mirror `_map_prerequisites_met`
# exactly.  Final-recipe knowledge is deliberately a separate repair concern:
# a legacy Map record may be true while that knowledge needs reconciliation.
static func threefold_loom_view(state, wayfinding_level: int,
		first_folio_settled: bool, final_recipe_known: bool,
		read_only: bool = false) -> Dictionary:
	var normalized := normalize_campaign_state(state)
	var road: Dictionary = (normalized.chapters as Dictionary).get(UNWRITTEN_ROAD, {})
	var fire: Dictionary = (normalized.chapters as Dictionary).get(FIRE_IN_THE_BOUGH, {})
	var waymark_target := int(CHAPTERS[UNWRITTEN_ROAD].clue_target)
	var requirements: Array = [
		{
			"id": "fire_in_the_bough", "label": "Fire in the Bough settled",
			"met": bool(fire.get("cleared", false)), "current": 1 if bool(fire.get("cleared", false)) else 0,
			"required": 1, "read_only": true,
		},
		{
			"id": "lost_waymarks", "label": "Lost Waymarks returned",
			"met": int(road.get("clue_count", 0)) >= waymark_target
				and (normalized.lost_waymarks as Array).size() >= waymark_target,
			"current": mini(int(road.get("clue_count", 0)),
				(normalized.lost_waymarks as Array).size()),
			"required": waymark_target, "read_only": true,
		},
		{
			"id": "past_thread", "label": "Past Thread remembered",
			"met": (normalized.threads as Array).has("past_thread"),
			"current": 1 if (normalized.threads as Array).has("past_thread") else 0,
			"required": 1, "read_only": true,
		},
		{
			"id": "present_thread", "label": "Present Thread remembered",
			"met": (normalized.threads as Array).has("present_thread"),
			"current": 1 if (normalized.threads as Array).has("present_thread") else 0,
			"required": 1, "read_only": true,
		},
		{
			"id": "wayfinding_23", "label": "Wayfinding",
			"met": wayfinding_level >= 23, "current": wayfinding_level,
			"required": 23, "read_only": true,
		},
	]
	var map_recorded := bool(normalized.map_of_nine_knots)
	var phase := "first_folio"
	if map_recorded:
		phase = "map_recorded"
	elif first_folio_settled:
		phase = "ritual_ready" if can_record_map_of_nine_knots(normalized,
			wayfinding_level) else "waiting"
	return {
		"valid": true,
		"phase": phase,
		"read_only": read_only,
		"can_trace": phase == "ritual_ready" and not read_only,
		"map_recorded": map_recorded,
		"knowledge_complete": first_folio_settled and final_recipe_known,
		"loom_state": loom_state(normalized),
		"requirements": requirements,
	}

# The Threefold Loom's Map ritual is pure and idempotent. Past/Present remain
# story references; no item, Rune, Thread, or Waymark leaves a satchel here.
static func record_map_of_nine_knots(state, wayfinding_level: int) -> Dictionary:
	var out := normalize_campaign_state(state)
	var result := {"ok": false, "changed": false, "state": out,
		"map_awarded": false, "loom_state": loom_state(out)}
	if bool(out.map_of_nine_knots):
		result.ok = true
		return result
	if wayfinding_level < 23 or not _map_prerequisites_met(out):
		return result
	out.map_of_nine_knots = true
	result.ok = true
	result.changed = true
	result.map_awarded = true
	result.loom_state = loom_state(out)
	return result

static func loom_state(state) -> String:
	var normalized := normalize_campaign_state(state)
	if chapter_cleared(normalized, UNWRITTEN_ROAD) \
		and (normalized.threads as Array).has("unwritten_thread"):
		return "awake"
	return "stirring" if bool(normalized.map_of_nine_knots) else "dormant"

# Pure generator-facing query. A legacy Tier-1 Chart has no physical recipe_id
# and therefore receives no campaign clue; only the authored Green Hollow route
# can carry the next missing Thorn Whisper.
static func next_clue_for_chart(state, recipe_id: String,
		chart_instance_id: String, wayfinding_level: int) -> Dictionary:
	var normalized := normalize_campaign_state(state)
	var chapter_id := _chapter_for_recipe(recipe_id, "clue_recipe_id")
	if chapter_id == "":
		return {}
	var chapter_def: Dictionary = CHAPTERS[chapter_id]
	var chapter: Dictionary = normalized.chapters[chapter_id]
	var clue_count := int(chapter.clue_count)
	if chart_instance_id == "" or not _chapter_prerequisites_met(normalized, chapter_id) \
			or wayfinding_level < int(chapter_def.min_wayfinding_clue) \
			or bool(chapter.cleared) \
			or (chapter.banked_chart_ids as Array).has(chart_instance_id) \
			or clue_count >= int(chapter_def.clue_target):
		return {}
	return {
		"chapter_id": chapter_id,
		"clue_id": String((chapter_def.clue_ids as Array)[clue_count]),
		"presentation": String(chapter_def.clue_presentation),
	}

static func record_successful_chart_return(state, recipe_id: String,
		chart_instance_id: String, wayfinding_level_after_xp: int,
		material_counts: Dictionary = {}) -> Dictionary:
	var out := normalize_campaign_state(state)
	var result := {"ok": true, "changed": false, "state": out,
		"clue_id": "", "material_awards": {}, "rumour_ids": []}
	var clue := next_clue_for_chart(out, recipe_id, chart_instance_id,
		wayfinding_level_after_xp)
	if clue.is_empty():
		return result
	var chapter_id := String(clue.chapter_id)
	var chapter_def: Dictionary = CHAPTERS[chapter_id]
	var chapter: Dictionary = out.chapters[chapter_id]
	var next_count := int(chapter.clue_count) + 1
	(chapter.banked_chart_ids as Array).append(chart_instance_id)
	chapter.clue_count = next_count
	result.changed = true
	result.clue_id = String(clue.clue_id)
	if chapter_id == UNWRITTEN_ROAD:
		# The authored clue id is the durable Waymark ledger fact. Chart instance
		# ids remain the idempotence ledger; neither is an inventory material.
		if not (out.lost_waymarks as Array).has(String(clue.clue_id)):
			(out.lost_waymarks as Array).append(String(clue.clue_id))
			(out.lost_waymarks as Array).sort()
	if next_count >= int(chapter_def.clue_target):
		result.rumour_ids = [String(chapter_def.boss_rumour_id)]
		var seal_id := String(chapter_def.seal_id)
		if bool(chapter_def.get("award_seal_from_clues", true)) \
				and int(material_counts.get(seal_id, 0)) <= 0:
			result.material_awards = {seal_id: 1}
	return result

static func has_open_escrow(state, chapter_id: String = FIRST_KNOT) -> bool:
	var normalized := normalize_campaign_state(state)
	for record_v in normalized.escrows.values():
		var record: Dictionary = record_v
		if _escrow_contract_id(record) == chapter_id \
				and String(record.phase) in OPEN_ESCROW_PHASES:
			return true
	return false

static func can_inscribe_boss(state, recipe_id: String,
		wayfinding_level: int, wildcraft_level: int = 23,
		huntcraft_level: int = 23) -> bool:
	var normalized := normalize_campaign_state(state)
	var chapter_id := _chapter_for_recipe(recipe_id, "boss_recipe_id")
	if chapter_id == "":
		return false
	var chapter_def: Dictionary = CHAPTERS[chapter_id]
	var chapter: Dictionary = normalized.chapters[chapter_id]
	return _chapter_prerequisites_met(normalized, chapter_id) \
		and wayfinding_level >= int(chapter_def.min_wayfinding_boss) \
		and wildcraft_level >= int(chapter_def.get("min_wildcraft_boss", 1)) \
		and huntcraft_level >= int(chapter_def.get("min_huntcraft_boss", 1)) \
		and int(chapter.clue_count) >= int(chapter_def.clue_target) \
		and not bool(chapter.cleared) \
		and not has_open_escrow(normalized, chapter_id) \
		and (chapter_id != UNWRITTEN_ROAD \
			or bool(required_story_inputs(normalized).eligible)) \
		# An old frozen Summit handoff holds the same physical Alpha Fang.  It
		# must resolve through its historic lifecycle before a new Queen escrow
		# can be committed, but it never becomes Queen campaign truth.
		and (chapter_id != QUEENS_SUMMIT \
			or not has_open_escrow(normalized, LEGACY_SUMMIT_HANDOFF))

static func boss_contract(recipe_id: String) -> Dictionary:
	var chapter_id := _chapter_for_recipe(recipe_id, "boss_recipe_id")
	if chapter_id == "":
		return {}
	var chapter_def: Dictionary = CHAPTERS[chapter_id]
	return {
		"chapter_id": chapter_id,
		"boss_kind": String(chapter_def.boss_kind),
		"seal_id": String(chapter_def.seal_id),
		"guaranteed": true,
		"escrow_items": (chapter_def.returned_on_failure as Dictionary).duplicate(true),
	}

static func handoff_contract(recipe_id: String) -> Dictionary:
	for contract_id_v in HANDOFFS:
		var contract_id := String(contract_id_v)
		var handoff: Dictionary = HANDOFFS[contract_id]
		if recipe_id == String(handoff.get("recipe_id", "")):
			return {
				"contract_id": contract_id,
				"boss_kind": String(handoff.boss_kind),
				"seal_id": String(handoff.seal_id),
				"guaranteed": true,
				"escrow_items": (handoff.returned_on_failure as Dictionary).duplicate(true),
				"campaign_inert": true,
			}
	return {}

static func can_inscribe_handoff(_state, _recipe_id: String) -> bool:
	# `queens_summit` was retired from all new v3 Table commits.  Keep
	# handoff_contract and the phase methods public for frozen charts, not for
	# starting a new old-style escrow.
	return false

static func begin_boss_escrow(state, chart_instance_id: String,
		chapter_id: String = FIRST_KNOT) -> Dictionary:
	var out := normalize_campaign_state(state)
	var result := {"ok": false, "changed": false, "state": out,
		"attempt_id": ""}
	if chart_instance_id == "" or not CHAPTERS.has(chapter_id):
		return result
	var chapter_def: Dictionary = CHAPTERS[chapter_id]
	var chapter: Dictionary = out.chapters[chapter_id]
	if not _chapter_prerequisites_met(out, chapter_id) or bool(chapter.cleared) \
			or int(chapter.clue_count) < int(chapter_def.clue_target):
		return result
	var story_inputs := required_story_inputs(out)
	if chapter_id == UNWRITTEN_ROAD and not bool(story_inputs.eligible):
		return result
	for prior_v in out.escrows.values():
		var prior: Dictionary = prior_v
		if String(prior.chart_instance_id) == chart_instance_id:
			return result
	if has_open_escrow(out, chapter_id):
		return result
	if chapter_id == QUEENS_SUMMIT \
			and has_open_escrow(out, LEGACY_SUMMIT_HANDOFF):
		return result
	var attempt_id := "%s-%d" % [chapter_id, int(out.next_attempt_id)]
	out.next_attempt_id = int(out.next_attempt_id) + 1
	out.escrows[attempt_id] = {
		"attempt_id": attempt_id,
		"chart_instance_id": chart_instance_id,
		"chapter_id": chapter_id,
		"phase": "case",
		"items": (chapter_def.returned_on_failure as Dictionary).duplicate(true),
	}
	if chapter_id == UNWRITTEN_ROAD:
		# Freeze the complete, sorted reference witness with the final attempt.
		# These IDs deliberately remain outside `items`, including recovery/refund.
		(out.escrows[attempt_id] as Dictionary)["story_input_snapshot"] \
			= (story_inputs.story_input_snapshot as Array).duplicate()
		(out.escrows[attempt_id] as Dictionary)["story_input_fingerprint"] \
			= String(story_inputs.story_input_fingerprint)
	result.ok = true
	result.changed = true
	result.attempt_id = attempt_id
	return result

static func begin_handoff_escrow(state, _chart_instance_id: String,
		_recipe_id: String) -> Dictionary:
	var out := normalize_campaign_state(state)
	var result := {"ok": false, "changed": false, "state": out,
		"attempt_id": ""}
	# New legacy handoff inscription is retired.  Existing records still use
	# mark/refund/resolve below and normalize exactly as before.
	# Keep the arguments in the public contract to avoid adapters treating a
	# post-v3 failure as permission to synthesize a replacement escrow.
	return result

static func mark_escrow_in_run(state, attempt_id: String,
		chart_instance_id: String, chapter_id: String = FIRST_KNOT) -> Dictionary:
	var out := normalize_campaign_state(state)
	var result := {"ok": false, "changed": false, "state": out}
	if not out.escrows.has(attempt_id):
		return result
	var record: Dictionary = out.escrows[attempt_id]
	if String(record.chart_instance_id) != chart_instance_id \
			or _escrow_contract_id(record) != chapter_id:
		return result
	if String(record.phase) == "in_run":
		result.ok = true
		return result
	if String(record.phase) != "case":
		return result
	record.phase = "in_run"
	result.ok = true
	result.changed = true
	return result

static func refund_escrow(state, attempt_id: String,
		chart_instance_id: String, chapter_id: String = FIRST_KNOT) -> Dictionary:
	var out := normalize_campaign_state(state)
	var result := {"ok": false, "changed": false, "state": out,
		"material_refunds": {}}
	if not out.escrows.has(attempt_id):
		return result
	var record: Dictionary = out.escrows[attempt_id]
	if String(record.chart_instance_id) != chart_instance_id \
			or _escrow_contract_id(record) != chapter_id:
		return result
	if String(record.phase) == "refunded":
		result.ok = true
		return result
	# A Chart still resting in the Case is not a failed attempt and keeps its
	# Seal escrowed. Only an entered, unresolved attempt can refund.
	if String(record.phase) != "in_run":
		return result
	record.phase = "refunded"
	result.ok = true
	result.changed = true
	result.material_refunds = (record.items as Dictionary).duplicate(true)
	return result

static func mark_handoff_in_run(state, attempt_id: String,
		chart_instance_id: String, recipe_id: String) -> Dictionary:
	var contract := handoff_contract(recipe_id)
	if contract.is_empty():
		return {"ok": false, "changed": false,
			"state": normalize_campaign_state(state)}
	return mark_escrow_in_run(state, attempt_id, chart_instance_id,
		String(contract.contract_id))

static func refund_handoff_escrow(state, attempt_id: String,
		chart_instance_id: String, recipe_id: String) -> Dictionary:
	var contract := handoff_contract(recipe_id)
	if contract.is_empty():
		return {"ok": false, "changed": false,
			"state": normalize_campaign_state(state), "material_refunds": {}}
	return refund_escrow(state, attempt_id, chart_instance_id,
		String(contract.contract_id))

static func resolve_boss_death(state, attempt_id: String,
		chart_instance_id: String, chapter_id: String = FIRST_KNOT) -> Dictionary:
	var out := normalize_campaign_state(state)
	var result := {"ok": false, "changed": false, "state": out,
		"material_awards": {}, "material_set": {}, "relic_awards": [],
		"material_targets_exact": {}, "thread_awards": [],
		"restoration_awards": []}
	if not CHAPTERS.has(chapter_id) or not out.escrows.has(attempt_id):
		return result
	var record: Dictionary = out.escrows[attempt_id]
	if String(record.chart_instance_id) != chart_instance_id \
			or _escrow_contract_id(record) != chapter_id:
		return result
	# Knot-Eater settlement is intentionally not a death event. Its encounter
	# may use this generic method nowhere; only the validated road-naming action
	# below can consume the Wyrm Scale and settle the final chapter.
	if chapter_id == UNWRITTEN_ROAD:
		return result
	if String(record.phase) == "consumed":
		result.ok = true
		return result
	if String(record.phase) != "in_run":
		return result
	var chapter_def: Dictionary = CHAPTERS[chapter_id]
	var chapter: Dictionary = out.chapters[chapter_id]
	record.phase = "consumed"
	if not bool(chapter.cleared):
		chapter.cleared = true
		chapter.clue_count = int(chapter_def.clue_target)
		result.material_awards = (chapter_def.boss_material_awards as Dictionary) \
			.duplicate(true)
		# The Nail has already left the case for this entered Boss Chart.  This
		# target (rather than a decrement) reconciles malformed duplicate counts
		# to the canonical post-settlement value when the runtime adapter applies
		# it with exact-target semantics.
		if chapter_id == PALE_OATH:
			result.material_set = {"oath_nail": 0}
			# Adapters apply this after ordinary award handling with exact-target
			# semantics. It is deliberately explicit so no hot runtime path needs a
			# Pale-specific chapter list: any malformed duplicate Nail is removed,
			# and the next-road Story Seal is exactly one Starheart Coal.
			result.material_targets_exact = {
				"oath_nail": 0,
				"starheart_coal": 1,
			}
		elif chapter_id == FIRE_IN_THE_BOUGH:
			# The Coal is the Fire chapter's single Story Seal. A successful
			# banking consumes every malformed duplicate and canonicalizes the
			# one forward-only Wyrm Scale award for the Unwritten Road.
			result.material_set = {"starheart_coal": 0}
			result.material_targets_exact = {
				"starheart_coal": 0,
				"wyrm_scale": 1,
			}
		var relic_id := String(chapter_def.relic_id)
		if not (out.relics as Array).has(relic_id):
			(out.relics as Array).append(relic_id)
			result.relic_awards = [relic_id]
		for thread_id_v in chapter_def.get("thread_awards", []):
			var thread_id := String(thread_id_v)
			if thread_id != "" and not (out.threads as Array).has(thread_id):
				(out.threads as Array).append(thread_id)
				(result.thread_awards as Array).append(thread_id)
		var restoration_id := String(chapter_def.restoration_id)
		if not (out.restorations as Array).has(restoration_id):
			(out.restorations as Array).append(restoration_id)
			result.restoration_awards = [restoration_id]
	result.ok = true
	result.changed = true
	return result

static func is_valid_road_name_id(road_name_id: String) -> bool:
	return ROAD_NAMES.has(road_name_id)

# The Knot-Eater's one canonical settlement transition. Calling this only after
# the encounter has verified its host/nonce/phase contract keeps Campaign pure
# while ensuring `died` can never accidentally advance the story.
static func resolve_unwritten_road(state, attempt_id: String,
		chart_instance_id: String, road_name_id: String) -> Dictionary:
	var out := normalize_campaign_state(state)
	var result := {"ok": false, "changed": false, "state": out,
		"material_awards": {}, "material_set": {}, "relic_awards": [],
		"material_targets_exact": {}, "thread_awards": [],
		"restoration_awards": [], "road_name_id": ""}
	if not is_valid_road_name_id(road_name_id) or not out.escrows.has(attempt_id):
		return result
	var record: Dictionary = out.escrows[attempt_id]
	if String(record.chart_instance_id) != chart_instance_id \
			or _escrow_contract_id(record) != UNWRITTEN_ROAD:
		return result
	if String(record.phase) == "consumed":
		# Tombstones make replay idempotent; their original name remains durable.
		result.ok = true
		result.road_name_id = String(out.road_name_id)
		return result
	if String(record.phase) != "in_run":
		return result
	var required: Dictionary = required_story_inputs(out)
	var snapshot := _canonical_story_input_snapshot(record.get("story_input_snapshot", []))
	if not bool(required.eligible) \
			or snapshot != (required.story_input_snapshot as Array) \
			or String(record.get("story_input_fingerprint", "")) \
				!= String(required.story_input_fingerprint):
		return result
	var chapter: Dictionary = out.chapters[UNWRITTEN_ROAD]
	if bool(chapter.cleared):
		return result
	record.phase = "consumed"
	record.road_name_id = road_name_id
	chapter.cleared = true
	chapter.clue_count = int(CHAPTERS[UNWRITTEN_ROAD].clue_target)
	out.road_name_id = road_name_id
	# Exact-target semantics canonicalize malformed duplicate physical trophies.
	# Wyrm Scale is the sole Seal; Map and Runes never appear in these fields.
	result.material_awards = {"quiet_tooth": 1}
	result.material_set = {"wyrm_scale": 0}
	result.material_targets_exact = {"wyrm_scale": 0, "quiet_tooth": 1}
	if not (out.threads as Array).has("unwritten_thread"):
		(out.threads as Array).append("unwritten_thread")
		result.thread_awards = ["unwritten_thread"]
	if not (out.restorations as Array).has("master_forge"):
		(out.restorations as Array).append("master_forge")
		result.restoration_awards = ["master_forge"]
	result.ok = true
	result.changed = true
	result.road_name_id = road_name_id
	return result

static func _trade_level(trades: Dictionary, trade_id: String) -> int:
	var value = trades.get(trade_id, 0)
	return int((value as Dictionary).get("lv", 0)) if value is Dictionary else int(value)

static func can_craft_quiet_tooth_grip(state, huntcraft_level: int,
		material_counts: Dictionary) -> bool:
	var normalized := normalize_campaign_state(state)
	return chapter_cleared(normalized, UNWRITTEN_ROAD) \
		and huntcraft_level >= 23 \
		and int(material_counts.get("quiet_tooth", 0)) >= 1 \
		and int(material_counts.get("quiet_tooth_grip", 0)) <= 0

# Master Hunt's exact-once trophy conversion. The resulting Grip remains a
# physical component for Master Forge; only its eligibility lives here.
static func craft_quiet_tooth_grip(state, huntcraft_level: int,
		material_counts: Dictionary) -> Dictionary:
	var out := normalize_campaign_state(state)
	var result := {"ok": false, "changed": false, "state": out,
		"material_targets_exact": {}}
	if not can_craft_quiet_tooth_grip(out, huntcraft_level, material_counts):
		return result
	result.ok = true
	result.changed = true
	result.material_targets_exact = {"quiet_tooth": 0, "quiet_tooth_grip": 1}
	return result

static func resolve_handoff(state, attempt_id: String,
		chart_instance_id: String, recipe_id: String) -> Dictionary:
	var out := normalize_campaign_state(state)
	var result := {"ok": false, "changed": false, "state": out,
		"material_awards": {}, "relic_awards": [], "restoration_awards": []}
	var contract := handoff_contract(recipe_id)
	if contract.is_empty() or not out.escrows.has(attempt_id):
		return result
	var record: Dictionary = out.escrows[attempt_id]
	if String(record.chart_instance_id) != chart_instance_id \
			or _escrow_contract_id(record) != String(contract.contract_id):
		return result
	if String(record.phase) == "consumed":
		result.ok = true
		return result
	if String(record.phase) != "in_run":
		return result
	record.phase = "consumed"
	result.ok = true
	result.changed = true
	return result

static func recover_unresolved_in_run(state) -> Dictionary:
	var out := normalize_campaign_state(state)
	var refunds := {}
	var refunded_attempt_ids: Array = []
	var attempt_ids: Array = out.escrows.keys()
	attempt_ids.sort()
	for attempt_id_v in attempt_ids:
		var attempt_id := String(attempt_id_v)
		var record: Dictionary = out.escrows[attempt_id]
		if String(record.phase) != "in_run":
			continue
		record.phase = "refunded"
		refunded_attempt_ids.append(attempt_id)
		for item_id_v in (record.items as Dictionary):
			var item_id := String(item_id_v)
			refunds[item_id] = int(refunds.get(item_id, 0)) \
				+ int((record.items as Dictionary)[item_id_v])
	return {"ok": true, "changed": not refunded_attempt_ids.is_empty(),
		"state": out, "material_refunds": refunds,
		"refunded_attempt_ids": refunded_attempt_ids}

# Only durable boss-death evidence may infer a legacy clear. Loose materials
# are deliberately ignored because dev grants and old inventories do not prove
# that the Hedgemother was defeated.
static func infer_legacy_clear(state, boss_ledger_slots: Dictionary,
		summit_cleared: bool = false) -> Dictionary:
	var out := normalize_campaign_state(state)
	var result := {"changed": false, "state": out}
	if chapter_cleared(out, FIRST_KNOT) \
			or (not summit_cleared and not boss_ledger_slots.has("tusker_tusk")):
		return result
	var chapter_def: Dictionary = CHAPTERS[FIRST_KNOT]
	var chapter: Dictionary = out.chapters[FIRST_KNOT]
	chapter.clue_count = int(chapter_def.clue_target)
	chapter.cleared = true
	if not (out.relics as Array).has(String(chapter_def.relic_id)):
		(out.relics as Array).append(String(chapter_def.relic_id))
	if not (out.restorations as Array).has(String(chapter_def.restoration_id)):
		(out.restorations as Array).append(String(chapter_def.restoration_id))
	result.changed = true
	return result

# A Story Seal is freely usable until its authored chapter becomes ready.  Once
# the clue ledger has named a pending Boss Chart, the Seal may only be used by
# that exact recipe.  The preceding chapter can reserve its canonical award
# earlier (for example Alpha Fang after the Seventh Road), so new legacy routes
# never consume it while the next clue road is underway.  This is pure policy:
# callers re-check it at preview, staging, and commit boundaries without a
# second reservation field.
static func seal_use_allowed(state, seal_id: String, recipe_id: String) -> bool:
	var normalized := normalize_campaign_state(state)
	for chapter_id in CHAPTER_ORDER:
		var chapter_def: Dictionary = CHAPTERS[chapter_id]
		var chapter: Dictionary = normalized.chapters[chapter_id]
		if seal_id == String(chapter_def.seal_id) \
				and _chapter_prerequisites_met(normalized, chapter_id) \
				and not bool(chapter.cleared) \
				and int(chapter.clue_count) >= int(chapter_def.clue_target):
			return recipe_id == String(chapter_def.boss_recipe_id)
	if FUTURE_SEAL_RECIPES.has(seal_id) \
			and chapter_cleared(normalized,
				String(FUTURE_SEAL_UNLOCK_CHAPTERS.get(seal_id, ""))):
		return recipe_id == String(FUTURE_SEAL_RECIPES[seal_id])
	return true

static func _inspection_context(context: Dictionary) -> Dictionary:
	var guest := bool(context.get("guest", false))
	var seen_event_keys := {}
	for field in ["seen_event_keys", "acknowledged_event_keys"]:
		var raw_seen = context.get(field, [])
		if raw_seen is Array:
			for event_key_v in raw_seen:
				seen_event_keys[String(event_key_v)] = true
		elif raw_seen is Dictionary:
			for event_key_v in (raw_seen as Dictionary).keys():
				if bool((raw_seen as Dictionary)[event_key_v]):
					seen_event_keys[String(event_key_v)] = true
	return {
		"available": bool(context.get("snapshot_available", true)),
		"guest": guest,
		"read_only": bool(context.get("read_only", false)) or guest,
		"seen_event_keys": seen_event_keys,
	}

static func _chapter_settlement_view(normalized: Dictionary, chapter_id: String,
		inspection: Dictionary, context: Dictionary) -> Dictionary:
	var chapter_def: Dictionary = CHAPTERS[chapter_id]
	var chapter: Dictionary = normalized.chapters[chapter_id]
	var available := bool(inspection.available)
	var cleared := bool(chapter.cleared)
	var relic_id := String(chapter_def.relic_id)
	var restoration_id := String(chapter_def.restoration_id)
	var visible := available and cleared and (normalized.restorations as Array).has(restoration_id)
	# The Loom's first source becomes readable after canonical Fire settlement.
	# It is presentation-only and deliberately ignores source unlock strings,
	# Trade levels, loose materials, and the unfinished chapter's own clear.
	var source_visible := chapter_id == UNWRITTEN_ROAD \
		and chapter_cleared(normalized, FIRE_IN_THE_BOUGH)
	var event_key := "%s_settlement" % chapter_id
	if chapter_id == FIRST_KNOT:
		event_key = "first_knot_homecoming"
	var suppress_debrief := chapter_id == FIRST_KNOT \
		and bool(context.get("d2_reprise", context.get("reprise", false)))
	var event_available := visible and not bool(inspection.read_only) \
		and not suppress_debrief and not (inspection.seen_event_keys as Dictionary).has(event_key)
	var awarded_threads: Array = []
	for thread_id_v in chapter_def.get("thread_awards", []):
		var thread_id := String(thread_id_v)
		if (normalized.threads as Array).has(thread_id):
			awarded_threads.append(thread_id)
	return {
		"chapter_id": chapter_id,
		"available": available,
		"visible": visible,
		"source_visible": source_visible,
		"cleared": cleared,
		"clue_count": int(chapter.clue_count),
		"clue_target": int(chapter_def.clue_target),
		"relic_visible": visible and (normalized.relics as Array).has(relic_id),
		"relic_id": relic_id,
		"restoration_visible": visible,
		"restoration_id": restoration_id,
		"thread_ids": awarded_threads,
		"road_name_id": String(normalized.road_name_id) \
			if chapter_id == UNWRITTEN_ROAD else "",
		"debrief_event": {"key": event_key, "available": event_available},
		"debrief_event_key": event_key,
		"read_only": bool(inspection.read_only),
		"guest": bool(inspection.guest),
		"d2_ineligible": suppress_debrief,
	}

# Neutral host/guest-safe settlement projection for all authored chapters.  It
# carries presentation truth only: callers cannot derive or repair campaign
# state from it.  Top-level chapter aliases make the two current consumers
# convenient without committing the runtime to a future quest framework.
static func settlement_view(state, context: Dictionary = {}) -> Dictionary:
	var normalized := normalize_campaign_state(state)
	var inspection := _inspection_context(context)
	var chapters := {}
	for chapter_id in CHAPTER_ORDER:
		chapters[chapter_id] = _chapter_settlement_view(normalized, chapter_id,
			inspection, context)
	return {
		"available": bool(inspection.available),
		"read_only": bool(inspection.read_only),
		"guest": bool(inspection.guest),
		"road_name_id": String(normalized.road_name_id),
		"loom_state": loom_state(normalized),
		"chapters": chapters,
		FIRST_KNOT: (chapters[FIRST_KNOT] as Dictionary).duplicate(true),
		GOLDEN_WALLOW: (chapters[GOLDEN_WALLOW] as Dictionary).duplicate(true),
		SEVENTH_ROAD: (chapters[SEVENTH_ROAD] as Dictionary).duplicate(true),
		QUEENS_SUMMIT: (chapters[QUEENS_SUMMIT] as Dictionary).duplicate(true),
		PALE_OATH: (chapters[PALE_OATH] as Dictionary).duplicate(true),
		FIRE_IN_THE_BOUGH: (chapters[FIRE_IN_THE_BOUGH] as Dictionary).duplicate(true),
	}

# First Knot Homecoming is a read-only town/Atlas projection.  The campaign
# state remains the only durable authority: this query never repairs a partial
# save, awards an item, or records that a player saw the debrief.  Presentation
# callers may pass their local inspection context without teaching every
# surface how to infer a chapter clear, a legacy migration, or Reprise rules.
static func first_knot_homecoming_view(state, context: Dictionary = {}) -> Dictionary:
	var generic: Dictionary = settlement_view(state, context).first_knot
	# Preserve the First Knot surface byte-for-byte at its public boundary while
	# presenting it through the same neutral chapter projection Golden will use.
	var visible := bool(generic.visible)
	var cleared := bool(generic.cleared)
	return {
		"chapter_id": FIRST_KNOT,
		"available": bool(generic.available),
		"visible": visible,
		"cleared": cleared,
		"rune_visible": bool(generic.relic_visible),
		"rune_id": "green_root_rune",
		"tusk_record_visible": visible and cleared,
		"tusk_record_id": "tusker_tusk",
		"restoration_visible": visible,
		"restoration_id": "trophy_hall",
		"covered_bow_rest_visible": visible,
		"covered_bow_rest_id": "covered_bow_rest",
		"atlas_handoff_visible": visible,
		"atlas_handoff_id": "sallow_shallows",
		"debrief_event": (generic.debrief_event as Dictionary).duplicate(true),
		"debrief_event_key": String(generic.debrief_event_key),
		"read_only": bool(generic.read_only),
		"guest": bool(generic.guest),
		"d2_ineligible": bool(generic.d2_ineligible),
	}
