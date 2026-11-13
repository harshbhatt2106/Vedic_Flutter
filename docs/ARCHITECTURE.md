# Flutter Architecture

## Architectural approach
Feature-first, role-separated Flutter application with shared infrastructure. The directory layout is a scaffold only; no business logic or screen implementation is included in this architecture commit.

## Top-level ownership
- `lib/app`: app bootstrap, routing, dependency registration and theme entry points.
- `lib/core`: cross-cutting API transport, authentication/session primitives, configuration, errors, storage, upload/media and utilities.
- `lib/shared`: reusable UI components and common presentation patterns.
- `lib/features/auth`: guest authentication and session-facing flows.
- `lib/features/user`: User role experience and user-owned features.
- `lib/features/mentor`: Mentor role experience.
- `lib/features/admin`: Admin role experience.

## Feature module convention
Each feature can grow into:
- `data/`: DTOs, remote data sources and repository implementations.
- `domain/`: entities, repository contracts and use cases when complexity justifies them.
- `presentation/pages/`: route-level screens.
- `presentation/widgets/`: feature-specific widgets.
- `presentation/state/`: state management owned by the feature.

Do not create abstractions without a real use. Keep backend DTOs at the data boundary and map to domain models only where useful. Keep role-specific navigation and authorization separate.

## Rules
1. Mirror existing React routes and backend capabilities; do not invent features.
2. Preserve API contracts documented in `API_MAPPING.md`.
3. Keep JWT refresh and role/session decisions centralized.
4. Keep User, Mentor and Admin route guards separate.
5. Protected media must use authorized API routes, not public upload URLs.
6. Use REST + SignalR for chat; REST is still needed for history and actions.
7. Keep environment-specific API base URLs outside source constants.
8. Do not embed production secrets, Firebase service-account credentials or tokens.
9. No payment integration is documented in this scaffold.
10. Build responsive layouts for mobile first; avoid copying desktop navigation literally.

## Next implementation order
1. Confirm app package, Flutter/Dart versions and state-management choice.
2. Implement environment config and API client.
3. Implement auth/session and role guards.
4. Implement profile/reference-data foundations.
5. Implement user feature flows, then mentor and admin parity.
6. Implement protected media, push registration and SignalR.
7. Add tests against real backend contracts.
