# Game Character Animation Playbook

A condensed, game-focused reference for taking a 3D character from generation → rigged → animated → exported. Optimized for stylized, low-poly, three.js / Unity / Unreal targets, generated or refined via Claude + Blender (MCP).

---

## 1. End-to-end pipeline

```
[Generate or model]  →  [Clean mesh]  →  [UV + material]  →  [Rig]  →  [Animate]  →  [Bake]  →  [Export glTF]
   Claude/MCP            quads, scale       handpaint or       Rigify     Mixamo / mocap     Actions     glb with
   tripo/sloyd           non-manifold       PBR-ORM             meta-rig    + keyframes        + NLA       multiple clips
```

Aim: produce a `.glb` with named animation clips (`idle`, `walk`, `run`, `attack`, `death`) and clean topology that deforms without tearing.

---

## 2. Model quality — what matters for animation

| Concern | Rule | Why |
|---|---|---|
| **Topology** | Quads, edge loops around joints | Quads bend predictably; loops at elbows/knees/shoulders/hips prevent collapse during deformation |
| **Poly budget** | 3k–15k tris for stylized hero; 500–2k for crowd | Lower = faster animation eval and engine perf |
| **Manifold geometry** | No holes, no inverted normals, no overlapping faces | AI-generated meshes (Tripo, Sloyd, etc.) commonly violate this — fix in Blender first |
| **Scale + origin** | Apply scale (Ctrl+A → Scale), origin at feet, +Z up, facing -Y | Engines/IK solvers misbehave with un-applied transforms |
| **Symmetry** | Mirror modifier during modeling, keep symmetric vertex groups | Lets you weight-paint half and mirror; lets engines apply IK mirroring |
| **UVs** | Smart UV Project as fallback; manual seams along hidden edges | Bad UVs = stretching that's amplified by deformation |
| **Materials** | One material per logical body part, packed glTF (ORM = AO/Roughness/Metallic in RGB) | three.js / glTF expects packed channels; reduces texture count |

### Common AI-mesh fixes (in order)
1. **Decimate** modifier or remesh to drop poly count
2. **Merge by distance** (Mesh → Clean Up → Merge by Distance)
3. **Fill holes** (Select Non-Manifold → F)
4. **Recalculate normals** (Shift+N)
5. **Remove doubles + inverted faces**
6. **Re-UV** with Smart UV Project
7. **Apply scale** (Ctrl+A)

---

## 3. Rigging — the Rigify path (recommended default)

1. Enable Rigify: Edit → Preferences → Add-ons → search "Rigify" → enable.
2. `Shift+A` → Armature → Human Meta-Rig (or Quadruped, Bird, etc.).
3. **Edit Mode**: align meta-rig bones to your mesh. Match joint pivots exactly. Keep symmetry (`X-Axis Mirror`).
4. Generate rig: select meta-rig → Properties → Armature → Rigify → "Generate Rig". Produces a control rig with FK/IK switches, IK targets, foot rolls, finger curls.
5. **Parent mesh to rig**: select mesh, shift-select rig, `Ctrl+P` → "With Automatic Weights".
6. **Weight paint** to fix obvious issues (armpits, hips, where the mesh tears in Pose Mode).

### FK vs IK cheat sheet

| Use FK when | Use IK when |
|---|---|
| Free arcs, waving, gestural motion | Foot planted on ground (always) |
| Spine / head / fingers | Hand on object, weapon, hip |
| Tail flicks, hair flowing | Climbing, pushing, contact poses |

Rigify ships both per limb — flip via the rig UI.

---

## 4. Animation techniques (ranked by game utility)

| Technique | Best for | Cost | Game-engine friendly? |
|---|---|---|---|
| **Mixamo retarget** | Humanoid base motions (walk/run/idle/attack) | Free | Yes — bake then export |
| **AI mocap** (DeepMotion, Rokoko Vision) | Custom motions from phone video | Freemium | Yes |
| **Manual keyframing** | Hero animations, stylized exaggeration | Time | Yes |
| **Shape keys** | Facial expressions, blink, viseme/lip-sync | Medium | Yes — glTF supports morph targets |
| **NLA strips** | Combining `walk` + `aim_up` as layered clips | Low | Bake before export |
| **Drivers** | Wheel rotation tied to forward velocity, eye-look targets | Low | Bake before export |
| **Constraints** | Cleanup (foot lock, look-at) | Low | Bake before export |
| **Physics sims** | Capes, hair, secondary motion | High | Bake to keyframes |
| **Geometry Nodes** | Procedural crowd / scatter | High | Limited engine support — bake to mesh |

---

## 5. Game-bound animation rules

- **One Action per clip.** Name them `idle`, `walk_loop`, `run_loop`, `attack_01`, `death`.
- **Loops must loop.** First frame = last frame for cyclical clips. Use Graph Editor → Cyclic extrapolation while authoring.
- **Bake before export.** Object → Animation → Bake Action. Apply Visual Keying. Removes constraints/IK/drivers from export — engines only understand sampled bone transforms.
- **Push each Action to NLA** as a separate strip with the clip name. glTF exporter pulls names from NLA strips.
- **Root motion**: keep on hips bone, not on the root, if the engine handles displacement separately. Otherwise put it on the root and zero out hip XZ.
- **30 fps for engines** unless you have a reason. Set in Output Properties.
- **Keep armature small**: Rigify generates a *lot* of helper bones — only export the deform bones (use the "Deform Bones Only" setting in glTF exporter, or manually flag).

