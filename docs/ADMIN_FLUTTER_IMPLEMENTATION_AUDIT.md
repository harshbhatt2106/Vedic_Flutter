# VedicVivah Admin — Flutter Implementation Audit

**Audit date:** 2026-11-13  
**Target:** harshbhatt2106/Vedic_Flutter, branch flutter-development  
**Frontend source:** harshbhatt2106/vedicvivah-frontend, branch FainalFrontend, audited HEAD 8850d016c92747477663b549e52c9fa2c416535e  
**Backend source:** harshbhatt2106/vedicvivah-backend, branch FainalBak, audited HEAD 3955f39cf8977d2563fa5e07204604e5ed90b6b7  
**Flutter starting HEAD:** ae576496f547ed74a9fdd1a1c4a73634cd91d56c  
**Production API root:** https://vedicvivah.co.in/api

> This is a source-backed first audit. A route, endpoint, or placeholder folder is not proof of a completed feature. No Flutter Admin feature is marked complete until its native UI, real API behavior, and tests have been verified.

## 1. Admin routes and page inventory

React route source: src/routes/AppRoutes.tsx. Admin navigation source: src/layouts/AdminLayout.tsx. The Admin layout requires role Admin, refreshes the pending-review count on route changes, and provides profile/logout controls.

| # | Web route / page | Features, inputs and actions found | Backend API contract | Flutter status |
|---:|---|---|---|---|
| 1 | /admin/dashboard — AdminDashboardPage | KPI cards; 14-day signup series; pending profile preview; recent activity; pending email-change list; approve/reject email change; shortcuts to members, reviews, mentors and activity | GET /api/admin/dashboard; GET /api/admin/profiles/pending; GET /api/admin/activities?take=6; GET /api/admin/email-changes/pending; POST /api/admin/email-changes/{userId}/approve; POST /api/admin/email-changes/{userId}/reject | [~] Implemented; flutter analyze/test passed on code commit 90d99ab788630998160b2db772fcdf338d732d37; live API/device verification pending |
| 2 | /admin/pending-requests — PendingRequestsPage | Pending/Approved/Rejected tabs; search by name/username; submitted-from/to date filters; clear filters; counts; profile detail; photo content; approve; reject with reason; refresh/retry/loading/error/empty states | GET /api/admin/dashboard; GET /api/admin/profiles/pending?status=&search=&fromDate=&toDate=; GET /api/admin/profiles/{profileId}; GET /api/admin/profiles/{profileId}/photos/{photoId}/content; PUT /api/admin/profiles/{profileId}/approve; PUT /api/admin/profiles/{profileId}/reject | [~] Native queue/detail/actions implemented; CI passed; live API/device verification pending |
| 3 | /admin/users — UsersPage | Paginated members; search; role/gender/profile-completion/active/role/gender/profile-completion/active filters; search; paginated profile cards; profile detail and primary photo; activate/deactivate with confirmation; assign/remove mentor; retry/error/empty states. The web page does not render a city filter or user-delete button. | GET /api/admin/users?page=&pageSize=&search=&role=&gender=&isProfileComplete=&isActive=; GET /api/admin/profiles/{profileId}; GET /api/admin/users/{userId}/primary-photo; GET /api/admin/users?role=Mentor&pageSize=500; POST /api/admin/user-mentor-assignments; DELETE /api/admin/user-mentor-assignments/{userId}/{mentorUserId}; PUT /api/admin/users/{userId}/activate; PUT /api/admin/users/{userId}/deactivate. Backend additionally supports city query filtering and DELETE /api/admin/users/{userId} soft-delete, but neither is exposed by this React page. | [ ] Not implemented |
| 4 | /admin/activities — ActivitiesPage | Up to 100 audit entries; client-side text search; activity type/action/entity filters; All/Today/Last 7 Days/Last 30 Days date presets; refresh; row opens detail panel | GET /api/admin/activities?take=100; backend normalizes invalid take to 100 and supports up to 500 | [ ] Not implemented |
| 5 | /admin/reports — ReportsPage | Read-only report list; refresh; loading/error/empty states; reporter, reported member, reason and date. No Admin action buttons found. | GET /api/reports (Admin-only). Separate member operations: POST /api/reports/{reportedUserId}, GET /api/reports/my | [ ] Not implemented |
| 6 | /admin/mentors — MentorManagementPage | Mentor list via Admin users; search; create/edit; active toggle; view mentor profile/location; view assigned members; remove member assignment; delete mentor; mentor photo upload/replace where exposed | GET /api/admin/users?page=1&pageSize=100; POST /api/admin/mentors (multipart); PUT /api/admin/mentors/{userId}; PUT /api/admin/mentors/{userId}/photo (multipart); GET /api/admin/mentors/{mentorUserId}/location; GET /api/admin/mentors/{mentorUserId}/members; DELETE /api/admin/user-mentor-assignments/{userId}/{mentorUserId}; DELETE /api/admin/mentors/{userId}; location selectors use GET /api/locations/countries, /states?countryId=, /cities?stateId= | [ ] Not implemented |
| 7 | /admin/mentor-assignments — AdminMentorAssignmentsPage | Mentor request list; search name/mobile/mentor; Pending/Fulfilled/Rejected/All filters; assign pending request; mentor member-count list; loading/empty/error feedback | GET /api/admin/mentor-user-requests; POST /api/admin/mentor-user-requests/{requestId}/assign; GET /api/admin/mentor-stats | [ ] Not implemented |
| 8 | /admin/master-data — MasterDataPage | Four tabs: Locations, Community, Mother Tongues, Education & Career; refresh; nested master-data panels | Detailed subpages below | [ ] Not implemented |
| 8a | Master Data → Locations | Country/State/City hierarchy; select parent; list/search; city server search with debounce; add/edit; active/inactive; parent validation; no delete UI/API found | GET /api/locations/admin/countries; GET /api/locations/admin/states?countryId=; GET /api/locations/admin/cities?stateId=&search=; POST/PUT /api/locations/admin/countries; POST/PUT /api/locations/admin/states; POST/PUT /api/locations/admin/cities | [ ] Not implemented |
| 8b | Master Data → Community | Religion/Caste/Sub-caste cascading selectors; search; add/edit; active/inactive; parent required for child records; no delete UI/API found | GET /api/reference-data/admin/religions; GET /api/reference-data/admin/castes?religionId=; GET /api/reference-data/admin/sub-castes?casteId=; corresponding POST/PUT routes under /api/reference-data/admin | [ ] Not implemented |
| 8c | Master Data → Mother Tongues | List/search; add/edit; active/inactive; no delete UI/API found | GET /api/reference-data/admin/mother-tongues; POST /api/reference-data/admin/mother-tongues; PUT /api/reference-data/admin/mother-tongues/{id} | [ ] Not implemented |
| 8d | Master Data → Education & Career | Education/Career tabs; Qualifications; Education Fields→Courses; Occupations→Professions; cascading selection; search; add/edit; active/inactive; no delete UI/API found | Admin GET/POST/PUT routes under /api/reference-data/admin for qualifications, education-fields, courses, occupations and professions | [ ] Not implemented |
| 9 | /admin/subscription-plans — AdminSubscriptionPlansPage | List; create/edit; delete with confirmation; name, short description, description, price, duration months, features, active/featured flags, display order | GET /api/subscription-plans/admin/all; POST /api/subscription-plans/admin; PUT /api/subscription-plans/admin/{id}; DELETE /api/subscription-plans/admin/{id}. Backend additionally exposes GET /api/subscription-plans/admin/stats and POST /api/subscription-plans/admin/assign; these are not a payment transaction console and are not exposed as assignment controls on the inspected page. | [ ] Not implemented |
| 10 | /admin/privacy-policy — PrivacyPolicyManagementPage | List; create draft; edit draft; publish; published item locked; refresh/retry; title max 200 characters; details plain text; no delete UI/API found | GET /api/admin/privacy-policies; POST /api/admin/privacy-policies; PUT /api/admin/privacy-policies/{policyId}; POST /api/admin/privacy-policies/{policyId}/publish | [ ] Not implemented |
| 11 | /admin/success-stories — SuccessStoriesPage | List; create/edit/delete; toggle publish; choose husband/wife from member suggestions; married date; message max 600; published flag | GET /api/admin/success-stories; POST /api/admin/success-stories; PUT /api/admin/success-stories/{id}; DELETE /api/admin/success-stories/{id}; member picker GET /api/admin/users?pageSize=200 | [ ] Not implemented |
| 12 | /admin/support — AdminSupportPage | Support ticket list; reply; reply is required; loading/error states | GET /api/admin/support-tickets; POST /api/admin/support-tickets/{id}/reply with body { reply } | [ ] Not implemented |
| 13 | /admin/settings — AdminSettingsPage | Load app settings; select/remove default mentors; enable/disable age-gap rule; configure male/female older/younger ranges; stepper bounds 1–20; save actions | GET /api/admin/settings; PUT /api/admin/settings/default-mentors with { mentorUserIds }; PUT /api/admin/settings/age-gap/{gender} with { olderYears, youngerYears }; PUT /api/admin/settings/age-gap/enabled with { enabled }. Backend also has legacy/specific default-mentor and age-gap routes. | [ ] Not implemented |
| 14 | /admin/profile — AccountSettingsPage embedded | Admin profile menu opens the shared AccountSettingsPage in embedded mode. Its full controls and account API operations require a separate detailed page audit before implementation. | AccountController and account service; exact actions to be documented after full AccountSettingsPage inspection. | [ ] Not implemented |

