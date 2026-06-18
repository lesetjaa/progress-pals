# Progress Pals 🚀

**Stop quitting. Start sharing.** Progress Pals is a social habit-tracking application built with Flutter and Firebase that leverages accountability to help users stick to their goals.

[![App Store](https://img.shields.io/badge/App_Store-Download-blue?logo=apple)](https://apps.apple.com/us/app/progress-pals/id6759215046)
[![Portfolio](https://img.shields.io/badge/Portfolio-lesetja.dev-green)](https://lesetja.dev)

---

## 📱 About the Project
Progress Pals was born out of a simple idea: habits are easier to keep when you aren't doing them alone. As a student at **UNISA**, I developed this app to solve the "silent quitter" problem by allowing a friend to see and cheer each other's progress in real-time.

### Key Features
* **Social Accountability:** Add a friend via email and share specific habits with them.
* **Visual Analytics:** Custom-built Bezier curve charts to visualize completion streaks over time.
* **Hybrid Data Architecture:** Seamlessly syncs between a local SQLite database and Firebase Cloud Firestore.
* **Privacy First:** Full user control with secure Firebase Authentication and a mandatory Account Deletion feature.
* **Themed Experience:** Full support for Light and Dark modes.

---

## 🛠 Tech Stack
* **Frontend:** [Flutter](https://flutter.dev) (Dart)
* **Backend:** [Firebase](https://firebase.google.com) (Auth, Firestore, Cloud Functions/Extensions)
* **Local Storage:** [sqflite](https://pub.dev/packages/sqflite) (SQLite for Flutter)
* **State Management:** [Provider](https://pub.dev/packages/provider)
* **Architecture:** Clean Architecture with MVVM (Model-View-ViewModel)

---

## 🏗 Project Structure
The project follows a modular structure to ensure maintainability and scalability:

```
└── lib
    └── core
        └── theme
            ├── app_colors.dart
            ├── app_theme.dart
            ├── theme_extensions.dart
            ├── theme_provider.dart
    └── data
        └── datasources
            └── local
                ├── database_service.dart
            └── remote
                ├── firebase_service.dart
        └── models
            ├── friend_model.dart
            ├── habit_model.dart
        └── repositories
            ├── habit_repository.dart
    └── presentation
        └── pages
            └── analytics
                ├── analytics_page.dart
                ├── friend_analytics_page.dart
            └── auth
                ├── welcome_page.dart
            └── friends
                ├── add_friend.dart
                ├── friends_page.dart
            └── habit
                ├── add_habit.dart
                ├── habit_detail_page.dart
            └── home
                ├── home_content.dart
                ├── home_page.dart
            └── profile
                ├── profile_page.dart
        └── viewmodels
            ├── friends_viewmodel.dart
            ├── home_viewmodel.dart
        └── widgets
            ├── app_button.dart
            ├── date_bubble.dart
            ├── habit_card.dart
    ├── app_router.dart
    ├── app_state.dart
    ├── firebase_options.dart
    └── main.dart
```

🚀 Getting Started
Prerequisites
Flutter SDK (3.x or higher)

CocoaPods (for iOS builds)

A Firebase Project

Installation
Clone the repo:

```Bash
git clone [https://github.com/your-username/progress-pals.git](https://github.com/your-username/progress-pals.git)
Install dependencies:
```

```Bash
flutter pub get
```
Configure Firebase:

Add your google-services.json (Android) and GoogleService-Info.plist (iOS).

Run the app:

```Bash
flutter run
```
📄 Privacy & Support

Support: lesetja.dev/support

Privacy Policy: lesetja.dev/privacy

👨‍💻 Developer
Lesetja Student at UNISA, South Africa

Portfolio: [lesetja.dev](http://lesetja.dev)

LinkedIn: [Lesetja](www.linkedin.com/in/lesetja)

Email: progresspals@lesetja.dev

📜 License
Distributed under the MIT License. See LICENSE for more information.


---