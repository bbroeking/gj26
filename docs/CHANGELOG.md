# Changelog

## 0.1.20-readable-objective — 2026-07-23

- Increased the top-left objective card from 320 to 372 pixels and raised its
  objective and guidance type to 18 and 16 pixels.
- Darkened supporting green copy and strengthened the existing wood edge and
  shadow so the card reads immediately against the bright Town world.
- Retuned content-hug height and compass placement for the larger component;
  immediate, 20-second, and 35-second guidance states remain unclipped.
- Preserved the Storybook Corners layout, parchment language, objective copy,
  controls, recovery timing, all other HUD surfaces, and gameplay.
- Promoted the 36-check HUD/Pack contract into the canonical gate and verified
  1,055 assertions, save roundtrip 120/120, all 118 release resources, and
  native plus real-browser 1280×720 frames.
- Published the exact versioned build behind stable `/play/`, verified the
  hosted HUD and complete journey, and updated the owner-only Field Journal to
  version 20.

## 0.1.19-clear-first-step — 2026-07-23

- Put the two controls needed for the opening objective—`WASD` movement and
  `E` talk—directly beneath Mara's objective on the first controllable frame.
- Preserved the existing gentle recovery ladder: Mara's teal worktable at 20
  seconds, then the direct gold-needle destination only after 35 seconds.
- Added no tutorial modal, marker, mode, instruction sequence, content, or
  control change; Mara, the Kind/Bold choice, First Road, combat lesson, and
  return remain unchanged.
- Expanded the First Road acceptance gate to 17 assertions and verified 1,019
  canonical assertions, save roundtrip 120/120, all 118 release resources, and
  matched native and real-browser first-controllable frames.
- Kept the cold-human comprehension gate explicit: rendered automation proves
  delivery and timing, not that first-time players understand unaided.
- Published the exact versioned build behind stable `/play/`, verified the
  hosted opening and complete journey, and updated the owner-only Field Journal
  to version 19.

## 0.1.18-working-edge — 2026-07-23

- Gathered the existing cottage, Chartmaker's tower, and smithy into one
  readable north-yard working edge without adding a landmark or changing the
  accepted Town camera and grade.
- Kept the Atlas, work props, logs, and ore attached to their owning buildings
  while preserving the central crossing and explicit approaches to Mara, the
  Chart table, Waystone, and practice space.
- Added a 12-assertion production-layout contract covering landmark order,
  support ownership, physical clearance, and 1280×720 lower-facade projection.
- Made the save-roundtrip suite fail closed unless `WYRD_NO_SAVE=1` is present,
  preventing an accidental test run from touching a live profile.
- Verified 1,016 canonical assertions, save roundtrip 120/120, all 118 release
  resources, and matched native and real-browser first-arrival play.
- Published the exact versioned build behind stable `/play/`, verified the
  hosted route, and updated the owner-only Field Journal to version 18.

## 0.1.17-gathered-arrival — 2026-07-21

- Gave Town one authored profile on the established FATE camera, pulling the
  first playable view back and framing ahead of the ranger toward Mara.
- Brought Mara, the Waystone, Chart table, and readable north-landmark bases
  into the same 1280×720 arrival frame while leaving every yard object fixed.
- Kept camera-relative framing through orbit and carried it through the first-
  arrival vignette's home frame without removing player zoom or yaw control.
- Verified 1,004 canonical assertions, save roundtrip 120/120, all 118 release
  resources, and the complete exported title → town → chart table → Creature
  Codex → road → return route.
- Published the exact versioned build behind stable `/play/`, verified the
  hosted route, and updated the owner-only Field Journal to version 17.

## 0.1.16-shaded-home — 2026-07-21

- Restored shadow, midtone, and highlight separation to Bramblewood's Town yard
  without changing its geometry, paths, stations, camera, or interactions.
- Kept the correction on Town's cloned 3D Environment so quest parchment,
  Field Journal UI, prompts, and input feedback retain their exact colors.
