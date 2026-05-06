# What makes an ARPG feel good

> A working synthesis of *what specifically* the satisfying ARPGs do
> better than the unsatisfying ones, and where Bramblewood sits on each
> axis. Sourced from: Steve Swink's *Game Feel* (the foundational
> textbook), Jan Willem Nijman's "Art of Screenshake" (Vlambeer talk on
> juice), GMTK's "Why Hades' Combat Feels So Good" / "Action Game
> Anatomy", Supergiant + Blizzard postmortems, Vlambeer / Heart Machine /
> Last Epoch dev streams, and Mark Brown's "Make a Good 2D Camera."

## The seven pillars

ARPG feel is not one thing — it is seven independent axes, each
contributing 10–20% of the overall sense of "punchy." A game that
nails 5 and ignores 2 will still feel mostly good. A game that misses 4
will feel "off" even if the other 3 are exceptional.

### 1. Input → action latency

The single biggest invisible variable. From button press to **first
visible response on screen** must be **≤ 100ms** or the player feels
they are pushing through molasses. Best-in-class:

- **Diablo III**: ~50ms input → swing-start animation
- **Hades**: ~33ms (single-frame at 30fps target) — cast, dash, and
  attack all show first-frame motion the same frame as input
- **Path of Exile**: 80–100ms (network-gated; feels noticeably worse than
  Diablo's offline cadence)

How they do it:

- **Animation start IS the input acknowledgment** — the wind-up
  animation begins exactly on the input frame, not after a network
  round-trip or a "decide what to do" tick.
- **Buffered input** — pressing during a cooldown queues the next
  action; it fires the moment the cooldown ends. Players feel like
  every press counts.
- **Cancellable recovery** — late frames of an attack can be
  interrupted by the next attack, dodge, or ability. Locks the player
  into stiff sequences in lesser games.

### 2. Hit feedback density (the "juice")

One swing should produce 6–10 simultaneous feedback layers. The Hades
swing fires:

| Layer | Detail |
|---|---|
| Screen shake | 0.06–0.10 amplitude, ~120ms decay |
| Hit-stop / freeze frame | 50–100ms freeze on contact (heavier hits, longer freeze) |
| Camera FOV pulse | +3–5° for 150ms |
| Splat number | Big crit numbers ≥ small numbers; color by type |
| Particle burst | 8–14 sparks, color by damage type |
| Enemy flash | Albedo brightens 30% for 180ms |
| Knockback | Enemy velocity impulse along hit vector |
| Audio (3 layers!) | Swing whoosh + flesh impact + metal-on-metal/cloth-shred |
| Hit-pose anim | Enemy plays "hurt" anim that *interrupts* their other anims |
| Gore / decals | Optional — blood spatter, ground impact ring |

The trick is **stacking**. Any one layer feels small. Five layers
synchronized to the same frame feel like a thunderclap.

**Subjective rule of thumb (Vlambeer)**: the player should not be able
to *count* the layers; they should just feel "the hit landed."

### 3. Damage curve readability

Numbers must communicate progress at every scale.

- **Number scaling**: a 4-damage hit and a 40-damage hit should look
  10× different — bigger font, brighter color, longer life. Diablo III
  scales numbers logarithmically by damage tier (regular / elite /
  crit / unique-modifier).
- **Color codes** (universal across genre):
  - white / pale yellow = regular damage
  - bright yellow / orange = critical
  - blue = elemental cold/water
  - red / crimson = elemental fire
  - green = poison or healing
  - violet = curse / shadow
- **HP bar drain physics**: damage taken animates the bar over 200–400ms
  with a "ghost bar" trailing the actual value. Ghost bar shows the
  recently-lost HP so the player can read magnitude.
- **Floaters**: smooth ease-out arc, fade alpha at end, never overlap
  the player or enemy mesh.

### 4. Power fantasy curve (over a session)

The player must FEEL their progress, not just see numbers tick up.

The classic curve:
1. **First hour**: every kill is a struggle. One brindlecow takes 5–6
   swings. Death is a real risk.
2. **Hours 2–4**: skills are maxing, gear is cohesive. Trash dies in
   2–3 hits. Player starts pulling 2–3 enemies casually.
3. **Hours 5+**: AoE chains kill packs. The player IS the screen-
   clearing event. Bosses are still tough (1-on-1 designed-for-skill
   encounters), but trash-cleanup is a power-fantasy delivery system.

This is the "Diablo curve." Hades does the same shape per-run. ARPGs
that miss this feel **flat** — every enemy stays as much trouble at
hour 10 as at hour 1.

The curve is delivered by:
- **Skill scaling**: ability damage grows non-linearly with level
- **AoE unlocks**: big-radius attacks come in around mid-game
- **Crowd control** stacks: stuns, slows, fears proliferate
- **Loot escalation**: rare → magic → legendary, each tier visibly +50% stats

### 5. Animation timing & weight

Each attack has THREE distinct phases:

| Phase | Duration | What's happening |
|---|---|---|
| **Wind-up** | 50–200ms | Player commits, body coils. Slow weapons = longer wind-up. |
| **Active** | 30–80ms | The actual swing arc. Hit registration happens here. |
| **Recovery** | 100–500ms | Player can't act, but CAN cancel via dodge / next attack. |

Heavy weapons (greatswords, hammers) have a 1:2:3 ratio (long wind-up,
short active, long recovery). Light weapons (daggers, claws) have a 1:1:1
ratio (rapid all phases). The **weight of the animation must match the
damage profile** — a 5dmg dagger swing that takes 600ms feels wrong; a
50dmg hammer slam in 200ms feels weightless.

Hades' Stygius (sword) is 220ms total per swing. Aspect-of-Arthur
(massive sword) is 600ms — but does 5× the damage and 2-tile reach.

### 6. Targeting forgiveness

Players don't want to aim precisely; they want to point at "that area"
and have the engine find the threat.

- **Snap radius**: clicking within ~0.6–1.0 tiles of an enemy targets
  it (Bramblewood ships this — see `src/main.js` left-click forgiveness).
- **Tab to cycle**: lockable target, Tab moves to next-nearest.
- **Auto-attack lock-on**: once you're swinging at something, the
  camera + the swing direction follow it without re-clicks.
- **AoE forgiveness**: a 3-tile slam should hit anything *visually*
  inside its radius, even if the unit center is fractionally outside —
  Diablo 3 uses a +0.3-tile generosity buffer.

### 7. World response

Enemies must visibly change state on every contact. The four hit-react
patterns:

| Pattern | When | Visual |
|---|---|---|
| **Hurt** | normal hit | flash + small recoil + brief stagger |
| **Stagger** | heavy hit, on a damage threshold | full stop animation, brief stun, camera lingers |
| **Knockback** | crit / power swing / heavy weapon | physical displacement + ragdoll-style flop |
| **Death** | HP ≤ 0 | dramatic — bigger explosion, slowmo briefly, loot drops with physics |

The **death frame is the most important frame in the game**. It's the
reward delivery moment. Diablo I's design rule (per the postmortem):
"Every death should be MORE satisfying than the last hit that killed
them." This is why Hades adds a brief 0.05s hit-stop on the killing
blow even though damage values are identical.

## Where Bramblewood currently stands

Honest score on each pillar (today, after the recent changes):

| Pillar | Current | Notes |
|---|---|---|
| 1. Input → action latency | **8/10** | 1.15s swing cooldown, but auto-attack tick + input buffer (#45) make presses feel honored. Click-forgiveness works. Camera-relative input now ships. |
| 2. Hit feedback density | **6/10** | Have screen shake, hit-stop, splats, sparks, knockback, audio. Missing: enemy flash, crit camera FOV pulse on every crit, and the "all five layers fire on the same frame" timing precision. |
| 3. Damage curve readability | **5/10** | Have splat numbers + colors. Missing: HP-bar ghost trail, log-scaled font for big crits, ghost-bar drain physics on enemy bars. |
| 4. Power fantasy curve | **4/10** | XP curve is fixed (#51) and combat formula is forgiving (#53). Missing: an actual content arc beyond "you can pull 2 goblins now." Trash density and AoE unlocks both gated on dungeon content. |
| 5. Animation timing & weight | **6/10** | Procedural anims work. Missing: distinct wind-up/active/recovery phases per weapon class — currently a single swing arc plays for all. Weapon-class weight differentiation (#26) only ships dmg/cd, not animation. |
| 6. Targeting forgiveness | **8/10** | Click-snap (#45) works. Tab cycles. Missing: auto-camera follow on locked target. |
| 7. World response | **5/10** | Death drops loot. Hurt anim plays. Missing: stagger threshold, dramatic death frames, killing-blow hit-stop, ragdoll-style flop on big hits. |

**Average: 6/10.** The "smoother" ask reflected pillar 5 (animation
weight) — flat-shaded chunky models read as un-finished animation
weight. The new smooth-normal pipeline addresses the visual dimension
of that.

## Cheap next wins for Bramblewood

If you want one focused pass that pushes 3 pillars at once, in priority
order:

### A. Killing-blow flourish (pillar 7 + 2, 1h)

When an enemy's HP hits 0:
- Insert a 0.12s hit-stop (longer than normal hit-stop)
- Bigger spark burst (24 vs 14)
- Camera shake +50%
- Brief 100ms "death-zoom" — FOV -3° for 150ms
- Body falls over with a procedural rotation (already in code!)
- Log line gets a special prefix ("⚔ FELLED" instead of "⚔ Hit")

Wires into `attackEnemy` after the `enemy.hp <= 0` branch. ~30 lines.

### B. Enemy hit-flash (pillar 2 + 7, 30 min)

Currently `enemy.hurtT` controls a coarse "I got hit" flag. Wire it to
**brighten the enemy's emissive** for 180ms on every hit. Matches
Hades' albedo-flash treatment.

`src/scene/characters.js` already has `m.emissive` preservation. Add a
per-frame tick that does `emissive.lerp(white, hurtT)` while hurtT > 0.

### C. Crit-feel layer (pillar 2 + 3, 30 min)

When `isCrit` fires (already detected):
- Camera FOV pulse +5° (already exists for power swings — extend to crits)
- Splat number rendered 1.4× larger
- Splat color: bright yellow `#ffd864` (already)
- Brief 0.04s hit-stop in addition to the regular timing

Wires into `combat.js` rollPlayerSwingDetailed's existing isCrit branch.

### D. HP-bar ghost trail (pillar 3, 1h)

Add a second `<div>` behind the boss HP bar that drains 250ms after the
real bar. Visualizes "you just took a chunk." Standard ARPG juice.

## What to NOT chase

- **Hyper-realism** — Bramblewood is a cozy fairytale. Blood splatter
  and ragdoll physics break the storybook tone. Stick with sparks, dust
  puffs, and ink-blot hit FX.
- **Ultra-tight Soulslike timing** — the game is hex-based and click-driven,
  not action-mash. Don't try to be Hades; aim for "comfortable Stardew."
- **Overlapping ability resources** — mana + stamina + cooldowns + runes
  is too many things to track. The current model (stamina + per-ability
  cooldown + rune costs for spells) is already at the upper limit of
  cozy-readable.

## Reading list

If you want primary sources rather than this synthesis:

- Swink, *Game Feel* (2009) — chapters 4–6 on input, response, polish
- Nijman, "The Art of Screenshake" (Vlambeer 2013) — 10 min, watch on YouTube
- GMTK, "Why Hades' Combat Feels So Good" — 12 min
- GMTK, "How (and Why) Spelunky Makes its Own Levels" — pacing curves
- Vlambeer, "JUICE IT or LOSE IT" (Petri Purho) — 10 min
- Last Epoch dev streams on `0.9` skill polish — search YouTube
- Heart Machine, *Hyper Light Drifter* postmortem — minimalist juice

## Mantra

> "Every action should produce more feedback than seems reasonable.
> Then remove half. The remaining half is the juice."
> — adapted from Vlambeer
