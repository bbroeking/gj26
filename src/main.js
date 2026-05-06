// Main — three.js scene, world, player, loop.
import * as THREE from 'three';
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';
import { EffectComposer } from 'three/addons/postprocessing/EffectComposer.js';
import { RenderPass } from 'three/addons/postprocessing/RenderPass.js';
import { UnrealBloomPass } from 'three/addons/postprocessing/UnrealBloomPass.js';
import { ShaderPass } from 'three/addons/postprocessing/ShaderPass.js';
import { OutputPass } from 'three/addons/postprocessing/OutputPass.js';
import { CONFIG } from './data/config.js';
import { ITEMS, pickRandomLoreParchment } from './data/items.js';
import { isPressed, takeInteract, takeDodge, takeAbility, takeTargetSwap, takePotion, takeJournal, takeSketch, takeCast, getSlotKey } from './core/input.js';
import { castSpell, canCast, SPELLS } from './game/spells.js';
import { attachMouse, takeLeftClick, takeRightClick, getHoverTile } from './core/mouse.js';
import { findPath, pathToAdjacent } from './core/pathfind.js';
import { createCamera, updateCamera } from './core/camera.js';
import { spawnFloat, spawnSplat, updateFloaters } from './core/floaters.js';
import { animateKnight, triggerSwing, triggerHurt } from './anim/procedural.js';
import { animateCow } from './anim/cow.js';
import { animateQuadruped } from './anim/quadruped.js';
import { animateBird } from './anim/bird.js';
import { World } from './scene/world.js';
import { terrainHeightAt } from './scene/terrain.js';
import { buildCookMesh, buildFireMesh, buildClickMarker, getWaterMaterial, loadCowGLB, loadKnightBase, loadEquipment, loadAllArchetypes, buildArchetypeMesh, loadGoblinGLB, loadBrambleImpGLB, loadHedgewightGLB, loadChartmakerStoneGLB, loadBurrowBoarGLB, loadWolfAlphaGLB, loadCookGLB, loadOakGLB, loadCastleGLB, loadForgeGLB, loadCottageGLB, loadWellGLB, loadBankGLB, loadSignpostGLB, loadChickenGLB, loadHareGLB, loadBoarGLB, loadHedgemotherGLB, loadHodGLB, loadMaudGLB, loadQuillGLB, loadWitheringGLB, loadApprenticesHammerGLB, loadHealingDraughtGLB, loadFalconsWhistleGLB, loadBrambleResinGLB, loadWhickerharesFootGLB, loadThornCrownGLB, loadPantryStewGLB, loadHodsAnvilTokenGLB, loadWitheredBrambleGLB, loadPracticeDummyGLB, loadMemorialLanternGLB, loadDryingRackGLB, loadFalconerPerchGLB, loadSkitterlingGLB, loadMarshRatGLB, loadIronGobGLB, loadTuskerSowGLB, loadBrambleArcherGLB, loadBrambleChargerGLB, loadEldraGLB, loadCricketGLB, loadPellGLB, loadOnywynGLB, buildEldraMesh, buildCricketMesh, buildPellMesh, buildOnywynMesh, loadTier3ItemGLBs, buildItemGLBMesh, buildChartmakerStoneMesh, buildHodMesh, buildQuillMesh, buildWitheringMesh, buildWitheredBrambleMesh, buildPracticeDummyMesh, buildMemorialLanternMesh, buildDryingRackMesh, buildFalconerPerchMesh, buildFalconMesh, toonifyMaterials } from './scene/characters.js';
import { animateGLBKnight, triggerAttack } from './anim/knight.js';
import { animateGoblin } from './anim/goblin.js';
import { makeSmoke, updateSmoke } from './scene/smoke.js';
import { spawnClouds } from './scene/clouds.js';
import { spawnDemoPads } from './scene/demoPads.js';
import { createPlayer, updatePlayerMovement, startStep, setPath, consumePathStep, tryDodge } from './game/player.js';
import { showCharCreator } from './ui/charCreator.js';
import { installDevConsole } from './ui/devConsole.js';
import { showLevelUp, showDialog } from './ui/dialog.js';
import { showWorldMap, closeWorldMap, isWorldMapOpen } from './ui/worldMap.js';
import { showFieldJournal, closeFieldJournal, isFieldJournalOpen } from './ui/fieldJournal.js';
import { showInscribingTable, closeInscribingTable, isInscribingTableOpen, inscribe as inscribeTable, placeIngredient as itPlace, removeIngredient as itRemove, loadKnownRecipes } from './ui/inscribingTable.js';
import { showSpellbook, closeSpellbook, isSpellbookOpen } from './ui/spellbook.js';
import { showPedestal, closePedestal, isPedestalOpen } from './ui/pedestal.js';
import { showWayfindingWorkshop, closeWayfindingWorkshop, isWayfindingWorkshopOpen, reopenIfWasOpen as reopenWayfindingWorkshop, noteSketchThisSession, setWorkshopTarget } from './ui/cartographyWorkshop.js';
import { showPlinthForge, closePlinthForge, isPlinthForgeOpen } from './ui/plinthForge.js';
import { showCookFire, closeCookFire, isCookFireOpen } from './ui/cookFire.js';
import { showRefineStation, closeRefineStation, isRefineStationOpen } from './ui/refineStation.js';
import { MATERIAL_DEFS } from './data/materials.js';
import { showAtlasMap, closeAtlasMap, isAtlasMapOpen } from './ui/atlasMap.js';
import { showMaterialsBrowser, closeMaterialsBrowser, isMaterialsBrowserOpen } from './ui/materialsBrowser.js';
import { ensureAtlasLoaded, recordChartCompletion, isBiomeUnlocked } from './game/atlas.js';
import { generateDungeonLayout, buildDungeonGroup, generateDungeonLoot, loadAuthoredLayout, loadScaffoldLayout, generateEchoLayout } from './scene/dungeon.js';
import { placeById as echoPlaceById } from './data/echo-places.js';
import { pickFor as pickDungeonSpawn } from './data/dungeonSpawns.js';
import { showCharting } from './ui/charting.js';
import { AFFIXES } from './data/affixes.js';
import { SMITH_RECIPES } from './data/smith-recipes.js';
import { COOK_RECIPES } from './data/cook-recipes.js';
import { ORB_RECIPES } from './data/orb-recipes.js';
import { NPC_DEFS } from './data/npcs.js';
import { ABILITIES, SLOT_BINDINGS, tryActivate as tryActivateAbility, isAbilityUnlocked } from './game/abilities.js';
import { getAction, actionUnlocked, actionCanAfford, actionMissingReason, ALL_ACTION_IDS } from './game/actions.js';
import { spawnGroundLoot, spawnArc, updateGroundLoot, clearGroundLoot } from './game/groundLoot.js';
import { spawnHitSparks, updateSparks, setSparkScene } from './scene/sparks.js';
import { setTelegraphScene, updateTelegraphs } from './scene/telegraph.js';
import { setImpactScene, updateImpacts } from './scene/impact.js';
import { setupAmbientDrift, updateAmbientDrift } from './scene/ambientDrift.js';
import { spawnStaminaShimmer, spawnHPShimmer, updateShimmers, clearShimmers } from './game/shimmer.js';
import { writeSave, readSave, applySave, tickAutosave } from './game/save.js';
import { sfx, setMasterVolume, getMasterVolume } from './core/sfx.js';
import { triggerHitStop, sampleHitStop } from './core/hitstop.js';
import { spawnCow, spawnGoblin, spawnChicken, spawnHare, spawnBoar, spawnHedgeWolf, spawnBrambleCap, spawnHedgemother, spawnBurrowBoar, spawnWolfAlpha, spawnSkitterling, spawnMarshRat, spawnIronGob, spawnTuskerSow, spawnArcher, spawnCharger, spawnTargetDummy, resetWindupTokens, updateEnemy } from './game/enemies.js';
import { attackEnemy, damagePlayer } from './game/combat.js';
import { talkToNpc } from './game/npcs.js';
import { questSummary, talkToCook,
  talkToHod, acceptHodQuest, turnInHodQuest,
  acceptHodDelveQuest, turnInHodDelveQuest,
  acceptMaudTuskerQuest, offerMaudTuskerQuest,
  talkToQuill, acceptQuillQuest, turnInQuillQuest,
  acceptQuillBriarQuest, turnInQuillBriarQuest,
  talkToWithering, acceptWitheringQuest, turnInWitheringQuest,
  acceptCrownQuest, turnInCrownQuest } from './game/quest.js';
import { xpProgress, SKILL_KEYS, setLevelUpHook, setXpHook, awardXp } from './game/skills.js';
import { SKILL_MILESTONES, nextMilestone, crossedMilestone } from './data/skill-milestones.js';

// ---------- THREE.JS BOOT ----------
const canvasEl = document.getElementById('three');
const stage = document.getElementById('stage');
const W = stage.clientWidth, H = stage.clientHeight;

const renderer = new THREE.WebGLRenderer({
  canvas: canvasEl, antialias: true, powerPreference: 'high-performance',
});
renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
renderer.setSize(W, H, false);
renderer.outputColorSpace = THREE.SRGBColorSpace;
renderer.toneMapping = THREE.ACESFilmicToneMapping;
renderer.toneMappingExposure = 0.85;     // less hot — sky / sun don't blow out

// shadow setup
renderer.shadowMap.enabled = true;
renderer.shadowMap.type = THREE.PCFSoftShadowMap;

const scene = new THREE.Scene();
setSparkScene(scene);
setTelegraphScene(scene);
setImpactScene(scene);
setupAmbientDrift(scene, { count: 14 });
// Expose item-GLB builder so groundLoot.js can render real models for
// quest-item drops (apprentice's hammer, healing draught, etc.) without
// a hard import cycle.
window.__gj26_buildItemGLB = buildItemGLBMesh;
window.__gj26_shimmerScene = scene;   // exposed for enemies.js shimmer drops

// Sun direction (for the directional light + shadows). Visible sun disc and
// sky color are baked into scene.background below — no procedural Sky shader.
const SUN_ELEVATION = 55;
const SUN_AZIMUTH   = 130;
const sunPosVec = new THREE.Vector3();
sunPosVec.setFromSphericalCoords(
  1,
  THREE.MathUtils.degToRad(90 - SUN_ELEVATION),
  THREE.MathUtils.degToRad(SUN_AZIMUTH)
);

// Baked gradient sky — a 1×256 canvas painted vertically, used as
// scene.background. Top = zenith blue, bottom = warm horizon haze that
// matches the fog color. Fully under our control, no HDR bleed.
const ZENITH  = '#4d7fbf';   // clear blue
const HORIZON = '#c5d6df';   // warm haze
const fogColor = new THREE.Color(HORIZON);

function bakeSkyGradient() {
  const c = document.createElement('canvas');
  c.width = 1; c.height = 256;
  const cx = c.getContext('2d');
  const g = cx.createLinearGradient(0, 0, 0, 256);
  g.addColorStop(0,    ZENITH);
  g.addColorStop(0.55, '#85a8cf');
  g.addColorStop(0.9,  HORIZON);
  g.addColorStop(1,    HORIZON);
  cx.fillStyle = g;
  cx.fillRect(0, 0, 1, 256);
  const tex = new THREE.CanvasTexture(c);
  tex.colorSpace = THREE.SRGBColorSpace;
  tex.minFilter = THREE.LinearFilter;
  tex.magFilter = THREE.LinearFilter;
  tex.mapping   = THREE.EquirectangularReflectionMapping;
  return tex;
}
scene.background = bakeSkyGradient();
scene.fog = new THREE.Fog(fogColor, 40, 130);

// === Day / night cycle =====================================================
// world.timeOfDay is a 0..1 phase: 0 = midnight, 0.25 = dawn, 0.5 = noon,
// 0.75 = dusk. One real-world minute = ~10% of a game day, so a full
// day completes in ~10 minutes — slow enough to feel atmospheric, fast
// enough to actually see.
const DAY_LENGTH_SEC = 600;          // 10 min real per game day
const _todPalette = {
  // [zenith, mid, horizon, sunColor, sunIntensity, hemiSky, hemiGround, hemiInt, ambInt, fogColor]
  // Night intensities raised from playtest: the village was unplayably
  // dark through the dusk→midnight transition. Keeping the blue/violet
  // hue (so it still reads as night) but floored so silhouettes stay
  // legible. Was sun=0.10 hemi=0.18 amb=0.04 → now sun=0.30 hemi=0.42 amb=0.14.
  midnight: ['#0a1226','#101a3a','#0e1535','#8aa4d4',0.30,'#3a4a78','#1a1a28',0.42,0.14,'#0e1535'],
  dawn:     ['#3a4a78','#a86a5a','#f1c499','#ffb074',0.55,'#a8c0e8','#5a4a3a',0.45,0.08,'#f1c499'],
  noon:     ['#4d7fbf','#85a8cf','#c5d6df','#fff3d8',1.40,'#a0d8ff','#4a5a3a',0.60,0.12,'#c5d6df'],
  // Dusk also bumped so the evening reads as "soft amber" instead of
  // "hand-over-eyes squint" — the transition into night is gentler.
  dusk:     ['#3e4a8a','#c46680','#fda080','#ff9460',0.70,'#b08cc8','#5a3a3a',0.50,0.10,'#fda080'],
};
const _todStops = [
  [0.00, 'midnight'], [0.20, 'midnight'], [0.30, 'dawn'],
  [0.50, 'noon'], [0.70, 'noon'], [0.80, 'dusk'], [0.95, 'midnight'], [1.00, 'midnight'],
];
function _lerpHex(a, b, t) {
  const ah = parseInt(a.slice(1), 16), bh = parseInt(b.slice(1), 16);
  const ar = (ah >> 16) & 0xff, ag = (ah >> 8) & 0xff, ab = ah & 0xff;
  const br = (bh >> 16) & 0xff, bg = (bh >> 8) & 0xff, bb = bh & 0xff;
  const r = Math.round(ar + (br - ar) * t);
  const g = Math.round(ag + (bg - ag) * t);
  const bl = Math.round(ab + (bb - ab) * t);
  return '#' + ((r << 16) | (g << 8) | bl).toString(16).padStart(6, '0');
}
function _lerpNum(a, b, t) { return a + (b - a) * t; }
function _palAt(tod) {
  for (let i = 0; i < _todStops.length - 1; i++) {
    const [t0, k0] = _todStops[i];
    const [t1, k1] = _todStops[i + 1];
    if (tod >= t0 && tod <= t1) {
      const a = _todPalette[k0], b = _todPalette[k1];
      const f = (tod - t0) / Math.max(0.001, t1 - t0);
      return [
        _lerpHex(a[0], b[0], f), _lerpHex(a[1], b[1], f), _lerpHex(a[2], b[2], f),
        _lerpHex(a[3], b[3], f), _lerpNum(a[4], b[4], f),
        _lerpHex(a[5], b[5], f), _lerpHex(a[6], b[6], f), _lerpNum(a[7], b[7], f),
        _lerpNum(a[8], b[8], f), _lerpHex(a[9], b[9], f),
      ];
    }
  }
  return _todPalette.noon;
}
function _bakeSkyAt(zenith, mid, horizon) {
  const c = document.createElement('canvas'); c.width = 1; c.height = 256;
  const cx = c.getContext('2d');
  const g = cx.createLinearGradient(0, 0, 0, 256);
  g.addColorStop(0, zenith); g.addColorStop(0.55, mid);
  g.addColorStop(0.9, horizon); g.addColorStop(1, horizon);
  cx.fillStyle = g; cx.fillRect(0, 0, 1, 256);
  const tex = new THREE.CanvasTexture(c);
  tex.colorSpace = THREE.SRGBColorSpace;
  tex.minFilter = THREE.LinearFilter; tex.magFilter = THREE.LinearFilter;
  tex.mapping = THREE.EquirectangularReflectionMapping;
  return tex;
}
let _todLastSky = -1;   // refresh sky texture only every ~10° of phase
function updateDayNight(dt) {
  if (typeof world.timeOfDay !== 'number') world.timeOfDay = 0.5;
  world.timeOfDay = (world.timeOfDay + dt / DAY_LENGTH_SEC) % 1;
  const tod = world.timeOfDay;
  const p = _palAt(tod);
  // Sun position via spherical interpolation: sun rises at tod=0.25, sets at tod=0.75
  const sunAng = (tod - 0.25) * Math.PI * 2;   // -π/2 at midnight, 0 at sunrise, π/2 at noon, π at sunset
  sunPosVec.set(Math.cos(sunAng + Math.PI / 2) * 0.6, Math.max(0.05, Math.sin(sunAng)), Math.sin(sunAng + Math.PI / 2) * 0.6);
  sunPosVec.normalize();
  // Apply colors / intensities
  sun.color.set(p[3]);
  sun.intensity = p[4];
  hemiLight.color.set(p[5]);
  hemiLight.groundColor.set(p[6]);
  hemiLight.intensity = p[7];
  ambLight.intensity = p[8];
  scene.fog.color.set(p[9]);
  // Day/night-responsive ambient: brightness 0..1 = night..noon. Use the
  // hemi intensity (range ~0.18..0.60) as a proxy.
  sfx.setAmbientBrightness((p[7] - 0.18) / (0.60 - 0.18));
  // Sky texture re-bake is expensive; do it every 0.01 phase tick (~6 sec at 10min/day)
  if (Math.abs(tod - _todLastSky) > 0.01 || _todLastSky < 0) {
    _todLastSky = tod;
    const newSky = _bakeSkyAt(p[0], p[1], p[2]);
    const old = scene.background;
    scene.background = newSky;
    if (old?.dispose) old.dispose();
  }
}

// Per-zone ambient swap. Inside a dungeon the dungeon enter/exit hooks own
// the drone; on the surface we pick by what the player is standing near —
// the forge brightens the drone, the village core hums warm, and beyond
// 10 tiles the air opens up to "wilds". startAmbient() is idempotent for
// the same kind, so we can call each frame without thrashing the graph.
function _zoneFor(px, py) {
  const fp = world.firePos;
  if (fp) {
    const fdx = px - fp.x, fdy = py - fp.y;
    if (fdx * fdx + fdy * fdy < 9) return 'forge';   // within ~3 tiles of the forge
  }
  const dx = px - world.spawn.x, dy = py - world.spawn.y;
  return (dx * dx + dy * dy) < (10 * 10) ? 'village' : 'wilds';
}
function updateZoneAmbient() {
  if (dungeon.active) return;
  sfx.startAmbient(_zoneFor(player.x, player.y));
}

const camera = createCamera(W / H);

// lighting — sky-tinted hemisphere fill + warm directional sun
const hemiLight = new THREE.HemisphereLight(0xa0d8ff, 0x4a5a3a, 0.6);
scene.add(hemiLight);
const ambLight = new THREE.AmbientLight(0xffffff, 0.12);
scene.add(ambLight);
const sun = new THREE.DirectionalLight(0xfff3d8, 1.4);
sun.position.copy(sunPosVec).multiplyScalar(40);
sun.castShadow = true;
sun.shadow.mapSize.set(2048, 2048);
sun.shadow.bias = -0.0005;
sun.shadow.normalBias = 0.04;
sun.shadow.radius = 2.5;
const SHADOW_HALF = 35;
const cam = sun.shadow.camera;
cam.left = -SHADOW_HALF;  cam.right = SHADOW_HALF;
cam.top  =  SHADOW_HALF;  cam.bottom = -SHADOW_HALF;
cam.near = 1;             cam.far    = 120;
cam.updateProjectionMatrix();
scene.add(sun);
// follow target so shadow map travels with the player
const sunTarget = new THREE.Object3D();
scene.add(sunTarget);
sun.target = sunTarget;

// ---------- WORLD ----------
const mapText = await fetch('src/data/map.txt').then(r => r.text());

// Preload all GLBs before constructing the world / spawning entities. Trees
// and cook are placed at world-construction / spawn time, so their GLBs need
// to be in cache by then or the procedural fallbacks render instead.
// Import v2 goblin loader (declared but not in main's import block by default)
const { loadGoblinV2GLB } = await import('./scene/characters.js');

await Promise.all([
  loadKnightBase(),
  loadAllArchetypes(),
  loadGoblinV2GLB(),
  loadEquipment('helmet_centurion'),
  loadEquipment('breastplate_olive'),
  loadEquipment('pauldrons_gold'),
  loadEquipment('belt_leather'),
  loadEquipment('tunic_skirt_cream'),
  loadEquipment('boots_brown'),
  loadEquipment('sword_short'),
  loadEquipment('shield_laurel'),
  loadEquipment('cape_red'),
  loadGoblinGLB(),
  loadBrambleImpGLB(),
  loadHedgewightGLB(),
  loadChartmakerStoneGLB(),
  loadBurrowBoarGLB(),
  loadWolfAlphaGLB(),
  loadHodGLB(),
  loadMaudGLB(),
  loadQuillGLB(),
  loadWitheringGLB(),
  loadApprenticesHammerGLB(),
  loadHealingDraughtGLB(),
  loadFalconsWhistleGLB(),
  loadBrambleResinGLB(),
  loadWhickerharesFootGLB(),
  loadThornCrownGLB(),
  loadPantryStewGLB(),
  loadHodsAnvilTokenGLB(),
  loadWitheredBrambleGLB(),
  loadPracticeDummyGLB(),
  loadMemorialLanternGLB(),
  loadDryingRackGLB(),
  loadFalconerPerchGLB(),
  loadCookGLB(),
  loadOakGLB(),
  loadCastleGLB(),
  loadForgeGLB(),
  loadCottageGLB(),
  loadWellGLB(),
  loadBankGLB(),
  loadSignpostGLB(),
  loadChickenGLB(),
  loadHareGLB(),
  loadBoarGLB(),
  loadHedgemotherGLB(),
  loadSkitterlingGLB(),
  loadMarshRatGLB(),
  loadIronGobGLB(),
  loadTuskerSowGLB(),
  loadBrambleArcherGLB(),
  loadBrambleChargerGLB(),
  loadEldraGLB(),
  loadCricketGLB(),
  loadPellGLB(),
  loadOnywynGLB(),
  loadTier3ItemGLBs(),
]);

// ---------- CHARACTER CREATION ----------
// Skip the creator if an existing save has already chosen an appearance.
const SAVE_KEY = 'gj26.save';
let charData = null;
try { charData = JSON.parse(localStorage.getItem(SAVE_KEY) || 'null'); } catch {}
if (!charData?.name) {
  charData = await showCharCreator();
  // If the player ticked "Skip tutorial" in the creator, preload every
  // step ID into the localStorage onboard set so advanceTutorial() and
  // the welcome timer below all short-circuit on first eligibility check.
  if (charData?.skipTutorial) {
    try {
      const ids = ['welcome', 'walk', 'cleave', 'kill', 'eat', 'npc', 'chart'];
      const existing = JSON.parse(localStorage.getItem('gj26.onboard') || '[]');
      const merged = Array.from(new Set([...existing, ...ids]));
      localStorage.setItem('gj26.onboard', JSON.stringify(merged));
    } catch {}
  }
  try { localStorage.setItem(SAVE_KEY, JSON.stringify(charData)); } catch {}
}

const world = new World(mapText, scene);
world.timeOfDay = 0.45;   // start a touch before noon so first session reads as day
// Expose tile-type lookup for surface-aware footsteps. Player module
// reads this through window.* so it stays decoupled from world.
window.__gj26_surfaceUnder = (x, y) => world.tileGrid?.[y]?.[x] || 'grass';

// Resolve archetype: explicit charData.archetype wins; otherwise infer
// from the preset name (Knight/Druid/Bard/Wanderer); fall back to Knight.
const _archetype = charData.archetype || charData.preset || 'Knight';
const player = createPlayer(world.spawn.x, world.spawn.y, _archetype);
player.name = charData.name;
player.appearance = charData.appearance;
player.archetype  = _archetype;
scene.add(player.mesh);

// Debug: expose for browser console testing.
window.__game = { world, player, scene, camera, renderer };
// Expose enterDungeon for the dev console (defined later in this file —
// installDevConsole reads from window.__game.enterDungeon at button-click time).
setTimeout(() => {
  window.__game.enterDungeon = enterDungeon;
  window.__game.enterAuthoredDungeon = enterAuthoredDungeon;
  // Orb-forge handlers — dev-console accessible until a Plinth UI ships.
  // listForgeableOrbs() returns recipe ids the player can run right now.
  // forgeOrb(id) consumes inputs and produces a rolled orb in inventory.
  window.__game.forgeOrb = tryForgeOrb;
  window.__game.canForgeOrb = canForgeOrb;
  window.__game.listForgeableOrbs = listForgeableOrbs;
}, 0);

/** Drop into a hand-authored dungeon. The JSON shape comes from
 *  editor.html's export. Reads `json.procgen` (Stage A: tier / rune /
 *  seed / affixIds) so the editor can drive every existing procgen lever
 *  through the same bridge. Dispatches on `json.mode`:
 *    - 'authored' (default): play exactly what the editor painted
 *    - 'scaffold': use painted rooms as scaffold; procgen connects + fills */
function enterAuthoredDungeon(json, tier = null) {
  const pg = (json && json.procgen) || {};
  const useTier      = tier ?? (+pg.tier || 1);
  const runeEffect   = pg.runeEffect || null;
  const affixes      = Array.isArray(pg.affixIds)
    ? pg.affixIds.map(id => ({ id, good: true, resolvedId: id }))
    : [];
  const layout = json?.mode === 'scaffold'
    ? loadScaffoldLayout(json, useTier, affixes)
    : loadAuthoredLayout(json, affixes);
  enterDungeon(useTier, affixes, runeEffect, layout.scope, layout);
  log('quest', `★ Entered authored level: ${layout.authoredName} `
            + `(tier ${useTier}${runeEffect ? `, rune ${runeEffect}` : ''}${affixes.length ? `, ${affixes.length} affix${affixes.length === 1 ? '' : 'es'}` : ''})`);
}

// Per-tile trap dispatcher. Spike traps deal 3 damage and remove
// themselves from layout.traps + the scene; bramble traps deal 1 and
// stay (tile becomes a persistent hazard). Both fire sfx.hit() — that's
// already a noiseBurst + thump combo and reads as "ouch" in-game.
function _checkTrapAt(tx, ty) {
  if (!dungeon.active || !dungeon.layout) return;
  const traps = dungeon.layout.traps;
  if (!traps || !traps.length) return;
  const idx = traps.findIndex(t => t.x === tx && t.y === ty);
  if (idx < 0) return;
  const t = traps[idx];
  const dmg = t.kind === 'spike' ? 3 : 1;
  damagePlayer(player, dmg, log, 'trap');
  import('./core/sfx.js').then(m => m.sfx.hit());
  if (t.kind === 'spike') {
    // One-shot consume — drop the entry and hide the prop in the scene.
    traps.splice(idx, 1);
    if (dungeon.group) {
      const dead = dungeon.group.children.find(c =>
        c.userData?.trap && c.userData.trap === t);
      if (dead) dungeon.group.remove(dead);
    }
  }
}

// Try to open a locked door — consume the matching key from inventory,
// flip door.locked=false, slide the panel mesh aside. If already open,
// just no-op. Color → key map mirrors the items.js entries.
const _DOOR_KEY = { iron: 'iron_key', gold: 'gold_key', thorn: 'thorn_key' };
function _tryOpenDoor(door) {
  if (door.locked === false) {
    log('hint', 'The door is already open.');
    return;
  }
  const keyId = _DOOR_KEY[door.color] || _DOOR_KEY.iron;
  const have = player.inventory.count(keyId);
  if (have <= 0) {
    log('hint', `Locked. You need ${ITEMS[keyId]?.name || keyId}.`);
    import('./core/sfx.js').then(m => m.sfx.miss());
    return;
  }
  player.inventory.remove(keyId, 1);
  door.locked = false;
  // Find + update the door's group in the scene so the panel slides
  // aside without a full rebuild. Children are tagged with userData.role
  // at build time so we can find the panel + lock without geometry
  // sniffing.
  if (dungeon.group) {
    const g = dungeon.group.children.find(c => c.userData?.door === door);
    if (g) {
      const panel = g.children.find(c => c.userData?.role === 'panel');
      if (panel) panel.position.x = -0.55;
      const lock = g.children.find(c => c.userData?.role === 'lock');
      if (lock) lock.visible = false;
    }
  }
  log('quest', `★ Unlocked the ${door.color} door.`);
  renderInv();
  import('./core/sfx.js').then(m => m.sfx.parry());
}

/** Player stepped onto a staircase tile. Look up the linked layout in the
 *  editor's library and swap floors in place. */
function tryTakeStaircase(sc) {
  const targetName = sc.target;
  if (!targetName) {
    log('hint', 'A staircase, but the carving on the riser is unreadable.');
    return;
  }
  let lib = {};
  try {
    const raw = localStorage.getItem('gj26.dungeon_library');
    if (raw) lib = JSON.parse(raw) || {};
  } catch (_) {}
  const rec = lib[targetName];
  if (!rec || !rec.json) {
    log('hint', `The riser reads "${targetName}" — but no such layout is saved.`);
    return;
  }
  log('quest', `★ Down the staircase to ${targetName}…`);
  swapAuthoredFloor(rec.json);
}

/** Tear down the current authored floor and replace it with a new one.
 *  Preserves the overworld-hidden state so the player stays inside the
 *  dungeon system across floor transitions. */
function swapAuthoredFloor(json) {
  if (!dungeon.active) {                        // first time? just enter normally
    enterAuthoredDungeon(json);
    return;
  }
  resetWindupTokens();
  const savedHiddenWorld = dungeon.hiddenWorld;  // keep so exit-to-village still works
  // Despawn dungeon-only enemies + ground state for the floor we're leaving.
  for (const e of dungeon.enemies) {
    const i = enemies.indexOf(e);
    if (i >= 0) enemies.splice(i, 1);
    if (e.mesh)  scene.remove(e.mesh);
    if (e.hpBar) scene.remove(e.hpBar);
  }
  dungeon.enemies = [];
  clearGroundLoot(scene);
  clearShimmers();
  if (dungeon.group) scene.remove(dungeon.group);
  dungeon.group = null;
  // Mark inactive so enterAuthoredDungeon's "hide overworld" pass is a no-op
  // on already-hidden children (it would otherwise discover an empty list and
  // overwrite our saved one).
  dungeon.active = false;
  enterAuthoredDungeon(json);
  dungeon.hiddenWorld = savedHiddenWorld;
}

// Boot hook: if URL is index.html#authored and localStorage has a stored
// layout, drop into it after world init. Editor's "Test in game" writes
// the JSON to that key and opens the URL.
function _maybeEnterAuthoredOnBoot() {
  if (!location.hash.includes('authored')) return;
  let raw = null;
  try { raw = localStorage.getItem('gj26.authored_dungeon'); } catch (_) {}
  if (!raw) return;
  let json;
  try { json = JSON.parse(raw); }
  catch (e) { console.warn('Authored dungeon parse error:', e); return; }
  // Wait one frame so the world is fully wired (player mesh, scene, etc.)
  setTimeout(() => enterAuthoredDungeon(json), 50);
}
setTimeout(_maybeEnterAuthoredOnBoot, 100);

// Slot-key remapping power-user API.
//   __game.setSlotKey(5, 'q')   — bind slot 5 to Q
//   __game.getSlotKey(5)        — read the current key
import('./core/input.js').then(m => {
  window.__game.setSlotKey = m.setSlotKey;
  window.__game.getSlotKey = m.getSlotKey;
});

// Wayfinding persistence — flush exploredTiles + waypoints to localStorage
// on a 1.5s debounce so frequent walks don't thrash storage.
let _saveExploredT = null;
function queueExploredSave() {
  if (_saveExploredT) return;
  _saveExploredT = setTimeout(() => {
    _saveExploredT = null;
    try {
      localStorage.setItem('gj26.explored',  JSON.stringify(Array.from(player.exploredTiles)));
      localStorage.setItem('gj26.waypoints', JSON.stringify(player.waypoints || []));
    } catch (_) { /* quota / private mode — ignore */ }
  }, 1500);
}
window.addEventListener('beforeunload', () => {
  try {
    localStorage.setItem('gj26.explored',  JSON.stringify(Array.from(player.exploredTiles)));
    localStorage.setItem('gj26.waypoints', JSON.stringify(player.waypoints || []));
  } catch (_) {}
});

// Starter tools so the new gathering skills are usable from spawn.
player.inventory.add('brindle_axe', 1);
player.inventory.add('brindle_pickaxe', 1);
player.inventory.add('fishing_rod', 1);
// Starter blank charts — fast-travel currency once Wayfinding 15 is reached.
player.inventory.add('chart_blank', 5);
// Wayfinding Phase A starters — every cartographer's kit
player.inventory.add('field_journal', 1);
player.inventory.add('surveyors_pole', 5);
player.inventory.add('vellum', 5);
player.inventory.add('charcoal_stick', 10);

// ---------- SAVE STATE ----------
// Restore skills / inventory / quest / position / hp / discovered tiles
// from localStorage if present. Char appearance was already applied above.
const _savedState = readSave();
if (_savedState) applySave(_savedState, player, world);
// Wayfinding v2 bootstrap — top up starter blank charts on existing saves
// so returning players still get the fast-travel onboard.
if (player.inventory.count('chart_blank') === 0) {
  player.inventory.add('chart_blank', 5);
}
// Phase A bootstrap — sketch verb tools for returning players
if (player.inventory.count('field_journal') === 0) {
  player.inventory.add('field_journal', 1);
  player.inventory.add('surveyors_pole', 5);
  player.inventory.add('vellum', 5);
  player.inventory.add('charcoal_stick', 10);
}
// Phase 1 (Inscribing Table) bootstrap — restore known recipes from save
loadKnownRecipes(player);
ensureAtlasLoaded(player);
// Starter ingredients so a brand-new player can craft Hedge Ink immediately
if (player.inventory.count('wild_herb') === 0) {
  player.inventory.add('wild_herb', 5);
  player.inventory.add('ore_dust', 3);
  player.inventory.add('pond_water', 3);
}
// Rune Magic Phase A — starter runes so the player can test Wind Strike (R).
// 5 air + 5 mind = 5 casts. Once spent, runes must be pressed at the
// pedestal (not yet implemented — Phase B).
if (player.inventory.count('rune_air') === 0) {
  player.inventory.add('rune_air', 5);
  player.inventory.add('rune_mind', 5);
  player.inventory.add('rune_stone', 3);
}
// Persist on tab close (ensures the most recent state lands)
window.addEventListener('beforeunload', () => writeSave(player, world));

// Browsers gate Web Audio behind a user gesture; resume + kick off village
// ambient on the first click (dungeon ambient swaps in on dungeon enter).
window.addEventListener('click', () => {
  sfx.resume();
  if (!dungeon.active) sfx.startAmbient('village');
}, { once: true });

// ---------- KEYBIND HINTS ----------
// Controls overlay: starts closed so it doesn't overlap the Adventurer
// panel on the right rail. The persistent "?" button reveals it; the ×
// inside dismisses it. No auto-show flash.
{
  const hints = document.getElementById('hints');
  const hide  = document.getElementById('hints-close');
  const show  = document.getElementById('hints-show');

  function setOpen(open) {
    hints.classList.toggle('open', open);
    show.classList.toggle('open', !open);
  }
  hide?.addEventListener('click', () => setOpen(false));
  show?.addEventListener('click', () => setOpen(true));
}

// ---------- HUD TOOLS (Bag / Skills / Quest popups) ----------
// Toggles the legacy #panel as a slide-in popup overlay anchored to the
// right side of the stage. Each button scrolls the panel to its section
// header, so the player lands at the right view immediately.
{
  const bagBtn    = document.getElementById('tool-bag');
  const skillsBtn = document.getElementById('tool-skills');
  const questBtn  = document.getElementById('tool-quest');
  const panel     = document.getElementById('panel');
  let openSection = null;   // 'inventory' | 'skills' | 'quest' | null

  function syncBtns() {
    bagBtn?.classList.toggle('active',    openSection === 'inventory');
    skillsBtn?.classList.toggle('active', openSection === 'skills');
    questBtn?.classList.toggle('active',  openSection === 'quest');
    document.body.classList.toggle('hud-panel-open', !!openSection);
  }
  function scrollTo(section) {
    if (!panel) return;
    let target = null;
    if (section === 'inventory') target = document.getElementById('inv');
    else if (section === 'skills') target = document.getElementById('skills');
    else if (section === 'quest') target = document.getElementById('quest');
    target?.scrollIntoView({ block: 'start', behavior: 'smooth' });
  }
  function setSection(next) {
    openSection = (openSection === next) ? null : next;
    syncBtns();
    if (openSection) scrollTo(openSection);
  }
  bagBtn?.addEventListener('click',    () => setSection('inventory'));
  skillsBtn?.addEventListener('click', () => setSection('skills'));
  questBtn?.addEventListener('click',  () => setSection('quest'));

  // Hotkeys — B / K / J. Skip when typing in any input or while a modal is up.
  window.addEventListener('keydown', e => {
    const tag = (e.target?.tagName || '').toLowerCase();
    if (tag === 'input' || tag === 'textarea') return;
    if (document.querySelector('#dialog-backdrop.open')) return;
    const k = e.key.toLowerCase();
    if (k === 'b') setSection('inventory');
    else if (k === 'k') setSection('skills');
    else if (k === 'j') setSection('quest');
    else if (k === 'escape' && openSection) { openSection = null; syncBtns(); }
  });

  // Click utility slots 5 (quaff) and 8 (bag). Slots 1-4 are abilities
  // and are dispatched by the keyboard hotkey path elsewhere.
  document.getElementById('skillbar')?.addEventListener('click', e => {
    const slot = e.target.closest('.sb-slot[data-slot]');
    if (!slot || !slot.classList.contains('sb-utility')) return;
    const num = +slot.dataset.slot;
    if (num === 5 && typeof tryQuaffPotion === 'function') tryQuaffPotion();
    else if (num === 8) setSection('inventory');
  });

  // World Map (Wayfinding) — M / map button
  const mapBtn = document.getElementById('tool-map');
  const mapClose = document.getElementById('wm-close');
  function buildLandmarks() {
    const out = [];
    if (world.firePos)    out.push({ x: world.firePos.x,    y: world.firePos.y,    name: 'Hearth' });
    if (world.cookSpawn)  out.push({ x: world.cookSpawn.x,  y: world.cookSpawn.y,  name: 'Cook' });
    if (typeof HOD_TILE !== 'undefined')         out.push({ x: HOD_TILE.x,         y: HOD_TILE.y,         name: 'Hod the Smith' });
    if (typeof HERBALIST_TILE !== 'undefined')   out.push({ x: HERBALIST_TILE.x,   y: HERBALIST_TILE.y,   name: 'Quill the Herbalist' });
    if (typeof WITHERING_TILE !== 'undefined')   out.push({ x: WITHERING_TILE.x,   y: WITHERING_TILE.y,   name: 'Sir Withering' });
    if (typeof CHARTMAKER_TILE !== 'undefined')  out.push({ x: CHARTMAKER_TILE.x,  y: CHARTMAKER_TILE.y,  name: "Chartmaker's Stone" });
    if (typeof MIRROR_TILE !== 'undefined')      out.push({ x: MIRROR_TILE.x,      y: MIRROR_TILE.y,      name: 'Looking Glass' });
    return out;
  }
  function tryFastTravel(target) {
    const cartoLv = player.skills.carto?.lv || 1;
    if (cartoLv < 15) {
      log('hint', "You'll need Wayfinding 15 to walk a chart's lines.");
      return false;
    }
    // Free travel at Lv 99; otherwise consume one chart_blank.
    if (cartoLv < 99) {
      if (!player.inventory.count('chart_blank') || player.inventory.count('chart_blank') < 1) {
        log('hint', 'No blank chart in your bag. Find or craft one to travel.');
        return false;
      }
      player.inventory.remove('chart_blank', 1);
      renderInv();
    }
    // Place the player on the target tile (next to it if blocked).
    let tx = target.x, ty = target.y;
    if (world.isTerrainBlocked(tx, ty)) {
      // Try adjacent tiles
      const tries = [[1,0],[-1,0],[0,1],[0,-1],[1,1],[-1,1],[1,-1],[-1,-1]];
      for (const [dx, dy] of tries) {
        if (!world.isTerrainBlocked(tx + dx, ty + dy)) { tx += dx; ty += dy; break; }
      }
    }
    player.x = tx; player.y = ty;
    player.targetX = tx; player.targetY = ty;
    player.pos.x = tx + 0.5;
    player.pos.z = ty + 0.5;
    player.moving = false; player.path = [];
    log('skill', `🗺  Fast-traveled to ${target.name}.`);
    return true;
  }
  function toggleMap() {
    if (isWorldMapOpen()) closeWorldMap();
    else showWorldMap({
      player, world,
      landmarks: buildLandmarks(),
      enemies,
      onTravel: tryFastTravel,
      onWaypointsChanged: queueExploredSave,
      log,
    });
  }
  mapBtn?.addEventListener('click', toggleMap);
  mapClose?.addEventListener('click', closeWorldMap);
  document.getElementById('world-map-backdrop')?.addEventListener('click', e => {
    if (e.target.id === 'world-map-backdrop') closeWorldMap();
  });
  window.addEventListener('keydown', e => {
    const tag = (e.target?.tagName || '').toLowerCase();
    if (tag === 'input' || tag === 'textarea') return;
    if (document.querySelector('#dialog-backdrop.open')) return;
    const k = e.key.toLowerCase();
    if (k === 'm') toggleMap();
    else if (k === 'escape' && isWorldMapOpen()) closeWorldMap();
  });

  // Wayfinding Workshop — 5th tool button. Opens the unified workshop;
  // the workshop's own buttons launch Inscribing Table / Pedestal /
  // Charting / Field Journal. C toggles. Same Esc-stack handler picks
  // it up below.
  const cartoBtn = document.getElementById('tool-carto');
  function toggleCartoWorkshop() {
    if (isWayfindingWorkshopOpen()) closeWayfindingWorkshop();
    else openWayfindingWorkshop();
  }
  cartoBtn?.addEventListener('click', toggleCartoWorkshop);
  window.addEventListener('keydown', e => {
    const tag = (e.target?.tagName || '').toLowerCase();
    if (tag === 'input' || tag === 'textarea') return;
    if (document.querySelector('#dialog-backdrop.open')) return;
    if (e.key.toLowerCase() === 'c') toggleCartoWorkshop();
  });

  // Modal breadcrumbs — when a sub-modal launched from the workshop closes,
  // reopen the workshop. We watch each backdrop for the .open class going
  // away; if the workshop's _state is still alive (it wasn't dismissed
  // itself), bring the workshop back forward. Cheap MutationObserver per
  // backdrop avoids modifying any of the sub-modules' close paths.
  const _breadcrumbTargets = [
    'inscribing-table-backdrop',
    'pedestal-backdrop',
    'charting-backdrop',
    'field-journal-backdrop',
    'atlas-map-backdrop',
    'materials-browser-backdrop',
  ];
  for (const id of _breadcrumbTargets) {
    const el = document.getElementById(id);
    if (!el) continue;
    let wasOpen = el.classList.contains('open');
    new MutationObserver(() => {
      const nowOpen = el.classList.contains('open');
      if (wasOpen && !nowOpen) reopenWayfindingWorkshop();
      wasOpen = nowOpen;
    }).observe(el, { attributes: true, attributeFilter: ['class'] });
  }

  // Field Journal — 6th tool button + Esc-close. Note: 'N' is the
  // sketch verb (handled in the loop), not an open shortcut. The
  // journal opens via the button or the F key.
  const journalBtn = document.getElementById('tool-journal');
  const journalClose = document.getElementById('fj-close');
  function toggleJournal() {
    if (isFieldJournalOpen()) closeFieldJournal();
    else showFieldJournal(player);
  }
  journalBtn?.addEventListener('click', toggleJournal);
  journalClose?.addEventListener('click', closeFieldJournal);
  document.getElementById('field-journal-backdrop')?.addEventListener('click', e => {
    if (e.target.id === 'field-journal-backdrop') closeFieldJournal();
  });
  window.addEventListener('keydown', e => {
    const tag = (e.target?.tagName || '').toLowerCase();
    if (tag === 'input' || tag === 'textarea') return;
    if (document.querySelector('#dialog-backdrop.open')) return;
    const k = e.key.toLowerCase();
    if (k === 'f') toggleJournal();
    else if (k === 'escape' && isFieldJournalOpen()) closeFieldJournal();
  });

  // Inscribing Table — modal lifecycle only; the module self-binds its
  // own grid / ingredient / inscribe / tab handlers.
  document.getElementById('it-close')?.addEventListener('click', closeInscribingTable);
  document.getElementById('inscribing-table-backdrop')?.addEventListener('click', e => {
    if (e.target.id === 'inscribing-table-backdrop') closeInscribingTable();
  });
  window.addEventListener('keydown', e => {
    if (e.key === 'Escape' && isInscribingTableOpen()) closeInscribingTable();
  });

  // Spellbook (V) + Pedestal (Esc handlers)
  window.addEventListener('keydown', e => {
    const tag = (e.target?.tagName || '').toLowerCase();
    if (tag === 'input' || tag === 'textarea') return;
    if (document.querySelector('#dialog-backdrop.open')) return;
    const k = e.key.toLowerCase();
    if (k === 'v') {
      if (isSpellbookOpen()) closeSpellbook();
      else showSpellbook(player);
    } else if (k === 'escape') {
      if (isSpellbookOpen()) closeSpellbook();
      if (isPedestalOpen()) closePedestal();
    }
  });

  // Restore active spell from save
  try {
    const saved = localStorage.getItem('gj26.activeSpell');
    if (saved) player.activeSpell = saved;
  } catch (_) {}
  player.activeSpell ||= 'wind_strike';
}

// ---------- UNIFIED ESCAPE STACK ----------
// Single source of truth for "what does Escape do." Walks the priority
// stack and closes ONLY the topmost open surface. Distinct individual
// Escape handlers in modal init blocks still exist (idempotent — calling
// closeFoo when foo is already closed is a no-op), but this one
// guarantees the lab-nav and any future modal also dismiss cleanly.
//
// Priority order = visual stack order. Right-click menu is always on top
// (it's positioned over whatever's beneath); spellbook + pedestal are
// peers; the rest are background panels.
window.addEventListener('keydown', (e) => {
  if (e.key !== 'Escape') return;
  const ctxMenuEl = document.getElementById('ctx-menu');
  const labNav    = document.getElementById('lab-nav');
  // 1. Right-click verb menu (highest visual layer)
  if (ctxMenuEl?.style.display === 'block') {
    e.preventDefault(); hideContextMenu(); return;
  }
  // 2. Modal-class popups. Wayfinding Workshop sits below the sub-modals
  // (you can have the workshop "behind" an opened pedestal); Esc dismisses
  // the front-most modal first, then the workshop on the next press.
  if (isSpellbookOpen())        { e.preventDefault(); closeSpellbook(); return; }
  if (isPedestalOpen())         { e.preventDefault(); closePedestal();  return; }
  if (isInscribingTableOpen())  { e.preventDefault(); closeInscribingTable(); return; }
  if (isAtlasMapOpen())         { e.preventDefault(); closeAtlasMap();  return; }
  if (isMaterialsBrowserOpen()) { e.preventDefault(); closeMaterialsBrowser(); return; }
  if (isWayfindingWorkshopOpen()) { e.preventDefault(); closeWayfindingWorkshop(); return; }
  // 3. Lab-nav hamburger (lower priority — small, dismissible)
  if (labNav?.classList.contains('open')) {
    e.preventDefault(); labNav.classList.remove('open'); return;
  }
  // 4. (settings + map + journal still listen for Escape themselves —
  //    leave them for now; they'll catch via their own handlers)
});

// ---------- SETTINGS ----------
// Volume slider persists via setMasterVolume → localStorage. Backdrop click
// + Escape both close the panel.
{
  const backdrop = document.getElementById('settings-backdrop');
  const btn      = document.getElementById('settings-btn');
  const closeBtn = document.getElementById('settings-close');
  const slider   = document.getElementById('settings-volume');
  const num      = document.getElementById('settings-volume-num');
  if (backdrop && btn && slider) {
    const sync = () => {
      const v = getMasterVolume();
      slider.value = String(v);
      if (num) num.textContent = Math.round(v * 100) + '%';
    };
    sync();
    btn.addEventListener('click', () => {
      sync();
      backdrop.classList.add('open');
    });
    closeBtn?.addEventListener('click', () => backdrop.classList.remove('open'));
    backdrop.addEventListener('click', (e) => {
      if (e.target === backdrop) backdrop.classList.remove('open');
    });
    window.addEventListener('keydown', (e) => {
      if (e.key === 'Escape' && backdrop.classList.contains('open')) {
        backdrop.classList.remove('open');
        e.stopPropagation();
      }
    });
    slider.addEventListener('input', () => {
      const v = parseFloat(slider.value);
      setMasterVolume(v);
      if (num) num.textContent = Math.round(v * 100) + '%';
    });
    // Bonus: pressing the gear button auto-resumes the audio context so
    // the user hears their slider changes immediately.
    btn.addEventListener('click', () => sfx.resume());
  }
  // ---- Camera + Display preferences ----
  // All persist to localStorage. Read once at boot; any future sliders /
  // checkboxes added to the modal can mirror this same pattern.
  const PREFS_KEY = 'gj26.prefs';
  const prefs = (() => {
    try {
      const raw = localStorage.getItem(PREFS_KEY);
      return raw ? JSON.parse(raw) : {};
    } catch { return {}; }
  })();
  prefs.camYaw   ??= 1.0;
  prefs.camInvert ??= false;
  prefs.showFps  ??= false;
  prefs.showFloaters ??= true;
  window.__gj26_prefs = prefs;
  function savePrefs() {
    try { localStorage.setItem(PREFS_KEY, JSON.stringify(prefs)); } catch {}
  }
  // Apply pref-driven CSS / runtime state.
  function applyDisplayPrefs() {
    const fps = document.getElementById('fps');
    if (fps) fps.style.display = prefs.showFps ? '' : 'none';
    const floaters = document.getElementById('floaters');
    if (floaters) floaters.style.display = prefs.showFloaters ? '' : 'none';
  }
  applyDisplayPrefs();

  const sens   = document.getElementById('settings-cam-sens');
  const sensN  = document.getElementById('settings-cam-sens-num');
  const inv    = document.getElementById('settings-cam-invert');
  const fps    = document.getElementById('settings-show-fps');
  const flo    = document.getElementById('settings-show-floaters');
  if (sens) {
    sens.value = String(prefs.camYaw);
    if (sensN) sensN.textContent = Math.round(prefs.camYaw * 100) + '%';
    sens.addEventListener('input', () => {
      prefs.camYaw = parseFloat(sens.value);
      if (sensN) sensN.textContent = Math.round(prefs.camYaw * 100) + '%';
      savePrefs();
    });
  }
  if (inv) {
    inv.checked = !!prefs.camInvert;
    inv.addEventListener('change', () => { prefs.camInvert = inv.checked; savePrefs(); });
  }
  if (fps) {
    fps.checked = !!prefs.showFps;
    fps.addEventListener('change', () => {
      prefs.showFps = fps.checked; savePrefs(); applyDisplayPrefs();
    });
  }
  if (flo) {
    flo.checked = !!prefs.showFloaters;
    flo.addEventListener('change', () => {
      prefs.showFloaters = flo.checked; savePrefs(); applyDisplayPrefs();
    });
  }
}

// ---------- ONBOARDING ----------
// Tutorial chain: ordered verb-gated hints. Each step fires once when its
// trigger event first occurs and persists "seen" in localStorage so a
// returning player doesn't get re-tutored. Two surface modes:
//   - 'log'    → fires as an in-panel chronicle hint (low friction)
//   - 'dialog' → opens the dialog modal with a portrait + multi-line
//                copy (used for the first beat of major systems so the
//                player can't miss them).
const ONBOARD_KEY = 'gj26.onboard';
const _onboardSeen = (() => {
  try { return new Set(JSON.parse(localStorage.getItem(ONBOARD_KEY) || '[]')); }
  catch { return new Set(); }
})();
function _markSeen(id) {
  _onboardSeen.add(id);
  try { localStorage.setItem(ONBOARD_KEY, JSON.stringify([..._onboardSeen])); } catch {}
}
function onboardHint(id, message) {
  if (_onboardSeen.has(id)) return;
  _markSeen(id);
  log('hint', `💡 ${message}`);
}
function onboardDialog(id, opts) {
  if (_onboardSeen.has(id)) return;
  _markSeen(id);
  showDialog(opts);
}
// Step table. Order matters: each entry is matched against the next-firing
// event in declaration order, so a kill fires the kill step even if the
// player hasn't taken damage yet (the eat-prompt waits for HP < half).
const TUTORIAL_STEPS = [
  { id: 'walk',     evt: 'walk_started', mode: 'log',
    msg: 'Walking. Click an enemy (a brindlecow east of town will do) to attack it.' },
  { id: 'cleave',   evt: 'enemy_attacked', mode: 'log',
    msg: 'Press 1 to Cleave — your sword ability — for a heavier strike.' },
  { id: 'kill',     evt: 'enemy_killed', mode: 'log',
    msg: 'Felled. Walk over the corpse, or right-click your inventory to use what dropped.' },
  { id: 'eat',      evt: 'hp_low', mode: 'log',
    msg: 'Hurt. Press Q to eat your smallest food — fast heal in a pinch.' },
  { id: 'npc',      evt: 'enemy_killed', mode: 'log',
    msg: 'Maud Pennycress (the cook) lives in the stone hut north — she has work for you.' },
  { id: 'chart',    evt: 'quest_accepted', mode: 'dialog',
    dialog: {
      speaker: 'Eldra the Lampwright',
      lines: [
        'A quest accepted — the wolds will remember you for it.',
        "Walk east of the square to the chartmaker's stone. There you can mix inks, press runes, refine raw materials, forge orbs, and inscribe charts.",
        'Each orb you forge spawns a hollow when you slot it into the Plinth. Bring the right inks + a core + a catalyst, and the orb rolls richer.',
      ],
      choices: [{ label: "I'll find the stone" }],
    } },
  { id: 'first_orb', evt: 'orb_forged', mode: 'dialog',
    dialog: {
      speaker: 'Eldra the Lampwright',
      lines: [
        'Your first orb. Look at the rolled properties — the Plinth tells you what kind of hollow waits inside.',
        'Higher Wayfinding tightens the roll. So does a fey blossom slotted as a catalyst.',
        'Slot it into the Plinth and step inside.',
      ],
      choices: [{ label: 'Onward' }],
    } },
];
function advanceTutorial(eventName) {
  for (const step of TUTORIAL_STEPS) {
    if (_onboardSeen.has(step.id)) continue;
    if (step.evt === eventName) {
      if (step.mode === 'dialog' && step.dialog) {
        onboardDialog(step.id, step.dialog);
      } else {
        onboardHint(step.id, step.msg);
      }
      return;
    }
  }
}
// Boot welcome — only step that isn't gated on an in-world event. Now a
// proper dialog so first-time players have one clear orient-and-act
// moment before the world opens.
setTimeout(() => {
  if (_onboardSeen.has('welcome')) return;
  _markSeen('welcome');
  showDialog({
    speaker: 'Eldra the Lampwright',
    lines: [
      'Welcome to Bramblewood, traveller. The wolds are wide and the days are short.',
      'Click the ground to walk. Right-click any tile to see what you can do there. Tab cycles your nearest target; 1–4 fire your ability slots; Q quaffs your smallest food.',
      "When you're ready for a hollow, find the chartmaker's stone east of the square — it's where every Wayfinder starts.",
    ],
    choices: [{ label: "I'll find my way" }],
  });
}, 1500);

// ---------- FALCONRY ----------
// One companion falcon is spawned at start. Orbits the player in 'idle';
// can be sent to attack enemies (mode 'flying' → strike → 'returning' → 'idle').
const falcon = {
  mesh: buildFalconMesh(),
  mode: 'idle',                  // 'idle' | 'flying' | 'striking' | 'returning'
  target: null,                  // enemy reference while flying
  cooldown: 0,                   // frames until next send allowed
  pos: new THREE.Vector3(player.pos.x, 2.0, player.pos.z),
  flapT: 0,
  // idle: orbit a circle around player at (radius, height); flying: lerp to target
  orbitPhase: 0,
  // Whistle scout — when > 0, orbit at a higher radius + height for the
  // duration. Decremented by dt in updateFalcon.
  scoutT: 0,
};
falcon.mesh.position.copy(falcon.pos);
scene.add(falcon.mesh);

function sendFalcon(targetEnemy) {
  if (falcon.cooldown > 0) {
    log('hint', 'Falcon is recovering.');
    return;
  }
  if (!targetEnemy || !targetEnemy.alive) return;
  falcon.mode = 'flying';
  falcon.target = targetEnemy;
  falcon.cooldown = 60 * 4;       // 4s cooldown
  log('skill', '🦅 Falcon takes flight.');
}

function updateFalcon(dt) {
  // Wing flap — fast in flight, slow in idle
  const flapRate = (falcon.mode === 'flying' || falcon.mode === 'returning') ? 28 : 14;
  falcon.flapT += dt * flapRate;
  const flapAngle = Math.sin(falcon.flapT) * 0.7;
  const parts = falcon.mesh.userData.parts;
  if (parts.Wing_L) parts.Wing_L.rotation.y =  flapAngle;
  if (parts.Wing_R) parts.Wing_R.rotation.y = -flapAngle;

  if (falcon.cooldown > 0) falcon.cooldown--;
  if (falcon.scoutT > 0) falcon.scoutT = Math.max(0, falcon.scoutT - dt);

  // Mode-driven motion
  if (falcon.mode === 'idle') {
    // Orbit at radius 1.4, height 2.0 around player. While scouting,
    // climb to radius 4 + height 5 with a faster spin so it reads as
    // an actual fly-around.
    const scout = falcon.scoutT > 0 ? Math.min(1, falcon.scoutT / 1.0) : 0;
    falcon.orbitPhase += dt * (1.4 + scout * 1.6);
    const radius = 1.4 + scout * 2.6;
    const ox = player.pos.x + Math.cos(falcon.orbitPhase) * radius;
    const oz = player.pos.z + Math.sin(falcon.orbitPhase) * radius;
    const oy = (player.mesh.position.y || 0) + 2.0 + scout * 3.0 + Math.sin(falcon.orbitPhase * 1.7) * 0.10;
    falcon.pos.lerp(new THREE.Vector3(ox, oy, oz), Math.min(1, dt * 4));
    // Face direction of motion (tangent to orbit)
    const tx = -Math.sin(falcon.orbitPhase);
    const tz =  Math.cos(falcon.orbitPhase);
    falcon.mesh.rotation.y = Math.atan2(tx, tz);
  } else if (falcon.mode === 'flying' && falcon.target) {
    const t = falcon.target;
    if (!t.alive) { falcon.mode = 'returning'; falcon.target = null; }
    else {
      const tgt = new THREE.Vector3(t.pos.x, 1.6, t.pos.z);
      falcon.pos.lerp(tgt, Math.min(1, dt * 5));
      const dx = tgt.x - falcon.pos.x;
      const dz = tgt.z - falcon.pos.z;
      falcon.mesh.rotation.y = Math.atan2(dx, dz) + Math.PI;
      // Reached strike point?
      if (falcon.pos.distanceTo(tgt) < 0.4) falcon.mode = 'striking';
    }
  } else if (falcon.mode === 'striking') {
    const t = falcon.target;
    if (t && t.alive) {
      // Strike: 1-2 damage, awards Falconry XP per damage point.
      const lv = player.skills.falconry.lv;
      const dmg = 1 + Math.floor(Math.random() * Math.min(2, lv));
      t.hp = Math.max(0, t.hp - dmg);
      t.hurtT = 12;
      t.hitReactT = 0.18;
      const splatPos = new THREE.Vector3(t.pos.x, t.pos.y + 1.2, t.pos.z);
      spawnSplat(splatPos, dmg, 'hit');
      const enemyLabel = t.kind === 'goblin' ? 'Bramble-imp' : 'Cow';
      log('combat', `🦅 Falcon hits ${dmg}. (${enemyLabel} ${t.hp}/${t.hpMax})`);
      import('./game/skills.js').then(m =>
        m.awardXp(player, 'falconry', 8 + dmg * 4, log, { worldPos: splatPos }));
      if (t.hp <= 0) {
        t.alive = false;
        t.respawn = 60 * 30;
        t.mesh.visible = false;
        log('combat', `☠ ${enemyLabel} felled by the falcon.`);
        if (t.onDeath) t.onDeath(player, log);
      }
    }
    falcon.target = null;
    falcon.mode = 'returning';
  } else if (falcon.mode === 'returning') {
    const home = new THREE.Vector3(player.pos.x, 2.0, player.pos.z);
    falcon.pos.lerp(home, Math.min(1, dt * 4.5));
    const dx = home.x - falcon.pos.x;
    const dz = home.z - falcon.pos.z;
    if (Math.abs(dx) + Math.abs(dz) > 0.05) {
      falcon.mesh.rotation.y = Math.atan2(dx, dz) + Math.PI;
    }
    if (falcon.pos.distanceTo(home) < 0.6) falcon.mode = 'idle';
  }

  falcon.mesh.position.copy(falcon.pos);
}

// snap camera initially
updateCamera(camera, player.pos, 1, true);

// mouse handler — registers clicks, consumed in loop
attachMouse(canvasEl);

// post-processing — render-pass + bloom + output
const composer = new EffectComposer(renderer);
composer.setSize(W, H);
composer.addPass(new RenderPass(scene, camera));
// strength / radius / threshold — only really emissive pixels (fire, marker
// lantern) should bloom. The sky used to exceed 0.78 → whole frame whitewash.
const bloom = new UnrealBloomPass(new THREE.Vector2(W, H), 0.35, 0.5, 0.95);
composer.addPass(bloom);
composer.addPass(new OutputPass());

// Paint one frame immediately so the canvas isn't transparent during the
// rest of synchronous boot (lots of mesh/material work follows). Without
// this the player sees the dark stage CSS background until the first
// rAF tick after module eval — which can read as a "blank game" bug.
composer.render();

// fire mesh + warm flickering point light + smoke
let fireMesh = null;
let fireLight = null;
let fireSmoke = null;
if (world.firePos) {
  const fy = terrainHeightAt(world.firePos.x + 0.5, world.firePos.y + 0.5);
  fireMesh = buildFireMesh();
  fireMesh.position.set(world.firePos.x + 0.5, fy, world.firePos.y + 0.5);
  scene.add(fireMesh);

  fireLight = new THREE.PointLight(0xffa346, 1.5, 6, 1.6);
  fireLight.position.set(world.firePos.x + 0.5, fy + 1.0, world.firePos.y + 0.5);
  scene.add(fireLight);

  fireSmoke = makeSmoke(
    new THREE.Vector3(world.firePos.x + 0.5, fy + 0.8, world.firePos.y + 0.5),
    40
  );
  scene.add(fireSmoke);
}

// Memorial lantern beside Maud's hearth — visible only once the harvest
// picnic finishes. Stored on a global so the visibility tick can toggle
// it as quest state changes.
let memorialLantern = null;
let memorialLanternLight = null;
if (world.firePos) {
  const lm = buildMemorialLanternMesh();
  if (lm) {
    const lx = world.firePos.x + 1.2;
    const lz = world.firePos.y - 0.8;
    lm.position.set(lx, terrainHeightAt(lx, lz), lz);
    lm.visible = false;
    scene.add(lm);
    memorialLantern = lm;
    // Soft warm point light tied to the lantern; flickers with fireLight
    memorialLanternLight = new THREE.PointLight(0xffd384, 0.0, 2.5, 1.6);
    memorialLanternLight.position.set(lx, terrainHeightAt(lx, lz) + 0.2, lz);
    scene.add(memorialLanternLight);
  }
}

// click-target marker
const clickMarker = buildClickMarker();
scene.add(clickMarker);

// ---------- MINIMAP ----------
// Tiny 2D top-down view of the area immediately around the player.
// Shows tile types (water/stone/path/grass/floor) as a subtle base
// plus colored dots for entities (player, enemies, NPCs).
const MM_RADIUS = 12;          // tiles in each direction from player
const _mmCanvas = document.getElementById('minimap');
const _mmCtx = _mmCanvas?.getContext?.('2d');
// Visibility radius in tiles around the player. Tiles inside are bright;
// previously-explored tiles outside are dim; un-explored tiles hidden.
const MM_VIS_RADIUS = 5;
function _mmTileVisibility(tx, ty) {
  // Inside the live visible radius? full brightness.
  const dx = tx - player.x, dy = ty - player.y;
  if (dx*dx + dy*dy <= MM_VIS_RADIUS * MM_VIS_RADIUS) return 1.0;
  // Otherwise: bright if explored (memory tiles), hidden if not.
  if (player.exploredTiles?.has(`${tx},${ty}`)) return 0.45;
  return 0;
}

function drawMinimap() {
  if (!_mmCtx || !player) return;
  const W = _mmCanvas.width, H = _mmCanvas.height;
  const cell = W / (MM_RADIUS * 2 + 1);
  _mmCtx.clearRect(0, 0, W, H);
  // Fog of Hedge affix — minimap goes black during a foggy run. The
  // player still sees a dim outline of their own tile so they don't
  // think the canvas broke.
  if (dungeon.active && dungeon.fogOfHedge) {
    _mmCtx.fillStyle = '#1c1610';
    _mmCtx.fillRect(0, 0, W, H);
    _mmCtx.fillStyle = '#c94c4c';
    _mmCtx.fillRect(W/2 - cell/2, H/2 - cell/2, cell, cell);
    _mmCtx.fillStyle = '#6b5a3a';
    _mmCtx.font = '10px "EB Garamond", serif';
    _mmCtx.fillText('Fog of Hedge', 8, H - 8);
    return;
  }
  // Wireframe spec: parchment-light backdrop, gold border drawn by CSS.
  _mmCtx.fillStyle = 'rgba(232, 220, 192, 0.95)';
  _mmCtx.fillRect(0, 0, W, H);
  // Subtle 8-px grid for orientation
  _mmCtx.strokeStyle = 'rgba(184, 165, 106, 0.35)';
  _mmCtx.lineWidth = 1;
  for (let i = 0; i <= MM_RADIUS * 2 + 1; i += 4) {
    _mmCtx.beginPath();
    _mmCtx.moveTo(i * (W / (MM_RADIUS * 2 + 1)), 0);
    _mmCtx.lineTo(i * (W / (MM_RADIUS * 2 + 1)), H);
    _mmCtx.moveTo(0, i * (H / (MM_RADIUS * 2 + 1)));
    _mmCtx.lineTo(W, i * (H / (MM_RADIUS * 2 + 1)));
    _mmCtx.stroke();
  }
  // Draw tiles in a window centered on the player, gated by fog.
  for (let dy = -MM_RADIUS; dy <= MM_RADIUS; dy++) {
    for (let dx = -MM_RADIUS; dx <= MM_RADIUS; dx++) {
      const tx = player.x + dx, ty = player.y + dy;
      const vis = _mmTileVisibility(tx, ty);
      if (vis <= 0) continue;
      const tile = world.tileGrid?.[ty]?.[tx];
      let col = null;
      if (tile === 'water')      col = '#3a6e8e';
      else if (tile === 'stone') col = '#8a8270';
      else if (tile === 'path')  col = '#a48852';
      else if (tile === 'sand')  col = '#c8b078';
      else if (tile === 'floor') col = '#8a6e4a';
      else if (tile === 'grass') col = '#56823a';
      if (col) {
        _mmCtx.globalAlpha = vis;
        _mmCtx.fillStyle = col;
        _mmCtx.fillRect((dx + MM_RADIUS) * cell, (dy + MM_RADIUS) * cell, cell, cell);
      }
    }
  }
  _mmCtx.globalAlpha = 1;
  // Trees — only inside live vis (they can move/be chopped, no point
  // showing them on memory tiles).
  if (world.trees) {
    _mmCtx.fillStyle = '#2c5a26';
    for (const t of world.trees) {
      if (t.depleted) continue;
      if (_mmTileVisibility(t.x, t.y) < 1) continue;
      const dx = t.x - player.x, dy = t.y - player.y;
      if (Math.abs(dx) > MM_RADIUS || Math.abs(dy) > MM_RADIUS) continue;
      _mmCtx.fillRect((dx + MM_RADIUS) * cell + 1, (dy + MM_RADIUS) * cell + 1, cell - 2, cell - 2);
    }
  }
  // Enemies — same: live vis only (memory shouldn't reveal patrol).
  // Sense Aggro spell relaxes the rule for any enemy currently aggro'd.
  const senseActive = (player.senseAggroT || 0) > 0;
  for (const e of enemies) {
    if (!e.alive) continue;
    const insideVis = _mmTileVisibility(e.x, e.y) >= 1;
    const showViaSense = senseActive && e.aggro;
    if (!insideVis && !showViaSense) continue;
    const dx = e.x - player.x, dy = e.y - player.y;
    if (Math.abs(dx) > MM_RADIUS || Math.abs(dy) > MM_RADIUS) continue;
    // Sense-only dots (outside fog) get a softer halo so the player can
    // tell "this dot is from the spell, not LOS".
    if (showViaSense && !insideVis) {
      _mmCtx.fillStyle = 'rgba(216, 65, 46, 0.40)';
      _mmCtx.beginPath();
      _mmCtx.arc((dx + MM_RADIUS) * cell + cell * 0.5,
                 (dy + MM_RADIUS) * cell + cell * 0.5,
                 cell * 0.7, 0, Math.PI * 2);
      _mmCtx.fill();
    }
    _mmCtx.fillStyle = e.isBoss ? '#ff7a3a' : '#d8412e';
    const cx = (dx + MM_RADIUS) * cell + cell * 0.5;
    const cy = (dy + MM_RADIUS) * cell + cell * 0.5;
    _mmCtx.beginPath();
    _mmCtx.arc(cx, cy, cell * (e.isBoss ? 0.55 : 0.40), 0, Math.PI * 2);
    _mmCtx.fill();
  }
  // NPC tiles — visible from memory too (they're stationary), but
  // dimmer until you're nearby.
  const npcTiles = [
    world.cookSpawn,
    HOD_TILE, WITHERING_TILE, HERBALIST_TILE,
    CHARTMAKER_TILE,
  ];
  for (const tile of npcTiles) {
    if (!tile) continue;
    const vis = _mmTileVisibility(tile.x, tile.y);
    if (vis <= 0) continue;
    const dx = tile.x - player.x, dy = tile.y - player.y;
    if (Math.abs(dx) > MM_RADIUS || Math.abs(dy) > MM_RADIUS) continue;
    _mmCtx.globalAlpha = vis;
    _mmCtx.fillStyle = '#6cb8ff';
    const cx = (dx + MM_RADIUS) * cell + cell * 0.5;
    const cy = (dy + MM_RADIUS) * cell + cell * 0.5;
    _mmCtx.beginPath();
    _mmCtx.arc(cx, cy, cell * 0.35, 0, Math.PI * 2);
    _mmCtx.fill();
  }
  _mmCtx.globalAlpha = 1;
  // Soft fog edge — gradient ring at the visible radius border so the
  // bright→dim transition reads.
  const cxC = MM_RADIUS * cell + cell * 0.5;
  const cyC = MM_RADIUS * cell + cell * 0.5;
  const visPx = MM_VIS_RADIUS * cell;
  const grad = _mmCtx.createRadialGradient(cxC, cyC, visPx * 0.85, cxC, cyC, visPx + cell);
  grad.addColorStop(0, 'rgba(232, 220, 192, 0)');
  grad.addColorStop(1, 'rgba(232, 220, 192, 0.85)');
  _mmCtx.fillStyle = grad;
  _mmCtx.fillRect(0, 0, W, H);
  // Compass letters on the edge so orientation reads.
  _mmCtx.fillStyle = 'rgba(58, 47, 31, 0.85)';   // ink
  _mmCtx.font = 'bold 11px Cinzel, serif';
  _mmCtx.textAlign = 'center';
  _mmCtx.textBaseline = 'middle';
  _mmCtx.fillText('N', W / 2, 9);
  _mmCtx.fillText('S', W / 2, H - 9);
  _mmCtx.fillText('W', 9, H / 2);
  _mmCtx.fillText('E', W - 9, H / 2);
  // Player (always at center, small white-gold dot with ring)
  const pcx = MM_RADIUS * cell + cell * 0.5;
  const pcy = MM_RADIUS * cell + cell * 0.5;
  _mmCtx.fillStyle = '#fff3a8';
  _mmCtx.beginPath();
  _mmCtx.arc(pcx, pcy, cell * 0.45, 0, Math.PI * 2);
  _mmCtx.fill();
  _mmCtx.strokeStyle = 'rgba(0, 0, 0, 0.7)';
  _mmCtx.lineWidth = 1;
  _mmCtx.stroke();
  // Facing tick
  const f = (player.dir === 'up') ? [0, -1] :
            (player.dir === 'down') ? [0, 1] :
            (player.dir === 'left') ? [-1, 0] : [1, 0];
  _mmCtx.strokeStyle = '#fff3a8';
  _mmCtx.lineWidth = 1.5;
  _mmCtx.beginPath();
  _mmCtx.moveTo(pcx, pcy);
  _mmCtx.lineTo(pcx + f[0] * cell * 0.9, pcy + f[1] * cell * 0.9);
  _mmCtx.stroke();
}

// ---------- ACTIVE PATH PREVIEW ----------
// Tiny translucent dots along the player's queued path so click-to-walk
// reads visually. Pre-allocate a small pool of meshes and toggle them
// each frame to match the current path length — cheaper than spawn/dispose.
const PATH_DOT_POOL = 24;
const pathDots = [];
for (let i = 0; i < PATH_DOT_POOL; i++) {
  const m = new THREE.Mesh(
    new THREE.CircleGeometry(0.10, 12),
    new THREE.MeshBasicMaterial({
      color: 0xfff3a8, transparent: true, opacity: 0.55,
      depthWrite: false, side: THREE.DoubleSide,
    })
  );
  m.rotation.x = -Math.PI / 2;
  m.renderOrder = 4;
  m.visible = false;
  scene.add(m);
  pathDots.push(m);
}

function updatePathPreview(now) {
  const path = (player && player.path) ? player.path : [];
  for (let i = 0; i < pathDots.length; i++) {
    const dot = pathDots[i];
    const tile = path[i];
    if (!tile) { dot.visible = false; continue; }
    dot.visible = true;
    dot.position.set(tile.x + 0.5, 0.05, tile.y + 0.5);
    // Pulse staggered along the path so it reads as direction-of-travel.
    const phase = now * 0.004 - i * 0.6;
    dot.material.opacity = 0.30 + 0.20 * (1 + Math.sin(phase));
  }
}

// ---------- TILE HOVER ----------
// Soft cream square on the floor under the cursor. Hidden when:
//   - cursor is off the canvas
//   - the hovered tile is unwalkable (per classifyTile)
//   - the player is currently moving on that exact tile
const tileHoverMesh = new THREE.Mesh(
  new THREE.PlaneGeometry(0.92, 0.92),
  new THREE.MeshBasicMaterial({
    color: 0xfff3a8,
    transparent: true,
    opacity: 0,
    depthWrite: false,
    side: THREE.DoubleSide,
  })
);
tileHoverMesh.rotation.x = -Math.PI / 2;
tileHoverMesh.renderOrder = 3;
tileHoverMesh.visible = false;
scene.add(tileHoverMesh);

// Compute a human-readable label for whatever's at (tx, ty), or null
// if there's nothing notable. Used by the hover tooltip.
function describeTile(tx, ty) {
  // Enemies first
  for (const e of enemies) {
    if (e.alive && e.x === tx && e.y === ty) {
      const name = e.displayName || (e.kind === 'goblin' ? 'Bramble-imp' : (e.kind || 'Creature'));
      return `${name} · ${Math.max(0, e.hp)}/${e.hpMax} HP`;
    }
  }
  // NPCs
  if (world.cookSpawn && world.cookSpawn.x === tx && world.cookSpawn.y === ty) return NPC_DEFS.cook?.name || 'Cook';
  if (HOD_TILE.x === tx && HOD_TILE.y === ty) return NPC_DEFS.hod?.name || 'Hod';
  if (WITHERING_TILE.x === tx && WITHERING_TILE.y === ty) return NPC_DEFS.withering?.name || 'Sir Withering';
  if (HERBALIST_TILE.x === tx && HERBALIST_TILE.y === ty) return NPC_DEFS.quill?.name || 'Quill';
  // Stations
  if (CHARTMAKER_TILE.x === tx && CHARTMAKER_TILE.y === ty) return "Chartmaker's Stone";
  if (MIRROR_TILE.x === tx && MIRROR_TILE.y === ty) return 'Looking Glass';
  if (world.firePos && world.firePos.x === tx && world.firePos.y === ty) return 'Hearth';
  // Resources — UI E: if the item has a `source: {skill, level}` gate and
  // the player isn't yet at that level, append a "needs X N (you have M)"
  // suffix so the player learns the gate before clicking. Same pattern
  // for trees / forage / ore.
  const _gateSuffix = (id) => {
    if (!id || !ITEMS[id]) return '';
    const src = ITEMS[id].source;
    if (!src) return '';
    const have = player?.skills?.[src.skill]?.lv ?? 1;
    if (have >= src.level) return '';
    const SKILL_NAMES = { atk: 'Attack', str: 'Strength', def: 'Defence', hp: 'HP',
      wilds: 'Wilds', earth: 'Earth', cook: 'Cooking',
      carto: 'Wayfinding', falconry: 'Falconry', magic: 'Magic' };
    return ` · needs ${SKILL_NAMES[src.skill] || src.skill} ${src.level} (you have ${have})`;
  };
  for (const t of world.trees) if (t.x === tx && t.y === ty && !t.depleted) return 'Oak Tree';
  for (const s of world.forageSpawns) if (s.x === tx && s.y === ty && !s.depleted) {
    const id = s.itemId || s.id;
    const baseName = (id && ITEMS[id]) ? ITEMS[id].name : 'Forage';
    return baseName + _gateSuffix(id);
  }
  if (world.oreNodes) {
    for (const n of world.oreNodes) if (n.x === tx && n.y === ty && !n.depleted) {
      const id = n.itemId || n.id || 'mosswort_ore';
      const baseName = (id && ITEMS[id]) ? ITEMS[id].name : 'Ore';
      return baseName + _gateSuffix(id);
    }
  }
  if (world.tileGrid?.[ty]?.[tx] === 'water') return 'Pond';
  return null;
}

function updateTileHover(now) {
  if (!camera) return;
  const t = getHoverTile(camera);
  const tip = document.getElementById('hover-tooltip');
  const fadeOut = () => {
    if (tileHoverMesh.material.opacity > 0) tileHoverMesh.material.opacity *= 0.85;
    if (tileHoverMesh.material.opacity < 0.02) tileHoverMesh.visible = false;
    if (tip) tip.classList.remove('show');
    _cpHoverDesc = null;
  };
  if (!t) { fadeOut(); return; }
  const cls = classifyTile(t.x, t.y);
  if (cls === 'unwalkable') { fadeOut(); return; }
  tileHoverMesh.visible = true;
  tileHoverMesh.position.set(t.x + 0.5, 0.03, t.y + 0.5);
  if (cls === 'entity') {
    tileHoverMesh.material.color.setHex(0xffd864);
    const pulse = 0.30 + 0.10 * (1 + Math.sin(now * 0.005));
    tileHoverMesh.material.opacity = pulse;
  } else {
    tileHoverMesh.material.color.setHex(0xfff3a8);
    const pulse = 0.18 + 0.07 * (1 + Math.sin(now * 0.005));
    tileHoverMesh.material.opacity = pulse;
  }
  // Tooltip — only when there's something nameable on the tile, anchored
  // to the cursor's last screen position via the click-marker projection.
  if (tip) {
    const label = describeTile(t.x, t.y);
    if (label) {
      tip.textContent = label;
      tip.classList.add('show');
      // Also drive the context panel's Interact state. Pick a verb based
      // on what's there: NPC = Talk, station = Use, resource = Examine.
      const cls = classifyTile(t.x, t.y);
      let verb = 'Examine', desc = label;
      if (cls === 'entity') {
        if (label.includes('HP')) verb = 'Attack';   // enemy with HP token
        else if (/Pennycress|Hod|Sir|Quill/.test(label)) verb = 'Talk';
        else if (/Tree|Ore|Pond|Forage|Hedgecap|Whitleberry|Wishrose/i.test(label)) verb = 'Examine';
        else verb = 'Use';
      }
      _cpHoverDesc = { name: label.split(' · ')[0], desc, action: verb };
      // Anchor at the projected world-tile position. If t.world is the
      // ground hit, project it to screen space.
      if (t.world) {
        const sv = t.world.clone();
        sv.y += 0.5;
        sv.project(camera);
        const W = renderer?.domElement?.clientWidth ?? 800;
        const H = renderer?.domElement?.clientHeight ?? 600;
        const sx = (sv.x * 0.5 + 0.5) * W;
        const sy = (-sv.y * 0.5 + 0.5) * H;
        tip.style.left = sx + 'px';
        tip.style.top  = sy + 'px';
      }
    } else {
      tip.classList.remove('show');
      _cpHoverDesc = null;
    }
  }
}

// ---------- LOCK-ON RING ----------
// Pulsing red ring on the floor under the player's locked combat target.
// Hidden when no target; positioned + pulsed each frame in updateLockOn().
const lockOnRing = new THREE.Mesh(
  new THREE.RingGeometry(0.45, 0.55, 28),
  new THREE.MeshBasicMaterial({
    color: 0xc63030,
    transparent: true,
    opacity: 0,
    side: THREE.DoubleSide,
    depthWrite: false,
  })
);
lockOnRing.rotation.x = -Math.PI / 2;
lockOnRing.renderOrder = 4;
lockOnRing.visible = false;
scene.add(lockOnRing);

function updateLockOn(now) {
  const t = player.combatTarget;
  if (!t || !t.alive) {
    lockOnRing.visible = false;
    return;
  }
  lockOnRing.visible = true;
  lockOnRing.position.set(t.pos.x, 0.04, t.pos.z);
  // Slow rotation reads as "actively tracking" instead of static decal.
  // The ring is rotated -π/2 around X so it lies flat; we drive the Z
  // axis here (post-rotation it's the visible plane's spin).
  lockOnRing.rotation.z = now * 0.0006;
  // Subtle pulse — alpha 0.55..0.95 at ~3Hz
  const pulse = 0.55 + 0.20 * (1 + Math.sin(now * 0.008));
  lockOnRing.material.opacity = pulse;
}

// Bramblewood keep — fixed landmark on the north edge of the map.
const castleScene = await loadCastleGLB();
if (castleScene) {
  const castle = castleScene.clone(true);
  const cx = Math.floor(world.spawn.x) + 0.5;
  const cz = 4.5;
  castle.position.set(cx, terrainHeightAt(cx, cz), cz);
  castle.scale.setScalar(1.4);
  scene.add(castle);
}

// Chartmaker's standing stone — Wayfinding skill's primary verb. Click
// to roll a Tier-1 chart that opens a procedural dungeon. See
// src/scene/dungeon.js for the procgen + render.
const CHARTMAKER_TILE = { x: world.spawn.x + 3, y: world.spawn.y - 1 };
{
  const cx = CHARTMAKER_TILE.x + 0.5;
  const cz = CHARTMAKER_TILE.y + 0.5;
  const cy = terrainHeightAt(cx, cz);
  // Prefer the carved-stone GLB; if the model hasn't loaded yet we fall back
  // to a chunky placeholder so the chartmaker click target stays alive
  // through boot.
  const stone = buildChartmakerStoneMesh() || new THREE.Group();
  if (stone.children.length === 0) {
    const main = new THREE.Mesh(
      new THREE.BoxGeometry(0.45, 1.30, 0.30),
      new THREE.MeshToonMaterial({ color: 0x8a8278 })
    );
    main.position.set(0, 0.65, 0);
    main.rotation.y = 0.15;
    stone.add(main);
  }
  // Glowing rune disc at the base — kept on top of the GLB so the click
  // affordance still reads at a glance.
  const rune = new THREE.Mesh(
    new THREE.CircleGeometry(0.22, 24),
    new THREE.MeshBasicMaterial({ color: 0xb58637, transparent: true, opacity: 0.85 })
  );
  rune.rotation.x = -Math.PI / 2;
  rune.position.set(0, 0.02, 0.30);
  stone.add(rune);
  stone.position.set(cx, cy, cz);
  stone.userData.kind = 'chartmaker';
  scene.add(stone);
}

// ============================================================
// VILLAGE SKILL STATIONS — every skill that's open-world-ish gets a hub
// presence so you can prep / wind down without leaving Bramblewood.
// Cooking has Maud's hearth (existing). Smithing has the forge (existing).
// Wayfinding has the chartmaker's stone (just added). The four below
// fill out fishing / foraging / woodcutting / mining.
// ============================================================
const POND_TILES = [
  { x: world.spawn.x - 4, y: world.spawn.y + 3 },
  { x: world.spawn.x - 3, y: world.spawn.y + 3 },
  { x: world.spawn.x - 4, y: world.spawn.y + 4 },
];
// Town reorg phase 3: Quill's herbalist hut now sits at rows 14-17 cols 4-8.
// Interior floor tile (6, 15) is where she stands. Was (-2, +4) = (13, 19).
const HERBALIST_TILE = { x: world.spawn.x - 9, y: world.spawn.y };
// Hod stands a tile west-southwest of the forge. Withering stands by
// the castle gate. Tiles match where the meshes are placed in the
// "Blacksmith forge" and "Sir Withering" blocks below.
// Town reorg phase 3: Hod's forge now at rows 17-20 cols 10-14.
// Interior floor (12, 18) — fire tile (12, 19) sits between him and the
// south door, so player approaches via the floor flank (11, 18) or (13, 18).
// Was (+4, +1) = (19, 16).
const HOD_TILE       = { x: world.spawn.x - 3, y: world.spawn.y + 3 };
// Town reorg phase 3: Withering's perch now at rows 6-8 cols 13-15.
// Interior floor (14, 7) is the single floor tile of the 3×3 perch.
// Was (-1, -5) = (14, 10).
const WITHERING_TILE = { x: world.spawn.x - 1, y: world.spawn.y - 8 };
const PRACTICE_STUMP_TILE = { x: world.spawn.x + 2, y: world.spawn.y + 1 };
const PRACTICE_ORE_TILE   = { x: world.spawn.x + 6, y: world.spawn.y + 2 };

// Refinement Stations — placed around the chartmaker stone so the
// Wayfinding loop has a diegetic outdoor surface (mortar / grindstone /
// vessel / curing / kiln). Click → opens the refinement modal filtered
// to that station. Tile constants drive interactAt, classifyTile, and
// the right-click verb menu.
const STATION_TILES = [
  { kind: 'mortar',     x: world.spawn.x + 4, y: world.spawn.y - 3, label: 'Mortar' },
  { kind: 'grindstone', x: world.spawn.x + 5, y: world.spawn.y - 3, label: 'Grindstone' },
  { kind: 'vessel',     x: world.spawn.x + 6, y: world.spawn.y - 3, label: 'Vessel' },
  { kind: 'curing',     x: world.spawn.x + 4, y: world.spawn.y - 4, label: 'Curing Rack' },
  { kind: 'kiln',       x: world.spawn.x + 6, y: world.spawn.y - 4, label: 'Kiln' },
];

/** Build a small procedural mesh for a refinement station. Stylized
 *  primitives — readable at a glance from camera distance. */
function buildStationMesh(kind) {
  const g = new THREE.Group();
  if (kind === 'mortar') {
    // Squat stone pedestal with a dished bowl on top.
    const base = new THREE.Mesh(
      new THREE.CylinderGeometry(0.22, 0.28, 0.45, 12),
      new THREE.MeshToonMaterial({ color: 0x8a8278 }));
    base.position.y = 0.225;
    base.castShadow = true; base.receiveShadow = true;
    g.add(base);
    const bowl = new THREE.Mesh(
      new THREE.CylinderGeometry(0.20, 0.10, 0.10, 12),
      new THREE.MeshToonMaterial({ color: 0x4a3528 }));
    bowl.position.y = 0.50;
    g.add(bowl);
  } else if (kind === 'grindstone') {
    // Vertical disc on a stout wood frame.
    const disc = new THREE.Mesh(
      new THREE.CylinderGeometry(0.32, 0.32, 0.08, 18),
      new THREE.MeshToonMaterial({ color: 0x9c8e76 }));
    disc.rotation.z = Math.PI / 2;
    disc.position.y = 0.45;
    disc.castShadow = true;
    g.add(disc);
    // Two posts.
    for (const dx of [-0.25, 0.25]) {
      const post = new THREE.Mesh(
        new THREE.BoxGeometry(0.06, 0.50, 0.06),
        new THREE.MeshToonMaterial({ color: 0x6e4a2a }));
      post.position.set(dx, 0.25, 0);
      g.add(post);
    }
  } else if (kind === 'vessel') {
    // Tall fired-clay urn — body + neck + lip.
    const body = new THREE.Mesh(
      new THREE.CylinderGeometry(0.18, 0.14, 0.45, 14),
      new THREE.MeshToonMaterial({ color: 0xb88456 }));
    body.position.y = 0.225;
    body.castShadow = true;
    g.add(body);
    const neck = new THREE.Mesh(
      new THREE.CylinderGeometry(0.10, 0.16, 0.10, 12),
      new THREE.MeshToonMaterial({ color: 0xb88456 }));
    neck.position.y = 0.50;
    g.add(neck);
    const lip = new THREE.Mesh(
      new THREE.CylinderGeometry(0.13, 0.10, 0.04, 12),
      new THREE.MeshToonMaterial({ color: 0x8a5a30 }));
    lip.position.y = 0.57;
    g.add(lip);
  } else if (kind === 'curing') {
    // Two posts + a horizontal beam + a draped pelt.
    for (const dx of [-0.30, 0.30]) {
      const post = new THREE.Mesh(
        new THREE.BoxGeometry(0.06, 0.85, 0.06),
        new THREE.MeshToonMaterial({ color: 0x6e4a2a }));
      post.position.set(dx, 0.425, 0);
      post.castShadow = true;
      g.add(post);
    }
    const beam = new THREE.Mesh(
      new THREE.BoxGeometry(0.72, 0.06, 0.06),
      new THREE.MeshToonMaterial({ color: 0x6e4a2a }));
    beam.position.y = 0.85;
    g.add(beam);
    // Hanging pelt.
    const pelt = new THREE.Mesh(
      new THREE.BoxGeometry(0.42, 0.46, 0.04),
      new THREE.MeshToonMaterial({ color: 0xa8784a }));
    pelt.position.y = 0.55;
    g.add(pelt);
  } else if (kind === 'kiln') {
    // Squat brick oven with a small chimney + door panel.
    const body = new THREE.Mesh(
      new THREE.BoxGeometry(0.55, 0.55, 0.45),
      new THREE.MeshToonMaterial({ color: 0x8a4a3a }));
    body.position.y = 0.275;
    body.castShadow = true;
    g.add(body);
    const door = new THREE.Mesh(
      new THREE.BoxGeometry(0.18, 0.20, 0.06),
      new THREE.MeshToonMaterial({ color: 0x2a1a14 }));
    door.position.set(0, 0.20, 0.24);
    g.add(door);
    const chim = new THREE.Mesh(
      new THREE.BoxGeometry(0.16, 0.30, 0.16),
      new THREE.MeshToonMaterial({ color: 0x6a3a2a }));
    chim.position.set(0.10, 0.70, -0.10);
    g.add(chim);
    // Glow at the door — tiny emissive plate.
    const glow = new THREE.Mesh(
      new THREE.PlaneGeometry(0.16, 0.18),
      new THREE.MeshBasicMaterial({ color: 0xffa346, transparent: true, opacity: 0.85 }));
    glow.position.set(0, 0.20, 0.275);
    g.add(glow);
  } else {
    return null;
  }
  return g;
}

// Station mesh placement deferred until after VILLAGE_TILES is declared
// (~line 2203 in main.js). See `_placeStationTiles()` near the well placement.

// 1) Fishing pond — overrides world tile grid to make a small water patch
// (existing tryFish already keys off world.tileGrid==='water'). Renders a
// flat blue plane on top so it reads visually.
{
  for (const p of POND_TILES) {
    if (world.tileGrid[p.y]) {
      world.tileGrid[p.y][p.x] = 'water';
      world.blocked[p.y][p.x]  = false;
    }
  }
  const pond = new THREE.Mesh(
    new THREE.PlaneGeometry(2.6, 2.0),
    new THREE.MeshBasicMaterial({ color: 0x4a78a0, transparent: true, opacity: 0.85 })
  );
  pond.rotation.x = -Math.PI / 2;
  pond.position.set(world.spawn.x - 3.0, terrainHeightAt(world.spawn.x - 3.0, world.spawn.y + 3.5) + 0.02, world.spawn.y + 3.5);
  scene.add(pond);
  // A small reed cluster at the edge for visibility
  const reed = new THREE.Mesh(
    new THREE.BoxGeometry(0.05, 0.50, 0.05),
    new THREE.MeshToonMaterial({ color: 0x5b7a3a })
  );
  reed.position.set(world.spawn.x - 4.4, terrainHeightAt(world.spawn.x - 4.4, world.spawn.y + 3.0) + 0.25, world.spawn.y + 3.0);
  scene.add(reed);
}

// 2) Herbalist's hut — Quill's cottage promoted to functional. The cottage
// is already placed; we only need the interaction tile + visual presence.
{
  const hx = HERBALIST_TILE.x + 0.5;
  const hz = HERBALIST_TILE.y + 0.5;
  // Drying rack of hanging herb bundles — prefer the carved GLB, fall
  // back to a chunky stick rack so the hut still reads while assets load.
  let rack = buildDryingRackMesh();
  if (!rack) {
    rack = new THREE.Group();
    const post1 = new THREE.Mesh(new THREE.BoxGeometry(0.04, 0.60, 0.04), new THREE.MeshToonMaterial({ color: 0x6e4a2a }));
    post1.position.set(-0.20, 0.30, 0); rack.add(post1);
    const post2 = post1.clone(); post2.position.x = 0.20; rack.add(post2);
    const beam  = new THREE.Mesh(new THREE.BoxGeometry(0.50, 0.04, 0.04), new THREE.MeshToonMaterial({ color: 0x6e4a2a }));
    beam.position.set(0, 0.58, 0); rack.add(beam);
    for (let i = 0; i < 3; i++) {
      const bunch = new THREE.Mesh(new THREE.BoxGeometry(0.04, 0.18, 0.04), new THREE.MeshToonMaterial({ color: 0x7a9656 }));
      bunch.position.set(-0.16 + i * 0.16, 0.42, 0); rack.add(bunch);
    }
  }
  rack.position.set(hx, terrainHeightAt(hx, hz), hz);
  rack.rotation.y = -Math.PI / 8;
  scene.add(rack);
  // Quill stands beside the rack — same tile, slight offset so the click
  // target is the rack/herbalist combo. NPC mesh is a click-readable
  // figure; the existing HERBALIST_TILE handler still routes interaction.
  const quill = buildQuillMesh();
  if (quill) {
    quill.position.set(hx + 0.30, terrainHeightAt(hx + 0.30, hz - 0.20), hz - 0.20);
    quill.rotation.y = -Math.PI / 5;
    quill.userData.kind = 'npc_quill';
    scene.add(quill);
  }
}

// Withered bramble-vine forage nodes — Quill's quest material lives
// here. Five hand-placed clusters at the village edge so the quest is
// reachable without combat. Each adds a forage entry that drops
// bramble_resin, mirroring the existing forage spawn shape.
{
  const VINE_TILES = [
    { x: world.spawn.x - 5, y: world.spawn.y + 6 },
    { x: world.spawn.x - 4, y: world.spawn.y + 7 },
    { x: world.spawn.x - 3, y: world.spawn.y + 8 },
    { x: world.spawn.x + 6, y: world.spawn.y + 5 },
    { x: world.spawn.x + 7, y: world.spawn.y + 6 },
  ];
  for (const t of VINE_TILES) {
    if (world.isTerrainBlocked(t.x, t.y)) continue;
    if (world.forageSpawns.some(s => s.x === t.x && s.y === t.y)) continue;
    const mesh = buildWitheredBrambleMesh();
    if (!mesh) continue;
    const wx = t.x + 0.5, wz = t.y + 0.5;
    mesh.position.set(wx, terrainHeightAt(wx, wz), wz);
    mesh.rotation.y = Math.random() * Math.PI * 2;
    scene.add(mesh);
    world.forageSpawns.push({
      x: t.x, y: t.y, mesh,
      kind: 'bramble', item: 'bramble_resin',
      depleted: false, respawn: 0,
    });
  }
}

// Foxglove sprigs — purple bell-shaped flowers along the road shoulders
// (Mother Onywyn's quest reagent).
{
  const FOXGLOVE_TILES = [
    { x: world.spawn.x - 7, y: world.spawn.y + 4 },
    { x: world.spawn.x - 6, y: world.spawn.y + 5 },
    { x: world.spawn.x + 5, y: world.spawn.y - 4 },
    { x: world.spawn.x + 6, y: world.spawn.y - 5 },
    { x: world.spawn.x + 8, y: world.spawn.y + 6 },
  ];
  const _foxStemMat = new THREE.MeshStandardMaterial({ color: 0x4d6b2c, roughness: 0.85 });
  const _foxBellMat = new THREE.MeshStandardMaterial({ color: 0x9a4eaa, roughness: 0.7, emissive: 0x331140, emissiveIntensity: 0.2 });
  for (const t of FOXGLOVE_TILES) {
    if (world.isTerrainBlocked(t.x, t.y)) continue;
    if (world.forageSpawns.some(s => s.x === t.x && s.y === t.y)) continue;
    const g = new THREE.Group();
    const stem = new THREE.Mesh(new THREE.BoxGeometry(0.04, 0.45, 0.04), _foxStemMat);
    stem.position.y = 0.22; g.add(stem);
    for (let i = 0; i < 4; i++) {
      const bell = new THREE.Mesh(new THREE.BoxGeometry(0.08, 0.06, 0.08), _foxBellMat);
      bell.position.set(0.05 * (i % 2 ? 1 : -1), 0.20 + i * 0.08, 0);
      g.add(bell);
    }
    const wx = t.x + 0.5, wz = t.y + 0.5;
    g.position.set(wx, terrainHeightAt(wx, wz), wz);
    g.rotation.y = Math.random() * Math.PI * 2;
    scene.add(g);
    world.forageSpawns.push({
      x: t.x, y: t.y, mesh: g,
      kind: 'herb', item: 'foxglove_sprig',
      depleted: false, respawn: 0,
    });
  }
}

// Sir Withering of Trelliswick — older knight + falcon-on-arm. Stands
// just outside the castle gate as a quest-giver presence. Click target
// is purely NPC-flavored for now; future hooks will tie into chartmaker
// reputation and a falconry minigame.
{
  const wx = world.spawn.x - 0.6;
  const wz = world.spawn.y - 5.0;
  const withering = buildWitheringMesh();
  if (withering) {
    withering.position.set(wx, terrainHeightAt(wx, wz), wz);
    withering.rotation.y = Math.PI;
    withering.userData.kind = 'npc_withering';
    scene.add(withering);
  }
  // Falconer's perch beside Sir Withering — a wood post with leather wrap
  // and dangling bells. Sells the falconry hint before the player ever
  // takes the quest. Fall back to nothing if GLB hasn't loaded.
  const perch = buildFalconerPerchMesh();
  if (perch) {
    const px = wx + 0.7;
    const pz = wz + 0.25;
    perch.position.set(px, terrainHeightAt(px, pz), pz);
    perch.rotation.y = Math.PI / 6;
    scene.add(perch);
  }
}

// 3) Practice woodcutting stump — adds a stump-shaped tree node to
// world.trees so the existing tryChopTree pipeline handles everything,
// including respawn timers + log drops + Woodcutting XP.
{
  const sx = PRACTICE_STUMP_TILE.x + 0.5;
  const sz = PRACTICE_STUMP_TILE.y + 0.5;
  const stump = new THREE.Group();
  const log = new THREE.Mesh(new THREE.CylinderGeometry(0.22, 0.26, 0.55, 12), new THREE.MeshToonMaterial({ color: 0x6e4a2a }));
  log.position.y = 0.27; stump.add(log);
  // a couple of leafy regrowth tufts
  const tuft = new THREE.Mesh(new THREE.BoxGeometry(0.15, 0.10, 0.15), new THREE.MeshToonMaterial({ color: 0x5b7a3a }));
  tuft.position.set(0, 0.60, 0); stump.add(tuft);
  stump.position.set(sx, terrainHeightAt(sx, sz), sz);
  scene.add(stump);
  world.trees.push({
    x: PRACTICE_STUMP_TILE.x, y: PRACTICE_STUMP_TILE.y,
    mesh: stump, kind: 'practice_oak',
    chopsRemaining: 3, depleted: false, respawn: 0,
  });
}

// 4) Practice ore rock — push into world.oreNodes so tryMineRock works.
{
  const rx = PRACTICE_ORE_TILE.x + 0.5;
  const rz = PRACTICE_ORE_TILE.y + 0.5;
  const rock = new THREE.Group();
  const stone = new THREE.Mesh(new THREE.BoxGeometry(0.55, 0.40, 0.55), new THREE.MeshToonMaterial({ color: 0x8a8278 }));
  stone.position.y = 0.20; rock.add(stone);
  const vein = new THREE.Mesh(new THREE.BoxGeometry(0.30, 0.06, 0.20), new THREE.MeshToonMaterial({ color: 0xb8722e }));
  vein.position.set(0, 0.42, 0); rock.add(vein);
  rock.position.set(rx, terrainHeightAt(rx, rz), rz);
  scene.add(rock);
  world.oreNodes.push({
    x: PRACTICE_ORE_TILE.x, y: PRACTICE_ORE_TILE.y,
    mesh: rock, kind: 'copper', item: 'mosswort_ore',
    chopsRemaining: 3, depleted: false, respawn: 0,
  });
}

// Makeover Mirror — re-customize the player's look without rerolling the
// save. Stands on a fixed tile near spawn; clicking opens the char creator
// pre-filled with the current appearance.
const MIRROR_TILE = { x: world.spawn.x - 2, y: world.spawn.y };
{
  const mx = MIRROR_TILE.x + 0.5;
  const mz = MIRROR_TILE.y + 0.5;
  const my = terrainHeightAt(mx, mz);
  const mirror = new THREE.Group();
  // wooden frame post
  const post = new THREE.Mesh(
    new THREE.BoxGeometry(0.10, 1.20, 0.10),
    new THREE.MeshToonMaterial({ color: 0x6e4a2a })
  );
  post.position.set(0, 0.60, 0);
  mirror.add(post);
  // oval glass — flat box with reflective-ish blue
  const glass = new THREE.Mesh(
    new THREE.BoxGeometry(0.55, 0.70, 0.06),
    new THREE.MeshToonMaterial({ color: 0xa8c8d8 })
  );
  glass.position.set(0, 1.10, 0);
  mirror.add(glass);
  // gilded frame around the glass
  const frame = new THREE.Mesh(
    new THREE.BoxGeometry(0.62, 0.78, 0.04),
    new THREE.MeshToonMaterial({ color: 0xb58637 })
  );
  frame.position.set(0, 1.10, -0.02);
  mirror.add(frame);
  mirror.position.set(mx, my, mz);
  mirror.userData.kind = 'mirror';
  scene.add(mirror);
}

// Blacksmith forge — east of spawn, gives the smithing skill a home.
const forgeScene = await loadForgeGLB();
let hodMesh = null;
if (forgeScene) {
  const forge = forgeScene.clone(true);
  const fx = world.spawn.x + 5.5;
  const fz = world.spawn.y + 1.0;
  forge.position.set(fx, terrainHeightAt(fx, fz), fz);
  forge.scale.setScalar(1.0);
  forge.rotation.y = -Math.PI / 2;
  scene.add(forge);
  // Old Hod the smith stands a tile to the south of the forge,
  // facing it. Click target wired in handleVillageTile.
  const hod = buildHodMesh();
  if (hod) {
    const hx = fx - 1.0;
    const hz = fz + 0.4;
    hod.position.set(hx, terrainHeightAt(hx, hz), hz);
    hod.rotation.y = Math.PI / 2;
    hod.userData.kind = 'npc_hod';
    scene.add(hod);
    hodMesh = hod;
  }
  // Practice dummy beside the forge — clickable for a small smithing
  // XP per swing once Hod's quest is accepted (see interactAt).
  const dummyMesh = buildPracticeDummyMesh();
  if (dummyMesh) {
    const dx = fx + 1.2, dz = fz + 0.2;
    dummyMesh.position.set(dx, terrainHeightAt(dx, dz), dz);
    dummyMesh.rotation.y = Math.PI / 5;
    dummyMesh.userData.kind = 'practice_dummy';
    dummyMesh.userData.tx = Math.floor(dx);
    dummyMesh.userData.ty = Math.floor(dz);
    scene.add(dummyMesh);
  }
}
const PRACTICE_DUMMY_TILE = { x: world.spawn.x + 6, y: world.spawn.y + 1 };

// Bramblewood neighbors. Tile coords are derived from offsets so placement
// and the click-to-talk dialog cannot drift apart.
const NEW_NPCS = [
  { kind: 'npc_eldra',   build: buildEldraMesh,   dx: -2.5, dz: -1.5, rotY: -Math.PI / 4,
    speaker: 'Eldra the Lampwright',
    lines: ['Old hands, old wicks. The lanterns find their light if you tend them, dear.',
            'Folks pass through here all hours, but the dark — well, the dark stays unless we coax it.'] },
  { kind: 'npc_cricket', build: buildCricketMesh, dx:  2.5, dz: -1.5, rotY:  Math.PI / 6,
    speaker: 'Cricket the Letter-Carrier',
    lines: ['Got a letter for someone? I run from valley head to coopers\' gate, three rounds a day.',
            'My friend on my shoulder — that\'s Pibbet. He\'s good at finding addresses I forgot.'] },
  { kind: 'npc_pell',    build: buildPellMesh,    dx: -1.5, dz:  3.0, rotY: -Math.PI / 3,
    speaker: 'Brother Pell of the Stone Cloister',
    lines: ['Peace to you, traveler. The cloister keeps a small library — old maps, old ledgers, a few pages of bramble-lore.',
            'If you ever need a quiet hour to read, our door is open from dawn to dusk-bell.'] },
  { kind: 'npc_onywyn',  build: buildOnywynMesh,  dx:  4.5, dz:  3.5, rotY:  Math.PI / 5,
    speaker: 'Mother Onywyn the Herb-Witch',
    lines: ['Hush, hush. The raven knows you\'re here. (She gestures with foxglove.)',
            'I trade bitter draughts and bittermint. Bring me the right herbs and we\'ll talk of the sleep that comes after the bramble-binding.'] },
];

for (const npc of NEW_NPCS) {
  const mesh = npc.build();
  if (!mesh) continue;
  const x = world.spawn.x + npc.dx;
  const z = world.spawn.y + npc.dz;
  mesh.position.set(x, terrainHeightAt(x, z), z);
  mesh.rotation.y = npc.rotY;
  mesh.userData.kind = npc.kind;
  scene.add(mesh);
  npc.mesh = mesh;
  npc.tx = Math.floor(x);
  npc.ty = Math.floor(z);
}

// ============================================================
// VALIDATION C — skinned-rig vs rigid-rig walk comparison.
// ------------------------------------------------------------
// Drops the canonical three.js Soldier (GLTF SkinnedMesh + embedded
// idle/walk/run clips, 49 bones, ~11k tris) next to Eldra and runs both
// in a continuous walk so the user can compare:
//   - Eldra: rigid-parented cube/cone segments, animateGLBKnight()
//            rotates Arm_L/Knee_L/etc. groups per-frame (joint seams
//            visible at every pivot).
//   - Soldier: weight-skinned mesh, THREE.AnimationMixer plays a
//              keyframed walk clip (vertices near each joint blend
//              between bones, surface bends smoothly, no seams).
// Both are toonified through the existing pipeline so material is held
// constant — only the rig type differs.
// To remove: search "VALIDATION C" and delete this block + the mixer
// update + the eldra-walk-test call in loop().
// ============================================================
let _validationEldra = null;          // { mesh, fakeEntity }
const eldraNpc = NEW_NPCS.find(n => n.kind === 'npc_eldra');
if (eldraNpc?.mesh) {
  // Force Eldra to walk in place by handing animateGLBKnight a fake
  // entity with moving=true. animateGLBKnight reads e.moving / e.running
  // / e._phase / e._t and rotates the group children — it doesn't care
  // whether the entity is the real player or a stub.
  _validationEldra = { mesh: eldraNpc.mesh, fakeEntity: { moving: true, running: false } };
}

// ============================================================
// BRAMBLEWOOD VILLAGE — spread along the Old Wagon Road. See
// docs/WORLD_BIBLE.md for who lives where.
// ============================================================
// Find the path's row (the road runs E-W across the map).
const ROAD_Z = 12.5;   // matches the P-tile row in src/data/map.txt
const VILLAGE_TILES = [];   // list of {x,y,kind,name} for blocking + interaction

// Refinement station placement — runs after VILLAGE_TILES is declared.
for (const s of STATION_TILES) {
  const cx = s.x + 0.5, cz = s.y + 0.5;
  const cy = terrainHeightAt(cx, cz);
  const mesh = buildStationMesh(s.kind);
  if (mesh) {
    mesh.position.set(cx, cy, cz);
    mesh.userData.kind = `station_${s.kind}`;
    mesh.userData.name = s.label;
    scene.add(mesh);
  }
  VILLAGE_TILES.push({ x: s.x, y: s.y, kind: `station_${s.kind}`, name: s.label });
}

const wellScene = await loadWellGLB();
if (wellScene) {
  // Old Mother Well — village center, at the path's midpoint near spawn
  const w = wellScene.clone(true);
  const wx = world.spawn.x + 0.5;
  const wz = ROAD_Z + 1.5;
  w.position.set(wx, terrainHeightAt(wx, wz), wz);
  w.scale.setScalar(1.0);
  w.rotation.y = Math.PI / 8;
  w.userData.kind = 'well';
  scene.add(w);
  VILLAGE_TILES.push({ x: world.spawn.x, y: Math.floor(wz), kind: 'well', name: 'Old Mother Well' });
}

const bankScene = await loadBankGLB();
if (bankScene) {
  // Coopers' Hold — west of spawn on the road
  const b = bankScene.clone(true);
  const bx = world.spawn.x - 5.5;
  const bz = ROAD_Z + 1.0;
  b.position.set(bx, terrainHeightAt(bx, bz), bz);
  b.scale.setScalar(1.1);
  b.rotation.y = 0;
  b.userData.kind = 'bank';
  scene.add(b);
  VILLAGE_TILES.push({ x: Math.floor(bx), y: Math.floor(bz), kind: 'bank', name: "Coopers' Hold" });
}

for (const npc of NEW_NPCS) {
  if (npc.tx == null) continue;   // mesh failed to build
  VILLAGE_TILES.push({ x: npc.tx, y: npc.ty, kind: npc.kind, name: npc.speaker });
}

// Eldra's dim lanterns — 5 markers scattered around the village. Click each
// while the quest is active to light it; lit state persists across reload.
const LANTERN_OFFSETS = [
  { id: 'lt_nwell', dx: -1.5, dz: -0.5 },
  { id: 'lt_sbank', dx: -5.0, dz:  2.5 },
  { id: 'lt_cot',   dx:  1.5, dz:  1.5 },
  { id: 'lt_forge', dx:  4.0, dz:  0.5 },
  { id: 'lt_chart', dx:  3.5, dz:  4.0 },
];
const _lantern_lit_mat = new THREE.MeshStandardMaterial({
  color: 0xffba60, emissive: 0xff8a20, emissiveIntensity: 1.6, roughness: 0.7,
});
const lanternMeshes = [];
for (const cfg of LANTERN_OFFSETS) {
  const mesh = buildMemorialLanternMesh();
  if (!mesh) continue;
  const x = world.spawn.x + cfg.dx;
  const z = world.spawn.y + cfg.dz;
  mesh.position.set(x, terrainHeightAt(x, z), z);
  mesh.scale.setScalar(0.55);
  mesh.userData.kind = 'eldra_lantern';
  mesh.userData.lanternId = cfg.id;
  scene.add(mesh);
  const tx = Math.floor(x), ty = Math.floor(z);
  lanternMeshes.push({ mesh, id: cfg.id, tx, ty });
  VILLAGE_TILES.push({ x: tx, y: ty, kind: 'eldra_lantern', name: 'Dim Lantern' });
}
function applyLanternLit(rec) {
  rec.mesh.traverse(o => { if (o.isMesh) o.material = _lantern_lit_mat; });
}
// Restore lit state on boot (handles quest progress that survived a reload)
for (const rec of lanternMeshes) {
  if (player.quest.eldraLitIds?.includes(rec.id)) applyLanternLit(rec);
}
// Cricket's mailboxes — 3 wooden boxes scattered through the village.
const MAILBOX_OFFSETS = [
  { id: 'mb_well',   dx: -0.5, dz: 1.0 },
  { id: 'mb_cot',    dx:  2.5, dz: 0.5 },
  { id: 'mb_chart',  dx:  4.5, dz: 4.5 },
];
const _mailboxMat = new THREE.MeshStandardMaterial({ color: 0x6b4626, roughness: 0.85 });
const _mailboxFlagMat = new THREE.MeshStandardMaterial({ color: 0xc54040, roughness: 0.7 });
const mailboxes = [];
for (const cfg of MAILBOX_OFFSETS) {
  const x = world.spawn.x + cfg.dx, z = world.spawn.y + cfg.dz;
  const g = new THREE.Group();
  const post = new THREE.Mesh(new THREE.BoxGeometry(0.08, 0.6, 0.08), _mailboxMat);
  post.position.y = 0.30; g.add(post);
  const box = new THREE.Mesh(new THREE.BoxGeometry(0.30, 0.20, 0.20), _mailboxMat);
  box.position.y = 0.50; g.add(box);
  const flag = new THREE.Mesh(new THREE.BoxGeometry(0.04, 0.10, 0.10), _mailboxFlagMat);
  flag.position.set(0.16, 0.55, 0); g.add(flag);
  g.position.set(x, terrainHeightAt(x, z), z);
  scene.add(g);
  const tx = Math.floor(x), ty = Math.floor(z);
  mailboxes.push({ id: cfg.id, tx, ty, mesh: g, flagMesh: flag });
  VILLAGE_TILES.push({ x: tx, y: ty, kind: 'mailbox', name: 'Mailbox' });
}
function tryDeliverLetter(tx, ty) {
  const mb = mailboxes.find(m => m.tx === tx && m.ty === ty);
  if (!mb) return false;
  const q = player.quest;
  if (!q.flags.cricketAccepted) {
    log('hint', 'A wooden mailbox. Maybe Cricket has something for it.');
    return true;
  }
  if (q.cricketDeliveredIds.includes(mb.id)) {
    log('hint', 'Already delivered to this one.');
    return true;
  }
  q.cricketDeliveredIds.push(mb.id);
  q.cricketDelivered = q.cricketDeliveredIds.length;
  // Lower the flag visually
  mb.flagMesh.rotation.z = -0.3;
  log('quest', `+ Letter delivered. (${q.cricketDelivered}/3)`);
  if (q.cricketDelivered >= 3) log('quest', '★ All three delivered. Cricket will tip you.');
  renderQuest();
  return true;
}

// Pell's marked books — 3 small book props near Brother Pell's tile.
const BOOK_OFFSETS = [
  { id: 'bk_a', dx: -0.5, dz: 2.5 },
  { id: 'bk_b', dx: -1.5, dz: 2.5 },
  { id: 'bk_c', dx: -1.0, dz: 3.5 },
];
const _bookMatA = new THREE.MeshStandardMaterial({ color: 0x4a6e3c, roughness: 0.8 });
const _bookMatB = new THREE.MeshStandardMaterial({ color: 0x6b3a26, roughness: 0.8 });
const _bookMatC = new THREE.MeshStandardMaterial({ color: 0x2a3d5e, roughness: 0.8 });
const _bookRibbonMat = new THREE.MeshStandardMaterial({ color: 0xc54040, roughness: 0.6 });
const _bookMats = [_bookMatA, _bookMatB, _bookMatC];
const books = [];
for (let i = 0; i < BOOK_OFFSETS.length; i++) {
  const cfg = BOOK_OFFSETS[i];
  const x = world.spawn.x + cfg.dx, z = world.spawn.y + cfg.dz;
  const g = new THREE.Group();
  const book = new THREE.Mesh(new THREE.BoxGeometry(0.30, 0.10, 0.22), _bookMats[i]);
  book.position.y = 0.05; g.add(book);
  const ribbon = new THREE.Mesh(new THREE.BoxGeometry(0.04, 0.02, 0.30), _bookRibbonMat);
  ribbon.position.set(0.05, 0.11, 0); g.add(ribbon);
  g.position.set(x, terrainHeightAt(x, z), z);
  scene.add(g);
  const tx = Math.floor(x), ty = Math.floor(z);
  books.push({ id: cfg.id, tx, ty, ribbonMesh: ribbon });
  VILLAGE_TILES.push({ x: tx, y: ty, kind: 'pell_book', name: 'Marked Book' });
}
function tryReadBook(tx, ty) {
  const bk = books.find(b => b.tx === tx && b.ty === ty);
  if (!bk) return false;
  const q = player.quest;
  if (!q.flags.pellAccepted) {
    log('hint', 'A book with a red ribbon. Brother Pell is the librarian.');
    return true;
  }
  if (q.pellReadIds.includes(bk.id)) {
    log('hint', 'You\'ve read this one through. The ribbon\'s already loose.');
    return true;
  }
  q.pellReadIds.push(bk.id);
  q.pellRead = q.pellReadIds.length;
  // Drop the ribbon
  bk.ribbonMesh.position.x += 0.10;
  bk.ribbonMesh.rotation.z = -0.5;
  log('quest', `+ Page-numbers filed. (${q.pellRead}/3)`);
  if (q.pellRead >= 3) log('quest', '★ All three read. Pell will be pleased.');
  renderQuest();
  return true;
}

// Lampwright's Eve hours — dusk through dawn. Outside this window Eldra's
// wicks won't catch (the oil's slow-burn needs the dark).
function isLampwrightHour() {
  const t = world.timeOfDay ?? 0.5;
  return t >= 0.70 || t < 0.25;
}
function tryLightLantern(tx, ty) {
  const rec = lanternMeshes.find(r => r.tx === tx && r.ty === ty);
  if (!rec) return false;
  const q = player.quest;
  if (!q.flags.eldraAccepted) {
    log('hint', 'A dim lantern. Maybe someone in the village would care.');
    return true;
  }
  if (q.eldraLitIds.includes(rec.id)) {
    log('hint', 'This wick already burns.');
    return true;
  }
  if (!isLampwrightHour()) {
    log('hint', 'The wick won\'t catch in this light. Come back at dusk.');
    return true;
  }
  q.eldraLitIds.push(rec.id);
  q.eldraLanternsLit = q.eldraLitIds.length;
  applyLanternLit(rec);
  log('quest', `+ Lantern lit. (${q.eldraLanternsLit}/5)`);
  if (q.eldraLanternsLit >= 5) log('quest', '★ All five lit. Eldra will want a word.');
  renderQuest();
  return true;
}

const cottageScene = await loadCottageGLB();
if (cottageScene) {
  // Three named cottages with slight tint variety so they don't read as clones.
  // Maud's House is at the cookSpawn cluster (her dairy hut already exists);
  // these are Hod's and Fenny's empty homes — door notes preserve discovery.
  const cottages = [
    { name: "Hod's Cottage",   x: world.spawn.x + 2.5,  z: ROAD_Z + 1.5,  rotY: 0,           tintHue: 0.0  },
    { name: "Fenny's Place",   x: world.spawn.x - 2.5,  z: ROAD_Z + 2.0,  rotY: Math.PI/8,   tintHue: 0.04 },
    { name: "Quill's Cottage", x: world.spawn.x + 8.0,  z: ROAD_Z + 2.0,  rotY: -Math.PI/12, tintHue:-0.03 },
  ];
  for (const c of cottages) {
    const inst = cottageScene.clone(true);
    // tint shift on plaster + thatch so each cottage feels distinct
    const hsl = {};
    inst.traverse(o => {
      if (!o.isMesh || !o.material) return;
      const m = o.material;
      // Hide roof/thatch meshes so the top-down camera can see inside the
      // cottage. The wall fader handles plaster occlusion separately.
      if (m.name === 'Thatch' || m.name === 'ThatchD') {
        o.visible = false;
        return;
      }
      if (m.name === 'Plaster') {
        const cloned = m.clone();
        if (cloned.color) {
          cloned.color.getHSL(hsl);
          hsl.h = (hsl.h + c.tintHue + 1) % 1;
          cloned.color.setHSL(hsl.h, hsl.s, hsl.l);
        }
        o.material = cloned;
        o.userData.occlude = true;
      }
    });
    inst.position.set(c.x, terrainHeightAt(c.x, c.z), c.z);
    inst.rotation.y = c.rotY;
    inst.scale.setScalar(1.0);
    inst.userData.kind = 'cottage';
    inst.userData.name = c.name;
    scene.add(inst);
    VILLAGE_TILES.push({ x: Math.floor(c.x), y: Math.floor(c.z), kind: 'cottage', name: c.name });
  }

  // Replace blocky stone-wall buildings detected in map.txt with proper
  // cottage GLBs. world.buildings is an array of {x,y,w,h} rects of
  // connected stone+floor footprints (skipped from per-tile rendering
  // in world.js). One GLB per building, scaled so its native footprint
  // covers the rect; thatch hidden so the top-down camera sees inside.
  if (world.buildings && world.buildings.length) {
    // Measure cottage GLB native footprint once.
    const probe = cottageScene.clone(true);
    probe.updateMatrixWorld(true);
    const probeBox = new THREE.Box3().setFromObject(probe);
    const cottageW = Math.max(0.01, probeBox.max.x - probeBox.min.x);
    const cottageD = Math.max(0.01, probeBox.max.z - probeBox.min.z);
    let bIdx = 0;
    for (const b of world.buildings) {
      const inst = cottageScene.clone(true);
      // Hide roof / mark plaster as occluder, same treatment as named cottages.
      const hsl = {};
      const tintHue = 0.06 * Math.sin(bIdx * 1.7); // light variety per building
      inst.traverse(o => {
        if (!o.isMesh || !o.material) return;
        const m = o.material;
        if (m.name === 'Thatch' || m.name === 'ThatchD') { o.visible = false; return; }
        if (m.name === 'Plaster') {
          const cloned = m.clone();
          if (cloned.color) {
            cloned.color.getHSL(hsl);
            hsl.h = (hsl.h + tintHue + 1) % 1;
            cloned.color.setHSL(hsl.h, hsl.s, hsl.l);
          }
          o.material = cloned;
          o.userData.occlude = true;
        }
      });
      // Scale to fit the footprint, but never stretch beyond the GLB's
      // authored size (cap at 1.0). Bigger footprints just leave more
      // floor visible around the cottage — better than a wide squat box.
      // Rotate 90° if the footprint is taller than wide so the cottage's
      // long axis matches the footprint's long axis.
      const longAxisAlongZ = b.h > b.w;
      const fitW = longAxisAlongZ ? b.h : b.w;
      const fitD = longAxisAlongZ ? b.w : b.h;
      const sx = fitW / cottageW;
      const sz = fitD / cottageD;
      inst.scale.setScalar(Math.min(1.0, Math.min(sx, sz)));
      inst.rotation.y = longAxisAlongZ ? Math.PI / 2 : 0;
      const cx = b.x + b.w / 2;
      const cz = b.y + b.h / 2;
      inst.position.set(cx, terrainHeightAt(cx, cz), cz);
      inst.userData.kind = 'cottage';
      inst.userData.name = `Cottage (${b.x},${b.y})`;
      scene.add(inst);
      bIdx++;
    }
  }
}

const signScene = await loadSignpostGLB();
if (signScene) {
  // Signposts at trail forks; flavor only, no waypoint arrows (per
  // evoke-online-game-feel: signs that don't explain produce wonder).
  const signs = [
    { x: world.spawn.x + 0.5,  z: ROAD_Z + 0.6, rotY: 0 },          // village center fork
    { x: world.spawn.x - 4.5,  z: ROAD_Z + 0.6, rotY: Math.PI/3 },  // by the bank
    { x: world.spawn.x + 4.5,  z: ROAD_Z + 0.6, rotY: -Math.PI/3 }, // toward forge
  ];
  for (const s of signs) {
    const inst = signScene.clone(true);
    inst.position.set(s.x, terrainHeightAt(s.x, s.z), s.z);
    inst.rotation.y = s.rotY;
    scene.add(inst);
  }
}

// cook mesh — sits on terrain
let cookMesh = null;
let cookBaseY = 0;
if (world.cookSpawn) {
  cookBaseY = terrainHeightAt(world.cookSpawn.x + 0.5, world.cookSpawn.y + 0.5);
  cookMesh = buildCookMesh();
  cookMesh.userData.kind = 'npc_cook';   // align with hod/quill/withering so scene scans + codex find her
  cookMesh.position.set(world.cookSpawn.x + 0.5, cookBaseY, world.cookSpawn.y + 0.5);
  scene.add(cookMesh);

  // ! marker: a little gold cone
  const markerGeo = new THREE.ConeGeometry(0.08, 0.3, 4);
  const markerMat = new THREE.MeshBasicMaterial({ color: 0xffd84a });
  const marker = new THREE.Mesh(markerGeo, markerMat);
  marker.rotation.x = Math.PI;
  marker.position.set(world.cookSpawn.x + 0.5, cookBaseY + 2.5, world.cookSpawn.y + 0.5);
  scene.add(marker);
  cookMesh.userData.marker = marker;
}

// preload the Blender-authored cow before spawning, so spawnCow clones the
// GLB instead of falling back to procedural geometry.
await loadCowGLB();

// enemies — cows in the field, goblins in the SE camp, plus chickens
// pecking around the village, hares scattered in tall grass, and a few
// bramble-caps mixed into the goblin camp for harder fights.
const enemies = [
  ...world.cowSpawns.map(p => spawnCow(p.x, p.y, scene)),
  ...world.goblinSpawns.map(p => spawnGoblin(p.x, p.y, scene)),
];

// Chickens around the village — three is plenty; four+ reads as a farm
// rather than a cottage neighborhood.
{
  const chickSpawns = [
    { x: world.spawn.x + 3, y: world.spawn.y + 4 },
    { x: world.spawn.x - 3, y: world.spawn.y + 4 },
    { x: world.spawn.x + 5, y: world.spawn.y + 5 },
  ];
  for (const p of chickSpawns) {
    if (!world.isTerrainBlocked(p.x, p.y)) enemies.push(spawnChicken(p.x, p.y, scene));
  }
}

// Hares — scattered in the meadow north of the path.
{
  const hareSpawns = [
    { x: world.spawn.x + 8, y: world.spawn.y - 3 },
    { x: world.spawn.x - 6, y: world.spawn.y - 4 },
    { x: world.spawn.x + 12, y: world.spawn.y - 5 },
    { x: world.spawn.x - 10, y: world.spawn.y - 2 },
  ];
  for (const p of hareSpawns) {
    if (!world.isTerrainBlocked(p.x, p.y)) enemies.push(spawnHare(p.x, p.y, scene));
  }
}

// One bramble-cap among the regular goblins (a champion variant).
if (world.goblinSpawns.length > 0) {
  const champPt = world.goblinSpawns[Math.floor(world.goblinSpawns.length / 2)];
  enemies.push(spawnBrambleCap(champPt.x + 1, champPt.y, scene));
}

// Wild boars — at the wood's edge, harder than cows. Iron-tier filler.
{
  const boarSpawns = [
    { x: world.spawn.x + 14, y: world.spawn.y - 6 },
    { x: world.spawn.x + 16, y: world.spawn.y - 4 },
    { x: world.spawn.x - 12, y: world.spawn.y - 5 },
  ];
  for (const p of boarSpawns) {
    if (!world.isTerrainBlocked(p.x, p.y)) enemies.push(spawnBoar(p.x, p.y, scene));
  }
}

// Hedge wolves — Hard-tier predators in the deep wolds. Two of them, far
// from spawn, so the Steel-tier player has somewhere to go for steel mats.
{
  const wolfSpawns = [
    { x: world.spawn.x + 22, y: world.spawn.y - 8 },
    { x: world.spawn.x - 18, y: world.spawn.y - 7 },
  ];
  for (const p of wolfSpawns) {
    if (!world.isTerrainBlocked(p.x, p.y)) enemies.push(spawnHedgeWolf(p.x, p.y, scene));
  }
}

// Dev-mode toggle — flips body.dev-mode based on ?dev URL param. Wires
// the FPS counter and any other dev-only HUD chrome. Run with
// http://127.0.0.1:8765/?dev to see them; default play is clean.
if (new URLSearchParams(location.search).has('dev')) {
  document.body.classList.add('dev-mode');
}

// Hamburger toggle for the lab-nav (Codex / Editor links). Clean play
// surface by default; click ☰ to expose. Click outside the nav closes
// it so the screen stays uncluttered.
{
  const nav = document.getElementById('lab-nav');
  const toggle = document.getElementById('lab-nav-toggle');
  if (nav && toggle) {
    toggle.addEventListener('click', (e) => {
      e.stopPropagation();
      nav.classList.toggle('open');
    });
    document.addEventListener('click', (e) => {
      if (nav.classList.contains('open') && !nav.contains(e.target)) {
        nav.classList.remove('open');
      }
    });
  }
}

// drifting cloud layer
const clouds = spawnClouds(scene, world, 18);

// Dev console install moved below the LOG / HUD block — installDevConsole
// calls log('hint', ...) at the end of its body, and `log` reads logEntries
// (a `const` further down in this file). Calling it before that const is
// initialized throws TDZ and aborts module init, blanking the canvas.

// Demo pads removed — they were dev animation labs polluting the village.
// (Kept the import in case we want to re-enable for character debugging.)
let demoZone = null;

// starter loadout
player.inventory.equipped.body = 'leather_body';
player.inventory.equipped.shield = 'wooden_shield';

// ---------- LOG / HUD ----------
// New wireframe log lives bottom-left at #log-list; the legacy #log node
// is hidden inside the unused #panel rail. We fan the same content into
// both so any code that scrolls #log keeps working.
const logEl = document.getElementById('log');
const logListEl = document.getElementById('log-list');
const logEntries = [];
function _fmtTime() {
  const d = new Date();
  const h = d.getHours().toString().padStart(2, '0');
  const m = d.getMinutes().toString().padStart(2, '0');
  return `${h}:${m}`;
}
function log(kind, msg) {
  if (kind === 'quest' && msg.startsWith('★')) {
    const fn = msg.includes(' — done') ? 'questDone' : 'questAccept';
    import('./core/sfx.js').then(m => m.sfx[fn]()).catch(() => {});
  }
  for (const e of logEntries) e.fresh = false;
  logEntries.push({ kind, msg, fresh: true, ts: _fmtTime() });
  if (logEntries.length > 24) logEntries.shift();
  const html = logEntries.map(e =>
    `<div class="entry ${e.kind}${e.fresh ? ' entry-new' : ''}"><span class="ts">[${e.ts}]</span>${escape(e.msg)}</div>`
  ).join('');
  if (logEl)     logEl.innerHTML = html;
  if (logListEl) logListEl.innerHTML = html;
  for (const el of [logEl, logListEl]) {
    if (!el) continue;
    if (el.scrollTo) el.scrollTo({ top: el.scrollHeight, behavior: 'smooth' });
    else             el.scrollTop = el.scrollHeight;
  }
}
function escape(s) {
  return s.replace(/[&<>"]/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]));
}

// Dev console — toggle with `. Installed AFTER the log block above because
// installDevConsole calls log() in its body and log() reads `logEntries`.
installDevConsole({
  player, world, scene,
  log,
  awardXp,
  ITEMS,
  enemies,
  spawnFns: {
    goblin: spawnGoblin, cow: spawnCow, chicken: spawnChicken, hare: spawnHare,
    boar: spawnBoar, hedgewolf: spawnHedgeWolf, brambleCap: spawnBrambleCap,
    burrowBoar: spawnBurrowBoar, wolfAlpha: spawnWolfAlpha, hedgemother: spawnHedgemother,
    targetDummy: spawnTargetDummy,
  },
});

const SKILL_LABELS = {
  atk: 'Attack', str: 'Strength', def: 'Defence', hp: 'HP',
  // Wilds = forage + fish + wc; Earth = mine + smith. See
  // docs/design/skills-consolidation.md.
  wilds: 'Wilds', earth: 'Earth', cook: 'Cooking',
  carto: 'Wayfinding', falconry: 'Falconry', magic: 'Magic',
};
// Hand-drawn ink SVG glyphs (16×16, currentColor stroke). Used as fallback
// when a skill's PNG icon hasn't been generated yet. They inherit the
// surrounding text color, so they tint correctly inside the ink palette.
const _ICON = (path, fill = 'none') => `<svg class="sk-ico" viewBox="0 0 16 16" width="14" height="14" fill="${fill}" stroke="currentColor" stroke-width="1.3" stroke-linecap="round" stroke-linejoin="round" style="vertical-align:-2px;margin-right:2px;">${path}</svg>`;
const _SKILL_SVG = {
  atk:      _ICON('<path d="M2 14 L9 7 M3 13 L4 12 M14 2 L9 7 L8 5 L11 2 Z"/>'),
  str:      _ICON('<path d="M3 11 Q3 7 6 7 Q9 7 9 4 L13 4 L13 7 Q13 11 10 11 Q7 11 7 14 L3 14 Z"/>'),
  def:      _ICON('<path d="M8 2 L13 4 Q13 11 8 14 Q3 11 3 4 Z M8 5 L8 11"/>'),
  hp:       _ICON('<path d="M8 13 Q3 9 3 6 Q3 4 5 4 Q7 4 8 6 Q9 4 11 4 Q13 4 13 6 Q13 9 8 13 Z"/>', 'currentColor'),
  cook:     _ICON('<path d="M3 6 H13 V12 Q13 13 12 13 H4 Q3 13 3 12 Z M2 6 L4 5 M14 6 L12 5 M6 4 Q7 2 8 4 Q9 6 10 4"/>'),
  wilds:    _ICON('<path d="M3 13 Q5 9 8 9 Q11 9 13 13 M8 9 Q8 5 6 4 M8 9 Q8 5 10 4 M5 8 Q4 11 7 12"/>'),
  earth:    _ICON('<path d="M2 14 L9 7 M5 5 Q8 2 14 5 M14 5 L8 8 L11 11 Z M2 11 H7 V13 H2 Z"/>'),
  carto:    _ICON('<path d="M3 4 H13 V12 H3 Z M3 4 Q1 6 3 8 Q1 10 3 12 M13 4 Q15 6 13 8 Q15 10 13 12 M5 6 H11 M5 9 H10"/>'),
  falconry: _ICON('<path d="M2 11 Q5 6 8 8 Q11 6 14 11 M8 8 V13"/>'),
  magic:    _ICON('<path d="M3 13 L8 3 L13 13 Z M5 11 H11 M8 6 L8 9"/>'),
};
// Skills with rendered PNG icons in assets/icons/. Listed explicitly so we
// only attempt the <img> path when one exists — keeps the load deterministic
// instead of relying on a 404 + onerror swap (browsers log the 404 to console).
const _SKILL_HAS_PNG = new Set(['atk','str','wilds','earth','cook','carto','falconry','magic']);
function skillIconHTML(k) {
  if (_SKILL_HAS_PNG.has(k)) {
    return `<img class="sk-ico-img" src="assets/icons/${k}.png" alt="" />`;
  }
  return _SKILL_SVG[k] || '';
}
const SKILL_ICONS = {
  atk: skillIconHTML('atk'), str: skillIconHTML('str'),
  def: skillIconHTML('def'), hp: skillIconHTML('hp'),
  cook: skillIconHTML('cook'), wilds: skillIconHTML('wilds'),
  earth: skillIconHTML('earth'), carto: skillIconHTML('carto'),
  falconry: skillIconHTML('falconry'), magic: skillIconHTML('magic'),
};

function renderStats() {
  const skillsEl = document.getElementById('skills');
  if (skillsEl) {
    skillsEl.innerHTML = SKILL_KEYS.map(k => {
      const lv = player.skills[k].lv;
      const pct = xpProgress(player, k);
      // UI B — render the next-milestone hint underneath the XP bar so the
      // player sees what they're chasing. Pulled lazily so a missing
      // milestones data file doesn't break the popup; the import is at
      // the top of main.js (see SKILL_MILESTONES import).
      const next = nextMilestone(k, lv);
      const hint = next
        ? `<div class="sk-next">→ Lv ${next.lv}: <b>${escape(next.label)}</b> <span class="sk-togo">(${next.lv - lv} to go)</span></div>`
        : '';
      return `<div class="sk">
        <div class="row"><span>${SKILL_ICONS[k] || ''} ${SKILL_LABELS[k]}</span><span class="lv">Lv ${lv}</span></div>
        <div class="bar tiny"><div class="bar-fill xp" style="width:${pct}%"></div></div>
        ${hint}
      </div>`;
    }).join('');
  }
  document.getElementById('hp-num').textContent = Math.max(0, player.hp);
  document.getElementById('hp-max').textContent = player.hpMax;
  document.getElementById('hp-bar').style.width = (100 * player.hp / player.hpMax) + '%';
  // Coin counter — shows total Bramblewood Coin in the bag.
  const coinEl = document.getElementById('coin-num');
  if (coinEl) coinEl.textContent = player.inventory.count('coin').toLocaleString();
}

// Skill bar — refreshes cooldown sweep + lock state. Called once per
// frame from the main loop. Uses CSS variable --cd (0..1) to drive the
// conic-gradient mask, so the actual DOM mutation is one style write per
// slot per frame: cheap. Also refreshes the stamina HUD so we don't add
// a second per-frame DOM scan.
/** Pop a brief celebratory beat when a slot transitions to unlocked.
 *  Triggers an extra-strong fire-flash on the slot, logs a quest line,
 *  and floats a label above the player so the moment reads. */
function celebrateAbilityUnlock(slot, def) {
  if (!player) return;
  // Re-use the existing fire flash but bump it longer.
  if (player.abilityFireT) player.abilityFireT[slot] = 0.9;
  log('quest', `★ ${def.name} unlocked! Press ${slot} to use it.`);
  const wp = new THREE.Vector3(player.pos.x, player.pos.y + 1.7, player.pos.z);
  spawnFloat(wp, `${def.icon} ${def.name}`, 'level');
  spawnHitSparks(new THREE.Vector3(player.pos.x, player.pos.y + 0.6, player.pos.z), {
    count: 22, spread: 1.6, color: 0xffd864, size: 7, life: 0.6,
  });
  import('./core/sfx.js').then(m => m.sfx.chest());
}

// Dynamic context panel (right side). State precedence:
//   COMBAT     — player.combatTarget is alive
//   GATHERING  — player.activeAction is set (chop/mine/fish/forage)
//   INTERACT   — hovering over a named tile (chest/NPC/station)
//   ADVENTURER — default fallback (coin + key stats)
let _cpHoverDesc = null;     // last described hover-tile, set by updateTileHover

function _cpShow(state) {
  for (const id of ['cp-adventurer', 'cp-combat', 'cp-gather', 'cp-interact']) {
    const el = document.getElementById(id);
    if (el) el.style.display = (id === state) ? 'block' : 'none';
  }
}

// UI A — Context-aware skill row picker.
// Tracks the last-XP'd time per skill so we can rotate the cp-adventurer
// stat rows toward whatever the player is *actually doing*. Default trio
// is atk/str/def (the combat triple); when the player has gathered XP in
// non-combat skills within the last ~30s, those skills bubble up.
const _skillLastXpAt = Object.create(null);
const _SKILL_ROW_ICONS = {
  atk: '⚔', str: '💪', def: '🛡', hp: '❤',
  wilds: '🌿', earth: '⛏', cook: '🍲',
  carto: '📜', falconry: '🦅', magic: '✨',
};
const _SKILL_ROW_LABELS = {
  atk: 'Attack', str: 'Strength', def: 'Defence', hp: 'HP',
  wilds: 'Wilds', earth: 'Earth', cook: 'Cooking',
  carto: 'Wayfinding', falconry: 'Falconry', magic: 'Magic',
};
function _pickKeyStatRow() {
  // If any non-combat skill has been XP'd in the last 30s, return its
  // 3 most-recent (or pad with combat skills). Otherwise return the
  // default combat triple.
  const now = performance.now();
  const RECENT_MS = 30_000;
  const recent = Object.entries(_skillLastXpAt)
    .filter(([_, t]) => now - t < RECENT_MS)
    .sort((a, b) => b[1] - a[1])
    .map(([k]) => k);
  if (recent.length === 0) return ['atk', 'str', 'def'];
  // Top 3 recent, dedupe, pad with atk/str/def to 3 if needed.
  const top = [];
  for (const k of recent) { if (!top.includes(k)) top.push(k); if (top.length >= 3) break; }
  for (const k of ['atk', 'str', 'def']) {
    if (top.length >= 3) break;
    if (!top.includes(k)) top.push(k);
  }
  return top;
}

function renderContextPanel() {
  if (!player) return;

  // Always refresh adventurer numbers — cheap, and the panel may switch back.
  const coinEl  = document.getElementById('cp-coin-num');
  if (coinEl) coinEl.textContent = player.inventory?.count?.('coin') ?? 0;
  // Dynamic key-stats trio (UI A) — atk/str/def by default, rotates toward
  // gathering skills when the player has been XP'ing those.
  const keyRow = _pickKeyStatRow();
  for (let i = 0; i < 3; i++) {
    const skill = keyRow[i];
    const iconEl = document.getElementById(`cp-stat-icon-${i + 1}`);
    const nameEl = document.getElementById(`cp-stat-name-${i + 1}`);
    // The value-id stays cp-stat-atk/str/def for backward-compat with the
    // initial layout; we just stuff whatever skill's level into them.
    const valEl  = document.getElementById(['cp-stat-atk', 'cp-stat-str', 'cp-stat-def'][i]);
    if (iconEl) {
      if (_SKILL_HAS_PNG.has(skill)) {
        iconEl.innerHTML = `<img class="cp-stat-icon-img" src="assets/icons/${skill}.png" alt="">`;
      } else {
        iconEl.textContent = _SKILL_ROW_ICONS[skill] || '?';
      }
    }
    if (nameEl) nameEl.textContent = _SKILL_ROW_LABELS[skill] || skill;
    if (valEl)  valEl.textContent  = player.skills?.[skill]?.lv ?? 1;
  }

  // 1) Combat — locked target, alive
  const ct = player.combatTarget;
  if (ct && ct.alive) {
    const nameEl = document.getElementById('cp-combat-name');
    const fillEl = document.getElementById('cp-combat-hp-fill');
    const numEl  = document.getElementById('cp-combat-hp-num');
    const maxEl  = document.getElementById('cp-combat-hp-max');
    const label = (ct.displayName || (ct.kind === 'goblin' ? 'Bramble-imp' : ct.kind || 'Enemy')).toUpperCase();
    if (nameEl) nameEl.textContent = label;
    const pct = (100 * Math.max(0, ct.hp) / Math.max(1, ct.hpMax)) + '%';
    if (fillEl) fillEl.style.width = pct;
    if (numEl)  numEl.textContent = Math.max(0, Math.round(ct.hp));
    if (maxEl)  maxEl.textContent = ct.hpMax;
    // Status icons — bleed gets a 🩸 chip
    const sEl = document.getElementById('cp-combat-status');
    if (sEl) {
      const icons = [];
      if (ct.bleed && ct.bleed.ticksLeft > 0) icons.push('<span class="cp-status-icon" title="Bleeding">🩸</span>');
      if (ct.staggered) icons.push('<span class="cp-status-icon" title="Staggered">⚡</span>');
      sEl.innerHTML = icons.length ? icons.join('') : '<span class="cp-status-empty">—</span>';
    }
    _cpShow('cp-combat');
    return;
  }

  // 2) Gathering — player has an active action
  const aa = player.activeAction;
  if (aa && aa.kind) {
    const nameEl = document.getElementById('cp-gather-name');
    const fillEl = document.getElementById('cp-gather-fill');
    const numEl  = document.getElementById('cp-gather-num');
    const maxEl  = document.getElementById('cp-gather-max');
    const toolEl = document.getElementById('cp-gather-tool');
    const effEl  = document.getElementById('cp-gather-eff');
    if (nameEl) nameEl.textContent = (aa.label || aa.kind).toUpperCase();
    const cur = aa.progress ?? 0;
    const max = aa.total ?? 100;
    const pct = (100 * cur / Math.max(1, max)) + '%';
    if (fillEl) fillEl.style.width = pct;
    if (numEl)  numEl.textContent = Math.max(0, Math.round(cur));
    if (maxEl)  maxEl.textContent = max;
    if (toolEl) toolEl.textContent = aa.tool || '—';
    if (effEl)  effEl.textContent = aa.effectiveness != null ? (aa.effectiveness + '%') : '—';
    _cpShow('cp-gather');
    return;
  }

  // 3) Interact — set by updateTileHover when describeTile returns a label
  if (_cpHoverDesc) {
    const nameEl = document.getElementById('cp-interact-name');
    const descEl = document.getElementById('cp-interact-desc');
    const btnEl  = document.getElementById('cp-interact-btn');
    if (nameEl) nameEl.textContent = (_cpHoverDesc.name || 'OBJECT').toUpperCase();
    if (descEl) descEl.textContent = _cpHoverDesc.desc || '—';
    if (btnEl)  btnEl.textContent  = _cpHoverDesc.action || 'Examine';
    _cpShow('cp-interact');
    return;
  }

  // 4) Default — Adventurer
  _cpShow('cp-adventurer');
}

function showAbilityTip(slotEl, tip) {
  if (!tip) return;
  const slot = slotEl.dataset.slot;
  let html = '';
  if (slot === 'dodge') {
    const cd = player.dodgeCd > 0 ? player.dodgeCd : 0;
    html = `<div class="sbt-name">Dodge</div>
      <div class="sbt-tag">UTILITY · V or Space</div>
      <div class="sbt-desc">A 1-tile dash with brief invulnerability frames. Drains stamina; can be used to parry red attacks if timed at impact.</div>
      <div class="sbt-cd">⏱ 0.6s cooldown${cd > 0.05 ? `  ·  ${cd.toFixed(1)}s left` : ''}</div>`;
  } else {
    const num = +slot;
    const id = player.actionBar?.[num - 1];
    if (!id) {
      html = `<div class="sbt-name">Slot ${num}</div>
        <div class="sbt-tag">EMPTY</div>
        <div class="sbt-desc">Open the Abilities Book (V) to bind an action here.</div>`;
    } else {
      const a = getAction(id);
      if (!a) { tip.classList.remove('show'); return; }
      const locked = !actionUnlocked(player, id);
      const key = getSlotKey(num) || num;
      let cost = '';
      if (a.cost?.stamina) cost += `<div>⚡ ${a.cost.stamina} stamina</div>`;
      if (a.cost?.runes) {
        for (const [k, n] of Object.entries(a.cost.runes)) {
          cost += `<div>${ITEMS[k]?.icon || '·'} ${n}× ${ITEMS[k]?.name || k}</div>`;
        }
      }
      const cd = player.actionCd?.[id] || 0;
      const cooling = cd > 0.05 ? `  ·  ${cd.toFixed(1)}s left` : '';
      html = `<div class="sbt-name">${escape(a.name)}</div>
        <div class="sbt-tag">${a.kind.toUpperCase()} · ${a.reqSkill.toUpperCase()} ${a.reqLevel} · key [${String(key).toUpperCase()}]</div>
        <div class="sbt-desc">${escape(a.desc || '')}</div>
        ${cost ? `<div class="sbt-cost">${cost}</div>` : ''}
        <div class="sbt-cd">⏱ ${a.cooldown}s cooldown${cooling}</div>
        ${locked ? `<div class="sbt-locked">Locked — needs ${a.reqSkill.toUpperCase()} ${a.reqLevel}.</div>` : ''}`;
    }
  }
  tip.innerHTML = html;
  tip.classList.add('show');
  positionAbilityTip(slotEl, tip);
}
function positionAbilityTip(slotEl, tip) {
  if (!tip) return;
  const r = slotEl.getBoundingClientRect();
  // Anchor centered on the slot's top edge, lifted by an 8px gap.
  tip.style.left = `${r.left + r.width / 2}px`;
  tip.style.top  = `${r.top - 8}px`;
}

function renderSkillBar(dt = 0.016) {
  renderContextPanel();
  // Boss HP bar — only visible when the locked combat target is a boss.
  // Dim/hide the moment the target is cleared, dies, or swaps to a non-boss.
  const bossBar = document.getElementById('boss-bar');
  if (bossBar && player) {
    const t = player.combatTarget;
    const isBossTarget = t && t.alive && t.isBoss;
    bossBar.classList.toggle('boss-bar-show', !!isBossTarget);
    if (isBossTarget) {
      const nameEl = document.getElementById('boss-bar-name');
      const numEl  = document.getElementById('boss-bar-num');
      const fillEl = document.getElementById('boss-bar-fill');
      const label = t.displayName || (t.kind === 'goblin' ? 'Bramble-imp' : t.kind);
      if (nameEl && nameEl.textContent !== label) nameEl.textContent = label;
      // Smooth the bar fill so each chunk of damage drains over ~250ms.
      const target = Math.max(0, t.hp);
      if (typeof t._shownHP !== 'number') t._shownHP = target;
      const k = 1 - Math.exp(-dt * 8);
      t._shownHP += (target - t._shownHP) * k;
      if (Math.abs(target - t._shownHP) < 0.1) t._shownHP = target;
      if (numEl)  numEl.textContent = `${Math.round(t._shownHP)} / ${t.hpMax}`;
      if (fillEl) fillEl.style.width = (100 * Math.max(0, t._shownHP) / Math.max(1, t.hpMax)) + '%';
    }
  }

  // Combo counter chip — visible only while a combo is in progress.
  // Pulses on increments by detoggling+reapplying the animation class.
  const chip = document.getElementById('combo-chip');
  if (chip && player) {
    const c = player.comboCount || 0;
    if (c > 0) {
      chip.classList.remove('combo-hidden');
      const numEl = chip.querySelector('#combo-count');
      if (numEl && +numEl.textContent !== c) {
        numEl.textContent = c;
        chip.classList.remove('combo-pulse');
        void chip.offsetWidth;
        chip.classList.add('combo-pulse');
      }
    } else {
      chip.classList.add('combo-hidden');
      chip.classList.remove('combo-pulse');
    }
  }

  // HP bar — smoothed so damage drains the bar over ~250ms (ease-out)
  // and regen fills at the same rate. Mirrors the value into BOTH the
  // legacy hp-* nodes (kept alive in the hidden #panel for back-compat)
  // AND the new wireframe pb-hp-* nodes in the top-left HUD bar block.
  const hpBar = document.getElementById('hp-bar');
  const hpNum = document.getElementById('hp-num');
  const pbHpFill = document.getElementById('pb-hp-fill');
  const pbHpNum  = document.getElementById('pb-hp-num');
  const pbHpMax  = document.getElementById('pb-hp-max');
  if (player) {
    const target = Math.max(0, player.hp ?? 0);
    if (typeof player._shownHP !== 'number') player._shownHP = target;
    const k = 1 - Math.exp(-dt * 9);
    player._shownHP += (target - player._shownHP) * k;
    if (Math.abs(target - player._shownHP) < 0.05) player._shownHP = target;
    const max = Math.max(1, Math.floor(player.hpMax ?? 1));
    const shown = player._shownHP;
    const pct = (100 * Math.max(0, shown) / max) + '%';
    const num = Math.max(0, Math.round(shown));
    if (hpBar) hpBar.style.width = pct;
    if (hpNum) hpNum.textContent = num;
    if (pbHpFill) pbHpFill.style.width = pct;
    if (pbHpNum)  pbHpNum.textContent = num;
    if (pbHpMax)  pbHpMax.textContent = max;
  }

  // Stamina bar — smoothed identically to HP, mirrored into both legacy
  // nodes and the new wireframe pb-sta-* HUD block.
  const staBar = document.getElementById('sta-bar');
  const staNum = document.getElementById('sta-num');
  const staMaxEl = document.getElementById('sta-max');
  const pbStaFill = document.getElementById('pb-sta-fill');
  const pbStaNum  = document.getElementById('pb-sta-num');
  const pbStaMax  = document.getElementById('pb-sta-max');
  if (player) {
    const target = Math.max(0, player.stamina ?? 0);
    if (typeof player._shownStamina !== 'number') player._shownStamina = target;
    const k = 1 - Math.exp(-dt * 9);
    player._shownStamina += (target - player._shownStamina) * k;
    if (Math.abs(target - player._shownStamina) < 0.05) player._shownStamina = target;
    const cur = Math.max(0, Math.floor(player._shownStamina));
    const max = Math.max(1, Math.floor(player.staminaMax ?? 100));
    const pct = (100 * cur / max) + '%';
    if (staBar) staBar.style.width = pct;
    if (staNum) staNum.textContent = cur;
    if (staMaxEl) staMaxEl.textContent = max;
    if (pbStaFill) pbStaFill.style.width = pct;
    if (pbStaNum)  pbStaNum.textContent = cur;
    if (pbStaMax)  pbStaMax.textContent = max;
    const wrap = staBar?.parentElement;
    if (wrap) {
      wrap.classList.toggle('sta-pulse', (player.staminaPulseT ?? 0) > 0);
      wrap.classList.toggle('sta-exhausted', (player.exhaustedT ?? 0) > 0);
    }
    // Also flag the new pb-track on exhaust/pulse so the wireframe HUD
    // reads the same state.
    const pbTrack = pbStaFill?.parentElement;
    if (pbTrack) {
      pbTrack.classList.toggle('sta-pulse', (player.staminaPulseT ?? 0) > 0);
      pbTrack.classList.toggle('sta-exhausted', (player.exhaustedT ?? 0) > 0);
    }
  }

  const bar = document.getElementById('skillbar');
  if (!bar) return;
  // One-time wiring of ability-tooltip hover. Slots are static DOM (their
  // contents update each frame, but the elements themselves don't churn),
  // so a single delegated set of listeners is enough — re-attaching every
  // frame would leak.
  if (!bar._sbTipBound) {
    bar._sbTipBound = true;
    const tip = document.getElementById('sb-tip');
    bar.querySelectorAll('.sb-slot[data-slot]').forEach(el => {
      el.addEventListener('mouseenter', () => showAbilityTip(el, tip));
      el.addEventListener('mousemove',  () => positionAbilityTip(el, tip));
      el.addEventListener('mouseleave', () => tip?.classList.remove('show'));
    });
  }
  bar.querySelectorAll('.sb-slot[data-slot]').forEach(el => {
    const slot = el.dataset.slot;
    const cdTextEl = el.querySelector('.sb-cdtext');
    // "Active" green-border hint follows the most recently fired ability.
    el.classList.toggle('sb-active', String(_activeSlot) === slot);
    if (slot === 'dodge') {
      const cd = player.dodgeCd > 0 ? player.dodgeCd / 0.6 : 0;
      el.style.setProperty('--cd', String(Math.min(1, Math.max(0, cd))));
      const cooling = player.dodgeCd > 0.05;
      el.classList.toggle('sb-cooling', cooling);
      if (cdTextEl) cdTextEl.textContent = cooling ? player.dodgeCd.toFixed(1) : '';
      return;
    }
    const num = +slot;
    const id = player.actionBar?.[num - 1];
    const iconEl = el.querySelector('.sb-icon');
    if (!id) {
      // Empty slot — show placeholder, prompt user to bind via Spellbook
      el.classList.add('sb-empty');
      el.classList.remove('sb-locked');
      el.classList.remove('sb-cooling');
      el.classList.remove('sb-utility');
      if (iconEl && iconEl.textContent !== '·') iconEl.textContent = '·';
      el.title = `Slot ${num} empty — open the Abilities Book (V) to bind an action.`;
      if (cdTextEl) cdTextEl.textContent = '';
      el.style.setProperty('--cd', '0');
      return;
    }
    el.classList.remove('sb-utility');
    el.classList.remove('sb-empty');
    const a = getAction(id);
    if (!a) return;
    if (iconEl && iconEl.textContent !== a.icon) iconEl.textContent = a.icon;
    const locked = !actionUnlocked(player, id);
    const prev = el.dataset.locked;
    if (prev === '1' && !locked && a.kind === 'melee' && a._ability) celebrateAbilityUnlock(num, a._ability);
    el.dataset.locked = locked ? '1' : '0';
    el.classList.toggle('sb-locked', locked);
    if (locked) {
      el.title = `${a.name} — needs ${a.reqSkill.toUpperCase()} ${a.reqLevel}`;
      el.style.setProperty('--cd', '1');
      el.classList.remove('sb-cooling');
      if (cdTextEl) cdTextEl.textContent = '';
      return;
    }
    // Tooltip with cost summary
    let costStr = '';
    if (a.cost?.stamina) costStr += ` · ${a.cost.stamina} sta`;
    if (a.cost?.runes) costStr += ' · ' + Object.entries(a.cost.runes).map(([k, n]) => `${n}× ${ITEMS[k]?.name || k}`).join(' + ');
    el.title = `${a.name} (${a.cooldown}s${costStr}) — ${a.desc}`;
    // Per-action cooldown stored on player.actionCd[id]
    const cd = player.actionCd?.[id] || 0;
    const ratio = cd > 0 ? Math.min(1, cd / a.cooldown) : 0;
    el.style.setProperty('--cd', String(ratio));
    const cooling = cd > 0.05;
    el.classList.toggle('sb-cooling', cooling);
    if (cdTextEl) cdTextEl.textContent = cooling ? cd.toFixed(1) : '';
    // Brief activation flash — bright border decays over 0.25s.
    const fireT = player.actionFireT?.[id] || 0;
    el.classList.toggle('sb-firing', fireT > 0);
  });
}

// Item icon helper — returns either a rendered PNG <img> (if available) or
// the emoji fallback. Browsers cache the PNG URL so the failed-load case
// only happens once per missing item.
// Per-scope palette for the inline orb icon. `core` is the glowing center,
// `rim` is the darker shell, `accent` powers the inner sparkle band.
const _ORB_PALETTE = {
  null:        { core: '#f4ead8', rim: '#9b8a64', accent: '#fff7d6' }, // blank/hollow
  snug:        { core: '#ffd47a', rim: '#a8732a', accent: '#fff3c0' },
  delve:       { core: '#d8b48a', rim: '#5a3d22', accent: '#f4e0b8' },
  hollow:      { core: '#7c8aa6', rim: '#1f2638', accent: '#a6b4d4' },
  briar_maze:  { core: '#9ed870', rim: '#2c5a1f', accent: '#d4f0a8' },
  sunken_hut:  { core: '#7ec8d8', rim: '#244e62', accent: '#bce6f0' },
};

/** Inline-SVG orb icon. The orb is drawn with a radial gradient, a
 *  glossy highlight, an inner accent ring, and tier-pip dots. Color
 *  follows the chart scope (or a neutral palette for blank orbs).
 *  Looks like a glowing artefact instead of a flat emoji. */
function _orbSvgIcon(def) {
  const scope = def.chart?.scope ?? null;
  const tier = def.chart?.tier ?? 0;
  const p = _ORB_PALETTE[scope] || _ORB_PALETTE[null];
  const id = 'orb-' + Math.random().toString(36).slice(2, 8);
  // Tier pips along the bottom — 1 dot for tier 1, 3 for tier 3.
  let pips = '';
  for (let i = 0; i < tier; i++) {
    const x = 18 + (i - (tier - 1) / 2) * 4;
    pips += `<circle cx="${x}" cy="33" r="1.1" fill="${p.accent}" opacity="0.85" />`;
  }
  return `<svg class="orb-icon" viewBox="0 0 36 36" width="100%" height="100%" aria-hidden="true">
    <defs>
      <radialGradient id="g${id}" cx="38%" cy="34%" r="62%">
        <stop offset="0%" stop-color="${p.accent}" />
        <stop offset="45%" stop-color="${p.core}" />
        <stop offset="100%" stop-color="${p.rim}" />
      </radialGradient>
      <radialGradient id="h${id}" cx="40%" cy="32%" r="22%">
        <stop offset="0%" stop-color="rgba(255,255,255,0.85)" />
        <stop offset="100%" stop-color="rgba(255,255,255,0)" />
      </radialGradient>
    </defs>
    <circle cx="18" cy="18" r="14.5" fill="url(#g${id})" stroke="${p.rim}" stroke-width="0.7" />
    <circle cx="18" cy="18" r="11" fill="none" stroke="${p.accent}" stroke-width="0.4" opacity="0.55" />
    <ellipse cx="14.5" cy="13" rx="5" ry="3.4" fill="url(#h${id})" />
    ${pips}
  </svg>`;
}

function itemIconHTML(id, def) {
  // Orb items (charts + the blank) render as an inline SVG with a radial-
  // gradient glow per scope — the visual the player sees in inventory and
  // on the bar.
  if (def.chart || id === 'chart_blank') return _orbSvgIcon(def);
  return `<img class="item-img" src="assets/icons/${id}.png" alt="${def.icon}"
    onerror="this.outerHTML='${def.icon}'">`;
}

// Per-slot last-seen state, so renderInv can detect qty/id increments
// and apply a pulse class to changed slots after the innerHTML rebuild.
const _lastInvSnapshot = [];

function renderInv() {
  hideGearTip();   // re-render kills the hovered slot before mouseleave fires
  const el = document.getElementById('inv');
  let html = '';
  // Build the new HTML and remember which slots gained or grew so we can
  // pulse them. A slot "grew" if its id matches the previous snapshot but
  // qty went up; "appeared" if there was nothing there before.
  const pulseSlots = new Set();
  for (let i = 0; i < CONFIG.inventory.slots; i++) {
    const s = player.inventory.slots[i];
    const prev = _lastInvSnapshot[i];
    if (s) {
      if (!prev || prev.id !== s.id || (s.qty || 1) > (prev.qty || 1)) pulseSlots.add(i);
      const def = ITEMS[s.id];
      const equipped = Object.values(player.inventory.equipped).includes(s.id) ? ' ★' : '';
      // tier shape — explicit `tier` field wins; fall back to chart/lore/food
      // categories so the slot border still color-codes thematically.
      const tier = def.chart ? 'orb'
                 : def.lore  ? 'lore'
                 : def.food  ? 'food'
                 : (def.tier || (def.equipBonus ? 'common' : ''));
      html += `<div class="slot" data-idx="${i}" data-tier="${tier}" title="${def.name}${equipped}">
        <div class="icon">${itemIconHTML(s.id, def)}</div>${s.qty > 1 ? s.qty : ''}</div>`;
    } else {
      html += '<div class="slot"></div>';
    }
    _lastInvSnapshot[i] = s ? { id: s.id, qty: s.qty || 1 } : null;
  }
  el.innerHTML = html;
  // Apply the pulse class after innerHTML so the CSS animation runs on
  // the new DOM nodes. Removed automatically after the animation ends.
  for (const idx of pulseSlots) {
    const slot = el.querySelector(`.slot[data-idx="${idx}"]`);
    if (slot) {
      slot.classList.add('slot-bump');
      slot.addEventListener('animationend', () => slot.classList.remove('slot-bump'), { once: true });
    }
  }
  el.querySelectorAll('.slot[data-idx]').forEach(slot => {
    slot.addEventListener('click', () => {
      const idx = +slot.dataset.idx;
      const s = player.inventory.slots[idx];
      // Charts: left-click opens the dungeon directly.
      if (s && ITEMS[s.id]?.chart) {
        openChartFromInventory(idx);
        return;
      }
      // Falcon's Whistle: special use-on-click → scout pulse.
      if (s && s.id === 'falcons_whistle') {
        useFalconsWhistle();
        return;
      }
      // Lore parchment: read in a dialog; doesn't consume the parchment.
      if (s && ITEMS[s.id]?.lore) {
        readLoreParchment(s.id);
        return;
      }
      const r = player.inventory.use(idx, player);
      if (r) {
        if (r.kind === 'equip')   log('hint', `Equipped ${ITEMS[r.id].name}.`);
        else if (r.kind === 'eat') {
          log('hint', `Ate ${ITEMS[r.id].name}: +${r.heal} HP.`);
          spawnHealFlash(r.heal);
        }
        else if (r.kind === 'full_hp') log('hint', 'You are at full health.');
        renderEquipped(); renderInv(); renderStats();
      }
    });
    slot.addEventListener('contextmenu', e => {
      e.preventDefault();
      const idx = +slot.dataset.idx;
      const s = player.inventory.slots[idx];
      if (!s) return;
      showInventoryMenu(idx, s, e.clientX, e.clientY);
    });
    slot.addEventListener('mouseenter', e => {
      const idx = +slot.dataset.idx;
      const s = player.inventory.slots[idx];
      if (!s) return;
      showGearTip(s, e.currentTarget.getBoundingClientRect());
    });
    slot.addEventListener('mouseleave', hideGearTip);
  });
}

const _gearTip = () => document.getElementById('gear-tip');

function showGearTip(slot, anchorRect) {
  const tip = _gearTip();
  if (!tip) return;
  const def = ITEMS[slot.id];
  if (!def) return;
  const html = buildGearTipHTML(def, slot.qty);
  if (!html) { hideGearTip(); return; }
  tip.innerHTML = html;
  tip.style.display = 'block';
  // Anchor: prefer left of the slot; fall back to right if it overflows.
  const tw = tip.offsetWidth, th = tip.offsetHeight;
  let x = anchorRect.left - tw - 8;
  if (x < 8) x = anchorRect.right + 8;
  let y = anchorRect.top + (anchorRect.height / 2) - (th / 2);
  y = Math.max(8, Math.min(window.innerHeight - th - 8, y));
  tip.style.left = x + 'px';
  tip.style.top  = y + 'px';
}

function hideGearTip() {
  const tip = _gearTip();
  if (tip) tip.style.display = 'none';
}

function buildGearTipHTML(def, qty) {
  const sub = def.slot ? def.slot : (def.food ? 'food' : (def.chart ? 'chart' : (def.tool ? 'tool' : '')));
  const head = `
    <div class="gt-name">${def.name}${qty > 1 ? ' ×' + qty : ''}</div>
    ${sub ? `<div class="gt-sub">${sub}${def.tier ? ' · ' + def.tier : ''}</div>` : ''}
  `;
  // Gear → comparison table vs currently equipped piece in same slot
  if (def.slot && def.equipBonus) {
    const curId = player.inventory.equipped[def.slot];
    const cur = curId ? ITEMS[curId] : null;
    const stats = ['atk', 'str', 'def'];
    const rows = stats.map(stat => {
      const newV = (def.equipBonus[stat] | 0);
      const oldV = (cur?.equipBonus?.[stat] | 0);
      const d = newV - oldV;
      const cls = d > 0 ? 'up' : d < 0 ? 'down' : 'same';
      const sign = d > 0 ? '+' : '';
      const arrow = d > 0 ? '▲' : d < 0 ? '▼' : '·';
      return `<div class="gt-row">
        <span class="stat">${stat}</span>
        <span><span>${newV}</span> <span class="delta ${cls}"><span class="delta-arrow">${arrow}</span>${sign}${d}</span></span>
      </div>`;
    }).join('');
    const reqLine = (def.reqSkill && def.reqLevel)
      ? `<div class="gt-foot">Requires ${def.reqLevel} ${def.reqSkill}</div>` : '';
    const curLine = cur
      ? `<div class="gt-foot">vs equipped: ${cur.name}</div>`
      : `<div class="gt-foot">Nothing equipped in ${def.slot}</div>`;
    return head + rows + (reqLine ? `<hr class="gt-hr">${reqLine}` : '') + `<hr class="gt-hr">${curLine}`;
  }
  // Food → heal preview
  if (def.food?.heal) {
    return head + `<div class="gt-row"><span class="stat">heal</span><span class="delta up">+${def.food.heal}</span></div>` +
      (def.desc ? `<hr class="gt-hr"><div class="gt-foot">${def.desc}</div>` : '');
  }
  // Everything else: just description
  if (def.desc) return head + `<div class="gt-foot" style="font-style:normal;color:var(--text)">${def.desc}</div>`;
  return head;
}

/** Show the shared ctx-menu populated with item-specific actions. */
function showInventoryMenu(idx, slot, screenX, screenY) {
  const def = ITEMS[slot.id];
  const items = [];
  // Equip / Eat — primary actions
  const gearSlot = def.slot;
  if (gearSlot) {
    items.push({ label: `<b>Equip</b> <span class="ctx-target">${def.name}</span>`, action: () => {
      const r = player.inventory.use(idx, player);
      if (r?.kind === 'equip') log('hint', `Equipped ${ITEMS[r.id].name}.`);
      renderEquipped(); renderInv(); renderStats();
    }});
  }
  if (def.food) {
    items.push({ label: `<b>Eat</b> <span class="ctx-target">${def.name}</span>`, action: () => {
      const r = player.inventory.use(idx, player);
      if (r?.kind === 'eat') {
        log('hint', `Ate ${ITEMS[r.id].name}: +${r.heal} HP.`);
        spawnHealFlash(r.heal);
      } else if (r?.kind === 'full_hp') log('hint', 'You are at full health.');
      renderInv(); renderStats();
    }});
  }
  if (def.chart) {
    items.push({ label: `<b>Open</b> <span class="ctx-target">${def.name}</span>`, action: () => {
      openChartFromInventory(idx);
    }});
  }
  if (def.lore) {
    items.push({ label: `<b>Read</b> <span class="ctx-target">${def.name}</span>`, action: () => {
      readLoreParchment(slot.id);
    }});
  }
  // Always available
  items.push({ label: `<b>Drop</b> <span class="ctx-target">${def.name}</span>`, action: () => {
    const dropped = player.inventory.dropSlot(idx);
    if (dropped) log('hint', `Dropped ${ITEMS[dropped.id].name}${dropped.qty > 1 ? ' x' + dropped.qty : ''}.`);
    renderInv();
  }});
  items.push({ label: `<b>Examine</b> <span class="ctx-target">${def.name}</span>`, action: () => {
    log('hint', def.desc || def.name);
  }});
  // Render via the shared ctx-menu
  ctxTitleEl.innerHTML = `${itemIconHTML(slot.id, def)} ${def.name}${slot.qty > 1 ? ' x' + slot.qty : ''}`;
  ctxItemsEl.innerHTML = '';
  for (const it of items) {
    const div = document.createElement('div');
    div.className = 'ctx-item';
    div.innerHTML = it.label;
    div.addEventListener('click', () => {
      hideContextMenu();
      it.action();
    });
    ctxItemsEl.appendChild(div);
  }
  const sx = Math.min(screenX, window.innerWidth  - 200);
  const sy = Math.min(screenY, window.innerHeight - 220);
  ctxMenu.style.left = sx + 'px';
  ctxMenu.style.top  = sy + 'px';
  ctxMenu.style.display = 'block';
}

/** Add right-click on equipped slots → option to unequip. */
function attachEquippedRightClick() {
  const el = document.getElementById('equipped');
  if (!el) return;
  el.querySelectorAll('.eq-slot').forEach((row, idx) => {
    row.addEventListener('contextmenu', e => {
      e.preventDefault();
      const gearSlot = ['weapon', 'body', 'helm', 'shield'][idx];
      const id = player.inventory.equipped[gearSlot];
      if (!id) return;
      const def = ITEMS[id];
      ctxTitleEl.innerHTML = `${itemIconHTML(id, def)} ${def.name}`;
      ctxItemsEl.innerHTML = '';
      const div = document.createElement('div');
      div.className = 'ctx-item';
      div.innerHTML = `<b>Unequip</b> <span class="ctx-target">${def.name}</span>`;
      div.addEventListener('click', () => {
        hideContextMenu();
        const r = player.inventory.unequip(gearSlot);
        if (r?.kind === 'unequipped') log('hint', `Unequipped ${ITEMS[r.id].name}.`);
        else if (r?.kind === 'no_room') log('hint', 'No room in inventory.');
        renderEquipped(); renderInv(); renderStats();
      });
      ctxItemsEl.appendChild(div);
      const sx = Math.min(e.clientX, window.innerWidth  - 200);
      const sy = Math.min(e.clientY, window.innerHeight - 100);
      ctxMenu.style.left = sx + 'px';
      ctxMenu.style.top  = sy + 'px';
      ctxMenu.style.display = 'block';
    });
  });
}

function renderEquipped() {
  const el = document.getElementById('equipped');
  if (!el) return;
  const slots = ['weapon', 'body', 'helm', 'shield'];
  el.innerHTML = slots.map(s => {
    const id = player.inventory.equipped[s];
    if (!id) return `<div class="eq-slot"><span>${s}</span><span class="empty">—</span></div>`;
    return `<div class="eq-slot"><span>${s}</span><span>${itemIconHTML(id, ITEMS[id])} ${ITEMS[id].name}</span></div>`;
  }).join('');
  attachEquippedRightClick();
}

function renderCombat() {
  const el = document.getElementById('combat-target');
  if (!el) return;
  const t = player.combatTarget;
  if (!t || !t.alive) {
    el.classList.add('ct-empty');
    el.textContent = 'No target';
    return;
  }
  el.classList.remove('ct-empty');
  const name = t.kind === 'goblin' ? 'Bramble-imp' : 'Cow';
  const ratio = Math.max(0, t.hp / t.hpMax);
  el.innerHTML = `
    <div class="ct-name">⚔ ${name}</div>
    <div class="ct-hp-row"><span>HP</span><span>${Math.max(0, Math.floor(t.hp))}/${t.hpMax}</span></div>
    <div class="bar"><div class="bar-fill hp" style="width:${(ratio * 100).toFixed(0)}%"></div></div>
  `;
}

// hook combat-style buttons. Two sets of these exist after the wireframe
// redesign — the old ones in the hidden #panel and the new ones in
// #cp-combat. Sync by data-style so both sets show the same active flag.
document.querySelectorAll('.cs-btn').forEach(btn => {
  btn.addEventListener('click', () => {
    const style = btn.dataset.style;
    player.combatStyle = style;
    document.querySelectorAll('.cs-btn').forEach(b => {
      b.classList.toggle('cs-active', b.dataset.style === style);
    });
    log('hint', `Combat style: ${style}.`);
  });
});

function renderQuest() {
  const el = document.getElementById('quest');
  el.innerHTML = questSummary(player.quest).map(s => {
    const mark = s.state === 'done' ? '✓' : (s.state === 'active' ? '▶' : '·');
    return `<div class="step ${s.state}">${mark} ${escape(s.text)}</div>`;
  }).join('');
}

// ---------- AUDIO (Web Audio API) ----------
// Tonal feedback for XP gain + level-up. Lazy-init on first interaction
// so we don't hit autoplay restrictions.
let audioCtx = null;
function ensureAudio() {
  if (!audioCtx) {
    const C = window.AudioContext || window.webkitAudioContext;
    if (C) audioCtx = new C();
  }
  return audioCtx;
}
window.addEventListener('pointerdown', ensureAudio, { once: true });
window.addEventListener('keydown',     ensureAudio, { once: true });

const SKILL_PITCHES = {
  atk:  660,  // E5
  str:  587,  // D5
  def:  784,  // G5
  hp:   880,  // A5
  cook: 988,  // B5
};

function playXpTone(skill) {
  const ac = ensureAudio(); if (!ac) return;
  const t = ac.currentTime;
  const o = ac.createOscillator();
  const g = ac.createGain();
  o.type = 'triangle';
  o.frequency.setValueAtTime(SKILL_PITCHES[skill] || 660, t);
  g.gain.setValueAtTime(0.05, t);
  g.gain.exponentialRampToValueAtTime(0.001, t + 0.10);
  o.connect(g); g.connect(ac.destination);
  o.start(t);
  o.stop(t + 0.12);
}

// Per-skill level-up jingles. Different chord shapes per family so the
// player hears which thing leveled before the modal arrives.
//   combat (atk/str/def/hp): bright major arpeggio C5-E5-G5-C6
//   craft  (cook/smith)     : warm fifth-up C5-G5-E5-C6 (heroic-tilted)
//   gather (wc/mine/fish/   : soft pentatonic D5-F#5-A5-D6 (folk-y)
//          forage)
//   carto                   : open-fifth ascending D5-A5-D6-A6 (mystical)
const _JINGLE_FAMILIES = {
  combat:  [523.25, 659.25, 783.99, 1046.50],
  craft:   [523.25, 783.99, 659.25, 1046.50],
  gather:  [587.33, 739.99, 880.00, 1174.66],
  carto:   [587.33, 880.00, 1174.66, 1760.00],
};
const _SKILL_FAMILY = {
  atk: 'combat', str: 'combat', def: 'combat', hp: 'combat',
  cook: 'craft', earth: 'craft',
  wilds: 'gather',
  carto: 'carto',
};

function playLevelUpJingle(skill) {
  const ac = ensureAudio(); if (!ac) return;
  const family = _SKILL_FAMILY[skill] || 'combat';
  const notes = _JINGLE_FAMILIES[family];
  notes.forEach((freq, i) => {
    const t = ac.currentTime + i * 0.10;
    const o = ac.createOscillator();
    const g = ac.createGain();
    o.type = 'triangle';
    o.frequency.setValueAtTime(freq, t);
    g.gain.setValueAtTime(0.10, t);
    g.gain.exponentialRampToValueAtTime(0.001, t + 0.22);
    o.connect(g); g.connect(ac.destination);
    o.start(t);
    o.stop(t + 0.24);
  });
}

// XP feedback: floating popup + tone + animated bar fill (CSS transition).
// Per-skill xp accumulator so sub-1 ticks (e.g. 0.33 hp xp) coalesce into
// visible popups — otherwise lots of "0" popups would clutter.
const _xpAccum = { atk: 0, str: 0, def: 0, hp: 0, wilds: 0, earth: 0, cook: 0, carto: 0, falconry: 0, magic: 0 };
setXpHook((p, skill, amount, ctx) => {
  // Track recency for UI A (context-aware key-stats row picker).
  _skillLastXpAt[skill] = performance.now();
  _xpAccum[skill] = (_xpAccum[skill] || 0) + amount;
  const whole = Math.floor(_xpAccum[skill]);
  if (whole >= 1) {
    _xpAccum[skill] -= whole;
    const wp = (ctx && ctx.worldPos)
      ? ctx.worldPos
      : new THREE.Vector3(p.pos.x, p.pos.y + 1.8, p.pos.z);
    spawnFloat(wp, `+${whole} ${skill.toUpperCase()}`, 'xp');
  }
  playXpTone(skill);
  renderStats();
});

setLevelUpHook((p, skill) => {
  const v = new THREE.Vector3(p.pos.x, p.pos.y + 1.8, p.pos.z);
  const label = (SKILL_LABELS[skill] || skill).toUpperCase();
  const newLv = p.skills[skill].lv;
  // Big gold floater over the player + a bold log entry. The modal below
  // ONLY fires when this level-up crossed a milestone — every-level modals
  // would interrupt the player too aggressively. Milestone modals (UI D)
  // are the celebratory beats: ability unlocks, recipe access, gear tiers.
  spawnFloat(v, `LEVEL UP! ${label} ${newLv}`, 'level');
  log('skill', `🎉 ${label} reached level ${newLv}.`);
  playLevelUpJingle(skill);
  renderStats();
  // UI D — only show the dialog modal when a milestone unlock actually
  // crossed. We compare prev = newLv - 1 since the level just incremented.
  const milestone = crossedMilestone(skill, newLv - 1, newLv);
  if (milestone) {
    log('skill', `★ Unlocked: ${milestone.label} — ${milestone.desc}`);
    showLevelUp({
      skillLabel: `${SKILL_LABELS[skill] || skill} — ${milestone.label}`,
      level: newLv,
      iconHTML: SKILL_ICONS[skill] || '',
    });
  }
});

// ---------- DISPATCH ----------
function isBlocked(tx, ty, exclude) {
  // In a dungeon: only the dungeon's wall grid + enemy tiles block.
  if (dungeon.active && dungeon.layout) {
    if (dungeon.layout.blocked(tx, ty)) return true;
    for (const e of enemies) if (e !== exclude && e.alive && e.x === tx && e.y === ty) return true;
    return false;
  }
  if (world.isTerrainBlocked(tx, ty)) return true;
  if (world.cookSpawn && world.cookSpawn.x === tx && world.cookSpawn.y === ty) return true;
  if (world.firePos && world.firePos.x === tx && world.firePos.y === ty) return true;
  if (MIRROR_TILE.x === tx && MIRROR_TILE.y === ty) return true;
  if (CHARTMAKER_TILE.x === tx && CHARTMAKER_TILE.y === ty) return true;
  if (HERBALIST_TILE.x === tx && HERBALIST_TILE.y === ty) return true;
  for (const v of VILLAGE_TILES) if (v.x === tx && v.y === ty) return true;
  for (const t of world.trees) if (t.x === tx && t.y === ty && !t.depleted) return true;
  if (world.oreNodes) {
    for (const n of world.oreNodes) if (n.x === tx && n.y === ty && !n.depleted) return true;
  }
  for (const e of enemies) if (e !== exclude && e.alive && e.x === tx && e.y === ty) return true;
  return false;
}

function tryFish(tx, ty) {
  if (player.attackCd > 0) return true;
  if (world.tileGrid[ty]?.[tx] !== 'water') return true;
  let hasRod = false;
  for (const s of player.inventory.slots) {
    if (s && ITEMS[s.id].tool === 'rod') { hasRod = true; break; }
  }
  if (!hasRod) { log('hint', 'You need a fishing rod.'); return true; }
  player.attackCd = 80;            // ~1.3s between casts
  triggerAttack(player);           // rod-cast swing reuses the attack motion
  const wp = new THREE.Vector3(tx + 0.5, 0.6, ty + 0.5);
  // 60% catch chance at lv 1, +3% per level (cap 95%)
  const catchChance = Math.min(0.95, 0.60 + 0.03 * (player.skills.wilds.lv - 1));
  if (Math.random() < catchChance) {
    player.inventory.add('raw_sardine', 1);
    import('./game/skills.js').then(m => m.awardXp(player, 'wilds', 14, log, { worldPos: wp }));
    log('skill', '🐟 Caught a Raw Sardine.');
  } else {
    spawnFloat(wp, 'no bite', 'miss');
    log('skill', '🐟 The line wiggles, but nothing bites.');
  }
  renderInv();
  return true;
}

// SMITH_RECIPES — moved to src/data/smith-recipes.js so codex + engine
// share one source of truth. Imported above.

function trySmeltOrSmith(action) {
  if (player.attackCd > 0) return true;
  const r = SMITH_RECIPES[action];
  if (!r) return true;
  if (r.reqLevel && player.skills.earth.lv < r.reqLevel) {
    log('hint', `Need Smithing level ${r.reqLevel} for that.`);
    return true;
  }
  triggerAttack(player);  // hammer-strike anim reuses the swing
  if (r.kind === 'smelt') {
    for (const [oreId, n] of Object.entries(r.inputs)) {
      if (player.inventory.count(oreId) < n) {
        log('hint', `Missing ${ITEMS[oreId].name} for ${r.label.toLowerCase()}.`);
        return true;
      }
    }
    player.attackCd = r.cd;
    for (const [oreId, n] of Object.entries(r.inputs)) player.inventory.remove(oreId, n);
    player.inventory.add(r.out, 1);
  } else {
    if (player.inventory.count(r.bars) < r.count) {
      log('hint', `Need ${r.count}× ${ITEMS[r.bars].name}.`);
      return true;
    }
    player.attackCd = r.cd;
    player.inventory.remove(r.bars, r.count);
    player.inventory.add(r.out, 1);
  }
  const fireWorld = world.firePos
    ? new THREE.Vector3(world.firePos.x + 0.5, 1.0, world.firePos.y + 0.5)
    : null;
  import('./game/skills.js').then(m => m.awardXp(player, 'earth', r.xp, log, { worldPos: fireWorld }));
  log('skill', `${r.kind === 'smelt' ? '🟧' : '⚒'} ${r.label}.`);
  renderInv();
  return true;
}

/** Find an interactable decor entry at (tx,ty) in the active dungeon, or
 *  null. Skips depleted entries. */
function _findDungeonGatherAt(tx, ty) {
  if (!dungeon.active || !dungeon.layout) return null;
  const decor = dungeon.layout.decor || [];
  for (const d of decor) {
    if (d.x !== tx || d.y !== ty) continue;
    if (d.depleted) continue;
    if (d.kind === 'ore_rock' || d.kind === 'forage_node' || d.kind === 'log_pile') return d;
  }
  return null;
}

/** Run the appropriate gather verb on a dungeon decor node — mine, pick,
 *  or chop. Mirrors the overworld gather handlers but reads the decor
 *  list rather than world.{oreNodes|forageSpawns|trees}. Always returns
 *  true (the click was consumed). */
function tryGatherDungeonDecor(tx, ty) {
  if (player.attackCd > 0) return true;
  const d = _findDungeonGatherAt(tx, ty);
  if (!d) return true;
  // Per-kind tool gate, XP skill, item.
  let needTool, skillKey, xp, label;
  if (d.kind === 'ore_rock')        { needTool = 'pickaxe'; skillKey = 'earth'; xp = 10; label = ITEMS[d.item]?.name || 'ore'; }
  else if (d.kind === 'log_pile')   { needTool = 'axe';     skillKey = 'wilds'; xp = 12; label = 'logs'; }
  else                              { needTool = null;      skillKey = 'wilds'; xp = 8;  label = ITEMS[d.item]?.name || 'forage'; }
  if (needTool) {
    let has = false;
    for (const s of player.inventory.slots) {
      if (s && ITEMS[s.id].tool === needTool) { has = true; break; }
    }
    if (!has) { log('hint', `You need a ${needTool} for that.`); return true; }
  }
  // Try to add to inventory FIRST. If the bag is full, refuse the gather
  // so the node isn't consumed for nothing — same UX as overworld.
  if (!player.inventory.add(d.item, 1)) {
    log('hint', 'Your bag is full.');
    return true;
  }
  player.attackCd = 50;
  triggerAttack(player);
  const wp = new THREE.Vector3(tx + 0.5, 0.8, ty + 0.5);
  import('./game/skills.js').then(m => m.awardXp(player, skillKey, xp, log, { worldPos: wp }));
  d.depleted = true;
  if (d._mesh) d._mesh.visible = false;
  log('skill', d.kind === 'ore_rock' ? `⛏ You chip out a ${label}.`
              : d.kind === 'log_pile' ? `🪵 You split a log from the pile.`
              : `🌿 You pick a ${label}.`);
  renderInv();
  return true;
}

function tryMineRock(tx, ty) {
  if (player.attackCd > 0) return true;
  const node = world.oreNodes.find(n => n.x === tx && n.y === ty && !n.depleted);
  if (!node) return true;
  let hasPick = false;
  for (const s of player.inventory.slots) {
    if (s && ITEMS[s.id].tool === 'pickaxe') { hasPick = true; break; }
  }
  if (!hasPick) { log('hint', 'You need a pickaxe to mine ore.'); return true; }
  player.attackCd = 50;
  triggerAttack(player);
  const wp = new THREE.Vector3(tx + 0.5, 0.8, ty + 0.5);
  player.inventory.add(node.item, 1);
  import('./game/skills.js').then(m => m.awardXp(player, 'earth', 10, log, { worldPos: wp }));
  const depleted = world.mineOreAt(tx, ty);
  if (depleted) {
    log('skill', `⛏ The ${node.kind} vein is exhausted.`);
  } else {
    log('skill', `⛏ You chip away at the ${node.kind} ore.`);
  }
  renderInv();
  return true;
}

function tryChopTree(tx, ty) {
  if (player.attackCd > 0) return true;
  const tree = world.trees.find(t => t.x === tx && t.y === ty && !t.depleted);
  if (!tree) return true;
  if (tree.kind !== 'oak') {
    log('hint', 'You can only chop oaks for now.');
    return true;
  }
  if (!player.inventory.equipped.weapon || !ITEMS[player.inventory.equipped.weapon].tool ||
      ITEMS[player.inventory.equipped.weapon].tool !== 'axe') {
    // Allow chopping if any axe is in inventory; OSRS-style auto-detect.
    let hasAxe = false;
    for (const s of player.inventory.slots) {
      if (s && ITEMS[s.id].tool === 'axe') { hasAxe = true; break; }
    }
    if (!hasAxe) { log('hint', 'You need an axe to chop trees.'); return true; }
  }
  player.attackCd = 50;     // ~0.83s between chops
  triggerAttack(player);    // reuse swing animation
  const treeWorld = new THREE.Vector3(tx + 0.5, 1.0, ty + 0.5);
  player.inventory.add('logs', 1);
  import('./game/skills.js').then(m => m.awardXp(player, 'wilds', 12, log, { worldPos: treeWorld }));
  const depleted = world.chopTreeAt(tx, ty);
  if (depleted) {
    log('skill', '🪵 You chop down the tree.');
    // chopping the last log dis-engages auto-action
    player.combatTarget = null;
  } else {
    log('skill', '🪵 You hack at the tree.');
  }
  renderInv();
  return true;
}

/** Click on the practice dummy near the forge. While Hod's quest is
 *  active (accepted but not finished), each swing grants a small chunk
 *  of smithing XP. Cooldown gates on player.attackCd so it can't be
 *  spammed faster than the main weapon swing. */
function tryPracticeDummy() {
  // Once Hod's first quest is finished, the dummy doubles as an ability-
  // practice arena: clicking opens a small choice dialog.
  if (player.quest?.flags?.hodFinished) {
    showDialog({
      speaker: 'Practice Dummy',
      lines: ['A weather-worn straw figure on a stake. Hod uses it to bend new bars.'],
      choices: [
        { label: 'Hammer it (smithing strike)', onClick: () => { _practiceHammer(); }},
        { label: 'Set up training target (immortal dummy nearby)', onClick: () => { _spawnTrainingTarget(); }},
        { label: 'Leave it', onClick: () => {} },
      ],
    });
    return true;
  }
  // Pre-Hod-quest behavior: hammer-only.
  return _practiceHammer();
}

function _practiceHammer() {
  if (player.attackCd > 0) return true;
  player.attackCd = 50;
  triggerAttack(player);
  const wp = new THREE.Vector3(PRACTICE_DUMMY_TILE.x + 0.5, 0.9, PRACTICE_DUMMY_TILE.y + 0.5);
  spawnHitSparks(wp, { count: 8, spread: 1.0, color: 0xf6c64a, size: 5, life: 0.32 });
  import('./core/sfx.js').then(m => m.sfx.craft());
  const hasHammer = player.inventory.count('apprentices_hammer') > 0;
  const hodActive = player.quest?.flags?.hodAccepted && !player.quest?.flags?.hodFinished;
  if (hasHammer && hodActive) {
    import('./game/skills.js').then(m => m.awardXp(player, 'earth', 6, log, { worldPos: wp }));
    log('skill', '🔨 You hammer the dummy. (+6 Smithing)');
  } else if (hasHammer) {
    log('skill', '🔨 You strike the dummy.');
  } else {
    log('hint', 'You should have a hammer to strike this.');
  }
  return true;
}

function _spawnTrainingTarget() {
  // Find an empty floor tile within 3 of the practice dummy.
  for (let dx = -3; dx <= 3; dx++) {
    for (let dy = -3; dy <= 3; dy++) {
      if (dx === 0 && dy === 0) continue;
      const tx = PRACTICE_DUMMY_TILE.x + dx, ty = PRACTICE_DUMMY_TILE.y + dy;
      if (world.isTerrainBlocked(tx, ty)) continue;
      // Don't pile on existing enemy
      if (enemies.some(e => e.alive && e.x === tx && e.y === ty)) continue;
      const dummy = spawnTargetDummy(tx, ty, scene);
      enemies.push(dummy);
      log('hint', '🪵 A training dummy is set up. Practice your kit — it regenerates.');
      return true;
    }
  }
  log('hint', 'No room to set up a training dummy here.');
  return true;
}

function tryForage(tx, ty) {
  if (player.attackCd > 0) return true;
  const node = world.forageSpawns.find(s => s.x === tx && s.y === ty && !s.depleted);
  if (!node) return true;
  player.attackCd = 30;
  triggerAttack(player);            // bend-down picking gesture reuses the swing
  const wp = new THREE.Vector3(tx + 0.5, 0.6, ty + 0.5);
  player.inventory.add(node.item, 1);
  import('./game/skills.js').then(m => m.awardXp(player, 'wilds', 8, log, { worldPos: wp }));
  world.pickForageAt(tx, ty);
  log('skill', `🌿 Picked ${ITEMS[node.item].name}.`);
  // Rare: a folded parchment tucked under the foliage.
  if (Math.random() < 0.015) {
    const parch = pickRandomLoreParchment();
    if (parch) {
      player.inventory.add(parch, 1);
      log('hint', `…tucked under the leaves: ${ITEMS[parch].name}.`);
    }
  }
  renderInv();
  return true;
}

/** Pick the best cookable recipe the player can run right now: highest
 *  reqLevel they meet, with all inputs in inventory. Returns the recipe
 *  entry or null. Single-input recipes win over multi-input compounds
 *  unless the player explicitly has the latter's whole ingredient list
 *  (so cooking just beef doesn't accidentally consume the pantry-stew
 *  spread). */
function _pickCookRecipe() {
  const lv = player.skills.cook.lv;
  let best = null;
  for (const [, r] of Object.entries(COOK_RECIPES)) {
    const req = r.reqLevel || 1;
    if (lv < req) continue;
    const inputs = r.inputs ?? { [r.input]: 1 };
    let canCook = true;
    for (const [id, n] of Object.entries(inputs)) {
      if (player.inventory.count(id) < n) { canCook = false; break; }
    }
    if (!canCook) continue;
    // Prefer single-input recipes first (the canonical "I have meat,
    // cook it" path), then fall through to compound recipes when the
    // single-input path isn't an option.
    const isCompound = !r.input;
    if (!best
        || (best.compound && !isCompound)
        || (best.compound === isCompound && (r.reqLevel || 1) > (best.req || 1))) {
      best = { r, compound: isCompound, req };
    }
  }
  return best ? best.r : null;
}

/** Run a specific cook recipe by id. Used by the Cook Fire modal so the
 *  player picks the dish explicitly rather than auto-cooking the
 *  highest-reqLevel match. Returns true (the click was consumed). */
function _runCookRecipe(recipeId) {
  if (player.attackCd > 0) return true;
  const r = COOK_RECIPES[recipeId];
  if (!r) { log('hint', `Unknown recipe '${recipeId}'.`); return true; }
  return _doCook(r);
}

/** Open the Cook Fire recipe browser. Replaces the old auto-pick path
 *  so the player sees the full ladder + missing-ingredient hints. */
function openCookFireModal() {
  showCookFire(player, log, {
    cookRecipe: (id) => _runCookRecipe(id),
  });
  return true;
}

function tryCook() {
  // Open the recipe browser instead of auto-cooking the best available.
  // Players still see the same outputs; they get to pick the dish + see
  // what they're short on for higher tiers.
  return openCookFireModal();
}

/** Body of the cook handler — split out so both the auto-pick legacy
 *  path (now dormant) and the explicit recipe path can share it. */
function _doCook(r) {
  if (player.attackCd > 0) return true;
  // Validate inputs again at fire-time (could be called by the modal
  // after the player picked something they THOUGHT they had — but a
  // background event consumed a sardine).
  const inputs = r.inputs ?? { [r.input]: 1 };
  for (const [id, n] of Object.entries(inputs)) {
    if (player.inventory.count(id) < n) {
      const def = ITEMS[id];
      log('hint', `Missing ${n}× ${def?.name || id}.`);
      return true;
    }
  }
  const lv = player.skills.cook?.lv || 1;
  if (r.reqLevel && lv < r.reqLevel) {
    log('hint', `Need Cooking ${r.reqLevel} for that.`);
    return true;
  }
  player.attackCd = r.cd ?? CONFIG.player.cookCdFrames;
  triggerAttack(player);
  // Consume inputs (validated above; safe to remove).
  for (const [id, n] of Object.entries(inputs)) player.inventory.remove(id, n);
  const fireWorld = world.firePos
    ? new THREE.Vector3(world.firePos.x + 0.5, 1.0, world.firePos.y + 0.5)
    : null;
  // Burn roll — base chance scales down with cook level. Compound dishes
  // ignore the burn roll (they're recipes the player chose deliberately
  // and the engine pre-empts with a reqLevel, so failure feels punitive).
  const burnBase = r.burnBase ?? CONFIG.cooking.burnChanceLv1;
  const burnChance = r.inputs ? 0 : Math.max(0,
    burnBase - CONFIG.cooking.burnDecayPerLv * (player.skills.cook.lv - 1));
  if (Math.random() < burnChance) {
    if (r.burnt) player.inventory.add(r.burnt, 1);
    const xp = r.xpBurn ?? CONFIG.cooking.cookXpPerBurn;
    import('./game/skills.js').then(m => m.awardXp(player, 'cook', xp, log, { worldPos: fireWorld }));
    log('skill', '🔥 You burnt it. Try again at a higher Cooking level.');
  } else {
    player.inventory.add(r.output, 1);
    const xp = r.xp ?? CONFIG.cooking.cookXpPerSuccess;
    import('./game/skills.js').then(m => m.awardXp(player, 'cook', xp, log, { worldPos: fireWorld }));
    const outName = ITEMS[r.output]?.name || r.output;
    log('skill', `🍳 ${outName}.`);
  }
  renderInv();
  return true;
}

// ---------- REFINE (raw → reagent) ----------
// Reads MATERIAL_DEFS — each reagent declares { refines, station } and
// gets minted at its station. v1: no skill gate; XP routes by station
// (mortar/vessel/curing → wilds; grindstone/kiln → earth).
const _STATION_SKILL = {
  mortar: 'wilds', vessel: 'wilds', curing: 'wilds',
  grindstone: 'earth', kiln: 'earth',
};
function tryRefine(reagentId) {
  const def = MATERIAL_DEFS.find(m => m.id === reagentId);
  if (!def || !def.refines) {
    log('hint', `'${reagentId}' isn't a refinable reagent.`);
    return false;
  }
  if (player.attackCd > 0) return false;
  const have = player.inventory.count(def.refines);
  if (have < 1) {
    const src = ITEMS[def.refines];
    log('hint', `Missing 1× ${src?.name || def.refines}.`);
    return false;
  }
  player.attackCd = 30;
  triggerAttack(player);
  player.inventory.remove(def.refines, 1);
  // Yield rolls 1-3 — biased high by the relevant skill so a high-level
  // refinement feels rewarding. At skill 1 → mostly 1; at 99 → mostly 3.
  const skillKey = _STATION_SKILL[def.station] || 'wilds';
  const skillLv = player.skills[skillKey]?.lv || 1;
  const bias = Math.min(2, Math.floor(skillLv / 33));
  const yieldN = 1 + bias + Math.floor(Math.random() * 2);
  const ok = player.inventory.add(def.id, yieldN);
  if (!ok) {
    // Bag full — restore the source raw.
    player.inventory.add(def.refines, 1);
    log('hint', 'Your bag is full.');
    return false;
  }
  const wp = new THREE.Vector3(player.pos.x, 0.8, player.pos.z);
  import('./game/skills.js').then(m => m.awardXp(player, skillKey, 6, log, { worldPos: wp }));
  const outName = ITEMS[def.id]?.name || def.id;
  log('skill', yieldN > 1
    ? `🜔 Refined ${yieldN}× ${outName}.`
    : `🜔 Refined ${outName}.`);
  renderInv();
  return true;
}

// ---------- ORB FORGE ----------
// Reads ORB_RECIPES from src/data/orb-recipes.js. Each recipe lists
// inks + optional core + optional catalyst + a hollow-orb blank. The
// player slots a recipe at the Plinth (chartmaker stone) and the engine
// validates inputs, consumes them, and emits the rolled orb.

/** Return the inputs map for a recipe (inks + core + catalyst + blank
 *  flattened to one {itemId: count} dict). Used for both the affordability
 *  check and the consumption pass. */
function _orbRecipeInputs(r) {
  const inputs = { ...(r.inks || {}) };
  if (r.core)     inputs[r.core] = (inputs[r.core] || 0) + 1;
  if (r.catalyst) inputs[r.catalyst] = (inputs[r.catalyst] || 0) + 1;
  if (r.blank)    inputs[r.blank] = (inputs[r.blank] || 0) + 1;
  return inputs;
}

/** Can the player run this recipe right now? Checks Wayfinding gate +
 *  every input being in inventory in sufficient quantity. */
function canForgeOrb(recipeId) {
  const r = ORB_RECIPES[recipeId];
  if (!r) return { ok: false, reason: `Unknown orb recipe '${recipeId}'.` };
  const lv = player.skills.carto?.lv || 1;
  if (r.reqLevel && lv < r.reqLevel) {
    return { ok: false, reason: `Need Wayfinding ${r.reqLevel} (you have ${lv}).` };
  }
  const inputs = _orbRecipeInputs(r);
  for (const [id, n] of Object.entries(inputs)) {
    if (player.inventory.count(id) < n) {
      const def = ITEMS[id];
      return { ok: false, reason: `Missing ${n}× ${def?.name || id}.` };
    }
  }
  return { ok: true, recipe: r };
}

/** Forge an orb from a recipe id. Consumes inputs, awards XP, adds
 *  the rolled orb to inventory. Returns {ok, output, rolls?} for caller. */
function tryForgeOrb(recipeId) {
  const check = canForgeOrb(recipeId);
  if (!check.ok) {
    log('hint', check.reason);
    return { ok: false, reason: check.reason };
  }
  const r = check.recipe;
  // Consume inputs in declared order.
  for (const [id, n] of Object.entries(_orbRecipeInputs(r))) {
    player.inventory.remove(id, n);
  }
  // Roll properties — for each rollable property name, pick a tier
  // weighted by player Wayfinding level. At Lv 1 the bias floors near
  // "thin"; at Lv 99 the bias floors near "rich" with mother-lode chance.
  const cartoLv = player.skills.carto?.lv || 1;
  const tierBands = ['thin', 'normal', 'rich', 'mother_lode'];
  const rolled = {};
  for (const prop of (r.rolls || [])) {
    // Skill bumps the bias up by ~1 tier per 30 levels.
    const bias = Math.min(3, Math.floor(cartoLv / 30) + Math.floor(Math.random() * 2));
    rolled[prop] = tierBands[bias];
  }
  // Mint the output orb. Stash rolled properties as `extra` so the
  // chart-opening flow can read them at enter-dungeon time.
  const ok = player.inventory.add(r.output, 1, rolled);
  if (!ok) {
    log('hint', 'Bag full — orb couldn\'t be added. Inputs returned.');
    // Roll back inputs so the player isn't punished for inventory size.
    for (const [id, n] of Object.entries(_orbRecipeInputs(r))) {
      player.inventory.add(id, n);
    }
    return { ok: false, reason: 'bag full' };
  }
  // XP + log.
  const wp = new THREE.Vector3(player.pos.x, 0.8, player.pos.z);
  import('./game/skills.js').then(m => m.awardXp(player, 'carto', r.xp || 30, log, { worldPos: wp }));
  const outName = ITEMS[r.output]?.name || r.output;
  const rollSummary = Object.entries(rolled)
    .map(([k, v]) => `${k}:${v}`).join(', ');
  log('skill', rollSummary
    ? `🔮 Forged ${outName} (${rollSummary}).`
    : `🔮 Forged ${outName}.`);
  renderInv();
  advanceTutorial('orb_forged');
  return { ok: true, output: r.output, rolls: rolled };
}

/** Return the list of forgeable recipe ids for the current player state.
 *  Used by the chartmaker UI to surface only the recipes that will
 *  succeed if clicked. */
function listForgeableOrbs() {
  return Object.keys(ORB_RECIPES).filter(id => canForgeOrb(id).ok);
}

// Mirror at MIRROR_TILE — opens the char creator pre-filled with the
// current appearance. New look is persisted to localStorage and applied
// on the next page load (cleaner than rebuilding the player mesh in place
// for now; the boot flow already handles applying saved appearance).
function openMakeover() {
  showDialog({
    speaker: 'Mirror',
    lines: [
      'A polished glass set in a gilded frame. It holds your reflection still — for now.',
      'Look closer to change your appearance?',
    ],
    choices: [
      {
        label: 'Yes, change my look',
        onClick: async () => {
          const current = player.appearance || {};
          const next = await showCharCreator({ initial: { name: player.name, ...current } });
          if (next?.name) {
            try {
              localStorage.setItem('gj26.save', JSON.stringify(next));
            } catch {}
            // Fastest path to a fully-rebuilt player visual: reload. The
            // boot flow already reads the save and applies appearance.
            location.reload();
          }
        },
      },
      { label: 'Not now' },
    ],
  });
}

// Village interactions. Cottages show the door-note text (preserves
// discovery — players learn who Fenny is by reading the note, not via UI
// label). The well is goalless flavor. Coopers' Hold opens the bank UI
// (stub for now — deposit/withdraw will land next iteration).
const COTTAGE_NOTES = {
  "Hod's Cottage":   "Out at the forge. Knock if there's smoke.\n— Hod",
  "Fenny's Place":   "Hawking. Back by dusk.\n— Fenny",
  "Quill's Cottage": "Gone to map the ridge above Sallow's End.\n— Quill",
};
// ============================================================
// DUNGEON SYSTEM — Bramblewood Charters. The chartmaker rolls a chart;
// opening the chart swaps in a procedural dungeon. The overworld scene
// stays mounted but is hidden during a run; the dungeon group lives
// alongside it. Player stats / inventory persist across the boundary.
// ============================================================
const dungeon = {
  active: false,
  group: null,         // THREE.Group when active
  layout: null,        // {grid, entry, exit, blocked} when active
  enemies: [],         // dungeon-only spawned enemies (also pushed to global enemies list)
  hiddenWorld: [],     // overworld scene children to restore on exit
  returnTile: null,    // where to put player when they leave
};

// Quill the herbalist — at the cottage by the path. Trades raw forage for
// gold, and (V1) lets you skill-up Foraging by drying a bundle (one
// wishrose → 12 Foraging XP). Dries up if you don't have herbs.
// Grant ink-recipe hints by id. Idempotent; persists to localStorage.
function grantInkHints(ids) {
  player.hintedRecipes ||= new Set();
  let added = false;
  for (const id of ids) {
    if (!player.hintedRecipes.has(id)) {
      player.hintedRecipes.add(id);
      added = true;
    }
  }
  if (added) {
    try { localStorage.setItem('gj26.hintedRecipes', JSON.stringify(Array.from(player.hintedRecipes))); } catch (_) {}
  }
}

// ---- Vessel commissioning (Wayfinding Depth #13) ----
// Each NPC commissions one vessel for a coin-and-materials price. Gated
// at Wayfinding 30 — once the player reaches tier-3 ink territory the
// option appears in the NPC's dialog. The cost pulls from each NPC's
// thematic skill: Hod (forge/earth), Quill (herbalist/wilds), Cricket
// (cooper/lumen).
const VESSEL_COMMISSIONS = {
  hod:     { vesselId: 'clay_flask',      coin: 30, mats: { stoneground_ink: 1, charcoal_stick: 2 } },
  quill:   { vesselId: 'bound_parchment', coin: 40, mats: { vellum: 1, wishrose: 2 } },
  cricket: { vesselId: 'glass_vial',      coin: 50, mats: { wellspring_ink: 1, ore_dust: 1 } },
};
function vesselCommissionChoice(npcKey) {
  const c = VESSEL_COMMISSIONS[npcKey];
  if (!c) return null;
  if ((player.skills.carto?.lv || 1) < 30) return null;
  const def = ITEMS[c.vesselId];
  const matsOK = Object.entries(c.mats).every(([id, n]) => player.inventory.count(id) >= n);
  const coinsOK = (player.coins || 0) >= c.coin;
  const matsLabel = Object.entries(c.mats).map(([id, n]) => `${n}× ${ITEMS[id]?.name || id}`).join(', ');
  const label = `Commission a ${def.name} (${c.coin} gp + ${matsLabel})`;
  if (!matsOK || !coinsOK) {
    return { label: `${label} — short on cost`, onClick: () => log('hint', `You need ${c.coin} coins and ${matsLabel}.`) };
  }
  return {
    label,
    onClick: () => {
      player.coins -= c.coin;
      for (const [id, n] of Object.entries(c.mats)) player.inventory.remove(id, n);
      const ok = player.inventory.add(c.vesselId, 1);
      if (!ok) { log('hint', 'Bag is full — make space and ask again.'); return; }
      log('quest', `★ ${def.name} acquired. Slot it in the Inscribing Table for tier-3 inks.`);
      renderInv(); renderStats();
    },
  };
}

function openHod() {
  // Hod hints earthen-essence inks (Stoneground, Refined Ink).
  grantInkHints(['stoneground_ink', 'refined_ink']);
  const r = talkToHod(player, log);
  const choices = [];
  if (r.kind === 'offer' && !player.quest.flags.hodAccepted) {
    choices.push({ label: 'Accept the task', onClick: () => { acceptHodQuest(player, log); advanceTutorial('quest_accepted'); renderInv(); renderQuest(); }});
  } else if (r.kind === 'turnin') {
    choices.push({ label: 'Hand over the materials', onClick: () => { turnInHodQuest(player, log); renderInv(); renderQuest(); renderStats(); }});
  } else if (r.kind === 'offer-delve') {
    choices.push({ label: 'Accept: Pale Veins', onClick: () => { acceptHodDelveQuest(player, log); renderInv(); renderQuest(); }});
  } else if (r.kind === 'turnin-delve') {
    choices.push({ label: 'Hand over 6 Palechalk Ore', onClick: () => { turnInHodDelveQuest(player, log); renderInv(); renderQuest(); renderStats(); }});
  }
  const hodVessel = vesselCommissionChoice('hod');
  if (hodVessel) choices.push(hodVessel);
  choices.push({ label: 'Leave' });
  showDialog({
    speaker: NPC_DEFS.hod.name,
    lines: _withGossip('hod', NPC_DEFS.hod.dialog(player.quest, r.kind)),
    choices,
  });
}

function openWithering() {
  // Withering hints sanguine inks (Bramblepress, Ember at higher carto).
  grantInkHints(['bramblepress_ink']);
  if (player.skills.carto.lv >= 25) grantInkHints(['ember_ink']);
  const r = talkToWithering(player, log);
  const choices = [];
  if (r.kind === 'offer' && !player.quest.flags.witheringAccepted) {
    choices.push({ label: "Accept Pernel's Errand", onClick: () => { acceptWitheringQuest(player, log); advanceTutorial('quest_accepted'); renderInv(); renderQuest(); }});
  } else if (r.kind === 'turnin') {
    choices.push({ label: "Hand over the charm", onClick: () => { turnInWitheringQuest(player, log); renderInv(); renderQuest(); renderStats(); }});
  } else if (r.kind === 'offer-crown' && !player.quest.flags.crownAccepted) {
    choices.push({ label: 'Accept: Crown of Thorns', onClick: () => { acceptCrownQuest(player, log); advanceTutorial('quest_accepted'); renderInv(); renderQuest(); }});
  } else if (r.kind === 'turnin-crown') {
    choices.push({ label: 'Show him the crown', onClick: () => { turnInCrownQuest(player, log); renderInv(); renderQuest(); renderStats(); }});
  }
  choices.push({ label: 'Leave' });
  showDialog({
    speaker: NPC_DEFS.withering.name,
    lines: _withGossip('withering', NPC_DEFS.withering.dialog(player.quest, r.kind)),
    choices,
  });
}

function openHerbalist() {
  // Quill hints verdant + lumen inks (Hedge, Wellspring, Bog).
  grantInkHints(['hedge_ink', 'wellspring_ink']);
  if (player.skills.carto.lv >= 14) grantInkHints(['bog_ink']);
  const r = talkToQuill(player, log);
  const HERB_PRICE = { whitleberry: 2, hedgecap: 3, wishrose: 4 };
  const choices = [];
  // Quest options first so they're at the top of the choice list.
  if (r.kind === 'offer' && !player.quest.flags.quillAccepted) {
    choices.push({ label: 'Accept: Withering Bramble', onClick: () => { acceptQuillQuest(player, log); advanceTutorial('quest_accepted'); renderInv(); renderQuest(); }});
  } else if (r.kind === 'turnin') {
    choices.push({ label: 'Hand over 3 Bramble Resin', onClick: () => { turnInQuillQuest(player, log); renderInv(); renderQuest(); renderStats(); }});
  } else if (r.kind === 'offer-briar') {
    choices.push({ label: 'Accept: A Bushel of Thorns', onClick: () => { acceptQuillBriarQuest(player, log); renderInv(); renderQuest(); }});
  } else if (r.kind === 'turnin-briar') {
    choices.push({ label: 'Hand over 5 Thorn Essence', onClick: () => { turnInQuillBriarQuest(player, log); renderInv(); renderQuest(); renderStats(); }});
  }
  for (const [id, price] of Object.entries(HERB_PRICE)) {
    const have = player.inventory.count(id);
    if (have > 0) {
      choices.push({
        label: `Sell ${have}× ${ITEMS[id].name} (${price * have} gp)`,
        onClick: () => {
          const n = player.inventory.count(id);
          player.inventory.remove(id, n);
          // Gold isn't yet a tracked currency — log only for now
          log('quest', `Sold ${n}× ${ITEMS[id].name} to Quill (${price * n} gp).`);
          renderInv();
        },
      });
    }
  }
  if (player.inventory.count('wishrose') > 0) {
    choices.push({
      label: 'Dry a bundle of herbs (+12 Foraging XP)',
      onClick: () => {
        player.inventory.remove('wishrose', 1);
        const wp = new THREE.Vector3(HERBALIST_TILE.x + 0.5, 0.6, HERBALIST_TILE.y + 0.5);
        import('./game/skills.js').then(m => m.awardXp(player, 'wilds', 12, log, { worldPos: wp }));
        renderInv();
      },
    });
  }
  const quillVessel = vesselCommissionChoice('quill');
  if (quillVessel) choices.push(quillVessel);
  choices.push({ label: 'Leave' });
  showDialog({
    speaker: NPC_DEFS.quill.name,
    lines: _withGossip('quill', NPC_DEFS.quill.dialog(player.quest, r.kind)),
    choices,
  });
}

// Death + respawn — cozy default: full HP back, teleport to village, no
// loss. Force-exit any active dungeon so the player isn't stranded.
function handleDeath() {
  player._justDied = false;
  sfx.death();
  if (dungeon.active) exitDungeon();
  player.hp = player.hpMax;
  player.x = world.spawn.x;
  player.y = world.spawn.y;
  player.pos.set(player.x + 0.5, 0, player.y + 0.5);
  player.mesh.position.copy(player.pos);
  player.path = [];
  player.onPathDone = null;
  player.combatTarget = null;
  renderStats();
  showDialog({
    speaker: 'You faded into the wolds',
    portrait: '',     // no portrait — keeps the slate clear
    variant: 'death',
    lines: [
      'A wave of soft moss wraps around you and drags you back to the village square.',
      'You wake at Old Mother Well, no worse for it. The Wolds keep their own counsel.',
    ],
    choices: [{ label: 'Continue' }],
  });
  log('combat', '☠ You fell. Bramblewood took you home.');
  writeSave(player, world);
}

function openInscriptionFlow() {
  // The chartmaker stone now opens the unified Wayfinding Workshop —
  // single-source-of-truth surface for the keystone skill. The four
  // sub-modals (Inscribing Table / Pedestal / Charting / Field Journal)
  // are launched from inside it.
  openWayfindingWorkshop();
}

function openWayfindingWorkshop() {
  showWayfindingWorkshop(player, log, {
    openInscribingTable: () => showInscribingTable({
      player, log,
      onChange: () => { renderInv(); renderStats(); },
    }),
    openPedestal:        () => showPedestal(player, log),
    openCharting:        () => openChartmaker(),
    openPlinthForge:     () => showPlinthForge(player, log, {
      onChange: () => { renderInv(); renderStats(); },
      onClose:  () => reopenWayfindingWorkshop(),
    }),
    openRefineStation:   () => showRefineStation(player, log, {
      refineRecipe: (id) => tryRefine(id),
    }),
    openFieldJournal:    () => showFieldJournal(player),
    openAtlas:           () => openAtlasMap(),
    openMaterialsBrowser:() => openMaterialsBrowserUI(),
  });
}

function openMaterialsBrowserUI() {
  showMaterialsBrowser(player, log, {
    onPickRecipe: (recipe) => {
      // Shopping-list mode: when the workshop reopens via the breadcrumb
      // observer, set the target so the Materials section highlights
      // exactly what this recipe needs. setWorkshopTarget no-ops if the
      // workshop's _state is already cleared.
      setWorkshopTarget(recipe);
    },
  });
}

function openAtlasMap() {
  showAtlasMap(player, log, {
    onEnterBiome: (biomeId) => {
      if (!isBiomeUnlocked(player, biomeId)) {
        log('hint', 'That biome is still hidden. Complete more charts to surface it.');
        return;
      }
      if (dungeon.active) {
        log('hint', 'Leave the current chart before walking to a biome.');
        return;
      }
      // Walking to a biome should also dismiss the workshop — entering a
      // place is leaving the workbench, not stacking another modal.
      if (isWayfindingWorkshopOpen()) closeWayfindingWorkshop();
      enterBiome(biomeId);
    },
  });
}

// Biomes reuse the dungeon-system as persistent walkable instances. They
// pin a deterministic seed so the layout stays the same across visits,
// and they don't grant carto XP / consume a chart on entry.
const BIOME_SEEDS = {
  biome_mossvale:    0x05a55a1e,    // pinned — same layout each visit
  biome_stillwater:  0x57111a7e,
  biome_coalrose:    0xc0a17053,
  biome_wightspire:  0x71647591,
  biome_echofold:    0xec40f01d,
};
const BIOME_TIERS = {
  biome_mossvale:    1,
  biome_stillwater:  2,
  biome_coalrose:    3,
  biome_wightspire:  3,
  biome_echofold:    3,
};
function enterBiome(biomeId) {
  resetWindupTokens();
  const seed = BIOME_SEEDS[biomeId] ?? 0xfeed;
  const tier = BIOME_TIERS[biomeId] ?? 1;
  // Generate the persistent layout with a fixed seed + biome scope tag.
  const layout = generateDungeonLayout(seed, [], biomeId);
  log('quest', `🌿 You step through the gate into ${biomeId.replace('biome_', '').replace(/_/g, ' ')}.`);
  enterDungeon(tier, [], null, biomeId, layout);
}

function openChartmaker() {
  showCharting(player, log, (result) => {
    // result = { template: {tier, baseItem, ...}, affixes: [{id, good, resolvedId}, ...] }
    const baseId = result.template.baseItem;
    const baseDef = ITEMS[baseId];
    if (!baseDef) { log('hint', 'The chart fails to take ink.'); return; }
    // Bake affixes onto a unique chart instance. Inventory.add stacks by id,
    // so we mint an item-instance with a stable id but the affix list lives
    // in the inventory slot's userData (the inventory module attaches it).
    const ok = player.inventory.add(baseId, 1, { affixes: result.affixes, runeEffect: result.runeEffect });
    if (!ok) { log('hint', 'Bag is full.'); return; }

    // Friendly log line per affix outcome — bad twins are notable.
    const goodCount = result.affixes.filter(a => a.good).length;
    const badCount  = result.affixes.length - goodCount;
    if (result.affixes.length === 0) {
      log('quest', '★ A blank Tier 1 chart appears in your bag.');
    } else if (badCount === 0) {
      log('quest', `★ Chart inscribed cleanly — ${goodCount} affix${goodCount > 1 ? 'es' : ''}.`);
    } else {
      log('quest', `★ Chart inscribed. ${goodCount} held, ${badCount} ran wild.`);
    }
    // Wayfinding XP — creating a map IS the verb. Tier scales the grant;
    // good twins land more XP than bad twins, but every chart pays.
    const tier = result.template.tier || 1;
    const xp = (tier * 100) + (goodCount * 40) + (badCount * 15);
    import('./game/skills.js').then(m => m.awardXp(player, 'carto', xp, log,
      { worldPos: new THREE.Vector3(player.pos.x, player.pos.y + 1.4, player.pos.z) }));
    log('skill', `🗺  Chart inscribed — ${xp} Wayfinding XP.`);
    renderInv();
  });
}

// Called when the player right-clicks a chart in inventory and picks "Open"
// (wired in renderInv). Or via inventory click flow — for now we expose a
// global window helper so the inv item-click can call it.
function openChartFromInventory(slotIdx) {
  const slot = player.inventory.slots[slotIdx];
  if (!slot || !ITEMS[slot.id]?.chart) return false;
  if (dungeon.active) { log('hint', 'You are already in a dungeon.'); return true; }
  // Pull the per-instance affix list (set by the chartmaker UI) before
  // remove() nukes the slot.
  const affixes = slot.extra?.affixes || [];
  const runeEffect = slot.extra?.runeEffect || null;
  player.inventory.remove(slot.id, 1);
  renderInv();
  const chartDef = ITEMS[slot.id].chart;
  enterDungeon(chartDef.tier, affixes, runeEffect, chartDef.scope);
  return true;
}
window.__openChart = openChartFromInventory;   // for the inv UI's right-click

// Echo scope → anchor tile in the live overworld. Resolves the place's
// `anchorRef` string to the matching runtime constant so echo-places.js
// stays pure-data.
function anchorTileForEchoScope(scope) {
  const place = echoPlaceById(scope);
  if (!place) return null;
  if (place.anchorRef === 'cookSpawn')      return world?.cookSpawn || null;
  if (place.anchorRef === 'HOD_TILE')       return typeof HOD_TILE !== 'undefined' ? HOD_TILE : null;
  if (place.anchorRef === 'HERBALIST_TILE') return typeof HERBALIST_TILE !== 'undefined' ? HERBALIST_TILE : null;
  if (place.anchorRef === 'WITHERING_TILE') return typeof WITHERING_TILE !== 'undefined' ? WITHERING_TILE : null;
  if (place.anchorRef === 'CHARTMAKER_TILE')return typeof CHARTMAKER_TILE !== 'undefined' ? CHARTMAKER_TILE : null;
  if (place.anchorRef === 'spawn')          return world?.spawn || null;
  return null;
}

function enterDungeon(tier, affixes = [], runeEffect = null, scope = undefined, prebuiltLayout = null) {
  resetWindupTokens();      // clear any dangling tokens from the overworld
  const seed = Math.floor(Math.random() * 0xffffffff);
  let layout = prebuiltLayout;
  if (!layout && typeof scope === 'string' && scope.startsWith('echo_')) {
    // Echo charts read the live world tiles around an anchor instead of
    // procgenning. Anchor lookup mirrors the place's `anchorRef` to the
    // matching runtime tile constant.
    const anchor = anchorTileForEchoScope(scope);
    if (anchor) layout = generateEchoLayout(world, scope, anchor, affixes);
  }
  if (!layout) layout = generateDungeonLayout(seed, affixes, scope);
  const group = buildDungeonGroup(layout, affixes);
  // The dungeon sits offset from the overworld so they don't collide
  // visually if a fog-render straggles. Player teleports to the entry.
  group.position.set(0, 0, 0);
  scene.add(group);

  // Hide overworld content. Keep the player + falcon + clickMarker visible
  // (they travel with us). Stash references so we can restore on exit.
  dungeon.hiddenWorld = [];
  for (const child of scene.children) {
    if (child === group) continue;
    if (child === player.mesh || child === clickMarker) continue;
    if (child === falcon.mesh) continue;
    if (child.isLight) continue;
    if (child.visible) {
      dungeon.hiddenWorld.push(child);
      child.visible = false;
    }
  }

  // Move player to entry stair
  dungeon.returnTile = { x: player.x, y: player.y };
  player.x = layout.entry.x;
  player.y = layout.entry.y;
  player.pos.set(layout.entry.x + 0.5, 0, layout.entry.y + 0.5);
  player.mesh.position.copy(player.pos);
  player.path = [];
  player.onPathDone = null;

  dungeon.active = true;
  dungeon.group  = group;
  dungeon.layout = layout;
  dungeon.enemies = [];
  // Wire the trap handler — onTileEnter fires after every step (path or
  // keyboard). Spike traps are one-shot consumed; bramble persists.
  player.onTileEnter = (tx, ty) => _checkTrapAt(tx, ty);
  dungeon.tier = tier;
  // Stash which affixes are in play so completion XP + chest bonuses can read them.
  dungeon.activeAffixes = affixes.slice();
  const hasGood = (id) => affixes.some(a => a.id === id && a.good);
  dungeon.tyrannical   = hasGood('tyrannical');
  dungeon.bursting     = hasGood('bursting');
  dungeon.frenzied     = hasGood('frenzied');
  dungeon.brambleBloom = hasGood('bramble_bloom');
  dungeon.fogOfHedge   = hasGood('fog_of_hedge');
  dungeon.festival     = hasGood('festival_pace');
  dungeon.gildedSeam   = hasGood('gilded_seam');
  dungeon.woodGrove    = hasGood('wood_grove');
  dungeon.herbalPatch  = hasGood('herbal_patch');
  dungeon.gemSeam      = hasGood('gem_seam');
  // Rune effect baked into the chart (Lv 50 carto + Lv 30 magic feature).
  // Applied to enemy spawns + chest loot below.
  dungeon.runeEffect = runeEffect;
  sfx.startAmbient('dungeon');

  // First-dungeon tutorial — fires once, with scope-aware tip if applicable.
  if (!player.quest.flags.firstDungeonEntered) {
    player.quest.flags.firstDungeonEntered = true;
    const scopeTip = ({
      briar_maze: 'This is a Briar Maze — heavy on thorn-fae. Bramble-caps drop thorn essence (Quill wants 5).',
      sunken_hut: 'This is a Sunken Hut — bog-soaked. Tusker Sows drop raw tusker (Maud wants 4).',
      delve:      'This is a Delve — stone-veined deep. The chest can hold palechalk ore (Hod wants 6).',
      hollow:     'This is a Hollow — mixed pool. Good for general combat practice.',
    })[scope] || 'A fresh hollow opens before you.';
    setTimeout(() => {
      showDialog({
        speaker: 'Adventurer',
        lines: [
          'The chart unfolds and the world rearranges around you.',
          scopeTip,
          'Hotkeys 1-4 fire your bound abilities. V opens the Abilities Book to bind more. Space dodges, Tab cycles target, ` opens the dev panel.',
        ],
        choices: [{ label: 'I\'m ready' }],
      });
    }, 250);
  }

  // Spawn enemies in non-entry rooms. Table-driven by tier (see
  // src/data/dungeonSpawns.js). Boss rooms (affix-flagged) get the named
  // boss instead. Penultimate room rolls from the GUARD pool.
  // Festival Pace adds one extra mob per non-boss room.
  const dungeonSpawnFns = {
    goblin: spawnGoblin, hare: spawnHare, boar: spawnBoar,
    hedgewolf: spawnHedgeWolf, brambleCap: spawnBrambleCap,
    chicken: spawnChicken,
    skitterling: spawnSkitterling, marshRat: spawnMarshRat,
    ironGob: spawnIronGob, tuskerSow: spawnTuskerSow,
    archer: spawnArcher, charger: spawnCharger,
  };
  function spawnByKey(key, ex, ey) {
    const fn = dungeonSpawnFns[key] || spawnGoblin;
    return fn(ex, ey, scene);
  }

  // Editor spawn-id → spawn factory. Used for authored layouts so a level
  // built in editor.html spawns exactly what the author placed.
  const AUTHORED_SPAWNS = {
    bramble_imp:     spawnGoblin,
    bramble_cap:     spawnBrambleCap,
    iron_gob:        spawnIronGob,
    skitterling:     spawnSkitterling,
    marsh_rat:       spawnMarshRat,
    tusker_sow:      spawnTuskerSow,
    bramble_archer:  spawnArcher,
    bramble_charger: spawnCharger,
    hedgewolf:       spawnHedgeWolf,
    wolf_alpha:      spawnWolfAlpha,
    burrow_boar:     spawnBurrowBoar,
    hedgemother:     spawnHedgemother,
  };

  if (layout.authored && Array.isArray(layout.authoredSpawns)) {
    for (const sp of layout.authoredSpawns) {
      const fn = AUTHORED_SPAWNS[sp.kind] || spawnGoblin;
      const e = fn(sp.x, sp.y, scene);
      applyAffixesToEnemy(e);
      enemies.push(e);
      dungeon.enemies.push(e);
    }
  } else {
    for (let i = 1; i < layout.rooms.length; i++) {
      const r = layout.rooms[i];
      const ex = r.x + Math.floor(r.w / 2);
      const ey = r.y + Math.floor(r.h / 2);
      if (ex === layout.exit.x && ey === layout.exit.y) continue;

      // Stage B: per-room intent tag dispatcher. Tag wins over heuristics.
      // Untagged rooms default to 'mob' (current behavior preserved).
      const tag = r.tag || (layout.bossRoom && r === layout.bossRoom ? 'boss' : 'mob');
      if (tag === 'puzzle' || tag === 'safe' || tag === 'treasure' || tag === 'shrine') {
        // No mob in this room. Treasure rooms have the chest moved here
        // upstream in loadScaffoldLayout; shrines drop a real pedestal
        // prop with a glowing rune disc + faceted gemstone (rendered by
        // dungeon.js's 'shrine_pedestal' decor case).
        if (tag === 'shrine') {
          (layout.decor = layout.decor || []).push({ kind: 'shrine_pedestal', x: ex, y: ey });
        }
        continue;
      }

      let e;
      if (tag === 'boss') {
        e = layout.bossKind === 'burrow_boar' ? spawnBurrowBoar(ex, ey, scene)
          : layout.bossKind === 'wolf_alpha'  ? spawnWolfAlpha(ex, ey, scene)
          :                                     spawnHedgemother(ex, ey, scene);
      } else if (i === layout.rooms.length - 1) {
        // Penultimate room — guard spawn (escalates with tier)
        e = spawnByKey(pickDungeonSpawn(tier, 'guard', scope), ex, ey);
      } else {
        // Regular mob — pulled from the tier's mob pool, biased by scope
        e = spawnByKey(pickDungeonSpawn(tier, 'mob', scope), ex, ey);
      }
      applyAffixesToEnemy(e);
      enemies.push(e);
      dungeon.enemies.push(e);

      if (dungeon.festival && tag !== 'boss') {
        // Extra mob at a slight offset so they don't pile up
        const ox = ex + (i % 2 ? 1 : -1);
        const oy = ey + (i % 2 ? 0 : 1);
        if (!layout.blocked(ox, oy) && !(ox === layout.entry.x && oy === layout.entry.y)) {
          const e2 = spawnByKey(pickDungeonSpawn(tier, 'mob', scope), ox, oy);
          applyAffixesToEnemy(e2);
          enemies.push(e2);
          dungeon.enemies.push(e2);
        }
      }
    }
  }

  // Scaffold mode: author's hand-placed spawns ride on top of the procgen
  // room loop. Lets the author force a specific encounter at a specific tile
  // without giving up procgen filler.
  if (Array.isArray(layout.scaffoldExtraSpawns)) {
    for (const sp of layout.scaffoldExtraSpawns) {
      const fn = AUTHORED_SPAWNS[sp.kind];
      if (!fn) continue;
      const e = fn(sp.x, sp.y, scene);
      applyAffixesToEnemy(e);
      enemies.push(e);
      dungeon.enemies.push(e);
    }
  }

  function applyAffixesToEnemy(e) {
    if (!e) return;
    if (dungeon.tyrannical) {
      const buff = 1.5;
      e.hpMax = Math.floor((e.hpMax || e.hp) * buff);
      e.hp    = e.hpMax;
      e.tyrannical = true;
    }
    if (dungeon.frenzied) e.frenzied = true;
    // Rune effect: air → enemy maxHit -1 (player takes less damage)
    if (dungeon.runeEffect === 'air' && e.maxHit > 1) {
      e.maxHit = Math.max(1, e.maxHit - 1);
      e.runeAired = true;
    }
  }

  // Tell the player what affixes ride with them.
  let affixSummary = '';
  for (const a of affixes) {
    const aff = AFFIXES[a.id];
    affixSummary += ' · ' + (a.good ? (aff?.name || a.id) : (aff?.badName || a.id));
  }
  log('quest', `★ You step inside the chart. (Tier ${tier})${affixSummary}`);
}

// Loot the dungeon's reward chest. Items burst out and arc to the floor;
// player walks over to pick each up (Diablo / Fate style).
function lootChest() {
  if (!dungeon.active || !dungeon.layout || dungeon.layout.chestLooted) return;
  const tier = dungeon.tier || 1;
  const drops = generateDungeonLoot(tier, dungeon.layout.affixes || [], dungeon.layout.scope);
  // Resource-bias affixes — each adds bonus loot to the chest.
  if (dungeon.brambleBloom) drops.push({ id: 'bramble_resin', qty: 3 });
  if (dungeon.woodGrove)    drops.push({ id: 'logs',          qty: 4 });
  if (dungeon.herbalPatch)  drops.push({ id: 'wild_herb',     qty: 5 });
  if (dungeon.gildedSeam)   drops.push({ id: 'coin',          qty: 50 });
  if (dungeon.gemSeam) {
    // Phase 1: stand-in for a gem item — drops bramble_resin + bonus coin
    // until we add gemstone items. Easy upgrade later.
    drops.push({ id: 'coin', qty: 100 });
  }
  // Rune effects — fire boosts loot quantity, earth adds stone chips.
  if (dungeon.runeEffect === 'fire') {
    for (const d of drops) d.qty = Math.ceil((d.qty || 1) * 1.30);
  }
  if (dungeon.runeEffect === 'earth') {
    drops.push({ id: 'stone_chip', qty: 3 });
  }
  if (dungeon.runeEffect === 'water') {
    log('skill', '✦ Water rune — stamina regen will be +20% for the run.');
  }
  dungeon.layout.chestLooted = true;

  sfx.chest();
  // Animate the lid opening (rotate the band/lid Y up)
  const chestGroup = dungeon.group?.userData.chest;
  if (chestGroup) {
    const lid = chestGroup.children[1];   // the lid mesh
    if (lid) lid.rotation.x = -Math.PI / 3;
    chestGroup.userData.opened = true;
  }
  // Arc the items out
  const origin = chestGroup
    ? new THREE.Vector3(chestGroup.position.x, chestGroup.position.y + 0.4, chestGroup.position.z)
    : new THREE.Vector3(player.pos.x, 0.5, player.pos.z);
  spawnArc(scene, origin, drops);

  log('quest', `★ The chest bursts open — ${drops.length} drops scatter across the stone.`);
}

function exitDungeon() {
  if (!dungeon.active) return;
  resetWindupTokens();      // dungeon enemies' setTimeouts may still hold tokens

  // Wayfinding: completion XP scales with tier + how many good twins
  // landed. Failed twins still grant a small consolation tick — even a
  // botched chart teaches the cartographer something.
  // Formula: tier × 75 + good × 40 + bad × 10, with fog_of_hedge ±25.
  // Biomes are places, not charts — looting their chest doesn't grant
  // carto XP and doesn't tick atlas progress (you're already there).
  const isBiome = String(dungeon.scope || '').startsWith('biome_');
  if (dungeon.layout?.chestLooted && !isBiome) {
    const tier   = dungeon.tier || 1;
    const aff    = dungeon.activeAffixes || [];
    const good   = aff.filter(a => a.good).length;
    const bad    = aff.filter(a => !a.good).length;
    let xp = (tier * 75) + (good * 40) + (bad * 10);
    if (dungeon.fogOfHedge) xp += 25;
    if (aff.some(a => a.id === 'fog_of_hedge' && !a.good)) xp -= 15;
    if (xp > 0) {
      import('./game/skills.js').then(m => m.awardXp(player, 'carto', xp, log,
        { worldPos: new THREE.Vector3(player.pos.x, player.pos.y + 1.4, player.pos.z) }));
      log('skill', `🗺  Charter complete — ${xp} Wayfinding XP.`);
    }
    // Atlas: tick the region for this scope. If the player just crossed
    // a region's threshold, surface the biome unlock as a celebratory log
    // line — the new biome appears in the Atlas modal immediately.
    const result = recordChartCompletion(player, dungeon.scope);
    if (result.justUnlocked && result.region) {
      log('quest', `★ Region unlocked — ${result.region.name}. ${result.region.biomeName} is now walkable from the Atlas.`);
    } else if (result.region) {
      const st = result.region;
      const count = (player.atlas.completions[st.id] || 0);
      log('hint', `📜 Atlas — ${st.name}: ${count} / ${st.threshold}`);
    }
  } else if (isBiome) {
    log('hint', '🌿 You leave the biome. The path back through the gate stays open.');
  } else {
    log('hint', '★ You leave the chart-line without claiming the chest. No XP earned.');
  }

  // Drop everything still on the floor — players have to grab loot before
  // taking the stairs (per the design spec: leaving means leaving).
  clearGroundLoot(scene);
  clearShimmers();
  // Despawn dungeon-only enemies (remove from main enemies array + scene)
  for (const e of dungeon.enemies) {
    const i = enemies.indexOf(e);
    if (i >= 0) enemies.splice(i, 1);
    if (e.mesh)  scene.remove(e.mesh);
    if (e.hpBar) scene.remove(e.hpBar);
  }
  dungeon.enemies = [];
  // Tear down dungeon group
  scene.remove(dungeon.group);
  dungeon.group = null;
  // Restore overworld visibility
  for (const c of dungeon.hiddenWorld) c.visible = true;
  dungeon.hiddenWorld = [];
  // Teleport player back to where they were (or village spawn fallback)
  const r = dungeon.returnTile || { x: world.spawn.x, y: world.spawn.y };
  player.x = r.x; player.y = r.y;
  player.pos.set(r.x + 0.5, 0, r.y + 0.5);
  player.mesh.position.copy(player.pos);
  player.path = [];
  player.onPathDone = null;
  player.onTileEnter = null;
  dungeon.active = false;
  dungeon.layout = null;
  dungeon.activeAffixes = [];
  dungeon.tyrannical = dungeon.bursting = dungeon.frenzied = false;
  dungeon.brambleBloom = dungeon.fogOfHedge = dungeon.festival = false;
  sfx.startAmbient('village');
  log('quest', '★ You step back through the chart-line into Bramblewood.');
}

function handleVillageTile(v) {
  if (v.kind === 'cottage') {
    showDialog({
      speaker: v.name,
      lines: [
        'A note is nailed to the door.',
        COTTAGE_NOTES[v.name] || 'No one home.',
      ],
    });
    return;
  }
  if (v.kind === 'well') {
    showDialog({
      speaker: 'Old Mother Well',
      lines: [
        'A deep stone well in the heart of Bramblewood. The water tastes of moss and copper, in the good way.',
        'A hand-carved plaque reads: "Built by the dairymothers, year of the long winter."',
      ],
    });
    return;
  }
  if (v.kind === 'bank') {
    openBank();
    return;
  }
  // Refinement stations open the refinement modal pre-filtered to that
  // station, so the player only sees the recipes that machine produces.
  if (typeof v.kind === 'string' && v.kind.startsWith('station_')) {
    const station = v.kind.slice('station_'.length);
    showRefineStation(player, log, {
      filterStation: station,
      refineRecipe: (id) => tryRefine(id),
    });
    return;
  }
}

// Coopers' Hold bank UI. Stackable inventory items can be deposited a stack
// at a time; banked items withdrawn the same way. Re-opens after each
// transaction so the player can chain operations until they Leave.
function openBank() {
  if (!player.bank) player.bank = {};
  const choices = [];
  // Deposit: every stackable inventory slot becomes one choice.
  for (let i = 0; i < player.inventory.slots.length; i++) {
    const s = player.inventory.slots[i];
    if (!s) continue;
    const def = ITEMS[s.id];
    if (!def?.stack) continue;            // skip equipment / one-of items
    if (choices.length >= 14) break;
    const qty = s.qty || 1;
    choices.push({
      label: `Deposit ${def.name} ×${qty}`,
      onClick: () => {
        const moved = player.inventory.count(s.id);
        if (moved <= 0) { openBank(); return; }
        player.inventory.remove(s.id, moved);
        player.bank[s.id] = (player.bank[s.id] || 0) + moved;
        log('hint', `Deposited ${def.name} ×${moved}.`);
        renderInv();
        openBank();
      },
    });
  }
  // Withdraw: every banked id becomes one choice.
  for (const [id, qty] of Object.entries(player.bank)) {
    if (qty <= 0) continue;
    const def = ITEMS[id];
    if (!def) continue;
    if (choices.length >= 28) break;
    choices.push({
      label: `Withdraw ${def.name} ×${qty}`,
      onClick: () => {
        const taken = qty;
        if (!player.inventory.add(id, taken)) {
          log('hint', 'Your bag is full. Make some room first.');
          openBank();
          return;
        }
        delete player.bank[id];
        log('hint', `Withdrew ${def.name} ×${taken}.`);
        renderInv();
        openBank();
      },
    });
  }
  choices.push({ label: 'Leave' });
  const lines = [
    'A converted grain warehouse, repurposed as the village strongbox. The cooper sisters keep ledgers in beeswax.',
  ];
  if (Object.keys(player.bank).length === 0) {
    lines.push('Your account is empty. Marra slides over a clean ledger page anyway.');
  }
  showDialog({ speaker: "Coopers' Hold", lines, choices });
}

// Cross-NPC gossip pool. Each line references another villager and only
// becomes available once the *other* villager has been spoken to at least
// once. Lines surface as a random "by the way..." prefix on the second
// or later visit, so the village feels like a network instead of four
// stand-alone quest givers.
const GOSSIP = {
  npc_eldra: [
    { ifVisited: 'cook',     line: 'Maud and I have tea every Threnday. Thirty-one years now.' },
    { ifVisited: 'pell',     line: 'Brother Pell married me my own copy of the village psalter. It still smells of his ink.' },
    { ifVisited: 'cricket',  line: 'Cricket lights the lantern by the cooperage for me when his loft\'s the warmest spot. Sweet boy.' },
  ],
  npc_cricket: [
    { ifVisited: 'withering', line: 'Sir Withering taught me to read after the previous letter-carrier passed. Linnet looked on the whole time.' },
    { ifVisited: 'pell',      line: 'I run weekly letters between Brother Pell and Mother Onywyn. They\'re mostly about weather.' },
    { ifVisited: 'onywyn',    line: 'I run weekly letters between Brother Pell and Mother Onywyn. They\'re mostly about weather.' },
  ],
  npc_pell: [
    { ifVisited: 'onywyn',  line: 'Mother Onywyn would prefer the cloister stayed out of her cupboard. The cloister returns the courtesy.' },
    { ifVisited: 'eldra',   line: 'Eldra reads the psalter most Threndays. She holds the page numbers easier than I do.' },
    { ifVisited: 'cricket', line: 'Cricket reads now. Sir Withering taught him. We\'re all glad — the post wouldn\'t move otherwise.' },
  ],
  npc_onywyn: [
    { ifVisited: 'pell',  line: 'Brother Pell would prefer I sleep at night. I prefer Brother Pell prefer that.' },
    { ifVisited: 'quill', line: 'Quill came up at the smithy after Bramwen passed. The girl knows her herbs. Hod taught her better than he knows.' },
    { ifVisited: 'cook',  line: 'Maud takes the bank fee personally. She and the Cooper sisters are family, on her late husband\'s side.' },
  ],
  cook: [
    { ifVisited: 'eldra',   line: 'Eldra and I take tea every Threnday. Old habit. Old friend.' },
    { ifVisited: 'cricket', line: 'Cricket\'s mother — bless her — was my apprentice once. The boy got her quick fingers and his father\'s short attention.' },
    { ifVisited: 'onywyn',  line: 'Mother Onywyn lives out beyond the briars now. Stubborn old woman. She knows what I think of her foxgloves.' },
    { ifVisited: 'pell',    line: 'Brother Pell still asks after my husband. Twelve years gone, and Pell remembers the date better than I do.' },
  ],
  hod: [
    { ifVisited: 'quill',   line: 'Quill apprenticed under Bramwen, who used to shoe horses here. Different trade, same hands. Good girl.' },
    { ifVisited: 'cricket', line: 'That letter-carrier kid — Cricket — keeps trying to ride my anvil like it\'s a pony. I\'ve told him twice. (He rode it again.)' },
    { ifVisited: 'eldra',   line: 'Eldra brought me a candle for the forge once. Said the dark crept in. Wasn\'t wrong.' },
  ],
  quill: [
    { ifVisited: 'onywyn',  line: 'Mother Onywyn taught me half what I know about foxglove. The other half I learned wrong from her, and had to unlearn.' },
    { ifVisited: 'eldra',   line: 'Eldra fetches her mint from me twice a moon. We don\'t haggle anymore — she just leaves a coin on the bench.' },
    { ifVisited: 'pell',    line: 'Brother Pell preserves herbs in oil for the cloister cellar. He\'s better at it than he admits.' },
  ],
  withering: [
    { ifVisited: 'cricket', line: 'I taught the letter-carrier his alphabet. Pernel watched the whole time, judging his vowels.' },
    { ifVisited: 'pell',    line: 'Brother Pell and I served the same earl, briefly, in different rooms. We don\'t talk about it. We do nod, on Threndays.' },
    { ifVisited: 'onywyn',  line: 'The witch out by the briars — Onywyn — she patched me up once, after a falconry mishap. Charged me two foxgloves and a story.' },
  ],
};
// Mirror: which NPCs have been talked to. We can't easily track existing
// NPCs (Hod, Maud, etc.) without modifying their dialog stubs, so use
// quest flags as proxies — they're set on first contact.
function _hasMet(kind) {
  const q = player.quest.flags;
  switch (kind) {
    case 'cook':      return !!q.cookTalked;
    case 'hod':       return !!q.hodTalked || !!q.hodAccepted;
    case 'quill':     return !!q.quillTalked || !!q.quillAccepted;
    case 'withering': return !!q.witheringTalked || !!q.witheringAccepted;
    case 'eldra':     return !!q.eldraAccepted || !!player.quest.eldraVisited;
    case 'cricket':   return !!q.cricketAccepted || !!player.quest.cricketVisited;
    case 'pell':      return !!q.pellAccepted || !!player.quest.pellVisited;
    case 'onywyn':    return !!q.onywynAccepted || !!player.quest.onywynVisited;
    default: return false;
  }
}
function _gossipFor(npcKind) {
  const pool = (GOSSIP[npcKind] || []).filter(g => _hasMet(g.ifVisited));
  if (!pool.length) return null;
  return pool[Math.floor(Math.random() * pool.length)].line;
}
// Prepend a random met-neighbor gossip line to an NPC's dialog, if any.
function _withGossip(kind, lines) {
  const g = _gossipFor(kind);
  if (g) lines.unshift(g);
  return lines;
}

// Read a lore parchment — opens a dialog with the legend. Doesn't consume.
function readLoreParchment(itemId) {
  const def = ITEMS[itemId];
  if (!def?.lore) return;
  showDialog({
    speaker: def.lore.title,
    lines: [def.lore.body, '— from a folded parchment in your bag.'],
    choices: [{ label: 'Fold it back away' }],
  });
}

function tryNewNpcDialog(tx, ty) {
  for (const n of NEW_NPCS) {
    if (n.tx !== tx || n.ty !== ty) continue;
    // Mark visited so future gossip lookups know we've met this neighbor.
    const visitFlag = n.kind.replace('npc_', '') + 'Visited';
    player.quest[visitFlag] = true;
    if (n.kind === 'npc_eldra')   return openEldra();
    if (n.kind === 'npc_cricket') return openCricket();
    if (n.kind === 'npc_pell')    return openPell();
    if (n.kind === 'npc_onywyn')  return openOnywyn();
    showDialog({ speaker: n.speaker, lines: n.lines });
    return true;
  }
  return false;
}

function openCricket() {
  const q = player.quest;
  const lines = [];
  const choices = [];
  const gossip = _gossipFor('npc_cricket');
  if (gossip) lines.push(gossip);
  if (q.flags.cricketFinished) {
    lines.push('Pibbet says hello! Anytime you need a parcel run, you know where to find me.');
  } else if (q.flags.cricketAccepted && q.cricketDelivered >= 3) {
    lines.push('All three! That\'s a record. Here — a few coins from the tips, and one of my spare reed-pens.');
    choices.push({ label: 'Take the tip', onClick: () => {
      q.flags.cricketFinished = true;
      player.coins = (player.coins || 0) + 30;
      player.inventory.add('hedge_ink', 2);
      log('quest', '★ Cricket\'s Letter Route — done. +30 coins, +2 hedge ink.');
      renderInv(); renderQuest();
    }});
  } else if (q.flags.cricketAccepted) {
    lines.push(`Three drops left to make. (${q.cricketDelivered}/3)`,
               'Look for the wooden mailboxes — there\'s one by each cottage cluster.');
  } else {
    lines.push('Got a letter for someone? I run from valley head to coopers\' gate, three rounds a day.',
               'My friend on my shoulder — that\'s Pibbet. He\'s good at finding addresses I forgot.',
               'Listen — I\'m short three deliveries. Could you drop these at the village mailboxes? Tip\'s yours.');
    choices.push({ label: 'Take the satchel', onClick: () => {
      q.flags.cricketAccepted = true;
      log('quest', '★ Quest started: Cricket\'s Letter Route (0/3)');
      renderQuest();
    }});
  }
  const cricketVessel = vesselCommissionChoice('cricket');
  if (cricketVessel) choices.push(cricketVessel);
  choices.push({ label: 'Leave' });
  showDialog({ speaker: 'Cricket the Letter-Carrier', lines, choices });
  return true;
}

function openPell() {
  const q = player.quest;
  const lines = [];
  const choices = [];
  const gossip = _gossipFor('npc_pell');
  if (gossip) lines.push(gossip);
  if (q.flags.pellFinished) {
    lines.push('The cloister thanks you. Come read whenever the dust feels welcoming.');
  } else if (q.flags.pellAccepted && q.pellRead >= 3) {
    lines.push('All three pages restored — even Brother Wycombe\'s ledger of moths. Take this; it\'s a copy of the older charts you found.');
    choices.push({ label: 'Take the chart copy', onClick: () => {
      q.flags.pellFinished = true;
      player.inventory.add('chart_blank', 3);
      log('quest', '★ Pell\'s Marked Pages — done. +3 blank charts.');
      renderInv(); renderQuest();
    }});
  } else if (q.flags.pellAccepted) {
    lines.push(`Three marked books still in the reading-nook. (${q.pellRead}/3)`,
               'Each has a slip of red ribbon — read until the slip falls out and the page-number\'s safe to file.');
  } else {
    lines.push('Peace to you, traveler. The cloister keeps a small library — old maps, old ledgers, a few pages of bramble-lore.',
               'Three of the books on the reading-bench have come loose. Could you read each through, so I know which page-numbers are still safe?');
    choices.push({ label: 'Accept the task', onClick: () => {
      q.flags.pellAccepted = true;
      log('quest', '★ Quest started: Pell\'s Marked Pages (0/3)');
      renderQuest();
    }});
  }
  choices.push({ label: 'Leave' });
  showDialog({ speaker: 'Brother Pell', lines, choices });
  return true;
}

function openOnywyn() {
  const q = player.quest;
  const lines = [];
  const choices = [];
  const gossip = _gossipFor('npc_onywyn');
  if (gossip) lines.push(gossip);
  const have = player.inventory.count?.('foxglove_sprig') ?? 0;
  if (q.flags.onywynFinished) {
    lines.push('The raven still watches, but kindly now. Bring me herbs whenever the brambles spit them up.');
  } else if (q.flags.onywynAccepted && have >= 5) {
    lines.push('Five sprigs. Good — the bees were nervous all morning, this calms them.',
               'Take this draught. One sip, one wound. Use it once and well.');
    choices.push({ label: 'Take the draught', onClick: () => {
      q.flags.onywynFinished = true;
      player.inventory.remove?.('foxglove_sprig', 5);
      player.inventory.add('healing_draught', 1);
      q.onywynFoxgloves = 5;
      log('quest', '★ Onywyn\'s Foxglove Trade — done. +1 healing draught.');
      renderInv(); renderQuest();
    }});
  } else if (q.flags.onywynAccepted) {
    q.onywynFoxgloves = Math.min(have, 5);
    lines.push(`I need five foxglove sprigs to brew the draught. (${q.onywynFoxgloves}/5)`,
               'They grow in the meadow shoulders along the road — purple-throated, bell-shaped. Bring them whole.');
  } else {
    lines.push('Hush, hush. The raven knows you\'re here. (She gestures with foxglove.)',
               'I trade bitter draughts and bittermint. Bring me five foxglove sprigs from the road-shoulders — I\'ll brew you something useful.');
    choices.push({ label: 'Take the trade', onClick: () => {
      q.flags.onywynAccepted = true;
      log('quest', '★ Quest started: Onywyn\'s Foxglove Trade (0/5)');
      renderQuest();
    }});
  }
  choices.push({ label: 'Leave' });
  showDialog({ speaker: 'Mother Onywyn', lines, choices });
  return true;
}

function openEldra() {
  const q = player.quest;
  const lines = [];
  const choices = [];
  const gossip = _gossipFor('npc_eldra');
  if (gossip) lines.push(gossip);
  if (q.flags.eldraFinished) {
    lines.push('Old hands, old wicks. The lanterns burn easier knowing you\'ve helped tend them.');
  } else if (q.flags.eldraAccepted && q.eldraLanternsLit >= 5) {
    lines.push('All five! Pibbet himself couldn\'t find them faster.',
               'Take this — bottle of lantern oil, four good charges. Save it for a dark hour.');
    choices.push({ label: 'Accept the oil', onClick: () => {
      q.flags.eldraFinished = true;
      player.inventory.add('lantern_oil', 4);
      log('quest', '★ Eldra\'s Lantern Watch — done. +4 lantern oil.');
      renderInv(); renderQuest();
    }});
  } else if (q.flags.eldraAccepted) {
    lines.push(`The dim ones still need lighting. (${q.eldraLanternsLit}/5)`,
               'They\'re scattered along the road and behind the cottages. Walk slow, and the wicks will find you.');
    if (!isLampwrightHour()) {
      lines.push('Mind — the slow-burn oil only catches at dusk and through the dark. Come back when the sky goes pink.');
    }
  } else {
    lines.push('Old hands, old wicks. The lanterns find their light if you tend them, dear.',
               'There are five dim ones still around the village — would you light them by sundown? My knees can\'t do the round these days.');
    choices.push({ label: 'Accept the watch', onClick: () => {
      q.flags.eldraAccepted = true;
      log('quest', '★ Quest started: Eldra\'s Lantern Watch (0/5)');
      renderQuest();
    }});
  }
  choices.push({ label: 'Leave' });
  showDialog({ speaker: 'Eldra the Lampwright', lines, choices });
  return true;
}

function interactAt(tx, ty) {
  if (tryNewNpcDialog(tx, ty)) return true;
  if (tryLightLantern(tx, ty)) return true;
  if (tryDeliverLetter(tx, ty)) return true;
  if (tryReadBook(tx, ty)) return true;
  if (world.cookSpawn && world.cookSpawn.x === tx && world.cookSpawn.y === ty) {
    talkToNpc('cook', player, log, { gossip: _gossipFor('cook') });
    renderQuest(); renderInv(); renderStats(); renderEquipped();
    return true;
  }
  if (MIRROR_TILE.x === tx && MIRROR_TILE.y === ty) {
    openMakeover();
    return true;
  }
  if (CHARTMAKER_TILE.x === tx && CHARTMAKER_TILE.y === ty) {
    openInscriptionFlow();
    return true;
  }
  if (HERBALIST_TILE.x === tx && HERBALIST_TILE.y === ty) {
    openHerbalist();
    return true;
  }
  if (HOD_TILE.x === tx && HOD_TILE.y === ty) {
    openHod();
    return true;
  }
  if (PRACTICE_DUMMY_TILE.x === tx && PRACTICE_DUMMY_TILE.y === ty) {
    return tryPracticeDummy();
  }
  if (WITHERING_TILE.x === tx && WITHERING_TILE.y === ty) {
    openWithering();
    return true;
  }
  if (dungeon.active && dungeon.layout) {
    const ct = dungeon.layout.chestTile;
    if (ct && !dungeon.layout.chestLooted && ct.x === tx && ct.y === ty) {
      lootChest();
      return true;
    }
    if (dungeon.layout.exit.x === tx && dungeon.layout.exit.y === ty) {
      exitDungeon();
      return true;
    }
    const sc = (dungeon.layout.staircases || []).find(s => s.x === tx && s.y === ty);
    if (sc) {
      tryTakeStaircase(sc);
      return true;
    }
    const door = (dungeon.layout.doors || []).find(d => d.x === tx && d.y === ty);
    if (door) {
      _tryOpenDoor(door);
      return true;
    }
  }
  // Village interactions — cottage door notes + Coopers' Hold dialog.
  for (const v of VILLAGE_TILES) {
    if (v.x === tx && v.y === ty) {
      handleVillageTile(v);
      return true;
    }
  }
  if (world.firePos && world.firePos.x === tx && world.firePos.y === ty) {
    return tryCook();
  }
  for (const e of enemies) {
    if (e.alive && e.x === tx && e.y === ty) {
      attackEnemy(player, e, log);
      triggerAttack(player);
      renderStats(); renderInv();
      return true;
    }
  }
  // Dungeon decor (affix-spawned ore / forage / log piles)?
  if (_findDungeonGatherAt(tx, ty)) {
    return tryGatherDungeonDecor(tx, ty);
  }
  // Tree at this tile?
  if (world.trees.find(t => t.x === tx && t.y === ty && !t.depleted)) {
    return tryChopTree(tx, ty);
  }
  // Forage spawn?
  if (world.forageSpawns.find(s => s.x === tx && s.y === ty && !s.depleted)) {
    return tryForage(tx, ty);
  }
  // Ore node?
  if (world.oreNodes && world.oreNodes.find(n => n.x === tx && n.y === ty && !n.depleted)) {
    return tryMineRock(tx, ty);
  }
  // Water tile → fishing
  if (world.tileGrid[ty]?.[tx] === 'water') {
    return tryFish(tx, ty);
  }
  return false;
}

/**
 * Find what's at (tx, ty) for click-targeting purposes.
 * Returns {kind: 'walk'|'entity', target} for pathfinding logic.
 */
function classifyTile(tx, ty) {
  // In a dungeon, only enemies, walls, the exit stair, the chest, and
  // affix-spawned gather nodes matter.
  if (dungeon.active && dungeon.layout) {
    for (const e of enemies) if (e.alive && e.x === tx && e.y === ty) return 'entity';
    if (dungeon.layout.exit.x === tx && dungeon.layout.exit.y === ty) return 'entity';
    const ct = dungeon.layout.chestTile;
    if (ct && !dungeon.layout.chestLooted && ct.x === tx && ct.y === ty) return 'entity';
    if ((dungeon.layout.staircases || []).some(s => s.x === tx && s.y === ty)) return 'entity';
    // Locked doors are interactable (entity) so click-to-walk paths to
    // them and fires interactAt to attempt the unlock.
    if ((dungeon.layout.doors || []).some(d => d.x === tx && d.y === ty && d.locked !== false)) return 'entity';
    if (_findDungeonGatherAt(tx, ty)) return 'entity';
    if (dungeon.layout.blocked(tx, ty)) return 'unwalkable';
    return 'walkable';
  }
  if (world.cookSpawn && world.cookSpawn.x === tx && world.cookSpawn.y === ty) return 'entity';
  if (world.firePos && world.firePos.x === tx && world.firePos.y === ty) return 'entity';
  if (MIRROR_TILE.x === tx && MIRROR_TILE.y === ty) return 'entity';
  if (CHARTMAKER_TILE.x === tx && CHARTMAKER_TILE.y === ty) return 'entity';
  if (HERBALIST_TILE.x === tx && HERBALIST_TILE.y === ty) return 'entity';
  if (HOD_TILE.x === tx && HOD_TILE.y === ty) return 'entity';
  if (PRACTICE_DUMMY_TILE.x === tx && PRACTICE_DUMMY_TILE.y === ty) return 'entity';
  if (WITHERING_TILE.x === tx && WITHERING_TILE.y === ty) return 'entity';
  for (const v of VILLAGE_TILES) if (v.x === tx && v.y === ty) return 'entity';
  for (const e of enemies) if (e.alive && e.x === tx && e.y === ty) return 'entity';
  if (world.forageSpawns.find(s => s.x === tx && s.y === ty && !s.depleted)) return 'entity';
  if (world.oreNodes && world.oreNodes.find(n => n.x === tx && n.y === ty && !n.depleted)) return 'entity';
  // Trees are entities (chop them by walking adjacent), not unwalkable.
  for (const t of world.trees) if (t.x === tx && t.y === ty && !t.depleted) return 'entity';
  if (world.tileGrid[ty]?.[tx] === 'water') return 'entity';
  if (world.isTerrainBlocked(tx, ty)) return 'unwalkable';
  return 'walkable';
}

const FACING = { down: [0, 1], up: [0, -1], left: [-1, 0], right: [1, 0] };

function tryInteractInFront() {
  const [dx, dy] = FACING[player.dir];
  if (interactAt(player.x + dx, player.y + dy)) return true;
  if (interactAt(player.x, player.y)) return true;
  // Nothing was in range. Stay quiet when Space-fallback-to-dodge is in
  // play; otherwise nudge the player.
  if (!_interactSilent) log('hint', 'Nothing in front of you.');
  return false;
}
// Set to true by the Space dodge-fallback path so a no-op interact attempt
// doesn't log "Nothing in front of you." every time the player just wanted
// to dodge in open ground.
let _interactSilent = false;

/** Boss intro — show the centered name banner for ~2.5s. Idempotent: calling
 *  while a banner is already shown re-arms with the new boss name. */
let _bossBannerHideT = null;
function showBossBanner(name, subtitle) {
  const el = document.getElementById('boss-banner');
  if (!el) return;
  el.querySelector('.boss-banner-name').textContent = name;
  el.querySelector('.boss-banner-sub').textContent = subtitle || '';
  el.classList.add('boss-banner-show');
  if (_bossBannerHideT) clearTimeout(_bossBannerHideT);
  _bossBannerHideT = setTimeout(() => {
    el.classList.remove('boss-banner-show');
    _bossBannerHideT = null;
  }, 2500);
}
// Expose to enemies.js via a global hook — same pattern as the spark scene
// setter. Avoids a hard import cycle.
window.__gj26_showBossBanner = showBossBanner;

/** Spawn the standard heal-flash effect on the player after a successful
 *  food eat. Green sparkle ring + "+N HP" floater above the head. */
function spawnHealFlash(healAmount) {
  const head = new THREE.Vector3(player.pos.x, player.pos.y + 1.5, player.pos.z);
  spawnFloat(head, `+${healAmount} HP`, 'heal');
  const ring = new THREE.Vector3(player.pos.x, player.pos.y + 0.6, player.pos.z);
  spawnHitSparks(ring, {
    count: 18, spread: 1.2, color: 0x6fc46a, size: 6, life: 0.55,
  });
  import('./core/sfx.js').then(m => m.sfx.pickup());
}

/** Use the Falcon's Whistle. Sends Pernel on a scouting circle:
 *  reveals a 5-tile radius around the player on the minimap, spawns a
 *  temporary flyby visual, logs a beat. 30s cooldown stored on the
 *  player so the timer survives across saves.
 */
let _whistleAt = -Infinity;
function useFalconsWhistle() {
  const COOLDOWN_MS = 30000;
  const now = performance.now();
  if (now - _whistleAt < COOLDOWN_MS) {
    const left = Math.ceil((COOLDOWN_MS - (now - _whistleAt)) / 1000);
    log('hint', `Pernel is still circling. (${left}s)`);
    return;
  }
  _whistleAt = now;
  // Reveal a 5-tile radius around the player as "explored".
  const px = player.x, py = player.y;
  const R = 5;
  for (let dy = -R; dy <= R; dy++) {
    for (let dx = -R; dx <= R; dx++) {
      if (dx*dx + dy*dy > R*R) continue;
      const tx = px + dx, ty = py + dy;
      if (tx < 0 || ty < 0) continue;
      player.exploredTiles.add(`${tx},${ty}`);
    }
  }
  // Briefly land a falcon visual circling overhead. Reuse the existing
  // companion mesh — pull it into a higher orbit for ~3s and back.
  if (typeof falcon !== 'undefined' && falcon?.scoutT !== undefined) {
    falcon.scoutT = 3.0;
  }
  // Audio + visual flourish
  import('./core/sfx.js').then(m => {
    m.sfx.craft();   // sharp double-chink reads as a whistle blast
    setTimeout(() => m.sfx.craft(), 90);
  });
  spawnHitSparks(new THREE.Vector3(player.pos.x, player.pos.y + 1.4, player.pos.z), {
    count: 8, spread: 1.4, color: 0xeae0c8, size: 6, life: 0.5,
  });
  log('quest', '🪈 You blow the whistle. Pernel circles overhead, scouting.');
}

/** Open the journal — a one-shot dialog showing the player's active
 *  questlines via questSummary(). Status colours map to the same kinds
 *  as the chronicle log (active = warm, done = green-muted, pending = dim).
 */
function openJournal() {
  const entries = questSummary(player.quest);
  const lines = entries.length
    ? entries.map(e => {
        const mark = e.state === 'done'    ? '✓'
                   : e.state === 'pending' ? '·'
                                            : '★';
        return `${mark} ${e.text}`;
      })
    : ['Your journal is empty. Talk to Maud, Hod, Quill, or Sir Withering to find work.'];
  showDialog({
    speaker: 'Journal',
    lines,
    choices: [{ label: 'Close' }],
  });
}

/** Quick-eat the smallest-heal food we have. Picks the lowest food.heal
 *  value so big foods are reserved for emergencies; if multiple share
 *  the smallest heal, picks the first slot found.
 *  Skips when at full HP — the keystroke shouldn't waste a ration. */
function tryQuaffPotion() {
  if (player.hp >= player.hpMax) {
    log('hint', 'You are at full health.');
    return;
  }
  let bestIdx = -1, bestHeal = Infinity;
  for (let i = 0; i < player.inventory.slots.length; i++) {
    const slot = player.inventory.slots[i];
    if (!slot) continue;
    const def = ITEMS[slot.id];
    if (!def?.food?.heal) continue;
    if (def.food.heal < bestHeal) {
      bestHeal = def.food.heal;
      bestIdx = i;
    }
  }
  if (bestIdx === -1) {
    log('hint', 'No food on you.');
    return;
  }
  const r = player.inventory.use(bestIdx, player);
  if (r?.kind === 'eat') {
    log('hint', `Ate ${ITEMS[r.id].name}: +${r.heal} HP.`);
    spawnHealFlash(r.heal);
    renderInv(); renderStats();
  } else if (r?.kind === 'full_hp') {
    log('hint', 'You are at full health.');
  }
}

// ---------- CARTOGRAPHY: SKETCH VERB ----------
// Find the nearest sketchable subject within 2 tiles. Returns one of
// trees / forage / enemies / NPC landmarks, with metadata for the
// channel + XP grant. Order matters: creatures > curiosity > settlement
// > flora > terrain (rare beats common when stacked on one tile).
function nearestSketchSubject() {
  const px = player.x, py = player.y;
  const R = 2;
  const cands = [];
  const dist = (x, y) => Math.max(Math.abs(x - px), Math.abs(y - py));

  // Creatures (alive enemies near player)
  for (const e of enemies) {
    if (!e.alive) continue;
    const d = dist(e.x, e.y);
    if (d > R) continue;
    cands.push({
      id: e.kind, name: e.displayName || (e.kind === 'goblin' ? 'Bramble-imp' : e.kind),
      category: 'creature', baseXp: 25, x: e.x, y: e.y, d, rank: 4,
    });
  }
  // Settlement landmarks (named NPCs / structures)
  const lms = [];
  if (typeof HOD_TILE !== 'undefined')        lms.push({ id: 'npc_hod',       name: 'Hod the Smith',       x: HOD_TILE.x,        y: HOD_TILE.y });
  if (typeof HERBALIST_TILE !== 'undefined')  lms.push({ id: 'npc_quill',     name: 'Quill the Herbalist', x: HERBALIST_TILE.x,  y: HERBALIST_TILE.y });
  if (typeof WITHERING_TILE !== 'undefined')  lms.push({ id: 'npc_withering', name: 'Sir Withering',       x: WITHERING_TILE.x,  y: WITHERING_TILE.y });
  if (typeof CHARTMAKER_TILE !== 'undefined') lms.push({ id: 'chartmaker',    name: "Chartmaker's Stone",  x: CHARTMAKER_TILE.x, y: CHARTMAKER_TILE.y });
  if (typeof MIRROR_TILE !== 'undefined')     lms.push({ id: 'mirror',        name: 'Looking Glass',       x: MIRROR_TILE.x,     y: MIRROR_TILE.y });
  if (world.firePos)   lms.push({ id: 'hearth',  name: 'Village Hearth', x: world.firePos.x,   y: world.firePos.y });
  if (world.cookSpawn) lms.push({ id: 'npc_cook', name: 'Cook',          x: world.cookSpawn.x, y: world.cookSpawn.y });
  for (const l of lms) {
    const d = dist(l.x, l.y);
    if (d > R) continue;
    cands.push({ ...l, category: 'settlement', baseXp: 30, d, rank: 3 });
  }
  // Flora — trees, forage
  for (const t of (world.trees || [])) {
    if (t.depleted) continue;
    const d = dist(t.x, t.y);
    if (d > R) continue;
    cands.push({
      id: t.kind || 'oak', name: 'Oak',
      category: 'flora', baseXp: 15, x: t.x, y: t.y, d, rank: 2,
    });
  }
  for (const f of (world.forageSpawns || [])) {
    if (f.depleted) continue;
    const d = dist(f.x, f.y);
    if (d > R) continue;
    const id = f.kind || f.item || 'forage';
    const name = ITEMS[f.item]?.name || id.replace(/_/g, ' ');
    cands.push({ id, name, category: 'flora', baseXp: 15, x: f.x, y: f.y, d, rank: 2 });
  }
  if (!cands.length) return null;
  // Higher rank wins; within same rank, closer wins.
  cands.sort((a, b) => (b.rank - a.rank) || (a.d - b.d));
  return cands[0];
}

function trySketch() {
  if (player.sketchT > 0) {
    log('hint', '📓 Already sketching. Hold still.');
    return;
  }
  if (!player.inventory.count('field_journal') || player.inventory.count('charcoal_stick') < 1) {
    log('hint', '📓 You need a Field Journal and a Charcoal Stick to sketch.');
    return;
  }
  const subject = nearestSketchSubject();
  if (!subject) {
    log('hint', '📓 Nothing sketchable nearby. Walk closer to a feature.');
    return;
  }
  // Stop the player so the sketch channel doesn't auto-cancel from
  // pathfinding drift.
  if (player.path && player.path.length) {
    player.path = [];
    player.onPathDone = null;
    if (player.clickMarker) player.clickMarker.visible = false;
  }
  player.moving = false;
  player.targetX = player.x;
  player.targetY = player.y;
  player.pos.x = player.x + 0.5;
  player.pos.z = player.y + 0.5;
  player.sketchT = 1.5;
  player.sketchSubject = subject;
  player.sketchAnchor = { x: player.pos.x, z: player.pos.z };
  log('skill', `📓 Sketching ${subject.name}...`);
}

function tickSketchChannel(dt) {
  if (player.sketchT <= 0) return;
  // Cancel if the player moved far enough that the line drifts.
  const dx = player.pos.x - player.sketchAnchor.x;
  const dz = player.pos.z - player.sketchAnchor.z;
  if (dx*dx + dz*dz > 0.05) {
    player.sketchT = 0;
    player.sketchSubject = null;
    log('hint', '📓 Sketch smudged — you moved.');
    return;
  }
  player.sketchT -= dt;
  if (player.sketchT <= 0) {
    completeSketch(player.sketchSubject);
    player.sketchSubject = null;
  }
}

function completeSketch(subject) {
  // Lookup prior sketches of this id; first-time sketches award full XP,
  // re-sketches award 30% (refresh-tier; full sketch decay is Phase C).
  const prior = (player.sketches || []).find(s => s.id === subject.id);
  let xp = subject.baseXp;
  if (prior) xp = Math.max(2, Math.floor(subject.baseXp * 0.30));
  // Spend one charcoal per sketch
  player.inventory.remove('charcoal_stick', 1);
  // Record (or refresh) the sketch entry
  const now = Date.now();
  if (prior) {
    prior.sketchedAt = now;
    prior.count = (prior.count || 1) + 1;
  } else {
    (player.sketches ||= []).push({
      id: subject.id, name: subject.name, category: subject.category,
      sketchedAt: now, count: 1,
    });
  }
  // Persist
  try { localStorage.setItem('gj26.sketches', JSON.stringify(player.sketches)); } catch (_) {}
  // No Wayfinding XP — sketches are journal pages, not maps. Wayfinding
  // XP only flows from chart inscription + dungeon completion.
  spawnFloat(new THREE.Vector3(player.pos.x, player.pos.y + 1.8, player.pos.z),
    prior ? `📓 Refreshed: ${subject.name}` : `📓 New sketch: ${subject.name}`,
    prior ? 'hint' : 'level');
  // Surface this in the Wayfinding Workshop's session counter so the
  // player sees that out-of-workshop sketching feeds the carto loop.
  noteSketchThisSession(subject.name);
  renderInv();
}

/** Element → spark color for the projectile burst. */
const SPELL_COLORS = {
  air:    0xc0e0ff,
  water:  0x5a90c8,
  earth:  0x8a7050,
  fire:   0xff7a3a,
  mind:   0xd0d0e0,
  body:   0xfac0c0,
  chaos:  0xc070d0,
  cosmic: 0xfff8c0,
  death:  0x303040,
  blood:  0xc02030,
  nature: 0x6fa050,
  law:    0xc8b870,
  soul:   0xfff8e0,
};

/** Cast the player's active spell. R hotkey hits this. */
function tryCastActiveSpell() {
  const id = player.activeSpell || 'wind_strike';
  const r = castSpell(player, id, log);
  if (!r.ok) {
    log('hint', `✦ ${r.reason}`);
    return;
  }
  const s = r.spell;
  // Damage spells: apply target effects
  if (s.effect === 'damage') {
    const t = r.target;
    const wp = new THREE.Vector3(t.pos.x, t.pos.y + 1.2, t.pos.z);
    spawnFloat(wp, `${s.name} −${r.dmg}`, 'hit');
    const enemyLabel = t.kind === 'goblin' ? 'Bramble-imp' : t.kind;
    log('combat', `✦ ${s.name} hits ${r.dmg}. (${enemyLabel} ${t.hp}/${t.hpMax})`);
    // Particles colored to the element
    import('./scene/sparks.js').then(m => m.spawnHitSparks(wp,
      { count: 16, spread: 1.6, color: SPELL_COLORS[s.element] || 0xc0e0ff, size: 5, life: 0.4 }));
    if (t.hp <= 0) {
      t.alive = false;
      t.respawn = 60 * 30;
      if (t.mesh) t.mesh.visible = false;
      log('combat', `☠ Felled by ${s.name}.`);
      if (t.onDeath) t.onDeath(player, log);
      player.combatTarget = null;
    }
  } else {
    // Utility / buff / travel — fire side-effect handler
    runUtilitySpell(s);
    log('combat', `✦ ${s.name} cast.`);
    spawnFloat(new THREE.Vector3(player.pos.x, player.pos.y + 1.5, player.pos.z),
      `✦ ${s.name}`, 'level');
  }
  // Magic XP
  import('./game/skills.js').then(m => m.awardXp(player, 'magic', s.xpOnCast || 10, log,
    { worldPos: new THREE.Vector3(player.pos.x, player.pos.y + 1.4, player.pos.z) }));
  renderInv(); renderStats();
}

/** Per-spell side-effects for utility/buff/travel spells. */
function runUtilitySpell(spell) {
  switch (spell.id) {
    case 'sense_aggro': {
      // Reveal aggroed enemies on the minimap for the duration. Phase B
      // simplification: tag a player flag the minimap can read.
      player.senseAggroT = (spell.duration || 60);
      break;
    }
    case 'quench_stamina': {
      const max = player.staminaMax ?? 100;
      const before = player.stamina ?? 0;
      player.stamina = Math.min(max, before + 30);
      // Restoring above 0 lifts the exhausted lockout immediately.
      if (player.stamina > 0) player.exhaustedT = 0;
      log('combat', `✦ Quench: +${(player.stamina - before).toFixed(0)} stamina.`);
      break;
    }
    case 'stone_skin': {
      player.stoneSkinT = (spell.duration || 30);
      log('combat', '✦ Stone Skin: +30% defence for 30s.');
      break;
    }
    case 'vigor': {
      // Heal over time — 3 hp/sec for 10s. Implemented as a flag the
      // main loop reads.
      player.vigorT = 10;
      break;
    }
    case 'teleport_bramblewood': {
      const sx = world.spawn.x, sy = world.spawn.y;
      player.x = sx; player.y = sy;
      player.targetX = sx; player.targetY = sy;
      player.path = [];
      player.pos.x = sx + 0.5; player.pos.z = sy + 0.5;
      log('quest', '✦ The world folds — you stand in Bramblewood.');
      break;
    }
    case 'teleport_chartmaker': {
      if (typeof CHARTMAKER_TILE !== 'undefined') {
        player.x = CHARTMAKER_TILE.x; player.y = CHARTMAKER_TILE.y;
        player.targetX = CHARTMAKER_TILE.x; player.targetY = CHARTMAKER_TILE.y;
        player.path = [];
        player.pos.x = CHARTMAKER_TILE.x + 0.5; player.pos.z = CHARTMAKER_TILE.y + 0.5;
        log('quest', '✦ Cosmic warp — you step into the chartmaker\'s clearing.');
      }
      break;
    }
    // ignite / quiet_thought / levitate / bind_plant / animal_sight /
    // holdinghut / blood_pact / soul_bind — all flagged stub:true and
    // short-circuited inside castSpell, so they cannot reach this handler.
  }
}

/** Cycle player.combatTarget to the next-nearest alive enemy in range.
 *  Range 8 tiles (Manhattan). If no current target, picks the closest;
 *  otherwise picks the next-closest (skipping the current). Always wraps. */
function cycleCombatTarget() {
  const RANGE = 8;
  const candidates = enemies
    .filter(e => e.alive && Math.abs(e.x - player.x) + Math.abs(e.y - player.y) <= RANGE)
    .sort((a, b) =>
      (Math.abs(a.x - player.x) + Math.abs(a.y - player.y)) -
      (Math.abs(b.x - player.x) + Math.abs(b.y - player.y))
    );
  if (candidates.length === 0) {
    if (player.combatTarget) {
      player.combatTarget = null;
      log('hint', 'No targets in range.');
    } else {
      log('hint', 'No targets nearby.');
    }
    return;
  }
  const cur = player.combatTarget;
  const idx = cur ? candidates.indexOf(cur) : -1;
  const next = candidates[(idx + 1) % candidates.length];
  player.combatTarget = next;
  const label = next.displayName || (next.kind === 'goblin' ? 'Bramble-imp' : next.kind);
  log('combat', `Targeting ${label}.`);
  // Auto-walk adjacent so the player engages without a second click.
  // If the target is already adjacent, attack immediately.
  const dx = Math.abs(next.x - player.x);
  const dy = Math.abs(next.y - player.y);
  if (dx + dy <= 1) {
    attackEnemy(player, next, log);
    triggerAttack(player);
    renderStats(); renderInv();
    return;
  }
  const path = pathToAdjacent(
    { x: player.x, y: player.y },
    { x: next.x,   y: next.y   },
    isBlocked
  );
  if (path !== null) {
    setPath(player, path, () => {
      // On arrival, fire one swing — the auto-attack tick keeps the
      // pressure on after that.
      if (next.alive) {
        attackEnemy(player, next, log);
        triggerAttack(player);
        renderStats(); renderInv();
      }
    });
  }
}

// Track the most recently fired ability slot so the action bar can show
// a green-border "active" hint on it. Defaults to slot 1 to match the
// wireframe's first-slot-selected look.
let _activeSlot = 1;

/** Activate the action bound to slot (1..8). Dispatches by action kind:
 *  melee → ABILITIES.run, magic → castSpell, ranged → projectile. */
function tryUseAbility(slot) {
  const id = player.actionBar?.[slot - 1];
  if (!id) return false;
  const a = getAction(id);
  if (!a) return false;
  // Locked / can't afford — log a hint on direct presses, but stay silent
  // when the input buffer is retrying. The hint already fired on the first
  // attempt; spamming it every frame for 250ms would clobber the log.
  const reason = actionMissingReason(player, id);
  if (reason) {
    if (!player._abilityBuffer || player._abilityBuffer.slot !== slot) {
      log('hint', reason);
    }
    return false;
  }
  // Cooldown check via per-id cooldown map. Buffered presses retry every
  // frame and quietly fail until the cd clears.
  player.actionCd ||= {};
  if ((player.actionCd[id] || 0) > 0) return false;

  let fired = false;
  if (a.kind === 'melee') {
    fired = tryActivateAbility(player, slot, { enemies, log, isBlocked });
  } else if (a.kind === 'magic') {
    fired = castFromActionBar(id, a);
  } else if (a.kind === 'ranged') {
    fired = fireRanged(id, a);
  } else if (a.kind === 'utility') {
    fired = fireUtility(id, a);
  }
  if (fired) {
    _activeSlot = slot;
    player.actionCd[id] = a.cooldown;
    player.actionFireT ||= {};
    player.actionFireT[id] = 0.25;
    renderStats(); renderInv(); renderSkillBar();
  }
  return fired;
}

/** Magic spell cast from the action bar. Reuses tryCastActiveSpell's
 *  feel (particles, XP, log, target death) but for an arbitrary spell id. */
function castFromActionBar(spellId, action) {
  // Temporarily set activeSpell to this id, run the existing pipeline,
  // then restore. Cheaper than duplicating the cast/fx code.
  const prev = player.activeSpell;
  player.activeSpell = spellId;
  tryCastActiveSpell();
  player.activeSpell = prev;
  return true;
}

/** Bindable utility actions — Quaff, Eat, Sketch. Dispatched from the
 *  action bar; reuses the existing single-purpose handlers. */
function fireUtility(actionId, action) {
  switch (actionId) {
    case 'quaff_potion':
    case 'eat_food': {
      // Both flow through tryQuaffPotion (smallest-heal-first). The eat
      // variant could pick the largest food in a future pass.
      tryQuaffPotion();
      return true;
    }
    case 'sketch_nearby': {
      trySketch();
      return true;
    }
    default:
      log('hint', `${action.name} — not yet wired.`);
      return false;
  }
}

/** Fire a ranged attack at the locked target. Now handles single-target
 *  (Quickshot, Aimed Shot, Falcon Strike) and AoE (Volley). */
function fireRanged(actionId, action) {
  const primary = player.combatTarget;
  if (!primary || !primary.alive) {
    log('hint', 'No target. Click an enemy first.');
    return false;
  }
  const dx = primary.x - player.x, dy = primary.y - player.y;
  const dist = Math.sqrt(dx*dx + dy*dy);
  if (dist > (action.range || 8)) {
    log('hint', `Out of range (${dist.toFixed(0)} > ${action.range}).`);
    return false;
  }
  // Falcon Strike requires an idle falcon (post-MVP polish — for now log and continue).
  if (action.isFalcon && falcon?.mode && falcon.mode !== 'idle') {
    log('hint', 'Your falcon is busy. Try again in a moment.');
    return false;
  }
  // Spend stamina
  if (action.cost?.stamina) {
    player.stamina = Math.max(0, (player.stamina ?? 0) - action.cost.stamina);
    if (player.stamina <= 0) player.exhaustedT = Math.max(player.exhaustedT || 0, 3.0);
  }
  // Build target list — single + AoE neighbors if action.aoe set
  const targets = [primary];
  if (action.aoe && action.aoe > 0) {
    for (const e of enemies) {
      if (!e.alive || e === primary) continue;
      const ex = Math.abs(e.x - primary.x), ey = Math.abs(e.y - primary.y);
      if (ex <= action.aoe && ey <= action.aoe) targets.push(e);
    }
  }
  let totalDmg = 0;
  for (const t of targets) {
    const min = action.minDmg || 4, max = action.maxDmg || 8;
    const dmg = min + Math.floor(Math.random() * (max - min + 1));
    t.hp = Math.max(0, t.hp - dmg);
    t.flashT = 0.2;
    t.hurtT = 8;
    totalDmg += dmg;
    const wp = new THREE.Vector3(t.pos.x, t.pos.y + 1.2, t.pos.z);
    spawnFloat(wp, `−${dmg}`, 'hit');
    import('./scene/sparks.js').then(m => m.spawnHitSparks(wp,
      { count: action.isFalcon ? 18 : 12, spread: 1.4,
        color: action.isFalcon ? 0xfff2a0 : 0xc8a060,
        size: action.isFalcon ? 7 : 5, life: 0.35 }));
    if (t.hp <= 0) {
      t.alive = false;
      t.respawn = 60 * 30;
      if (t.mesh) t.mesh.visible = false;
      log('combat', `☠ ${t.kind === 'goblin' ? 'Bramble-imp' : t.kind} felled by ${action.name}.`);
      if (t.onDeath) t.onDeath(player, log);
      if (t === player.combatTarget) player.combatTarget = null;
    }
  }
  const icon = action.isFalcon ? '🦅' : '🏹';
  log('combat', targets.length > 1
    ? `${icon} ${action.name} hits ${targets.length} for ${totalDmg} total.`
    : `${icon} ${action.name} hits ${totalDmg}. (${primary.kind === 'goblin' ? 'Bramble-imp' : primary.kind} ${primary.hp}/${primary.hpMax})`);
  // Falcon Strike sets the falcon mode → returning so it's busy briefly
  if (action.isFalcon && falcon) {
    falcon.mode = 'returning';
  }
  // Falconry XP grant — scales with hits and AoE size
  const xpGain = 10 * targets.length + (action.aoe ? 5 : 0);
  import('./game/skills.js').then(m => m.awardXp(player, 'falconry', xpGain, log,
    { worldPos: new THREE.Vector3(primary.pos.x, primary.pos.y + 1.2, primary.pos.z) }));
  return true;
}

function smoothstep(a, b, x) {
  const t = Math.max(0, Math.min(1, (x - a) / (b - a)));
  return t * t * (3 - 2 * t);
}

// ---------- CONTEXT MENU ----------
const ctxMenu = document.getElementById('ctx-menu');
const ctxItemsEl = ctxMenu.querySelector('.ctx-items');
const ctxTitleEl = ctxMenu.querySelector('.ctx-title');

function hideContextMenu() {
  ctxMenu.style.display = 'none';
  ctxItemsEl.innerHTML = '';
}

document.addEventListener('mousedown', e => {
  if (!ctxMenu.contains(e.target)) hideContextMenu();
});
window.addEventListener('keydown', e => {
  if (e.key === 'Escape') hideContextMenu();
  if (e.key === 'Shift') player.runHeld = true;
});
window.addEventListener('keyup', e => {
  if (e.key === 'Shift') player.runHeld = false;
});

/** Build a list of {label, action} options for whatever's at (tx, ty). */
function buildContextOptions(tx, ty) {
  const items = [];
  const start = () => ({ x: player.x, y: player.y });
  const goal = { x: tx, y: ty };

  // helpers
  const walkAdjacent = (then) => {
    const path = pathToAdjacent(start(), goal, isBlocked);
    if (path !== null) {
      setPath(player, path, () => {
        const dx = Math.sign(goal.x - player.x);
        const dy = Math.sign(goal.y - player.y);
        if (dy === -1) player.dir = 'up';
        else if (dy === 1) player.dir = 'down';
        else if (dx === -1) player.dir = 'left';
        else if (dx === 1) player.dir = 'right';
        if (then) then();
      });
    } else log('hint', "Can't get to that.");
  };
  const walkTo = () => {
    player.combatTarget = null;          // explicit "Walk here" disengages
    const path = findPath(start(), goal, isBlocked);
    if (path !== null) setPath(player, path);
    else log('hint', "Can't get there.");
  };

  // Cook NPC (Maud)
  if (world.cookSpawn && world.cookSpawn.x === tx && world.cookSpawn.y === ty) {
    items.push({
      label: `<span class="verb">Talk to</span> <span class="target">${NPC_DEFS.cook.name}</span>`,
      action: () => walkAdjacent(() => interactAt(tx, ty)),
    });
    items.push({
      label: `<span class="verb">Examine</span> <span class="target">${NPC_DEFS.cook.name}</span>`,
      action: () => log('quest', 'Maud Pennycress, the village matron — silver hair, sharp tongue.'),
    });
  }
  // Hod the smith
  else if (HOD_TILE.x === tx && HOD_TILE.y === ty) {
    items.push({
      label: `<span class="verb">Talk to</span> <span class="target">${NPC_DEFS.hod.name}</span>`,
      action: () => walkAdjacent(() => interactAt(tx, ty)),
    });
    items.push({
      label: `<span class="verb">Examine</span> <span class="target">${NPC_DEFS.hod.name}</span>`,
      action: () => log('quest', 'A barrel-chested smith. Apron, hammer, look that says \"don\'t lean on the anvil.\"'),
    });
  }
  // Sir Withering
  else if (WITHERING_TILE.x === tx && WITHERING_TILE.y === ty) {
    items.push({
      label: `<span class="verb">Talk to</span> <span class="target">${NPC_DEFS.withering.name}</span>`,
      action: () => walkAdjacent(() => interactAt(tx, ty)),
    });
    items.push({
      label: `<span class="verb">Examine</span> <span class="target">${NPC_DEFS.withering.name}</span>`,
      action: () => log('quest', 'Sir Withering of Trelliswick — older knight, falcon Pernel on his arm.'),
    });
  }
  // Quill the herbalist (HERBALIST_TILE)
  else if (HERBALIST_TILE.x === tx && HERBALIST_TILE.y === ty) {
    items.push({
      label: `<span class="verb">Talk to</span> <span class="target">${NPC_DEFS.quill.name}</span>`,
      action: () => walkAdjacent(() => interactAt(tx, ty)),
    });
    items.push({
      label: `<span class="verb">Examine</span> <span class="target">${NPC_DEFS.quill.name}</span>`,
      action: () => log('quest', 'Quill — auburn curls, green cloak. Smells of meadowsweet.'),
    });
  }
  // Fire (cooking range / forge)
  else if (world.firePos && world.firePos.x === tx && world.firePos.y === ty) {
    items.push({
      label: '<span class="verb">Cook on</span> <span class="target">Fire</span>',
      action: () => walkAdjacent(() => interactAt(tx, ty)),
    });
    // Surface every smith/smelt recipe the player can do with their bag +
    // skill level. Keeps the menu honest — entries only show if doable.
    for (const [actionId, r] of Object.entries(SMITH_RECIPES)) {
      if (r.reqLevel && player.skills.earth.lv < r.reqLevel) continue;
      let doable = true;
      if (r.kind === 'smelt') {
        for (const [oreId, n] of Object.entries(r.inputs)) {
          if (player.inventory.count(oreId) < n) { doable = false; break; }
        }
      } else if (player.inventory.count(r.bars) < r.count) {
        doable = false;
      }
      if (!doable) continue;
      const verb = r.kind === 'smelt' ? 'Smelt' : 'Smith';
      const target = r.label.replace(/^(Smelt|Smith)\s+/, '');
      items.push({
        label: `<span class="verb">${verb}</span> <span class="target">${target}</span>`,
        action: () => walkAdjacent(() => trySmeltOrSmith(actionId)),
      });
    }
    items.push({
      label: '<span class="verb">Examine</span> <span class="target">Fire</span>',
      action: () => log('hint', 'A small fire — cooking, smelting, smithing.'),
    });
  }
  // Enemy?
  else {
    const enemy = enemies.find(e => e.alive && e.x === tx && e.y === ty);
    if (enemy) {
      const name = enemy.kind === 'goblin' ? 'Bramble-imp' : 'Cow';
      items.push({
        label: `<span class="verb">Attack</span> <span class="target">${name}</span>`,
        action: () => walkAdjacent(() => interactAt(tx, ty)),
      });
      items.push({
        label: `<span class="verb">Send Falcon at</span> <span class="target">${name}</span>`,
        action: () => sendFalcon(enemy),
      });
      items.push({
        label: `<span class="verb">Examine</span> <span class="target">${name}</span>`,
        action: () => log('hint',
          enemy.kind === 'goblin'
            ? 'A mossy bramble-imp clutching a thorn-studded club.'
            : 'A docile cow. Drops raw beef + wool_flank on death.'),
      });
    }
  }

  // Tree at this tile?
  const treeNode = world.trees.find(t => t.x === tx && t.y === ty && !t.depleted);
  if (treeNode) {
    if (treeNode.kind === 'oak') {
      items.push({
        label: `<span class="verb">Chop</span> <span class="target">Oak</span>`,
        action: () => walkAdjacent(() => interactAt(tx, ty)),
      });
    }
    items.push({
      label: `<span class="verb">Examine</span> <span class="target">${treeNode.kind === 'oak' ? 'Oak' : 'Tree'}</span>`,
      action: () => log('hint', treeNode.kind === 'oak'
        ? 'A sturdy oak. Yields logs when chopped with an axe.'
        : 'A tree. Cannot be chopped.'),
    });
  }
  // Dungeon decor — affix-spawned ore / forage / log piles. Verb depends
  // on kind; matches the overworld phrasing for consistency.
  const dungeonDecor = _findDungeonGatherAt(tx, ty);
  if (dungeonDecor) {
    const def = ITEMS[dungeonDecor.item];
    const itemName = def?.name || dungeonDecor.item;
    const verb = dungeonDecor.kind === 'ore_rock' ? 'Mine'
               : dungeonDecor.kind === 'log_pile' ? 'Chop'
               : 'Pick';
    items.push({
      label: `<span class="verb">${verb}</span> <span class="target">${itemName}</span>`,
      action: () => walkAdjacent(() => interactAt(tx, ty)),
    });
  }
  // Forage spawn?
  const forage = world.forageSpawns.find(s => s.x === tx && s.y === ty && !s.depleted);
  if (forage) {
    const def = ITEMS[forage.item];
    items.push({
      label: `<span class="verb">Pick</span> <span class="target">${def.name}</span>`,
      action: () => walkAdjacent(() => interactAt(tx, ty)),
    });
  }
  // Ore node?
  const ore = world.oreNodes && world.oreNodes.find(n => n.x === tx && n.y === ty && !n.depleted);
  if (ore) {
    items.push({
      label: `<span class="verb">Mine</span> <span class="target">${ore.kind === 'copper' ? 'Copper Ore' : 'Tin Ore'}</span>`,
      action: () => walkAdjacent(() => interactAt(tx, ty)),
    });
  }
  // Water tile → fishing
  if (world.tileGrid[ty]?.[tx] === 'water') {
    items.push({
      label: `<span class="verb">Fish at</span> <span class="target">Water</span>`,
      action: () => walkAdjacent(() => interactAt(tx, ty)),
    });
  }

  // Walk-here always available if the tile is at all reachable
  const cls = classifyTile(tx, ty);
  if (cls === 'walkable') {
    items.push({
      label: `<span class="verb">Walk here</span>`,
      action: walkTo,
    });
  } else if (cls === 'entity' && items.length > 0) {
    items.push({
      label: `<span class="verb">Walk to</span>`,
      action: () => walkAdjacent(),
    });
  }

  // Always offer "Cancel" to dismiss
  items.push({ label: '<span class="verb" style="color:#888">Cancel</span>', action: () => {} });
  return items;
}

function openContextMenu(rightClick) {
  const items = buildContextOptions(rightClick.x, rightClick.y);
  if (items.length === 0) return;
  // title — first non-cancel item determines the topic
  const cls = classifyTile(rightClick.x, rightClick.y);
  let title = 'Tile (' + rightClick.x + ', ' + rightClick.y + ')';
  if (cls === 'entity') {
    if (world.cookSpawn && world.cookSpawn.x === rightClick.x && world.cookSpawn.y === rightClick.y) title = 'Cook';
    else if (world.firePos && world.firePos.x === rightClick.x && world.firePos.y === rightClick.y) title = 'Fire';
    else {
      const e = enemies.find(en => en.alive && en.x === rightClick.x && en.y === rightClick.y);
      if (e) title = e.kind === 'goblin' ? 'Bramble-imp' : 'Cow';
    }
  }
  ctxTitleEl.textContent = title;
  ctxItemsEl.innerHTML = '';
  for (const it of items) {
    const div = document.createElement('div');
    div.className = 'ctx-item';
    div.innerHTML = it.label;
    div.addEventListener('click', () => {
      hideContextMenu();
      it.action();
    });
    ctxItemsEl.appendChild(div);
  }
  // position — clamp to viewport so menu doesn't get cut off
  const sx = Math.min(rightClick.screenX || 0, window.innerWidth  - 180);
  const sy = Math.min(rightClick.screenY || 0, window.innerHeight - 200);
  ctxMenu.style.left = sx + 'px';
  ctxMenu.style.top  = sy + 'px';
  ctxMenu.style.display = 'block';
}

// ---------- LOOP ----------
const fpsEl = document.getElementById('fps');
let last = performance.now();
let frameCount = 0;
let fpsAccum = 0;

// ---------- WALL OCCLUSION FADE ----------
// Walls and cottage plaster tagged with userData.occlude fade out when
// they sit between the camera and the player. Cheap: per-mesh project
// onto the camera→player segment, fade if within FADE_R of the line
// segment. No raycasting.
const FADE_R = 0.85;        // tile-units of wall to consider "in front"
const FADE_MIN = 0.18;      // residual opacity so geometry still reads
const FADE_LERP = 14;       // higher = snappier reveal

const _occlPlayerVec = new THREE.Vector3();
const _occlSegVec    = new THREE.Vector3();
const _occlToMesh    = new THREE.Vector3();
const _occlClosest   = new THREE.Vector3();

function updateOccluders(dt) {
  _occlPlayerVec.set(player.pos.x, 1.0, player.pos.z);
  _occlSegVec.subVectors(_occlPlayerVec, camera.position);
  const segLen2 = _occlSegVec.lengthSq();
  if (segLen2 < 0.01) return;
  const lerp = 1 - Math.exp(-dt * FADE_LERP);

  scene.traverse(o => {
    if (!o.isMesh || !o.userData.occlude || !o.material) return;
    _occlToMesh.subVectors(o.getWorldPosition(_occlClosest), camera.position);
    const t = _occlToMesh.dot(_occlSegVec) / segLen2;
    let target = 1.0;
    if (t > 0.02 && t < 0.98) {
      _occlClosest.copy(_occlSegVec).multiplyScalar(t).add(camera.position);
      const d2 = _occlClosest.distanceToSquared(o.getWorldPosition(_occlToMesh));
      if (d2 < FADE_R * FADE_R) target = FADE_MIN;
    }
    const m = o.material;
    if (o.userData._occlOpacity == null) o.userData._occlOpacity = 1;
    o.userData._occlOpacity += (target - o.userData._occlOpacity) * lerp;
    if (o.userData._occlOpacity < 0.999) {
      m.transparent = true;
      m.depthWrite = false;
    } else {
      m.transparent = false;
      m.depthWrite = true;
    }
    m.opacity = o.userData._occlOpacity;
  });
}

function loop() {
  const now = performance.now();
  // Raw frame delta clamped to 50ms so background-tab catch-up doesn't
  // teleport everything. Hit-stop scales the dt to ~5% for ~60ms on
  // power impacts so the strike lands before time resumes.
  const rawDt = Math.min(0.05, (now - last) / 1000);
  // Global pace multiplier — 0.75 reads as "slowed down" without
  // crawling. Applied before hit-stop so impact freezes still register.
  const PACED_DT = rawDt * 0.75;
  const dt = sampleHitStop(PACED_DT);
  last = now;
  frameCount++;
  fpsAccum += dt;
  if (fpsAccum >= 0.5) {
    fpsEl.textContent = (frameCount / fpsAccum).toFixed(0) + ' fps';
    frameCount = 0; fpsAccum = 0;
  }

  // ---------- CLICK HANDLING ----------
  // Left = walk *and run the default action* (OSRS-style "click anything").
  // Right = open the verb menu for non-default actions.
  const leftClick = takeLeftClick(camera);
  if (leftClick) {
    player.combatTarget = null;          // any walk command disengages
    const start = { x: player.x, y: player.y };
    let goal  = { x: leftClick.x, y: leftClick.y };
    let cls   = classifyTile(goal.x, goal.y);
    // Click forgiveness — if the click landed on empty ground but a
    // hostile mob's body is within ~0.7 tile-units of the actual hit
    // point, snap to that mob's tile. Lets sloppy aim still engage the
    // intended target instead of triggering a "walk here" detour.
    if (cls !== 'entity' && leftClick.world) {
      const SNAP_R = 0.7;
      let best = null, bestD = SNAP_R * SNAP_R;
      for (const e of enemies) {
        if (!e.alive) continue;
        const dx = e.pos.x - leftClick.world.x;
        const dz = e.pos.z - leftClick.world.z;
        const d2 = dx*dx + dz*dz;
        if (d2 < bestD) { bestD = d2; best = e; }
      }
      if (best) {
        goal = { x: best.x, y: best.y };
        cls = classifyTile(goal.x, goal.y);
      }
    }
    if (cls === 'entity') {
      // Left-click runs the FIRST option of the right-click verb menu.
      // Single source of truth — whatever reads as "Attack X" / "Talk to
      // X" / "Chop X" at the top of the verb menu IS what left-click
      // does. Each first-option's action() handles its own walkAdjacent
      // + then-block, so we just call it. Keeps the two code paths from
      // drifting apart over time.
      const verbs = buildContextOptions(goal.x, goal.y);
      if (verbs.length > 0) {
        advanceTutorial('walk_started');
        verbs[0].action();
      } else {
        log('hint', "Nothing to do here.");
      }
    } else if (cls === 'walkable') {
      const path = findPath(start, goal, isBlocked);
      if (path !== null) {
        setPath(player, path);
        advanceTutorial('walk_started');
      } else log('hint', "Can't get there.");
    } else {
      log('hint', "Can't walk there.");
    }
  }
  const rightClick = takeRightClick(camera);
  if (rightClick) openContextMenu(rightClick);

  // ---------- KEYBOARD MOVEMENT (also cancels active path) ----------
  // WoW-style camera-relative movement: W = "into the screen" regardless
  // of which way the camera is yawed. We project the keyboard cardinal
  // through the camera yaw, then snap to the nearest grid cardinal
  // (N/S/E/W) so movement stays tile-discrete. Camera is unchanged — only
  // the input mapping rotates. Up/down dominates left/right when both are
  // pressed because forward motion reads as the player's intent.
  //
  // Bramble-root (Hedgemother phase-2 mechanic) gates movement here:
  // while rootedT > 0, keyboard + path-following are both suppressed.
  // Casting / abilities are unaffected (different code paths below).
  if (player.rootedT > 0) {
    // Skip the movement block entirely. Don't consume path either —
    // when the root expires, the queued path resumes from the same step.
  } else
  if (!player.moving) {
    // World-relative movement. W/↑ = north (-Z), S/↓ = south (+Z),
    // A/← = west (-X), D/→ = east (+X). Camera yaw is ignored — the
    // direction the player walks doesn't depend on which way the
    // camera is currently pointing. If both axes are held we prefer
    // vertical so diagonal input still snaps to one cardinal.
    let dx = 0, dy = 0;
    if (isPressed('arrowup', 'w'))         dy = -1;
    else if (isPressed('arrowdown', 's'))  dy =  1;
    else if (isPressed('arrowleft', 'a'))  dx = -1;
    else if (isPressed('arrowright', 'd')) dx =  1;
    if (dx || dy) {
      // keyboard interrupts active path
      if (player.path.length > 0) {
        player.path = [];
        player.onPathDone = null;
        player.clickMarker.visible = false;
      }
      startStep(player, dx, dy, isBlocked);
    } else {
      // no key held → consume next path step
      consumePathStep(player, isBlocked);
    }
  }

  // interact (E / Enter / Space). Space additionally queues a dodge —
  // the loop tries interact first; if there's nothing in range we silence
  // the "Nothing in front" hint and let the dodge handler below fire.
  // E and V never queue both, so they keep clean single-purpose feel.
  let _interactDidSomething = false;
  if (!player.moving && takeInteract()) {
    _interactSilent = true;
    _interactDidSomething = tryInteractInFront();
    _interactSilent = false;
  }

  // dodge (V / Space-fallback) — fast 1-tile dash with brief i-frames.
  // If interact already did something this frame, consume the dodge queue
  // silently so "Space near an NPC" doesn't talk + dodge in the same press.
  if (_interactDidSomething) takeDodge();
  if (takeDodge()) {
    const dodged = tryDodge(player, isBlocked);
    if (dodged) {
      import('./core/sfx.js').then(m => m.sfx.footstep());
      import('./core/camera.js').then(m => m.shakeCamera(0.04));
    } else if (player.dodgeCd > 0) {
      // Soft feedback when on cooldown — don't spam the log
    }
  }

  // Active abilities (1..4 hotkeys). Input buffering: a press during an
  // active cooldown stashes the slot for ~250ms instead of dropping it,
  // so the player can chord "swing → 1" and the ability fires the moment
  // the swing recovers — Diablo-style "feels responsive even though I'm
  // pressing during an animation". The buffer is cleared on a successful
  // fire OR on timeout. Only the most recent press survives (later
  // presses overwrite older ones — what you pressed *last* is what fires).
  const abilityKey = takeAbility();
  if (abilityKey !== null && abilityKey !== undefined) {
    const fired = tryUseAbility(abilityKey);
    if (!fired) {
      player._abilityBuffer = { slot: abilityKey, t: 0.25 };
    }
  }
  // Drain the buffer: tick its TTL, retry the fire each frame while live.
  if (player._abilityBuffer) {
    player._abilityBuffer.t -= dt;
    if (player._abilityBuffer.t <= 0) {
      player._abilityBuffer = null;
    } else if (tryUseAbility(player._abilityBuffer.slot)) {
      player._abilityBuffer = null;
    }
  }

  // Tab → cycle combat target to the nearest visible alive enemy in
  // range. If a target is already locked, picks the next-nearest.
  if (takeTargetSwap()) cycleCombatTarget();

  // Q → quick-quaff the smallest-heal food in inventory. Skips when at
  // full HP so the keystroke doesn't waste rations.
  if (takePotion()) tryQuaffPotion();
  if (takeSketch()) trySketch();
  tickSketchChannel(dt);
  if (takeCast()) tryCastActiveSpell();

  // J → open journal (active quest summary).
  if (takeJournal()) openJournal();

  // Derive run state: shift held, OR auto-run while chasing a combat target.
  player.running = player.runHeld || !!player.combatTarget;

  // Sprint dust kickup — small earthy puff behind the player while
  // running. Throttled to ~3/sec via _sprintDustT accumulator.
  if (player.running && player.moving) {
    player._sprintDustT = (player._sprintDustT || 0) + dt;
    if (player._sprintDustT >= 0.33) {
      player._sprintDustT = 0;
      const dustPos = new THREE.Vector3(player.pos.x, 0.10, player.pos.z);
      spawnHitSparks(dustPos, {
        count: 6, spread: 0.6, color: 0xc9b58c, size: 4, life: 0.4,
      });
    }
  } else {
    player._sprintDustT = 0;
  }

  updatePlayerMovement(player, dt);
  // ride the heightmap (including water-sinking near shore)
  // Dungeon floor is flat; the overworld terrain mesh has noise.
  player.mesh.position.y = dungeon.active
    ? player.pos.y
    : player.pos.y + world.surfaceHeightAt(player.pos.x, player.pos.z);

  // Wayfinding: track tile visits for fog-of-war + the world map, but
  // award NO XP. Wayfinding XP only comes from creating maps (chart
  // inscription) or completing maps (running a chart's dungeon).
  // Walking is the cost of doing the work, not the work itself.
  const tileKey = player.x + ',' + player.y;
  if (!player.exploredTiles.has(tileKey)) {
    player.exploredTiles.add(tileKey);
    queueExploredSave();
  }

  // Tree + forage respawn ticks
  world.tickRespawns();

  // Falcon companion: idle orbit / flight to target / strike / return
  updateFalcon(dt);

  // Procedural per-frame animation for the GLB knight (walk/idle/run/attack).
  if (player.mesh.userData?.isGLBKnight) {
    animateGLBKnight(player.mesh, player, dt);
  }

  // Auto-attack tick — once locked onto a target, keep swinging. If the
  // target wanders out of reach, pursue them. Disengage only on death,
  // unreachable, or an explicit walk-elsewhere command.
  if (player.combatTarget) {
    const t = player.combatTarget;
    if (!t.alive) {
      player.combatTarget = null;
    } else if (!player.moving && player.path.length === 0) {
      const d = Math.abs(player.x - t.x) + Math.abs(player.y - t.y);
      if (d === 1 && player.attackCd === 0) {
        // adjacent + ready — swing
        attackEnemy(player, t, log);
        triggerAttack(player);
        renderStats();
        advanceTutorial('enemy_attacked');
        if (!t.alive) advanceTutorial('enemy_killed');
      } else if (d > 1) {
        // target moved away — pursue
        const path = pathToAdjacent(
          { x: player.x, y: player.y },
          { x: t.x, y: t.y },
          isBlocked
        );
        if (path === null) {
          player.combatTarget = null;     // unreachable — disengage
          log('hint', 'Lost the target.');
        } else if (path.length > 0) {
          setPath(player, path);          // chase (running flag set per-frame below)
        }
      }
      // d === 1 with attackCd > 0 → wait for cooldown, no action this tick
    }
  }

  // Procedural limb animation on the player's mesh
  animateKnight(player.mesh, player.animState, {
    moving: player.moving,
    speed: player.moving ? 1 : 0,
    dir: player.dir,
  }, dt);

  // Idle breath — micro-scale modulation while standing. Pillar 5
  // (animation weight) — keeps the character looking alive between
  // actions instead of frozen for the 1.15s swing cooldown. Disabled
  // while moving (the walk anim already provides motion) and during
  // dodge i-frames (would conflict with the dodge dash). 0.012 amplitude
  // at 0.6 Hz reads as a quiet breath without bobbing the camera.
  if (!player.moving && (player.iframeT || 0) <= 0) {
    const breath = Math.sin(now * 0.001 * 0.6 * Math.PI * 2) * 0.012;
    player.mesh.scale.setScalar(1 + breath);
  } else {
    player.mesh.scale.setScalar(1);
  }

  // Demo lab — cycle walk amplitude over a 6-second loop so all 3 pads
  // demonstrate idle ↔ walk transitions visibly without player input.
  if (demoZone) {
    const cyclePhase = (now / 6000) % 1;
    // smoothstep up for first half, hold, smoothstep down — 0 → 1 → 0
    const walkU =
      cyclePhase < 0.4 ? smoothstep(0, 0.4, cyclePhase) :
      cyclePhase < 0.6 ? 1 :
                         1 - smoothstep(0.6, 1, cyclePhase);
    demoZone.update(dt, walkU);
  }
  // Mob aggro propagation: capture pre-update aggro flags, run updateEnemy,
  // then for any enemy that just flipped aggro=true, wake nearby same-kind
  // mobs (4-tile Manhattan). Bosses don't propagate (they're lone-wolf
  // by design).
  const _prevAggro = enemies.map(e => !!e.aggro);
  // Track alive→dead transitions for shimmer drops (post-pass).
  const _prevAlive = enemies.map(e => !!e.alive);
  for (const e of enemies) {
    updateEnemy(e, player, isBlocked, log, dt);
    if (e.alive) {
      // GLB cows have named child parts that we drive procedurally.
      const ud = e.mesh.userData;
      if (e.kind === 'cow' && ud?.isGLBCow) animateCow(e.mesh, e, dt);
      else if (ud?.parts && (ud.rig === 'biped' || ud.isGLBGoblin)) {
        animateGoblin(e.mesh, e, dt);
      }
      else if (ud?.parts && (ud.rig === 'quad' ||
        ud.isGLBBoar || ud.isGLBHedgewolf || ud.isGLBWolfAlpha ||
        ud.isGLBBurrowBoar || ud.isGLBHedgewight || ud.isGLBHare || ud.isGLBHedgemother
      )) animateQuadruped(e.mesh, e, dt);
      else if (e.mesh.userData?.parts && e.mesh.userData.isGLBChicken) {
        animateBird(e.mesh, e, dt);
      }
      // Per-instance idle bob — gentle Y drift so resting enemies feel
      // alive. Phase is offset by enemy spawn position so a herd doesn't
      // bob in lockstep. Suppressed during attack windups + hit-react so
      // it doesn't fight the existing animation pipeline.
      if (e._bobPhase === undefined) e._bobPhase = (e.x * 0.7 + e.y * 1.3) % 6.283;
      const settled = !e.moving && (e.attackAnimT || 0) <= 0 && (e.hitReactT || 0) <= 0;
      const idleAmp = settled ? 0.04 : 0;
      const bobY = idleAmp * Math.sin(now * 0.0035 + e._bobPhase);
      // Preserve any local Y (squash/hit-react offY set by updateEnemy)
      // when adding the idle bob and terrain height.
      const localY = e.mesh.position.y || 0;
      e.mesh.position.y = localY + bobY + world.surfaceHeightAt(e.pos.x, e.pos.z);
      // HP bar — position above head, billboard, smoothed fill + bleed badge.
      if (e.hpBar) {
        const ratio = Math.max(0, e.hp / e.hpMax);
        if (ratio >= 1) {
          e.hpBar.visible = false;
        } else {
          e.hpBar.visible = true;
          const headY = (e.kind === 'goblin') ? 1.55 : 1.35;
          e.hpBar.position.set(
            e.mesh.position.x,
            e.mesh.position.y + headY,
            e.mesh.position.z
          );
          // Smooth the fill scale toward the true ratio so chunk damage
          // drains the bar over ~250ms instead of snapping.
          if (typeof e._shownHPRatio !== 'number') e._shownHPRatio = ratio;
          const k = 1 - Math.exp(-dt * 8);
          e._shownHPRatio += (ratio - e._shownHPRatio) * k;
          if (Math.abs(ratio - e._shownHPRatio) < 0.005) e._shownHPRatio = ratio;
          e.hpBar.userData.fill.scale.x = e._shownHPRatio;
          e.hpBar.userData.fillMat.color.setHSL(e._shownHPRatio * 0.33, 0.7, 0.55);
          // Bleed status dot — fades in while a bleed effect is active.
          const dotMat = e.hpBar.userData.bleedDotMat;
          if (dotMat) {
            const targetOp = (e.bleed && e.bleed.ticksLeft > 0) ? 0.95 : 0;
            // pulse the dot subtly so it reads as active
            const pulse = (e.bleed && e.bleed.ticksLeft > 0)
              ? 0.6 + Math.abs(Math.sin(now * 0.006)) * 0.35
              : 0;
            dotMat.opacity = (targetOp > 0) ? pulse : Math.max(0, dotMat.opacity - dt * 4);
          }
          e.hpBar.lookAt(camera.position);
        }
      }
    } else if (e.hpBar) {
      e.hpBar.visible = false;
    }
  }

  // Aggro propagation pass — same-kind enemies within 4 tiles wake too.
  // Skip bosses so the boss intro stays a 1v1 beat.
  for (let i = 0; i < enemies.length; i++) {
    const e = enemies[i];
    if (!e.alive || e.isBoss) continue;
    if (_prevAggro[i] || !e.aggro) continue;
    // This enemy just went aggro this frame — pull nearby kin in.
    for (const other of enemies) {
      if (other === e || !other.alive || other.aggro || other.isBoss) continue;
      if (other.kind !== e.kind) continue;
      const d = Math.abs(other.x - e.x) + Math.abs(other.y - e.y);
      if (d <= 4) {
        other.aggro = true;
        const wp = new THREE.Vector3(other.mesh.position.x, other.mesh.position.y + 1.6, other.mesh.position.z);
        spawnFloat(wp, '!', 'level');
      }
    }
  }

  // Death-transition pass — start the death-fade animation + roll
  // shimmer drops. The death code paths still hide the mesh; we re-show
  // it for the fade window and animate scale + Y-sink each frame in
  // updateEnemyDeathFade(). Bosses guarantee both shimmers.
  for (let i = 0; i < enemies.length; i++) {
    const e = enemies[i];
    if (_prevAlive[i] && !e.alive) {
      // Start fade: re-show mesh (death path snapped it off) and store
      // the original scale so we can shrink-from-1 cleanly.
      e._deathFadeT = 0.6;
      e._deathFadeBaseY = e.mesh.position.y;
      e._deathFadeBaseScale = e.mesh.scale.x;   // assume uniform
      e._deathFadeBaseRotZ = e.mesh.rotation.z;
      e.mesh.visible = true;

      // Death sfx — short bassy wheeze. Distinct from sfx.death (player
      // death) so it doesn't dominate when multiple enemies fall together.
      // Skip for passive critters (cow/chicken) — their fall is comic, not
      // dramatic, and the descending tone is wrong for them.
      if (e.kind !== 'cow' && e.kind !== 'chicken') {
        sfx.enemyDeath();
      }

      // Dust puff — tan/brown sparks at ground level so the corpse feels
      // like it's settling into the earth. Same spawnHitSparks pattern as
      // dodge dust kick; lower position + warm earth color.
      const dustPos = new THREE.Vector3(e.pos.x, 0.10, e.pos.z);
      import('./scene/sparks.js').then(m => m.spawnHitSparks(dustPos, {
        count: 14, spread: 1.2, color: 0xc9a36a, size: 6, life: 0.55,
      }));

      const pos = { x: e.pos.x, y: 0, z: e.pos.z };
      if (e.isBoss) {
        spawnStaminaShimmer(scene, pos);
        spawnHPShimmer(scene, { ...pos, x: pos.x + 0.3 });
      } else {
        if (Math.random() < 0.25) spawnStaminaShimmer(scene, pos);
        if (Math.random() < 0.15) spawnHPShimmer(scene, { ...pos, x: pos.x + 0.2 });
      }

      // BURSTING affix — corpse pops with a small AoE. Player takes 2 dmg
      // if within 1.5 tiles. Visible spark burst so the player learns the
      // tell and can dodge away on subsequent kills.
      if (dungeon.active && dungeon.bursting) {
        const dx = player.pos.x - e.pos.x;
        const dz = player.pos.z - e.pos.z;
        const dist = Math.sqrt(dx*dx + dz*dz);
        // Always show the burst visually
        import('./scene/sparks.js').then(m => m.spawnHitSparks(
          new THREE.Vector3(e.pos.x, 0.4, e.pos.z),
          { count: 16, spread: 1.8, color: 0xff6a3a, size: 6, life: 0.4 }
        ));
        if (dist < 1.5) {
          const burstDmg = 2;
          if (!(window.__godMode && window.__godMode())) {
            player.hp = Math.max(0, player.hp - burstDmg);
          }
          spawnFloat(new THREE.Vector3(player.pos.x, player.pos.y + 1.3, player.pos.z),
            `Burst -${burstDmg}`, 'hit');
          log('combat', `💥 Bursting — corpse pop dealt ${burstDmg}.`);
          renderStats();
        }
      }
    }
    // Tick the fade — when it hits 0 we hand the mesh back to the
    // existing respawn path (which keeps mesh.visible = false).
    if (e._deathFadeT > 0 && !e.alive) {
      e._deathFadeT = Math.max(0, e._deathFadeT - dt);
      const u = e._deathFadeT / 0.6;       // 1 → 0
      const ease = u * u;                  // ease-out (bigger drop late)
      e.mesh.position.y = e._deathFadeBaseY - (1 - ease) * 0.4;
      const scl = e._deathFadeBaseScale * Math.max(0.05, ease);
      e.mesh.scale.set(scl, scl, scl);
      // Fall-over — rotate forward up to ~75° as the body settles. Pick
      // a random tilt direction (left or right) on first tick so a row
      // of dying enemies doesn't all fall the same way.
      if (e._deathFallSign === undefined) e._deathFallSign = Math.random() < 0.5 ? 1 : -1;
      const tiltMax = 1.3 * e._deathFallSign;   // ~75°, signed
      e.mesh.rotation.z = e._deathFadeBaseRotZ + (1 - ease) * tiltMax;
      if (e._deathFadeT === 0) {
        e.mesh.visible = false;
        e.mesh.scale.set(e._deathFadeBaseScale, e._deathFadeBaseScale, e._deathFadeBaseScale);
        e.mesh.position.y = e._deathFadeBaseY;
        e.mesh.rotation.z = e._deathFadeBaseRotZ;
        e._deathFallSign = undefined;
      }
    }
  }

  // animate fire flames + flicker the warm light
  if (fireMesh && fireMesh.userData.flames) {
    const t = now / 100;
    const f = fireMesh.userData.flames;
    f.scale.y = 0.85 + Math.sin(t) * 0.15;
    f.scale.x = 0.95 + Math.cos(t * 1.3) * 0.1;
    f.scale.z = 0.95 + Math.cos(t * 1.3) * 0.1;
    f.rotation.y += 0.02;
  }
  if (fireLight) {
    fireLight.intensity = 1.2 + Math.sin(now / 130) * 0.4 + Math.random() * 0.2;
  }
  // Memorial lantern — flickers gently once Maud's quest is done.
  if (memorialLantern) {
    const lit = !!player.quest?.flags?.maudFinished;
    memorialLantern.visible = lit;
    if (memorialLanternLight) {
      memorialLanternLight.intensity = lit
        ? 0.8 + Math.sin(now / 240) * 0.15 + Math.random() * 0.05
        : 0;
    }
  }
  if (fireSmoke) updateSmoke(fireSmoke, dt);
  clouds.update(dt);
  updateSparks(dt);
  updateTelegraphs(dt);
  updateImpacts(dt);
  updateLockOn(now);
  updatePathPreview(now);
  updateTileHover(now);
  updateShimmers(dt, player);
  updateAmbientDrift(dt, player);
  // Ambient atmosphere — cricket chirps fire on a long random interval
  // out of combat. Owls hoot occasionally inside dungeons (cool reverb
  // feel). Both stay quiet so they don't compete with combat audio.
  if (player) {
    player._ambSfxT = (player._ambSfxT || (8 + Math.random() * 7)) - dt;
    if (player._ambSfxT <= 0) {
      player._ambSfxT = 8 + Math.random() * 12;
      if (!player.combatTarget) {
        if (dungeon.active && Math.random() < 0.5) sfx.owl();
        else sfx.cricket();
      }
    }
  }
  // Ground loot: gravity arc → settle → walk-over pickup
  updateGroundLoot(dt, player, log, renderInv);
  // Autosave every 10 seconds. Cheap — just JSON.stringify the player.
  tickAutosave(dt, player, world, 10);
  // Death: triggered by combat.js setting player._justDied.
  if (player._justDied) handleDeath();

  // refresh combat target panel (cheap; DOM diffs only on change)
  renderCombat();

  // animate grass blade sway + water waves
  const t = now / 1000;
  if (world.bladeMat?.userData?.shader) world.bladeMat.userData.shader.uniforms.uTime.value = t;
  const waterMat = getWaterMaterial();
  if (waterMat.userData.shader) waterMat.userData.shader.uniforms.uTime.value = t;

  // Click marker — animated while flagged visible; smoothly fades over
  // ~0.3s when the flag clears (instead of snap-hide). Uses an alpha
  // gain stored on the marker's userData; the two rings already have
  // transparent: true.
  const cm = clickMarker;
  if (player.clickMarker.visible) {
    cm.visible = true;
    cm.userData.fadeOpacity = 1;
    const cmx = player.clickMarker.x + 0.5;
    const cmz = player.clickMarker.y + 0.5;
    cm.position.set(cmx, terrainHeightAt(cmx, cmz) + 0.03, cmz);
    const tt = now / 200;
    cm.children[0].scale.setScalar(1 + Math.sin(tt) * 0.06);
    cm.rotation.y += 0.04;
    cm.children[0].material.opacity = 0.85;
    if (cm.children[1]) cm.children[1].material.opacity = 0.6;
  } else if (cm.visible) {
    // Fade pass — reduce alpha across both rings, hide once invisible.
    cm.userData.fadeOpacity = Math.max(0, (cm.userData.fadeOpacity ?? 0) - dt * 3.5);
    const f = cm.userData.fadeOpacity;
    cm.children[0].material.opacity = 0.85 * f;
    if (cm.children[1]) cm.children[1].material.opacity = 0.6 * f;
    if (f === 0) cm.visible = false;
  }

  // bob cook (relative to terrain-anchored base)
  if (cookMesh) {
    cookMesh.position.y = cookBaseY + Math.sin(now / 600) * 0.06;
    if (cookMesh.userData.marker) {
      cookMesh.userData.marker.position.y = cookBaseY + 2.5 + Math.sin(now / 250) * 0.1;
      const showMarker = !player.quest.flags.finished &&
        (!player.quest.flags.cookTalked || player.inventory.count('brindle_roast') > 0);
      cookMesh.userData.marker.visible = showMarker;
    }
  }

  // passive HP regen out of combat
  if (player.hp < player.hpMax && player.attackCd === 0 && Math.random() < 0.003) {
    player.hp = Math.min(player.hpMax, player.hp + 1);
    renderStats();
  }

  updateCamera(camera, player.pos, dt);

  // Day/night cycle disabled per playtest — locking the world to noon
  // gives consistent visibility and one less gameplay axis to babysit.
  // The updateDayNight() function + _todPalette palette are still in this
  // file in case we want to bring it back as an option later.
  // updateDayNight(dt);
  updateZoneAmbient();

  sunTarget.position.set(player.pos.x, 0, player.pos.z);
  sun.position.set(
    player.pos.x + sunPosVec.x * 40,
    sunPosVec.y * 40,
    player.pos.z + sunPosVec.z * 40
  );

  // Drive Eldra's idle-walk so she paces in place even when the player
  // is far away — keeps the village feeling alive.
  if (_validationEldra) animateGLBKnight(_validationEldra.mesh, _validationEldra.fakeEntity, dt);

  updateOccluders(dt);
  composer.render();
  updateFloaters(camera, W, H);
  renderSkillBar(dt);
  drawMinimap();
  // Tutorial: surface the eat-prompt the moment the player first drops
  // below half HP. Cheap per-frame check; advanceTutorial gates so the
  // hint only fires once.
  if (player.hp < player.hpMax * 0.5) advanceTutorial('hp_low');

  requestAnimationFrame(loop);
}

window.addEventListener('resize', () => {
  const w = stage.clientWidth, h = stage.clientHeight;
  renderer.setSize(w, h, false);
  composer.setSize(w, h);
  camera.aspect = w / h;
  camera.updateProjectionMatrix();
});

// ---------- BOOT ----------
// Surface any unhandled error to the in-game log so a black screen at least
// tells you what broke.
window.addEventListener('error', e => {
  log('hint', 'JS error: ' + (e.message || e.error?.message || 'unknown'));
});
window.addEventListener('unhandledrejection', e => {
  log('hint', 'Promise: ' + (e.reason?.message || e.reason || 'unknown'));
});

log('hint', 'Welcome to Bramblewood.');
log('hint', 'Click = walk · Click+drag = rotate camera · Wheel = zoom.');
log('hint', 'Right-click for menu — works on any tile or entity.');
log('hint', 'Combat style affects which skill levels up. Pick from the panel.');
renderCombat();
renderStats();
renderInv();
renderEquipped();
renderSkillBar();
renderQuest();
// Force one resize pass after boot so the renderer + camera pick up the
// final stage dimensions (CSS layout sometimes settles after module load,
// and the wireframe redesign moved from 800×576 to 1280×800 max).
// Force one resize pass after boot so the renderer + camera pick up the
// final stage dimensions (CSS layout sometimes settles after module load,
// and the wireframe redesign moved from 800×576 to 1280×800 max).
requestAnimationFrame(() => {
  const w = stage.clientWidth, h = stage.clientHeight;
  if (w > 0 && h > 0) {
    renderer.setSize(w, h, false);
    if (typeof composer !== 'undefined' && composer?.setSize) composer.setSize(w, h);
    camera.aspect = w / h;
    camera.updateProjectionMatrix();
  }
  // Toonify everything authored procedurally (mushrooms, ore, lanterns,
  // grass blades, fire, water surface). GLBs already toonify on load.
  toonifyMaterials(scene);
});
requestAnimationFrame(loop);
