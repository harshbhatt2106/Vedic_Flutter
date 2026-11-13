# VedicVivah User Panel — Flutter Implementation Audit

> **Audit status: IN PROGRESS — NOT APPROVED FOR IMPLEMENTATION YET**
>
> This is the working audit register. Route discovery and initial repository comparison are complete. Per-page control/validation/API tracing is still pending. No page or feature is marked complete based on folder existence alone.

## 1. Source revisions inspected

| Layer | Repository | Branch | Revision |
|---|---|---|---|
| Web frontend | harshbhatt2106/vedicvivah-frontend | FainalFrontend | 8850d016c92747477663b549e52c9fa2c416535e |
| Backend | harshbhatt2106/vedicvivah-backend | FainalBak | 3955f39cf8977d2563fa5e07204604e5ed90b6b7 |
| Flutter target | harshbhatt2106/Vedic_Flutter | flutter-development | 89798f453cebbabb80b1ba498178ebadea3b4905 |

## 2. Initial findings

- React router is defined in `src/routes/AppRoutes.tsx`.
- User navigation and subscription/privacy restrictions are implemented in `src/layouts/UserLayout.tsx`.
- The frontend feature inventory identifies 12 primary User routes, in addition to guest authentication and the privacy acceptance flow.
- Backend controller inventory contains dedicated controllers for profile, account, preferences, interests, shortlists, blocks, conversations, notifications, subscriptions, support, privacy policy, reports and reference data.
- Flutter is feature-first and role-separated. The current User page folders are mostly placeholders; the User dashboard has an initial screen implementation. This is not evidence of User feature parity.
- Flutter architecture documentation explicitly describes the current directory layout as a scaffold and states that screen/business-logic implementation is not included in the architecture stage.
- The current Flutter dependencies include `http` and `flutter_secure_storage`; no payment gateway integration is documented in the inspected backend/API catalogue.
- Do not infer payment processing, endpoint availability, or completed functionality from route names or folder names.

## 3. Discovered guest/auth routes

| Route | Web page | Backend contract | Flutter status |
|---|---|---|---|
| `/login` | LoginPage | POST `/auth/login`, POST `/auth/refresh`, POST `/auth/logout` | Implemented baseline; detailed regression pending |
| `/register` | CreateAccountPage + email OTP step | POST `/auth/register`, POST `/auth/verify-email`, POST `/auth/resend-email-otp` | Implemented baseline; detailed regression pending |
| `/forgot-password` | ForgotPasswordPage | POST `/auth/forgot-password`, verify/resend/reset endpoints | Implemented baseline; detailed regression pending |

## 4. Discovered User routes

| # | Route | Web page | Backend/API mapping | Flutter source/status |
|---:|---|---|---|---|
| 1 | `/dashboard` | DashboardPage | GET `/user/dashboard`; related unread counts/summary calls to be traced | `user_dashboard_screen.dart` exists; audit pending |
| 2 | `/profile` | ProfilePage | `/user-profile`, photos, references, reference data, visibility, submit-for-review | Folder exists; implementation not verified |
| 3 | `/preferences` | PartnerPreferencesPage; Find Matches navigation label | GET/PUT `/partner-preferences`; discover API is GET `/user-profile/discover` | Folder exists; implementation not verified |
| 4 | `/shortlisted` | ShortlistPage | GET/POST/DELETE `/shortlists`; status lookup | Folder exists; implementation not verified |
| 5 | `/interests` | InterestsPage | `/interests/sent`, `/interests/received`, pending-count, status, send, accept, reject, resubmit, withdraw | Folder exists; implementation not verified |
| 6 | `/blocked` | BlockedUsersPage | GET/POST/DELETE `/blocks`; status lookup | Folder exists; implementation not verified |
| 7 | `/my-reports` | MyReportsPage | GET `/reports/my`; POST `/reports/{reportedUserId}` | Folder exists; implementation not verified |
| 8 | `/messages` | MessagesPage | `/conversations`, messages, read/unread, send/delete; SignalR `/api/hubs/chat` | Folder exists; implementation not verified |
| 9 | `/notifications` | NotificationPage | GET `/notifications`, unread-count, mark-one/read-all, device token registration | Folder exists; implementation not verified |
| 10 | `/account/settings` | AccountSettingsPage | GET `/account`; account name/username/email/password/profile-picture; deactivate/delete | Folder exists; implementation not verified |
| 11 | `/support` | SupportPage | POST/GET `/support/tickets` | Folder exists; implementation not verified |
| 12 | `/plans` | PlansPage | GET `/subscription-plans`; GET `/subscription-plans/my-subscription` | Folder exists; implementation not verified |

### Nested User flows and non-route screens

| Item | Source behavior | Audit status |
|---|---|---|
| Privacy acceptance | UserLayout checks GET `/privacy-policy/pending-acceptance`; acceptance via POST `/privacy-policy/accept-all` or individual accept | Nested modal; control-by-control audit pending |
| Complete profile alias | `/profile/complete` redirects to `/profile` | Redirect discovered; no separate screen |
| Profile photos/gallery | Upload, list, protected content, delete, set primary | Nested profile section; detailed audit pending |
| Profile section editing | Personal, community, education/career, family, location/residence, about | Nested profile sections; detailed audit pending |
| Discover/match filters | Discover API is `GET /user-profile/discover`; preferences are a separate route | Filter fields, query mapping and interaction trace pending |
| Profile details | `GET /user-profile/{userId}`, permitted photo metadata/content and primary photo | Navigation entry points and all actions pending |
| Mentor selection/directory | `GET /user/mentors`, `/user/mentor`, `/user/mentors/assigned`, `/user/mentor/suggestion`; POST `/user/mentor` | Visibility/entry point and controls pending |
| Consent/terms | Privacy policy acceptance is confirmed; separate Terms route not found in the inspected route table | Confirm whether surfaced elsewhere before classifying as absent |

