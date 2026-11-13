# Authentication Mapping — VedicVivah Flutter

## Verified source revisions

- Backend: harshbhatt2106/vedicvivah-backend, branch FainalBak.
- Web frontend: harshbhatt2106/vedicvivah-frontend, branch FainalFrontend.
- Flutter target: harshbhatt2106/Vedic_Flutter, branch flutter-development.
- Backend controller: VedicVivah/Controllers/AuthController.cs.
- Backend handlers: VedicVivah.Application/Users/Commands.
- Web auth service: src/features/auth/services/authService.ts.
- Web login form: src/components/auth/LoginForm/LoginForm.tsx.
- Web registration: src/pages/CreateAccount/CreateAccountPage.tsx.
- Web forgot password: src/pages/ForgotPassword/ForgotPasswordPage.tsx.
- Web session: src/features/auth/session.ts.
- Backend startup/security: VedicVivah/Program.cs.

This document maps existing behavior only. Flutter does not add server-side fields or bypass backend validation.

## Existing web flows

### Login
1. User enters email or mobile number as identifier and password.
2. Web validates both values are non-empty.
3. Web calls POST /api/auth/login.
4. On success and a non-empty access token, the session is saved.
5. “Keep me signed in” selects localStorage; otherwise sessionStorage.
6. Exact role routing: Admin → /admin/dashboard; User → /dashboard; Mentor → /mentor/dashboard.

### Registration
1. One details step collects username, mobile, email and password.
2. Web validation:
   - Username: 3–30 characters; ASCII letters, digits, dot or underscore.
   - Mobile: exactly 10 digits.
   - Email: non-whitespace local/domain with a dot.
   - Password: minimum 8 characters.
3. Username is trimmed and lowercased; email is trimmed; mobile is digits only.
4. POST /api/auth/register body: userName, email, phoneNumber, password.
5. Backend returns data.registrationId; UI moves to six-digit email OTP.
6. POST /api/auth/verify-email verifies OTP; success activates account and web redirects to Login.
7. Web resend cooldown is 60 seconds, maximum three resends (four sends including initial).
8. No confirm-password field or terms checkbox exists in the web registration form or backend RegisterRequest. Mobile is collected, but verification is email OTP.

### Forgot password
1. Email → POST /api/auth/forgot-password → data.resetRequestId.
2. Six-digit OTP → POST /api/auth/verify-password-reset-otp.
3. New password → POST /api/auth/reset-password with resetRequestId and newPassword.
4. Web confirms password equality locally; backend requires at least eight characters and a verified reset request.

## Backend endpoint contracts

All paths are appended to the /api base. JSON properties use camelCase.

| Method | Path | Request JSON | Success response |
|---|---|---|---|
| POST | /auth/register | { userName, email, phoneNumber, password } | { success, message, data: { registrationId } } |
| POST | /auth/verify-email | { registrationId, otp } | { success, message, data: { userId } } |
| POST | /auth/resend-email-otp | { registrationId } | { success, message } |
| POST | /auth/login | { identifier, password } | { success, message, data: { userId, userName, role, accessToken, expiresAtUtc, refreshToken, refreshTokenExpiresAtUtc } } |
| POST | /auth/refresh | { refreshToken } | Same token/session data as login |
| POST | /auth/logout | { refreshToken } | { success, message } |
| POST | /auth/forgot-password | { email } | { success, message, data: { resetRequestId } } |
| POST | /auth/verify-password-reset-otp | { resetRequestId, otp } | { success, message } |
| POST | /auth/resend-password-reset-otp | { resetRequestId } | { success, message } |
| POST | /auth/reset-password | { resetRequestId, newPassword } | { success, message } |

### Request validation from AuthController
- RegisterRequest.userName: required, 3–30 chars, ^[a-zA-Z0-9._]+$.
- RegisterRequest.email: required, .NET EmailAddress.
- RegisterRequest.phoneNumber: required, ^\+?[0-9]{7,15}$.
- RegisterRequest.password: required, 8–1000 chars.
- LoginRequest.identifier: required, max 255 chars.
- LoginRequest.password: required, 8–1000 chars.
- VerifyEmailRequest.registrationId: required GUID; otp: six digits.
- ResendEmailOtpRequest.registrationId: required GUID.
- ForgotPasswordRequest.email: required email.
- Password-reset request IDs are required GUIDs; OTP is six digits; new password is 8–1000 chars.
- RefreshTokenRequest.refreshToken is required, max 200 chars.
- Auth DTOs reject unmapped JSON properties.

The web mobile rule is stricter than the backend phone regex: web requires exactly ten digits. Flutter retains web behavior.

## Backend behavior and security

