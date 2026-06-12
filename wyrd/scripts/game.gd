extends Node

# Wyrd — the cross-scene game state autoload ("Game").
# Owns everything that must survive a change_scene: trades/XP, the materials
# satchel, the chart case, the active run, and the tutorial step. The Player
# node stays scene-local; it pulls hp/inventory/equipment from here in _ready
# and Game snapshots hp back right before a scene change.
#
# Player-facing trade names: carto = "Wayfinding", earth = "Earthcraft",
# wilds = "Wildcraft". XP curve is the three.js prototype's:
# xp_for_level(n) = (n-1)^2 * 8 + (n-1) * 32.

const ChartsData = preload("res://data/charts.gd")
const GatherDefs = preload("res://data/gather.gd")

const TOWN_SCENE := "res://scenes/Town.tscn"
const DUNGEON_SCENE := "res://scenes/World.tscn"

# "Trade" = a leveling discipline (carto / earth / wilds). NOT "skill" —
# that word is reserved for hotbar abilities (CONTEXT.md Language).
const TRADE_NAMES := {
	"carto": "Wayfinder",
	"earth": "Earthcraft",
	"wilds": "Wildcraft",
	"hunt": "Huntcraft",   # B7/ADR 0005 — the one combat trade
}

signal xp_gained(trade: String, amount: int)
signal leveled_up(trade: String, new_lv: int)
signal materials_changed
signal charts_changed
signal gold_changed(amount: int)
signal tutorial_changed(step: int)
signal toast(msg: String)
signal mute_changed(muted: bool)

# Toasts emitted during a scene change land in a HUD that is freed the same
# frame; buffer them and let the next scene's HUD drain the queue in _ready.
var pending_toasts: Array = []
var _defer_toasts := false

func notify(msg: String) -> void:
	if _defer_toasts:
		pending_toasts.append(msg)
	else:
		toast.emit(msg)

func drain_pending_toasts() -> Array:
	_defer_toasts = false
	var out := pending_toasts.duplicate()
	pending_toasts.clear()
	return out

# ---- persistence ----
# Headless tests drive the real autoload through the whole loop — without
# this gate they would both inherit and clobber the player's actual save.
var persistence_enabled := true

func save_now() -> void:
	if persistence_enabled:
		SaveGame.save(self)

# Quitting the window saves whatever the moment held. Closing mid-run keeps
# the chart consumed (keystone V1 ruling) — the save reopens in town.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and persistence_enabled:
		SaveGame.save(self)

# ---- persistent player-adjacent state ----
var trades := {
	"hunt": {"lv": 1, "xp": 0},
	"carto": {"lv": 1, "xp": 0},
	"earth": {"lv": 1, "xp": 0},
	"wilds": {"lv": 1, "xp": 0},
}
var materials: Dictionary = {}        # material id -> count
var charts: Array = []                # crafted chart dicts (the chart case)
var gold := 0                         # Hod's the faucet AND the sink
var summit_cleared := false           # the final chart, charted
var muted := false                    # spec 38 — master audio mute (persisted)
# B5 — the picked skills for hotbar slots 2-4 (slot 1 is always the Bow).
const SKILL_POOL := ["PowerShot", "MultiShot", "BrambleSnare",
	"PiercingBolt", "RainOfThorns"]
var loadout: Array = ["PowerShot", "MultiShot", "BrambleSnare"]
var seen_hints: Dictionary = {}       # one-time skill tutorials already shown
var inventory: Inventory = null       # Tetris gear grid — shared across scenes
var equipment = null                  # Equipment — shared across scenes
var player_hp := -1                   # -1 = "full" (first boot)

# ---- the active run ----
var active_chart: Dictionary = {}     # {} = not in a chart run (town / dev boot)
var in_dungeon := false

