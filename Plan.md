# Wayfinder — Feel Plan (whole loop)

Living plan for making **every verb in the loop feel good** — gather → craft →
chart → delve → town. Grounded in research passes (animation pipeline; hit-feel +
bullet-hell tactics), a read of the current code, and plan-optimizer passes.
**Blender is parked** — everything here is code-side (procedural), no asset
round-trips.

The document has two parts:

- **Part A — Combat & movement feel** (§0–§9 below). **Shipped** (Phases 1–5,
  gate-green). The animation toolkit in §1 and the cross-cutting rules in §3/§5
  are the shared vocabulary Part B reuses — read them first.
- **Part B — Feel across the whole loop** (after §9). **Planned.** Brings the
  *cozy* half of the loop (gather/craft/inscribe/pickup/level-up/town) up to the
  bar Part A set for combat, reusing the same patterns.

Status legend: ✅ done · 🔄 doing · ⬜ planned · ⏸ parked

---

# PART A — Combat & movement feel  *(shipped, gate-green)*

---

## 0. Why procedural (the constraint that shapes everything)

Meshy auto-rig only works on **humanoid T-pose** models. Our enemies were made
from posed concept art and most are quadruped/amorphous — confirmed when a test
rig of the skeleton failed Meshy pose-estimation (`422`, 0 credits spent). So
**only the player chibi is rigged**; the whole enemy/boss cast is animated in
**GDScript**. For chunky-toon characters, procedural squash/anticipation/overshoot
*is* how "feel" is made.

## Non-goals (scope boundary — say no to creep)
- **Not** true bullet-hell density (no curtains/spirals); cozy = telegraph-heavy,
  density-light.
- **Not** new enemy archetypes or a combo system (combat stays one-verb).
- **Not** skeletal clip authoring (parked with Blender).
- **Not** a netcode rewrite — extend the existing host-authoritative model only.

---

## 1. Animation tactics — how other people do this

The reusable toolkit (12-principles → games → our engine):

- **Squash & stretch, volume-preserved** — stretch on the fast part, squash on
  impact/apex; Y up ⇒ X/Z down. (Idle does this ±2.8% in `creature_anim.gd`;
  *event* squashes are missing.)
- **Anticipation → action → follow-through** — wind-up before, overshoot-settle
  after. **ease-IN on wind-ups** (building force), **ease-OUT on impacts** (snap).
- **Overshoot & settle on every tween** — never lerp straight; ~110–120% then
  back with `TRANS_BACK`/`TRANS_ELASTIC`. Biggest "moves → alive" change, free.
- **Event scale-punch** — punch ~1.18–1.22 then decay (we use this for hit-react
  0.18 / telegraph 0.22 in `combatant._tick_feedback`); extend to spawn/land/death.
- **Velocity lean** — tilt mesh ±6–8° into travel, lerp back when stopped.
- **Secondary motion / phase de-sync** — per-creature phase offset (we derive it
  from spawn pos, RNG-free — keep it).
- **Two-layer transform split** — idle/locomotion writes the **mesh** node;
  hit/attack punch writes the **body** node; they compose, never fight.

Reference points: Hollow Knight, Hades, Smash (hitlag scales with strength), Dark
Souls (~0.33s roll i-frame). **Cozy rule: telegraph density up, projectile/shake
density down.** Keep idle breath ≤ ~3% (more = rubbery on chunky-toon).

---

## 2. Current state (don't rebuild)