## 2. Aliases, hidden panels and non-routes

- /admin redirects to /admin/dashboard.
- /admin/locations, /admin/community and /admin/education-career redirect to /admin/master-data; these are tabs/panels, not separate routed screens.
- /admin/mentors/add redirects to /admin/mentors. Mentor creation is inside MentorManagementPage. An older AddMentorPage.tsx exists but is not routed.
- Admin profile menu opens /admin/profile. Logout calls auth logout if a refresh token exists, clears local session and returns to login.
- Admin sidebar items: Dashboard, Profile Reviews, Members, Reports, Activity Log, Mentors, Mentor Requests, Master Data, Subscription Plans, Privacy Policy, Success Stories, Support and Settings.
- AdminLayout loads GET /api/admin/profiles/pending-count on navigation to update the pending badge.

## 3. Backend authorization and API notes

- AdminController route prefix is /api/admin and class-level authorization requires role Admin.
- LocationController and ReferenceDataController require authentication globally; admin subroutes additionally require role Admin.
- SubscriptionPlansController requires authentication globally; admin routes explicitly require role Admin.
- ReportsController requires authentication globally; GET /api/reports explicitly requires role Admin.
- PrivacyPolicyController exposes user policy acceptance; Admin policy management is in AdminController.
- MentorController is Mentor-role protected; it is not the Admin mentor-management API.
- Flutter ApiClient supports authenticated JSON GET/POST/PUT, 401 refresh retry and authenticated binary GET. DELETE, multipart upload and a formal query-parameter helper remain to be added when their pages require them.
- API root is already configured as https://vedicvivah.co.in/api. No base URL change is required.

