---
type: system
tags: [economy, gold, hod, balance, smithing-gate]
status: draft
updated: 2026-06-13
sources: ["docs/wyrd-trades-recap.md", "docs/specs/45-trade-ladders-earth.md", "docs/game-balance-playbook.md", "wyrd/data/economy.gd", "wyrd/scripts/game.gd"]
---

# Economy

The gold economy in Wayfinder channels a single faucet (selling dungeon gear to Hod) and a single sink (buying raw materials and inks from Hod's shelf), deliberately priced so gold is a convenience shortcut into the ink economy — not a bypass of the [[Chart Loop]].

## Gold faucet: selling gear

Dungeon runs produce gear items in the Tetris inventory. Selling to Hod pays by rarity (`wyrd/data/economy.gd::SELL_BY_RARITY`):

| Rarity | Gold |
|---|---|
| Normal | 4 |
| Magic | 12 |
| Rare | 35 |
| Unique | 90 |

The player sells by clicking in the vendor panel; `Game.sell_item()` removes the item and credits gold.

## Gold sink: Hod's shelf

Hod stocks a small shelf of materials and inks. Prices are roughly 3–4× the opportunity cost of gathering them yourself (`wyrd/data/economy.gd::WARES`):

| Item | Price |
|---|---|
| Wild Herb | 3 g |
| Logs | 4 g |
| Bogiron Ore | 7 g |
| Hedge Ink | 12 g |
| Stoneground Ink | 18 g |
| Refined Ink | 38 g |

Boss trophies are never sold — the trophy chain is the only road to boss dens. (`docs/wyrd-trades-recap.md`)

## The no-arbitrage smithing gate

A critical invariant (`_test_wyrd_loop.gd::_test_economy_gate`): any forge recipe whose inputs are **all purchasable from Hod** must cost more at Hod's prices than its sell value. This prevents gold farming through the forge. The test iterates every recipe in `STATIONS.forge.recipes` automatically, so new recipes are covered without test edits.

Example: the Longbow (magic, sells 12 g) costs 1 bogiron_bar + 2 logs = 14 g + 8 g = 22 g to buy at Hod's prices. Gate holds. (`docs/specs/45-trade-ladders-earth.md`)

Recipes that require deep ores (copper, palechalk, starsilver, hedgesteel) are gate-safe by construction because those ores are not sold on Hod's shelf. The spec recommends keeping it this way for the demo — gather-only deep ores keep tier-2 charts as the only road to the top of the ladder.

**Price floors if deep ores were ever stocked** (computed in `45-trade-ladders-earth.md`):
- Palechalk: at least 2 g
- Starsilver ore: at least 7 g
- Hedgesteel ore: at least 7 g

## Balance philosophy

From `docs/game-balance-playbook.md` §10 (cozy single-player):

- Gold is "always winnable, occasionally tense, never frustrating" — never a blocker, always a shortcut.
- Target TTK for trivial mobs: 5–15 s. Death = fade to bed with minor penalty.
- Never one-shot a player below 50% HP; always allow retreat.
- Linear tier scaling (not multiplicative): old gear remains usable, not invalidated.

The cozy balance goal is that the player can buy their way into a chart run if they're stuck, but buying is always more expensive than gathering — the chart loop rewards engagement and not the gold shortcut.

## Gold outside gear

No other faucets exist in the demo: crafting materials, gathered ores, and trophies are not sold. Gold income scales naturally with run depth (deeper runs produce higher-rarity gear).

## See also

- [[Chart Loop]], [[Crafting]], [[Gathering]]
- [[Earthcraft]] (Hod's Anvil, gear), [[Wayfinding]] (inks and their prices)
- [[NPCs]] (Hod Tenter — the vendor and smith)
- [[Design Decisions]]

## Sources

- `wyrd/data/economy.gd` — SELL_BY_RARITY, WARES
- `wyrd/scripts/game.gd` — sell_item(), buy_ware()
- `docs/wyrd-trades-recap.md` — economy touchpoints
- `docs/specs/45-trade-ladders-earth.md` — economy gate proof table
- `docs/game-balance-playbook.md` — cozy balance philosophy
