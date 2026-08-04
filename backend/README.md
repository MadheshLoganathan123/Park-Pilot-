# 🚗 ParkPilot – Intelligent Parking Navigation & Reservation System Backend

This repository contains the backend REST API services for **ParkPilot**, built using **Node.js, Express.js, TypeScript, PostgreSQL, Prisma ORM, Firebase Authentication**, and **Google Maps Platform APIs**.

---

## 📐 Project Architecture

```
backend/
├── src/
│   ├── config/          # Environment, Firebase, Prisma, and Google Maps SDK configurations
│   ├── controllers/     # Controller logic for Health, Users, Parking, Bookings, and Providers
│   ├── middleware/      # Auth (Firebase ID Token), RBAC, Zod Validation, Error Handling, Logger
│   ├── routes/          # Express route definitions
│   ├── services/        # Business logic: Booking transactions, Maps Haversine, Provider stats
│   ├── utils/           # QR generator, Haversine geo formula, logger, response wrappers
│   ├── types/           # Express type augmentation and DTO schemas
│   ├── app.ts           # Express application setup (Helmet, CORS, Morgan)
│   └── server.ts        # Server entrypoint and graceful shutdown listeners
├── prisma/
│   ├── schema.prisma    # Database models, relations, enums, and geospatial indexes
│   └── seed.ts          # Chennai parking spaces seed script
├── .env.example         # Environment template
├── package.json         # Node.js dependencies and scripts
├── tsconfig.json        # TypeScript configuration
└── README.md            # Comprehensive documentation
```

---

## 🛠️ Tech Stack & Prerequisites

- **Node.js** (v18+ recommended)
- **npm** (v9+)
- **PostgreSQL** (v14+ or Supabase Postgres instance)
- **TypeScript** (v5+)

---

## ⚙️ Step-by-Step Installation & Setup

### 1. Clone & Navigate to Backend
```bash
cd backend
```

### 2. Install Dependencies
```bash
npm install
```

### 3. Setup Environment Variables
Copy `.env.example` to create your local `.env` file:
```bash
cp .env.example .env
```

Edit `.env` with your PostgreSQL database URL, Google Maps API key, and Firebase credentials:
```env
PORT=5000
NODE_ENV=development
DATABASE_URL="postgresql://postgres:postgres@localhost:5432/parkpilot_db?schema=public"

# Google Maps Platform API (Optional - built-in Haversine fallback active if blank)
GOOGLE_MAPS_API_KEY=your_google_maps_api_key_here

# Firebase Admin Credentials
FIREBASE_PROJECT_ID=parkpilot-app
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@parkpilot-app.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nYOUR_PRIVATE_KEY_HERE\n-----END PRIVATE KEY-----\n"

CORS_ORIGIN="*"
```

---

## 🗄️ Database Setup & Prisma ORM

### 1. Generate Prisma Client
```bash
npx prisma generate
```

### 2. Run Database Migrations
Make sure your PostgreSQL database server is running, then execute:
```bash
npx prisma migrate dev --name init
```

### 3. Seed Database with Chennai Parking Locations
Populate initial provider, customer, and 5 prime Chennai parking locations (Express Avenue, T. Nagar MLP, Phoenix Marketcity, Marina Beach, Chennai Central):
```bash
npx prisma db seed
```
*Alternatively run:* `npm run prisma:seed`

---

## 🚀 Running the Development Server

Start the live-reloading development server:
```bash
npm run dev
```

The API will be available at:
`http://localhost:5000`

---

## 🔑 Authentication & Test Token System

The backend integrates with **Firebase Admin SDK** to verify ID Tokens passed in the `Authorization` header:
`Authorization: Bearer <firebase_id_token>`

### Development & Postman Testing Tokens
For quick testing without creating live Firebase tokens in Postman, use these dev tokens:
- **Customer Bearer Token**: `Bearer test-token-customer`
- **Provider Bearer Token**: `Bearer test-token-provider`

---

## 📡 API Endpoint Reference

### 🏥 Health Check
- `GET /api/health` — System status check

