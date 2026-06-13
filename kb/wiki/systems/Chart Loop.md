---
type: system
tags: [chart-loop, core-loop, wayfinding, dungeon, progression]
status: draft
updated: 2026-06-13
sources: ["docs/cartography.md", "docs/cartography-systems.md", "docs/cartography-keystone-design.md", "docs/cartography-progression.md", "wyrd/data/charts.gd"]
---

# Chart Loop

The chart loop is Wayfinder's primary progression engine: gather materials → mix inks → inscribe a chart at [[The Crafting Bench]] → delve the resulting hollow → return with loot, trophies, and Wayfinder XP, then repeat at escalating tiers up to the Summit endgame.

## The core cycle

```
gather materials
      ↓
mix inks at the bench's mixing pot
      ↓
inscribe chart (place base + slot inks + optionally slot trophy)
      ↓
enter hollow via [[The Waystone]]
      ↓
fight through → loot chest → exit
      ↓
Wayfinder XP + materials + possible trophy drop
      ↓
(repeat with higher tier or different affixes)
```

The differentiating verb is **inscription**: a chart is not bought or found — it is hand-crafted. The inks slotted at the bench bias which [[Affixes]] appear; the player is gambling with weighted dice of their own making.

## Chart templates and tiers

Five templates are active in code (`wyrd/data/charts.gd`):

| Template | Tier | Req Wayfinder | Affix slots | Notable cost |
|---|---|---|---|---|
| Snug | 1 | 1 | 0 | 1× hedge ink |
| Tier 1 Hollow | 1 | 1 | 1 | 2× hedge ink |
| Hollow | 2 | 10 | 2 | 3× hedge ink |
| Briar Maze | 2 | 15 | 2 | 3× hedge ink |
| Chart of the Summit | 3 | 16 | 0 | 4× hedge ink + 1× refined ink + 1× alpha fang |

The Summit is the endgame keystone — its boss (the Hedgemother Queen) cannot be reached until the trophy chain has been completed through the preceding boss dens.

## XP and completion formula

Completing a chart awards Wayfinder XP. The shipped formula (`wyrd/data/charts.gd::completion_xp`):

```
xp = tier × 75 + good_affixes × 40 + bad_affixes × 10
```

If the Tyrannical affix resolved to its good twin, the total is multiplied by 1.3. A Tier 1 chart with one good affix yields 115 XP; a Tier 2 with both good affixes yields 230 XP. Bad twins still pay some XP — a botched roll is still a lesson.

> ⚠️ Design docs (`docs/cartography-keystone-design.md`) state an older formula: `tier × 30 + good × 25 + bad × 5`. Shipped code (`completion_xp`) uses `tier × 75 + good × 40 + bad × 10`. Code wins.

## Wayfinder leveling unlocks

Each Wayfinder level unlocks new chart templates, inks, or vision abilities. Key milestones from `docs/cartography-progression.md`:

- **Lv 1** — Snug + Tier 1 charts; Hedge Ink + Charcoal Bind
- **Lv 10** — Hollow chart (Tier 2, 2 affix slots)
- **Lv 15** — Briar Maze
- **Lv 16+** — Refined, Bog, Lustrous, Ember inks unlock in sequence
- **Lv 30** — Delve template (design-stage only; not yet in shipped code)
- **Lv 60** — Summit chart + Tideink

## The trophy chain

Boss dens are not random affix rolls — they are inscribed by slotting a boss trophy at the bench. Killing the Hedgemother drops `thorn_essence` → slotting it inscribes a `hedgemother_den` chart. That boss drops `tusker_tusk`, and so on up to the Summit. This is the game's primary vertical progression spine.

## Living Atlas (macro-loop)

Every chart completed also ticks a region counter in the Living Atlas. Completing enough charts in a region unlocks a new walkable biome. Atlas state persists to `localStorage[gj26.atlas.v1]` (prototype code) / save file (Godot). This layer turns individual chart runs into a persistent world-expansion arc. See `docs/cartography-systems.md`.

## See also

- [[Charts]] — what a chart is as an item (template, seed, affix list)
- [[Affixes]] — the good/bad twin system that makes each run different
- [[Inks]] — how inks bias the affix roll
- [[The Crafting Bench]] — the physical station where charts are inscribed
- [[The Waystone]] — how a finished chart becomes an enterable dungeon
- [[Dungeon Generation]] — what the generator does with the chart's parameters
- [[Wayfinding]] — the Trade that governs the skill
- [[Gathering]] — supplies the raw materials the loop consumes
- [[Bosses]] — the trophy chain and what each boss drops

## Sources

- `docs/cartography.md`
- `docs/cartography-keystone-design.md`
- `docs/cartography-systems.md`
- `docs/cartography-progression.md`
- `wyrd/data/charts.gd`
