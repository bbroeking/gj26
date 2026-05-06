// Dialog modal — NPC speech, level-up callouts, future shops.
// Single shared overlay. Call `showDialog({...})` to open and pass an
// `onClose` callback if you need to react to dismissal.
//
// Markup expected in index.html:
//   #dialog-backdrop > #dialog > .speaker / .lines / .choices / .hint

const backdrop = document.getElementById('dialog-backdrop');
const dialog   = document.getElementById('dialog');
const speakerEl = dialog.querySelector('.speaker');
const portraitEl = dialog.querySelector('.dialog-portrait');
const linesEl   = dialog.querySelector('.lines');
const choicesEl = dialog.querySelector('.choices');
const hintEl    = dialog.querySelector('.hint');

let currentOnClose = null;
// Active typewriter handle so a new dialog (or Space skip) can cancel
// any in-flight character emission.
let _typeTimer = null;
let _typePending = null;     // { node, full, idx, onDone }

// Portrait file mapping per speaker. Mirrors NPC_PORTRAITS in codex.js
// — kept here so the engine can render dialogs without importing the
// codex module. Add new speakers here as we add NPCs.
const PORTRAITS = {
  'Maud Pennycress':                 'npc-maud-pennycress.png',
  'Old Hod Tenter':                  'npc-hod-tenter.png',
  'Hod':                             'npc-hod-tenter.png',
  'Quill':                           'npc-quill.png',
  'Sir Withering':                   'npc-sir-withering.png',
  'Eldra the Lampwright':            'npc-eldra-lampwright.png',
  'Eldra':                           'npc-eldra-lampwright.png',
  'Cricket the Letter-Carrier':      'npc-cricket.png',
  'Cricket':                         'npc-cricket.png',
  'Brother Pell of the Stone Cloister': 'npc-pell.png',
  'Brother Pell':                    'npc-pell.png',
  'Mother Onywyn the Herb-Witch':    'npc-onywyn.png',
  'Mother Onywyn':                   'npc-onywyn.png',
};

// Queue: showLevelUp during an open dialog stacks rather than overwriting.
const _queue = [];
function _drainQueue() {
  if (isDialogOpen() || _queue.length === 0) return;
  const next = _queue.shift();
  next();
}

/**
 * @param {object} opts
 * @param {string} opts.speaker        — display name (drop-cap'd in CSS)
 * @param {string[]} opts.lines        — paragraphs of dialog
 * @param {{label:string,onClick?:Function}[]} [opts.choices]
 *        — optional choice buttons. If omitted, a default "Continue" button
 *          closes the dialog.
 * @param {Function} [opts.onClose]    — fires when modal closes by any path
 */
export function showDialog({ speaker, lines = [], choices, onClose, portrait, variant } = {}) {
  // Reset any prior variant class — keeps level-up / death from
  // sticking when the next plain dialog opens.
  dialog.classList.remove('levelup', 'death');
  if (variant === 'death') dialog.classList.add('death');
  import('../core/sfx.js').then(m => m.sfx.dialogOpen()).catch(() => {});
  _cancelTypewriter();
  speakerEl.textContent = speaker || '';
  // Portrait — explicit `portrait` arg wins; otherwise look up by speaker
  // name. Empty string hides the portrait altogether (level-up etc.).
  const portraitFile = portrait === ''
    ? null
    : (portrait || PORTRAITS[speaker] || null);
  if (portraitFile && portraitEl) {
    portraitEl.src = `docs/concept-art/${portraitFile}`;
    portraitEl.style.display = 'block';
    portraitEl.alt = speaker || '';
  } else if (portraitEl) {
    portraitEl.style.display = 'none';
    portraitEl.removeAttribute('src');
  }
  // Render lines as <p>s, then run the typewriter.
  linesEl.innerHTML = lines.map(() => '<p></p>').join('');
  const paragraphs = Array.from(linesEl.querySelectorAll('p'));
  _runTypewriter(paragraphs, lines);
  choicesEl.innerHTML = '';

  const cs = choices && choices.length
    ? choices
    : [{ label: 'Continue', onClick: closeDialog }];

  cs.forEach((c, i) => {
    const btn = document.createElement('button');
    btn.className = 'choice-btn';
    // Numbered prefix only for multi-choice dialogs — a single dismiss-style
    // button (e.g. journal "Close") read as a quest entry when numbered.
    btn.innerHTML = cs.length > 1
      ? `<span class="num">${i + 1}.</span> ${escapeHTML(c.label)}`
      : escapeHTML(c.label);
    btn.addEventListener('click', (e) => {
      e.stopPropagation();
      const cb = c.onClick;
      // Default behavior closes; if onClick returns false, leave open.
      const keepOpen = cb && cb() === false;
      if (!keepOpen) closeDialog();
    });
    choicesEl.appendChild(btn);
  });

  currentOnClose = onClose || null;
  backdrop.classList.add('open');
  // Defer focus to next frame so screen readers announce the dialog
  requestAnimationFrame(() => dialog.focus());
}

