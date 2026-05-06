// Procedural SFX via Web Audio. No source files — every sound is
// synthesized with simple oscillators + envelopes so the game stays
// dependency-free. Inspired by the existing playLevelUpJingle in main.js.
//
// Public API:
//   sfx.hit()        — combat strike
//   sfx.pickup()     — ground-loot collected
//   sfx.chest()      — reward chest opened
//   sfx.footstep()   — soft tap (called sparingly by the move loop)
//   sfx.craft()      — smithing/cooking success
//   sfx.death()      — descending tone
//
// All gates through a single user-gesture-initialised AudioContext, so
// browsers don't block playback. Initialised lazily on first sfx call.

let _ctx = null;
let _master = null;

// Persisted master volume — read once at module load, then any later
// setMasterVolume call also writes-through to localStorage so the slider
// state survives across sessions.
const _LS_KEY = 'gj26.sfx.master';
function _readSavedVolume() {
  try {
    const raw = localStorage.getItem(_LS_KEY);
    if (raw == null) return 0.35;
    const v = parseFloat(raw);
    return Number.isFinite(v) ? Math.max(0, Math.min(1, v)) : 0.35;
  } catch (_) { return 0.35; }
}
let _masterVol = _readSavedVolume();

function ensureCtx() {
  if (_ctx) return _ctx;
  try {
    _ctx = new (window.AudioContext || window.webkitAudioContext)();
    _master = _ctx.createGain();
    _master.gain.value = _masterVol;
    _master.connect(_ctx.destination);
  } catch (_) {
    _ctx = null;
  }
  return _ctx;
}

/** Set the master output gain (0..1). Persists across sessions. */
export function setMasterVolume(v) {
  _masterVol = Math.max(0, Math.min(1, v));
  try { localStorage.setItem(_LS_KEY, String(_masterVol)); } catch (_) {}
  if (_master) _master.gain.value = _masterVol;
}

/** Read the current master volume (0..1). */
export function getMasterVolume() { return _masterVol; }

function tone(freq, dur, type = 'sine', vol = 0.3, attack = 0.005, decay = 0.05) {
  const ctx = ensureCtx();
  if (!ctx) return;
  const now = ctx.currentTime;
  const osc = ctx.createOscillator();
  const gain = ctx.createGain();
  osc.type = type;
  osc.frequency.value = freq;
  gain.gain.setValueAtTime(0, now);
  gain.gain.linearRampToValueAtTime(vol, now + attack);
  gain.gain.exponentialRampToValueAtTime(0.0001, now + dur);
  osc.connect(gain).connect(_master);
  osc.start(now);
  osc.stop(now + dur);
}

function noiseBurst(dur, vol = 0.15, lpf = 1200) {
  const ctx = ensureCtx();
  if (!ctx) return;
  const buf = ctx.createBuffer(1, ctx.sampleRate * dur, ctx.sampleRate);
  const data = buf.getChannelData(0);
  for (let i = 0; i < data.length; i++) data[i] = (Math.random() * 2 - 1) * vol;
  const src = ctx.createBufferSource();
  src.buffer = buf;
  const filter = ctx.createBiquadFilter();
  filter.type = 'lowpass';
  filter.frequency.value = lpf;
  src.connect(filter).connect(_master);
  src.start();
}

// ---- ambient drone --------------------------------------------------------
// A single soft, low-frequency hum used inside dungeons. Two detuned
// oscillators through a low-pass + slow LFO on the cutoff give it
// movement without tonality. Fades in/out via gain ramp so toggling
// doesn't click.
let _amb = null;   // { osc1, osc2, lfo, lfoGain, filter, gain, kind }

