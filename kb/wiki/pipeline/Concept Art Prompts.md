---
type: pipeline
tags: [concept-art, midjourney, prompts, art-style, pipeline]
status: draft
updated: 2026-06-13
sources:
  - "docs/concept-art-prompts-master.md"
  - "docs/concept-art-prompts-archetypes.md"
  - "docs/concept-art-prompts-cow.md"
  - "docs/concept-art-prompts-next.md"
  - "docs/concept-art/INDEX.md"
  - "docs/concept-art/dungeons/crypt/PROMPTS.md"
  - "docs/concept-art/enemies/PROMPTS.md"
  - "docs/concept-art/ranger-props/PROMPTS.md"
  - "docs/skills/CONCEPT_ART_PROMPTS.md"
  - "docs/prompts/eldra_iterations.md"
---

# Concept Art Prompts

The Midjourney (and ChatGPT/DALL-E) prompt library for Wayfinder concept art — the master style stems, per-category prompt sets, and the workflow from generated PNG to 3D model.

All 53 master-sheet prompts shipped 2026-05-01 (categories A–I in `docs/concept-art-prompts-master.md`). This page catalogs the stems, per-category summaries, and the additional specialized batches written after the master sheet.

---

## Master Style Stem (characters and props)

All character/prop prompts prepend this locked stem verbatim. **Do not change it** — it is what maintains tonal coherence across the whole Bramblewood cast.

```
Stylized low-poly fantasy RPG render in the style of RuneScape 3 meets Genshin Impact.
Hand-painted toon textures over simple chunky primitive geometry. Clean readable
silhouette, soft warm key light from upper left, cool sky fill, gentle ambient
occlusion, faint rim light, painterly grass-and-wood materials, no photorealism,
no glossy plastic, no PBR-metallic look. 3/4 isometric camera, slight downward tilt,
square aspect ratio, isolated on a neutral cream-grey backdrop. Family-friendly,
cozy adventure mood.
```

**Midjourney flags:** `--ar 1:1 --stylize 250 --v 7`

The subject goes between em-dashes after the stem. Palette notes go after the subject. When something is wrong, fix the *subject* paragraph, not the stem.

---

## Master Sheet (53 prompts, all shipped 2026-05-01)

Prompts live in `docs/concept-art-prompts-master.md`. Generated PNGs saved to `docs/concept-art/<slug>.png`.

### A. Player archetypes (6) ✅

| Slug | Character | Key palette |
|---|---|---|
| `knight` | Young human knight, centurion helm with red plume, olive-bronze breastplate, red cape, iron sword + laurel shield | Warm earthy greens, oak browns, burnished gold, soft rose |
| `knight-gold` | Sun Knight variant — gilded helm with sunburst crest, gold-trimmed breastplate, royal-blue tabard, sunburst shield | Pale gold, royal blue, cream linen, bone white, polished silver |
| `druid` | Bramble-green hooded robe with leaf-trim, twisted oak staff with amber orb | Deep moss green, oak brown, soft amber glow, cream linen |
| `druid-dark` | Night Druid — deep indigo-purple hood, blackthorn staff with pale-blue moonstone | Deep indigo, midnight blue, pale moon-blue, charcoal, silver |
| `archer-player` | Mosscloak Ranger — mossy-green forest cloak, longbow of warm oak, back quiver, leather belt | Mossy forest green, warm oak brown, cream linen, dark leather |
| `wanderer-bard` | Bridget the bard — dusty-pink wool hat with sky-blue feather, auburn hair, wooden lute | Dusty pink, soft gold, cream linen, warm auburn, sky blue |

### B. Enemies (7) ✅

