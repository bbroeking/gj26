# Spec 57 — First-Session Onboarding Storyboard

> **Outcome:** a first-time player reaches Mara without confusion, learns the
> four core verbs in a safe Snug Chart, returns to visible progress, completes
> one authored Tier 1 Hollow, discovers the Second Hand mystery, and chooses to
> make a third Chart without being ordered to do so.

> **Target length:** 25–35 minutes. This is the shot-by-shot implementation
> companion to [Spec 55](55-playable-first-chapter.md), not a separate tutorial
> mode.

## Direction

The opening is two small adventures, not seven software instructions.

1. **The Snug loop teaches:** move → gather → inscribe → fight → finish → return.
2. **The Tier 1 loop adds:** one Focus Skill → one ink choice → one Affix twin →
   one optional discovery → a reason to continue.

Every panel below names what the player sees, does, and learns. Guidance begins
as a quiet invitation, becomes more explicit only when the player stalls, and
disappears once the action is understood.

```mermaid
flowchart LR
    A["New Game"] --> B["Arrive at the Old Wagon Road"]
    B --> C["Meet Mara"]
    C --> D["Gather three herbs"]
    D --> E["Mix Hedge Ink"]
    E --> F["Inscribe and enter a Snug"]
    F --> G["Learn Basic Shot and find the first mark"]
    G --> H["Return: found, rose, opened"]
    H --> I["Learn Power Shot"]
    I --> J["Inscribe Tier 1 with one ink"]
    J --> K["Read one Affix and find the second mark"]
    K --> L["Return to Mara"]
    L --> M["Choose the third Chart"]
```

## Rules the opening must obey

- Start with **Basic Shot only**. Do not present three Focus Skills as though
  the player already knows them.
- Introduce no more than one new combat action and one new Chart rule per loop.
- Keep one primary objective on screen. Never stack a quest ribbon, tutorial
  modal, tooltip, NPC marker, minimap route, and interaction prompt at once.
- A blocking dialog page is at most two short sentences. Mara may use two pages
  for a milestone; ambient hints use one.
- Demonstrate before explaining. The player sees a shimmering herb patch before
  the word “forage,” an empty ink socket before ink odds, and an Affix result
  before an Affix lecture.
- The gold needle points toward the next required place, not every useful thing.
  Optional rooms and clues remain discoverable.
- The Codex records knowledge after it is encountered. It is a reward and
  memory aid, never required reading in the first session.
- Keyboard, mouse, and controller prompts come from the last-used input device.
  Do not write permanent keyboard-only instructions into dialog.
- Health, Focus, and the hotbar appear only when they become useful. Pack,
  Atlas, Skills, and equipment shortcuts are introduced on first relevance.

## Animated guidance language

Use short in-engine **storybook vignettes** at major handoffs. These are live
camera moves over the playable scene, not video files or separate cutscene
levels.

- **Arrival (about 5 seconds):** road → Mara and Waystone → return to player.
- **Herbs gathered (about 2 seconds):** player → Inscribing Table → player.
- **First Chart finished (about 2 seconds):** player → Waystone → player.
- Every vignette is skippable after a short input guard, plays only once per
  save, hides the gameplay HUD, stops player input, and lands the camera back
  where control resumes.
- A vignette may point at one destination and deliver one sentence. It must not
  explain a menu, play during combat, chain directly into another vignette, or
  exceed six seconds.
- Use the live Godot scene and already loaded assets so guidance adds no video
  download and no new scene-loading hitch on the web.

## Storyboard

### Panel 0 — The book opens

**Time / place:** 0:00–0:30 · title screen

**Picture:** The Bramblewood title rests over a quiet living landscape. One
clear primary action, **Begin**, has the strongest contrast. Continue appears
first only when a valid save exists. Settings and Codex are smaller secondary
actions.

**Player does:** Selects **Begin**.

**Game teaches:** This is a warm, readable adventure. The first click has an
obvious result.

**UI copy:** `Begin` · `Continue` · `Settings` · `Field Codex`

**Sound:** A short page-turn and one two-note Waystone motif. Avoid a long boot
cinematic before control.

