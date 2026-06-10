import SwiftUI

/// Horizontal card used in the "Nearby" rail on Explore.
struct SpotCard: View {
    @Environment(AppModel.self) private var model
    let spot: Spot

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [spot.category.tint.opacity(0.55), spot.category.tint.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 110)
                    .overlay(
                        Text(spot.category.emoji)
                            .font(.system(size: 42))
                    )

                saveButton
                    .padding(8)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(spot.name)
                    .font(.display(15, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                HStack(spacing: 4) {
                    Text(spot.area)
                    Text("·")
                    Text(spot.distance)
                }
                .font(.display(12, weight: .medium))
                .foregroundStyle(Theme.inkSecondary)

                HStack(spacing: 3) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.lime)
                    Text(spot.rating, format: .number.precision(.fractionLength(1)))
                        .font(.display(12, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                }
                .padding(.top, 2)
            }
            .padding(12)
        }
        .frame(width: 170, alignment: .leading)
        .card(cornerRadius: 24)
    }

    private var saveButton: some View {
        Button {
            Haptics.tap()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.55)) {
                model.toggleSaved(spot)
            }
        } label: {
            Image(systemName: spot.isSaved ? "heart.fill" : "heart")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(spot.isSaved ? Theme.coral : Theme.ink)
                .symbolEffect(.bounce, value: spot.isSaved)
                .frame(width: 30, height: 30)
                .background(Circle().fill(.ultraThinMaterial))
        }
        .buttonStyle(SquishyButtonStyle(scale: 0.85))
    }
}

/// Full-width row used in vertical lists (Explore "Popular", Saved).
struct SpotRow: View {
    @Environment(AppModel.self) private var model
    let spot: Spot

    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(spot.category.tint.opacity(0.35))
                .frame(width: 54, height: 54)
                .overlay(Text(spot.category.emoji).font(.system(size: 24)))

            VStack(alignment: .leading, spacing: 3) {
                Text(spot.name)
                    .font(.display(16, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                Text("\(spot.area) · \(spot.distance)")
                    .font(.display(13, weight: .medium))
                    .foregroundStyle(Theme.inkSecondary)
            }

            Spacer()

            Button {
                Haptics.tap()
                withAnimation(.spring(response: 0.35, dampingFraction: 0.55)) {
                    model.toggleSaved(spot)
                }
            } label: {
                Image(systemName: spot.isSaved ? "heart.fill" : "heart")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(spot.isSaved ? Theme.coral : Theme.inkSecondary)
                    .symbolEffect(.bounce, value: spot.isSaved)
            }
            .buttonStyle(SquishyButtonStyle(scale: 0.8))
        }
        .padding(14)
        .card(cornerRadius: 22)
    }
}

/// Rounded category chip used on Explore and the map.
struct CategoryChip: View {
    let category: SpotCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Text(category.emoji).font(.system(size: 13))
                Text(category.rawValue)
                    .font(.display(13, weight: .semibold))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .foregroundStyle(isSelected ? Theme.canvas : Theme.ink)
            .background(
                Capsule(style: .continuous)
                    .fill(isSelected ? Theme.ink : Theme.surface)
                    .shadow(color: Theme.ink.opacity(0.05), radius: 6, y: 3)
            )
        }
        .buttonStyle(SquishyButtonStyle())
    }
}

/// Section heading with optional trailing accessory.
struct SectionHeader: View {
    let title: String
    var trailing: String? = nil

    var body: some View {
        HStack {
            Text(title)
                .font(.display(20, weight: .bold))
                .foregroundStyle(Theme.ink)
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(.display(13, weight: .semibold))
                    .foregroundStyle(Theme.inkSecondary)
            }
        }
    }
}
