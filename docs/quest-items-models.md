# Quest Item Model Build Index

Each new town-quest item that needs a 3D representation. Models follow the
project's chunky-low-poly Blender pipeline (Principled BSDF + scale-aware
bevel + glTF export per `docs/BLENDER_PIPELINE.md`). Sized to fit comfortably
in an inventory slot icon (≈0.4–1.0 unit cube footprint) since they're
display-only items unless otherwise noted.

Output target: `models/<id>.glb`. Loader registration goes in
`src/scene/characters.js`. For pure inventory icons, a 2D PNG in
`assets/icons/<id>.png` is also acceptable and avoids the Blender pass.

---

## Hod Tenter quest

### apprentices_hammer
**One-line brief**: A short-handled smith's hammer with a leather-wrapped grip.
**Build prompt** (Midjourney / Imagen / Flux):
> A chunky low-poly stylized blacksmith's hammer, short hickory haft wrapped in dark leather strap, square steel head with one chipped corner, hand-painted toon look, plain neutral grey backdrop, 3/4 view, no scene clutter. Soft warm key light, painted shading, no photorealism.

**Blender pipeline shape**:
- Haft: cylinder, 0.04r × 0.34h, wrapped at midpoint with a 4-segment torus collar (leather material).
- Head: cube 0.10×0.06×0.08, slightly chipped corner via knife-cut on one edge.
- Materials: `Wood` 0x6e4a2a, `Leather` 0x4a3220, `Steel` 0x6a6e74.
- Bevel pass at default 0.025/2/30°.

### hods_anvil_token
**Brief**: Small bronze coin pressed with an anvil silhouette.
**Build prompt**:
> A bronze hand-cast token coin embossed with a stylized anvil silhouette, weathered patina, 1cm diameter, hand-drawn stylized look, neutral backdrop, 3/4 view.

**Pipeline**: cylinder 0.10r × 0.012h with a raised anvil-shaped extrude on one face. Materials: `Bronze` 0xa07a3a + `BronzeDark` 0x6f4a18 for the relief.

---

## Quill quest

### healing_draught
**Brief**: Cloudy green tincture in a stoppered bottle.
**Build prompt**:
> A small stoppered glass bottle full of cloudy green herb-tincture, cork stopper bound with hemp twine, twisted parchment label with handwritten herb sigil, hand-drawn stylized RPG inventory item, neutral backdrop, soft moss-green glow.

**Pipeline**: bottle = stretched UV sphere ~0.12 tall, cork = small cylinder, twine = thin torus around the neck. Materials: `Glass` 0x8aa874 (semi-transparent), `Cork` 0x8a6438, `Twine` 0xc4a36a.

### bramble_resin
**Brief**: Sticky amber droplet on a snippet of bramble vine.
**Build prompt**:
> A drop of sticky amber bramble-sap clinging to a short snippet of dark thorny vine, frozen mid-drip, hand-drawn stylized fantasy material item, neutral backdrop, 3/4 view, painted toon shading.

**Pipeline**: thorny vine = bent cylinder with three small cone-spike children. Resin droplet = stretched UV sphere with high gloss, color 0xd4a04a, slight emissive (0.3). Materials: `Thorn` 0x4a3220, `Resin` 0xd4a04a (translucent ON in BSDF).

---

## Sir Withering quest

### falcons_whistle
**Brief**: Small bone whistle on a leather thong.
**Build prompt**:
> A short fluted bone whistle, three small finger-holes, threaded on a worn leather thong, hand-drawn stylized RPG item, neutral backdrop. Bone has a creamy ivory tone with small dark scrimshaw-style etchings of feathers.

**Pipeline**: bone = cylinder 0.06r × 0.16h with three small bored holes (tiny cylinders subtracted). Thong = thin torus loop through one end. Materials: `Bone` 0xe8d8a8, `Leather` 0x4a3220.

### whickerhares_foot
**Brief**: Velvet rabbit's foot charm with a small brass cap.
**Build prompt**:
> A traditional rabbit's-foot charm — soft velvet-fur foot tipped with a brass cap, on a knotted leather cord, hand-drawn stylized fantasy lucky-charm, neutral backdrop, 3/4 view.

**Pipeline**: foot = stretched UV sphere with light tan fur material (high roughness). Cap = brass cylinder cap at one end. Cord = thin torus. Materials: `Fur` 0xc8b58c, `Brass` 0xb58637, `Cord` 0x4a3220.

### thorn_crown
**Brief**: Diadem of black bramble with red berries, slightly cursed-looking.
**Build prompt**:
> An ornate crown woven of dark thorned bramble with three glowing red berries embedded in the front, slightly menacing but elegant, hand-drawn stylized fantasy boss-drop item, neutral backdrop.

**Pipeline**: torus 0.16 major × 0.04 minor (the band) with 6–8 small thorn cones radiating outward. Three red UV spheres at the front for berries (emissive 1.5 to glow). Materials: `Thorn` 0x2a1a14 (very dark wood), `Berry` 0xc63030 (emissive).

---

## Maud follow-up

### pantry_stew
**Brief**: Earthenware bowl with thick brown stew + green herbs.
**Build prompt**:
> A small earthenware bowl filled with thick brown stew, sprigs of green herb on top, steam wisps rising, hand-drawn stylized fantasy food, neutral backdrop, 3/4 view.

**Pipeline**: bowl = wide squat cylinder with inset top face. Stew = flat disk material 0x6e4a2a. Herb sprigs = three small cones in green. Materials: `Earthenware` 0xa68258, `Stew` 0x6e4a2a, `Herb` 0x6f8a3f.

---

## Workflow

1. Generate the concept image via Midjourney / Imagen / Flux from the prompt above.
2. Save it to `docs/concept-art/<id>.png`.
3. Build the Blender mesh per the pipeline notes via the Blender MCP tool, export to `models/<id>.glb`.
4. Add a loader to `src/scene/characters.js` (`loadXxxGLB`) and a builder where the item is rendered in 3D (drop, equipped pose, etc).
5. For inventory-only icons, save a 64×64 PNG at `assets/icons/<id>.png`. The renderInv pipeline already prefers PNG over emoji.
