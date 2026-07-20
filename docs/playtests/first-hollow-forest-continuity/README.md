# First Hollow forest continuity evidence

Exact `0.1.7-shaded-road` before and `0.1.8-deep-wood` after captures from the
production First Road at 1280×720. The approved comparison remains
`docs/concept-art/gameplay-direction/wayfinder-state-02-first-hollow.png`.

- `before-native.png` / `after-native.png` — native Forward+ hands-on play.
- `before-web.png` / `after-web.png` — WebGL Compatibility gameplay frames from
  the compact production title → town → generated First Road → return route.
- Crop: image rows 8% through 82%; luminance is mean RGB in normalized sRGB.
- Near-black threshold: luminance below `0.025`.
- Web before: `0.2684`; Web after: `0.0000`; approved concept: `0.0001`.
- Native after: `0.0000` near-black coverage.

The after frames show the playable clearing inside continuous forest depth.
The foreground wall remains brighter and readable, and the exterior bed never
becomes route, collision, navigation, interaction, or encounter authority. The
existing complete-wall cutaway lowers and restores both new depth tiers, and
its production scan remains below 1.5 ms.

Validation receipts: 878/878 canonical assertions; 118/122 retained direct
entrypoints with the four documented driver/repro and old movement exceptions;
112/112 audited release resources; clean browser title/town/world/complete
route with no warning or error diagnostics. Exact PCK: 105,923,504 bytes,
SHA-256 `1b77869a37ec656e664e4d0b4212667812c0808ff47b35377b0f501472d06ce7`.
