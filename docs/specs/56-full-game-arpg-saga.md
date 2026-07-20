# 56 — Full-game ARPG systems, level-23 Trades, and the Root Saga

**Status:** Full-game design / implementation source of truth

**Direction locked:** 2026-07-17 via
[ADR 0016](../adr/0016-four-trades-level-23.md) and
[ADR 0017](../adr/0017-local-norse-root-saga.md)

**Research:** [ARPG systems and Norse campaign source research](../research/arpg-systems-and-norse-campaign-sources.md).
The mechanical references are used as patterns, not copied feature-for-feature.

## Outcome

Grow the current playable chapter into a complete cozy ARPG with:

- four Trades, each independently levelable from 1 to 23;
- a carefully staged combat-Skill onboarding instead of nine abilities at
  the beginning;
- a campaign that is delivered through repeatable, random charts;
- collected clues and trophies that are crafted into deterministic boss
  charts;
- new biomes, buildings, items, enemies, bosses, recipes, and icons paced
  across the same progression ladder; and
- one legendary bow, **Wayweaver**, that requires mastery of the whole game.

The complete player loop is:

```text
arrive in Bramblewood
  → gather and learn a Trade
  → make tools, brews, inks, and gear
  → inscribe a random chart
  → delve for materials, clues, and mastery
  → assemble a boss chart
  → defeat / quiet / free the chapter boss
  → bring home its Root Rune
  → restore a town building and open the next biome
  → master all four Trades
  → forge Wayweaver
  → inscribe the Unwritten Road
```

The research supports this structure from three directions: official ARPG
documentation repeatedly uses repeatable keyed runs, visible milestone
progress, authored bosses, targetable rewards, and permanent unlocks; Norse
sources place fate, knowledge, damage, and renewal around a living root system;
and the source tradition itself is inconsistent enough that an original local
myth is more faithful than a rigid franchise pantheon. The companion note links
the official documentation and academic/primary-text editions claim by claim.

---

## 1. The ARPG systems inventory

This is the comprehensive system menu. “Now” means it belongs in the level-23
game; “Deepen” means a shipped system needs more content or clarity; “Later”
is optional after the campaign; “Avoid” means it works against Wayfinder.

### 1.1 Moment-to-moment play

| System | Wayfinder form | Call |
|---|---|---|
| Movement | readable click/keyboard movement, collision, acceleration, pathing | Deepen |
| Camera | FATE-style isometric follow, occlusion handling, shake restraint | Deepen |
| Targeting | cursor aim, hover feedback, clear interact/attack states | Deepen |
| Primary attack | fixed free Basic Shot; always available | Keep |
| Active Skills | three chosen actions from a gradually unlocked pool | Deepen |
| Combat resource | Focus; spend rhythm, out-of-combat recovery | Keep |
| Defensive verb | movement first; one earned Threadstep at late game | Now |
| Hit resolution | damage, crit, super-crit, armor/grit, level delta | Deepen |
| Health/recovery | Vigor, draughts, rest sites, death return | Deepen |
| Interaction | one consistent prompt for NPCs, stations, loot, clues | Deepen |
| Feedback | hit flash, numbers, impact, sound, telegraph, controller rumble | Deepen |

### 1.2 Combat depth

| System | Wayfinder form | Call |
|---|---|---|
| Enemy roles | chaser, flanker, ranged, tank, support, disruptor | Now |
| Pack composition | authored role budgets selected by biome/depth | Now |
| Telegraph language | shared shapes/colors/timings across enemies and bosses | Deepen |
| Status effects | bleed, slow, root, mark, burn, ward; few and legible | Keep |
| Crowd control | roots, knockback, brief stagger; bosses answer with Poise | Deepen |
| Elites | one or two readable modifiers plus stronger rewards | Deepen |
| Hazards | biome rules: fog, mud, cave-ins, cinders, root pulses | Now |
| Boss phases | three-beat fights with story interaction between phases | Deepen |
| Poise / Reeling | reward correct reads with a short damage/Skill-reset window | Now |
| Encounter objectives | clear, survive, protect, hunt, interrupt, retrieve | Now |
| Difficulty preview | “easy / fair / very hard” from player↔den level delta | Deepen |
| Co-op scaling | host authority, per-player loot, role-safe boss mechanics | Deepen |

### 1.3 Character growth and build expression

| System | Wayfinder form | Call |
|---|---|---|
| Trade levels | Wayfinding, Earthcraft, Wildcraft, Huntcraft; each 1–23 | Now |
| Per-level unlocks | every level grants a visible verb, recipe, gate, or mastery | Now |
| Skill onboarding | Basic Shot first; new actions at spaced Huntcraft levels | Now |
| Loadouts | three configurable Skill slots; swap only in town or at a Hearth | Deepen |
| Gear slots | weapon, helm, chest, boots, ring, pickaxe, axe | Keep |
| Gear tiers | Brindle → Bogiron → Palechalk → Starsilver → Hedgesteel → Wildgold | Now |
| Item rarity | normal, magic, rare, unique, legendary | Deepen |
| Affixes | small readable stat pool; no affix text soup | Deepen |
| Enchants | crafted/discovered charms that add a behavior or Skill modifier | Deepen |
| Uniques | named items with authored properties and acquisition stories | Deepen |
| Legendary pursuit | one account-defining multi-Trade craft: Wayweaver | Now |
| Respec | mastery choices can be re-inked for a material cost | Now |
| Cosmetics | visible town restoration, titles, capes, weapon appearances | Later |

