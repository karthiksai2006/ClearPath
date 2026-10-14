# ClearPath 🚑⚡

**Real-Time Emergency Vehicle Proximity Alert System for Connected Drivers**  
*A Social-Impact Intelligent Transportation Prototype*

---

## 🌟 Overview & Problem Statement

Every year, ambulances encounter severe delays in congested traffic because drivers in front cannot see or hear sirens until the emergency vehicle is directly behind them. Traditional sirens suffer from acoustic insulation in modern cars, loud audio systems, and urban echo reflection.

**ClearPath** solves this problem by establishing a real-time, lightweight peer-to-peer awareness network between emergency vehicles and participating civilian drivers:
- When an ambulance enters **Emergency Mode**, it securely broadcasts its live coordinates over WebSockets.
- Participating driver devices receive a high-visibility, high-priority alert:  
  **`"AMBULANCE APPROACHING — MAKE WAY WHEN SAFE"`**  
  the exact moment the ambulance enters a **100-foot (30.48-metre)** radius.
- **Automatic Deactivation**: The alert vanishes automatically the moment the ambulance passes outside the 30.48m perimeter, if the ambulance terminates its emergency session, or if location updates become stale (>5 seconds).

---

## ⚠️ Safety, Ethics & Prototype Boundaries

> [!IMPORTANT]
> **Proximity Threshold vs. Lane Proof**: 100 feet (30.48m) measures physical Euclidean proximity using the geographic Haversine formula. It is an awareness threshold, **not** proof that a vehicle is in the ambulance's specific lane or direction of travel. Drivers must always check mirrors and yield only when safe.

> [!WARNING]
> **No Dashboard Auto-Interference**: ClearPath is an app-based prototype for participating smartphones, tablets, or web dashboards. An ordinary app cannot broadcast directly into unsupported vehicle dashboard hardware or warn non-participating vehicles.

> [!CAUTION]
> **Prototype Demonstration Only**: ClearPath is designed for education, hackathon demonstration, and civic research. It is **not certified or licensed for real-world life-or-death emergency dispatch**.

---

## 🏗️ Architecture & Technical Stack

```
                                  +-------------------------------------------+
                                  |         FastAPI Real-Time Backend         |
                                  |   - Haversine Distance Engine (30.48m)    |
                                  |   - Dispatcher Auth & Anti-Spoofing       |
                                  |   - WebSocket Telemetry Broadcaster       |
                                  |   - Road Corridor Simulation Engine       |
                                  +---------------------+---------------------+
                                                        |
                                       WebSocket / HTTP | JSON Stream
                                                        |
                 +--------------------------------------+--------------------------------------+
                 |                                                                             |
+----------------v-------------------+                                 +-----------------------v-------------------+
|      Ambulance Dispatcher Mode     |                                 |             Civilian Driver Mode          |
|  - Start / Stop Emergency Session  |                                 |  - Real-time Proximity Radar              |
|  - Passcode: CLEARPATH-EMERGENCY-2026 |                              |  - Prominent Warning Screen:              |
|  - Session Token Validation        |                                 |    "AMBULANCE APPROACHING —               |
|  - Live Coordinate Stream          |                                 |     MAKE WAY WHEN SAFE"                   |
+------------------------------------+                                 |  - Instant Automatic Deactivation         |
                                                                       +-------------------------------------------+
                                                        |
                                       +----------------v------------------+
                                       |     Interactive Road Simulation   |
                                       |  - 300m Road Corridor Canvas      |
                                       |  - 30.48m (100ft) Radius Bubble   |
                                       |  - Ambulance + 3 Civilian Cars    |
                                       |  - Play / Pause / Step / Reset    |
                                       +-----------------------------------+
```

### Components
- **Backend**: Python 3.11+, FastAPI, Uvicorn, WebSockets, Pydantic, Pytest.
- **Frontend**: Flutter 3.44+, Dart 3.12+, WebSocket Channel, Material 3 Dark UI.
- **Mathematics**: Spherical Earth Haversine formula ($R = 6,371,000 \text{ m}$), evaluated with $d \le 30.48\text{ m}$.

---

## 🗂️ Project Directory Structure

