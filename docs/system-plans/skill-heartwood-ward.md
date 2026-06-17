---
title: Heartwood Ward
domain: Combat Skills
type: skill
status: partial
effort: M
tags: [wayfinder, plan]
---

# Heartwood Ward

> The game's only defensive skill is mechanically complete but lacks a HUD readout, a decay animation, a dedicated icon, and the balance-tightening work that makes the ward feel like a meaningful decision rather than an obvious slot-filler.

## Current state

The skill file (`wyrd/scripts/skills/heartwood_ward.gd:8-19`) is a minimal 23-line implementation: it exposes two constants (`WARD_HP = 30`, `WARD_SEC = 8.0`), sets `cost = 25.0` and `base_cd = 14.0` in `_init`, and calls `player.apply_ward(WARD_HP, WARD_SEC)` on fire, falling back silently if the player lacks the method. `apply_ward` (`player_controller.gd:1386-1393`) writes `_ward_hp` and `_ward_t`, then fires a 0.10-s scale-up/0.14-s scale-down tween on `_mesh` as a bark-hardening cue. The absorb logic lives in `take_damage` (`player_controller.gd:751-758`): any incoming hit is soaked up to `_ward_hp`, the remaining ward HP is decremented, and if the hit is fully soaked the player still receives iframes (`IFRAMES_SEC = 0.6`). The ward timer is ticked in `_physics_process` (`player_controller.gd:447-451`) and zeroes `_ward_hp` on expiry.

The gate is live: `SKILL_REQS` (`game.gd:118`) requires Wayfinding level 7, and `skill_unlocked` enforces it. `test_skills.gd:133-139` sets the level to 9 and verifies the trio fires and costs Focus, but does not test absorb math or timer expiry.

**What is missing:** There is no HUD indicator that the ward is active or how much HP remains. The `skill_bar.gd` entry uses a fallback glyph `❦` and no painted icon (`skill_bar.gd:49`); `loadout_panel.gd:39` also falls back to `skill_basic.png`. The scale pulse is the only in-world feedback; there is no particle burst, tint, or ring that persists while the ward holds. No upgrade path or scaling exists. Multiplayer behavior is cosmetic-only (ward activates locally; remote casters do not get the absorb replayed on the host side via `_net_cast` — `_net_cast` replays `sk.fire(self)` on the puppet, which does call `apply_ward` on the puppet body, but that puppet's `_ward_hp` is separate and irrelevant to the host's damage model).

## Gaps — what needs fleshing out

1. **(Hard blocker for readability) HUD ward indicator** — `_ward_hp` and `_ward_t` are private to `player_controller.gd` and never exposed to `hud.gd` or `hotbar_tray.gd`. The player has no way to know whether the bark-skin is active, how much it has left, or when it expires.
2. **No persistent visual on the character** — the 0.24-s scale pulse disappears immediately. A bark-brown tint on `_mesh` material or a passive particle ring for the full 8s duration would communicate the state at a glance.
3. **No absorb-consumed VFX** — when the ward soaks a hit, nothing differentiates it from a normal hit. A muffled thud SFX + brief bark-chip particles on the body would make the soak feel satisfying.
4. **No dedicated painted icon** — `HeartwoodWard` has no entry in `skill_bar.gd::SKILL_ICON` and falls back to the fallback glyph `❦`. The other four open skills have painted icons; the gated trio were deferred.
5. **No absorb test coverage** — `test_skills.gd` only confirms the skill fires and deducts Focus; it does not assert `_ward_hp == 30` after cast, test partial vs full soak, or verify `_ward_hp == 0` after `WARD_SEC` seconds.
6. **Balance: the "always slot it" problem** — at lv 7 with `WARD_HP = 30` and base enemy damage of ~8-12, the ward absorbs 2-3 hits and costs 25 Focus on a 14s CD. Against the crypt the absorb/cost ratio may be too high. There is no upgrade path; stats are compile-time constants.
7. **Co-op: shared-ward mechanic** — the ward is purely self-targeted. In two-player runs a co-op ally cannot benefit from a teammate's ward cast. This is a design gap (no decision recorded); the current `_net_cast` path would call `apply_ward` on the puppet body which is non-authoritative and does nothing for protection.

## Plan

### Phase 1 — HUD indicator + persistent visual (read-before-react)

