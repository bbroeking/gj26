# Casual walk animation delivery

Generated 2026-07-25 for the Godot cast using Meshy's
`Casual_Walk_inplace` action (action ID 613). The four animation jobs cost
3 credits each, 12 credits total.

| Character | Rig task | Animation task | Production sidecar |
| --- | --- | --- | --- |
| Player | `019eb1c2-b42c-76a2-843d-310511003b2e` | `019f9ad2-7c44-758d-904c-2057af656e76` | `models/player_wayfinder_v2_casual_walk_anim.glb` |
| Mara Linnet | `019f731e-9f1d-7899-86ae-fbb8ee4c9dd9` | `019f9ad2-7eb9-7beb-9e35-c85b03875c2f` | `models/npc_mara_linnet_v1_casual_walk_anim.glb` |
| Old Hod Tenter | `019f7321-c5a9-790f-9f6d-968df2863651` | `019f9ad2-81a1-79de-8629-13e1275dcb7e` | `models/npc_hod_tenter_v1_casual_walk_anim.glb` |
| Quill | `019f7321-df54-7e28-98aa-ded3b04a162e` | `019f9ad2-839c-7df9-ac15-150dd96b5461` | `models/npc_quill_v3_casual_walk_anim.glb` |

The player animation came from the previously recorded chibi rig. Inspection
confirmed that it and Ranger v2 have the same ordered 24-bone Meshy hierarchy,
so the meshless clip can be merged onto the current Ranger without retargeting.

The production files contain an armature and one looping animation only—no
mesh, material, image, or texture payload. Raw downloaded GLBs remain under
`models/meshy_staging/`. Rebuild the production sidecars with:

```bash
blender --background --factory-startup \
  --python wyrd/tools/export_animation_sidecars.py -- \
  player_wayfinder_v2_casual_walk_anim.glb \
  npc_mara_linnet_v1_casual_walk_anim.glb \
  npc_hod_tenter_v1_casual_walk_anim.glb \
  npc_quill_v3_casual_walk_anim.glb
```
