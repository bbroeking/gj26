# Lumbridge Plains — Game Design Doc

**Project codename:** `gj26` (Game Jam 2026 entry)
**Version:** v0.1 — 2026-04-26
**Owner:** —
**Status:** Level 1 prototype playable; planning Level 2+

---

## 1. Pitch (one line)
A browser-based, top-down RuneScape-like where every sprite is procedurally drawn from code — sprite forge meets old-school RPG.

## 2. Hook
Why does someone click "play" and stay 5 minutes?
- Nostalgic RS Classic loop: chop, fight, level up, brag.
- Procedural pixel art ("sprite forge") — every visual is data, not an asset file.
- Zero-install: open URL, you're playing in 2 seconds.
- Full Level 1 clearable in under 5 minutes — designed for jam-judge attention spans.

## 3. Core Loop (30-second player experience)
1. **Walk** → see something interactive (yellow `!`, tree, goblin).
2. **Click** → meaningful action (talk / chop / attack).
3. **Reward** → XP bar fills, item drops, log line confirms.
4. **Progress** → level up unlocks the next quest beat.

Decision cadence target: ~6 decisions / minute. Loop length: 5–15s.

## 4. Design Pillars
1. **Readable in 1 second** — every sprite identifiable at a glance.
2. **Click anything** — no menu trees, no modal dialogs.
3. **Skills > grind** — XP per action is generous; levels are meaningful but not paywalled.
4. **Code-as-art** — every visual is a char grid or a procedural draw call.

## 5. MVP Scope (Level 1) — ✅ shipped, 🟡 in-progress, ❌ todo

**Engine**
- ✅ 800×576 canvas, 25×18 tile grid
- ✅ Procedural tile renderer (grass, path, water, stone, sand, floor)
- ✅ Sprite baking from 16×16 char grids
- ✅ Y-sort entity render
- ✅ Smooth grid-tween movement + collision

**Player**
- ✅ 4-direction sprites
- ✅ HP, Attack XP, Woodcutting XP, level-up curve
- ✅ 12-slot inventory
- ✅ Death + respawn

**World (Lumbridge Plains)**
- ✅ Castle (enterable), path, tree grove, goblin field, beach corner
- ✅ Wizard Aric NPC w/ bobbing `!` marker
- ✅ 6 trees, 2 goblins, 2 chickens

**Mechanics**
- ✅ Click-to-attack combat, goblin AI (aggro/idle/respawn)
- ✅ Woodcutting (3-swing fell, 25s regrow, log drop)
- ✅ 4-step quest chain → "Level Complete" overlay

**Polish (to lock down before "done")**
- 🟡 Sound effects (chop / hit / level-up / death)
- ❌ Title screen with start button
- ❌ Screen-flash on damage
- ❌ Goblin death pop animation
- ❌ Footstep tile-aware sound (grass vs path)

## 6. Skill Matrix (locked v1)

Drawing from OSRS, New World (3-tier refinement, Camping, Salvaging, Azoth), Stardew (Profession choices, Friendship), Valheim (Sneak, Comfort, Food stacking).

### 6.1 Final skill list (13 skills + 3 meta-systems)

