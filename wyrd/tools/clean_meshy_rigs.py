"""Remove Meshy's visible rig-helper sphere and export production character GLBs.

Run with Blender:

    blender --background --factory-startup --python wyrd/tools/clean_meshy_rigs.py

Meshy's Character_output GLBs contain an ``Icosphere`` helper alongside the
skinned character. It is useful to the service's rigging pipeline but must not
render in game, and it also poisons runtime AABB-based height normalization.
"""

from __future__ import annotations

import json
import struct
from pathlib import Path

import bpy


ROOT = Path(__file__).resolve().parents[2]
MODELS = ROOT / "models"
RIGS = {
    "meshy_staging/npc_mara_linnet_v1_rigged.glb":
        "npc_mara_linnet_v1_rigged.glb",
    "meshy_staging/npc_hod_tenter_v1_rigged.glb":
        "npc_hod_tenter_v1_rigged.glb",
    "meshy_staging/npc_quill_v3_rigged.glb":
        "npc_quill_v3_rigged.glb",
}


def _glb_json(path: Path) -> dict:
    raw = path.read_bytes()
    if raw[:4] != b"glTF":
        raise RuntimeError(f"Not a GLB: {path}")
    json_size = struct.unpack_from("<I", raw, 12)[0]
    return json.loads(raw[20 : 20 + json_size].decode("utf-8"))


def clean_rig(source_name: str, output_name: str) -> dict:
    source = MODELS / source_name
    output = MODELS / output_name
    bpy.ops.wm.read_factory_settings(use_empty=True)
    result = bpy.ops.import_scene.gltf(filepath=str(source))
    if "FINISHED" not in result:
        raise RuntimeError(f"Blender could not import {source}")

    removed = []
    for obj in list(bpy.data.objects):
        if obj.type == "MESH" and obj.name.lower().startswith("icosphere"):
            removed.append(obj.name)
            bpy.data.objects.remove(obj, do_unlink=True)
    if not removed:
        raise RuntimeError(f"No Meshy helper sphere found in {source}")

    bpy.ops.object.select_all(action="SELECT")
    export_result = bpy.ops.export_scene.gltf(
        filepath=str(output),
        export_format="GLB",
        use_selection=True,
        export_yup=True,
        export_apply=False,
        export_cameras=False,
        export_lights=False,
        export_animations=True,
        export_animation_mode="ACTIONS",
        export_force_sampling=True,
        export_optimize_animation_size=True,
        export_def_bones=True,
        export_skins=True,
        export_morph=False,
    )
    if "FINISHED" not in export_result:
        raise RuntimeError(f"Blender could not export {output}")

    doc = _glb_json(output)
    if len(doc.get("meshes", [])) != 1 or not doc.get("skins"):
        raise RuntimeError(f"Unexpected cleaned rig structure in {output}")
    if not doc.get("animations"):
        raise RuntimeError(f"Idle animation was lost from {output}")
    return {
        "source": source_name,
        "output": output_name,
        "removed": removed,
        "bytes": output.stat().st_size,
        "meshes": len(doc["meshes"]),
        "animations": len(doc["animations"]),
    }


print(json.dumps([clean_rig(source, output)
                  for source, output in RIGS.items()], indent=2))