# ---- per-skill first-time tutorials ----
# The first harvest of each kind earns a short word from the right
# neighbor. Shown once ever (persisted).
const SKILL_HINTS := {
	"forage_node": ["Mara Linnet, the Wayfinder", [
		"Good eye. Three of those wild herbs crush down into a pot of hedge ink at my table.",
		"Herbs make ink, ink makes charts. Wildcraft grows with every handful — check your Trades page (K).",
	]],
	"ore_rock": ["Old Hod Tenter", [
		"Bogiron. Rust-heavy, stubborn — good. That's Earthcraft settling into your wrists.",
		"Two lumps grind into stoneground ink, which pulls a chart toward the mineral seams. Or sell it to me at 7g if you'd rather. The hollows carry richer veins than my spoil heap.",
	]],
	"log_pile": ["Mara Linnet, the Wayfinder", [
		"Split logs — Wildcraft counts the axe-work too.",
		"Wood Grove charts grow them three piles at a time. For now the cottage pile regrows as fast as anyone honest needs.",
	]],
	"cookfire": ["Mara Linnet, the Wayfinder", [
		"The hearth takes herbs and a log and gives back a draught — drink it with Q when the hollows bite.",
		"Cooking feeds Wildcraft same as foraging does. A full bottle has saved more wayfinders than any sword.",
	]],
	"bench": ["Mara Linnet, the Wayfinder", [
		"The bench works by hand: set a chart base in the big socket, pour inks into the rounds, and the finished chart waits on the right.",
		"The pot takes raw makings — three herbs become hedge ink. Trophies fit the diamond socket, and they promise a den.",
	]],
	"forge": ["Old Hod Tenter", [
		"Two lumps of bogiron smelt down to a bar. Bars become gear — that's the whole trade, and it's a good one.",
		"Earthcraft levels open the deeper recipes. Bring me ore or bring me patience.",
	]],
}

func first_time_hint(kind: String) -> void:
	if seen_hints.get(kind, false) or not SKILL_HINTS.has(kind):
		return
	seen_hints[kind] = true
	save_now()
	var hint: Array = SKILL_HINTS[kind]
	var dlg: CanvasLayer = load("res://scripts/ui/dialog_panel.gd").new()
	dlg.open(String(hint[0]), hint[1])
	var scn := get_tree().current_scene
	if scn != null:
		scn.add_child(dlg)

# ---- tutorial ----
# Steps: 0 talk · 1 forage 3 herbs · 2 mix ink · 3 inscribe Snug ·
# 4 socket + enter · 5 reach the far waystone · 6 inscribe a Tier 1 · 7 done
const TUTORIAL_OBJECTIVES := [
	"Speak with Mara Linnet, the Wayfinder",
	"Forage 3 wild herbs from the yard",
	"Mix a pot of hedge ink at the Inscribing Table",
	"Inscribe a Snug chart at the Inscribing Table",
	"Socket your chart at the Waystone and step through",
	"Find the far waystone",
	"Inscribe a Tier 1 chart — this time with an affix",
	"",
]
var tutorial_step := 0

