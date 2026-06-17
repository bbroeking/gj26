# Wayfinder System Plans — Map of Content

This vault holds **forward-looking build & expansion plans**, one note per
skill and per game system. Each note answers *"what's the next most valuable
work here, and what's in the way?"* — it is the **roadmap layer**, not the
reference layer.

How it relates to the rest of the docs:

- **repo-root `Plan.md`** owns the cross-cutting *combat-feel* and *loop-feel*
  passes (the "B0–B7" feel beats these notes repeatedly defer to). When a note
  says "blocked on Plan.md B0/B3/B6", that work lives there.
- **`kb/`** is the *"what exists"* design wiki (systems, entities, world,
  decisions, pipeline; start at `kb/index.md`). It describes the shipped
  reality; **this vault describes the intended next state.**
- **`docs/adr/`** holds the decisions these plans build on (ADR 0003 cozy
  spine, ADR 0012 mastery, ADR 0013 three power pillars / Ledger).

## Status legend

- ✅ **complete** — shipped and working; the note is an *expansion* roadmap.
- 🔶 **partial** — core is wired but meaningful gaps remain.
- ⬜ **stub** — placeholder / barely started (none currently).

---

## Player & Abilities

- 🔶 [[system-skills-hotbar]] — 4-slot hotbar, Focus resource, and loadout
  picker are fully shipped; the one load-bearing gap is pick-one-of-N mastery —
  adding a player-choice node at lv 5/10/14/17 to turn the auto-unlock ladder
  into a build-identity decision.
- 🔶 [[system-status-effects]] — Five ailments fully wired on enemies and
  player; priority next step is player visual parity (coloured tick-pulse +
  status pip row on the HP orb).
- ✅ [[system-player-controller]] — Locomotion + dash/roll-i-frame + bow + the
  shipped hit-feel block are complete; remaining work is movement-feel polish
  (a player lean) and hardening the co-op authority seams the netcode note flags.

## Combat Skills

- ✅ [[skill-basic-shot]] — Slot-1 always-on bow shot is fully functional and
  juicy; the single most important next step is wiring the 4-variant
  colour-picker (Arrow.variant_idx) which is stubbed but never written.
- ✅ [[skill-power-shot]] — Core heavy-hitter is fully shipped; expansion
  roadmap: perk-gated upgrade tiers, Burn synergy combos with Hunter's Mark,
  and a loadout-screen balance pass against Piercing Bolt.
- ✅ [[skill-multi-shot]] — Fully-shipped fan-of-three; expansion roadmap
  covers spread-count upgrades, a 5-arrow mastery variant, balance tuning, and
  a dedicated SFX asset.
- 🔶 [[skill-bramble-snare]] — Fully-implemented AoE root with a rich 5-beat
  VFX stack; missing pieces are the WINDUP cast animation, the thornwood pod
  pickup economy (visual-only), and any upgrade/synergy path.
- 🔶 [[skill-piercing-bolt]] — The corridor skill (1.6× line shot through up to
  3 enemies); highest-priority gap is a distinct visual identity (currently
  fires the same ember-red bolt as PowerShot) and a pierce-count upgrade path.
- 🔶 [[skill-rain-of-thorns]] — Delayed AoE nuke; mechanics fully wired but the
  telegraph VFX is prototype-quality — next step is a Spec-34 4-beat visual
  stack to match BrambleSnare's bar.
- 🔶 [[skill-thornburst]] — Player-centered ring AoE; damage and snare are live
  but VFX is a bare torus alpha-fade; next step is a Spec-34 5-beat rebuild.
- ✅ [[skill-hunters-mark]] — A fully wired boss-setup skill; expansion roadmap
  is a dedicated particle, a boss HUD tell, and perk-gated synergies.
- 🔶 [[skill-heartwood-ward]] — The game's only defensive skill is mechanically
  complete but lacks a HUD readout, a decay animation, a dedicated icon, and a
  balance pass to make the ward a real decision.
- 🔶 [[skill-mercy-shot]] — The execute finisher is mechanically live but has
  no in-world cue that the threshold is crossed; biggest gap is an enemy
  indicator and a distinctive kill burst.

## Progression

- 🔶 [[system-trades-progression]] — One unified Wayfinding skill (lv 1–17, 19
  perks) is shipped and gate-green; next priority is pick-one-of-N mastery
  choice at cluster levels and the level-up feel moment (Plan.md B3).

## Enemies & Combat

- 🔶 [[system-combatant-ai]] — 3-state FSM, melee, and ranged attacks all
  shipped; next priority is chain-aggro (solo enemies are trivially kited) then
  two new archetypes to broaden the combat vocabulary.
- 🔶 [[system-bosses]] — The 3-phase boss machine, sealed arena, and trophy
  chain are end-to-end wired; top priority is fixing the boss bar hardcoding
  "The Hedgemother" for all boss kinds, then the Ledger trophy→stat boost.
