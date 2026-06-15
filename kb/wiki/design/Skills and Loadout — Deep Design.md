---
type: design
tags: [system-design, skills]
status: draft
updated: 2026-06-14
sources:
  - "kb/wiki/entities/Skills.md"
  - "kb/wiki/Universe Build-Out Plan.md"
  - "kb/wiki/concepts/Balance Philosophy.md"
  - "wyrd/scripts/player_controller.gd"
  - "wyrd/scripts/skills/skill.gd"
  - "wyrd/scripts/skills/projectile_skill.gd"
  - "wyrd/scripts/game.gd"
  - "wyrd/scripts/skill_bar.gd"
  - "wyrd/test_skills.gd"
  - "kb/wiki/games/roguelike/Hades II.md"
  - "kb/wiki/games/roguelike/Slay the Spire.md"
  - "kb/wiki/games/arpg/Path of Exile 2.md"
  - "kb/wiki/games/roguelike/Dead Cells.md"
  - "kb/wiki/games/mmorpg/Guild Wars 2.md"
---

# Skills and Loadout — Deep Design
> Forward-looking deep design. Current-state: [[Skills]]. Constrained by [[Universe Build-Out Plan]].

## Player fantasy & role in the cozy spine

You are a Wayfinder who hunts with a bow and a small repertoire of *learned hunting verbs* — never a spellcaster with a growing grimoire. The loadout is the **kit you pack before a delve**, like choosing which three tools fit your belt. Per [[Universe Build-Out Plan]] P8, combat is **one verb** deepened only by reading/response and *loadout opportunity cost*; the player fantasy here is "I picked the right three answers for what this run threw at me," not "I unlocked a bigger weapon." Skills sit *downstream* of the [[Gathering|spine]]: [[Huntcraft]] (leveled by every kill, everywhere — ADR 0005) gates the three deepest verbs, so combat capability is *earned by playing the loop*, never bought. This keeps the spine the heart (ADR 0003): you go delving to feed trades, and the loadout is how the delve answers back.

## What ships today (grounded in code)

The system is **already built and tested.** From `player_controller.gd`:

- A **4-slot hotbar.** Slot 1 is hardwired `BasicShot` (the Bow), free, also on `F` (bound in `_ready`). Slots 2–4 come from `Game.loadout` (`rebuild_skills()`, lines ~1317–1336).
- A **9-skill pool** (`game.gd::SKILL_POOL`). Three are Huntcraft-gated (`SKILL_REQS = {HuntersMark:4, HeartwoodWard:7, MercyShot:9}`); the rest open from the start.
- **Focus**, one regenerating resource (`FOCUS_MAX = 50`), regenerating slower in combat (`FOCUS_REGEN_IN 3` vs `OUT 10`) to force a spend rhythm. Slots 2–4 cost Focus; slot 1 is free.
- **Per-slot cooldowns** (`_skill_cooldowns`), reduced by the `cooldown_reduction` affix via `Skill.effective_cd()`, **capped at `CDR_CAP = 0.80`**. Slot 1 instead scales off `fire_rate` (`BasicShot.effective_cd` overrides to read `fire_cooldown`) — the deliberate spec-30 split.
- **Modular skills:** each is a `Skill`/`ProjectileSkill` subclass in `scripts/skills/`; the player only dispatches via `_try_skill(slot)` (lines ~816–834). `set_loadout()` (`game.gd` ~239) validates *exactly 3, no dupes, gates met* and calls `rebuild_skills()`, which **re-seeds** the cooldown keys (a bare `clear()` once unkeyed the slots and froze the game — the regression `test_skills.gd` guards).
- The **SkillBar HUD** (`skill_bar.gd`) builds lazily from the live `skills` array, with painted icons / inked-glyph fallbacks, costs, and hover tooltips — combat is explained where the buttons live.

What's thin today: there is **no loadout-swap UI surface** (it's `set_loadout()` API only), the *opportunity cost* is real but under-taught, and skills don't yet read a boss's **reading state** (Poise is Pillar One per P9).

## Deep design

### Core mechanics (precise, Wayfinder-flavored)

