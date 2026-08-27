"""Prepare the Meshy Wayfinder Ranger v2 assets for Godot.

Run with Blender:

    blender --background --factory-startup \
      --python models/scripts/process_wayfinder_ranger_v2.py

The Meshy sources stay in ``models/meshy_staging``. Production outputs are:

* ``models/player_wayfinder_v2_rigged.glb``
* ``models/player_wayfinder_v2_walk_anim.glb``
* ``models/prop_shortbow_v2.glb``
"""

from __future__ import annotations

import argparse
import json
import struct
import sys
from pathlib import Path

import bpy
from mathutils import Vector


ROOT = Path(__file__).resolve().parents[2]
MODELS = ROOT / "models"
RIG_DIR = (
    MODELS
    / "meshy_staging"
    / "player_wayfinder_v2_rig_export"
    / "Meshy_AI_Greencloak_Adventurer_biped"
)
BODY_SOURCE = RIG_DIR / "Meshy_AI_Greencloak_Adventurer_biped_Character_output.glb"
WALK_SOURCE = (
    RIG_DIR
    / "Meshy_AI_Greencloak_Adventurer_biped_Animation_Walking_withSkin.glb"
)
BOW_SOURCE = MODELS / "meshy_staging" / "prop_shortbow_v2_source.glb"

BODY_OUTPUT = MODELS / "player_wayfinder_v2_rigged.glb"
WALK_OUTPUT = MODELS / "player_wayfinder_v2_walk_anim.glb"
BOW_OUTPUT = MODELS / "prop_shortbow_v2.glb"

SHORTBOW_HEIGHT = 0.68


def glb_json(path: Path) -> dict:
    raw = path.read_bytes()
    if raw[:4] != b"glTF":
        raise RuntimeError(f"Not a GLB: {path}")
    json_size = struct.unpack_from("<I", raw, 12)[0]
    return json.loads(raw[20 : 20 + json_size].decode("utf-8"))


def import_glb(path: Path) -> None:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    result = bpy.ops.import_scene.gltf(filepath=str(path))
    if "FINISHED" not in result:
        raise RuntimeError(f"Blender could not import {path}")


def remove_meshy_helpers() -> list[str]:
    removed = []
    for obj in list(bpy.data.objects):
        if obj.type == "MESH" and obj.name.lower().startswith("icosphere"):
            removed.append(obj.name)
            bpy.data.objects.remove(obj, do_unlink=True)
    return removed


def soften_pbr() -> None:
    """Keep Meshy's painted base color while suppressing shiny AI-material cues."""
    for material in bpy.data.materials:
        material.diffuse_color = (*material.diffuse_color[:3], 1.0)
        material.metallic = 0.0
        material.roughness = 0.88
        if not material.use_nodes or material.node_tree is None:
            continue
        for node in material.node_tree.nodes:
            if node.type != "BSDF_PRINCIPLED":
                continue
            if "Metallic" in node.inputs:
                node.inputs["Metallic"].default_value = 0.0
            if "Roughness" in node.inputs:
                node.inputs["Roughness"].default_value = 0.88


def export_scene(
    path: Path,
    *,
    animations: bool,
    materials: bool = True,
    morphs: bool = False,
    deform_bones_only: bool = True,
) -> None:
    bpy.ops.object.select_all(action="SELECT")
    result = bpy.ops.export_scene.gltf(
        filepath=str(path),
        export_format="GLB",
        use_selection=True,
        export_yup=True,
        export_apply=False,
        export_cameras=False,
        export_lights=False,
        export_materials="EXPORT" if materials else "NONE",
        export_animations=animations,
        export_animation_mode="ACTIONS",
        export_force_sampling=animations,
        export_optimize_animation_size=animations,
        export_def_bones=deform_bones_only,
        export_skins=True,
        export_morph=morphs,
    )
    if "FINISHED" not in result:
        raise RuntimeError(f"Blender could not export {path}")


