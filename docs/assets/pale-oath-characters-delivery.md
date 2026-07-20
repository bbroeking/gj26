# Pale Oath character delivery

Status: production Blender pass, 2026-07-18.

## Delivered assets

| Runtime asset | Rig | Animation clips | Web payload |
|---|---|---|---:|
| `models/boss_barrow_jarl_v1.glb` | one Blender armature + one skinned mesh | `Jarl_Idle`, `Jarl_Walk`, `Jarl_Attack`, `Jarl_Hit`, `Jarl_Shield`, `Jarl_Reeling`, `Jarl_Relief`, `Jarl_Kneel`, `Jarl_Defeat` | 266,644 B |
| `models/enemy_oathbound_v1.glb` | one Blender armature + one skinned mesh | `Oathbound_Idle`, `Oathbound_Walk`, `Oathbound_Attack`, `Oathbound_Hit`, `Oathbound_Shield`, `Oathbound_Reeling`, `Oathbound_Relief`, `Oathbound_Defeat` | 236,384 B |

Both files are self-contained, texture-free low-poly GLBs. Materials use
Principled BSDF with the project’s 2-segment, angle-limited bevel treatment;
the actual Godot lighting, outline pass, and fog remain in the World scene.

## Art and encounter contract

- The Barrow Jarl is a broad, root-cloaked old ruler: brass crown, winter
  beard, pale rootlight, oath hammer, fur mantle, and a readable chest rune.
- The Oathbound is a compact post-keeper: hood and helm, pale eyes, round oath
  shield, lantern-spear, and a folded rootroad cape.
- `layout_loader.gd` loads only these production paths. The former silhouette
  files are no longer in the boss/guard registry, Web include filter, or PCK
  audit. The old Blender blockout routine is diagnostic-only and writes only
  beneath `models/debug/` when manually invoked.
- `BarrowJarl` plays shield, relief, kneel, and defeat clips at its existing
  authority-owned encounter transitions. `OathboundGuard` plays shield, hit,
  reeling, and relief clips; neither visual action alters the canonical relief
  or settlement rules.

## Reproduction and proof

Run:

```bash
/Applications/Blender.app/Contents/MacOS/Blender --background --factory-startup \
  --python models/scripts/build_pale_oath_characters_v1.py
```

The script validates that each output contains exactly one mesh, one skin, and
only its expected state clips. It also regenerates the non-runtime previews:

- `docs/assets/pale-oath-characters/barrow_jarl_v1.png`
- `docs/assets/pale-oath-characters/oathbound_v1.png`

`test_pale_oath_world.gd` verifies the production binding, one skeleton, one
skinned mesh, and every required imported Godot `AnimationPlayer` clip.

## Provenance and remaining scope

These are Blender-authored procedural assets, not Meshy output. No Meshy task
or credits were used. The deliberately low-poly single-mesh design is suitable
for the current top-down browser build; a future close-up/cinematic pass may
replace it with a higher-detail human-authored or separately authorized Meshy
family without changing the encounter scripts or clip vocabulary.
