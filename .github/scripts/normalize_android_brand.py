#!/usr/bin/env python3
"""One-time, loss-minimizing MathWorld icon cleanup on the SOURCE brand artwork.

The approved source remains authoritative: no AI redrawing or symbol changes.
Flood-fills only a contiguous near-black matte touching the bitmap edges.
Generates transparent in-app PNG and launcher/adaptive assets from that source.
Run on a disposable branch; review generated PNGs before merging.
Rebuilt after detection of residual opaque neutral-black pixels.
"""
from __future__ import annotations

from collections import deque
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "assets/branding/mathworld-mark.png"
RES = ROOT / "android/app/src/main/res"
PURPLE = (109, 40, 217, 255)


def remove_connected_black_matte(original: Image.Image) -> Image.Image:
    image = original.convert("RGBA")
    width, height = image.size
    pixels = image.load()

    def near_black(x: int, y: int) -> bool:
        r, g, b, a = pixels[x, y]
        return a > 0 and max(r, g, b) < 52

    # Only pixels connected to an image border may be removed.
    visited = bytearray(width * height)
    queue: deque[tuple[int, int]] = deque()

    def add(x: int, y: int) -> None:
        index = y * width + x
        if visited[index] or not near_black(x, y):
            return
        visited[index] = 1
        queue.append((x, y))

    for x in range(width):
        add(x, 0)
        add(x, height - 1)
    for y in range(height):
        add(0, y)
        add(width - 1, y)

    removed = 0
    while queue:
        x, y = queue.popleft()
        removed += 1
        if x: add(x - 1, y)
        if x < width - 1: add(x + 1, y)
        if y: add(x, y - 1)
        if y < height - 1: add(x, y + 1)

    # Avoid changing source if the edge is not a black matte.
    border_count = 2 * width + 2 * height - 4
    border_black = sum(near_black(x, 0) or near_black(x, height - 1)
                       for x in range(width)) + sum(
        near_black(0, y) or near_black(width - 1, y)
        for y in range(1, height - 1))
    if border_black / max(border_count, 1) < 0.65:
        print("No near-black outer matte detected; original image retained.")
        return image

    if removed > width * height * 0.95:
        raise RuntimeError("Refusing to erase almost all approved logo pixels")
    for y in range(height):
        for x in range(width):
            if visited[y * width + x]:
                r, g, b, _ = pixels[x, y]
                pixels[x, y] = (r, g, b, 0)

    # The approved PNG contains an opaque dark rectangle behind its colored
    # emblem in addition to edge-connected black. Remove near-neutral dark
    # matte remnants anywhere (including disconnected islands), while keeping
    # saturated purple/violet interior pixels and white/math symbols intact.
    # This is a pixel cleanup, not a redraw of the brand artwork.
    neutral_matte_removed = 0
    for y in range(height):
        for x in range(width):
            r, g, b, alpha = pixels[x, y]
            if alpha and max(r, g, b) < 92 and max(r, g, b) - min(r, g, b) < 38:
                pixels[x, y] = (r, g, b, 0)
                neutral_matte_removed += 1
    print("Removed neutral dark square remnants:", neutral_matte_removed)

    bounds = image.getbbox()
    if not bounds:
        raise RuntimeError("No visible logo remained after matte cleanup")
    print(f"Removed {removed} edge-connected black pixels; logo bbox: {bounds}")
    return image.crop(bounds)


def fit(image: Image.Image, size: int) -> Image.Image:
    thumb = image.copy()
    thumb.thumbnail((size, size), Image.Resampling.LANCZOS)
    return thumb


def generate() -> None:
    if not SOURCE.is_file():
        raise FileNotFoundError(SOURCE)
    original = Image.open(SOURCE)
    print("MathWorld logo source:", original.size, original.mode)
    cleaned = remove_connected_black_matte(original)
    cleaned.save(SOURCE, format="PNG", optimize=True)

    # Android adaptive icon foreground: keep the entire MathWorld artwork
    # inside the central safe area so circular/squircle masks don't cut it.
    size = 432
    foreground = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    mark = fit(cleaned, 280)
    foreground.alpha_composite(
        mark, ((size - mark.width) // 2, (size - mark.height) // 2)
    )
    adaptive_path = RES / "drawable-nodpi/mathworld_adaptive_foreground.png"
    adaptive_path.parent.mkdir(parents=True, exist_ok=True)
    foreground.save(adaptive_path, optimize=True)

    # Legacy icons use Android-like rounded-square silhouettes, rather than
    # an extra black box around the inner brand mark.
    sizes = {
        "mdpi": 48, "hdpi": 72, "xhdpi": 96,
        "xxhdpi": 144, "xxxhdpi": 192,
    }
    for density, extent in sizes.items():
        canvas = Image.new("RGBA", (extent, extent), (0, 0, 0, 0))
        art = Image.new("RGBA", (extent, extent), PURPLE)
        mask = Image.new("L", (extent, extent), 0)
        draw = ImageDraw.Draw(mask)
        draw.rounded_rectangle((0, 0, extent - 1, extent - 1),
                               radius=round(extent * .22), fill=255)
        art.putalpha(mask)
        canvas.alpha_composite(art)
        logo = fit(cleaned, round(extent * .86))
        canvas.alpha_composite(
            logo, ((extent - logo.width) // 2, (extent - logo.height) // 2)
        )
        out = RES / f"mipmap-{density}/ic_launcher.png"
        out.parent.mkdir(parents=True, exist_ok=True)
        canvas.save(out, format="PNG", optimize=True)
    # Self-test on the images the Android build actually packages.
    for path in [SOURCE, adaptive_path, RES / "mipmap-xxxhdpi/ic_launcher.png"]:
        result = Image.open(path).convert("RGBA")
        if result.getbbox() is None:
            raise RuntimeError(f"Empty output: {path}")
        print(path.relative_to(ROOT), result.size,
              "corner-alpha", result.getpixel((0, 0))[3])


if __name__ == "__main__":
    generate()
