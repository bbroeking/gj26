# Hedgemother — Bramble-Vine Pull (phase 2 mechanic)

> Sketch for the first unique boss mechanic, blocking task #3 in the
> Tier 3 plan. Prefer review of this doc before I touch `src/game/enemies.js`.
> Designed to reuse existing infra (`spawnLineTelegraph`, telegraph
> windup tokens, parryOnly attack frame) so the diff is ~50 lines.

## Why this fight, why this attack

Hedgemother already has `parryOnly: true` — her thorn-slam is a RED
attack that the player must Riposte to negate. Combat against her plays
out as:

- (phase 1) every ~1.8s she telegraphs a 3×3 thorn-slam; the player
  parries on impact-frame for the riposte buff
- (phase 2, ≤50% HP) `e._lashAlt` flips so 50% of her attacks become a
  4-tile **lash** in her facing direction; same parry timing, different
  shape. Player has to read the shape during the windup.

The fight is well-paced for a **standing duel** — but the player can
trivialize it by **kiting**: walk away, throw a spell, back off. Her
slam range is 1×1 and her lash is a fixed 4 tiles, both predictable. The
designed-for-melee cadence collapses against ranged play.

The bramble-vine pull is the answer. Not "more damage" — that just
makes the duel sharper. The pull **breaks distance management**: any
time you're in pull range, she can yank you 2 tiles toward her +
root-pin you for a follow-up. Forces the player to engage on her terms
or use Quiet Thought / dodge-dance to escape.

## The mechanic

### Trigger

- Phase 2 only (HP ≤ 50%, after `phase2Triggered` flips).
- Cycles in alongside slam + lash. New `e._brambleAlt` counter:

  | tick | attack |
  |------|--------|
  | 0    | slam   |
  | 1    | lash   |
  | 2    | **pull** |
  | 3    | slam   |
  | …    | repeat |

  So the player gets a pull every ~5.4s of in-combat time. Telegraphed
  like the others — counterable.

### Telegraph

- Same `<scene/telegraph.js>` infra as lash. New color
  `TELEGRAPH_COLORS.PULL` = warm green-amber (#a4b04a).
- Line shape from Hedgemother's tile to the player's tile **at windup
  start** — like the existing lash, but emanating *from* the boss
  outward rather than along her facing.
- Windup duration: **0.85s** (matches lash; lets the player register).

### Resolution (after windup)

- Re-evaluate the line: if the player is still anywhere on it, the
  pull lands. (Generous: any tile of the line counts.)
- If the player **dodged with i-frames during the windup** (existing
  `player.iframeT > 0` check), the pull is negated — quiet skip, no log.
- Else **pull the player 2 tiles toward the boss** along the line, AND
  set `player.rootedT = 1.0` (1 second of forced-stationary).
- During root: `player.rootedT > 0` blocks `startStep` and pathfinding
  step consumption — same gate as the existing dodge cooldown but
  movement-side.
- **No direct damage** from the pull. The setup is the threat — the
  next tick's slam (which arrives 1.8s later, cooldown-permitting)
  almost certainly connects on a rooted player.

### Counter-play

- **Dodge** during windup (already ungated for non-parryOnly attacks; the
  pull is yellow-amber, not red, so dodging i-frames cleanly through it).
- **Be out of line** at evaluation. Move perpendicular to the boss-line
  during windup; the line is fixed at windup-start, so moving away
  works.
- **Quiet Thought** spell drops her aggro briefly — pull never fires if
  she's not aggro'd.

## Code sketch

Three insertion sites in `src/game/enemies.js`. All under the
`if (e.attackCd === 0)` block already guarding the slam/lash/pull
switch.

```js
// Around line 1237 — replace the phase2Lash boolean with a 3-state cycle.
const phase2 = (e.phase === 2);
let attackKind = 'slam';
if (phase2) {
  e._brambleAlt = ((e._brambleAlt | 0) + 1) % 3;
  attackKind = ['slam', 'lash', 'pull'][e._brambleAlt];
}

// Around line 1241 — gate the existing isSlam by attackKind.
const isSlam = attackKind === 'slam' || (!phase2 && (isBoss || !!e.slam));
const isLash = attackKind === 'lash';
const isPull = attackKind === 'pull';

// Around line 1244 — pull uses lash's cooldown (long windup).
e.attackCd  = Math.round(
  (isPull ? 110 : isSlam ? 110 : 75) * cdScale
);
e.attackAnimT = (isPull ? 0.85 : isSlam ? 0.75 : 0.55) * cdScale;

// Around line 1251 — telegraph dispatch — add a pull branch.
import('../scene/telegraph.js').then(m => {
  let color;
  if (e.parryOnly && isSlam)  color = m.TELEGRAPH_COLORS.PARRY_ONLY;
  else if (isPull)            color = m.TELEGRAPH_COLORS.PULL || 0xa4b04a;
  else if (isBoss)            color = m.TELEGRAPH_COLORS.BOSS;
  else if (isSlam)            color = m.TELEGRAPH_COLORS.AOE;
  else                        color = m.TELEGRAPH_COLORS.NORMAL;

  if (isPull) {
    // Line from boss → player, pinned at windup start.
    m.spawnLineTelegraph(e.x, e.y, player.x, player.y, 0.85, { color });
  } else if (isLash) {
    /* existing line code */
  } else if (isSlam) {
    /* existing area code */
  }
});

// Around line 1278 — strike resolution — add pull branch.
e.queuedHit = setTimeout(() => {
  e.queuedHit = null;
  releaseWindupToken(e);
  if (!e.alive) return;
  if (e.staggered) return;

  if (isPull) {
    // Dodge i-frames cleanly negate the pull.
    if (player.iframeT > 0) return;
    // Did the player exit the line? Cheap check: distance from the
    // line segment boss→targetPlayer ≤ 0.6 tiles.
    if (!_onLine(player, e, targetPlayer)) {
      log('combat', `${_label}'s vine misses.`);
      return;
    }
    // Pull 2 tiles toward boss, root for 1s. No damage.
    pullPlayerToward(player, e, 2);
    player.rootedT = 1.0;
    log('combat', `${_label} drags you in!`);
    import('../core/sfx.js').then(m => m.sfx.thud());
    return;
  }

  /* existing slam / lash branches */
}, strikeDelayMs);
```

Helpers (new, in same file or `src/game/player.js`):

```js
function _onLine(player, boss, target) {
  // distance from player.pos to segment boss.pos→target.pos
  // simple 2D point-to-segment in the X/Z plane.
  // tolerance 0.6 tiles lets a half-step dodge save the player.
}

