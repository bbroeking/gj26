# Implementation notes — 31-status-and-aoe

## Decisions
- **Tick damage routes through new `_apply_tick_damage(amount)`, NOT
  `take_damage`.** Spec said `take_damage(dpt, ZERO, 0.0, 0.0)` to disable
  crit; I went with a dedicated bypass method instead because: (1) Bleed-on-
  crit is implemented INSIDE `take_damage`, so a tick that randomly super-
  crits (4% chance, ignores `crit_chance` param) would re-bleed in a loop,
  (2) tick damage shouldn't trigger hitstop / knockback / hit-spark / SFX
  every 0.5s, (3) cleaner separation — tick path is one method that just
  decrements HP + shows a damage number + flashes the mesh.
- **`apply_status` overrides on `boss.gd`** REPLACE the spec 30
  `apply_root` pass-through entirely. `apply_root` is now a Combatant alias
  that routes through `apply_status("root", ...)` — the boss override
  catches the "root" kind and returns null, same net effect with one less
  override.
- **Strict tick semantics: single tick per frame, no while-loop catch-up.**
  Spec was ambiguous on multi-tick on a single frame with high `delta`.
  Chose single-tick because the while-loop approach has a double-fire edge
  case at `delta == tick_interval` (next_tick goes from 0 → -tick → 0 in
  one frame, fires twice). Single-tick: predictable, accept the lag-loss
  on hitches > tick_interval as an acceptable v1 trade.
- **`_statuses.keys()` snapshot in the tick loop.** A tick can call
  `_die()` (via `_apply_tick_damage` if it kills) which clears the dict.
  Iterating live would crash; snapshotting + checking `if not _statuses.has(kind)` per iteration handles the mutation safely.
- **Skipped the mesh tint pulse from the spec.** Spec listed 3 visual
  channels (particle + tint pulse + apply-text). Implemented 2 — the tint
  pulse conflicted with the existing spec 14 hit-flash (`_apply_flash`
  takes over `_meshes` for ~0.12s); coordinating the two systems was more
  code than the marginal visual benefit warranted. Particle + apply-text
  carry the load. Documented as a followup.
- **`damage_number.setup_apply` uses smaller scale + status colour**, not
  italic. Label3D has no italic property out of the box; loading a separate
  italic font is a polish followup. The smaller `_base = 0.7` + the
  status-themed `modulate` colour already read as "this is different from
  a hit number."
- **Apply-text fires *once* on initial apply, NOT on refresh.** Spec said
  "on apply only, not per tick" — I interpreted "apply" as the *first time*
  the status lands on this enemy. Re-applying the same status (highest-
  wins/refresh) does NOT re-pop the text. Reads as "this enemy is already
  on fire," which matches the genre convention.

