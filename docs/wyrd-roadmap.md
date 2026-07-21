# Wayfinder — consolidated roadmap (2026-06-12)

THE single where-are-we doc. Detail lives in the linked plans; when this
disagrees with code, code wins. Repo note: the three.js prototype was
removed 2026-06-12 (recoverable from git history).

## Full-game direction locked 2026-07-17

The playable build below remains the current implementation, but the next
full-game arc now has a concrete source of truth:

- [ADR 0016](adr/0016-four-trades-level-23.md) supersedes the one-Trade,
  level-17 direction: Wayfinding, Earthcraft, Wildcraft, and Huntcraft will
  each run from level 1 through 23.
- [ADR 0017](adr/0017-local-norse-root-saga.md) narrowly amends the locked lore
  ceiling: Bramblewood remains warm and local, while older rootroads may hold
  Norse-inspired, place-bound keepers beyond the Hedgemother chapter.
- [Spec 56](specs/56-full-game-arpg-saga.md) defines the complete ARPG system
  inventory, per-level unlocks, staggered combat-Skill onboarding, item and
  building ladders, boss-chart collection loop, Norse-inspired Root Saga,
  icon/asset contract, legendary Wayweaver, and implementation waves.
- [Research sources](research/arpg-systems-and-norse-campaign-sources.md)
  ground the map/key, target-farming, legendary, settlement, and Norse-myth
  patterns in first-party ARPG documentation and primary/academic texts.

No code is implied shipped by this section. Implementation begins with save
migration and progression/onboarding contracts, then re-ladders the existing
levels 1–17 before adding the new 18–23 chapters.

## Product focus amended 2026-07-20

[ADR 0018](adr/0018-authored-charts-single-player-focus.md) makes Wayfinder a
single-player product for the current build. Co-op entry points, the Lantern,
and network boot hooks are removed; dormant transport compatibility is not a
supported feature or release gate. Charts retain procedural layouts and
contents, but the player authors up to three Affixes that bias distributions
such as enemy vigor, elite frequency, and resource abundance. Early Charts
target 5–10 minutes; mature Charts cap at roughly 20–25 minutes.

## First Road vertical slice — playable 2026-07-20

[Spec 60](specs/60-first-road-vertical-slice.md) is the current reaction gate.
Fresh New Journey now proves the direction in one bounded loop: Mara offers a
Kind or Bold three-Affix Chart, the seeded four-to-five-room road teaches bow
and roll, a later room supplies pressure, and a successful return awards Power
Shot and physically lights the First Road lamp in the yard. Do not expand the
slice until the player has reacted to the actual build.

## Responsive Road checkpoint — playable 2026-07-20

[Spec 61](specs/61-responsive-locomotion-checkpoint.md) resolves the largest
feel mismatch exposed by the First Road playtest: cozy pacing had leaked into
input, camera, roll, and creature-facing latency. The checkpoint keeps the
FATE camera composition and authored Chart loop, but makes starts, stops,
turns, camera catch-up, and dodge recovery immediate enough for a one-verb
action game. Creature pursuit now turns continuously and carries a readable
stride instead of snapping as a chunky block. This is a tuning checkpoint,
not a content expansion.

## Readable Hollow checkpoint — accepted locally 2026-07-20

[Spec 62](specs/62-readable-hollow-checkpoint.md) resolves the largest visual
mismatch exposed after locomotion became responsive: procedural wall blocks
could still hide the ranger, enemies, and the immediate combat lane. The camera
now lowers only wall visuals inside a bounded player aperture, retaining opaque
mass, collision, layout, and encounter truth. The eight-suite native gate is
green at 841 assertions, and the exported compact journey passed Chromium with
an empty diagnostic ledger. Publication remains pending because the current
working tree contains a much larger uncommitted campaign build whose release
provenance must be made reproducible without discarding it.

## Living Yard checkpoint — playable 2026-07-20

[Spec 63](specs/63-living-yard-checkpoint.md) resolves the largest mismatch in
the hometown after the Field Journal and First Road passes: Bramblewood's
neighbor-led loop was staged around three nearly frozen people. Mara, Hod, and
Quill now carry restrained, staggered ambient motion from their existing rigs
and walk sidecars, readable at the FATE camera without moving prompts,
colliders, conversations, or authored work positions. This is intentionally a
social-presence checkpoint, not a schedule or navigation system. The 1280×720
W/Space production gate passes 12/12, and rendered evidence lives in
`docs/playtests/living-yard/`.

## Sure Road checkpoint — accepted locally 2026-07-20

[Spec 64](specs/64-sure-road-checkpoint.md) resolves the largest reliability
mismatch exposed by the strict late-road playthrough: the visible prompt could
name the way home while a settled encounter prop still won the scanner. Used
Hearth chains and relieved Oath bells are now scanner-inert, and critical
source, chain, and far-Waystone actions carry an exact one-shot interaction
receipt that fails closed rather than retargeting. The 845-assertion native
gate is green. A fresh 362.069-second exported Fire route passed every phase,
loaded all 112 audited resources from a 105,898,896-byte PCK, and produced no
browser diagnostics. Root publication is still pending a safe provenance
boundary for the larger mixed campaign worktree.

## Natural Hollows checkpoint — shipped 2026-07-20

