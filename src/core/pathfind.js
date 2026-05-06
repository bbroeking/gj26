// A* pathfinder on a 4-connected tile grid.
// Returns an array of {x, y} from start (exclusive) to goal (inclusive),
// or null if unreachable.

function key(x, y) { return x * 10000 + y; }
function heuristic(a, b) { return Math.abs(a.x - b.x) + Math.abs(a.y - b.y); }

export function findPath(start, goal, isBlocked, opts = {}) {
  const maxNodes = opts.maxNodes ?? 4000;
  const allowGoalIfBlocked = opts.allowGoalIfBlocked ?? false;

  if (start.x === goal.x && start.y === goal.y) return [];

  const open = new Map();      // key -> {x, y}
  const closed = new Set();
  const gScore = new Map();
  const fScore = new Map();
  const cameFrom = new Map();

  const sk = key(start.x, start.y);
  open.set(sk, start);
  gScore.set(sk, 0);
  fScore.set(sk, heuristic(start, goal));

  let visited = 0;
  while (open.size > 0 && visited < maxNodes) {
    visited++;
    // pick lowest fScore in open set (linear scan; small grid, fine)
    let bestK = null, bestF = Infinity;
    for (const [k, _] of open) {
      const f = fScore.get(k) ?? Infinity;
      if (f < bestF) { bestF = f; bestK = k; }
    }
    if (bestK === null) break;
    const current = open.get(bestK);
    if (current.x === goal.x && current.y === goal.y) {
      return reconstruct(cameFrom, current);
    }
    open.delete(bestK);
    closed.add(bestK);

    for (const [dx, dy] of [[1, 0], [-1, 0], [0, 1], [0, -1]]) {
      const nx = current.x + dx;
      const ny = current.y + dy;
      const nk = key(nx, ny);
      if (closed.has(nk)) continue;
      // Allow stepping onto goal even if blocked (for "click on entity")
      const isGoal = nx === goal.x && ny === goal.y;
      if (isBlocked(nx, ny) && !(isGoal && allowGoalIfBlocked)) continue;
      const tentative = (gScore.get(bestK) ?? Infinity) + 1;
      const neighborG = gScore.get(nk) ?? Infinity;
      if (tentative < neighborG) {
        cameFrom.set(nk, current);
        gScore.set(nk, tentative);
        fScore.set(nk, tentative + heuristic({ x: nx, y: ny }, goal));
        if (!open.has(nk)) open.set(nk, { x: nx, y: ny });
      }
    }
  }
  return null;
}

function reconstruct(cameFrom, end) {
  const out = [end];
  let cur = end;
  while (true) {
    const k = key(cur.x, cur.y);
    const prev = cameFrom.get(k);
    if (!prev) break;
    out.unshift(prev);
    cur = prev;
  }
  // drop the start tile (player is already there)
  out.shift();
  return out;
}

/**
 * Path from `start` to a tile adjacent to `goal` (4-connected).
 * Useful for "walk up to entity" — entity tile itself is blocked.
 * Returns the best (shortest) such path or null.
 */
export function pathToAdjacent(start, goal, isBlocked) {
  const candidates = [
    { x: goal.x + 1, y: goal.y },
    { x: goal.x - 1, y: goal.y },
    { x: goal.x, y: goal.y + 1 },
    { x: goal.x, y: goal.y - 1 },
  ];
  let best = null;
  for (const c of candidates) {
    if (isBlocked(c.x, c.y)) continue;
    if (start.x === c.x && start.y === c.y) return [];
    const p = findPath(start, c, isBlocked);
    if (p && (!best || p.length < best.length)) best = p;
  }
  return best;
}
