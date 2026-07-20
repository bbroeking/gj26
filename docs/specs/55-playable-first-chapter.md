# Spec 55 — Playable First Chapter

> **Outcome:** a fresh player can launch Wayfinder on desktop or the web,
> complete the `Snug` and `Tier 1 Hollow` Charts in one 25–35 minute session,
> become visibly stronger, discover the first trace of an ongoing mystery, and
> understand why they want to inscribe a third Chart.

> **Storyboard:** [Spec 57 — First-Session Onboarding Storyboard](57-first-session-onboarding-storyboard.md)
> turns this chapter contract into the timed shot list, exact UI disclosure,
> recovery behavior, and implementation slices.

## Why

The mechanical spine already works end to end. The next risk is not missing
systems; it is whether a new player can read the game, feel the authorship in
Wayfinding, and leave the first session curious. This spec turns the shipped
parts into a deliberately paced first chapter, then defines the content and
asset contracts used to deepen it without producing disconnected features.

The target feelings are **wonder**, **discovery-as-content**, **earned
mastery**, **quirky charm**, and **belonging to Bramblewood**. The tutorial may
clarify the next verb, but must not explain away the mystery or mark every
optional discovery.

## Experience contract

The first session follows this rhythm:

```
title → meet Mara → gather → mix Hedge Ink → inscribe Snug
      → complete Snug → return stronger → craft one preparation
      → inscribe Tier 1 Hollow with an ink choice → read one Affix twin
      → find the second marginal mark → complete the Hollow
      → Mara reacts → a third Chart becomes a self-directed goal
```

The first Chart ends with a question, not a boss. The second Chart proves that
the question can recur inside different generated places. Bosses and the
trophy Ledger remain the later answer-and-power arc.

## Opening mystery — the Second Hand

Working player-facing term: **the Second Hand**. It is not a revealed person or
villain in this chapter.

- The player inscribes a Chart at the table.
- Inside the resulting place they find a small piece of marginalia they did not
  draw: the same hooked mark on two different surfaces.
- The first mark may be dismissed as old graffiti. The second is clearly in the
  player's own ink and therefore could not predate the Chart.
- Mara recognizes the mark as deliberate but does not identify its author. Her
  response is curious and practical, not an exposition dump.
- The Living Atlas records only what the player has observed. It does not show
  a checklist or reveal the solution.

The hook must remain compatible with several later answers: a hidden
Wayfinder, the Charts themselves answering back, a Bramblewood intelligence,
or a known NPC working through an unknown motive.

## Scope

### Phase 0 — Web baseline

**In:**

- Repair the `Web` export preset around `Main.tscn`, `Town.tscn`, and
  `World.tscn`, including dynamically loaded scripts/data and runtime assets.
- Keep the export single-threaded and single-player.
- Add a repeatable browser smoke that boots the title, chooses New Game, and
  reaches Town without a script/resource error.
- Exercise Compatibility-renderer output for Town and one `Snug` run.
- Measure raw and compressed `.wasm`/`.pck` sizes; record the largest asset
  contributors before setting numeric web budgets.
- Preserve local save behavior and surface a warning when browser persistence
  is unavailable.

**Out:**

- Browser co-op. The live ENet/UPnP transport is native-only; a WebSocket or
  WebRTC transport is separate work.
- A marketing site, accounts, cloud saves, payments, analytics, or a backend.
- Mobile-browser certification.

### Phase 1 — First 30 minutes

**In:**

- Retain the existing tutorial steps and event seams, but pace them as two
  complete Chart loops rather than a list of UI operations.
- `Snug` remains fixed, gentle, and Affix-free.
- Place the first Second Hand clue on the guaranteed route near the far
  Waystone, readable without opening a journal.
- On first return, award and visibly summarize Wayfinding XP, gold/finds, and
  one immediately useful preparation choice.
- `Tier 1 Hollow` remains the first one-slot Affix Chart. The table teaches one
  ink choice, the resolved good/bad twin, and the den difficulty band.
- Guarantee one optional room or side discovery in the second run without
  marking its precise location.
- Place the second clue in that run and give Mara a short reactive response on
  return.
- Keep first-use hints for shrines, statuses, and Affix reading concise and
  state-gated.

**Out:**

- A bespoke cinematic, voiced cutscene, full quest log, waypoint trail, or a
  first-session boss.
- Rebalancing the complete level 1–17 curve.

### Phase 2 — Power and return clarity