1. **The loadout is the depth lever, not the skill count.** Following [[Slay the Spire]] (deck-as-state) and [[Hades II|Hades II]] (Arcana Grasp), depth comes from *what you can't bring*. Three open slots over a 9-skill pool means every pick costs a pick. We harden this by ensuring the pool has **no dominant triple**: each skill answers exactly one of the four ARPG questions (kill-a-tank / clear-a-pack / make-space / survive), so three slots can never cover all four — the player accepts a gap and the *chart's affixes/biome* (the read) decide which gap is safe this run.
2. **Loadout is set at the Hearth, never mid-delve.** Locking it to town/rest sites (the [[Guild Wars 2]] out-of-combat-swap rule) makes the pre-delve "what will the Pale Veins throw at me" decision the moment of expression — it reads off the **summary card** ([[Chart Loop]]). No swap-roulette mid-fight.
3. **Skills are hunting verbs gated by Huntcraft, the doing-teaches-it trade.** Per ADR 0005 every kill feeds Huntcraft `max(2, hp_max/3)`, so the deep verbs (Mark/Ward/Mercy) unlock by *hunting more*, not grinding a skill tree — the cozy "earned mastery" feel ([[Camera and Game Feel]]) without a new progression axis.
4. **One reading mechanic (Pillar One, P9): Poise/stance-break.** Bosses carry a Poise meter; hits during their recovery/whiff frames fill it; at full they **Reel** for ~3s, opening a Wayfinder's Mark finisher *and a skill-reset window*. Skills become *the answer to a read* (dump cooldowns into the Reel), not a rotation. This is the **only** new combat reading mechanic in the demo — Rally is explicitly cut.

### Data model & formulas (GDScript-flavored)

The model is the shipped one; the design adds two small, data-driven knobs and one reading hook. No new gear tier, no new weapon class.

| Field | Where | Notes |
|---|---|---|
| `cost: float` | `Skill` | Focus, 0 for Bow |
| `base_cd: float` | `Skill` | reduced by `effective_cd` |
| `effective_cd(player)` | `Skill` | `base_cd / (1 + clamp(cdr, 0, 0.80))`; Bow uses `fire_cooldown` |
| `answer: String` | **new** | `"tank"\|"pack"\|"space"\|"survive"` — drives the loadout-screen "coverage" hint |
| `req_hunt: int` | from `SKILL_REQS` | unlock gate (0 = open) |

```gdscript
# Loadout-coverage hint (new, pure-data, no dispatch change → test_skills safe)
func loadout_coverage(picks: Array) -> Dictionary:
    var covered := {}
    for sk in picks:
        covered[SKILL_FACTORY[sk].new().answer] = true
    return covered   # screen shows which of the 4 questions go UNanswered
```

```gdscript
# Reeling skill-reset window — fires on the boss Poise-break signal.
# Lives in the boss, NOT in _try_skill (keeps the guarded dispatch path untouched).
func _on_boss_reeling() -> void:
    for k in _skill_cooldowns:
        _skill_cooldowns[k] = 0.0   # reset, then the player chooses the dump
```

Focus, CDR cap, and the slot-1 split are **frozen as shipped** — touching `_try_skill` risks the frozen-hotbar regression, so all additions are *adjacent* (a data field, a boss-side signal), never inside the dispatch loop.

### Content to author (tiers / tables / worked examples)

The 9-skill pool stays at 9 (P8: no new weapon class; growth is *re-flavoring*, not *adding*). Author the missing `answer` tag and one Pale-Veins re-skin per P3:

| Skill | Answer | Gate | Pale-Veins read it pairs with |
|---|---|---|---|
| PowerShot | tank | open | Stoneflesh-heavy Hedgewight packs |
| PiercingBolt | pack(line) | open | branching-vein corridors |
| MultiShot | pack(cone) | open | open ore-vaults |
| RainOfThorns | space(zone) | open | collapsing-vein telegraph fight |
| BrambleSnare | space(root) | open | Boar charge windows |
| Thornburst | survive(panic) | open | being surrounded in a vault |
| HuntersMark | tank-primer | Hunt 4 | Boar tusk-quake phase |
| HeartwoodWard | survive | Hunt 7 | unavoidable quake damage |
| MercyShot | execute | Hunt 9 | finishing a Reeling boss |

**Worked example (the depth bite):** the Burrow Boar fight ([[Bosses]]) rewards `survive` + a way to punish the Reel. A player who packed PowerShot/MultiShot/PiercingBolt (all damage, no survive, no space) *can* win but eats every quake; a player who swapped MultiShot→HeartwoodWard trades pack-clear for survivability. **That trade is the design.** The summary card surfaces the gap before they commit.

### Edge cases, failure modes, anti-frustration

