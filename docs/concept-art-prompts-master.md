# Bramblewood Concept-Art Master Prompt Sheet

Every concept-art prompt for the project, in **one-click-copy** code blocks (locked stem already prepended). Click the copy icon on any block, paste into Midjourney / Imagen / Flux.

## Status legend

| Icon | Meaning |
|---|---|
| ✅ | Concept art shipped (file exists in `docs/concept-art/`) — re-run only if you want a fresh take |
| 🟡 | Game has placeholder/dummy GLB; concept art still **needed** to upgrade |
| 🔴 | No art and no placeholder — fresh build |

## What we already have (don't re-generate)

| Slug | File |
|---|---|
| `knight` | `docs/concept-art/knight.png` |
| `druid` | `docs/concept-art/druid.png` |
| `wanderer` | `docs/concept-art/wanderer.png` (note: Wanderer slot is now Archer — wanderer art still useful as the base silhouette, but the bow-redesign needs new art) |
| Brindlecow | `brindlecow.png` + `brindlecow-with-pack.png` |
| Bramble-Imp | `bramble-imp.png` |
| Hedgewight | `hedgewight.png` (also serves Hedgewolf — same GLB) |
| Wolf Alpha | `wolf-alpha.png` |
| Burrow Boar | `burrow-boar.png` |
| Hedgemother | `hedgemother.png` |
| Hod / Maud / Quill / Sir Withering | 4 NPC PNGs |
| Chartmaker's Stone | `chartmaker-stone.png` |
| Village panorama | `village-panorama.png` (reference only) |
| Dungeon interiors | `dungeon-interior-1.png`, `dungeon-interior-2.png` (reference only) |

Skip these unless you want a re-roll. Everything **🟡** and **🔴** below is what needs fresh art.

**Generation tips:**
- Don't change the locked stem — that's what keeps the storybook tone consistent
- 4 variations is the sweet spot
- If a prompt produces a mismatch on first try, refine the *subject* paragraph (between em-dashes), not the stem
- Save favorite as `docs/concept-art/<slug>.png`, append a row to `INDEX.md`, hand the slug to the engineer

---

# A. Player archetypes (6)

## A1. Knight ✅ — slug `knight`

Already exists at `docs/concept-art/knight.png`. Re-run for a refresh:

```
Stylized low-poly fantasy RPG render in the style of RuneScape 3 meets Genshin Impact. Hand-painted toon textures over simple chunky primitive geometry. Clean readable silhouette, soft warm key light from upper left, cool sky fill, gentle ambient occlusion, faint rim light, painterly grass-and-wood materials, no photorealism, no glossy plastic, no PBR-metallic look. 3/4 isometric camera, slight downward tilt, square aspect ratio, isolated on a neutral cream-grey backdrop. Family-friendly, cozy adventure mood.

— A young human knight, chunky stylized proportions, gleaming centurion-style helmet with a tall red plume, polished olive-bronze breastplate with gold pauldrons, leather belt with metal studs, cream tunic skirt, brown leather boots, short iron sword in right hand, large rounded laurel-rimmed shield in left hand, red cape draping behind shoulders, confident relaxed stance, neutral friendly expression, full body 3/4 view, single character on plain cream backdrop. —

Color palette: warm earthy greens, oak browns, burnished gold accents, soft rose, bone white, deep red plume. Avoid neon, avoid grayscale, avoid cyberpunk lighting. --ar 1:1 --stylize 250 --v 7
```

## A2. Sun Knight ✅ — slug `knight-gold`

Shipped at `docs/concept-art/knight-gold.png` (2026-05-01). Re-run for a refresh:

```
Stylized low-poly fantasy RPG render in the style of RuneScape 3 meets Genshin Impact. Hand-painted toon textures over simple chunky primitive geometry. Clean readable silhouette, soft warm key light from upper left, cool sky fill, gentle ambient occlusion, faint rim light, painterly grass-and-wood materials, no photorealism, no glossy plastic, no PBR-metallic look. 3/4 isometric camera, slight downward tilt, square aspect ratio, isolated on a neutral cream-grey backdrop. Family-friendly, cozy adventure mood.

— A young human Sun-Knight, chunky stylized proportions, gleaming gilded helmet with a sunburst crest in pale gold and a short white plume, polished gold-trimmed breastplate engraved with a sun motif, royal-blue tabard under-tunic showing at the hem, blue cape lined cream draping behind shoulders, gold pauldrons, white leather belt with brass studs, cream linen skirt, dark brown boots with gold buckles, short bright-steel sword in right hand, large round shield with sunburst boss in left hand, calm radiant expression, dawn-knight stance, full body 3/4 view, single character on plain cream backdrop. —

Color palette: pale gold, royal blue, cream linen, bone white, polished silver-steel, hint of warm orange-gold rim. Avoid neon, avoid grayscale, avoid cyberpunk lighting. --ar 1:1 --stylize 250 --v 7
```

## A3. Druid ✅ — slug `druid`

Already exists at `docs/concept-art/druid.png`. Re-run for a refresh:

```
Stylized low-poly fantasy RPG render in the style of RuneScape 3 meets Genshin Impact. Hand-painted toon textures over simple chunky primitive geometry. Clean readable silhouette, soft warm key light from upper left, cool sky fill, gentle ambient occlusion, faint rim light, painterly grass-and-wood materials, no photorealism, no glossy plastic, no PBR-metallic look. 3/4 isometric camera, slight downward tilt, square aspect ratio, isolated on a neutral cream-grey backdrop. Family-friendly, cozy adventure mood.

— A young druid, chunky stylized proportions, soft bramble-green hooded robe with leaf-trim and ivy embroidery, deep moss-green hood pulled back to reveal a brown-haired head wreathed in tiny oak leaves, twisted oak walking staff in right hand topped with a glowing amber orb of bramble-light, simple linen under-tunic in cream, brown leather sandals, faint glowing rune motifs on hem and sleeves, gentle thoughtful expression, full body 3/4 view, single character on plain cream backdrop. —

Color palette: deep moss green, oak brown, soft amber glow accents, cream linen, bone white. Avoid neon, avoid grayscale, avoid cyberpunk lighting. --ar 1:1 --stylize 250 --v 7
```

## A4. Night Druid ✅ — slug `druid-dark`

Shipped at `docs/concept-art/druid-dark.png` (2026-05-01). Re-run for a refresh:

```
Stylized low-poly fantasy RPG render in the style of RuneScape 3 meets Genshin Impact. Hand-painted toon textures over simple chunky primitive geometry. Clean readable silhouette, soft warm key light from upper left, cool sky fill, gentle ambient occlusion, faint rim light, painterly grass-and-wood materials, no photorealism, no glossy plastic, no PBR-metallic look. 3/4 isometric camera, slight downward tilt, square aspect ratio, isolated on a neutral cream-grey backdrop. Family-friendly, cozy adventure mood.

— A young night-druid, chunky stylized proportions, deep indigo-purple hooded robe trimmed with crescent-moon embroidery in silver, hood pulled up shadowing dark-haired head, twisted blackthorn staff in right hand topped with a glowing pale-blue moonstone, midnight-blue tunic underneath, dark leather wraps on forearms, mossy charcoal leather boots, faint silver rune motifs on hem, slightly mysterious yet kind expression, full body 3/4 view, single character on plain cream backdrop. —

Color palette: deep indigo, midnight blue, pale moon-blue glow accents, charcoal grey, silver. Avoid neon, avoid grayscale, avoid cyberpunk lighting. --ar 1:1 --stylize 250 --v 7
```