## 5. Redirect-only routes (not separate screens)

- `/profile/complete` → `/profile`
- `/admin` → `/admin/dashboard`
- `/admin/locations`, `/admin/community`, `/admin/education-career` → `/admin/master-data`
- `/admin/mentors/add` → `/admin/mentors`
- Unknown paths → `/login`

Admin and Mentor are not part of this User-panel implementation scope, but their existing Flutter functionality must not be damaged.

## 6. API groups confirmed from backend controller inventory

| Feature | Controller | Key routes |
|---|---|---|
| Authentication | AuthController | `/auth/*` |
| Account settings | AccountController | `/account*` |
| Profile/discovery/photos | UserProfileController | `/user-profile*` |
| Dashboard/mentor selection | UserController | `/user/*` |
| Partner preferences | PartnerPreferencesController | `/partner-preferences` |
| Interests | InterestsController | `/interests/*` |
| Shortlist | ShortlistsController | `/shortlists*` |
| Block list | BlocksController | `/blocks*` |
| Chat | ConversationsController + ChatHub | `/conversations*`, `/api/hubs/chat` |
| Notifications/push | NotificationsController + DeviceTokensController | `/notifications*`, `/device-tokens` |
| Subscription | SubscriptionPlansController | `/subscription-plans*` |
| Privacy acceptance | PrivacyPolicyController | `/privacy-policy/*` |
| Support | SupportController | `/support/tickets*` |
| Reports | ReportsController | `/reports*` |
| Reference data | ReferenceDataController + LocationController | `/reference-data/*`, `/locations/*` |
| User references | UserReferencesController | `/user-references*` |

The detailed endpoint catalogue is maintained in `docs/API_MAPPING.md`. Each operation must still be checked against its exact controller action, DTO, handler, validation and authorization before implementation.

## 7. Per-page control audit register

For each route above, the next audit pass must inspect and record:
- Every button, icon button, clickable card and link, with exact result/navigation.
- Every tab, modal, bottom sheet, popup and conditional screen.
- Every input, dropdown, checkbox, radio, search and filter.
- Required/optional rules, formatting, client validation and server validation.
- Exact HTTP method, route, query/body/multipart fields and response model.
- Controller authorization, application handler/business rules and database relationship.
- Loading, empty, success, failure, retry and refresh behavior.
- Flutter parity status and test evidence.

**Current status for all User routes:** Detailed control-level audit pending. Do not mark any route complete yet.

## 8. Initial Flutter parity comparison

| Area | Current repository evidence | Audit result |
|---|---|---|
| Auth | Login, registration, forgot-password screens and auth repository/services exist | Baseline exists; test and contract verification pending |
| User dashboard | `user_dashboard_screen.dart` exists | Partial screen presence only; functionality audit pending |
| Profile, preferences, discovery, shortlist, interests, messages, notifications, settings, blocked users, reports, support, subscriptions | Feature folders exist, most route folders contain `.gitkeep` | Native page implementation not yet evidenced |
| Shared infrastructure | API client, app config, session storage, error model exist | Review implementation and token/error edge cases |
| Automated tests | Auth/model unit tests exist; integration/widget directories are placeholders | User flow tests not evidenced |

## 9. Implementation gate

**Do not begin User feature implementation until the per-page web control audit and exact backend contract trace are completed.** After that, implement one page at a time, verify its controls and API behavior, update this document, and only then move to the next page.

## 10. Testing and completion evidence

No Flutter CLI, Android emulator/device, live backend test account, or runtime test session was available through this repository inspection. Therefore:
- Flutter analyze: NOT RUN
- Flutter test: NOT RUN
- Android build: NOT RUN
- Physical-device verification: NOT RUN
- Live API end-to-end tests: NOT RUN

These checks must be run in the user's local Flutter/Android environment or an execution environment with Flutter SDK and valid test access. Never report them as passed without actual output.


## 11. Code-level audit findings — first pass

### 11.1 User dashboard (/dashboard)

**Web source inspected:** src/features/auth/pages/DashboardPage.tsx  
**Flutter source inspected:** lib/features/user/presentation/pages/dashboard/user_dashboard_screen.dart  
**Backend source inspected:** UserController.cs and UserProfileController.cs.

#### Web data dependencies observed
- Own profile: GET /user-profile.
- Own photos: GET /user-profile/photos; primary image content: GET /user-profile/photos/{photoId}/content.
- Relative references: GET /user-references.
- Partner preference: GET /partner-preferences.
- Match preview: GET /user-profile/discover using saved preferences.
- Shortlist preview: GET /shortlists.
- Recent notifications: notification service list call.
- Public success stories: public success-story service; exact request still to be recorded from its service implementation.

