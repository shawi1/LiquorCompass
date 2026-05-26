# LiquorCompass

A minimal SwiftUI iOS app: a compass needle that points to the nearest liquor
store, with distance shown below. Built to look at home next to Apple's own
Compass and Find My apps.

![Style: SwiftUI](https://img.shields.io/badge/style-SwiftUI-orange)
![iOS 17+](https://img.shields.io/badge/iOS-17%2B-blue)

## Features

- Live compass dial with tick marks every 5°, cardinal letters, and a
  north-tinted accent
- Red/white needle that points to the nearest liquor store relative to the
  phone's current heading
- Distance shown in large, locale-aware units (ft/mi or m/km)
- Re-searches automatically when you move more than 250 m
- Graceful permission overlay when location access is denied

## How it works

`LocationManager` publishes the user's `CLLocation` and device heading.
`LiquorStoreFinder` queries Apple Maps (`MKLocalSearch`) for "liquor store"
within a 20 km region and keeps the closest result. `ContentView` computes the
bearing from user → store and rotates the needle by `bearing − heading` so it
always points at the store, regardless of which way the phone is facing.

## Build

Requirements: macOS 15+, Xcode 16+ (Xcode 26 if on macOS 26 Tahoe).

```bash
# Open in Xcode
open LiquorCompass.xcodeproj
```

Then pick a simulator or device and Run.

> The simulator has no magnetometer, so the compass dial won't rotate, but the
> needle direction is still correct relative to North. Use a physical device
> for the full experience.

## Regenerate the Xcode project

The project is generated from `project.yml` via
[XcodeGen](https://github.com/yonaskolb/XcodeGen):

```bash
brew install xcodegen
xcodegen generate
```

## Project structure

```
LiquorCompass/
├── project.yml                     # XcodeGen spec
├── LiquorCompass.xcodeproj/        # Generated project
└── LiquorCompass/
    ├── LiquorCompassApp.swift      # App entry
    ├── ContentView.swift           # Compass UI
    ├── LocationManager.swift       # CLLocationManager wrapper
    ├── LiquorStoreFinder.swift     # MKLocalSearch wrapper
    ├── Assets.xcassets/            # Accent color + app icon
    └── Preview Content/
```

## License

MIT
