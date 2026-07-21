class_name TownEnvironment
extends Node3D

# Wyrd — the Chartmaker's Yard environment pass. The yard used to be a flat
# single-color plane with six oaks; this node owns everything that makes it
# read as a storybook clearing instead of an empty field:
#
#   · mottled two-green ground (noise shader, replaces the flat albedo)
#   · a dirt path network — plaza hub with spokes to every station
#   · a treeline ring sealing the clearing (the invisible bounds get a face)
#   · MultiMesh grass tufts + wildflower dots, kept off the paths
#   · scatter dressing from the existing GLB shelf
#
# Town.gd instantiates one and calls setup() with the yard layout.

const OAK_GLB := preload("res://models/oak_v4.glb")
const BUSH_GLB := preload("res://models/prop_herb_bush_v1.glb")
const LANTERN_GLB := preload("res://models/memorial_lantern_v2.glb")
const RACK_GLB := preload("res://models/drying_rack_v2.glb")
const DUMMY_GLB := preload("res://models/practice_dummy_v2.glb")
const BRAMBLE_GLB := preload("res://models/withered_bramble_v2.glb")
const FENCE_GLB := preload("res://models/prop_fence_v1.glb")
const FLOWERS_GLB := preload("res://models/prop_flowers_v1.glb")

# Spec 76 — Town's authored materials currently land in a narrow, pale value
# band even in Forward+, then clip further in Web Compatibility. Adjust only
# the duplicated 3D Environment so parchment and Field Journal UI stay exact.
const GRADE_BRIGHTNESS_NATIVE := 0.62
const GRADE_BRIGHTNESS_WEB := 0.56
const GRADE_CONTRAST := 1.15
const GRADE_SATURATION := 1.08

const GRASS_COUNT := 700
const FLOWER_COUNT := 140
const PATH_CLEAR := 1.5            # grass keeps this far from path centers
const STATION_CLEAR := 2.2         # ...and from interactables

var _yard := 40.0
var _plaza := Vector3(20.0, 0.0, 21.0)
var _stations: Array = []          # Vector3s grass must keep clear of
var _spokes: Array = []            # path destinations (subset of stations)
var _treeline_breaks: Array = []   # restored roads may visibly pierce the ring
var _path_points: Array = []       # sampled path centers (Vector3)
var _rng := RandomNumberGenerator.new()

# B7 — ambient life state
const MOTE_COUNT := 12             # drifting firefly/dust motes (capped cheap)
var _mote_nodes: Array = []        # MeshInstance3D references for sway update
var _mote_phases: Array = []       # float phase offset per mote (varied drift)
var _lantern_lights: Array = []    # OmniLight3D refs for flicker
var _lantern_phases: Array = []    # float phase offset per lantern
var _ambient_t := 0.0              # running time for procedural sway


static func apply_tonal_grade(env: Environment, web_feature: bool,
		force_web: String = "") -> bool:
	if env == null:
		return false
	env.adjustment_enabled = true
	env.adjustment_brightness = GRADE_BRIGHTNESS_WEB \
		if web_feature or force_web != "" else GRADE_BRIGHTNESS_NATIVE
	env.adjustment_contrast = GRADE_CONTRAST
	env.adjustment_saturation = GRADE_SATURATION
	return true

func setup(yard: float, plaza: Vector3, stations: Array, spokes: Array,
		treeline_breaks: Array = []) -> void:
	_yard = yard
	_plaza = plaza
	_stations = stations
	_spokes = spokes
	_treeline_breaks = treeline_breaks
	_rng.seed = 26                 # the yard looks the same every visit

func _ready() -> void:
	_build_paths()
	_build_treeline()
	_build_grass_and_flowers()
	_build_scatter()
	# B7 — ambient life: drifting motes + lantern flicker driven by _process.
	_build_ambient_motes()
	_gather_lantern_lights()
	set_process(true)

