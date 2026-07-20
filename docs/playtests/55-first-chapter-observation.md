# Spec 55 — fresh-player observation

Status: **instrumented; awaiting three native and one web first-time participants**.

The build and deterministic two-Chart path are ready. This sheet is the final
human gate for Spec 55. Use a participant who has not played Wayfinder and has
not read the spec. Do not teach controls or goals unless they have been unable
to progress for three minutes; record every intervention.

For a no-install session, give the participant only this normal play URL:
https://bbroeking.github.io/gj26/play/

Do not use the `?wyrd_smoke=snug` QA query during the observation; it automates
the Snug roundtrip and invalidates the result.

For a native session, launch with `WYRD_PLAYTEST=1 godot --path wyrd`. The game
writes a privacy-safe `onboarding_playtest.json` beneath Godot's Wayfinder
`user://` folder. For a web session, read `globalThis.__wyrdOnboarding` from the
browser console after the second return. Both contain only milestone names,
elapsed seconds, and recovery-hint counts—never player text or coordinates.

After collecting the four JSON files, run:

```bash
python3 wyrd/tools/summarize_onboarding_playtests.py path/to/native-1.json \
  path/to/native-2.json path/to/native-3.json path/to/web.json
```

The summary applies every Spec 57 time gate, shows per-session and median
timings, and totals recovery activations so repeated stalls are obvious.

## Session record

- Date:
- Participant alias:
- Build/commit:
- Platform: native / Chromium
- Session start:
- First Chart completed (elapsed):
- Second Chart completed (elapsed):
- Total session time:
- Observer interventions:
- Timing report attached: yes / no

## Observe, do not lead

Record each hesitation, misread, or abandoned action with an elapsed time.

| Time | Place | What the player tried or said | Severity (pause / wrong turn / blocked) |
|---:|---|---|---|
| | | | |

After Snug, ask without offering vocabulary:

1. “How do you gather what you need?”
2. “How does fighting work?”
3. “How do you finish a Chart?”
4. “How do you get home?”

Player's answer:

> 

Before Tier 1 Hollow, ask:

1. “How dangerous does this place look?”
2. “What do you think the ink changes?”
3. “Does the ink guarantee the helpful result?”

Player's answer:

> 

After the second return, ask exactly:

> What do you want to do next?

Player's answer:

> 

## Result and next revision

- Unaided two-Chart completion: pass / fail
- Player can explain gather, fight, finish, and return: pass / fail
- Player understands den band and ink bias: pass / fail
- Second Hand created curiosity: yes / no / unclear
- Most important confusion point:
- Next revision this observation justifies:

Do not mark the Spec 55 observation Done item until the elapsed times, confusion
notes, verbatim next-action answer, and resulting revision decision are filled.
