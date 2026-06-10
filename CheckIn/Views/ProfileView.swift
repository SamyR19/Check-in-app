import SwiftUI

struct ProfileView: View {
    @Environment(Store.self) private var store
    @State private var ringShown = false
    @State private var showResetConfirm = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                identity
                    .appearStagger(0)
                statsRow
                    .appearStagger(1)
                if !store.isParent {
                    scheduleSection
                        .appearStagger(2)
                    inviteSection
                        .appearStagger(3)
                }
                if !store.parents.isEmpty {
                    circleSection
                        .appearStagger(4)
                }
                settingsSection
                    .appearStagger(5)
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 120)
        }
        .onAppear {
            withAnimation(.spring(response: 1.1, dampingFraction: 0.8).delay(0.2)) {
                ringShown = true
            }
        }
        .confirmationDialog(
            "Reset the app?",
            isPresented: $showResetConfirm,
            titleVisibility: .visible
        ) {
            Button("Erase everything", role: .destructive) {
                Haptics.thump()
                store.reset()
            }
        } message: {
            Text("All local data is erased and onboarding starts over.")
        }
    }

    private var identity: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .trim(from: 0, to: ringShown ? 0.78 : 0)
                    .stroke(Theme.heroGradient, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 104, height: 104)
                Circle()
                    .fill(Theme.limeSoft)
                    .frame(width: 88, height: 88)
                    .overlay(
                        Text(store.profile.initials.isEmpty ? "🎒" : store.profile.initials)
                            .font(.display(30, weight: .bold))
                            .foregroundStyle(Theme.ink)
                    )
            }

            VStack(spacing: 5) {
                Text(store.profile.name)
                    .font(.display(24, weight: .bold))
                    .foregroundStyle(Theme.ink)
                Text(store.profile.email)
                    .font(.display(14, weight: .medium))
                    .foregroundStyle(Theme.inkSecondary)
                Text(store.isParent ? "🛡️ Parent · watching the board" : "🎒 Traveler")
                    .font(.display(12, weight: .bold))
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(store.isParent ? Theme.skySoft : Theme.limeSoft))
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var statsRow: some View {
        HStack(spacing: 10) {
            statCard(value: "\(store.records.count)", label: "Check-ins", emoji: "✅")
            statCard(value: "\(store.streakDays)", label: "Day streak", emoji: "🔥")
            statCard(value: onTimePercent, label: "On time", emoji: "⏰")
        }
    }

    private var onTimePercent: String {
        guard !store.records.isEmpty else { return "—" }
        let onTime = store.records.filter { $0.status == .onTime }.count
        return "\(Int(Double(onTime) / Double(store.records.count) * 100))%"
    }

    private func statCard(value: String, label: String, emoji: String) -> some View {
        VStack(spacing: 4) {
            Text(emoji).font(.system(size: 20))
            Text(value)
                .font(.display(22, weight: .heavy))
                .monospacedDigit()
                .foregroundStyle(Theme.ink)
                .contentTransition(.numericText())
            Text(label)
                .font(.display(12, weight: .semibold))
                .foregroundStyle(Theme.inkSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .card(cornerRadius: 22)
    }

    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Check-in times")
            VStack(spacing: 0) {
                ForEach(store.schedule) { slot in
                    HStack(spacing: 12) {
                        Text(slot.label)
                            .font(.display(15, weight: .semibold))
                            .foregroundStyle(slot.isEnabled ? Theme.ink : Theme.inkSecondary)
                        Spacer()
                        Text(slot.timeString)
                            .font(.display(14, weight: .bold))
                            .monospacedDigit()
                            .foregroundStyle(slot.isEnabled ? Theme.ink : Theme.inkSecondary)
                        Toggle("", isOn: Binding(
                            get: { slot.isEnabled },
                            set: { _ in
                                Haptics.tap()
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    store.toggleSlot(slot)
                                }
                            }
                        ))
                        .labelsHidden()
                        .tint(Theme.lime)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 11)

                    if slot.id != store.schedule.last?.id {
                        Divider().padding(.leading, 16)
                    }
                }
            }
            .card(cornerRadius: 24)
        }
    }

    @State private var copiedID: UUID?

    private var inviteSection: some View {
        Group {
            if !store.inviteCodes.isEmpty {
                VStack(alignment: .leading, spacing: 14) {
                    SectionHeader(title: "Trip invites", trailing: "expire in 24h")
                    VStack(spacing: 10) {
                        ForEach(store.inviteCodes) { invite in
                            HStack(spacing: 12) {
                                EmojiAvatar(emoji: invite.audience.emoji, size: 42,
                                            tint: invite.audience == .friends ? Theme.limeSoft : Theme.skySoft)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(invite.audience.title)
                                        .font(.display(14, weight: .semibold))
                                        .foregroundStyle(Theme.ink)
                                    Text(invite.displayCode)
                                        .font(.system(size: 15, weight: .heavy, design: .monospaced))
                                        .foregroundStyle(Theme.inkSecondary)
                                }
                                Spacer()
                                Button {
                                    Haptics.success()
                                    UIPasteboard.general.string = invite.code
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                        copiedID = invite.id
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                                        withAnimation { copiedID = nil }
                                    }
                                } label: {
                                    Image(systemName: copiedID == invite.id ? "checkmark" : "doc.on.doc")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(copiedID == invite.id ? Theme.ink : .white)
                                        .frame(width: 36, height: 36)
                                        .background(Circle().fill(copiedID == invite.id ? Theme.lime : Theme.ink))
                                }
                                .buttonStyle(SquishyButtonStyle(scale: 0.85))
                            }
                            .padding(12)
                            .card(cornerRadius: 22)
                        }
                    }
                }
            }
        }
    }

    private var circleSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Your circle", trailing: "\(store.parents.count) people")
            VStack(spacing: 10) {
                ForEach(store.parents) { parent in
                    HStack(spacing: 12) {
                        EmojiAvatar(emoji: parent.emoji, size: 44)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(parent.name)
                                .font(.display(15, weight: .semibold))
                                .foregroundStyle(Theme.ink)
                            Text(parent.relation)
                                .font(.display(13, weight: .medium))
                                .foregroundStyle(Theme.inkSecondary)
                        }
                        Spacer()
                        HStack(spacing: 4) {
                            Image(systemName: "bell.fill")
                                .font(.system(size: 10, weight: .semibold))
                            Text("Gets alerts")
                                .font(.display(12, weight: .semibold))
                        }
                        .foregroundStyle(Theme.sky)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Theme.skySoft.opacity(0.4)))
                    }
                    .padding(12)
                    .card(cornerRadius: 22)
                }
            }
        }
    }

    private var settingsSection: some View {
        VStack(spacing: 0) {
            settingsRow(icon: "bell", title: "Notifications")
            Divider().padding(.leading, 56)
            settingsRow(icon: "location", title: "Location access")
            Divider().padding(.leading, 56)
            settingsRow(icon: "lock", title: "Privacy")
            Divider().padding(.leading, 56)
            Button {
                Haptics.tap()
                showResetConfirm = true
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.danger)
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(Theme.dangerSoft.opacity(0.6)))
                    Text("Reset app")
                        .font(.display(15, weight: .semibold))
                        .foregroundStyle(Theme.danger)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 13)
            }
            .buttonStyle(SquishyButtonStyle(scale: 0.98))
        }
        .card(cornerRadius: 24)
    }

    private func settingsRow(icon: String, title: String) -> some View {
        Button {
            Haptics.tap()
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(Theme.canvas))
                Text(title)
                    .font(.display(15, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.inkSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
        }
        .buttonStyle(SquishyButtonStyle(scale: 0.98))
    }
}

#Preview {
    ZStack {
        Theme.canvas.ignoresSafeArea()
        ProfileView()
    }
    .environment(Store())
}
