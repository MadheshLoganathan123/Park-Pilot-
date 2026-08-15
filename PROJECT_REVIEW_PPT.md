# ParkPilot — Project Review Presentation Guide

> **Purpose:** Use this document as the source material for your Project Review PPT.  
> Each section below maps to one or more slides. Copy headings as slide titles and bullets as slide content.

---

## Slide 1 — Title Slide

**ParkPilot**  
*Intelligent Parking Navigation & Slot Reservation System*

- **Project Type:** Full-stack mobile + web application
- **Platform:** Flutter (Android, Web, Windows) + Node.js REST API
- **Domain:** Smart Mobility / Urban Parking Management
- **Version:** 1.0.0
- **Tagline:** *Find. Book. Park. Manage.*

**Suggested visuals:** App logo, parking map screenshot, dual-role UI mockup

---

## Slide 2 — Problem Statement

### The Urban Parking Challenge

| Problem | Impact |
|---------|--------|
| Drivers cannot find vacant slots quickly | 15–20 minutes wasted per trip |
| No advance booking | Uncertainty and last-minute stress |
| Manual gate verification | Long queues at parking entrances |
| Providers lack live occupancy data | Revenue loss and poor space utilization |
| Fragmented payment & records | No unified digital trail |

### Why It Matters

Urban congestion, fuel waste, and poor parking infrastructure affect millions of daily commuters. A digital platform that connects **drivers** and **parking operators** in real time solves a practical, high-frequency problem.

---

## Slide 3 — Proposed Solution

### ParkPilot Overview

ParkPilot is a **dual-role smart parking platform** that enables:

1. **Customers** to discover nearby parking, reserve slots, and use a digital QR pass for entry
2. **Providers** to manage facilities, monitor occupancy, validate check-ins, and track revenue

### Core Value Proposition

| Stakeholder | Value Delivered |
|-------------|-----------------|
| **Customer** | Faster parking discovery, guaranteed reservations, digital pass |
| **Provider** | Live dashboard, slot control, QR validation, booking analytics |
| **City / Ecosystem** | Reduced circling traffic, digitized parking operations |

---

## Slide 4 — Project Objectives

### Primary Objectives

- Build a **cross-platform Flutter app** with separate Customer and Provider experiences
- Implement **secure authentication** using Firebase
- Provide **real-time parking discovery** with map-based visualization
- Enable **slot-based booking** with confirmation and QR reservation pass
- Offer **provider tools** for facility management, slot status, and QR scanning
- Connect to a **scalable backend** with PostgreSQL and REST APIs

### Secondary Objectives

- Light-theme, modern mobile-first UI
- Offline-capable session persistence (SharedPreferences)
- Extensible database schema for payments, reviews, and notifications
- Support for web demo (Chrome) and Android deployment

---

## Slide 5 — Technology Stack

### Frontend (Flutter)

| Layer | Technology |
|-------|------------|
| Framework | Flutter 3.x / Dart 3.x |
| Auth | Firebase Auth + Google Sign-In |
| Storage | Firebase Storage (profile images) |
| Maps | OpenStreetMap tiles + OSRM routing (`flutter_map`, `latlong2`) |
| Location | `geolocator` (GPS) |
| QR | `qr_flutter` (generate pass), `mobile_scanner` (provider scan) |
| HTTP | `http` package with Firebase Bearer tokens |
| Local state | `SharedPreferences` + `ParkingDataService` singleton |

### Backend

| Layer | Technology |
|-------|------------|
| Runtime | Node.js 18+ |
| Framework | Express 4.x + TypeScript |
| ORM | Prisma 5.x |
| Database | PostgreSQL (Supabase-hosted) |
| Auth verification | Firebase Admin SDK |
| Validation | Zod |
| Security | Helmet, CORS, RBAC middleware |

---

## Slide 6 — System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    FLUTTER CLIENT                            │
│  Login → AppShell → Customer Tabs | Provider Tabs           │
│  ParkingDataService → ApiClient → Firebase ID Token           │
└──────────────────────────┬──────────────────────────────────┘
                           │ HTTPS REST (JSON)
                           ▼