func _ready() -> void:
	# Inventory/Equipment classes come from the existing spec-27 scripts.
	inventory = Inventory.new()
	var EquipmentScript = load("res://scripts/equipment.gd")
	equipment = EquipmentScript.new()
	# Wyrd — restore the last session before anything else reads state.
	if OS.get_environment("WYRD_NO_SAVE") != "":
		persistence_enabled = false
	elif SaveGame.load_into(self):
		print("[game] session restored (tutorial step %d)" % tutorial_step)
	AudioServer.set_bus_mute(0, muted)   # spec 38 — restore the mute state
	# Spec 41 — the kit cursor takes over in-game (interact/attack swaps
	# are a followup; the controller can call set_cursor as states land).
	if ResourceLoader.exists("res://assets/ui/cursor_default.png"):
		Input.set_custom_mouse_cursor(load("res://assets/ui/cursor_default.png"),
			Input.CURSOR_ARROW, Vector2(3, 2))
	# Dev: WYRD_DEV_CHART=<template_id> boots straight into a chart run with
	# every gather affix landed good — visual checks without the town loop.
	var dev_chart := OS.get_environment("WYRD_DEV_CHART")
	if dev_chart != "" and ChartsData.TEMPLATES.has(dev_chart):
		var t: Dictionary = ChartsData.TEMPLATES[dev_chart]
		active_chart = {
			"template_id": dev_chart, "tier": int(t.tier),
			"scope": String(t.scope), "name": String(t.name), "seed": 12345,
			"affixes": [
				{"id": "mineral_vein", "good": true, "resolvedId": "mineral_vein"},
				{"id": "wood_grove", "good": true, "resolvedId": "wood_grove"},
				{"id": "bramble_bloom", "good": true, "resolvedId": "bramble_bloom"},
			],
		}
		# Dev: WYRD_DEV_BOSS=<den affix id> forces that boss into the run —
		# B4a playtests: WYRD_DEV_CHART=tier_1 WYRD_DEV_BOSS=burrow_boar_den.
		var dev_boss := OS.get_environment("WYRD_DEV_BOSS")
		if dev_boss != "" and ChartsData.AFFIXES.has(dev_boss):
			(active_chart.affixes as Array).append(
				{"id": dev_boss, "good": true, "resolvedId": dev_boss})
		in_dungeon = true
		tutorial_step = TUTORIAL_OBJECTIVES.size() - 1
		get_tree().change_scene_to_file.call_deferred(DUNGEON_SCENE)

# B5 — swap the loadout (validated against the pool; exactly 3, no dupes).
func set_loadout(picks: Array) -> bool:
	if picks.size() != 3:
		return false
	var seen := {}
	for sk in picks:
		if not SKILL_POOL.has(String(sk)) or seen.has(sk):
			return false
		seen[sk] = true
	loadout = picks.duplicate()
	save_now()
	if is_inside_tree():
		var player := get_tree().get_first_node_in_group("player")
		if player != null and player.has_method("rebuild_skills"):
			player.rebuild_skills()
		notify("Loadout set: %s." % ", ".join(picks))
	return true

# Spec 38 — master mute. One bus flip silences the SFX pool and the music
# channel together; the state rides the save like any other preference.
func set_muted(m: bool) -> void:
	muted = m
	AudioServer.set_bus_mute(0, muted)
	mute_changed.emit(muted)
	save_now()

# ---- trades (leveling) ----

static func xp_for_level(n: int) -> int:
	var k := n - 1
	return k * k * 8 + k * 32

func trade_lv(key: String) -> int:
	return int(trades.get(key, {}).get("lv", 1))

func award_xp(key: String, amount: int) -> void:
	if amount <= 0 or not trades.has(key):
		return
	trades[key].xp += amount
	xp_gained.emit(key, amount)
	while trades[key].xp >= xp_for_level(int(trades[key].lv) + 1):
		trades[key].lv += 1
		leveled_up.emit(key, int(trades[key].lv))
		notify("%s rises to %d" % [TRADE_NAMES.get(key, key), int(trades[key].lv)])
		var sfx_lv := get_node_or_null("/root/Sfx")
		if sfx_lv != null:
			sfx_lv.play("level_up")

# ---- materials satchel ----

func material_count(id: String) -> int:
	return int(materials.get(id, 0))

func add_material(id: String, n: int = 1) -> void:
	if n <= 0:
		return
	materials[id] = material_count(id) + n
	materials_changed.emit()
	_tutorial_check_materials()

func spend_materials(cost: Dictionary) -> bool:
	for id in cost:
		if material_count(String(id)) < int(cost[id]):
			return false
	for id in cost:
		materials[String(id)] = material_count(String(id)) - int(cost[id])
		if materials[String(id)] <= 0:
			materials.erase(String(id))
	materials_changed.emit()
	return true

func can_afford(cost: Dictionary) -> bool:
	for id in cost:
		if material_count(String(id)) < int(cost[id]):
			return false
	return true