## A5. Archer ✅ — slug `archer-player`

Shipped at `docs/concept-art/archer-player.png` (2026-05-01). Re-run for a refresh:

```
Stylized low-poly fantasy RPG render in the style of RuneScape 3 meets Genshin Impact. Hand-painted toon textures over simple chunky primitive geometry. Clean readable silhouette, soft warm key light from upper left, cool sky fill, gentle ambient occlusion, faint rim light, painterly grass-and-wood materials, no photorealism, no glossy plastic, no PBR-metallic look. 3/4 isometric camera, slight downward tilt, square aspect ratio, isolated on a neutral cream-grey backdrop. Family-friendly, cozy adventure mood.

— A young hooded ranger archer, chunky stylized proportions, mossy-green forest cloak with leaf-stitch trim, hood pulled half up showing tousled brown hair and alert calm expression, cream linen tunic underneath cinched with a wide leather belt and brass buckle, dark brown trousers, scuffed leather boots, fingerless leather bracers, longbow of warm oak wood with braided cream string held in left hand, three feathered arrows nocked to the string, back quiver of stained leather slung crossbody with five more arrows visible, small leather pouch at hip, leather thumb-ring on right hand, drawn-back ready stance, full body 3/4 view, single character on plain cream backdrop. —

Color palette: mossy forest green, warm oak brown, cream linen, dark leather, cream-fletched arrows, brass accents. Avoid neon, avoid grayscale, avoid cyberpunk lighting. --ar 1:1 --stylize 250 --v 7
```

## A6. Bard ✅ — slug `wanderer-bard`

Shipped at `docs/concept-art/wanderer-bard.png` (2026-05-01). Re-run for a refresh:

```
Stylized low-poly fantasy RPG render in the style of RuneScape 3 meets Genshin Impact. Hand-painted toon textures over simple chunky primitive geometry. Clean readable silhouette, soft warm key light from upper left, cool sky fill, gentle ambient occlusion, faint rim light, painterly grass-and-wood materials, no photorealism, no glossy plastic, no PBR-metallic look. 3/4 isometric camera, slight downward tilt, square aspect ratio, isolated on a neutral cream-grey backdrop. Family-friendly, cozy adventure mood.

— A cheerful young traveling bard named Bridget, chunky stylized proportions, dusty-pink wool hat with a single sky-blue feather, shoulder-length auburn hair with a small braid, kind freckled face with a slight smile, cream linen blouse with gold trim at collar, dusty-pink jerkin laced in front, soft golden-brown trousers tucked into tan boots, wooden lute slung across the back on a braided strap, smaller hand-drum at the hip, small leather pouch of song-coins, gold cord bracelet, full body 3/4 view, single character on plain cream backdrop. —

Color palette: dusty pink, soft gold, cream linen, warm auburn, sky blue. Avoid neon, avoid grayscale, avoid cyberpunk lighting. --ar 1:1 --stylize 250 --v 7
```

---

# B. Enemies (7)

## B1. Skitterling ✅ — slug `enemy-skitterling`

Shipped at `docs/concept-art/enemy-skitterling.png` (2026-05-01). Re-run for a refresh:

```
Stylized low-poly fantasy RPG render in the style of RuneScape 3 meets Genshin Impact. Hand-painted toon textures over simple chunky primitive geometry. Clean readable silhouette, soft warm key light from upper left, cool sky fill, gentle ambient occlusion, faint rim light, painterly grass-and-wood materials, no photorealism, no glossy plastic, no PBR-metallic look. 3/4 isometric camera, slight downward tilt, square aspect ratio, isolated on a neutral cream-grey backdrop. Family-friendly, cozy adventure mood.

— A tiny child-of-bramble Skitterling, chunky stylized proportions but knee-height, glassy black bead eyes, prickle-skin made of tiny thorns, mossy yellow-green tone, hunched insect-fae posture on two short legs, two small clawed hands holding a bramble-stick, half-crooked grin showing tiny fangs, single dried leaf as a cap on the head, full body 3/4 view, single character on plain cream backdrop. —

Color palette: yellow-green moss, dark thorn-brown, glass-black eyes, dried leaf brown. Avoid neon, avoid grayscale, avoid cyberpunk lighting. --ar 1:1 --stylize 250 --v 7
```

## B2. Marsh Rat ✅ — slug `enemy-marsh-rat`

Shipped at `docs/concept-art/enemy-marsh-rat.png` (2026-05-01) — first batch came out feathery, may want a re-roll later:

```
Stylized low-poly fantasy RPG render in the style of RuneScape 3 meets Genshin Impact. Hand-painted toon textures over simple chunky primitive geometry. Clean readable silhouette, soft warm key light from upper left, cool sky fill, gentle ambient occlusion, faint rim light, painterly grass-and-wood materials, no photorealism, no glossy plastic, no PBR-metallic look. 3/4 isometric camera, slight downward tilt, square aspect ratio, isolated on a neutral cream-grey backdrop. Family-friendly, cozy adventure mood.

— A wet-furred bog Marsh Rat, chunky stylized quadruped proportions, dark slate-grey fur with green algae streaks along the spine, pink scaled tail half as long as body, sharp orange incisors, beady wet-looking black eyes, torn ear on one side, droplets of bog-water beading along whiskers, low crouched stance, claws planted in mossy ground, full body side-3/4 view, single creature on plain cream backdrop. —

Color palette: slate-grey, algae green, pink scaled tail, orange tooth, muddy brown paws. Avoid neon, avoid grayscale, avoid cyberpunk lighting. --ar 1:1 --stylize 250 --v 7
```

## B3. Iron Gob ✅ — slug `enemy-iron-gob`

Shipped at `docs/concept-art/enemy-iron-gob.png` (2026-05-01). Re-run for a refresh:

```
Stylized low-poly fantasy RPG render in the style of RuneScape 3 meets Genshin Impact. Hand-painted toon textures over simple chunky primitive geometry. Clean readable silhouette, soft warm key light from upper left, cool sky fill, gentle ambient occlusion, faint rim light, painterly grass-and-wood materials, no photorealism, no glossy plastic, no PBR-metallic look. 3/4 isometric camera, slight downward tilt, square aspect ratio, isolated on a neutral cream-grey backdrop. Family-friendly, cozy adventure mood.

— An armored Iron Gob, chunky stylized goblin proportions but heavier than a normal goblin, sooty olive-grey skin, riveted patchwork iron plate breastplate, asymmetric pauldron only on the right shoulder, dented iron helm with a single horn-spike, gauntlets with bandage wraps, big two-handed forge hammer resting on shoulder, planted heavy-footed stance, dim gleaming red eyes peering from helm shadow, mismatched leather boots, full body 3/4 view, single character on plain cream backdrop. —

Color palette: dark iron-grey, soot black, dim ember-red eye glow, olive goblin skin, leather brown. Avoid neon, avoid grayscale, avoid cyberpunk lighting. --ar 1:1 --stylize 250 --v 7
```

