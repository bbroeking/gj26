extends SceneTree

# Wyrd — economy unit tests (impl-system-economy).
# Run: WYRD_NO_SAVE=1 godot --headless --path wyrd --script res://test_economy.gd
#
# Covers: ware_min_lv, chart_entry_fee, wares_for_level,
#         sell_value backward-compat, WARES backward-compat alias.
# Does NOT cover game.gd buy/sell gates (those need game.gd edits — deferred).

const EconomyData = preload("res://data/economy.gd")

var _pass := 0
var _fail := 0

func _check(name: String, ok: bool, detail: String = "") -> void:
	if ok:
		_pass += 1
		print("  ✓ %s" % name)
	else:
		_fail += 1
		print("  ✗ %s %s" % [name, detail])

func _init() -> void:
	print("--- economy gate check ---")
	_test_ware_min_lv()
	_test_chart_entry_fee()
	_test_wares_for_level()
	_test_compat_alias()
	_test_sell_value()
	print("--- %d passed, %d failed ---" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)

func _test_ware_min_lv() -> void:
	print("[ware_min_lv]")
	_check("wild_herb min lv = 1",
		EconomyData.ware_min_lv("wild_herb") == 1,
		str(EconomyData.ware_min_lv("wild_herb")))
	_check("logs min lv = 1",
		EconomyData.ware_min_lv("logs") == 1)
	_check("bogiron_ore min lv = 2",
		EconomyData.ware_min_lv("bogiron_ore") == 2,
		str(EconomyData.ware_min_lv("bogiron_ore")))
	_check("hedge_ink min lv = 2",
		EconomyData.ware_min_lv("hedge_ink") == 2)
	_check("stoneground_ink min lv = 4",
		EconomyData.ware_min_lv("stoneground_ink") == 4,
		str(EconomyData.ware_min_lv("stoneground_ink")))
	_check("refined_ink min lv = 6",
		EconomyData.ware_min_lv("refined_ink") == 6,
		str(EconomyData.ware_min_lv("refined_ink")))
	_check("hedgesteel_ore min lv = 8",
		EconomyData.ware_min_lv("hedgesteel_ore") == 8,
		str(EconomyData.ware_min_lv("hedgesteel_ore")))
	_check("unknown ware defaults to 1",
		EconomyData.ware_min_lv("nonexistent_widget") == 1)

func _test_chart_entry_fee() -> void:
	print("[chart_entry_fee]")
	_check("tier 1 fee = 0",
		EconomyData.chart_entry_fee(1) == 0,
		str(EconomyData.chart_entry_fee(1)))
	_check("tier 2 fee = 15",
		EconomyData.chart_entry_fee(2) == 15,
		str(EconomyData.chart_entry_fee(2)))
	_check("tier 3 fee = 30",
		EconomyData.chart_entry_fee(3) == 30,
		str(EconomyData.chart_entry_fee(3)))
	_check("unknown tier defaults to 0",
		EconomyData.chart_entry_fee(99) == 0,
		str(EconomyData.chart_entry_fee(99)))

func _test_wares_for_level() -> void:
	print("[wares_for_level]")
	var lv1: Array = EconomyData.wares_for_level(1)
	# lv1: wild_herb, logs, bogiron_ore, hedge_ink + repair_all = 5
	_check("lv 1 shelf = 5 wares", lv1.size() == 5,
		str(lv1.size()))
	# Check repair_all is always last
	_check("repair_all always on the shelf",
		String(lv1[lv1.size() - 1].id) == "repair_all")
	var lv4: Array = EconomyData.wares_for_level(4)
	# lv4: adds stoneground_ink → 6
	_check("lv 4 shelf = 6 wares", lv4.size() == 6,
		str(lv4.size()))
	var lv6: Array = EconomyData.wares_for_level(6)
	# lv6: adds refined_ink → 7
	_check("lv 6 shelf = 7 wares", lv6.size() == 7,
		str(lv6.size()))
	var lv8: Array = EconomyData.wares_for_level(8)
	# lv8: adds hedgesteel_ore → 8
	_check("lv 8 shelf = 8 wares", lv8.size() == 8,
		str(lv8.size()))
	# Every ware has id and price keys.
	var all_have_keys := true
	for w in lv8:
		if not (w.has("id") and w.has("price")):
			all_have_keys = false
	_check("every ware has id + price", all_have_keys)
	# Prices are positive ints.
	var prices_ok := true
	for w in lv8:
		if int(w.price) <= 0:
			prices_ok = false
	_check("all prices positive", prices_ok)
	# Anti-arbitrage: for every ware also in WARES (the compat array), the
	# wares_for_level price must equal the WARES price (no silent drift).
	var compat_prices: Dictionary = {}
	for w in EconomyData.WARES:
		compat_prices[String(w.id)] = int(w.price)
	var drift_ok := true
	for w in lv8:
		var wid := String(w.id)
		if compat_prices.has(wid) and int(w.price) != int(compat_prices[wid]):
			drift_ok = false
	_check("wares_for_level prices match WARES for shared ids", drift_ok)

func _test_compat_alias() -> void:
	print("[WARES backward-compat]")
	_check("WARES has 6 entries", (EconomyData.WARES as Array).size() == 6,
		str((EconomyData.WARES as Array).size()))
	var ids: Array = []
	for w in EconomyData.WARES:
		ids.append(String(w.id))
	_check("WARES contains refined_ink", ids.has("refined_ink"))
	_check("WARES contains wild_herb",   ids.has("wild_herb"))
	_check("WARES contains hedge_ink",   ids.has("hedge_ink"))
	# repair_all must NOT appear in WARES (it's only in wares_for_level)
	# so the _test_economy_gate loop in test_wyrd_loop stays clean.
	_check("repair_all absent from WARES", not ids.has("repair_all"))

func _test_sell_value() -> void:
	print("[sell_value]")
	_check("normal sells 4",  EconomyData.sell_value({"rarity": "normal"}) == 4)
	_check("magic sells 12",  EconomyData.sell_value({"rarity": "magic"})  == 12)
	_check("rare sells 35",   EconomyData.sell_value({"rarity": "rare"})   == 35)
	_check("unique sells 90", EconomyData.sell_value({"rarity": "unique"}) == 90)
	_check("missing rarity defaults to 4",
		EconomyData.sell_value({}) == 4)