# ---- ground (called by town.gd in place of its flat material) ----
# Two greens mixed by large noise + a fine brightness grain. Shader, not
# texture, so it stays crisp at any zoom and costs nothing to author.
static func ground_material() -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
uniform sampler2D noise_tex;
uniform vec3 base_col : source_color = vec3(0.43, 0.56, 0.30);
uniform vec3 alt_col : source_color = vec3(0.36, 0.50, 0.26);
uniform vec3 dry_col : source_color = vec3(0.55, 0.58, 0.33);
void fragment() {
	float big = texture(noise_tex, UV * 5.0).r;
	float mid = texture(noise_tex, UV * 13.0 + 0.37).r;
	float fine = texture(noise_tex, UV * 60.0).r;
	vec3 col = mix(base_col, alt_col, smoothstep(0.38, 0.62, big));
	col = mix(col, dry_col, smoothstep(0.72, 0.85, mid) * 0.5);
	col *= 0.95 + 0.10 * fine;
	ALBEDO = col;
	ROUGHNESS = 1.0;
}
"""
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = 0.8
	noise.fractal_octaves = 3
	var nt := NoiseTexture2D.new()
	nt.noise = noise
	nt.seamless = true
	nt.width = 256
	nt.height = 256
	var mat := ShaderMaterial.new()
	mat.shader = sh
	mat.set_shader_parameter("noise_tex", nt)
	return mat

# ---- dirt paths: plaza hub, one spoke per station ----
func _build_paths() -> void:
	var dirt := StandardMaterial3D.new()
	dirt.albedo_color = Color(0.52, 0.42, 0.30)
	dirt.roughness = 1.0
	var dirt_alt := StandardMaterial3D.new()
	dirt_alt.albedo_color = Color(0.47, 0.38, 0.27)
	dirt_alt.roughness = 1.0
	for station in _spokes:
		var from := _plaza
		var to: Vector3 = station
		var dist := from.distance_to(to)
		var steps := int(dist / 0.7) + 1
		for i in steps:
			var t := float(i) / float(steps)
			# A lazy sine wobble so the spokes meander like footpaths.
			var p := from.lerp(to, t)
			var side := (to - from).cross(Vector3.UP).normalized()
			p += side * sin(t * PI * 2.0 + from.x) * 0.45
			_path_points.append(p)
			var disc := CylinderMesh.new()
			# Narrow near the plaza so converging spokes don't pool into a
			# mud blob; widen slightly toward the destination.
			var w := lerpf(0.30, 0.55, t) * _rng.randf_range(0.85, 1.15)
			disc.top_radius = w
			disc.bottom_radius = w
			disc.height = 0.02
			disc.radial_segments = 9
			var mi := MeshInstance3D.new()
			mi.mesh = disc
			mi.material_override = dirt if _rng.randf() < 0.6 else dirt_alt
			mi.position = Vector3(p.x, 0.012 + _rng.randf() * 0.004, p.z)
			add_child(mi)

# ---- treeline: the clearing's storybook wall ----
func _build_treeline() -> void:
	var half := _yard * 0.5
	var center := Vector3(half, 0.0, half)
	var count := 34
	for i in count:
		var ang := TAU * float(i) / float(count) + _rng.randf_range(-0.06, 0.06)
		var radius := half + _rng.randf_range(-1.5, 1.5)
		var pos := center + Vector3(cos(ang), 0.0, sin(ang)) * radius
		if _near_treeline_break(pos):
			continue
		var oak: Node3D = OAK_GLB.instantiate()
		GlbFit.normalize_height(oak, _rng.randf_range(4.6, 7.2))
		GlbFit.unmetal(oak)
		oak.position = pos
		oak.rotation.y = _rng.randf() * TAU
		add_child(oak)
	# A second, sparser inner rank so the wall has depth, not a picket line.
	for i in 14:
		var ang := TAU * float(i) / 14.0 + 0.22
		var pos := center + Vector3(cos(ang), 0.0, sin(ang)) * (half - 3.2)
		if _too_close(pos, STATION_CLEAR + 1.5) or _near_treeline_break(pos):
			continue
		var oak: Node3D = OAK_GLB.instantiate()
		GlbFit.normalize_height(oak, _rng.randf_range(3.4, 5.0))
		GlbFit.unmetal(oak)
		oak.position = pos
		oak.rotation.y = _rng.randf() * TAU
		add_child(oak)

# ---- grass + flowers (MultiMesh — hundreds of instances, one draw call) ----
func _build_grass_and_flowers() -> void:
	var grass_mesh := CylinderMesh.new()    # thin cone reads as a tuft
	grass_mesh.top_radius = 0.0
	grass_mesh.bottom_radius = 0.07
	grass_mesh.height = 0.26
	grass_mesh.radial_segments = 5
	grass_mesh.rings = 1
	var grass_mat := StandardMaterial3D.new()
	grass_mat.albedo_color = Color(0.38, 0.55, 0.27)
	grass_mat.roughness = 1.0
	grass_mesh.material = grass_mat
	_scatter_multimesh(grass_mesh, GRASS_COUNT, 0.7, 1.6, 0.13)

	var flower_mesh := SphereMesh.new()
	flower_mesh.radius = 0.045
	flower_mesh.height = 0.09
	flower_mesh.radial_segments = 6
	flower_mesh.rings = 3
	var flower_mat := StandardMaterial3D.new()
	flower_mat.albedo_color = Color(0.95, 0.88, 0.62)
	flower_mat.roughness = 0.9
	flower_mesh.material = flower_mat
	_scatter_multimesh(flower_mesh, FLOWER_COUNT, 0.8, 1.3, 0.07)

func _scatter_multimesh(mesh: Mesh, count: int, min_s: float, max_s: float,
		base_y: float) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	var placed: Array = []
	var tries := 0
	while placed.size() < count and tries < count * 8:
		tries += 1
		var pos := Vector3(_rng.randf_range(2.0, _yard - 2.0), 0.0,
			_rng.randf_range(2.0, _yard - 2.0))
		if _too_close(pos, STATION_CLEAR) or _near_path(pos):
			continue
		var xf := Transform3D(Basis().rotated(Vector3.UP, _rng.randf() * TAU)
			.scaled(Vector3.ONE * _rng.randf_range(min_s, max_s)),
			pos + Vector3(0.0, base_y, 0.0))
		placed.append(xf)
	mm.instance_count = placed.size()
	for i in placed.size():
		mm.set_instance_transform(i, placed[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)

# ---- scatter dressing from the existing shelf ----
func _build_scatter() -> void:
	# Lanterns flank the plaza where the spokes meet.
	for off in [Vector3(1.6, 0.0, 1.2), Vector3(-1.8, 0.0, -0.8)]:
		_drop(LANTERN_GLB, _plaza + off, 1.5)
	# Decorative bushes (the gather prop, non-interactable) soften corners.
	for i in 9:
		var pos := Vector3(_rng.randf_range(3.0, _yard - 3.0), 0.0,
			_rng.randf_range(3.0, _yard - 3.0))
		if _too_close(pos, STATION_CLEAR + 0.5) or _near_path(pos):
			continue
		_drop(BUSH_GLB, pos, _rng.randf_range(0.5, 0.95))
	# Withered brambles hug the treeline — the wild pressing at the edge.
	for i in 8:
		var ang := TAU * float(i) / 8.0 + 0.4
		var half := _yard * 0.5
		var pos := Vector3(half, 0.0, half) \
			+ Vector3(cos(ang), 0.0, sin(ang)) * (half - 2.2)
		_drop(BRAMBLE_GLB, pos, _rng.randf_range(0.9, 1.4))
	# Homestead touches: drying rack by the cottage, dummy by the forge.
	_drop(RACK_GLB, Vector3(11.5, 0.0, 9.5), 1.6)
	_drop(DUMMY_GLB, Vector3(30.0, 0.0, 14.5), 1.5)
	# Wildflower clumps wherever the grass allows.
	var planted := 0
	var tries := 0
	while planted < 7 and tries < 60:
		tries += 1
		var pos := Vector3(_rng.randf_range(4.0, _yard - 4.0), 0.0,
			_rng.randf_range(4.0, _yard - 4.0))
		if _too_close(pos, STATION_CLEAR) or _near_path(pos):
			continue
		_drop(FLOWERS_GLB, pos, _rng.randf_range(0.45, 0.7))
		planted += 1
	# Fence runs: a garden line by the cottage, and two wings framing the
	# south entrance behind the spawn.
	_fence_run(Vector3(5.0, 0.0, 12.5), 0.0, 3)
	_fence_run(Vector3(13.5, 0.0, 30.0), 0.0, 3)
	_fence_run(Vector3(23.0, 0.0, 30.0), 0.0, 3)

# A straight run of fence segments laid end to end along +X (rotated by
# `angle`). Segment width is measured from the fitted GLB so they join.
func _fence_run(start: Vector3, angle: float, count: int) -> void:
	var probe: Node3D = FENCE_GLB.instantiate()
	GlbFit.normalize_height(probe, 0.95)
	var width: float = maxf(0.8, GlbFit.merged_aabb(probe, Transform3D.IDENTITY).size.x)
	probe.free()
	var dir := Vector3(cos(angle), 0.0, sin(angle))
	for i in count:
		var seg: Node3D = FENCE_GLB.instantiate()
		GlbFit.normalize_height(seg, 0.95)
		GlbFit.unmetal(seg)
		seg.position = start + dir * (width * float(i))
		seg.rotation.y = -angle + _rng.randf_range(-0.04, 0.04)   # storybook crooked
		add_child(seg)

func _drop(packed: PackedScene, pos: Vector3, target_h: float) -> void:
	var inst: Node3D = packed.instantiate()
	GlbFit.normalize_height(inst, target_h)
	GlbFit.unmetal(inst)
	inst.position = pos
	inst.rotation.y = _rng.randf() * TAU
	add_child(inst)

# ---- placement filters ----
func _too_close(pos: Vector3, clearance: float) -> bool:
	for s in _stations:
		if pos.distance_to(s) < clearance:
			return true
	return false


func _near_treeline_break(pos: Vector3) -> bool:
	for opening_v in _treeline_breaks:
		if opening_v is Vector3 and pos.distance_to(opening_v as Vector3) < 5.2:
			return true
	return false

func _near_path(pos: Vector3) -> bool:
	for p in _path_points:
		if pos.distance_to(p) < PATH_CLEAR:
			return true
	return false

# ---- B7 — ambient life ----

# Spawn MOTE_COUNT cheap billboard quads that drift gently in _process.
# They float in a loose band just above the plaza and herb beds.
# Origins are stored in _mote_phases (x/z are the phase float; the resting
# world positions are kept in a parallel _mote_origins array).
var _mote_origins: Array = []     # Vector3 rest positions, set once in build

func _build_ambient_motes() -> void:
	var rng_m := RandomNumberGenerator.new()
	rng_m.seed = 99
	# Three flavour pools: warm firefly (golden), cool dust (grey-blue), leaf green.
	var colors: Array[Color] = [
		Color(0.96, 0.88, 0.42, 0.65),
		Color(0.78, 0.86, 0.95, 0.45),
		Color(0.62, 0.92, 0.60, 0.50),
	]
	for _i in MOTE_COUNT:
		var mi := MeshInstance3D.new()
		var qm := QuadMesh.new()
		qm.size = Vector2(0.06, 0.06)
		mi.mesh = qm
		var mat := StandardMaterial3D.new()
		var cidx: int = int(rng_m.randf_range(0.0, float(colors.size()) - 0.01))
		mat.albedo_color = colors[cidx]
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.no_depth_test = true
		mi.material_override = mat
		# Scatter across the plaza ± 6 m, floating 0.4–1.8 m above ground.
		var origin := _plaza + Vector3(
			rng_m.randf_range(-6.0, 6.0),
			rng_m.randf_range(0.4, 1.8),
			rng_m.randf_range(-6.0, 6.0))
		mi.position = origin
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
		_mote_nodes.append(mi)
		_mote_phases.append(rng_m.randf() * TAU)
		_mote_origins.append(origin)

# Collect OmniLight3D children of the lantern dressing so we can flicker them.
# Lanterns are dropped as direct children via _drop(); we scan for any
# OmniLight3D one level deep inside each child node.
func _gather_lantern_lights() -> void:
	var rng_l := RandomNumberGenerator.new()
	rng_l.seed = 77
	for child in get_children():
		for sub in child.get_children():
			if sub is OmniLight3D:
				_lantern_lights.append(sub)
				_lantern_phases.append(rng_l.randf() * TAU)

# Drive ambient life every frame: drift motes + flicker lanterns.
# Cost: one sin/cos + one property write per mote/lantern — negligible.
func _process(delta: float) -> void:
	_ambient_t += delta
	# Oscillate each mote around its rest origin using a slow Lissajous curve.
	# Reading from _mote_origins avoids the additive-drift problem.
	for i in _mote_nodes.size():
		var mi: MeshInstance3D = _mote_nodes[i] as MeshInstance3D
		if not is_instance_valid(mi):
			continue
		var ph: float = _mote_phases[i]
		var org: Vector3 = _mote_origins[i]
		# X and Z at different frequencies → organic, never perfectly circular.
		mi.position = org + Vector3(
			sin(_ambient_t * 0.35 + ph) * 0.25,
			sin(_ambient_t * 0.18 + ph * 1.3) * 0.12,
			cos(_ambient_t * 0.28 + ph * 0.7) * 0.22)
		# Soft alpha pulse — fireflies breathe in and out.
		var mat: StandardMaterial3D = mi.material_override as StandardMaterial3D
		if mat != null:
			var c: Color = mat.albedo_color
			c.a = 0.35 + 0.40 * (0.5 + 0.5 * sin(_ambient_t * 0.9 + ph))
			mat.albedo_color = c
	# Flicker lantern OmniLights with two overlaid sines → organic, no branching.
	for j in _lantern_lights.size():
		var light: OmniLight3D = _lantern_lights[j] as OmniLight3D
		if not is_instance_valid(light):
			continue
		var lph: float = _lantern_phases[j]
		light.light_energy = 1.8 \
			+ 0.22 * sin(_ambient_t * 2.1 + lph) \
			+ 0.10 * sin(_ambient_t * 5.3 + lph * 1.7)
