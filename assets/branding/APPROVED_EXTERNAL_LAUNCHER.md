# MathWorld approved external Android launcher

**Approved artwork:** glossy balanced violet → pink rounded-square
icon featuring the graduation-cap stroke and `Σ x²`, **without** a separate
smaller hexagonal badge or pastel outer background.

- Approved launcher compressed source:
  `assets/branding/mathworld-approved-android-external.webp.b64`
- Source WebP SHA-256:
  `07589258bb3f0f19e06cc6fa3306414e6892a70da68a0e6ec57c92d58db01ae3`
- Exact deterministic generator:
  `python tools/rebuild_approved_external_launcher.py`
- Native Android launcher: all mipmap densities, adaptive foreground, legacy icon.
- Generated resources are committed with the branding change. The maintenance workflow regenerates only on explicit dispatch; regular CI audits the committed artwork. Use the signed APK built from the merged branding commit.

## Branding boundary — mandatory

**This approved image is only the EXTERNAL Android app launcher.**
The following remain unchanged:
- `assets/branding/mathworld-mark.png` and both brand SVGs.
- `lib/widgets/brand_logo.dart`, app navigation and Flutter splash.
- Website branding, iOS launcher and favicon.

Never replace the internal MathWorld brand mark with this rounded app icon.
Do not run a generic icon generator that paints a new, lighter square behind
the approved image or restores the previous internal cubical mark as the
external Android icon.

## Android release verification

After rebuilding, verify:
1. Launcher artwork shows a **single** continuous violet/pink field, split equally with a narrow transition.
2. `Σ x²` and graduation cap remain legible on installed launcher at 48–192px.
3. On Android 8+, adaptive launcher uses the approved artwork with the device mask.
4. In-app MathWorld mark matches the balanced web mark; the external rounded artwork retains its approved geometry.
5. Google sign-in still uses the established signing certificate; no QA package ID.

The compressed source is intentionally compact for reproducible GitHub Actions.
A separately retained 1024px master is appropriate for future app-store assets,
but should not be substituted for in-app branding.
