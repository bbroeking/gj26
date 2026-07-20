"""Build Fire in the Bough's deterministic low-poly asset packet.

Run from Blender 4.x/5.x:
  /Applications/Blender.app/Contents/MacOS/Blender --background --python \
    models/scripts/build_fire_in_the_bough_assets_v1.py

The packet intentionally has no texture or Meshy dependency.  It is the
reproducible Blender fallback approved by the Fire council: a single skinned
Hearth Giant with the encounter-state vocabulary plus compact static
interactables/settlement assets.  Solid Principled materials, small angle-
limited bevels, and low primitive counts keep the Web export disciplined.
"""

from __future__ import annotations

import json
import math
import struct
from pathlib import Path

import bpy
from mathutils import Vector


ROOT = Path(__file__).resolve().parents[2]
MODELS = ROOT / "models"
FPS = 24
GIANT_PATH = MODELS / "boss_hearth_giant_v1.glb"
STATIC_ASSETS = {
    "prop_hollow_link_chain_v1.glb": "HollowLinkChain",
    "prop_braided_link_chain_v1.glb": "BraidedLinkChain",
    "prop_knot_link_chain_v1.glb": "KnotLinkChain",
    "building_ember_kiln_v1.glb": "EmberKiln",
    "building_threefold_loom_foundation_v1.glb": "ThreefoldLoomFoundation",
    "biome_ashen_bough_landing_v1.glb": "AshenBoughLanding",
    "biome_ashen_bough_roots_v1.glb": "AshenBoughRoots",
}
GIANT_CLIPS = [
    "HearthGiant_Idle", "HearthGiant_Walk", "HearthGiant_Attack",
    "HearthGiant_Hit", "HearthGiant_HeatShield", "HearthGiant_ChainReact",
    "HearthGiant_Kneel",
]


def wipe() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for collection in (bpy.data.meshes, bpy.data.materials, bpy.data.armatures,
                       bpy.data.actions, bpy.data.cameras, bpy.data.lights):
        for item in list(collection):
            collection.remove(item)


def mat(name: str, color: tuple[float, float, float], metallic: float = 0.0) -> bpy.types.Material:
    result = bpy.data.materials.new(name)
    result.use_nodes = True
    bsdf = next(node for node in result.node_tree.nodes if node.type == "BSDF_PRINCIPLED")
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    bsdf.inputs["Roughness"].default_value = 0.91
    bsdf.inputs["Metallic"].default_value = metallic
    return result


def soften(obj: bpy.types.Object, width: float) -> None:
    # glTF imports split vertices; authored primitives do not, but merging here
    # preserves the production bevel rule if this script is adapted later.
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.mesh.remove_doubles(threshold=0.0001)
    bpy.ops.object.mode_set(mode="OBJECT")
    if width >= 0.005:
        bevel = obj.modifiers.new("WayfinderSoftEdges", "BEVEL")
        bevel.width = width
        bevel.segments = 2
        bevel.limit_method = "ANGLE"
        bevel.angle_limit = math.radians(30)
        bpy.ops.object.modifier_apply(modifier=bevel.name)
    bpy.ops.object.shade_smooth_by_angle()
    obj.select_set(False)


def cube(name: str, center: tuple[float, float, float], size: tuple[float, float, float],
         material: bpy.types.Material, bone: str | None = None,
         rotation: tuple[float, float, float] = (0.0, 0.0, 0.0), bevel: float = 0.035) -> bpy.types.Object:
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=center, rotation=rotation)
    obj = bpy.context.object
    obj.name = name
    obj.scale = size
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    obj.data.materials.append(material)
    soften(obj, min(bevel, min(size) * 0.10))
    if bone:
        group = obj.vertex_groups.new(name=bone)
        group.add(list(range(len(obj.data.vertices))), 1.0, "REPLACE")
    return obj


def ico(name: str, center: tuple[float, float, float], radius: float,
        material: bpy.types.Material, bone: str | None = None, subdivisions: int = 1) -> bpy.types.Object:
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=subdivisions, radius=radius, location=center)
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.append(material)
    if bone:
        group = obj.vertex_groups.new(name=bone)
        group.add(list(range(len(obj.data.vertices))), 1.0, "REPLACE")
    return obj


