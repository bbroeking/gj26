---
type: overview
tags: [history, timeline, pivot, three-js, godot, specs]
status: draft
updated: 2026-06-13
sources: ["docs/wyrd-roadmap.md", "docs/wyrd-slice.md", "docs/wyrd-implementation-notes.md", "docs/specs/README.md", "docs/specs/07-godot-evaluation.md", "docs/specs/06-crypt-aftermath.md"]
---

# Development History

Wayfinder (working name "gj26", then "Wyrd") is a cozy fairytale dungeon-crawler whose development arc moved from a **three.js browser prototype** through a formal **Godot evaluation** to a full **Godot 4.6 rewrite**, with the prototype removed from the working tree on 2026-06-12 (recoverable from git history). The spec numbering 01–46 provides the clearest timeline skeleton.

---

## Phase 0 — Pre-spec: three.js prototype (before spec 01)

The project started as a browser game built in three.js (`src/`, `index.html`). By the time the spec system began, the prototype had a working dungeon procgen (`src/scene/dungeon.js`), a tile-step / swing-cooldown combat model, 28-slot Tetris inventory, loot tables, affix system (mineral_vein, bramble_bloom, hedgemother_den…), town↔dungeon transitions, orbit camera with screen shake, and 90+ GLBs in `models/` via the Meshy AI pipeline.

The `docs/specs/README.md` opening line: "The dungeon system is ~90% built already." The specs began not at zero but at a late polish and content-extension phase on top of an existing engine.

---

## Phase 1 — Crypt assets and the three.js content arc (specs 01–06)

Specs 01–06 were **three.js specs**, all targeting `src/`:

| Spec | Title | Outcome |
|---|---|---|
| 01 | Crypt assets | 16 cleaned crypt-tile GLBs in `models/`, 3 floor PNGs |
| 02 | Crypt scope wiring | `'crypt'` registered scope; `buildDungeonGroup` renders niji GLBs |
| 03 | Multi-floor descent | Procgen staircases; variable-floor crypt arc with depth HUD |
| 04 | Crypt enemies | Skeleton, rat, ghost, hedge-sprite GLBs; spawn-table entries |
| 05 | Hedgemother boss | Hedgemother GLB; 3-phase fight on the final floor |
| 06 | Crypt aftermath | Village reacts to `cryptCleared`: Cook gifts deep chart, NPC gossip, Withering follow-up |

The GLB pipeline — Meshy AI → `clean_ai_mesh.py` → `models/*.glb` — was established in this phase and carries forward unchanged into Godot.

---

## Phase 2 — Godot evaluation and the engine pivot (spec 07)

**Spec 07: "Godot evaluation: render the crypt dungeon natively"** (2026-05-xx, formalized decision ~2026-05-20 per project memory).

Goal: hands-on comparison of Godot 4.6 vs three.js on a working artifact, not on vibes. Outcome: `godot/` project bootstrapped with the same crypt layout (loaded from a JSON snapshot of `dungeon.layout`), the same GLBs via symlink, and a working camera — without porting any game logic. Both engines kept running simultaneously.

The decision that followed: **Godot, not three.js** (project memory: `project_godot_evaluation.md`, "DECIDED 2026-05-20"). The three.js `src/` became the design prototype; Godot became the implementation target. The "no decision yet" framing retired.

`docs/specs/07-godot-evaluation.md` is explicit: "This spec is evaluation, not migration."

---

## Phase 3 — Godot evaluation combat arc (specs 08–26)

Specs 08–26 were **Godot evaluation specs** targeting `godot/`, exploring camera, physics, animation, enemy AI, combat feel, and dungeon readability in the new engine. Key landmarks:

| Spec range | Theme |
|---|---|
| 08–09 | Quality procgen + FATE camera in Godot |
| 10–11 | Physics, animation foundations |
| 13–14 | Ranger bow + arrows; fluid combat |
| 15–17 | Enemy AI, HP; Hedgemother boss fight in Godot |
| 18–19 | Ranger walk animation; enemy pathfinding (navmesh) |
| 20–22 | GLB textures, rat rigging, playtest feel tuning |
| 23–26 | Fluid movement sandbox, dungeon readability, dungeon placement polish, combat juice |

Spec 22 (playtest feel tuning) corresponds to the combat playtest checklist in `docs/PLAYTEST.md` — 21 dimensions rated and one-pass tuned.

---

## Phase 4 — Item system (spec 27, seven sub-specs)

Spec 27 (a–f) built the full item system in Godot: item data registry, ground pickups, inventory UI (Tetris grid), equipment with stat bonuses, stats system, polish. Seven sub-specs spanning 27–27f. `docs/specs/27-item-system.md`

---

## Phase 5 — Dungeon polish and typed rooms (specs 28–29)

- Spec 28: dungeon placement polish
- Spec 29: typed room contracts (vault, shrine, hearthroom, bossroom)

---

## Phase 6 — Skills, AoE, and the hotbar (specs 30–32, 32a–d, 33a)

The 4-skill hotbar (1–4 + F), status effects, AoE abilities, pack scaling, and the pickup/interactable base class. Specs 30–33a built the combat system's depth layer. test_skills.gd was introduced here; its absence later caused the frozen-hotbar regression that shipped.

| Spec | Outcome |
|---|---|
| 30 | Skills and cooldowns |
| 31 | Status effects and AoE |
| 32 | Pack scaling |
| 32a | Pickup deepening |
| 32b | Skill module |
| 32c | Hit feedback |
| 32d | Interactable base |
| 33a | Player status |

---

## Phase 7 — UI redesign (specs 35, 38–41)

- Spec 35: HUD upscale
- Spec 38: Tools, mute, HP/Focus globes UI (the carved wood globes + skill tray, PoE layout)
- Spec 39: Panel redesign — the Wayfinder UI Kit introduced (Claude Design project `wayfinder-ui`); carved wood nine-patch frames, kit chips/buttons/troughs
- Spec 40: UI-from-design implementation
- Spec 41: UI cohesion pass

Specs 39–40 established the "design-then-implement" workflow: Claude Design produces Midjourney reference images → measure/crop → implement in GDScript drawn-UI. `docs/wyrd-ui-design-pass.md`

---

## Phase 8 — The Godot rewrite "Wyrd" and the chart loop (forked 2026-06-09)

The evaluation `godot/` project was forked into `wyrd/` on 2026-06-09, renamed "Wayfinder" 2026-06-10. This is the canonical Godot game. `docs/wyrd-slice.md`, `docs/wyrd-implementation-notes.md`

The wyrd-slice loop: town → forage → mix ink → inscribe chart → parameterized dungeon → exit waystone → Wayfinding XP → deeper templates. Seven tutorial steps tracked in `Game.tutorial_step`. Core systems built in this phase:

- `Game` autoload (`scripts/game.gd`): trades/satchel/charts/gold/tutorial/save
- `DungeonGen.generate(seed, cfg)` — cfg from the chart
- `layout_loader.gd` — reads `Game.active_chart`, spawns GatherNodes, applies affixes
- Chart templates: Snug, Tier 1, Hollow, Briar Maze
- Inks: Hedge, Stoneground, Refined (v1 — 3 of eventual 9)
- Affixes: 7 of 16 designed, only implemented ones rolled (no false UI promises)
- Tutorial: 7 steps, Mara Linnet as guide
- Tests: test_wyrd_loop.gd (38 checks), test_wyrd_dungeon_scene.gd (5), test_wyrd_transitions.gd (26)

Adversarial review same day fixed ~19 issues including: dying to Hedgemother sealing the run, dead-input gate ordering, toast buffer across scene changes, Snug charging for inks it can't use, `Game.skills` colliding with blessed "Skill" term (renamed to `trades`). `docs/wyrd-implementation-notes.md §Adversarial review round`

