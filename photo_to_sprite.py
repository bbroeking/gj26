#!/usr/bin/env python3
"""
photo_to_sprite.py

Convert a portrait photograph into a pixel-art sprite suitable for the
Agent Sprite Forge game engine. Inspired by the deterministic pixel
operations from the agent-sprite-forge skill, but operates on an
existing image instead of generating one from a prompt.

Pipeline:
  1. Crop to a square around the head (heuristic, tunable).
  2. Median filter to reduce photographic noise.
  3. Resize to small pixel-grid sizes (default 16, 32).
  4. Adaptive-palette quantization (16 colors).
  5. Generate animation frames by editing the eye / mouth bands.
  6. Export PNG, upscaled-PNG (for inspection), and an animated GIF.
  7. Map the 16x16 result to the game's char-grid SPR palette and
     emit a JS snippet ready to paste into game.js.

Usage:
    python3 photo_to_sprite.py <source_image> [name]

Example:
    python3 photo_to_sprite.py ~/Downloads/trump.jpeg trump
"""
import os
import sys
import warnings
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageOps, ImageEnhance
from scipy import ndimage

# Numpy 2.0 + sklearn matmul throws benign RuntimeWarnings — silence them.
warnings.filterwarnings('ignore', category=RuntimeWarning)

# DawnBringer 32 — a classic curated pixel-art palette with strong skin
# tones, blues, reds; widely used because it reads well at low res.
DAWNBRINGER_32 = [
    (0, 0, 0),       (34, 32, 52),    (69, 40, 60),    (102, 57, 49),
    (143, 86, 59),   (223, 113, 38),  (217, 160, 102), (238, 195, 154),
    (251, 242, 54),  (153, 229, 80),  (106, 190, 48),  (55, 148, 110),
    (75, 105, 47),   (82, 75, 36),    (50, 60, 57),    (63, 63, 116),
    (48, 96, 130),   (91, 110, 225),  (99, 155, 255),  (95, 205, 228),
    (203, 219, 252), (255, 255, 255), (155, 173, 183), (132, 126, 135),
    (105, 106, 106), (89, 86, 82),    (118, 66, 138),  (172, 50, 50),
    (217, 87, 99),   (215, 123, 186), (143, 151, 74),  (138, 111, 48),
]

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'sprites')
os.makedirs(OUT, exist_ok=True)

# Game's char-grid palette (match game.js PAL exactly).
GAME_PAL = {
    '0': (0x0a, 0x0a, 0x0a),
    '1': (0x1f, 0x14, 0x10),
    '2': (0x2d, 0x4a, 0x1f),
    '3': (0x4a, 0x7a, 0x2f),
    '4': (0x6b, 0xa0, 0x3d),
    '5': (0x5a, 0x3a, 0x1a),
    '6': (0x8a, 0x5a, 0x2a),
    '7': (0xca, 0xa3, 0x7b),
    '8': (0xde, 0xc2, 0x95),
    '9': (0x2d, 0x4a, 0x8a),
    'A': (0x4a, 0x6c, 0xba),
    'B': (0x5e, 0x5e, 0x66),
    'C': (0x9a, 0x9a, 0xa2),
    'D': (0xc8, 0xc8, 0xd0),
    'E': (0xfc, 0xd1, 0xa4),
    'F': (0xc0, 0x39, 0x2b),
    'G': (0xec, 0xc9, 0x4b),
    'H': (0xff, 0xff, 0xff),
    'I': (0x4a, 0xb0, 0x7c),
    'J': (0x2c, 0x6e, 0x4d),
    'K': (0xa3, 0xd2, 0x7a),
    'L': (0xb0, 0x7c, 0x9a),
    'M': (0x5e, 0x88, 0xc8),
    'N': (0xa5, 0x52, 0x3a),
    'O': (0xf2, 0x5c, 0x4f),
    'P': (0xff, 0xf8, 0xc8),
    'Q': (0xd4, 0xaf, 0x37),
    'R': (0x7c, 0xc1, 0x4a),
    'S': (0x3a, 0x8a, 0x5a),
    'T': (0x5d, 0x2c, 0x14),
    'U': (0x8a, 0x4a, 0x1c),
    'V': (0x24, 0x14, 0x08),
    'W': (0x80, 0x55, 0x3a),
    'X': (0x1c, 0x1c, 0x24),
    'Y': (0xf4, 0xf4, 0xf4),
}


