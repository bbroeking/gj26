# Wayfinder — skills & combat build plan (v2, optimized 2026-06-10)

v2 supersedes the v1 tables in place — every v1 piece is carried forward
with its number. Optimized via /plan-optimizer; score trajectory
52 → 74 → 84 → 86.

**North star (ADR 0003):** cozy-skilling is the spine; combat is one verb.
Every piece must pass the **spine test** before it ships: *would a player
voluntarily do this verb with no quest pointing at it?* A piece that makes
a verb feel like a chore regresses the game even if the system works.

**How to read a piece:** *Felt change* is what the player notices — the
reason the piece exists. *Done when* is the exit gate; no passing gate, no
✅. Sizes: **S** under an hour · **M** a session · **L** needs a lite-first
split (ship the lite, schedule the rest).

## Done so far (all gates green — 125 checks across 3 headless suites)

A1 town gather stations · A2 first-time trade hints · A3 Trades page (K) ·
A4 channel gathering · A7-lite anvil (bar → longbow → ring) · A8-lite
hearth (draughts + Q-quaff + HUD count) · A9 perks ×4 · B1 action-bar
icons/tooltips · **B3 per-kind enemy stats** (2026-06-11: rat 2dmg/2.6spd
vs skeleton 7dmg/1.55spd; tests assert both axes) · **B4a Boar charge**
(2026-06-11: windup → line telegraph → dodgeable dash, one hit per charge;
headless tests cover lane-hit and sidestep-dodge; *feels-fair playtest
still owed* — `WYRD_DEV_CHART=tier_1 WYRD_DEV_BOSS=burrow_boar_den`) ·
**B2 control scheme** (2026-06-11: verdict (a) keep 1-4+F — ADR 0004;
Q stays quaff; the click-move fork is closed; **B5 unblocked**) ·
**B4b Wolf pack-lunge** (2026-06-11: chained re-aimed dashes, 2/3/4 by
phase, snappy 0.32s re-telegraphs; headless chain test green; playtest
via `WYRD_DEV_CHART=tier_1 WYRD_DEV_BOSS=wolf_alpha_den`) · **B8 audio**
(2026-06-11: 13 ElevenLabs SFX via `tools/generate_audio.py` — gather
channels audible, quaff/craft/level-up/boss-telegraph/roll/waystone wired,
looping town theme starts in town and stops in the hollows)

## Next, in order

UI design pass in Claude Design (user directive — design each page on the
locked spec-39 layout language before more code styling) → B5 loadouts →
A6 node tiers (+ tool tiers) → B6 affixes (≥2 per session).

Spec 38 (2026-06-11) closed **A5 tools** (own equip slots, −30% channel,
forge-crafted), added the **master mute** (F10, persisted), the **potion
globes** (PoE-style bottom cluster — and fixed the skill bar, which had
been rendering off-screen since spec-35), and ran the **UI audit** (dialog
matte stripped, inscribing overflow fixed, satchel wrap, pack z-order,
HUD strip). Notes: docs/specs/38-tools-mute-globes-ui-notes.md.

## Track A — make the trades deep (resumes after B2)

| # | Piece | Felt change | Done when | Size |
|---|---|---|---|---|
| A6 | Node tiers | Higher Earthcraft opens richer veins — visible, locked, coveted | copper → bogiron → palechalk in data; a locked node names its level; richer veins only inside charts (chart loop stays primary) | M |
| A7-full | Smithing economy | The anvil is a destination: ore in, build-relevant gear out | three.js `smith-recipes.js` table ported; **every recipe's sell value < input buy cost from Hod** (no gold mint); ladder on Trades page | M (lite ✅) |
| A8-full | Alchemy with Quill | A second crafting NPC; draughts that buff, not just heal | Quill placed + voiced per WORLD_BIBLE; 2 buff draughts (gather speed, focus regen); first-use hint | M (lite ✅) |

## Track B — make combat textured (resumes after B2)

| # | Piece | Felt change | Done when | Size |
|---|---|---|---|---|
| B5 | Loadout choice at the hearth | First build-crafting moment | 2-3 skills ported (Piercing Bolt, Rain of Thorns); pick-4 UI; loadout persists in save | L |
| B6 | Remaining 9 affixes | Every chart roll reads differently | rolling — ship ≥2 per session alongside other pieces; each has good/bad twin + test | rolling |
| B7 | Combat XP as a trade | Fighting levels something — combat joins the economy | **ADR first**: does a 4th+ trade dilute the three? cozy spine wins ties; only then wire `awardCombatXp` | M |

## Risks & open decisions

- ~~Q-key collision~~ — resolved by ADR 0004 (2026-06-11): Q stays
  quaff; no skill alt-binds.
- **B7 trade dilution:** combat XP risks turning the Trades page into an
  OSRS stat screen. Decide by ADR; if in doubt, combat stays XP-less.
- **Economy inflation (A7-full):** smithed gear + Hod buyback can mint
  gold. Hard gate: sell value < material buy cost, asserted in tests.
- ~~Audio keeps slipping~~ — B8 landed 2026-06-11, before B5.

## Cut-line (if time gets short)

Order of mercy: **B3 → B4a → B2 → B8 → A5**. Everything below the line
survives a cut without breaking the spine.

## Playtest cadence

One 15-minute self-playtest after each shipped piece + the spine test.
Record one sentence per playtest in `wyrd-implementation-notes.md` —
drift between "plan says" and "game feels" is the failure mode this plan
exists to catch.
