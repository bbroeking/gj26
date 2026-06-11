# Meshy operations cookbook

Three concrete recipes for the things Meshy fills in for our pipeline. The
*rest* of the stack (sockets, animation layering, anim-notify timing, hit
detection, equipment swap) is engine/game code — see
[`PROP_ATTACHMENT.md`](./PROP_ATTACHMENT.md) for that side.

**What Meshy does well, for us:**

| Recipe | Meshy feature | Output |
|---|---|---|
| **A.** Texture a rigged body | AI Texturing (Text/Image → Texture) | Re-textured GLB, same rig + clips |
| **B.** Add a bow-draw animation clip | Animation Library on a rigged character | Rigged GLB with the new clip baked in |
| **C.** Generate a new prop mesh | Image-to-3D, Stylized preset, static rig | Single-mesh GLB ready for socket-attach |

Lessons baked in: Meshy's auto-rig strips textures, so you texture **after**
rigging, not before. The "Merged Animations" sidecar GLBs are degenerate
(empty skeleton, no mesh) — always grab the "with-skin" / "Character"
variant that has the body in it. Animation clip names come through in
`gltf.animations[].name` — keep them sensible so `find('draw')` / `find('walk')`
in the sandbox loader picks them up.

---

## Recipe A — Texture the rigged body (AI Texturing)

**Goal:** the body in the sandbox is grey because Meshy's animation export
strips textures. Re-texture the rigged GLB with the same character art.

**Steps:**

1. Open [meshy.ai](https://meshy.ai) and go to **AI Texturing** (sometimes
   labeled "Text to Texture" or "Image to Texture").
2. **Upload** `models/ranger_anim_v1.glb` (or whichever rigged body you're
   using — `ranger_sockets_v1.glb` works too; sockets are preserved through
   re-texturing).
3. **Reference image**: attach `docs/concept-art/archer-player.png` (or
   `ranger-stripped.png` for prop-stripped colors).
4. **Prompt** (short, factual — Meshy's texture model responds well to
   plain descriptions of colors/materials):
   ```
   chibi fairytale forest archer, messy chestnut hair, cream off-white
   tunic, dark moss-green shorts, soft brown leather boots, leather belt
   with small pouches, fair skin with rosy cheeks, big dark green eyes,
   Wind Waker cel-shaded storybook look
   ```
5. **Settings:** Style = Stylized · PBR maps = yes (gives normal/roughness
   for nicer toon shading) · Resolution = 2K (1K is fine if the credit
   budget matters).
6. Generate. ~2–5 minutes. Preview rotates the textured mesh; reroll if a
   region looks wrong (typically face / hair seams).
7. **Download as GLB** → save to `~/Downloads/`.
8. Drop it in the project:
   ```bash
   cp ~/Downloads/<file>.glb models/ranger_anim_v1_textured.glb
   ```
9. In `rig_test.html`, change `BODY_URL` to the new path (one line), or
   tell me the filename and I'll swap it in plus rebuild the
   `ranger_sockets_v1.glb` socket variant on top of the textured body.

**Common failure:** Meshy returns a textured GLB but the **rig is gone**
(materials swapped in lost the skeleton). If that happens, the texture is
salvageable — extract the diffuse image from the textured GLB and assign it
to the rigged GLB's material in Blender (one-shot script, ~5 min — say the
word and I'll do it).

---

## Recipe B — Add a bow-draw animation clip

**Goal:** the body needs a real "pull bow back, hold, release" clip on top
of the existing Walking/Running. The sandbox's X-press flow already has the
state machine — it just needs the clip to crossfade.

**Steps (Meshy):**

1. Open the rigged character in Meshy (the same Tiny Wanderer rig — Meshy
   keeps the auto-rig task linked to your account).
2. Open the **Animation Library** panel for that character.
3. Search for: **archer / draw bow / aim / shoot bow / pull arrow.** Meshy's
   library is smaller than Mixamo's — if a "draw bow" doesn't appear, try
   "aim", "ranged attack", or "two-handed pull".