## 4. Verified DTOs and persistence entities

Verified DTOs:
- Pending review business rules verified in UserProfileRepository: status Pending means SubmittedForReview (not incomplete draft profiles); All includes every active, non-deleted member profile; search matches username/first/last name; date range applies to profile creation date with inclusive end date; the server caps the list at 100. The web client sorts Pending oldest-first and decided lists newest-first.
- Approve handler writes an Administration/ProfileApproved audit log, sends a ProfileApproved notification and invalidates profile/discovery caches. Reject trims reason, enforces 5–1000 characters in the handler, writes an audit log, sends a ProfileRejected notification and invalidates caches.
- AdminDashboardStatsDto: totalMembers, newMembersLast7Days, pendingReviews, approvedProfiles, rejectedProfiles, incompleteProfiles, activeMentors, totalShortlists, signupsLast14Days (date/count).
- AdminPendingProfileDto: profile ID, user ID/name, email, first/last name, gender, date of birth, profession, education, city, about-me, rejection reason, approval status and created time.
- AdminProfileReviewDto: Profile, Photos and RelativeContacts.
- AdminUserDto: user ID/name/mobile/email, role, email/mobile verification, active/deleted, created time, profile ID, names, gender, profession, education, approval/visibility status, profile-complete flag, DOB, city, religion and mentor details.
- SubscriptionPlanDto/CreatePlanRequest fields are reflected in page 9.
- Success story request fields include husband/wife names, married date, message, published flag and optional linked user IDs.
- Support reply body is { reply }; backend rejects blank replies.

Persistence entity names present in the audited backend branch include User, UserProfile, UserPhoto, UserReference, ProfileApprovalStatus, ProfileVisibilityStatus, Mentor, MentorUserRequest, UserMentorAccess, Country, State, City, Religion, Caste, SubCaste, MotherTongue, Qualification, EducationField, Course, Occupation, Profession, AppSetting, AuditLog, Report, SubscriptionPlan, UserSubscription, SuccessStory, SupportTicket, PrivacyPolicy and PrivacyPolicyAcceptance. Exact relationships, cascade rules and deletion constraints still require review in EF configurations/repositories before destructive operations are implemented.

## 5. Confirmed scope gaps — do not invent

- The React Members page does not expose the backend soft-delete user endpoint; Flutter must not add a Delete User button unless the web scope is changed.
- No separate Admin payment/transaction page or payment gateway transaction endpoints were found in the React Admin route/sidebar. The web Admin subscription page manages plans. Backend plan statistics/manual assignment endpoints exist but do not establish a payment-management UI.
- Master-data APIs expose list/create/update; no delete routes were found for locations, community, mother tongues, education or career reference data.
- Privacy policy exposes list/create/edit-draft/publish; no delete action/route found.
- Reports page is read-only; do not invent dismissal, blocking or deletion.
- Support page exposes ticket list/reply; no Admin close/reopen/status mutation was found.
- Do not introduce mock data, new APIs or unverified business rules to fill these gaps.