### 1.4 Loot, crafting, and economy

| System | Wayfinder form | Call |
|---|---|---|
| Loot tables | biome + enemy-role + depth + chart-affix aware | Deepen |
| Smart loot | mild weighting toward missing slots; never fully deterministic | Now |
| Materials | stackable satchel; resources stay distinct from gear-grid items | Keep |
| Inventory | spatial pack for gear, separate materials satchel | Keep |
| Equipment | comparison, equip, visible model attachment, derived stats | Deepen |
| Gathering | tiered ore, herbs, logs, rare story resources | Deepen |
| Refining | ore→bar, herb→brew, materials→ink/charm components | Deepen |
| Crafting | station recipes, discovery riddles, masterwork variants | Deepen |
| Enchanting | bind a known charm into a compatible gear slot | Deepen |
| Salvage | unwanted gear→scrap/dust; never full-value conversion | Now |
| Vendors | dependable basics, rotating curios, level-gated stock | Deepen |
| Gold | convenience and services, not the only progression gate | Keep |
| Sinks | repairs only if interesting; prefer rerolls, respec, chart services | Now |
| Anti-arbitrage | no buy→craft→sell profit loops; automated data test | Keep |
| Trading/auction | no global auction house; it erases local gathering value | Avoid |

### 1.5 Charts, maps, and procedural runs

| System | Wayfinder form | Call |
|---|---|---|
| Chart templates | run length, room grammar, biome, depth, affix slots | Deepen |
| Seeds | deterministic layout shared by save, replay, and co-op | Keep |
| Biomes | distinct palettes, hazards, resources, enemies, and room kits | Now |
| Room grammar | entrance, combat, gather, event, treasure, rest, clue, boss | Now |
| Affix twins | charted upside with possible mischievous downside | Keep |
| Inks | bias affix family and stability; the value spine | Deepen |
| Omens | optional deeper-floor risk chosen during a run | Deepen |
| Secrets | landmarks, hidden rooms, breakable clues, NPC rumors | Now |
| Run objectives | one main objective plus optional authored events | Now |
| Checkpoints | far Waystones between layers; no invisible hard lock | Deepen |
| Death | return to town, lose unbanked run bundle, keep permanent progress | Now |
| Boss charts | crafted from guaranteed clue progress + a prior trophy | Now |
| Pity system | designated clue room guarantees campaign progress | Now |
| Replay | bosses remain replayable for uniques and legendary components | Now |
| Endless mode | only after campaign; no endless treadmill before level 23 | Later |

### 1.6 World, narrative, and retention

| System | Wayfinder form | Call |
|---|---|---|
| Town hub | home, social space, stations, visible restoration | Deepen |
| Buildings | unlock verbs and visually remember campaign progress | Now |
| NPC relationships | milestone dialog and small favors, not romance simulation | Deepen |
| Main quest | seven chapters carried by charts, trophies, and restored roads | Now |
| Side stories | short neighbor problems that teach systems or reveal lore | Now |
| Living Atlas | region completion restores town corners/buildings | Deepen |
| Codex/Almanac | records discoveries; hints without step-by-step spoilers | Deepen |
| Collections | enemies, affix twins, brews, ores, unique gear, boss memories | Now |
| Achievements | authored feats and visible titles; no checklist spam | Later |
| Festivals | warm cosmetic/event layer with no exclusive combat power | Later |
| Daily chores | no daily quests, streaks, energy timers, or battle pass | Avoid |
| Seasonal resets | no gear invalidation or Trade reset | Avoid |

### 1.7 Product and platform systems

| System | Wayfinder form | Call |
|---|---|---|
| Onboarding | one verb at a time; first chart in under ten minutes | Now |
| HUD | contextual reduction; hide unavailable systems and modal bleed-through | Deepen |
| Accessibility | remap, controller, font scale, contrast, reduced motion, captions | Now |
| Save/migrations | versioned additive schema; web and desktop compatible | Deepen |
| Web delivery | Godot web export, cached PCK, loading progress, compressed assets | Deepen |
| Startup performance | staged preload, shader warmup, lazy noncritical UI/assets | Now |
| Co-op | two-player town/delve, join/leave/reconnect, shared reads | Deepen |
| Analytics | opt-in funnel timings and deaths; no behavioral monetization | Later |
| Localization | string IDs and layout-safe UI before content explodes | Now |
| Mod support | data-authored content seams, but not a launch dependency | Later |

### 1.8 Systems deliberately excluded

- No class selection: identity comes from loadout, gear, and Trade mastery.
- No separate strength/dexterity/intelligence tree.
- No ten-slot rotation bar.
- No randomized passive-tree web.
- No gear score replacing item understanding.
- No daily checklist, battle pass, stamina, or paid progress.
- No endless paragon levels after 23. Post-campaign depth comes from charts,
  collections, harder authored encounters, co-op, and cosmetic mastery.

---

## 2. Progression contract: all four Trades are 1–23

### 2.1 Shared XP curve

