import Foundation
import CoreLocation

// MARK: - Domain models (all Codable for local persistence)

struct UserProfile: Codable, Equatable {
    var name: String
    var email: String

    var initials: String {
        name.split(separator: " ").prefix(2).compactMap(\.first).map(String.init).joined()
    }
}

struct ParentContact: Codable, Identifiable, Equatable {
    var id = UUID()
    var name: String
    var relation: String
    var emoji: String
}

struct ScheduledCheckIn: Codable, Identifiable, Equatable {
    var id = UUID()
    var label: String
    var hour: Int
    var minute: Int
    var isEnabled: Bool

    func dateToday(_ calendar: Calendar = .current, base: Date = .now) -> Date? {
        calendar.date(bySettingHour: hour, minute: minute, second: 0, of: base)
    }

    var timeString: String {
        guard let date = dateToday() else { return "--:--" }
        return date.formatted(date: .omitted, time: .shortened)
    }
}

enum CheckInStatus: String, Codable {
    case onTime, late, missed
}

struct CheckInRecord: Codable, Identifiable {
    var id = UUID()
    var date: Date
    var latitude: Double?
    var longitude: Double?
    var battery: Int
    var status: CheckInStatus
    var mood: String
    var note: String

    var coordinate: CLLocationCoordinate2D? {
        guard let latitude, let longitude else { return nil }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var coordinateString: String {
        guard let latitude, let longitude else { return "No location" }
        return String(format: "%.4f, %.4f", latitude, longitude)
    }
}

struct ItineraryStop: Codable, Identifiable {
    var id = UUID()
    var city: String
    var country: String
    var emoji: String
    var dates: String
    var isCurrent: Bool
}

struct Expense: Codable, Identifiable {
    var id = UUID()
    var title: String
    var emoji: String
    var amount: Double
    var date: Date
}

enum MemberStatus: String, Codable {
    case good, due, alert
}

struct FamilyMember: Codable, Identifiable {
    var id = UUID()
    var name: String
    var emoji: String
    var role: String
    var battery: Int
    var lastSeenMinutes: Int
    var status: MemberStatus
    var isMe: Bool

    var lastSeenString: String {
        lastSeenMinutes <= 1 ? "now" : "\(lastSeenMinutes)m ago"
    }
}

struct PingRequest: Codable, Identifiable {
    var id = UUID()
    var fromName: String
    var sentMinutesAgo: Int
    var isApproved: Bool
}

enum EventKind: String, Codable {
    case checkIn, missed, ping, sos, recap

    var emoji: String {
        switch self {
        case .checkIn: "✅"
        case .missed: "⚠️"
        case .ping: "📍"
        case .sos: "🆘"
        case .recap: "📸"
        }
    }
}

struct ActivityEvent: Codable, Identifiable {
    var id = UUID()
    var kind: EventKind
    var title: String
    var detail: String
    var date: Date
}

// MARK: - Seed data (demo content for first launch — no backend)

enum Seed {
    static let parents: [ParentContact] = [
        ParentContact(name: "Mom", relation: "Parent", emoji: "🌸"),
        ParentContact(name: "Dad", relation: "Parent", emoji: "🧢"),
    ]

    static let schedule: [ScheduledCheckIn] = [
        ScheduledCheckIn(label: "Morning", hour: 9, minute: 0, isEnabled: true),
        ScheduledCheckIn(label: "Afternoon", hour: 15, minute: 0, isEnabled: true),
        ScheduledCheckIn(label: "Evening", hour: 21, minute: 0, isEnabled: true),
    ]

    static let stops: [ItineraryStop] = [
        ItineraryStop(city: "Lisbon", country: "Portugal", emoji: "🚋", dates: "Jun 7 – 12", isCurrent: true),
        ItineraryStop(city: "Seville", country: "Spain", emoji: "🍊", dates: "Jun 12 – 16", isCurrent: false),
        ItineraryStop(city: "Madrid", country: "Spain", emoji: "🖼️", dates: "Jun 16 – 20", isCurrent: false),
        ItineraryStop(city: "Barcelona", country: "Spain", emoji: "🏖️", dates: "Jun 20 – 25", isCurrent: false),
    ]

    static let expenses: [Expense] = [
        Expense(title: "Hostel · 2 nights", emoji: "🛏️", amount: 84, date: .now.addingTimeInterval(-86400 * 2)),
        Expense(title: "Pastéis de nata run", emoji: "🥧", amount: 9.5, date: .now.addingTimeInterval(-86400)),
        Expense(title: "Tram day pass", emoji: "🚋", amount: 6.8, date: .now.addingTimeInterval(-3600 * 5)),
    ]

    static func family(meName: String) -> [FamilyMember] {
        [
            FamilyMember(name: meName, emoji: "🎒", role: "Traveling", battery: 100,
                         lastSeenMinutes: 0, status: .good, isMe: true),
            FamilyMember(name: "Mom", emoji: "🌸", role: "Home", battery: 64,
                         lastSeenMinutes: 4, status: .good, isMe: false),
            FamilyMember(name: "Dad", emoji: "🧢", role: "Home", battery: 41,
                         lastSeenMinutes: 18, status: .good, isMe: false),
        ]
    }

    static let pings: [PingRequest] = [
        PingRequest(fromName: "Mom", sentMinutesAgo: 12, isApproved: false),
    ]

    static let records: [CheckInRecord] = [
        CheckInRecord(date: .now.addingTimeInterval(-3600 * 20), latitude: 38.7223, longitude: -9.1393,
                      battery: 81, status: .onTime, mood: "😌", note: "Back at the hostel"),
        CheckInRecord(date: .now.addingTimeInterval(-3600 * 26), latitude: 38.7139, longitude: -9.1334,
                      battery: 54, status: .onTime, mood: "🤩", note: "Alfama viewpoint"),
    ]

    static let events: [ActivityEvent] = [
        ActivityEvent(kind: .checkIn, title: "Evening check-in", detail: "On time · 📍 attached · 🔋 81%",
                      date: .now.addingTimeInterval(-3600 * 20)),
        ActivityEvent(kind: .recap, title: "Daily recap sent", detail: "“Climbed every hill in Lisbon. Worth it.”",
                      date: .now.addingTimeInterval(-3600 * 22)),
        ActivityEvent(kind: .ping, title: "Location shared with Dad", detail: "Approved in 1 tap",
                      date: .now.addingTimeInterval(-3600 * 30)),
    ]
}
