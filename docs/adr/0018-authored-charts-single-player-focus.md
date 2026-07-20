# ADR 0018 — Authored Charts and single-player product focus

**Status:** Accepted (2026-07-20)

## Context

Wayfinder's differentiator is the player's ability to author the conditions of
a journey without eliminating procedural discovery. Native co-op had also
become deeply coupled to campaign authority, UI, and encounter plumbing while
contributing little to the intended player experience.

## Decision

Wayfinder is a single-player game for the current product and release plan.

- Remove the title-screen co-op entry, the Lantern host/join UI, network boot
  hooks, party HUD construction, and co-op release gates.
- Keep dormant transport compatibility internal until it can be removed from
  campaign and encounter authority paths without destabilizing solo play.
- Do not design new encounters, UI, progression, or saves around multiplayer.

Charts preserve randomness in layout, room arrangement, placement, and
incidental contents. The player authors the distributions within that
randomness:

- A completed Chart may carry up to **three Affixes** based on the components
  and inks used to create it.
- Affixes may make low-vigor or high-vigor enemies more common, raise or lower
  elite frequency, bias resource abundance, or influence other declared
  encounter families.
- An Affix is a bias or guarantee with clear preview language, not a fixed room
  script. Two Charts with the same recipe can still produce different layouts.
- Every Affix needs visible world evidence and an observable gameplay effect;
  it cannot exist only as hidden arithmetic.

Chart duration targets are:

- Early Charts: **5–10 minutes**.
- Mature ordinary Charts: longer by depth and complexity.
- Maximum intended Chart commitment: **20–25 minutes**.

The opening reveals only immediately useful UI. The village grows through a
small number of legible physical additions and transformations as chapters are
completed.

## Consequences

- Procedural generation remains replayable while Chartmaking gains deliberate
  target-farming and difficulty-shaping value.
- Duration is controlled primarily through room count, depth, and encounter
  density rather than larger health pools.
- Village restoration becomes the primary persistent visual record of player
  progress.
- Spec 46 and co-op-specific tests are historical evidence, not current product
  requirements.
