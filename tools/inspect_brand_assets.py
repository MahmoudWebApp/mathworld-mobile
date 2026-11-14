#!/usr/bin/env python3
"""Inspect exact artwork shipped in Flutter and both native app launchers.

Read-only by design. Images are never auto-recolored or cropped, because the
approved MathWorld cap/sigma/x² artwork must retain its geometry.
"""
from __future__ import annotations
import base64
import io
import json
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
ASSETS = {
    "flutter-mark": "assets/branding/mathworld-mark.png",
    "android-adaptive-foreground": "android/app/src/main/res/drawable-nodpi/mathworld_adaptive_foreground.png",
    "android-launcher-mdpi": "android/app/src/main/res/mipmap-mdpi/ic_launcher.png",
    "android-launcher-xxxhdpi": "android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png",
    "ios-app-icon-1024": "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png",
    "ios-native-launch-3x": "ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@3x.png",
    "flutter-web-icon-512": "web/icons/Icon-512.png",
    "flutter-web-maskable-512": "web/icons/Icon-maskable-512.png",
}

def summarize(label: str, path: Path) -> dict:
    with Image.open(path) as source:
        img = source.convert("RGBA")
        width, height = img.size
        corners = [img.getpixel(p) for p in [(0,0),(width-1,0),(0,height-1),(width-1,height-1)]]
        sample = img.resize((96,96), Image.Resampling.LANCZOS)
        buffer = io.BytesIO()
        sample.save(buffer, format="PNG", optimize=True)
        preview = base64.b64encode(buffer.getvalue()).decode("ascii")
        # These compact PNGs are previews in the CI log, not source artwork
        # or downloadable production assets.
        print(f"BRAND_PREVIEW|{label}|{preview}", flush=True)
        opaque_black_corners = sum(1 for r,g,b,a in corners if a >= 250 and max(r,g,b) < 42)
        alpha_bounds = img.getchannel("A").getbbox()
        return {
            "name":label, "path":str(path.relative_to(ROOT)), "width":width,
            "height":height, "sourceMode":source.mode,
            "alphaRange":list(img.getchannel("A").getextrema()),
            "cornerRgba":[list(p) for p in corners],
            "opaqueDarkCorners":opaque_black_corners,
            "hasTransparentCorner":any(a < 32 for _,_,_,a in corners),
            "alphaBounds":list(alpha_bounds) if alpha_bounds else None,
            "alphaExtentFraction": (
                round(max(alpha_bounds[2]-alpha_bounds[0],
                          alpha_bounds[3]-alpha_bounds[1])/max(width,height),3)
                if alpha_bounds else 0
            ),
        }

def main():
    results=[]
    missing=[]
    for name, relative in ASSETS.items():
        path=ROOT/relative
        if not path.is_file():
            missing.append(relative)
            continue
        results.append(summarize(name,path))
    print("BRAND_AUDIT_JSON|"+json.dumps({
        "assets":results, "missing":missing,
        "note":"Opaque/dark corners can indicate a baked-in background. "
               "Launcher apps require device QA; CI cannot approve visual identity."
    },ensure_ascii=False),flush=True)
    if missing:
        raise SystemExit("Missing external launcher/Flutter icon assets: "+", ".join(missing))
    for item in results:
        if item["name"] in ("flutter-mark", "android-adaptive-foreground", "ios-native-launch-3x"):
            if not item["hasTransparentCorner"]:
                raise SystemExit("Expected transparent approved mark: "+item["name"])
        if item["name"] in ("ios-app-icon-1024", "flutter-web-icon-512", "flutter-web-maskable-512"):
            if item["opaqueDarkCorners"] > 0 or item["hasTransparentCorner"]:
                raise SystemExit("Expected opaque lavender/pink (NOT black) icon corners: "+item["name"])
    native_launch=next(x for x in results if x["name"] == "ios-native-launch-3x")
    if (native_launch["width"],native_launch["height"]) != (504,555):
        raise SystemExit("Native iOS splash image must be 504x555 pixels at 3x")
    print("PASS: iOS/PWA icons have no black matte; iOS native splash and Flutter marks retain transparency")

if __name__=="__main__":
    main()
