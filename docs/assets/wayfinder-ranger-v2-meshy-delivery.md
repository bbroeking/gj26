# Wayfinder Ranger v2 — Meshy delivery

Generated 2026-07-24 to replace the mismatched chibi Ranger and oversized bow.

## Art direction

- One moss-green, cream, and chestnut palette across character and weapon.
- Cozy storybook chibi proportions with a large readable hood, simple tunic,
  short trousers, and sturdy boots.
- Compact recurved shortbow with warm wood, moss-green grip, and cream wraps.
- Bow normalized to 0.68 m, about 54% of the Ranger's 1.25 m body height.

## Source references

- `docs/concept-art/meshy-source/player_wayfinder_v2_apose.png`
- `docs/concept-art/meshy-source/prop_shortbow_v2.png`

The character reference deliberately uses a clear A-pose with no bow or quiver
so Meshy can separate and skin the limbs. The bow reference is an isolated
orthographic-style prop view.

## Meshy pipeline

1. Image-to-3D with Meshy 6 Standard, private generation.
2. Texture from the source image at 2K with PBR and lighting removal.
3. Ranger remeshed to 30K triangles before auto-rigging.
4. Humanoid auto-rig with Meshy's walking clip.
5. Blender cleanup removes Meshy's rig helper, exports a meshless walking
   sidecar, softens metallic/roughness cues, and normalizes the bow.

Meshy consumed 60 machine credits for the two model generations and two texture
passes. Remeshing was free.

## Production assets

- `models/player_wayfinder_v2_rigged.glb`
- `models/player_wayfinder_v2_walk_anim.glb`
- `models/prop_shortbow_v2.glb`
- `models/scripts/process_wayfinder_ranger_v2.py`

Raw downloads and rig exports are retained under `models/meshy_staging/`.