## B4. Tusker Sow ✅ — slug `enemy-tusker-sow`

Shipped at `docs/concept-art/enemy-tusker-sow.png` (2026-05-01). Re-run for a refresh:

```
Stylized low-poly fantasy RPG render in the style of RuneScape 3 meets Genshin Impact. Hand-painted toon textures over simple chunky primitive geometry. Clean readable silhouette, soft warm key light from upper left, cool sky fill, gentle ambient occlusion, faint rim light, painterly grass-and-wood materials, no photorealism, no glossy plastic, no PBR-metallic look. 3/4 isometric camera, slight downward tilt, square aspect ratio, isolated on a neutral cream-grey backdrop. Family-friendly, cozy adventure mood.

— A massive matriarch Tusker Sow, chunky stylized boar proportions but a third bigger than a regular boar, dark mossy-brown bristled fur, two huge yellowing tusks per side curving up, bog-mud caked along the belly and flanks, small sharp eyes, leaf-mantle of mossy fronds along the back, clumps of wet reeds caught in her bristles, planted heavy stance, all four hooves visible on the ground, full body side-3/4 view, single creature on plain cream backdrop. —

Color palette: dark mossy brown, yellow-bone tusk, bog-mud charcoal, mossy green leaf-mantle, glassy black eye. Avoid neon, avoid grayscale, avoid cyberpunk lighting. --ar 1:1 --stylize 250 --v 7
```

## B5. Bramble Archer ✅ — slug `enemy-bramble-archer`

Shipped at `docs/concept-art/enemy-bramble-archer.png` (2026-05-01). Re-run for a refresh:

```
Stylized low-poly fantasy RPG render in the style of RuneScape 3 meets Genshin Impact. Hand-painted toon textures over simple chunky primitive geometry. Clean readable silhouette, soft warm key light from upper left, cool sky fill, gentle ambient occlusion, faint rim light, painterly grass-and-wood materials, no photorealism, no glossy plastic, no PBR-metallic look. 3/4 isometric camera, slight downward tilt, square aspect ratio, isolated on a neutral cream-grey backdrop. Family-friendly, cozy adventure mood.

— A perched Bramble Archer, a small thorn-fae with crow-like proportions standing on a thorny branch, dusty-brown feathered cloak, hood-mask of woven thorns showing only sharp glassy black eyes, drawn shortbow made of twisted vine with a leaf-fletch arrow nocked, quiver of green arrows on back, short leathery talons gripping the branch, body crouched and balanced, full body 3/4 view, single creature on a small thorny perch on plain cream backdrop. —

Color palette: dusty feather brown, dark thorn green, glassy black eyes, warm vine wood, leaf-green fletching. Avoid neon, avoid grayscale, avoid cyberpunk lighting. --ar 1:1 --stylize 250 --v 7
```

## B6. Bramble Charger ✅ — slug `enemy-bramble-charger`

Shipped at `docs/concept-art/enemy-bramble-charger.png` (2026-05-01). Re-run for a refresh:

```
Stylized low-poly fantasy RPG render in the style of RuneScape 3 meets Genshin Impact. Hand-painted toon textures over simple chunky primitive geometry. Clean readable silhouette, soft warm key light from upper left, cool sky fill, gentle ambient occlusion, faint rim light, painterly grass-and-wood materials, no photorealism, no glossy plastic, no PBR-metallic look. 3/4 isometric camera, slight downward tilt, square aspect ratio, isolated on a neutral cream-grey backdrop. Family-friendly, cozy adventure mood.

— A black-bristled Bramble Charger, chunky stylized boar proportions mid-charge, glossy charcoal-black fur with green-bramble crown growing through the shoulders and neck, two sharp pale tusks, glowing amber eyes narrowed for the charge, front legs braced and rear legs kicked back as if mid-leap, mud and leaves spraying from hooves, mossy green saddle of brambles along the spine, full body side view in motion, single creature on plain cream backdrop. —

Color palette: charcoal black, mossy green bramble crown, pale ivory tusks, glowing amber eyes, muddy hoof-spray. Avoid neon, avoid grayscale, avoid cyberpunk lighting. --ar 1:1 --stylize 250 --v 7
```

## B7. Hedgewolf ✅ — slug `enemy-hedge-wolf`

Already covered by `hedgewight.png` (same GLB used). Re-run if you want a wolf-specific take:

```
Stylized low-poly fantasy RPG render in the style of RuneScape 3 meets Genshin Impact. Hand-painted toon textures over simple chunky primitive geometry. Clean readable silhouette, soft warm key light from upper left, cool sky fill, gentle ambient occlusion, faint rim light, painterly grass-and-wood materials, no photorealism, no glossy plastic, no PBR-metallic look. 3/4 isometric camera, slight downward tilt, square aspect ratio, isolated on a neutral cream-grey backdrop. Family-friendly, cozy adventure mood.

— A predator Hedgewolf, chunky stylized wolf proportions, ash-grey fur woven through with bramble vines, two short blackthorn antlers behind the ears, glowing amber eyes, long forelimbs, leaf-shingle armor along shoulders and back, prowling low pose, lips slightly drawn back showing teeth, body half in shadow, full body side-3/4 view, single creature on plain cream backdrop. —

Color palette: ash-grey fur, deep moss-green leaf shingles, blackthorn brown antlers, amber glowing eyes. Avoid neon, avoid grayscale, avoid cyberpunk lighting. --ar 1:1 --stylize 250 --v 7
```

---

# C. Weapons by tier (12) ✅

All 12 shipped 2026-05-01 to `docs/concept-art/weapon-{brindle,bogiron,cinderbloom}-{sword,axe,dagger,pickaxe}.png`. Re-roll any individual entry if you want a fresh take.

## C1. Brindle Sword — slug `weapon-brindle-sword`

```
Stylized low-poly fantasy RPG item render in the style of RuneScape 3 meets Genshin Impact. Hand-painted toon textures over simple chunky primitive geometry. Clean readable silhouette, soft key light from upper left, gentle ambient occlusion, painterly wood-and-metal materials, no photorealism, no glossy plastic. Single object floating against a neutral cream backdrop, 3/4 top-down icon angle, slight drop shadow under the object.

— A stylized Brindle Sword: short broadsword with a warm-tan brindle-bronze blade with subtle dappled markings, simple oak crossguard wrapped in cream leather grip, brass pommel cap engraved with a small leaf sigil, leather strap dangling from pommel. Single weapon, no character. —

Color palette: warm brindle-tan, oak brown, cream leather, brass. --ar 1:1 --stylize 250 --v 7
```

## C2. Brindle Axe — slug `weapon-brindle-axe`

