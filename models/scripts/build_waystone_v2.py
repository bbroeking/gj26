import bpy
import math
import os
import random
from mathutils import Vector


ROOT = "/Users/bbroeking/projects/gj26"
OUT_GLB = os.path.join(ROOT, "models", "waypoint_cairn_v2.glb")
OUT_BLEND = os.path.join(ROOT, "docs", "assets", "blender", "waypoint_cairn_v2.blend")
PREVIEW = os.path.join(ROOT, "docs", "assets", "blender", "waypoint_cairn_v2_preview.png")
random.seed(260720)


def clear_scene():
    if bpy.context.object and bpy.context.object.mode != "OBJECT":
        bpy.ops.object.mode_set(mode="OBJECT")
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for datablocks in (bpy.data.meshes, bpy.data.curves, bpy.data.materials,
                       bpy.data.cameras, bpy.data.lights):
        for datablock in list(datablocks):
            if datablock.users == 0:
                datablocks.remove(datablock)


def material(name, color, roughness=0.9, emission=None, emission_strength=0.0):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    bsdf.inputs["Roughness"].default_value = roughness
    if emission is not None:
        bsdf.inputs["Emission Color"].default_value = (*emission, 1.0)
        bsdf.inputs["Emission Strength"].default_value = emission_strength
    return mat


def apply_bevel(obj, width=0.04, segments=2):
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    mod = obj.modifiers.new("Soft chipped edges", "BEVEL")
    mod.width = width
    mod.segments = segments
    mod.limit_method = "ANGLE"
    mod.angle_limit = math.radians(28)
    bpy.ops.object.modifier_apply(modifier=mod.name)
    obj.select_set(False)
    for poly in obj.data.polygons:
        poly.use_smooth = True


def prism_from_profile(name, profile, depth, mat, bevel=0.045):
    # Profile is a clockwise list of (x, z) points, extruded along Y.
    verts = [(x, -depth / 2, z) for x, z in profile]
    verts += [(x, depth / 2, z) for x, z in profile]
    n = len(profile)
    faces = [tuple(range(n - 1, -1, -1)), tuple(range(n, 2 * n))]
    for i in range(n):
        j = (i + 1) % n
        faces.append((i, j, n + j, n + i))
    mesh = bpy.data.meshes.new(name + "Mesh")
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(mat)
    apply_bevel(obj, bevel, 2)
    return obj


def irregular_rock(name, loc, scale, mat, seed, rotation=(0, 0, 0)):
    rng = random.Random(seed)
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=0.5, location=loc)
    obj = bpy.context.object
    obj.name = name
    for v in obj.data.vertices:
        v.co *= rng.uniform(0.86, 1.12)
    obj.scale = scale
    obj.rotation_euler = rotation
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    obj.data.materials.append(mat)
    apply_bevel(obj, min(scale) * 0.035, 2)
    return obj


def curve_line(name, points, mat, radius=0.025, resolution=1):
    curve = bpy.data.curves.new(name + "Curve", "CURVE")
    curve.dimensions = "3D"
    curve.resolution_u = resolution
    curve.bevel_depth = radius
    curve.bevel_resolution = 2
    spline = curve.splines.new("POLY")
    spline.points.add(len(points) - 1)
    for p, co in zip(spline.points, points):
        p.co = (*co, 1.0)
    obj = bpy.data.objects.new(name, curve)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(mat)
    return obj


def leaf_cluster(name, loc, scale, mat, seed):
    rng = random.Random(seed)
    parts = []
    for i in range(4):
        bpy.ops.mesh.primitive_ico_sphere_add(
            subdivisions=1,
            radius=0.5,
            location=(loc[0] + rng.uniform(-0.11, 0.11),
                      loc[1] + rng.uniform(-0.025, 0.025),
                      loc[2] + rng.uniform(-0.07, 0.07)),
        )
        o = bpy.context.object
        o.name = f"{name}_{i:02d}"
        o.scale = (scale * rng.uniform(0.7, 1.15), scale * 0.24,
                   scale * rng.uniform(0.45, 0.75))
        o.rotation_euler.y = rng.uniform(-0.45, 0.45)
        bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
        o.data.materials.append(mat)
        parts.append(o)
    return parts


def grass_tuft(name, loc, mat, seed, size=0.24):
    rng = random.Random(seed)
    verts = []
    faces = []
    for i in range(5):
        a = math.radians(i * 72 + rng.uniform(-12, 12))
        bx = loc[0] + math.cos(a) * size * 0.18
        by = loc[1] + math.sin(a) * size * 0.18
        z0 = loc[2]
        h = size * rng.uniform(0.65, 1.15)
        w = size * 0.12
        side = Vector((-math.sin(a) * w, math.cos(a) * w, 0))
        base = len(verts)
        verts.extend([(bx - side.x, by - side.y, z0),
                      (bx + side.x, by + side.y, z0),
                      (bx + math.cos(a) * size * 0.16,
                       by + math.sin(a) * size * 0.16, z0 + h)])
        faces.append((base, base + 1, base + 2))
    mesh = bpy.data.meshes.new(name + "Mesh")
    mesh.from_pydata(verts, [], faces)
    mesh.materials.append(mat)
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    return obj


