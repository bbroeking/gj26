---
type: game
tags: [game-study, strategy, turn-based-tactics, permadeath, procedural-generation, campaign, roguelite]
status: draft
updated: 2026-06-14
sources:
  - https://www.gamedeveloper.com/design/a-deep-dive-into-xcom-and-xcom-2
  - https://gamerant.com/xcom-2-procedural-level-detail/
  - https://www.gamedeveloper.com/design/xcom-2-and-vision-the-cost-of-an-illusion
  - https://en.wikipedia.org/wiki/XCOM_2
---
# XCOM 2

Turn-based tactical strategy (2016, Firaxis Games / 2K), casting players as a guerrilla resistance fighting an alien occupation with a squad of permanently mortal soldiers across procedurally assembled maps and a timed campaign-layer threat counter.

## Design

- **Two-layer structure** — the **Avenger** (geoscape / strategic layer) manages base construction, research, resource allocation, and global mission scheduling; the **tactical layer** is a turn-based grid combat with cover-based positioning. Decisions in each layer directly constrain options in the other.
- **Permadeath with class depth** — soldiers earn class abilities (Ranger, Grenadier, Sharpshooter, Specialist, Psi Op) through XP and level up to Colonel rank. High-ranked soldiers carry irreplaceable ability combinations; losing them removes tactical tools permanently and shifts campaign strategy.
- **Plot-and-parcel procedural generation** — maps are composed from a hand-authored **plot** (fixed land layout defining overall shape and chokepoints) into which **parcels** (prefab building and encounter clusters) are randomly inserted. The system targets naturalistic, varied environments without the seam-visibility problems of fully random generation.
- **Avatar Project timer** — a doom counter that ticks toward game-over unless players disrupt alien facilities. Forces aggressive play and prevents turtling; missions exist on a calendar with consequences for ignoring them. Criticized by some players as anxiety-inducing but praised for momentum.
- **Cover asymmetry** — half cover reduces incoming hit chance by 25%; full cover by 50%. Flanking removes cover entirely. Simple math with dramatic tactical consequences, readable at a glance.
- **Concealment mechanic** — squads deploy in concealment, allowing pre-positioning before engagement. Leaving concealment (activating a pod) shifts the encounter entirely, as enemies gain immediate reaction advantages.

## Implementation

- Built in **Unreal Engine 3** (same base as XCOM: Enemy Unknown); the plot-and-parcel system required Firaxis to author a library of parcels compatible with any plot, with mission type parameters injected at runtime to vary objective placement.
- Enemy AI uses **pod-based activation**: enemy groups sleep until spotted or triggered, then activate together with scripted response behaviors. This was a deliberate shift from the original X-COM's dynamic AI that patrolled organically.
- The **War of the Chosen** expansion added faction heroes (Reaper, Skirmisher, Templar) with unique class mechanics, resistance ring management, and the Chosen—elite enemies that persist across missions with increasing threat levels, essentially adding a rogue-like "boss" pressure layer.
- Modding support via the **Steam Workshop** and an exposed Unreal SDK drove a large community mod ecosystem, including the Long War 2 total conversion that dramatically expanded the campaign structure.

## Why it matters

- XCOM 2 showed that **procedural level design can feel hand-crafted** if the procedural layer operates at the right granularity: randomizing parcel placement within a fixed plot skeleton preserves readability while delivering variety.
- Permadeath at class depth (not just level number) creates disproportionate narrative consequence from individual soldier deaths—a small player roster becomes a cast of characters without authored backstory.
- The Avatar Project timer is the genre's clearest articulation of **meta-progression urgency**: even resource-rich players cannot ignore the clock, preventing the mid-game entropy that plagues many strategy campaigns.

## Relevance to Wayfinder

- **[[Dungeon Generation]]** — the plot-and-parcel model (fixed skeleton, randomized content parcels) directly applies to Wayfinder's crypt/dungeon layouts: hand-authored room types as parcels slotted into chart-defined plot skeletons, giving variety without incoherence.
- **[[Balance Philosophy]]** — pod-based enemy activation (enemies idle until triggered, then respond in a burst) is a usable model for Wayfinder's dungeon encounter pacing, preventing the "enemies always pursuing" pressure while still rewarding careful approach.
- **[[Economy]]** — the Avenger resource competition (research vs. build vs. recruit) models how Wayfinder's gather→craft→chart loop could introduce meaningful inter-session resource trade-offs beyond single-run inventory management.

## See also

- [[Game Index]] · [[Game Studies]] · [[Design Influences]]
- [[Balance Philosophy]] · [[Economy]] · [[Dungeon Generation]] · [[Combat]]
- [[Into the Breach]] (Firaxis spiritual successor; pure tactics layer) · [[Civilization VI]] (shared developer; dual-layer design)

## Sources

- https://www.gamedeveloper.com/design/a-deep-dive-into-xcom-and-xcom-2
- https://gamerant.com/xcom-2-procedural-level-detail/
- https://www.gamedeveloper.com/design/xcom-2-and-vision-the-cost-of-an-illusion
- https://en.wikipedia.org/wiki/XCOM_2