| # | Skill | Type | Verb | XP source | Lv5 Perk pick | Lv10 Perk pick |
|---|---|---|---|---|---|---|
| 1 | Attack | Combat | swing | melee hit | +5% accuracy / -10% atk cd | +1 dmg / 5% crit |
| 2 | Strength | Combat (auto) | — | melee kill | +1 base dmg / +1 hp on kill | +2 dmg / lifesteal 10% |
| 3 | Defence | Combat (auto) | — | hit taken | -1 dmg taken / +20% block | -2 dmg taken / 5% parry |
| 4 | Hitpoints | Combat (auto) | — | damage dealt | +2 maxHP / +1 regen rate | +5 maxHP / regen out of combat 2x |
| 5 | Woodcutting | Gather | chop tree | swing axe | +1 log/tree / 10% double | reveal trees on screen |
| 6 | Mining | Gather | pick rock | swing pick | +1 ore/rock / faster swing | reveal rocks on screen |
| 7 | Fishing | Gather | cast | tile cooldown | +1 fish/cast / rare fish chance | reveal fishing spots |
| 8 | Smelting | Refine | use furnace | ore→bar | -1 ore needed / 10% double | unlock iron / unlock steel |
| 9 | Smithing | Craft | use anvil | bar→weapon | -1 bar / +1 weapon dmg | unlock iron sword / + crit |
| 10 | Cooking | Craft | use range | raw→cooked | +heal amount / 10% no-burn | food stacking (3 slots active) |
| 11 | Cartography | Utility | walk | tiles explored | +map fog reveal radius | show treasure-X marks |
| 12 | Camping | Utility | place fire | place a campfire | +1 active fire / +regen aura | rested buff +20% XP rate |
| 13 | Sneak | Utility | crouch (Shift) | tiles crouched | -aggro radius / silent footsteps | first-strike crit from sneak |

### 6.2 Meta-systems (not skills, but tie everything)

- **Azoth** — purple gem currency. +1-3 from every gather/kill/cook. Spend on:
  - Fast travel between own campfires (5 azoth)
  - Guarantee crit on next swing (3 azoth)
  - Pixelweave a permanent sprite mote (10 azoth)
- **Resource Detection** — Gather skills ≥5 cause matching nodes to softly pulse on screen.
- **Profession choices** — at lv 5 and lv 10 of any skill, modal pops with two perks (Stardew-style).

### 6.3 Dependency graph (what feeds what)

```
Trees ──────► Logs ────► [Cooking fuel]
                  │
Chickens ─► Feathers ─► [future: Fletching]
                  │
Rocks ────► Ore ───► Bars ───► Weapons (Att+Str dmg)
              │       └──► [future: Armor (Def)]
              │
Water ────► Raw Fish ──► Cooked Fish ──► HP heal (food stack)
                              │
Goblins ──► XP, Azoth ◄───────┘ (Azoth feeds everything)

Tiles walked ──► Cartography (passive)
Tiles crouched ─► Sneak (passive, shift held)
Campfires ───► Comfort buff in radius (Camping perk)
```

### 6.4 Resource & item table

| Item | Source | Used in | Stacks |
|---|---|---|---|
| Log | tree (WC) | Cooking fuel, future Fletching | yes |
| Feather | chicken | future Fletching | yes |
| Copper Ore | copper rock (Mining) | Smelting | yes |
| Tin Ore | tin rock (Mining) | Smelting | yes |
| Iron Ore | iron rock (Mining lv 5+) | Smelting (lv 5+) | yes |
| Bronze Bar | 1 copper + 1 tin (Smelting) | Smithing | yes |
| Iron Bar | 1 iron (Smelting lv 5+) | Smithing (lv 5+) | yes |
| Bronze Sword | 2 bronze bar (Smithing) | Equipped: +1 atk dmg | no (equip) |
| Iron Sword | 2 iron bar (Smithing lv 10+) | Equipped: +2 atk dmg | no (equip) |
| Raw Fish | fishing spot | Cooking | yes |
| Cooked Fish | raw fish + range | Heal 4 HP | yes |
| Burnt Fish | failed Cooking | (waste) | yes |
| Azoth | any action | meta-currency | yes |

### 6.5 XP curves & balance

- **XP for level n**: `(n-1)² × 8` (already used; keep)
- **XP per action** (tuned for jam pacing — ~5 min to lv 5):
  - WC chop: 8 / Mining ore: 8 / Fishing catch: 8
  - Smelting bar: 6 / Smithing weapon: 14 / Cooking: 5 (+5 if not burnt)
  - Sneak: 0.5/tile, Cartography: 0.3/new tile, Camping: 5/fire placed
