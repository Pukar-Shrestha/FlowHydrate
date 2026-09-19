# 💧 FlowHydrate

**Focus deeply. Drink consistently.**

FlowHydrate is a wellness companion app for iOS that seamlessly combines a **Focus Timer** (Pomodoro technique) with a **Hydration Tracker**. Build productive habits while staying hydrated — all in one beautifully designed app.

Built with Swift 6, SwiftUI, and SwiftData for iOS 18+.

---

## 📸 Screenshots

<!-- Add screenshots here -->
<!-- ![Home Screen](screenshots/home.png) -->
<!-- ![Focus Timer](screenshots/timer.png) -->
<!-- ![Hydration Tracker](screenshots/hydration.png) -->
<!-- ![Statistics](screenshots/stats.png) -->

---

## ✨ Features

### 🧠 Focus Timer
- Full **Pomodoro technique** implementation with focus, short break, and long break cycles
- **Customizable durations** for each session type
- Automatic session cycling with long breaks every 4 focus sessions
- **Background timer support** — keeps running when the app is backgrounded
- Live countdown with animated circular progress ring

### 💧 Hydration Tracker
- **Quick-add** buttons for common amounts (100, 250, 500, 750 mL)
- Custom amount entry for precise logging
- Configurable **daily water goal** with progress tracking
- Unit support for **milliliters and ounces**
- Beautiful wave animation showing fill level

### 📊 Statistics
- **Daily, weekly, and monthly** views with interactive Swift Charts
- Focus minutes and hydration intake visualizations
- Goal completion tracking over time
- Session history with detailed breakdowns

### 🔥 Streak System
- Independent **focus**, **hydration**, and **combined** streak tracking
- Milestone celebrations at **3, 7, 30, and 100 days**
- Animated celebration effects when milestones are reached
- Visual streak badges in the dashboard

### 📱 Widgets
- **Small widget** — current streak and next timer at a glance
- **Medium widget** — today's focus and hydration progress side-by-side
- **Lock Screen widgets** — compact circular progress indicators

### 🏝️ Live Activities
- **Dynamic Island** — live timer countdown during focus sessions
- **Lock Screen Live Activity** — expanded timer view with session details

### ❤️ HealthKit Integration
- Automatic **water intake sync** to Apple Health
- Permission-based opt-in with clear privacy explanations
- Respects user health data preferences

### ♿ Accessibility
- Full **VoiceOver** support with descriptive labels, hints, and values
- **Dynamic Type** support — all text scales with system preferences
- **Reduce Motion** support — animations gracefully degrade
- High-contrast adaptive colors for Dark and Light mode

---

## 📋 Requirements

| Requirement | Version |
|-------------|---------|
| iOS | 18.0+ |
| Xcode | 16.0+ |
| Swift | 6 |

---

## 🚀 Setup Instructions

### 1. Get the Source Code

```bash
git clone <repository-url>
cd FlowHydrate
```

Or download and extract the ZIP archive.

### 2. Create the Xcode Project

1. Open **Xcode 16+**
2. Select **File → New → Project**
3. Choose **iOS → App**
4. Configure:
   - **Product Name**: `FlowHydrate`
   - **Organization Identifier**: `com.flowhydrate`
   - **Interface**: SwiftUI
   - **Storage**: SwiftData
   - **Language**: Swift
5. Click **Create**

### 3. Add Source Files

Copy the source files from this repository into the corresponding groups in your Xcode project:

```
FlowHydrate/
├── Models/          → Add to FlowHydrate target
├── ViewModels/      → Add to FlowHydrate target
├── Views/           → Add to FlowHydrate target
├── Utilities/       → Add to FlowHydrate target
├── Shared/          → Add to both FlowHydrate and Widget targets
└── FlowHydrateTests/ → Add to test target
```

### 4. Add Widget Extension

1. Select **File → New → Target**
2. Choose **iOS → Widget Extension**
3. Name it **FlowHydrateWidget**
4. Check **Include Live Activity** if prompted
5. Click **Finish**

### 5. Configure App Group

Both the main app and widget extension need a shared App Group:

1. Select the **FlowHydrate** target → **Signing & Capabilities**
2. Click **+ Capability** → **App Groups**
3. Add: `group.com.flowhydrate.shared`
4. Repeat for the **FlowHydrateWidget** target

### 6. Enable Capabilities

On the **FlowHydrate** main target:

| Capability | Notes |
|-----------|-------|
| **HealthKit** | Enable "Health Records" if needed |
| **Background Modes** | Check "Background processing" |
| **Push Notifications** | For hydration reminders |

### 7. Configure Info.plist

Add the following keys to your `Info.plist`:

```xml
<key>NSHealthShareUsageDescription</key>
<string>FlowHydrate reads your health data to show hydration trends.</string>
<key>NSHealthUpdateUsageDescription</key>
<string>FlowHydrate saves your water intake to Apple Health.</string>
```

### 8. Build and Run

Select your target device or simulator and press **⌘R**.

---

## 🏗️ Architecture

FlowHydrate follows the **MVVM** (Model-View-ViewModel) pattern using Swift's modern concurrency and observation frameworks.

```
┌─────────────────────────────────────────┐
│                  Views                   │
│  (SwiftUI views with @Environment)       │
├─────────────────────────────────────────┤
│              ViewModels                  │
│  (@Observable classes with business      │
│   logic and state management)            │
├─────────────────────────────────────────┤
│                Models                    │
│  (@Model classes persisted with          │
│   SwiftData)                             │
├─────────────────────────────────────────┤
│              Services                    │
│  (HealthKit, Notifications, Widgets)     │
└─────────────────────────────────────────┘
```

