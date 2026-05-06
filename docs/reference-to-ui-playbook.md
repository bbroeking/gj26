# Reference-to-UI Playbook

A six-stage process for going from "I want my game to look cohesive" to "the UI is rendered, themed, and integrated." Extends the `ART_BIBLE.md` pattern (master prompt stem → hero shots → derived assets) to user interfaces.

Targets: **game UI primarily** (HUD, inventory, dialog, menus), **text-game UI as secondary mode** (paragraph layouts, choice lists, status panels). Output: **HTML + CSS** by default; React notes at the end.

---

## 1. The pattern in one sentence

> **One locked stem → three hero screens → a component sheet → an extracted design system → a translated HTML/CSS implementation → an integration test in the real game.**

Each stage produces a concrete artifact. You don't move on until the artifact is good. This mirrors how `ART_BIBLE.md` works for art — same discipline applies to UI.

---

## 2. Stage 0 — UI Bible (the master stem)

A locked prompt stem you prepend to every UI generation. The **structure** changes per generation; the **style** never does.

### Template

```
[FRAME]: stylized {GENRE} game UI mockup, {AESTHETIC DESCRIPTORS}, hand-drawn /
painterly / pixel-perfect, no photorealism. Soft warm lighting, gentle shadows,
{COLOR DESCRIPTORS}. Clean readable typography, {FONT FEELING}.

[LAYOUT]: {SCREEN | COMPONENT | ICON} on {BACKDROP}, {ASPECT RATIO}, {VIEW ANGLE}.

[SUBJECT]:
{the actual thing being mocked up}

[PALETTE]: {color list}.

[NEGATIVE]: no neon, no cyberpunk, no glossy plastic, no 3D-render look, no
photorealism, no harsh outlines, no busy backgrounds, no menus stacked on
menus.
```

### gj26 example (matches `ART_BIBLE.md`)

```
[FRAME]: stylized cozy fantasy RPG game UI mockup in the style of RuneScape 3
meets Genshin Impact. Hand-painted toon textures, soft warm key light from
upper left, gentle ambient occlusion, painterly grass-and-wood materials. No
photorealism, no glossy plastic, no PBR-metallic look. Family-friendly,
cozy adventure mood.

[LAYOUT]: full-screen UI mockup at 16:9, isolated on neutral cream-grey backdrop.

[SUBJECT]:
{the actual thing being mocked up}

[PALETTE]: warm earthy greens, oak browns, burnished gold accents, soft rose,
bone white. Avoid neon, avoid grayscale, avoid cyberpunk lighting.

[NEGATIVE]: no hard cel-shade black outlines, no anime portraits, no neon, no
glossy plastic, no busy backgrounds.

Generator flags:
- Midjourney: --ar 16:9 --stylize 250 --v 7
- Flux / Imagen / SDXL: drop flags
```

**Save this as `docs/UI_BIBLE.md`** in the project. Treat it like `ART_BIBLE.md` — locked once approved.

---

## 3. Stage 1 — Hero screens (the rule-setters)

Generate **3 full-screen mockups** that establish the rules for everything else. Same energy as the hero shots in `ART_BIBLE.md`.

### Pick three screens that span your UI surface

For an action RPG or cozy life-sim:

1. **Gameplay HUD** — the screen the player stares at most. HP/XP, minimap, action bar, current goal.
2. **Inventory or character sheet** — a "menu" screen. Grid of slots, equipped gear, stats.
3. **Dialog or shop** — text-heavy modal. Portrait, name, dialog box, choice buttons.

For a text-based game:

1. **Story page** — paragraph of prose, choice list, status bar.
2. **Inventory / journal** — list of items + descriptions.
3. **Map or relationship view** — connections, locations, or NPC list.

### Generation protocol

For each hero screen:
1. Run the master stem with the screen as `[SUBJECT]`.
2. Generate **4 variations**.
3. Pick a favorite. Save to `docs/ui-refs/hero_<screen>.png`.

### The "three together" test

Lay all three favorites side-by-side. Ask: *do these look like the same game?* If no, the stem isn't tight enough — refine and regenerate before continuing. Common failures:

- Different fonts → tighten font-feeling in the stem
- Different palettes → lock palette earlier in the stem
- Different "weight" of ornamentation → add a "minimal / ornate / medium" descriptor

Repeat until the three screens *feel* like one game.

---

## 4. Stage 2 — Component sheet (atoms)

Once the hero screens are locked, generate **isolated UI components** so you can see them without screen context. These become the design tokens.

### What to generate

