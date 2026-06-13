# raw/ — new external sources

This KB's primary raw sources live **in place** in the game repo (`../docs/`,
`../docs/specs/`, `../docs/adr/`, `../CONTEXT.md`, and `../wyrd/` code) — they're
the source of truth and are never duplicated here. See [`../CLAUDE.md`](../CLAUDE.md).

Drop **new external** sources in this folder when you want them in the wiki:
reference articles (Obsidian Web Clipper → markdown), competitor/genre analysis,
research papers, inspiration boards, transcripts. Then tell the LLM to ingest
them. They're immutable once here — the LLM reads, never edits.