**Success transition:** Fade through cream paper to the Old Wagon Road. The
player receives control within 15 seconds of selecting Begin.

**If stuck:** After six seconds without input, Begin takes a restrained golden
edge pulse. Nothing else animates for attention.

---

### Panel 1 — The new arrival

**Time / place:** 0:30–1:30 · Old Wagon Road, edge of the Chartmaker's Yard

**Picture:** The camera settles behind the player. The road, Mara's teal-and-gold
work area, and the Waystone form a readable triangle. Mara is visible but not
placed directly under the player's feet. A few herb patches glimmer off the
road, foreshadowing the next action.

**Player does:** Moves, turns the camera, and walks into the yard.

**Game teaches:** Movement and camera only.

**Objective:** `Follow the road into Bramblewood`

**Prompt:** Show the movement cluster for the detected device, then fade it as
soon as the player travels several body lengths. Do not show combat controls.

**Narration:** `The wagon road ends here. Bramblewood begins.`

**Success transition:** Crossing the yard threshold changes the objective to
`Meet Mara Linnet, the Wayfinder` and gives Mara one restrained nameplate.

**If stuck:** At 20 seconds, the road-edge flowers drift in Mara's direction.
At 35 seconds, reveal the gold needle. Never take camera control away.

---

### Panel 2 — Mara gives one useful job

**Time / place:** 1:30–3:00 · Mara's work area

**Picture:** At conversational distance, `[Interact] Talk to Mara Linnet`
appears beside Mara. On interaction, the world dims slightly but remains
visible. Mara's portrait, name, and text occupy a compact panel rather than a
full-screen parchment.

**Player does:** Interacts and advances two short pages.

**Game teaches:** NPC interaction, who Mara is, and the gather → ink → Chart
relationship. It does not explain Affixes, bosses, tiers, the Atlas, or the
whole campaign.

**Mara — page 1:** `New boots. Good. The yard could use a pair.`

**Mara — page 2:** `Bring me three wild herbs. We'll make a road small enough
to learn on.`

**Objective:** `Forage 3 wild herbs from the yard · 0/3`

**Success transition:** The dialog closes on the nearest visible herb patch,
which gives one soft shimmer. The health and hotbar remain hidden.

**If stuck:** Closing the dialog early still assigns the task. Talking to Mara
again produces one page: `The shimmer-green patches. Three will do.`

---

### Panel 3 — Hands in the hedge

**Time / place:** 3:00–5:00 · Chartmaker's Yard herb patches

**Picture:** When the player nears a patch it gains a soft outline and the
context prompt `Forage Wild Herbs`. The counter increments in the objective
ribbon. The pickup briefly travels toward the pack counter; no inventory grid
opens.

**Player does:** Forages three patches.

**Game teaches:** Interactable readability, gathering, and a counted objective.

**Barks:** First herb: `Wild Herb · 1/3`. Third herb: `Enough for one pot of
Hedge Ink.`

**Success transition:** The worktable answers with a small warm lamp and the
objective changes to `Mix Hedge Ink at Mara's table`.

**If the player gathers early:** Count herbs already held. Never require three
new clicks merely because Mara had not spoken yet.

**If stuck:** After 20 seconds without progress, glimmer the nearest unharvested
patch. After 45 seconds, the gold needle points to that patch rather than the
table.

---

### Panel 4 — The first recipe

**Time / place:** 5:00–7:00 · Inscribing Table, mixing view

**Picture:** The table opens directly to a stripped-down recipe card. It shows
three herb shapes flowing into one ink pot. All later recipes, Affix sockets,
and advanced tabs are absent or visually covered by Mara's working papers.

**Player does:** Selects `Mix Hedge Ink`, then collects the result.

**Game teaches:** A recipe consumes ingredients and makes a persistent item.

**UI copy:**

- `Hedge Ink`
- `Wild Herb 3/3`
- `Mix`
- Result: `Hedge Ink ×1 — enough to inscribe a Snug Chart`

**Mara bark:** `First pot. Keep it off your sleeves.`

**Success transition:** The interface turns one page to the Snug Chart rather
than closing and forcing the player to rediscover the same table.

