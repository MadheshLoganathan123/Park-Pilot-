# 🅿️ ParkPilot — Master Implementation Plan
> **Android App · Flutter + Firebase Auth + Express/Prisma Backend + Supabase Postgres**
> Last updated: 2026-08-14 · Total estimated work remaining: **5–6 hours**

---

## 📊 Project Health Snapshot

> Read this section first — it tells you exactly where the project stands before you touch a single line of code.

| Layer | Status | Verdict |
|---|---|---|
| Flutter UI (Customer) | 12 screens built | ✅ Mostly done — needs real-data wiring |
| Flutter UI (Provider) | 6 screens built | ✅ Mostly done — needs real-data wiring |
| Firebase Auth (Login + Register) | Screen exists, `FirebaseAuth` calls in service | ⚠️ Wired but **Firebase not initialized** in `main.dart` |
| Google Sign-In | Button exists in `login_screen.dart` | ⚠️ Works on web popup; Android needs SHA-1 + config |
| Backend (Express + Prisma) | 7 controllers, full routes, Zod validation | ✅ Structurally complete — needs DB migration + seed |
| Flutter → Backend HTTP | `ApiClient` + `api_config.dart` exist | ⚠️ Client built, but **most screens still read local mock data** |
| Real QR Camera Scanning | `mobile_scanner` in pubspec, unused | ❌ `MobileScanner` widget not placed in QR screen yet |
| Google Maps | Not added anywhere | ❌ Stretch goal only |
| Push Notifications (FCM) | `firebase-admin` in backend deps | ❌ Stretch goal only |

---

## 🗂️ All Screens — Completion Status

### 👤 Customer Screens

| Screen | File | Built? | Real Data? | What Remains |
|---|---|---|---|---|
| Login | `login_screen.dart` | ✅ | ⚠️ | Firebase `initializeApp` must fire first |
| Create Account | `customer/create_account_screen.dart` | ✅ | ⚠️ | Same Firebase init dependency |
| Customer Home | `customer/customer_home_screen.dart` | ✅ | ❌ | Wire `loadLots()` result; show real nearby lots |
| Find Parking | `customer/find_parking_screen.dart` | ✅ | ❌ | Replace hardcoded list with `ParkingDataService.lots` |
| Parking Details | `customer/parking_details_screen.dart` | ✅ | ❌ | Wire to real lot from API; show live slot count |
| Slot Selection | `customer/slot_selection_screen.dart` | ✅ | ❌ | Fetch real slots; disable already-booked ones |
| Booking Confirmation | `customer/confirmation_screen.dart` | ✅ | ❌ | Call real `POST /api/bookings` on confirm |
| Reservation Pass (QR) | `customer/reservation_pass_screen.dart` | ✅ | ⚠️ | Already renders QR; needs real booking ID from API |
| My Bookings | `customer/customer_bookings_screen.dart` | ✅ | ❌ | Call `GET /api/bookings/customer/:id` |
| Profile | `customer/customer_profile_screen.dart` | ✅ | ⚠️ | Profile service exists; test end-to-end |
| Edit Profile | `customer/edit_profile_screen.dart` | ✅ | ❌ | Wire save to `PUT /api/profile` |
| My Vehicles | `customer/my_vehicles_screen.dart` | ✅ | ❌ | Add vehicle list via API or local storage |
| Payment Methods | `customer/payment_methods_screen.dart` | ✅ | ❌ | Static UI fine for demo; no payment gateway needed |

### 🏢 Provider Screens

| Screen | File | Built? | Real Data? | What Remains |
|---|---|---|---|---|
| Dashboard | `provider/provider_dashboard_screen.dart` | ✅ | ❌ | Call `GET /api/providers/:id/stats` |
| Slot Status | `provider/provider_slot_status_screen.dart` | ✅ | ❌ | Call `GET /api/providers/:id/spaces`; toggle via API |
| Bookings | `provider/provider_bookings_screen.dart` | ✅ | ❌ | Call `GET /api/bookings/provider/:id` |
| QR Validator | `provider/provider_qr_validator_screen.dart` | ✅ | ❌ | Replace simulated scanner with real `MobileScanner` |
| Controls | `provider/provider_controls_screen.dart` | ✅ | ❌ | Wire surge pricing toggle to API |
| Profile | `provider/provider_profile_screen.dart` | ✅ | ⚠️ | Same as customer profile wiring |

