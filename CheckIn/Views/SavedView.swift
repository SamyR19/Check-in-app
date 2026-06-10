import SwiftUI

/// Saved spots & lists — gradient progress bar styled after the imports screen.
struct SavedView: View {
    @Environment(AppModel.self) private var model
    @State private var progressShown = false

    private let savedGoal = 25

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                header
                    .appearStagger(0)
                progressCard
                    .appearStagger(1)
                listsSection
                    .appearStagger(2)
                spotsSection
                    .appearStagger(3)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 120)
        }
        .onAppear {
            withAnimation(.spring(response: 1.0, dampingFraction: 0.85).delay(0.25)) {
                progressShown = true
            }
        }
    }

    private var header: some View {
        HStack {
            HStack(spacing: 10) {
                Text("🪐")
                    .font(.system(size: 28))
                Text("Saved")
                    .font(.display(28, weight: .bold))
                    .foregroundStyle(Theme.ink)
            }
            Spacer()
            HStack(spacing: 4) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.coral)
                Text("\(model.savedSpots.count) / \(savedGoal)")
                    .font(.display(14, weight: .bold))
                    .foregroundStyle(Theme.ink)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Capsule().fill(Theme.surface))
        }
    }

    private var progressCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Theme.skySoft.opacity(0.45))
                    Capsule()
                        .fill(Theme.skyGradient)
                        .frame(
                            width: progressShown
                                ? proxy.size.width * min(1, CGFloat(model.savedSpots.count) / CGFloat(savedGoal))
                                : 0
                        )
                }
            }
            .frame(height: 38)

            HStack {
                Text("Just started")
                Spacer()
                Text("Local legend")
            }
            .font(.display(12, weight: .semibold))
            .foregroundStyle(Theme.inkSecondary)
        }
    }

    private var listsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Your lists", trailing: "\(MockData.lists.count) lists")
            VStack(spacing: 10) {
                ForEach(Array(MockData.lists.enumerated()), id: \.element.id) { index, list in
                    listRow(list)
                        .appearStagger(index + 3)
                }
            }
        }
    }

    private func listRow(_ list: SpotList) -> some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(list.tint)
                .frame(width: 54, height: 54)
                .overlay(Text(list.emoji).font(.system(size: 24)))

            VStack(alignment: .leading, spacing: 3) {
                Text(list.title)
                    .font(.display(16, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                Text(list.subtitle)
                    .font(.display(13, weight: .medium))
                    .foregroundStyle(Theme.inkSecondary)
            }

            Spacer()

            Text("\(list.saved)")
                .font(.display(14, weight: .bold))
                .foregroundStyle(Theme.sky)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(Theme.skySoft.opacity(0.4)))
        }
        .padding(14)
        .card(cornerRadius: 22)
    }

    private var spotsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "All saved spots")
            if model.savedSpots.isEmpty {
                emptyState
            } else {
                VStack(spacing: 10) {
                    ForEach(model.savedSpots) { spot in
                        SpotRow(spot: spot)
                    }
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.85), value: model.savedSpots.count)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Text("🗺️")
                .font(.system(size: 40))
            Text("Save your first spot!")
                .font(.display(17, weight: .bold))
                .foregroundStyle(Theme.ink)
            Text("Tap the heart on any spot to build your map.")
                .font(.display(14, weight: .medium))
                .foregroundStyle(Theme.inkSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(Theme.sky.opacity(0.4), style: StrokeStyle(lineWidth: 1.5, dash: [6, 5]))
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Theme.skySoft.opacity(0.18))
                )
        )
    }
}

#Preview {
    ZStack {
        Theme.canvas.ignoresSafeArea()
        SavedView()
    }
    .environment(AppModel())
}
