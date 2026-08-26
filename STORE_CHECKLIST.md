# OneLoop UIv2 — App Store review checklist

UI/UX is the current scope. Cloud/database work comes later. Use this against
[App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/).

## Guideline map (this app)

| Guideline | How OneLoop UIv2 meets it |
|---|---|
| **1.4.1 Physical harm / medical** | Personal reminder only. Not a device, not diagnosis/treatment. First-launch disclaimer + Settings copy. No HealthKit, no sensor “measurements.” |
| **1.5 Developer information** | In-app Support (email + URL) in Settings. Public support page. |
| **1.6 / 5.1 Privacy** | In-app Privacy Policy + hosted URL. Local-first JSON. Cloud optional and called out in the disclaimer. |
| **2.1 Completeness** | Core flow works without an account (**Skip**). No IAP. Reviewer can: Add med → Mark taken → History. |
| **2.3 Metadata** | Name ≤ 30 chars (`OneLoop UIv2`). Screenshots must show the app in use (Today / Schedule / History), not only splash/login. |
| **2.3.5 Category** | Health & Fitness (reminder utility), not Medical. |
| **2.3.6 Age rating** | Answer honestly; 4+ is typical. No “For Kids.” |
| **2.5.1 Public APIs** | SwiftUI, UserNotifications, WidgetKit, App Groups. |
| **2.5.16 Widgets** | Widget shows next dose / progress from this app only. |
| **4.2 Minimum functionality** | Scheduling, reminders, history, widgets — not a thin website wrapper. |
| **4.5 Apple trademarks** | No Apple product names in the app name. |
| **4.8 Sign in with Apple** | Alpha/internal: Google is on for testing. Apple is visible but disabled. Before App Store submit, ship Sign in with Apple or hide Google (4.8). |
| **5.1.1 Privacy policy** | Required URL in App Store Connect + in-app legal screens. |
| **5.1.3 Health** | No HealthKit. User-entered schedules only. No sharing health data with advertisers. |
| Export compliance | `ITSAppUsesNonExemptEncryption = NO` (standard HTTPS only). |

## Before upload

1. **Public legal/support pages**  
   - Home: https://dcsvisuals.github.io/OneLoop-MedicationTracker-PrivacyPolicy/  
   - Privacy: `…/privacy/`  
   - Support: `…/support/`  
   - Wired in `AppInfo.swift`  
   - Use a real inbox in `AppInfo.supportEmail` if `support@oneloop.app` is not yours  

2. **App Store Connect**
   - Bundle ID: `com.davidcarranco.oneloop.medtracker.uiv2`  
   - App Group: `group.com.davidcarranco.oneloop.medtracker.uiv2` (app + widget)  
   - Privacy Policy URL and Support URL  
   - Screenshots of **Today, Schedule, History** (not splash/login only)  
   - Age rating questionnaire  
   - App Privacy nutrition labels: on-device medication schedule; optional account email if they sign in later  
   - Export compliance: standard encryption only  

3. **Device QA**
   - First-launch disclaimer; Continue stays disabled until the toggle  
   - Skip sign-in; add / edit / remove medication  
   - Notifications: allow, deny, Open Settings  
   - History after removing a medication  
   - Widget  
   - Light / dark  
   - Floating capsule and Liquid Glass (iOS 26+)  

4. **Review notes** (paste into App Store Connect)

   > Personal medication **reminder** utility — not a medical device and not for diagnosis or treatment. A medical disclaimer is required on first launch (toggle + Continue) and remains in Settings.  
   >  
   > **No account required.** Use Skip on the sign-in screen. Sample: Add medication → Mark taken → History. Enable notifications in Settings to test reminders.  
   >  
   > Cloud backup is optional and not required for review. Social login is not offered in this build.

5. **Archive & submit**
   - Product → Archive (Release, Any iOS Device)  
   - Distribute to App Store Connect  