---

## ⏱️ SESSION PLAN — 5 to 6 Hours

> Each session block is self-contained. You can stop at any session boundary and have a working app.
> **Do sessions in order** — later sessions depend on earlier ones.

---

## 🕐 SESSION 1 — Firebase Init + Backend Boot (45–60 min)

> **Goal:** App launches without crashing, Firebase Auth is live, backend connects to DB.

### 1.1 — Fix Firebase Initialization in `main.dart`

**Why it matters:** `FirebaseAuth.instance` is already called in `parking_data_service.dart` lines 35–40, but `Firebase.initializeApp()` is never awaited before that — this causes a silent crash or auth failure at startup.

**File:** `lib/main.dart`

```dart
// Add this at the very top of main():
WidgetsFlutterBinding.ensureInitialized();
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
final dataService = ParkingDataService();
await dataService.init(); // restores session from SharedPreferences
```

- Add `import 'firebase_core/firebase_core.dart'` and `import 'firebase_options.dart'`
- Make `main()` async if it isn't already
- After `Firebase.initializeApp()`, call `ParkingDataService().init()` — this restores a persisted session from `SharedPreferences` and auto-logs in returning users

### 1.2 — Android Firebase Configuration

**File:** `android/app/google-services.json`

- Verify `google-services.json` is in place (it must contain the `package_name` matching `android/app/build.gradle`)
- Add your debug SHA-1 to Firebase Console → Project Settings → Android App
  ```bash
  # Get SHA-1:
  cd android && ./gradlew signingReport
  ```
- Re-download `google-services.json` after adding SHA-1 (required for Google Sign-In on Android)
- Verify `android/build.gradle` has `classpath 'com.google.gms:google-services:...'`
- Verify `android/app/build.gradle` has `apply plugin: 'com.google.gms.google-services'` at the bottom

### 1.3 — Boot the Backend

```bash
cd backend
npm install
npx prisma generate
npx prisma migrate dev --name init    # creates tables in Supabase
npm run prisma:seed                   # loads sample parking lots, slots, users
npm run dev                           # starts Express on port 5000
```

- Hit `http://localhost:5000/api/health` — expect `{ status: 'ok' }`
- Smoke-test: `GET /api/parking` → should return seeded lots as JSON
- Smoke-test: `GET /api/parking/:id` → lot details with slots array

### 1.4 — Set Backend Base URL in Flutter

**File:** `lib/services/api_config.dart`

```dart
// Android emulator reaches host machine at 10.0.2.2
static const String baseUrl = 'http://10.0.2.2:5000/api';
// Physical device: use your LAN IP, e.g. 'http://192.168.1.x:5000/api'
// ngrok tunnel: 'https://xxxx.ngrok.io/api'
```

**✅ Session 1 Checkpoint:** App launches → Login screen appears → backend health check passes.

---

## 🕑 SESSION 2 — Auth Flow: Login + Register Working End-to-End (60–75 min)

> **Goal:** Real users can sign up, log in with email/password or Google, and their session persists across restarts.

### 2.1 — Login Screen — Make It Fully Functional

**File:** `lib/screens/login_screen.dart`

The screen UI is complete. The `_handleLogin()` method calls `dataService.login()` which calls `FirebaseAuth.instance.signInWithEmailAndPassword()` — this chain works once Session 1 fixes are applied.

**Unique implementation detail — Role persistence:** After successful login, the role chosen in the `ChoiceChip` widget must be saved to `SharedPreferences` via `_saveSession()`. Verify `_currentRole` is correctly applied so the `AppShell` routes to either the customer nav bar or the provider nav bar immediately after login — no second tap required.

**Test these exact scenarios:**
- Wrong password → SnackBar shows Firebase error message
- Empty fields → SnackBar shows validation message (already coded at line 21)
- Correct credentials → Navigator replaces to `AppShell`

### 2.2 — Create Account Screen — Wire Registration