┌─────────────────────────────────────────────────────────────┐
│              NODE.JS EXPRESS API (:5000/api)                 │
│  Auth Middleware → RBAC → Controllers → Services             │
└──────────────────────────┬──────────────────────────────────┘
                           │ Prisma ORM
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                   POSTGRESQL (Supabase)                      │
│  users · parking_spaces · bookings · payments · reviews      │
└─────────────────────────────────────────────────────────────┘

External: Firebase Auth · OpenStreetMap · OSRM Routing
```

### Architecture Highlights

- **Client–server separation** with REST API contract
- **Firebase** handles identity; **PostgreSQL** stores business data
- **Role-based access** on every protected endpoint
- **Singleton service pattern** on Flutter for centralized state

---

## Slide 7 — User Roles & Access

### Two Distinct User Personas

| Role | Selected At | Bottom Navigation |
|------|-------------|-------------------|
| **Customer** | Login / Sign-up | Home · Explore · Reservations · Profile |
| **Provider** | Login / Sign-up | Dashboard · Slots · Bookings · Profile |

### Customer Capabilities

- Search and filter parking near Chennai Central (demo region)
- View lot details, pricing, amenities, and ratings
- Select time slot, duration, and parking slot from visual grid
- Book a spot and receive a **QR reservation pass**
- View upcoming, past, and cancelled bookings
- Manage profile, vehicles, and settings

### Provider Capabilities

- View revenue, occupancy, and active booking stats
- Manage parking spaces (create/edit lots, pricing, capacity)
- Monitor and update individual slot status (available / occupied / maintenance)
- Scan customer QR codes for check-in validation
- Review all bookings linked to owned facilities

---

## Slide 8 — Customer Module (Screens & Flow)

### Customer Screen Map

```
Login / Sign Up
    └── App Shell (Customer)
            ├── Home        → Search, filters, map preview, nearby lots
            ├── Explore     → Full search, sort, list/map browse
            ├── Reservations→ Booking history (upcoming / past / cancelled)
            └── Profile     → Edit profile, vehicles, settings, logout

Drill-down flows:
    Home/Explore → Parking Details → Slot Selection → Confirmation → QR Pass
    Home         → Live Parking Map (OSM + markers + routing)
```

### Customer Home Features (Latest)

- **In-place search** by name or address
- **Category filters:** All · Available · EV Fast · Top Rated
- **Sort sheet (tune icon):** Nearest · Price · Availability · Rating
- **Live map radar card** with OSM preview and lot pins
- **Parking cards** with rating, slots left, EV bays, hourly rate, Book Spot CTA

---

## Slide 9 — Provider Module (Screens & Flow)

### Provider Screen Map

```
Login (Provider role)
    └── App Shell (Provider)
            ├── Dashboard   → Revenue, occupancy, quick actions, QR validator
            ├── Slots       → Grid view, filter by status, update slots
            ├── Bookings    → Search, date filters, booking list
            └── Profile     → Business info, facility management, logout

Drill-down:
    Dashboard → Manage Parking Space (CRUD)
    Dashboard → QR Validator (camera scan + manual code entry)