def cylinder(name: str, center: tuple[float, float, float], radius: float, depth: float,
             material: bpy.types.Material, bone: str | None = None,
             rotation: tuple[float, float, float] = (0.0, 0.0, 0.0)) -> bpy.types.Object:
    bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=radius, depth=depth, location=center, rotation=rotation)
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.append(material)
    soften(obj, min(0.040, radius * 0.18))
    if bone:
        group = obj.vertex_groups.new(name=bone)
        group.add(list(range(len(obj.data.vertices))), 1.0, "REPLACE")
    return obj


def torus(name: str, center: tuple[float, float, float], major: float, minor: float,
          material: bpy.types.Material, rotation: tuple[float, float, float]) -> bpy.types.Object:
    bpy.ops.mesh.primitive_torus_add(major_radius=major, minor_radius=minor, major_segments=8,
                                    minor_segments=4, location=center, rotation=rotation)
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.append(material)
    return obj


def join(parts: list[bpy.types.Object], name: str) -> bpy.types.Object:
    bpy.ops.object.select_all(action="DESELECT")
    for part in parts:
        part.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    bpy.ops.object.join()
    result = bpy.context.object
    result.name = name
    bpy.context.scene.cursor.location = (0.0, 0.0, 0.0)
    bpy.ops.object.origin_set(type="ORIGIN_CURSOR")
    return result


def giant_armature() -> bpy.types.Object:
    bpy.ops.object.armature_add(enter_editmode=True, location=(0.0, 0.0, 0.0))
    armature = bpy.context.object
    armature.name = "HearthGiant_Armature"
    armature.data.name = "HearthGiant_Skeleton"
    edit = armature.data.edit_bones
    edit.remove(edit[0])

    def bone(name: str, head: tuple[float, float, float], tail: tuple[float, float, float], parent: str | None = None) -> None:
        item = edit.new(name)
        item.head, item.tail = Vector(head), Vector(tail)
        if parent:
            item.parent = edit[parent]

    bone("Root", (0, 0, 0), (0, 0, 0.75))
    bone("Hips", (0, 0, 0.75), (0, 0, 1.75), "Root")
    bone("Spine", (0, 0, 1.75), (0, 0, 2.70), "Hips")
    bone("Chest", (0, 0, 2.70), (0, 0, 3.50), "Spine")
    bone("Neck", (0, 0, 3.50), (0, 0, 3.84), "Chest")
    bone("Head", (0, 0, 3.84), (0, 0, 4.45), "Neck")
    bone("Arm_L", (-0.56, 0, 3.15), (-1.48, 0, 2.73), "Chest")
    bone("Forearm_L", (-1.48, 0, 2.73), (-2.00, 0, 1.92), "Arm_L")
    bone("Hand_L", (-2.00, 0, 1.92), (-2.20, -0.08, 1.64), "Forearm_L")
    bone("Arm_R", (0.56, 0, 3.15), (1.48, 0, 2.73), "Chest")
    bone("Forearm_R", (1.48, 0, 2.73), (2.00, 0, 1.92), "Arm_R")
    bone("Hand_R", (2.00, 0, 1.92), (2.20, -0.08, 1.64), "Forearm_R")
    bone("Leg_L", (-0.50, 0, 1.60), (-0.54, 0, 0.70), "Hips")
    bone("Shin_L", (-0.54, 0, 0.70), (-0.54, -0.10, 0.12), "Leg_L")
    bone("Leg_R", (0.50, 0, 1.60), (0.54, 0, 0.70), "Hips")
    bone("Shin_R", (0.54, 0, 0.70), (0.54, -0.10, 0.12), "Leg_R")
    bone("EmberCore", (0, -0.30, 2.86), (0, -0.47, 3.16), "Chest")
    bpy.ops.object.mode_set(mode="OBJECT")
    armature["wayfinder_asset"] = "boss_hearth_giant_v1"
    armature["rig_contract"] = "BlenderArmatureSkin_v1"
    armature["animation_contract"] = ",".join(GIANT_CLIPS)
    return armature


