# Skill consolidation — Wilds + Earth + Cooking

> **Decision (2026-05-04):** soft merge the 5 gathering skills into 2
> umbrella skills, keeping Cooking separate. Total skill count: 13 → 10.

---

## Target shape

| umbrella skill | absorbs | rationale |
|---|---|---|
| **Wilds** | forage + fish + wc | "What nature gives you." All three are *soft* gathering — passive harvest from the meadow / forest / pond. Same identity, same wiki-style "outdoor cozy" feel. |
| **Earth** | mine + smith | "What you take from the ground and work into shape." Mining and smithing are paired — every miner becomes a smith and vice-versa; they share the same metal-tier ladder (Brindle / Bogiron / Cinderbloom). |
| **Cooking** | (no change) | Different verb. You don't *gather* food, you *transform* it. Tied directly to combat HP via `food.heal`. Big enough loop to stand alone. |

The combat triple (`atk str def hp`) and the utility skills (`carto falconry magic`) are unchanged.

---

## Final skill list (10 total)

| skill | category | what it does |
|---|---|---|
| atk | combat | hit chance |
| str | combat | damage roll |
| def | combat | damage taken |
| hp | combat | HP pool |
| **wilds** | gathering | forage + fish + wc |
| **earth** | gathering+craft | mine + smith |
| cook | crafting | turns gathered → healing food |
| carto | crafting | charts dungeons |
| falconry | companion | Pernel scout/combat |
| magic | combat/utility | rune spells |

---

## XP routing (after merge)

Every action that previously awarded XP in one of the 5 sub-skills now awards Wilds or Earth:

| old action | old skill | new skill |
|---|---|---|
| Pick whitleberry | forage | **wilds** |
| Catch sardine | fish | **wilds** |
| Chop oak | wc | **wilds** |
| Mine mosswort ore | mine | **earth** |
| Smelt brindle bar | smith | **earth** |
| Smith brindle dagger | smith | **earth** |
| Cook brindle roast | cook | cook (unchanged) |

Per-action XP rates **unchanged**. The pool is shared, so a miner-only player levels Earth at the same rate they used to level Mining; in practice Earth levels *faster* than the old Mining alone because it pools mine + smith XP.

---

## Milestone re-numbering

The 5 old gather skills have ~3 milestones each = ~15 milestones. The merged 2 skills get **5 milestones each** because they cover more verbs. Cooking unchanged.

### Wilds milestones (5)

| Lv | Unlock | What |
|---|---|---|
| 5  | **Catch chance up** | Fishing catch rate climbs faster (formula already exists). |
| 12 | **Mid-tier herbs** | Wishrose + Mossvine forage. |
| 15 | **Coalrose chunks** | Wood-fuel for hearth + carto inks. |
| 25 | **Foxfire Glow** | Night-only forageable for endgame charts. |
| 35 | **Endgame fish + ash** | Briarcoast fish + Hard Ash logs. |

### Earth milestones (5)

| Lv | Unlock | What |
|---|---|---|
| 5  | **Pickaxe + smith strikes** | Faster mine + smelt cooldowns (~10% reduction). |
| 15 | **Bogiron tier** | Bogiron ore mineable + tier-2 weapons/armor smithable. |
| 22 | **Bogiron cuirass** | Tier-2 chest armor (currently smith reqLevel 22). |
| 30 | **Cinderbloom tier** | Coalrose + cinderbloom alloy + tier-3 smithing. |
| 38 | **Cinderbloom plate** | Tier-3 endgame plate (currently smith reqLevel 38). |

### Cook (unchanged)

Lv 5 / 15 / 25 milestones from the existing `skill-milestones.js`.

---

## Code change checklist

Files that touch the renamed skills, in dependency order:

### Phase 1 — engine (`src/game/skills.js`, `src/data/config.js`)
- [ ] `SKILL_KEYS` array: drop `wc fish mine forage smith`, add `wilds earth`. Total 10.
- [ ] `makeSkills()` adds `wilds, earth` rows; `hp.lv = 10` unchanged.
- [ ] No formula change to `xpForLevel` or `hpMaxForLv`.
- [ ] Add migration helper `migrateSkills(savedSkills)` — for existing saves, set `wilds.lv = max(forage, fish, wc).lv` and `earth.lv = max(mine, smith).lv`, sum XP.

