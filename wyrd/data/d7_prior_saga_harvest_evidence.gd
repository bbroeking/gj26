class_name D7PriorSagaHarvestEvidence
extends RefCounted

# Browser-marathon evidence policy for the released D3–D6 prior-saga legs.
# The driver is allowed to return an actually empty Briar Maze only after the
# earlier physical Green-Hollow training road has completed every ordinary
# GatherNode family.  Keep the decision pure: Game owns scanner interaction and
# records the receipt, while this seam makes it impossible to conflate an empty
# authored road with a failed visible gather.

const DungeonGenScript = preload("res://scripts/dungeon_gen.gd")
const REQUIRED_SCANNER_KINDS := ["ore_rock", "forage_node", "log_pile"]


static func has_cumulative_scanner_gather_proof(seen_kinds: Dictionary) -> bool:
	for kind in REQUIRED_SCANNER_KINDS:
		if not bool(seen_kinds.get(kind, false)):
			return false
	return true


# `candidate_count` is the number of live production GatherNodes the World
# driver observed; `harvested_count` is the material-delta count from their
# normal scanner channels. A visible node with zero delta is always a failure,
# even if the Chart's Affixes would otherwise permit an empty Briar.
static func evaluate(cfg: Dictionary, candidate_count: int, harvested_count: int,
		seen_kinds: Dictionary) -> Dictionary:
	if harvested_count > 0:
		return {"valid": true, "reason": "production_gather_completed",
			"record_authored_no_gather": false}
	if candidate_count > 0:
		return {"valid": false, "reason": "visible_gather_uncompleted",
			"record_authored_no_gather": false}
	if not DungeonGenScript.allows_authored_zero_production_gather(cfg, candidate_count):
		return {"valid": false, "reason": "not_authored_empty",
			"record_authored_no_gather": false}
	if not has_cumulative_scanner_gather_proof(seen_kinds):
		return {"valid": false, "reason": "missing_cumulative_gather_proof",
			"record_authored_no_gather": false}
	return {"valid": true, "reason": "authored_empty_briar",
		"record_authored_no_gather": true}


# Browser telemetry needs a receipt per allowed empty leg rather than a mutable
# Boolean. This does not decide eligibility; callers may append only after the
# evaluation above returns `record_authored_no_gather`.
static func append_authored_empty_briar_receipt(existing: Array, chart: Dictionary,
		cfg: Dictionary, candidate_count: int, harvested_count: int) -> Array:
	var receipts := existing.duplicate(true)
	receipts.append({
		"recipe_id": String(chart.get("recipe_id", "")),
		"scope": String(cfg.get("scope", "")),
		"candidate_count": candidate_count,
		"harvested_count": harvested_count,
		"affixes": (cfg.get("affixes", []) as Array).duplicate(true),
	})
	return receipts
