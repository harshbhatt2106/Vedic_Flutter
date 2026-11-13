# VedicVivah Flutter

Flutter mobile client for the existing VedicVivah platform.

## Source revisions
- Backend: https://github.com/harshbhatt2106/vedicvivah-backend/tree/FainalBak
- Web frontend: https://github.com/harshbhatt2106/vedicvivah-frontend/tree/FainalFrontend
- Flutter target: https://github.com/harshbhatt2106/Vedic_Flutter/tree/flutter-development

## Authentication
- Premium login and registration.
- Email OTP verification and resend.
- Forgot-password email OTP and reset.
- JWT access/refresh session handling.
- Secure persistent storage when Remember Me is selected.
- Role-aware authenticated landing for Admin, User and Mentor.

Read docs/AUTHENTICATION_MAPPING.md for API contracts and implementation limitations.

## Android setup

The Android runner is committed in `android/`. Its application ID is `com.vedicvivah.app`, matching the existing VedicVivah Android application.

Run from the repository root:

    flutter pub get
    flutter doctor -v
    flutter run

The default API root is configured in `lib/core/config/app_config.dart`. To override it for local development:

    flutter run --dart-define=API_BASE_URL=http://<YOUR_PC_LAN_IP>:5113/api

Cleartext HTTP is allowed only in debug builds. Release builds must use HTTPS.

Build a debug APK:

    flutter build apk --debug

The GitHub Actions workflow also uploads a `vedicvivah-debug-apk` artifact after a successful build.

**Release limitation:** A Play Store AAB has not been built. Configure the existing app's release keystore/signing secrets and increment the version code before preparing a production release. The generated Android launcher icon is still the Flutter template icon; the approved VedicVivah logo/splash assets have not yet been migrated into this Flutter project.

## Checks

    flutter analyze --no-fatal-infos
    flutter test
    flutter build apk --debug

Live User Panel workflows still require a reachable backend, safe test accounts and physical-device testing. Never commit credentials, OTPs, tokens or signing keys.