[Spec 65](specs/65-first-hollow-room-grammar.md) preserves seeded procedural
Charts and the continuous FATE camera while changing what a First Road room is.
Role-aware clearing archetypes now own varied floor footprints and a protected
combat aperture. The loader builds only the playable wall boundary instead of
the unused exterior field, presenting it as lower irregular hedge-and-rootstone
mass whose local pieces still lower and restore under camera obstruction. The
nine-suite checkpoint gate is green at 855 assertions, and the retained corpus
adds no new failure to its four documented driver/repro exceptions. The Web
export audited 112/112 release resources from a 105,903,744-byte PCK; both the
compact title → town → World → return journey and a manual Bold Road entry had
empty diagnostic ledgers. The exact game source is pushed on
`codex/wayfinder-director`, and companion-site version 4 is live with the new
playable export and release evidence.

## Living Edge checkpoint — shipped 2026-07-20

[Spec 66](specs/66-first-hollow-living-edge.md) deepens the accepted procedural
room grammar without replacing it. Every First Road boundary cell now resolves
to a deterministic, archetype-owned leaf, root, fern, stone, or bramble
profile, and every generated room owns one seeded perimeter landmark. The
layered visual remains a child of the existing colliding wall and therefore
lowers and restores as one unit under the continuous FATE camera. The
ten-suite gate is green at 866 assertions; native and Web rendered evidence
shows a denser, more asymmetrical perimeter with a protected central stage.
The exact game source is pushed on `codex/wayfinder-director`, and companion
site version 5 is live with the verified playable export and release receipt.
The next player-visible candidate is the Web renderer's bright, flat tonal
separation, not another parallel game system.

## Shaded Road checkpoint — shipped 2026-07-20

[Spec 67](specs/67-web-tonal-separation.md) resolves the Web renderer mismatch
exposed by Living Edge. Generated exploration scenes now apply one Web-only
post-tonemap adjustment through their duplicated 3D biome environment, lowering
clipped highlights without filtering the HUD or changing native Forward+
rendering. The eleven-suite gate is green at 870 assertions; native before and
after distributions match to five decimal places, while the browser
playfield's measured mean moved from `0.371` toward the approved concept at
`0.316` versus `0.328`. The exact 105,922,096-byte export audited all 112
release resources and completed title → town → generated First Road → return
with no warning/error diagnostics. Companion-site version 6 is live with the
same playable export, fingerprint, rendered comparison, and next priority. The
next visual comparison should address the remaining black-void/isolated-ring
read around rooms, deepening forest continuity without restoring obstructive
wall fields or changing the continuous FATE camera.

## Deep Wood checkpoint — shipped 2026-07-20

[Spec 68](specs/68-first-hollow-forest-continuity.md) resolves the isolated-ring
read exposed by Shaded Road. Procedural First Road clearings now sit over one
quiet, non-authoritative forest bed, and each existing cutaway-owned rear
foliage shoulder reaches into two seeded depth tiers. The authored archetypes,
Chart graph, collision, navigation, encounters, and continuous FATE camera are
unchanged. In the matched Web crop, near-black coverage fell from `0.2684` to
`0.0000`; native and browser renders now read as clearings embedded in
Bramblewood rather than boards over void. The twelve-suite gate is green at 878
assertions, the retained corpus is 118/122 with only historical driver/timing
exceptions, all 112 release resources audit cleanly, and the exact browser
route completed title → town → generated First Road → return with an empty
diagnostic ledger. Companion-site version 7 is live owner-only with the exact
playable export, fingerprint, rendered comparison, and next-replay priority.
The next cycle should begin by replaying the shipped build
and deciding whether foreground canopy bulk, interior ground sameness, or room
landmark identity is now the highest-leverage visible weakness.

## Soft Ground checkpoint — shipped 2026-07-20

[Spec 69](specs/69-first-road-soft-ground.md) resolves the uniform stone-sheet
read exposed by the Deep Wood replay. The First Road now morphs the existing
one-surface toon-ground shader toward warm soil and broad moss variation with
almost no grout or bevel. No mesh, texture, draw call, route, collision,
navigation, encounter, wall, camera, control, or later-biome material changed.
Native and Web evidence shows a quieter dirt clearing closer to the approved
forest concepts after two rejected material passes. The thirteen-suite gate is
green at 883 assertions, all 112 release resources audit cleanly, and the exact
browser route completed title → town → generated First Road → return without a
warning or error. The next cycle should replay the shipped build before choosing
between foreground canopy bulk, corridor-mouth direction, and stronger
archetype landmark identity. Companion-site version 8 is live owner-only with
the exact playable export, fingerprint, accepted render, and replay priority;
its pushed source is `b31880de5417103ab8c72dcf83337f4a5283f09b`.

## Open Canopy checkpoint — shipped 2026-07-20

[Spec 70](specs/70-first-road-open-canopy.md) resolves the foreground crowding
exposed by replaying Soft Ground at the continuous FATE angle. The two existing
presentation-only forest-depth tiers now sit lower and inside a tighter visual
envelope, and the established opaque cutaway protects a wider nearby combat
stage so adjacent natural crowns yield with the direct occluder. Procedural
rooms, randomized archetypes, wall collision, navigation, encounters,
corridors, camera control, audio, and later biomes are unchanged. Native moving
play rejected two geometry-only passes before accepting the wider low opening.
The fourteen-suite gate is green at 888 assertions; the retained corpus is
120/124 with only historical driver/repro and old movement exceptions; all 112
release resources audit cleanly; and the exact browser route passed title →
town → generated First Road → return with no warning/error diagnostics. The
exact 105,923,952-byte PCK has SHA-256
`add43de81df0b0416608d86d02a6356b804e69f9a7149aae644cf98f5c363bb8`.
Companion-site version 9 is live owner-only with the exact playable export,
fingerprint, accepted render, and next-replay priority; its pushed source is
`5e5532d9671bac7b1e85a09d58080dc68006067a`.

