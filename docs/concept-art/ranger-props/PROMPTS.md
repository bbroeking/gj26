# Ranger prop-set — Midjourney prompts → Meshy

Goal: take the Mosscloak Ranger and split it into **separable assets** —
a prop-stripped body + the bow, arrow, quiver, and cloak as standalone
models. Each gets a Midjourney concept image (saved in this folder), then
Meshy image-to-3Ds it. Final cleaned GLBs land in `models/`.

Pipeline per asset:  **MJ prompt → save PNG here → Meshy Image-to-3D
(Stylized, Tri, ~10k polys) → `scripts/clean_ai_mesh.py` → `models/`.**

Save Midjourney outputs in this folder with these exact filenames so the
sandbox / scripts can find them.

**Master reference: `../archer-player.png`** — that's the Mosscloak Ranger
(chibi forest archer, messy brown hair, mossy green cloak, bow in the left
hand, quiver on the back, leather pouches). Use it two ways:
- As Midjourney `--cref ../archer-player.png` on the **stripped body**
  prompt below — keeps the character identity while the prompt strips the
  props.
- The bow / quiver / cloak are all clearly visible in it — you can just
  **crop a close-up of each prop straight out of `archer-player.png`** and
  feed that crop to Meshy Image-to-3D. Often cleaner than a fresh MJ gen,
  and guaranteed to match the character. (Fresh MJ prompts below are the
  fallback if a crop is too small / occluded.)

Prompts are in code blocks below so they copy-paste clean — grab the whole
block, paste into Midjourney.

---

## 1. `ranger-stripped.png` — the body, no props  ✅ DONE

The Ranger with **empty hands, no bow, no quiver, no cape** — the figure in
its tunic, A-pose, clean for rigging and Image-to-3D. Current image saved
in this folder. Prompt used (keep for re-rolls):

```
chunky low-poly stylized fairytale forest archer, a small round-faced young ranger with messy chestnut hair, big simple dot eyes, wearing a cream off-white tunic, dark short trousers, oversized soft brown leather boots, and a thin leather belt with small pouches — EMPTY HANDS, no bow, no arrows, no quiver, no cape, no cloak, no hood — standing in a clean relaxed A-pose with arms held about 35 degrees away from the body, palms forward, feet shoulder-width apart, full body head to toe with a small margin, straight-on front view, plain flat pale-grey studio background, soft even shadowless lighting, Wind Waker cel-shaded storybook look with a slightly felted hand-crafted texture, soft chunky rounded shapes, clean character turnaround reference, centered --ar 3:4 --cref ../archer-player.png --cw 80 --no bow, arrow, arrows, quiver, cape, cloak, hood, weapon, staff, background scenery, props, text, logo
```

`--cw 80` keeps face/proportions/palette from the original but lets the
A-pose + prop-stripping override; drop to ~50 if it clings to the old
cloak/bow. For a multi-view Meshy input, regenerate as a 3-panel
front/side/back sheet.

Notes for Meshy: Symmetry **Auto**, Tri topology, ~10k polys, "Yes with
PBR" texture. Then `clean_ai_mesh.py --rig biped` (it'll re-rig with the
29-bone UniRig). Add sockets per `docs/character-pipeline/PROP_ATTACHMENT.md`.

---

## 2. `prop-ranger-bow.png` — the bow  (bramble-thorn ARCHERY bow)  ✅ DONE

⚠️ The word "bow" alone makes Midjourney draw a ribbon/gift bow. The prompt
below hammers that it's an **archery weapon — a longbow you shoot arrows
with** — and excludes ribbon/bow-tie shapes. Design: a longbow whose stave
is woven from dark twisted bramble vines, on-theme for Bramblewood.