**If stuck:** The ingredient row and Mix button pulse once in sequence. No
floating tutorial window covers the recipe.

---

### Panel 5 — Draw a small road

**Time / place:** 7:00–9:00 · Inscribing Table, Chart view

**Picture:** Only the Snug base is available. The result preview is a small,
friendly Chart card with no empty Affix slots inviting premature questions.

**Player does:** Selects the Snug base, inscribes, and takes the completed Chart.

**Game teaches:** Charts are crafted keys. This first one is fixed and safe.

**Result card:**

```text
Snug Chart
Gentle · No Affixes · 4–6 minutes
A small hollow for learning the road.
```

**Mara bark:** `A tidy little road. Don't crease it.`

**Success transition:** The Chart folds into the upper-right case icon. The
table closes, the Waystone emits the same two-note motif, and the objective
changes to `Socket the Snug Chart at the Waystone`.

**If the player leaves the table early:** Preserve every selection. The world
objective continues to point to the table until the finished Chart is taken.

---

### Panel 6 — Commit to the crossing

**Time / place:** 9:00–10:30 · town Waystone

**Picture:** Near the Waystone, the interaction prompt reads `Socket Snug
Chart`. The confirmation is a compact card, not a second crafting interface.

**Player does:** Sockets the Chart, reviews the summary, and chooses `Step
Through`.

**Game teaches:** A Chart is consumed by a run and the far Waystone brings the
player home.

**Commit card:**

```text
SNUG CHART
Gentle · No Affixes
Far Waystone: return home

[Step Through]   [Keep Chart]
```

**Mara bark from the yard:** `Far stone brings you home. Mind the thorns.`

**Success transition:** The portal opens immediately; finish background loading
during the preceding panels so the first crossing does not hitch.

**If stuck:** The first time only, a small line under the buttons reads `The
Chart is spent when the crossing opens.`

---

### Panel 7 — One bow, one danger

**Time / place:** 10:30–13:30 · first room of the Snug

**Picture:** Health appears only when danger can occur. The hotbar reveals one
large slot: **Basic Shot**. Focus is not yet shown because nothing spends it.
A harmless bramble target or slow lone thorn-imp waits at generous distance.

**Player does:** Aims, fires Basic Shot, moves, then rolls through one clearly
telegraphed pinch.

**Game teaches:** Basic Shot, threat telegraph, movement during combat, and
roll. The room is impossible to fail from one missed input.

**Prompt sequence:**

1. `Aim · Basic Shot`
2. After the first hit: `Move before it pinches.`
3. On the first large telegraph: `Roll clear`

Each line disappears when performed and never returns as a blocking modal.

**Success transition:** The gate opens, the tutorial text clears, and the
player hears the success chime attached to ordinary room completion.

**If defeated:** Return to the room entrance with full health and no lost
Chart. Mara's line appears once: `The Snug is patient. Try the step again.`

---

### Panel 8 — Let the player discover

**Time / place:** 13:30–16:30 · middle and far rooms of the Snug

**Picture:** A fork presents one obvious route and one shallow optional alcove.
The alcove contains a gather node or small chest. The far Waystone is visible
through composition and light, not a giant marker.

**Player does:** Fights one small group, optionally gathers or opens the chest,
then approaches the far Waystone.

**Game teaches:** A run can contain finds beyond its required path. The gold
needle communicates general bearing, not a painted route.

**First clue:** Beside the far Waystone is a hooked marginal mark. Inspecting it
shows: `A hooked mark, drawn where your hand never went.` The mark is recorded
silently in the Atlas after inspection.

**Completion prompt:** `Touch the far Waystone · Return to Bramblewood`

**Success transition:** Activating the Waystone gives a half-second tableau of
the mark and stone before the crossing. Do not identify the Second Hand yet.

**If the player misses the clue:** It sits on the guaranteed interaction arc of
the Waystone, but inspecting it is optional. Mara only reacts if it was read.

---

### Panel 9 — The return means something

**Time / place:** 16:30–18:30 · Chartmaker's Yard

