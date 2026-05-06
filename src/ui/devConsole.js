// Dev console — toggled with backtick (`). One floating panel for fast
// gameplay iteration: skill grants, HP refill, spawn helpers, teleport,
// gear bundles. Wire by calling `installDevConsole(api)` from main.js after
// the player + world are alive.
//
// API expected:
//   { player, world, scene, log, awardXp, ITEMS, enemies, spawnFns }
// where spawnFns is { goblin, cow, boar, hedgewolf, wolfAlpha, hedgemother,
//   chicken, hare, brambleCap, burrowBoar }.

const CSS = `
#dev-console {
  position: fixed;
  top: 12px; right: 12px;
  width: 280px;
  background: rgba(20, 18, 14, 0.92);
  color: #f0e8d8;
  border: 1px solid #6a5a3a;
  border-radius: 6px;
  padding: 10px 12px;
  font: 12px/1.4 ui-monospace, 'SF Mono', Menlo, monospace;
  z-index: 9999;
  display: none;
  box-shadow: 0 4px 16px rgba(0,0,0,0.5);
  user-select: none;
}
#dev-console.open { display: block; }
#dev-console h3 {
  margin: 0 0 6px; font-size: 12px; color: #c4a868;
  text-transform: uppercase; letter-spacing: 1px;
  border-bottom: 1px solid #4a3e28; padding-bottom: 4px;
}
#dev-console .row { display: flex; flex-wrap: wrap; gap: 4px; margin-bottom: 8px; }
#dev-console button {
  flex: 1 1 auto;
  background: #2e2820;
  color: #f0e8d8;
  border: 1px solid #4a3e28;
  border-radius: 3px;
  padding: 4px 8px;
  font: inherit;
  cursor: pointer;
  min-width: fit-content;
}
#dev-console button:hover { background: #4a3e28; border-color: #c4a868; }
#dev-console button:active { background: #c4a868; color: #2e2820; }
#dev-console select {
  background: #2e2820; color: #f0e8d8;
  border: 1px solid #4a3e28; border-radius: 3px;
  padding: 3px 6px; font: inherit;
  flex: 1 1 auto;
}
#dev-console .hint { color: #8a7e62; font-size: 11px; margin-top: 4px; }
#dev-console .key { color: #c4a868; font-weight: bold; }
`;

const SKILLS = [
  ['atk', 'Attack'], ['str', 'Strength'], ['def', 'Defense'], ['hp', 'HP'],
  ['cook', 'Cook'], ['wc', 'Woodcut'], ['fish', 'Fish'], ['mine', 'Mine'],
  ['smith', 'Smith'], ['forage', 'Forage'], ['carto', 'Carto'],
  ['falconry', 'Falconry'], ['magic', 'Magic'],
];

// Curated gear bundles — quick gear-up for combat tuning.
// Tier names match Bramblewood's themed materials, not OSRS bronze/iron/steel.
const GEAR_BUNDLES = {
  brindle:     ['brindle_sword', 'leather_body', 'wooden_shield'],
  bogiron:     ['bogiron_sword', 'bogiron_cuirass', 'bogiron_shield'],
  cinderbloom: ['cinderbloom_sword', 'cinderbloom_plate', 'cinderbloom_shield', 'cinderbloom_helm'],
};

const ENEMY_KINDS = [
  ['targetDummy', 'Training Dummy (immortal)'],
  ['goblin', 'Goblin'],
  ['archer', 'Bramble Archer'],
  ['charger', 'Bramble Charger'],
  ['cow', 'Cow'],
  ['chicken', 'Chicken'],
  ['hare', 'Hare'],
  ['boar', 'Boar'],
  ['hedgewolf', 'Hedgewolf'],
  ['brambleCap', 'Bramble Cap'],
  ['burrowBoar', 'Burrow Boar'],
  ['wolfAlpha', 'Wolf Alpha'],
  ['hedgemother', 'Hedgemother'],
];

