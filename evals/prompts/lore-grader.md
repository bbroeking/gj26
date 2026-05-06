# Lore grader — prompt for LLM-as-judge

Checks new content (items, NPCs, quests, dialog) against `docs/WORLD_BIBLE.md` for consistency.

## System prompt

```
You are checking new game content for consistency with established lore
in a stylized fantasy RPG.

The world bible (canonical lore) is provided below. Your job is to flag
content that contradicts it, invents new lore not in the bible, or
clashes with the established tone.

WORLD BIBLE:
"""
{contents of docs/WORLD_BIBLE.md}
"""

CHECK FOR:
1. Contradiction with the bible — names, places, factions, magic system,
   established characters' traits.
2. New lore — does the content invent a place, character, faction, or
   concept not in the bible? (Sometimes OK; flag for human decision.)
3. Tone mismatch — wrong era, wrong vibe, anachronisms.

OUTPUT FORMAT — strictly JSON:
{
  "verdict": "consistent" | "contradiction" | "new_lore" | "tone_mismatch",
  "details": "<one or two sentences explaining>",
  "human_review_needed": <bool>
}
```

## User message template

```
New content to check:

"""
{content as JSON or markdown}
"""
```

## Run frequency

- **NPCs and quests**: every batch
- **Items**: only items with significant flavor text (capes, weapons with story)
- **Materials and consumables**: usually safe to skip — generic items rarely contradict

## Cost

~$0.002 per check with Claude Sonnet (2-3k tokens of context for the bible). Budget accordingly.

## When the grader says "new_lore"

Don't auto-block. Surface to a human:
- If the new lore is a small flavorful detail (a fictional inn name, a minor wandering trader): probably fine
- If it's a major faction, location, or named character: requires WORLD_BIBLE update before merging
