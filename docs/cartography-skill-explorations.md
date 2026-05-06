# Cartography — Idea Explorations

> Companion to `cartography-skill-design.md` and `cartography-keystone-design.md`. The base design doc is "what we'd build if we kept it tight." This doc is **wider** — alternatives, weird ideas, dead-ends that might be cool, edge cases, social hooks, narrative threads. Each idea has a **what-if**, a **how it works**, **tradeoffs**, and a **question to discuss**.
>
> Goal: surface design choices we haven't made yet so we can reject or pull them in deliberately. Don't implement any of these without first deciding they're worth it.

---

## Section 1 — Alternative core verbs

The base design picked Survey + Sketch + Inscribe. Here are six other verbs that could replace or supplement them.

### 1.1 — The Pace Step (rhythm-based survey)

**What if** every step you take while walking has a rhythm, and matching the rhythm "paces out" the distance accurately for your map?

**How it works**: a faint metronome plays while traveling. Each step in-rhythm adds 1 "paced unit" of accuracy to the segment of path you're walking. Off-rhythm = inaccurate (segment bends slightly on the map). At Lv 1, you can only pace 5 units at a time. At Lv 50, 50 units. Paced segments contribute to route_card precision.

**Tradeoffs**: cool diegetic feel. But: rhythm games are accessibility-hostile, and players who aren't musical will hate it. Could be optional / off by default.

**Question**: Is rhythm-as-skill-input a good fit for cozy? (Stardew has fishing minigame; Sea of Thieves has shanties. Could work or could feel imposed.)

### 1.2 — The Theodolite (active-aiming survey)

**What if** instead of "place a pole, fix everything in radius," surveying is an active-aim verb?

**How it works**: hold a Theodolite, aim a reticle at a distant landmark, click → fix that one bearing. Three bearings on one feature = triangulated. Encourages players to *look* at the world.

**Tradeoffs**: more engaging than auto-radius. But: 3D aim with mouse → cozy game gets twitchier than it wants to be. Could limit to 2D top-down minimap aiming for accessibility.

**Question**: Does turning Cartography into a *first-person* mini-genre conflict with the rest of the game's WASD-isometric verb shape?

### 1.3 — The Compass-and-Pace ("dead reckoning")

**What if** the player has no GPS — the world map is blank until they explicitly survey, and direction is read from a compass tool?

**How it works**: minimap is OFF by default. Player carries a compass (always shows N). To move toward a known landmark, they have to remember the bearing they recorded. New surveys get added by triangulation (paragraph 1.1). Survey XP scales with how *unmapped* the current tile was.

**Tradeoffs**: dramatic, immersive, evokes 1700s exploration. But: brutal for new players who just want to *play*. Probably an opt-in "Hardcore Cartographer" mode.

**Question**: Is removing GPS too punishing for cozy, or does it unlock the era-feel we're chasing? (RuneScape didn't have a compass either; players asked NPCs for directions.)

### 1.4 — Sketch Channeling vs Sketch Sliders

**What if** sketching isn't a hold-still channel but a slider mini-game (Stardew fishing-style)?

**How it works**: press N near a feature → a sketch slider appears. Player has to keep a needle inside a moving target zone for ~3 seconds. Higher Cartography level = bigger target zone = easier sketches.

**Tradeoffs**: more *active* than channel. But: introduces a 2nd UI mode for the same verb, and combat-mid-sketch becomes impossible-to-cancel. Channel is simpler.

**Question**: Is "active-input sketch" worth the UI cost, given combat already forbids stand-still?

### 1.5 — The Memory Palace (sketch-from-memory)

**What if** sketching has *two phases* — Observe (close to feature) and Inscribe (back at the desk)?

**How it works**: walking near a feature for ~3s "observes" it (no item cost, no XP). At the desk, you can later "inscribe from memory" — but the observation fades over hours of game time. Late inscriptions give degraded sketches.

**Tradeoffs**: matches how real cartographers work. But: doubles the verb count and adds a memory-management UI. Might feel chore-y.

**Question**: Is the second-phase deliberation worth the friction? Or is one-step sketch (observe + inscribe simultaneously) cleaner for jam scope?

### 1.6 — The Geomancer's Stake (consumable area-mark)

**What if** you can plant a "stake" anywhere → for the next 1 in-game day, all sketches in 5 tiles around the stake are doubled XP?

**How it works**: stake item, single use, 24h server time effect. Encourages targeted "expedition" play.

**Tradeoffs**: economy-clean, gameplay variety. But: opens an exploit path (drop stake near constantly-respawning enemies → grinding).

**Question**: Should consumables modify XP rate at all, or is that going to drive bad behavior?

---

## Section 2 — Persistence + decay alternatives

The base design has 3-step decay (Vivid → Faded → Stale → Lost). Three alternative shapes:

