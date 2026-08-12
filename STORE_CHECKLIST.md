# OneLoop — App Store submission checklist

In-app legal, privacy, support, and build polish are implemented.
Use this list for the remaining external steps.

## Before upload

1. **Host a privacy policy** at a public HTTPS URL  
   - Draft text is in the app (`Settings → Privacy Policy`) and `AppInfo.privacyPolicyFull`  
   - Update `AppInfo.privacyPolicyURL` and `AppInfo.supportURL` to your real links  
   - Update `AppInfo.supportEmail` if needed  

2. **App Store Connect**
   - Create the app with bundle ID `com.davidcarranco.oneloop.medtracker`
   - Register App Group `group.com.davidcarranco.oneloop.medtracker` for app + widget
   - Privacy Policy URL (required for listing)
   - Support URL
   - Screenshots (required device sizes)
   - Age rating questionnaire
   - App Privacy nutrition labels (on-device medication schedule data)
   - Export compliance: uses standard encryption only (project sets `ITSAppUsesNonExemptEncryption = NO`)

3. **Device QA**
   - First launch disclaimer gate
   - Add / edit / remove medication
   - Notifications grant, deny, and Open Settings path
   - History after medication removal
   - Widget update
   - Light / dark mode
   - Both navigation modes

4. **Archive & submit**
   - Product → Archive (Release, real device / Any iOS Device)
   - Distribute to App Store Connect
   - Submit for review with notes, e.g.  
     “Personal medication reminder. No account. Enable notifications in Settings to test reminders. Sample flow: Add medication → Mark taken → History.”

## Reviewer notes tip

Mention that the app is a **personal reminder utility**, not a medical device, and that a medical disclaimer is shown on first launch and in Settings.
