# MathWorld — mobile Google/Facebook sign-in rollout

**Status: Google native integration is implemented but opt-in/disabled by
default. Facebook native login is not activated yet.** Do not ship a build with
placeholder OAuth provider credentials.

## Why backend configuration comes first

Backend [MathWordBackEnd PR #5](https://github.com/MahmoudWebApp/MathWordBackEnd/pull/5)
must be merged and deployed first. It removes insecure matching-by-email
provider linking and adds authenticated account-linking endpoints.

For existing MathWorld users (including email/password students), always sign
in to the existing account and **link** Google/Facebook from settings; never
assume the same email automatically grants ownership of that account.

## Google Developer setup

1. Create the Google Cloud project, OAuth consent screen, and Web OAuth client.
2. Use that **Web client ID** for the ASP.NET backend environment variable
   `Google__ClientId` and the mobile `MATHWORLD_GOOGLE_SERVER_CLIENT_ID`
   build value. The Google plugin sends the corresponding ID token, which the
   backend verifies (issuer, signature, expiry and audience).
3. Register a separate Android OAuth client with the final Android package
   name and each debug/release signing SHA-1 certificate fingerprint. Android
   production signing is currently under preparation; do not assume the
   debug-signed release APK matches Google Play's eventual app-signing key.
4. Register a separate iOS OAuth client and configure required URL types and
   callback schemes in Xcode's Runner Info.plist. The optional
   `MATHWORLD_GOOGLE_IOS_CLIENT_ID` build value is for the iOS OAuth client.
5. Verify the OAuth consent publishing status/test-user access. Google developer
   accounts can be replaced with project-owned accounts later via provider
   project ownership/transfer configuration rather than changing MathWorld IDs.

Feature flag (default disabled):
```bash
flutter build apk --release \
  --dart-define=MATHWORLD_SOCIAL_LOGIN_ENABLED=true \
  --dart-define=MATHWORLD_GOOGLE_SERVER_CLIENT_ID=YOUR_WEB_CLIENT_ID
```

The previous APK remains unaffected until the new code is merged and built.
Never put a Google client secret or a Facebook App Secret into Flutter.

## Facebook/Meta native setup (planned, NOT enabled here)

1. Create a Meta developer app for the MathWorld product.
2. Configure Facebook Login for Android and iOS and define the real App ID,
   Client Token, Android package name, app signing key hashes, iOS bundle ID,
   Info.plist settings and URL schemes. On iOS choose a supported classic/
   limited-login token model; the current backend accepts Facebook Graph
   access tokens, **not** limited-login JWT ID tokens.
3. App Secret is **server-only** (`Facebook__AppSecret`), together with
   `Facebook__AppId`. Do not commit these to repository files.
4. Test with Meta app test roles while in Development Mode.
5. Only add the native Facebook SDK dependency, platform declarations and
   visible login/link actions after the platform identifiers are available.
   The official Flutter plugin can fail during Android initialization when
   native Meta credentials are missing. Never add placeholder App IDs just
   to pass compilation.
6. Confirm App Store review requirements for third-party login, especially
   Sign in with Apple policies.

## Safety acceptance checks

- Email/password login unchanged when social flag is disabled.
- Valid Google ID token creates a new account and routes student through stage
  choice; later Google sign-in restores the **same** MathWorld user.
- A verified Google identity whose email matches an unlinked existing MathWorld
  account gets HTTP 409, not an implicit account takeover.
- After email/password login, linking the matching Google identity keeps
  original UserId, solved questions, stage, points and subscriptions.
- Attempting to link a provider identity to a different MathWorld account is
  denied. Provider IDs must never be silently replaced.
- Invalid/expired provider tokens are refused; the backend does not store
  social access tokens.
- Google client uses a *server* OAuth client audience matching backend.
- Test Android debug and release signing separately; test iOS on a signed
  device after callback configuration.
- Do not activate public Facebook login until token type, native credentials
  and end-to-end QA are verified.

## Release order

1. Verify backend PR #5 with .NET CI and apply it before any client feature
   is enabled.
2. Deploy the gated web PR #5 with `NEXT_PUBLIC_SOCIAL_LOGIN_ENABLED=false`.
3. Merge this Flutter PR only after analyzer/build and Android device QA;
   the default release still hides social buttons.
4. Set up Google Cloud/Meta accounts and then enable one platform at a time.
5. Add Facebook Android/iOS integration once real App ID and Client Token
   are supplied, without exposing the server secret.