#### Web dashboard actions observed
- Add profile photo → /profile with edit state and photos section.
- Find Matches CTA and match statistic → /preferences.
- View/Edit Profile and Create Biodata → /profile (with edit state for section-specific actions).
- Profile completion section actions → /profile with the selected section in navigation state.
- Shortlist statistic/preview actions → /shortlisted.
- Unread updates statistic, See all and notification preview actions → /notifications.
- Shortlist preview Open action → /shortlisted.
- Profile status includes incomplete, pending/under review, approved/live and rejected/changes requested states; rejection reason is surfaced when present.
- Loading/error states exist independently for profile bundle, matches, shortlist and notifications.

#### Flutter dashboard behavior observed
- Loads profile, photos, shortlist, latest notifications and relative references concurrently.
- Calculates a ten-section biodata completion score locally.
- Shows profile name/status, shortlist count, unread updates, photo count, latest updates and shortlist preview.
- App bar exposes Refresh and Sign out.
- Current screen does not expose the web dashboard's Find Matches, profile edit, add photo, shortlist navigation or notifications navigation actions. Statistic tiles and preview rows are currently display-only.
- Current screen does not load saved partner preferences, discover preview matches or success stories.
- Flutter screen uses GET /notifications?take=4; web dashboard delegates to notificationService.getNotifications(4). Exact query-name parity must be checked in the web service and backend controller.
- Flutter screen does not call GET /user/dashboard. Backend UserController.Dashboard() currently returns only success=true and an authorization message, not dashboard statistics. Web dashboard data is assembled from feature APIs instead.

**Dashboard parity status:** PARTIAL. Data display exists; major web navigation/actions and data sections are missing or unverified. Do not mark complete.

### 11.2 My Profile (/profile) — initial structural audit

**Web sources inspected:** ProfilePage.tsx, CompleteProfilePage.tsx, profileService.ts, referenceDataService.ts.

The profile editor is a merged profile/detail experience with ten sections:
1. Personal
2. Religion & Community
3. Education & Career
4. Physical
5. Family
6. Relative Contacts
7. Location
8. Residence
9. About Me
10. Photos

The profile request model includes identity and birth details, disability, religion/caste/sub-caste, mother tongue, education/career reference IDs and display fields, income/work type, height/weight, family, native/residential location, residence type/area/room count, marital status, about text and row-version concurrency data.

#### Profile API operations observed in the web service
- GET /user-profile — read own profile.
- PUT /user-profile — save complete profile.
- PATCH /user-profile/personal, /community, /education-career, /family, /location-residence, /about — section-specific saves.
- PATCH /user-profile/visibility with { status: 'Visible' | 'Hidden' }.
- POST /user-profile/submit-for-review.
- GET /user-profile/photos; POST multipart /user-profile/photos; DELETE /user-profile/photos/{photoId}; PUT /user-profile/photos/{photoId}/primary.
- GET protected own photo bytes via /user-profile/photos/{photoId}/content.
- GET /user-references; POST/PUT/DELETE /user-references for relative contact management.
- Reference lookups include religion, caste by religion, sub-caste by caste, qualifications, mother tongues, education fields, courses, occupations and professions.
- Location lookup dependencies include countries, states by country and cities by state. Location values are backend-managed.

#### Backend behavior confirmed in inspected source
- UserProfileController is authenticated.
- Discover validation enforces pageNumber >= 1, pageSize 1–50, ages >= 18, minimum age <= maximum age, minimum income <= maximum income.
- Photo upload is limited to 5 MiB and passes through image validation before the upload command.
- UserController mentor-selection endpoints require the User role.
- PartnerPreferencesController validates age >= 18, min/max age order, income order and maximum height feet <= 8; concurrency/unique-row conflicts return HTTP 409 with reload guidance.

#### Data/master-data warning
The inspected web referenceDataService.ts still contains local fallback arrays for religion/caste/sub-caste when local-data mode is enabled. Production behavior should use backend reference data. Flutter must not copy those local arrays as production master data. Location lookups are explicitly backend-sourced because Admin manages them dynamically.

**Profile parity status:** WEB structure and service/API surface partially traced; every individual field, conditional control, validation, modal, photo action and backend handler still requires line-by-line audit. Flutter profile UI is not evidenced by the current User page tree. Do not mark complete.



## 12. Code-level audit findings — discovery and communication first pass

### 12.1 Find Matches / Partner Preferences (/preferences)

**Web sources inspected:** PartnerPreferencesPage.tsx, partnerPreferenceService.ts, matchFilters.ts, profileService.ts.  
**Backend source inspected:** PartnerPreferencesController.cs and UserProfileController.cs.

This route is not just a static preference form. The web page combines saved partner-preference editing, match discovery, pagination, profile detail/gallery dialogs and profile actions.

**Observed UI interactions**
- Expand/open preferences modal; close/cancel restores the form and marital-preference snapshot.
- Reset filters.
- Done/apply preferences and refresh the match search.
- Previous/next pagination with disabled/loading states.
- Open a profile detail modal and close it.
- Toggle shortlist from a profile view/card.
- Start Send Interest flow and confirm/cancel the send dialog.
- Open profile photo gallery and close it.
- Block profile flow with reason selection, cancel and confirm.
- Report profile action opens report flow.
- Profile card exposes profile, block and report icon actions in addition to shortlist/interest/photo actions.