| System | State | Where |
|---|---|---|
| Enemy hit-feel (flash, knockback, hit-stop, spark, shake) | ✅ textbook, leave it | `hit_feedback.gd`, `hitstop.gd`, `camera_rig.gd` |
| Hit-stop tiers (0.07 / 0.13 / 0.20s) | ✅ | `hit_feedback.gd` |
| Enemy attack tell (wind-back → lunge) | ✅ visible anticipation + lunge | `creature_anim.gd`, `combatant.gd` ATTACK |
| Procedural idle/locomotion (all enemies) | ✅ | `creature_anim.gd` |
| Player **i-frames** (`IFRAMES_SEC`, roll `0.27`) | ✅ exist (no visible tell) | `player_controller.gd` |
| Player **dodge-roll** (with i-frames) | ✅ exists — leverage for avoidance | `player_controller.gd` ROLL |
| Player hit: knockback + hit-stop + flash + hurt-vignette | ✅ exist | `player_controller.gd:take_damage` |
| Player **micro-stun (input-lock)** | ✅ `STUN_SEC 0.10` | `player_controller.gd` |
| Player **i-frame blink tell** + mesh **flinch** | ✅ `BLINK_PERIOD`/`FLINCH_SEC` | `player_controller.gd` |
| Enemy **ranged attacks / projectiles** | ✅ ghost lobs telegraphed orbs | `enemy_projectile.gd`, `combatant.gd` |
| Player **bow-draw** (arms draw on fire) | ✅ SkeletonModifier3D draw-and-loose | `bow_draw_modifier.gd`, `player_controller.gd` |
| Player clip easing (linear → robotic) | ⏸ needs Blender | — |

---

## 3. Cross-cutting concerns (apply to every phase)

- **Centralized tuning** — put every new feel constant (stun, i-frame, blink,
  projectile speed/telegraph/density) in one block (extend the `hit_feedback.gd`
  tunables pattern or a `feel.gd`), so a playtest is one-file fast. No magic
  numbers buried in logic.
- **Audio** — the research ranks layered SFX as carrying as much weight as
  visuals. Every new beat gets a sound via the existing pipeline
  (`tools/generate_audio.py`, ElevenLabs) with `pitch_scale = randf_range(0.95,
  1.05)` so it doesn't fatigue: player-hit "oof", enemy wind-up charge, projectile
  fire, projectile impact, bow-draw creak.