// Per-kind drone params. Tweak voicings here to differentiate zones —
// dungeon = low and tight, village = warm chord, wilds = open + slower
// breath, forge = brighter with a perfect fifth. brightBase/brightPeak set
// the day/night-driven filter sweep range for each kind.
const _AMB_PRESETS = {
  dungeon: { lpf: 320, osc1: 55,  osc2: 82,  lfoRate: 0.12, lfoDepth: 80,  brightBase: 220, brightPeak: 480 },
  village: { lpf: 580, osc1: 110, osc2: 165, lfoRate: 0.12, lfoDepth: 80,  brightBase: 380, brightPeak: 820 },
  wilds:   { lpf: 720, osc1: 73,  osc2: 110, lfoRate: 0.07, lfoDepth: 140, brightBase: 320, brightPeak: 940 },
  forge:   { lpf: 820, osc1: 130, osc2: 195, lfoRate: 0.15, lfoDepth: 60,  brightBase: 460, brightPeak: 980 },
};
function buildAmbient(kind = 'dungeon') {
  const ctx = ensureCtx();
  if (!ctx) return null;
  const p = _AMB_PRESETS[kind] || _AMB_PRESETS.village;
  const filter = ctx.createBiquadFilter();
  filter.type = 'lowpass';
  filter.frequency.value = p.lpf;
  filter.Q.value = 0.6;

  const gain = ctx.createGain();
  gain.gain.value = 0;
  filter.connect(gain).connect(_master);

  const osc1 = ctx.createOscillator();
  const osc2 = ctx.createOscillator();
  osc1.type = 'sawtooth';
  osc2.type = 'triangle';
  osc1.frequency.value = p.osc1;
  osc2.frequency.value = p.osc2;
  osc1.connect(filter); osc2.connect(filter);

  // slow LFO modulates filter cutoff for a breath
  const lfo = ctx.createOscillator();
  const lfoGain = ctx.createGain();
  lfo.frequency.value = p.lfoRate;
  lfoGain.gain.value = p.lfoDepth;
  lfo.connect(lfoGain).connect(filter.frequency);

  osc1.start(); osc2.start(); lfo.start();
  return { osc1, osc2, lfo, lfoGain, filter, gain, kind };
}

