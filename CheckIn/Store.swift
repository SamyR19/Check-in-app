import Foundation
import CoreLocation
import Observation

/// App-wide state with local JSON persistence — every mutation is saved to disk.
/// No backend: this is the "database" until Supabase is wired up.
@Observable
final class Store {
    var hasOnboarded = false
    var profile = UserProfile(name: "", email: "")
    var parents: [ParentContact] = []
    var schedule: [ScheduledCheckIn] = []
    var records: [CheckInRecord] = []
    var stops: [ItineraryStop] = []
    var expenses: [Expense] = []
    var budget: Double = 1200
    var family: [FamilyMember] = []
    var pings: [PingRequest] = []
    var events: [ActivityEvent] = []
    var recentSearches: [String] = []
    var streakDays = 5

    init() {
        load()
    }

    // MARK: - Derived state

    var currentStop: ItineraryStop? { stops.first(where: \.isCurrent) }

    var lastRecord: CheckInRecord? { records.max(by: { $0.date < $1.date }) }

    var spentTotal: Double { expenses.reduce(0) { $0 + $1.amount } }

    var pendingPing: PingRequest? { pings.first(where: { !$0.isApproved }) }

    /// The most recent slot today whose time has passed without a confirmation.
    var dueSlot: ScheduledCheckIn? {
        let now = Date.now
        let passed = schedule
            .filter(\.isEnabled)
            .compactMap { slot -> (ScheduledCheckIn, Date)? in
                guard let date = slot.dateToday(), date <= now else { return nil }
                return (slot, date)
            }
        guard let latest = passed.max(by: { $0.1 < $1.1 }) else { return nil }
        let confirmed = records.contains { $0.date >= latest.1 }
        return confirmed ? nil : latest.0
    }

