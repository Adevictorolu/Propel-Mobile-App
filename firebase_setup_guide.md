# Firebase Setup Guide for Propel Mentorship App

Follow these exact steps to connect your own Firebase project to the Propel Flutter App.

---

## 1. Create a Firebase Project
1. Go to the [Firebase Console](https://console.firebase.google.com/).
2. Click **Add project** (or **Create a project**).
3. Enter Project Name: `propel-mentorship` (or your preferred name) and click **Continue**.
4. Disable or enable Google Analytics according to your preference, then click **Create Project**.

---

## 2. Enable Authentication
1. In the left navigation menu, go to **Build** > **Authentication**.
2. Click **Get Started**.
3. Under **Sign-in method**, choose **Email/Password**.
4. Enable **Email/Password** and click **Save**.

---

## 3. Create Cloud Firestore Database
1. In the left navigation menu, go to **Build** > **Firestore Database**.
2. Click **Create database**.
3. Select a location closest to your users (e.g. `us-central` or `europe-west`).
4. Choose **Start in production mode** or **test mode** and click **Create**.
5. Go to the **Rules** tab and paste the following security rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /profiles/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    match /mentor_profiles/{userId} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    match /mentee_profiles/{userId} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    match /connections/{connectionId} {
      allow read, write: if request.auth != null;
    }
    match /events/{eventId} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    match /messages/{messageId} {
      allow read, write: if request.auth != null;
    }
    match /ratings/{ratingId} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

---

## 4. Register Platforms & Download Credentials

### Android Setup:
1. In Firebase Console, click the **Android** icon (`+ Add app`).
2. Enter Android package name: `com.example.propel` (or as defined in `android/app/build.gradle`).
3. Download `google-services.json`.
4. Move `google-services.json` into `android/app/google-services.json`.

### iOS Setup:
1. In Firebase Console, click the **iOS** icon (`+ Add app`).
2. Enter iOS bundle ID: `com.example.propel` (as defined in Xcode project).
3. Download `GoogleService-Info.plist`.
4. Add `GoogleService-Info.plist` to your iOS project inside Xcode under `Runner/`.

### Web & FlutterFire CLI (Recommended for Cross-Platform):
Run the official FlutterFire CLI inside your project terminal:
```bash
npm install -g firebase-tools
firebase login
dart pub global activate flutterfire_cli
flutterfire configure
```
This automatically generates `lib/firebase_options.dart` with all your Firebase project keys!

---

## 5. Enable Firebase Packages in `pubspec.yaml`
Add the official Firebase SDK packages to `pubspec.yaml`:
```yaml
dependencies:
  firebase_core: ^3.1.0
  firebase_auth: ^5.1.0
  cloud_firestore: ^5.0.1
```

Once configured, call `await Firebase.initializeApp()` inside `lib/main.dart`!
