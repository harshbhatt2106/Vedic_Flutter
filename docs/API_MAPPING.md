# API Mapping — VedicVivah Flutter

**Source backend:** `harshbhatt2106/vedicvivah-backend` @ `FainalBak`  
**Source frontend:** `harshbhatt2106/vedicvivah-frontend` @ `FainalFrontend`  
**Base path:** `/api` (the deployment base URL is environment-specific; do not hard-code it).

This document maps endpoints observed in backend controller source. The frontend uses an Axios client with relative paths, so Flutter should preserve these paths and the backend's request/response contracts. Confirm DTO fields from the controller/application source before implementing each call.

## Authentication and transport

- Authentication: JWT bearer access token; backend validates issuer, audience, signature and lifetime.
- Roles: `Admin`, `User`, `Mentor`; several controllers require any authenticated user.
- Refresh/logout: refresh token is sent in the request body by the web client.
- Chat: SignalR hub at `/api/hubs/chat`; JWT may be supplied as `access_token` query parameter for hub negotiation/connection.
- Uploads: use multipart form-data; do not expose raw `/uploads` paths. Backend intentionally blocks direct unauthenticated access and serves protected media through controller actions.
- Common response envelope is usually `{ success, data, message }`; verify each action because file responses and some actions differ.
- Respect 401/403/404/409/429 and validation responses. Auth routes have a stricter rate limiter; general requests are also rate-limited.

## Endpoint catalogue

### Authentication — `AuthController` — anonymous/public actions
| Method | Path | Purpose / request model |
|---|---|---|
| POST | `/auth/register` | Register; `RegisterRequest` |
| POST | `/auth/verify-email` | Verify registration OTP; `VerifyEmailRequest` |
| POST | `/auth/resend-email-otp` | Resend registration OTP; `ResendEmailOtpRequest` |
| POST | `/auth/forgot-password` | Start password reset; `ForgotPasswordRequest` |
| POST | `/auth/verify-password-reset-otp` | Verify reset OTP; `VerifyPasswordResetOtpRequest` |
| POST | `/auth/resend-password-reset-otp` | Resend reset OTP; `ResendPasswordResetOtpRequest` |
| POST | `/auth/reset-password` | Complete reset; `ResetPasswordRequest` |
| POST | `/auth/login` | Login; `LoginRequest` |
| POST | `/auth/refresh` | Refresh JWT; `RefreshTokenRequest` |
| POST | `/auth/logout` | Revoke refresh token; `RefreshTokenRequest` |

### Account — `AccountController` — authenticated
| Method | Path | Purpose / request model |
|---|---|---|
| GET | `/account` | Account settings |
| GET | `/account/username-availability` | Query: username |
| PUT | `/account/name` | `UpdateNameRequest` |
| PUT | `/account/username` | `UpdateUsernameRequest` |
| POST | `/account/email-change` | `RequestEmailChangeRequest` |
| POST | `/account/email-change/verify` | `VerifyEmailChangeRequest` |
| POST | `/account/email-change/resend` | `ResendEmailChangeOtpRequest` |
| PUT | `/account/profile-picture` | Multipart: photo |
| PUT | `/account/password` | `ChangePasswordRequest` |
| POST | `/account/deactivate` | Deactivate own account |
| DELETE | `/account` | Query: isMarried; delete own account |

### User profile — `UserProfileController` — authenticated
| Method | Path | Purpose |
|---|---|---|
| GET | `/user-profile` | Get own profile |
| GET | `/user-profile/discover` | Discover/search profiles; filters and pagination |
| GET | `/user-profile/photos` | List own photos |
| POST | `/user-profile/photos` | Upload photo; multipart |
| GET | `/user-profile/{userId}` | View permitted profile |
| GET | `/user-profile/{userId}/primary-photo` | Protected primary photo |
| GET | `/user-profile/{userId}/photos` | View permitted photo metadata |
| GET | `/user-profile/{userId}/photos/{photoId}/content` | Protected photo content |
| GET | `/user-profile/photos/{photoId}/content` | Own protected photo content |
| DELETE | `/user-profile/photos/{photoId}` | Delete own photo |
| PUT | `/user-profile/photos/{photoId}/primary` | Set primary photo |
| POST | `/user-profile/submit-for-review` | Submit profile for review |
| PATCH | `/user-profile/personal` | Save personal information |
| PATCH | `/user-profile/community` | Save community information |
| PATCH | `/user-profile/education-career` | Save education/career |
| PATCH | `/user-profile/family` | Save family details |
| PATCH | `/user-profile/location-residence` | Save location/residence |
| PATCH | `/user-profile/visibility` | Set visibility; `SetVisibilityRequest` |
| PATCH | `/user-profile/about` | Save about section; `SaveAboutMeRequest` |
| PUT | `/user-profile` | Save complete profile; `SaveUserProfileRequest` |