### Key Patterns

- **@Observable** (Observation framework) for reactive view models
- **SwiftData** with `@Model` for type-safe persistence
- **@Environment(\.modelContext)** for dependency injection in views
- **App Group** shared container for widget data access
- **Swift 6 concurrency** with `Sendable` conformance

---

## 📁 Project Structure

```
FlowHydrate/
├── FlowHydrate/
│   ├── FlowHydrateApp.swift            # App entry point
│   ├── ContentView.swift               # Root tab view
│   │
│   ├── Models/
│   │   ├── TimerMode.swift             # Focus/break mode enum
│   │   ├── TimerState.swift            # Idle/running/paused enum
│   │   ├── VolumeUnit.swift            # mL/oz enum
│   │   ├── AppearanceMode.swift        # System/light/dark enum
│   │   ├── FocusSession.swift          # Focus session data model
│   │   ├── WaterLog.swift              # Water log entry model
│   │   ├── DailyRecord.swift           # Daily aggregated record
│   │   └── UserSettings.swift          # App settings model
│   │
│   ├── ViewModels/
│   │   ├── FocusTimerViewModel.swift    # Timer logic & state
│   │   ├── HydrationViewModel.swift     # Water tracking logic
│   │   └── StreakViewModel.swift         # Streak calculations
│   │
│   ├── Views/
│   │   ├── Dashboard/
│   │   │   └── DashboardView.swift      # Main dashboard
│   │   ├── Focus/
│   │   │   ├── FocusTimerView.swift      # Timer interface
│   │   │   └── TimerRingView.swift       # Animated ring
│   │   ├── Hydration/
│   │   │   ├── HydrationView.swift       # Water tracker
│   │   │   └── WaveView.swift            # Wave animation
│   │   ├── Statistics/
│   │   │   └── StatisticsView.swift      # Charts & history
│   │   ├── Streaks/
│   │   │   └── StreakView.swift           # Streak display
│   │   └── Settings/
│   │       └── SettingsView.swift        # App settings
│   │
│   ├── Utilities/
│   │   ├── HealthKitManager.swift       # HealthKit integration
│   │   ├── NotificationManager.swift    # Local notifications
│   │   └── Extensions.swift             # Shared extensions
│   │
│   └── Shared/
│       └── SharedDefaults.swift         # App Group UserDefaults
│
├── FlowHydrateWidget/
│   ├── FlowHydrateWidget.swift          # Widget entry point
│   ├── FocusWidget.swift                # Focus timer widget
│   ├── HydrationWidget.swift            # Hydration widget
│   └── LiveActivity.swift               # Live Activity config
│
├── FlowHydrateTests/
│   ├── FocusTimerViewModelTests.swift   # Timer VM tests
│   ├── HydrationViewModelTests.swift    # Hydration VM tests
│   ├── StreakViewModelTests.swift        # Streak VM tests
│   └── MockData.swift                   # Sample data
│
└── README.md                            # This file
```

---

## 🎨 Customization

### Colors

The app uses semantic colors that adapt to Dark and Light mode. To customize the color palette:

1. Open `Assets.xcassets`
2. Modify the named color sets:
   - `FocusColor` — primary accent for focus mode (default: indigo)
   - `BreakColor` — accent for break modes (default: green)
   - `HydrationColor` — accent for water tracking (default: cyan)

### Timer Durations

Default durations can be changed in the app's Settings screen, or modify the defaults in `UserSettings.swift`:

```swift
var focusDuration: TimeInterval = 1500      // 25 minutes
var shortBreakDuration: TimeInterval = 300   // 5 minutes
var longBreakDuration: TimeInterval = 900    // 15 minutes
```

### Daily Water Goal

The default goal is **2500 mL** (approximately 84 oz). Users can change this in Settings, or modify the default in `UserSettings.swift`:

```swift
var dailyWaterGoal: Double = 2500  // in milliliters
```

### Quick-Add Amounts

To change the preset water amounts, modify `HydrationViewModel.swift`:

```swift
static let quickAmounts: [Double] = [100, 250, 500, 750]
```

---

## 📦 App Store Submission Checklist

Use this checklist when preparing FlowHydrate for App Store release:

### Privacy & Permissions
- [ ] HealthKit usage description in `Info.plist`
- [ ] Notification usage description
- [ ] App Privacy details configured in App Store Connect
- [ ] Review [HealthKit guidelines](https://developer.apple.com/documentation/healthkit) for App Review

### Testing
- [ ] Test on physical device (timer background behavior)
- [ ] Test widgets on physical device (all sizes)
- [ ] Test Live Activities on physical device (Dynamic Island + Lock Screen)
- [ ] Test HealthKit integration on physical device
- [ ] Test notifications (foreground, background, and scheduled)
- [ ] Test VoiceOver navigation flow
- [ ] Test Dynamic Type at all sizes (including accessibility sizes)
- [ ] Test Reduce Motion behavior
- [ ] Test with no data (empty state)
- [ ] Test data persistence across app restarts

### Release
- [ ] Archive and upload to App Store Connect
- [ ] Configure app metadata in App Store Connect
- [ ] Submit for review

---

## 📄 License

```
MIT License

Copyright (c) 2025 FlowHydrate

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
