# 🚗 ParkPilot

### Intelligent Android Parking Navigation & Reservation System

[![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Android](https://img.shields.io/badge/Platform-Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)](https://developer.android.com)
[![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Node.js](https://img.shields.io/badge/Node.js-18+-339933?style=for-the-badge&logo=node.js&logoColor=white)](https://nodejs.org)
[![Express](https://img.shields.io/badge/Express-4.19-000000?style=for-the-badge&logo=express&logoColor=white)](https://expressjs.com)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.3-3178C6?style=for-the-badge&logo=typescript&logoColor=white)](https://www.typescriptlang.org)
[![Prisma](https://img.shields.io/badge/Prisma-5.10-2D3748?style=for-the-badge&logo=prisma&logoColor=white)](https://www.prisma.io)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15+-4169E1?style=for-the-badge&logo=postgresql&logoColor=white)](https://www.postgresql.org)
[![Firebase](https://img.shields.io/badge/Firebase-Auth%20%26%20FCM-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com)

**ParkPilot** is an Android mobile parking platform that seamlessly connects **drivers looking for parking spaces** with **parking providers managing and monetizing their facilities**.

The application eliminates urban parking friction by enabling real-time parking space discovery, interactive map navigation, advance slot reservations, digital QR verification, and automated occupancy & revenue analytics for space owners.

---

## 📋 Table of Contents
- [🎯 Objectives & Solution](#-objectives--solution)
- [👥 User Roles](#-user-roles)
  - [🚘 Customer (Driver)](#-customer-driver)
  - [🅿️ Parking Provider](#%EF%B8%8F-parking-provider)
- [✨ Key Features & Highlights](#-key-features--highlights)
- [📱 Screen Architecture](#-screen-architecture)
  - [Customer Experience](#customer-experience)
  - [Provider Experience](#provider-experience)
- [🏗️ System Architecture](#%EF%B8%8F-system-architecture)
- [🗄️ Database Schema & Data Models](#%EF%B8%8F-database-schema--data-models)
- [🔌 REST API Reference](#-rest-api-reference)
- [📁 Folder & Project Structure](#-folder--project-structure)
- [🛠️ Installation & Setup Guide](#%EF%B8%8F-installation--setup-guide)
  - [Prerequisites](#prerequisites)
  - [1. Backend Setup](#1-backend-setup)
  - [2. Flutter Android Setup](#2-flutter-android-setup)
- [⚙️ Environment Variables](#%EF%B8%8F-environment-variables)
- [🧪 Database Seeding](#-database-seeding)
- [🚀 Future Roadmap](#-future-roadmap)
- [📄 License](#-license)

---

## 🎯 Objectives & Solution

### The Challenge
- Drivers waste an average of **15–20 minutes** per trip searching for vacant parking slots, contributing to urban traffic congestion and fuel wastage.
- Parking providers lack real-time visibility into occupancy, manual paper ticket verification causes bottlenecks, and revenue potential remains unoptimized.

### The ParkPilot Solution
ParkPilot bridges this gap by providing:
- **Instant Discovery**: GPS-located nearby parking with real-time slot availability.
- **Guaranteed Reservations**: Book specific parking slots in advance before arrival.
- **Touchless Verification**: Encrypted QR code generation and mobile camera scanning for fast gate check-in/out.
- **Provider Command Center**: Live slot management, occupancy tracking, and multi-tier revenue analytics.

---

## 👥 User Roles

### 🚘 Customer (Driver)
Designed for users seeking fast, transparent, and hassle-free parking:
- **Discover Parking**: Browse nearby parking spots sorted by distance, price, and rating.
- **Map & GPS Integration**: Interactive Google Maps view with live location markers and turn-by-turn navigation.
- **Visual Slot Picker**: Select exact parking slots (e.g., A-1, B-4) via an interactive grid interface.
- **Digital Reservation Pass**: Receive instant booking confirmation with an offline-capable QR pass code.
- **Booking History**: Manage upcoming, checked-in, completed, and cancelled reservations.
- **Ratings & Reviews**: Rate parking locations and write feedback post-parking.

### 🅿️ Parking Provider
Designed for parking lot managers, commercial garages, and private space owners:
- **Provider Dashboard**: Real-time overview of active bookings, total revenue, available slots, and occupancy rates.
- **Facility Management**: Add, update, or disable parking spaces, set hourly rates, capacity, and operating hours.
- **Live Slot Control**: Monitor individual slot availability (Covered, Open, Multi-Level, Valet).
- **Built-in QR Scanner**: Integrated mobile scanner using device camera (`mobile_scanner`) to validate check-ins.
- **Revenue Analytics**: Daily, weekly, and monthly financial breakdowns with transaction logs.

---

## ✨ Key Features & Highlights

| Feature | Description | Tech Stack |
| :--- | :--- | :--- |
| **Dual-Role Switcher** | Switch between Customer and Provider interfaces seamlessly within a single app shell. | Flutter State Management |
| **GPS & Interactive Maps** | Dynamic map view displaying custom markers, cluster availability, and direction links. | `google_maps_flutter` / Maps API |
| **Grid Slot Selection** | Visual slot selection interface showing occupied, reserved, and available spots. | Flutter Custom Widgets |
| **QR Gate Verification** | Unique encrypted QR code generation (`qr_flutter`) and camera validation (`mobile_scanner`). | Mobile Scanner + REST API |
| **Prisma & PostgreSQL** | Robust relational data backend with strict type safety and relational cascade deletes. | Express, Prisma ORM, Postgres |
| **Firebase Auth & FCM** | Secure user authentication and real-time push notification support for booking events. | Firebase Admin & Android SDK |

---

## 📱 Screen Architecture

```text
ParkPilot Android Application
├── 🏠 App Shell (Role Switcher & Navigation)
├── 🚘 Customer Flow
│   ├── Customer Home (Location Banner, Quick Actions, Nearby Cards)
│   ├── Find Parking (Interactive Map + Search & Filter List)
│   ├── Parking Details (Image Carousel, Pricing, Operating Hours, Amenities)
│   ├── Slot Selection (Grid Layout: Covered/Open/Multi-level slots)
│   ├── Booking Confirmation (Payment Breakdown, Time Duration, Slot ID)
│   ├── Reservation Pass (Digital Pass with Encrypted QR Code)
│   ├── Booking History (Active, Checked-In, Past, Cancelled)
│   └── Customer Profile (Account Info, Preferences, Support)
└── 🅿️ Provider Flow
    ├── Provider Dashboard (Stats Cards: Revenue, Occupancy %, Active Bookings)
    ├── Slot Status Control (Live Capacity Toggles & Override Controls)
    ├── Booking Management (Check-in Filter, Status Updates, Customer Info)
    ├── QR Scanner / Validator (Camera Scanner for Entry Verification)
    ├── Provider Controls & Listings (Manage Facilities & Pricing)
    └── Provider Profile (Business Details, Payout Settings)
```

---

## 🏗️ System Architecture

```mermaid
graph TD
    subgraph Client ["Flutter Android Application"]
        UI[App Shell & Role Switcher]
        Cust[Customer UI Modules]
        Prov[Provider UI Modules]
        QRGen[QR Generator]
        QRScan[Camera QR Scanner]
    end

    subgraph Firebase ["Firebase Cloud Platform"]
        FAuth[Firebase Auth]
        FCM[Cloud Messaging]
    end

    subgraph Backend ["Node.js + Express REST API Server"]
        AuthMid[Auth & Verification Middleware]
        UserCtrl[User Controller]
        ParkCtrl[Parking Controller]
        BookCtrl[Booking Controller]
        ProvCtrl[Provider Analytics Controller]
    end

    subgraph Database ["Database Layer"]
        Prisma[Prisma ORM]
        PostgreSQL[(PostgreSQL Database)]
    end

    UI --> Cust
    UI --> Prov
    Cust --> QRGen
    Prov --> QRScan

    Client <-->|Token Auth| FAuth
    Client <-->|HTTP REST JSON| Backend
    Backend <-->|SQL Queries| Prisma
    Prisma <--> PostgreSQL
    Backend -->|Push Notifications| FCM
```

---

## 🗄️ Database Schema & Data Models

The database is built on PostgreSQL using **Prisma ORM** ([backend/prisma/schema.prisma](file:///c:/Users/Admin/Desktop/MAD/backend/prisma/schema.prisma)).

```mermaid
erDiagram
    User ||--o{ ParkingSpace : "owns (Provider)"
    User ||--o{ Booking : "makes (Customer)"
    User ||--o{ Review : "writes"
    User ||--o{ Notification : "receives"
    ParkingSpace ||--o{ Booking : "contains"
    ParkingSpace ||--o{ Review : "receives"
    Booking ||--o| Payment : "has"

    User {
        string id PK
        string firebaseUid UK
        string name
        string email UK
        string phone
        UserRole role
        datetime createdAt
    }

    ParkingSpace {
        string id PK
        string providerId FK
        string name
        string address
        float latitude
        float longitude
        ParkingType parkingType
        int totalSlots
        int availableSlots
        float pricePerHour
        ParkingStatus status
    }

    Booking {
        string id PK
        string customerId FK
        string parkingSpaceId FK
        datetime bookingDate
        datetime startTime
        datetime endTime
        float duration
        string slotNumber
        float totalAmount
        BookingStatus status
        string qrCode UK
    }

    Payment {
        string id PK
        string bookingId FK
        float amount
        PaymentMethod paymentMethod
        PaymentStatus status
        string transactionId
    }
```

### Core Enums

- **`UserRole`**: `CUSTOMER`, `PROVIDER`, `BOTH`
- **`ParkingType`**: `COVERED`, `OPEN`, `MULTI_LEVEL`, `VALET`
- **`ParkingStatus`**: `ACTIVE`, `INACTIVE`, `MAINTENANCE`
- **`BookingStatus`**: `PENDING`, `CONFIRMED`, `CHECKED_IN`, `COMPLETED`, `CANCELLED`
- **`PaymentMethod`**: `CARD`, `UPI`, `WALLET`, `CASH`
- **`PaymentStatus`**: `PENDING`, `COMPLETED`, `FAILED`, `REFUNDED`

---

## 🔌 REST API Reference

The backend API runs on Node.js/Express with modular routing ([backend/src/routes/](file:///c:/Users/Admin/Desktop/MAD/backend/src/routes)).

### Health Check
- `GET /api/health` - Check API server uptime & status.

### User Routes (`/api/users`)
- `POST /api/users/sync` - Synchronize Firebase Auth user with database.
- `GET /api/users/profile` - Fetch current user profile.
- `PUT /api/users/profile` - Update profile information.

### Parking Routes (`/api/parking`)
- `GET /api/parking` - Search & discover parking spaces (Supports `lat`, `lng`, `radius`, `search`).
- `GET /api/parking/:id` - Fetch detailed information for a specific parking facility.
- `POST /api/parking` - Register a new parking space (Provider only).
- `PUT /api/parking/:id` - Update parking details & availability.
- `DELETE /api/parking/:id` - Delete a parking space.

### Booking Routes (`/api/bookings`)
- `POST /api/bookings` - Create a new parking reservation slot.
- `GET /api/bookings/my-bookings` - Retrieve customer reservation history.
- `GET /api/bookings/:id` - Fetch booking details and QR payload.
- `POST /api/bookings/verify-qr` - Validate customer QR code at check-in (Provider gate scan).
- `PATCH /api/bookings/:id/cancel` - Cancel an active reservation.

### Provider Analytics Routes (`/api/provider`)
- `GET /api/provider/dashboard` - Get provider metrics (total spaces, active bookings, live occupancy, total revenue).
- `GET /api/provider/bookings` - List all bookings for provider-owned parking lots.
- `PATCH /api/provider/slots` - Update live slot counts and operating status.

---

## 📁 Folder & Project Structure

```text
MAD/
├── android/                        # Android Native Project Files (com.parkpilot.app)
├── assets/                         # Application Images & Graphics
├── lib/                            # Flutter Frontend Source Code
│   ├── firebase_options.dart       # Firebase Client Configurations
│   ├── main.dart                   # Application Entrypoint & Theme Config
│   ├── models/                     # Dart Data Models (ParkingLot, etc.)
│   ├── services/                   # API Services & Mock Data Provider
│   └── screens/                    # UI Screen Components
│       ├── app_shell.dart          # Master Shell with Role Navigation
│       ├── customer/               # Customer Screens (Home, Find, Details, Slot Picker, Pass)
│       └── provider/               # Provider Screens (Dashboard, QR Validator, Controls, Bookings)
├── backend/                        # Express + TypeScript Backend
│   ├── prisma/                     # Database Schema & Migrations
│   │   ├── schema.prisma           # Prisma Data Models & Relations
│   │   ├── seed.ts                 # Database Seeding Script
│   │   └── tsconfig.json           # Prisma TypeScript Config
│   ├── src/                        # Backend Application Source
│   │   ├── server.ts               # Server Entrypoint
│   │   ├── app.ts                  # Express App Initialization
│   │   ├── config/                 # Environment & Firebase Admin Configs
│   │   ├── controllers/            # Request Handlers
│   │   ├── middleware/             # Auth & Error Handling Middleware
│   │   ├── routes/                 # Endpoint Route Definitions
│   │   ├── services/               # Business Logic Services
│   │   ├── types/                  # TypeScript Interfaces & Enums
│   │   └── utils/                  # Helper Utilities
│   ├── package.json                # Backend Dependencies & Scripts
│   └── tsconfig.json               # Root TypeScript Config
└── pubspec.yaml                    # Flutter Dependencies & Assets Manifest
```

---

## 🛠️ Installation & Setup Guide

### Prerequisites
Ensure you have the following installed on your development machine:
- **Flutter SDK** (`>= 3.0.0`)
- **Android Studio** & **Android SDK / Emulator** (or physical Android device with USB debugging enabled)
- **Node.js** (`>= 18.0.0`) & **npm**
- **PostgreSQL** database (Local instance or Cloud Provider like Supabase/Neon)
- **Firebase CLI** (`npm i -g firebase-tools`) & **FlutterFire CLI**

---

### 1. Backend Setup

1. **Navigate to the backend directory**:
   ```bash
   cd backend
   ```

2. **Install Node.js dependencies**:
   ```bash
   npm install
   ```

3. **Configure Environment Variables**:
   Create a `.env` file in the `backend/` directory (see [.env sample](#%EF%B8%8F-environment-variables)):
   ```bash
   cp .env.example .env
   ```

4. **Run Database Migrations & Generate Prisma Client**:
   ```bash
   npm run prisma:generate
   npm run prisma:migrate
   ```

5. **Seed Database with Initial Data**:
   ```bash
   npm run prisma:seed
   ```

6. **Start the Development Server**:
   ```bash
   npm run dev
   ```
   *The backend REST API will start on `http://localhost:5000` (Health check at `http://localhost:5000/api/health`).*

---

### 2. Flutter Android Setup

1. **Navigate to the project root directory**:
   ```bash
   cd ..
   ```

2. **Install Flutter dependencies**:
   ```bash
   flutter pub get
   ```

3. **Configure Firebase for Android**:
   ```bash
   flutterfire configure --project=parkpilot-242eb --android-package-name=com.parkpilot.app
   ```

4. **Run on Android Emulator or Physical Device**:
   ```bash
   flutter run
   ```

---

## ⚙️ Environment Variables

### Backend Configuration (`backend/.env`)

```env
# Server Config
PORT=5000
NODE_ENV=development

# Database Connection (PostgreSQL)
DATABASE_URL="postgresql://postgres:postgres@localhost:5432/parkpilot?schema=public"

# Firebase Admin SDK Credentials
FIREBASE_PROJECT_ID="parkpilot-242eb"
FIREBASE_CLIENT_EMAIL="firebase-adminsdk@parkpilot-242eb.iam.gserviceaccount.com"
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nYOUR_PRIVATE_KEY_HERE\n-----END PRIVATE KEY-----"

# Google Maps API Key (Optional for backend distance matrix)
GOOGLE_MAPS_API_KEY="YOUR_GOOGLE_MAPS_API_KEY"
```

---

## 🧪 Database Seeding

The backend includes an automated database seed script ([backend/prisma/seed.ts](file:///c:/Users/Admin/Desktop/MAD/backend/prisma/seed.ts)) that populates:
- Sample Customer and Parking Provider accounts
- Realistic parking locations across major city zones (Mall Parking, Metro Parking, Airport Parking)
- Active & completed booking records with pre-generated QR codes
- Review records and notifications

To re-seed the database at any time:
```bash
cd backend
npm run prisma:seed
```

---

## 🚀 Future Roadmap

- [ ] **IoT Parking Sensor Integration**: Live physical hardware slot status synchronization via MQTT / WebSockets.
- [ ] **Automatic License Plate Recognition (ALPR)**: Camera-based automated barrier gate opening without manual QR scan.
- [ ] **In-App Payment Gateway**: Integration with Razorpay / Stripe for automatic UPI and Card payments.
- [ ] **EV Charging Slot Reservation**: Reserve dedicated Electric Vehicle charging stations with power output filters.
- [ ] **Dynamic Surge Pricing Algorithm**: Automatic hourly rate adjustments based on real-time peak demand.

---

## 📄 License

This project is licensed under the [MIT License](LICENSE) - feel free to use and adapt ParkPilot for your own application needs.

---

<p center="text-center">
  <b>Built with ❤️ using Flutter, Android, Node.js, Prisma & Firebase</b>
</p>