    /// The next upcoming slot (today if still ahead, otherwise tomorrow's first).
    var nextSlot: (slot: ScheduledCheckIn, date: Date)? {
        let now = Date.now
        let enabled = schedule.filter(\.isEnabled)
        let upcoming = enabled
            .compactMap { slot -> (ScheduledCheckIn, Date)? in
                guard let date = slot.dateToday(), date > now else { return nil }
                return (slot, date)
            }
            .min(by: { $0.1 < $1.1 })
        if let upcoming { return upcoming }
        // Tomorrow's earliest slot
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now) ?? now
        return enabled
            .compactMap { slot -> (ScheduledCheckIn, Date)? in
                guard let date = slot.dateToday(base: tomorrow) else { return nil }
                return (slot, date)
            }
            .min(by: { $0.1 < $1.1 })
    }

    var nextSlotCountdown: String {
        guard let next = nextSlot else { return "No check-ins scheduled" }
        let minutes = max(0, Int(next.date.timeIntervalSinceNow / 60))
        let (h, m) = (minutes / 60, minutes % 60)
        return h > 0 ? "in \(h)h \(m)m" : "in \(m)m"
    }

    // MARK: - Mutations

    func completeOnboarding(profile: UserProfile, parents: [ParentContact], schedule: [ScheduledCheckIn]) {
        self.profile = profile
        self.parents = parents
        self.schedule = schedule
        self.family = Seed.family(meName: profile.name.split(separator: " ").first.map(String.init) ?? profile.name)
        hasOnboarded = true
        save()
    }

    func checkIn(coordinate: CLLocationCoordinate2D?, battery: Int, mood: String, note: String) {
        let wasDue = dueSlot != nil
        let record = CheckInRecord(
            date: .now,
            latitude: coordinate?.latitude,
            longitude: coordinate?.longitude,
            battery: battery,
            status: wasDue ? .late : .onTime,
            mood: mood,
            note: note
        )
        records.append(record)
        if let lastDate = records.dropLast().map(\.date).max(),
           !Calendar.current.isDateInToday(lastDate) {
            streakDays += 1
        }
        let pin = coordinate == nil ? "no 📍" : "📍 attached"
        events.insert(
            ActivityEvent(kind: .checkIn, title: "Checked in \(mood)",
                          detail: "\(pin) · 🔋 \(battery)%", date: .now),
            at: 0
        )
        if let index = family.firstIndex(where: \.isMe) {
            family[index].status = .good
            family[index].battery = battery
            family[index].lastSeenMinutes = 0
        }
        save()
    }

    func approvePing(_ ping: PingRequest) {
        guard let index = pings.firstIndex(where: { $0.id == ping.id }) else { return }
        pings[index].isApproved = true
        events.insert(
            ActivityEvent(kind: .ping, title: "Location shared with \(ping.fromName)",
                          detail: "Approved in 1 tap", date: .now),
            at: 0
        )
        save()
    }

    func sendRecap(_ text: String) {
        events.insert(
            ActivityEvent(kind: .recap, title: "Daily recap sent", detail: "“\(text)”", date: .now),
            at: 0
        )
        save()
    }

    func addExpense(title: String, emoji: String, amount: Double) {
        expenses.insert(Expense(title: title, emoji: emoji, amount: amount, date: .now), at: 0)
        save()
    }

    func triggerSOS(coordinate: CLLocationCoordinate2D?) {
        let location = coordinate.map { String(format: "%.4f, %.4f", $0.latitude, $0.longitude) } ?? "location unavailable"
        events.insert(
            ActivityEvent(kind: .sos, title: "SOS sent to your circle",
                          detail: "📍 \(location)", date: .now),
            at: 0
        )
        save()
    }

    func toggleSlot(_ slot: ScheduledCheckIn) {
        guard let index = schedule.firstIndex(where: { $0.id == slot.id }) else { return }
        schedule[index].isEnabled.toggle()
        save()
    }

    func addRecentSearch(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        recentSearches.removeAll { $0.caseInsensitiveCompare(trimmed) == .orderedSame }
        recentSearches.insert(trimmed, at: 0)
        recentSearches = Array(recentSearches.prefix(6))
        save()
    }

    func reset() {
        try? FileManager.default.removeItem(at: Self.fileURL)
        hasOnboarded = false
        profile = UserProfile(name: "", email: "")
        parents = []
        schedule = []
        seedDemoContent()
    }

    // MARK: - Persistence (JSON file in Documents)

    private struct Snapshot: Codable {
        var hasOnboarded: Bool
        var profile: UserProfile
        var parents: [ParentContact]
        var schedule: [ScheduledCheckIn]
        var records: [CheckInRecord]
        var stops: [ItineraryStop]
        var expenses: [Expense]
        var budget: Double
        var family: [FamilyMember]
        var pings: [PingRequest]
        var events: [ActivityEvent]
        var recentSearches: [String]
        var streakDays: Int
    }

    private static let fileURL = FileManager.default
        .urls(for: .documentDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("checkin-store.json")

    func save() {
        let snapshot = Snapshot(
            hasOnboarded: hasOnboarded, profile: profile, parents: parents,
            schedule: schedule, records: records, stops: stops, expenses: expenses,
            budget: budget, family: family, pings: pings, events: events,
            recentSearches: recentSearches, streakDays: streakDays
        )
        if let data = try? JSONEncoder().encode(snapshot) {
            try? data.write(to: Self.fileURL, options: .atomic)
        }
    }

    private func load() {
        guard let data = try? Data(contentsOf: Self.fileURL),
              let snapshot = try? JSONDecoder().decode(Snapshot.self, from: data) else {
            seedDemoContent()
            return
        }
        hasOnboarded = snapshot.hasOnboarded
        profile = snapshot.profile
        parents = snapshot.parents
        schedule = snapshot.schedule
        records = snapshot.records
        stops = snapshot.stops
        expenses = snapshot.expenses
        budget = snapshot.budget
        family = snapshot.family
        pings = snapshot.pings
        events = snapshot.events
        recentSearches = snapshot.recentSearches
        streakDays = snapshot.streakDays
    }

    private func seedDemoContent() {
        records = Seed.records
        stops = Seed.stops
        expenses = Seed.expenses
        family = Seed.family(meName: "You")
        pings = Seed.pings
        events = Seed.events
        recentSearches = []
        streakDays = 5
    }
}
