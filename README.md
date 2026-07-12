# ALU Startup Connect

ALU Startup Connect is a mobile application built to bridge the gap between ALU students and startups seeking talent. Students can explore opportunities (internships, full-time jobs) while verified startups can post roles and manage applicants.

## 📱 Features
- **Role-based Access**: Custom dashboards for Students, Startups, and Administrators.
- **Admin Verification**: Startups must upload proof documents to be approved by an Admin before accessing the platform.
- **Student Profiles**: Base64 image compression for avatars and resumes seamlessly synced with Cloud Firestore.
- **Real-time Updates**: Status monitoring and real-time approval detection using Firestore streams.
- **Modern UI**: Polished Flutter UI with custom animations and interactive components.

## 🛠️ Tech Stack
- **Framework:** Flutter / Dart
- **Backend as a Service:** Firebase (Auth & Cloud Firestore)
- **Routing:** `go_router`
- **State Management & UI:** Built-in Flutter features + `flutter_animate`

---

## 🚀 How to Run the App Locally

Follow these instructions to set up and run the app on your local machine or physical device.

### 1. Prerequisites
Ensure you have the following installed:
* [Flutter SDK](https://docs.flutter.dev/get-started/install) (Ensure `flutter doctor` passes without major issues)
* [Android Studio](https://developer.android.com/studio) (for Android emulator/tools) or Xcode (for iOS)
* A physical device connected via USB or an active Emulator.

### 2. Getting the Code
Open your terminal and navigate to the project directory.
```bash
# If you haven't already fetched dependencies:
flutter pub get
```

### 3. Firebase Setup (If needed)
The app is already connected to a Firebase project via the generated `firebase_options.dart` file. 
*Note: If you are setting this up for a fresh Firebase project, you will need to run `flutterfire configure` to generate your own `firebase_options.dart`.*

### 4. Running the App
The most stable way to run the app is using a **USB connection** (wireless ADB can sometimes be unstable and drop connection).

1. Connect your Android/iOS phone via USB cable.
2. Make sure **USB Debugging** is enabled in your phone's Developer Options.
3. Check that your device is recognized by Flutter:
   ```bash
   flutter devices
   ```
4. Run the app:
   ```bash
   flutter run
   ```

### 5. Testing the Roles
Once the app is running, you can test the three different flows:

* **Admin Role**: Log in using `admin@aluadmin.com` to access the Admin Dashboard where you can approve/reject startups. (See `ADMIN_SETUP.md` for rules).
* **Startup Role**: Create an account, select "Startup", and upload a proof document (PDF or Image). You will be put on a "Verification Pending" screen until an Admin approves you.
* **Student Role**: Sign up with an `@alustudent.com` email address to directly access the student dashboard and browse jobs.

---

## 📝 Common Troubleshooting

- **"Lost connection to device" / App crashes suddenly during testing:** 
  This usually happens if you are using Wireless Debugging and your Wi-Fi drops. Switching to a USB cable solves this.
- **Upload fails/hangs on Startup signup:**
  Ensure the proof document is less than 700KB. The app automatically compresses images, but large raw PDFs might exceed Firestore's 1MB document limit.