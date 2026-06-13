---
type: concept
tags: [mmo-research, synthesis, design-lessons]
status: maintained
updated: 2026-06-13
sources: ["kb/wiki/research/World of Warcraft.md", "kb/wiki/research/RuneScape.md", "kb/wiki/research/EVE Online.md", "kb/wiki/research/Final Fantasy XIV.md", "kb/wiki/research/MMO Survey.md", "kb/wiki/research/MMO Economy and Itemization.md", "kb/wiki/research/MMO Progression Systems.md", "kb/wiki/research/MMO Social and Endgame.md", "kb/wiki/research/MMO Server Architecture.md", "kb/wiki/research/MMO Netcode and Tick Systems.md"]
---

# MMO Lessons for Wayfinder

The "so what" of the [[MMO Research]] cluster: what the genre's design and
implementation history actually tells us to **borrow, adapt, or avoid** for
Wayfinder — a *cozy, 2–4-player co-op* dungeon-crawler with four
[[Trades and Leveling|trades]] to a level-17 demo cap, a [[Chart Loop|chart loop]],
[[Combat|one-verb combat]], and a [[Economy|no-arbitrage economy]]. Wayfinder is
not an MMO; the value is in the scaled-down lessons, not the scale.

## What Wayfinder already gets right (validated)