def nearest_key(rgb):
    """Closest palette key (Euclidean RGB) to the given color tuple."""
    r, g, b = rgb[:3]
    best_k, best_d = '0', 1 << 30
    for k, (kr, kg, kb) in GAME_PAL.items():
        d = (kr - r) ** 2 + (kg - g) ** 2 + (kb - b) ** 2
        if d < best_d:
            best_d, best_k = d, k
    return best_k


def skin_tone_bbox(img):
    """
    Find the densest skin-tone region using axis histograms.
    Robust against warm-coloured background (walls, lights) that would
    inflate a simple min/max bbox.
    """
    arr = np.asarray(img)
    if arr.ndim != 3:
        return None
    R, G, B = arr[..., 0].astype(int), arr[..., 1].astype(int), arr[..., 2].astype(int)
    # stricter skin filter: warm-orange face tone, not pale wall beige
    mask = (
        (R > 110) & (G > 45) & (B > 20) &
        (R > G + 10) & (G > B + 5) &
        ((R - B) > 35)
    )
    if mask.sum() < 1000:
        return None
    # column / row histograms
    cols = mask.sum(axis=0).astype(float)
    rows = mask.sum(axis=1).astype(float)
    # smooth with a small box filter so spurious bg pixels don't form peaks
    def smooth(arr, k=15):
        kernel = np.ones(k) / k
        return np.convolve(arr, kernel, mode='same')
    cols_s = smooth(cols)
    rows_s = smooth(rows)
    # Find peak, then expand until density drops below 25% of peak
    def width_around_peak(hist, threshold_frac=0.25):
        peak_idx = int(hist.argmax())
        thresh = hist[peak_idx] * threshold_frac
        lo = peak_idx
        while lo > 0 and hist[lo - 1] >= thresh:
            lo -= 1
        hi = peak_idx
        while hi < len(hist) - 1 and hist[hi + 1] >= thresh:
            hi += 1
        return lo, hi
    x0, x1 = width_around_peak(cols_s)
    y0, y1 = width_around_peak(rows_s)
    return (x0, y0, x1, y1)


def tight_face_crop(img, hair_pad=0.55, chin_pad=0.15, side_pad=0.06, debug=True):
    """
    Crop tight around the face using skin-tone detection, then expand
    upward to include hair and downward for a bit of neck/shoulders.
    Result is squared.
    """
    bbox = skin_tone_bbox(img)
    W, H = img.size
    if bbox is None:
        # heuristic fallback (the old behavior)
        cx = W // 2
        cy = int(H * 0.45)
        side = int(min(W, H) * 0.7)
        half = side // 2
        return img.crop((max(0, cx - half), max(0, cy - half),
                         min(W, cx + half), min(H, cy + half)))

    x0, y0, x1, y1 = bbox
    if debug:
        print(f'  skin bbox (face only): ({x0},{y0}) - ({x1},{y1})  size {x1-x0}x{y1-y0}')
    fw = x1 - x0
    fh = y1 - y0
    # expand to include hair / a bit of chin / minor side margin
    x0 -= int(fw * side_pad)
    x1 += int(fw * side_pad)
    y0 -= int(fh * hair_pad)
    y1 += int(fh * chin_pad)
    # square the box around its centre
    cx = (x0 + x1) // 2
    cy = (y0 + y1) // 2
    side = max(x1 - x0, y1 - y0)
    half = side // 2
    left = max(0, cx - half)
    top = max(0, cy - half)
    right = min(W, cx + half)
    bottom = min(H, cy + half)
    side = min(right - left, bottom - top)
    if debug:
        print(f'  expanded square crop: ({left},{top}) side={side}')
    return img.crop((left, top, left + side, top + side))


