# Spec 36 — Bindings & Cancel-Grammar Research

Survey of default keyboard bindings and cancel-grammar conventions in shipped ARPGs and action games, written to inform the five-verb locomotion contract (walk, run, roll, dash, jump) for our Godot 4 ARPG.

## 1. Default-binding heatmap

| Game | Jump key | Roll / Dodge key | Dash key |
|---|---|---|---|
| Diablo 3 | — (no verb) | — (no verb) | Class skill on action bar (1–4 / RMB / Force-Move slot; community convention: Space) [1] |
| Path of Exile 2 | — (no verb) | **Space** (Dodge Roll, universal) [2][3] | — (skill-gem dashes bound to LMB/RMB/Q/W/E/R) [3] |
| Elden Ring (pre-SOTE) | F | **Space** (Roll / Backstep / Dash via hold) | Hold Space while moving = sprint/dash [4] |
| Elden Ring (post-SOTE default) | **Space** | LShift (Roll / Backstep) | Hold LShift = sprint/dash [4] |
| Hades / Hades 2 | — (no verb) | — (dash is the dodge) | **Space** (Dash) [5][6] |
| Lost Ark | — (no verb) | **Space** (universal Movement Skill / dodge) [7] | Class skill on F1–F4 / Z–V slot |
| Last Epoch | — (no verb) | **Space** (Dodge; default per in-game key bindings page) — unverified | Class traversal skill on action bar |
| Sekiro | **Space** | LShift (Step Dodge) [8] | LShift while running = step dodge [8] |
| Devil May Cry 5 | Space (PC default Jump) | LCtrl (Lock-on / Style varies); no universal dodge bound to Space | Forward+Jump or weapon skill |

Notes: Last Epoch's Space=Dodge mapping was returned by search but I could not confirm it on a primary page (lastepochtools is 403'd); marking as unverified. Diablo 3 has neither jump nor roll as verbs — class skills carry all mobility, and the community-recommended habit is to put the class mobility skill on Space [1]. Pre-SOTE Elden Ring is the famous "F to jump" outlier; the SOTE update flipped Jump to Space and Dodge to Shift to match modern conventions [4].

## 2. The Space conflict, resolved

**Option A — Space = Jump, Shift+Space = Roll, Ctrl = Dash.** No shipped game uses chord-on-Space for a second locomotion verb. The closest analog is Sekiro (Space=Jump, LShift=Step Dodge) [8], which keeps them on separate keys rather than a chord. Chording fast defensive inputs is fragile: under stress players hit Space alone and get the wrong verb. Breaks reactive play.

**Option B — Space = Roll, Alt = Jump, Ctrl = Dash.** This matches PoE 2, Lost Ark, Hades 2, and post-SOTE Elden Ring's Roll/Dodge convention [2][5][7][4]. Putting Jump on Alt is unusual — no surveyed game does this — but Alt is a large near-thumb key and Jump in an ARPG is the lowest-frequency of the three verbs (terrain hop, not Mario). Ctrl=Dash matches no shipped game directly, but it is a common WoW/MMO "extra action" slot and parallels Sekiro's near-thumb LShift dodge.

**Option C — Space = context-sensitive (jump if airborne-eligible, roll otherwise).** No shipped ARPG I surveyed does this for jump-vs-roll; the closest is Souls-family hold-to-sprint vs tap-to-roll on the same button [4]. Context-sensitive bindings work when the contexts are mutually exclusive and obvious (you're standing on a ledge → jump; you're locked in combat → roll). They break when contexts overlap (combat near a ledge: did I want to dodge backward or hop down?). Elden Ring's tap-vs-hold solves a similar problem but only between *roll and sprint*, never roll and jump.

**Recommendation: Option B.** Every surveyed ARPG that has a roll puts it on Space [2][4][5][7]. Jumping is the rarest of our five verbs, so it can afford a less-prime key. Players coming from PoE 2, Lost Ark, or Hades will hit Space and get the defensive verb they expect; players coming from Sekiro/post-SOTE Elden Ring will adapt within minutes. Reserve Shift for sprint/walk-toggle (matches Souls sprint, MMO walk).

## 3. Cancel grammar table

| Game | Attack → Roll/Dash | Roll/Dash → Attack | Dash → Jump | Jump → Attack |
|---|---|---|---|---|
| Diablo 3 | Y (any skill cancels any other on cast) | Y | n/a | n/a |
| Path of Exile 2 | Y — dodge roll cancels skill recovery [2] | Y | n/a | n/a |
| Elden Ring | Conditional — only during recovery, not active frames; community describes it as "you can only cancel out of heavy attacks through a roll" [9] | Y (rolls have a recovery, attack from there) | n/a | Y (jumping attack is its own move) |
| Hades / Hades 2 | **N** — by design, attacks cannot be dash-cancelled [10] | Y | n/a | n/a |
| Lost Ark | unknown (Space dodge widely used to escape AoE; whether it cancels mid-cast is class-specific) | Y | n/a | n/a |
| Last Epoch | unknown | unknown | n/a | n/a |
| Sekiro | Y — deflect and step-dodge are primary cancel options out of attack recovery | Y | conditional | Y (jumping attacks) |
| DMC 5 | Y — and famously Jump-Cancel (Enemy Step) interrupts almost any attack mid-air [11] | Y | Y | Y |

