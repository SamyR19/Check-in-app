# Spots — Check-in App (SwiftUI)

A native iOS check-in app frontend built with SwiftUI. Track the places you go, save spots you love, and see where your friends are checking in.

**Frontend only** — all data is mocked in `CheckIn/Models.swift` (`MockData`). No Supabase / backend is wired up yet.

## Running it

1. Open `CheckIn.xcodeproj` in **Xcode 16+**
2. Pick an iPhone simulator (iOS 17+)
3. ⌘R

## What's inside

| Screen | Highlights |
| --- | --- |
| **Explore** | Greeting header, search, category chips, nearby spot rail, popular list, floating lime **Map** pill |
| **Map** | Full-screen MapKit map with emoji spot markers, filter pills (All / Saved / Nearby), tap-to-preview card |
| **Saved** | Animated gradient progress bar toward a savings goal, curated lists, all saved spots |
| **Activity** | Event countdown hero card, friends' check-in feed grouped by day, live pulse indicator |
| **Profile** | Animated progress ring avatar, stats, badge grid, settings |
| **Check in (+)** | Spot picker, mood picker, note, springy success burst |

## Design system

- Custom **floating bottom navigation bar** with a sliding lime pill (`matchedGeometryEffect`), bouncing SF Symbols, haptics, and a center check-in button
- Warm paper canvas (`#F6F4EF`), ink black, lime + sky accents, rounded SF typography
- Subtle animations throughout: staggered fade-up entrances, scroll transitions, squishy press states, animated progress bars and rings

## Structure

```
CheckIn/
├── CheckInApp.swift        # App entry
├── RootView.swift          # Tab switching + check-in sheet
├── Theme.swift             # Colors, fonts, haptics, shared modifiers
├── Models.swift            # Models, mock data, observable AppModel
├── Components/
│   ├── FloatingTabBar.swift
│   └── SpotViews.swift     # Cards, rows, chips, section headers
└── Views/
    ├── ExploreView.swift
    ├── MapExploreView.swift
    ├── SavedView.swift
    ├── ActivityView.swift
    ├── ProfileView.swift
    └── CheckInSheet.swift
```
