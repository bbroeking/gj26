# HUD design — what good ones do

> Research synthesis after a "the UI feels cluttered" playtest note.
> Sourced from: Mark Brown "How Games Use Heads-Up Displays" (GMTK
> 2020), the Dead Space diegetic-HUD postmortem (Visceral 2008),
> Game UI Database pattern catalog (Pierre Alexandre Roussel),
> Diablo IV UI development blogs (Blizzard 2023), Hades + Death's
> Door HUD breakdowns (Supergiant + Acid Nerve), Apple HIG, Persona
> 5's distinctive HUD analysis (GMTK).

## The four principles

Across every HUD that gets praised:

### 1. Information hierarchy

The single most-important piece of info should be the brightest, biggest,
or most-centered element. The least-important should fade into the chrome.
Hades nails this — the dash counter (your survival lifeline) is twice
the size of the cast counter (a recoverable resource). Doom Eternal —
ammo at the bottom, health to the left, armor to the right; the eye
sweeps in priority order.

> **Anti-pattern**: every UI element competing for the same level of
> visual weight. Eye doesn't know where to land. Brain works overtime.

### 2. Show when relevant, hide when not

The screen is real estate. UI shown when it doesn't matter dilutes UI
shown when it does. Boss bar in Dark Souls only appears during a boss
fight; the rest of the time, the screen is clean. Hades' dash counter
fades when you're not under threat.

Bramblewood's `#context-panel` already does this (4 states: adventurer
/ combat / gather / interact). The principle: extend it to ALL UI.

> **Anti-pattern**: a 10-line tutorial popup pinned to the corner six
> hours into the game.

### 3. Diegetic when possible

UI that exists "in the world" rather than "on top of the camera"
disappears into the experience. Dead Space's spine HP bar is the canonical
example — the player's character has a glowing HP gauge attached to their
back. No HUD overlay. Persona 5 stylizes UI to match the rebellious
graphic-design aesthetic; the menus ARE the game's vibe.

For us: floating XP numbers above an enemy after a kill IS diegetic.
A floating "+5 Coin" near the player's tile IS diegetic. A static "+5"
in a corner box would be non-diegetic. Bramblewood already prefers the
former; reinforce it.

### 4. Reduce decision frequency

Every UI element the player has to LOOK AT to make a choice is a
micro-burden. Persona 5's social-link fortune-telling lasts seconds
but the menu has 5 levels of nesting — most players don't engage
because the cost-to-evaluate is high. Hades' boon-pick screen is the
opposite: 3 cards, each with the upgrade summary 80% rendered already.

For us: action-bar slots with cooldown numbers ARE making a decision
("can I cleave now?"). Action-bar slots locked behind an empty placeholder
icon are NOT — they teach nothing.

## What the great HUDs all do

Pattern catalogue from the references:

| HUD pattern | Best-in-class example | What it does |
|---|---|---|
| **Health prominent, mana auxiliary** | Diablo II globe pair | HP is bigger because death-by-running-out is a 1-cost, mana is recoverable |
| **Cooldown radial sweep** | Diablo III, Hades, Bramblewood | Time-as-shape; brain reads "almost ready" without parsing a number |
| **Color = state, never just decoration** | Persona 5 (red = combat, blue = navigation) | Context conveyed without text |
| **Icon shape + color disambiguation** | Diablo IV affixes | If the player is colorblind the shape still differentiates |
| **Info density inverse to combat intensity** | Dead Space, Doom | Fewer overlays during fights, more in safe areas |
| **Single primary line of action** | Hades (top-down), Death's Door (top-right) | One spot the player ALWAYS looks first |
| **Negative space at the focal point** | Tunic, Hyper Light Drifter | Center is empty — that's where the play happens |
| **Auto-hiding chrome** | Last Epoch, Path of Exile | Stationary UI fades to 60% when player is moving |

## Anti-patterns we currently have

Honest read on Bramblewood's HUD today:

| Element | Anti-pattern | Why |
|---|---|---|
| `#title` "BRAMBLEWOOD" | Watermark | Has zero gameplay function after second 0; competes for top-center attention |
| `#fps` counter | Dev info on prod | Useful in dev, distracting in play. Lights up bright at top-right. |
| `#hints` panel default-open | Tutorial UI never hides | Players past tutorial don't need it; it eats the top-left corner |
| `#lab-links` always visible | Out-of-game UI on the in-game canvas | Codex / Editor links don't belong on the play surface |
| Long `#log-panel` | Wall of text in the corner | Players scan top-down; a 12-line chronicle reads as noise |
| `#hud-tools` row of emoji buttons | No labels | 5 emojis (🎒📖📜🗺📓) require memorization; players parse them every time |

We're solid on:

| ✓ | What |
|---|---|
| ✓ | Player bars (HP/Stamina) prominent top-left — correct hierarchy |
| ✓ | Skillbar bottom-center — eye returns there constantly, justified |
| ✓ | Minimap bottom-right — global standard, low cost |
| ✓ | Context-panel context-state-aware — adventurer/combat/gather already swap |
| ✓ | Floating XP/damage numbers diegetic |
| ✓ | Boss bar only-during-boss — correct |
| ✓ | Hover tooltips for tiles + abilities — context-on-demand |

## The cleanup pass

What we ship in this turn:

1. **Title auto-fade** — fades after 8s on first run, doesn't show on subsequent loads
2. **FPS counter dev-gated** — hidden unless `?dev` URL param OR a settings toggle
3. **Hints auto-close on first input** — opens once for new players, closes when they've moved/clicked, "?" button reopens
4. **Lab links collapsed into hamburger** — top-right gets a small ☰ that expands the Codex/Editor links on click
5. **Hud-tools labels** — text labels under each emoji button; grouped visually with the skillbar
6. **Log panel compact** — show last 4 lines, expand on hover; pulse-on-new keeps it useful

After this the always-on UI shrinks from 15 surfaces to **6 essentials**:
- HP/Stamina (top-left)
- Hamburger nav (top-right)
- Skillbar (bottom-center)
- Minimap (bottom-right)
- Compact log (bottom-left, expands on hover)
- Context-panel (right side, content-driven)

Plus 4 surfaces that appear only when needed:
- Boss bar (during a boss fight)
- Hud-tools panel (when bag/skills/etc are open)
- Floating numbers (during combat / pickup)
- Hover tooltips (on cursor)

That's the **"6 always, 4 contextual"** rule — a strong HUD baseline.

## Reading list

- Mark Brown, "How Games Use Heads-Up Displays" — GMTK 2020
- Visceral Games, "Designing the Dead Space HUD" — GDC 2008 vault
- Pierre Alexandre Roussel, *Game UI Database* — gameuidatabase.com
- Blizzard UI team, "Diablo IV UI Tour" — Blizz dev blog 2023
- Mark Brown, "How (and Why) Persona 5 Looks This Cool" — GMTK 2017
- Tomohiro Akiyama, "Persona 5 UI Design" — CEDEC 2017 (slides translated)
- Apple HIG, "Visual Design" — developer.apple.com/design/human-interface-guidelines

## Mantra

> "If the HUD is doing its job, the player doesn't notice it.
>  If the player is reading the HUD, the HUD is failing."
> — adapted from Brown