def boost(img, contrast=1.20, saturation=1.18, sharpness=1.10):
    """Mild pre-quantization punch-up so faces hold up at low res."""
    img = ImageEnhance.Contrast(img).enhance(contrast)
    img = ImageEnhance.Color(img).enhance(saturation)
    img = ImageEnhance.Sharpness(img).enhance(sharpness)
    return img


def bilateral_like(img, passes=3, size=5):
    """
    Approximate a bilateral filter (edge-preserving smoothing) by stacking
    median filter passes. Median preserves edges while smoothing flat areas
    — exactly what you want before quantization.
    """
    out = img
    for _ in range(passes):
        out = out.filter(ImageFilter.MedianFilter(size=size))
    return out


def kmeans_palette(img, k=24, sample=20000, seed=0):
    """
    Build an image-specific palette via k-means in RGB. Always
    appends pure black (for outlines) and pure white if absent so
    we have controls for line work and highlights.
    """
    from sklearn.cluster import KMeans
    arr = np.asarray(img, dtype=np.float64).reshape(-1, 3)
    if arr.shape[0] > sample:
        idx = np.random.RandomState(seed).choice(arr.shape[0], sample, replace=False)
        arr = arr[idx]
    km = KMeans(n_clusters=k, n_init=4, random_state=seed).fit(arr)
    palette = [tuple(int(round(v)) for v in c) for c in km.cluster_centers_]
    # Ensure black is in palette (for outlines)
    if not any(sum(c) < 60 for c in palette):
        palette.append((0, 0, 0))
    return palette


def quantize_to_palette(arr, palette):
    """
    Map every pixel to its nearest palette color (Manhattan in RGB).
    Vectorised — handles a 1000×1000 image in roughly half a second.
    """
    pal = np.asarray(palette, dtype=np.int16)               # (N, 3)
    flat = arr.reshape(-1, 3).astype(np.int16)              # (M, 3)
    diffs = np.abs(flat[:, None, :] - pal[None, :, :]).sum(axis=2)
    idx = diffs.argmin(axis=1)
    out = pal[idx].reshape(arr.shape).astype(np.uint8)
    return out


def sobel_edge_mask(img, threshold=55):
    """Binary edge mask via Sobel magnitude on luminance."""
    L = np.asarray(img.convert('L'), dtype=np.float32)
    sx = ndimage.sobel(L, axis=1)
    sy = ndimage.sobel(L, axis=0)
    mag = np.hypot(sx, sy)
    return mag > threshold


def pixel_art_pass(img, target_size, palette=None, outline=True, n_colors=24):
    """
    Photo → pixel-art conversion:
      1. flatten regions (median × 3)
      2. build image-specific palette via k-means (or use given palette)
      3. quantize at high res
      4. detect edges on smoothed pre-quantization image
      5. composite outlines onto quantized image
      6. downscale (BOX averaging) to target size
      7. re-quantize at low res to lock to palette
    """
    smoothed = bilateral_like(img, passes=3, size=5)
    if palette is None:
        palette = kmeans_palette(smoothed, k=n_colors)
    arr_smooth = np.asarray(smoothed)
    arr_q = quantize_to_palette(arr_smooth, palette)

    if outline:
        edges = sobel_edge_mask(smoothed, threshold=70)
        # only keep edges where the local color contrast is meaningful
        # (drops a lot of speckled facial-noise edges)
        arr_q[edges] = (0, 0, 0)

    quantized = Image.fromarray(arr_q)
    small = quantized.resize((target_size, target_size), Image.BOX)
    arr_small = np.asarray(small)
    arr_small_q = quantize_to_palette(arr_small, palette)
    return Image.fromarray(arr_small_q), palette