- Add a `ward_hp` and `ward_frac` getter (or expose `_ward_hp`/`_ward_t` as read-only properties) in `player_controller.gd` so the HUD can read them.
- In `hud.gd` (or `hotbar_tray.gd`), draw a small bark-brown arc/label beneath the hotbar slot for Heartwood Ward when `_ward_hp > 0`, showing remaining HP (e.g. "30" draining to "0") — same radial-slot pattern already used for the cooldown wedge in `hotbar_slot.gd`.
- In `apply_ward`, start a `ShaderMaterial` overlay tint (bark brown, `Color(0.45, 0.28, 0.10, 0.35)`) on `_mesh`; clear it in `take_damage` when `_ward_hp` hits 0 or in the `_ward_t <= 0` branch. Use `create_tween` (same pattern as `apply_ward:1391`).
- **DoD:** Ward active state is visible as a browning mesh tint + arc counter while HP > 0; tint disappears on expiry or full absorption; no new autoloads or scenes.
- **Effort:** S

### Phase 2 — Absorb-hit feedback (the "soak sells itself" beat)

This is the combat-feel beat that makes the ward feel like a decision rather than a passive stat. See Plan.md Part A §3 (SFX pipeline) and §2 (hit-feel patterns).

- When `_ward_hp > 0` and a hit is fully soaked (`amount <= 0` after soak, `player_controller.gd:755`): play `Sfx.play("ward_absorb")` (new ElevenLabs SFX — a muffled wooden thud, generated via `wyrd/audio/tools/generate_audio.py`).
- Spawn 4-6 `MeshInstance3D` bark-chip particles (cheap quads, reuse the scatter pattern from Plan.md Part A §2 flinch) flying outward ~0.3m, fade + fall over 0.4s.
- When `_ward_hp` is drained to 0 mid-hit: play `Sfx.play("ward_break")` (bark-crack SFX) + a brighter outward burst.
- **DoD:** Fully soaked hit produces muffled SFX + chip particles; ward-break (drained by damage) produces crack SFX + burst; normal vigor hits play the existing `hit` SFX path unchanged.
- **Effort:** S–M

### Phase 3 — Dedicated painted icon + test coverage (hygiene pass)

- Commission or generate a painted `skill_ward.png` icon (Midjourney: `bark-wood shield crest, bold ink outline, flat cel-shaded, Bramblewood cozy style --ar 1:1`). Add it to `wyrd/assets/ui/icons/`, register in `skill_bar.gd::SKILL_ICON` and `loadout_panel.gd::SKILL_ICON`.
- Add absorb unit tests to `test_skills.gd`:
  - Assert `p._ward_hp == 30` after `HeartwoodWard.fire(p)`.
  - Assert `p._ward_hp == 22` and `p.hp == p.hp_max` after `p.take_damage(8, Vector3.FORWARD)` while ward is active.
  - Assert `p._ward_hp == 0` and `p.hp == p.hp_max - 2` after a 32-damage hit (30 soaked, 2 through).
  - Assert `p._ward_hp == 0` after simulating `WARD_SEC + 0.1` seconds via `_physics_process` calls.
- **DoD:** `WYRD_NO_SAVE=1 godot --headless --path . --script res://test_skills.gd` stays green and covers the four absorb cases above.
- **Effort:** S

### Phase 4 — Balance tuning (polish pass, post-playtesting)

This phase cannot be started until Phase 1-2 feedback makes the ward legible in play.

- Instrument absorb events: print `[ward] soaked %d / broke` in `take_damage` during dev, so playtest sessions produce a soak log.
- Key tuning levers (all in `heartwood_ward.gd`):
  - `WARD_HP`: 30 is the starting value; target range is 2-3 average enemy hits at the unlock depth (lv 7 / den depth ~2).
  - `WARD_SEC`: 8s feels safe; lower (5s) creates urgency and forces proactive casts; raise (10s) makes it a comfort blanket.
  - `cost` (25 Focus) vs `base_cd` (14s): the CD is already high enough that you can only cast it once or twice per room at full regen.
- If gear affix `cooldown_reduction` is equipped, the effective CD of 14s drops to `14/(1+CDR)`. At CDR cap 0.80 that is 7.8s — still one cast per encounter but double-cast in long boss fights is possible. No change needed here; that is the intended reward for gear investment.
- **DoD:** Playtest log shows ward soaks at least once per crypt run without feeling mandatory; if the ward is present in 100% of loadouts across three playtest sessions, reduce `WARD_HP` by 5 until it competes with offensive alternatives.
- **Effort:** S (tuning only)

### Phase 5 — Co-op extension (if multiplayer ships — deferred)

This is intentionally deferred until multiplayer Phase C is further along (see Plan.md Part A §4, `_net_cast` / `_net_forward_cast`).

