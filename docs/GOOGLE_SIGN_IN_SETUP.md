# MathWorld Google sign-in — one website, one Android app (development)

## Project decision

There is **one** MathWorld website (`math-world-frontend.vercel.app`) and **one** Flutter Android app (`com.mathworld.mathworld_mobile`). The existing Render backend and Supabase database are shared. Everything is currently development/testing. Do **not** create a second .qa package, a second Vercel project, or another backend.

The Android Google OAuth entry called "MathWorld Android QA" with package `com.mathworld.mathworld_mobile.qa` is NOT used by the single-app build. In the SAME existing Google Cloud project, register an Android OAuth client with:

- Package name: `com.mathworld.mathworld_mobile`
- SHA-1: `8B:E7:F7:DB:00:1B:97:16:8E:E4:7D:3B:56:B6:C0:32:07:51:52:36` **only if** this fingerprint comes from the actual `android/app/mathworld-qa.jks` that will sign APKs. If different, determine and register the genuine signing certificate fingerprint first.
- **Never** put the Android OAuth client ID in Flutter's `serverClientId`. Use the existing "MathWorld Web" OAuth client ID instead.

Existing site Google login must continue to use the existing authorized JavaScript origin `https://math-world-frontend.vercel.app`. Backend Google ID-token audience (`Google__ClientId`) must match the SAME Web OAuth client ID.

## Stable local signing key

Keep a safe backup of the `android/app/mathworld-qa.jks` created on Windows. **Do not generate a new key if you already have one.** This is a developer/test signing key reused for the **same, original** Android package name.

Inspect its SHA-1 from the Flutter project root with PowerShell:

```powershell
keytool -list -v -keystore android/app/mathworld-qa.jks -alias mathworldqa
```

If no key exists yet, create one locally using Java `keytool`:

```powershell
keytool -genkeypair -v -keystore android/app/mathworld-qa.jks -storetype PKCS12 -keyalg RSA -keysize 3072 -validity 10000 -alias mathworldqa
```

Store the keystore and its passwords securely off-repository. Git ignores `android/app/*.jks`. A different signing certificate cannot install as an update to an existing APK with the same package name: uninstall the old debug-signed app before the **first** stable-signed test install (this removes local app data; backend user data is separate). Keep this signing key stable for subsequent test updates.

## GitHub Actions — setup (owner action)

Go to `https://github.com/MahmoudWebApp/mathworld-mobile/settings/secrets/actions`. Configure the following **repository secrets** (do not paste them in PRs, logs or chat):

| Secret name | Value |
|---|---|
| `MATHWORLD_QA_KEYSTORE_BASE64` | Base64 bytes of the existing `mathworld-qa.jks` file |
| `MATHWORLD_QA_STORE_PASSWORD` | Local keystore password |
| `MATHWORLD_QA_KEY_ALIAS` | Usually `mathworldqa` |
| `MATHWORLD_QA_KEY_PASSWORD` | Private key password |

PowerShell command to copy the key as Base64 (without printing it):

```powershell
[Convert]::ToBase64String(
  [IO.File]::ReadAllBytes((Resolve-Path 'android/app/mathworld-qa.jks').Path)
) | Set-Clipboard
```

Create a **repository variable**, NOT another secret:

| Variable name | Value |
|---|---|
| `MATHWORLD_GOOGLE_WEB_CLIENT_ID` | The existing **MathWorld Web** OAuth client ID from Google Cloud (ends in `.apps.googleusercontent.com`) |

Do not put the Android client ID here. This is a public client identifier; do not share client *secrets*.

After the GitHub workflow in `main` is available: **Actions → MathWorld Android (one app, Google sign-in) → Run workflow → Branch: main**. It runs Flutter checks first, then builds `app-release.apk` with:

- `MATHWORLD_STABLE_DEV_SIGNING=true`: stable developer keystore; **no .qa suffix**
- `MATHWORLD_SOCIAL_LOGIN_ENABLED=true`
- `MATHWORLD_GOOGLE_SERVER_CLIENT_ID`: the existing MathWorld Web ID

The action refuses to create an APK if required secrets/variable are missing, or if signing SHA-1 differs from the registered development certificate. GitHub Actions signing secrets are **not used by pull requests**. Download the artifact named `mathworld-android-google-login`. This is an Android device-test APK, **not** a Play Store production release.

## Local Windows APK (same package and key)

From the Flutter project root, with `.env` containing the existing non-secret API base URL:

```powershell
$env:MATHWORLD_STABLE_DEV_SIGNING = 'true'
$env:MATHWORLD_QA_KEYSTORE_FILE = 'mathworld-qa.jks'
$env:MATHWORLD_QA_KEY_ALIAS = 'mathworldqa'
$pass = Read-Host 'Developer keystore password' -AsSecureString
$plain = [System.Net.NetworkCredential]::new('', $pass).Password
$env:MATHWORLD_QA_STORE_PASSWORD = $plain
$env:MATHWORLD_QA_KEY_PASSWORD = $plain

$env:GOOGLE_WEB_CLIENT_ID = 'PASTE_YOUR_EXISTING_MATHWORLD_WEB_OAUTH_CLIENT_ID'
flutter pub get
flutter build apk --release `
  --dart-define=MATHWORLD_SOCIAL_LOGIN_ENABLED=true `
  "--dart-define=MATHWORLD_GOOGLE_SERVER_CLIENT_ID=$env:GOOGLE_WEB_CLIENT_ID"
```

Use the same keystore file for Windows and GitHub Actions. Passwords may differ between the keystore and private key; when they do, supply each value independently.

## Manual Android acceptance — required before calling Google login done

1. Install the signed MathWorld APK with the *original* package `com.mathworld.mathworld_mobile`; confirm there is only one MathWorld app on the phone.
2. Confirm the "Continue with Google" button is present on login/registration; the default unconfigured developer build intentionally hides it.
3. Sign in with a new Google account → app receives MathWorld JWT → user selects educational stage → opens an allowed Free category.
4. Sign out and sign in again with the same account; prior student stage and progress must persist.
5. Password-account linking is explicit in Settings; do not auto-merge users by email.
6. Cancel Google chooser, retry, test a second account, no-network behavior and cache isolation.
7. Confirm backend `Google__ClientId` accepts the same Web audience and Google Cloud Audience allows the test user.

OAuth account/project will be changed for the public launch later; no production credentials, release signing or iOS setup is implied by this development workflow.
