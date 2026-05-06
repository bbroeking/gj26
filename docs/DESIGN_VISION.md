# gj26 — Design Vision

**Status:** v3 in flight (3D, three.js, Blender pipeline)
**Date locked:** 2026-04-29
**Genre verdict:** RuneScape-lineage skill RPG with Harvest Moon-style cozy layer. Specifically: a **toon-painted browser life-sim with light combat**.

This doc makes the calls. It supersedes the v1 GDD where they conflict. Companion docs:
- `ART_BIBLE.md` — locked visual target
- `BLENDER_PIPELINE.md` — asset production
- `game-character-animation-playbook.md` — animation reference
- `mmo-game-design-playbook.md` — MMO theory (apply selectively)
- `cozy-life-sim-design-playbook.md` — cozy theory (apply liberally)

---

## 1. Pitch (locked)

**A toon-painted browser RPG where you live a slow life in a small fantasy village.** Chop trees, fish, cook, fight a goblin, learn a neighbour's name, watch the seasons turn — all in a 3D world that loads in under three seconds.

It's RuneScape Classic's skill loop with Stardew's heart. Family-friendly. Browser-native. Single-player at launch, designed so multiplayer is the obvious next step.

**One-line elevator:** *Stardew Valley meets RuneScape, in your browser.*

---

## 2. Why this and not something else

| Option considered | Verdict | Reason |
|---|---|---|
| Pure hardcore MMO | ❌ | Wrong art direction (cozy ≠ raid combat), wrong scope (years of dev), wrong audience |
| Pure cozy farm sim | ❌ | Loses the RuneScape DNA (skill levels, click-to-attack) that v1 already proved fun |
| 2D pixel RS-clone | ❌ | v1 shipped that. Fun but visually crowded market |
| **3D toon RS + HM hybrid** | ✅ | Underexploited niche. Browser-native is differentiator. Art bible already aligned. Fits existing src/ structure. |
| Multiplayer co-op cozy | 🟡 Defer | Right next step *after* solo proves the loop |

The hybrid is the design bet. Two underserved markets stacked: browser 3D life-sims (rare) and cozy + skill-grind (rarer).

---

## 3. Player & motivation

**Primary player type:** Achiever (Bartle).
- Skill levels, completion logs, "I got woodcutting to 50" feeling.
**Secondary:** Explorer / Socializer.
- Hidden NPCs and lore. Heart events with neighbours.
**Tertiary:** Killer.
- Light combat exists (goblins, mines). Never the focus.

**Five-minute promise:** A new player walks the meadow, chops a tree, fights a goblin, talks to Wizard Aric, sees one skill bar move and one heart fill. *They've touched all four player types in the first session.*

---

## 4. The hybrid loop

```
[Wake at home]
   │
   ▼
[Pick a goal: skill / quest / relationship]
   │
   ▼
[Move through world → click verbs (chop, fish, attack, talk)]
   │
   ▼
[Skill XP fills + items collected + hearts move]
   │
   ▼
[Energy drains → eat or sleep]
   │
   ▼
[Wake → next day, world ticks (crops grow, NPCs reset)]
```

Three nested loops:

| Loop | Window | Activity |
|---|---|---|
| **Micro** (seconds) | One click | Chop, swing, cast, gift |
| **Meso** (one day) | ~12 min real | Multi-task list, energy budget, NPC schedule, sleep |
| **Meta** (season = 28 days) | ~5–6 hrs | Skill milestones, festival, heart event, area unlock |

The day cycle is the central forcing function — it gives shape without punishment (see `cozy-life-sim-design-playbook.md` §4 & §8).

---

## 5. Locked decisions

### Combat
- **Click-to-attack tab-target.** Already in v1. Cheap, accessible, fits cozy.
- **Auto-stop when dead** — no death penalty beyond respawn at home + small XP loss (Stardew faint model, not RS PvP-grave).
- **Light variety:** 3 mob types max for jam (goblin, chicken, generic mine creature).
- **Combat is opt-in in 80% of zones.** Goblin field & mine are the only places mobs spawn; meadow/farm/village are safe.

### Skills (RuneScape lineage)
Multi-skill horizontal progression. Ship four for jam, defer the rest:

| Skill | Verb | XP source |
|---|---|---|
| Woodcutting | Chop trees | Per swing + per log |
| Fishing | Cast at water | Per fish caught (mini-game) |
| Cooking | Use cooking pot at home | Per dish cooked |
| Attack | Click mob | Per damage dealt |

Defer to post-jam: Mining, Smithing, Crafting, Construction, Magic, Farming-skill.

### Time & season
- **Day length:** 12 min real (Stardew middle ground).
- **Season:** 28 days; ship Spring only for jam. Other seasons = post-jam unlocks.
- **Forced sleep:** 2 AM → faint → wake at home, lose 10% gold cap. No items lost.
- **Energy:** caps at 100. Each verb costs 2–10. Eat to refill mid-day.

