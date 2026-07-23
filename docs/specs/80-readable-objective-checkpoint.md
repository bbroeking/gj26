# Spec 80 — Readable Objective checkpoint

## Player-visible problem

At the accepted 1280×720 play frame, the top-left objective plate is present
but asks for effort: its 320-pixel width wraps short objectives awkwardly, its
supporting line is small and muted, and the whole card reads as incidental
decoration against the bright Town world.

## Promise

The same storybook objective plate is immediately legible at normal play
distance. It is only one measured step larger and stronger—not a new HUD,
not a global interface scale change, and not a larger interruption of the
world.

## Scope

- Increase the objective plate width by roughly 15 percent.
- Raise header, objective, progress, and hint type by one restrained step.
- Darken supporting green copy against the cream parchment.
- Give the existing wood frame and shadow slightly more separation.
- Retune content-hug height and compass placement for the larger plate.
- Capture and inspect the real first-controllable 1280×720 Town frame.

## Boundaries

- Preserve the Storybook Corners layout, parchment/wood language, typography,
  objective wording, controls, recovery timing, compass behavior, and world.
- Do not globally scale the HUD or alter hotbar, vitals, Pack actions, toast
  positions, modal surfaces, camera, Town composition, or gameplay.
- Keep the component inside the top-left edge and subordinate to the playfield.
- Do not solve the separate objective/control/recovery composition question in
  this checkpoint.

## Acceptance

- The plate is at least 360 pixels wide and remains within a 400-pixel budget.
- The objective is at least 18 pixels and supporting guidance at least 16.
- The first Mara objective no longer orphans `Wayfinder` onto its own line.
- The plate remains content-hugging in its immediate, 20-second, and 35-second
  guidance states.
- The focused HUD contract, canonical checkpoint gate, and rendered native
  frame pass before the change is considered accepted.
