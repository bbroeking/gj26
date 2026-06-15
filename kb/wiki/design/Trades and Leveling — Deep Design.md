---
type: design
tags: [system-design, trades]
status: draft
updated: 2026-06-14
sources:
  - "kb/wiki/systems/Trades and Leveling.md"
  - "kb/wiki/entities/Wayfinding.md"
  - "kb/wiki/entities/Earthcraft.md"
  - "kb/wiki/entities/Wildcraft.md"
  - "kb/wiki/entities/Huntcraft.md"
  - "kb/wiki/concepts/Balance Philosophy.md"
  - "kb/wiki/Universe Build-Out Plan.md"
  - "wyrd/scripts/game.gd"
  - "kb/wiki/games/rpg/The Elder Scrolls V Skyrim.md"
  - "kb/wiki/games/rpg/Disco Elysium.md"
  - "kb/wiki/games/arpg/Grim Dawn.md"
---

# Trades and Leveling — Deep Design

> Forward-looking deep design. Current-state: [[Trades and Leveling]]. Constrained by [[Universe Build-Out Plan]].

## Player fantasy & role in the cozy spine

You are a Wayfinder who *grows competent at everything you touch* — not by picking a class, but by **doing**. Mine and Earthcraft rises; forage and Wildcraft rises; fight and Huntcraft rises; come home, mix ink, and inscribe a chart, and Wayfinding rises. The four Trades are the spine's progression voice (ADR 0003): [[Wayfinding]] is the differentiator the other three feed, and every Trade levels in **every** region (P11). The fantasy is Skyrim's use-based leveling (`The Elder Scrolls V Skyrim` §"give every Trade a doing loop") wearing storybook clothes — no character sheet to mis-build, just the slow filling-in of an atlas of competence as the village grows back.

## What ships today (grounded in code — `wyrd/scripts/game.gd`)

The system is **already real and tested**, not a proposal:

- **One shared curve.** `xp_for_level(n) = (n-1)² × 8 + (n-1) × 32` (line 268). Lv2=40, Lv10=936, Lv17=2560. Step grows linearly `16n+24`.
- **`LEVEL_CAP := 17`** (line 276); `award_xp` (line 278) banks XP past the cap but stops leveling — a post-demo lift discards nothing.
- **`PERKS` dict** (lines 411–462): four arrays of `{id, lv, name, desc}`, gated by `perk_active(trade, id)` (line 464), which is just `trade_lv(trade) >= perk.lv`. The Trades page (K) renders this dict generically, so a new perk row needs **zero UI code**.
- **Perk effects are scattered, not centralized:** `gather_bonus` (line 472), the Second Pour branch in `craft` (line 383), Smith's Thrift (line 392), and combat-side reads in `player_controller`/`combatant`. There is no perk *registry* — each perk is hand-wired at its effect site.
- **XP faucets** are spread across `craft` (line 406), `discover_ink` (+50, line 567), `try_pot_mix` (+5 smudge, line 601), `return_to_town` (chart completion, line 718), and `combatant._die` (Huntcraft `max(2, hp_max/3)`).

This is the substrate the deep design extends — it does **not** rewrite it.

## Deep design

### Core mechanics (precise, Wayfinder-flavored)

1. **Mastery choices replace fixed perks above ~Lv10.** Today every perk is a fixed unlock. The deep move (per Build-Out Plan §4.1, *Earthcraft only* in the demo) is to turn the upper perks into **pick-one-of-N** at a milestone — same power budget, real identity. Disco Elysium's Thought Cabinet ("limited slots force curation") is the model, not Grim Dawn's devotion tree (a 200-node star-map is exactly the scope a tiny team must refuse). A mastery choice is **one decision, two-to-three options, re-pickable at a cost** — never a sprawling graph.

2. **Cross-trade synergy chains** make the trades feed each other diegetically: deep ore (Earthcraft) → deep ink (Wayfinding) is the one two-hop chain built for the demo. The principle, already live, is that the *deepest* recipe of one trade requires a material from another (Hedgesteel Bar needs Wildcraft logs; Foxglove Ink needs bogiron). Synergy is authored as **recipe inputs**, never as a hidden XP multiplier.

