import SwiftUI

struct ExploreView: View {
    @Environment(AppModel.self) private var model
    @State private var selectedCategory: SpotCategory = .all
    @State private var showMap = false

    private var filteredSpots: [Spot] {
        selectedCategory == .all
            ? model.spots
            : model.spots.filter { $0.category == selectedCategory }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    header
                        .appearStagger(0)
                    searchBar
                        .appearStagger(1)
                    categoryRow
                        .appearStagger(2)
                    nearbyRail
                        .appearStagger(3)
                    popularList
                        .appearStagger(4)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 140)
            }

            mapButton
                .padding(.bottom, 96)
        }
        .fullScreenCover(isPresented: $showMap) {
            MapExploreView()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Good evening, \(MockData.userName)")
                .font(.display(28, weight: .bold))
                .foregroundStyle(Theme.ink)
            HStack(spacing: 5) {
                Image(systemName: "location.fill")
                    .font(.system(size: 11, weight: .semibold))
                Text(MockData.homeArea)
                    .font(.display(14, weight: .medium))
            }
            .foregroundStyle(Theme.inkSecondary)
        }
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.inkSecondary)
            Text("Search spots, lists, friends…")
                .font(.display(15, weight: .medium))
                .foregroundStyle(Theme.inkSecondary)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            Capsule(style: .continuous)
                .fill(Theme.surface)
                .shadow(color: Theme.ink.opacity(0.05), radius: 8, y: 4)
        )
    }

    private var categoryRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(SpotCategory.allCases) { category in
                    CategoryChip(category: category, isSelected: selectedCategory == category) {
                        Haptics.tap()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            selectedCategory = category
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.horizontal, -20)
    }

    private var nearbyRail: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Nearby", trailing: "See all")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(filteredSpots.prefix(5)) { spot in
                        SpotCard(spot: spot)
                            .scrollTransition { content, phase in
                                content
                                    .opacity(phase.isIdentity ? 1 : 0.55)
                                    .scaleEffect(phase.isIdentity ? 1 : 0.94)
                            }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 6)
            }
            .padding(.horizontal, -20)
        }
    }

    private var popularList: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Popular this week")
            VStack(spacing: 10) {
                ForEach(filteredSpots) { spot in
                    SpotRow(spot: spot)
                        .scrollTransition { content, phase in
                            content
                                .opacity(phase.isIdentity ? 1 : 0.4)
                                .scaleEffect(phase.isIdentity ? 1 : 0.96)
                        }
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.85), value: selectedCategory)
        }
    }

    private var mapButton: some View {
        Button {
            Haptics.thump()
            showMap = true
        } label: {
            HStack(spacing: 7) {
                Image(systemName: "map.fill")
                    .font(.system(size: 14, weight: .semibold))
                Text("Map")
                    .font(.display(15, weight: .bold))
            }
            .foregroundStyle(Theme.ink)
            .padding(.horizontal, 20)
            .padding(.vertical, 13)
            .background(
                Capsule(style: .continuous)
                    .fill(Theme.lime)
                    .shadow(color: Theme.lime.opacity(0.55), radius: 14, y: 6)
            )
        }
        .buttonStyle(SquishyButtonStyle())
    }
}

#Preview {
    ZStack {
        Theme.canvas.ignoresSafeArea()
        ExploreView()
    }
    .environment(AppModel())
}