- **Co-op / netcode** (host-authoritative — extend, don't rewrite) — **enemy
  projectiles spawn on the host and replicate** like enemy state / `drop_event`
  in `net_game.gd`; spawn parameters come from the host (never a bare `randf()` —
  reuse the seeded path lesson). **Player stun / i-frames / flinch are LOCAL**
  (each peer owns its body; `take_damage` already forwards remote hits to the
  owner). Guests must never authoritatively resolve projectile damage.
- **Collision layers** — enemy projectiles hit the **player** layer only (no
  enemy-enemy friendly fire); player arrows keep hitting the **enemy** layer.
  Verify the masks when reusing `arrow.gd`.
- **Performance** — at cozy density (1–2 shooters, ~1 shot/2.5–3s) pooling is
  unnecessary; instantiate per-shot. If a pattern ever caps active projectiles,
  `log()` the drop (no silent truncation).

---

## 4. Roadmap (priority order)

### Phase 1 — Player "getting hit" feel ✅  *(shipped)*
- **Micro-stun:** `_stun_t` on the player; ~**0.10s** set in `take_damage`; gate
  input atop `_physics_process` (`if _stun_t > 0: _stun_t -= delta; decay vel;
  return`). 80–150ms reads without ever feeling like a stunlock.
- **Flinch:** brief mesh recoil along the hit normal + small squash, ease-out ~0.15s.
- **I-frame blink tell:** pulse mesh visibility / flash every ~0.08s while
  `_iframe_t > 0` so "briefly safe" is legible (we have i-frames; surface them).
- **Knockback after hit-stop:** let the 0.07s freeze release *then* shove (free weight).
- **Audio:** a soft "oof" on player-hit. Keep flash/vignette/shake at the *low* tier.
- **DoD / acceptance:** taking a hit visibly stuns ≤0.15s, recoils the player,
  blinks during i-frames, and a second hit inside the i-frame window deals 0
  damage. Verified by the timer test (§5) + a blink screenshot.
- **Effort: S–M.** Pure GDScript, solo.

### Phase 2 — Enemy melee attack tell (anticipation → lunge) ✅  *(shipped)*
Enrich the *existing* telegraph window with visible motion.
- During `_telegraph_t` (bump melee ~0.45s): **wind-back** — pull mesh from
  target + squash (ease-in). On strike: **lunge** toward target (ease-out pop),
  then settle.
- **Shared foundation (reused by Phase 3):** add an **"attacking" yield** to
  `creature_anim` (like the existing "moving" settle) so idle breathing doesn't
  fight the attack. Build it here; Phase 3's ranged windup reuses it.
- Windup length scales with `attack_cooldown` (heavy hitters telegraph longer).
- **Audio:** a wind-up cue.
- **DoD / acceptance:** an attack has a visible pull-back before contact; a
  play-tester can name the incoming hit before it lands ≥90% of the time.
- **Effort: M.** Motion → play-test (use the dummy mode, §5).

### Phase 3 — Enemy ranged / cozy bullet-hell-lite ✅  *(shipped; 2 follow-ups noted)*
**Hardened via adversarial review.** Fixed: a `RANGED_MIN` (4m) standoff so the
ghost backs off and never fires undodgeable point-blank orbs; the aim-line now
tweens over the windup + sizes to the shot distance; the telegraph is freed on
death and on root (rooting interrupts the cast); an `_armed` guard on the orb.
Verified clean: collision layers / no friendly fire, host-only spawn, remote
damage forwarding, determinism. **Deferred follow-ups:** co-op guest-visual
replication of the orb + telegraph (damage already forwards), and a per-step
wall raycast (low risk at 9 u/s).

- **Reuse `arrow.gd`:** lower `SPEED` 50 → **~10** aimed / **~6** orb; flip the
  Hitbox mask to the **player** layer; route damage through `player.take_damage`.
- **Every shot telegraphs (~0.6s):** emissive wind-up pulse (reuse Phase-2 yield
  + a warning-color flash) + a **ground line/ring decal** (reuse the AoE-burst
  ring in `arrow.gd:326–349`) + a charge SFX. Consistent color = "incoming".
- **Pattern vocabulary** (pick a few): single aimed shot · 3–5 fixed fan · slow
  orb · delayed AoE zone. No streams/curtains.
- **Avoidance = strafing** (player `move_speed` > projectile speed) **+ the
  existing dodge-roll's i-frames** for tight moments — not a new mechanic.
- **Density:** 1–2 ranged enemies active; ~1 aimed shot / 2.5–3s. Bright vs the
  dark crypt. Host-authoritative spawn (§3).
- Data: a `ranged`/`projectile` kind in `ENEMY_KINDS`; `_ranged_attack()` in
  `combatant` fires at telegraph-end instead of melee.
- **DoD / acceptance:** shooter telegraphs ≥0.5s before firing; a strafing player
  who reads tells clears all shots without rolling; co-op: guest sees identical
  projectiles, host resolves damage.
- **Effort: M–L.** Motion → play-test + telegraph-decal screenshot.

### Phase 4 — Player bow-draw ✅  *(shipped)*
Procedural arm pose on fire (no Blender, no AnimationTree): on `trigger_fire`,
pose the bow/draw-arm bones via a `SkeletonModifier3D` (or `set_bone_pose_rotation`
after the AnimationPlayer) — raise to draw, snap on release, ease back ~0.15s.
Port the angle intent from the unused `ranger_anim.gd` draw pose onto the chibi's
Mixamo-named arm bones. **Audio:** a bow-creak.
- **DoD / acceptance:** firing visibly raises/draws the arm; legs keep cycling
  (additive); screenshot-verified mid-draw.
- **Effort: M.** Screenshot-able.

### Phase 5 — Animation juice (cheap, broad) ✅  *(core shipped)*
- ✅ **Spawn pop-in** — every enemy/boss overshoots into existence (back-out
  scale 0→1 over 0.28s) instead of popping at full size (`creature_anim`).
- ✅ **Velocity lean** — creatures tilt ~7° forward while moving, straighten at
  rest (`creature_anim`).
- ⬜ Remaining optional polish: land-squash on hop valleys, death-squash,
  overshoot on the other one-shot tweens, a player movement lean.
- **Effort: S–M.**

### Parked — ⏸ Player clip easing (needs Blender)
`bpy` re-curve walk/run/idle fcurves to BEZIER + retime + re-export the 3 chibi
GLBs. Runs whenever the user opens Blender + the MCP add-on; no code dep. Interim:
Phase-5 lean + a speed-driven blend mask some of the robotic feel.

---

## 5. Verification strategy (beats "motion can't be screenshotted")

1. **Four-suite gate stays green** every commit: `test_stats`, `test_wyrd_loop`,
   `test_wyrd_dungeon_scene`, `test_wyrd_transitions`, `test_skills` (`WYRD_NO_SAVE=1`).
2. **Timer-assertion tests** (test_stats-style, headless): assert stun duration,
   i-frame window (a 2nd hit inside it deals 0), projectile spawn + damage routing,
   telegraph length. Catches logic regressions a screenshot can't.
3. **Combat-dummy gallery mode** — ✅ built: `tools/animation_gallery.gd` attaches
   `creature_anim` to static enemies (so the gallery shows the procedural idle),
   `A` demos the attack tell, and `WYRD_GALLERY_ATTACK=1` captures the lunge
   frame. Closes the screenshot gap for Phases 2–4; extend with ranged-telegraph
   + draw demos as those land.
4. **Screenshot** where static reads: i-frame blink (P1), telegraph decal (P3),
   bow-draw mid-frame (P4).
5. **Play-test sign-off** from the user for the felt timing of P2/P3 (motion).

## 6. Success metrics (felt, validate by playtest)
- A hit *reads*: the player can tell they were hit without watching the HP bar.
- Attacks are *fair*: tester names an incoming attack before it lands ≥90%.
- Ranged is *avoidable*: a tells-reading, strafing player clears shots without
  twitch reflexes; never feels screen-filling.
- Cozy holds: no stunlock (≤0.15s), generous i-frames (0.4–0.6s), shake subtle.

## 7. Sequence & first step
1. **P1** (player hit-feel) — fast, mostly enhancement. **First commit:** `_stun_t`
   + input-gate + i-frame blink, with a timer test.
2. **P2** (melee tell + the shared attack-yield foundation) + the dummy mode.
3. **P3** (ranged/bullet-hell, reuses P2 yield + dummy mode).
4. **P4** (bow-draw) — independent, screenshot-verifiable.
5. **P5** (juice) — fold in throughout.
Blender easing runs whenever the user's ready. P1/P4/P5 are solo-verifiable;
P2/P3 motion needs a play-test.

## 8. Accessibility / guardrails
"Reduce screen shake" toggle; conservative shake; micro-stun ≤0.15s; generous
i-frames; slow telegraph-heavy projectiles. A player who reads tells and keeps
moving never needs twitch reflexes.

## 9. Sources
Two research passes (session-archived): animation pipeline + 12-principles;
hit-feel number bands + bullet-hell telegraphing. Anchors: Hollow Knight Hornet
frame data, Dark Souls roll i-frame, Smash hitlag, shmup bullet-visibility,
ARPG ground-decal telegraphs.

---

# PART B — Feel across the whole loop  *(planned)*

Cozy skilling is the spine (ADR 0003): the player spends most of their time
**gathering, crafting, inscribing charts, and resting in town** — and right now
those verbs are functional but flat next to the combat that Part A polished. Part
B closes that gap with the *same* toolkit (§1) and the *same* guardrails (§3/§5),
so nothing here is a new system — it's the existing feel patterns applied to the
cozy half.

**Guiding rule:** a verb *feels good* when it has anticipation → a clear moment of
impact → an overshoot-settle payoff, plus a sound. Every phase below adds the
missing beat(s) to one verb.

## B-0. Current state of the cozy loop (don't rebuild)

| Verb | What already feels good | The gap (what B adds) | Where |
|---|---|---|---|
| **Gather** (mine/chop/forage) | per-swing node squash, tool-in-hand, channel bar, per-beat SFX, floating "+N", move/damage cancel | swing rotates the **whole mesh** (stiff) not the arm; no impact chip; harvest end is a quiet number, not a payoff | `gather_node.gd`, `player_controller.gd:begin_gather` |
| **Craft** (cook/forge/distil) | recipe panel, craft SFX, success toast, perk procs | the **station body does nothing** on success — no flare/spark/bubble | `game.gd:craft`, `craft_station.gd` |
| **Inscribe a chart** (signature Wayfinding verb) | purple glow OmniLight on the table, toasts | no ritual — affixes don't *reveal*, the chart doesn't *appear*, no seal beat | inscribing table, chart panel |
| **Pickup** | glowing beacon (`ItemPickup`), proximity scanner, auto/try-take | grab + satchel-landing have no payoff (suck, chime, slot pulse) | `item_pickup.gd`, satchel HUD |
| **Level / trade-up** | `level_up` SFX, `leveled_up` signal, HUD refresh | the moment is silent visually — no burst, no perk banner, no count-up | `game.gd`, `player_controller.gd:_on_leveled_up`, `player_hud.gd` |
| **Town / Living-Atlas** | forage/ore/log nodes regrow on timers, town theme | nodes just *appear*; no arrival beat; Atlas/board doesn't react to an unlock | `town.gd` |

## B-1. Cross-cutting (Part B deltas — extend Part A §3/§5, don't duplicate)

- **`feel.gd` central tunables (build FIRST — phase B0).** Part A flagged "one
  tuning block" as wanted but never built it. Create `data/feel.gd` (a
  `RefCounted`/autoload const bag) holding every Part B constant: gather swing
  depth/rate, impact-chip count, harvest mote count + arc time, craft-reaction
  intensity per station, pickup suck-time, level-up punch scale, town grow-in
  duration. Every later phase reads from here so a playtest is one-file-fast. No
  magic numbers buried in logic.
