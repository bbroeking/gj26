// Dialog modal — NPC speech, level-up callouts, future shops.
// Single shared overlay. Call `showDialog({...})` to open and pass an
// `onClose` callback if you need to react to dismissal.
//
// Markup expected in index.html:
//   #dialog-backdrop > #dialog > .speaker / .lines / .choices / .hint

const backdrop = document.getElementById('dialog-backdrop');
const dialog   = document.getElementById('dialog');
const speakerEl = dialog.querySelector('.speaker');
const linesEl   = dialog.querySelector('.lines');
const choicesEl = dialog.querySelector('.choices');
const hintEl    = dialog.querySelector('.hint');

let currentOnClose = null;

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
export function showDialog({ speaker, lines = [], choices, onClose } = {}) {
  import('../core/sfx.js').then(m => m.sfx.dialogOpen()).catch(() => {});
  speakerEl.textContent = speaker || '';
  linesEl.innerHTML = lines.map(l => `<p>${escapeHTML(l)}</p>`).join('');
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

// ESC closes; click on backdrop (not inner card) closes.
window.addEventListener('keydown', (e) => {
  if (e.key === 'Escape' && isDialogOpen()) {
    closeDialog();
    e.stopPropagation();
  }
});
backdrop.addEventListener('click', (e) => {
  if (e.target === backdrop) closeDialog();
});
