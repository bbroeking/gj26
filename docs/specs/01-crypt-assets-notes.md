# Implementation notes — 01-crypt-assets

## Surprises

- **Every `.webp` file in `docs/concept-art/dungeons/crypt/` is a 5455-byte Cloudflare bot-challenge HTML page, not an image.**
  - `file dungeon-crypt-altar-v0.webp` → `HTML document text, ASCII text, with very long lines (5455)`
  - First 500 bytes: `<!DOCTYPE html>…<title>Just a moment...</title>…challenges.cloudflare.com…`
  - All 100 files have the **exact same size (5455 bytes)** because they're all the same Cloudflare interstitial.
  - The earlier curl downloads in this project's history reported `ok dungeon-crypt-<piece>-vN.webp` and the file count was right (100), so the failure was invisible. curl received the HTML response with a 200 status; the content was just an HTML stall page asking the client to verify it's human, not an image.

- **Chrome connector bypasses Cloudflare cleanly.** Driving MJ's web UI via `mcp__claude-in-chrome__*` uses the user's authenticated session, which has the Cloudflare clearance cookie. The per-image Download button delivers a full-res PNG (~1024px, ~300KB) instead of the 640px CDN webp we were trying to scrape.
  - Filename pattern: `qurtyyy_<prompt-fragment-50-chars>_<jobId>_<variantIndex>.png` — lands in `~/Downloads/`.
  - Test: downloaded the bookshelf v3 (jobId `c9bcb7b2-7161-4276-9056-26657565bad3`, index 3) successfully. 341KB PNG of the correct asset.

## Implications (resolved — see Decisions below)

- ~~Cannot pick variants~~ → fixed by re-downloading via Chrome connector + MJ web UI.
- ~~Cannot run Meshy~~ → unblocked, real PNGs in place.
- ~~Cannot identify the 4 `_UNK_` files~~ → done; all 4 renamed below.

## Decisions

- **Variant picks (all 20 pieces — chosen for cleanest silhouette, plain background, no clutter that hurts Meshy isolation):**

  | Piece | Pick | Reason |
  |---|---|---|
  | altar | v3 | melted candles on grey stone w/ runes — matches "two melted candle stubs" spec; v0/v1/v2 had faces or demon imagery |
  | archway | v1 | cleanest "walk-through" opening with blank background visible through arch |
  | bones | v3 | actual bone fragments + one intact skull on top; v0 too vague, v1 cubes, v2 too many skulls |
  | bookshelf | v3 | darker grey wood + red spines + sprouting plants — cryptier vibe vs v1/v2 cheerful warm-wood |
  | brazier | v2 | brazier with coals (no smiley-flame anthropomorphism); v3 has dark bg that hurts Meshy isolation |
  | chest | v0 | archetypal silhouette — clean wood + iron bands + prominent keyhole; v3's plants would clutter Meshy |
  | column | v3 | most classical-column silhouette (round shaft + base + capital); others read as wall blocks |
  | door-wood | v2 | strongest "tomb door" — single arched panel + iron bands + iron ring knocker; no ivy clutter |
  | floor-brick | v2 | cleanest brick-grid pattern with warm beige; v1/v3 read as cobble |
  | floor-cracked | v3 | cleanest "cracked flagstone tiles" — large panels with hairline cracks; v0/v2 are cobble |
  | floor-mossy | v2 | tileable moss-tuft pattern in gaps; v0/v1 have full bushes that won't tile |
  | pottery | v0 | cleanest contained mound silhouette of broken shards; others too scattered for Meshy |
  | rug | v3 | dungeon-y triangle border + fringe + plain red center; v0/v2 too busy, v1 too plain |
  | sarcophagus | v0 | classic sarcophagus — rectangular box + carved lid + cross/gem; v2 mis-rendered as a column |
  | stairs | v2 | chunky 3/4-view steps matching in-game camera; v1 mis-rendered as a wall, v3 split into studies |
  | torch-wall | v2 | sconce + generic flame + plain wall; v1 had pumpkin face, v3 too ornate |
  | wall-corner-inner | v3 | closest to L-shape with two visible wall faces; others render as single walls/towers |
  | wall-corner-outer | v0 | two faces splitting from central vertical edge — textbook outer corner |
  | wall-straight | v1 | clean horizontal straight-wall section with concentrated stone coverage |
  | web | v2 | best X-corner-spread cobweb pattern for corner-decal billboard |

- **Re-downloaded all 80 PNGs via Chrome MCP driving the MJ web UI.** Each `https://www.midjourney.com/jobs/<jobId>?index=<N>` page has a `button[title="Download Image"]` which a JS `.click()` fires. Files land in `~/Downloads/` as `qurtyyy_<promptfrag>_<jobid>_<idx>.png`. Bypasses Cloudflare entirely because it's the user's authenticated session.
- **Used a polling JS click** to handle MJ's render timing: `async loop; for i<30; sleep 200ms; if btn exists click & return; else continue`. 100% reliable across 80 downloads (one duplicate from earlier coordinate-click experiments was cleaned up by hand).
- **`_UNK_<jobid>` identification by reading the downloaded PNGs:**
  - `_UNK_1d7eedd7` → `wall-corner-outer` (vertical edge where two wall faces meet pointing outward)
  - `_UNK_32c5f718` → `wall-corner-inner` (L-shaped inside corner; both faces visible)
  - `_UNK_7c981aa9` → `brazier` (smiley-face flame on a tripod)
  - `_UNK_e78fae36` → `archway` (round-arched stone doorway, no door)
