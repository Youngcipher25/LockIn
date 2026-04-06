# LockIn - Private Organizer & Productivity Dashboard

![LockIn Logo](https://img.shields.io/badge/LockIn-Private_Productivity-blue?style=for-the-badge&logo=swift)

**LockIn** is a secure, privacy-first productivity application built with SwiftUI. It combines task management, calendar integration, and usage tracking with robust security features to ensure your personal data stays yours.

## Key Features

- **Robust Security**: 
  - Mandatory biometric/PIN authentication via `AppLockView`.
  - Secure OTP-based authentication flow.
- **Smart Calendar**: 
  - Integrated `CalendarView` for managing schedules alongside tasks.
- **Privacy Dashboard**: 
  - Real-time tracking of app usage and privacy metrics.
- **Task Management**: 
  - Efficient task creation and organization via `NewTaskView`.
- **Modern UI/UX**: 
  - Native SwiftUI implementation with support for Dark Mode.
  - Custom brand-themed components for a premium feel.
- **Data Control**: 
  - Local storage management and secure data export options.

## Getting Started

### Prerequisites

- **macOS** with **Xcode 15.0+** installed.
- **iOS 17.0+** target device or simulator.

### Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/Youngcipher25/LockIn.git
   cd LockIn
   ```

2. **Open the project**:
   ```bash
   open LockIn.xcodeproj
   ```

3. **Build and Run**:
   - Select your target device (iPhone) in Xcode.
   - Press `Cmd + R` to build and run.

## Technology Stack

- **Framework**: SwiftUI
- **Language**: Swift 5.9+
- **Data Persistence**: `AppStorage` & custom `TaskStore` (JSON-backed or similar)
- **Security**: LocalAuthentication (Biometrics)

## Project Structure

```text
LockIn/
├── LockIn/
│   ├── App/
│   │   ├── LockInApp.swift          # App Entry Point
│   │   └── PrivateOrganizerApp.swift # Core App Logic & Auth Views
│   ├── Views/
│   │   ├── HomeView.swift           # Main Dashboard
│   │   ├── CalendarView.swift       # Schedule Management
│   │   ├── PrivacyDashboardView.swift # Security Metrics
│   │   └── AppLockView.swift        # Authentication UI
│   ├── Models/
│   │   └── Models.swift             # Task & User Data Models
│   └── Components/
│       └── UIComponents.swift       # Reusable Styled Components
└── LockIn.xcodeproj                 # Xcode Project File
```

## License

This project is licensed under the MIT License - see the LICENSE file for details.

---

Designed with passion for Privacy and Productivity.
