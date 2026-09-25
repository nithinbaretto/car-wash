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
- **Demo Mode**: Instant preview mode for UI review and testing without requiring live Firebase super-admin credentials.

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
Only Firebase Auth accounts with the `superAdmin: true` custom claim can access the live API backend. For fast evaluation or UI preview, use the **Preview as Super Admin (Demo Mode)** button on the sign-in screen.
