import Foundation
import CoreLocation
import SwiftUI

// MARK: - Models

enum SpotCategory: String, CaseIterable, Identifiable {
    case all = "All"
    case coffee = "Coffee"
    case food = "Food"
    case bars = "Bars"
    case parks = "Parks"
    case music = "Music"

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .all: "✨"
        case .coffee: "☕️"
        case .food: "🍜"
        case .bars: "🍸"
        case .parks: "🌳"
        case .music: "🎶"
        }
    }

    var tint: Color {
        switch self {
        case .all: Theme.lime
        case .coffee: Color(hex: 0xD9A066)
        case .food: Color(hex: 0xFF8A5C)
        case .bars: Color(hex: 0xB18CFF)
        case .parks: Color(hex: 0x7ED98A)
        case .music: Color(hex: 0x6FC8FF)
        }
    }
}

struct Spot: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let category: SpotCategory
    let area: String
    let distance: String
    let rating: Double
    let latitude: Double
    let longitude: Double
    var isSaved: Bool = false

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

struct FriendCheckIn: Identifiable {
    let id = UUID()
    let friendName: String
    let avatarEmoji: String
    let spotName: String
    let mood: String
    let note: String
    let timeAgo: String
    let isToday: Bool
}

struct SpotList: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let emoji: String
    let saved: Int
    let tint: Color
}

struct Badge: Identifiable {
    let id = UUID()
    let name: String
    let emoji: String
    let earned: Bool
}

// MARK: - Mock data (frontend only — no backend wired up)

enum MockData {
    static let userName = "Samy"
    static let homeArea = "Queen Anne, Seattle"
    static let homeCoordinate = CLLocationCoordinate2D(latitude: 47.6324, longitude: -122.3574)

    static let spots: [Spot] = [
        Spot(name: "Salt & Straw", category: .food, area: "Queen Anne", distance: "0.3 mi", rating: 4.8,
             latitude: 47.6293, longitude: -122.3565, isSaved: true),
        Spot(name: "Nectar Lounge", category: .music, area: "Fremont", distance: "1.1 mi", rating: 4.5,
             latitude: 47.6497, longitude: -122.3520, isSaved: true),
        Spot(name: "Caffe Ladro", category: .coffee, area: "Queen Anne", distance: "0.2 mi", rating: 4.6,
             latitude: 47.6371, longitude: -122.3571),
        Spot(name: "Kerry Park", category: .parks, area: "Queen Anne", distance: "0.5 mi", rating: 4.9,
             latitude: 47.6295, longitude: -122.3599, isSaved: true),
        Spot(name: "The Masonry", category: .bars, area: "Lower QA", distance: "0.7 mi", rating: 4.4,
             latitude: 47.6254, longitude: -122.3563),
        Spot(name: "How to Cook a Wolf", category: .food, area: "Queen Anne", distance: "0.4 mi", rating: 4.7,
             latitude: 47.6379, longitude: -122.3566, isSaved: true),
        Spot(name: "Gas Works Park", category: .parks, area: "Wallingford", distance: "1.6 mi", rating: 4.8,
             latitude: 47.6456, longitude: -122.3344),
        Spot(name: "Anchorhead Coffee", category: .coffee, area: "Belltown", distance: "1.3 mi", rating: 4.7,
             latitude: 47.6157, longitude: -122.3413),
    ]

    static let nearby: [Spot] = Array(spots.prefix(5))

    static let checkIns: [FriendCheckIn] = [
        FriendCheckIn(friendName: "Maya", avatarEmoji: "🦊", spotName: "Salt & Straw",
                      mood: "🤤", note: "Honey lavender. No notes.", timeAgo: "12m", isToday: true),
        FriendCheckIn(friendName: "Jonas", avatarEmoji: "🐻", spotName: "Nectar Lounge",
                      mood: "🔥", note: "Show starts at 9 — come thru", timeAgo: "1h", isToday: true),
        FriendCheckIn(friendName: "Priya", avatarEmoji: "🦋", spotName: "Kerry Park",
                      mood: "🌅", note: "Golden hour delivered", timeAgo: "3h", isToday: true),
        FriendCheckIn(friendName: "Leo", avatarEmoji: "🐯", spotName: "The Masonry",
                      mood: "🍕", note: "Wood-fired everything", timeAgo: "1d", isToday: false),
        FriendCheckIn(friendName: "Ana", avatarEmoji: "🐬", spotName: "Anchorhead Coffee",
                      mood: "☕️", note: "Best flat white in town", timeAgo: "1d", isToday: false),
        FriendCheckIn(friendName: "Maya", avatarEmoji: "🦊", spotName: "Gas Works Park",
                      mood: "🪁", note: "Kite weather", timeAgo: "2d", isToday: false),
    ]

    static let lists: [SpotList] = [
        SpotList(title: "Date night", subtitle: "Dinner, drinks & a view", emoji: "🕯️", saved: 6, tint: Color(hex: 0xFFD9CE)),
        SpotList(title: "Coffee crawl", subtitle: "Every roaster worth the walk", emoji: "☕️", saved: 9, tint: Color(hex: 0xF1E3CD)),
        SpotList(title: "Out-of-towners", subtitle: "When friends visit Seattle", emoji: "🧭", saved: 12, tint: Color(hex: 0xD7ECFF)),
        SpotList(title: "Live music", subtitle: "Small rooms, big sound", emoji: "🎶", saved: 4, tint: Color(hex: 0xE5DCFF)),
    ]

    static let badges: [Badge] = [
        Badge(name: "First steps", emoji: "👟", earned: true),
        Badge(name: "Regular", emoji: "📍", earned: true),
        Badge(name: "Early bird", emoji: "🌅", earned: true),
        Badge(name: "Night owl", emoji: "🦉", earned: true),
        Badge(name: "Explorer", emoji: "🗺️", earned: false),
        Badge(name: "Streak ×30", emoji: "🔥", earned: false),
    ]
}

// MARK: - App-wide observable state

@Observable
final class AppModel {
    var spots: [Spot] = MockData.spots
    var totalCheckIns = 86
    var streakDays = 12

    var savedSpots: [Spot] { spots.filter(\.isSaved) }

    func toggleSaved(_ spot: Spot) {
        guard let index = spots.firstIndex(where: { $0.id == spot.id }) else { return }
        spots[index].isSaved.toggle()
    }

    func recordCheckIn() {
        totalCheckIns += 1
    }
}
