# Prop Attachment & Action Sequences (sockets, bow-draw flow)

How separable props (bow, arrow, quiver, cape) get attached to a rigged
character via **bone sockets**, and how a multi-step action like "draw bow
and fire" is orchestrated on top of skeletal animation.

Companion to `AI_WORKFLOW.md` (mesh generation) and the sandbox at
`/rig_test.html`.

---

## Core idea: sockets

A prop is a *child of a bone* in the scene graph. When the bone animates,
the prop rides along — that's how every engine does held weapons, hats,
backpacks. We add **named empty objects** ("sockets") parented to bones, so
code attaches props by socket name and the per-prop offset survives
re-export. (This is Unreal "sockets" / Unity "attachment points".)

### Socket table (Meshy `UniRigArmature`, 29-bone `Bone_NNN` rig)

Derived from rest-pose bone positions. Left-arm chain runs outward
`Bone_020(shoulder)→019→018→017(wrist)→016(hand)→015→014`; right arm
mirrors `Bone_027→026→025→024→023(hand)→022→021`; spine is
`Bone_000(pelvis)→003→002→001(chest)→013(neck)→012(head)`.

| Socket | Parent bone | Holds |
|---|---|---|
| `socket_hand_L` | `Bone_016` (left hand) | bow when drawn |
| `socket_hand_R` | `Bone_023` (right hand) | arrow when nocked |
| `socket_back`   | `Bone_002` (upper spine) | bow when stowed |
| `socket_quiver` | `Bone_001` (chest/upper back) | quiver (always) |
| `socket_cape`   | `Bone_002` (upper spine) | cape root |

For a Mixamo-named rig the bones would be `LeftHand` / `RightHand` /
`Spine2` / `Spine1` etc. — same five sockets, different parent names.

---

## Stage A — asset prep (Blender, via MCP)

### A1. The props must be separate GLBs

A Meshy character export is **one merged mesh, no materials, ~17k unwelded
fragments** — you cannot surgically select the bow/quiver/cape out of it.
Two options:

- **Clean re-gen (preferred):** generate the base character in Meshy
  *without* props ("hooded archer, simple tunic, empty hands, no cape").
  Generate `bow.glb`, `arrow.glb`, `quiver.glb` as their own Meshy assets
  (simple shapes — fine for Meshy). Model/gen the cape separately, ideally
  with a 2-3 bone vertical chain for secondary motion.
- **Surgical extraction (painful):** weld the mesh first
  (`remove_doubles`), then hand-select the prop faces in Edit Mode,
  `P → Separate by Selection`, clear skin weights on each piece, re-export.
  Only worth it if you can't re-gen.

### A2. Weld + add sockets + re-export

The MCP script that produced `models/npc_rigged_test_v2.glb`:

1. Import the rigged GLB
2. `bpy.ops.mesh.remove_doubles(threshold=0.0005)` on the mesh (53k → 9k
   verts here) + `normals_make_consistent`
3. For each socket: `e = bpy.data.objects.new(name, None)`,
   `e.parent = armature_obj`, `e.parent_type = 'BONE'`,
   `e.parent_bone = '<bone>'`, zero the local transform
4. `bpy.ops.export_scene.gltf(..., export_apply=False, export_skins=True,
   export_animations=False)` — `export_apply=False` keeps the Armature
   modifier so skinning survives

In the exported GLB the sockets become child nodes of their bone nodes
(glTF has no "bone parenting" concept — bones *are* nodes, sockets are
just children).

---

## Stage B — runtime attachment (JS)

At load (`rig_test.html` → `loadModel`):

```js
const SOCKET_NAMES = ['socket_hand_L','socket_hand_R','socket_back','socket_quiver','socket_cape'];
for (const sn of SOCKET_NAMES) {
  const o = gltf.scene.getObjectByName(sn);
  if (o) sockets[sn] = o;
}
// attach props
sockets.socket_back.add(bowMesh);     placeInSocket(bowMesh, 'socket_back');   // stowed
sockets.socket_quiver.add(quiverMesh); placeInSocket(quiverMesh, 'socket_quiver');
sockets.socket_cape.add(capeMesh);    placeInSocket(capeMesh, 'socket_cape');
```

`placeInSocket` applies a per-socket local transform from a `TUNE` table —
eyeballed once for the real prop GLBs, then constant. (The sandbox uses
placeholder shapes — colored boxes/cylinders standing in for the real
GLBs.)

After attachment the body's animation (clips via `AnimationMixer`, or the
procedural `rigged_walk.js`) drives the bones; sockets ride the bones;
props ride the sockets. Nothing else to do for normal locomotion.

---

## Stage C — the bow-draw action state machine

This is the part **no animation tool gives you** — Meshy/Mixamo provide
the body *clips*; the prop choreography is game code. State machine
(implemented in `rig_test.html` → `updateBow`):

```
STOW   ──F pressed──▶ DRAW          reparent bow: socket_back → socket_hand_L
                                    crossfade body clip → 'bow_draw'
DRAW   ──t≥30%──▶ (spawn arrow on socket_hand_R; decrement visible quiver)
DRAW   ──F released (mid-draw)──▶ STOW    cancel: remove arrow, bow → socket_back
DRAW   ──t≥100%──▶ AIM              hold last draw frame; player aims
AIM    ──F released──▶ RELEASE      detach arrow → projectile w/ velocity
                                    crossfade body clip → 'bow_release'
RELEASE──ends, F held──▶ DRAW       re-nock, rapid fire
RELEASE──ends, F up──▶ STOW         bow → socket_back; crossfade → locomotion
```

The flying arrow is a *fresh* `arrow.glb` instance spawned into the world
(or handed to the existing projectile/combat system); the nocked one in
the hand is destroyed. Tunables: `DRAW_TIME`, `RELEASE_TIME`, `NOCK_AT`.

This mirrors the existing `triggerAttack` windup→strike→recover phases in
`src/anim/knight.js` — just more steps + prop reparenting.

---

## Where each tool fits

- **Meshy** — generates the *meshes* only (body, bow, arrow, quiver). Does
  not parent, sequence, or know what a quiver is. Note: Meshy's
  *animation* export is currently broken for our characters — degenerate
  skeleton (all bones at origin), no mesh geometry. Don't rely on it for
  clips yet.
- **Mixamo** — gives the *body clips*: "Standing Draw Arrow", "Standing
  Aim Recoil Arrow", "Standing Aim Overdraw". Upload a rigged body, apply,
  download with clips baked in. Mixamo renames bones to its standard —
  fine, just match those in the socket table.
- **Game code** — sockets, parenting, the state machine, prop
  spawn/destroy timing, the flying arrow. Always code, in every engine.

---

## Status & remaining prerequisites

Done:
- `models/npc_rigged_test_v2.glb` — welded + 5 sockets
- `rig_test.html` — loads v2, discovers sockets, attaches placeholder
  bow/quiver/cape, full draw→fire state machine, WASD movement, follow cam
- `src/anim/rigged_walk.js` — procedural bone walk (rough; placeholder
  until real clips exist)

Needed to finish:
1. **Clean rigged body GLB without baked props** (Meshy re-gen) + the
   prop GLBs (`bow.glb`, `arrow.glb`, `quiver.glb`, `cape.glb`)
2. **Body animation clips** — idle, walk, run, bow_draw, bow_release
   (Mixamo round-trip on the rigged body is the fastest route)
3. Re-tune the `TUNE` table for the real prop geometry
4. Port the state machine into the game's player/combat code; wire the
   released arrow into the projectile system
