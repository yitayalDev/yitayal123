# Project Documentation: Campus Appointment

---

## 🏛️ Institution Details
* **Institution:** College of Informatics
* **Department:** Department of Information Technology
* **Project Type:** Mobile Application Development Project
* **App Name:** Campus Appointment (Cross-Platform Mobile & Web)
* **Date:** May 2026

---

## 📋 Executive Summary
**Campus Appointment** is a state-of-the-art, secure, and cross-platform scheduling and digital communication system built specifically for university environments. The system streamlines all academic and administrative scheduling—connecting students directly with departmental officers, advisors, registrars, and health clinicians.

### Core Problems Solved
1. **Queue Redundancies:** Eliminates physical queues outside offices by allowing digital slot bookings.
2. **Virtual / Telehealth Meetings:** Provides instant, encrypted video calls inside the app without external account dependencies.
3. **Verification Integrity:** Integrates secure QR Code scanning to verify physical attendance.
4. **Paperless Workflows:** Enables students to upload attachments to their bookings natively on both web and mobile platforms.
5. **State Resilience:** Fully handles browser refreshes and connection state drops through persistent local state management.

---

## ⚙️ Technical Architecture

The project implements a modern, decoupled client-server architecture:

```mermaid
graph TD
    subgraph Client Layer (Flutter Cross-Platform)
        Mobile[Android/iOS Native App]
        Web[Flutter SPA Web App]
    end

    subgraph Middleware / Services
        Provider[Provider State Management]
        Local[Shared Preferences Cache]
    end

    subgraph Backend Layer (Express Node.js)
        Server[Express App Server]
        Socket[Socket.IO Chat Server]
        Push[Firebase Cloud Messaging]
    end

    subgraph Database Layer
        Mongo[(MongoDB Atlas Database)]
    end

    Mobile --> Server
    Web --> Server
    Mobile --> Socket
    Web --> Socket
    Server --> Mongo
    Server --> Push
```

### 1. Frontend: Flutter & Dart
* **State Management:** `provider` (MultiProvider architectural pattern) for granular reactivity.
* **Persistent Storage:** `shared_preferences` for session persistence and browser state recovery.
* **Scan Engine:** `mobile_scanner` for ultra-fast QR Code camera capturing.
* **Video SDK:** `jitsi_meet_flutter_sdk` natively for mobile, conditionally falling back to browser window interops on web.
* **Universal File Handlers:** `file_picker` dynamically managing native directories on mobile and memory arrays on web.

### 2. Backend: Node.js, Express & MongoDB
* **Database engine:** MongoDB Atlas (Cloud hosted database cluster).
* **Real-time Sync:** Socket.IO for immediate chat message delivery.
* **Push Notifications:** Firebase Admin SDK pushing background events to physical phones.
* **Auth Security:** JSON Web Token (JWT) using secure custom authorization header validations.

---

## 💎 Features & Functional Modules

### A. Student Module
* **Service Discovery:** Explore all university departments, registrar windows, clinics, and IT centers. Filter by category or search in real time.
* **Appointment Booking:** View specific provider schedules, select available slots, enter reasons, and attach supporting files (PDF, images, etc.).
* **QR Check-in Ticket:** Instantly generates a unique high-resolution QR Code ticket for physical scanning upon arrival.
* **Live Chat & Help Desk:** Open a secure chat channel with advisors to clarify requirements before/after booking approvals.

### B. Provider / Faculty Module
* **Manage Screen:** Review incoming requests with real-time "Approve", "Reject" (with reason dialogues), and "Cancel" triggers.
* **Real-time Attendance QR Scanner:** Activates the device's native camera or web camera to scan student tickets, instantly updating statuses in the database to `attended`.
* **Dynamic Calendar & Schedules:** View upcoming bookings in structured layouts.
* **Analytics Center:** Interactive statistics showing pending, approved, and attended booking volume.
* **Absence Manager:** Quick toggles to switch availability, immediately updating service cards for students.

### C. Admin & Service Management Module
* **Service Configurator:** Administrative control panel to create/delete departments (e.g. Registrar, Dean Office, Academic Advisors, Health Clinic) and set service properties.
* **System Audit & Appointment Logs:** Real-time visibility into booking metrics, active sessions, and database collection states.
* **Role Management:** Administrative panel to elevate user levels, transition student accounts into provider roles, or grant administrative access.

---

## 🛠️ Key Technical Solved Challenges & Modern Implementation Highlights

### 1. Universal Web/Mobile Conditional Compilation Guard
**Problem:** Using native web libraries (like `dart:js` or `dart:html`) crashes native mobile builds during Flutter's compilation phase, while mobile SDKs crash on web.
**Solution:** Implemented a **Conditional Export Pattern** utilizing stubs:
```dart
// launcher_helper.dart
export 'launcher_stub.dart' if (dart.library.js) 'launcher_web.dart';
```
This allows the app to open native external browser screens on the web while calling the compiled Jitsi Conference controller seamlessly on Android/iOS!

### 2. Web State Recovery across Refreshes
**Problem:** Hitting the F5/Refresh key in browsers resets the entire app state, kicking the user out of sub-screens like "My Appointments" back to the home page.
**Solution:** Integrated an automated state preservation pipeline. When any major page initializes:
* The active view state is saved persistently:
  ```dart
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('last_route', 'my_appointments');
  ```
* On boot, the main app reads the preference, redirects the user immediately, and wipes the flag to keep routing organic and clean.

### 3. File Picker MIME Type Universal Fallback
**Problem:** Newer browsers and specific Android file managers crash or do nothing when restricted to custom file extensions.
**Solution:** Converted picker options to `FileType.any` with custom try-catch fallbacks to catch internal platform errors and print them clearly inside modern snackbars.

---

## 🚀 Compilation & Deployment Guidelines

### 1. Generating Android Native Release APK
To compile the highly optimized, tree-shaken Android APK, navigate to the `frontend/` directory and run:
```bash
flutter clean
flutter pub get
flutter build apk --release
```
**Output Path:** `build/app/outputs/flutter-apk/app-release.apk`

### 2. Building & Serving Web Version
To generate the web assets and serve them statically via the Express server backend:
```bash
# 1. Compile web assets
flutter build web

# 2. Copy compiled assets to express public directory (Windows PowerShell example)
Copy-Item -Path ".\build\web\*" -Destination "..\backend\public" -Recurse -Force

# 3. Deploy to production/Render
git add .
git commit -m "Deploy fresh compiled static assets"
git push origin main
```

---

*Project developed and certified under the **College of Informatics, Department of Information Technology** academic standards.*
