# Implementation Roadmap — Sequencing the 31 Build Docs

## Build log — 2026-06-17 (live, post-audit)
**The game now BOOTS and plays end-to-end with a green 5-suite gate.** A
critical regression (`town.gd` parse error from the big systems build-out) had
made it unlaunchable since `ff5fc36`; fixed in `299fe61`, and a new
`test_boot_smoke` suite (`edcf2c6`) compiles every script + loads Town/World so
this class of bug can't ship green again.

A parallel audit (4 agents, all 31 systems, cross-checked against code) found
the **core spine is COMPLETE** — chart loop, economy, mastery tree to lv 17,
ledger (ADR 0013 #3), combat + status + elites + combatant-AI, save/load,
dungeon-gen scopes, biome palettes, co-op C-1/C-2/C-4/C-5, HUD + feel.gd, the
inventory pack + compare-on-hover tooltip. What remains splits three ways:
- **Real, codeable tails** (small, self-contained): per-skill VFX/upgrade
  passes (snare windup, ward arc, mercy execute-ring, pierce-count), status
  player-flash + cleanse-factory + MP sync, Herald/Protector elites + depth
  density, inscription-ritual reveal + run-debrief, SKILL_HINTS, HUD status
  strip, multi-floor descent, biome decor models, New-Game button.
- **Blocked on assets/decisions**: ALL audio .mp3 (ElevenLabs, ~$0.85, needs
  spend approval), painted skill-icon PNGs + NPC portraits (art), new biome
  GLBs (Meshy), C-3 boss telegraph host-sync (large-structural — guest boss
  runs own AI), repair/durability + skill perk-ladders (design decisions).
- **Vetted moot** (audit-flagged but NOT real): consumable stacking + trophy-
  sell block (consumables/trophies aren't grid items — they're satchel
  materials / ledger entries); chart entry fee (charts already consumed).

This session shipped: `town.gd` boot fix · boot-smoke suite · compare-on-hover
tooltip · co-op C-2/C-4/C-5 + Quickroot cleanse · economy buy-gate + chart-case
cap + save-test footgun fix. See git log `ff5fc36..HEAD`.

## Build log — 2026-06-16 (live)
**22 / 31 systems built & gate-green** (all standard suites + per-feature suites pass).
Serial (me): ㉒ status-effects player parity — HUD drain-arc pip row above the HP globe, `marked` suffix, `StatusEffect.duration`, and the `hp_regen` tick (the `vigorous` affix now heals over time). `test_player_status` P5/P6 added. Deferred: DoT mesh-tint pulse (needs material-flash plumbing), cleanse path, multiplayer status sync.
Serial (me): combatant-AI Phase 2 — IDLE wander (enemies shuffle near spawn, nav-guarded) + elites fully visual-differentiated (per-kind `ring_color` ring + floated `label_color` modifier name on promotion). Remaining combatant-AI: Warden/Brute archetypes, Herald/Protector elite dispatch, co-op orb replication.
Serial (me): ㉕ biomes-decor — per-scope wall/floor palette (hollow earthy, briar green-black, snug sandstone, crypt default) via `_apply_biome_palette`; crypt sarcophagi filtered from non-crypt biomes; bones + bookshelf now breakable. Deferred: new biome GLBs (Meshy), per-scope room themes (dungeon_gen threading), shatter shader.
Serial (me): combatant-AI Barrow Brute archetype — `barrow_brute` kind (crypt table), `is_bruiser` + expanding orange floor-ring telegraph (0.7s) → 14-dmg AoE strike (ATTACK_RANGE×1.6); root cancels the windup; ring freed on hit/root/death. `test_statuses` T10. Combatant-AI archetypes complete; remaining: co-op orb replication (folds into multiplayer Phase C).
Serial (me): combatant-AI Warden archetype — a support enemy (`warden` kind, hollow/crypt tables) that follows + heals adjacent allies +2/4s (green "+N"), never attacks; `_support_tick`/`_nearest_ally`/`_heal_direct`. `test_statuses` T9. Remaining combatant-AI: Barrow Brute AoE-telegraph, co-op orb replication.
Serial (me): combatant-AI/elites — wired the two staged Batch-4 elite modifiers LIVE: `thornshelled` (spine_burst → Bleed-on-swing) + `blightwalker` (blight_pool → death AoE Bleed + teal disc). `test_statuses` T8 added. Elites system now complete (6 modifiers, all functional + distinct). Remaining combatant-AI: Warden/Brute archetypes, co-op orb replication.
Serial (me): ㉔ inventory-equipment UX — full-pack pickup toast (no more silent item loss) + pack grows a row at lv 6/12 (`Inventory.rows` var + `resize()`, panel renders extra rows, level-derived on load). `test_wyrd_loop` _test_pack_progression added. Deferred: consumable stacking (needs grid-vs-materials investigation), tooltip compare-on-hover, InventoryController split (ADR 0001).
Serial (me): ㉓ gathering deep-tier readability — starsilver/hedgesteel veins cast a faint `OmniLight` halo, foxglove/stonebreak patches pulse via material emission (deplete kills, regrow resumes). Deferred: `herbal_patch` item-field tweak (needs flow verification; code comment contradicts the impl note), still/forge hint test. Pre-existing non-fatal "Lambda capture freed" teardown noise noted (HEAD has it too).
Serial (me): ⑱ combatant-AI chain-aggro (waking one wakes the pack) — and fixed a real pre-existing `bool(null)` crash in `_nearest_player` that was silently breaking enemy targeting (also cleared test_combat F7).
Parallel Batch 4 (disjoint files): ⑲ elites — distinct per-modifier tints + 2 new data modifiers · ⑳ town-hub ambient — drifting motes, Living-Atlas board, regrow sprout-motes, arrival beat (NOW wired: `gather_node.regrew` signal + `game._returning_from_delve` + sfx keys) · ㉑ UI panels — tooltip rarity stripe (items-affixes task 12) + crafting-bench/loadout kit polish.
Remaining (~10): status-effect player icons (+ wire the exposed `hp_regen` tick), deeper combatant-AI phases (wander, Warden/Brute, Herald/Protector elite dispatch + ring/label colors, co-op orb replication), gathering deep-tier node spawns, inventory-equipment UX, multiplayer Phase C, biomes-decor, audio (ElevenLabs-gated), + tails (skills Trades-page view, boss queen-summon, inscribe ritual).

Parallel Batch 3 (disjoint files): ⑭ save-load hardening (atomic write + `.bak` fallback + roundtrip suite that never touches the real save) · ⑮ animation — gather arm-swing `SkeletonModifier` (Plan.md B1), now wired into `player_controller` begin/end_gather · ⑯ NPC/story — Mara dialogue depth + Summit payoff + dialog portrait slot · ⑰ charts-wayfinding — waystone affix/stability/den-band preview.
Integration sweep (serial, by me): economy now reachable (Quill = 2nd vendor, Hod shelf scales with level); skill SFX keys + distinct `craft_still`; `honed`/gather_speed affix cuts channel time; `hp_regen` stat exposed; fixed an agent parse error in `gather_swing_modifier.gd` (`const: type :=` → `=`).
New tests: `test_save_roundtrip` (35).


Serial (shared-file, by me): ① mastery skill tree (pick-1-of-N + modal + save/migrate) · ② ledger (trophy→stat, ADR 0013 #3) · ③ boss-bar per-kind names · ④ level-up moment + `feel.gd` (B0/B3) · ⑤ craft-station `react()` (B5).
Parallel Batch 1 (disjoint files): ⑥ Rain of Thorns VFX · ⑦ Thornburst VFX · ⑧ Piercing Bolt frost identity · ⑨ Items & Affixes data (6 uniques, 4 affixes, rare names) + `Drops.droppable_kinds()`.
Parallel Batch 2 (disjoint files): ⑩ dungeon-gen scope archetypes + 3 set-pieces + scoring bands · ⑪ economy data (gate hardening, tiered wares, chart fees) + Quill panel · ⑫ interactables (shrine modal restyle, buff variety, abandoning waystone) · ⑬ combat-juice VFX (spark tiers, scaled damage numbers, breakable shatter).
New tests: `test_economy` (30), `test_procgen` (15), `test_items` (40, +I4 fix).

**Integration backlog** (shared-file wiring the parallel batches deferred — next serial pass): economy buy-gate + chart-entry-fee charge + sell-trophy block + repair sink (`game.gd`), vendor/Quill panel wiring (`vendor_panel.gd`, `quill_npc.gd`), skill SFX keys + level-gates + mastery-upgrade perks (`sfx.gd`/`game.gd`), gather_speed + hp_regen sums (`gather_node.gd`/`player_controller.gd`), tooltip rarity stripe (`inventory_panel.gd`), pierce-count upgrade. Audio generation gated on ElevenLabs approval.

---

This note is the **executable program of work**. The strategic layer
([[index]]) says *what each system needs and why it matters*; the feel layer
(repo-root `Plan.md`, the "B0–B7" beats) says *how the game should feel*. This
roadmap sits between them: it takes the 31 partial-system **implementation
plans** (`impl-<system>.md`, one per 🔶 note in [[index]]) and sequences their
*first commits* into dependency-ordered **waves**, so the build never trips over
a missing prerequisite.

How the three layers stack:

- **[[index]]** — strategic map of content. Each 🔶 note ("what's next + what's
  in the way"). Read it to understand *why* a system is on the list.
- **This roadmap** — the order of operations. Each impl note has been decomposed
  into a *first commit* (the smallest safe, valuable, test-green slice) plus a
  task tail; this note orders those first commits.
- **`Plan.md` (repo root)** — the cross-cutting feel passes (B0 feel/audio
  scaffolding, B1–B2 gather feel, B3 level-up moment, B4 pickup, B5 craft react,
  B6 inscription ritual, B7 arrival/ambient). Many impl notes *defer* to these;
  the most load-bearing of them, **B0**, is itself a Wave-1 unblocker below.

The 31 impl notes inherit the user's stated priorities verbatim: the **mastery
TREE** (pick-one-of-N at cluster levels), **multiplayer friend-invites**
(Phase C polish), and **every-slot-casts** (already shipped — appears only as
regression coverage in [[impl-system-skills-hotbar]]).

---

## Critical path & shared blockers

Three prerequisites are cited across many impl notes. They are *not* themselves
single notes you can "finish" — they are scaffolding that, until it exists,
hard-blocks or forces ugly workarounds in everything downstream. **Build these
first** (Wave 1) and the dependency web collapses.

### 1. `ledger.gd` does not exist — the single biggest unblocker

ADR 0013 pillar #3 (trophies → live stats) is inert because the file that turns
accumulated boss trophies into capped persistent `derived_stats` bonuses was
never created. Four impl notes name its absence as an explicit blocker, and a
fifth (economy) depends on the trophy plumbing it provides:

- [[impl-system-items-affixes]] — *blocker:* "ledger.gd does not exist — must be
  created (task 3)"; its first commit is the full ledger.gd plumbing.
- [[impl-system-bosses]] — *blocker:* "ledger.gd does not exist — must be created
  as Task 6 before Tasks 7–9 can compile."
- [[impl-system-trades-progression]] — *blocker:* "ledger.gd does not exist —
  task 11 creates it"; wires trophies into `derived_stats`.
- [[impl-system-economy]] — *blocker:* notes ledger.gd is missing (scoped to
  trades-progression) but its trophy-sell gate depends on the trophy model.

**Resolution:** one of the three creators must author `ledger.gd` first.
[[impl-system-items-affixes]]'s first commit ("create ledger.gd, wire game.gd,
layout_loader.gd trophy path, _derive_stats sum, save_game persist") is the most
complete and self-contained — make that the canonical creation site, and have
bosses / trades-progression / economy *consume* it rather than re-create it.
**Sub-blocker:** boss trophy item IDs in `drops.gd` must be confirmed before the
`TROPHY_BONUSES` dict can be finalized (called out in both bosses and
trades-progression).

### 2. The mastery data model — shared by skills-hotbar + trades-progression

The "skill tree" ask (pick-one-of-N at cluster levels) is implemented in **two
notes that share one data model** (`chosen_perks` state, `MASTERY_CHOICE_LVS` /
`MASTERY_CLUSTERS`, the rewritten `perk_active()` gate, save schema + migration):

- [[impl-system-skills-hotbar]] — owns `chosen_perks`, `MASTERY_CHOICE_LVS`,
  `PERK_CATEGORY`, `mastery_choice_ready` signal, `choose_perk()`, the
  perk_active rewrite, and `_test_mastery_choice`. First commit ships all of this
  *without UI*.
- [[impl-system-trades-progression]] — first commit adds `MASTERY_CLUSTERS`,
  `chosen_perks` state+save/load, and the updated `perk_active()` gate.

**These overlap and will collide if built in parallel.** Resolve the open design
question first — **one-of-N vs two-of-four per tier** (blocker in
skills-hotbar) — then land the data model **once** (skills-hotbar's first commit
is the more complete version), and have trades-progression's first commit *build
on it* (cluster constant + level-up feel) rather than redefine `chosen_perks`.
**Sub-blocker:** `_derive_stats` lives on `player_controller`, not `game.gd` —
`choose_perk()` must call `player._derive_stats` via tree lookup
(skills-hotbar blocker).

### 3. `Plan.md` B0 — the `feel.gd` + audio-key scaffolding

`data/feel.gd` (tunable feel constants) and a batch of graceful-no-op SFX/music
keys are the B0 feel-beat scaffolding. **Eight** impl notes either hard-block on
`feel.gd` or inline TODO constants as a workaround until it exists:

- *hard block:* [[impl-system-hud]] ("must be created (Task 1) before any Feel.*
  constant compiles") — its first commit **creates feel.gd + the autoload entry**.
- *workaround / soft block:* [[impl-system-audio-music]] (also creates a feel.gd
  stub — coordinate to avoid a race), [[impl-system-crafting]],
  [[impl-system-charts-wayfinding]], [[impl-system-town-hub]],
  [[impl-system-animation]], [[impl-skill-heartwood-ward]],
  [[impl-skill-mercy-shot]] (all inline constants "until B0 lands").

**Resolution:** [[impl-system-hud]] and [[impl-system-audio-music]] both try to
create `feel.gd` — **pick one canonical creator** (HUD's first commit is the
natural home since it also owns toast timing) and have audio-music reference it.
Once `feel.gd` + the autoload exist, the seven workaround notes drop their inline
TODOs.

### Secondary shared prerequisites (smaller blast radius)

- **New files that gate their own note's later tasks** (create-then-consume,
  no cross-note race): `mastery_choice_panel.gd` (skills-hotbar t5),
  `quill_panel.gd` (economy t11), `PortalWaystone.tscn` (interactables t9),
  `staircase_node.gd` (dungeon-gen t14), `test_wyrd_decor.gd` (biomes t15),
  `feel_bench.gd` (animation Phase 5).
- **Audio files not yet generated** — many SFX keys ship as graceful no-ops
  until `tools/generate_audio.py` runs (snare throw, rain/thornburst impact,
  ward absorb/break, inscribe seal, dungeon ambience). None block code; they
  block the *felt* result. Batch the ElevenLabs spend (~$0.85, pre-approval
  required per [[impl-system-audio-music]]).
- **Typed `boss_kind` var** — `combatant.gd` has no explicit boss_kind; it's a
  dynamic property today. Both [[impl-system-drops-loot]] (task 8) and
  [[impl-system-bosses]] touch this — add the typed var once.

---

## Build waves

Five waves. **Each wave depends only on earlier waves.** Within a wave, items
are ordered by `priority` (then by how many downstream notes they unblock).
Status badges: 🟢 ship-now first commit is pure-additive / zero-risk · 🟡 first
commit safe but touches shared scaffolding · 🔵 first commit depends on a Wave-1
unblocker landing.

### Wave 1 — Unblockers + quick high-value wins

*Create the three pieces of shared scaffolding and bank the zero-risk
first-commits that need nothing else. Everything downstream keys off this wave.*

| | Note | Objective (one line) | Effort | First commit |
|---|---|---|---|---|
| 🟡 | [[impl-system-hud]] | Level-up banner, buff/debuff icon strip, tunable toasts, sub-objective line | M | **Create `feel.gd` + autoload**, replace toast magic numbers, add show_toast category+dedup, wire `_show_levelup_banner` (gold "✦ Mara's Marginalia" on lv 2) |
| 🟡 | [[impl-system-skills-hotbar]] | Pick-one-of-N mastery at lv 5/10/14/17; chosen_perks persists+migrates | M | **Mastery data model** (chosen_perks, MASTERY_CHOICE_LVS, PERK_CATEGORY, mastery_choice_ready, perk_active rewrite, choose_perk, save+migration, headless suite) — no UI |
| 🟡 | [[impl-system-items-affixes]] | ledger live + rare composed names + 6 uniques + tool affixes + rarity stripe | M | **Create `ledger.gd`** + full plumbing (game.gd, layout_loader trophy path, _derive_stats sum, save persist) + rare composed naming; test_stats R1/L0–L3 green |
| 🟡 | [[impl-system-audio-music]] | Dungeon ambience from entry, B0 keys, bus split, boss-theme transitions | M | Add dungeon_ambience to MUSIC_PATHS + B0 keys to PATHS (graceful no-ops), call ambience in layout_loader._ready, **feel.gd stub** (coordinate w/ HUD), Sfx smoke assertion |
| 🟢 | [[impl-system-bosses]] | Correct boss name on bar; ledger trophy→stat; bench den preview; Queen phase-3 | M | Add `display_name` to BOSS_KINDS, pass to bossbar.prime(), kill the hardcoded "The Hedgemother" literal in boss_bar.gd |
| 🟢 | [[impl-system-save-load]] | Roundtrip test off real save path; atomic writes + bak; migration; New Game | M | Add save_to/load_from path overloads, redirect _test_save_roundtrip to user://wyrd_test_roundtrip.json (closes CLAUDE.md followup) |
| 🟢 | [[impl-system-combat-juice-vfx]] | Magnitude-scaled numbers, biome-tinted sparks, emissive breakable shatter | M | Add `_magnitude_scale()` to damage_number.gd + apply in setup() — bleed ticks render smaller than crits |
| 🟢 | [[impl-system-gathering]] | herbal_patch fallback fix, deep-tier glow, ink-discovery logic test | M | Fix GATHER_BY_AFFIX["herbal_patch"] fallback in dungeon_gen.gd:291 + regression assertion |
| 🟢 | [[impl-system-crafting]] | Buff timers in HUD, still SFX, station react(), bench gate confirmed | M | Register craft_still in sfx.gd:PATHS + fix game.gd:409 three-way SFX match (two lines) |
| 🟢 | [[impl-system-inventory-equipment]] | Full-pack toast, consumable stacking, pack-row progression, compare tooltip | M | Replace print-only full-pack path (item_pickup.gd:110) with game.notify() + inv_full SFX + `_test_full_pack_toast()` |
| 🟢 | [[impl-system-drops-loot]] | Shrine resolved, boss signature drops, depth-gated kinds, rarity-math tests | M | Extend test_drops.gd D6–D9 rarity-math assertions + register suite in CLAUDE.md gate (pure test coverage) |

> **Wave-1 ordering note:** land HUD's `feel.gd` and items-affixes' `ledger.gd`
> *before* the rest of the wave commits, since audio-music/crafting/inventory
> and bosses/economy respectively reference them. The 🟢 rows are otherwise
> independent and can land in any order.

### Wave 2 — Build on the scaffolding

*Needs the mastery data model, ledger, and feel.gd from Wave 1. This is where
the progression spine, status-effect parity, and elite/combat depth land.*

| | Note | Objective (one line) | Effort | First commit |
|---|---|---|---|---|
| 🔵 | [[impl-system-trades-progression]] | Unmissable level-up + mastery choice survives save/load; ledger→stats; den band in Waystone | L | Add MASTERY_CLUSTERS, chosen_perks state+save/load, updated perk_active() gate (build on skills-hotbar's model; additive) |
| 🟢 | [[impl-system-status-effects]] | Player visual parity, marked-suffix fix, cleanse, MP sync, suites in gate | M | Add "marked" to STATUS_WORD + wire HitFeedback.tick_pulse from _tick_statuses (single file, tested P1–P5) |
| 🟢 | [[impl-system-elites]] | Per-modifier tints/rings/labels, depth-scaled density, 2 new archetypes | M | Per-modifier tint/ring_color/label_color in elites.gd + floating modifier-name label from combatant.gd::apply_elite |
| 🟢 | [[impl-system-economy]] | Anti-arbitrage gate, trophies blocked from sell, fees+repair sink, Quill buy panel | M | Add _WARE_MIN_LV to economy.gd, gate buy_ware() on trade_lv(), block trophy sell (additive, no UI) |
| 🟢 | [[impl-system-ui-panels]] | Shrine modal kit-styled, buff-HUD chip, body-font consistency, vendor fixes | M | Apply WyrdUi.style_panel/style_title to shrine_choice_modal + drawn _BuffCard inner class |
| 🟢 | [[impl-system-charts-wayfinding]] | Colour-coded affix preview + XP estimate, case cap=8, inscription ritual | L | waystone_panel.gd colour-coded affix lines (GOLD/TERRACOTTA), tier badges, expected-XP line (pure UI reads) |
| 🟢 | [[impl-system-animation]] | Gather arm-articulation, non-shot cast poses, dead-code removal, feel_bench | M | Create gather_swing_modifier.gd, wire into begin_gather via tween, drop whole-body rotation.x |

### Wave 3 — Enemies, dungeons, world content

*Needs progression/status/elites (Wave 2) and charts/feel scaffolding. The
combat vocabulary, multi-floor dungeons, and biome variety land here.*

| | Note | Objective (one line) | Effort | First commit |
|---|---|---|---|---|
| 🟢 | [[impl-system-combatant-ai]] | Chain-aggro, IDLE wander, 2 archetypes, AoE telegraph, elite mods, co-op ranged | M | Add `_alert_nearby` + wire into IDLE→CHASE + chain-aggro test stanza (no new assets/FSM changes) |
| 🟢 | [[impl-system-dungeon-generation]] | Distinct room themes per scope, setpieces, score bands ≥0.70, multi-floor descent | L | Add SCOPE_THEMES + ROOM_THEMES entries, wire into _assign_rooms, scope-variance test assertions |
| 🟢 | [[impl-system-biomes-decor]] | briar_maze/hollow palettes, 3 unused crypt GLBs placed, bones/bookshelf shatter | L | Add archway/stairs/door_wood to DECOR_MODEL+COLLIDER, wire entry_arch/descent_hall themes, add to DECOR_BREAKABLE |
| 🟢 | [[impl-system-town-hub]] | Living Atlas board, regrowth SFX+motes, return-from-delve beat, co-op fan-arc spawn | M | sfx.gd stub keys, game.gd _returning_from_delve flag, town.gd arrival beat, net_game.gd fan-arc spawn |
| 🟢 | [[impl-system-interactables]] | Shrine modal restyle, 10-entry buff pool, hearth preload, waystone tests | M | hearth.gd preload hygiene + WyrdUi.style_panel on shrine modal backing Panel (zero-risk pair) |

### Wave 4 — Skills polish + multiplayer + story payoff

*Each combat skill's VFX/upgrade pass needs status-effects, combat-juice, the
mastery model, and (for thorn skills) BrambleSnare merged first. Multiplayer
Phase C needs the AI/boss/dungeon/elite/interactable seams from Waves 2–3.*

| | Note | Objective (one line) | Effort | First commit |
|---|---|---|---|---|
| 🔵 | [[impl-system-multiplayer-netcode]] | Guest arrows, dmg numbers, boss telegraphs, 30s hold+rejoin, exit-vote, first-node sweep | M | Phase C-1: replace all 7 get_first_node_in_group("player") with Game.local_player()/_nearest_player(); two-process smoke clean |
| 🟢 | [[impl-system-npc-story-tutorial]] | Shrine/status/affix hints on first contact, Quill tonic react, Hod greet, Summit payoff | M | Add SKILL_HINTS for shrine/status_bleed/status_slow/affix_reading + wire call sites (closes both confusion blockers) |
| 🟢 | [[impl-skill-bramble-snare]] | Windup pose, thornwood pod material pickup, synergy affordances | M | Add _play_cast_windup() tween + body squash in fire() (zero satchel/Focus changes) — **gates the thorn-skill family** |
| 🟢 | [[impl-skill-piercing-bolt]] | Distinct frost-white needle bolt, no AoE ring, pierce-count upgrade path | M | Add PIERCINGBOLT_VARIANT + "pierce" branch in arrow.gd, _pierce_thread helper, fix loadout icon |
| 🟢 | [[impl-skill-heartwood-ward]] | Arc counter on slot, bark-brown tint, absorb/break SFX, icon, absorb-math tests | M | Ward getters in player_controller + ward_frac arc in hotbar_slot + skill_bar push + bark-brown modulate |
| 🟢 | [[impl-skill-mercy-shot]] | Amber sub-35% execute ring + silver-white kill burst, co-op readable | M | Add EXECUTE_RING_BELOW + _update_execute_ring() to combatant.gd, wire take_damage/net_apply_state, clean in _die() |

### Wave 5 — Thorn-skill VFX rebuilds (depend on BrambleSnare merged)

*Both copy BrambleSnare's `vine_grow.gdshader` / `_make_thorn` / `_wither_subtree`
patterns — they cannot start until [[impl-skill-bramble-snare]] (Wave 4) merges.*

| | Note | Objective (one line) | Effort | First commit |
|---|---|---|---|---|
| 🔵 | [[impl-skill-rain-of-thorns]] | 4-beat telegraph stack + Phase-1 correctness (RANGE, crit args, bleed, SFX) | M | Phase 1: rename RANGE constants, pass crit args, scale bleed off derived_stats.damage, register+swap SFX key, 2 test assertions |
| 🔵 | [[impl-skill-thornburst]] | 4-beat burst VFX (flash→amber disc→thorn snap→wither), gate at lv 5, upgrade vars | M | sfx thornburst_impact key + VFX constants + _burst_vfx rebuild + fire() rewrite; WYRD_SHOT confirms disc→snap |

---

## Where the gaps are

The 7 biggest gaps across the whole game, and which wave closes each:

1. **Boss trophies are inert (ledger.gd missing).** ADR 0013's third power
   pillar produces *nothing* — trophies don't feed stats. Blocks items-affixes,
   bosses, economy, and trades-progression at once. → **Wave 1**
   ([[impl-system-items-affixes]] creates it; consumers in Waves 1–2).

2. **No "skill tree" — leveling is a silent auto-unlock.** The headline ask
   (pick-one-of-N mastery) and its level-up feel moment don't exist; both depend
   on one shared data model. → **Wave 1** data model
   ([[impl-system-skills-hotbar]]) + banner ([[impl-system-hud]]), completed in
   **Wave 2** ([[impl-system-trades-progression]]).

3. **The dungeon is silent and has no feel-tuning layer.** No ambience key/call
   site; `feel.gd` (B0) doesn't exist, so eight notes inline TODO constants.
   → **Wave 1** ([[impl-system-audio-music]] + [[impl-system-hud]] create the
   scaffolding).

4. **Co-op is visually broken & mistargets.** Guests see no arrows/damage
   numbers/telegraphs, there's no reconnect grace or exit vote, and 7
   `get_first_node_in_group("player")` calls hit the wrong player. Directly
   blocks the friend-invite ask. → **Wave 4** ([[impl-system-multiplayer-netcode]]).

5. **Every place reads as the same place.** Biome scopes (briar_maze/hollow/
   snug) share decor and room themes; there's no multi-floor descent. → **Wave 3**
   ([[impl-system-dungeon-generation]] + [[impl-system-biomes-decor]]).

6. **Combat lacks legibility & variety.** Elites all share one golden tint;
   status effects have no player-side visual parity; solo enemies are trivially
   kited (no chain-aggro). → **Wave 2** (elites + status) and **Wave 3**
   (combatant-ai chain-aggro).

7. **Half the skill kit has prototype VFX / no upgrade identity.** Piercing Bolt
   looks like Power Shot; Rain of Thorns & Thornburst are bare alpha-fades; Ward
   and Mercy Shot have no in-world cue. → **Wave 4** (snare, pierce, ward, mercy)
   and **Wave 5** (rain, thornburst — gated on snare).

*(An eighth, lower-urgency gap: the signature **inscription ritual** and chart
preview — [[impl-system-charts-wayfinding]] in **Wave 2** — sharpens the
Wayfinding differentiator but isn't a correctness hole.)*

---

## Suggested first sprint

Pick the four that **unblock the most downstream work** and **honor the user's
top stated asks**, while every one ships a test-green first commit:

1. **[[impl-system-items-affixes]] — create `ledger.gd` (the full plumbing).**
   Single highest-leverage move: it unblocks bosses, economy, and
   trades-progression simultaneously (ADR 0013 pillar #3). Self-contained first
   commit with test_stats coverage.

2. **[[impl-system-skills-hotbar]] — land the mastery data model (no UI).** The
   "skill tree" is the user's #1 named ask. Shipping `chosen_perks` +
   choice-levels + `perk_active` rewrite headless-first de-risks the UI and
   stops it colliding with [[impl-system-trades-progression]] in Wave 2. Resolve
   *one-of-N vs two-of-four* before this lands.

3. **[[impl-system-hud]] — create `feel.gd` + the level-up banner.** Unblocks
   the eight B0-dependent notes and delivers the level-up *feel moment* (Plan.md
   B3) that the mastery choice fires right after. Without it, leveling is a
   silent text bump.

4. **[[impl-system-bosses]] — fix the boss-bar label.** The one true sprint
   quick-win: a visible correctness bug ("The Hedgemother" on every boss) fixed
   in three lines, in a marquee moment — and it's the on-ramp into the ledger
   work that bosses also consume.

This quartet leaves Wave 1 nearly closed: the three scaffolding pieces
(`ledger.gd`, mastery model, `feel.gd`) plus the highest-visibility correctness
fix. The remaining 🟢 Wave-1 rows (combat-juice, gathering, crafting, inventory,
drops, save-load, audio no-ops) are independent pure-additive commits that can
fill out the sprint or slot into the next.

---

## Link check

All wikilinks in this note were verified against the 31 valid impl-note names
and the strategic notes ([[index]], [[system-map]]). **No dangling links.**

- Every `[[impl-*]]` target resolves to an existing
  `docs/system-plans/impl-*.md` file.
- Strategic references ([[index]], [[system-map]]) resolve to existing notes.
- `Plan.md` (repo root) and `feel.gd` / `ledger.gd` / `gather_swing_modifier.gd`
  etc. are intentionally **not** wikilinked — they are repo files / files-to-be-
  created, not vault notes, and are referenced as inline code spans on purpose.
