# 📝 Keep Notes - My Notes App

[![Flutter](https://img.shields.io/badge/Flutter-3.10+-02569B?style=for-the-badge&logo=flutter)](https://flutter.dev/)
[![Firebase](https://img.shields.io/badge/Firebase-Platform-FFCA28?style=for-the-badge&logo=firebase)](https://firebase.google.com/)
[![Dart](https://img.shields.io/badge/Dart-3.10+-0175C2?style=for-the-badge&logo=dart)](https://dart.dev/)
[![Android](https://img.shields.io/badge/Android-Supported-3DDC84?style=for-the-badge&logo=android&logoColor=white)](https://developer.android.com/)
[![Status](https://img.shields.io/badge/Status-Active%20Development-brightgreen?style=for-the-badge)](#)

> A modern Flutter-based note taking application for creating, organizing, securing, and managing important notes with Firebase authentication, cloud sync, reminders, voice notes, image attachments, PDF export, and home widget support.

---

## 📱 Overview

**Keep Notes - My Notes App** is a smart and user-friendly note taking application designed for students, professionals, and daily users who want to save important information in a simple, secure, and organized way.

The app allows users to create notes, edit notes, organize notes with labels, set reminders, attach images, record voice notes, archive notes, move deleted notes to trash, export notes as PDF, and protect the app using a PIN lock.

It is built with **Flutter**, **Dart**, and **Firebase**, making it modern, scalable, and suitable for cross-platform development.

### ✨ Key Highlights

- 📝 **Smart Notes Management** - Create, edit, duplicate, archive, restore, and delete notes
- 🔐 **Firebase Authentication** - Secure email/password login and signup system
- ☁️ **Cloud Sync** - Notes can be stored and synced using Firebase Firestore
- 🔒 **PIN Lock** - Protect personal notes with a 4-6 digit PIN
- ⏰ **Reminders** - Set note reminders using local notifications
- 🖼️ **Image Attachments** - Add images to notes for visual information
- 🎙️ **Voice Notes** - Record and attach audio notes
- 📄 **PDF Export** - Export notes as professional PDF files
- 🏠 **Home Widget** - Android home widget support for quick access
- 🌙 **Dark Mode** - Light, dark, and system theme support
- 🌐 **Language Support** - English and Bangla language support
- 🎨 **Custom Theme Palette** - Multiple color palettes for personalization

---

## 🚀 Features

### 👤 User Features

#### 🔐 Authentication

- Create a new account
- Login with email and password
- Firebase Authentication integration
- Forgot password support
- Password reset email
- Change password option
- User-specific note access

#### 📝 Notes Management

- Create new notes
- Edit existing notes
- Save note title and description
- Duplicate notes
- Delete notes
- Restore deleted notes
- Permanently delete notes
- Organize notes in grid or list layout

#### 📌 Pin & Favorite Notes

- Pin important notes
- Unpin notes
- Mark notes as favorite
- Remove notes from favorite
- Keep important notes visible at the top

#### 🏷️ Labels & Organization

- Add labels to notes
- Use multiple labels
- Filter notes by labels
- Organize personal, study, work, and idea notes
- Keep notes clean and structured

#### 🔍 Search, Filter & Sort

- Search notes quickly
- Search trash notes
- Filter pinned notes
- Filter notes with labels
- Filter notes due today
- Filter notes without reminders
- Sort notes by newest first
- Sort notes by oldest first
- Sort notes by title
- Sort notes by pinned first

#### 📦 Archive System

- Archive notes
- View archived notes
- Unarchive notes
- Keep the main notes screen clean
- Separate active notes from old notes

#### 🗑️ Trash System

- Move notes to trash
- View deleted notes
- Restore notes from trash
- Delete notes permanently
- Undo move to trash
- Confirm before moving notes to trash

#### ⏰ Reminders & Notifications

- Set reminder for notes
- Clear note reminders
- Local notification support
- Due today filter
- Timezone support
- Exact alarm support on Android
- Useful for tasks, study plans, and important events

#### 🖼️ Image Attachments

- Attach images to notes
- Store image path
- View image attachments inside notes
- Useful for screenshots, documents, and visual notes

#### 🎙️ Voice Notes

- Record voice notes
- Stop voice recording
- Attach audio to notes
- Play recorded audio
- Pause audio playback
- Microphone permission handling

#### 📄 PDF Export

- Export a note as PDF
- Save generated PDF file
- Share exported PDF
- Useful for reports, assignments, study notes, and documentation

#### 🔁 Backup & Restore

- Create notes backup
- Restore notes from backup
- Auto backup on save option
- User-specific backup filename
- Local JSON backup support

#### 🏠 Android Home Widget

- Home widget support
- Quick access to notes
- Small, medium, and large widget support
- Launch app from widget
- Useful for fast note access

#### 🔒 PIN Lock

- Set 4-6 digit PIN
- Change PIN
- Remove PIN
- Lock the app manually
- Unlock notes using PIN
- Extra privacy for personal information

#### 🎨 Theme & Customization

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

#### 🌐 Language Support

- English language
- Bangla language
- Persistent language selection
- Localized app labels and messages

#### 📊 Notes Statistics

- Total notes count
- Active notes count
- Archived notes count
- Trash notes count
- Pinned notes count
- Notes with reminders count

---

## 🛠️ Technology Stack

### Frontend

- **Flutter** - Cross-platform UI framework
- **Dart** - Programming language
- **Material 3** - Modern design system
- **Flutter Localizations** - Multi-language support

### Backend & Cloud

- **Firebase Authentication** - Email/password authentication
- **Cloud Firestore** - Cloud database for notes
- **Firebase Analytics** - Analytics event tracking
- **Firebase Remote Config** - Remote app configuration

### Local Storage & Device Features

- **SharedPreferences** - Local storage for settings and cache
- **Flutter Local Notifications** - Reminder notifications
- **Timezone** - Timezone-based reminder scheduling
- **Home Widget** - Android home screen widget support
- **Image Picker** - Image attachment support
- **Record** - Voice recording
- **Audioplayers** - Audio playback
- **Path Provider** - Local file path management
- **PDF** - PDF generation
- **Share Plus** - Share exported files

### Key Packages

```yaml
- firebase_core
- firebase_auth
- cloud_firestore
- firebase_analytics
- firebase_remote_config
- shared_preferences
- flutter_local_notifications
- timezone
- flutter_timezone
- home_widget
- path_provider
- image_picker
- record
- audioplayers
- pdf
- share_plus
```

---

## 📋 Prerequisites

Before you begin, ensure you have:

- Flutter SDK installed
- Dart SDK installed
- Firebase account
- Android Studio or VS Code
- Android emulator or physical Android device
- Git installed

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

This app uses Firebase Authentication, Cloud Firestore, Firebase Analytics, and Firebase Remote Config.

#### Option A: Use Existing Configuration

If Firebase is already configured, make sure the required Firebase files are available.

For Android, place:

```text
android/app/google-services.json
```

#### Option B: Full Firebase Setup

1. Go to Firebase Console
2. Create a new Firebase project
3. Add an Android app
4. Download `google-services.json`
5. Place it inside `android/app/`
6. Enable Firebase Authentication
7. Enable Email/Password sign-in method
8. Enable Cloud Firestore
9. Enable Firebase Analytics
10. Enable Firebase Remote Config if needed
11. Generate or update `firebase_options.dart`

### 4️⃣ Run the App

```bash
# For Android
flutter run

# For Web
flutter run -d chrome

# For Windows
flutter run -d windows

# For specific device
flutter devices
flutter run -d <device-id>
```

---

## 📁 Project Structure

```text
Keep_notes/
│
├── android/                      # Android configuration
├── ios/                          # iOS configuration
├── linux/                        # Linux configuration
├── macos/                        # macOS configuration
├── web/                          # Web configuration
├── windows/                      # Windows configuration
├── test/                         # Flutter test files
│
├── assets/
│   └── app_icon/                 # App icon assets
│
├── lib/
│   ├── main.dart                 # Main app code, screens, services, and logic
│   └── firebase_options.dart     # Firebase platform configuration
│
├── firebase.json                 # Firebase configuration
├── pubspec.yaml                  # Project dependencies
├── pubspec.lock                  # Dependency lock file
├── analysis_options.yaml         # Flutter linting rules
└── README.md                     # Project documentation
```

---

## 🔒 Security & Privacy

This app includes multiple privacy-focused features:

```text
- Firebase Authentication for secure login
- User-specific note storage
- PIN lock for app privacy
- Password reset support
- Local settings stored securely using SharedPreferences
- Notes can be synced under logged-in user account
- Trash system prevents accidental permanent deletion
```

### Required Permissions

The app may require the following Android permissions:

```xml
android.permission.POST_NOTIFICATIONS
android.permission.SCHEDULE_EXACT_ALARM
android.permission.RECORD_AUDIO
```

### Permission Usage

- **POST_NOTIFICATIONS** - Used to show note reminder notifications
- **SCHEDULE_EXACT_ALARM** - Used to schedule exact note reminders
- **RECORD_AUDIO** - Used to record voice notes

---

## 🔥 Firebase Features Used

### Firebase Authentication

- Sign up
- Sign in
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
- Track login event
- Track signup event
- Track password change event

### Firebase Remote Config

- App title configuration
- Home banner text
- Enable or disable voice note FAB
- Enable or disable PDF export

---

## 📖 Documentation

This README includes the full setup and usage guide for the project.

Useful sections:

- Installation & Setup
- Firebase Setup
- Project Structure
- Required Permissions
- Testing Checklist
- Build Commands
- Troubleshooting

---

## 🎨 Design System

### Color Palettes

```dart
Emerald
Ocean
Sunset
Rose
Amber
Violet
Teal
Slate
Coral
Indigo
```

### Theme Modes

- Light Theme
- Dark Theme
- System Theme
- AMOLED-style Dark Theme

### UI Components

- Rounded note cards
- Clean input fields
- Material 3 buttons
- Responsive grid/list view
- Smooth navigation
- Minimal and readable design
- Theme-based color system

---

## 🧪 Testing

### Manual Testing Checklist

- [ ] App runs successfully
- [ ] Firebase initialization works
- [ ] User sign up works
- [ ] User sign in works
- [ ] Password reset email works
- [ ] Change password works
- [ ] Create note works
- [ ] Edit note works
- [ ] Duplicate note works
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

## 🚀 Deployment

### Android

```bash
flutter build apk --release
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

---

## 💡 Key Achievements

- ✅ **Modern Note Taking App** - Clean and practical note management system
- ✅ **Firebase Authentication** - Secure login and signup system
- ✅ **Cloud Firestore Sync** - User-specific notes can be stored in cloud
- ✅ **PIN Lock System** - Extra privacy for personal notes
- ✅ **Reminder Support** - Local notifications for important notes
- ✅ **Voice Notes** - Audio recording and playback support
- ✅ **Image Attachments** - Visual note support
- ✅ **PDF Export** - Notes can be exported and shared as PDF
- ✅ **Home Widget Support** - Android widget support for quick access
- ✅ **Multi-language Support** - English and Bangla support
- ✅ **Custom Themes** - Multiple palettes and dark mode support
- ✅ **Cross-platform** - Android, iOS, Web, Windows, macOS, and Linux support from one codebase

---

## 🐛 Known Issues & Solutions

If you encounter any problems:

1. Verify Firebase configuration
2. Make sure all dependencies are installed
3. Check Flutter doctor
4. Check Android permissions
5. Check notification permission
6. Check microphone permission for voice notes
7. Check `google-services.json` location

### Common Fix

```bash
flutter clean
flutter pub get
flutter run
```

### Flutter Doctor

```bash
flutter doctor -v
```

### Dependency Update

```bash
flutter pub get
flutter pub upgrade
```

---

## ⚠️ Known Limitations

- Firebase setup is required for authentication and cloud sync
- Voice recording requires microphone permission
- Reminder notifications require notification permission
- Exact alarm permission may be required on some Android versions
- Android home widget features may not work on all platforms
- Web and desktop platforms may not support all native Android features
- If Firebase configuration files are missing, the app may not run properly

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

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch

```bash
git checkout -b feature/AmazingFeature
```

3. Commit your changes

```bash
git commit -m "Add some AmazingFeature"
```

4. Push to the branch

```bash
git push origin feature/AmazingFeature
```

5. Open a Pull Request

---

## 📝 License

This project is open for educational and learning purposes.

If you want to use an open-source license, you can add a `LICENSE` file to the repository.

---

## 👨‍💻 Developer

**Mehedi Hasan**

- GitHub: [@mehedi77k](https://github.com/mehedi77k)
- Project: Keep Notes - My Notes App
- Built with Flutter, Dart, and Firebase

---

## 📞 Support

For support, open an issue in the GitHub repository.

Repository:  
https://github.com/mehedi77k/Keep_notes

---

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Firebase team for powerful backend services
- Dart team for the programming language
- Open-source package contributors
- All testers and users

---

## 📊 Project Status

✅ **Active Development** - Features are being improved and updated

**Version**: 1.0.0+1  
**Platform**: Flutter  
**Main Language**: Dart  
**Backend**: Firebase  
**Status**: Active Development

---

<div align="center">

### ⭐ Star this repository if you find it helpful!

Made with ❤️ using Flutter and Firebase

</div>