---

## Phase 9 — Economy, endgame chain, and town environment (Session 3, 2026-06-10)

- Gold economy: `Game.gold`, `data/economy.gd`, Hod Tenter vendor
- Trophy chain: elites → Hedgemother → Boar → Wolf → Chart of the Summit (endgame)
- Boss dens removed from random pool; guaranteed by trophy slot
- `summit_cleared` flag, Mara epilogue
- Town environment pass: noise ground shader, dirt-path web, 34+14 treeline, ~700 MultiMesh grass tufts, 4 new Meshy props
- Suites: 60 + 5 + 28 checks green

---

## Phase 10 — Chart crafting UI (spec 42)

Shipped 2026-06-12. The Crafting Bench (placement sockets, live odds preview, on-bench mixing pot, guided-tutorial highlights) replaced the menu panel. 151 checks green. `docs/specs/42-chart-crafting-ui.md`

---

## Phase 11 — Loadout / skill expansion (spec B5 wave 1 + wave 2)

Shipped 2026-06-12. Skill pool grew from 5 to 9: PiercingBolt, RainOfThorns (wave 1); Thornburst, Hunter's Mark, Heartwood Ward, Mercy Shot (wave 2). Loadout panel for dungeon Hearth rest + Cottage Hearth button. Persisted in save. Huntcraft gates deeper skills (levels 4/7/9). `docs/wyrd-roadmap.md`

---

## Phase 12 — Node tiers and tool tiers (spec A6)

Shipped 2026-06-12. Ore ladder: copper (E1) → bogiron (E3) → palechalk (E7, tier-2+ charts only). Locked veins visible naming their level. Cinderbloom tools at E7. `docs/wyrd-roadmap.md`

---

## Phase 13 — Affixes wave 1 + wave 2 (spec B6)

Shipped 2026-06-12. 15 rollable affixes total (9/9). Wave 1: Sprinting Things, Gilded Hollow, Bursting. Wave 2: Quiver/Damp Strings, Fog of Hedge/Blinding Fog, Frenzied/Seething, Wellspring/Barren Veins, Echoing Steps/Hollow Echo, Marked Quarry/Skittish Prey. `docs/wyrd-roadmap.md`

---

## Phase 14 — Huntcraft trade (spec B7, ADR 0005)

Shipped 2026-06-12. One combat trade: Huntcraft. Kills award `max(2, hp_max/3)` XP. Perks: Steady Hands (5, +5% crit), Hunter's Stride (10, +5% move). Fourth Trades-page row. `docs/adr/` ADR 0005.

---

## Phase 15 — Full smithing and alchemy (specs A7, A8)

Shipped 2026-06-12. Forge: 14 recipes (Shortbow E1 → Palechalk Longbow E9). Economy-gated: no smithed item sells for more than its Hod-buyable inputs. Quill (Herbalist NPC): 2 buff brews, timed-buff engine on Game. `docs/wyrd-roadmap.md`

---

## Phase 16 — Recipe discovery (spec 43)

Shipped 2026-06-12. Ink recipes are found, not given. Fresh saves know only Hedge Ink. "Try the Mix" discovery mechanic (+50 carto on hit, consolation on miss). Bench codex strip with NPC riddles. 2 new discoverable inks (Ash, Chalkwash). `docs/specs/43-recipe-discovery.md`

---

## Phase 17 — Trade ladders to the demo cap (specs 45-*)

Shipped 2026-06-12. Demo level cap: 17 (ADR 0006). Wildcraft: 6 herb tiers, heal ladder 35→220, 3 buff brews, perks 13/17. Earthcraft: Starsilver E11, Hedgesteel E15, 10 forge recipes to E17 Warbow, perks 13/17. Huntcraft: Quick Nock 12, Heavy Draw 14, Even Breath 17. Wayfinding: 6 perks 2→17 including Master Wayfinder's +1 ink slot. 3 new discoverable inks (Mothglow, Foxglove, Gildleaf). `docs/specs/45-trade-ladders-*.md`

