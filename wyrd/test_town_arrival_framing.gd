extends SceneTree

# Spec 77 — Town authors one composition through the production CameraRig.
# The contract checks the same 1280×720 projection used for rendered evidence.

const CameraRigScene = preload("res://scenes/CameraRig.tscn")

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
	call_deferred("_run")


func _run() -> void:
	print("--- Town arrival framing ---")
	root.size = Vector2i(1280, 720)
	var town_scene := load("res://scenes/Town.tscn") as PackedScene
	var town := town_scene.instantiate()
	var profile: Dictionary = town.town_camera_profile()
	check("Town keeps the established FATE pitch",
		is_equal_approx(float(profile.pitch), 38.0))
	check("Town uses a bounded pulled-back view",
		float(profile.zoom) > 16.5 and float(profile.zoom) <= 22.0,
		profile.zoom)
	check("Town gathers the view ahead of the ranger",
		float(profile.framing_forward) >= 3.0
		and float(profile.framing_forward) <= 4.0,
		profile.framing_forward)

	var rig := CameraRigScene.instantiate()
	root.add_child(rig)
	rig.apply_play_profile(float(profile.pitch), float(profile.zoom),
		float(profile.framing_forward))
	var applied: Dictionary = rig.play_profile()
	check("production rig accepts the Town profile",
		is_equal_approx(float(applied.pitch), float(profile.pitch))
		and is_equal_approx(float(applied.zoom), float(profile.zoom))
		and is_equal_approx(float(applied.framing_forward),
			float(profile.framing_forward)))

	var spawn: Vector3 = town.PLAYER_SPAWN
	var focus: Vector3 = town._town_camera_focus(spawn)
	check("arrival focus keeps height and shifts only toward Mara",
		focus.is_equal_approx(spawn + Vector3(0.0, 1.0,
			-town.TOWN_CAMERA_FORWARD_FRAME)), focus)
	rig.apply_cinematic_frame({
		"focus": focus,
		"yaw": 0.0,
		"pitch": float(profile.pitch),
		"zoom": float(profile.zoom),
	})
	var camera := rig.get_node("Camera") as Camera3D
	var player_screen := camera.unproject_position(spawn + Vector3(0.0, 1.0, 0.0))
	var mara_screen := camera.unproject_position(
		town.WAYFINDER_POS + Vector3(0.0, 1.0, 0.0))
	var tower_screen := camera.unproject_position(
		town.TOWER_POS + Vector3(0.0, 1.0, 0.0))
	check("ranger anchors in the lower half",
		player_screen.y > 360.0 and player_screen.y < 680.0, player_screen)
	check("Mara remains comfortably inside the playable frame",
		mara_screen.y > 70.0 and mara_screen.y < 360.0, mara_screen)
	check("north landmark base contributes to the frame",
		tower_screen.y > 0.0 and tower_screen.y < 200.0, tower_screen)

	rig.free()
	town.free()
	print("--- Town arrival framing: %d PASS, %d FAIL ---" % [passed, failed])
	quit(1 if failed > 0 else 0)
