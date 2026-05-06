# Bramblewood — Concept Art Index

Reference art generated for the project. Filenames are stable; the long Midjourney originals live in the user's `~/Downloads/concept-art/` archive.

Use these as **modeling reference** before any new GLB build. Match silhouette, palette, and prop set; chunky low-poly Blender treatment per `docs/BLENDER_PIPELINE.md`.

## Creatures

| File | Subject | Status | Mesh notes |
|---|---|---|---|
| `bramble-imp.png` | Mossy goblin-imp with leaf cloak + thorn-club | Placeholder (tinted goblin GLB) → **needs new GLB** | Greener body, stacked-leaf back, 2-spike club |
| `hedgewight.png` | Wolf shape covered in moss-leaf carapace | Placeholder (tinted boar GLB) → **needs new GLB** | Quadruped wolf base; leaf shingles on back/shoulders |
| `wolf-alpha.png` | Boss wolf, glowing blue eye, leaf mane | Missing | Larger hedgewight variant; same body, taller spiked mane |
| `burrow-boar.png` | Boss boar with leaf-mantle + tusks | Missing | Existing boar mesh + leaf-shingle dorsal stack + larger tusks |
| `hedgemother.png` | Boss: bramble-crowned forest hag | **Shipped** (`models/hedgemother.glb`) | — |

## NPCs

| File | Subject | Status | Mesh notes |
|---|---|---|---|
| `npc-hod-tenter.png` | Old Hod, the smith — bald, white beard, leather apron, green tunic | Missing | Stocky body, bald + beard, riveted shoulder pad |
| `npc-quill.png` | Quill, the herbalist — auburn curls, green cloak, log backpack | Missing | Slight build, green cloak hood-down, leaf accents |
| `npc-maud-pennycress.png` | Maud, the cook/matron — silver upswept hair, apron, ladle | Missing | Stocky, ladle in right hand, jug at belt |
| `npc-sir-withering.png` | Sir Withering — older knight with falcon, blue cloak | Missing | Tall, falcon perched on left arm, cape |

## Environment

| File | Subject | Status | Mesh notes |
|---|---|---|---|
| `chartmaker-stone.png` | Standing stone with carved spiral, mossy plinth | Missing | Tall obelisk on stepped plinth + ground inset disk |
| `village-panorama.png` | Three timber-framed cottages with green slate roofs | Reference only | Inform existing cottage GLB tweaks |
| `dungeon-interior-1.png` | Stone block dungeon room, green portal alcove, chest | Reference only | Inform dungeon walls/floor textures + portal |
| `dungeon-interior-2.png` | Dungeon arch with hearth + mossy steps + chest | Reference only | Inform fireplace/arch decor |

## Dummy models awaiting concept art

Per `docs/ASSET_PIPELINE.md` Phase 2B — slugs ending in `_dummy` are placeholders that need real concept art before the next quality pass.

| Slug | Base mesh | What it represents | Concept-art prompt to write |
|---|---|---|---|
| `archer.glb` (current name) | wanderer_v3 + procedural bow/quiver | Player Archer archetype | **Concept landed** — `archer-player.png` (2026-05-01); rebuild via Phase 2A |
| `skitterling` (in spawn pool) | goblin_v2 tinted small | Trivial swarm thorn-fae | Tiny child-of-bramble, hand-sized, glassy eyes, prickle-skin |
| `marshRat` (in spawn pool) | hare_v2 tinted dark | Easy bog rodent | Wet-furred rat with bog-water beading on whiskers, sharp incisors |
| `ironGob` (in spawn pool) | goblin_v2 tinted iron | Medium armored goblin | Goblin in patchwork plate, hammer+helm, sooty face |
| `tuskerSow` (in spawn pool) | boar_v2 scaled up | Hard matriarch boar | Big sow with bog-mud caked on belly, two tusks per side |
| `archer` (enemy) | falcon_v2 perched | Easy ranged enemy | Bramble-fae perched on a thornlimb, drawing a bow of woven vine |
| `charger` (enemy) | boar_v2 dark-tinted | Medium dasher | Black-bristled boar mid-charge, bramble crown, eye-glow |

When a concept lands, the slug graduates: rebuild via Phase 2A, point the loader at the new file, retire the dummy after one cycle.

## Concept art landed 2026-05-01 (awaiting Blender pass)

| Slug | File | Replaces dummy |
|---|---|---|
| `knight-gold` | `docs/concept-art/knight-gold.png` | `knight_gold.glb` (Sun Knight player variant) |
| `druid-dark` | `docs/concept-art/druid-dark.png` | `druid_dark.glb` (Night Druid player variant) |
| `archer-player` | `docs/concept-art/archer-player.png` | `archer.glb` (Archer player base) |
| `wanderer-bard` | `docs/concept-art/wanderer-bard.png` | `wanderer_bard.glb` (Bard player variant) |

## Voice anchors

These all sit at the **storybook / cozy fantasy** end of the spectrum (per `docs/WORLD_BIBLE.md`). When modeling, prioritize:
- **Chunky silhouettes** — readable from 6m at the player camera
- **Mossy / leaf-shingle accents** — the recurring visual language of Bramblewood
- **Painted-toon shading** via `MeshToonMaterial` + the project's 4-step gradient (set in `src/scene/characters.js#toonifyMaterials`)
