# Fix Google sign-in redirect (deploy this once)

## What was wrong

After Google login, Supabase was sending you to your **Site URL**
(`dcsvisuals.github.io` homepage) instead of back into the app.
The in-app browser stayed open on the website, so OneLoop never received
the auth tokens and never left the carousel.

## Fix: HTTPS → app bridge page

### 1. Deploy the bridge page

Copy `docs/auth-callback/index.html` into your **privacy/support GitHub Pages repo** so it is live at:

```text
https://dcsvisuals.github.io/OneLoop-MedicationTracker-PrivacyPolicy/auth-callback/
```

(or `/auth-callback/index.html` — both work with GitHub Pages)

### 2. Supabase → Authentication → URL Configuration

**Site URL** (recommended):

```text
https://dcsvisuals.github.io/OneLoop-MedicationTracker-PrivacyPolicy/auth-callback/
```

**Redirect URLs** (add all of these):

```text
https://dcsvisuals.github.io/OneLoop-MedicationTracker-PrivacyPolicy/auth-callback/
https://dcsvisuals.github.io/OneLoop-MedicationTracker-PrivacyPolicy/**
oneloop://auth-callback
oneloop://**
```

Save.

### 3. How the flow works now

```text
App → Google → Supabase
  → https://…/auth-callback/?code=…
  → oneloop://auth-callback?code=…   (JS redirect)
  → browser closes, app signs you in, Today opens
```

### 4. Rebuild & test OneLoop

The iOS app already points OAuth `redirectTo` at the HTTPS bridge URL.