---

## 6. Export — glTF/glb checklist

Before File → Export → glTF 2.0:
- [ ] Apply scale on mesh (Ctrl+A)
- [ ] Bake all Actions, Visual Keying on
- [ ] Each clip pushed down as NLA strip, named
- [ ] Materials use Principled BSDF only (glTF understands this; complex node trees won't transfer)
- [ ] Textures packed (ORM channel layout if PBR)
- [ ] Mesh has only Deform armature modifier
- [ ] Origin at character's feet, facing -Y, +Z up

Export options:
- Format: **glb** (binary, single file)
- Include: **Selected Objects** (avoid exporting the meta-rig, lights, camera)
- Transform: **+Y Up**
- Geometry: **Apply Modifiers** off if you have shape keys; on otherwise
- Animation: **Use Current Frame** off, **NLA Strips** on, **Sampling Rate** = 1
- Skinning: **Deform Bones Only** on

Verify with `gltf-viewer` or three.js editor before shipping.

---

## 7. Beginner plan — 4 weekends to a working character

| Week | Goal | Deliverable |
|---|---|---|
| 1 | Keyframe fundamentals | 5-second bouncing ball with squash/stretch + ease curves |
| 2 | Armatures + skinning | Worm or arm that bends without mesh tearing; weight-paint cleanup |
| 3 | Rigify a humanoid | Claude-generated character rigged with Human Meta-Rig, posed in 3 keyframed poses (idle/run/jump) |
| 4 | Mixamo + export | Same character with 3 named clips (`idle`, `walk`, `attack`) playing in three.js or Babylon viewer |

**Stretch goals** (after week 4): shape keys for facial expressions, one custom DeepMotion-captured animation, drivers for procedural eye-look, physics-sim cape baked to keyframes.

---

## 8. Working with Claude + Blender MCP

When asking Claude to drive Blender, the prompts that produce the best animated characters:

- **Be explicit about poly budget**: "≤8k tris, quads only where possible, no n-gons."
- **Ask for clean topology**: "Add edge loops at every joint pivot before parenting to the rig."
- **Specify pivot/orientation**: "Origin at feet, +Z up, facing -Y, scale applied."
- **Request named outputs**: "Bake actions named `idle`, `walk_loop`, `attack_01`. Push each to NLA. Export `character.glb`."
- **Verify with screenshots**: ask Claude to use `render_viewport_to_path` after each major step (after rig, after first Action) so you can spot weight-paint issues early.

**Pitfalls** (from the bundled `blender-stylized-game-assets` skill):
- Operators depend on mode (Object/Edit/Pose) — Claude must set mode before calling
- Active object ≠ selection — must set both
- Update depsgraph before reading computed properties
- bmesh in Edit Mode, not direct mesh API

---

## 9. Tools cheat sheet

| Need | Tool | Free? |
|---|---|---|
| Auto-rig humanoid | Rigify (built into Blender) | Yes |
| Auto-rig anything (paid) | Auto-Rig Pro | No |
| Free motion library | Mixamo | Yes |
| Video → mocap | DeepMotion, Rokoko Vision | Freemium |
| Real-time mocap (phone) | Rokoko Vision | Freemium |
| Retarget Mixamo → Rigify | Auto-Rig Pro retarget, or `Rokoko Studio Live` add-on | Mixed |
| Stylized hand-paint | Blender Texture Paint, Substance 3D Painter | Mixed |
| glTF viewer | three.js editor, gltf-viewer.donmccurdy.com | Yes |
| Inspect/optimize glb | gltf-transform CLI | Yes |

---

## 10. References

- Blender Manual — [Animation & Rigging](https://docs.blender.org/manual/en/latest/animation/index.html), [glTF 2.0 export](https://docs.blender.org/manual/en/latest/addons/import_export/scene_gltf2.html)
- CGCookie — [Art of Good Topology](https://cgcookie.com/posts/the-art-of-good-topology-blender), [Fundamentals of Rigging](https://cgcookie.com/courses/learn-how-to-rig-anything-in-blender-fundamentals-of-rigging)
- CGDive — [Rig Anything with Rigify](https://cgdive.com/easy-rigging-in-blender-with-rigify-armature-basics/)
- Khronos — [Art Pipeline for glTF](https://www.khronos.org/blog/art-pipeline-for-gltf)
- Sloyd.ai — [7 Best Practices for AI-Generated 3D Models](https://www.sloyd.ai/blog/7-best-practices-for-ai-generated-3d-models-in-game-development)
- Katsbits — [Optimising AI Generated 3D Models](https://www.katsbits.com/codex/optimising-ai-generated-3d-models/)
- RebusFarm — [Mixamo Blender beginner guide](https://rebusfarm.net/blog/how-to-use-mixamo-with-blender-full-beginner-guide)
- DeepMotion — [Blender integration](https://www.deepmotion.com/companion-tools/blender)
- ahujasid — [blender-mcp](https://github.com/ahujasid/blender-mcp)
- funwithtriangles — [Blender to three.js export guide](https://github.com/funwithtriangles/blender-to-threejs-export-guide)
