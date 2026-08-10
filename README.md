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
