# 27a — Item data + affix pool + drop tables

> The data foundation for the whole loot system. No UI, no nodes — just data and the `roll_drop()` function that turns an enemy death into a concrete item instance.

## Why

Everything keys off item data. 27b-f all consume the data model + the roll. Pinning this down first means later subspecs are pure UI/integration on a stable schema.

## Scope

**In:**

### A. Item kind catalogue (`godot/data/items.gd`)
- A dict of `KINDS` — each kind: `id` · `name` · `category` (weapon/helmet/chest/boots/ring) · `size` (Vector2i for the Tetris footprint, e.g. weapon = 2×4, helmet = 2×2, ring = 1×1) · `base_stat` (the kind's primary stat: weapon = damage, armor = HP, ring = +crit chance) · `base_value` (numeric) · `icon_color` (placeholder while we don't have icons).
- Starter set: 2 weapons (shortbow, longbow), 3 armor pieces (helmet, chest, boots — generic), 1 ring. ~6 kinds is enough to populate inventory + equipment.

### B. Affix pool (`godot/data/affixes.gd`)
- `PREFIXES` and `SUFFIXES` dicts — each entry: `id` · `display` (template like `"+%d HP"`) · `stat` (which derived stat it modifies — `hp / damage / crit_chance / crit_mult / move_speed / fire_rate`) · `value_range` (Vector2 min/max) · `tier_min` (only rolls on rare+ if needed).
- ~6 prefixes + ~6 suffixes for v1 — covers the main player stats. Document the schema so adding affixes is a one-line entry.

### C. Item instance
- Function `make_item(kind_id, rarity)` → a Dictionary `{kind, name, rarity, affixes: [{prefix_id, value}, ...], size, base_value}`.
- Magic = 1 affix, rare = 3, unique = predefined (we hardcode a few uniques as a stretch).
- Display name composes: `<prefix?> <kind name> <suffix?>` (Magic) or `<kind name>` (Rare uses tooltip-only affixes).

### D. Drop tables (`godot/data/drops.gd`)
- Per-enemy-role drop table: each role (combat/treasure/shrine/boss) → drop chance + a tier-weight roll.
- A `roll_drop(role, depth) -> Array[Dictionary]` returns 0..N item instances on a death. Depth biases the rarity weights upward.
- Boss returns at least one rare+ item.

### E. Tests (`test_items.gd`)
- A new headless eval harness: 1000 rolls — verify the rarity distribution is in expected ranges; verify magic has 1 affix, rare 3; verify boss always rare+; verify all kinds are reachable.

**Out:**
- Any UI, ground spawning, picking up, equipping, stats application. Those are 27b-e.
- Tradeable currency (gold beyond a placeholder kind).

## Files

| Path | Action |
|---|---|
| `godot/data/items.gd` | new — `KINDS` dict + helpers |
| `godot/data/affixes.gd` | new — `PREFIXES` / `SUFFIXES` dicts |
| `godot/data/drops.gd` | new — `TABLES` + `roll_drop()` |
| `godot/test_items.gd` | new — distribution evals |
| `docs/GODOT_PIPELINE.md` | mention the data dirs |

## Acceptance
1. `make_item(kind_id, "rare")` returns a valid item with 3 affixes from the pool.
2. `roll_drop("boss", 5)` always returns at least one item of rarity ≥ rare.
3. `test_items.gd` passes: distribution sane, schema correct.
4. `test_combat.gd` 21/21, `test_movement.gd` 6/6 still pass — pure data, no integration yet.

## Open decisions
- **Unique items** — count for v1. Lean: 2 (one weapon, one armor) — enough to feel them exist; expandable.
- **Stat keys** — exact list. Lean: `hp · damage · crit_chance · crit_mult · move_speed · fire_rate`. Player consumes them in 27e.
- **Size catalogue** — weapon 2×4 / helmet 2×2 / chest 2×3 / boots 2×2 / ring 1×1. Tunable in 27c.