- Design question to resolve first (see Open questions): is the ward self-only, or can one player cast it on an ally?
- If self-only: confirm the current `_net_cast` path's `apply_ward` on a puppet body is harmless (it is — the puppet's `_ward_hp` is irrelevant to the authoritative body; `take_damage` on the authoritative body ignores puppet state). Add a comment to `_net_cast` noting this.
- If "cast on ally": requires a new `@rpc` call targeting the ally's multiplayer authority, sending `(WARD_HP, WARD_SEC)`. The ally's authoritative `player_controller` calls `apply_ward` locally. Mirror the pattern of `_net_take_damage` (`player_controller.gd:1338`).
- **DoD:** In a two-player local session, Heartwood Ward either (a) correctly does nothing to the remote body with no spurious errors, or (b) applies a genuine absorb pool on the ally's authoritative body.
- **Effort:** S (self-only no-op confirmation) or M (cross-cast implementation)

## Dependencies & links

- [[system-skills-hotbar]] — The skill's slot, cooldown wedge, and glyph fallback all live in `skill_bar.gd`; Phase 1's ward arc indicator extends the existing `hotbar_slot.gd` `set_state` pattern.
- [[system-status-effects]] — Ward is a timed absorb pool, not a status effect, but any future "ward + status" interaction (e.g. a chart affix that extends ward duration) routes through the status framework.
- [[system-player-controller]] — `apply_ward`, `take_damage`, and the ward tick are all in `player_controller.gd`; all three phases touch this file.
- [[system-hud]] — Phase 1 ward arc lives here; the HUD readout design must fit the existing Focus/HP bar layout.
- [[system-combat-juice-vfx]] — Phase 2 bark-chip particles and absorb SFX are combat-juice work; reuse the scatter quad pattern from Plan.md Part A §2.
- [[system-multiplayer-netcode]] — Phase 5 cross-cast design depends on the Phase C netcode architecture; `_net_take_damage` is the pattern to mirror.
- [[skill-hunters-mark]] — Hunter's Mark is the other gated skill at lv 4; the two skills interact naturally (mark amplifies all damage, ward absorbs it).
- [[skill-mercy-shot]] — The third gated skill at lv 9; together the three gated skills form the "mid/late Huntcraft" suite that replaces default offensive loadouts.
- [[system-trades-progression]] — The lv 7 gate is enforced by `SKILL_REQS` in `game.gd`; progression pacing determines when the player first encounters the ward in the loadout panel.

**Plan.md cross-references:**
- Part A (combat feel, SHIPPED): the tween/scale/SFX toolkit in §1-§3 is the same vocabulary Phases 1-2 of this plan reuse — do not reinvent.
- Part B Phase B0 (`feel.gd` tunables): Phase 4 balance constants (`WARD_HP`, `WARD_SEC`) should be promoted to `feel.gd` once it exists, per the "one central tunables bag" decision in B0.
- Part B Phase B2 (harvest payoff particles): the bark-chip quad pattern in Phase 2 is a lower-fidelity cousin of the B2 scatter; share the implementation shape.

## Verification

- **Phase 1 (HUD + tint):** `WYRD_NO_SAVE=1 godot --headless --path . --script res://test_skills.gd` stays green (no regressions). Screenshot via `WYRD_SHOT=1` or `WYRD_UI_SHOT=hud` showing the arc indicator present when ward is active; mesh tint visible in a viewport screenshot (`mcp__blender__render_viewport_to_path` or `WYRD_SHOT=1`).
- **Phase 2 (absorb VFX):** Playtest session confirms muffled thud SFX plays on a fully soaked hit and is absent on a through-hit; bark-chip particles appear at the player position. No new failing `test_skills.gd` assertions.
- **Phase 3 (icon + tests):** `WYRD_NO_SAVE=1 godot --headless --path . --script res://test_skills.gd` green with the four new absorb assertions passing. `skill_bar.gd::SKILL_ICON` has a `HeartwoodWard` entry and the icon renders in the hotbar (screenshot).
- **Phase 4 (balance):** Three playtest sessions produce a soak-event log; ward present in <100% of loadouts at lv 7+ (if it was 100%, tuning succeeded).
- **Phase 5 (co-op):** `WYRD_NET=host` + a guest join; cast HeartwoodWard; confirm no errors in the console and the host body's `_ward_hp` is 30 (self-only path) or the ally's body is also protected (cross-cast path).

## Open questions

1. **Self-only or ally-cast?** The current implementation is self-only. In co-op, should a player be able to cast the ward on their partner? This is a high-effort design commitment; lean toward self-only until a playtester explicitly requests it.
2. **Stacking on re-cast?** If the player recasts before the first ward expires, should `_ward_hp` reset to 30 or cap at 30 (current behavior: `apply_ward` unconditionally overwrites `_ward_hp`; if it was already 15 due to partial absorption, recasting to 30 is a small bonus)? The current behavior is intentional but undocumented.
3. **Chart affixes that modify ward?** A future "Bark-Deep" chart affix (`+10 ward HP, -3 Focus`) is a natural fit. Should the ward constants be chart-affix-aware, or is gear-CDR the only indirect scaling we want?
