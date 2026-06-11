# 06 — Crypt Aftermath: village reacts to the Hedgemother's fall

> **Outcome**: clearing the crypt and presenting the thorn-crown to Sir Withering propagates the victory through the village — Cook hands the player a Deep Pilgrim ledger, the other named NPCs (Hod, Maud, Quill) get one-line acknowledgements in their gossip pool, and Withering opens a follow-up tier-5 hook.

## Why

Spec 05 lands the Hedgemother fight and sets `player.flags.cryptCleared`. Right now nothing in the world reacts to it. The existing Crown of Thorns quest (`turnInCrownQuest` in `src/game/quest.js`) gives a stat reward in private but the rest of Bramblewood doesn't know anything happened. This spec closes the loop so the player feels the village shift around them — and gives them a forward path to the Deep Pilgrim arc.

## Scope

**In:**
- **Cook hands over `chart_crypt_long` once** when the player talks to him after `cryptCleared` is set. One-shot, flag-gated (`q.flags.cookGaveLongChart`).
- **Village gossip lines** added to Hod, Maud, Quill — each gets 1–2 short reactions inserted into their gossip pool when `cryptCleared` is true. Existing gossip system in `_withGossip` (see `openWithering` in main.js).
- **Withering's post-Crown follow-up**: after the thorn-crown has been turned in, his `kind: 'done'` branch in `talkToWithering` should offer a new tier-5 hook — `q.flags.witheringDeepPilgrim` — that hints toward the Deep Pilgrim arc. Reward is a small but pointed unique (`witherings_signet`, +1 atk passive or a single-use stat tonic).
- **Inventory desc reactivity**: `thorn_crown.desc` already says "Sir Withering bows when you wear it." Add a check when the player wears the crown in a slot that fires a one-time log line outside Withering's dialog.

**Out (explicit non-goals):**
- The Deep Pilgrim arc itself — that's the next spec's worth. This spec only opens the door.
- New GLB assets — `witherings_signet` is item-registry-only (icon string OK).
- Other villagers (Pell, Onywyn, Cricket, Eldra) — they're newer NPCs and may not yet have established gossip pools; skip until they do.
- A wear-the-crown visual / equip effect on the player mesh — text-only acknowledgement for v1.

## Files

| Path | Action |
|---|---|
| `src/game/quest.js` | modify — Cook chart gift, post-crown follow-up logic, wear-crown one-time log |
| `src/main.js` | modify — `openCook` shows the chart-gift choice when ungifted+cryptCleared; `openWithering` routes the post-crown follow-up branch |
| `src/data/items.js` | new — `witherings_signet` entry (small unique reward) |
| `src/ui/dialog.js` | none — existing dialog modal handles new choices |
| `src/game/npcs.js` | modify — extend gossip pools for Hod, Maud, Quill with `cryptCleared`-conditional lines |

## Acceptance criteria

1. With `player.flags.cryptCleared !== true`, talking to Cook offers no chart gift (current behavior unchanged).
2. With `cryptCleared === true` and `q.flags.cookGaveLongChart !== true`, Cook's dialog adds a "Take Cook's deeper chart" choice; selecting it places `chart_crypt_long` in inventory and sets the flag. Repeating the talk does *not* offer again.
3. With `cryptCleared === true`, Hod / Maud / Quill each have at least one new line that mentions the crypt or the bramble retreat, surfaced through the existing `_withGossip` rotation.
4. After `turnInCrownQuest` runs, talking to Withering offers a "Listen to his next charge" branch; accepting sets `q.flags.witheringDeepPilgrim` and grants `witherings_signet`.
5. Equipping `thorn_crown` while NOT at the castle fires a single `log('quest', '★ A hush moves through the village.')` line and then does not repeat.
6. All state survives a save/load cycle (uses the existing `player.quest.flags` + `player.flags` persistence path).

## Open decisions

- **`witherings_signet` mechanical effect.** Recommend: passive +1 atk while held (no slot, no equipment work), so it stacks cleanly with existing gear. Alternative is a single-use tonic for one full heal + run buff. Notes record final pick.
- **Cook's chart-gift wording.** Recommend a single line ("A deeper hole than the one you climbed out of. Don't tell my wife.") rather than full quest-offer ceremony — Cook is gruff. Notes record final.
- **Wear-the-crown log placement.** Inventory equip path vs. a per-frame inventory check. Recommend equip path (cheaper), gated by a `flags.crownWornOnce` flag so it's one-shot.
- **Should `cryptCleared` also persist across deaths in unrelated dungeons?** It's already on `player.flags` (not `dungeon.flags`), so yes — it does. Worth a sanity note.

## References

- Spec 05 Hedgemother boss + `cryptCleared` flag: [`05-hedgemother-boss.md`](./05-hedgemother-boss.md)
- Existing Withering quest hooks: `talkToWithering`, `acceptCrownQuest`, `turnInCrownQuest` in [`src/game/quest.js`](../../src/game/quest.js)
- Existing dialog wiring pattern: `openWithering` in [`src/main.js`](../../src/main.js) around line 4820
- Gossip rotation helper: `_withGossip` (same area of main.js)
- Item registry: [`src/data/items.js`](../../src/data/items.js)
- Cook's lore and tone: [`docs/WORLD_BIBLE.md`](../WORLD_BIBLE.md)

## Done check

- [ ] Cook offers the Deep Pilgrim chart once when `cryptCleared` is set.
- [ ] Hod, Maud, Quill each have a `cryptCleared`-conditional gossip line.
- [ ] Withering offers a follow-up after Crown of Thorns turn-in.
- [ ] `witherings_signet` exists in `ITEMS` and the follow-up grants it.
- [ ] Crown-wear log line fires exactly once.
- [ ] State persists through a save/load cycle.
