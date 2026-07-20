# gj26 — Bramblewood ARPG

A cozy fairytale Godot 4.6.2 ARPG set in Bramblewood. Toon-shaded low-poly visuals, a 4-skill hotbar + Focus resource, a status-effect framework, and themed procedural dungeons with typed-room contracts (combat / treasure / shrine / rest). NOT OSRS, NOT Diablo grimdark — storybook flavour with Diablo/PoE-shaped mechanics.

## Language

**Pickup**:
An item lying in the world that the player can pick up. Spawned by drops (combatant deaths) and chests (treasure rooms). Visually a glowing beacon + a rarity-coloured floating label; an Area3D on the pickup layer so the player's PickupScanner detects it. The single seam through which loot enters the player's inventory.
_Avoid_: GroundLoot, GroundItem, DroppedItem, WorldItem.

**Skill**:
A player-usable ability bound to a hotbar slot. Carries cost (Focus), cooldown, and a list of SkillEffects applied on hit. Slot 1 is always BasicShot; slots 2–4 are picked from the pool (PowerShot, MultiShot, BrambleSnare, PiercingBolt, RainOfThorns, Thornburst, HuntersMark, HeartwoodWard, MercyShot — the deeper hunting verbs gate on Huntcraft level). Lives in `scripts/skills/`.
_Avoid_: ability, spell, attack. Never use Skill for a leveling discipline — that's a **Trade**.

**Trade**:
An independently levelled discipline. Wayfinding, Earthcraft, Wildcraft, and Huntcraft each run from level 1 through 23 and own the XP earned through their verbs.
_Avoid_: skill (reserved for hotbar abilities), stat, profession.

**Wayfinding**:
The Trade of discovering routes, learning Chart Recipes, inscribing Charts, reading Affixes, restoring the Living Atlas, and turning chapter clues into Boss Charts.
_Avoid_: Cartography, carto, mapmaking skill.

**Chart**:
A crafted route that opens one dungeon run. Its Chart Recipe determines the destination and route shape; its inks shape the Affix odds. A Chart is inscribed at the Chart Table and consumed by the Waystone on entry.
_Avoid_: map (overloaded), orb, keystone (flavor, not identifier).

**Chart Table**:
Mara's Wayfinding station. The player places a Chart Base, Waymark, Binding, inks, and an optional Seal into a learned arrangement; the arrangement chooses the Chart's destination and shape while the inks shape its Affix odds.
_Avoid_: Creation Table, Crafting Bench, Inscribing Table.

**Chart Recipe**:
A discoverable arrangement of components at the Chart Table that deterministically produces a Chart family. A recipe determines where the Chart leads and what route it draws, not the final good/bad Affix rolls.
_Avoid_: Formula, blueprint, crafting menu entry.

**Affix**:
A chart property with a good twin and a bad twin, resolved by a stability roll at inscribe time. Bias affixes spawn GatherNodes; modifier/pacing affixes change combat math; boss affixes put a boss in the deepest room. Only affixes with implemented effects appear in `Charts.AFFIXES` — the preview must never promise what the run can't deliver.
_Avoid_: modifier (overloaded with elite modifiers), property, mod.

**GatherNode**:
An Interactable resource node (ore_rock / forage_node / log_pile). One E-press harvests: a material into the satchel + trade XP. Dungeon nodes deplete for the run; town herb patches regrow.
_Avoid_: resource, spawn, vein (that's an affix name).

**Waystone**:
The travel stones. The town Waystone sockets a chart and starts the run; the exit waystone inside a dungeon ends it (completion XP, return to town). In a boss chart the exit waystone rises only when the boss falls. An **abandon stone** always stands at the dungeon entry — stepping through it ends the run with no completion reward (the chart stays spent).
_Avoid_: portal, gate (the boss arena's seals are gates).

**Satchel**:
The keyed, stackable materials inventory (`Game.materials`, id → count) — herbs, ores, logs, inks. Separate from the Tetris gear Inventory by design: gear and reagents are different verbs.
_Avoid_: pouch, bag, materials-inventory.

**SkillEffect**:
The on-hit consequence of a Skill (e.g. apply burn, apply snared, apply bleed). Carried by the projectile and applied to the hit target at impact. v1 effects all apply statuses via Combatant.apply_status.
_Avoid_: on-hit, ailment-data.

**HitFeedback**:
The system that fires the 6 visual/audio channels (flash, knockback, hitstop, hit-spark, camera shake, SFX) when a Combatant takes a hit, plus a soft mesh-tint pulse when a status DoT ticks. Static module; tier-keyed tunables in one place.
_Avoid_: impact-effect, hit-react.

**Interactable**:
A world object the player presses E to engage. Single-use (Chest, Shrine) or multi-use (Hearth). Spawned by typed-room contracts (spec 29). Detected via INTERACT_LAYER + the player's InteractScanner. Base class owns Area3D + collision sphere + prompt Label3D; subclasses override hooks (`interact`, `is_used`, `get_prompt_text`, `get_prompt_color`, `_ready_interactable`).
_Avoid_: triggerable, usable, prompt-target.

**Elite**:
A Combatant promoted at spawn-time with one of four storybook modifiers (Brambled, Swift, Sunlit, Briarbound) that bump HP, scale, and tint, and dispatch per-modifier behaviour (death-nova bleed, faster movement, melee burn-pulse, CC-immunity). Travels with 2–3 same-kind trash as retinue. Drops loot at the new `"elite"` tier (magic-leaning floor, above combat, below treasure). One elite per combat room maximum.
_Avoid_: champion, rare, modifier (the last one is overloaded with status/affix).
