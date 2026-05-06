# What's next — a research synthesis (Apr 2026 state)

> Honest gap analysis after ~60 commits worth of polish. Sourced from
> Stardew Valley dev logs (ConcernedApe blog, GDC 2017), Hades + Death's
> Door postmortems (Supergiant, Acid Nerve), Last Epoch dev streams,
> OSRS update cadence (Jagex blog), Cult of the Lamb interviews
> (Massive Monster), and GMTK's "What makes a good progression curve"
> + "What is lootboxing actually doing." References at the bottom.

## Where Bramblewood is, honestly

After this session's pass, on the seven-pillar ARPG-feel scoring:

| Pillar | Score | Δ from start of session |
|---|---|---|
| 1. Input → action latency | 8/10 | — |
| 2. Hit feedback density | 8/10 | +2 (kill flourish + crit splats + emissive flash already-wired) |
| 3. Damage curve readability | 7/10 | +2 (kind-scaled splats) |
| 4. Power fantasy curve | 4/10 | — |
| 5. Animation timing & weight | 7/10 | +1 (smoothstep movement, idle breath) |
| 6. Targeting forgiveness | 8/10 | — |
| 7. World response | 8/10 | +3 (kill flourish, hit-flash) |

Average **6.6 → 7.1**. Felt sense: combat is fluid. The bottleneck has
shifted off feel and onto **content + loop**.

## The actual gaps (gap analysis)

### Loop integrity (where players bounce)

The current 30-minute experience for a new player:

1. min 0-2: tutorial guides them through walk → attack → kill → eat → loot
2. min 3-15: kill goblins / brindlecows in the meadow, level basic combat
3. min 15-25: talk to Maud, accept quest, gather X, return — first quest cycle
4. min 25-30: open inscribing table, mix ink, transmute rune, inscribe chart, enter dungeon
5. min 30+: ???

**The bounce point is around minute 30.** Once you've seen the chartmaker
loop once, what's the second hour? Right now:
- More dungeons (same content)
- More combat (same enemies)
- More skills to level (same XP grind)

Successful peers extend hour-2 with:
- **Stardew Valley**: seasonal calendar (each in-game day adds new
  spawns/forageables/festivals); NPC schedules + relationships; mine
  depth gates
- **OSRS**: skill diversity (every skill has a meaningful self-contained
  loop with its own progression tree)
- **Death's Door**: tight bosses you can replay with new tools
- **Hades**: meta-progression (Mirror of Night) that re-frames every
  run with new options
- **Cult of the Lamb**: cult-management meta-loop runs in parallel to
  combat runs

### Reward density (where the dopamine is thin)

Right now every kill produces:
- XP (skill gain)
- Sometimes a drop (raw meat, hide, occasional ore-bar)
- Maybe a coin

Compared to ARPG peers, the **drops feel transactional, not like
gifts**. Diablo's loot is the entire game; ours is a list-item in the
inventory.

What's missing:
- **Drop physics** — items should *fall from* the corpse with a small
  arc, not just appear in inventory
- **Rarity color** — common (white) / uncommon (green) / rare (blue) /
  unique (gold) with a matching audio chime per tier
- **Loot magnetism** — items within 1.5 tiles auto-pick up while you
  walk past
- **Coin pile rendering** — coins on the ground as a small spinning
  3D model, not just a number tick

The ratio of effort to "this kill felt rewarding" is heavy on effort
and light on reward right now.

### Sound (single biggest underutilized lever for solo devs)

Combat SFX exist (hit, miss, crit, footstep, eating, level-up jingle,
sparks). Missing:
- **Ambient music** — village vs meadow vs dungeon should have distinct
  tracks. Right now: silence under a distant ambient drone.
- **Discovery stings** — small chord on entering a new area, opening
  a chest, finding a rare item. Stardew's "ba-ba-bah" on every chest.
- **Boss intro music** — Hedgemother's banner shows but no audio cue
- **Tension layer** — a low drone fades in when an enemy is aggro'd,
  fades out when combat ends. Hades + DOOM both use this; cheap.

Sound is the *cheapest* per-impact polish a solo dev can do. ~5 audio
clips per area, free CC0 sources, plus a tiny scheduler in `src/core/sfx.js`.

### Boss content (Hedgemother is the only differentiated fight)

We shipped Hedgemother's bramble-pull this session. The other two
bosses (Burrow Boar, Wolf Alpha) still use the generic boss AI scaffold
— telegraphed slam OR lash, no signature mechanic. The design doc
already has the proposals:

- **Burrow Boar**: emerge-charge — disappears 3s, surfaces in a charge
  line, dodge or take heavy hit
- **Wolf Alpha**: pack-summon — at 50% HP summons 2 wolfpups, the
  player must AoE or get worn down

Each ~50 lines of code, reuses existing infra. Three differentiated
bosses elevate the world from "one boss + 2 reskins" to "three
genuinely distinct fights."

### Tutorial → onboarding past tutorial (the "what do I do at level 5" gap)