def giant_mesh(materials: dict[str, bpy.types.Material]) -> bpy.types.Object:
    parts: list[bpy.types.Object] = []
    # A tall ash-and-stone guardian with an unmistakable warm core.  He faces
    # -Y to match the town/dungeon convention used by existing characters.
    parts += [
        cube("Giant_AshTorso", (0, 0.03, 2.48), (1.52, 0.86, 1.72), materials["ash"], "Spine", bevel=0.11),
        cube("Giant_ChestPlate", (0, -0.46, 2.93), (1.30, 0.14, 0.74), materials["char"], "Chest", bevel=0.045),
        ico("Giant_EmberCore", (0, -0.545, 2.88), 0.30, materials["ember"], "EmberCore", 2),
        cube("Giant_CoreFrame", (0, -0.57, 2.88), (0.72, 0.08, 0.70), materials["iron"], "Chest", bevel=0.032),
        ico("Giant_Head", (0, -0.02, 3.92), 0.62, materials["ash_light"], "Head", 2),
        cube("Giant_Brow", (0, -0.52, 4.10), (0.86, 0.10, 0.16), materials["char"], "Head", bevel=0.026),
        ico("Giant_EyeL", (-0.22, -0.57, 3.96), 0.075, materials["ember"], "Head", 1),
        ico("Giant_EyeR", (0.22, -0.57, 3.96), 0.075, materials["ember"], "Head", 1),
        cube("Giant_Beard", (0, -0.40, 3.60), (0.72, 0.17, 0.48), materials["char"], "Head", bevel=0.048),
        cube("Giant_ShoulderL", (-0.82, 0.02, 3.14), (0.66, 0.88, 0.48), materials["ash_light"], "Arm_L", bevel=0.080),
        cube("Giant_ShoulderR", (0.82, 0.02, 3.14), (0.66, 0.88, 0.48), materials["ash_light"], "Arm_R", bevel=0.080),
        cylinder("Giant_ArmL", (-1.28, 0, 2.62), 0.31, 1.18, materials["ash"], "Arm_L", (0, math.pi/2, 0)),
        cylinder("Giant_ArmR", (1.28, 0, 2.62), 0.31, 1.18, materials["ash"], "Arm_R", (0, math.pi/2, 0)),
        cylinder("Giant_ForearmL", (-1.80, 0, 2.05), 0.28, 1.02, materials["ash_light"], "Forearm_L", (0, math.pi/2.6, 0)),
        cylinder("Giant_ForearmR", (1.80, 0, 2.05), 0.28, 1.02, materials["ash_light"], "Forearm_R", (0, math.pi/2.6, 0)),
        ico("Giant_FistL", (-2.13, -0.05, 1.68), 0.34, materials["iron"], "Hand_L", 1),
        ico("Giant_FistR", (2.13, -0.05, 1.68), 0.34, materials["iron"], "Hand_R", 1),
        cube("Giant_HipBelt", (0, 0, 1.63), (1.36, 0.78, 0.20), materials["iron"], "Hips", bevel=0.035),
        cylinder("Giant_LegL", (-0.51, 0, 1.06), 0.35, 1.20, materials["ash"], "Leg_L"),
        cylinder("Giant_LegR", (0.51, 0, 1.06), 0.35, 1.20, materials["ash"], "Leg_R"),
        cylinder("Giant_ShinL", (-0.55, 0, 0.47), 0.31, 0.86, materials["ash_light"], "Shin_L"),
        cylinder("Giant_ShinR", (0.55, 0, 0.47), 0.31, 0.86, materials["ash_light"], "Shin_R"),
        cube("Giant_FootL", (-0.55, -0.18, 0.14), (0.66, 0.88, 0.28), materials["iron"], "Shin_L", bevel=0.060),
        cube("Giant_FootR", (0.55, -0.18, 0.14), (0.66, 0.88, 0.28), materials["iron"], "Shin_R", bevel=0.060),
    ]
    mesh = join(parts, "HearthGiant_SkinnedMesh")
    mesh["wayfinder_asset"] = "boss_hearth_giant_v1"
    mesh["browser_budget"] = "one_skinned_mesh_no_textures"
    return mesh


def key_pose(armature: bpy.types.Object, frame: int, rotations: dict[str, tuple[float, float, float]],
             locations: dict[str, tuple[float, float, float]] | None = None) -> None:
    for bone in armature.pose.bones:
        bone.rotation_mode = "XYZ"
        bone.rotation_euler = rotations.get(bone.name, (0.0, 0.0, 0.0))
        bone.location = (locations or {}).get(bone.name, (0.0, 0.0, 0.0))
        bone.keyframe_insert(data_path="rotation_euler", frame=frame)
        if bone.name in (locations or {}):
            bone.keyframe_insert(data_path="location", frame=frame)


def action(armature: bpy.types.Object, name: str, poses: list[tuple[int, dict, dict]], loop: bool) -> None:
    clip = bpy.data.actions.new(name)
    clip.frame_start, clip.frame_end = poses[0][0], poses[-1][0]
    armature.animation_data_create()
    armature.animation_data.action = clip
    for frame, rotations, locations in poses:
        key_pose(armature, frame, rotations, locations)
    clip["wayfinder_loop"] = loop
    clip["wayfinder_state"] = name


