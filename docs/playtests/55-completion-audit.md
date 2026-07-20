# Spec 55 — completion audit

Audit date: 2026-07-16. Public build: `gh-pages` deployment `26ef5e3` at
https://bbroeking.github.io/gj26/play/

This audit separates implemented behavior from evidence that can only come
from a first-time human. “Automated pass” is not substituted for comprehension
or unaided-play evidence.

| # | Acceptance requirement | Current evidence | Verdict |
|---:|---|---|---|
| 1 | Fresh save completes Town → Snug → Town → Tier 1 → Town without hidden knowledge | `test_wyrd_transitions.gd` drives the real scenes and blank Game state through both loops; public browser smoke proves the first loop. It cannot prove “unaided” or “without unstated knowledge.” | Human evidence pending |
| 2 | Player can explain gather, fight, finish, and return after Snug | Exact questions are prepared in `55-first-chapter-observation.md`; no participant answers exist. | Pending |
| 3 | Player sees the den band and understands ink as bias, not guarantee | `waystone_panel.gd` renders `Den · lv N — band`; `crafting_bench.gd` says inks “tilt the affix odds” and renders live odds. Human explanation is not yet recorded. | UI delivered; comprehension pending |
| 4 | Two guaranteed clues, different contexts, persisted | Generator/state/save assertions in `test_wyrd_loop.gd`; both real interactions in `test_wyrd_transitions.gd`. | Proven |
| 5 | Distinct concise Mara reactions without revealing the answer | Both state-specific reactions are exercised in `test_wyrd_transitions.gd`; the Second Hand identity remains absent from chapter state. | Proven |
| 6 | Returns report finds, growth, and a newly opened choice | Real debrief asserts **Found → Rose → Opened**, gold/XP, preparation choice, and second opened choice in `test_wyrd_transitions.gd`. | Proven |
| 7 | Combat kills award no Wayfinding XP | Real enemy death assertion in `test_wyrd_dungeon_scene.gd`. | Proven |
| 8 | Web title/Town/Snug return without script/resource errors | Local and public Chromium smoke reached `[web-smoke] complete`; public deployment `26ef5e3` produced an empty error log. | Proven |
| 9 | Persistence failure is detectable and honest | Failure state/save refusal assertions in `test_wyrd_loop.gd`; title behavior is implemented in `main_menu.gd`. | Proven |
| 10 | Six native suites stay green | 304 + 26 + 80 + 33 + 92 + 15 = 550 passing checks, zero failures. | Proven |
| 11 | New biome/assets satisfy delivery and renderer QA | `biome-sallow-mire-delivery.md`, `player-animation-sidecars-delivery.md`, Forward+ captures, Compatibility captures, and PCK audit. | Proven |
| 12 | Observation records both Chart times, confusion, and next desire | The observer sheet is prepared but its session record and answers are blank. | Pending |

Additional renderer gate:

```bash
cd wyrd
./tools/check_transition_render_errors.sh
```

Current result: `PASS: transition suite is green with no null-material renderer errors`.

## Remaining completion action

One person who has never played Wayfinder must receive only the normal public
URL and complete the observer session. The observer must then fill the elapsed
times, interventions/confusions, exact answers, and the resulting revision
decision in `55-first-chapter-observation.md`. Acceptance criteria 1–3 and 12,
plus the two unchecked Done items, cannot be closed before that evidence exists.
