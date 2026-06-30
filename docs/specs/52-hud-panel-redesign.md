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
1. **Layout reorg** (D20 ✓): objective → compact chip top-LEFT; run-meta plaque
   top-RIGHT; always-on mute removed → transient toast.
2. **Vitals + bar** (D21 ✓): GlobeGauge orbs slimmed (R 40→36, the thick wood
   ring + 4 bramble pegs replaced by a teal rim + gold pinstripe); draught is now
   a real **Q-slot** appended to the hotbar (♨ + GOLD "Q" + ×N count from the
   full DRAUGHT_ORDER, dimmed at 0, click-to-drink). Globes pushed to ±258 to
   clear the wider 5-slot tray.
3. **Pack buttons** (D21 ✓): Gear/Satchel/Trades are 50px Enamel icon buttons —
   painted icon medallion, top-left key-hint, trade-color underline tab (was
   carried by the text), word moved to the tooltip.
4. **Compass** (D21 ✓): a CompassArrow Control just right of the chip resolves
   its target each frame (live exit/descent waystone via the `abandoning`
   duck-type, else the live boss arena), projects (target−player) through the
   camera ground basis to a screen heading, eases it, draws a gold arrow on a
   teal disc. Hidden in town + on arrival.

## Panel redesign (follow-on)
The Gear/Satchel pack + crafting bench: flip to Enamel teal (user-approved) AND
reconsider layout — paper-doll + grid read cleanly, charts/trades split from
inventory. Detailed after the HUD passes land.

## Constraints
Keep all six test suites green (boot_smoke catches HUD parse/boot errors).
Screenshot each pass in-bog (WYRD_DEV_CHART=mire) to verify coherence.