- **Damage formula**: `roll(1, 1+atkLv) + (equippedSwordBonus) + floor(strLv/3) - floor(targetDefLv/3)`
- **Hit chance**: `60% + atkLv*3% - targetDef*2%` (cap 95%, floor 30%)

### 6.6 Stretch — not in v1

| Feature | Source inspiration | Effort |
|---|---|---|
| Magic (runes, fireball) | OSRS | M |
| Ranged + Bow | OSRS/NW | M |
| Pixelweaving (sprite-mote crafting) | original | M |
| Palette Mastery | original | S |
| NPC Friendship & gifts | Stardew | M |
| Food stacking (3-slot buff) | Valheim | S (Cooking lv 10 perk hooks here) |
| Day/Night cycle | Stardew | S |
| Salvaging items → materials | NW | S |
| Tracking footprints | NW | M |
| Engineering / Arcana | NW | L (cut for v1) |

## 7. Cut List (do NOT build for jam)
- Multiplayer / netcode
- Trading economy / shops
- Procedural map generation
- Mobile touch controls
- Music / audio mixer
- Save server / accounts
- Animations beyond bob + flash

These are RS hallmarks. Each one alone eats the jam timeline.

## 8. Tech Stack
- HTML5 Canvas, vanilla JS, no build step
- Two files: `index.html`, `game.js`
- ~700 LOC target
- Deploy: drag-and-drop to itch.io as static HTML

## 9. Schedule (7-day jam — adjust to your jam length)

| Day | Goal | Status |
|---|---|---|
| 1 | Engine + tile + sprite + movement | ✅ |
| 2 | Tilemap + collision + combat skeleton | ✅ |
| 3 | Quest system + NPC + inventory | ✅ |
| 4 | XP/levels + woodcutting + win state | ✅ |
| 5 | **Audio + title screen + balance** | ← here |
| 6 | Playtest + bug bash |  |
| 7 | Submit (build, screenshots, blurb) |  |

## 10. Risks & Mitigations

| Risk | Likelihood | Mitigation |
|---|---|---|
| 16×16 sprites unreadable | medium | Fallback to 24×24; current sprites tested OK |
| Combat feels mashy | medium | Add cooldown ring around player on attack |
| Quest gating unclear | low | `!` marker bobs; add edge-of-screen arrow if playtests show confusion |
| Browser perf on low-end | low | Current build idles ≤2% CPU |
| Scope creep into Level 2 before Level 1 polish | **high** | Cut list above; review daily |

## 11. Open Questions
- [ ] Goblin loot drops? (gold → shop NPC?)
- [ ] Fixed 800×576 or scale-to-viewport?
- [ ] One save slot or none for jam build?
- [ ] How does the player know combat is on cooldown? Visual ring vs sword icon?

## 12. Submission Checklist (jam day)
- [ ] Title screen
- [ ] Screenshots (3): castle, combat, quest-complete overlay
- [ ] 60-second gameplay GIF
- [ ] itch.io blurb (under 80 words)
- [ ] Controls listed in description
- [ ] Tested on Chrome + Firefox + Safari
- [ ] No console errors on first load

## 13. Controls Reference

| Action | Input |
|---|---|
| Move (4 directions) | `W`/`A`/`S`/`D` or arrow keys |
| Interact with the tile in front (talk/attack/chop/mine/fish/cook/smelt/forge) | `Space`, `E`, or `Enter` |
| Equip / unequip a sword | click the sword in the inventory panel |
| Eat a Cooked Fish (+4 HP) | click it in the inventory panel |
| Pause / menus | none yet (add for v1.1) |
| Restart after Graduate overlay | "Play Again" button |

**Facing rule:** the interact key always targets the tile **directly in front of** the player — i.e., the tile in the direction of last movement. The yellow `[Space] <action>` prompt above that tile shows what will happen.

