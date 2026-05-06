// Echo Charts — known places the player can echo (Wayfinding Depth #3).
//
// Each place defines:
//   id         — stable scope tag, used in chart items + atlas
//   name       — display name
//   anchor     — center tile in the live overworld (we snapshot a region
//                around this point at echo-enter time)
//   radius     — half-width of the echo (radius=6 → 13×13 tiles captured)
//   enemies    — list of {kind, n} that replaces the peaceful residents.
//                Spawned around the periphery of floor tiles.
//   reqCarto   — minimum Wayfinding level to inscribe this echo
//   tier       — chart tier (drives loot table)
//   reqDiscovery — anchor tile must be in the player's discovered set
//   bossKind   — optional: an echo can carry a single boss
//
// Anchors reference live runtime constants (HOD_TILE etc.) by name so we
// resolve them at echo-time — keeps this file pure data.

export const ECHO_PLACES = [
  {
    id:           'echo_village',
    name:         'Echo: Bramblewood Square',
    description:  'A copy of the village square — but the residents are gone, and the fields are walked by hostiles.',
    anchorRef:    'cookSpawn',         // world.cookSpawn
    radius:       6,
    enemies:      [
      { kind: 'bramble_imp', n: 3 },
      { kind: 'iron_gob',    n: 2 },
    ],
    reqCarto:     35,
    tier:         2,
  },
  {
    id:           'echo_forge',
    name:         "Echo: Hod's Forge",
    description:  'The forge yard, but the bellows are cold and the anvil rings under iron-shod feet.',
    anchorRef:    'HOD_TILE',
    radius:       5,
    enemies:      [
      { kind: 'iron_gob',         n: 2 },
      { kind: 'bramble_charger',  n: 2 },
    ],
    reqCarto:     40,
    tier:         3,
  },
  {
    id:           'echo_perch',
    name:         "Echo: Withering's Perch",
    description:  'The falconer\'s perch is empty. The hedge-hawks circle, hungry.',
    anchorRef:    'WITHERING_TILE',
    radius:       5,
    enemies:      [
      { kind: 'hedgewolf',     n: 2 },
      { kind: 'bramble_archer', n: 2 },
    ],
    reqCarto:     45,
    tier:         3,
  },
];

export function placeById(id) {
  return ECHO_PLACES.find(p => p.id === id) || null;
}