**Backend contract facts confirmed**
- GET/PUT /partner-preferences; request includes preferred gender, marital status, additional requirements, row version, age, height, community, career and location nested objects.
- GET /user-profile/discover accepts search, gender, age, religion/caste/sub-caste, mother tongue, education/profession, income, height, country/state/city, marital status, education-field/course/qualification/occupation/profession/work type and pagination.
- Backend discover pageSize is 1–50, default 12; pageNumber must be >= 1.
- Backend validates ages >= 18, min age <= max age and min income <= max income.
- Preference save validates age >= 18, min/max age order, income order and maximum feet <= 8; row-version and duplicate-create races return 409.

**Audit gap:** Need finish the web-to-backend query serialization and field-by-field control/validation map, including dependent master-data resets and all report/block/interest dialog requirements.

**Flutter parity status:** Missing native discovery/preferences screen is evidenced by placeholder feature folders. NOT IMPLEMENTED / NOT VERIFIED.

### 12.2 Interests (/interests)

**Web source inspected:** InterestsPage.tsx.  
**Backend source inspected:** InterestsController.cs.

**Observed UI interactions**
- Switch Received and Sent tabs.
- Received pending interest can be accepted through a confirmation dialog or rejected directly.
- Accepted connections expose a message action that navigates to /messages and passes openUserId.
- Existing accepted connection can be rejected through a confirmation flow.
- Rejected sent interest can be resubmitted.
- Sent interest can be withdrawn through a confirmation dialog.
- Empty-state CTA navigates to /preferences.
- Dismissible status feedback is present.

**Backend operations confirmed**
- GET /interests/sent and /interests/received.
- GET /interests/received/pending-count and /interests/status/{targetUserId}.
- POST /interests/{targetUserId}; PUT /interests/{interestId}/accept; PUT /interests/{interestId}/reject.
- GET /interests/connections/search?q=...
- PUT /interests/{interestId}/resubmit; DELETE /interests/{interestId}.
- Resubmit is explicitly sender-only; backend returns 409 when the current user is not the sender.

**Audit gap:** Need inspect service DTO/status values and every conditional state in both tabs; confirm whether rejected/accepted states expose all same actions as the current UI.

**Flutter parity status:** interests page directory is placeholder-only in the current Flutter tree. NOT IMPLEMENTED / NOT VERIFIED.

### 12.3 Shortlist (/shortlisted)

**Web source inspected:** ShortlistPage.tsx.  
**Backend source inspected:** ShortlistsController.cs.

**Observed UI interactions**
- Empty state CTA navigates to /preferences.
- Remove-from-shortlist heart action.
- View Profile opens a profile detail modal.
- Profile detail modal has close action.

**Backend operations confirmed**
- GET /shortlists.
- GET /shortlists/status/{shortlistedUserId}.
- POST /shortlists/{shortlistedUserId}.
- DELETE /shortlists/{shortlistedUserId}.

**Audit gap:** Inspect exact profile detail sections, protected photo retrieval, mutation refresh behavior and service response DTOs.

**Flutter parity status:** shortlist page directory is placeholder-only. NOT IMPLEMENTED / NOT VERIFIED.

### 12.4 Messages / Chat (/messages)

**Web source inspected:** MessagesPage.tsx and useChatHub.ts.  
**Backend source inspected:** ConversationsController.cs and ChatHub.cs.

**Observed UI interactions**
- New conversation dialog opens/closes.
- Search accepted connections and choose a person to start/open chat.
- Selecting a conversation switches to chat view; mobile layout has a back-to-list action.
- Message composer supports keyboard send handling.
- Message context menu opens and offers delete.
- Delete-conversation confirmation supports cancel and delete.
- Conversation photo is loaded through an authenticated blob path where available.

**Backend operations confirmed from controller catalogue**
- GET /conversations; POST /conversations/{otherUserId}.
- GET /conversations/{conversationId}/messages with take/before pagination.
- POST /conversations/{conversationId}/messages.
- PUT /conversations/{conversationId}/read.
- DELETE /conversations/{conversationId}/messages/{messageId}; DELETE /conversations/{conversationId}.
- GET /conversations/unread-count; GET /conversations/{conversationId}/photo.
- SignalR hub is mounted at /api/hubs/chat and supports JWT access_token query handling.

**Audit gap:** Need record exact SignalR event names/payloads, reconnect behavior, optimistic send/error behavior, pagination defaults, delete authorization and read receipt behavior.

**Flutter parity status:** messaging page and shared chat directories are placeholders; no User chat implementation is evidenced in Flutter. NOT IMPLEMENTED / NOT VERIFIED.

### 12.5 Notifications (/notifications)

**Web source inspected:** NotificationPage.tsx and notificationService.ts.  
**Backend source inspected:** NotificationsController.cs and DeviceTokensController.cs.

**Observed UI interactions**
- Mark all notifications as read.
- Mark an individual notification as read.
- Notification item behavior/navigation needs full inspection of the remainder of the page and notification payload mapping.

**Backend operations confirmed**
- GET /notifications?take=...
- GET /notifications/unread-count.
- PUT /notifications/{notificationId}/read.
- PUT /notifications/read-all.
- POST/DELETE /device-tokens for push token registration/unregistration.

**Flutter parity status:** notifications page/shared notifications directories are placeholders. Dashboard preview only displays recent notifications; it is not a notifications feature implementation. NOT IMPLEMENTED / NOT VERIFIED.



