# ActsValid — Flutter Mobile Application

> **Legal Document Generation Platform** powered by LLaMA 3.1 AI, ED25519 Signatures & IPFS Storage

![Flutter](https://img.shields.io/badge/Flutter-3.10.1-02569B?style=for-the-badge&logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.10.1-0175C2?style=for-the-badge&logo=dart)
![BLoC](https://img.shields.io/badge/State-BLoC-purple?style=for-the-badge)
![Version](https://img.shields.io/badge/Version-1.0.0-green?style=for-the-badge)

---

## 📋 Table of Contents

- [Project Overview](#-project-overview)
- [Tech Stack](#-tech-stack)
- [Architecture](#-architecture)
- [Folder Structure](#-folder-structure)
- [Key Design Patterns](#-key-design-patterns)
- [Screens Implemented](#-screens-implemented)
- [API Integration](#-api-integration)
- [Design System](#-design-system)
- [Setup & Installation](#-setup--installation)
- [Pending Features](#-pending-features)
- [Development Notes](#-development-notes)

---

## 🏛️ Project Overview

ActsValid is a compliance-focused legal document generation mobile application.

| Property | Details |
|---|---|
| **App Name** | ActsValid |
| **Platform** | Flutter — iOS, Android, Windows |
| **Backend AI** | LLaMA 3.1 |
| **Storage** | IPFS (InterPlanetary File System) |
| **Signatures** | ED25519 Cryptographic Signatures |
| **Architecture** | Clean Architecture + BLoC Pattern |
| **Developer** | Jyoti |
| **Version** | 1.0.0 |
| **Dart SDK** | ^3.10.1 |

---

## 📦 Tech Stack

### Core Dependencies

| Package | Version | Purpose |
|---|---|---|
| `flutter_bloc` | ^8.1.3 | State management — BLoC pattern |
| `dio` | ^5.4.0 | HTTP client with interceptors |
| `flutter_secure_storage` | ^9.2.2 | Secure JWT token storage |
| `local_auth` | ^2.3.0 | Biometric authentication |
| `web_socket_channel` | ^2.4.0 | Real-time WebSocket connection |

### Why These Packages?

#### `flutter_bloc`
- Industry-standard state management for Flutter production apps
- Separates business logic from UI — testable and maintainable
- **Event → BLoC → State** pattern is predictable and debuggable

#### `dio`
- Interceptor support — automatically injects JWT tokens in every request
- Auto-refresh logic — refreshes token before 401 errors occur
- Better error handling than the default `http` package

#### `flutter_secure_storage`
- **iOS** → Apple Keychain (hardware-backed encryption)
- **Android** → Android Keystore (hardware-backed encryption)
- Normal `SharedPreferences` is NOT encrypted — unsafe for tokens

#### `local_auth`
- Supports fingerprint and Face ID on both iOS and Android
- Falls back to PIN/password if biometrics unavailable
- Required for **FR-AUTH-03** biometric login requirement

#### `web_socket_channel`
- Official Dart team package
- Real-time document processing status updates
- Required for **FR-DOC-04** pipeline status requirement

---

## 🏗️ Architecture

### Clean Architecture — 4 Layers

```
┌─────────────────────────────────┐
│         UI Layer                │
│   Screens, Widgets, Forms       │
│   lib/features/*/presentation/  │
├─────────────────────────────────┤
│         BLoC Layer              │
│   Business Logic, State Mgmt    │
│   lib/features/*/bloc/          │
├─────────────────────────────────┤
│       Repository Layer          │
│   API calls, Data Transform     │
│   lib/features/*/data/          │
├─────────────────────────────────┤
│        Service Layer            │
│   Auth, Token, Dio, WebSocket   │
│   lib/core/services/            │
└─────────────────────────────────┘
```

---

## 📁 Folder Structure

```
lib/
├── core/
│   ├── constants/
│   │   ├── api_constants.dart       # API URLs, WebSocket base
│   │   └── app_constants.dart       # Tab indices, app-wide constants
│   ├── networks/
│   │   └── dio_client.dart          # DioClient with interceptors
│   ├── services/
│   │   ├── auth_service.dart        # Login, logout, refresh
│   │   ├── token_service.dart       # JWT secure storage
│   │   └── websocket_service.dart   # WebSocket connection manager
│   └── theme/
│       └── app_theme.dart           # App-wide theme
├── features/
│   ├── auth/
│   │   ├── bloc/
│   │   │   └── auth_bloc.dart
│   │   └── presentation/
│   │       ├── login_screen.dart
│   │       └── splash_screen.dart
│   ├── documents/
│   │   ├── bloc/
│   │   │   └── document_bloc.dart
│   │   ├── data/
│   │   │   ├── document_model.dart
│   │   │   └── document_repository.dart
│   │   └── presentation/
│   │       ├── document_request_screen.dart
│   │       ├── document_list_screen.dart
│   │       └── document_detail_screen.dart
│   ├── home/
│   │   └── presentation/
│   │       └── home_screen.dart
│   ├── rates/
│   │   └── presentation/
│   │       └── rates_screen.dart
│   └── settings/
│       └── presentation/
│           └── settings_screen.dart
└── main.dart                        # Entry point + DI setup
```

---

## 🎯 Key Design Patterns

### 1. BLoC Pattern — State Management

```
User Action
    ↓  Event fire hoti hai
    ↓  BLoC event process karta hai
    ↓  API call → success / failure
    ↓  State emit hoti hai
    ↓  UI automatically rebuild hoti hai
```

### 2. Dependency Injection — Constructor Pattern

Services are created **once** in `main.dart` and passed via constructors. No global singletons.

```
TokenService → DioClient → AuthService    → AuthBloc
                         → DocumentRepository → DocumentBloc
             → WebSocketService           → DocumentBloc
```

### 3. MultiBlocProvider — Global State

`AuthBloc` and `DocumentBloc` provided at root level — accessible from any screen.

### 4. IndexedStack — Tab Persistence

```dart
// All 5 screens stay alive in memory
IndexedStack(
  index: _currentIndex,
  children: _screens,
)
// Switching tabs = changing visible index only
// No rebuild! No data loss!
```

### 5. Callback Pattern — Child to Parent Navigation

`DashboardTab` receives `VoidCallbacks` from `HomeScreen` to switch tabs — avoids breaking `IndexedStack` persistence.

### 6. JWT Token Lifecycle

| Event | Action |
|---|---|
| Login Success | Access + Refresh token → Keychain/Keystore |
| Every API Request | DioClient interceptor injects Bearer token |
| T-3 min before expiry | Auto-refresh triggered proactively |
| 401 Unauthorized | Refresh attempted → if fails → Logout |
| Logout | Server revoke + local tokens cleared |

### 7. WebSocket — Real-time Status

```
Document submitted
    ↓  WebSocket connects to /ws/documents/{id}
    ↓  Real-time status updates stream in:
       queued → processing → signing → storing → completed
    ↓  Auto-reconnect with exponential backoff (max 5 attempts)
    ↓  Disconnect on completion or screen exit
```

---

## 📱 Screens Implemented

### Authentication (FR-AUTH-01 to FR-AUTH-05) ✅

| Requirement | Implementation |
|---|---|
| FR-AUTH-01: Login Form | Email regex + password strength validation |
| FR-AUTH-02: JWT Storage | flutter_secure_storage → Keychain/Keystore |
| FR-AUTH-03: Biometric | local_auth → Fingerprint + Face ID |
| FR-AUTH-04: Token Refresh | Auto-refresh at T-3 min before 15-min TTL |
| FR-AUTH-05: Logout | Server revoke + local clear |

### Home Screen ✅

- Gradient `SliverAppBar` — Navy Blue to Indigo
- Stats Row — Total Docs, Delivered, Pending
- Quick Actions — Stamp Duty, Clause Validation, History, Rates
- Recent Documents — Empty state UI
- `NavigationBar` — 5 tabs

### Document Request Form (FR-DOC-01, FR-DOC-02, FR-DOC-03) ✅

- Document Type, Jurisdiction, Transaction Type dropdowns
- Transaction Value — Rupee prefix, numeric validation
- Property Address — multi-line input
- Supplementary Text — optional
- Local validation before API call
- Duplicate request prevention via `_isRequestInFlight` flag

---

## 🔌 API Integration

### Base Configuration

| Config | Value |
|---|---|
| Base URL | `https://api.actsvalid.com` |
| WebSocket | `wss://api.actsvalid.com/ws` |
| Auth Header | `Bearer {access_token}` |
| Token TTL | 15 min (access) / 7 days (refresh) |

### Endpoints

| Method | Endpoint | Purpose |
|---|---|---|
| POST | `/auth/login` | Email + password login |
| POST | `/auth/refresh` | Refresh access token |
| POST | `/auth/logout` | Revoke refresh token |
| GET | `/auth/me` | Get current user profile |
| POST | `/documents/request` | Submit document request |
| GET | `/documents` | Get all user documents |
| GET | `/documents/{id}` | Get single document |
| GET | `/rates` | Stamp duty rates by jurisdiction |
| WS | `/ws/documents/{id}` | Real-time processing status |

---

## 🎨 Design System

### Color Palette

| Color | Hex | Usage |
|---|---|---|
| Primary Navy | `#1A237E` | Headers, buttons, headings |
| Medium Blue | `#283593` | Gradient mid |
| Accent Blue | `#3949AB` | Gradient end |
| Background | `#F5F6FA` | App background |
| Success | `#2E7D32` | Delivered status |
| Warning | `#E65100` | Pending status |
| Teal | `#00897B` | Clause Validation |
| Purple | `#6A1B9A` | Rates action |

### Design Principles

- Cards with `BoxShadow` — subtle depth without heavy elevation
- `BorderRadius.circular(16)` — rounded corners everywhere
- Fixed height cards `72px` — responsive across all screen sizes
- `Row + Column` layout — avoids `GridView` aspect ratio issues on desktop
- `withValues(alpha: x)` — replaces deprecated `withOpacity()`
- `NavigationBar` (Material 3) — modern bottom nav

---

## 🚀 Setup & Installation

### Prerequisites

- Flutter SDK `3.10.1+`
- Dart SDK `^3.10.1`
- Android Studio or VS Code with Flutter extension
- Android device/emulator (API 21+) or iOS device/simulator (iOS 12+)

### Steps

```bash
# 1. Clone the repository
git clone https://github.com/jyotiarora-cse/ActsValid.git

# 2. Navigate to project
cd actsvalid_app

# 3. Install dependencies
flutter pub get

# 4. Run on connected device
flutter run

# 5. Run on Windows desktop
flutter run -d windows

# 6. Run on Chrome
flutter run -d chrome
```

---

## ⏳ Pending Features

| Feature | Requirement | Status |
|---|---|---|
| WebSocket Integration | FR-DOC-04 | 🔄 In Progress |
| Document Delivery & Viewing | Section 2.3 | ⏳ Pending |
| Document History | Section 2.4 | ⏳ Pending |
| Rates Lookup | Section 2.5 | ⏳ Pending |
| Settings & Profile | Section 2.6 | ⏳ Pending |
| Push Notifications | — | ⏳ Pending |
| Dynamic Jurisdictions | GET /rates | ⏳ Pending |

---

## 🛠️ Development Notes

| Issue | Solution |
|---|---|
| `withOpacity()` deprecated | Use `withValues(alpha: 0.x)` |
| GridView cards stretched on desktop | Use `Row + Column + height: 72` |
| Method not found in class | Ensure methods are inside class brackets |
| Import paths breaking | Features use `../../../core/` (3 levels up) |
| Emulator slow on AMD Ryzen | Use physical device or `flutter run -d windows` |
| Backend not live | `"Something went wrong"` on login is expected |
| `NuGet.exe` warning | Windows-only Flutter warning — safe to ignore |
| Git commit flag | Use `git commit -m "message"` not `git commit m -"message"` |

---

## 👩‍💻 Developer

**Jyoti** — Frontend Flutter Developer  
📅 March 2026  
🔒 Confidential — ActsValid Team

---

*ActsValid Flutter App — v1.0.0*