## Forest Rooms checkpoint — shipped 2026-07-20

[Spec 71](specs/71-first-hollow-room-composition.md) resolves the room-identity
gap exposed by replaying Open Canopy. The generator's existing Lantern Landing,
Round Glade, Crooked Bower, and Long Clearing choices now control compact forest
composition kits rather than inheriting generic crypt-era themes beneath asset
remapping. Shapes, graph connections, counts, and placement remain seeded and
procedural; the continuous FATE camera, natural cutaway walls, protected combat
stage, typed interactions, enemies, rewards, controls, audio, and later biomes
are unchanged. The fifteen-suite gate is green at 893 assertions. All 112
release resources audit cleanly, and the exact exported title → town → generated
road → return route completed with no browser diagnostic. The 105,924,736-byte
PCK has SHA-256
`f3ea722c0a716db7615d83250e9dacb305ff5fa81759445c8ea7ea9ca6f62509`.
The next replay should judge the oversized pale treasure-chest presentation and
remaining creature/prop coherence rather than adding another room system.
Companion-site version 10 is live owner-only with the exact playable export,
Forest Rooms evidence, fingerprint, and next-replay priority; its pushed source
is `466671dc6dea6a960226d560a61e52819b3cdfa3`.

## Open Floor checkpoint — shipped 2026-07-20

[Spec 72](specs/72-first-hollow-room-breathing.md) resolves the interior
crowding exposed by replaying Forest Rooms. First Road satellites now carry an
authored supporting scale, and each real corridor mouth reserves a three-wide,
two-deep landing before seeded decor may resume. Full-size archetype landmarks,
procedural graphs and placement variation, the continuous FATE camera, natural
cutaway walls, collision, navigation, combat, typed rooms, rewards, controls,
audio, and later biomes are unchanged. The sixteen-suite gate is green at 898
assertions; the strict retained audit is 119/126 with the same three long-driver
timeouts and four documented legacy exceptions as the prior 118/125 corpus.
All 112 release resources audit cleanly, and the exact exported title → town →
generated road → return route completed with an empty browser diagnostic
ledger. The 105,925,552-byte PCK has SHA-256
`097269870847107143037a5fd35054fe2937616ea65f04a26a6225c7b5a70a66`.
Companion-site version 12 is live owner-only with the exact playable export,
Open Floor evidence, fingerprint, and next-replay priority; its pushed source
is `8d1e4023c3ae39860134ec598585fc97b59bea69`. Version 11's source-only publish
attempt hit the host's fetch path, so the identical verified build was saved
and published through the supported archive fallback as version 12.

## Open Larder checkpoint — shipped 2026-07-21

[Spec 73](specs/73-first-hollow-setpiece-breathing.md) resolves the setpiece
exception exposed by replaying Open Floor. The First Road larder remains an
authored, seeded discovery inside the procedural Chart, but its legacy pottery
markers now resolve at the accepted forest-support scale and do not render
inside protected room approaches. Hidden occupancy reservations keep downstream
enemy placement deterministic. The procedural graph, randomized archetypes,
continuous FATE camera, natural cutaway walls, collision, navigation,
encounters, controls, audio, rewards, typed interactions, and later-biome
setpieces are unchanged. The seventeen-suite gate is green at 904 assertions;
the strict retained audit is 120/127 with the same three long-driver timeouts
and four documented historical exceptions. All 112 release resources audit
cleanly, and the exact exported title → town → generated road → return
route completed in 25.7 seconds with an empty browser diagnostic ledger. The
105,926,096-byte PCK has SHA-256
`53e32814f232d775355572878864935f0c1d54812fa3feba929f4c32cb38efac`.
Companion-site version 13 is live owner-only with the exact playable export,
Open Larder evidence, fingerprint, and next-replay priority; its pushed source
is `a178c4053f21545e2843a2906738f3096026bdf5`.

## Readable Passages checkpoint — shipped 2026-07-21

[Spec 74](specs/74-first-hollow-readable-passages.md) resolves the doorway
silhouette exposed by replaying Open Larder through continuous camera yaw.
Actual First Road room connections now tag only their neighboring physical wall
cells with a compact `passage_bank` profile: low rootstone and leaf masses form
a five-wide concave shoulder while the deeper forest tier remains beyond the
boundary. Procedural graphs, randomized archetypes, corridor widths, wall
cells, collision, navigation, projectile truth, room landmarks, encounters,
controls, audio, rewards, and the established opaque cutaway are unchanged.
The eighteen-suite gate is green at 911 assertions. The strict retained sweep
is 120/128 with four timeouts and the same four historical failures; the only
additional timeout, the marginal Golden Wallow handoff, passed an immediate
isolated 30-second rerun in 29 seconds, and every changed-seam entrypoint passes.
All 112 release resources audit cleanly, and the exact exported title → town →
generated road → return route completed in 29.8 seconds with an empty browser
diagnostic ledger. The 105,927,600-byte PCK has SHA-256
`646d6db35b5bdcf299907ac399b8ee04bfbe8f82bd273cd94aa94dad4e14d82f`.
Companion-site version 14 is live owner-only with the exact playable export,
Readable Passages evidence, fingerprint, and next-replay priority; its pushed
source is `a7900d5bd8bcc6a69b284cd09ffc0b821bfd8d6c`.

## Creature Identity checkpoint — shipped 2026-07-21

