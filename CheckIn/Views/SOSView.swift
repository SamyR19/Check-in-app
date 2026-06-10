import SwiftUI

/// Hold-to-activate SOS. Fires location to the whole circle, surfaces 112
/// and the nearest U.S. consulate. (Frontend only — the Twilio leg comes later.)
struct SOSView: View {
    @Environment(Store.self) private var store
    @Environment(LocationService.self) private var location
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @State private var holdProgress: CGFloat = 0
    @State private var isSent = false

    var body: some View {
        ZStack {
            Theme.ink.ignoresSafeArea()

            if isSent {
                sentState
                    .transition(.scale(scale: 0.85).combined(with: .opacity))
            } else {
                armState
                    .transition(.opacity)
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.8), value: isSent)
        .onAppear { location.refresh() }
    }

    // MARK: - Armed (hold to send)

    private var armState: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button {
                    Haptics.tap()
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 38, height: 38)
                        .background(Circle().fill(.white.opacity(0.12)))
                }
                .buttonStyle(SquishyButtonStyle(scale: 0.85))
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)

            Spacer()

            VStack(spacing: 10) {
                Text("Emergency")
                    .font(.display(30, weight: .bold))
                    .foregroundStyle(.white)
                Text("Hold the button for 3 seconds.\nYour location goes to everyone in your circle.")
                    .font(.display(15, weight: .medium))
                    .foregroundStyle(.white.opacity(0.65))
                    .multilineTextAlignment(.center)
            }

            Spacer()

            ZStack {
                Circle()
                    .stroke(.white.opacity(0.12), lineWidth: 10)
                    .frame(width: 210, height: 210)
                Circle()
                    .trim(from: 0, to: holdProgress)
                    .stroke(Theme.danger, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 210, height: 210)

                Circle()
                    .fill(Theme.danger)
                    .frame(width: 170, height: 170)
                    .shadow(color: Theme.danger.opacity(0.5), radius: 26, y: 10)
                    .overlay(
                        VStack(spacing: 6) {
                            Image(systemName: "light.beacon.max.fill")
                                .font(.system(size: 36, weight: .bold))
                            Text("HOLD")
                                .font(.display(15, weight: .heavy))
                                .kerning(2)
                        }
                        .foregroundStyle(.white)
                    )
                    .scaleEffect(holdProgress > 0 ? 0.94 : 1)
            }
            .onLongPressGesture(minimumDuration: 3, maximumDistance: 60) {
                fire()
            } onPressingChanged: { pressing in
                if pressing {
                    Haptics.thump()
                    withAnimation(.linear(duration: 3)) { holdProgress = 1 }
                } else {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { holdProgress = 0 }
                }
            }

            Spacer()
            Spacer()
        }
    }

    private func fire() {
        Haptics.success()
        store.triggerSOS(coordinate: location.lastLocation?.coordinate)
        withAnimation { isSent = true }
    }

    // MARK: - Sent

    private var sentState: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Theme.danger)
                    .frame(width: 88, height: 88)
                    .shadow(color: Theme.danger.opacity(0.5), radius: 20, y: 8)
                Image(systemName: "checkmark")
                    .font(.system(size: 36, weight: .heavy))
                    .foregroundStyle(.white)
            }

            VStack(spacing: 6) {
                Text("Alert sent")
                    .font(.display(28, weight: .bold))
                    .foregroundStyle(.white)
                Text(locationLine)
                    .font(.display(14, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(.white.opacity(0.65))
            }
            .padding(.top, 22)

            HStack(spacing: -8) {
                ForEach(store.parents) { parent in
                    EmojiAvatar(emoji: parent.emoji, size: 38, tint: .white)
                        .overlay(Circle().strokeBorder(Theme.ink, lineWidth: 2))
                }
                Text("notified")
                    .font(.display(13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.65))
                    .padding(.leading, 18)
            }
            .padding(.top, 16)

            VStack(spacing: 10) {
                actionRow(emoji: "📞", title: "Call 112", subtitle: "European emergency line") {
                    openURL(URL(string: "tel://112")!)
                }
                actionRow(emoji: "🇺🇸", title: "U.S. Consulate — Lisbon", subtitle: "Av. das Forças Armadas · 2.1 km") {
                    Haptics.tap()
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 36)

            Spacer()

            Button {
                Haptics.tap()
                dismiss()
            } label: {
                Text("I'm safe now")
                    .font(.display(16, weight: .bold))
                    .foregroundStyle(Theme.ink)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Capsule().fill(.white))
            }
            .buttonStyle(SquishyButtonStyle(scale: 0.97))
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }

    private var locationLine: String {
        guard let coordinate = location.lastLocation?.coordinate else {
            return "📍 Location unavailable — sent last known"
        }
        return String(format: "📍 %.4f, %.4f shared live", coordinate.latitude, coordinate.longitude)
    }

    private func actionRow(emoji: String, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Text(emoji).font(.system(size: 24))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.display(16, weight: .bold))
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.display(13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white.opacity(0.4))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(.white.opacity(0.1))
            )
        }
        .buttonStyle(SquishyButtonStyle(scale: 0.97))
    }
}

#Preview {
    SOSView()
        .environment(Store())
        .environment(LocationService())
}