3. **Beyond-17 is horizontal.** No power past the cap. Banked XP converts to **Grand Routes** — cosmetic titles and Codex/atlas completion milestones ("the Wayfinder who walked every vein") — honoring P6's anti-escalation and §7's "horizontal progression" anti-pattern guard.

### Data model & formulas (concrete, GDScript-flavored)

The mastery upgrade keeps the existing `PERKS` shape and adds an optional `choices` array. `perk_active` stays the level gate; a new `mastery_pick(trade)` reads the player's stored choice:

```gdscript
"earth": [
  ...,
  {"id": "deep_seam_mastery", "lv": 13, "name": "The Deep Seam",
   "choices": [   # pick ONE at Lv13 — same power budget, real identity
     {"id": "rich_seams",   "name": "Rich Seams",   "desc": "deep veins always give a second lump"},
     {"id": "true_smelt",   "name": "True Smelt",   "desc": "+15% bar yield from deep ore"},
     {"id": "quick_pick",   "name": "Quick Pick",   "desc": "deep-vein channel −20%"},
   ]},
]
# new state: trades[key].masteries = {"deep_seam_mastery": "rich_seams"}
# new gate:  func mastery_active(trade, choice_id) -> bool
```

| Decision | Value | Why |
|---|---|---|
| Curve | unchanged `(n-1)²×8 + (n-1)×32` | tested across the whole unlock ladder; re-tuning is expensive (ADR 0006) |
| Cap | 17 (`LEVEL_CAP`) | Summit at 16 + 1; capstone felt one level before the ceiling |
| Mastery scope (demo) | Earthcraft Lv13 only | proves the pattern at zero balance cost before it spreads |
| Re-pick cost | small ink fee at the bench | inks are the value spine (P12); curation has weight without being punishing |
| Beyond-17 | banked XP → titles, never stats | P6 / Balance §7 (no power creep, horizontal tail) |

### Content to author (tiers / worked examples)

| Trade | Mastery node (Lv13–17) | Pick-one-of-N (same budget) |
|---|---|---|
| Earthcraft (DEMO) | The Deep Seam (13) | Rich Seams / True Smelt / Quick Pick |
| Wayfinding (HORIZON) | Sure Lines → Mastery (10) | Steadier nib / wider ink slot / cheaper reroll |
| Wildcraft (HORIZON) | Light Hands → Mastery (13) | +herb / +brew bottle / faster channel |
| Huntcraft (HORIZON) | Heavy Draw → Mastery (14) | crit damage / focus return / CDR |

**Worked synergy (built for the demo):** mine a Pale Veins `ore_rock` → vein-read for **deep ore** → refine at the bench into **Palechalk Ink** → slot it into a chart to bias toward stable affixes. Earthcraft XP at the node, Wayfinding XP at chart completion — one gather, two trades fed, told as one continuous loop (P3).

