# Raw Sources: Puzzle / Programming — Batch 2
*Ingested: 2026-06-14 | Pages produced: Opus Magnum, Shenzhen I/O, Human Resource Machine, SpaceChem*

---

## Opus Magnum

- **Wikipedia** — https://en.wikipedia.org/wiki/Opus_Magnum
  Release Dec 2017; hex-grid transmutation; arms (manipulators) run simultaneously; 3-axis leaderboard (speed, cost, area); GIF export; Metacritic 90; IGF Excellence in Design 2018; descended from *Codex of Alchemical Engineering* (2008 Flash).

- **Zachtronics Official** — https://www.zachtronics.com/opus-magnum/
  "Open-ended puzzles"; three competing metrics; Steam Workshop; *Sigmar's Garden* solitaire bonus; GIF sharing as first-party feature.

- **GDC Vault 2019** — https://gdcvault.com/play/1025715/Open-Ended-Puzzle-Design-at
  Zach Barth GDC talk: puzzles shipped unsolved by designers; aesthetic as hidden 4th dimension; histogram vs. leaderboard rationale; open-endedness generates replayability without new content.

- **Steam store page** — https://store.steampowered.com/app/558990/Opus_Magnum/
  Confirmed Switch port; Early Access Oct 2017 → full Dec 2017.

---

## Shenzhen I/O

- **Wikipedia** — https://en.wikipedia.org/wiki/Shenzhen_I/O
  Released Nov 2016; assembly-like language; MCUs + logic gates + RAM; 41-page manual; inspired by Andrew "bunnie" Huang's Shenzhen blogs; spiritual successor to TIS-100 (2015); IGF Excellence in Design nomination 2018; Lua-scriptable level system; Shenzhen Solitaire spinoff Dec 2016.

- **Zachtronics Official** — https://www.zachtronics.com/shenzhen-io/
  "Construct circuits and write code"; histogram optimization (cycles, power, LOC).

- **Inverse interview with Zach Barth** — https://www.inverse.com/article/23382-shenzhen-io-zachtronics-zach-barth-interview
  "Selective authenticity" principle; explicitly NOT educational; "feel like wizards"; manual as transmedia fiction; MIT four learning freedoms; problem-solving > solutions; "so much of programming is not fun" — stripped the tedium.

- **Steam store page** — https://store.steampowered.com/app/504210/SHENZHEN_IO/
  Confirmed platforms, pricing notes.

---

## Human Resource Machine

- **Wikipedia** — https://en.wikipedia.org/wiki/Human_Resource_Machine
  Released Oct 2015; Tomorrow Corporation (Gabler/Blomquist/Gray); ~40 puzzles; 2 → 11 commands; inbox/outbox Harvard architecture; Metacritic iOS 86; sequel 7 Billion Humans (2018) adds multi-agent parallelism; Hour of Code edition (school adoption).

- **Tomorrow Corporation Official** — https://tomorrowcorporation.com/humanresourcemachine
  "Programming is just puzzle solving"; accessibility-first ("you don't actually need to know any of the below"); drag-and-drop; corporate satire ("Management is watching"); optimization challenges per level (size + speed).

- **Medium — Rachael Versaw** — https://medium.com/@rachaelversaw/human-resource-machine-teaching-coding-basics-56e79e7db175
  Office metaphor rationale: physical analogy makes Harvard architecture legible; absence of syntax removes friction; teaches loops, conditionals, memory addressing without naming them.

---

## SpaceChem

- **Wikipedia** — https://en.wikipedia.org/wiki/SpaceChem
  Released Jan 2011; Zachtronics Industries; two waldos; C#/Mono; $4,000 budget; Barth quit Microsoft after commercial success; ResearchNet added Apr 2011; school adoption UK; Metacritic 84.

- **Game Developer postmortem** — https://www.gamedeveloper.com/design/postmortem-zachtronics-industries-i-spacechem-i-
  What went right: open-ended puzzles; histogram vs. leaderboard (cheating prevention + fairness); low-risk dev model; C# tooling; multiple distribution channels. What went wrong: chemistry theme deterred casual audience; only 2% completion; tutorial overloaded too many mechanics at once; story gated behind hardest content; failed metrics infrastructure. Broad lessons: open-ended > prescribed; histograms > leaderboards; tutorial failure = design failure; story should end before difficulty peaks.

- **Grokipedia** — https://grokipedia.com/page/SpaceChem
  Factory pipeline layer (reactor-to-reactor piping); "invention vs. discovery" framing.

- **Gregor Ulm review** — https://gregorulm.com/programming-game-review-spacechem-2011-by-zachtronics/
  "Inventing a solution" quote; analysis of waldo system depth.

---

## Cross-cutting notes

- Histogram design introduced in SpaceChem, carried forward to Opus Magnum, Shenzhen I/O, and EXAPUNKS (confirmed via GDC talk and Grokipedia).
- "Open-ended puzzle design" talk at GDC 2019 covers all four games and is the canonical statement of the Zachtronics design pattern.
- SpaceChem postmortem is the most analytically useful document for tutorial design and content pacing lessons.
- Tomorrow Corporation (Human Resource Machine) shares the "no prescribed solution" and "optimization challenge" patterns with Zachtronics but is a distinct studio.
