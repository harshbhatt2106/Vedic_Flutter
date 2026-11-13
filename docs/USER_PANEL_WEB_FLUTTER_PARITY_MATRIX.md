# VedicVivah User Panel — Web vs Flutter parity matrix

**Audit date:** 2026-11-13  
**Source branches inspected:**
- Web: `harshbhatt2106/vedicvivah-frontend` / `FainalFrontend`
- Backend: `harshbhatt2106/vedicvivah-backend` / `FainalBak`
- Flutter: `harshbhatt2106/Vedic_Flutter` / `flutter-development`

Scope is the existing **User Panel only**. Admin and Mentor panels are excluded. Mentor selection inside the User's own profile is included because it is a web User Profile feature.

## Status interpretation

- **FULLY IMPLEMENTED** requires source parity plus successful functional verification.
- **PARTIALLY IMPLEMENTED** means the Flutter screen/API workflow is present in source, but one or more web interactions, runtime checks, or device/API tests are not yet verified.
- **UI ONLY**, **API NOT CONNECTED**, **NOT IMPLEMENTED**, and **BROKEN** are used only where source inspection supports those findings.
- **NOT APPLICABLE** means the current Web User Panel/backend does not provide that requested capability.

## Feature matrix

| No. | Web user feature | Flutter status | API status | Testing status | Action / finding |
|---:|---|---|---|---|---|
| 1 | Registration form and validation | PARTIALLY IMPLEMENTED | Endpoint mapped: `POST /auth/register` | Unit/source only; live registration not run | Test with a safe account and verify server validation |
| 2 | Email OTP verification and resend | PARTIALLY IMPLEMENTED | `POST /auth/verify-email`, `/auth/resend-email-otp` | Live OTP not run | Verify delivery, expiry, cooldown and invalid OTP |
| 3 | Login and role routing | PARTIALLY IMPLEMENTED | `POST /auth/login` | Unit/source only | Verify real User login and role routing |
| 4 | Remember Me, session persistence, refresh and logout | PARTIALLY IMPLEMENTED | `/auth/refresh`, `/auth/logout` plus authenticated retry | Unit/source only | Test restart with Remember Me on/off and expired access token |
| 5 | Forgot password, reset OTP, resend and reset | PARTIALLY IMPLEMENTED | Existing `/auth/forgot-password`, verify/resend/reset endpoints | Live email/OTP flow not run | Run complete email reset workflow |
| 6 | User dashboard, profile strength, counters, updates, shortlist preview and success stories | PARTIALLY IMPLEMENTED | Profile, photos, references, shortlist, notifications and public success-story endpoints mapped | Not run against authenticated API | Verify counters and dashboard content with real account data |
| 7 | Profile biodata editing: personal, physical, community, education/career, family, location/residence and About Me | PARTIALLY IMPLEMENTED | Existing GET and PATCH section endpoints mapped | Not run against authenticated API | Validate each section save, row-version conflicts and persistence |
| 8 | Profile completion percentage and approval/rejection state | PARTIALLY IMPLEMENTED | `GET /user-profile` | Not run against authenticated API | Compare completion percentage and rejected profile behavior with web |
| 9 | Profile visibility and submit for review | PARTIALLY IMPLEMENTED | `PATCH /user-profile/visibility`, `POST /user-profile/submit-for-review` | Not run against authenticated API | Verify visibility in discovery and review state transitions |
| 10 | Own photo gallery: upload, view, delete and set primary | PARTIALLY IMPLEMENTED | Existing photo GET/POST/DELETE/PUT endpoints mapped | Not run on physical device/API | Verify file MIME/size limits, six-photo limit and protected image loading |
| 11 | Relative/reference contacts: add, edit, delete, maximum three, cascading location | PARTIALLY IMPLEMENTED | `/user-references` and country/state/city endpoints mapped | Not run against authenticated API | Verify existing contact edit restores its location and server validation |
| 12 | Mentor selection from User Profile: available, assigned and suggested mentor | PARTIALLY IMPLEMENTED | Existing `/user/mentors`, `/user/mentor`, `/user/mentor/suggestion` endpoints mapped | Not run against authenticated API | Verify location-based availability and selection persistence |
| 13 | Partner preferences: age, marital status, height, community, career, income and location | PARTIALLY IMPLEMENTED | GET/PUT `/partner-preferences` | Not run against authenticated API | Verify null/default semantics, all nested values and row-version conflicts |
| 14 | Find Matches: search, full filter set, cascading selectors, clear filters and pagination | PARTIALLY IMPLEMENTED | `GET /user-profile/discover` with backend-supported query parameters | Not run against authenticated API | Compare each filter and page result against Web for same account |
| 15 | Match profile details and accepted-interest photo access | PARTIALLY IMPLEMENTED | `GET /user-profile/{userId}`, interest status and protected photo endpoints | Not run against authenticated API | Verify privacy rules: photos visible only after accepted interest |
| 16 | Send interest from matches | PARTIALLY IMPLEMENTED | `POST /interests/{targetUserId}` | Not run against authenticated API | Verify duplicate/pending/accepted cases and resulting status |
| 17 | Received/sent interests, accept, reject, resubmit, withdraw and message after acceptance | PARTIALLY IMPLEMENTED | Existing interests endpoints mapped | Not run against authenticated API | Test both user accounts through the full state transition workflow |
| 18 | Shortlist list, add/remove and profile view | PARTIALLY IMPLEMENTED | Existing `/shortlists` endpoints mapped | Not run against authenticated API | Verify list/badge consistency after actions and across restart |
| 19 | Block and unblock profiles, including block reason | PARTIALLY IMPLEMENTED | Existing `/blocks` endpoints mapped | Not run against authenticated API | Verify blocked profiles disappear from discovery and unblock restores visibility |
| 20 | Report a profile and view My Reports | PARTIALLY IMPLEMENTED | `POST /reports/{reportedUserId}`, `GET /reports/my` | Not run against authenticated API | Verify reason validation and saved report history |
| 21 | Conversation inbox, accepted-connection search, message history, send/read, delete and paging | PARTIALLY IMPLEMENTED | Existing `/conversations` REST endpoints mapped | Not run against authenticated API | Verify permissions, message ownership, pagination and unread counts |
| 22 | Real-time chat and reconnect/rejoin | PARTIALLY IMPLEMENTED | SignalR hub `/api/hubs/chat`, `JoinConversation`, `LeaveConversation`, receive/delete events | Not run against live hub | Test two physical sessions, reconnect, duplicate messages and group authorization |
| 23 | Notifications list, mark one read and mark all read | PARTIALLY IMPLEMENTED | Existing `/notifications` endpoints mapped | Not run against authenticated API | Verify unread counts and state after refresh/restart |
| 24 | Push notifications / native device token delivery | NOT APPLICABLE to current Web User Panel | Backend has device-token registration endpoints, but inspected Web User Panel does not register browser/device tokens | Not tested | Do not add Firebase behavior without a real configured Firebase project; no Web User Panel push client was found |
| 25 | Account name, username availability/update, email OTP, password and profile-picture change | PARTIALLY IMPLEMENTED | Existing `/account` endpoints mapped | Not run against authenticated API | Verify username/session update, OTP resend and profile-picture replacement |
| 26 | Account deactivation and permanent deletion | PARTIALLY IMPLEMENTED | `POST /account/deactivate`, `DELETE /account?isMarried=...` | Not run; destructive actions intentionally not executed | Test only with an explicitly approved disposable account |
| 27 | Privacy policy/terms pending gate, scroll-to-end and Accept All | PARTIALLY IMPLEMENTED | `GET /privacy-policy/pending-acceptance`, `POST /privacy-policy/accept-all` | Not run against published policy data | Verify pending gate, no-scroll and long-scroll cases, acceptance persistence |
| 28 | Help & Support: submit ticket and view admin replies | PARTIALLY IMPLEMENTED | `GET/POST /support/tickets` | Not run against authenticated API | Verify ticket submission and reply rendering |
| 29 | Active plans, current subscription, expiry and access restrictions | PARTIALLY IMPLEMENTED | `GET /subscription-plans`, `GET /subscription-plans/my-subscription` | Not run against real subscription states | Verify active, expired, null/free and network-unavailable states |
| 30 | User plan purchase / checkout / payment status / payment history | NOT APPLICABLE to current implementation | No User checkout/payment endpoint exists in inspected backend; Web Plans page instructs users to contact support for activation | Not applicable | Do not invent payment UI or call a plan purchased without a backend contract |