| Level | Lifetime XP | Level | Lifetime XP | Level | Lifetime XP |
|---:|---:|---:|---:|---:|---:|
| 1 | 0 | 9 | 768 | 17 | 2,560 |
| 2 | 40 | 10 | 936 | 18 | 2,856 |
| 3 | 96 | 11 | 1,120 | 19 | 3,168 |
| 4 | 168 | 12 | 1,320 | 20 | 3,496 |
| 5 | 256 | 13 | 1,536 | 21 | 3,840 |
| 6 | 360 | 14 | 1,768 | 22 | 4,200 |
| 7 | 480 | 15 | 2,016 | 23 | 4,576 |
| 8 | 616 | 16 | 2,280 |  |  |

### 2.2 XP ownership

| Trade | XP comes from | XP does not come from |
|---|---|---|
| Wayfinding | finishing charts, discovering affixes/inks, first biome clears, Atlas restoration | kills, buying charts |
| Earthcraft | mining, smelting, smithing, enchanting, first masterwork | buying ore, equipping gear |
| Wildcraft | foraging, chopping, cooking, brewing, ink discovery | buying herbs, drinking potions |
| Huntcraft | encounter completion, elites, bosses, hunt challenges | harmless animals, repeated trivial summons |

Campaign gates use Wayfinding plus one supporting Trade, never “all four must
be level X” until the optional legendary craft at the very end. This prevents a
player from being forced to stop a story chapter and grind three unrelated
bars.

---

## 3. The complete 1–23 unlock ladder

Every row contains a felt unlock for every Trade. Existing content is retained
where practical; levels 18–23 are the new full-game band.

| Lv | Wayfinding | Earthcraft | Wildcraft | Huntcraft |
|---:|---|---|---|---|
| 1 | Snug Chart, Tier-1 Hollow, Mineral Vein | Copper vein/bar, Shortbow recipe | Wild Herb, Logs, Hedge Ink, Hearth Draught | **Basic Shot only**; movement/aim lesson |
| 2 | Mara's Marginalia: all recipe riddles visible | Bogiron tool recipes | Careful Picking: +10% common yield | **Power Shot** unlock |
| 3 | Practiced Measures: stage known ink recipes | Bogiron vein, Bogiron Bar | Bittergrass, Quickroot Tonic | Weak-Point lesson; +5% boss-Poise damage |
| 4 | Bramble Bloom affix | Glimmerdust refining | Bitter Draught | **Bramble Snare** unlock |
| 5 | Tyrannical affix; first mastery choice | Bogiron cap/boots; Sturdy Swings | Keen Eye: +1 herb chance | Steady Hands: +5% crit |
| 6 | Sprinting Things affix; Atlas Hall foundation | Bogiron Jerkin | Clearwater Philter | **Multi-Shot** unlock |
| 7 | Wood Grove + Festival Pace | Palechalk vein; Cinderbloom tools | Crowsfoot patch | **Heartwood Ward** unlock |
| 8 | **Hedgemother Boss Chart** | Copper/Palechalk ringwork | Ash Ink | Ward upgrade: clean blocks return Focus |
| 9 | Gilded Hollow | Palechalk Longbow | Crowsfoot Cordial | **Piercing Bolt** unlock |
| 10 | Hollow Chart + Fog of Hedge | Palechalk Jerkin; Miner's Rhythm | Mothmint; Clean Splits | Hunter's Stride: +5% movement |
| 11 | Frenzied affix | Starsilver vein/bar | Hale Draught | **Hunter's Mark** unlock |
| 12 | **Sallow Mire + Burrow Boar Boss Chart**; Bursting | Starsilver tools | Mothmint Mend | Quick Nock: +10% Skill recovery |
| 13 | Wellspring affix | Starsilver Band; Rich Seams | Foxglove-Blue | **Rain of Thorns** unlock |
| 14 | **Wolf Alpha Boss Chart**; Herbal Patch | Starsilver Longbow | Mothglow + Foxglove inks | Heavy Draw: +25% critical damage |
| 15 | Briar Maze + Echoing Steps | Hedgesteel vein/bar | Heartsease Draught | **Thornburst** unlock |
| 16 | Marked Quarry; Summit approach | Hedgesteel armor set | Stonebreak + Stonebreak Tonic | **Mercy Shot** unlock |
| 17 | **Current Summit / Queen of Thorns**; Deepening I | Hedgesteel Warbow; Smith's Thrift | Second Pour | Even Breath: kills return Focus |
| 18 | **Pale Veins Chart**; Stonewake affix | Wildgold vein | Wellmoss; Wellmoss Salve | **Driving Volley** unlock (pack knockback) |
| 19 | Pale Oath boss road; Skald Archive | Wildgold bar + master tools | Wellwater Philter | Trophy Sense: elite modifier and reward-floor read |
| 20 | **Ashen Bough Chart**; Cinderbound affix | Wildgold armor | Embersage; Emberleaf Ink | **Threadstep** unlock (short reposition) |
| 21 | **Hearth Giant Boss Chart**; Deepening II | Wildgold bow + Starheart alloy | Dawncap; Dawnsap Cordial | Pack Reader: first elite modifier is previewed |
| 22 | **Root Below Chart**; Mythic affix slot | Waysteel Core recipe | Root-Sap Cord recipe | **Wayfinder's Mark** unlock (Poise finisher) |
| 23 | **Unwritten Chart** + Map of Nine Knots | Master Forge + Wayweaver frame | Threefold Draught + Wayweaver string | Master Hunt + Wayweaver grip; legendary craft eligible |

