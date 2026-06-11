# Implementation notes — 27a-item-data

## Decisions
- **Stat keys** locked as the spec lean: `hp · damage · crit_chance · crit_mult · fire_rate · move_speed`. 27e will consume these.
- **2 uniques** (the spec lean): `shortbow → "Whispering Yew"`, `leather_helm → "Coatcap of the Bramble"`. Trivially expandable in the `UNIQUES` dict.
- **Item sizes** as the spec lean: weapon 2×4, helmet 2×2, chest 2×3, boots 2×2, ring 1×1. 27c will lay these out.
- **Affix value precision** — hp/damage rounded to int; fractional stats (`crit_chance`, `crit_mult`, `fire_rate`, `move_speed`) snapped to 0.01. Keeps tooltips clean.
- **format_affix** uses PoE-style readout: `+12 Maximum Health`, `+5% Critical Strike Chance`, etc. — 27f tooltips will call this.

## Deviations
- **Unique fallback** — if a unique-tier roll lands on a kind without a `UNIQUES` entry, the item gracefully downgrades to `rare` (3 affixes) rather than erroring. So adding new kinds without writing uniques for them all is safe.

## Tradeoffs
- **Tier roll = `min(d10, d10)`** for the base + role/depth bias on top — gives a clean dropoff curve (≈75/21/3/1 normal/magic/rare/unique at combat depth 0) without authoring a weighted lookup table. Verified by I6.
- **Affix dedup** — `roll_affixes` doesn't de-duplicate by *stat*, so a rare item can roll e.g. `Hardened` (+hp) and `of Vigor` (+hp). 27e will sum them — same as PoE behaviour.

## Surprises
- The familiar `var ok := count.normal > …` parse error — Dictionary access returns Variant so `:=` can't infer. Same fix class as spec 25 (`var ok: bool = …`).

## Followups
- **More uniques** — 2 is a starter; the UNIQUES dict is the only place to extend.
- **More item kinds** — currently 6 (2 weapons + 3 armor + 1 ring); 27c will benefit from more variety once it can render them.
- **Deterministic RNG for evals** — uses the global RNG; threading a seeded `RandomNumberGenerator` through `roll_affixes`/`roll_drop` would make I6's distribution reproducible. Not blocking; the I6 thresholds are loose enough.

## Status
COMPLETE — items + affixes + drops as pure data; `test_items.gd` **7/7**; `test_combat.gd` **21/21**, `test_movement.gd` **6/6** still green. Foundation ready for 27b (ground pickup).
