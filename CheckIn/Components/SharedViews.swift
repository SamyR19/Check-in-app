import SwiftUI

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

/// Small colored status dot with a soft halo, used on the family board.
struct StatusDot: View {
    let status: MemberStatus

    private var color: Color {
        switch status {
        case .good: Theme.lime
        case .due: Theme.amber
        case .alert: Theme.danger
        }
    }

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 10, height: 10)
            .background(Circle().fill(color.opacity(0.3)).frame(width: 20, height: 20))
    }
}

/// Rounded gray input field matching the onboarding screenshots.
struct LabeledField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var isSecure = false
    var keyboard: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.display(15, weight: .medium))
                .foregroundStyle(Theme.inkSecondary)
            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                        .keyboardType(keyboard)
                        .textInputAutocapitalization(keyboard == .emailAddress ? .never : .words)
                        .autocorrectionDisabled()
                }
            }
            .font(.display(17, weight: .medium))
            .padding(.horizontal, 18)
            .frame(height: 58)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Theme.ink.opacity(0.04))
            )
        }
    }
}

/// Full-width primary pill button (ink when enabled, gray when disabled).
struct PrimaryButton: View {
    let title: String
    var isEnabled = true
    var tint: Color = Theme.ink
    var titleColor: Color = .white
    let action: () -> Void

    var body: some View {
        Button {
            guard isEnabled else { return }
            Haptics.thump()
            action()
        } label: {
            Text(title)
                .font(.display(17, weight: .bold))
                .foregroundStyle(isEnabled ? titleColor : Theme.inkSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    Capsule(style: .continuous)
                        .fill(isEnabled ? tint : Theme.ink.opacity(0.07))
                        .shadow(color: tint.opacity(isEnabled ? 0.25 : 0), radius: 12, y: 6)
                )
        }
        .buttonStyle(SquishyButtonStyle(scale: 0.97))
        .disabled(!isEnabled)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isEnabled)
    }
}

/// Emoji avatar in a soft circle.
struct EmojiAvatar: View {
    let emoji: String
    var size: CGFloat = 48
    var tint: Color = Theme.limeSoft

    var body: some View {
        Circle()
            .fill(tint)
            .frame(width: size, height: size)
            .overlay(Text(emoji).font(.system(size: size * 0.46)))
    }
}

/// Row used in the Activity feed and search results.
struct EventRow: View {
    let event: ActivityEvent

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            EmojiAvatar(emoji: event.kind.emoji, size: 44, tint: tint)

            VStack(alignment: .leading, spacing: 3) {
                Text(event.title)
                    .font(.display(15, weight: .bold))
                    .foregroundStyle(Theme.ink)
                Text(event.detail)
                    .font(.display(13, weight: .medium))
                    .foregroundStyle(Theme.inkSecondary)
            }

            Spacer()

            Text(event.date.formatted(date: .omitted, time: .shortened))
                .font(.display(12, weight: .semibold))
                .foregroundStyle(Theme.inkSecondary)
        }
        .padding(14)
        .card(cornerRadius: 22)
    }

    private var tint: Color {
        switch event.kind {
        case .checkIn: Theme.limeSoft
        case .missed: Theme.amberSoft
        case .ping: Theme.skySoft
        case .sos: Theme.dangerSoft
        case .recap: Color(hex: 0xF1E3CD)
        }
    }
}
