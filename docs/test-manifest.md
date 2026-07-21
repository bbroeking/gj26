# Wayfinder test manifest

Updated 2026-07-20 for `0.1.11-forest-rooms`.

## Canonical checkpoint gate

Run every entry with `WYRD_NO_SAVE=1 godot --headless --path wyrd --script res://…`.

| Entry | Assertions | Protects |
|---|---:|---|
| `test_wyrd_loop.gd` | 426 | Core loop, data, economy, campaign contracts |
| `test_wyrd_dungeon_scene.gd` | 41 | Production World scene and dungeon construction |
| `test_wyrd_transitions.gd` | 125 | Town/World transitions and return ownership |
| `test_skills.gd` | 75 | Hotbar dispatch and Skill behavior |
| `test_boot_smoke.gd` | 147 | Script compilation and Town/World boot paths |
| `test_first_road_slice.gd` | 14 | Fresh 5–10 minute First Road promise |
| `test_movement_feel.gd` | 12 | Production keyboard movement, roll feel, and named-neighbor motion |
| `test_hollow_readability.gd` | 9 | Boundary-only living walls, complete-profile cutaway restoration, and budget |
| `test_first_hollow_room_grammar.gd` | 8 | Archetype determinism, variation, boundary truth, and combat apertures |
| `test_first_hollow_living_edge.gd` | 9 | Profile ownership, landmark count, deterministic remixing, and production realization |
| `test_web_tonal_separation.gd` | 4 | Web-only environment grade, native no-op, and forced production mutation seam |
| `test_first_hollow_forest_continuity.gd` | 8 | Forest-bed coverage, cutaway ownership, depth, and non-authority |
| `test_first_road_soft_ground.gd` | 5 | One-surface First Road soil morph and later-biome isolation |
| `test_first_road_open_canopy.gd` | 5 | Compact forest shoulder and wider opaque camera cutaway stage |
| `test_first_hollow_room_composition.gd` | 5 | Archetype-owned forest themes, focal realization, aperture safety, and biome isolation |
| **Total** | **893** | **Required before a checkpoint is accepted** |

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

The persistence-disabled retained corpus currently contains 125 direct
entrypoints. A strict 30-second-per-entrypoint audit passed 118; three known
long-running driver fixtures exceeded that artificial watchdog, while the
documented driver/repro and old movement exceptions remained. After updating
the obsolete snug-theme assertion, every retained test that loads the changed
composition seam passes. The production
dungeon, transition, boot, standalone movement, room, cutaway, and tonal-grade
gates remain green.

The repository also contains focused chapter, UI, authority, economy, save,
and regression entrypoints. They remain useful for their owning specs, but are
not silently counted as part of this compact checkpoint gate.
