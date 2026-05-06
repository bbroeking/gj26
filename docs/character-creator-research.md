# Character Creator Research — Cross-Game Survey

A condensed survey of how major games handle character creation, the patterns they share, the deliberate tradeoffs, and what it means for a cozy RuneScape-flavored project like gj26.

---

## 1. The scope spectrum (the single most important axis)

Character creators sit on a one-dimensional spectrum from **minimal-presets** to **maximum-sliders**. Every other design decision flows from where you sit.

```
MINIMAL ──────────────────────────────────── MAXIMUM
    │            │            │            │
Animal       Stardew     OSRS      WoW    FFXIV  Elden    BDO    Saints
Crossing     Valley                               Ring            Row
   │            │           │       │      │       │       │       │
"is the      "presets    "swap     "race   "wide  "deep   "every  "make
 mascot"     only"       loadout"   +      slider  slider  pixel   anything"
                                  preset"  range" + share" tunable"
```

| Position | Player time spent | Returning to creator | Player satisfaction signal |
|---|---|---|---|
| Minimal (Animal Crossing) | <60s | rare/never | "Cute, let's play" |
| Light (Stardew, OSRS) | 1–3 min | character barber, low cost | "I look like me-ish" |
| Medium (WoW, ESO) | 5–15 min | barber shop with fees | "I feel attached" |
| Deep (FFXIV) | 15–60 min | fantasia potion (paid) | "I love them" |
| Maximum (BDO, Saints Row, Hogwarts Legacy) | 1–4 *hours* | dedicated re-creation tools | "This is my OC for life" |

**Pick deliberately.** A cozy game with a maximum-slider creator scares casuals. A AAA action-RPG with minimal options gets returns. The creator should match the rest of your game's depth.

---

## 2. Case studies

### OSRS / RuneScape (light)
- Inside Tutorial Island, between RS Guide and Survival Expert
- ~6 categories: gender, hair (color + style), facial hair, top color, leg color, skin
- Tiny portrait + button rotators (no sliders) — paddles for prev/next
- ~60–90 seconds typical
- Re-customization: free at Makeover Mage anytime
- **Why it works:** matches the game's chunky, low-detail look. Players accept the constraint because the world is also low-poly. *Sets the bar for our reference.*

### Stardew Valley (light, cozy minimum)
- Sprite portrait, ~8 hair styles, ~6 shirts, skin tone, accessory, eye color, name, farm name, pets, favorite thing
- Random button (yes — even Stardew has one)
- Re-customization: Mayor's wizard NPC for a fee in-game
- **Why it works:** the game is 2D pixel art; a deeper creator would be both technically wasteful and emotionally mismatched

### Animal Crossing: New Horizons (lightest)
- Hair (8 styles × 8 colors), eye color, mouth, face style, skin tone
- That's it. Outfit is changed in-game, not in creator
- **Why it works:** the player isn't the focus — the *island* is. Any time spent on the creator is time not spent on the actual gameplay loop

### World of Warcraft (medium, classic vs modern split)
- **Classic (2004):** very rigid — race + gender + ~6 face presets + ~10 hair + skin. ~2 minutes.
- **Modern (Shadowlands+):** added body modifications, multiple skin tones per race, accessories per race, jewelry, tattoos, blindness/glow eyes. Playtest data drove it — racial customization complaints were the single biggest UX gripe of the era.
- **Re-customization:** in-game barber shop with gold cost (free for some changes since DF)
- **Lesson:** start more flexible than you think you need. Adding categories later is harder than they look — every NPC dialog with a portrait has to support the new options.

### FFXIV (medium-deep, the gold standard for many)
- 8 races, gender per race, dozens of hairstyles per race, sliders for face structure, multiple eye colors, scars, makeup
- Full-body 3D preview that rotates and swaps lighting
- **Killer feature:** save and load *appearance presets* as `.dat` files — community libraries form
- Re-customization: "Fantasia" item, real-money or gameplay-earned, costs ~$10 — this is a real revenue source
- **Lesson:** community sharing of appearance data is a content multiplier — build the export/import format from day 1