**Picture:** On arrival, a compact three-row debrief appears over the living
yard. It never fills the full screen and dismisses with one action.

**Debrief:**

```text
THE ROAD BROUGHT BACK

FOUND    8 gold · Wild Herbs ×2 · [first item, if any]
ROSE     Wayfinding +XP · Level progress
OPENED   Power Shot · Tier 1 Hollow Charts
```

If there was no item, omit the empty item row. If the player leveled, replace
level progress with a clear `Wayfinding 2` moment.

**Player does:** Reads/dismisses the summary and chooses one preparation:
healing food, a useful material bundle, or a small gold purse. Each card says
what it enables in plain language.

**Game teaches:** Finds, progression, and new choices are different kinds of
reward.

**Mara — if the first mark was read:** `A hooked hand beside the far stone? I
didn't put it there.` / `Curiosity first. Conclusions later.`

**Success transition:** Focus appears. A single new Skill slot unfolds beside
Basic Shot, carrying the Power Shot icon and a `New` ribbon.

**If the player closes the debrief:** Rewards are already granted. A small
`Last crossing` card remains available at the Waystone until the next run.

---

### Panel 10 — One new Skill, safely learned

**Time / place:** 18:30–20:30 · practice target beside Mara's yard

**Picture:** The new slot and Focus orb are the only HUD elements drawing
attention. A practice bramble grows beside the table; it is not an enemy and
cannot hurt the player.

**Player does:** Uses Power Shot once, sees Focus decrease, and waits or uses
Basic Shot while it recovers.

**Game teaches:** Power Shot is a deliberate stronger hit, costs Focus, and
does not replace Basic Shot.

**Unlock card:** `Power Shot learned — one telling hit; costs 20 Focus.`

**Practice prompt:** `Try Power Shot on the practice bramble`

**Mara bark:** `Put your shoulder into this one. The hedge won't complain.`

**Success transition:** The bramble bursts into harmless leaves. The objective
becomes `Inscribe a Tier 1 Hollow Chart` and the table's advanced paper is
uncovered.

**If the player skips practice:** After one prompt, allow them to continue.
Their first Power Shot inside the Hollow triggers the same brief Focus hint.

---

### Panel 11 — Ink courts a path

**Time / place:** 20:30–23:30 · Inscribing Table

**Picture:** Tier 1 Hollow is the only newly highlighted base. One Affix socket
and Hedge Ink are visible. Hovering an ink previews a probability shift before
the player commits. Locked tiers are shown only as quiet silhouettes with level
requirements, not a wall of unavailable recipes.

**Player does:** Selects Tier 1, adds Hedge Ink, compares the before/after odds,
and inscribes.

**Game teaches:** Ink biases a Chart; it does not command the outcome. An Affix
has a helpful and troublesome twin.

**Table annotation:** `Ink courts a path. It does not command it.`

**Preview language:**

```text
Without ink          With Hedge Ink
Helpful 50%          Helpful 65%
Troublesome 50%  →   Troublesome 35%
```

Show the actual project probabilities. The numbers above describe the required
presentation, not a balance override.

**Resolved result:** Reveal exactly one twin with its gameplay effect, color,
and den-band change. Example: `Greenwake — more forage in the Hollow · Gentle`.

**Success transition:** The finished Chart goes to the case. The objective
becomes `Read your Chart at the Waystone`.

**If stuck:** After 20 seconds, Mara writes one animated underline from the ink
pot to the empty socket. Do not auto-fill it.

---

### Panel 12 — Read before you cross

**Time / place:** 23:30–24:30 · town Waystone

**Picture:** The commit card repeats the resolved Affix, its specific effect,
and the final den band. The helpful/troublesome color always appears with a
word and icon; color never carries meaning alone.

**Player does:** Reads the Chart and steps through.

**Game teaches:** The table creates the risk; the Waystone is the last chance
to read it.

**Commit card:** `Tier 1 Hollow · [Affix name and effect] · [Den band]`

**First-time footnote:** `Gold helps. Red bites harder and pays more.`

**Success transition:** Quick portal transition into a room whose composition
visibly demonstrates the selected Affix where possible.

