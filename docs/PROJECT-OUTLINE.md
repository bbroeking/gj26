# Wayfinder project outline

Reconciled 2026-08-27 for `0.1.25-wayfinder-unified` on
`codex/wayfinder-unified`.

This is the concise map of what the project is, how its parts fit together,
what is playable, and what remains. Detailed design contracts stay in
`docs/specs/`, durable decisions stay in `docs/adr/`, and the root
`CONTEXT.md` owns the ubiquitous language. When a status claim disagrees with
the game, the game and its passing acceptance gates win.

## 1. Product thesis

Wayfinder is a single-player cozy fairytale ARPG set in Bramblewood. Cozy
skilling is the spine; responsive real-time combat is one verb among many.
The differentiator is Wayfinding: the player physically inscribes Charts whose
components select a destination and route shape while inks and Affixes shape
the conditions of the journey.

The complete loop is:

```text
meet a Neighbor
  → gather through a Trade
  → craft tools, gear, brews, inks, and Chart components
  → discover and arrange a Chart Recipe
  → inscribe a Chart
  → enter through the Waystone
  → delve a seeded procedural Hollow
  → return with materials, clues, mastery, and trophies
  → settle a Boss Chart
  → restore the Living Atlas and village
  → open the next Road
  → master all four Trades and forge Wayweaver
```

The current product is deliberately single-player. Historical co-op code may
remain behind internal authority seams, but it is not a player-facing mode or
a release requirement.

## 2. One domain, five connected areas

These are areas of one Wayfinder domain, not independent bounded contexts.
Each exists to serve the same home → Road → home loop.

| Area | Owns | Feeds |
|---|---|---|
| Wayfinding | Chart Recipes, components, inks, Affixes, Chart Table, Waystones | Every Delve and Chapter |
| Trades and making | Wayfinding, Earthcraft, Wildcraft, Huntcraft; gathering, crafting, Gear, economy | Preparation and level gates |
| Bramblewood and campaign | Neighbors, Chapters, clues, Boss Charts, Root Runes, Living Atlas, restored buildings | New Roads and permanent meaning |
| Delves and encounters | Seeded Hollows, rooms, creatures, elites, bosses, Skills, rewards | Materials, clues, mastery, trophies |
| Presentation and delivery | FATE camera, movement feel, HUD, UI kit, audio, models, native and Web builds | Legibility and release confidence |

The root `CONTEXT.md` is the single glossary. A `CONTEXT-MAP.md` is neither
needed nor desired while these areas change together and share one player
progression record.

## 3. Playable progression

All four Trades run independently from level 1 through 23:

- **Wayfinding** — Charts, discoveries, clues, Affixes, and Atlas restoration.
- **Earthcraft** — mining, refining, smithing, tools, Gear, and charms.
- **Wildcraft** — foraging, woodcutting, cooking, brewing, inks, and field
  preparation.
- **Huntcraft** — encounters, elites, bosses, and combat-Skill onboarding.

The player begins with Basic Shot and gradually earns the three configurable
hotbar actions. Vigor is survival; Focus pays for deeper Skills. The Pack holds
Gear while the Satchel holds stackable making goods.

### Campaign ladder

| Band | Road / Chapter | Current state |
|---|---|---|
| Arrival, 1–3 | First Road onboarding | Shipped and publicly playable |
| 4–8 | The First Knot / Hedgemother | Shipped |
| 9–12 | The Golden Wallow / Burrow Boar | Shipped |
| 13–16 | The Seventh Road / Wolf Alpha | Shipped |
| 17 | Queen's Summit / Hedgemother Queen | Shipped |
| 18–19 | The Pale Oath / Barrow Jarl | Shipped |
| 20–21 | Fire in the Bough / Hearth Giant | Implemented; strict native and Web D7 acceptance recorded |
| 22–23 | The Unwritten Road / Knot-Eater / Wayweaver | Core story, encounter, naming, mastery, Rune, and legendary systems are implemented and native-accepted; a dedicated D8 Web marathon and final boss art are still open |

The Knot-Eater currently uses a bounded Barrow Jarl placeholder model. That is
the clearest remaining content-completeness gap in the final Chapter.

## 4. Runtime shape

```text
Main.tscn / main_menu.gd
  └─ starts or resumes the journey
     └─ Town.tscn / town.gd
        ├─ Neighbors and physical Trade stations
        ├─ Chart Table and Waystone
        ├─ Living Atlas, Trophy Hall, and restored buildings
        └─ Player + HUD
           └─ World.tscn / layout_loader.gd
              ├─ dungeon_gen.gd chooses the seeded room graph
              ├─ Chart data supplies biome, topology, Affixes, and story contract
              ├─ combatant.gd, boss scripts, and Skill scripts run encounters
              └─ exit Waystones settle return, rewards, and campaign progress
```

Cross-scene state lives in the `Game` autoload: Trades, Satchel, Charts, Gear,
campaign, tutorial, gold, settings-facing signals, and save/load behavior.
`Checkpoint`, `MapLoading`, `Settings`, `Cursor`, `Sfx`, and `Hitstop` own
narrow runtime services. `NetGame` remains an internal historical seam and
must not drive new product behavior.

### Main module map

