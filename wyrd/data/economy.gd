class_name EconomyData
extends RefCounted

# Wyrd — the gold economy. Selling dungeon gear to Hod is the gold faucet;
# his wares (raw materials + inks) are the sink. Prices deliberately favor
# gathering your own materials — buying is a convenience tax, not a bypass
# of the chart loop.

# Sell value of a gear item by rarity (the smith melts it down).
const SELL_BY_RARITY := {
	"normal": 4,
	"magic": 12,
	"rare": 35,
	"unique": 90,
}

static func sell_value(item: Dictionary) -> int:
	if not bool(item.get("sellable", true)):
		return 0
	return int(SELL_BY_RARITY.get(String(item.get("rarity", "normal")), 4))

# Minimum Wayfinding level required to buy each ware from Hod.
# The gate ensures buying is a convenience bypass only for materials a player
# could already gather, not a shortcut past the gather loop entirely.
const _WARE_MIN_LV := {
	"wild_herb":       1,
	"logs":            1,
	"bogiron_ore":     2,
	"hedge_ink":       2,
	"stoneground_ink": 4,
	"refined_ink":     6,
	"hedgesteel_ore":  8,
	"repair_all":      1,
}

static func ware_min_lv(id: String) -> int:
	return int(_WARE_MIN_LV.get(id, 1))

# Chart-entry gold fees by tier. Tier 1 is always free (the snug/hollow range).
# Fee waived by boss trophy is handled in game.gd:enter_dungeon once the trophy
# system ships (impl-system-bosses); here we just define the table.
const CHART_TIER_FEE := {1: 0, 2: 15, 3: 30}

static func chart_entry_fee(tier: int) -> int:
	return int(CHART_TIER_FEE.get(tier, 0))

# What Hod sells, scaled to the player's Wayfinding level.
# Deeper materials unlock as the player levels — buying them is still a
# convenience tax (prices stay 3-4× effective gather time-cost), but a
# fresh character can't bypass the early gather loop by buying stacks of
# advanced inks outright.
# repair_all is always appended so Hod's shelf always has a gold sink.
static func wares_for_level(lv: int) -> Array:
	var w: Array = [
		{"id": "wild_herb",   "price": 3},
		{"id": "logs",        "price": 4},
		{"id": "bogiron_ore", "price": 7},
		{"id": "hedge_ink",   "price": 12},
	]
	if lv >= 4:
		w.append({"id": "stoneground_ink", "price": 18})
	if lv >= 6:
		w.append({"id": "refined_ink", "price": 38})
	if lv >= 8:
		w.append({"id": "hedgesteel_ore", "price": 22})
	w.append({"id": "repair_all", "price": 20, "label": "Repair all gear"})
	return w

# Backward-compat alias: callers that iterate EconomyData.WARES (game.gd
# _cheapest_material, test_wyrd_loop _test_economy_gate) see the base shelf.
# New call-sites should use wares_for_level(lv) instead.
const WARES := [
	{"id": "wild_herb",       "price": 3},
	{"id": "logs",            "price": 4},
	{"id": "bogiron_ore",     "price": 7},
	{"id": "hedge_ink",       "price": 12},
	{"id": "stoneground_ink", "price": 18},
	{"id": "refined_ink",     "price": 38},
]
