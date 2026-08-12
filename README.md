# OneLoop — Medication Tracker (iOS)

OneLoop is a personal iOS medication reminder and schedule app built with **SwiftUI**.

> **Disclaimer:** OneLoop is a personal organization tool. It is **not** a medical device and does not provide medical advice, diagnosis, or treatment.

## Features

- Today dashboard with dose adherence
- Flexible schedules (including staged dose changes)
- Local notifications and snooze
- History that persists after a medication is removed
- Home Screen / Lock Screen widgets
- Floating capsule navigation or system Liquid Glass tab bar (iOS 26+)
- First-launch medical disclaimer, privacy policy, and support links

## Requirements

- Xcode 26+ (recommended)
- iOS 26.5+ deployment target (as currently configured)
- Apple Developer team + App Group for widgets:
  - `group.com.davidcarranco.oneloop.medtracker`

## Open in Xcode

1. Clone this repository
2. Open `OneLoop.xcodeproj`
3. Select the **OneLoop** scheme
4. Build and run on a simulator or device

## Project structure

```
OneLoop/                 # Main app sources
OneLoopWidgets/          # Widget extension
OneLoop.xcodeproj        # Xcode project
STORE_CHECKLIST.md       # App Store submission notes
```

## Configuration

Update support/privacy URLs and email in:

- `OneLoop/AppInfo.swift`

Register the App Group for both the app and widget targets in your Apple Developer account before shipping widgets.

## License

This project is licensed under the [MIT License](LICENSE).

## Author

David Carranco — [DCSvisuals](https://github.com/DCSvisuals)
