# Controls stay 1-4 + F; the click-to-move fork is closed

B2 on the skills & combat plan (docs/wyrd-skills-combat-plan.md) flagged a
control-scheme decision: Wayfinder shipped with WASD movement, F for the
basic shot, 1-4 for skills, E to interact, Space to roll, Q to quaff. The
FATE/PoE lineage suggested an alternative fork — click-to-move + QWER —
and an intermediate option of alt-binding skills 2/3 onto reachable letter
keys. The plan deliberately deferred the verdict until combat had texture
(B3 per-kind enemy stats, B4a Boar charge) so the schemes would be judged
against real fights, not placeholders.

**Decision (2026-06-11): option (a) — keep the current scheme.** WASD +
F + 1-4 + E + Space + Q is the control layout. The click-to-move + QWER
prototype is **not built**; the alt-bind variant is dropped. Recorded
after the B3/B4a playtest build; the user picked (a) directly rather than
requesting the comparison prototype.

Consequences:

- **B5 (loadout choice) is unblocked** — new skills bind to the existing
  1-4 slots; the pick-4-at-the-hearth UI can assume numeric binds.
- **Q stays quaff.** The Q-key collision flagged in the plan's risk table
  resolves in favor of the sustain verb — no skill alt-binds will claim it.
- No losing branches to delete — neither (b) nor (c) was ever built, which
  is exactly what deferring the decision was for.

## Considered options

- **(a) Keep 1-4 + F.** Accepted. WASD movement is already tuned (FATE
  camera, roll, dash); combat with per-kind enemies and the Boar charge
  plays fine on it; zero rework.
- **(b) Alt-bind slots 2/3 onto letters (R/V/C after Q went to quaff).**
  Rejected — marginal reach benefit, new collision surface (R is inventory
  rotate), and it splits muscle memory across two bind sets.
- **(c) Click-to-move + QWER (the FATE fork).** Rejected without
  prototyping — an M-sized build for a scheme that would also force
  rethinking gather channels, roll, and interact targeting. Revisit only
  if a future playtest shows WASD fighting the camera.

## When to revisit

If B4b (Wolf pack-lunge) or B5 (loadouts) playtests surface that aiming
skills while strafing feels bad, reopen against option (c) — that's the
scheme click-to-move actually fixes. Don't reopen for key-reach
complaints alone; rebinds solve those without a fork.
