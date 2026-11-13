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

Read docs/AUTHENTICATION_MAPPING.md for verified contracts and implementation limitations.

## Android setup
The repository did not contain generated platform runners before this phase. With Flutter installed, run from the repository root:

    flutter create --platforms=android .
    flutter pub get
    flutter run --dart-define=API_BASE_URL=https://YOUR_BACKEND_HOST/api

Supply the actual backend API root. The API URL is not hardcoded.

## Checks
    flutter analyze
    flutter test

Live auth tests require a reachable backend and test accounts. Never commit credentials, OTPs or tokens.
