# Car Wash — project context

Last updated: **2026-09-30**. Start here when continuing development. This is a
dated handoff; check the source and current deployment before relying on status.

## Product and architecture

Customers find nearby car washes, select services and slots, book, and track
booking status. Owners submit shops for admin approval, manage availability,
process bookings and walk-ins, and view completed booking value. Administrators
review shops and manage users, bookings and audit history.

| Directory | Stack and responsibility | Start here |
| --- | --- | --- |
| `Frontend_app/` | Flutter/Dart; customer and owner Android/iOS app | [Mobile setup](Frontend_app/Readme.md), `lib/core/services/app_session.dart`, `lib/app.dart` |
| `Backend/` | Express on Firebase Functions v2; Firebase Admin SDK and Firestore | [Backend setup](Backend/Readme.md), `functions/src/app.js`, `functions/index.js` |
| `Admin/` | React 19, TypeScript, Vite, MUI, TanStack Query, Firebase Auth | [Admin setup](Admin/Readme.md), `src/api/client.ts`, `src/context/AuthContext.tsx` |

The mobile and admin apps access business data through authenticated HTTP APIs.
The repository's Firestore rules deny direct client reads/writes. Backend Admin
SDK operations enforce account roles and ownership in middleware and routes.
Add routes to the matching feature router and import the shared Firebase setup
from `Backend/functions/src/config/firebase.js`.

## Environment and URLs

- Firebase project: `car-wash-5d9ce`; project number: `653869969705`.
- HTTP function: `api`, region `asia-south1`.
- Production API base: `https://asia-south1-car-wash-5d9ce.cloudfunctions.net/api`.
  Append `/v1/...`; health is **`/health`**, not `/v1/health`.
- Admin hosting: `https://car-wash-5d9ce-admin.web.app`.
- Android package and iOS bundle: `com.carwash.carwash`.
- Business timezone: `Asia/Kolkata`; money is integer INR paise.
- Local emulator ports in `Backend/firebase.json`: Auth `9099`, Firestore `8080`,
  Functions `5002`, emulator UI `4000`.
- Flutter API configuration: `lib/core/network/api_config.dart`. Supports
  `--dart-define=API_BASE_URL=...`; persisted device URL settings can override it.
- Admin reads `Admin/.env`, not `.env.example`. `VITE_API_URL` is the API base
  without `/v1`. Blank uses same-origin requests; Vite needs `API_PROXY_TARGET`
  for local proxying. Restart Vite after environment changes.
- Admin production builds go to **`Backend/admin-dist/`**, not `Admin/dist/`.
  Hosting rewrites `/v1/**` and `/api/**` to the API before the SPA fallback.

## Authentication and configuration

Phone login uses real Firebase Phone Auth: SMS request, OTP verification,
resend, automatic verification and SDK token refresh. Do not restore the removed
fake OTP or predictable email/password flow. API requests use Firebase ID tokens
in the `Authorization: Bearer` header. Admin uses email/password with the
`superAdmin: true` custom claim, never a publicly assignable profile role.

Phone provider, billing and SMS delivery to India were verified enabled.
Android/iOS Firebase apps and this machine's Android debug signing fingerprints
are registered. Physical-device SMS verification, iOS APNs setup and release/Play
signing fingerprints remain release checks.

These required, generated mobile files are now local and Git-ignored:

- `Frontend_app/lib/firebase_options.dart`
- `Frontend_app/android/app/google-services.json`
- `Frontend_app/ios/Runner/GoogleService-Info.plist`

See the mobile README for `flutterfire configure` instructions. Fresh clones and
CI must generate/restore them before analysis, tests or builds. Do not force-add
them or copy API keys into documentation. Never commit service-account keys or
tokens. Firebase client keys remain visible in installed apps; restrictions and
authorization provide protection, not Git exclusion.

The Android/iOS/browser client keys were inspected on 2026-09-30 and had
Firebase-related API restrictions, with no Generative Language API allowed.
The GitHub alert concerned a Firebase client key. No key was revoked or rotated.
GitHub alert access returned 404; closing the verified client-key alert as false
positive remains manual. Removing tracked files does not erase Git history.

## Implemented workflows and invariants

- **Owner enrollment:** `/v1/me/owner-enrollment` grants owner capability to an
  existing eligible user; it does not grant admin access or activate a shop.
- **Shop onboarding:** real business/contact/address details, explicit map pin
  (FlutterMap/CARTO, GPS or manual coordinates), service prices/durations and
  dated slots. No fabricated shop, location, default service or availability.
- **Atomic submission:** `POST /v1/owner/car-washes/onboarding`; read/correct with
  `GET`/`PUT /v1/owner/car-washes/:id/onboarding`. Use **`car-washes`**, plural.
  Details, services, availability and an idempotency receipt commit together.
- **Retry safety:** persist the exact payload and idempotency key; replay the
  same request after uncertain failure, including across restarts. Never turn
  an uncertain POST into a new PUT that overwrites an intervening review.
- **Shop lifecycle:** new/corrected submissions are `pending_review`; rejected
  shops show feedback and can correct/resubmit the same shop. Suspended shops
  remain blocked from operations but can maintain future availability. Only
  active shops appear to customers. Owner lookup failures expose retry UI and
  must not be interpreted as an empty shop list.