### User, matching and preferences
| Controller / role | Method | Path | Purpose |
|---|---|---|---|
| User (User) | GET | `/user/dashboard` | User dashboard |
| User (User) | GET | `/user/mentors` | Mentor directory |
| User (User) | GET | `/user/mentor` | Current mentor |
| User (User) | GET | `/user/mentors/assigned` | Assigned mentors |
| User (User) | GET | `/user/mentor/suggestion` | Mentor suggestion |
| User (User) | POST | `/user/mentor` | Select mentor; `SelectMentorRequest` |
| PartnerPreferences (authenticated) | GET | `/partner-preferences` | Get preferences |
| PartnerPreferences (authenticated) | PUT | `/partner-preferences` | Save preferences; `SavePartnerPreferenceRequest` |
| Interests (authenticated) | GET | `/interests/sent` | Sent interests |
| Interests (authenticated) | GET | `/interests/received` | Received interests |
| Interests (authenticated) | GET | `/interests/received/pending-count` | Pending count |
| Interests (authenticated) | GET | `/interests/status/{targetUserId}` | Interest status |
| Interests (authenticated) | POST | `/interests/{targetUserId}` | Send interest |
| Interests (authenticated) | PUT | `/interests/{interestId}/accept` | Accept |
| Interests (authenticated) | PUT | `/interests/{interestId}/reject` | Reject |
| Interests (authenticated) | GET | `/interests/connections/search` | Search connections |
| Interests (authenticated) | PUT | `/interests/{interestId}/resubmit` | Resubmit rejected interest |
| Interests (authenticated) | DELETE | `/interests/{interestId}` | Withdraw |
| Shortlists (authenticated) | GET | `/shortlists` | List shortlisted profiles |
| Shortlists (authenticated) | GET | `/shortlists/status/{shortlistedUserId}` | Check shortlist status |
| Shortlists (authenticated) | POST | `/shortlists/{shortlistedUserId}` | Add |
| Shortlists (authenticated) | DELETE | `/shortlists/{shortlistedUserId}` | Remove |
| Blocks (authenticated) | GET | `/blocks` | List blocked users |
| Blocks (authenticated) | GET | `/blocks/status/{blockedUserId}` | Check block status |
| Blocks (authenticated) | POST | `/blocks/{blockedUserId}` | Block; `AddBlockRequest` |
| Blocks (authenticated) | DELETE | `/blocks/{blockedUserId}` | Unblock |
| Reports (authenticated) | POST | `/reports/{reportedUserId}` | Submit report; `SubmitReportRequest` |
| Reports (authenticated) | GET | `/reports/my` | My reports |
| Reports (Admin) | GET | `/reports` | All reports |

### Messaging, notifications and device registration
| Controller / role | Method | Path | Purpose |
|---|---|---|---|
| Conversations (authenticated) | GET | `/conversations` | Conversation list |
| Conversations (authenticated) | POST | `/conversations/{otherUserId}` | Get/create conversation |
| Conversations (authenticated) | GET | `/conversations/{conversationId}/messages` | Message history; take/before query |
| Conversations (authenticated) | POST | `/conversations/{conversationId}/messages` | Send; `SendMessageRequest` |
| Conversations (authenticated) | PUT | `/conversations/{conversationId}/read` | Mark read |
| Conversations (authenticated) | DELETE | `/conversations/{conversationId}/messages/{messageId}` | Delete message |
| Conversations (authenticated) | DELETE | `/conversations/{conversationId}` | Delete conversation |
| Conversations (authenticated) | GET | `/conversations/{conversationId}/photo` | Conversation photo |
| Conversations (authenticated) | GET | `/conversations/unread-count` | Unread message count |
| Notifications (authenticated) | GET | `/notifications` | List; take query |
| Notifications (authenticated) | GET | `/notifications/unread-count` | Unread count |
| Notifications (authenticated) | PUT | `/notifications/{notificationId}/read` | Mark one read |
| Notifications (authenticated) | PUT | `/notifications/read-all` | Mark all read |
| DeviceTokens (authenticated) | POST | `/device-tokens` | Register push token; `RegisterTokenRequest` |
| DeviceTokens (authenticated) | DELETE | `/device-tokens` | Unregister push token |
| SignalR | — | `/hubs/chat` | Hub endpoint is mounted at `/api/hubs/chat`; JWT access_token query support |