### 2.1 — Real-world clock vs game-day clock

**What if** sketch decay tracks *real-world time* (a sketch fades if you don't return for a real week) vs *game-time* (sketch fades if 5 in-game days pass, regardless of real time)?

**Tradeoffs**: real-world FOMO is spicier (forces returning). Game-time feels cozier (you control the pace). RuneScape used real-time for trees (so players couldn't farm by AFK overnight) but in-game time for crops.

**Question**: Cozy = forgiving. Should we use game-time decay only? Or seasonal real-time (you have to come back at least once a season)?

### 2.2 — No decay; just collection-counter

**What if** sketches never decay — they stay forever, and the only progression is "have I sketched everything"?

**Tradeoffs**: relaxing, totally cozy. But: removes the persistent-FOMO lever. Probably weakens the mid-game loop.

**Question**: Is the FOMO from decay worth the anxiety it creates in a cozy game?

### 2.3 — Sketch erosion via copy-pressure

**What if** sketches don't decay on their own, but each time you *use* one in an inscription, it loses 1 quality step?

**How it works**: a sketch of an oak is "Vivid" until you spend it inscribing 3 charts → degrades to "Faded" → spend it 3 more times → "Stale" → eventually "Lost." Forces re-sketching specifically when you're a heavy crafter.

**Tradeoffs**: gameplay-emergent decay (only for heavy users). But: opaque to discover; players will be confused why their journal is degrading.

**Question**: Is implicit-on-use decay clearer or muddier than time-based decay?

---

## Section 3 — Social / multiplayer hooks

Currently the game is single-player. But Cartography is *the* skill that begs for sharing. Future-proofing:

### 3.1 — Chart Trading Post

**What if** an NPC at the Chartmaker's Stone runs a "Notice Board" where charts you inscribe can be sold to other (offline-AI) cartographers?

**How it works**: post a chart, set a price in coin or trade-for-ink. NPC simulates "demand" — popular chart types sell faster, rare ones sit. Persists across sessions.

**Tradeoffs**: gives Cartography an economic exit. Single-player; multiplayer-extensible. But: requires balancing prices, demand-curves, hoarding incentives.

**Question**: Is single-player simulated trading worth building, or wait until real multiplayer?

### 3.2 — Inscribed Letters (asymmetric multiplayer light)

**What if** charts inscribed by you can be exported as a code (already proposed in chart-share design), and a friend can import + run?

**How it works**: `btoa(JSON.stringify(chart))` → 60-char code. Friend pastes. They run *your* keystone with *your* affixes. Good runs become viral.

**Tradeoffs**: light social hook, no infrastructure. But: zero feedback loop (you don't know if friends ran your chart).

**Question**: Worth shipping a one-direction code without knowing whether anyone is using it?

### 3.3 — Cartographer's Guild (NPC-only, simulated leaderboard)

**What if** there's a guild of named NPC cartographers, and your XP / charts inscribed shows you climbing a roster?

**How it works**: 20 named NPCs with set XP totals (300, 500, 1200, 2400, ...). Player passes them as they level. Each "promotion" earns a small reward.

**Tradeoffs**: simulated belonging. Weak version of guilds, but no real social cost. Cozy-friendly.

**Question**: Does a fake roster feel like community or like loneliness with extra steps?

---

## Section 4 — Anti-grief and accessibility

Cartography has more friction than most skills. Worth thinking about who gets locked out.

### 4.1 — Accessibility — the "Quiet Cartographer" mode

**What if** there's a setting that disables sketch decay, doubles channel time tolerance, and removes the rhythm/aim mini-games?

**Tradeoffs**: makes the skill viable for players with motor or memory differences. Cost: zero — it's a setting, not a build branch.

**Question**: Should we ship Quiet mode by default at jam scope and add the harder modes later? Or commit to full mechanics from day one?

### 4.2 — Anti-grief — sketches you can't lose

**What if** the Field Journal is *bound* (can't be dropped, can't be stolen, can't be lost on death) — but specific sketches can be ripped out and traded?

**Tradeoffs**: protects collection. Allows trading without fear of losing the master record.

**Question**: Is bound = "always carry this" already a strong-enough commitment? Should we ever let players burn their journal to start fresh?

### 4.3 — Anti-burnout — XP capping

**What if** there's a soft cap of "no more than 50 sketch XP per real-day"?

**Tradeoffs**: prevents binge-grinding. Felt heavy-handed in WoW (rest XP); felt good in OSRS (no cap). Probably wrong for cozy.

**Question**: Do we cap XP gain at all, or trust players to pace?

---

## Section 5 — Cross-skill bleed

Cartography touches every other skill. Where do those edges live?

### 5.1 — Foraging × Cartography

**What if** plants you've sketched glow faintly on the minimap when in range, but only for sketched species?

**How it works**: knowing the plant's silhouette = recognizing it from afar. Implementation: minimap dot brightness based on `player.sketches.has(species)`.

**Tradeoffs**: makes Cartography support Foraging without taking over. Lovely synergy.

**Question**: Should the bonus apply to all sketched species, or only flora-category sketches?

### 5.2 — Combat × Cartography

**What if** sketching an enemy reveals their attack pattern in combat (telegraph window doubled)?

**How it works**: sketched creature → their telegraph indicators glow longer for the player who has them in their journal.

**Tradeoffs**: makes Cartography load-bearing for difficult fights. Reduces required reflex skill.

**Question**: Does this make Cartography mandatory for combat, breaking the "pursue what you love" promise?

### 5.3 — Mining × Cartography

**What if** sketching an ore vein once unlocks "ore deposit guesses" — small ?-icons appear on the minimap where ore *might* be?

**How it works**: per-region sketch unlocks 30% chance per discovered ore deposit to be hinted on the map.

**Tradeoffs**: pleasant treasure-hunt loop. Reduces miner's wandering.

**Question**: Does this devalue Mining's exploration, or enrich it?

### 5.4 — Cooking × Cartography

**What if** the Field Journal also tracks regional cuisine — sketches of unique food NPCs or recipe scrolls?

**Tradeoffs**: lets Cartographers feel relevant in a kitchen. But: scope creep.

**Question**: Stretch the journal beyond geography or keep it tight to map-making?

---

## Section 6 — Narrative + worldbuilding hooks

The Cartographer is a *role*. What does the world think of them?

### 6.1 — The Lost Cartographer (NPC quest line)

**What if** at Cartography 30+, an NPC arrives in the village asking for help — their cartographer mentor disappeared in the southern bog three years ago, and they need someone to retrace the route?

**How it works**: Multi-step quest. Find old surveyor poles in the bog. Inscribe a recovery map. Find the body. Inscribe their final atlas. Receive the mentor's compass (cosmetic + +5% sketch XP).

**Tradeoffs**: gives Cartography a soulful mid-game story arc. Cost: hand-written content.

**Question**: Worth one big handcrafted quest, or 5 smaller commissions?

### 6.2 — Cartographer's Curses

**What if** in folk-tradition, a cartographer who maps a "forbidden" place (bramble crown, hedgemother's den) earns a curse — minor mechanical consequence + diegetic story bit?

**How it works**: each forbidden sketch adds a curse-stack. At 3 stacks, the player has nightmares (a darker overlay on screen at night). Stacks decay over time. Curses can be cleansed via the Cloister NPC.

**Tradeoffs**: gives bigger sketches teeth. Cost: subtle systems.

**Question**: Is cozy + curses too tonally weird, or does it hit the right "quirky charm" note?

### 6.3 — The Master Cartographer's Atlas as a *village* artifact

**What if** the player's final Atlas isn't a personal cape but becomes a permanent fixture in the village tavern, where other adventurers can "consult" it (i.e., NPCs reference your name)?

**How it works**: village tavern gets a wall-frame. Walk in, see a giant map with your sketches drawn on it. NPC barkeep says "the Cartographer's atlas — best in the wolds." Title persists across saves.

**Tradeoffs**: legacy-building feel. Costs: small NPC dialogue + a wall mesh.

**Question**: Is a village artifact more or less rewarding than a personal cape? (Lean: ship both. Cape for combat, atlas for hangout.)

---

## Section 7 — Wild ideas worth questioning

The genuinely-weird ones. Most won't make it; one or two might.

### 7.1 — The Sketch as Drawing Mini-Game

**What if** sketching opens a tiny pixel-art canvas where the player has 10 seconds to actually click-draw the subject?

**Tradeoffs**: hilarious, soulful, totally on-brand for "indie game wears its handmade-ness." But: player drawings will be terrible, mocking real cartographers. Could be a v2 cosmetic feature.

**Question**: Could we ship a *non-judgmental* version — every drawing is "approved" no matter what?

### 7.2 — Multi-page sketches (folio)

**What if** big features (a whole village, a dungeon entry) require *three* sketches at different angles, recorded as a 3-page folio?

**Tradeoffs**: handles "sketch the cathedral" prestige features. Cost: UI complexity.

**Question**: Is this too crunchy? (Lean: yes, cut it. Single sketch per subject is enough.)

### 7.3 — Borrowed sketches

**What if** Quill / Hod / Withering have already sketched 1-2 things, and you can copy from their journal (but the copy is only "Faded" quality)?

**Tradeoffs**: helps onboarding (Quill teaches you what an oak looks like). Costs: more NPC dialog.

**Question**: Worth handing players a starter journal of 3 NPC-sourced sketches?

### 7.4 — Anti-cartography (the Forgotten Map)

**What if** there's a counter-skill — *Forgetting* — where dropping a sketch (deliberately) increases its mystery value to other players, possibly as a quest item?

**Tradeoffs**: weird, narrative-rich. Probably out of scope.

**Question**: Tabled until multiplayer.

### 7.5 — Sketch reactions

**What if** other in-world NPCs *react* to seeing your journal — Maud asks to leaf through it, Quill points at your bramble-imp sketch and says "his eyes are too far apart"?

**Tradeoffs**: charming, makes the journal social. Costs: NPC dialog branches per-sketch.

**Question**: Worth NPC-touched journal hooks for a few key sketches, or skip?

---

## Section 8 — Failure-mode catalog

What can go wrong, why, what to do about it. This is the "before we build, anticipate" section.

| Failure | Cause | Mitigation |
|---|---|---|
| Player never finds the verb | N keybind not discoverable | Onboarding NPC dialog at the chartmaker stone teaches it |
| Sketches feel pointless | No reward loop visible | Show XP gain + journal entry + "+sketch flora" floater on completion |
| Per-tile XP nerf hurts feel | Players walked + got XP, now they walk + get nothing | Ship +2 trickle (current) + sketch XP burst for asymmetric reward |
| Sketch decay surprises returning players | They come back after a week, journal looks half-rotted | Soft warn at first decay event ("Your oak sketch is faded — sketch it again to refresh") |
| Triangulation feels like math homework | Three poles, where do I put them? | Visual guide: when 1 pole down, ghost-circles show valid 2nd-pole positions |
| Players grind via cheap species | Repeat sketching same chicken | Already mitigated: re-sketches give 30% XP |
| Rare species camp | Player camps at a rare creature spawn for first sketch | Limit: each species sketches once per real-day |
| Inscription resource sink too steep | Need 4 vellum + 3 ink for one chart, players never craft | Tune costs in playtest; set a "first 10 charts free of refined ink" tutorial bonus |
| Falcon recon trivializes vistas | Player sends falcon everywhere, walks nowhere | Falcon recon costs charges; only available Lv 60+ |
| Atlas legendary too long | Player burns out at 80% completion | Soft milestone rewards every 25% (small cape, scarf, hat) before the full cape |

---

## Discussion checklist

Bring to a design call. For each, mark **YES / NO / NEEDS DESIGN**:

1. Should Cartography level by walking at all (the +2 trickle), or remove entirely so all XP comes from active verbs?
2. Channel-based vs slider-based sketch?
3. Real-time decay vs game-time decay vs no decay?
4. Theodolite (active aim) or Surveyor's Pole (drop and radius-fix)?
5. Specialty paths exclusive (pick one) or all-pursuable?
6. Falcon recon line-of-sight, anywhere, or remove?
7. Treasure maps in scope for Phase A-D, or v2?
8. Cartographer's Cape — combat cosmetic only, or +stats too?
9. Atlas — personal trophy or village artifact (or both)?
10. NPC commissions — auto-generated or hand-written?
11. Sketch trading post — single-player simulated, or wait for multiplayer?
12. Anti-grief: bound journal? Capped daily XP? Soft caps? None?
13. Cross-skill bleed: which is cleanest first hook? (Foraging plants on minimap, lean)
14. The Lost Cartographer quest — handcrafted now, or commission template?
15. "Draw a real picture" mini-game — yes/no/never?

## Recommended go/no-go (my read)

If we had to ship a tightened v1.5 right now:

**YES**:
- Pole + sightline survey (1.4 from base doc)
- Channel-based sketch (1.4 here, channel wins)
- Game-time decay only (2.1)
- Specialty paths all-pursuable (base doc)
- Plants-on-minimap (5.1, the cleanest cross-skill hook)
- Lost Cartographer quest (6.1, but commission-template version)
- Atlas as both cape AND village artifact (6.3)

**NO** (this iteration):
- Compass-and-pace mode (1.3) — too punishing
- Memory palace (1.5) — doubled UI cost
- Rhythm/active-aim verbs (1.1, 1.2) — accessibility-hostile
- Real-time decay (2.1) — too anxiety-inducing
- Combat × Cartography telegraph bonus (5.2) — makes carto load-bearing
- Drawing minigame (7.1) — out of scope
- Sketch erosion (2.3) — opaque

**NEEDS MORE DESIGN**:
- Trading post (3.1) vs share-codes (3.2) — economy choice
- Cartographer's Curses (6.2) — tonal experiment
- NPC-borrowed starter sketches (7.3) — onboarding tradeoff
- XP cap (4.3) — pacing question

## Where this lands us

The base design doc + this exploration give about **40 distinct mechanics** to choose from. Ship the YES list above as the actual scope, leave the NO list out, and bring the NEEDS-DESIGN questions to a 30-min talk before Phase B begins.

The point of *this* doc: have the menu visible so we don't fumble into an idea we haven't questioned.
