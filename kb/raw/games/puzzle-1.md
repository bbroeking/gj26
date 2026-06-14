# Raw Source Digest: puzzle-1 — Puzzle Games Batch 1

Fetched: 2026-06-14
Feeds: wiki/games/puzzle/Portal 2.md, wiki/games/puzzle/The Witness.md,
       wiki/games/puzzle/Baba Is You.md, wiki/games/puzzle/Cocoon.md,
       wiki/games/puzzle/Return of the Obra Dinn.md

---

## Portal 2

Sources fetched:
- https://www.gamedeveloper.com/design/portal-2-game-design-review-part-1
- https://developer.valvesoftware.com/wiki/Game_Mechanics_(Portal_2)
- https://mechanicsofmagic.com/2024/05/15/critical-play-puzzles-ellie/
- https://medium.com/@oyunbozan2b2/portal-2-a-pacing-and-design-breakdown-b2bac5242713

Key findings:
- Mechanic isolation + recombination is the explicit design principle. New elements debut in dedicated single-purpose chambers before combining with prior elements.
- UI embeds into geometry (dotted lines, color-coded portal surfaces) — no overlaid tutorial text.
- Portal visibility system: portals remain visible through walls so players never forget which color was placed last — a deliberate UX affordance.
- Only one portal of each color can exist simultaneously: simplicity generating strategic depth.
- Co-op (Cooperative Testing Initiative): two portal guns multiply state space such that solo completion is mechanically impossible — enforces communication.
- Puzzle Maker (2012): in-engine community editor; used in formal education.
- Engine: Source (Valve), custom stencil-buffer recursive portal rendering.
- Wheatley / GLaDOS: narrative pacing layer; provides tension and motivation without interrupting puzzle flow.

---

## The Witness

Sources fetched:
- https://www.gamedeveloper.com/design/gaming-moments-01-how-the-witness-breaks-the-rules-of-puzzle-design-and-gets-away-with-it
- https://en.wikipedia.org/wiki/The_Witness_(2016_video_game)
- https://intermittentmechanism.blog/2017/08/18/lets-study-the-witness/
- https://thegemsbok.com/art-reviews-and-articles/the-witness-thekla-jonathan-blow-analysis-deconstruction/
- https://game-wisdom.com/analysis/the-witness

Key findings:
- Single interaction verb: draw a line on a panel. ~650 panels; ~11 distinct symbol languages.
- Zero text. Symbol rules are deduced entirely by observing patterns across multiple panels.
- "Solution-before-puzzle" sequencing: players receive a solution key (drawn map) as reward for a tutorial puzzle, then encounter the puzzle it unlocks later. Inverts normal design flow; deferred application makes discovery satisfying.
- Open structure as hint system: most of the island is accessible from the start, so players self-rescue by switching areas rather than grinding.
- Environmental "natural" puzzles: panel-tracing metaphor applied to shadows, reflections, and sounds in the world geometry itself.
- Engine: proprietary (Thekla Inc.). Spatially recorded ambient audio supports environmental puzzles.
- Released 2016 (PS4/PC). Jonathan Blow, creator of Braid.
- Divisive: late levels combine multiple symbol languages; some players find it transcendent, others find it cruel.

---

## Baba Is You

Sources fetched:
- https://www.gamedeveloper.com/design/designing-i-baba-is-you-i-s-delightfully-innovative-rule-writing-system
- https://en.wikipedia.org/wiki/Baba_Is_You
- https://www.paulwetzelgamedesign.de/baba-is-you-rule-creation
- https://cleverwasteoftime.com/baba-is-you-rulebending-mechanics-and-creative-problem-solving/

