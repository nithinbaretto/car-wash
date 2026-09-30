# Car Wash mobile app

## Run

```sh
flutter pub get
flutter run
```

The default API is `https://asia-south1-car-wash-5d9ce.cloudfunctions.net/api`.
Override it for another deployed backend:

```sh
flutter run --dart-define=API_BASE_URL=https://YOUR_API_BASE
```

Firebase client configuration is in `lib/firebase_options.dart`,
`android/app/google-services.json`, and `ios/Runner/GoogleService-Info.plist`.
These are public client identifiers; never put Admin credentials or service-account
keys in the app. The Android package and iOS bundle ID are `com.carwash.carwash`.

## Phone OTP

Login uses the Firebase Auth SDK to send an SMS to the entered +91 number. It
navigates to code entry only after Firebase accepts the SMS request (or verifies
automatically). Verify exchanges the actual SMS code for a Firebase session;
Resend sends a new request. API calls use the SDK's refreshed Firebase ID token.
The old deterministic email/password login has been removed. Existing placeholder
accounts are not automatically linked to a verified phone account.

Configuration verified on 2026-09-30 for `car-wash-5d9ce`:

- Phone provider enabled; SMS allowlist includes India (`IN`); billing enabled.
- Android and iOS apps registered, matching the package/bundle identifiers above.
- This machine's Android debug SHA-1 and SHA-256 registered. Register release and
  Google Play signing fingerprints before distributing a release.
- Web auth domain is `car-wash-5d9ce.firebaseapp.com`; `localhost` is authorized.
  Authorize additional web deployment domains in Firebase Authentication.

For iOS, the reCAPTCHA return URL schemes and Firebase configuration resource are
included. Configure an APNs authentication key in Firebase and enable the Push
Notifications capability for the signed app to support silent app verification.
The app retains Firebase's reCAPTCHA fallback; app verification is never disabled.
The Firebase SDK requires iOS 15+ and Android API 23+.

See [Firebase phone authentication](https://firebase.google.com/docs/auth/flutter/phone-auth)
and [Apple setup](https://firebase.google.com/docs/auth/ios/phone-auth).
No real SMS recipient was used during automated checks. Test delivery and code
verification on a device before release. Firebase test numbers can exercise the
flow without sending SMS; keep them configured only for intended test accounts.

## API deployment and verification

New owner endpoints require deploying `Backend/functions` and the Firestore
indexes before the default production client can use them. See
[owner API contracts](../Backend/docs/OWNER_OPERATIONS.md) and
[backend setup](../Backend/Readme.md). Code changes are not automatically deployed.
The Money tab reports completed booking totals; it does not claim payment or
settlement balances. Push notification token registration requires a real FCM
integration and is not fabricated by the app.

```sh
flutter analyze
flutter test
flutter build apk --debug
```

## Verification for this change

- Flutter static analysis: no issues; 31 automated tests passed.
- Backend: 13 tests passed and syntax checks passed.
- Admin: 10 tests passed and production build succeeded.
- Android build: tooling updated to Gradle 8.14.3, AGP 8.11.1 and Kotlin 2.2.20
  to meet installed Flutter 3.47.4 requirements. Build could not complete because
  the Gradle distribution download timed out; retry on a working connection.
- iOS: configuration plists and Xcode project syntax validated; native build,
  APNs configuration and real-device SMS receipt have not been verified.

## Shop onboarding and review

Owners enter business/contact/address details, confirm their map pin (map tap, GPS or manual coordinates), add priced services and durations, and choose a dated booking schedule. The first date, 1–31 consecutive days, opening/closing times and simultaneous booking capacity are explicit. Times use `Asia/Kolkata`; generated slots fit the longest enabled service. The app submits all details atomically through `POST /v1/owner/car-washes/onboarding`.

Drafts are saved per signed-in owner on the device. An unchanged failed request reuses its original endpoint and idempotency key, including across app restarts. Shop-load failures show a retry state and never imply that a new registration is needed. Owners return to their existing application after sign-in. `pending_review`, `rejected` (with review feedback) and `suspended` show status screens; only `active` opens the booking board. Pending/rejected applications can be corrected through the same form and atomic `PUT /v1/owner/car-washes/:id/onboarding`.

Approved owners can maintain individual booking dates using the calendar action on the board. Suspended owners can maintain dates from their status screen so expired availability does not prevent review/reactivation. Saving a day replaces its slot schedule; the backend protects existing reservations. Onboarding submission does not automatically approve a shop.

The onboarding endpoints must be deployed with this client. `flutter test test/shop_onboarding_test.dart` covers real form validation, draft saving, submission and correction payloads, lost-response retries, review routing, failed shop lookup recovery and delayed session restoration. A physical-device check is still needed for map tiles and GPS permission behavior.


See [shop onboarding API and emulator verification](../Backend/docs/SHOP_ONBOARDING.md).
Deploy updated Functions before releasing the mobile client and Admin build.
Broader post-approval business/service editing is outside this onboarding flow.
