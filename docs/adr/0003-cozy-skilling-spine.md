# Cozy-skilling is the spine; combat is one verb among many

A grill session on 2026-05-29 resolved the project's long-unstated identity. gj26 had been pulling in three directions at once — cozy OSRS-style skilling, New World gathering depth, and FATE/Diablo ARPG combat (the specs 30–43 roadmap) — with no doc saying which was the *spine* and which were seasoning. The core loop, "why it's fun," and "how it feels" were all undefinable until that was settled.

**Decision:** the spine is **cozy skilling**. You are a resident of Bramblewood; gather / cook / craft / chart are the heart of the game; combat is **one verb among many** (the OSRS model — it matters, but you are not primarily a fighter). The ARPG roadmap (specs 30–43) is hereby re-contextualized as *seasoning* — "satisfying real-time combat as one pillar," not "a Diablo-killer."

This is a decision about the game's center of gravity, **not** about the engine. The engine was already settled — Godot, decided 2026-05-20 (see project memory `project-godot-evaluation`), with a "port each three.js system as a minimum vertical slice" strategy. The grill re-confirmed Godot (the user's stated reason: it's the engine they'll *sustain* — and a solo project dies from motivation drain before technical cost). So nothing about the engine changes; this ADR records the identity call that the engine decision was missing.

**Supporting commitments** (downstream of the spine):
- **three.js `src/` is the design prototype**, not a port target. Its value is the *decisions and data* — item defs, recipes, skill curves, NPC dialog, and the ~49 files of cartography design — which are engine-agnostic. Port the decisions/data; reimplement logic in GDScript.
- **Vertical-slice-first.** Build one complete, *fun* loop end-to-end before widening. The first slice is **gather → cook → sustain → fight**: it's the smallest complete loop, leverages what Godot already has (hearth, combat, inventory), and the only net-new is the spec-37 channel-gather + one forageable + one fishing spot.
- **Cartography is the differentiator** and the meta-loop, but it is *slice 2*, not slice 1 — you lead with the smallest fun loop, then layer the unique hook on a working base.

## Considered options

- **ARPG spine** (combat is the core; skilling feeds the build). Rejected — most competitive genre, the hardest feel to nail (a full session on locomotion barely scratched it), and it would make cartography — the one genuinely novel system — secondary to a derivative combat loop.
- **Co-equal hybrid** (New World model; both deep, loop alternates town ↔ dungeon). Rejected — it is effectively two games; the highest scope and risk for one developer.
- **Cozy-skilling spine.** Accepted — it is the most-built side (three.js maturity), the most differentiated (cartography), and the most achievable solo. Combat still feels good without being the point.

## When to revisit

Re-open this decision if:
- The gather→cook→sustain→fight slice *fails the "is it fun?" playtest* — the spine doesn't earn its place and combat (or something else) is doing the real work.
- Combat consistently playtests as more compelling than skilling and is what pulls the player back — the center of gravity may actually be elsewhere.
- Scope forces dropping cartography — without the differentiator, the whole cozy-skilling thesis needs re-evaluation.
