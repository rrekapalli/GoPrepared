# OAuth setup — Google and Microsoft

GoPrepared uses **ID token exchange**: the Flutter app signs in with Google or Microsoft, sends the provider ID token to the API, and receives a GoPrepared JWT.

Configure both the **API** (`.env` at repo root) and the **Flutter app** (`--dart-define` or native config).

## Environment variables

| Variable | Where | Purpose |
|----------|-------|---------|
| `GOOGLE_CLIENT_ID` | API + Flutter | Google **Web** client ID (used to verify ID tokens) |
| `MICROSOFT_CLIENT_ID` | API + Flutter | Entra app (client) ID |
| `MICROSOFT_TENANT_ID` | API + Flutter | `common` for work + personal Microsoft accounts |
| `GOPREPARED_AUTH_DEV_ENABLED` | API only | Set `false` in production to disable `POST /auth/dev` |

Flutter run example:

```powershell
cd go-prepared-app
flutter run -d chrome `
  --dart-define=GOOGLE_CLIENT_ID=YOUR_WEB_CLIENT_ID.apps.googleusercontent.com `
  --dart-define=MICROSOFT_CLIENT_ID=YOUR_ENTRA_CLIENT_ID `
  --dart-define=MICROSOFT_TENANT_ID=common
```

Copy [`.env.example`](../.env.example) to `.env` for the API.

---

## Google Cloud Console

1. Create a project (or use an existing one).
2. **APIs & Services → OAuth consent screen** — configure app name, support email, scopes (`email`, `profile`, `openid`).
3. **Credentials → Create OAuth client ID** for each platform:

### Web (primary for API verification)

- Type: **Web application**
- Authorized JavaScript origins: `http://localhost:<flutter-port>`, production PWA URL (e.g. `https://goprepared.example.com`)
- Authorized redirect URIs: same origins (Google Sign-In for web)
- Copy **Client ID** → `GOOGLE_CLIENT_ID` in `.env` and Flutter `--dart-define`

Optional: set the same ID in [`go-prepared-app/web/index.html`](../go-prepared-app/web/index.html) meta tag `google-signin-client_id`.

### Android

- Type: **Android**
- Package name: `com.goprepared.go_prepared_app`
- SHA-1: from debug keystore (`keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android`)
- Use the **Web client ID** as `serverClientId` in Flutter (already wired when `GOOGLE_CLIENT_ID` is set).

### iOS

- Type: **iOS**
- Bundle ID: `com.goprepared.goPreparedApp`
- Add reversed client ID URL scheme to `Info.plist` if using Google Sign-In native flow (optional when `serverClientId` is set in Dart).

---

## Microsoft Entra (Azure) app registration

1. [Azure Portal](https://portal.azure.com) → **Microsoft Entra ID** → **App registrations** → **New registration**.
2. Name: `GoPrepared`
3. Supported account types: **Accounts in any organizational directory and personal Microsoft accounts**
4. Redirect URIs — add **all** platforms you ship:

| Platform | Redirect URI |
|----------|----------------|
| Web (SPA) | `http://localhost:<port>/` (Flutter web dev) |
| Web (SPA) | Production PWA origin, e.g. `https://goprepared.example.com/` |
| Mobile/desktop | `msauth://com.goprepared.go_prepared_app/callback` (Android) |
| Mobile/desktop | `msauth.com.goprepared.goPreparedApp://auth` (iOS) |

5. **Authentication** → enable **ID tokens** (implicit / hybrid not required; aad_oauth uses authorization code).
6. **API permissions** → Microsoft Graph → delegated: `openid`, `profile`, `email`, `User.Read`.
7. Copy **Application (client) ID** → `MICROSOFT_CLIENT_ID`.

Set `MICROSOFT_TENANT_ID=common` unless you restrict to a single tenant.

---

## Native project wiring (already in repo)

- **Android:** [`AndroidManifest.xml`](../go-prepared-app/android/app/src/main/AndroidManifest.xml) — `msauth` intent filter for Microsoft callback.
- **iOS:** [`Info.plist`](../go-prepared-app/ios/Runner/Info.plist) — `CFBundleURLTypes` for `msauth.com.goprepared.goPreparedApp`.
- **Web:** [`index.html`](../go-prepared-app/web/index.html) — optional Google meta tag.

---

## Production deploy

In `.env` on the server:

```bash
GOPREPARED_AUTH_DEV_ENABLED=false
GOOGLE_CLIENT_ID=...
MICROSOFT_CLIENT_ID=...
MICROSOFT_TENANT_ID=common
```

Ensure `GOPREPARED_CORS_ORIGINS` includes your PWA origin.

Build Flutter with the same client IDs:

```powershell
flutter build web `
  --dart-define=GOOGLE_CLIENT_ID=... `
  --dart-define=MICROSOFT_CLIENT_ID=... `
  --dart-define=DEV_AUTH_ENABLED=false
```

---

## Verify

1. Start API: `cd go-prepared-api; .\mvnw.cmd spring-boot:run`
2. Run app with OAuth dart-defines.
3. Visit `/explore` without signing in — knowledge loads.
4. Visit `/home` — redirects to `/login`.
5. Sign in with Google (primary) or Microsoft (secondary).
6. Create a journey — API returns 200 with Bearer JWT.

## Troubleshooting

| Issue | Fix |
|-------|-----|
| Google `Invalid ID token` | Web client ID must match token audience; on mobile use Web client ID as `serverClientId` |
| Microsoft button disabled | Set `MICROSOFT_CLIENT_ID` in `--dart-define` |
| Microsoft redirect error | Redirect URI in Entra must exactly match [`AppConfig.oauthRedirectUri`](../go-prepared-app/lib/core/config/app_config.dart) for the platform |
| `503 Google OAuth is not configured` | Set `GOOGLE_CLIENT_ID` in API `.env` |
| Dev login fails in release | Expected — use OAuth or enable dev auth only in debug |
