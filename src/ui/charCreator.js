// Character Creator — modal screen shown before the game starts.
//
// Exports `showCharCreator(): Promise<CharData>`.
// Shows a modal, runs a tiny three.js preview of the knight on the right,
// lets the player pick name + 4 swatches, returns the chosen appearance.
//
// Persistence is the caller's job: pass the result to createPlayer() and
// write to localStorage in main.js.

import * as THREE from 'three';
import { loadKnightBase, loadEquipment, buildKnightMesh } from '../scene/characters.js';

// ---- swatch palettes -----------------------------------------------------
// Hex values come from the project's locked palette (see ART_BIBLE.md).
// Keep these in sync with docs/UI_BIBLE.md if you formalize tokens.
const SWATCHES = {
  hair:  ['#3a2c20', '#c8a464', '#1a1410', '#7a3820'],
  skin:  ['#f1d3b0', '#e2b48a', '#b48868', '#7a5238'],
  tunic: ['#dfceaa', '#6f8aa3', '#7a9656', '#c7867a'],
  cape:  ['red', 'blue', 'green', 'gold', null],
};

const CAPE_DISPLAY_HEX = {
  red:   '#a73a2a',
  blue:  '#3e5a80',
  green: '#5b7a3a',
  gold:  '#b58637',
};

// Thematic on-ramps for the indecisive player. Each preset is a complete
// loadout — clicking applies it and updates the preview. See the
// `character-creator-design` skill: presets unblock first-time creators
// even in slider-heavy designs.
const PRESETS = {
  Knight:     { hair: '#3a2c20', skin: '#e2b48a', tunic: '#dfceaa', cape: 'red' },
  SunKnight:  { hair: '#c8a464', skin: '#f1d3b0', tunic: '#dfceaa', cape: 'gold' },
  Druid:      { hair: '#7a3820', skin: '#b48868', tunic: '#7a9656', cape: 'green' },
  NightDruid: { hair: '#1a1410', skin: '#7a5238', tunic: '#6f8aa3', cape: 'blue' },
  Archer:     { hair: '#1a1410', skin: '#7a5238', tunic: '#6f8aa3', cape: null },
  Bard:       { hair: '#c8a464', skin: '#f1d3b0', tunic: '#c7867a', cape: 'gold' },
};

// Display labels for the preset row (multi-word names need spaces).
const PRESET_LABELS = {
  Knight:     'Knight',
  SunKnight:  'Sun Knight',
  Druid:      'Druid',
  NightDruid: 'Night Druid',
  Archer:     'Archer',
  Bard:       'Bard',
};

const DEFAULT_PICK = {
  name: 'Adventurer',
  archetype: 'Knight',
  ...PRESETS.Knight,
};

/**
 * Show the modal and resolve with the picked CharData when the player
 * clicks "Begin Adventure" (first run) or "Confirm Look" (re-customization).
 *
 * @param {object} [opts]
 * @param {object} [opts.initial]  — current {name, hair, skin, tunic, cape};
 *   when provided, the creator opens pre-filled with these values, used by
 *   the in-game Mirror for re-customization.
 * @returns {Promise<{name: string, appearance: {hair: string, skin: string, tunic: string, cape: string|null}}>}
 */
