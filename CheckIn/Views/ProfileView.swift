import SwiftUI

struct ProfileView: View {
    @Environment(AppModel.self) private var model
    @State private var ringShown = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                identity
                    .appearStagger(0)
                statsRow
                    .appearStagger(1)
                badgesSection
                    .appearStagger(2)
                settingsSection
                    .appearStagger(3)
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
                    .overlay(Text("🏔️").font(.system(size: 40)))
            }

            VStack(spacing: 3) {
                Text(MockData.userName)
                    .font(.display(24, weight: .bold))
                    .foregroundStyle(Theme.ink)
                Text("@samy · \(MockData.homeArea)")
                    .font(.display(14, weight: .medium))
                    .foregroundStyle(Theme.inkSecondary)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var statsRow: some View {
        HStack(spacing: 10) {
            statCard(value: "\(model.totalCheckIns)", label: "Check-ins", emoji: "📍")
            statCard(value: "\(model.streakDays)", label: "Day streak", emoji: "🔥")
            statCard(value: "\(model.savedSpots.count)", label: "Saved", emoji: "❤️")
        }
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

    private var badgesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Badges", trailing: "4 of 6")
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                ForEach(Array(MockData.badges.enumerated()), id: \.element.id) { index, badge in
                    badgeCell(badge)
                        .appearStagger(index + 3)
                }
            }
        }
    }

    private func badgeCell(_ badge: Badge) -> some View {
        VStack(spacing: 6) {
            Text(badge.emoji)
                .font(.system(size: 28))
                .grayscale(badge.earned ? 0 : 1)
                .opacity(badge.earned ? 1 : 0.4)
            Text(badge.name)
                .font(.display(12, weight: .semibold))
                .foregroundStyle(badge.earned ? Theme.ink : Theme.inkSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(badge.earned ? Theme.surface : Theme.surface.opacity(0.5))
                .shadow(color: Theme.ink.opacity(badge.earned ? 0.05 : 0), radius: 10, y: 5)
        )
    }

    private var settingsSection: some View {
        VStack(spacing: 0) {
            settingsRow(icon: "bell", title: "Notifications")
            Divider().padding(.leading, 56)
            settingsRow(icon: "person.2", title: "Find friends")
            Divider().padding(.leading, 56)
            settingsRow(icon: "lock", title: "Privacy")
            Divider().padding(.leading, 56)
            settingsRow(icon: "questionmark.circle", title: "Help & feedback")
        }
        .card(cornerRadius: 24)
    }

    private func settingsRow(icon: String, title: String) -> some View {
        Button {
            Haptics.tap()
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
    .environment(AppModel())
}