After each completed Chart, the player must understand what changed.

- **Wayfinding:** XP, level progress, new recipe/Chart/Skill/mastery gates.
- **Gear:** crafted or found stats flow through `_derive_stats()`.
- **Ledger:** boss trophies provide later permanent power and are previewed,
  not awarded, during this chapter.
- **Gold:** early gold buys control or convenience without skipping gathering
  gates. Existing repairs and wares remain valid sinks.
- **Knowledge:** new ink recipes, Affix understanding, and Living Atlas entries
  increase the player's control even when damage does not rise.

The return debrief is a short hierarchy: **what was found → what rose → what
opened**. It must not become a multi-screen reward ceremony.

### Phase 3 — Chart depth

Add run depth by extending the Chart contract rather than by stacking unrelated
metagame systems.

- A future Chart may declare `depth`/layers in addition to tier and scope.
- A completed layer offers a legible choice: return safely or press deeper.
- Pressing deeper adds an Omen, tightens a resource constraint, or exposes a
  rarer room family; it never silently changes the committed tier.
- Affixes remain constant for the Chart unless the deeper-choice UI explicitly
  shows the added Omen.
- The far Waystone remains the completion language. An entry-side abandon
  route remains available with no completion XP.

This phase is informed by FATE's descending-dungeon commitment, re-expressed
as authored Chart depth rather than an endless generic floor counter.

### Phase 4 — Biome packages

A biome is only complete when it changes play, discovery, and art together.
Every new or deepened biome ships as one package:

1. Modular room kit and palette/lighting contract.
2. Room grammar or traversal signature.
3. Native GatherNode/resource opportunity.
4. Enemy family plus one signature combat role.
5. Wayside encounter, shrine, or strange merchant.
6. Hidden-room or clue pattern.
7. One miniboss/boss relationship.
8. Two or three biome-specific Affix effects or presentations.
9. Ambient audio/VFX identity.
10. A return reason after the first clear.

The existing scopes (`snug`, `hollow`, `briar_maze`, `mire`, `summit`) and
biome registry are the starting set. A new biome must not be approved as only a
palette and prop swap.

## 3D asset contract

### Authoring choice

- **Blender MCP default:** modular architecture, static props, gather nodes,
  weapons, collision meshes, kit variants, LOD/optimization, and GLB cleanup.
- **Meshy selective:** organic creatures, bosses, or complex character bases
  where generation/rigging saves material time.
- Every Meshy result passes through Blender for silhouette review, scale and
  origin normalization, material cleanup, animation naming, collision, and GLB
  validation before entering `models/`.

### Readability rules

- The primary silhouette must read at the shipped FATE-style camera distance.
- One asset owns one dominant shape; tertiary detail may not carry gameplay
  meaning.
- Interactive props need a distinct height/value break from decorative peers.
- Materials must survive Godot's Compatibility renderer: matte by default,
  intentional emission only, no accidental metallic/chrome response.
- The asset must be judged in its real room and lighting, not only in a turntable.

### Technical delivery

- Naming: `biome_<biome>_<kind>_vN.glb` for biome props; existing entity naming
  remains unchanged.
- Grounded origin, documented forward axis, normalized real-world scale.
- Reuse the `GlbFit` normalization/outline/unmetal path where applicable.
- Static kits share materials/atlases when the visual result permits it.
- Rigged assets ship with a named animation contract and a static fallback.
- Each asset records source (`Blender MCP` or `Meshy`), generation prompt or
  build script, cleanup performed, and license/provenance in its delivery note.
- Every new asset is tested in native Forward+ and the Web Compatibility build.

Numeric triangle, texture, and download budgets are deliberately deferred until
Phase 0 measures the current web package. The first budget must be evidence-led.

## NPC and conversation readability

- Interacting turns/faces the NPC toward the player when navigation permits.
- The active talk target has one restrained world-space read: name/prompt plus
  the existing interaction affordance, not stacked markers.
- Dialog opens with a recognizable portrait, speaker name, and short page.
- Painted portrait delivery takes priority over facial rigging for the first
  chapter; the existing portrait well retains its silhouette fallback.
- NPCs react to player state (first return, first Affix, second clue) so they
  feel like residents rather than menu launchers.

## Files

The exact implementation may narrow this list, but work is expected to center
on these seams.

