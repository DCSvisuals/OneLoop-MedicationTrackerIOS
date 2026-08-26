# Step 5 — Connect OneLoop (iOS) to Supabase

Dashboard work (project, Auth, tables, RLS) is done.  
These are the **Xcode / app** steps.

## A. Add the Supabase Swift package

1. Open `OneLoopUIv2.xcodeproj` in Xcode  
2. **File → Add Package Dependencies…**  
3. URL:
   ```text
   https://github.com/supabase/supabase-swift
   ```
4. Dependency rule: **Up to Next Major Version** from `2.0.0` (or latest 2.x)  
5. Add product **`Supabase`** to the **OneLoop** app target (not only the widget)  
6. Finish  

## B. Paste your keys

Open `OneLoop/SupabaseConfig.swift` and set:

```swift
static let projectURLString = "https://YOUR_PROJECT_REF.supabase.co"
static let publishableKey = "sb_publishable_..."
```

Use **Project Settings → API**:

- Project URL  
- **Publishable** key only (never the secret key)

## C. Confirm Auth redirect URLs (Supabase)

**Authentication → URL Configuration → Redirect URLs** must include:

```text
oneloop://auth-callback
```

(Also keep your GitHub Pages URL if you want.)

The app already registers URL scheme **`oneloop`** via `OneLoop/Info.plist`.

## D. Google (you already enabled it)

In Google Cloud, the **Web** OAuth client redirect must be:

```text
https://YOUR_PROJECT_REF.supabase.co/auth/v1/callback
```

Same value Supabase shows for the Google provider.

## E. Build & try

1. Run the app on a **simulator or device**  
2. **Settings → Account & cloud sync**  
3. Try:
   - Email magic link, or  
   - Password sign-in / create account, or  
   - Continue with Google  
4. After sign-in:
   - **Upload medications to cloud**  
   - **Download medications from cloud**  

## F. What was added in code

| File | Role |
|------|------|
| `SupabaseConfig.swift` | URL + publishable key |
| `SupabaseManager.swift` | Auth + medication upload/download |
| `AccountSettingsSection.swift` | Settings UI |
| `MedicationStore.replaceAllMedications` | Apply cloud download locally |
| `Info.plist` | `oneloop://` deep link |

## G. Security reminders

- Local data still works offline without signing in  
- Cloud is **opt-in** (upload/download buttons)  
- RLS means only the signed-in user’s rows are accessible  
- Do not commit real keys to a **public** repo if you care about key rotation clutter (publishable is public-by-design; still better not to spam them). Prefer local-only config or xcconfig gitignored for production.

## Next (optional Step 6)

- Auto-sync after local changes  
- Sync `dose_logs` / history  
- Sign in with Apple  
- Account delete  