def giant_actions(armature: bpy.types.Object) -> None:
    idle = [(1, {"Spine": (0.025, 0, 0), "Head": (0, 0.02, 0)}, {}),
            (20, {"Spine": (-0.022, 0, 0), "Head": (0, -0.02, 0), "EmberCore": (0, 0.12, 0)}, {}),
            (40, {"Spine": (0.025, 0, 0), "Head": (0, 0.02, 0)}, {})]
    walk = [(1, {"Arm_L": (0.38,0,0), "Arm_R": (-0.38,0,0), "Leg_L": (-0.35,0,0), "Leg_R": (0.35,0,0)}, {"Root": (0,0,0.05)}),
            (13, {"Arm_L": (-0.38,0,0), "Arm_R": (0.38,0,0), "Leg_L": (0.35,0,0), "Leg_R": (-0.35,0,0)}, {}),
            (25, {"Arm_L": (0.38,0,0), "Arm_R": (-0.38,0,0), "Leg_L": (-0.35,0,0), "Leg_R": (0.35,0,0)}, {"Root": (0,0,0.05)})]
    attack = [(1, {"Chest": (0,-0.12,0), "Arm_R": (0.42,0,-0.35)}, {}),
              (11, {"Chest": (0,0.30,0), "Arm_R": (-1.18,0,0.14), "Forearm_R": (-0.68,0,0)}, {"Root": (0,-0.16,0)}),
              (27, {}, {})]
    hit = [(1, {}, {}), (8, {"Spine": (0,-0.22,0), "Head": (0.16,0,0), "Arm_L": (-0.26,0,0)}, {}), (20, {}, {})]
    shield = [(1, {"EmberCore": (0,0,0)}, {}),
              (15, {"Chest": (0,-0.13,0), "Arm_L": (-0.58,0,-0.42), "Forearm_L": (-0.52,0,0), "EmberCore": (0,0.52,0)}, {}),
              (34, {"Chest": (0,-0.13,0), "Arm_L": (-0.58,0,-0.42), "Forearm_L": (-0.52,0,0), "EmberCore": (0,0.52,0)}, {})]
    chain = [(1, {"Spine": (0.10,0,0)}, {}),
             (12, {"Spine": (0.30,0,0), "Chest": (0.26,0,0), "Head": (-0.20,0,0), "Arm_L": (-0.46,0,0.26), "Arm_R": (-0.46,0,-0.26)}, {}),
             (30, {"Spine": (0.10,0,0)}, {})]
    kneel = [(1, {}, {}),
             (24, {"Spine": (0.34,0,0), "Chest": (0.38,0,0), "Head": (-0.30,0,0), "Leg_L": (0.88,0,0), "Leg_R": (0.88,0,0), "Shin_L": (-1.02,0,0), "Shin_R": (-1.02,0,0)}, {"Root": (0,0,-0.58)}),
             (48, {"Spine": (0.34,0,0), "Chest": (0.38,0,0), "Head": (-0.30,0,0), "Leg_L": (0.88,0,0), "Leg_R": (0.88,0,0), "Shin_L": (-1.02,0,0), "Shin_R": (-1.02,0,0)}, {"Root": (0,0,-0.58)})]
    for name, poses, loop in [
        (GIANT_CLIPS[0], idle, True), (GIANT_CLIPS[1], walk, True), (GIANT_CLIPS[2], attack, False),
        (GIANT_CLIPS[3], hit, False), (GIANT_CLIPS[4], shield, True), (GIANT_CLIPS[5], chain, False),
        (GIANT_CLIPS[6], kneel, False),
    ]:
        action(armature, name, poses, loop)
    armature.animation_data.action = bpy.data.actions[GIANT_CLIPS[0]]


def static_root(name: str) -> bpy.types.Object:
    bpy.ops.object.empty_add(type="PLAIN_AXES", location=(0, 0, 0))
    root = bpy.context.object
    root.name = name
    root["wayfinder_asset"] = name
    root["browser_budget"] = "low_poly_static_no_textures"
    return root


def parent_all(root: bpy.types.Object, objects: list[bpy.types.Object]) -> None:
    for obj in objects:
        obj.parent = root