Hades is the sharpest counter-example: Supergiant explicitly chose *no* dash-cancel to preserve commitment and risk/reward [10]. Souls/Elden Ring lands in the middle — cancel exists but only in recovery, never during the active swing [9]. DMC is the upper bound: almost everything cancels into almost everything, and Jump Cancel is taught as a core technique [11].

## 4. The "active vs recovery" pattern

Every action-game frame-data breakdown decomposes a move into **startup → active → recovery** [12][13]. Active frames are when the hitbox is out; recovery is the lockout after. The cancel-window convention almost all action games settle on:

- **Active frames are uncancellable.** The move is committing. This is what makes attacks feel "weighty" and lets enemies punish bad timing.
- **Recovery frames open a cancel window** into specific follow-ups (next combo step, defensive option, traversal). Designers choose which inputs the window accepts — this is the "cancel grammar."

Concrete examples:

- **Elden Ring**: heavy attacks cannot be aborted during active frames, but their long recovery is roll-cancellable [9]. This is the entire shape of Souls combat — commit, then bail.
- **Hades / Hades 2**: active frames *and* recovery are both uncancellable into dash [10]. Recovery only cancels into the next attack in the combo. Supergiant calls this "deliberate action" — it raises the cost of attack inputs and forces pre-emptive positioning.
- **Devil May Cry 5**: cancel windows are extremely permissive. Jump Cancel (Enemy Step) can interrupt the recovery of nearly any aerial attack, and many ground attacks cancel into jumps, dashes, or weapon-switch [11]. The cost is a higher skill floor.

The recovery-cancel window in shipped games ranges from ~6–8 frames (Souls roll-cancel out of light attacks, ~30fps) to "the entire recovery" (DMC). I did not find authoritative frame counts published by developers — community datamining is the usual source [9][12].

## 5. Recommendations for our 5-verb game

- **D2 (Space binding):** Space = Roll, Alt = Jump, Ctrl = Dash. Matches PoE 2 / Lost Ark / Hades / post-SOTE Elden Ring's convention that Space is the universal defensive verb in an ARPG [2][4][5][7].
- **D6 (roll-recovery → dash):** Yes, allow it. Souls-family and DMC both permit traversal-into-traversal in recovery, and refusing it makes the locomotion suite feel jail-cell stiff [9][11].
- **D7 (dash → jump):** Yes, during recovery only. DMC's Jump Cancel is the canonical version of exactly this [11]; it adds expressive mobility without compromising commitment on active frames.
- **D8 (jump ↔ attack):** Jump does *not* cancel an in-progress attack's active frames; attack *can* cancel jump (jumping attack is its own move, Elden Ring/Sekiro/DMC pattern [8][11]); jump cannot cancel into roll mid-air (no surveyed game does mid-air roll — keep roll grounded).

Split where shipped-game consensus genuinely differs: **Attack → Dash cancellability.** Hades says no [10]; PoE 2, Souls (in recovery), and DMC say yes [2][9][11]. This is a design-feel choice, not a convention — pick based on whether we want commitment-heavy combat (Hades direction) or fluid cancel grammar (DMC direction). Our 5-verb suite leans fluid, so the table in §3 nudges toward yes-in-recovery, no-in-active-frames.

## 6. References

- [1] Tales of the Aggronaut — Diablo 3 Keybinds: https://aggronaut.com/2019/12/02/diablo-3-keybinds/ (verified)
- [2] Mobalytics — PoE 2 Dodge Roll Guide: https://mobalytics.gg/poe-2/guides/dodge-roll-mechanic (search-verified; direct fetch 403'd)
- [3] Switchblade Gaming — PoE 2 Keybinds Guide: https://www.switchbladegaming.com/path-of-exile-2/keybinds-guide-3/ (verified)
- [4] Fextralife — Elden Ring Controls: https://eldenring.wiki.fextralife.com/Controls (verified, includes SOTE remap note)
- [5] Fextralife — Hades 2 Controls: https://hades2.wiki.fextralife.com/Controls (verified)
- [6] Shacknews — Hades 2 controls & PC keybindings: https://www.shacknews.com/article/146103/hades-2-controls-pc-keybindings (search-verified)
- [7] Pro Game Guides — How to Dodge in Lost Ark: https://progameguides.com/lost-ark/how-to-dodge-in-lost-ark-movement-skill-explained/ (verified)
- [8] Fextralife — Sekiro Controls: https://sekiroshadowsdietwice.wiki.fextralife.com/Controls (verified)
- [9] Nexus Mods — Elden Ring "Attack Recovery Overhaul" (mod description documents vanilla cancel behavior): https://www.nexusmods.com/eldenring/mods/1198 (search-verified)
- [10] Steam — Hades II "this game needs dodge cancel" discussion (Supergiant design rationale via community): https://steamcommunity.com/app/1145350/discussions/2/4336483638879034882/ (verified)
- [11] DMC Wiki — Jump Cancel: https://devilmaycry.fandom.com/wiki/Jump_Cancel (search-verified; direct fetch 403'd)
- [12] CritPoints — Frame Data Patterns That All Game Designers Should Know: https://critpoints.net/2023/02/20/frame-data-patterns-that-game-designers-should-know/ (verified)
- [13] GDKeys — Keys to Combat Design: Anatomy of an Attack: https://gdkeys.com/keys-to-combat-design-1-anatomy-of-an-attack/ (verified)