**File:** `lib/screens/customer/create_account_screen.dart`

- The `createAccount()` call in `ParkingDataService` uses `FirebaseAuth.instance.createUserWithEmailAndPassword()`
- After creation, `_syncAndSaveSession()` POSTs to the backend `ProfileService` to create a DB record — verify `backend/src/controllers/authController.ts` and `profileController.ts` handle this correctly
- **Unique implementation:** On first-time account creation, call `_apiClient.post('/auth/sync', body: {...})` in `ProfileService.sync()` — this upserts the user in Postgres so all future booking calls have a valid `customerId` foreign key

**Test:**
- Create account with a new email → arrives at `AppShell` as Customer
- Attempt to create duplicate email → Firebase error displayed

### 2.3 — Google Sign-In on Android

**File:** `lib/services/parking_data_service.dart` lines 111–158

- Requires SHA-1 from step 1.2 — without it, Google Sign-In silently returns `null` on Android
- `_googleSignIn.signIn()` returns `null` if user cancels — already handled at line 134 (`return false`)
- After successful Google auth, `_syncAndSaveSession()` creates the backend user record if it doesn't exist (idempotent upsert)

### 2.4 — Forgot Password Flow (Unique Feature)

**File:** `lib/screens/login_screen.dart` — "Forgot password?" button currently has `onPressed: () {}`

Add a dedicated `PasswordResetDialog` (inline `showDialog`) that:
1. Shows a single email field
2. On submit: calls `FirebaseAuth.instance.sendPasswordResetEmail(email: email)`
3. Shows a confirmation message: "Reset link sent to [email]"

This is a **unique, polished feature** that most student apps skip — it makes the auth flow feel production-grade.

### 2.5 — Session Restore on App Restart

**File:** `lib/main.dart`

```dart
// In main(), after dataService.init():
runApp(MyApp(isLoggedIn: dataService.isLoggedIn));

// In MyApp, the initialRoute / home should be:
home: dataService.isLoggedIn ? const AppShell() : const LoginScreen(),
```

**✅ Session 2 Checkpoint:** Sign up → log in → close app → reopen → goes directly to home screen without re-login.

---

## 🕒 SESSION 3 — Customer Core Flow: Browse → Book → QR Pass (90–100 min)

> **Goal:** The complete customer journey works with real backend data. A booking created in Flutter appears in Prisma Studio.

### 3.1 — Customer Home Screen — Real Data

**File:** `lib/screens/customer/customer_home_screen.dart`

- `ParkingDataService.loadLots()` already calls `GET /api/parking` via `ApiClient` — verify it's being called in `initState` or via a `ChangeNotifier` listener
- The home screen's "Featured Parking" and "Nearby" sections must read from `ParkingDataService.lots` (the live list)
- Add a `CircularProgressIndicator` when `lots.isEmpty && isLoading == true`
- Add a retry button when `lots.isEmpty && error != null`

**Unique implementation — Recent Search Chips:** Store the last 3 lot names the user tapped in `SharedPreferences` as a JSON-encoded list. Display them as dismissible chips under the search bar — tapping one jumps directly to that lot's detail screen.

### 3.2 — Find Parking Screen — Real Filterable List

**File:** `lib/screens/customer/find_parking_screen.dart`

- Replace any hardcoded lot list with `context.watch<ParkingDataService>().lots` (or `AnimatedBuilder` equivalent already used in the project)
- Filters (price, distance, rating, amenities) must operate on the in-memory loaded list — no extra API calls needed
- **Unique implementation — Live Availability Badges:** Each lot card shows a colored badge: `🟢 Available`, `🟡 Limited` (< 20% slots free), `🔴 Full`. Compute this from `lot.availableSlots / lot.totalSlots`. Update whenever `ParkingDataService` notifies.
- Sort options: Nearest, Cheapest, Highest Rated — all computed client-side from loaded data

### 3.3 — Parking Details Screen — Real Slot Data

**File:** `lib/screens/customer/parking_details_screen.dart`