### Mentor — `MentorController` — Mentor role
| Method | Path | Purpose |
|---|---|---|
| GET | `/mentor/profiles` | Profile directory; search query |
| GET | `/mentor/profiles/{profileId}` | Profile detail |
| GET | `/mentor/profiles/{profileId}/photos/{photoId}/content` | Protected photo |
| GET | `/mentor/profiles/{profileId}/primary-photo` | Protected primary photo |
| GET | `/mentor/colleagues` | Mentor colleagues |
| GET | `/mentor/shares/sent` | Sent profile shares |
| GET | `/mentor/shares/received` | Received profile shares |
| DELETE | `/mentor/shares/{shareId}` | Revoke share |
| POST | `/mentor/profiles/{userId}/share` | Share; `ShareProfileRequest` |
| GET | `/mentor/created-profiles` | Profiles created by mentor |
| GET | `/mentor/users/unassigned` | Unassigned members |
| GET | `/mentor/users/search` | Search assignable members |
| POST | `/mentor/user-requests` | Request member assignment; `CreateUserRequestBody` |
| GET | `/mentor/user-requests` | My assignment requests |
| GET | `/mentor/members/{memberUserId}/conversations` | Read-only member conversations |
| GET | `/mentor/members/{memberUserId}/conversations/{conversationId}/messages` | Read-only messages; take/before |
| PUT | `/mentor/photo` | Upload mentor photo; multipart |

### Admin — `AdminController` — Admin role
| Method | Path | Purpose / request model |
|---|---|---|
| GET | `/admin/dashboard` | Dashboard summary |
| GET | `/admin/users` | User management/list |
| GET | `/admin/activities` | Activity/audit feed |
| GET | `/admin/profiles/pending-count` | Pending profile count |
| GET | `/admin/profiles/pending` | Pending profiles |
| GET | `/admin/profiles/{profileId}` | Profile review details |
| GET | `/admin/users/{userId}/primary-photo` | Protected primary photo |
| GET | `/admin/profiles/{profileId}/photos/{photoId}/content` | Protected photo |
| POST | `/admin/mentors` | Create mentor; `CreateMentorRequest` |
| PUT | `/admin/mentors/{userId}/photo` | Mentor photo; multipart |
| PUT | `/admin/mentors/{userId}` | Update mentor; `UpdateMentorRequest` |
| GET | `/admin/mentors/{mentorUserId}/location` | Mentor location |
| DELETE | `/admin/mentors/{userId}` | Delete mentor |
| GET | `/admin/email-changes/pending` | Pending email changes |
| POST | `/admin/email-changes/{userId}/approve` | Approve email change |
| POST | `/admin/email-changes/{userId}/reject` | Reject email change |
| PUT | `/admin/profiles/{profileId}/approve` | Approve profile |
| PUT | `/admin/profiles/{profileId}/reject` | Reject; `RejectProfileRequest` |
| PUT | `/admin/users/{userId}/activate` | Activate account |
| PUT | `/admin/users/{userId}/deactivate` | Deactivate account |
| DELETE | `/admin/users/{userId}` | Delete user |
| GET | `/admin/settings` | Admin settings |
| PUT | `/admin/settings/default-mentor` | Set default mentor; `SetDefaultMentorRequest` |
| PUT | `/admin/settings/default-mentors` | Set default mentors; `SetDefaultMentorsRequest` |
| PUT | `/admin/settings/age-gap` | Set age gap; `SetAgeGapRequest` |
| PUT | `/admin/settings/age-gap/male` | Set male age range; `SetAgeGapRangeRequest` |
| PUT | `/admin/settings/age-gap/female` | Set female age range; `SetAgeGapRangeRequest` |
| PUT | `/admin/settings/age-gap/enabled` | Enable/disable age-gap rule; `SetAgeGapEnabledRequest` |
| GET | `/admin/success-stories` | List stories |
| POST | `/admin/success-stories` | Create; `SuccessStoryRequest` |
| PUT | `/admin/success-stories/{id}` | Update; `UpdateSuccessStoryRequest` |
| DELETE | `/admin/success-stories/{id}` | Delete |
| GET | `/admin/mentor-user-requests` | Assignment requests |
| POST | `/admin/mentor-user-requests/{requestId}/assign` | Assign request |
| GET | `/admin/users/search` | Search users for assignment |
| POST | `/admin/user-mentor-assignments` | Assign user; `AssignUserToMentorRequest` |
| GET | `/admin/mentor-stats` | Mentor statistics |
| DELETE | `/admin/user-mentor-assignments/{userId}/{mentorUserId}` | Remove assignment |
| GET | `/admin/mentors/{mentorUserId}/members` | Mentor members |
| GET | `/admin/support-tickets` | Support ticket queue |
| POST | `/admin/support-tickets/{id}/reply` | Reply; `SupportReplyRequest` |
| GET | `/admin/privacy-policies` | Policy management |
| POST | `/admin/privacy-policies` | Create; `PrivacyPolicyRequest` |
| PUT | `/admin/privacy-policies/{policyId}` | Update; `PrivacyPolicyRequest` |
| POST | `/admin/privacy-policies/{policyId}/publish` | Publish policy |

