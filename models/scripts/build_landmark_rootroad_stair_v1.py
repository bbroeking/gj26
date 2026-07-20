"""Build Wayfinder's Pale Stair landmark as a deterministic game-ready GLB.

Run with Blender in background mode.  The asset is a snow-crusted root-and-
stone descent with an emissive pale well.  It contains no collider, animation,
or portal semantics: Godot's PaleStair Interactable supplies the read-only
inspection affordance.
"""

import math
from pathlib import Path

import bpy
from mathutils import Vector


ROOT = Path("/Users/bbroeking/projects/gj26")
GLB_PATH = ROOT / "models" / "landmark_rootroad_stair_v1.glb"
PREVIEW_PATH = Path("/tmp/wayfinder_landmark_rootroad_stair_v1.png")


def clear_scene():
    if bpy.context.object and bpy.context.object.mode != "OBJECT":
        bpy.ops.object.mode_set(mode="OBJECT")
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for collection in (bpy.data.meshes, bpy.data.curves, bpy.data.materials,
                       bpy.data.cameras, bpy.data.lights):
        for block in list(collection):
            if block.users == 0:
                collection.remove(block)


def material(name, color, roughness=0.82, emission=None, emission_strength=2.2):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*color, 1.0)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Metallic"].default_value = 0.0
    if emission is not None:
        (bsdf.inputs.get("Emission Color") or bsdf.inputs.get("Emission")).default_value = (*emission, 1.0)
        bsdf.inputs["Emission Strength"].default_value = emission_strength
    return mat


def bevel(obj, width=0.045):
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    mod = obj.modifiers.new("Storybook soft edges", "BEVEL")
    mod.width = width
    mod.segments = 2
    mod.limit_method = "ANGLE"
    mod.angle_limit = math.radians(30)
    bpy.ops.object.modifier_apply(modifier=mod.name)
    obj.select_set(False)


def cube(name, loc, dims, mat, parent, rotation=(0, 0, 0), bevel_width=0.045):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc, rotation=rotation)
    obj = bpy.context.object
    obj.name = name
    obj.scale = dims
    obj.data.materials.append(mat)
    bevel(obj, min(bevel_width, min(dims) * 0.18))
    obj.parent = parent
    return obj


def cylinder(name, loc, radius, depth, mat, parent, rotation=(0, 0, 0), vertices=10):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth,
                                       location=loc, rotation=rotation)
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.append(mat)
    bevel(obj, min(0.04, radius * 0.16))
    obj.parent = parent
    return obj


def sphere(name, loc, scale, mat, parent):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=1.0, location=loc)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(mat)
    obj.parent = parent
    return obj


def root_curve(name, points, radius, mat, parent):
    curve = bpy.data.curves.new(name, "CURVE")
    curve.dimensions = "3D"
    curve.resolution_u = 2
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
stone_dark = material("Pale Stair charcoal stone", (0.25, 0.30, 0.37))
stone_mid = material("Pale Stair weathered stone", (0.38, 0.44, 0.51))
stone_light = material("Pale Stair broken edge", (0.53, 0.59, 0.66))
root_bark = material("Pale Stair old root", (0.20, 0.16, 0.13))
root_frost = material("Pale Stair frosted root", (0.59, 0.69, 0.78))
snow = material("Pale Stair snow", (0.82, 0.90, 0.98), roughness=0.9)
pale_light = material("Pale Stair pale well", (0.45, 0.72, 1.0), roughness=0.42,
                      emission=(0.28, 0.60, 1.0), emission_strength=3.6)

root = bpy.data.objects.new("PaleStairRoot", None)
bpy.context.collection.objects.link(root)
# The GLB exporter performs Blender Z-up → glTF Y-up conversion.  Geometry is
# therefore authored directly in Blender's coordinates here; adding a root
# rotation would double-convert the landmark and turn the treads into a wall
# in Godot.
root["wayfinder_asset"] = "landmark_rootroad_stair_v1"
root["presentation"] = "pale_stair"
root["interaction"] = "look_down_only"

# Broad snowy landing, then seven descending uneven stone treads.  The line
# runs +Y in game-space; scale and silhouette remain legible from above.
cube("SnowLanding", (0, -1.15, 0.12), (1.55, 0.75, 0.15), snow, root, bevel_width=0.09)
for i in range(7):
    y = -0.35 + i * 0.47
    z = 0.02 - i * 0.21
    width = 1.42 - i * 0.045
    depth = 0.32
    drift = (-0.035 if i % 2 else 0.035)
    tread = cube(f"RootRoadTread_{i+1:02d}", (drift, y, z), (width, depth, 0.16),
                 stone_mid if i % 3 else stone_dark, root,
                 rotation=(0.02 * (i % 2), 0.015 * (i - 3), 0.025 * ((i % 3) - 1)),
                 bevel_width=0.065)
    # A thin, offset snow cap makes each tread read as winter-worn rather than
    # a generic staircase.
    cube(f"SnowCap_{i+1:02d}", (drift - 0.06, y - 0.015, z + 0.175),
         (width * 0.72, depth * 0.70, 0.035), snow, root,
         rotation=(0.02 * (i % 2), 0.015 * (i - 3), 0.025 * ((i % 3) - 1)), bevel_width=0.025)

