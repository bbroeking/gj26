# Cartography — Keystone System Design

The Cartography skill is the player's primary verb for crafting their own dungeon runs, in the spirit of WoW Mythic+ keystones. Every chart is hand-rolled with affix slots that change what spawns, how enemies behave, what the loot looks like, and how the run feels.

## Vision

A cartographer is **not a tourist** — they don't level up by walking the overworld. They level up by *making the maps*. Every chart they craft and complete is the verb that progresses the skill.

**Core loop:**

```
craft chart  →  slot affixes (good/bad-twin gambit)  →  spend ink  →  step into dungeon
                                                                            ↓
        Carto XP + ink + materials  ←  loot chest  ←  reach exit  ←  fight through
```

**Why a player crafts:**
- Better gear (boss affixes drop named uniques)
- Crafting reagents (mineral veins, ink fountains)
- Variety (the same dungeon never plays twice)
- The dance of building a keystone that's *just hard enough* — push too far and the bad twin lands

## Affix design space

Each affix has a **good twin** (lands on success) and a **bad twin** (lands on failure). Stability % is rolled at craft time; refined ink locks at 100%.

### Categories (6)

| Category | What it changes | Example |
|---|---|---|
| `bias` | What fills the dungeon (resources, density biome) | mineral_vein, bramble_bloom |
| `modifier` | Combat math on every enemy | tyrannical, bursting |
| `boss` | Replaces the deepest room with a named boss | hedgemother_den |
| `pacing` | Run timing, density waves, timer | festival_pace, sprinter |
| `risk` | High-stakes mods (death penalty, loot lock) | cursed_key, blood_pact |
| `atmosphere` | Visibility, lighting, sound; minor mechanical edge | fog_of_hedge, lantern_blessed |

## The full affix list (target: ~25 in v1.5)

Format: **id** — Good name (Bad twin) — *good outcome* / *bad outcome*. `Lv` = reqCarto. Bold rows are already shipped or in this PR.

### Bias (resource layer)
- **mineral_vein** — Mineral Vein (Barren) — *3-5 mineable rocks* / *no ore*. Lv 1
- **bramble_bloom** — Bramble Bloom (Wilted) — *4-6 forage spawns* / *no forage at all, dim look*. Lv 4
- **tinder_cache** — Tinder Cache (Damp Wood) — *3 hidden log piles* / *all rooms wet, stamina regen -25%*. Lv 6
- **ink_spring** — Ink Spring (Ink Salt) — *one room has 2-3 refined-ink rocks* / *all hedge_ink output halved on harvest*. Lv 18
- **gilded_seam** — Gilded Seam (Pyrite) — *coin chest in every room* / *fool's gold drops, vendor refuses*. Lv 20

### Modifier (combat math)
- **tyrannical** — Tyrannical (Erratic) — *enemies +50% HP* / *each enemy rolls a random secondary mod*. Lv 5
- **bursting** — Bursting (Spongy) — *enemies pop on death (small AoE, dodge to avoid)* / *enemies absorb 30% damage*. Lv 9
- **frenzied** — Frenzied (Sluggish) — *enemies +30% atk speed under 30% HP* / *enemies attack 30% slower (worse XP)*. Lv 12
- **quiver** — Quiver (Stoneskin) — *enemies dodge 15% of attacks* / *enemies start with 4 armor*. Lv 16
- **stoneflesh** — Stoneflesh (Brittle) — *enemies +5 armor, slower fights, +xp* / *enemies break easier, less xp*. Lv 22

### Boss
- **hedgemother_den** — Hedgemother's Den (Empty Throne) — *deepest room is her arena, drops thorn_crown* / *empty*. Lv 8
- **burrow_boar_den** — Burrow Boar's Wallow (Empty Wallow) — *boar boss + tusk drop* / *empty*. Lv 12
- **wolf_alpha_den** — Wolf Alpha's Roost (Cold Trail) — *fast pack-leader hedgewight* / *empty*. Lv 14
- **bog_stag_mire** — Bog Stag's Mire (Drained Pool) — *moss-deer boss, drops antler reagent* / *empty puddle*. Lv 26
- **briar_king** — Briar King's Garden (Locked Gate) — *secret hidden boss in alt-route room* / *blocked door*. Lv 40

