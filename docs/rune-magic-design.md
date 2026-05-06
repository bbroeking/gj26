# Rune Magic — Design Doc

> RuneScape-flavored magic that grafts cleanly onto the Cartography vertical. Runes are not a separate skill tree — they're **ink made permanent**. The cartographer who masters inks naturally becomes a runesmith.

This is a **design-only** doc — no implementation yet. Read alongside:
- `cartography-skill-design.md` (the verb)
- `cartography-keystone-design.md` (chart affixes)
- `cartography-inscribing-table-design.md` (ink mixing)

## The pitch in one sentence

**An ink + a rune-stone + a chant = a permanent rune. Runes are spell ingredients you carry into the world, cast at the right moment for combat, gathering, or travel utility.**

## Why integrate with Cartography (not a separate Magic skill)

Three reasons:
1. **The crafting pipeline already exists** — ingredients → inks → charts. Adding "→ runes" is a one-step extension, not a new vertical.
2. **Cozy world budget** — gj26 is small. A standalone Magic skill with its own gather/craft/cast loop would double the surface area. Sharing infrastructure keeps it tight.
3. **Diegetic fit** — RuneScape's runes were *literal carved stones with magic words on them*. A cartographer **carves** maps. The verb shape matches.

The magic stat in the player skill list could be either:
- **`magic` skill** that levels independently (RuneScape-true), gated by carto for crafting
- **Folded into `carto`** so high-carto = high magic (simpler, more cozy)

Lean: **separate `magic` skill**, but every magic skill-up requires carto-crafted runes. So you can't level magic without leveling carto. Two skills, one verb-supply pipeline.

## The recipe — how runes are made

```
   ┌─ Cartography ─┐    ┌─ Runesmithing ─────────┐    ┌─ Magic ────┐
   │  ingredients  │    │                          │    │            │
   │       ↓       │    │  rune-stone + ink + chant│    │  cast spell│
   │     inks    ───→──→│  → permanent rune        │───→│  in world  │
   │                │    │                          │    │            │
   └────────────────┘    └──────────────────────────┘    └────────────┘
```

### Inputs

- **Rune-stone** — a small carved blank, dropped from mining nodes (rare) or crafted from `bogiron_ore + 1 charcoal_stick + 1 hedge_ink`. Stackable item.
- **Ink** — already exists; specific inks press into specific rune types.
- **Chant** — a one-line verbal recipe, learned by reading **chant scrolls** (rare dungeon drop) or from **Brother Pell** (the Cloister monk). Without the chant, the press fails.

### Output