```

### Provider Dashboard Highlights

- Real-time stats refresh (revenue, available slots, active bookings)
- Occupancy visualization
- Quick navigation to slot management and QR scanning
- Facility listing and management shortcuts

---

## Slide 10 — Key Features Demonstration Points

| # | Feature | Description | Demo Tip |
|---|---------|-------------|----------|
| 1 | **Dual-role login** | Customer vs Provider at sign-in | Show role toggle on login screen |
| 2 | **Firebase authentication** | Email/password + Google Sign-In | Demo account quick-fill buttons |
| 3 | **OpenStreetMap integration** | Free map tiles, no API key required | Open Live Map screen |
| 4 | **GPS & routing** | User location + OSRM driving routes | Show navigation to a lot |
| 5 | **Visual slot picker** | Grid with floor filter, time, duration | Slot Selection screen |
| 6 | **Booking & QR pass** | Confirmed booking with scannable QR | Reservation Pass screen |
| 7 | **QR validator** | Provider scans customer pass | Provider QR Validator |
| 8 | **Search & filters** | Home in-place search + sort sheet | Type "Chennai" or filter EV |
| 9 | **Booking history** | Tabbed upcoming / past / cancelled | Reservations tab |
| 10 | **Provider analytics** | Dashboard metrics from live API data | Provider Dashboard |

---

## Slide 11 — Booking Lifecycle

### End-to-End Booking Flow

```
1. DISCOVER   → Customer browses parking lots (Home / Explore / Map)
2. DETAILS    → Views pricing, address, amenities, ratings
3. SELECT     → Picks slot, time window, and duration
4. BOOK       → POST /api/bookings → server creates booking + payment record
5. CONFIRM    → Confirmation screen with booking summary
6. QR PASS    → Digital pass with unique QR code for entry
7. CHECK-IN   → Provider scans QR → booking status → CHECKED_IN
8. COMPLETE   → Session ends → COMPLETED (or CANCELLED if refunded)
```

### Booking Status States

| Status | Meaning |
|--------|---------|
| `PENDING` | Order initiated, awaiting confirmation |
| `CONFIRMED` | Slot reserved, QR pass active |
| `CHECKED_IN` | Provider validated entry |
| `COMPLETED` | Parking session finished |
| `CANCELLED` | Booking cancelled |

---

## Slide 12 — Authentication & Security

### Authentication Flow

```
Flutter Login
    → Firebase signInWithEmailAndPassword (or Google)
    → Firebase ID Token issued
    → POST /api/auth/sync { role: CUSTOMER | PROVIDER }
    → Backend verifies token (Firebase Admin SDK)
    → User profile created/updated in PostgreSQL
    → Session saved locally (SharedPreferences)
    → Navigate to AppShell dashboard
```

### Security Measures

- Firebase ID tokens on every API request (`Authorization: Bearer`)
- Backend never trusts client-supplied user IDs — uses decoded Firebase UID
- Role-based access control (RBAC) on provider vs customer endpoints
- Helmet security headers on Express
- Zod request body validation
- Environment secrets stored in `.env` (never in Flutter client)
- Server-side amount calculation for bookings

---

## Slide 13 — Database Design

### Entity Relationship (Core Models)

```
User ──owns──► ParkingSpace ──has──► Booking ──has──► Payment
  │                │                    │
  ├── Booking      └── Review           └── Notification
  └── Review
```

### Main Tables

| Model | Purpose |
|-------|---------|
| **User** | Customers and providers (firebaseUid, role, profile) |
| **ParkingSpace** | Lot details, geo coordinates, slots, pricing |
| **Booking** | Reservation with times, slot, amount, QR code, status |
| **Payment** | Transaction linked 1:1 to booking |
| **Review** | Customer ratings for parking spaces |
| **Notification** | Booking confirmations, reminders, cancellations |

### Key Enums

- `UserRole`: CUSTOMER, PROVIDER, BOTH
- `ParkingType`: COVERED, OPEN, MULTI_LEVEL, VALET
- `BookingStatus`: PENDING → CONFIRMED → CHECKED_IN → COMPLETED / CANCELLED

---

## Slide 14 — REST API Overview

**Base URL:** `http://localhost:5000/api` (dev) · `http://10.0.2.2:5000/api` (Android emulator)

| Module | Key Endpoints |
|--------|---------------|
| **Health** | `GET /health` |
| **Auth** | `POST /auth/sync` |
| **Profile** | `GET /profile`, `PUT /profile` |
| **Parking** | `GET /parking`, `GET /parking/nearby`, `GET /parking/:id`, `POST/PUT/DELETE` (provider) |
| **Bookings** | `POST /bookings`, `GET /bookings/customer/:id`, `PUT /bookings/:id/cancel`, `POST /bookings/verify-qr`, `PUT /bookings/:id/check-in` |
| **Providers** | `GET /providers/:id/stats`, `GET /providers/:id/bookings`, `PUT /providers/spaces/:id/slots/:id/status` |

