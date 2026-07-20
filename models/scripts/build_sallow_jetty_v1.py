"""Build Wayfinder's Sallow Jetty as a deterministic, game-ready GLB.

Run inside Blender 4.x.  The asset uses only authored geometry and solid-color
materials so it stays lightweight in the Godot Web export.
"""

import math
from pathlib import Path

import bpy
from mathutils import Vector


ROOT = Path("/Users/bbroeking/projects/gj26")
GLB_PATH = ROOT / "models" / "building_sallow_jetty_v1.glb"
PREVIEW_PATH = Path("/tmp/wayfinder_sallow_jetty_v1.png")


def clear_scene():
    if bpy.context.object and bpy.context.object.mode != "OBJECT":
        bpy.ops.object.mode_set(mode="OBJECT")
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for datablocks in (bpy.data.meshes, bpy.data.curves, bpy.data.materials,
                       bpy.data.cameras, bpy.data.lights):
        for block in list(datablocks):
            if block.users == 0:
                datablocks.remove(block)


def material(name, color, metallic=0.0, roughness=0.82, emission=None):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*color, 1.0)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Metallic"].default_value = metallic
    if emission is not None:
        emission_input = bsdf.inputs.get("Emission Color") or bsdf.inputs.get("Emission")
        if emission_input:
            emission_input.default_value = (*emission, 1.0)
        strength = bsdf.inputs.get("Emission Strength")
        if strength:
            strength.default_value = 2.2
    return mat


def apply_bevel(obj, width=0.055, segments=2):
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    bevel = obj.modifiers.new("Soft storybook edges", "BEVEL")
    bevel.width = width
    bevel.segments = segments
    bevel.limit_method = "ANGLE"
    bevel.angle_limit = math.radians(30)
    bpy.ops.object.modifier_apply(modifier=bevel.name)
    obj.select_set(False)


def cube(name, location, scale, mat, rotation=(0.0, 0.0, 0.0), bevel=0.055, parent=None):
    bpy.ops.mesh.primitive_cube_add(location=location, rotation=rotation)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    obj.data.materials.append(mat)
    apply_bevel(obj, min(bevel, min(scale) * 0.18))
    obj.parent = parent
    return obj


def cylinder(name, location, radius, depth, mat, rotation=(0.0, 0.0, 0.0), vertices=10, parent=None):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth,
                                       location=location, rotation=rotation)
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.append(mat)
    apply_bevel(obj, min(0.04, radius * 0.16))
    obj.parent = parent
    return obj


def sphere(name, location, scale, mat, parent=None):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=1.0, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    obj.data.materials.append(mat)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.parent = parent
    return obj


def rope(name, points, radius, mat, parent=None):
    curve = bpy.data.curves.new(name, "CURVE")
    curve.dimensions = "3D"
    curve.resolution_u = 1
    curve.bevel_depth = radius
    curve.bevel_resolution = 1
    spline = curve.splines.new("BEZIER")
    spline.bezier_points.add(len(points) - 1)
    for point, co in zip(spline.bezier_points, points):
        point.co = co
        point.handle_left_type = "AUTO"
        point.handle_right_type = "AUTO"
    obj = bpy.data.objects.new(name, curve)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(mat)
    obj.parent = parent
    return obj


def look_at(obj, target):
    obj.rotation_euler = (Vector(target) - obj.location).to_track_quat("-Z", "Y").to_euler()


clear_scene()

wood = material("Sallow weathered oak", (0.26, 0.20, 0.11))
wood_light = material("Sallow worn plank", (0.43, 0.34, 0.18))
wood_moss = material("Sallow mossed timber", (0.25, 0.31, 0.18))
rope_mat = material("Loop cord", (0.53, 0.40, 0.22))
iron = material("Bogiron bands", (0.16, 0.20, 0.18), metallic=0.25, roughness=0.70)
teal = material("Wayfinder teal", (0.08, 0.33, 0.31))
gold = material("Wayfinder gilt", (0.87, 0.60, 0.18), metallic=0.15, roughness=0.55)
mist = material("Mist Root glow", (0.35, 0.86, 0.70), emission=(0.20, 0.78, 0.60))

root = bpy.data.objects.new("SallowJetty", None)
bpy.context.collection.objects.link(root)
# Geometry below is authored in game-space (Y up, Z forward).  Rotate that
# authored frame into Blender's Z-up world; glTF then converts it for Godot.
root.rotation_euler = (math.pi / 2.0, 0.0, 0.0)
root["wayfinder_asset"] = "sallow_jetty"
root["interaction_verb"] = "Launch held Mire Chart"

# A broad shore landing narrows into a deliberately crooked, readable pier.
for i, z in enumerate([-1.05, -0.35, 0.35]):
    cube(f"LandingPlank_{i:02d}", (0, 0.34 + (i % 2) * 0.025, z),
         (2.75, 0.18, 0.30), wood_light if i % 2 == 0 else wood_moss,
         rotation=(0, (-0.012 if i % 2 else 0.009), (i - 1) * 0.012), parent=root)

for i in range(13):
    z = 1.00 + i * 0.54
    drift = math.sin(i * 0.72) * 0.10
    cube(f"PierPlank_{i:02d}", (drift, 0.42 + (i % 3) * 0.018, z),
         (1.72, 0.17, 0.245), wood_light if i % 3 else wood_moss,
         rotation=(0, (i % 2 - 0.5) * 0.018, math.sin(i) * 0.016), parent=root)

