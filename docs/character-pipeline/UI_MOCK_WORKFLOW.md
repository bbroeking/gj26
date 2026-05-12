# UI_MOCK_WORKFLOW.md

A 4-step lightweight workflow for mocking a character BEFORE any Blender
build. The goal: catch silhouette / palette / rig / animation problems on
a flat 2D pass that takes 15–30 minutes, not on a 3D rebuild that takes 2
hours and a half-dozen back-and-forth iterations.

This doc is dev-internal — we are not commissioning artist work. Outputs
are: one PNG silhouette, one palette card (markdown table is fine), one
animation card (text bullets), and one codex preview entry that wires the
finished GLB back to the concept for in-game A/B comparison.

Cross-references:
- `docs/UI_BIBLE.md` — UI tokens, frame-ink decoration, dialog patterns.
  The codex viewer follows these rules.
- `docs/ASSET_PIPELINE.md` — concept → model → game pipeline. This file
  is the BEFORE-Blender half.
- `docs/character-pipeline/MODEL_DESCRIPTION_TEMPLATE.md` — the
  filled-in proportions/parts/palette doc that closes the loop. The
  outputs from this workflow feed directly into that template.
- `CLAUDE.md` — design tokens live in `src/ui/tokens.css`; everything
  in the codex viewer should reuse them.

Project-specific surfaces this workflow touches:
- `codex.html` / `codex.js` — the in-browser model viewer (Bramblewood
  Codex). Has `MODEL_GROUPS` (which models to list) and
  `MODEL_OVERLAY_MAP` (which concept image to overlay over each model).
- `docs/concepts/` — concept art (input).
- `docs/character-pipeline/<name>.md` — model description (output of
  this workflow + filled-in MODEL_DESCRIPTION_TEMPLATE).

---

## Step 1: silhouette outline trace

**Why**: at NPC distance (~6m, 30° camera tilt), the player only reads
your character's silhouette. If two NPCs share a silhouette, no amount
of palette or facial detail recovers the difference. Silhouette is the
first thing to validate, before pixels are spent on color or geometry.

**How**:

1. Open the concept art in any image editor (Preview / Photopea /
   Affinity / Procreate / etc.).
2. Trace the OUTERMOST outline of the character as a single filled
   black shape on white. No internal lines, no clothing folds — just
   the silhouette boundary.
3. Scale to ~80px tall (matches in-game NPC pixel height roughly) and
   eyeball: would you recognize this character among the existing
   cast (Eldra / Hod / Cricket / Bramble Imp / Burrow Boar) at this
   size?
4. Save as `docs/concepts/<name>_silhouette.png`.

**Code-side alternative**: if no image editor is convenient, you can
trace in code via a flat orthographic render of a placeholder primitive
set. Author 6–8 boxes/spheres approximating the character's main
masses, render at orthographic 80px height with a flat black material
on a white background, screenshot. Same A/B test against existing cast.
This is faster than it sounds — the goal is a 5-minute placeholder, not
a finished build.

**Pass criteria**:
- Distinct from every existing NPC silhouette in current cast.
- One single dominant shape gesture (round / tall / hunched / wide).
- A signature feature visible at 80px (staff, hat, hump, antenna,
  basket — pick one and only one).

If the silhouette fails this gate, change the proportions / build /
signature prop in the concept art BEFORE moving on. The Blender build
won't fix it.

---

## Step 2: palette card

**Why**: the painted-vertex-color pipeline derives swatch palettes from
material `Base Color` directly. Picking the right 6–10 hexes upstream
saves an iteration cycle of "the vest reads pinkish, can we shift it
warmer?".

**How**:

1. Color-pick from the concept art. Avoid picking from the deepest
   shadow or the highest specular — pick from the mid-tone face of the
   surface, which is what a painted-flat material actually represents.
2. Group into Material slots. Convention: `<CharName>_<Slot>`. Slots
   tend to fall into these buckets:
   - structural skin/fur/scales (`_Skin`, `_Hair`, `_Fur`, `_Scales`)
   - primary garment (`_Tunic`, `_Coat`, `_Robe`, `_Cloak`)
   - secondary garment (`_Vest`, `_Apron`, `_Sash`)
   - leather/metal/wood accents (`_Leather`, `_Brass`, `_Tin`, `_Wood`)
   - emissive (`_Lantern`, `_Flame`, `_Crystal`)
