# API cURL collection

Run individual requests, not this entire document. Defaults target local emulators. Never use production tokens against an untrusted server.

```sh
export baseUrl='http://127.0.0.1:5002/car-wash-5d9ce/asia-south1/api'
export token='REPLACE_WITH_CUSTOMER_FIREBASE_ID_TOKEN'
export ownerToken='REPLACE_WITH_OWNER_FIREBASE_ID_TOKEN'
export adminToken='REPLACE_WITH_SUPER_ADMIN_FIREBASE_ID_TOKEN'
export shopId='REPLACE'
export serviceId='REPLACE'
export bookingId='REPLACE'
export userId='REPLACE'
export date='REPLACE_WITH_FUTURE_YYYY-MM-DD'
export idempotencyKey='REPLACE_WITH_UNIQUE_REQUEST_ID'
```

Production URL (only after successful deployment): `https://asia-south1-car-wash-5d9ce.cloudfunctions.net/api`.

## Authentication

Phone OTP, Google and Apple sign-in belong to Firebase Auth in the app. Send the resulting Firebase ID token, not a Google access token. Refresh on expiry. For local testing only, create an email/password account in the Auth Emulator UI, then sign in:

```sh
AUTH_RESPONSE=$(curl -sS -X POST 'http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=fake-api-key' -H 'Content-Type: application/json' -d '{"email":"customer@test.local","password":"TestPass123!","returnSecureToken":true}')
token=$(printf '%s' "$AUTH_RESPONSE" | jq -er '.idToken // error("Sign-in failed; inspect error response")')
```

Repeat for a separate owner account, assigning `ownerToken`. Onboard it with `initialRole: owner` and its token. Admin requires the server-managed `superAdmin: true` claim (see existing README/script); signing in as owner does not grant admin. Refresh the admin token after setting its claim. Emulator tokens are invalid in production.

## Suggested integration sequence

Customer sign-in → onboarding (once) → profile. Owner sign-in → owner onboarding → create shop → create service → set future slots → admin approval → customer discovery → booking → owner manual acceptance → in_progress → completed. Copy IDs from response bodies into the variables above. A customer booking starts pending; never show it as accepted immediately. Cancellation only works while pending. Retry the same booking with the same idempotency key; use a fresh key for each new booking.

Success responses use `{success:true,data,requestId}` except DELETE 204 with no body. Errors use `{success:false,error,requestId}`. Check HTTP status before parsing data. List limits are not pagination cursors.

## Health

```sh
curl -sS -i -X GET "${baseUrl}/health"
```

## Onboard

```sh
curl -sS -i -X POST "${baseUrl}/v1/me/onboarding" \
  -H "Authorization: Bearer ${token}" \
  -H 'Content-Type: application/json' \
  --data "{\"displayName\":\"Test Customer\",\"initialRole\":\"customer\",\"acceptedTermsVersion\":\"v1\",\"acceptedPrivacyVersion\":\"v1\"}"
```

## Profile

```sh
curl -sS -i -X GET "${baseUrl}/v1/me" \
  -H "Authorization: Bearer ${token}"
```

## Edit profile

```sh
curl -sS -i -X PATCH "${baseUrl}/v1/me" \
  -H "Authorization: Bearer ${token}" \
  -H 'Content-Type: application/json' \
  --data "{\"displayName\":\"Test Customer\",\"photoUrl\":null}"
```

## Enroll owner

```sh
curl -sS -i -X POST "${baseUrl}/v1/me/owner-enrollment" \
  -H "Authorization: Bearer ${token}" \
  -H 'Content-Type: application/json' \
  --data "{}"
```

## Switch role

```sh
curl -sS -i -X PUT "${baseUrl}/v1/me/active-role" \
  -H "Authorization: Bearer ${token}" \
  -H 'Content-Type: application/json' \
  --data "{\"activeRole\":\"customer\"}"
```

## Register device