- This screen receives a `ParkingLot` object from navigation — it must use the live object from the service, not a local copy
- Call `GET /api/parking/:id` for fresh slot availability when this screen opens (cache the result in the service for 60 seconds to avoid hammering the API)
- Display: lot name, address, price/hour, rating, amenities list, available vs total slots, operating hours

**Unique implementation — Animated Slot Counter:** Use a `TweenAnimationBuilder<int>` to animate the "X slots available" counter from 0 to the real value when the screen loads. A slot count ring chart shows occupancy visually.

### 3.4 — Slot Selection Screen — Disable Already-Booked Slots

**File:** `lib/screens/customer/slot_selection_screen.dart`

- Fetch `GET /api/parking/:id` → `slots` array. Each slot has a `status` field (`AVAILABLE`, `OCCUPIED`, `MAINTENANCE`)
- Render slots as a grid: green = available, red = occupied (non-tappable), orange = maintenance
- **Unique implementation — Time-Slot Picker:** Show a horizontal scroll of 30-min time blocks for the current day. Grayed blocks = already booked by another user.
- Selected slot highlighted with a pulsing border animation (`AnimationController` + `BorderSide`)

### 3.5 — Booking Confirmation Screen → Real API Call

**File:** `lib/screens/customer/confirmation_screen.dart`

This is the most critical screen — it creates the actual booking in the database.

**Implementation:**
```dart
// On "Confirm Booking" button tap:
final booking = await ParkingDataService().createBooking(
  parkingSpaceId: selectedSlot.id,   // UUID from API
  bookingDate: selectedDate.toIso8601String(),
  startTime: startTime.toIso8601String(),
  endTime: endTime.toIso8601String(),
  paymentMethod: 'CARD',
);
// Navigate to ReservationPassScreen with the real booking object
```

In `ParkingDataService`, `createBooking()` must:
1. Call `POST /api/bookings` with the Firebase JWT token in the `Authorization` header (already handled by `ApiClient._buildHeaders()`)
2. Parse the response into a `Booking` model using `Booking.fromJson()`
3. Add to `_bookings` list and `notifyListeners()`

**Unique implementation — Optimistic UI:** Immediately show a "Booking in progress..." overlay (blurred background + spinning logo) while the API call is in flight. If it fails, show a specific error card (slot taken = "Someone just grabbed this spot — choose another", network error = "Check your connection and retry") with an actionable Retry button.

### 3.6 — Reservation Pass Screen — Real QR with Booking ID

**File:** `lib/screens/customer/reservation_pass_screen.dart`

- `qr_flutter` is already used here — **this screen is the most complete in the project**
- Ensure the QR data string uses the real `booking.id` UUID from the API response (not a locally generated ID)
- The QR should encode: `PARKPILOT::BOOKING::{bookingId}` so the provider-side validator can parse it deterministically
- **Unique implementation — Shareable Pass:** Add a "Share Pass" button that copies the booking ID to clipboard with a confirmation toast

### 3.7 — My Bookings Screen — Live History

**File:** `lib/screens/customer/customer_bookings_screen.dart`

- Call `GET /api/bookings/customer/:customerId` using the stored `userId` from `ParkingDataService`
- Display: lot name, slot ID, date/time, status chip (CONFIRMED, CHECKED_IN, CANCELLED)
- **Unique implementation — Swipe to Cancel:** Wrap each booking card in a `Dismissible` widget. Swipe-left reveals a red "Cancel" action. On dismiss, call `PUT /api/bookings/:id/cancel` with confirmation dialog first. Animate the card out on success; restore it on failure with an error snackbar.
- Tab bar: "Upcoming" | "Past" | "Cancelled" — filter client-side from the loaded list

**✅ Session 3 Checkpoint:** Full loop works — create booking in Flutter → open Prisma Studio (`npx prisma studio`) → booking appears in `Booking` table with `status: CONFIRMED`.

---

## 🕓 SESSION 4 — Provider Side: Dashboard, Bookings, Slot Management (75–90 min)

> **Goal:** Provider can view real stats, manage their lots, and see all customer bookings.

### 4.1 — Provider Dashboard — Real Stats via API

**File:** `lib/screens/provider/provider_dashboard_screen.dart`

