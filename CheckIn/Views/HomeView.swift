import SwiftUI
import MapKit

/// The green board: my check-in status, battery/last-seen, ping requests, family view.
struct HomeView: View {
    @Environment(Store.self) private var store
    @Environment(LocationService.self) private var location

    @State private var showSearch = false
    @State private var showSOS = false
    @State private var showCheckIn = false
    @State private var approvedPingID: UUID?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                header
                    .appearStagger(0)
                statusHero
                    .appearStagger(1)
                if let ping = activePing {
                    pingCard(ping)
                        .appearStagger(2)
                }
                familyBoard
                    .appearStagger(3)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 120)
        }
        .sheet(isPresented: $showSearch) { SearchView() }
        .sheet(isPresented: $showCheckIn) {
            CheckInSheet()
                .presentationDetents([.large])
                .presentationCornerRadius(32)
        }
        .fullScreenCover(isPresented: $showSOS) { SOSView() }
        .onAppear { location.refresh() }
    }

    /// Pending ping, or the one just approved (kept visible to show its success state).
    private var activePing: PingRequest? {
        if let pending = store.pendingPing { return pending }
        return store.pings.first { $0.id == approvedPingID }
    }

    private var header: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Hey, \(store.profile.name.split(separator: " ").first.map(String.init) ?? "there")")
                    .font(.display(28, weight: .bold))
                    .foregroundStyle(Theme.ink)
                if let stop = store.currentStop {
                    HStack(spacing: 5) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 11, weight: .semibold))
                        Text("\(stop.city), \(stop.country)")
                            .font(.display(14, weight: .medium))
                    }
                    .foregroundStyle(Theme.inkSecondary)
                }
            }

            Spacer()

            Button {
                Haptics.tap()
                showSearch = true
            } label: {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Theme.ink)
                    .frame(width: 42, height: 42)
                    .background(Circle().fill(Theme.surface))
            }
            .buttonStyle(SquishyButtonStyle(scale: 0.85))

            Button {
                Haptics.thump()
                showSOS = true
            } label: {
                Text("SOS")
                    .font(.display(14, weight: .heavy))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .frame(height: 42)
                    .background(
                        Capsule().fill(Theme.danger)
                            .shadow(color: Theme.danger.opacity(0.35), radius: 8, y: 4)
                    )
            }
            .buttonStyle(SquishyButtonStyle())
        }
    }

    // MARK: - Status hero

    private var isDue: Bool { store.dueSlot != nil }

    private var statusHero: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(isDue ? Theme.amberSoft : Theme.limeSoft)
                        .frame(width: 54, height: 54)
                    Image(systemName: isDue ? "clock.fill" : "checkmark")
                        .font(.system(size: 22, weight: .heavy))
                        .foregroundStyle(isDue ? Theme.amber : Theme.ink)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(isDue ? "Check-in due" : "All good")
                        .font(.display(21, weight: .bold))
                        .foregroundStyle(Theme.ink)
                    Text(isDue
                         ? "\(store.dueSlot?.label ?? "") · was \(store.dueSlot?.timeString ?? "")"
                         : "Next check-in \(store.nextSlotCountdown)")
                        .font(.display(13, weight: .semibold))
                        .foregroundStyle(Theme.inkSecondary)
                }

                Spacer()
            }

            if isDue {
                PrimaryButton(title: "I'm good ✓", tint: Theme.lime, titleColor: Theme.ink) {
                    showCheckIn = true
                }
            }

            if let record = store.lastRecord {
                lastCheckInDetails(record)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Theme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .strokeBorder(isDue ? Theme.amber.opacity(0.5) : .clear, lineWidth: 2)
                )
                .shadow(color: Theme.ink.opacity(0.06), radius: 14, y: 7)
        )
    }

    private func lastCheckInDetails(_ record: CheckInRecord) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if let coordinate = record.coordinate {
                Map(initialPosition: .region(
                    MKCoordinateRegion(
                        center: coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.012, longitudeDelta: 0.012)
                    )
                )) {
                    Annotation("", coordinate: coordinate) {
                        Text(record.mood)
                            .font(.system(size: 16))
                            .frame(width: 34, height: 34)
                            .background(
                                Circle().fill(.white)
                                    .shadow(color: Theme.ink.opacity(0.2), radius: 5, y: 2)
                            )
                            .overlay(Circle().strokeBorder(Theme.lime, lineWidth: 3))
                    }
                }
                .frame(height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .allowsHitTesting(false)
                .id(record.id)
            }

            HStack(spacing: 14) {
                detailChip(icon: "clock", text: record.date.formatted(date: .omitted, time: .shortened))
                detailChip(icon: "battery.75percent", text: "\(record.battery)%")
                detailChip(icon: "location.fill", text: record.coordinate == nil ? "No 📍" : "Attached")
                Spacer()
            }
        }
    }

    private func detailChip(icon: String, text: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
            Text(text)
                .font(.display(12, weight: .semibold))
        }
        .foregroundStyle(Theme.inkSecondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Capsule().fill(Theme.canvas))
    }

    // MARK: - Ping request

    private func pingCard(_ ping: PingRequest) -> some View {
        HStack(spacing: 14) {
            EmojiAvatar(emoji: "📍", size: 46, tint: Theme.skySoft)

            VStack(alignment: .leading, spacing: 3) {
                Text(ping.isApproved ? "Location shared" : "\(ping.fromName) asked where you are")
                    .font(.display(15, weight: .bold))
                    .foregroundStyle(Theme.ink)
                Text(ping.isApproved ? "\(ping.fromName) can see your spot 📍" : "Sent \(ping.sentMinutesAgo)m ago · one tap to share")
                    .font(.display(13, weight: .medium))
                    .foregroundStyle(Theme.inkSecondary)
            }

            Spacer()

            Button {
                Haptics.success()
                approvedPingID = ping.id
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    store.approvePing(ping)
                }
            } label: {
                HStack(spacing: 4) {
                    if ping.isApproved {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                    }
                    Text(ping.isApproved ? "Shared" : "Share")
                        .font(.display(14, weight: .bold))
                }
                .foregroundStyle(ping.isApproved ? Theme.ink : .white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Capsule().fill(ping.isApproved ? Theme.lime : Theme.sky))
            }
            .buttonStyle(SquishyButtonStyle())
            .disabled(ping.isApproved)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Theme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(Theme.sky.opacity(ping.isApproved ? 0 : 0.45), lineWidth: 1.5)
                )
                .shadow(color: Theme.ink.opacity(0.05), radius: 12, y: 6)
        )
    }

    // MARK: - Family board

    private var familyBoard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Family board", trailing: "\(store.family.count) people")
            VStack(spacing: 10) {
                ForEach(store.family) { member in
                    memberRow(member)
                }
            }
        }
    }

    private func memberRow(_ member: FamilyMember) -> some View {
        let battery = member.isMe ? Device.batteryPercent() : member.battery
        return HStack(spacing: 14) {
            EmojiAvatar(emoji: member.emoji, size: 48,
                        tint: member.isMe ? Theme.limeSoft : Theme.canvas)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(member.isMe ? "You" : member.name)
                        .font(.display(16, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                    StatusDot(status: member.isMe && isDue ? .due : member.status)
                }
                Text(member.role)
                    .font(.display(13, weight: .medium))
                    .foregroundStyle(Theme.inkSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                HStack(spacing: 4) {
                    Image(systemName: battery <= 20 ? "battery.25percent" : "battery.75percent")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(battery <= 20 ? Theme.danger : Theme.ink)
                    Text("\(battery)%")
                        .font(.display(14, weight: .bold))
                        .monospacedDigit()
                        .foregroundStyle(Theme.ink)
                }
                Text("seen \(member.isMe ? "now" : member.lastSeenString)")
                    .font(.display(12, weight: .medium))
                    .foregroundStyle(Theme.inkSecondary)
            }
        }
        .padding(14)
        .card(cornerRadius: 22)
    }
}

#Preview {
    ZStack {
        Theme.canvas.ignoresSafeArea()
        HomeView()
    }
    .environment(Store())
    .environment(LocationService())
}