```
Stylized low-poly fantasy RPG item render in the style of RuneScape 3 meets Genshin Impact. Hand-painted toon textures over simple chunky primitive geometry. Clean readable silhouette, soft key light from upper left, gentle ambient occlusion, painterly wood-and-metal materials, no photorealism, no glossy plastic. Single object floating against a neutral cream backdrop, 3/4 top-down icon angle, slight drop shadow under the object.

— A stylized Brindle Axe: short woodcutter's axe with a warm brindle-bronze head, oak haft wrapped at the grip with cream leather, brass cap on the butt, single object angle, faint nicks on the blade edge for lived-in feel. Single weapon, no character. —

Color palette: warm brindle-tan, oak haft, cream leather, brass. --ar 1:1 --stylize 250 --v 7
```

## C3. Brindle Dagger — slug `weapon-brindle-dagger`

```
Stylized low-poly fantasy RPG item render in the style of RuneScape 3 meets Genshin Impact. Hand-painted toon textures over simple chunky primitive geometry. Clean readable silhouette, soft key light from upper left, gentle ambient occlusion, painterly wood-and-metal materials, no photorealism, no glossy plastic. Single object floating against a neutral cream backdrop, 3/4 top-down icon angle, slight drop shadow under the object.

— A stylized Brindle Dagger: short pointed blade in warm brindle-bronze with a subtle dappled finish, simple oak crossguard, cream leather wrap on grip, brass pommel pin, leather wrist-thong. Single weapon, no character. —

Color palette: warm brindle-tan, oak brown, cream leather. --ar 1:1 --stylize 250 --v 7
```

## C4. Brindle Pickaxe — slug `weapon-brindle-pickaxe`

```
Stylized low-poly fantasy RPG item render in the style of RuneScape 3 meets Genshin Impact. Hand-painted toon textures over simple chunky primitive geometry. Clean readable silhouette, soft key light from upper left, gentle ambient occlusion, painterly wood-and-metal materials, no photorealism, no glossy plastic. Single object floating against a neutral cream backdrop, 3/4 top-down icon angle, slight drop shadow under the object.

— A stylized Brindle Pickaxe (mining tool): single-pointed mining pick in warm brindle-bronze head, oak haft, cream leather grip-wrap, slight chips along the point from use. Single object angle. —

Color palette: warm brindle-tan, oak brown, cream leather. --ar 1:1 --stylize 250 --v 7
```

## C5. Bogiron Sword — slug `weapon-bogiron-sword`

```
Stylized low-poly fantasy RPG item render in the style of RuneScape 3 meets Genshin Impact. Hand-painted toon textures over simple chunky primitive geometry. Clean readable silhouette, soft key light from upper left, gentle ambient occlusion, painterly wood-and-metal materials, no photorealism, no glossy plastic. Single object floating against a neutral cream backdrop, 3/4 top-down icon angle, slight drop shadow under the object.

— A stylized Bogiron Sword: medium-length straight blade in dark rusty bog-iron with peat-stained pitting, hand-forged crossguard with a leaf motif, warm dark-leather grip, copper pommel with a single hammered rivet. Single weapon, no character. —

Color palette: rusty bog-iron, dark moss green tint, oak grip, hammered copper. --ar 1:1 --stylize 250 --v 7
```

## C6. Bogiron Axe — slug `weapon-bogiron-axe`

```
Stylized low-poly fantasy RPG item render in the style of RuneScape 3 meets Genshin Impact. Hand-painted toon textures over simple chunky primitive geometry. Clean readable silhouette, soft key light from upper left, gentle ambient occlusion, painterly wood-and-metal materials, no photorealism, no glossy plastic. Single object floating against a neutral cream backdrop, 3/4 top-down icon angle, slight drop shadow under the object.

— A stylized Bogiron Axe: heavy single-bit axe head in rust-mottled bog iron, dark oak haft with copper bands at top and bottom, leather wrap on grip, slight green moss in the rivet seams. Single weapon. —

Color palette: bog-iron rust, oak haft, copper bands, hint of moss green. --ar 1:1 --stylize 250 --v 7
```

## C7. Bogiron Dagger — slug `weapon-bogiron-dagger`

```
Stylized low-poly fantasy RPG item render in the style of RuneScape 3 meets Genshin Impact. Hand-painted toon textures over simple chunky primitive geometry. Clean readable silhouette, soft key light from upper left, gentle ambient occlusion, painterly wood-and-metal materials, no photorealism, no glossy plastic. Single object floating against a neutral cream backdrop, 3/4 top-down icon angle, slight drop shadow under the object.

— A stylized Bogiron Dagger: short curved blade in pitted bog-iron, oak crossguard, dark-leather grip, copper pommel cap with a hedge-rose stamp. Single weapon. —

Color palette: bog-iron rust, oak, dark leather, hammered copper. --ar 1:1 --stylize 250 --v 7
```

## C8. Bogiron Pickaxe — slug `weapon-bogiron-pickaxe`

```
Stylized low-poly fantasy RPG item render in the style of RuneScape 3 meets Genshin Impact. Hand-painted toon textures over simple chunky primitive geometry. Clean readable silhouette, soft key light from upper left, gentle ambient occlusion, painterly wood-and-metal materials, no photorealism, no glossy plastic. Single object floating against a neutral cream backdrop, 3/4 top-down icon angle, slight drop shadow under the object.

— A stylized Bogiron Pickaxe: heavier mining pick than the brindle, head in pitted bog iron with a moss-green wash in the seams, dark oak haft with copper bands, leather grip. Single object. —

Color palette: bog-iron rust, oak, copper, mossy green. --ar 1:1 --stylize 250 --v 7
```

## C9. Cinderbloom Sword — slug `weapon-cinderbloom-sword`

```
Stylized low-poly fantasy RPG item render in the style of RuneScape 3 meets Genshin Impact. Hand-painted toon textures over simple chunky primitive geometry. Clean readable silhouette, soft key light from upper left, gentle ambient occlusion, painterly wood-and-metal materials, no photorealism, no glossy plastic. Single object floating against a neutral cream backdrop, 3/4 top-down icon angle, slight drop shadow under the object.

— A stylized Cinderbloom Sword: long straight blade of dark steel with a glowing pink ember-line running down the fuller, the blade tip showing a faint cinder glow, blackened cross-guard with embered details, deep red-black leather grip wrapped in spiral, gold pommel cap shaped like a closed flower bud about to bloom. Single weapon, no character. —

Color palette: dark steel, pink-ember glow, black-leather, gold-bud pommel. --ar 1:1 --stylize 250 --v 7
```

## C10. Cinderbloom Axe — slug `weapon-cinderbloom-axe`

```
Stylized low-poly fantasy RPG item render in the style of RuneScape 3 meets Genshin Impact. Hand-painted toon textures over simple chunky primitive geometry. Clean readable silhouette, soft key light from upper left, gentle ambient occlusion, painterly wood-and-metal materials, no photorealism, no glossy plastic. Single object floating against a neutral cream backdrop, 3/4 top-down icon angle, slight drop shadow under the object.

— A stylized Cinderbloom Axe: large single-bit axe head in dark steel with glowing pink ember-veins along the cutting edge, blackened oak haft, gold band at the grip, leather wrap, slight steam-glow rising from the head. Single weapon. —

Color palette: dark steel, pink-ember, blackened oak, gold band. --ar 1:1 --stylize 250 --v 7
```

## C11. Cinderbloom Dagger — slug `weapon-cinderbloom-dagger`