- **Audio (same pipeline as Part A §3).** Each new beat gets one ElevenLabs SFX
  via `tools/generate_audio.py`, `pitch_scale = randf_range(0.95, 1.05)` so
  repetition (especially gather, the most-repeated verb) never fatigues: gather
  impact-chip (per material kind), harvest chime, craft flare/sizzle/clang/bubble
  per station, inscribe seal, pickup chime, level-up chord, town arrival swell.
- **Co-op (CRITICAL — opposite default from Part A projectiles).** Part B
  reactions are **cosmetic and LOCAL** — gather swing, craft flare, motes,
  pickup suck, level-up burst, town grow-in run on **each peer independently**.
  Only the *authoritative state* they accompany (materials added, xp/level,
  chart created, item taken) routes through `game`/`net_game` as it does today.
  Do **not** gate cosmetics behind the host or they vanish for guests. (Contrast:
  enemy projectiles in Part A *are* host-authoritative because they deal damage.)
- **Performance.** Motes/chips/sparks are short-lived `MeshInstance3D` + a tween,
  not particle systems or physics. Cap bursts (≤8 motes, ≤6 chips) in `feel.gd`
  and `log()` if ever clamped. Free on tween-finish; never leak across a scene
  change (parent to the node, not the scene root).
- **Accessibility.** The Part A "reduce screen shake" toggle also damps Part B
  camera micro-kicks (gather impact, craft clang). Reactions stay readable with
  shake off.

