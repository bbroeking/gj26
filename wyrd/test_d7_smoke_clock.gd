extends SceneTree

# Contract seam for D7's browser-only simulation lease. This never constructs
# Game, a Town, or a World: it proves the clock owner cannot mutate gameplay
# truth while still enforcing its gate/boundary/terminal guarantees.

const D7SmokeClock = preload("res://scripts/d7_smoke_clock.gd")
const GameScript = preload("res://scripts/game.gd")

var passed := 0
var failed := 0


func check(label: String, ok: bool, detail = "") -> void:
	if ok:
		passed += 1
		print("  ✓ %s" % label)
	else:
		failed += 1
		print("  ✗ %s %s" % [label, str(detail)])


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	print("--- D7 owned simulation-clock contract ---")
	var original_scale := Engine.time_scale
	# A pre-existing 7x clock is not a baseline that the D7 owner may capture or
	# normalize. Refusal must happen before *any* Engine mutation.
	Engine.time_scale = 7.0
	var over_cap_baseline = D7SmokeClock.new()
	check("a pre-existing 7x baseline is refused without mutating Engine time",
		not over_cap_baseline.begin(true, true) \
			and is_equal_approx(Engine.time_scale, 7.0) \
			and over_cap_baseline.telemetry().get("last_refusal", "") == "baseline_scale_over_cap" \
			and not bool(over_cap_baseline.telemetry().get("baseline_valid", true)),
		over_cap_baseline.telemetry())
	# A non-default finite baseline proves restore is lease-owned rather than
	# silently returning to the old hitstop constant of 1.0.
	Engine.time_scale = 2.5
	var clock = D7SmokeClock.new()

	check("query gate refuses any non-Web/non-D7 caller",
		not clock.begin(false, true) and is_equal_approx(Engine.time_scale, 2.5),
		clock.telemetry())
	check("fresh boundary refuses activation before its observable report",
		not clock.begin(true, false) and is_equal_approx(Engine.time_scale, 2.5),
		clock.telemetry())
	check("only an active query after fresh_campaign captures and applies exact 6x",
		clock.begin(true, true, "fresh_campaign") and is_equal_approx(Engine.time_scale, 6.0),
		clock.telemetry())
	var active: Dictionary = clock.telemetry()
	check("activation evidence uses the browser probe's strict schema",
		active.get("owner", "") == "d7_smoke_clock" \
			and bool(active.get("activated_after_fresh_campaign", false)) \
			and is_equal_approx(float(active.get("requested_scale", 0.0)), 6.0) \
			and is_equal_approx(float(active.get("observed_scale", 0.0)), 6.0) \
			and is_equal_approx(float(active.get("max_observed_scale", 0.0)), 6.0) \
			and is_equal_approx(float(active.get("captured_baseline_scale", 0.0)), 2.5) \
			and active.get("watchdog_clock", "") == "monotonic_real_time",
		active)
	check("a duplicate begin is refused without replacing the first lease",
		not clock.begin(true, true) and clock.is_active() \
			and is_equal_approx(Engine.time_scale, 6.0) \
			and bool(clock.telemetry().get("double_begin_refused", false)),
		clock.telemetry())
	clock.record_watchdog("training_start", 8.0, true)
	clock.record_watchdog("training_start", 8.0, true, true)
	var complete: Dictionary = clock.restore("complete")
	check("complete restores the captured baseline before terminal serialization",
		is_equal_approx(Engine.time_scale, 2.5) \
			and bool(complete.get("restored_before_terminal_serialization", false)) \
			and bool(complete.get("restored", false)) \
			and complete.get("terminal_reason", "") == "complete" \
			and is_equal_approx(float(complete.get("terminal_scale", 0.0)), 2.5) \
			and complete.get("training_start_watchdog", {}) == {
				"duration_sec": 8.0, "ignore_time_scale": true,
				"armed": false, "fired": true},
		complete)

	# Exercise the Game wrapper without constructing a Town/World or mutating
	# campaign state. The internal owner is activated directly because native
	# tests deliberately do not satisfy the exported-Web query gate.
	Engine.time_scale = 3.25
	var complete_game = GameScript.new()
	complete_game.web_smoke_enabled = true
	complete_game.web_smoke_d7_enabled = true
	complete_game._web_smoke_d7_stage = "terminal_owner"
	complete_game._web_smoke_d7_clock.begin(true, true)
	complete_game._d7_sync_simulation_clock_evidence()
	complete_game.web_smoke_report("complete")
	var complete_feature: Dictionary = complete_game.web_smoke_features.get(
		"d7_simulation_clock", {})
	check("Game complete report syncs restoration before its terminal state",
		complete_game.web_smoke_phase == "complete" \
			and is_equal_approx(Engine.time_scale, 3.25) \
			and bool(complete_feature.get("restored_before_terminal_serialization", false)) \
			and bool(complete_feature.get("restored", false)) \
			and complete_feature.get("terminal_reason", "") == "complete" \
			and is_equal_approx(float(complete_feature.get("terminal_scale", 0.0)), 3.25),
		complete_feature)
	var completed_history: Array = complete_game.web_smoke_history.duplicate(true)
	var completed_payload: Dictionary = complete_game._web_smoke_terminal_payload.duplicate(true)
	complete_game._web_smoke_d7_fail("late coroutine after complete")
	check("the D7 fail helper cannot mutate stage or payload after terminal completion",
		complete_game._web_smoke_d7_stage == "terminal_owner"
			and complete_game.web_smoke_phase == "complete"
			and complete_game.web_smoke_history == completed_history
			and complete_game._web_smoke_terminal_payload == completed_payload,
		{"stage": complete_game._web_smoke_d7_stage,
			"history": complete_game.web_smoke_history,
			"payload": complete_game._web_smoke_terminal_payload})
	complete_game.free()

	Engine.time_scale = 3.75
	var failed_game = GameScript.new()
	failed_game.web_smoke_enabled = true
	failed_game.web_smoke_d7_enabled = true
	failed_game._web_smoke_d7_clock.begin(true, true)
	failed_game._d7_sync_simulation_clock_evidence()
	failed_game.web_smoke_report("failed", "intentional focused failure")
	var failure_feature: Dictionary = failed_game.web_smoke_features.get(
		"d7_simulation_clock", {})
	check("Game failed report restores before serializing the failure receipt",
		failed_game.web_smoke_phase == "failed" \
			and is_equal_approx(Engine.time_scale, 3.75) \
			and bool(failure_feature.get("restored", false)) \
			and failure_feature.get("terminal_reason", "") == "failed",
		failure_feature)
	var failed_history: Array = failed_game.web_smoke_history.duplicate(true)
	var failed_payload: Dictionary = failed_game._web_smoke_terminal_payload.duplicate(true)
	failed_game.web_smoke_report("checkpoint_after_failure")
	failed_game.web_smoke_report("complete")
	check("the first terminal failure latches history and browser payload against late coroutines",
		failed_game.web_smoke_phase == "failed"
			and failed_game.web_smoke_history == failed_history
			and failed_game._web_smoke_terminal_payload == failed_payload
			and bool(failed_game._web_smoke_terminal_latched),
		{"history": failed_game.web_smoke_history,
			"payload": failed_game._web_smoke_terminal_payload})
	failed_game.free()

	Engine.time_scale = 5.0
	var over_cap_game = GameScript.new()
	over_cap_game.web_smoke_enabled = true
	over_cap_game.web_smoke_d7_enabled = true
	over_cap_game._web_smoke_d7_clock.begin(true, true)
	Engine.time_scale = 7.0
	over_cap_game.web_smoke_report("checkpoint")
	var over_cap_feature: Dictionary = over_cap_game.web_smoke_features.get(
		"d7_simulation_clock", {})
	check("an over-cap observation fails closed and restores the captured baseline",
		over_cap_game.web_smoke_phase == "failed" \
			and over_cap_game._web_smoke_d7_stage == "failed" \
			and is_equal_approx(Engine.time_scale, 5.0) \
			and is_equal_approx(float(over_cap_feature.get("max_observed_scale", 0.0)), 7.0) \
			and bool(over_cap_feature.get("restored", false)) \
			and over_cap_feature.get("terminal_reason", "") == "failed",
		over_cap_feature)
	over_cap_game.free()

	Engine.time_scale = 4.25
	var exit_game = GameScript.new()
	exit_game.web_smoke_enabled = true
	exit_game.web_smoke_d7_enabled = true
	exit_game._web_smoke_d7_clock.begin(true, true)
	exit_game._exit_tree()
	var exit_feature: Dictionary = exit_game.web_smoke_features.get("d7_simulation_clock", {})
	check("Game exit-tree safety restoration cannot leave an accelerated clock",
		is_equal_approx(Engine.time_scale, 4.25) \
			and bool(exit_feature.get("restored", false)) \
			and exit_feature.get("terminal_reason", "") == "exit_tree",
		exit_feature)
	exit_game.free()

	# The terminal watchdog is armed by Game at lease activation. A short,
	# debug-only injected duration lets this focused proof cover the real
	# SceneTreeTimer ownership contract without sleeping for the 840-second
	# release interval.
	Engine.time_scale = 2.75
	var watchdog_game = GameScript.new()
	root.add_child(watchdog_game)
	watchdog_game.web_smoke_enabled = true
	watchdog_game.web_smoke_d7_enabled = true
	watchdog_game._web_smoke_d7_clock.begin(true, true)
	watchdog_game._web_smoke_d7_terminal_watchdog_test_duration_sec = 0.02
	watchdog_game._d7_arm_terminal_watchdog()
	await create_timer(0.08, true, false, true).timeout
	var watchdog_feature: Dictionary = watchdog_game.web_smoke_features.get(
		"d7_simulation_clock", {})
	var watchdog_receipt: Dictionary = watchdog_feature.get("terminal_watchdog", {})
	check("terminal watchdog fires into one failed receipt and restores the baseline",
		watchdog_game.web_smoke_phase == "failed" \
			and is_equal_approx(Engine.time_scale, 2.75) \
			and bool(watchdog_receipt.get("fired", false)) \
			and not bool(watchdog_receipt.get("armed", true)) \
			and bool(watchdog_receipt.get("ignore_time_scale", false)) \
			and int(watchdog_receipt.get("generation", -1)) > 0 \
			and String(watchdog_receipt.get("attempt_token", "")).begins_with("d7_fresh_campaign_") \
			and watchdog_feature.get("terminal_reason", "") == "failed",
		watchdog_feature)
	watchdog_game.queue_free()
	await process_frame

	Engine.time_scale = 2.875
	var stale_game = GameScript.new()
	root.add_child(stale_game)
	stale_game.web_smoke_enabled = true
	stale_game.web_smoke_d7_enabled = true
	stale_game._web_smoke_d7_clock.begin(true, true)
	stale_game._web_smoke_d7_terminal_watchdog_test_duration_sec = 0.05
	stale_game._d7_arm_terminal_watchdog()
	stale_game.web_smoke_report("complete")
	var terminal_history_size: int = stale_game.web_smoke_history.size()
	await create_timer(0.12, true, false, true).timeout
	var stale_feature: Dictionary = stale_game.web_smoke_features.get(
		"d7_simulation_clock", {})
	var stale_receipt: Dictionary = stale_feature.get("terminal_watchdog", {})
	check("terminal transition invalidates the timer; its later callback is stale and a no-op",
		stale_game.web_smoke_phase == "complete" \
			and stale_game.web_smoke_history.size() == terminal_history_size \
			and is_equal_approx(Engine.time_scale, 2.875) \
			and bool(stale_receipt.get("cancelled", false)) \
			and bool(stale_receipt.get("stale", false)) \
			and not bool(stale_receipt.get("fired", true)),
		stale_feature)
	stale_game.queue_free()
	await process_frame

	Engine.time_scale = original_scale
	print("--- D7 owned simulation-clock contract: %d PASS, %d FAIL ---" % [passed, failed])
	quit(1 if failed > 0 else 0)