```
Stylized low-poly fantasy RPG item render in the style of RuneScape 3 meets Genshin Impact. Hand-painted toon textures over simple chunky primitive geometry. Clean readable silhouette, soft key light from upper left, gentle ambient occlusion, painterly wood-and-metal materials, no photorealism, no glossy plastic. Single object floating against a neutral cream backdrop, 3/4 top-down icon angle, slight drop shadow under the object.

— A stylized Cinderbloom Dagger: short curved blade in dark steel with a pink ember edge, blackened crossguard, deep red leather grip, small gold flower-bud pommel. Single weapon. —

Color palette: dark steel, pink-ember edge, blackened metal, deep red, gold. --ar 1:1 --stylize 250 --v 7
```

## C12. Cinderbloom Pickaxe — slug `weapon-cinderbloom-pickaxe`

```
Stylized low-poly fantasy RPG item render in the style of RuneScape 3 meets Genshin Impact. Hand-painted toon textures over simple chunky primitive geometry. Clean readable silhouette, soft key light from upper left, gentle ambient occlusion, painterly wood-and-metal materials, no photorealism, no glossy plastic. Single object floating against a neutral cream backdrop, 3/4 top-down icon angle, slight drop shadow under the object.

— A stylized Cinderbloom Pickaxe: heavy mining pick with a dark-steel double-pointed head, glowing pink ember running through both points, blackened oak haft, gold band, leather grip. Single object. —

Color palette: dark steel, pink-ember, blackened oak, gold. --ar 1:1 --stylize 250 --v 7
```

---

# D. Shields (3) ✅

All 3 shipped 2026-05-01 to `docs/concept-art/shield-{wooden,bogiron,cinderbloom}.png`. Re-roll any individual entry if you want a fresh take.

## D1. Wooden Shield — slug `shield-wooden`

```
Stylized low-poly fantasy RPG item render in the style of RuneScape 3 meets Genshin Impact. Hand-painted toon textures over simple chunky primitive geometry. Clean readable silhouette, soft key light from upper left, gentle ambient occlusion, painterly wood-and-metal materials, no photorealism, no glossy plastic. Single object floating against a neutral cream backdrop, 3/4 top-down icon angle, slight drop shadow under the object.

— A stylized Wooden Shield: round buckler made of plank-and-iron-band construction, four oak planks visible with cream leather lashings at the seams, two iron rim-bands top and bottom, central iron boss hammered like a sun, leather grip on the back partly visible, slight nicks and scuffs suggesting use. Single object, front 3/4 angle. —

Color palette: warm oak, cream leather, dark iron, brass rivet highlights. --ar 1:1 --stylize 250 --v 7
```

## D2. Bogiron Shield — slug `shield-bogiron`

```
Stylized low-poly fantasy RPG item render in the style of RuneScape 3 meets Genshin Impact. Hand-painted toon textures over simple chunky primitive geometry. Clean readable silhouette, soft key light from upper left, gentle ambient occlusion, painterly wood-and-metal materials, no photorealism, no glossy plastic. Single object floating against a neutral cream backdrop, 3/4 top-down icon angle, slight drop shadow under the object.

— A stylized Bogiron Shield: heater-shape shield with a dark-stained oak back, full bogiron face plate showing peat-pitted texture, riveted iron rim, central boss in the shape of a moss-bramble crest, copper edge studs, leather grip on the back. Front 3/4 angle. —

Color palette: bog-iron rust, dark oak, copper studs, mossy green crest. --ar 1:1 --stylize 250 --v 7
```

## D3. Cinderbloom Shield — slug `shield-cinderbloom`

```
Stylized low-poly fantasy RPG item render in the style of RuneScape 3 meets Genshin Impact. Hand-painted toon textures over simple chunky primitive geometry. Clean readable silhouette, soft key light from upper left, gentle ambient occlusion, painterly wood-and-metal materials, no photorealism, no glossy plastic. Single object floating against a neutral cream backdrop, 3/4 top-down icon angle, slight drop shadow under the object.

— A stylized Cinderbloom Shield: kite-shape shield in dark steel with a glowing pink ember-line running diagonally across the face, gold-trim border, central blackened-rose embossed flower, gold rivet studs at the corners, deep red leather grip on the back. Front 3/4 angle. —

Color palette: dark steel, glowing pink ember, gold trim, deep red, black-rose. --ar 1:1 --stylize 250 --v 7
```

---

# E. Armor (4) ✅

All 4 shipped 2026-05-01 to `docs/concept-art/armor-{leather-body,bogiron-cuirass,cinderbloom-plate,cinderbloom-helm}.png`. Re-roll any individual entry if you want a fresh take.

## E1. Leather Body — slug `armor-leather-body`

```
Stylized low-poly fantasy RPG item render in the style of RuneScape 3 meets Genshin Impact. Hand-painted toon textures over simple chunky primitive geometry. Clean readable silhouette, soft key light from upper left, gentle ambient occlusion, painterly wood-and-metal materials, no photorealism, no glossy plastic. Single object floating against a neutral cream backdrop, 3/4 top-down icon angle, slight drop shadow under the object.

— A stylized Leather Body chest armor: simple boiled-leather cuirass in warm tan, cream linen shirt visible at neck and sleeve cuffs, dark leather straps and brass buckles, padded shoulders, slight worn-in creasing at the sides. Front-facing icon angle, no character. —

Color palette: warm tan leather, cream linen, brass, dark leather straps. --ar 1:1 --stylize 250 --v 7
```

## E2. Bogiron Cuirass — slug `armor-bogiron-cuirass`

```
Stylized low-poly fantasy RPG item render in the style of RuneScape 3 meets Genshin Impact. Hand-painted toon textures over simple chunky primitive geometry. Clean readable silhouette, soft key light from upper left, gentle ambient occlusion, painterly wood-and-metal materials, no photorealism, no glossy plastic. Single object floating against a neutral cream backdrop, 3/4 top-down icon angle, slight drop shadow under the object.

— A stylized Bogiron Cuirass: hand-forged plate breastplate in pitted bog-iron, riveted shoulder straps in dark leather, copper buckles, a hammered moss-bramble crest at the chest, slight verdigris in the seams, front-facing icon angle. —

Color palette: bog-iron rust, dark leather, copper, faint verdigris green. --ar 1:1 --stylize 250 --v 7
```

## E3. Cinderbloom Plate — slug `armor-cinderbloom-plate`

```
Stylized low-poly fantasy RPG item render in the style of RuneScape 3 meets Genshin Impact. Hand-painted toon textures over simple chunky primitive geometry. Clean readable silhouette, soft key light from upper left, gentle ambient occlusion, painterly wood-and-metal materials, no photorealism, no glossy plastic. Single object floating against a neutral cream backdrop, 3/4 top-down icon angle, slight drop shadow under the object.

— A stylized Cinderbloom Plate breastplate: dark-steel plate with glowing pink ember-veins tracing rose-vine engravings across the chest, gold trim on collar and sleeve cuffs, deep red leather straps, gold buckles, faint heat-glow from seams. Front-facing icon angle. —

Color palette: dark steel, pink-ember vein, gold trim, deep red leather. --ar 1:1 --stylize 250 --v 7
```