Currently reads hardcoded getters (`todayRevenue`, `activeBookingsCount`, etc.) from `ParkingDataService`.

**Implementation:**
- Call `GET /api/providers/:providerId/stats` — this endpoint exists in `providerController.ts` (`getProviderRevenueStats`)
- Parse the response: `{ todayRevenue, totalRevenue, activeBookingsCount, totalSlotsCount, occupiedSlotsCount, occupancyRate }`
- Update `ParkingDataService` to store `_providerStats` and expose it, with `loadProviderStats()` method
- Show a loading skeleton (shimmer effect using `AnimatedContainer` with cycling opacity) while fetching

**Unique implementation — Revenue Chart:** Add a 7-day revenue bar chart showing last 7 days on X-axis and revenue (₹) on Y-axis. This makes the dashboard feel like a real analytics product, not just a counter display.

**Unique implementation — Live Occupancy Ring:** The occupancy percentage (`occupiedSlotsCount / totalSlotsCount`) shown as a circular progress ring with an animated fill using `TweenAnimationBuilder<double>`. Ring color transitions: green (< 70%) → amber (70–90%) → red (> 90%).

### 4.2 — Provider Slot Status Screen — Real Toggle

**File:** `lib/screens/provider/provider_slot_status_screen.dart`

- Load slots via `GET /api/providers/:id/spaces` → each space has a `slots` array
- Each slot card shows: slot number, current status, vehicle plate (if occupied), check-in time
- **Unique implementation — Maintenance Mode Toggle:** Each slot has a `Switch` widget. Toggling it calls `PUT /api/parking/:spaceId/slots/:slotId/status` with `{ status: 'MAINTENANCE' | 'AVAILABLE' }`.
- Show a color-coded legend: 🟢 Available · 🔵 Occupied · 🟠 Maintenance · ⚫ Reserved
- Tapping an occupied slot card expands it (using `AnimatedContainer`) to show the full booking details inline

### 4.3 — Provider Bookings Screen — Full List with Actions

**File:** `lib/screens/provider/provider_bookings_screen.dart`

- Call `GET /api/bookings/provider/:providerId`
- Booking cards show: customer name, slot number, date/time, status, amount
- **Unique implementation — Booking Status Workflow Tags:** Each booking gets a visual status pill that follows the lifecycle: `PENDING → CONFIRMED → CHECKED_IN → COMPLETED → CANCELLED`. Use distinct colors for each state.
- Filter tabs: Today | This Week | All Time — filter client-side by `bookingDate`
- Search bar (name or booking ID) with `TextField` + client-side filtering on the loaded list

### 4.4 — Provider Controls Screen — Surge Pricing & Settings

**File:** `lib/screens/provider/provider_controls_screen.dart`

This screen is currently a stub (1,533 bytes). Build it out:

**Unique implementation — Surge Pricing Control Panel:**
- `Switch` to enable/disable surge pricing (`isSurgePricingEnabled` already exists in `ParkingDataService`)
- `Slider` for surge multiplier (1.0× to 3.0×) — show real-time preview: "Current rate: ₹50/hr → Surge rate: ₹125/hr"
- On save, call `PUT /api/providers/:id/settings` with `{ surgeEnabled, surgeMultiplier }`
- Add this endpoint to backend `providerController.ts` and `providerService.ts`

**Operating Hours Manager:**
- Day-of-week toggles (Mon–Sun) to mark open/closed
- Time pickers for open and close time per day
- Saved to backend via the same settings endpoint

**✅ Session 4 Checkpoint:** Provider logs in → Dashboard shows real numbers from DB → Slot status grid reflects actual slot states → Booking list shows all customer reservations.

---

## 🕔 SESSION 5 — Real QR Camera Scanning for Providers (45–60 min)

> **Goal:** Provider points phone camera at a customer's QR → booking is checked in live.

### 5.1 — Replace Simulated Scanner with Real `MobileScanner`

**File:** `lib/screens/provider/provider_qr_validator_screen.dart`

The `mobile_scanner` package is already in `pubspec.yaml` — it just hasn't been used.

**Step-by-step replacement:**

