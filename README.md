# Keep Notes - My Notes App

[![Flutter](https://img.shields.io/badge/Flutter-3.10+-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.10+-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev/)
[![Firebase](https://img.shields.io/badge/Firebase-Platform-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com/)
[![Android](https://img.shields.io/badge/Android-Supported-3DDC84?style=for-the-badge&logo=android&logoColor=white)](https://developer.android.com/)
[![Status](https://img.shields.io/badge/Status-Completed-success?style=for-the-badge)](#)

A modern Flutter-based note-taking application for creating, organizing, securing, and managing important notes with Firebase authentication, Firestore cloud storage, reminders, image attachments, voice notes, PDF export, theme customization, localization, and Android home widget support.

---

## Overview

**Keep Notes - My Notes App** is a completed Flutter note-taking application designed for students, professionals, and everyday users who need a simple, secure, and organized way to save important information.

The app allows users to create, edit, organize, protect, and manage personal notes. It includes authentication, cloud-based note storage, reminder notifications, media attachments, PDF export, theme customization, PIN protection, and multilingual support.

The project is built using **Flutter**, **Dart**, and **Firebase**, making it suitable for modern cross-platform application development.

---

## Key Features

- Create, edit, duplicate, archive, restore, and delete notes
- Firebase email/password authentication
- User-specific Firestore note storage
- Cloud-based note synchronization
- PIN lock for additional privacy
- Reminder notifications for important notes
- Image attachment support
- Voice note recording and playback
- PDF export and sharing
- Android home-screen widget support
- Light, dark, system, and AMOLED-style theme support
- Multiple theme color palettes
- English and Bangla language support
- Local settings persistence using SharedPreferences
- Notes search, filter, and sort functionality
- Trash system to prevent accidental permanent deletion
- Backup and restore support
- Notes statistics and organization tools

---

## Application Modules

| Module | Description |
|---|---|
| Authentication | Login, signup, password reset, and user account access |
| Notes | Create, edit, duplicate, archive, restore, and delete notes |
| Labels | Organize notes using labels and categories |
| Search & Filter | Search notes, filter by status, and sort by different criteria |
| Reminders | Schedule reminder notifications for selected notes |
| Attachments | Add images and voice recordings to notes |
| PDF Export | Export notes as PDF files and share them |
| PIN Lock | Protect the app with a 4-6 digit PIN |
| Themes | Change theme mode and app color palette |
| Localization | Switch between English and Bangla |
| Home Widget | Access note-related information from Android home screen |

---

## System Architecture

```text
Flutter Application
        │
        ├── Authentication Layer
        │   └── Firebase Authentication
        │
        ├── Notes Management Layer
        │   ├── Create notes
        │   ├── Edit notes
        │   ├── Delete notes
        │   ├── Archive notes
        │   ├── Restore notes
        │   └── Organize notes
        │
        ├── Cloud Data Layer
        │   └── Cloud Firestore
        │
        ├── Local Storage Layer
        │   └── SharedPreferences
        │
        ├── Device Features
        │   ├── Local notifications
        │   ├── Image picker
        │   ├── Voice recording
        │   ├── Audio playback
        │   ├── PDF generation
        │   └── Home widget
        │
        └── User Interface
            ├── Notes screen
            ├── Authentication screens
            ├── Settings screen
            ├── Theme controls
            └── Language controls
```

---

## Technology Stack

### Core Framework

| Technology | Purpose |
|---|---|
| Flutter | Cross-platform app development |
| Dart | Main programming language |
| Material Design | UI components and design system |

### Backend and Cloud

| Technology | Purpose |
|---|---|
| Firebase Authentication | User login, signup, and password reset |
| Cloud Firestore | Cloud database for user notes |
| Firebase Analytics | App event tracking |
| Firebase Remote Config | Remote configuration and feature control |

### Local Storage and Device Features

| Package / Feature | Purpose |
|---|---|
| SharedPreferences | Save local settings and preferences |
| Flutter Local Notifications | Reminder notifications |
| Timezone | Timezone-aware notification scheduling |
| Home Widget | Android home-screen widget support |
| Image Picker | Attach images to notes |
| Record | Record voice notes |
| Audioplayers | Play recorded audio |
| Path Provider | Access local file directories |
| PDF | Generate PDF documents |
| Share Plus | Share exported notes and files |

---

## Features in Detail

### Authentication

The app includes a secure Firebase authentication system.

Features:

- Create a new account
- Sign in using email and password
- Reset forgotten password
- Change password
- Protect notes under each authenticated user
- Store user-specific data securely in Firestore

---

### Notes Management

Users can manage notes efficiently with a complete note lifecycle.

Features:

- Create new notes
- Edit note title and content
- Duplicate existing notes
- Delete notes
- Restore deleted notes
- Permanently delete notes
- Archive and unarchive notes
- View notes in organized layouts
- Store creation and update timestamps

---

### Pin and Favorite Notes

Important notes can be highlighted for quick access.

Features:

- Pin important notes
- Unpin notes
- Mark notes as favorite
- Remove notes from favorites
- Keep high-priority notes visible and easy to find

---

### Labels and Organization

Labels help users keep notes structured.

Features:

- Add labels to notes
- Use multiple labels
- Filter notes by labels
- Organize study, work, personal, and idea notes
- Keep note collections clean and manageable

---

### Search, Filter, and Sort

The app includes search and organization tools for faster navigation.

Features:

- Search notes quickly
- Search deleted notes
- Filter pinned notes
- Filter favorite notes
- Filter notes by labels
- Filter notes due today
- Filter notes without reminders
- Sort by newest first
- Sort by oldest first
- Sort by title
- Sort by pinned first

---

### Archive System

The archive system keeps older notes separate from active notes.

Features:

- Archive notes
- View archived notes
- Unarchive notes
- Keep the main notes screen clean
- Preserve older notes without deleting them

---

### Trash System

Deleted notes are moved to trash before permanent deletion.

Features:

- Move notes to trash
- View deleted notes
- Restore notes from trash
- Delete notes permanently
- Undo move-to-trash action
- Confirm before permanent deletion

---

### Reminders and Notifications

Users can set reminders for important notes.

Features:

- Set reminders for notes
- Clear reminders
- Receive local notifications
- Support for timezone-aware reminders
- Android exact alarm support
- Useful for tasks, deadlines, study plans, and events

---

### Image Attachments

Notes can include visual information.

Features:

- Attach images to notes
- Store image references
- View image attachments inside notes
- Useful for screenshots, documents, receipts, and study material

---

### Voice Notes

The app supports voice-based note-taking.

Features:

- Record voice notes
- Stop voice recording
- Attach audio recordings to notes
- Play recorded audio
- Pause audio playback
- Handle microphone permission

---

### PDF Export

Notes can be exported as PDF documents.

Features:

- Export selected notes as PDF
- Save generated PDF files
- Share PDF files
- Useful for assignments, reports, study notes, documentation, and backups

---

### Backup and Restore

The app supports note backup and restore workflows.

Features:

- Create notes backup
- Restore notes from backup
- Auto-backup option
- User-specific backup filename
- Local JSON backup support

---

### Android Home Widget

The app includes Android home-screen widget support.

Features:

- Home-screen widget integration
- Quick access to notes
- Small, medium, and large widget support
- Launch app from widget
- Convenient access without opening the app manually

---

### PIN Lock

The app includes PIN-based privacy protection.

Features:

- Set a 4-6 digit PIN
- Change existing PIN
- Remove PIN
- Lock the app manually
- Unlock the app using PIN
- Add extra protection for personal notes

---

### Theme and Customization

Users can personalize the app appearance.

Theme modes:

- Light theme
- Dark theme
- System theme
- AMOLED-style dark theme

Available color palettes:

- Emerald
- Ocean
- Sunset
- Rose
- Amber
- Violet
- Teal
- Slate
- Coral
- Indigo

---

### Language Support

The app supports multiple languages.

Available languages:

- English
- Bangla

Features:

- Persistent language selection
- Localized labels and messages
- User-friendly multilingual interface

---

### Notes Statistics

The app can show useful note statistics.

Statistics include:

- Total notes count
- Active notes count
- Archived notes count
- Trash notes count
- Pinned notes count
- Notes with reminders count

---

## Firebase Features

### Firebase Authentication

Used for:

- User registration
- User login
- Password reset
- Password change
- User-specific access control

### Cloud Firestore

Used for:

- Storing user notes
- Syncing notes under user accounts
- Maintaining user-specific note collections
- Supporting cloud-based data access

Recommended Firestore structure:

```text
users
└── {userId}
    ├── profile information
    └── notes
        └── {noteId}
            ├── title
            ├── content
            ├── labels
            ├── isPinned
            ├── isFavorite
            ├── isArchived
            ├── isDeleted
            ├── reminderTime
            ├── imagePath
            ├── audioPath
            ├── createdAt
            └── updatedAt
```

### Firebase Analytics

Used for:

- Tracking app usage
- Tracking login events
- Tracking signup events
- Tracking password change events
- Understanding feature usage

### Firebase Remote Config

Used for:

- Remote app title configuration
- Home banner text
- Feature toggles
- Voice note FAB enable/disable control
- PDF export enable/disable control

---

## Key Packages

The project uses the following major packages:

```yaml
dependencies:
  flutter:
    sdk: flutter

  firebase_core: latest
  firebase_auth: latest
  cloud_firestore: latest
  firebase_analytics: latest
  firebase_remote_config: latest

  shared_preferences: latest
  flutter_local_notifications: latest
  timezone: latest
  flutter_timezone: latest

  home_widget: latest
  path_provider: latest
  image_picker: latest
  record: latest
  audioplayers: latest
  pdf: latest
  share_plus: latest
```

> Check `pubspec.yaml` for the exact package versions used in the project.

---

## Prerequisites

Before running this project, make sure you have:

- Flutter SDK installed
- Dart SDK installed
- Firebase account
- Android Studio or Visual Studio Code
- Android emulator or physical Android device
- Git installed

Check the Flutter environment:

```bash
flutter doctor
```

---

## Installation and Setup

### 1. Clone the Repository

```bash
git clone https://github.com/mehedi77k/Keep_notes.git
cd Keep_notes
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Configure Firebase

This app uses Firebase Authentication, Cloud Firestore, Firebase Analytics, and Firebase Remote Config.

#### Option A: Use Existing Firebase Configuration

If the project already includes Firebase configuration files, make sure they are correctly placed.

For Android:

```text
android/app/google-services.json
```

For generated FlutterFire configuration:

```text
lib/firebase_options.dart
```

#### Option B: Configure Firebase Manually

1. Open Firebase Console.
2. Create a new Firebase project.
3. Add an Android app to the Firebase project.
4. Download `google-services.json`.
5. Place `google-services.json` inside:

```text
android/app/
```

6. Enable Firebase Authentication.
7. Enable Email/Password sign-in.
8. Enable Cloud Firestore.
9. Enable Firebase Analytics if required.
10. Enable Firebase Remote Config if required.
11. Generate or update `firebase_options.dart` using FlutterFire CLI.

Example FlutterFire command:

```bash
flutterfire configure
```

### 4. Run the App

For Android:

```bash
flutter run
```

For Web:

```bash
flutter run -d chrome
```

For Windows:

```bash
flutter run -d windows
```

For a specific device:

```bash
flutter devices
flutter run -d <device-id>
```

---

## Project Structure

```text
Keep_notes/
│
├── android/                       # Android platform configuration
├── ios/                           # iOS platform configuration
├── linux/                         # Linux platform configuration
├── macos/                         # macOS platform configuration
├── web/                           # Web platform configuration
├── windows/                       # Windows platform configuration
├── test/                          # Flutter test files
│
├── assets/
│   └── app_icon/                  # App icon assets
│
├── lib/
│   ├── main.dart                  # Main application, authentication, themes, localization, and app logic
│   ├── home_page.dart             # Notes home screen and notes CRUD logic
│   ├── signup_page.dart           # User signup screen
│   └── firebase_options.dart      # Firebase platform configuration
│
├── firebase.json                  # Firebase configuration
├── pubspec.yaml                   # Project metadata and dependencies
├── pubspec.lock                   # Locked dependency versions
├── analysis_options.yaml          # Flutter linting configuration
└── README.md                      # Project documentation
```

---

## Important Files

| File | Purpose |
|---|---|
| `lib/main.dart` | App initialization, Firebase setup, authentication flow, theme settings, localization, PIN lock, and login logic |
| `lib/home_page.dart` | Notes home screen, Firestore CRUD operations, note list, add/edit dialog, delete logic, and logout |
| `lib/signup_page.dart` | User registration screen and Firebase Auth signup logic |
| `lib/firebase_options.dart` | Firebase configuration generated by FlutterFire CLI |
| `pubspec.yaml` | Project dependencies, assets, metadata, and app version |
| `firebase.json` | Firebase project configuration |
| `android/app/google-services.json` | Android Firebase configuration file |

---

## Required Permissions

The app may require the following Android permissions depending on enabled features:

```xml
android.permission.POST_NOTIFICATIONS
android.permission.SCHEDULE_EXACT_ALARM
android.permission.RECORD_AUDIO
```

Permission usage:

| Permission | Purpose |
|---|---|
| `POST_NOTIFICATIONS` | Shows note reminder notifications |
| `SCHEDULE_EXACT_ALARM` | Schedules exact reminder alarms on supported Android versions |
| `RECORD_AUDIO` | Records voice notes |

---

## Security and Privacy

This app includes privacy-focused features to protect user notes.

Security features:

- Firebase Authentication for secure account access
- User-specific note storage
- PIN lock for extra local privacy
- Password reset support
- Password change support
- Trash system to prevent accidental permanent deletion
- Local settings saved using SharedPreferences
- Firestore-based note separation by user ID

Recommended privacy practices:

- Keep Firebase rules properly configured
- Restrict note access to authenticated users only
- Do not expose Firebase credentials outside intended app configuration
- Inform users about notification, audio, and storage permissions
- Store sensitive note data responsibly

Example Firestore security rule concept:

```text
Only authenticated users should read and write their own notes.
```

---

## UI and Design System

The app follows a clean, modern note-taking interface.

Design characteristics:

- Rounded note cards
- Clean input fields
- Material 3 buttons
- Responsive grid and list views
- Smooth navigation
- Minimal and readable design
- Theme-based color system
- Light and dark mode support
- Custom color palette support

---

## How the App Works

1. The user opens the app.
2. Firebase initializes.
3. The app checks authentication status.
4. If the user is not logged in, the login screen is shown.
5. New users can create an account using email and password.
6. After login, the user is taken to the notes screen.
7. Notes are stored under the authenticated user account.
8. The user can create, edit, organize, archive, delete, or restore notes.
9. Optional features such as reminders, image attachments, voice notes, PDF export, and PIN lock can be used.
10. Settings such as theme, language, and PIN preferences are stored locally.

---

## Build Commands

### Android APK

```bash
flutter build apk --release
```

### Android App Bundle

```bash
flutter build appbundle --release
```

### iOS

```bash
flutter build ios --release
```

### Web

```bash
flutter build web --release
```

### Windows

```bash
flutter build windows --release
```

### Linux

```bash
flutter build linux --release
```

### macOS

```bash
flutter build macos --release
```

### Clean Build

```bash
flutter clean
flutter pub get
flutter run
```

---

## Testing Checklist

Use this checklist before final release or presentation:

- [ ] App runs successfully
- [ ] Firebase initializes correctly
- [ ] User signup works
- [ ] User login works
- [ ] Password reset email works
- [ ] Change password works
- [ ] Create note works
- [ ] Edit note works
- [ ] Duplicate note works
- [ ] Delete note works
- [ ] Restore note works
- [ ] Permanent delete works
- [ ] Archive note works
- [ ] Unarchive note works
- [ ] Pin and unpin note works
- [ ] Favorite and unfavorite note works
- [ ] Search notes works
- [ ] Filter notes works
- [ ] Sort notes works
- [ ] Label system works
- [ ] Reminder notification works
- [ ] Image attachment works
- [ ] Voice recording works
- [ ] Audio playback works
- [ ] PDF export works
- [ ] PDF sharing works
- [ ] Backup creation works
- [ ] Backup restore works
- [ ] PIN lock works
- [ ] Theme change works
- [ ] Color palette change works
- [ ] Language change works
- [ ] Android home widget works
- [ ] App works after restart
- [ ] Firestore security rules are configured
- [ ] Android permissions are requested correctly

---

## Troubleshooting

### App Does Not Run

Run:

```bash
flutter doctor -v
```

Then fix any Flutter environment issues shown in the terminal.

After that, run:

```bash
flutter clean
flutter pub get
flutter run
```

---

### Firebase Initialization Fails

Check that:

- Firebase project is created
- `google-services.json` exists in `android/app/`
- `firebase_options.dart` exists in `lib/`
- Firebase Authentication is enabled
- Cloud Firestore is enabled
- Package names match between Firebase and Android project

---

### Login or Signup Does Not Work

Check that:

- Email/Password sign-in is enabled in Firebase Authentication
- Internet connection is available
- Firebase configuration files are correct
- Firestore rules allow authenticated users to access their own data

---

### Notes Are Not Saving

Check that:

- User is logged in
- Cloud Firestore is enabled
- Firestore rules are configured correctly
- Internet connection is working
- Firestore collection path is correct

---

### Reminder Notification Does Not Work

Check that:

- Notification permission is allowed
- Exact alarm permission is available if required
- Device notification settings allow this app
- Reminder time is set correctly
- Timezone configuration is initialized

---

### Voice Recording Does Not Work

Check that:

- Microphone permission is allowed
- Device microphone is available
- App has `RECORD_AUDIO` permission
- Audio recording package is configured correctly

---

### PDF Export Does Not Work

Check that:

- Storage or file access path is available
- Required dependencies are installed
- App has permission to write generated files if needed
- PDF generation completes before sharing

---

### Dependency Problems

Run:

```bash
flutter pub get
flutter pub upgrade
```

If the issue continues:

```bash
flutter clean
flutter pub get
```

---

## Known Limitations

- Firebase setup is required for authentication and cloud sync.
- Internet connection is required for cloud-based note synchronization.
- Voice recording requires microphone permission.
- Reminder notifications require notification permission.
- Exact alarm permission may be required on some Android versions.
- Android home widget features are platform-specific and may not work on all platforms.
- Web and desktop platforms may not support every native Android feature.
- If Firebase configuration files are missing, the app may fail to initialize.
- PDF export, audio recording, and widget behavior may vary depending on platform support.

---

## Future Improvements

Although the core project is complete, the following improvements may be added in future versions:

- Rich text editor with formatting tools
- Cloud image and audio upload
- Note sharing between users
- Real-time collaboration
- AI note summary
- Smart search
- Calendar reminder view
- Individual note lock
- Biometric unlock
- More home widget designs
- Export all notes as PDF
- Export notes as CSV or JSON
- Import notes from external files
- Web dashboard
- Better analytics dashboard
- Offline-first synchronization
- Markdown support
- Tag color customization

---

## Key Achievements

- Completed modern note-taking application
- Firebase Authentication integration
- Firestore cloud note storage
- User-specific note management
- PIN lock privacy system
- Reminder notification support
- Image attachment support
- Voice note support
- PDF export and sharing
- Android home widget support
- English and Bangla language support
- Multiple theme modes and color palettes
- Cross-platform Flutter project structure

---

## Contributing

Contributions are welcome.

To contribute:

1. Fork the repository

2. Create a new branch

```bash
git checkout -b feature/new-feature
```

3. Commit your changes

```bash
git commit -m "Add new feature"
```

4. Push to your branch

```bash
git push origin feature/new-feature
```

5. Open a Pull Request

---

## License

This project is open for educational and learning purposes.

If you want to use a formal open-source license, add a `LICENSE` file to the repository.

---

## Developer

**Mehedi Hasan**

- GitHub: [@mehedi77k](https://github.com/mehedi77k)
- Repository: [Keep_notes](https://github.com/mehedi77k/Keep_notes)
- Project: Keep Notes - My Notes App
- Built with Flutter, Dart, and Firebase

---

## Support

For issues, suggestions, or improvements, open an issue in the GitHub repository:

```text
https://github.com/mehedi77k/Keep_notes/issues
```

---

## Project Status

```text
Status: Completed
Version: 1.0.0+1
Project Type: Note-Taking Application
Framework: Flutter
Main Language: Dart
Backend: Firebase
Database: Cloud Firestore
Authentication: Firebase Authentication
Primary Platform: Android
Additional Platforms: iOS, Web, Windows, Linux, macOS
```

---

<div align="center">

### Star this repository if you find it useful.

Built with Flutter, Dart, and Firebase.

</div>
