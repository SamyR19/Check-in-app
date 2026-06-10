# I'm Good — Check-in App (SwiftUI)

A native iOS app that turns "trust me" into a live feed of proof. Agreed check-in times → one tap says "I'm good" → location + battery attach automatically → your family sees a green board. Miss one and the app nudges before anyone worries.

**Frontend only** — no Supabase/Twilio yet. All state is persisted locally to a JSON file (`Store.swift`), so check-ins, expenses, recaps, and your account survive relaunches. Location (CoreLocation) and battery level are real.

## Running it

1. Open `CheckIn.xcodeproj` in **Xcode 16+**
2. Pick an iPhone simulator or device (iOS 17+)
3. ⌘R — onboarding runs on first launch ("Reset app" in Profile brings it back)

## The core loop

| Piece | Where |
| --- | --- |
| Scheduled check-ins, one-tap confirm, auto-attach 📍 + 🔋 + 🕐 | Center tab-bar button → `CheckInSheet` |
| Due-state escalation UI (amber pulse, "Check-in due" hero) | `HomeView` + tab bar |
| On-demand location ping with one-tap approve | `HomeView` ping card |
| Battery + last-seen status board for the whole family | `HomeView` family board |
| Hold-to-activate SOS → circle alerted, 112 + consulate | `SOSView` |

Tier 2 polish included: daily recap composer (`ActivityView`), live itinerary with "currently here" marker and spend tracker (`PlanView`).

## Screens

- **Onboarding** — welcome card grid → create account → pick your circle → check-in schedule → permissions (location/notifications) → "Finishing setup"
- **Home** — status hero with mini-map of last check-in, ping requests, family board, SOS
- **Trip** — itinerary timeline + budget-vs-actual spend tracker with add-expense sheet
- **Activity** — recap composer + proof feed (check-ins, pings, SOS, recaps)
- **Profile** — stats, check-in times, your circle, settings, reset
- **Search** — live search across family, itinerary, and history with persisted recents

## Design system

- Custom **floating bottom nav** with sliding lime pill (`matchedGeometryEffect`); center check-in button pulses amber when a check-in is due
- Warm paper canvas (`#F6F4EF`), ink black, lime/sky/amber accents, true red reserved for SOS
- Subtle animations: staggered entrances, squishy press states, animated progress bars, hold-to-SOS ring, success bursts, haptics throughout

## Structure

```
CheckIn/
├── CheckInApp.swift        # Entry: onboarding vs main app
├── RootView.swift          # Tabs + check-in sheet
├── Theme.swift             # Colors, fonts, haptics, shared modifiers
├── Models.swift            # Domain models + seed data
├── Store.swift             # Observable state + local JSON persistence
├── Services.swift          # CoreLocation, battery, notifications
├── Components/             # FloatingTabBar, shared cards/buttons/fields
├── Onboarding/             # Flow container + steps
└── Views/                  # Home, Plan, Activity, Profile, CheckInSheet, SOS, Search
```

## Not wired up yet (by design)

Supabase (auth, realtime board sync), Twilio SMS escalation, push notification scheduling, the parent web dashboard. The local `Store` mirrors the planned `users` / `checkins` / `ping_requests` / `alerts` tables so swapping in Supabase later is mechanical.
