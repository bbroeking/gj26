# Wayfinder System Plans

Forward-looking **build & expansion plans** for the Wayfinder game — one note
per combat skill and per game system. This is the *"what's next"* layer of the
project's docs.

> **This folder is checked into a public repository.** Keep it free of secrets,
> internal-only credentials, and anything you would not want a player to read.
> The notes are design intent, not implementation handoffs.

## How to use this vault

- **In Obsidian:** open `docs/system-plans/` as a vault (or open the repo root
  as a vault and navigate here). The `[[wikilinks]]` between notes resolve
  natively, and the graph view will show the system dependency web.
- **As plain Markdown:** start at **[index.md](index.md)** — the Map of Content.
  It groups every note by domain with a status badge and a one-line hook, ranks
  the top build priorities, and indexes notes by status.
- **For the dependency picture:** open **[system-map.md](system-map.md)** for a
  Mermaid graph of how the systems link to each other.

## Naming convention

| Prefix      | Meaning                          | Example                     |
|-------------|----------------------------------|-----------------------------|
| `skill-*`   | A single hotbar combat skill     | `skill-power-shot.md`       |
| `system-*`  | A game system / subsystem        | `system-charts-wayfinding.md` |

File names are kebab-case and match the note's wikilink target exactly (the
link `[[system-bosses]]` points at `system-bosses.md`).

## Note template

Each plan note follows the same shape so they stay scannable:

- **Frontmatter / header** — title, domain, type (`skill` / `system`), status
  (`complete` / `partial` / `stub`), effort estimate.
- **Hook** — one paragraph: what's shipped and what the single most valuable
  next step is.
- **What exists today** — the shipped reality (cross-references `kb/` for depth).
- **Top gaps** — the prioritized list of missing/weak pieces, each anchored to a
  concrete file:line or a `Plan.md` feel-beat where possible.
- **Expansion roadmap / next steps** — the forward plan.
- **Links** — `[[wikilinks]]` to related skills and systems.

## How this relates to the other docs

- **`Plan.md`** (repo root) owns the cross-cutting *combat-feel* and *loop-feel*
  passes (the "B0–B7" beats). Notes here defer to it for shared feel work.
- **`kb/`** is the *"what exists"* design wiki — the reference layer. These plans
  are the roadmap layer.
- **`docs/adr/`** holds the decisions these plans build on (ADR 0003, 0012, 0013).

When you finish a plan's work, update its **status** badge here and reflect the
shipped reality back into `kb/`.
