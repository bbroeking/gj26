"""Build meshless GLB animation sidecars for the Wayfinder player rigs.

Run with Blender, not system Python:

    blender --background --factory-startup \
      --python wyrd/tools/export_animation_sidecars.py

The source Meshy GLBs remain untouched. Each output keeps the imported
armature, bone hierarchy, and animation Actions, but deliberately contains no
mesh, material, texture, or image payload. Godot merges the clip into the body
rig exactly as it did from the full walk/run export.
"""

from __future__ import annotations

import json
import struct
import sys
from pathlib import Path

import bpy


ROOT = Path(__file__).resolve().parents[2]
MODELS = ROOT / "models"
SIDECARS = {
    "_ranger_v5_walk.glb": "ranger_walk_anim_v1.glb",
    "_ranger_v5_run.glb": "ranger_run_anim_v1.glb",
    "player_chibi_v1_walk.glb": "player_chibi_walk_anim_v1.glb",
    "player_chibi_v1_run.glb": "player_chibi_run_anim_v1.glb",
    "meshy_staging/player_chibi_dash_anim_v1.glb": "player_chibi_dash_anim_v1.glb",
    "meshy_staging/npc_mara_linnet_v1_walk.glb": "npc_mara_linnet_v1_walk_anim.glb",
    "meshy_staging/npc_mara_linnet_v1_run.glb": "npc_mara_linnet_v1_run_anim.glb",
    "meshy_staging/npc_hod_tenter_v1_walk.glb": "npc_hod_tenter_v1_walk_anim.glb",
    "meshy_staging/npc_hod_tenter_v1_run.glb": "npc_hod_tenter_v1_run_anim.glb",
    "meshy_staging/npc_quill_v3_walk.glb": "npc_quill_v3_walk_anim.glb",
    "meshy_staging/npc_quill_v3_run.glb": "npc_quill_v3_run_anim.glb",
}


def _glb_json(path: Path) -> dict:
    raw = path.read_bytes()
    if raw[:4] != b"glTF":
        raise RuntimeError(f"Not a GLB: {path}")
    json_size = struct.unpack_from("<I", raw, 12)[0]
    return json.loads(raw[20 : 20 + json_size].decode("utf-8"))


def export_sidecar(source_name: str, output_name: str) -> dict:
    source = MODELS / source_name
    output = MODELS / output_name
    bpy.ops.wm.read_factory_settings(use_empty=True)
    result = bpy.ops.import_scene.gltf(filepath=str(source))
    if "FINISHED" not in result:
        raise RuntimeError(f"Blender could not import {source}")

    action_names = sorted(action.name for action in bpy.data.actions)
    if not action_names:
        raise RuntimeError(f"No animation Actions found in {source}")

    # Remove every render payload while retaining the armature and its Actions.
    for obj in list(bpy.data.objects):
        if obj.type == "MESH":
            bpy.data.objects.remove(obj, do_unlink=True)
    for datablocks in (bpy.data.meshes, bpy.data.materials, bpy.data.images,
                       bpy.data.textures):
        for datablock in list(datablocks):
            datablocks.remove(datablock)

    bpy.ops.object.select_all(action="SELECT")
    export_result = bpy.ops.export_scene.gltf(
        filepath=str(output),
        export_format="GLB",
        use_selection=True,
        export_yup=True,
        export_apply=False,
        export_materials="NONE",
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
    forbidden = {
        key: len(doc.get(key, []))
        for key in ("meshes", "materials", "textures", "images")
        if doc.get(key)
    }
    if forbidden:
        raise RuntimeError(f"Render payload leaked into {output}: {forbidden}")
    if not doc.get("animations"):
        raise RuntimeError(f"No animation was exported to {output}")
    return {
        "source": source_name,
        "output": output_name,
        "actions": action_names,
        "bytes": output.stat().st_size,
        "animations": len(doc["animations"]),
        "nodes": len(doc.get("nodes", [])),
    }


requested = set()
if "--" in sys.argv:
    requested = set(sys.argv[sys.argv.index("--") + 1 :])

records = [export_sidecar(source, output)
           for source, output in SIDECARS.items()
           if not requested or output in requested]
if requested and len(records) != len(requested):
    known = set(SIDECARS.values())
    raise RuntimeError(f"Unknown sidecar output(s): {sorted(requested - known)}")
print(json.dumps(records, indent=2))
