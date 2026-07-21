# Spec 76 implementation notes — Shaded Home checkpoint

## Decisions

- Resume from the shipped `0.1.15-creature-identity` checkpoint and treat its
  public versioned Pages build as the baseline.
- Keep the correction on Town's 3D `Environment`; Canvas UI and world geometry
  are not part of this checkpoint.
- Protect warmth and route legibility while compressing the clipped highlight
  band. Native and Web may use different brightness values because they are
  different renderers presenting the same approved art direction.

## Deviations

- None.

## Tradeoffs

- A bounded grade cannot make the current yard composition identical to the
  concept's denser building frame. It can make the existing authored yard
  readable enough to judge composition honestly in the next replay.
- Accepted native brightness `0.62`, Web brightness `0.56`, contrast `1.15`,
  and saturation `1.08`. Lower Web trials removed the wash but made the whole
  clearing feel overcast; the accepted value keeps route and actor separation
  without losing the welcoming daylight.

## Surprises

- The settled native Forward+ capture is already substantially paler than the
  approved Arrival concept; Web Compatibility clips it further. The weakness
  is therefore a shared Town grade gap with an additional Web mismatch, not a
  Web-only regression.

## Followups

- After Shaded Home ships, replay the exact arrival before deciding whether
  camera framing, foreground foliage, or landmark composition remains the next
  highest-leverage gap.

## Validation ledger

- Baseline native first-arrival barrier released in 961.3 ms; its existing
  capture driver still reports teardown-only texture/RID warnings.
- Exact shipped public Web play reproduced the clipped yard at 1280×720.
- Approved comparison:
  `docs/concept-art/gameplay-direction/wayfinder-state-01-arrival.png`.
- The focused Town contract passes 10/10. Boot 148/148, movement 14/14,
  transitions 125/125, First Road 14/14, core loop 427/427, and save roundtrip
  120/120 pass after the final values.
- The full canonical gate passes 20 suites and 996 assertions.
- The exact Web export audits all 118 required resources. A real 1280×720
  browser arrival retains the parchment colors and restores world separation;
  the enhanced fail-closed route passed `title → town → chart_table → codex →
  chart_table_closed → world → complete`. The final versioned PCK is
  96,120,576 bytes with SHA-256
  `7499e80d380ba0a6b82d392ffd7db17787bf90f81fbaad1e4a5d625cca7987ce`.
- Source checkpoint `9125935b99e31853f91109fa4a159a76377fdd82` and GitHub
  Pages deployment `0bddb09339449079b68815774b386cf7ce07e0d6` are pushed.
  The exact public versioned journey passed after deployment.
- Owner-only companion Field Journal version 16 deployed successfully from
  source `552de19cbccc71b818b28a2188c972f7457e7941`; its page, hero evidence,
  playable export, and release fingerprint were verified from production.
