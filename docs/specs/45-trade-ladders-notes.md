# Implementation notes — 45-trade-ladders (integration pass)

Integrates the four design specs (carto/earth/wilds/hunt) in one pass, per
the review decisions: enforce den gates, add Gildleaf Ink, build both new
buff hooks, all dispositions accepted.

## Decisions
- **Gildleaf Ink** (the user-approved stitch): starsilver_ore ×1 +
  wild_herb ×2 → gilded ×2.2 / festival_pace ×1.8, Hod riddle on the
  `forge` hint. Every rollable affix now has at least one courting ink.
- **Cap clamp**: `LEVEL_CAP := 17` in game.gd; `award_xp`'s level-up loop
  stops at the cap but **xp keeps accruing** — post-demo cap lifts won't
  lose progress.
- **Practiced Measures** = clicking a *known* codex row fills the pot with
  that recipe's exact makings (claims, not spends). The player still
  presses Try (or keeps stacking) — auto-mix wasn't triggered on purpose,
  so the perk sets out makings rather than brewing unattended.
- **Tier plumbing generalized minimally**: `setup_herb_tier` +
  `herb_tier` mirror the ore path instead of a unified tier table —
  two parallel small mechanisms beat one premature abstraction at n=2.
  `locked()` gates ore on Earthcraft, forage on Wildcraft.
- **Roll tables in data** (`ORE_ROLLS_BY_TIER`, `FORAGE_ROLLS_BY_TIER`,
  `FORAGE_ROLLS_PATCH` in gather.gd) with one `_roll_tier` helper in
  dungeon_gen — the post-demo 8–10-tier vision is now a dict edit.
- **starsilver_band's crit_mult base stat works as-is** — `_derive_stats`
  sums base stats generically into `crit_mult_bonus` (earth spec's open
  Q4 resolved with zero code).

## Deviations
- None from the reviewed specs; all numbers landed as designed.

## Tradeoffs
- The bench panel grew again (620 → 660 tall) for the 8-row codex. At
  ~10 discoverable inks the codex needs columns or paging — same growth
  cliff the tray hit at spec 43.
- Smith's Thrift rolls once per craft and picks a random RAW input
  (never `*_bar` — string suffix check). A bar refund would crack the
  economy gate on all-buyable recipes; the suffix convention is now
  load-bearing, noted here so nobody names a raw material `x_bar`.

## Surprises
- **The new tier rolls shifted the dungeon RNG stream** — same seed,
  different enemy layout downstream. The dungeon-scene test's "prey"
  became a 12-HP imp that died during the Hunter's-Mark probe (13 dmg),
  corpse-failing the kill checks. The probe is now 2 dmg (→3 marked).
  Lesson: any new rng consumption in dungeon_gen reshuffles everything
  after it at the same seed.
- The economy-gate test covered all 10 new forge recipes with zero test
  edits (it iterates the station list) — exactly as the earth spec
  predicted.

## Followups
- Curious Fingers' 40/45/15 odds, Second Pour, Smith's Thrift, and Rich
  Seams have definition-level tests only (randomness); a seeded
  statistical pass would harden them.
- Buff HUD chip is now *more* wanted: five brews, a ward, and Even
  Breath all change state invisibly.
- New herb/ore node art: tiers tint the shared GLB props; per-tier props
  are art one-offs.
- Hale/Heartsease heal numbers (140/220) anchored to ×1.75 steps, not to
  measured Summit damage — needs the balance playtest pass.
- The craft panel's recipe-glyph map doesn't know "band" (falls to ▣).
