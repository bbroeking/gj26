# Implementation notes — 30-skills-and-cooldowns

## Decisions
- **Slot 1 routes through `_fire_buffer`, not direct fire.** `_try_skill(1)`
  sets `_fire_buffer = INPUT_BUFFER_SEC` rather than calling `_fire_arrow`
  directly. This keeps the F-spam "press a tick early" feel — pressing `1`
  also gets buffered, so 1-key and F-key behave identically. Slots 2-4 fire
  immediately (no buffer) which matches D3 conventions.
- **`_skill_cooldowns[1]` mirrors `_fire_cd` each frame** rather than being
  the source of truth. Lets the existing F-fire path keep owning slot 1's
  cooldown while the skill bar reads `_skill_cooldowns` uniformly.
- **Bramble Snare's `_aim_dir()` uses input direction first, then mesh facing
  fallback.** Same pattern as `_fire_arrow`. Snare lands at `player_pos +
  dir * 4.0` clamped to y=0.05. No raycast against walls — if the player
  aims into a wall, the AoE harmlessly drops inside (no enemies there).
- **Snare visual = unique-per-cast StandardMaterial3D + alpha tween.** Each
  cast spawns a fresh material (so concurrent snares don't share fade state)
  and tweens `albedo_color:a` (not `modulate:a`, which MeshInstance3D doesn't
  have — caught by the first eval run, fixed before T4 even noticed).
- **CDR_CAP = 0.80 at the `_derive_stats` level**, not at `_effective_skill_cd`.
  That way the cap is visible in the derived dict (and the skill bar reads
  the capped value if it ever needs to).
- **Combat timer bumped on three events**: taking damage (existing), firing
  BasicShot, and any skill cast. The "in-combat" definition is *"the player
  is fighting"*, not *"an enemy is nearby"* — simpler and reads better
  (firing a skill into nothing still gates Focus regen).
- **`apply_root(d)` is idempotent — `maxf` of existing + new duration.**
  Multiple snares stacking on the same enemy extend the root if longer,
  never shorten it. Visual disc is reused (created once, not recreated per
  application).
- **Knockback still applies to rooted enemies.** The root early-returns in
  `_tick_ai` after zeroing velocity, but `_physics_process` adds
  `_knockback` *after* the AI tick — so the player can shoot a rooted
  enemy and visibly push it around. Side-effect, but a good one.
- **`_die()` clears the root disc.** Without this the disc would outlive the
  dying enemy, leaving a green ring at the corpse position until queue_free.

## Deviations
- **SFX deferred entirely** — same pattern as spec 29. The 3 PATHS entries
  exist; `play()` is a graceful no-op until the files land. User confirmation
  for ~$0.30 ElevenLabs spend not requested yet (deferred to a follow-up
  unless asked).
- **Cooldown "sweep" is a fading alpha overlay, not a rotating sector.** The
  spec called for a D3-style rotating second-hand sweep; v1 uses a simpler
  `ColorRect` alpha that fades as the cooldown elapses. Readable as
  "cooldown is shrinking" but not literally a sweep. Proper radial fill via
  `TextureProgressBar` is a polish followup.
- **Skill names are 3-letter placeholders (`Bow`/`Pow`/`Mlt`/`Snr`)** not the
  Bramblewood-flavored names from the spec (PowerShot, etc.). Full names
  + ink-style icons land with the icon spec.

## Tradeoffs
- **`_skill_cooldowns[1] = _fire_cd` sync vs unifying into one cooldown
  system.** Sync is uglier but preserves the existing F-fire path verbatim
  (including the input buffer + spec 26 SFX call + spec 27e crit pass).
  Unifying would touch the whole fire path, with no functional gain.
- **MultiShot fires 3 arrows in a ±20° cone, each at base damage** (not
  scaled down). Total damage = 3× base, but spreads across enemies. Each
  arrow rolls crit independently — 3 chances for a crit, more "loot rain"
  feel. Alternative would have been 3 arrows at 50% damage each (D3
  Demon Hunter style); chose higher per-arrow damage to make MultiShot
  feel like a real pack-clear, not a downside-of-Power.
- **Snare radius = 2.5m and reach = 4m, not configurable per shot.** Could
  have made these `derived_stats` keys for a future "wider snare" affix
  ("of_widening" suffix?) but added that to Followups instead. v1 keeps the
  affix surface small.
- **`MIN_COMBAT_ROOMS` interaction.** Spec 29 reserves 2 combat rooms per
  dungeon; spec 30 makes combat encounters more interesting. Combination
  means players will see a real fight in every dungeon with multiple skills.
  Confirmed by 5/8 enemies per boot — meaningful encounters.

## Surprises
- **T4 passed despite the `modulate:a` error** because the error fires when
  the tween chain is *built*, but `tween_callback(disc.queue_free)` still
  runs (Godot's tween chain is robust). The enemy got rooted regardless —
  the snare's root logic runs immediately, the disc fade is purely visual.
  Caught + fixed before the boot test so neither error noise nor a stale
  disc reaches the player.
- **Out-of-combat regen 5.0 / 0.5s = 10/sec exactly** matches the constant
  (no jitter from physics_frame timing). The headless test ran 30 frames
  at 60Hz cleanly. Made T6 a precise check, not a fuzzy one.
- **`_input_dir()` returns the camera-relative direction**, so when the
  player has no movement input, `_aim_dir()` falls back to mesh rotation.
  In T4 I had to manually set `p._mesh.rotation.y = 0` to make snare land
  predictably at (0, 0, 4) — without it, the default rotation produced an
  off-axis aim.
- **Default `focus = FOCUS_MAX` works fine for the spawn case**, but if
  Player.tscn ever changes to construct Player via `new()` without going
  through `_ready`, focus would default to whatever `FOCUS_MAX` is at parse
  time (50.0). Fine for now; documented for future-me.

## Followups (post-/spec)
- ✅ **3 ElevenLabs SFX generated** (`skill_power` 24KB, `skill_multi` 24KB,
  `skill_snare` 33KB, all 128kbps stereo, md5-distinct). Total spend ~$0.30.
- ✅ **MultiShot tuned to 50% per arrow** (D3 Demon Hunter convention).
  3 arrows × 0.5 = 1.5× total damage — preserves pack-clear without
  eclipsing PowerShot on single targets. `int(round(damage * 0.5))` in
  `_fire_multishot`.
- ✅ **Hedgemother root-immune.** One-line `func apply_root(_d): pass`
  override on `boss.gd`. Snare still casts visually but the boss can move
  + attack uninterrupted. Spec 31's status framework will handle per-status
  immunity more elegantly; this is the v1 quick-fix.
- **Ink-style icons for the skill bar.** 4 cohesive line-drawings (bow,
  power-shot, multi-shot fan, bramble vines). Replaces the 3-letter text
  placeholders.
- **Proper radial cooldown sweep** via `TextureProgressBar` (clockwise fill).
  Replace the fading-alpha overlay; lands as part of a UI polish spec.
- **Hedgemother's Wrath ultimate (R key).** The 5th skill the spec deferred.
  ~30s CD, free cost, AoE knockback burst. Probably gets its own small spec.
- **Status framework (spec 31).** Generalises Snare's root into a status
  dict on Combatant + per-frame tick. Burn/freeze/poison/bleed slot in.
- **AoE damage shapes (spec 31).** ExplosiveArrow, ChainShot. PowerShot's
  damage is single-target only today.
- **Wider snare affix (`of_widening`).** Promotes `SNARE_RADIUS` from const
  to a `derived_stats` key. Skipped in v1 to keep the affix surface small;
  could ship alongside spec 36 (expanded item pool).
- **Skill Codex screen** for the future rune system (D3 model — 3 variants
  per skill, swappable out of combat).
- **Bramble Snare wall raycast.** Currently the AoE drops at `player +
  forward * 4`; could clip into a wall. v1 accepts this; a follow-up could
  raycast and clamp the impact point to the nearest open floor.
- **Boss root immunity** — Hedgemother can currently be rooted. If that
  trivializes the fight, a one-line `func apply_root(d): pass` override on
  `boss.gd` makes the boss immune.

## Status
COMPLETE — `test_skills.gd` 6/6 + every existing harness still green:
items 7 · inventory 8 · drops 5 · equipment 7 · stats 5 · movement 6 ·
combat 21 · decor placement 3 · typed rooms 5 · skills 6 = **73/73 evals
across 10 harnesses**. World boots, score ~0.93, 5–9 enemies per dungeon.
3 new SFX paths added (files deferred).
