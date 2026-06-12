# Spec 43 — The Experiment: ink-recipe discovery at the bench

Adapts the discovery loop from `docs/cartography-inscribing-table-design.md`
(the prototype-era design whose headline win was "recipes hide behind
experimentation") to the shipped Godot Crafting Bench. The 3×3 spatial
grid is NOT ported — the bench's mixing pot (quantity recipes) stays; the
new layer is **discovery as the verb**.

## Contract

1. **Ink recipes start unknown.** A fresh save knows only Hedge Ink
   (Mara's everyday ink — keeps tutorial step 2 intact). Stoneground,
   Refined, and two NEW inks must be found.
2. **The pot auto-mixes only discovered recipes** (today's behavior,
   now gated). An undiscovered exact match does nothing on drop.
3. **"Try the Mix"** — a button by the pot, the risky verb:
   - exact match, undiscovered → **discovery**: ink produced, recipe
     learned forever, +50 Wayfinder xp, gold bloom + toast.
   - exact match, discovered → mixes (same as auto).
   - no match → pot consumed (one of the cheapest makings handed back),
     +5 Wayfinder xp ("each smudge teaches"), then 60% **smudge**
     (nothing), 30% **wild ink** (a random common settles out), 10%
     **serendipity** (a bottle of an undiscovered ink — item only, the
     recipe stays unknown).
4. **Codex strip on the bench** (under the pot): one line per recipe —
   discovered `● Name — recipe`; hinted `◌ ??? — <NPC riddle>` (riddle
   unlocks when the matching first-time hint has been seen); unknown
   `◌ ???`.
5. **Two new inks** widen the space and bias the wave-2 affixes:
   - **Ash Ink** — 2 logs + 1 wild herb; biases wood_grove ×2.5,
     sprinter ×1.8. Riddle via the log_pile hint.
   - **Chalkwash Ink** — 1 palechalk + 2 wild herb; biases wellspring /
     echoing / marked_quarry ×1.8. Riddle via Quill's still hint.
6. **Persistence**: `discovered_inks` rides the save. Pre-43 saves
   backfill all three original inks (never regress a save).
7. Tray gains logs + palechalk as pot-draggable materials; zero-count
   ink/material rows hide to keep the tray inside the panel.

## Files

`wyrd/data/gather.gd` (recipes + riddles + materials), `wyrd/data/charts.gd`
(INKS bias entries), `wyrd/scripts/game.gd` (discovered_inks, discover_ink,
try_pot_mix), `wyrd/scripts/save_game.gd` (persist + migrate),
`wyrd/scripts/ui/crafting_bench.gd` (pot gate, pot_try, Try button, codex
strip, outcome blooms), tests in loop + transitions suites.

## Done when

- Fresh game: 2 ore in the pot does NOT auto-mix; Try discovers
  Stoneground (+50 carto, ink in satchel) — headless-tested.
- A junk pot resolves to smudge/wild/serendipity with the consolation
  and +5 carto — headless-tested.
- Discovery survives save/load; old saves keep their three inks.
- All 3 suites green.
