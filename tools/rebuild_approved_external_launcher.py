#!/usr/bin/env python3
"""Generate ONLY Android launcher assets from the user-approved MathWorld icon.

The PNG/WebP launched by Android contains a single continuous cosmic surface
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
EXPECTED_SHA256 = "ab6e65e4817cbcfb7fb51496c0c3f993d5b0109fb986f9a800a29e11fb821057"
DENSITIES = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}


def read_approved_icon() -> Image.Image:
    encoded = SOURCE.read_text(encoding="ascii").strip()
    binary = base64.b64decode(encoded, validate=True)
    actual = hashlib.sha256(binary).hexdigest()
    if actual != EXPECTED_SHA256:
        raise ValueError("Approved external launcher artwork fingerprint changed")
    with Image.open(io.BytesIO(binary)) as original:
        if original.width != original.height or original.width < 256:
            raise ValueError("Approved icon must be square and at least 256 pixels")
        result = original.convert("RGB")
    # This artwork is a single, glossy violet/pink background, not a pasted
    # badge with a separate light-colored backing behind the original symbol.
    r, g, b = result.getpixel((result.width // 2, result.height // 2))
    if not (r < 210 and b > 100):
        raise ValueError("Unexpected icon color balance")
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
    webp = ANDROID / "drawable-nodpi/mathworld_external_launcher.webp"
    webp.parent.mkdir(parents=True, exist_ok=True)
    icon.resize((432, 432), Image.Resampling.LANCZOS).save(
        webp, "WEBP", quality=95, method=6
    )
    print(f"EXTERNAL_LAUNCHER|{webp.relative_to(ROOT)}|432")
    print("PASS: generated Android external launcher ONLY; internal MathWorld logo unchanged")


if __name__ == "__main__":
    main()
