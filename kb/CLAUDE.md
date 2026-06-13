# Wayfinder Knowledge Base — schema

This directory (`kb/`) is an **LLM Wiki**: an interlinked markdown knowledge
base over the design of **Wayfinder** (the cozy fairytale dungeon-crawler in
`../wyrd/`). It follows the pattern in [`LLM-WIKI-PATTERN.md`](LLM-WIKI-PATTERN.md).
**You (the LLM) own and maintain every page under `wiki/`. The human reads it in
Obsidian and directs the work — they rarely edit pages by hand.**

This file is the **schema**: how the wiki is structured, the conventions, and
the workflows. Co-evolve it as the wiki grows.

## The three layers

1. **Raw sources — read-only, IN PLACE.** Unlike a generic LLM Wiki, this KB's
   sources already live in the game repo and are the source of truth:
   - `../docs/` — design docs, `WORLD_BIBLE.md`, `WORLD_LORE.md`, `DESIGN_VISION.md`,
     pipeline docs, playbooks, `wyrd-roadmap.md`.
   - `../docs/specs/` — 60+ per-feature specs (`NN-title.md`) + `-notes.md` deltas.
   - `../docs/adr/` — architecture decision records (the load-bearing "why"s).
   - `../CONTEXT.md` (domain glossary), `../CLAUDE.md` (project instructions).
   - The code in `../wyrd/scripts/` + `../wyrd/data/`, and git history.
   **Never edit these from the KB.** `kb/raw/` is reserved for *new external*
   sources you ingest later (reference articles, competitor analysis, research).

2. **The wiki — `kb/wiki/`.** LLM-generated interlinked pages. You own it.
   - `wiki/world/` — Bramblewood, lore, voice & tone.
   - `wiki/systems/` — the loops and machinery (chart loop, gathering, crafting,
     trades/leveling, combat, dungeon generation, economy, multiplayer, saves).
   - `wiki/entities/` — concrete game things (the four trades, charts, affixes,
     inks, skills, bosses, enemies, items/gear, gather nodes, NPCs).
   - `wiki/decisions/` — digest of the ADRs (the surprising, hard-to-reverse calls).
   - `wiki/pipeline/` — how art/assets/anim/code get made (Godot, Blender, Meshy…).
   - `wiki/sources/` — per-cluster source digests: which raw docs were read, a
     one-line summary of each, and what wiki pages they fed.

3. **The schema — this file** (`CLAUDE.md`; `AGENTS.md` points here for Codex).

Navigation files at the vault root: `index.md` (content catalog) and
`log.md` (chronological journal).

## Page conventions

- **Filenames are Title Case with spaces**, matching the page's display title:
  `wiki/entities/Charts.md`, `wiki/systems/Chart Loop.md`. This makes Obsidian
  wikilinks read naturally.
- **Cross-reference with Obsidian wikilinks:** `[[Charts]]`, `[[Affixes]]`,
  `[[Wayfinding|the Wayfinder trade]]` (alias after `|`). Link liberally —
  a `[[Page]]` whose target doesn't exist yet is fine; it marks a page worth
  writing. Aim for a densely connected graph, not islands.
- **Every page starts with YAML frontmatter:**
  ```yaml
  ---
  type: world | system | entity | decision | pipeline | source | overview
  tags: [trade, progression]      # lowercase, kebab; for Dataview/graph
  status: stub | draft | maintained
  updated: 2026-06-13              # ISO date; pass dates in, don't invent
  sources: ["docs/cartography.md", "docs/specs/42-chart-crafting-ui.md"]
  ---
  ```
- **Structure of a page:** H1 title → one-sentence definition → body with
  sections → a `## See also` list of wikilinks at the end → optionally
  `## Sources` listing the raw docs it draws from (repo-relative paths).
- **Cite the source.** When a claim comes from a specific doc/spec/ADR, name it
  (`docs/specs/45-trade-ladders-earth.md`) so provenance is traceable.
- **Code is the tiebreaker.** When a doc disagrees with `../wyrd/` code, the code
  wins for "what the game does today"; note the doc as design intent. Flag the
  contradiction explicitly on the page (`> ⚠️ Doc says X; code does Y as of <date>.`).
- **Use the project's language** (`../CONTEXT.md`): a leveling discipline is a
  **Trade**; "Skill" = hotbar abilities only; **Chart** not map/keystone;
  **Affix** good/bad twins; **GatherNode** kinds. Player-facing prose follows the
  `WORLD_BIBLE.md` voice; this wiki is internal/analytic, so plain is fine.

## Operations

### Ingest (add knowledge)
1. Read the source (a raw doc, a spec, code, or a new file dropped in `kb/raw/`).
2. Decide which wiki pages it touches — usually several. Create or update them:
   integrate the facts, add cross-links, and flag contradictions with existing
   pages rather than silently overwriting.
3. Update `index.md` (add/adjust the page's catalog line).
4. Append a `log.md` entry: `## [YYYY-MM-DD] ingest | <source>` + 1–3 bullets on
   what changed.
5. Prefer touching many pages in one pass over leaving stale cross-references.

### Query (answer questions)
1. Read `index.md` first to locate relevant pages, then drill in (use `rg` over
   `wiki/` for keywords).
2. Synthesize an answer **with citations to wiki pages** (and raw docs where it
   matters).
3. If the answer is durable (a comparison, an analysis, a discovered connection),
   **file it back** as a new `wiki/` page and catalog it — don't let it die in chat.
4. Rich outputs (tables, Marp slides, charts) go in `kb/outputs/`; file the
   useful ones back into `wiki/`.

### Lint (health-check)
Periodically scan for: contradictions between pages; stale claims a newer spec
or the code superseded; orphan pages (no inbound `[[links]]`); concepts mentioned
but lacking a page; missing cross-references; gaps worth a new source. Write
findings to `kb/wiki/_lint_report.md` and propose next questions/sources.

## index.md and log.md

- **index.md** — content catalog. One line per page: `- [[Page]] — one-line summary`.
  Grouped by category (World, Systems, Entities, Decisions, Pipeline, Sources).
  Update on every ingest. It's the entry point for queries.
- **log.md** — append-only, chronological. Consistent prefix so it greps:
  `## [YYYY-MM-DD] ingest|query|lint | <subject>`. Newest at the bottom.

## Tools

- **Obsidian** is the human's frontend; this `kb/` dir is a registered vault.
  CLI: `obsidian ls` (list vaults), `obsidian open <path>` (register/open).
- **Search:** `rg -n "<term>" kb/wiki` is enough at this scale. If the wiki
  outgrows it, add `qmd` (on-device BM25+vector search over markdown) — see the
  pattern doc's "Optional: CLI tools".
- **Dates:** today's date is provided in context; pass it into frontmatter/log.
  Never fabricate dates.

## Scope note

This is a *living design wiki*, not the spec system. Specs (`docs/specs/`) are
the immutable per-feature contracts; this wiki is the synthesized, navigable map
across all of them — the thing you read to understand how Wayfinder fits together.
