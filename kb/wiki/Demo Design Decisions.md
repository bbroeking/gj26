---
type: decision
tags: [design-decisions, demo, baseline, open-questions]
status: draft
updated: 2026-06-15
sources: ["kb/wiki/Universe Build-Out Plan.md", "kb/wiki/Gap Analysis and Build Plan.md", "kb/wiki/design/"]
---

# Demo Design Decisions

The opinionated baseline answer to the seven open design questions (see
[[Current State]] / the deep designs). **This is a draft to edit against, not
gospel** — each call is concrete enough to argue with. The three deliberately
spiky ones are flagged at the bottom. Already locked by ADR: gear gives no combat
power ([[Design Decisions|ADR 0010]]) and progression is one skill
([[Design Decisions|ADR 0012]]).

**The stance in one line:** *a cozy, opt-in-difficulty, fully-horizontal one-verb-read
crawler where the [[Chart Loop|chart]] is the load-bearing bridge,
inks are spice-with-a-cost, and the game is built pillar-by-pillar at a
throughput-honest pace.*

## 1. One-verb combat — make the *enemies* the content; ban safe kiting
- The bow is the only attack. Depth = reading enemy tells + the 4-skill loadout + positioning. Never the bow itself.
- **Hard rule: no enemy can be safely back-pedaled forever.** Every archetype gets an anti-kite trait (fast closer / movement-forcing AoE / standing-punish poke).
- **Poise/stance-break** is the core read: fill it in the boss's recovery windows → ~3s Reeling → Wayfinder's Mark finisher.
- TTK (cozy): trash 3–8s, elites 10–20s, bosses 60–120s over 2–3 phases.
- No combos / no execution depth — depth is *decision*, not dexterity.
- See [[Combat — Deep Design]], [[Enemies and Bosses — Deep Design]].

## 2. Cozy ↔ danger — warm-reset failure + a player-held difficulty dial
- **Death = wake at home, keep 100% of gathered mats + trophies, lose only the run's completion bonus.** No gear/XP/material loss in the demo.
- **Danger is opt-in:** you authored the chart; the summary card shows the danger before you commit. Player sets the ceiling; the floor is always cozy.
- Co-op: downed-not-dead + teammate revive; only a full wipe ends the run.
- Target: a default tier-1 chart is ~90% winnable; spice is chosen.
- See [[Chart Loop — Deep Design]], [[Charts Affixes and Inks — Deep Design]].

## 3. Hybrid coherence — chart is the mandatory bidirectional bridge; the cozy half must be fun alone
- **Hard rule:** no delve without inscribing (cozy→delve); the village only grows from delve rewards (delve→cozy). One causal chain.
- **The cozy half stands alone:** vein-reading, ink discovery, town growth must be fun even if you never delve.
- One [[Trades and Leveling|Wayfinding skill]] (ADR 0012) is the keystone — gathering and delving feed the same growth.
- Fiction seals it: gather / mix / delve are all *"remembering a way."*

## 4. Inks/economy — every ink is a tradeoff lever, never a stat stick
- **Each ink biases TOWARD some affixes and AWAY from others** (Palechalk → stone/ore, away from grove/forage). Slotting = a real choice with opportunity cost.
- **Ink slots are scarce** (≤3/chart; Master Wayfinder = +1) — pick a run *identity*, can't have everything.
- Inks are the universal currency/sink: inscription cost + Smudge-Stick reroll + dissolve-gear-to-ink-dust. Gold (Hod) is secondary.
- Recipes are **discovered**, not given.
- **Success test:** players agonize over which inks to slot. Auto-slotting = the inks need real downsides.
- See [[Crafting and Inks — Deep Design]], [[Items Gear and Economy — Deep Design]].

## 5. Co-op — honest cozy-social baseline + ONE cheap "better-with-two" beat ⚠️
- **Demo co-op = social, not interdependent, and we say so:** same bow, same seed, shared town, party-wipe stakes, per-player loot. No forced roles.
- **Add one cheap distinct-with-two mechanic now:** a **"two-hands" interaction** — rich nodes / a sealed vault need one player to brace while another harvests or crosses.
- **Signature co-op identity = #1 post-demo bet: the chart-reader seat** (one player reads the chart's tells and calls them while others fight).
- See [[Multiplayer Co-op — Deep Design]].

## 6. Progression — VERTICAL power, fueled by the cozy spine (RESOLVED 2026-06-15)
*The earlier "fully horizontal" call was overruled: the numbers DO get bigger.*
- **You get stronger via three sources, all fed by the cozy loop (never by grinding kills):**
  1. **Leveling** your Wayfinding skill grows damage/HP; the cap rises past 17 in the full game. You level by gather/craft/chart, so the cozy loop is the engine of power. (Combat still gives no skill XP — ADR 0012.)
  2. **Gear** — crafted, gather-gated equipment gives power (rolled affixes matter). **Reverses ADR 0010** → to be rewritten as "gear gives power, gather-gated." Power flows from smithing, not kill-loot.
  3. **Boss trophies / Ledger** — each trophy grants a real stat boost (capped per slot), tied to the trophy chain — the "kill boss → get stronger" beat.
- **Dungeons scale to match:** deeper tiers / Deepening scale enemy numbers up. Anti-escalation holds — *no new, worse creature*; the Hedgemother stays the apex being, deeper just means bigger numbers.
- **Cozy guardrail:** the fastest way to get strong is to play the cozy game (skill/craft/charts/bosses), never to grind mobs.
- **Still horizontal alongside the vertical:** Codex (collection), Living Atlas (the village grows), opt-in seasonal novelty — no daily chores/streaks.
- See [[Progression and Endgame — Deep Design]], [[Items Gear and Economy — Deep Design]].

## 7. Content pipeline — scope follows a *measured* throughput number, not ambition
- **Rebuild the pipeline immediately (Tier 0/1), then measure one biome** before sizing the universe.
- **Re-scope to throughput-realistic:** a few hero biomes + heavy re-skinning of the existing crypt/Briar-Maze kits. Demo = exactly 2 (hardened crypt + the Pale Veins).
- Systems-first on tinted dummy clones; art in tonal batches of 3–5; custom Meshy clips only for boss signature moves; kick AI batches early (async).
- **First step:** recover `clean_ai_mesh.py` + the briefs from git, push one Pale Veins tile-set + one creature end-to-end, **record GLBs/week** — that number caps how many biomes the full game can have.
- See [[Asset Pipeline]], [[Gap Analysis and Build Plan]].

## The contested calls (where to fight first)
- **⚠️ #5 co-op** — I forced a real co-op mechanic ("two-hands") into the demo. Counter-position: social-only is enough for a cozy game; save the effort.
- **⚠️ #6 horizontal** — *zero* power growth sheds a whole player type. Counter-position: a small vertical mastery bump as a hook.
- **⚠️ #1 kiting** — "ban safe kiting" makes a ranged-cozy game tenser than some cozy players want. Counter-position: kiting *is* the cozy fantasy.

## See also
- [[Universe Build-Out Plan]] · [[Gap Analysis and Build Plan]] · [[Current State]]