def add_left_hand_socket_and_grip_shape() -> dict:
    """Author a palm socket and closed mitten pose without adding finger bones."""
    armatures = [obj for obj in bpy.context.scene.objects if obj.type == "ARMATURE"]
    meshes = [
        obj
        for obj in bpy.context.scene.objects
        if obj.type == "MESH" and obj.vertex_groups.get("LeftHand") is not None
    ]
    if len(armatures) != 1 or len(meshes) != 1:
        raise RuntimeError(
            "Expected one armature and one LeftHand-weighted Ranger mesh; "
            f"found armatures={len(armatures)}, meshes={len(meshes)}"
        )
    armature = armatures[0]
    body = meshes[0]
    hand_group = body.vertex_groups["LeftHand"]

    weighted_vertices = []
    for vertex in body.data.vertices:
        weight = next(
            (
                assignment.weight
                for assignment in vertex.groups
                if assignment.group == hand_group.index
            ),
            0.0,
        )
        if weight >= 0.5:
            weighted_vertices.append((body.matrix_world @ vertex.co, weight))
    if not weighted_vertices:
        raise RuntimeError("LeftHand vertex group has no strongly weighted vertices")

    total_weight = sum(weight for _, weight in weighted_vertices)
    palm_world = sum(
        (point * weight for point, weight in weighted_vertices),
        Vector(),
    ) / total_weight
    palm_armature = armature.matrix_world.inverted() @ palm_world

    bpy.ops.object.select_all(action="DESELECT")
    armature.select_set(True)
    bpy.context.view_layer.objects.active = armature
    bpy.ops.object.mode_set(mode="EDIT")
    left_hand = armature.data.edit_bones.get("LeftHand")
    if left_hand is None:
        raise RuntimeError("Ranger armature has no LeftHand bone")
    socket = armature.data.edit_bones.get("Socket_Hand_L")
    if socket is None:
        socket = armature.data.edit_bones.new("Socket_Hand_L")
    hand_direction = (left_hand.tail - left_hand.head).normalized()
    socket.head = palm_armature
    socket.tail = palm_armature + hand_direction * 5.0
    # Equipment socket convention:
    #   +Y follows the hand/fingers (and the bow's authored long axis).
    #   +X is the hand-relative "top" of the item (the bow-string side).
    # This gives Godot a meaningful full socket basis instead of a palm point
    # with the generated hand bone's arbitrary roll.
    armature_up = (
        armature.matrix_world.inverted().to_3x3() @ Vector((0.0, 0.0, 1.0))
    ).normalized()
    socket_x = armature_up - hand_direction * armature_up.dot(hand_direction)
    if socket_x.length_squared < 1.0e-8:
        socket_x = Vector((1.0, 0.0, 0.0))
    socket_x.normalize()
    socket_z = socket_x.cross(hand_direction).normalized()
    socket.align_roll(socket_z)
    socket.parent = left_hand
    socket.use_connect = False
    socket.use_deform = False
    socket.inherit_scale = "NONE"
    bpy.ops.object.mode_set(mode="OBJECT")

    if body.data.shape_keys is None:
        body.shape_key_add(name="Basis", from_mix=False)
    basis = body.data.shape_keys.key_blocks["Basis"]
    grip_key = body.data.shape_keys.key_blocks.get("BowGrip_L")
    if grip_key is None:
        grip_key = body.shape_key_add(name="BowGrip_L", from_mix=False)
    for index in range(len(body.data.vertices)):
        grip_key.data[index].co = basis.data[index].co

    body_inverse = body.matrix_world.inverted()
    changed_vertices = 0
    max_move = 0.0
    for vertex in body.data.vertices:
        weight = next(
            (
                assignment.weight
                for assignment in vertex.groups
                if assignment.group == hand_group.index
            ),
            0.0,
        )
        if weight <= 0.05:
            continue
        point = body.matrix_world @ basis.data[vertex.index].co
        fold = max(
            0.0,
            min(1.0, (point.x - (palm_world.x - 0.012)) / 0.058),
        )
        fold = fold * fold * (3.0 - 2.0 * fold)
        influence = min(1.0, weight * 1.25) * fold
        if influence <= 0.0:
            continue
        target = point.copy()
        target.x = point.x + (palm_world.x + 0.010 - point.x) * 0.88 * influence
        target.y = point.y + 0.032 * influence
        target.z = point.z + (palm_world.z - 0.006 - point.z) * 0.30 * influence
        grip_key.data[vertex.index].co = body_inverse @ target
        changed_vertices += 1
        max_move = max(max_move, (target - point).length)
    grip_key.value = 1.0
    bpy.context.view_layer.update()

    return {
        "socket": socket.name,
        "socket_parent": left_hand.name,
        "palm_world": [round(value, 6) for value in palm_world],
        "grip_shape": grip_key.name,
        "grip_shape_value": grip_key.value,
        "changed_vertices": changed_vertices,
        "max_vertex_move_m": round(max_move, 6),
    }


def clean_body() -> dict:
    import_glb(BODY_SOURCE)
    removed = remove_meshy_helpers()
    if not removed:
        raise RuntimeError("Meshy rig-helper sphere was not found in body source")
    grip = add_left_hand_socket_and_grip_shape()
    soften_pbr()
    export_scene(
        BODY_OUTPUT,
        animations=True,
        morphs=True,
        deform_bones_only=False,
    )
    doc = glb_json(BODY_OUTPUT)
    if len(doc.get("meshes", [])) != 1 or not doc.get("skins"):
        raise RuntimeError("Cleaned Ranger body lost its mesh or skin")
    return {
        "output": BODY_OUTPUT.name,
        "removed": removed,
        "meshes": len(doc["meshes"]),
        "skins": len(doc["skins"]),
        "animations": len(doc.get("animations", [])),
        "grip": grip,
        "bytes": BODY_OUTPUT.stat().st_size,
    }