## 13. Code-level audit findings — account, safety and subscription first pass

### 13.1 Blocked users (/blocked)

**Web source inspected:** BlockedUsersPage.tsx.  
**Backend source inspected:** BlocksController.cs.

- Web page presents blocked profiles and an Unblock action.
- Backend exposes GET /blocks, GET /blocks/status/{blockedUserId}, POST /blocks/{blockedUserId}, DELETE /blocks/{blockedUserId}.
- Flutter blocked-users page directory is placeholder-only.
- Detailed empty/error states, confirmation behavior and refresh semantics remain to be traced.

**Flutter parity status:** NOT IMPLEMENTED / NOT VERIFIED.

### 13.2 My Reports (/my-reports)

**Web source inspected:** MyReportsPage.tsx.  
**Backend source inspected:** ReportsController.cs.

- Web route is a read-only list of the current user's submitted reports in the inspected page.
- Report creation is initiated from profile/match UI through the report modal, not from a visible create button on My Reports.
- Backend exposes GET /reports/my and POST /reports/{reportedUserId}; Admin-only GET /reports is outside User scope.
- Flutter My Reports page directory is placeholder-only.
- Report modal reasons, required fields, duplicate handling and server-side validation still need field-level inspection.

**Flutter parity status:** NOT IMPLEMENTED / NOT VERIFIED.

### 13.3 Account settings (/account/settings)

**Web source inspected:** AccountSettingsPage.tsx.  
**Backend source inspected:** AccountController.cs.

**Observed UI interactions**
- Change profile picture: choose file, save, cancel or remove existing picture.
- Edit first/last name: save/cancel.
- Edit username: live availability feedback, save/cancel.
- Change email: enter new email, request OTP, verify six-digit OTP, resend with cooldown, cancel/reset.
- Change password: current/new/confirm fields, show/hide toggles, update/cancel.
- Danger zone: delete account multi-step flow with back/cancel/continue; asks marital status before final deletion.
- User-only My Biodata shortcut navigates to /profile.
- Embedded mode is supported for Admin profile settings; do not alter Admin behavior when implementing User settings.

**Backend operations confirmed in API mapping**
- GET /account; GET /account/username-availability?username=...
- PUT /account/name; PUT /account/username.
- POST /account/email-change; POST /account/email-change/verify; POST /account/email-change/resend.
- PUT multipart /account/profile-picture.
- PUT /account/password.
- POST /account/deactivate; DELETE /account?isMarried=...
- Exact DTO fields, validation and email OTP limits must be verified from AccountController and its handlers before implementation.

**Flutter parity status:** account-settings page directory is placeholder-only. NOT IMPLEMENTED / NOT VERIFIED.

### 13.4 Help & Support (/support)

**Web source inspected:** SupportPage.tsx.  
**Backend source inspected:** SupportController.cs.

- Web page loads the current user's tickets with GET /support/tickets.
- New ticket submission sends POST /support/tickets with a message.
- Form validation, max length, ticket status rendering, error and retry behavior still need field-level inspection.
- Flutter support page directory is placeholder-only.

**Flutter parity status:** NOT IMPLEMENTED / NOT VERIFIED.

### 13.5 My Plan (/plans)

**Web source inspected:** PlansPage.tsx and subscriptionPlansApi.ts.  
**Backend source inspected:** SubscriptionPlansController.cs.

- Web page loads available plans and the current user's subscription.
- Plan cards expose Contact Us / support navigation; inspected page does not show a payment initiation action.
- Expired notice has a Dismiss action.
- Backend API catalogue exposes GET /subscription-plans and GET /subscription-plans/my-subscription for members.
- Admin plan management endpoints exist but are out of User scope.
- No payment gateway initiation, checkout, callback/webhook or transaction-history endpoint was found in the inspected backend controller catalogue. Do not invent a payment flow or claim payment parity.
- Flutter subscriptions page directory is placeholder-only.

**Flutter parity status:** NOT IMPLEMENTED / NOT VERIFIED. Payment feature is a backend capability gap unless another payment service/controller is found in a later full source scan.

### 13.6 Privacy acceptance (UserLayout modal)

**Web source inspected:** UserLayout.tsx and PrivacyPolicyAcceptancePage.tsx.  
**Backend source inspected:** PrivacyPolicyController.cs.

- UserLayout checks pending policy acceptance before rendering normal User content.
- GET /privacy-policy/pending-acceptance retrieves pending policies.
- POST /privacy-policy/accept-all accepts all pending policies; POST /privacy-policy/{policyId}/accept accepts one.
- The modal's complete text, scroll-to-end requirements, checkbox/button enablement, error retry and post-accept navigation still need detailed UI audit.
- Flutter route guard/modal parity is not evidenced by the current User feature tree.

**Flutter parity status:** NOT IMPLEMENTED / NOT VERIFIED.



## 14. Flutter foundation audit — navigation and transport

**Flutter sources inspected:** main.dart, vedic_vivah_app.dart, auth_gate.dart, auth_role_landing_screen.dart, api_client.dart, app_config.dart, session_store.dart.

### Navigation
- MaterialApp currently registers only '/', '/login', '/register' and '/forgot-password'.
- AuthGate restores the session and sends authenticated users to AuthRoleLandingScreen.
- AuthRoleLandingScreen sends User directly to UserDashboardScreen and Admin to AdminShellScreen.
- No User navigation shell, route registry, page stack policy or User destination registration is currently evidenced.
- The Mentor role currently lands on a generic placeholder screen. This User-panel scope must not accidentally change Admin routing or introduce a broken Mentor route.

