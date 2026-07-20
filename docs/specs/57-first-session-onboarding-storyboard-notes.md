# Implementation notes — 57-first-session-onboarding-storyboard

## Decisions

- Onboarding camera guidance uses short in-engine vignettes over the live Town
  scene. The reusable player borrows `CameraRig`, uses the existing modal seam
  to stop input and hide gameplay HUD, and restores the authored gameplay frame
  before releasing control.
- Arrival, Inscribing Table, and Waystone vignettes are stored as one-time
  `seen_hints` entries so returning saves do not replay them.
- Headless automation, visual-capture environments, and co-op skip authored
  onboarding vignettes. The reusable cutscene lifecycle is tested directly in
  the transition suite instead.
- HUD disclosure and shortcut permissions share
  `Game.onboarding_surface_available()`. A surface hidden during onboarding is
  therefore also unavailable through its memorized I/M/K shortcut.
- The Satchel appears when the first completed Chart makes it relevant; Gear
  and Trades appear after the first return. Health and the Bow row appear on
  entering the Snug, while Focus waits for Power Shot.
- The nearest generated Snug combat room is normalized into the teaching
  encounter: exactly one rat, one damage, slow movement, long attack recovery,
  and no elite roll. Later rooms remain procedural.
- Basic Shot and roll prompts advance from the real input dispatch points. The
  player may still walk past the lesson; it guides without hard-locking a room.
- Power Shot practice uses an arrow-compatible, non-economic Combatant target
  beside Mara's table. Only a projectile tagged `power` completes the lesson;
  ordinary arrows can strike it without consuming the beat.
- Bramble Bloom now unlocks at Wayfinding 3 so first-return Hedge Ink changes
  a real roll: Mineral Vein/Bramble Bloom shifts from 50/50 to about 33/67.
  The guided table separates path odds from the later helpful/troublesome twin
  roll instead of compressing both probabilities into one row.
- During the three table lessons, the material tray contains only the objects
  needed for that action. The full recipe Codex, trophy shelf, locked bases,
  and unrelated materials return after onboarding.
- The complete Skill bar remains folded away through the first Tier 1 Hollow.
  Completing that Hollow is the chapter boundary; crafting its key is not.
- Mara closes the chapter with a three-way preference (strength, materials, or
  mystery). The preference only changes the standing objective copy and does
  not lock a build, reward, or content branch. Esc records a neutral choice so
  the conversation never becomes a blocker.
- First-session measurement records named milestones and authored-guidance
  activations only. `WYRD_PLAYTEST=1` writes
  `user://onboarding_playtest.json`; web builds expose the same schema as
  `globalThis.__wyrdOnboarding`. No text, identity, inputs, or coordinates are
  collected.
- Recovery follows two timed stages after every meaningful action: a contextual
  landmark nudge at 20 seconds, then direct controls plus the gold needle at
  35 seconds for Mara or 45 seconds for later town beats. Opening a new beat,
  gathering an herb, firing/rolling, and completing Power Shot practice reset
  the quiet window. Bench socket pulses are withheld until the first stage;
  the always-processing bench advances that clock while its offline modal has
  the rest of the scene paused.
- Cold-session reports are evaluated with a dependency-free analyzer that
  applies all seven timing gates, requires four reports, calculates medians,
  and totals recovery activations. Comprehension answers remain in the human
  observation sheet because they must not be captured as telemetry.

## Deviations

- Cold first-time validation cannot be substituted with automated agents. The
  implementation and measurement build are ready, but the required three
  native participants and one web participant remain an external human gate.

## Tradeoffs

- Live camera moves add no web video payload and preserve the actual character
  and town state, at the cost of requiring authored camera focus points for each
  teaching handoff.

## Surprises

- The current HUD already limits active Skill slots to one in the Snug and two
  on first return, but health and Focus presentation are still constructed and
  shown together. Progressive Skill disclosure is therefore partly shipped,
  while resource-globe disclosure is not.
- The current Web export completed the query-gated title → Town → Snug → Town
  smoke in Chromium after the timing changes. Its console reached
  `[web-smoke] complete` without warning or error entries. This is delivery
  verification, not one of the required cold participant sessions.

## Followups

- Run three native and one web session using
  `docs/playtests/55-first-chapter-observation.md`; tune any beat that needs
  coaching or misses the 35-minute chapter target.