# ---- the gold economy (Hod's counter) ----

# Sell a gear item out of the Tetris inventory. Returns the price paid.
func sell_item(item: Dictionary) -> int:
	if inventory == null or not inventory.items.has(item):
		return 0
	var price := EconomyData.sell_value(item)
	inventory.remove(item)
	gold += price
	gold_changed.emit(gold)
	save_now()
	return price

# Buy a material off Hod's shelf. Returns false if gold is short.
func buy_ware(id: String, price: int) -> bool:
	if gold < price:
		return false
	gold -= price
	gold_changed.emit(gold)
	add_material(id, 1)
	save_now()
	return true

# ---- ink mixing ----

# ---- crafting stations (A7/A8-lite) ----
const CraftingDefs = preload("res://data/crafting.gd")

# Craft a recipe at a station. Returns false (with a toast) when gated,
# unaffordable, or the pack has no room for a gear yield.
func craft(station_id: String, recipe_id: String) -> bool:
	var st: Dictionary = CraftingDefs.station(station_id)
	var rec: Dictionary = CraftingDefs.recipe(recipe_id)
	if st.is_empty() or rec.is_empty():
		return false
	if not (st.recipes as Array).has(recipe_id):
		return false
	var trade := String(st.trade)
	if trade_lv(trade) < int(rec.get("req_lv", 1)):
		notify("%s asks for %s %d." % [String(rec.name),
			TRADE_NAMES.get(trade, trade), int(rec.get("req_lv", 1))])
		return false
	if not can_afford(rec.inputs):
		return false
	var made_item: Dictionary = {}
	if rec.has("yields_item"):
		# Reserve pack space BEFORE spending — no materials lost to a full pack.
		var ItemsData = load("res://data/items.gd")
		made_item = ItemsData.make_item(String(rec.yields_item.kind),
			String(rec.yields_item.rarity))
		var fit: Dictionary = inventory.find_first_fit(made_item)
		if fit.is_empty():
			notify("Your pack has no room for the %s." % String(rec.name))
			return false
		spend_materials(rec.inputs)
		inventory.try_place(made_item, fit.pos, fit.rotated)
		notify("Forged: %s." % String(made_item.get("name", rec.name)))
	else:
		spend_materials(rec.inputs)
		add_material(String(rec.yields_material), int(rec.get("yields_n", 1)))
		notify("Made %s." % GatherDefs.material_name(String(rec.yields_material)))
	var sfx := get_node_or_null("/root/Sfx")
	if sfx != null:
		sfx.play("craft_cook" if station_id == "cookfire" else "craft_smith")
	award_xp(trade, int(rec.get("xp", 0)))
	save_now()
	return true

# ---- per-trade level perks (A9) ----
const PERKS := {
	"earth": [
		{"id": "double_ore", "lv": 5, "name": "Sturdy Swings",
			"desc": "25% chance a vein gives a second lump"},
		{"id": "quick_mining", "lv": 10, "name": "Miner's Rhythm",
			"desc": "Mining takes a third less time"},
	],
	"wilds": [
		{"id": "keen_eye", "lv": 5, "name": "Keen Eye",
			"desc": "+1 herb on every forage"},
		{"id": "clean_splits", "lv": 10, "name": "Clean Splits",
			"desc": "+1 log on every chop"},
	],
	"hunt": [
		{"id": "steady_hands", "lv": 5, "name": "Steady Hands",
			"desc": "+5% crit chance"},
		{"id": "hunters_stride", "lv": 10, "name": "Hunter's Stride",
			"desc": "+5% move speed"},
	],
}

func perk_active(trade: String, perk_id: String) -> bool:
	for perk in PERKS.get(trade, []):
		if String(perk.id) == perk_id:
			return trade_lv(trade) >= int(perk.lv)
	return false

