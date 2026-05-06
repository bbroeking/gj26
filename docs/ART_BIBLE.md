# Art Bible — Toon-Painted Low-Poly

The visual target for the project. Use the **master style stem** on every
generation; only the **subject** changes. This keeps props, characters, and
environment art consistent.

When in doubt, generate one of the **Hero shots** (below) and ask: "would this
prop / character / tile sit naturally inside that scene?" If yes, ship it. If
no, regenerate.

---

## Master style stem

Always lead with this; only the **subject** changes.

> Stylized low-poly fantasy RPG render in the style of RuneScape 3 meets
> Genshin Impact. Hand-painted toon textures over simple chunky primitive
> geometry. Clean readable silhouette, soft warm key light from upper left,
> cool sky fill, gentle ambient occlusion, faint rim light, painterly
> grass-and-wood materials, no photorealism, no glossy plastic, no
> PBR-metallic look. 3/4 isometric camera, slight downward tilt, square
> aspect ratio, isolated on a neutral cream-grey backdrop. Family-friendly,
> cozy adventure mood.
>
> — **[SUBJECT]** —
>
> Color palette: warm earthy greens, oak browns, burnished gold accents, soft
> rose, bone white. Avoid neon, avoid grayscale, avoid cyberpunk lighting.

**Generator flags:**
- Midjourney: append `--ar 1:1 --stylize 250 --v 7`
- Imagen / Flux / SDXL: drop flags

---

## 1. Hero shots — generate these FIRST

These three set the rules for everything else. Generate 4 variations of each,
pick one favorite per slot, save to `docs/art-refs/hero_*.png`.

### 1a. Lumbridge meadow at golden hour
> A toon-painted low-poly grass meadow with rolling hills, scattered chunky
> oak trees, a wooden split-rail fence, a stone path winding to a small
> thatched cottage, distant blue mountains, a few drifting cumulus clouds, a
> small campfire in the foreground emitting orange embers, warm afternoon
> sun, painterly grass with visible brushstrokes.

### 1b. The cook's kitchen
> A cozy medieval kitchen interior, warm hearth fire on the right, hanging
> copper pots, a wooden table with a clay cooking pot and stacked apples,
> sunlight through a small window, painterly stone walls, no people, low-poly
> props with hand-painted texture.

### 1c. Goblin camp at dusk
> A small low-poly goblin encampment in a clearing, two ragged tents,
> smoldering fire, scattered crude weapons on the ground, twilight sky with
> peach-orange clouds, single torch glowing, no characters in frame,
> hand-painted toon shading.

---

## 2. Characters

Use the master stem. Subject line goes between the dashes. Full body, 3/4
view, neutral cream backdrop.

### Knight (player)
> A young human adventurer in chunky leather armor, red plumed helmet,
> oversized wooden shield, simple iron sword, friendly stylized proportions,
> T-pose, neutral expression, full body 3/4 view, single character on plain
> background.

### Cow
> A cute toon dairy cow, blocky simplified body, large pink snout, big curved
> cream horns, black blob spots, four chunky legs with dark hooves, friendly
> cartoon proportions, side 3/4 view.

### Goblin
> A small green-skinned goblin warrior with a tattered brown loincloth,
> pointed ears, wooden club, mischievous grin, hunched posture, full body 3/4
> view.

### Cook NPC
> A round friendly medieval cook in a white apron and tall puffy chef hat,
> holding a wooden ladle, warm smile, full body 3/4 view.

---

## 3. Items (inventory icons)

Replace the camera line in the stem with:
*centered on a flat soft-grey background, perfectly framed for an inventory icon.*

- A weathered wooden bucket, slight wood grain, iron rim band.
- A simple iron longsword, leather-wrapped grip, slight nicks on the blade.
- A round clay cooking pot with two handles, warm terracotta color.
- A glossy red apple with a single green leaf and tiny stem.
- A raw freshwater trout, silvery scales, painterly highlights.
- A brown leather satchel with a brass buckle.
- A bundle of three golden wheat stalks tied with twine.
- A small healing potion: red liquid in a chunky round glass flask with a cork stopper, faint inner glow.
- A piece of cowhide, rolled up, leather strap binding it.
- A cooked piece of meat on a small wooden skewer, glossy brown crust.
- A wooden tinderbox with iron clasp.
- A rusty iron key with an ornate bow.

---

## 4. Environment props

Single object, isolated, neutral backdrop.

- A chunky stylized oak tree, broad rounded canopy in painterly greens, simple brown trunk, low-poly silhouette.
- A pine tree, conical layered canopy, dark forest-green tones.
- A cluster of three mossy grey boulders.
- A wooden split-rail fence segment, two posts, weathered grain.
- A small lit campfire on a ring of stones, orange flames, faint smoke wisp.
- A medieval iron lantern with warm yellow inner glow.
- A red-cap mushroom and two smaller white-stemmed mushrooms.
- A stone well with a wooden bucket on a rope.
- A simple thatched-roof cottage with cream walls and dark wood timbers.

---

## 5. Tile / material swatches

For matching the world's ground textures.

- A square seamless texture swatch of toon-painted meadow grass with subtle clover and a few yellow wildflowers.
- A square seamless texture of a worn dirt path with embedded round pebbles.
- A square seamless texture of stylized clear blue water with painterly ripples.
- A square seamless texture of light tan beach sand with subtle shell flecks.

---

## 6. Workflow

1. Generate the **3 hero shots** first. Pick a favorite per slot.
2. Compare the three favorites side by side: do they look like the same
   game? If not, refine the stem (shift palette warmer, change lighting
   direction, etc.) before continuing.
3. Once the stem is locked, batch-run the **items** in groups of 4 — they
   come back more stylistically aligned that way.
4. Save final picks under `docs/art-refs/`:
   - `hero_meadow.png`, `hero_kitchen.png`, `hero_goblin_camp.png`
   - `char_knight.png`, `char_cow.png`, `char_goblin.png`, `char_cook.png`
   - `item_<name>.png` for each inventory icon
   - `prop_<name>.png` for environment props
   - `tile_<name>.png` for material swatches
5. Once references exist, the in-game look is matched to them by:
   - recoloring Blender materials in `models/*.blend`
   - retuning lighting / fog / exposure in `src/main.js`
   - rebuilding any prop whose silhouette doesn't match

---

## 7. Locked palette (fill in once hero shots are picked)

After the hero shots are saved, eyedrop the dominant colors and record them
here so future agents and Blender sessions match without guessing.

| Slot              | Hex      | Notes                              |
| ----------------- | -------- | ---------------------------------- |
| Grass (sunlit)    | `#______` |                                    |
| Grass (shadow)    | `#______` |                                    |
| Path / dirt       | `#______` |                                    |
| Water             | `#______` |                                    |
| Tree foliage      | `#______` |                                    |
| Wood (warm)       | `#______` |                                    |
| Stone (grey)      | `#______` |                                    |
| Sky zenith        | `#______` |                                    |
| Sky horizon       | `#______` |                                    |
| Knight red        | `#______` |                                    |
| Gold accent       | `#______` |                                    |

---

## 8. Anti-style — what to reject

If a generation comes back with any of these traits, regenerate:

- Photoreal grass, skin, or fabric
- Hard cel-shade black outlines
- Anime portrait proportions on full-body characters
- Neon or saturated cyberpunk lighting
- Glossy plastic / PBR-metallic finish
- Heavy bloom or HDR halo on bright props
- Pixel-art aliasing on edges
- Busy backgrounds (everything sits on a clean cream-grey)
