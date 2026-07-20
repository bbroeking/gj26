# Spec 55 — Playable First Chapter — implementation notes

Running decisions, deviations, measurements, and surprises for
`55-playable-first-chapter.md`.

## 2026-07-16 — kickoff

### Decisions

- Web persistence is treated as a player-visible capability, not an implicit
  promise. The Game autoload checks for IndexedDB, turns any failed save into
  the same unavailable state, and the title screen hides Continue while
  explaining that the visit is session-only.

- The north-star milestone is one fresh 25–35 minute session through two
  complete Chart loops, not a broad content expansion.
- The existing `Snug` and `Tier 1 Hollow` templates are the two introductory
  runs. We do not create substitute tutorial-only Chart types.
- The opening mystery is provisionally **the Second Hand**: marginalia appears
  inside a newly inscribed Chart in the player's own ink. Its identity remains
  unresolved through this spec.
- Browser delivery starts single-player. The current ENet/UPnP co-op transport
  is native-only and is not allowed to block the first Web release.
- Blender MCP is the default for modular/static assets; Meshy is reserved for
  high-cost organic or rigged bases. Meshy output is never drop-in production
  art—it must pass through Blender cleanup and Godot QA.
- Web asset budgets will be based on measured package composition, not guessed
  triangle/texture numbers.

### Current-state findings

- `Main.tscn` is the live title-screen entry and routes into `Town.tscn`.
- The existing Web preset still exports only `World.tscn` plus an old manual
  allowlist. A release package is produced, but the browser fails because the
  live main scene and required class/data resources are absent.
- Baseline stale-preset export measured approximately 36 MB `.wasm` and 24 MB
  `.pck` before server compression. This is not a representative full-game
  package because Town and most current runtime assets are missing.
- Godot 4.6.2 Web templates are installed locally, including the preferred
  no-threads release template.
- The code already contains Compatibility-renderer cleanup for Meshy metallic
  materials (`GlbFit.unmetal`, `layout_loader._unmetal`).
- The project contains 234 top-level GLBs (~787 MB raw); only about 88 GLBs
  (~165 MB raw) are referenced by live scripts/scenes. The production export
  must not blindly pack the entire `models/` directory.

### Deviations

- None yet.

### Next implementation step

Replace the dungeon-only Web resource selection with the three live root
scenes plus a maintained runtime allowlist, export to a temporary directory,
and drive the browser through title → New Game → Town while collecting console
errors and package sizes.

## 2026-07-16 — Web baseline repair

### Implemented

- Replaced the dungeon-only export root with `Main.tscn`, `Town.tscn`, and
  `World.tscn`.
- Added the live scene/script/data/UI/audio resource families and an explicit
  allowlist of the 88 GLBs referenced by current runtime code.
- Kept the no-threads Web template (`variant/thread_support=false`).
- Added the model-side PNG/JPG/WebP families required by Godot's extracted
  glTF image resources. Although the source files are `.glb`, Godot's imported
  scenes may still refer to images extracted beside the model; excluding those
  images produces white meshes only in the exported build.

### Browser evidence

- Release export succeeds with Godot 4.6.2.
- Chromium loads the Wayfinder title with no warning/error console entries.
- Clicking **New Game** reaches Town, displays the first objective (`Speak with
  Mara Linnet, the Wayfinder`), renders the player and Town assets with their
  textures, and leaves the console clean.
- The earlier curated build without companion model images also reached Town,
  but logged missing texture loaders and rendered affected models white. That
  failure is now fixed in the preset.

The initial browser smoke covered title → New Game → Town. The final
query-gated smoke now continues through a real Snug inscription and the live
`Main → Town → World → Town` transition. On 2026-07-16 Chromium returned to
Town and rendered the **Chart Returned** card with 8 gold, 75 Wayfinding XP,
Wayfinding 2, and the Tier 1 Hollow opening. No script parse failure or missing
resource occurred.

At this checkpoint Godot 4.6.2 still printed its renderer-level `Parameter
"material" is null` diagnostic while releasing a scene. The same two-line
diagnostic reproduced in the native Compatibility transition suite and
predated this spec's Web resource closure. The renderer cleanup section below
records its eventual cause and removal.