export function closeDialog() {
  if (!backdrop.classList.contains('open')) return;
  import('../core/sfx.js').then(m => m.sfx.dialogClose()).catch(() => {});
  backdrop.classList.remove('open');
  // Strip any variant class so the next open starts from the default look.
  dialog.classList.remove('levelup');
  const cb = currentOnClose;
  currentOnClose = null;
  if (cb) cb();
  // Show queued level-ups one at a time.
  _drainQueue();
}

/**
 * Celebratory level-up overlay. Reuses the same modal infrastructure but
 * applies the .levelup variant for centered layout, gold number, sage
 * radial wash. Multiple calls in a single frame queue and play in order.
 *
 * @param {object} opts
 * @param {string} opts.skillLabel  — display name ("Strength", "Cooking")
 * @param {number} opts.level        — new level
 * @param {string} [opts.iconHTML]   — inline SVG markup for the skill (~14×14)
 *                                     scaled up by CSS to ~64×64
 */
export function showLevelUp({ skillLabel, level, iconHTML = '' } = {}) {
  // If a dialog is already open, queue and return.
  if (isDialogOpen()) {
    _queue.push(() => showLevelUp({ skillLabel, level, iconHTML }));
    return;
  }
  speakerEl.textContent = 'Level Up';
  // Custom body — replace .lines content with our celebratory layout.
  linesEl.innerHTML = `
    ${iconHTML ? `<div class="lvup-icon">${_resizeIcon(iconHTML, 64)}</div>` : ''}
    <div class="lvup-skill">${escapeHTML(skillLabel || '')}</div>
    <div class="lvup-level"><span class="label">now level</span>${level}</div>
  `;
  choicesEl.innerHTML = '';
  const btn = document.createElement('button');
  btn.className = 'choice-btn';
  btn.textContent = 'Continue';
  btn.addEventListener('click', (e) => { e.stopPropagation(); closeDialog(); });
  choicesEl.appendChild(btn);
  hintEl.style.display = 'none';

  dialog.classList.add('levelup');
  currentOnClose = () => { hintEl.style.display = ''; };
  backdrop.classList.add('open');
  requestAnimationFrame(() => dialog.focus());
}

// Replace width/height on an inline <svg> string so the icon fills the
// celebratory slot without us having to author a separate copy of every glyph.
function _resizeIcon(svg, size) {
  return svg
    .replace(/\swidth="[^"]*"/, ` width="${size}"`)
    .replace(/\sheight="[^"]*"/, ` height="${size}"`)
    .replace(/\sstroke-width="[^"]*"/, ' stroke-width="0.9"');
}

export function isDialogOpen() {
  return backdrop.classList.contains('open');
}

function escapeHTML(s) {
  return String(s)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;');
}

// ---------- TYPEWRITER ----------
// Reveals dialog text one paragraph at a time, ~32 chars/sec. Space or
// Enter skips immediately to the full text without closing the dialog.
const _CHARS_PER_SEC = 60;
function _runTypewriter(paragraphs, fullLines) {
  if (!paragraphs.length) return;
  let pIdx = 0;
  const tickOne = () => {
    if (pIdx >= paragraphs.length) { _typeTimer = null; _typePending = null; return; }
    const p = paragraphs[pIdx];
    const full = fullLines[pIdx] || '';
    let cIdx = 0;
    _typePending = {
      node: p, full,
      idx: cIdx,
      onDone: () => { pIdx++; tickOne(); },
    };
    const stepMs = Math.max(8, Math.round(1000 / _CHARS_PER_SEC));
    const step = () => {
      if (!_typePending) return;
      _typePending.idx += 1;
      _typePending.node.textContent = _typePending.full.slice(0, _typePending.idx);
      if (_typePending.idx >= _typePending.full.length) {
        const onDone = _typePending.onDone;
        _typePending = null;
        _typeTimer = null;
        // Brief pause between paragraphs reads naturally.
        _typeTimer = setTimeout(() => { _typeTimer = null; onDone && onDone(); }, 140);
      } else {
        _typeTimer = setTimeout(step, stepMs);
      }
    };
    _typeTimer = setTimeout(step, stepMs);
  };
  tickOne();
}
function _cancelTypewriter() {
  if (_typeTimer) clearTimeout(_typeTimer);
  _typeTimer = null;
  // Snap any partially-typed paragraph to its full text + finish remaining.
  if (_typePending) {
    _typePending.node.textContent = _typePending.full;
    const onDone = _typePending.onDone;
    _typePending = null;
    if (onDone) onDone();
  }
}
function _isTyping() {
  return !!(_typeTimer || _typePending);
}

// ESC closes; click on backdrop (not inner card) closes. Space / Enter
// skip the typewriter without dismissing — only after typing finishes
// will Space close the dialog.
window.addEventListener('keydown', (e) => {
  if (!isDialogOpen()) return;
  if (e.key === 'Escape') {
    closeDialog();
    e.stopPropagation();
    return;
  }
  if ((e.key === ' ' || e.key === 'Enter') && _isTyping()) {
    _cancelTypewriter();
    e.preventDefault();
    e.stopPropagation();
  }
});
backdrop.addEventListener('click', (e) => {
  if (e.target === backdrop) closeDialog();
});