### Black Desert Online (extreme depth)
- Hundreds of sliders. Eye gloss. Wrinkle depth. Per-tooth shape. Lip volume.
- Standalone creator app — players spend *hours* before ever launching the game
- Template import/export from popular community files
- **Catch:** classes are gender-locked (a deliberate constraint that many criticize)
- **Lesson:** when sliders go to 11, you must give players save/share or they'll redo the same character every alt

### Elden Ring (deep, soulslike pattern)
- ~30 sliders across face, body, eyes, hair
- Presets ("Hero", "Confessor", "Bandit", etc.) act as **starting points** — a slider preset, not a class
- 3D real-time preview with lighting toggles (day/dusk/dim)
- Massive community of slider-sharing sites (eldensliders.com, eldenblingsliders.com)
- Re-customization: in-game mirror after specific story beat
- **Lesson:** presets-as-shortcuts let casual players ship in 60 seconds; sliders let obsessives spend an hour. Same screen serves both

### Mass Effect (cinematic, narrative-locked)
- ~20 sliders, but the screen is **framed cinematically** — Shepard appears in a portrait shot with mood lighting, not a T-pose
- Voice + biographical background sliders affect dialog and cutscenes
- Default Shepard ("Femshep") became famous for being a designed character — many players just used the default
- **Lesson:** the camera framing of the preview tells players how to feel about their character. T-pose = "data entry." 3/4 portrait with mood lighting = "this is my hero"

### Cyberpunk 2077 (modern, gender-decoupled)
- "Body type" (masculine/feminine frame) and "Voice tone" (which sets pronouns) are **separate** sliders
- Genitals are independent
- All visual aspects re-editable in-game via mirror or ripperdoc, but body type and voice are locked at creation
- **Lesson:** decoupling body/voice/pronouns is now standard for new games released 2020+. Don't ship "male/female" as the only axis in 2026 — it's behind the curve

### Hogwarts Legacy (modern, body-type approach)
- Two body types (no gender label). Voice. Facial sliders.
- Pronouns set via dropdown, independent from body
- **Lesson:** match Cyberpunk's pattern. It's now the cozy/modern default.

### Saints Row IV/V (extreme expression)
- Every slider goes to absurd values. Player can be 12-foot-tall purple. Voice options include zombie groans.
- The creator is *itself* a feature people buy the game for
- **Lesson:** if expression is your core fun, sliders should over-shoot reasonable limits. Players will love the over-the-top. (Doesn't apply to gj26.)

### Genshin Impact (zero creator)
- No creator at all. You play named, designed characters.
- **Lesson:** for narrative-first games where the protagonist is *meant* to be a specific person, skipping the creator is correct. Your players bond to the designed character; a creator would dilute that

### Hogwarts Legacy / Stardew / cozy modern norm
- Always include: body type, voice/pronouns (decoupled), skin tone, hair (style + color), accessories
- Almost always include: random button, presets, in-game re-customization (cheap or free)
- Increasingly include: scars, prosthetics, vitiligo, freckles, glasses, hearing aids — the "inclusivity check" of 2024+

---

## 3. The patterns that span every game

### A. Presets are a starting point, not a destination
- Every successful creator has presets, even slider-heavy ones (Elden Ring, BDO)
- Presets unblock the player who doesn't want to tweak
- For sliders-heavy games, presets are also a great `random` seed — random a preset, then adjust 2-3 sliders, ship

### B. Random button is mandatory above light scope
- Layered randomization > single button: "Random face", "Random hair", "Random outfit", "Random everything"
- 80% of players use it at least once
- Surprise + recognition triggers attachment

### C. Real-time 3D preview beats static portrait
- Even Stardew's 2D portrait *animates* (blink, slight bob)
- Best practice: rotating preview, click-and-drag to rotate, button to swap lighting (day/dusk/in-game)
- Cinematic framing > T-pose. 3/4 angle, slight downward tilt, soft fill light

### D. Body / voice / pronouns are now independent axes
- Modern (post-2020) standard. Skipping this in 2026 reads as dated.
- Default to "Body type" (one or two presets affecting frame), "Voice tone" (sets dialog pronouns), and a separate pronoun dropdown
- Don't gender-lock classes (BDO did, paid for it in critics' reviews and discourse)

