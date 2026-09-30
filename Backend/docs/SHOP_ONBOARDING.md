# Shop onboarding

The mobile app submits shop details, services and dated availability in one transaction. A completed submission is `pending_review`; only an administrator can activate it. Customers can discover/book only active shops.

Machine-readable request body: [shop-onboarding.schema.json](shop-onboarding.schema.json).

## Contract

All routes require `Authorization: Bearer <Firebase ID token>`. The owner role and active account are required. Bodies/responses use JSON; errors follow `{success:false,error:{code,message,fields?,requestId}}` and correlation IDs use `X-Correlation-ID`.

- `POST /v1/owner/car-washes/onboarding`: create a complete submission, `201` on creation, `200` on replay.
- `GET /v1/owner/car-washes/:carWashId/onboarding`: load current shop, services, upcoming availability and computed readiness.
- `PUT /v1/owner/car-washes/:carWashId/onboarding`: atomically replace a pending/rejected submission and submit for review, `200`.

POST and PUT accept JSON bodies up to 512 KiB and require `Idempotency-Key` (1–128 alphanumeric, `_` or `-`). Persist the key and exact request payload before sending. Retry a timed-out request with the same key and payload; changed payloads require a new key. Receipts are owner scoped, persisted with the transaction, and a conflicting reuse returns `409 IDEMPOTENCY_KEY_REUSED`. A failed transaction leaves no partial shop/services/availability. Retry network failures or 5xx with capped exponential backoff (e.g. 1/2/4 seconds), using a 30-second client timeout. Do not automatically retry validation, authorization or state conflicts. No endpoint-specific rate limit is currently configured; upstream infrastructure may return 429.

Request example (choose future dates before sending):

```json
{
  "name": "Central Car Wash",
  "contactPhone": "+919876543210",
  "address": {
    "line1": "10 Main Road", "area": "Centre", "city": "Pune",
    "state": "Maharashtra", "postalCode": "411001",
    "formattedAddress": "10 Main Road, Centre, Pune, Maharashtra 411001"
  },
  "location": {"latitude": 18.52, "longitude": 73.85},
  "categories": ["quick"],
  "services": [{"name": "Quick Wash", "category": "quick", "priceMinor": 15000, "durationMinutes": 30, "active": true}],
  "availability": [{"date": "2030-01-01", "slots": [{"startAt": "10:00", "endAt": "11:00", "capacity": 2, "enabled": true}]}]
}
```

Prices are integer INR paise; service price 1–10,000,000 and duration 5–1,440 minutes. Provide 1–20 services and 1–31 distinct availability dates, with at most 100 slots per date. Dates cannot be in the past; slot times use `Asia/Kolkata` and slots must not overlap. Each selected shop category must have an active priced service. Every active service must use a selected shop category and fit at least one enabled future slot with remaining capacity. Coordinates must be finite/in bounds. At least one active service and one usable future slot are required. `coverImageUrl` and `location.placeId` are optional.

Write response: `{success:true,data:{carWash},requestId}`. Shop includes normalized `location:{latitude,longitude,placeId}`, `review:{decision,reason,stateChangedAt,stateChangedBy}`, and submission metadata `onboarding:{completedAt,availabilityDates}`.

Read response: `{success:true,data:{carWash,services,availability,onboarding},requestId}`. `data.onboarding` is computed readiness `{complete,issues:string[],serviceCount,availabilityDates:string[]}`. Do not confuse this with the shop's historical submission metadata. Availability contains `{date,slots,updatedAt}`, and returned slots include server-owned `bookedCount`. Strip `id`, timestamps, `bookedCount` and `availableCapacity` before constructing write payloads.

## Review and recovery

- New and corrected submissions remain pending until approved.
- Pending/rejected shops can load this form and resubmit on the same shop ID. Correction replaces services and upcoming availability, clears the previous review reason, and logs an audit event.
- Rejected shops show `carWash.review.reason`; submitting a corrected complete form sets pending again.
- Active/suspended shops cannot use wholesale onboarding replacement (`409 SHOP_ONBOARDING_LOCKED`). Existing owner service/availability APIs remain available for ongoing maintenance; suspended shops must await administrator reactivation.
- Replacement refuses existing reserved upcoming slots (`409 AVAILABILITY_CONFLICT`). Legacy shops with over 100 services or upcoming days must use existing maintenance APIs.
- Existing incremental create/edit APIs remain compatible. Legacy incomplete pending shops can be repaired using PUT onboarding. Admin detail reports readiness for them; admin approval and legacy resubmit refuse incomplete setup with `SHOP_ONBOARDING_INCOMPLETE`.
- Approval/reactivation rechecks actual shop/services/future slots transactionally. Expired availability blocks approval; the owner must publish future dates. Service/availability updates touch shop `updatedAt` for stale-review protection.

No data migration or new composite Firestore index is required. Deploy Functions before the mobile client that uses these endpoints. Local test success does not deploy the API.

## Verification

Run from the repository root with Node dependencies installed, Firebase CLI, and the Java runtime required by the Firestore emulator:

```sh
npm test --prefix Backend/functions
npm run lint --prefix Backend/functions
firebase emulators:exec --config Backend/firebase.json --project demo-car-wash-onboarding --only auth,firestore 'node Backend/functions/scripts/verify-onboarding-emulator.js'
```

The integration script refuses non-demo projects or absent emulator environment variables. It starts the Express API locally and exercises actual Auth tokens and Firestore transactions: owner/customer signup, complete creation and idempotent retries, pending visibility restrictions, rejection reason and correction, approval/readiness, discovery, customer booking, owner queue, and reserved slot protection. It also verifies role denial and incomplete legacy approval rejection. These checks do not deploy or access the production database.
