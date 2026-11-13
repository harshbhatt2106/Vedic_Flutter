# VedicVivah User Panel — Flutter Implementation Audit

> **Audit status: IN PROGRESS — NOT APPROVED FOR IMPLEMENTATION YET**
>
> This is the working audit register. Route discovery and initial repository comparison are complete. Per-page control/validation/API tracing is still pending. No page or feature is marked complete based on folder existence alone.

## 1. Source revisions inspected

| Layer | Repository | Branch | Revision |
|---|---|---|---|
| Web frontend | harshbhatt2106/vedicvivah-frontend | FainalFrontend | 8850d016c92747477663b549e52c9fa2c416535e |
| Backend | harshbhatt2106/vedicvivah-backend | FainalBak | 3955f39cf8977d2563fa5e07204604e5ed90b6b7 |
| Flutter target | harshbhatt2106/Vedic_Flutter | flutter-development | 902f4165f11853bd5920fad7f4a8e16038d5a528 |

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

