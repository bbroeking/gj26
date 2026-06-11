# Specs — FATE-style crypt arc on top of existing dungeon code

The dungeon system is **~90% built already** (`src/scene/dungeon.js`, `src/data/dungeonSpawns.js`, `enterDungeon` in `src/main.js`). These specs cover the actual gap: wiring the niji 6 crypt assets into the existing system + adding multi-floor descent + Hedgemother as a real boss model.

Use `/spec docs/specs/<file>.md` to implement one. The skill keeps a `<file>-notes.md` sibling capturing every decision / deviation / tradeoff made along the way.

## Order

```
01 ─► 02 ─► 03
         │
         └─► 04 (parallel, can run alongside 02 and 03)
                  │
                  ▼
                  05
```

| # | Spec | Outcome |
|---|---|---|
| 01 | [01-crypt-assets.md](./01-crypt-assets.md) | 16 cleaned crypt-tile GLBs in `models/` + 3 floor PNG textures |
| 02 | [02-crypt-scope-wiring.md](./02-crypt-scope-wiring.md) | `'crypt'` becomes a registered scope; `buildDungeonGroup` renders the niji GLBs instead of procedural meshes for crypt dungeons |
| 03 | [03-multi-floor-descent.md](./03-multi-floor-descent.md) | Procgen emits staircases; variable-floor crypt arc (per-chart `floors`) with depth HUD; bosses at `ceil(floors/2)` and `floors` |
| 04 | [04-crypt-enemies.md](./04-crypt-enemies.md) | Crypt enemy GLBs (skeleton, rat, ghost, hedge-sprite) + spawn-table entries; mid-boss reuses existing `wolf_alpha` (no new mini-boss model) |
| 05 | [05-hedgemother-boss.md](./05-hedgemother-boss.md) | Hedgemother GLB replaces procedural mesh; 3-phase fight on the final floor |

## What's already done (out of scope here)

- Tile-step / swing-cooldown combat with input buffering, dodge, riposte, vigor
- 28-slot inventory + equipped gear with stat bonuses (`ITEMS`, `player.inventory`)
- Loot tables, chest rolls (`rollChest`, `generateDungeonLoot`)
- Procgen layouts (rooms-and-corridors, seeded `mulberry32`)
- Authored + scaffold + echo layout loaders
- 4 existing biome scopes (briar_maze, sunken_hut, delve, hollow) with their own enemies, lighting, decor
- Affix system (mineral_vein, bramble_bloom, hedgemother_den, …) → modifies generation
- Traps, doors with keys, dungeon library save (localStorage)
- Town↔dungeon transition (`enterDungeon`, hidden-overworld pattern, ambient swap)
- Orbit camera with screen shake + FOV pulse
- Multi-floor staircases (works today for authored levels; spec 03 extends to procgen)

## Resolved decisions (foundation)

These came out of the grill-me pass; specs assume them.

### Game-design (Q1–Q9)

- **Q1 — Combat model**: keep existing tile-step / swing-cooldown system. The new dungeon hosts encounters in the existing `CONFIG.combat` rules; no real-time / hitbox rewrite.
- **Q2 — Run shape**: Hades-style finite arc per Crypt Ledger. Variable floor count per chart. Bosses at `ceil(floors/2)` (mid-boss) and `floors` (final boss = Hedgemother). Replayable for loot — re-entering rolls a fresh arc.
- **Q3 — Death penalty**: soft. Player returns to town with full HP and inventory intact, but loses the in-progress arc (depth resets; final boss chest + unique drop forfeit).
- **Q4 — Entry path**: NPC quest gives the first Crypt Ledger; recipe unlocks at the chartmaker afterward so the player can craft more.
- **Q5 — Tier × floors**: chart has both `tier` (1–5, difficulty, constant across the arc) and `floors` (variable, e.g., 5–15+). Both fields visible on the chart pre-entry — player commits with full knowledge of length and difficulty.
- **Q6 — Affixes**: per-arc, baked into the chart at craft time, constant across all floors. Chart fully describes the run.
- **Q7 — No voluntary return**: once you enter, you complete the arc or die. No mid-arc gold exit. "Complete the arc" is the only path to the final reward.
- **Q8 — Heal between floors**: partial — 25% max HP restored on descent. Food/potions still meaningful for in-floor recovery.
- **Q9 — Mid-boss identity**: reuse existing `bossKind: 'wolf_alpha'` reskinned in-lore as "crypt hound". Zero new model needed; spec 04's enemy roster drops the separate `crypt_warden` mini-boss as a result.

### Operational defaults (D1–D8)

- **D1** — Crypt Ledger is consumed on entry (matches existing chart behavior).
- **D2** — Floor must be cleared of hostile enemies before staircase activates.
- **D3** — `player.flags.cryptCleared` persists to localStorage so it survives page refreshes.
- **D4** — Crypt Ledger recipe unlocks immediately after the intro quest (not gated on a first clear).
- **D5** — Quest NPC for the first ledger = **Cook** (existing dialog tables + cookfire is a natural prep zone).
- **D6** — Hedgemother unique drop = **Hedgemother's Thorn Crown** (head slot, starting bonuses `{ atk: 2, str: 1, def: 0 }` — exact numbers tunable in spec 05).
- **D7** — If the reward chest isn't picked up before leaving the boss room, it's lost (no town-side mailbox in v1).
- **D8** — Existing 4 scopes (briar/sunken/delve/hollow) remain single-floor for v1. Only crypt charts trigger the multi-floor arc.

## Workflow

1. Read a spec.
2. Refine in conversation if scope/decisions are unclear.
3. `/spec docs/specs/<file>.md` to implement.
4. Review the resulting `<file>-notes.md` for surprises.
5. Iterate, then move to the next spec.

## Template

New specs use [`SPEC_TEMPLATE.md`](./SPEC_TEMPLATE.md).