| Category | Examples |
|---|---|
| **Buttons** | Primary, secondary, danger, disabled, hover (4 states each) |
| **Panels / cards** | Frame style, with header, with corner ornament |
| **Bars** | HP, XP, mana, hunger, energy — full + empty states |
| **Icons** | Inventory slot icons (item set already in `ART_BIBLE.md`) |
| **Cursors** | Default, walk, talk, attack, pick-up |
| **Text styles** | Headings, body, dialog speaker, item description |
| **Modals** | Confirm dialog, item tooltip, NPC dialog, level-up celebration |
| **Lists** | Inventory grid, quest log entry, NPC roster line |

### Prompt template for components

```
[STEM]
[SUBJECT]: a {component type} for the game UI: {detailed description},
isolated on neutral grey backdrop, frontal view, no other UI around it.
```

Save each to `docs/ui-refs/comp_<name>.png`.

---

## 5. Stage 3 — Extract the design system

Now you have ~15+ images. Distill them into **CSS tokens**: a finite set of colors, sizes, spacings, fonts. This is the "art bible's locked palette" extended to typography and spacing.

### Tokens to extract

```
:root {
  /* color */
  --bg-game:    #;       /* canvas backdrop */
  --bg-panel:   #;       /* main panel fill */
  --bg-modal:   #;       /* full modal bg */
  --border:     #;       /* default panel border */
  --border-hl:  #;       /* highlight / hover */
  --text:       #;       /* body text */
  --text-dim:   #;       /* secondary text */
  --gold:       #;       /* premium / XP / accent */
  --hp:         #;       /* HP bar fill */
  --xp:         #;       /* XP bar fill */
  --danger:     #;       /* errors / damage */
  --success:    #;       /* gains / completions */

  /* spacing — 4px scale */
  --s-1: 4px;
  --s-2: 8px;
  --s-3: 12px;
  --s-4: 16px;
  --s-6: 24px;
  --s-8: 32px;

  /* typography */
  --font-heading: 'Cinzel', 'Trajan Pro', serif;
  --font-body:    'Lora', 'Garamond', serif;
  --font-mono:    'Courier New', monospace;
  --fs-sm: 12px;
  --fs-md: 14px;
  --fs-lg: 18px;
  --fs-xl: 24px;

  /* radius */
  --r-sm: 2px;
  --r-md: 4px;
  --r-lg: 8px;

  /* shadow */
  --shadow-panel: 0 2px 6px rgba(0,0,0,0.25);
  --shadow-modal: 0 8px 24px rgba(0,0,0,0.4);
}
```

### Extraction process

1. **Drop each hero image into a palette extractor** (Coolors, PixelPanda, Khroma) — extract 5–8 dominant colors per image. Most should overlap; the cross-image overlap *is* your palette.
2. **Eyedrop specific roles.** Open the image in a viewer and pick the exact colors for: bg, panel, text, accent, HP, XP. Record as hex.
3. **Measure spacing.** In your favorite hero screen, measure the gap between elements with a screenshot ruler (Pixel Picker, ColorZilla). Round to a 4px grid.
4. **Pick fonts.** Identify the *feeling* (serif/sans, weight, ornament). Find Google Fonts matches: Cinzel (titles), Lora/EB Garamond (body), VT323 (retro). Test in the layout.

