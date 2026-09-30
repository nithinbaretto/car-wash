# CleanWheel — Super Admin Platform

Enterprise dashboard for managing partner car wash hubs, booking operations, user accounts, and regulatory compliance.

---

## Features

- **Executive Overview**: Real-time KPI metrics, booking volume distribution, weekly throughput velocity, and partner approval alerts.
- **Fast-Track Approvals Queue**: Verification workflow for new partner studio applications with one-click decision dialogs and compliance reasoning.
- **Partner Hubs Directory**: Manage facility locations, operational statuses (*Active*, *Pending*, *Suspended*, *Rejected*), service catalog pricing, and bay capacity utilization meters by date.
- **Customer Bookings Feed**: Live appointment tracking with formatted INR pricing and status lifecycle tracking (*Pending*, *Accepted*, *In Progress*, *Completed*, *Cancelled*).
- **User Accounts & Sanctions**: Customer and partner owner directory with regulatory account suspension and reactivation controls.
- **Security & Compliance Audit Trail**: Immutable record of administrative state transitions, timestamps, actor accounts, and transition payloads.
- **Enterprise Design System**:
  - Seamless **Midnight Dark Mode** & **Slate Light Mode** with local persistence.
  - Plus Jakarta Sans typography with tailored micro-interactions.
  - Responsive layout with collapsible sidebar and mobile drawer.

---

## Getting Started

### 1. Install Dependencies
```bash
npm install
```

### 2. Configure Environment
Copy `.env.example` to `.env`:
```bash
cp .env.example .env
```
Ensure the Firebase and API parameters match your project:
```env
VITE_API_URL=https://asia-south1-car-wash-5d9ce.cloudfunctions.net/api
VITE_FIREBASE_API_KEY=AIzaSy...
VITE_FIREBASE_AUTH_DOMAIN=car-wash-5d9ce.firebaseapp.com
VITE_FIREBASE_PROJECT_ID=car-wash-5d9ce
VITE_FIREBASE_APP_ID=1:...
```

### 3. Start Development Server
```bash
npm run dev
```
Open [http://localhost:5173](http://localhost:5173) in your browser.

### 4. Build for Production
```bash
npm run build
```
Builds the optimized production bundle directly into `../Backend/admin-dist/`.

---

## Role-Based Access
Only Firebase Auth accounts with the `superAdmin: true` custom claim can access the live API backend. The dashboard verifies access with `/v1/admin/me`; it does not offer a mock login.


## API and emulator setup

The empty `VITE_API_URL` uses same-origin `/v1/*` requests. In development,
Vite proxies these requests to `API_PROXY_TARGET`, or derives the Functions
emulator URL from `VITE_FIREBASE_PROJECT_ID`. Set the proxy target to your
project ID before starting Vite. Firebase Hosting rewrites `/v1/*` to the
`api` function in `asia-south1`. For a separately hosted dashboard, set
`VITE_API_URL` to the HTTPS function URL shown above, without a trailing `/v1`.

Enable the Firebase Email/Password provider for admin login, create an account,
and grant its UID the `superAdmin` custom claim with
`Backend/functions/scripts/set-super-admin.js`. The dashboard refreshes the ID
token once if newly granted claims have not reached the session yet.

For local accounts, set `VITE_FIREBASE_AUTH_EMULATOR_URL=http://127.0.0.1:9099`
and run the Auth, Firestore and Functions emulators using the same project ID.
Leave this setting unset for production. Restart Vite after environment changes.
Firebase client settings are public; never put service-account files, provider
secrets or SMS credentials in `VITE_*` values.

Phone OTP SMS belongs to the Flutter customer's Firebase Phone Auth flow;
the admin portal uses email/password. Firebase Phone Auth provider settings,
billing, platform credentials and SMS region policy must be configured on the
Firebase project for real messages. Auth emulator codes do not send SMS.

Lists load server cursor pages with a Load more button. Failed API requests
show errors, and signing out clears cached operational data.
