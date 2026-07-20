"""Render uniform previews of the current Meshy town set for visual triage.

Run with Blender:

    blender --background --factory-startup --python wyrd/tools/render_meshy_audit.py

Outputs land in ``/tmp/wayfinder_meshy_audit`` and do not modify source GLBs.
"""

from __future__ import annotations

import math
from pathlib import Path

import bpy
from mathutils import Vector


ROOT = Path(__file__).resolve().parents[2]
MODELS = ROOT / "models"
OUTPUT = Path("/tmp/wayfinder_meshy_audit")
OUTPUT.mkdir(parents=True, exist_ok=True)

ASSETS = [
    "building_mauds_hearth_v1.glb",
    "building_hods_smithy_v1.glb",
    "building_chartmaker_tower_v1.glb",
    "npc_mara_linnet_v1_rigged.glb",
    "npc_hod_tenter_v1_rigged.glb",
    "npc_quill_v3_rigged.glb",
]


def world_bounds(objects: list[bpy.types.Object]) -> tuple[Vector, Vector]:
    corners = [obj.matrix_world @ Vector(corner)
               for obj in objects if obj.type == "MESH"
               for corner in obj.bound_box]
    return (
        Vector(tuple(min(point[i] for point in corners) for i in range(3))),
        Vector(tuple(max(point[i] for point in corners) for i in range(3))),
    )


def render_asset(filename: str) -> None:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(MODELS / filename))
    meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
    low, high = world_bounds(meshes)
    center = (low + high) * 0.5
    size = high - low

    root = bpy.data.objects.new("AuditRoot", None)
    bpy.context.scene.collection.objects.link(root)
    for obj in list(bpy.context.scene.objects):
        if obj != root and obj.parent is None:
            obj.parent = root
    root.location = Vector((-center.x, -center.y, -low.z))

    world = bpy.data.worlds.new("AuditWorld")
    bpy.context.scene.world = world
    world.use_nodes = True
    background = world.node_tree.nodes.get("Background")
    background.inputs[0].default_value = (0.69, 0.66, 0.58, 1.0)
    background.inputs[1].default_value = 0.5

    bpy.ops.mesh.primitive_plane_add(size=max(size.x, size.y) * 3.5,
                                     location=(0, 0, -0.015))
    plane = bpy.context.active_object
    mat = bpy.data.materials.new("Ground")
    mat.diffuse_color = (0.44, 0.50, 0.32, 1.0)
    mat.roughness = 1.0
    plane.data.materials.append(mat)

    bpy.ops.object.light_add(type="AREA", location=(-4.5, -5.5, 7.0))
    key = bpy.context.active_object
    key.data.energy = 900.0
    key.data.shape = "DISK"
    key.data.size = 5.0

    bpy.ops.object.light_add(type="AREA", location=(4.0, 2.0, 4.0))
    fill = bpy.context.active_object
    fill.data.energy = 350.0
    fill.data.size = 4.0

    height = max(size.z, 0.1)
    bpy.ops.object.camera_add(location=(height * 2.2, -height * 2.6,
                                       height * 1.85))
    camera = bpy.context.active_object
    target = Vector((0.0, 0.0, height * 0.46))
    camera.rotation_euler = (target - camera.location).to_track_quat("-Z", "Y").to_euler()
    camera.data.type = "ORTHO"
    camera.data.ortho_scale = max(height * 1.35, max(size.x, size.y) * 1.45)

    scene = bpy.context.scene
    scene.camera = camera
    scene.render.engine = "BLENDER_EEVEE"
    scene.render.resolution_x = 512
    scene.render.resolution_y = 512
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.filepath = str(OUTPUT / filename.replace(".glb", ".png"))
    scene.view_settings.view_transform = "Standard"
    scene.view_settings.look = "None"
    scene.render.film_transparent = False
    bpy.ops.render.render(write_still=True)
    print("AUDIT_RENDER", scene.render.filepath)


for asset in ASSETS:
    render_asset(asset)
