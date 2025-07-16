# 🖥️ Flutter SM Current App (Desktop)

A cross-platform **Flutter Desktop App** for user authentication using **SQLite (with FFI)**. This app demonstrates local sign-in and registration functionality, user profile display, and simple UI logic for login validation—all built with **MVP**.

---

## 🚀 Features

- 📦 Local user authentication with SQLite (using `sqflite_common_ffi`)
- 🔒 Login with validation
- 📝 Sign-up with unique username constraint
- 👤 Profile screen showing full user details
- ❌ Error message on failed login
- ✅ Stateless profile screen with navigation
- 🎯 Clean code architecture (split into SQLite, JSON, Components, Views)

---

## 📸 Preview

<p align="center">
  <img src="assets/Screenshot 2025-05-29 211224.png" alt="Login Screen" width="50%" style="margin-right: 10px;" />
  <img src="assets/Screenshot 2025-05-29 211250.png" alt="Profile Screen" width="50%" style="margin: 0 10px;" />
</p>
<p align="center">
  <img src="assets/Screenshot 2025-07-16 025553.png" alt="Login Screen" width="50%" style="margin-right: 10px;" />
  <img src="assets/Screenshot 2025-07-16 025613.png" alt="Profile Screen" width="50%" style="margin: 0 10px;" />
</p>

<p align="center">
  <img src="assets/Screenshot 2025-07-16 030741.png" alt="Login Screen" width="50%" style="margin-right: 10px;" />
  <img src="assets/Screenshot 2025-07-16 030754.png" alt="Profile Screen" width="50%" style="margin: 0 10px;" />
</p>
<p align="center">
  <img src="assets/Screenshot 2025-07-16 030823.png" alt="Login Screen" width="50%" style="margin-right: 10px;" />
  <img src="assets/Screenshot 2025-07-16 030852.png" alt="Profile Screen" width="50%" style="margin: 0 10px;" />
</p>

---

## 📁 Folder Structure

lib/
├── Components/ # Reusable UI components
│ ├── button.dart # Custom styled button
│ ├── colors.dart # App-wide color constants
│ └── textfield.dart # Custom styled input field
│
├── JSON/ # Model classes
│ └── users.dart # User model with serialization
│
├── SQLite/ # Local SQLite database logic
│ └── database_helper.dart # SQLite DB operations (insert, get, authenticate)
│
├── Views/ # App screens and pages
│ ├── login.dart # Login screen UI and logic
│ └── profile.dart # Profile screen UI
│
└── main.dart # App entry pointv

# 📈 Flutter EMG + Pulse Signal Viewer using STM32 and Serial Port

This Flutter project connects to one or two STM32 devices over serial USB (using `serial_port_win32`) and displays real-time EMG signals and generated pulse waveforms using `fl_chart`.

---

## 🧠 Features

- ✅ **Serial communication** with one or two STM32 devices via USB  
- 📡 Real-time **data reading** and **JSON parsing** from STM32  
- 📊 Live plotting of:
  - EMG1, EMG2, EMG3 (from STM32)
  - Signal (raw signal)
  - Pulse signal (generated in Flutter)
- 🔁 Custom **pulse shape generation**:
  - First pulse
  - Second pulse
  - Third pulse
  - Fourth pulse
- 💾 Save received STM32 readings to **SQLite local database**
- 🧩 Modular, maintainable code structure using `Provider`

---

## 🧰 Tech Stack

| Tech                   | Usage                            |
|------------------------|----------------------------------|
| Flutter                | UI and logic                     |
| Provider               | State management                 |
| serial_port_win32      | Read from USB/serial (Windows)   |
| fl_chart               | Real-time chart rendering        |
| SQLite                 | Local persistent storage         |
| STM32 (via USB serial) | Sends sensor data (EMG + more)   |

---

## 📁 Folder Structure


---

## 🛠️ Getting Started

### 1. Clone the repository

```bash
git https://github.com/KhaledElKenawy00/Sm_Current

cd Sm_Current