### Master/reference data
- `GET /locations/countries`, `GET /locations/states`, `GET /locations/cities` — authenticated location lookups.
- Admin location CRUD: `GET /locations/admin/countries|states|cities`, `POST /locations/admin/countries|states|cities`, `PUT /locations/admin/countries/{id}`, `PUT /locations/admin/states/{id}`, `PUT /locations/admin/cities/{id}` — Admin role.
- Authenticated reference lookups: `GET /reference-data/religions`, `castes`, `sub-castes`, `qualifications`, `mother-tongues`, `education-fields`, `courses`, `occupations`, `professions`.
- Admin reference-data list/create/update routes use `/reference-data/admin/{resource}` for religions, castes, sub-castes, qualifications, mother-tongues, education-fields, courses, occupations and professions. Create is POST; update is PUT `/{id}`; Admin role required.

### Remaining services
| Controller / role | Method | Path | Purpose |
|---|---|---|---|
| PrivacyPolicy (authenticated) | GET | `/privacy-policy/pending-acceptance` | Policies requiring acceptance |
| PrivacyPolicy (authenticated) | POST | `/privacy-policy/accept-all` | Accept all pending |
| PrivacyPolicy (authenticated) | POST | `/privacy-policy/{policyId}/accept` | Accept one |
| Public (anonymous) | GET | `/public/success-stories` | Public success stories |
| Public (anonymous) | GET | `/public/mentor-nearby` | Nearby mentor lookup |
| Public (anonymous) | GET | `/public/mentor-contact/{userId}` | Mentor contact details |
| Public (anonymous) | GET | `/public/mentor-photo/{userId}` | Mentor photo |
| Support (User role) | POST | `/support/tickets` | Submit ticket; `SubmitTicketRequest` |
| Support (User role) | GET | `/support/tickets` | My tickets |
| UserReferences (authenticated) | GET | `/user-references` | List references |
| UserReferences (authenticated) | POST | `/user-references` | Create; `SaveUserReferenceRequest` |
| UserReferences (authenticated) | PUT | `/user-references/{referenceId}` | Update; `SaveUserReferenceRequest` |
| UserReferences (authenticated) | DELETE | `/user-references/{referenceId}` | Delete |
| SubscriptionPlans (authenticated) | GET | `/subscription-plans` | Plans; action allows anonymous |
| SubscriptionPlans (authenticated) | GET | `/subscription-plans/my-subscription` | Current subscription |
| SubscriptionPlans (Admin) | GET | `/subscription-plans/admin/all` | All plans |
| SubscriptionPlans (Admin) | GET | `/subscription-plans/admin/stats` | Subscription statistics |
| SubscriptionPlans (Admin) | POST | `/subscription-plans/admin` | Create plan; `CreatePlanRequest` |
| SubscriptionPlans (Admin) | PUT | `/subscription-plans/admin/{id}` | Update plan |
| SubscriptionPlans (Admin) | DELETE | `/subscription-plans/admin/{id}` | Delete plan |
| SubscriptionPlans (Admin) | POST | `/subscription-plans/admin/assign` | Assign subscription; `AssignSubscriptionRequest` |

## Implementation guardrails

1. No endpoint should be inferred from a screen name. Use this catalogue plus backend source.
2. Preserve HTTP verb, route, query names, multipart field names and DTO casing/shape.
3. Keep access/refresh token lifecycle centralized; never scatter token parsing across pages.
4. Protected profile images must be fetched through authorized endpoints and handled as authenticated bytes/streams.
5. The Flutter chat client must implement both REST history/send and SignalR realtime behavior; do not treat the hub as a REST endpoint.
6. Do not add payment gateway calls: no payment endpoint was found in the inspected controller catalogue.
7. Before implementation, inspect the specific controller action and corresponding Application command/query/DTO for full validation and response semantics.
