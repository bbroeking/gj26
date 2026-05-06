# World & Content Reference — Tutorial Island

This is the canonical content doc: lore, every NPC, every enemy, every item, and the exact tutorial dialog. Update here before changing `game.js`; treat code as the implementation of this spec.

---

## 1. Setting

**Tutorial Island** is the easternmost spit of land in the Aeternian Sea — a teaching ground maintained by the Wizards' Conclave. Every adventurer who would walk the mainland of **Lumbridge Plains** must first prove themselves on the Island.

The Island is small (1024 × 768 pixels — about 30 seconds of walking edge-to-edge) but contains every basic discipline: combat, gathering, refining, crafting, fishing, cooking. Five station-masters run the curriculum. When you graduate, you board a boat to the mainland.

**Tone:** Old-school RPG warmth — friendly NPCs, clear progression, no grimdark. Goblins are pests, not war. The wizard is wise but not aloof. Failure (death) is forgiving — respawn at start with no XP loss for the tutorial run.

### Why goblins?
The Conclave seeded the eastern field with wild goblins specifically for combat training. They breed quickly, fight predictably, and drop nothing dangerous. The "boss goblin" at the final exam is a slightly larger one fattened on Conclave rations.

---

## 2. Bestiary

### 2.1 NPCs (station-masters)

| Role | Name | Sprite | Position | Teaches |
|---|---|---|---|---|
| Aric | Wizard Aric | `npc` (purple hat, white beard) | (4, 9) — by spawn | Welcome + Final exam |
| Brawler | Brawl Master Krell | `npc_warrior` (red plumed helmet, bulky) | (15, 11) — central field | Attack |
| Smith | Smith Halgar | `npc_smith` (bald, brown beard, dark apron) | (10, 7) — outside castle door | Mining → Smelting → Smithing |
| Chef | Chef Mira | `npc_cook` (tall white hat, red apron stripe) | (14, 20) — south pond | Fishing → Cooking |

**Aric's lines (canonical)**
- First contact: *"Welcome to Tutorial Island, adventurer. Speak with the Brawl Master east of here to begin."*
- Mid-quest revisit: *"Continue your training. Find each station-master in turn."*
- Final exam (after all 4 stations): *"One last test — defeat the giant goblin behind you!"* (spawns boss)
- Boss-still-alive: *"The boss still stalks. Fell it!"*
- Graduation: *"You have graduated, hero."* → **GRADUATED** overlay.

**Brawl Master**
- *"Face a goblin and press Space to swing at it."*
- *"Defeat one and we'll talk again."*

**Smith**
- *"Mine copper and tin (south-west), smelt at my furnace,"*
- *"then forge a Bronze Sword on the anvil."*

**Chef Mira**
- *"Fish from the pond south, then cook on my range."*
- *"Face the fishing spot and press Space — same with the range."*

### 2.2 Enemies

| Name | HP | Damage | Aggro | Respawn | XP | Drops |
|---|---|---|---|---|---|---|
| Goblin | 5 | 1 (30% chance: 2) | within 4 tiles, retreat at 8 | 30 s | +10 Attack | — (kill counter only) |
| **Boss Goblin** | 24 | 1-2 | always aggro on player | does not respawn | +30 Attack | one-time, advances `final` step |

Goblin AI: passive wander within 3 tiles of home. Aggro within 4 tiles → step toward player every 30 frames (≈ 0.5 s). Adjacent → attack with 70-frame cooldown.

### 2.3 Animals

| Name | Sprite | HP | Behavior | XP | Drops |
|---|---|---|---|---|---|
| Chicken | `chicken` | 1 | wander in 14-22, 14-16 box | +2 Attack | Feather |

Chickens are passive — they wander in a small grid. Face one and press Space to "snatch a feather" (counts as a kill but no fight).

---

## 3. Item Catalog