| Module | Responsibility |
|---|---|
| `wyrd/scripts/game.gd` | Durable player and campaign state plus cross-scene application services |
| `wyrd/data/charts.gd` | Chart templates, components, recipes, discoveries, clues, and materialization rules |
| `wyrd/data/campaign.gd` | Seven-Chapter state machine, escrow, settlement, Root Runes, and final Road prerequisites |
| `wyrd/data/progression.gd` | Four-Trade level ladder and unlock contract |
| `wyrd/scripts/town.gd` | Bramblewood hub composition and restoration projections |
| `wyrd/scripts/layout_loader.gd` | Production realization of a Chart as a Hollow |
| `wyrd/scripts/dungeon_gen.gd` | Seeded room graph and typed-room selection |
| `wyrd/scripts/player_controller.gd` | Movement, aiming, rolling, animation, Gear presentation, interaction, and Skill dispatch |
| `wyrd/scripts/combatant.gd` and boss scripts | Damage, status, creature, elite, and named-encounter behavior |
| `wyrd/scripts/ui/` | Chart Table, crafting, Pack, Codex, HUD, menus, and the shared UI language |
| `wyrd/scripts/save_game.gd` | Versioned persistence and migration boundary |

## 5. Data and content shape

Gameplay definitions live under `wyrd/data/` rather than being spread through
scenes. Charts, campaign, progression, gathering, crafting, items, economy,
drops, Affixes, elites, enchantments, and creature records each have a focused
data module. Scenes provide stable runtime anchors; scripts materialize data
into behavior and presentation.

The production asset root is `models/`, reached in Godot through the
`wyrd/models` symlink. Production GLBs and their import metadata are versioned.
Raw Meshy downloads stay in ignored `models/meshy_staging/`; selected concept
art, delivery receipts, Blender sources, and processing scripts preserve the
authoring trail without turning raw generator output into release source.

## 6. Presentation direction

- Continuous FATE-style camera with camera-aware wall and foliage cutaways.
- Chunky, warm, low-poly storybook forms rather than grim ARPG realism.
- Wayfinder UI Kit: carved wood, cream paper, green accents, high-contrast body
  text, and restrained ornament.
- One semantic cursor, four-slot Skill tray, Vigor and Focus gauges, and a
  compact next-step objective.
- Neighbor motion is restrained and readable at the play camera rather than a
  schedule simulation.

The `0.1.25` asset pass replaces the old player body and bow presentation with
the Wayfinder v2 rig, an authored left-palm socket and grip shape, a compact
shortbow, casual-walk sidecars for the player/Mara/Hod/Quill, smoother turning,
and a quieter HUD/cursor treatment.

## 7. Source and branch topology

`codex/wayfinder-unified` is the single emerging source branch.

- `main` is an ancestor, 122 commits behind the pre-consolidation source tip.
- `feat/system-buildout` is also an ancestor, 40 commits behind that tip.
- `codex/wayfinder-director` supplied the latest committed source checkpoint.
- `gh-pages` stays separate because it is generated deployment output, not a
  competing source branch or domain.

The latest public deployment remains `0.1.24`. This unified source is versioned
`0.1.25-wayfinder-unified` and should become public only after its checkpoint
commit is pushed and the desired release route is published.

## 8. Bring-up and verification

The project-matched runtime is Godot 4.6.2. Use:

```bash
wyrd/tools/godot.sh --path wyrd
wyrd/tools/test_checkpoint_gate.sh
cd wyrd && tools/web_smoke.sh
```

`wyrd/tools/godot.sh` prefers `WYRD_GODOT_BIN`, then the side-by-side macOS
4.6.2 app, then `godot` on `PATH`.

Reconciled `0.1.25` evidence:

- Native Metal/Forward+ boot reached the real Town and captured the production
  Wayfinder, shortbow, Neighbor motion, objective, and HUD.
- All 23 canonical checkpoint entrypoints pass: 1,082 assertions/contracts.
- Modified Wayweaver runtime and modal/icon focused tests also pass.
- The release Web export loads all 118 audited D6–D8 resources.
- The PCK is 118,023,608 bytes; the WebAssembly runtime is about 36 MiB.
- Chrome completes `title → town → world → complete` with the smoke harness in
  `passed` state and no game-console warning, error, assertion, or exception.

The longer D8 title-to-Wayweaver browser marathon does not yet have a dedicated
query-gated harness. The compact release route proves packaging and the common
journey, not the entire final campaign.

## 9. Known debt and contradictions

1. **Final release proof:** add and pass the dedicated D8 browser route from a
   fresh save through the Knot-Eater settlement and Wayweaver forge.
2. **Final encounter art:** replace the Knot-Eater placeholder and complete its
   visual/animation gate.
3. **Godot shutdown diagnostics:** several otherwise passing headless tests and
   native capture runs report ObjectDB/resource leaks, especially under 4.7.1.
4. **Status-document drift:** the old KB Current State and parts of the long
   roadmap retain superseded level-17, co-op, four-suite, or publication text.
   This outline and `docs/test-manifest.md` are the current concise view.
5. **Web size:** the 118 MB PCK is functional but remains the delivery
   bottleneck.
6. **Dormant networking:** `NetGame` remains loaded for compatibility even
   though the supported product is single-player; remove it only through a
   tested authority simplification.
7. **Completion quality:** accessibility, localization-safe strings, final
   performance work, deeper playtesting, and final visual/audio polish remain
   before a finished-game claim.

## 10. Recommended sequence

1. Land this unified source checkpoint with its production assets and authoring
   receipts.
2. Push the unified branch and choose whether it will replace `main` through a
   fast-forward or pull request.
3. Add the strict D8 Web harness and certify a fresh title-to-Wayweaver journey.
4. Replace Knot-Eater placeholder art and repeat native, PCK, and browser gates.
5. Publish `0.1.25`, then update or retire stale roadmap/KB status prose.
6. Move into completion quality: playtest balance, accessibility, startup size,
   remaining UI/art one-offs, and release packaging.