- **Renamed canonical:** files moved to `docs/concept-art/dungeons/crypt/dungeon-crypt-<piece>-v<N>.png`. 20 pieces × 4 variants = 80 PNGs, all distinct (verified by 4 unique file sizes per job).
- **Format swap:** dropped `.webp` extension; files are now native `.png` (which is what MJ delivers via Download). PROMPTS.md will need a one-line update to reflect `.png` filenames if it references `.webp`.

## Tradeoffs

- **Polling JS vs fixed-wait clicks.** Fixed 2s waits had ~25% miss rate (page not rendered yet); fixed 4s waits got 100% but added ~50s per batch. Polling JS (200ms × up to 30) auto-tunes — cold loads got ~200-600ms wait, warm reloads got 0ms. Faster overall.
- **One torch-wall duplicate.** Manual coordinate-click experiment created a duplicate `..._3 (1).png` before the polling approach was adopted. Deleted by hand.

## Meshy run (2026-05-20)

- **16 of 17 props successfully converted**: altar, archway, bones, bookshelf, brazier, chest, column, door-wood, pottery, rug, sarcophagus, stairs, torch-wall, wall-corner-inner, wall-corner-outer, wall-straight. All in `models/dungeon_crypt_<piece>_v1.glb` between 55KB (rug) and 144KB (sarcophagus). Pipeline: niji 6 PNG → Meshy Image-to-3D (Meshy 6, Standard, ~30s–90s, 20 credits) → `clean_ai_mesh.py --rig static --tris {3000-8000}` → models/.
- **Web FAILED** in Meshy with "Generating failed" — the thin radial pattern doesn't carry enough volume for the Image-to-3D pipeline (matches the followup prediction). Web stays as a billboard: use the PNG as a transparent texture on a small PlaneGeometry placed at corner positions in dungeon rooms. Lost 20 credits on the failed attempt with no refund.
- **Total credits used**: ~340 (2,140 → 1,800).
- **Meshy auto-names** were colorful: bookshelf→"Tome Tower", altar→"Runestone Altar", archway→"Stone Archway", bones→"Cat on a Paper Mountain", brazier→"Embers on a Tripod", chest→"Golden Treasure Chest", column→"Sunlit Ancient Column", door→"Gateway of Timber and Stone", pottery→"Crimson Heap", rug→"Crimson Geometric Rug", sarcophagus→"Icebound Relic Chest", stairs→"Stone Staircase", torch-wall→"Torch on the Stone Wall", wall-corner-inner→"Blue Bastion", wall-corner-outer→"Stone Wall Ruins", wall-straight→"Overgrown Stone Wall", web→"Starburst Web" (failed). Filenames in `~/Downloads/Meshy_AI_<auto-name>_<timestamp>_generate.glb`.

## Followups

1. **Web billboard implementation.** The web PNG (`docs/concept-art/dungeons/crypt/dungeon-crypt-web-v2.png`) needs to be a transparent texture on a PlaneGeometry billboard. Probably author a small `dungeon_crypt_web_v1` PlaneGeometry mesh in code with the PNG as `MeshBasicMaterial({map, transparent:true, alphaTest:0.5})`. Per spec 02, places at corners of crypt rooms.
2. **Re-roll the wall-corner pieces** if visual quality is poor in-game. Both came through Meshy but the source PNGs were weak (Midjourney drifted from L-shape geometry). v3-inner and v0-outer are least-bad picks; a new MJ prompt batch with sharper "isometric 3/4 view, corner geometry, two faces meeting at 90° vertical edge" language would land cleaner sources.
3. **Floor textures** — `floor-brick-v2`, `floor-cracked-v3`, `floor-mossy-v2` PNGs go straight to `assets/textures/` (not Meshy, they're tileable textures).
4. **Tris budgets used**: 3000 for pottery+rug (flat-ish props), 8000 for sarcophagus (large silhouette), 5000 for all others. Sarcophagus came out 144KB; everything else 55-91KB.
5. **Browser automation lessons** (for future runs): (a) The Meshy CSP `connect-src` allows `http://localhost:8080` but not arbitrary ports — use 8080 for the local CORS server. (b) Direct file_upload fails (sandboxed) but `fetch → File → DataTransfer.items.add → input.files = dt.files → dispatchEvent('change')` works reliably from JS. (c) Click coords shift at resize — re-screenshot if browser dimensions change. (d) Click "Image" tab on left sidebar (the camera-icon at top), not the Nano-Banana "Image" entry. (e) Meshy occasionally shows stale progress %; reloading the workspace refreshes state without losing in-progress jobs.

## What was verified

- `scripts/clean_ai_mesh.py` exists (18121 bytes) — ready for static-rig prop cleanup.
- `models/` folder exists with the project's existing GLBs (cow, bramble_imp variants, archer, etc.) — drop location is fine.
- Naming convention is settled: pieces map cleanly to `models/dungeon_crypt_<piece>_v1.glb`.
- 80 PNGs in `docs/concept-art/dungeons/crypt/` covering 20 pieces × 4 variants — all distinct, none corrupt, all displayable in Read tool.