```sh
curl -sS -i -X POST "${baseUrl}/v1/me/devices" \
  -H "Authorization: Bearer ${token}" \
  -H 'Content-Type: application/json' \
  --data "{\"installationId\":\"test-device\",\"fcmToken\":\"REPLACE_WITH_FCM_TOKEN\",\"platform\":\"android\"}"
```

## Remove device

```sh
curl -sS -i -X DELETE "${baseUrl}/v1/me/devices/test-device" \
  -H "Authorization: Bearer ${token}"
```

## Categories

```sh
curl -sS -i -X GET "${baseUrl}/v1/categories" \
  -H "Authorization: Bearer ${token}"
```

## Nearby

```sh
curl -sS -i -X GET "${baseUrl}/v1/car-washes/nearby?latitude=12.9352&longitude=77.6245&radiusKm=5&category=quick&limit=20" \
  -H "Authorization: Bearer ${token}"
```

## Shop detail

```sh
curl -sS -i -X GET "${baseUrl}/v1/car-washes/${shopId}" \
  -H "Authorization: Bearer ${token}"
```

## Available slots

```sh
curl -sS -i -X GET "${baseUrl}/v1/car-washes/${shopId}/availability?date=${date}" \
  -H "Authorization: Bearer ${token}"
```

## Favourites

```sh
curl -sS -i -X GET "${baseUrl}/v1/me/favourites?limit=20" \
  -H "Authorization: Bearer ${token}"
```

## Save favourite

```sh
curl -sS -i -X PUT "${baseUrl}/v1/me/favourites/${shopId}" \
  -H "Authorization: Bearer ${token}"
```

## Remove favourite

```sh
curl -sS -i -X DELETE "${baseUrl}/v1/me/favourites/${shopId}" \
  -H "Authorization: Bearer ${token}"
```

## Create booking

```sh
curl -sS -i -X POST "${baseUrl}/v1/bookings" \
  -H "Authorization: Bearer ${token}" \
  -H "Idempotency-Key: ${idempotencyKey}" \
  -H 'Content-Type: application/json' \
  --data "{\"carWashId\":\"${shopId}\",\"serviceId\":\"${serviceId}\",\"date\":\"${date}\",\"startAt\":\"15:30\"}"
```

## My bookings

```sh
curl -sS -i -X GET "${baseUrl}/v1/me/bookings?tab=ongoing&limit=20" \
  -H "Authorization: Bearer ${token}"
```

## Booking detail

```sh
curl -sS -i -X GET "${baseUrl}/v1/bookings/${bookingId}" \
  -H "Authorization: Bearer ${token}"
```

## Cancel pending booking

```sh
curl -sS -i -X POST "${baseUrl}/v1/bookings/${bookingId}/cancel" \
  -H "Authorization: Bearer ${token}" \
  -H 'Content-Type: application/json' \
  --data "{}"
```

## Notifications

```sh
curl -sS -i -X GET "${baseUrl}/v1/me/notifications?type=all&limit=20" \
  -H "Authorization: Bearer ${token}"
```

## Read notifications

```sh
curl -sS -i -X POST "${baseUrl}/v1/me/notifications/read" \
  -H "Authorization: Bearer ${token}" \
  -H 'Content-Type: application/json' \
  --data "{\"markAll\":true}"
```

## Create shop

```sh
curl -sS -i -X POST "${baseUrl}/v1/owner/car-washes" \
  -H "Authorization: Bearer ${ownerToken}" \
  -H 'Content-Type: application/json' \
  --data "{\"name\":\"Test Car Wash\",\"contactPhone\":\"+919999999999\",\"address\":{\"line1\":\"1 Main Road\",\"area\":\"Koramangala\",\"city\":\"Bengaluru\",\"state\":\"Karnataka\",\"postalCode\":\"560034\",\"formattedAddress\":\"1 Main Road, Koramangala, Bengaluru\"},\"location\":{\"latitude\":12.9352,\"longitude\":77.6245},\"categories\":[\"quick\"]}"
```

## Owner shops