### NPCs & relationships
- **Six named NPCs for jam:** Wizard Aric (quest-giver), Cook (shopkeeper), Farmer (tutorial), Smith (gear), and 2 romanceable candidates.
- **5-heart cap** for jam (vs Stardew's 10) — tighter scope, faster reward.
- **Gift system:** each NPC has 1 loved / 2 liked / 1 hated item. Birthdays in calendar.
- **No marriage in jam.** Ship it post-launch.
- **NPC schedules:** simple — each NPC has 2 locations (home + workplace) and switches at fixed hours.

### Economy
- **Single currency:** gold.
- **Sinks:** shop purchases (gear, seeds, food), home upgrades, NPC gifts.
- **Faucets:** mob drops, sold goods, quest rewards.
- **No auction house, no trading** in jam — pure NPC economy. Player-driven economy is post-multiplayer.

### Quests
- **One spine quest** (Wizard Aric → kill goblin → return → unlock fishing).
- **Daily side hooks:** "Cook needs 3 fish today" — optional, refresh next day.
- **No quest log UI for jam** — current goal pinned top-left, RS-style.

### World
- **One zone:** Lumbridge Plains (matches v1 + ART_BIBLE hero shot 1a).
  - Sub-areas: Castle hub, Tree grove, Goblin field, Beach, Cottage (player home), Cook's kitchen.
- **No portals or teleport in jam.** Walking is the verb.
- **Hand-placed, not procedural** — keeps the painterly look.

### Multiplayer
- **Solo only at launch.**
- **But built so adding "see other players in the village" is a one-week add.** Persistence model uses player-keyed save state. Networking is a future render layer, not a redesign.

### Art
- **Locked to ART_BIBLE.md.** No deviation.
- **Toon-painted, hand-textured, no PBR-metallic look.**
- **Camera: 3/4 isometric tilted, near-orthographic.** Matches the art bible's reference framing.

### Tech stack
- **Vanilla three.js + ES modules + a single bundler (vite).** Already in flight.
- **No React, no R3F.** v3 src/ is plain JS, don't migrate mid-jam.
- **GLB everything** for models (per `BLENDER_PIPELINE.md`).
- **Save:** localStorage JSON for jam. Server persistence is post-multiplayer.

---

## 6. The "is this fun yet?" gate

Before adding *any* new content, the MVP must pass this 10-minute test:

- [ ] First 30 seconds: player understands movement and "click thing → thing happens"
- [ ] First 2 minutes: player has gained at least one skill XP and seen at least one number go up
- [ ] First 5 minutes: player has defeated one mob and talked to one NPC
- [ ] First 10 minutes: player has felt the day-cycle clock pressure once (something they wanted to finish before bed)
- [ ] No required tutorial popups; world teaches via affordances (yellow `!`, hover cursor, tooltip)

If the loop drags before the 10-minute mark, cut content, don't add UI.

---

## 7. MVP slice (jam-feasible)

**In scope (must ship):**
1. Lumbridge meadow zone (one biome, hand-placed)
2. Player character (knight) with walk/idle/attack/chop animations (Mixamo retarget)
3. Four skills (Woodcutting, Fishing, Cooking, Attack) with visible XP bars
4. Six NPCs, 5-heart hearts, simple gift system, schedules
5. One spine quest, two daily side hooks
6. Day/night cycle, energy, sleep-at-cottage
7. One season (Spring, 28 days), one festival event (day 14)
8. Inventory (12 slots), one shop, one cooking pot
9. Localstorage save on sleep
10. Basic SFX (chop, hit, level, sleep, gift)

**Out of scope (post-jam):**
- Multiplayer
- Marriage / romance unlocks beyond hearts
- Mining / Smithing / Crafting / Construction / Magic
- Multiple seasons
- Multiple zones
- Quest chains beyond the spine
- Auction house, player trading
- Mobile / touch controls
- Audio music score (placeholder loop only)

**Definition of "shipped":** a fresh browser visit lands in the meadow in <3s, plays for 10 minutes without crashing, and the player wants to come back tomorrow.

---

## 8. Risk register

| Risk | Likelihood | Mitigation |
|---|---|---|
| Day-cycle pacing feels wrong | High | Tune in week 1, not week 4 |
| Combat feels mushy in 3D | High | Pre-bake clear hit-stop frames; use SFX punch |
| NPC schedules feel dead | Medium | Two locations + dialog rotation per time-of-day |
| Save corruption | Medium | Versioned schema, defensive parsing |
| Browser perf below 60fps | Medium | See `threejs-stylized-bootstrap-playbook.md` — instancing, draw-call audit, frustum |
| Art inconsistency | Low | ART_BIBLE.md locked; reject anything that fails the hero-shot test |
| Scope creep | High | This doc is the gate. Anything not in §7 is post-jam. |

---

## 9. Post-jam roadmap (just so the doors stay open)

**v3.1** — second zone (forest), Mining + Smithing skills, animal husbandry (cow, chicken), summer season.

**v3.2** — multiplayer presence ("see other farmers in town"), shared festival events, no PvP.

**v3.3** — co-op (party of up to 4), instanced dungeons, real co-op cooking minigame.

**v4** — full life-sim feature set: marriage, kids, full year of seasons, all RS-classic skills.

The order is deliberate: prove fun → broaden content → add other humans → go deep. Don't reorder.

---

## 10. North star

> *A 12-year-old should be able to load this in a browser, play for ten minutes, learn one neighbour's name, and want to come back tomorrow.*

Every decision in §5 supports that sentence. When in doubt, re-read it.
