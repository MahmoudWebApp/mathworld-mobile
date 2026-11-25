#!/usr/bin/env python3
"""Generate ONLY Android launcher assets from the user-approved MathWorld icon.

The PNG launched by Android contains a single continuous cosmic surface
rather than a smaller hexagonal emblem on top of a second pale square.

Never writes assets/branding/mathworld-mark.png, in-app logo widget,
iOS icons, website favicons, splash screens, or Flutter UI assets.
"""
from __future__ import annotations

import base64
import hashlib
import io
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/branding/mathworld-approved-android-external.webp.b64"
ANDROID = ROOT / "android/app/src/main/res"
EXPECTED_SHA256 = "07589258bb3f0f19e06cc6fa3306414e6892a70da68a0e6ec57c92d58db01ae3"
DENSITIES = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}


def read_approved_icon() -> Image.Image:
    encoded = "".join(SOURCE.read_text(encoding="ascii").split())
    binary = base64.b64decode(encoded, validate=True)
    actual = hashlib.sha256(binary).hexdigest()
    if actual != EXPECTED_SHA256:
        raise ValueError("Approved external launcher artwork fingerprint changed")
    with Image.open(io.BytesIO(binary)) as original:
        if original.width != original.height or original.width < 192:
            raise ValueError("Approved icon must be square and at least 256 pixels")
        result = original.convert("RGB")
    # This artwork is a single, glossy violet/pink background, not a pasted
    # badge with a separate light-colored backing behind the original symbol.
    r, g, b = result.getpixel((result.width // 2, result.height // 2))
    if not (r < 210 and b > 100):
        raise ValueError("Unexpected icon color balance")
    # Retain the approved artwork and highlights; rebalance only chromatic pixels.
    pixels = result.load()
    for y in range(result.height):
        for x in range(result.width):
            rgb = pixels[x, y]
            r, g, b = (v / 255 for v in rgb)
            v, low = max(r, g, b), min(r, g, b)
            saturation = 1 - low / v if v else 0
            if saturation < .12 or v < .025:
                continue
            t = max(0., min(1., (x / result.width - .06 + .10 * (.5 - y / result.height)) / .88))
            t = t * t * (3 - 2 * t)
            hue = (255 + 73 * t) / 60
            chroma = v * saturation
            z = chroma * (1 - abs(hue % 2 - 1))
            m = v - chroma
            target = (z, 0, chroma) if hue < 5 else (chroma, 0, z)
            mix = min(1., (saturation - .12) / .24)
            pixels[x, y] = tuple(round(rgb[i] * (1 - mix) + 255 * (target[i] + m) * mix) for i in range(3))
    return result


def write_png(icon: Image.Image, path: Path, size: int) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    icon.resize((size, size), Image.Resampling.LANCZOS).save(
        path, "PNG", optimize=True
    )
    print(f"EXTERNAL_LAUNCHER|{path.relative_to(ROOT)}|{size}")


def main() -> None:
    icon = read_approved_icon()
    # Full-bleed artwork means Android itself applies the launcher mask.
    # An extra pastel layer or inner hexagonal panel must not be generated.
    for directory, size in DENSITIES.items():
        for name in ("ic_launcher.png", "ic_launcher_round.png"):
            write_png(icon, ANDROID / directory / name, size)
    write_png(icon, ANDROID / "drawable-nodpi/mathworld_adaptive_foreground.png", 432)
    write_png(icon, ANDROID / "drawable-nodpi/ic_launcher_foreground.png", 432)
    write_png(icon, ANDROID / "drawable-nodpi/mathworld_external_launcher.png", 432)
    print("PASS: generated Android external launcher ONLY; internal MathWorld logo unchanged")


if __name__ == "__main__":
    main()