export function pullPlayerToward(player, boss, tiles) {
  // Step the player N tiles along (boss.x - player.x, boss.y - player.y)
  // by the dominant axis, snapped to grid, blocked by walls.
  // Reuses isBlocked from main.js — pass it in or move to a helper.
}
```

Player-side, in `src/game/player.js` `updatePlayerMovement(player, dt)`:

```js
// Tick the root timer (added next to defensiveT / stoneSkinT).
if (player.rootedT > 0) player.rootedT = Math.max(0, player.rootedT - dt);
```

And in `src/main.js` movement gate (the keyboard/path block ~5418):

```js
if (player.rootedT > 0) {
  // Show a brief "Rooted!" floater on first frame of the root, then
  // suppress all movement input until the timer expires.
  return;     // skip startStep + path consumption
}
```

## Numbers to tune

| | Default | Notes |
|---|---|---|
| pull windup | 0.85s | matches lash; long enough to read |
| pull range | unlimited within map | no fall-off; designed-for-kiting break |
| pull distance | 2 tiles | one tile is barely a feel; three resets the duel |
| root duration | 1.0s | ~one slam window; second slam usually connects |
| line tolerance | 0.6 tiles | mid-step dodges save the player cleanly |
| cycle: slam/lash/pull | even rotate | 33% pull rate phase 2; reduce to 25% if too oppressive |

## Risks / edge cases

- **Pull through walls**: the existing world has clean tile blocking;
  `pullPlayerToward` should respect `isBlocked`. If the path is blocked,
  pull the player as far as they can go.
- **Root + falcon/spell**: spells/abilities should still fire while
  rooted — the gate is *movement*, not *casting*. Worth verifying once
  shipped.
- **Multiple Hedgemothers** in the same fight: edge case (two-boss
  arena), but ensure `_brambleAlt` is per-enemy not per-class.
- **Player already adjacent**: pulling 2 tiles toward the boss when
  already 1 tile away → just keeps them adjacent. Fine, no error.

## Estimated diff

~50 lines in `src/game/enemies.js`, ~5 in `player.js`, ~5 in `main.js`.
One new color constant in `src/scene/telegraph.js`. Unit-of-work: 1 hour
including playtesting + tuning.

## Open question

> Bramblewood is **cozy fairytale**. Does a forced-pull mechanic feel
> appropriate, or should phase 2's mechanic be softer (e.g., she calls
> down a thorn-rain that the player avoids)? Pull is mechanically the
> right anti-kite tool, but tonally it's the meanest move in the kit so
> far. Worth running it past you before I implement.
