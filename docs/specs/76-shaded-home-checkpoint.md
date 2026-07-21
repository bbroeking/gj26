# 76 — Shaded Home checkpoint

> **Outcome:** The first view of Bramblewood reads as a warm, grounded home in
> native and Web play instead of a pale green field with clipped highlights.

## Why this is the checkpoint

The exact shipped `0.1.15-creature-identity` replay leaves its clearest visual
gap before the first Chart is chosen. The Town yard is materially brighter and
flatter than the approved Arrival concept in native Forward+ and clips still
further in Web Compatibility. Grass, paths, the ranger, Mara, and station props
collapse into nearly the same high-value band, weakening both the welcome and
the route to the first conversation.

This checkpoint corrects that one rendering authority. It does not rebuild the
yard, move stations, add buildings, change the camera, or add another system.

## Scope

**In:**

- Apply one centralized post-tonemap grade to Town's duplicated 3D
  `Environment`.
- Restore readable shadow, midtone, and highlight separation in native play.
- Apply a stronger renderer-aware brightness correction in Web Compatibility,
  where the same world currently clips further.
- Compare exact native and Web captures with the approved Arrival concept.

**Out:**

- Changing Town geometry, paths, stations, props, spawn points, camera,
  controls, quests, interactions, audio, or progression.
- Placing a full-screen overlay over Canvas UI.
- Regrading generated Roads or later biomes.
- Adding assets, buildings, foliage systems, paid services, or parallel visual
  pipelines.

## Player-visible contract

1. The ranger, Mara, dirt paths, grass, flowers, and station props occupy
   distinct value bands at the shipped FATE camera.
2. The yard stays warmly lit and cozy; the correction must not become a dark
   vignette or mute the green-and-amber palette.
3. Web play approaches the native result instead of clipping the yard into a
   near-white field.
4. Quest parchment, Field Journal UI, labels, prompts, and input feedback are
   unchanged because the correction belongs only to the 3D environment.
5. Town layout, camera, collision, controls, interactions, quests, audio, and
   save behavior are unchanged.

## Acceptance criteria

1. A focused production test proves the native grade, Web override, cloned
   environment ownership, and absence of any Canvas overlay.
2. Exact native before/after captures and the approved Arrival concept are
   retained together and show materially clearer foreground, route, and actor
   separation.
3. The exact exported Web build shows the same correction at 1280×720 and
   completes the fail-closed title → town → chart table → Creature Codex → road
   → return journey without warnings or errors.
4. The full canonical native gate and representative save/transition checks
   remain green.
5. Roadmap, notes, changelog, devlog, version, test manifest, public game, and
   owner-only companion site are current and verified before acceptance.

## Reference

- `docs/concept-art/gameplay-direction/wayfinder-state-01-arrival.png`

