extends SceneTree

# Fast regression for the strict D7 control-handoff success criterion.  The
# browser route owns the process/physics awaits; this pure tracker proves that
# success requires three consecutive observations from one scene owner and
# that either a modal predicate or owner transition resets the sequence.

const D7ControlStability = preload("res://scripts/d7_control_stability.gd")

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
	print("--- D7 owner-bound control stability ---")
	var tracker = D7ControlStability.new()
	check("one or two observations cannot release control",
		not tracker.observe("Town:41", true)
			and not tracker.observe("Town:41", true), tracker.receipt())
	check("the third same-owner observation releases control",
		tracker.observe("Town:41", true), tracker.receipt())

	tracker = D7ControlStability.new()
	tracker.observe("World:7", true)
	tracker.observe("World:7", true)
	check("a paused/modal predicate resets an almost-stable handoff",
		not tracker.observe("World:7", false)
			and not tracker.observe("World:7", true)
			and not tracker.observe("World:7", true), tracker.receipt())
	check("three new clear observations are required after the modal",
		tracker.observe("World:7", true), tracker.receipt())

	tracker = D7ControlStability.new()
	tracker.observe("World:7", true)
	tracker.observe("World:7", true)
	check("a scene-owner change cannot inherit the prior World's stability",
		not tracker.observe("World:8", true)
			and not tracker.observe("World:8", true)
			and tracker.observe("World:8", true), tracker.receipt())
	var receipt: Dictionary = tracker.receipt()
	check("receipt proves three process/physics-separated owner observations",
		int(receipt.get("required_observations", 0)) == 3
			and int(receipt.get("consecutive_observations", 0)) == 3
			and bool(receipt.get("process_observation_between_checks", false))
			and bool(receipt.get("physics_observation_between_checks", false)), receipt)

	print("--- D7 control stability: %d PASS, %d FAIL ---" % [passed, failed])
	quit(1 if failed > 0 else 0)
