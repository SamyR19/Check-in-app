import Foundation
import CoreLocation
import Observation

/// App-wide state with local JSON persistence — every mutation is saved to disk.
/// No backend: this is the "database" until Supabase is wired up.
@Observable
final class Store {
    var hasOnboarded = false
    var role: UserRole = .teen
    var profile = UserProfile(name: "", email: "")
    var trip: Trip?
    var inviteCodes: [InviteCode] = []
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
    /// Parent only: show the "send a test ping" prompt until they've done it.
    var needsTestPing = false

    init() {
        load()
    }

    // MARK: - Derived state

    var isParent: Bool { role == .parent }

    var currentStop: ItineraryStop? { stops.first(where: \.isCurrent) }

    var lastRecord: CheckInRecord? { records.max(by: { $0.date < $1.date }) }

    var spentTotal: Double { expenses.reduce(0) { $0 + $1.amount } }

    var pendingPing: PingRequest? { pings.first(where: { !$0.isApproved }) }

    var teens: [FamilyMember] { family.filter(\.isTraveling) }
    var guardians: [FamilyMember] { family.filter { !$0.isTraveling } }
    /// Parent's primary teen (first traveler on the board).
    var primaryTeen: FamilyMember? { teens.first }

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

    // MARK: - Onboarding completion

    func completeTeenOnboarding(
        profile: UserProfile, trip: Trip,
        schedule: [ScheduledCheckIn], inviteCodes: [InviteCode]
    ) {
        role = .teen
        self.profile = profile
        self.trip = trip
        self.schedule = schedule
        self.inviteCodes = inviteCodes
        parents = Seed.parents
        let firstName = profile.name.split(separator: " ").first.map(String.init) ?? profile.name
        family = Seed.familyAsTeen(meName: firstName)
        events.insert(
            ActivityEvent(kind: .checkIn, title: "Dry run complete",
                          detail: "Test check-in + ping worked — you're trip-ready", date: .now),
            at: 0
        )
        hasOnboarded = true
        save()
    }

    func completeParentOnboarding(profile: UserProfile, pairingCode: String) {
        role = .parent
        self.profile = profile
        trip = Seed.defaultTrip
        schedule = Seed.schedule
        parents = []
        pings = []
        let firstName = profile.name.split(separator: " ").first.map(String.init) ?? profile.name
        family = Seed.familyAsParent(meName: firstName)
        events.insert(
            ActivityEvent(kind: .ping, title: "Linked to “\(trip?.name ?? "the trip")”",
                          detail: "Code \(pairingCode) · you now follow the board", date: .now),
            at: 0
        )
        needsTestPing = true
        hasOnboarded = true
        save()
    }

    // MARK: - Teen actions

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

    func triggerSOS(coordinate: CLLocationCoordinate2D?) {
        let location = coordinate.map { String(format: "%.4f, %.4f", $0.latitude, $0.longitude) } ?? "location unavailable"
        events.insert(
            ActivityEvent(kind: .sos, title: "SOS sent to your circle",
                          detail: "📍 \(location)", date: .now),
            at: 0
        )
        save()
    }

    // MARK: - Parent actions

    func requestPing(to teenName: String, isTest: Bool) {
        events.insert(
            ActivityEvent(kind: .ping,
                          title: "\(isTest ? "Test ping" : "Ping") sent to \(teenName)",
                          detail: "Waiting for their one-tap approval", date: .now),
            at: 0
        )
        save()
    }

    func completePing(to teenName: String) {
        events.insert(
            ActivityEvent(kind: .ping, title: "\(teenName) shared location",
                          detail: "📍 38.7223, -9.1393 · approved in 1 tap", date: .now),
            at: 0
        )
        if let index = family.firstIndex(where: { $0.name == teenName }) {
            family[index].lastSeenMinutes = 0
            family[index].status = .good
        }
        needsTestPing = false
        save()
    }

    // MARK: - Shared actions

    func addExpense(title: String, emoji: String, amount: Double) {
        expenses.insert(Expense(title: title, emoji: emoji, amount: amount, date: .now), at: 0)
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
        role = .teen
        profile = UserProfile(name: "", email: "")
        trip = nil
        inviteCodes = []
        parents = []
        schedule = []
        needsTestPing = false
        seedDemoContent()
    }

    // MARK: - Persistence (JSON file in Documents)

    private struct Snapshot: Codable {
        var hasOnboarded: Bool
        var role: UserRole
        var profile: UserProfile
        var trip: Trip?
        var inviteCodes: [InviteCode]
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
        var needsTestPing: Bool
    }

    private static let fileURL = FileManager.default
        .urls(for: .documentDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("checkin-store.json")

    func save() {
        let snapshot = Snapshot(
            hasOnboarded: hasOnboarded, role: role, profile: profile, trip: trip,
            inviteCodes: inviteCodes, parents: parents, schedule: schedule,
            records: records, stops: stops, expenses: expenses, budget: budget,
            family: family, pings: pings, events: events,
            recentSearches: recentSearches, streakDays: streakDays,
            needsTestPing: needsTestPing
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
        role = snapshot.role
        profile = snapshot.profile
        trip = snapshot.trip
        inviteCodes = snapshot.inviteCodes
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
        needsTestPing = snapshot.needsTestPing
    }

    private func seedDemoContent() {
        records = Seed.records
        stops = Seed.stops
        expenses = Seed.expenses
        family = Seed.familyAsTeen(meName: "You")
        pings = Seed.pings
        events = Seed.events
        recentSearches = []
        streakDays = 5
    }
}
