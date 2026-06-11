# Wayfinder — consolidated roadmap (2026-06-12)

THE single where-are-we doc. Detail lives in the linked plans; when this
disagrees with code, code wins. Repo note: the three.js prototype was
removed 2026-06-12 (recoverable from git history).

## Shipped (all gates green — 141 headless checks across 3 suites)

**Core loop:** tutorial → forage → mix ink → inscribe chart → parameterized
dungeon (affixes shape gather nodes / density / HP / boss dens) → exit
waystone → completion XP → trophy chain (elites → Hedgemother → Boar →
Wolf → **Summit** endgame) → gold economy with Hod → save/load.

**Trades:** Wayfinder/Earthcraft/Wildcraft with XP+levels (Trades page K);
channel-time gathering with interrupts; town stations (6 herb / 3 ore /
3 log, regrowing); cooking at the Cottage Hearth (draughts, Q-quaff);
smelting+smithing at Hod's Anvil (bar → pickaxe/axe/longbow/ring); trade
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
2. **B5 loadouts** — 2-3 new skills + pick-4 at the hearth (first
   build-crafting moment; unblocked by ADR 0004).
3. **A6 node tiers + tool tiers** — copper→bogiron→palechalk; richer veins
   only in charts.
4. **B6 remaining 9 affixes** — rolling, ≥2 per session.
5. **B7 combat XP as a trade** — ADR first (dilution question).
6. **A7-full smithing / A8-full alchemy (Quill)** — port the full recipe
   tables.

## Standing followups

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
| `adr/` | 0003 cozy-skilling spine · 0004 controls |
| `WORLD_BIBLE.md` / `CONTEXT.md` | voice / domain language |