- **One character, all disciplines.** Wayfinder puts all four trades on one
  character — exactly [[Final Fantasy XIV|FFXIV's]] "one character, all jobs"
  insight, and the opposite of WoW's alt treadmill. Keep it.
- **No holy trinity.** [[MMO Social and Endgame|The trinity creates a structural DPS surplus and tank/healer scarcity]] that makes matchmaking miserable — and a
  *mandatory healer is untenable at 2–4 players*. Wayfinder's [[Combat|one-verb combat]] sidesteps this. Caveat (the [[MMO Survey|GW2]] lesson): abolishing the
  trinity means you must design encounters that *don't quietly assume one* — lean
  on [[Affixes]] and positioning, not role-checks.
- **In-game play is the best path to loot.** [[MMO Economy and Itemization|Diablo III's real-money auction house "short-circuited the core reward loop"]] and was
  torn out. Wayfinder's [[Economy|no-arbitrage smithing gate]] (deep ores never
  sold on Hod's shelf) already enforces the same principle. Hold that line.
- **Host-authoritative is the right call at our scale.** [[MMO Netcode and Tick Systems|Client prediction, reconciliation, and lag compensation]] exist to hide
  internet latency; at LAN/friend-group latency Wayfinder doesn't need them. Its
  [[Multiplayer Co-op|seed-identical world + 10 Hz host snapshots]] is the correct
  small-scale analog of an authoritative zone server, and *trust-the-party* is an
  acceptable anti-cheat posture for invited friends.

## What to borrow

- **The Mythic+ / league model for chart replayability.** [[World of Warcraft|WoW's Mythic+]] (a consumable keystone that scales difficulty with rotating weekly
  affixes) is the direct design ancestor of the [[Chart Loop]]. The transferable
  refinements: *weekly/seasonal affix rotation* keeps runs fresh, and
  [[MMO Progression Systems|Path of Exile's opt-in seasonal resets]] show how a
  periodic fresh economy revives discovery without punishing anyone.
- **XP-curve psychology.** [[RuneScape|OSRS's curve doubles every ~7 levels]] so
  that *level 92 is the halfway point to 99* — a deliberate, legible "long tail."
  Wayfinder's curve is quadratic and capped at 17; worth borrowing the *milestone
  framing* (a visible "you're halfway" beat) even if the math differs.
  > ⚠️ The [[MMO Progression Systems]] page flags Wayfinder's quadratic curve as a
  > divergence from the OSRS doubling curve [[Trades and Leveling]] is otherwise modeled on.
- **Sinks as first-class design.** [[MMO Survey|Ultima Online's closed economy collapsed]]; the fix everywhere is deliberate *sinks* ([[MMO Economy and Itemization|OSRS's 2% GE tax that deletes items, repair costs, consumables]]).
  Wayfinder's consumable draughts and chart-inscription costs are sinks — make
  sure faucets (drops, gather nodes) never outpace them.
- **Friendship and recurring encounters as retention.** [[MMO Social and Endgame|The strongest retention force is a single good friend, built through repeated shared encounters]] — not forced dependency. Co-op with the *same* friends, plus the
  party-wipe boss rule that makes a [[Bosses|boss]] a shared stake, is exactly this
  lever at 2–4-player scale.

## What to adapt at our scale

- **Marketplace.** [[MMO Economy and Itemization|GE vs AH]] is a player-market
  problem; Wayfinder's curated [[NPCs|Hod vending]] is the right call for co-op and
  avoids the bot/RMT arms race entirely ([[MMO Survey|Lineage II banned 1.38M accounts]] and still deflated). Only revisit a player market if Wayfinder ever
  goes persistent-multiplayer.
- **Retention without obligation.** [[MMO Progression Systems|Daily-quest burnout hits around ~1 hour of obligation per session]] ("I *need* to do my dailies").
  Cozy means *no* FOMO chores — prefer opt-in seasonal/chart-rotation freshness over
  login-streak pressure. This is consistent with the [[Balance Philosophy|cozy pacing]] target.

## What to avoid

- **Mudflation / the vertical treadmill.** The level-17 cap and tight scope
  sidestep this for the demo; resist piling on ever-higher gear tiers that obsolete
  the last (the WoW level-squish was the cleanup bill for exactly that).
- **Talent-tree churn.** [[World of Warcraft|WoW repeatedly pruned and rebuilt its talent trees]]; the lesson is that *unstable* progression frustrates. Keep the
  [[Wayfinding|perk ladders]] stable once shipped.
- **Architecture debt.** [[Final Fantasy XIV|FFXIV 1.0 had to be rebuilt from the foundation]] because the core architecture was wrong. Wayfinder's analog: keep the
  [[Multiplayer Co-op]] authority model and [[Save System|save schema]] sound now,
  while the surface area is small.

## Pattern → Wayfinder map

| MMO pattern | Source | Wayfinder system | Stance |
|---|---|---|---|
| Keystone + rotating affixes | [[World of Warcraft]] M+ | [[Chart Loop]], [[Affixes]] | **Borrow** (add seasonal rotation) |
| Seasonal economy reset | [[MMO Survey]] (PoE) | [[Chart Loop]], [[Economy]] | Borrow (opt-in) |
| One character, all jobs | [[Final Fantasy XIV]] | [[Trades and Leveling]] | Already done ✓ |
| Skill-as-verb, XP doubling curve | [[RuneScape]] | [[Trades and Leveling]] | Adapt (milestone framing) |
| No trinity → design around it | [[MMO Survey]] (GW2) | [[Combat]] | Already done ✓ (mind encounters) |
| In-game play = best loot path | [[MMO Economy and Itemization]] (D3) | [[Economy]] | Already done ✓ (hold line) |
| Faucets/sinks discipline | [[MMO Economy and Itemization]] (UO/OSRS) | [[Economy]], [[Gathering]] | Borrow |
| Friendship/recurring encounters | [[MMO Social and Endgame]] | [[Multiplayer Co-op]], [[Bosses]] | Borrow |
| Host-authoritative + seed-identical | [[MMO Netcode and Tick Systems]] | [[Multiplayer Co-op]] | Already done ✓ |
| Player market / auction house | [[MMO Economy and Itemization]] | [[NPCs]] (Hod) | Avoid at co-op scale |
| Daily-obligation retention | [[MMO Progression Systems]] | [[Balance Philosophy]] | Avoid (cozy) |
| Vertical gear treadmill | [[MMO Progression Systems]] | [[Items and Gear]] | Avoid (cap-scoped) |

## See also
- [[MMO Research]] (the hub) · [[Design Influences]] · [[Balance Philosophy]]
- [[Current State]] — where these lessons could land next
