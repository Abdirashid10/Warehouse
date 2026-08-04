# Logistics WMS Mobile — Android Release Checklist

## Pre-build

- [ ] Set production API URL: `flutter build apk --dart-define=API_BASE_URL=https://your-server/api --dart-define=PRODUCTION=true`
- [ ] Update `version` in `pubspec.yaml` (name + build number)
- [ ] Configure release signing in `android/app/build.gradle.kts` (replace debug signing)
- [ ] Store keystore credentials securely (never commit keystore)
- [ ] Verify `applicationId` in `android/app/build.gradle.kts` matches your organization

## Quality gates

- [ ] `flutter analyze` — zero issues
- [ ] `flutter test` — all passing
- [ ] Manual smoke test: Login → Dashboard → Inventory → Orders → Reports → Profile
- [ ] Test offline banner and cached data display
- [ ] Test light / dark / system theme switching
- [ ] Test session expiry (401) shows clear message and returns to login

## Build commands

```bash
# Debug APK
flutter build apk --debug

# Release APK (unsigned until signing configured)
flutter build apk --release --dart-define=PRODUCTION=true

# App bundle for Play Store
flutter build appbundle --release --dart-define=PRODUCTION=true
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

## Play Store assets

- [ ] App icon 512×512
- [ ] Feature graphic 1024×500
- [ ] Screenshots (phone + tablet if applicable)
- [ ] Privacy policy URL
- [ ] Short & full description

## Security

- [ ] Tokens stored in `flutter_secure_storage` only
- [ ] No API keys in source control
- [ ] HTTPS-only API base URL in production
- [ ] ProGuard/R8 rules if enabling minification

## Post-release

- [ ] Monitor crash reports
- [ ] Verify backend rate limits and auth refresh behavior
- [ ] Document supported Android min SDK for warehouse devices
