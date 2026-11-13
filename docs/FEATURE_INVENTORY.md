# Feature Inventory — Web-to-Flutter parity

**Source UI:** `vedicvivah-frontend` branch `FainalFrontend`, route configuration `src/routes/AppRoutes.tsx`.  
**Source API:** `vedicvivah-backend` branch `FainalBak`.  
This inventory describes existing web routes and features only. It is not a promise that every route is independently implemented as a native screen; redirects are identified separately.

## Public and authentication
| Role | Web route | Existing page | Backend/API |
|---|---|---|---|
| Public | `/` | HomePage | `GET /public/success-stories`; public mentor lookups where used |
| Guest | `/login` | LoginPage | `POST /auth/login` |
| Guest | `/register` | CreateAccountPage | `POST /auth/register`, verify/resend OTP |
| Guest | `/forgot-password` | ForgotPasswordPage | forgot/verify/resend/reset password endpoints |

## User area
| Role | Web route | Existing page | Backend/API |
|---|---|---|---|
| User | `/dashboard` | DashboardPage | `GET /user/dashboard` |
| User | `/profile` | ProfilePage | `/user-profile`, photos, references, reference data |
| User | `/preferences` | PartnerPreferencesPage | `GET/PUT /partner-preferences` |
| User | `/shortlisted` | ShortlistPage | `/shortlists` |
| User | `/interests` | InterestsPage | `/interests` |
| User | `/blocked` | BlockedUsersPage | `/blocks` |
| User | `/my-reports` | MyReportsPage | `GET /reports/my`, `POST /reports/{reportedUserId}` |
| User | `/messages` | MessagesPage | `/conversations`, SignalR chat hub |
| User | `/notifications` | NotificationPage | `/notifications`, device tokens |
| User | `/account/settings` | AccountSettingsPage | `/account` |
| User | `/support` | SupportPage | `/support/tickets` |
| User | `/plans` | PlansPage | `/subscription-plans`, `/subscription-plans/my-subscription` |

## Mentor area
| Role | Web route | Existing page | Backend/API |
|---|---|---|---|
| Mentor | `/mentor/dashboard` | MentorDashboardPage | Mentor summary/directory endpoints |
| Mentor | `/mentor/my-members` | MentorMyMembersPage | `/mentor/created-profiles`, member conversations |
| Mentor | `/mentor/request-members` | MentorRequestMembersPage | `/mentor/users/*`, `/mentor/user-requests` |
| Mentor | `/mentor/shared` | MentorSharedProfilesPage | `/mentor/shares/*`, share/revoke |
| Mentor | `/mentor/profile` | MentorProfilePage | Mentor profile/photo endpoints |

## Admin area
| Role | Web route | Existing page | Backend/API |
|---|---|---|---|
| Admin | `/admin/dashboard` | AdminDashboardPage | `GET /admin/dashboard` |
| Admin | `/admin/pending-requests` | PendingRequestsPage | pending profiles, approvals/rejections, pending email changes |
| Admin | `/admin/users` | UsersPage | `/admin/users`, activate/deactivate/delete |
| Admin | `/admin/activities` | ActivitiesPage | `GET /admin/activities` |
| Admin | `/admin/reports` | ReportsPage | `GET /reports` |
| Admin | `/admin/mentors` | MentorManagementPage | `/admin/mentors` |
| Admin | `/admin/master-data` | MasterDataPage | reference-data and location admin endpoints |
| Admin | `/admin/settings` | AdminSettingsPage | `/admin/settings` |
| Admin | `/admin/privacy-policy` | PrivacyPolicyManagementPage | `/admin/privacy-policies` |
| Admin | `/admin/success-stories` | SuccessStoriesPage | `/admin/success-stories` |
| Admin | `/admin/mentor-assignments` | AdminMentorAssignmentsPage | assignment, mentor stats and members endpoints |
| Admin | `/admin/support` | AdminSupportPage | `/admin/support-tickets` |
| Admin | `/admin/subscription-plans` | AdminSubscriptionPlansPage | `/subscription-plans/admin/*` |
| Admin | `/admin/profile` | AccountSettingsPage (embedded) | `/account` |

## Redirect-only routes (do not create separate feature screens)
- `/profile/complete` redirects to `/profile`.
- `/admin` redirects to `/admin/dashboard`.
- `/admin/locations`, `/admin/community`, `/admin/education-career` redirect to `/admin/master-data`.
- `/admin/mentors/add` redirects to `/admin/mentors`.
- Unknown paths redirect to `/login`.

## Feature groups and page ownership

- Auth: login, registration, email OTP verification, forgot/reset password, session and token refresh.
- User: dashboard, discover/matching, profile sections, photo gallery, partner preferences, shortlist, interests, blocks, reports, chat, notifications, account settings, privacy acceptance, support and plans.
- Mentor: dashboard, directory/profile viewing, own/created member profiles, member requests, colleague sharing, read-only chat monitoring, mentor photo.
- Admin: dashboard, user/profile moderation, activities/audit, reports, mentor management and assignments, master data, settings, privacy policies, success stories, support queue, subscription plan management.
- Shared: API client, auth/session, reference data models, protected media, validation, error mapping and reusable widgets.

## Scope notes
- The route list is based on the actual React router, not an inferred sitemap.
- Some user capabilities are nested tabs/sections inside a page rather than separate top-level routes.
- The backend has more endpoint capabilities than top-level web routes; the API mapping lists those separately.
- This architecture stage creates directories and docs only. No Flutter screens, networking implementation, fake data, or new product behavior is added.
