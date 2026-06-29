extends SceneTree

# Throwaway QA viewer — renders a row of biome prop GLBs to a screenshot so the
# Meshy lowpoly output can be eyeballed up close. Uses a SubViewport (offscreen
# render) so it captures reliably under --script.
#   godot --path . --script res://tools/view_biome_props.gd --quit-after 600

const PROPS := [
	"res://models/biome_mineral_seam_orevein_v1.glb",
	"res://models/biome_mineral_seam_crystals_v1.glb",
	"res://models/biome_mineral_seam_minecart_v1.glb",
	"res://models/biome_mineral_seam_timber_v1.glb",
	"res://models/biome_mineral_seam_lantern_v1.glb",
	"res://models/biome_mineral_seam_rubble_v1.glb",
	"res://models/biome_mineral_seam_mushrooms_v1.glb",
]
const OUT := "/tmp/biome_props_montage.png"

func _initialize() -> void:
	_run()

func _run() -> void:
	var sub := SubViewport.new()
	sub.size = Vector2i(1400, 480)
	sub.world_3d = World3D.new()
	sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(sub)

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.86, 0.82, 0.72)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.78, 0.78, 0.75)
	env.ambient_light_energy = 1.1
	var we := WorldEnvironment.new()
	we.environment = env
	sub.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, -35, 0)
	sun.light_energy = 1.4
	sub.add_child(sun)

	var n := PROPS.size()
	var spacing := 1.7
	var span := (n - 1) * spacing
	var cx := span * 0.5
	var cam := Camera3D.new()
	sub.add_child(cam)
	cam.look_at_from_position(Vector3(cx, 3.0, span * 0.55 + 5.0),
		Vector3(cx, 0.7, 0.0), Vector3.UP)
	cam.current = true

	var x := 0.0
	for p in PROPS:
		if ResourceLoader.exists(p):
			var packed = load(p)
			if packed != null:
				var inst: Node3D = packed.instantiate()
				sub.add_child(inst)
				GlbFit.normalize_height(inst, 1.3)
				for vi in _meshes(inst):
					var m: Mesh = vi.mesh
					if m == null:
						continue
					for s in range(m.get_surface_count()):
						var mat := m.surface_get_material(s)
						if mat is BaseMaterial3D:
							(mat as BaseMaterial3D).metallic = 0.0
				inst.position = Vector3(x, 0.0, 0.0)
		x += spacing

	await physics_frame
	await physics_frame
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img := sub.get_texture().get_image()
	img.save_png(OUT)
	print("[view_biome_props] %d meshes, saved %s" % [_meshes(sub).size(), OUT])
	quit()

func _meshes(node: Node) -> Array:
	var out := []
	if node is MeshInstance3D:
		out.append(node)
	for c in node.get_children():
		out.append_array(_meshes(c))
	return out
