import SwiftUI

enum AppTab: String, CaseIterable, Identifiable {
    case home, plan, activity, profile

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: "Home"
        case .plan: "Trip"
        case .activity: "Activity"
        case .profile: "Profile"
        }
    }

    var icon: String {
        switch self {
        case .home: "house"
        case .plan: "map"
        case .activity: "bolt"
        case .profile: "person.crop.circle"
        }
    }

    var selectedIcon: String {
        switch self {
        case .home: "house.fill"
        case .plan: "map.fill"
        case .activity: "bolt.fill"
        case .profile: "person.crop.circle.fill"
        }
    }
}

/// Floating pill tab bar with a sliding lime highlight and a center
/// "I'm good" check-in button that pulses when a check-in is due.
struct FloatingTabBar: View {
    @Binding var selection: AppTab
    var isCheckInDue: Bool
    var onCheckIn: () -> Void

    @Namespace private var pillSpace
    @State private var duePulse = false

    var body: some View {
        HStack(spacing: 4) {
            tabButton(.home)
            tabButton(.plan)
            checkInButton
            tabButton(.activity)
            tabButton(.profile)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            Capsule(style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule(style: .continuous)
                        .strokeBorder(Theme.ink.opacity(0.06), lineWidth: 1)
                )
                .shadow(color: Theme.ink.opacity(0.12), radius: 18, y: 8)
        )
        .padding(.horizontal, 16)
        .onAppear { duePulse = true }
    }

    private func tabButton(_ tab: AppTab) -> some View {
        let isSelected = selection == tab
        return Button {
            guard selection != tab else { return }
            Haptics.tap()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                selection = tab
            }
        } label: {
            VStack(spacing: 3) {
                Image(systemName: isSelected ? tab.selectedIcon : tab.icon)
                    .font(.system(size: 17, weight: .semibold))
                    .symbolEffect(.bounce, value: isSelected)
                Text(tab.title)
                    .font(.display(10, weight: .semibold))
            }
            .foregroundStyle(isSelected ? Theme.ink : Theme.inkSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .background {
                if isSelected {
                    Capsule(style: .continuous)
                        .fill(Theme.lime)
                        .matchedGeometryEffect(id: "activePill", in: pillSpace)
                }
            }
        }
        .buttonStyle(SquishyButtonStyle(scale: 0.9))
    }

    private var checkInButton: some View {
        Button {
            Haptics.thump()
            onCheckIn()
        } label: {
            ZStack {
                if isCheckInDue {
                    Circle()
                        .stroke(Theme.amber.opacity(0.55), lineWidth: 3)
                        .frame(width: 52, height: 52)
                        .scaleEffect(duePulse ? 1.28 : 1)
                        .opacity(duePulse ? 0 : 1)
                        .animation(
                            .easeOut(duration: 1.2).repeatForever(autoreverses: false),
                            value: duePulse
                        )
                }
                Image(systemName: "checkmark")
                    .font(.system(size: 19, weight: .heavy))
                    .foregroundStyle(.white)
                    .frame(width: 52, height: 52)
                    .background(
                        Circle()
                            .fill(isCheckInDue ? Theme.amber : Theme.ink)
                            .shadow(color: (isCheckInDue ? Theme.amber : Theme.ink).opacity(0.35), radius: 10, y: 5)
                    )
            }
        }
        .buttonStyle(SquishyButtonStyle(scale: 0.88))
        .accessibilityLabel("Check in — I'm good")
    }
}

#Preview {
    ZStack(alignment: .bottom) {
        Theme.canvas.ignoresSafeArea()
        FloatingTabBar(selection: .constant(.home), isCheckInDue: true, onCheckIn: {})
    }
}
