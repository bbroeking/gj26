# Debug Protocol — Living Fix Log

OpenGame's "Debug Skill": every time we hit an integration bug, append a structured entry. Future-self reads this list before debugging similar issues.

Entry format:

```
### [yyyy-mm-dd] short title
**Symptom:** what broke
**Root cause:** why
**Fix:** what we did (commit hash if relevant)
**Prevention:** check before reintroducing
```

---

## Pre-execution validations (run these as habit)

- [ ] Every `SPR.*` is exactly 16×16 — run sprite validator after edits
- [ ] Every map row in `data/map.txt` is exactly 40 chars — run map validator
- [ ] Every imported module path matches actual file (ES modules are case-sensitive on some OSes)
- [ ] `data/items.js` IDs referenced by code exist in the registry
- [ ] No circular imports between `game/*` modules

---

## Known fixes (carried from v1 lessons)

### [v1] Sprite asymmetry caused offset rendering
**Symptom:** A sprite drew shifted left of its tile.
**Root cause:** Char grid had asymmetric dot padding (e.g. `..0M` vs `0M..`).
**Fix:** Recount leading vs trailing dots; aim for symmetry.
**Prevention:** Sprite validator counts row length, not symmetry — eyeball when the design is centered.

### [v1] Goblins blocked themselves on respawn
**Symptom:** Goblin respawn point already had a different goblin → tile blocked.
**Root cause:** Multiple respawns to the same `(homeX, homeY)`.
**Fix:** Check `isBlocked` before placing the respawned mob; otherwise wait one tick.
**Prevention:** Always re-check blocked state when reactivating dormant entities.

### [v1] Click target consumed mid-step
**Symptom:** Click on tree did nothing if player was still tweening between tiles.
**Root cause:** `clickTarget` consumed unconditionally each frame.
**Fix:** Defer consumption: `if (pendingInteract && !player.moving)`.
**Prevention:** Same rule for any queued action — don't process while transitioning grids.

### [v1] Camera-aware draw missed for HUD overlays
**Symptom:** Quest `!` marker drifted as camera moved (drew in screen coords inside translated context).
**Root cause:** `ctx.translate(-camera.x, ...)` wraps everything inside `ctx.save/restore`; world-coord draws are correct, but they're inside the wrap.
**Fix:** All world-coord draws inside the translate block; HUD outside (or use absolute coords).
**Prevention:** Draw order: `tiles → entities → particles → world FX (inside translate) → HUD (outside translate)`.

---

## v2 entries (append as we ship)

(none yet)