- **Admin review:** fetch current detail/readiness; block approval/reactivation
  until real services and usable future slots exist. Preserve stale-review
  protection with `expectedUpdatedAt` normalized to `{seconds, nanoseconds}`
  from either public or underscored Firestore fields. Preserve nanosecond precision.
- **Bookings and walk-ins:** authenticated, ownership-checked, transactionally
  reserve slots and use idempotency. Availability changes preserve reservations.
  Walk-ins store guest details without creating fake customer accounts.
- **Earnings:** value of completed bookings, not payments collected or payouts.
- **Data integrity:** failed/empty APIs must not fall back to mock shops,
  bookings, slots or earnings. Real FCM delivery is not implemented; do not
  manufacture device tokens or claim notifications are delivered.

## Find the relevant implementation quickly

| Change | Primary files |
| --- | --- |
| OTP and sessions | `Frontend_app/lib/core/services/auth_service.dart`, `app_session.dart`; `lib/features/auth/` |
| Mobile API adapters | `Frontend_app/lib/core/network/api_client.dart`; `lib/core/services/*_api_service.dart` |
| Shop form, drafts, map, dates | `Frontend_app/lib/features/vendor/onboarding/` |
| Owner routing/status gates | `Frontend_app/lib/features/vendor/vendor_shell.dart` |
| Atomic onboarding and readiness | `Backend/functions/src/routes/shop-onboarding.js`, `src/services/shop-onboarding.js` |
| Owner services, slots, walk-ins, earnings | `Backend/functions/src/routes/owner-operations.js`, `owner-shops.js`, `src/services/availability.js` |
| Admin APIs/review | `Backend/functions/src/routes/admin.js`; `Admin/src/components/shops/ReviewModal.tsx`, `OnboardingReadiness.tsx` |
| Admin shop display | `Admin/src/pages/ShopDetail.tsx`, `Approvals.tsx`; `src/types/index.ts` |

Detailed contracts: [Shop onboarding](Backend/docs/SHOP_ONBOARDING.md),
[request schema](Backend/docs/shop-onboarding.schema.json),
[owner operations](Backend/docs/OWNER_OPERATIONS.md),
[frontend integration](Backend/docs/FRONTEND_INTEGRATION.md).

## Verification and deployment

Run checks for the affected component:

```sh
# From the repository root
npm test --prefix Backend/functions
npm run lint --prefix Backend/functions
npm test --prefix Admin
npm run build --prefix Admin

# From Frontend_app (local Firebase configs must exist)
flutter analyze
flutter test
```

The real Auth/Firestore emulator journey covers submission/replay,
rejection/correction, approval, discovery, customer booking and reserved slots:

```sh
# From the repository root; requires Firebase CLI and a supported Java runtime
firebase emulators:exec --config Backend/firebase.json --project demo-car-wash-onboarding --only auth,firestore 'node Backend/functions/scripts/verify-onboarding-emulator.js'
```

Last successful checks: **31 Flutter tests**, **13 backend tests**, **11 admin
tests**, Flutter analysis, backend syntax checks, admin production build and the
onboarding emulator journey. These were run across the recent changes, not as
one release certification. Native APK/iOS builds and real SMS/GPS/map behavior
have not been verified end to end.

Production changes completed on 2026-09-30:

- Deployed `functions:api` after the live onboarding route returned 404. Verified
  `/health` returned 200 and unauthenticated onboarding returned the expected 401.
- Built and deployed `hosting:admin` after the old bundle caused false stale-review
  errors. Verified the live asset matched the tested local build. Existing tabs
  need a hard refresh to pick up the current UI.
- No Firestore rules/index deployment was recorded in this work. The owner
  earnings query needs the composite index in `Backend/firestore.indexes.json`;
  confirm its production state before treating earnings as release-verified.

Deployment commands, from `Backend/`, when deployment is part of the task:

```sh
firebase deploy --only functions:api --project car-wash-5d9ce
# Build Admin first; this publishes Backend/admin-dist
firebase deploy --only hosting:admin --project car-wash-5d9ce
# For index changes
firebase deploy --only firestore:indexes --project car-wash-5d9ce
```

## Remaining work and known limitations

- **Android tooling warning is unresolved.** Current pins: Gradle `8.14.3`, AGP
  `8.11.1`, Kotlin `2.2.20`. Installed Flutter `3.47.4` warns about upcoming minimums
  `9.1.0`, `9.0.1`, `2.3.20` respectively. Investigation was interrupted; no upgrade
  was applied. Check the compatible combination and plugin migration requirements
  before editing. `android.builtInKotlin=false` and `android.newDsl=false` currently
  preserve legacy plugin compatibility. A previous APK build hit a Gradle download
  timeout; the user's later log showed warnings, not an actual compilation error.
- **Backend runtime:** package targets Node 20. Firebase warned during deployment
  that it is deprecated and will be decommissioned on 2026-10-30. Plan a tested
  supported-runtime upgrade; it has not been performed.
- **Device/release setup:** iOS minimum 15, Android minimum 23; APNs credentials,
  push capability, release signing fingerprints and device verification remain.
- **Scope not completed:** real FCM push delivery, payment processing, KYC/license
  uploads and general post-approval business/service editing UI.

Keep this file current when behavior, setup or deployment changes. Record what
was actually verified and retain unresolved items until evidence closes them.
