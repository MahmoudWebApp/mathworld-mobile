# MathWorld Mobile — Final Updated Flutter Package

MathWorld is a bilingual Flutter application for browsing and solving mathematical problems. It supports Arabic RTL and English LTR, rendered LaTeX, educational stages and categories, progress, favorites, solved problems, light and dark themes, and secure JWT authentication.

## Included files

```text
lib/
assets/translations/
android/app/src/main/AndroidManifest.xml
test/
pubspec.yaml
analysis_options.yaml
.env
.env.example
CURRENT_BACKEND_COMPATIBILITY.md
CHANGELOG.md
```

## Main architecture

- Riverpod state management.
- Repository layer between providers and network transport.
- Centralized Dio API client and API-envelope parsing.
- Typed application errors.
- JWT stored only in Flutter Secure Storage.
- Startup session validation through `/users/profile`.
- Automatic session clearing and login redirection after HTTP 401.
- Hive fallback cache for stages and categories.
- Arabic and English request headers.

## Current backend integration

- Unified search through `/problems/search`.
- MeiliSearch enabled by default through `SEARCH_ENGINE=meilisearch`.
- PostgreSQL can be selected through `SEARCH_ENGINE=postgresql`.
- Favorite updates send `ProblemId` and the requested `IsFavorite` value.
- Answer submission supports the one-attempt backend rule.
- Correct answer highlighting supports `CorrectOptionId` and `CorrectOptionText`.
- Authentication supports the current flat `AuthResponseDto` format.

## User experience improvements

- Responsive stages, categories, problem cards, and answer options.
- Reduced-motion-aware animations.
- Real glass blur.
- Localized relative dates.
- Safe LaTeX rendering fallback.
- External video solution launching.
- Correct and incorrect option highlighting after server validation.
- Light and dark themes.

## Installation

1. Back up the current Flutter project.
2. Replace the existing `lib` folder with the included `lib` folder.
3. Replace the Arabic and English translation files.
4. Merge the Android manifest permissions.
5. Replace or merge `pubspec.yaml`.
6. Copy `.env` and update `API_BASE_URL` when required.

Run:

```powershell
flutter clean
flutter pub get
dart format lib test
flutter analyze
flutter test
flutter run
```

## Environment

```env
API_BASE_URL=https://mathwordbackend.onrender.com/api
SEARCH_ENGINE=meilisearch
ENABLE_HTTP_LOGS=false
```

Never put JWT signing keys, database passwords, MeiliSearch administration keys, ImgBB keys, Google secrets, or Facebook secrets inside the Flutter application.

## Safe Android staging APK

For visual/launcher-only inspection, download the existing debug-signed Android artifact from [GitHub Actions](https://github.com/MahmoudWebApp/mathworld-mobile/actions/runs/43730687183) → **Artifacts**. **Warning:** that existing build bundles `.env.example` and points at the live Render API. Do not submit answers, register test students, redeem codes, edit admin records or otherwise perform write-flow QA using it.

For safe interactive QA against a dedicated non-production backend/database, use the new [Android staging QA workflow](.github/workflows/android-staging-qa-apk.yml). Set the GitHub Actions repository variable `MATHWORLD_STAGING_API_URL` to the isolated HTTPS API ending in `/api`; on a new feature-branch PR/push run, retrieve the `mathworld-staging-qa-apk-debug-signed` artifact. The workflow refuses known production hosts; the installed QA build displays a visible **QA** ribbon.

GitHub's `workflow_dispatch` for a *new* workflow is not available until its definition exists on the default branch. **Do not merge merely to activate it**: the feature-branch PR/push trigger can build the artifact once the repository variable is configured. A skipped QA workflow is **not** a build pass.

The staging APK remains debug-signed, not Play Store signed, and uses the existing Android application ID. Installing may replace an existing MathWorld installation. Google/Facebook native sign-in are disabled pending verified OAuth configuration.