## 6. Flutter starting state and baseline defect

- Admin feature folders exist with .gitkeep placeholders for dashboard, users, pending requests, activities, mentor management/assignments, master data, subscription plans, privacy policy, reports, success stories, support and settings.
- No native Admin screens currently exist. AuthRoleLandingScreen shows a generic Admin Dashboard placeholder.
- Shared infrastructure already present: ApiClient, AppConfig, secure SessionStore, auth repository and maroon/cream/gold theme.
- Baseline CI on starting HEAD fails at flutter analyze: registration_screen.dart line 166 constructs LoginScreen without its required apiClient. Fix this before treating subsequent CI results as valid.

## 7. Implementation checklist

### Foundation and navigation
- [ ] Fix registration-to-login apiClient analyzer error.
- [ ] Add Admin role routing without changing User or Mentor routing.
- [ ] Build mobile-first Admin shell/navigation drawer and sign-out.
- [ ] Extend authenticated API support for GET/POST/PUT/DELETE, query parameters, multipart upload and protected binary media; test each method.
- [ ] Add Admin DTO parsing and reusable loading/error/empty/retry states.

### Screens
- [~] Dashboard — live KPIs, signup series, pending profiles, audit activity and email-change actions; implementation pushed, awaiting CI and live Admin-session/device verification.
- [~] Profile Reviews — status tabs, search/date filters, detail/photos, approve/reject validation implemented; response-model unit tests and GitHub Actions passed; live Admin API/device verification pending.
- [ ] Members — pagination/search/filters, detail/photo, mentor assignment, activate/deactivate/delete confirmation.
- [ ] Activity Log — search, filters, date presets and detail view.
- [ ] Reports — real Admin report list and refresh.
- [ ] Mentor Management — create/edit/photo/status/location/member list/remove assignment/delete.
- [ ] Mentor Requests — search/status/assign and mentor counts.
- [ ] Master Data / Locations — hierarchical Country/State/City list/create/edit/status/search.
- [ ] Master Data / Community — Religion/Caste/Sub-caste list/create/edit/status.
- [ ] Master Data / Mother Tongues — list/create/edit/status.
- [ ] Master Data / Education & Career — Qualifications, Education Fields/Courses, Occupations/Professions.
- [ ] Subscription Plans — list/create/edit/delete using verified fields.
- [ ] Privacy Policy — list/create/edit/publish and published lock behavior.
- [ ] Success Stories — list/create/edit/delete/publish and member selection.
- [ ] Support — ticket list and reply.
- [ ] Settings — default mentors and age-gap settings.
- [ ] Admin Profile — inspect and implement account settings parity.

### Verification gates
- [x] Unit tests for profile-review DTO parsing passed in GitHub Actions run 43388786654.
- [ ] API request tests for authenticated PUT and binary GET.
- [ ] Widget tests for loading/error/empty/success states, navigation, dialogs and forms.
- [ ] Verify operations against real API using an Admin session; mocks do not count as integration completion.
- [ ] Android build and device smoke test on representative screen sizes.
- [ ] Verify every control works and no overflow/clipping occurs.
- [x] flutter pub get, flutter analyze and flutter test passed in GitHub Actions run 43387728552 for code commit 90d99ab788630998160b2db772fcdf338d732d37.
- [ ] Android build and physical-device smoke test; not run in this environment.
- [ ] Live API verification using a real Admin account; not run.
- [ ] Update this audit with evidence for every completed feature and exact remaining blockers.

## 8. Audit status

**React Admin route/sidebar inventory:** first pass completed.  
**Backend Admin route/authorization inventory:** first pass completed for AdminController, LocationController, ReferenceDataController, SubscriptionPlansController, PrivacyPolicyController, ReportsController and MentorController.  
**Field-by-field DTO, validation, business-rule and EF relationship audit:** in progress; this file does not claim that every rule has been reviewed.  
**Flutter Admin implementation:** in progress; Admin shell, dashboard and Profile Reviews queue/detail/decision flow are pushed. CI analyze/tests pass through commit f68294899cf3daae0dac3a3e971cd05e5e0c810d; live API and Android device verification are pending.  
**Features marked complete:** none yet, because no live Admin-session or Android device verification has been completed. Dashboard and Profile Reviews are implemented in code; GitHub Actions analyze/test passed for the recorded commit. Android device and live Admin API verification remain outstanding.