# Bonus yield for one harvest of `kind` — deterministic perks return 1,
# chance perks roll here so GatherNode stays dumb.
func gather_bonus(kind: String) -> int:
	match kind:
		"forage_node":
			return 1 if perk_active("wilds", "keen_eye") else 0
		"log_pile":
			return 1 if perk_active("wilds", "clean_splits") else 0
		"ore_rock":
			if perk_active("earth", "double_ore") and randf() < 0.25:
				return 1
	return 0

# ---- draughts (the sustain verb) ----
# Smallest sufficient bottle first; returns the heal amount (0 = none had).
func quaff_draught() -> int:
	for id in CraftingDefs.DRAUGHT_ORDER:
		if material_count(String(id)) > 0:
			spend_materials({id: 1})
			notify("You quaff a %s." % GatherDefs.material_name(String(id)))
			save_now()
			return int(CraftingDefs.DRAUGHTS[id])
	notify("No draughts in the satchel — the hearth makes them.")
	return 0

func mix_ink(ink_id: String) -> bool:
	var recipe: Dictionary = GatherDefs.INK_RECIPES.get(ink_id, {})
	if recipe.is_empty():
		return false
	if not spend_materials(recipe.inputs):
		return false
	add_material(ink_id, int(recipe.get("yields", 1)))
	notify("Mixed a pot of %s." % GatherDefs.material_name(ink_id))
	if tutorial_step == 2 and ink_id == "hedge_ink":
		advance_tutorial()
	save_now()
	return true

# ---- chart case ----

func add_chart(chart: Dictionary) -> void:
	charts.append(chart)
	charts_changed.emit()
	notify("Inscribed: %s" % ChartsData.chart_label(chart))
	if tutorial_step == 3 and String(chart.get("template_id", "")) == "snug":
		advance_tutorial()
	elif tutorial_step == 6 and String(chart.get("template_id", "")) != "snug":
		advance_tutorial()
	save_now()

# ---- the run ----

# Socket a chart at the Waystone: consume it, snapshot the player, swap scenes.
func enter_dungeon(chart: Dictionary, player: Node) -> void:
	_defer_toasts = true       # the dungeon HUD will drain these in _ready
	charts.erase(chart)
	charts_changed.emit()
	active_chart = chart
	in_dungeon = true
	_snapshot_player(player)
	if tutorial_step == 4:
		advance_tutorial()
	# A fresh run never inherits a stale in-dungeon checkpoint.
	var cp := get_node_or_null("/root/Checkpoint")
	if cp != null and cp.has_method("clear"):
		cp.clear()
	save_now()
	# Deferred — interactables call this from physics processing.
	get_tree().change_scene_to_file.call_deferred(DUNGEON_SCENE)

# Step back through the far waystone. Completion XP per the shipped formula.
func return_to_town(player: Node) -> void:
	_defer_toasts = true       # the town HUD will drain these in _ready
	if not active_chart.is_empty():
		var xp := ChartsData.completion_xp(active_chart)
		award_xp("carto", xp)
		notify("Chart complete — %d Wayfinder XP." % xp)
		# The end the whole chain builds toward.
		if String(active_chart.get("template_id", "")) == "summit" \
				and not summit_cleared:
			summit_cleared = true
			notify("★ The Summit is charted. The Queen's nest stands empty.")
			notify("Mara will want to hear of this.")
	active_chart = {}
	in_dungeon = false
	_snapshot_player(player)
	if tutorial_step == 5:
		advance_tutorial()
	var cp := get_node_or_null("/root/Checkpoint")
	if cp != null and cp.has_method("clear"):
		cp.clear()
	save_now()
	# Deferred — the exit waystone calls this from physics processing.
	get_tree().change_scene_to_file.call_deferred(TOWN_SCENE)