### 👤 User Operations
- `POST /api/users/sync` — Sync Firebase user profile to Postgres DB
- `GET /api/users/:id` — Fetch user profile *(Auth required)*
- `PUT /api/users/:id` — Update user profile *(Auth required)*

### 🚗 Parking Space Operations
- `GET /api/parking` — List all active parking spaces
- `GET /api/parking/nearby?lat=13.0587&lng=80.2641&radius=5` — Find nearby parking using Haversine algorithm
- `GET /api/parking/:id` — Get parking space details
- `GET /api/parking/:id/route?originLat=13.04&originLng=80.23` — Calculate route & drive time
- `POST /api/parking` — Create new space *(Provider only)*
- `PUT /api/parking/:id` — Edit space *(Provider only)*
- `DELETE /api/parking/:id` — Delete space *(Provider only)*

### 🎫 Booking Operations
- `POST /api/bookings` — Reserve slot with atomic overbooking lock *(Customer only)*
- `GET /api/bookings/:id` — Get booking details & QR *(Auth required)*
- `GET /api/bookings/customer/:customerId` — Customer booking history
- `GET /api/bookings/provider/:providerId` — Provider incoming bookings
- `PUT /api/bookings/:id/cancel` — Cancel booking and restore slot *(Customer only)*
- `POST /api/bookings/verify-qr` — Scan & verify QR token *(Provider / Scanner)*

### 📊 Provider Dashboard
- `GET /api/providers/:id/parking` — List owned spaces
- `GET /api/providers/:id/bookings` — View space reservations
- `GET /api/providers/:id/revenue` — Real-time revenue & occupancy analytics

---

## 🧪 Testing with Postman / cURL

### 1. Nearby Parking Search
```bash
curl -X GET "http://localhost:5000/api/parking/nearby?lat=13.0587&lng=80.2641&radius=10"
```

### 2. Create Booking (Customer)
```bash
curl -X POST "http://localhost:5000/api/bookings" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer test-token-customer" \
  -d '{
    "parkingSpaceId": "REPLACE_WITH_PARKING_SPACE_ID",
    "bookingDate": "2026-08-05T10:00:00.000Z",
    "startTime": "2026-08-05T10:00:00.000Z",
    "endTime": "2026-08-05T12:00:00.000Z",
    "paymentMethod": "UPI"
  }'
```

### 3. Verify QR Code (Provider Scanner)
```bash
curl -X POST "http://localhost:5000/api/bookings/verify-qr" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer test-token-provider" \
  -d '{
    "qrCode": "PARKPILOT-EA-MALL-A42-TESTQR"
  }'
```

---

## 📱 Connecting to Flutter/Dart Frontend

In your Flutter app, create an API client service using `http` or `dio`:

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class ParkPilotApiService {
  // Use http://10.0.2.2:5000 for Android Emulator or http://localhost:5000 for iOS Simulator
  static const String baseUrl = 'http://10.0.2.2:5000/api';

  Future<Map<String, String>> _getHeaders() async {
    final user = FirebaseAuth.instance.currentUser;
    final token = user != null ? await user.getIdToken() : 'test-token-customer';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<dynamic>> fetchNearbyParking(double lat, double lng, {double radius = 5.0}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/parking/nearby?lat=$lat&lng=$lng&radius=$radius'),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['data'];
    } else {
      throw Exception('Failed to load nearby parking spaces');
    }
  }

  Future<Map<String, dynamic>> createBooking({
    required String parkingSpaceId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/bookings'),
      headers: headers,
      body: jsonEncode({
        'parkingSpaceId': parkingSpaceId,
        'bookingDate': startTime.toIso8601String(),
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'paymentMethod': 'UPI',
      }),
    );

    return jsonDecode(response.body);
  }
}
```

---

## 🛡️ Security Features
- **Helmet**: Secures HTTP headers against standard vulnerabilities
- **CORS**: Configurable cross-origin origin filtering
- **Firebase Token Verification**: Authenticates all user & provider requests
- **Atomic Transactions**: Prevents slot double-booking concurrency issues
- **Zod Input Validation**: Sanitizes and validates request bodies and query parameters
