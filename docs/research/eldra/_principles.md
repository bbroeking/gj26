# Eldra autoresearch — applied art-style principles

This file is the bridge between **what the wiki says** and **what the experiments
test.** Every prompt under `runs/` cites at least one of these principles in its
`hypothesis` field so we can read the gallery as a research log instead of a pile
of variants.

Source wiki (one per principle): `~/projects/research/wiki/art/`.

---

## 1. Shape commitment — pick a primary shape and exaggerate past comfort

> "A 'kind of square' character is forgettable; a *defiantly* square character is
> iconic." — [silhouette-shape-language §2.1]

Eldra is a cozy lampwright elder. The right primary shape is **CIRCLE** (friendly,
soft, comforting — the Disney/vsquad shape-language read for nurturing characters).
Currently she's a stocky-cube blob — neither circle nor square nor triangle reads
clearly. The wiki's prescription is to commit harder: exaggerate the round
midsection, soften every angular cue, treat the staff hook as the only triangle.

**Implications for prompts:**
- `ELDRA_BODY_CAST` higher values (0.4, 0.6) push her toward circle (already in
  flight in r004–r008).
- A future axis: width-scale the torso (`ELDRA_BODY_WIDTH_MUL>1`) to broaden the
  rotund silhouette past comfort.

## 2. Hierarchy — 60-70% primary, 20-30% secondary, <10% tertiary

> "Tertiary detail should occupy less than 10% of the silhouette mass and cluster
> at one or two focal points." — [silhouette-shape-language §3.3]

Eldra's tertiary is currently scattered: stitches, motifs, weave stripes, hem
trim, belt buckle, drawstring. They sum to far more than 10% of the silhouette.

**Implications for prompts:**
- `ELDRA_FORM_MERGE=1` drops the nano-detail (already tested in r002+).
- `ELDRA_FORM_MERGE=2` collapses tabard segments + drape (r003+).

## 3. Limited palette — 5-8 hues per asset, ONE saturation peak

> "A reliable working budget for stylized assets is 5 to 8 distinct hues per
> asset." — [color-and-lighting §2.1]

Eldra currently uses **30 distinct color constants** (counted in
`build_npc_eldra_v2.py`). That's 4× the wiki budget. The result reads as muddy
because no single color carries the eye.

> "A scene should have one most-saturated color, and everything else should be
> visibly desaturated relative to it. The eye goes where saturation is, so the
> saturation peak doubles as the scene's focal point." — [color-and-lighting §2.3]

Eldra's thematic identity is **the lantern**. The lantern glow (warm yellow)
should be the ONE saturated color in the silhouette; everything else (skin,
shawl, tunic, beard, sandals, satchel) should sit visibly below it on the
saturation axis.

**Implications for prompts:**
- `ELDRA_PALETTE_MODE='desat'` keeps the hue rotation but multiplies saturation
  by 0.6 on every color *except* `LANTERN_GLOW`. Tests "one saturation peak"
  literally.
- `ELDRA_PALETTE_MODE='reduced'` collapses the 30 colors down to 8 anchor
  swatches by aliasing similar colors (TUNIC_SEAM → TUNIC, PANT_DK → PANT,
  HAIR_SHADOW → HAIR_WHITE, BEARD_WHITE → HAIR_WHITE, SANDAL_STRP → LEATHER_DK,
  POT_DK → LEATHER_DK, etc). Tests the per-asset hue budget.

## 4. Cel shading — tone ramp + inverted-hull outline + flat textures

> "1D tone ramp, inverted-hull outlines, posterized textures — every toon shader
> from Wind Waker to Genshin is built out of these three orthogonal pieces." —
> [toon-shading §1]

We have:
- Tone ramp ✓ — `MeshToonMaterial` in three.js, 4-step grayscale gradient set in
  `src/scene/characters.js`.
- Inverted-hull outlines ✓ — added to the codex viewer this iteration. Uses
  vertex-normal-baked geometry expansion so SkinnedMesh skinning preserves it.
- Flat textures ✓ — we don't author PBR maps; per-cube solid colors only.

Most of the orthogonal stylization knobs are already in place. The remaining
unexplored knob: a **harder tone ramp** (2 bands instead of 4) to push the
storybook-cel feel further.

## 5. Wind Waker chibi proportions

> "Wind Waker's oversized-head/disc-eye proportions translate directly to
> GLB-exported character rigs and read clearly at small browser resolutions." —
> [reference-catalog §1.4]

Eldra is 3 heads tall (gnome-like). She could go further: 2.5–2.75 heads via
a head-scale multiplier. Bigger heads also amplify her lampwright FACE-expressive
identity — the kindly squint and bushy beard read better at distance with a
larger head.

**Implications for future prompts (not yet authored):**
- `ELDRA_HEAD_SCALE_MUL>1` would scale Head_skull + jaw + face features +
  hair/beard tufts together. Worth a future axis.

## 6. Thumbnail test — silhouette as a 64×64 black-on-white blob

> "If you can't pass the thumbnail test, do not advance to the next stage of
> production." — [silhouette-shape-language §1.2]

The autoresearch-loop renders a 800×800 thumbnail at `runs/<id>/thumb.png`. We
should add a 64×64 silhouette-only render alongside (black material, white BG,
no lighting) so each gallery card shows BOTH the colorful render AND the
thumbnail-test silhouette. That comparison is the literal Disney Family Museum
diagnostic. **Future tooling lever, not yet implemented.**

---

## What the next batch tests

| run | wiki principle | prompt |
|---|---|---|
| r009_palette_desat | §3 (one saturation peak) | desat all colors except lantern_glow |
| r010_palette_reduced | §3 (5-8 hues per asset) | collapse 30 colors to 8 anchors |
| r011_best_so_far_desat | §3 (combine best with desat) | r004 winner + desat |
