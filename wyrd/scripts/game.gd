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

# ADR 0012 — the four trades (carto/earth/wilds/hunt) are compressed into ONE
# leveling skill, "Wayfinding": every cozy activity (gather, craft, forage,
# chart) feeds it; combat gives NO skill XP. One unified perk ladder.
const SKILL := "wayfinding"
const TRADE_NAMES := {
	"wayfinding": "Wayfinding",
}

signal xp_gained(trade: String, amount: int)
signal leveled_up(trade: String, new_lv: int)
signal materials_changed
signal charts_changed
signal gold_changed(amount: int)
signal tutorial_changed(step: int)
signal toast(msg: String)
signal mute_changed(muted: bool)
# Mastery (ADR 0012 pick-one-of-N): fires when a level-up reaches a choice
# tier so the HUD can prompt; perks_changed re-derives cached combat stats
# (crit/move/CDR) on the player after a pick.
signal mastery_choice_ready(level: int)
signal perks_changed
signal crafted(station_id: String)   # B5 — station reacts in-world on a successful craft

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

# ---- spec 46 Phase A: modal accounting ----
# Offline, a modal pauses the tree exactly as it always did. In co-op the
# tree must keep simulating (the host opening the vendor cannot freeze the
# server), so modals just count and the LOCAL player's input gates on
# modal_count instead.
var modal_count := 0

# NetGame looked up at runtime, never as a compile-time global — the loop
# test loads this script from SceneTree._init, before autoloads register.
func net_active() -> bool:
	if not is_inside_tree():
		return false
	var net := get_node_or_null("/root/NetGame")
	return net != null and bool(net.active)

func modal_opened() -> void:
	modal_count += 1
	if not net_active() and is_inside_tree():
		get_tree().paused = true

func modal_closed() -> void:
	modal_count = maxi(0, modal_count - 1)
	if not net_active() and modal_count == 0 and is_inside_tree():
		get_tree().paused = false

# The player this machine controls: offline it's the only one; in co-op
# it's the body whose multiplayer authority is ours.
func local_player() -> Node:
	var tree := get_tree()
	if tree == null:
		return null   # standalone Game instance (headless tests) — not in the tree
	for p in tree.get_nodes_in_group("player"):
		if not net_active() or (p as Node).is_multiplayer_authority():
			return p
	return null

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
	"wayfinding": {"lv": 1, "xp": 0},   # ADR 0012 — the one skill
}
var materials: Dictionary = {}        # material id -> count
var charts: Array = []                # crafted chart dicts (the chart case)
var gold := 0                         # Hod's the faucet AND the sink
var summit_cleared := false           # the final chart, charted
var muted := true                     # spec 38 — master mute (persisted).
                                      # Default ON: fresh games start silent
                                      # (user 2026-06-12); F10 opts in.
# B5 — the picked skills for hotbar slots 2-4 (slot 1 is always the Bow).
const SKILL_POOL := ["PowerShot", "MultiShot", "BrambleSnare",
	"PiercingBolt", "RainOfThorns", "Thornburst", "HuntersMark",
	"HeartwoodWard", "MercyShot"]
# B5-wave2 — the deeper hunting verbs gate on Wayfinding level (ADR 0012: one
# trade; leveling — gather/craft/chart — opens them, not kills). Absent = open.
const SKILL_REQS := {"HuntersMark": 4, "HeartwoodWard": 7, "MercyShot": 9}

func skill_unlocked(sk: String) -> bool:
	return trade_lv(SKILL) >= int(SKILL_REQS.get(sk, 1))
var loadout: Array = ["PowerShot", "MultiShot", "BrambleSnare"]
# ADR 0012 mastery — perk_id -> true for the ONE perk the player chose at each
# multi-perk tier. Single-perk tiers (lv 2/3/12) auto-grant and never appear here.
var chosen_perks: Dictionary = {}
var seen_hints: Dictionary = {}       # one-time skill tutorials already shown
var inventory: Inventory = null       # Tetris gear grid — shared across scenes
var equipment = null                  # Equipment — shared across scenes
var ledger: RefCounted = null         # ADR 0013 — boss-trophy stat boosts
var player_hp := -1                   # -1 = "full" (first boot)

