# gj26 — Godot combat playtest checklist

The eval harness proves the combat *functions* (20/20). This checks how it
*feels* — FATE / Diablo as the bar: weighty, readable, satisfying before
it's hard. Play, rate each row, jot a note. Then the agent applies one
tuning pass.

## How to play

- **Browser:** http://localhost:8866/index.html  (re-exported with specs 17–21)
- **or native:** `godot --path godot`
- **Controls:** WASD / arrows move · **F** fire arrows · **Q/E** orbit camera · scroll to zoom
- Walk into a room, fight the enemies, find the boss room (the gates seal behind you).

## Rate each — `OK` / `too X` / a note

| # | Dimension | What to feel for | Constant(s) — current | Rating |
|---|---|---|---|---|
| 1 | Player move speed | brisk but controlled, not skatey | `player SPEED` 5.0, `ACCEL` 10.0 | |
| 2 | Fire cadence | satisfying rhythm; taps never dropped | `FIRE_COOLDOWN` 0.4, `INPUT_BUFFER_SEC` 0.15 | |
| 3 | Arrow speed/reach | reads as a shot, not a lob | `arrow SPEED` 18, `LIFETIME` 3.0 | |
| 4 | Hit feel (on enemies) | hitstop + flash = a real impact | `HITSTOP_SEC` 0.09, `FLASH_SEC` 0.12 | |
| 5 | Enemy knockback | proportional shove, not floaty/rigid | `KNOCKBACK` 0.6 | |
| 6 | Aggro radius | enemies wake at a fair distance | `AGGRO_RADIUS` 7.0 | |
| 7 | Enemy chase speed | a threat, but outrunnable | `MOVE_SPEED` 2.5 vs player 5.0 | |
| 8 | Telegraph readability | you can see an attack coming + react | enemy `TELEGRAPH_SEC` 0.35 | |
| 9 | Pathfinding | enemies route around walls, no corner-jam | (spec 19 navmesh) | |
| 10 | Getting hit | flash + hitstop + knockback land clearly | `HIT_KNOCKBACK` 4.5 | |
| 11 | i-frames | fair — not chain-stunned, not invincible | `IFRAMES_SEC` 0.6 | |
| 12 | Difficulty | enemy HP / damage vs player HP | `ENEMY_HP` 18, `ENEMY_DAMAGE` 5, `PLAYER_HP` 30 | |
| 13 | Death + respawn | the pause/respawn beat feels right | `DEATH_PAUSE` 1.2 | |
| 14 | Camera | distance + angle frame the action well | `ZOOM_DEFAULT` 13, `PITCH_DEFAULT` 55° | |
| 15 | Wall occlusion | player never lost behind a wall | (spec 14 fade) | |
| 16 | Boss — telegraphs | thorn-sweep / root-stomp danger zones read | boss `TELEGRAPH` 0.75/0.6/0.46 | |
| 17 | Boss — phases | phase shifts feel like the fight escalating | boss HP gates 66% / 33% | |
| 18 | Boss — attack damage | a real threat, not a stat-check | `BOSS_DAMAGE` 8 | |
| 19 | Boss — arena seal | the sealed-in moment lands | (spec 17 gates) | |
| 20 | Ranger walk | the procedural leg cycle reads as walking | `ranger_anim` SWING/CYCLE | |
| 21 | Rat | the hop-bob reads as a live critter | `rat_anim` bob | |

## Notes / anything else
_(free text — bugs, surprises, "this felt great", structural problems)_

---
_Once filled in, the agent applies the tuning pass (spec 22) and re-runs
`test_combat.gd`._