Save the tokens to `src/ui/tokens.css` (or update gj26's existing `index.html` `:root` block).

---

## 6. Stage 4 — HTML/CSS translation

Now turn the hero screens into actual markup. Two paths:

### Path A — manual (slow, accurate)

Build each component by hand, referencing the hero image. Best for cozy/painterly games where AI-generated code will fight your tokens.

```html
<div class="panel">
  <header class="panel-header">Inventory</header>
  <div class="inv-grid">
    <button class="inv-slot"><img src="/icons/sword.png"/></button>
    ...
  </div>
</div>
```

```css
.panel {
  background: var(--bg-panel);
  border: 2px solid var(--border);
  border-radius: var(--r-md);
  box-shadow: var(--shadow-panel);
  padding: var(--s-4);
  font-family: var(--font-body);
  color: var(--text);
}
.panel-header {
  font-family: var(--font-heading);
  font-size: var(--fs-lg);
  color: var(--gold);
  border-bottom: 1px solid var(--border);
  padding-bottom: var(--s-2);
  margin-bottom: var(--s-3);
}
.inv-grid {
  display: grid;
  grid-template-columns: repeat(4, 48px);
  gap: var(--s-2);
}
.inv-slot {
  width: 48px; height: 48px;
  background: var(--bg-game);
  border: 1px solid var(--border);
  border-radius: var(--r-sm);
  cursor: pointer;
  transition: border-color 120ms;
}
.inv-slot:hover { border-color: var(--border-hl); }
```

### Path B — AI-assisted (fast first pass, hand-finish)

Use **screenshot-to-code** tools to bootstrap the layout, then hand-tune to your tokens.

Options:
- **abi/screenshot-to-code** (open source, GPT-4 Vision or Claude vision) — drop image, get Tailwind/HTML
- **v0 by Vercel** — best quality (~72% accuracy), Tailwind only
- **Claude directly** — paste image into a Claude conversation: *"Generate clean HTML/CSS using these CSS variables: [paste tokens]. Match the layout in this image. Don't introduce new colors — only the tokens above."*

**Rule:** never accept the AI's output as-is. It will invent colors, padding, and font-sizes. Always reduce its output to your tokens.

### The Claude vision prompt that works

When asking Claude (or GPT-4o) to translate a UI image:

```
Here is a mockup of a game UI screen.

Below is my locked design system. Use ONLY these tokens — do not invent
new colors, spacing, or fonts.

[paste tokens.css]

Generate semantic HTML and CSS for this screen. Constraints:
1. Use CSS variables from my tokens for all colors, fonts, spacing.
2. Use the 4px spacing scale (--s-1 through --s-8).
3. Output one HTML block and one CSS block, no explanation.
4. Do not include any inline styles.
5. Use semantic elements (button, header, nav, ul, dialog).
6. If the image shows a state (hover, disabled), include the matching CSS rule.

If something in the image is ambiguous, prefer simpler markup over guessing.
```

Image-then-text ordering is critical for Claude vision — paste the image *before* the prompt text.

---

## 7. Stage 5 — Stylized CSS techniques

Game UIs need techniques most web projects skip.

### 9-slice borders (parchment, wood frames, stone panels)

`border-image` lets a single image become a scalable frame. Corner art preserved, edges tile/stretch.

```css
.parchment {
  border: 16px solid transparent;
  border-image: url('/ui/parchment_frame.png') 16 fill / 16px / 0 round;
  /* slice / width / outset / repeat */
  padding: var(--s-4);
}
```

The `fill` keyword tells the browser to also use the middle of the image as a background. Without `fill`, the center is transparent.

### Pixel-perfect rendering (for retro/pixel-art games)

```css
.pixel-icon {
  image-rendering: pixelated;
  image-rendering: -moz-crisp-edges;
}
```

### Stylized fonts via `@font-face`

```css
@font-face {
  font-family: 'Cinzel';
  src: url('/fonts/Cinzel-Regular.woff2') format('woff2');
  font-display: swap;
}
```

Self-host fonts; don't trust Google Fonts CDN at runtime if you want offline-playable.

### Painterly drop shadows

```css
.painted-panel {
  filter: drop-shadow(2px 4px 0 rgba(0,0,0,0.4));
}
```

`drop-shadow` follows the alpha edges of an image, unlike `box-shadow` which uses the rectangle.

### Soft text glow (for important callouts)

```css
.level-up {
  color: var(--gold);
  text-shadow:
    0 0 4px rgba(255,200,80,0.8),
    0 0 12px rgba(255,200,80,0.4);
}
```

### CSS-only progress bars (HP, XP)

```html
<div class="bar"><span style="width: 65%"></span></div>
```

```css
.bar {
  height: 10px;
  background: var(--bg-game);
  border: 1px solid var(--border);
  border-radius: 999px;
  overflow: hidden;
}
.bar > span {
  display: block;
  height: 100%;
  background: linear-gradient(180deg, var(--hp), color-mix(in srgb, var(--hp) 60%, black));
  transition: width 200ms ease-out;
}
```

`color-mix()` lets you derive a darker shade on the fly without a second token.

---

## 8. Stage 6 — Integration test

Drop the new UI into the actual game and play for 5 minutes. Test cases:

- [ ] Does the UI **not** distract from the gameplay scene? (3D world should still feel primary)
- [ ] HP bar updates smoothly under damage; doesn't jump
- [ ] Modal opens without shifting the world
- [ ] Hover/click states feel snappy (≤120ms transitions)
- [ ] Text is readable over busy backgrounds (use a translucent panel under text always)
- [ ] On a 1366×768 laptop screen the UI fits without overlap
- [ ] Mobile / small-window: identify the breakpoint where it breaks; either gate or build a mobile variant
- [ ] No `console.error` in DevTools

If anything fails: do **not** add UI. Revisit the stage where it broke.

---

## 9. Game UI pattern reference

The minimum components for an RPG/cozy game:

| Pattern | Purpose | Implementation note |
|---|---|---|
| **HUD overlay** | HP/XP/energy/time always visible | Position-fixed corners; pointer-events: none on the wrapper, auto on interactives |
| **Action bar** | Hotbar of skills/items | Grid of slots with keyboard binding labels |
| **Inventory grid** | Item storage | Grid + drag-and-drop OR click-and-place |
| **Tooltip** | Item / button info on hover | Position smart (above by default, flip below if cut off) |
| **Dialog box** | NPC speech | Bottom anchor, portrait left, text right, choice buttons below |
| **Modal** | Shop, level-up, confirm | Center, backdrop, ESC to close |
| **Toast / log** | Loot drops, XP gains, system messages | Bottom-left, FIFO, auto-fade |
| **Quest tracker** | Current goal | Top-right, collapsible |
| **Minimap** | Spatial awareness | Top-right, click to open full map |
| **Pause menu** | Settings / save / quit | Backdrop blur, large hit targets |

For text-game UI, the same patterns specialize:

| Pattern | Text-game form |
|---|---|
| **HUD overlay** | Status line: name, HP, day/time, location |
| **Action bar** | Verb buttons (look, take, use, talk) OR command line |
| **Inventory** | Vertical list with item icons + descriptions |
| **Tooltip** | Inline expansion on hover or `[?]` link |
| **Dialog** | Speaker name + paragraph + numbered choice list |
| **Modal** | Full-screen "examine" view of an object |
| **Toast** | New entry in journal / log scroll |

---

## 10. Tools roundup

| Need | Tool | Free? |
|---|---|---|
| Generate UI mockups | Midjourney, Flux (Black Forest Labs), Imagen, SDXL | Mostly paid |
| Refine specific regions | Claude / GPT-4o vision + edit | Paid |
| Color palette extraction | Coolors, PixelPanda, Khroma | Yes |
| Eyedrop colors from image | macOS Digital Color Meter, ColorZilla | Yes |
| Screenshot-to-code | abi/screenshot-to-code, v0 by Vercel | Mixed |
| Browse real game UIs | Game UI Database (1300+ games, 55K screenshots) | Yes |
| RPG UI starter CSS | RPGUI (Ronen Ness) | Yes |
| Asset packs | Franuka itch.io, CraftPix | Mixed |
| 9-slice generator | Found.tools border-image visualizer | Yes |
| Test on devices | Chrome DevTools device toolbar | Yes |

---

## 11. React translation notes

If you later move to React (or already use it):

- Each component → its own `.jsx` file with co-located CSS module
- `tokens.css` becomes a CSS module imported in root
- For dynamic styling (HP %), use inline `style` on the bar fill — not a class swap
- Use `framer-motion` for non-trivial transitions; CSS transitions for hovers
- Headless component libraries (Radix, react-aria) are usually overkill for game UI — the patterns are too specific. Hand-roll.

---

## 12. References

**Image generation for UI**
- [Medium — 40+ Midjourney Prompts for UI Design](https://medium.com/design-bootcamp/40-midjourney-prompts-to-create-outstanding-ui-design-c59bba7ad0d6)
- [hero.page — Midjourney Prompts for Game UI/UX](https://hero.page/samir/midjourney-prompts-for-games-prompt-library/ui-ux-design-for-games)
- [PromptBase — Mobile Games GUI Elements](https://promptbase.com/prompt/mobile-games-gui-elements)

**Screenshot-to-code**
- [abi/screenshot-to-code (GitHub)](https://github.com/abi/screenshot-to-code)
- [v0 by Vercel](https://v0.dev)
- [Medium — GPT-4 Vision Screenshot to Code](https://medium.com/@datadrifters/from-screenshots-to-code-using-gpt-4-vision-generate-html-react-and-tailwindcss-boilerplates-in-3eb468819cd4)
- [WebSight dataset (arXiv)](https://arxiv.org/html/2403.09029v1)

**Claude vision**
- [Anthropic — Vision API Docs](https://platform.claude.com/docs/en/build-with-claude/vision)
- [Anthropic — Prompt Engineering Best Practices](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices)

**Game UI**
- [Game UI Database (1300 games, 55k screens)](https://www.gameuidatabase.com/)
- [RPGUI by Ronen Ness](https://ronenness.github.io/RPGUI/)
- [Franuka itch.io RPG UI Pack](https://franuka.itch.io/rpg-ui-pack)
- [CraftPix RPG Game UI](https://craftpix.net/categorys/rpg-game-ui/)

**Color palette extraction**
- [Coolors](https://coolors.co/)
- [PixelPanda](https://pixelpanda.ai/free-tools/palette-extractor)
- [Khroma](https://www.khroma.co/)
- [Colormind (AI palette generator)](http://colormind.io/)

**CSS techniques**
- [MDN — border-image-slice](https://developer.mozilla.org/en-US/docs/Web/CSS/border-image-slice)
- [CSS-Tricks — Understanding border-image](https://css-tricks.com/understanding-border-image/)
- [Coherent Labs — 9-slice modal](https://coherent-labs.com/blog/uitutorials/nine-slice-modal/)
- [callum-gander/nine-slice-frame (React/Vue/Svelte)](https://github.com/callum-gander/nine-slice-frame)
