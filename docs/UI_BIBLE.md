# UI_BIBLE.md — Wayfinder UI master prompt stem

Locked style stem for generating UI concept mockups (reference-to-ui skill,
Stage 0). Run the hero prompts below in Midjourney, save the favourites to
`docs/ui-refs/`, and the design system gets extracted from them.

Aesthetic north star: **cozy fairytale storybook, hand-painted, enamel + carved
wood + leaf-gold** — the "Storybook Enamel Night" skin already in-game, but
elevated. Deep teal panels, gold filigree, warm cream text, IM Fell serif.

## Master stem

```
stylized cozy fairytale RPG game UI mockup, hand-painted storybook illustration,
carved enamelled wood panels with leaf-gold filigree, warm and inviting,
ornamental but clean and readable, soft warm candlelit glow,
deep enamel-teal panels, leaf-gold accents, warm cream parchment text,
ember-terracotta and sage highlights, old-style serif lettering,
[SUBJECT], straight-on game screen,
no neon, no cyberpunk, no glossy plastic, no photorealism, no flat corporate SaaS,
no hard cel-shade outlines, no busy background
--ar 16:9 --stylize 250 --v 7
```

Palette anchors: deep teal `#14342F`, leaf-gold `#E3B85C`, warm cream `#EFE7CE`,
ember `#D56A45`, sage `#A6C264`.

## Hero prompts (Stage 1 — run each, pick 1 of the 4 variations)

Replace `[SUBJECT]` in the stem with each of these:

1. **Gameplay HUD** — `a cozy fairytale action-RPG gameplay HUD overlay: a small chibi hooded ranger in a lantern-lit dungeon, a round health orb and a focus orb flanking a carved wooden skill hotbar of five slots, a compact quest banner in one corner, a minimap compass, clean and uncluttered`
2. **Inventory / pack** — `a fairytale RPG inventory and character screen: an equipment paper-doll of a chibi hooded ranger down one side, a tidy grid of item slots with painted icons, carved enamel-and-gold framed panels, tabs along the top`
3. **NPC dialogue** — `a cozy storybook NPC dialogue screen: a warm framed dialogue box across the lower third with a hand-painted character portrait on the left, cream parchment prose, three carved wooden choice buttons, an ornamental gold border`
4. **Title / main menu** — `a fairytale game title screen: the word "Wayfinder" in gilded old-style serif over a misty dusk Bramblewood clearing, a vertical stack of five carved wooden menu buttons, drifting firefly motes, warm and inviting`

## Component sheet (Stage 2 — optional, after heroes are locked)

Isolated on a neutral grey backdrop, frontal, no surrounding UI: buttons (rest /
hover / pressed / disabled), a panel/frame, HP+focus orbs, a skill slot, item
icons, a tab bar, a dialogue box, a scrollbar.

## Flow from here

1. You generate the 4 heroes in Midjourney (4 variations each), pick a favourite
   per screen, and drop them in `docs/ui-refs/` (or just tell me the paths).
2. **Three-together check:** if the three heroes don't look like one game, I'll
   refine the stem and you regenerate.
3. I extract tokens (palette, spacing, type, frame metrics) into `WyrdUi` and
   rebuild the HUD, panels, and menus to match the locked references.
