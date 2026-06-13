---
type: pipeline
tags: [characters, modeling, pipeline, enemies, npcs, bosses, briefs]
status: draft
updated: 2026-06-13
sources:
  - "docs/character-pipeline/MODEL_DESCRIPTION_TEMPLATE.md"
  - "docs/character-pipeline/AI_WORKFLOW.md"
  - "docs/character-pipeline/MESHY_OPERATIONS.md"
  - "docs/character-pipeline/PROP_ATTACHMENT.md"
  - "docs/character-pipeline/bramble_charger.md"
  - "docs/character-pipeline/specs/bramble_archer.md"
  - "docs/character-pipeline/specs/bramble_charger.md"
  - "docs/character-pipeline/specs/brother_pell.md"
  - "docs/character-pipeline/specs/hedgemother.md"
  - "docs/character-pipeline/specs/hedgewight.md"
  - "docs/character-pipeline/specs/iron_gob.md"
  - "docs/character-pipeline/specs/marsh_rat.md"
  - "docs/character-pipeline/specs/quill.md"
  - "docs/character-pipeline/specs/sir_withering.md"
  - "docs/character-pipeline/specs/skitterling.md"
  - "docs/character-pipeline/specs/tusker_sow.md"
  - "docs/build-plans/eldra.md"
  - "docs/research/eldra/_principles.md"
---

# Character Model Briefs

Per-character model briefs cataloging every enemy, NPC, and boss in the Bramblewood pipeline — silhouettes, palettes, rig types, surface approaches, and the template that governs them all.

---

## The Brief Template

Every character must have a brief at `docs/character-pipeline/<name>.md` **before any Blender script is written** (`docs/character-pipeline/MODEL_DESCRIPTION_TEMPLATE.md`). The eight required sections:

| Section | Contents |
|---|---|
| **1. Identity** | Display name, role, one-line silhouette-first description, concept art path |
| **2. Proportions** | Height (m), head:body ratio, build (chibi/stocky/slim/hulking), authoring origin |
| **3. Palette** | 6–10 named hex colors with material slot names (`<Char>_<Slot>` convention), roughness notes |
| **4. Parts table** | Every primitive: mesh name, type, world position, dimensions, material, skip-outline flag |
| **5. Rig** | Layout (biped 6-part or quadruped 7-part), joint heights (Z_HIP/Z_SHOULDER/Z_NECK/Z_HEAD_TOP), sub-mesh parenting |
| **6. Surface texture approach** | One of: strand-cones / displaced-mass / painted-stripes / none — per region |
| **7. Outline strategy** | Which meshes skip the inverted-hull pass and why; suffix conventions (`_ruffle`, `_detail`, `_line`) |
| **8. Validation checklist** | 7-point gate: reads at NPC distance, unique silhouette, eyes protrude, no orphan meshes, Principled BSDF, outline suffixes, GLB size 30–150 KB |

**Authoring frame:** face on +X, lateral on ±Y, up on +Z. Script helpers remap to Blender's -Y forward. All sub-meshes parent to one of the named rig empties — no orphans. GLB exports with `export_animations=False, export_skins=False`; procedural empty rig drives motion in the engine (see [[Animation Pipeline]]).

### Outline suffix conventions