```sh
curl -sS -i -X GET "${baseUrl}/v1/owner/car-washes" \
  -H "Authorization: Bearer ${ownerToken}"
```

## Owner shop detail

```sh
curl -sS -i -X GET "${baseUrl}/v1/owner/car-washes/${shopId}" \
  -H "Authorization: Bearer ${ownerToken}"
```

## Update shop map pin

```sh
curl -sS -i -X PATCH "${baseUrl}/v1/owner/car-washes/${shopId}" \
  -H "Authorization: Bearer ${ownerToken}" \
  -H 'Content-Type: application/json' \
  --data "{\"location\":{\"latitude\":12.9352,\"longitude\":77.6245}}"
```

## Create service

```sh
curl -sS -i -X POST "${baseUrl}/v1/owner/car-washes/${shopId}/services" \
  -H "Authorization: Bearer ${ownerToken}" \
  -H 'Content-Type: application/json' \
  --data "{\"name\":\"Quick Wash\",\"category\":\"quick\",\"priceMinor\":25000,\"durationMinutes\":30,\"active\":true}"
```

## Set availability

```sh
curl -sS -i -X PUT "${baseUrl}/v1/owner/car-washes/${shopId}/availability/${date}" \
  -H "Authorization: Bearer ${ownerToken}" \
  -H 'Content-Type: application/json' \
  --data "{\"slots\":[{\"startAt\":\"15:30\",\"endAt\":\"16:00\",\"capacity\":2,\"enabled\":true}]}"
```

## Owner booking board

```sh
curl -sS -i -X GET "${baseUrl}/v1/owner/car-washes/${shopId}/bookings?date=${date}&limit=50" \
  -H "Authorization: Bearer ${ownerToken}"
```

## Accept booking

```sh
curl -sS -i -X POST "${baseUrl}/v1/owner/bookings/${bookingId}/status" \
  -H "Authorization: Bearer ${ownerToken}" \
  -H 'Content-Type: application/json' \
  --data "{\"status\":\"accepted\"}"
```

## Admin dashboard

```sh
curl -sS -i -X GET "${baseUrl}/v1/admin/dashboard" \
  -H "Authorization: Bearer ${adminToken}"
```

## Admin shop queue

```sh
curl -sS -i -X GET "${baseUrl}/v1/admin/car-washes?status=pending_review&limit=50" \
  -H "Authorization: Bearer ${adminToken}"
```

## Approve shop

```sh
curl -sS -i -X POST "${baseUrl}/v1/admin/car-washes/${shopId}/review" \
  -H "Authorization: Bearer ${adminToken}" \
  -H 'Content-Type: application/json' \
  --data "{\"decision\":\"approve\"}"
```

## Suspend user

```sh
curl -sS -i -X PATCH "${baseUrl}/v1/admin/users/${userId}/status" \
  -H "Authorization: Bearer ${adminToken}" \
  -H 'Content-Type: application/json' \
  --data "{\"status\":\"suspended\",\"reason\":\"Replace with actual reason\"}"
```

## Variants and cautions

- Bookings: `tab=completed` for completed only; cancelled/rejected history is not returned by that tab.
- Notifications: `type=booking|offer|update|all`, optional `unreadOnly=true`; mark specific items with `{"notificationIds":["ID"]}`. Mark-all currently processes at most 500.
- Owner status: pending → accepted or rejected; accepted → in_progress; in_progress → completed. Rejection releases reserved capacity.
- Admin review decisions: approve, reject, suspend, reactivate; provide `reason` for non-approve actions. User status can also be active.
- Enrollment is idempotent and preserves customer role. It does not approve a shop or grant admin rights.
- Availability PUT replaces the date's slots. Current implementation has concurrency/reserved-slot limitations; do not rewrite a date with live bookings until hardened.
- Register a stable installation ID containing letters, digits, underscores or hyphens. Delete that device before Firebase sign-out. Device registration alone does not implement push delivery.
- Prices are integer minor units: 25000 INR = ₹250. Legal versions must match your actual published policies; v1 is only an example.