| Path | Action |
|---|---|
| `wyrd/export_presets.cfg` | repair Web resource selection |
| `wyrd/scripts/main_menu.gd` | browser entry/input affordances if required |
| `wyrd/scripts/game.gd` | tutorial/story flags and return state |
| `wyrd/scripts/save_game.gd` | persist new observed-clue state |
| `wyrd/scripts/wayfinder_npc.gd` | first/second-return reactive dialog |
| `wyrd/scripts/layout_loader.gd` | clue/setpiece placement and later depth |
| `wyrd/scripts/dungeon_gen.gd` | optional-room guarantee and later layers |
| `wyrd/scripts/player_hud.gd` | concise objective/debrief readability |
| `wyrd/scripts/ui/dialog_panel.gd` | portrait/readability delivery |
| `wyrd/data/charts.gd` | Chart/depth data contract when Phase 3 begins |
| `wyrd/tests` / `wyrd/test_*.gd` | fresh-save, two-Chart, and web smoke coverage |
| `models/` | contracted biome/character GLBs only |

## Acceptance criteria

1. A fresh save can complete Town → Snug → Town → Tier 1 Hollow → Town with no
   dev command, console, or unstated knowledge.
2. A first-time player can state after Snug how to gather, fight, finish a
   Chart, and return home.
3. Before entering Tier 1 Hollow, the player sees its den band and can explain
   that an ink biases the Chart rather than guaranteeing a good twin.
4. The first and second Second Hand clues are guaranteed in the first chapter,
   occur in different presentation contexts, and persist as observed.
5. Mara has distinct concise dialog after each clue; no answer to the mystery
   is revealed in this chapter.
6. The first completion visibly reports XP and finds; the second also reports
   at least one newly opened choice.
7. Combat kills award no Wayfinding XP; the cozy spine remains the power engine.
8. The Web export boots `Main.tscn`, New Game reaches Town, and a Snug run can
   return to Town in a Chromium browser without script/resource errors.
9. Browser persistence failure is detectable and does not crash or falsely
   claim a durable save.
10. The native six-suite gate stays green.
11. Any new biome or 3D asset delivered under this spec has a completed asset
    contract and passes native plus Compatibility-renderer visual QA.
12. A fresh-player observation test records time-to-first-Chart, time-to-second-
    Chart, confusion points, and the player's answer to “what do you want to do
    next?”

## Sequencing

1. Phase 0 Web export boot and measurement.
2. Fresh-save recording of the current two-Chart tutorial; log friction without
   changing it mid-run.
3. First clue + first-return debrief.
4. Tier 1 Affix teaching + optional discovery.
5. Second clue + Mara reaction + opened-choice summary.
6. Conversation portrait/readability pass.
7. One complete biome-package expansion.
8. Chart Depth prototype after the first chapter is playtest-green.

## Open decisions

- **Second Hand identity:** intentionally unresolved. Do not choose an answer
  until at least one fresh-player test shows the hook creates curiosity.
- **First optional-room reward:** prefer knowledge or a sidegrade over raw
  damage so the main route remains sufficient.
- **Web host:** GitHub Pages serves the optimized milestone build at `/play`.
  Revisit object storage + CDN only if a later PCK exceeds GitHub's file limit
  or the release needs stronger cache/header controls.
- **Browser multiplayer:** explicitly deferred. Revisit only after single-player
  web parity and decide between WebSocket client/server and WebRTC.

## References

- `CONTEXT.md`
- `docs/WORLD_BIBLE.md`
- `docs/adr/0003-cozy-skilling-spine.md`
- `docs/adr/0012-one-skill-wayfinding.md`
- `docs/adr/0013-vertical-progression.md`
- `docs/adr/0014-player-systems-formal-model.md`
- `docs/system-plans/system-npc-story-tutorial.md`
- `docs/system-plans/system-chart-affixes.md`
- `docs/system-plans/system-dungeon-generation.md`
- `docs/specs/48-biomes-notes.md`
- `wyrd/data/charts.gd`
- `wyrd/scripts/glb_fit.gd`

## Done check

- [x] Live title/Town game boots from the Web export.
- [ ] Fresh player completes both introductory Charts unaided.
- [x] Both clues land and persist without revealing their answer.
- [x] Returns communicate finds, growth, and the next opened choice.
- [x] NPC interaction/dialog is readable at shipped camera and UI scale.
- [x] First biome package satisfies the gameplay + art contract.
- [x] Native and browser smoke gates are green.
- [ ] Fresh-player observation notes exist and inform the next revision.