```text
hack 2 skill/
├── .gitignore                      # Git ignore for Python, Flutter, Windows & IDEs
├── pytest.ini                      # Pytest discovery configuration
├── README.md                       # Complete documentation & run instructions
├── backend/
│   ├── __init__.py
│   ├── requirements.txt            # Backend dependencies
│   ├── app/
│   │   ├── __init__.py
│   │   ├── main.py                 # FastAPI application, REST & WebSocket endpoints
│   │   ├── models.py               # Pydantic schemas (Vehicles, Coordinates, Alerts)
│   │   ├── proximity.py            # Haversine distance engine & 30.48m threshold rule
│   │   ├── auth.py                 # Dispatcher passcode security & anti-spoofing
│   │   ├── simulation.py           # Multi-vehicle corridor road simulation
│   │   └── websocket_manager.py    # Real-time WebSocket connection manager
│   └── tests/
│       ├── __init__.py
│       ├── test_proximity.py       # 30.48m threshold, auto-clearing & staleness tests
│       ├── test_simulation.py      # Corridor movement & vehicle wrapping tests
│       └── test_api.py             # Session start/stop & security endpoint tests
└── frontend/
    ├── pubspec.yaml                # Flutter project manifest & dependencies
    ├── lib/
    │   ├── main.dart               # App entry point & dark theme configuration
    │   ├── models/
    │   │   ├── vehicle.dart        # Vehicle and coordinate models
    │   │   └── alert_state.dart    # Proximity alert state & Haversine helper
    │   ├── services/
    │   │   └── websocket_service.dart # Real-time client with auto-reconnect & API helpers
    │   ├── widgets/
    │   │   ├── alert_banner.dart   # High-priority warning banner / warning screen
    │   │   ├── connection_badge.dart # Online / Reconnecting / Offline badge
    │   │   └── safety_disclaimer.dart # Safety boundaries banner
    │   └── screens/
    │       ├── home_screen.dart    # Mode selection dashboard
    │       ├── ambulance_screen.dart # Authenticated emergency start/stop screen
    │       ├── driver_screen.dart  # Driver HUD with warning screen
    │       └── simulation_screen.dart # Visual road canvas with 30.48m perimeter bubble
    └── test/
        └── widget_test.dart        # Flutter widget and unit test suite
```

---

## 🚀 Setup & Execution Guide (Windows PowerShell)

Follow these step-by-step instructions. No prior setup is assumed.

### Step 1: Open Windows PowerShell in the Project Directory
```powershell
cd "c:\Users\DELL\Desktop\KARTHIK\hack 2 skill"
```

### Step 2: Set Up Backend Virtual Environment
```powershell
# Create Python virtual environment using Python 3.11 launcher
py -3.11 -m venv .venv

# Activate the virtual environment
.\.venv\Scripts\Activate.ps1

# Upgrade pip and install dependencies
pip install --trusted-host pypi.org --trusted-host files.pythonhosted.org -r backend/requirements.txt
```

### Step 3: Run Backend Automated Tests
Verify that all 13 proximity, simulation, and security tests pass:
```powershell
.\.venv\Scripts\pytest.exe -v
```

### Step 4: Start the FastAPI Backend Server
```powershell
python -m uvicorn backend.app.main:app --reload --port 8000
```
The backend API is now live at:
- **API URL**: `http://127.0.0.1:8000`
- **Interactive Swagger Docs**: `http://127.0.0.1:8000/docs`
- **Health Check**: `http://127.0.0.1:8000/health`
- **WebSocket Endpoint**: `ws://127.0.0.1:8000/ws/telemetry`

---

### Step 5: Start the Flutter App (In a New Terminal Tab)
Open a second PowerShell window:
```powershell
cd "c:\Users\DELL\Desktop\KARTHIK\hack 2 skill\frontend"

# Verify codebase health
flutter analyze

# Run Flutter automated test suite
flutter test

# Launch the app in Google Chrome (instant cross-platform web mode)
flutter run -d chrome
```

---

## 🧪 How to Demonstrate the 100-Foot (30.48m) Activation & Deactivation

You can demonstrate the core functionality in two easy ways:

