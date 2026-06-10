import SwiftUI

enum AppTab: String, CaseIterable, Identifiable {
    case explore, saved, activity, profile

    var id: String { rawValue }

    var title: String {
        switch self {
        case .explore: "Explore"
        case .saved: "Saved"
        case .activity: "Activity"
        case .profile: "Profile"
        }
    }

    var icon: String {
        switch self {
        case .explore: "magnifyingglass"
        case .saved: "heart"
        case .activity: "chart.line.uptrend.xyaxis"
        case .profile: "person.crop.circle"
        }
    }

    var selectedIcon: String {
        switch self {
        case .explore: "magnifyingglass"
        case .saved: "heart.fill"
        case .activity: "chart.line.uptrend.xyaxis"
        case .profile: "person.crop.circle.fill"
        }
    }
}

/// Floating pill tab bar with a sliding lime highlight and a center check-in button.
struct FloatingTabBar: View {
    @Binding var selection: AppTab
    var onCheckIn: () -> Void

    @Namespace private var pillSpace

    var body: some View {
        HStack(spacing: 4) {
            tabButton(.explore)
            tabButton(.saved)
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
            Image(systemName: "plus")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 52, height: 52)
                .background(
                    Circle()
                        .fill(Theme.ink)
                        .shadow(color: Theme.ink.opacity(0.3), radius: 10, y: 5)
                )
        }
        .buttonStyle(SquishyButtonStyle(scale: 0.88))
        .accessibilityLabel("Check in")
    }
}

#Preview {
    ZStack(alignment: .bottom) {
        Theme.canvas.ignoresSafeArea()
        FloatingTabBar(selection: .constant(.explore), onCheckIn: {})
    }
}
