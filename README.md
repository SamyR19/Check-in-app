# I'm Good — Check-in App (SwiftUI)

A native iOS app that turns "trust me" into a live feed of proof. Agreed check-in times → one tap says "I'm good" → location + battery attach automatically → your family sees a green board. Miss one and the app nudges before anyone worries.

**Frontend only** — no Supabase/Twilio yet. All state is persisted locally to a JSON file (`Store.swift`), so accounts, check-ins, expenses, and recaps survive relaunches. Location (CoreLocation) and battery level are real; auth, pairing, and ping approval are local mocks shaped like the future backend.

## Running it

1. Open `CheckIn.xcodeproj` in **Xcode 16+**
2. Pick an iPhone simulator or device (iOS 17+)
3. ⌘R — onboarding runs on first launch ("Reset app" in Profile brings it back, which is also how you switch roles)

## Two roles, one app

### Teen flow
Sign up (email or mock Apple/Google) → "I'm traveling" → create the trip (name, dates, destination) → set the check-in schedule → **primed** permissions (friendly explainer before each OS prompt) → generate invite codes (short-lived, trip-bound, copy/share) → **dry run** (test check-in + test ping + simulated SOS, with haptics) → home.

### Parent flow
Sign up → "I'm a parent or guardian" → enter the 6-character pairing code (code-box UI) → **expectations screen**: what you'll see vs. what you won't (no 24/7 tracking, no silent pings) → primed notifications → land on the **dashboard** with a "send a test ping" prompt.

### Parent dashboard (mobile)
Same floating-nav shell as the teen app, parent-flavored:
- **Board** tab — every teen's status dot, battery, last-seen, last check-in with mini-map; other guardians on the same board (multi-teen, multi-parent group)
- Center button becomes **Ping** — pick a teen, request location, watch the simulated one-tap approval land
- **Trip** and **Activity** show the shared itinerary, spending, and proof feed

## The core loop

| Piece | Where |
| --- | --- |
| Scheduled check-ins, one-tap confirm, auto-attach 📍 + 🔋 + 🕐 | Center tab-bar button → `CheckInSheet` |
| Due-state escalation UI (amber pulse, "Check-in due" hero) | `HomeView` + tab bar |
| On-demand location ping with one-tap approve (both sides) | Teen: `HomeView` ping card · Parent: `PingSheet` |
| Battery + last-seen status board for the whole group | `HomeView` / `ParentHomeView` |
| Hold-to-activate SOS → circle alerted, 112 + consulate | `SOSView` |

Tier 2 polish included: daily recap composer (`ActivityView`), live itinerary with "currently here" marker and spend tracker (`PlanView`), search with persisted recents (`SearchView`).

## Design system

- Custom **floating bottom nav** with sliding lime pill (`matchedGeometryEffect`); role-aware center button (✓ check-in / 📍 ping), amber pulse when due
- Warm paper canvas (`#F6F4EF`), ink black, lime/sky/amber accents, true red reserved for SOS
- Subtle animations: staggered entrances, squishy press states, animated progress bars, hold-to-SOS ring, success bursts, haptics throughout

## Structure

```
CheckIn/
├── CheckInApp.swift        # Entry: onboarding vs main app
├── RootView.swift          # Role-aware tabs + center action sheet
├── Theme.swift             # Colors, fonts, haptics, shared modifiers
├── Models.swift            # Domain models + seed data
├── Store.swift             # Observable state + local JSON persistence
├── Services.swift          # CoreLocation, battery, notifications
├── Components/             # FloatingTabBar, shared cards/buttons/fields
├── Onboarding/
│   ├── OnboardingFlow.swift     # Branching container, welcome, finishing
│   ├── OnboardingSteps.swift    # Sign-up, role, trip, schedule, permissions
│   └── OnboardingPairing.swift  # Invites, dry run, pairing, expectations, alerts
└── Views/                  # Home, ParentHome+Ping, Plan, Activity, Profile, CheckInSheet, SOS, Search
```

## Not wired up yet (by design)

Supabase (auth, realtime board sync, invite validation), Twilio SMS escalation, push notification scheduling, real ping delivery between devices. The local `Store` mirrors the planned `users` / `checkins` / `ping_requests` / `alerts` tables so swapping in Supabase later is mechanical.