```
a single archery longbow, the kind a forest archer holds to shoot arrows — a tall curved wooden bowstave with a taut bowstring running tip to tip — the stave is made of dark twisted BRAMBLE vines, several knotted thorny branches braided together into the longbow shape, a few sharp thorns and two small red berries clinging to it, a rough wrapped-cord grip in the middle, gnarled organic silhouette, chunky low-poly stylized fairytale game weapon prop, one object only, clean side profile so the full curve and string are visible, plain flat neutral grey background, Wind Waker cel-shaded look, soft chunky shapes, centered, even soft lighting --ar 1:1 --no ribbon, bow tie, gift bow, hair bow, decorative bow, knot, ribbons, character, person, hands, arrows, quiver, full bush, dense foliage, background scenery
```

If it STILL draws a ribbon: lead the prompt with the word "weapon" —
"an archery weapon, a wooden longbow and bowstring..." — and add
"NOT a ribbon, NOT a bow tie" to the start. If MJ buries the longbow in a
thornbush instead, add "clear readable longbow shape, sparse thorns, the
curve and string are obvious".

Meshy: Symmetry Auto, Tri, ~6–10k polys. `clean_ai_mesh.py --rig static`.
Origin should end up at the grip — set in Blender after import so it sits
in `socket_hand_L` cleanly. (Optional: match the arrow to it — a
thorn-tipped bramble arrow with a leaf fletching.)

---

## 3. `prop-ranger-arrow.png` — a single arrow  (matches the bramble bow)  ✅ DONE

```
a single archery arrow, the kind shot from a longbow — a straight slender wooden shaft, three small green leaf-shaped fletchings at the nock end, a simple tapered dark thorn-like arrowhead, a tiny bramble-vine wrap near the head, chunky low-poly stylized fairytale game weapon prop, one object only, clean horizontal side profile so the whole arrow is visible end to end, plain flat neutral grey background, Wind Waker cel-shaded look, soft chunky shapes, centered --ar 16:9 --no ribbon, bow, longbow, character, hands, quiver, multiple arrows, background scenery
```

Meshy: Tri, low poly (~3–5k is plenty). `clean_ai_mesh.py --rig static`.
Origin at the nock end (back), shaft pointing +X — that's what the bow
state machine assumes when parenting to `socket_hand_R`.

---

## 4. `prop-ranger-quiver.png` — the quiver  ✅ DONE

```
chunky low-poly stylized fairytale quiver, woven russet leather cylinder with a buckled strap, a few feathered arrow ends poking out of the top, cozy storybook game prop, one object only, three-quarter view, plain flat neutral grey background, Wind Waker cel-shaded look, soft chunky shapes, centered, even soft lighting --ar 3:4 --no character, person, hands, bow, background scenery
```

Meshy: Symmetry Off, Tri, ~5–8k polys. `clean_ai_mesh.py --rig static`.
Parents to `socket_quiver` (chest/upper-back bone). The visible arrows in
the top can be part of this mesh, or separate `arrow.glb` instances
positioned by the spawn code — either works.

---

## 5. `prop-ranger-cloak.png` — the hooded cloak / cape  ✅ DONE

```
chunky low-poly stylized fairytale hooded cloak, moss-green wool with a torn ragged hem and a carved-leaf clasp at the throat, draped as if worn by an invisible figure, hood down on the shoulders, cozy storybook game prop, one object only, three-quarter back view, plain flat neutral grey background, Wind Waker cel-shaded look, soft chunky shapes, centered --ar 3:4 --no character, person, face, body, bow, quiver, background scenery
```

Meshy: Symmetry Auto, Tri, ~6–10k polys. `clean_ai_mesh.py --rig static`
for now (rigid-parent to `socket_cape`). Later: add a 2–3 bone vertical
chain in Blender for secondary swing — see PROP_ATTACHMENT.md "needed to
finish".

---

## 6. `ranger-face-atlas.png` — the expression sprite sheet  ✅ DONE

NOT a Meshy asset. This is a flat **sprite sheet** of the Ranger's face in
different expressions; the game shows one cell at a time on a "face quad"
(a flat rectangle parented to the head bone — see PROP_ATTACHMENT.md
`socket_face`). No mesh deformation; expression = which sub-rect of this
PNG is displayed.

Cell layout (the engine code assumes this exact order):
```
Row 0:   neutral  |  happy   |  sad      |  angry
Row 1:   surprised |  blink  |  talk-A   |  talk-O
```