---

## Phase 18 — End-to-end gap pass

Shipped 2026-06-12. Frozen-hotbar crash fixed (cooldown keys re-seeded; test_skills revived → 4th gate suite). Trades/Satchel/Charts pages scroll. Abandon stone at every dungeon entry. Foxglove/stonebreak obtainable. Capstone gear out of drop pool. Skill bar carries glyphs/tooltips for all 9 skills. Vendor/waystone lists scroll. Hod's hint corrected. 333 headless checks across 4 suites all green. `docs/wyrd-roadmap.md`

---

## Phase 19 — Multiplayer co-op (spec 46)

Shipped 2026-06-12. Phase A (town together): NetGame autoload, ENet host-auth, 12 Hz transform sync, name tags, The Lantern menu. Phase B (dungeon co-op): host sockets the party, deterministic `NetFoe` names, 10 Hz enemy snapshots, guest cast replay, per-player loot rolls, party-wipe boss resets. Two-process headless loopback smoke test green. Phase C polish queue open (arrows visible to guests, boss telegraphs on guests, reconnect grace). `docs/specs/46-multiplayer-coop.md`

---

## Three.js prototype removal — 2026-06-12

On 2026-06-12 the three.js prototype (`src/`, `index.html`, `godot/`) was removed from the working tree. `docs/wyrd-roadmap.md`: "Repo note: the three.js prototype was removed 2026-06-12 (recoverable from git history)." Its surviving value — item/recipe/skill data, design docs — was ported into `wyrd/data/` and `docs/`.

---

## Spec count summary

| Range | Phase | Engine |
|---|---|---|
| 01–06 | Crypt assets + content arc | three.js |
| 07 | Godot evaluation | bridge |
| 08–33a | Camera, combat, items, skills, AoE, polish | Godot (`godot/`) |
| 35, 38–41 | UI redesign / Wayfinder UI Kit | Godot (`godot/`) |
| 42–46 | Chart crafting, loadouts, tiers, affixes, trades, multiplayer | Godot (`wyrd/`) |

---

## Key turning points

1. **Spec 07 (Godot evaluation)** — the decision that forked the engine path.
2. **ADR 0003 (cozy-skilling spine, 2026-05-29)** — locked identity: skilling is the heart, combat is one verb; ARPG demoted to seasoning.
3. **wyrd/ fork (2026-06-09)** — canonical Godot game born; `godot/` evaluation project frozen.
4. **Wayfinder rename (2026-06-10)** — project name locked.
5. **Session 3 (2026-06-10)** — economy, trophy chain, and endgame; game's loop is fully playable.
6. **2026-06-12 mega-ship** — specs 42–46 + B5/B6/B7/A6/A7/A8/43/45/gap pass all shipped same day; three.js prototype removed; 333 headless checks green.

---

## See also

- [[Overview]] — current feature summary
- [[Current State]] — in-flight work and open items
- [[Chart Loop]] — the core loop born in this history
- [[Design Decisions]] — ADRs that shaped each pivot
- [[Godot Pipeline]] — the engine side of the Godot evaluation
- [[Trades and Leveling]] — the four-trade system built across phases 8–17
- [[Multiplayer Co-op]] — spec 46 history
- [[Crafting]] — chart crafting UI (spec 42)

## Sources

- `docs/wyrd-roadmap.md` — consolidated state, shipped log (2026-06-12)
- `docs/wyrd-slice.md` — wyrd/ fork design doc
- `docs/wyrd-implementation-notes.md` — wyrd/ build record, adversarial review, Session 3
- `docs/specs/README.md` — phase 1 spec order and what was already done
- `docs/specs/06-crypt-aftermath.md` — three.js content arc, NPC reactions
- `docs/specs/07-godot-evaluation.md` — pivot spec, explicit evaluation-not-migration framing
