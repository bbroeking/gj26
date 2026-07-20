# Town Meshy production manifest

Status: integrated and visually verified, 2026-07-17

## Locked visual stem

Chunky low-poly storybook game asset; rounded, lightly beveled forms; hand-painted
flat color; subtle ink-outline read; five to eight hues per asset; warm light and
cooler shadows; no metallic/PBR finish; clean silhouette at the town camera's
gameplay distance.

Characters are generated in a strict T-pose at 25k target polygons, then rigged
by Meshy. Buildings are static exterior-only shells at 35k target polygons. The
repository consumes GLB even when Meshy also provides FBX for animation work.

## Assets

| Asset | Role | Output | Meshy tasks | Status |
|---|---|---|---|---|
| Mara Linnet | Wayfinder | rigged GLB, walk + run | concept `019f7310-5718-75bc-8c49-5a3e3f57bbc9`; model `019f7311-77f7-7643-bd7a-9ba9d1085f72`; rig `019f731e-9f1d-7899-86ae-fbb8ee4c9dd9` | complete |
| Old Hod Tenter | smith and vendor | rigged GLB, walk + run | concept `019f7313-c44e-76b4-86af-f0e8a0d88c3f`; model `019f731e-8a6f-7893-bb62-c029443ef8dc`; rig `019f7321-c5a9-790f-9f6d-968df2863651` | complete |
| Quill | herbalist | rigged GLB, walk + run | concept `019f7313-cbe5-7b43-bf51-d2f56cb37977`; model `019f731e-8c64-7173-be7e-de1f8603eee2`; rig `019f7321-df54-7e28-98aa-ded3b04a162e` | complete |
| Maud's Hearth | cottage/dairy exterior | static GLB | concept `019f7310-5ec9-75bf-bbe2-d1b6f3f8b986`; model `019f7311-7966-7644-9c39-ee764832cd66` | complete |
| Hod's Smithy | forge exterior | static GLB | concept `019f7313-cb6f-76b7-85d7-926428a9bc5d`; model `019f731e-8e3b-788b-ad55-a1e3f5b0d89c` | complete |
| Chartmaker's tower | town landmark exterior | static GLB | concept `019f7313-d385-7b45-b739-7bc368a72f9a`; model `019f731e-904d-7d3b-881b-7ce3b6e96d32` | complete |
| Player dash | `RunFast` animation for existing player rig | meshless animation GLB | rig `019eb1c2-b42c-76a2-843d-310511003b2e`; animation `019f731e-ec22-7d55-95c6-0c8149773e47` | complete |

## Integration targets

- `models/npc_mara_linnet_v1_rigged.glb`
- `models/npc_hod_tenter_v1_rigged.glb`
- `models/npc_quill_v3_rigged.glb`
- `models/building_mauds_hearth_v1.glb`
- `models/building_hods_smithy_v1.glb`
- `models/building_chartmaker_tower_v1.glb`
- `models/player_chibi_dash_anim_v1.glb`

Each NPC also retains lightweight meshless walk/run sidecars beside the body
GLB. The production character exports remove Meshy's visible `Icosphere` rig
helper; stationary town NPCs hold a natural pose sampled from their own walk
sidecar instead of displaying the service's T-pose `clip0`.

Total Meshy spend: **252 credits** (six concepts, six Meshy 6 image-to-3D
models with remesh, three character rigs, and one player animation).

The former town assets remain in the repository for compatibility/history, but
the live town scripts now reference this set. Godot import, gameplay-camera
rendering, ground alignment, NPC stance, and dash clip resolution were verified
after integration.

## Quality audit — 2026-07-18

All six town models passed a uniform isolated-render review. The apparent asset
quality problem in gameplay came from town composition rather than failed Meshy
geometry, so **no regeneration is currently approved or required**.

Integration corrections:

- removed the obsolete market stall that duplicated and obscured Hod's smithy;
- enlarged and regrouped the three exterior shells into a readable landmark row;
- grounded Meshy models from their fitted bounds after scaling; and
- limited fresh-town paths to landmarks that actually exist in the current
  campaign state, eliminating roads to empty future locations.

Before spending more credits on a town replacement, render the candidate in
isolation with `wyrd/tools/render_meshy_audit.py`, then compare its silhouette in
the gameplay camera. Regenerate only when the source model fails both checks;
placement, scale, grounding, or scene clutter should be corrected in integration.

The Meshy task list may show a concept under more than one task category. Entries
with the same task ID are one generation, not duplicate paid work. The available
Meshy MCP does not expose task deletion, so repository manifests and production
filenames are the source of truth for what is approved for the game.