### Pacing
- **festival_pace** — Festival Pace (Lockstep) — *+50% mob density, +30% xp* / *enemies patrol fixed routes only, less ambush*. Lv 7
- **pulse** — Pulse (Empty Halls) — *waves of mobs at 30s intervals* / *sparse, slow*. Lv 11
- **sprinter** — Sprinter's Run (Heart's Stone) — *5-min timer, ×2 chest if you make it* / *no timer, but stamina regen halved*. Lv 17

### Risk
- **cursed_key** — Cursed Key (Pity Token) — *+100% chest loot, but death drops your inventory inside* / *no bonus, no penalty*. Lv 30
- **heirloom_pact** — Heirloom Pact (Bonded Word) — *one item is "bound" and survives death* / *lose 2 random items on death*. Lv 22
- **blood_pact** — Blood Pact (Salt Circle) — *start at 50% HP, +30% xp* / *no benefit, no penalty*. Lv 25

### Atmosphere
- **fog_of_hedge** — Fog of Hedge (Lantern's Friend) — *minimap hidden, +xp on completion* / *minimap fully revealed, -xp*. Lv 10
- **mistwoven** — Mistwoven (Dust Choked) — *cinematic fog, +rare-drop chance* / *no boost*. Lv 15

## Chart templates

| ID | Tier | Reqs | Affix slots | Base cost | Flavor |
|---|---|---|---|---|---|
| `chart_snug` | 1 | Lv 1 | 0 | 1× hedge_ink | Tutorial cellar — guaranteed clean run |
| `chart_tier_1` | 1 | Lv 1 | up to 2 | 2× hedge_ink | Standard small dungeon |
| `chart_hollow` | 2 | Lv 10 | up to 2 | 3× hedge_ink | Multi-room, larger map (in this PR) |
| `chart_briar_maze` | 2 | Lv 15 | up to 2 | 3× hedge_ink | Twisted layout, more corridors than rooms (in this PR) |
| `chart_sunken_hut` | 3 | Lv 22 | up to 3 | 4× hedge_ink + 1× refined_ink | Wet rooms, atmosphere bias (in this PR) |
| `chart_delve` | 3 | Lv 30 | up to 3 | 5× hedge_ink + 1× refined_ink | Long, rich, hard |
| `chart_summit` | 5 | Lv 60 | up to 5 | 8× hedge_ink + 4× refined_ink | Future endgame keystone |

## Cartography XP — completion formula

The "+5 XP per new tile" overworld grant **stays** as a small drip-feed for early Lv 1-3 onboarding. The bulk of carto XP comes from **completing crafted runs**:

```
xp = (tier × 30) + (good_affixes × 25) + (bad_twins_resolved × 5)
   + (timer_bonus if sprinter affix)
```

Why bad twins still grant some XP — even a botched roll teaches the cartographer something. Slight comfort against the rng.

A Tier 1 with 2 good affixes = 30 + 50 = 80 XP. Lv 1→2 takes ~80 XP, so one chart per level early on. Tier 3 with 3 good affixes = 90 + 75 = 165 XP. Endgame Tier 5 with 5 good = 150 + 125 = 275 XP per run.

## What's left for v2

- **Heirloom retirement** — items in your bag that "survive" via heirloom_pact build personality (named items get a +1 bonus per dungeon survived).
- **Layout affixes** — bigger/smaller dungeons, branching paths, multiple floors.
- **Themed sub-dungeons** — Hollow / Sunken Hut / Hedge Maze get distinct tile sets.
- **Affix synergies** — combining `bursting + festival_pace` triggers a special "Pyre" event in one room.
- **Group-cartographer hooks** — share charts with friends (post-v2 multiplayer).

## Open design questions

- **Loot pity** — if you roll the bad twin five times in a row, does the next refined-ink lock cost half? (lean yes — feel-good crank)
- **Boss affixes** — should they cost the boss's signature item, so killing boss A lets you craft boss B's chart? (lean yes — combat → crafting loop)
- **Dungeon save state** — if a player closes the tab mid-dungeon, do they re-enter at the same spot? (V1: no, the chart is consumed. V2: maybe.)