### 3.1 Combat Skill list and onboarding

The fixed Basic Shot remains in slot 1. The player chooses three of the other
Skills for slots 2–4. Skills do not each carry a separate 1–23 XP bar; they are
unlocked and improved by the 1–23 Huntcraft ladder.

| Hunt lv | Skill | Job | Focus | Cooldown | Teaching beat |
|---:|---|---|---:|---:|---|
| 1 | Basic Shot | dependable free damage | 0 | fire-rate based | shoot one target |
| 2 | Power Shot | tank / single target | 20 | 5s | spend Focus for a telling hit |
| 4 | Bramble Snare | space / root | 18 | 4s | stop a charger |
| 6 | Multi-Shot | pack / cone | 22 | 5s | shape matters |
| 7 | Heartwood Ward | survive / absorb | 24 | 10s | prepare for a telegraph |
| 9 | Piercing Bolt | pack / line | 25 | 6s | line enemies up |
| 11 | Hunter's Mark | tank primer | 16 | 8s | prepare a burst window |
| 13 | Rain of Thorns | zone / delayed AoE | 30 | 9s | predict where a pack will be |
| 15 | Thornburst | panic / self-nova | 28 | 8s | recover when surrounded |
| 16 | Mercy Shot | execute | 25 | 7s | read low Vigor |
| 18 | Driving Volley | displacement | 26 | 6s | make room without a hard stun |
| 20 | Threadstep | mobility | 20 | 8s | cross a late-game hazard cleanly |
| 22 | Wayfinder's Mark | boss finisher | 35 | 14s | cash in a Reeling window |

Onboarding rule: a fresh player sees Basic Shot and one empty locked slot, not
the whole pool. Each unlock gets a 20-second safe practice prompt at the
Hunter's Lodge or the next appropriate story encounter. The loadout screen
appears only after the third active Skill exists.

---

## 4. Item and gear ladder

### 4.1 Progression bands

| Band | Levels | Core materials | Gear identity | Main source |
|---|---:|---|---|---|
| Arrival | 1–4 | copper, bogiron, wild herb, logs | patched leather, Brindle bow | town + Snug charts |
| Hedge | 5–8 | bogiron, bittergrass, palechalk | sturdy magic gear | Hollows + Hedgemother |
| Mire | 9–12 | palechalk, crowsfoot, mothmint | utility affixes, first rares | Sallow Mire + Boar |
| Summit | 13–17 | starsilver, hedgesteel, foxglove, stonebreak | rare gear and named uniques | Briar/Summit + Wolf/Queen |
| Rootroads | 18–19 | wildgold, wellmoss, oath nails | master tools, story charms | Pale Veins + Barrow Jarl |
| Ash Bough | 20–21 | embersage, starheart, dawncap | high-end wildgold gear | Ashen Bough + Hearth Giant |
| Unwritten | 22–23 | waysteel, root-sap cord, three story Threads | legendary components | Root Below + final chart |

### 4.2 Required item families by band

Each band authors a small complete family rather than dozens of stat clones:

- one ore, bar/alloy, herb, brew, ink, chart base, boss clue, boss trophy;
- one bow, helm, chest, boots, ring, pickaxe, and axe where the band supports
  Earthcraft gear;
- two named uniques tied to biome enemies or events; and
- one permanent story object (Root Rune / Thread) shown in the Trophy Hall.

### 4.3 Campaign-critical item manifest

| Chapter | Collectible clues | Boss-chart ingredient | Boss trophy | Permanent relic |
|---|---|---|---|---|
| First Knot | Thorn Whispers ×3 | Thorn Essence | Tusker Tusk | Green Root Rune |
| Golden Wallow | Gilt Bristles ×3 | Tusker Tusk + Mire Ink | Wightpelt | Mist Root Rune |
| Seventh Road | Cold Tracks ×4 | Wightpelt + Mothglow Ink | Alpha Fang | Fang Root Rune |
| Queen's Summit | Shed Crown-Thorns ×4 | Alpha Fang + Refined Ink | Oath Nail | Crown Root Rune |
| Pale Oath | Oath-Rubbings ×4 | Oath Nail + Stoneground Ink | Starheart Coal | Pale Root Rune + Past Thread |
| Fire in the Bough | Ember Verses ×5 | Starheart Coal + Emberleaf Ink | Wyrm Scale | Ember Root Rune + Present Thread |
| Unwritten Road | Lost Waymarks ×5 | Wyrm Scale + all six Root Runes | Quiet Tooth | Unwritten Thread |

Clues are quest-ledger entries, not physical inventory clutter. Every valid
campaign chart has one guaranteed clue room; elites can add bonus progress.
Boss ingredients and trophies are physical, illustrated items.

### 4.4 Named uniques

Keep the shipped uniques and add one memorable acquisition story per boss:

| Source | Unique | Slot | Defining property |
|---|---|---|---|
| Hedgemother | Coatcap of the Bramble | helm | roots briefly slow attackers |
| Burrow Boar | Wallow-Treader Boots | boots | mud no longer slows; charge near-misses grant speed |
| Wolf Alpha | Glintband of the Seventh Road | ring | marked enemies reveal their next attack sooner |
| Queen of Thorns | Crownward Jerkin | chest | first hit in each room grants a small Ward |
| Barrow Jarl | Oathnock Bow | weapon | every third piercing hit echoes |
| Hearth Giant | Cinderquiet Band | ring | burning enemies restore a little Focus on defeat |
| Knot-Eater | Quiet-Tooth Charm | enchant | Reeling lasts slightly longer, once per boss phase |

### 4.5 The legendary: Wayweaver

**Wayweaver** is a legendary longbow grown around a waysteel frame. It is not a
random drop. The player sees its empty wall mount in the Trophy Hall early.

Craft requirements:

- Wayfinding 23: **Map of Nine Knots**;
- Earthcraft 23: **Waysteel Frame**;
- Wildcraft 23: **Wayweaver String**, woven from Root-Sap Cord and a
  Threefold Draught at the awakened Loom;
- Huntcraft 23: **Quiet-Tooth Grip**;
- the Past, Present, and Unwritten Threads; and
- one Root Rune from every campaign boss.

Legendary behavior:

- base damage at the top of the Wildgold band, not an order of magnitude above;
- the first successfully cast Focus Skill after entering an eligible room
  “threads” that Skill;
- the next Basic Shot repeats a modest echo of the threaded Skill's identity
  (pierce, fan, root, ward, or mark), then spends that room's one thread;
- one visible glowing strand changes color to match the threaded action; and
- it can equip one cosmetic Root Rune at a time, changing particles and sound
  but not invalidating other endgame bows.

This makes the legendary expressive and readable rather than a flat damage
stick. Its pursuit proves mastery of the entire loop.

---

## 5. Buildings and town growth

Buildings are verbs made visible. A restoration should change both the skyline
and what the player can do.

| Unlock | Building / upgrade | New verb | Visual change |
|---|---|---|---|
| Start | Mara's Chart Table | mix ink, inscribe first charts | small table under canvas |
| Start | Maud's Hearth | cook recovery food/draughts | smoking cottage chimney |
| Earth 2 | Hod's Smithy | smelt, smith, repair tools | forge fire and hanging tools |
| Wild 3 | Quill's Still | brew timed preparations | copper coil, herb racks |
| Hunt 4 | Hunter's Lodge | practice Skills, set loadout | targets, bow rack, Linnet's perch |
| Way 6 | Living Atlas Hall | see biome progress and restored roads | wall map gains painted regions |
| First boss | Trophy Hall | display bosses, uniques, Wayweaver mount | first alcove opens |
| Earth 9 | Charmwright Bench | salvage and bind enchants | small rune vice at Hod's yard |
| Way 12 | Sallow Jetty | launch Mire charts and fishing events | repaired dock and lantern |
| Way 15 | Skald Archive | review Saga clues and target clue inks | shelves, story stones, reading nook |
| Way 18 | Rootroad Lift | descend to Pale Veins | well-house opens around old shaft |
| Way 20 | Ember Kiln | make Starheart alloy and Emberleaf Ink | kiln glows beyond smithy |
| Way 22 | Threefold Loom | combine the three Threads | loom room grows from Atlas Hall |
| All 23 | Master Forge | assemble Wayweaver | Hod lights the old second hearth |

Town pacing rule: at most one new station button appears at a time. NPC dialog
walks the player to it, the station performs one guided recipe, and only then
does its full panel open.

---

## 6. Main storyline — *The Thread Under the Hedge*

### 6.1 Norse-myth translation

The story borrows Norse myth's deep structure while keeping Bramblewood
original and intimate:

| Mythic source shape | Bramblewood translation |
|---|---|
| Yggdrasil, the world tree | **Old Mother Root**, the rootroad beneath the Wolds |
| The three Norns | the **Three Mendwives**, remembered as Past, Present, Unwritten |
| Runes | waymarks and Root Runes, practical signs before they are magic |
| The wells beneath the tree | Old Mother Well, the Sallow spring, the deep pale well |
| Ratatoskr / message carrier | Linnet the falcon and Cricket the letter-carrier |
| Gullinbursti / sacred boar | the Burrow Boar, hoarder of bright road-nails |
| Fenrir / the bound wolf | the Wolf Alpha at the Seventh Road |
| Draugr | the Oathbound, dead Wayfinders who refuse to leave their posts |
| Jötunn and fire | the Hearth Giant, keeper of an over-hot root-forge |
| Níðhöggr gnawing the root | the **Knot-Eater**, a winter wyrm that eats forgotten roads |
| Ragnarök and renewal | the **Ragged Winter**, a local cycle of roads lost and remade |

The Knot-Eater is not secretly evil. It consumes ways nobody remembers so the
root can grow new ones. Bramblewood's trouble began because the old Wayfinders
stopped completing the cycle: they bound every road permanently, leaving the
creature starving and the root tangled. The player wins by making one new road,
not by killing a necessary part of the world.

### 6.2 Cast roles

- **Mara Linnet** teaches charting and discovers that finished maps are losing
  their final lines.
- **Old Hod Tenter** recognizes the pale Oath Nails from the forgotten hedge
  war and eventually admits he once guarded a rootroad.