- Gave Web Compatibility its own bounded brightness value, bringing the pale
  browser yard back toward native play and the approved Arrival concept.
- Verified 996 canonical assertions, all 118 release resources, and the full
  exported title → town → chart table → Creature Codex → road → return route.
- Published the exact versioned build behind stable `/play/`, verified that
  hosted journey, and updated the owner-only Field Journal to version 16.

## 0.1.15-creature-identity — 2026-07-21

- Added a complete Creature Codex to the Pause folio, covering every production
  common and named creature with its Nature, Roads, battle sign, and
  Bramblewood lore.
- Gave every common creature a kind-owned, color-matched ranged opening before
  it resumes its established melee, pursuit, kiting, support, or bruiser role.
- Kept named signatures primary: Hedgemother, Barrow Jarl, and Hearth Giant may
  weave in their colored cast, while Burrow Boar, Wolf Alpha, and Knot-Eater
  remain signature-only.
- Replaced the pale crypt-era chest with an authored Wayfinder chest whose
  visible footprint, prompt, scanner reach, one-shot opening, and two treasure
  rolls agree. Gilded roads now add exactly one bonus chest.
- Expanded the canonical checkpoint gate to 19 suites and 986 assertions and
  the Web export audit to 118 required resources.
- Kept editable UI source sheets in the repository but out of the release PCK,
  bringing the verified Web artifact beneath GitHub Pages' file-size limit.
- Published the exact build behind a stable `/play/` entry and versioned asset
  path, then updated the owner-only Field Journal to checkpoint version 15.

## 0.1.14-readable-passages — 2026-07-21

- Kept procedural Chart graphs, randomized authored room archetypes, corridor
  widths, full wall collision, and the continuous FATE camera unchanged.
- Gave real First Road room connections deterministic low passage shoulders
  instead of the same bulbous living-wall crowns used around ordinary edges.
- Tapered each opening across a five-wide concave frame while retaining dense
  Bramblewood depth beyond the physical boundary and away from connections.
- Kept room landmarks off passage shoulders and preserved the established
  opaque screen-space cutaway as the single camera-obstruction authority.
- Verified 911 canonical assertions, all 112 release resources, and a clean
  exported title → town → generated road → return route.

## 0.1.13-open-larder — 2026-07-21

- Kept procedural Chart graphs, randomized authored room archetypes, the
  continuous FATE camera, natural cutaway walls, and the larder setpiece.
- Reduced the First Road larder's legacy pottery markers to the accepted forest
  support scale after biome remapping made them full-size mossy boulders.
- Omitted only the supports inside protected room approaches while retaining
  their seeded occupancy records, so encounter placement remains deterministic.
- Preserved room connectivity, collision, navigation, encounters, controls,
  rewards, audio, typed interactions, and later-biome setpieces.
- Verified 904 canonical assertions, all 112 release resources, and a clean
  exported title → town → generated road → return route.

## 0.1.12-open-floor — 2026-07-20

- Kept procedural Chart graphs, randomized authored room archetypes, full-size
  forest landmarks, and the continuous FATE camera unchanged.
- Reduced First Road ferns, toadstools, and mossy boulders from landmark scale
  to supporting scale after their source meshes measured roughly two floor
  tiles wide in the rendered game.
- Reserved a three-wide, two-deep landing inside every corridor mouth so
  supporting dressing frames the route instead of forming a barricade.
- Preserved established collision, navigation, combat apertures, typed-room
  focal contracts, encounters, controls, audio, rewards, and later biomes.
- Verified 898 canonical assertions, all 112 release resources, and a clean
  exported title → town → generated road → return route.

## 0.1.11-forest-rooms — 2026-07-20

- Kept procedural Chart graphs, seeded room variation, the continuous FATE
  camera, natural cutaway walls, encounters, rewards, and controls unchanged.
