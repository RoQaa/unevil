# 🚶 Project Walkthrough - Unveil

This document provides a step-by-step explanation of how the Unveil application works, from the user interface to the AI backend.

## 1. User Lifecycle (Auth Flow)
*   **Sign Up**: When a user registers, the app uses `Firebase Authentication` to create an account. Simultaneously, it creates a user document in `Firestore` (`users/{uid}`) to store profile metadata.
*   **Login/Persistence**: The app uses an `AuthGate` in `main.dart` which listens to `authStateChanges()`. This ensures that if a user is already logged in, they are immediately taken to the Home screen without re-entering credentials.

## 2. Analysis Flow (The "Brain")
Every analysis page (Text, Image, Audio, Video) follows a standardized pattern:

1.  **Input Collection**: User enters text or picks a file using `image_picker` or `file_picker`.
2.  **API Request**: The app sends the data via a `MultipartRequest` (for files) or a JSON `POST` (for text) to the FastAPI backend.
3.  **Backend Processing**:
    *   **Text**: Analyzes word variance and formal patterns.
    *   **Image/Video**: Scans pixels for "GAN artifacts" using Sightengine.
    *   **Audio**: Uses a neural network to find "cloned" frequencies.
4.  **Result Handling**: The backend returns a JSON containing `result`, `confidence`, and `reason`.
5.  **UI Update**: The app displays the `AnalysisResultCard` with a visual progress bar.
6.  **Auto-Save**: The `HistoryService.saveHistory()` function is called to record the analysis in Firestore under `users/{uid}/history`.

## 3. History Management
*   The **History Page** uses a `StreamBuilder`. This is crucial because it provides "Real-time" updates. If a user deletes an item or adds a new analysis, the UI updates instantly without refreshing.
*   **Filtering**: Users can filter by type (Text/Image/etc.) using `FilterChips` which perform client-side filtering on the stream data.

## 4. Design System
*   **Responsive Scaling**: We use `ScreenUtil`. This means a button defined as `52.h` will look proportionately the same on a small Android phone and a large iPad.
*   **Typography**: All text uses the `AppTypography` class. This makes it easy to change the font or size globally across the entire app by editing one file.

---
## 🛠️ How to explain the code to a developer:
"The project is a **Decoupled Architecture**. The Flutter frontend handles the UX and data persistence via Firebase, while the Python backend acts as an **AI Inference Microservice**. We use Firebase as a **Backend-as-a-Service (BaaS)** to handle the heavy lifting of security and database management, allowing the app to scale across multiple platforms easily."