def chain_asset(root: bpy.types.Object, style: str, materials: dict[str, bpy.types.Material]) -> None:
    parts: list[bpy.types.Object] = []
    if style == "Hollow":
        for i in range(3):
            parts.append(torus("HollowLink_%d" % i, (0, 0, 0.58 + i * 0.38), 0.27, 0.075,
                               materials["iron"], (math.pi / 2, 0 if i % 2 == 0 else math.pi / 2, 0)))
    elif style == "Braided":
        for i in range(3):
            for side in (-1, 1):
                parts.append(cylinder("BraidedLink_%d_%d" % (i, side), (side * 0.12, 0, 0.45 + i * 0.36),
                                      0.07, 0.58, materials["brass"], rotation=(side * 0.48, 0, 0)))
    else:
        for i in range(3):
            parts.append(torus("KnotLink_%d" % i, (0.18 * math.cos(i * 2.1), 0, 0.70 + 0.14 * math.sin(i * 2.1)),
                               0.23, 0.07, materials["iron"], (math.pi / 2, i * 0.65, 0)))
        parts.append(ico("KnotCore", (0, 0, 0.70), 0.16, materials["ember"], subdivisions=1))
    parts.append(cube("ChainPedestal", (0, 0, 0.14), (0.84, 0.84, 0.28), materials["ash"], bevel=0.055))
    parent_all(root, parts)


def kiln_asset(root: bpy.types.Object, materials: dict[str, bpy.types.Material]) -> None:
    parts = [
        cylinder("KilnStoneBase", (0, 0, 0.18), 0.92, 0.36, materials["ash"]),
        cylinder("KilnBody", (0, 0.05, 0.86), 0.72, 1.05, materials["ash_light"]),
        cylinder("KilnMouth", (0, -0.70, 0.72), 0.32, 0.09, materials["char"], rotation=(math.pi / 2, 0, 0)),
        ico("KilnEmber", (0, -0.75, 0.72), 0.19, materials["ember"], subdivisions=1),
        cube("KilnChimney", (0.24, 0.10, 1.70), (0.32, 0.34, 0.74), materials["iron"], bevel=0.04),
        cube("KilnAnvil", (-1.03, 0.08, 0.72), (0.48, 0.48, 0.22), materials["iron"], bevel=0.035),
        cylinder("KilnAnvilBlock", (-1.03, 0.08, 0.38), 0.23, 0.56, materials["ash"]),
    ]
    parent_all(root, parts)


def loom_asset(root: bpy.types.Object, materials: dict[str, bpy.types.Material]) -> None:
    parts = [cube("LoomPlinth", (0, 0, 0.14), (2.4, 1.65, 0.28), materials["ash"], bevel=0.055)]
    for x in (-0.86, 0.0, 0.86):
        parts.append(cylinder("LoomSocket_%s" % x, (x, 0, 0.36), 0.23, 0.24, materials["iron"]))
        parts.append(ico("LoomDormantEmber_%s" % x, (x, 0, 0.52), 0.10, materials["char"], subdivisions=1))
    parts += [cube("LoomBrokenBeamA", (-0.48, 0, 0.82), (1.42, 0.16, 0.16), materials["ash_light"], rotation=(0, 0.16, 0), bevel=0.025),
              cube("LoomBrokenBeamB", (0.62, 0, 0.78), (0.82, 0.16, 0.16), materials["ash_light"], rotation=(0, -0.33, 0), bevel=0.025)]
    parent_all(root, parts)


def landing_asset(root: bpy.types.Object, materials: dict[str, bpy.types.Material]) -> None:
    parts = [cube("LandingSlate", (0, 0, 0.08), (3.1, 2.7, 0.16), materials["ash"], bevel=0.04)]
    for i, x in enumerate((-1.18, -0.38, 0.42, 1.22)):
        parts.append(cube("LandingStep%d" % i, (x, 0.74, 0.16 + 0.07 * i), (0.64, 0.54, 0.14), materials["ash_light"], bevel=0.025))
    parts += [cube("LandingMarker", (0, -0.84, 0.50), (0.22, 0.22, 0.94), materials["iron"], bevel=0.035),
              ico("LandingEmber", (0, -0.98, 0.64), 0.12, materials["ember"], subdivisions=1)]
    parent_all(root, parts)


def roots_asset(root: bpy.types.Object, materials: dict[str, bpy.types.Material]) -> None:
    parts: list[bpy.types.Object] = []
    for i, (x, y, angle) in enumerate(((-0.72,-0.18,0.52), (0.45,0.12,-0.60), (0.04,0.56,1.18), (0.78,-0.48,-0.25))):
        parts.append(cylinder("AshRoot%d" % i, (x, y, 0.30), 0.16, 1.55, materials["char"], rotation=(0, math.pi/2 - angle, 0.34 * angle)))
        parts.append(ico("CinderBud%d" % i, (x * 1.15, y * 1.15, 0.54), 0.12, materials["ember"], subdivisions=1))
    parent_all(root, parts)