### API Response Format

```json
{
  "success": true,
  "message": "Operation description",
  "data": { ... }
}
```

---

## Slide 15 — UI/UX Design

### Design System

| Element | Value |
|---------|-------|
| Primary color | `#005DAC` (ParkPilot Blue) |
| Theme | Light mode, clean white cards |
| Typography | Google Fonts |
| Layout | Mobile-first, max-width 440px on wide screens |
| Components | Rounded cards, chip filters, bottom navigation, Material 3 |

### UX Principles Applied

- **Role clarity** — Customer and Provider see completely different tab layouts
- **Progressive disclosure** — Home summary → Details → Slot pick → Confirm → Pass
- **Real-time feedback** — Loading states, error banners, pull-to-refresh
- **Quick actions** — Demo login buttons, Book Spot, Open Map, QR scan
- **Accessibility** — Clear labels, icon + text navigation, form validation

---

## Slide 16 — Data Flow Example (Login to Booking)

```
┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
│  Login   │───►│ Firebase │───►│ /auth/   │───►│ AppShell │
│  Screen  │    │   Auth   │    │  sync    │    │  (Home)  │
└──────────┘    └──────────┘    └──────────┘    └────┬─────┘
                                                       │
                       ┌───────────────────────────────┘
                       ▼
              ┌────────────────┐
              │ GET /parking   │ → List lots on Home/Explore
              └───────┬────────┘
                      ▼
              ┌────────────────┐
              │ Slot Selection │ → User picks slot + time
              └───────┬────────┘
                      ▼
              ┌────────────────┐
              │ POST /bookings │ → Booking + Payment + QR created
              └───────┬────────┘
                      ▼
              ┌────────────────┐
              │ QR Pass Screen │ → Customer shows QR at gate
              └───────┬────────┘
                      ▼
              ┌────────────────┐
              │ Provider Scan  │ → POST /bookings/verify-qr
              └────────────────┘
```

---

## Slide 17 — Project Structure

```
MAD/
├── lib/                          # Flutter frontend
│   ├── main.dart                 # App entry, Firebase init
│   ├── models/                   # ParkingLot, Booking, UserProfile
│   ├── services/                 # API client, parking data, maps, profile
│   ├── screens/
│   │   ├── customer/             # 12+ customer screens
│   │   ├── provider/             # 7 provider screens
│   │   ├── app_shell.dart        # Role-based navigation shell
│   │   └── login_screen.dart
│   ├── theme/                    # AppTheme, logo
│   └── widgets/                  # Shared components
├── backend/
│   ├── prisma/schema.prisma      # Database models
│   ├── src/
│   │   ├── routes/               # API route modules
│   │   ├── controllers/          # HTTP handlers
│   │   ├── services/             # Business logic
│   │   ├── middleware/           # Auth, RBAC, validation
│   │   └── config/               # Env, Firebase, Prisma
│   └── package.json
├── assets/images/                # App logo and graphics
├── pubspec.yaml                  # Flutter dependencies
└── README.md                     # Setup documentation
```

---

## Slide 18 — Testing & Quality Assurance

### What Was Tested

| Area | Method | Result |
|------|--------|--------|
| Flutter static analysis | `flutter analyze lib` | No issues |
| Backend TypeScript | `npx tsc --noEmit` | Compiles clean |
| API health | `GET /api/health` | Server UP |
| Firebase + sync login | REST API test | Customer & provider sync OK |
| Wrong password | Firebase auth | Correctly rejected |
| Login error messaging | Backend down scenario | Clear server unreachable message |
| Search & filters | Manual UI test | Home filters list in place |

### Demo Accounts (Seed Data)

| Role | Email | Password |
|------|-------|----------|
| Customer | `customer@parkpilot.com` | `password123` |
| Provider | `provider@parkpilot.com` | `password123` |

---

## Slide 19 — Challenges & Solutions