export function installDevConsole(api) {
  const { player, world, scene, log, awardXp, ITEMS, enemies, spawnFns } = api;

  const style = document.createElement('style');
  style.textContent = CSS;
  document.head.appendChild(style);

  const root = document.createElement('div');
  root.id = 'dev-console';
  root.innerHTML = `
    <h3>Dev Console</h3>

    <div class="row">
      <select id="dev-skill"></select>
      <button data-cmd="xp-skill">+1k XP</button>
      <button data-cmd="lv-skill">+5 LV</button>
    </div>
    <div class="row">
      <button data-cmd="all-99">All skills 99</button>
      <button data-cmd="reset-skills">Reset skills</button>
    </div>

    <h3>Combat</h3>
    <div class="row">
      <button data-cmd="heal">Full HP</button>
      <button data-cmd="god">God mode</button>
      <button data-cmd="kill-all">Kill all enemies</button>
    </div>
    <div class="row">
      <select id="dev-enemy"></select>
      <button data-cmd="spawn-1">Spawn 1</button>
      <button data-cmd="spawn-5">Spawn 5</button>
    </div>

    <h3>Gear</h3>
    <div class="row">
      <button data-cmd="gear-brindle">Brindle set</button>
      <button data-cmd="gear-bogiron">Bogiron set</button>
      <button data-cmd="gear-cinderbloom">Cinder set</button>
    </div>
    <div class="row">
      <button data-cmd="cooked-stack">+50 tusker</button>
      <button data-cmd="logs-stack">+50 logs</button>
    </div>

    <h3>Teleport</h3>
    <div class="row">
      <button data-cmd="tp-spawn">Home</button>
      <button data-cmd="tp-cook">Cook</button>
    </div>

    <h3>Dungeon (instant)</h3>
    <div class="row">
      <select id="dev-scope">
        <option value="">(no scope)</option>
        <option value="briar_maze">Briar Maze</option>
        <option value="sunken_hut">Sunken Hut</option>
        <option value="delve">Delve</option>
        <option value="hollow">Hollow</option>
      </select>
    </div>
    <div class="row">
      <button data-cmd="dungeon-t1">Tier 1</button>
      <button data-cmd="dungeon-t3">Tier 3</button>
      <button data-cmd="dungeon-t5">Tier 5</button>
    </div>
    <div class="row">
      <button data-cmd="dungeon-hedgemother">+Hedgemother</button>
      <button data-cmd="dungeon-wolf">+Wolf Alpha</button>
    </div>

    <h3>Action Bar</h3>
    <div class="row">
      <select id="dev-bar-slot">
        <option value="1">Slot 1</option><option value="2">Slot 2</option>
        <option value="3">Slot 3</option><option value="4">Slot 4</option>
        <option value="5">Slot 5</option><option value="6">Slot 6</option>
        <option value="7">Slot 7</option><option value="8">Slot 8</option>
      </select>
      <select id="dev-bar-ability">
        <option value="">(empty)</option>
        <option value="cleave">Cleave (5 atk)</option>
        <option value="leap">Leap (12 atk)</option>
        <option value="rend">Rend (18 atk)</option>
        <option value="whirlwind">Whirlwind (25 atk)</option>
        <option value="backstab">Backstab (20 atk)</option>
        <option value="aimed_shot">Aimed Shot (16 atk)</option>
        <option value="shield_bash">Shield Bash (8 def)</option>
        <option value="defensive_stance">Defensive Stance (14 def)</option>
        <option value="riposte">Riposte (22 def)</option>
        <option value="bull_rush">Bull Rush (10 str)</option>
        <option value="sunder">Sunder (15 str)</option>
        <option value="last_stand">Last Stand (25 hp)</option>
      </select>
      <button data-cmd="bar-bind">Bind</button>
    </div>
    <div class="row">
      <button data-cmd="bar-fill">Fill all 8 (auto)</button>
    </div>

    <div class="hint">Press <span class="key">\`</span> to toggle</div>
  `;
  document.body.appendChild(root);

  const skillSel = root.querySelector('#dev-skill');
  for (const [key, label] of SKILLS) {
    const opt = document.createElement('option');
    opt.value = key; opt.textContent = label;
    skillSel.appendChild(opt);
  }
  const enemySel = root.querySelector('#dev-enemy');
  for (const [key, label] of ENEMY_KINDS) {
    const opt = document.createElement('option');
    opt.value = key; opt.textContent = label;
    enemySel.appendChild(opt);
  }

  // Toggle on backtick
  window.addEventListener('keydown', (ev) => {
    if (ev.target.tagName === 'INPUT' || ev.target.tagName === 'TEXTAREA') return;
    if (ev.key === '`' || ev.key === '~') {
      ev.preventDefault();
      root.classList.toggle('open');
    }
  });

  // God mode patch — wraps player.hp setter? Easier: store a flag, intercept
  // in the main loop via window.__game.godMode. Player damage code reads it.
  let godMode = false;
  window.__godMode = () => godMode;

  function spawnEnemy(kind, count = 1) {
    const fn = spawnFns[kind];
    if (!fn) { log('hint', `[dev] no spawn fn for ${kind}`); return; }
    for (let i = 0; i < count; i++) {
      const dx = Math.round((Math.random() - 0.5) * 6);
      const dy = Math.round((Math.random() - 0.5) * 6);
      const ex = Math.max(1, player.x + dx);
      const ey = Math.max(1, player.y + dy);
      try {
        const e = fn(ex, ey, scene);
        enemies.push(e);
      } catch (err) {
        log('hint', `[dev] spawn ${kind} failed: ${err.message}`);
        return;
      }
    }
    log('hint', `[dev] spawned ${count}× ${kind}`);
  }

  function giveBundle(items) {
    for (const id of items) {
      if (!ITEMS[id]) { log('hint', `[dev] missing item ${id}`); continue; }
      player.inventory.add(id, 1);
    }
    log('hint', `[dev] gear bundle granted`);
  }

  root.addEventListener('click', (ev) => {
    const btn = ev.target.closest('button[data-cmd]');
    if (!btn) return;
    const cmd = btn.dataset.cmd;
    switch (cmd) {
      case 'xp-skill':
        awardXp(player, skillSel.value, 1000, log, { source: 'dev' });
        break;
      case 'lv-skill': {
        const sk = player.skills[skillSel.value];
        sk.lv = Math.min(99, sk.lv + 5);
        sk.xp = 0;
        if (skillSel.value === 'hp') {
          player.hpMax = sk.lv * 2;
          player.hp = player.hpMax;
        }
        log('skill', `[dev] ${skillSel.value.toUpperCase()} → Lv ${sk.lv}`);
        break;
      }
      case 'all-99':
        for (const [k] of SKILLS) {
          player.skills[k].lv = 99;
          player.skills[k].xp = 0;
        }
        player.hpMax = 198;
        player.hp = player.hpMax;
        log('hint', '[dev] all skills 99');
        break;
      case 'reset-skills':
        for (const [k] of SKILLS) {
          player.skills[k].lv = 1;
          player.skills[k].xp = 0;
        }
        player.skills.hp.lv = 10;
        player.hpMax = 20;
        player.hp = 20;
        log('hint', '[dev] skills reset');
        break;
      case 'heal':
        player.hp = player.hpMax;
        log('hint', '[dev] healed');
        break;
      case 'god':
        godMode = !godMode;
        btn.textContent = godMode ? 'God: ON' : 'God mode';
        log('hint', `[dev] god mode ${godMode ? 'ON' : 'OFF'}`);
        break;
      case 'kill-all':
        for (const e of enemies) if (e.alive) e.hp = 0;
        log('hint', '[dev] all enemies killed');
        break;
      case 'spawn-1': spawnEnemy(enemySel.value, 1); break;
      case 'spawn-5': spawnEnemy(enemySel.value, 5); break;
      case 'gear-brindle':     giveBundle(GEAR_BUNDLES.brindle); break;
      case 'gear-bogiron':     giveBundle(GEAR_BUNDLES.bogiron); break;
      case 'gear-cinderbloom': giveBundle(GEAR_BUNDLES.cinderbloom); break;
      case 'cooked-stack':
        player.inventory.add('tusker_crackling', 50);
        log('hint', '[dev] +50 tusker crackling');
        break;
      case 'logs-stack':
        player.inventory.add('logs', 50);
        log('hint', '[dev] +50 logs');
        break;
      case 'tp-spawn':
        if (world.spawn) { player.x = world.spawn.x; player.y = world.spawn.y; }
        log('hint', '[dev] teleported home');
        break;
      case 'tp-cook':
        if (world.cookSpawn) { player.x = world.cookSpawn.x; player.y = world.cookSpawn.y; }
        log('hint', '[dev] teleported to cook');
        break;
      case 'dungeon-t1':
      case 'dungeon-t3':
      case 'dungeon-t5': {
        const tier = +cmd.split('-t')[1];
        const fn = window.__game?.enterDungeon;
        if (!fn) { log('hint', '[dev] enterDungeon not exposed yet'); break; }
        const scope = root.querySelector('#dev-scope').value || undefined;
        fn(tier, [], null, scope);
        log('hint', `[dev] entered Tier ${tier}${scope ? ` ${scope}` : ''} dungeon`);
        break;
      }
      case 'bar-bind': {
        const slot = +root.querySelector('#dev-bar-slot').value;
        const id = root.querySelector('#dev-bar-ability').value || null;
        if (!player.actionBar) player.actionBar = [null, null, null, null, null, null, null, null];
        player.actionBar[slot - 1] = id;
        try { localStorage.setItem('gj26.actionBar', JSON.stringify(player.actionBar)); } catch (_) {}
        log('hint', `[dev] slot ${slot} → ${id || '(empty)'}`);
        break;
      }
      case 'bar-fill': {
        const ALL = ['cleave', 'shield_bash', 'sunder', 'last_stand', 'leap', 'defensive_stance', 'rend', 'backstab'];
        player.actionBar = ALL.slice();
        try { localStorage.setItem('gj26.actionBar', JSON.stringify(player.actionBar)); } catch (_) {}
        log('hint', '[dev] action bar filled with mixed-tree set');
        break;
      }
      case 'dungeon-hedgemother':
      case 'dungeon-wolf': {
        const fn = window.__game?.enterDungeon;
        if (!fn) { log('hint', '[dev] enterDungeon not exposed yet'); break; }
        const id = cmd === 'dungeon-hedgemother' ? 'hedgemother_den' : 'wolf_alpha_den';
        const scope = root.querySelector('#dev-scope').value || undefined;
        // Synthesize a successful affix roll so the boss room is flagged
        fn(3, [{ id, good: true, resolvedId: id }], null, scope);
        log('hint', `[dev] entered T3${scope ? ` ${scope}` : ''} dungeon w/ ${id} boss`);
        break;
      }
    }
  });

  log('hint', '[dev] console ready — press ` to toggle');
}