| Suffix | Meaning |
|---|---|
| `_ruffle` | Small surface bumps — skip outline (avoids fragmenting the dome's silhouette) |
| `_detail` | Small accessory overlapping a parent shape — skip if ink line would fight the parent |
| `_line` | A thin sliver that IS the drawn line (eyebrow, mouth seam) — skip the inverted-hull pass on the mesh itself |

### Surface texture approaches (Eldra A/B/C/D pass findings)

- **strand-cones:** many small cones as discrete strands. Every cone gets its own ink line — avoid for fur/beard/grass at NPC distance; OK for hero props seen close-up.
- **displaced-mass:** one main ellipsoid + ruffle bumps with `_ruffle` suffix. Cel-banded volume with one clean silhouette. Current beard/hair recipe.
- **painted-stripes:** vertex-color or texture stripes on a single primitive. Used for armor seams, scales. Cheap, no extra geometry.
- **none:** bare painted material. Most clothing, walls, weapons.

---

## AI Workflow (Meshy → Clean → Register → Game)

Source: `docs/character-pipeline/AI_WORKFLOW.md`. Cost: ~10 min active work, 35 Meshy credits (~$0.10 at Pro tier).

### Stage 1 — Generate via Meshy Image-to-3D (~5 min)
Upload concept art from `docs/concept-art/<name>.png`. Settings: Art style Stylized, Symmetry Auto (biped) or Off (quadruped), Topology Tri, Texture Yes with PBR, ~10,000 polygons. Regenerate if the first pass has melted faces or wrong proportions — second/third seeds often hit. Download as `.glb`.

### Stage 2 — Clean + slice + rig (~30 sec)

```bash
python3 scripts/clean_ai_mesh.py \
    --input ~/Downloads/Meshy_AI_Foo.glb \
    --name foo_ai_v1 \
    --rig biped \        # biped | quadruped | static
    --tris 30000         # 30k for hero NPCs; 10–15k for ambient mobs
```

The script: imports → applies transforms → optional Z rotation → centers + grounds → decimates + shade smooth → slices into rig parts → caps openings → renames materials → wraps in named empties → exports to `models/<name>.glb`.

**Key flags:** `--rotate-z` (correct forward axis), `--head-cut-ratio` / `--legs-cut-ratio` (Z-plane fractions for biped slicing, defaults 0.72/0.45), `--arm-cut-ratio` (X-plane fraction, default 0.30).

### Stage 3 — Register in codex

```bash
python3 scripts/register_ai_character.py foo_ai_v1
```

Inserts the GLB into `codex.js` MODEL_GROUPS and bumps the cache-buster.

### Stage 4 — Verify in codex
Open `codex.html`, click the model, toggle painted + ink outline. Codex info card must show all 6 rig parts. If it shows `static (no rig)`, re-run with adjusted cut ratios.

### Stage 5 — In-game integration (~5 min)
Add `loadFooGLB` + `buildFooMesh` in `src/scene/characters.js`. Wire `loadFooGLB()` into the `Promise.all([...])` startup block. Add to `NEW_NPCS` spawn list in `src/main.js`. Bump the `?v=<bump>` cache-buster on every import line.

### Troubleshooting

| Symptom | Fix |
|---|---|
| Codex says `static (no rig)` | Re-run `clean_ai_mesh.py` with adjusted `--head-cut-ratio` / `--legs-cut-ratio` |
| Character faces wrong way | Use `--rotate-z 90` (or 180, -90) |
| Mesh looks lumpy | Increase `--tris` to 30000+ |
| In-game NPC missing | Bump cache-buster on every `import` line in main.js |

---

## Prop Attachment and Sockets

Source: `docs/character-pipeline/PROP_ATTACHMENT.md`. Props are children of named empty objects ("sockets") parented to bones. Code attaches props by socket name; per-prop offsets survive re-export.

### Socket table (Meshy `UniRigArmature`, 29-bone rig)

| Socket | Parent bone | Holds |
|---|---|---|
| `socket_hand_L` | `Bone_016` (left hand) | Bow when drawn |
| `socket_hand_R` | `Bone_023` (right hand) | Arrow when nocked |
| `socket_back` | `Bone_002` (upper spine) | Bow when stowed |
| `socket_quiver` | `Bone_001` (chest/upper back) | Quiver (always) |
| `socket_cape` | `Bone_002` (upper spine) | Cape root |

Sockets are authored in Blender: `e = bpy.data.objects.new(name, None)`, parent type `BONE`, zero local transform. Export with `export_apply=False` so the Armature modifier survives.

### Prop generation (Recipe C)
Generate props as separate Meshy Image-to-3D assets (3–15k tris depending on size). Clean with `--rig static`. Drop in `PROP_URLS` + `PROP_SIZE` lookup in the sandbox. Parent to the right socket in code.

### Bow-draw state machine (game code)
```
STOW → DRAW    reparent bow: socket_back → socket_hand_L; crossfade body clip
DRAW (30%)     spawn arrow on socket_hand_R; decrement visible quiver
DRAW → AIM     hold last draw frame
AIM → RELEASE  detach arrow → projectile with velocity
RELEASE → STOW bow → socket_back; crossfade → locomotion
```
Tunables: `DRAW_TIME`, `RELEASE_TIME`, `NOCK_AT`. This prop choreography is always game code — Meshy and Mixamo provide body clips only.

**Hard-won facts about Meshy auto-rig:**
- Only rigs Meshy-native T-pose generations — feeding a `clean_ai_mesh.py` low-poly GLB fails with "Pose estimation failed" every time.
- Meshy 6 meshes are dense (300K–1.4M faces); the rig API caps at 300K — run `meshy_remesh` (target ~50K) first.
- Rigging is humanoid-only. Quadrupeds fail pose estimation.
- Rigging includes walk + run free (5 credits). `meshy_animate` (3 credits) adds a custom clip.
- Animation tasks download as `Animation_<Name>_withSkin.glb`. "Merged Animations" sidecar GLBs are degenerate — always grab the "with-skin" / "Character" variant.

---

## Character Catalog

### Enemies

#### Skitterling
**Role:** Enemy (small leaf-clad sprite / lesser bramble spirit) — links to [[Enemies]]
**Silhouette:** Small chibi humanoid, knee-high to player. Hooded cowl woven entirely from leaves (green with rust-orange tips), pale linen-bag face, two big featureless black holes for eyes. Crooked thin twig staff taller than the creature.
**Palette:** Face `#E4D8C2` · Leaf mid-green `#5E7A36` · Leaf rust-tip `#B0612A` · Tunic tan `#A88A5C` · Strap leather `#4A3220` · Staff wood `#6B4A2C` · Satchel `#8C6A3F` · Eye holes `#0B0B10`
**Rig:** biped · **Surface:** leaf-cones as entire hood/cape/skirt (the signature look) + painted-stripes for tunic seams
**Challenge:** Leaf-cones must be dense without exploding tri count. Staff taller than body — idle pose must angle it back.

---

#### Marsh Rat
**Role:** Enemy (small painted scaly quadruped) — links to [[Enemies]]
**Silhouette:** Low quadruped — barrel body, four short stubby legs, long tapered scaled tail. Pale cream face/snout, single big black eye. Dorsal crest of upright red-orange leaf-petals running spine-line. Body clad in overlapping slate-blue diamond scales with green moss patches.
**Palette:** Scales slate-blue `#3D556A` · Face cream `#E2D4B6` · Petals red `#B23A33` · Petals orange `#D8772E` · Moss `#6E833A` · Belly/feet tan `#A88862` · Tongue pink `#D87A86` · Eye black `#1A1A1E`
**Rig:** quadruped (4 legs + tail) · **Surface:** leaf-cones for dorsal petal crest (small flat cones, two rows); painted-stripes on body for scale tiling
**Challenge:** Petal crest is signature silhouette — cones must lay back along spine, not stick straight up.

---

#### Iron Gob
**Role:** Enemy (heavy-armored goblin brute) — links to [[Enemies]]
**Silhouette:** Chibi goblin proportions — huge head/helmet, short legs, broad shoulders. Slate-blue riveted plate armor with orange rivets/accents. Stone-headed warhammer almost as tall as he is.
**Palette:** Skin goblin-green `#7C9A5A` · Armor slate-blue `#3F5566` · Rivets/accent orange `#D87330` · Eyes glow-orange `#FF9B3D` · Kilt leather-brown `#6B4A2E` · Hammer stone-grey `#9A9A94` · Hammer haft wood `#7A5536` · Strap leather `#4A2F1E`
**Rig:** biped · **Surface:** painted-stripes for armor plate edges and rivets — no extra geometry
**Challenge:** Hammer is roughly chest-height — two-handed idle pose must not clip the breastplate or kilt. Helmet eye-glow needs emissive material.

---

#### Tusker Sow
**Role:** Enemy (large bramble-grown wild boar matriarch) — links to [[Enemies]]
**Silhouette:** Heavy quadruped — deep barrel chest, short stout legs, low-slung head. Stylized "wood-plank" body construction. Dense moss-green leaf clumps along spine/shoulders/rump. Two large curling cream-yellow tusks.
**Palette:** Plank warm-brown `#7A5A3A` · Plank shadow `#4A3220` · Leaf green `#5C7438` · Leaf yellow-green `#9AAE48` · Tusks cream `#E8DCB2` · Strap dark `#3A2616` · Snout tan `#A88058` · Eyes `#1A1612`
**Rig:** quadruped (4 legs) · **Surface:** leaf-cones for dorsal/shoulder leaf clumps; painted-stripes for plank seams
**Challenge:** Quadruped walk + charge animation. Tusks are silhouette-critical. Leaf-clumps need to mass into 3–4 readable shapes, not scatter as noise.

---

#### Bramble Archer
**Role:** Enemy (ranged bramble-cult skirmisher) — links to [[Enemies]]
**Silhouette:** Small biped, slightly hunched into draw stance. Pale dome-hood/mask with dark twin eye-slits and pointed beak (ghostly owl-skull read). Layered tattered cloak in green leaves with rusty-orange neck wrap. Curved organic-twig recurve bow drawn at chest height.
**Palette:** Mask pale-bone `#E0D2B6` · Mask shadow `#9A8C72` · Cloak deep-green `#48603A` · Leaf highlight `#7C9A48` · Neck wrap rust `#B25E2C` · Tunic mossy `#6E7E48` · Leather brown `#5A3D26` · Bow/arrows wood `#7A5536`
**Rig:** biped · **Surface:** leaf-cones layered along cloak shoulders and skirt edges; painted-stripes for mask eye-slits and arrow fletching colors
**Challenge:** Drawn-bow pose is the signature read — both hands must hold props (bow + arrow nock), requiring proper hand parenting. Beak-mask must not clip into the high collar leaves.

---

#### Bramble Charger
**Role:** Enemy (smaller, faster bramble-grown boar) — links to [[Enemies]]
**Silhouette:** Compact quadruped, lower-slung than Tusker Sow. Dense layered green leaves covering almost the entire body. Pale cream snout pushing forward (+X), two upturned cream tusks, glowing amber eyes, wood-plank armor strapped to flanks. Charge-pose: head low, hindquarters slightly higher.
**Palette:** Hide dark `#2A1F18` · Leaf dark `#46582E` · Leaf light `#7E933E` · Snout cream `#D8C49A` · Tusk cream `#EFE0B6` · Eye glow-amber `#F0962A` (emissive `#FFB54A`, strength 1.8) · Plank brown `#6E4D2E` · Strap `#3A2516` · Hoof `#2E2218`
**Rig:** quadruped (Body/Head/Tail/Leg_FL/FR/BL/BR) · **Surface:** ~28 leaf-cones as the dominant surface (names carry `_ruffle_leaf_` so outline pass skips them → one unified silhouette); plank armor as solid boxes; emissive flat color on eyes
**Coverage rule:** Leaves must cluster densely on top/sides but leave a clear cream snout protruding +X and legs visible below z=-0.10. Burying the snout is the most common failure.
**Full spec:** `docs/character-pipeline/bramble_charger.md` (parts table with all 28 leaf positions)

---

### Bosses

#### Hedgemother
**Role:** Boss (matriarch bramble-spirit, hedgerow given form) — links to [[Bosses]]
**Silhouette:** Wide, squat boss — broader than tall, crouched on knuckle-arms. Crown of crooked branching antlers studded with bright red berry clusters. Body a layered tangle of moss-green leaves over deep brown root/bark torso. Long heavy bark-knuckle arms reaching the ground.
**Palette:** Bark dark `#3A281C` · Bark mid `#6E4A2E` · Leaves deep-green `#3E5128` · Leaves highlight `#7C9A3E` · Berries red `#B83830` · Eye glow-yellow `#F2C033` · Antler pale-wood `#B89868` · Vine/root `#5A4A2E`
**Rig:** biped (knuckle-walker proportions — long arms, short legs) · **Surface:** leaf-cones for body/shoulders/crown/back + strand-cones for root-tendril chin beard and antler tines + painted-stripes for bark grain — two surface systems on one rig
**Challenge:** Glow eyes need emissive material that survives toonification. Antler crown must read clean at silhouette and not noise out against leaves behind it.

---

#### Hedgewight
**Role:** Boss (mini-boss / lieutenant — bramble-grown bear-beast) — links to [[Bosses]]
**Silhouette:** Heavy quadruped — thick legs, low broad shoulders, bear-like head. Pale cream skull-mask face with dark eye-pits. Massive leaf-and-plank "shell" mound covering back/shoulders/hips. Small bright flower clusters (yellow, blue, white) dotting the leaf mass.
**Palette:** Skull-face cream `#E0D2B0` · Skull shadow `#A89880` · Leaves green `#5A7236` · Leaves highlight `#94AE48` · Plank warm-brown `#7A5236` · Plank shadow `#3E2A1A` · Flower yellow `#E8C44A` · Flower cool-blue `#4A6FA0`
**Rig:** quadruped (4 legs) · **Surface:** leaf-cones across entire dorsal mound; small-scale leaf-cone variant with flower-petal tinting for flower clusters; painted-stripes for plank seams and skull-mask shadow
**Challenge:** Flower clusters need a separate small-scale leaf-cone variant (color-tinted) so they read as petals against the green mass. Quadruped boss rig with heavier idle breathing animation than Tusker/Charger.

---

### NPCs

#### Quill
**Role:** NPC (young forager / apprentice cartographer) — links to [[NPCs]]
**Silhouette:** Big round head, tiny body — most extreme chibi ratio in the cast. Voluminous curly auburn hair with leaf sprigs tucked in. Mossy green half-cape with hood thrown back. Forager's pack: wooden frame with strapped log, leaves, herb bundles.
**Palette:** Skin `#F2C9A7` · Hair auburn `#B8662E` · Hair highlight `#D8954A` · Cape moss-green `#5A6E3A` · Tunic beige `#C9B68A` · Belt/boots brown `#5A3826` · Leaves fresh-green `#6E8C36` · Pack wood `#8C6A3F`
**Rig:** biped · **Surface:** displaced-mass for hair (single cap mesh with vertex jitter to read as curls); leaf-cones for leaf sprigs in hair and pack
**Challenge:** Hair volume is half the silhouette — must not eat the face plane. Pack contents need to be a single welded prop, not loose floaters that pop through walk cycle.

---

#### Brother Pell
**Role:** NPC (mendicant scribe / wandering brother) — links to [[NPCs]]
**Silhouette:** Wide barrel torso, short legs, large flat brown boots. Bald crown ringed by tonsure of brown hair; massive square brown beard with grey streaks. Cream/off-white belted robe with cracked dark trim. Open scroll held in left hand.
**Palette:** Skin `#E5B391` · Beard brown `#5C3E2A` · Beard highlight grey `#A89884` · Robe cream `#E4D8B8` · Robe trim dark `#3A3026` · Bedroll slate `#4A5C68` · Belt/pouch leather `#6B4530` · Medallion brass `#C49A3F`
**Rig:** biped · **Surface:** strand-cones for the squared-off beard tips; painted-stripes for robe trim, belt detail, and the lined-text scroll
**Challenge:** Held scroll prop should parent to left hand without clipping through belly. Beard volume must not crash into the medallion.

---

#### Sir Withering
**Role:** NPC (chibi gnome-knight with falcon companion) — links to [[NPCs]]
**Silhouette:** Stout chibi — oversized head, tiny legs, large brown boots. Frizzy white hair + full forked white beard. Layered garb: deep teal hooded cloak over cream tabard. Falcon companion (separate small mesh) on outstretched gauntlet.
**Palette:** Skin `#E2A98A` · Hair/beard `#E8E4DC` · Cloak teal `#3F5D6A` · Tabard cream `#D9CDB2` · Patch red `#A8423B` · Boots brown `#5A3A28` · Falcon body `#5C7480` · Falcon beak/feet `#D9A53C`
**Rig:** biped (humanoid); falcon is a separate small biped/winged prop · **Surface:** strand-cones for the forked beard tips and side-tufts; painted-stripes for cloak patches and tabard markings
**Challenge:** Falcon must parent to the right gauntlet bone so it rides through walk cycle without sliding. Beard fork must read at silhouette without poking through chest cloak.

---

#### Eldra the Lampwright
**Role:** NPC (village lampwright, elderly grandfather figure) — links to [[NPCs]]
**Silhouette:** Squat chibi — body ~3.5 heads tall. Voluminous windswept white hair (up + back), substantial chin beard with forked tip. Character-defining prop: staff with two hanging lanterns (the saturation peak). Primary shape: circle (kindly read). Secondary shape: triangle (staff rising past shoulder).
**Height:** 1.55 m · Head fraction 0.32 · **Palette:** skin `#f0c8a8` · hair/beard `#f4f0e8` · tunic cream `#e8d8b8` · vest ochre `#a87a48` · scarf teal `#4a6878` · trousers olive `#7a8a78` · leather `#6a4a2a` · herb `#5a7848` · lantern brass `#b88440` · **lantern flame `#ffd060` (EMISSIVE 2.5 — the one saturation peak)**
**Rig:** biped, 6-empty rig · **Animation overrides:** `cadenceMul: 0.7` (slow elder walk), `leanMul: 1.6` (stooped forward lean), `locked_arms: R` (Arm_R holds staff, does not swing)
**Full build plan:** `docs/build-plans/eldra.md` (65 parts: STAFF 8, LANTERN×2=10, BEARD 10, HAIR 8, BACKPACK 7 + standalone parts)
**Art-style principles applied:** shape commitment to CIRCLE, one saturation peak (lantern flame), palette reduced to 10 hues (from 30 in v2), Wind Waker chibi proportions, 64×64 thumbnail test (`docs/research/eldra/_principles.md`)

---

## Brief Template Reference (Wren the Tinker)

The filled example in `MODEL_DESCRIPTION_TEMPLATE.md` is Wren the Tinker — a slim young woman in a patched oilcloth coat, brass goggles, and a belt of tin tools. Not a canon character but a complete worked example showing the expected level of detail for all 8 sections, including all part positions, skip-outline flags, and a GLB size projection (70–90 KB at ~30 primitives).

---

## See also

- [[Enemies]] — stat blocks and spawn functions
- [[Bosses]] — boss encounter design
- [[NPCs]] — dialog, schedule, gift preferences
- [[Blender Pipeline]] — material recipe (Principled BSDF, bevel, GLB export flags)
- [[Asset Pipeline]] — concept → model → game end-to-end
- [[Animation Pipeline]] — procedural empty rig, walk animator, GLB orientation
- [[Art Bible]] — style rules (chunky silhouette, mossy/leaf-shingle visual language, painted-toon shading)
- [[Concept Art Prompts]] — Midjourney prompts that produce the concept images these briefs are built from

## Sources

- `docs/character-pipeline/MODEL_DESCRIPTION_TEMPLATE.md` — brief template + Wren worked example
- `docs/character-pipeline/AI_WORKFLOW.md` — Meshy stages 1–6 + troubleshooting table
- `docs/character-pipeline/MESHY_OPERATIONS.md` — recipes A (texturing), B (draw clip), C (prop mesh); Meshy API hard-won facts
- `docs/character-pipeline/PROP_ATTACHMENT.md` — socket table, Blender socket authoring, bow-draw state machine
- `docs/character-pipeline/bramble_charger.md` — full parts table with 28-leaf layout
- `docs/character-pipeline/specs/` — one-page briefs for all 11 characters
- `docs/build-plans/eldra.md` — complete Eldra build plan (65 parts, palette, animation contract)
- `docs/research/eldra/_principles.md` — six art-style principles (shape commitment, hierarchy, palette, cel shading, chibi proportions, thumbnail test)