The 7-step tutorial chain is solid for the first 15 minutes. After
that the player is on their own. There's no:

- Persistent on-screen quest tracker
- "Suggested next" hint when an objective closes
- Tier-up celebration when a skill crosses a milestone
  (we have the milestone modal — but it's at level 5/15/22/etc., not
  every 5 levels)
- Daily-login style "today's recommended" prompt

Stardew Valley's calendar is a masterclass here — it gives the player
a "what to do today" without the game telling them what to do.

### Equipment depth (the late-game tier-curve hole)

Currently:
- Tier 1: Brindle (sword, dagger, axe, pickaxe, bar, ore alloy)
- Tier 2: Bogiron (sword, dagger, axe, pickaxe, cuirass, shield)
- Tier 3: Cinderbloom (sword, dagger, axe, pickaxe, plate, helm, shield)

What's missing:
- **Combat-axe family** — currently axes are pickaxe-tools, not combat
- **Trinket slot** — passive bonuses, room for build expression
- **Tier-4 named weapons** — endgame chase items
- **Affixes on weapons** (currently only on dungeon charts) — gives
  build crafting depth

Adding these turns combat from "one optimal build" to "what build do I
feel like running today?"

### Spell stubs (8 of 21 spells still demoted)

We shipped the visual badge for v2-stubs in the spellbook this session,
but 8 spells are still un-implemented:
ignite, quiet_thought, levitate, bind_plant, animal_sight, holdinghut,
blood_pact, soul_bind.

Cheapest 2 to implement (per pillars 4 + content depth):
- `quiet_thought` — drop nearby aggro for 8s. ~20 lines: walk enemies'
  aggro flag, log a hint
- `ignite` — light a target tile on fire, 1.5s burn DoT.
  ~30 lines: target tile + visual flame + DoT tick

The other 6 are bigger fish.

## Top 3 recommendations (ranked by impact / cost ratio)

### #1 — **Loot juice pass** (≈2 hours, MASSIVE impact)

Every drop becomes a gift. Specifically:
- Items render as small 3D models on the ground (rotating, with a
  ground-puddle-of-glow underneath)
- 4-tier rarity color: white → green → blue → gold
- Tier-matched audio chime on drop (3 short clips)
- Pickup auto-magnetism within 1.5 tiles (coins suck toward player)
- Coin pile renders as a small stack of coins, not a flat icon
- Floater on pickup ("+5 Coin" "+1 Iron Ore")

This single pass would push pillar 4 (power fantasy) from 4/10 to 7/10
and double the per-kill dopamine. Not new content — making existing
content sing.

### #2 — **Two more boss mechanics** (≈2 hours)

Burrow Boar emerge-charge + Wolf Alpha pack-summon. The pattern is set
after Hedgemother. Each boss-on-its-own-mechanic elevates dungeon
runs from "fight three reskins" to "memorize three patterns."

### #3 — **Ambient music per zone** (≈1 hour code, ≈1 hour finding tracks)

Three CC0 / royalty-free tracks (village ambient, meadow daytime,
dungeon tension), zone-detection logic (which tile is the player on),
crossfade between them. Probably the single biggest "vibe" upgrade
available for under 2 hours of work.

Free sources:
- freepd.com (CC0)
- pixabay.com/music (royalty-free)
- itch.io's "music asset packs" tag (often CC0)

## What I'd defer

- **Endgame loop** — premature; the early game still needs to sing first
- **Multiplayer / persistence** — out of scope for the cozy genre at this stage
- **NPC schedules + relationships** — Stardew was 4 years of dev for that
  layer alone; even a 10% version is 1 month of work
- **Quest tracker UI** — would help, but loot-juice + bosses + music
  push the experience harder per hour invested

## Prioritized next session

If you ship 3 things in the next 4 hours of work:

1. Loot juice pass (#1) — 2h
2. Burrow Boar mechanic (#2 part one) — 1h
3. Ambient music (#3) — 1h

Together: pillar 4 jumps 4 → 7. Average score 7.1 → 8.0. The game
becomes recognizable as "yes, this is a real cozy ARPG."

## References

- ConcernedApe, "How to Make a Game (Talk)" — GDC 2017 — Stardew design philosophy
- Greg Kasavin (Supergiant), "Hades — Slay the Underworld in Style" — D.I.C.E. 2021
- Mark Brown, GMTK — "How (and Why) Spelunky Makes its Own Levels"
- Mark Brown, GMTK — "What is lootboxing actually doing to your brain?"
- Acid Nerve postmortem on Death's Door — IGN feature, 2021
- Last Epoch dev streams: 0.9 Patch — boss polish + loot rarity calls
- OSRS update cadence — Jagex weekly newsposts (search "polled")
- Massive Monster, "Cult of the Lamb's Cult" — IndieWorld interview 2022

## Mantra

> "Your most-played game has a polished hour 1. Your *favorite* game
> has a polished hour 50. The polish from 1 to 50 is the dev's job."