# ---- the active run ----
var active_chart: Dictionary = {}     # {} = not in a chart run (town / dev boot)
var in_dungeon := false
var _returning_from_delve := false    # B7 — town plays an arrival beat when set

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
		"Two lumps grind into stoneground ink, which pulls a chart toward the mineral seams. Or bring it to my forge and smelt a bar — that's where ore earns its keep. The hollows carry richer veins than my spoil heap.",
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
	"still": ["Quill, the Herbalist", [
		"First brew's the hardest — after that the still does half the work.",
		"Tonics sit beside your hearth bottles. Quaff with Q when you're hale and it's the tonic you'll taste. They keep a week if you don't shake them too hard.",
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
	ledger = load("res://scripts/ledger.gd").new()   # ADR 0013 — before load_into restores it
	# Wyrd — restore the last session before anything else reads state.
	if OS.get_environment("WYRD_NO_SAVE") != "":
		persistence_enabled = false
	elif SaveGame.load_into(self):
		print("[game] session restored (tutorial step %d)" % tutorial_step)
	AudioServer.set_bus_mute(0, muted)   # spec 38 — restore the mute state
	mastery_choice_ready.connect(_on_mastery_choice_ready)   # ADR 0012 mastery modal
	# Spec 41 — the kit cursor takes over in-game (interact/attack swaps
	# are a followup; the controller can call set_cursor as states land).
	if ResourceLoader.exists("res://assets/ui/cursor_default.png"):
		Input.set_custom_mouse_cursor(load("res://assets/ui/cursor_default.png"),
			Input.CURSOR_ARROW, Vector2(3, 2))
	# Dev: WYRD_DEV_LEVEL=<n> sets the Wayfinding level on boot — for eyeballing
	# the mastery ladder and the ADR-0013 difficulty bands at any level.
	var dev_level := OS.get_environment("WYRD_DEV_LEVEL")
	if dev_level != "":
		var dl: int = clampi(int(dev_level), 1, LEVEL_CAP)
		trades.wayfinding.lv = dl
		trades.wayfinding.xp = xp_for_level(dl)
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

# B5 — swap the loadout (validated against the pool; exactly 3, no dupes,
# every pick's Huntcraft gate met).
func set_loadout(picks: Array) -> bool:
	if picks.size() != 3:
		return false
	var seen := {}
	for sk in picks:
		if not SKILL_POOL.has(String(sk)) or seen.has(sk):
			return false
		if not skill_unlocked(String(sk)):
			return false
		seen[sk] = true
	loadout = picks.duplicate()
	save_now()
	if is_inside_tree():
		var player := local_player()   # co-op: rebuild the LOCAL player's skills
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

# ADR 0012 — one skill; the key arg is ignored (kept for call-site compat).
func trade_lv(_key: String = "") -> int:
	return int(trades[SKILL].lv)

# ADR 0006 — the demo level cap; xp accrues past it but levels stop.
const LEVEL_CAP := 17

# The Tetris pack grows a row at level milestones (lv 6 → 7 rows, lv 12 → 8).
# Idempotent — safe to call on every level-up and once on load.
func grow_pack_for_level() -> void:
	if inventory == null:
		return
	var lv := trade_lv()
	if lv >= 12 and inventory.rows < 8:
		inventory.resize(8)
	elif lv >= 6 and inventory.rows < 7:
		inventory.resize(7)

func award_xp(_key: String, amount: int) -> void:
	if amount <= 0:
		return
	trades[SKILL].xp += amount
	xp_gained.emit(SKILL, amount)
	while int(trades[SKILL].lv) < LEVEL_CAP \
			and trades[SKILL].xp >= xp_for_level(int(trades[SKILL].lv) + 1):
		trades[SKILL].lv += 1
		leveled_up.emit(SKILL, int(trades[SKILL].lv))
		notify("%s rises to %d" % [TRADE_NAMES.get(SKILL, "Wayfinding"), int(trades[SKILL].lv)])
		var sfx_lv := get_node_or_null("/root/Sfx")
		if sfx_lv != null:
			sfx_lv.play("level_up")
		if MASTERY_CHOICE_LVS.has(int(trades[SKILL].lv)):
			mastery_choice_ready.emit(int(trades[SKILL].lv))
		grow_pack_for_level()   # the satchel gains a row at lv 6 / lv 12

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
		var n_out := int(rec.get("yields_n", 1))
		# Spec 45-wilds — Second Pour: a wilds material craft sometimes
		# pours a second bottle.
		if trade == "wilds" and perk_active("wilds", "second_pour") \
				and randf() < 0.25:
			n_out += 1
			notify("Second pour! The pot had more to give.")
		add_material(String(rec.yields_material), n_out)
		notify("Made %s." % GatherDefs.material_name(String(rec.yields_material)))
	# Spec 45-earth — Smith's Thrift: 1 in 4 forge crafts hand back one RAW
	# input (never a bar — a bar refund would crack the economy gate on the
	# all-buyable recipes).
	if station_id == "forge" and perk_active("earth", "smiths_thrift") \
			and randf() < 0.25:
		var raws: Array = []
		for mid in rec.inputs:
			if not String(mid).ends_with("_bar"):
				raws.append(String(mid))
		if not raws.is_empty():
			var back := String(raws.pick_random())
			add_material(back, 1)
			notify("Smith's thrift — a %s comes back to the pile." %
				GatherDefs.material_name(back))
	var sfx := get_node_or_null("/root/Sfx")
	if sfx != null:
		var craft_key: String = "craft_cook" if station_id == "cookfire" \
			else ("craft_still" if station_id == "still" else "craft_smith")
		sfx.play(craft_key)
	crafted.emit(station_id)   # B5 — the in-world station reacts
	award_xp(trade, int(rec.get("xp", 0)))
	save_now()
	return true

# ---- per-trade level perks (A9) ----
const PERKS := {
	# ADR 0012 — ONE unified Wayfinding ladder: the old carto/earth/wilds/hunt
	# perks all live here now, unlocked by the single skill level. (Pick-one-of-N
	# mastery is a planned refinement.)
	"wayfinding": [
		{"id": "marginalia", "lv": 2, "name": "Mara's Marginalia",
			"desc": "Mara's notes crowd the codex margins — every riddle, plain to read"},
		{"id": "practiced_measures", "lv": 3, "name": "Practiced Measures",
			"desc": "Click a known mix in the codex and the pot sets out its makings"},
		{"id": "curious_fingers", "lv": 5, "name": "Curious Fingers",
			"desc": "A failed mix smudges less — curiosity keeps more of what it touches"},
		{"id": "double_ore", "lv": 5, "name": "Sturdy Swings",
			"desc": "25% chance a vein gives a second lump"},
		{"id": "keen_eye", "lv": 5, "name": "Keen Eye",
			"desc": "+1 herb on every forage"},
		{"id": "steady_hands", "lv": 5, "name": "Steady Hands",
			"desc": "+5% crit chance"},
		{"id": "sure_lines", "lv": 10, "name": "Sure Lines",
			"desc": "Your nib doesn't waver — every affix leans 5 points toward its good twin"},
		{"id": "quick_mining", "lv": 10, "name": "Miner's Rhythm",
			"desc": "Mining takes a third less time"},
		{"id": "clean_splits", "lv": 10, "name": "Clean Splits",
			"desc": "+1 log on every chop"},
		{"id": "hunters_stride", "lv": 10, "name": "Hunter's Stride",
			"desc": "+5% move speed"},
		{"id": "quick_nock", "lv": 12, "name": "Quick Nock",
			"desc": "Skills come back a tenth sooner"},
		{"id": "rich_seams", "lv": 13, "name": "Rich Seams",
			"desc": "Starsilver and deeper veins always give a second lump"},
		{"id": "light_hands", "lv": 13, "name": "Light Hands",
			"desc": "Foraging and chopping take a quarter less time"},
		{"id": "thrifty_quill", "lv": 14, "name": "Thrifty Quill",
			"desc": "Each chart asks one less pot of hedge ink. Waste not"},
		{"id": "heavy_draw", "lv": 14, "name": "Heavy Draw",
			"desc": "Your telling hits land a quarter harder"},
		{"id": "master_wayfinder", "lv": 17, "name": "Master Wayfinder",
			"desc": "Every chart that takes ink holds one more pot — the page listens closer"},
		{"id": "smiths_thrift", "lv": 17, "name": "Smith's Thrift",
			"desc": "1 in 4 forge crafts hand back one raw input — never a bar"},
		{"id": "second_pour", "lv": 17, "name": "Second Pour",
			"desc": "25% chance a hearth or still recipe pours a second bottle"},
		{"id": "even_breath", "lv": 17, "name": "Even Breath",
			"desc": "A clean kill steadies you — every kill returns 6 Focus"},
	],
}

# ADR 0012 mastery — the multi-perk tiers where the player picks ONE of the
# perks unlocked at that level (the "most choosy" ruling, 2026-06-16). The
# single-perk tiers (lv 2/3/12) are absent here, so they auto-grant on reach.
const MASTERY_CHOICE_LVS := [5, 10, 13, 14, 17]
# Perk flavour grouping for the choice cards (chart / gather / craft / combat).
const PERK_CATEGORY := {
	"marginalia": "chart", "practiced_measures": "chart",
	"curious_fingers": "craft", "double_ore": "gather", "keen_eye": "gather",
	"steady_hands": "combat", "sure_lines": "chart", "quick_mining": "gather",
	"clean_splits": "gather", "hunters_stride": "combat", "quick_nock": "combat",
	"rich_seams": "gather", "light_hands": "gather", "thrifty_quill": "chart",
	"heavy_draw": "combat", "master_wayfinder": "chart", "smiths_thrift": "craft",
	"second_pour": "craft", "even_breath": "combat",
}

# A perk is active when its level is reached AND, for a multi-perk choice tier,
# it is the one the player picked. Single-perk tiers (lv 2/3/12) auto-grant.
func perk_active(_trade: String, perk_id: String) -> bool:
	for perk in PERKS[SKILL]:
		if String(perk.id) == perk_id:
			if trade_lv(SKILL) < int(perk.lv):
				return false
			if MASTERY_CHOICE_LVS.has(int(perk.lv)):
				return bool(chosen_perks.get(perk_id, false))
			return true
	return false

# The perks unlocked at a given level (the candidates for that tier's choice).
func perks_at_level(lv: int) -> Array:
	var out: Array = []
	for perk in PERKS[SKILL]:
		if int(perk.lv) == lv:
			out.append(perk)
	return out

# True once the player has picked a perk at this choice tier.
func tier_chosen(lv: int) -> bool:
	for perk in perks_at_level(lv):
		if bool(chosen_perks.get(String(perk.id), false)):
			return true
	return false

# Choice tiers the player has reached but not yet picked — for retroactive
# prompts (a migrated save, or a tier skipped past while another modal was up).
func pending_mastery_levels() -> Array:
	var out: Array = []
	for lv in MASTERY_CHOICE_LVS:
		if trade_lv(SKILL) >= int(lv) and not tier_chosen(int(lv)):
			out.append(int(lv))
	return out

# Pick one perk at its tier. Permanent for now (no respec) — rejects a second
# pick at a tier that already has one. Returns true if the pick took.
func choose_perk(perk_id: String) -> bool:
	for perk in PERKS[SKILL]:
		if String(perk.id) == perk_id:
			var pl: int = int(perk.lv)
			if not MASTERY_CHOICE_LVS.has(pl):
				return false
			if trade_lv(SKILL) < pl:
				return false
			if tier_chosen(pl):
				return false
			chosen_perks[perk_id] = true
			perks_changed.emit()       # player re-derives cached combat stats
			save_now()
			return true
	return false

# ADR 0012 — pop the pick-one-of-N modal when a level-up reaches a choice tier.
# The panel owns its own modal accounting (open() → modal_opened; a pick →
# modal_closed), mirroring the shrine modal. If we're mid-scene-transition the
# choice stays queued in pending_mastery_levels() for a future prompt.
func _on_mastery_choice_ready(level: int) -> void:
	var tree := get_tree()
	if tree == null:
		return                       # standalone Game instance (headless tests)
	var scn := tree.current_scene
	if scn == null:
		return
	var MasteryPanel := load("res://scripts/ui/mastery_choice_panel.gd")
	var panel: CanvasLayer = MasteryPanel.new()
	scn.add_child(panel)
	panel.open(level)

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

# ---- A8-full: Quill's shelf — timed buffs ----
# id -> {"stat": String, "value": float, "left": float}. Runtime-only:
# a sip deliberately doesn't outlive the session (not saved).

signal buffs_changed
var buffs: Dictionary = {}

func apply_buff(id: String, stat: String, value: float, duration: float) -> void:
	buffs[id] = {"stat": stat, "value": value, "left": duration}
	buffs_changed.emit()

func buff_value(stat: String) -> float:
	var total := 0.0
	for id in buffs:
		if String(buffs[id].stat) == stat:
			total += float(buffs[id].value)
	return total

func _process(delta: float) -> void:
	if buffs.is_empty():
		return
	var expired: Array = []
	for id in buffs:
		buffs[id].left = float(buffs[id].left) - delta
		if float(buffs[id].left) <= 0.0:
			expired.append(id)
	for id in expired:
		buffs.erase(id)
		notify("The %s fades." % GatherDefs.material_name(String(id)))
	if not expired.is_empty():
		buffs_changed.emit()

# Q at full vigor reaches for the buff shelf (the player decides; the
# hearth's heal shelf keeps priority while hurt).
func quaff_buff_draught() -> bool:
	for id in CraftingDefs.BUFF_DRAUGHT_ORDER:
		if material_count(String(id)) > 0:
			var def: Dictionary = CraftingDefs.BUFF_DRAUGHTS[id]
			spend_materials({id: 1})
			apply_buff(String(id), String(def.stat), float(def.value),
				float(def.duration))
			# Quickroot Tonic also shakes off movement-locking statuses.
			if String(id) == "quickroot_tonic":
				var pl: Node = local_player()
				if pl != null and pl.has_method("cleanse_status"):
					pl.cleanse_status("root")
					pl.cleanse_status("snared")
			notify(String(def.toast))
			save_now()
			return true
	return false

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

# ---- spec 43: the experiment — ink recipes are discovered, not given ----
# Only hedge ink is known from the start (Mara teaches it). The rest are
# found by trying combinations in the bench pot.

var discovered_inks: Array = ["hedge_ink"]

func ink_discovered(ink_id: String) -> bool:
	return discovered_inks.has(ink_id)

func discover_ink(ink_id: String) -> void:
	if ink_discovered(ink_id):
		return
	discovered_inks.append(ink_id)
	award_xp("carto", 50)   # finding a recipe is real wayfinding
	notify("✦ Recipe found: %s! It's yours for good." %
		GatherDefs.material_name(ink_id))
	save_now()

# Resolve a pot attempt (the "Try the Mix" verb). An exact recipe match
# mixes — and teaches the recipe the first time. A miss consumes the pot
# (one of the cheapest makings handed back), pays a little Wayfinder xp
# for the lesson, and resolves 60/30/10 smudge / wild ink / serendipity.
# Returns {"outcome": discovery|mix|smudge|wild|serendipity, "ink": id?}.
func try_pot_mix(pot: Dictionary) -> Dictionary:
	if pot.is_empty():
		return {}
	for ink_id in GatherDefs.INK_RECIPE_ORDER:
		var inputs: Dictionary = GatherDefs.INK_RECIPES[ink_id].inputs
		if not _pot_match(pot, inputs):
			continue
		var fresh: bool = not ink_discovered(String(ink_id))
		if not mix_ink(String(ink_id)):
			return {}
		if fresh:
			discover_ink(String(ink_id))
			return {"outcome": "discovery", "ink": String(ink_id)}
		return {"outcome": "mix", "ink": String(ink_id)}
	# No recipe — the experiment goes sideways. Cozy consolation: one of
	# the cheapest makings stays in the satchel.
	var cost := pot.duplicate()
	var keep := _cheapest_material(pot)
	if keep != "":
		cost[keep] = int(cost[keep]) - 1
		if int(cost[keep]) <= 0:
			cost.erase(keep)
	if not cost.is_empty() and not spend_materials(cost):
		return {}
	award_xp("carto", 5)   # each smudge teaches
	# Spec 45-carto — Curious Fingers: misses smudge less (40/45/15).
	var smudge_at := 0.4 if perk_active("carto", "curious_fingers") else 0.6
	var wild_at := 0.85 if perk_active("carto", "curious_fingers") else 0.9
	var roll := randf()
	if roll < smudge_at:
		notify("The mix curdles to a grey smudge. Still — now you know.")
		save_now()
		return {"outcome": "smudge"}
	if roll < wild_at:
		var wild := String(["hedge_ink", "stoneground_ink"].pick_random())
		add_material(wild, 1)
		notify("A wild ink settles out — looks like %s." %
			GatherDefs.material_name(wild))
		save_now()
		return {"outcome": "wild", "ink": wild}
	# Serendipity — a bottle of something you haven't learned to make
	# (the recipe stays unknown; the bottle is the tease).
	var pool: Array = []
	for id in GatherDefs.INK_RECIPE_ORDER:
		if not ink_discovered(String(id)):
			pool.append(String(id))
	var lucky := "refined_ink" if pool.is_empty() else String(pool.pick_random())
	add_material(lucky, 1)
	notify("Serendipity! A pot of %s — though you couldn't say how." %
		GatherDefs.material_name(lucky))
	save_now()
	return {"outcome": "serendipity", "ink": lucky}

# Exact multiset equality — the pot must hold the recipe, no more, no less.
func _pot_match(pot: Dictionary, inputs: Dictionary) -> bool:
	if pot.size() != inputs.size():
		return false
	for id in inputs:
		if int(pot.get(id, 0)) != int(inputs[id]):
			return false
	return true

# Cheapest pot material by Hod's shelf price; unbuyables never come back.
func _cheapest_material(pot: Dictionary) -> String:
	var best := ""
	var best_price := 1 << 30
	for id in pot:
		for w in EconomyData.WARES:
			if String(w.id) == String(id) and int(w.price) < best_price:
				best_price = int(w.price)
				best = String(id)
	return best

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
	# Spec 46 Phase B — in co-op the HOST sockets for the party; the chart
	# leaves the host's case and everyone crosses on the same seed.
	if net_active():
		var net := get_node("/root/NetGame")
		if not bool(net.is_host()):
			notify("Only the fire-keeper sockets a chart — ask your host.")
			return
		charts.erase(chart)
		charts_changed.emit()
		net.start_run(chart)
		return
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
# Spec 46 Phase B — every peer enters the same chart locally: same seed,
# same geometry, same (seeded) foes. The host's chart was already spent.
func net_enter(chart: Dictionary) -> void:
	_defer_toasts = true
	active_chart = chart
	in_dungeon = true
	var p := local_player()
	if p != null:
		_snapshot_player(p)
	if tutorial_step == 4:
		advance_tutorial()
	var cp := get_node_or_null("/root/Checkpoint")
	if cp != null and cp.has_method("clear"):
		cp.clear()
	get_tree().change_scene_to_file.call_deferred(DUNGEON_SCENE)

# Spec 45-gaps — `abandoned` skips the completion reward: the entry-side
# return stone carries you home but the chart pays nothing torn.
func return_to_town(player: Node, abandoned: bool = false) -> void:
	_defer_toasts = true       # the town HUD will drain these in _ready
	if abandoned:
		notify("You tear the chart and step home. The hollow keeps its prize.")
	elif not active_chart.is_empty():
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
	_returning_from_delve = true   # B7 — the town reads + clears this for its arrival beat
	_snapshot_player(player)
	if tutorial_step == 5:
		advance_tutorial()
	var cp := get_node_or_null("/root/Checkpoint")
	if cp != null and cp.has_method("clear"):
		cp.clear()
	save_now()
	# Deferred — the exit waystone calls this from physics processing.
	get_tree().change_scene_to_file.call_deferred(TOWN_SCENE)

# ADR 0013 — power multiplier per level, applied to BOTH the player (in
# player_controller._derive_stats) and a den's enemies (in layout_loader).
# Net difficulty ≈ (LEVEL_POWER^2)^(den_level − player_level). The tuning knob
# for the level-delta curve (≤−2 easy, ±1 fair, ≥+2 very hard).
const LEVEL_POWER := 1.25

# The generation config handed to DungeonGen.generate(). {} when booting
# World.tscn directly (dev) — which keeps today's defaults, boss included.
func run_cfg() -> Dictionary:
	if active_chart.is_empty():
		return {}
	var t: Dictionary = ChartsData.TEMPLATES.get(String(active_chart.template_id), {})
	var cfg: Dictionary = (t.get("gen", {}) as Dictionary).duplicate()
	cfg["tier"] = int(active_chart.get("tier", 1))
	# ADR 0013 — each den carries a level (tier-derived); enemies scale to it.
	cfg["den_level"] = ({1: 3, 2: 8, 3: 13}).get(int(cfg["tier"]), 3)
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
