// "Animation lab" pads near spawn — three approaches side by side.
// Pad A: procedural on Object3D hierarchy (animateKnight)
// Pad B: AnimationMixer driven by programmatic AnimationClips
// Pad C: AnimationMixer driven by Mixamo-rigged glTF skeletal animation
import * as THREE from 'three';
import { buildPlayerMesh } from './characters.js';
import { terrainHeightAt } from './terrain.js';
import { animateKnight, triggerSwing } from '../anim/procedural.js';
import { setupKnightMixer } from '../anim/clips.js';
import { loadSoldier } from '../anim/skeletal.js';

const PEDESTAL_HEIGHT = 0.3;

function buildPedestal(label) {
  const g = new THREE.Group();
  const base = new THREE.Mesh(
    new THREE.CylinderGeometry(0.7, 0.8, PEDESTAL_HEIGHT, 8),
    new THREE.MeshStandardMaterial({ color: 0x88847e, roughness: 0.9 })
  );
  base.position.y = PEDESTAL_HEIGHT / 2;
  base.castShadow = true; base.receiveShadow = true;
  g.add(base);

  // floating gold label
  const labelCanvas = document.createElement('canvas');
  labelCanvas.width = 256; labelCanvas.height = 64;
  const ctx = labelCanvas.getContext('2d');
  ctx.fillStyle = 'rgba(0,0,0,0.0)';
  ctx.fillRect(0, 0, 256, 64);
  ctx.font = 'bold 28px monospace';
  ctx.textAlign = 'center';
  ctx.lineWidth = 6;
  ctx.strokeStyle = '#000';
  ctx.fillStyle = '#ffd84a';
  ctx.strokeText(label, 128, 42);
  ctx.fillText(label, 128, 42);
  const tex = new THREE.CanvasTexture(labelCanvas);
  tex.colorSpace = THREE.SRGBColorSpace;
  const sprite = new THREE.Sprite(new THREE.SpriteMaterial({ map: tex, transparent: true }));
  sprite.scale.set(2.0, 0.5, 1);
  sprite.position.set(0, 2.4, 0);
  g.add(sprite);

  return g;
}

/**
 * @param scene  THREE.Scene
 * @param origin world {x, y} tile coords for the LEFT pedestal
 * @returns      { update(dt) } — call each frame
 */
export async function spawnDemoPads(scene, origin) {
  const out = { entries: [], update: (dt, walkU) => {
    for (const e of out.entries) e.update(dt, walkU);
  } };

  // Pad A — procedural ----------------------------------------------------
  {
    const padPos = { x: origin.x + 0.5, y: 0, z: origin.y + 0.5 };
    padPos.y = terrainHeightAt(padPos.x, padPos.z);
    const pedestal = buildPedestal('A · Procedural');
    pedestal.position.set(padPos.x, padPos.y, padPos.z);
    scene.add(pedestal);

    const knight = buildPlayerMesh();
    knight.position.set(padPos.x, padPos.y + PEDESTAL_HEIGHT, padPos.z);
    scene.add(knight);

    const animState = {};
    let swingT = 0;
    out.entries.push({
      update: (dt, walkU) => {
        // demo: cycle moving on/off every 3.5s; swing every 5s
        swingT += dt;
        if (swingT > 5) { swingT = 0; triggerSwing(animState); }
        animateKnight(knight, animState, { moving: walkU > 0.05, speed: walkU }, dt);
      },
    });
  }

  // Pad B — programmatic AnimationClip + Mixer ----------------------------
  {
    const padPos = { x: origin.x + 2.5, y: 0, z: origin.y + 0.5 };
    padPos.y = terrainHeightAt(padPos.x, padPos.z);
    const pedestal = buildPedestal('B · Mixer + Clips');
    pedestal.position.set(padPos.x, padPos.y, padPos.z);
    scene.add(pedestal);

    const knight = buildPlayerMesh();
    knight.position.set(padPos.x, padPos.y + PEDESTAL_HEIGHT, padPos.z);
    scene.add(knight);

    const rig = setupKnightMixer(knight);
    let swingT = 0;
    out.entries.push({
      update: (dt, walkU) => {
        swingT += dt;
        if (swingT > 5) { swingT = 0; rig.triggerAttack(); }
        rig.setSpeed(walkU);
        rig.mixer.update(dt);
      },
    });
  }

  // Pad C — skeletal Mixamo ----------------------------------------------
  {
    const padPos = { x: origin.x + 4.5, y: 0, z: origin.y + 0.5 };
    padPos.y = terrainHeightAt(padPos.x, padPos.z);
    const pedestal = buildPedestal('C · Skeletal (glTF)');
    pedestal.position.set(padPos.x, padPos.y, padPos.z);
    scene.add(pedestal);

    try {
      const soldier = await loadSoldier();
      soldier.root.position.set(padPos.x, padPos.y + PEDESTAL_HEIGHT, padPos.z);
      scene.add(soldier.root);
      out.entries.push({
        update: (dt, walkU) => {
          soldier.setSpeed(walkU);
          soldier.mixer.update(dt);
        },
      });
    } catch (err) {
      console.warn('Soldier load failed:', err);
      // fallback: empty entry
      out.entries.push({ update: () => {} });
    }
  }

  return out;
}
