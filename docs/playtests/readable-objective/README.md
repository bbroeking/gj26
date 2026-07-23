# Readable Objective checkpoint evidence

## Question

Can the objective HUD become a little larger and more obvious without turning
into a banner or globally scaling the accepted interface?

## Result

Yes. The same Storybook Corners card is now 372 pixels wide with an 18-pixel
objective, 16-pixel guidance, darker supporting green, and a slightly stronger
wood edge and shadow. The player's supplied frame no longer orphans
`Wayfinder`, while the longer fresh-journey objective wraps into two balanced
lines in the real Web build.

## Rendered evidence

- `before.png` — the player-supplied 0.1.19 frame.
- `after-native.png` — the immediate native Forward+ Town frame.
- `after-web-immediate.png` — the immediate real-browser guidance.
- `after-web-recovery.png` — the 20-second landmark recovery.
- `after-web-direct.png` — the 35-second direct guidance and compass.

All three browser states remain content-hugging and readable at 1280×720. The
browser warning/error ledger is empty.

## Validation

- Focused HUD and Pack contract: 36/36.
- Canonical checkpoint gate: 1,055/1,055 across 23 suites.
- Guarded save roundtrip: 120/120.
- Web release-resource audit: 118/118.
- Web package: 96,120,928 bytes; SHA-256
  `619b5db4494e1abd2bac1db740da7f0c6cb0072b8e52ccbd7f6ba8c0bd77c555`.