def make_frames(base, size):
    """Generate 4 animation frames: idle, blink, talk1, talk2."""
    idle = base.copy()

    # eye band (rough)
    eye_y = int(size * 0.42)
    eye_x_lo = int(size * 0.30)
    eye_x_hi = int(size * 0.70)
    skin = base.getpixel((size // 2, int(size * 0.30)))

    blink = base.copy()
    drw = ImageDraw.Draw(blink)
    drw.rectangle([eye_x_lo, eye_y, eye_x_hi, eye_y + 1], fill=skin)

    # mouth band
    mouth_y = int(size * 0.72)
    talk1 = base.copy()
    drw = ImageDraw.Draw(talk1)
    drw.rectangle(
        [int(size * 0.40), mouth_y, int(size * 0.60), mouth_y + 1],
        fill=(50, 25, 20),
    )

    talk2 = base.copy()
    drw = ImageDraw.Draw(talk2)
    drw.rectangle(
        [int(size * 0.36), mouth_y - 1, int(size * 0.64), mouth_y + 2],
        fill=(40, 18, 15),
    )

    return [idle, blink, talk1, talk2]


def chargrid(img, size=16):
    """Convert a small RGB image to the game's char-grid SPR format."""
    small = img.resize((size, size), Image.LANCZOS)
    rows = []
    for y in range(size):
        row = ''
        for x in range(size):
            row += nearest_key(small.getpixel((x, y)))
        rows.append(row)
    return rows


def emit_js_snippet(name, rows):
    """Format the grid as a JS array literal pasteable into game.js."""
    lines = ["SPR.{} = [".format(name)]
    for r in rows:
        lines.append("  '{}',".format(r))
    lines.append("];")
    return "\n".join(lines)


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)
    src = sys.argv[1]
    name = sys.argv[2] if len(sys.argv) > 2 else 'sprite'

    print(f'Loading {src}...')
    img = Image.open(src).convert('RGB')
    print(f'  source size: {img.size}')

    img = tight_face_crop(img)
    img = boost(img)
    print(f'  cropped to: {img.size}')

    # Build a shared image-specific palette once (so all sizes use the same
    # colors). 24 clusters from a 3×-median-smoothed source.
    smoothed = bilateral_like(img, passes=3, size=5)
    palette = kmeans_palette(smoothed, k=24)
    print(f'  k-means palette: {len(palette)} colors')

    sizes = (16, 32, 48, 64)
    for size in sizes:
        quant, _ = pixel_art_pass(img, size, palette=palette, outline=size >= 32)
        scale = max(4, 384 // size)
        big = quant.resize((size * scale, size * scale), Image.NEAREST)
        quant.save(f'{OUT}/{name}_{size}.png')
        big.save(f'{OUT}/{name}_{size}_big.png')
        print(f'  saved {name}_{size}.png (k-means palette, outline={size >= 32}, ×{scale} preview)')

    # Animation: 4 frames at 32px (game-friendly) and 64px (high detail)
    for anim_size in (32, 64):
        base = Image.open(f'{OUT}/{name}_{anim_size}.png').convert('RGB')
        frames = make_frames(base, anim_size)
        scale = max(4, 256 // anim_size)
        bigs = [f.resize((anim_size * scale, anim_size * scale), Image.NEAREST) for f in frames]
        bigs[0].save(
            f'{OUT}/{name}_{anim_size}_anim.gif',
            save_all=True,
            append_images=bigs[1:],
            duration=[700, 150, 250, 250],
            loop=0,
        )
        for i, f in enumerate(frames):
            f.save(f'{OUT}/{name}_{anim_size}_f{i}.png')
        print(f'  saved {name}_{anim_size}_anim.gif (4 frames)')

    # Char-grids: 16 (in-game NPC), 32 (portrait NPC w/ richer detail)
    for grid_size in (16, 32):
        rows = chargrid(img, grid_size)
        var_name = f'npc_{name}' + (f'_{grid_size}' if grid_size != 16 else '')
        snippet = emit_js_snippet(var_name, rows)
        grid_path = f'{OUT}/{name}_chargrid_{grid_size}.js'
        with open(grid_path, 'w') as f:
            f.write(snippet + '\n')
        print(f'  saved {grid_path}')

    print()
    print('--- 16x16 Char-grid snippet (paste into game.js SPR section) ---')
    with open(f'{OUT}/{name}_chargrid_16.js') as f:
        print(f.read())


if __name__ == '__main__':
    main()