### Method A: Interactive Road Simulation Screen (All-in-One View)
1. In the ClearPath app, select **"Interactive Road Simulation"**.
2. Click **"PLAY SIMULATION"** or use **"STEP +1s"**:
   - The road corridor spans 300 metres with three civilian cars (`CAR-01` at 60m, `CAR-02` at 130m, `CAR-03` at 210m).
   - As the ambulance drives forward, observe its red circular **30.48m (100ft) safety bubble**.
   - **Activation**: When the ambulance enters within 30.48m of `CAR-01`, `CAR-01`'s badge immediately turns **RED** with `"ACTIVE ALERT"`.
   - **Automatic Deactivation**: As the ambulance drives past 91m (distance > 30.48m), `CAR-01`'s alert **automatically clears** back to `"CLEAR"`.
   - Next, `CAR-02` enters the bubble and triggers an alert.
3. **Emergency Stop Test**: Click **"EMERGENCY: ON"** to toggle it OFF. Notice that all alerts instantly vanish, even if a car is directly next to the ambulance!

### Method B: Multi-Window Dual Device Demo (Ambulance + Driver)
1. Open ClearPath in two browser tabs or windows side-by-side.
2. In Window 1, select **Driver Mode** (monitoring `CAR-01`).
3. In Window 2, select **Ambulance Mode**:
   - Enter passcode: `CLEARPATH-EMERGENCY-2026`
   - Click **"START EMERGENCY MODE"**.
4. In the simulation controls, step the ambulance towards 60m:
   - On the Driver screen, observe the screen erupt into the high-priority warning:  
     **`"AMBULANCE APPROACHING — MAKE WAY WHEN SAFE"`**  
     with real-time distance countdown (e.g. `22.5 m (74 ft)`).
   - Step the ambulance past `CAR-01` (> 30.48m away): observe the alert **automatically clear** to a calm green radar screen.
   - Click **"STOP EMERGENCY SESSION"** in Ambulance Mode: alerts immediately deactivate.

---

## 🔒 Security: Fake Ambulance Protection

To prevent pranksters or malicious users from falsely triggering evacuation alerts:
1. ClearPath ambulances must provide an authorized security dispatcher passcode (`CLEARPATH-EMERGENCY-2026`).
2. The server issues a cryptographically secure, time-stamped emergency session token (`EMG-<32-hex>`).
3. Without this token, coordinate broadcasts and emergency sirens are rejected with HTTP 401/403.
4. When the session is stopped, the token is revoked immediately.

---

## 📐 Mathematical Formulation (Haversine Formula)

ClearPath calculates physical distance using the spherical law of Haversine:
$$\Delta\phi = \text{radians}(\text{lat}_2 - \text{lat}_1), \quad \Delta\lambda = \text{radians}(\text{lon}_2 - \text{lon}_1)$$
$$a = \sin^2\left(\frac{\Delta\phi}{2}\right) + \cos(\phi_1)\cos(\phi_2)\sin^2\left(\frac{\Delta\lambda}{2}\right)$$
$$c = 2 \cdot \text{atan2}\left(\sqrt{a}, \sqrt{1 - a}\right)$$
$$d = R \cdot c \quad (\text{with } R = 6,371,000\text{ metres})$$

### 100-Foot Threshold Rule:
$$\text{Alert Status} = \begin{cases} \mathbf{ACTIVE}, & \text{if } d \le 30.48\text{ m} \text{ AND } \text{Session is ACTIVE} \text{ AND } \Delta t \le 5\text{ s} \\ \mathbf{CLEARED}, & \text{otherwise} \end{cases}$$

---

## 📦 How to Upload This Repository to GitHub

When you are ready to submit your project to GitHub:

```powershell
# 1. Initialize git (if not already initialized)
git status

# 2. Stage all project files (ignoring .venv and build artifacts via .gitignore)
git add .

# 3. Create your initial commit
git commit -m "feat: complete ClearPath ambulance proximity alert system MVP"

# 4. Link your remote GitHub repository (replace with your GitHub repository URL)
git remote add origin https://github.com/<YOUR_GITHUB_USERNAME>/ClearPath.git

# 5. Rename branch to main
git branch -M main

# 6. Push code to GitHub
git push -u origin main
```

---

## 📄 License & Attribution
Created for the Social Impact Innovation Hackathon. Licensed under the MIT License.