export function showCharCreator(opts = {}) {
  return new Promise((resolve) => {
    const root = document.getElementById('char-creator');
    if (!root) throw new Error('char creator: #char-creator not in DOM');
    root.classList.add('cc-open');

    const pick = { ...DEFAULT_PICK, ...(opts.initial || {}) };
    // Reflect re-customize context in the CTA copy.
    const isRedo = !!opts.initial;
    const beginBtnEl = root.querySelector('#cc-begin');
    if (beginBtnEl) beginBtnEl.textContent = isRedo ? 'Confirm Look' : 'Begin Adventure';

    // ---- name input + preview overlay ----
    const nameInput = root.querySelector('#cc-name');
    const previewName = root.querySelector('#cc-preview-name');
    nameInput.value = pick.name;
    syncName();
    nameInput.addEventListener('input', () => {
      pick.name = nameInput.value.trim().slice(0, 12) || 'Adventurer';
      syncName();
    });
    function syncName() {
      previewName.textContent = pick.name;
    }

    // ---- preset row — thematic on-ramps; click applies a full loadout ----
    const presetsRow = root.querySelector('#cc-row-presets');
    presetsRow.innerHTML = '';
    for (const [presetName, values] of Object.entries(PRESETS)) {
      const btn = document.createElement('button');
      btn.className = 'cc-preset';
      btn.type = 'button';
      btn.dataset.preset = presetName;
      btn.textContent = PRESET_LABELS[presetName] || presetName;
      if (presetMatches(pick, values)) btn.classList.add('cc-preset-on');
      btn.addEventListener('click', () => {
        Object.assign(pick, values);
        pick.archetype = presetName;       // record archetype for v2 mesh swap
        refreshSwatchSelection();
        markActivePreset();
        previewApply(pick);
      });
      presetsRow.appendChild(btn);
    }

    // ---- swatch rows (built from SWATCHES) ----
    for (const slot of ['hair', 'skin', 'tunic', 'cape']) {
      const row = root.querySelector(`#cc-row-${slot}`);
      row.innerHTML = '';
      for (const value of SWATCHES[slot]) {
        const sw = document.createElement('button');
        sw.className = 'cc-sw';
        sw.dataset.value = value ?? '';
        if (slot === 'cape' && value === null) {
          sw.classList.add('cc-sw-none');
          sw.textContent = '✕';
          sw.title = 'No cape';
        } else {
          sw.style.background = slot === 'cape' ? CAPE_DISPLAY_HEX[value] : value;
        }
        if (value === pick[slot]) sw.classList.add('cc-sw-on');
        sw.addEventListener('click', () => {
          pick[slot] = value;
          row.querySelectorAll('.cc-sw').forEach(s => s.classList.remove('cc-sw-on'));
          sw.classList.add('cc-sw-on');
          markActivePreset();
          previewApply(pick);
        });
        row.appendChild(sw);
      }
    }

    // ---- random button: pick from each swatch list, never null cape ----
    const randomBtn = root.querySelector('#cc-random');
    randomBtn.addEventListener('click', () => {
      for (const slot of ['hair', 'skin', 'tunic', 'cape']) {
        const opts = SWATCHES[slot];
        // bias the cape toward "has cape" — null shows up only ~20% of the time
        if (slot === 'cape' && Math.random() > 0.20) {
          const colored = opts.filter(v => v !== null);
          pick[slot] = colored[Math.floor(Math.random() * colored.length)];
        } else {
          pick[slot] = opts[Math.floor(Math.random() * opts.length)];
        }
      }
      refreshSwatchSelection();
      markActivePreset();
      previewApply(pick);
    });

    // ---- 3D preview ----
    const previewCanvas = root.querySelector('#cc-preview');
    const preview = startPreview(previewCanvas, pick);

    // ---- begin button ----
    const beginBtn = root.querySelector('#cc-begin');
    const skipTutorialBox = root.querySelector('#cc-skip-tutorial');
    beginBtn.addEventListener('click', () => {
      preview.stop();
      root.classList.remove('cc-open');
      resolve({
        name: pick.name,
        archetype: pick.archetype || 'Knight',
        appearance: {
          hair:  pick.hair,
          skin:  pick.skin,
          tunic: pick.tunic,
          cape:  pick.cape,
        },
        skipTutorial: !!skipTutorialBox?.checked,
      });
    }, { once: true });

    // ---- helpers shared by presets / swatches / random ----
    function previewApply(p) { preview.apply(p); }
    function refreshSwatchSelection() {
      for (const slot of ['hair', 'skin', 'tunic', 'cape']) {
        const row = root.querySelector(`#cc-row-${slot}`);
        row.querySelectorAll('.cc-sw').forEach(s => {
          const raw = s.dataset.value;
          const sval = raw === '' ? null : raw;
          s.classList.toggle('cc-sw-on', sval === pick[slot]);
        });
      }
    }
    function markActivePreset() {
      for (const btn of presetsRow.querySelectorAll('.cc-preset')) {
        btn.classList.toggle('cc-preset-on', presetMatches(pick, PRESETS[btn.dataset.preset]));
      }
    }
    previewApply(pick);
  });
}

function presetMatches(pick, preset) {
  return preset.hair === pick.hair
      && preset.skin === pick.skin
      && preset.tunic === pick.tunic
      && preset.cape === pick.cape;
}