**Prompt A — ChatGPT / GPT-image** (attach `ranger-stripped.png` or
`../archer-player.png` to the message):
```
Using the chibi forest-archer character in the attached image as the reference, create ONE single image: a clean expression sheet of just this character's HEAD/FACE, arranged in a 4-column by 2-row grid on a plain flat white background. All 8 cells must show the exact same head at the exact same size, scale, crop, and angle (straight-on front view) — only the facial expression changes between cells. The 8 expressions, in this order, left to right, top row then bottom row: 1) neutral calm, 2) happy big warm smile with slightly squinted eyes, 3) sad downturned mouth and drooping brows, 4) angry brows angled down and a frowning mouth, 5) surprised with wide round eyes and a small open "o" mouth and raised brows, 6) eyes closed and relaxed (a blink frame), 7) talking with the mouth open in a relaxed oval ("ah"), 8) talking with the mouth in a small round shape ("oh"). Keep the same chunky low-poly storybook Wind Waker cel-shaded style, the messy chestnut hair, and the big simple eyes. No body or shoulders below the neck, no text or labels, no borders or lines between cells — just the 8 faces evenly spaced on a white background.
```

**Prompt B — Midjourney** (looser grid; good for style/character check):
```
chibi forest archer character expression sheet, the same round-faced young ranger with messy chestnut hair and big simple dot eyes, his HEAD only shown eight times in a clean 4-by-2 grid on a plain flat white background, every head identical in size scale crop and straight-on front angle, only the facial expression changing between them — neutral calm, happy big smile, sad, angry, surprised wide round eyes, eyes closed blinking, mouth open saying ah, mouth open saying oh — chunky low-poly stylized fairytale Wind Waker cel-shaded look, soft chunky shapes, even soft lighting, no body, no shoulders, no labels, no borders --ar 2:1 --cref ../ranger-stripped.png --cw 90 --no body, shoulders, neck below, text, labels, captions, grid lines, borders, frames, background scenery
```

If the generated grid is uneven (heads different sizes / off the cells),
generate/crop the 8 faces individually as `face-neutral.png`,
`face-happy.png`, `face-sad.png`, `face-angry.png`, `face-surprised.png`,
`face-blink.png`, `face-talkA.png`, `face-talkO.png` in this folder — a
packing script will tile them into `ranger-face-atlas.png`.

How the engine uses it (texture-swap):

```js
// faceMat.map = the atlas texture
const COLS = 4, ROWS = 2;
function setExpression(col, row) {
  faceMat.map.repeat.set(1/COLS, 1/ROWS);
  faceMat.map.offset.set(col/COLS, 1 - (row+1)/ROWS);
}
// blink: every 3–5s, setExpression(blinkCol,blinkRow) for ~100ms then back
// talking: while a line plays, alternate the two mouth-open cells ~8 Hz
```

---

## After all six exist

1. Drop the PNGs in this folder with the names above.
2. Run the five mesh assets through Meshy → download GLBs →
   `clean_ai_mesh.py` → `models/`. Suggested names: `npc_ranger_body_v1.glb`,
   `prop_bow_v1.glb`, `prop_arrow_v1.glb`, `prop_quiver_v1.glb`,
   `prop_cloak_v1.glb`. (The face atlas is a PNG, not a GLB — it goes
   straight to the game as a texture.)
3. Re-run the Blender socket pass on `npc_ranger_body_v1.glb` (it'll have
   the 29-bone rig from clean_ai_mesh) — add `socket_hand_L/R`, `socket_back`,
   `socket_quiver`, `socket_cape`, `socket_face` → `npc_ranger_body_v1_sockets.glb`.
4. In `rig_test.html`: swap the placeholder prop factories
   (`makeBowPlaceholder` etc.) for `GLTFLoader.load('models/prop_bow_v1.glb')`,
   add the face quad + `setExpression`, re-tune the `TUNE` table.
5. Mixamo round-trip the body for idle/walk/run/bow_draw/bow_release clips.
6. Port the state machine + expression system into the game's player code.
