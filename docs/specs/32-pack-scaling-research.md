# Spec 32 research — pack scaling + elites in FATE: Reawakened, Diablo 3, Path of Exile 2

Background synthesis for spec 32 (denser packs + a one-modifier elite tier). Saved per the ARPG-spec workflow so the spec's "References" section can link back to the genre research that informed each decision.

## 1. FATE: Reawakened (Crate, 2025 remaster)

FATE is the *cozy* reference and the most permissive on density. Dungeon floors are populated by **hordes of trash that escalate by depth** — goblins/slimes on the upper floors, then skeletons/orcs/vampires, then dragons in the lower reaches ([In-Game News DLC writeup](https://www.ingamenews.com/2026/05/fate-reawakened-prometheus-dlc-adds-new.html)). Realm bosses are *randomized within a depth band* (38–42 in Grove, 43–47 in Druantia/Typhon) — bosses themselves are reskinned-and-upscaled common enemies with one or two unique patterns (sweeping tail, summon-minions). There is no "champion / rare / unique" colored-name hierarchy as in Diablo; FATE leans on **enemy *kind* variety instead of affixes**.

Pack composition: goblins rush in melee waves of ~5–8; skeletons drop in 2–3s and reanimate if not fully killed; dragons appear nearly solo as set-pieces. Loot bump for "named" monsters is modest — a Renown-tier item ([Reawakened Wiki guide](https://www.reawakened.wiki/guide/reawakened-beginner-guide)) is the rough analogue of an elite drop. Visual distinction is **purely model swap** (a bigger skeleton is a champion-skeleton); no glow, no name color.

**Gets right:** density without modifier soup — packs feel *populated*, not stat-checked. Bosses are diegetic (one big version of a familiar thing), which gj26 already does with Hedgemother. **Pitfall:** FATE's enemies blur together because no in-engine signal differentiates a tough one from chaff at a glance — without read-aloud names or modifier text, the player can't *predict* trouble.

## 2. Diablo 3 (Blizzard)

D3 is the canonical reference. The hierarchy is **Champion (blue) → Rare (yellow) → Unique (purple-ish)** — see the [Diablo Wiki on Champion monsters](https://diablo.fandom.com/wiki/Champion_monsters). Champion packs spawn **3–5 identical-model elites** (typically 3, rarely 2 or 6); rares are a *single* yellow-named leader with a **3-monster minion retinue** of the same kind (silver name, normal model colors). All elites share **bright blue/yellow glow on the model** + a colored health bar + the elite's name shown over the head. Affix names appear on hover.

Affixes (Maxroll's [Elite Affixes guide](https://maxroll.gg/d3/resources/elite-affixes) is canonical) — roughly **~24 affixes** total, split into champion-only, rare-only, and shared. Champions get 1 affix, rares get **3 affixes** drawn from a wider pool. The full set includes Arcane Enchanted, Avenger, Desecrator, Electrified, Fast, Fire Chains, Frozen, Frozen Pulse, Health Link, Horde, Illusionist, Jailer, Juggernaut, Knockback, Missile Dampening, Molten, Mortar, Nightmarish, Orbiter, Plagued, Poison Enchanted, Reflects Damage, Shielding, Teleporter, Thunderstorm, Vortex, Waller. **Loved:** Avenger, Health Link, Fast (interesting counterplay); **loathed:** Waller, Shielding, Juggernaut (auto-skip — no counterplay) per Maxroll.

Loot bump: elites drop **3–4 progression globes** in Greater Rifts and historically dropped **2 guaranteed rares per pack** (Loot 2.0 reduced count but raised quality — see [Diablo Wiki: Magic find](https://diablo.fandom.com/wiki/Magic_find)). Kill-an-elite is the basic Nephalem Valor trigger.

AI tweaks per affix are concrete: Fast = +40% move + attack/cast speed, Teleporter = blink every few seconds, Vortex = pull within 50 yds, Mortar = ranged arcs that *cannot* fall closer than 25 yds (which is what makes melee builds laugh at it). Several affixes apply real status: Frozen explodes and freezes, Plagued leaves a DoT poison pool, Molten leaves a fire trail on movement *and* erupts on death.

**Gets right:** Hover-text + glow + name color is a three-channel visual contract that scales — even at 50 enemies on screen the elite is unambiguous. **Pitfall (well-documented in Blizzard's own forums):** the "lightning show" problem — stacked Arcane Enchanted + Orbiter + Frozen Pulse + Thunderstorm + Mortar on one pack [makes the screen unreadable](https://us.forums.blizzard.com/en/d3/t/d4-should-not-have-such-visually-intense-elite-affixes-as-d3/15916), and affix-name hover [hides info during high-pace combat](https://us.battle.net/forums/en/d3/topic/19071947484).

## 3. Path of Exile 2 (GGG, 2024–2026)

PoE 2 inherits PoE 1's structure: **Normal (grey) → Magic (blue) → Rare (yellow) → Unique (brown)** — see the [PoE 2 Rarity page](https://www.poewiki.net/wiki/poe2wiki:Rarity). Magic monsters get **1 affix**, rares get **2–4 affixes**, uniques are hand-authored. Most monsters in a pack are normal; magic/rare leaders sprinkle in. Visual: blue / yellow / brown name overhead + a small icon and (for rares) a randomly generated proper name. Rares now also expose **damage-weakness icons** under their health bar in PoE 2 ([MMOJUGG writeup](https://www.mmojugg.com/news/boss-damage-icons-in-path-of-exile-2.html)) — break the armor icon and it lights red, signalling vulnerability.

Affix catalogue is large (50+ in PoE 1, [PoE Wiki Monster modifiers](https://pathofexile.fandom.com/wiki/Monster_modifiers); PoE 2 has trimmed but is still 30+). Notable: **Vampiric** (heals on hit, you can't leech from it), **Hasted** (+30% atk / +30% cast / +40% move), **Soul Eater** (gains a stacking damage buff per ally death), **Enraging/Frenzy** (periodic 40% damage boost), **Berserker** (gets stronger as it loses HP), **Hexproof** (immune to curses), **Unstoppable** (CC-immune) — see [vhpg's Archnemesis breakdown](http://www.vhpg.com/poe-archnemesis-mods/). Loot: each modifier slot **directly increases item rarity + quantity drop** — a 4-affix rare drops nearly as much as a small boss.

**Gets right:** rarity colors + small icon + damage-weakness signal layered consistently — the player decodes a pack at a glance. **Pitfall (community-acknowledged):** brick combinations. The community [explicitly calls out](https://www.pathofexile.com/forum/view-thread/3674735) Haste Aura + Chaos Tracking Orbs + Life-Regen-with-Heal-Allies + Proximal Tangibility + auto-respawn Minion Spawning as un-killable for many builds — multiple rares with these in one pack stalls runs. The lesson: **don't combine *defense* + *sustain* + *zone denial* on one monster.**

## Comparison table

| Dimension | FATE: Reawakened | Diablo 3 | Path of Exile 2 |
|---|---|---|---|
| Pack size (trash) | 5–8 per room | density-dependent, 10–30 per "pack zone" | 4–10 per pack |
| Elite tiers | none formal; "named" or "boss" | Champion / Rare / Unique | Magic / Rare / Unique |
| Elites per room | 0–1 named | 1 pack (3–5 champions OR 1 rare + 3 minions) | usually 1 magic; 1 rare every few rooms |
| Affixes per elite | none | Champion=1, Rare=3 | Magic=1, Rare=2–4 |
| Total affix catalogue | n/a | ~24 | ~30+ |
| Visual distinction | model swap only | **name color + body glow + healthbar** | **name color + small icon + damage-weakness icons** |
| Loot bump | small (Renown) | 2 guaranteed rares + globes | linear with affix count (more affix → more drops) |
| Common AI tweak | bigger HP only | +40% speed / pull / blink / per-affix | +30% atk speed / heal / aura / per-affix |
| Status from modifier | none (modifiers don't exist) | Molten burn / Frozen freeze / Plagued poison | Ignite / Chill / Shock applied by elemental affixes |
| Top pitfall | "all enemies look the same" | "lightning show — screen unreadable" | "brick combos — pack un-killable" |

All three agree on one strong default: **elites are visually unambiguous from the moment they spawn** — D3 and PoE 2 both layer name-color + secondary indicator; FATE's *failure* to do this is its weakest link. **Treat name color + body tint as the floor, not a bonus.**

## Recommendations for gj26 spec 32

### Pack-size and elite-density targets

Current state (per `dungeon_gen.gd` / `layout_loader.gd`): 2–5 enemies per combat room, ~5–12 per dungeon, MIN_COMBAT_ROOMS=2. That's *FATE-light* and feels under-populated for an ARPG.

Recommend:
- **Combat-room trash count: `4 + clampi(depth/2, 0, 6)`** — so 4 at depth 0, 7 at depth 6, capped at 10. Doubles the current floor.
- **Treasure/shrine guard counts: unchanged** (1 / 0-1) — those rooms are pacing relief.
- **Elite density: 1 elite per ~8 trash spawns, capped at 1 elite per room.** At depth 0 that's roughly *one elite somewhere in the dungeon*; at depth 6+, *one per combat room*.
- **Boss rooms stay elite-free** — Hedgemother is the only "elite" in her room. Avoid the D3 "elite ambush in the boss arena" trap.

### Elite hierarchy — ship ONE tier in v1

D3's two-tier (Champion/Rare) and PoE 2's three-tier (Magic/Rare/Unique) both *split* the affix pool to keep variety per encounter. v1 should be simpler: **one "Elite" tier, 1 random modifier**, no Champion/Rare distinction. Adopt PoE 2's Magic-monster shape: blue name + 1 affix + ~50% more HP + ~25% more loot. If pack scaling proves shallow in playtest, *then* split into Champion (1 affix, +HP) vs Rare (3 affixes, +HP+damage, retinue) — that's spec 33+ territory.

### Pick the 6 elite modifiers to ship in v1

Reuse the spec 31 status framework. Each modifier should either **(a)** add a passive stat tweak the player can read, **(b)** apply an existing status on contact/death, or **(c)** change AI behavior — never combine all three on one elite.

| Modifier | Effect | Status interaction | AI tweak |
|---|---|---|---|
| **Brambled** | +50% HP, ~25% larger; on death, 2.5m nova applies Bleed (4s, 6.25%/tick) to all in radius | Bleed (existing) | none |
| **Swift** | +50% move speed, +20% attack speed; no HP bump | none | the only "fast" elite; chase / kite shifts |
| **Sunlit** | +50% HP; melee contact applies Burn (3s, 1/tick); leaves a 2.5m burn patch under it for 2s on each melee swing | Burn (existing) | none |
| **Briarbound** | +30% HP; **immune to Root and Snared** for 4s after being snared (then takes it normally) | partial-immunity (new flag) | none — but breaks the player's CC kit briefly |
| **Hearthwarden** | +80% HP, ~25% larger; -20% move speed; takes 50% damage from arrows hit beyond 6m (encourages closing distance) | none | tank — slow, hard to plink from afar |
| **Wisp-sworn** | +30% HP; orbits 1–2 small wisp particles that fire a low-damage chip arrow at the player every 2s (range 5m) | none | adds incidental ranged pressure |

Why these six:
- **Storybook names**, no Diablo grimdark ("Brambled" / "Sunlit" / "Wisp-sworn" lean Bramblewood).
- **Each ties to either an existing status (Burn/Bleed) or a clean AI tweak**, so v1 ships with **zero new visual systems and one new flag** (partial CC immunity).
- **No modifier alone makes an enemy un-killable** — the brick-combo trap is structurally impossible at 1 modifier each.
- **Skipped (D3/PoE pool) for v1:**
  - *Reflects Damage* — punishes the player's main verb (shooting); cozy tone says no.
  - *Vampiric / Health Link / Heal Allies* — sustain mods are top of the PoE brick list.
  - *Waller / Vortex / Jailer / Teleporter* — require pathing/positional code we don't have.
  - *Mortar / Orbiter / Arcane Enchanted* — projectile-soup; screen-clutter risk.
  - *Frozen / Freeze* — overlaps Root, no fantasy slot.

### Pick the visual distinction — combination of three cheap channels

D3's lesson is layered redundancy. PoE 2's lesson is **a small icon beats a hover-text**. Recommend the **same trio for elites**:

1. **Mesh tint (cheap, reuses spec 31 `_flash_mat` infra):** elites apply a soft golden wash (`Color(1.0, 0.92, 0.55, 0.35)`) on all child MeshInstance3Ds. Reuses the per-status palette pattern in `combatant.gd:STATUS_COLOR` — store an `_elite_color` and apply via material override.
2. **Scale boost (+15–25%):** existing `_base_scale` already exists; multiply at setup time. Big enough to read on the minimap silhouette, small enough not to break navmesh.
3. **Particle ring at feet:** a single GPUParticles3D at y=0.05, color = elite tint, ~8 particles slow-spinning. Reuses spec 31's particle infrastructure — *don't* add a head particle (the status particle slot is already there).

**Skip for v1:** colored damage numbers (DamageNumber.tscn would need a new variant), name-plates (no UI infra), boss-bar style mini-name-bar (per CLAUDE.md cozy compromise — defer until playtest demands it).

**Trade-off named:** D3's name-color is more immediately readable than a tint + ring; PoE 2's icon is even better but needs UI. The tint + ring + scale combo is the cheapest cohesive option that survives Bramblewood's "no UI clutter" aesthetic.

### Pack composition rules

Borrow D3's "leader + retinue" structure but simplified:
- **Trash-only rooms** are most rooms.
- **Elite-led rooms** (the ~1 per 8 spawns roll) contain the elite **+ 2–3 same-kind trash** (its "retinue"). The retinue isn't tagged elite, doesn't get the modifier, just spawns adjacent to the elite within ~2m.
- **No "all elite" packs** in v1. (D3 Champion packs of 3–5 identical elites is a fun-but-spiky pattern; defer to spec 33.)

### Address the pitfalls

1. **Brick-combo risk:** structurally avoided — 1 modifier per elite.
2. **Screen clutter risk:** zero new particle systems beyond the feet-ring; modifier visuals reuse existing status particles. Cap at 1 status-from-modifier active per elite at any time.
3. **"Just more HP" risk:** half the modifiers (Swift, Briarbound, Wisp-sworn) don't add HP. Of those that do, every one carries a behavioral change (burn-patch, retinue, distance-falloff, death-nova) — the player has to *play differently*, not just chew longer.
4. **Boss-immunity scope:** Hedgemother's status table from spec 31 already handles modifier-applied statuses (she takes Bleed/Burn at 50% duration). Confirm `apply_status` route covers `Brambled`'s death-nova Bleed and `Sunlit`'s burn-patch Burn — they should pass through the same `boss.gd:apply_status` override, no new code.
5. **The CC-immunity flag (Briarbound):** new state but it's the *simplest* of the proposed mods. Implementation: a `_cc_immune_until: float` timestamp on Combatant, set when Snare/Root applied to a Briarbound elite, gates further status application for 4s. Don't generalize this into a full DR system (D3's hidden DR is opaque).

### Strong default observed across all three games

**Elites are unambiguous from spawn.** D3 = name color + glow + healthbar; PoE 2 = name color + icon + damage-weakness; FATE = (this is its weak spot, model swap only and the community calls it). The triple-redundancy (tint + scale + ring) is the right floor for gj26.

## Files referenced (for the implementing agent)
- `/Users/bbroeking/projects/gj26/godot/scripts/combatant.gd` — add `is_elite: bool`, `modifier: String`, `_elite_color`, `_cc_immune_until`
- `/Users/bbroeking/projects/gj26/godot/scripts/boss.gd` — verify modifier-applied statuses still route through immunity table
- `/Users/bbroeking/projects/gj26/godot/scripts/layout_loader.gd` — bump trash per role + add elite roll + retinue spawn
- `/Users/bbroeking/projects/gj26/godot/scripts/dungeon_gen.gd` — no changes (MIN_COMBAT_ROOMS stays 2)
- `/Users/bbroeking/projects/gj26/godot/data/drops.gd` — elite role gets a +25% drop-quantity multiplier or a guaranteed-magic+ flag
- new: `/Users/bbroeking/projects/gj26/godot/data/elites.gd` — modifier table (name, hp_mult, status_kind, ai_tweak) mirroring `data/affixes.gd` shape

## Sources
- [Diablo 3 Elite Affixes (Maxroll)](https://maxroll.gg/d3/resources/elite-affixes)
- [Champion Monsters (Diablo Fandom)](https://diablo.fandom.com/wiki/Champion_monsters)
- [Magic Find / loot bump (Diablo Fandom)](https://diablo.fandom.com/wiki/Magic_find)
- [D4 Feedback: visual intensity of D3 affixes (Blizzard Forum)](https://us.forums.blizzard.com/en/d3/t/d4-should-not-have-such-visually-intense-elite-affixes-as-d3/15916)
- [Elite affix visual clarity (Blizzard Forum)](https://us.battle.net/forums/en/d3/topic/19071947484)
- [Path of Exile 2 Rarity (PoE 2 Wiki)](https://www.poewiki.net/wiki/poe2wiki:Rarity)
- [Path of Exile Monster modifiers (PoE Fandom)](https://pathofexile.fandom.com/wiki/Monster_modifiers)
- [PoE Rare Monster Mods reference (vhpg)](http://www.vhpg.com/poe-archnemesis-mods/)
- [Rare mods that need to disappear (PoE Forum, brick-combo discussion)](https://www.pathofexile.com/forum/view-thread/3674735)
- [Boss Damage Icons in PoE 2 (MMOJUGG)](https://www.mmojugg.com/news/boss-damage-icons-in-path-of-exile-2.html)
- [FATE: Reawakened Prometheus DLC writeup (In-Game News)](https://www.ingamenews.com/2026/05/fate-reawakened-prometheus-dlc-adds-new.html)
- [FATE: Reawakened beginner guide (Reawakened Wiki)](https://www.reawakened.wiki/guide/reawakened-beginner-guide)
- [FATE: Reawakened Console Patch Notes](https://playfate.com/patch-notes/fate-reawakened-console-patch-notes/)
