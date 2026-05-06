# Brindlecow Concept-Art Prompt

The Brindlecow is the Trivial-tier passive enemy of the Bramblewood — found in
the south pasture, drops Raw Brindle + Wool Flank. Per `src/data/items.js` and
`docs/ART_BIBLE.md`: cute toon dairy cow, blocky simplified body, friendly
proportions.

After generating, save the favorite as `docs/concept-art/brindlecow.png` and
the runner-up to `docs/art-refs/cow_v2.png`. Then re-author `models/cow.glb`
to match — single coherent body block, head + ears + horns + snout grouped
on a short neck, four chunky legs with hooves on the ground, tail behind, a
few black blob spots painted onto the body sides (not floating).

---

## Prompt

```
Stylized low-poly fantasy RPG render in the style of RuneScape 3 meets
Genshin Impact. Hand-painted toon textures over simple chunky primitive
geometry. Clean readable silhouette, soft warm key light from upper left,
cool sky fill, gentle ambient occlusion, faint rim light, painterly
grass-and-wood materials, no photorealism, no glossy plastic, no
PBR-metallic look. 3/4 isometric camera, slight downward tilt, square
aspect ratio, isolated on a neutral cream-grey backdrop. Family-friendly,
cozy adventure mood.

— A cute cartoon dairy cow standing on all fours, side 3/4 view, warm
cream-white body with a few large irregular black blob spots painted on the
sides and back, blocky simplified body shape (a single rounded box, not
naturalistic), short stubby neck connecting body to head, gentle rectangular
head with a large soft pink snout, two big black dot eyes with bright
highlights, two small drooping cream ears, two short curved cream horns
sticking up, leather collar with a small brass bell at the base of the neck,
four short stocky legs with dark brown hooves planted on the ground, a slim
black-tipped tail behind, friendly relaxed expression, full body 3/4 view,
single character on plain cream backdrop, all parts visually connected — no
floating accessories. —

Color palette: warm cream-white body, soft rose pink snout and udder, oak
brown hooves, deep brown spots, cream horns, brass bell. Avoid neon, avoid
grayscale, avoid cyberpunk lighting.
```

**Midjourney flags**: `--ar 1:1 --stylize 250 --v 7`

---

## What to look for in the result

Pick the variant where:
- The cow reads as **one coherent shape** when squinted at — not a collection of separated parts
- Head sits **directly against** the body (no visible gap)
- Horns and ears **touch the head**
- Spots are **on the body surface**, not floating
- All four legs **reach the ground** at roughly the same level
- The silhouette is **clearly bovine** even at 32×32 pixels

The first three points are the ones the previous cow.glb failed at. The new
mesh will be authored by Blender script using your chosen reference image as
the visual target — proportions, color hex, spot count, horn curve, etc. are
all driven from what you pick.

---

## After concept art lands

Once `docs/concept-art/brindlecow.png` is saved, the rebuild plan is:

1. Wipe Blender to a fresh empty scene
2. Author the cow procedurally — primitives positioned by code so every
   sub-part TOUCHES its neighbor (no parent_inverse pitfall, no scattered
   children). Roughly 12-15 meshes total:
   - `Body` (rounded box, the spine)
   - `Head` (smaller rounded box at the front, touching neck)
   - `Neck` (short stub between body front and head)
   - `Snout` (pink box on head front)
   - `Ear_L`, `Ear_R` (small drooping shapes off head sides)
   - `Horn_L`, `Horn_R` (curved cones on head top)
   - `Eye_L`, `Eye_R` (small black spheres on head)
   - `Leg_FL`, `Leg_FR`, `Leg_BL`, `Leg_BR` (cylinders, all reaching ground)
   - `Tail` (thin curve at body rear)
   - `Spots[]` (welded ONTO the body mesh — not separate objects, baked in)
   - `Bell` (small brass cube on collar, touching neck)
3. Keep the named rig empties (`Body`, `Head`, `Tail`, `Leg_FL/FR/BL/BR`) so
   `src/anim/cow.js` keeps driving walk + idle without code changes.
4. Apply the bevel + Principled BSDF + glTF export recipe from
   `docs/BLENDER_PIPELINE.md` (the `feedback_blender_bevel_pipeline.md`
   memory).
5. Verify in `/codex.html` model viewer before shipping — the silhouette
   should read as a cow at any zoom.
