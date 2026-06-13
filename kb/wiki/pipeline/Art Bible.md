---
type: pipeline
tags: [art-style, toon, concept-art, ui-kit, visual-style, midjourney]
status: draft
updated: 2026-06-13
sources: ["docs/ART_BIBLE.md", "docs/MODEL_REBUILD_RECIPE.md", "docs/character-pipeline/MODEL_DESCRIPTION_TEMPLATE.md"]
---

# Art Bible

Wayfinder's visual target: stylized low-poly fantasy with hand-painted toon textures, bold readable silhouettes, and a cozy fairytale mood — "RuneScape 3 meets Genshin Impact, Wind Waker cel-shaded storybook look."

> From `feedback_chunky_toon_not_painterly` project memory: **bold ink outlines + flat cel-shaded + sharp edges** — drop "watercolor wash + soft lighting + --style raw". The style is chunky toon, not painterly.

## Master style stem

All concept art generation leads with this. Only the `[SUBJECT]` line changes:

> Stylized low-poly fantasy RPG render in the style of RuneScape 3 meets Genshin Impact. Hand-painted toon textures over simple chunky primitive geometry. Clean readable silhouette, soft warm key light from upper left, cool sky fill, gentle ambient occlusion, faint rim light, painterly grass-and-wood materials, no photorealism, no glossy plastic, no PBR-metallic look. 3/4 isometric camera, slight downward tilt, square aspect ratio, isolated on a neutral cream-grey backdrop. Family-friendly, cozy adventure mood.
>
> — **[SUBJECT]** —
>
> Color palette: warm earthy greens, oak browns, burnished gold accents, soft rose, bone white. Avoid neon, avoid grayscale, avoid cyberpunk lighting.

**Generator flags:** `--ar 1:1 --stylize 250 --v 7` (Midjourney). Drop flags for Imagen / Flux / SDXL.

**Lock rule:** never change the locked stem mid-batch. If the style needs to shift, start a new prompt batch file with a new stem and document why (`docs/concept-art-prompts-*.md`).

## Hero shots (generate first)

These three set the rules for everything else. Generate 4 variations of each, pick one per slot, save to `docs/art-refs/hero_*.png`. All subsequent assets must read as belonging to the same game as these three.

1. **Lumbridge meadow at golden hour** — rolling hills, chunky oak trees, thatched cottage, campfire with orange embers.
2. **The cook's kitchen** — warm hearth, copper pots, wooden table, no people, hand-painted stone walls.
3. **Goblin camp at dusk** — ragged tents, smoldering fire, scattered crude weapons, twilight peach-orange clouds.

## Shape language

| Shape | Reads as | Use for |
|---|---|---|
| Circle | warm, kind, harmless | Maud (cook), Eldra (lampwright), villagers |
| Square / block | stable, solid, trustworthy | Hod (smith), guards, stone-keep NPCs |
| Triangle | sharp, dangerous, fast | Goblins, archers, the Pale Hag, bosses |

Each character: one primary shape + one secondary as a counter-note. Hod = square primary, circle secondary (round head, friendly under the gruff). Eldra = circle primary, triangle accent (lantern flame). See `docs/MODEL_REBUILD_RECIPE.md` for the full design language.

## Silhouette rules

Top-down ARPG camera weights the outline and the head/shoulders. The **thumbnail test**: render at 64×64 black-on-white from the actual game camera angle. If you can't identify the character, redo.

1. Exaggerate the head — chunky cozy uses ~1:4 head:body ratio.
2. One distinct primary shape per character. No two NPCs in the village share their primary shape.
3. Crown the silhouette with one identifying mark — Eldra's lantern, Hod's hammer, the Hedgemother's thorn crown.
4. Tuck arms IN at idle; spread only at attack telegraph.
5. Author the head + crown-prop to stay visible from the ~45° pitch game camera. Hoods that hide the face from above kill recognition.

## Palette discipline

