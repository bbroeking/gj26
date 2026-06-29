extends RefCounted

# Spec 27a — drop tables + roll_drop(). Per-enemy-role drop chance + a
# tier-weighted rarity roll biased by dungeon depth. Returns 0..N concrete
# item instances on a death; 27b wires this into combatant._die().

const Items = preload("res://data/items.gd")
const EnchantDefs = preload("res://data/enchants.gd")

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
static func roll_drop(role: String, depth: int = 0, tier_bonus: int = 0) -> Array:
	var out: Array = []
	var chance: float = ROLE_DROP_CHANCE.get(role, 0.50)
	var count := BOSS_DROP_COUNT if role == "boss" else 1
	for _i in count:
		if randf() > chance:
			continue
		var tier := _roll_tier(role, depth, tier_bonus)
		var rarity := _tier_to_rarity(tier)
		var kind_id := _pick_kind(depth)
		var item := Items.make_item(kind_id, rarity)
		if not item.is_empty():
			out.append(item)
	return out

# Base roll = min of two d10 → biased toward 0 (most drops are "normal"),
# then shifted up by role + depth/2. Boss is clamped to ≥8 (rare+).
static func _roll_tier(role: String, depth: int, tier_bonus: int = 0) -> int:
	var base: int = mini(randi() % 10, randi() % 10)
	# C11 — an elite modifier's reward_tier_bonus lifts the rarity floor.
	var bias: int = int(ROLE_TIER_BIAS.get(role, 0)) + (depth / 2) + tier_bonus
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

# The kinds that CAN drop as random loot — the single source of truth.
# Spec 38: trade tools are crafted at the anvil, never random loot. E17: the
# capstone gear (warbow / starsilver_band) is forged too. Used by _pick_kind
# and by tests so the "what drops" rule lives in exactly one place.
static func droppable_kinds() -> Array:
	return Items.kind_ids().filter(func(id):
		return String(Items.KINDS[id].category) not in ["pickaxe", "axe"] \
			and String(id) not in ["warbow", "starsilver_band"])

# C11/D12 — the better droppable kinds unlock with depth, so a fresh den drops
# shortbow + leather and deeper dens start handing out longbows + rings. Loot
# tiers by depth instead of the same 6-kind pool from lv 1 to 17.
const KIND_DEPTH_MIN := {
	"longbow":     4,
	"copper_ring": 3,
	"leather_chest": 2,
}

static func _pick_kind(depth: int = 99) -> String:
	var ids: Array = droppable_kinds().filter(func(id):
		return depth >= int(KIND_DEPTH_MIN.get(String(id), 0)))
	if ids.is_empty():
		ids = droppable_kinds()
	return ids[randi() % ids.size()]

# ---- enchant economy: the delving faucet (the other half of the mixed
# source — the bench crafts reagents, the dungeon also hands them out, and
# elites/bosses TEACH the rare/unique charms). Pure rolls; combatant._die
# routes the results into Game.add_material / Game.discover_enchant. ----

# Common reagents that can drop while delving (the bench crafts these too).
const REAGENT_POOL := ["glimmerdust", "emberglass", "dewthread"]
const REAGENT_DROP_CHANCE := {
	"combat": 0.12, "elite": 0.60, "treasure": 0.45, "shrine": 0.0, "boss": 1.0,
}

# Roll a small reagent payout for a kill/open. Returns {mat_id: count} (may be
# empty). Boss kills pour more; deeper dens pour a touch more on top.
static func roll_reagents(role: String, depth: int = 0, _tier_bonus: int = 0) -> Dictionary:
	var out: Dictionary = {}
	if randf() > float(REAGENT_DROP_CHANCE.get(role, 0.0)):
		return out
	var n := 1
	if role == "boss":
		n = 2 + (depth / 4)
	elif role == "elite" and randf() < 0.4:
		n = 2
	var mid: String = REAGENT_POOL[randi() % REAGENT_POOL.size()]
	out[mid] = n
	return out

# Elites can TEACH a rare charm; bosses always teach a unique. Returns enchant
# ids to add to Game.discovered_enchants (idempotent on the Game side).
static func roll_enchant_discovery(role: String, _depth: int = 0, _tier_bonus: int = 0) -> Array:
	var out: Array = []
	if role == "boss":
		var uniques: Array = _enchants_of_tier("unique")
		if not uniques.is_empty():
			out.append(uniques[randi() % uniques.size()])
		# A boss also tends to leave a rare in its wake.
		var rares: Array = _enchants_of_tier("rare")
		if not rares.is_empty() and randf() < 0.5:
			out.append(rares[randi() % rares.size()])
	elif role == "elite" and randf() < 0.35:
		var rares2: Array = _enchants_of_tier("rare")
		if not rares2.is_empty():
			out.append(rares2[randi() % rares2.size()])
	return out

static func _enchants_of_tier(t: String) -> Array:
	return (EnchantDefs.ENCHANT_ORDER as Array).filter(func(id):
		return EnchantDefs.tier(String(id)) == t)
