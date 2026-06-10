import SwiftUI

/// The core action: pick a nearby spot, pick a mood, check in.
/// Ends with a springy success burst before dismissing.
struct CheckInSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    @State private var selectedSpot: Spot?
    @State private var selectedMood: String?
    @State private var note = ""
    @State private var showSuccess = false

    private let moods = ["🤩", "😋", "😌", "🥂", "🎶", "🌅"]

    var body: some View {
        ZStack {
            Theme.canvas.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 22) {
                grabberHeader
                spotPicker
                moodPicker
                noteField
                Spacer()
                confirmButton
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 16)
            .opacity(showSuccess ? 0 : 1)
            .scaleEffect(showSuccess ? 0.96 : 1)

            if showSuccess {
                SuccessBurst(spotName: selectedSpot?.name ?? "")
                    .transition(.scale(scale: 0.7).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.8), value: showSuccess)
    }

    private var grabberHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("Check in")
                    .font(.display(26, weight: .bold))
                    .foregroundStyle(Theme.ink)
                Text("Where are you right now?")
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
    }

    private var spotPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("NEARBY")
                .font(.display(11, weight: .heavy))
                .foregroundStyle(Theme.inkSecondary)
                .kerning(1.2)

            VStack(spacing: 8) {
                ForEach(MockData.nearby) { spot in
                    spotOption(spot)
                }
            }
        }
    }

    private func spotOption(_ spot: Spot) -> some View {
        let isSelected = selectedSpot?.id == spot.id
        return Button {
            Haptics.tap()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                selectedSpot = spot
            }
        } label: {
            HStack(spacing: 12) {
                Text(spot.category.emoji)
                    .font(.system(size: 20))
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(spot.category.tint.opacity(0.3)))

                VStack(alignment: .leading, spacing: 2) {
                    Text(spot.name)
                        .font(.display(15, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                    Text("\(spot.area) · \(spot.distance)")
                        .font(.display(12, weight: .medium))
                        .foregroundStyle(Theme.inkSecondary)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(isSelected ? Theme.lime : Theme.inkSecondary.opacity(0.4))
                    .symbolEffect(.bounce, value: isSelected)
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Theme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(isSelected ? Theme.lime : .clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(SquishyButtonStyle(scale: 0.97))
    }

    private var moodPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("MOOD")
                .font(.display(11, weight: .heavy))
                .foregroundStyle(Theme.inkSecondary)
                .kerning(1.2)

            HStack(spacing: 8) {
                ForEach(moods, id: \.self) { mood in
                    let isSelected = selectedMood == mood
                    Button {
                        Haptics.tap()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.55)) {
                            selectedMood = isSelected ? nil : mood
                        }
                    } label: {
                        Text(mood)
                            .font(.system(size: 24))
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(isSelected ? Theme.limeSoft : Theme.surface)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .strokeBorder(isSelected ? Theme.lime : .clear, lineWidth: 2)
                                    )
                            )
                            .scaleEffect(isSelected ? 1.08 : 1)
                    }
                    .buttonStyle(SquishyButtonStyle(scale: 0.85))
                }
            }
        }
    }

    private var noteField: some View {
        TextField("Add a note (optional)", text: $note, axis: .vertical)
            .font(.display(15, weight: .medium))
            .lineLimit(2...3)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Theme.surface)
            )
    }

    private var confirmButton: some View {
        Button {
            guard selectedSpot != nil else { return }
            Haptics.success()
            model.recordCheckIn()
            withAnimation { showSuccess = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                dismiss()
            }
        } label: {
            Text(selectedSpot == nil ? "Pick a spot" : "Check in")
                .font(.display(17, weight: .bold))
                .foregroundStyle(selectedSpot == nil ? Theme.inkSecondary : .white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    Capsule(style: .continuous)
                        .fill(selectedSpot == nil ? Theme.surface : Theme.ink)
                        .shadow(
                            color: Theme.ink.opacity(selectedSpot == nil ? 0 : 0.25),
                            radius: 12, y: 6
                        )
                )
        }
        .buttonStyle(SquishyButtonStyle(scale: 0.97))
        .disabled(selectedSpot == nil)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: selectedSpot == nil)
    }
}

/// Checkmark + radiating dots shown after a successful check-in.
private struct SuccessBurst: View {
    let spotName: String
    @State private var burst = false

    var body: some View {
        VStack(spacing: 18) {
            ZStack {
                ForEach(0..<8, id: \.self) { index in
                    Circle()
                        .fill(index.isMultiple(of: 2) ? Theme.lime : Theme.sky)
                        .frame(width: 9, height: 9)
                        .offset(y: burst ? -64 : 0)
                        .rotationEffect(.degrees(Double(index) / 8 * 360))
                        .opacity(burst ? 0 : 1)
                }

                Circle()
                    .fill(Theme.lime)
                    .frame(width: 92, height: 92)
                    .shadow(color: Theme.lime.opacity(0.5), radius: 18, y: 8)
                Image(systemName: "checkmark")
                    .font(.system(size: 38, weight: .heavy))
                    .foregroundStyle(Theme.ink)
                    .scaleEffect(burst ? 1 : 0.3)
            }

            VStack(spacing: 4) {
                Text("You're in!")
                    .font(.display(24, weight: .bold))
                    .foregroundStyle(Theme.ink)
                Text(spotName)
                    .font(.display(15, weight: .semibold))
                    .foregroundStyle(Theme.inkSecondary)
            }
            .opacity(burst ? 1 : 0)
            .offset(y: burst ? 0 : 8)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.05)) {
                burst = true
            }
        }
    }
}

#Preview {
    CheckInSheet()
        .environment(AppModel())
}
