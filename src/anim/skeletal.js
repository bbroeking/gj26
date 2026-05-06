// Approach C — skeletal animation via glTF + AnimationMixer.
// Loads three.js's sample Soldier.glb (Mixamo-rigged) which ships with three
// embedded animations: "Idle", "Walk", "Run". This is the path you'd use for
// any Mixamo / Ready Player Me / Quaternius character.
import * as THREE from 'three';
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';

const SOLDIER_URL = 'https://threejs.org/examples/models/gltf/Soldier.glb';

const loader = new GLTFLoader();

/**
 * Load the Soldier model and return { root, mixer, actions, setSpeed,
 * triggerAttack(noop) }. `root` is a THREE.Group ready to add to the scene.
 *
 * Caller should invoke `mixer.update(dt)` each frame.
 */
export async function loadSoldier() {
  const gltf = await loader.loadAsync(SOLDIER_URL);
  const root = gltf.scene;
  root.scale.setScalar(0.36);  // bring to roughly knight-height
  root.traverse(o => {
    if (o.isMesh) { o.castShadow = true; o.receiveShadow = true; }
  });
  const mixer = new THREE.AnimationMixer(root);
  const clipsByName = Object.fromEntries(gltf.animations.map(c => [c.name, c]));
  const idle = mixer.clipAction(clipsByName['Idle']);
  const walk = mixer.clipAction(clipsByName['Walk']);
  const run  = mixer.clipAction(clipsByName['Run']);
  idle.play(); walk.play(); run.play();
  walk.setEffectiveWeight(0);
  run.setEffectiveWeight(0);

  let curSpeed = 0;
  const setSpeed = (target) => {
    curSpeed = THREE.MathUtils.lerp(curSpeed, target, 0.2);
    // 0..0.5 idle->walk, 0.5..1 walk->run
    if (curSpeed < 0.5) {
      const u = curSpeed * 2;
      idle.setEffectiveWeight(1 - u);
      walk.setEffectiveWeight(u);
      run.setEffectiveWeight(0);
    } else {
      const u = (curSpeed - 0.5) * 2;
      idle.setEffectiveWeight(0);
      walk.setEffectiveWeight(1 - u);
      run.setEffectiveWeight(u);
    }
  };

  return {
    root, mixer,
    actions: { idle, walk, run },
    setSpeed,
    // Soldier glb has no attack clip; this is a no-op so the demo loop's
    // call sites don't need to know which character is which.
    triggerAttack: () => {},
  };
}