| Challenge | Solution Implemented |
|-----------|---------------------|
| Backend unreachable during login | Improved error messages; sign out on failed sync |
| Android emulator vs localhost | `10.0.2.2` mapping in `ApiConfig` |
| Map API costs | Switched to **OpenStreetMap + OSRM** (free, no API key) |
| Dual-role single app | `AppShell` with role-based tab sets |
| Slot visualization without per-slot DB rows | Client-side slot grid synthesized from aggregate counts |
| Firebase ↔ DB user mapping | `/auth/sync` links `firebaseUid` to PostgreSQL profile |
| Search bar was non-functional on Home | Added in-place search + sort bottom sheet |

---

## Slide 20 — Future Enhancements

| Priority | Feature |
|----------|---------|
| High | **Razorpay / payment gateway** — UPI, card, netbanking at checkout |
| High | **Push notifications (FCM)** — booking confirmations and reminders |
| Medium | **IoT sensor integration** — real hardware slot occupancy |
| Medium | **ALPR** — automatic license plate recognition at gates |
| Medium | **Dynamic surge pricing** — demand-based hourly rates |
| Low | **Reviews UI** — customer rating flow post-parking |
| Low | **Multi-city expansion** — beyond Chennai demo data |

---

## Slide 21 — Conclusion

### Project Summary

ParkPilot successfully delivers a **full-stack intelligent parking platform** combining:

- Modern **Flutter** cross-platform UI
- Secure **Firebase** authentication
- Scalable **Node.js + Prisma + PostgreSQL** backend
- **OpenStreetMap**-based discovery and navigation
- **QR-based** touchless check-in for providers
- Separate **Customer** and **Provider** operational dashboards

### Key Takeaways for Reviewers

1. Solves a **real-world urban mobility problem** with practical features
2. Demonstrates **full software engineering lifecycle** — frontend, backend, database, auth, APIs
3. Architecture is **extensible** for payments, IoT, and analytics
4. UI is **production-quality** with consistent branding and responsive layout
5. Project is **demo-ready** with seeded data and working end-to-end booking flow

### One-Line Pitch

> *"ParkPilot turns parking from a stressful search into a one-tap reserve-and-scan experience — for drivers and lot owners alike."*

---

## Appendix A — Suggested PPT Slide Order (Quick Copy)

1. Title  
2. Problem Statement  
3. Solution Overview  
4. Objectives  
5. Technology Stack  
6. System Architecture  
7. User Roles  
8. Customer Module  
9. Provider Module  
10. Key Features Demo  
11. Booking Lifecycle  
12. Authentication & Security  
13. Database Design  
14. REST API  
15. UI/UX Design  
16. Data Flow Diagram  
17. Project Structure  
18. Testing & QA  
19. Challenges & Solutions  
20. Future Enhancements  
21. Conclusion & Q&A  

---

## Appendix B — Screenshot Checklist for PPT

Capture these screens for visual slides:

- [ ] Login screen (Customer / Provider toggle)
- [ ] Customer Home (search bar + filter chips + map card)
- [ ] Explore / Find Parking list
- [ ] Live Parking Map (OSM markers)
- [ ] Parking Details screen
- [ ] Slot Selection grid
- [ ] Booking Confirmation
- [ ] Reservation Pass (QR code)
- [ ] Customer Reservations history
- [ ] Provider Dashboard (stats)
- [ ] Provider Slot Status grid
- [ ] Provider QR Validator (camera)
- [ ] Architecture diagram (from Slide 6)
- [ ] Database ER diagram (from Slide 13)

---

## Appendix C — Speaker Notes (30-Second Elevator Pitch)

*"ParkPilot is a smart parking app built with Flutter and Node.js. Customers can find nearby parking on a live map, book a specific slot, and get a QR pass for entry. Parking providers get a dashboard to manage their lots, track occupancy and revenue, and scan QR codes at the gate. We use Firebase for secure login, PostgreSQL for data, and OpenStreetMap for free map navigation — making it scalable, affordable, and ready for real-world deployment."*

---

*Document generated for ParkPilot v1.0.0 — Project Review Presentation.*