1. Import: `import 'package:mobile_scanner/mobile_scanner.dart';`
2. Add `MobileScannerController _scannerController = MobileScannerController();` to state
3. Replace the simulated viewfinder `Container` with:

```dart
MobileScanner(
  controller: _scannerController,
  onDetect: (capture) {
    final barcode = capture.barcodes.first;
    final raw = barcode.rawValue;
    if (raw != null && raw.startsWith('PARKPILOT::BOOKING::')) {
      final bookingId = raw.replaceFirst('PARKPILOT::BOOKING::', '');
      _validateAndCheckIn(bookingId);
    }
  },
)
```

4. Overlay a corner-bracket viewfinder frame using a `CustomPainter` (draws 4 rounded L-shapes at the corners)
5. Add a torch toggle button (`_scannerController.toggleTorch()`) for dim environments

**Unique implementation — Corner-Bracket Viewfinder:** Instead of a plain rectangle, draw a custom animated viewfinder using `CustomPainter`:
- 4 rounded corner brackets (not a full rectangle border)
- A horizontal scan line that bounces top-to-bottom using `AnimationController` + `Tween`
- This makes the scanner look premium, not like a generic library widget

6. Keep the manual text-entry field as a collapsible fallback panel (tap a "Can't scan?" button to reveal it).

### 5.2 — Wire Check-In to Backend

Inside `_validateAndCheckIn(String bookingId)`:

```dart
// 1. Call GET /api/bookings/:id to fetch booking details
// 2. Show booking summary card (customer name, slot, time) — let provider verify it visually
// 3. On provider tapping "Confirm Check-In" button:
//    Call PUT /api/bookings/:id/check-in
// 4. On success: show green success animation + update local bookings list
// 5. On failure: show red error state with specific message
```

**Unique implementation — Success Celebration Animation:** On successful check-in, display a full-screen overlay with:
- A green checkmark that draws itself using `AnimatedContainer` + `TweenAnimationBuilder`
- "Booking #xxxxx Checked In!" text
- Customer name and slot number
- Auto-dismisses after 2.5 seconds, scanner resumes

### 5.3 — Camera Permissions

**Android:** Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.CAMERA"/>
```

Request permission at runtime using `permission_handler` before showing the `MobileScanner` widget:
```dart
final status = await Permission.camera.request();
if (!status.isGranted) { /* show settings redirect */ }
```

### 5.4 — QR Scan History Log

**Unique implementation:** After each scan attempt (success or fail), append an entry to a local scan log list displayed below the scanner:
- `✅ 14:32 — Booking #abc123 — Arun Kumar — Slot A-12 — Checked In`
- `❌ 14:29 — Invalid QR — Unknown Code`

This is shown as a scrollable list that can be cleared. It gives providers a quick audit trail of the session without opening the full bookings screen.

**✅ Session 5 Checkpoint:** Scan a QR code from the customer's reservation pass → booking status changes to CHECKED_IN in DB → provider sees success animation → customer's booking history shows CHECKED_IN.

---

## 🕕 SESSION 6 — Polish, Profile, Error States & End-to-End Test (45–60 min)

> **Goal:** The app handles all failure cases gracefully and every profile action works.

### 6.1 — Customer Profile Screen

**File:** `lib/screens/customer/customer_profile_screen.dart`

- Profile data is fetched via `ProfileService` → `GET /api/profile` (authenticated)
- Show: name, email, role badge, profile photo (or initials avatar)
- **Unique implementation — Initials Avatar with Gradient:** If no profile photo is set, generate an avatar using the user's initials on a gradient background. The gradient hue is derived from the hash of the user's name (so "Arun" always gets the same color). Use `CustomPainter` to draw the gradient circle + initials text.

### 6.2 — Edit Profile Screen

**File:** `lib/screens/customer/edit_profile_screen.dart`

- On save: call `PUT /api/profile` with `{ name, phone }`
- Profile photo: `ImagePicker` → pick from gallery → store as base64 in `SharedPreferences`
- Show a `LinearProgressIndicator` during save; success snackbar on completion

### 6.3 — My Vehicles Screen

**File:** `lib/screens/customer/my_vehicles_screen.dart`