### Package measurement

| Artifact | Raw | gzip -9 |
|---|---:|---:|
| `index.wasm` | 37,695,054 B | 9,379,534 B |
| `index.pck` | 256,429,388 B | 255,070,897 B |
| complete output directory | 296 MB | — |

The PCK is already composed largely of compressed model/texture payloads and
therefore gains almost nothing from HTTP gzip. The 88 referenced source GLBs
total about 165 MB; top contributors include the rigged Hedgemother (15.3 MB),
rigged Hedge Sprite (10.4 MB), ranger animation models (~9.3 MB each), and
rigged Skeleton (9.0 MB). Model-side extracted images add about 146.6 MB of
source payload across the directory.

This is technically hostable as a static Godot Web export, but it is not yet a
good public first-load. The next Web task is an asset manifest/import pass:
remove duplicate animation textures, downsize/convert oversized extracted
images, and split first-chapter-required assets from later biome/content
packages before choosing a public download budget and deployment target.

### First public-download budget and host choice

The measured package establishes this provisional release gate:

| Budget | Gate |
|---|---:|
| gzip WebAssembly | ≤ 10 MiB |
| first-load PCK | ≤ 128 MiB |
| total first navigation | ≤ 150 MiB |
| one source GLB | ≤ 16 MiB |

The WebAssembly already passes; the PCK and first navigation do not. The first
optimization target is therefore the resource pack, not the engine binary or
HTTP compression. The 128 MiB PCK gate requires roughly halving the current
pack by moving non-chapter models out of the boot manifest and consolidating
duplicate rig/animation texture payloads.

At the 256 MB baseline, static publishing required object storage plus a CDN:
Cloudflare Pages/Workers static assets have a 25 MiB per-file cap, and GitHub's
normal repository path enforces 100 MB per object. The optimization pass below
changes that decision by bringing the PCK below GitHub's hard object limit.

### Regression gate

All six native suites remain green:

- `test_wyrd_loop.gd`: 268 passed
- `test_wyrd_dungeon_scene.gd`: 25 passed
- `test_wyrd_transitions.gd`: 59 passed
- `test_skills.gd`: 33 passed
- `test_boot_smoke.gd`: 91 passed
- `test_coop.gd`: 15 passed

Some suites still print pre-existing teardown/deferred-call warnings while
returning zero failures; this Web-preset change did not introduce a test
regression.

## 2026-07-16 — First-chapter state

### Decisions

- Persist observed evidence as two stable ids (`far_waystone` and
  `inked_scrap`) on `Game`, without persisting or choosing an identity for the
  Second Hand. Repeated interactions are idempotent, so the world can remain
  readable without manufacturing duplicate story progress.

### Tradeoffs

- Story state lives beside tutorial state in the cross-scene `Game` save rather
  than in a separate quest subsystem. The chapter needs two observed facts,
  not a generalized quest graph; the public methods keep a future migration
  possible.

### Decisions

- Generate clue placement as `story_clues` layout data. The Snug mark is tied
  to the far-Waystone room; Tier 1 prefers a typed or strange non-entry,
  non-boss room. The interactions stay optional and never enter the objective
  tracker.
- A completed Chart now pays `8 × tier + 4 × Affix count` gold. This makes the
  Chart loop itself a small gold faucet while preserving the rule that combat
  kills award no Trade XP or direct progression.
- Return communication is one card, not three screens: **Found → Rose →
  Opened**. The first card also offers a one-time choice between a Hearth
  Draught and Hedge Ink, so the reward immediately feeds the next run.

### Surprises

- The existing transition test stopped after inscribing Tier 1; it did not
  enter or complete the second Chart. It now drives both real scene roundtrips,
  both clue interactions, both return cards, and Mara's two distinct reactions.

## 2026-07-16 — Chart Depth prototype

### Decisions

- Depth is opt-in on later `Hollow` (two layers) and `Sallow Mire` (three
  layers); the two first-chapter Charts remain single-layer onboarding runs.
