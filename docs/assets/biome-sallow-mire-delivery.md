# Sallow Mire asset delivery record

Delivery audit: 2026-07-16. Original asset commit: `9887500` (2026-06-28/29
biome batch).

## Shared contract

- Source: Meshy low-poly text-to-3D, generated with the project owner's paid
  Meshy credits. No third-party reference image is recorded.
- Reconstructed prompt stem: “chunky low-poly stylized fantasy wetland prop,
  cozy fairytale dungeon crawler, strong simple silhouette, untextured single
  object, game-ready, no ground plane.” The exact original job prompts and
  Meshy task ids were not committed and cannot be recovered from git; this is
  a provenance gap, not a claim that the reconstruction is verbatim.
- Cleanup: imported as static GLB; normalized at runtime with `GlbFit`, forced
  matte/unmetal for Compatibility, assigned a controlled biome tint, and given
  the shared ink outline. These props have no rig or animation contract.
- Coordinate contract: grounded by runtime normalization; Godot +Y up; static
  prop orientation is non-semantic and may be rotated by room dressing.
- License/provenance: paid-account Meshy output created for this project. Meshy's
  current published policy says paid customers own their generated assets when
  their inputs do not violate third-party rights. Re-verify the account plan
  and terms before commercial release:
  https://help.meshy.ai/en/articles/9992001-can-i-use-my-generated-assets-for-commercial-projects
- QA: source files are small (about 90–481 KB each), contain no external
  textures, and are included in the native and Web export manifests. Native
  Forward+ and Web Compatibility in-room QA is recorded in the Spec 55 notes.

## Delivered files

| File | Dominant shape / gameplay read | Source prompt suffix | Cleanup note |
|---|---|---|---|
| `biome_bog_roots_v1.glb` | broad gnarled root fan; shrine/setpiece anchor | “gnarled drowned tree roots” | warm grey-brown tint; focal scale |
| `biome_bog_sunkenlog_v1.glb` | low long fallen log; wall-line obstacle read | “mossy half-sunken fallen log” | dark moss tint; horizontal placement |
| `biome_bog_dockpost_v1.glb` | tall split timber; traversal rhythm | “weathered marsh dock post” | weathered timber tint; corner placement |
| `biome_bog_lilypads_v1.glb` | flat clustered pads; wet-floor read | “cluster of oversized lily pads” | green tint; kept low against floor |
| `biome_bog_wisp_v1.glb` | small upright flame; shrine beacon | “will-o-wisp flame on a simple marsh stand” | pale emissive-family tint; focal use |
| `biome_bog_mudmound_v1.glb` | squat lumpy mound; breakable scatter | “chunky dark mud mound” | dark mud tint; satellite use |
| `biome_bog_reeds_v1.glb` | tall narrow reed bundle; room-edge curtain | “bundle of tall sallow marsh reeds” | marsh-green tint; wall clusters |

## Gameplay package attached to the art

The seven props are not approved as a palette-only biome. `mire` additionally
owns reed-bed/drowned-root room themes, a guaranteed wisp-pool wayside shrine,
two native Mothmint nodes, the ranged Bog Wisp family role, three rewritten
Affix presentations, wet fog/motes/reflection, a Burrow Boar den relationship,
and multi-layer Chart depth as its replay reason.

## Follow-up

- Backfill original Meshy task ids and exact prompts if they remain in the
  owner's Meshy history.
- Preserve a source `.blend` cleanup file for the next revision; this inherited
  batch predates the current rule that every Meshy result passes through a
  committed Blender cleanup artifact.
