---
name: spec
description: Implement a spec file at the given path. Maintain a running implementation-notes markdown file alongside the spec that captures decisions made outside the spec, deviations, tradeoffs, and other facts the user should know about the implementation.
---

# /spec — implement a spec file

You will be passed a spec file path as the argument (e.g. `/spec docs/specs/01-crypt-assets.md`). Your job is to read it, implement it, and keep a running notes file with everything the spec didn't fully nail down.

## 1. Read the spec

Open the spec file and read it in full. The spec describes the outcome — what to build, what files to touch, what success looks like.

## 2. Implement it

Do the work. Edit code, create files, run commands. Follow the conventions in `AGENTS.md` and project memory. Use `TaskCreate` if it has 3+ discrete steps.

## 3. Maintain implementation notes

Alongside the spec file (same folder, filename `<spec-stem>-notes.md`), maintain a running markdown file capturing anything that wasn't fully nailed down in the spec. This is **not** a redo of the spec — it's the delta.

**Goes in notes:**
- **Decisions** you had to make that weren't explicit in the spec (e.g. "spec said 'inventory UI', I went 4×7 since AGENTS.md mentions 28-slot")
- **Deviations** — things you did differently than asked, and why
- **Tradeoffs** weighed (option A vs B, why you picked one)
- **Surprises** — discoveries the spec author probably didn't know
- **Followups** — work the spec didn't cover that should happen later

**Does not go in notes:**
- Restating the spec
- Generic narration of what you did (the diff shows that)
- Internal deliberation that didn't lead to a decision

## 4. Format

Sections: `Decisions`, `Deviations`, `Tradeoffs`, `Surprises`, `Followups`. One short headline per entry, supporting detail beneath if needed. Example:

```markdown
# Implementation notes — 01-crypt-assets

## Decisions
- Picked variant v2 for `bones` over v0 — v0's skull was off-centre and clipped the floor tile.
- Skipped Meshy on `rug-v2` — it's flat enough to use directly as PlaneGeometry material.

## Deviations
- Spec said 16 GLBs; landed 15. `archway-v3` had inverted normals after cleanup. See Followups.

## Tradeoffs
- `clean_ai_mesh.py --tris 6000` on `chest` produced a too-faceted lid; bumped to 8000. Larger file, cleaner silhouette.

## Followups
- Rebuild `archway-v3` once the normal-flip cause is found in the Blender script.
```

## 5. Update notes incrementally

Append entries as you make each decision — not all at the end. If you later change a decision, edit the existing entry (don't add a "changed my mind" line).

## 6. Reporting

When done, give the user a concise summary:
1. What was built (1–2 sentences).
2. The notes file path.
3. The top 3 entries from notes they should look at.
