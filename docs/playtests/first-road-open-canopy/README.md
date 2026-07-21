# First Road open-canopy evidence

Native and Web comparisons from the production Bold First Road, judged beside
`docs/concept-art/gameplay-direction/wayfinder-state-02-first-hollow.png`.

- `before-native.png` — exact shipped `0.1.9-soft-ground` frame.
- `after-native.png` — accepted moving `0.1.10-open-canopy` frame after two
  rejected canopy-only passes; the player has moved and fired through the
  widened low foreground opening.
- `before-web.png` / `after-web.png` — exact exported comparison; the accepted
  frame shows the low foreground wall opening and continuous forest surround.

The accepted native frame keeps the dark continuous forest and natural wall
silhouette while exposing more playable ground and a readable corridor mouth.
The compact rear tiers remain presentation-only children of each wall's
cutaway-owned `WallMesh`; the wider cutaway remains opaque and changes no
collision, navigation, encounter, room, or camera-control truth.

Validation receipts: 888/888 canonical assertions; 120/124 retained direct
entrypoints after the one-frame movement tolerance reran green, leaving only
the four documented driver/repro and old movement exceptions; 112/112 audited
release resources; clean browser title/town/world/complete route with an empty
warning/error ledger. Exact PCK: 105,923,952 bytes, SHA-256
`add43de81df0b0416608d86d02a6356b804e69f9a7149aae644cf98f5c363bb8`.

Companion receipt: owner-only Field Journal version 9, source
`5e5532d9671bac7b1e85a09d58080dc68006067a`, deployed successfully at
`https://wayfinder-field-journal.iamactuallyinthearen.chatgpt.site`.
