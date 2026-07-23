extends SceneTree

# Spec 78 — the existing Town landmarks form one north-yard working edge while
# protecting every established approach and the accepted arrival composition.

const CameraRigScene = preload("res://scenes/CameraRig.tscn")
const TownEnvironmentScript = preload("res://scripts/town_environment.gd")

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


func _xz_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x, a.z).distance_to(Vector2(b.x, b.z))


func _distance_to_segment(point: Vector3, start: Vector3, finish: Vector3) -> float:
	var p := Vector2(point.x, point.z)
	var a := Vector2(start.x, start.z)
	var b := Vector2(finish.x, finish.z)
	var line := b - a
	var t := clampf((p - a).dot(line) / line.length_squared(), 0.0, 1.0)
	return p.distance_to(a + line * t)


func _run() -> void:
	print("--- Town working edge ---")
	root.size = Vector2i(1280, 720)
	var town_scene := load("res://scenes/Town.tscn") as PackedScene
	var town := town_scene.instantiate()
	var layout: Dictionary = town.north_landmark_layout()
	check("working edge owns exactly the three established landmarks",
		layout.keys().size() == 3
		and layout.has("cottage") and layout.has("tower") and layout.has("forge"))

	var cottage: Dictionary = layout.cottage
	var tower: Dictionary = layout.tower
	var forge: Dictionary = layout.forge
	check("landmarks retain cottage → tower → forge order",
		(cottage.position as Vector3).x < (tower.position as Vector3).x
		and (tower.position as Vector3).x < (forge.position as Vector3).x)
	var north_z := [float((cottage.position as Vector3).z),
		float((tower.position as Vector3).z), float((forge.position as Vector3).z)]
	check("three exteriors form one compact north band",
		north_z.max() - north_z.min() <= 1.5, north_z)
	check("working edge stays north of Mara",
		north_z.max() < town.WAYFINDER_POS.z - 6.0, north_z)

	var route_clear := true
	for entry in layout.values():
		route_clear = route_clear and _distance_to_segment(entry.position,
			town.PLAYER_SPAWN, town.WAYFINDER_POS) > float(entry.radius) + 1.0
	check("direct ranger-to-Mara route stays physically open", route_clear)
	check("cottage leaves the Chart-table approach open",
		_xz_distance(cottage.position, town.TABLE_POS) - float(cottage.radius) >= 2.0)
	check("smithy leaves the Waystone approach open",
		_xz_distance(forge.position, town.WAYSTONE_POS) - float(forge.radius) >= 1.5)
	check("tower leaves the practice space open",
		_xz_distance(tower.position, town.PRACTICE_POS) - float(tower.radius) >= 1.0)

	var support_count := 0
	var supports_clear_plaza := true
	for entry in layout.values():
		for support in entry.supports:
			support_count += 1
			supports_clear_plaza = supports_clear_plaza \
				and _xz_distance(support, Vector3(20.0, 0.0, 21.0)) >= 6.0
	check("all established building-owned supports stay attached",
		support_count == 11, support_count)
	check("attached work clusters do not claim the central plaza",
		supports_clear_plaza)

	town.call("_build_environment")
	var environment = null
	for child in town.get_children():
		if child.get_script() == TownEnvironmentScript:
			environment = child
			break
	check("production environment receives the same landmark owners",
		environment != null
		and environment.get("_landmarks").cottage == cottage.position
		and environment.get("_landmarks").forge == forge.position)

	var rig := CameraRigScene.instantiate()
	root.add_child(rig)
	var profile: Dictionary = town.town_camera_profile()
	rig.apply_play_profile(profile.pitch, profile.zoom, profile.framing_forward)
	rig.apply_cinematic_frame({
		"focus": town._town_camera_focus(town.PLAYER_SPAWN),
		"yaw": 0.0,
		"pitch": profile.pitch,
		"zoom": profile.zoom,
	})
	var camera := rig.get_node("Camera") as Camera3D
	var facades_visible := true
	var facade_points := {}
	for key in layout:
		var screen := camera.unproject_position(
			(layout[key].position as Vector3) + Vector3(0.0, 1.2, 0.0))
		facade_points[key] = screen
		facades_visible = facades_visible and screen.y > 0.0 and screen.y < 180.0
	check("all three lower facades enter the accepted 1280×720 frame",
		facades_visible, facade_points)

	rig.free()
	town.free()
	print("--- Town working edge: %d PASS, %d FAIL ---" % [passed, failed])
	quit(1 if failed > 0 else 0)

