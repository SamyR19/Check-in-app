import SwiftUI
import MapKit

/// The parent dashboard — same navigation shell as the teen app,
/// but the home tab is the live board of everyone on the trip.
struct ParentHomeView: View {
    @Environment(Store.self) private var store

    @State private var showSearch = false
    @State private var showPing = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                header
                    .appearStagger(0)
                if store.needsTestPing {
                    testPingPrompt
                        .appearStagger(1)
                }
                nextCheckInCard
                    .appearStagger(2)
                teensBoard
                    .appearStagger(3)
                guardiansRow
                    .appearStagger(4)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 120)
        }
        .sheet(isPresented: $showSearch) { SearchView() }
        .sheet(isPresented: $showPing) {
            PingSheet()
                .presentationDetents([.large])
                .presentationCornerRadius(32)
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text("The board")
                    .font(.display(28, weight: .bold))
                    .foregroundStyle(Theme.ink)
                if let trip = store.trip {
                    HStack(spacing: 5) {
                        Text(trip.emoji)
                            .font(.system(size: 12))
                        Text("\(trip.name) · \(trip.dateRangeString)")
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
        }
    }

    /// First-run prompt: prove the loop works the moment they land.
    private var testPingPrompt: some View {
        HStack(spacing: 14) {
            EmojiAvatar(emoji: "📳", size: 46, tint: Theme.skySoft)

            VStack(alignment: .leading, spacing: 3) {
                Text("See it work right now")
                    .font(.display(15, weight: .bold))
                    .foregroundStyle(Theme.ink)
                Text("Send \(store.primaryTeen?.name ?? "your teen") a test ping — their phone buzzes, they approve, you see it land.")
                    .font(.display(13, weight: .medium))
                    .foregroundStyle(Theme.inkSecondary)
            }

            Spacer()

            Button {
                Haptics.thump()
                showPing = true
            } label: {
                Text("Try it")
                    .font(.display(14, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Theme.sky))
            }
            .buttonStyle(SquishyButtonStyle())
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Theme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(Theme.sky.opacity(0.45), lineWidth: 1.5)
                )
                .shadow(color: Theme.ink.opacity(0.05), radius: 12, y: 6)
        )
    }

    private var nextCheckInCard: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Theme.limeSoft)
                    .frame(width: 54, height: 54)
                Image(systemName: "clock.badge.checkmark")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Theme.ink)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("Next check-in expected")
                    .font(.display(15, weight: .bold))
                    .foregroundStyle(Theme.ink)
                Text("\(store.nextSlot?.slot.label ?? "—") · \(store.nextSlot?.slot.timeString ?? "") · \(store.nextSlotCountdown)")
                    .font(.display(13, weight: .semibold))
                    .foregroundStyle(Theme.inkSecondary)
            }

            Spacer()
        }
        .padding(16)
        .card(cornerRadius: 26)
    }

    // MARK: - Teens

    private var teensBoard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "On the trip", trailing: "\(store.teens.count) traveling")
            VStack(spacing: 10) {
                ForEach(Array(store.teens.enumerated()), id: \.element.id) { index, teen in
                    teenCard(teen, showMap: index == 0)
                }
            }
        }
    }

    private func teenCard(_ teen: FamilyMember, showMap: Bool) -> some View {
        VStack(spacing: 14) {
            HStack(spacing: 14) {
                EmojiAvatar(emoji: teen.emoji, size: 48, tint: Theme.limeSoft)

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(teen.name)
                            .font(.display(16, weight: .semibold))
                            .foregroundStyle(Theme.ink)
                        StatusDot(status: teen.status)
                    }
                    Text(lastProofLine(for: teen))
                        .font(.display(13, weight: .medium))
                        .foregroundStyle(Theme.inkSecondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 3) {
                    HStack(spacing: 4) {
                        Image(systemName: teen.battery <= 20 ? "battery.25percent" : "battery.75percent")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(teen.battery <= 20 ? Theme.danger : Theme.ink)
                        Text("\(teen.battery)%")
                            .font(.display(14, weight: .bold))
                            .monospacedDigit()
                            .foregroundStyle(Theme.ink)
                    }
                    Text("seen \(teen.lastSeenString)")
                        .font(.display(12, weight: .medium))
                        .foregroundStyle(Theme.inkSecondary)
                }
            }

            if showMap, let record = store.lastRecord, let coordinate = record.coordinate {
                Map(initialPosition: .region(
                    MKCoordinateRegion(
                        center: coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.012, longitudeDelta: 0.012)
                    )
                )) {
                    Annotation("", coordinate: coordinate) {
                        Text(teen.emoji)
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
        }
        .padding(14)
        .card(cornerRadius: 24)
    }

    private func lastProofLine(for teen: FamilyMember) -> String {
        if teen.name == store.primaryTeen?.name, let record = store.lastRecord {
            return "Checked in \(record.date.formatted(date: .omitted, time: .shortened)) · 📍 attached"
        }
        return teen.role
    }

    // MARK: - Guardians

    private var guardiansRow: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Also watching")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(store.guardians) { guardian in
                        HStack(spacing: 10) {
                            EmojiAvatar(emoji: guardian.emoji, size: 38, tint: Theme.skySoft)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(guardian.isMe ? "You" : guardian.name)
                                    .font(.display(14, weight: .bold))
                                    .foregroundStyle(Theme.ink)
                                Text("seen \(guardian.lastSeenString)")
                                    .font(.display(12, weight: .medium))
                                    .foregroundStyle(Theme.inkSecondary)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .card(cornerRadius: 20)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 4)
            }
            .padding(.horizontal, -20)
        }
    }
}