## B-2. Roadmap (priority = frequency × payoff)

### Phase B0 — `feel.gd` tunables + audio scaffolding  ⬜  *(do first)*
The foundation every other phase reads from. Stub the SFX keys in `sfx.gd` so
later phases just call `sfx.play("gather_chip")`.
- **DoD:** `data/feel.gd` exists with the constants above; `Feel.GATHER_*` etc.
  resolve in a headless smoke test; new SFX keys registered (silent stubs OK
  until audio is generated). Gate green.
- **Clones:** `hit_feedback.gd` tunables pattern. **Effort: S.**

### Phase B1 — Gather arm-articulation (the bow-draw treatment) ⬜
The clearest "make an action feel good" win — gathering is the most-repeated verb
and the spine of the game. Replace the whole-mesh swing with a `SkeletonModifier3D`
that drives the **arm bones** through a mine/chop arc (forage = a lower, gentler
pluck) while the locomotion/idle clip keeps playing underneath — exactly how
`bow_draw_modifier.gd` layers the bow draw over the legs.
- Add `GatherSwingModifier` (sibling of `bow_draw_modifier.gd`); `begin_gather`
  drives `swing_amount` on a per-kind sawtooth synced to the channel beat.
- On each swing **apex**: a small impact — `feel`-capped chip motes off the node,
  a sharper node recoil (the existing squash, deeper), a tiny camera micro-kick
  (shake-toggle aware), and the per-kind impact-chip SFX.
