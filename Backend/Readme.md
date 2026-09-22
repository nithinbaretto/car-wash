# Car Wash Firebase Backend

This folder contains the Firebase Cloud Functions API for the car-wash app.

## Backend layout

```text
functions/
  index.js                 Exports the Firebase HTTP function
  src/
    app.js                 Assembles Express middleware and feature routers
    constants.js           Roles, platforms, and service categories
    config/firebase.js     Initializes Firebase Admin and Firestore once
    middleware/            Authentication, authorization, request IDs, errors
    routes/                Users, discovery, favourites, bookings, notifications,
                           admin, owner shops, and health
    serializers/           User, shop, and booking response shapes
    services/              Booking status/notification helpers and audit records
    utils/                 Validation, geohash, API errors, async handlers
  scripts/
    set-super-admin.js      Manual admin bootstrap
    check-syntax.js         Checks all JavaScript source, scripts, and tests
  tests/app.test.js         Route and HTTP middleware regression checks
```

The public API base URL and existing route paths remain unchanged by this
organization.

Add endpoints to the matching feature router. Shared authorization belongs in
`middleware/`, response shaping in `serializers/`, and reusable business logic
in `services/`. Existing Firestore transactions remain in their feature routers.
Import Firebase through `config/firebase.js`; feature modules must not initialize
their own Firebase app. `src/app.js` exports the Express app for local tests;
only the root `index.js` wraps it in a deployed Firebase Function.

Run checks from `Backend/functions`:

```bash
npm run lint
npm test
```

These tests start a temporary local HTTP server without writing to Firebase.
They verify route registration, health, authentication boundaries, and error
middleware. Database workflows still require Firebase Emulator integration tests.

## One-time setup

1. Create a Firebase project in the Firebase Console.
2. Replace `YOUR_FIREBASE_PROJECT_ID` in `.firebaserc` with its project ID.
3. Install the Firebase CLI and sign in:

   ```bash
   npm install -g firebase-tools
   firebase login
   ```

4. Install the backend dependencies:

   ```bash
   cd Backend/functions
   npm install
   ```

## Run locally

```bash
cd Backend
firebase emulators:start --only functions,firestore
```

The health-check endpoint is available at:

```text
http://127.0.0.1:5002/YOUR_FIREBASE_PROJECT_ID/asia-south1/api/health
```

## Deploy

```bash
cd Backend
firebase deploy --only functions,firestore
```

After deployment, test:

```text
https://asia-south1-YOUR_FIREBASE_PROJECT_ID.cloudfunctions.net/api/health
```

## Customer onboarding API

Phone OTP, Google, and Apple sign-in are handled by Firebase Authentication in
the mobile app. Send the resulting ID token to every protected endpoint:

```text
Authorization: Bearer <firebase-id-token>
```

| Method | Endpoint | Purpose |
| --- | --- | --- |
| `POST` | `/api/v1/me/onboarding` | Creates the authenticated user profile. |
| `GET` | `/api/v1/me` | Returns the authenticated user profile. |
| `PATCH` | `/api/v1/me` | Updates the name or profile photo. |
| `PUT` | `/api/v1/me/active-role` | Switches to an already granted role. |
| `POST` | `/api/v1/me/devices` | Registers a device for future push notifications. |

Example onboarding request:

```json
{
  "displayName": "Shamil P",
  "initialRole": "customer",
  "acceptedTermsVersion": "2026-09-20",
  "acceptedPrivacyVersion": "2026-09-20"
}
```

Choosing `owner` enables the owner to create and manage their own shop.
Future staff accounts will require an approved shop membership before they can
manage bookings.

## Owner shop setup API

The authenticated profile must have the `owner` role. Shop locations come from
the Google Maps picker in the mobile app; the API saves the formatted address,
latitude, longitude, Firestore `GeoPoint`, and derived geohash.