**Impact:** User route implementation needs a navigation architecture that supports all discovered User destinations, nested profile sections, dialogs/bottom sheets, profile deep links from interests/messages/notifications and correct back behavior. Dashboard is not sufficient as the only User destination.

### API transport
- ApiClient currently exposes JSON GET, POST, PUT, DELETE and protected byte GET.
- It centralizes bearer token attachment, 25-second timeout, structured API error parsing and one in-flight refresh retry for authenticated 401 responses.
- ApiClient currently does not expose PATCH or multipart upload methods in the inspected source. Backend/web profile section saves use PATCH; profile photo/account picture/mentor photo operations require multipart. These operations cannot be implemented correctly until transport support is added and tested.
- ApiClient refresh retry is centralized; retain this behavior and do not create per-screen token refresh logic.
- AppConfig defaults to https://vedicvivah.co.in/api and supports --dart-define=API_BASE_URL; no localhost endpoint is hardcoded in this Flutter config.
- SessionStore persists encrypted session only when Remember Me is enabled and otherwise retains session in memory. This matches the documented web Remember Me distinction at a high level; device lifecycle and logout edge cases still require tests.

### Flutter dependency and test evidence
- Current pubspec includes Flutter, http and flutter_secure_storage. No image picker, SignalR client, push-notification/Firebase or multipart-specific package is declared in the current pubspec.
- Existing test tree contains auth/model unit tests. User feature integration/widget test folders are placeholders.
- This static source inspection cannot establish successful compilation or runtime behavior. Flutter analyze/test/build remain NOT RUN.

**Architecture gate:** Before feature implementation, add/test the missing PATCH and multipart transport paths, then establish User navigation without replacing the existing Admin shell. SignalR/push/media requirements must be handled only with compatible dependencies and verified platform configuration.



## 15. Audit checkpoint — 2026-11-13

**Current Flutter branch head verified:** `89798f453cebbabb80b1ba498178ebadea3b4905` (`feat(admin): add hierarchical location master model`). The source revision in this register has been refreshed to this branch head.

### 15.1 User source inventory re-verified against the current branch

The recursive tree under `lib/features/user` contains 34 entries, but only one Dart page implementation is present:
- `presentation/pages/dashboard/user_dashboard_screen.dart`

The following User page directories contain only `.gitkeep` placeholders:
- account settings
- blocked users
- discover matches
- interests
- messages
- my reports
- notifications
- partner preferences
- profile
- shortlist
- subscriptions
- support

This confirms that these are not implemented native screens yet. Their folder existence must not be counted as feature parity.

### 15.2 Dashboard code inspection — additional confirmed gaps

The current Flutter dashboard:
- Fetches own profile, own photos, shortlists, recent notifications and user references.
- Displays a profile summary/status, locally calculated biodata strength, three statistic tiles, recent notifications and shortlist previews.
- Exposes refresh and sign-out actions.

Compared with the web dashboard behavior recorded above, the current Flutter dashboard does not yet expose the web navigation actions for Find Matches, View/Edit Profile, Create Biodata, section-specific profile completion, Shortlisted, and Notifications. The statistic tiles and preview list items currently have no navigation callbacks. It also does not load the web dashboard's match preview or public success-story content. Treat dashboard parity as PARTIAL, not COMPLETE.

### 15.3 Transport/navigation blockers re-confirmed

- `ApiClient` has JSON GET/POST/PUT/DELETE and protected byte GET; no JSON PATCH method is exposed.
- Multipart support is limited to POST in the inspected client; profile section updates require PATCH and account/profile photo upload contracts include multipart PUT.
- Current app navigation is not yet a complete User route shell; only the dashboard is evidenced as an implemented User page.
- The current User feature subtree does not evidence native SignalR chat, push-notification registration, protected profile gallery UI or the User page flows listed in the route inventory.

### 15.4 Implementation decision

The User Panel is **not at feature parity**. Continue the per-page web control and backend DTO/validation audit before implementation, as required by the implementation gate in this document. Implement one User route at a time after its contract is traced. Keep Admin and Mentor screens outside this task and preserve their existing behavior.

### 15.5 Verification limitations

This checkpoint is based on static GitHub source inspection. Flutter CLI analysis, tests, Android build, physical-device testing and authenticated live API tests have not been run. No runtime pass or 100% parity claim is made.


## 16. Implementation progress — 2026-11-13

The first implementation batch has now been committed to `flutter-development`:

- Added a User Panel bottom-navigation shell and routed authenticated User accounts through it. Existing Admin routing remains unchanged.
- Added API-backed Notifications list with individual mark-as-read and mark-all-as-read actions.
- Added API-backed Shortlist list with remove action.
- Added API-backed Blocked Profiles list with unblock action.
- Added API-backed My Reports read-only list.
- Added Received/Sent Interests tabs with the web-supported pending accept/reject, sent rejected resubmit, and sent pending withdraw actions.

**Files added**
- `lib/features/user/presentation/pages/user_panel_shell.dart`
- `lib/features/user/presentation/pages/user_tools_screen.dart`
- `lib/features/user/presentation/pages/user_interests_screen.dart`