- 🔶 [[system-elites]] — 4-modifier data-driven elite system is wired; next
  step is per-modifier visual differentiation (all four share one golden tint).
- 🔶 [[system-combat-juice-vfx]] — Six-channel hit feedback is shipped and
  solid; remaining work is biome-tinted sparks, magnitude-scaled damage
  numbers, and a material-aware breakable-decor shatter.

## Gather · Craft · Economy

- 🔶 [[system-gathering]] — Channel-harvest loop is mechanically complete across
  all ore and herb tiers; main remaining work is feel polish (Plan.md B1–B2)
  and a minor herbal_patch affix data-fallback bug.
- 🔶 [[system-crafting]] — Three functional stations with 29 recipes and a solid
  craft() pipeline; next is the still's missing buff HUD, a craft_still SFX, and
  the Plan.md B5 station react() hook.
- 🔶 [[system-items-affixes]] — The data layer (kinds, rarities, make_item,
  affix rolls, tooltips) is fully wired; main gap is the missing ledger.gd that
  would make boss trophies a live stat source (ADR 0013 pillar #3).
- 🔶 [[system-inventory-equipment]] — Core data model and drag-UI are shipped;
  remaining work is pack-size progression, consumable stacking, a "full pack"
  HUD prompt, and the deferred InventoryController split.
- 🔶 [[system-drops-loot]] — The rarity-roll and loot-pipe are fully wired;
  remaining work is targeted boss drops, shrine item integration, pickup feel
  (Plan.md B4), and a headless test suite that locks the math.
- 🔶 [[system-economy]] — The faucet (sell to Hod) and the sink (buy at
  convenience-tax prices) are wired; the anti-arbitrage gate, more gold sinks,
  and a second vendor remain unbuilt.

## Wayfinding & Dungeons

- 🔶 [[system-charts-wayfinding]] — Chart data, affix engine, and bench are all
  shipped; the inscription ritual feel (Plan.md B6) and a few bad-twin gaps are
  the highest-leverage work remaining.
- ✅ [[system-chart-affixes]] — All 18 affixes (15 rollable + 3 boss-dens) are
  shipped and wired; expansion roadmap focuses on tension tuning, a third affix
  wave, and multiplayer fairness for bad-twin effects.
- 🔶 [[system-dungeon-generation]] — The TinyKeep procgen pipeline is fully
  shipped; next most valuable step is multi-floor descent and per-scope
  room-archetype expansion so each biome feels distinct.
- 🔶 [[system-biomes-decor]] — Crypt dressing is feature-complete; next priority
  is routing the briar_maze / hollow / snug scopes to distinct decor themes so
  each chart template reads as a different place.

## World & Interactables

- 🔶 [[system-town-hub]] — The 40×40 yard is structurally complete but lacks an
  arrival beat, a Living Atlas board, co-op spawn polish, and ambient life
  (Plan.md Part B / Phase B7).
- 🔶 [[system-interactables]] — A well-factored Interactable base exists and all
  five types are functional; remaining work is polish: shrine modal restyling,
  hearth GLB swap, buff variety, and interaction feedback.
- ✅ [[system-camera]] — The core FATE rig is fully shipped; expansion roadmap
  is polish — boss framing, a shake-accessibility toggle, and a town arrival
  ease-in (Plan.md B7).
- 🔶 [[system-npc-story-tutorial]] — Three NPCs are live, dialog is polished,
  tutorial steps 0–7 gate correctly; gaps are missing shrine/status/affix
  hints, inert Quill, an abrupt summit payoff, and ghosted portraits.

## Multiplayer

- 🔶 [[system-multiplayer-netcode]] — Phase A (town) and Phase B (dungeon) are
  both SHIPPED; Phase C polish — guest arrows, damage events, boss telegraphs,
  reconnect grace, exit vote, first-node sweep — is the remaining work.

## UI & Presentation

- 🔶 [[system-hud]] — Core meters and feedback are functional; biggest unshipped
  work is the level-up perk banner (Plan.md B3), buff/debuff icons, and toast
  polish.
- 🔶 [[system-ui-panels]] — The WyrdUi parchment kit is solid and consistently
  applied; next most important step is finishing the shrine-choice modal
  (currently unstyled) and landing the buff-HUD chip.

## Audio & Animation

- 🔶 [[system-audio-music]] — SFX pool and all 19 mp3 files are on disk and
  wired; next milestone blocker is dungeon ambience — no key or call site
  exists for it, and Plan.md B0 feel-beat keys aren't registered yet.
- 🔶 [[system-animation]] — Four complementary drivers are live and composing;
  next highest-value work is wiring gather arm-articulation (Plan.md B1) and
  per-skill cast poses so non-shot abilities have a visible tell.

## Persistence

- 🔶 [[system-save-load]] — The single-slot JSON save works for every shipped
  feature but has no corruption guard, no save-slot UX, and the roundtrip test
  still touches the real save path — three gaps that matter before a public build.

---

## Build priority

Synthesized across all 37 notes, weighted by the user's stated asks
(multiplayer friend-invites / Phase C, the lv 1→17 mastery TREE, every-slot-casts
— already done) and by status × player impact. Ranked top 8:

1. **Pick-one-of-N mastery choice** — turn the lv 5/10/13/14/17 auto-unlock
   clusters into a player build decision. This is ADR 0012's named refinement
   and the spine of the "skill tree" ask. → [[system-skills-hotbar]],
   [[system-trades-progression]]
2. **Level-up feel moment (Plan.md B3)** — perk-name banner + burst + HUD flash.
   The mastery choice should fire right after it; with no payoff today, leveling
   reads as a silent text bump. → [[system-hud]], [[system-trades-progression]]
3. **Multiplayer Phase C polish** — guest arrows, replicated damage events, boss
   telegraphs, reconnect grace, and the eight residual `get_first_node_in_group`
   wrong-player bugs. Directly serves the friend-invite ask. →
   [[system-multiplayer-netcode]], [[system-combatant-ai]]
4. **Ledger: trophy → live stat source (ADR 0013 pillar #3)** — `ledger.gd`
   does not exist; boss trophies are inert. It is seamed into items, economy,
   inventory, bosses, and progression and unblocks several notes at once. →
   [[system-items-affixes]], [[system-bosses]], [[system-economy]]
5. **Dungeon ambience + B0 feel-beat audio keys** — the dungeon is silent for an
   entire run; no ambience key/call site exists, and the gather/harvest/inscribe/
   craft/level SFX keys aren't registered. High felt-quality, low effort. →
   [[system-audio-music]]
6. **Boss bar hardcoded label fix** — `boss_bar.gd` shows "The Hedgemother" for
   Boar and Wolf fights too. A small, visible correctness bug in a marquee
   moment. → [[system-bosses]]
7. **Chart / affix preview + inscription ritual (Plan.md B6)** — the signature
   verb has no color-coded chart preview, no XP estimate, no active-affix HUD
   chips, and no inscription ceremony. Sharpens the differentiator. →
   [[system-charts-wayfinding]], [[system-chart-affixes]], [[system-ui-panels]]
8. **Panel & HUD polish: shrine modal restyle + buff HUD chip** — the
   shrine-choice modal is the one unstyled panel, and active still/shrine buffs
   are completely invisible (signals emitted, never connected). →
   [[system-ui-panels]], [[system-hud]], [[system-crafting]]

---

## Implementation plans

The strategic notes above describe *intent*; the **build docs** describe *order
of operations*. Start at **[[implementation-roadmap]]** — it sequences the 31
partial systems into dependency-ordered waves, calls out the cross-cutting
blockers (the missing `ledger.gd`, the shared mastery data model, the `Plan.md`
B0 `feel.gd`/audio scaffolding), and picks the suggested first sprint.

Each 🔶 partial note now has a companion `[[impl-<name>]]` build doc with a
decomposed task list and a *first commit* (the smallest safe, test-green slice).
Obsidian backlinks connect each impl note to its strategic note — e.g.
[[impl-system-bosses]] backlinks to [[system-bosses]].

---

## By status

**✅ complete (7)** — expansion roadmaps:
[[skill-basic-shot]] · [[skill-power-shot]] · [[skill-multi-shot]] ·
[[skill-hunters-mark]] · [[system-chart-affixes]] · [[system-camera]] ·
[[system-player-controller]]

**🔶 partial (32)** — core wired, gaps remain:
[[system-skills-hotbar]] · [[system-status-effects]] · [[skill-bramble-snare]] ·
[[skill-piercing-bolt]] · [[skill-rain-of-thorns]] · [[skill-thornburst]] ·
[[skill-heartwood-ward]] · [[skill-mercy-shot]] · [[system-trades-progression]] ·
[[system-combatant-ai]] · [[system-bosses]] · [[system-elites]] ·
[[system-combat-juice-vfx]] · [[system-gathering]] · [[system-crafting]] ·
[[system-items-affixes]] · [[system-inventory-equipment]] · [[system-drops-loot]] ·
[[system-economy]] · [[system-charts-wayfinding]] · [[system-dungeon-generation]] ·
[[system-biomes-decor]] · [[system-town-hub]] · [[system-interactables]] ·
[[system-npc-story-tutorial]] · [[system-multiplayer-netcode]] · [[system-hud]] ·
[[system-ui-panels]] · [[system-audio-music]] · [[system-animation]] ·
[[system-save-load]]

**⬜ stub (0)** — none currently.

Counts reflect **7 complete / 31 partial / 0 stub** across the 38 notes.

---

## Dangling links to reconcile

**None.** `system-player-controller` (referenced by 7 notes) was the one dangling
target — its writer agent died on a transient API error during the run; the note
was authored afterward, so all wikilink targets now resolve to existing notes.
