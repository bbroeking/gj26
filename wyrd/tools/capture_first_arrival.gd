extends SceneTree

# Visual/performance contract for the title → first Town arrival seam.
# Run without --headless so the real renderer and onboarding vignette execute:
#   WYRD_NO_SAVE=1 godot --path . --script res://tools/capture_first_arrival.gd

const TOWN := "res://scenes/Town.tscn"
const COVER_SHOT := "/tmp/wayfinder_first_arrival_cover.png"
const VIGNETTE_SHOT := "/tmp/wayfinder_first_arrival_after_barrier.png"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := root.get_node_or_null("Game")
	if game == null:
		push_error("First-arrival capture requires the Game autoload")
		quit(1)
		return
	game.persistence_enabled = false
	game.reset_to_defaults()
	var started := Time.get_ticks_usec()
	change_scene_to_file(TOWN)
	await scene_changed
	var town := current_scene
	var scene_ready := Time.get_ticks_usec()
	var cover := town.get_node_or_null("FirstArrivalCover") if town != null else null
	if cover == null:
		push_error("First arrival did not install its render-barrier cover")
		quit(1)
		return
	await RenderingServer.frame_post_draw
	var first_draw := Time.get_ticks_usec()
	var image := root.get_texture().get_image()
	if image != null:
		image.save_png(COVER_SHOT)
	var deadline := Time.get_ticks_msec() + 1500
	while is_instance_valid(cover) and Time.get_ticks_msec() < deadline:
		await process_frame
	await RenderingServer.frame_post_draw
	var vignette: Variant = town.get("_micro_cutscene") if town != null else null
	var image2 := root.get_texture().get_image()
	if image2 != null:
		image2.save_png(VIGNETTE_SHOT)
	var elapsed_scene := float(scene_ready - started) / 1000.0
	var elapsed_draw := float(first_draw - started) / 1000.0
	print("FIRST ARRIVAL scene_ready=%.1fms first_draw=%.1fms cover_released=%s vignette_active=%s" % [
		elapsed_scene, elapsed_draw, not is_instance_valid(cover),
		vignette != null and is_instance_valid(vignette)])
	quit(0 if not is_instance_valid(cover) and vignette != null \
		and is_instance_valid(vignette) else 1)
