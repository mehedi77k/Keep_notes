# 📝 Keep Notes - My Notes App

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)
![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)
![Status](https://img.shields.io/badge/Status-Active%20Development-brightgreen?style=for-the-badge)

A modern Flutter-based note taking application for creating, organizing, securing, and managing important notes with Firebase authentication, cloud sync, reminders, voice notes, image attachments, PDF export, and home widget support.

---

## 📱 Overview

**Keep Notes - My Notes App** is a smart and user-friendly note taking application built using Flutter and Dart.

This app helps users save important notes, organize them with labels, attach images, record voice notes, set reminders, archive notes, move notes to trash, export notes as PDF, and protect the app using a PIN lock.

The main goal of this project is to provide a simple, clean, secure, and feature-rich notes app that can be used for daily personal tasks, study notes, ideas, reminders, and important information.

---

## ✨ Key Highlights

- 📝 Create and manage personal notes
- 🔐 Firebase email/password authentication
- 🔑 Password reset support
- 🔒 PIN lock for app privacy
- ☁️ Cloud note sync using Firebase Firestore
- 💾 Local note caching using SharedPreferences
- 🖼️ Image attachment support
- 🎙️ Voice note recording support
- 🔊 Audio playback support
- ⏰ Reminder notification support
- 🏷️ Label-based note organization
- 📌 Pin important notes
- ⭐ Mark notes as favorite
- 📦 Archive notes
- 🗑️ Trash and restore system
- 📄 Export notes as PDF
- 📤 Share exported notes
- 🏠 Android home widget support
- 🌙 Light, dark, and system theme support
- 🎨 Multiple color palette options
- 🌐 English and Bangla language support
- 📊 Notes statistics
- 🔍 Search, filter, and sort notes
- 🔁 Backup and restore support

---

## 🚀 Features

### 🔐 Authentication

The app includes Firebase-based authentication for user account management.

- User sign up
- User sign in
- Firebase email/password login
- Forgot password option
- Password reset email
- Change password support
- User-specific notes collection

---

### 📝 Notes Management

Users can create and manage notes easily.

- Create new notes
- Edit existing notes
- Save note title and body
- Duplicate notes
- Delete notes
- Restore deleted notes
- Permanently delete notes
- Organize notes in grid or list view

---

### 📌 Pin & Favorite Notes

Important notes can be highlighted for quick access.

- Pin important notes
- Unpin notes
- Mark notes as favorite
- Remove favorite status
- Keep important notes visible at the top

---

### 🏷️ Labels

The app supports label-based organization.

- Add labels to notes
- Use multiple labels
- Filter notes by labels
- Example labels:
  - work
  - ideas
  - personal
  - study
  - reminder

---

### 🔍 Search, Filter & Sort

The app makes it easy to find notes quickly.

- Search notes
- Search trash notes
- Filter pinned notes
- Filter notes with labels
- Filter notes due today
- Filter notes without reminder
- Sort by newest first
- Sort by oldest first
- Sort by title
- Sort by pinned first

---

### 📦 Archive System

Users can archive notes they do not want to keep in the main notes list.

- Archive notes
- View archived notes
- Unarchive notes
- Keep main notes list clean

---

### 🗑️ Trash System

Deleted notes are moved to trash instead of being removed immediately.

- Move notes to trash
- View trash notes
- Restore notes from trash
- Delete notes forever
- Undo move to trash
- Confirm before trash option

---

### ⏰ Reminders & Notifications

The app supports note reminders using local notifications.

- Set reminder for notes
- Clear reminder
- Reminder notification support
- Due today filter
- Timezone support
- Exact alarm permission support on Android

---

### 🖼️ Image Attachments

Users can attach images to notes.

- Add image to notes
- Store image path
- View image attachments
- Useful for screenshots, documents, and visual notes

---

### 🎙️ Voice Notes

The app supports voice note recording.

- Record voice notes
- Stop voice recording
- Attach audio to notes
- Play audio
- Pause audio
- Microphone permission handling

---

### 📄 PDF Export

Notes can be exported as PDF files.

- Export note as PDF
- Save generated PDF
- Share exported PDF
- Useful for reports, study notes, and documentation

---

### 🔁 Backup & Restore

The app supports backup and restore features.

- Create notes backup
- Restore notes from backup
- Auto backup on save option
- User-specific backup filename
- Local JSON backup support

---

### 🏠 Android Home Widget

The app includes Android home widget support.

- Small notes widget
- Medium notes widget
- Large notes widget
- Home widget launch support
- Quick access from home screen

---

### 🔒 PIN Lock

Users can protect the app using a PIN.

- Set 4-6 digit PIN
- Change PIN
- Remove PIN
- Lock now option
- Unlock notes with PIN
- Extra privacy for personal notes

---

### 🎨 Theme & Customization

The app includes a modern Material 3 UI with theme customization.

- Light theme
- Dark theme
- System theme
- AMOLED-style dark theme
- Multiple color palettes:
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

### 🌐 Language Support

The app supports multiple languages.

- English language
- Bangla language
- Persistent language selection
- Localized app labels and messages

---

### 📊 Notes Statistics

Users can view useful note statistics.

- Total notes
- Active notes
- Archived notes
- Trash notes
- Pinned notes
- Notes with reminders

---

## 🛠️ Technology Stack

### Frontend

- **Flutter** - Cross-platform UI framework
- **Dart** - Programming language
- **Material 3** - Modern UI design system
- **Flutter Localizations** - Multi-language support

### Backend & Cloud

- **Firebase Core** - Firebase initialization
- **Firebase Authentication** - User login and registration
- **Cloud Firestore** - Cloud note storage and sync
- **Firebase Analytics** - Analytics event tracking
- **Firebase Remote Config** - Remote app configuration

### Local Storage & Device Features

- **SharedPreferences** - Local app settings and note cache
- **Flutter Local Notifications** - Reminder notifications
- **Timezone** - Notification timezone management
- **Home Widget** - Android home screen widget
- **Image Picker** - Image attachment support
- **Record** - Voice recording
- **Audioplayers** - Audio playback
- **Path Provider** - Local file path management
- **PDF** - PDF generation
- **Share Plus** - Share exported files

---

## 📦 Key Packages

```yaml
dependencies:
  flutter:
    sdk: flutter

  flutter_localizations:
    sdk: flutter

  cupertino_icons: ^1.0.8
  shared_preferences: ^2.5.4
  flutter_local_notifications: ^21.0.0
  timezone: ^0.11.0
  flutter_timezone: ^5.0.2
  home_widget: ^0.9.0
  path_provider: ^2.1.5
  image_picker: ^1.1.2
  record: ^6.0.0
  audioplayers: ^6.1.0
  firebase_core: ^4.5.0
  firebase_auth: ^6.2.0
  firebase_analytics: ^12.0.0
  pdf: ^3.11.3
  share_plus: ^11.1.0
  cloud_firestore: ^6.2.0
  firebase_remote_config: ^6.3.0
```

---

## 📋 Prerequisites

Before running this project, make sure you have installed:

- Flutter SDK
- Dart SDK
- Android Studio or VS Code
- Android emulator or physical Android device
- Firebase account
- Git

Check Flutter installation:

```bash
flutter doctor
```

---

## ⚙️ Installation & Setup

### 1️⃣ Clone the Repository

```bash
git clone https://github.com/mehedi77k/Keep_notes.git
cd Keep_notes
```

### 2️⃣ Install Dependencies

```bash
flutter pub get
```

### 3️⃣ Firebase Setup

This app uses Firebase Authentication, Firestore, Analytics, and Remote Config.

To configure Firebase:

1. Go to Firebase Console
2. Create a new Firebase project
3. Add Android app
4. Download `google-services.json`
5. Place it inside:

```text
android/app/google-services.json
```

6. Enable Firebase Authentication
7. Enable Email/Password sign-in method
8. Enable Cloud Firestore
9. Configure Firebase for other platforms if needed

---

### 4️⃣ Run the App

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

To see available devices:

```bash
flutter devices
```

Run on a specific device:

```bash
flutter run -d <device-id>
```

---

## 📁 Project Structure

```text
Keep_notes/
│
├── android/                         # Android native configuration
├── ios/                             # iOS configuration
├── web/                             # Web configuration
├── windows/                         # Windows configuration
├── macos/                           # macOS configuration
├── linux/                           # Linux configuration
├── test/                            # Flutter tests
│
├── assets/
│   └── app_icon/                    # App icon assets
│
├── lib/
│   ├── main.dart                    # Main app code, screens, services, and logic
│   └── firebase_options.dart        # Firebase platform configuration
│
├── firebase.json                    # Firebase configuration
├── pubspec.yaml                     # Project dependencies
├── pubspec.lock                     # Dependency lock file
├── analysis_options.yaml            # Flutter linting rules
└── README.md                        # Project documentation
```

---

## 🔐 Required Permissions

The app may require the following Android permissions:

```xml
android.permission.POST_NOTIFICATIONS
android.permission.SCHEDULE_EXACT_ALARM
android.permission.RECORD_AUDIO
```

### Why these permissions are needed:

- **POST_NOTIFICATIONS** - To show note reminder notifications
- **SCHEDULE_EXACT_ALARM** - To schedule exact reminders
- **RECORD_AUDIO** - To record voice notes

---

## 🔥 Firebase Features Used

This project uses Firebase for secure and cloud-based app features.

### Firebase Authentication

- Sign in
- Sign up
- Password reset
- Change password
- User-specific account access

### Cloud Firestore

- Store user notes
- Sync notes by user ID
- Keep cloud copy of notes
- Support multi-device access

### Firebase Analytics

- Track app events
- Track login and signup events
- Track password change events

### Firebase Remote Config

- App title configuration
- Home banner text
- Enable or disable voice note FAB
- Enable or disable PDF export

---

## 🧠 How the App Works

1. User signs in or creates an account.
2. Firebase Authentication verifies the user.
3. Notes are stored under the logged-in user's account.
4. Notes are saved locally using SharedPreferences.
5. Notes are synced with Firebase Firestore.
6. Users can create, edit, delete, archive, pin, favorite, and label notes.
7. Users can add image and voice attachments.
8. Users can set reminders for important notes.
9. Local notifications show note reminders.
10. Users can export notes as PDF.
11. PIN lock can protect private notes.
12. Home widget can show quick note information on Android.

---

## 🎨 UI/UX Design

The app uses a clean and modern Material 3 design.

### Design Features

- Rounded cards
- Clean input fields
- Smooth app layout
- Light and dark mode
- AMOLED-style dark theme
- Color palette customization
- Grid and list note layout
- Responsive design
- Simple and readable typography

### Main Screens

- Login Page
- Sign Up Page
- Reset Password Page
- Notes Home Page
- Note Editor Page
- Archive Page
- Trash Page
- Settings / Actions Menu
- PIN Unlock Page
- Change Password Page

---

## 🧪 Testing Checklist

Use this checklist before final release:

- [ ] App runs successfully
- [ ] Firebase initialization works
- [ ] User sign up works
- [ ] User sign in works
- [ ] Password reset email works
- [ ] Change password works
- [ ] Create note works
- [ ] Edit note works
- [ ] Delete note works
- [ ] Restore note works
- [ ] Delete forever works
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
- [ ] Share PDF works
- [ ] Backup creation works
- [ ] Backup restore works
- [ ] PIN lock works
- [ ] Theme change works
- [ ] Color palette change works
- [ ] Language change works
- [ ] Home widget works on Android
- [ ] App works after restart

---

## 🚀 Build Commands

### Android APK

```bash
flutter build apk --release
```

### Android App Bundle

```bash
flutter build appbundle --release
```

### Web

```bash
flutter build web --release
```

### Windows

```bash
flutter build windows --release
```

### iOS

```bash
flutter build ios --release
```

---

## ⚠️ Known Limitations

- Firebase setup is required before running full authentication and cloud sync features.
- Voice recording requires microphone permission.
- Reminder notifications require notification permission.
- Exact alarm permission may be required on some Android versions.
- Android home widget features may not work on all platforms.
- Web and desktop platforms may not support all native Android features.
- If Firebase configuration files are missing, the app may not run properly.

---

## 🐛 Troubleshooting

### App does not run

Try:

```bash
flutter clean
flutter pub get
flutter run
```

---

### Firebase error

Check:

- `google-services.json` is placed inside `android/app/`
- Firebase project is created
- Firebase Authentication is enabled
- Cloud Firestore is enabled
- `firebase_options.dart` is correctly generated

---

### Notification not working

Check:

- Notification permission is allowed
- Exact alarm permission is allowed
- App is not battery restricted
- Device timezone is correct

---

### Voice note not working

Check:

- Microphone permission is allowed
- Device microphone is working
- App has storage/path access where needed

---

### Dependencies problem

Run:

```bash
flutter pub get
flutter pub upgrade
```

---

### Flutter setup problem

Run:

```bash
flutter doctor -v
```

Then fix the issues shown in the terminal.

---

## 💡 Future Improvements

Possible future updates:

- Rich text editor with more formatting options
- Cloud image and audio upload support
- Note sharing between users
- Collaboration features
- AI note summary
- Smart search
- Note categories
- Calendar reminder view
- Lock individual notes
- Biometric unlock
- More widget designs
- Export all notes as PDF
- Import notes from external files
- Web dashboard support
- Better analytics dashboard

---

## 🤝 Contributing

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

## 👨‍💻 Developer

**Mehedi Hasan**

- GitHub: [@mehedi77k](https://github.com/mehedi77k)
- Project: Keep Notes App
- Built with Flutter, Dart, and Firebase

---

## 📞 Support

If you face any issue or have suggestions, please open an issue in the GitHub repository.

Repository:  
https://github.com/mehedi77k/Keep_notes

---

## 📌 Project Status

```text
Status: Active Development
Version: 1.0.0+1
Platform: Flutter
Main Language: Dart
Backend: Firebase
```

---

## ⭐ Show Your Support

If you like this project, please give it a star on GitHub.
