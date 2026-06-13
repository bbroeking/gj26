---
type: entity
tags: [affix, chart, good-twin, bad-twin, wayfinding, dungeon]
status: draft
updated: 2026-06-13
sources: ["docs/cartography-keystone-design.md", "docs/cartography-progression.md", "wyrd/data/charts.gd"]
---

# Affixes

Affixes are the modifiers that make each [[Charts|chart]] run distinct — every affix has a **good twin** and a **bad twin**, and which one lands is determined by a stability roll at the moment of inscription.

## The good/bad twin mechanic

When a chart is inscribed, each affix slot picks an affix from the weight table (biased by slotted [[Inks]]), then performs a stability roll. Stability is a percentage chance of landing the good twin:

```
effective_stability = min(95, base_stab + wayfinder_lv × 0.6
                          + ink_bonus × 100 + perk_bonus × 100)
```

`base_stab` is set per affix (roughly 46–55 across the pool). A fresh Lv 1 player rolling `mineral_vein` (base 55) has a 55% chance of the good twin before any ink bias. At Lv 40 that rises to 79%. Stability is capped at 95 — there is always a small chance of the bad twin. (`wyrd/data/charts.gd::effective_stability`)

## The shipped affix pool

Fifteen affixes are rollable at random in `wyrd/data/charts.gd`. Boss dens are a separate category — they are never random-rolled; a player must deliberately slot a trophy to inscribe one.

### Bias (resource layer)

| ID | Good twin | Bad twin | Req | base_stab |
|---|---|---|---|---|
| `mineral_vein` | Mineral Vein — 3–5 ore rocks in the hollow | Barren — no ore | 1 | 55 |
| `bramble_bloom` | Bramble Bloom — 4–6 forage spawns | Wilted — no forage | 4 | 55 |
| `wood_grove` | Wood Grove — 3–5 log piles | Stripped Grove — no logs | 7 | 55 |
| `herbal_patch` | Herbal Patch — 6–9 herb spawns | Frostbit Patch — no herbs | 14 | 55 |
| `gilded` | Gilded Hollow — 2 extra chests | Picked Clean — no extra chests | 9 | 55 |
| `wellspring` | Wellspring — every gather node yields +1 | Barren Veins — gathering 33% slower | 13 | 55 |

### Modifier (combat math)

| ID | Good twin | Bad twin | Req | base_stab |
|---|---|---|---|---|
| `tyrannical` | Tyrannical — enemies +50% HP, +30% chart XP | Erratic — random secondary mods | 5 | 52 |
| `sprinter` | Sprinting Things — everything +25% speed | Mired Boots — player -10% speed | 6 | 52 |
| `bursting` | Bursting — slain enemies burst and harm kin | Volatile — bursts hit you too | 12 | 50 |
| `quiver` | Quiver — +20% fire rate | Damp Strings — -10% firing speed | 8 | 54 |
| `fog_of_hedge` | Fog of Hedge — enemies notice player 33% later | Blinding Fog — enemies detect further | 10 | 52 |
| `frenzied` | Frenzied — enemies attack 25% faster | Seething — enemies hit 15% harder | 11 | 50 |
| `echoing` | Echoing Steps — Focus regen ×1.5 | Hollow Echo — Focus regen −25% | 15 | 52 |
| `marked_quarry` | Marked Quarry — elites carry trophies 2× more often | Skittish Prey — trophy odds halved | 16 | 50 |

### Pacing

| ID | Good twin | Bad twin | Req | base_stab |
|---|---|---|---|---|
| `festival_pace` | Festival Pace — +50% enemy density | Lockstep — fewer enemies | 7 | 52 |

### Boss dens (deliberate inscription only)

Boss dens are never in the random weight table. A player slots a boss trophy at the bench; `TROPHY_TO_AFFIX` maps the trophy to the den affix, guaranteeing it in one affix slot. The stability roll still applies — the bad twin produces an empty throne.

| ID | Trophy required | Good twin | Bad twin | base_stab |
|---|---|---|---|---|
| `hedgemother_den` | `thorn_essence` | Hedgemother's Den — her thorn-arena | Empty Throne | 50 |
| `burrow_boar_den` | `tusker_tusk` | Burrow Boar's Wallow | Empty Wallow | 48 |
| `wolf_alpha_den` | `wightpelt` | Wolf Alpha's Roost | Cold Trail | 46 |

## Affix categories (design taxonomy)

The design doc (`docs/cartography-keystone-design.md`) classifies affixes into six categories — `bias`, `modifier`, `boss`, `pacing`, `risk`, and `atmosphere`. Shipped code (`wyrd/data/charts.gd`) uses `kind` values: `bias`, `modifier`, `boss`, `pacing`. The `risk` and `atmosphere` categories (e.g., `cursed_key`, `blood_pact`, `fog_of_hedge` as atmosphere) exist only in design docs and have not been implemented yet.

> ⚠️ Design docs list ~25 affixes as a v1.5 target including `cursed_key`, `heirloom_pact`, `blood_pact`, `mistwoven`, `stoneflesh`, `tinder_cache`, `ink_spring`. None of these appear in the shipped `AFFIXES` dict. The 15 entries in code are current behavior.

## Affix weights and ink bias

Base weights in `BASE_WEIGHTS` range from 5 (`marked_quarry`) to 10 (`mineral_vein`). Slotted inks multiply specific affix weights before normalization. The roll for each slot is independent; the same affix cannot fill two slots in one chart. See [[Inks]] for the full bias table per ink.

## See also

- [[Inks]] — how to bias which affix lands
- [[Charts]] — how affixes are inscribed into a chart
- [[Chart Loop]] — the loop that makes rolling affixes meaningful
- [[The Crafting Bench]] — where affixes are set during inscription
- [[Dungeon Generation]] — how affix results alter what spawns
- [[Bosses]] — the trophy chain that unlocks boss den affixes
- [[Gather Nodes]] — resource-bias affixes populate these

## Sources

- `docs/cartography-keystone-design.md`
- `docs/cartography-progression.md`
- `wyrd/data/charts.gd`