## Deviations
- **No new SFX in this spec** — spec said so explicitly ("Apply event is
  silent (visual only). Existing hit/crit SFX carry the moment."). Followed.
- **`STATUS_PARTICLE_CAP = 2`** — spec said "cap simultaneous particle
  systems at 2." Root's mesh disc isn't counted (different visual type).
  So a fully-loaded enemy can have root disc + 2 particle systems (Burn +
  Bleed). A 3rd damaging status (no skill applies one in v1 anyway) would
  get the dict entry + apply-text but no particle visual.
- **The spec said `cooldown_reduction` should NOT affect ticks; nothing
  was said about ticks scaling with any stat.** Confirmed by implementation —
  status damage is fixed per the StatusEffect, no `derived_stats` lookup
  on tick. Future affixes (`fire_damage`, `bleed_chance`) belong to spec 36.

## Tradeoffs
- **`_apply_tick_damage` skips the hit-spark + screen shake + SFX** that
  `take_damage` runs. Trade: ticks are visually quieter (just the flash
  pulse), but the alternative is 6 hit-sparks + 6 screen shakes over 3
  seconds for a single Burn. The quieter feel is correct — DoT is "this
  is happening to them," not "this is a moment to feel." Documented.
- **Bleed damage rounds UP via `max(1, ...)`.** A crit for 5 damage at
  6.25% per tick is 0.3125, which rounds to 0. The `max(1, ...)` clamp
  ensures every crit produces a *visible* bleed of at least 1 per tick.
  Trade: at very low crit damage, bleed contributes a disproportionate
  amount (1 dmg / tick over 4 ticks = 4 total off a 5-dmg crit = 80%
  bleed). Acceptable for cozy small-numbers gameplay.
- **GDScript `var x :=` Variant-inference issue** struck again in
  `test_statuses.gd` (T4 and T6). Same pattern as specs 25/26/27a/27c.
  Resolved with explicit `var x: bool = ...`. Worth promoting to a
  workflow note: **anytime a `_check` argument comes from a
  dynamic-method call, type the intermediate var explicitly**.
- **Single-tick-per-frame loses ticks on lag spikes.** A 1.2s frame would
  fire only one Burn tick instead of two (or three). At 60Hz target this
  never happens; at 30Hz it could happen during pack-clears. Documented as
  a followup if pack scaling makes this visible.

## Surprises
- **T3 (MultiShot) was failing 7/8 runs because `await physics_frame` let
  the arrow's Hitbox auto-fire on a leftover enemy from a prior test** —
  all test enemies default-position at origin, the arrow's collision_mask
  picks up the first hurtbox it sees. Auto-call applied Snared to T1's or
  T2's enemy, then `_spent = true` made my manual call no-op on T3's
  enemy. Fix: a `_strip_arrow_autosignal()` helper that disconnects the
  `area_entered` signal before manual call. T2 was passing by luck (auto-
  call happened to hit the right hurtbox that run).
- **`get_meta("combatant").get_instance_id()` was the smoking-gun debug.**
  Printing instance IDs side-by-side showed the arrow's `c` and the test's
  `e` were genuinely different combatants. Without the ID print I'd have
  spent another hour assuming the status framework had a bug.
- **`super.apply_status(...)` works cleanly in `boss.gd`.** GDScript's
  inheritance + super() handles the chain perfectly. No signature issues
  like spec 27e had with `take_damage` (the signature was identical here
  because the boss override has the same default args).
- **The "Unyielding" suffix on the boss name** is just a string append in
  `set_phase`. No new UI work needed. Lands as "The Hedgemother — Phase 1 —
  Unyielding" which is a little verbose but readable.

## Followups
- **Mesh tint pulse on tick** — skipped this spec. Would need to coordinate
  with `_apply_flash` (the hit-flash) so they don't fight for `_meshes`
  ownership. Probably: a separate "soft pulse" tween that doesn't touch
  `material_override` at all (modulate the meshes' colour briefly), or
  refactor `_flash_mat` into a stack with priorities.
- **Status icons in the HUD bar** — currently the entity-level visuals
  carry everything. A polish pass could add small icons under the HP bar
  for the *player's* statuses (once enemies can apply them — spec 32+).
- **Italic apply-text font** — load a separate italic font for the apply-
  text variant. Label3D supports `font` property; a quick polish pass.
- **Status-affecting affixes** (`fire_damage`, `bleed_chance`,
  `burn_duration`) — spec 36 (expanded item pool) territory. Promotes the
  hard-coded burn dmg/duration into `derived_stats` lookups.
- **Status framework SFX** (`status_apply_burn`, `status_apply_bleed`,
  `status_apply_snared`, `status_apply_root`). Currently silent on apply.
  ~$0.40 ElevenLabs spend; confirm before generating.
- **ExplosiveArrow** as the first real consumer of `aoe_query.query_circle`
  for *damage* (Snare uses it for status-only). Probably 1-day spec.
- **Multi-tick catch-up on lag spikes** — switch single-tick to bounded
  while-loop if pack-scaling (spec 32) makes frame-time variance visible.
- **Player-side status visuals** — `take_damage` on the player goes
  through `player_controller`, not `combatant`. If enemies later apply
  statuses to the player (spec 32+ elites with on-hit effects), need a
  parallel path on the player.

## Status
COMPLETE — `test_statuses.gd` 7/7 + every existing harness still green.
Full tally: items 7 · inventory 8 · drops 5 · equipment 7 · stats 5 ·
movement 6 · combat 21 · decor placement 3 · typed rooms 5 · skills 6 ·
statuses 7 = **80/80 evals across 11 harnesses**. World boots, score 0.95,
7 enemies per dungeon. No new SFX (deferred).
