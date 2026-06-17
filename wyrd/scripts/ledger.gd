extends RefCounted

# ADR 0013 power source #3 — the Ledger: boss-trophy flat stat boosts.
# Each defeated boss's trophy fills one slot (trophy_id -> {stat, value}); the
# slots sum into the player's derived_stats alongside gear, shrine buffs, and
# Wayfinding-level scaling. Per-stat CAPS stop the chain from stacking
# unbounded. One slot per trophy id, so re-claiming a trophy is idempotent.
#
# Owned by the Game autoload (`Game.ledger`); applied on boss death in
# layout_loader; summed in player_controller._derive_stats; persisted in
# save_game. Auto-assigned for now — a player-chosen boon per trophy is a
# noted follow-up (see impl-system-items-affixes "Risks").

const TROPHY_GRANTS := {
	"thorn_essence": {"stat": "damage",      "value": 4.0},    # the Hedgemother
	"tusker_tusk":   {"stat": "hp",          "value": 12.0},   # the Burrow Boar
	"wightpelt":     {"stat": "crit_chance", "value": 0.05},   # the Wolf Alpha line
	"alpha_fang":    {"stat": "crit_mult",   "value": 0.25},   # the Pack Alpha
}
# Per-stat ceilings (matches the derived_stats sums-dict keys).
const CAPS := {"damage": 15.0, "hp": 40.0, "crit_chance": 0.15,
	"crit_mult": 0.50, "move_speed": 0.10}

var slots: Dictionary = {}   # trophy_id -> {"stat": String, "value": float}

# Claim a boss trophy. Unknown ids are ignored; re-claiming is idempotent.
func apply(trophy_id: String) -> bool:
	if not TROPHY_GRANTS.has(trophy_id):
		return false
	slots[trophy_id] = (TROPHY_GRANTS[trophy_id] as Dictionary).duplicate()
	return true

# Sum every slot's stat, clamped to CAPS. Keys match _derive_stats' sums dict.
func sum_stats() -> Dictionary:
	var out: Dictionary = {}
	for tid in slots:
		var g: Dictionary = slots[tid]
		var st := String(g.get("stat", ""))
		if st == "":
			continue
		out[st] = float(out.get(st, 0.0)) + float(g.get("value", 0.0))
	for st in out:
		if CAPS.has(st):
			out[st] = minf(float(out[st]), float(CAPS[st]))
	return out

# Restore from a saved slots dict (save_game load path).
func load_slots(saved: Dictionary) -> void:
	slots = {}
	for tid in saved:
		var g = saved[tid]
		if g is Dictionary and g.has("stat"):
			slots[String(tid)] = {"stat": String(g.stat), "value": float(g.value)}
