#!/usr/bin/env python3
"""Regenerate docs/manifest.json for the design-bible viewer.

Run from anywhere:  python3 docs/regen-manifest.py
Re-run whenever docs are added/moved/renamed.

Produces, relative to docs/:
  - byName:     basename(no ext) -> path   (for [[wikilink]] resolution)
  - collisions: basename -> [paths...]      (same filename in >1 folder)
  - tree:       every browsable doc {path, type, dir}  (for all.html)

Infra files (the viewer's own pages + the stylesheet) are excluded.
On a basename collision, byName prefers the shortest path (fewest
segments, then alphabetical); the full set stays reachable via all.html.
"""
import json, os

DOCS = os.path.dirname(os.path.abspath(__file__))
INFRA = {"index.html", "view.html", "all.html", "design-system.css", "regen-manifest.py"}

md_paths, html_paths = [], []
for root, dirs, files in os.walk(DOCS):
    dirs[:] = [d for d in dirs if not d.startswith(".")]
    for f in files:
        rel = os.path.relpath(os.path.join(root, f), DOCS)
        if rel in INFRA:
            continue
        if f.endswith(".md"):
            md_paths.append(rel)
        elif f.endswith(".html"):
            html_paths.append(rel)

md_paths.sort()
html_paths.sort()

# basename -> candidate paths
cand = {}
for p in md_paths:
    base = os.path.splitext(os.path.basename(p))[0]
    cand.setdefault(base, []).append(p)

by_name, collisions = {}, {}
for base, paths in cand.items():
    chosen = sorted(paths, key=lambda x: (x.count(os.sep), x))[0]
    by_name[base] = chosen
    if len(paths) > 1:
        collisions[base] = sorted(paths)

tree = [{"path": p, "type": "md", "dir": os.path.dirname(p) or "."} for p in md_paths]
tree += [{"path": p, "type": "html", "dir": os.path.dirname(p) or "."} for p in html_paths]

out = {"byName": by_name, "collisions": collisions, "tree": tree,
       "counts": {"md": len(md_paths), "html": len(html_paths)}}

with open(os.path.join(DOCS, "manifest.json"), "w") as fh:
    json.dump(out, fh, indent=0, sort_keys=True)

print(f"manifest.json: {len(md_paths)} md, {len(html_paths)} html, "
      f"{len(collisions)} basename collision(s)")
if collisions:
    for b, ps in collisions.items():
        print(f"  collision {b!r}: byName -> {by_name[b]}  (others: {[p for p in ps if p != by_name[b]]})")
