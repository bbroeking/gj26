#!/usr/bin/env python3
"""Spec 39 — nine-patch sanity check for panel frame textures.

A frame texture is safe to nine-patch when:
  1. its center region (inside the declared margins) is low-variance
     parchment — no vines/tendrils/art that would tile or smear;
  2. its border thickness is roughly symmetric (within tolerance), so
     symmetric content insets work.

Usage: python3 tools/check_ninepatch.py <texture> <L> <T> <R> <B>
Exits non-zero on failure — wire into any future skin swap.
"""
import sys

import numpy as np
from PIL import Image


def main() -> int:
    path, L, T, R, B = sys.argv[1], *map(int, sys.argv[2:6])
    im = Image.open(path).convert("RGB")
    a = np.asarray(im).astype(float)
    h, w, _ = a.shape

    center = a[T:h - B, L:w - R]
    std = center.std(axis=(0, 1)).max()
    ok_center = std < 18.0
    print(f"center region {center.shape[1]}x{center.shape[0]} "
          f"max channel std {std:.1f} -> {'OK' if ok_center else 'FAIL (art in center?)'}")

    sides = {"L": L, "T": T, "R": R, "B": B}
    mean = sum(sides.values()) / 4.0
    spread = max(abs(v - mean) / mean for v in sides.values())
    ok_sym = spread <= 0.15
    print(f"margins {sides} spread {spread*100:.0f}% -> "
          f"{'OK' if ok_sym else 'FAIL (asymmetric border)'}")

    return 0 if (ok_center and ok_sym) else 1


if __name__ == "__main__":
    sys.exit(main())