**If the player backs out:** Keep the completed Chart. Returning to the table
does not reroll it.

---

### Panel 13 — The first authored Hollow

**Time / place:** 24:30–30:30 · Tier 1 Hollow

**Picture:** Three beats form the run: a readable combat room, an optional side
room, and the far route. Enemy composition asks the player to use Basic Shot
for rhythm and Power Shot for one priority target. No third Skill appears.

**Player does:** Reads the Affix in play, fights, chooses whether to investigate
the side room, and reaches the far Waystone.

**Game teaches:** Affixes change a real run, Power Shot has a role, and optional
curiosity can pay.

**One-time Affix callout:** `[Affix icon] Greenwake — forage grows thick here.`
The message appears in the world for three seconds; it is not a dialog.

**Second clue:** The optional room contains a scrap bearing the hooked mark in
fresh Hedge Ink. Inspect text: `The mark is wet. The ink is yours.`

**Reward:** The optional room gives a useful item or recipe fragment in
addition to the clue, so curiosity is mechanically respected.

**Success transition:** The far Waystone returns the player home. Run two may
be slightly harder, but the player should not need to grind, shop, or rearrange
a loadout to finish it.

**If defeated:** Preserve the observed clue and Codex entry, but do not award
completion XP. Offer `Try the same Chart again` and `Return to the yard`; the
first retry does not consume another Chart.

---

### Panel 14 — A question, then freedom

**Time / place:** 30:30–35:00 · Chartmaker's Yard

**Picture:** The second debrief uses the same Found / Rose / Opened grammar. If
the second clue was read, Mara notices the player before any quest marker asks
for her.

**Mara — page 1:** `Your ink? Let me see.`

**Mara — page 2:** `Same hand. Fresh line. Then something answered the Chart.
Or someone did.`

**Mara — final line:** `Draw another when you're ready. Curiosity first.`

**Player does:** Dismisses the debrief and receives three suggested, nonbinding
intentions:

- `Seek strength` — prepare another Hollow with a combat-leaning Affix.
- `Seek materials` — choose an ink that biases gathering.
- `Follow the mark` — inscribe any Chart and search its side rooms.

**Game teaches:** The tutorial has ended; goals can be authored through Charts.

**Final objective:** `Prepare your next Chart`

The objective is dismissible and has no progress counter. The Pack, Atlas, and
full town services may now be discovered through contextual prompts.

**Success condition:** The player opens the table, explores town, checks the
Codex, or leaves the game knowing why they might return. Do not immediately
replace the completed tutorial with a larger mandatory checklist.

## HUD disclosure schedule

| Beat | Objective | Health | Focus | Skill slots | Pack/Chart | Atlas/menu |
|---|---|---:|---:|---:|---|---|
| Arrival | one line | hidden | hidden | hidden | hidden | pause only |
| Herb task | one line + count | hidden | hidden | hidden | tiny pickup count | pause only |
| Table | inside panel | hidden | hidden | hidden | Chart case on result | pause only |
| Snug combat | one line | shown | hidden | Basic Shot | Chart state | pause only |
| First return | debrief | shown | shown | Basic + Power Shot | pack prompt | Codex unlock toast |
| Tier 1 | one line | shown | shown | two slots | Chart + ink | Codex available |
| Tutorial end | dismissible | shown | shown | earned slots only | available | available |

Locked Skill slots should not appear as empty circles during the opening. Empty
UI reads as missing content or an obligation to fill it.

## Recovery and edge cases

| Situation | Required response |
|---|---|
| Player already gathered herbs | Credit held herbs immediately. |
| Player spends or loses required herbs | Respawn tutorial patches quickly until the ink is mixed. |
| Player inscribes early | Advance to the first unmet meaningful action; never make them repeat it. |
| Player wanders away from Mara | Escalate from composition → subtle needle → direct objective hint. |
| Player closes a panel | Preserve selections and keep the world objective accurate. |
| Player misses a clue | Continue normally; clues enrich the hook but never block the run. |
| Pack is full | Tutorial-critical items enter a protected quest pocket or offer an immediate replace choice. |
| Player dies in the Snug | Retry from the room with no resource loss. |
| Player dies in Tier 1 | Keep observations; offer one free retry or safe return. |
| Player quits mid-run | Resume at the last safe room boundary when feasible; otherwise restore the unspent Chart. |
| Input device changes | Swap every visible glyph on the next input event. |
| Web load is slow | Keep title animation responsive, preload the Snug in the yard sequence, and never show a frozen first frame. |