- Pressing deeper preserves tier, scope, and resolved Affixes. It changes the
  seed, adds the Omen shown by the far-Waystone choice, and defers the entire
  completion payout until the player returns safely from a later layer.
- Each extra completed layer adds 50 Wayfinding XP and 6 gold. This rewards
  commitment through the cozy completion channel; combat kills still pay no
  Wayfinding XP.

### Tradeoffs

- The prototype uses a short deterministic Omen sequence rather than an Omen
  drafting screen. It proves the Chart contract and legible commitment choice
  without introducing another metagame inventory.

## 2026-07-16 — Web asset import experiment

### Surprises

- The first 1024 px import experiment did not invalidate Godot's generated
  texture cache, so it misleadingly produced a nearly unchanged release. A
  forced reimport later proved the setting works; the final pass combines that
  import limit with a stricter manifest and meshless animation sidecars.

## 2026-07-16 — Web release optimization

### Implemented

- Replaced the four complete walk/run GLBs with Blender-authored, meshless
  animation sidecars. Each sidecar retains the imported armature hierarchy and
  one sampled animation, but contains no mesh, material, texture, or image.
  `wyrd/tools/export_animation_sidecars.py` makes the conversion reproducible
  and validates the exported GLB payload.
- Removed the unused ranger fallback body and later-biome rig-calibration GLBs
  from the Web manifest. The shipped player body is the chibi Wayfinder; her
  walk/run sidecars are 35,052 B and 31,424 B at source.
- Replaced the broad model-image include with the 19 extracted images actually
  referenced by the shipped GLBs. Those images now import at a 1024 px maximum.
- Added `wyrd/tools/audit_pck.gd` and its isolated audit project so package
  composition can be measured without mixing files from the development tree.

### Final package measurement

| Artifact | Raw | gzip -9 | Gate |
|---|---:|---:|---:|
| `index.wasm` | 37,695,054 B | 9,379,534 B | gzip ≤ 10 MiB — pass |
| `index.pck` | 76,172,860 B | 75,769,982 B | raw ≤ 128 MiB — pass |
| complete output directory | 109 MB | — | first navigation ≤ 150 MiB — pass |

The optimized PCK contains 595 virtual files / 76,117,513 virtual bytes. The
audit finds both chibi animation sidecars and no full ranger animation,
calibration rig, cow, or validation asset. Chromium then completed the real
query-gated title → Town → Snug → Town route and rendered the **Chart Returned**
card. No missing resource, GDScript, or JavaScript error appeared. The
Compatibility `material is null` transition diagnostic was still present at
this package checkpoint and was removed in the renderer cleanup below.

A separate normal New Game capture held in Town before any transition. The
1024 px player/prop textures remained present and readable at the shipped
camera, and Chromium reported no console errors in that scene.

The package now clears the release budgets. The initial publish used isolated
deployment commit `4739155` on the `gh-pages` branch; the renderer-clean build
is deployment commit `26ef5e3`. The old root URL redirects to
`https://bbroeking.github.io/gj26/play/`. GitHub accepted the 76 MB PCK (while
warning that it exceeds the recommended 50 MB repository-file size).
Cloudflare Pages' 25 MiB per-file static limit remains too small for the single
pack, so GitHub Pages is the milestone host.

The live CDN URL booted the title and completed the query-gated title → Town →
Snug → Town route. The browser log reached `[web-smoke] complete` with no
missing-resource, script, parse, or JavaScript error.

## 2026-07-16 — Compatibility renderer cleanup

### Surprises

- The null-material diagnostic did not originate in Town/World teardown or a
  missing exported asset. A minimized two-GatherNode repro showed that two
  instances of the same imported GLB were sufficient. Raw and `unmetal`-only
  instances released cleanly; adding the ink rim through a duplicated surface
  material's `next_pass` deterministically failed.

### Decisions

- Inverted-hull ink now uses `GeometryInstance3D.material_overlay`. It preserves
  the imported/painted base material, deforms with skinned meshes, works on
  materialless geometry, and is owned per instance instead of being chained
  through a shared imported mesh's surface material.