### E. Save / load / share is the difference between attachment and friction
- BDO, FFXIV, Elden Ring all let players export their character data
- Community sites form — multiplier on game's lifespan
- Even minimal creators benefit: Stardew lets players reroll farm seed, share farm-name data

### F. Re-customization economy is a design lever
- **Free in-game** (RuneScape Makeover Mage, FFXIV initial Aesthetician) — keeps players experimenting, low friction
- **In-game gold cost** (WoW barber) — a money sink, see `mmo-game-design-playbook.md` §7
- **Paid item** (FFXIV Fantasia ~$10) — real revenue line for live-service games
- **Locked** (Cyberpunk's body type, Elden Ring's everything until mirror) — drives commitment but frustrates new players who realize they hate their choice in hour 3

### G. Pacing — when to creator
- **Before tutorial** (90% of games) — players want to be themselves before learning
- **After tutorial** (rare; e.g., Mass Effect 1 — Shepard's history is set first via Q&A) — works only if narratively justified
- **Backloaded** (Skyrim's race-locked features unlocking after racemenu mods) — typically a workaround for engine limits

### H. The 3-tab heuristic
Most successful creators organize as:
1. **Body** (race/body type, height, voice)
2. **Face** (presets, sliders, eye/hair color)
3. **Style** (outfit, accessories, makeup, scars)

More than 5 tabs and players get lost. Fewer than 2 and the depth feels token. Three is the sweet spot for medium creators.

---

## 4. The "is this character creator good?" smoke test

- [ ] Can a player who doesn't care ship in <90 seconds via presets + random button?
- [ ] Can a player who *does* care spend 30+ minutes without hitting a wall?
- [ ] Is the preview rotated, lit, and framed cinematically (not a flat T-pose)?
- [ ] Are body type, voice, and pronouns independent?
- [ ] Is the player's name visible in the preview area (so it feels real before they even ship)?
- [ ] Is there a clear "Begin" or "Confirm" button — and a clear "Back" to come back later?
- [ ] Is re-customization possible in-game without restart?
- [ ] Does the creator's aesthetic match the rest of the game (toon UI for toon game)?

---

## 5. Recommendations for gj26 specifically

Given the project's positioning (cozy RuneScape × HM, jam-scoped, browser-bound):

| Decision | Recommendation | Reason |
|---|---|---|
| Position on scope spectrum | **Light** (between OSRS and Stardew) | Match toon-painted, low-poly aesthetic; ship in jam |
| Customization categories | Name, hair color, skin tone, tunic color, cape color/none | Already implemented |
| Body type | Single body type for jam | Mesh swap = post-jam |
| Voice / pronouns | Skip for jam; use a single playerName interpolation | No voice in cozy text-only dialog yet |
| Random button | **Add** — high leverage, low cost | Universally used pattern |
| Presets | **Add 4 starter presets** (Bandit, Knight, Druid, Bard themed) | Unblocks indecisive players |
| Real-time preview | ✅ already shipped (rotating knight) | Keep |
| Re-customization | **Free at the cottage mirror** | Cozy default; no gold sink needed at jam |
| Save/share | localStorage only for jam; export-to-string post-jam | One feature at a time |
| Pacing | **Before tutorial** (already correct) | Standard |

### One concrete addition — the Random button

Three lines to add inside `cc-form`:

```html
<button id="cc-random" class="cc-secondary">🎲 Surprise Me</button>
```

```js
document.getElementById('cc-random').addEventListener('click', () => {
  for (const slot of ['hair', 'skin', 'tunic', 'cape']) {
    const opts = SWATCHES[slot];
    pick[slot] = opts[Math.floor(Math.random() * opts.length)];
    const row = root.querySelector(`#cc-row-${slot}`);
    row.querySelectorAll('.cc-sw').forEach(sw => {
      sw.classList.toggle('cc-sw-on', (sw.dataset.value || '') === (pick[slot] ?? ''));
    });
  }
  previewApply(pick);
});
```

### Future preset starters

```js
const PRESETS = {
  Knight:  { hair: '#3a2c20', skin: '#e2b48a', tunic: '#dfceaa', cape: 'red' },
  Druid:   { hair: '#7a3820', skin: '#b48868', tunic: '#7a9656', cape: 'green' },
  Bard:    { hair: '#c8a464', skin: '#f1d3b0', tunic: '#c7867a', cape: 'gold' },
  Wanderer:{ hair: '#1a1410', skin: '#7a5238', tunic: '#6f8aa3', cape: null },
};
```

Show as 4 small portraits across the top of the form. Click → applies preset → player adjusts from there. **This is the single biggest UX upgrade you can make to the existing creator.**

---

## 6. Key references

**MMO comparisons**
- [Massively OP — Character Customization Dealbreakers (2021)](https://massivelyop.com/2021/03/25/massively-overthinking-what-are-your-mmo-character-customization-dealbreakers/)
- [Gnomecore — WoW vs FFXIV Character Customization](https://gnomecore.wordpress.com/2021/09/15/character-customization-in-wow-and-ffxiv-pro-and-cons/)
- [MMOSumo — BDO vs FFXIV](https://mmosumo.com/black-desert-online-vs-final-fantasy-xiv/)
- [SellersAndFriends — BDO vs FFXIV](https://www.sellersandfriends.com/blog/black-desert-vs-ffxiv-which-mmo-is-better)

**Soulslike / Slider-share**
- [Elden Sliders (community preset library)](https://eldensliders.com/)
- [Elden Ring Wiki — Character Creation](https://eldenring.wiki.fextralife.com/Character+Creation)
- [GitHub — EldenBlingAutoSliders (slider import/export)](https://github.com/fazedankinbank/EldenBlingAutoSliders)

**Modern / Inclusive design**
- [Game8 — Cyberpunk 2077 Character Creation Guide](https://game8.co/games/Cyberpunk-2077/archives/Character-Creation)
- [Cyberpunk Wiki — Character Customization](https://cyberpunk.fandom.com/wiki/Cyberpunk_2077_Character_Customization)
- [GamesRadar — CDPR on Cyberpunk's Gender Options](https://www.gamesradar.com/cyberpunk-2077-gender-options/)
- [Sidequest — Gender Politics of the Cyberpunk Creator](https://sidequest.zone/2021/04/12/neither-nor-the-gender-politics-of-the-cyberpunk-character-creator/)

**UX patterns**
- [Game UI Database — Character Creator/Editor screens (curated)](https://www.gameuidatabase.com/index.php?scrn=38)
- [Medium — UX Process: Building a Simple Character Creator](https://medium.com/@fpocha/the-ux-design-process-building-a-simple-character-creator-5ae7eddb5597)
- [Ship of Heroes — Creating a Character with Randomizers](https://shipofheroes.com/creating-a-character-with-randomizers/)

**Cozy reference**
- [GameSpot — Fae Farm: Animal Crossing × Stardew](https://www.gamespot.com/articles/animal-crossing-meets-stardew-valley-in-fae-farm-a-new-cozy-sim-for-switch/1100-6507404/)
- [Her Cozy Gaming — 50+ Cozy Games like Stardew (2026)](https://hercozygaming.com/cozy-games-like-stardew-valley/)
- [Jazzybee itch.io — Stardew Valley Character Creator](https://jazzybee.itch.io/sdvcharactercreator)
