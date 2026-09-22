# Frontend integration audit

The Flutter app currently uses local session state and MockData, not the backend. This audit does not mean those screens are integrated or production-ready.

## Screen mapping

| Frontend feature | Backend integration | Remaining frontend work |
| --- | --- | --- |
| Login / OTP | Firebase Auth SDK, then POST /v1/me/onboarding | Replace hardcoded MockData.otpCode; add Firebase dependencies and provider configuration. Existing users fetch /v1/me instead of repeating onboarding. |
| Role selection / become vendor | POST /v1/me/owner-enrollment, PUT /v1/me/active-role | Map frontend vendor to backend owner. Enrollment retains customer access; new shops still require admin approval. |
| Home / location | GET /v1/categories and /v1/car-washes/nearby | Send selected latitude/longitude; current map uses flutter_map. Location selection may stay local. Replace MockData.shops. |
| Shop detail / booking | GET shop detail and availability; POST /v1/bookings | Select actual service ID, date and returned slot. Do not use mock nextAvailable text or report success before server response. |
| Favourites | GET, PUT, DELETE /v1/me/favourites | Replace locally seeded favourite IDs; reconcile failed mutations. Nearby favourite flag currently defaults false, so merge favourite IDs yourself. |
| My bookings | GET /v1/me/bookings and /v1/bookings/:id | Preserve pending vs accepted; show awaiting owner approval. Refresh after owner changes. |
| Notifications | GET /v1/me/notifications; POST /v1/me/notifications/read | Replace mock items, map tabs to singular booking/offer/update values. |
| Profile / logout | GET/PATCH /v1/me; DELETE device then Firebase sign-out | Clear local user state. Do not send phone-number edits through PATCH profile; verified identity belongs to Auth. |
| Vendor onboarding | POST /v1/owner/car-washes | Current name/area form is insufficient: add contact, full address, map coordinates and categories. |
| Vendor today | GET owner shop bookings, POST owner booking status | Select managed shop and date; replace MockData.vendorToday. Manual acceptance remains mandatory. |

## Model adapters

- Public shop: map coverImageUrl to imageUrl, rating.average to rating, rating.count to reviewCount, startingPriceMinor to display price (divide by 100 for INR), address.formattedAddress to address, and location.latitude/longitude to coordinates. Owner shop responses have a different shape and omit public rating/price summaries. Allow null image/price/distance rather than inventing defaults.
- Category IDs are quick/interior/complete/premium; filter by IDs instead of matching display-label substrings.
- Booking: carWashId → shopId; carWash/service snapshots supply labels. Combine scheduledDate/startAt for whenLabel. Price is minor units, not whole rupees.
- Backend pending and accepted currently both fit frontend upcoming, but add a separate pending state or approval label. in_progress → inProgress; completed → completed; cancelled/rejected → cancelled. Current completed list returns completed only, not cancellation history.
- Timestamps currently serialize as Firestore timestamp objects, not guaranteed ISO strings. Use scheduledDate/startAt for booking labels; add a timestamp adapter for seconds/nanoseconds instead of parsing the object as text.

## Added in this change

- POST /v1/me/owner-enrollment: transactionally and idempotently enroll an active existing customer as owner, preserving existing roles. No admin claim or shop approval is granted.
- DELETE /v1/me/devices/:installationId: idempotent removal of the authenticated user's installation on logout. Registration/removal validate IDs.

## Still missing / needs follow-up

These are not implemented by the collection; do not wire mock data as if real.

- Vendor walk-ins: current screen only shows a snackbar. Decide guest identity, slot/bay capacity, vehicle data and whether walk-ins start accepted or in progress before adding a route.
- Vendor money: current earnings and pending payouts are mock values. No payment, refund, settlement or payout model exists. Booking totals are not paid revenue.
- Open-now filter, shop about text and next-available summary lack a complete backend contract. Need opening-hours/timezone and metadata fields; use explicit unknown states meanwhile.
- Owner service editing/deactivation and owner-specific availability reads are missing. The collection covers current creation/replacement only.
- Availability replacement needs transaction/concurrency protection and prevention of removal of reserved slots before production use with active bookings.
- Push delivery is not implemented just by registering FCM tokens. Notification list/read APIs can be integrated now.
- Support tickets, AI assistance, QR behavior and published policy content need defined workflows/content before APIs are added.
- Lists generally have limits but no cursor pagination. Notification mark-all caps at 500. Add pagination/history contracts for scale.

## Handoff

Use API_CURL.md or import car-wash.postman_collection.json. Start on emulators, create owner/customer accounts and a reviewed shop, then exercise pending → accepted → in_progress → completed. Test rejection, pending cancellation, invalid tokens and cross-owner access. No deployment was performed by this change.
