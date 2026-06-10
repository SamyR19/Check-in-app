import SwiftUI

/// Friends' check-in feed with a countdown hero card, FOTMOB-style.
struct ActivityView: View {
    @State private var pulse = false

    private var todayCheckIns: [FriendCheckIn] { MockData.checkIns.filter(\.isToday) }
    private var earlierCheckIns: [FriendCheckIn] { MockData.checkIns.filter { !$0.isToday } }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                header
                    .appearStagger(0)
                eventCard
                    .appearStagger(1)
                feedSection(title: "Today", items: todayCheckIns, startIndex: 2)
                feedSection(title: "Earlier", items: earlierCheckIns, startIndex: 5)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 120)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }

    private var header: some View {
        HStack {
            Text("Activity")
                .font(.display(28, weight: .bold))
                .foregroundStyle(Theme.ink)
            Spacer()
            HStack(spacing: 6) {
                Circle()
                    .fill(Theme.coral)
                    .frame(width: 7, height: 7)
                    .scaleEffect(pulse ? 1.25 : 0.85)
                Text("3 friends out now")
                    .font(.display(13, weight: .semibold))
                    .foregroundStyle(Theme.ink)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Capsule().fill(Theme.surface))
        }
    }

    private var eventCard: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                Text("UP NEXT")
                    .font(.display(10, weight: .heavy))
                    .foregroundStyle(Theme.ink.opacity(0.5))
                    .kerning(1.2)
                Text("Trivia night")
                    .font(.display(19, weight: .bold))
                    .foregroundStyle(Theme.ink)
                Text("@ Nectar Lounge · Thu 8 PM")
                    .font(.display(13, weight: .semibold))
                    .foregroundStyle(Theme.ink.opacity(0.65))
            }
            .padding(18)

            Spacer()

            HStack(spacing: 14) {
                countdownColumn(value: "1", unit: "day")
                countdownColumn(value: "16", unit: "hrs")
                countdownColumn(value: "3", unit: "min")
            }
            .padding(.trailing, 20)
        }
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Theme.heroGradient)
                .shadow(color: Theme.sky.opacity(0.3), radius: 14, y: 7)
        )
    }

    private func countdownColumn(value: String, unit: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.display(22, weight: .heavy))
                .monospacedDigit()
                .foregroundStyle(Theme.ink)
            Text(unit)
                .font(.display(10, weight: .bold))
                .foregroundStyle(Theme.ink.opacity(0.55))
        }
    }

    private func feedSection(title: String, items: [FriendCheckIn], startIndex: Int) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: title)
            VStack(spacing: 10) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, checkIn in
                    feedRow(checkIn)
                        .appearStagger(startIndex + index)
                }
            }
        }
    }

    private func feedRow(_ checkIn: FriendCheckIn) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(Theme.limeSoft)
                    .frame(width: 48, height: 48)
                    .overlay(Text(checkIn.avatarEmoji).font(.system(size: 22)))
                Text(checkIn.mood)
                    .font(.system(size: 14))
                    .padding(2)
                    .background(Circle().fill(.white))
                    .offset(x: 4, y: 4)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 0) {
                    Text(checkIn.friendName)
                        .font(.display(15, weight: .bold))
                    Text(" checked in at ")
                        .font(.display(15, weight: .medium))
                        .foregroundStyle(Theme.inkSecondary)
                    Text(checkIn.spotName)
                        .font(.display(15, weight: .bold))
                }
                .foregroundStyle(Theme.ink)
                .lineLimit(2)

                Text("“\(checkIn.note)”")
                    .font(.display(13, weight: .medium))
                    .foregroundStyle(Theme.inkSecondary)
            }

            Spacer()

            Text(checkIn.timeAgo)
                .font(.display(12, weight: .semibold))
                .foregroundStyle(Theme.inkSecondary)
        }
        .padding(14)
        .card(cornerRadius: 22)
    }
}

#Preview {
    ZStack {
        Theme.canvas.ignoresSafeArea()
        ActivityView()
    }
    .environment(AppModel())
}