- **Quill** learns to reveal old waymarks by brewing stains from biome herbs.
- **Mother Onywyn / the Hedgemother** remembers the Root in slow, seasonal
  thoughts and becomes the first trustworthy witness.
- **Sir Withering and Linnet** teach Huntcraft; the falcon repeatedly finds
  roads that no longer exist on the ground.
- **Cricket** carries letters between restored buildings and serves as the
  ordinary human measure of whether the roads are safe.
- **The Three Mendwives** are encountered through artifacts and voices before
  appearing at the Loom. They are caretakers, not quest dispensers.

### 6.3 Chapter structure

#### Prologue — A Blank Place on the Page (levels 1–3)

The new arrival reaches Bramblewood while Mara is arguing with a chart whose
road ends in blank parchment. The player gathers three herbs, mixes Hedge Ink,
inscribes a Snug Chart, and learns Basic Shot inside a harmless cellar. At the
far Waystone they find a waymark carved on the wrong side of the stone.

**Payoff:** the Chart Table opens; the player sees one distant locked map socket
and one locked Hunter's Lodge slot, not the full game UI.

#### Chapter I — The First Knot (levels 4–8)

Random Hollows carry Thorn Whispers. Completing three reveals that the hedge is
repeating an old warning. The player makes a Thorn Essence and inscribes the
Hedgemother's Den. The fight is an attempt to quiet her enormous, tangled
thought long enough to speak.

On defeat she says the root “has begun remembering forward.” She gives the
Green Root Rune and a Tusker Tusk she has kept out of the soil for years.

**Boss:** Hedgemother. **Town:** Trophy Hall opens. **Road:** Sallow Mire.

#### Chapter II — The Golden Wallow (levels 9–12)

The Burrow Boar has rooted bright Oath Nails out of drowned roadbeds and built
a wallow around them. Mire charts reveal Gilt Bristles and waterlogged saga
lines. The player uses the prior tusk, Mire Ink, and the clues to chart its
Wallow.

The Boar is driven off rather than killed. Beneath its nest is the Mist Root
Rune and a Wightpelt snagged on an Oath Nail. Something wolf-shaped has been
following roads after they disappear.

**Boss:** Burrow Boar. **Town:** Sallow Jetty restored. **Road:** Briar Maze.

#### Chapter III — The Seventh Road (levels 13–16)

Every Briar chart contains six real roads and a seventh seen only in fog. Cold
Tracks from several randomized layouts assemble into a route. The Wolf Alpha is
not hunting villagers; it is guarding the entrance to the disappearing road.

After the fight, Linnet lands beside the wolf instead of the player. Its Alpha
Fang opens the current Summit Chart. At the Summit, the Queen of Thorns yields
the Crown Root Rune and an Oath Nail. Her final arena cracks open onto a stair
descending below the known game.

**Bosses:** Wolf Alpha, then Queen of Thorns at the current Summit.
**Town:** Skald Archive. **Hinge:** this is the shipped demo's ending and the
full campaign's midpoint revelation.

#### Chapter IV — The Pale Oath (levels 18–19)

Pale Veins charts lead through abandoned Wayfinder stations. The Oathbound are
not generic undead: they continue their last patrol because no one relieved
them. Oath-Rubbings reveal that Hod was the youngest keeper and fled before the
rootroad was sealed.

The Barrow Jarl boss alternates combat with bell interactions that release its
companions from their posts. When relieved, it hands Hod's old Starheart Coal
to the player; the **Pale Root Rune** and **Past Thread** appear at the deep
pale well.

**Boss:** Barrow Jarl. **Town:** Rootroad Lift and Hod's restored oath-stone.

#### Chapter V — Fire in the Bough (levels 20–21)

The Ashen Bough is not a separate world; it is a rootroad that passes too close
to the old forge beneath the Wolds. Random charts collect Ember Verses that
teach the safe rhythm of its vents. The Hearth Giant has chained itself to the
forge to keep the root from catching fire.

The player uses brews, hazard reads, and forge interactions during the boss
fight. Breaking the wrong chains is dangerous; breaking the right three lets
the Giant bank the fire. It gives a Wyrm Scale, the **Ember Root Rune**, and the
**Present Thread**.

**Boss:** Hearth Giant. **Town:** Ember Kiln and Threefold Loom foundation.

#### Chapter VI — The Unwritten Road (levels 22–23)

Root Below charts contain Lost Waymarks from places the Wolds almost forgot.
Mara realizes the Knot-Eater has been blamed for the damage caused by the old
Wayfinders' permanent bindings. The Root needs one path left unfixed—an
unwritten road—so old ways can end without vanishing violently.

The final Boss Chart consumes its renewable page, tracings, bindings, Ink, and
the physical Wyrm Scale Seal. The Map of Nine Knots and all six Root Runes are
immutable story references: the Table witnesses and snapshots them into the
attempt, but never removes, locks, spends, or refunds them. The Knot-Eater fight
has three phases: survive its gnawing, break the old bindings, then use
Wayfinder's Mark on three exposed knots while Mara inscribes from town. The
last action is “Name the new road,” not “Kill.”

The creature leaves along the path the player made. The **Unwritten Thread**
remains, the Threefold Loom wakes, and all four level-23 components can become
Wayweaver.

**Final boss:** Knot-Eater. **Town:** Master Forge. **Epilogue:** restored roads
become endgame chart variants, and boss memories remain replayable.