### 3.1 Tools (starter kit)
| Icon | Item | Source | Effect |
|---|---|---|---|
| ⛏ | Pickaxe | given at boot | required to mine rocks |
| 🪓 | Axe | given at boot | (cosmetic; chopping doesn't actually require it yet) |

### 3.2 Gathered materials
| Icon | Item | From | Stack |
|---|---|---|---|
| 🪵 | Log | tree (any kind) | yes |
| 🪶 | Feather | chicken | yes |
| 🟠 | Copper Ore | copper rock | yes |
| ⚪ | Tin Ore | tin rock | yes |
| ⚫ | Iron Ore | iron rock (Mining ≥ 5) | yes |
| 🐟 | Raw Fish | fishing spot | yes |

### 3.3 Refined / crafted
| Icon | Item | Recipe | Skill needed | XP |
|---|---|---|---|---|
| 🟫 | Bronze Bar | 1 Copper Ore + 1 Tin Ore at furnace | Smelting 1 | +6 Smelt |
| ⬛ | Iron Bar | 1 Iron Ore at furnace | Smelting 5 | +12 Smelt |
| 🍣 | Cooked Fish | 1 Raw Fish on cooking range (40% burn at lv 1, drops 7%/lv) | Cooking 1 | +6 Cook |
| ⬛ | Burnt Fish | failed cook (no use, takes inv slot) | — | +1 Cook |

### 3.4 Equipment
| Icon | Item | Recipe | Skill needed | Effect when equipped |
|---|---|---|---|---|
| 🗡 | Bronze Sword | 1 Bronze Bar at anvil | Smithing 1 | +1 Attack damage |
| ⚔ | Iron Sword | 1 Iron Bar at anvil | Smithing 5 | +2 Attack damage |

Click any sword in the **inventory panel** to equip / unequip. Auto-equips the better sword on craft. (Inventory remains click-driven; world actions are keyboard-only.)

### 3.5 Consumables
| Icon | Item | Effect |
|---|---|---|
| 🍣 | Cooked Fish | click it in the inventory panel → +4 HP (no effect at full HP) |

---

## 4. World Map (annotated)

```
                          T T T T T            ← Oak/pine grove
       ┌─────────┐
       │  □ u    │                              u = Furnace (5,3)
       │  □ □ v  │                              v = Anvil (8,4)
       │  □ □ □  │
       └────┬────┘
       Aric ●  M●         ← Smith outside castle (10,7)
            │  ╔══════════════════════════╗
            │  ║       PATH east  →       ║
            │  ╚══════════════╗
                              ║ B          ← Brawler (15,11)
            X ←spawn          ║
                              ║   ↓ path
                              ║
     SAND                     ●            ← Chef (14,20)
     r t                      k            ← Cooking range (15,20)
     r t i                    
                       ~ f ~ f ~           ← Fishing pond (cols 13,15 row 22)
                       (water with spots)
```

- Spawn: (7, 11)
- Castle interior: cols 4-8, rows 3-5; door at (6, 6)
- Goblin field: east half, especially around (20, 10) and (22, 14)
- Mining outcrop: (3-5, 17-18) on sand
- Boss spawn: (6, 11) — adjacent to player spawn

---

## 5. Tutorial Walkthrough (exact step triggers)

The quest has **5 visible steps** plus internal flags. Steps unlock in order; `!` markers float above the active station-master.

### Step 1 — `aric_intro`
- Trigger: face Aric and press Space (any time after boot)
- Side effects: `flags.aric_intro = true`; step 1 done; Brawler `!` appears
- Dialog: *"Welcome to Tutorial Island, adventurer."*

### Step 2 — `brawler`
- Sub-flag A: `brawler_talked` (set on first Brawl Master interaction)
- Sub-flag B: `killed_a_goblin` (set on any goblin kill, anytime)
- Step done when **both** A and B are true
- Side effect: Smith `!` appears

### Step 3 — `smith`
- Sub-flag: `smith_talked`
- Step done when smith was talked AND inventory contains `bronze_sword` or `iron_sword`
- Side effect: Chef `!` appears
- Player must travel: smith → mining outcrop → furnace → anvil

### Step 4 — `chef`
- Sub-flag: `chef_talked`
- Step done when chef was talked AND inventory has `cooked_fish`
- Player must travel: chef → fishing spot → range
- Eating the fish is optional — only Cook a fish (not eat) needed for the step

### Step 5 — `final`
- After steps 1-4 done: Aric `!` re-appears
- Face Aric + Space → `aric_final_talked = true` → boss spawns at (6, 11)
- Kill boss → `boss_dead = true`; Aric `!` keeps showing
- Face Aric + Space again → step 5 done → **GRADUATED** overlay with all skill levels listed

### Failure cases
- **Player death** during boss fight: respawn at (7, 11), full HP. Boss does not despawn.
- **Player death** general: same — respawn at start, no XP loss.
- Soft-locks: none known. All resources regrow (trees 25 s, rocks 25 s, fishing spots 20 s).

---

## 6. Dialog conventions

- NPC name in bold prefix: `**Aric:** "..."` in code → log line `Aric: "..."`
- All dialog written American English, present tense, friendly tone
- Avoid in-jokes / meta references
- Each line ≤ 60 chars (fits combat log without wrapping)

---

## 7. Future content hooks

When you add Level 2+, these are the seams already implied:

- **Boat to mainland** — `GRADUATED` overlay's "Play Again" should be "Sail to Lumbridge"
- **Magic / Runes** — Aric is set up to teach Magic on the mainland (he hints at it)
- **Crafting expansion** — Smith already gates iron at Smithing 5, leaving room for steel/mithril
- **Slayer tasks** — Aric already dispenses tasks (final fight is one); reuse the pattern
- **Day/Night** — palette swap in `bakeWaterFrames` already supports per-frame color shift