## E4. Cinderbloom Helm — slug `armor-cinderbloom-helm`

```
Stylized low-poly fantasy RPG item render in the style of RuneScape 3 meets Genshin Impact. Hand-painted toon textures over simple chunky primitive geometry. Clean readable silhouette, soft key light from upper left, gentle ambient occlusion, painterly wood-and-metal materials, no photorealism, no glossy plastic. Single object floating against a neutral cream backdrop, 3/4 top-down icon angle, slight drop shadow under the object.

— A stylized Cinderbloom Helm: dark-steel close helm with a sweeping gold crest in the shape of a flame-tongue, glowing pink ember running along the brow line, narrow visor slit, gold trim around the cheek-guards, deep red inner padding visible. Front 3/4 icon angle. —

Color palette: dark steel, gold flame crest, pink-ember glow, deep red padding. --ar 1:1 --stylize 250 --v 7
```

---

# F. Quest items (9) ✅

All 9 shipped 2026-05-01 to `docs/concept-art/item-{apprentice-hammer,falcons-whistle,thorn-crown,quill-atlas,anvil-token,healing-draught,pantry-stew,whickerhares-foot,bramble-resin}.png`. Re-roll any individual entry if you want a fresh take.

## F1. Apprentice Hammer — slug `item-apprentice-hammer`

```
Stylized low-poly fantasy RPG item render in the style of RuneScape 3 meets Genshin Impact. Hand-painted toon textures over simple chunky primitive geometry. Clean readable silhouette, soft key light from upper left, gentle ambient occlusion, painterly wood-and-metal materials, no photorealism, no glossy plastic. Single object floating against a neutral cream backdrop, 3/4 top-down icon angle, slight drop shadow under the object.

— A stylized Apprentice Hammer: short oak-handled smith hammer with a warm bronze head (one flat face, one slight peen), cream leather grip, brass cap on pommel, a forge-spark or two trailing the head as if just lifted. Single object icon. —

Color palette: warm bronze, oak, cream leather, brass. --ar 1:1 --stylize 250 --v 7
```

## F2. Falcon's Whistle — slug `item-falcons-whistle`

```
Stylized low-poly fantasy RPG item render in the style of RuneScape 3 meets Genshin Impact. Hand-painted toon textures over simple chunky primitive geometry. Clean readable silhouette, soft key light from upper left, gentle ambient occlusion, painterly wood-and-metal materials, no photorealism, no glossy plastic. Single object floating against a neutral cream backdrop, 3/4 top-down icon angle, slight drop shadow under the object.

— A stylized Falcon's Whistle: short bone whistle on a braided leather cord with three feather charms (one cream-white, one barred brown, one black-tipped), small brass mouthpiece ring, slight engraved feather pattern on the bone. Single object icon. —

Color palette: bone white, braided leather brown, brass, three feather charms (cream / brown / black). --ar 1:1 --stylize 250 --v 7
```

## F3. Thorn Crown — slug `item-thorn-crown`

```
Stylized low-poly fantasy RPG item render in the style of RuneScape 3 meets Genshin Impact. Hand-painted toon textures over simple chunky primitive geometry. Clean readable silhouette, soft key light from upper left, gentle ambient occlusion, painterly wood-and-metal materials, no photorealism, no glossy plastic. Single object floating against a neutral cream backdrop, 3/4 top-down icon angle, slight drop shadow under the object.

— A stylized Thorn Crown: circlet of black-iron thorns interlaced with dried bramble vines, a single drop of dried red sap on the front spike, silver glinted highlights on the thorn tips, soft drop-shadow underneath. Single object icon. —

Color palette: black iron, deep wine-red sap, dried bramble brown, silver highlight. --ar 1:1 --stylize 250 --v 7
```

## F4. Quill's Field Atlas — slug `item-quill-atlas`

```
Stylized low-poly fantasy RPG item render in the style of RuneScape 3 meets Genshin Impact. Hand-painted toon textures over simple chunky primitive geometry. Clean readable silhouette, soft key light from upper left, gentle ambient occlusion, painterly wood-and-metal materials, no photorealism, no glossy plastic. Single object floating against a neutral cream backdrop, 3/4 top-down icon angle, slight drop shadow under the object.

— A stylized Field Atlas: small leather-bound book stamped with a leaf sigil, brass corner caps, ribbon bookmark, slightly fanned pages showing botanical sketches of bramble flowers, a feathered quill resting on top. Single object icon. —

Color palette: deep leaf-green leather, brass, cream pages, ink-blue sketches. --ar 1:1 --stylize 250 --v 7
```

## F5. Hod's Anvil Token — slug `item-anvil-token`

```
Stylized low-poly fantasy RPG item render in the style of RuneScape 3 meets Genshin Impact. Hand-painted toon textures over simple chunky primitive geometry. Clean readable silhouette, soft key light from upper left, gentle ambient occlusion, painterly wood-and-metal materials, no photorealism, no glossy plastic. Single object floating against a neutral cream backdrop, 3/4 top-down icon angle, slight drop shadow under the object.

— A stylized Anvil Token: small bronze coin with an anvil-and-hammer relief on the front, hole at the top with a worn cream cord through it, slight patina in the engraving. Single object icon. —

Color palette: bronze, patina-green, cream cord. --ar 1:1 --stylize 250 --v 7
```

## F6. Healing Draught — slug `item-healing-draught`

```
Stylized low-poly fantasy RPG item render in the style of RuneScape 3 meets Genshin Impact. Hand-painted toon textures over simple chunky primitive geometry. Clean readable silhouette, soft key light from upper left, gentle ambient occlusion, painterly wood-and-metal materials, no photorealism, no glossy plastic. Single object floating against a neutral cream backdrop, 3/4 top-down icon angle, slight drop shadow under the object.

— A stylized Healing Draught: small round-bottomed glass bottle with a glowing soft-pink liquid inside, a cork stopper sealed with cream wax, a hand-tied tag on the neck reading 'D' in inked script. Single object icon. —

Color palette: pale rose-pink glow, glass, cream wax, brown tag string. --ar 1:1 --stylize 250 --v 7
```

## F7. Pantry Stew — slug `item-pantry-stew`

```
Stylized low-poly fantasy RPG item render in the style of RuneScape 3 meets Genshin Impact. Hand-painted toon textures over simple chunky primitive geometry. Clean readable silhouette, soft key light from upper left, gentle ambient occlusion, painterly wood-and-metal materials, no photorealism, no glossy plastic. Single object floating against a neutral cream backdrop, 3/4 top-down icon angle, slight drop shadow under the object.

— A stylized Pantry Stew: small wooden bowl filled with thick golden-brown stew, a single visible chunk of carrot and a sprig of green herb, a wooden spoon resting in the bowl, slight steam line rising. Single object icon. —

Color palette: warm wood, golden stew, orange carrot, herb green, wisp white. --ar 1:1 --stylize 250 --v 7
```

## F8. Whickerhare's Foot — slug `item-whickerhares-foot`

