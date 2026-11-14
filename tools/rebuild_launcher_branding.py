#!/usr/bin/env python3
"""Rebuild iOS and Flutter Web app icons from the approved TRANSPARENT mark.

No generative redraw or matte stripping: the mathematical symbol is taken
unchanged from assets/branding/mathworld-mark.png, composited onto an opaque
light MathWorld lavender/pink background for platforms requiring one.
"""
from __future__ import annotations

import json
import math
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/branding/mathworld-mark.png"
IOS = ROOT / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
WEB = ROOT / "web"
SCALE = 1024

def source_mark() -> Image.Image:
    image = Image.open(SOURCE).convert("RGBA")
    a = image.getchannel("A")
    lo, hi = a.getextrema()
    if lo != 0 or hi != 255:
        raise ValueError(
            "The approved logo MUST have transparent pixels and opaque symbol. "
            "Refusing to bake in an unknown old/black matte."
        )
    bbox = a.getbbox()
    if bbox is None:
        raise ValueError("Approved logo image is empty")
    mark = image.crop(bbox)
    if mark.width < 20 or mark.height < 20:
        raise ValueError("Approved logo is too small")
    return mark

def backdrop(size: int) -> Image.Image:
    """Pastel branded background: never a black or fake transparent square."""
    # Top-left lavender through pale pink, the same brand's light surfaces.
    top=(248,244,255)
    bottom=(255,234,247)
    image=Image.new("RGB",(size,size))
    pixel=image.load()
    for y in range(size):
        for x in range(size):
            t=(x+y)/(2*max(1,size-1))
            pixel[x,y]=tuple(round((1-t)*top[k]+t*bottom[k]) for k in range(3))
    return image

def master(mark: Image.Image, fraction: float) -> Image.Image:
    square=backdrop(SCALE).convert("RGBA")
    max_size=round(SCALE*fraction)
    ratio=min(max_size/mark.width,max_size/mark.height)
    dim=(max(1,round(mark.width*ratio)),max(1,round(mark.height*ratio)))
    layer=mark.resize(dim,Image.Resampling.LANCZOS)
    left=(SCALE-dim[0])//2
    top=(SCALE-dim[1])//2
    square.alpha_composite(layer,(left,top))
    return square.convert("RGB")

def save(image: Image.Image,path:Path,px:int):
    path.parent.mkdir(parents=True,exist_ok=True)
    img=image.resize((px,px),Image.Resampling.LANCZOS)
    img.save(path,"PNG",optimize=True)
    print(f"BRAND_ICON_GENERATED|{path.relative_to(ROOT)}|{px}x{px}",flush=True)

def main():
    mark=source_mark()
    regular=master(mark,0.72)
    maskable=master(mark,0.56)
    manifest=json.loads((IOS/"Contents.json").read_text(encoding="utf-8"))
    items=manifest.get("images",[])
    emitted=set()
    for entry in items:
        name=entry.get("filename")
        if not name:
            continue
        size=float(entry["size"].split("x")[0])
        scale=int(entry["scale"].removesuffix("x"))
        px=round(size*scale)
        if px<1 or px>2048:
            raise ValueError(f"Bad iOS icon size {px}")
        save(regular,IOS/name,px)
        emitted.add(name)
    # Keep legacy iOS PNG assets synchronized with the same approved artwork.
    for existing in IOS.glob("Icon-App-*.png"):
        if existing.name not in emitted:
            px=Image.open(existing).width
            save(regular,existing,px)
    save(regular,WEB/"favicon.png",64)
    save(regular,WEB/"icons/Icon-192.png",192)
    save(regular,WEB/"icons/Icon-512.png",512)
    save(maskable,WEB/"icons/Icon-maskable-192.png",192)
    save(maskable,WEB/"icons/Icon-maskable-512.png",512)
    # Verify no opaque black corner survives, and iOS icons have no alpha.
    for path in [IOS/"Icon-App-1024x1024@1x.png",WEB/"icons/Icon-512.png"]:
        img=Image.open(path).convert("RGB")
        corners=[img.getpixel((0,0)),img.getpixel((img.width-1,0))]
        if any(max(p)<60 for p in corners):
            raise AssertionError(f"Black corner still present: {path}")
    print("PASS: rebuilt opaque brand icons from unchanged transparent MathWorld geometry")

if __name__=="__main__":
    main()
