# Wayfinder test manifest

Updated 2026-07-23 for `0.1.19-clear-first-step`.

## Canonical checkpoint gate

Run every entry with `WYRD_NO_SAVE=1 godot --headless --path wyrd --script res://…`.

| Entry | Assertions | Protects |
|---|---:|---|
| `test_wyrd_loop.gd` | 427 | Core loop, data, economy, campaign contracts, Gilded chest count |
| `test_wyrd_dungeon_scene.gd` | 41 | Production World scene and dungeon construction |
| `test_wyrd_transitions.gd` | 125 | Town/World transitions and return ownership |
| `test_skills.gd` | 75 | Hotbar dispatch and Skill behavior |
| `test_boot_smoke.gd` | 148 | Script compilation and Town/World boot paths |
| `test_first_road_slice.gd` | 17 | Fresh 5–10 minute First Road promise and three-stage first-control guidance |
| `test_movement_feel.gd` | 14 | Production keyboard movement, roll feel, named-neighbor motion, and creature opening-to-pursuit behavior |
| `test_hollow_readability.gd` | 9 | Boundary-only living walls, complete-profile cutaway restoration, and budget |
| `test_first_hollow_room_grammar.gd` | 8 | Archetype determinism, variation, boundary truth, and combat apertures |
| `test_first_hollow_living_edge.gd` | 9 | Profile ownership, landmark count, deterministic remixing, and production realization |
| `test_web_tonal_separation.gd` | 4 | Web-only environment grade, native no-op, and forced production mutation seam |
| `test_first_hollow_forest_continuity.gd` | 8 | Forest-bed coverage, cutaway ownership, depth, and non-authority |
| `test_first_road_soft_ground.gd` | 5 | One-surface First Road soil morph and later-biome isolation |
| `test_first_road_open_canopy.gd` | 5 | Compact forest shoulder and wider opaque camera cutaway stage |
| `test_first_hollow_room_composition.gd` | 5 | Archetype-owned forest themes, focal realization, aperture safety, and biome isolation |
| `test_first_hollow_room_breathing.gd` | 5 | Seeded support scale, full-size landmarks, protected room-mouth landings, and biome isolation |
| `test_first_hollow_setpiece_breathing.gd` | 6 | Deterministic larder support scale, hidden approach reservations, encounter stability, and biome isolation |
| `test_first_hollow_readable_passages.gd` | 7 | Deterministic passage ownership, every room mouth, compact production realization, collision truth, and biome isolation |
| `test_creature_codex.gd` | 71 | Exact creature roster, distinct combat tells, named signatures, Wayfinder chest, and nested Codex interaction |
| `test_town_tonal_separation.gd` | 10 | Town-only cloned environment grade, native/Web values, and absence of a Canvas overlay |
| `test_town_arrival_framing.gd` | 8 | Town-only camera profile, bounded framing values, and the real 1280×720 player/Mara/landmark projection |
| `test_town_working_edge.gd` | 12 | Three-landmark band, attached support ownership, protected approaches, and lower-facade projection |
| **Total** | **1,019** | **Required before a checkpoint is accepted** |

## Exported-browser gate

`tools/web_smoke.sh` builds and audits the Web export. For the compact real-path
receipt, run `monitor_web_smoke.mjs` with `--begin`; acceptance requires the
ordered title/town/world/complete history and an empty diagnostic ledger.

The retained `0.1.4-sure-road` proof additionally requires the strict fresh D7
journey: all five Ashen returns, three exact Hearth-chain banks, Giant
settlement, Ember Kiln, Starheart work, and Threadstep. The accepted run took
362.069 seconds, loaded 112/112 audited resources from a 105,898,896-byte PCK,
and ended with a passed harness and an empty diagnostic ledger.

The `0.1.5-natural-hollows` release proof additionally requires a rendered
1280×720 Bold Road comparison with the approved First Hollow concept, the
export resource audit, and a real title → town → First Road → return journey
with an empty browser diagnostic ledger.

The `0.1.6-living-edge` proof additionally compares native and Web First Road
renders with the approved First Hollow concept, requires deterministic profile
and landmark data, and verifies that the full layered edge lowers and restores
through the production camera cutaway. The accepted export loaded all 112
audited release resources from a 105,921,728-byte PCK and completed the compact
journey with an empty browser diagnostic ledger.

The `0.1.7-shaded-road` proof additionally requires measured native/Web/concept
comparison, a native before/after no-op check, and a real exported title → town
→ generated First Road → return receipt with an empty warning/error ledger. The
accepted export loaded all 112 audited release resources from a
105,922,096-byte PCK.

The `0.1.8-deep-wood` proof additionally requires matched native/Web renders
beside the approved First Hollow concept, no physics or navigation authority in
the exterior depth, complete-profile cutaway restoration, and Web near-black
coverage no greater than `0.08`. The accepted render moved from `0.2684` to
`0.0000`; the release PCK loaded all 112 audited resources and the clean compact
browser route produced no warning/error diagnostics. The exact PCK is
105,923,504 bytes with SHA-256
`1b77869a37ec656e664e4d0b4212667812c0808ff47b35377b0f501472d06ce7`.

The `0.1.9-soft-ground` proof additionally requires native/Web comparison of
the First Road floor beside the approved forest concepts, one unchanged merged
floor surface, and a snug-only material override that does not spill into later
wood-grove Charts. The accepted export audited all 112 release resources and
completed the compact browser route with no warning/error diagnostics. Its
105,923,984-byte PCK has SHA-256
`372e3d0c71b3f732beaa9b4f2f8564782af3f5e3a649ce8fc62aa11bc70a467f`.