# The generation config handed to DungeonGen.generate(). {} when booting
# World.tscn directly (dev) — which keeps today's defaults, boss included.
func run_cfg() -> Dictionary:
	if active_chart.is_empty():
		return {}
	var t: Dictionary = ChartsData.TEMPLATES.get(String(active_chart.template_id), {})
	var cfg: Dictionary = (t.get("gen", {}) as Dictionary).duplicate()
	cfg["tier"] = int(active_chart.get("tier", 1))
	cfg["scope"] = String(active_chart.get("scope", "crypt"))
	cfg["affixes"] = active_chart.get("affixes", [])
	cfg["seed"] = int(active_chart.get("seed", -1))
	# Boss-as-affix: no boss unless a den's good twin landed — except
	# templates that name their own boss in the gen block (the Summit).
	if not cfg.has("boss_kind"):
		cfg["boss_kind"] = ""
	const DEN_TO_BOSS := {
		"hedgemother_den": "hedgemother",
		"burrow_boar_den": "burrow_boar",
		"wolf_alpha_den": "wolf_alpha",
	}
	for a in cfg["affixes"]:
		if bool(a.get("good", false)) and DEN_TO_BOSS.has(String(a.get("id", ""))):
			cfg["boss_kind"] = DEN_TO_BOSS[String(a.get("id", ""))]
	return cfg

func is_boss_den_affix(id: String) -> bool:
	return id in ["hedgemother_den", "burrow_boar_den", "wolf_alpha_den"]

func affix_good(id: String) -> bool:
	for a in active_chart.get("affixes", []):
		if String(a.get("id", "")) == id and bool(a.get("good", false)):
			return true
	return false

func affix_bad(id: String) -> bool:
	for a in active_chart.get("affixes", []):
		if String(a.get("id", "")) == id and not bool(a.get("good", false)):
			return true
	return false

# ---- player snapshot ----

func _snapshot_player(player: Node) -> void:
	if player != null and is_instance_valid(player):
		player_hp = int(player.get("hp"))
		# The scene change is deferred — a hit (or death) landing in the gap
		# would be silently dropped. I-frame the player through the gap.
		player.set("_iframe_t", 999.0)

# Player calls this from _ready. Restores hp; inventory/equipment are
# already shared references owned here.
func restore_player(player: Node) -> void:
	if player_hp > 0:
		player.set("hp", player_hp)

# ---- tutorial ----

func advance_tutorial() -> void:
	if tutorial_step >= TUTORIAL_OBJECTIVES.size() - 1:
		return
	tutorial_step += 1
	tutorial_changed.emit(tutorial_step)
	# A step may already be satisfied by out-of-order play (herbs foraged
	# before talking to Mara, a Snug inscribed early) — re-check on entry.
	_tutorial_check_satisfied()

func objective_text() -> String:
	if tutorial_step < 0 or tutorial_step >= TUTORIAL_OBJECTIVES.size():
		return ""
	# Town objectives can't be acted on mid-run — point at the exit instead.
	if in_dungeon and tutorial_step < 5:
		return TUTORIAL_OBJECTIVES[5]
	var text := String(TUTORIAL_OBJECTIVES[tutorial_step])
	# Post-tutorial: the standing quest is the chart chain itself.
	if text == "" and not summit_cleared:
		return "Chart your way to the Summit — trophies ink the deeper dens"
	return text

# Live counter suffix for the tracker ("2/3 herbs"). Empty when the step
# has no countable goal.
func objective_progress() -> String:
	if in_dungeon:
		return ""
	match tutorial_step:
		1: return "%d / 3 herbs" % mini(3, material_count("wild_herb"))
		2: return "%d / 1 hedge ink" % mini(1, material_count("hedge_ink"))
		3: return "%d / 1 chart" % mini(1, charts.size())
		_: return ""

func _tutorial_check_materials() -> void:
	_tutorial_check_satisfied()

func _tutorial_check_satisfied() -> void:
	if tutorial_step == 1 and material_count("wild_herb") >= 3:
		advance_tutorial()
	elif tutorial_step == 3 and _has_chart("snug"):
		advance_tutorial()

func _has_chart(template_id: String) -> bool:
	for c in charts:
		if String(c.get("template_id", "")) == template_id:
			return true
	return false