[Spec 75](specs/75-creature-identity-checkpoint.md) closes the clearest combat-
readability and world-coherence gaps in the current campaign. Every production
common creature now owns a fair, colored ranged opening before returning to its
existing melee, kiting, support, or bruiser role. Named creatures opt into the
same language only where it complements their authored signature; Boar, Wolf,
and Knot-Eater remain signature-only. Pause now opens a complete Creature Codex,
and treasure rooms use the authored Wayfinder chest with aligned collision,
scanner reach, prompt, one-shot opening, and two-roll loot behavior. Gilded adds
exactly one bonus chest.

The nineteen-suite native gate is green at 986 assertions, including a new
71-assertion identity contract. Representative chapter gates from First Road
through The Unwritten Road pass. The final Web export audited all 118 required
resources, completed title → town → generated road → return in Chromium, and
left an empty warning/error ledger. Authoring-only UI source sheets are excluded
from the release package; its 96,119,632-byte PCK has SHA-256
`41e4db15838ce053a8cc0a3486688210f99da32ead1019724373e9656fa5d2d2`.
Native and Web evidence lives in `playtests/creature-identity/`. Game source is
pushed at `2948dfb473645506384664b6d1a7a3412006d50d`. GitHub Pages deployment
`aca5e5865267c68e77f847a2a3b6f217f605ec23` keeps `/play/` stable while routing
to versioned `v0.1.15` assets so returning browsers cannot reuse an older PCK;
the public fail-closed title → town → chart table → Codex → road → return route
passed from that URL. Owner-only companion-site version 15 is live with the
exact chunked playable export, Creature Identity evidence, fingerprint, and
next director priority; its pushed source is
`a3ab1f8d49d9f9b510eb4a5f130fde8536553b99`.

## Shaded Home checkpoint — shipped 2026-07-21

[Spec 76](specs/76-shaded-home-checkpoint.md) corrects the clearest weakness in
the exact shipped Creature Identity replay: Town's grass, paths, ranger, Mara,
flowers, and station props collapsed into one pale value band, with Web
Compatibility clipping further toward white. Town now duplicates its 3D
Environment and applies one post-tonemap grade, using a stronger bounded Web
brightness value. Canvas UI, geometry, camera, collision, controls,
interactions, quests, audio, progression, and saves are unchanged.

Matched Forward+ before/after and forced Compatibility captures sit beside the
approved Arrival concept in `playtests/shaded-home/`; a real 1280×720 browser
arrival agrees with the Compatibility result. The twenty-suite canonical gate
is green at 996 assertions, save roundtrip passes 120/120, all 118 release
resources audit cleanly, and the enhanced browser journey passed title → town
→ chart table → Creature Codex → road → return. The exact 96,120,576-byte PCK
has SHA-256
`7499e80d380ba0a6b82d392ffd7db17787bf90f81fbaad1e4a5d625cca7987ce`.
Game source is pushed at
`9125935b99e31853f91109fa4a159a76377fdd82`. GitHub Pages deployment
`0bddb09339449079b68815774b386cf7ce07e0d6` keeps `/play/` stable while routing
to versioned `v0.1.16` assets; the public fail-closed title → town → chart table
→ Codex → road → return route passed from that exact path. Owner-only companion
Field Journal version 16 is live with the exact chunked playable export, Shaded
Home evidence, fingerprint, and arrival-composition priority; its pushed source
is `552de19cbccc71b818b28a2188c972f7457e7941`.

## Gathered Arrival checkpoint — accepted locally 2026-07-21

[Spec 77](specs/77-gathered-arrival-checkpoint.md) closes the next visual gap
revealed by Shaded Home. Town now applies one authored profile to the shared
FATE camera: 38° pitch, 20.5 m distance, and a 3.5 m camera-relative forward
frame. The ranger remains low in view while Mara, the main path crossing,
Waystone, Chart table, and readable bases of all three north landmarks share
the first controllable 1280×720 frame. No yard object, path, spawn, interaction,
or progression landmark moved; orbit and zoom remain under player control, and
First Road retains the global camera defaults.

Matched Forward+ and real browser captures sit beside the approved Arrival
concept in `playtests/gathered-arrival/`. The twenty-one-suite canonical gate is
green at 1,004 assertions after serial confirmation of the two timing-budget
suites, save roundtrip passes 120/120, all 118 release resources audit cleanly,
and the enhanced browser route passed title → town → chart table → Creature
Codex → road → return. The exact 96,121,600-byte PCK has SHA-256
`af1d1ff69fb2c47dd2e71a38816ff1b1c52b5552c80b05e9b8aa68d738edc9bd`.
Publication is not yet claimed by this local acceptance.

## Shipped (all gates green — 333 headless checks across 4 suites; test_skills
## joined the gate after the frozen-hotbar regression)

**Core loop:** tutorial → forage → mix ink → inscribe chart → parameterized
dungeon (affixes shape gather nodes / density / HP / boss dens) → exit
waystone → completion XP → trophy chain (elites → Hedgemother → Boar →
Wolf → **Summit** endgame) → gold economy with Hod → save/load.