**Files updated**
- `lib/features/auth/presentation/screens/auth_role_landing_screen.dart`

**Important limitations**
- This is a partial implementation batch, not complete User Panel parity.
- Find Matches, Partner Preferences, full Profile/Biodata editing and photo gallery, Account Settings, Messages/SignalR, Support, Subscription Plans, Privacy Policy acceptance, and remaining dashboard navigation are still outstanding.
- The new screens use the existing API client and endpoints observed in the web services. They have not yet been compiled or exercised against a live authenticated backend.
- UI/interaction parity still needs comparison against the exact web dialogs, validation, navigation, and error states.
- Do not mark these features as runtime-verified until Flutter analyze/tests/build and device/API testing pass.


## 17. User implementation batch — 2026-11-13

The following implementation batch is committed to `flutter-development`. This does **not** certify 100% parity.

### Added / connected screens

- User Panel navigation now includes Home, Updates, Shortlist, Blocked, Reports, Interests, More, and Account.
- More workspace contains:
  - Find Matches list using `GET /user-profile/discover`, shortlist action and send-interest action.
  - Profile personal-information and About Me saves using the existing PATCH routes; visibility toggle and submit-for-review.
  - Partner preference read/save using `GET/PUT /partner-preferences`, retaining existing nested height/community/career/location values when available.
  - REST conversation inbox and conversation message send/read flow.
  - Support ticket create/list.
  - Active subscription plan and current subscription read-only display; activation links are not fabricated because the web says payment gateway is not available and asks users to contact support.
  - Profile photo gallery: protected image content, set-primary and delete actions.
- Account & Privacy screen contains account name, username availability/update, email-change OTP request/verify, password update, and pending privacy-policy acceptance with scroll-to-end and explicit confirmation.
- API client now supports authenticated JSON PATCH, needed for the existing profile and visibility endpoints.

### Still not implemented / not fully equivalent

- Profile: full community, education/career, physical, family, location/residence sections, reference management, master-data cascading selectors, photo upload, complete profile validation, and full photo privacy/visibility controls.
- Discover: complete web filter set (religion/caste/sub-caste, education/career, income, height, location, marital status, gender, etc.), filter popup, detailed profile view, report/block from profile, and exact pagination behavior.
- Preferences: complete nested preference editor and master-data selectors; current screen exposes only gender, marital status, age and additional requirements while retaining other values.
- Messaging: REST polling/manual refresh only; SignalR real-time connection/reconnection, delete message/conversation, search, paging and live read receipts are not implemented.
- Account: profile picture upload, username/session edge-case parity, email resend/cooldown, account deactivation/deletion and confirmation flows remain.
- Privacy: screen is accessible from Account; automatic mandatory post-login policy gate and individual acceptance parity still need integration/verification.
- Notifications: device-token registration/push delivery and deep-link navigation remain.
- User references, mentor directory/selection (where surfaced as a User feature), and complete reports/profile report creation remain.
- User dashboard still needs web parity actions and exact summary/stat navigation.

### Verification status

- Source commits were written directly to the existing `flutter-development` branch. No branch was created or switched.
- Flutter CI workflow is configured to run `flutter pub get`, `flutter analyze`, and `flutter test` on pushes to this branch. This audit does not claim those checks passed until a corresponding successful workflow run is observed.
- No live authenticated API test or physical-device test has been performed in this batch.
- Do not report 100% parity. Continue the route-by-route control/DTO audit and close the outstanding items above before final sign-off.


## 18. Expanded User Panel implementation checkpoint — 2026-11-13

The following User-facing implementation is now present on `flutter-development`:

### User features implemented or substantially wired

- Dashboard quick actions and tappable shortlist, notification and photo counters.
- Find Matches: API-backed discovery, age/search and extended filters, pagination, full profile detail view, shortlist, send-interest, report and block actions.
- Profile/Biodata: personal, physical, community, education/career, family, location/residence and About Me sections; live reference-data dropdowns and cascading religion/caste, education/course, occupation/profession and country/state/city selections; visibility and submit-for-review.
- Photos: gallery read, protected image content, upload (JPG/PNG/WEBP, 5 MB limit, maximum six photos), set primary and delete. Account profile-picture replacement is also wired.
- Partner Preferences: read/save all nested age, height, community, career and location preferences; live cascading reference-data selectors; client validation for age and income ranges.
- Interests: received/sent actions, resubmit/withdraw, and start a conversation after acceptance.
- Messaging: inbox and conversation search, accepted-connection search, REST send/read, SignalR authenticated connection, reconnect/rejoin, real-time receive/delete events, own-message deletion, conversation deletion and older-message paging.
- Notifications: list, individual mark-as-read on tap and mark-all-as-read.
- Shortlist: remove and view full profile.
- Blocked profiles: unblock.
- My Reports: list.
- Account: name, username availability/update (including persisted session username), email OTP request/resend/verify, password update with confirmation, profile-picture replacement, deactivation and deletion.
- Support: create and list tickets.
- Plans: active plans and current subscription display. No checkout action is added because the inspected backend exposes no payment/checkout endpoint.
- Privacy: pending policy acceptance is enforced as a post-login gate; the user must scroll to the end and confirm before continuing.
- User references: list/create/edit/delete.
- Mentor selection: available, suggested and currently assigned mentor.

### API/client and CI changes