- **Dead-loadout / hard-lock:** because slot 1 (Bow, free) always works, no loadout can soft-lock a player out of damage — the cozy guardrail ([[Balance Philosophy]]: "always winnable"). A bad triple is *slower*, never *unwinnable*.
- **The frozen-hotbar class of bug:** any change near dispatch must keep `test_skills.gd` green; the rule is *re-seed cooldown keys, never bare-clear* (the comment is in `rebuild_skills`). New features go adjacent to `_try_skill`, never inside it.
- **Focus-starve:** `FOCUS_REGEN_IN/OUT` already prevents skill-spam; the in-combat penalty is the spend rhythm, not a punishment — no skill should be un-castable in a fight, so costs stay ≤ ~32 (one full bar refills in ~5s out of combat).
- **Over-teaching:** loadout opportunity-cost is invisible if untaught. The fix is the *coverage hint*, not a wall of numbers — one storybook line ("you carry no way to hold ground").
- **Bosses ignore CC:** bosses are root/snare-immune (Skills §"Unyielding"), so Poise is the *replacement* for crowd-control on the verbs that would otherwise do nothing to a boss.

## Interlocks — how this feeds/uses other systems

- [[Huntcraft]] — gates the 3 deep verbs; leveled by every kill (ADR 0005). The one trade↔skill coupling.
- [[Combat]] — Focus, hit feedback, the Poise/stance-break reading mechanic the loadout answers.
- [[Affixes]] — `cooldown_reduction` scales slots 2–4 (cap 0.80); `quiver`/`echoing` chart affixes bend Bow fire-rate and Focus regen (`_chart_fire_mult`, `_chart_focus_mult`).
- [[Chart Loop]] — the summary card surfaces the *read* a loadout is chosen against; loadout is set at the Hearth before inscribing.
- [[Items and Gear]] — `fire_rate` scales the Bow only; gear never adds a skill (no build-enabling sockets — the [[Path of Exile|PoE 2]] "build expression decoupled from item hunt" lesson, held to one verb).
- [[Multiplayer Co-op]] — Poise + boss telegraphs RPC to all peers so every screen reads the same Reel window (P9 correctness, not polish).

## Demo scope vs Horizon

**DEMO (Pillar One):** the `answer` coverage tag + loadout-screen hint; the Poise-break **skill-reset window** wired to the boss reeling signal; Pale-Veins skill re-skin strings (P3); RPC of Poise/telegraphs to co-op peers. All adjacent to the guarded dispatch path.

**HORIZON (named, NOT built — P7 cut-line):** **Rally** (the second reading mechanic — the plan picks Poise *or* Rally, and picks Poise); the **charm-notch loadout re-cost** and **named cross-skill synergies** (§4.4); **item-skill modifiers**; any 10th+ skill. A skill expansion ships *only* when a region needs it and **never** as a new weapon class or gear tier (P6/P8). The pick-one-of-N *mastery* pattern (§4.1) is Earthcraft-only in the demo and does not touch the skill pool.

## Implementation notes (Godot)

- **Scripts:** `scripts/skills/*.gd` (add `answer` to each `_init`); `scripts/player_controller.gd` (`rebuild_skills`, untouched `_try_skill`; new boss-reeling reset handler); `scripts/game.gd` (`set_loadout`, `SKILL_POOL`, `SKILL_REQS`).
- **Data:** loadout persists in the save via `Game.loadout`; the migration ladder (Pillar Zero) must carry it forward, not reset it.
- **UI:** the **loadout-swap screen** is a new kit-compliant panel (extend `skill_bar.gd` data into a Hearth panel) — must pass `tools/check_ninepatch.py` and get a `WYRD_UI_SHOT` capture surface (§6 UI workstream). The SkillBar HUD already reads live skill data.
- **Guard suite:** `test_skills.gd` is the **only** suite that catches a dead keypress — it must stay green on every change to dispatch, loadout swap, or gates. Add a case asserting the coverage hint and the reeling-reset don't alter Focus/cooldown accounting.

## Open questions

- Should the coverage hint *block* an all-damage triple, or only warn? (Cozy contract says warn.)
- Does the Reel skill-reset risk trivializing the boss if a player dumps three cooldowns? Balance-sim it against the crypt curve before shipping.
- Should HuntersMark's gate (Hunt 4) come *before* the first boss, so the priming verb is available when it first matters?

## See also / Sources

- [[Skills]] · [[Huntcraft]] · [[Combat]] · [[Affixes]] · [[Chart Loop]] · [[Bosses]] · [[Items and Gear]] · [[Balance Philosophy]] · [[Universe Build-Out Plan]]
- [[Hades II]] · [[Slay the Spire]] · [[Path of Exile 2]] · [[Dead Cells]] · [[Guild Wars 2]]
- Code: `wyrd/scripts/player_controller.gd`, `wyrd/scripts/skills/`, `wyrd/scripts/game.gd`, `wyrd/scripts/skill_bar.gd`, `wyrd/test_skills.gd`
