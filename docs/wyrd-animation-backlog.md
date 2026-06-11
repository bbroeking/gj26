# Wayfinder — animation backlog (2026-06-12)

Animations owed to interactions that already shipped. Priority = feel
impact per hour. Most are tweens/particles in-engine, not authored clips;
the gathering set is the exception (needs pose work on the chibi rig).

## P1 — the verbs players repeat constantly

| Interaction | Animation needed | Notes |
|---|---|---|
| Gather channel (mine/chop/forage) | **Player swing/kneel poses per verb** + tool-in-hand during channel | The biggest gap: the chibi just stands while the bar fills. Models for tools exist; render the equipped pickaxe/axe in the hand socket during the channel, loop a swing every ~0.5s with a hit-spark on the node |
| Quaff (Q) | Drink pose + bottle prop + green heal sparkle rising | Currently instant; sell the sustain verb |
| Bench: socket snap | Dropped item scale-pops into the socket (0.9→1.05→1.0, ~120ms) | Tween on a drawn rect — fake it with a per-socket "pop" timer like the result stamp |
| Bench: pot mix | Puff of steam + swirl when a recipe completes; pot wobble | The mix is the tutorial's first magic moment — it should feel alchemical |
| Bench: craft | Scroll rolls up + wax-seal press; replaces the bare gold flash | The signature craft of the whole game |
| Chart socket at Waystone | Chart flies from case to stone, stone glow ramps | Sells "the chart is spent on the crossing" |

## P2 — combat reads

| Interaction | Animation needed | Notes |
|---|---|---|
| PiercingBolt | Pierce flash per punched-through enemy + a line trail | Reuses hit spark; trail = stretched quad |
| RainOfThorns | Falling thorn particles during the 0.6s telegraph → impact burst | Disc exists; the *rain* doesn't |
| Boar charge | Dust trail during dash + impact dust on wall stop | |
| Wolf pack-lunge | Motion blur/afterimage on each lunge | Cheap: 2-3 fading mesh ghosts |
| Loadout swap | Skill-bar slots flip/refill left-to-right on apply | The "take up this kit" moment |

## P3 — ambient + UI polish

| Interaction | Animation needed | Notes |
|---|---|---|
| HP/Focus globes | Liquid slosh on damage/heal; low-HP rim pulse | GlobeGauge is drawn — animate the meniscus line + a sin-wave surface |
| Tooltips | 80ms fade/slide-in | Currently pops |
| Tray drag ghost | Slight rotation + drop shadow while held | |
| Craft stations | Cookfire pot bubbles (particles), anvil ember sparks on craft | Stations are static primitives |
| Pack | Equip flash on doll slot; item settle-bounce on grid drop | |
| Cursor | Interact/attack swaps (art exists) + click ripple | Needs controller hover plumbing |
| Trades page | XP bar fill tween on open; cell unlock pop when a level-up unlocks something | |
| Toasts | Slide-up + fade instead of pop | |

## Implementation notes

- Drawn-UI "animation" = timed state + `queue_redraw` (the result-stamp
  pattern in crafting_bench.gd); don't reach for AnimationPlayer in panels.
- Player poses ride the existing procedural animator (`anim/` rotation
  rigs) — a swing is a keyed rotation loop on Arm_R + slight Body lean,
  NOT a Meshy re-rig.
- Particles: GPUParticles3D one-shots with the spec-34 soft_circle/ember
  textures already in assets/vfx/.
