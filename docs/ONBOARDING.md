# gj26 — Onboarding Flow

Modeled on OSRS Tutorial Island: **one NPC per system, can't progress without completing each step.** Adapted for gj26's cozy scope (4 skills + relationships + day cycle, vs OSRS's 10+ skills).

The onboarding lasts ~10 minutes and is the **single most important UX in the game** — see retention data in `mmo-game-design-playbook.md` §5: launch-month players have 10x the retention of later cohorts, and the first 10 minutes determine whether they stay.

---

## 1. The OSRS Tutorial Island reference

Canonical OSRS sequence:

| Stage | NPC | Teaches |
|---|---|---|
| 1 | RuneScape Guide | Movement, camera, minimap, talk-to-NPC |
| 2 | Survival Expert | Fishing, woodcutting, firemaking, cooking, inventory |
| 3 | Master Chef | Cooking deep-dive, music, run toggle |
| 4 | Quest Guide | Quest journal |
| 5 | Mining Instructor | Mining + smithing |
| 6 | Combat Instructor | Melee + ranged, equipment, combat styles |
| 7 | Financial Advisor | Banking, money |
| 8 | Brother Brace | Prayer, friends list |
| 9 | Adam & Paul | Game modes (ironman) |
| 10 | Magic Instructor | Magic spell-casting |

What works about it:
- **One concept per NPC** — never overload
- **Can't skip** — gates ensure every system is touched
- **Hands-on, not text** — chop a tree, kill a rat, cook the shrimp
- **Branded NPCs survive into the main game** — Survival Expert appears later, sells fishing nets

What we copy: structure. What we cut: scope. gj26 only has 4 skills, 1 zone, ~6 NPCs at jam.

---

## 2. gj26 onboarding sequence

### Stage 0 — Title screen
- "Lumbridge Plains" title in IM Fell English, painted-on-parchment treatment
- Single button: **Begin Adventure** (or **Continue** if save exists)
- Background: dimmed Hero shot 1a (golden-hour meadow) with a pulse of light through the cottage window

### Stage 0.5 — Character Creation ⭐ (this doc's deliverable)
- Modal screen, no game running behind
- Player picks: name, hair color, skin tone, tunic color, cape color
- Live 3D preview of the character rotates slowly
- "Begin" button writes save and transitions to Stage 1

### Stage 1 — Wake up at the cottage (Wizard Aric)
**Maps to: OSRS Stage 1 (RuneScape Guide).**
- Player wakes inside the cottage. Camera fades in.
- Wizard Aric stands by the door with a `!` floater.
- Click on him → dialog: *"Welcome to Lumbridge, {playerName}. Walk outside when you're ready."*
- **Teaches:** click-to-move, click-to-talk, dialog flow.
- Yellow arrow points to the cottage door.

### Stage 2 — Chop your first tree (Farmer Brom)
**Maps to: OSRS Stage 2 (Survival Expert).**
- Outside. Farmer Brom stands by an oak with `!`.
- Talk: *"Take this hatchet. Try chopping the tree behind me."*
- Hatchet lands in inventory (slot 0). Inventory pulses once.
- Player clicks the tree → 3-swing fell animation → log drops → +25 Woodcutting XP.
- **Teaches:** inventory open, woodcutting verb, XP bar fills, item drops, click-to-action.

### Stage 3 — Cook the meal (Cook Cynthia)
**Maps to: OSRS Stage 3 (Master Chef).**
- Cynthia in the cottage kitchen. `!`.
- Dialog: *"Cooking warms the bones. Use the pot — make us breakfast."*
- Player clicks the cooking pot → log + raw fish (gifted) → cook animation → meal in inventory.
- **Teaches:** Cooking verb, item-to-station interaction, energy refill from food.
- After cook: prompt to **eat** the meal → energy bar fills → visible feedback.

### Stage 4 — Fight the goblin (Smith Gareth)
**Maps to: OSRS Stage 6 (Combat Instructor).**
- Gareth stands outside the smithy. `!`.
- Dialog: *"A goblin crept up at the field's edge. Take this sword and see it off."*
- Sword auto-equips. Player walks to goblin field → clicks goblin → combat starts.
- **Teaches:** equip from inventory, click-to-attack, HP bar, combat target card, damage floaters, kill → XP.
- Goblin drops a copper coin on death.

### Stage 5 — Sell and buy (Cook Cynthia, return)
**Maps to: OSRS Stage 7 (Financial Advisor).**
- Cynthia again. `!`.
- Dialog: *"Bring me a fish if you find one — I'll trade you for seeds."*
- Player walks to the dock → clicks water → fishing animation → fish caught → return to Cynthia → trade.
- **Teaches:** Fishing verb, NPC trade, gold drop.

### Stage 6 — Make a friend (Romance NPC #1)
**Maps to: OSRS Stage 8 (Brother Brace, friends list).**
- Romance NPC stands at the village edge. `!`.
- Dialog: *"You're new here. Talk to me again sometime — bring me something pretty."*
- Tooltip on the heart icon explains the gift system.
- **Teaches:** gift system, heart progression, NPC schedules.

### Stage 7 — Sleep (cottage)
**Maps to: end-of-tutorial, no direct OSRS analogue.**
- Player walks back to cottage as the sky dims.
- Click bed → "Sleep until morning?" → fade to black → wake next day.
- Energy refills. Tomorrow's tasks pinned in quest log.
- **Teaches:** day cycle, sleep verb, save-on-sleep.

### Tutorial complete
- Quest log clears tutorial steps.
- Wizard Aric pins next quest: *"The goblin camp is back. Investigate the field."*
- Free-roam unlocks. Festival prep begins (day 14).

---

## 3. UX rules for the tutorial

| Rule | Why |
|---|---|
| Yellow `!` over the next NPC at all times | New players fixate on the highlight |
| Dialog auto-advances on click; never timed | Reading speed varies wildly |
| Disable hostile actions outside the goblin field for tutorial | No one rage-quits because they got attacked while reading |
| Each verb is taught in **isolation** before being combined | One concept at a time |
| Every action gives positive feedback within 200ms | XP floater, sound cue, bar update |
| Tutorial-state lives in `player.quest.tutorialStage` (number 0–7) | Resumable if they refresh the tab |
| Tutorial cannot be re-entered after completion | But "tutorial mode" toggle in settings can replay tips |

---

## 4. Character Creation — full spec

### Goal
A 60–90 second screen that produces a personalized character, locks it into save state, and transitions into Stage 1.

### Customization options (jam scope)

| Option | Type | Choices | How it's applied |
|---|---|---|---|
| **Name** | Text input, max 12 chars | Player-typed | Stored in save; used in dialog |
| **Hair color** | 4 swatches | Brown, blonde, black, auburn | Material color on `Head` mesh hair sub-region |
| **Skin tone** | 4 swatches | Light, tan, brown, deep | Material color on `Body`, `Head`, arms, legs (skin parts) |
| **Tunic color** | 4 swatches | Cream, blue, green, rose | Material color on `tunic_skirt_cream` equipment |
| **Cape color** | 4 swatches + "none" | Red, blue, green, gold, no cape | Loadout swap: `cape_red` / `cape_blue` / `cape_green` / `cape_gold` / omit |

### Layout

```
+----------------------------------------------------------+
|                  Name Thy Adventurer                     |  ← title in IM Fell English SC
|                                                          |
|   +-------------+    +------------------------------+    |
|   |             |    |  Name:  [____________]       |    |
|   |   3D Char   |    |                              |    |
|   |   Preview   |    |  Hair:  [▼][▼][▼][▼]         |    |
|   |   (rotate)  |    |  Skin:  [▼][▼][▼][▼]         |    |
|   |             |    |  Tunic: [▼][▼][▼][▼]         |    |
|   |             |    |  Cape:  [▼][▼][▼][▼][✕]      |    |
|   +-------------+    |                              |    |
|                      |                              |    |
|                      |     [ Begin Adventure ]      |    |
|                      +------------------------------+    |
+----------------------------------------------------------+
```

### Data shape (what gets saved)

```js
{
  name: "Aldric",
  appearance: {
    hair:   "#3a2c20",   // hex from chosen swatch
    skin:   "#e2b48a",
    tunic:  "#dfceaa",
    cape:   "red",       // or null for no-cape
  },
  // ... rest of save state
}
```

### Persistence

- Save written to `localStorage['gj26.save']` on **Begin Adventure** click.
- On subsequent visits: detect existing save → skip character creation → land in Stage 1 (or whatever `tutorialStage` is).
- "New game" button on title screen wipes save and re-enters character creation.

### Integration points

1. `index.html` — add `#char-creator` modal markup
2. `src/ui/charCreator.js` — new module, exports `showCharCreator(): Promise<CharData>`
3. `src/ui/tokens.css` — extract design tokens from existing index.html `:root` (formalization side-quest)
4. `src/main.js` — call `showCharCreator()` before the game loop kicks off; pass result to `createPlayer()`
5. `src/scene/characters.js` — extend `buildKnightMesh()` to accept `appearance` and apply material colors

---

## 5. Post-jam onboarding additions

- **Audio cues** for each tutorial action (chop, cook, sword swing, level up)
- **Skippable tutorial** for returning players (toggle on title screen)
- **Tutorial replay** option in settings menu
- **Multilingual support** (most cozy games punch above weight here)
- **Mobile-friendly layout** for character creator (stack vertically on narrow screens)
- More mesh-swap options (hair *style*, not just color)
- Animation preview during creation (character does an idle pose, occasional wave)