Key findings:
- Rule grammar: [NOUN] IS [PROPERTY], three pushable word tiles. Rules take effect instantly when formed; break instantly when words are separated.
- Win condition is itself a rule (FLAG IS WIN) — player can push it apart.
- Meta-words: TEXT, LONELY, MORE — rules that modify the rule system itself. Late-game requires multi-step logical chain construction.
- Lazy rule evaluation: engine only updates active rule set when a word tile moves, not every frame.
- Stacked/branching sentences (a word in two perpendicular valid sentences) required full engine rewrite.
- Engine: Multimedia Fusion 2 + Lua scripting. Released 2019 (PC/Switch), 2021 (mobile).
- Design constraint: too many initially-active rules overwhelm players; sparse starting state is required for elegant puzzles. Some levels were cut for this reason.
- Awards: D.I.C.E. Outstanding Achievement in Game Design; GDC Best Design; IGF Excellence in Design + Best Student Game.
- Creator: Arvi Teikari (Hempuli), Finland.

---

## Cocoon

Sources fetched:
- https://www.gamedeveloper.com/design/the-challenges-of-laying-worlds-upon-worlds-in-puzzle-game-cocoon
- https://en.wikipedia.org/wiki/Cocoon_(video_game)
- https://store.steampowered.com/app/1497440/COCOON/

Key findings:
- Core mechanic: carry worlds inside orbs; worlds can be nested inside each other to arbitrary depth. State of each world persists while player is elsewhere.
- Four orb abilities: invisible bridge manifestation, vertical-tower toggling, orb-cloning into eggs, cross-world projectile firing.
- Teaching method: single-variable-change-per-room. Director Jeppe Carlsen (formerly Playdead, designed Limbo and Inside) calls this "mental scaffolding."
- Boss encounters: introduce new movement mechanic as kinetic toy first, then integrate into puzzle solution. Purpose: decompression + pacing variety.
- Engine: Unity. Scene management substantially more complex than linear games — multiple complete worlds in memory simultaneously, swappable in seconds.
- Level design is recursive: testing one room requires setting up correct state of all surrounding worlds and orb nesting order.
- Rejected mechanic: rhythm-based orb (distracting in player testing).
- Linear structure (no branch points) — player cannot self-rescue by going elsewhere. Compensated by keeping per-room complexity low.
- Released Sept 2023. Metacritic 88–90. Awards: TGA Best Debut Indie; D.I.C.E. Outstanding Achievement Independent Game; Eurogamer GOTY 2023.

---

## Return of the Obra Dinn

Sources fetched:
- https://viciousundertow.wordpress.com/2018/11/08/return-of-the-obra-dinn-a-lesson-on-detective-games-and-hands-off-design/
- https://atomicbobomb.home.blog/2020/03/21/return-of-the-obra-dinn-lateral-information/
- https://en.wikipedia.org/wiki/Return_of_the_Obra_Dinn
- https://intermittentmechanism.blog/2024/05/20/the-interplay-of-puzzle-and-narrative-in-return-of-the-obra-dinn/
- https://www.kokutech.com/blog/gamedev/design-patterns/unique-mechanics/return-of-the-obra-dinn

Key findings:
- Player role: insurance assessor, 60 crew to identify.
- Tools: logbook (pre-populated crew portraits) + "Memento Mortem" pocket watch (reveals frozen death diorama + ambient audio).
- Each death requires three fields: name, cause, fate. Confirmation only when three entries are simultaneously correct and complete — prevents guessing, signals when reasoning is sound.
- Lateral information architecture: every vignette contains more data than needed for that scene alone; identifications in one scene unlock previously unsolvable scenes.
- Nonlinear exploration: any discovered corpse can be visited in any order; self-rescue by switching scenes.
- Identification vectors: visual (silhouette, posture, role-specific dress), audio (nationality-coded accents, vocabulary), positional (seen together in which scenes).
- Difficulty curve weakness: late game, elimination-by-deduction becomes trivially available when most fates are resolved — designer's control weakest at end.
- 1-bit dithered monochrome visual style: functional choice to reduce noise, focus player on shape and action over color/texture.
- Engine: Unity. Solo developer Lucas Pope.
- Released Oct 2018 (macOS/PC), Oct 2019 (Switch/PS4/Xbox).
- Awards: IGF Seumas McNally Grand Prize + Excellence in Narrative; BAFTA Artistic Achievement + Game Design; GDC Best Narrative; TGA Best Art Direction.
