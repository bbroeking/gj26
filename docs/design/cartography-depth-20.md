# Cartography depth — 20 ideas

> The current loop (raw → ink → rune → chart → dungeon) works. These are
> ideas to make the *skill itself* feel deep — not just "more dungeons,"
> but more verbs, more decisions, and more moments where carto-knowledge
> beats raw level. Tagged by cost (S/M/L) so we can pick.

## Pillars these ideas push

- **Knowledge > level.** A carto-savvy Lv 20 player should out-craft a
  brute-force Lv 40 who picks defaults.
- **Many small decisions.** Each step (ink, slot, rune, fold, sign)
  should be a real choice, not a default.
- **Replayability without grind.** Charts should feel different at
  Lv 50 than at Lv 20, even on the same template.

---

## 1. Themed chart families · M

Add 4 themed templates that lock to one essence: **Bramble Vault**
(verdant), **Smelter's Reach** (earthen), **Briarscar** (sanguine),
**Mirepool** (lumen). Each has its own enemy mix, biome materials in
chests, and a signature affix the matching ink dramatically biases.
Makes ink choice mean "what *kind* of dungeon," not just "shape the
roll."

## 2. Boss charts (named encounters) · M

A new template tier ("Wardens") that always ends in a named
hedgemother-tier boss. Unlocks at carto 40. The roll picks *which*
warden — fixed pool of ~6 named bosses, each with a unique drop. Boss
charts can't be re-rolled; they consume a chart_seal.

## 3. Echo charts (overworld inversion) · L

New verb: **Echo** at the Chartmaker stone. Picks a region of the
overworld you've explored — cloister, town, your hut — and produces a
chart that inverts it (same layout, hostile enemies). Carto knowledge
lets you predict cover spots from memory. Carto 35.

## 4. Layered charts (multi-floor) · M

Templates with `floors: 3`. Affixes compound between floors — floor 2
adds your floor-1 affixes plus one new one. Chest at the bottom is
loot-multiplied by floor count. Carto 25.

## 5. Decaying charts (use-it-or-lose-it) · S

Charts gain a `decayAt` timestamp on inscription (24h). Each uncompleted
hour drops one affix tier (good→neutral→bad). Push the player to run
fresh charts instead of hoarding. Counter-pressure to hoarding behavior.

## 6. Survey verb (new gathering loop) · M

New verb: stand near a feature in the overworld, hold **R** for 3s →
sketches *and* unlocks a chart template themed on it. Surveying the
forge unlocks Forge Ruin chart. Surveying the well unlocks Drowned
Wellroom. Turns the overworld itself into the source of new templates.

## 7. Cartographer's Atlas · S

Codex-style index of every chart you've ever inscribed (seeds + affix
list). Carto 40 unlocks **Copy from atlas** — half ink cost to re-make
a chart you've already cracked. Mid-game flow becomes "scout templates
once, copy the good ones."

## 8. Chart seeds + sharing · S

Every chart gets a 6-letter seed (`G3K-PLM`). Two players running the
same seed get identical layouts. Build the share-chart UI later; for
now, surface the seed in the chart's tooltip and accept "Open chart
from seed…" input.

## 9. Cursed charts (high-risk band) · S

5% chance an ink-mix produces a Wild Cursed Ink instead of a normal
wild. Charting with Cursed Ink rolls all bad twins but doubles XP and
gates a unique-only loot table. Gives a way to *intentionally* use
bad-twin affixes for the reward.

## 10. Folded charts · M

At carto 30, the workshop gains a **Fold** action: consume two T1
charts → produce one T2 chart with a hand-picked affix from each
parent. Carto-savvy players can build a perfectly-affixed T2 from
two cheap T1 rolls.

## 11. NPC-signed charts · M

Hod / Quill / Withering / Maud each gain a "Sign chart" dialog option
once you've raised their friendship. A signed chart guarantees one
good twin on a thematically-aligned affix (Hod → mineral_vein,
Quill → bramble_bloom, etc.). Pulls NPC progression into carto.

## 12. Dynamic daily wheel · S

A free affix-of-the-day applied to every chart inscribed today
(e.g. "Today: gilded_seam +50%"). Visible in the workshop header.
Drives daily replay without forcing daily quests. Server-less:
deterministic from the date string.

## 13. Inkwell vessels (cross-skill loop) · L

Tier-3 inks require crafted vessels: clay flask (Hod), bound parchment
(Quill), glass vial (Cricket). Pulls forge/cooper/herbalist skills
into the carto loop. Each vessel adds a different bias modifier.

## 14. Map fragments (drop loop) · M

Elite enemies drop **map fragments**. Four fragments combine into a
"Found Chart" that bypasses the inscribe step — pre-rolled, themed by
the elite that dropped them (boar elite → Boar Warren, hedgewight
elite → Wightspire). Adds a chart type that flows from combat, not
crafting.

## 15. Constellation charts (night-only) · M

After dusk, the workshop unlocks **Constellation** templates. Use
lumen + mind essences. Layouts are dreamlike, fog-heavy, and drop only
*memory* items (lore unlocks, cosmetics, codex pages). No combat XP,
double carto XP, no normal loot. Adds a parallel non-combat carto loop.

## 16. Master keys (Lv 99 capstone) · S

A unique chart that re-rolls its affixes every time you re-enter
(no consume on use). Lv 99 carto reward. Becomes the player's permanent
"daily run" anchor and a status-symbol item.

## 17. Annotated charts · S

After completing a chart, the player can write a one-line annotation
("Boar elite top-right by the lantern"). The annotation persists with
the seed; if you or anyone else runs that seed, the note shows on the
loading screen. Tiny social loop without networking.

## 18. Reverse cartography (Mirror NPC) · M

The Mirror NPC takes a *completed* chart and produces a "Mirrored"
twin: same layout, flipped on the diagonal, with opposite-essence
enemies (sanguine ↔ lumen, verdant ↔ earthen). Costs the same chart;
returns one of opposite type. Adds an asymmetric trade verb.

## 19. Personal cartographer's signature · S

Inscribed charts gain a hidden glyph (your save's hash). When another
local-save player imports your seed, they see "by [glyph]". Later we
can light up a leaderboard tracking which signatures cleared which
seeds fastest. Foundation for cooperative meta later.

## 20. Living atlas / hidden meta-map · L

Every completed chart fills in one tile on a hidden world map.
Completing all tiles in a region unlocks a *new overworld biome* the
player can walk to (e.g., the Ashvale gate east of Bramblewood opens
when 25 carto charts are cleared in tier 2+). Charts feed real
exploration; the village is a hub, the world expands as you map it.

---

## Picking order — my recommendation

If we're going to pick three, I'd start with these because they
multiply each other:

- **#7 Cartographer's Atlas** (S) — gives the carto skill a
  permanent-feeling artifact you build, not just consume
- **#11 NPC-signed charts** (M) — pulls existing NPCs into the loop
  without new content, and creates a real reason to talk to them
- **#1 Themed chart families** (M) — gives "what kind of chart"
  meaning, which makes signing + atlas decisions feel weightier

After those land, **#10 Folded** + **#5 Decaying** form the next
natural pair (one hoarding-counter, one hoarding-rewarder, balancing
each other). **#20 Living atlas** is the long-term spine that ties
carto into the actual world expansion roadmap.