1. **5–8 hues per asset**, never more. More than 8 → muddy at game distance.
2. **One saturation peak per character** — the defining prop. Everything else ≤60% saturation.
3. **Warm light, cool shadow** (or inverse). Never grey-grey. Highlights shift yellow-orange; shadows shift blue-violet.
4. **Implied light: upper-left, ~10–11 o'clock.** All hand-baked highlights match. The in-engine directional light matches.
5. **Shared world palette** — every asset pulls from the same 24–48 swatch set. Lock hexes in this Bible once hero shots are picked.

### Locked palette (fill once hero shots are chosen)

| Slot | Hex | Notes |
|---|---|---|
| Grass (sunlit) | `#______` | |
| Grass (shadow) | `#______` | |
| Path / dirt | `#______` | |
| Water | `#______` | |
| Tree foliage | `#______` | |
| Wood (warm) | `#______` | |
| Stone (grey) | `#______` | |
| Sky zenith | `#______` | |
| Sky horizon | `#______` | |
| Gold accent | `#______` | |

## Asset categories and filing

| Category | Save path | Filename pattern |
|---|---|---|
| Hero shots | `docs/art-refs/` | `hero_<scene>.png` |
| Characters | `docs/art-refs/` | `char_<slug>.png` |
| Inventory icons | `docs/art-refs/` | `item_<name>.png` |
| Environment props | `docs/art-refs/` | `prop_<name>.png` |
| Tile / material swatches | `docs/art-refs/` | `tile_<name>.png` |
| Concept art (primary) | `docs/concept-art/<slug>.png` | |
| Runner-up refs | `docs/art-refs/<slug>_v2.png` | |

## UI kit

The Wayfinder UI Kit (Claude Design project `wayfinder-ui`) produces tokens and styleboxes consumed by `wyrd/scripts/ui/wyrd_ui.gd`. Conventions:

- Ornament lives on **frames and headers**. Body text is plain and high-contrast.
- New frame-like art must pass `wyrd/tools/check_ninepatch.py`.
- Never `load()` a texture first inside `_draw()` — it renders as a white rect forever (project memory: `godot-draw-load-white-texture`). Preload in `_ready`.
- Fonts: **IM Fell** (display / headings), **Caveat** (handwritten / informal). Both in `wyrd/assets/`.

## Anti-style — what to reject

Regenerate if any generation shows:
- Photoreal grass, skin, or fabric
- Hard cel-shade black outlines (we want *inverted-hull* outlines, not baked outlines)
- Anime portrait proportions on full-body characters
- Neon or saturated cyberpunk lighting
- Glossy plastic / PBR-metallic finish
- Heavy bloom or HDR halo on bright props
- Pixel-art aliasing on edges
- Busy backgrounds (everything sits on a clean cream-grey)

## Concept art workflow

1. Generate the 3 hero shots first. Pick one per slot.
2. Compare side by side — do they look like the same game? Refine the stem if not.
3. Once the stem is locked, batch-run items in groups of 4 (more stylistically aligned that way).
4. After references exist, match the in-game look by:
   - Recoloring Blender materials in `models/*.blend`
   - Retuning lighting / fog / exposure in `src/main.js`
   - Rebuilding any prop whose silhouette doesn't match

## Character description template

Before writing any Blender script, create a character description at `docs/character-pipeline/<name>.md` using the template in `docs/character-pipeline/MODEL_DESCRIPTION_TEMPLATE.md`. Required sections: identity, proportions, palette (6–10 named hex colors with material slot names), parts table (one row per authored primitive), rig layout, surface texture approach, outline strategy, validation checklist.

The validation checklist's "reads at NPC distance" check: render at the in-game camera distance (~6m, 30° tilt). Silhouette must identify the character without facial detail.

## See also

- [[Blender Pipeline]] — the Blender-side execution of this visual style
- [[Asset Pipeline]] — how concept art flows into Meshy and then Blender
- [[Bramblewood]] — the world that all art must fit inside
- [[Voice and Tone]] — the narrative register that the art should complement
- [[NPCs]] — the character cast whose designs must stay silhouette-unique

## Sources

- `docs/ART_BIBLE.md`
- `docs/MODEL_REBUILD_RECIPE.md`
- `docs/character-pipeline/MODEL_DESCRIPTION_TEMPLATE.md`
