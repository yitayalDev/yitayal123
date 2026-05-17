# University Appointment System - Overview

The University Appointment System is a full-stack web and mobile application designed to streamline scheduling, communication, and administrative tasks between students, service providers, and administrators within a university setting.

## Key Features

- **Role-Based Access Control:** Secure authentication for three distinct roles: `User` (Students), `Provider` (Staff/Departments), and `Admin` (System Administrators).
- **Appointment Booking:** Students can discover services and book appointments with available providers.
- **Service Management:** Providers and Admins can create and manage various services offered.
- **Real-Time Notifications:** Push notifications and in-app alerts (via Firebase) to keep users informed about appointment statuses, reminders, and messages.
- **In-App Messaging:** Direct communication channel between users and providers regarding their appointments.
- **Reviews & Ratings:** Students can leave feedback for services, ensuring quality control and accountability.
- **Cross-Platform Accessibility:** A responsive Flutter frontend that can be compiled for Web, Android, and iOS.

## Technology Stack

### Backend
- **Node.js & Express.js:** The core server architecture.
- **MongoDB & Mongoose:** NoSQL database for flexible data storage.
- **JSON Web Tokens (JWT):** For secure authentication and authorization.
- **Firebase Admin SDK:** For sending push notifications to mobile clients.
- **Multer:** For handling file uploads (e.g., profile pictures, documents).
- **Node-cron:** For automated background tasks like appointment reminders.

### Frontend
- **Flutter (Dart):** Single codebase for compiling cross-platform applications.
- **Provider:** State management solution.
- **Firebase Messaging:** For receiving push notifications on the client side.
- **Jitsi Meet:** Integrated for handling virtual/telemedicine video appointments.
- **QR & Barcode Scanning:** Integrated tools (`qr_flutter`, `mobile_scanner`) for quick check-ins or clearance validation.

## Project Structure

The repository is divided into two main components:

- `/backend`: Contains the Node.js API server, MongoDB models, business logic, and authentication middleware.
- `/frontend`: Contains the Flutter application codebase, UI screens, state management providers, and API integration services.

## What's Next?

This documentation suite is broken down into several parts. Please review the following documents for deeper technical details:

1. [Backend Database Schema](./database-schema.md)
2. [Backend API Reference](./api-reference.md)
3. [Frontend Architecture](./frontend-architecture.md)
4. [Deployment & Setup Guide](./deployment.md)
