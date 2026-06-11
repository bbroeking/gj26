# InventoryController extraction deferred until a second view exists

The `improve-codebase-architecture` review on 2026-05-26 (candidate #6) proposed extracting an `InventoryController` from `scripts/inventory_panel.gd` to hold cross-cutting state (drag, `try_equip`) and let the panel become a pure view. We considered it and deferred — today's panel works, and a single caller (the player's one inventory UI) is a hypothetical seam, not a real one. The deepening pays off when a second view (vendor, trade, bank) creates the second adapter that justifies the seam; until then it's speculative.

## Considered options

- **Extract InventoryController now.** Rejected — one-adapter = hypothetical seam (per the `improve-codebase-architecture` LANGUAGE.md principle); refactoring before the second view risks getting the shape wrong and re-refactoring later.
- **Minimal: extract just `try_equip` to a static helper.** Rejected — 80% of the value, 10% of the work, but adds a second place to look for inventory logic without solving the cross-cutting state problem.
- **Defer entirely until vendor lands.** Accepted — the panel works, and the trigger to revisit is well-defined (a second view appears, e.g. spec 37 vendor).

## When to revisit

Re-open this decision when:
- Spec 37 (vendor) or similar adds a second view that needs Inventory + Equipment + cross-cutting invariants.
- A multiplayer/serialization spec needs a serializable inventory state separate from the UI.
- The panel's drag state becomes a bottleneck for unit-testing inventory rules.