**Unique implementation:** Store vehicles locally in `SharedPreferences` as a JSON list: `[{ plate: 'TN09AB1234', type: 'Sedan', label: 'My Honda City' }]`. This is the local-first storage pattern — common in production apps for data that rarely changes.

- Add Vehicle dialog: plate number field with `TextInputFormatter` enforcing Indian plate format (`[A-Z]{2}\d{2}[A-Z]{2}\d{4}`)
- Swipe to delete a vehicle
- Select a default vehicle — stored as `prefs.setString('defaultVehicle', plate)`
- The selected vehicle auto-fills the booking confirmation screen's vehicle field

### 6.4 — Provider Profile Screen

**File:** `lib/screens/provider/provider_profile_screen.dart`

Same as customer profile but shows:
- Business name, address, total lots managed
- Revenue summary (total earned, this month)
- Logout button → calls `FirebaseAuth.instance.signOut()` + clears `SharedPreferences` + navigates to Login

### 6.5 — Global Error Handling & Loading States

Apply to **every screen** that makes an API call:

| State | UI Treatment |
|---|---|
| Loading (first fetch) | Shimmer skeleton cards (animated opacity pulse) |
| Loading (refresh) | `RefreshIndicator` on scrollable screens |
| Network error | Centered icon + message + "Retry" button |
| Empty state | Illustrated empty state (use `Icons` + descriptive text) |
| Auth error (401) | Silently sign out → redirect to Login |
| Conflict (409 slot taken) | Specific message "Slot just got taken — pick another" |
| Server error (5xx) | "Something went wrong on our end. Try again in a moment." |

**Unique implementation — Persistent Error Banner:** Use a `ValueNotifier<String?>` in `ParkingDataService` for a global error message. In `AppShell`, show a dismissible `MaterialBanner` at the top of the screen when this notifier has a value.

### 6.6 — End-to-End Demo Test

Run this exact sequence twice before considering the app done:

```
1.  Launch app → Login screen (not crash)
2.  Sign up as new Customer → AppShell loads
3.  Home screen → real parking lots from DB visible
4.  Find Parking → tap a lot → slot grid loads
5.  Select a slot → pick time → Confirm → Booking created in DB
6.  Reservation Pass shows real QR code
7.  Switch app to Provider mode (log out → log in as provider)
8.  Dashboard shows updated stats
9.  Provider Bookings shows the booking just created
10. QR Validator → scan or paste booking ID → Check In → status updates
11. Switch back to Customer → My Bookings → shows CHECKED_IN status
12. Cancel a booking → status updates in DB
```

---

## 🚀 STRETCH GOALS (Only if Sessions 1–6 complete early)

Ranked by impact-to-effort ratio. Do them in order.

### Stretch A — Google Maps on Find Parking (2–3 hrs extra)
- Add `google_maps_flutter` to `pubspec.yaml`
- Add `latitude` and `longitude` fields to `ParkingLot` model and Prisma schema
- Seed real coordinates for the sample lots
- Replace (or tab-switch with) the current list view with a `GoogleMap` widget
- Place `Marker`s at each lot location; marker info window shows lot name + price
- Tapping a marker navigates to `ParkingDetailsScreen`
- Get a Google Maps API key from Cloud Console → add to `android/app/src/main/AndroidManifest.xml`

### Stretch B — Push Notifications via FCM (1–2 hrs extra)
- Backend already has `firebase-admin` — implement `POST /api/notifications/booking-confirmed`
- Flutter: `firebase_messaging` package → request permission → store FCM token → send to backend on login
- Notification triggers: booking confirmed, 30-min reminder, check-in complete

### Stretch C — Payment Gateway Simulation (1 hr extra)
- Add Razorpay test-mode integration with `key_id = 'rzp_test_...'` — no real money moves
- Wire the confirmation screen to show a payment UI before creating the booking

### Stretch D — Dark Mode (30 min extra)
- Flutter `ThemeMode.system` detects device dark/light preference
- Add a dark `ColorScheme` with the same brand blue but dark surface colors
- Toggle in Settings screen → stored in `SharedPreferences`

---

## 📁 Key Files Reference