### Registration / verification
- Username/email are trimmed and lowercased by the handler; phone has a leading plus removed.
- A verified, non-deleted matching username/email/phone causes HTTP 409 duplicate-account conflict.
- A single pending unverified registration can be updated, subject to resend rules.
- Passwords are hashed with ASP.NET Core Identity PasswordHasher; plaintext is not stored.
- OTP is cryptographically generated and hashed; email delivery is queued through the email outbox.
- OTP lifetime: 10 minutes. Registration lifetime: 30 minutes.
- Backend resend cooldown: 60 seconds; initial send plus up to three additional sends per hour.
- Email OTP verification allows at most five attempts.
- Successful verification activates the account, removes verification record, creates a profile stub, optionally assigns configured default mentor and assigns a trial subscription (handler fallback: 60 days).

### Login / tokens
- Backend looks up identifier and verifies password using the password hasher.
- Deleted, inactive, inactive-role and email-unverified accounts cannot authenticate.
- Ten wrong-password attempts cause a 10-minute lockout; warning begins after eight failures.
- Exact role strings used by frontend routing: Admin, User, Mentor.
- JWT validates issuer, audience, signature and lifetime. Role claim type is .NET ClaimTypes.Role.
- JwtSettings code defaults: 30-minute access token and 7-day refresh token; deployment config may override.
- Auth controller rate limit: 10 requests/minute; global limit: 300 requests/minute per IP.
- Remember Me is client-side only; no remember flag is sent to backend.

### Password recovery
- Unknown email is handled with a non-enumerating response.
- Reset OTP expires in 10 minutes; resend cooldown is 60 seconds; backend limit is five sends/hour.
- OTP verification allows at most five attempts.
- After OTP verification, reset must complete within 15 minutes.
- New password minimum: eight characters.

### Error response
Global exception handler returns { success: false, message }.
- Application validation/business error: HTTP 400.
- Duplicate/conflict: HTTP 409.
- Unauthorized: HTTP 401 (backend message: “Unauthorized.”).
- Missing resource: HTTP 404.
- Serialization/concurrency conflict: HTTP 409.
- Unexpected server error: HTTP 500 with generic message.
- Auth rate-limit rejection: HTTP 429.

## Flutter source mapping

| Flutter file | Responsibility |
|---|---|
| lib/core/config/app_config.dart | API root from API_BASE_URL dart-define; no host hardcoded |
| lib/core/api/api_client.dart | JSON HTTP requests, bearer header, timeout, error parsing and one-time refresh retry for authenticated calls |
| lib/core/errors/api_exception.dart | Structured HTTP error |
| lib/core/storage/session_store.dart | Secure persistent session for Remember Me; memory-only otherwise |
| lib/features/auth/data/models/auth_models.dart | Auth/session response parsing |
| lib/features/auth/data/services/auth_api_service.dart | Exact backend auth endpoints and payload fields |
| lib/features/auth/data/repositories/auth_repository.dart | Auth orchestration, role validation, refresh and logout |
| lib/features/auth/domain/auth_validation.dart | Web-compatible local validation |
| lib/features/auth/presentation/screens/login_screen.dart | Premium login and role-aware success routing |
| lib/features/auth/presentation/screens/registration_screen.dart | Details → email OTP → login |
| lib/features/auth/presentation/screens/forgot_password_screen.dart | Email → OTP → new password |
| lib/features/auth/presentation/screens/auth_gate.dart | Persistent session restoration |
| lib/app/theme/app_theme.dart | Royal Indian Heritage palette |
| test/unit/auth_validation_test.dart | Local validation tests |
| test/unit/auth_models_test.dart | Backend response parsing tests |

## Session persistence
- Remember Me on: full session persisted in Android encrypted secure storage.
- Remember Me off: session stays in process memory and is not restored after app termination.
- Startup reads persistent session. If access token is expired and refresh token remains valid, Flutter calls POST /auth/refresh and replaces both tokens.
- Authenticated API calls can retry once after a 401 using the refresh token; a failed refresh clears the local session.
- A temporary network/configuration failure during startup refresh retains the stored session rather than silently signing out.
- Passwords and OTPs are never persisted or logged.

## Build configuration and known limits

Pass the backend API root, including /api:

    flutter run --dart-define=API_BASE_URL=https://YOUR_BACKEND_HOST/api

Do not assume localhost on a physical Android phone points to the development computer. Use a reachable HTTPS hostname or a deliberately configured development endpoint.

Before this phase, the repository contained architecture documentation and folders only: no pubspec.yaml and no generated Android runner. This implementation adds the Flutter package manifest and Dart application source. Generate Android platform files with:

    flutter create --platforms=android .

Then run flutter pub get, flutter analyze and flutter test. Flutter/Dart/Android SDK are not available in this execution environment, so analyzer, emulator and live API scenarios cannot be reported as run here.

The successful-auth destination in this phase is an explicit role landing placeholder. Actual Admin, User and Mentor dashboards are separate feature work and were not fabricated as part of authentication.
