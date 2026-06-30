# Spec 52 — HUD + panel redesign from first principles (Direction A)

Playtest: "everything needs a redesign from first principles." After fixing the
acute breakages (interact popover D17, modal dismiss D17), the remaining work is
the structural HUD + panel rethink. User picked **Direction A — Storybook
Corners**.

## First-principles critique of the old HUD
- Everything piled into bottom-center (HP orb, 4 skills, Focus orb, draught
  chip, mute label) — one overloaded zone.
- Persistent noise: "F10 mutes" on screen forever; quest banner a 520px two-line
  plate for read-once info.
- No orientation: nothing points to the objective (worse now that zones are
  bigger, D18).
- Inconsistent visual languages: ornate bramble-nest orbs vs. flat text pack
  buttons vs. tiny corner meta.

## Principle
**Edges hold persistent state; the center stays clear for the world.** Group by
function, one language (the Enamel kit), surface situational info only when
relevant.

## Direction A — Storybook Corners (in-run HUD)
```
 ◇ Reach the Summit den        ⌖ Depth 2 · 240g · Wyrd 8
   ▪vein ▪grove ▪bloom               (run meta, top-right)
        ↑ compass to objective

              · · · world stays clear · · ·

  ╭───╮ ┌──┬──┬──┬──┐ ╭─╮ ╭───╮    ⌂Gear ⌂Satchel ⌂Trades
  │HP │ │1 │2 │3 │4 │ │Q│ │Foc│     (icon buttons, same kit)
  ╰───╯ └──┴──┴──┴──┘ ╰─╯ ╰───╯
```

### Build passes
1. **Layout reorg** (this pass): objective → compact one-line chip top-LEFT with
   affix sub-line; run-meta (gold · Wayfinding, later + Depth) → a clean plaque
   top-RIGHT; remove the always-on mute label, show mute only as a transient
   toast on F10.
2. **Vitals + bar**: slim the GlobeGauge orbs (lighter nest ornament), add the
   draught as a real **Q-slot** on the hotbar instead of a floating "♨ ×N · Q"
   chip.
3. **Pack buttons**: Gear/Satchel/Trades as icon buttons in the Enamel kit
   (bottom-right), matching the hotbar language.
4. **Compass**: a small arrow at the objective chip that points toward the
   descent/exit waystone in world space (projected through camera yaw); hidden
   when there's no target. Closes the orientation gap.

## Panel redesign (follow-on)
The Gear/Satchel pack + crafting bench: flip to Enamel teal (user-approved) AND
reconsider layout — paper-doll + grid read cleanly, charts/trades split from
inventory. Detailed after the HUD passes land.

## Constraints
Keep all six test suites green (boot_smoke catches HUD parse/boot errors).
Screenshot each pass in-bog (WYRD_DEV_CHART=mire) to verify coherence.