def mushroom(name, loc, size, stem_mat, cap_mat):
    bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=size * 0.14,
                                        depth=size * 0.52,
                                        location=(loc[0], loc[1], loc[2] + size * 0.26))
    stem = bpy.context.object
    stem.name = name + "_Stem"
    stem.data.materials.append(stem_mat)
    bpy.ops.mesh.primitive_uv_sphere_add(segments=12, ring_count=6,
                                        location=(loc[0], loc[1], loc[2] + size * 0.56))
    cap = bpy.context.object
    cap.name = name + "_Cap"
    cap.scale = (size * 0.48, size * 0.48, size * 0.20)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    cap.data.materials.append(cap_mat)
    return [stem, cap]


def setup_asset():
    stone = material("Waystone warm slate", (0.31, 0.36, 0.35))
    stone_light = material("Waystone edge stone", (0.43, 0.47, 0.42))
    stone_dark = material("Waystone shadow stone", (0.19, 0.24, 0.23))
    moss = material("Waystone moss", (0.25, 0.39, 0.14))
    moss_light = material("Waystone moss light", (0.40, 0.52, 0.20))
    grass = material("Waystone grass", (0.21, 0.34, 0.13))
    stem = material("Waystone mushroom stem", (0.66, 0.57, 0.39))
    cap = material("Waystone mushroom cap", (0.55, 0.20, 0.10))
    rune = material("Waystone rune glow", (0.05, 0.55, 0.37), roughness=0.4,
                    emission=(0.08, 0.92, 0.58), emission_strength=2.7)

    # Broad shoulders, tapered waist, and a chipped slanted crown read cleanly at game distance.
    profile = [
        (-0.46, 0.28), (-0.58, 0.47), (-0.51, 0.77), (-0.55, 1.16),
        (-0.48, 1.62), (-0.30, 2.08), (0.03, 2.31), (0.34, 2.20),
        (0.51, 1.82), (0.50, 1.34), (0.44, 0.89), (0.53, 0.51),
        (0.34, 0.27), (0.05, 0.20),
    ]
    monolith = prism_from_profile("Waystone_Monolith", profile, 0.40, stone, 0.065)
    monolith.rotation_euler.z = math.radians(-2.5)

    rocks = [
        irregular_rock("Waystone_Base_C", (0.00, 0.02, 0.19), (0.78, 0.62, 0.38), stone_light, 1),
        irregular_rock("Waystone_Base_L", (-0.64, 0.01, 0.17), (0.58, 0.50, 0.34), stone_dark, 2,
                       rotation=(0.12, -0.18, 0.10)),
        irregular_rock("Waystone_Base_R", (0.62, 0.02, 0.16), (0.54, 0.48, 0.32), stone_light, 3,
                       rotation=(-0.10, 0.15, -0.08)),
        irregular_rock("Waystone_Base_FL", (-0.42, -0.35, 0.10), (0.43, 0.35, 0.22), stone_light, 4),
        irregular_rock("Waystone_Base_FR", (0.43, -0.36, 0.09), (0.39, 0.32, 0.20), stone_dark, 5),
        irregular_rock("Waystone_Pebble_L", (-0.92, -0.15, 0.08), (0.24, 0.20, 0.15), stone_light, 6),
        irregular_rock("Waystone_Pebble_R", (0.86, -0.19, 0.07), (0.21, 0.18, 0.13), stone_dark, 7),
    ]

    # A single luminous, cartographic spiral with a downward road/fork.
    spiral = []
    center_x, center_z = 0.0, 1.47
    for i in range(43):
        t = i / 42.0
        angle = t * math.tau * 1.62
        radius = 0.035 + t * 0.29
        spiral.append((center_x + math.cos(angle) * radius, -0.244,
                       center_z + math.sin(angle) * radius))
    curves = [curve_line("Waystone_Rune_Spiral", spiral, rune, 0.032),
              curve_line("Waystone_Rune_Road", [(0.00, -0.244, 1.18), (0.00, -0.244, 0.84)], rune, 0.029),
              curve_line("Waystone_Rune_Fork_L", [(0.00, -0.244, 1.02), (-0.17, -0.244, 0.91)], rune, 0.026),
              curve_line("Waystone_Rune_Fork_R", [(0.00, -0.244, 1.02), (0.18, -0.244, 0.91)], rune, 0.026)]

    # Sparse dark seams suggest hand-chipped age without competing with the rune.
    curves += [
        curve_line("Waystone_Crack_L", [(-0.43, -0.243, 0.75), (-0.31, -0.243, 0.83),
                                         (-0.36, -0.243, 0.96)], stone_dark, 0.012),
        curve_line("Waystone_Crack_R", [(0.34, -0.243, 1.90), (0.24, -0.243, 1.80),
                                         (0.32, -0.243, 1.70)], stone_dark, 0.011),
    ]

    # Moss stays secondary: a crown patch, one shoulder, and a foot cluster.
    foliage = []
    foliage += leaf_cluster("Waystone_Moss_Crown", (-0.22, -0.225, 2.18), 0.20, moss_light, 20)
    foliage += leaf_cluster("Waystone_Moss_Shoulder", (0.44, -0.225, 1.77), 0.17, moss, 21)
    foliage += leaf_cluster("Waystone_Moss_Foot", (-0.45, -0.35, 0.34), 0.18, moss_light, 22)
    # A thin creeping vine reinforces the storybook hand-made character.
    vine_points = [(-0.34, -0.255, 2.14), (-0.40, -0.255, 1.96),
                   (-0.35, -0.255, 1.80), (-0.42, -0.255, 1.64)]
    curves.append(curve_line("Waystone_Moss_Vine", vine_points, moss, 0.018))

    grass_parts = [
        grass_tuft("Waystone_Grass_L", (-0.83, -0.12, 0.02), grass, 31, 0.28),
        grass_tuft("Waystone_Grass_R", (0.75, -0.10, 0.02), grass, 32, 0.24),
        grass_tuft("Waystone_Grass_F", (0.16, -0.53, 0.02), grass, 33, 0.19),
    ]
    fungi = mushroom("Waystone_Mushroom_A", (0.71, -0.36, 0.02), 0.25, stem, cap)
    fungi += mushroom("Waystone_Mushroom_B", (0.88, -0.27, 0.02), 0.16, stem, cap)

    bpy.ops.object.empty_add(type="PLAIN_AXES", location=(0, 0, 0))
    root = bpy.context.object
    root.name = "WaystoneRoot"
    asset_objects = [monolith] + rocks + curves + foliage + grass_parts + fungi
    for obj in asset_objects:
        obj.parent = root

    return root, asset_objects, rune