# Two roots embrace the stone.  Pale frost beads on the upper outer roots to
# pull the eye down toward the future road.
for side in (-1, 1):
    root_curve(f"AncientRoot_{'L' if side < 0 else 'R'}", [
        (side * 1.42, -1.35, 0.30), (side * 1.30, -0.35, 0.36),
        (side * 1.03, 0.92, -0.42), (side * 0.78, 2.62, -1.28),
    ], 0.16, root_bark, root)
    root_curve(f"FrostRoot_{'L' if side < 0 else 'R'}", [
        (side * 1.52, -0.85, 0.49), (side * 1.35, 0.32, 0.48),
        (side * 1.10, 1.48, -0.22),
    ], 0.045, root_frost, root)

# Broken cairn-like flanks reinforce that this is an old road, not a portal.
for side in (-1, 1):
    for i in range(3):
        cylinder(f"RoadCairn_{'L' if side < 0 else 'R'}_{i}",
                 (side * (1.50 - i * 0.10), 0.34 + i * 0.72, 0.05 - i * 0.20),
                 0.18 + i * 0.025, 0.25 + i * 0.05,
                 stone_light if i == 1 else stone_dark, root, vertices=7)

# A shallow well at the final visible step.  It is a deliberately non-solid
# glow, echoed by the Godot light but not used for collision or transition.
cylinder("PaleWellRim", (0, 2.82, -1.43), 0.46, 0.12, stone_light, root, vertices=12)
sphere("PaleWellGlow", (0, 2.82, -1.39), (0.30, 0.30, 0.08), pale_light, root)
for angle in range(6):
    a = angle * math.pi / 3.0
    sphere(f"PaleRune_{angle}", (math.cos(a) * 0.43, 2.82 + math.sin(a) * 0.43, -1.36),
           (0.065, 0.065, 0.04), pale_light, root)

# Export the hierarchy only, preserving the named root for future pipeline
# inspection and avoiding preview lights/camera in the Web payload.
bpy.ops.object.select_all(action="DESELECT")
root.select_set(True)
for obj in bpy.context.scene.objects:
    if obj.parent == root:
        obj.select_set(True)
bpy.context.view_layer.objects.active = root
GLB_PATH.parent.mkdir(parents=True, exist_ok=True)
bpy.ops.export_scene.gltf(filepath=str(GLB_PATH), export_format="GLB", use_selection=True,
                          export_yup=True, export_apply=True, export_normals=True,
                          export_materials="EXPORT", export_animations=False)

# Deterministic preview is intentionally excluded from the GLB.
ground = cube("PreviewSnow", (0, 0.7, -1.84), (5.4, 4.8, 0.08), snow, None, bevel_width=0.01)
bpy.ops.object.camera_add(location=(6.4, -7.8, 5.8))
camera = bpy.context.object
camera.name = "PreviewCamera"
camera.data.lens = 54
look_at(camera, (0, 0.65, -0.45))
bpy.context.scene.camera = camera
bpy.ops.object.light_add(type="AREA", location=(-3.0, -4.5, 7.0))
key = bpy.context.object
key.name = "Cold key"
key.data.energy = 880
key.data.color = (0.60, 0.78, 1.0)
key.data.shape = "DISK"
key.data.size = 6.0
look_at(key, (0, 0.8, -0.5))
bpy.ops.object.light_add(type="AREA", location=(4.0, 3.0, 4.0))
fill = bpy.context.object
fill.name = "Soft moon fill"
fill.data.energy = 480
fill.data.color = (0.78, 0.86, 1.0)
fill.data.size = 5.0
look_at(fill, (0, 0.8, -0.5))
scene = bpy.context.scene
# Blender 4.x calls the real-time engine BLENDER_EEVEE_NEXT; the installed
# Blender 5.1 build exposes it as BLENDER_EEVEE again.  Keep the authoring
# preview portable while the exported GLB stays identical.
scene.render.engine = "BLENDER_EEVEE"
scene.render.resolution_x = 960
scene.render.resolution_y = 720
scene.render.resolution_percentage = 100
scene.render.image_settings.file_format = "PNG"
scene.render.filepath = str(PREVIEW_PATH)
scene.world.color = (0.035, 0.05, 0.09)
scene.view_settings.look = "None"
scene.view_settings.view_transform = "Standard"
bpy.ops.wm.save_as_mainfile(filepath="/tmp/wayfinder_landmark_rootroad_stair_v1.blend")
bpy.ops.render.render(write_still=True)

mesh_count = len([obj for obj in bpy.context.scene.objects
                  if obj.type == "MESH" and obj != ground])
print({"glb": str(GLB_PATH), "preview": str(PREVIEW_PATH), "mesh_count": mesh_count})