| Method | Endpoint | Purpose |
| --- | --- | --- |
| `POST` | `/api/v1/owner/car-washes` | Creates a car-wash shop. |
| `GET` | `/api/v1/owner/car-washes` | Lists shops managed by the owner. |
| `GET` | `/api/v1/owner/car-washes/:carWashId` | Returns one managed shop. |
| `PATCH` | `/api/v1/owner/car-washes/:carWashId` | Updates shop details or map location. |
| `POST` | `/api/v1/owner/car-washes/:carWashId/services` | Adds a service and price in paise. |
| `PUT` | `/api/v1/owner/car-washes/:carWashId/availability/:date` | Saves daily booking slots. |

Example shop-location payload within shop creation or update:

```json
{
  "address": {
    "line1": "80 Feet Road",
    "area": "Koramangala",
    "city": "Bengaluru",
    "state": "Karnataka",
    "postalCode": "560034",
    "formattedAddress": "80 Feet Road, Koramangala, Bengaluru, Karnataka 560034"
  },
  "location": {
    "latitude": 12.9352,
    "longitude": 77.6245,
    "placeId": "google-place-id-optional"
  }
}
```

## Customer discovery API

All discovery endpoints require the same Firebase ID token as onboarding.

| Method | Endpoint | Purpose |
| --- | --- | --- |
| `GET` | `/api/v1/categories` | Returns the supported wash categories. |
| `GET` | `/api/v1/car-washes/nearby?latitude=&longitude=` | Finds active shops within a radius. |
| `GET` | `/api/v1/car-washes/:carWashId` | Returns public shop details and active services. |
| `GET` | `/api/v1/car-washes/:carWashId/availability?date=YYYY-MM-DD` | Returns bookable slots. |
| `GET` | `/api/v1/me/favourites` | Returns saved active shops. |
| `PUT` | `/api/v1/me/favourites/:carWashId` | Saves a shop idempotently. |
| `DELETE` | `/api/v1/me/favourites/:carWashId` | Removes a saved shop idempotently. |

Nearby search accepts `latitude`, `longitude`, optional `radiusKm` (default 5,
maximum 10), category, and `limit` (maximum 50). The backend uses geohash
bounds followed by an exact distance calculation, so shops across geohash-cell
boundaries are not missed.

## Booking and notification APIs

Bookings begin as `pending`; the car-wash owner must manually accept or reject
them. Booking creation requires an `Idempotency-Key` header.

| Method | Endpoint | Purpose |
| --- | --- | --- |
| `POST` | `/api/v1/bookings` | Reserves an available slot as `pending`. |
| `GET` | `/api/v1/me/bookings?tab=ongoing\|completed` | Lists customer bookings. |
| `POST` | `/api/v1/bookings/:bookingId/cancel` | Cancels a pending booking and releases capacity. |
| `GET` | `/api/v1/owner/car-washes/:carWashId/bookings?date=YYYY-MM-DD` | Owner booking queue. |
| `POST` | `/api/v1/owner/bookings/:bookingId/status` | Accepts, rejects, starts, or completes a booking. |
| `GET` | `/api/v1/me/notifications` | Customer notification feed. |
| `POST` | `/api/v1/me/notifications/read` | Marks selected or all notifications as read. |

## Super-admin bootstrap

Super-admin access is granted only through a Firebase custom claim, never by a
public API. Authenticate locally with Google Cloud Application Default
Credentials or set `GOOGLE_APPLICATION_CREDENTIALS` to a service-account file
that is not committed to Git, then run:

```bash
cd Backend/functions
node scripts/set-super-admin.js YOUR_FIREBASE_AUTH_UID
```

The user must sign out and sign in again afterwards so Firebase issues an ID
token containing the new `superAdmin` claim.
# Integration handoff

- [cURL requests for all registered APIs](docs/API_CURL.md)
- [Importable Postman collection](docs/car-wash.postman_collection.json)
- [Frontend screen mapping and remaining gaps](docs/FRONTEND_INTEGRATION.md)
