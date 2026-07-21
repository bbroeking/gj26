import bpy
import math
import os


ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT_GLB = os.path.join(ROOT, "models", "prop_wayfinder_chest_v1.glb")


def clear_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)


def material(name, color, roughness=0.9, emission=None):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    bsdf.inputs["Roughness"].default_value = roughness
    if emission is not None:
        bsdf.inputs["Emission Color"].default_value = (*emission, 1.0)
        bsdf.inputs["Emission Strength"].default_value = 1.8
    return mat


def box(name, location, size, mat, bevel=0.025, rotation=(0.0, 0.0, 0.0)):
    bpy.ops.mesh.primitive_cube_add(size=2, location=location, rotation=rotation)
    obj = bpy.context.object
    obj.name = name
    obj.scale = (size[0] / 2.0, size[1] / 2.0, size[2] / 2.0)
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    obj.data.materials.append(mat)
    mod = obj.modifiers.new("Soft hand-hewn edges", "BEVEL")
    mod.width = min(bevel, min(size) * 0.08)
    mod.segments = 2
    mod.limit_method = "ANGLE"
    mod.angle_limit = math.radians(30)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.modifier_apply(modifier=mod.name)
    for polygon in obj.data.polygons:
        polygon.use_smooth = True
    return obj


def build():
    clear_scene()
    wood = material("Bramblewood warm oak", (0.38, 0.20, 0.085))
    wood_light = material("Bramblewood lid oak", (0.55, 0.31, 0.12))
    iron = material("Wayfinder dark iron", (0.12, 0.14, 0.12), 0.72)
    moss = material("Wayfinder moss", (0.25, 0.40, 0.13))
    glow = material("Wayfinder latch glow", (0.70, 0.53, 0.16), 0.55,
                    emission=(0.96, 0.72, 0.24))

    parts = [
        box("Chest_Body", (0.0, 0.0, 0.24), (0.82, 0.56, 0.42), wood, 0.045),
        box("Chest_Lid", (0.0, 0.0, 0.53), (0.88, 0.60, 0.22), wood_light, 0.055),
        box("Chest_Feet", (0.0, 0.0, 0.055), (0.70, 0.47, 0.11), iron, 0.025),
    ]
    for x in (-0.31, 0.31):
        parts.append(box("Chest_Band", (x, -0.005, 0.36), (0.075, 0.60, 0.61), iron, 0.012))
    parts.extend([
        box("Chest_Latch", (0.0, -0.315, 0.40), (0.17, 0.055, 0.25), iron, 0.016),
        box("Chest_Rune", (0.0, -0.348, 0.43), (0.075, 0.025, 0.10), glow, 0.010),
        box("Chest_Moss_L", (-0.25, -0.315, 0.62), (0.23, 0.035, 0.055), moss, 0.014,
            rotation=(0.0, 0.0, math.radians(-8))),
        box("Chest_Moss_R", (0.25, -0.315, 0.59), (0.18, 0.035, 0.045), moss, 0.012,
            rotation=(0.0, 0.0, math.radians(7))),
    ])

    bpy.ops.object.empty_add(type="PLAIN_AXES", location=(0.0, 0.0, 0.0))
    root = bpy.context.object
    root.name = "WayfinderChestRoot"
    for part in parts:
        part.parent = root

    bpy.ops.object.select_all(action="DESELECT")
    root.select_set(True)
    for part in parts:
        part.select_set(True)
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
    )
    print("Wrote", OUT_GLB)


build()
