# MathWorld Android QA — install once, update from GitHub Actions

**Status:** Implemented on the development branch. A permanently updateable QA APK will appear only **after one-time GitHub Secrets setup** and a successful workflow run. The ordinary debug-signed APK is **not** guaranteed to update older APKs.

## Why the old test APK reports "App not installed"

The ordinary GitHub-hosted runner can generate a different Android debug signing key on each CI run. Android forbids installing an update for an existing app ID if its signing certificate does not match, even when both files are "test builds". The 30 MB GitHub artifact is a ZIP and the uncompressed APK can be 60+ MB; file size does not diagnose the install rejection.

Existing original app ID: `com.mathworld.mathworld_mobile`.

New opt-in permanently signed test app ID: `com.mathworld.mathworld_mobile.qa`, display name **MathWorld QA**. It can be installed beside the original app without removing it or touching its on-device data.

## One-time permanent QA signing key

**Create this key ONCE, outside the repository, and back it up encrypted.** The private key and passwords never belong in GitHub source, public artifacts, screenshots or chat.

On Windows, after installing a JDK with `keytool`:

```powershell
keytool -genkeypair -v -keystore mathworld-qa.jks -storetype PKCS12 -alias mathworld-qa -keyalg RSA -keysize 3072 -validity 3650
```

Enter a strong password when prompted, and save the keystore in an encrypted safe location. The signing key's owner should retain a private copy independent of GitHub.

Go to GitHub: **mathworld-mobile → Settings → Secrets and variables → Actions → Repository secrets**. Create **four** repository secrets (not regular variables):

| Secret name | Value |
| --- | --- |
| `MATHWORLD_QA_KEYSTORE_BASE64` | Base64 of the entire binary `mathworld-qa.jks` file |
| `MATHWORLD_QA_STORE_PASSWORD` | Keystore password |
| `MATHWORLD_QA_KEY_ALIAS` | `mathworld-qa` |
| `MATHWORLD_QA_KEY_PASSWORD` | Key password (often same as store password for PKCS12) |

Convert the file to Base64 locally without uploading the key elsewhere:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes((Resolve-Path ".\mathworld-qa.jks"))) | Set-Clipboard
```

Paste clipboard text directly into the `MATHWORLD_QA_KEYSTORE_BASE64` secret. Avoid putting key/password contents into commit history.

## Every future build, automatically

GitHub Actions workflow: [Flutter Free-access tests and debug-signed Android QA APK](../.github/workflows/stage-daily-quota-mobile-ci.yml).

On a feature branch PR run touching `lib/**`, `android/**`, or the workflow, CI does the existing tests and then:

1. Creates the ordinary legacy debug-signed APK artifact (visual inspection only, **not reliably updateable**).
2. If all four repository secrets exist, restores the exact same QA keystore from GitHub Secrets.
3. Builds **MathWorld QA** with `MATHWORLD_ISOLATED_QA_APK=true` and `--build-number=${{ github.run_number }}` (strictly increasing within this workflow).
4. Uploads artifact **`mathworld-qa-updateable-stable-signing`** for manual download.

Download the QA artifact ZIP, unzip, and install `app-release.apk`. For the first QA installation, this is a **different** app from the previous MathWorld package; thereafter, install later **QA** APKs directly over it. No manual version edits, app uninstalls or signing key changes.

If the four secrets are absent, the permanent QA artifact is intentionally **not published**; GitHub's green result for the legacy build does not imply signing compatibility.

### Important notes

- A package **cannot update an old APK that used an unknown/different signing certificate**. The first switch to the new `.qa` package is a one-time new install. New and old can coexist.
- A lost QA keystore breaks update continuity. Back it up and **do not rotate** without planning.
- `MathWorld QA` currently uses the example API URL `https://mathwordbackend.onrender.com/api`; do not create/modify live student data in this visual-test build. Use a dedicated staging backend/database for interactive tests.
- Google OAuth requires a **separate Android OAuth package registration** for `com.mathworld.mathworld_mobile.qa`, using the SHA-1 fingerprint of this QA signing key. By default, Google login stays OFF.
- These artifacts are **QA-only**, not Play Store releases. Real production signing remains separate.