- **DoD:** the arm visibly articulates the swing (not the whole body tipping);
  legs/idle keep cycling; mid-swing screenshot via the feel bench (§B-3); gate
  green. **Clones:** `bow_draw_modifier.gd`. **Effort: M.**

### Phase B2 — Harvest payoff (the "pop") ⬜
The end of a channel should *pay off*, distinct from each swing. On `_harvest`:
- node does a bigger squash-burst + a depletion puff; **material motes arc to the
  player** (≤8 cheap `MeshInstance3D`, back-out tween toward the player, no
  physics) then the "+N material" float scales in with an overshoot-settle; a
  brighter harvest chime (distinct from the per-beat tick).
- **DoD:** harvest reads as a payoff distinct from a swing; motes visibly travel
  node→player; "+N" overshoots in. Verify by feel bench + a 3-frame capture.
- **Clones:** `creature_anim._back_out` overshoot; existing `_float_text`.
  **Effort: S–M.**

### Phase B3 — Level / trade-up moment ⬜
Cheap, touches every trade, pure dopamine — the progression payoff. On
`leveled_up`:
- player burst: pulse the existing ink-outline **gold** + an overshoot scale-punch
  (reuse the spawn back-out); a **perk banner** toast naming the unlock (we have
  the perk names in `PERKS`); the HUD trade readout does a count-up/flash; a held
  level-up chord (we already play `level_up` SFX — layer the chord).
- **DoD:** crossing a trade level is unmissable — burst + named-perk banner +
  HUD flash fire together within one frame of the signal. Timer/logic test
  asserts the banner shows the correct perk for the new level. **Clones:**
  `creature_anim` back-out; Part A flinch/punch on `_mesh`. **Effort: S–M.**

### Phase B4 — Pickup & satchel-landing feel ⬜
Independent, satisfying, frequent. On take:
- the beacon **sucks toward the player** + scales down over `Feel.PICKUP_SUCK`,
  a pickup chime, a floating item-name chip, and **the satchel slot it lands in
  pulses/flashes** so "it went in my bag" is legible without opening the pack.
- **DoD:** taking an item animates beacon→player and pulses the destination slot;
  no item is consumed if the pack is full (existing reserve-space rule holds).
  Logic test: suck tween completes and slot-pulse targets the actual fit slot.
  **Clones:** `item_pickup.gd` beacon; HUD slot draw. **Effort: S–M.**

### Phase B5 — Craft station reaction ⬜
A successful craft should make the **station react in-world**, not just toast. Add
a `react()` hook on `CraftStation`; `game.craft()` success finds the active
station and calls it:
- **cookfire** — ember-light energy pulse + flame flicker + steam motes rising
  from the pot; **anvil** — spark burst + a scale-punch on the anvil body + clang
  micro-flash; **still** — green vapor puff + the catch-flask glints.
- **DoD:** each station has a distinct visible reaction on a successful craft;
  reaction fires only on success (not on a gated/failed attempt). Logic test:
  `react()` called exactly once per successful `craft()`, zero on failure.
  **Clones:** `craft_station.gd` OmniLight + `_prim`; mote pattern from B2.
  **Effort: M.**

### Phase B6 — Inscribe / chart ritual (the signature verb) ⬜
Wayfinding is *the* differentiator (CLAUDE.md). Inscribing a chart should feel
ceremonial, not like a menu confirm. **Shippable in two slices:**
- **B6a — table reaction:** the table glow brightens & pulses, a light/quill
  sweep crosses a parchment plane, the finished chart "drops" onto the table with
  a settle, a **seal** chime.
