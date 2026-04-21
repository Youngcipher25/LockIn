# LockIn - Private Organizer & Productivity Dashboard

**LockIn** is a secure, privacy-first productivity application built with SwiftUI. It combines task management, calendar integration, and usage tracking with professional-grade security features to ensure your personal data remains confidential and accessible across your devices.

## Key Features

- **Biometric Privacy Protection**
  - Native integration with Face ID and Touch ID for secure content gating.
  - Automatic blurring of sensitive tasks and metadata when the app is locked.
  - Configurable auto-lock timers to maintain security during inactive periods.

- **Cloud Synchronization (Supabase)**
  - Permanent Account Sync: Securely backup and sync your tasks across multiple devices using a personal account.
  - Quick Transfer: Move your data between devices without an account using a temporary 6-digit transfer code.
  - Cross-Device Continuity: Seamlessly transition your productivity workflow between iPhone and iPad.

- **Smart Data Management**
  - Offline-First: All data is stored locally by default to ensure maximum privacy and speed.
  - Backup & Restore: Export your entire database to a JSON file and restore it on any device.
  - Cloud Sovereignty: Full control to delete all cloud-stored data while preserving your local records.

- **Modern UI/UX**
  - Native SwiftUI implementation optimized for iOS 17.
  - Integrated CalendarView for managing schedules alongside tasks.
  - Privacy Dashboard for real-time tracking of security metrics and app usage.

## Getting Started

### Prerequisites

- macOS with Xcode 15.0 or newer.
- iOS 17.0 or newer for target devices or simulators.
- A Supabase project (for Cloud Sync features).

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/Youngcipher25/LockIn.git
   cd LockIn
   ```

2. Open the project:
   ```bash
   open LockIn.xcodeproj
   ```

3. Configure Supabase:
   - Update `SupabaseSyncManager.swift` with your Supabase URL and Anon Key.
   - Run the provided SQL setup script in your Supabase SQL Editor to initialize the database tables.

4. Build and Run:
   - Select your target device in Xcode.
   - Press Cmd + R to build and run.

## Technology Stack

- **Framework**: SwiftUI
- **Database**: Local JSON storage with Supabase Cloud Integration.
- **Security**: LocalAuthentication (Face ID/Touch ID).
- **Networking**: Supabase Swift SDK.

## Project Structure

```text
LockIn/
├── LockIn/
│   ├── PrivateOrganizerApp.swift  # Main Entry Point with Environment Objects
│   ├── SupabaseSyncManager.swift # Cloud Sync & Auth Logic
│   ├── BiometricAuthManager.swift # LocalAuthentication & Gating Logic
│   ├── Views/
│   │   ├── HomeView.swift         # Dynamic Dashboard with Blur Gating
│   │   ├── SyncView.swift         # Cloud Sync & Transfer UI
│   │   ├── ExportDataView.swift   # JSON Backup & Restore Management
│   │   ├── PrivacyDashboardView.swift # Security & Usage Stats
│   │   └── CalendarView.swift     # Integrated Schedule Management
│   ├── Models/
│   │   └── Models.swift           # Task & Core Data Models
│   └── Components/
│       └── UIComponents.swift     # Premium Design System
```

## License

This project is licensed under the MIT License.

---

Built for individuals who value privacy as much as productivity.