# Long bearers and chunky piles sell the construction at gameplay camera distance.
for x in (-1.18, 1.18):
    cube(f"Bearer_{'L' if x < 0 else 'R'}", (x, 0.10, 3.90),
         (0.16, 0.18, 4.15), wood, parent=root)
for row, z in enumerate((-0.80, 1.55, 3.85, 6.10, 7.25)):
    for x in (-1.48, 1.48):
        cylinder(f"Pile_{row}_{'L' if x < 0 else 'R'}", (x, -0.28, z), 0.22, 2.45,
                 wood, rotation=(math.pi / 2, 0, 0), parent=root)
        cylinder(f"PileBand_{row}_{'L' if x < 0 else 'R'}", (x, 0.56, z), 0.245, 0.16,
                 iron, rotation=(math.pi / 2, 0, 0), parent=root)

# Rope rails dip naturally between piles, but leave the landing open.
for side in (-1, 1):
    rail_points = []
    for i, z in enumerate((1.55, 2.70, 3.85, 4.98, 6.10, 7.25)):
        rail_points.append((side * 1.48, 1.22 if i % 2 == 0 else 1.03, z))
    rope(f"RopeRail_{'L' if side < 0 else 'R'}", rail_points, 0.045, rope_mat, root)

# End shrine: the Mist Root Rune is the visual proof that the Jetty was restored.
for x in (-1.18, 1.18):
    cylinder(f"ShrinePost_{'L' if x < 0 else 'R'}", (x, 1.60, 7.15), 0.17, 2.70,
             teal, rotation=(math.pi / 2, 0, 0), parent=root)
cube("ShrineLintel", (0, 2.82, 7.15), (1.55, 0.18, 0.22), teal, parent=root)
cube("ShrineGiltLine", (0, 2.65, 7.13), (1.20, 0.055, 0.245), gold, bevel=0.025, parent=root)
cylinder("MistRuneOuter", (0, 2.06, 7.12), 0.49, 0.13, gold,
         vertices=12, parent=root)
sphere("MistRuneHeart", (0, 2.06, 7.03), (0.31, 0.43, 0.10), mist, root)
for angle in (0, math.pi / 2, math.pi, math.pi * 1.5):
    x = math.cos(angle) * 0.57
    y = 2.06 + math.sin(angle) * 0.57
    sphere(f"RuneKnot_{int(angle * 100)}", (x, y, 7.02), (0.10, 0.10, 0.08), gold, root)

# Two low mooring horns communicate the launch verb without adding a boat system yet.
for x in (-0.82, 0.82):
    cylinder(f"Mooring_{'L' if x < 0 else 'R'}", (x, 0.78, 7.22), 0.13, 0.72,
             wood, rotation=(math.pi / 2, 0, 0), parent=root)
    cylinder(f"MooringCap_{'L' if x < 0 else 'R'}", (x, 1.14, 7.22), 0.18, 0.12,
             gold, rotation=(math.pi / 2, 0, 0), parent=root)

# Export only the authored asset hierarchy.
bpy.ops.object.select_all(action="DESELECT")
root.select_set(True)
for obj in bpy.context.scene.objects:
    if obj.parent == root:
        obj.select_set(True)
bpy.context.view_layer.objects.active = root
GLB_PATH.parent.mkdir(parents=True, exist_ok=True)
bpy.ops.export_scene.gltf(filepath=str(GLB_PATH), export_format="GLB", use_selection=True,
                          export_yup=True, export_apply=True)

# Preview environment is intentionally excluded from the GLB.
ground = cube("PreviewGround", (0, -3.2, -1.58), (7.5, 7.0, 0.10),
              material("Preview marsh", (0.13, 0.21, 0.15)), bevel=0.02)

bpy.ops.object.camera_add(location=(11.8, -14.5, 10.0))
camera = bpy.context.object
camera.name = "PreviewCamera"
camera.data.lens = 52
look_at(camera, (0, -3.35, 0.75))
bpy.context.scene.camera = camera

bpy.ops.object.light_add(type="AREA", location=(4.5, -3.0, 12.0))
key = bpy.context.object
key.name = "Warm key"
key.data.energy = 1050
key.data.shape = "DISK"
key.data.size = 7.0
key.data.color = (1.0, 0.78, 0.54)
look_at(key, (0, -3.5, 0.5))

bpy.ops.object.light_add(type="AREA", location=(-7.0, -8.0, 7.5))
fill = bpy.context.object
fill.name = "Cool fill"
fill.data.energy = 720
fill.data.size = 6.0
fill.data.color = (0.48, 0.74, 0.76)
look_at(fill, (0, -3.5, 0.8))

scene = bpy.context.scene
scene.render.engine = "BLENDER_EEVEE"
scene.render.resolution_x = 960
scene.render.resolution_y = 720
scene.render.resolution_percentage = 100
scene.render.image_settings.file_format = "PNG"
scene.render.filepath = str(PREVIEW_PATH)
scene.render.film_transparent = False
scene.world.color = (0.045, 0.065, 0.060)
scene.view_settings.look = "AgX - Medium High Contrast"
bpy.ops.wm.save_as_mainfile(filepath="/tmp/wayfinder_sallow_jetty_v1.blend")
bpy.ops.render.render(write_still=True)

result = {
    "glb": str(GLB_PATH),
    "preview": str(PREVIEW_PATH),
    "mesh_count": len([obj for obj in bpy.context.scene.objects if obj.type == "MESH" and obj != ground]),
}