```
Stylized low-poly fantasy RPG item render in the style of RuneScape 3 meets Genshin Impact. Hand-painted toon textures over simple chunky primitive geometry. Clean readable silhouette, soft key light from upper left, gentle ambient occlusion, painterly wood-and-metal materials, no photorealism, no glossy plastic. Single object floating against a neutral cream backdrop, 3/4 top-down icon angle, slight drop shadow under the object.

— A stylized Whickerhare's Foot Charm: a single tan rabbit's foot with braided cream cord wrapped at the cut end, three tiny brass rings woven into the cord, a small painted blue bead at the tip. Single object icon. —

Color palette: tan fur, cream braid, brass, blue bead. --ar 1:1 --stylize 250 --v 7
```

## F9. Bramble Resin — slug `item-bramble-resin`

```
Stylized low-poly fantasy RPG item render in the style of RuneScape 3 meets Genshin Impact. Hand-painted toon textures over simple chunky primitive geometry. Clean readable silhouette, soft key light from upper left, gentle ambient occlusion, painterly wood-and-metal materials, no photorealism, no glossy plastic. Single object floating against a neutral cream backdrop, 3/4 top-down icon angle, slight drop shadow under the object.

— A stylized Bramble Resin clump: a small lump of translucent amber-orange sap with tiny bramble-leaf bits suspended inside, slight glow from within, pinch of dried thorns clinging to the bottom. Single object icon. —

Color palette: amber-orange, leaf green flecks, dark thorn brown. --ar 1:1 --stylize 250 --v 7
```

---

# G. Cartography props (5) ✅

All 5 shipped 2026-05-01 to `docs/concept-art/item-{chart-blank,surveyor-pole,cartographer-compass,master-chart}.png` and `docs/concept-art/prop-waypoint-cairn.png`. Re-roll any individual entry if you want a fresh take.

## G1. Blank Chart — slug `item-chart-blank`

```
Stylized low-poly fantasy RPG item render in the style of RuneScape 3 meets Genshin Impact. Hand-painted toon textures over simple chunky primitive geometry. Clean readable silhouette, soft key light from upper left, gentle ambient occlusion, painterly wood-and-metal materials, no photorealism, no glossy plastic. Single object floating against a neutral cream backdrop, 3/4 top-down icon angle, slight drop shadow under the object.

— A stylized Blank Chart: folded parchment on a worn wooden plank, edges browned, two iron weights at the corners, faint grid lines visible, an unrolled corner showing a fresh quill mark. Single object icon. —

Color palette: cream parchment, browned edges, dark iron, oak plank. --ar 1:1 --stylize 250 --v 7
```

## G2. Surveyor's Pole — slug `item-surveyor-pole`

```
Stylized low-poly fantasy RPG item render in the style of RuneScape 3 meets Genshin Impact. Hand-painted toon textures over simple chunky primitive geometry. Clean readable silhouette, soft key light from upper left, gentle ambient occlusion, painterly wood-and-metal materials, no photorealism, no glossy plastic. Single object floating against a neutral cream backdrop, 3/4 top-down icon angle, slight drop shadow under the object.

— A stylized Surveyor's Pole: tall striped wooden stake with red and cream bands, brass plumb-bob hanging from a leather strap at the tip, slight mud at the bottom from being planted in earth. Single object icon. —

Color palette: cream-and-red striped wood, brass plumb, leather strap. --ar 1:1 --stylize 250 --v 7
```

## G3. Cartographer's Compass — slug `item-cartographer-compass`

```
Stylized low-poly fantasy RPG item render in the style of RuneScape 3 meets Genshin Impact. Hand-painted toon textures over simple chunky primitive geometry. Clean readable silhouette, soft key light from upper left, gentle ambient occlusion, painterly wood-and-metal materials, no photorealism, no glossy plastic. Single object floating against a neutral cream backdrop, 3/4 top-down icon angle, slight drop shadow under the object.

— A stylized Cartographer's Compass: open brass compass on a worn leather travel-map, ink quill beside it, half-drunk glass inkpot, candle stub casting warm light. Top-down icon angle. —

Color palette: brass compass, sepia map, ink-blue, candle warm-yellow. --ar 1:1 --stylize 250 --v 7
```

## G4. Master Chart — slug `item-master-chart`

```
Stylized low-poly fantasy RPG item render in the style of RuneScape 3 meets Genshin Impact. Hand-painted toon textures over simple chunky primitive geometry. Clean readable silhouette, soft key light from upper left, gentle ambient occlusion, painterly wood-and-metal materials, no photorealism, no glossy plastic. Single object floating against a neutral cream backdrop, 3/4 top-down icon angle, slight drop shadow under the object.

— A stylized Master Chart of the Bramblewood Valley: large unfurled vellum map showing rivers, hills, hand-illuminated ornaments in each corner (oak tree / wolf / well / sun), wax seal in the center, inked hand lines connecting waypoints. Top-down icon angle. —

Color palette: cream vellum, sepia ink, wax seal red, gold leaf ornament. --ar 1:1 --stylize 250 --v 7
```

## G5. Waypoint Cairn — slug `prop-waypoint-cairn`

```
Stylized low-poly fantasy RPG render in the style of RuneScape 3 meets Genshin Impact. Hand-painted toon textures over simple chunky primitive geometry. Clean readable silhouette, soft warm key light from upper left, cool sky fill, gentle ambient occlusion, faint rim light, painterly grass-and-wood materials, no photorealism, no glossy plastic, no PBR-metallic look. 3/4 isometric camera, slight downward tilt, square aspect ratio, isolated on a neutral cream-grey backdrop. Family-friendly, cozy adventure mood.

— A stylized Waypoint Cairn: small ceremonial stone cairn with a carved hedge-rose sigil at the top, tied red ribbon, mushrooms growing at its base, mossy patches between the stones. 3/4 isometric prop view. —

Color palette: warm stone-grey, moss green, ribbon red, mushroom cream. --ar 1:1 --stylize 250 --v 7
```

---

# H. NPCs (4 new) ✅

All 4 shipped 2026-05-01 to `docs/concept-art/npc-{eldra-lampwright,cricket-letter-carrier,brother-pell,mother-onywyn}.png`. Re-roll any individual entry if you want a fresh take.

The four existing NPCs (Hod / Maud / Quill / Withering) **already have art** at `docs/concept-art/npc-*.png` — skip those.

## H1. Eldra the Lampwright — slug `npc-eldra-lampwright`

```
Stylized low-poly fantasy RPG render in the style of RuneScape 3 meets Genshin Impact. Hand-painted toon textures over simple chunky primitive geometry. Clean readable silhouette, soft warm key light from upper left, cool sky fill, gentle ambient occlusion, faint rim light, painterly grass-and-wood materials, no photorealism, no glossy plastic, no PBR-metallic look. 3/4 isometric camera, slight downward tilt, square aspect ratio, isolated on a neutral cream-grey backdrop. Family-friendly, cozy adventure mood.

— Eldra the Lampwright: stooped elderly woman in patchwork shawl, lantern-pole over shoulder hung with three lit lanterns, soft white hair tied with twine, kindly squint, leather pouch of wicks at her belt, mended canvas skirt, sturdy clogs. Full body 3/4 view, single character. —

Color palette: weathered cream shawl, warm lantern-orange glow, white hair, mended-patch greens. --ar 1:1 --stylize 250 --v 7
```

