# Spec 30 research — skill systems in FATE: Reawakened, Diablo 3, Path of Exile 2

Background synthesis for spec 30 (skills + cooldowns + mana). Saved per the ARPG-spec workflow so the spec's "References" section can link back to the genre research that informed each decision.

## Per-game profiles

### FATE: Reawakened (Crate Entertainment, 2025)
The cozy benchmark. Skills split between **passive proficiencies** (weapon, magic, dual-wield, shield — picked on level-up) and **active spells** learned from scrolls/books. The remaster shrank the hotbar **from 12 slots to 6**, accessed via number keys; spells bound via F1–F12 over the spell foldout. **Resource = Mana** (single shared pool, scaled by Magic stat); spells have per-cast Mana costs (e.g. Fireball: Mana 12, Cast Time 1.0s, 2–7 damage + 2/level). **No global cooldown** — pacing gated by mana + cast time, not timers. Spells fall into Attack / Defense / Charm categories with a per-category Magic skill that scales effect — *that* is the "variant" system: not branching modifiers but linear scaling per cast count. Pet partner can also be handed scrolls. The hotbar prioritizes **consumables (potions, scrolls, town portal) alongside spells**, not pure abilities. Sources: [Steam beginner handbook](https://steamcommunity.com/sharedfiles/filedetails/?id=3443436273), [FATE Spells wiki](https://fate.fandom.com/wiki/Spells), [Reawakened patch notes](https://playfate.com/2025/06/fate-reawakened-console-patch-notes/).

### Diablo 3 (Blizzard)
The polish benchmark. **6 hotbar slots**: Left Mouse, Right Mouse, keys 1–4. By default skills gate into 6 categories (Primary, Secondary, Defensive, Might, Tactics, Rage — class-renamed) with the LMB pinned to a Primary, key 1 to a Defensive, etc.; **Elective Mode** unlocks free assignment. **Per-class resource**: Barbarian = Fury (built from attacks), Monk = Spirit (combo/finisher), Demon Hunter = Hatred + Discipline, Wizard = Arcane Power (regenerating), Witch Doctor = Mana (slow regen), Crusader = Wrath. **Generator/Spender economy** is the heart: Primaries cost no resource and *generate* it; Secondaries *spend* it for burst damage. **Cooldowns** are per-skill (no global cooldown), with strong ultimates at 60/90/120s; Cooldown Reduction stat caps so cooldowns can't go below 0.5s. **Runes**: each skill has **5 runes** unlocked one-at-a-time between levels 6–60. Runes are *meaningful*: change element, damage shape, secondary effect — not cosmetic. UI: bottom-center bar with cooldown sweep (rotating second-hand inside the icon, icon greys out), resource as a left-side **orb** mirroring the HP orb on the right. Sources: [DiabloFans Elective Mode](https://www.diablowiki.net/Elective_mode), [Fury wiki](https://diablo.fandom.com/wiki/Fury_(Diablo_III)), [Maxroll CDR](https://maxroll.gg/d3/resources/cooldown-and-resource-cost-reduction-mechanics), [Cooldown wiki](https://diablo.fandom.com/wiki/Cooldown).

### Path of Exile 2 (Grinding Gear Games, 2024–2026)
The depth benchmark. **One hotbar**, but **two weapon sets** swapped on `X`; each weapon set has its own skill loadout and passive-skill allocation (24 weapon-set points by campaign end). **Default skill-gem slot limit = 9**. Two resources: **Mana** (regenerating, paid per cast for most skill gems; weapon "innate" basic attacks cost nothing) and **Spirit** (reservation-only pool, 0–100+ from progression, reserves for auras, persistent minions, and "meta gems" that auto-trigger skills under conditions). No traditional global cooldown, but **movement skills and meta-triggered skills carry their own cooldowns**, reducible with the Ingenuity support. **Support gems are the variant system**: each active skill links up to **5 supports**, names like Brutality, Heavy Swing, Martial Tempo — they multiply damage, change behaviour, or constrain (Brutality forbids non-physical scaling). Character Strength/Dex/Int determines how many of each colour support you can use, so build identity gates depth. UI: top-left mana globe, top-right life globe, skill icons across the bottom. **Pitfall:** the May 2025 "loot tap" patch [accidentally deleted players' equipped skill gems](https://steamcommunity.com/groups/rps/announcements/detail/545608109498826961) — cautionary tale for storing build state on items rather than the character. Sources: [Spirit guide](https://maxroll.gg/poe2/resources/spirit-guide), [Skills in PoE2](https://maxroll.gg/poe2/resources/skills-in-path-of-exile-2), [PC Gamer weapon sets](https://www.pcgamer.com/games/rpg/path-of-exile-2-weapon-set-skill-points/).

## Comparison table

| Axis | FATE: Reawakened | Diablo 3 | Path of Exile 2 |
|---|---|---|---|
| **Active hotbar size** | 6 (mixes spells + potions + scrolls) | 6 (LMB, RMB, 1–4) | ~9 gems, 1 hotbar, weapon-swap doubles effective loadout |
| **Resource** | Mana (single pool, scaled by Magic stat) | Per-class (Fury, Spirit, Arcane, Mana, Hatred/Discipline, Wrath) | Mana (regen) + Spirit (reservation only) |
| **Cost model** | Flat mana per cast | Generator/Spender (Primaries free + generate; Secondaries spend) | Basic attack free; gems cost mana; auras reserve spirit |
| **Cooldowns** | None (cast time + mana gate pace) | Per-skill, big ults 60–180s, floor 0.5s | Per-skill on movement & meta; most attacks mana-gated |
| **Variants per skill** | 1 (linear skill-level scaling) | 5 runes per skill, unlock 6–60, swappable out of combat | Up to 5 support gems per skill, build-gated by attribute colours |
| **UI** | Bottom hotbar, mana bar, no cooldown sweeps | Bottom bar + dual orbs (HP/Resource), rotating cooldown sweep | Bottom bar + dual orbs (HP/Mana), weapon-set toggle widget |
| **Pitfall** | Spells feel samey — no real variants | Global cooldown frustration on ult-stacked builds; 6-slot ceiling cramps experimentation | Skill gems are *items* — bug deleted them; dense for new players |

**Contradictions worth naming:**
- **D3 generator/spender vs FATE no-resource.** D3 makes every fight a mini economy; FATE makes every fight a "do I want to spend a potion." Cozy ARPGs lean FATE; depth ARPGs lean D3.
- **Per-skill cooldowns (D3) vs cast-time + mana gate (FATE/PoE2 attacks).** Cooldowns produce visible *rotations*; mana produces *sustained pressure*. Mixing both is what PoE2 does, and is what gj26's `FIRE_COOLDOWN = 0.28s` already implies on the basic shot.

## Recommendations for gj26 spec 30

A 4-skill hotbar (1–4) is the right ceiling — half of D3's, fits a controller without modifiers, matches the Bramblewood cozy tone. Concrete picks:

1. **Resource = single regen "Focus" pool.** Reject D3 per-class fragmentation (too crunchy for cozy) and reject FATE no-pacing (basic shot already has a 0.28s cooldown — Focus *adds* the strategic layer of "save it for the spender"). Suggested floor: ~50 Focus, regens ~10/sec out of combat, ~3/sec in combat. Basic shot stays free (preserves the snappy F-spam feel already working); skills 2–4 cost 15–40 Focus.

2. **Hybrid cooldown + Focus on skills 2–4.** Pure cooldowns alone feel MMO; pure resource alone (FATE) makes every fight identical. Tag one of the four slots as the "ultimate" with a long cooldown (~30s) and free cost — gives players a "moment" without forcing them to track multiple bars. Wire into `derived_stats` like `fire_cooldown` already is.

3. **Variants = D3 runes, not PoE2 gems.** Steal D3's model: **3 variants per skill, unlocked at skill levels 3/6/9**, swappable from a "Skill Codex" between fights. Reject PoE2 gem-as-item model (deletion bug, inventory pressure, cognitive load). The four bolt VARIANTS already in `arrow.gd` (gold/emerald/frost/violet) are halfway there — promote from cosmetic to mechanical (frost = slow, violet = pierce, emerald = lifesteal, gold = crit-bonus).

4. **UI: D3 orb + cooldown sweep, but in our ink-line style.** Bottom-center bar with 4 slotted icons + keybind labels. Each slot: skill icon, cooldown sweep (rotating sector greying out when unusable), Focus cost in the corner. Add a small Focus *bar* under the HP bar (orbs feel too Diablo-coded for Bramblewood; bars feel more cozy/storybook).

5. **One thing to steal from each:**
   - **FATE**: pet/companion can hold a scroll — the player isn't the only caster on screen. Fits Bramblewood neighbors-as-systems.
   - **D3**: rune-swap out-of-combat with zero penalty — encourages experimentation, central to cozy "try things" energy.
   - **PoE2**: weapon-swap as implicit second loadout — *if* gj26 later adds a melee weapon, dual-loadout via Tab is richer than 5th–8th hotbar slots.

6. **One pitfall to avoid (highest priority):** Don't put skill state on items (PoE2 deleted-gem disaster). Store equipped skills + variants on the **player**; treat items as stat affixes only — matches the existing `equipment.gd` / `_derive_stats()` pattern. Also: don't ship 4 skills that all *feel* like F (the cardinal FATE sin). Each of the 4 should answer a different question: **kill one tank, clear a pack, create space, save my life.**

## Files referenced (absolute paths)
- `/Users/bbroeking/projects/gj26/godot/scripts/player_controller.gd` — `FIRE_COOLDOWN`, `derived_stats`, `_fire_arrow`, key bindings `bolt_1..4` — extend for the new hotbar.
- `/Users/bbroeking/projects/gj26/godot/scripts/arrow.gd` — `VARIANTS` array + `variant_idx` is the seed for the rune system; promote from visual to mechanical.
- `/Users/bbroeking/projects/gj26/godot/scripts/combatant.gd` — `take_damage(amount, dir, crit_chance, crit_mult)` signature already supports per-shot tuning; new skill variants slot in here.

## Sources
- [Steam FATE: Reawakened Beginner Handbook](https://steamcommunity.com/sharedfiles/filedetails/?id=3443436273)
- [FATE Spells (Fandom)](https://fate.fandom.com/wiki/Spells)
- [FATE: Reawakened Patch Notes](https://playfate.com/2025/06/fate-reawakened-console-patch-notes/)
- [Diablo 3 Skill Runes (Fandom)](https://diablo.fandom.com/wiki/Skill_Runes)
- [Diablo 3 Fury (Fandom)](https://diablo.fandom.com/wiki/Fury_(Diablo_III))
- [Diablo 3 Elective Mode (DiabloWiki)](https://www.diablowiki.net/Elective_mode)
- [Diablo 3 Cooldown (Fandom)](https://diablo.fandom.com/wiki/Cooldown)
- [Maxroll CDR & RCR Mechanics](https://maxroll.gg/d3/resources/cooldown-and-resource-cost-reduction-mechanics)
- [Maxroll PoE2 Spirit Guide](https://maxroll.gg/poe2/resources/spirit-guide)
- [Maxroll PoE2 Skills Guide](https://maxroll.gg/poe2/resources/skills-in-path-of-exile-2)
- [PC Gamer PoE2 Weapon-Set Skill Points](https://www.pcgamer.com/games/rpg/path-of-exile-2-weapon-set-skill-points/)
- [RPS — PoE2 patch deleted skill gems](https://steamcommunity.com/groups/rps/announcements/detail/545608109498826961)
