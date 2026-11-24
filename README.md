# MathWorld Mobile

Flutter student application for MathWorld. The app uses Arabic (RTL) and English (LTR), Riverpod, Dio, Flutter Secure Storage, and Math/LaTeX rendering. The ASP.NET backend is the authority for account roles, problem access, progress, and Premium entitlements.

## Project layout

- `lib/screens/` — student flows (auth, stages, home, problems, favorites, error notebook, reports and settings)
- `lib/providers/`, `lib/repositories/`, `lib/services/` — app state, API calls and session management
- `assets/translations/` and `assets/branding/` — localization and approved branding
- `test/` — Flutter tests
- `.env.example` — versioned configuration example; local `.env` is intentionally ignored and must be created for local builds

## Setup (from this repository; do not replace folders manually)

Requires Flutter/Dart versions compatible with `pubspec.yaml` and an approved MathWorld API for the environment being tested.

```sh
git clone https://github.com/MahmoudWebApp/mathworld-mobile.git
cd mathworld-mobile
cp .env.example .env
flutter pub get
flutter analyze
flutter test
flutter run
```

On PowerShell, use `Copy-Item .env.example .env` instead of `cp`.

Configure the local `API_BASE_URL` to the **intended authorized backend** before running. The versioned `.env.example` may contain a live URL; never interpret it as authorization to submit test answers, change subscription settings, or publish content on production. Use a separately verified test API/database for write testing. Do not commit any `.env` overrides or put JWT signing keys, SMTP/provider secrets, Google OAuth client secrets or database credentials in Flutter assets.

## Architecture and API contracts

- Riverpod providers orchestrate screen state and repository/API communication.
- Dio handles requests; session tokens are stored using secure storage.
- Server-owned progress, favorites, Premium entitlements and correct answers must not be inferred or fabricated in the UI.
- The current `main` branch is an **implementation snapshot**, not proof that every planned flow is finished. In particular, the current product specification requires wrong-answer retries, full solutions only after correct answers, and Premium-only progressive hints. Review the backend/Flutter implementation together before release; do not assume an older one-attempt flow or solution-preview flow is the intended contract.
- For current feature requirements and tracked gaps, see the [active MathWorld execution plan](https://github.com/MahmoudWebApp/MathWordBackEnd/issues/17).

## Android CI and release safety

Review [GitHub Actions](https://github.com/MahmoudWebApp/mathworld-mobile/actions) for Flutter analyze/test results and Android build artifacts. A successful Android CI run proves that the configured build completed; it does **not** prove that the APK is release-signed for distribution, that Google login works on a specific device, or that the latest UX matches the approved screenshots.

Validate the installed build on a device (including launcher icon, Google sign-in, Arabic/English, dark/light, Premium access, and problem navigation). A production release also requires controlled signing, API compatibility and real-device acceptance checks. Avoid using a production-connected test APK for destructive or write-based QA.

## Safe-change rule

Keep this repository's single official student app. Do not alter live credentials, production users, subscriptions, problem content or app signing while doing read-only QA and cleanup. Make reviewed incremental changes, run CI, and track deployment evidence separately from Git commits.