**Trades:** Wayfinder/Earthcraft/Wildcraft/**Huntcraft** with XP+levels
(Trades page K, four rows); kills feed Huntcraft scaled to the slain
thing's vigor, perks at 5/10 (crit/move speed) — ADR 0005;
channel-time gathering with interrupts; town stations (6 herb / 3 ore /
3 log, regrowing); cooking at the Cottage Hearth (draughts, Q-quaff);
alchemy at Quill's still (timed buff tonics — Q at full vigor drinks
from her shelf);
smelting+smithing at Hod's Anvil (full gear ladder, 14 recipes E1→E9,
economy-gated); trade
tools in their own equip slots (−30% channel); per-level perks ×4;
first-time hint dialogs per verb.

**Combat:** 4-skill hotbar (1-4+F, icons+tooltips); per-kind enemy stats
(rats nip, skeletons slam); Boar line-telegraph charge; Wolf chained
pack-lunge (2/3/4 by phase); elites + affix modifiers; controls locked
1-4+F (ADR 0004 — click-move fork closed).

**Audio:** 26 ElevenLabs SFX + looping town theme; master mute (F10,
persisted). Regenerate: `wyrd/tools/generate_audio.py`.

**UI:** Wayfinder UI Kit (Claude Design project `wayfinder-ui`) — carved
wood frames (nine-patch-verified), kit chips/buttons/troughs everywhere;
wood-ring HP/Focus globes + skill tray bottom-center (PoE layout); pages
designed-then-implemented: Trades (professions rows + unlock cells), Pack,
Dialog (portrait well), Vendor; custom in-game cursor (default state).
Specs 38–41 + notes.

## In flight

- **Four-Trade progression foundation** — [spec 56](specs/56-full-game-arpg-saga.md)
  + [council notes](specs/56-full-game-arpg-saga-notes.md): ~~Milestones 0A
  pure contract + 0B atomic runtime/save/UI cutover + 0C Chart Table
  presentation~~ **SHIPPED 2026-07-17**.
  Four independent level-1–23 Trade records, save v2 migration, Basic-Shot-only
  onboarding, durable owned-Skill entitlements, transient gear-Skill overlay,
  Wayfinding-only pack growth, and the physical Chart Table are live. The ten
  integrated gates pass 932 checks/contracts. Levels 18/20/22 remain planned
  labels, not usable Skills, until their runtime/UI implementations land.
- **Wayfinding + Chart Table deepening** — [spec 58](specs/58-wayfinding-chart-table.md):
  ~~Slice A recipe resolver + compatibility migration + Slice B physical table
  + Slice C Codex and three-source discovery journey + Slice D1 First Knot
  campaign Seal + Slice D2 matching-Binding Deepening and First Knot Reprise~~
  **SHIPPED 2026-07-18**.
  The progressively revealed 3×3 grid, separate
  four-pot Ink rail, deterministic materialization, atomic no-loss commit,
  first-return discovery lesson, controller focus, guest authority, complete
  roll/stability preview, four-state redacted Codex, known-recipe ghosts,
  Practiced Measures Stage All, Green/Deep/Sallow clues and lesson kits, and a
  fail-closed real-source/Codex Web journey are green. D1 adds three distinct
  guaranteed Green Hollow clues, the deterministic Hedgemother Boss Chart,
  exact-once Thorn Essence escrow, and Tusker Tusk/Green Root Rune/Trophy Hall
  first-clear settlement. D2 adds four recipe-owned Deepening variants, one
  authored layer beyond each recipe's native depth, a hard terminal Hearth,
  the far-Waystone Omen choice, and the campaign-inert two-layer First Knot
  Reprise with one seeded heirloom. Sol accepted the integrated seam after the
  Reprise identity correction. The clean 15-stage release-Web route and all 29
  native test entrypoints passed at D2 acceptance.
- **First Knot Homecoming** — [spec 56 council notes](specs/56-full-game-arpg-saga-notes.md):
  **SHIPPED 2026-07-18**. One pure campaign projection now drives a compact,
  inspectable yard-side Trophy Hall (Green Root Rune, Tusker record, covered
  old bow-rest), the Living Atlas wet-road handoff toward Sallow, and a warm
  session-only debrief. The Hall is durable after a canonical or normalized
  legacy clear; a Reprise suppresses only the debrief. Host truth projects
  read-only to guests and is revoked immediately on join/server loss without
  touching either player's campaign, materials, rewards, recipes, or save.
  Sol and independent Terra QA accepted the corrected authority/modal seams.
  The clean release-Web journey passed all 17 ordered phases and 14 feature
  flags with 0 console warnings/errors; all 31 native test entrypoints pass.
- **Golden Wallow** — [spec 56 council notes](specs/56-full-game-arpg-saga-notes.md):
  **SHIPPED 2026-07-18**. The first new deterministic chapter now carries three
  distinct Sallow Shallows clue returns, a Wildcraft-10 Mire Ink experiment,
  the guaranteed Burrow Boar's Wallow Boss Chart, exact-once Tusker Tusk
  escrow, Mist Root Rune and Wightpelt settlement, and the restored Sallow
  Jetty. The proven two-chapter descriptor preserves First Knot compatibility;
  host truth projects read-only to guests and fails closed on disconnect. The
  release-Web route passed all 21 ordered phases and 13 production-feature
  proofs with zero warnings/errors, including the new Jetty GLB. Sol accepted
  the integrated contract with no P1/P2 findings; all 36 native test
  entrypoints pass.
- **Seventh Road** — [spec 56 council notes](specs/56-full-game-arpg-saga-notes.md):
  **SHIPPED 2026-07-18**. Four host-frozen Cold Tracks now advance through
  distinct Briar returns; Mothglow and the Boss Table enforce current
  Wildcraft 14; Wightpelt escrow produces the guaranteed Wolf Alpha; and the
  canonical death settles exactly one Alpha Fang, Fang Root Rune, and a live
  Skald Archive. Guests are read-only at sources and receive the host's frozen
  World clue. The protected, campaign-inert Summit handoff refunds Alpha Fang
  once on abandon/recovery and consumes it once on Queen death. Sol accepted
  the corrected implementation with no remaining P1/P2 findings. All 41 native
  entrypoints pass, and the post-review Chromium route passed 32 phases and 20
  production proofs.
- **Queen's Summit** — [spec 56 acceptance](specs/56-full-game-arpg-saga-notes.md):
  **SHIPPED 2026-07-18**. Four physical Crownward Ascent returns bank distinct
  Shed Crown-Thorns; the level-17 Queen Chart escrows Alpha Fang and forces the
  canonical Hedgemother Queen; settlement awards exactly one Oath Nail, Crown
  Root Rune, and readable Pale Stair. Legacy Summit Charts remain campaign-
  inert and retired from new commits, including one-time v2 Fang migration and
  frozen D4 compatibility. Host truth projects read-only to guests. Sol found
  no remaining P1/P2 blocker; all 47 native entrypoints pass. Final Chromium
  D4 passed 32 phases / 20 proofs, D5 passed 28 phases / 13 proofs with two
  scanner-driven Stair reads, and both browser error logs were empty. The Web
  PCK explicitly contains the Stair GLB. **Next:** The Pale Oath, levels 18–19,
  then Fire in the Bough and The Unwritten Road through level 23.
- **Pale Oath** — [implementation and acceptance](specs/56-full-game-arpg-saga-notes.md):
  **SHIPPED 2026-07-18**. The copy-only Pale Stair now leads through the real
  Archive, physical Table, four distinct Pale Veins returns, and the
  Oath-Nail-sealed Barrow Jarl road. Campaign v4, Rootroads, Stonewake,
  Wildgold/Wellmoss, Driving Volley, Trophy Sense, exact settlement, the
  Rootroad Lift/oath-stone, final skinned characters, and distinct reward/Skill
  icons are live. Sol's final audit first exposed four encounter lifecycle,
  damage, co-op-authority, and bell-model defects; Terra repaired them and Sol
  accepted the focused re-audit with no P1/P2 remaining. All 54 native
  entrypoints pass. The post-repair final-export D6 route passed 32 phases and
  16 production proofs with 72 browser entries and zero warnings/errors; its
  isolated 55-resource PCK audit measured 117,332,168 bytes. **Next:** Fire in
  the Bough, levels 20–21.
- **Fire in the Bough** — [locked council contract](specs/56-full-game-arpg-saga-notes.md):
  **ACCEPTED NATIVE + RELEASE WEB 2026-07-20; PUBLICATION PROVENANCE PENDING.** Terra
  and Sol completed a full design/architecture/QA council and accepted the
  reconciled contract. The slice is Campaign v5 with
  five physical Ashen Bough returns, Ember Verses, renewable Emberleaf Ink, a
  seed-frozen elite manifest, Cinderbound twins, host-authoritative Threadstep,
  the three-bank Hearth Giant and late-join encounter snapshot, exact Coal to
  Wyrm Scale settlement, Ember Root Rune, Present Thread, and the sole Fire
  restoration at the Ember Kiln. The final native D7 route passed 5/5 in 458
  seconds across 52/60 World legs. Accepted hardening includes immutable
  World/Chart/generation ownership for delayed Far returns, one return claim per
  generation, authored tier-2 Briar evidence when a valid layout has no gather
  candidates, and exact-once modal ownership. Release Web now omits only the
  incompatible dynamic bog ReflectionProbe; a four-way Web A/B isolated that
  probe as the framebuffer-blit source, while native Mire still contains one.
  The final release export passed an isolated 112/112-resource audit at
  105,898,896 bytes. A clean fresh Chromium journey completed all prior-saga
  receipts, five Ashen returns, three exact chain banks, the Hearth Giant,
  Ember Kiln, Starheart work, and Threadstep in 362.069 seconds. The strict
  harness passed with zero warnings, errors, assertions, or exceptions. The
  root commit/push remains pending because this accepted slice shares a much
  larger mixed uncommitted campaign worktree whose ownership must not be
  rewritten merely to publish D7. **Next:** establish a safe provenance
  boundary, then certify The Unwritten Road in a separate strict browser run.
- **The Unwritten Road** — [locked council and native slice acceptances](specs/56-full-game-arpg-saga-notes.md):
  **IMPLEMENTING — CORE STORY/MASTERY/WAYWEAVER SLICES NATIVELY ACCEPTED;
  RELEASE WEB ACCEPTANCE PENDING (STOPPING POINT 2026-07-19).** Campaign v6,
  immutable final-story witnesses, Wyrm-only
  escrow, the Root Below/final Table contracts, and exact authored late XP are
  implemented. Sol rejected the first pass because queued pre-inscribed Charts
  could lose their indexed reward when rebinding to the next Waymark; Terra
  corrected the atomic clue-plus-reward rebind and Sol accepted the re-review
  with no P1/P2 findings. The physical Loom lesson, renewable 10/5/7g stock,
  five production Table/Waystone/World/return loops, deterministic reachable
  Waysteel/Root-Sap/Waymark guarantees, Open Thread/Snagged Thread, and read-only
  Codex/Atlas projections are now accepted. The zero-gold route reaches exactly
  level 23 and leaves 52g after four replacement kits. The Huntcraft-22 Lodge
  lesson, owner-reserved 35-Focus Wayfinder's Mark, six-phase physical
  Knot-Eater ritual, stable reconnect receipts, full-party reset, blocking
  host-only naming, and durable mechanically-identical road result are now
  accepted. Later native slices also include pure mastery and Thread rules,
  physical mastery components, an authoritative/persistent Master Forge, the
  unique Wayweaver legendary and equipped LeftHand attachment, room-scoped
  Focus-to-Basic-Shot echoes, Root Rune cosmetics, Town/Trophy projections, and
  the physical Map of Nine Knots Loom ritual and final lesson provenance. The
  Knot-Eater still uses the bounded Barrow Jarl placeholder model. **Next after
  the independent D7 browser gate:** run the separate strict fresh
  title-to-Wayweaver D8 browser marathon, then complete the remaining release
  and art gates. A real two-process ENet gate also remains open.
- **UI refinement rounds** (design-pass Phase 3 tail): Craft, Satchel,
  Charts, Inscribing — all already wear the kit; rounds are polish.
  ⚠️ Inscribing's round is **superseded by the crafting rebuild below**.
- **Art one-offs:** painted trade emblems, tool icons, NPC portraits
  (dialog well shows a ghost), cursor interact/attack hover swaps.

## Next, in order

1. ~~Chart crafting rebuild — spec 42~~ **SHIPPED 2026-06-12**: the
   Crafting Bench (placement sockets, live odds preview, on-bench mixing
   pot, guided-tutorial highlights) replaced the menu panel; 151 checks
   green. Open: design-page side-by-side + fresh-save manual tutorial run
   (notes file).
2. ~~B5 loadouts~~ **SHIPPED 2026-06-12**: PiercingBolt (pierce-3 line
   shot) + RainOfThorns (delayed thorn AoE w/ bleed); slot 1 fixed Bow,
   slots 2-4 picked in the Loadout panel (dungeon Hearth rest + Cottage
   Hearth button); persisted in the save; 160 checks green. Also this
   pass: bench tooltips everywhere + click-to-place.
3. ~~A6 node tiers + tool tiers~~ **SHIPPED 2026-06-12**: copper (E1) →
   bogiron (E3) → palechalk (E7, charts tier-2+ only); locked veins stand
   visible naming their level; town heap = 2 copper + 1 locked bogiron;
   copper chain (ore→bar→Copper Ring); Cinderbloom tools at E7 (−45%
   channel, palechalk-made). Note: stoneground ink now effectively gates
   at Earthcraft 3 — intended ("coveted"), watch the early-game feel.
4. ~~B6 affixes~~ **SHIPPED 9/9 2026-06-12**: wave 1 (Sprinting Things ·
   Gilded Hollow · Bursting) + wave 2 (Quiver/Damp Strings · Fog of
   Hedge/Blinding Fog · Frenzied/Seething · Wellspring/Barren Veins ·
   Echoing Steps/Hollow Echo · Marked Quarry/Skittish Prey). 15 rollable
   affixes total; dens stay trophy-only.
5. ~~B7 combat XP as a trade~~ **SHIPPED 2026-06-12**: ADR 0005 — ONE
   combat trade, Huntcraft. Kills award `max(2, hp_max/3)` xp; perks
   Steady Hands (5, +5% crit) / Hunter's Stride (10, +5% move); fourth
   Trades-page row; old saves backfill at lv 1.
6. ~~A7-full smithing~~ **SHIPPED 2026-06-12**: forge now carries the full
   gear ladder (14 recipes) — Shortbow E1, caps/boots E5, jerkin E6,
   Palechalk Ring (rare) + Palechalk Longbow E9 — behind a tested economy
   gate: no smithed item sells for more than its Hod-buyable input cost.
   Craft panel grew a scroll. **A8-full alchemy (Quill)** still open.
7. ~~A8-full alchemy (Quill)~~ **SHIPPED 2026-06-12**: Quill, the
   Herbalist (canon npcs.js character, soft-spoken) minds the SW herb
   corner with her copper still; 2 buff brews — Quickroot Tonic (W3,
   −25% channel, 90s) + Clearwater Philter (W6, palechalk-gated, +50%
   Focus regen, 90s); timed-buff engine on Game (runtime-only, not
   saved); Q at full vigor drinks the buff shelf, heal shelf keeps
   priority while hurt; first-use still hint in her voice. Deferred:
   herb tiers to mirror A6's ore ladder (A6-style forage tiers).
8. ~~Recipe discovery ("the experiment") — spec 43~~ **SHIPPED
   2026-06-12**: ink recipes are found, not given. Fresh saves know only
   Hedge Ink; the pot auto-mixes discovered recipes and unknown matches
   wait for **Try the Mix** (discovery +50 carto · miss = smudge / wild
   ink / serendipity, consolation kept, +5 carto). Bench codex strip
   with NPC riddles gated on seen hints; 2 new discoverable inks (Ash —
   groves/sprinter bias · Chalkwash — the deep wave-2 trio); discovery
   rides the save, pre-43 saves keep their three inks.
9. ~~B5 wave 2 — the ability roster~~ **SHIPPED 2026-06-12**: pool grew
   5 → 9. Thornburst (nova + snare panic button), Hunter's Mark (marked
   status: +30% damage taken, 8s), Heartwood Ward (30-damage absorb,
   8s), Mercy Shot (×3 execute under 35% vigor). Huntcraft gates the
   deeper three (4 / 7 / 9) — kills teach the hunting verbs; locked rows
   stand visible in the loadout picker.
10. **UI detail pass — reference round 2 (IN FLIGHT, user-side)**:
    12 Midjourney prompts (8 page heroes + 4 crop-ready element sheets)
    — preserved in `../kb/wiki/pipeline/Concept Art Prompts.md` and
    `kb/wiki/pipeline/UI Workflow.md`. Generate → drop in
    `docs/ui-refs/round2/` → measure/crop/implement (the spec-39 flow).
11. ~~Trade ladders to the cap — specs 45-*~~ **SHIPPED 2026-06-12**
    (ADR 0006: demo level cap 17, enforced in `award_xp`). Wildcraft: 6
    herb tiers (W1/3/7/10/13/16, bible's locked list), heal ladder
    35→220, 3 buff brews (move_speed / vigor_regen / grit), perks 13/17.
    Earthcraft: Starsilver E11 + Hedgesteel E15, 10 forge recipes to the
    E17 Warbow, perks 13/17, 2 fixed Summit hedgesteel veins. Huntcraft:
    Quick Nock 12 / Heavy Draw 14 / **Even Breath 17** (kills return 6
    Focus). Wayfinding: first perk ladder (6 perks 2→17 incl. Master
    Wayfinder's +1 ink slot), den req gates now enforced. 3 new
    discoverable inks (Mothglow, Foxglove, Gildleaf) — every rollable
    affix now has a courting ink. Design specs + integration notes in
    `docs/specs/45-trade-ladders-*.md`.
12. ~~End-to-end gap pass~~ **SHIPPED 2026-06-12**: frozen-hotbar crash
    fixed (cooldown keys re-seeded; test_skills revived → 4th gate
    suite); Trades/Satchel/Charts pages scroll (drawn-UI scroll +
    ninepatch masks); **abandon stone** at every dungeon entry (boss
    charts can't soft-lock); foxglove/stonebreak obtainable (tier-2
    rolls + fixed Summit patches); capstone gear out of the drop pool;
    skill bar carries glyphs/tooltips for all 9 skills; vendor/waystone
    lists scroll; Hod's hint stops promising ore-selling.
13. **Retired direction — multiplayer co-op (spec 46):** Phase A and Phase B
    were previously implemented, but ADR 0018 removes co-op from the supported
    product. The historical implementation remains recoverable from git; it is
    not a player-facing mode or current release gate.
    <!-- Historical detail retained below for provenance. -->
    ~~Phase A "town together"~~
    **SHIPPED 2026-06-12**: NetGame autoload (ENet host-auth, roster,
    per-peer spawns), Esc opens The Lantern (host port 7777 / join by
    IP / roster / leave), 12 Hz transform sync + name tags, all seven
    modals stopped pausing the tree in-session (offline unchanged),
    camera/HUD bind the local body, dungeons gated until Phase B.
    Two-process headless loopback smoke test green; `WYRD_NET=host` /
    `join:<ip>` dev hooks. ~~Phase B~~ **SHIPPED 2026-06-12**: dungeon
    co-op — host sockets for the party, everyone crosses on the same
    seed; enemies build seed-identically per peer (deterministic
    `NetFoe` names) and mirror the host via 10 Hz snapshots; guest casts
    replay on the host with the caster's aim/stats; damage to guests
    forwards to their machine; kill credit + Even Breath to the killer;
    per-player loot rolls; party-wipe boss resets; exit/abandon ends
    the run for all. Local-only hitstop, puppet walk anim. Two-process
    dungeon smoke green (`WYRD_NET_RUN=<sec>` hook). **Phase C polish
    queue**: guests seeing each other's arrows, damage numbers via
    events, boss telegraphs on guests, reconnect grace, exit vote.
14. **Queue — next candidates:** buff HUD chip, discovery feel pass,
    skill-icon paint-over once `sheet-icons` lands, fresh-save tutorial
    + boss-feel playtests (user-side), UI mock picks (round 2, your
    ChatGPT conversations), P2/P3 animation sets, balance pass on the
    140/220 heals vs Summit damage.

## Standing followups

- **Animation backlog** (now in `../kb/wiki/pipeline/Animation Pipeline.md`):
  P1 mostly shipped 2026-06-12 — gather swing loop + tool-in-hand + node
  strike pulses, quaff tip-back, bench socket pops + pot mix bloom. Still owed:
  craft scroll-and-seal, waystone chart-socketing, P2/P3 sets.

- Save-file safety: `_test_save_roundtrip` writes/deletes the REAL save.
- Boss-fight feel playtests still owed (Boar charge, Wolf lunge):
  `WYRD_DEV_CHART=tier_1 WYRD_DEV_BOSS=burrow_boar_den|wolf_alpha_den`.
- Vendor list-row buttons slightly washed (cream-on-cream).
- Hosted agent-native apps need one-time OAuth (`connect` commands) before
  /assets, /design-exploration, /visual-plan are usable.

## Doc index

| Doc | Role |
|---|---|
| `wyrd-roadmap.md` | this — consolidated state + queue |
| `../kb/wiki/Universe Build-Out Plan.md` | the plan to grow the demo into a full cozy co-op game (KB-mined: Pillar Zero + Pillar One committed, rest = Horizon) |
| `../kb/` | the LLM Wiki — synthesized, interlinked design map (start at `kb/index.md`). The loose `docs/*.md` design docs (skills/combat plan, UI design pass, trades recap, playbooks, cartography notes, etc.) were folded in here and removed 2026-06-13 |
| `specs/*.md` (+ notes) | per-feature contracts and deltas (immutable record) |
| `adr/` | 0003 cozy-skilling spine · 0004 controls · 0005 Huntcraft · 0006 cap 17 |
| `WORLD_BIBLE.md` / `WORLD_LORE.md` / `CONTEXT.md` | voice / lore / domain language |
