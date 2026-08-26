# OneLoop UIv2 — Medication Tracker (iOS)

OneLoop UIv2 is a personal iOS medication reminder and schedule app built with **SwiftUI**.

> **Disclaimer:** OneLoop UIv2 is a personal organization tool. It is **not** a medical device and does not provide medical advice, diagnosis, or treatment.

This repository’s **main** branch is the UIv2 redesign. The previous app is kept on the **`legacy-v1`** branch.

## Features

- Today dashboard with dose adherence
- Flexible schedules (including staged dose changes)
- Local notifications and snooze
- History that persists after a medication is removed
- Home Screen / Lock Screen widgets
- Floating capsule navigation or system Liquid Glass tab bar (iOS 26+)
- First-launch medical disclaimer, privacy policy, and support links
- Optional account (email, Google) — **Skip** to use the app without signing in

## Requirements

- Xcode 26+ (recommended)
- iOS 18.6+ deployment target (as currently configured)
- Apple Developer team + App Group for widgets:
  - `group.com.davidcarranco.oneloop.medtracker.uiv2`

## Open in Xcode

1. Clone this repository
2. Open `OneLoopUIv2.xcodeproj`
3. Select the **OneLoopUIv2** scheme
4. Build and run on a simulator or device

## Project structure

```
OneLoopUIv2/                 # Main app sources
OneLoopUIv2Widgets/          # Widget extension
OneLoopUIv2.xcodeproj        # Xcode project
STORE_CHECKLIST.md           # App Store submission notes
```

## Configuration

Update support/privacy URLs and email in:

- `OneLoopUIv2/AppInfo.swift`

### Supabase (optional cloud sync)

See **`SUPABASE_STEP5_IOS.md`** for full steps.

1. Add SPM package: `https://github.com/supabase/supabase-swift` → product **Supabase**
2. Set URL + publishable key in `OneLoopUIv2/SupabaseConfig.swift`
3. Allow redirect URL `oneloopuiv2://auth-callback` in Supabase Auth

Register the App Group for both the app and widget targets in your Apple Developer account before shipping widgets.

## License

Copyright (c) 2026 David Carranco. All rights reserved.

This project is **not** MIT-licensed. You may download and run it **only for personal testing and evaluation**. You may not use it commercially, modify it (except to build/run it yourself for testing), or distribute copies. See [LICENSE](LICENSE).

## Author

David Carranco — [DCSvisuals](https://github.com/DCSvisuals)
