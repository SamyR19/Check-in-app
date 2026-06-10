import SwiftUI
import CoreLocation

/// The core loop: one tap says "I'm good" — location + battery attach automatically.
struct CheckInSheet: View {
    @Environment(Store.self) private var store
    @Environment(LocationService.self) private var location
    @Environment(\.dismiss) private var dismiss

    @State private var selectedMood = "😌"
    @State private var note = ""
    @State private var showSuccess = false
    @State private var attachShown = false

    private let moods = ["😌", "🤩", "😋", "🥱", "🎶", "🌅"]

    var body: some View {
        ZStack {
            Theme.canvas.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 22) {
                header
                attachments
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
                SuccessBurst(
                    title: "You're good ✓",
                    subtitle: "Your circle's board just went green"
                )
                .transition(.scale(scale: 0.7).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.8), value: showSuccess)
        .onAppear {
            location.refresh()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.3)) {
                attachShown = true
            }
        }
    }

    private var slotDescription: String {
        if let due = store.dueSlot {
            return "\(due.label) check-in · was due \(due.timeString)"
        }
        if let next = store.nextSlot {
            return "Early for \(next.slot.label.lowercased()) · \(next.slot.timeString)"
        }
        return "Unscheduled check-in"
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("I'm good")
                    .font(.display(26, weight: .bold))
                    .foregroundStyle(Theme.ink)
                Text(slotDescription)
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

    // MARK: - Auto-attached proof

    private var attachments: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ATTACHED AUTOMATICALLY")
                .font(.display(11, weight: .heavy))
                .foregroundStyle(Theme.inkSecondary)
                .kerning(1.2)

            VStack(spacing: 8) {
                attachmentRow(
                    emoji: "📍",
                    title: "Location",
                    value: locationValue,
                    ready: location.lastLocation != nil || !location.isAuthorized
                )
                attachmentRow(
                    emoji: "🔋",
                    title: "Battery",
                    value: "\(Device.batteryPercent())%",
                    ready: true
                )
                attachmentRow(
                    emoji: "🕐",
                    title: "Time",
                    value: Date.now.formatted(date: .omitted, time: .shortened),
                    ready: true
                )
            }
        }
    }

    private var locationValue: String {
        if !location.isAuthorized { return "Off — enable in Settings" }
        guard let last = location.lastLocation else { return "Locating…" }
        return String(format: "%.4f, %.4f", last.coordinate.latitude, last.coordinate.longitude)
    }

    private func attachmentRow(emoji: String, title: String, value: String, ready: Bool) -> some View {
        HStack(spacing: 12) {
            Text(emoji)
                .font(.system(size: 18))
                .frame(width: 38, height: 38)
                .background(Circle().fill(Theme.canvas))

            Text(title)
                .font(.display(15, weight: .semibold))
                .foregroundStyle(Theme.ink)

            Spacer()

            Text(value)
                .font(.display(13, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(Theme.inkSecondary)

            if ready {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Theme.lime)
            } else {
                ProgressView()
                    .controlSize(.small)
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Theme.surface))
        .opacity(attachShown ? 1 : 0)
        .offset(y: attachShown ? 0 : 8)
    }

    // MARK: - Mood + note

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
                            selectedMood = mood
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
        TextField("Add a note for the digest (optional)", text: $note, axis: .vertical)
            .font(.display(15, weight: .medium))
            .lineLimit(2...3)
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Theme.surface))
    }

    private var confirmButton: some View {
        PrimaryButton(title: "I'm good ✓", tint: Theme.lime, titleColor: Theme.ink) {
            Haptics.success()
            store.checkIn(
                coordinate: location.lastLocation?.coordinate,
                battery: Device.batteryPercent(),
                mood: selectedMood,
                note: note
            )
            withAnimation { showSuccess = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                dismiss()
            }
        }
    }
}

/// Checkmark + radiating dots shown after a successful action.
struct SuccessBurst: View {
    let title: String
    let subtitle: String
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
                Text(title)
                    .font(.display(24, weight: .bold))
                    .foregroundStyle(Theme.ink)
                Text(subtitle)
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
        .environment(Store())
        .environment(LocationService())
}