The canonical late-Wayfinding lane uses authored replacement rewards rather
than the generic tier/Affix formula. Five clue-bearing Ashen Bough returns pay
68/69/69/69/69 XP, the Hearth Giant return pays 360, and five clue-bearing Root
Below returns pay 75/75/75/75/76. Starting at the level-20 floor, those exact
successful returns reach the level-21, level-22, and level-23 floors without
Affix or discovery-XP variance. Abandoned, duplicate, non-clue, and replay
Charts cannot replay these campaign rewards; older materialized Charts without
the frozen reward retain their compatibility behavior.

---

## 7. How authored story survives random maps

Random generation owns space; the campaign owns beats. Do not procedurally
generate plot prose.

Each campaign chart injects these typed rooms into the seeded layout:

1. **Entrance room** — chapter-specific NPC line or visual reminder.
2. **One guaranteed clue room** — the campaign cannot stall.
3. **One biome event room** — selected from 3–5 authored events.
4. **One rest/Hearth room** on multi-layer charts.
5. **Far Waystone** — banks the clue and gives a short debrief.
6. **Boss arena** only when the crafted boss chart requests it.

The spatial path, enemy packs, gather nodes, optional rooms, and affix effects
remain random. The clue room's *presentation* can vary, but its story fact is
authored and advances exactly once.

### 7.1 Boss-chart recipe

```text
chapter clue threshold
  + previous boss trophy (except the first chapter)
  + one biome ink
  + one chart base
  → deterministic Boss Chart
```

- Clues are guaranteed at one per valid campaign chart.
- Elites have a bonus chance to add one clue.
- The summary card names the boss, den level, expected run length, and unique
  reward family before inscription.
- A boss chart cannot roll an Empty Den bad twin. Failure can change hazards or
  reward quality, but it never consumes the story key without presenting the
  boss.
- Losing consumes the chart base and ink but returns the irreplaceable trophy;
  the player can immediately gather/craft another attempt.

---

## 8. Icon and asset integration contract

Every player-visible item or Skill must enter through a manifest; no font glyph
is considered final art.

### 8.1 Icon families

| Family | Estimated final count | Art rule | Runtime size |
|---|---:|---|---:|
| Combat Skills | 13 | clear silhouette + one action color | 128×128 source, 64 HUD |
| Materials/ores/herbs/logs | 24–30 | single object, transparent, readable at 24 px | 128×128 |
| Inks/brews | 18–22 | bottle/pot silhouette + distinct cap/liquid | 128×128 |
| Gear bases | 30–36 | three-quarter object, material color band | 256×256 |
| Clues/trophies/Root Runes | 20–24 | storybook relic, gold rim only for permanent | 256×256 |
| Buildings/stations | 14 | small painted elevation or sign emblem | 256×256 |
| Affixes/omens | 24–30 | paired good/bad composition sharing a silhouette | 128×128 |
| Legendary set | 6–8 | Wayweaver, components, empty/full wall mount | 512×512 hero + 256 icon |

### 8.2 File/data rules

- Paths: `res://assets/ui/items/<id>.png`, `skills/<id>.png`,
  `affixes/<id>_<good|bad>.png`, `story/<id>.png`.
- A single data registry owns `icon_path`; panels never hand-build paths.
- Preload icon textures before drawing; never first-load inside `_draw()`.
- Missing icons fail a content-contract test and display a deliberate painted
  “unfinished sketch” placeholder in development builds only.
- Each icon is checked at 24, 48, and 96 pixels on cream and enamel-green.
- Gear icons and 3D attachments share the same item ID.

### 8.3 3D asset order

1. Buildings that unlock verbs.
2. Boss silhouettes and telegraph-critical props.
3. Player-visible gear attachments.
4. Biome kit modular pieces and landmarks.
5. Ordinary enemy variants and decorative props.

Meshy is appropriate for base characters/creatures that need texture and
rigging help; Blender remains the cleanup, shared skeleton, attachment socket,
LOD, collision, and export authority. All humanoid gear targets the shared
Wayfinder rig and named attachment bones/sockets rather than being baked into
each character.

---

## 9. Build sequence

### Wave 0 — contract and migration

- Land ADR 0016 and this design.
- Add versioned save migration for four Trades and level 23.
- Clone legacy unified lifetime XP into each Trade so no existing unlock is
  lost; new saves use separate XP pools.
- Add data-contract tests: all Trade levels 1–23 have at least one unlock;
  every referenced item/Skill/icon/building exists.

### Wave 1 — onboarding and progression foundation

- Split the one Wayfinding record back into four Trade records.
- Extend the cap and UI to 23.
- Start new players with Basic Shot only.
- Gate existing Skills at Huntcraft 2/4/6/7/9/11/13/15/16.
- Introduce Trade surfaces only as their mentors teach them.

### Wave 2 — current content re-ladder

- Preserve the shipped levels 1–17 materials, recipes, affixes, and bosses.
- Turn Summit 16/17 into the midpoint hinge.
- Implement clue ledger + guaranteed clue room + safe boss-chart recipe.
- Open Trophy Hall and Atlas Hall restorations.

### Wave 3 — levels 18–19, Pale Oath