### Phase 2 — item gates (`src/data/items.js`, `src/main.js` recipes)
- [ ] Replace every `source: { skill: 'forage' }` / `'fish'` / `'wc'` → `'wilds'`.
- [ ] Replace every `source: { skill: 'mine' }` / `refines: { skill: 'smith' }` → `'earth'`.
- [ ] Replace every `reqSkill: 'mine' | 'forage' | 'fish' | 'wc' | 'smith'` → `'wilds' | 'earth'`.
- [ ] Smith recipe table in `main.js:3148+` — switch all `kind: 'smith'` / `'smelt'` to award `earth` XP instead of `smith`.

### Phase 3 — milestones + UI (`src/data/skill-milestones.js`, `src/main.js`, `index.html`)
- [ ] Replace the 5 entries in `skill-milestones.js` with the 2 new ones above. Cook unchanged.
- [ ] `SKILL_LABELS` / `SKILL_ICONS` in `main.js` — add wilds / earth icons (vine 🌿 + chisel ⛏); drop the 5 old.
- [ ] `_SKILL_ROW_ICONS` / `_SKILL_ROW_LABELS` in `main.js` (UI A) — add wilds / earth.
- [ ] `awardCombatXp` in `skills.js` is unchanged (combat only).
- [ ] Custom XP awarders for non-combat actions: search for `awardXp(player, '<old>'` in `main.js` and rename.

### Phase 4 — codex (`codex.html`, `codex.js`)
- [ ] `SKILL_GROUPS` in `codex.js` — collapse "Gathering" + "Crafting" rows into "Gathering & Crafting" with [wilds, earth, cook].
- [ ] `SKILL_LABELS` in `codex.js` — add wilds, earth; drop the 5 old.

### Phase 5 — docs
- [ ] Merge `docs/skills/wc.md`, `fish.md`, `forage.md` → `docs/skills/wilds.md`.
- [ ] Merge `docs/skills/mine.md`, `smith.md` → `docs/skills/earth.md`.
- [ ] Cook unchanged.
- [ ] Add a header note in each merged file explaining the consolidation.

---

## Save migration

Single-version save bump. New saves use the new schema directly. Old saves run through:

```js
function migrateSkills(saved) {
  if (saved.wilds || saved.earth) return saved; // already migrated
  const max3 = (a, b, c) => ({ lv: Math.max(a.lv, b.lv, c.lv), xp: a.xp + b.xp + c.xp });
  const max2 = (a, b)    => ({ lv: Math.max(a.lv, b.lv),       xp: a.xp + b.xp });
  saved.wilds = max3(saved.forage, saved.fish, saved.wc);
  saved.earth = max2(saved.mine, saved.smith);
  delete saved.forage; delete saved.fish; delete saved.wc;
  delete saved.mine; delete saved.smith;
  return saved;
}
```

A maxed Forage 30 / Fish 5 / WC 8 player becomes Wilds 30 (with combined XP). They don't lose progress and they don't artificially gain — the highest of their three rules.

---

## Rollback

Each phase is independent enough to revert separately:
- Phase 1-2 reverts cleanly via git
- Phase 3-4 are display only — old code paths still exist as commented-out fallbacks
- Save migration is one-way; we'd need a back-migration if reverting after players have loaded with new schema

If we ship and find the merge feels wrong, we can split back out — the old XP per-action is preserved; we just need new SKILL_KEYS.

---

## Smoke test for the new shape

- [ ] At Wilds 12, the player picks Wishrose and the gate suffix disappears (UI E)
- [ ] At Earth 15, both Bogiron ore mining AND Bogiron weapon smithing unlock simultaneously
- [ ] Picking 1 berry awards Wilds XP (was Forage)
- [ ] Smelting 1 bar awards Earth XP (was Smith)
- [ ] Save from old schema migrates cleanly on load
- [ ] Skills tab in codex shows 10 skills with the new groupings
- [ ] No `Cannot read properties of undefined` runtime errors from a stale `player.skills.fish` reference

---

## Estimate

~2-3 hours total, mostly in Phase 2 (item gates — there are ~50 grep hits across `items.js` + `main.js`).
