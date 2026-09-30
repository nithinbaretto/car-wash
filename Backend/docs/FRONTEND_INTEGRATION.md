# Frontend integration audit

The Flutter app uses authenticated API services for discovery, booking, favourites, notifications, profiles, and owner workflows. Phone verification uses Firebase Authentication. This document maps contracts; real-device and deployed-environment verification are still required.

## Screen mapping

| Frontend feature | Backend integration | Implemented behavior / constraints |
| --- | --- | --- |
| Login / OTP | Firebase Auth SDK, then POST /v1/me/onboarding | Real SMS send, verify and resend through Firebase Auth SDK. Existing users fetch /v1/me before onboarding. India SMS delivery enabled; see [mobile setup](../../Frontend_app/README.md) for signing/APNs and device verification. |
| Role selection / become vendor | POST /v1/me/owner-enrollment, PUT /v1/me/active-role | Map frontend vendor to backend owner. Enrollment retains customer access; new shops still require admin approval. |
| Home / location | GET /v1/categories and /v1/car-washes/nearby | Sends selected latitude/longitude from flutter_map; displays real empty and error states. |
| Shop detail / booking | GET shop detail and availability; POST /v1/bookings | Uses actual service IDs and returned slots, guards stale selections, and retains idempotency keys for retries. |
| Favourites | GET, PUT, DELETE /v1/me/favourites | Loads saved IDs, merges them into discovery, and reports failed mutations. |
| My bookings | GET /v1/me/bookings and /v1/bookings/:id | Preserve pending vs accepted; show awaiting owner approval. Refresh after owner changes. |
| Notifications | GET /v1/me/notifications; POST /v1/me/notifications/read | Uses notification feed/read endpoints and singular booking/offer/update filter values. |
| Profile / logout | GET/PATCH /v1/me; DELETE device then Firebase sign-out | Clear local user state. Do not send phone-number edits through PATCH profile; verified identity belongs to Auth. |
| Vendor onboarding | POST /v1/owner/car-washes | Submits contact, address, selected map coordinates and categories for admin approval. |
| Vendor today | GET owner shop bookings, POST owner booking status | Loads the managed shop queue and persists status changes. Manual acceptance remains mandatory. |

## Model adapters

- Public shop: map coverImageUrl to imageUrl, rating.average to rating, rating.count to reviewCount, startingPriceMinor to display price (divide by 100 for INR), address.formattedAddress to address, and location.latitude/longitude to coordinates. Owner shop responses have a different shape and omit public rating/price summaries. Allow null image/price/distance rather than inventing defaults.
- Category IDs are quick/interior/complete/premium; filter by IDs instead of matching display-label substrings.
- Booking: carWashId → shopId; carWash/service snapshots supply labels. Combine scheduledDate/startAt for whenLabel. Price is minor units, not whole rupees.
- Backend pending and accepted currently both fit frontend upcoming, but add a separate pending state or approval label. in_progress → inProgress; completed → completed; cancelled/rejected → cancelled. Current completed list returns completed only, not cancellation history.
- Timestamps currently serialize as Firestore timestamp objects, not guaranteed ISO strings. Use scheduledDate/startAt for booking labels; add a timestamp adapter for seconds/nanoseconds instead of parsing the object as text.

## Added in this change

- POST /v1/me/owner-enrollment: transactionally and idempotently enroll an active existing customer as owner, preserving existing roles. No admin claim or shop approval is granted.
- DELETE /v1/me/devices/:installationId: idempotent removal of the authenticated user's installation on logout. Registration/removal validate IDs.

## Operational coverage and follow-up

- Vendor walk-ins now use an owner-only, idempotent creation endpoint with guest snapshots and slot reservation; see [Owner operations](OWNER_OPERATIONS.md).
- Vendor money uses completed booking totals for today and the trailing seven days. No payment, refund, settlement or payout model exists; booking totals are not paid revenue.
- Open-now filter, shop about text and next-available summary lack a complete backend contract. Need opening-hours/timezone and metadata fields; use explicit unknown states meanwhile.
- Owner service editing/deactivation is still missing. Owner service and availability reads now complement creation/replacement.
- Availability replacement now uses a transaction and preserves reserved slots; exercise concurrent booking/update behavior with the Firestore emulator before release.
- Push delivery is not implemented just by registering FCM tokens. Notification list/read APIs are integrated; fake FCM token registration was removed.
- Support tickets, AI assistance, QR behavior and published policy content need defined workflows/content before APIs are added.
- Mobile lists currently request bounded pages; Admin list screens support cursor pagination. Notification mark-all caps at 500. Add pagination/history contracts for scale.

## Handoff

Use API_CURL.md or import car-wash.postman_collection.json. Start on emulators, create owner/customer accounts and a reviewed shop, then exercise pending → accepted → in_progress → completed. Test rejection, pending cancellation, invalid tokens and cross-owner access. No deployment was performed by this change.

## Super-admin dashboard

The separate React dashboard is in `Admin/`. It signs in with Firebase email/password
accounts carrying the `superAdmin` claim and reads all operational data through the
protected `/v1/admin/*` API. Configure `Admin/.env` from `Admin/.env.example` before
running it. A rejected owner shop can now be corrected and resubmitted with
`POST /v1/owner/car-washes/:carWashId/resubmit`.
