# Implementation notes — 43-recipe-discovery

## Decisions
- **The 3×3 spatial grid was NOT ported.** The prototype design's pattern
  puzzle conflicts with the shipped pot (quantity recipes) and the spec-42
  tutorial. Discovery became the layer: exact *amounts* are the puzzle now
  ("no more, no less" — `_pot_match` is strict multiset equality), riddles
  hint quantities loosely.
- **Auto-mix stays for discovered recipes.** Dropping the third herb still
  mixes instantly (tutorial step 2 untouched, transitions test unchanged);
  only unknown matches wait for the deliberate "Try the Mix".
- **Consolation = cheapest pot material by Hod's shelf price** (the doc's
  "always return 1 charcoal" analog). Unbuyables (palechalk) never come
  back — a junk pot with palechalk in it really hurts, which feels right
  for tier-2 material.
- **Serendipity hands the bottle, not the recipe** — a 10% tease that
  shows the ink's name in the satchel without teaching the mix.
- **Riddle gating rides seen_hints** — no new hint state machine. Each
  recipe names a `hint_key`; once that first-time hint has fired (Hod's
  ore talk, Quill's still talk…), the codex line upgrades from `???` to
  `??? — <riddle>`. Hod's existing ore hint already *states* the
  stoneground recipe — that's now intentional (he's the hint NPC).
- **discovery xp = 50 carto, smudge xp = 5 carto** (the doc's numbers),
  on the shared curve.

## Deviations
- Spec said riddles show for hinted recipes; hedge ink also carries a
  riddle + hint_key (forage_node) even though it starts discovered —
  harmless, keeps the data uniform.
- Panel grew 560 → 620 tall: the 5-row codex clipped into the carved
  frame's bottom border at 560 (caught by staged screenshot, not tests).

## Tradeoffs
- **Zero-count tray rows now hide** (inks and materials). Keeps the tray
  inside the panel with 5 inks + 4 materials, and the codex carries the
  "what exists" knowledge instead. Cost: you can't see a dimmed row for
  an ink you've discovered but run out of — the codex line covers it.
- Wild-ink pool is just the two commons (hedge/stoneground); with only 5
  recipes a wider pool would leak the new inks too cheaply.

## Surprises
- The pot was already a *claims* dict (materials stay in the satchel
  until mix) — `try_pot_mix` could live entirely on Game and be tested
  headless without the bench. The bench's only new state is a Rect2.
- `Dictionary ==` would have worked for the match, but the bench already
  had `_dict_eq` — Game got its own `_pot_match` to stay dependency-free.

## Followups
- Discovery feel pass: the gold bloom is 0.16s — a found recipe deserves
  a bigger moment (scroll-unfurl toast, codex line sparkle).
- A "tries" counter per undiscovered recipe could fuel an NPC pity-hint
  ("you've been at that pot a while…") — doc's hint ladder, deferred.
- The wider recipe space (doc targets 15 inks) wants the reagent
  ecosystem (essence types) — pairs with the deferred herb tiers.
- Smudge/wild/serendipity want SFX (generate_audio.py prompts exist for
  craft sounds; nothing fizzle-flavored yet).