```
lib/
├── main.dart                               ← ADD Firebase.initializeApp() here
├── firebase_options.dart                   ← Already exists; don't modify
├── services/
│   ├── api_client.dart                     ← Already built; HTTP wrapper with Firebase JWT
│   ├── api_config.dart                     ← SET baseUrl HERE (10.0.2.2 or LAN IP)
│   ├── parking_data_service.dart           ← Central state; wire loadLots/loadBookings
│   └── profile_service.dart               ← Already built; profile sync
├── screens/
│   ├── login_screen.dart                   ← Add forgot-password dialog (Session 2.4)
│   ├── customer/
│   │   ├── customer_home_screen.dart       ← Wire to real lots (Session 3.1)
│   │   ├── find_parking_screen.dart        ← Real list + availability badges (Session 3.2)
│   │   ├── parking_details_screen.dart     ← Real slot count + animation (Session 3.3)
│   │   ├── slot_selection_screen.dart      ← Disable booked slots + time picker (Session 3.4)
│   │   ├── confirmation_screen.dart        ← POST /api/bookings (Session 3.5)
│   │   ├── reservation_pass_screen.dart    ← Already works; verify real booking ID (Session 3.6)
│   │   ├── customer_bookings_screen.dart   ← GET + swipe-to-cancel (Session 3.7)
│   │   ├── customer_profile_screen.dart    ← Wire profile data (Session 6.1)
│   │   ├── edit_profile_screen.dart        ← PUT /api/profile (Session 6.2)
│   │   └── my_vehicles_screen.dart         ← Local SharedPreferences storage (Session 6.3)
│   └── provider/
│       ├── provider_dashboard_screen.dart  ← GET /api/providers/:id/stats (Session 4.1)
│       ├── provider_slot_status_screen.dart ← GET spaces + toggle status (Session 4.2)
│       ├── provider_bookings_screen.dart    ← GET /api/bookings/provider/:id (Session 4.3)
│       ├── provider_qr_validator_screen.dart ← MobileScanner + check-in API (Session 5)
│       ├── provider_controls_screen.dart    ← Surge pricing + hours (Session 4.4)
│       └── provider_profile_screen.dart     ← Provider info + logout (Session 6.4)

backend/src/
├── controllers/
│   ├── authController.ts       ← User sync on first login
│   ├── bookingController.ts    ← createBooking, checkInBooking, cancelBooking
│   ├── parkingController.ts    ← getLots, getLotById, updateSlotStatus (ADD this)
│   ├── providerController.ts   ← getStats ✅, getSpaces ✅, updateSettings (ADD this)
│   └── profileController.ts   ← getProfile, updateProfile
├── routes/
│   ├── bookingRoutes.ts        ← Already complete ✅
│   └── parkingRoutes.ts        ← Add slot status update route
└── services/
    ├── bookingService.ts       ← Core booking logic ✅
    └── providerService.ts      ← getProviderRevenueStats ✅ — verify output matches Flutter model
```

---

## ⚠️ Security Checklist (Do Before Any Git Push)

- [ ] `backend/.env` is in `.gitignore` — **the Supabase password was committed in the original zip; rotate it in Supabase dashboard NOW**
- [ ] `google-services.json` is in `.gitignore` (it contains an API key)
- [ ] `build/` and `.dart_tool/` are in `.gitignore`
- [ ] No hardcoded API keys or secrets anywhere in `lib/`

---

## 📝 Known Limitations (Add to README after completing all sessions)

> **Scope decisions made for this version:**
> - **No Google Maps view:** The Find Parking screen uses a filterable list view with real data. Map integration is in the stretch goals — the list approach provides equivalent functionality with better performance on low-end devices.
> - **No payment gateway:** The confirmation and payment screens use mock payment method selection. Razorpay integration is the next planned milestone.
> - **Email/password + Google auth only:** No phone OTP or Apple Sign-In. Firebase makes adding these straightforward when needed.
> - **No push notifications:** FCM infrastructure exists in the backend (`firebase-admin`). The notification service is scaffolded but not triggered.

---

*Plan written 2026-08-14. Check off sessions above as you complete them.*
