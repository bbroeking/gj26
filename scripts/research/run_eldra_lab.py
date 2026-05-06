#!/usr/bin/env python3
"""Eldra autoresearch loop runner.

Reads prompt JSON files from docs/research/eldra/runs/<id>/prompt.json,
invokes the Eldra build script with each prompt's env vars, renders a
thumbnail, and appends to docs/research/eldra/manifest.json so the codex
gallery can list every experiment.

Each prompt JSON has the schema:

  {
    "id":          "r004_simplify_2_cast",
    "title":       "FORM_MERGE=2 + body cast 0.3",
    "hypothesis":  "Dropping shawl drapes + merging tabard reads as one
                    sculpted torso instead of stacked panels. Mild Cast
                    softens the remaining flat front of the tunic.",
    "params": {
      "ELDRA_VARIANT":     "s",
      "ELDRA_SKIP_GRASS":  "1",
      "ELDRA_FORM_MERGE":  "2",
      "ELDRA_BODY_CAST":   "0.3"
    },
    "parent": "r003_simplify_2",
    "rating": null,
    "notes":  ""
  }

Run from the project root:
  python3 scripts/research/run_eldra_lab.py [run_id...]

If you pass run ids it builds only those; otherwise it walks every prompt
in docs/research/eldra/runs/ that doesn't already have a model.glb.
"""
import json, os, subprocess, sys, time
from datetime import datetime, timezone

ROOT      = os.path.abspath(os.path.dirname(__file__) + '/../..')
RUNS_DIR  = os.path.join(ROOT, 'docs/research/eldra/runs')
MANIFEST  = os.path.join(ROOT, 'docs/research/eldra/manifest.json')
BLENDER   = '/Applications/Blender.app/Contents/MacOS/Blender'
BUILD     = os.path.join(ROOT, 'scripts/build_npc_eldra_v2.py')
RENDER    = os.path.join(ROOT, 'scripts/render_npc_thumbnail.py')

def load_prompt(run_id):
    path = os.path.join(RUNS_DIR, run_id, 'prompt.json')
    with open(path) as f:
        return json.load(f)

def save_prompt(run_id, prompt):
    path = os.path.join(RUNS_DIR, run_id, 'prompt.json')
    with open(path, 'w') as f:
        json.dump(prompt, f, indent=2)

def build_one(run_id, force=False):
    prompt = load_prompt(run_id)
    out_glb_name = f'npc_eldra_v2_{run_id}.glb'
    out_glb = os.path.join(ROOT, 'models', out_glb_name)
    out_thumb = os.path.join(RUNS_DIR, run_id, 'thumb.png')
    out_glb_link = os.path.join(RUNS_DIR, run_id, 'model.glb')

    if not force and os.path.exists(out_glb_link):
        print(f"[skip] {run_id} — model.glb exists (use --force to rebuild)")
        return prompt, False

    env = os.environ.copy()
    env.update(prompt.get('params', {}))
    env['ELDRA_OUT_NAME'] = run_id

    print(f"\n=== Building {run_id} ===")
    print(f"    title:  {prompt.get('title','')}")
    print(f"    params: {prompt.get('params',{})}")
    t0 = time.time()
    r = subprocess.run(
        [BLENDER, '--background', '--python', BUILD],
        env=env, cwd=ROOT, capture_output=True, text=True,
    )
    if r.returncode != 0:
        print(f"[FAIL] {run_id}: blender returned {r.returncode}")
        print(r.stderr[-2000:])
        return prompt, False
    if not os.path.exists(out_glb):
        print(f"[FAIL] {run_id}: build script ran but {out_glb_name} missing")
        return prompt, False

    # Symlink models/<glb> into the run folder so the codex can load it.
    if os.path.exists(out_glb_link) or os.path.islink(out_glb_link):
        os.remove(out_glb_link)
    os.symlink(os.path.relpath(out_glb, os.path.dirname(out_glb_link)),
               out_glb_link)

    print(f"    [{time.time()-t0:.1f}s] glb -> {out_glb_link}")

    # Render the thumbnail.
    print(f"    rendering thumb...")
    rr = subprocess.run(
        [BLENDER, '--background', '--python', RENDER, '--', out_glb, out_thumb],
        cwd=ROOT, capture_output=True, text=True,
    )
    if rr.returncode != 0:
        print(f"[warn] {run_id}: thumbnail render failed (non-fatal)")
    else:
        print(f"    thumb -> {out_thumb}")

    prompt.setdefault('outputs', {})
    prompt['outputs']['glb']   = f'models/{out_glb_name}'
    prompt['outputs']['thumb'] = f'docs/research/eldra/runs/{run_id}/thumb.png'
    prompt['built_at']         = datetime.now(timezone.utc).isoformat()
    save_prompt(run_id, prompt)
    return prompt, True

def update_manifest():
    runs = []
    for d in sorted(os.listdir(RUNS_DIR)):
        path = os.path.join(RUNS_DIR, d, 'prompt.json')
        if not os.path.exists(path):
            continue
        with open(path) as f:
            runs.append(json.load(f))
    manifest = {
        'updated': datetime.now(timezone.utc).isoformat(),
        'count':   len(runs),
        'runs':    runs,
    }
    with open(MANIFEST, 'w') as f:
        json.dump(manifest, f, indent=2)
    print(f"\nManifest updated — {len(runs)} runs total: {MANIFEST}")

def main():
    args = sys.argv[1:]
    force = '--force' in args
    args = [a for a in args if a != '--force']

    # If no specific run ids given, walk all runs in the runs dir.
    if not args:
        args = sorted(d for d in os.listdir(RUNS_DIR)
                      if os.path.isdir(os.path.join(RUNS_DIR, d)))

    for run_id in args:
        if not os.path.exists(os.path.join(RUNS_DIR, run_id, 'prompt.json')):
            print(f"[skip] {run_id} — no prompt.json")
            continue
        build_one(run_id, force=force)

    update_manifest()

if __name__ == '__main__':
    main()
