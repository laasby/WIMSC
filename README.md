# WIMSC — Tesla Supercharger Explorer

A native iOS 17+ app for discovering, evaluating, and navigating to Tesla Superchargers worldwide, with first-class Nordic support.

## Features

- **Map view** — Interactive MapKit map with V2/V3/V4 colour-coded pins (colorblind-safe), clustering, range ring overlay
- **List view** — Sortable/filterable list with distance, stall count, kW, Magic Dock badge
- **Detail view** — Full site info: pricing, amenities, weather (MET Norway), cold-soak warning, preconditioning advisor, live availability, dwell-time planner
- **Trip planner** — Route between two points, Supercharger corridor overlay, recommended stops
- **Nordic features** — Vegvesen mountain pass status, NO1–NO5 spot prices, home-vs-Supercharger arbitrage
- **Visit history** — Manual session logging, year-over-year cost dashboard, stall reliability tracking
- **Multi-vehicle** — Add your Teslas (KALM3, LAAMY, …) with per-vehicle range and charge estimates
- **Privacy-first** — No analytics, no ads, all data on-device; opt-in iCloud sync via CloudKit
- **Offline-first** — Bundled site database, delta sync when online

## Architecture

```
WIMSC.xcodeproj
├── WIMSC/           Host app (SwiftUI @main, ContentView, WIMSCApp)
├── WIMSCWidgets/    WidgetKit extension (Live Activity, Nearest SC widget)
├── WIMSCUITests/    XCTest UI tests
└── Packages/
    ├── SCData/      Data layer: SwiftData models, networking, sync, location
    ├── SCDomain/    Business logic: filtering, range, trip planning, forensics
    ├── SCUI/        SwiftUI views and components
    └── SCTests/     Swift Testing unit tests
```

## Setup

1. Clone the repo and open `WIMSC.xcodeproj` in Xcode 16+
2. Select the `WIMSC` scheme and an iOS 17+ simulator
3. Build and run — the app works offline with bundled seed data

### Optional API keys

Create `WIMSC/Secrets.swift` (gitignored) with:
```swift
enum Secrets {
    static let tibberToken: String? = "YOUR_TIBBER_TOKEN"
}
```

- **Tibber token** — for real-time NO1–NO5 spot prices (free at tibber.com/developer)
- No other API keys required; all other data sources are open

### iCloud sync

To enable CloudKit sync in development:
1. Add the `iCloud` capability in Xcode → Signing & Capabilities
2. Enable `CloudKit` and add container `iCloud.com.laasby.wimsc`
3. The toggle in Settings → Privacy & Sync will then work

## Data Sources

| Source | Use |
|---|---|
| [supercharge.info](https://supercharge.info) | Primary Supercharger database |
| Tesla Find Us | Secondary cross-reference |
| [MET Norway Locationforecast 2.0](https://api.met.no) | Weather (attribution required) |
| [Vegvesen](https://www.vegvesen.no) | Norwegian road & pass status |
| [Tibber API](https://developer.tibber.com) | NO1–NO5 spot electricity prices |

## Running tests

```bash
# Unit tests (Swift Testing)
cd Packages/SCTests && swift test

# UI tests
xcodebuild test \
  -project WIMSC.xcodeproj \
  -scheme WIMSC \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest'
```

## Privacy

- No third-party analytics SDKs
- No advertising identifiers
- Location requested only when Map or List view opens
- Tesla OAuth tokens stored in Keychain only
- All user data on-device by default; iCloud sync is opt-in
- See Settings → Your Data for a full breakdown and one-tap JSON export