- **B6b — affix reveal:** the chart's affix names reveal **one-by-one** with a
  stamp/overshoot (good/bad twins in their kit colors) instead of appearing all
  at once.
- **DoD (a):** inscribing triggers a visible table ritual + seal SFX. **DoD (b):**
  affixes reveal sequentially, each with an overshoot stamp, in ≤1.2s total.
  Verify by feel bench capture. **Clones:** inscribing OmniLight; B3 overshoot;
  toast/float text. **Effort: M–L** (highest ceremony — do when the toolkit's warm).

### Phase B7 — Town / Living-Atlas ambient feel ⬜
Town is the rest beat — returning from a delve should feel like arriving home.
- **arrival beat:** a gentle camera ease-in + a town ambient swell on entering
  from a delve; **regrowth pop:** a node that respawns **sprouts/grows in** with
  an overshoot (reuse the spawn back-out) instead of appearing; ambient life —
  light sway / drifting motes on town props; the **Atlas/chart board reacts**
  when a new den unlocks (glow + a stamp).
- **DoD:** a returning player sees ≥1 regrown node grow-in (not pop) within the
  first seconds; arrival plays the swell once; an unlock visibly marks the board.
  **Clones:** `creature_anim` back-out (grow-in); `town.gd` node respawn.
  **Effort: M.**

### Parked / explicitly out of scope
- ⏸ **Blender arm-clip authoring** — the `SkeletonModifier3D` procedural approach
  (B1) is the interim, same call as the bow-draw. Re-curve real swing clips
  whenever the user opens Blender + the MCP add-on; no code dependency.
- **Defeat / down / revive feel** — *not* in Part B (combat-adjacent, and co-op
  revive is a netcode question, not a cosmetic one). Flag for a later combat pass.
- **Delve→town transition wipe** — the transition suite owns this; B7's arrival
  beat is the town-side reaction, not a new transition.

## B-3. Verification (extends Part A §5)
1. **Five-suite gate stays green** every commit (`WYRD_NO_SAVE=1`).
2. **Feel bench** — extend `tools/animation_gallery.gd` (or a sibling
   `tools/feel_bench.gd`) with triggers for each cozy beat: `G` gather swing,
   `H` harvest pop, `L` level-up burst, `P` pickup, `C` craft react (cycle
   station), `I` inscribe. `WYRD_SHOT` + a `WYRD_FEEL=<beat>` hook captures the
   key frame — closes the "motion can't be screenshotted" gap for the cozy half.
3. **Logic tests** where there's logic, not just motion: B3 banner names the
   right perk; B4 suck completes + targets the real fit slot; B5 `react()` fires
   once per success / never on failure; B7 regrowth grow-in starts on respawn.
4. **Play-test sign-off** for felt timing of B1 (swing rhythm) and B6 (ritual pace).

## B-4. Success metrics (felt — validate by playtest)
- **Gather** has rhythm: the swing, the chip, and the harvest pop are three
  distinct felt beats, not one mushy channel.
- **Craft** is causal: the player sees the station *do* the thing they made.
- **Inscribe** reads as the game's signature ritual — a tester unfamiliar with
  the game calls it "the cool part."
- **Pickup / level-up** never go unnoticed: the player knows it landed without
  watching a number.
- **Town** feels restful and alive — arriving home is a beat, not a load.
- **Cozy holds** (Part A §8): no jank, no fatigue (pitch-jittered SFX), shake
  optional, reactions readable.

## B-5. Sequence & first step
1. **B0** (`feel.gd` + SFX stubs) — foundation, fast, unblocks the rest.
2. **B1 + B2** (gather swing → harvest pop) — highest frequency, the spine.
3. **B3** (level-up) — cheap, high dopamine, touches every trade.
4. **B4** (pickup) — independent, satisfying.
5. **B5** (craft reaction).
6. **B6** (inscribe ritual — a then b) — the signature, do when the toolkit's warm.
7. **B7** (town/atlas) — the connective rest beat.
**First commit:** `data/feel.gd` with the tunables block + registered SFX stub
keys + a headless smoke test that the constants resolve. B0 → B1 is the path.
