# Concept-Art Prompts — Next Wave (Bramblewood)

Drop-in batch for Midjourney / Imagen / Flux. Each prompt prepends the **locked stem** so every output reads as one cohesive Bramblewood storybook.

When art comes back, save to `docs/concept-art/<slug>.png` then bring the slug here so we can Blender + wire it.

## Locked stem

Use this verbatim as the prefix for every prompt below:

```
hand-painted storybook concept art, cozy fairytale RPG, low-poly 3D
reference, Bramblewood village setting, soft watercolor wash + ink
linework, warm earthy palette (oak browns, mossy greens, parchment cream,
hearth-orange highlights), gentle directional dawn light, 3/4 isometric
view, neutral grey background, no UI, no text, no outline cel-shade,
single subject centered.
--ar 1:1 --stylize 250 --v 7
```

Negative prompt (paste after for stable diffusion-style backends):
`no neon, no cyberpunk, no glossy plastic, no photorealism, no hard cel-shade outlines, no busy backgrounds`.

## Group A — Village ambient props

For `src/scene/world.js` placement once modeled.

1. **Signpost crossroads** — wood signpost with three carved arrows pointing different directions, hand-burned town names, a lantern hung from a hook, mushroom ring at its base. *(slug: `prop-signpost-crossroads`)*
2. **Market stall** — small wood-frame stall with green-striped awning, fruit baskets and a hanging scale, bench and stool, bunched flowers in a pail. *(slug: `prop-market-stall`)*
3. **Village well** — round stone well with mossy lip, wooden roof shingled in hand-cut planks, iron crank handle, rope and bucket at rest, ivy creeping up one post. *(slug: `prop-village-well`)*
4. **Dovecote** — tall rough-stone cylinder with arched openings, doves perched and in flight, ladder leaning against it, scattered seed at base. *(slug: `prop-dovecote`)*
5. **Fishing dock** — short plank dock over a still pond with cattails, three-leg fishing chair, tackle bucket, basket of two trout. *(slug: `prop-fishing-dock`)*

## Group B — New NPCs (quest-givers)

Each as a single storybook portrait so the silhouette reads at a distance.

6. **Eldra the Lampwright** — stooped elderly woman in patchwork shawl, lantern-pole over shoulder hung with three lanterns, soft white hair tied with twine, kindly squint, leather pouch of wicks. *(slug: `npc-eldra-lampwright`)*
7. **Cricket the Letter-Carrier** — thin teen boy in mossy-green tunic with leather satchel of folded letters, tall walking staff, a cricket on his shoulder, mud on boots. *(slug: `npc-cricket-letter-carrier`)*
8. **Brother Pell of the Stone Cloister** — short round-faced monk in cream wool robe with dark belt, holding an illuminated parchment, tonsured hair, gentle smile. *(slug: `npc-brother-pell`)*
9. **Mother Onywyn the Herb-Witch** — tall thin woman in deep-green hooded cloak, glass jars at her belt, raven on shoulder, crow's-foot eye lines, cradling a sprig of foxglove. *(slug: `npc-mother-onywyn`)*

## Group C — Mid-tier hostile creatures (Hard tier)

For `src/game/enemies.js` extension. HP 60–180, atk 12–20, def 8–12, maxHit 5.

10. **Hedge-Wolf** — predator wolf woven of bramble vines and ash-grey fur, glowing amber eyes, blackthorn antlers, long forelimbs, prowling pose. *(slug: `enemy-hedge-wolf`)*
11. **Briar Lurker** — humanoid frame entirely of woven thorny vines with a hollow lantern-pumpkin head glowing dim orange, tattered cloth strips, slow stalking gait. *(slug: `enemy-briar-lurker`)*
12. **Bog-Stag** — gaunt deer with moss-covered ribs visible through hide, antlers tangled with reeds, glowing white eyes, water dripping from belly. *(slug: `enemy-bog-stag`)*
13. **Hollow Gourd** — large carved-pumpkin creature with ember-glow grin and brittle root legs, stuffed with straw, perched on a stump. *(slug: `enemy-hollow-gourd`)*

## Group D — Environment landmarks

Replace the current procedural placeholders with hand-modeled landmarks.

14. **Chartmaker's Tower** — three-story round stone tower with hexagonal observation deck, brass telescope, nautical pennants, ivy, copper-domed roof, weathervane in the shape of a fish. *(slug: `landmark-chartmaker-tower`)*
15. **Forge interior** — anvil with fresh-glowing iron, leather bellows, tool rack of tongs/hammers/files, water trough, sparks mid-air, brick hearth. *(slug: `landmark-forge-interior`)*
16. **Herbalist hut interior** — sloped beam ceiling hung with herb bundles, alchemy bench cluttered with mortars and bottles, stone hearth, a sleeping cat on a stack of books. *(slug: `landmark-herbalist-interior`)*

## Group E — Quest props (carryable items)

Small icon-style references for `models/*.glb` work. Each rendered as a single object on a neutral pedestal, soft drop shadow.

17. **Hod's Apprentice Hammer** — short oak-handled smith hammer with a bronze head, leather grip, brass cap on pommel. *(slug: `item-apprentice-hammer`)*
18. **Falcon's Whistle** — bone whistle on a braided leather cord with three feather charms (one white, one barred brown, one black-tipped). *(slug: `item-falcon-whistle`)*
19. **Thorn Crown** — circlet of black-iron thorns interlaced with dried bramble vines, single drop of dried red sap on the front spike. *(slug: `item-thorn-crown`)*
20. **Quill's Field Atlas** — small leather-bound book stamped with a leaf sigil, brass corner caps, ribbon bookmark, pages slightly fanned showing botanical sketches. *(slug: `item-quill-atlas`)*

## Group F — Cartography (new this wave)

Match the new world-map / fast-travel feature.

21. **Blank Chart** — folded parchment on a worn wooden plank, edges browned, two iron weights at the corners, faint grid lines visible. *(slug: `item-chart-blank`)*
22. **Surveyor's Pole** — tall striped wooden stake (red and cream bands) with a small brass plumb bob hanging from its tip, leather strap. *(slug: `item-surveyor-pole`)*
23. **Cartographer's Compass** — open brass compass on a worn leather travel-map, ink quill beside it, half-drunk inkpot, candle stub. *(slug: `item-cartographer-compass`)*
24. **Bramblewood Master Chart** — large unfurled vellum map of the whole valley with rivers, hills, hand-illuminated ornament in each corner (tree / wolf / well / sun). *(slug: `item-master-chart`)*
25. **Waypoint Cairn** — small ceremonial stone cairn with a carved hedge-rose sigil and a tied red ribbon, mushrooms growing at its base. *(slug: `prop-waypoint-cairn`)*

---

## After the art lands

For each generated PNG:

1. Save to `docs/concept-art/<slug>.png` (per the slugs above).
2. Append a one-line entry to `docs/concept-art/INDEX.md`.
3. Bring the slug + one-sentence "what's special about it" back to me — I'll Blender it via the MCP, wire the loader into `src/scene/characters.js`, and place it in the world.

Hand back in batches of 3-5 — bigger batches lose tonal coherence.
