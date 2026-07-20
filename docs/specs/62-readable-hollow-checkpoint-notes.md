# Spec 62 implementation notes — Readable Hollow

## Decision record

The old camera test cast one ray through the player. It missed walls that filled
the play area without crossing that exact line, so apparently valid geometry
could hide both the ranger and the pressure encounter.

The first replacement faded those walls. That exposed black, floorless cells
behind procedural wall tiles and failed the visual review. The accepted version
keeps the wall opaque and lowers only its mesh to a short boundary while it
overlaps a 350×290-pixel protected aperture around the player. Collision and
the authored layout never change.

Wall candidates are cached per World camera. The check projects each wall's
top and bottom into screen space, rejects walls outside the camera-to-player
depth interval, and restores every prior cut when the relationship clears.

## Verification

- `test_hollow_readability.gd`: 5/5
- Eight-suite canonical native gate: 841/841
- Export audit: 111/111 required D6–D8 resources; PCK 105,755,040 bytes
- Chromium compact route: passed in 11,369 ms; empty diagnostic ledger
- Target viewport: 1280×720 native capture and exported-browser canvas

The browser monitor gained an explicit `--begin` option. It clicks the real
lower-centre New Journey control instead of calling a Godot transition seam,
so the compact route can remain faithful to the shipped front door.
