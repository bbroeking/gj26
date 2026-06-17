# Wayfinder System Map

A dependency / relationship overview of the plan notes. Nodes are grouped into
domain subgraphs; edges are the `links` declared between notes. The full link
set is dense (~220 undirected edges); this graph keeps **all intra-domain edges
plus the high-signal cross-domain spine** so the structure stays readable. For
the exhaustive per-note link lists, open each note.

**Hubs** (highest connectivity, the load-bearing systems):
`system-combat-juice-vfx`, `system-trades-progression`, `system-bosses`,
`system-charts-wayfinding`, `system-skills-hotbar`, `system-hud`,
`system-combatant-ai`, `system-status-effects`.

```mermaid
graph LR
  subgraph Player["Player & Abilities"]
    skillshotbar[system-skills-hotbar]
    status[system-status-effects]
  end

  subgraph Skills["Combat Skills"]
    basic[skill-basic-shot]
    power[skill-power-shot]
    multi[skill-multi-shot]
    snare[skill-bramble-snare]
    pierce[skill-piercing-bolt]
    rain[skill-rain-of-thorns]
    thorn[skill-thornburst]
    mark[skill-hunters-mark]
    ward[skill-heartwood-ward]
    mercy[skill-mercy-shot]
  end

  subgraph Prog["Progression"]
    trades[system-trades-progression]
  end

  subgraph Enemy["Enemies & Combat"]
    ai[system-combatant-ai]
    boss[system-bosses]
    elite[system-elites]
    juice[system-combat-juice-vfx]
  end

  subgraph GCE["Gather · Craft · Economy"]
    gather[system-gathering]
    craft[system-crafting]
    items[system-items-affixes]
    inv[system-inventory-equipment]
    drops[system-drops-loot]
    econ[system-economy]
  end

  subgraph Wyrd["Wayfinding & Dungeons"]
    charts[system-charts-wayfinding]
    affixes[system-chart-affixes]
    dungeon[system-dungeon-generation]
    biomes[system-biomes-decor]
  end

  subgraph World["World & Interactables"]
    town[system-town-hub]
    inter[system-interactables]
    cam[system-camera]
    npc[system-npc-story-tutorial]
  end

  subgraph MP["Multiplayer"]
    net[system-multiplayer-netcode]
  end

  subgraph UI["UI & Presentation"]
    hud[system-hud]
    panels[system-ui-panels]
  end

  subgraph Audio["Audio & Animation"]
    audio[system-audio-music]
    anim[system-animation]
  end

  subgraph Persist["Persistence"]
    save[system-save-load]
  end

  %% --- Combat Skills internal web ---
  basic --- power
  basic --- multi
  basic --- mark
  power --- multi
  power --- pierce
  power --- snare
  power --- mark
  multi --- pierce
  multi --- snare
  multi --- mark
  pierce --- rain
  snare --- rain
  snare --- thorn
  snare --- mark
  rain --- mark
  thorn --- ward
  ward --- mark
  ward --- mercy
  mark --- mercy

  %% --- Skills -> Player/Progression spine ---
  basic --- skillshotbar
  mark --- skillshotbar
  skillshotbar --- status
  skillshotbar --- trades
  skillshotbar --- ai

  %% --- Progression spine ---
  trades --- charts
  trades --- boss
  trades --- gather
  trades --- ai
  trades --- hud
  trades --- save

  %% --- Enemies & Combat ---
  ai --- boss
  ai --- elite
  ai --- status
  boss --- elite
  boss --- juice
  boss --- status
  boss --- items
  boss --- charts
  juice --- elite
  juice --- status
  juice --- hud

  %% --- Gather · Craft · Economy ---
  gather --- craft
  gather --- items
  gather --- econ
  craft --- econ
  craft --- items
  craft --- inv
  items --- drops
  items --- inv
  items --- econ
  drops --- inv
  drops --- econ

  %% --- Wayfinding & Dungeons ---
  charts --- affixes
  charts --- dungeon
  charts --- econ
  charts --- save
  charts --- panels
  charts --- hud
  affixes --- dungeon
  affixes --- biomes
  dungeon --- biomes
  dungeon --- inter

  %% --- World & Interactables ---
  town --- inter
  town --- npc
  town --- cam
  inter --- npc

  %% --- Multiplayer reach ---
  net --- boss
  net --- ai
  net --- cam
  net --- hud
  net --- status

  %% --- UI ---
  hud --- panels
  hud --- status
  hud --- skillshotbar

  %% --- Audio & Animation ---
  audio --- juice
  audio --- gather
  anim --- audio
  anim --- gather
  anim --- skillshotbar

  %% --- Camera juice ---
  cam --- juice
```

## How to read it

- **Combat Skills** form a tight internal mesh (synergy chains: Mark amplifies
  Power/Multi/Rain; Snare links the AoE family) and hang off
  `system-skills-hotbar`, which in turn is the bridge into **Progression**.
- **`system-trades-progression`** is the central spine: it touches the hotbar,
  charts, bosses, gathering, HUD, and save — the Wayfinding ladder is what ties
  the cozy-skilling loop to the combat loop.
- **`system-charts-wayfinding`** is the signature hub of the dungeon side,
  fanning out to affixes, generation, biomes, economy, and UI.
- **`system-combat-juice-vfx`** and **`system-hud`** are presentation hubs that
  almost every gameplay system feeds into — they are why a polish pass there
  (sparks, damage numbers, level-up banner, buff chips) lifts many notes at once.
- **`system-multiplayer-netcode`** reaches across into bosses, AI, camera, HUD,
  and status — the Phase C work is correctness glue that spans domains rather
  than a self-contained feature.

## A note on `system-player-controller`

Seven notes link to `[[system-player-controller]]`, but **no such note exists**
in the vault yet (it is the only dangling target — see the bottom of
[index.md](index.md)). It is omitted from the graph above. If authored, it would
sit in the Player & Abilities cluster as a hub between the hotbar, animation,
camera, and netcode.