- API client supports authenticated JSON PATCH and multipart POST/PUT with the correct image MIME types.
- Added `image_picker` and `signalr_netcore`.
- CI now runs `flutter pub get`, `flutter analyze --no-fatal-infos`, `flutter test`, creates the missing Android runner for the job, then attempts a debug APK build.

### Verification and remaining blockers

- On commit `d91e3b859996e2ea310f2ddbdf086f1726283eb5`, `flutter analyze --no-fatal-infos` passed and all 21 existing Flutter tests passed.
- The repository does not track an Android platform runner; CI now generates one temporarily before building. The verbose Gradle trace identified the prior `25.0.5` failure as Kotlin's Java-version parser rejecting the runner's default JDK 25. CI now explicitly installs Temurin JDK 17 before the Android build; the new build run is pending.
- The generated Android runner currently exists only inside CI, not as committed project files. The exact Play Console Android application ID must be confirmed before committing a permanent Android runner; do not guess it.
- Firebase configuration is absent from the repository. Native push-token registration/delivery cannot be completed safely without the project's Firebase Android configuration (`google-services.json`) and matching Firebase project setup.
- Reference-contact city selection still accepts a City ID rather than using the full cascading country/state/city selector.
- Discover filters now use live cascading selectors for religion/caste/sub-caste, education/course, occupation/profession and country/state/city, plus gender/marital-status dropdowns. Reference contacts now include country/state/city selectors with a manual City ID fallback for editing existing entries.
- No live authenticated API end-to-end run or physical Android-device test has been performed.
- Payment initiation remains not applicable to the current backend contract; do not invent a payment flow.
- **Do not claim 100% parity yet.** Finish the Android build diagnosis, obtain the Android application ID/Firebase config, complete the remaining selector/UI parity, and run authenticated device testing before sign-off.


## 19. Follow-up source fixes and Android runner verification — 2026-11-13

This section supersedes the earlier Android-runner and CI limitations recorded in section 18.

### Source revisions inspected
- Web frontend branch `FainalFrontend`: `8850d016c92747477663b549e52c9fa2c416535e`
- Backend branch `FainalBak`: `3955f39cf8977d2563fa5e07204604e5ed90b6b7`
- Flutter branch latest application-code commit at this checkpoint: `03e5a8823e53f6e548b23d896c57a2e80efc57cc`

### Additional source defects corrected
- Photo upload no longer displays a success notice after a failed upload.
- Added mounted/lifecycle guards to asynchronous match-connection search, message send, photo picker, photo actions and account-photo picker flows.
- SignalR connection failures are now surfaced instead of silently discarded.
- Real-time message read-status failures are handled rather than left as unhandled asynchronous errors.

These were source-level reliability defects; they were not reproduced on a physical device because no device session was available.

### Permanent Android project
- The Android runner is now committed under `android/` on the existing `flutter-development` branch.
- Application ID and namespace: `com.vedicvivah.app`, verified against the existing MAUI project's `ApplicationId`.
- Application label: `VedicVivah`.
- Main Android manifest includes INTERNET permission.
- Debug manifest allows cleartext HTTP only for local development; release remains HTTPS-only.
- CI selects Temurin JDK 17 before generating/building the Android project.
- The launcher icon is still the generated Flutter template icon; the existing VedicVivah logo/splash has not yet been migrated.
- Release signing is not configured in Flutter. No Play Store release AAB has been built.

### CI verification evidence
- Run [43413977908](https://github.com/harshbhatt2106/Vedic_Flutter/actions/runs/43413977908) succeeded: `flutter doctor -v`, `flutter pub outdated`, `flutter analyze --no-fatal-infos`, all 21 tests, Android runner generation/commit, debug APK build and artifact upload.
- Run [43414180792](https://github.com/harshbhatt2106/Vedic_Flutter/actions/runs/43414180792) succeeded with the main-manifest INTERNET permission and uploaded the debug APK.
- Run [43414418762](https://github.com/harshbhatt2106/Vedic_Flutter/actions/runs/43414418762) succeeded with debug-only cleartext networking.
- Run [43414727751](https://github.com/harshbhatt2106/Vedic_Flutter/actions/runs/43414727751) includes the subsequent SignalR error-handling changes. At the time this section was written, analyze and all 21 tests had passed; the final debug APK step was still running.

### Runtime verification still outstanding
- No physical Android device or emulator workflow was run from this session.
- No authenticated live API end-to-end tests were performed because safe test-account credentials were not available.
- No two-account live SignalR/reconnection test was performed.
- No destructive account action or real purchase was attempted.
- Release signing, Play Store AAB generation, Firebase native push delivery and branded launcher/splash assets remain outside the verified result. Native push and checkout remain not applicable to Web User Panel parity where the inspected web client does not provide those flows.

### Current strict parity count
- 30 audited feature rows.
- 28 applicable Web User Panel features; 2 not applicable (native push client and purchase/checkout).
- 28 partially implemented pending live authenticated/device workflow verification.
- 0 fully implemented and end-to-end runtime verified.
- 0 UI-only, 0 API-not-connected, 0 not-implemented and 0 broken identified by this static checkpoint.
- Strict verified parity: `0 / 28 × 100 = 0%`.

The 0% figure is the strict verified-parity metric, not a statement that the Flutter code contains no implementation. Do not claim 100% parity until the 28 applicable workflows have been verified against the live backend and Android runtime.
