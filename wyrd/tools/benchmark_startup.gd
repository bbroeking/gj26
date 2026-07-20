extends SceneTree

# Repeatable startup benchmark for the hitch between pressing New Game and the
# first responsive Town frame.
#
# Run:
#   WYRD_NO_SAVE=1 godot --headless --path . \
#     --script res://tools/benchmark_startup.gd

const TOWN_PATH := "res://scenes/Town.tscn"
const SETTLE_FRAMES := 3
const CLICK_BUDGET_MS := 250.0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var prewarm_started := Time.get_ticks_usec()
	if ResourceLoader.load_threaded_request(TOWN_PATH) != OK:
		push_error("Could not request %s" % TOWN_PATH)
		quit(1)
		return
	while ResourceLoader.load_threaded_get_status(TOWN_PATH) \
			== ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		await process_frame
	var click_started := Time.get_ticks_usec()
	var packed := ResourceLoader.load_threaded_get(TOWN_PATH) as PackedScene
	var loaded := Time.get_ticks_usec()
	if packed == null:
		push_error("Could not load %s" % TOWN_PATH)
		quit(1)
		return
	var town := packed.instantiate()
	var instantiated := Time.get_ticks_usec()
	root.add_child(town)
	var attached := Time.get_ticks_usec()
	for _i in SETTLE_FRAMES:
		await process_frame
	var settled := Time.get_ticks_usec()
	var prewarm_ms := float(click_started - prewarm_started) / 1000.0
	var load_ms := float(loaded - click_started) / 1000.0
	var instantiate_ms := float(instantiated - loaded) / 1000.0
	var attach_ms := float(attached - instantiated) / 1000.0
	var settle_ms := float(settled - attached) / 1000.0
	var click_ms := float(settled - click_started) / 1000.0
	print("STARTUP prewarm=%.1fms click_load=%.1fms instantiate=%.1fms attach=%.1fms settle=%.1fms click_total=%.1fms nodes=%d budget=%.0fms" % [
		prewarm_ms, load_ms, instantiate_ms, attach_ms, settle_ms, click_ms,
		_count_nodes(town), CLICK_BUDGET_MS])
	quit(0 if click_ms <= CLICK_BUDGET_MS else 1)

func _count_nodes(node: Node) -> int:
	var total := 1
	for child in node.get_children():
		total += _count_nodes(child)
	return total