## H2. Cricket the Letter-Carrier — slug `npc-cricket-letter-carrier`

```
Stylized low-poly fantasy RPG render in the style of RuneScape 3 meets Genshin Impact. Hand-painted toon textures over simple chunky primitive geometry. Clean readable silhouette, soft warm key light from upper left, cool sky fill, gentle ambient occlusion, faint rim light, painterly grass-and-wood materials, no photorealism, no glossy plastic, no PBR-metallic look. 3/4 isometric camera, slight downward tilt, square aspect ratio, isolated on a neutral cream-grey backdrop. Family-friendly, cozy adventure mood.

— Cricket the Letter-Carrier: thin teenage boy in a mossy-green tunic with a leather satchel of folded letters, tall walking staff, a real small cricket perched on his shoulder, mud on boots, freckled cheeks, windblown straw hair. Full body 3/4 view. —

Color palette: mossy green, oak satchel, straw hair, mud brown. --ar 1:1 --stylize 250 --v 7
```

## H3. Brother Pell of the Stone Cloister — slug `npc-brother-pell`

```
Stylized low-poly fantasy RPG render in the style of RuneScape 3 meets Genshin Impact. Hand-painted toon textures over simple chunky primitive geometry. Clean readable silhouette, soft warm key light from upper left, cool sky fill, gentle ambient occlusion, faint rim light, painterly grass-and-wood materials, no photorealism, no glossy plastic, no PBR-metallic look. 3/4 isometric camera, slight downward tilt, square aspect ratio, isolated on a neutral cream-grey backdrop. Family-friendly, cozy adventure mood.

— Brother Pell: short round-faced monk in cream wool robe with a dark belt, tonsured hair, holding an illuminated parchment with gold ornament, gentle smile, small hand-cast iron key on a cord around the neck. Full body 3/4 view. —

Color palette: cream wool, dark belt, gold parchment ornament, ruddy cheeks. --ar 1:1 --stylize 250 --v 7
```

## H4. Mother Onywyn the Herb-Witch — slug `npc-mother-onywyn`

```
Stylized low-poly fantasy RPG render in the style of RuneScape 3 meets Genshin Impact. Hand-painted toon textures over simple chunky primitive geometry. Clean readable silhouette, soft warm key light from upper left, cool sky fill, gentle ambient occlusion, faint rim light, painterly grass-and-wood materials, no photorealism, no glossy plastic, no PBR-metallic look. 3/4 isometric camera, slight downward tilt, square aspect ratio, isolated on a neutral cream-grey backdrop. Family-friendly, cozy adventure mood.

— Mother Onywyn: tall thin woman in deep-green hooded cloak, glass jars at her belt holding dried herbs, raven on her shoulder, crow's-foot eye lines, cradling a sprig of foxglove, weathered staff, dark linen under-robe. Full body 3/4 view. —

Color palette: deep forest green, raven black, foxglove purple, dark linen. --ar 1:1 --stylize 250 --v 7
```

---

# I. Environment landmarks (3) ✅

All 3 shipped 2026-05-01 to `docs/concept-art/landmark-{chartmaker-tower,forge-interior,herbalist-interior}.png`. Re-roll any individual entry if you want a fresh take.

(`chartmaker-stone.png` exists ✅ — different from the Tower below; Tower is a new build)

## I1. Chartmaker's Tower — slug `landmark-chartmaker-tower`

```
Stylized low-poly fantasy RPG render in the style of RuneScape 3 meets Genshin Impact. Hand-painted toon textures over simple chunky primitive geometry. Clean readable silhouette, soft warm key light from upper left, cool sky fill, gentle ambient occlusion, faint rim light, painterly grass-and-wood materials, no photorealism, no glossy plastic, no PBR-metallic look. 3/4 isometric camera, slight downward tilt, square aspect ratio, isolated on a neutral cream-grey backdrop. Family-friendly, cozy adventure mood.

— A stylized Chartmaker's Tower: three-story round stone tower with a hexagonal observation deck on top, brass telescope mounted to the deck rail, nautical pennants in cream and red, ivy creeping up one side, copper-domed roof in patinated green, weathervane in the shape of a leaping fish, cobble path leading to the door. 3/4 isometric building shot. —

Color palette: warm grey stone, copper-patina green, brass telescope, cream pennants, ivy green. --ar 1:1 --stylize 250 --v 7
```

## I2. Forge interior — slug `landmark-forge-interior`

```
Stylized low-poly fantasy RPG render in the style of RuneScape 3 meets Genshin Impact. Hand-painted toon textures over simple chunky primitive geometry. Clean readable silhouette, soft warm key light from upper left, cool sky fill, gentle ambient occlusion, faint rim light, painterly grass-and-wood materials, no photorealism, no glossy plastic, no PBR-metallic look. 3/4 isometric camera, slight downward tilt, square aspect ratio, isolated on a neutral cream-grey backdrop. Family-friendly, cozy adventure mood.

— A stylized Forge interior: anvil with a fresh-glowing iron bar still on it, leather bellows beside the brick hearth, tool rack of tongs / hammers / files on the wall, water trough at floor level, sparks mid-air rising from the hearth, cluttered shelf of nails and rivets. Cutaway 3/4 interior shot. —

Color palette: warm hearth-orange, dark soot, oak tools, iron grey, brick red. --ar 1:1 --stylize 250 --v 7
```

## I3. Herbalist hut interior — slug `landmark-herbalist-interior`

```
Stylized low-poly fantasy RPG render in the style of RuneScape 3 meets Genshin Impact. Hand-painted toon textures over simple chunky primitive geometry. Clean readable silhouette, soft warm key light from upper left, cool sky fill, gentle ambient occlusion, faint rim light, painterly grass-and-wood materials, no photorealism, no glossy plastic, no PBR-metallic look. 3/4 isometric camera, slight downward tilt, square aspect ratio, isolated on a neutral cream-grey backdrop. Family-friendly, cozy adventure mood.

— A stylized Herbalist hut interior: sloped beam ceiling hung with herb bundles, alchemy bench cluttered with mortars and bottles, stone hearth with a small simmering pot, a sleeping cat on a stack of books, woven rug on the floor. Cutaway 3/4 interior shot. —

Color palette: warm wood, dried-herb green, glass-bottle blue, hearth orange, cream rug. --ar 1:1 --stylize 250 --v 7
```

---

# Workflow reference

After generating any of the above:

1. Save the favorite as `docs/concept-art/<slug>.png`
2. Append a row to `docs/concept-art/INDEX.md` (mark Status: shipped or replacing dummy)
3. Hand the slug back — engineer follows Phase 2A of `docs/ASSET_PIPELINE.md`

Don't generate ahead — go in batches of 3-5 prompts so tonal coherence holds. Highest priority = the 🟡 entries (game has dummies waiting for art).

**Total prompts: 53. ALL 53 SHIPPED 2026-05-01.** 46 fresh PNGs added across A through I (the other 7 were existing pre-2026-05-01 art). Re-roll any individual entry if you want a fresh take, but the full Bramblewood concept-art set is now in `docs/concept-art/`.