- The renderer gate is executable as
  `wyrd/tools/check_transition_render_errors.sh`. It runs the real two-Chart
  transition suite and fails on either a gameplay assertion or the exact
  null-material renderer diagnostic.

### Renderer QA

- The two-node minimal repro is clean for forage, ore, and log-pile GLBs.
- The full native transition suite is clean, and all six native suites remain
  green.
- Native Forward+ Town and browser Compatibility Town retain the ink silhouette
  at shipped camera distance. The local Web title → Town → Snug → Town route
  reaches `[web-smoke] complete` with an empty browser error log.
- GitHub Pages deployment `26ef5e3` completed the same public route with an
  empty browser error log.

## 2026-07-16 — Sallow Mire package completion

### Decisions

- Complete the existing Sallow Mire instead of adding another shallow biome.
  It now owns reed-bed/drowned-root grammar, a guaranteed optional wisp-pool
  shrine, two native Mothmint nodes, a ranged Bog Wisp signature role, three
  Mire-specific presentations of existing Affix mechanics, wet fog/motes/
  reflections, the Burrow Boar den relationship, and three-layer replay depth.
- Reuse the existing Ghost silhouette for the Bog Wisp role. At shipped camera
  distance its brighter green emission-family tint, smaller scale, faster
  projectile, and Mire-only spawn id are more legible than another unrigged
  one-off mesh.

### Deviations

- The seven inherited Meshy props predate the current delivery-note rule. Git
  establishes the source batch and cleanup intent, but not exact Meshy job ids
  or verbatim prompts. `docs/assets/biome-sallow-mire-delivery.md` records
  reconstructed prompt suffixes and flags the missing source records for
  backfill rather than fabricating them.

## 2026-07-16 — Conversation readability

### Decisions

- Mara now turns toward the local player on interaction and supplies a painted
  portrait to the existing speaker-name/short-page dialog layout. The editable
  master is a 512 px transparent PNG at
  `wyrd/assets/ui/portraits/mara_linnet_v1.png`; the shipped texture is the
  opaque deep-teal `mara_linnet_v2.webp`, which avoids Compatibility/Web alpha
  corruption in the portrait well. The silhouette remains the fallback for
  NPCs without delivered art.
- The portrait was generated with the built-in image tool from a storybook
  brief (practical middle-aged cartographer, chestnut braid, moss coat, cream
  shirt, brass compass, rolled Chart), keyed from a flat magenta background,
  despilled, alpha-validated, and reduced to the shipped UI size.

### Renderer QA

- Sallow Mire captured successfully in native Metal Forward+ and native
  OpenGL Compatibility at 1280×720. Forward+ is deliberately darker and foggier;
  Compatibility is brighter, but the wet ground, prop silhouettes, player,
  HUD, and interaction prompt remain readable in both.

## 2026-07-16 — Remaining observational gate

The deterministic two-Chart transition suite proves the entire state machine,
but it cannot stand in for a first-time human. The observer sheet at
`docs/playtests/55-first-chapter-observation.md` is ready and deliberately does
not fabricate completion times or player answers. This is the only unresolved
gate, and it controls both unchecked Done items plus the human portions of
acceptance criteria 1–3 and 12: one fresh participant must play without
coaching, then the notes must name the next revision (including “no revision”
if no repeated friction appears). The requirement-by-requirement evidence is
recorded in `docs/playtests/55-completion-audit.md`.

### Final automated gate

Run after the complete implementation on 2026-07-16:

- `test_wyrd_loop.gd`: 304 passed, 0 failed
- `test_wyrd_dungeon_scene.gd`: 26 passed, 0 failed
- `test_wyrd_transitions.gd`: 80 passed, 0 failed
- `test_skills.gd`: 33 passed, 0 failed
- `test_boot_smoke.gd`: 92 passed, 0 failed (89 scripts)
- `test_coop.gd`: 15 passed, 0 failed
- `tools/check_transition_render_errors.sh`: pass; no null-material renderer
  diagnostics

`git diff --check` is clean.
