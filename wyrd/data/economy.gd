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
	return int(SELL_BY_RARITY.get(String(item.get("rarity", "normal")), 4))

# What Hod sells, in shelf order. Roughly 3-4× what gathering "costs" in
# time so the satchel stays the primary source. Boss trophies are NEVER
# sold — the chain only passes through the hollows.
const WARES := [
	{"id": "wild_herb", "price": 3},
	{"id": "logs", "price": 4},
	{"id": "bogiron_ore", "price": 7},
	{"id": "hedge_ink", "price": 12},
	{"id": "stoneground_ink", "price": 18},
	{"id": "refined_ink", "price": 38},
]