def export_walk_sidecar() -> dict:
    import_glb(WALK_SOURCE)
    actions = sorted(action.name for action in bpy.data.actions)
    if not actions:
        raise RuntimeError("Walking source contains no animation Actions")

    for obj in list(bpy.data.objects):
        if obj.type == "MESH":
            bpy.data.objects.remove(obj, do_unlink=True)
    for datablocks in (
        bpy.data.meshes,
        bpy.data.materials,
        bpy.data.images,
        bpy.data.textures,
    ):
        for datablock in list(datablocks):
            datablocks.remove(datablock)

    export_scene(WALK_OUTPUT, animations=True, materials=False)
    doc = glb_json(WALK_OUTPUT)
    forbidden = {
        key: len(doc.get(key, []))
        for key in ("meshes", "materials", "textures", "images")
        if doc.get(key)
    }
    if forbidden or not doc.get("animations"):
        raise RuntimeError(
            f"Invalid walk sidecar: render payload={forbidden}, "
            f"animations={len(doc.get('animations', []))}"
        )
    return {
        "output": WALK_OUTPUT.name,
        "actions": actions,
        "animations": len(doc["animations"]),
        "bytes": WALK_OUTPUT.stat().st_size,
    }


def find_bow_grip_anchor(meshes: list[bpy.types.Object]) -> tuple[Vector, dict]:
    """Locate the moss-green wrap from the embedded base-color texture + UVs."""
    image = None
    for obj in meshes:
        for material in obj.data.materials:
            if material is None or not material.use_nodes or material.node_tree is None:
                continue
            for node in material.node_tree.nodes:
                if node.type == "TEX_IMAGE" and node.image is not None:
                    if "base" in node.image.name.lower() and "color" in node.image.name.lower():
                        image = node.image
                        break
            if image is not None:
                break
        if image is not None:
            break
    if image is None:
        raise RuntimeError("Shortbow base-color texture was not found")

    width, height = image.size
    pixels = image.pixels[:]
    samples = []
    for obj in meshes:
        uv_layer = obj.data.uv_layers.active
        if uv_layer is None:
            continue
        for loop in obj.data.loops:
            uv = uv_layer.data[loop.index].uv
            x = min(width - 1, max(0, int((uv.x % 1.0) * width)))
            y = min(height - 1, max(0, int((uv.y % 1.0) * height)))
            pixel = (y * width + x) * 4
            red, green, blue = pixels[pixel : pixel + 3]
            if (
                green > red * 1.08
                and green > blue * 1.55
                and green > 0.045
            ):
                vertex = obj.data.vertices[loop.vertex_index]
                samples.append(obj.matrix_world @ vertex.co)
    if len(samples) < 1000:
        raise RuntimeError(
            f"Shortbow grip detection found too few green UV samples: {len(samples)}"
        )

    centroid = sum(samples, Vector()) / len(samples)
    low = Vector(tuple(min(point[i] for point in samples) for i in range(3)))
    high = Vector(tuple(max(point[i] for point in samples) for i in range(3)))
    return centroid, {
        "image": image.name,
        "samples": len(samples),
        "bbox_low": [round(value, 6) for value in low],
        "bbox_high": [round(value, 6) for value in high],
    }


def clean_bow() -> dict:
    import_glb(BOW_SOURCE)
    remove_meshy_helpers()
    meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
    if not meshes:
        raise RuntimeError("Shortbow source contains no mesh")

    corners = [
        obj.matrix_world @ Vector(corner)
        for obj in meshes
        for corner in obj.bound_box
    ]
    low = Vector(tuple(min(point[i] for point in corners) for i in range(3)))
    high = Vector(tuple(max(point[i] for point in corners) for i in range(3)))
    center = (low + high) * 0.5
    grip_anchor, grip_detection = find_bow_grip_anchor(meshes)
    source_height = high.z - low.z
    if source_height <= 0.0:
        raise RuntimeError("Shortbow source has zero height")
    scale = SHORTBOW_HEIGHT / source_height

    # Bake every imported mesh into a shared grip-centered coordinate system.
    # The geometric bbox center lies near the string; the actual handhold is
    # the moss-green wrapped section, detected above from texture + UV data.
    for obj in meshes:
        world = obj.matrix_world.copy()
        for vertex in obj.data.vertices:
            vertex.co = (world @ vertex.co - grip_anchor) * scale
        obj.matrix_world.identity()

    soften_pbr()
    export_scene(BOW_OUTPUT, animations=False)
    doc = glb_json(BOW_OUTPUT)
    if not doc.get("meshes") or doc.get("skins"):
        raise RuntimeError("Cleaned shortbow has an invalid static-mesh structure")
    return {
        "output": BOW_OUTPUT.name,
        "height_m": SHORTBOW_HEIGHT,
        "source_height_m": round(source_height, 4),
        "scale": round(scale, 5),
        "bbox_center_to_grip_m": [
            round(value * scale, 6) for value in (grip_anchor - center)
        ],
        "grip_detection": grip_detection,
        "meshes": len(doc["meshes"]),
        "bytes": BOW_OUTPUT.stat().st_size,
    }


def parse_args() -> argparse.Namespace:
    blender_args = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else []
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--only",
        choices=("all", "body", "walk", "bow"),
        default="all",
        help="Rebuild one production output instead of the full delivery.",
    )
    return parser.parse_args(blender_args)


args = parse_args()
steps = {
    "body": clean_body,
    "walk": export_walk_sidecar,
    "bow": clean_bow,
}
targets = steps.keys() if args.only == "all" else (args.only,)
print(json.dumps({target: steps[target]() for target in targets}, indent=2))
