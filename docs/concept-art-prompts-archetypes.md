# Archetype Concept-Art Prompts

Three prompts for fresh concept art before re-authoring the v2 archetype meshes
(`knight_v2.glb`, `druid_v2.glb`, `wanderer_v2.glb`). Each is the project's
locked **master style stem** from `docs/ART_BIBLE.md` with the archetype-specific
subject between the dashes.

After generating, save the favorite as:
- `docs/art-refs/knight_v20_archetype.png`
- `docs/art-refs/druid_v1_archetype.png`
- `docs/art-refs/wanderer_v1_archetype.png`

Then re-author the GLBs in Blender to match the chosen reference. The three
archetypes share the same body proportions / rig (Body, Head, Arm_L/R, Leg_L/R)
so animation code drives all three identically — only the surface details (gear,
silhouette, colors) differ.

---

## 1. Knight

```
Stylized low-poly fantasy RPG render in the style of RuneScape 3 meets
Genshin Impact. Hand-painted toon textures over simple chunky primitive
geometry. Clean readable silhouette, soft warm key light from upper left,
cool sky fill, gentle ambient occlusion, faint rim light, painterly
grass-and-wood materials, no photorealism, no glossy plastic, no
PBR-metallic look. 3/4 isometric camera, slight downward tilt, square
aspect ratio, isolated on a neutral cream-grey backdrop. Family-friendly,
cozy adventure mood.

— A young human knight, chunky stylized proportions, gleaming centurion-style
helmet with a tall red plume, polished olive-bronze breastplate with gold
pauldrons, leather belt with metal studs, cream tunic skirt, brown leather
boots, short iron sword in right hand, large rounded laurel-rimmed shield in
left hand, red cape draping behind shoulders, confident relaxed stance,
neutral friendly expression, full body 3/4 view, single character on plain
cream backdrop. —

Color palette: warm earthy greens, oak browns, burnished gold accents, soft
rose, bone white, deep red plume. Avoid neon, avoid grayscale, avoid cyberpunk
lighting.
```
**Midjourney flags**: `--ar 1:1 --stylize 250 --v 7`

---

## 2. Druid

```
Stylized low-poly fantasy RPG render in the style of RuneScape 3 meets
Genshin Impact. Hand-painted toon textures over simple chunky primitive
geometry. Clean readable silhouette, soft warm key light from upper left,
cool sky fill, gentle ambient occlusion, faint rim light, painterly
grass-and-wood materials, no photorealism, no glossy plastic, no
PBR-metallic look. 3/4 isometric camera, slight downward tilt, square
aspect ratio, isolated on a neutral cream-grey backdrop. Family-friendly,
cozy adventure mood.

— A young druid, chunky stylized proportions, soft bramble-green hooded robe
with leaf-trim and ivy embroidery, deep moss-green hood pulled back to reveal
a brown-haired head wreathed in tiny oak leaves, twisted oak walking staff in
right hand topped with a glowing amber orb of bramble-light, simple linen
under-tunic in cream, brown leather sandals, faint glowing rune motifs on
hem and sleeves, gentle thoughtful expression, full body 3/4 view, single
character on plain cream backdrop. —

Color palette: deep moss green, oak brown, soft amber glow accents, cream
linen, bone white. Avoid neon, avoid grayscale, avoid cyberpunk lighting.
```
**Midjourney flags**: `--ar 1:1 --stylize 250 --v 7`

---

## 3. Wanderer

```
Stylized low-poly fantasy RPG render in the style of RuneScape 3 meets
Genshin Impact. Hand-painted toon textures over simple chunky primitive
geometry. Clean readable silhouette, soft warm key light from upper left,
cool sky fill, gentle ambient occlusion, faint rim light, painterly
grass-and-wood materials, no photorealism, no glossy plastic, no
PBR-metallic look. 3/4 isometric camera, slight downward tilt, square
aspect ratio, isolated on a neutral cream-grey backdrop. Family-friendly,
cozy adventure mood.

— A traveling wanderer, chunky stylized proportions, weathered slate-blue
hooded traveler's cloak draped over the shoulders, simple cream linen tunic
underneath cinched with a wide leather belt and brass buckle, sturdy brown
canvas pants, scuffed leather boots, leather satchel slung crossbody on a
braided strap, plain wooden walking stick in right hand reaching the ground,
small leather bracers on both forearms, hood pulled back showing tousled
chestnut hair and a quiet alert expression, road-traveler stance, full body
3/4 view, single character on plain cream backdrop. —

Color palette: weathered slate blue, oak brown, cream linen, brass-gold
accents, bone white. Avoid neon, avoid grayscale, avoid cyberpunk lighting.
```
**Midjourney flags**: `--ar 1:1 --stylize 250 --v 7`

---

## After concept art lands

Once the three references are saved, re-authoring in Blender follows the
same pattern as the existing characters:

1. Build common rig (Body, Head, Arm_L, Arm_R, Leg_L, Leg_R as named EMPTYs at
   the standard rig positions: Body z=0.55, Head z=1.15 (with head MESH at the
   actual head visual position, NOT cancelled by `parent_inverse`)
2. Author each archetype's gear meshes parented to the appropriate empty
3. **Critical**: when parenting, set `keep_transform=False` so locals reflect
   intended offsets. The earlier v2 pass used `keep_transform=True` which baked
   the parent's world position into a `parent_inverse` matrix that cancelled
   the rig position — this is the bug that made the v2 GLBs collapse to origin.
4. Use the recipe from `docs/BLENDER_PIPELINE.md` for materials and bevel.
5. Export with `export_visible=True` from a fresh isolated scene to avoid
   cross-scene pollution.
