# 47 — Enchants (skills-on-items) — implementation notes

Built 2026-06-23. A "skills on items like enchants" layer requested by the
owner: bind virtues — **charms** — into equipped gear at the **Charm Table**.

## Decisions (owner, 2026-06-23)
- **Both** kinds of payoff: gear takes passive/stat + on-hit charms; weapons
  also carry a skill-granting slot.
- **Mixed source**: common charms always bindable; rare charms discovered from
  elites; unique charms from bosses.
- **Swappable at the bench**: socket/unsocket freely, reagents cost per bind,
  no gear destroyed (unbind is free, no refund).

## Model
Charms live in a **separate `enchants: Array[String]` on the item dict**, never
touching the rolled `affixes` (which stay immutable — the clarity covenant).
Slot capacity is a property of the gear *category*, read by kind
(`Items.enchant_slots`): weapon 2, helmet/chest/boots/ring 1, tools 0.

Three kinds (`data/enchants.gd` → `EnchantData.ENCHANTS`):
| kind | engine hook | example |
|------|-------------|---------|
| `stat` | sums into `player._derive_stats()` like an affix | Keening +6% crit |
| `on_hit` | a `SkillEffect` appended to **every** shot in `ProjectileSkill._spawn_arrow` | Emberbind (Burn) |
| `skill_grant` | makes a hotbar skill slottable while worn | Galebrand → Galecall |

Tiers gate the *source*, not the slot: `common` always bindable; `rare`/`unique`
must be in `Game.discovered_enchants` first.

## Engine wiring
- **`Game` API** (`scripts/game.gd`): `enchant_available`, `known_enchant_ids`,
  `discover_enchant`, `granted_skills`, `available_skills`, `can_bind_enchant`,
  `bind_enchant`, `unbind_enchant`, `_refresh_after_enchant`, `_sanitize_loadout`,
  `_connect_equipment`. `GRANT_SKILLS` lists skills that exist *only* via a charm.
- **Loadout integration**: `set_loadout` validates against `available_skills()`
  (unlocked pool + granted). `equipment.changed` is connected to
  `_sanitize_loadout`, which drops any now-invalid pick (e.g. you unequipped the
  granting weapon) and backfills — closes the dangling-grant exploit.
- **Combat**: `player._derive_stats` folds equipped charms (stat → sums; on_hit →
  cached `_enchant_hit_effects`). `ProjectileSkill._spawn_arrow` does
  `arrow.effects = on_hit_effects + enchant_fx` (new array — never mutates the
  skill's shared list). Two granted skills added to `SKILL_FACTORY`:
  `Galecall` (galebrand, rare), `Wyrdvolley` (wyrdspark, unique).
- **Economy**: 3 reagents (`glimmerdust`/`emberglass`/`dewthread`) — craftable
  at forge/still (`data/crafting.gd`) and dropped while delving
  (`Drops.roll_reagents`). Elites teach rares, bosses teach uniques
  (`Drops.roll_enchant_discovery`), routed by `combatant._award_enchant_loot`.
- **Persistence** (`scripts/save_game.gd`): `discovered_enchants` is a new
  optional top-level field (default `[]`, backfilled — no VERSION bump). Item
  `enchants` round-trips via the existing deep-copy.

## UI
`scripts/ui/enchant_panel.gd` — the Charm Table modal (clones the loadout/vendor
kit). Left: enchantable gear; right: bound charms (click to draw out) + bindable
charms (click to bind, greyed when locked). Reachable in-world via the **Loadout
panel → "Charm gear ▸"** (Cottage Hearth in town, dungeon Hearth). Capture:
`WYRD_UI_SHOT=enchant` (added to `tools/capture_ui.sh`).

## Tests
`test_enchants.gd` (37 checks): shape, source-gating, stat sum, on-hit on a real
arrow, skill-grant slot + sanitize-on-unequip, capacity/category/availability/dup
gates, save round-trip. All six must-stay-green suites still pass. (`test_skills`
loadout count updated for the new still reagent recipe.)

## Adversarial review (2026-06-23) — fixed
- **Hotbar alignment**: `rebuild_skills` now substitutes a Bow + `push_error`
  when a loadout pick has no `SKILL_FACTORY` entry (was a silent array-shrink →
  slot/skills desync). Covered by `test_enchants [factory guard]`.
- **Save backfill**: `_migrate` backfills `item.enchants = []` on pre-spec-47
  items (matches the `discovered_inks` convention; consumers already used
  `.get`, so belt-and-braces).
- **Early-game reachability**: `dewthread` lowered to req_lv 1 so the gentlest
  charms are bindable from the start instead of a lv-2 dead-zone.

## Known follow-ups / non-goals
- **Co-op (the real gap — all single-player paths are correct + tested).** Guest
  player *puppets* on the host are built from the **host's** loadout/equipment,
  and `_net_cast` replays a guest's shot on that puppet. So a guest's:
  - **on-hit charms don't replay** — the puppet's `_enchant_hit_effects` reflects
    host gear, not the guest's (host is authoritative for damage, so the guest's
    burns/bleeds are simply missing — safe, not a crash).
  - **skill-grant picks can desync** — the puppet fires its own `skills[slot-1]`,
    built from the host loadout, not the guest's actual slotted skill.
  The naive "RPC the effects" fix is **wrong**: `SkillEffect` is a `RefCounted`
  and isn't RPC-serializable. A correct fix sends enchant **IDs** (or the guest's
  loadout) and rebuilds host-side, and/or syncs equipment — it belongs with the
  co-op goal ([[project_coop_goal]] / `docs/system-plans/COOP-GOAL.md`).
- **Co-op discovery**: `_award_enchant_loot` is skipped under live co-op
  (reagents are consumables needing per-player instancing like
  `NetGame.drop_event`; discoveries would need an RPC to reach the guest). Both
  faucets stay available offline; charms are also craftable, so no one is hard-gated.
- No dedicated Charm Table world prop yet — it rides the Loadout panel button.
- Balance is first-pass (on-hit DoT values deliberately light since they ride
  *every* shot); tune against ADR-0013 difficulty bands.