export const sfx = {
  hit() {
    // Brief noise burst + low thump
    noiseBurst(0.08, 0.20, 1500);
    tone(120, 0.10, 'square', 0.18);
  },
  pickup() {
    // Bright two-note bling
    tone(660, 0.08, 'sine', 0.20);
    setTimeout(() => tone(990, 0.10, 'sine', 0.18), 60);
  },
  /** Tier-matched chime fired when a drop SPAWNS (not picked up).
   *  Scales: common → soft tink, uncommon → 2-note, rare → 3-note,
   *  unique → 4-note ascending fanfare. The rarity is passed as a
   *  string. Loot-juice pillar 4. */
  lootDrop(rarity = 'common') {
    if (rarity === 'unique') {
      tone(523, 0.10, 'triangle', 0.22);
      setTimeout(() => tone(659, 0.10, 'triangle', 0.22), 70);
      setTimeout(() => tone(784, 0.10, 'triangle', 0.24), 140);
      setTimeout(() => tone(1047, 0.20, 'triangle', 0.26), 210);
    } else if (rarity === 'rare') {
      tone(440, 0.10, 'triangle', 0.18);
      setTimeout(() => tone(659, 0.12, 'triangle', 0.20), 80);
      setTimeout(() => tone(880, 0.16, 'triangle', 0.18), 160);
    } else if (rarity === 'uncommon') {
      tone(523, 0.08, 'sine', 0.16);
      setTimeout(() => tone(784, 0.10, 'sine', 0.18), 70);
    } else {
      tone(880, 0.05, 'sine', 0.10);   // common — soft tink
    }
  },
  chest() {
    // Wood creak + soft chime cluster
    noiseBurst(0.18, 0.12, 800);
    setTimeout(() => tone(523, 0.18, 'triangle', 0.20), 120);
    setTimeout(() => tone(659, 0.20, 'triangle', 0.18), 200);
    setTimeout(() => tone(784, 0.22, 'triangle', 0.16), 280);
  },
  footstep() {
    noiseBurst(0.04, 0.06, 600);
  },
  /** Surface-aware footstep variant. `kind` is one of:
   *  'grass' (default) | 'stone' | 'floor' | 'path' | 'sand' | 'water'
   *  Each picks a slightly different filter cutoff + volume so the
   *  player can hear what they're stepping on. */
  footstepOn(kind = 'grass') {
    switch (kind) {
      case 'stone':
      case 'floor':
        // Sharper, harder tap — higher LPF + brief click tone.
        noiseBurst(0.05, 0.10, 1800);
        tone(900, 0.04, 'square', 0.06);
        break;
      case 'path':
      case 'sand':
        noiseBurst(0.05, 0.05, 900);
        break;
      case 'water':
        // Watery slosh — lower LPF, longer noise tail.
        noiseBurst(0.10, 0.07, 400);
        break;
      case 'grass':
      default:
        noiseBurst(0.04, 0.06, 600);
        break;
    }
  },
  craft() {
    // Hammer-on-anvil — two bright chinks
    tone(1300, 0.05, 'square', 0.18);
    setTimeout(() => tone(1100, 0.06, 'square', 0.16), 90);
  },
  death() {
    // Descending mournful tone
    tone(440, 0.30, 'sine', 0.22);
    setTimeout(() => tone(330, 0.40, 'sine', 0.20), 200);
    setTimeout(() => tone(220, 0.60, 'sine', 0.18), 500);
  },
  cricket() {
    // High triplet chirp — short tones at ~5kHz with rapid amplitude
    // wobble; reads as a single insect chirping nearby.
    tone(5000, 0.04, 'sine', 0.04);
    setTimeout(() => tone(5200, 0.04, 'sine', 0.04), 80);
    setTimeout(() => tone(5000, 0.04, 'sine', 0.04), 160);
  },
  owl() {
    // Two soft hoots — descending, low.
    tone(360, 0.20, 'sine', 0.06);
    setTimeout(() => tone(310, 0.30, 'sine', 0.06), 280);
  },
  growl() {
    // Low rumble + brief noise burst. Used as enemy idle vocalization
    // when an aggro'd hostile is within earshot but not yet attacking.
    // Frequency randomly varies 60-90Hz so consecutive growls don't
    // feel like the same loop.
    const f = 60 + Math.random() * 30;
    tone(f, 0.45, 'sawtooth', 0.10, 0.02, 0.45);
    noiseBurst(0.20, 0.05, 350);
  },
  enemyDeath() {
    // Short descending wheeze + low thump. Distinct from sfx.death
    // (player death) — enemy death is shorter and bassier so it doesn't
    // dominate the audio when multiple enemies fall in quick succession.
    tone(180, 0.18, 'sawtooth', 0.16);
    setTimeout(() => tone(110, 0.30, 'sine', 0.14), 80);
    noiseBurst(0.12, 0.08, 400);
  },
  miss() {
    // Whiff — high noise, brief
    noiseBurst(0.10, 0.06, 2000);
  },
  parry() {
    // Bright metallic ping — clean parry
    tone(900, 0.04, 'triangle', 0.18);
    setTimeout(() => tone(1320, 0.16, 'triangle', 0.20), 30);
  },
  riposte() {
    // Two-note flourish — perfect-counter feel
    tone(880, 0.10, 'sine', 0.22);
    setTimeout(() => tone(1320, 0.20, 'sine', 0.22), 80);
  },
  dialogOpen() {
    tone(440, 0.06, 'sine', 0.10);
    setTimeout(() => tone(660, 0.06, 'sine', 0.10), 60);
  },
  dialogClose() {
    tone(660, 0.05, 'sine', 0.08);
    setTimeout(() => tone(440, 0.05, 'sine', 0.08), 50);
  },
  questAccept() {
    // C → G, two-note resolution start
    tone(523, 0.16, 'triangle', 0.20);
    setTimeout(() => tone(784, 0.20, 'triangle', 0.20), 110);
  },
  questDone() {
    // C → E → G major arpeggio resolve
    tone(523, 0.16, 'sine', 0.22);
    setTimeout(() => tone(659, 0.16, 'sine', 0.22), 110);
    setTimeout(() => tone(784, 0.30, 'sine', 0.22), 220);
  },
  /** Resume context on first user gesture (browsers require this). */
  resume() {
    const ctx = ensureCtx();
    if (ctx && ctx.state === 'suspended') ctx.resume();
  },
  /** Start (or swap) the ambient drone. Idempotent for the same kind. */
  startAmbient(kind = 'dungeon') {
    const ctx = ensureCtx();
    if (!ctx) return;
    if (_amb && _amb.kind === kind) return;
    if (_amb) this.stopAmbient();
    _amb = buildAmbient(kind);
    if (!_amb) return;
    const now = ctx.currentTime;
    _amb.gain.gain.cancelScheduledValues(now);
    _amb.gain.gain.setValueAtTime(0, now);
    _amb.gain.gain.linearRampToValueAtTime(0.18, now + 1.2);
  },
  /** Smoothly retune the active ambient drone's filter — used by the
   *  day/night cycle to "hush" the world at midnight and brighten at noon.
   *  brightness ∈ [0, 1]: 0 = deep hush (low cutoff), 1 = open (high cutoff). */
  setAmbientBrightness(brightness) {
    if (!_amb) return;
    const ctx = ensureCtx();
    if (!ctx) return;
    const b = Math.max(0, Math.min(1, brightness));
    const p = _AMB_PRESETS[_amb.kind] || _AMB_PRESETS.village;
    _amb.filter.frequency.setTargetAtTime(p.brightBase + (p.brightPeak - p.brightBase) * b, ctx.currentTime, 1.5);
  },
  /** Fade and tear down the ambient drone. */
  stopAmbient() {
    if (!_amb) return;
    const ctx = ensureCtx();
    const now = ctx.currentTime;
    const a = _amb; _amb = null;
    a.gain.gain.cancelScheduledValues(now);
    a.gain.gain.linearRampToValueAtTime(0, now + 0.6);
    setTimeout(() => {
      try { a.osc1.stop(); a.osc2.stop(); a.lfo.stop(); } catch (_) {}
    }, 800);
  },
};
