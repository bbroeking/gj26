// Living Atlas — runtime state + persistence for chart-completion tracking.
//
// Player state lives at `player.atlas = { completions: { [regionId]: count },
// unlockedBiomes: Set<string> }`. We persist completions + biomes to
// localStorage on every change.
//
// Public API:
//   ensureAtlasLoaded(player)
//   recordChartCompletion(player, scope) → { region, justUnlocked, biomeId }
//   getRegionState(player, regionId)     → { count, threshold, unlocked }
//   isBiomeUnlocked(player, biomeId)
//   listUnlockedBiomes(player)

import { ATLAS_REGIONS, regionForScope, regionById } from '../data/atlas-regions.js';

const STORAGE_KEY = 'gj26.atlas.v1';

export function ensureAtlasLoaded(player) {
  if (player.atlas?._loaded) return;
  player.atlas = {
    _loaded: true,
    completions: {},                      // regionId → integer count
    unlockedBiomes: new Set(),
  };
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (raw) {
      const data = JSON.parse(raw);
      if (data?.completions) player.atlas.completions = data.completions;
      if (Array.isArray(data?.unlockedBiomes)) {
        player.atlas.unlockedBiomes = new Set(data.unlockedBiomes);
      }
    }
  } catch (_) {}
}

function persist(player) {
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify({
      completions: player.atlas.completions,
      unlockedBiomes: Array.from(player.atlas.unlockedBiomes),
    }));
  } catch (_) {}
}

/** Record a chart completion. Returns { region, justUnlocked, biomeId }
 *  where `justUnlocked` is true only if this completion crossed the
 *  region's threshold this call (the call site uses that to fire the
 *  unlock celebration). */
export function recordChartCompletion(player, scope) {
  ensureAtlasLoaded(player);
  const region = regionForScope(scope);
  if (!region) return { region: null, justUnlocked: false, biomeId: null };

  const before = player.atlas.completions[region.id] || 0;
  const after  = before + 1;
  player.atlas.completions[region.id] = after;

  let justUnlocked = false;
  if (before < region.threshold && after >= region.threshold) {
    if (!player.atlas.unlockedBiomes.has(region.biomeUnlock)) {
      player.atlas.unlockedBiomes.add(region.biomeUnlock);
      justUnlocked = true;
    }
  }
  persist(player);
  return { region, justUnlocked, biomeId: region.biomeUnlock };
}

export function getRegionState(player, regionId) {
  ensureAtlasLoaded(player);
  const region = regionById(regionId);
  if (!region) return null;
  const count = player.atlas.completions[region.id] || 0;
  return {
    count,
    threshold: region.threshold,
    unlocked: player.atlas.unlockedBiomes.has(region.biomeUnlock),
    region,
  };
}

export function isBiomeUnlocked(player, biomeId) {
  ensureAtlasLoaded(player);
  return player.atlas.unlockedBiomes.has(biomeId);
}

export function listUnlockedBiomes(player) {
  ensureAtlasLoaded(player);
  return Array.from(player.atlas.unlockedBiomes);
}

export { ATLAS_REGIONS };
