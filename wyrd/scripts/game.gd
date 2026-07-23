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
const FirstRoadData = preload("res://data/first_road.gd")
const CampaignData = preload("res://data/campaign.gd")
const D7ControlStability = preload("res://scripts/d7_control_stability.gd")
const D7PriorSagaHarvestEvidence = preload("res://data/d7_prior_saga_harvest_evidence.gd")
const D7SmokeClock = preload("res://scripts/d7_smoke_clock.gd")
const Drops = preload("res://data/drops.gd")
const GatherDefs = preload("res://data/gather.gd")
const DungeonGenScript = preload("res://scripts/dungeon_gen.gd")
const ItemsData = preload("res://data/items.gd")
const EnchantDefs = preload("res://data/enchants.gd")
const Progression = preload("res://data/progression.gd")
const WayweaverMasteryRules = preload("res://data/wayweaver_mastery.gd")
const WayweaverRuneCosmetics = preload("res://data/wayweaver_rune_cosmetics.gd")

const TOWN_SCENE := "res://scenes/Town.tscn"
const DUNGEON_SCENE := "res://scenes/World.tscn"

const TRADE_NAMES := Progression.TRADE_NAMES

signal xp_gained(trade: String, amount: int)
signal leveled_up(trade: String, new_lv: int)
signal materials_changed
signal charts_changed
signal gold_changed(amount: int)
signal tutorial_changed(step: int)
signal onboarding_changed
signal toast(msg: String)
signal mute_changed(muted: bool)
# Future mastery-choice seam: fires only if authored data gives one Trade two
# or more perks at the same level. The current 1–23 ladders have no such tier.
# perks_changed re-derives cached combat stats after a future pick.
signal mastery_choice_ready(trade_key: String, level: int)
signal perks_changed
signal crafted(station_id: String)   # B5 — station reacts in-world on a successful craft
# Wayfinding signature — fired when a chart run completes (not abandoned). The
# town HUD subscribes to debrief the bargain you struck: affixes + XP earned.
signal run_completed(chart: Dictionary, xp: int)
signal story_changed
signal chart_knowledge_changed
signal persistence_changed(available: bool, warning: String)
signal modal_changed(is_open: bool)
signal wayweaver_cosmetic_changed(rune_id: String)

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
var _modal_cancel_release_guard := false

# NetGame looked up at runtime, never as a compile-time global — the loop
# test loads this script from SceneTree._init, before autoloads register.
func net_active() -> bool:
	if not is_inside_tree():
		return false
	var net := get_node_or_null("/root/NetGame")
	return net != null and bool(net.active)

func modal_opened() -> void:
	var was_open := modal_count > 0
	modal_count += 1
	if not was_open:
		modal_changed.emit(true)
	if not net_active() and is_inside_tree():
		get_tree().paused = true

func modal_closed() -> void:
	var was_open := modal_count > 0
	modal_count = maxi(0, modal_count - 1)
	# An Esc press that dismisses a modal must not fall through to the player on
	# the same frame and open Pause underneath it. Hold the guard until release,
	# so polling input and event-driven panels share one ownership boundary.
	if was_open and modal_count == 0 and Input.is_action_pressed("ui_cancel"):
		_modal_cancel_release_guard = true
	if was_open and modal_count == 0:
		modal_changed.emit(false)
	if not net_active() and modal_count == 0 and is_inside_tree():
		get_tree().paused = false


func modal_owns_cancel_release() -> bool:
	if not _modal_cancel_release_guard:
		return false
	if not Input.is_action_pressed("ui_cancel"):
		_modal_cancel_release_guard = false
		return false
	return true

# The player this machine controls: offline it's the only one; in co-op
# it's the body whose multiplayer authority is ours.
func local_player() -> Node:
	if not is_inside_tree():
		return null   # standalone Game instance (headless tests) — not in the tree
	var tree := get_tree()
	for p in tree.get_nodes_in_group("player"):
		if not net_active() or (p as Node).is_multiplayer_authority():
			return p
	return null

# ---- persistence ----
# Headless tests drive the real autoload through the whole loop — without
# this gate they would both inherit and clobber the player's actual save.
var persistence_enabled := true
var persistence_available := true
var persistence_warning := ""
var web_smoke_enabled := false
var web_smoke_codex_enabled := false
var web_smoke_c2_enabled := false
var web_smoke_d1_enabled := false
var web_smoke_d2_enabled := false
var web_smoke_d3_enabled := false
var web_smoke_d4_enabled := false
var web_smoke_d5_enabled := false
var web_smoke_d6_enabled := false
var web_smoke_d7_enabled := false
var web_smoke_phase := ""
var web_smoke_history: Array = []
var web_smoke_features: Dictionary = {}
var _web_smoke_terminal_latched := false
var _web_smoke_terminal_payload: Dictionary = {}
var _web_smoke_c2_stage := ""
var _web_smoke_c2_run_count := 0
var _web_smoke_c2_deep_chart: Dictionary = {}
# D1 is deliberately query-gated release QA. These fields never participate in
# campaign state; they only retain evidence while the browser drives a fresh
# playthrough through the real table, run, boss, and return adapters.
var _web_smoke_d1_stage := ""
var _web_smoke_d1_run_count := 0
var _web_smoke_d1_green_ids: Array = []
var _web_smoke_d1_boss_chart: Dictionary = {}
var _web_smoke_d1_reward_counts: Dictionary = {}
var _web_smoke_d1_homecoming_campaign_before: Dictionary = {}
var _web_smoke_d1_homecoming_materials_before: Dictionary = {}
# D2's explicit browser-only prerequisite fixture is intentionally narrow:
# D1 proves the fresh campaign path, while D2 proves the replay from the real
# physical Table onward. These route-local fields never enter campaign state.
var _web_smoke_d2_stage := ""
var _web_smoke_d2_chart: Dictionary = {}
var _web_smoke_d2_campaign_before: Dictionary = {}
var _web_smoke_d2_rewards_before: Dictionary = {}
var _web_smoke_d3_stage := ""
var _web_smoke_d3_shallows_ids: Array = []
var _web_smoke_d3_boss_chart: Dictionary = {}
var _web_smoke_d3_rewards_before: Dictionary = {}
var _web_smoke_d4_stage := ""
var _web_smoke_d4_briar_ids: Array = []
var _web_smoke_d4_clue_ids: Array = []
var _web_smoke_d4_wolf_chart: Dictionary = {}
var _web_smoke_d4_summit_chart: Dictionary = {}
var _web_smoke_d4_first_handoff_attempt := ""
# D5 begins at the accepted Seventh Road boundary.  The only fixture values are
# durable prior-chapter truth, earned level, and ordinary Table makings; the
# new Crown-Thorn facts, Queen settlement, and Pale Stair remain production.
var _web_smoke_d5_stage := ""
var _web_smoke_d5_approach_ids: Array = []
var _web_smoke_d5_clue_ids: Array = []
var _web_smoke_d5_queen_chart: Dictionary = {}
# D6 starts at the accepted canonical Queen boundary and earns every new Pale
# Oath fact through physical World/Table interactions.
var _web_smoke_d6_stage := ""
var _web_smoke_d6_veins_ids: Array = []
var _web_smoke_d6_clue_ids: Array = []
var _web_smoke_d6_boss_chart: Dictionary = {}
# The D6 bell adapter records the exact pre-return action edge, so a browser
# receipt never diagnoses an authority rejection from the player's restored
# Town/home position.
var _web_smoke_d6_last_bell_action_detail: Dictionary = {}
var _web_smoke_d7_last_chain_action_detail: Dictionary = {}
# D7 starts from a real new journey. It records browser-QA evidence while the
# prior saga and every Fire clue, folio, escrow, Giant bank, settlement, and
# Kiln craft progress through their production seams.
var _web_smoke_d7_stage := ""
var _web_smoke_d7_ashen_ids: Array = []
var _web_smoke_d7_verse_ids: Array = []
var _web_smoke_d7_manifest: Dictionary = {}
var _web_smoke_d7_boss_chart: Dictionary = {}
# D7's fresh-save marathon earns its late Trade gates from an actual repeatable
# road rather than treating a prior release route's fixture as a hand-off.  The
# record is deliberately browser-driver-only: it is never saved or consulted by
# CampaignData, the Table, or progression.  It merely remembers which live
# Town/World leg should resume after the current physical training Chart returns.
var _web_smoke_d7_training: Dictionary = {}
var _web_smoke_d7_training_seen_kinds: Dictionary = {}
# One real Wolf boss drop is carried through the shared Pack and sold through
# Hod's visible counter during the fresh release marathon.  This is route-only
# evidence for the shipped loot/gold faucet, never a Queen campaign condition.
var _web_smoke_d7_sale_item: Dictionary = {}
# A per-World receipt of each legitimate Affix-driven empty Briar leg. This
# remains browser-driver-only and is reset with every new journey.
var _web_smoke_d7_prior_saga_no_gather_legs: Array = []
# Last D7 Far Waystone attempt. This belongs only to the query-gated release
# driver so a browser failure carries enough scene truth to diagnose a missed
# return without affecting gameplay or persistence.
var _web_smoke_d7_far_waystone_detail: Dictionary = {}
# Last strict gather attempt. Like the Waystone record, this is query-gated
# diagnostic evidence only; it never participates in node interaction, UI,
# progression, or persistence.
var _web_smoke_d7_last_harvest_detail: Dictionary = {}
# Append-only companion to the last-attempt snapshot. A multi-node World must
# retain every scanner outcome so its terminal browser receipt cannot hide two
# locked/cancelled candidates behind whichever node happened to run last.
var _web_smoke_d7_harvest_attempts: Array = []
# Every D7 World arrival owns a unique token.  Delayed release callbacks are
# SceneTree-owned (and therefore survive a scene swap), so they must never be
# allowed to act on whichever World happens to be current when they finally
# fire.  This remains query-driver-only diagnostic state.
var _web_smoke_d7_world_generation := 0
var _web_smoke_d7_world_token: Dictionary = {}
var _web_smoke_d7_return_claim_generation := -1
# D7's release-Web marathon gets one bounded simulation-clock lease.  This is
# browser-QA-only evidence, never saved or read by ordinary gameplay.
var _web_smoke_d7_clock := D7SmokeClock.new()
# Successful control waits use an owner-bound observation proof while the
# exact release-Web lease is active.  This receipt is QA-only and never decides
# campaign, inventory, Trade, or interaction outcomes.
var _web_smoke_d7_control_stability_receipt: Dictionary = {}
var _web_smoke_d7_progressive_level_ledger: Array = []
# The terminal guard is intentionally real-wall time.  It begins with the one
# owned lease after `fresh_campaign`, leaving a small margin inside the
# JavaScript runner's 900-second outer deadline so Game can publish a restored
# failure receipt instead of being killed externally. The lease starts after
# title/new-journey/bootstrap work, so 840s preserves a full 60s startup and
# serialization margin rather than incorrectly treating a post-fresh 895s
# timer as inside the outer 900s budget.
const D7_TERMINAL_WATCHDOG_DURATION_SEC := 840.0
# Fresh D7 trains only for the next authored action. Prior chapter returns then
# contribute their normal XP before a later gate is evaluated. The function
# below derives recipe/Ink/Alloy gates from production data; only Pack Reader's
# direct Huntcraft check and the one early Forge-proof level need named values.
const D7_FIRE_ENTRY_WAYFINDING_XP := 3496
const D7_FIRE_FIVE_VERSE_WAYFINDING_XP := 3840
const D7_FIRE_GIANT_WAYFINDING_XP := 4200
const D7_GOLDEN_DEEP_RETURN_WAYFINDING_XP := 1136
const D7_GOLDEN_THIRD_SHALLOWS_WAYFINDING_XP := 1320
const D7_TRAINING_PRACTICE_RECIPE := "green_hollow"
const D7_TRAINING_WORLD_LEG_CAP := 60
var _web_smoke_d7_terminal_watchdog_generation := 0
var _web_smoke_d7_terminal_watchdog_active_generation := -1
var _web_smoke_d7_terminal_watchdog_token := ""
# Native focused tests may inject a short duration; release/Web builds always
# use the fixed real-wall budget above.
var _web_smoke_d7_terminal_watchdog_test_duration_sec := -1.0

# This is the authored, fresh-save Wayfinding lane through Pale Oath.  Keep it
# data-derived so a future campaign-reward edit cannot silently turn the D7
# Fire-entry assertion into a stale literal.  It deliberately excludes every
# generic practice return: support Trades are Town gathering/Forge work, not a
# hidden Wayfinding faucet.
func d7_fire_entry_wayfinding_ledger() -> Dictionary:
	var entries: Array = []
	var add_entry := func(id: String, xp: int) -> void:
		entries.append({"id": id, "xp": xp})
	add_entry.call("snug_return", ChartsData.legacy_completion_xp({"tier": 1}))
	add_entry.call("green_hollow_discovery", ChartsData.recipe_discovery_xp("green_hollow"))
	for index in 3:
		add_entry.call("green_hollow_clue_%d" % (index + 1),
			ChartsData.campaign_completion_xp_for("green_hollow", index))
	add_entry.call("first_knot_boss", ChartsData.campaign_completion_xp_for("first_knot_boss"))
	for recipe_index in [0, -1, 1, 2]:
		var xp := ChartsData.campaign_completion_xp_for("deep_hollow") \
			if recipe_index < 0 else ChartsData.campaign_completion_xp_for("sallow_shallows", recipe_index)
		add_entry.call("deep_hollow" if recipe_index < 0 else "sallow_shallows_%d" % (recipe_index + 1), xp)
	add_entry.call("mire_ink_discovery", GatherDefs.ink_discovery_xp("mire_ink"))
	add_entry.call("golden_wallow_boss", ChartsData.campaign_completion_xp_for("golden_wallow_boss"))
	for index in 4:
		add_entry.call("briar_maze_clue_%d" % (index + 1),
			ChartsData.campaign_completion_xp_for("briar_maze", index))
	add_entry.call("mothglow_ink_discovery", GatherDefs.ink_discovery_xp("mothglow_ink"))
	add_entry.call("seventh_road_boss", ChartsData.campaign_completion_xp_for("seventh_road_boss"))
	add_entry.call("refined_ink_discovery", GatherDefs.ink_discovery_xp("refined_ink"))
	for index in 4:
		add_entry.call("summit_approach_clue_%d" % (index + 1),
			ChartsData.campaign_completion_xp_for("summit_approach", index))
	add_entry.call("queens_summit_boss", ChartsData.campaign_completion_xp_for("queens_summit_boss"))
	add_entry.call("stoneground_ink_discovery", GatherDefs.ink_discovery_xp("stoneground_ink"))
	for index in 4:
		add_entry.call("pale_veins_clue_%d" % (index + 1),
			ChartsData.campaign_completion_xp_for("pale_veins", index))
	add_entry.call("pale_oath_boss", ChartsData.campaign_completion_xp_for("pale_oath_boss"))
	var total := 0
	for entry_v in entries:
		total += int((entry_v as Dictionary).get("xp", 0))
	return {"entries": entries, "total": total}

# Spec 57 — privacy-safe first-session timing. Nothing here records player
# text, inputs, account data, or world coordinates: only named milestones and
# recovery-hint counters. Native playtest builds write a small report when
# launched with WYRD_PLAYTEST=1; web builds expose the same report to the page.
var onboarding_started_msec := -1
var onboarding_events: Array = []
var onboarding_recoveries: Dictionary = {}
var _onboarding_progress_msec := -1
var _onboarding_hint_stage := 0
var _onboarding_recovery_poll_msec := 0

func start_onboarding_measurement() -> void:
	onboarding_started_msec = Time.get_ticks_msec()
	onboarding_events = []
	onboarding_recoveries = {}
	mark_onboarding_progress()
	record_onboarding_event("begin_selected")

# Each meaningful action starts a fresh quiet window. Recovery then escalates
# from composition alone → a contextual nudge → the direct control/destination.
# This remains runtime-only; continuing a save starts a new quiet window.
func mark_onboarding_progress() -> void:
	_onboarding_progress_msec = Time.get_ticks_msec()
	_onboarding_hint_stage = 0
	_onboarding_recovery_poll_msec = 0
	if is_inside_tree():
		onboarding_changed.emit()

func onboarding_hint_stage() -> int:
	return _onboarding_hint_stage

func onboarding_compass_available() -> bool:
	if in_dungeon or tutorial_step >= 7:
		return true
	return _onboarding_hint_stage >= 2

func _tick_onboarding_recovery() -> void:
	if _onboarding_progress_msec == -1 or in_dungeon or tutorial_step >= 7:
		return
	var now := Time.get_ticks_msec()
	if now - _onboarding_recovery_poll_msec < 250:
		return
	_onboarding_recovery_poll_msec = now
	var stalled_sec := float(now - _onboarding_progress_msec) / 1000.0
	var direct_at := 35.0 if tutorial_step == 0 else 45.0
	var wanted := 2 if stalled_sec >= direct_at else 1 if stalled_sec >= 20.0 else 0
	if wanted <= _onboarding_hint_stage:
		return
	for stage in range(_onboarding_hint_stage + 1, wanted + 1):
		record_onboarding_recovery("step_%d_stage_%d" % [tutorial_step, stage])
	_onboarding_hint_stage = wanted
	onboarding_changed.emit()

func record_onboarding_event(event_name: String) -> void:
	if onboarding_started_msec < 0:
		return
	for entry in onboarding_events:
		if String((entry as Dictionary).get("event", "")) == event_name:
			return
	onboarding_events.append({
		"event": event_name,
		"elapsed_sec": snappedf(
			float(Time.get_ticks_msec() - onboarding_started_msec) / 1000.0, 0.01),
	})
	_publish_onboarding_report()

func record_onboarding_recovery(hint_name: String) -> void:
	if onboarding_started_msec < 0:
		return
	onboarding_recoveries[hint_name] = int(onboarding_recoveries.get(hint_name, 0)) + 1
	_publish_onboarding_report()

func onboarding_report() -> Dictionary:
	return {
		"schema": 1,
		"events": onboarding_events.duplicate(true),
		"recovery_hints": onboarding_recoveries.duplicate(true),
	}

func _publish_onboarding_report() -> void:
	var payload := JSON.stringify(onboarding_report())
	if OS.has_feature("web"):
		JavaScriptBridge.eval("globalThis.__wyrdOnboarding = %s" % payload, true)
	elif OS.get_environment("WYRD_PLAYTEST") == "1":
		var file := FileAccess.open("user://onboarding_playtest.json", FileAccess.WRITE)
		if file != null:
			file.store_string(payload)

func save_now() -> bool:
	if not persistence_enabled or not persistence_available:
		return false
	var ok := SaveGame.save(self)
	if not ok:
		report_persistence_unavailable(
			"Progress cannot be saved in this browser. This visit is session-only.")
	return ok

func report_persistence_unavailable(reason: String) -> void:
	persistence_available = false
	persistence_warning = reason
	persistence_changed.emit(false, reason)

func _check_web_persistence() -> void:
	if not OS.has_feature("web"):
		return
	# Godot's web save path is backed by IndexedDB. Browsers may omit or block
	# it (notably private/locked-down contexts); be explicit rather than showing
	# a Continue button that cannot survive the tab.
	var has_indexed_db = JavaScriptBridge.eval(
		"typeof globalThis.indexedDB !== 'undefined'", true)
	if not bool(has_indexed_db):
		report_persistence_unavailable(
			"This browser is not allowing local saves. Progress lasts for this visit only.")

func _configure_web_smoke() -> void:
	if not OS.has_feature("web"):
		return
	var legacy_smoke := bool(JavaScriptBridge.eval(
		"new URLSearchParams(location.search).get('wyrd_smoke') === 'snug'", true))
	var d6_smoke := bool(JavaScriptBridge.eval(
		"(() => { const q = new URLSearchParams(location.search); "
		+ "return q.get('smoke') === '1' && q.get('ui') === 'd6'; })()", true))
	var d7_smoke := bool(JavaScriptBridge.eval(
		"(() => { const q = new URLSearchParams(location.search); "
		+ "return q.get('smoke') === '1' && q.get('ui') === 'd7'; })()", true))
	web_smoke_enabled = legacy_smoke or d6_smoke or d7_smoke
	var ui_smoke_mode := "d7" if d7_smoke else "d6" if d6_smoke else String(JavaScriptBridge.eval(
		"new URLSearchParams(location.search).get('wyrd_ui_smoke') || ''", true))
	web_smoke_codex_enabled = web_smoke_enabled and ui_smoke_mode == "codex"
	web_smoke_c2_enabled = web_smoke_enabled and ui_smoke_mode == "c2"
	web_smoke_d1_enabled = web_smoke_enabled and ui_smoke_mode == "d1"
	web_smoke_d2_enabled = web_smoke_enabled and ui_smoke_mode == "d2"
	web_smoke_d3_enabled = web_smoke_enabled and ui_smoke_mode == "d3"
	web_smoke_d4_enabled = web_smoke_enabled and ui_smoke_mode == "d4"
	web_smoke_d5_enabled = web_smoke_enabled and ui_smoke_mode == "d5"
	web_smoke_d6_enabled = d6_smoke
	web_smoke_d7_enabled = d7_smoke
	web_smoke_phase = ""
	web_smoke_history = []
	web_smoke_features = {}
	_web_smoke_terminal_latched = false
	_web_smoke_terminal_payload = {}
	_web_smoke_c2_stage = ""
	_web_smoke_c2_run_count = 0
	_web_smoke_c2_deep_chart = {}
	_web_smoke_d1_stage = ""
	_web_smoke_d1_run_count = 0
	_web_smoke_d1_green_ids = []
	_web_smoke_d1_boss_chart = {}
	_web_smoke_d1_reward_counts = {}
	_web_smoke_d1_homecoming_campaign_before = {}
	_web_smoke_d1_homecoming_materials_before = {}
	_web_smoke_d2_stage = ""
	_web_smoke_d2_chart = {}
	_web_smoke_d2_campaign_before = {}
	_web_smoke_d2_rewards_before = {}
	_web_smoke_d3_stage = ""
	_web_smoke_d3_shallows_ids = []
	_web_smoke_d3_boss_chart = {}
	_web_smoke_d3_rewards_before = {}
	_web_smoke_d4_stage = ""
	_web_smoke_d4_briar_ids = []
	_web_smoke_d4_clue_ids = []
	_web_smoke_d4_wolf_chart = {}
	_web_smoke_d4_summit_chart = {}
	_web_smoke_d4_first_handoff_attempt = ""
	_web_smoke_d5_stage = ""
	_web_smoke_d5_approach_ids = []
	_web_smoke_d5_clue_ids = []
	_web_smoke_d5_queen_chart = {}
	_web_smoke_d6_stage = ""
	_web_smoke_d6_veins_ids = []
	_web_smoke_d6_clue_ids = []
	_web_smoke_d6_boss_chart = {}
	_web_smoke_d7_stage = ""
	_web_smoke_d7_ashen_ids = []
	_web_smoke_d7_verse_ids = []
	_web_smoke_d7_manifest = {}
	_web_smoke_d7_boss_chart = {}
	_web_smoke_d7_training = {}
	_web_smoke_d7_training_seen_kinds = {}
	_web_smoke_d7_sale_item = {}
	_web_smoke_d7_prior_saga_no_gather_legs = []
	_web_smoke_d7_far_waystone_detail = {}
	_web_smoke_d7_last_harvest_detail = {}
	_web_smoke_d7_harvest_attempts = []
	_web_smoke_d7_world_generation = 0
	_web_smoke_d7_world_token = {}
	_web_smoke_d7_return_claim_generation = -1
	_web_smoke_d7_control_stability_receipt = {}
	_web_smoke_d7_progressive_level_ledger = []
	if web_smoke_enabled:
		web_smoke_report("title")

func web_smoke_report(phase: String, error: String = "") -> void:
	if not web_smoke_enabled:
		return
	# The first terminal report is immutable. SceneTree-owned timers and
	# in-flight World coroutines can unwind after a watchdog/failure; none may
	# append a later checkpoint, replace the terminal reason, or publish a second
	# browser payload for the same attempt.
	if _web_smoke_terminal_latched:
		return
	# Every D7 checkpoint observes the owned lease. A lower hitstop freeze is
	# legitimate; a faster or invalid scale is a contract breach and is converted
	# to one non-recursive failed terminal receipt.
	if web_smoke_d7_enabled and _web_smoke_d7_clock.is_active() \
			and not _web_smoke_d7_clock.observe_current_scale():
		_web_smoke_d7_stage = "failed"
		_d7_restore_simulation_clock("failed")
		phase = "failed"
		error = "D7 simulation clock exceeded its owned 6x cap."
	# The D7 clock must be restored before a terminal browser payload is written,
	# so a passing smoke report cannot leave the page's simulation accelerated.
	if web_smoke_d7_enabled and (phase == "complete" or phase == "failed"):
		_d7_restore_simulation_clock(phase)
	web_smoke_phase = phase
	web_smoke_history.append(phase)
	var payload_data := {"phase": phase, "error": error,
		"history": web_smoke_history.duplicate(true),
		"features": web_smoke_features.duplicate(true),
		"d7_far_waystone": _web_smoke_d7_far_waystone_detail.duplicate(true),
		"d7_last_harvest": _web_smoke_d7_last_harvest_detail.duplicate(true),
		"d7_last_chain_action": _web_smoke_d7_last_chain_action_detail.duplicate(true),
		"d7_harvest_attempts": _web_smoke_d7_harvest_attempts.duplicate(true)}
	if phase == "complete" or phase == "failed":
		_web_smoke_terminal_latched = true
		_web_smoke_terminal_payload = payload_data.duplicate(true)
	if OS.has_feature("web"):
		var payload := JSON.stringify(payload_data)
		JavaScriptBridge.eval("globalThis.__wyrdSmoke = %s" % payload, true)
	print("[web-smoke] %s%s" % [phase, " — " + error if error != "" else ""])


func _d7_simulation_clock_query_active() -> bool:
	# D7 is query-gated only on exported Web builds. Native focused tests may
	# exercise the same route but must retain their own explicit dwell policy.
	return OS.has_feature("web") and web_smoke_enabled and web_smoke_d7_enabled


func _d7_begin_simulation_clock() -> bool:
	var fresh_campaign_reported := web_smoke_phase == "fresh_campaign" \
		and web_smoke_history.has("fresh_campaign")
	# A duplicate boundary callback is safe: the owner refuses another lease and
	# the still-active first lease remains authoritative.
	if _web_smoke_d7_clock.is_active():
		_web_smoke_d7_clock.begin(_d7_simulation_clock_query_active(),
			fresh_campaign_reported, "fresh_campaign")
		_d7_sync_simulation_clock_evidence()
		return true
	var began := _web_smoke_d7_clock.begin(_d7_simulation_clock_query_active(),
		fresh_campaign_reported, "fresh_campaign")
	_d7_sync_simulation_clock_evidence()
	if began:
		_d7_arm_terminal_watchdog()
	return began


func _d7_restore_simulation_clock(reason: String) -> void:
	# The SceneTreeTimer outlives World scenes.  Invalidate its generation before
	# writing any terminal report, so a late callback cannot turn a completed or
	# already-failed attempt into a second failure.
	_d7_invalidate_terminal_watchdog("cancelled")
	if not _web_smoke_d7_clock.is_active():
		return
	# A real impact freeze must return to the clock lease's captured baseline,
	# not to the old hard-coded 1.0.  Hitstop exposes this cancellation seam in
	# the companion owned-clock change; the conditional preserves old/dev roots.
	var hitstop := get_node_or_null("/root/Hitstop") if is_inside_tree() else null
	if hitstop != null and hitstop.has_method("cancel_and_restore"):
		hitstop.call("cancel_and_restore", _web_smoke_d7_clock.prior_scale())
	_web_smoke_d7_clock.restore(reason)
	_d7_sync_simulation_clock_evidence()


func _d7_sync_simulation_clock_evidence() -> void:
	web_smoke_features["d7_simulation_clock"] = _web_smoke_d7_clock.telemetry()


func _d7_control_observation_enabled() -> bool:
	# Native focused routes deliberately retain their historical wall dwell.
	# Only the query-gated release owner can replace wall silence with the
	# stronger process+physics observation contract.
	return web_smoke_d7_enabled and _web_smoke_d7_clock.is_active()


func _d7_control_owner_key() -> String:
	var scene := get_tree().current_scene if is_inside_tree() else null
	if scene == null:
		return ""
	return "%s:%d:%s:%d" % [String(scene.name), scene.get_instance_id(),
		_web_smoke_d7_stage, _web_smoke_d7_world_generation]


func _d7_record_control_stability(label: String, tracker: D7ControlStability) -> void:
	var receipt := tracker.receipt()
	receipt["label"] = label
	receipt["successful_waits"] = int(
		_web_smoke_d7_control_stability_receipt.get("successful_waits", 0)) + 1
	_web_smoke_d7_control_stability_receipt = receipt
	web_smoke_features["d7_control_stability_receipt"] = receipt.duplicate(true)


func _d7_record_progressive_level_ledger(label: String) -> void:
	var trade_ledger := {}
	for trade_key in Progression.TRADE_KEYS:
		var record: Dictionary = trades.get(trade_key, {})
		trade_ledger[trade_key] = {"level": trade_lv(trade_key),
			"xp": int(record.get("xp", 0))}
	_web_smoke_d7_progressive_level_ledger.append({"label": label,
		"trades": trade_ledger})
	web_smoke_features["d7_progressive_level_ledger"] = \
		_web_smoke_d7_progressive_level_ledger.duplicate(true)


# A release-route-only receipt for the four real Wayfinding award seams. It
# makes a future exact-ledger failure attributable to a Chart return, discovery
# or pot smudge without changing normal XP ownership, persistence, or UI.
func _d7_record_wayfinding_award(source: String, amount: int,
		before_xp: int, after_xp: int) -> void:
	if not web_smoke_d7_enabled:
		return
	var chart: Dictionary = active_chart if not active_chart.is_empty() else {}
	var reward := ChartsData.authored_completion_reward(chart)
	var awards: Array = web_smoke_features.get("d7_wayfinding_award_ledger", [])
	awards.append({
		"source": source,
		"amount": amount,
		"before_xp": before_xp,
		"after_xp": after_xp,
		"stage": _web_smoke_d7_stage,
		"recipe_id": String(chart.get("recipe_id", "")),
		"chart_instance_id": String(chart.get("chart_instance_id", "")),
		"authored_reward": reward.duplicate(true),
	})
	web_smoke_features["d7_wayfinding_award_ledger"] = awards


func _d7_wait_control_observation() -> void:
	# The tracker counts only after both schedulers have had a real opportunity
	# to publish queued frees, Area3D ownership, pause, and modal changes.
	await get_tree().process_frame
	await get_tree().physics_frame


func _d7_record_simulation_clock_watchdog(fired: bool = false) -> void:
	if not _web_smoke_d7_clock.is_active():
		return
	_web_smoke_d7_clock.record_watchdog("training_start", 8.0, true, fired)
	_d7_sync_simulation_clock_evidence()


func _d7_terminal_watchdog_duration_sec() -> float:
	# This seam is deliberately unavailable to exported release builds.  It
	# exists only so the owned-callback contract is covered without a 15-minute
	# native test sleep.
	if OS.is_debug_build() and _web_smoke_d7_terminal_watchdog_test_duration_sec > 0.0:
		return _web_smoke_d7_terminal_watchdog_test_duration_sec
	return D7_TERMINAL_WATCHDOG_DURATION_SEC


func _d7_terminal_watchdog_attempt_token(generation: int) -> String:
	return "d7_fresh_campaign_%d" % generation


func _d7_record_terminal_watchdog(event: String, generation: int) -> void:
	if _web_smoke_d7_terminal_watchdog_token == "":
		return
	_web_smoke_d7_clock.record_terminal_watchdog(
		_d7_terminal_watchdog_duration_sec(), true,
		_web_smoke_d7_terminal_watchdog_token, generation, event)
	_d7_sync_simulation_clock_evidence()


func _d7_arm_terminal_watchdog() -> void:
	if not _web_smoke_d7_clock.is_active() or not is_inside_tree():
		return
	# Duplicate fresh-boundary callbacks retain the original lease and watchdog.
	if _web_smoke_d7_terminal_watchdog_active_generation >= 0:
		return
	_web_smoke_d7_terminal_watchdog_generation += 1
	var generation := _web_smoke_d7_terminal_watchdog_generation
	_web_smoke_d7_terminal_watchdog_active_generation = generation
	_web_smoke_d7_terminal_watchdog_token = _d7_terminal_watchdog_attempt_token(generation)
	_d7_record_terminal_watchdog("armed", generation)
	# process_always and ignore_time_scale deliberately make this a monotonic
	# real-wall guard: paused modals, hitstop, and D7's 6x lease cannot extend it.
	var watchdog := get_tree().create_timer(_d7_terminal_watchdog_duration_sec(), true, false, true)
	watchdog.timeout.connect(_d7_terminal_watchdog_timeout.bind(generation))


func _d7_invalidate_terminal_watchdog(event: String = "cancelled") -> void:
	var generation := _web_smoke_d7_terminal_watchdog_active_generation
	if generation < 0:
		return
	_web_smoke_d7_terminal_watchdog_active_generation = -1
	_d7_record_terminal_watchdog(event, generation)


func _d7_terminal_watchdog_timeout(generation: int) -> void:
	if generation != _web_smoke_d7_terminal_watchdog_active_generation \
			or not _web_smoke_d7_clock.is_active():
		# The timer is intentionally not freed on terminal transition; it must
		# prove that its old attempt token cannot mutate the newer terminal state.
		_d7_record_terminal_watchdog("stale", generation)
		return
	_web_smoke_d7_terminal_watchdog_active_generation = -1
	_d7_record_terminal_watchdog("fired", generation)
	_web_smoke_d7_fail("D7 terminal real-wall watchdog expired before completion.")

# Query-gated release QA. The tester still chooses New Game at the real title;
# Town then sockets a real Snug chart, World builds it, and the completion path
# returns to Town. No query means none of this code runs.
func web_smoke_scene_ready(scene_name: String) -> void:
	if not web_smoke_enabled:
		return
	if web_smoke_c2_enabled:
		_web_smoke_c2_scene_ready(scene_name)
		return
	# D7 composes production helpers from earlier chapter routes. It must retain
	# dispatch ownership while those helpers are enabled, otherwise D1/D3 would
	# steal later Town/World arrivals before D7 can hand off the marathon stage.
	if web_smoke_d7_enabled:
		_web_smoke_d7_scene_ready(scene_name)
		return
	if web_smoke_d1_enabled:
		_web_smoke_d1_scene_ready(scene_name)
		return
	if web_smoke_d2_enabled:
		_web_smoke_d2_scene_ready(scene_name)
		return
	if web_smoke_d3_enabled:
		_web_smoke_d3_scene_ready(scene_name)
		return
	if web_smoke_d4_enabled:
		_web_smoke_d4_scene_ready(scene_name)
		return
	if web_smoke_d5_enabled:
		_web_smoke_d5_scene_ready(scene_name)
		return
	if web_smoke_d6_enabled:
		_web_smoke_d6_scene_ready(scene_name)
		return
	if scene_name == "Town":
		if web_smoke_phase == "world":
			web_smoke_report("complete")
			return
		if web_smoke_phase != "title":
			return
		web_smoke_report("town")
		if web_smoke_codex_enabled:
			get_tree().create_timer(0.8).timeout.connect(_run_codex_web_smoke)
		else:
			get_tree().create_timer(0.8).timeout.connect(_start_web_smoke_snug)
	elif scene_name == "World" and web_smoke_phase in ["town", "chart_table_closed"]:
		web_smoke_report("world")
		get_tree().create_timer(1.2).timeout.connect(func() -> void:
			return_to_town(local_player(), false))

func _start_web_smoke_snug() -> void:
	var chart := ChartsData.inscribe("snug", [], trade_lv("wayfinding"))
	if chart.is_empty():
		web_smoke_report("failed", "Snug inscription returned empty")
		return
	enter_dungeon(chart, local_player())

# Enhanced release QA drives the real Chart Table Controls. Reporting a phase
# is contingent on the corresponding UI actually existing, so the injected Web
# probe cannot pass on a transition-only false positive.
func _run_codex_web_smoke() -> void:
	var scene := get_tree().current_scene
	if scene == null:
		web_smoke_report("failed", "Town scene was missing")
		return
	var bench_script = load("res://scripts/ui/crafting_bench.gd")
	if bench_script == null:
		web_smoke_report("failed", "Chart Table script was missing")
		return
	var bench: CanvasLayer = bench_script.new()
	scene.add_child(bench)
	await get_tree().process_frame
	await get_tree().process_frame
	var panel := bench.get_node_or_null("ChartTablePanel")
	var view := panel.get_node_or_null("ChartTableView") if panel != null else null
	if view == null:
		web_smoke_report("failed", "Chart Table did not build")
		bench.queue_free()
		return
	web_smoke_report("chart_table")
	var codex_button := view.find_child("CodexButton", true, false) as Button
	if codex_button == null:
		web_smoke_report("failed", "Mara's Codex button was missing")
		bench.close()
		return
	codex_button.pressed.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	var pages := view.find_children("CodexPage_*", "Button", true, false)
	if pages.size() != ChartsData.CHART_RECIPE_ORDER.size():
		web_smoke_report("failed", "Codex pages did not build")
		bench.close()
		return
	web_smoke_report("codex")
	codex_button.pressed.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	if not view.find_children("CodexPage_*", "Button", true, false).is_empty():
		web_smoke_report("failed", "Codex did not close")
		bench.close()
		return
	web_smoke_report("chart_table_closed")
	bench.close()
	await get_tree().process_frame
	_start_web_smoke_snug()

# Slice D1 Web acceptance is a fresh, query-gated vertical slice. It retains
# only route-local evidence: every durable transition remains in Game,
# CampaignData, CraftingBench, LayoutLoader, and the real World scene.
func _web_smoke_d1_scene_ready(scene_name: String) -> void:
	if scene_name == "Town":
		if _web_smoke_d1_stage == "boss_return":
			_verify_d1_post_return.call_deferred()
			return
		if _web_smoke_d1_stage in ["green_1", "green_2", "green_3"] \
				and _web_smoke_d1_green_ids.size() > 0:
			web_smoke_report("green_hollow_%d" % _web_smoke_d1_green_ids.size())
		if _web_smoke_d1_stage == "":
			_web_smoke_d1_stage = "snug"
			web_smoke_report("town")
		get_tree().create_timer(0.45).timeout.connect(_continue_d1_web_smoke)
	elif scene_name == "World":
		match _web_smoke_d1_stage:
			"boss_world":
				get_tree().create_timer(0.8).timeout.connect(_drive_d1_boss_world)
			"green_1", "green_2", "green_3":
				web_smoke_report("green_world_%d" % _web_smoke_d1_green_ids.size())
				if web_smoke_d7_enabled:
					_d7_schedule_far_waystone_return(0.8, "d1_green")
				else:
					get_tree().create_timer(0.8).timeout.connect(func() -> void: return_to_town(local_player(), false))
			"snug", "training":
				if not web_smoke_history.has("world"):
					web_smoke_report("world")
				if web_smoke_d7_enabled:
					_d7_schedule_far_waystone_return(0.8, "d1_training")
				else:
					get_tree().create_timer(0.8).timeout.connect(func() -> void: return_to_town(local_player(), false))
			_:
				_web_smoke_d1_fail("A World opened outside the D1 acceptance route.")


func _continue_d1_web_smoke() -> void:
	if not web_smoke_d1_enabled or web_smoke_phase == "failed":
		return
	await _wait_d1_town_control()
	if web_smoke_phase == "failed":
		return
	match _web_smoke_d1_stage:
		"snug":
			# The one introductory Snug uses the released production run path to
			# unlock the Binding and the Green Hollow lesson kit.
			_web_smoke_d1_stage = "training"
			_start_d1_training_run("snug")
		"training":
			# Once all three Whispers are banked, keep earning the remaining
			# Wayfinding XP through ordinary Tier-1 returns until the level-8 Boss
			# Chart gate is genuinely met.  The live curve can end the third Green
			# Hollow just shy of eight; this route never injects that missing XP.
			if _web_smoke_d1_green_ids.size() == 3:
				if trade_lv("wayfinding") < 8:
					_start_d1_training_run("tier_1")
				else:
					if not await _gather_d1_hedge_ink() or web_smoke_phase == "failed":
						return
					await _prepare_d1_boss_chart()
			elif trade_lv("wayfinding") < 4:
				_start_d1_training_run("tier_1")
			else:
				_web_smoke_d1_stage = "green_1"
				if not await _gather_d1_hedge_ink() or web_smoke_phase == "failed":
					return
				await _inscribe_d1_green_hollow()
		"green_1", "green_2", "green_3":
			# This Town arrival follows a successful physical Green Hollow. Its
			# instance identity is checked before the next inscription starts.
			if _web_smoke_d1_green_ids.size() < 3:
				_web_smoke_d1_stage = "green_%d" % (_web_smoke_d1_green_ids.size() + 1)
				if not await _gather_d1_hedge_ink() or web_smoke_phase == "failed":
					return
				await _inscribe_d1_green_hollow()
			else:
				if trade_lv("wayfinding") < 8:
					_start_d1_training_run("tier_1")
				else:
					if not await _gather_d1_hedge_ink() or web_smoke_phase == "failed":
						return
					await _prepare_d1_boss_chart()
		_:
			_web_smoke_d1_fail("D1 reached an unknown Town stage: %s." % _web_smoke_d1_stage)


func _wait_d1_town_control() -> void:
	var deadline := Time.get_ticks_msec() + 20000
	var stable_since := -1
	var d7_stability = D7ControlStability.new()
	while Time.get_ticks_msec() < deadline:
		# Every training/Green Hollow return uses Town's production debrief.  Close
		# that real acknowledgement panel through its own completion seam so this
		# query-gated driver exercises modal ownership without stalling behind it.
		var debriefs := get_tree().get_nodes_in_group("run_debrief")
		if not debriefs.is_empty():
			stable_since = -1
			d7_stability.observe(_d7_control_owner_key(), false)
			for debrief in debriefs:
				if debrief != null and is_instance_valid(debrief) and debrief.has_method("_finish"):
					debrief.call("_finish")
				else:
					_web_smoke_d1_fail("A D1 return debrief had no production close action.")
					return
			await get_tree().process_frame
			await get_tree().process_frame
			continue
		if not get_tree().paused and modal_count == 0:
			if _d7_control_observation_enabled():
				if d7_stability.observe(_d7_control_owner_key(), true):
					_d7_record_control_stability("d1_town", d7_stability)
					return
			else:
				if stable_since < 0:
					stable_since = Time.get_ticks_msec()
				if Time.get_ticks_msec() - stable_since >= 700:
					return
		else:
			stable_since = -1
			d7_stability.observe(_d7_control_owner_key(), false)
		if _d7_control_observation_enabled():
			await _d7_wait_control_observation()
		else:
			await get_tree().create_timer(0.1, true).timeout
	_web_smoke_d1_fail("Town never returned stable control for D1.")


func _start_d1_training_run(template_id: String) -> void:
	if web_smoke_d7_enabled:
		_d7_physical_training_chart.bind(template_id).call_deferred()
		return
	_web_smoke_d1_run_count += 1
	if _web_smoke_d1_run_count > 12:
		_web_smoke_d1_fail("D1 training exceeded its bounded run count.")
		return
	if template_id == "tier_1":
		_web_smoke_d1_stage = "training"
	var chart := ChartsData.inscribe(template_id, [], trade_lv("wayfinding"), "",
		0.0, 72000 + _web_smoke_d1_run_count)
	if chart.is_empty():
		_web_smoke_d1_fail("D1 %s training inscription returned empty." % template_id)
		return
	if web_smoke_d7_enabled:
		_d7_socket_chart_at_town.bind(chart).call_deferred()
	else:
		enter_dungeon(chart, local_player())


func _d7_physical_training_chart(template_id: String) -> void:
	if template_id != "snug":
		# Once the first return has supplied the Green lesson, that physical recipe
		# is the cheapest renewable D7 trainer; never construct legacy templates.
		var clue_bearing := _web_smoke_d1_green_ids.size() < 3
		_web_smoke_d1_stage = "green_%d" % (_web_smoke_d1_green_ids.size() + 1) \
			if clue_bearing else "training"
		if not await _gather_d1_hedge_ink():
			return
		await _inscribe_d1_green_hollow(clue_bearing)
		return
	# New Journey's authored onboarding: speak with Mara, gather three herbs,
	# mix Hedge Ink at the real Table, then commit the Snug recipe visibly.
	# Mara owns a stable production group; do not parse player-visible prompt
	# copy (currently "Talk to Mara") as runtime identity.
	var mara := get_tree().get_first_node_in_group("tutorial_mara") as Node3D
	if mara == null or not await _d6_scanner_interact(mara):
		_web_smoke_d7_fail("Fresh D7 could not reach Mara's real onboarding dialog.")
		return
	for dialog_v in get_tree().current_scene.get_children():
		if dialog_v.has_method("_finish") and dialog_v.has_node("DialogueShell"):
			dialog_v.call("_finish")
			break
	# DialogPanel owns pause/modal teardown. Wait for that production lifecycle
	# before starting channelled gathering; paused GatherNodes cannot advance.
	await _wait_d1_town_control()
	if web_smoke_phase == "failed":
		return
	var herbs := 0
	for node_v in get_tree().get_nodes_in_group("interactable"):
		if herbs >= 3:
			break
		var node_kind = node_v.get("kind") if node_v is Node3D else null
		var node_item = node_v.get("item_id") if node_v is Node3D else null
		if node_v is Node3D and node_kind != null and node_item != null \
				and String(node_kind) == "forage_node" \
				and String(node_item) == "wild_herb" and node_v.has_method("interact"):
			var before := material_count("wild_herb")
			await _d7_scanner_harvest(node_v as Node3D, "wild_herb", 3000)
			if material_count("wild_herb") > before:
				herbs += 1
				# The first authored forage opens its onboarding teaching beat.
				# Acknowledge that real modal before asking the next GatherNode to
				# channel; otherwise the paused scene correctly leaves it inert.
				if modal_count > 0:
					for child in get_tree().current_scene.get_children():
						if child.has_node("DialogueShell") and child.has_method("_finish"):
							child.call("_finish")
							break
					await _wait_d1_town_control()
					if web_smoke_phase == "failed":
						return
	if herbs != 3:
		_web_smoke_d7_fail("Fresh D7 could not complete three real onboarding herb channels.")
		return
	var bench: Node = await _open_d1_chart_table()
	if bench == null:
		return
	var view := bench.get_node_or_null("ChartTablePanel/ChartTableView")
	var mix := view.find_child("MixTab", true, false) as Button if view != null else null
	if mix == null:
		_web_smoke_d7_fail("Fresh D7 Table lacked the real Hedge Ink pot.")
		return
	mix.pressed.emit()
	for _herb in 3:
		if not await _press_d1_supply_control(bench, "wild_herb"):
			_web_smoke_d7_fail("Fresh D7 could not stage an earned Wild Herb.")
			return
	var try_mix := view.find_child("TryMixButton", true, false) as Button
	if try_mix != null and not try_mix.disabled:
		try_mix.pressed.emit()
	await get_tree().process_frame
	var supplies := view.find_child("SuppliesTab", true, false) as Button
	if supplies == null:
		_web_smoke_d7_fail("Fresh D7 Table lacked Supplies after the Hedge Ink mix.")
		return
	supplies.pressed.emit()
	for item_id in ["practice_leaf", "hedge_sprig", "hedge_ink"]:
		if not await _press_d1_supply_control(bench, item_id):
			_web_smoke_d7_fail("Fresh D7 Snug Table rejected %s." % item_id)
			return
	var preview: Dictionary = bench.call("current_preview")
	var commit := view.find_child("InscribeChartButton", true, false) as Button
	var count := charts.size()
	if String(preview.get("recipe_id", "")) != "snug" or commit == null or commit.disabled:
		_web_smoke_d7_fail("Fresh D7 Snug was not commit-ready at the physical Table.")
		return
	commit.pressed.emit()
	await get_tree().process_frame
	var chart: Dictionary = charts.back() if charts.size() == count + 1 else {}
	bench.close()
	if chart.is_empty():
		_web_smoke_d7_fail("Fresh D7 real Snug commit did not mint a Chart.")
		return
	await _d7_socket_chart_at_town(chart)


func _open_d1_chart_table():
	var scene := get_tree().current_scene
	var player := local_player() as Node3D
	var tables := get_tree().get_nodes_in_group("inscribing_table")
	if scene == null or player == null or tables.size() != 1:
		_web_smoke_d1_fail("The authored Town Inscribing Table was missing.")
		return null
	var table := tables[0] as Node3D
	var home := player.global_position
	var table_pos := table.global_position
	player.global_position = Vector3(table_pos.x + 1.05, home.y, table_pos.z)
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	if player.get("_active_interactable") != table:
		player.global_position = home
		_web_smoke_d1_fail("The player scanner did not acquire the Inscribing Table.")
		return null
	# A just-closed teaching/debrief modal can leave the shared interact action
	# in its release frame. Keep the player inside the real scanner boundary and
	# retry the shipped action after a full release/physics settle; never call the
	# Table's interact method directly.
	for _attempt in 3:
		await _press_c2_world_interact()
		await get_tree().create_timer(0.08, true).timeout
		for child in scene.get_children():
			if child.has_node("ChartTablePanel"):
				player.global_position = home
				web_smoke_features["d1_world_interact_table"] = true
				return child
		# At tutorial step 7 the first real Table use opens Mara's authored
		# bench lesson before the deferred CraftingBench can finish _ready on Web.
		# Acknowledge that visible dialog, then allow the already-created bench to
		# build; do not send another station action through the paused player.
		var teaching_dialog = null
		for child in scene.get_children():
			if child.has_node("DialogueShell") and child.has_method("_finish"):
				teaching_dialog = child
				break
		if teaching_dialog != null:
			teaching_dialog.call("_finish")
			await _wait_d1_town_control()
			if web_smoke_phase == "failed":
				player.global_position = home
				return null
			for child in scene.get_children():
				if child.has_node("ChartTablePanel"):
					player.global_position = home
					web_smoke_features["d1_world_interact_table"] = true
					return child
		await get_tree().physics_frame
	player.global_position = home
	_web_smoke_d1_fail("The real Town Chart Table did not open through interact.")
	return null


func _press_d1_supply_control(bench: Node, material_id: String) -> bool:
	var panel := bench.get_node_or_null("ChartTablePanel")
	var view := panel.get_node_or_null("ChartTableView") if panel != null else null
	var supply := view.find_child("Supply_%s" % material_id, true, false) as Button \
		if view != null else null
	if supply == null or supply.disabled:
		return false
	supply.pressed.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	return true


func _inscribe_d1_green_hollow(count_campaign_loop: bool = true) -> void:
	var bench: Node = await _open_d1_chart_table()
	if bench == null or web_smoke_phase == "failed":
		return
	var recipe: Dictionary = ChartsData.CHART_RECIPES.get("green_hollow", {})
	var panel := bench.get_node_or_null("ChartTablePanel")
	var view := panel.get_node_or_null("ChartTableView") if panel != null else null
	var supplies := view.find_child("SuppliesTab", true, false) as Button if view != null else null
	if recipe.is_empty() or supplies == null:
		bench.close()
		_web_smoke_d1_fail("The Green Hollow table controls were missing.")
		return
	supplies.pressed.emit()
	await get_tree().process_frame
	for component_v in (recipe.pattern as Dictionary).values():
		var component_id := String(component_v)
		var before := material_count(component_id)
		if not await _press_d1_supply_control(bench, component_id):
			bench.close()
			_web_smoke_d1_fail("Green Hollow rejected its %s supply Control." % component_id)
			return
		# A renewed component can require its first press to buy, then its second
		# to stage after the refreshed row is built.
		if not (bench.get("draft").get("grid", {}) as Dictionary).values().has(component_id):
			if material_count(component_id) <= before \
					or not await _press_d1_supply_control(bench, component_id):
				bench.close()
				_web_smoke_d1_fail("Green Hollow did not stage its %s." % component_id)
				return
	var preview: Dictionary = bench.call("current_preview")
	var costs: Dictionary = preview.get("costs", {})
	var before_counts := {}
	for material_id_v in costs:
		before_counts[String(material_id_v)] = material_count(String(material_id_v))
	var action := view.find_child("InscribeChartButton", true, false) as Button
	if String(preview.get("recipe_id", "")) != "green_hollow" \
			or not bool(preview.get("commit_ready", false)) or action == null or action.disabled:
		bench.close()
		_web_smoke_d1_fail("Green Hollow was not commit-ready through the physical table.")
		return
	var charts_before := charts.size()
	action.pressed.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	var chart: Dictionary = charts.back() if charts.size() == charts_before + 1 else {}
	for material_id_v in costs:
		var material_id := String(material_id_v)
		if material_count(material_id) != int(before_counts[material_id]) - int(costs[material_id_v]):
			bench.close()
			_web_smoke_d1_fail("Green Hollow did not consume its exact %s cost." % material_id)
			return
	bench.close()
	var chart_id := String(chart.get("chart_instance_id", ""))
	if String(chart.get("recipe_id", "")) != "green_hollow" or chart_id == "" \
			or _web_smoke_d1_green_ids.has(chart_id):
		_web_smoke_d1_fail("Green Hollow did not create a distinct physical Chart instance.")
		return
	if count_campaign_loop:
		_web_smoke_d1_green_ids.append(chart_id)
	web_smoke_features["d1_green_table_commit"] = true
	if web_smoke_d7_enabled:
		_d7_socket_chart_at_town.bind(chart).call_deferred()
	else:
		enter_dungeon(chart, local_player())


func _gather_d1_hedge_ink() -> bool:
	var scene := get_tree().current_scene
	var player := local_player() as Node3D
	if scene == null or player == null:
		_web_smoke_d1_fail("D1 could not find Town gathering controls.")
		return false
	var herbs_before_gather := material_count("wild_herb")
	var gathered := 0
	for node_v in get_tree().get_nodes_in_group("interactable"):
		if gathered >= 6:
			break
		var node_kind = node_v.get("kind") if node_v is Node3D else null
		var node_item = node_v.get("item_id") if node_v is Node3D else null
		if not node_v is Node3D or node_kind == null or node_item == null \
				or (String(node_kind) not in ["forage_node", "ore_rock", "log_pile"] \
					and String(node_item) not in ["wellwater", "embersage"]) \
				or String(node_item) != "wild_herb" \
				or not node_v.has_method("is_used") or bool(node_v.call("is_used")):
			continue
		var before := material_count("wild_herb")
		await _d7_scanner_harvest(node_v as Node3D, "wild_herb", 2500)
		if material_count("wild_herb") <= before:
			_web_smoke_d1_fail("An authored Wild Herb production channel did not finish.")
			return false
		gathered += 1
		# first_time_hint may schedule its teaching dialog after the harvest
		# callback returns. Let that real UI materialize before deciding whether
		# the next channel/Table interaction is unblocked (notably on Web).
		await get_tree().process_frame
		await get_tree().process_frame
		if modal_count > 0:
			for child in scene.get_children():
				if child.has_node("DialogueShell") and child.has_method("_finish"):
					child.call("_finish")
					break
			await _wait_d1_town_control()
			if web_smoke_phase == "failed":
				return false
	# Six completed nodes are the proof. Legitimate production bonuses (Keen
	# Eye or a chart/town reward settling concurrently) may yield surplus herbs;
	# the Copper Pot below still proves its exact six-herb spend.
	if gathered != 6 or material_count("wild_herb") < herbs_before_gather + 6:
		_web_smoke_d1_fail("The six authored Wild Herb channels did not yield at least the two-pot supply.")
		return false
	var bench: Node = await _open_d1_chart_table()
	if bench == null:
		return false
	var panel := bench.get_node_or_null("ChartTablePanel")
	var view := panel.get_node_or_null("ChartTableView") if panel != null else null
	var mix := view.find_child("MixTab", true, false) as Button if view != null else null
	var try_mix := view.find_child("TryMixButton", true, false) as Button if view != null else null
	if mix == null or try_mix == null:
		bench.close()
		_web_smoke_d1_fail("The physical Hedge Ink pot controls were missing.")
		return false
	mix.pressed.emit()
	await get_tree().process_frame
	var ink_before := material_count("hedge_ink")
	var herbs_before_mix := material_count("wild_herb")
	for _pot in range(2):
		var pot_herbs_before := material_count("wild_herb")
		var pot_ink_before := material_count("hedge_ink")
		for _i in range(3):
			if not await _press_d1_supply_control(bench, "wild_herb"):
				bench.close()
				_web_smoke_d1_fail("The copper pot rejected an earned Wild Herb.")
				return false
		if material_count("wild_herb") != pot_herbs_before - 3:
			bench.close()
			_web_smoke_d1_fail("The real copper-pot Controls did not spend exactly three Wild Herbs.")
			return false
		try_mix = view.find_child("TryMixButton", true, false) as Button
		# Once a recipe is known, the third real supply Control auto-mixes its
		# exact pot. A fresh recipe instead leaves the pot intact for Try the Mix.
		# Both paths are production behavior; do not require a button that the
		# successful auto-mix has correctly disabled after clearing the pot.
		if material_count("hedge_ink") == pot_ink_before + 1:
			continue
		if try_mix == null or try_mix.disabled:
			bench.close()
			_web_smoke_d1_fail("The unresolved copper pot never enabled its real Try the Mix Control.")
			return false
		try_mix.pressed.emit()
		await get_tree().process_frame
		await get_tree().process_frame
		if material_count("hedge_ink") != pot_ink_before + 1:
			bench.close()
			_web_smoke_d1_fail("The real Try the Mix Control did not settle a Hedge Ink pot.")
			return false
	bench.close()
	if material_count("wild_herb") != herbs_before_mix - 6 \
			or material_count("hedge_ink") != ink_before + 2:
		_web_smoke_d1_fail("The real Hedge Ink mixing controls did not yield two pots.")
		return false
	web_smoke_features["d1_production_ink_mixing"] = true
	return true


func _prepare_d1_boss_chart() -> void:
	if _web_smoke_d1_green_ids.size() != 3 \
			or CampaignData.chapter_clue_count(campaign_state, CampaignData.FIRST_KNOT) != 3:
		_web_smoke_d1_fail("D1 did not bank exactly three distinct Green Hollow clues.")
		return
	if material_count("thorn_essence") != 1:
		_web_smoke_d1_fail("The third Whisper did not grant Thorn Essence missing-only.")
		return
	if trade_lv("wayfinding") < 8:
		_web_smoke_d1_fail("Three Green returns did not reach the Wayfinding-8 Boss Chart gate.")
		return
	# No stock is granted here: the real pot just supplied the exact two-pot
	# Boss cost, one visible on the rail and one in the template's base cost.
	var bench: Node = await _open_d1_chart_table()
	if bench == null:
		return
	var panel := bench.get_node_or_null("ChartTablePanel")
	var view := panel.get_node_or_null("ChartTableView") if panel != null else null
	var supplies := view.find_child("SuppliesTab", true, false) as Button if view != null else null
	if supplies == null:
		bench.close()
		_web_smoke_d1_fail("The Boss Chart supplies Control was missing.")
		return
	supplies.pressed.emit()
	await get_tree().process_frame
	# Press the real rows in the authored physical order: Base, Waymark,
	# Binding, required Hedge Ink, then the Seal cell.
	for item_id in ["field_parchment", "hedge_sprig", "loop_cord", "hedge_ink", "thorn_essence"]:
		if not await _press_d1_supply_control(bench, item_id):
			bench.close()
			_web_smoke_d1_fail("The Boss Chart rejected its real %s Control." % item_id)
			return
	var preview: Dictionary = bench.call("current_preview")
	var grid: Dictionary = bench.get("draft").get("grid", {})
	var rail: Array = bench.get("draft").get("ink_rail", [])
	var costs: Dictionary = preview.get("costs", {})
	var ordinary: Dictionary = preview.get("ordinary_costs", {})
	var action := view.find_child("InscribeChartButton", true, false) as Button
	if String(preview.get("recipe_id", "")) != CampaignData.FIRST_KNOT_BOSS_RECIPE \
			or String((preview.get("output", {}) as Dictionary).get("name", "")) != "Hedgemother's Den" \
			or String(grid.get("c", "")) != "field_parchment" \
			or String(grid.get("n", "")) != "hedge_sprig" \
			or String(grid.get("w", "")) != "loop_cord" \
			or String(grid.get("s", "")) != "thorn_essence" \
			or rail.count("hedge_ink") != 1 \
			or costs != {"field_parchment": 1, "hedge_sprig": 1, "loop_cord": 1,
				"hedge_ink": 2, "thorn_essence": 1} \
			or int(costs.get("thorn_essence", 0)) != 1 \
			or ordinary != {"field_parchment": 1, "hedge_sprig": 1,
				"loop_cord": 1, "hedge_ink": 2} \
			or preview.get("returned_on_failure", {}) != {"thorn_essence": 1} \
			or (preview.get("guaranteed", []) as Array).is_empty() \
			or String((preview.get("guaranteed", []) as Array)[0].get("id", "")) != "hedgemother" \
			or action == null or action.disabled:
		bench.close()
		_web_smoke_d1_fail("The Boss Chart preview did not expose the full Hedgemother Seal contract.")
		return
	web_smoke_features["d1_boss_preview_contract"] = true
	web_smoke_report("chart_table")
	web_smoke_report("boss_preview")
	var before_counts := {}
	for material_id_v in costs:
		before_counts[String(material_id_v)] = material_count(String(material_id_v))
	var charts_before := charts.size()
	action.pressed.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	var chart: Dictionary = charts.back() if charts.size() == charts_before + 1 else {}
	bench.close()
	var contract: Dictionary = chart.get("campaign_contract", {})
	var attempt_id := String(chart.get("attempt_id", ""))
	var escrow: Dictionary = (campaign_state.get("escrows", {}) as Dictionary).get(attempt_id, {})
	if String(chart.get("recipe_id", "")) != CampaignData.FIRST_KNOT_BOSS_RECIPE \
			or String(contract.get("boss_kind", "")) != "hedgemother" \
			or attempt_id == "" or String(escrow.get("phase", "")) != "case":
		_web_smoke_d1_fail("Game.try_inscribe_chart did not create the canonical Boss Chart escrow.")
		return
	for material_id_v in costs:
		var material_id := String(material_id_v)
		if material_count(material_id) != int(before_counts[material_id]) - int(costs[material_id_v]):
			_web_smoke_d1_fail("Boss Chart did not consume its exact %s cost." % material_id)
			return
	_web_smoke_d1_boss_chart = chart.duplicate(true)
	web_smoke_features["d1_try_inscribe_chart_escrow"] = true
	if web_smoke_d7_enabled:
		_web_smoke_d1_stage = "boss_world"
		_d7_socket_chart_at_town.bind(chart).call_deferred()
		return
	else:
		enter_dungeon(chart, local_player())
	var in_run: Dictionary = (campaign_state.get("escrows", {}) as Dictionary).get(attempt_id, {})
	if String(in_run.get("phase", "")) != "in_run":
		_web_smoke_d1_fail("Socketing the Boss Chart did not move its Seal escrow into the run.")
		return
	_web_smoke_d1_stage = "boss_world"


func _drive_d1_boss_world() -> void:
	var boss: Node = null
	for foe in get_tree().get_nodes_in_group("enemy"):
		if String(foe.get("role")) == "boss" and String(foe.get("kind")) == "hedgemother":
			boss = foe
			break
	if boss == null or not boss.has_method("take_damage"):
		_web_smoke_d1_fail("The campaign World did not build its guaranteed Hedgemother.")
		return
	var cfg := run_cfg()
	if String(cfg.get("boss_kind", "")) != "hedgemother" \
			or String((cfg.get("campaign_contract", {}) as Dictionary).get("chapter_id", "")) \
				!= CampaignData.FIRST_KNOT:
		_web_smoke_d1_fail("The World lost the Boss Chart's authored campaign contract.")
		return
	web_smoke_features["d1_world_campaign_boss"] = true
	web_smoke_report("boss_world")
	_web_smoke_d1_reward_counts = {
		"tusker_tusk": material_count("tusker_tusk"),
		"thorn_essence": material_count("thorn_essence"),
	}
	# This is a real Combatant damage/death transition, not a direct campaign
	# settlement. LayoutLoader's production boss.died callback invokes the host
	# resolver, which owns the tombstone and reward transaction.
	boss.call("take_damage", int(boss.get("hp")) + 1, Vector3.ZERO)
	await get_tree().process_frame
	var chapter_cleared := CampaignData.chapter_cleared(campaign_state, CampaignData.FIRST_KNOT)
	var attempt_id := String(_web_smoke_d1_boss_chart.get("attempt_id", ""))
	var escrow: Dictionary = (campaign_state.get("escrows", {}) as Dictionary).get(attempt_id, {})
	if not chapter_cleared or String(escrow.get("phase", "")) != "consumed" \
			or material_count("tusker_tusk") != int(_web_smoke_d1_reward_counts.tusker_tusk) + 1 \
			or not (campaign_state.get("relics", []) as Array).has("green_root_rune") \
			or not (campaign_state.get("restorations", []) as Array).has("trophy_hall"):
		_web_smoke_d1_fail("The real Hedgemother death did not settle First Knot exactly once.")
		return
	web_smoke_features["d1_boss_death_host_resolver"] = true
	web_smoke_report("boss_cleared")
	_web_smoke_d1_stage = "boss_return"
	if web_smoke_d7_enabled:
		_d7_schedule_far_waystone_return(0.35, "d1_boss")
	else:
		get_tree().create_timer(0.35).timeout.connect(func() -> void: return_to_town(local_player(), false))


func _verify_d1_post_return() -> void:
	var tusks_before := int(_web_smoke_d1_reward_counts.get("tusker_tusk", 0))
	var attempt_id := String(_web_smoke_d1_boss_chart.get("attempt_id", ""))
	var escrow: Dictionary = (campaign_state.get("escrows", {}) as Dictionary).get(attempt_id, {})
	if material_count("tusker_tusk") != tusks_before + 1 \
			or material_count("thorn_essence") != int(_web_smoke_d1_reward_counts.get("thorn_essence", 0)) \
			or String(escrow.get("phase", "")) != "consumed":
		_web_smoke_d1_fail("The completed Boss Chart re-rewarded or refunded on return.")
		return
	web_smoke_features["d1_terminal_return_idempotence"] = true
	var scene := get_tree().current_scene
	if scene == null:
		_web_smoke_d1_fail("Town was unavailable for the First Knot Homecoming projection.")
		return
	# Town owns the projection and may legitimately present the ordinary run
	# debrief before the Homecoming debrief.  Let those real dialogs settle, and
	# close them only through their public dialog completion seam before moving a
	# player into the Hall scanner.
	await _wait_d1_homecoming_control()
	if web_smoke_phase == "failed":
		return
	web_smoke_features["d1_homecoming_modal_control"] = true
	var halls := scene.find_children("FirstKnotTrophyHall", "", true, false)
	var hall: Node3D = scene.get_node_or_null("FirstKnotTrophyHall") as Node3D
	if halls.size() != 1 or hall == null or not hall.visible or not hall.is_in_group("interactable") \
			or hall.get_node_or_null("GreenRootRune") == null \
			or hall.get_node_or_null("TuskerRecordPlaque") == null \
			or hall.get_node_or_null("CoveredBowRest") == null:
		_web_smoke_d1_fail("Town did not project exactly one complete First Knot Trophy Hall.")
		return
	web_smoke_features["d1_homecoming_hall_projection"] = true
	web_smoke_report("homecoming_hall")
	var atlas := scene.get_node_or_null("AtlasDeepRumourSource")
	if atlas == null or not atlas.has_method("homecoming_handoff_visible") \
			or not bool(atlas.call("homecoming_handoff_visible")):
		_web_smoke_d1_fail("Town's Living Atlas did not receive the First Knot handoff projection.")
		return
	web_smoke_features["d1_homecoming_atlas_handoff"] = true
	web_smoke_report("homecoming_atlas")
	# This acceptance tail is presentation-only: preserve deep copies before the
	# real scanner/interact action so the Hall cannot conceal a reward path.
	_web_smoke_d1_homecoming_campaign_before = campaign_state.duplicate(true)
	_web_smoke_d1_homecoming_materials_before = materials.duplicate(true)
	if not await _inspect_d1_trophy_hall(hall):
		return
	if campaign_state != _web_smoke_d1_homecoming_campaign_before \
			or materials != _web_smoke_d1_homecoming_materials_before:
		_web_smoke_d1_fail("Inspecting the Trophy Hall changed campaign or materials.")
		return
	web_smoke_features["d1_homecoming_copy_only"] = true
	web_smoke_report("homecoming_inspected")
	web_smoke_features["d1_gameplay_driver"] = true
	if web_smoke_d7_enabled and _web_smoke_d7_stage == "prior_first_knot":
		web_smoke_d1_enabled = false
		_web_smoke_d7_stage = "prior_golden_wallow"
		web_smoke_report("first_knot_complete")
		_d7_record_progressive_level_ledger("first_knot_settlement")
		_d7_begin_golden_wallow_from_earned_state.call_deferred()
		return
	web_smoke_report("complete")


func _wait_d1_homecoming_control() -> void:
	var deadline := Time.get_ticks_msec() + 20000
	var stable_since := -1
	var d7_stability = D7ControlStability.new()
	while Time.get_ticks_msec() < deadline:
		# `run_debrief` is scheduled first by Town; when it closes, Town schedules
		# FirstKnotHomecomingDebrief through modal_changed.  Both are real dialog
		# nodes, so this invokes their production close method rather than clearing
		# modal state or bypassing presentation ownership.
		var dialogs: Array = []
		dialogs.append_array(get_tree().get_nodes_in_group("run_debrief"))
		dialogs.append_array(get_tree().get_nodes_in_group("FirstKnotHomecomingDebrief"))
		if not dialogs.is_empty():
			stable_since = -1
			d7_stability.observe(_d7_control_owner_key(), false)
			for dialog in dialogs:
				if dialog != null and is_instance_valid(dialog) and dialog.has_method("_finish"):
					dialog.call("_finish")
				else:
					_web_smoke_d1_fail("A Homecoming arrival dialog had no production close action.")
					return
			await get_tree().process_frame
			await get_tree().process_frame
			continue
		if not get_tree().paused and modal_count == 0:
			if _d7_control_observation_enabled():
				if d7_stability.observe(_d7_control_owner_key(), true):
					_d7_record_control_stability("d1_homecoming", d7_stability)
					return
			else:
				if stable_since < 0:
					stable_since = Time.get_ticks_msec()
				if Time.get_ticks_msec() - stable_since >= 700:
					return
		else:
			stable_since = -1
			d7_stability.observe(_d7_control_owner_key(), false)
		if _d7_control_observation_enabled():
			await _d7_wait_control_observation()
		else:
			await get_tree().create_timer(0.1, true).timeout
	_web_smoke_d1_fail("Town never returned stable control after its Homecoming debriefs.")


func _inspect_d1_trophy_hall(hall: Node3D) -> bool:
	var player := local_player() as Node3D
	if player == null:
		_web_smoke_d1_fail("Town had no local player for Trophy Hall scanner acceptance.")
		return false
	var home := player.global_position
	var hall_pos := hall.global_position
	# Cross the scanner boundary like a real walking approach.  In Web builds an
	# immediate teleport from one already-overlapping Area3D to another can leave
	# the old target selected, so try every side and require the Hall itself.
	var acquired := false
	for direction in [Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD, Vector3.BACK]:
		for step in 31:
			var distance := lerpf(4.0, 1.05, float(step) / 30.0)
			player.global_position = Vector3(
				hall_pos.x + direction.x * distance, home.y,
				hall_pos.z + direction.z * distance)
			await get_tree().physics_frame
			if player.get("_active_interactable") == hall:
				acquired = true
				break
		if acquired:
			break
	if not acquired:
		player.global_position = home
		_web_smoke_d1_fail("The player scanner did not acquire the Trophy Hall.")
		return false
	await _press_c2_world_interact()
	player.global_position = home
	await get_tree().process_frame
	var dialog := get_tree().get_first_node_in_group("TrophyHallInspectDialog")
	if dialog == null:
		_web_smoke_d1_fail("The real Trophy Hall interact action did not open its inspect dialog.")
		return false
	web_smoke_features["d1_homecoming_scanner_inspect"] = true
	# The dialog is an acknowledgement-only read. Close it through the same
	# public seam so the final smoke completion leaves Town in stable control.
	if dialog.has_method("_finish"):
		dialog.call("_finish")
		await get_tree().process_frame
		return true
	_web_smoke_d1_fail("Trophy Hall inspect dialog had no production close action.")
	return false


func _web_smoke_d1_fail(reason: String) -> void:
	_web_smoke_d1_stage = "failed"
	web_smoke_report("failed", reason)


# Golden Wallow release route. This fixture starts at the accepted First Knot
# Homecoming boundary so the browser spends its budget on the second chapter.
# It supplies prerequisite levels/makings only; source read, Table commits,
# World transitions, clue returns, boss death, and settlement are production.
func _web_smoke_d3_scene_ready(scene_name: String, owner_token: Dictionary = {}) -> void:
	if scene_name == "Town":
		if _web_smoke_d3_stage == "":
			_web_smoke_d3_stage = "fixture"
			web_smoke_report("town")
			_setup_d3_homecoming_fixture.call_deferred()
			return
		if _web_smoke_d3_stage.begins_with("shallows_"):
			web_smoke_report("shallows_return_%d" % _web_smoke_d3_shallows_ids.size())
			# Fresh D7 must earn Mara's wet-road components through Deep Hollow
			# after its first physical Shallows return. Standalone Golden Wallow
			# keeps the original finite Shallows loop unchanged.
			if web_smoke_d7_enabled and _web_smoke_d7_stage == "prior_golden_wallow" \
					and _web_smoke_d3_shallows_ids.size() == 1 \
					and not bool(_web_smoke_d7_training.get("golden_deep_hollow_complete", false)):
				_d7_begin_golden_deep_hollow.call_deferred()
				return
			get_tree().create_timer(0.35).timeout.connect(_continue_d3_web_smoke)
			return
		if _web_smoke_d3_stage == "boar_return":
			_verify_d3_settlement.call_deferred()
	elif scene_name == "World":
		if _web_smoke_d3_stage.begins_with("shallows_"):
			web_smoke_report("shallows_world_%d" % _web_smoke_d3_shallows_ids.size())
			if web_smoke_d7_enabled and _web_smoke_d7_stage == "prior_golden_wallow":
				_d7_harvest_world_then_return.bind(owner_token).call_deferred()
				return
			# Give the compatibility renderer time to finish its first probe step
			# before this accelerated fixture tears the World scene down again.
			get_tree().create_timer(1.2).timeout.connect(func() -> void:
				return_to_town(local_player(), false))
		elif _web_smoke_d3_stage == "boar_world":
			get_tree().create_timer(0.7).timeout.connect(_drive_d3_boar_world)
		else:
			_web_smoke_d3_fail("A World opened outside the Golden Wallow route.")


func _setup_d3_homecoming_fixture() -> void:
	campaign_state = CampaignData.empty_state()
	var first: Dictionary = campaign_state.chapters[CampaignData.FIRST_KNOT]
	first.cleared = true
	first.clue_count = 3
	campaign_state.relics = ["green_root_rune"]
	campaign_state.restorations = ["trophy_hall"]
	trades.wayfinding = {"xp": Progression.xp_for_level(9), "lv": 9}
	trades.wildcraft = {"xp": Progression.xp_for_level(10), "lv": 10}
	chart_source_unlocks = ChartsData.normalize_chart_source_unlocks(
		["atlas_sallow_shallows"])
	known_chart_recipes = ChartsData.starting_recipe_ids()
	chart_recipe_journal = ChartsData.fresh_recipe_journal()
	# A cleared First Knot can only exist after the first Snug return. Preserve
	# that earlier Table milestone explicitly so the Binding well is available.
	seen_hints["chart_table_snug_returned"] = true
	discovered_inks = ["hedge_ink"]
	charts = []
	gold = 500
	_apply_campaign_material_targets({"hedge_ink": 6})
	web_smoke_features["d3_post_first_knot_fixture"] = true
	var town := get_tree().current_scene
	if town != null:
		if town.has_method("_refresh_campaign_settlement_view"):
			town.call("_refresh_campaign_settlement_view")
		if town.has_method("_refresh_first_knot_homecoming_view"):
			town.call("_refresh_first_knot_homecoming_view")
	await _wait_d3_town_control()
	if web_smoke_phase == "failed":
		return
	var hall := town.get_node_or_null("FirstKnotTrophyHall") if town != null else null
	if hall == null or not hall.visible:
		_web_smoke_d3_fail("The Golden route fixture did not begin at Homecoming.")
		return
	web_smoke_report("first_knot_homecoming")
	if not await _read_d3_shallows_atlas_source():
		return
	web_smoke_features["d3_real_atlas_source_read"] = true
	web_smoke_report("shallows_source")
	_web_smoke_d3_stage = "shallows_1"
	await _inscribe_d3_shallows()


func _read_d3_shallows_atlas_source() -> bool:
	var scene := get_tree().current_scene
	var atlas := scene.get_node_or_null("AtlasDeepRumourSource") as Node3D \
		if scene != null else null
	var player := local_player() as Node3D
	if atlas == null or player == null or not atlas.has_method("active_source_id") \
			or String(atlas.call("active_source_id")) != "atlas_sallow_shallows":
		_web_smoke_d3_fail("The Living Atlas did not expose the Shallows source.")
		return false
	if not await _d3_scanner_interact(atlas):
		return false
	var dialog := get_tree().get_first_node_in_group("ChartRumourSourceDialog")
	if dialog == null or not dialog.has_method("_finish"):
		_web_smoke_d3_fail("The Shallows source did not open its production dialog.")
		return false
	dialog.call("_finish")
	await get_tree().process_frame
	await get_tree().process_frame
	var status := chart_source_status("atlas_sallow_shallows")
	if not (chart_recipe_journal.rumours as Array).has("atlas_sallow_shallows") \
			or String(status.state) != "read" \
			or material_count("field_parchment") < 1 \
			or material_count("mire_reed") < 1 or material_count("loop_cord") < 1:
		_web_smoke_d3_fail("The real Atlas read did not grant its missing-only lesson.")
		return false
	return true


func _d3_scanner_interact(target: Node3D) -> bool:
	var player := local_player() as Node3D
	if player == null:
		_web_smoke_d3_fail("The Golden route had no local player scanner.")
		return false
	var home := player.global_position
	var target_pos := target.global_position
	var acquired := false
	for direction in [Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD, Vector3.BACK]:
		for step in 31:
			var distance := lerpf(3.6, 0.85, float(step) / 30.0)
			player.global_position = Vector3(target_pos.x + direction.x * distance,
				home.y, target_pos.z + direction.z * distance)
			await get_tree().physics_frame
			if not is_instance_valid(player) or not is_instance_valid(target):
				_web_smoke_d3_fail("The Golden route lost its scanner target.")
				return false
			if player.get("_active_interactable") == target:
				acquired = true
				break
		if acquired:
			break
	if not acquired:
		player.global_position = home
		_web_smoke_d3_fail("The player scanner did not acquire the Golden route target.")
		return false
	await _press_c2_world_interact()
	if not is_instance_valid(player) or not is_instance_valid(target):
		_web_smoke_d3_fail("The Golden route lost its scanner target.")
		return false
	player.global_position = home
	await get_tree().process_frame
	return true


func _continue_d3_web_smoke() -> void:
	if not web_smoke_d3_enabled or web_smoke_phase == "failed":
		return
	await _wait_d3_town_control()
	if web_smoke_phase == "failed":
		return
	if _web_smoke_d3_shallows_ids.size() < 3:
		_web_smoke_d3_stage = "shallows_%d" % (_web_smoke_d3_shallows_ids.size() + 1)
		await _inscribe_d3_shallows()
		return
	if CampaignData.chapter_clue_count(campaign_state, CampaignData.GOLDEN_WALLOW) != 3 \
			or material_count("tusker_tusk") != 1 \
			or not (chart_recipe_journal.rumours as Array).has("golden_wallow_boss"):
		_web_smoke_d3_fail("Three distinct Shallows did not settle the Golden clue ledger.")
		return
	if web_smoke_d7_enabled and _web_smoke_d7_stage == "prior_golden_wallow":
		await _d7_read_mara_sallow_source_then_prepare_boss()
		return
	trades.wayfinding = {"xp": Progression.xp_for_level(12), "lv": 12}
	_apply_campaign_material_targets({"bittergrass": 1, "mothmint": 1,
		"hedge_ink": 4, "waxed_vellum": 1, "mire_reed": 1, "sunk_knot": 1})
	web_smoke_features["d3_bounded_makings_fixture"] = true
	if not await _mix_d3_mire_ink():
		return
	web_smoke_report("mire_ink")
	await _inscribe_d3_boar_chart()


func _inscribe_d3_shallows() -> void:
	var chart := await _d3_table_inscribe("sallow_shallows",
		["field_parchment", "mire_reed", "loop_cord", "hedge_ink"])
	if chart.is_empty():
		return
	var chart_id := String(chart.get("chart_instance_id", ""))
	if chart_id == "" or _web_smoke_d3_shallows_ids.has(chart_id):
		_web_smoke_d3_fail("Sallow Shallows did not mint a distinct physical Chart.")
		return
	_web_smoke_d3_shallows_ids.append(chart_id)
	web_smoke_features["d3_shallows_real_table"] = true
	web_smoke_report("shallows_table_%d" % _web_smoke_d3_shallows_ids.size())
	if web_smoke_d7_enabled:
		_d7_socket_chart_at_town.bind(chart).call_deferred()
	else:
		enter_dungeon(chart, local_player())


func _d3_table_inscribe(recipe_id: String, supplies_to_press: Array) -> Dictionary:
	var bench: Node = await _open_d1_chart_table()
	if bench == null or web_smoke_phase == "failed":
		return {}
	var panel := bench.get_node_or_null("ChartTablePanel")
	var view := panel.get_node_or_null("ChartTableView") if panel != null else null
	var supplies := view.find_child("SuppliesTab", true, false) as Button if view != null else null
	if supplies == null:
		bench.close()
		_web_smoke_d3_fail("The Golden route Table had no Supplies tab.")
		return {}
	supplies.pressed.emit()
	await get_tree().process_frame
	for item_id_v in supplies_to_press:
		var item_id := String(item_id_v)
		var before := material_count(item_id)
		if not await _press_d1_supply_control(bench, item_id):
			bench.close()
			_web_smoke_d3_fail("The Golden Table rejected %s." % item_id)
			return {}
		var draft: Dictionary = bench.get("draft")
		var staged := (draft.get("grid", {}) as Dictionary).values().has(item_id) \
			or (draft.get("ink_rail", []) as Array).has(item_id)
		if not staged and material_count(item_id) > before:
			if not await _press_d1_supply_control(bench, item_id):
				bench.close()
				_web_smoke_d3_fail("The renewed %s would not stage." % item_id)
				return {}
	var preview: Dictionary = bench.call("current_preview")
	var action := view.find_child("InscribeChartButton", true, false) as Button
	if String(preview.get("recipe_id", "")) != recipe_id \
			or not bool(preview.get("commit_ready", false)) \
			or action == null or action.disabled:
		bench.close()
		_web_smoke_d3_fail("The physical Table did not resolve %s." % recipe_id)
		return {}
	if recipe_id == "golden_wallow_boss":
		var guarantees: Array = preview.get("guaranteed", [])
		if String((preview.get("output", {}) as Dictionary).get("name", "")) \
				!= "Burrow Boar's Wallow" or guarantees.is_empty() \
				or String((guarantees[0] as Dictionary).get("id", "")) != "burrow_boar" \
				or not (preview.get("preparation_notes", []) as Array).has(
					"Mire Ink — mixed at Wildcraft 10.") \
				or preview.get("returned_on_failure", {}) != {"tusker_tusk": 1}:
			bench.close()
			_web_smoke_d3_fail("The Boar preview did not expose its full Golden contract.")
			return {}
		web_smoke_features["d3_boar_preview_contract"] = true
		web_smoke_report("boar_preview")
	var charts_before := charts.size()
	action.pressed.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	var chart: Dictionary = charts.back() if charts.size() == charts_before + 1 else {}
	bench.close()
	if String(chart.get("recipe_id", "")) != recipe_id:
		_web_smoke_d3_fail("The Golden Table commit did not mint %s." % recipe_id)
		return {}
	return chart


func _mix_d3_mire_ink() -> bool:
	var bench: Node = await _open_d1_chart_table()
	if bench == null:
		return false
	var panel := bench.get_node_or_null("ChartTablePanel")
	var view := panel.get_node_or_null("ChartTableView") if panel != null else null
	var mix := view.find_child("MixTab", true, false) as Button if view != null else null
	if mix == null:
		bench.close()
		_web_smoke_d3_fail("The Golden route Table had no Mix tab.")
		return false
	mix.pressed.emit()
	await get_tree().process_frame
	var before := {"bittergrass": material_count("bittergrass"),
		"mothmint": material_count("mothmint"), "hedge_ink": material_count("hedge_ink"),
		"mire_ink": material_count("mire_ink")}
	for item_id in ["bittergrass", "mothmint", "hedge_ink"]:
		if not await _press_d1_supply_control(bench, item_id):
			bench.close()
			_web_smoke_d3_fail("The Mire Ink pot rejected %s." % item_id)
			return false
	var try_mix := view.find_child("TryMixButton", true, false) as Button
	if try_mix == null or try_mix.disabled:
		bench.close()
		_web_smoke_d3_fail("The exact Mire Ink pot did not enable Try the Mix.")
		return false
	try_mix.pressed.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	bench.close()
	if material_count("mire_ink") != int(before.mire_ink) + 1 \
			or material_count("bittergrass") != int(before.bittergrass) - 1 \
			or material_count("mothmint") != int(before.mothmint) - 1 \
			or material_count("hedge_ink") != int(before.hedge_ink) - 1:
		_web_smoke_d3_fail("The real Wildcraft-10 pot did not settle exact Mire Ink.")
		return false
	web_smoke_features["d3_mire_ink_production_controls"] = true
	return true


func _inscribe_d3_boar_chart() -> void:
	var chart := await _d3_table_inscribe("golden_wallow_boss",
		["waxed_vellum", "mire_reed", "sunk_knot", "mire_ink", "tusker_tusk"])
	if chart.is_empty():
		return
	var attempt_id := String(chart.get("attempt_id", ""))
	var escrow: Dictionary = (campaign_state.escrows as Dictionary).get(attempt_id, {})
	if attempt_id == "" or String(escrow.get("phase", "")) != "case":
		_web_smoke_d3_fail("The Boar Chart did not open its Tusker escrow.")
		return
	_web_smoke_d3_boss_chart = chart.duplicate(true)
	web_smoke_features["d3_boar_table_escrow"] = true
	_web_smoke_d3_stage = "boar_world"
	if web_smoke_d7_enabled:
		_d7_socket_chart_at_town.bind(chart).call_deferred()
	else:
		enter_dungeon(chart, local_player())


func _drive_d3_boar_world() -> void:
	var boss: Node = null
	for foe in get_tree().get_nodes_in_group("enemy"):
		if String(foe.get("role")) == "boss" and String(foe.get("kind")) == "burrow_boar":
			boss = foe
			break
	if boss == null or not boss.has_method("take_damage") \
			or String(run_cfg().get("boss_kind", "")) != "burrow_boar":
		_web_smoke_d3_fail("The Golden World did not build its guaranteed Burrow Boar.")
		return
	web_smoke_features["d3_world_burrow_boar"] = true
	web_smoke_report("boar_world")
	_web_smoke_d3_rewards_before = {"wightpelt": material_count("wightpelt")}
	boss.call("take_damage", int(boss.get("hp")) + 1, Vector3.ZERO)
	await get_tree().process_frame
	var attempt_id := String(_web_smoke_d3_boss_chart.get("attempt_id", ""))
	var escrow: Dictionary = (campaign_state.escrows as Dictionary).get(attempt_id, {})
	if not CampaignData.chapter_cleared(campaign_state, CampaignData.GOLDEN_WALLOW) \
			or String(escrow.get("phase", "")) != "consumed" \
			or material_count("wightpelt") != int(_web_smoke_d3_rewards_before.wightpelt) + 1 \
			or not (campaign_state.relics as Array).has("mist_root_rune") \
			or not (campaign_state.restorations as Array).has("sallow_jetty"):
		_web_smoke_d3_fail("Burrow Boar death did not settle Golden Wallow exactly once.")
		return
	web_smoke_features["d3_boar_death_settlement"] = true
	web_smoke_report("boar_cleared")
	_web_smoke_d3_stage = "boar_return"
	if web_smoke_d7_enabled:
		_d7_schedule_far_waystone_return(0.35, "d3_boss")
	else:
		get_tree().create_timer(0.35).timeout.connect(func() -> void: return_to_town(local_player(), false))


func _verify_d3_settlement() -> void:
	await _wait_d3_town_control()
	if web_smoke_phase == "failed":
		return
	var scene := get_tree().current_scene
	var hall := scene.get_node_or_null("FirstKnotTrophyHall") if scene != null else null
	var atlas := scene.get_node_or_null("AtlasDeepRumourSource") if scene != null else null
	var jetty := scene.get_node_or_null("SallowJetty") if scene != null else null
	if hall == null or hall.get_node_or_null("GoldenWallowRecord") == null \
			or hall.get_node_or_null("MistRootRune") == null \
			or hall.get_node_or_null("WightpeltRecord") == null:
		_web_smoke_d3_fail("Town did not project the Golden Hall record.")
		return
	web_smoke_features["d3_golden_hall_projection"] = true
	web_smoke_report("golden_hall")
	if atlas == null or not atlas.has_method("golden_settlement_visible") \
			or not bool(atlas.call("golden_settlement_visible")) \
			or atlas.get_node_or_null("GoldenWallowAtlasMark") == null:
		_web_smoke_d3_fail("The Living Atlas did not acknowledge Golden settlement.")
		return
	web_smoke_features["d3_golden_atlas_projection"] = true
	web_smoke_report("golden_atlas")
	if jetty == null or not jetty.visible or jetty.get_node_or_null("SallowJettyModel") == null \
			or String(jetty.call("launch_verb")) != "Launch held Mire Chart":
		_web_smoke_d3_fail("The restored Sallow Jetty was not playable in Town.")
		return
	web_smoke_features["d3_sallow_jetty_projection"] = true
	web_smoke_report("sallow_jetty")
	web_smoke_features["d3_gameplay_driver"] = true
	if web_smoke_d7_enabled and _web_smoke_d7_stage == "prior_golden_wallow":
		web_smoke_d3_enabled = false
		_web_smoke_d7_stage = "prior_seventh_road"
		web_smoke_report("golden_wallow_complete")
		_d7_record_progressive_level_ledger("golden_wallow_settlement")
		_d7_begin_seventh_road_from_earned_state.call_deferred()
		return
	web_smoke_report("complete")


func _wait_d3_town_control() -> void:
	var deadline := Time.get_ticks_msec() + 20000
	var stable_since := -1
	var d7_stability = D7ControlStability.new()
	while Time.get_ticks_msec() < deadline:
		var dialogs: Array = []
		dialogs.append_array(get_tree().get_nodes_in_group("run_debrief"))
		dialogs.append_array(get_tree().get_nodes_in_group("FirstKnotHomecomingDebrief"))
		dialogs.append_array(get_tree().get_nodes_in_group("GoldenWallowSettlementDebrief"))
		if not dialogs.is_empty():
			stable_since = -1
			d7_stability.observe(_d7_control_owner_key(), false)
			for dialog in dialogs:
				if dialog != null and is_instance_valid(dialog) and dialog.has_method("_finish"):
					dialog.call("_finish")
				else:
					_web_smoke_d3_fail("A Golden route debrief had no production close action.")
					return
			await get_tree().process_frame
			await get_tree().process_frame
			continue
		if not get_tree().paused and modal_count == 0 and pending_run_debrief.is_empty():
			if _d7_control_observation_enabled():
				if d7_stability.observe(_d7_control_owner_key(), true):
					_d7_record_control_stability("d3_town", d7_stability)
					return
			else:
				if stable_since < 0:
					stable_since = Time.get_ticks_msec()
				if Time.get_ticks_msec() - stable_since >= 650:
					return
		else:
			stable_since = -1
			d7_stability.observe(_d7_control_owner_key(), false)
		if _d7_control_observation_enabled():
			await _d7_wait_control_observation()
		else:
			await get_tree().create_timer(0.1, true).timeout
	_web_smoke_d3_fail("Town never returned stable control for Golden Wallow.")


func _web_smoke_d3_fail(reason: String) -> void:
	_web_smoke_d3_stage = "failed"
	web_smoke_report("failed", reason)


# Seventh Road release route. Like D3, this begins at the accepted boundary of
# the preceding chapter. Every new source read, physical Chart, World return,
# boss settlement, restored Archive read, and handoff escrow transition remains
# production; the query fixture supplies only already-proven history and bounded
# ordinary makings so the release run fits inside one browser watchdog.
func _web_smoke_d4_scene_ready(scene_name: String, owner_token: Dictionary = {}) -> void:
	if scene_name == "Town":
		if _web_smoke_d4_stage == "":
			_web_smoke_d4_stage = "fixture"
			web_smoke_report("town")
			_setup_d4_golden_fixture.call_deferred()
			return
		if _web_smoke_d4_stage.begins_with("briar_"):
			web_smoke_report("briar_return_%d" % _web_smoke_d4_briar_ids.size())
			get_tree().create_timer(0.35).timeout.connect(_continue_d4_web_smoke)
			return
		if _web_smoke_d4_stage == "wolf_return":
			_verify_d4_seventh_settlement.call_deferred()
			return
		if _web_smoke_d4_stage == "summit_abandon_return":
			_verify_d4_summit_refund.call_deferred()
	elif scene_name == "World":
		if _web_smoke_d4_stage.begins_with("briar_"):
			var clue: Dictionary = run_cfg().get("campaign_clue", {})
			var expected_index := _web_smoke_d4_briar_ids.size() - 1
			var expected_id := String(CampaignData.SEVENTH_ROAD_CLUES[expected_index]) \
				if expected_index >= 0 and expected_index < CampaignData.SEVENTH_ROAD_CLUES.size() \
				else ""
			if String(clue.get("clue_id", "")) != expected_id \
					or String(clue.get("presentation", "")) != "cold_track_clue":
				_web_smoke_d4_fail("A Briar World did not carry its exact Cold Track clue.")
				return
			_web_smoke_d4_clue_ids.append(expected_id)
			web_smoke_report("briar_world_%d" % _web_smoke_d4_briar_ids.size())
			if web_smoke_d7_enabled and _web_smoke_d7_stage == "prior_seventh_road":
				_d7_harvest_world_then_return.bind(owner_token).call_deferred()
				return
			get_tree().create_timer(1.2).timeout.connect(func() -> void:
				return_to_town(local_player(), false))
		elif _web_smoke_d4_stage == "wolf_world":
			get_tree().create_timer(0.7).timeout.connect(_drive_d4_wolf_world)
		elif _web_smoke_d4_stage == "legacy_world_1":
			get_tree().create_timer(0.7).timeout.connect(_drive_d4_summit_abandon)
		elif _web_smoke_d4_stage == "legacy_world_2":
			get_tree().create_timer(0.7).timeout.connect(_drive_d4_queen_world)
		else:
			_web_smoke_d4_fail("A World opened outside the Seventh Road route.")


func _setup_d4_golden_fixture() -> void:
	campaign_state = CampaignData.empty_state()
	for chapter_id in [CampaignData.FIRST_KNOT, CampaignData.GOLDEN_WALLOW]:
		var chapter: Dictionary = campaign_state.chapters[chapter_id]
		chapter.cleared = true
		chapter.clue_count = int(CampaignData.CHAPTERS[chapter_id].clue_target)
	campaign_state.relics = ["green_root_rune", "mist_root_rune"]
	campaign_state.restorations = ["trophy_hall", "sallow_jetty"]
	trades.wayfinding = {"xp": Progression.xp_for_level(15), "lv": 15}
	trades.wildcraft = {"xp": Progression.xp_for_level(13), "lv": 13}
	chart_source_unlocks = ChartsData.normalize_chart_source_unlocks(
		["atlas_sallow_shallows", "atlas_briar_knot"])
	known_chart_recipes = ChartsData.starting_recipe_ids()
	chart_recipe_journal = ChartsData.fresh_recipe_journal()
	seen_hints["chart_table_snug_returned"] = true
	discovered_inks = ["hedge_ink", "mire_ink"]
	charts = []
	gold = 1200
	# Four ordinary Briar inscriptions each retain their authored three-pot base
	# cost. The fixture supplies only this already-proven consumable runway; every
	# physical arrangement and commit still travels through the production Table.
	_apply_campaign_material_targets({"hedge_ink": 12, "mothmint": 2})
	web_smoke_features["d4_post_golden_fixture"] = true
	var town := get_tree().current_scene
	if town != null:
		if town.has_method("_refresh_campaign_settlement_view"):
			town.call("_refresh_campaign_settlement_view")
		if town.has_method("_refresh_first_knot_homecoming_view"):
			town.call("_refresh_first_knot_homecoming_view")
	await _wait_d4_town_control()
	if web_smoke_phase == "failed":
		return
	var atlas := town.get_node_or_null("AtlasDeepRumourSource") if town != null else null
	if atlas == null or not atlas.has_method("golden_settlement_visible") \
			or not bool(atlas.call("golden_settlement_visible")):
		_web_smoke_d4_fail("The D4 fixture did not begin at Golden Wallow settlement.")
		return
	web_smoke_report("golden_wallow_settlement")
	if not await _read_d4_briar_atlas_source(atlas):
		return
	web_smoke_features["d4_real_atlas_briar_source"] = true
	web_smoke_report("briar_source")
	_web_smoke_d4_stage = "briar_1"
	await _inscribe_d4_briar()


func _read_d4_briar_atlas_source(atlas: Node) -> bool:
	if not atlas.has_method("active_source_id") \
			or String(atlas.call("active_source_id")) != "atlas_briar_knot":
		_web_smoke_d4_fail("The Living Atlas did not expose the Briar source.")
		return false
	if not await _d4_scanner_interact(atlas as Node3D):
		return false
	var dialog := get_tree().get_first_node_in_group("ChartRumourSourceDialog")
	if dialog == null or not dialog.has_method("_finish"):
		_web_smoke_d4_fail("The Briar source did not open its production dialog.")
		return false
	dialog.call("_finish")
	await get_tree().process_frame
	await get_tree().process_frame
	var status := chart_source_status("atlas_briar_knot")
	if String(status.state) != "read" \
			or not (chart_recipe_journal.rumours as Array).has("atlas_briar_knot") \
			or material_count("thorn_rubbing") != 1 \
			or material_count("stitched_parchment") != 1 \
			or material_count("briar_knot") != 1:
		_web_smoke_d4_fail("The Briar source did not grant its missing-only lesson kit.")
		return false
	return true


func _continue_d4_web_smoke() -> void:
	if not web_smoke_d4_enabled or web_smoke_phase == "failed":
		return
	await _wait_d4_town_control()
	if web_smoke_phase == "failed":
		return
	if _web_smoke_d4_briar_ids.size() < 4:
		_web_smoke_d4_stage = "briar_%d" % (_web_smoke_d4_briar_ids.size() + 1)
		await _inscribe_d4_briar()
		return
	if CampaignData.chapter_clue_count(campaign_state, CampaignData.SEVENTH_ROAD) != 4 \
			or material_count("wightpelt") != 1 \
			or not (chart_recipe_journal.rumours as Array).has("seventh_road_boss"):
		_web_smoke_d4_fail("Four Briar returns did not settle the Seventh Road ledger.")
		return
	if _web_smoke_d4_clue_ids != CampaignData.SEVENTH_ROAD_CLUES:
		_web_smoke_d4_fail("The four Briar Worlds did not present four distinct Cold Tracks.")
		return
	web_smoke_features["d4_four_briar_table_loops"] = true
	web_smoke_features["d4_four_distinct_cold_tracks"] = true
	if web_smoke_d7_enabled and _web_smoke_d7_stage == "prior_seventh_road":
		await _d7_prepare_seventh_boss_from_earned_state()
		return
	_apply_campaign_material_targets({"mothmint": 2, "hedge_ink": 4,
		"thorn_rubbing": 1, "stitched_parchment": 1, "briar_knot": 1})
	web_smoke_features["d4_bounded_makings_fixture"] = true
	if not await _mix_d4_mothglow_13_to_14():
		return
	await _inscribe_d4_wolf_chart()


func _inscribe_d4_briar() -> void:
	var chart := await _d4_table_inscribe("briar_maze",
		["thorn_rubbing", "stitched_parchment", "briar_knot"])
	if chart.is_empty():
		return
	var chart_id := String(chart.get("chart_instance_id", ""))
	if chart_id == "" or _web_smoke_d4_briar_ids.has(chart_id):
		_web_smoke_d4_fail("Briar Maze did not mint a distinct physical Chart.")
		return
	_web_smoke_d4_briar_ids.append(chart_id)
	web_smoke_report("briar_table_%d" % _web_smoke_d4_briar_ids.size())
	if web_smoke_d7_enabled:
		_d7_socket_chart_at_town.bind(chart).call_deferred()
	else:
		enter_dungeon(chart, local_player())


func _d4_table_inscribe(recipe_id: String, supplies_to_press: Array,
		preview_phase: String = "") -> Dictionary:
	var bench: Node = await _open_d1_chart_table()
	if bench == null or web_smoke_phase == "failed":
		return {}
	var panel := bench.get_node_or_null("ChartTablePanel")
	var view := panel.get_node_or_null("ChartTableView") if panel != null else null
	var supplies := view.find_child("SuppliesTab", true, false) as Button if view != null else null
	if supplies == null:
		bench.close()
		_web_smoke_d4_fail("The Seventh Road Table had no Supplies tab.")
		return {}
	supplies.pressed.emit()
	await get_tree().process_frame
	var wanted_counts := {}
	for item_id_v in supplies_to_press:
		var item_id := String(item_id_v)
		wanted_counts[item_id] = int(wanted_counts.get(item_id, 0)) + 1
		var before := material_count(item_id)
		var pressed := await _press_d1_supply_control(bench, item_id)
		if not pressed:
			bench.close()
			_web_smoke_d4_fail("The Seventh Road Table rejected %s." % item_id)
			return {}
		var draft: Dictionary = bench.get("draft")
		var staged_count := (draft.get("grid", {}) as Dictionary).values().count(item_id) \
			+ (draft.get("ink_rail", []) as Array).count(item_id)
		if staged_count < int(wanted_counts[item_id]) and material_count(item_id) > before:
			if not await _press_d1_supply_control(bench, item_id):
				bench.close()
				_web_smoke_d4_fail("The renewed %s would not stage." % item_id)
				return {}
	var preview: Dictionary = bench.call("current_preview")
	var action := view.find_child("InscribeChartButton", true, false) as Button
	if String(preview.get("recipe_id", "")) != recipe_id \
			or not bool(preview.get("commit_ready", false)) \
			or action == null or action.disabled:
		bench.close()
		_web_smoke_d4_fail("The physical Table did not resolve %s." % recipe_id)
		return {}
	if recipe_id == "seventh_road_boss":
		var guarantees: Array = preview.get("guaranteed", [])
		if String((preview.get("output", {}) as Dictionary).get("name", "")) \
				!= "Wolf Alpha's Seventh Road" or guarantees.is_empty() \
				or String((guarantees[0] as Dictionary).get("id", "")) != "wolf_alpha" \
				or preview.get("returned_on_failure", {}) != {"wightpelt": 1} \
				or not (preview.get("preparation_notes", []) as Array).has(
					"Mothglow Ink — mixed at Wildcraft 14."):
			bench.close()
			_web_smoke_d4_fail("The Wolf preview did not expose its full Seventh contract.")
			return {}
		web_smoke_features["d4_wolf_preview_contract"] = true
		web_smoke_report("wolf_preview")
	elif recipe_id == "queens_summit":
		# The retired recipe is deliberately not a D4 physical-Table path.  D4
		# exercises only frozen materialized records below; a future caller cannot
		# accidentally turn compatibility QA back into new legacy inscription.
		bench.close()
		_web_smoke_d4_fail("D4 may not physically inscribe the retired Summit recipe.")
		return {}
	var charts_before := charts.size()
	action.pressed.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	var chart: Dictionary = charts.back() if charts.size() == charts_before + 1 else {}
	bench.close()
	if String(chart.get("recipe_id", "")) != recipe_id:
		_web_smoke_d4_fail("The Seventh Road Table did not mint %s." % recipe_id)
		return {}
	return chart


func _mix_d4_mothglow_13_to_14() -> bool:
	# D4's standalone release proof intentionally demonstrates the blocked
	# Wildcraft-13 pot, then uses a narrow level fixture for its second half.
	# Fresh D7 has already earned Wildcraft 14 on the repeatable training road,
	# so it must use the same real pot without replaying that fixture mutation.
	if web_smoke_d7_enabled:
		return await _d7_mix_mothglow_from_earned_level()
	var before := {"mothmint": material_count("mothmint"),
		"hedge_ink": material_count("hedge_ink"),
		"mothglow_ink": material_count("mothglow_ink")}
	var bench: Node = await _open_d1_chart_table()
	if bench == null:
		return false
	var panel := bench.get_node_or_null("ChartTablePanel")
	var view := panel.get_node_or_null("ChartTableView") if panel != null else null
	var mix := view.find_child("MixTab", true, false) as Button if view != null else null
	if mix == null:
		bench.close()
		_web_smoke_d4_fail("The Seventh Road Table had no Mix tab.")
		return false
	mix.pressed.emit()
	await get_tree().process_frame
	for item_id in ["mothmint", "mothmint", "hedge_ink"]:
		if not await _press_d1_supply_control(bench, item_id):
			bench.close()
			_web_smoke_d4_fail("The Mothglow pot rejected %s." % item_id)
			return false
	var try_mix := view.find_child("TryMixButton", true, false) as Button
	if try_mix == null or try_mix.disabled:
		bench.close()
		_web_smoke_d4_fail("The Wildcraft-13 Mothglow pot could not be tested.")
		return false
	try_mix.pressed.emit()
	await get_tree().process_frame
	if material_count("mothmint") != int(before.mothmint) \
			or material_count("hedge_ink") != int(before.hedge_ink) \
			or material_count("mothglow_ink") != int(before.mothglow_ink) \
			or not String(bench.call("mix_feedback")).contains("Wildcraft 14"):
		bench.close()
		_web_smoke_d4_fail("Mothglow did not remain blocked and unspent at Wildcraft 13.")
		return false
	bench.close()
	web_smoke_features["d4_mothglow_level_gate"] = true
	web_smoke_report("mothglow_blocked_13")
	trades.wildcraft = {"xp": Progression.xp_for_level(14), "lv": 14}
	bench = await _open_d1_chart_table()
	if bench == null:
		return false
	panel = bench.get_node_or_null("ChartTablePanel")
	view = panel.get_node_or_null("ChartTableView") if panel != null else null
	mix = view.find_child("MixTab", true, false) as Button if view != null else null
	if mix == null:
		bench.close()
		_web_smoke_d4_fail("The Wildcraft-14 Table had no Mix tab.")
		return false
	mix.pressed.emit()
	await get_tree().process_frame
	for item_id in ["mothmint", "mothmint", "hedge_ink"]:
		if not await _press_d1_supply_control(bench, item_id):
			bench.close()
			_web_smoke_d4_fail("The unlocked Mothglow pot rejected %s." % item_id)
			return false
	try_mix = view.find_child("TryMixButton", true, false) as Button
	if try_mix == null or try_mix.disabled:
		bench.close()
		_web_smoke_d4_fail("The Wildcraft-14 Mothglow pot did not enable Try the Mix.")
		return false
	try_mix.pressed.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	bench.close()
	if material_count("mothmint") != int(before.mothmint) - 2 \
			or material_count("hedge_ink") != int(before.hedge_ink) - 1 \
			or material_count("mothglow_ink") != int(before.mothglow_ink) + 1 \
			or not ink_discovered("mothglow_ink"):
		_web_smoke_d4_fail("Mothglow did not settle through production controls at Wildcraft 14.")
		return false
	web_smoke_features["d4_mothglow_production_controls"] = true
	web_smoke_report("mothglow_mixed_14")
	return true


func _d7_mix_mothglow_from_earned_level() -> bool:
	if trade_lv("wildcraft") < 14:
		_web_smoke_d7_fail("D7 tried Mothglow before its production Wildcraft-14 gate.")
		return false
	var before := {"mothmint": material_count("mothmint"),
		"hedge_ink": material_count("hedge_ink"), "mothglow_ink": material_count("mothglow_ink")}
	var bench: Node = await _d7_open_chart_table()
	if bench == null:
		return false
	var panel := bench.get_node_or_null("ChartTablePanel")
	var view := panel.get_node_or_null("ChartTableView") if panel != null else null
	var mix := view.find_child("MixTab", true, false) as Button if view != null else null
	if mix == null:
		bench.close()
		_web_smoke_d7_fail("D7 could not open the physical Mothglow pot.")
		return false
	mix.pressed.emit()
	await get_tree().process_frame
	for item_id in ["mothmint", "mothmint", "hedge_ink"]:
		if not await _press_d6_supply_control(bench, item_id):
			bench.close()
			_web_smoke_d7_fail("D7's earned Mothglow pot rejected %s." % item_id)
			return false
	await get_tree().process_frame
	if material_count("mothglow_ink") == int(before.mothglow_ink):
		var try_mix := view.find_child("TryMixButton", true, false) as Button
		if try_mix == null or try_mix.disabled:
			bench.close()
			_web_smoke_d7_fail("D7's earned Mothglow pot never exposed Try the Mix.")
			return false
		try_mix.pressed.emit()
		await get_tree().process_frame
		await get_tree().process_frame
	bench.close()
	if material_count("mothmint") != int(before.mothmint) - 2 \
			or material_count("hedge_ink") != int(before.hedge_ink) - 1 \
			or material_count("mothglow_ink") != int(before.mothglow_ink) + 1 \
			or not ink_discovered("mothglow_ink"):
		_web_smoke_d7_fail("D7's earned Mothglow pot did not settle through production controls.")
		return false
	return true


func _inscribe_d4_wolf_chart() -> void:
	var chart := await _d4_table_inscribe("seventh_road_boss",
		["thorn_rubbing", "stitched_parchment", "briar_knot",
		"mothglow_ink", "wightpelt"])
	if chart.is_empty():
		return
	var attempt_id := String(chart.get("attempt_id", ""))
	var escrow: Dictionary = (campaign_state.escrows as Dictionary).get(attempt_id, {})
	if attempt_id == "" or String(escrow.get("phase", "")) != "case":
		_web_smoke_d4_fail("The Wolf Chart did not open its Wightpelt escrow.")
		return
	_web_smoke_d4_wolf_chart = chart.duplicate(true)
	web_smoke_features["d4_wolf_table_escrow"] = true
	_web_smoke_d4_stage = "wolf_world"
	if web_smoke_d7_enabled:
		_d7_socket_chart_at_town.bind(chart).call_deferred()
	else:
		enter_dungeon(chart, local_player())


func _drive_d4_wolf_world() -> void:
	var boss := _d4_find_boss("wolf_alpha")
	if boss == null or String(run_cfg().get("boss_kind", "")) != "wolf_alpha":
		_web_smoke_d4_fail("The Seventh World did not build its guaranteed Wolf Alpha.")
		return
	web_smoke_features["d4_world_wolf_alpha"] = true
	web_smoke_report("wolf_world")
	var pickup_ids_before := {}
	if web_smoke_d7_enabled:
		for pickup_v in get_tree().current_scene.find_children("*", "ItemPickup", true, false):
			pickup_ids_before[(pickup_v as Node).get_instance_id()] = true
	var alpha_before := material_count("alpha_fang")
	boss.call("take_damage", int(boss.get("hp")) + 1, Vector3.ZERO)
	await get_tree().process_frame
	var attempt_id := String(_web_smoke_d4_wolf_chart.get("attempt_id", ""))
	var escrow: Dictionary = (campaign_state.escrows as Dictionary).get(attempt_id, {})
	if not CampaignData.chapter_cleared(campaign_state, CampaignData.SEVENTH_ROAD) \
			or String(escrow.get("phase", "")) != "consumed" \
			or material_count("alpha_fang") != alpha_before + 1 \
			or not (campaign_state.relics as Array).has("fang_root_rune") \
			or not (campaign_state.restorations as Array).has("skald_archive"):
		_web_smoke_d4_fail("Wolf death did not settle the Seventh Road exactly once.")
		return
	web_smoke_features["d4_wolf_death_settlement"] = true
	web_smoke_report("wolf_cleared")
	_web_smoke_d4_stage = "wolf_return"
	if web_smoke_d7_enabled:
		if not await _d7_collect_wolf_boss_sale_item(pickup_ids_before):
			return
		_d7_schedule_far_waystone_return(0.35, "d4_boss")
	else:
		get_tree().create_timer(0.35).timeout.connect(func() -> void: return_to_town(local_player(), false))


func _d7_collect_wolf_boss_sale_item(pickup_ids_before: Dictionary) -> bool:
	# Boss loot cascades over 160 ms.  Wait for all three production
	# ItemPickups, choose the most valuable guaranteed rare+ piece, then acquire
	# it only through PlayerController's released G action.
	await get_tree().create_timer(0.24, true).timeout
	await get_tree().physics_frame
	var best: ItemPickup = null
	var best_value := -1
	for pickup_v in get_tree().current_scene.find_children("*", "ItemPickup", true, false):
		if not pickup_v is ItemPickup \
				or pickup_ids_before.has((pickup_v as Node).get_instance_id()):
			continue
		var candidate: Dictionary = pickup_v.get("_item")
		var rarity := String(candidate.get("rarity", ""))
		var value := EconomyData.sell_value(candidate)
		if rarity not in ["rare", "unique"] or not bool(candidate.get("sellable", true)) \
				or value <= 0:
			continue
		if value > best_value:
			best = pickup_v as ItemPickup
			best_value = value
	if best == null:
		_web_smoke_d7_fail("The Wolf boss did not leave a new guaranteed sellable rare+ ItemPickup.")
		return false
	var item: Dictionary = best.get("_item")
	var token := "d7-wolf-%d-%d" % [_web_smoke_d7_world_generation,
		best.get_instance_id()]
	item["_d7_sale_token"] = token
	best.set("_item", item)
	var player := local_player() as Node3D
	if player == null or inventory == null:
		_web_smoke_d7_fail("The Wolf loot pickup had no live player Pack.")
		return false
	var inventory_before := inventory.items.size()
	var wayfinding_before := int((trades.get("wayfinding", {}) as Dictionary).get("xp", 0))
	# Cross the pickup boundary before standing on the chosen drop. Nearby boss
	# drops may overlap, so the exact target position makes this one nearest.
	var pickup_position := (best as Node3D).global_position
	player.global_position = pickup_position + Vector3(3.0, 0.0, 0.0)
	if player is CharacterBody3D:
		(player as CharacterBody3D).velocity = Vector3.ZERO
	await get_tree().physics_frame
	await get_tree().process_frame
	player.global_position = pickup_position
	if player is CharacterBody3D:
		(player as CharacterBody3D).velocity = Vector3.ZERO
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().process_frame
	var overlaps: Variant = player.get("_overlapping_pickups")
	if not (overlaps is Array) or not (overlaps as Array).has(best):
		_web_smoke_d7_fail("The released PickupScanner did not acquire the chosen Wolf boss drop.")
		return false
	Input.action_press(&"grab")
	await get_tree().physics_frame
	Input.action_release(&"grab")
	await get_tree().process_frame
	await get_tree().process_frame
	var carried: Array = inventory.items.filter(func(raw):
		return raw is Dictionary and String((raw as Dictionary).get(
			"_d7_sale_token", "")) == token)
	if carried.size() != 1 or inventory.items.size() != inventory_before + 1 \
			or int((trades.get("wayfinding", {}) as Dictionary).get("xp", 0)) \
			!= wayfinding_before:
		_web_smoke_d7_fail("The released G pickup did not bank exactly one unchanged Wolf sale item.")
		return false
	_web_smoke_d7_sale_item = carried[0]
	web_smoke_features["d7_wolf_boss_loot_receipt"] = {
		"token": token,
		"kind_id": String(item.get("kind_id", "")),
		"name": String(item.get("name", "")),
		"rarity": String(item.get("rarity", "")),
		"sell_value": best_value,
		"inventory_before": inventory_before,
		"inventory_after": inventory.items.size(),
		"wayfinding_xp": wayfinding_before,
		"pickup_action": "grab",
	}
	web_smoke_features["d7_real_wolf_boss_pickup"] = true
	return true


func _verify_d4_seventh_settlement() -> void:
	await _wait_d4_town_control()
	if web_smoke_phase == "failed":
		return
	var scene := get_tree().current_scene
	var hall := scene.get_node_or_null("FirstKnotTrophyHall") if scene != null else null
	var atlas := scene.get_node_or_null("AtlasDeepRumourSource") if scene != null else null
	var archive := scene.get_node_or_null("SkaldArchive") if scene != null else null
	if hall == null or hall.get_node_or_null("SeventhRoadRecord") == null \
			or hall.get_node_or_null("FangRootRune") == null \
			or hall.get_node_or_null("AlphaFangRecord") == null:
		_web_smoke_d4_fail("Town did not project the Seventh Road Hall record.")
		return
	web_smoke_report("seventh_hall")
	if atlas == null or not atlas.has_method("seventh_road_settlement_visible") \
			or not bool(atlas.call("seventh_road_settlement_visible")) \
			or atlas.get_node_or_null("SeventhRoadAtlasMark") == null:
		_web_smoke_d4_fail("The Living Atlas did not acknowledge Seventh Road settlement.")
		return
	web_smoke_report("seventh_atlas")
	if archive == null or not archive.visible \
			or archive.get_node_or_null("FangRootRune") == null:
		_web_smoke_d4_fail("The restored Skald Archive was not present in Town.")
		return
	web_smoke_features["d4_seventh_town_projection"] = true
	web_smoke_report("skald_archive")
	if web_smoke_d7_enabled and _web_smoke_d7_stage == "prior_seventh_road":
		web_smoke_d4_enabled = false
		_web_smoke_d7_stage = "prior_queens_summit"
		web_smoke_report("seventh_road_complete")
		_d7_record_progressive_level_ledger("seventh_road_settlement")
		_d7_begin_queens_summit_from_earned_state.call_deferred()
		return
	_apply_campaign_material_targets({"cold_track": 1, "climbing_cord": 2})
	var lesson_before := {"atlas_folio": material_count("atlas_folio"),
		"cold_track": material_count("cold_track"),
		"climbing_cord": material_count("climbing_cord")}
	if not await _d4_scanner_interact(archive as Node3D):
		return
	var dialog := get_tree().get_first_node_in_group("SkaldArchiveDialog")
	if dialog == null or not dialog.has_method("_finish"):
		_web_smoke_d4_fail("The Archive did not open its production review dialog.")
		return
	dialog.call("_finish")
	await get_tree().process_frame
	await get_tree().process_frame
	var status := chart_source_status("skald_queens_summit")
	if String(status.state) != "read" \
			or material_count("atlas_folio") != int(lesson_before.atlas_folio) + 1 \
			or material_count("cold_track") != int(lesson_before.cold_track) + 1 \
			or material_count("climbing_cord") != int(lesson_before.climbing_cord):
		_web_smoke_d4_fail("The Archive did not apply its missing-only Summit lesson.")
		return
	web_smoke_features["d4_skald_archive_source_control"] = true
	web_smoke_features["d4_archive_missing_only_lesson"] = true
	web_smoke_report("summit_lesson")
	# D4 is now a compatibility route, not a covert way to keep inscribing the
	# retired recipe.  Freeze the v2-shaped legacy Chart and its `case` escrow
	# after the real Seventh Road route, then prove the historic abandon/retry
	# lifecycle against the normal World adapters.  No Table, clue, or Queen
	# chapter state is injected by this fixture.
	await _begin_d4_frozen_legacy_handoff(false)


func _begin_d4_frozen_legacy_handoff(is_retry: bool) -> void:
	var seed := 94004 if is_retry else 94003
	# This is deliberately a materialized compatibility record, not a call to
	# resolve/commit `queens_summit` through the physical Table.  The provenance
	# matches the release-v2 handoff schema so current code must still accept its
	# old case -> in_run -> terminal lifecycle.
	# A `case` record already has its sole protected Seal in the case.  Mirror
	# that historic materialized state exactly; abandon below is what returns it.
	_apply_campaign_material_targets({"alpha_fang": 0}, true)
	var chart := ChartsData.inscribe("summit", [], 16, "", 0.0, seed)
	chart["recipe_id"] = "queens_summit"
	chart["chart_instance_id"] = "d4-frozen-legacy-summit-%d" % seed
	chart["handoff_contract"] = CampaignData.handoff_contract("queens_summit")
	chart["seal_id"] = "alpha_fang"
	chart["returned_on_failure"] = {"alpha_fang": 1}
	# New handoff creation is intentionally retired.  Install the exact persisted
	# v2 `case` record instead of calling the production begin API: this route is
	# proving that already-frozen saves remain playable, not authoring a new one.
	var attempt_number := int(campaign_state.get("next_attempt_id", 1))
	var attempt_id := "%s-%d" % [CampaignData.LEGACY_SUMMIT_HANDOFF, attempt_number]
	var frozen_state := campaign_state.duplicate(true)
	frozen_state["next_attempt_id"] = attempt_number + 1
	var frozen_escrows: Dictionary = frozen_state.get("escrows", {}).duplicate(true)
	frozen_escrows[attempt_id] = {
		"attempt_id": attempt_id,
		"chart_instance_id": String(chart.chart_instance_id),
		"kind": "handoff",
		"contract_id": CampaignData.LEGACY_SUMMIT_HANDOFF,
		"phase": "case",
		"items": {"alpha_fang": 1},
	}
	frozen_state["escrows"] = frozen_escrows
	campaign_state = CampaignData.normalize_campaign_state(frozen_state)
	chart["attempt_id"] = attempt_id
	var escrow: Dictionary = (campaign_state.escrows as Dictionary).get(attempt_id, {})
	if attempt_id == "" or String(escrow.get("contract_id", "")) \
			!= CampaignData.LEGACY_SUMMIT_HANDOFF \
			or String(escrow.get("phase", "")) != "case":
		_web_smoke_d4_fail("The frozen v2 Summit fixture did not retain a legacy case escrow.")
		return
	if is_retry:
		if attempt_id == _web_smoke_d4_first_handoff_attempt:
			_web_smoke_d4_fail("The frozen legacy retry reused its refunded attempt.")
			return
		web_smoke_features["d4_legacy_retry_new_escrow"] = true
		_web_smoke_d4_stage = "legacy_world_2"
	else:
		_web_smoke_d4_first_handoff_attempt = attempt_id
		web_smoke_features["d4_frozen_legacy_chart_case"] = true
		web_smoke_report("legacy_case_1")
		_web_smoke_d4_stage = "legacy_world_1"
	_web_smoke_d4_summit_chart = chart.duplicate(true)
	enter_dungeon(chart, local_player())


func _drive_d4_summit_abandon() -> void:
	var boss := _d4_find_boss("hedgemother_queen")
	var attempt_id := String(_web_smoke_d4_summit_chart.get("attempt_id", ""))
	var escrow: Dictionary = (campaign_state.escrows as Dictionary).get(attempt_id, {})
	if boss == null or String(run_cfg().get("boss_kind", "")) != "hedgemother_queen" \
			or String(escrow.get("phase", "")) != "in_run":
		_web_smoke_d4_fail("The first Summit did not build its Queen handoff World.")
		return
	web_smoke_features["d4_world_hedgemother_queen"] = true
	web_smoke_features["d4_legacy_world_handoff"] = true
	web_smoke_report("legacy_world_1")
	var abandon_stone: Node3D = null
	for node_v in get_tree().get_nodes_in_group("interactable"):
		if node_v is ExitWaystone and bool(node_v.abandoning):
			abandon_stone = node_v as Node3D
			break
	if abandon_stone == null:
		_web_smoke_d4_fail("The Summit World had no entry-side abandon Waystone.")
		return
	_web_smoke_d4_stage = "summit_abandon_return"
	await _d4_scanner_interact(abandon_stone)


func _verify_d4_summit_refund() -> void:
	await _wait_d4_town_control()
	if web_smoke_phase == "failed":
		return
	var escrow: Dictionary = (campaign_state.escrows as Dictionary).get(
		_web_smoke_d4_first_handoff_attempt, {})
	if String(escrow.get("phase", "")) != "refunded" \
			or material_count("alpha_fang") != 1 \
			or CampaignData.can_inscribe_handoff(campaign_state, "queens_summit"):
		_web_smoke_d4_fail("Abandoning Summit did not refund exactly one Alpha Fang.")
		return
	web_smoke_features["d4_summit_abandon_refund"] = true
	web_smoke_report("legacy_refunded")
	await _begin_d4_frozen_legacy_handoff(true)


func _drive_d4_queen_world() -> void:
	var boss := _d4_find_boss("hedgemother_queen")
	var attempt_id := String(_web_smoke_d4_summit_chart.get("attempt_id", ""))
	var escrow: Dictionary = (campaign_state.escrows as Dictionary).get(attempt_id, {})
	if boss == null or String(run_cfg().get("boss_kind", "")) != "hedgemother_queen" \
			or String(escrow.get("phase", "")) != "in_run":
		_web_smoke_d4_fail("The Summit retry did not build its Queen handoff World.")
		return
	web_smoke_report("legacy_world_2")
	var campaign_before := campaign_state.duplicate(true)
	boss.call("take_damage", int(boss.get("hp")) + 1, Vector3.ZERO)
	await get_tree().process_frame
	escrow = (campaign_state.escrows as Dictionary).get(attempt_id, {})
	var before_chapters: Dictionary = campaign_before.chapters
	if String(escrow.get("phase", "")) != "consumed" \
			or material_count("alpha_fang") != 0 \
			or campaign_state.chapters != before_chapters \
			or campaign_state.relics != campaign_before.relics \
			or campaign_state.restorations != campaign_before.restorations:
		_web_smoke_d4_fail("Queen death did not consume the inert handoff exactly once.")
		return
	web_smoke_features["d4_legacy_handoff_consumed"] = true
	web_smoke_report("legacy_consumed")
	web_smoke_features["d4_gameplay_driver"] = true
	web_smoke_report("complete")


func _d4_find_boss(kind: String) -> Node:
	for foe in get_tree().get_nodes_in_group("enemy"):
		if String(foe.get("role")) == "boss" and String(foe.get("kind")) == kind \
				and foe.has_method("take_damage"):
			return foe
	return null


func _d4_scanner_interact(target: Node3D) -> bool:
	var player := local_player() as Node3D
	if player == null or target == null:
		_web_smoke_d4_fail("The Seventh Road route had no live scanner target.")
		return false
	var home := player.global_position
	var target_pos := target.global_position
	var acquired := false
	for direction in [Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD, Vector3.BACK]:
		for step in 31:
			var distance := lerpf(3.8, 0.85, float(step) / 30.0)
			player.global_position = Vector3(target_pos.x + direction.x * distance,
				home.y, target_pos.z + direction.z * distance)
			await get_tree().physics_frame
			if player.get("_active_interactable") == target:
				acquired = true
				break
		if acquired:
			break
	if not acquired:
		player.global_position = home
		_web_smoke_d4_fail("The player scanner did not acquire a Seventh Road target.")
		return false
	await _press_c2_world_interact()
	if is_instance_valid(player):
		player.global_position = home
	await get_tree().process_frame
	return true


func _wait_d4_town_control() -> void:
	var deadline := Time.get_ticks_msec() + 20000
	var stable_since := -1
	var d7_stability = D7ControlStability.new()
	while Time.get_ticks_msec() < deadline:
		var dialogs: Array = []
		dialogs.append_array(get_tree().get_nodes_in_group("run_debrief"))
		dialogs.append_array(get_tree().get_nodes_in_group("FirstKnotHomecomingDebrief"))
		dialogs.append_array(get_tree().get_nodes_in_group("GoldenWallowSettlementDebrief"))
		if not dialogs.is_empty():
			stable_since = -1
			d7_stability.observe(_d7_control_owner_key(), false)
			for dialog in dialogs:
				if dialog != null and is_instance_valid(dialog) and dialog.has_method("_finish"):
					dialog.call("_finish")
				else:
					_web_smoke_d4_fail("A Seventh Road debrief had no production close action.")
					return
			await get_tree().process_frame
			await get_tree().process_frame
			continue
		if not get_tree().paused and modal_count == 0:
			if _d7_control_observation_enabled():
				if d7_stability.observe(_d7_control_owner_key(), true):
					_d7_record_control_stability("d4_town", d7_stability)
					return
			else:
				if stable_since < 0:
					stable_since = Time.get_ticks_msec()
				if Time.get_ticks_msec() - stable_since >= 650:
					return
		else:
			stable_since = -1
			d7_stability.observe(_d7_control_owner_key(), false)
		if _d7_control_observation_enabled():
			await _d7_wait_control_observation()
		else:
			await get_tree().create_timer(0.1, true).timeout
	_web_smoke_d4_fail("Town never returned stable control for the Seventh Road.")


func _web_smoke_d4_fail(reason: String) -> void:
	_web_smoke_d4_stage = "failed"
	web_smoke_report("failed", reason)


# D5 is the authored Queen's Summit release route.  It starts at the accepted
# post-Seventh boundary, then uses the real Archive, Table, World, Queen death,
# Pale Stair, and Town projection paths.  Query state supplies no Crown-Thorn,
# Queen, Oath Nail, Crown Rune, or Stair truth.
func _web_smoke_d5_scene_ready(scene_name: String, owner_token: Dictionary = {}) -> void:
	if scene_name == "Town":
		if _web_smoke_d5_stage == "":
			_web_smoke_d5_stage = "fixture"
			web_smoke_report("town")
			_setup_d5_post_seventh_fixture.call_deferred()
			return
		if _web_smoke_d5_stage.begins_with("approach_"):
			web_smoke_report("approach_return_%d" % _web_smoke_d5_approach_ids.size())
			get_tree().create_timer(0.35).timeout.connect(_continue_d5_web_smoke)
			return
		if _web_smoke_d5_stage == "queen_return":
			_verify_d5_queen_settlement.call_deferred()
			return
	elif scene_name == "World":
		if _web_smoke_d5_stage.begins_with("approach_"):
			var clue: Dictionary = run_cfg().get("campaign_clue", {})
			var index := _web_smoke_d5_approach_ids.size() - 1
			var expected := String(CampaignData.QUEENS_SUMMIT_CLUES[index]) \
				if index >= 0 and index < CampaignData.QUEENS_SUMMIT_CLUES.size() else ""
			if String(clue.get("clue_id", "")) != expected \
					or String(clue.get("presentation", "")) != "shed_crown_thorn" \
					or String(run_cfg().get("boss_kind", "")) != "":
				_web_smoke_d5_fail("A Crownward World did not carry its boss-free authored Crown-Thorn.")
				return
			_web_smoke_d5_clue_ids.append(expected)
			web_smoke_report("approach_world_%d" % _web_smoke_d5_approach_ids.size())
			if web_smoke_d7_enabled and _web_smoke_d7_stage == "prior_queens_summit":
				_d7_harvest_world_then_return.bind(owner_token).call_deferred()
				return
			if web_smoke_d7_enabled:
				_d7_schedule_far_waystone_return(1.0, "d5_approach")
			else:
				get_tree().create_timer(1.0).timeout.connect(func() -> void: return_to_town(local_player(), false))
		elif _web_smoke_d5_stage == "queen_world":
			get_tree().create_timer(0.7).timeout.connect(_drive_d5_queen_world)
		else:
			_web_smoke_d5_fail("A World opened outside the Queen's Summit release route.")


func _setup_d5_post_seventh_fixture() -> void:
	campaign_state = CampaignData.empty_state()
	for chapter_id in [CampaignData.FIRST_KNOT, CampaignData.GOLDEN_WALLOW,
		CampaignData.SEVENTH_ROAD]:
		var chapter: Dictionary = campaign_state.chapters[chapter_id]
		chapter.cleared = true
		chapter.clue_count = int(CampaignData.CHAPTERS[chapter_id].clue_target)
	campaign_state.relics = ["green_root_rune", "mist_root_rune", "fang_root_rune"]
	campaign_state.restorations = ["trophy_hall", "sallow_jetty", "skald_archive"]
	trades.wayfinding = {"xp": Progression.xp_for_level(17), "lv": 17}
	trades.wildcraft = {"xp": Progression.xp_for_level(14), "lv": 14}
	chart_source_unlocks = ChartsData.normalize_chart_source_unlocks(["atlas_sallow_shallows",
		"atlas_briar_knot", "skald_queens_summit"])
	known_chart_recipes = ChartsData.starting_recipe_ids()
	chart_recipe_journal = ChartsData.fresh_recipe_journal()
	seen_hints["chart_table_snug_returned"] = true
	discovered_inks = ["hedge_ink", "mire_ink", "mothglow_ink", "refined_ink"]
	charts = []
	gold = 1600
	# The lone Fang is established Seventh Road settlement stock, not a Queen
	# truth claim. Archive supplies are intentionally absent until its real read.
	_apply_campaign_material_targets({"alpha_fang": 1, "thorn_rubbing": 1})
	web_smoke_features["d5_post_seventh_fixture"] = true
	var town := get_tree().current_scene
	if town != null and town.has_method("_refresh_campaign_settlement_view"):
		town.call("_refresh_campaign_settlement_view")
	if town != null and town.has_method("_apply_driving_volley_lesson"):
		town.call("_apply_driving_volley_lesson")
	await _wait_d5_town_control()
	if web_smoke_phase == "failed":
		return
	var archive := town.get_node_or_null("SkaldArchive") if town != null else null
	if archive == null or not bool(archive.visible):
		_web_smoke_d5_fail("The post-Seventh fixture did not project its restored Skald Archive.")
		return
	web_smoke_report("post_seventh_settlement")
	if not await _d5_read_archive_source(archive as Node3D):
		return
	web_smoke_features["d5_real_archive_source"] = true
	web_smoke_report("archive_source")
	# This is bounded ordinary making stock. Four approaches consume four
	# Refined/Hedge Inks and the Queen then consumes its own visible pair.
	_apply_campaign_material_targets({"cold_track": 8, "atlas_folio": 5,
		"climbing_cord": 10, "refined_ink": 5, "hedge_ink": 20,
		"thorn_rubbing": 1, "alpha_fang": 1})
	web_smoke_features["d5_bounded_makings_fixture"] = true
	_web_smoke_d5_stage = "approach_1"
	await _inscribe_d5_approach()


func _d5_read_archive_source(archive: Node3D) -> bool:
	if not await _d5_scanner_interact(archive):
		return false
	var dialog := get_tree().get_first_node_in_group("SkaldArchiveDialog")
	if dialog == null or not dialog.has_method("_finish"):
		_web_smoke_d5_fail("The restored Skald Archive did not open its production dialog.")
		return false
	dialog.call("_finish")
	await get_tree().process_frame
	await get_tree().process_frame
	var status := chart_source_status("skald_queens_summit")
	if String(status.get("state", "")) != "read" \
			or material_count("cold_track") != 2 or material_count("atlas_folio") != 1 \
			or material_count("climbing_cord") != 2:
		_web_smoke_d5_fail("The real Archive did not grant the Crownward lesson kit.")
		return false
	return true


func _continue_d5_web_smoke() -> void:
	if not web_smoke_d5_enabled or web_smoke_phase == "failed":
		return
	await _wait_d5_town_control()
	if web_smoke_phase == "failed":
		return
	if _web_smoke_d5_approach_ids.size() < 4:
		_web_smoke_d5_stage = "approach_%d" % (_web_smoke_d5_approach_ids.size() + 1)
		await _inscribe_d5_approach()
		return
	if _web_smoke_d5_clue_ids != CampaignData.QUEENS_SUMMIT_CLUES \
			or CampaignData.chapter_clue_count(campaign_state, CampaignData.QUEENS_SUMMIT) != 4 \
			or not (chart_recipe_journal.rumours as Array).has("queens_summit_boss"):
		_web_smoke_d5_fail("Four physical Crownward returns did not bank the Queen road.")
		return
	web_smoke_features["d5_four_approach_table_loops"] = true
	web_smoke_features["d5_four_distinct_crown_thorns"] = true
	if web_smoke_d7_enabled and _web_smoke_d7_stage == "prior_queens_summit":
		await _d7_prepare_queen_boss_from_earned_state()
		return
	await _inscribe_d5_queen_chart()


func _inscribe_d5_approach() -> void:
	var chart := await _d5_table_inscribe("summit_approach", ["cold_track", "cold_track",
		"atlas_folio", "climbing_cord", "climbing_cord", "refined_ink"],
		"approach_table_%d" % (_web_smoke_d5_approach_ids.size() + 1))
	if chart.is_empty():
		return
	var chart_id := String(chart.get("chart_instance_id", ""))
	if chart_id == "" or _web_smoke_d5_approach_ids.has(chart_id):
		_web_smoke_d5_fail("Crownward Ascent did not mint a distinct physical Chart.")
		return
	_web_smoke_d5_approach_ids.append(chart_id)
	if web_smoke_d7_enabled:
		_d7_socket_chart_at_town.bind(chart).call_deferred()
	else:
		enter_dungeon(chart, local_player())


func _inscribe_d5_queen_chart() -> void:
	var chart := await _d5_table_inscribe("queens_summit_boss", ["cold_track",
		"thorn_rubbing", "atlas_folio", "climbing_cord", "climbing_cord",
		"refined_ink", "alpha_fang"], "queen_preview")
	if chart.is_empty():
		return
	var attempt_id := String(chart.get("attempt_id", ""))
	var escrow: Dictionary = (campaign_state.escrows as Dictionary).get(attempt_id, {})
	if attempt_id == "" or String(escrow.get("phase", "")) != "case":
		_web_smoke_d5_fail("Queen's Summit did not open the canonical Alpha Fang escrow.")
		return
	_web_smoke_d5_queen_chart = chart.duplicate(true)
	web_smoke_features["d5_queen_table_escrow"] = true
	_web_smoke_d5_stage = "queen_world"
	if web_smoke_d7_enabled:
		_d7_socket_chart_at_town.bind(chart).call_deferred()
	else:
		enter_dungeon(chart, local_player())


func _d5_table_inscribe(recipe_id: String, supplies_to_press: Array,
		phase: String) -> Dictionary:
	var bench: Node = await _open_d1_chart_table()
	if bench == null:
		_web_smoke_d5_fail("The authored Table did not open for %s." % recipe_id)
		return {}
	var panel := bench.get_node_or_null("ChartTablePanel")
	var view := panel.get_node_or_null("ChartTableView") if panel != null else null
	var supplies := view.find_child("SuppliesTab", true, false) as Button if view != null else null
	if supplies == null:
		bench.close()
		_web_smoke_d5_fail("The Queen route's physical Table had no Supplies tab.")
		return {}
	supplies.pressed.emit()
	await get_tree().process_frame
	var wanted := {}
	for item_v in supplies_to_press:
		var item_id := String(item_v)
		wanted[item_id] = int(wanted.get(item_id, 0)) + 1
		if not await _d5_stage_supply_exact(bench, recipe_id, phase, item_id,
				int(wanted[item_id])):
			bench.close()
			return {}
	var preview: Dictionary = bench.call("current_preview")
	var action := view.find_child("InscribeChartButton", true, false) as Button
	var grid: Dictionary = bench.get("draft").get("grid", {})
	var rail: Array = bench.get("draft").get("ink_rail", [])
	var expected_grid := {"nw": "cold_track", "n": "cold_track", "c": "atlas_folio",
		"w": "climbing_cord", "e": "climbing_cord"} if recipe_id == "summit_approach" \
		else {"nw": "cold_track", "n": "thorn_rubbing", "c": "atlas_folio",
			"w": "climbing_cord", "e": "climbing_cord", "s": "alpha_fang"}
	if String(preview.get("recipe_id", "")) != recipe_id \
			or not bool(preview.get("commit_ready", false)) or action == null or action.disabled \
			or grid != expected_grid or rail != ["refined_ink"]:
		bench.close()
		_web_smoke_d5_fail("The physical Table did not resolve the exact %s grammar." % recipe_id)
		return {}
	if recipe_id == "summit_approach":
		if not (preview.get("campaign_contract", {}) as Dictionary).is_empty() \
				or not (preview.get("handoff_contract", {}) as Dictionary).is_empty() \
				or String((preview.get("output", {}) as Dictionary).get("name", "")) != "Crownward Ascent":
			bench.close()
			_web_smoke_d5_fail("Crownward Ascent was not a boss-free authored preview.")
			return {}
	else:
		var contract: Dictionary = preview.get("campaign_contract", {})
		var guarantees: Array = preview.get("guaranteed", [])
		if contract != CampaignData.boss_contract("queens_summit_boss") \
				or String((preview.get("output", {}) as Dictionary).get("name", "")) != "Queen's Summit" \
				or preview.get("returned_on_failure", {}) != {"alpha_fang": 1} \
				or guarantees.is_empty() or String((guarantees[0] as Dictionary).get("id", "")) != "hedgemother_queen":
			bench.close()
			_web_smoke_d5_fail("Queen's Summit did not visibly bind Refined Ink and Alpha Fang to its contract.")
			return {}
		web_smoke_features["d5_queen_preview_contract"] = true
	web_smoke_features["d5_real_table_commits"] = true
	web_smoke_report(phase)
	var before_costs := {}
	for material_v in (preview.get("costs", {}) as Dictionary):
		before_costs[String(material_v)] = material_count(String(material_v))
	var charts_before := charts.size()
	action.pressed.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	var chart: Dictionary = charts.back() if charts.size() == charts_before + 1 else {}
	bench.close()
	if chart.is_empty() or String(chart.get("recipe_id", "")) != recipe_id:
		_web_smoke_d5_fail("The real Inscribe Chart Control did not commit %s." % recipe_id)
		return {}
	for material_v in (preview.get("costs", {}) as Dictionary):
		var material_id := String(material_v)
		if material_count(material_id) != int(before_costs[material_id]) \
				- int((preview.get("costs", {}) as Dictionary)[material_v]):
			_web_smoke_d5_fail("%s did not charge its exact %s cost." % [recipe_id, material_id])
			return {}
	return chart


func _d5_staged_supply_count(bench: Node, item_id: String) -> int:
	var draft: Dictionary = bench.get("draft")
	return (draft.get("grid", {}) as Dictionary).values().count(item_id) \
		+ (draft.get("ink_rail", []) as Array).count(item_id)


func _d5_stage_supply_exact(bench: Node, recipe_id: String, phase: String,
		item_id: String, wanted: int) -> bool:
	var authored_price := ChartsData.component_supply_price(item_id)
	for _attempt in 2:
		var staged_before := _d5_staged_supply_count(bench, item_id)
		if staged_before >= wanted:
			return true
		var owned_before := material_count(item_id)
		var gold_before := gold
		if not await _press_d1_supply_control(bench, item_id):
			return _d5_fail_supply_transaction(bench, recipe_id, phase, item_id,
				wanted, authored_price, "row_missing_or_disabled")
		var staged_after := _d5_staged_supply_count(bench, item_id)
		var owned_after := material_count(item_id)
		var gold_after := gold
		# Existing stock stages without moving durable inventory or gold.
		if staged_after == staged_before + 1 and owned_after == owned_before \
				and gold_after == gold_before:
			continue
		# Empty renewable stock buys exactly one unit. The production bench may
		# reserve it in the same activation or rebuild the row for one follow-up
		# press; both paths must show the exact durable purchase transaction.
		if staged_after in [staged_before, staged_before + 1] \
				and owned_after == owned_before + 1 and authored_price > 0 \
				and gold_after == gold_before - authored_price:
			if web_smoke_d7_enabled:
				var purchases: Array = (web_smoke_features.get(
					"d7_component_purchase_receipts", []) as Array).duplicate(true)
				purchases.append({"recipe_id": recipe_id, "phase": phase,
					"component_id": item_id, "unit_price": authored_price,
					"gold_before": gold_before, "gold_after": gold_after,
					"owned_before": owned_before, "owned_after": owned_after,
					"staged_before": staged_before})
				web_smoke_features["d7_component_purchase_receipts"] = purchases
				var budget: Dictionary = (web_smoke_features.get(
					"d7_queen_component_budget", {}) as Dictionary).duplicate(true)
				budget["actual_component_spend"] = int(budget.get(
					"actual_component_spend", 0)) + authored_price
				web_smoke_features["d7_queen_component_budget"] = budget
			continue
		return _d5_fail_supply_transaction(bench, recipe_id, phase, item_id,
			wanted, authored_price, "activation_changed_no_valid_transaction")
	if _d5_staged_supply_count(bench, item_id) == wanted:
		return true
	return _d5_fail_supply_transaction(bench, recipe_id, phase, item_id, wanted,
		authored_price, "wanted_count_not_staged")


func _d5_fail_supply_transaction(bench: Node, recipe_id: String, phase: String,
		item_id: String, wanted: int, authored_price: int, reason: String) -> bool:
	var draft: Dictionary = bench.get("draft")
	var panel := bench.get_node_or_null("ChartTablePanel")
	var view := panel.get_node_or_null("ChartTableView") if panel != null else null
	var row := view.find_child("Supply_%s" % item_id, true, false) as Button \
		if view != null else null
	var detail := {
		"recipe_id": recipe_id,
		"phase": phase,
		"component": item_id,
		"reason": reason,
		"wanted": wanted,
		"staged": _d5_staged_supply_count(bench, item_id),
		"owned": material_count(item_id),
		"gold": gold,
		"price": authored_price,
		"row_present": row != null,
		"row_disabled": row.disabled if row != null else true,
		"grid": (draft.get("grid", {}) as Dictionary).duplicate(true),
		"rail": (draft.get("ink_rail", []) as Array).duplicate(true),
		"preview": bench.call("current_preview"),
	}
	web_smoke_features["d5_last_supply_failure"] = detail
	_web_smoke_d5_fail("The Table could not stage its exact visible supply: %s." % detail)
	return false


func _drive_d5_queen_world() -> void:
	var boss := _d4_find_boss("hedgemother_queen")
	var attempt_id := String(_web_smoke_d5_queen_chart.get("attempt_id", ""))
	var escrow: Dictionary = (campaign_state.escrows as Dictionary).get(attempt_id, {})
	if boss == null or String(run_cfg().get("boss_kind", "")) != "hedgemother_queen" \
			or String(escrow.get("phase", "")) != "in_run":
		_web_smoke_d5_fail("The canonical Queen World did not bind its live campaign escrow.")
		return
	web_smoke_features["d5_world_forced_queen"] = true
	web_smoke_report("queen_world")
	var oath_before := material_count("oath_nail")
	boss.call("take_damage", int(boss.get("hp")) + 1, Vector3.ZERO)
	await get_tree().process_frame
	await get_tree().process_frame
	escrow = (campaign_state.escrows as Dictionary).get(attempt_id, {})
	if String(escrow.get("phase", "")) != "consumed" \
			or not CampaignData.chapter_cleared(campaign_state, CampaignData.QUEENS_SUMMIT) \
			or material_count("oath_nail") != oath_before + 1 \
			or not (campaign_state.relics as Array).has("crown_root_rune") \
			or not (campaign_state.restorations as Array).has("pale_stair"):
		_web_smoke_d5_fail("Canonical Queen death did not settle Oath Nail, Crown Root, and Pale Stair once.")
		return
	web_smoke_features["d5_canonical_queen_settlement"] = true
	web_smoke_report("queen_cleared")
	var stair := get_tree().get_first_node_in_group("pale_stair") as Node3D
	if stair == null:
		var world := get_tree().current_scene
		_web_smoke_d5_fail("Canonical Queen settlement did not reveal a live Pale Stair " \
			+ "(scene=%s, arena_ready=%s, arena_center=%s, landmark=%s)." % [
				String(world.name) if world != null else "<null>",
				str(world.get("_boss_arena_ready")) if world != null else "<null>",
				str(world.get("_boss_arena_center")) if world != null else "<null>",
				str(world.call("pale_stair_landmark")) if world != null \
					and world.has_method("pale_stair_landmark") else "<no-adapter>",
			])
		return
	if not await _d5_read_pale_stair_twice(stair):
		return
	web_smoke_features["d5_pale_stair_two_reads"] = true
	_web_smoke_d5_stage = "queen_return"
	if web_smoke_d7_enabled:
		_d7_schedule_far_waystone_return(0.35, "d5_queen")
	else:
		get_tree().create_timer(0.35).timeout.connect(func() -> void: return_to_town(local_player(), false))


func _d5_read_pale_stair_twice(stair: Node3D) -> bool:
	var campaign_before := campaign_state.duplicate(true)
	var materials_before := materials.duplicate(true)
	for read_index in 2:
		if not await _d5_scanner_interact(stair):
			return false
		web_smoke_report("pale_stair_interact_%d" % (read_index + 1))
		var dialog := get_tree().get_first_node_in_group("PaleStairDialog")
		if dialog == null or not dialog.has_method("_finish"):
			_web_smoke_d5_fail("The Pale Stair did not open its repeatable production dialog.")
			return false
		dialog.call("_finish")
		await get_tree().process_frame
		var read: Dictionary = stair.call("read_now")
		if not bool(read.get("ok", false)) or bool(read.get("changed", true)) \
				or not bool(read.get("repeatable", false)) \
				or String(read.get("route", "")) != "pale_oath_not_yet_walkable":
			_web_smoke_d5_fail("The Pale Stair was not a copy-only, not-yet-walkable reading.")
			return false
		web_smoke_report("pale_stair_read_%d" % (read_index + 1))
	if campaign_state != campaign_before or materials != materials_before:
		_web_smoke_d5_fail("Repeated Pale Stair readings changed campaign or inventory state.")
		return false
	web_smoke_report("pale_stair_twice")
	return true


func _verify_d5_queen_settlement() -> void:
	await _wait_d5_town_control()
	if web_smoke_phase == "failed":
		return
	var scene := get_tree().current_scene
	var hall := scene.get_node_or_null("FirstKnotTrophyHall") if scene != null else null
	var atlas := scene.get_node_or_null("AtlasDeepRumourSource") if scene != null else null
	var archive := scene.get_node_or_null("SkaldArchive") if scene != null else null
	if hall == null or hall.get_node_or_null("QueensSummitRecord") == null \
			or hall.get_node_or_null("OathNailRecord") == null \
			or hall.get_node_or_null("CrownRootRune") == null:
		_web_smoke_d5_fail("Town did not project the canonical Queen Hall record.")
		return
	web_smoke_report("queen_hall")
	if atlas == null or not atlas.has_method("queens_summit_settlement_visible") \
			or not bool(atlas.call("queens_summit_settlement_visible")) \
			or atlas.get_node_or_null("QueensSummitAtlasMark") == null:
		_web_smoke_d5_fail("The Living Atlas did not project Crown Root and Pale Stair truth.")
		return
	web_smoke_report("queen_atlas")
	if archive == null or not archive.has_method("queen_settlement_visible") \
			or not bool(archive.call("queen_settlement_visible")):
		_web_smoke_d5_fail("The Skald Archive did not present the canonical Queen settlement.")
		return
	web_smoke_features["d5_queen_town_projection"] = true
	web_smoke_features["d5_gameplay_driver"] = true
	web_smoke_report("queen_archive")
	if web_smoke_d7_enabled and _web_smoke_d7_stage == "prior_queens_summit":
		web_smoke_d5_enabled = false
		_web_smoke_d7_stage = "prior_pale_oath"
		web_smoke_report("queens_summit_complete")
		_d7_record_progressive_level_ledger("queens_summit_settlement")
		_d7_begin_pale_oath_from_earned_state.call_deferred()
		return
	web_smoke_report("complete")


func _d5_scanner_interact(target: Node3D) -> bool:
	var player := local_player() as Node3D
	if player == null or target == null:
		_web_smoke_d5_fail("The Queen route had no live scanner target.")
		return false
	var home := player.global_position
	var last_receipt: Dictionary = {}
	var acquired_once := false
	# A previous interaction can leave `_active_interactable` selected from the
	# scanner's old overlap for one physics edge.  Starting the next sweep at
	# 3.8m then used to mistake that stale selection for a fresh acquisition;
	# the following input edge correctly refused it, while this helper still
	# reported success.  Settle outside first, then require the same target on
	# two inside physics edges before arming PlayerController's exact-target
	# contract.  One bounded retry is allowed only when no actual interaction
	# occurred.
	for _attempt in 2:
		if not is_instance_valid(player) or not is_instance_valid(target):
			break
		var acquired := false
		for direction in [Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD, Vector3.BACK]:
			if not is_instance_valid(player) or not is_instance_valid(target):
				break
			player.global_position = Vector3(
				target.global_position.x + direction.x * 5.0,
				home.y, target.global_position.z + direction.z * 5.0)
			await get_tree().physics_frame
			await get_tree().physics_frame
			if not is_instance_valid(player) or not is_instance_valid(target):
				break
			# Do not enter from a scanner state that still claims the target at
			# the known-outside point.  Another direction/retry gives Area3D a
			# bounded chance to publish the exit before we approach again.
			if player.get("_active_interactable") == target:
				continue
			for step in 31:
				var distance := lerpf(3.8, 0.85, float(step) / 30.0)
				player.global_position = Vector3(
					target.global_position.x + direction.x * distance,
					home.y, target.global_position.z + direction.z * distance)
				await get_tree().physics_frame
				if not is_instance_valid(player) or not is_instance_valid(target):
					break
				if player.get("_active_interactable") != target:
					continue
				await get_tree().physics_frame
				if is_instance_valid(player) and is_instance_valid(target) \
						and player.get("_active_interactable") == target:
					acquired = true
					acquired_once = true
					break
			if acquired:
				break
		if not acquired or not is_instance_valid(player) or not is_instance_valid(target):
			continue
		if not player.has_method("arm_expected_interact") \
				or not bool(player.call("arm_expected_interact", target)):
			break
		await _press_c2_world_interact()
		last_receipt = player.call("last_interact_receipt") \
			if is_instance_valid(player) and player.has_method("last_interact_receipt") else {}
		if String(last_receipt.get("status", "")) == "actual":
			# Never retry an actual interaction: doing so could duplicate a
			# one-shot target's mutation.  Exact identity is success; any other
			# actual target is a hard ownership failure.
			if is_instance_valid(player):
				player.global_position = home
			await get_tree().process_frame
			if last_receipt.get("actual") == target:
				return true
			_web_smoke_d5_fail("The Queen-route scanner interacted with a different authored target.")
			return false
		# No action/refusal is safe to retry because PlayerController did not
		# invoke any Interactable.  Clear a possibly still-armed expectation
		# before the next bounded acquisition.
		if is_instance_valid(player) and player.has_method("clear_expected_interact"):
			player.call("clear_expected_interact")
	if is_instance_valid(player):
		if player.has_method("clear_expected_interact"):
			player.call("clear_expected_interact")
		player.global_position = home
	await get_tree().process_frame
	if not acquired_once:
		_web_smoke_d5_fail("The player scanner did not acquire the authored Queen-route target.")
	else:
		_web_smoke_d5_fail("The authored Queen-route scanner interaction was refused (%s)." \
			% String(last_receipt.get("status", "no_action")))
	return false


func _wait_d5_town_control() -> void:
	var deadline := Time.get_ticks_msec() + 20000
	var stable_since := -1
	var d7_stability = D7ControlStability.new()
	while Time.get_ticks_msec() < deadline:
		var dialogs: Array = []
		dialogs.append_array(get_tree().get_nodes_in_group("run_debrief"))
		dialogs.append_array(get_tree().get_nodes_in_group("FirstKnotHomecomingDebrief"))
		dialogs.append_array(get_tree().get_nodes_in_group("GoldenWallowSettlementDebrief"))
		if not dialogs.is_empty():
			stable_since = -1
			d7_stability.observe(_d7_control_owner_key(), false)
			for dialog in dialogs:
				if dialog != null and is_instance_valid(dialog) and dialog.has_method("_finish"):
					dialog.call("_finish")
				else:
					_web_smoke_d5_fail("A Queen route debrief had no production close action.")
					return
			await get_tree().process_frame
			continue
		if not get_tree().paused and modal_count == 0:
			if _d7_control_observation_enabled():
				if d7_stability.observe(_d7_control_owner_key(), true):
					_d7_record_control_stability("d5_town", d7_stability)
					return
			else:
				if stable_since < 0:
					stable_since = Time.get_ticks_msec()
				if Time.get_ticks_msec() - stable_since >= 650:
					return
		else:
			stable_since = -1
			d7_stability.observe(_d7_control_owner_key(), false)
		if _d7_control_observation_enabled():
			await _d7_wait_control_observation()
		else:
			await get_tree().create_timer(0.1, true).timeout
	_web_smoke_d5_fail("Town never returned stable control for Queen's Summit.")


func _web_smoke_d5_fail(reason: String) -> void:
	_web_smoke_d5_stage = "failed"
	web_smoke_report("failed", reason)


# D6 is the authored Pale Oath release route. Its fixture stops precisely at
# canonical Queen completion; every Pale clue, folio, Chart, escrow, relief,
# reward, restoration, and lesson below is obtained through a live adapter.
func _web_smoke_d6_scene_ready(scene_name: String, owner_token: Dictionary = {}) -> void:
	if scene_name == "Town":
		if _web_smoke_d6_stage == "":
			_web_smoke_d6_stage = "fixture"
			web_smoke_report("town")
			_setup_d6_canonical_queen_fixture.call_deferred()
			return
		if _web_smoke_d6_stage.begins_with("veins_"):
			web_smoke_report("pale_veins_return_%d" % _web_smoke_d6_veins_ids.size())
			get_tree().create_timer(0.35).timeout.connect(_continue_d6_web_smoke)
			return
		if _web_smoke_d6_stage == "jarl_return":
			_verify_d6_pale_oath_settlement.call_deferred()
			return
	elif scene_name == "World":
		if _web_smoke_d6_stage.begins_with("veins_"):
			var clue: Dictionary = run_cfg().get("campaign_clue", {})
			var index := _web_smoke_d6_veins_ids.size() - 1
			var expected := String(CampaignData.PALE_OATH_CLUES[index]) \
				if index >= 0 and index < CampaignData.PALE_OATH_CLUES.size() else ""
			if String(clue.get("clue_id", "")) != expected \
					or String(clue.get("presentation", "")) != "oath_rubbing" \
					or String(run_cfg().get("boss_kind", "")) != "":
				_web_smoke_d6_fail("A Pale Veins World did not carry its boss-free authored Oath-Rubbing.")
				return
			_web_smoke_d6_clue_ids.append(expected)
			web_smoke_report("pale_veins_world_%d" % _web_smoke_d6_veins_ids.size())
			if web_smoke_d7_enabled and _web_smoke_d7_stage == "prior_pale_oath":
				_d7_harvest_world_then_return.bind(owner_token).call_deferred()
				return
			if web_smoke_d7_enabled:
				_d7_schedule_far_waystone_return(1.0, "d6_veins")
			else:
				get_tree().create_timer(1.0).timeout.connect(func() -> void: return_to_town(local_player(), false))
		elif _web_smoke_d6_stage == "jarl_world":
			get_tree().create_timer(0.7).timeout.connect(_drive_d6_jarl_world)
		else:
			_web_smoke_d6_fail("A World opened outside the Pale Oath release route.")


func _setup_d6_canonical_queen_fixture() -> void:
	# This is prior-chapter truth only. In particular, no Pale Oath ledger,
	# source read, Chart, escrow, relief, reward, Thread, Rune, or restoration
	# is seeded here.
	campaign_state = CampaignData.empty_state()
	for chapter_id in [CampaignData.FIRST_KNOT, CampaignData.GOLDEN_WALLOW,
		CampaignData.SEVENTH_ROAD, CampaignData.QUEENS_SUMMIT]:
		var chapter: Dictionary = campaign_state.chapters[chapter_id]
		chapter.cleared = true
		chapter.clue_count = int(CampaignData.CHAPTERS[chapter_id].clue_target)
	campaign_state.relics = ["green_root_rune", "mist_root_rune", "fang_root_rune",
		"crown_root_rune"]
	campaign_state.restorations = ["trophy_hall", "sallow_jetty", "skald_archive",
		"pale_stair"]
	trades.wayfinding = {"xp": Progression.xp_for_level(19), "lv": 19}
	trades.wildcraft = {"xp": Progression.xp_for_level(14), "lv": 14}
	trades.huntcraft = {"xp": Progression.xp_for_level(18), "lv": 18}
	chart_source_unlocks = ChartsData.normalize_chart_source_unlocks([])
	known_chart_recipes = ChartsData.starting_recipe_ids()
	chart_recipe_journal = ChartsData.fresh_recipe_journal()
	seen_hints["chart_table_snug_returned"] = true
	discovered_inks = ["hedge_ink", "mire_ink", "mothglow_ink", "refined_ink",
		"stoneground_ink"]
	charts = []
	gold = 1800
	_apply_campaign_material_targets({"oath_nail": 1, "cold_track": 1})
	_sync_campaign_chart_sources()
	var pale: Dictionary = campaign_state.chapters[CampaignData.PALE_OATH]
	if not CampaignData.chapter_cleared(campaign_state, CampaignData.QUEENS_SUMMIT) \
			or not (campaign_state.relics as Array).has("crown_root_rune") \
			or not (campaign_state.restorations as Array).has("pale_stair") \
			or int(pale.get("clue_count", -1)) != 0 \
			or material_count("oath_nail") != 1 \
			or (campaign_state.escrows as Dictionary).size() != 0 \
			or (campaign_state.threads as Array).has("past_thread") \
			or (campaign_state.relics as Array).has("pale_root_rune") \
			or (campaign_state.restorations as Array).has("rootroad_lift"):
		_web_smoke_d6_fail("The D6 fixture contained more than canonical Queen-complete truth.")
		return
	web_smoke_features["d6_canonical_queen_fixture"] = true
	var town := get_tree().current_scene
	if town != null and town.has_method("_refresh_campaign_settlement_view"):
		town.call("_refresh_campaign_settlement_view")
	await _wait_d6_town_control()
	if web_smoke_phase == "failed":
		return
	web_smoke_report("queen_complete_fixture")
	if not await _d6_read_pale_stair(town):
		return
	web_smoke_features["d6_real_pale_stair_read"] = true
	web_smoke_report("pale_stair")
	var archive := town.get_node_or_null("SkaldArchive") if town != null else null
	if archive == null or not bool(archive.visible) or not await _d6_read_archive_source(archive as Node3D,
			"skald_pale_oath"):
		return
	web_smoke_features["d6_real_archive_source"] = true
	web_smoke_report("archive_source")
	# Ordinary Table stock only. The Archive furnished the first physical Pale
	# kit; this bounded QA stock pays the ordinary five-pot Hedge Ink measure for
	# four roads plus the boss Chart without manufacturing a clue or Story Seal.
	_apply_campaign_material_targets({"pale_wellmark": 4, "atlas_folio": 4,
		"climbing_cord": 8, "stoneground_ink": 4, "hedge_ink": 25,
		"cold_track": 1})
	_web_smoke_d6_stage = "veins_1"
	await _inscribe_d6_pale_veins()


func _d6_read_pale_stair(town: Node) -> bool:
	# The production Stair belongs to an authored Queen arena. D6 starts after
	# that arena has already settled, so it mounts the same production script and
	# explicit settlement token as a physical, scanner-driven breadcrumb rather
	# than inventing a run/Chart solely to revisit an already-cleared Queen.
	if town == null:
		_web_smoke_d6_fail("The canonical Queen fixture had no Town for its Pale Stair breadcrumb.")
		return false
	var stair_script = load("res://scripts/pale_stair.gd")
	var stair: Node3D = stair_script.new() if stair_script != null else null
	if stair == null:
		_web_smoke_d6_fail("The production Pale Stair script could not be mounted.")
		return false
	stair.name = "D6PaleStairBreadcrumb"
	stair.position = Vector3(20.0, 0.0, 20.0)
	stair.call("set_campaign_settlement_view", {"canonical_queen": true, "pale_stair": true})
	town.add_child(stair)
	await get_tree().process_frame
	if not await _d6_scanner_interact(stair):
		stair.queue_free()
		return false
	var dialog := get_tree().get_first_node_in_group("PaleStairDialog")
	if dialog == null or not dialog.has_method("_finish"):
		stair.queue_free()
		_web_smoke_d6_fail("The physical Pale Stair did not open its production dialog.")
		return false
	dialog.call("_finish")
	await get_tree().process_frame
	var read: Dictionary = stair.call("read_now")
	stair.queue_free()
	if not bool(read.get("ok", false)) or bool(read.get("changed", true)) \
			or not bool(read.get("repeatable", false)) \
			or String(read.get("route", "")) != "pale_oath_not_yet_walkable":
		_web_smoke_d6_fail("The physical Pale Stair was not the copy-only production breadcrumb.")
		return false
	return true


func _d6_read_archive_source(archive: Node3D, source_id: String) -> bool:
	if archive == null or not await _d6_scanner_interact(archive):
		return false
	var dialog := get_tree().get_first_node_in_group("SkaldArchiveDialog")
	if dialog == null or not dialog.has_method("_finish"):
		_web_smoke_d6_fail("The Skald Archive did not open its production review dialog.")
		return false
	dialog.call("_finish")
	await get_tree().process_frame
	await get_tree().process_frame
	var status := chart_source_status(source_id)
	if String(status.get("state", "")) != "read":
		_web_smoke_d6_fail("The Skald Archive did not commit its %s source transaction." % source_id)
		return false
	return true


func _continue_d6_web_smoke() -> void:
	if not web_smoke_d6_enabled or web_smoke_phase == "failed":
		return
	await _wait_d6_town_control()
	if web_smoke_phase == "failed":
		return
	if _web_smoke_d6_veins_ids.size() < 4:
		_web_smoke_d6_stage = "veins_%d" % (_web_smoke_d6_veins_ids.size() + 1)
		await _inscribe_d6_pale_veins()
		return
	if _web_smoke_d6_clue_ids != CampaignData.PALE_OATH_CLUES \
			or CampaignData.chapter_clue_count(campaign_state, CampaignData.PALE_OATH) != 4:
		_web_smoke_d6_fail("Four physical Pale Veins returns did not bank the Oath-Rubbing ledger.")
		return
	web_smoke_features["d6_four_pale_veins_loops"] = true
	web_smoke_features["d6_four_distinct_oath_rubbings"] = true
	if web_smoke_d7_enabled and _web_smoke_d7_stage == "prior_pale_oath":
		await _d7_prepare_pale_boss_from_earned_state()
		return
	var archive := get_tree().current_scene.get_node_or_null("SkaldArchive")
	if archive == null or not await _d6_read_archive_source(archive as Node3D,
			"skald_pale_oath_boss"):
		return
	web_smoke_report("pale_oath_boss_folio")
	await _inscribe_d6_pale_oath_chart()


func _inscribe_d6_pale_veins() -> void:
	var chart := await _d6_table_inscribe("pale_veins", ["pale_wellmark", "atlas_folio",
		"climbing_cord", "climbing_cord", "stoneground_ink"],
		"pale_veins_table_%d" % (_web_smoke_d6_veins_ids.size() + 1))
	if chart.is_empty():
		return
	var chart_id := String(chart.get("chart_instance_id", ""))
	if chart_id == "" or _web_smoke_d6_veins_ids.has(chart_id):
		_web_smoke_d6_fail("Pale Veins did not mint a distinct physical Chart.")
		return
	_web_smoke_d6_veins_ids.append(chart_id)
	if web_smoke_d7_enabled:
		_d7_socket_chart_at_town.bind(chart).call_deferred()
	else:
		enter_dungeon(chart, local_player())


func _inscribe_d6_pale_oath_chart() -> void:
	var chart := await _d6_table_inscribe("pale_oath_boss", ["barrow_mark", "pale_wellmark",
		"cold_track", "atlas_folio", "climbing_cord", "climbing_cord", "stoneground_ink",
		"oath_nail"], "pale_oath_preview")
	if chart.is_empty():
		return
	var attempt_id := String(chart.get("attempt_id", ""))
	var escrow: Dictionary = (campaign_state.escrows as Dictionary).get(attempt_id, {})
	if attempt_id == "" or String(escrow.get("phase", "")) != "case" \
			or (escrow.get("items", {}) as Dictionary) != {"oath_nail": 1}:
		_web_smoke_d6_fail("The Pale Oath Table commit did not open its exact Oath Nail escrow.")
		return
	_web_smoke_d6_boss_chart = chart.duplicate(true)
	web_smoke_features["d6_boss_table_escrow"] = true
	_web_smoke_d6_stage = "jarl_world"
	if web_smoke_d7_enabled:
		_d7_socket_chart_at_town.bind(chart).call_deferred()
	else:
		enter_dungeon(chart, local_player())


func _d6_table_inscribe(recipe_id: String, supplies_to_press: Array, phase: String) -> Dictionary:
	var bench: Node = await _open_d6_chart_table()
	if bench == null:
		return {}
	var panel := bench.get_node_or_null("ChartTablePanel")
	var view := panel.get_node_or_null("ChartTableView") if panel != null else null
	var supplies := view.find_child("SuppliesTab", true, false) as Button if view != null else null
	if supplies == null:
		bench.close()
		_web_smoke_d6_fail("The physical Table had no Supplies tab for %s." % recipe_id)
		return {}
	supplies.pressed.emit()
	await get_tree().process_frame
	var wanted := {}
	for item_v in supplies_to_press:
		var item_id := String(item_v)
		wanted[item_id] = int(wanted.get(item_id, 0)) + 1
		var before := material_count(item_id)
		if not await _press_d6_supply_control(bench, item_id):
			bench.close()
			_web_smoke_d6_fail("The physical Table rejected its visible %s supply." % item_id)
			return {}
		var draft: Dictionary = bench.get("draft")
		var staged := (draft.get("grid", {}) as Dictionary).values().count(item_id) \
			+ (draft.get("ink_rail", []) as Array).count(item_id)
		if staged < int(wanted[item_id]) and material_count(item_id) > before:
			if not await _press_d6_supply_control(bench, item_id):
				bench.close()
				_web_smoke_d6_fail("The renewed %s supply would not stage at the physical Table." % item_id)
				return {}
	var preview: Dictionary = bench.call("current_preview")
	var action := view.find_child("InscribeChartButton", true, false) as Button
	var grid: Dictionary = bench.get("draft").get("grid", {})
	var rail: Array = bench.get("draft").get("ink_rail", [])
	var expected_grid := {"n": "pale_wellmark", "c": "atlas_folio",
		"w": "climbing_cord", "e": "climbing_cord"} if recipe_id == "pale_veins" \
		else {"nw": "barrow_mark", "n": "pale_wellmark", "ne": "cold_track",
			"c": "atlas_folio", "w": "climbing_cord", "e": "climbing_cord", "s": "oath_nail"}
	if String(preview.get("recipe_id", "")) != recipe_id \
			or not bool(preview.get("commit_ready", false)) or action == null or action.disabled \
			or grid != expected_grid or rail != ["stoneground_ink"]:
		var supply_counts := {}
		for item_v in supplies_to_press:
			var item_id := String(item_v)
			supply_counts[item_id] = material_count(item_id)
		bench.close()
		_web_smoke_d6_fail(("The physical Table did not resolve the exact %s grammar " \
			+ "(preview=%s, ready=%s, action=%s, grid=%s, rail=%s, reason=%s, gold=%d, supplies=%s).") % [
				recipe_id, String(preview.get("recipe_id", "")),
				str(preview.get("commit_ready", false)),
				str(action != null and not action.disabled), str(grid), str(rail),
				String(preview.get("reason", "")), gold, str(supply_counts)])
		return {}
	if recipe_id == "pale_veins":
		if not (preview.get("campaign_contract", {}) as Dictionary).is_empty() \
				or String((preview.get("output", {}) as Dictionary).get("name", "")) != "Pale Veins":
			bench.close()
			_web_smoke_d6_fail("Pale Veins was not a boss-free authored preview.")
			return {}
	else:
		var contract: Dictionary = preview.get("campaign_contract", {})
		var guarantees: Array = preview.get("guaranteed", [])
		if contract != CampaignData.boss_contract("pale_oath_boss") \
				or String((preview.get("output", {}) as Dictionary).get("name", "")) != "The Pale Oath" \
				or preview.get("returned_on_failure", {}) != {"oath_nail": 1} \
				or guarantees.is_empty() or String((guarantees[0] as Dictionary).get("id", "")) != "barrow_jarl":
			bench.close()
			_web_smoke_d6_fail("The Pale Oath preview did not visibly bind the Jarl and Oath Nail contract.")
			return {}
		web_smoke_features["d6_boss_preview_contract"] = true
	web_smoke_features["d6_real_table_commits"] = true
	web_smoke_report(phase)
	var before_costs := {}
	for material_v in (preview.get("costs", {}) as Dictionary):
		before_costs[String(material_v)] = material_count(String(material_v))
	var charts_before := charts.size()
	action.pressed.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	var chart: Dictionary = charts.back() if charts.size() == charts_before + 1 else {}
	bench.close()
	if chart.is_empty() or String(chart.get("recipe_id", "")) != recipe_id:
		_web_smoke_d6_fail("The real Inscribe Chart Control did not commit %s." % recipe_id)
		return {}
	for material_v in (preview.get("costs", {}) as Dictionary):
		var material_id := String(material_v)
		if material_count(material_id) != int(before_costs[material_id]) \
				- int((preview.get("costs", {}) as Dictionary)[material_v]):
			_web_smoke_d6_fail("%s did not charge its exact %s cost." % [recipe_id, material_id])
			return {}
	return chart


func _drive_d6_jarl_world() -> void:
	var boss := _d4_find_boss("barrow_jarl")
	var attempt_id := String(_web_smoke_d6_boss_chart.get("attempt_id", ""))
	var escrow: Dictionary = (campaign_state.escrows as Dictionary).get(attempt_id, {})
	if boss == null or String(run_cfg().get("boss_kind", "")) != "barrow_jarl" \
			or String(escrow.get("phase", "")) != "in_run":
		_web_smoke_d6_fail("The Pale Oath World did not bind its live Barrow Jarl escrow.")
		return
	var controller := get_tree().current_scene.find_child("BarrowJarlReliefController", true, false)
	if controller == null or not controller.has_method("request_bell_relief"):
		_web_smoke_d6_fail("The Barrow Jarl World had no host relief controller.")
		return
	web_smoke_features["d6_world_barrow_jarl"] = true
	web_smoke_report("pale_oath_world")
	for phase in 3:
		boss.call("take_damage", int(boss.get("hp")) + 1, Vector3.FORWARD)
		await get_tree().process_frame
		var guards: Array = controller.get("guards")
		var bells: Array = controller.get("bells")
		var guard = guards[phase] if phase < guards.size() else null
		var bell = bells[phase] if phase < bells.size() else null
		if guard == null or bell == null or not guard.has_method("take_damage"):
			_web_smoke_d6_fail("The Barrow Jarl relief %d had no authored guard and bell." % (phase + 1))
			return
		guard.call("take_damage", int(guard.get("hp")) + 1, Vector3.FORWARD)
		await get_tree().process_frame
		if not bool(guard.get("reeling")) or not await _d6_scanner_interact(bell as Node3D):
			return
		if not bool((controller.get("completed") as Array)[phase]) \
				or bool(boss.get("vow_shielded")):
			var bell_detail: Dictionary = _web_smoke_d6_last_bell_action_detail
			var action_distance := float(bell_detail.get("action_distance", -1.0))
			_web_smoke_d6_fail(("The host controller did not validate Barrow Jarl relief %d " \
				+ "(phase=%s, completed=%s, shield=%s, reeling=%s, action_distance=%.2f, detail=%s).") % [
					phase + 1, str(boss.get("relief_phase")), str(controller.get("completed")),
					str(boss.get("vow_shielded")), str(guard.get("reeling")),
					action_distance, str(bell_detail)])
			return
		web_smoke_report("jarl_relief_%d" % (phase + 1))
	web_smoke_features["d6_three_host_validated_bell_reliefs"] = true
	var canonical_death_seen := [false]
	boss.connect("died", func() -> void: canonical_death_seen[0] = true, CONNECT_ONE_SHOT)
	boss.call("take_damage", int(boss.get("hp")) + 1, Vector3.FORWARD)
	# The Jarl's authored kneel is a tween-driven, canonical death transition.
	# D7 runs at an accelerated time scale, so a second scaled timer can race the
	# final tween/callback in Web builds. Wait on the production settlement
	# instead, bounded by real wall time so a broken encounter still fails fast.
	var settlement_deadline_ms := Time.get_ticks_msec() + 5000
	while Time.get_ticks_msec() < settlement_deadline_ms:
		escrow = (campaign_state.escrows as Dictionary).get(attempt_id, {})
		if bool(canonical_death_seen[0]) and String(escrow.get("phase", "")) == "consumed":
			break
		await get_tree().process_frame
	escrow = (campaign_state.escrows as Dictionary).get(attempt_id, {})
	if String(escrow.get("phase", "")) != "consumed" \
			or not CampaignData.chapter_cleared(campaign_state, CampaignData.PALE_OATH) \
			or material_count("oath_nail") != 0 or material_count("starheart_coal") != 1 \
			or not (campaign_state.relics as Array).has("pale_root_rune") \
			or not (campaign_state.threads as Array).has("past_thread") \
			or not (campaign_state.restorations as Array).has("rootroad_lift"):
		_web_smoke_d6_fail(("Canonical Barrow Jarl death did not exact-settle the Pale Oath once " \
			+ "(death_seen=%s, boss_valid=%s, boss_dead=%s, escrow=%s, completed=%s, " \
			+ "nail=%d, coal=%d, relics=%s, threads=%s, restorations=%s).") % [
			str(canonical_death_seen[0]), str(is_instance_valid(boss)),
			str(bool(boss.get("dead")) if is_instance_valid(boss) else true), str(escrow),
			str(controller.get("completed") if is_instance_valid(controller) else []),
			material_count("oath_nail"), material_count("starheart_coal"),
			str(campaign_state.relics), str(campaign_state.threads),
			str(campaign_state.restorations)])
		return
	web_smoke_features["d6_exact_pale_oath_settlement"] = true
	web_smoke_report("jarl_cleared")
	_web_smoke_d6_stage = "jarl_return"
	if web_smoke_d7_enabled:
		_d7_schedule_far_waystone_return(0.35, "d6_jarl")
	else:
		get_tree().create_timer(0.35).timeout.connect(func() -> void: return_to_town(local_player(), false))


func _verify_d6_pale_oath_settlement() -> void:
	await _wait_d6_town_control()
	if web_smoke_phase == "failed":
		return
	var scene := get_tree().current_scene
	var lift := scene.get_node_or_null("RootroadLift") if scene != null else null
	if lift == null or not lift.has_method("presentation_ids") \
			or lift.call("presentation_ids") != {"restoration_id": "rootroad_lift",
				"lift_id": "rootroad_lift", "oathstone_id": "hod_oathstone"} \
			or lift.get_node_or_null("RootroadLiftWellhouse") == null:
		_web_smoke_d6_fail("Town did not project the functional Rootroad Lift.")
		return
	if not await _d6_scanner_interact(lift as Node3D):
		return
	var lift_dialog := get_tree().get_first_node_in_group("RootroadLiftDialog")
	if lift_dialog == null or not lift_dialog.has_method("_finish"):
		_web_smoke_d6_fail("The physical Rootroad Lift did not open its production dialog.")
		return
	lift_dialog.call("_finish")
	await get_tree().process_frame
	web_smoke_report("rootroad_lift")
	if lift.get_node_or_null("HodOathstone") == null:
		_web_smoke_d6_fail("The Rootroad Lift projection did not include Hod's oath-stone.")
		return
	web_smoke_features["d6_rootroad_lift_oathstone"] = true
	web_smoke_report("oathstone")
	var hall := scene.get_node_or_null("FirstKnotTrophyHall") if scene != null else null
	var atlas := scene.get_node_or_null("AtlasDeepRumourSource") if scene != null else null
	var archive := scene.get_node_or_null("SkaldArchive") if scene != null else null
	if hall == null or hall.get_node_or_null("PaleOathRecord") == null \
			or hall.get_node_or_null("StarheartCoalRecord") == null \
			or hall.get_node_or_null("PaleRootRune") == null \
			or hall.get_node_or_null("PastThreadRecord") == null:
		_web_smoke_d6_fail("The Trophy Hall did not project the exact Pale Oath settlement.")
		return
	web_smoke_report("pale_oath_hall")
	if atlas == null or not atlas.has_method("pale_oath_settlement_visible") \
			or not bool(atlas.call("pale_oath_settlement_visible")) \
			or atlas.get_node_or_null("PaleOathAtlasMark") == null:
		_web_smoke_d6_fail("The Living Atlas did not project the Pale Oath settlement.")
		return
	web_smoke_report("pale_oath_atlas")
	if archive == null or not archive.has_method("pale_oath_presentation_ids") \
			or archive.call("pale_oath_presentation_ids") != {"folio_id": "skald_pale_oath",
				"boss_folio_id": "skald_pale_oath_boss", "relic_id": "pale_root_rune",
				"thread_record_id": "past_thread", "material_record_id": "starheart_coal"}:
		_web_smoke_d6_fail("The Skald Archive did not project the settled Pale Oath record.")
		return
	web_smoke_features["d6_town_settlement_projections"] = true
	web_smoke_report("pale_oath_archive")
	if not await _d6_drive_driving_volley(scene):
		return
	web_smoke_features["d6_gameplay_driver"] = true
	if web_smoke_d7_enabled and _web_smoke_d7_stage == "prior_pale_oath":
		web_smoke_d6_enabled = false
		_web_smoke_d7_stage = "fire_lift"
		web_smoke_report("prior_saga_complete")
		_d7_record_progressive_level_ledger("pale_oath_settlement")
		await _d7_begin_fire_from_earned_state()
		return
	web_smoke_report("complete")


func _d7_begin_fire_from_earned_state() -> void:
	if not CampaignData.chapter_cleared(campaign_state, CampaignData.PALE_OATH):
		_web_smoke_d7_fail("The Fire road lost the production Pale Oath settlement.")
		return
	var targets := _d7_progressive_training_targets("fire_in_the_bough")
	var authored_ledger := d7_fire_entry_wayfinding_ledger()
	var authored_total := int(authored_ledger.get("total", -1))
	if authored_total != D7_FIRE_ENTRY_WAYFINDING_XP:
		_web_smoke_d7_fail("D7 Fire-entry authored ledger drifted from %d to %d: %s" % [
			D7_FIRE_ENTRY_WAYFINDING_XP, authored_total,
			authored_ledger.get("entries", [])])
		return
	if not _d7_require_exact_wayfinding_xp(
			"fire_entry", authored_total):
		return
	await _wait_d7_town_control()
	if web_smoke_phase == "failed":
		return
	if not await _d7_prepare_support_trades(targets, "fire_in_the_bough"):
		return
	if not _d7_training_complete(targets):
		_d7_begin_trade_training("fire_in_the_bough", targets)
		return
	var fire_lift := get_tree().current_scene.get_node_or_null("RootroadLift") as Node3D
	if fire_lift == null or not await _d7_read_lift_folio(
			fire_lift, "rootroad_lift_ashen_bough", true):
		return
	web_smoke_features["d7_real_lift_ordinary_folio"] = true
	web_smoke_report("lift_ordinary_folio")
	var hedge_runway := _d7_hedge_runway("ashen_bough", 5,
		"fire_in_the_bough_boss")
	if not await _d7_training_make_hedge_ink(hedge_runway) \
			or not await _d7_mix_ink_to_count("ash_ink", 6):
		return
	web_smoke_features["d7_fire_renewable_ink"] = true
	_web_smoke_d7_stage = "ashen_1"
	await _inscribe_d7_ashen_bough()


func _d6_drive_driving_volley(scene: Node) -> bool:
	var lodge := scene.get_node_or_null("HuntersLodgeLesson") if scene != null else null
	if lodge == null or not await _d6_scanner_interact(lodge as Node3D):
		return false
	var dialog := get_tree().get_first_node_in_group("HuntersLodgeLessonDialog")
	if dialog == null or not dialog.has_method("_finish"):
		_web_smoke_d6_fail("The Hunter's Lodge did not open its production Driving Volley lesson.")
		return false
	dialog.call("_finish")
	await get_tree().process_frame
	var player := local_player() as Node3D
	if player == null or not skill_owned("DrivingVolley") or not loadout.has("DrivingVolley") \
			or not player.has_method("_try_skill"):
		_web_smoke_d6_fail("The physical Lodge lesson did not equip Driving Volley.")
		return false
	web_smoke_features["d6_driving_volley_equipped"] = true
	var bramble_script = load("res://scripts/practice_bramble.gd")
	var target: Node3D = bramble_script.new() if bramble_script != null else null
	if target == null:
		_web_smoke_d6_fail("No harmless production target was available for Driving Volley.")
		return false
	target.name = "D6DrivingVolleyTarget"
	var direction := Vector3.FORWARD
	player.set("net_aim", direction)
	scene.add_child(target)
	target.global_position = player.global_position + direction * 4.0
	await get_tree().physics_frame
	await get_tree().physics_frame
	var slot := -1
	var skills: Array = player.get("skills")
	for index in skills.size():
		if String(skills[index].get("name")) == "DrivingVolley":
			slot = index + 1
			break
	if slot < 2:
		target.queue_free()
		_web_smoke_d6_fail("Driving Volley was equipped but absent from the live hotbar.")
		return false
	player.call("_try_skill", slot)
	for _frame in 18:
		await get_tree().physics_frame
	player.set("net_aim", Vector3.ZERO)
	var displaced := (target.get("_knockback") as Vector3).length() > 0.001
	target.queue_free()
	if not displaced:
		_web_smoke_d6_fail("Driving Volley did not land its real collision-safe displacement on a harmless target.")
		return false
	web_smoke_features["d6_driving_volley_real_displacement"] = true
	web_smoke_report("driving_volley")
	return true


func _open_d6_chart_table():
	var scene := get_tree().current_scene
	var player := local_player() as Node3D
	var tables := get_tree().get_nodes_in_group("inscribing_table")
	if scene == null or player == null or tables.size() != 1:
		_web_smoke_d6_fail("The authored Town Inscribing Table was missing.")
		return null
	var table := tables[0] as Node3D
	var home := player.global_position
	player.global_position = Vector3(table.global_position.x + 1.05, home.y, table.global_position.z)
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	if player.get("_active_interactable") != table:
		player.global_position = home
		_web_smoke_d6_fail("The player scanner did not acquire the Inscribing Table.")
		return null
	await _press_c2_world_interact()
	player.global_position = home
	await get_tree().process_frame
	for child in scene.get_children():
		if child.has_node("ChartTablePanel"):
			return child
	_web_smoke_d6_fail("The real Town Chart Table did not open through interact.")
	return null


func _press_d6_supply_control(bench: Node, material_id: String) -> bool:
	var panel := bench.get_node_or_null("ChartTablePanel")
	var view := panel.get_node_or_null("ChartTableView") if panel != null else null
	var supply := view.find_child("Supply_%s" % material_id, true, false) as Button \
		if view != null else null
	if supply == null or supply.disabled:
		return false
	supply.pressed.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	return true


func _d6_player_controllable(player: Node3D) -> bool:
	return player != null and is_instance_valid(player) \
		and not bool(player.get("dead")) and modal_count == 0 \
		and float(player.get("_stun_t")) <= 0.0


func _d6_scanner_interact(target: Node3D) -> bool:
	var player := local_player() as Node3D
	_web_smoke_d6_last_bell_action_detail = {}
	_web_smoke_d7_last_chain_action_detail = {}
	if player == null or target == null:
		_web_smoke_d6_fail("The Pale Oath route had no live scanner target.")
		return false
	var home := player.global_position
	var acquired := false
	for direction in [Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD, Vector3.BACK]:
		for step in 31:
			var distance := lerpf(3.8, 0.85, float(step) / 30.0)
			player.global_position = Vector3(target.global_position.x + direction.x * distance,
				home.y, target.global_position.z + direction.z * distance)
			await get_tree().physics_frame
			if player.get("_active_interactable") == target:
				acquired = true
				break
		if acquired:
			break
	if not acquired:
		player.global_position = home
		_web_smoke_d6_fail("The player scanner did not acquire the authored Pale Oath target.")
		return false
	# Bell requests are host-validated at a stricter 2.25m boundary than the
	# scanner's generous prompt radius. The old helper returned success after any
	# released interaction, even if a late scanner retarget rang a different bell
	# and the host rejected it. Keep the shipped InputMap path, but bind the final
	# edge to the exact bell and require the controller's resulting state.
	if target.is_in_group("pale_oath_bell"):
		var bell_controller: Node = target.get("controller") as Node
		var bell_phase := int(target.get("phase_index"))
		var bell_id := String(target.get("bell_id"))
		var controller_events := {"commit_phase": 0, "commit_bell_id": "", "rejection": ""}
		var on_commit := func(phase_index: int, committed_bell_id: String) -> void:
			controller_events.commit_phase = phase_index
			controller_events.commit_bell_id = committed_bell_id
		var on_rejected := func(reason: String) -> void:
			controller_events.rejection = reason
		if bell_controller != null and bell_controller.has_signal("relief_committed"):
			bell_controller.connect("relief_committed", on_commit)
		if bell_controller != null and bell_controller.has_signal("bell_request_rejected"):
			bell_controller.connect("bell_request_rejected", on_rejected)
		var action_detail := {}
		for attempt in 3:
			# A hit can land between the broad scanner acquisition and InputMap's
			# next physics edge. Wait only through that transient lock; death/modal
			# states are terminal for this action and never receive a blind press.
			var control_wait := 0
			while not _d6_player_controllable(player) and control_wait < 12:
				if player is CharacterBody3D:
					(player as CharacterBody3D).velocity = Vector3.ZERO
				await get_tree().physics_frame
				control_wait += 1
			if not _d6_player_controllable(player):
				action_detail = {"attempt": attempt + 1, "reason": "not_controllable",
					"dead": bool(player.get("dead")), "modal_count": modal_count,
					"stun": float(player.get("_stun_t")), "wait_frames": control_wait}
				break
			var toward_player := player.global_position - target.global_position
			toward_player.y = 0.0
			if toward_player.length_squared() <= 0.0001:
				toward_player = Vector3.RIGHT
			player.global_position = Vector3(target.global_position.x, home.y,
				target.global_position.z) + toward_player.normalized() * 1.75
			if player is CharacterBody3D:
				(player as CharacterBody3D).velocity = Vector3.ZERO
			await get_tree().physics_frame
			await get_tree().process_frame
			if not _d6_player_controllable(player) or player.get("_active_interactable") != target:
				action_detail = {"attempt": attempt + 1, "reason": "lost_before_arm",
					"dead": bool(player.get("dead")), "modal_count": modal_count,
					"stun": float(player.get("_stun_t")),
					"active": player.get("_active_interactable") == target}
				if float(player.get("_stun_t")) > 0.0 and attempt < 2:
					continue
				break
			if not player.has_method("arm_expected_interact") \
					or not bool(player.call("arm_expected_interact", target)):
				action_detail = {"attempt": attempt + 1, "reason": "arm_failed"}
				break
			var action_position := player.global_position
			await _press_c2_world_interact()
			await get_tree().process_frame
			var receipt: Dictionary = player.call("last_interact_receipt") \
				if player.has_method("last_interact_receipt") else {}
			var completed: Array = bell_controller.get("completed") as Array \
				if bell_controller != null else []
			var controller_completed := bell_phase >= 1 and bell_phase <= completed.size() \
				and bool(completed[bell_phase - 1])
			var boss = bell_controller.get("jarl") if bell_controller != null else null
			var shield_released := boss != null and not bool(boss.get("vow_shielded"))
			var exact_receipt: bool = String(receipt.get("status", "")) == "actual" \
				and receipt.get("actual") == target
			var exact_commit: bool = int(controller_events.commit_phase) == bell_phase \
				and String(controller_events.commit_bell_id) == bell_id
			action_detail = {"attempt": attempt + 1, "reason": "receipt_or_host_rejected",
				"receipt_status": String(receipt.get("status", "")),
				"receipt_exact": exact_receipt, "controller_completed": controller_completed,
				"shield_released": shield_released,
				"commit_phase": int(controller_events.commit_phase),
				"commit_bell_id": String(controller_events.commit_bell_id),
				"rejection": String(controller_events.rejection),
				"action_distance": action_position.distance_to(target.global_position),
				"stun": float(player.get("_stun_t"))}
			_web_smoke_d6_last_bell_action_detail = action_detail.duplicate(true)
			if exact_receipt and controller_completed and shield_released and exact_commit:
				if bell_controller != null and bell_controller.is_connected("relief_committed", on_commit):
					bell_controller.disconnect("relief_committed", on_commit)
				if bell_controller != null and bell_controller.is_connected("bell_request_rejected", on_rejected):
					bell_controller.disconnect("bell_request_rejected", on_rejected)
				if is_instance_valid(player):
					player.global_position = home
				await get_tree().process_frame
				return true
			# Input ignored by a fresh stun is the only bounded retry. A mismatched
			# actual target is a hard ownership violation, never a retryable action.
			if not exact_receipt and float(player.get("_stun_t")) > 0.0 and attempt < 2:
				continue
			break
		if bell_controller != null and bell_controller.is_connected("relief_committed", on_commit):
			bell_controller.disconnect("relief_committed", on_commit)
		if bell_controller != null and bell_controller.is_connected("bell_request_rejected", on_rejected):
			bell_controller.disconnect("bell_request_rejected", on_rejected)
		_web_smoke_d6_last_bell_action_detail = action_detail.duplicate(true)
		if is_instance_valid(player):
			player.global_position = home
		await get_tree().process_frame
		_web_smoke_d6_fail(("The Oath Bell action was not accepted by its exact host controller " \
			+ "(phase=%s, detail=%s).") % [str(bell_phase), str(action_detail)])
		return false
	# Hearth chains share the bells' narrow host-authority seam. A prompt alone
	# is not proof that the InputMap edge reached the intended chain, especially
	# while the Giant can stun the player between scanner acquisition and input.
	# Require the exact interaction receipt and the controller's corresponding
	# bank/rejection signal. The deliberately wrong first chain is successful
	# only when its recoverable hazard is confirmed without mutating the mask.
	if target.is_in_group("hearth_chain"):
		var chain_controller: Node = target.get("encounter") as Node
		var chain_id := String(target.get("chain_id"))
		var chain_order: Array = chain_controller.get("CHAIN_ORDER") as Array \
			if chain_controller != null else []
		var chain_index := chain_order.find(chain_id)
		var mask_before := int(chain_controller.get("bank_mask")) \
			if chain_controller != null else -1
		var expected_id := String(chain_controller.call("_expected_chain_id")) \
			if chain_controller != null and chain_controller.has_method("_expected_chain_id") else ""
		var expect_hazard := chain_id != expected_id
		var controller_events := {"bank_phase": 0, "bank_chain_id": "",
			"rejection": "", "hazard_chain_id": "", "hazard_damage": 0}
		var on_bank := func(phase_index: int, banked_chain_id: String) -> void:
			controller_events.bank_phase = phase_index
			controller_events.bank_chain_id = banked_chain_id
		var on_rejected := func(reason: String) -> void:
			controller_events.rejection = reason
		var on_hazard := func(hazard_chain_id: String, damage: int) -> void:
			controller_events.hazard_chain_id = hazard_chain_id
			controller_events.hazard_damage = damage
		if chain_controller != null and chain_controller.has_signal("chain_banked"):
			chain_controller.connect("chain_banked", on_bank)
		if chain_controller != null and chain_controller.has_signal("chain_request_rejected"):
			chain_controller.connect("chain_request_rejected", on_rejected)
		if chain_controller != null and chain_controller.has_signal("recoverable_hazard"):
			chain_controller.connect("recoverable_hazard", on_hazard)
		var action_detail := {}
		for attempt in 3:
			var control_wait := 0
			while not _d6_player_controllable(player) and control_wait < 12:
				if player is CharacterBody3D:
					(player as CharacterBody3D).velocity = Vector3.ZERO
				await get_tree().physics_frame
				control_wait += 1
			if not _d6_player_controllable(player):
				action_detail = {"attempt": attempt + 1, "reason": "not_controllable",
					"dead": bool(player.get("dead")), "modal_count": modal_count,
					"stun": float(player.get("_stun_t")), "wait_frames": control_wait}
				break
			var toward_player := player.global_position - target.global_position
			toward_player.y = 0.0
			if toward_player.length_squared() <= 0.0001:
				toward_player = Vector3.RIGHT
			player.global_position = Vector3(target.global_position.x, home.y,
				target.global_position.z) + toward_player.normalized() * 1.75
			if player is CharacterBody3D:
				(player as CharacterBody3D).velocity = Vector3.ZERO
			await get_tree().physics_frame
			await get_tree().process_frame
			if not _d6_player_controllable(player) or player.get("_active_interactable") != target:
				action_detail = {"attempt": attempt + 1, "reason": "lost_before_arm",
					"dead": bool(player.get("dead")), "modal_count": modal_count,
					"stun": float(player.get("_stun_t")),
					"active": player.get("_active_interactable") == target}
				if float(player.get("_stun_t")) > 0.0 and attempt < 2:
					continue
				break
			if not player.has_method("arm_expected_interact") \
					or not bool(player.call("arm_expected_interact", target)):
				action_detail = {"attempt": attempt + 1, "reason": "arm_failed"}
				break
			var action_position := player.global_position
			await _press_c2_world_interact()
			await get_tree().process_frame
			var receipt: Dictionary = player.call("last_interact_receipt") \
				if player.has_method("last_interact_receipt") else {}
			var exact_receipt: bool = String(receipt.get("status", "")) == "actual" \
				and receipt.get("actual") == target
			var mask_after := int(chain_controller.get("bank_mask")) \
				if chain_controller != null else -1
			var expected_bit := 1 << chain_index if chain_index >= 0 else 0
			var host_accepted := not expect_hazard \
				and String(controller_events.bank_chain_id) == chain_id \
				and expected_bit != 0 and mask_after & expected_bit != 0
			var host_recoverable := expect_hazard \
				and String(controller_events.rejection) == "wrong_chain" \
				and String(controller_events.hazard_chain_id) == chain_id \
				and mask_after == mask_before
			action_detail = {"attempt": attempt + 1, "reason": "receipt_or_host_rejected",
				"chain_id": chain_id, "expected_id": expected_id,
				"receipt_status": String(receipt.get("status", "")),
				"receipt_exact": exact_receipt, "bank_phase": int(controller_events.bank_phase),
				"bank_chain_id": String(controller_events.bank_chain_id),
				"rejection": String(controller_events.rejection),
				"hazard_chain_id": String(controller_events.hazard_chain_id),
				"hazard_damage": int(controller_events.hazard_damage),
				"mask_before": mask_before, "mask_after": mask_after,
				"action_distance": action_position.distance_to(target.global_position),
				"stun": float(player.get("_stun_t"))}
			_web_smoke_d7_last_chain_action_detail = action_detail.duplicate(true)
			if exact_receipt and (host_accepted or host_recoverable):
				_disconnect_d7_chain_action_signals(chain_controller, on_bank, on_rejected, on_hazard)
				if is_instance_valid(player):
					player.global_position = home
				await get_tree().process_frame
				return true
			if not exact_receipt and float(player.get("_stun_t")) > 0.0 and attempt < 2:
				continue
			break
		_disconnect_d7_chain_action_signals(chain_controller, on_bank, on_rejected, on_hazard)
		_web_smoke_d7_last_chain_action_detail = action_detail.duplicate(true)
		if is_instance_valid(player):
			player.global_position = home
		await get_tree().process_frame
		_web_smoke_d7_fail("The Hearth chain action was not accepted by its exact host " \
			+ "controller (detail=%s)." % str(action_detail))
		return false
	await _press_c2_world_interact()
	if is_instance_valid(player):
		player.global_position = home
	await get_tree().process_frame
	return true


func _disconnect_d7_chain_action_signals(controller: Node, on_bank: Callable,
		on_rejected: Callable, on_hazard: Callable) -> void:
	if controller == null:
		return
	if controller.has_signal("chain_banked") and controller.is_connected("chain_banked", on_bank):
		controller.disconnect("chain_banked", on_bank)
	if controller.has_signal("chain_request_rejected") \
			and controller.is_connected("chain_request_rejected", on_rejected):
		controller.disconnect("chain_request_rejected", on_rejected)
	if controller.has_signal("recoverable_hazard") \
			and controller.is_connected("recoverable_hazard", on_hazard):
		controller.disconnect("recoverable_hazard", on_hazard)


# Strict D7 gathering stays on the shipped player-scanner/InputMap path. The
# driver may shorten the channel dwell, but GatherNode still owns depletion,
# yield, Trade XP, hints, and respawn. Unlike a generic interaction helper, the
# player remains beside the node until the channel settles so movement cannot
# cancel a legitimate harvest.
func _d7_scanner_harvest(target: Node3D, item_id: String,
		timeout_ms: int = 3000) -> bool:
	var player := local_player() as Node3D
	_web_smoke_d7_last_harvest_detail = {}
	if player == null or target == null or item_id == "" \
			or not target.has_method("is_used") or bool(target.call("is_used")):
		return false
	var node_kind := str(target.get("kind"))
	var gather_def: Dictionary = GatherDefs.NODE_KINDS.get(node_kind, {})
	var trade_key := str(gather_def.get("trade", ""))
	var trade_before := trade_lv(trade_key) if trade_key != "" else -1
	var before := material_count(item_id)
	var harvest_detail := {
		"expected_kind": node_kind, "expected_item": item_id,
		"target_pre": _d7_interactable_snapshot(target),
		"player_pre": _d7_harvest_player_snapshot(player),
		"seen_hint": bool(seen_hints.get(node_kind, false)),
		"trade": trade_key, "trade_before": trade_before,
		"material_before": before,
		"pre_press": {"paused": get_tree().paused, "modal_count": modal_count,
			"receipt": _d7_interaction_receipt_snapshot(player)},
	}
	_web_smoke_d7_last_harvest_detail = harvest_detail
	var home := player.global_position
	var channel_position := home
	var acquired := false
	# Most GatherNodes acquire immediately at a normal player standing distance.
	# Try those authored interaction distances first; retain the bounded sweep as
	# a fallback for dense props and uneven World navigation.
	for direction in [Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD, Vector3.BACK]:
		for distance in [1.25, 1.75, 2.25, 2.75]:
			if not is_instance_valid(player) or not is_instance_valid(target):
				harvest_detail["outcome"] = "scanner_target_invalid"
				_web_smoke_d7_last_harvest_detail = harvest_detail
				return false
			channel_position = Vector3(target.global_position.x + direction.x * distance,
				home.y, target.global_position.z + direction.z * distance)
			player.global_position = channel_position
			if player is CharacterBody3D:
				(player as CharacterBody3D).velocity = Vector3.ZERO
			await get_tree().physics_frame
			if not is_instance_valid(player) or not is_instance_valid(target):
				harvest_detail["outcome"] = "scanner_target_invalid"
				_web_smoke_d7_last_harvest_detail = harvest_detail
				return false
			if player.get("_active_interactable") == target:
				acquired = true
				break
		if acquired:
			break
	if acquired:
		pass
	else:
		for direction in [Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD, Vector3.BACK]:
			for step in 31:
				if not is_instance_valid(player) or not is_instance_valid(target):
					harvest_detail["outcome"] = "scanner_target_invalid"
					_web_smoke_d7_last_harvest_detail = harvest_detail
					return false
				var distance := lerpf(3.8, 0.85, float(step) / 30.0)
				channel_position = Vector3(target.global_position.x + direction.x * distance,
					home.y, target.global_position.z + direction.z * distance)
				player.global_position = channel_position
				if player is CharacterBody3D:
					(player as CharacterBody3D).velocity = Vector3.ZERO
				await get_tree().physics_frame
				if not is_instance_valid(player) or not is_instance_valid(target):
					harvest_detail["outcome"] = "scanner_target_invalid"
					_web_smoke_d7_last_harvest_detail = harvest_detail
					return false
				if player.get("_active_interactable") == target:
					acquired = true
					break
			if acquired:
				break
	if not acquired:
		if is_instance_valid(player):
			player.global_position = home
		harvest_detail["outcome"] = "scanner_not_acquired"
		harvest_detail["target_post"] = _d7_interactable_snapshot(target)
		_web_smoke_d7_last_harvest_detail = harvest_detail
		return false
	# Acquisition alone is not an interaction contract. A nearby marginal mark
	# can enter the scanner during the next physics edge and retarget the released
	# InputMap action. Re-approach at a position where this GatherNode is strictly
	# nearest, then prove PlayerController consumed the action on this exact node.
	# If the competition changes before the action boundary, retry positioning;
	# never dismiss or undo an accidentally-read story object after the fact.
	if not is_instance_valid(player) or not is_instance_valid(target):
		harvest_detail["outcome"] = "scanner_target_invalid"
		_web_smoke_d7_last_harvest_detail = harvest_detail
		return false
	var press_accepted := await _d7_press_interact_for_target(player, target)
	# The action helper yields across both input and physics edges.  A scene
	# change can free either endpoint during that await, so no post-press receipt
	# or success result is meaningful until the exact pair is revalidated.
	if not is_instance_valid(player) or not is_instance_valid(target):
		harvest_detail["outcome"] = "scanner_target_invalid"
		_web_smoke_d7_last_harvest_detail = harvest_detail
		return false
	harvest_detail["post_receipt"] = {"press_accepted": press_accepted,
		"paused": get_tree().paused, "modal_count": modal_count,
		"receipt": _d7_interaction_receipt_snapshot(player),
		"target": _d7_interactable_snapshot(target)}
	_web_smoke_d7_last_harvest_detail = harvest_detail
	if not press_accepted:
		if is_instance_valid(player):
			player.global_position = home
		harvest_detail["outcome"] = "input_not_accepted"
		_web_smoke_d7_last_harvest_detail = harvest_detail
		return false
	# A locked GatherNode still owns a genuine, correctly-targeted input receipt,
	# but its production interaction intentionally starts no channel. Classify it
	# immediately instead of burning the full channel timeout and obscuring the
	# authored Trade gate as a generic cancellation.
	var locked_after_press := target.has_method("locked") \
		and bool(target.call("locked", self))
	# The strict boundary check may select a safer approach side than the first
	# loose acquisition. Hold the actual action position through GatherNode's
	# production channel so this positioning repair cannot cancel the harvest.
	channel_position = player.global_position
	var deadline := Time.get_ticks_msec() + timeout_ms
	while not locked_after_press and material_count(item_id) <= before \
			and Time.get_ticks_msec() < deadline:
		if not is_instance_valid(player) or not is_instance_valid(target):
			harvest_detail["outcome"] = "scanner_target_invalid"
			_web_smoke_d7_last_harvest_detail = harvest_detail
			return false
		# Collision recovery can add a tiny displacement on dense World decor.
		# Hold the scanner position stable; this is positioning, not a GatherNode
		# mutation, and mirrors a player standing still through the progress ring.
		if is_instance_valid(player):
			player.global_position = channel_position
			if player is CharacterBody3D:
				(player as CharacterBody3D).velocity = Vector3.ZERO
		await get_tree().create_timer(0.01, true).timeout
	if not is_instance_valid(player) or not is_instance_valid(target):
		harvest_detail["outcome"] = "scanner_target_invalid"
		_web_smoke_d7_last_harvest_detail = harvest_detail
		return false
	var completed := material_count(item_id) > before
	harvest_detail["outcome"] = "completed" if completed else \
		"locked_by_trade" if locked_after_press else "timeout_or_cancel"
	harvest_detail["settle"] = {"paused": get_tree().paused, "modal_count": modal_count,
		"material_after": material_count(item_id),
		"material_delta": material_count(item_id) - before,
		"trade_after": trade_lv(trade_key) if trade_key != "" else -1,
		"player": _d7_harvest_player_snapshot(player),
		"receipt": _d7_interaction_receipt_snapshot(player),
		"target": _d7_interactable_snapshot(target)}
	_web_smoke_d7_last_harvest_detail = harvest_detail
	if is_instance_valid(player):
		player.global_position = home
		if player is CharacterBody3D:
			(player as CharacterBody3D).velocity = Vector3.ZERO
	await get_tree().physics_frame
	# Returning to the saved position also yields.  Treat a freed endpoint here
	# as invalid even if the gather completed before the frame boundary: callers
	# must never receive a successful interaction for a released target.
	if not is_instance_valid(player) or not is_instance_valid(target):
		harvest_detail["outcome"] = "scanner_target_invalid"
		_web_smoke_d7_last_harvest_detail = harvest_detail
		return false
	if completed and web_smoke_d7_enabled:
		_d7_record_cumulative_gather_proof(node_kind, item_id,
			"d7_scanner_harvest", before, material_count(item_id))
	harvest_detail["after_return_physics"] = {"paused": get_tree().paused,
		"modal_count": modal_count, "receipt": _d7_interaction_receipt_snapshot(player),
		"target": _d7_interactable_snapshot(target)}
	_web_smoke_d7_last_harvest_detail = harvest_detail
	return completed


const D7_INTERACT_TARGET_MARGIN := 0.05


func _d7_target_margin(player: Node3D, target: Node3D) -> float:
	if player == null or target == null or not is_instance_valid(player) \
			or not is_instance_valid(target) or player.get("_active_interactable") != target:
		return -INF
	var target_distance := player.global_position.distance_to(target.global_position)
	var nearest_other := INF
	var raw_overlaps: Variant = player.get("_overlapping_interactables")
	if raw_overlaps is Array:
		for candidate_v in raw_overlaps:
			if candidate_v == target or not (candidate_v is Node3D) \
					or not is_instance_valid(candidate_v):
				continue
			var candidate := candidate_v as Node3D
			if candidate.has_method("is_used") and bool(candidate.call("is_used")):
				continue
			nearest_other = minf(nearest_other,
				player.global_position.distance_to(candidate.global_position))
	return nearest_other - target_distance


func _d7_find_strict_target_position(player: Node3D, target: Node3D,
		home: Vector3) -> Dictionary:
	if player == null or target == null or not is_instance_valid(player) \
			or not is_instance_valid(target):
		return {"found": false, "invalid_target": true}
	var best_margin := -INF
	var best_distance := INF
	var best_position := home
	for direction in [Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD, Vector3.BACK]:
		# Area3D's entered/exited bookkeeping needs a real boundary crossing;
		# jumping among already-overlapping points can leave PlayerController's
		# nearest prompt stale. Follow the same bounded outside→inside approach as
		# the production D7 gather scanner, then score every settled position.
		for step in 31:
			if not is_instance_valid(player) or not is_instance_valid(target):
				return {"found": false, "invalid_target": true}
			var distance := lerpf(3.8, 0.85, float(step) / 30.0)
			var candidate_position := Vector3(target.global_position.x + direction.x * distance,
				home.y, target.global_position.z + direction.z * distance)
			player.global_position = candidate_position
			if player is CharacterBody3D:
				(player as CharacterBody3D).velocity = Vector3.ZERO
			await get_tree().physics_frame
			await get_tree().process_frame
			if not is_instance_valid(player) or not is_instance_valid(target):
				return {"found": false, "invalid_target": true}
			var margin := _d7_target_margin(player, target)
			var target_distance := candidate_position.distance_to(target.global_position)
			# A clear scanner position has an infinite margin.  Do not retain the
			# first clear point (the 3.8m boundary) merely because INF > INF is
			# false: the close end of the same legal approach is materially more
			# resilient when a neighbouring Area3D finishes entering during the
			# final settle before the InputMap edge.
			var equal_margin := margin == best_margin
			if margin > best_margin or (equal_margin and target_distance < best_distance):
				best_margin = margin
				best_distance = target_distance
				best_position = candidate_position
	if best_margin <= D7_INTERACT_TARGET_MARGIN:
		return {"found": false, "margin": best_margin}
	player.global_position = best_position
	if player is CharacterBody3D:
		(player as CharacterBody3D).velocity = Vector3.ZERO
	await get_tree().physics_frame
	await get_tree().process_frame
	if not is_instance_valid(player) or not is_instance_valid(target):
		return {"found": false, "invalid_target": true}
	return {"found": _d7_target_margin(player, target) > D7_INTERACT_TARGET_MARGIN,
		"margin": _d7_target_margin(player, target), "position": best_position,
		"distance": best_distance}


func _d7_press_interact_for_target(player: Node3D, target: Node3D) -> bool:
	if player == null or target == null or not is_instance_valid(player) \
			or not is_instance_valid(target):
		return false
	var home := player.global_position
	for _attempt in 2:
		if not is_instance_valid(player) or not is_instance_valid(target):
			return false
		# Ordinary gathers already reached a scanner position through the original
		# bounded approach. Do not rescan a clean target; pay the longer four-side
		# search only when an actual overlapping competitor makes that position
		# ambiguous.
		if player.get("_active_interactable") != target \
				or _d7_target_margin(player, target) <= D7_INTERACT_TARGET_MARGIN:
			var position_result: Dictionary = await _d7_find_strict_target_position(player, target, home)
			if not bool(position_result.get("found", false)) \
					or player.get("_active_interactable") != target \
					or _d7_target_margin(player, target) <= D7_INTERACT_TARGET_MARGIN:
				continue
		if not await _d7_settle_target_before_interact(player, target, home):
			continue
		if not is_instance_valid(target):
			return false
		if not player.has_method("arm_expected_interact") \
				or not bool(player.call("arm_expected_interact", target)):
			return false
		# The check immediately above and this action live on adjacent physics
		# edges. After the released action, PlayerController records the exact
		# Interactable that owned it, so a retarget is observable and rejected.
		Input.action_press(&"interact")
		await get_tree().physics_frame
		Input.action_release(&"interact")
		await get_tree().process_frame
		if not is_instance_valid(player) or not is_instance_valid(target):
			return false
		var receipt: Dictionary = player.call("last_interact_receipt") \
			if player.has_method("last_interact_receipt") else {}
		var status := String(receipt.get("status", ""))
		if status == "actual" and receipt.get("actual") == target:
			return true
		if status.begins_with("refused_"):
			# The in-boundary guard made no world call, so a bounded re-approach is
			# safe. An actual non-target action is never retried or concealed.
			continue
		if player.has_method("clear_expected_interact"):
			player.call("clear_expected_interact")
		# An actual non-target action would be a production bug; do not conceal it
		# by closing/reverting its dialog or campaign mutation.
		return false
	if is_instance_valid(player):
		player.global_position = home
	return false


func _d7_settle_target_before_interact(player: Node3D, target: Node3D,
		home: Vector3) -> bool:
	# This is deliberately the final gate before Input.action_press. Teleports
	# and Area3D enter/exit signals settle over a physics/process pair; holding
	# still across that pair ensures the released action cannot inherit a stale
	# nearest prompt. If a competitor wins during the settle, re-run the bounded
	# gradual approach once and require the same final proof again.
	for settle_attempt in 2:
		if player == null or target == null or not is_instance_valid(player) \
				or not is_instance_valid(target):
			return false
		if player is CharacterBody3D:
			(player as CharacterBody3D).velocity = Vector3.ZERO
		await get_tree().physics_frame
		await get_tree().process_frame
		if not is_instance_valid(player) or not is_instance_valid(target):
			return false
		if player.get("_active_interactable") == target \
				and _d7_target_margin(player, target) > D7_INTERACT_TARGET_MARGIN:
			return true
		if settle_attempt == 0:
			var position_result: Dictionary = await _d7_find_strict_target_position(player, target, home)
			if not bool(position_result.get("found", false)):
				return false
	return false


func _wait_d6_town_control() -> void:
	var deadline := Time.get_ticks_msec() + 20000
	var stable_since := -1
	var d7_stability = D7ControlStability.new()
	while Time.get_ticks_msec() < deadline:
		var dialogs: Array = []
		dialogs.append_array(get_tree().get_nodes_in_group("run_debrief"))
		dialogs.append_array(get_tree().get_nodes_in_group("FirstKnotHomecomingDebrief"))
		dialogs.append_array(get_tree().get_nodes_in_group("GoldenWallowSettlementDebrief"))
		if not dialogs.is_empty():
			stable_since = -1
			d7_stability.observe(_d7_control_owner_key(), false)
			for dialog in dialogs:
				if dialog != null and is_instance_valid(dialog) and dialog.has_method("_finish"):
					dialog.call("_finish")
				else:
					_web_smoke_d6_fail("A Pale Oath route debrief had no production close action.")
					return
			await get_tree().process_frame
			continue
		if not get_tree().paused and modal_count == 0:
			if _d7_control_observation_enabled():
				if d7_stability.observe(_d7_control_owner_key(), true):
					_d7_record_control_stability("d6_town", d7_stability)
					return
			else:
				if stable_since < 0:
					stable_since = Time.get_ticks_msec()
				if Time.get_ticks_msec() - stable_since >= 650:
					return
		else:
			stable_since = -1
			d7_stability.observe(_d7_control_owner_key(), false)
		if _d7_control_observation_enabled():
			await _d7_wait_control_observation()
		else:
			await get_tree().create_timer(0.1, true).timeout
	_web_smoke_d6_fail("Town never returned stable control for the Pale Oath.")


func _web_smoke_d6_fail(reason: String) -> void:
	_web_smoke_d6_stage = "failed"
	web_smoke_report("failed", reason)


# D7 is Fire in the Bough's strict release-Web route. It begins at the shipped
# title and only advances through production controls; its marathon may never
# seed campaign, Trade, inventory, Chart, source, or settlement truth.
func _web_smoke_d7_scene_ready(scene_name: String) -> void:
	if scene_name == "MainMenu":
		if _web_smoke_d7_stage == "":
			_web_smoke_d7_stage = "title_new_journey"
			var begin: Button = null
			for candidate_v in get_tree().current_scene.find_children("*", "Button", true, false):
				var candidate := candidate_v as Button
				if candidate != null and candidate.text == "Begin a New Journey":
					begin = candidate
					break
			if begin == null:
				_web_smoke_d7_fail("The shipped title did not expose Begin a New Journey.")
				return
			web_smoke_features["d7_real_title_new_journey"] = true
			web_smoke_report("title_new_journey")
			begin.pressed.emit()
		return
	if scene_name == "Town":
		if _web_smoke_d7_stage == "title_new_journey":
			web_smoke_report("town")
			_begin_d7_fresh_marathon.call_deferred()
			return
		if _web_smoke_d7_stage == "training_town":
			_d7_schedule_trade_training_continue()
			return
		if _web_smoke_d7_stage == "golden_deep_hollow_world":
			_d7_finish_golden_deep_hollow.call_deferred()
			return
		if _web_smoke_d7_stage == "prior_first_knot":
			_web_smoke_d1_scene_ready(scene_name)
			return
		if _web_smoke_d7_stage == "prior_golden_wallow":
			_d7_dispatch_golden_wallow(scene_name)
			return
		if _web_smoke_d7_stage == "prior_seventh_road":
			_web_smoke_d4_scene_ready(scene_name)
			return
		if _web_smoke_d7_stage == "prior_queens_summit":
			_web_smoke_d5_scene_ready(scene_name)
			return
		if _web_smoke_d7_stage == "prior_pale_oath":
			_web_smoke_d6_scene_ready(scene_name)
			return
		if _web_smoke_d7_stage.begins_with("ashen_"):
			web_smoke_report("ashen_return_%d" % _web_smoke_d7_ashen_ids.size())
			get_tree().create_timer(0.35).timeout.connect(_continue_d7_web_smoke)
			return
		if _web_smoke_d7_stage == "giant_return":
			_verify_d7_fire_settlement.call_deferred()
			return
	elif scene_name == "World":
		# A SceneTreeTimer belongs to the tree rather than this World.  Stamp the
		# new scene before any route helper can defer work, so a prior chapter's
		# delayed Far-Waystone action cannot silently return this chart instead.
		var owner_token := _d7_capture_world_owner_token("scene_ready")
		if _web_smoke_d7_stage == "training_world":
			_d7_drive_trade_training_world.bind(owner_token).call_deferred()
			return
		if _web_smoke_d7_stage == "golden_deep_hollow_world":
			_d7_harvest_world_then_return.bind(owner_token).call_deferred()
			return
		if _web_smoke_d7_stage == "prior_first_knot":
			_web_smoke_d1_scene_ready(scene_name)
			return
		if _web_smoke_d7_stage == "prior_golden_wallow":
			_d7_dispatch_golden_wallow(scene_name, owner_token)
			return
		if _web_smoke_d7_stage == "prior_seventh_road":
			_web_smoke_d4_scene_ready(scene_name, owner_token)
			return
		if _web_smoke_d7_stage == "prior_queens_summit":
			_web_smoke_d5_scene_ready(scene_name, owner_token)
			return
		if _web_smoke_d7_stage == "prior_pale_oath":
			_web_smoke_d6_scene_ready(scene_name, owner_token)
			return
		if _web_smoke_d7_stage.begins_with("ashen_"):
			_drive_d7_ashen_world.bind(owner_token).call_deferred()
		elif _web_smoke_d7_stage == "giant_world":
			get_tree().create_timer(0.7).timeout.connect(_drive_d7_giant_world.bind(owner_token))
		else:
			_web_smoke_d7_fail("A World opened outside the Fire release route.")


func _d7_dispatch_golden_wallow(scene_name: String, owner_token: Dictionary = {}) -> void:
	# D7 remains the first dispatcher. Golden Wallow may receive a scene only
	# once its explicit owner is active; otherwise a stale stage must fail closed
	# rather than letting dormant D3 logic advance a Fire route transition.
	if not web_smoke_d3_enabled:
		_web_smoke_d7_fail("D7 Golden Wallow stage had no active Golden dispatcher owner.")
		return
	_web_smoke_d3_scene_ready(scene_name, owner_token)

func _begin_d7_fresh_marathon() -> void:
	# The fresh state was created by MainMenu._on_new_game. Do not repair or
	# prefill it: a regression here must fail before any chapter is earned. A
	# shipped new game deliberately owns the exact two Snug starter components;
	# treating those as an injection would contradict reset_to_defaults itself.
	if campaign_state != CampaignData.empty_state() \
			or materials != CHART_STARTER_COMPONENTS or not charts.is_empty() \
			or trades != Progression.fresh_trade_state() \
			or known_chart_recipes != ChartsData.starting_recipe_ids() \
			or material_count("starheart_coal") != 0:
		_web_smoke_d7_fail("Begin a New Journey did not leave D7 at an empty campaign boundary.")
		return
	web_smoke_features["d7_fresh_campaign_boundary"] = true
	web_smoke_report("fresh_campaign")
	# Only the actual query-gated Web release route may take the owned 6x lease,
	# and only after the fresh boundary has reached its observable report.
	if _d7_simulation_clock_query_active() and not _d7_begin_simulation_clock():
		_web_smoke_d7_fail("D7 could not acquire its owned simulation-clock lease.")
		return
	# Reuse D1's no-fixture production journey for the first real chapter. Its
	# terminal continuation is redirected below into this marathon instead of
	# reporting a standalone D1 completion.
	web_smoke_d1_enabled = true
	_web_smoke_d7_stage = "prior_first_knot"
	_web_smoke_d1_scene_ready("Town")


func _d7_begin_golden_wallow_from_earned_state() -> void:
	# D3's release fixture is intentionally not called here. The source and
	# every input below must come from the state earned by the prior real chapter.
	if not CampaignData.chapter_cleared(campaign_state, CampaignData.FIRST_KNOT):
		_web_smoke_d7_fail("The fresh marathon lost the production First Knot settlement.")
		return
	# Enter at the first authored action only. Mire's guaranteed Mothmint is an
	# entry support gate; the later boss requirement is checked after its clues.
	var targets := _d7_progressive_training_targets("golden_wallow")
	await _wait_d7_town_control()
	if web_smoke_phase == "failed":
		return
	if not await _d7_prepare_support_trades(targets, "golden_wallow"):
		return
	if not _d7_training_complete(targets):
		_d7_begin_trade_training("golden_wallow", targets)
		return
	await _d7_enter_golden_route_from_earned_state()


func _d7_progressive_training_targets(resume: String) -> Dictionary:
	var recipe_id := ""
	match resume:
		"golden_wallow":
			recipe_id = "sallow_shallows"
		"golden_wallow_boss":
			recipe_id = "golden_wallow_boss"
		"seventh_road":
			recipe_id = "briar_maze"
		"seventh_road_boss":
			recipe_id = "seventh_road_boss"
		"queens_summit":
			recipe_id = "summit_approach"
		"queens_summit_boss":
			recipe_id = "queens_summit_boss"
		"pale_oath":
			recipe_id = "pale_veins"
		"pale_oath_boss":
			recipe_id = "pale_oath_boss"
		"fire_in_the_bough":
			recipe_id = "ashen_bough"
		_:
			return {}
	var requirements := ChartsData.recipe_production_requirements(recipe_id)
	if not bool(requirements.get("valid", false)):
		# Preserve the authored diagnostic. Treating a mapped data defect like an
		# unknown resume made the empty Dictionary look complete to older callers.
		return requirements
	return {"wayfinding": int(requirements.wayfinding),
		"huntcraft": int(requirements.huntcraft),
		"earthcraft": int(requirements.earthcraft),
		"wildcraft": int(requirements.wildcraft)}


func _d7_training_complete(targets: Dictionary) -> bool:
	if targets.is_empty():
		return false
	if targets.has("valid") and not bool(targets.get("valid", false)):
		_web_smoke_d7_fail("D7 mapped route requirements are invalid: %s." %
			String(targets.get("reason", "unknown production-data defect")))
		return false
	for trade in ["wayfinding", "huntcraft", "earthcraft", "wildcraft"]:
		if not targets.has(trade):
			_web_smoke_d7_fail("D7 route requirements omitted the %s Trade gate." % trade)
			return false
		if trade_lv(trade) < int(targets[trade]):
			return false
	return true


func _d7_enter_golden_route_from_earned_state() -> void:
	_web_smoke_d7_stage = "prior_golden_wallow"
	var hedge_runway := _d7_hedge_runway("sallow_shallows", 3,
		"golden_wallow_boss")
	if not await _d7_training_make_hedge_ink(hedge_runway):
		return
	web_smoke_features["d7_golden_renewable_ink"] = true
	web_smoke_d3_enabled = true
	if not await _d7_read_shallows_atlas_source():
		return
	web_smoke_report("golden_source")
	_web_smoke_d3_stage = "shallows_1"
	await _inscribe_d3_shallows()


func _d7_require_exact_wayfinding_xp(label: String, expected_xp: int) -> bool:
	var record: Dictionary = trades.get("wayfinding", {})
	var actual_xp := int(record.get("xp", 0))
	var expected_level := Progression.level_for_xp(expected_xp)
	var actual_level := trade_lv("wayfinding")
	var receipts: Dictionary = web_smoke_features.get(
		"d7_exact_wayfinding_checkpoints", {})
	receipts[label] = {"expected_xp": expected_xp, "actual_xp": actual_xp,
		"expected_level": expected_level, "actual_level": actual_level}
	web_smoke_features["d7_exact_wayfinding_checkpoints"] = receipts
	if actual_xp != expected_xp or actual_level != expected_level:
		_web_smoke_d7_fail("D7 %s required exact earned Wayfinding %d XP at level %d; reached %d XP at level %d." % [
			label, expected_xp, expected_level, actual_xp, actual_level])
		return false
	return true


func _d7_training_abort_requested() -> bool:
	return not web_smoke_d7_enabled or web_smoke_phase == "failed" \
		or _web_smoke_d7_stage == "native_probe_timeout"


func _d7_training_evidence_complete() -> bool:
	if int(_web_smoke_d7_training.get("world_legs", 0)) <= 0:
		return false
	var targets: Dictionary = _web_smoke_d7_training.get("targets", {})
	if int(targets.get("earthcraft", 1)) > 1 \
			and int(_web_smoke_d7_training.get("forge_crafts", 0)) <= 0:
		return false
	for kind in ["ore_rock", "forage_node", "log_pile"]:
		if not bool(_web_smoke_d7_training_seen_kinds.get(kind, false)):
			return false
	return true


func _d7_begin_trade_training(resume: String, targets: Dictionary) -> void:
	if targets.is_empty():
		_web_smoke_d7_fail("D7 cannot begin Trade training without mapped route requirements.")
		return
	if targets.has("valid") and not bool(targets.get("valid", false)):
		_web_smoke_d7_fail("D7 cannot train through invalid mapped requirements: %s." %
			String(targets.get("reason", "unknown production-data defect")))
		return
	if _web_smoke_d7_stage == "training_town" or _web_smoke_d7_stage == "training_world":
		return
	if not chart_recipe_known("green_hollow"):
		_web_smoke_d7_fail("Fresh D7 reached training before the real Green Hollow lesson was known.")
		return
	var prior_training := _web_smoke_d7_training.duplicate(true)
	_web_smoke_d7_training = {
		"resume": resume,
		"targets": targets.duplicate(true),
		"runs": 0,
		"world_legs": 0,
		"town_settlements": 0,
		"forge_crafts": int(prior_training.get("forge_crafts", 0)),
		"component_gold_spent": int(prior_training.get("component_gold_spent", 0)),
		"progressive_stage": resume,
		"practice_recipe": D7_TRAINING_PRACTICE_RECIPE,
		"world_leg_cap": D7_TRAINING_WORLD_LEG_CAP,
	}
	var cumulative_receipt: Dictionary = (web_smoke_features.get(
		"d7_progressive_training_receipt", {}) as Dictionary).duplicate(true)
	cumulative_receipt.merge({
		"active_stage": resume, "targets": targets.duplicate(true),
		"practice_recipe": D7_TRAINING_PRACTICE_RECIPE,
		"world_leg_cap": D7_TRAINING_WORLD_LEG_CAP,
		"stages_started": int(cumulative_receipt.get("stages_started", 0)) + 1,
	}, true)
	web_smoke_features["d7_progressive_training_receipt"] = cumulative_receipt
	# Scanner/forge evidence is cumulative across the one fresh attempt. Each
	# progressive stage still requires a new physical World leg, but it need not
	# pretend an already-proven ore/log/forage interaction never happened.
	if _web_smoke_d7_training_seen_kinds.is_empty():
		_web_smoke_d7_training_seen_kinds = {}
	_web_smoke_d7_stage = "training_town"
	web_smoke_report("trade_training_start")
	_d7_schedule_trade_training_continue()
	# This is a real-wall-clock guard, intentionally independent of D7's 6x
	# simulation lease. It proves a fast route cannot hide a stalled control
	# handoff behind scaled time.
	_d7_record_simulation_clock_watchdog()
	var watchdog := get_tree().create_timer(8.0, true, false, true)
	watchdog.timeout.connect(_d7_training_start_watchdog)


func _d7_schedule_trade_training_continue() -> void:
	if not web_smoke_d7_enabled or _web_smoke_d7_stage != "training_town" \
			or bool(_web_smoke_d7_training.get("continue_scheduled", false)) \
			or bool(_web_smoke_d7_training.get("continue_running", false)):
		return
	_web_smoke_d7_training["continue_scheduled"] = true
	web_smoke_report("trade_training_control_scheduled")
	# A Homecoming dialog can pause the offline tree between this route's prior
	# completion callback and the next deferred call. SceneTreeTimer's
	# process_always flag is deliberate: it starts the exact Town-control waiter
	# so that waiter can finish only the authored debrief through `_finish`.
	var timer := get_tree().create_timer(0.01, true)
	timer.timeout.connect(func() -> void:
		_web_smoke_d7_training["continue_scheduled"] = false
		_d7_continue_trade_training())


func _d7_training_start_watchdog() -> void:
	_d7_record_simulation_clock_watchdog(true)
	if not web_smoke_d7_enabled or _web_smoke_d7_stage != "training_town" \
			or web_smoke_phase == "failed" or int(_web_smoke_d7_training.get("runs", 0)) > 0 \
			or bool(_web_smoke_d7_training.get("control_wait_started", false)):
		return
	_d7_record_far_waystone_detail("training_control_not_entered", null,
		local_player() as Node3D, {"training_modal": _d7_training_modal_snapshot()})
	_web_smoke_d7_fail("D7 training never entered its bounded Town-control handoff.")


func _d7_training_modal_snapshot() -> Array:
	var snapshot: Array = []
	var scene := get_tree().current_scene
	if scene == null:
		return snapshot
	for child in scene.get_children():
		if child == null or not is_instance_valid(child) or not child.has_node("DialogueShell"):
			continue
		var groups: Array = []
		for group_v in child.get_groups():
			groups.append(String(group_v))
		snapshot.append({"name": String(child.name), "groups": groups,
			"speaker": String(child.get("_speaker")), "pages": child.get("_pages")})
	return snapshot


# Failure telemetry only.  A late World pause can be a production dialog,
# another modal surface, or a stale accounting leak; capture the concrete
# CanvasLayer identity before a D7 failure explains it.  This deliberately
# observes rather than finishes any UI, so an unexpected modal remains
# inspectable and no story/UI owner is bypassed.
func _d7_world_modal_snapshot() -> Array:
	var snapshot: Array = []
	var scene := get_tree().current_scene
	if scene == null:
		return snapshot
	for node_v in scene.find_children("*", "CanvasLayer", true, false):
		if not node_v is CanvasLayer or not is_instance_valid(node_v):
			continue
		var node := node_v as CanvasLayer
		var groups: Array = []
		for group_v in node.get_groups():
			groups.append(String(group_v))
		var script_path := ""
		var script: Script = node.get_script()
		if script != null:
			script_path = script.resource_path
		snapshot.append({"name": String(node.name), "script": script_path,
			"groups": groups, "visible": node.visible,
			"dialogue_shell": node.has_node("DialogueShell"),
			"speaker": str(node.get("_speaker")), "pages": node.get("_pages")})
	return snapshot


func _d7_interactable_snapshot(node: Variant) -> Dictionary:
	if node == null:
		return {"valid": false}
	if not (node is Node) or not is_instance_valid(node):
		return {"valid": false, "freed": true}
	# A queued World node remains a valid Object briefly after scene handoff, but
	# tree-only accessors such as get_path/global_position emit engine errors.
	# Preserve safe identity for diagnostics without turning normal teardown into
	# a browser release failure.
	if not (node as Node).is_inside_tree():
		return {"valid": false, "detached": true,
			"name": String((node as Node).name),
			"type": String((node as Node).get_class())}
	var out := {"valid": true, "name": String((node as Node).name),
		"path": str((node as Node).get_path()), "type": String((node as Node).get_class())}
	var script: Script = (node as Node).get_script()
	out["script"] = script.resource_path if script != null else ""
	if node is Node3D:
		var position := (node as Node3D).global_position
		# Web smoke is JSON-serialized. Keep vectors as plain scalar arrays rather
		# than relying on engine-specific Variant encoding in a browser payload.
		out["position"] = [position.x, position.y, position.z]
	var property_names := {}
	for property_info in (node as Node).get_property_list():
		property_names[String((property_info as Dictionary).get("name", ""))] = true
	for property in ["kind", "item_id", "ore_tier", "herb_tier", "req_lv",
			"_channeling", "_channel_t", "_channel_len", "_channel_start_hp",
			"_depleted"]:
		if property_names.has(property):
			out[property.trim_prefix("_")] = node.get(property)
	var node_kind := String(out.get("kind", ""))
	if GatherDefs.NODE_KINDS.has(node_kind):
		var trade_key := String((GatherDefs.NODE_KINDS[node_kind] as Dictionary).get(
			"trade", ""))
		out["gate_trade"] = trade_key
		out["trade_level"] = trade_lv(trade_key) if trade_key != "" else -1
		out["locked"] = bool(node.call("locked", self)) \
			if node.has_method("locked") else false
	if node.has_method("get_prompt_text"):
		out["prompt"] = String(node.call("get_prompt_text"))
	if node.has_method("is_used"):
		out["used"] = bool(node.call("is_used"))
	return out


func _d7_harvest_player_snapshot(player: Variant) -> Dictionary:
	if player == null or not is_instance_valid(player) or not (player is Node3D):
		return {"valid": false}
	var position := (player as Node3D).global_position
	return {"valid": true, "position": [position.x, position.y, position.z],
		"hp": int(player.get("hp")), "dead": bool(player.get("dead")),
		"velocity": [float((player as CharacterBody3D).velocity.x),
			float((player as CharacterBody3D).velocity.y),
			float((player as CharacterBody3D).velocity.z)] if player is CharacterBody3D \
			else [0.0, 0.0, 0.0]}


func _d7_interaction_receipt_snapshot(player: Variant) -> Dictionary:
	if player == null or not is_instance_valid(player) \
			or not player.has_method("last_interact_receipt"):
		return {"available": false}
	var receipt: Dictionary = player.call("last_interact_receipt")
	var snapshot := {"available": true, "status": String(receipt.get("status", "")),
		"expected": _d7_interactable_snapshot(receipt.get("expected")),
		"actual": _d7_interactable_snapshot(receipt.get("actual")),
		"last_interacted": _d7_interactable_snapshot(
			player.call("last_interacted") if player.has_method("last_interacted") else null)}
	return snapshot


func _d7_resume_after_trade_training(resume: String) -> void:
	var targets: Dictionary = _web_smoke_d7_training.get("targets",
		_d7_progressive_training_targets(resume))
	if not _d7_training_complete(targets):
		_web_smoke_d7_fail("D7 left its physical training road before all Trade gates were earned (WF %d, HC %d, EC %d, WC %d)." % [
			trade_lv("wayfinding"), trade_lv("huntcraft"), trade_lv("earthcraft"),
			trade_lv("wildcraft")])
		return
	for kind in ["ore_rock", "forage_node", "log_pile"]:
		if not bool(_web_smoke_d7_training_seen_kinds.get(kind, false)):
			_web_smoke_d7_fail("D7 trade training never completed a scanner-driven %s interaction." % kind)
			return
	var forge_required := int(targets.get("earthcraft", 1)) > 1
	if (forge_required and int(_web_smoke_d7_training.get("forge_crafts", 0)) <= 0) \
			or int(_web_smoke_d7_training.get("world_legs", 0)) <= 0:
		_web_smoke_d7_fail("D7 trade training skipped a required production Forge or World return leg.")
		return
	web_smoke_features["d7_trade_training_production"] = true
	web_smoke_features["d7_training_scanner_gathering"] = true
	web_smoke_features["d7_training_production_combat"] = true
	web_smoke_features["d7_training_real_forge"] = true
	web_smoke_report("trade_training_complete")
	_d7_record_progressive_level_ledger("training_%s_complete" % resume)
	_d7_complete_progressive_practice_receipt(resume, targets)
	# Native cumulative QA can stop precisely at this earned production boundary.
	# It is query-driver-only and leaves normal campaign resumption untouched.
	if bool(_web_smoke_d7_training.get("stop_after_complete", false)):
		web_smoke_report("trade_training_probe_complete")
		return
	match resume:
		"golden_wallow":
			# D7 owns the global dispatcher while composing prior chapter routes.
			# Transfer the route stage before any later Town work can lead to a
			# Golden Table/World transition; a stale `training_town` stage would
			# otherwise make the D7 World branch fail instead of delegating D3.
			if _web_smoke_d7_stage != "training_town":
				_web_smoke_d7_fail("D7 Golden Wallow handoff began outside its training Town boundary.")
				return
			await _d7_enter_golden_route_from_earned_state()
		"golden_wallow_boss":
			_web_smoke_d7_stage = "prior_golden_wallow"
			await _d7_prepare_golden_boss_from_earned_state()
		"seventh_road":
			_web_smoke_d7_stage = "prior_seventh_road"
			await _d7_begin_seventh_road_from_earned_state()
		"seventh_road_boss":
			_web_smoke_d7_stage = "prior_seventh_road"
			await _d7_prepare_seventh_boss_from_earned_state()
		"queens_summit":
			_web_smoke_d7_stage = "prior_queens_summit"
			await _d7_begin_queens_summit_from_earned_state()
		"queens_summit_boss":
			_web_smoke_d7_stage = "prior_queens_summit"
			await _d7_prepare_queen_boss_from_earned_state()
		"pale_oath":
			_web_smoke_d7_stage = "prior_pale_oath"
			await _d7_begin_pale_oath_from_earned_state()
		"pale_oath_boss":
			_web_smoke_d7_stage = "prior_pale_oath"
			await _d7_prepare_pale_boss_from_earned_state()
		"fire_in_the_bough":
			_web_smoke_d7_stage = "fire_lift"
			await _d7_begin_fire_from_earned_state()
		_:
			_web_smoke_d7_fail("D7 training had no valid resume route: %s." % resume)


func _d7_complete_progressive_practice_receipt(resume: String,
		targets: Dictionary) -> void:
	var progressive_receipt: Dictionary = web_smoke_features.get(
		"d7_progressive_training_receipt", {})
	progressive_receipt["completed_stage"] = resume
	progressive_receipt["runs"] = int(_web_smoke_d7_training.get("runs", 0))
	progressive_receipt["world_legs"] = int(
		_web_smoke_d7_training.get("world_legs", 0))
	progressive_receipt["town_settlements"] = int(
		_web_smoke_d7_training.get("town_settlements", 0))
	progressive_receipt["forge_crafts_cumulative"] = int(
		_web_smoke_d7_training.get("forge_crafts", 0))
	var practice_stages: Array = progressive_receipt.get("practice_stages", [])
	practice_stages.append({"stage": resume,
		"recipe": String(_web_smoke_d7_training.get(
			"practice_recipe", D7_TRAINING_PRACTICE_RECIPE)),
		"targets": targets.duplicate(true),
		"runs": int(_web_smoke_d7_training.get("runs", 0)),
		"world_legs": int(_web_smoke_d7_training.get("world_legs", 0)),
		"town_settlements": int(_web_smoke_d7_training.get("town_settlements", 0))})
	progressive_receipt["practice_stages"] = practice_stages
	progressive_receipt["runs_cumulative"] = int(
		progressive_receipt.get("runs_cumulative", 0)) \
		+ int(_web_smoke_d7_training.get("runs", 0))
	progressive_receipt["world_legs_cumulative"] = int(
		progressive_receipt.get("world_legs_cumulative", 0)) \
		+ int(_web_smoke_d7_training.get("world_legs", 0))
	progressive_receipt["town_settlements_cumulative"] = int(
		progressive_receipt.get("town_settlements_cumulative", 0)) \
		+ int(_web_smoke_d7_training.get("town_settlements", 0))
	web_smoke_features["d7_progressive_training_receipt"] = progressive_receipt


func _d7_read_shallows_atlas_source() -> bool:
	# This is deliberately separate from `_read_d3_shallows_atlas_source`.
	# The latter remains the Golden Wallow fixture's ordinary scanner proof;
	# fresh D7 arrives after a long renewable Town pass, when nearby prompts
	# make a fixed-offset scan nondeterministic.  The shared D7 helper moves the
	# real player through a bounded outside→inside scan and requires the exact
	# Interactable receipt before this source dialog can be considered opened.
	var scene := get_tree().current_scene
	var atlas := scene.get_node_or_null("AtlasDeepRumourSource") as Node3D \
		if scene != null else null
	if atlas == null or not atlas.has_method("active_source_id") \
		or String(atlas.call("active_source_id")) != "atlas_sallow_shallows":
		_web_smoke_d7_fail("The Living Atlas did not expose the D7 Shallows source.")
		return false
	var before := chart_source_status("atlas_sallow_shallows")
	if not bool(before.get("unlocked", false)) \
		or String(before.get("state", "")) != "eligible" \
		or (atlas.has_method("is_used") and bool(atlas.call("is_used"))):
		_web_smoke_d7_fail("The D7 Shallows Atlas page was not physically readable: %s." % before)
		return false
	if not await _d7_read_golden_source(atlas, "atlas_sallow_shallows"):
		return false
	var status := chart_source_status("atlas_sallow_shallows")
	if not (chart_recipe_journal.rumours as Array).has("atlas_sallow_shallows") \
		or String(status.get("state", "")) != "read" \
		or material_count("field_parchment") < 1 \
		or material_count("mire_reed") < 1 \
		or material_count("loop_cord") < 1:
		_web_smoke_d7_fail("The D7 physical Shallows Atlas read did not grant its missing-only lesson.")
		return false
	return true


func _d7_begin_golden_deep_hollow() -> void:
	# Waxed Vellum is not a pot/forge recipe. Mara's rain note supplies the
	# authored wet-road lesson, and that note appears only after a real Hollow
	# return. The first Shallows inscription resolves its Atlas page, making the
	# Deep Hollow page physically reachable on the same Atlas panel.
	if _web_smoke_d7_stage != "prior_golden_wallow" \
			or _web_smoke_d3_stage != "shallows_1" \
			or _web_smoke_d3_shallows_ids.size() != 1:
		_web_smoke_d7_fail("D7 Golden Deep Hollow began outside the first Shallows return boundary.")
		return
	# D3 normally waits for the return debrief before it resumes Town work. This
	# D7 insertion must preserve that control boundary too: Area3D can advance
	# physics frames while the modal still owns input, leaving every scanner
	# overlap empty. Settle the real debrief before the physical Atlas read.
	await _wait_d7_town_control()
	if web_smoke_phase == "failed":
		return
	if get_tree().paused or modal_count != 0:
		_web_smoke_d7_fail("The Deep Hollow Atlas began before its Shallows return released Town control.")
		return
	if not chart_recipe_known("sallow_shallows") \
			or not chart_source_unlocks.has("atlas_deep_hollow"):
		_web_smoke_d7_fail("The first physical Shallows did not resolve the Deep Hollow source gate.")
		return
	var scene := get_tree().current_scene
	var atlas := scene.get_node_or_null("AtlasDeepRumourSource") as Node3D \
		if scene != null else null
	if atlas == null or not atlas.has_method("active_source_id") \
			or String(atlas.call("active_source_id")) != "atlas_deep_hollow":
		_web_smoke_d7_fail("The first physical Shallows did not turn the Living Atlas to Deep Hollow.")
		return
	var deep_status := chart_source_status("atlas_deep_hollow")
	if not bool(deep_status.get("unlocked", false)) \
			or String(deep_status.get("state", "")) != "eligible" \
			or not atlas.has_method("is_used") or bool(atlas.call("is_used")):
		_web_smoke_d7_fail("The Deep Hollow Atlas page was visible but not physically readable: %s." % deep_status)
		return
	if (chart_recipe_journal.get("rumours", []) as Array).has("atlas_deep_hollow") \
			or material_count("hedge_sprig") != 0 \
			or material_count("stitched_parchment") != 0 \
			or material_count("hollow_stitch") != 0 \
			or bool(chart_source_status("mara_sallow_reed").get("unlocked", false)):
		_web_smoke_d7_fail("Deep Hollow's source kit or Mara's note existed before its earned Atlas read.")
		return
	if not await _d7_read_golden_source(atlas, "atlas_deep_hollow"):
		return
	if not (chart_recipe_journal.get("rumours", []) as Array).has("atlas_deep_hollow") \
			or material_count("hedge_sprig") != 1 \
			or material_count("stitched_parchment") != 1 \
			or material_count("hollow_stitch") != 1:
		_web_smoke_d7_fail("The physical Deep Hollow Atlas read did not leave its exact lesson components.")
		return
	web_smoke_features["d7_golden_deep_hollow_source"] = true
	web_smoke_report("atlas_deep_source")
	web_smoke_report("golden_deep_source")
	var chart := await _d3_table_inscribe("deep_hollow",
		["hedge_sprig", "stitched_parchment", "hollow_stitch"])
	if chart.is_empty() or web_smoke_phase == "failed":
		return
	if String(chart.get("recipe_id", "")) != "deep_hollow":
		_web_smoke_d7_fail("The physical Golden Deep Hollow Table did not mint its authored Chart.")
		return
	_web_smoke_d7_training["golden_deep_hollow_chart"] = \
		String(chart.get("chart_instance_id", ""))
	web_smoke_features["d7_golden_deep_hollow_table"] = true
	web_smoke_report("deep_table")
	web_smoke_report("golden_deep_table")
	_web_smoke_d7_stage = "golden_deep_hollow_world"
	if not await _d7_socket_chart_at_town(chart):
		return


func _d7_finish_golden_deep_hollow() -> void:
	if _web_smoke_d7_stage != "golden_deep_hollow_world":
		return
	await _wait_d7_town_control()
	if web_smoke_phase == "failed":
		return
	if not _d7_require_exact_wayfinding_xp(
			"golden_deep_return", D7_GOLDEN_DEEP_RETURN_WAYFINDING_XP):
		return
	var note_status := chart_source_status("mara_sallow_reed")
	var scene := get_tree().current_scene
	var note := scene.get_node_or_null("MaraSallowRumourSource") as Node3D \
		if scene != null else null
	if not bool(note_status.get("unlocked", false)) or note == null \
			or String(note_status.get("state", "")) not in ["locked", "eligible"]:
		_web_smoke_d7_fail("The completed Golden Deep Hollow did not reveal Mara's physical rain note.")
		return
	if (chart_recipe_journal.get("rumours", []) as Array).has("mara_sallow_reed") \
			or material_count("waxed_vellum") != 0 \
			or material_count("mire_reed") != 0 or material_count("sunk_knot") != 0:
		_web_smoke_d7_fail("Mara's wet-road kit existed before the completed Deep Hollow return.")
		return
	_web_smoke_d7_training["golden_deep_hollow_complete"] = true
	_web_smoke_d7_stage = "prior_golden_wallow"
	get_tree().create_timer(0.35).timeout.connect(_continue_d3_web_smoke)


func _d7_read_mara_sallow_source_then_prepare_boss() -> void:
	# Deep Hollow reveals the physical note at exact WF 1136 / level 11, but
	# Mara's authored lesson remains level 12. The remaining two Shallows are
	# the earned bridge to 1320; only their third return may commit this read.
	if not bool(_web_smoke_d7_training.get("golden_deep_hollow_complete", false)) \
			or _web_smoke_d3_shallows_ids.size() != 3:
		_web_smoke_d7_fail("Mara's rain note began outside the completed three-Shallows route.")
		return
	await _wait_d7_town_control()
	if web_smoke_phase == "failed":
		return
	if not pending_run_debrief.is_empty() or get_tree().paused or modal_count != 0:
		_web_smoke_d7_fail("Mara's rain note began before the third Shallows debrief released Town control.")
		return
	if not _d7_require_exact_wayfinding_xp(
			"golden_third_shallows_return", D7_GOLDEN_THIRD_SHALLOWS_WAYFINDING_XP):
		return
	var note_status := chart_source_status("mara_sallow_reed")
	var scene := get_tree().current_scene
	var note := scene.get_node_or_null("MaraSallowRumourSource") as Node3D \
		if scene != null else null
	if note == null or String(note_status.get("state", "")) != "eligible":
		_web_smoke_d7_fail("Mara's rain note was not eligible after the third Shallows return: %s." % note_status)
		return
	if not await _d7_read_golden_source(note, "mara_sallow_reed"):
		return
	note_status = chart_source_status("mara_sallow_reed")
	if String(note_status.get("state", "")) != "read" \
			or not (chart_recipe_journal.get("rumours", []) as Array).has("mara_sallow_reed") \
			or material_count("waxed_vellum") != 1 \
			or material_count("mire_reed") != 1 \
			or material_count("sunk_knot") != 1:
		_web_smoke_d7_fail("Mara's physical rain note did not settle the exact Sallow Mire lesson kit.")
		return
	_web_smoke_d7_training["golden_mire_note_complete"] = true
	web_smoke_features["d7_golden_mire_note"] = true
	web_smoke_report("mara_sallow_source")
	web_smoke_report("golden_mire_note")
	await _d7_prepare_golden_boss_from_earned_state()


func _d7_read_golden_source(target: Node3D, source_id: String) -> bool:
	var player := local_player() as Node3D
	if target == null or not is_instance_valid(target) or player == null:
		_web_smoke_d7_fail("D7 Golden route had no live scanner target for %s." % source_id)
		return false
	# Sources can sit beside several Town prompts. Reuse D7's strict
	# outside→inside target selection and receipt proof instead of a chapter-
	# specific fixed-offset scanner: the physical Interactable must receive this
	# exact released action or the route fails with inspectable evidence.
	# The Atlas is mounted above the path; align the scanner's own 0.9m sensor
	# center to its physical Area before the bounded horizontal approach.
	# This is only player positioning (the same category as the normal scanner
	# sweep), never a source or inventory mutation.
	player.global_position.y = target.global_position.y - 0.9
	await get_tree().physics_frame
	await get_tree().process_frame
	var scanner_position: Dictionary = await _d7_find_strict_target_position(
		player, target, player.global_position)
	if not bool(scanner_position.get("found", false)) \
			or not await _d7_press_interact_for_target(player, target):
		_web_smoke_d7_fail("D7 Golden route could not scanner-read %s: %s." % [
			source_id, {"position": scanner_position,
				"receipt": _d7_interaction_receipt_snapshot(player),
				"player_position": player.global_position,
				"overlaps": player.get("_overlapping_interactables"),
				"target": _d7_interactable_snapshot(target)}])
		return false
	var dialog := _d7_source_dialog_owned_by(target, source_id)
	if dialog == null or not dialog.has_method("_finish"):
		_web_smoke_d7_fail("D7 Golden source %s did not open its production dialog." % source_id)
		return false
	dialog.call("_finish")
	await get_tree().process_frame
	await get_tree().process_frame
	var status := chart_source_status(source_id)
	if String(status.get("state", "")) != "read":
		_web_smoke_d7_fail("D7 Golden source %s did not commit its read transaction." % source_id)
		return false
	return true


func _d7_source_dialog_owned_by(target: Node3D, source_id: String) -> Node:
	if target == null or not is_instance_valid(target):
		return null
	for dialog in get_tree().get_nodes_in_group("ChartRumourSourceDialog"):
		if dialog != null and is_instance_valid(dialog) \
				and String(dialog.get_meta("chart_source_id", "")) == source_id \
				and int(dialog.get_meta("chart_source_owner_id", 0)) == target.get_instance_id():
			return dialog
	return null


func _d7_read_prior_saga_source(target: Node3D, source_id: String,
		dialog_group: String, source_label: String) -> bool:
	# D4–D6 keep their fixed-offset scanner helpers for their standalone release
	# proofs.  Fresh D7 reaches the same Town landmarks after long, noisy routes,
	# so use its receipt-proven scanner here: the exact target must own the shipped
	# InputMap press before the one expected production dialog is acknowledged.
	var player := local_player() as Node3D
	if target == null or not is_instance_valid(target) or player == null:
		_web_smoke_d7_fail("D7 %s handoff had no live scanner target." % source_label)
		return false
	if target.has_method("active_source_id") \
			and String(target.call("active_source_id")) != source_id:
		_web_smoke_d7_fail("The %s landmark did not expose %s." % [source_label, source_id])
		return false
	var before := chart_source_status(source_id)
	if not bool(before.get("unlocked", false)) or String(before.get("state", "")) != "eligible" \
			or (target.has_method("is_used") and bool(target.call("is_used"))):
		_web_smoke_d7_fail("The %s source was not physically readable: %s." % [
			source_label, before])
		return false
	if not get_tree().get_nodes_in_group(dialog_group).is_empty():
		_web_smoke_d7_fail("The %s handoff found a stale production dialog before its scanner press." % source_label)
		return false
	# Town landmarks are mounted above the walk plane. Align the scanner centre
	# with their authored interaction Area (not merely the Node3D origin), then
	# use the normal bounded outside→inside scan; this remains player positioning,
	# never a source mutation.
	var collision_offset := target.call("get_collision_offset") as Vector3 \
		if target.has_method("get_collision_offset") else Vector3.ZERO
	player.global_position.y = target.global_position.y + collision_offset.y - 0.9
	await get_tree().physics_frame
	await get_tree().process_frame
	var scanner_position: Dictionary = await _d7_find_strict_target_position(
		player, target, player.global_position)
	if not bool(scanner_position.get("found", false)) \
			or not await _d7_press_interact_for_target(player, target):
		if not is_instance_valid(player) or not is_instance_valid(target):
			_web_smoke_d7_fail("D7 %s scanner target was released before its receipt settled." % source_label)
			return false
		_web_smoke_d7_fail("D7 %s could not scanner-read %s: %s." % [
			source_label, source_id, {"position": scanner_position,
				"receipt": _d7_interaction_receipt_snapshot(player),
				"player_position": player.global_position,
				"overlaps": player.get("_overlapping_interactables"),
				"target": _d7_interactable_snapshot(target)}])
		return false
	var receipt := _d7_interaction_receipt_snapshot(player)
	web_smoke_features["d7_prior_source_receipt_%s" % source_id] = {
		"source_id": source_id, "target": _d7_interactable_snapshot(target),
		"receipt": receipt,
	}
	var dialogs := get_tree().get_nodes_in_group(dialog_group)
	if dialogs.size() != 1 or not dialogs[0].has_method("_finish"):
		_web_smoke_d7_fail("The %s source did not open its production dialog." % source_label)
		return false
	var dialog := dialogs[0]
	dialog.call("_finish")
	await get_tree().process_frame
	await get_tree().process_frame
	if not get_tree().get_nodes_in_group(dialog_group).is_empty() \
			or get_tree().paused or modal_count != 0:
		_web_smoke_d7_fail("The %s source dialog did not release its exact modal owner." % source_label)
		return false
	var status := chart_source_status(source_id)
	if String(status.get("state", "")) != "read":
		_web_smoke_d7_fail("The %s source did not commit its read transaction." % source_label)
		return false
	return true


func _d7_continue_trade_training() -> void:
	if bool(_web_smoke_d7_training.get("town_driver_active", false)):
		return
	_web_smoke_d7_training["town_driver_active"] = true
	await _d7_continue_trade_training_impl()
	_web_smoke_d7_training["town_driver_active"] = false


func _d7_continue_trade_training_impl() -> void:
	if not web_smoke_d7_enabled or _web_smoke_d7_stage != "training_town" \
			or web_smoke_phase == "failed" \
			or bool(_web_smoke_d7_training.get("continue_running", false)):
		return
	_web_smoke_d7_training["continue_running"] = true
	_web_smoke_d7_training["control_wait_started"] = true
	web_smoke_report("trade_training_control_wait")
	await _wait_d7_town_control()
	_web_smoke_d7_training["continue_running"] = false
	if web_smoke_phase == "failed":
		return
	# Keep an observation-only receipt for the cumulative native/browser probe:
	# every completed World leg must reach an unpaused, modal-free Town before a
	# later lap may be prepared.  This records no outcome and does not decide
	# progression; it makes an interrupted/deferred Far Waystone transition
	# distinguishable from a genuine settled return.
	var returned_legs := int(_web_smoke_d7_training.get("world_legs", 0))
	var settlements := int(_web_smoke_d7_training.get("town_settlements", 0))
	if returned_legs > settlements:
		if get_tree().current_scene == null or get_tree().current_scene.name != "Town" \
				or get_tree().paused or modal_count != 0:
			_d7_record_far_waystone_detail("interaction_did_not_settle", null,
				local_player() as Node3D, {"settlement_check": "town_not_stable"})
			_web_smoke_d7_fail("D7 training resumed before its Far Waystone return settled Town control.")
			return
		_web_smoke_d7_training["town_settlements"] = returned_legs
	var pause_after := int(_web_smoke_d7_training.get("pause_after_world_legs", 0))
	if pause_after > 0 and returned_legs >= pause_after:
		web_smoke_report("trade_training_probe_pause")
		return
	var targets: Dictionary = _web_smoke_d7_training.get("targets", {})
	if targets.is_empty():
		_web_smoke_d7_fail("D7 training lost its target contract.")
		return
	if returned_legs >= D7_TRAINING_WORLD_LEG_CAP and not _d7_training_complete(targets):
		_web_smoke_d7_fail("D7 trade training reached its 60 World-leg contract before all Trade gates were earned.")
		return
	if _d7_training_complete(targets) and _d7_training_evidence_complete():
		var resume := String(_web_smoke_d7_training.get("resume", ""))
		await _d7_resume_after_trade_training(resume)
		return
	var runs := int(_web_smoke_d7_training.get("runs", 0))
	if runs >= 180:
		_web_smoke_d7_fail("D7 trade training exceeded 180 real Chart returns (WF %d, HC %d, EC %d, WC %d)." % [
			trade_lv("wayfinding"), trade_lv("huntcraft"), trade_lv("earthcraft"),
			trade_lv("wildcraft")])
		return
	# Establish one real forge proof early, but hold the high-level Earthcraft
	# finish until the other Trades and the complete World/gathering receipt are
	# already earned.  That keeps Town smithing a focused final road instead of
	# silently replacing the Chart route that teaches Wayfinding, Huntcraft, and
	# Wildcraft.
	var earthcraft_target := int(targets.get("earthcraft", 1))
	var other_trade_gates_met := trade_lv("wayfinding") >= int(targets.get("wayfinding", 1)) \
			and trade_lv("huntcraft") >= int(targets.get("huntcraft", 1)) \
			and trade_lv("wildcraft") >= int(targets.get("wildcraft", 1))
	var need_first_forge_proof := earthcraft_target > 1 \
		and int(_web_smoke_d7_training.get("forge_crafts", 0)) <= 0
	if need_first_forge_proof:
		if not await _d7_training_forge_copper({"earthcraft": mini(2, earthcraft_target)}):
			return
	elif other_trade_gates_met and _d7_training_evidence_complete() \
			and trade_lv("earthcraft") < earthcraft_target:
		if not await _d7_training_forge_copper(targets):
			return
	# Once the Town smithing loop has reached the final remaining Trade gate,
	# do not spend another whole Chart on a completion that already has its World
	# return and all three gathering kinds.  This is a route decision only: the
	# XP remains owned by renewable copper nodes and live Forge transactions.
	if _d7_training_complete(targets) and _d7_training_evidence_complete():
		var completed_resume := String(_web_smoke_d7_training.get("resume", ""))
		await _d7_resume_after_trade_training(completed_resume)
		return
	# The Town lumber pile is renewable and already needed later for Ash Ink.
	# Prove its real scanner/channel path once up front so training completion
	# cannot depend on randomly rolling a Wood Grove Affix.
	if not bool(_web_smoke_d7_training_seen_kinds.get("log_pile", false)) \
			and not await _d7_training_harvest_town("logs", 1):
		return
	# Keep two earned pots after the Green Hollow's ordinary cost.  The later
	# source-taught roads still stage and charge every one through their own
	# Tables; this just prevents a fresh marathon from reaching a real source
	# with an empty ink shelf after its production practice laps.
	if not await _d7_training_make_hedge_ink(4):
		return
	var chart := await _d7_training_commit_green_hollow()
	if chart.is_empty() or web_smoke_phase == "failed":
		return
	_web_smoke_d7_training["runs"] = runs + 1
	_web_smoke_d7_stage = "training_world"
	if not await _d7_socket_chart_at_town(chart):
		return


func _d7_training_make_hedge_ink(pots: int) -> bool:
	var current := material_count("hedge_ink")
	if current >= pots:
		return true
	var needed_pots := pots - current
	if not await _d7_training_harvest_town("wild_herb", needed_pots * 3):
		return false
	var bench: Node = await _d7_open_chart_table()
	if bench == null:
		return false
	var panel := bench.get_node_or_null("ChartTablePanel")
	var view := panel.get_node_or_null("ChartTableView") if panel != null else null
	var mix := view.find_child("MixTab", true, false) as Button if view != null else null
	if mix == null:
		bench.close()
		_web_smoke_d7_fail("D7 training could not reach Quill's physical copper pot.")
		return false
	mix.pressed.emit()
	await get_tree().process_frame
	for _pot in needed_pots:
		var before := material_count("hedge_ink")
		for _herb in 3:
			if not await _press_d6_supply_control(bench, "wild_herb"):
				bench.close()
				_web_smoke_d7_fail("D7 training could not stage a physically gathered Wild Herb in the pot.")
				return false
		await get_tree().process_frame
		if material_count("hedge_ink") == before + 1:
			continue
		var try_mix := view.find_child("TryMixButton", true, false) as Button
		if try_mix == null or try_mix.disabled:
			bench.close()
			_web_smoke_d7_fail("D7 training's Hedge Ink pot never offered its production mix action.")
			return false
		try_mix.pressed.emit()
		await get_tree().process_frame
		await get_tree().process_frame
		if material_count("hedge_ink") != before + 1:
			bench.close()
			_web_smoke_d7_fail("D7 training's physical Hedge Ink mix did not settle exactly one pot.")
			return false
	bench.close()
	return material_count("hedge_ink") >= pots


# Build a chapter's authored Ink through renewable Town nodes and the physical
# Copper Pot. `target_count` is the number that must remain on the shelf after
# this helper returns; it never grants ingredients, discovery, or output.
func _d7_mix_ink_to_count(ink_id: String, target_count: int) -> bool:
	if material_count(ink_id) >= target_count:
		return true
	var recipe: Dictionary = GatherDefs.INK_RECIPES.get(ink_id, {})
	if recipe.is_empty():
		_web_smoke_d7_fail("D7 has no authored renewable recipe for %s." % ink_id)
		return false
	# Fail before the first scanner interaction. A route which cannot legally
	# harvest or mix an ingredient must prepare its support Trades in Town first.
	var support := GatherDefs.ink_trade_requirements(ink_id)
	if not bool(support.get("valid", false)):
		_web_smoke_d7_fail("D7 cannot resolve %s's production requirements (%s)." % [
			ink_id, String(support.get("reason", "invalid recipe"))])
		return false
	if trade_lv("earthcraft") < int(support.get("earthcraft", 1)) \
			or trade_lv("wildcraft") < int(support.get("wildcraft", 1)):
		_web_smoke_d7_fail("D7 cannot scan ingredients for %s before Earthcraft %d / Wildcraft %d." % [
			ink_id, int(support.get("earthcraft", 1)), int(support.get("wildcraft", 1))])
		return false
	var pots_needed := target_count - material_count(ink_id)
	for material_id_v in (recipe.get("inputs", {}) as Dictionary):
		var material_id := String(material_id_v)
		var required := pots_needed * int((recipe.inputs as Dictionary)[material_id_v])
		if material_count(material_id) >= required:
			continue
		if material_id == "hedge_ink":
			if not await _d7_training_make_hedge_ink(required):
				return false
		elif not await _d7_training_harvest_town(material_id,
				required - material_count(material_id)):
			return false
	var bench: Node = await _d7_open_chart_table()
	if bench == null:
		return false
	var panel := bench.get_node_or_null("ChartTablePanel")
	var view := panel.get_node_or_null("ChartTableView") if panel != null else null
	var mix := view.find_child("MixTab", true, false) as Button if view != null else null
	if mix == null:
		bench.close()
		_web_smoke_d7_fail("D7 could not reach the physical %s pot." % ink_id)
		return false
	mix.pressed.emit()
	await get_tree().process_frame
	for _pot in pots_needed:
		var before := material_count(ink_id)
		for material_id_v in (recipe.inputs as Dictionary):
			var material_id := String(material_id_v)
			for _measure in int((recipe.inputs as Dictionary)[material_id_v]):
				if not await _press_d6_supply_control(bench, material_id):
					bench.close()
					_web_smoke_d7_fail("D7's %s pot rejected earned %s." % [ink_id, material_id])
					return false
		# Known mixtures settle on their final measure; the first experiment
		# remains in the pot until the player presses the production Try action.
		if material_count(ink_id) == before + 1:
			continue
		var try_mix := view.find_child("TryMixButton", true, false) as Button
		if try_mix == null or try_mix.disabled:
			bench.close()
			_web_smoke_d7_fail("D7's exact %s experiment never enabled Try the Mix." % ink_id)
			return false
		try_mix.pressed.emit()
		await get_tree().process_frame
		await get_tree().process_frame
		if material_count(ink_id) != before + 1:
			bench.close()
			_web_smoke_d7_fail("D7's physical %s mix did not settle exactly one pot." % ink_id)
			return false
	bench.close()
	return material_count(ink_id) >= target_count and ink_discovered(ink_id)


func _d7_chart_material_cost(recipe_id: String, material_id: String) -> int:
	var recipe: Dictionary = ChartsData.CHART_RECIPES.get(recipe_id, {})
	var output: Dictionary = recipe.get("output", {})
	var template: Dictionary = ChartsData.TEMPLATES.get(
		String(output.get("template_id", "")), {})
	var count := int((template.get("base_cost", {}) as Dictionary).get(material_id, 0))
	if material_id == "hedge_ink" and count > 0 \
			and perk_active("wayfinding", "thrifty_quill"):
		count = maxi(1, count - 1)
	count += (recipe.get("required_inks", []) as Array).count(material_id)
	return count


func _d7_hedge_runway(ordinary_recipe: String, ordinary_count: int,
		boss_recipe: String, mixed_inks: Dictionary = {}) -> int:
	var total := ordinary_count * _d7_chart_material_cost(ordinary_recipe, "hedge_ink")
	total += _d7_chart_material_cost(boss_recipe, "hedge_ink")
	for ink_id_v in mixed_inks:
		var ink_id := String(ink_id_v)
		var recipe: Dictionary = GatherDefs.INK_RECIPES.get(ink_id, {})
		total += int(mixed_inks[ink_id_v]) \
			* int((recipe.get("inputs", {}) as Dictionary).get("hedge_ink", 0))
	return total


func _d7_training_commit_green_hollow() -> Dictionary:
	var bench: Node = await _d7_open_chart_table()
	if bench == null:
		return {}
	var panel := bench.get_node_or_null("ChartTablePanel")
	var view := panel.get_node_or_null("ChartTableView") if panel != null else null
	var supplies := view.find_child("SuppliesTab", true, false) as Button if view != null else null
	if supplies == null:
		bench.close()
		_web_smoke_d7_fail("D7 training's physical Table had no Supplies controls.")
		return {}
	supplies.pressed.emit()
	await get_tree().process_frame
	for component_id in ["hedge_sprig", "field_parchment", "loop_cord"]:
		var before := material_count(component_id)
		var gold_before := gold
		if not await _press_d6_supply_control(bench, component_id):
			bench.close()
			_web_smoke_d7_fail("D7 training could not stage renewable %s at the physical Table." % component_id)
			return {}
		var draft: Dictionary = bench.get("draft")
		if material_count(component_id) > before:
			var expected_price := ChartsData.component_supply_price(component_id)
			if expected_price <= 0 or gold_before - gold != expected_price:
				bench.close()
				_web_smoke_d7_fail("D7 training's renewable %s purchase did not charge its authored gold price." % component_id)
				return {}
			_web_smoke_d7_training["component_gold_spent"] = \
				int(_web_smoke_d7_training.get("component_gold_spent", 0)) + expected_price
			web_smoke_features["d7_training_component_economy"] = true
		if not (draft.get("grid", {}) as Dictionary).values().has(component_id):
			if material_count(component_id) <= before \
					or not await _press_d6_supply_control(bench, component_id):
				bench.close()
				_web_smoke_d7_fail("D7 training's renewable %s did not settle into the Table grammar." % component_id)
				return {}
	var preview: Dictionary = bench.call("current_preview")
	var action := view.find_child("InscribeChartButton", true, false) as Button
	var expected_grid := {"n": "hedge_sprig", "c": "field_parchment", "w": "loop_cord"}
	if String(preview.get("recipe_id", "")) != "green_hollow" \
			or not bool(preview.get("commit_ready", false)) or action == null or action.disabled \
			or (bench.get("draft").get("grid", {}) as Dictionary) != expected_grid:
		bench.close()
		_web_smoke_d7_fail("D7 training did not resolve the cheapest renewable known Green Hollow grammar.")
		return {}
	var before_costs := {}
	for material_v in (preview.get("costs", {}) as Dictionary):
		before_costs[String(material_v)] = material_count(String(material_v))
	var charts_before := charts.size()
	action.pressed.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	var chart: Dictionary = charts.back() if charts.size() == charts_before + 1 else {}
	bench.close()
	if String(chart.get("recipe_id", "")) != "green_hollow":
		_web_smoke_d7_fail("D7 training's real Table commit did not mint Green Hollow.")
		return {}
	for material_v in (preview.get("costs", {}) as Dictionary):
		var material_id := String(material_v)
		if material_count(material_id) != int(before_costs[material_id]) \
				- int((preview.get("costs", {}) as Dictionary)[material_v]):
			_web_smoke_d7_fail("D7 training did not charge Green Hollow's exact %s input." % material_id)
			return {}
	web_smoke_features["d7_training_real_table"] = true
	return chart


func _d7_open_chart_table():
	if _d7_training_abort_requested():
		return null
	var scene := get_tree().current_scene
	var player := local_player() as Node3D
	var tables := get_tree().get_nodes_in_group("inscribing_table")
	if scene == null or player == null or tables.size() != 1:
		_web_smoke_d7_fail("D7 training could not find the authored Town Inscribing Table.")
		return null
	var table := tables[0] as Node3D
	var home := player.global_position
	player.global_position = Vector3(table.global_position.x + 1.05, home.y, table.global_position.z)
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	if _d7_training_abort_requested():
		return null
	if not is_instance_valid(player) or not is_instance_valid(table) or not is_instance_valid(scene):
		_web_smoke_d7_fail("D7 training lost its player or Inscribing Table during scanner positioning.")
		return null
	if player.get("_active_interactable") != table:
		player.global_position = home
		_web_smoke_d7_fail("D7 training's player scanner did not acquire the Inscribing Table.")
		return null
	await _press_c2_world_interact()
	if _d7_training_abort_requested():
		return null
	if not is_instance_valid(player) or not is_instance_valid(scene):
		_web_smoke_d7_fail("D7 training lost Town during its physical Table interaction.")
		return null
	player.global_position = home
	await get_tree().process_frame
	if _d7_training_abort_requested():
		return null
	if not is_instance_valid(scene):
		_web_smoke_d7_fail("D7 training lost Town while waiting for its Table panel.")
		return null
	for child in scene.get_children():
		if child.has_node("ChartTablePanel"):
			return child
	_web_smoke_d7_fail("D7 training did not open the physical Chart Table through interact.")
	return null


func _d7_training_harvest_town(item_id: String, count: int) -> bool:
	var player := local_player()
	if player == null:
		_web_smoke_d7_fail("D7 training had no Town player for %s harvesting." % item_id)
		return false
	var harvested := 0
	var attempts := 0
	while harvested < count and attempts < count * 8 + 32:
		if not web_smoke_d7_enabled or web_smoke_phase == "failed" \
				or _web_smoke_d7_stage == "native_probe_timeout":
			return false
		var progressed := false
		for node_v in get_tree().get_nodes_in_group("interactable"):
			if harvested >= count:
				break
			if not node_v is Node3D or not is_instance_valid(node_v) \
					or not node_v.has_method("interact") \
					or not node_v.has_method("is_used"):
				continue
			var node_item = node_v.get("item_id")
			if node_item == null or String(node_item) != item_id:
				continue
			if bool(node_v.call("is_used")):
				continue
			node_v.set("respawn_sec", 0.01)
			node_v.set("_tier_channel", 0.01)
			var before := material_count(item_id)
			var target := node_v as Node3D
			var completed := await _d7_scanner_harvest(target, item_id, 1200)
			if not web_smoke_d7_enabled or web_smoke_phase == "failed" \
					or _web_smoke_d7_stage == "native_probe_timeout":
				return false
			if String(_web_smoke_d7_last_harvest_detail.get("outcome", "")) == "scanner_target_invalid":
				_web_smoke_d7_fail("D7 Town harvest lost its scanner target before the production channel settled.")
				return false
			if not is_instance_valid(target):
				attempts += 1
				continue
			if material_count(item_id) > before:
				harvested += 1
				attempts += 1
				progressed = true
				var node_kind = node_v.get("kind")
				if node_kind != null and String(node_kind) in ["ore_rock", "forage_node", "log_pile"]:
					# A fresh run may have just opened the authored first-use teaching
					# page. Let it build, then dismiss only that real DialogueShell before
					# asking the player scanner to start another production channel.
					# Without this acknowledgement the offline modal pause makes every
					# subsequent InputMap interact legitimately inert.
					if not await _d7_finish_fresh_hint(String(node_kind)):
						return false
			elif not completed:
				attempts += 1
		if not progressed:
			await get_tree().create_timer(0.02, true).timeout
			attempts += 1
	if harvested != count:
		_web_smoke_d7_fail("D7 training's physical Town %s loop stopped at %d/%d gathers." % [item_id, harvested, count])
		return false
	return true


func _d7_training_forge_copper(targets: Dictionary) -> bool:
	if trade_lv("earthcraft") >= int(targets.get("earthcraft", 1)):
		return true
	# Earthcraft can otherwise become the sole late gate after Wayfinding,
	# Huntcraft, and Wildcraft have capped.  This Town finish remains entirely
	# physical: each loop re-reads live XP and the satchel, mines released Town
	# ore through the player scanner, then presses Hod's real Forge row.  At
	# Earthcraft 3 it deliberately upgrades to Bogiron (2 x 12 mining XP + 12
	# smelting XP) rather than grinding the starter Copper chain.
	var target_level := int(targets.get("earthcraft", 1))
	var xp_before := int((trades.get("earthcraft", {}) as Dictionary).get("xp", 0))
	var target_xp := Progression.xp_for_level(target_level)
	var started_msec := Time.get_ticks_msec()
	var forge: Node3D = null
	for node_v in get_tree().get_nodes_in_group("interactable"):
		var station_id = node_v.get("station_id") if node_v is Node3D else null
		if node_v is Node3D and station_id != null and String(station_id) == "forge":
			forge = node_v as Node3D
			break
	if forge == null:
		_web_smoke_d7_fail("D7 training could not find Hod's physical forge.")
		return false
	# Do not open the modal until the first real ore pair is in the satchel:
	# offline CraftPanel pauses the tree, and the next scanner mining approach
	# must always happen with ordinary Town control.
	var panel: Node = null
	var crafted_count := 0
	var copper_nodes_requested := 0
	var bogiron_nodes_requested := 0
	var copper_bars := 0
	var bogiron_bars := 0
	var no_progress := 0
	# A gathered batch can cross a low early-level threshold by itself.  Keep
	# going through one affordable Forge transaction so the route's stated
	# production proof remains true without claiming mining alone was smithing.
	while (int((trades.get("earthcraft", {}) as Dictionary).get("xp", 0)) < target_xp \
			or crafted_count == 0) and no_progress < 3:
		if _d7_training_abort_requested():
			return false
		var use_bogiron := trade_lv("earthcraft") >= 3
		var ore_id := "bogiron_ore" if use_bogiron else "copper_ore"
		var recipe_id := "bogiron_bar" if use_bogiron else "copper_bar"
		# Mine only the next small, state-driven batch.  This makes existing ore
		# surplus a first-class case and lets a double-ore result reduce later
		# gathering without inventing any material or XP in the driver.
		if material_count(ore_id) < 2:
			if panel != null:
				var batch_close := panel.find_child("CloseButton", true, false) as Button
				if batch_close != null:
					batch_close.pressed.emit()
					await get_tree().process_frame
					await get_tree().physics_frame
					await get_tree().process_frame
				panel = null
				if not await _d7_finish_fresh_hint("forge"):
					return false
			var requested := mini(8, 2 - material_count(ore_id) + 6)
			if not await _d7_training_harvest_town(ore_id, requested):
				break
			if use_bogiron:
				bogiron_nodes_requested += requested
			else:
				copper_nodes_requested += requested
			continue
		if panel == null:
			if not await _d6_scanner_interact(forge):
				_web_smoke_d7_fail("D7 training could not open Hod's physical forge.")
				break
			panel = _d7_find_craft_panel("forge")
		var row: Button = await _d7_training_forge_recipe_button(panel, recipe_id)
		if row == null:
			break
		var xp_before_craft := int((trades.get("earthcraft", {}) as Dictionary).get("xp", 0))
		row.pressed.emit()
		await get_tree().process_frame
		await get_tree().physics_frame
		await get_tree().process_frame
		var xp_after_craft := int((trades.get("earthcraft", {}) as Dictionary).get("xp", 0))
		if xp_after_craft <= xp_before_craft:
			no_progress += 1
			continue
		no_progress = 0
		crafted_count += 1
		if recipe_id == "copper_bar":
			copper_bars += 1
		else:
			bogiron_bars += 1
	var close := panel.find_child("CloseButton", true, false) as Button if panel != null else null
	if close != null:
		close.pressed.emit()
		# CraftPanel releases its modal and queues its recipe rows for deletion in
		# the close callback.  Let that production UI transaction settle before
		# immediately asking the player scanner to open the adjacent Table.
		await get_tree().process_frame
		await get_tree().physics_frame
		await get_tree().process_frame
	# CraftStation opens its first-use teaching page before it opens the Craft
	# Panel. Closing the latter releases only its own modal; finish the real
	# Forge DialogueShell too so the next Town scanner interaction has control.
	if not await _d7_finish_fresh_hint("forge"):
		return false
	var xp_after := int((trades.get("earthcraft", {}) as Dictionary).get("xp", 0))
	_web_smoke_d7_training["earthcraft_town_loop"] = {
		"from_level": Progression.level_for_xp(xp_before), "to_level": trade_lv("earthcraft"),
		"xp_before": xp_before, "xp_after": xp_after, "xp_delta": xp_after - xp_before,
		"copper_nodes_requested": copper_nodes_requested,
		"bogiron_nodes_requested": bogiron_nodes_requested,
		"copper_bars": copper_bars, "bogiron_bars": bogiron_bars,
		"forge_transactions": crafted_count, "no_progress": no_progress,
		"row_diagnostic": _web_smoke_d7_training.get("forge_row_diagnostic", {}),
		"elapsed_msec": Time.get_ticks_msec() - started_msec,
	}
	if crafted_count <= 0 or trade_lv("earthcraft") < target_level:
		_web_smoke_d7_fail("D7 training's physical Town forge loop stopped before Earthcraft %d (reached %d)." % [
			target_level, trade_lv("earthcraft")])
		return false
	_web_smoke_d7_training["forge_crafts"] = int(_web_smoke_d7_training.get("forge_crafts", 0)) + crafted_count
	web_smoke_features["d7_training_earthcraft_town_loop"] = true
	return true


func _d7_training_forge_recipe_button(panel: Node, recipe_id: String) -> Button:
	if panel == null:
		return null
	# Spec 59 split recipe choice from transaction commit: Recipe_* rows now
	# navigate the recipe book, while PrimaryCraftAction owns the actual craft.
	# Select the requested live row first, then return only the enabled primary
	# action. CraftPanel redraws its rows after every successful transaction, so
	# never retain a Recipe_* row across iterations.
	for _frame in 12:
		var selected := false
		for candidate_v in panel.find_children("Recipe_%s" % recipe_id, "", true, false):
			var candidate := candidate_v as Button
			if candidate != null and not candidate.is_queued_for_deletion() and not candidate.disabled:
				candidate.pressed.emit()
				selected = true
				break
		if selected:
			await get_tree().process_frame
			var primary := panel.find_child("PrimaryCraftAction", true, false) as Button
			if primary != null and not primary.is_queued_for_deletion() and not primary.disabled:
				return primary
		await get_tree().process_frame
	# A just-spent row can remain queued until the next idle turn. Ask the view
	# owner to rebuild from the live satchel, then repeat the same physical
	# select-row -> primary-action path (never call Game.craft directly).
	var owner := panel
	if owner.has_method("_render_recipe_index") and owner.has_method("_render_detail"):
		owner.call("_render_recipe_index")
		owner.call("_render_detail")
		await get_tree().process_frame
		for candidate_v in panel.find_children("Recipe_%s" % recipe_id, "", true, false):
			var candidate := candidate_v as Button
			if candidate != null and not candidate.is_queued_for_deletion() and not candidate.disabled:
				candidate.pressed.emit()
				await get_tree().process_frame
				var primary := panel.find_child("PrimaryCraftAction", true, false) as Button
				if primary != null and not primary.is_queued_for_deletion() and not primary.disabled:
					return primary
				break
	var rows: Array = []
	for node_v in panel.find_children("*", "", true, false):
		if node_v is Node and String((node_v as Node).name).begins_with("Recipe_"):
			var node := node_v as Node
			rows.append({"name": String(node.name), "class": node.get_class(),
				"queued": node.is_queued_for_deletion(),
				"disabled": (node as Button).disabled if node is Button else null})
	var box: Variant = owner.get("_recipe_box") if owner != null else null
	var primary := panel.find_child("PrimaryCraftAction", true, false) as Button
	_web_smoke_d7_training["forge_row_diagnostic"] = {"wanted": recipe_id, "rows": rows,
		"panel_parent": owner.get_class(),
		"panel_parent_name": String(owner.name),
		"station_id": String(owner.get("station_id")),
		"recipe_box_children": box.get_child_count() if box is Node else -1,
		"primary_found": primary != null,
		"primary_disabled": primary.disabled if primary != null else null}
	return null


# CraftPanel is now the transaction owner itself; `TransactionShell` belonged
# to the retired station layout and can also collide with first-use Dialog
# shells. Match the shipped CanvasLayer by script and station identity so D7
# presses only the real recipe Buttons even when a teaching page opened beside
# the station in the same input frame.
func _d7_find_craft_panel(station_id: String) -> Node:
	var scene := get_tree().current_scene
	if scene == null:
		return null
	for child_v in scene.get_children():
		var child := child_v as Node
		if child == null or not is_instance_valid(child) or child.is_queued_for_deletion():
			continue
		var script: Script = child.get_script()
		if script != null and script.resource_path == "res://scripts/ui/craft_panel.gd" \
				and String(child.get("station_id")) == station_id:
			return child
	return null


func _d7_drive_trade_training_world(owner_token: Dictionary = {}) -> void:
	if owner_token.is_empty():
		owner_token = _d7_current_world_owner_token("training_driver")
	if owner_token.is_empty():
		_web_smoke_d7_fail("D7 training World arrived without an owner token.")
		return
	var generation := int(owner_token.get("world_generation", -1))
	if bool(_web_smoke_d7_training.get("world_driver_active", false)) \
			and int(_web_smoke_d7_training.get("world_driver_generation", -1)) == generation:
		return
	_web_smoke_d7_training["world_driver_active"] = true
	_web_smoke_d7_training["world_driver_generation"] = generation
	await _d7_drive_trade_training_world_impl(owner_token)
	# A newer World can legitimately begin while an old coroutine unwinds after
	# its token is rejected.  Never let that old completion clear the newer
	# driver's ownership flag.
	if int(_web_smoke_d7_training.get("world_driver_generation", -1)) == generation:
		_web_smoke_d7_training["world_driver_active"] = false


func _d7_drive_trade_training_world_impl(owner_token: Dictionary = {}) -> void:
	if not web_smoke_d7_enabled or _web_smoke_d7_stage != "training_world":
		return
	if owner_token.is_empty():
		owner_token = _d7_current_world_owner_token("training_driver_impl")
	if not _d7_world_owner_valid(owner_token, "training_driver_entry"):
		return
	if String(active_chart.get("recipe_id", "")) != "green_hollow":
		_web_smoke_d7_fail("D7 training entered a World without its physical Green Hollow Chart.")
		return
	var player := local_player()
	if player == null:
		_web_smoke_d7_fail("D7 training had no World player.")
		return
	# A first affixed Chart can open Mara's reading lesson as the World becomes
	# interactive.  Finish only that exact fresh DialogueShell through its public
	# seam, then prove the offline modal has released before the scanner attempts
	# any gather, combat, or Far Waystone action.  No hint is pre-marked and no
	# unrelated World dialogue is touched.
	if not await _d7_finish_fresh_world_hint("affix_reading", owner_token):
		return
	var gathered := 0
	for node_v in get_tree().get_nodes_in_group("interactable"):
		if not node_v is Node3D or not node_v.has_method("interact") \
				or not node_v.has_method("is_used") or bool(node_v.call("is_used")):
			continue
		var node_kind = node_v.get("kind")
		if node_kind == null:
			continue
		var kind := String(node_kind)
		if kind not in ["ore_rock", "forage_node", "log_pile"]:
			continue
		node_v.set("_tier_channel", 0.01)
		var node_item = node_v.get("item_id")
		if node_item == null:
			continue
		var item_id := String(node_item)
		var before := material_count(item_id)
		var target := node_v as Node3D
		var scanner_completed := await _d7_scanner_harvest(target, item_id, 1200)
		if String(_web_smoke_d7_last_harvest_detail.get("outcome", "")) == "scanner_target_invalid":
			_d7_record_far_waystone_detail("scanner_target_invalid", target,
				local_player() as Node3D, {"during": "d7_scanner_harvest",
				"harvest_detail": _web_smoke_d7_last_harvest_detail.duplicate(true)})
			_web_smoke_d7_fail("D7 training lost its scanner target during a physical World harvest.")
			return
		# A combat status lesson can arrive while the scanner awaits this exact
		# gather. Settle only the authored status panels before a zero delta is
		# interpreted as a failed production interaction.
		if not await _d7_finish_pending_world_status_hints(owner_token):
			return
		var after := material_count(item_id)
		if after > before:
			gathered += 1
			# A truly fresh World can teach mining or chopping on this exact
			# production harvest.  It pauses the offline tree, so acknowledge only
			# that matching dialogue before the World driver damages the pack or
			# asks the Far Waystone to accept another scanner interaction.
			if not await _d7_finish_fresh_world_hint(kind, owner_token):
				return
		elif modal_count > 0 or get_tree().paused:
			_d7_record_far_waystone_detail("unexpected_world_modal", target,
				local_player() as Node3D, {"during": "d7_scanner_harvest",
				"expected_kind": kind, "expected_item": item_id,
				"scanner_completed": scanner_completed,
				"harvest_detail": _web_smoke_d7_last_harvest_detail.duplicate(true),
				"material": {"before": before, "after": after, "delta": after - before}})
			_web_smoke_d7_fail("D7 training scanner interaction opened an unexpected World modal before its target harvest settled.")
			return
	# A bad-twin Green Hollow can deliberately have no resource nodes.  It is
	# still a real Chart leg: complete its authored combat and return through
	# the Far Waystone.  Gather kinds accumulate across subsequent physical
	# Charts and are required before the training road can ever complete.
	var no_gather := gathered <= 0
	var kills := 0
	for foe in get_tree().get_nodes_in_group("enemy"):
		if foe != null and is_instance_valid(foe) and foe.has_method("take_damage") \
				and String(foe.get("role")) != "boss":
			foe.call("take_damage", int(foe.get("hp")) + 1, Vector3.ZERO)
			kills += 1
			await get_tree().process_frame
	if kills <= 0:
		_web_smoke_d7_fail("D7 training's generated World had no production Combatant damage target.")
		return
	# The Far Waystone helper repeats the narrow status check at its own scanner
	# boundary for delayed combat callbacks that arrive after this loop.
	# Leave the route marked as World-bound until the Far Waystone action has
	# actually succeeded.  Town's scene-ready hook therefore cannot start the
	# next lap between a no-gather kill and its physical return.
	if not await _d7_return_through_far_waystone(owner_token):
		return
	_web_smoke_d7_training["world_legs"] = int(_web_smoke_d7_training.get("world_legs", 0)) + 1
	if int(_web_smoke_d7_training.get("world_legs", 0)) > D7_TRAINING_WORLD_LEG_CAP:
		_web_smoke_d7_fail("D7 trade training exceeded its 60 physical World-leg contract.")
		return
	if no_gather:
		_web_smoke_d7_training["no_gather_legs"] = \
			int(_web_smoke_d7_training.get("no_gather_legs", 0)) + 1
		web_smoke_report("trade_training_no_gather")
	_web_smoke_d7_stage = "training_town"
	_d7_schedule_trade_training_continue()


func _d7_grind_town_wildcraft(target_level: int) -> bool:
	# Town patches are authored renewable GatherNodes. D7 only shortens their
	# channel/respawn dwell; every herb and every XP point still comes from interact →
	# channel completion → GatherNode's normal Game award callback.
	var player := local_player()
	if player == null:
		_web_smoke_d7_fail("The production Wildcraft grind had no Town player.")
		return false
	var attempts := 0
	var sweeps := 0
	var no_progress_sweeps := 0
	var deadline_msec := Time.get_ticks_msec() + 60000
	while trade_lv("wildcraft") < target_level and attempts < 240 \
			and no_progress_sweeps < 100 and Time.get_ticks_msec() < deadline_msec:
		sweeps += 1
		var progressed := false
		for node_v in get_tree().get_nodes_in_group("interactable"):
			var node_kind = node_v.get("kind") if node_v is Node3D else null
			var node_item = node_v.get("item_id") if node_v is Node3D else null
			if not node_v is Node3D or node_kind == null or node_item == null \
					or String(node_kind) != "forage_node" \
					or not node_v.has_method("is_used") or not node_v.has_method("interact"):
				continue
			if node_v.get("respawns") != true:
				continue
			node_v.set("respawn_sec", 0.05)
			node_v.set("_tier_channel", 0.01)
			if bool(node_v.call("is_used")):
				continue
			var item_id := String(node_item)
			var before := material_count(item_id)
			await _d7_scanner_harvest(node_v as Node3D, item_id, 2000)
			if material_count(item_id) > before:
				progressed = true
				attempts += 1
		if not progressed:
			no_progress_sweeps += 1
			await get_tree().create_timer(0.1, true).timeout
		else:
			no_progress_sweeps = 0
	if trade_lv("wildcraft") < target_level:
		_web_smoke_d7_fail("The real Town forage loop stopped after %d gathers / %d sweeps before Wildcraft %d (reached %d; no-progress=%d)." % [attempts, sweeps, target_level, trade_lv("wildcraft"), no_progress_sweeps])
		return false
	web_smoke_features["d7_prior_saga_production"] = true
	return true


func _d7_prepare_support_trades(targets: Dictionary, label: String) -> bool:
	# Support gates are earned entirely in the stable Town production loop. They
	# never borrow the Green practice Chart lane, whose completion XP would
	# corrupt D7's exact Wayfinding ledger.
	if targets.is_empty():
		_web_smoke_d7_fail("D7 %s has no mapped support requirements." % label)
		return false
	if targets.has("valid") and not bool(targets.get("valid", false)):
		_web_smoke_d7_fail("D7 %s has invalid mapped support requirements: %s." % [
			label, String(targets.get("reason", "unknown production-data defect"))])
		return false
	var scene := get_tree().current_scene
	if scene == null or scene.name != "Town" or get_tree().paused or modal_count != 0:
		_web_smoke_d7_fail("D7 %s support preparation requires stable Town control." % label)
		return false
	var wayfinding_before := int((trades.get("wayfinding", {}) as Dictionary).get("xp", 0))
	var charts_before := charts.duplicate(true)
	var before := {"earthcraft": trade_lv("earthcraft"),
		"wildcraft": trade_lv("wildcraft")}
	if trade_lv("wildcraft") < int(targets.get("wildcraft", 1)) \
			and not await _d7_grind_town_wildcraft(int(targets.get("wildcraft", 1))):
		return false
	if trade_lv("earthcraft") < int(targets.get("earthcraft", 1)) \
			and not await _d7_training_forge_copper(targets):
		return false
	var wayfinding_after := int((trades.get("wayfinding", {}) as Dictionary).get("xp", 0))
	if wayfinding_after != wayfinding_before or charts != charts_before:
		_web_smoke_d7_fail("D7 %s support preparation changed Wayfinding XP or the Chart case." % label)
		return false
	if trade_lv("wildcraft") < int(targets.get("wildcraft", 1)) \
			or trade_lv("earthcraft") < int(targets.get("earthcraft", 1)):
		_web_smoke_d7_fail("D7 %s support preparation stopped below its authored Trade gates." % label)
		return false
	var receipts: Array = web_smoke_features.get("d7_support_trade_receipts", [])
	receipts.append({"label": label, "targets": targets.duplicate(true),
		"before": before,
		"after": {"earthcraft": trade_lv("earthcraft"),
			"wildcraft": trade_lv("wildcraft")},
		"wayfinding_xp": wayfinding_after, "chart_count": charts.size()})
	web_smoke_features["d7_support_trade_receipts"] = receipts
	return true


func _d7_prepare_golden_boss_from_earned_state() -> void:
	var targets := _d7_progressive_training_targets("golden_wallow_boss")
	if not await _d7_prepare_support_trades(targets, "golden_wallow_boss"):
		return
	if not _d7_training_complete(targets):
		_d7_begin_trade_training("golden_wallow_boss", targets)
		return
	# The three Shallows layouts are allowed to roll no specific herb.  Once
	# Wildcraft 10 is earned, close the boss recipe's exact renewable gap at the
	# matching Town patches instead of treating a lucky World mothmint roll as a
	# hidden requirement of the Golden route.
	for herb_id in ["bittergrass", "mothmint"]:
		if material_count(herb_id) < 1 \
				and not await _d7_training_harvest_town(herb_id, 1):
			return
	if not await _d7_training_make_hedge_ink(
			_d7_hedge_runway("", 0, "golden_wallow_boss", {"mire_ink": 1})):
		return
	if not await _mix_d3_mire_ink():
		return
	web_smoke_report("mire_ink")
	await _inscribe_d3_boar_chart()


func _d7_prepare_seventh_boss_from_earned_state() -> void:
	var targets := _d7_progressive_training_targets("seventh_road_boss")
	if not await _d7_prepare_support_trades(targets, "seventh_road_boss"):
		return
	if not _d7_training_complete(targets):
		_d7_begin_trade_training("seventh_road_boss", targets)
		return
	if not await _d7_training_make_hedge_ink(
			_d7_hedge_runway("", 0, "seventh_road_boss", {"mothglow_ink": 1})):
		return
	if not await _mix_d4_mothglow_13_to_14():
		return
	await _inscribe_d4_wolf_chart()


func _d7_prepare_queen_boss_from_earned_state() -> void:
	var targets := _d7_progressive_training_targets("queens_summit_boss")
	if not await _d7_prepare_support_trades(targets, "queens_summit_boss"):
		return
	if not _d7_training_complete(targets):
		_d7_begin_trade_training("queens_summit_boss", targets)
		return
	if not _d7_record_queen_component_budget("boss_ready"):
		return
	await _inscribe_d5_queen_chart()


func _d7_prepare_pale_boss_from_earned_state() -> void:
	var targets := _d7_progressive_training_targets("pale_oath_boss")
	if not await _d7_prepare_support_trades(targets, "pale_oath_boss"):
		return
	if not _d7_training_complete(targets):
		_d7_begin_trade_training("pale_oath_boss", targets)
		return
	var archive := get_tree().current_scene.get_node_or_null("SkaldArchive")
	if archive == null or not await _d6_read_archive_source(archive as Node3D,
			"skald_pale_oath_boss"):
		return
	web_smoke_report("pale_oath_boss_folio")
	await _inscribe_d6_pale_oath_chart()


func _d7_begin_seventh_road_from_earned_state() -> void:
	if not CampaignData.chapter_cleared(campaign_state, CampaignData.GOLDEN_WALLOW):
		_web_smoke_d7_fail("The fresh marathon lost the production Golden Wallow settlement.")
		return
	var targets := _d7_progressive_training_targets("seventh_road")
	# Golden's run debrief is scheduled by the returning Town scene.  Do not
	# begin the next chapter's Atlas scanner while that authored modal still
	# owns the pause: Area3D physics can continue, but the prompt receipt cannot
	# be produced until Town control is genuinely released.
	await _wait_d7_town_control()
	if web_smoke_phase == "failed":
		return
	var town := get_tree().current_scene
	if town == null or town.name != "Town":
		_web_smoke_d7_fail("Golden Wallow handoff lost the stable Town scene before the Briar source.")
		return
	# Seventh Road is the first entry that needs Earthcraft 3. Prepare that
	# support Trade at this settled Town boundary before considering the legacy
	# Green practice route: a post-First-Knot Green has no authored clue and pays
	# generic Wayfinding XP, corrupting the exact campaign ledger on the way to
	# Fire.
	if not await _d7_prepare_support_trades(targets, "seventh_road"):
		return
	if not _d7_training_complete(targets):
		_d7_begin_trade_training("seventh_road", targets)
		return
	if not await _d7_ensure_cumulative_gather_proof_before_briar():
		return
	web_smoke_d4_enabled = true
	var atlas := town.get_node_or_null("AtlasDeepRumourSource") as Node3D
	if atlas == null or not await _d7_read_prior_saga_source(atlas, "atlas_briar_knot",
			"ChartRumourSourceDialog", "Briar"):
		return
	if not (chart_recipe_journal.rumours as Array).has("atlas_briar_knot") \
			or material_count("thorn_rubbing") != 1 \
			or material_count("stitched_parchment") != 1 \
			or material_count("briar_knot") != 1:
		_web_smoke_d7_fail("The Briar source did not grant its missing-only lesson kit.")
		return
	web_smoke_report("seventh_source")
	var hedge_runway := _d7_hedge_runway("briar_maze", 4,
		"seventh_road_boss")
	if not await _d7_training_make_hedge_ink(hedge_runway):
		return
	web_smoke_features["d7_seventh_renewable_ink"] = true
	_web_smoke_d4_stage = "briar_1"
	await _inscribe_d4_briar()


func _d7_sell_banked_boss_item_at_hod() -> bool:
	if _web_smoke_d7_sale_item.is_empty() or inventory == null:
		_web_smoke_d7_fail("The Queen handoff had no physically banked Wolf boss item for Hod.")
		return false
	var token := String(_web_smoke_d7_sale_item.get("_d7_sale_token", ""))
	var matches: Array = inventory.items.filter(func(raw):
		return raw is Dictionary and String((raw as Dictionary).get(
			"_d7_sale_token", "")) == token)
	if token == "" or matches.size() != 1:
		_web_smoke_d7_fail("The exact Wolf boss pickup did not persist into Town's shared Pack.")
		return false
	var sale_item: Dictionary = matches[0]
	var expected_value := EconomyData.sell_value(sale_item)
	if expected_value <= 0 or String(sale_item.get("rarity", "")) not in ["rare", "unique"]:
		_web_smoke_d7_fail("The banked Wolf item was not the guaranteed sellable rare+ economy proof.")
		return false
	var immutable_before := {
		"wayfinding_xp": int((trades.get("wayfinding", {}) as Dictionary).get("xp", 0)),
		"campaign": CampaignData.normalize_campaign_state(campaign_state),
		"source_unlocks": chart_source_unlocks.duplicate(),
		"recipe_journal": chart_recipe_journal.duplicate(true),
		"known_recipes": known_chart_recipes.duplicate(),
		"charts": charts.duplicate(true),
	}
	var gold_before := gold
	var inventory_before := inventory.items.size()
	var town := get_tree().current_scene
	var player := local_player() as Node3D
	var hod: Node3D = null
	for node_v in get_tree().get_nodes_in_group("interactable"):
		if node_v is Node3D and node_v.has_method("get_prompt_text") \
				and String(node_v.call("get_prompt_text")) == "[E] Trade with Old Hod":
			hod = node_v as Node3D
			break
	if town == null or town.name != "Town" or player == null or hod == null:
		_web_smoke_d7_fail("The earned-economy route could not find Old Hod's physical Town counter.")
		return false
	var scan := await _d7_find_strict_target_position(player, hod, player.global_position)
	if not bool(scan.get("found", false)) \
			or not await _d7_press_interact_for_target(player, hod):
		_web_smoke_d7_fail("The player scanner could not open Old Hod's physical counter.")
		return false
	await get_tree().process_frame
	# A fresh save receives Hod's two-page introduction first. Its production
	# finished signal opens the same VendorPanel used on later visits.
	var hod_dialog: Node = null
	for child in town.get_children():
		if child.has_node("DialogueShell") and child.has_method("_finish") \
				and "Hod" in String(child.get("_speaker")):
			hod_dialog = child
			break
	if hod_dialog != null:
		hod_dialog.call("_finish")
		await get_tree().process_frame
		await get_tree().process_frame
	var vendor: Node = null
	for child in town.get_children():
		if child is CanvasLayer and child.has_node("TransactionShell") \
				and child.find_child("SellSourcePanel", true, false) != null:
			vendor = child
			break
	if vendor == null:
		_web_smoke_d7_fail("Old Hod's real Sell panel did not open after the scanner interaction.")
		return false
	var sell_row: Button = null
	for row_v in vendor.find_children("SellRow*", "Button", true, false):
		var bound = row_v.get_meta("inventory_item", null)
		if bound is Dictionary and String((bound as Dictionary).get(
				"_d7_sale_token", "")) == token:
			if sell_row != null:
				vendor.call("_close")
				_web_smoke_d7_fail("Hod exposed the same Wolf item in more than one sell row.")
				return false
			sell_row = row_v as Button
	if sell_row == null or sell_row.disabled:
		vendor.call("_close")
		_web_smoke_d7_fail("Hod's visible Pack list did not expose the exact carried Wolf item.")
		return false
	# The row's callback re-renders the panel synchronously and queues this exact
	# Button for deletion. Retain only immutable evidence before activating it.
	var sell_row_name := String(sell_row.name)
	sell_row.pressed.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	var remaining: Array = inventory.items.filter(func(raw):
		return raw is Dictionary and String((raw as Dictionary).get(
			"_d7_sale_token", "")) == token)
	var immutable_after := {
		"wayfinding_xp": int((trades.get("wayfinding", {}) as Dictionary).get("xp", 0)),
		"campaign": CampaignData.normalize_campaign_state(campaign_state),
		"source_unlocks": chart_source_unlocks.duplicate(),
		"recipe_journal": chart_recipe_journal.duplicate(true),
		"known_recipes": known_chart_recipes.duplicate(),
		"charts": charts.duplicate(true),
	}
	var duplicate_row := false
	for row_v in vendor.find_children("SellRow*", "Button", true, false):
		var bound = row_v.get_meta("inventory_item", null)
		if bound is Dictionary and String((bound as Dictionary).get(
				"_d7_sale_token", "")) == token:
			duplicate_row = true
			break
	vendor.call("_close")
	await get_tree().process_frame
	if not remaining.is_empty() or duplicate_row \
			or inventory.items.size() != inventory_before - 1 \
			or gold != gold_before + expected_value \
			or immutable_after != immutable_before:
		_web_smoke_d7_fail("Hod's exact sell row did not settle one immutable production sale.")
		return false
	var receipt := {
		"token": token,
		"kind_id": String(sale_item.get("kind_id", "")),
		"name": String(sale_item.get("name", "")),
		"rarity": String(sale_item.get("rarity", "")),
		"expected_value": expected_value,
		"actual_value": gold - gold_before,
		"gold_before": gold_before,
		"gold_after": gold,
		"inventory_before": inventory_before,
		"inventory_after": inventory.items.size(),
		"persisted_to_town": true,
		"exact_row": sell_row_name,
		"second_sale_possible": duplicate_row,
		"immutable_state_unchanged": true,
	}
	web_smoke_features["d7_wolf_hod_sale_receipt"] = receipt
	web_smoke_features["d7_real_boss_loot_hod_economy"] = true
	_web_smoke_d7_sale_item = {}
	return true


func _d7_record_queen_component_budget(phase: String = "chapter_start") -> bool:
	var legs := [["summit_approach", 4], ["queens_summit_boss", 1]] \
		if phase == "chapter_start" else [["queens_summit_boss", 1]]
	var required := {}
	for leg_v in legs:
		var leg: Array = leg_v
		var recipe: Dictionary = ChartsData.CHART_RECIPES.get(String(leg[0]), {})
		for component_v in (recipe.get("pattern", {}) as Dictionary).values():
			var component_id := String(component_v)
			if ChartsData.component_supply_price(component_id) > 0:
				required[component_id] = int(required.get(component_id, 0)) + int(leg[1])
	var stock := {}
	var purchases := {}
	var purchase_cost := 0
	for component_v in required:
		var component_id := String(component_v)
		var have := material_count(component_id)
		var count := maxi(0, int(required[component_v]) - have)
		var price := ChartsData.component_supply_price(component_id)
		stock[component_id] = have
		purchases[component_id] = {"count": count, "unit_price": price,
			"cost": count * price}
		purchase_cost += count * price
	var guaranteed_income := 4 * ChartsData.completion_gold({"tier": 3}) \
		if phase == "chapter_start" else 0
	var affordable := gold + guaranteed_income >= purchase_cost
	var receipt: Dictionary = (web_smoke_features.get(
		"d7_queen_component_budget", {}) as Dictionary).duplicate(true)
	receipt[phase] = {
		"gold": gold,
		"required": required,
		"stock": stock,
		"remaining_purchases": purchases,
		"purchase_cost": purchase_cost,
		"guaranteed_approach_income": guaranteed_income,
		"available_through_boss": gold + guaranteed_income,
		"affordable": affordable,
	}
	web_smoke_features["d7_queen_component_budget"] = receipt
	if not affordable:
		_web_smoke_d7_fail("The earned Wolf sale and Crownward purses did not fund the remaining authored components: %s." % receipt[phase])
		return false
	return true


func _d7_begin_queens_summit_from_earned_state() -> void:
	if not CampaignData.chapter_cleared(campaign_state, CampaignData.SEVENTH_ROAD):
		_web_smoke_d7_fail("The fresh marathon lost the production Seventh Road settlement.")
		return
	var targets := _d7_progressive_training_targets("queens_summit")
	# The Wolf return can still be presenting its real debrief when this deferred
	# handoff starts.  Let that exact owner release input before scanner-reading
	# the restored Archive.
	await _wait_d7_town_control()
	if web_smoke_phase == "failed":
		return
	var town := get_tree().current_scene
	if town == null or town.name != "Town":
		_web_smoke_d7_fail("Seventh Road handoff lost the stable Town scene before the Archive source.")
		return
	if not await _d7_sell_banked_boss_item_at_hod():
		return
	if not await _d7_prepare_support_trades(targets, "queens_summit"):
		return
	if not _d7_training_complete(targets):
		_d7_begin_trade_training("queens_summit", targets)
		return
	web_smoke_d5_enabled = true
	var archive := town.get_node_or_null("SkaldArchive") as Node3D
	if archive == null or not await _d7_read_prior_saga_source(archive,
			"skald_queens_summit", "SkaldArchiveDialog", "Queen's Summit"):
		return
	if material_count("cold_track") != 2 or material_count("atlas_folio") != 1 \
			or material_count("climbing_cord") != 2:
		_web_smoke_d7_fail("The real Archive did not grant the Crownward lesson kit.")
		return
	web_smoke_report("queens_source")
	var hedge_runway := _d7_hedge_runway("summit_approach", 4,
		"queens_summit_boss", {"refined_ink": 5})
	if not await _d7_training_make_hedge_ink(hedge_runway) \
			or not await _d7_mix_ink_to_count("refined_ink", 5):
		return
	if not _d7_record_queen_component_budget():
		return
	web_smoke_features["d7_queen_renewable_ink"] = true
	_web_smoke_d5_stage = "approach_1"
	await _inscribe_d5_approach()


func _d7_begin_pale_oath_from_earned_state() -> void:
	if not CampaignData.chapter_cleared(campaign_state, CampaignData.QUEENS_SUMMIT):
		_web_smoke_d7_fail("The fresh marathon lost the production Queen's Summit settlement.")
		return
	var targets := _d7_progressive_training_targets("pale_oath")
	# The Queen settlement and its run debrief share Town's modal lifecycle with
	# the Archive source.  Keep the source action behind the same D7 control
	# boundary used for the earlier Golden/Deep-Hollow handoff.
	await _wait_d7_town_control()
	if web_smoke_phase == "failed":
		return
	var town := get_tree().current_scene
	if town == null or town.name != "Town":
		_web_smoke_d7_fail("Queen's Summit handoff lost the stable Town scene before the Archive source.")
		return
	if not await _d7_prepare_support_trades(targets, "pale_oath"):
		return
	if not _d7_training_complete(targets):
		_d7_begin_trade_training("pale_oath", targets)
		return
	web_smoke_d6_enabled = true
	var archive := town.get_node_or_null("SkaldArchive") as Node3D
	if archive == null or not await _d7_read_prior_saga_source(archive,
			"skald_pale_oath", "SkaldArchiveDialog", "Pale Oath"):
		return
	if not (chart_recipe_journal.rumours as Array).has("skald_pale_oath") \
			or material_count("pale_wellmark") != 1 or material_count("atlas_folio") != 1 \
			or material_count("climbing_cord") != 2 or material_count("stoneground_ink") < 1:
		_web_smoke_d7_fail("The real Archive did not grant the Pale Oath missing-only lesson kit.")
		return
	web_smoke_report("pale_source")
	var hedge_runway := _d7_hedge_runway("pale_veins", 4,
		"pale_oath_boss")
	if not await _d7_training_make_hedge_ink(hedge_runway) \
			or not await _d7_mix_ink_to_count("stoneground_ink", 5):
		return
	web_smoke_features["d7_pale_renewable_ink"] = true
	_web_smoke_d6_stage = "veins_1"
	await _inscribe_d6_pale_veins()


func _d7_harvest_world_then_return(owner_token: Dictionary = {}) -> void:
	# Harvesting uses each spawned production node's normal interaction and wait;
	# it never grants an item or Trade XP directly. This is the marathon's only
	# acceleration over ordinary play before it asks the real Far Waystone home.
	# A scene may have been intentionally torn down by a focused native probe
	# after it observed the dispatcher handoff. Do not turn that explicit driver
	# shutdown into a late, unrelated World failure.
	if not web_smoke_d7_enabled or web_smoke_phase == "failed":
		return
	if owner_token.is_empty():
		owner_token = _d7_current_world_owner_token("prior_saga_harvest")
	if not _d7_world_owner_valid(owner_token, "prior_saga_harvest_entry"):
		return
	var player := local_player()
	if player == null:
		_web_smoke_d7_fail("The fresh marathon had no player for World harvesting.")
		return
	# The first affixed Sallow World may still be presenting Mara's authored
	# reading lesson when the scene-ready dispatcher arrives. Let that actual
	# dialogue settle before a scanner press; otherwise the paused World quite
	# correctly rejects a production gather.
	if not await _d7_finish_fresh_world_hint("affix_reading", owner_token):
		return
	player = local_player()
	if player == null or not is_instance_valid(player) \
			or bool(player.get("dead")) or int(player.get("hp")) <= 0:
		_web_smoke_d7_fail("The prior-saga World reached combat preparation with a dead player.")
		return
	var golden_deep_world := _web_smoke_d7_stage == "golden_deep_hollow_world" \
		and String(active_chart.get("recipe_id", "")) == "deep_hollow"
	if golden_deep_world:
		web_smoke_report("deep_world")
		web_smoke_report("golden_deep_world")
	# Clear the ordinary pack before the first gather approach. These are the
	# same released Combatant damage/death callbacks used by normal combat, so
	# Huntcraft XP remains production-owned; D7 never writes it directly.
	var kills := 0
	for foe in get_tree().get_nodes_in_group("enemy"):
		if foe != null and is_instance_valid(foe) and foe.has_method("take_damage") \
				and String(foe.get("role")) != "boss":
			foe.call("take_damage", int(foe.get("hp")) + 1, Vector3.ZERO)
			kills += 1
	if kills <= 0:
		_web_smoke_d7_fail("The authored ordinary prior-saga World had no production Combatant targets before gathering.")
		return
	# Death callbacks, queued frees, navigation, and any already-scheduled attack
	# must all settle before a channel can begin. This prevents a dead pack's
	# final attack from interrupting the first scanner gather one frame later.
	await get_tree().process_frame
	await get_tree().physics_frame
	await get_tree().process_frame
	await get_tree().physics_frame
	await get_tree().process_frame
	if not _d7_world_owner_valid(owner_token, "prior_saga_combat_settled"):
		return
	player = local_player()
	if player == null or not is_instance_valid(player) \
			or bool(player.get("dead")) or int(player.get("hp")) <= 0:
		_web_smoke_d7_fail("The prior-saga player died before the post-combat gather approach.")
		return
	var combat_receipts: Array = (web_smoke_features.get(
		"d7_prior_saga_combat_gather_receipts", []) as Array).duplicate(true)
	var combat_receipt := {
		"stage": _web_smoke_d7_stage,
		"recipe_id": String(active_chart.get("recipe_id", "")),
		"world_generation": _web_smoke_d7_world_generation,
		"kills": kills,
		"kill_passes": 1,
		"events": ["combat_clear"],
		"settled_before_gather": true,
	}
	combat_receipts.append(combat_receipt)
	web_smoke_features["d7_prior_saga_combat_gather_receipts"] = combat_receipts
	web_smoke_features["d7_prior_saga_combat_before_gather"] = true
	var harvested := 0
	var gather_candidates := 0
	var eligible_candidates := 0
	var locked_candidates := 0
	var candidate_manifest: Array = []
	var eligible_nodes: Array = []
	var locked_nodes: Array = []
	for node_v in get_tree().get_nodes_in_group("interactable"):
		var node_kind = node_v.get("kind") if node_v is Node3D else null
		var node_item = node_v.get("item_id") if node_v is Node3D else null
		if not node_v is Node3D or node_kind == null or node_item == null \
				or String(node_kind) not in ["forage_node", "ore_rock", "log_pile"] \
			or not node_v.has_method("is_used") or not node_v.has_method("interact") \
			or bool(node_v.call("is_used")):
			continue
		gather_candidates += 1
		var item_id := String(node_item)
		var target_snapshot := _d7_interactable_snapshot(node_v)
		var candidate_locked := bool(target_snapshot.get("locked", false))
		var candidate := {"node": node_v, "item_id": item_id,
			"candidate_index": gather_candidates - 1, "snapshot": target_snapshot,
			"locked": candidate_locked}
		candidate_manifest.append({"candidate_index": gather_candidates - 1,
			"locked": candidate_locked, "eligible": not candidate_locked,
			"target": target_snapshot})
		if candidate_locked:
			locked_candidates += 1
			locked_nodes.append(candidate)
		else:
			eligible_candidates += 1
			eligible_nodes.append(candidate)
	# Evidence needs one completed channel, not every optional vein in the map.
	# Prefer eligible nodes and stop after the first success. If a malformed
	# World has only locked candidates, send one real E edge for its exact gate
	# receipt; the manifest above preserves every other visible candidate without
	# paying a wall-time channel timeout for each.
	var attempt_nodes: Array = eligible_nodes
	var required_item := _d7_required_harvest_item()
	if required_item != "":
		var required_nodes: Array = []
		var other_nodes: Array = []
		for candidate_v in eligible_nodes:
			var candidate: Dictionary = candidate_v
			if String(candidate.get("item_id", "")) == required_item:
				required_nodes.append(candidate)
			else:
				other_nodes.append(candidate)
		attempt_nodes = required_nodes + other_nodes
	if attempt_nodes.is_empty() and not locked_nodes.is_empty():
		attempt_nodes = [locked_nodes[0]]
	for candidate_v in attempt_nodes:
		var candidate: Dictionary = candidate_v
		var node := candidate.node as Node3D
		var item_id := String(candidate.item_id)
		var before := material_count(item_id)
		if node == null or not is_instance_valid(node):
			continue
		var completed := await _d7_scanner_harvest(node, item_id, 3000)
		var attempt: Dictionary = _web_smoke_d7_last_harvest_detail.duplicate(true)
		attempt["attempt_index"] = _web_smoke_d7_harvest_attempts.size()
		attempt["stage"] = _web_smoke_d7_stage
		attempt["recipe_id"] = String(active_chart.get("recipe_id", ""))
		attempt["world_generation"] = _web_smoke_d7_world_generation
		attempt["candidate_index"] = int(candidate.candidate_index)
		attempt["candidate_locked"] = bool(candidate.locked)
		attempt["candidate_eligible"] = not bool(candidate.locked)
		attempt["target_before_attempt"] = candidate.snapshot
		attempt["scanner_returned_completed"] = completed
		_web_smoke_d7_harvest_attempts.append(attempt)
		web_smoke_features["d7_prior_saga_harvest_attempts"] = \
			_web_smoke_d7_harvest_attempts.duplicate(true)
		if not _d7_world_owner_valid(owner_token, "prior_saga_harvest_after_scanner"):
			return
		if completed and material_count(item_id) > before:
			harvested += 1
		if modal_count > 0:
			for child in get_tree().current_scene.get_children():
				if child.has_method("_finish") and child.has_node("DialogueShell"):
					child.call("_finish")
					break
			await get_tree().process_frame
		if harvested > 0:
			break
	combat_receipt["gather_candidates"] = gather_candidates
	combat_receipt["eligible_candidates"] = eligible_candidates
	combat_receipt["locked_candidates"] = locked_candidates
	combat_receipt["candidate_manifest"] = candidate_manifest
	combat_receipt["harvested"] = harvested
	if gather_candidates > 0:
		(combat_receipt.events as Array).append("gather_scan")
	combat_receipts[combat_receipts.size() - 1] = combat_receipt
	web_smoke_features["d7_prior_saga_combat_gather_receipts"] = combat_receipts
	# Sallow Shallows carries guaranteed visible Mothmint. Only the separately
	# tracked Deep-Hollow handoff may bypass this prior-saga gather requirement.
	var authored_no_gather_route := golden_deep_world
	var cfg := run_cfg()
	if harvested == 0 and gather_candidates > 0 and not authored_no_gather_route:
		if eligible_candidates == 0:
			_web_smoke_d7_fail(("The authored World exposed %d GatherNodes, but every one " \
				+ "was locked above its earned Trade gate.") % gather_candidates)
			return
		_web_smoke_d7_fail(("The fresh marathon completed none of its %d eligible " \
			+ "production gathering attempts.") % eligible_candidates)
		return
	if harvested == 0 and not authored_no_gather_route:
		var evidence := D7PriorSagaHarvestEvidence.evaluate(cfg, gather_candidates,
			harvested, _web_smoke_d7_training_seen_kinds)
		if not bool(evidence.get("valid", false)):
			if String(evidence.get("reason", "")) == "missing_cumulative_gather_proof":
				_web_smoke_d7_fail("An authored empty Briar arrived before D7 had cumulative production gathering proof.")
				return
			_web_smoke_d7_fail("The fresh marathon found no completed production gathering in its authored World.")
			return
		# Do not overwrite a Boolean witness: every legitimate empty Briar gets
		# an auditable receipt, while the all-three-kinds invariant remains owned
		# by the real scanner-driven Green-Hollow training road.
		_web_smoke_d7_prior_saga_no_gather_legs = \
			D7PriorSagaHarvestEvidence.append_authored_empty_briar_receipt(
				_web_smoke_d7_prior_saga_no_gather_legs, active_chart, cfg,
				gather_candidates, harvested)
		web_smoke_features["d7_prior_saga_authored_no_gather"] = \
			_web_smoke_d7_prior_saga_no_gather_legs.duplicate(true)
		web_smoke_report("prior_saga_authored_no_gather")
	web_smoke_features["d7_prior_saga_production"] = true
	_d7_schedule_far_waystone_return(0.25, "prior_saga_harvest", owner_token)


func _d7_required_harvest_item() -> String:
	# The Fire chapter promises these nodes in every generated Ashen road. The
	# release driver completes one real production channel per road, so choose
	# the next missing ritual input instead of depending on scene-tree order.
	# Existing bars count as two ore apiece: returning players should only mine
	# the renewable Wildgold still needed for the two post-clear Forge rows.
	# Normal players remain free to gather any or every visible node.
	if String(active_chart.get("recipe_id", "")) != "ashen_bough":
		return ""
	if material_count("embersage") < 2:
		return "embersage"
	if material_count("wellwater") < 1:
		return "wellwater"
	var wildgold_equivalent := material_count("wildgold_ore") \
		+ material_count("wildgold_bar") * 2
	if wildgold_equivalent < 4:
		return "wildgold_ore"
	return ""


func _d7_record_cumulative_gather_proof(kind: String, item_id: String,
		provenance: String, material_before: int, material_after: int) -> void:
	if kind not in D7PriorSagaHarvestEvidence.REQUIRED_SCANNER_KINDS \
			or material_after <= material_before:
		return
	var already_seen := bool(_web_smoke_d7_training_seen_kinds.get(kind, false))
	_web_smoke_d7_training_seen_kinds[kind] = true
	# The witness is monotonic; retain the first real production interaction for
	# each family instead of growing browser telemetry on every renewable gather.
	var receipt: Dictionary = (web_smoke_features.get(
		"d7_cumulative_gather_proof", {}) as Dictionary).duplicate(true)
	var witnesses: Dictionary = (receipt.get("first_witness_by_kind", {}) as Dictionary).duplicate(true)
	if not already_seen and not witnesses.has(kind):
		witnesses[kind] = {
			"kind": kind, "item_id": item_id, "provenance": provenance,
			"material_before": material_before, "material_after": material_after,
			"delta": material_after - material_before,
			"stage": _web_smoke_d7_stage,
			"world_generation": _web_smoke_d7_world_generation,
		}
	receipt["first_witness_by_kind"] = witnesses
	receipt["seen_kinds"] = _web_smoke_d7_training_seen_kinds.duplicate(true)
	receipt["complete"] = D7PriorSagaHarvestEvidence.has_cumulative_scanner_gather_proof(
		_web_smoke_d7_training_seen_kinds)
	web_smoke_features["d7_cumulative_gather_proof"] = receipt


func _d7_ensure_cumulative_gather_proof_before_briar() -> bool:
	# Exact authored Wayfinding removed the old generic practice detour. Keep
	# the empty-Briar proof tied to production: reuse prior witnesses, then make
	# one bounded Town scanner gather only for each family still missing.
	var sources := [
		{"kind": "ore_rock", "item_id": "copper_ore"},
		{"kind": "forage_node", "item_id": "wild_herb"},
		{"kind": "log_pile", "item_id": "logs"},
	]
	var missing_before: Array = []
	for source_v in sources:
		var source: Dictionary = source_v
		var kind := String(source.kind)
		if bool(_web_smoke_d7_training_seen_kinds.get(kind, false)):
			continue
		missing_before.append(kind)
		var item_id := String(source.item_id)
		var before := material_count(item_id)
		if not await _d7_training_harvest_town(item_id, 1):
			return false
		# `_d7_training_harvest_town` owns the scanner/material transaction and
		# normally records this witness. Reassert through the same positive-delta
		# adapter so the boundary fails closed if that writer ever regresses.
		_d7_record_cumulative_gather_proof(kind, item_id,
			"seventh_road_town_scanner", before, material_count(item_id))
		if not bool(_web_smoke_d7_training_seen_kinds.get(kind, false)):
			_web_smoke_d7_fail("The Seventh Road Town gather did not prove %s before Briar." % kind)
			return false
	var receipt: Dictionary = (web_smoke_features.get(
		"d7_cumulative_gather_proof", {}) as Dictionary).duplicate(true)
	receipt["boundary"] = "before_first_briar"
	receipt["missing_before_boundary"] = missing_before
	receipt["seen_kinds"] = _web_smoke_d7_training_seen_kinds.duplicate(true)
	receipt["complete"] = D7PriorSagaHarvestEvidence.has_cumulative_scanner_gather_proof(
		_web_smoke_d7_training_seen_kinds)
	web_smoke_features["d7_cumulative_gather_proof"] = receipt
	if not bool(receipt.complete):
		_web_smoke_d7_fail("The Seventh Road began without cumulative production gathering proof.")
		return false
	return true


func _d7_read_lift_folio(lift: Node3D, source_id: String, ordinary: bool = false) -> bool:
	if lift == null or not await _d6_scanner_interact(lift):
		return false
	var dialog := get_tree().get_first_node_in_group("RootroadLiftDialog")
	if dialog == null or not dialog.has_method("_finish"):
		_web_smoke_d7_fail("The physical Rootroad Lift did not open its production folio dialog.")
		return false
	dialog.call("_finish")
	# Fire's Lift sources grant their recipe immediately, so the authoritative
	# post-close status is `resolved` (unlike a rumour-only source's `read`).
	# Wait for the dialog's finished callback to transact, then prove both the
	# resolved source and its authored source-lesson provenance.
	var deadline := Time.get_ticks_msec() + 3000
	var status := chart_source_status(source_id)
	while Time.get_ticks_msec() < deadline and String(status.get("state", "")) == "eligible":
		await get_tree().process_frame
		status = chart_source_status(source_id)
	var recipe_id := String(status.get("recipe_id", ""))
	var discoveries: Dictionary = chart_recipe_journal.get("discoveries", {})
	if String(status.get("state", "")) != "resolved" \
			or recipe_id == "" or not chart_recipe_known(recipe_id) \
			or String(discoveries.get(recipe_id, "")) != "source_lesson":
		_web_smoke_d7_fail("The Rootroad Lift did not commit its %s source transaction." % source_id)
		return false
	if ordinary:
		var landing: Dictionary = lift.call("lower_landing_state") if lift.has_method("lower_landing_state") else {}
		if not bool(landing.get("lowered", false)) or not chart_recipe_known("ashen_bough"):
			_web_smoke_d7_fail("The ordinary Lift folio did not teach Ashen Bough and lower its landing.")
			return false
	return true


func _continue_d7_web_smoke() -> void:
	if not web_smoke_d7_enabled or web_smoke_phase == "failed":
		return
	await _wait_d7_town_control()
	if web_smoke_phase == "failed":
		return
	if _web_smoke_d7_ashen_ids.size() < 5:
		_web_smoke_d7_stage = "ashen_%d" % (_web_smoke_d7_ashen_ids.size() + 1)
		await _inscribe_d7_ashen_bough()
		return
	if _web_smoke_d7_verse_ids != CampaignData.FIRE_IN_THE_BOUGH_CLUES \
			or CampaignData.chapter_clue_count(campaign_state, CampaignData.FIRE_IN_THE_BOUGH) != 5:
		_web_smoke_d7_fail("Five physical Ashen Bough returns did not bank the Ember Verse ledger.")
		return
	web_smoke_features["d7_five_ashen_bough_loops"] = true
	web_smoke_features["d7_five_distinct_ember_verses"] = true
	if trade_lv("huntcraft") < 21 \
			or not bool(web_smoke_features.get("d7_pack_reader_zero_rng_manifest", false)):
		_web_smoke_d7_fail("Five Ashen returns did not earn and reveal Pack Reader through real combat.")
		return
	if not _d7_require_exact_wayfinding_xp(
			"five_ember_verses", D7_FIRE_FIVE_VERSE_WAYFINDING_XP):
		return
	# Fire entry already prepared every support gate implied by its generated
	# World. Keep this late boundary as an assertion, never a hidden post-loop
	# grind that changes when the chapter becomes playable.
	var fire_requirements := ChartsData.recipe_production_requirements(
		"fire_in_the_bough_boss")
	if not bool(fire_requirements.get("valid", false)) \
			or trade_lv("earthcraft") < int(fire_requirements.get("earthcraft", 23)) \
			or trade_lv("wildcraft") < int(fire_requirements.get("wildcraft", 23)):
		_web_smoke_d7_fail("Fire boss support gates were not already satisfied at chapter entry.")
		return
	if material_count("embersage") < 2 or material_count("wellwater") < 1:
		_web_smoke_d7_fail("Five real Ashen harvests did not bank Emberleaf's 2 Embersage + 1 Wellwater inputs.")
		return
	var lift := get_tree().current_scene.get_node_or_null("RootroadLift") as Node3D
	if lift == null or not await _d7_read_lift_folio(lift, "rootroad_lift_hearth_giant"):
		return
	web_smoke_features["d7_real_lift_boss_folio"] = true
	web_smoke_report("lift_giant_folio")
	if not await _d7_mix_emberleaf_ink():
		return
	web_smoke_features["d7_real_emberleaf_mix"] = true
	web_smoke_report("emberleaf_mix")
	await _inscribe_d7_fire_boss_chart()


func _inscribe_d7_ashen_bough() -> void:
	var chart := await _d7_table_inscribe("ashen_bough", ["ash_mark", "cinder_waymark",
		"ember_mark", "cinder_binding", "ember_folio", "ash_ink"],
		"ashen_table_%d" % (_web_smoke_d7_ashen_ids.size() + 1))
	if chart.is_empty():
		return
	var chart_id := String(chart.get("chart_instance_id", ""))
	if chart_id == "" or _web_smoke_d7_ashen_ids.has(chart_id):
		_web_smoke_d7_fail("Ashen Bough did not mint a distinct physical Chart.")
		return
	_web_smoke_d7_ashen_ids.append(chart_id)
	if not await _d7_socket_chart_at_town(chart):
		return


func _drive_d7_ashen_world(owner_token: Dictionary = {}) -> void:
	if owner_token.is_empty():
		owner_token = _d7_current_world_owner_token("ashen_world")
	if not _d7_world_owner_valid(owner_token, "ashen_world_entry"):
		return
	var index := _web_smoke_d7_ashen_ids.size() - 1
	var clue: Dictionary = run_cfg().get("campaign_clue", {})
	var expected := String(CampaignData.FIRE_IN_THE_BOUGH_CLUES[index]) \
		if index >= 0 and index < CampaignData.FIRE_IN_THE_BOUGH_CLUES.size() else ""
	var manifest = run_cfg().get("elite_manifest", {})
	if String(clue.get("clue_id", "")) != expected \
			or String(clue.get("presentation", "")) != "ember_verse" \
			or String(run_cfg().get("boss_kind", "")) != "" \
			or not manifest is Dictionary or not bool((manifest as Dictionary).get("eligible", false)):
		_web_smoke_d7_fail("An Ashen Bough World did not carry its authored Verse and frozen elite manifest.")
		return
	if _web_smoke_d7_manifest.is_empty():
		_web_smoke_d7_manifest = (manifest as Dictionary).duplicate(true)
	if not _d7_observe_pack_reader_manifest(manifest as Dictionary,
			_web_smoke_d7_ashen_ids.size()):
		return
	_web_smoke_d7_verse_ids.append(expected)
	web_smoke_features["d7_frozen_elite_manifest"] = true
	web_smoke_report("ashen_world_%d" % _web_smoke_d7_ashen_ids.size())
	_d7_harvest_world_then_return.bind(owner_token).call_deferred()


func _d7_observe_pack_reader_manifest(manifest: Dictionary,
		world_index: int) -> bool:
	var receipt: Dictionary = (web_smoke_features.get(
		"d7_pack_reader_deferred_reveal", {}) as Dictionary).duplicate(true)
	var reader: Dictionary = pack_reader_view()
	var plate := get_tree().get_first_node_in_group("pack_reader_manifest")
	if trade_lv("huntcraft") < 21:
		if bool(reader.get("available", false)) or plate != null:
			_web_smoke_d7_fail("Pack Reader appeared before Huntcraft 21.")
			return false
		var deferred_worlds: Array = receipt.get("deferred_worlds", [])
		if not deferred_worlds.has(world_index):
			deferred_worlds.append(world_index)
		receipt["deferred_worlds"] = deferred_worlds
		receipt["revealed_world"] = int(receipt.get("revealed_world", 0))
		receipt["huntcraft"] = trade_lv("huntcraft")
		web_smoke_features["d7_pack_reader_deferred_reveal"] = receipt
		return true
	if String(reader.get("seed_fingerprint", "")) \
			!= String(manifest.get("seed_fingerprint", "")) or plate == null:
		_web_smoke_d7_fail("Pack Reader did not reveal the materialized Ashen manifest without rolling it.")
		return false
	if not bool(web_smoke_features.get("d7_pack_reader_zero_rng_manifest", false)):
		receipt["revealed_world"] = world_index
		receipt["huntcraft"] = trade_lv("huntcraft")
		receipt["seed_fingerprint"] = String(manifest.get("seed_fingerprint", ""))
		web_smoke_features["d7_pack_reader_deferred_reveal"] = receipt
		web_smoke_features["d7_pack_reader_zero_rng_manifest"] = true
		web_smoke_report("pack_reader_manifest")
	return true


func _d7_mix_emberleaf_ink() -> bool:
	var bench: Node = await _open_d6_chart_table()
	if bench == null:
		return false
	var panel := bench.get_node_or_null("ChartTablePanel")
	var view := panel.get_node_or_null("ChartTableView") if panel != null else null
	var mix := view.find_child("MixTab", true, false) as Button if view != null else null
	if mix == null:
		bench.close()
		_web_smoke_d7_fail("The physical Chart Table had no Mix Ink control.")
		return false
	mix.pressed.emit()
	await get_tree().process_frame
	for item_id in ["embersage", "embersage", "wellwater", "ash_ink"]:
		if not await _press_d6_supply_control(bench, item_id):
			bench.close()
			_web_smoke_d7_fail("The Copper Pot rejected its renewable %s making." % item_id)
			return false
	var try_mix := view.find_child("TryMixButton", true, false) as Button
	var before := material_count("emberleaf_ink")
	if try_mix == null or try_mix.disabled:
		bench.close()
		_web_smoke_d7_fail("The Copper Pot never exposed its real Emberleaf mix action.")
		return false
	try_mix.pressed.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	bench.close()
	if material_count("emberleaf_ink") != before + 1 or not ink_discovered("emberleaf_ink"):
		_web_smoke_d7_fail("The production Copper Pot did not discover and settle Emberleaf Ink.")
		return false
	return true


func _inscribe_d7_fire_boss_chart() -> void:
	var chart := await _d7_table_inscribe("fire_in_the_bough_boss", ["furnace_mark",
		"cinder_waymark", "soot_track", "cinder_binding", "ember_folio", "emberleaf_ink",
		"starheart_coal"], "giant_preview")
	if chart.is_empty():
		return
	var attempt_id := String(chart.get("attempt_id", ""))
	var escrow: Dictionary = (campaign_state.escrows as Dictionary).get(attempt_id, {})
	if attempt_id == "" or String(escrow.get("phase", "")) != "case" \
			or (escrow.get("items", {}) as Dictionary) != {"starheart_coal": 1}:
		_web_smoke_d7_fail("The Fire Table commit did not open the exact Starheart Coal escrow.")
		return
	_web_smoke_d7_boss_chart = chart.duplicate(true)
	web_smoke_features["d7_boss_table_escrow"] = true
	_web_smoke_d7_stage = "giant_world"
	if not await _d7_socket_chart_at_town(chart):
		return


func _d7_socket_chart_at_town(chart: Dictionary) -> bool:
	var chart_id := String(chart.get("chart_instance_id", ""))
	var chart_index := -1
	for index in charts.size():
		if String((charts[index] as Dictionary).get("chart_instance_id", "")) == chart_id:
			chart_index = index
			break
	if chart_index < 0:
		_web_smoke_d7_fail("The new Fire Chart never reached the Town Chart Case.")
		return false
	var stone: Node3D = null
	for node_v in get_tree().get_nodes_in_group("interactable"):
		if node_v is Node3D and node_v.has_method("get_prompt_text") \
				and String(node_v.call("get_prompt_text")) == "[E] Socket a chart":
			stone = node_v as Node3D
			break
	if stone == null or not await _d6_scanner_interact(stone):
		_web_smoke_d7_fail("The authored Town Waystone did not open for the Fire Chart.")
		return false
	var panel: Node = null
	for child in get_tree().current_scene.get_children():
		if child is CanvasLayer and child.find_child("StepThroughButton", true, false) != null:
			panel = child
			break
	var row := panel.find_child("ChartCaseRow%d" % chart_index, true, false) as Button \
		if panel != null else null
	if panel == null or row == null:
		_web_smoke_d7_fail("The real Waystone Chart Case did not expose the new Fire Chart.")
		return false
	row.pressed.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	var step := panel.find_child("StepThroughButton", true, false) as Button
	if step == null or step.disabled:
		_web_smoke_d7_fail("The real Waystone did not enable Step Through for the Fire Chart.")
		return false
	web_smoke_features["d7_real_town_waystone"] = true
	step.pressed.emit()
	return true


func _d7_capture_world_owner_token(owner_label: String) -> Dictionary:
	var scene := get_tree().current_scene
	if scene == null or scene.name != "World":
		return {}
	_web_smoke_d7_world_generation += 1
	_web_smoke_d7_world_token = {
		"owner": owner_label,
		"world_generation": _web_smoke_d7_world_generation,
		"world_instance_id": scene.get_instance_id(),
		"stage": _web_smoke_d7_stage,
		"chart_instance_id": String(active_chart.get("chart_instance_id", "")),
	}
	return _web_smoke_d7_world_token.duplicate(true)


func _d7_current_world_owner_token(owner_label: String) -> Dictionary:
	var scene := get_tree().current_scene
	if scene == null or scene.name != "World":
		return {}
	if _web_smoke_d7_world_token.is_empty() \
			or int(_web_smoke_d7_world_token.get("world_instance_id", -1)) != scene.get_instance_id():
		return _d7_capture_world_owner_token(owner_label)
	return _web_smoke_d7_world_token.duplicate(true)


func _d7_world_owner_identity_valid(token: Dictionary) -> bool:
	var scene := get_tree().current_scene
	return not token.is_empty() and scene != null and scene.name == "World" \
		and int(token.get("world_generation", -1)) == _web_smoke_d7_world_generation \
		and int(token.get("world_instance_id", -1)) == scene.get_instance_id() \
		and String(token.get("chart_instance_id", "")) == String(active_chart.get("chart_instance_id", ""))


func _d7_rebind_world_owner_stage(token: Dictionary, owner_label: String) -> Dictionary:
	# A route phase can change while the same physical World remains authoritative
	# (the Giant settles before its Far Waystone return). Rebind only an already
	# verified immutable World identity; this never increments generation or
	# replaces the scene-ready token, so an old World cannot bless a newer one.
	if not _d7_world_owner_identity_valid(token):
		_d7_record_far_waystone_detail("stale_return_rejected", null,
			local_player() as Node3D, {"boundary": "world_stage_rebind",
			"expected_owner": token.duplicate(true)})
		_web_smoke_d7_fail("D7 rejected a stale World stage rebind for %s." % owner_label)
		return {}
	var rebound := token.duplicate(true)
	rebound["owner"] = owner_label
	rebound["stage"] = _web_smoke_d7_stage
	return rebound


func _d7_world_owner_valid(token: Dictionary, boundary: String,
		fail_on_stale: bool = true) -> bool:
	var scene := get_tree().current_scene
	var current := {
		"world_generation": _web_smoke_d7_world_generation,
		"world_instance_id": scene.get_instance_id() if scene != null else -1,
		"scene": String(scene.name) if scene != null else "<none>",
		"stage": _web_smoke_d7_stage,
		"chart_instance_id": String(active_chart.get("chart_instance_id", "")),
	}
	var valid := _d7_world_owner_identity_valid(token) \
		and String(token.get("stage", "")) == _web_smoke_d7_stage
	if not valid and fail_on_stale:
		_d7_record_far_waystone_detail("stale_return_rejected", null,
			local_player() as Node3D, {"boundary": boundary,
			"expected_owner": token.duplicate(true), "current_owner": current})
		_web_smoke_d7_fail("D7 rejected a stale World owner at %s." % boundary)
	return valid


func _d7_schedule_far_waystone_return(delay_sec: float, owner_label: String,
		owner_token: Dictionary = {}) -> void:
	var token := owner_token.duplicate(true) if not owner_token.is_empty() \
		else _d7_current_world_owner_token(owner_label)
	if token.is_empty():
		_web_smoke_d7_fail("D7 could not bind a World owner for %s." % owner_label)
		return
	get_tree().create_timer(delay_sec, true).timeout.connect(
		_d7_run_scheduled_far_waystone_return.bind(token, owner_label))


func _d7_run_scheduled_far_waystone_return(token: Dictionary, owner_label: String) -> void:
	# The token check is intentionally before any modal/status/waystone work.
	# A stale timer must fail observably without mutating the later chart.
	if not _d7_world_owner_valid(token, "scheduled_far_return:%s" % owner_label):
		return
	await _d7_return_through_far_waystone(token)


func _d7_claim_far_waystone_return(owner_token: Dictionary) -> bool:
	var generation := int(owner_token.get("world_generation", -1))
	if generation < 0:
		_d7_record_far_waystone_detail("stale_return_rejected", null,
			local_player() as Node3D, {"boundary": "far_waystone_invalid_generation",
			"expected_owner": owner_token.duplicate(true)})
		_web_smoke_d7_fail("D7 rejected a Far Waystone return without a valid World generation.")
		return false
	if _web_smoke_d7_return_claim_generation == generation:
		_d7_record_far_waystone_detail("stale_return_rejected", null,
			local_player() as Node3D, {"boundary": "far_waystone_duplicate_claim",
			"expected_owner": owner_token.duplicate(true)})
		_web_smoke_d7_fail("D7 rejected a duplicate Far Waystone return for one World.")
		return false
	_web_smoke_d7_return_claim_generation = generation
	return true


func _d7_return_through_far_waystone(owner_token: Dictionary = {}) -> bool:
	# Strict D7 never accepts an unowned delayed return. Direct callers take the
	# immutable token captured at their World boundary; delayed callers receive
	# the same immutable token from `_d7_schedule_far_waystone_return`.
	if owner_token.is_empty():
		_d7_record_far_waystone_detail("stale_return_rejected", null,
			local_player() as Node3D, {"boundary": "far_waystone_missing_owner"})
		_web_smoke_d7_fail("D7 rejected an unowned Far Waystone return.")
		return false
	if not _d7_world_owner_valid(owner_token, "far_waystone_entry"):
		return false
	# Claim before the first yield. Two callbacks can both be valid at the same
	# World boundary, but only one may ever press this chart's Far Waystone.
	if not _d7_claim_far_waystone_return(owner_token):
		return false
	# Other D7 World routes can reach the return stone from a deferred combat
	# callback rather than the training loop above.  Re-check the same exact
	# status lessons at this action boundary so a late combat tick cannot leave
	# PlayerController paused between target acquisition and InputMap interact.
	if not await _d7_finish_pending_world_status_hints(owner_token):
		return false
	if not _d7_world_owner_valid(owner_token, "far_waystone_after_status"):
		return false
	var deep_hollow_return := _web_smoke_d7_stage == "golden_deep_hollow_world" \
		and String(active_chart.get("recipe_id", "")) == "deep_hollow"
	var waystone := _find_d2_exit_waystone()
	if waystone == null:
		_d7_record_far_waystone_detail("stone_missing", null, null)
		_web_smoke_d7_fail("The Fire run could not return through its real Far Waystone (stone_missing).")
		return false
	var result := await _d7_interact_far_waystone(waystone, owner_token)
	if String(result.get("status", "")) != "settled":
		_web_smoke_d7_fail("The Fire run could not return through its real Far Waystone (%s)." \
			% String(result.get("status", "interaction_did_not_settle")))
		return false
	web_smoke_features["d7_real_far_waystone"] = true
	if deep_hollow_return:
		web_smoke_report("deep_far_return")
		web_smoke_report("golden_deep_far_return")
	return true


func _d7_far_waystone_return_committed(target: Variant) -> bool:
	# A real ExitWaystone commits one of two observable receipts.  The normal
	# single-layer path can change the scene immediately.  On a fast Web frame,
	# however, `return_to_town()` clears `active_chart` before its deferred Town
	# scene swap; the exact stone's `_used` receipt is therefore the authoritative
	# proof during that short boundary.  Do not treat a depth-choice stone as
	# committed: it intentionally remains unused until the player presses one of
	# the dialog's real actions.
	var scene := get_tree().current_scene
	if scene != null and scene.name == "Town":
		return true
	return is_instance_valid(target) and target.has_method("is_used") \
		and bool(target.call("is_used"))


# Diagnostic-only D7 variant of the generic World scanner helper.  D2's
# existing caller only needs acquisition; D7's long fresh route needs the
# stronger fact that the same physical press actually began a return.  This
# never calls Interactable directly, chooses no depth option, and mutates no
# gameplay state: it just observes scanner acquisition and the released
# ExitWaystone/scene-transition consequences.
func _d7_interact_far_waystone(target: Node3D, owner_token: Dictionary) -> Dictionary:
	if not _d7_world_owner_valid(owner_token, "far_waystone_interact_entry"):
		return {"status": "stale_owner"}
	var player := local_player() as Node3D
	if player == null:
		_d7_record_far_waystone_detail("player_missing", target, null)
		return {"status": "player_missing"}
	if target == null or not is_instance_valid(target):
		_d7_record_far_waystone_detail("stone_missing", null, player)
		return {"status": "stone_missing"}
	var home := player.global_position
	var acquired := false
	for direction in [Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD, Vector3.BACK]:
		for step in 31:
			if not _d7_world_owner_valid(owner_token, "far_waystone_scanner_before_frame"):
				return {"status": "stale_owner"}
			if not is_instance_valid(player) or not is_instance_valid(target):
				_d7_record_far_waystone_detail("scanner_target_invalid", target, player)
				return {"status": "scanner_target_invalid"}
			var distance := lerpf(4.0, 1.05, float(step) / 30.0)
			player.global_position = Vector3(
				target.global_position.x + direction.x * distance, home.y,
				target.global_position.z + direction.z * distance)
			await get_tree().physics_frame
			if not _d7_world_owner_valid(owner_token, "far_waystone_scanner_after_frame"):
				return {"status": "stale_owner"}
			if not is_instance_valid(player) or not is_instance_valid(target):
				_d7_record_far_waystone_detail("scanner_target_invalid", target, player)
				return {"status": "scanner_target_invalid"}
			if player.get("_active_interactable") == target:
				acquired = true
				break
		if acquired:
			break
	if not acquired:
		player.global_position = home
		_d7_record_far_waystone_detail("scanner_not_acquired", target, player)
		return {"status": "scanner_not_acquired"}
	# Acquisition is only a presentation fact. Bind the actual InputMap edge to
	# this exact stone so a nearby inert prop cannot win on the next physics tick.
	# The shared strict helper retries only refused (mutation-free) ownership
	# edges and requires PlayerController's exact actual-target receipt.
	if not await _d7_press_interact_for_target(player, target):
		player.global_position = home
		_d7_record_far_waystone_detail("target_mismatch", target, player)
		return {"status": "target_mismatch"}
	# Pressing the physical Waystone may be the action that moves us to Town;
	# accept that explicit settled transition, or the exact stone's production
	# `_used` edge while the deferred scene swap is still pending. The latter can
	# clear `active_chart` before `current_scene` changes on a fast Web frame, so
	# owner validation after that committed edge would manufacture a stale token.
	if _d7_far_waystone_return_committed(target):
		_d7_record_far_waystone_detail("settled", target, player,
			{"settled_by": "town_transition" if get_tree().current_scene != null \
				and get_tree().current_scene.name == "Town" else "stone_used"})
		return {"status": "settled", "settled_by": "town_transition" \
			if get_tree().current_scene != null and get_tree().current_scene.name == "Town" \
			else "stone_used"}
	if not _d7_world_owner_valid(owner_token, "far_waystone_after_interact_press"):
		return {"status": "stale_owner"}
	if not is_instance_valid(player) or not is_instance_valid(target):
		_d7_record_far_waystone_detail("scanner_target_invalid", target, player)
		return {"status": "scanner_target_invalid"}
	# A multi-fold Chart opens the shipped Far Waystone choice instead of changing
	# scenes immediately. Return through its actual paged dialog; leaving it
	# open is neither a completed physical return nor a valid reason to time out.
	if not bool(target.get("abandoning")) and can_press_deeper():
		if not await _d7_choose_far_waystone_return(target, owner_token):
			_d7_record_far_waystone_detail("depth_return_control_missing", target, player)
			return {"status": "depth_return_control_missing"}
	if is_instance_valid(player):
		player.global_position = home
	var deadline := Time.get_ticks_msec() + 3500
	while Time.get_ticks_msec() < deadline:
		var town_transitioned := get_tree().current_scene != null \
			and get_tree().current_scene.name == "Town"
		if _d7_far_waystone_return_committed(target):
			_d7_record_far_waystone_detail("settled", target, player, {
				"settled_by": "town_transition" if town_transitioned else "stone_used"})
			return {"status": "settled", "settled_by": "town_transition" if town_transitioned else "stone_used"}
		await get_tree().create_timer(0.05, true).timeout
		if _d7_far_waystone_return_committed(target):
			_d7_record_far_waystone_detail("settled", target, player,
				{"settled_by": "town_transition" if get_tree().current_scene != null \
					and get_tree().current_scene.name == "Town" else "stone_used"})
			return {"status": "settled", "settled_by": "town_transition" \
				if get_tree().current_scene != null and get_tree().current_scene.name == "Town" \
				else "stone_used"}
		if not _d7_world_owner_valid(owner_token, "far_waystone_settle_wait"):
			return {"status": "stale_owner"}
		if not is_instance_valid(player) or not is_instance_valid(target):
			_d7_record_far_waystone_detail("scanner_target_invalid", target, player)
			return {"status": "scanner_target_invalid"}
	_d7_record_far_waystone_detail("interaction_did_not_settle", target, player)
	return {"status": "interaction_did_not_settle"}


func _d7_choose_far_waystone_return(target: Node3D, owner_token: Dictionary) -> bool:
	if not _d7_world_owner_valid(owner_token, "far_waystone_depth_entry"):
		return false
	var deadline := Time.get_ticks_msec() + 3000
	var dialog: Node = null
	while Time.get_ticks_msec() < deadline:
		dialog = _find_d2_depth_choice_dialog()
		if dialog != null:
			break
		await get_tree().process_frame
		if not _d7_world_owner_valid(owner_token, "far_waystone_depth_wait"):
			return false
	if dialog == null:
		return false
	# The Omen is the dialog's first page; advance through the same released
	# pointer event ordinary play uses before selecting the visible return button.
	await get_tree().create_timer(0.3, true).timeout
	if not _d7_world_owner_valid(owner_token, "far_waystone_depth_before_advance"):
		return false
	var advance_event := InputEventMouseButton.new()
	advance_event.button_index = MOUSE_BUTTON_LEFT
	advance_event.pressed = true
	advance_event.position = get_viewport().get_visible_rect().size * 0.5
	Input.parse_input_event(advance_event)
	await get_tree().process_frame
	if not _d7_world_owner_valid(owner_token, "far_waystone_depth_after_advance_press"):
		return false
	advance_event.pressed = false
	Input.parse_input_event(advance_event)
	await get_tree().process_frame
	if not _d7_world_owner_valid(owner_token, "far_waystone_depth_after_advance_release"):
		return false
	var safe_return: Button = null
	for button_v in dialog.find_children("*", "Button", true, false):
		var button := button_v as Button
		if button != null and button.text == "Return safely" and not button.disabled:
			safe_return = button
			break
	if safe_return == null:
		return false
	safe_return.pressed.emit()
	# `Return safely` uses the same production ExitWaystone receipt as a
	# single-layer return.  It may clear `active_chart` before the deferred Town
	# scene swap, so accept only the exact used stone at this boundary; an open
	# depth choice remains `_used == false` and still takes the strict owner path.
	if _d7_far_waystone_return_committed(target):
		return true
	await get_tree().process_frame
	if not _d7_far_waystone_return_committed(target) \
			and not _d7_world_owner_valid(owner_token, "far_waystone_depth_after_return_press"):
		return false
	return true


func _d7_record_far_waystone_detail(status: String, target: Variant, player: Variant,
		extra: Dictionary = {}) -> void:
	var chart: Dictionary = active_chart
	var affixes: Array = []
	for affix_v in chart.get("affixes", []):
		if affix_v is Dictionary:
			var affix := affix_v as Dictionary
			affixes.append({"id": String(affix.get("id", "")),
				"good": bool(affix.get("good", false))})
	var player_valid := player != null and is_instance_valid(player)
	var active_prompt := ""
	var active: Variant = player.get("_active_interactable") if player_valid else null
	if active != null and is_instance_valid(active) and active.has_method("get_prompt_text"):
		active_prompt = String(active.call("get_prompt_text"))
	var overlaps: Array = []
	if player_valid:
		var raw_overlaps: Variant = player.get("_overlapping_interactables")
		if raw_overlaps is Array:
			for node_v in raw_overlaps:
				if not (node_v is Node3D) or not is_instance_valid(node_v):
					continue
				var node := node_v as Node3D
				var prompt := String(node.call("get_prompt_text")) \
					if node.has_method("get_prompt_text") else ""
				var used := bool(node.call("is_used")) if node.has_method("is_used") else false
				overlaps.append({"prompt": prompt,
					"distance": snappedf(player.global_position.distance_to(node.global_position), 0.01),
					"used": used})
	_web_smoke_d7_far_waystone_detail = {
		"status": status,
		"runs": int(_web_smoke_d7_training.get("runs", 0)),
		"world_legs": int(_web_smoke_d7_training.get("world_legs", 0)),
		"trades": {"wayfinding": trade_lv("wayfinding"), "huntcraft": trade_lv("huntcraft"),
			"earthcraft": trade_lv("earthcraft"), "wildcraft": trade_lv("wildcraft")},
		"chart": {"id": String(chart.get("chart_instance_id", "")),
			"seed": int(chart.get("seed", -1)), "affixes": affixes,
			"layer": int(chart.get("layer", 1)), "max_layers": int(chart.get("max_layers", 1)),
			"boss_kind": String(run_cfg().get("boss_kind", ""))},
		"player": {"hp": int(player.get("hp")) if player_valid else -1,
			"dead": bool(player.get("dead")) if player_valid else true},
		"paused": get_tree().paused,
		"modal_count": modal_count,
		"modal_snapshot": _d7_world_modal_snapshot() if modal_count > 0 or get_tree().paused else [],
		"interaction_receipt": _d7_interaction_receipt_snapshot(player),
		"active_interactable_prompt": active_prompt,
		"overlapping_interactables": overlaps,
		"target": _d7_interactable_snapshot(target),
	}
	for key in extra:
		_web_smoke_d7_far_waystone_detail[String(key)] = extra[key]


func _d7_table_inscribe(recipe_id: String, supplies_to_press: Array, phase: String) -> Dictionary:
	var bench: Node = await _open_d6_chart_table()
	if bench == null:
		return {}
	var panel := bench.get_node_or_null("ChartTablePanel")
	var view := panel.get_node_or_null("ChartTableView") if panel != null else null
	var supplies := view.find_child("SuppliesTab", true, false) as Button if view != null else null
	if supplies == null:
		bench.close()
		_web_smoke_d7_fail("The physical Fire Table had no Supplies tab for %s." % recipe_id)
		return {}
	supplies.pressed.emit()
	await get_tree().process_frame
	var wanted := {}
	for item_v in supplies_to_press:
		var item_id := String(item_v)
		wanted[item_id] = int(wanted.get(item_id, 0)) + 1
		var before := material_count(item_id)
		if not await _press_d6_supply_control(bench, item_id):
			bench.close()
			_web_smoke_d7_fail("The Fire Table rejected its visible %s supply." % item_id)
			return {}
		var draft: Dictionary = bench.get("draft")
		var staged := (draft.get("grid", {}) as Dictionary).values().count(item_id) \
			+ (draft.get("ink_rail", []) as Array).count(item_id)
		if staged < int(wanted[item_id]) and material_count(item_id) > before \
				and not await _press_d6_supply_control(bench, item_id):
			bench.close()
			_web_smoke_d7_fail("The renewed %s supply would not stage at the Fire Table." % item_id)
			return {}
	var preview: Dictionary = bench.call("current_preview")
	var action := view.find_child("InscribeChartButton", true, false) as Button
	var grid: Dictionary = bench.get("draft").get("grid", {})
	var rail: Array = bench.get("draft").get("ink_rail", [])
	var ordinary := recipe_id == "ashen_bough"
	var expected_grid := {"nw": "ash_mark", "n": "cinder_waymark", "ne": "ember_mark",
		"w": "cinder_binding", "c": "ember_folio"} if ordinary else \
		{"nw": "furnace_mark", "n": "cinder_waymark", "ne": "soot_track",
		"w": "cinder_binding", "c": "ember_folio", "s": "starheart_coal"}
	var expected_rail := ["ash_ink"] if ordinary else ["emberleaf_ink"]
	if String(preview.get("recipe_id", "")) != recipe_id \
			or not bool(preview.get("commit_ready", false)) or action == null or action.disabled \
			or grid != expected_grid or rail != expected_rail:
		var supply_counts := {}
		for item_v in supplies_to_press:
			var item_id := String(item_v)
			supply_counts[item_id] = material_count(item_id)
		bench.close()
		_web_smoke_d7_fail("The physical Table did not resolve the exact %s grammar (preview=%s, grid=%s, rail=%s, gold=%d, supplies=%s)." % [
			recipe_id, String(preview.get("recipe_id", "")), str(grid), str(rail),
			gold, str(supply_counts)])
		return {}
	if ordinary:
		if not (preview.get("campaign_contract", {}) as Dictionary).is_empty() \
				or String((preview.get("output", {}) as Dictionary).get("name", "")) != "Ashen Bough" \
				or String((preview.get("depth_contract", {}) as Dictionary).get("variant_id", "")) != "":
			bench.close()
			_web_smoke_d7_fail("Ashen Bough did not remain the base, boss-free Table contract.")
			return {}
	else:
		var contract: Dictionary = preview.get("campaign_contract", {})
		var guarantees: Array = preview.get("guaranteed", [])
		if contract != CampaignData.boss_contract("fire_in_the_bough_boss") \
				or preview.get("returned_on_failure", {}) != {"starheart_coal": 1} \
				or guarantees.is_empty() or String((guarantees[0] as Dictionary).get("id", "")) != "hearth_giant":
			bench.close()
			_web_smoke_d7_fail("The Giant preview did not visibly bind its forced encounter and Coal safeguard.")
			return {}
		web_smoke_features["d7_boss_preview_contract"] = true
	web_smoke_features["d7_real_table_commits"] = true
	web_smoke_report(phase)
	var before_costs := {}
	for material_v in (preview.get("costs", {}) as Dictionary):
		before_costs[String(material_v)] = material_count(String(material_v))
	var charts_before := charts.size()
	action.pressed.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	var chart: Dictionary = charts.back() if charts.size() == charts_before + 1 else {}
	bench.close()
	if chart.is_empty() or String(chart.get("recipe_id", "")) != recipe_id:
		_web_smoke_d7_fail("The real Inscribe Chart Control did not commit %s." % recipe_id)
		return {}
	for material_v in (preview.get("costs", {}) as Dictionary):
		var material_id := String(material_v)
		if material_count(material_id) != int(before_costs[material_id]) \
				- int((preview.get("costs", {}) as Dictionary)[material_v]):
			_web_smoke_d7_fail("%s did not charge its exact %s cost." % [recipe_id, material_id])
			return {}
	return chart


func _drive_d7_giant_world(owner_token: Dictionary = {}) -> void:
	if owner_token.is_empty():
		owner_token = _d7_current_world_owner_token("giant_world")
	if not _d7_world_owner_valid(owner_token, "giant_world_entry"):
		return
	var boss := _d4_find_boss("hearth_giant")
	var attempt_id := String(_web_smoke_d7_boss_chart.get("attempt_id", ""))
	var escrow: Dictionary = (campaign_state.escrows as Dictionary).get(attempt_id, {})
	var controller := get_tree().current_scene.get_node_or_null("HearthGiantEncounter")
	if boss == null or controller == null or not controller.has_method("request_chain_bank") \
			or String(run_cfg().get("boss_kind", "")) != "hearth_giant" \
			or String(escrow.get("phase", "")) != "in_run":
		_web_smoke_d7_fail("The Fire World did not bind its live Hearth Giant Coal escrow.")
		return
	web_smoke_features["d7_world_hearth_giant"] = true
	web_smoke_report("giant_world")
	var player := local_player() as Node3D
	if player == null:
		_web_smoke_d7_fail("The Giant World had no host player for its chain interactions.")
		return
	for phase in 3:
		boss.call("take_damage", int(boss.get("hp")) + 1, Vector3.FORWARD)
		await get_tree().process_frame
		if not _d7_world_owner_valid(owner_token, "giant_world_after_damage"):
			return
		var expected_id := String((controller.get("CHAIN_ORDER") as Array)[phase])
		var chains: Dictionary = controller.get("chains")
		var expected := chains.get(expected_id) as Node3D
		if expected == null or not bool(boss.get("heat_shielded")):
			_web_smoke_d7_fail("The Hearth Giant did not raise heat floor %d with its expected chain." % (phase + 1))
			return
		if phase == 0:
			var wrong := chains.get("braided_link") as Node3D
			var mask_before := int(controller.get("bank_mask"))
			if not await _d6_scanner_interact(wrong):
				return
			await get_tree().process_frame
			if not _d7_world_owner_valid(owner_token, "giant_world_after_wrong_chain"):
				return
			if int(controller.get("bank_mask")) != mask_before:
				_web_smoke_d7_fail("A wrong Hearth chain did not remain recoverable and unbanked.")
				return
			web_smoke_features["d7_recoverable_wrong_chain"] = true
			web_smoke_report("giant_wrong_chain")
		if not await _d6_scanner_interact(expected):
			return
		await get_tree().process_frame
		if not _d7_world_owner_valid(owner_token, "giant_world_after_expected_chain"):
			return
		var expected_bit := 1 << phase
		if int(controller.get("bank_mask")) & expected_bit == 0:
			_web_smoke_d7_fail("The host rejected the expected %s bank." % expected_id)
			return
		web_smoke_report("giant_chain_%d" % (phase + 1))
	if not bool(boss.get("kneeling")) or bool(boss.get("dead")):
		_web_smoke_d7_fail("All three valid chains did not kneel the Giant without a generic death.")
		return
	await get_tree().create_timer(0.6).timeout
	if not _d7_world_owner_valid(owner_token, "giant_world_after_settlement_wait"):
		return
	escrow = (campaign_state.escrows as Dictionary).get(attempt_id, {})
	if String(escrow.get("phase", "")) != "consumed" \
			or not CampaignData.chapter_cleared(campaign_state, CampaignData.FIRE_IN_THE_BOUGH) \
			or material_count("starheart_coal") != 0 or material_count("wyrm_scale") != 1 \
			or not (campaign_state.relics as Array).has("ember_root_rune") \
			or not (campaign_state.threads as Array).has("present_thread") \
			or not (campaign_state.restorations as Array).has("ember_kiln"):
		_web_smoke_d7_fail("The Giant's production kneel did not exact-settle Fire in the Bough.")
		return
	web_smoke_features["d7_three_host_validated_chain_banks"] = true
	web_smoke_features["d7_exact_fire_settlement"] = true
	web_smoke_report("giant_cleared")
	_web_smoke_d7_stage = "giant_return"
	var return_token := _d7_rebind_world_owner_stage(owner_token, "giant_return")
	if return_token.is_empty():
		return
	_d7_schedule_far_waystone_return(0.35, "giant_return", return_token)


func _verify_d7_fire_settlement() -> void:
	await _wait_d7_town_control()
	if web_smoke_phase == "failed":
		return
	if not _d7_require_exact_wayfinding_xp(
			"hearth_giant_return", D7_FIRE_GIANT_WAYFINDING_XP):
		return
	var scene := get_tree().current_scene
	var kiln := scene.get_node_or_null("EmberKiln") as Node3D if scene != null else null
	if kiln == null or kiln.get_node_or_null("ThreefoldLoomFoundation") == null \
			or not CampaignData.chapter_cleared(campaign_state, CampaignData.FIRE_IN_THE_BOUGH) \
			or not (campaign_state.restorations as Array).has("ember_kiln"):
		_web_smoke_d7_fail("Town did not project the settled functional Ember Kiln and inert Loom foundation.")
		return
	web_smoke_features["d7_town_settlement_projections"] = true
	web_smoke_report("ember_kiln")
	# Starheart Alloy is post-settlement content. Its Earthcraft gate is earned
	# only after the Kiln restoration exists, through live Town mining and Forge
	# transactions; no Fire entry work or campaign reward grants this level.
	var alloy_gate := int((CraftingDefs.RECIPES.get(
		"starheart_alloy", {}) as Dictionary).get("req_lv", 1))
	if trade_lv("earthcraft") < alloy_gate \
			and not await _d7_training_forge_copper({"earthcraft": alloy_gate}):
		return
	if not await _d7_craft_starheart_alloy(kiln):
		return
	web_smoke_features["d7_post_clear_starheart_alloy"] = true
	web_smoke_report("starheart_alloy")
	if not await _d7_drive_threadstep(scene):
		return
	web_smoke_features["d7_gameplay_driver"] = true
	_d7_record_progressive_level_ledger("fire_in_the_bough_settlement")
	web_smoke_report("complete")


func _d7_craft_starheart_alloy(kiln: Node3D) -> bool:
	if not await _d7_forge_fire_inputs():
		return false
	if not await _d6_scanner_interact(kiln):
		return false
	var panel := _d7_find_craft_panel("ember_kiln")
	var recipe: Button = await _d7_training_forge_recipe_button(panel, "starheart_alloy")
	var before := material_count("starheart_alloy")
	if recipe == null:
		_web_smoke_d7_fail("The restored Ember Kiln did not expose an enabled Starheart Alloy craft.")
		return false
	recipe.pressed.emit()
	await get_tree().process_frame
	var close := panel.find_child("CloseButton", true, false) as Button if panel != null else null
	if close != null:
		close.pressed.emit()
	if material_count("starheart_alloy") != before + 1:
		_web_smoke_d7_fail("The real Ember Kiln did not craft exactly one Starheart Alloy.")
		return false
	return true


func _d7_forge_fire_inputs() -> bool:
	# The forge panel remains the only authority for these material conversions.
	# Harvest loops must have supplied the ores/logs before this point. Preserve
	# usable intermediates earned by the Earthcraft training loop: only craft a
	# material while its live stock remains below the Alloy chain's requirement.
	var forge: Node3D = null
	for node_v in get_tree().get_nodes_in_group("interactable"):
		var station_id = node_v.get("station_id") if node_v is Node3D else null
		if node_v is Node3D and station_id != null and String(station_id) == "forge":
			forge = node_v as Node3D
			break
	if forge == null or not await _d6_scanner_interact(forge):
		_web_smoke_d7_fail("The Fire forge loop could not open Hod's real forge.")
		return false
	var panel := _d7_find_craft_panel("forge")
	var requirements := {"bogiron_bar": 2, "emberglass": 2, "wildgold_bar": 2}
	for recipe_id_v in requirements:
		var recipe_id := String(recipe_id_v)
		while material_count(recipe_id) < int(requirements[recipe_id_v]):
			var button: Button = await _d7_training_forge_recipe_button(panel, recipe_id)
			if button == null:
				var failed_close := panel.find_child("CloseButton", true, false) as Button \
					if panel != null else null
				if failed_close != null:
					failed_close.pressed.emit()
				_web_smoke_d7_fail(("The real forge lacks affordable %s " \
					+ "(have=%d, need=%d); harvest/train inputs before Alloy.") % [
					recipe_id, material_count(recipe_id), int(requirements[recipe_id_v])])
				return false
			button.pressed.emit()
			await get_tree().process_frame
	var close := panel.find_child("CloseButton", true, false) as Button if panel != null else null
	if close != null:
		close.pressed.emit()
	if material_count("emberglass") < 2 or material_count("wildgold_bar") < 2:
		_web_smoke_d7_fail("Real forge transactions did not produce two Emberglass and two Wildgold Bars.")
		return false
	return true


func _d7_drive_threadstep(scene: Node) -> bool:
	var lodge := scene.get_node_or_null("HuntersLodgeLesson") as Node3D if scene != null else null
	if lodge == null or not await _d6_scanner_interact(lodge):
		return false
	var dialog := get_tree().get_first_node_in_group("HuntersLodgeLessonDialog")
	if dialog == null or not dialog.has_method("_finish"):
		_web_smoke_d7_fail("The physical Hunter's Lodge did not open the Threadstep lesson.")
		return false
	dialog.call("_finish")
	await get_tree().process_frame
	var player := local_player() as Node3D
	if player == null or not skill_owned("Threadstep") or not loadout.has("Threadstep") \
			or not player.has_method("try_threadstep"):
		_web_smoke_d7_fail("The physical Lodge lesson did not equip Threadstep.")
		return false
	var focus_before := float(player.get("focus"))
	if focus_before < 20.0:
		_web_smoke_d7_fail("Threadstep needs 20 earned Focus; the fresh marathon may not refill it directly.")
		return false
	# Exercise the rejected host-side preflight first so the successful request
	# remains free of the eight-second cooldown.  Its evidence is reported only
	# after the accepted step, keeping the browser journey in player-facing order.
	var blocked := not bool(player.call("try_threadstep", Vector3.ZERO))
	await get_tree().physics_frame
	if not blocked or not is_equal_approx(float(player.get("focus")), focus_before):
		_web_smoke_d7_fail("Blocked Threadstep did not reject without spending Focus.")
		return false
	var origin := player.global_position
	# Town paths are deliberately irregular. Choose a production-probed clear
	# cardinal/diagonal rather than assuming world-right is always five metres of
	# navigable ground from whichever side acquired the Lodge marker.
	var step_direction := Vector3.ZERO
	if player.has_method("_threadstep_probe"):
		for candidate in [Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD, Vector3.BACK,
				Vector3(1.0, 0.0, 1.0).normalized(), Vector3(-1.0, 0.0, 1.0).normalized(),
				Vector3(1.0, 0.0, -1.0).normalized(), Vector3(-1.0, 0.0, -1.0).normalized()]:
			var probe: Dictionary = player.call("_threadstep_probe", origin, candidate, 5.0)
			if bool(probe.get("ok", false)):
				step_direction = candidate
				break
	if step_direction == Vector3.ZERO:
		_web_smoke_d7_fail("The Lodge return point exposed no collision-safe Threadstep direction.")
		return false
	if not bool(player.call("try_threadstep", step_direction)):
		_web_smoke_d7_fail("Threadstep did not submit its accepted production request.")
		return false
	var focus_after_commit := float(player.get("focus"))
	await get_tree().physics_frame
	if player.global_position.distance_to(origin) < 0.5 \
			or not is_equal_approx(focus_after_commit, focus_before - 20.0):
		# The endpoint/focus assertions below provide useful failure detail without
		# trusting a reported Skill phase.
		_web_smoke_d7_fail(("Accepted Threadstep did not commit its authoritative endpoint " \
			+ "(moved=%.2f, focus=%.1f→%.1f→%.1f, direction=%s).") % [
			player.global_position.distance_to(origin), focus_before,
			focus_after_commit, float(player.get("focus")), str(step_direction)])
		return false
	web_smoke_features["d7_threadstep_accepted"] = true
	web_smoke_report("threadstep_accepted")
	web_smoke_features["d7_threadstep_blocked"] = true
	web_smoke_report("threadstep_blocked")
	return true


# Fresh-only training helpers must never pre-mark a lesson. GatherNode and
# CraftStation own the lesson creation; this driver waits for it to materialize
# and acknowledges the matching production dialogue through its public finish
# seam before it asks PlayerController to consume another InputMap action.
func _d7_finish_fresh_hint(hint_id: String) -> bool:
	var hint: Array = SKILL_HINTS.get(hint_id, [])
	if hint.is_empty():
		return true
	# `first_time_hint` adds its DialogPanel synchronously today, but retain two
	# frames for the deferred/UI-safe path used by browser builds.
	await get_tree().process_frame
	await get_tree().process_frame
	var scene := get_tree().current_scene
	if scene == null:
		_web_smoke_d7_fail("D7 lost Town while waiting for the fresh %s lesson." % hint_id)
		return false
	var expected_speaker := String(hint[0])
	var expected_pages: Array = hint[1] if hint.size() > 1 and hint[1] is Array else []
	var fresh_hint: Node = null
	for child in scene.get_children():
		if child != null and is_instance_valid(child) and child.has_node("DialogueShell") \
				and child.has_method("_finish") \
				and String(child.get("_speaker")) == expected_speaker \
				and (child.get("_pages") as Array) == expected_pages:
			fresh_hint = child
			break
	if fresh_hint == null:
		return true
	fresh_hint.call("_finish")
	await _wait_d7_town_control()
	return web_smoke_phase != "failed" and modal_count == 0


# World harvesting has the same fresh lesson contract as Town harvesting, but
# it cannot use Town's debrief-aware control waiter.  The World driver must
# leave all unrelated UI untouched: it finds only the exact speaker for the
# gathered kind, finishes it through DialogPanel's public seam, then proves
# the pause/modal ownership has actually returned before it proceeds.
func _d7_finish_fresh_world_hint(hint_id: String, owner_token: Dictionary = {}) -> bool:
	if owner_token.is_empty():
		owner_token = _d7_current_world_owner_token("fresh_hint:%s" % hint_id)
	if not _d7_world_owner_valid(owner_token, "fresh_hint_entry:%s" % hint_id):
		return false
	var hint: Array = SKILL_HINTS.get(hint_id, [])
	if hint.is_empty():
		return await _wait_d7_world_control(owner_token)
	# `GatherNode._harvest` opens its first-use DialogPanel after awarding the
	# material.  Give the regular and deferred Web UI paths time to attach it.
	await get_tree().process_frame
	await get_tree().process_frame
	if not _d7_world_owner_valid(owner_token, "fresh_hint_after_frames:%s" % hint_id):
		return false
	var scene := get_tree().current_scene
	if scene == null:
		_web_smoke_d7_fail("D7 lost World while waiting for the fresh %s lesson." % hint_id)
		return false
	var expected_speaker := String(hint[0])
	var expected_pages: Array = hint[1] if hint.size() > 1 and hint[1] is Array else []
	var fresh_hint: Node = null
	for child in scene.get_children():
		if child != null and is_instance_valid(child) and child.has_node("DialogueShell") \
				and child.has_method("_finish") \
				and String(child.get("_speaker")) == expected_speaker \
				and (child.get("_pages") as Array) == expected_pages:
			fresh_hint = child
			break
	if fresh_hint != null:
		fresh_hint.call("_finish")
	await get_tree().process_frame
	if not _d7_world_owner_valid(owner_token, "fresh_hint_after_finish:%s" % hint_id):
		return false
	return await _wait_d7_world_control(owner_token)


# D14 status explainers originate from PlayerController combat timing rather
# than GatherNode's immediate completion callback.  The D7 driver may therefore
# see them after a successful harvest and before its Far Waystone scanner
# action. Match only the two authored status pages byte-for-byte and finish via
# DialogPanel's public seam; never treat an arbitrary modal as disposable.
func _d7_finish_pending_world_status_hints(owner_token: Dictionary = {}) -> bool:
	if owner_token.is_empty():
		owner_token = _d7_current_world_owner_token("status_hint")
	if not _d7_world_owner_valid(owner_token, "status_hint_entry"):
		return false
	var deadline := Time.get_ticks_msec() + 20000
	var stable_since := -1
	var d7_stability = D7ControlStability.new()
	while Time.get_ticks_msec() < deadline:
		if not _d7_world_owner_valid(owner_token, "status_hint_wait"):
			return false
		if _d7_training_abort_requested():
			return false
		var scene := get_tree().current_scene
		if scene == null:
			_web_smoke_d7_fail("D7 lost World while waiting for a pending status lesson.")
			return false
		var finished: Array[String] = []
		for child in scene.get_children():
			if child == null or not is_instance_valid(child) or child.is_queued_for_deletion() \
					or not child.has_node("DialogueShell") or not child.has_method("_finish"):
				continue
			for hint_id in ["status_bleed", "status_slow"]:
				var hint: Array = SKILL_HINTS.get(hint_id, [])
				if hint.is_empty():
					continue
				var expected_speaker := String(hint[0])
				var expected_pages: Array = hint[1] if hint.size() > 1 and hint[1] is Array else []
				if String(child.get("_speaker")) == expected_speaker \
						and (child.get("_pages") as Array) == expected_pages:
					child.call("_finish")
					finished.append(hint_id)
					break
		if not finished.is_empty():
			d7_stability.observe(_d7_control_owner_key(), false)
			var prior: Array = _web_smoke_d7_training.get("world_status_hints_finished", [])
			prior.append_array(finished)
			_web_smoke_d7_training["world_status_hints_finished"] = prior
			web_smoke_features["d7_world_status_hints"] = true
		if not get_tree().paused and modal_count == 0:
			if _d7_control_observation_enabled():
				if d7_stability.observe(_d7_control_owner_key(), true):
					_d7_record_control_stability("d7_world_status", d7_stability)
					return true
			else:
				if stable_since < 0:
					stable_since = Time.get_ticks_msec()
				if Time.get_ticks_msec() - stable_since >= 300:
					return true
		else:
			stable_since = -1
			d7_stability.observe(_d7_control_owner_key(), false)
			# A D7 World modal which did not exactly match one of the two authored
			# status pages is a real owner failure, not a license for generic close.
			if finished.is_empty():
				_web_smoke_d7_fail("D7 World encountered a non-status modal while waiting for the Far Waystone.")
				return false
		if _d7_control_observation_enabled():
			await _d7_wait_control_observation()
		else:
			await get_tree().create_timer(0.05, true).timeout
		if not _d7_world_owner_valid(owner_token, "status_hint_after_yield"):
			return false
	_web_smoke_d7_fail("D7 World status lesson never released control before the Far Waystone.")
	return false


func _wait_d7_world_control(owner_token: Dictionary = {}) -> bool:
	if owner_token.is_empty():
		owner_token = _d7_current_world_owner_token("world_control")
	if not _d7_world_owner_valid(owner_token, "world_control_entry"):
		return false
	var deadline := Time.get_ticks_msec() + 20000
	var stable_since := -1
	var d7_stability = D7ControlStability.new()
	while Time.get_ticks_msec() < deadline:
		if not _d7_world_owner_valid(owner_token, "world_control_wait"):
			return false
		if not get_tree().paused and modal_count == 0:
			if _d7_control_observation_enabled():
				if d7_stability.observe(_d7_control_owner_key(), true):
					_d7_record_control_stability("d7_world", d7_stability)
					return true
			else:
				if stable_since < 0:
					stable_since = Time.get_ticks_msec()
				if Time.get_ticks_msec() - stable_since >= 300:
					return true
		else:
			stable_since = -1
			d7_stability.observe(_d7_control_owner_key(), false)
		if _d7_control_observation_enabled():
			await _d7_wait_control_observation()
		else:
			await get_tree().create_timer(0.05, true).timeout
		if not _d7_world_owner_valid(owner_token, "world_control_after_yield"):
			return false
	_web_smoke_d7_fail(("D7 World never released the fresh lesson before the next scanner action " \
		+ "(paused=%s, modal=%d).") % [get_tree().paused, modal_count])
	return false


func _wait_d7_town_control() -> void:
	var deadline := Time.get_ticks_msec() + 20000
	var stable_since := -1
	var d7_stability = D7ControlStability.new()
	while Time.get_ticks_msec() < deadline:
		var dialogs: Array = []
		dialogs.append_array(get_tree().get_nodes_in_group("run_debrief"))
		dialogs.append_array(get_tree().get_nodes_in_group("FirstKnotHomecomingDebrief"))
		dialogs.append_array(get_tree().get_nodes_in_group("GoldenWallowSettlementDebrief"))
		if not dialogs.is_empty():
			stable_since = -1
			d7_stability.observe(_d7_control_owner_key(), false)
			for dialog in dialogs:
				if dialog != null and is_instance_valid(dialog) and dialog.has_method("_finish"):
					dialog.call("_finish")
				else:
					_web_smoke_d7_fail("A Fire route debrief had no production close action.")
					return
			await get_tree().process_frame
			continue
		# Town creates the run debrief with call_deferred. Its durable pending
		# payload owns control before the CanvasLayer joins `run_debrief`, so an
		# active-clock route must not count that pre-materialization gap as stable.
		if not get_tree().paused and modal_count == 0 and pending_run_debrief.is_empty():
			if _d7_control_observation_enabled():
				if d7_stability.observe(_d7_control_owner_key(), true):
					_d7_record_control_stability("d7_town", d7_stability)
					return
			else:
				if stable_since < 0:
					stable_since = Time.get_ticks_msec()
				if Time.get_ticks_msec() - stable_since >= 650:
					return
		else:
			stable_since = -1
			d7_stability.observe(_d7_control_owner_key(), false)
		if _d7_control_observation_enabled():
			await _d7_wait_control_observation()
		else:
			await get_tree().create_timer(0.1, true).timeout
	if web_smoke_d7_enabled and _web_smoke_d7_stage == "training_town":
		_d7_record_far_waystone_detail("training_town_control_timeout", null,
			local_player() as Node3D, {"training_modal": _d7_training_modal_snapshot()})
	_web_smoke_d7_fail("Town never returned stable control for Fire in the Bough.")


func _web_smoke_d7_fail(reason: String) -> void:
	# Terminal publication owns the attempt before any late coroutine owns a
	# route stage. Once latched, even the helper must be observationally inert.
	if _web_smoke_terminal_latched:
		return
	_web_smoke_d7_stage = "failed"
	web_smoke_report("failed", reason)

# Slice D2 Web acceptance isolates only the already-proven prerequisite state.
# D1 is the fresh-host proof for earning First Knot, whereas this route is the
# replay proof from the physical Chart Table through the World and final return.
# No state is injected after `_apply_d2_prerequisite_fixture`; every subsequent
# action uses the released controls and production transition/callback seams.
func _web_smoke_d2_scene_ready(scene_name: String) -> void:
	if scene_name == "Town":
		pending_run_debrief = {}
		if _web_smoke_d2_stage == "reprise_return":
			_verify_d2_campaign_inert_return()
			return
		if _web_smoke_d2_stage != "":
			_web_smoke_d2_fail("D2 returned to Town outside its terminal replay return.")
			return
		web_smoke_report("town")
		_apply_d2_prerequisite_fixture()
		if web_smoke_phase == "failed":
			return
		get_tree().create_timer(0.6).timeout.connect(_begin_d2_reprise_table)
	elif scene_name == "World":
		match _web_smoke_d2_stage:
			"layer_1":
				_verify_d2_layer_one()
			"layer_2":
				_verify_d2_layer_two()
			_:
				_web_smoke_d2_fail("A World opened outside the D2 Reprise route.")


# Explicitly narrow and query-gated: this does not claim to earn D1 or level
# twenty-one. It is deliberately visible to the browser probe as its own flag.
func _apply_d2_prerequisite_fixture() -> void:
	if not web_smoke_d2_enabled:
		return
	trades.wayfinding = {"xp": xp_for_level(21), "lv": 21}
	materials = {
		"field_parchment": 1,
		"hedge_sprig": 1,
		"loop_cord": 2,
		"hedge_ink": 2,
		"thorn_essence": 1,
	}
	known_chart_recipes = ["first_knot_reprise"]
	chart_recipe_journal = ChartsData.normalize_recipe_journal(
		ChartsData.fresh_recipe_journal(), known_chart_recipes)
	chart_source_unlocks = []
	# A player who cleared First Knot has already received the one-time Table
	# lesson. Marking that proven prerequisite prevents Mara's tutorial dialog
	# from stacking over the query driver's physical Table transaction.
	seen_hints = {"chart_table_snug_returned": true, "bench": true,
		"affix_reading": true}
	tutorial_step = 7
	campaign_state = CampaignData.empty_state()
	var chapters: Dictionary = campaign_state.get("chapters", {})
	var first_knot: Dictionary = chapters.get(CampaignData.FIRST_KNOT, {})
	if first_knot.is_empty():
		_web_smoke_d2_fail("D2 fixture could not locate the First Knot chapter.")
		return
	first_knot["cleared"] = true
	first_knot["clue_count"] = 3
	chapters[CampaignData.FIRST_KNOT] = first_knot
	campaign_state["chapters"] = chapters
	# Match the same canonical shape the physical Table's campaign adapter uses,
	# so the later snapshot detects gameplay mutation rather than harmless
	# normalization of this explicit prerequisite fixture.
	campaign_state = CampaignData.normalize_campaign_state(campaign_state)
	_web_smoke_d2_campaign_before = campaign_state.duplicate(true)
	_web_smoke_d2_rewards_before = {
		"tusker_tusk": material_count("tusker_tusk"),
		"thorn_essence": material_count("thorn_essence"),
		"ledger_tusker_tusk": ledger.slots.has("tusker_tusk") if ledger != null else false,
	}
	if trade_lv("wayfinding") != 21 or not known_chart_recipes.has("first_knot_reprise") \
			or not CampaignData.chapter_cleared(campaign_state, CampaignData.FIRST_KNOT) \
			or materials != {"field_parchment": 1, "hedge_sprig": 1, "loop_cord": 2,
				"hedge_ink": 2, "thorn_essence": 1}:
		_web_smoke_d2_fail("D2 prerequisite fixture did not produce the declared replay inputs.")
		return
	materials_changed.emit()
	chart_knowledge_changed.emit()
	web_smoke_features["d2_prerequisite_fixture"] = true
	_web_smoke_d2_stage = "table"
	web_smoke_report("d2_prerequisites")


func _begin_d2_reprise_table() -> void:
	if not web_smoke_d2_enabled or _web_smoke_d2_stage != "table":
		return
	# Town may still be finishing its arrival vignette. Opening a second modal
	# over that handoff can carry a stale pause into World in Web builds.
	await _wait_d2_stable_control("Town")
	if web_smoke_phase == "failed":
		return
	var bench: Node = await _open_d2_chart_table()
	if bench == null or web_smoke_phase == "failed":
		return
	var panel := bench.get_node_or_null("ChartTablePanel")
	var view := panel.get_node_or_null("ChartTableView") if panel != null else null
	var supplies := view.find_child("SuppliesTab", true, false) as Button if view != null else null
	if supplies == null:
		bench.close()
		_web_smoke_d2_fail("The real D2 Chart Table Supplies Control was missing.")
		return
	supplies.pressed.emit()
	await get_tree().process_frame
	# Supply Controls choose the authored physical wells. The duplicate Loop Cord
	# is the meaningful D2 action: it must occupy the second Binding cell.
	for material_id in ["field_parchment", "hedge_sprig", "loop_cord", "loop_cord",
			"hedge_ink", "thorn_essence"]:
		if not await _press_d2_supply_control(bench, material_id):
			bench.close()
			_web_smoke_d2_fail("The Reprise table rejected its real %s Control." % material_id)
			return
	var preview: Dictionary = bench.call("current_preview")
	var grid: Dictionary = bench.get("draft").get("grid", {})
	var rail: Array = bench.get("draft").get("ink_rail", [])
	var depth: Dictionary = preview.get("depth_contract", {})
	var encounter: Dictionary = preview.get("encounter_contract", {})
	var action := view.find_child("InscribeChartButton", true, false) as Button
	if String(preview.get("recipe_id", "")) != "first_knot_reprise" \
			or not bool(preview.get("commit_ready", false)) \
			or grid != {"c": "field_parchment", "n": "hedge_sprig",
				"w": "loop_cord", "e": "loop_cord", "s": "thorn_essence"} \
			or rail.count("hedge_ink") != 1 \
			or int(depth.get("max_layers", 0)) != 2 \
			or int(depth.get("hearth_layer", 0)) != 2 \
			or String(encounter.get("boss_kind", "")) != "hedgemother" \
			or int(encounter.get("boss_layer", 0)) != 2 \
			or String(encounter.get("reward_family_id", "")) != "first_knot_heirlooms" \
			or not bool(encounter.get("suppress_chain_trophy", false)) \
			or action == null or action.disabled:
		bench.close()
		_web_smoke_d2_fail("The physical Reprise preview lost its authored depth or encounter contract.")
		return
	web_smoke_features["d2_reprise_preview_contract"] = true
	web_smoke_report("chart_table")
	web_smoke_report("reprise_preview")
	var costs: Dictionary = preview.get("costs", {})
	var before_counts := {}
	for material_id_v in costs:
		before_counts[String(material_id_v)] = material_count(String(material_id_v))
	var charts_before := charts.size()
	action.pressed.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	var chart: Dictionary = charts.back() if charts.size() == charts_before + 1 else {}
	bench.close()
	if chart.is_empty() or String(chart.get("recipe_id", "")) != "first_knot_reprise" \
			or chart.get("depth_contract", {}) != depth \
			or String((chart.get("encounter_contract", {}) as Dictionary).get("boss_kind", "")) \
				!= "hedgemother" \
			or chart.has("campaign_contract") or chart.has("returned_on_failure"):
		_web_smoke_d2_fail("The real Inscribe Chart Control did not commit a campaign-inert Reprise.")
		return
	for material_id_v in costs:
		var material_id := String(material_id_v)
		if material_count(material_id) != int(before_counts[material_id]) - int(costs[material_id_v]):
			_web_smoke_d2_fail("The Reprise commit did not spend its exact %s cost." % material_id)
			return
	_web_smoke_d2_chart = chart.duplicate(true)
	web_smoke_features["d2_reprise_table_commit"] = true
	web_smoke_report("reprise_committed")
	await get_tree().process_frame
	if modal_count != 0 or get_tree().paused:
		_web_smoke_d2_fail(("The D2 Chart Table did not release its modal before entry " \
			+ "(paused=%s, modal=%d).") % [get_tree().paused, modal_count])
		return
	_web_smoke_d2_stage = "layer_1"
	enter_dungeon(chart, local_player())


func _open_d2_chart_table():
	var scene := get_tree().current_scene
	var player := local_player() as Node3D
	var tables := get_tree().get_nodes_in_group("inscribing_table")
	if scene == null or player == null or tables.size() != 1:
		_web_smoke_d2_fail("The authored Town Inscribing Table was missing for D2.")
		return null
	var table := tables[0] as Node3D
	var home := player.global_position
	player.global_position = Vector3(table.global_position.x + 1.05, home.y,
		table.global_position.z)
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	if player.get("_active_interactable") != table:
		player.global_position = home
		_web_smoke_d2_fail("The player scanner did not acquire the D2 Inscribing Table.")
		return null
	await _press_c2_world_interact()
	player.global_position = home
	await get_tree().process_frame
	for child in scene.get_children():
		if child.has_node("ChartTablePanel"):
			web_smoke_features["d2_world_interact_table"] = true
			return child
	_web_smoke_d2_fail("The real D2 Chart Table did not open through interact.")
	return null


func _press_d2_supply_control(bench: Node, material_id: String) -> bool:
	var panel := bench.get_node_or_null("ChartTablePanel")
	var view := panel.get_node_or_null("ChartTableView") if panel != null else null
	var supply := view.find_child("Supply_%s" % material_id, true, false) as Button \
		if view != null else null
	if supply == null or supply.disabled:
		return false
	supply.pressed.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	return true


func _verify_d2_layer_one() -> void:
	var cfg := run_cfg()
	if int(cfg.get("layer", 0)) != 1 or String(cfg.get("boss_kind", "")) != "" \
			or not cfg.get("required_room_roles", []).is_empty():
		_web_smoke_d2_fail("Reprise layer one was not the contract's boss-free first fold.")
		return
	web_smoke_report("reprise_layer_1")
	get_tree().create_timer(0.7).timeout.connect(_drive_d2_first_exit_waystone)


func _drive_d2_first_exit_waystone() -> void:
	await _wait_d2_stable_control("World")
	if web_smoke_phase == "failed":
		return
	var waystone := _find_d2_exit_waystone()
	if waystone == null or not await _interact_d2_world_node(waystone):
		_web_smoke_d2_fail("D2 could not reach the real first-layer Exit Waystone.")
		return
	var dialog := _find_d2_depth_choice_dialog()
	var deeper: Button = null
	if dialog == null:
		_web_smoke_d2_fail("The real Exit Waystone did not open its Far Waystone dialog.")
		return
	# The real dialog is paged: the Omen sits on page two and only then do the
	# Return/Deeper Controls appear. Advance it through the shipped interact
	# action after the ordinary input lockout instead of reaching into `_idx`.
	await get_tree().create_timer(0.3, true).timeout
	# Feed the same left-click event the released dialog accepts in `_input`.
	# `Input.action_press` is physics-edge based and Web can clear that edge before
	# this pause-immune dialog's idle process sees it.
	var advance_event := InputEventMouseButton.new()
	advance_event.button_index = MOUSE_BUTTON_LEFT
	advance_event.pressed = true
	advance_event.position = get_viewport().get_visible_rect().size * 0.5
	Input.parse_input_event(advance_event)
	await get_tree().process_frame
	advance_event.pressed = false
	Input.parse_input_event(advance_event)
	await get_tree().process_frame
	for button_v in dialog.find_children("*", "Button", true, false):
		var button := button_v as Button
		if button.text == "Press deeper":
			deeper = button
			break
	if deeper == null or deeper.text != "Press deeper":
		_web_smoke_d2_fail("The Far Waystone did not expose the real Press deeper Control.")
		return
	web_smoke_features["d2_real_exit_waystone"] = true
	web_smoke_report("exit_waystone")
	web_smoke_report("deepen_choice")
	_web_smoke_d2_stage = "layer_2"
	deeper.pressed.emit()
	web_smoke_features["d2_real_deepen_choice"] = true


func _verify_d2_layer_two() -> void:
	var cfg := run_cfg()
	if int(cfg.get("layer", 0)) != 2 or String(cfg.get("boss_kind", "")) != "hedgemother" \
			or cfg.get("required_room_roles", []) != ["rest"]:
		_web_smoke_d2_fail("Reprise layer two lost its terminal Hearth or Hedgemother contract.")
		return
	web_smoke_features["d2_layer_two_encounter_contract"] = true
	web_smoke_report("reprise_layer_2")
	get_tree().create_timer(0.7).timeout.connect(_drive_d2_terminal_hearth)


func _drive_d2_terminal_hearth() -> void:
	await _wait_d2_stable_control("World")
	if web_smoke_phase == "failed":
		return
	var hearth: Node3D = null
	for node_v in get_tree().get_nodes_in_group("interactable"):
		if node_v is Node3D and node_v.has_method("get_prompt_text") \
				and String(node_v.call("get_prompt_text")) == "[E] Rest":
			hearth = node_v as Node3D
			break
	if hearth == null or not await _interact_d2_world_node(hearth):
		_web_smoke_d2_fail("D2 terminal layer did not expose an interactable Hearth.")
		return
	await get_tree().process_frame
	var checkpoint := get_node_or_null("/root/Checkpoint")
	if checkpoint == null or not checkpoint.has_method("read") \
			or (checkpoint.call("read") as Dictionary).is_empty():
		_web_smoke_d2_fail("The terminal Hearth did not complete its real checkpoint interaction.")
		return
	var loadout_open := false
	for child in get_tree().current_scene.get_children():
		if child.has_method("_close") and child.has_node("TransactionShell"):
			loadout_open = true
			child.call("_close")
			break
	if not loadout_open:
		_web_smoke_d2_fail("The terminal Hearth did not open its real rest/loadout panel.")
		return
	web_smoke_features["d2_terminal_hearth_interaction"] = true
	web_smoke_report("terminal_hearth")
	get_tree().create_timer(0.35).timeout.connect(_drive_d2_reprise_boss)


func _drive_d2_reprise_boss() -> void:
	var boss: Node = null
	for foe in get_tree().get_nodes_in_group("enemy"):
		if String(foe.get("role")) == "boss" and String(foe.get("kind")) == "hedgemother":
			boss = foe
			break
	if boss == null or not boss.has_method("take_damage"):
		_web_smoke_d2_fail("The terminal Reprise World did not build Hedgemother.")
		return
	web_smoke_report("reprise_boss_world")
	var contract: Dictionary = active_chart.get("encounter_contract", {})
	var expected: Dictionary = Drops.select_first_knot_heirloom(int(contract.get("reward_seed", 0)))
	if expected.is_empty():
		_web_smoke_d2_fail("The Reprise had no valid seeded heirloom contract.")
		return
	boss.call("take_damage", int(boss.get("hp")) + 1, Vector3.ZERO)
	await get_tree().process_frame
	await get_tree().process_frame
	var heirlooms := 0
	for pickup_v in get_tree().current_scene.find_children("*", "ItemPickup", true, false):
		var item = pickup_v.get("_item")
		if item is Dictionary and String((item as Dictionary).get("rarity", "")) == "unique" \
				and String((item as Dictionary).get("kind_id", "")) == String(expected.get("kind_id", "")):
			heirlooms += 1
	if heirlooms != 1 or not claim_first_knot_reprise_reward(active_chart).is_empty():
		_web_smoke_d2_fail("The real Reprise death did not leave exactly one seeded heirloom.")
		return
	web_smoke_features["d2_exact_one_heirloom"] = true
	web_smoke_report("reprise_boss_cleared")
	get_tree().create_timer(0.35).timeout.connect(_drive_d2_final_exit_waystone)


func _drive_d2_final_exit_waystone() -> void:
	var waystone := _find_d2_exit_waystone()
	# The production return is deferred from the input frame and can make Town
	# ready before this coroutine resumes. Publish the expected route stage
	# before pressing the real Control so Town can verify the terminal return.
	_web_smoke_d2_stage = "reprise_return"
	if waystone == null or not await _interact_d2_world_node(waystone):
		_web_smoke_d2_fail("D2 could not use the real final Exit Waystone.")
		return


func _find_d2_exit_waystone() -> Node3D:
	for node_v in get_tree().get_nodes_in_group("interactable"):
		if node_v is Node3D and node_v.has_method("get_prompt_text") \
				and String(node_v.call("get_prompt_text")) == "[E] Step through the waystone":
			return node_v as Node3D
	return null


func _interact_d2_world_node(target: Node3D) -> bool:
	var player := local_player() as Node3D
	if player == null or target == null:
		return false
	var home := player.global_position
	# The boss-free far Waystone has a reward chest beside it. A single fixed
	# offset can therefore put the scanner closer to the chest than the stone,
	# even though both overlap. Try the four walk-up sides and accept only the
	# production scanner's exact target; never call the Interactable directly.
	var acquired := false
	for direction in [Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD, Vector3.BACK]:
		# Begin outside both detection spheres and cross the boundary over several
		# physics frames. Godot Web does not emit Area-entered when this QA driver
		# teleports from one already-overlapping position to another; an actual
		# walking approach (and this bounded interpolation) does.
		for step in 31:
			var distance := lerpf(4.0, 1.05, float(step) / 30.0)
			player.global_position = Vector3(
				target.global_position.x + direction.x * distance, home.y,
				target.global_position.z + direction.z * distance)
			await get_tree().physics_frame
			if player.get("_active_interactable") == target:
				acquired = true
				break
		if acquired:
			break
	if not acquired:
		player.global_position = home
		return false
	await _press_c2_world_interact()
	if is_instance_valid(player):
		player.global_position = home
	return true


func _wait_d2_stable_control(scene_label: String) -> void:
	var deadline := Time.get_ticks_msec() + 20000
	var stable_since := -1
	while Time.get_ticks_msec() < deadline:
		if not get_tree().paused and modal_count == 0:
			if stable_since < 0:
				stable_since = Time.get_ticks_msec()
			if Time.get_ticks_msec() - stable_since >= 500:
				return
		else:
			stable_since = -1
		await get_tree().create_timer(0.1, true).timeout
	_web_smoke_d2_fail(("The D2 %s never returned stable player control " \
		+ "(paused=%s, modal=%d).") % [scene_label, get_tree().paused, modal_count])


func _find_d2_depth_choice_dialog() -> Node:
	for child in get_tree().current_scene.get_children():
		if child.has_signal("choice_selected") and child.find_child("Choices", true, false) != null:
			return child
	return null


func _verify_d2_campaign_inert_return() -> void:
	if campaign_state != _web_smoke_d2_campaign_before \
			or material_count("tusker_tusk") != int(_web_smoke_d2_rewards_before.get("tusker_tusk", 0)) \
			or material_count("thorn_essence") != 0 \
			or (ledger != null and ledger.slots.has("tusker_tusk") \
				!= bool(_web_smoke_d2_rewards_before.get("ledger_tusker_tusk", false))):
		_web_smoke_d2_fail("The Reprise return changed campaign state, chain trophy, or refunded Thorn Essence.")
		return
	web_smoke_features["d2_campaign_inert_return"] = true
	web_smoke_features["d2_gameplay_driver"] = true
	web_smoke_report("reprise_return")
	web_smoke_report("complete")


func _web_smoke_d2_fail(reason: String) -> void:
	_web_smoke_d2_stage = "failed"
	web_smoke_report("failed", reason)

# Slice C2 release QA is intentionally a small automated playthrough rather
# than a state fixture. It earns the source gates through completed Charts,
# then uses the physical source Interactables, their real DialogPanel, and the
# real Chart Table/Codex Controls. The query is the only entry point: ordinary
# play never reaches this driver.
func _web_smoke_c2_scene_ready(scene_name: String) -> void:
	if scene_name == "Town":
		# Do not let the ordinary return debrief pause the query-gated driver. The
		# completed run, XP, source unlock, reward, and save have already happened.
		if _web_smoke_c2_stage == "deep_runs" \
				and not bool(web_smoke_features.get("deep_hollow_completed_return", false)):
			var note_status := chart_source_status("mara_sallow_reed")
			if String(pending_run_debrief.get("template_id", "")) != "hollow" \
					or in_dungeon or not active_chart.is_empty() \
					or not bool(note_status.get("unlocked", false)):
				_web_smoke_c2_fail("The committed Deep Hollow did not complete and unlock Mara's note.")
				return
			web_smoke_features["deep_hollow_completed_return"] = true
		pending_run_debrief = {}
		if _web_smoke_c2_stage == "":
			_web_smoke_c2_stage = "tier1_runs"
			web_smoke_report("town")
		get_tree().create_timer(0.55).timeout.connect(_continue_c2_web_smoke)
	elif scene_name == "World":
		if _web_smoke_c2_stage == "tier1_runs":
			web_smoke_report("world" if not web_smoke_history.has("world") \
				else "tier1_training")
		elif _web_smoke_c2_stage == "deep_runs":
			# The required sequence names the first genuine Deep Hollow World.
			web_smoke_report("world" if web_smoke_history.count("world") < 2 \
				else "deep_training")
		else:
			_web_smoke_c2_fail("A World opened outside a C2 Chart run.")
			return
		get_tree().create_timer(0.8).timeout.connect(func() -> void:
			return_to_town(local_player(), false))


func _continue_c2_web_smoke() -> void:
	if not web_smoke_c2_enabled or web_smoke_phase == "failed":
		return
	await _wait_c2_town_control()
	if web_smoke_phase == "failed":
		return
	match _web_smoke_c2_stage:
		"tier1_runs":
			# Accumulate the six ordinary Ink pots needed by the two source
			# experiments through the actual Town nodes. Each visit harvests at
			# most three patches via the player's scanner/controller path.
			await _gather_c2_ink_ingredients(3)
			if web_smoke_phase == "failed":
				return
			if not chart_table_first_snug_returned():
				# Earn the Binding cell and Green Hollow lesson through the real
				# successful Snug-return transaction before any Tier 1 training.
				_start_c2_chart_run("snug")
			elif trade_lv("wayfinding") < 10:
				_start_c2_chart_run("tier_1")
			else:
				if material_count("hedge_ink") + material_count("wild_herb") / 3 < 6:
					await _gather_c2_ink_ingredients(99)
				if web_smoke_phase == "failed":
					return
				if material_count("hedge_ink") + material_count("wild_herb") / 3 < 6:
					_web_smoke_c2_fail("The earned herb supply could not fund both experiments.")
					return
				_web_smoke_c2_stage = "atlas_source"
				_drive_c2_source("AtlasDeepRumourSource", "atlas_deep_hollow",
					"atlas_deep_source_control", "deep_hollow")
		"deep_runs":
			if trade_lv("wayfinding") < 12:
				_start_c2_chart_run("hollow")
			else:
				_web_smoke_c2_stage = "sallow_source"
				_drive_c2_source("MaraSallowRumourSource", "mara_sallow_reed",
					"mara_sallow_source_control", "sallow_mire")
		_:
			pass


func _wait_c2_town_control() -> void:
	# Arrival vignettes intentionally pause ordinary world Nodes. QA timers are
	# process-always, so wait for the same unpaused handoff a player receives
	# before starting any scanner or gather transaction.
	var deadline := Time.get_ticks_msec() + 20000
	var stable_since := -1
	while Time.get_ticks_msec() < deadline:
		if not get_tree().paused and modal_count == 0:
			if stable_since < 0:
				stable_since = Time.get_ticks_msec()
			# Town opens its arrival vignette with deferred calls. Require a full
			# second of stable control so that deferred modal cannot interrupt the
			# first production channel after this check returns.
			if Time.get_ticks_msec() - stable_since >= 1000:
				return
		else:
			stable_since = -1
		await get_tree().create_timer(0.1, true).timeout
	_web_smoke_c2_fail("Town never returned stable control after its arrival vignette.")


func _start_c2_chart_run(template_id: String) -> void:
	_web_smoke_c2_run_count += 1
	if _web_smoke_c2_run_count > 24:
		_web_smoke_c2_fail("C2 progression exceeded its completed-Chart safety bound.")
		return
	var chart := ChartsData.inscribe(template_id, [], trade_lv("wayfinding"),
		"", 0.0, 41000 + _web_smoke_c2_run_count)
	if chart.is_empty():
		_web_smoke_c2_fail("%s inscription returned empty." % template_id)
		return
	enter_dungeon(chart, local_player())


func _drive_c2_source(node_name: String, source_id: String,
		feature_name: String, codex_recipe_id: String) -> void:
	var scene := get_tree().current_scene
	var source := scene.get_node_or_null(node_name) if scene != null else null
	var player := local_player() as Node3D
	var before := chart_source_status(source_id)
	if source == null or not source.has_method("interact") \
			or not source.is_in_group("chart_rumour_source") or player == null:
		_web_smoke_c2_fail("The real %s Interactable was missing." % node_name)
		return
	if String(before.get("state", "invalid")) != "eligible":
		_web_smoke_c2_fail("%s was not eligible after earned progression." % node_name)
		return
	var player_home := player.global_position
	var source_pos := (source as Node3D).global_position
	# Travel the real scanner to the authored source instead of invoking its
	# method or moving the world prop into the player.
	player.global_position = Vector3(source_pos.x + 0.75, player_home.y, source_pos.z)
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	if player.get("_active_interactable") != source:
		player.global_position = player_home
		_web_smoke_c2_fail("The player scanner did not acquire %s." % node_name)
		return
	await _press_c2_world_interact()
	var dialog := scene.get_node_or_null("ChartRumourSourceDialog")
	if dialog == null or not dialog.is_in_group("ChartRumourSourceDialog") \
			or not dialog.has_method("_finish"):
		player.global_position = player_home
		_web_smoke_c2_fail("%s did not open its real source dialog." % node_name)
		return
	web_smoke_features["chart_rumour_source_dialog"] = true
	web_smoke_features["controller_source_binding"] = _c2_controller_a_is_bound()
	web_smoke_features["world_interact_action"] = true
	dialog.call("_finish")
	await get_tree().process_frame
	await get_tree().process_frame
	player.global_position = player_home
	var after := chart_source_status(source_id)
	if String(after.get("state", "invalid")) != "read" \
			or not bool(after.get("heard", false)):
		_web_smoke_c2_fail("%s did not record its Rumoured page on close." % node_name)
		return
	web_smoke_features[feature_name] = true
	web_smoke_report("atlas_deep_source" if source_id == "atlas_deep_hollow" \
		else "mara_sallow_source")
	await get_tree().create_timer(0.25).timeout
	await _verify_c2_codex_rumour(codex_recipe_id)


func _verify_c2_codex_rumour(recipe_id: String) -> void:
	var scene := get_tree().current_scene
	if scene == null:
		_web_smoke_c2_fail("The Chart Table could not open for C2 verification.")
		return
	var bench: Node = await _open_c2_chart_table()
	if bench == null or web_smoke_phase == "failed":
		return
	var panel: Node = bench.get_node_or_null("ChartTablePanel")
	var view: Node = panel.get_node_or_null("ChartTableView") if panel != null else null
	var codex_button := view.find_child("CodexButton", true, false) as Button \
		if view != null else null
	if codex_button == null:
		bench.close()
		_web_smoke_c2_fail("The real C2 Codex Control was missing.")
		return
	web_smoke_report("chart_table")
	codex_button.pressed.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	var page := view.find_child("CodexPage_%s" % recipe_id, true, false) as Button
	if page == null or not page.text.begins_with("Rumoured"):
		bench.close()
		_web_smoke_c2_fail("%s was not visibly Rumoured in Mara's Codex." % recipe_id)
		return
	page.pressed.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	var detail := view.find_child("CodexDetail", true, false) as RichTextLabel
	var selected: Dictionary = bench.call("selected_codex_page")
	var expected_source := "faded Atlas panel" if recipe_id == "deep_hollow" \
		else "rain-stained note"
	if detail == null or String(selected.get("recipe_id", "")) != recipe_id \
			or String(selected.get("state", "")) != "rumoured" \
			or expected_source not in detail.text:
		bench.close()
		_web_smoke_c2_fail("The Rumoured %s Codex detail was not source-specific." % recipe_id)
		return
	web_smoke_report("codex_deep_rumoured" if recipe_id == "deep_hollow" \
		else "codex_sallow_rumoured")
	await get_tree().create_timer(0.25).timeout
	# Return from the Codex page to the physical supplies/table surface, mix the
	# earned herbs in Quill's real pot, then stage every component and commit via
	# CraftingBench -> Game.try_inscribe_chart. This is the acceptance proof that
	# a Rumour is only a clue: knowledge must come from a table experiment.
	codex_button.pressed.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	var chart = await _inscribe_c2_rumoured_chart(bench, recipe_id)
	if web_smoke_phase == "failed":
		bench.close()
		return
	bench.close()
	await get_tree().process_frame
	web_smoke_report("chart_table_closed")
	if recipe_id == "deep_hollow":
		_web_smoke_c2_deep_chart = chart
		_web_smoke_c2_stage = "deep_runs"
		# The first Hollow entered here is the exact Chart just discovered and
		# committed above. Its successful return is what unlocks Mara's note.
		enter_dungeon(_web_smoke_c2_deep_chart, local_player())
	else:
		_web_smoke_c2_stage = "complete"
		web_smoke_features["c2_gameplay_driver"] = true
		web_smoke_report("complete")


func _press_c2_world_interact() -> void:
	# The Web runner has no physical Gamepad device, so Chromium can discard a
	# fabricated Joypad event before it reaches InputMap. Drive the same shipped
	# `interact` action that E/controller-A resolve to; transition tests separately
	# prove that literal JOY_BUTTON_A opens both authored rumour sources.
	Input.action_press(&"interact")
	await get_tree().physics_frame
	await get_tree().process_frame
	Input.action_release(&"interact")
	await get_tree().process_frame


func _c2_controller_a_is_bound() -> bool:
	for event in InputMap.action_get_events(&"interact"):
		if event is InputEventJoypadButton \
				and (event as InputEventJoypadButton).button_index == JOY_BUTTON_A:
			return true
	return false


func _open_c2_chart_table():
	var scene := get_tree().current_scene
	var player := local_player() as Node3D
	var tables := get_tree().get_nodes_in_group("inscribing_table")
	if scene == null or player == null or tables.size() != 1:
		_web_smoke_c2_fail("The authored Town Inscribing Table was missing.")
		return null
	var table := tables[0] as Node3D
	var player_home := player.global_position
	var table_pos := table.global_position
	player.global_position = Vector3(table_pos.x + 1.05, player_home.y, table_pos.z)
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	if player.get("_active_interactable") != table:
		player.global_position = player_home
		_web_smoke_c2_fail("The player scanner did not acquire the Inscribing Table.")
		return null
	await _press_c2_world_interact()
	player.global_position = player_home
	await get_tree().process_frame
	for child in scene.get_children():
		if child.has_node("ChartTablePanel"):
			web_smoke_features["controller_chart_table_open"] = true
			return child
	_web_smoke_c2_fail("Controller A did not open the real Town Chart Table.")
	return null
func _gather_c2_ink_ingredients(max_nodes: int) -> void:
	if material_count("hedge_ink") + material_count("wild_herb") / 3 >= 6:
		return
	var scene := get_tree().current_scene
	var player := local_player() as Node3D
	if scene == null or player == null:
		_web_smoke_c2_fail("Town gathering could not find its player or scene.")
		return
	var nodes: Array[Node3D] = []
	for candidate in get_tree().get_nodes_in_group("interactable"):
		if candidate is Node3D and String(candidate.get("kind")) == "forage_node" \
				and String(candidate.get("item_id")) == "wild_herb" \
				and not bool(candidate.call("is_used")):
			nodes.append(candidate as Node3D)
	if nodes.is_empty():
		_web_smoke_c2_fail("Town did not contain an authored Wild Herb patch.")
		return
	var player_home := player.global_position
	var harvested := 0
	for node in nodes:
		if harvested >= max_nodes \
				or material_count("hedge_ink") + material_count("wild_herb") / 3 >= 6:
			break
		# The query driver invokes the authored Interactable from the player's
		# stable spawn position. GatherNode's complete production channel still
		# owns cancellation, animation, depletion, material, and Trade-XP effects;
		# avoiding a teleport also avoids collision recovery cancelling the channel.
		player.set("velocity", Vector3.ZERO)
		var before := material_count("wild_herb")
		# Gathering itself is the production channel/harvest transaction. Source
		# and Table Controls have separate controller/scanner proofs below; calling
		# this Interactable directly avoids input-state races across rapid harvests
		# without ever seeding materials or skipping the one-second channel.
		node.call("interact", player)
		var channel_deadline := Time.get_ticks_msec() + 2500
		while material_count("wild_herb") <= before \
				and Time.get_ticks_msec() < channel_deadline:
			await get_tree().create_timer(0.1).timeout
		if material_count("wild_herb") <= before:
			player.global_position = player_home
			var start_pos: Vector3 = node.get("_channel_start_pos")
			_web_smoke_c2_fail(
				"A production Town forage channel did not finish " +
				"(channeling=%s used=%s paused=%s modal=%d moved=%.2f dead=%s)." % [
				bool(node.get("_channeling")), bool(node.call("is_used")),
				get_tree().paused, modal_count,
				player.global_position.distance_to(start_pos), bool(player.get("dead"))])
			return
		harvested += 1
		# The first real forage opens the normal one-time Wildcraft lesson. Close
		# that real Dialog before beginning another channel; otherwise its modal
		# correctly pauses GatherNode midway through the next harvest.
		if modal_count > 0:
			var lesson_closed := false
			for child in scene.get_children():
				if child.has_node("DialogueShell") and child.has_method("_finish"):
					child.call("_finish")
					lesson_closed = true
					break
			await get_tree().process_frame
			await get_tree().process_frame
			if not lesson_closed or modal_count > 0:
				_web_smoke_c2_fail("The real Wildcraft lesson did not return control.")
				return
	player.global_position = player_home
	await get_tree().physics_frame
	await get_tree().physics_frame
	web_smoke_features["production_town_gathering"] = true


func _inscribe_c2_rumoured_chart(bench: Node, recipe_id: String):
	if chart_recipe_known(recipe_id):
		_web_smoke_c2_fail("%s was Known before its table experiment." % recipe_id)
		return {}
	var recipe: Dictionary = ChartsData.CHART_RECIPES.get(recipe_id, {})
	if recipe.is_empty():
		_web_smoke_c2_fail("The %s authored experiment was missing." % recipe_id)
		return {}
	var panel := bench.get_node_or_null("ChartTablePanel")
	var view := panel.get_node_or_null("ChartTableView") if panel != null else null
	var mix_tab := view.find_child("MixTab", true, false) as Button if view != null else null
	if mix_tab == null:
		_web_smoke_c2_fail("The real Chart Table Mix Ink Control was missing.")
		return {}
	mix_tab.pressed.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	# Mix enough ordinary Ink for this commit by pressing the refreshed Wild
	# Herb supply Control three times per pot. The known recipe auto-mixes.
	while material_count("hedge_ink") < 3:
		var herb_before := material_count("wild_herb")
		var ink_before := material_count("hedge_ink")
		for _i in range(3):
			if not await _press_c2_supply_control(bench, "wild_herb"):
				_web_smoke_c2_fail("The Chart Table pot rejected an earned wild herb.")
				return {}
		if material_count("wild_herb") != herb_before - 3 \
				or material_count("hedge_ink") != ink_before + 1:
			_web_smoke_c2_fail("The physical Ink pot did not consume three herbs.")
			return {}
	web_smoke_features["chart_table_ink_mixing"] = true
	var supplies_tab := view.find_child("SuppliesTab", true, false) as Button
	if supplies_tab == null:
		_web_smoke_c2_fail("The real Chart Table Supplies Control was missing.")
		return {}
	supplies_tab.pressed.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	# Each component kind owns one unlocked target here, so supply Controls stage
	# the exact authored c/n/w arrangement without a QA-only draft mutation.
	for slot_v in (recipe.pattern as Dictionary):
		var component_id := String((recipe.pattern as Dictionary)[slot_v])
		var staged := false
		# A zero-count renewable row may spend its first press at the counter
		# before the rebuilt row becomes stageable. Re-find and press the real
		# Control once more only when the draft proves the first press did not land.
		for _attempt in range(2):
			if not await _press_c2_supply_control(bench, component_id):
				break
			if (bench.get("draft").get("grid", {}) as Dictionary).values() \
					.has(component_id):
				staged = true
				break
		if not staged:
			_web_smoke_c2_fail("The Chart Table rejected the %s Control." % component_id)
			return {}
	var preview: Dictionary = bench.call("current_preview")
	if String(preview.get("recipe_id", "")) != recipe_id \
			or String(preview.get("state", "")) != "attemptable" \
			or not bool(preview.get("commit_ready", false)) \
			or not (preview.get("normalized_draft", {}) as Dictionary) \
				.get("ink_rail", []).is_empty():
		_web_smoke_c2_fail(
			"The staged %s experiment was not commit-ready " % recipe_id +
			"(id=%s state=%s ready=%s draft=%s reason=%s)." % [
			String(preview.get("recipe_id", "")), String(preview.get("state", "")),
			bool(preview.get("commit_ready", false)), str(bench.get("draft")),
			String(preview.get("reason", ""))])
		return {}
	var costs: Dictionary = preview.get("costs", {})
	var before_counts := {}
	for material_id_v in costs:
		var material_id := String(material_id_v)
		before_counts[material_id] = material_count(material_id)
	var chart_count := charts.size()
	var action := view.find_child("InscribeChartButton", true, false) as Button
	if action == null or action.disabled:
		_web_smoke_c2_fail("The physical Inscribe Chart Control was not enabled for %s." % recipe_id)
		return {}
	action.pressed.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	if charts.size() != chart_count + 1 or not chart_recipe_known(recipe_id) \
			or String((chart_recipe_journal.get("discoveries", {}) as Dictionary)
				.get(recipe_id, "")) != "table_experiment":
		_web_smoke_c2_fail("%s did not become Known through table_experiment." % recipe_id)
		return {}
	for material_id_v in costs:
		var material_id := String(material_id_v)
		if material_count(material_id) != int(before_counts[material_id]) \
				- int(costs[material_id_v]):
			_web_smoke_c2_fail("%s did not consume its staged %s cost." %
				[recipe_id, material_id])
			return {}
	var chart: Dictionary = charts.back()
	if String(chart.get("template_id", "")) \
			!= String((recipe.output as Dictionary).get("template_id", "")):
		_web_smoke_c2_fail("%s committed the wrong Chart output." % recipe_id)
		return {}
	web_smoke_features["%s_table_experiment" % recipe_id] = true
	return chart


func _press_c2_supply_control(bench: Node, material_id: String) -> bool:
	var panel := bench.get_node_or_null("ChartTablePanel")
	var view := panel.get_node_or_null("ChartTableView") if panel != null else null
	var supply := view.find_child("Supply_%s" % material_id, true, false) as Button \
		if view != null else null
	if supply == null or supply.disabled:
		return false
	supply.pressed.emit()
	# Source rows rebuild after every placement; callers must never retain the
	# old Button and this helper deliberately re-finds it on each invocation.
	await get_tree().process_frame
	await get_tree().process_frame
	return true


func _web_smoke_c2_fail(reason: String) -> void:
	_web_smoke_c2_stage = "failed"
	web_smoke_report("failed", reason)

# New Game — wipe progress back to a fresh start and clear the save, so a
# friend (or a fresh run) isn't stranded by a finished/stuck session. Mirrors
# the persisted fields exactly; the caller reloads Town.tscn so the player +
# town pick up the new shared inventory/equipment/ledger. Preferences (muted)
# are intentionally preserved — this resets PROGRESS, not settings.
func reset_to_defaults() -> void:
	start_onboarding_measurement()
	trades = Progression.fresh_trade_state()
	materials = {}
	charts = []
	gold = 0
	summit_cleared = false
	owned_skills = []
	loadout = []
	chosen_perks = {}
	seen_hints = {}
	second_hand_clues = []
	pending_run_debrief = {}
	_homecoming_return_was_d2_reprise = false
	player_hp = -1
	active_chart = {}
	pending_run_layout = {}
	in_dungeon = false
	tutorial_step = 0
	discovered_inks = ["hedge_ink"]
	known_chart_recipes = ChartsData.starting_recipe_ids()
	chart_recipe_journal = ChartsData.fresh_recipe_journal()
	chart_source_unlocks = []
	campaign_state = CampaignData.empty_state()
	_campaign_recovery_dirty = false
	discovered_enchants = []
	buffs = {}
	chart_table_version = CHART_TABLE_VERSION
	ensure_chart_starter_supplies()
	# Fresh shared objects (the live player rebinds on the town reload).
	inventory = Inventory.new()
	equipment = load("res://scripts/equipment.gd").new()
	_connect_equipment()   # enchant skill-grants: keep the loadout valid on gear swaps
	ledger = load("res://scripts/ledger.gd").new()
	if persistence_enabled:
		SaveGame.clear()
	# Refresh every listener.
	materials_changed.emit()
	charts_changed.emit()
	gold_changed.emit(gold)
	perks_changed.emit()
	tutorial_changed.emit(tutorial_step)


# New Journey enters the bounded playable slice. Existing saves retain their
# current onboarding; this marker only changes a freshly reset journey.
func start_first_road() -> void:
	seen_hints["first_road_slice"] = true
	tutorial_step = 0
	mark_onboarding_progress()
	tutorial_changed.emit(tutorial_step)
	save_now()


func first_road_active() -> bool:
	return bool(seen_hints.get("first_road_slice", false))


func choose_first_road(choice: int) -> bool:
	if not first_road_active() or String(seen_hints.get("first_road_profile", "")) != "":
		return false
	var profile_id := FirstRoadData.profile_id_for_choice(choice)
	var chart := FirstRoadData.make_chart(profile_id)
	if chart.is_empty():
		return false
	seen_hints["first_road_profile"] = profile_id
	tutorial_step = 4
	charts.append(chart)
	charts_changed.emit()
	tutorial_changed.emit(tutorial_step)
	seen_hints["affix_reading"] = true
	notify("Mara set %s in your chart case." % String(chart.name))
	mark_onboarding_progress()
	save_now()
	return true

# Quitting the window saves whatever the moment held. Closing mid-run keeps
# the chart consumed (keystone V1 ruling) — the save reopens in town.
func _exit_tree() -> void:
	# A tab/window teardown may bypass the terminal smoke report. Returning the
	# lease here keeps editor/native harnesses honest and leaves no global clock
	# mutation if this autoload is replaced.
	_d7_restore_simulation_clock("exit_tree")


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and persistence_enabled:
		SaveGame.save(self)

# ---- persistent player-adjacent state ----
var trades: Dictionary = Progression.fresh_trade_state()
var materials: Dictionary = {}        # material id -> count
var charts: Array = []                # crafted chart dicts (the chart case)
var campaign_state: Dictionary = CampaignData.empty_state()
# Set only by save-load reconciliation. SaveGame consumes this flag after it
# atomically persists the refunded escrow tombstone.
var _campaign_recovery_dirty := false
const CHART_TABLE_VERSION := 1
var chart_table_version := 0          # optional-save migration marker (Slice B)
var gold := 0                         # Hod's the faucet AND the sink
var summit_cleared := false           # the final chart, charted
var muted := true                     # spec 38 — master mute (persisted).
                                      # Default ON: fresh games start silent
                                      # (user 2026-06-12); F10 opts in.
# Basic Shot is the only fresh-game combat action. Focus Skills are owned
# permanently when taught, then independently equipped into the three slots.
var SKILL_POOL: Array = Progression.focus_skill_ids()
var owned_skills: Array = []
var loadout: Array = []

func skill_owned(skill_id: String) -> bool:
	return Progression.canonicalize_owned_skills(owned_skills).has(skill_id)

func skill_unlocked(skill_id: String) -> bool:
	if skill_id == Progression.BASIC_SHOT:
		return true
	if Progression.is_focus_skill(skill_id):
		return skill_owned(skill_id)
	return Progression.is_gear_granted_skill(skill_id) and granted_skills().has(skill_id)
# 2026-07-02 — a pinned quick-use consumable for the Q slot, set by dragging a
# draught from the bag onto the Spell Book's Q slot. "" = auto (drink the best
# available, the legacy behaviour).
var quick_item: String = ""
signal quick_item_changed

# Pin a bag consumable to the Q slot (or "" to clear back to auto). Validates it
# is a known draught the recipe book carries.
func set_quick_item(id: String) -> bool:
	if id != "" and not (CraftingDefs.DRAUGHT_ORDER.has(id) \
			or CraftingDefs.BUFF_DRAUGHT_ORDER.has(id)):
		return false
	quick_item = id
	save_now()
	quick_item_changed.emit()
	if is_inside_tree():
		notify("Quick-use set: %s." % GatherDefs.material_name(id) if id != "" \
			else "Quick-use cleared.")
	return true
# Reserved mastery picks, keyed by Trade and perk id. Current authored tiers
# each contain one automatic perk; this stays empty until a real choice tier is
# designed and tested.
var chosen_perks: Dictionary = {}
var seen_hints: Dictionary = {}       # one-time skill tutorials already shown
# Spec 55 — observed evidence only. The answer behind the Second Hand is
# deliberately absent; the save records what the player actually found.
const SECOND_HAND_CLUE_IDS := ["far_waystone", "inked_scrap"]
var second_hand_clues: Array = []
var inventory: Inventory = null       # Tetris gear grid — shared across scenes
var equipment = null                  # Equipment — shared across scenes
var ledger: RefCounted = null         # ADR 0013 — boss-trophy stat boosts
var player_hp := -1                   # -1 = "full" (first boot)

# ---- the active run ----
var active_chart: Dictionary = {}     # {} = not in a chart run (town / dev boot)
var pending_run_layout: Dictionary = {} # generated once behind the loading card
var in_dungeon := false
var _returning_from_delve := false    # B7 — town plays an arrival beat when set
var _run_start_snapshot: Dictionary = {}
var pending_run_debrief: Dictionary = {}
# Set immediately before the returned Chart is cleared. This is intentionally
# not persisted: it only prevents a D2 Reprise arrival from presenting the
# First Knot Homecoming event in this Town session.
var _homecoming_return_was_d2_reprise := false
# D2 replay loot is an in-run world event, not a saved progression reward.
# Keep the exact-once guard outside the immutable materialized Chart.
var _reprise_reward_claims: Dictionary = {}


# MapLoading calls this after its first visible frame. The exact generated
# layout then serves both the loading overview and LayoutLoader, preventing a
# cosmetic preview from rolling a different road than the player enters.
func prepare_map_layout(scene_path: String) -> Dictionary:
	if scene_path != DUNGEON_SCENE or active_chart.is_empty():
		pending_run_layout = {}
		return pending_run_layout
	var cfg := run_cfg()
	pending_run_layout = DungeonGenScript.generate(int(cfg.get("seed", -1)), cfg)
	return pending_run_layout


func take_pending_run_layout() -> Dictionary:
	var layout := pending_run_layout
	pending_run_layout = {}
	return layout


func _travel_to_map(scene_path: String) -> void:
	# Headless suites have no loading presentation and intentionally retain the
	# historical one-deferred-frame transition contract used by their harness.
	if DisplayServer.get_name() == "headless":
		get_tree().change_scene_to_file.call_deferred(scene_path)
		return
	var loader := get_node_or_null("/root/MapLoading")
	if loader != null and loader.has_method("travel_to"):
		loader.call_deferred("travel_to", scene_path)
	else:
		get_tree().change_scene_to_file.call_deferred(scene_path)

func has_second_hand_clue(clue_id: String) -> bool:
	return second_hand_clues.has(clue_id)

func second_hand_clue_count() -> int:
	return second_hand_clues.size()

# Returns true only when this interaction added new observed evidence.
func observe_second_hand(clue_id: String) -> bool:
	if not SECOND_HAND_CLUE_IDS.has(clue_id) or second_hand_clues.has(clue_id):
		return false
	second_hand_clues.append(clue_id)
	story_changed.emit()
	if clue_id == "far_waystone":
		notify("A hooked mark has been cut beside the far Waystone.")
	else:
		notify("The same hooked hand appears again — drawn in your own ink.")
	save_now()
	return true

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
	# D14 — first-contact explainers for the systems players hit blind.
	"shrine": ["Mara Linnet, the Wayfinder", [
		"A wayshrine. Touch it and choose a boon — they hold until the run ends.",
		"Some ask a small price for a larger gift. Read each before you pick; the shrine won't ask twice.",
	]],
	"status_bleed": ["Mara Linnet, the Wayfinder", [
		"You're bleeding — vigor drains a little each beat until it fades.",
		"A Mothmint draught closes scratches as you walk. Keep one on your hip for the deeper hollows.",
	]],
	"status_slow": ["Mara Linnet, the Wayfinder", [
		"Rooted — thorns have your boots. You'll move slow till it lets go.",
		"A Quickroot tonic shakes off the snare; or just weather it and keep loosing arrows.",
	]],
	"affix_reading": ["Mara Linnet, the Wayfinder", [
		"That chart carries affixes — good twins help you, bad twins bite. The colour tells which.",
		"Stronger affixes pay more chart XP but harden the den. Read them at the Waystone before you socket.",
	]],
}

func first_time_hint(kind: String) -> void:
	_first_time_hint(kind, true)

func _first_time_hint(kind: String, persist: bool) -> void:
	if seen_hints.get(kind, false) or not SKILL_HINTS.has(kind):
		return
	seen_hints[kind] = true
	if persist:
		save_now()
	# Null-safe for headless / standalone Game (no tree, no current scene): the
	# hint counts as seen, we just can't pop the dialog.
	if not is_inside_tree():
		return
	var tree := get_tree()
	if tree == null or tree.current_scene == null:
		return
	var hint: Array = SKILL_HINTS[kind]
	var dlg: CanvasLayer = load("res://scripts/ui/dialog_panel.gd").new()
	dlg.open(String(hint[0]), hint[1])
	tree.current_scene.add_child(dlg)

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

# First-session combat disclosure. The loadout remains persisted as three
# picks, but the player only has to read the verbs the tutorial has taught:
# Bow for the first Snug, one Focus skill on return, then the full bar after
# the first Tier 1 Hollow is complete.
func active_skill_slots() -> int:
	if tutorial_step <= 5:
		return 1
	if not bool(seen_hints.get("tier1_completed", false)):
		return 2
	return 4

# Spec 57 progressive disclosure. The HUD and key handlers share this one
# contract so a hidden menu cannot still be opened by knowing its shortcut.
func onboarding_surface_available(surface: String) -> bool:
	# UI capture/dev work must be able to open a requested panel on a fresh
	# state without mutating tutorial progress first.
	if OS.get_environment("WYRD_UI_SHOT") != "":
		return true
	match surface:
		"combat":
			# Health + Bow arrive with actual danger. After the first return they
			# remain visible in town because the player now owns combat power.
			return in_dungeon or tutorial_step >= 6
		"focus":
			return active_skill_slots() > 1
		"satchel":
			# The case becomes useful when a finished Chart exists.
			return tutorial_step >= 4
		"gear", "trades":
			return tutorial_step >= 6
		_:
			return true

func in_first_snug_lesson() -> bool:
	return in_dungeon and tutorial_step == 5 \
		and String(active_chart.get("template_id", "")) in ["snug", "first_road"]

func record_onboarding_combat_action(action: String) -> void:
	if not in_first_snug_lesson():
		return
	var key := "snug_basic_shot" if action == "basic_shot" \
		else "snug_roll" if action == "roll" else ""
	if key == "" or bool(seen_hints.get(key, false)):
		return
	# The roll lesson follows the shot lesson; an exploratory roll before the
	# player sees its prompt does not silently consume the teaching beat.
	if action == "roll" and not bool(seen_hints.get("snug_basic_shot", false)):
		return
	seen_hints[key] = true
	mark_onboarding_progress()
	save_now()

func complete_power_shot_practice() -> void:
	if tutorial_step != 6 or bool(seen_hints.get("power_shot_practiced", false)):
		return
	seen_hints["power_shot_practiced"] = true
	mark_onboarding_progress()
	notify("Power Shot learned — one telling hit for 20 Focus.")
	save_now()

func objective_hint() -> String:
	if in_dungeon:
		if in_first_snug_lesson():
			if not bool(seen_hints.get("snug_basic_shot", false)):
				return "F or 1 — loose a Basic Shot"
			if not bool(seen_hints.get("snug_roll", false)):
				return "Move before it pinches · Space — roll clear"
		return "F loose · Space roll · follow the gold needle"
	# Town starts quiet. At 20 seconds the hint names the visual landmark; only
	# after a longer stall does it spell out the control and reveal the needle.
	match tutorial_step:
		0:
			if _onboarding_hint_stage == 0: return "WASD move · E talk"
			if _onboarding_hint_stage == 1: return "Mara waits beside the teal worktable"
			if _onboarding_hint_stage >= 2: return "WASD move · follow the gold needle · E talk"
		1:
			if _onboarding_hint_stage == 1: return "Look for the shimmering herb patches"
			if _onboarding_hint_stage >= 2: return "E forage · the nearest fresh patch is marked"
		2:
			if _onboarding_hint_stage == 1: return "Mara's table has begun to glow"
			if _onboarding_hint_stage >= 2: return "Follow the gold needle · E use the table"
		3:
			if _onboarding_hint_stage == 1: return "The Snug base is the only road you need"
			if _onboarding_hint_stage >= 2: return "Set the Snug base · take the finished Chart"
		4:
			if _onboarding_hint_stage == 1: return "The Waystone answered your finished Chart"
			if _onboarding_hint_stage >= 2: return "Follow the gold needle · E socket the Chart"
		6:
			if not bool(seen_hints.get("power_shot_practiced", false)):
				return "2 — Power Shot · the practice bramble cannot hurt you"
			if _onboarding_hint_stage == 1: return "Tier 1 and Hedge Ink are waiting at Mara's table"
			if _onboarding_hint_stage >= 2: return "Set Tier 1 · add Hedge Ink · inscribe"
		_: return ""
	return ""

func _ready() -> void:
	# Spec 53 — make IM Fell English the project default face before any UI builds,
	# so unstyled Labels stop rendering the engine's Open-Sans.
	WyrdUi.apply_defaults()
	WyrdUi.preload_kit()   # cache painted UI textures before any panel _draw
	_check_web_persistence()
	_configure_web_smoke()
	# Inventory/Equipment classes come from the existing spec-27 scripts.
	inventory = Inventory.new()
	var EquipmentScript = load("res://scripts/equipment.gd")
	equipment = EquipmentScript.new()
	_connect_equipment()   # enchant skill-grants: keep the loadout valid on gear swaps
	ledger = load("res://scripts/ledger.gd").new()   # ADR 0013 — before load_into restores it
	# Wyrd — restore the last session before anything else reads state.
	if OS.get_environment("WYRD_NO_SAVE") != "":
		persistence_enabled = false
	elif SaveGame.load_into(self):
		print("[game] session restored (tutorial step %d)" % tutorial_step)
	# Missing first-road pieces recover free until the Snug has been walked
	# home, preventing a fresh zero-gold save from soft-locking at the table.
	ensure_chart_starter_supplies()
	AudioServer.set_bus_mute(0, muted)   # spec 38 — restore the mute state
	mastery_choice_ready.connect(_on_mastery_choice_ready)   # ADR 0012 mastery modal
	# Spec 41 — the kit cursor takes over in-game (interact/attack swaps
	# are a followup; the controller can call set_cursor as states land).
	if ResourceLoader.exists("res://assets/ui/cursor_default.png"):
		Input.set_custom_mouse_cursor(load("res://assets/ui/cursor_default.png"),
			Input.CURSOR_ARROW, Vector2(3, 2))
	# Dev: WYRD_DEV_LEVEL=<n> sets Wayfinding on boot — for eyeballing
	# chart gates and ADR-0013 difficulty bands at any level.
	var dev_level := OS.get_environment("WYRD_DEV_LEVEL")
	if dev_level != "":
		var dl: int = clampi(int(dev_level), 1, Progression.LEVEL_CAP)
		trades.wayfinding.lv = dl
		trades.wayfinding.xp = xp_for_level(dl)
	# Bounded slice routes: kind/bold boot directly into the chosen road;
	# returned boots the physical yard payoff for deterministic review.
	var dev_first_road := OS.get_environment("WYRD_DEV_FIRST_ROAD")
	if dev_first_road in FirstRoadData.PROFILE_ORDER:
		active_chart = FirstRoadData.make_chart(dev_first_road)
		seen_hints["first_road_slice"] = true
		seen_hints["first_road_profile"] = dev_first_road
		in_dungeon = true
		tutorial_step = 5
		_travel_to_map(DUNGEON_SCENE)
	elif dev_first_road == "choice":
		seen_hints["first_road_slice"] = true
		tutorial_step = 0
	elif dev_first_road == "returned":
		seen_hints["first_road_slice"] = true
		seen_hints["first_road_profile"] = "kind"
		seen_hints["first_road_completed"] = true
		tutorial_step = 6
	# Dev: WYRD_DEV_CHART=<template_id> boots straight into a chart run with
	# every gather affix landed good — visual checks without the town loop.
	var dev_chart := OS.get_environment("WYRD_DEV_CHART")
	if dev_first_road == "" and dev_chart != "" and ChartsData.TEMPLATES.has(dev_chart):
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
		_travel_to_map(DUNGEON_SCENE)

# Swap the configured Focus-Skill loadout. Basic Shot is innate and does not
# occupy one of the three slots. Gear grants are transient and therefore do
# not persist in this entitlement loadout.
func set_loadout(picks: Array) -> bool:
	if picks.size() > 3:
		return false
	var seen := {}
	for sk in picks:
		var skill_id := String(sk)
		if not skill_owned(skill_id) or seen.has(skill_id):
			return false
		seen[skill_id] = true
	loadout = picks.duplicate()
	save_now()
	if is_inside_tree():
		var player := local_player()   # co-op: rebuild the LOCAL player's skills
		if player != null and player.has_method("rebuild_skills"):
			player.rebuild_skills()
		notify("Loadout set: %s." % ", ".join(picks))
	return true

# ---- enchants (skills-on-items) ----------------------------------------
# A charm bound into gear at the Charm Table (data/enchants.gd). Three kinds:
# `stat` sums into player stats like an affix, `on_hit` rides every shot,
# `skill_grant` makes a new hotbar skill slottable while the weapon is worn.
# Source is mixed: common charms are always bindable, rare/unique ones must be
# DISCOVERED first (drops). Binding is swappable and costs reagents each time.

# Skill names that ONLY exist via a granting enchant (never in the base pool).
# Registered in player_controller.SKILL_FACTORY so rebuild_skills can build them.
const GRANT_SKILLS := ["Galecall", "Wyrdvolley"]

# True if the player may bind this charm at all (exists + tier-gated source).
func enchant_available(id: String) -> bool:
	if not EnchantDefs.exists(id):
		return false
	return EnchantDefs.is_common(id) or discovered_enchants.has(id)

# Every charm the player can currently bind (commons + discovered), in catalogue
# order — the Charm Table list.
func known_enchant_ids() -> Array:
	return (EnchantDefs.ENCHANT_ORDER as Array).filter(func(id):
		return enchant_available(String(id)))

# Learn a rare/unique charm (idempotent). Called from the drop pipe.
func discover_enchant(id: String) -> void:
	if not EnchantDefs.exists(id) or EnchantDefs.is_common(id):
		return
	if discovered_enchants.has(id):
		return
	discovered_enchants.append(id)
	notify("You've puzzled out a new charm: %s." % EnchantDefs.display_name(id))
	save_now()

# Skill names currently granted by bound enchants on EQUIPPED gear.
func granted_skills() -> Array:
	var out: Array = []
	if equipment == null:
		return out
	for slot in Equipment.SLOT_ORDER:
		var it = equipment.get_slot(slot)
		if it == null:
			continue
		for eid in it.get("enchants", []):
			if EnchantDefs.kind(String(eid)) == "skill_grant":
				var g := EnchantDefs.granted_skill(String(eid))
				if g != "" and not out.has(g):
					out.append(g)
	return out

# The loadout picker only exposes permanent owned Focus Skills. Gear-granted
# Skills remain available to combat while equipped, but cannot fossilize into
# a save or occupy a permanent slot.
func available_skills() -> Array:
	return Progression.canonicalize_owned_skills(owned_skills)

# Validate a prospective bind. Returns {"ok": bool, "reason": String}.
func can_bind_enchant(item: Dictionary, enchant_id: String, replace_index: int = -1) -> Dictionary:
	if item == null or item.is_empty():
		return {"ok": false, "reason": "No item."}
	if not EnchantDefs.exists(enchant_id):
		return {"ok": false, "reason": "No such charm."}
	if not enchant_available(enchant_id):
		return {"ok": false, "reason": "You haven't puzzled that charm out yet."}
	var cat := String(item.get("category", ""))
	if not EnchantDefs.allowed_for(enchant_id, cat):
		return {"ok": false, "reason": "That charm won't take on this."}
	var cur: Array = item.get("enchants", [])
	# No binding the same charm twice on one piece (unless we're replacing it).
	for i in cur.size():
		if String(cur[i]) == enchant_id and i != replace_index:
			return {"ok": false, "reason": "Already wears that charm."}
	if replace_index < 0:
		var cap := ItemsData.enchant_slots(String(item.get("kind_id", "")))
		if cur.size() >= cap:
			return {"ok": false, "reason": "No free charm slot — swap one out first."}
	elif replace_index >= cur.size():
		return {"ok": false, "reason": "No charm in that slot to swap."}
	if not can_afford(EnchantDefs.cost(enchant_id)):
		return {"ok": false, "reason": "Not enough reagents."}
	return {"ok": true, "reason": ""}

# Bind a charm into `item` (append, or replace the slot at replace_index).
# Spends reagents; refreshes stats + the loadout. Returns success.
func bind_enchant(item: Dictionary, enchant_id: String, replace_index: int = -1) -> bool:
	var chk := can_bind_enchant(item, enchant_id, replace_index)
	if not bool(chk.ok):
		notify(String(chk.reason))
		return false
	if not spend_materials(EnchantDefs.cost(enchant_id)):
		return false   # race guard; can_afford already passed
	if not item.has("enchants"):
		item["enchants"] = []
	if replace_index >= 0:
		(item["enchants"] as Array)[replace_index] = enchant_id
	else:
		(item["enchants"] as Array).append(enchant_id)
	_refresh_after_enchant(item)
	notify("Bound %s into the %s." % [EnchantDefs.display_name(enchant_id),
		String(item.get("name", item.get("kind_name", "gear")))])
	return true

# Strip the charm in `index` (no reagent refund — the makings are spent).
func unbind_enchant(item: Dictionary, index: int) -> bool:
	var cur: Array = item.get("enchants", [])
	if index < 0 or index >= cur.size():
		return false
	var removed := String(cur[index])
	cur.remove_at(index)
	_refresh_after_enchant(item)
	notify("Drew the %s back out." % EnchantDefs.display_name(removed))
	return true

# Re-derive stats (on-hit/stat charms) + re-validate the loadout (skill-grant
# charms) + persist. equipment.changed drives the player's _derive_stats and
# our _sanitize_loadout; we save regardless since inventory items count too.
func _refresh_after_enchant(_item: Dictionary) -> void:
	if equipment != null:
		equipment.changed.emit()
	else:
		_sanitize_loadout()
	save_now()

# Drop invalid or duplicated persisted picks. There is intentionally no
# backfill: a fresh player has Basic Shot only until a lesson grants a Skill.
func _sanitize_loadout() -> void:
	var normalized := Progression.canonicalize_loadout(loadout, owned_skills)
	if normalized != loadout:
		loadout = normalized
		save_now()
		if is_inside_tree():
			var player := local_player()
			if player != null and player.has_method("rebuild_skills"):
				player.rebuild_skills()

func _on_equipment_changed() -> void:
	# Gear grants are transient: rebuild skills for the local player on every
	# swap, while `_sanitize_loadout` only touches persisted owned Focus Skills.
	_sanitize_loadout()
	if not is_inside_tree():
		return
	var player := local_player()
	if player != null and player.has_method("rebuild_skills"):
		player.rebuild_skills()

# Re-called after reset/new-game replaces the equipment object.
func _connect_equipment() -> void:
	if equipment != null and not equipment.changed.is_connected(_on_equipment_changed):
		equipment.changed.connect(_on_equipment_changed)

# Spec 38 — master mute. One bus flip silences the SFX pool and the music
# channel together; the state rides the save like any other preference.
func set_muted(m: bool) -> void:
	muted = m
	AudioServer.set_bus_mute(0, muted)
	mute_changed.emit(muted)
	save_now()

# ---- trades (leveling) ----

static func xp_for_level(n: int) -> int:
	return Progression.xp_for_level(n)

const LEVEL_CAP := Progression.LEVEL_CAP

# Runtime callers must name one canonical Trade. Legacy save aliases are
# accepted only by Progression.normalize_save_to_v2 during persistence repair.
func trade_lv(trade_key: String) -> int:
	var key := Progression.require_runtime_trade_key(trade_key)
	if key == "":
		return 1
	var record: Dictionary = trades.get(key, Progression.fresh_trade_record())
	return int(Progression.normalize_trade_record(record).get("lv", 1))

# The Tetris pack grows a row at level milestones (lv 6 → 7 rows, lv 12 → 8).
# Idempotent — safe to call on every level-up and once on load.
func grow_pack_for_level() -> void:
	if inventory == null:
		return
	var lv := trade_lv("wayfinding")
	if lv >= 12 and inventory.rows < 8:
		inventory.resize(8)
	elif lv >= 6 and inventory.rows < 7:
		inventory.resize(7)

func award_xp(trade_key: String, amount: int, source: String = "") -> void:
	var key := Progression.require_runtime_trade_key(trade_key)
	if key == "" or amount <= 0:
		return
	# A guest consumes the host snapshot, so only host/offline Wayfinding gains
	# can alter the Loom projection.  Keep a full copied presentation fingerprint
	# to avoid a network update for ordinary XP that does not change it.
	var loom_before: Dictionary = _threefold_loom_projection_fingerprint() \
		if key == "wayfinding" and _campaign_is_authority() else {}
	var before_xp := int((trades.get(key, {}) as Dictionary).get("xp", 0))
	var before := trade_lv(key)
	trades[key] = Progression.award_trade_xp(
		trades.get(key, Progression.fresh_trade_record()), amount)
	if key == "wayfinding":
		_d7_record_wayfinding_award(source, amount, before_xp,
			int((trades.get(key, {}) as Dictionary).get("xp", 0)))
	xp_gained.emit(key, amount)
	var after := trade_lv(key)
	for level in range(before + 1, after + 1):
		leveled_up.emit(key, level)
		notify("%s rises to %d" % [TRADE_NAMES.get(key, key), level])
		var unlock := Progression.unlock_for_trade_level(key, level)
		var skill_id := String(unlock.get("skill_id", ""))
		# Basic Shot is innate. Every authored Focus-Skill unlock confers
		# ownership at its Trade level, while onboarding separately decides when
		# the first lesson equips Power Shot.
		if skill_id != "" and skill_id not in [Progression.BASIC_SHOT, "WayfindersMark"]:
			grant_skill(skill_id)
		var sfx_lv := get_node_or_null("/root/Sfx") if is_inside_tree() else null
		if sfx_lv != null:
			sfx_lv.play("level_up")
		if perks_at_level(level, key).size() > 1 and not tier_chosen(key, level):
			mastery_choice_ready.emit(key, level)
	if key == "wayfinding":
		grow_pack_for_level()   # pack growth belongs to Wayfinding only
		_publish_threefold_loom_if_changed(loom_before)

func grant_skill(skill_id: String, equip: bool = false) -> bool:
	if not Progression.is_focus_skill(skill_id):
		return false
	var granted := false
	if not owned_skills.has(skill_id):
		owned_skills.append(skill_id)
		granted = true
	if equip and not loadout.has(skill_id) and loadout.size() < 3:
		loadout.append(skill_id)
	if is_inside_tree():
		var player := local_player()
		if player != null and player.has_method("rebuild_skills"):
			player.rebuild_skills()
	return granted


# Huntcraft 18 confers ownership through the normal Trade ladder, while the
# physical Lodge owns the teaching beat. This projection lets Town mount that
# interaction without deciding entitlement or mutating the loadout itself.
func driving_volley_lesson_status() -> Dictionary:
	var unlocked := trade_lv("huntcraft") >= 18 \
		and Progression.is_focus_skill("DrivingVolley")
	var completed := bool(seen_hints.get("driving_volley_lesson_completed", false))
	return {
		"available": unlocked and not completed,
		"unlocked": unlocked,
		"owned": skill_owned("DrivingVolley"),
		"completed": completed,
		"loadout_full": loadout.size() >= 3 and not loadout.has("DrivingVolley"),
	}


# Atomic Lodge lesson transaction. A free slot may receive Driving Volley;
# a full bar is preserved byte-for-byte and the lesson points at Loadout
# instead. Either branch grants permanent ownership and completes only once.
func accept_driving_volley_lesson() -> Dictionary:
	var status := driving_volley_lesson_status()
	var result := {"ok": false, "changed": false, "equipped": false,
		"deferred": false, "loadout": loadout.duplicate(true)}
	if not bool(status.available):
		return result
	if not skill_owned("DrivingVolley"):
		grant_skill("DrivingVolley")
	var lesson_script = load("res://scripts/skills/driving_volley.gd")
	if lesson_script == null or not lesson_script.has_method("lesson_loadout_plan"):
		return result
	# `already_owned` in the pure planner means already *taught*. Ownership is
	# intentionally established first so set_loadout can validate the result.
	var plan: Dictionary = lesson_script.lesson_loadout_plan(loadout, false)
	if bool(plan.get("equip_now", false)):
		var planned_loadout: Array = plan.get("loadout", loadout).duplicate(true)
		if not set_loadout(planned_loadout):
			return result
		result.equipped = true
	else:
		result.deferred = true
	seen_hints["driving_volley_lesson_completed"] = true
	seen_hints["driving_volley_lesson_deferred"] = bool(result.deferred)
	result.ok = true
	result.changed = true
	result.loadout = loadout.duplicate(true)
	notify("Driving Volley is yours. Choose it in Loadout when you want the road cleared." \
		if bool(result.deferred) else
		"Driving Volley learned — five close arrows drive the road clear.")
	save_now()
	return result


# The level-20 Lodge page teaches Threadstep without forcing a hotbar choice.
# Ownership still comes from the normal Huntcraft ladder; this transaction is
# the physical explanation/equip beat and is safe to defer when all three
# configurable slots are occupied.
func threadstep_lesson_status() -> Dictionary:
	var unlocked := trade_lv("huntcraft") >= 20 \
		and Progression.is_focus_skill("Threadstep")
	var completed := bool(seen_hints.get("threadstep_lesson_completed", false))
	return {
		"lesson_id": "threadstep",
		"skill_id": "Threadstep",
		"available": unlocked and not completed,
		"unlocked": unlocked,
		"owned": skill_owned("Threadstep"),
		"completed": completed,
		"loadout_full": loadout.size() >= 3 and not loadout.has("Threadstep"),
	}


func accept_threadstep_lesson() -> Dictionary:
	var status := threadstep_lesson_status()
	var result := {"ok": false, "changed": false, "equipped": false,
		"deferred": false, "loadout": loadout.duplicate(true)}
	if not bool(status.available):
		return result
	if not skill_owned("Threadstep"):
		grant_skill("Threadstep")
	if not loadout.has("Threadstep") and loadout.size() < 3:
		var planned := loadout.duplicate(true)
		planned.append("Threadstep")
		if not set_loadout(planned):
			return result
		result.equipped = true
	else:
		result.deferred = not loadout.has("Threadstep")
	seen_hints["threadstep_lesson_completed"] = true
	seen_hints["threadstep_lesson_deferred"] = bool(result.deferred)
	result.ok = true
	result.changed = true
	result.loadout = loadout.duplicate(true)
	notify("Threadstep is yours. Choose it in Loadout when you want the ash-road crossed." \
		if bool(result.deferred) else
		"Threadstep learned — the road moves only after it answers safe.")
	save_now()
	return result

func wayfinders_mark_lesson_status() -> Dictionary:
	var unlocked := trade_lv("huntcraft") >= 22 \
		and Progression.is_focus_skill("WayfindersMark")
	var completed := bool(seen_hints.get("wayfinders_mark_lesson_completed", false))
	return {
		"lesson_id": "wayfinders_mark", "skill_id": "WayfindersMark",
		"available": unlocked and not completed, "unlocked": unlocked,
		"owned": skill_owned("WayfindersMark"), "completed": completed,
		"loadout_full": loadout.size() >= 3 and not loadout.has("WayfindersMark"),
	}

func accept_wayfinders_mark_lesson() -> Dictionary:
	var status := wayfinders_mark_lesson_status()
	var result := {"ok": false, "changed": false, "equipped": false,
		"deferred": false, "loadout": loadout.duplicate(true)}
	if not bool(status.available):
		return result
	if not skill_owned("WayfindersMark") and not grant_skill("WayfindersMark"):
		return result
	if not loadout.has("WayfindersMark") and loadout.size() < 3:
		var next := loadout.duplicate(true)
		next.append("WayfindersMark")
		if set_loadout(next):
			result.equipped = true
		else:
			result.deferred = true
	else:
		result.deferred = not loadout.has("WayfindersMark")
	seen_hints["wayfinders_mark_lesson_completed"] = true
	seen_hints["wayfinders_mark_lesson_deferred"] = bool(result.deferred)
	result.ok = true
	result.changed = true
	result.loadout = loadout.duplicate(true)
	notify("Wayfinder's Mark is yours. Choose it in Loadout when the old binding reels." \
		if bool(result.deferred) else
		"Wayfinder's Mark learned — hold the Focus until the old binding reels.")
	save_now()
	return result


# One Lodge marker presents the earliest unfinished authored lesson. Keeping
# this projection in Game prevents Town from inferring Trade or hint state.
func hunters_lodge_lesson_status() -> Dictionary:
	var driving := driving_volley_lesson_status()
	if bool(driving.get("available", false)):
		driving = driving.duplicate(true)
		driving["lesson_id"] = "driving_volley"
		driving["skill_id"] = "DrivingVolley"
		return driving
	var threadstep := threadstep_lesson_status()
	if bool(threadstep.get("available", false)):
		return threadstep
	return wayfinders_mark_lesson_status()


func accept_hunters_lodge_lesson() -> Dictionary:
	var status := hunters_lodge_lesson_status()
	if String(status.get("lesson_id", "")) == "threadstep": return accept_threadstep_lesson()
	if String(status.get("lesson_id", "")) == "wayfinders_mark": return accept_wayfinders_mark_lesson()
	return accept_driving_volley_lesson()

# ---- materials satchel ----

func material_count(id: String) -> int:
	return int(materials.get(id, 0))

func add_material(id: String, n: int = 1) -> void:
	if n <= 0:
		return
	materials[id] = material_count(id) + n
	if tutorial_step == 1 and id == "wild_herb":
		mark_onboarding_progress()
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

# ---- D8 Wayweaver mastery ----

const WAYWEAVER_STATION_ACTIONS := {
	"hod_mastery": ["waysteel_core", "waysteel_frame"],
	"quill_mastery": ["root_sap_cord", "threefold_draught"],
	"awake_loom": ["wayweaver_string"],
	"master_hunt": ["quiet_tooth_grip"],
	"master_forge": ["wayweaver"],
}

const WAYWEAVER_ACTION_COPY := {
	"waysteel_core": {
		"title": "Draw the Waysteel Core",
		"description": "Hod banks three old-road shards into one patient heart.",
		"action_label": "Make the Waysteel Core",
	},
	"waysteel_frame": {
		"title": "Set the Waysteel Frame",
		"description": "The Core and the last two shards become a crescent that can carry a road.",
		"action_label": "Make the Waysteel Frame",
	},
	"root_sap_cord": {
		"title": "Twist the Root-Sap Cord",
		"description": "Quill measures three warm draws of sap into one unbroken cord.",
		"action_label": "Twist the Cord",
	},
	"threefold_draught": {
		"title": "Pour the Threefold Draught",
		"description": "Two clear measures wake what the Loom remembers.",
		"action_label": "Pour the Draught",
	},
	"wayweaver_string": {
		"title": "Wake the Wayweaver String",
		"description": "Cord and draught pass through all three Threads. The Threads are witnessed, never spent.",
		"action_label": "Weave the String",
	},
	"quiet_tooth_grip": {
		"title": "Bind the Quiet-Tooth Grip",
		"description": "The last trophy becomes a handhold, not a trinket.",
		"action_label": "Bind the Grip",
	},
	"wayweaver": {
		"title": "Forge Wayweaver",
		"description": "Frame, String, and Grip meet at the second hearth. Every older road remains yours.",
		"action_label": "Forge Wayweaver",
	},
}

func wayweaver_preview(station_id: String, action_id: String) -> Dictionary:
	if not _wayweaver_station_allows(station_id, action_id):
		return _wayweaver_ui_preview({}, station_id, action_id, false,
			"This work belongs at another hearth.")
	if action_id == WayweaverMasteryRules.WAYWEAVER:
		var keep_plan := WayweaverMasteryRules.preview(action_id,
			_wayweaver_facts(WayweaverMasteryRules.KEEP), WayweaverMasteryRules.KEEP)
		var equip_plan := WayweaverMasteryRules.preview(action_id,
			_wayweaver_facts(WayweaverMasteryRules.EQUIP), WayweaverMasteryRules.EQUIP)
		var plan: Dictionary = keep_plan if bool(keep_plan.get("ready", false)) else equip_plan
		return _wayweaver_ui_preview(plan, station_id, action_id,
			bool(keep_plan.get("ready", false)) or bool(equip_plan.get("ready", false)))
	var plan := WayweaverMasteryRules.preview(action_id, _wayweaver_facts(""))
	return _wayweaver_ui_preview(plan, station_id, action_id,
		bool(plan.get("ready", false)))

func commit_wayweaver(station_id: String, action_id: String,
		destination: String = "keep") -> Dictionary:
	if not _wayweaver_station_allows(station_id, action_id):
		return {"ok": false, "reason": "This work belongs at another hearth."}
	var choice := destination if action_id == WayweaverMasteryRules.WAYWEAVER else ""
	var facts := _wayweaver_facts(choice)
	var plan := WayweaverMasteryRules.commit_plan(action_id, facts, choice)
	if not bool(plan.get("commit_ready", false)):
		return {"ok": false, "reason": _wayweaver_missing_reason(plan), "plan": plan}
	var delta: Dictionary = plan.get("material_delta", {}) as Dictionary
	if not _wayweaver_delta_is_affordable(delta):
		return {"ok": false, "reason": "The satchel changed before the work began."}
	var made_item: Dictionary = {}
	var equipment_changed := false
	if action_id == WayweaverMasteryRules.WAYWEAVER:
		if inventory == null or equipment == null:
			return {"ok": false, "reason": "Your Pack is not ready for the bow."}
		made_item = ItemsData.make_item("wayweaver", "legendary")
		made_item["cosmetic_rune_id"] = ""
		var placement: Dictionary = plan.get("placement", {}) as Dictionary
		if String(placement.get("target", "")) == "pack":
			var fit: Dictionary = placement.get("fit", {}) as Dictionary
			if fit.is_empty() or not inventory.try_place(made_item,
					fit.get("pos", Vector2i(-1, -1)), bool(fit.get("rotated", false))):
				return {"ok": false, "reason": "Your Pack shifted before the bow could be set down."}
		else:
			var old_weapon = equipment.get_slot("weapon")
			if old_weapon != null:
				var displaced_fit: Dictionary = placement.get("displaced_weapon_fit", {}) as Dictionary
				if displaced_fit.is_empty() or not inventory.try_place(old_weapon,
						displaced_fit.get("pos", Vector2i(-1, -1)),
						bool(displaced_fit.get("rotated", false))):
					return {"ok": false, "reason": "There is no safe place for the bow in your hand."}
			equipment.slots["weapon"] = made_item
			equipment_changed = true
	_wayweaver_apply_delta(delta)
	if equipment_changed:
		equipment.changed.emit()
	materials_changed.emit()
	crafted.emit(station_id)
	if action_id == WayweaverMasteryRules.WAYWEAVER:
		notify("Wayweaver is yours. The next room will hear what you thread through it.")
	else:
		notify("Made %s." % GatherDefs.material_name(String(
			(plan.get("material_output", {}) as Dictionary).get("material_id", action_id))))
	save_now()
	if action_id == WayweaverMasteryRules.WAYWEAVER:
		# Town may already be open on host and guests may already be looking at its
		# Hall. Publish after the transaction and one save boundary, never from the
		# Trophy Hall itself.
		_publish_campaign_settlement_view()
	return {"ok": true, "changed": true, "action_id": action_id,
		"destination": choice, "item": made_item, "plan": plan}

func _wayweaver_station_allows(station_id: String, action_id: String) -> bool:
	return (WAYWEAVER_STATION_ACTIONS.get(station_id, []) as Array).has(action_id)

func _wayweaver_facts(choice: String) -> Dictionary:
	var pack := {}
	var wayweaver_item := ItemsData.make_item("wayweaver", "legendary")
	if inventory != null:
		var wayweaver_fit: Dictionary = inventory.find_first_fit(wayweaver_item)
		if not wayweaver_fit.is_empty():
			pack["wayweaver_fit"] = wayweaver_fit
		if equipment != null:
			var old_weapon = equipment.get_slot("weapon")
			if old_weapon != null:
				var displaced_fit: Dictionary = inventory.find_first_fit(old_weapon)
				if not displaced_fit.is_empty():
					pack["displaced_weapon_fit"] = displaced_fit
	return {
		"campaign_state": campaign_state,
		"trades": trades,
		"materials": materials,
		"ownership": {
			"pack": inventory.items if inventory != null else [],
			"equipment": equipment.slots if equipment != null else {},
		},
		"pack": pack,
		"choice": choice,
	}

func _wayweaver_delta_is_affordable(delta: Dictionary) -> bool:
	for material_id_v in delta:
		var amount := int(delta[material_id_v])
		if amount < 0 and material_count(String(material_id_v)) < -amount:
			return false
	return true

func _wayweaver_apply_delta(delta: Dictionary) -> void:
	for material_id_v in delta:
		var material_id := String(material_id_v)
		var next := material_count(material_id) + int(delta[material_id_v])
		if next > 0:
			materials[material_id] = next
		else:
			materials.erase(material_id)

func _wayweaver_ui_preview(plan: Dictionary, station_id: String,
		action_id: String, enabled: bool, override_reason: String = "") -> Dictionary:
	var copy: Dictionary = WAYWEAVER_ACTION_COPY.get(action_id, {}) as Dictionary
	var requirements: Array = []
	var kept_records: Array[String] = []
	for requirement_v in plan.get("requirements", []):
		if not requirement_v is Dictionary:
			continue
		var requirement: Dictionary = requirement_v
		var id := String(requirement.get("id", "record"))
		if id.begins_with("story.") or id.begins_with("thread.") \
				or id in ["unwritten_road_cleared", "master_forge_restored"]:
			kept_records.append(_wayweaver_requirement_label(id))
			continue
		var row := {"id": id, "label": _wayweaver_requirement_label(id),
			"met": bool(requirement.get("met", false))}
		var amount := _wayweaver_material_requirement(id)
		if not amount.is_empty():
			var material_id := String(amount.material_id)
			row["material_id"] = material_id
			row["required"] = int(amount.required)
			row["have"] = material_count(material_id)
			row["icon_path"] = GatherDefs.material_icon_path(material_id)
			requirements.append(row)
	var reason := override_reason if override_reason != "" else _wayweaver_missing_reason(plan)
	var rune_options: Array = wayweaver_rune_options() if action_id == WayweaverMasteryRules.WAYWEAVER \
		and not _owned_wayweaver_item().is_empty() else []
	return {
		"ok": enabled, "enabled": enabled, "can_commit": enabled,
		"station_id": station_id, "action_id": action_id,
		"title": String(copy.get("title", "Masterwork")),
		"description": String(copy.get("description", "")),
		"action_label": String(copy.get("action_label", "Make the masterwork")),
		"requirements": requirements, "kept_records": kept_records,
		"mastery_gate": "The station rechecks the live Trade and story record.",
		"missing_reason": "" if enabled else reason,
		"final_forge": action_id == WayweaverMasteryRules.WAYWEAVER,
		"rune_options": rune_options,
		"plan": plan,
	}

func _wayweaver_missing_reason(plan: Dictionary) -> String:
	var missing: Array = plan.get("missing_predicates", []) as Array
	if missing.is_empty():
		return "The station cannot settle that work yet."
	return "Still needed: %s." % _wayweaver_requirement_label(String(missing[0]))

func _wayweaver_requirement_label(id: String) -> String:
	var exact := {
		"final_choice": "choose Keep or Equip",
		"unwritten_road_cleared": "the named Unwritten Road",
		"master_forge_restored": "the restored second hearth",
		"wayweaver_not_owned": "Wayweaver not already owned",
		"pack_fits_wayweaver_2x4": "a clear 2×4 place in the Pack",
		"pack_fits_displaced_weapon": "room for the displaced bow",
		"threefold_loom_awake": "the awake Threefold Loom",
	}
	if exact.has(id):
		return String(exact[id])
	if id.begins_with("trade."):
		return id.trim_prefix("trade.").replace(">=", " mastery ").capitalize()
	if id.begins_with("materials."):
		var amount := _wayweaver_material_requirement(id)
		return "%s ×%d" % [GatherDefs.material_name(String(amount.get("material_id", ""))),
			int(amount.get("required", 1))]
	if id.begins_with("story."):
		return id.trim_prefix("story.").replace("_", " ").capitalize()
	if id.begins_with("thread."):
		return id.trim_prefix("thread.").replace("_", " ").capitalize()
	if id.begins_with("one_per_chain."):
		return "only one %s" % GatherDefs.material_name(id.trim_prefix("one_per_chain."))
	return id.replace("_", " ").capitalize()

func _wayweaver_material_requirement(id: String) -> Dictionary:
	if not id.begins_with("materials."):
		return {}
	var body := id.trim_prefix("materials.")
	var parts := body.split(">=")
	return {"material_id": String(parts[0]),
		"required": int(parts[1]) if parts.size() > 1 else 1}

# ---- Mara's Chart Table supplies ----

const CHART_STARTER_COMPONENTS := {"practice_leaf": 1, "hedge_sprig": 1}
const CHART_FIRST_RETURN_COMPONENTS := {
	"field_parchment": 1, "loop_cord": 1, "hedge_sprig": 1,
}

func chart_table_first_snug_returned() -> bool:
	# The explicit marker is canonical. Tutorial/recipe fallbacks keep saves from
	# the pre-table build from losing a Binding cell before migration re-saves.
	return bool(seen_hints.get("chart_table_snug_returned", false)) \
		or tutorial_step >= 6 or known_chart_recipes.has("green_hollow")

func chart_table_context() -> Dictionary:
	var extra_ink_slots := 0
	if perk_active("wayfinding", "master_wayfinder"):
		extra_ink_slots = 1
	var owned_component_ids: Array = []
	for component_id_v in ChartsData.COMPONENT_ORDER:
		var component_id := String(component_id_v)
		if material_count(component_id) > 0:
			owned_component_ids.append(component_id)
	return {
		"level": trade_lv("wayfinding"),
		"wildcraft_level": trade_lv("wildcraft"),
		"known_recipe_ids": known_chart_recipes.duplicate(),
		"recipe_journal": chart_recipe_journal.duplicate(true),
		"chart_source_unlocks": chart_source_unlocks.duplicate(),
		"campaign_state": CampaignData.normalize_campaign_state(campaign_state),
		"material_counts": materials.duplicate(),
		"owned_component_ids": owned_component_ids,
		"hedge_discount": 1 if perk_active("wayfinding", "thrifty_quill") else 0,
		"stability_perk_bonus": 0.05 if perk_active("wayfinding", "sure_lines") else 0.0,
		"extra_ink_slots": extra_ink_slots,
		"first_snug_returned": chart_table_first_snug_returned(),
		"revision": _chart_table_revision,
	}

# Top up only the two first-road pieces, and only before the first completed
# Snug. This is recovery, not a repeatable component faucet.
func ensure_chart_starter_supplies() -> Dictionary:
	if chart_table_first_snug_returned():
		return {}
	var granted := {}
	for id in CHART_STARTER_COMPONENTS:
		var missing := maxi(0, int(CHART_STARTER_COMPONENTS[id]) - material_count(id))
		if missing > 0:
			materials[id] = material_count(id) + missing
			granted[id] = missing
	if not granted.is_empty():
		materials_changed.emit()
	return granted

func grant_first_return_chart_supplies() -> Dictionary:
	if chart_table_first_snug_returned():
		return {}
	seen_hints["chart_table_snug_returned"] = true
	# The Green Hollow rumour arrives with the lesson pieces, before
	# return_to_town's existing save. There is no intermediate save or NPC gate.
	_remember_chart_rumour("mara_first_loop")
	var granted := CHART_FIRST_RETURN_COMPONENTS.duplicate()
	for id in granted:
		materials[id] = material_count(id) + int(granted[id])
	materials_changed.emit()
	notify("Mara sets out a Field Parchment, Loop Cord, and fresh Hedge Sprig.")
	return granted

func buy_chart_component(component_id: String, count: int = 1) -> bool:
	if count <= 0 or not ChartsData.component_supply_ids(chart_table_context()).has(component_id):
		return false
	var each := ChartsData.component_supply_price(component_id)
	var total := each * count
	if each <= 0 or gold < total:
		return false
	gold -= total
	materials[component_id] = material_count(component_id) + count
	gold_changed.emit(gold)
	materials_changed.emit()
	notify("Mara sets aside %d %s." % [count, GatherDefs.material_name(component_id)])
	save_now()
	return true

# ---- the gold economy (Hod's counter) ----

# Sell a gear item out of the Tetris inventory. Returns the price paid.
func sell_item(item: Dictionary) -> int:
	if inventory == null or not inventory.items.has(item):
		return 0
	if not bool(item.get("sellable", true)):
		notify("Hod lowers his hammer. Some roads are not scrap.")
		return 0
	var price := EconomyData.sell_value(item)
	inventory.remove(item)
	gold += price
	gold_changed.emit(gold)
	save_now()
	return price

# Buy a material off Hod's shelf. Returns false if gold is short or the ware
# is above the player's Wayfinding level (defense-in-depth: the vendor panel
# already hides over-level wares via wares_for_level, but buy_ware enforces its
# own invariant so no other call path can bypass the gather loop).
func buy_ware(id: String, price: int) -> bool:
	if trade_lv("wayfinding") < EconomyData.ware_min_lv(id):
		notify("Hod won't sell that yet — keep charting.")
		return false
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
const STATION_TRADE := {
	"cookfire": "wildcraft",
	"still": "wildcraft",
	"forge": "earthcraft",
	"ember_kiln": "earthcraft",
}

# Craft a recipe at a station. Returns false (with a toast) when gated,
# unaffordable, or the pack has no room for a gear yield.
func craft(station_id: String, recipe_id: String) -> bool:
	var st: Dictionary = CraftingDefs.station(station_id)
	var rec: Dictionary = CraftingDefs.recipe(recipe_id)
	if st.is_empty() or rec.is_empty():
		return false
	if not (st.recipes as Array).has(recipe_id):
		return false
	# Restored stations are campaign projections, never unlocks inferred from a
	# forged direct call or a loose reward. Both declarations may carry the gate
	# so data validation and the mutation boundary agree.
	for required_v in [st.get("requires_restoration", ""),
			rec.get("requires_restoration", "")]:
		var required := String(required_v)
		if required != "" and not (campaign_state.get("restorations", []) as Array).has(required):
			return false
	var trade := String(STATION_TRADE.get(station_id, ""))
	if trade == "":
		return false
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
		if trade == "wildcraft" and perk_active("wildcraft", "second_pour") \
				and randf() < 0.25:
			n_out += 1
			notify("Second pour! The pot had more to give.")
		add_material(String(rec.yields_material), n_out)
		notify("Made %s." % GatherDefs.material_name(String(rec.yields_material)))
	# Spec 45-earth — Smith's Thrift: 1 in 4 forge crafts hand back one RAW
	# input (never a bar — a bar refund would crack the economy gate on the
	# all-buyable recipes).
	if station_id == "forge" and perk_active("earthcraft", "smiths_thrift") \
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
	var sfx := get_node_or_null("/root/Sfx") if is_inside_tree() else null
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
	"wayfinding": [
		{"id": "marginalia", "lv": 2, "name": "Mara's Marginalia",
			"desc": "Mara's notes crowd the codex margins — every riddle, plain to read"},
		{"id": "practiced_measures", "lv": 3, "name": "Practiced Measures",
			"desc": "Stage every required making for a known Chart at once"},
		{"id": "curious_fingers", "lv": 5, "name": "Curious Fingers",
			"desc": "A failed mix smudges less — curiosity keeps more of what it touches"},
		{"id": "sure_lines", "lv": 10, "name": "Sure Lines",
			"desc": "Your nib doesn't waver — every affix leans 5 points toward its good twin"},
		{"id": "thrifty_quill", "lv": 14, "name": "Thrifty Quill",
			"desc": "Each chart asks one less pot of hedge ink. Waste not"},
		{"id": "master_wayfinder", "lv": 17, "name": "Master Wayfinder",
			"desc": "Every chart that takes ink holds one more pot — the page listens closer"},
	],
	"earthcraft": [
		{"id": "double_ore", "lv": 5, "name": "Sturdy Swings",
			"desc": "25% chance a vein gives a second lump"},
		{"id": "quick_mining", "lv": 10, "name": "Miner's Rhythm",
			"desc": "Mining takes a third less time"},
		{"id": "rich_seams", "lv": 13, "name": "Rich Seams",
			"desc": "Starsilver and deeper veins always give a second lump"},
		{"id": "smiths_thrift", "lv": 17, "name": "Smith's Thrift",
			"desc": "1 in 4 forge crafts hand back one raw input — never a bar"},
	],
	"wildcraft": [
		{"id": "keen_eye", "lv": 5, "name": "Keen Eye",
			"desc": "+1 herb on every forage"},
		{"id": "clean_splits", "lv": 10, "name": "Clean Splits",
			"desc": "+1 log on every chop"},
		{"id": "light_hands", "lv": 13, "name": "Light Hands",
			"desc": "Foraging and chopping take a quarter less time"},
		{"id": "second_pour", "lv": 17, "name": "Second Pour",
			"desc": "25% chance a hearth or still recipe pours a second bottle"},
	],
	"huntcraft": [
		{"id": "steady_hands", "lv": 5, "name": "Steady Hands",
			"desc": "+5% crit chance"},
		{"id": "hunters_stride", "lv": 10, "name": "Hunter's Stride",
			"desc": "+5% move speed"},
		{"id": "quick_nock", "lv": 12, "name": "Quick Nock",
			"desc": "Skills come back a tenth sooner"},
		{"id": "heavy_draw", "lv": 14, "name": "Heavy Draw",
			"desc": "Your telling hits land a quarter harder"},
		{"id": "even_breath", "lv": 17, "name": "Even Breath",
			"desc": "A clean kill steadies you — every kill returns 6 Focus"},
	],
}

# Choice machinery is data-driven and currently dormant: no authored Trade has
# more than one perk at the same level. A future multi-choice level will begin
# prompting without requiring a separate hard-coded tier list.
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

# A perk is active when its level is reached. If future data authors multiple
# perks at one Trade level, only the persisted choice at that tier is active.
func perk_active(trade_key: String, perk_id: String) -> bool:
	if not Progression.is_runtime_trade_key(trade_key):
		return false
	for perk in PERKS.get(trade_key, []):
		if String(perk.id) == perk_id:
			if trade_lv(trade_key) < int(perk.lv):
				return false
			if perks_at_level(int(perk.lv), trade_key).size() > 1:
				return bool((chosen_perks.get(trade_key, {}) as Dictionary).get(perk_id, false))
			return true
	return false

# The perks unlocked at a given level (the candidates for that tier's choice).
func perks_at_level(lv: int, trade_key: String = "wayfinding") -> Array:
	var out: Array = []
	for perk in PERKS.get(trade_key, []):
		if int(perk.lv) == lv:
			out.append(perk)
	return out

# True once the player has picked a perk at this choice tier.
func tier_chosen(trade_or_level, level: int = -1) -> bool:
	var trade_key := "wayfinding" if level < 0 else String(trade_or_level)
	var lv := int(trade_or_level) if level < 0 else level
	if not Progression.is_runtime_trade_key(trade_key):
		return false
	for perk in perks_at_level(lv, trade_key):
		if bool((chosen_perks.get(trade_key, {}) as Dictionary).get(String(perk.id), false)):
			return true
	return false

# Choice tiers the player has reached but not yet picked — for retroactive
# prompts (a migrated save, or a tier skipped past while another modal was up).
func pending_mastery_levels() -> Array:
	var out: Array = []
	for trade_key in Progression.TRADE_KEYS:
		for lv in range(1, Progression.LEVEL_CAP + 1):
			if perks_at_level(int(lv), trade_key).size() > 1 \
					and trade_lv(trade_key) >= int(lv) and not tier_chosen(trade_key, int(lv)):
				out.append({"trade": trade_key, "level": int(lv)})
	return out

# Pick one perk at its tier. Permanent for now (no respec) — rejects a second
# pick at a tier that already has one. Returns true if the pick took.
func choose_perk(perk_id: String) -> bool:
	for trade_key in Progression.TRADE_KEYS:
		for perk in PERKS.get(trade_key, []):
			if String(perk.id) == perk_id:
				var pl: int = int(perk.lv)
				if perks_at_level(pl, trade_key).size() < 2 or trade_lv(trade_key) < pl:
					return false
				if tier_chosen(trade_key, pl):
					return false
				if not chosen_perks.has(trade_key):
					chosen_perks[trade_key] = {}
				(chosen_perks[trade_key] as Dictionary)[perk_id] = true
				perks_changed.emit()
				save_now()
				return true
	return false

# Future seam — pop the pick-one-of-N modal only for an authored choice tier.
# The panel owns its own modal accounting (open() → modal_opened; a pick →
# modal_closed), mirroring the shrine modal. If we're mid-scene-transition the
# choice stays queued in pending_mastery_levels() for a future prompt.
func _on_mastery_choice_ready(trade_key: String, level: int) -> void:
	if not is_inside_tree():
		return
	var tree := get_tree()
	if tree == null:
		return                       # standalone Game instance (headless tests)
	var scn := tree.current_scene
	if scn == null:
		return
	var MasteryPanel := load("res://scripts/ui/mastery_choice_panel.gd")
	var panel: CanvasLayer = MasteryPanel.new()
	scn.add_child(panel)
	panel.open(level, trade_key)

# Bonus yield for one harvest of `kind` — deterministic perks return 1,
# chance perks roll here so GatherNode stays dumb.
func gather_bonus(kind: String) -> int:
	match kind:
		"forage_node":
			return 1 if perk_active("wildcraft", "keen_eye") else 0
		"log_pile":
			return 1 if perk_active("wildcraft", "clean_splits") else 0
		"ore_rock":
			if perk_active("earthcraft", "double_ore") and randf() < 0.25:
				return 1
	return 0

# ---- draughts (the sustain verb) ----
# Smallest sufficient bottle first; returns the heal amount (0 = none had).
func quaff_draught() -> int:
	# Prefer the pinned quick-use draught when it's a healing one you still own.
	if quick_item != "" and CraftingDefs.DRAUGHT_ORDER.has(quick_item) \
			and material_count(quick_item) > 0:
		spend_materials({quick_item: 1})
		notify("You quaff a %s." % GatherDefs.material_name(quick_item))
		save_now()
		return int(CraftingDefs.DRAUGHTS[quick_item])
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
	_tick_onboarding_recovery()
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
			seen_hints["tonic_quaffed"] = true   # D15 — Quill reacts to this
			save_now()
			return true
	return false

func ink_recipe_status(ink_id: String) -> Dictionary:
	var recipe: Dictionary = GatherDefs.INK_RECIPES.get(ink_id, {})
	if recipe.is_empty():
		return {"valid": false, "unlocked": false, "ink_id": ink_id,
			"required_wildcraft": 0, "wildcraft_level": trade_lv("wildcraft")}
	var required := maxi(1, int(recipe.get("req_wildcraft", 1)))
	var level := trade_lv("wildcraft")
	return {"valid": true, "unlocked": level >= required, "ink_id": ink_id,
		"required_wildcraft": required, "wildcraft_level": level}


func mix_ink(ink_id: String) -> bool:
	var recipe: Dictionary = GatherDefs.INK_RECIPES.get(ink_id, {})
	var status := ink_recipe_status(ink_id)
	if recipe.is_empty() or not bool(status.unlocked):
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
# Spec 58 Slice A — known Chart Recipes are persisted now so the compatibility
# migration has a stable home before the Codex/discovery UI arrives in Slice C.
var known_chart_recipes: Array = ChartsData.starting_recipe_ids()
# Slice C1 — supplemental provenance only. `known_chart_recipes` remains the
# sole recipe entitlement authority; normalization can never add to it.
var chart_recipe_journal: Dictionary = ChartsData.fresh_recipe_journal()
# Unlocked world sources are distinct from read rumours: returning from a run
# can make a panel/note available without silently teaching its arrangement.
var chart_source_unlocks: Array = []
# Rare/unique charms the player has puzzled out (commons are always bindable;
# see enchant_available). Persisted alongside discovered_inks.
var discovered_enchants: Array = []

func ink_discovered(ink_id: String) -> bool:
	return discovered_inks.has(ink_id)

func chart_recipe_known(recipe_id: String) -> bool:
	return known_chart_recipes.has(recipe_id)


# Source unlock strings are durable availability hints, not campaign truth.
# Late Root-Saga sources declare their canonical prerequisites in ChartsData;
# recheck those predicates here so a stale or malformed unlock can never grant
# lesson supplies or a rumour on its own.
func _chart_source_prerequisites_met(source: Dictionary) -> bool:
	var required_clear := String(source.get("requires_chapter_clear", ""))
	if required_clear != "" \
			and not CampaignData.chapter_cleared(campaign_state, required_clear):
		return false
	var raw_clues = source.get("requires_chapter_clue_count", {})
	if raw_clues is Dictionary and not (raw_clues as Dictionary).is_empty():
		var chapter_id := String((raw_clues as Dictionary).get("chapter_id", ""))
		var required_count := maxi(0, int((raw_clues as Dictionary).get("count", 0)))
		if chapter_id == "" or CampaignData.chapter_clue_count(
				campaign_state, chapter_id) < required_count:
			return false
	return true

func _remember_chart_rumour(rumour_id: String) -> bool:
	if not ChartsData.CHART_RUMOURS.has(rumour_id):
		return false
	var next := ChartsData.journal_with_rumour(chart_recipe_journal, rumour_id,
		known_chart_recipes)
	if next == chart_recipe_journal:
		return false
	chart_recipe_journal = next
	chart_knowledge_changed.emit()
	return true

# Public personal-progress adapter for future NPC, clue-room, and Atlas source
# call sites. The first-return transaction uses _remember_chart_rumour so its
# supplies + rumour share return_to_town's single save.
func hear_chart_rumour(rumour_id: String) -> bool:
	if not _remember_chart_rumour(rumour_id):
		return false
	save_now()
	return true

# Stable world-controller query. Controllers render copy from `state`; they do
# not inspect journals, component stacks, or migration flags.
func chart_source_status(source_id: String) -> Dictionary:
	if not ChartsData.CHART_SOURCES.has(source_id):
		return {"valid": false, "source_id": source_id, "state": "invalid",
			"unlocked": false, "level": trade_lv("wayfinding"),
			"min_wayfinding": 0, "rumour_id": "", "recipe_id": "",
			"known": false, "heard": false}
	var source: Dictionary = ChartsData.CHART_SOURCES[source_id]
	var rumour_id := String(source.rumour_id)
	var recipe_id := String(source.recipe_id)
	var level := trade_lv("wayfinding")
	var entitlement := chart_source_unlocks.has(source_id)
	var prerequisite_met := _chart_source_prerequisites_met(source)
	var unlocked := entitlement and prerequisite_met
	var known := chart_recipe_known(recipe_id)
	var heard := (chart_recipe_journal.get("rumours", []) as Array).has(rumour_id)
	var state := "resolved" if known else "locked" if not unlocked \
		or level < int(source.min_wayfinding) else "read" if heard else "eligible"
	return {"valid": true, "source_id": source_id, "state": state,
		"unlocked": unlocked, "entitled": entitlement,
		"prerequisite_met": prerequisite_met, "level": level,
		"min_wayfinding": int(source.min_wayfinding), "rumour_id": rumour_id,
		"recipe_id": recipe_id, "known": known, "heard": heard}

# Atomic personal-progress mutation. An eligible first read remembers the
# rumour; an authored lesson source may also resolve a rumour already heard
# from campaign clue convergence into recipe knowledge. Both routes top any
# ordinary lesson components to one, invalidate a stale table preview, signal
# once, toast once, then save once.
func read_chart_source(source_id: String) -> Dictionary:
	var status := chart_source_status(source_id)
	var result := {"ok": bool(status.valid), "changed": false,
		"state": String(status.state), "granted": {}, "recipe_granted": "",
		"status": status}
	# Shared Town progression belongs to the host. Guests may read the host's
	# presentation, but never grant supplies, edit journals, or write a save.
	if not _campaign_is_authority():
		result["ok"] = false
		result["read_only"] = true
		return result
	if not bool(status.valid):
		return result
	var source: Dictionary = ChartsData.CHART_SOURCES[source_id]
	var source_state := String(status.state)
	var resolves_heard_lesson := source_state == "read" \
		and bool(source.get("grant_recipe_knowledge", false)) \
		and not bool(status.get("known", false))
	if source_state != "eligible" and not resolves_heard_lesson:
		return result
	var loom_before: Dictionary = _threefold_loom_projection_fingerprint() \
		if source_id == "threefold_loom_root_below" else {}
	if source_state == "eligible" and not _remember_chart_rumour(String(source.rumour_id)):
		result.status = chart_source_status(source_id)
		result.state = String(result.status.state)
		return result
	var granted := {}
	var recipe_granted := ""
	if bool(source.get("grant_recipe_knowledge", false)):
		var recipe_id := String(source.get("recipe_id", ""))
		if ChartsData.CHART_RECIPES.has(recipe_id) \
				and not known_chart_recipes.has(recipe_id):
			known_chart_recipes.append(recipe_id)
			var provenance := String(source.get("discovery_provenance", "source_lesson"))
			chart_recipe_journal = ChartsData.journal_with_discovery(
				chart_recipe_journal, recipe_id, provenance, known_chart_recipes)
			recipe_granted = recipe_id
	# Keep physical Table pieces and the separately taught Ink visible in the
	# source schema even though both top up through the same Satchel adapter.
	for kit_field in ["lesson_components", "lesson_inks"]:
		var kit = source.get(kit_field, {})
		if not kit is Dictionary:
			continue
		for item_id_v in (kit as Dictionary):
			var item_id := String(item_id_v)
			var missing := maxi(0, int((kit as Dictionary)[item_id_v]) \
				- material_count(item_id))
			if missing > 0:
				materials[item_id] = material_count(item_id) + missing
				granted[item_id] = missing
	if not granted.is_empty():
		materials_changed.emit()
	_chart_table_revision += 1
	notify(String(source.get("toast", "A Chart clue has been added to Mara's Codex.")))
	save_now()
	result.changed = true
	result.granted = granted
	result.recipe_granted = recipe_granted
	result.status = chart_source_status(source_id)
	result.state = String(result.status.state)
	_publish_threefold_loom_if_changed(loom_before)
	return result


# The physical Threefold Loom has two authored moments: its first Root Below
# folio, then the level-23 Map tracing.  Keep this adapter in Game so the
# scene/UI can only render an already-derived view and never infer campaign or
# Codex truth from inventory, a loose Rune, or a stale local save.
func threefold_loom_view(context: Dictionary = {}) -> Dictionary:
	var inspection := context.duplicate(true)
	if net_active():
		var net := get_node_or_null("/root/NetGame")
		if net == null or not bool(net.is_host()):
			# A guest never derives Loom phase, prerequisites, or Codex repair
			# eligibility from its local save.  `campaign_settlement_view` is the
			# one sanitizing boundary for the current host snapshot; until it
			# arrives, render no ritual truth at all.
			var settlement := campaign_settlement_view(inspection)
			var remote_loom = settlement.get("threefold_loom", {})
			if not remote_loom is Dictionary or (remote_loom as Dictionary).is_empty() \
					or not bool((remote_loom as Dictionary).get("valid", false)):
				return _unavailable_threefold_loom_view()
			var projection: Dictionary = (remote_loom as Dictionary).duplicate(true)
			projection["read_only"] = true
			projection["can_trace"] = false
			projection["can_repair_knowledge"] = false
			return projection
	var read_only := bool(inspection.get("read_only", false))
	var first_folio_settled := String(chart_source_status(
		"threefold_loom_root_below").get("state", "")) == "resolved"
	var final_recipe_id := CampaignData.UNWRITTEN_ROAD_BOSS_RECIPE
	var discoveries = chart_recipe_journal.get("discoveries", {})
	var final_recipe_known := known_chart_recipes.has(final_recipe_id) \
		and discoveries is Dictionary \
		and String((discoveries as Dictionary).get(final_recipe_id, "")) == "source_lesson" \
		and (chart_recipe_journal.get("rumours", []) as Array).has(
			CampaignData.UNWRITTEN_ROAD_RUMOUR)
	var view := CampaignData.threefold_loom_view(campaign_state,
		trade_lv("wayfinding"), first_folio_settled, final_recipe_known, read_only)
	# A trusted v6 Map is durable campaign truth.  A partial older save may need
	# only the Codex side reconciled; expose that narrowly so the panel can name
	# the repair without pretending a completed record can be traced again.
	view["can_repair_knowledge"] = bool(view.get("map_recorded", false)) \
		and not bool(view.get("knowledge_complete", false)) and not read_only
	return view


# A joining guest may open Town before the host has sent its compact settlement
# projection.  This is intentionally not a locally-derived "waiting" Loom:
# it names no requirements and offers no inference surface until host truth is
# present.
func _unavailable_threefold_loom_view() -> Dictionary:
	return {
		"valid": false,
		"phase": "unavailable",
		"read_only": true,
		"can_trace": false,
		"can_repair_knowledge": false,
		"map_recorded": false,
		"knowledge_complete": false,
		"loom_state": "dormant",
		"requirements": [],
	}


# Only the Loom's published presentation belongs in this fingerprint.  It is
# copied before a source/XP mutation and compared after it, so a normal XP
# award that leaves the view alone sends no co-op settlement snapshot.
func _threefold_loom_projection_fingerprint() -> Dictionary:
	if not _campaign_is_authority():
		return {}
	return threefold_loom_view().duplicate(true)


func _publish_threefold_loom_if_changed(before: Dictionary) -> bool:
	if before.is_empty() or not _campaign_is_authority():
		return false
	if before == _threefold_loom_projection_fingerprint():
		return false
	_publish_campaign_settlement_view()
	return true


# Host-only convergent Map transaction.  The pure Campaign transition owns the
# Map policy; this adapter stages every dependent Codex record first so a
# successful fresh trace or a trusted partial-v6 repair has exactly one save
# and one settlement publication.  Do not use _remember_chart_rumour here:
# its immediate signal would split this transaction's signal boundary.
func trace_threefold_loom_map() -> Dictionary:
	var view := threefold_loom_view()
	if bool(view.get("read_only", false)) or not _campaign_is_authority():
		return {"ok": false, "changed": false, "reason": "host_only", "view": view}
	var transition := CampaignData.record_map_of_nine_knots(campaign_state,
		trade_lv("wayfinding"))
	var map_recorded := bool(view.get("map_recorded", false))
	# A new Map must still be traceable at the live Loom.  A Map already accepted
	# by CampaignData is the one intentional repair path, even after its panel
	# has moved to map_recorded.
	if not map_recorded and (not bool(transition.get("ok", false)) \
			or not bool(view.get("can_trace", false))):
		return {"ok": false, "changed": false, "reason": "requirements", "view": view}
	if map_recorded and not bool(transition.get("ok", false)):
		return {"ok": false, "changed": false, "reason": "invalid_map", "view": view}

	var recipe_id := CampaignData.UNWRITTEN_ROAD_BOSS_RECIPE
	var rumour_id := CampaignData.UNWRITTEN_ROAD_RUMOUR
	var next_known: Array = known_chart_recipes.duplicate()
	var knowledge_changed := false
	if not next_known.has(recipe_id):
		next_known.append(recipe_id)
		knowledge_changed = true
	var next_journal := ChartsData.journal_with_rumour(chart_recipe_journal,
		rumour_id, next_known)
	next_journal = ChartsData.journal_with_discovery(next_journal, recipe_id,
		"source_lesson", next_known)
	if next_journal != chart_recipe_journal:
		knowledge_changed = true
	var campaign_changed := bool(transition.get("changed", false))
	if not campaign_changed and not knowledge_changed:
		return {"ok": true, "changed": false, "view": view}

	# Commit only after all ordinary in-memory reconciliation has been staged.
	# There are no inventory/material or world operations after this point.
	if campaign_changed:
		campaign_state = transition.state
	if knowledge_changed:
		known_chart_recipes = next_known
		chart_recipe_journal = next_journal
	_chart_table_revision += 1
	if campaign_changed:
		story_changed.emit()
	if knowledge_changed:
		chart_knowledge_changed.emit()
	notify("The Threefold Loom records the Map of Nine Knots.")
	save_now()
	_publish_campaign_settlement_view()
	return {"ok": true, "changed": true, "map_awarded": campaign_changed,
		"knowledge_repaired": knowledge_changed, "view": threefold_loom_view()}

# Internal event seam: availability is durable, but never teaches a rumour.
func _unlock_chart_source(source_id: String) -> bool:
	if not ChartsData.CHART_SOURCES.has(source_id) or chart_source_unlocks.has(source_id):
		return false
	chart_source_unlocks.append(source_id)
	chart_source_unlocks = ChartsData.normalize_chart_source_unlocks(chart_source_unlocks)
	# Unlocks happen only inside the successful return transaction while the
	# dungeon scene is retiring. The incoming Town reads this durable state when
	# it builds; emitting the Codex signal here would wake Controls from the old
	# Town during Web scene teardown. Reading a source still emits exactly once.
	return true


# Rebuild only source *availability* from canonical Campaign truth. The source
# transaction still rechecks the declarative prerequisite before it can teach
# a rumour or grant a missing-only lesson kit.
func _sync_campaign_chart_sources() -> bool:
	var changed := false
	for chapter_id_v in CampaignData.CHAPTER_ORDER:
		var chapter_id := String(chapter_id_v)
		var chapter: Dictionary = CampaignData.CHAPTERS.get(chapter_id, {})
		var clue_source_id := String(chapter.get("clue_source_id", ""))
		var required_clear := String(chapter.get("requires_chapter_clear", ""))
		if clue_source_id != "" and (required_clear == "" \
				or CampaignData.chapter_cleared(campaign_state, required_clear)):
			changed = _unlock_chart_source(clue_source_id) or changed
		var boss_source_id := String(chapter.get("boss_source_id", ""))
		if boss_source_id != "" \
				and CampaignData.chapter_clue_count(campaign_state, chapter_id) \
					>= int(chapter.get("clue_target", 0)):
			changed = _unlock_chart_source(boss_source_id) or changed
	return changed

func _unlock_chart_sources_for_completed_chart(chart: Dictionary,
		abandoned: bool = false) -> bool:
	if abandoned:
		return false
	match String(chart.get("template_id", "")):
		"tier_1":
			return _unlock_chart_source("atlas_deep_hollow")
		"hollow":
			return _unlock_chart_source("mara_sallow_reed")
	return false

func discover_ink(ink_id: String) -> void:
	if ink_discovered(ink_id):
		return
	discovered_inks.append(ink_id)
	var discovery_xp := GatherDefs.ink_discovery_xp(ink_id)
	if discovery_xp > 0:
		award_xp("wayfinding", discovery_xp, "ink_discovery:%s" % ink_id)
	notify("✦ Recipe found: %s! It's yours for good." %
		GatherDefs.material_name(ink_id))
	save_now()

# ---- Slice D1: deterministic campaign progress + story-key escrow ----

# The old elite trophy roll is deliberately unavailable until the authored
# first boss has been cleared. World adapters call this seam rather than
# reading campaign dictionaries or deciding progression themselves.
func campaign_elite_trophy_eligible(trophy_id: String = "thorn_essence") -> bool:
	if trophy_id != "thorn_essence":
		return true
	return CampaignData.chapter_cleared(campaign_state, CampaignData.FIRST_KNOT)

# Small pure seam for co-op contract tests and the live authority adapter.
func campaign_settlement_allowed(net_session: bool, is_host: bool) -> bool:
	return not net_session or is_host

# Pure co-op policy seam for the far-Waystone tests and UI adapters. A guest
# can see the authored choice but cannot make either branch happen.
func depth_choice_allowed(net_session: bool, is_host: bool) -> bool:
	return not net_session or is_host

func _campaign_is_authority() -> bool:
	if not net_active():
		return true
	var net := get_node_or_null("/root/NetGame")
	return campaign_settlement_allowed(true, net != null and bool(net.is_host()))

# Public Homecoming adapter.  In a shared Town the host campaign is the only
# authority, so a guest consumes NetGame's already-derived snapshot rather
# than inspecting or normalizing its own save.  If that snapshot has not
# arrived yet, return a fail-closed empty projection; opening Town must never
# grant or reconcile local campaign progress.
func first_knot_homecoming_view(context: Dictionary = {}) -> Dictionary:
	var inspection := context.duplicate(true)
	# The return source is session-only presentation context.  It deliberately
	# never enters campaign state or a save: a Reprise may return to the already
	# restored Hall, but it cannot trigger the First Knot Homecoming debrief.
	if not inspection.has("d2_reprise") and not inspection.has("reprise"):
		inspection["d2_reprise"] = _homecoming_return_was_d2_reprise
	if net_active():
		var net := get_node_or_null("/root/NetGame")
		if net == null or not bool(net.is_host()):
			inspection["guest"] = true
			inspection["read_only"] = true
			var remote: Dictionary = net.homecoming_view_snapshot() \
				if net != null and net.has_method("homecoming_view_snapshot") else {}
			if remote.is_empty():
				inspection["snapshot_available"] = false
				return CampaignData.first_knot_homecoming_view(
					CampaignData.empty_state(), inspection)
			# The host snapshot is itself presentation-only.  Force guest policy
			# again at the adapter boundary so a stale/older host cannot offer a
			# guest a local acknowledgement action.
			remote = remote.duplicate(true)
			remote["guest"] = true
			remote["read_only"] = true
			var event = remote.get("debrief_event", {})
			if event is Dictionary:
				event = (event as Dictionary).duplicate(true)
				event["available"] = false
				remote["debrief_event"] = event
			return remote
	var view := CampaignData.first_knot_homecoming_view(campaign_state, inspection)
	if net_active():
		var host_net := get_node_or_null("/root/NetGame")
		if host_net != null and host_net.has_method("publish_homecoming_view"):
			host_net.publish_homecoming_view(view)
	return view

func _publish_first_knot_homecoming_view() -> void:
	if not net_active():
		return
	var net := get_node_or_null("/root/NetGame")
	if net != null and bool(net.is_host()) and net.has_method("publish_homecoming_view"):
		net.publish_homecoming_view(CampaignData.first_knot_homecoming_view(campaign_state))

# Neutral campaign projection for Town adapters added after First Knot. This
# is deliberately view-only: the host publishes an already-derived snapshot;
# guests neither normalize nor persist their own campaign save while sharing a
# fire. Keep `first_knot_homecoming_view` above intact for its existing Hall
# debrief callers until that presentation migrates to this surface.
func campaign_settlement_view(context: Dictionary = {}) -> Dictionary:
	var inspection := context.duplicate(true)
	if net_active():
		var net := get_node_or_null("/root/NetGame")
		if net == null or not bool(net.is_host()):
			inspection["guest"] = true
			inspection["read_only"] = true
			var remote: Dictionary = net.settlement_view_snapshot() \
				if net != null and net.has_method("settlement_view_snapshot") else {}
			if remote.is_empty():
				inspection["snapshot_available"] = false
				return CampaignData.settlement_view(CampaignData.empty_state(), inspection)
			remote = remote.duplicate(true)
			remote["guest"] = true
			remote["read_only"] = true
			# The host owns visibility, while the receiving role owns interaction
			# policy. Stamp every chapter alias read-only so a Town presenter never
			# mistakes the host's local `false` for guest permission.
			var remote_chapters = remote.get("chapters", {})
			if remote_chapters is Dictionary:
				for chapter_id_v in (remote_chapters as Dictionary).keys():
					var chapter_id := String(chapter_id_v)
					var chapter = (remote_chapters as Dictionary)[chapter_id_v]
					if chapter is Dictionary:
						(chapter as Dictionary)["guest"] = true
						(chapter as Dictionary)["read_only"] = true
						var debrief = (chapter as Dictionary).get("debrief_event", {})
						if debrief is Dictionary:
							(debrief as Dictionary)["available"] = false
						remote[chapter_id] = (chapter as Dictionary).duplicate(true)
			var remote_loom = remote.get("threefold_loom", {})
			if remote_loom is Dictionary:
				(remote_loom as Dictionary)["read_only"] = true
				(remote_loom as Dictionary)["can_trace"] = false
				(remote_loom as Dictionary)["can_repair_knowledge"] = false
				remote["threefold_loom"] = (remote_loom as Dictionary).duplicate(true)
			return remote
	var view := _campaign_settlement_snapshot(inspection)
	return view


# One neutral host snapshot serves both the local Town view and NetGame's
# presentation-only guest replication.  Equipment mount state is deliberately
# still a Game projection; the Threefold Loom view is CampaignData-derived and
# explicitly read-only when a guest consumes the copied snapshot.
func _campaign_settlement_snapshot(context: Dictionary = {}) -> Dictionary:
	var view := CampaignData.settlement_view(campaign_state, context)
	view["wayweaver_mount"] = _wayweaver_mount_projection()
	view["threefold_loom"] = threefold_loom_view(context)
	return view

func _publish_campaign_settlement_view() -> void:
	var net := get_node_or_null("/root/NetGame") if net_active() else null
	var host_publication := net != null and bool(net.is_host()) \
		and net.has_method("publish_settlement_view")
	# A solo forge happens while Town is already open, so it still owns one
	# direct local refresh.  In a hosted Town, `publish_settlement_view` uses a
	# call-local settlement RPC; Town already listens to that signal.  Scheduling
	# both paths would refresh the same host Town twice.
	if not host_publication and is_inside_tree():
		var scene := get_tree().current_scene
		if scene != null and scene.has_method("_refresh_campaign_settlement_view"):
			scene.call_deferred("_refresh_campaign_settlement_view")
	if host_publication:
		net.publish_settlement_view(_campaign_settlement_snapshot())


# Trophy Hall's last rest is a read-only settlement fact.  Before the Unwritten
# Road clears, the familiar cloth remains over the bow rest.  Afterward the
# rest is empty until the unique actually exists in either authoritative gear
# location; this prevents a campaign clear (or a guest's local save) from
# counterfeiting a legendary display.
func _wayweaver_mount_projection() -> Dictionary:
	var chapters = campaign_state.get("chapters", {})
	var final_chapter = (chapters as Dictionary).get(CampaignData.UNWRITTEN_ROAD, {}) \
		if chapters is Dictionary else {}
	var final_cleared := final_chapter is Dictionary \
		and bool((final_chapter as Dictionary).get("cleared", false))
	if not final_cleared:
		return {"state": "covered", "cosmetic_rune_id": ""}
	var owned := _owned_wayweaver_item()
	if owned.is_empty():
		return {"state": "empty", "cosmetic_rune_id": ""}
	return {"state": "full", "cosmetic_rune_id": String(owned.get("cosmetic_rune_id", ""))}


# A Root Rune is a permanent campaign witness, so this small mutation never
# spends, reserves, or copies it. The unique Wayweaver is the only mutable
# owner of this cosmetic record. Keeping it here, rather than on TrophyHall or
# Player, makes save, host projection, and live equipment presentation agree.
func wayweaver_rune_options() -> Array:
	var selected := String(_owned_wayweaver_item().get("cosmetic_rune_id", ""))
	var result: Array = []
	for rune_id_v in WayweaverRuneCosmetics.ROOT_RUNE_IDS:
		var rune_id := String(rune_id_v)
		var profile := WayweaverRuneCosmetics.profile_for(rune_id)
		result.append({
			"id": rune_id,
			"label": String(profile.get("label", rune_id.replace("_", " ").capitalize())),
			"icon_path": String(profile.get("icon_path", CampaignData.story_icon_path(rune_id))),
			"owned": WayweaverRuneCosmetics.is_owned_rune(rune_id, campaign_state),
			"selected": rune_id == selected,
		})
	return result


func set_wayweaver_cosmetic_rune(rune_id: String) -> Dictionary:
	if not _campaign_is_authority():
		return {"ok": false, "changed": false, "reason": "Only the hearthkeeper can set a Rune while the fire is shared."}
	if not WayweaverRuneCosmetics.is_valid_rune(rune_id):
		return {"ok": false, "changed": false, "reason": "That Root Rune has no Wayweaver binding."}
	if not WayweaverRuneCosmetics.is_owned_rune(rune_id, campaign_state):
		return {"ok": false, "changed": false, "reason": "That Root Rune has not settled into your keeping."}
	var location := _wayweaver_item_location()
	if location.is_empty():
		return {"ok": false, "changed": false, "reason": "Wayweaver must be yours before it can take a Rune."}
	var current := String(location.get("item", {}).get("cosmetic_rune_id", ""))
	if current == rune_id:
		return {"ok": true, "changed": false, "rune_id": rune_id}
	if String(location.get("where", "")) == "pack":
		var index := int(location.get("index", -1))
		if inventory == null or index < 0 or index >= inventory.items.size():
			return {"ok": false, "changed": false, "reason": "Wayweaver moved before the Rune could settle."}
		var item: Dictionary = inventory.items[index] as Dictionary
		item["cosmetic_rune_id"] = rune_id
		inventory.items[index] = item
		# Pack grid cells point at the same item, but normalize them deliberately
		# so an imported/copy-on-write item cannot leave stale display metadata.
		for y in inventory.cells.size():
			for x in inventory.cells[y].size():
				if inventory.cells[y][x] is Dictionary \
						and String((inventory.cells[y][x] as Dictionary).get("kind_id", "")) == "wayweaver":
					inventory.cells[y][x] = item
	else:
		if equipment == null:
			return {"ok": false, "changed": false, "reason": "Wayweaver moved before the Rune could settle."}
		var equipped: Dictionary = equipment.get_slot("weapon") as Dictionary
		if String(equipped.get("kind_id", "")) != "wayweaver":
			return {"ok": false, "changed": false, "reason": "Wayweaver moved before the Rune could settle."}
		equipped["cosmetic_rune_id"] = rune_id
		equipment.slots["weapon"] = equipped
	wayweaver_cosmetic_changed.emit(rune_id)
	notify("%s answers along Wayweaver's bright strand." % String(
		WayweaverRuneCosmetics.profile_for(rune_id).get("label", "The Root Rune")))
	var sfx := get_node_or_null("/root/Sfx") if is_inside_tree() else null
	if sfx != null and sfx.has_method("play_tuned"):
		var profile := WayweaverRuneCosmetics.profile_for(rune_id)
		sfx.play_tuned(String(profile.get("sfx", "wayweaver_rune_green")),
			float(profile.get("sfx_pitch", 1.0)))
	save_now()
	_publish_campaign_settlement_view()
	return {"ok": true, "changed": true, "rune_id": rune_id}


func _wayweaver_item_location() -> Dictionary:
	if equipment != null:
		var equipped = equipment.get_slot("weapon")
		if equipped is Dictionary and String((equipped as Dictionary).get("kind_id", "")) == "wayweaver":
			return {"where": "equipment", "item": (equipped as Dictionary).duplicate(true)}
	if inventory != null:
		for index in inventory.items.size():
			var raw = inventory.items[index]
			if raw is Dictionary and String((raw as Dictionary).get("kind_id", "")) == "wayweaver":
				return {"where": "pack", "index": index, "item": (raw as Dictionary).duplicate(true)}
	return {}


func _owned_wayweaver_item() -> Dictionary:
	if inventory != null:
		for raw in inventory.items:
			if raw is Dictionary and String((raw as Dictionary).get("kind_id", "")) == "wayweaver":
				return (raw as Dictionary).duplicate(true)
	if equipment != null and equipment.slots is Dictionary:
		for raw in (equipment.slots as Dictionary).values():
			if raw is Dictionary and String((raw as Dictionary).get("kind_id", "")) == "wayweaver":
				return (raw as Dictionary).duplicate(true)
	return {}

func _campaign_boss_contract(chart: Dictionary,
		preview: Dictionary = {}) -> Dictionary:
	var contract = chart.get("campaign_contract",
		preview.get("campaign_contract", {}))
	var recipe_id := String(chart.get("recipe_id", preview.get("recipe_id", "")))
	# A chapter's clue recipe is not itself a Boss Chart. Contract identity is
	# the authoritative discriminator here; `chapter_for_recipe` intentionally
	# includes both kinds of recipe for clue settlement.
	var expected := CampaignData.boss_contract(recipe_id)
	if recipe_id == "" or expected.is_empty() or not contract is Dictionary:
		return {}
	if (contract as Dictionary) != expected:
		return {}
	return (contract as Dictionary).duplicate(true)


func _handoff_contract(chart: Dictionary, preview: Dictionary = {}) -> Dictionary:
	var contract = chart.get("handoff_contract",
		preview.get("handoff_contract", {}))
	var recipe_id := String(chart.get("recipe_id", preview.get("recipe_id", "")))
	var expected := CampaignData.handoff_contract(recipe_id)
	if recipe_id == "" or expected.is_empty() or not contract is Dictionary:
		return {}
	if (contract as Dictionary) != expected:
		return {}
	return (contract as Dictionary).duplicate(true)

func _begin_campaign_case_escrow(chart: Dictionary,
		preview: Dictionary = {}) -> Dictionary:
	var result := {"ok": true, "chart": chart.duplicate(true),
		"state": CampaignData.normalize_campaign_state(campaign_state)}
	if not _campaign_is_authority():
		return result
	var contract := _campaign_boss_contract(result.chart, preview)
	var handoff := _handoff_contract(result.chart, preview)
	var recipe_id := String(result.chart.get("recipe_id",
		preview.get("recipe_id", "")))
	# Recheck the pure reservation policy at the host mutation boundary. The
	# preview performs the player-facing version of this test, but a stale or
	# forged direct caller must never consume a pending story Seal into a legacy
	# den Chart.
	var seal_id := String(preview.get("seal_id", result.chart.get("seal_id", "")))
	if seal_id != "" and not CampaignData.seal_use_allowed(campaign_state,
			seal_id, recipe_id):
		return {"ok": false, "reason": "That story Seal belongs to another road.",
			"chart": result.chart, "state": campaign_state}
	if contract.is_empty() and handoff.is_empty():
		var raw_contract = result.chart.get("campaign_contract",
			preview.get("campaign_contract", {}))
		var raw_handoff = result.chart.get("handoff_contract",
			preview.get("handoff_contract", {}))
		if not CampaignData.boss_contract(recipe_id).is_empty() \
				or not CampaignData.handoff_contract(recipe_id).is_empty() \
				or not raw_contract is Dictionary \
				or not (raw_contract as Dictionary).is_empty() \
				or not raw_handoff is Dictionary \
				or not (raw_handoff as Dictionary).is_empty():
			return {"ok": false, "reason": "That Boss Chart contract is incomplete.",
				"chart": result.chart, "state": campaign_state}
		return result
	if not handoff.is_empty():
		if not CampaignData.can_inscribe_handoff(campaign_state, recipe_id):
			return {"ok": false, "reason": "That Summit handoff is already being held.",
				"chart": result.chart, "state": campaign_state}
		var handoff_instance_id := String(result.chart.get("chart_instance_id", ""))
		if handoff_instance_id == "":
			return {"ok": false, "reason": "That Summit Chart has no physical identity.",
				"chart": result.chart, "state": campaign_state}
		result.chart["handoff_contract"] = handoff.duplicate(true)
		var handoff_begun := CampaignData.begin_handoff_escrow(
			campaign_state, handoff_instance_id, recipe_id)
		if not bool(handoff_begun.get("ok", false)):
			return {"ok": false, "reason": "That Summit handoff is already being held.",
				"chart": result.chart, "state": campaign_state}
		result.chart["attempt_id"] = String(handoff_begun.get("attempt_id", ""))
		result.state = handoff_begun.state
		return result
	# New authored Boss Charts must still be eligible at the commit boundary.
	# Legacy sealed Charts have no D1 recipe identity and are preserved.
	if not CampaignData.can_inscribe_boss(campaign_state, recipe_id,
			trade_lv("wayfinding"), trade_lv("wildcraft")):
		return {"ok": false, "reason": "That chapter road is not ready.",
			"chart": result.chart, "state": campaign_state}
	var instance_id := String(result.chart.get("chart_instance_id", ""))
	if instance_id == "":
		return {"ok": false, "reason": "That Boss Chart has no physical identity.",
			"chart": result.chart, "state": campaign_state}
	result.chart["chart_instance_id"] = instance_id
	result.chart["campaign_contract"] = contract.duplicate(true)
	var begun := CampaignData.begin_boss_escrow(campaign_state, instance_id,
		String(contract.get("chapter_id", CampaignData.FIRST_KNOT)))
	if not bool(begun.get("ok", false)):
		return {"ok": false, "reason": "A chapter Chart is already being held.",
			"chart": result.chart, "state": campaign_state}
	result.chart["attempt_id"] = String(begun.get("attempt_id", ""))
	result.state = begun.state
	return result

func _ensure_campaign_case_escrow(chart: Dictionary) -> Dictionary:
	var out := chart.duplicate(true)
	var normalized := CampaignData.normalize_campaign_state(campaign_state)
	var contract := _campaign_boss_contract(out)
	var handoff := _handoff_contract(out)
	var attempt_id := String(out.get("attempt_id",
		out.get("campaign_attempt_id", "")))
	if contract.is_empty() and handoff.is_empty():
		var raw_contract = out.get("campaign_contract", {})
		var raw_handoff = out.get("handoff_contract", {})
		if not CampaignData.boss_contract(String(out.get("recipe_id", ""))).is_empty() \
				or not CampaignData.handoff_contract(String(out.get("recipe_id", ""))).is_empty() \
				or attempt_id != "" \
				or not raw_contract is Dictionary \
				or not (raw_contract as Dictionary).is_empty() \
				or not raw_handoff is Dictionary \
				or not (raw_handoff as Dictionary).is_empty():
			return {"ok": false, "reason": "That chapter Chart binding is invalid.",
				"chart": out, "state": normalized}
		return {"ok": true, "chart": out, "state": normalized}
	var chart_instance_id := String(out.get("chart_instance_id", ""))
	if attempt_id == "" or chart_instance_id == "" \
			or not (normalized.escrows as Dictionary).has(attempt_id):
		return {"ok": false, "reason": "That chapter Chart has no live escrow.",
			"chart": out, "state": normalized}
	var record: Dictionary = normalized.escrows[attempt_id]
	var expected_contract_id := String(contract.get("chapter_id",
		handoff.get("contract_id", "")))
	if String(record.get("chart_instance_id", "")) != chart_instance_id \
			or String(record.get("contract_id", record.get("chapter_id", ""))) \
				!= expected_contract_id:
		return {"ok": false, "reason": "That chapter Chart does not match its escrow.",
			"chart": out, "state": normalized}
	return {"ok": true, "chart": out, "state": normalized}

func _mark_campaign_chart_in_run(chart: Dictionary) -> Dictionary:
	if not _campaign_is_authority():
		return {"ok": true, "chart": chart.duplicate(true),
			"state": CampaignData.normalize_campaign_state(campaign_state)}
	var ensured := _ensure_campaign_case_escrow(chart)
	if not bool(ensured.get("ok", false)):
		return ensured
	var out: Dictionary = ensured.chart
	var attempt_id := String(out.get("attempt_id",
		out.get("campaign_attempt_id", "")))
	if attempt_id == "":
		return ensured
	var contract := _campaign_boss_contract(out)
	var handoff := _handoff_contract(out)
	var marked := CampaignData.mark_handoff_in_run(ensured.state, attempt_id,
		String(out.get("chart_instance_id", "")), String(out.get("recipe_id", ""))) \
		if not handoff.is_empty() else CampaignData.mark_escrow_in_run(
			ensured.state, attempt_id, String(out.get("chart_instance_id", "")),
			String(contract.get("chapter_id", "")))
	if not bool(marked.get("ok", false)):
		return {"ok": false, "reason": "That chapter attempt is already settled.",
			"chart": out, "state": campaign_state}
	return {"ok": true, "chart": out, "state": marked.state}

func _apply_campaign_material_targets(targets: Dictionary,
		exact: bool = false) -> Dictionary:
	var granted := {}
	for item_id_v in targets:
		var item_id := String(item_id_v)
		var target := maxi(0, int(targets[item_id_v]))
		if exact and material_count(item_id) != target:
			var delta := target - material_count(item_id)
			if target <= 0:
				materials.erase(item_id)
			else:
				materials[item_id] = target
			granted[item_id] = delta
			continue
		var missing := maxi(0, target - material_count(item_id))
		if missing <= 0:
			continue
		materials[item_id] = material_count(item_id) + missing
		granted[item_id] = missing
	if not granted.is_empty():
		materials_changed.emit()
	return granted

func _apply_campaign_material_refunds(refunds: Dictionary) -> Dictionary:
	var granted := {}
	for item_id_v in refunds:
		var item_id := String(item_id_v)
		var count := maxi(0, int(refunds[item_id_v]))
		if count <= 0:
			continue
		materials[item_id] = material_count(item_id) + count
		granted[item_id] = count
	if not granted.is_empty():
		materials_changed.emit()
	return granted

func _record_campaign_chart_return(chart: Dictionary) -> Dictionary:
	if not _campaign_is_authority():
		return {"changed": false}
	var recipe_id := String(chart.get("recipe_id", ""))
	var chart_instance_id := String(chart.get("chart_instance_id", ""))
	var transition := CampaignData.record_successful_chart_return(campaign_state,
		recipe_id, chart_instance_id, trade_lv("wayfinding"), materials)
	if not bool(transition.get("changed", false)):
		return transition
	campaign_state = transition.state
	_apply_campaign_material_targets(transition.get("material_awards", {}))
	for rumour_id_v in transition.get("rumour_ids", []):
		_remember_chart_rumour(String(rumour_id_v))
	var chapter_id := String(CampaignData.chapter_for_recipe(recipe_id))
	var chapter: Dictionary = CampaignData.CHAPTERS.get(chapter_id, {})
	var target := int(chapter.get("clue_target", 0))
	var clue_label := String(chapter.get("clue_label", chapter.get("clue_presentation", "clue"))) \
		.replace("_", " ").capitalize()
	var count := CampaignData.chapter_clue_count(campaign_state, chapter_id)
	if target > 0:
		notify("A %s settles into the campaign ledger (%d/%d)." %
			[clue_label, count, target])
	if target > 0 and count >= target:
		var boss_label := String(chapter.get("boss_name", chapter.get("name", "chapter road")))
		notify("The signs agree. Mara can now seal %s." % boss_label)
	_sync_campaign_chart_sources()
	story_changed.emit()
	_publish_campaign_settlement_view()
	return transition

func _refund_campaign_attempt(chart: Dictionary) -> Dictionary:
	if not _campaign_is_authority():
		return {"ok": false, "changed": false, "reason": "host_only"}
	var ensured := _ensure_campaign_case_escrow(chart)
	if not bool(ensured.get("ok", false)):
		return ensured
	var bound_chart: Dictionary = ensured.chart
	var attempt_id := String(bound_chart.get("attempt_id",
		chart.get("campaign_attempt_id", "")))
	if attempt_id == "":
		return {"ok": true, "changed": false}
	var contract := _campaign_boss_contract(bound_chart)
	var handoff := _handoff_contract(bound_chart)
	var transition := CampaignData.refund_handoff_escrow(campaign_state,
		attempt_id, String(bound_chart.get("chart_instance_id", "")),
		String(bound_chart.get("recipe_id", ""))) if not handoff.is_empty() \
		else CampaignData.refund_escrow(campaign_state, attempt_id,
			String(bound_chart.get("chart_instance_id", "")),
			String(contract.get("chapter_id", "")))
	if not bool(transition.get("ok", false)) \
			or not bool(transition.get("changed", false)):
		return transition
	campaign_state = transition.state
	var refunded := _apply_campaign_material_refunds(
		transition.get("material_refunds", {}))
	if not refunded.is_empty():
		var seal_id := String(contract.get("seal_id",
			handoff.get("seal_id", "story seal")))
		notify("Mara's %s returns unbroken." % GatherDefs.material_name(seal_id))
	story_changed.emit()
	_publish_campaign_settlement_view()
	return transition


# Queen death resolves only the safe legacy Summit handoff. It consumes the
# protected Alpha Fang tombstone and deliberately creates no campaign truth.
func resolve_handoff_boss_death(chart: Dictionary) -> Dictionary:
	if not _campaign_is_authority():
		return {"ok": false, "changed": false, "reason": "host_only"}
	var ensured := _ensure_campaign_case_escrow(chart)
	if not bool(ensured.get("ok", false)):
		return ensured
	var bound_chart: Dictionary = ensured.chart
	var handoff := _handoff_contract(bound_chart)
	if handoff.is_empty():
		return {"ok": false, "changed": false, "reason": "not_handoff_boss"}
	var transition := CampaignData.resolve_handoff(campaign_state,
		String(bound_chart.get("attempt_id", "")),
		String(bound_chart.get("chart_instance_id", "")),
		String(bound_chart.get("recipe_id", "")))
	if not bool(transition.get("ok", false)) \
			or not bool(transition.get("changed", false)):
		return transition
	campaign_state = transition.state
	story_changed.emit()
	save_now()
	return transition

# Named campaign-boss death callback for world adapters. A normal dungeon
# return can never originate chapter completion: the caller must present the
# exact authored Boss Chart, with its explicit contract and live attempt.
# This method owns the one durable settlement save; callers must not save or
# grant the campaign rewards separately.
func resolve_campaign_boss_death(chart: Dictionary) -> Dictionary:
	if not _campaign_is_authority():
		return {"ok": false, "changed": false, "reason": "host_only"}
	var ensured := _ensure_campaign_case_escrow(chart)
	if not bool(ensured.get("ok", false)):
		return ensured
	var bound_chart: Dictionary = ensured.chart
	var contract := _campaign_boss_contract(bound_chart)
	if contract.is_empty():
		return {"ok": false, "changed": false, "reason": "not_campaign_boss"}
	var attempt_id := String(bound_chart.get("attempt_id", ""))
	var transition := CampaignData.resolve_boss_death(campaign_state, attempt_id,
		String(bound_chart.get("chart_instance_id", "")),
		String(contract.get("chapter_id", "")))
	if not bool(transition.get("ok", false)) \
			or not bool(transition.get("changed", false)):
		return transition
	var chapter_id := String(contract.get("chapter_id", ""))
	campaign_state = transition.state
	# D8 authored Boss XP is payable only by the same live Chart after the
	# canonical boss settlement.  This transient runtime marker is intentionally
	# not saved or copied into a Memory Chart; the durable escrow remains the
	# source of truth for the actual chapter clear.
	if String(active_chart.get("chart_instance_id", "")) \
			== String(bound_chart.get("chart_instance_id", "")):
		active_chart["campaign_completion_boss_settled"] = true
	# Story-Seal settlement awards are singular physical keys. Old saves that
	# somehow carry extras are reconciled to the authored target, not preserved
	# as duplicate attempts at the next road.
	_apply_campaign_material_targets(transition.get("material_awards", {}),
		chapter_id in [CampaignData.SEVENTH_ROAD, CampaignData.QUEENS_SUMMIT])
	var exact_material_targets = transition.get("material_targets_exact", {})
	if exact_material_targets is Dictionary \
			and not (exact_material_targets as Dictionary).is_empty():
		_apply_campaign_material_targets(exact_material_targets, true)
	if chapter_id == CampaignData.FIRST_KNOT:
		_grant_first_knot_reprise_entitlement()
		# The restored Atlas mark names a reachable, copy-only lesson. Clearing
		# the chapter unlocks the source but does not teach its rumour or recipe.
		_unlock_chart_source("atlas_sallow_shallows")
	elif chapter_id == CampaignData.GOLDEN_WALLOW:
		_unlock_chart_source("atlas_briar_knot")
	elif chapter_id == CampaignData.SEVENTH_ROAD:
		_unlock_chart_source("skald_queens_summit")
	elif chapter_id == CampaignData.QUEENS_SUMMIT:
		# This remains a legacy presentation flag only. CampaignData is the sole
		# Queen authority; setting the old flag keeps post-Summit NPC copy useful
		# without permitting it to infer the chapter on future loads.
		summit_cleared = true
	_sync_campaign_chart_sources()
	# Until every old boss callback is removed, both the material target and
	# Ledger claim remain idempotent around its historical Tusker award.
	if ledger != null and chapter_id == CampaignData.FIRST_KNOT:
		ledger.apply("tusker_tusk")
	elif ledger != null and chapter_id == CampaignData.SEVENTH_ROAD:
		ledger.apply("alpha_fang")
	if not (transition.get("relic_awards", []) as Array).is_empty():
		notify("A Root Rune settles into the town's keeping.")
	if not (transition.get("restoration_awards", []) as Array).is_empty():
		notify("A new corner of Bramblewood opens its doors.")
	story_changed.emit()
	_publish_first_knot_homecoming_view()
	_publish_campaign_settlement_view()
	save_now()
	return transition


# D8's Knot-Eater is deliberately not a death settlement.  The encounter has
# already accepted its exact host naming effect when it calls this narrow
# wrapper; this method alone mutates Campaign, awards physical consequences,
# publishes the projection, and saves. A consumed tombstone returns its durable
# name but never re-applies rewards or overwrites a different road name.
func resolve_unwritten_road_settlement(effect: Dictionary) -> Dictionary:
	if not _campaign_is_authority():
		return {"ok": false, "changed": false, "reason": "host_only"}
	if effect.is_empty() or String(effect.get("effect_id", "")).is_empty():
		return {"ok": false, "changed": false, "reason": "bad_effect"}
	var attempt_id := String(effect.get("attempt_id", ""))
	var chart_id := String(effect.get("chart_instance_id", ""))
	var road_name := String(effect.get("road_name_id", ""))
	var active_contract = active_chart.get("campaign_contract", {})
	if chart_id == "" or attempt_id == "" or String(effect.get("effect_id", "")).begins_with(chart_id + ":" + attempt_id + ":") == false \
			or String(active_chart.get("chart_instance_id", "")) != chart_id \
			or String(active_chart.get("attempt_id", "")) != attempt_id \
			or not active_contract is Dictionary \
			or String((active_contract as Dictionary).get("chapter_id", "")) != CampaignData.UNWRITTEN_ROAD:
		return {"ok": false, "changed": false, "reason": "identity_mismatch"}
	var transition := CampaignData.resolve_unwritten_road(campaign_state, attempt_id,
		chart_id, road_name)
	if not bool(transition.get("ok", false)):
		return transition
	# A replay is valid only for the tombstone's original choice. Never let a
	# second name mutate state after the exact-once resolver has consumed it.
	if not bool(transition.get("changed", false)):
		if String(transition.get("road_name_id", "")) != road_name:
			return {"ok": false, "changed": false, "reason": "road_name_mismatch"}
		return transition
	campaign_state = transition.state
	if String(active_chart.get("chart_instance_id", "")) == chart_id:
		active_chart["campaign_completion_boss_settled"] = true
	_apply_campaign_material_targets(transition.get("material_awards", {}))
	var exact = transition.get("material_targets_exact", {})
	if exact is Dictionary and not (exact as Dictionary).is_empty():
		_apply_campaign_material_targets(exact as Dictionary, true)
	_sync_campaign_chart_sources()
	story_changed.emit()
	_publish_campaign_settlement_view()
	save_now()
	return transition

# SaveGame calls this after restoring an optional campaign_state. An in-run
# escrow cannot be resumed because active_chart is intentionally not persisted,
# so it becomes one exact refund and a durable terminal tombstone.
func reconcile_unresumable_campaign_attempts() -> Dictionary:
	var transition := CampaignData.recover_unresolved_in_run(campaign_state)
	campaign_state = transition.state
	# D2 entitlement compatibility is additive and fill-only. It deliberately
	# does not alter an already-inscribed Chart, chart-table version, or save
	# schema; the recovery persistence hook writes only when this repaired data.
	if _grant_first_knot_reprise_entitlement():
		_campaign_recovery_dirty = true
	# Fill-only migration for saves that cleared First Knot before the Golden
	# chapter source existed. Reading the Atlas still remains a player action.
	if CampaignData.chapter_cleared(campaign_state, CampaignData.FIRST_KNOT) \
			and _unlock_chart_source("atlas_sallow_shallows"):
		_campaign_recovery_dirty = true
	if CampaignData.chapter_cleared(campaign_state, CampaignData.GOLDEN_WALLOW) \
			and _unlock_chart_source("atlas_briar_knot"):
		_campaign_recovery_dirty = true
	if CampaignData.chapter_cleared(campaign_state, CampaignData.SEVENTH_ROAD) \
			and _unlock_chart_source("skald_queens_summit"):
		_campaign_recovery_dirty = true
	if _sync_campaign_chart_sources():
		_campaign_recovery_dirty = true
	if bool(transition.get("changed", false)):
		_apply_campaign_material_refunds(transition.get("material_refunds", {}))
		_campaign_recovery_dirty = true
		_publish_campaign_settlement_view()
	return transition

func _grant_first_knot_reprise_entitlement() -> bool:
	const REPRISE_RECIPE := "first_knot_reprise"
	if not CampaignData.chapter_cleared(campaign_state, CampaignData.FIRST_KNOT) \
			or not ChartsData.CHART_RECIPES.has(REPRISE_RECIPE) \
			or known_chart_recipes.has(REPRISE_RECIPE):
		return false
	known_chart_recipes.append(REPRISE_RECIPE)
	chart_recipe_journal = ChartsData.normalize_recipe_journal(
		chart_recipe_journal, known_chart_recipes)
	chart_knowledge_changed.emit()
	return true

# The D2 reprise is not a campaign boss: it has no escrow or Ledger award.
# Its immutable encounter contract identifies the one deterministic heirloom
# roll, while this seam prevents a duplicate died signal from spawning two.
func claim_first_knot_reprise_reward(chart: Dictionary) -> Dictionary:
	if not _campaign_is_authority():
		return {}
	var encounter = chart.get("encounter_contract", {})
	if not encounter is Dictionary:
		return {}
	var contract: Dictionary = encounter
	if String(chart.get("recipe_id", "")) != "first_knot_reprise" \
			or String(contract.get("boss_kind", "")) != "hedgemother" \
			or int(contract.get("boss_layer", 0)) != 2 \
			or String(contract.get("reward_family_id", "")) != "first_knot_heirlooms" \
			or not bool(contract.get("suppress_chain_trophy", false)):
		return {}
	var reward_seed := int(contract.get("reward_seed", 0))
	if reward_seed <= 0:
		return {}
	var chart_instance_id := String(chart.get("chart_instance_id", ""))
	if chart_instance_id == "":
		return {}
	var claim_key := "%s:%d" % [chart_instance_id, reward_seed]
	if _reprise_reward_claims.has(claim_key):
		return {}
	var item: Dictionary = Drops.select_first_knot_heirloom(reward_seed)
	if item.is_empty():
		return {}
	_reprise_reward_claims[claim_key] = true
	return item.duplicate(true)

# Resolve a pot attempt (the "Try the Mix" verb). An exact recipe match
# mixes — and teaches the recipe the first time. A miss consumes the pot
# (one of the cheapest makings handed back), pays a little Wayfinder xp
# for the lesson, and resolves 60/30/10 smudge / wild ink / serendipity.
# Returns {"outcome": discovery|mix|smudge|wild|serendipity, "ink": id?}.
func try_pot_mix(pot: Dictionary) -> Dictionary:
	if pot.is_empty():
		return {}
	for material_id_v in pot:
		if ChartsData.is_protected_chart_supply(String(material_id_v)):
			return {}
	for ink_id in GatherDefs.INK_RECIPE_ORDER:
		var ink_id_string := String(ink_id)
		var recipe: Dictionary = GatherDefs.INK_RECIPES[ink_id]
		var inputs: Dictionary = recipe.inputs
		if not _pot_match(pot, inputs):
			continue
		var status := ink_recipe_status(ink_id_string)
		if not bool(status.unlocked):
			notify("Wildcraft %d is required to settle %s." % [
				int(status.required_wildcraft), GatherDefs.material_name(ink_id_string)])
			return {"outcome": "locked", "ink": ink_id_string,
				"required_wildcraft": int(status.required_wildcraft)}
		var fresh: bool = not ink_discovered(ink_id_string)
		if not mix_ink(ink_id_string):
			return {}
		if fresh:
			discover_ink(ink_id_string)
			return {"outcome": "discovery", "ink": ink_id_string}
		return {"outcome": "mix", "ink": ink_id_string}
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
	award_xp("wayfinding", 5, "pot_smudge")   # each smudge teaches
	# Spec 45-carto — Curious Fingers: misses smudge less (40/45/15).
	var smudge_at := 0.4 if perk_active("wayfinding", "curious_fingers") else 0.6
	var wild_at := 0.85 if perk_active("wayfinding", "curious_fingers") else 0.9
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
		if not ink_discovered(String(id)) \
				and bool(ink_recipe_status(String(id)).unlocked):
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

# The chart case holds a bounded stack — inscribing is gated on free space so
# charts stay a "use them" resource, not an infinite hoard. Callers that spend
# materials (the bench) must check chart_case_full() BEFORE spending.
const CHART_CASE_MAX := 8

func chart_case_full() -> bool:
	return charts.size() >= CHART_CASE_MAX

var _chart_inscription_active := false
var _chart_table_revision := 0

func _chart_commit_failure(reason: String, preview: Dictionary = {}) -> Dictionary:
	return {"ok": false, "reason": reason, "preview": preview}

func _allocate_chart_seed() -> int:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var seed := int(rng.randi()) & 0x7FFFFFFF
	return 1 if seed == 0 else seed

# The sole physical-table mutation boundary. It re-resolves the live context,
# materializes before spending, and leaves no fallible game operation after the
# cost deduction. Signals fire while the re-entry guard is still raised.
func try_inscribe_chart(draft: Dictionary, expected_fingerprint: String,
		seed: int = 0) -> Dictionary:
	if _chart_inscription_active:
		return _chart_commit_failure("The seal press is already moving.")
	_chart_inscription_active = true
	var result := _try_inscribe_chart_locked(draft, expected_fingerprint, seed)
	_chart_inscription_active = false
	return result

func _try_inscribe_chart_locked(draft: Dictionary, expected_fingerprint: String,
		seed: int) -> Dictionary:
	if net_active():
		var net := get_node_or_null("/root/NetGame")
		if net == null or not depth_choice_allowed(true, bool(net.is_host())):
			return _chart_commit_failure(
				"Only the fire-keeper can inscribe while the fire is shared.")
	var preview := ChartsData.preview_table(draft, chart_table_context())
	if expected_fingerprint == "":
		return _chart_commit_failure("Read the live Chart before setting Mara's seal.",
			preview)
	if expected_fingerprint != String(preview.fingerprint):
		return _chart_commit_failure("The table changed. Read the Chart again.", preview)
	if not bool(preview.get("commit_ready", false)):
		return _chart_commit_failure(String(preview.get("reason", "The road is unfinished.")),
			preview)
	if chart_case_full():
		return _chart_commit_failure("Your chart case is full (max %d)." % CHART_CASE_MAX,
			preview)
	var cost: Dictionary = preview.costs
	if not can_afford(cost):
		return _chart_commit_failure("The table is missing part of the arrangement.", preview)
	var actual_seed := seed
	if actual_seed < 0:
		return _chart_commit_failure("That Chart seed is invalid.", preview)
	if actual_seed == 0:
		actual_seed = _allocate_chart_seed()
	# Materialize first. An invalid authored output can never burn supplies.
	var chart := ChartsData.materialize_chart(preview, actual_seed)
	if chart.is_empty():
		return _chart_commit_failure("The road would not take the ink.", preview)
	# A campaign Boss Chart enters escrow while it is still in the Case. Build
	# that next state before spending so a rejected/open duplicate attempt cannot
	# burn a unique Seal.
	var campaign_commit := _begin_campaign_case_escrow(chart, preview)
	if not bool(campaign_commit.get("ok", false)):
		return _chart_commit_failure(String(campaign_commit.get("reason",
			"That chapter road is not ready.")), preview)
	chart = campaign_commit.chart
	# Commit: affordability was checked synchronously and every remaining
	# operation is an in-memory append/update with no failure branch.
	spend_materials(cost)
	campaign_state = campaign_commit.state
	charts.append(chart)
	charts_changed.emit()
	var discovered := not known_chart_recipes.has(String(preview.recipe_id))
	if discovered:
		var discovered_recipe_id := String(preview.recipe_id)
		known_chart_recipes.append(discovered_recipe_id)
		chart_recipe_journal = ChartsData.journal_with_discovery(
			chart_recipe_journal, discovered_recipe_id, "table_experiment",
			known_chart_recipes)
		chart_knowledge_changed.emit()
		var discovery_xp := ChartsData.recipe_discovery_xp(discovered_recipe_id)
		if discovery_xp > 0:
			award_xp("wayfinding", discovery_xp,
				"chart_discovery:%s" % discovered_recipe_id)
		notify("Recipe found: %s." % String(preview.output.name))
	if not (chart.get("affixes", []) as Array).is_empty() \
			and not bool(seen_hints.get("affix_reading", false)):
		# The table preview has already taught the reading; retain the durable
		# first-contact marker without introducing a second save mid-transaction.
		seen_hints["affix_reading"] = true
	if tutorial_step == 3 and String(chart.get("template_id", "")) == "snug":
		advance_tutorial()
	elif tutorial_step == 6 and String(chart.get("template_id", "")) != "snug":
		advance_tutorial()
	# Invalidate the exact preview instance. A queued second activation now
	# re-resolves with a new fingerprint, while a deliberately re-staged copy is
	# free to preview and inscribe again.
	_chart_table_revision += 1
	notify("Inscribed: %s" % ChartsData.chart_label(chart))
	save_now()
	return {"ok": true, "reason": "", "preview": preview,
		"chart": chart, "discovered": discovered}

func add_chart(chart: Dictionary) -> void:
	# Compatibility/dev callers may still provide a pre-materialized Chart.
	# Treat a serialized Seal as a commit boundary too, so it cannot bypass the
	# physical table's pure reservation check. Older legacy den Charts have no
	# recipe/seal provenance and remain intentionally unaffected.
	var seal_id := String(chart.get("seal_id", ""))
	if seal_id != "" and not CampaignData.seal_use_allowed(campaign_state,
			seal_id, String(chart.get("recipe_id", ""))):
		notify("That story Seal belongs to another road.")
		return
	charts.append(chart)
	charts_changed.emit()
	notify("Inscribed: %s" % ChartsData.chart_label(chart))
	# D14 — first chart that carries affixes: explain reading the twins.
	if not (chart.get("affixes", []) as Array).is_empty():
		first_time_hint("affix_reading")
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
		var campaign_run := _mark_campaign_chart_in_run(chart)
		if not bool(campaign_run.get("ok", false)):
			notify(String(campaign_run.get("reason", "That chapter Chart will not socket.")))
			return
		var run_chart: Dictionary = _freeze_campaign_clue(campaign_run.chart)
		campaign_state = campaign_run.state
		charts.erase(chart)
		charts_changed.emit()
		net.start_run(run_chart)
		return
	var campaign_run := _mark_campaign_chart_in_run(chart)
	if not bool(campaign_run.get("ok", false)):
		notify(String(campaign_run.get("reason", "That chapter Chart will not socket.")))
		return
	_defer_toasts = true       # the dungeon HUD will drain these in _ready
	var run_chart: Dictionary = _freeze_campaign_clue(campaign_run.chart)
	campaign_state = campaign_run.state
	charts.erase(chart)
	charts_changed.emit()
	active_chart = run_chart
	in_dungeon = true
	if String(run_chart.get("template_id", "")) == "snug":
		record_onboarding_event("snug_entered")
	elif String(run_chart.get("template_id", "")) == "tier_1":
		record_onboarding_event("tier1_entered")
	_capture_run_start()
	_snapshot_player(player)
	if tutorial_step == 4:
		advance_tutorial()
	# A fresh run never inherits a stale in-dungeon checkpoint.
	var cp := get_node_or_null("/root/Checkpoint") if is_inside_tree() else null
	if cp != null and cp.has_method("clear"):
		cp.clear()
	save_now()
	# Deferred — interactables call this from physics processing.
	_travel_to_map(DUNGEON_SCENE)

# Step back through the far waystone. Completion XP per the shipped formula.
# Spec 46 Phase B — every peer enters the same chart locally: same seed,
# same geometry, same (seeded) foes. The host's chart was already spent.
func net_enter(chart: Dictionary) -> void:
	_defer_toasts = true
	active_chart = chart
	in_dungeon = true
	_capture_run_start()
	var p := local_player()
	if p != null:
		_snapshot_player(p)
	if tutorial_step == 4:
		advance_tutorial()
	var cp := get_node_or_null("/root/Checkpoint")
	if cp != null and cp.has_method("clear"):
		cp.clear()
	# Host already moved the escrow case -> in_run before broadcasting. Persist
	# the chart removal and attempt state here; guests retain only the replicated
	# chart and can never settle personal campaign state.
	if _campaign_is_authority():
		save_now()
	_travel_to_map(DUNGEON_SCENE)

# Campaign generation inputs are materialized by the host before NetGame
# replicates the Chart. Guests therefore build the identical authored clue
# even when their personal save's campaign ledger differs from the host's.
func _same_campaign_clue(a: Dictionary, b: Dictionary) -> bool:
	return String(a.get("chapter_id", "")) == String(b.get("chapter_id", "")) \
		and String(a.get("clue_id", "")) == String(b.get("clue_id", ""))

func _remove_stale_clue_reward(chart: Dictionary) -> bool:
	var reward := ChartsData.authored_completion_reward(chart)
	if String(reward.get("kind", "")) == "clue":
		chart.erase("authored_completion_xp")
		chart.erase("authored_completion_reward")
		return true
	return false

func _freeze_campaign_clue(chart: Dictionary) -> Dictionary:
	var out := chart.duplicate(true)
	if not _campaign_is_authority():
		return out
	var recipe_id := String(out.get("recipe_id", ""))
	var expected := CampaignData.next_clue_for_chart(campaign_state,
		recipe_id, String(out.get("chart_instance_id", "")), trade_lv("wayfinding"))
	var frozen = out.get("campaign_clue", {})
	if frozen is Dictionary and not (frozen as Dictionary).is_empty():
		if not expected.is_empty() and _same_campaign_clue(frozen, expected):
			var existing_reward := ChartsData.authored_completion_reward(out)
			if not existing_reward.is_empty() and _same_campaign_clue(
					existing_reward, expected):
				return out
		# The table may have held a Chart while another return advanced the
		# ledger. It can still carry the fresh World clue below, but may never
		# replay the replacement XP frozen for the now-stale fact.
		out.erase("campaign_clue")
		_remove_stale_clue_reward(out)
	if not expected.is_empty():
		out["campaign_clue"] = expected.duplicate(true)
		# Two distinct Charts may have been inscribed against the same pending
		# ledger fact. The second remains eligible after the first returns, but
		# now owns the next clue's exact authored total. A replayed Chart ID gets
		# no `expected` clue from CampaignData and can never reach this branch.
		var rebound := ChartsData.campaign_completion_reward_for_clue(
			recipe_id, expected)
		if not rebound.is_empty():
			out["authored_completion_xp"] = int(rebound.get("xp", 0))
			out["authored_completion_reward"] = rebound.duplicate(true)
	return out

# An authored XP field is a materialized promise, but only while it belongs to
# the exact campaign event that made it eligible.  This keeps copied/stale
# clue Charts, unfinished Boss Charts, Memory Charts, and legacy records out
# of the replacement lane while preserving old generic completion math.
func _frozen_campaign_completion_reward_claimable(chart: Dictionary) -> bool:
	var reward := ChartsData.authored_completion_reward(chart)
	if reward.is_empty() or bool(chart.get("campaign_inert", false)) \
			or bool(chart.get("memory_chart", false)) \
			or String(chart.get("recipe_id", "")).begins_with("memory_"):
		return false
	var kind := String(reward.get("kind", ""))
	if kind == "clue":
		var clue = chart.get("campaign_clue", {})
		if not clue is Dictionary or (clue as Dictionary).is_empty() \
				or not _same_campaign_clue(clue, reward):
			return false
		if not _campaign_is_authority():
			return true
		var expected := CampaignData.next_clue_for_chart(campaign_state,
			String(chart.get("recipe_id", "")),
			String(chart.get("chart_instance_id", "")), trade_lv("wayfinding"))
		return not expected.is_empty() and _same_campaign_clue(expected, reward)
	if kind == "boss":
		return bool(chart.get("campaign_completion_boss_settled", false)) \
			and not _campaign_boss_contract(chart).is_empty()
	if kind == "fixed":
		return true
	return false

func _completion_xp_for_successful_return(chart: Dictionary) -> int:
	if not chart.has("authored_completion_xp"):
		return ChartsData.completion_xp(chart)
	if _frozen_campaign_completion_reward_claimable(chart):
		return ChartsData.completion_xp(chart)
	return ChartsData.legacy_completion_xp(chart)

# Spec 45-gaps — `abandoned` skips the completion reward: the entry-side
# return stone carries you home but the chart pays nothing torn.
func return_to_town(player: Node, abandoned: bool = false) -> void:
	_defer_toasts = true       # the town HUD will drain these in _ready
	# Reprise identity, not its outcome, owns Homecoming ineligibility. Tearing
	# the Chart at the return stone must not turn a D2 replay into a chapter-clear
	# event on the following Town frame.
	_homecoming_return_was_d2_reprise = \
		String(active_chart.get("recipe_id", "")) == "first_knot_reprise"
	if abandoned:
		_refund_campaign_attempt(active_chart)
		notify("You tear the chart and step home. The hollow keeps its prize.")
	elif not active_chart.is_empty():
		# C2 source availability joins the existing successful-return save. An
		# abandoned Chart never enters this branch and unlocks nothing.
		_unlock_chart_sources_for_completed_chart(active_chart)
		var xp := _completion_xp_for_successful_return(active_chart)
		award_xp("wayfinding", xp,
			"chart_return:%s" % String(active_chart.get("recipe_id", "")))
		# Campaign clue eligibility intentionally reads the Wayfinding level after
		# completion XP. A level-3 return that crosses to 4 therefore counts.
		_record_campaign_chart_return(active_chart)
		var purse := ChartsData.completion_gold(active_chart)
		gold += purse
		gold_changed.emit(gold)
		notify("Chart complete — %d Wayfinder XP." % xp)
		# Wayfinding signature — the debrief names the bargain you struck:
		# which good twins paid out, which bad twins you delved under anyway.
		# (notify() buffers across the scene change → reads in town.)
		var goods: Array = []
		var bads: Array = []
		var tyrannical := false
		for a in active_chart.get("affixes", []):
			var nm := String(ChartsData.affix_presentation(active_chart, a)
				.get("name", ""))
			if nm == "":
				continue
			if bool(a.get("good", false)):
				goods.append(nm)
				if String(a.get("id", "")) == "tyrannical":
					tyrannical = true
			else:
				bads.append(nm)
		if not goods.is_empty():
			notify("The chart gave you: %s." % ", ".join(goods))
		if not bads.is_empty():
			notify("Its bad twins held: %s." % ", ".join(bads))
		if tyrannical:
			notify("Tyrannical foes paid the richer purse.")
		# The end the whole chain builds toward.
		if String(active_chart.get("template_id", "")) == "summit" \
				and not summit_cleared:
			summit_cleared = true
			notify("★ The Summit is charted. The Queen's nest stands empty.")
			notify("Mara will want to hear of this.")
		# Typed seam for future overlays / co-op exit-debrief. Snapshot the
		# chart BEFORE it's cleared.
		if String(active_chart.get("template_id", "")) == "tier_1":
			seen_hints["tier1_completed"] = true
			record_onboarding_event("tier1_completed")
			onboarding_changed.emit()
		elif String(active_chart.get("template_id", "")) == "snug":
			record_onboarding_event("snug_completed")
			grant_first_return_chart_supplies()
		elif String(active_chart.get("template_id", "")) == "first_road":
			seen_hints["first_road_completed"] = true
			record_onboarding_event("first_road_completed")
			onboarding_changed.emit()
			notify("The First Road lamp has been lit in the yard.")
		run_completed.emit((active_chart as Dictionary).duplicate(true), xp)
		pending_run_debrief = _make_run_debrief(active_chart, xp)
	active_chart = {}
	pending_run_layout = {}
	_reprise_reward_claims.clear()
	in_dungeon = false
	_returning_from_delve = true   # B7 — the town reads + clears this for its arrival beat
	_snapshot_player(player)
	if tutorial_step == 5:
		advance_tutorial()
	var cp := get_node_or_null("/root/Checkpoint") if is_inside_tree() else null
	if cp != null and cp.has_method("clear"):
		cp.clear()
	save_now()
	# Deferred — the exit waystone calls this from physics processing.
	if is_inside_tree():
		_travel_to_map(TOWN_SCENE)

func can_press_deeper() -> bool:
	return not active_chart.is_empty() and ChartsData.can_press_deeper(active_chart)

func next_depth_omen() -> Dictionary:
	return ChartsData.next_omen(active_chart) if can_press_deeper() else {}

# Far-Waystone choice: keep the same authored Chart and its Affixes, accept the
# shown Omen, and generate the next layer. Completion pays only on safe return.
func press_deeper(player: Node) -> bool:
	if not can_press_deeper():
		return false
	if net_active():
		var net := get_node_or_null("/root/NetGame")
		if net == null or not bool(net.is_host()):
			notify("Only the fire-keeper may press the Chart deeper.")
			return false
	var deeper := ChartsData.deepen(active_chart)
	if deeper.is_empty():
		return false
	if net_active():
		(get_node("/root/NetGame") as Node).deepen_run(deeper)
		return true
	return _enter_deeper_layer(deeper, player)

# NetGame broadcasts the complete materialized Chart then calls this on every
# peer. No re-materialization occurs, so host and guest rebuild the same layer.
func net_deepen(chart: Dictionary) -> void:
	if chart.is_empty():
		return
	_enter_deeper_layer(chart, local_player())

func _enter_deeper_layer(deeper: Dictionary, player: Node) -> bool:
	_defer_toasts = true
	active_chart = deeper
	_snapshot_player(player)
	notify("Layer %d — Omen accepted: %s." % [int(active_chart.layer),
		String((active_chart.omens as Array).back().name)])
	var cp := get_node_or_null("/root/Checkpoint")
	if cp != null and cp.has_method("clear"):
		cp.clear()
	if _campaign_is_authority():
		save_now()
	_travel_to_map(DUNGEON_SCENE)
	return true

func _capture_run_start() -> void:
	_run_start_snapshot = {
		"materials": materials.duplicate(),
		"gold": gold,
		"items": inventory.items.size() if inventory != null else 0,
	}

func _make_run_debrief(chart: Dictionary, xp: int) -> Dictionary:
	var found: Array = []
	var before_mats: Dictionary = _run_start_snapshot.get("materials", {})
	var ids: Array = materials.keys()
	ids.sort()
	for id in ids:
		var delta := int(materials[id]) - int(before_mats.get(id, 0))
		if delta > 0:
			found.append("%d %s" % [delta, GatherDefs.material_name(String(id))])
	var gold_delta := gold - int(_run_start_snapshot.get("gold", gold))
	found.push_front("%d gold" % gold_delta)
	var item_delta := (inventory.items.size() if inventory != null else 0) \
		- int(_run_start_snapshot.get("items", 0))
	if item_delta > 0:
		found.append("%d pack find%s" % [item_delta, "" if item_delta == 1 else "s"])
	var template_id := String(chart.get("template_id", ""))
	var opened := "Another Chart, drawn by your own hand"
	var preparation := false
	if template_id == "snug":
		opened = "Tier 1 Hollow · ink sockets · one preparation"
		preparation = not bool(seen_hints.get("first_return_preparation", false))
	elif template_id == "tier_1":
		opened = "Hollow Charts · trophy-marked dens · the Living Atlas"
	elif template_id == "first_road":
		opened = "The First Road lamp · Power Shot · a changed yard"
	return {
		"template_id": template_id,
		"found": " · ".join(found),
		"rose": "+%d Wayfinding XP · Wayfinding %d" % [xp, trade_lv("wayfinding")],
		"opened": opened,
		"preparation": preparation,
	}

func run_debrief_text(debrief: Dictionary) -> String:
	return "Found — %s\n\nRose — %s\n\nOpened — %s" % [
		String(debrief.get("found", "")), String(debrief.get("rose", "")),
		String(debrief.get("opened", ""))]

func clear_pending_run_debrief() -> void:
	pending_run_debrief = {}
	save_now()

# Town may clear the transient return source after it has handled the arrival.
# This is not an acknowledgement and never changes campaign or save state.
func clear_first_knot_homecoming_return_context() -> void:
	_homecoming_return_was_d2_reprise = false

# First Snug return: pick one useful next-run preparation. The claim is
# one-shot even if a dialog is reopened after a save or scene interruption.
func claim_first_return_preparation(choice: int) -> bool:
	if bool(seen_hints.get("first_return_preparation", false)):
		return false
	var item := "hearth_draught" if choice == 0 else "hedge_ink"
	add_material(item, 1)
	seen_hints["first_return_preparation"] = true
	notify("Set aside: %s." % GatherDefs.material_name(item))
	save_now()
	return true

# The first chapter closes on a preference, not a build commitment. It gives
# the standing objective a little personality while leaving every Chart,
# Skill, and reward path available.
func choose_onboarding_intention(choice: int) -> void:
	var intentions := ["strength", "materials", "mystery"]
	if choice >= 0 and choice < intentions.size():
		seen_hints["third_chart_intention"] = intentions[choice]
	seen_hints["third_chart_choice_seen"] = true
	record_onboarding_event("first_chapter_complete")
	save_now()
	onboarding_changed.emit()

func dismiss_onboarding_intention() -> void:
	if bool(seen_hints.get("third_chart_choice_seen", false)):
		return
	seen_hints["third_chart_choice_seen"] = true
	record_onboarding_event("first_chapter_complete")
	save_now()
	onboarding_changed.emit()

# ADR 0013 — power multiplier per level, applied to BOTH the player (in
# player_controller._derive_stats) and a den's enemies (in layout_loader).
# Net difficulty ≈ (LEVEL_POWER^2)^(den_level − player_level). The tuning knob
# for the level-delta curve (≤−2 easy, ±1 fair, ≥+2 very hard).
const LEVEL_POWER := 1.25

# Each den's level is tier-derived (enemies scale to it). Single source of
# truth — run_cfg() and the waystone difficulty preview both read it.
const DEN_LEVEL_BY_TIER := {1: 3, 2: 8, 3: 13}

func den_level_for_tier(tier: int) -> int:
	return int(DEN_LEVEL_BY_TIER.get(tier, 3))

# Wayfinding signature — the strategic read BEFORE the delve: how hard is this
# chart's den vs. your current Wayfinding level? Returns {label, tone}; the
# waystone panel maps tone → colour. Net difficulty tracks (den_level −
# player_level) per ADR 0013 (≤−2 easy, ±1 fair, ≥+2 hard).
func difficulty_band(chart: Dictionary) -> Dictionary:
	var delta := den_level_for_tier(int(chart.get("tier", 1))) - trade_lv("wayfinding")
	if delta <= -2:
		return {"label": "Gentle", "tone": "easy"}
	elif delta <= 1:
		return {"label": "Fair", "tone": "fair"}
	elif delta <= 3:
		return {"label": "Steep", "tone": "hard"}
	return {"label": "Deadly", "tone": "deadly"}

# The generation config handed to DungeonGen.generate(). {} when booting
# World.tscn directly (dev) — which keeps today's defaults, boss included.
func run_cfg() -> Dictionary:
	if active_chart.is_empty():
		return {}
	var t: Dictionary = ChartsData.TEMPLATES.get(String(active_chart.template_id), {})
	var cfg: Dictionary = (t.get("gen", {}) as Dictionary).duplicate()
	cfg["template_id"] = String(active_chart.get("template_id", ""))
	cfg["tier"] = int(active_chart.get("tier", 1))
	# ADR 0013 — each den carries a level (tier-derived); enemies scale to it.
	cfg["den_level"] = den_level_for_tier(int(cfg["tier"]))
	cfg["scope"] = String(active_chart.get("scope", "crypt"))
	cfg["affixes"] = active_chart.get("affixes", [])
	cfg["layer"] = int(active_chart.get("layer", 1))
	cfg["max_layers"] = int(active_chart.get("max_layers", 1))
	cfg["omens"] = active_chart.get("omens", [])
	cfg["seed"] = int(active_chart.get("seed", -1))
	# Ashen's first-elite decision was materialized at inscription. World may
	# consume and present this exact descriptor but must never reroll it.
	var elite_manifest = active_chart.get("elite_manifest", {})
	if elite_manifest is Dictionary and not (elite_manifest as Dictionary).is_empty():
		cfg["elite_manifest"] = (elite_manifest as Dictionary).duplicate(true)
	# D2 depth data is authored at inscription. The runtime only adapts the
	# currently realized layer: the added terminal layer must contain a real
	# Hearth/rest focal, never merely hope the ordinary typed-room budget does.
	var depth_contract = active_chart.get("depth_contract", {})
	if depth_contract is Dictionary:
		var depth: Dictionary = depth_contract
		if not depth.is_empty():
			cfg["depth_contract"] = depth.duplicate(true)
			if int(cfg["layer"]) == int(depth.get("hearth_layer", -1)):
				cfg["required_room_roles"] = ["rest"]
	# The reprise's encounter is likewise a frozen inscription promise. Layer 1
	# is intentionally boss-free even if future Affixes add another boss source.
	var encounter_contract = active_chart.get("encounter_contract", {})
	if encounter_contract is Dictionary and not (encounter_contract as Dictionary).is_empty():
		cfg["encounter_contract"] = (encounter_contract as Dictionary).duplicate(true)
	# Publish authored campaign metadata as immutable generation inputs. World and
	# DungeonGen may present these records, but campaign-state math stays here.
	var authored_contract := _campaign_boss_contract(active_chart)
	if not authored_contract.is_empty():
		cfg["campaign_contract"] = authored_contract.duplicate(true)
	var handoff = active_chart.get("handoff_contract", {})
	if handoff is Dictionary and not (handoff as Dictionary).is_empty():
		var expected_handoff := CampaignData.handoff_contract(
			String(active_chart.get("recipe_id", "")))
		if (handoff as Dictionary) == expected_handoff:
			cfg["handoff_contract"] = (handoff as Dictionary).duplicate(true)
	var campaign_clue = active_chart.get("campaign_clue", {})
	# Compatibility for direct/offline test and developer entrypoints that set
	# active_chart without crossing the Waystone. Live runs are frozen above.
	if (not campaign_clue is Dictionary or (campaign_clue as Dictionary).is_empty()) \
			and _campaign_is_authority():
		campaign_clue = CampaignData.next_clue_for_chart(campaign_state,
			String(active_chart.get("recipe_id", "")),
			String(active_chart.get("chart_instance_id", "")), trade_lv("wayfinding"))
	if not campaign_clue.is_empty():
		cfg["campaign_clue"] = campaign_clue
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
	# Slice D Boss Charts carry an authored encounter contract. It overrides the
	# good/bad den Affix so a paid campaign Seal can never open an empty lair.
	if bool(authored_contract.get("guaranteed", false)):
		cfg["boss_kind"] = String(authored_contract.get("boss_kind", ""))
	if handoff is Dictionary and bool((handoff as Dictionary).get("guaranteed", false)):
		cfg["boss_kind"] = String((handoff as Dictionary).get("boss_kind", ""))
	if encounter_contract is Dictionary and not (encounter_contract as Dictionary).is_empty():
		var encounter: Dictionary = encounter_contract
		cfg["boss_kind"] = String(encounter.get("boss_kind", "")) \
			if int(cfg["layer"]) == int(encounter.get("boss_layer", -1)) else ""
	for omen in cfg["omens"]:
		cfg["enemy_density"] = float(cfg.get("enemy_density", 1.0)) \
			* float(omen.get("enemy_density_mult", 1.0))
		cfg["enemy_damage_mult"] = float(cfg.get("enemy_damage_mult", 1.0)) \
			* float(omen.get("enemy_damage_mult", 1.0))
	return cfg


func pack_reader_view() -> Dictionary:
	if trade_lv("huntcraft") < 21:
		return {"available": false, "eligible": false}
	var manifest = active_chart.get("elite_manifest", {})
	if not manifest is Dictionary or (manifest as Dictionary).is_empty():
		return {"available": true, "eligible": false}
	var out := (manifest as Dictionary).duplicate(true)
	out["available"] = true
	out["read_only"] = true
	return out

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
	# The first return from Snug is the authored Power Shot lesson. It is the
	# only Focus Skill a normal new player receives before choosing to pursue
	# later Huntcraft unlocks.
	if tutorial_step == 6:
		grant_skill("PowerShot", true)
	mark_onboarding_progress()
	tutorial_changed.emit(tutorial_step)
	# A step may already be satisfied by out-of-order play (herbs foraged
	# before talking to Mara, a Snug inscribed early) — re-check on entry.
	_tutorial_check_satisfied()

# D13 — the sub-objective line: while delving, names the chart you're inside
# (its affixes) so the run's bargain stays visible under the main objective.
func objective_sub() -> String:
	if in_dungeon and not active_chart.is_empty():
		return ChartsData.chart_label(active_chart)
	return ""

func objective_text() -> String:
	if first_road_active():
		if bool(seen_hints.get("first_road_completed", false)):
			return "First Road complete — the new lamp burns beside Mara"
		if String(seen_hints.get("first_road_profile", "")) == "":
			return "Speak with Mara and choose the temper of your first road"
		if in_dungeon:
			return "Find the far Waystone and bring the Chart home"
		return "Socket your First Road Chart at the Waystone"
	if tutorial_step < 0 or tutorial_step >= TUTORIAL_OBJECTIVES.size():
		return ""
	# Town objectives can't be acted on mid-run — point at the exit instead.
	if in_dungeon and tutorial_step < 5:
		return TUTORIAL_OBJECTIVES[5]
	if tutorial_step == 6 and not bool(seen_hints.get("power_shot_practiced", false)):
		return "Try Power Shot on the practice bramble"
	if tutorial_step == 7:
		if in_dungeon:
			return "Find the far Waystone and read what the ink changed"
		if bool(seen_hints.get("tier1_completed", false)) \
				and not bool(seen_hints.get("third_chart_choice_seen", false)):
			return "Return to Mara with what you found"
		if not bool(seen_hints.get("tier1_completed", false)):
			return "Socket your Tier 1 Chart at the Waystone"
		match String(seen_hints.get("third_chart_intention", "")):
			"strength": return "Prepare a combat-leaning Chart"
			"materials": return "Prepare a gathering-leaning Chart"
			"mystery": return "Prepare a Chart and search its side rooms"
			_: return "Prepare your next Chart"
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