## Static source/API findings

- The Flutter User Panel now includes Home, Notifications, Shortlist, Blocked, Reports, Interests, More (Find Matches, Profile, Photos, Preferences, Messages, Support, Plans, References, Mentor), and Account/Privacy.
- Existing backend contracts were inspected for User Profile, references, account, conversations, chat hub, interests, notifications, privacy, plans, support, locations and reference data.
- Flutter uses existing endpoints; no duplicate backend endpoint was added in this implementation.
- The Flutter API client supports authenticated requests, token refresh/retry, binary photo reads, JSON PATCH and multipart photo uploads.
- Access restrictions now account for pending privacy acceptance, unapproved profiles and expired subscriptions.
- Payment initiation is intentionally absent because the existing Web User Panel and backend do not expose a User checkout flow.
- Push token registration is not included because no push client was found in the inspected Web User Panel and no Firebase Android configuration is present in the Flutter repository.

## Verification summary

Latest observed CI run on the current Flutter development branch:
- `flutter pub get`: passed
- `flutter analyze --no-fatal-infos`: passed
- `flutter test`: passed
- Temporary Android runner generation: passed
- Java setup: passed
- `flutter build apk --debug`: still running when this report was last checked

The Android runner is generated temporarily by CI and is not committed in the repository. A permanent Android application ID and release signing configuration are not established in the inspected Flutter source. Therefore, this CI debug build does not verify a Play Store release bundle.

No authenticated live API workflow, two-account SignalR test, physical Android-device test, or destructive account test has been performed. No test-account credentials were provided, and no real purchases or destructive production operations were attempted. Firebase configuration is absent; the inspected Web User Panel does not implement a push-notification client.

## Counts and parity

There are **30 audited feature rows**:
- **28 applicable** to the current Web User Panel/backend.
- **2 not applicable**: User checkout/payment and native push client (no corresponding Web User Panel capability).
- **0 FULLY IMPLEMENTED and runtime-verified** at this checkpoint.
- **28 PARTIALLY IMPLEMENTED**: the Flutter source and endpoint wiring exist, but live API/device workflows remain unverified.
- **0 UI ONLY**, **0 API NOT CONNECTED**, **0 NOT IMPLEMENTED**, **0 BROKEN** identified by this static checkpoint.

Strict verified parity using the requested formula:

`0 fully verified applicable features / 28 applicable web features × 100 = 0% verified`

This is **not** a claim that no code exists. It means no User workflow has yet been verified end-to-end against a live authenticated backend/device, so none can honestly be marked fully implemented under the acceptance criteria. Do not claim 100% until the remaining runtime tests pass.