| Slug | Enemy | Key silhouette features |
|---|---|---|
| `enemy-skitterling` | Tiny bramble-fae, prickle-skin, glassy black eyes, dried-leaf cap, bramble-stick | Yellow-green moss, dark thorn-brown |
| `enemy-marsh-rat` | Wet-furred bog rat, dark slate-grey fur with algae streaks, pink scaled tail, orange incisors | Slate-grey, algae green, pink tail |
| `enemy-iron-gob` | Armored goblin — sooty olive-grey skin, patchwork iron plate, forge hammer on shoulder | Dark iron-grey, soot black, ember-red eye glow, olive goblin skin |
| `enemy-tusker-sow` | Matriarch boar — dark mossy-brown bristles, two huge yellowing tusks per side, leaf-mantle | Dark mossy brown, yellow-bone tusk, bog-mud charcoal |
| `enemy-bramble-archer` | Thorn-fae perched on a thornlimb — dusty-brown feathered cloak, thorn hood-mask with black eyes, vine shortbow | Dusty feather brown, dark thorn green |
| `enemy-bramble-charger` | Black-bristled boar mid-charge — charcoal-black fur with green-bramble crown, glowing amber eyes | Charcoal black, mossy green, pale ivory tusks, amber eyes |
| `enemy-hedge-wolf` | Predator wolf of bramble vines + ash-grey fur — blackthorn antlers, leaf-shingle armor, prowling pose | Ash-grey fur, deep moss-green leaf shingles, amber eyes |

### C. Weapons by tier (12) ✅

All 12 shipped to `docs/concept-art/weapon-{brindle,bogiron,cinderbloom}-{sword,axe,dagger,pickaxe}.png`.

**Item stem (separate from character stem):**
```
Stylized low-poly fantasy RPG item render in the style of RuneScape 3 meets Genshin Impact.
Hand-painted toon textures over simple chunky primitive geometry. Clean readable silhouette,
soft key light from upper left, gentle ambient occlusion, painterly wood-and-metal materials,
no photorealism, no glossy plastic. Single object floating against a neutral cream backdrop,
3/4 top-down icon angle, slight drop shadow under the object.
```

| Tier | Palette |
|---|---|
| Brindle (T1) | Warm brindle-tan, oak brown, cream leather, brass |
| Bogiron (T2) | Rusty bog-iron, dark moss green tint, oak grip, hammered copper |
| Cinderbloom (T3) | Dark steel, pink-ember glow, black-leather, gold-bud pommel |

### D. Shields (3) ✅
Wooden (oak + iron bands), Bogiron (heater-shape, moss-bramble boss, copper studs), Cinderbloom (kite-shape, glowing pink ember-line, blackened-rose embossed).

### E. Armor (4) ✅
Leather body (warm tan, brass buckles), Bogiron cuirass (pitted bog-iron, moss-bramble crest), Cinderbloom plate (dark steel with pink ember-veins + gold trim), Cinderbloom helm (flame-tongue crest, pink brow-line).

### F. Quest items (9) ✅
Apprentice Hammer, Falcon's Whistle, Thorn Crown, Quill's Field Atlas, Hod's Anvil Token, Healing Draught, Pantry Stew, Whickerhare's Foot, Bramble Resin.

### G. Cartography props (5) ✅
Blank Chart, Surveyor's Pole, Cartographer's Compass, Master Chart of the Bramblewood Valley, Waypoint Cairn.

### H. NPCs (4 new) ✅
Eldra the Lampwright (stooped elderly woman, lantern-pole, patchwork shawl), Cricket the Letter-Carrier (thin teen, mossy-green tunic, cricket on shoulder), Brother Pell (short round-faced monk, cream robe, illuminated parchment), Mother Onywyn the Herb-Witch (tall thin, deep-green cloak, raven on shoulder, foxglove sprig).

### I. Environment landmarks (3) ✅
Chartmaker's Tower (three-story round stone, brass telescope, copper-domed roof), Forge interior (anvil with glowing bar, leather bellows, sparks), Herbalist hut interior (herb bundles on beams, alchemy bench, sleeping cat).

---

## Next Wave Prompts (batch 2)

Source: `docs/concept-art-prompts-next.md`. A second batch organized by function. **Locked stem** for this wave uses a different voice (more "storybook concept art" than the RuneScape/Genshin framing):

```
hand-painted storybook concept art, cozy fairytale RPG, low-poly 3D reference,
Bramblewood village setting, soft watercolor wash + ink linework, warm earthy palette
(oak browns, mossy greens, parchment cream, hearth-orange highlights), gentle
directional dawn light, 3/4 isometric view, neutral grey background, no UI, no text,
no outline cel-shade, single subject centered.
--ar 1:1 --stylize 250 --v 7
```

> ⚠️ This stem was superseded by the skills-art rejection (see "Aesthetic failure modes" below). The RuneScape/Genshin character stem is preferred.