- Gave Lantern Landing, Round Glade, Crooked Bower, and Long Clearing their own
  compact forest composition kits instead of dressing them from crypt-era room
  themes hidden beneath biome remapping.
- Preserved the protected combat aperture and every Chest, Shrine, Hearth, and
  boss focal contract; later biomes retain their existing themes.
- Shifted the First Road fallen log from grey-green toward bark brown so its
  room anchor no longer reads as pale crypt stone at play distance.
- Verified 893 canonical assertions, all 112 release resources, and a clean
  exported title → town → generated road → return route.

## 0.1.10-open-canopy — 2026-07-20

- Preserved procedural Chart graphs, randomized authored clearing archetypes,
  continuous FATE camera control, and every gameplay wall/corridor boundary.
- Tightened and lowered only the two presentation-only Deep Wood foliage tiers
  after rendered play showed them becoming oversized foreground blobs.
- Widened the existing opaque screen-space cutaway so adjacent natural wall
  crowns yield with the direct occluder, protecting the nearby combat stage.
- Kept collision, navigation, encounters, room footprints, camera framing,
  controls, audio, and later-biome walls unchanged.
- Verified 888 canonical native assertions, the retained direct corpus with no
  checkpoint-caused failure, all release resources, and a clean browser title
  → town → generated First Road → return route.

## 0.1.9-soft-ground — 2026-07-20

- Kept the procedural Chart, authored clearing archetypes, merged floor,
  collision, navigation, walls, and continuous FATE camera unchanged.
- Morphed only the First Road's existing toon-ground controls from evenly
  weighted polygonal stone toward warm dirt with broad moss variation.
- Rejected a flat olive pass and a second large-polygon pass before accepting
  the quieter warm soil treatment in native and Web play.
- Preserved later wood-grove materials and added no mesh, texture, decal,
  shader, scatter system, draw call, or gameplay authority.
- Verified 883 canonical native assertions, the retained direct corpus with no
  checkpoint-caused failure, all 112 release resources, and a clean browser
  title → town → generated First Road → return route.

## 0.1.8-deep-wood — 2026-07-20

- Kept procedural Chart graphs, randomized authored clearing archetypes, and
  the continuous FATE camera while embedding First Road rooms in deeper forest.
- Added one presentation-only forest bed beneath the generated grid and
  deepened each existing cutaway-owned rear foliage shoulder into two seeded
  tiers without adding collision, navigation, interaction, or route authority.
- Reduced near-black pixels in the rendered Web playfield from `0.2684` to
  `0.0000`, matching the approved First Hollow concept's continuous surround.
- Verified the complete layered wall still lowers and restores under the local
  cutaway and keeps its scan below the existing 1.5 ms budget.
- Passed 878 canonical native assertions, 118/122 retained direct entrypoints
  with only historical driver/timing exceptions, all 112 release resources,
  and a clean browser title → town → generated First Road → return route.

## 0.1.7-shaded-road — 2026-07-20

- Preserved the accepted native art direction while correcting the Web
  Compatibility renderer's clipped, flat First Road presentation.
- Added one Web-only post-tonemap grade to the duplicated 3D biome environment;
  HUD, parchment, labels, procedural layout, walls, and camera are untouched.
- Moved the measured browser playfield mean from `0.371` to `0.316` beside the
  approved concept's `0.328`, restoring visible floor/foliage/wall separation.
- Proved native before/after luminance distributions match to five decimal
  places and completed the real browser title → town → World → return route
  with an empty warning/error ledger.
- Verified 870 canonical native assertions, the 116/121 retained corpus with
  only its historical driver/timing exceptions, and all 112 release resources.

## 0.1.6-living-edge — 2026-07-20

- Kept procedural Charts, randomized authored room archetypes, and the
  continuous FATE camera while giving First Road rooms deterministic living
  edge profiles.
- Replaced the repeated hedge ring with layered leaf, root, fern, stone, and
  bramble banks plus one archetype-aware landmark per room.
