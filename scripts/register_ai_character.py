#!/usr/bin/env python3
"""Register an AI-processed character into the codex viewer.

Inputs: the character name (e.g. `npc_mosscloak_ranger_ai_v1`).

What this does:
  1. Inserts the GLB filename into the "AI-generated (Meshy) — test bench"
     group in codex.js MODEL_GROUPS (idempotent — won't double-insert).
  2. Bumps the cache-buster query string in codex.html so the next page
     load picks up the new MODEL_GROUPS array.

What this does NOT do (yet):
  - Wire up the in-game loader / spawn entry in src/main.js +
    src/scene/characters.js. Those still need manual edits because they
    require per-character animation config (lockArm, cadenceMul, leanMul)
    and dialog lines.

Usage:
  python3 scripts/register_ai_character.py npc_mosscloak_ranger_ai_v1
"""

import sys, re, os, datetime

PROJECT_ROOT = os.path.abspath(os.path.dirname(__file__) + '/..')
CODEX_JS = os.path.join(PROJECT_ROOT, 'codex.js')
CODEX_HTML = os.path.join(PROJECT_ROOT, 'codex.html')

def main():
    if len(sys.argv) < 2:
        print("Usage: python3 scripts/register_ai_character.py <character_name>")
        print("       (the GLB filename without .glb)")
        sys.exit(1)
    name = sys.argv[1]
    filename = name + '.glb' if not name.endswith('.glb') else name
    glb_path = os.path.join(PROJECT_ROOT, 'models', filename)
    if not os.path.exists(glb_path):
        print(f"WARN: GLB not found at {glb_path} — registering anyway")

    # 1. Insert filename into the AI-generated MODEL_GROUPS entry
    with open(CODEX_JS, 'r') as f:
        src = f.read()

    # Find the AI-generated group
    pattern = r"(\{ label: 'AI-generated \(Meshy\) — test bench', files: \[\n)(.*?)(\n  \]\},)"
    m = re.search(pattern, src, re.DOTALL)
    if not m:
        print(f"ERROR: 'AI-generated (Meshy)' group not found in codex.js")
        print(f"       Expected pattern: {pattern[:80]}")
        sys.exit(1)
    existing = m.group(2)
    if filename in existing:
        print(f"  Already registered in codex.js — skipping insert")
    else:
        new_entry = f"    '{filename}',\n"
        # Insert before the closing of the files array
        new_block = m.group(1) + existing + ('\n' if not existing.endswith('\n') else '') + new_entry.rstrip('\n') + m.group(3)
        # Actually simpler: just append new line before the close
        replacement = m.group(1) + existing + new_entry + '  ]},'
        # Wait, m.group(3) is "\n  ]},". Rebuild cleanly.
        replacement = (
            m.group(1)
            + existing.rstrip()
            + '\n' + new_entry
            + '  ]},'
        )
        # Drop the original m.group(3) since we're providing the close ourselves.
        # m.group(0) = full match including the close. Replace it.
        src = src[:m.start()] + replacement + src[m.end():]
        with open(CODEX_JS, 'w') as f:
            f.write(src)
        print(f"  Registered {filename} in codex.js")

    # 2. Bump cache-buster in codex.html
    with open(CODEX_HTML, 'r') as f:
        html = f.read()
    today = datetime.date.today().strftime('%Y%m%d')
    new_v = f'{today}-{name.replace("npc_", "").replace("_ai_v1", "")}'
    html2 = re.sub(
        r'src="codex\.js\?v=[^"]+"',
        f'src="codex.js?v={new_v}"',
        html,
    )
    if html != html2:
        with open(CODEX_HTML, 'w') as f:
            f.write(html2)
        print(f"  Bumped codex.html cache-buster → v={new_v}")
    else:
        print(f"  codex.html cache-buster unchanged (regex didn't match)")

    print(f"\nDone. Open http://127.0.0.1:8765/codex.html?cb={new_v} and pick the model from the AI-generated group.")

if __name__ == '__main__':
    main()
