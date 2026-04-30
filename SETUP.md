# 🚀 Complete Run & Setup Guide - Unveil

Follow these steps to get the Unveil project running on your local machine.

---

## 1. Prerequisites (What you need to install)

### For the App (Frontend):
*   **Flutter SDK**: [Install Flutter](https://docs.flutter.dev/get-started/install) (Version 3.19.0 or higher recommended).
*   **Android Studio / VS Code**: With Flutter & Dart extensions.
*   **Chrome Browser**: For web testing.

### For the AI Engine (Backend):
*   **Python 3.9+**: [Download Python](https://www.python.org/downloads/).
*   **FFmpeg**: **CRITICAL for Audio Analysis.**
    *   **Windows**: `winget install ffmpeg` (or download from ffmpeg.org).
    *   **Mac**: `brew install ffmpeg`.
    *   **Linux**: `sudo apt install ffmpeg`.

---

## 2. Backend Setup (AI Microservice)

1.  **Open a Terminal** and navigate to the backend folder:
    ```bash
    cd backend
    ```
2.  **Create a Virtual Environment** (Optional but recommended):
    ```bash
    python -m venv venv
    # Activate on Windows:
    .\venv\Scripts\activate
    # Activate on Mac/Linux:
    source venv/bin/activate
    ```
3.  **Install Dependencies**:
    ```bash
    pip install -r requirements.txt
    ```
4.  **Configure API Keys**:
    Create a file named `.env` in the `backend/` folder and add your Sightengine credentials:
    ```env
    SIGHTENGINE_API_USER=your_user_id
    SIGHTENGINE_API_SECRET=your_api_secret
    ```
5.  **Run the Backend**:
    ```bash
    uvicorn main:app --reload --port 8000
    ```
    *Keep this terminal open.* The backend must be running for analysis to work.

---

## 3. Frontend Setup (Flutter App)

1.  **Open a new Terminal** (in the root project folder):
    ```bash
    flutter pub get
    ```
2.  **Firebase Setup**:
    The project is already configured with `firebase_options.dart`. If you want to use your own Firebase project:
    *   Install FlutterFire CLI: `dart pub global activate flutterfire_cli`
    *   Run: `flutterfire configure`
3.  **Run the App**:
    *   **Web**: `flutter run -d chrome`
    *   **Mobile**: Connect your phone/emulator and run `flutter run`

---

## 4. Testing the Integration

Once both are running:
1.  Open the App.
2.  Register a new account or Login.
3.  Go to **Text Analysis**.
4.  Enter some text and click **Analyze**.
5.  If you see a result, the connection between Frontend and Backend is successful!

---

## 🛠️ Troubleshooting

*   **"Connection Refused"**: Ensure the backend is running on `localhost:8000`. If you are testing on a **Physical Android/iOS Device**, change `localhost` in `lib/config.dart` to your computer's **Local IP Address** (e.g., `192.168.1.5`).
*   **"Audio Analysis Failed"**: Ensure `ffmpeg` is installed and added to your System PATH.
*   **"Firebase Error"**: Ensure you have enabled **Email/Password Authentication** and **Cloud Firestore** in your Firebase Console.

---
**Note**: The app is designed to be cross-platform (iOS, Android, Windows, macOS, Web). The UI will automatically adapt to the screen size.
