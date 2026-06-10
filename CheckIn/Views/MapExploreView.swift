import SwiftUI
import MapKit

/// Full-screen map of nearby spots, like the screenshot's map view —
/// floating filter pills on the bottom, close button up top.
struct MapExploreView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    enum Filter: String, CaseIterable, Identifiable {
        case all = "All"
        case saved = "Saved"
        case nearby = "Nearby"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .all: "sparkles"
            case .saved: "heart.fill"
            case .nearby: "location.fill"
            }
        }
    }

    @State private var filter: Filter = .all
    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: MockData.homeCoordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.045, longitudeDelta: 0.045)
        )
    )
    @State private var selectedSpot: Spot?

    private var visibleSpots: [Spot] {
        switch filter {
        case .all: model.spots
        case .saved: model.savedSpots
        case .nearby: MockData.nearby
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Map(position: $position) {
                ForEach(visibleSpots) { spot in
                    Annotation(spot.name, coordinate: spot.coordinate) {
                        marker(for: spot)
                    }
                }
            }
            .mapStyle(.standard(pointsOfInterest: .excludingAll))
            .ignoresSafeArea()

            VStack(spacing: 12) {
                if let selectedSpot {
                    spotPreview(selectedSpot)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                filterBar
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .overlay(alignment: .topTrailing) {
            closeButton
                .padding(.trailing, 20)
                .padding(.top, 8)
        }
    }

    private func marker(for spot: Spot) -> some View {
        Button {
            Haptics.tap()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                selectedSpot = selectedSpot?.id == spot.id ? nil : spot
            }
        } label: {
            Text(spot.category.emoji)
                .font(.system(size: 17))
                .frame(width: 38, height: 38)
                .background(
                    Circle()
                        .fill(.white)
                        .shadow(color: Theme.ink.opacity(0.2), radius: 6, y: 3)
                )
                .overlay(
                    Circle().strokeBorder(
                        selectedSpot?.id == spot.id ? Theme.lime : .clear,
                        lineWidth: 3
                    )
                )
                .scaleEffect(selectedSpot?.id == spot.id ? 1.18 : 1)
        }
        .buttonStyle(SquishyButtonStyle(scale: 0.85))
    }

    private func spotPreview(_ spot: Spot) -> some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(spot.category.tint.opacity(0.35))
                .frame(width: 48, height: 48)
                .overlay(Text(spot.category.emoji).font(.system(size: 22)))

            VStack(alignment: .leading, spacing: 2) {
                Text(spot.name)
                    .font(.display(16, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                Text("\(spot.area) · \(spot.distance)")
                    .font(.display(13, weight: .medium))
                    .foregroundStyle(Theme.inkSecondary)
            }

            Spacer()

            HStack(spacing: 3) {
                Image(systemName: "star.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.lime)
                Text(spot.rating, format: .number.precision(.fractionLength(1)))
                    .font(.display(13, weight: .semibold))
                    .foregroundStyle(Theme.ink)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.regularMaterial)
                .shadow(color: Theme.ink.opacity(0.12), radius: 14, y: 6)
        )
    }

    private var filterBar: some View {
        HStack(spacing: 6) {
            ForEach(Filter.allCases) { item in
                let isSelected = filter == item
                Button {
                    Haptics.tap()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        filter = item
                        selectedSpot = nil
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: item.icon)
                            .font(.system(size: 12, weight: .semibold))
                        Text(item.rawValue)
                            .font(.display(14, weight: .semibold))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 11)
                    .foregroundStyle(isSelected ? Theme.canvas : Theme.ink)
                    .background(
                        Capsule(style: .continuous)
                            .fill(isSelected ? Theme.ink : .clear)
                    )
                }
                .buttonStyle(SquishyButtonStyle())
            }
        }
        .padding(5)
        .background(
            Capsule(style: .continuous)
                .fill(.regularMaterial)
                .shadow(color: Theme.ink.opacity(0.15), radius: 14, y: 6)
        )
    }

    private var closeButton: some View {
        Button {
            Haptics.tap()
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Theme.ink)
                .frame(width: 38, height: 38)
                .background(
                    Circle()
                        .fill(.regularMaterial)
                        .shadow(color: Theme.ink.opacity(0.15), radius: 8, y: 4)
                )
        }
        .buttonStyle(SquishyButtonStyle(scale: 0.85))
    }
}

#Preview {
    MapExploreView()
        .environment(AppModel())
}