Groups: A (village ambient props: signpost, market stall, village well, dovecote, fishing dock), B (new NPCs — overlaps with master sheet H), C (mid-tier hostile creatures: Hedge-Wolf, Briar Lurker, Bog-Stag, Hollow Gourd), D (environment landmarks — overlaps with master sheet I), E (quest props — overlaps with master sheet F/G), F (cartography — overlaps with G).

---

## Archetype Prompts (v2 rebuild refs)

Source: `docs/concept-art-prompts-archetypes.md`. Three prompts for fresh concept art before re-authoring `knight_v2.glb`, `druid_v2.glb`, `wanderer_v2.glb`. Uses the same locked character stem. Save outputs to `docs/art-refs/<slug>_archetype.png`, then rebuild the GLBs in Blender.

**Critical Blender note from this batch:** when parenting rig empties, set `keep_transform=False` — using `keep_transform=True` bakes the parent's world position into a `parent_inverse` matrix that cancels the rig position, which is the bug that made v2 GLBs collapse to origin.

---

## Brindlecow Prompt

Source: `docs/concept-art-prompts-cow.md`. Uses the locked character stem. Subject: a cute cartoon dairy cow, blocky simplified body (a single rounded box), cream-white with large irregular black blob spots, soft pink snout, leather collar with brass bell, four short stocky legs with dark brown hooves.

**What to look for:** All four legs reach the ground, spots are ON the body surface (not floating), head sits directly against the body, all parts visually connected. The three previous `cow.glb` failures were: gap between head and body, floating spots, legs not reaching ground.

Save to `docs/concept-art/brindlecow.png`. Then rebuild `models/cow.glb` procedurally in Blender (~12–15 meshes keeping the named rig empties Body/Head/Tail/Leg_FL/FR/BL/BR).

---

## Crypt Biome Tile Set (20 pieces)

Source: `docs/concept-art/dungeons/crypt/PROMPTS.md`. Pipeline: Midjourney → save PNG → Meshy Image-to-3D → `clean_ai_mesh.py --rig static` → `models/dungeon_crypt_<piece>_v1.glb`.

**Crypt master prompt stem:**
```
chunky low-poly stylized fairytale dungeon <PIECE>, mossy grey stone, cozy storybook
game asset, one object only, three-quarter view, plain flat neutral grey background,
Wind Waker cel-shaded look, soft chunky shapes, centered, even soft lighting
--ar 1:1 --cref ../../dungeon-interior-1.png --cw 50
--no character, person, UI, HUD, multiple objects, scenery, background, text
```

`--cref dungeon-interior-1.png --cw 50` is mandatory on every call — it keeps palette/style locked across the 20 tiles.

**Tile categories and Meshy settings:**

| Category | Pieces | Target polycount |
|---|---|---|
| Floor tiles (3) | brick, mossy, cracked — top-down shot | 3,000 |
| Walls (5) | straight, inner corner, outer corner, archway, door | 3,000 |
| Vertical/structural (2) | stairs, column | 3,000 |
| Light sources (2) | brazier, wall torch — also spawn a PointLight in code | 3,000 |
| Furniture (4) | sarcophagus, altar, chest, bookshelf | 5,000 |
| Doodads (4) | frayed rug (--ar 16:9), cobweb cluster, bone pile, broken pottery | 2,000 |

**Floor tile shortcut:** If Meshy struggles with a flat tile, skip it and use the generated PNG as a tileable texture on a `PlaneGeometry` (`texture.wrapS/T = RepeatWrapping`). Walls and props always go through full Meshy Image-to-3D.

**ASCII layout parser** maps characters to GLBs: `.` = brick floor, `W` = wall (parser auto-picks straight/corner/rotation), `B` = brazier (+ PointLight), `S` = sarcophagus, `@` = player spawn, `g` = enemy spawn. See `docs/concept-art/dungeons/crypt/PROMPTS.md` for the full legend.

---

## Crypt Enemy Set (4 creatures)

Source: `docs/concept-art/enemies/PROMPTS.md`. Uses niji 6 for a more anime-readable toon look than the character stem:

```
<SUBJECT>, cute exaggerated chunky cartoon proportions, super simple geometric
shapes, plain pale cream background, one object only, three-quarter view
--niji 6 --ar 3:4 --stylize 400
--no photoreal, realistic, PBR, gradient shading, watercolor, dark, gritty,
multiple characters, scenery, UI, text
```

| Enemy | Rig | Target tris | Stat block |
|---|---|---|---|
| Skeleton | biped | 5,000 | HP 18 · dmg 4 · spd 2.0 |
| Crypt Rat | quadruped | 3,000 | HP 8 · dmg 2 · spd 3.0 |
| Ghost | static (animator bobs) | 3,000 | HP 14 · dmg 5 · spd 1.5 |
| Hedge-Sprite | biped | 5,000 | HP 22 · dmg 6 · spd 1.8 |

After GLBs land: `src/data/enemies.js` stat registry, `src/anim/<name>.js` × 4, `src/data/dungeonSpawns.js` for `MOB_CRYPT`.

---

## Ranger Prop Set (6 assets)

Source: `docs/concept-art/ranger-props/PROMPTS.md`. Splits the Mosscloak Ranger into a prop-stripped body + separable assets. All using `archer-player.png` as `--cref`.

| Asset | Slug | Notes |
|---|---|---|
| Stripped body | `ranger-stripped.png` | A-pose, empty hands, no props — `--cw 80` to keep face/proportions |
| Bramble longbow | `prop-ranger-bow.png` | Lead with "archery weapon" to avoid Midjourney ribbon confusion; no ribbon, no foliage |
| Single arrow | `prop-ranger-arrow.png` | Horizontal side profile `--ar 16:9`; origin at nock end, shaft pointing +X |
| Quiver | `prop-ranger-quiver.png` | Russet leather, feathered arrow ends poking out; `--ar 3:4`, Symmetry Off |
| Hooded cloak | `prop-ranger-cloak.png` | Draped as if on invisible figure, hood down; back view |
| Expression sprite sheet | `ranger-face-atlas.png` | 4-col × 2-row grid: neutral/happy/sad/angry / surprised/blink/talk-A/talk-O |

**Expression atlas layout** (used in JS as UV offset): col/row → `faceMat.map.repeat.set(1/4, 1/2); faceMat.map.offset.set(col/4, 1 - (row+1)/2)`. Blink cycles every 3–5s; talking alternates two mouth-open cells at ~8 Hz.

After all 6 exist: Meshy Image-to-3D the 5 mesh assets, add sockets to body GLB in Blender, swap placeholder factories in `rig_test.html`, Mixamo round-trip for clips.

---

## Skills / Ability Codex Prompts

Source: `docs/skills/CONCEPT_ART_PROMPTS.md`. 13 prompts for the ability codex showcase at `docs/skills/index.html`.

**Aesthetic failure (batch 1, 2026-05-26):** Painterly watercolor stem + `--style raw --v 6` → atmospheric mist, not the chunky toon the game uses. User feedback: "maybe not cartoony enough. this pattern just looks blurry."

**Locked stem v2 (chunky toon):**
```
Storybook chunky cartoon illustration, bold black ink outlines, flat cel-shaded colors,
thick linework, low-poly toon style, saturated parchment palette, sharp edges,
Bramblewood enchanted forest setting, focal subject centered.
```
Flags: `--ar 16:9 --v 6 --stylize 50 --no blur, mist, painterly, soft photo`
ChatGPT/DALL-E: prepend `Create a wide cinematic 16:9 landscape image.`

| Slug | Subject sentence |
|---|---|
| `basicshot` | A single glowing golden arrow mid-flight, crisp bright sparks trailing behind, bright morning forest light. |
| `powershot` | A heavy crackling golden arrow with fierce bright sparks, dynamic motion, dramatic glow piercing through the forest. |
| `multishot` | Three arrows fanned out in a perfect cone, sharp golden trails arcing through warm dawn forest light. |
| `snare` | Bramble vines snapping up from the forest floor in a ring of thorns, bright green glow ensnaring the air mid-coil. |
| `hedgemother` | An ancient towering forest mother of bramble and root, fearsome but storybook, hovering wreathed in glowing vines, looming and beautiful. |
| (+ 8 more) | burn, bleed, snared, root, brambled, swift, sunlit, briarbound |

---