// MARK: - Ping sheet (parent's center button)

/// Consent-based location request: pick a teen, send, watch the one-tap
/// approval land. (Approval is simulated locally until the backend exists.)
struct PingSheet: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss

    private enum Phase { case pick, waiting, shared }
    @State private var phase: Phase = .pick
    @State private var selectedTeen: FamilyMember?

    var body: some View {
        ZStack {
            Theme.canvas.ignoresSafeArea()

            switch phase {
            case .pick:
                pickPhase
                    .transition(.opacity)
            case .waiting:
                waitingPhase
                    .transition(.scale(scale: 0.92).combined(with: .opacity))
            case .shared:
                SuccessBurst(
                    title: "\(selectedTeen?.name ?? "") shared 📍",
                    subtitle: "38.7223, -9.1393 · approved in one tap"
                )
                .transition(.scale(scale: 0.7).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.8), value: phase == .waiting)
        .onAppear { selectedTeen = store.primaryTeen }
    }

    private var pickPhase: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Request location")
                        .font(.display(26, weight: .bold))
                        .foregroundStyle(Theme.ink)
                    Text("They approve with one tap — pings are never silent.")
                        .font(.display(14, weight: .medium))
                        .foregroundStyle(Theme.inkSecondary)
                }
                Spacer()
                Button {
                    Haptics.tap()
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Theme.ink)
                        .frame(width: 34, height: 34)
                        .background(Circle().fill(Theme.surface))
                }
                .buttonStyle(SquishyButtonStyle(scale: 0.85))
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("WHO")
                    .font(.display(11, weight: .heavy))
                    .foregroundStyle(Theme.inkSecondary)
                    .kerning(1.2)

                VStack(spacing: 8) {
                    ForEach(store.teens) { teen in
                        teenOption(teen)
                    }
                }
            }

            Spacer()

            PrimaryButton(
                title: store.needsTestPing ? "Send test ping" : "Send ping",
                isEnabled: selectedTeen != nil,
                tint: Theme.sky
            ) {
                send()
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 16)
    }

    private func teenOption(_ teen: FamilyMember) -> some View {
        let isSelected = selectedTeen?.id == teen.id
        return Button {
            Haptics.tap()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                selectedTeen = teen
            }
        } label: {
            HStack(spacing: 12) {
                EmojiAvatar(emoji: teen.emoji, size: 42, tint: Theme.limeSoft)

                VStack(alignment: .leading, spacing: 2) {
                    Text(teen.name)
                        .font(.display(15, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                    Text("🔋 \(teen.battery)% · seen \(teen.lastSeenString)")
                        .font(.display(12, weight: .medium))
                        .foregroundStyle(Theme.inkSecondary)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(isSelected ? Theme.sky : Theme.inkSecondary.opacity(0.4))
                    .symbolEffect(.bounce, value: isSelected)
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Theme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(isSelected ? Theme.sky : .clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(SquishyButtonStyle(scale: 0.97))
    }

    private var waitingPhase: some View {
        VStack(spacing: 20) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Theme.skySoft)
                    .frame(width: 92, height: 92)
                Text(selectedTeen?.emoji ?? "🎒")
                    .font(.system(size: 40))
            }

            VStack(spacing: 5) {
                Text("\(selectedTeen?.name ?? "")'s phone just buzzed")
                    .font(.display(22, weight: .bold))
                    .foregroundStyle(Theme.ink)
                Text("Waiting for their one-tap approval…")
                    .font(.display(14, weight: .semibold))
                    .foregroundStyle(Theme.inkSecondary)
            }

            ProgressView()
                .controlSize(.large)

            Spacer()
        }
    }

    private func send() {
        guard let teen = selectedTeen else { return }
        Haptics.thump()
        store.requestPing(to: teen.name, isTest: store.needsTestPing)
        withAnimation { phase = .waiting }
        // Simulated consent: the teen approves a moment later.
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
            Haptics.success()
            store.completePing(to: teen.name)
            withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) {
                phase = .shared
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                dismiss()
            }
        }
    }
}

#Preview {
    ZStack {
        Theme.canvas.ignoresSafeArea()
        ParentHomeView()
    }
    .environment(Store())
}