**Movement is the targeting:** to attack a goblin, walk up to it (player auto-faces the direction of the last keypress) and press Space. To chop a tree, face it and press Space. To talk, face the NPC and press Space.

**Why no clicks:** keeps both hands on the keyboard, plays well on laptops without a mouse, and matches old-school ARPG/roguelike feel.

**Cooldowns:** universal `attackCd` (frames) gates all attacks/chops/mines/cooks. Range:
- Attack swing: 60 frames (~1 s)
- Chop: 45 / Mine: 50 / Smelt: 60 / Smith: 70 / Fish: 50 / Cook: 60

(Cooldowns are intentionally chunky — feels weighty, prevents button-mash trivializing combat.)

---

## 14. Balance Tuning Sheet

This section is the source of truth for numbers. If you change a value in `game.js`, change it here too.

### 14.1 Combat formulas

```
damage  = roll(1, 1 + atkLv) + swordBonus
        + floor(strLv / 3)            (planned, not yet wired)
        - floor(targetDefLv / 3)      (planned, not yet wired)

hit     = always (no miss roll yet — planned for Defence skill)

sword bonus: bronze = +1, iron = +2
```

Boss goblin damage to player: 1 (with 30% chance of 2). HP regen: passive ~1 hp per ~12 s while not in combat.

### 14.2 XP curve

```
xpForLevel(n)   = (n-1)² × 8
xpProgress(xp,lv) = clamp((xp - xpForLevel(lv)) / (xpForLevel(lv+1) - xpForLevel(lv)) × 100)
```

Levels: 1 → 2 needs 8 XP; 2 → 3 needs 32; 3 → 4 needs 72; etc. Designed for fast early progression in the tutorial demo.

### 14.3 XP per action

| Action | Skill | XP |
|---|---|---|
| Goblin kill | Attack | +10 |
| Boss goblin kill | Attack | +30 |
| Chicken (feather pickup) | Attack | +2 |
| Tree felled | Woodcutting | +8 |
| Rock mined (copper/tin) | Mining | +8 |
| Rock mined (iron) | Mining | +14 |
| Bar smelted (bronze) | Smelting | +6 |
| Bar smelted (iron) | Smelting | +12 |
| Sword forged (bronze) | Smithing | +14 |
| Sword forged (iron) | Smithing | +24 |
| Fish caught | Fishing | +8 |
| Fish cooked | Cooking | +6 |
| Fish burnt | Cooking | +1 |

### 14.4 Resource respawn

| Resource | Cooldown |
|---|---|
| Tree | 25 s |
| Rock | 25 s |
| Fishing spot | 20 s |
| Goblin | 30 s |

### 14.5 Inventory

- 16 slots, no weight system
- One stack per item type (no split stacks)
- Equipped sword is shown with `★` on the slot

### 14.6 World dimensions

- Tile size: 32 × 32 px
- World: 32 × 24 tiles (1024 × 768 px)
- Viewport: 25 × 18 tiles (800 × 576 px)
- Camera scrolls; clamps to world edges

### 14.7 Onboarding pacing target

| Beat | Target time from spawn |
|---|---|
| Talk to Aric | 0:15 |
| First goblin kill | 0:45 |
| Forge bronze sword | 2:30 |
| Cook + eat fish | 3:30 |
| Boss spawned | 4:00 |
| Graduation | 4:45 |

If playtests run > 8 minutes, reduce mining swing count or increase XP rates. If < 3 minutes, lengthen the chain or add a side-objective.

### 14.8 Difficulty knobs (one-line tweaks)

| Want this? | Change |
|---|---|
| Easier combat | bump initial `player.hpMax` from 10 → 14 |
| Faster forging | drop bronze sword from 1 bar → 0 (give as a quest reward instead) |
| Boss more menacing | raise boss `hpMax` from 24 → 36 and damage range to (2-3) |
| Earlier mid-game | unlock iron at Mining 3 instead of 5 |
| More relaxed timer | raise resource respawn rates (×0.5) |
