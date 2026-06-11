extends RefCounted

# Spec 27a — drop tables + roll_drop(). Per-enemy-role drop chance + a
# tier-weighted rarity roll biased by dungeon depth. Returns 0..N concrete
# item instances on a death; 27b wires this into combatant._die().

const Items = preload("res://data/items.gd")

const ROLE_DROP_CHANCE := {
	"combat":   0.50,
	"elite":    1.00,    # spec 32 — elite kills always drop
	"treasure": 1.00,    # treasure rooms intentionally drop
	"shrine":   0.25,
	"boss":     1.00,
}
const ROLE_TIER_BIAS := {   # added to the base 0-9 roll
	"combat":   0,
	"elite":    1,       # spec 32 — magic-leaning floor (below chest, above trash)
	"treasure": 2,
	"shrine":   1,
	"boss":     3,
}
const BOSS_DROP_COUNT := 3   # boss drops several items, always rare+

# Roll the drop pile for an enemy with the given role + depth. May be empty.
static func roll_drop(role: String, depth: int = 0) -> Array:
	var out: Array = []
	var chance: float = ROLE_DROP_CHANCE.get(role, 0.50)
	var count := BOSS_DROP_COUNT if role == "boss" else 1
	for _i in count:
		if randf() > chance:
			continue
		var tier := _roll_tier(role, depth)
		var rarity := _tier_to_rarity(tier)
		var kind_id := _pick_kind()
		var item := Items.make_item(kind_id, rarity)
		if not item.is_empty():
			out.append(item)
	return out

# Base roll = min of two d10 → biased toward 0 (most drops are "normal"),
# then shifted up by role + depth/2. Boss is clamped to ≥8 (rare+).
static func _roll_tier(role: String, depth: int) -> int:
	var base: int = mini(randi() % 10, randi() % 10)
	var bias: int = int(ROLE_TIER_BIAS.get(role, 0)) + (depth / 2)
	var tier: int = base + bias
	if role == "boss" and tier < 8:
		tier = 8
	return clampi(tier, 0, 9)

static func _tier_to_rarity(tier: int) -> String:
	if tier >= 9:
		return "unique"
	if tier == 8:
		return "rare"
	if tier >= 5:
		return "magic"
	return "normal"

static func _pick_kind() -> String:
	# Spec 38 — trade tools are crafted at the anvil, never random loot.
	var ids: Array = Items.kind_ids().filter(func(id):
		return String(Items.KINDS[id].category) not in ["pickaxe", "axe"])
	return ids[randi() % ids.size()]