def setup_preview(rune):
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE"
    scene.render.resolution_x = 720
    scene.render.resolution_y = 720
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.filepath = PREVIEW
    scene.render.film_transparent = False
    scene.view_settings.look = "AgX - Medium High Contrast"

    world = bpy.data.worlds.new("Waystone Preview World") if not bpy.data.worlds else bpy.data.worlds[0]
    scene.world = world
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.035, 0.055, 0.045, 1)
    world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.24

    bpy.ops.mesh.primitive_cylinder_add(vertices=64, radius=3.5, depth=0.08, location=(0, 0, -0.05))
    ground = bpy.context.object
    ground.name = "Preview_Ground"
    ground.data.materials.append(material("Preview ground", (0.09, 0.14, 0.08)))

    bpy.ops.object.light_add(type="AREA", location=(-3.8, -4.2, 6.0))
    key = bpy.context.object
    key.name = "Preview_Key"
    key.data.energy = 850
    key.data.shape = "DISK"
    key.data.size = 4.0
    key.data.color = (1.0, 0.75, 0.50)
    key.rotation_euler = (math.radians(28), 0, math.radians(-38))

    bpy.ops.object.light_add(type="AREA", location=(3.8, 1.5, 3.2))
    fill = bpy.context.object
    fill.name = "Preview_Fill"
    fill.data.energy = 500
    fill.data.size = 3.0
    fill.data.color = (0.30, 0.64, 0.72)

    bpy.ops.object.light_add(type="POINT", location=(0, -1.0, 1.45))
    glow = bpy.context.object
    glow.name = "Preview_RuneGlow"
    glow.data.energy = 80
    glow.data.color = (0.16, 1.0, 0.72)
    glow.data.shadow_soft_size = 0.8

    bpy.ops.object.camera_add(location=(4.1, -6.2, 3.7))
    camera = bpy.context.object
    camera.name = "Preview_Camera"
    camera.data.type = "ORTHO"
    camera.data.ortho_scale = 3.45
    target = Vector((0, 0, 1.08))
    camera.rotation_euler = (target - camera.location).to_track_quat("-Z", "Y").to_euler()
    scene.camera = camera


def export_asset(root, asset_objects):
    os.makedirs(os.path.dirname(OUT_BLEND), exist_ok=True)
    os.makedirs(os.path.dirname(PREVIEW), exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=OUT_BLEND)

    bpy.ops.object.select_all(action="DESELECT")
    root.select_set(True)
    for obj in asset_objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = root
    bpy.ops.export_scene.gltf(
        filepath=OUT_GLB,
        export_format="GLB",
        use_selection=True,
        export_yup=True,
        export_apply=True,
        export_animations=False,
        export_skins=False,
        export_lights=False,
        export_cameras=False,
        export_materials="EXPORT",
    )


clear_scene()
root, asset_objects, rune = setup_asset()
setup_preview(rune)
export_asset(root, asset_objects)
bpy.context.scene.render.filepath = PREVIEW
bpy.ops.render.render(write_still=True)

mesh_objects = [o for o in asset_objects if o.type == "MESH"]
curve_objects = [o for o in asset_objects if o.type == "CURVE"]
result = {
    "glb": OUT_GLB,
    "blend": OUT_BLEND,
    "preview": PREVIEW,
    "mesh_objects": len(mesh_objects),
    "curve_objects": len(curve_objects),
    "triangles": sum(len(o.data.polygons) for o in mesh_objects),
}