3. Drop into the markdown palette table in
   `MODEL_DESCRIPTION_TEMPLATE.md` §3. That table IS the palette card —
   no separate file needed.

**Pass criteria**:
- 6–10 colors total. Fewer reads as flat; more reads as noisy.
- Saturation is mid-to-high. Painted style + bright toon gradient
  crushes desaturated colors to mud (CLAUDE.md notes this — toon
  gradient floor is intentionally bright at 200/255).
- One emissive material (if applicable) sits brighter than the rest of
  the palette, with `Base Color` chosen to match the unlit night
  reading and `Emission Color` slightly warmer.

---

## Step 3: animation card

**Why**: rig choice (biped vs quadruped vs custom) and prop attachment
points are decided here. Getting it wrong means re-parenting after
export.

**How**: a text-only card. No diagrams. Just bullets:

```
Idle:
  - body subtle bob
  - head idle look (yaw drift ±10°)
  - <prop> hangs from <hand/strap>; passive sway
Walk:
  - L/R legs alternate (procedural walk in src/anim)
  - opposite arm swing, ±25°
  - <prop> swings with arm
Work / interact:
  - which arm raises? to what height?
  - what does the head do? (nod, tilt, look at player)
```

Pin which empty drives which prop. For Eldra: staff parents to
`Arm_R`. For a basket-carrier: basket parents to `Body` (held in front
with both hands). For an axe-swinger: axe parents to `Arm_R` and the
work-pose adds an extra rotation to that empty.

**Pass criteria**:
- Rig layout decided: biped (`Body/Head/Arm_L/Arm_R/Leg_L/Leg_R`) OR
  quadruped (`Body/Head/Tail/Leg_FL/FR/BL/BR`) OR custom (rare —
  document deviation).
- Every prop has a parenting target named.
- Idle / walk / one work-or-interact pose each have ≤3 bullets.

---

## Step 4: codex preview entry

**Why**: once the GLB exists, the codex viewer (`codex.html` /
`codex.js`) lets you A/B-toggle between the concept art image and the
3D render. This is the closing-the-loop step — you confirm the build
matches the concept, not just abstractly looks "stylized".

**How**:

1. Drop the concept art into `docs/concepts/<name>.png` (already done
   in Step 1; just confirm the file is committed).
2. Add the new model to `MODEL_GROUPS` in `codex.js` under the right
   section (NPCs / enemies / props / etc.). Use the same display name
   as in `MODEL_DESCRIPTION_TEMPLATE.md` §1.
3. Add a `MODEL_OVERLAY_MAP` entry mapping the GLB filename to the
   concept image path:

   ```js
   MODEL_OVERLAY_MAP['models/npc_<name>_v<n>.glb'] =
     'docs/concepts/<name>.png';
   ```

4. Open `codex.html` in the browser, navigate to the model, click the
   overlay toggle. Confirm:
   - Proportions match (head:body ratio reads the same).
   - Palette matches (no surprise "vest is pink" moments).
   - Silhouette matches the Step 1 trace.

**Pass criteria** (codex A/B):
- 3D render and concept overlay align on head height, shoulder width,
  and signature-prop position.
- Palette swatches in the codex sidebar match the material table in
  `MODEL_DESCRIPTION_TEMPLATE.md` §3.
- The model description doc, the concept PNG, the GLB, and the codex
  entry all use the same `<name>` token, so future drift is greppable.

---

## When to skip steps

- **Tiny variant of an existing NPC** (e.g. recolor for a faction
  swap): skip Steps 1 and 3. The silhouette and animation are
  inherited. Only do Step 2 (new palette) and Step 4 (codex overlay).
- **Boss / hero character with elaborate concept**: do Steps 1–4
  AND a second silhouette pass at the action pose, not just idle.
  Boss readability under combat conditions matters more than at rest.
- **Ambient creature with no AI** (decoration only): Step 1 + Step 4
  only. No animation card needed.

The default for any named NPC or enemy is all 4 steps. Resist the urge
to skip Step 1 — it is the cheapest step and the highest-leverage one.
