# Wayfinder humanoid rig and equipment contract

Status: locked for the next character and gear batch (2026-07-17).

## Why this contract exists

Meshy can produce a good character and a usable animation rig, but independently
generated characters do not automatically share bone names, proportions, bind
poses, or equipment anchors. Swappable gear only works reliably when every
playable humanoid is normalized to one canonical skeleton before it reaches
Godot.

## Canonical skeleton

The current player body is the baseline. Its imported armature contains:

```text
Hips
├─ LeftUpLeg → LeftLeg → LeftFoot → LeftToeBase
├─ RightUpLeg → RightLeg → RightFoot → RightToeBase
└─ Spine02 → Spine01 → Spine
   ├─ LeftShoulder → LeftArm → LeftForeArm → LeftHand
   ├─ RightShoulder → RightArm → RightForeArm → RightHand
   └─ neck → Head → head_end / headfront
```

Future bodies must retain these names, hierarchy, rest pose, and scale. Blender
may append socket bones, but it must not rename or reorder the deform skeleton.
The existing walk/run sidecars remain the shared locomotion source.

## Socket bones

Append these non-deforming bones to the canonical Blender rig:

| Socket | Parent | Used by |
|---|---|---|
| `Socket_Hand_L` | `LeftHand` | bows, shields, lanterns |
| `Socket_Hand_R` | `RightHand` | tools, swords, held quest items |
| `Socket_Back` | `Spine` | quivers, backpacks, sheathed weapons |
| `Socket_Head` | `Head` | hats, helmets, masks |
| `Socket_Chest` | `Spine` | badges, rigid breastplates, amulets |
| `Socket_Hip_L` | `Hips` | satchels, potion belts |
| `Socket_Hip_R` | `Hips` | sheaths, tool loops |

Godot creates a `BoneAttachment3D` for each socket. A rigid item GLB is parented
under that attachment and keeps a small item-specific local transform. The live
bow already proves this pattern against `LeftHand`; authored socket bones remove
the remaining per-model guesswork.

Rigid items also own the other half of the contract: their object origin (or an
authoring-only `Grip` marker) sits at the actual contact point. For the shortbow,
Blender detects the moss-green wrap from its base-color texture and UVs, then
rebases the exported mesh so that point is local zero. A palm socket aligned to
a bounding-box-centered weapon is not a valid attachment.

The current Meshy skeleton has no finger bones. The Ranger therefore ships a
`BowGrip_L` blend shape for the closed left-hand silhouette; Godot activates it
when the model loads. Characters with articulated finger bones should use an
authored hand pose instead, but should keep the same socket + item-origin
contract.

## Two gear paths

Rigid gear does not need skinning. Hats, weapons, quivers, backpacks, belts,
amulets, and tools attach to a socket. This is the default because it is cheap,
stable, and easy to author.

Deforming gear does need skinning. Tunics, coats, gloves, trousers, and boots are
exported as separate meshes weighted to the exact canonical skeleton. In Godot,
their `MeshInstance3D.skeleton` points at the player's `Skeleton3D`. Each armor
piece also declares which base-body regions it hides so the body does not clip
through the clothing.

Recommended body masks:

```text
head, hair, torso, upper_arm_l, upper_arm_r,
forearm_l, forearm_r, hand_l, hand_r,
hips, thigh_l, thigh_r, calf_l, calf_r, foot_l, foot_r
```

## Meshy → Blender → Godot pipeline

1. Generate a neutral A-pose character in Meshy. Use Meshy rigging when it gives
   a cleaner organic deformation than procedural Blender work.
2. Import the result into the canonical Blender character file.
3. Retarget its weights to the canonical skeleton. Do not ship Meshy's private
   armature as a second gameplay skeleton.
4. Append and align the seven socket bones, apply transforms, and verify +Y up / 
   forward convention.
5. Test idle, walk, run, bow draw, gather swing, and roll with the shared
   animation sidecars.
6. Export one body GLB. Export each rigid item as its own origin-normalized GLB;
   export deforming armor as a same-skeleton skinned mesh.
7. In Godot, verify silhouette, clipping, hand placement, and attachment motion
   from the actual top-down camera before approving the asset.

## Asset data contract

Every visual item should carry data equivalent to:

```gdscript
{
  "model": "res://models/gear/wayfinder_quiver_v1.glb",
  "mode": "rigid",                 # rigid | skinned
  "socket": "Socket_Back",
  "offset": Vector3(0.0, 0.02, -0.08),
  "rotation_deg": Vector3(0, 180, 8),
  "scale": 1.0,
  "hide_regions": []
}
```

Skinned armor replaces `socket` with `skeleton_profile: "wayfinder_humanoid_v1"`
and supplies `hide_regions`.

## Acceptance gate

- No T-pose and no missing animation track.
- Held items stay in the hand through idle, walk, run, roll, and attack.
- Head/back/hip props do not jitter or inherit an unexpected scale.
- No visible body penetration from the gameplay camera.
- Character body GLB target: under 2 MB imported mesh data and one 512px texture
  for Web unless a close-up screen proves it needs more.
- Rigid item target: under 150 KB imported scene data and one 256–512px texture.
