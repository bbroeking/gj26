"""Build the final Pale Oath character pair as browser-budget rigged GLBs.

This is the reproducible Blender source of truth for the Barrow Jarl and the
Oathbound guard.  It deliberately uses Blender-authored geometry and a small,
real armature rather than claiming a Meshy delivery or consuming Meshy credits.

Run with a Blender build (5.1 validated) from the repository root:

    Blender --background --factory-startup \
      --python models/scripts/build_pale_oath_characters_v1.py

It exports two self-contained Godot-importable GLBs and two non-runtime preview
renders under ``docs/assets/pale-oath-characters``.  Each GLB has one skinned
mesh, an Armature/Skeleton, named material slots, and the clips listed in
``docs/assets/pale-oath-characters-delivery.md``.
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
PREVIEWS = ROOT / "docs" / "assets" / "pale-oath-characters"


def clear_scene() -> None:
    if bpy.context.object is not None and bpy.context.object.mode != "OBJECT":
        bpy.ops.object.mode_set(mode="OBJECT")
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for collection in (
        bpy.data.meshes,
        bpy.data.curves,
        bpy.data.materials,
        bpy.data.armatures,
        bpy.data.actions,
        bpy.data.cameras,
        bpy.data.lights,
    ):
        for block in list(collection):
            if block.users == 0:
                collection.remove(block)


def make_material(name: str, color: tuple[float, float, float], *,
                  emission: tuple[float, float, float] | None = None) -> bpy.types.Material:
    material = bpy.data.materials.new(name)
    material.use_nodes = True
    bsdf = material.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    bsdf.inputs["Roughness"].default_value = 0.93
    bsdf.inputs["Metallic"].default_value = 0.0
    if emission is not None:
        (bsdf.inputs.get("Emission Color") or bsdf.inputs.get("Emission")).default_value = (*emission, 1.0)
        bsdf.inputs["Emission Strength"].default_value = 1.6
    return material


def soften(obj: bpy.types.Object, width: float) -> None:
    """Apply the project-approved small 2-segment, angle-limited bevel."""
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.mesh.remove_doubles(threshold=0.0001)
    bpy.ops.object.mode_set(mode="OBJECT")
    if width >= 0.005:
        bevel = obj.modifiers.new("Storybook soft edges", "BEVEL")
        bevel.width = width
        bevel.segments = 2
        bevel.limit_method = "ANGLE"
        bevel.angle_limit = math.radians(30)
        bpy.ops.object.modifier_apply(modifier=bevel.name)
    bpy.ops.object.shade_smooth()
    obj.select_set(False)


def primitive_box(name: str, location: tuple[float, float, float],
                  dimensions: tuple[float, float, float], material: bpy.types.Material,
                  bone: str, rotation=(0.0, 0.0, 0.0)) -> bpy.types.Object:
    bpy.ops.mesh.primitive_cube_add(size=2, location=location, rotation=rotation)
    obj = bpy.context.object
    obj.name = name
    obj.scale = tuple(value / 2.0 for value in dimensions)
    obj.data.materials.append(material)
    soften(obj, min(0.065, min(dimensions) * 0.08))
    group = obj.vertex_groups.new(name=bone)
    group.add(list(range(len(obj.data.vertices))), 1.0, "REPLACE")
    return obj


def primitive_ico(name: str, location: tuple[float, float, float],
                  dimensions: tuple[float, float, float], material: bpy.types.Material,
                  bone: str) -> bpy.types.Object:
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=1.0, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.scale = tuple(value / 2.0 for value in dimensions)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(material)
    group = obj.vertex_groups.new(name=bone)
    group.add(list(range(len(obj.data.vertices))), 1.0, "REPLACE")
    bpy.ops.object.shade_smooth()
    return obj


def primitive_cylinder(name: str, location: tuple[float, float, float],
                       radius: float, depth: float, material: bpy.types.Material,
                       bone: str, rotation=(0.0, 0.0, 0.0), vertices=8) -> bpy.types.Object:
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=vertices, radius=radius, depth=depth, location=location, rotation=rotation
    )
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.append(material)
    soften(obj, min(0.045, radius * 0.13))
    group = obj.vertex_groups.new(name=bone)
    group.add(list(range(len(obj.data.vertices))), 1.0, "REPLACE")
    return obj


def join_meshes(meshes: list[bpy.types.Object], name: str) -> bpy.types.Object:
    bpy.ops.object.select_all(action="DESELECT")
    for mesh in meshes:
        mesh.select_set(True)
    bpy.context.view_layer.objects.active = meshes[0]
    bpy.ops.object.join()
    mesh = bpy.context.object
    mesh.name = name
    # The armature rests at world origin.  A root origin keeps all skinned mesh
    # coordinates in the same stable space for Godot and glTF.
    bpy.context.scene.cursor.location = (0.0, 0.0, 0.0)
    bpy.ops.object.origin_set(type="ORIGIN_CURSOR")
    bpy.context.scene.cursor.location = (0.0, 0.0, 0.0)
    return mesh


def make_armature(asset_id: str, scale: float = 1.0) -> bpy.types.Object:
    bpy.ops.object.armature_add(enter_editmode=True, location=(0.0, 0.0, 0.0))
    armature = bpy.context.object
    armature.name = f"{asset_id}_Armature"
    armature.data.name = f"{asset_id}_Skeleton"
    armature.show_in_front = True
    edit = armature.data.edit_bones
    # Replace the operator's default bone with the explicit production skeleton.
    edit.remove(edit[0])

    def bone(name: str, head: tuple[float, float, float], tail: tuple[float, float, float],
             parent: str | None = None, connected: bool = False) -> None:
        result = edit.new(name)
        result.head = Vector(head) * scale
        result.tail = Vector(tail) * scale
        if parent:
            result.parent = edit[parent]
            result.use_connect = connected

    bone("Root", (0, 0, 0), (0, 0, 0.32))
    bone("Hips", (0, 0, 0.32), (0, 0, 0.78), "Root", True)
    bone("Spine", (0, 0, 0.78), (0, 0, 1.32), "Hips", True)
    bone("Chest", (0, 0, 1.32), (0, 0, 1.76), "Spine", True)
    bone("Neck", (0, 0, 1.76), (0, 0, 1.91), "Chest", True)
    bone("Head", (0, 0, 1.91), (0, 0, 2.23), "Neck", True)
    bone("Arm_L", (0, 0, 1.60), (-0.46, 0, 1.48), "Chest")
    bone("Forearm_L", (-0.46, 0, 1.48), (-0.79, 0, 1.27), "Arm_L", True)
    bone("Hand_L", (-0.79, 0, 1.27), (-0.94, 0, 1.19), "Forearm_L", True)
    bone("Arm_R", (0, 0, 1.60), (0.46, 0, 1.48), "Chest")
    bone("Forearm_R", (0.46, 0, 1.48), (0.79, 0, 1.27), "Arm_R", True)
    bone("Hand_R", (0.79, 0, 1.27), (0.94, 0, 1.19), "Forearm_R", True)
    bone("Leg_L", (-0.24, 0, 0.78), (-0.24, 0, 0.35), "Hips")
    bone("Shin_L", (-0.24, 0, 0.35), (-0.24, 0, 0.08), "Leg_L", True)
    bone("Foot_L", (-0.24, 0, 0.08), (-0.24, -0.22, 0.05), "Shin_L", True)
    bone("Leg_R", (0.24, 0, 0.78), (0.24, 0, 0.35), "Hips")
    bone("Shin_R", (0.24, 0, 0.35), (0.24, 0, 0.08), "Leg_R", True)
    bone("Foot_R", (0.24, 0, 0.08), (0.24, -0.22, 0.05), "Shin_R", True)
    bone("Cape", (0, 0.22, 1.62), (0, 0.40, 0.64), "Chest")
    bone("Crown", (0, 0, 2.18), (0, 0, 2.38), "Head")
    bpy.ops.object.mode_set(mode="OBJECT")
    return armature


def bind(mesh: bpy.types.Object, armature: bpy.types.Object, asset_id: str) -> None:
    mesh.parent = armature
    modifier = mesh.modifiers.new("WayfinderArmature", "ARMATURE")
    modifier.object = armature
    mesh["wayfinder_asset"] = asset_id
    mesh["rig_contract"] = "BlenderArmatureSkin_v1"
    mesh["browser_budget"] = "low_poly_one_skinned_mesh"
    armature["wayfinder_asset"] = asset_id
    armature["rig_contract"] = "BlenderArmatureSkin_v1"


def key_pose(armature: bpy.types.Object, frame: int, rotations: dict[str, tuple[float, float, float]],
             locations: dict[str, tuple[float, float, float]] | None = None) -> None:
    for pose_bone in armature.pose.bones:
        pose_bone.rotation_mode = "XYZ"
        pose_bone.rotation_euler = rotations.get(pose_bone.name, (0.0, 0.0, 0.0))
        pose_bone.location = (locations or {}).get(pose_bone.name, (0.0, 0.0, 0.0))
        pose_bone.keyframe_insert(data_path="rotation_euler", frame=frame)
        if pose_bone.name in (locations or {}):
            pose_bone.keyframe_insert(data_path="location", frame=frame)


def create_action(armature: bpy.types.Object, name: str, poses: list[tuple[int, dict, dict]], loop: bool) -> None:
    action = bpy.data.actions.new(name)
    action.use_frame_range = True
    action.frame_start = poses[0][0]
    action.frame_end = poses[-1][0]
    armature.animation_data_create()
    armature.animation_data.action = action
    for frame, rotations, locations in poses:
        key_pose(armature, frame, rotations, locations)
    # glTF does not promise loop metadata.  Godot's AnimDriver applies the loop
    # policy at runtime for Idle/Walk; the custom state clips are one-shots.
    action["wayfinder_loop"] = loop
    action["wayfinder_state"] = name


def build_actions(armature: bpy.types.Object, prefix: str, is_jarl: bool) -> list[str]:
    idle = [
        (1, {"Spine": (0.03, 0, 0), "Chest": (0.02, 0, 0), "Head": (0, 0.02, 0)}, {}),
        (18, {"Spine": (-0.025, 0, 0), "Chest": (-0.018, 0, 0), "Head": (0, -0.02, 0)}, {}),
        (36, {"Spine": (0.03, 0, 0), "Chest": (0.02, 0, 0), "Head": (0, 0.02, 0)}, {}),
    ]
    walk = [
        (1, {"Arm_L": (0.58, 0, 0), "Forearm_L": (-0.20, 0, 0), "Arm_R": (-0.58, 0, 0),
             "Forearm_R": (0.20, 0, 0), "Leg_L": (-0.52, 0, 0), "Shin_L": (0.34, 0, 0),
             "Leg_R": (0.52, 0, 0), "Shin_R": (-0.34, 0, 0)}, {"Root": (0, 0, 0.025)}),
        (13, {"Arm_L": (-0.58, 0, 0), "Forearm_L": (0.20, 0, 0), "Arm_R": (0.58, 0, 0),
              "Forearm_R": (-0.20, 0, 0), "Leg_L": (0.52, 0, 0), "Shin_L": (-0.34, 0, 0),
              "Leg_R": (-0.52, 0, 0), "Shin_R": (0.34, 0, 0)}, {"Root": (0, 0, 0.0)}),
        (25, {"Arm_L": (0.58, 0, 0), "Forearm_L": (-0.20, 0, 0), "Arm_R": (-0.58, 0, 0),
              "Forearm_R": (0.20, 0, 0), "Leg_L": (-0.52, 0, 0), "Shin_L": (0.34, 0, 0),
              "Leg_R": (0.52, 0, 0), "Shin_R": (-0.34, 0, 0)}, {"Root": (0, 0, 0.025)}),
    ]
    attack = [
        (1, {"Chest": (0, -0.10, 0), "Arm_R": (0.25, 0, -0.28), "Forearm_R": (-0.18, 0, 0),
             "Arm_L": (-0.10, 0, 0.10)}, {}),
        (9, {"Chest": (0, 0.30, 0), "Arm_R": (-1.0, 0, 0.15), "Forearm_R": (-0.72, 0, 0),
             "Arm_L": (0.24, 0, -0.10)}, {"Root": (0, -0.06, 0)}),
        (17, {"Chest": (0, 0.06, 0), "Arm_R": (-0.35, 0, 0), "Forearm_R": (-0.12, 0, 0)}, {}),
        (27, {}, {}),
    ]
    hit = [
        (1, {}, {}),
        (7, {"Spine": (0, -0.22, 0), "Head": (0.14, 0, 0), "Arm_L": (-0.18, 0, 0)}, {}),
        (18, {}, {}),
    ]
    shield = [
        (1, {}, {}),
        (12, {"Arm_L": (-0.62, 0, -0.42), "Forearm_L": (-0.65, 0, 0), "Chest": (0, -0.10, 0)}, {}),
        (28, {"Arm_L": (-0.62, 0, -0.42), "Forearm_L": (-0.65, 0, 0), "Chest": (0, -0.10, 0)}, {}),
    ]
    reeling = [
        (1, {"Spine": (0.22, 0, 0), "Chest": (0.26, 0, 0), "Head": (-0.16, 0, 0),
             "Arm_L": (-0.46, 0, 0.22), "Arm_R": (-0.35, 0, -0.22)}, {}),
        (18, {"Spine": (0.30, 0, 0), "Chest": (0.30, 0, 0), "Head": (-0.20, 0.05, 0),
              "Arm_L": (-0.52, 0, 0.22), "Arm_R": (-0.40, 0, -0.22)}, {"Root": (0, 0, -0.045)}),
        (34, {"Spine": (0.22, 0, 0), "Chest": (0.26, 0, 0), "Head": (-0.16, 0, 0),
              "Arm_L": (-0.46, 0, 0.22), "Arm_R": (-0.35, 0, -0.22)}, {}),
    ]
    relief = [
        (1, {"Chest": (0, -0.08, 0), "Arm_L": (-0.48, 0, 0.10), "Arm_R": (-0.48, 0, -0.10)}, {}),
        (18, {"Chest": (0.16, 0, 0), "Arm_L": (-0.78, 0, 0.18), "Arm_R": (-0.68, 0, -0.18),
              "Head": (-0.14, 0, 0)}, {}),
        (32, {"Chest": (0.06, 0, 0), "Arm_L": (-0.34, 0, 0), "Arm_R": (-0.34, 0, 0)}, {}),
    ]
    kneel = [
        (1, {}, {}),
        (20, {"Spine": (0.30, 0, 0), "Chest": (0.34, 0, 0), "Head": (-0.28, 0, 0),
              "Leg_L": (0.80, 0, 0), "Leg_R": (0.80, 0, 0), "Shin_L": (-0.92, 0, 0),
              "Shin_R": (-0.92, 0, 0)}, {"Root": (0, 0, -0.30)}),
        (42, {"Spine": (0.30, 0, 0), "Chest": (0.34, 0, 0), "Head": (-0.28, 0, 0),
              "Leg_L": (0.80, 0, 0), "Leg_R": (0.80, 0, 0), "Shin_L": (-0.92, 0, 0),
              "Shin_R": (-0.92, 0, 0)}, {"Root": (0, 0, -0.30)}),
    ]
    defeat = [
        (1, {}, {}),
        (18, {"Spine": (0.50, 0, 0), "Chest": (0.55, 0, 0), "Head": (-0.45, 0, 0),
              "Leg_L": (0.92, 0, 0), "Leg_R": (0.92, 0, 0), "Shin_L": (-1.0, 0, 0),
              "Shin_R": (-1.0, 0, 0)}, {"Root": (0, 0.18, -0.42)}),
        (36, {"Spine": (0.50, 0, 0), "Chest": (0.55, 0, 0), "Head": (-0.45, 0, 0),
              "Leg_L": (0.92, 0, 0), "Leg_R": (0.92, 0, 0), "Shin_L": (-1.0, 0, 0),
              "Shin_R": (-1.0, 0, 0)}, {"Root": (0, 0.18, -0.42)}),
    ]
    actions = [
        ("Idle", idle, True), ("Walk", walk, True), ("Attack", attack, False),
        ("Hit", hit, False), ("Shield", shield, False), ("Reeling", reeling, True),
        ("Relief", relief, False), ("Kneel", kneel, False), ("Defeat", defeat, False),
    ]
    if not is_jarl:
        # Both characters ship the full state vocabulary for a single reusable
        # guard family.  Jarl code uses Kneel; a relieved guard uses Relief.
        actions = [item for item in actions if item[0] != "Kneel"]
    for state, poses, loop in actions:
        create_action(armature, f"{prefix}_{state}", poses, loop)
    armature.animation_data.action = bpy.data.actions[f"{prefix}_Idle"]
    return [f"{prefix}_{state}" for state, _, _ in actions]


def make_jarl(materials: dict[str, bpy.types.Material]) -> tuple[bpy.types.Object, bpy.types.Object, list[str]]:
    armature = make_armature("BarrowJarl")
    parts = [
        primitive_box("Jarl_Rootcoat", (0, 0.02, 1.13), (1.28, 0.76, 1.36), materials["coat"], "Spine"),
        primitive_box("Jarl_Cuirass", (0, -0.37, 1.42), (1.06, 0.10, 0.62), materials["iron"], "Chest"),
        primitive_box("Jarl_CuirassRune", (0, -0.429, 1.43), (0.23, 0.016, 0.36), materials["pale"], "Chest"),
        primitive_box("Jarl_Belt", (0, -0.01, 0.87), (1.14, 0.80, 0.14), materials["brass"], "Hips"),
        primitive_ico("Jarl_Head", (0, -0.02, 2.06), (0.62, 0.58, 0.66), materials["skin"], "Head"),
        primitive_box("Jarl_Beard", (0, -0.33, 1.91), (0.48, 0.10, 0.40), materials["beard"], "Head"),
        primitive_box("Jarl_MoustacheL", (-0.15, -0.355, 2.00), (0.25, 0.045, 0.075), materials["beard"], "Head", (0, 0.20, 0.13)),
        primitive_box("Jarl_MoustacheR", (0.15, -0.355, 2.00), (0.25, 0.045, 0.075), materials["beard"], "Head", (0, -0.20, -0.13)),
        primitive_box("Jarl_BrowL", (-0.15, -0.335, 2.20), (0.20, 0.045, 0.055), materials["beard"], "Head", (0, 0, -0.16)),
        primitive_box("Jarl_BrowR", (0.15, -0.335, 2.20), (0.20, 0.045, 0.055), materials["beard"], "Head", (0, 0, 0.16)),
        primitive_box("Jarl_CrownBand", (0, -0.01, 2.31), (0.68, 0.62, 0.11), materials["brass"], "Crown"),
        primitive_box("Jarl_CrownPeakL", (-0.22, -0.01, 2.44), (0.13, 0.20, 0.23), materials["brass"], "Crown", (0, 0.0, 0.20)),
        primitive_box("Jarl_CrownPeakM", (0.0, -0.01, 2.49), (0.13, 0.20, 0.30), materials["brass"], "Crown"),
        primitive_box("Jarl_CrownPeakR", (0.22, -0.01, 2.44), (0.13, 0.20, 0.23), materials["brass"], "Crown", (0, 0.0, -0.20)),
        primitive_ico("Jarl_EyeL", (-0.15, -0.315, 2.10), (0.07, 0.025, 0.07), materials["pale"], "Head"),
        primitive_ico("Jarl_EyeR", (0.15, -0.315, 2.10), (0.07, 0.025, 0.07), materials["pale"], "Head"),
        primitive_box("Jarl_PauldronL", (-0.67, 0.0, 1.64), (0.34, 0.78, 0.32), materials["iron"], "Arm_L", (0, 0.08, -0.18)),
        primitive_box("Jarl_PauldronR", (0.67, 0.0, 1.64), (0.34, 0.78, 0.32), materials["iron"], "Arm_R", (0, -0.08, 0.18)),
        primitive_ico("Jarl_FurMantleL", (-0.45, 0.12, 1.69), (0.62, 0.60, 0.32), materials["fur"], "Chest"),
        primitive_ico("Jarl_FurMantleR", (0.45, 0.12, 1.69), (0.62, 0.60, 0.32), materials["fur"], "Chest"),
        primitive_ico("Jarl_FurCollar", (0.0, 0.18, 1.80), (0.80, 0.42, 0.25), materials["fur"], "Chest"),
        primitive_box("Jarl_UpperArmL", (-0.47, 0.01, 1.42), (0.28, 0.30, 0.55), materials["coat"], "Arm_L", (0, 0.0, -0.20)),
        primitive_box("Jarl_UpperArmR", (0.47, 0.01, 1.42), (0.28, 0.30, 0.55), materials["coat"], "Arm_R", (0, 0.0, 0.20)),
        primitive_box("Jarl_ForearmL", (-0.78, -0.01, 1.20), (0.24, 0.28, 0.48), materials["iron"], "Forearm_L", (0, 0.0, -0.18)),
        primitive_box("Jarl_ForearmR", (0.78, -0.01, 1.20), (0.24, 0.28, 0.48), materials["iron"], "Forearm_R", (0, 0.0, 0.18)),
        primitive_cylinder("Jarl_OathHammerHaft", (0.98, 0.0, 0.84), 0.055, 1.28, materials["wood"], "Hand_R", (0, 0.25, 0), 8),
        primitive_box("Jarl_OathHammerHead", (1.12, -0.01, 1.32), (0.42, 0.32, 0.27), materials["brass"], "Hand_R", (0.2, 0, 0)),
        primitive_box("Jarl_ThighL", (-0.25, 0.0, 0.63), (0.40, 0.45, 0.55), materials["coat"], "Leg_L"),
        primitive_box("Jarl_ThighR", (0.25, 0.0, 0.63), (0.40, 0.45, 0.55), materials["coat"], "Leg_R"),
        primitive_box("Jarl_ShinL", (-0.25, 0.02, 0.26), (0.34, 0.38, 0.44), materials["iron"], "Shin_L"),
        primitive_box("Jarl_ShinR", (0.25, 0.02, 0.26), (0.34, 0.38, 0.44), materials["iron"], "Shin_R"),
        primitive_box("Jarl_BootL", (-0.25, -0.16, 0.08), (0.40, 0.66, 0.18), materials["wood"], "Foot_L"),
        primitive_box("Jarl_BootR", (0.25, -0.16, 0.08), (0.40, 0.66, 0.18), materials["wood"], "Foot_R"),
        primitive_box("Jarl_Cape", (0.0, 0.36, 1.16), (1.05, 0.12, 1.38), materials["cape"], "Cape", (0.16, 0, 0)),
        primitive_box("Jarl_CapeRune", (0.0, 0.426, 1.26), (0.19, 0.018, 0.48), materials["pale"], "Cape"),
        primitive_box("Jarl_CapeRootL", (-0.39, 0.42, 1.04), (0.12, 0.045, 1.08), materials["wood"], "Cape", (0.10, 0.10, -0.18)),
        primitive_box("Jarl_CapeRootR", (0.39, 0.42, 1.04), (0.12, 0.045, 1.08), materials["wood"], "Cape", (0.10, -0.10, 0.18)),
    ]
    mesh = join_meshes(parts, "BarrowJarl_SkinnedMesh")
    bind(mesh, armature, "boss_barrow_jarl_v1")
    clips = build_actions(armature, "Jarl", True)
    return mesh, armature, clips


def make_guard(materials: dict[str, bpy.types.Material]) -> tuple[bpy.types.Object, bpy.types.Object, list[str]]:
    armature = make_armature("Oathbound", scale=0.76)
    parts = [
        primitive_box("Guard_Coat", (0, 0.01, 0.84), (0.78, 0.48, 0.88), materials["guard_coat"], "Spine"),
        primitive_ico("Guard_Hood", (0, 0.02, 1.57), (0.58, 0.52, 0.62), materials["hood"], "Head"),
        primitive_box("Guard_Belt", (0, -0.01, 0.59), (0.70, 0.52, 0.11), materials["brass"], "Hips"),
        primitive_ico("Guard_Head", (0, -0.255, 1.56), (0.34, 0.18, 0.38), materials["skin"], "Head"),
        primitive_box("Guard_Helm", (0, 0.0, 1.78), (0.50, 0.48, 0.12), materials["iron"], "Crown"),
        primitive_box("Guard_HelmNose", (0, -0.295, 1.61), (0.08, 0.065, 0.31), materials["iron"], "Head"),
        primitive_ico("Guard_EyeL", (-0.105, -0.435, 1.59), (0.05, 0.02, 0.05), materials["pale"], "Head"),
        primitive_ico("Guard_EyeR", (0.105, -0.435, 1.59), (0.05, 0.02, 0.05), materials["pale"], "Head"),
        primitive_box("Guard_ArmL", (-0.34, 0, 1.08), (0.20, 0.25, 0.38), materials["guard_coat"], "Arm_L", (0, 0, -0.18)),
        primitive_box("Guard_ArmR", (0.34, 0, 1.08), (0.20, 0.25, 0.38), materials["guard_coat"], "Arm_R", (0, 0, 0.18)),
        primitive_box("Guard_ForearmL", (-0.57, 0, 0.94), (0.18, 0.22, 0.35), materials["iron"], "Forearm_L", (0, 0, -0.18)),
        primitive_box("Guard_ForearmR", (0.57, 0, 0.94), (0.18, 0.22, 0.35), materials["iron"], "Forearm_R", (0, 0, 0.18)),
        primitive_cylinder("Guard_RoundShield", (-0.73, -0.11, 0.98), 0.36, 0.11, materials["shield"], "Hand_L", (math.pi / 2.0, 0, 0), 12),
        primitive_cylinder("Guard_ShieldBoss", (-0.73, -0.18, 0.98), 0.09, 0.045, materials["brass"], "Hand_L", (math.pi / 2.0, 0, 0), 10),
        primitive_cylinder("Guard_Spear", (0.73, 0.0, 0.86), 0.032, 1.05, materials["wood"], "Hand_R", (0, 0.21, 0), 8),
        primitive_ico("Guard_SpearTip", (0.84, 0, 1.38), (0.11, 0.08, 0.18), materials["pale"], "Hand_R"),
        primitive_box("Guard_SpearLantern", (0.86, -0.01, 0.84), (0.18, 0.14, 0.22), materials["brass"], "Hand_R"),
        primitive_ico("Guard_LanternGlow", (0.86, -0.09, 0.84), (0.10, 0.025, 0.12), materials["pale"], "Hand_R"),
        primitive_box("Guard_ThighL", (-0.18, 0, 0.43), (0.25, 0.31, 0.37), materials["guard_coat"], "Leg_L"),
        primitive_box("Guard_ThighR", (0.18, 0, 0.43), (0.25, 0.31, 0.37), materials["guard_coat"], "Leg_R"),
        primitive_box("Guard_ShinL", (-0.18, 0, 0.19), (0.21, 0.28, 0.32), materials["iron"], "Shin_L"),
        primitive_box("Guard_ShinR", (0.18, 0, 0.19), (0.21, 0.28, 0.32), materials["iron"], "Shin_R"),
        primitive_box("Guard_BootL", (-0.18, -0.11, 0.07), (0.26, 0.44, 0.13), materials["wood"], "Foot_L"),
        primitive_box("Guard_BootR", (0.18, -0.11, 0.07), (0.26, 0.44, 0.13), materials["wood"], "Foot_R"),
        primitive_box("Guard_Cape", (0, 0.24, 0.89), (0.66, 0.09, 0.78), materials["cape"], "Cape", (0.16, 0, 0)),
        primitive_box("Guard_CapeTrim", (0, 0.296, 0.82), (0.44, 0.018, 0.52), materials["pale"], "Cape"),
    ]
    mesh = join_meshes(parts, "Oathbound_SkinnedMesh")
    bind(mesh, armature, "enemy_oathbound_v1")
    clips = build_actions(armature, "Oathbound", False)
    return mesh, armature, clips


def add_preview_setup() -> tuple[bpy.types.Object, bpy.types.Object]:
    world = bpy.context.scene.world or bpy.data.worlds.new("PreviewWorld")
    bpy.context.scene.world = world
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs[0].default_value = (0.075, 0.105, 0.13, 1.0)
    world.node_tree.nodes["Background"].inputs[1].default_value = 0.34
    # Blender 5.1's Python enum exposes the renamed real-time renderer as
    # ``BLENDER_EEVEE``; older 4.x builds expose ``BLENDER_EEVEE_NEXT``.
    engines = {item.identifier for item in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items}
    bpy.context.scene.render.engine = "BLENDER_EEVEE" if "BLENDER_EEVEE" in engines else "BLENDER_EEVEE_NEXT"
    bpy.context.scene.render.resolution_x = 640
    bpy.context.scene.render.resolution_y = 640
    bpy.context.scene.render.resolution_percentage = 100
    bpy.context.scene.render.image_settings.file_format = "PNG"
    bpy.context.scene.view_settings.look = "None"
    bpy.context.scene.view_settings.view_transform = "Standard"
    bpy.ops.mesh.primitive_plane_add(size=20, location=(0, 0, 0))
    floor = bpy.context.object
    floor.name = "PreviewGround"
    floor.data.materials.append(make_material("Preview ground", (0.14, 0.18, 0.20)))
    bpy.ops.object.camera_add(location=(4.8, -6.8, 3.5))
    camera = bpy.context.object
    camera.name = "PreviewCam"
    bpy.context.scene.camera = camera
    bpy.ops.object.light_add(type="AREA", location=(3.5, -4.0, 6.0))
    key = bpy.context.object
    key.data.energy = 1050
    key.data.shape = "DISK"
    key.data.size = 5.0
    bpy.ops.object.light_add(type="AREA", location=(-4.0, -1.0, 3.0))
    fill = bpy.context.object
    fill.data.energy = 550
    fill.data.color = (0.45, 0.70, 1.0)
    fill.data.size = 4.0
    return camera, floor


def look_at(camera: bpy.types.Object, point: tuple[float, float, float]) -> None:
    camera.rotation_euler = (Vector(point) - camera.location).to_track_quat("-Z", "Y").to_euler()


def render_preview(camera: bpy.types.Object, armature: bpy.types.Object, path: Path,
                   center: tuple[float, float, float]) -> None:
    armature.animation_data.action = bpy.data.actions.get("Jarl_Idle") or bpy.data.actions.get("Oathbound_Idle")
    bpy.context.scene.frame_set(16)
    camera.location = (4.15, -5.65, 3.10) if center[2] > 1.0 else (3.15, -4.30, 2.45)
    look_at(camera, center)
    bpy.context.scene.render.filepath = str(path)
    bpy.ops.render.render(write_still=True)


def glb_json(path: Path) -> dict:
    raw = path.read_bytes()
    if raw[:4] != b"glTF":
        raise RuntimeError(f"Not a GLB: {path}")
    json_size = struct.unpack_from("<I", raw, 12)[0]
    return json.loads(raw[20:20 + json_size].decode("utf-8"))


def export_asset(mesh: bpy.types.Object, armature: bpy.types.Object, path: Path,
                 clips: list[str]) -> dict:
    bpy.ops.object.select_all(action="DESELECT")
    mesh.select_set(True)
    armature.select_set(True)
    bpy.context.view_layer.objects.active = armature
    result = bpy.ops.export_scene.gltf(
        filepath=str(path), export_format="GLB", use_selection=True,
        export_yup=True, export_apply=False, export_normals=True,
        export_materials="EXPORT", export_cameras=False, export_lights=False,
        export_animations=True, export_animation_mode="ACTIONS",
        export_force_sampling=True, export_optimize_animation_size=True,
        export_def_bones=True, export_skins=True, export_morph=False,
    )
    if "FINISHED" not in result:
        raise RuntimeError(f"Blender could not export {path}")
    doc = glb_json(path)
    exported = sorted(animation.get("name", "") for animation in doc.get("animations", []))
    expected = sorted(clips)
    if exported != expected:
        raise RuntimeError(f"Animation export mismatch for {path.name}: {exported} != {expected}")
    if len(doc.get("meshes", [])) != 1 or len(doc.get("skins", [])) != 1:
        raise RuntimeError(f"Expected one skinned mesh in {path.name}")
    return {
        "file": path.name,
        "bytes": path.stat().st_size,
        "meshes": len(doc.get("meshes", [])),
        "skins": len(doc.get("skins", [])),
        "animations": exported,
        "nodes": len(doc.get("nodes", [])),
    }


def main() -> None:
    clear_scene()
    PREVIEWS.mkdir(parents=True, exist_ok=True)
    materials = {
        "coat": make_material("Jarl weathered rootcoat", (0.12, 0.24, 0.25)),
        "guard_coat": make_material("Oathbound faded cloth", (0.18, 0.31, 0.34)),
        "hood": make_material("Oathbound midnight hood", (0.10, 0.18, 0.22)),
        "iron": make_material("Oath iron", (0.27, 0.37, 0.42)),
        "brass": make_material("Old oath brass", (0.72, 0.48, 0.15)),
        "skin": make_material("Pale wayfinder skin", (0.59, 0.70, 0.71)),
        "beard": make_material("Jarl winter beard", (0.78, 0.79, 0.72)),
        "fur": make_material("Jarl storm-fur", (0.36, 0.44, 0.44)),
        "wood": make_material("Rootroad ash wood", (0.25, 0.17, 0.12)),
        "cape": make_material("Pale oath cape", (0.30, 0.43, 0.48)),
        "shield": make_material("Oathbound shield", (0.38, 0.50, 0.52)),
        "pale": make_material("Pale rootlight", (0.50, 0.78, 0.88), emission=(0.20, 0.58, 0.92)),
    }
    camera, _floor = add_preview_setup()
    # ACTIONS export includes every Action in the Blender file.  Build/export
    # each family in sequence so a production Jarl file cannot quietly carry
    # the guard's clips (and vice versa) into the Web payload.
    jarl_mesh, jarl_armature, jarl_clips = make_jarl(materials)
    render_preview(camera, jarl_armature, PREVIEWS / "barrow_jarl_v1.png", (0.0, 0.0, 1.25))
    jarl_record = export_asset(
        jarl_mesh, jarl_armature, MODELS / "boss_barrow_jarl_v1.glb", jarl_clips
    )
    bpy.data.objects.remove(jarl_mesh, do_unlink=True)
    bpy.data.objects.remove(jarl_armature, do_unlink=True)
    for action in list(bpy.data.actions):
        if action.name.startswith("Jarl_"):
            bpy.data.actions.remove(action)

    guard_mesh, guard_armature, guard_clips = make_guard(materials)
    render_preview(camera, guard_armature, PREVIEWS / "oathbound_v1.png", (0.0, 0.0, 0.86))
    guard_record = export_asset(
        guard_mesh, guard_armature, MODELS / "enemy_oathbound_v1.glb", guard_clips
    )
    records = [
        jarl_record,
        guard_record,
    ]
    print(json.dumps({"status": "ok", "assets": records}, indent=2))


if __name__ == "__main__":
    main()