- Pale Veins biome kit, Oathbound roster, Barrow Jarl.
- Wildgold and Wellmoss ladders.
- Rootroad Lift, Skald Archive, Past Thread.

### Wave 4 — levels 20–21, Fire in the Bough

- Ashen Bough biome kit, cinder hazards, Hearth Giant.
- Wildgold gear, Starheart alloy, Embersage/Dawncap.
- Threadstep, Ember Kiln, Present Thread.

### Wave 5 — levels 22–23, Unwritten Road

- Root Below biome and Knot-Eater final encounter.
- Threefold Loom and final chart ritual.
- Level-23 master components and Wayweaver.
- Epilogue/endgame chart variants.

### Wave 6 — completion quality

- Finish the complete icon manifest and gear-on-character attachments.
- Accessibility/controller/localization pass.
- Web startup profiling, PCK caching, shader warmup, and asset LOD audit.
- Full fresh-save playtest, co-op campaign pass, and economy/progression sim.

---

## 10. Acceptance gates

- All four Trades can independently reach exactly level 23 and cannot exceed it.
- Every level 1–23 has at least one visible, functional unlock in every Trade.
- A fresh player has only Basic Shot and does not see an unexplained full bar.
- Every campaign chapter can advance after a bounded number of completed charts;
  random drops cannot hard-lock progress.
- Every boss chart names its boss and always produces that boss encounter.
- Defeat never deletes a unique campaign trophy.
- Every item, Skill, affix, trophy, and building has a valid icon registry entry.
- Every gear item that appears on the player uses the shared rig/attachment
  contract.
- The final chart requires campaign completion; Wayweaver additionally requires
  level 23 in all four Trades.
- The final story resolves through restoration and a newly inscribed road, not
  world-ending violence.
- All six Godot test gates stay green, plus new progression/content-contract
  and fresh-save campaign tests.

### 10.1 D7 Fire browser-release clock contract

The strict `?smoke=1&ui=d7` route is a release test, not a player-facing speed
setting. After the real `fresh_campaign` phase only, one D7 clock owner may
lease **exactly 6×** simulation time; no D7 path may request or observe a scale
above 6×. The owner captures the existing positive time scale and restores that
same baseline before terminal report serialization, on failure, and in
`_exit_tree`. A Hitstop freeze must preserve the active baseline across
overlaps, and cancellation must invalidate delayed callbacks before restoring
the D7 baseline.

The watchdog is measured with monotonic real time, not simulation time. The
outer runner begins its 900-second budget before `fresh_campaign`, so the
attempt-owned in-game terminal watchdog fires 840 seconds after the lease (a
60-second startup/serialization margin), using a `SceneTree.create_timer` with
both `process_always` and `ignore_time_scale`. Terminal completion, failure,
and `_exit_tree` invalidate its generation; a late callback is evidence-only
and may not alter the terminal phase. The release report must include an
attempt-bound `d7_simulation_clock` receipt with
`owner: "d7_smoke_clock"`, `activated_after_fresh_campaign: true`, exact
`requested_scale`, `observed_scale`, and `max_observed_scale` of 6, a positive
`captured_baseline_scale`, `watchdog_clock: "monotonic_real_time"`,
`restored_before_terminal_serialization: true`, `restored: true`,
`terminal_reason: "complete"`, and `terminal_scale` equal to the captured
baseline. Its nested `training_start_watchdog` receipt must record exactly
`duration_sec: 8`, `ignore_time_scale: true`, `armed: false`, and `fired: true`.
Its separate `terminal_watchdog` receipt must record exactly
`duration_sec: 840`, `ignore_time_scale: true`, a nonempty `d7_`-prefixed
`attempt_token`, an integer `generation > 0`, `armed: false`, `fired: false`,
`cancelled: true`, and `stale: false`. The attempt identity proves it was armed;
the terminal state proves it was invalidated before serialization. A stale
callback can occur only after the frozen terminal payload and remains a no-op.
The Web probe rejects a boolean or truthy substitute.

Shipping requires focused 1×/6× parity proof for the ordered phase and receipt
history, Hearth Giant floors/chain banks, status/cooldown/Threadstep behavior,
and final campaign truth. It also requires two independent fresh exported-Web
passes, each under the existing 900-second real-wall budget (target ≤750
seconds), with zero browser warnings/errors and a restored terminal scale.

---

## 11. Feel audit

The complete saga loop scores **15/18** against the project's nostalgic
online-game-feel rubric:

| Feeling | Score | What produces it |
|---|---:|---|
| Wonder | 2 | locked roads, rumors, typed secrets, new root biomes |
| Earned mastery | 2 | four finite 1–23 ladders and one all-Trade legendary |
| Belonging | 2 | every boss visibly restores a shared town space |
| Hangout | 1 | town supports it, but this design adds few social-only verbs |
| Persistent FOMO | 1 | neutral by design; no abusive daily/streak pressure |
| Quirky charm | 2 | neighbor-scale problems and authored item/story specificity |
| Identity expression | 2 | loadout, visible gear, uniques, Root Rune cosmetics |
| Slow time | 1 | crafted preparation and travel remain, without forced waiting |
| Discovery | 2 | ink riddles, clues, hidden rooms, partial Almanac guidance |

The two neutral areas are intentional. Future festivals or town emotes can
deepen hangout and shared-time feeling without attaching power or missable
chores.
