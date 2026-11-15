# MathWorld Flutter — Google Sign-In release checklist

**Status:** Flutter UI, Google token retrieval, app-session handling, backend
ID-token verification and account linking exist on feature branches.
**Google login is OFF by default**, not yet validated on a real Android/iOS
device, and must not be called production-ready. Payments are out of scope.

## 1. Google Cloud OAuth clients (owner action)

In a Google Cloud project, configure the OAuth consent screen and authorized
test users/publishing status as applicable. Create **three distinct OAuth
clients** when shipping on both platforms:

- **Web application** client ID (this is the **server audience ID**, not a
  client secret). The ASP.NET backend verifies Google ID tokens against this
  exact ID using `Google:ClientId`.
- **Android** client with package name
  `com.mathworld.mathworld_mobile` and SHA-1 certificate fingerprint.
  Register fingerprints for **debug**, **release/upload**, and **Google Play
  App Signing** certificates as appropriate. SHA-256 is useful for diagnostics.
  Obtain the correct fingerprint from the actual signing certificate, e.g.
  `keytool -list -v -keystore <path-to-keystore> -alias <alias>`.
  Never assume the CI debug key equals a developer's local key.
- **iOS** client with final iOS bundle ID; configure its reversed client-ID
  URL scheme in `ios/Runner/Info.plist` under `CFBundleURLTypes`. The
  iOS URL scheme is **not configured in this repository yet**; iOS must be
  tested only after that native change. Apple app review and alternate-sign-in
  requirements must be evaluated before publishing.

The Web/server client ID must be passed to the Flutter SDK as
`serverClientId` and configured as the **same value** in the backend
`Google:ClientId`. Do not substitute the Android client ID.

## 2. Configure without committing credentials

Backend service environment (Render/staging):

```
Google__ClientId=<WEB_APPLICATION_OAUTH_CLIENT_ID>
```

Android Flutter QA build (value is a public client identifier, not a secret):

```bash
flutter build apk --release \
  --dart-define=MATHWORLD_SOCIAL_LOGIN_ENABLED=true \
  --dart-define=MATHWORLD_GOOGLE_SERVER_CLIENT_ID=<WEB_APPLICATION_OAUTH_CLIENT_ID>
```

Flutter's `SocialAuthConfig.googleAvailable` shows the Google button only
on supported native builds with a plausible OAuth client ID. The default
`flutter build apk --release` **does not enable** Google login. For iOS
also supply `--dart-define=MATHWORLD_GOOGLE_IOS_CLIENT_ID=<IOS_OAUTH_CLIENT_ID>`
and configure the iOS native URL scheme before distributing test builds.

No Firebase dependency is required solely to use this plugin with explicit
OAuth IDs. Never bundle Google client **secrets** or service-account keys in
the mobile app. Keep provider tokens out of logs.

## 3. Verify on real devices (acceptance)

1. Install a QA build signed with the **same certificate registered** in
   Google Cloud. Check Google sign-in button appears only in enabled builds.
2. New Google account: sign in, backend issues MathWorld JWT, student selects
   learning stage, and can solve within the Free two-category policy.
3. Returning Google account: same MathWorld user ID, stage, answers and points.
4. Existing password account with same email: backend requires **explicit
   account linking**, never silently merges by email. Sign in by password,
   open Settings → Link Google, then retry Google login.
5. Cancel the Google account chooser: return to the login screen without
   showing an error or creating a session.
6. Sign out: local JWT and Google SDK state are cleared; the next learner on a
   shared device can select their own account.
7. Try disabled user, invalid token, revoked authorization, slow/no network
   and a different Google account. Verify no cross-account cached progress,
   badges or notifications.
8. Test **both debug and production signing** (their certificate fingerprints
   are different). Do a clean install and check the **external launcher logo**.
9. On iOS, confirm reversed URL scheme, ID-token audience, iPhone app lifecycle
   and any relevant App Store guidelines.

**Common Android error:** Credential Manager can sometimes report a
`canceled` error even after selecting an account if SHA, package name or
`serverClientId` is wrong. Check native OAuth configuration before assuming
a user intentionally dismissed it.

## 4. Release blockers

- Actual Google Cloud OAuth client IDs, Android SHA registrations and
  iOS URL-scheme configuration are **external/owner actions**.
- The deployed backend configuration and mobile build flags have not been
  inspected/changed by this feature-branch work.
- CI `flutter analyze` and Android APK compilation do **not** validate a
  Google authorization exchange.
- Do not merge, deploy, or mark Google login completed without signed-device
  acceptance and explicit approval.