- **Rune item** — stackable consumable. Each cast spends 1 rune.
- **Bonus**: if you press with **refined ink**, the rune becomes a **Refined Rune** (50% chance to *not* consume on cast, like Skyrim's Atronach perk).

### Where you press

A new placeable: the **Runestone Pedestal** in the Cloister (a new room added to the village or unlocked after Brother Pell's intro quest). Click → opens a 3-slot UI (rune-stone center, ink left, chant scroll right) → press → rune item lands in bag.

This is *separate* from the Inscribing Table. Both produce things; they don't share a screen.

## The rune families (RuneScape-flavored)

Thirteen runes, grouped into Common / Catalyst / Rare. Each rune lets a spell do *one* effect; spells combine multiple runes.

### Common runes (Lv 1-30 magic)

| Rune | Pressed from | Used for |
|---|---|---|
| 🌬 **Air** | Hedge Ink + Air Chant | Wind Strike, Push Back, Levitate |
| 💧 **Water** | Wellspring Ink + Water Chant | Water Strike, Quench, Slow Bog |
| 🪨 **Earth** | Stoneground Ink + Earth Chant | Earth Strike, Stone Skin, Rooted |
| 🔥 **Fire** | Bramblepress Ink + Fire Chant | Fire Strike, Ignite, Warmth |
| 🧠 **Mind** | Charcoal Bind + Mind Chant | Sense Aggro, Quiet Thought, Doubt |
| 💪 **Body** | Refined Ink + Body Chant | Hold Person, Trip, Vigor |

### Catalyst runes (Lv 30-60)

These don't supply elemental energy — they *enable* tier-2 spells.

| Rune | Pressed from | Enables |
|---|---|---|
| 🌀 **Chaos** | Bog Ink + Refined Ink + Chaos Chant | Tier-2 attack spells (double damage of base elementals) |
| ⚖ **Cosmic** | Lustrous Ink + Aurora Shard + Cosmic Chant | Travel + utility (teleport, summon, scry) |
| 🚪 **Law** | Atlas Ink + Law Chant | Tier-3 utility (full teleport, dungeon-bind) |
| 🌫 **Nature** | Hedgemother's Thorn + Bog Ink + Nature Chant | Plant + animal magic |

### Rare runes (Lv 60+)

| Rune | Pressed from | Enables |
|---|---|---|
| ☠ **Death** | Wightblood Ink + Death Chant | Necrotic spells, undead binding |
| 🩸 **Blood** | Aurora Ink + Hedgemother's Thorn + Blood Chant | Self-fuel spells (HP-cost casts, heavy damage) |
| ✨ **Soul** | Atlas Ink + master_chart_bramblewood + Soul Chant | Endgame: unique-named spells |

## The spell list — combinations matter

RuneScape's pattern: each spell consumes a *specific combo* of runes. No improvising — you either have the right runes or you don't.

| Spell | Tier | Magic Lv | Ingredients per cast | Effect |
|---|---|---|---|---|
| **Wind Strike** | Common attack | 1 | 1 air + 1 mind | small damage on a creature in sight |
| **Water Strike** | Common attack | 5 | 1 water + 1 mind | medium damage; slows water-vulnerable foes |
| **Earth Strike** | Common attack | 9 | 1 earth + 1 mind | medium damage; +50% vs. wood foes |
| **Fire Strike** | Common attack | 13 | 1 fire + 1 mind | medium damage; lights bramble-imps on fire |
| **Sense Aggro** | Utility | 6 | 1 mind + 1 air | reveals all aggroed enemies on minimap (60s) |
| **Quench Stamina** | Utility | 8 | 1 water + 1 body | refills 30 stamina |
| **Stone Skin** | Buff | 12 | 1 earth + 1 body | +30% defense for 30s |
| **Ignite** | Utility | 14 | 1 fire + 1 air | sets a target tile on fire (dungeon brazier) |
| **Levitate** | Travel | 16 | 2 air + 1 cosmic | crosses a 3-tile water gap |
| **Quiet Thought** | Utility | 18 | 2 mind + 1 chaos | enemies near player lose aggro for 8s |
| **Wind Wave** | Tier-2 attack | 24 | 3 air + 1 mind + 1 chaos | AoE knockback in 3-tile radius |
| **Water Wave** | Tier-2 attack | 28 | 3 water + 1 mind + 1 chaos | AoE damage + slow |
| **Vigor** | Buff | 30 | 2 body + 1 cosmic | restores 30 HP over 10s |
| **Teleport: Bramblewood** | Travel | 33 | 1 law + 3 air | warp to village spawn from anywhere |
| **Teleport: Last Chartmaker** | Travel | 35 | 1 law + 3 cosmic | warp back to the chartmaker's stone |
| **Bind Plant** | Nature | 38 | 1 nature + 2 earth | roots an enemy in place for 6s |
| **Animal Sight** | Nature | 41 | 1 nature + 2 air | falcon scouts a 5-tile radius for 30s |
| **Holdinghut** | Travel | 50 | 1 law + 1 cosmic + 1 nature | bind a "home tile" — teleport here free for 1 game-day |
| **Death's Whisper** | Death attack | 60 | 1 death + 1 chaos + 2 fire | high damage; the dying enemy briefly fights for you |
| **Blood Pact** | Risk | 70 | 1 blood + 2 fire + 1 chaos | -2 HP self → +200% damage on next swing |
| **Soul Bind** | Endgame | 85 | 1 soul + 1 law | a slain rare drops a unique always |

## Magic skill leveling

| Lv | Title | Unlock |
|---|---|---|
| 1 | Apprentice | Wind Strike |
| 5 | Charmer | Water Strike, Sense Aggro |
| 9 | Stoneword | Earth Strike, Stone Skin |
| 13 | Firebrand | Fire Strike |
| 16 | Stepwalker | Levitate, Ignite |
| 18 | Whisperer | Quiet Thought |
| 24 | Stormcaller | Wind Wave |
| 28 | Tideturner | Water Wave |
| 30 | Vigour | Vigor |
| 33 | Walker | Teleport: Bramblewood |
| 35 | Pathwarp | Teleport: Last Chartmaker |
| 38 | Bindword | Bind Plant |
| 41 | Eyes-of-the-Falcon | Animal Sight |
| 50 | Hold-warden | Holdinghut |
| 60 | Bone-speaker | Death's Whisper |
| 70 | Bloodpact | Blood Pact |
| 85 | Bound-soul | Soul Bind |
| 99 | Archmage of Bramblewood | Cape: +5% spell cost reduction, all common runes pressed at no ink cost |

## XP for magic

- **Casting a spell** awards magic XP based on tier × runes spent.
- **Pressing a rune** awards small magic XP (1-5).
- **Reading a chant scroll** awards 25 magic XP (one-time per chant).

This keeps the magic loop tight: gather → press → cast → repeat. The cartographer grinds carto by inscribing charts; the mage grinds magic by *casting in runs they create*.

## Cross-skill bleed (already designed)

| Cartography | → | Magic |
|---|---|---|
| Inks (T1) | press into | Common runes |
| Refined Ink | press into | Body rune (catalyst) |
| Bog / Lustrous Ink | press into | Chaos / Cosmic runes |
| Aurora / Wightblood Ink | press into | Death / Blood runes |
| Atlas Ink | press into | Law / Soul runes |

A high-carto player has the entire rune palette available at their bench. A new carto player is limited to common runes.

## How runes integrate with charts

Two integration points:

### A. Rune slots in chart inscription (Lv 50+)

At Lv 50 carto + Lv 30 magic, charts gain an optional **rune slot** — drop a rune into the chart and the dungeon ITSELF carries an effect:
- **Air rune** in chart → all enemies inside have -1 dmg
- **Earth rune** in chart → walls have +30% drop chance for stone chips
- **Fire rune** in chart → braziers throughout, brighter visibility

This is the late-game loop: carto crafts the rune, then *bakes it into a chart*, then runs the chart.

### B. Rune-Spell combos in dungeons

Players bring runes as consumables. Casting Wind Strike inside a chart deals damage *and* triggers the chart's affix interactions if the affix matches the rune element:
- Wind Strike + `tinder_cache` chart → combo flame ignites all log piles for bonus XP

This is a content-pressure-relief: your prep choices (which inks → which runes → which charts) produce emergent combos in run.

## What this design deliberately avoids

- **Mana bar** — no separate resource. Runes ARE the resource.
- **Spell-leveling per-spell** (Final Fantasy style) — flat magic skill instead.
- **Complex elemental rock-paper-scissors** — element bonuses are flat +%, not arrows of weakness.
- **Touch-target combat** — every spell has range and can be cast from movement.

## Open design questions

1. **Magic skill: separate or under carto?** Lean: separate. Two skill-up tracks for two different verbs.
2. **Runes consumed always or sometimes?** Lean: always common; refined runes 50% chance to keep.
3. **Chant scrolls — where do they drop?** Lean: dungeon chests, weighted by tier (T1 charts drop common chants, T3 drops catalyst chants).
4. **Rune-stone source?** Lean: rare mining drop + craftable (bogiron + charcoal + hedge_ink).
5. **Cast input — keybind or hotbar?** Lean: hotbar. Slot 5 is currently quick-quaff; slots 6-8 could become spell hotkeys at Lv 1+.
6. **Multi-target spells?** Lean: only AoE-tier-2 spells get them. Single-target is the default.
7. **Spell "miss" mechanic?** Lean: hits always land but damage is rolled (5-12 range for Wind Strike) so it's still random.
8. **Visual presentation** — runes drawn from above as small carved stone discs in inventory, with the elemental glyph in burnished gold.

## Implementation phases

If we ever ship this:

### Phase A (the bare minimum slice)
- Rune-stone item (drop from mining)
- Magic skill in `SKILL_KEYS`
- Runestone Pedestal placeable + UI
- 3 common runes (Air, Earth, Fire)
- 3 spells (Wind Strike, Earth Strike, Fire Strike)
- Cast hotkey → projectile + damage
- Magic XP grant on cast

### Phase B
- Catalyst runes + tier-2 spells
- Chant scrolls
- 6 more spells

### Phase C
- Rare runes + endgame spells
- Rune slots in chart inscription
- Magic 99 cape

## TL;DR

Rune Magic is **inks pressed into permanent stones**. Stones combine into spells. Magic levels separately from Carto, but every rune is gated by Carto's ink palette. RuneScape's elements (Air/Water/Earth/Fire/Mind/Body/Chaos/Cosmic/Law/Nature/Death/Blood/Soul) all map naturally onto the cartography ink set we already designed.

**~22 spells across 3 tiers**. Magic 1-99 covers the whole content slope. Two cross-skill integrations (chart rune slots + run-time combos) keep cartographers and mages in the same play space without merging the verbs.

Implementation is meaningful but not heroic — Phase A is ~1 week, full system is ~3 weeks. Recommend **shipping after Cartography Phase 3 lands** so we have a stable carto loop to graft onto.
