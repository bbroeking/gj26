# Wayfinder — consolidated roadmap (2026-06-12)

THE single where-are-we doc. Detail lives in the linked plans; when this
disagrees with code, code wins. Repo note: the three.js prototype was
removed 2026-06-12 (recoverable from git history).

## Shipped (all gates green — 217 headless checks across 3 suites)

**Core loop:** tutorial → forage → mix ink → inscribe chart → parameterized
dungeon (affixes shape gather nodes / density / HP / boss dens) → exit
waystone → completion XP → trophy chain (elites → Hedgemother → Boar →
Wolf → **Summit** endgame) → gold economy with Hod → save/load.

**Trades:** Wayfinder/Earthcraft/Wildcraft/**Huntcraft** with XP+levels
(Trades page K, four rows); kills feed Huntcraft scaled to the slain
thing's vigor, perks at 5/10 (crit/move speed) — ADR 0005;
channel-time gathering with interrupts; town stations (6 herb / 3 ore /
3 log, regrowing); cooking at the Cottage Hearth (draughts, Q-quaff);
smelting+smithing at Hod's Anvil (full gear ladder, 14 recipes E1→E9,
economy-gated); trade
tools in their own equip slots (−30% channel); per-level perks ×4;
first-time hint dialogs per verb.

**Combat:** 4-skill hotbar (1-4+F, icons+tooltips); per-kind enemy stats
(rats nip, skeletons slam); Boar line-telegraph charge; Wolf chained
pack-lunge (2/3/4 by phase); elites + affix modifiers; controls locked
1-4+F (ADR 0004 — click-move fork closed).

**Audio:** 26 ElevenLabs SFX + looping town theme; master mute (F10,
persisted). Regenerate: `wyrd/tools/generate_audio.py`.

**UI:** Wayfinder UI Kit (Claude Design project `wayfinder-ui`) — carved
wood frames (nine-patch-verified), kit chips/buttons/troughs everywhere;
wood-ring HP/Focus globes + skill tray bottom-center (PoE layout); pages
designed-then-implemented: Trades (professions rows + unlock cells), Pack,
Dialog (portrait well), Vendor; custom in-game cursor (default state).
Specs 38–41 + notes.

## In flight

- **UI refinement rounds** (design-pass Phase 3 tail): Craft, Satchel,
  Charts, Inscribing — all already wear the kit; rounds are polish.
  ⚠️ Inscribing's round is **superseded by the crafting rebuild below**.
- **Art one-offs:** painted trade emblems, tool icons, NPC portraits
  (dialog well shows a ghost), cursor interact/attack hover swaps.

## Next, in order

1. ~~Chart crafting rebuild — spec 42~~ **SHIPPED 2026-06-12**: the
   Crafting Bench (placement sockets, live odds preview, on-bench mixing
   pot, guided-tutorial highlights) replaced the menu panel; 151 checks
   green. Open: design-page side-by-side + fresh-save manual tutorial run
   (notes file).
2. ~~B5 loadouts~~ **SHIPPED 2026-06-12**: PiercingBolt (pierce-3 line
   shot) + RainOfThorns (delayed thorn AoE w/ bleed); slot 1 fixed Bow,
   slots 2-4 picked in the Loadout panel (dungeon Hearth rest + Cottage
   Hearth button); persisted in the save; 160 checks green. Also this
   pass: bench tooltips everywhere + click-to-place.
3. ~~A6 node tiers + tool tiers~~ **SHIPPED 2026-06-12**: copper (E1) →
   bogiron (E3) → palechalk (E7, charts tier-2+ only); locked veins stand
   visible naming their level; town heap = 2 copper + 1 locked bogiron;
   copper chain (ore→bar→Copper Ring); Cinderbloom tools at E7 (−45%
   channel, palechalk-made). Note: stoneground ink now effectively gates
   at Earthcraft 3 — intended ("coveted"), watch the early-game feel.
4. ~~B6 affixes~~ **SHIPPED 9/9 2026-06-12**: wave 1 (Sprinting Things ·
   Gilded Hollow · Bursting) + wave 2 (Quiver/Damp Strings · Fog of
   Hedge/Blinding Fog · Frenzied/Seething · Wellspring/Barren Veins ·
   Echoing Steps/Hollow Echo · Marked Quarry/Skittish Prey). 15 rollable
   affixes total; dens stay trophy-only.
5. ~~B7 combat XP as a trade~~ **SHIPPED 2026-06-12**: ADR 0005 — ONE
   combat trade, Huntcraft. Kills award `max(2, hp_max/3)` xp; perks
   Steady Hands (5, +5% crit) / Hunter's Stride (10, +5% move); fourth
   Trades-page row; old saves backfill at lv 1.
6. ~~A7-full smithing~~ **SHIPPED 2026-06-12**: forge now carries the full
   gear ladder (14 recipes) — Shortbow E1, caps/boots E5, jerkin E6,
   Palechalk Ring (rare) + Palechalk Longbow E9 — behind a tested economy
   gate: no smithed item sells for more than its Hod-buyable input cost.
   Craft panel grew a scroll. **A8-full alchemy (Quill)** still open.
7. **A8-full alchemy (Quill)** — port the full potion/draught table; new
   herb tiers to pair with A6's ore ladder.

## Standing followups

- **Animation backlog** (`docs/wyrd-animation-backlog.md`): P1 mostly
  shipped 2026-06-12 — gather swing loop + tool-in-hand + node strike
  pulses, quaff tip-back, bench socket pops + pot mix bloom. Still owed:
  craft scroll-and-seal, waystone chart-socketing, P2/P3 sets.

- Save-file safety: `_test_save_roundtrip` writes/deletes the REAL save.
- Boss-fight feel playtests still owed (Boar charge, Wolf lunge):
  `WYRD_DEV_CHART=tier_1 WYRD_DEV_BOSS=burrow_boar_den|wolf_alpha_den`.
- Vendor list-row buttons slightly washed (cream-on-cream).
- Hosted agent-native apps need one-time OAuth (`connect` commands) before
  /assets, /design-exploration, /visual-plan are usable.

## Doc index

| Doc | Role |
|---|---|
| `wyrd-roadmap.md` | this — consolidated state + queue |
| `wyrd-skills-combat-plan.md` | A/B-track detail (v2, plan-optimized) |
| `wyrd-ui-design-pass.md` | Claude-Design workflow + lessons |
| `wyrd-trades-recap.md` | trade-system ground truth + stale-doc audit |
| `specs/3x-4x-*.md` (+ notes) | per-feature contracts and deltas |
| `adr/` | 0003 cozy-skilling spine · 0004 controls · 0005 Huntcraft |
| `WORLD_BIBLE.md` / `CONTEXT.md` | voice / domain language |