// --------------------------------------------------------------------------
// 3D preview — shares no state with the main game; cleans up on stop().
// --------------------------------------------------------------------------
function startPreview(canvas, initialPick) {
  const W = canvas.clientWidth, H = canvas.clientHeight;
  const renderer = new THREE.WebGLRenderer({ canvas, antialias: true, alpha: true });
  renderer.setPixelRatio(Math.min(devicePixelRatio, 2));
  renderer.setSize(W, H, false);
  renderer.outputColorSpace = THREE.SRGBColorSpace;

  const scene = new THREE.Scene();
  scene.background = null;

  const camera = new THREE.PerspectiveCamera(35, W / H, 0.1, 50);
  camera.position.set(0, 1.4, 3.4);
  camera.lookAt(0, 1.0, 0);

  scene.add(new THREE.HemisphereLight('#cfe8ff', '#3a2c20', 0.55));
  const sun = new THREE.DirectionalLight('#fff5e0', 1.6);
  sun.position.set(2, 4, 2);
  scene.add(sun);

  // floor disc — soft circle of paper-color so the character has a base
  const floor = new THREE.Mesh(
    new THREE.CircleGeometry(1.2, 32),
    new THREE.MeshBasicMaterial({ color: '#ecdcb8', transparent: true, opacity: 0.4 })
  );
  floor.rotation.x = -Math.PI / 2;
  scene.add(floor);

  let knightGroup = null;
  let mounted = true;

  // Preload all the GLBs used by the loadout, then build the mesh.
  const equipmentSet = ['cape_red', 'cape_blue', 'cape_green', 'cape_gold',
                        'helmet_centurion', 'breastplate_olive', 'pauldrons_gold',
                        'belt_leather', 'tunic_skirt_cream', 'boots_brown'];
  Promise.all([
    loadKnightBase(),
    ...equipmentSet.map(n => loadEquipment(n).catch(() => null)),
  ]).then(() => {
    if (!mounted) return;
    rebuildMesh(initialPick);
  });

  function rebuildMesh(p) {
    if (knightGroup) {
      scene.remove(knightGroup);
      knightGroup.traverse(o => {
        if (o.isMesh && o.material && o !== knightGroup) {
          // do not dispose shared GLB materials/geometries — just drop the group
        }
      });
    }
    const loadout = ['breastplate_olive', 'pauldrons_gold', 'belt_leather',
                     'tunic_skirt_cream', 'boots_brown'];
    if (p.cape) loadout.unshift(`cape_${p.cape}`);
    knightGroup = buildKnightMesh(loadout);
    if (!knightGroup) return;
    knightGroup.position.set(0, 0, 0);
    scene.add(knightGroup);
    applyAppearance(knightGroup, p);
  }

  function apply(p) {
    if (!knightGroup) return;
    // Cape requires a mesh swap → rebuild. Color tints can mutate in place.
    rebuildMesh(p);
  }

  // ---- render loop ----
  let raf = 0;
  let t0 = performance.now();
  function tick() {
    if (!mounted) return;
    const t = (performance.now() - t0) / 1000;
    if (knightGroup) knightGroup.rotation.y = Math.sin(t * 0.4) * 0.6;
    renderer.render(scene, camera);
    raf = requestAnimationFrame(tick);
  }
  tick();

  function stop() {
    mounted = false;
    cancelAnimationFrame(raf);
    renderer.dispose();
  }

  return { apply, stop };
}

/** Mutate material colors on a freshly-built knight group to match the pick. */
function applyAppearance(group, pick) {
  group.traverse(o => {
    if (!o.isMesh || !o.material) return;
    const mat = Array.isArray(o.material) ? o.material[0] : o.material;
    const name = (o.name || '').toLowerCase();
    const matName = (mat.name || '').toLowerCase();

    // Skin: Body + arms + legs + bare head
    if (/body|arm|leg|head/.test(name) && !/helmet|hair/.test(name)) {
      // Only tint if material name suggests skin or we're on a base mesh.
      if (/skin|body|arm|leg/.test(matName) || matName === '') {
        mat.color?.set(pick.skin);
      }
    }
    // Hair: meshes named "hair" or material named "hair"
    if (/hair/.test(name) || /hair/.test(matName)) {
      mat.color?.set(pick.hair);
    }
    // Tunic: the cream tunic equipment piece
    if (/tunic/.test(name) || /tunic/.test(matName)) {
      mat.color?.set(pick.tunic);
    }
  });
}