- Kept every compound edge on its existing wall body so collision,
  navigation, projectile truth, and the local camera cutaway remain unified.
- Quieted the playable center and hid the immediate exterior void behind a
  non-colliding rear foliage shoulder without rebuilding deep wall fields.
- Verified 866 canonical native assertions, the retained corpus with no
  checkpoint-caused regression, and the real native and Web renders beside
  the approved First Hollow concept.

## 0.1.5-natural-hollows — 2026-07-20

- Kept seeded procedural Chart graphs while giving First Road rooms
  deterministic, role-aware clearing archetypes and varied footprints.
- Replaced the solid field of unused wall cells with only the playable
  boundary, cutting obstruction without changing routes or collision truth.
- Replaced rectangular First Road slabs with lower, irregular root-and-hedge
  masses that continue to yield to the continuous FATE camera.
- Protected combat-room centers from theme, Affix, and guaranteed-resource
  dressing so movement, rolls, enemies, and bow lines own the stage.
- Verified 855 native assertions, the retained regression corpus with no new
  failures, and rendered 1280×720 production play beside the approved First
  Hollow concept.

## 0.1.4-sure-road — 2026-07-20

- Made resolved Hearth chains and relieved Oath bells scanner-inert so a used
  encounter prop cannot steal the player's exit interaction.
- Added fail-closed, exact-target receipts to critical source, chain, and far
  Waystone actions without changing normal nearest-prompt play.
- Corrected the Fire route's renewable Wildgold economy and physical Lodge
  status projection while preserving authored Chart randomness and rewards.
- Audited all 112 release resources and completed the exported Fire in the
  Bough journey in Chromium in 362 seconds with an empty diagnostic ledger.
- Kept the 845-assertion native checkpoint gate green and strengthened its
  controller-A source checks to prove the intended physical target acted.

## 0.1.3-living-yard — 2026-07-20

- Replaced the named neighbors' nearly frozen Meshy pose with a readable,
  planted ambient rig cycle for Mara, Hod, and Quill.
- Staggered each neighbor's timing so the town cast no longer moves in lockstep.
- Preserved authored work positions, prompts, collision, dialog, and the
  existing procedural creature stride instead of adding wandering AI.
- Added production-scene checks at 1280×720 proving all three rigs and their
  visible model roots continue moving alongside the W/Space input gate.
- Verified 844 native assertions and captured a rendered yard replay.

## 0.1.2-readable-hollow — 2026-07-20

- Added a bounded screen-space wall cutaway around the player so procedural
  Hollow walls no longer hide the ranger, enemies, or immediate combat lane.
- Kept wall collision and full physical height while lowering only the
  occluding wall visuals to a readable solid boundary.
- Added a production Bold Road gate covering multiple cuts, restoration after
  camera rotation, and a 1.5 ms update budget.
- Verified 841 native assertions and a clean exported-browser journey through
  the real title, town, Hollow, and return path.
- Added repeatable native/Web before-and-after evidence and made the compact
  browser gate capable of choosing the rendered New Journey button.

## 0.1.1-responsive-road — 2026-07-20

- Restored immediate ARPG locomotion after the First Road feel review.
- Increased run response while retaining Shift-walk for deliberate town motion.
- Shortened the roll without changing its displacement or recovery proportion.
- Tightened camera follow and reduced reversal lead.
- Added faster locomotion crossfades, readable creature stride, and smooth
  creature steering.
- Added a 1280×720 W/Space production-input acceptance gate and rendered replay.

## 0.1.0-first-road — 2026-07-20

- Replaced the fresh New Journey opening with a bounded 5–10 minute First Road.
- Added Kind and Bold authored Charts, each with three visible Affixes.
- Added explicit low-vigor, suppressed-elite, and guaranteed-elite tuning.
- Added a deterministic safe lesson target and a later pressure encounter.
- Added a successful-return debrief, Power Shot award, and physical village lamp.
- Added three deterministic debug routes and a 14-check acceptance gate.