The `0.1.10-open-canopy` proof requires native/Web comparison of the moving
foreground beside the approved First Hollow concept, compact presentation-only
depth tiers, the wider opaque cutaway stage, and unchanged procedural/gameplay
authority. The exact export audited 112 resources and completed title → town →
generated First Road → return with an empty diagnostic ledger. Its
105,923,952-byte PCK has SHA-256
`add43de81df0b0416608d86d02a6356b804e69f9a7149aae644cf98f5c363bb8`.

The `0.1.11-forest-rooms` proof requires native/Web/concept comparison of the
same generated road, distinct authored composition kits across the seeded
archetype sample, protected combat apertures, and unchanged typed-room focal
contracts. The exact export audited 112 resources and completed title → town →
generated road → return with an empty diagnostic ledger. Its 105,924,736-byte
PCK has SHA-256
`f3ea722c0a716db7615d83250e9dacb305ff5fa81759445c8ea7ea9ca6f62509`.

The `0.1.12-open-floor` proof requires native/Web/concept comparison of the
same generated road, explicit supporting scale on First Road satellites,
full-size archetype landmarks, and a three-wide, two-deep decor-free landing at
every corridor mouth. The exact export audited 112 resources and completed
title → town → generated road → return with an empty diagnostic ledger. Its
105,925,552-byte PCK has SHA-256
`097269870847107143037a5fd35054fe2937616ea65f04a26a6225c7b5a70a66`.

The `0.1.13-open-larder` proof requires native/Web/concept comparison of the
same generated larder, retained seeded setpiece composition, accepted 0.62
support scale, no rendered support inside a protected approach, and unchanged
downstream encounter placement. The exact export audited all 112 resources and
completed title → town → generated road → return in 25.7 seconds with an
empty diagnostic ledger. Its 105,926,096-byte PCK has SHA-256
`53e32814f232d775355572878864935f0c1d54812fa3feba929f4c32cb38efac`.

The `0.1.14-readable-passages` proof requires native/Web/concept comparison of
the same generated room connections at the default camera angle and through
yaw, deterministic passage ownership beside every room mouth, compact cutaway-
owned visual banks, and unchanged full wall collision. The exact export audited
all 112 resources and completed title → town → generated road → return in 29.8
seconds with an empty diagnostic ledger. Its 105,927,600-byte PCK has SHA-256
`646d6db35b5bdcf299907ac399b8ee04bfbe8f82bd273cd94aa94dad4e14d82f`.

The `0.1.15-creature-identity` proof requires exact Codex coverage of every
production common and named creature, kind-owned common-creature opening tells
without erasing established roles, opt-in named-creature casts, the authored
Wayfinder chest, and native/Web Codex evidence. Representative production
chapter gates from First Road through The Unwritten Road pass. The exact export
audited all 118 required resources and completed title → town → generated road
→ return with an empty warning/error ledger. Authoring-only UI source sheets
are excluded from the release package; its 96,119,632-byte PCK has SHA-256
`41e4db15838ce053a8cc0a3486688210f99da32ead1019724373e9656fa5d2d2`.

The `0.1.16-shaded-home` proof requires matched native before/after and forced
Compatibility captures beside the approved Arrival concept, a real 1280×720
browser arrival inspection, and the fail-closed enhanced journey through title
→ town → chart table → Codex → road → return. The Town correction must remain
on its cloned 3D Environment so Canvas UI and every gameplay authority stay
unchanged. The exact 96,120,576-byte PCK has SHA-256
`7499e80d380ba0a6b82d392ffd7db17787bf90f81fbaad1e4a5d625cca7987ce`.

The `0.1.17-gathered-arrival` proof requires matched native and Web first-
controllable-frame captures beside the approved Arrival concept, the ranger in
the lower half, Mara clear of the top edge, and visible north-landmark bases.
The Town-only profile must keep the shared FATE rig and player orbit/zoom while
leaving First Road defaults and all world/gameplay authority unchanged.

The `0.1.18-working-edge` proof requires matched native/Web first-arrival
captures beside Gathered Arrival and the approved concept, all three existing
north-landmark lower facades in frame, deterministic attached support clusters,
and explicit clearance for Mara's route, Chart table, Waystone, practice space,
and central plaza. Camera, grade, content count, and gameplay authorities remain
unchanged.

The `0.1.19-clear-first-step` proof requires the existing Mara objective to show
`WASD move · E talk` on the first controllable native and Web frames with no
compass. The 20-second landmark nudge must remain compass-free, and only the
35-second direct recovery may reveal the gold needle. No other First Road
instruction, interaction, content, or progression authority changes. The exact
96,120,912-byte PCK has SHA-256
`57fa0f9601b4c6e13f82e47cf5fff0819fe9e316d134cbc76541f856e6808fa7`.

The persistence-disabled retained corpus currently contains 128 direct
entrypoints. A strict 30-second-per-entrypoint serial audit passed 120; the
three known long-running driver fixtures and the marginal Golden Wallow handoff
exceeded that watchdog, while the same four documented historical failures
remained. Golden Wallow passed an immediate isolated watchdog rerun in 29
seconds. Every retained test that loads the changed generator/rendering seam
passes. The production
dungeon, transition, boot, standalone movement, room, cutaway, and tonal-grade
gates remain green.

The repository also contains focused chapter, UI, authority, economy, save,
and regression entrypoints. They remain useful for their owning specs, but are
not silently counted as part of this compact checkpoint gate.