## Eldra Exploration (Blender iteration, not Midjourney)

Source: `docs/prompts/eldra_iterations.md`. The Eldra exploration is a **Blender script iteration series**, not a Midjourney session. Five variants (A–E) each test one "less blocky" lever in isolation:

| Variant | Lever | Mechanism |
|---|---|---|
| A — Tapered limbs | Silhouette reads as stacked blocks | Replace limb segments with 3 stacked cubes stepping down in width |
| B — Asymmetry | Mirror-symmetric "robot" feel | Random jitter on hair tufts, beard off-centre, shoulders at different heights |
| C — Round forms | Everything is a cube | Head dome as top-half sphere, lanterns as 8-sided cylinders, subsurf level 3 on selected parts |
| D — Multi-shade gradient | Flat "painted plastic" fabric | 3 stacked cubes per garment panel: top-shadow + main + bottom-highlight |
| E — Cylinders + sphere head | Stacked-cube tapering (variant A) | All limb segments → 12-vertex tapered cylinders; head → UV sphere; Cast modifier on torso/shoulders |

Winner from grading: **Variant A direction** (tapered limbs). Variant E pushes it further with real cylindrical primitives. Pattern propagates to other NPCs once validated.

---

## Aesthetic Failure Modes

| Failure | Cause | Fix |
|---|---|---|
| "Blurry / atmospheric mist" | Watercolor wash stem + `--style raw --v 6` | Use chunky-toon stem v2 with `--no blur, mist, painterly, soft photo` |
| "Roblox / Minecraft" read | Limbs are uniform columns (not tapered) | Apply Variant A tapered-limbs treatment |
| Midjourney draws a ribbon for "bow" | Ambiguous keyword | Lead with "archery weapon, a longbow you shoot arrows with — NOT a ribbon" |
| Prop buried in foliage | MJ over-interprets "thorn" | Add "clear readable silhouette, sparse thorns" |
| Second generation prompt failures | Don't know what concept art looked like | Start with `--cref <reference.png> --cw 50` to anchor style |

---

## Workflow Reference

1. Save the favorite as `docs/concept-art/<slug>.png`
2. Append a row to `docs/concept-art/INDEX.md` (mark Status: shipped or replacing dummy)
3. Hand the slug back — engineer follows Phase 2A of the [[Asset Pipeline]] (`docs/ASSET_PIPELINE.md`)
4. Generate in batches of 3–5 prompts — larger batches lose tonal coherence

**Generation tips:** 4 variations is the sweet spot. Regenerate (different seed) if the first pass is wrong — 2nd/3rd seeds often hit. Never modify the locked stem; fix the subject paragraph if anything reads wrong.

---

## See also

- [[Art Bible]] — style rules that these prompts operationalize (chunky silhouettes, mossy/leaf-shingle language, toon shading)
- [[Character Model Briefs]] — per-character palettes, rig types, and silhouette notes
- [[Asset Pipeline]] — what happens after a PNG lands (Meshy → clean → register → game)
- [[Blender Pipeline]] — Blender-side cleanup recipe
- [[Enemies]] — which enemy GLBs are waiting on concept art
- [[NPCs]] — which NPC GLBs are waiting on concept art

## Sources

- `docs/concept-art-prompts-master.md` — 53 prompts A–I, all shipped 2026-05-01
- `docs/concept-art-prompts-archetypes.md` — v2 archetype rebuild refs + Blender parenting fix
- `docs/concept-art-prompts-cow.md` — Brindlecow prompt + what-to-look-for checklist
- `docs/concept-art-prompts-next.md` — batch 2 with the (deprecated) watercolor stem
- `docs/concept-art/INDEX.md` — status table for all generated PNGs
- `docs/concept-art/dungeons/crypt/PROMPTS.md` — 20 crypt tile prompts + ASCII layout format
- `docs/concept-art/enemies/PROMPTS.md` — 4 crypt enemy prompts (niji 6)
- `docs/concept-art/ranger-props/PROMPTS.md` — 6 ranger prop/expression prompts
- `docs/skills/CONCEPT_ART_PROMPTS.md` — 13 ability codex prompts (v2 chunky-toon stem)
- `docs/prompts/eldra_iterations.md` — Eldra Blender variant prompts A–E