def glb_doc(path: Path) -> dict:
    raw = path.read_bytes()
    if raw[:4] != b"glTF":
        raise RuntimeError("Not a GLB: %s" % path)
    length = struct.unpack_from("<I", raw, 8)[0]
    if length != len(raw):
        raise RuntimeError("Invalid GLB length: %s" % path)
    json_bytes = struct.unpack_from("<I", raw, 12)[0]
    return json.loads(raw[20:20 + json_bytes].decode("utf-8"))


def export(path: Path, root: bpy.types.Object, animated: bool = False) -> dict:
    bpy.ops.object.select_all(action="DESELECT")
    root.select_set(True)
    for obj in root.children_recursive:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = root
    result = bpy.ops.export_scene.gltf(
        filepath=str(path), export_format="GLB", use_selection=True, export_yup=True,
        export_apply=False, export_normals=True, export_materials="EXPORT",
        export_cameras=False, export_lights=False, export_image_format="AUTO",
        export_animations=animated, export_animation_mode="ACTIONS", export_force_sampling=True,
        export_optimize_animation_size=True, export_def_bones=True, export_skins=animated,
        export_morph=False,
    )
    if "FINISHED" not in result:
        raise RuntimeError("Blender could not export %s" % path)
    doc = glb_doc(path)
    textures = doc.get("images", [])
    if any("uri" in image for image in textures):
        raise RuntimeError("External texture dependency in %s" % path.name)
    if animated:
        names = sorted(animation.get("name", "") for animation in doc.get("animations", []))
        if names != sorted(GIANT_CLIPS) or len(doc.get("skins", [])) != 1:
            raise RuntimeError("Giant rig export mismatch: %s" % names)
    elif doc.get("skins") or doc.get("animations"):
        raise RuntimeError("Static asset exported a skin/animation: %s" % path.name)
    return {"file": path.name, "bytes": path.stat().st_size, "meshes": len(doc.get("meshes", [])),
            "nodes": len(doc.get("nodes", [])), "skins": len(doc.get("skins", [])),
            "animations": [item.get("name", "") for item in doc.get("animations", [])]}


def main() -> None:
    wipe()
    MODELS.mkdir(parents=True, exist_ok=True)
    materials = {
        "ash": mat("Ashen Root", (0.24, 0.20, 0.18)), "ash_light": mat("Ashen Stone", (0.43, 0.36, 0.31)),
        "char": mat("Charcoal", (0.085, 0.075, 0.065)), "iron": mat("Bog Iron", (0.22, 0.25, 0.25), 0.15),
        "brass": mat("Banked Brass", (0.56, 0.37, 0.13), 0.25), "ember": mat("Banked Ember", (0.92, 0.20, 0.055)),
    }
    armature = giant_armature()
    mesh = giant_mesh(materials)
    mesh.parent = armature
    modifier = mesh.modifiers.new("WayfinderArmature", "ARMATURE")
    modifier.object = armature
    giant_actions(armature)
    records = [export(GIANT_PATH, armature, True)]
    # The character must be removed before the independent static exports;
    # otherwise its selected data can leak into a prop GLB.
    bpy.data.objects.remove(armature, do_unlink=True)
    builders = [
        ("prop_hollow_link_chain_v1.glb", lambda r: chain_asset(r, "Hollow", materials)),
        ("prop_braided_link_chain_v1.glb", lambda r: chain_asset(r, "Braided", materials)),
        ("prop_knot_link_chain_v1.glb", lambda r: chain_asset(r, "Knot", materials)),
        ("building_ember_kiln_v1.glb", lambda r: kiln_asset(r, materials)),
        ("building_threefold_loom_foundation_v1.glb", lambda r: loom_asset(r, materials)),
        ("biome_ashen_bough_landing_v1.glb", lambda r: landing_asset(r, materials)),
        ("biome_ashen_bough_roots_v1.glb", lambda r: roots_asset(r, materials)),
    ]
    for filename, build in builders:
        root = static_root(STATIC_ASSETS[filename])
        build(root)
        records.append(export(MODELS / filename, root, False))
        bpy.data.objects.remove(root, do_unlink=True)
    print(json.dumps({"status": "ok", "assets": records, "giant_clips": GIANT_CLIPS}, indent=2))


if __name__ == "__main__":
    main()