**Worked title (Horizon):** at Lv17 with all four trades capped, banked overflow unlocks "**Walked Every Vein**" in the [[Wayfarer's Codex]] — a line of WORLD_LORE-voice text and an atlas stamp. Zero stat effect.

### Edge cases, failure modes, anti-frustration

- **No mis-build trap.** Skyrim's lesson (§"avoid forcing a Trade choice before playing"): you never pick a class, and a mastery is re-pickable for ink, so a "wrong" pick is a small refund, never a ruined character.
- **Banked-XP honesty.** XP accrues past 17 already; the post-demo cap lift must read the banked value, not reset it — a save-migration concern, not a leveling one.
- **Perk-effect drift.** Because effects are hand-wired at their sites (not a registry), every new mastery choice needs its effect *and* its `mastery_active` gate added together; a choice with no effect site is a silent dead pick. The mastery PR must touch the effect site in the same change.
- **No XP-by-region rule.** A region is never "the Earthcraft region" (P11) — it is rich in certain `GatherNode` kinds and creature families. The flavor is the gather palette; the XP is universal.
- **Cozy pacing holds.** Mastery picks add *decision* texture, never a power gate; an underleveled player still clears with cooked food (Balance §2).

## Interlocks — how this feeds/uses other systems

- **[[Wayfinding]] / [[Chart Loop]]:** chart completion is the largest Wayfinding faucet; ink slots and Sure Lines bias [[Affixes]] toward good twins.
- **[[Earthcraft]] / [[Gathering]]:** ore harvest is the Earthcraft faucet and the deep-ink chain's first link.
- **[[Wildcraft]] / [[Crafting]]:** forage/chop/cook/brew faucets; logs feed deep [[Earthcraft]] smithing.
- **[[Huntcraft]] / [[Combat]]:** the one combat trade, fed by **all** kills everywhere (`max(2, hp_max/3)`, ADR 0005); chart [[Affixes]] (Tyrannical, Festival Pace) are its training dial.
- **[[Economy]]:** mastery re-pick fee and ink refining route through the ink value spine (P12); no-arbitrage gate (Balance §5) keeps deep materials gather-only.
- **[[Skills]]:** Huntcraft level gates hotbar Skills (H4/H7/H9) — distinct from Trades.

## Demo scope vs Horizon

| Feature | Scope | Note |
|---|---|---|
| Four trades, shared curve, cap 17, `PERKS` dict | **SHIPPED** | live and tested today |
| Earthcraft Lv13 pick-one-of-N mastery | **DEMO** | Build-Out §4.1; proves the pattern, zero balance cost |
| Deep ore → deep ink cross-trade chain | **DEMO** | the one two-hop synergy (Pillar One) |
| `mastery_active` gate + stored choice in save | **DEMO** | small, additive to `PERKS` shape |
| Pick-one-of-N for all four trades | HORIZON | spreads only after the demo proves it (§10) |
| Beyond-17 titles / Grand Routes | HORIZON | horizontal tail, post-demo |
| Trade-flavored skill voices across the cast | HORIZON | Disco-Elysium skill-as-voice ambition (§3.6) |

Respects the P7 cut-line (mastery ships *inside* the Pale Veins pillar that uses it) and P1 spine-growth (Earthcraft is the demo's deepened trade).

## Implementation notes (Godot)

- **Lives in** `wyrd/scripts/game.gd`: extend the `PERKS["earth"]` array with a `choices` block; add `masteries` to the per-trade dict in `_ready`/save; add `mastery_active(trade, choice_id)`; wire the chosen effect at its existing site (e.g. the Rich Seams branch in `gather_bonus`).
- **UI:** the Trades page (K) already renders `PERKS` generically — a mastery row needs a small picker (three buttons), a new kit-compliant control passing `check_ninepatch.py` with a `WYRD_UI_SHOT` surface (Build-Out §6 UI workstream).
- **Save:** the `masteries` dict is new persisted state — gated behind the **migration ladder** (Build-Out §9), never a destructive reset.
- **Guarded by** `test_wyrd_loop.gd` (XP/economy gates) and a new assertion that a chosen mastery's effect site fires; `test_skills.gd` stays the dispatch guard.
- **Balance:** validated by the on-demand balance-sim script (P10), never a commit gate.

## Open questions

- Where does the mastery **re-pick** happen — Mara's bench, or a dedicated "remembering" interaction? (Affects the diegetic frame.)
- Does Huntcraft get a mastery node at all, or stay fixed perks (it is deliberately the quietest trade, ADR 0005)?
- Beyond-17: do titles attach to the [[Wayfarer's Codex]] or a separate "Grand Routes" panel? (UI scope.)
- Should the deep-ore→deep-ink chain be the *only* synergy in the demo, or pair with one Wildcraft→Wayfinding chain to avoid Earthcraft monopolizing the spotlight?

## See also / Sources

- [[Trades and Leveling]] · [[Wayfinding]] · [[Earthcraft]] · [[Wildcraft]] · [[Huntcraft]]
- [[Balance Philosophy]] · [[Chart Loop]] · [[Economy]] · [[Skills]] · [[Combat]]
- [[Universe Build-Out Plan]] (P1, P6, P7, P11, P12; §4.1)
- `wyrd/scripts/game.gd` — `PERKS`, `perk_active`, `xp_for_level`, `award_xp`, `LEVEL_CAP`
- Game refs: `The Elder Scrolls V Skyrim` (use-based leveling), `Disco Elysium` (curated-slot perks), `Grim Dawn` (devotion tree — the scope to refuse)