## First-session content guarantees

The generator may vary the room shapes, but these teaching beats are fixed:

### Snug

- One safe combat-teaching room with one slow threat.
- One shallow optional alcove with a gather node or chest.
- The first hooked mark on the guaranteed far-Waystone route.
- No Affix, shrine, elite, status effect, inventory-management check, or boss.

### Tier 1 Hollow

- Exactly one resolved Affix and one short in-world callout.
- One combat room where Power Shot has an obvious priority target.
- One optional room with both a useful reward and the fresh-ink clue.
- No requirement to change gear or Skill loadout.
- No boss. The chapter ends with intrigue, not a difficulty spike.

## Instrumentation and playtest gates

Record timestamps and recovery-hint activations without recording player text.
The build is ready for a cold playtest when it can report:

| Gate | Target |
|---|---:|
| Control after selecting Begin | ≤ 15 seconds |
| First voluntary movement | ≤ 10 seconds after control |
| First conversation with Mara | ≤ 3 minutes |
| Snug Chart entered | ≤ 10 minutes |
| Snug completed | ≤ 18 minutes |
| Tier 1 Hollow entered | ≤ 25 minutes |
| First chapter completed | ≤ 35 minutes |
| Blocking tutorial overlays per scene | 0; dialog only at Mara/table commits |

After the session, ask the player to explain—without looking at the HUD—how
to:

1. Gather an ingredient.
2. Make and enter a Chart.
3. Fight and finish a run.
4. Return home.
5. Describe what ink changes.
6. Name one thing they want to do next.

Passing means the player can explain the first four, understands that ink
**biases rather than guarantees**, and volunteers a next intention. Exact game
terminology is not required.

## Implementation slices

### Slice A — disclosure and opening path

- Make the title-to-control path immediate and visually direct.
- Apply the HUD disclosure schedule.
- Keep only Basic Shot active and visible through the Snug.
- Replace the opening conversation with the two-page job.
- Add escalating, state-based recovery hints.

### Slice B — complete Snug lesson

- Guarantee the safe combat room, optional alcove, and first hooked mark.
- Make Snug defeat lossless.
- Ship the compact Found / Rose / Opened return debrief.

### Slice C — second-loop depth

- Unlock and safely demonstrate Power Shot.
- Teach one ink probability shift and one resolved Affix twin.
- Guarantee the optional Tier 1 room and fresh-ink clue.
- End on the three nonbinding third-Chart intentions.

### Slice D — validate and trim

- Add timestamp/recovery instrumentation.
- Run at least three cold first-time playtests on native and one on web.
- Remove any prompt that all participants complete without reading.
- Rewrite or reposition any beat that requires verbal coaching from the tester.

## Acceptance criteria

1. A fresh player receives control quickly and can identify the first social
   destination without a full-screen instruction.
2. Only Basic Shot is visible in the Snug; Power Shot is introduced after the
   first return; no other Focus Skill appears in the first chapter.
3. The first player action for every taught system occurs in context and is
   recoverable without restarting or consulting external documentation.
4. The Snug contains the fixed safe lesson, shallow optional discovery, and
   first clue while retaining procedural room presentation.
5. The first return distinguishes what was found, what rose, and what opened in
   one compact debrief.
6. The Tier 1 table makes ink bias and the resolved Affix effect legible before
   the player commits.
7. The second run demonstrates its Affix, rewards optional exploration, and
   guarantees the fresh-ink clue.
8. Mara reacts in no more than two short pages and does not explain the Second
   Hand.
9. Completion ends with a dismissible self-directed goal rather than another
   mandatory tutorial chain.
10. A cold playtester completes both loops within 35 minutes and can explain
    the four core verbs plus ink bias without coaching.