4. If found:
   - Apply it. Preview the clip; check the rig holds the pose (no broken
     elbow/shoulder twists — Meshy's library sometimes mis-retargets).
   - **Name the clip** `draw` (or note Meshy's name — `find('draw')` in
     the sandbox matches any clip whose lowercase name contains "draw").
   - **Add a second clip** for release/recoil if available — `release`,
     `recoil`, `loose arrow`. Otherwise the sandbox just snaps from AIM
     back to STOW (fine — the arrow flying covers the moment).
   - **Export** the character with all clips merged. Make sure the export
     dialog says "with skin" — not the bare "armature + animation" sidecar.
   - Download → `~/Downloads/<file>.glb`.
5. Tell me the filename. I'll:
   - replace `BODY_URL` in `rig_test.html`,
   - rebuild the socket variant (`ranger_sockets_v1.glb`) on top of it,
   - wire the draw clip into the DRAW state (`mixer.crossFadeTo(drawAction)` —
     additive blend so the legs keep walking),
   - swap the placeholder `bow.t`-against-`NOCK_AT` notify-fake for
     `drawAction.time`-against-the-clip's-nock-time.

**Fallback — Mixamo (if Meshy's library doesn't have a draw clip):**

1. Go to [mixamo.com](https://mixamo.com) (Adobe account, free).
2. **Upload Character** → drop `models/ranger_anim_v1.glb`. Mixamo
   auto-retargets the rig (it'll re-name bones to Mixamo standards —
   `mixamorig:LeftHand` etc. — that's fine, the sandbox finds bones by
   `endsWith('LeftHand')`).
3. Search for **"Standing Draw Arrow"** and **"Standing Aim Recoil Arrow"**
   (or "Standing Aim Overdraw" for a hold variant).
4. For each clip: enable **"In Place"** so the character doesn't drift
   forward. Format = **glTF 2.0 binary (.glb)**. Skin = "With Skin" for the
   first download, "Without Skin" for subsequent (so you don't have
   duplicate meshes).
5. You'll end up with one or two GLBs — `Ranger_DrawArrow.glb`,
   `Ranger_AimRecoil.glb`. Drop them in `~/Downloads/`.
6. Tell me the filenames. I'll merge the clips into the body GLB (Blender
   script — import each, copy the action, assign to the same armature,
   re-export) and wire them up.

---

## Recipe C — Generate a new prop mesh

**Goal:** add another bow / sword / shield / quiver / cloak / etc. that
attaches to a socket.

**Steps:**

1. Have a reference image: either a Midjourney/ChatGPT generation (see
   `docs/concept-art/ranger-props/PROMPTS.md` for the style stem) or a
   crop from an existing concept-art PNG.
2. Meshy → **Image to 3D** (not Text to 3D — concept art carries detail
   that prompts can't recover).
3. Upload the image. Settings:
   - **Art style:** Stylized (cartoon-friendly topology).
   - **Symmetry:** Auto for bilateral things (bow, shield), Off for
     asymmetric (quiver with strap, cloak).
   - **Topology:** Tri.
   - **Texture:** Yes, with PBR (we strip these on cleanup but useful to
     have for reference).
   - **Polygon count:** ~3–5k for a small prop (arrow), ~5–10k for a
     medium prop (bow, quiver, sword), ~10–15k for a large/draped prop
     (cloak, banner). Lower is fine — we re-decimate in cleanup.
4. Generate. Re-roll if the silhouette is wrong (2nd–3rd seed often hits).
5. **Refine** once the base looks right.
6. Download GLB → `~/Downloads/`.
7. Run the cleanup script:
   ```bash
   cd /Users/bbroeking/projects/gj26
   /Applications/Blender.app/Contents/MacOS/Blender --background \
     --python scripts/clean_ai_mesh.py -- \
     --input "$HOME/Downloads/<file>.glb" \
     --name "prop_<name>_v1" \
     --rig static \
     --tris 6000          # 3000 for arrow, 8000 for quiver/sword, 10000 for cloak
   ```
   This welds the confetti mesh, decimates, normalizes, and saves
   `models/prop_<name>_v1.glb`.
8. Add it to the sandbox (one-line edits to `PROP_URLS` + `PROP_SIZE` in
   `rig_test.html`):
   ```js
   const PROP_URLS = { ..., sword:'models/prop_sword_v1.glb' };
   const PROP_SIZE = { ..., sword: 0.9 };
   ```
9. To equip it: parent to the right socket — for a sword on the hip you'd
   add a `socket_hip_R` empty in Blender (see PROP_ATTACHMENT.md), then
   `socket.add(propWrap)` like the other props.

---

## Where everything lives

```
models/
  ranger_anim_v1.glb              ← the rigged body from Meshy (current sandbox default)
  ranger_sockets_v1.glb           ← body + socket empties added in Blender
  prop_bow_v1.glb / prop_arrow_v1.glb / prop_quiver_v1.glb   ← static props
  prop_<new>_v1.glb               ← drop new ones here

docs/concept-art/
  archer-player.png               ← master character reference
  ranger-props/                   ← prop concept images + PROMPTS.md
  <category>-<name>.png           ← all other concept art (NPCs, enemies, items, landmarks)

scripts/
  clean_ai_mesh.py                ← weld + decimate + rig wrap for Meshy outputs
  register_ai_character.py        ← register a model in codex.html for previewing
```

## When you're done

For each recipe, the deliverable to me is the filename(s) you downloaded.
I handle: cleanup (already scripted), Blender socket pass, sandbox wiring,
and the engine-side hook-up (animation layering, notify timing, projectile
spawn). The two pieces converge in the sandbox at
`http://127.0.0.1:8765/rig_test.html`.

## Godot import (spec 07 — dual-engine asset model)

The Meshy → `clean_ai_mesh.py` → `models/<name>_v1.glb` pipeline is
unchanged. The Godot evaluation project at `godot/` reads the same files
via a symlink (`godot/models -> ../models`), so one GLB serves both
engines.

When you add a new GLB:

1. Run the existing pipeline. The file lands at `models/<name>_v1.glb`.
2. **three.js** — same as today: add a `loadFooGLB` + `buildFooMesh` in
   `src/scene/characters.js`, a `spawnFoo` in `src/game/enemies.js`, and
   wire it through `src/main.js`.
3. **Godot** — open the editor (`godot --editor --path godot`). It
   auto-imports the new file and creates a `models/<name>_v1.glb.import`
   sidecar. Commit the sidecar. The model is now usable as
   `res://models/<name>_v1.glb` in any GDScript or scene.

No duplicate copies of GLBs anywhere. See `docs/GODOT_PIPELINE.md` for the
broader workflow.

## Rig + animate via the Meshy API (spec 11)

The Meshy MCP (`@meshy-ai/meshy-mcp-server`, needs `MESHY_API_KEY`) can
auto-rig + animate characters for Godot's `AnimationPlayer`. Hard-won facts:

- **Meshy auto-rig only rigs Meshy-native t-pose generations.** Feeding it a
  `clean_ai_mesh.py` low-poly GLB fails with "Pose estimation failed" — every
  time, even for an obviously humanoid mesh. The model must be generated by
  `meshy_image_to_3d` / `meshy_text_to_3d` with `pose_mode="t-pose"`.
- **Meshy 6 meshes are dense** (300K–1.4M faces). The rig API caps at 300K —
  run `meshy_remesh` (target ~50K) first.
- **Rigging is humanoid-only.** Quadrupeds fail pose estimation. The crypt
  rat could not be rigged; it stays a static GLB.
- **Rigging includes walk + run free** (5 credits). `meshy_animate`
  (3 credits) adds a custom clip — `action_id: 0` is the basic Idle. The full
  action list is the Meshy "Animation Library Reference" doc.
- The animation task downloads as `Animation_<Name>_withSkin.glb` — a
  complete rigged+animated GLB. Save it as `models/<name>_rigged.glb`.
- Cost reality (spec 11, Meshy 6): generation ≈ 29 credits/model (not the
  ~20 advertised). Budget accordingly.

The `_rigged.glb` files live alongside the static `_v1` GLBs; the three.js
game keeps using `_v1` (procedural animation), Godot prefers `_rigged`.
