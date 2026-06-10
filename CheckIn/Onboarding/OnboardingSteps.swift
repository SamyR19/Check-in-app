import SwiftUI

// MARK: - Create your account

struct AccountStep: View {
    @Binding var name: String
    @Binding var email: String
    @Binding var password: String
    var onContinue: () -> Void

    private var isValid: Bool {
        email.contains("@") && email.contains(".")
            && !name.trimmingCharacters(in: .whitespaces).isEmpty
            && password.count >= 8
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    Text("Create your account")
                        .font(.display(30, weight: .bold))
                        .foregroundStyle(Theme.ink)
                        .padding(.top, 12)

                    LabeledField(label: "Email", placeholder: "you@example.com",
                                 text: $email, keyboard: .emailAddress)
                    LabeledField(label: "Full Name", placeholder: "Your name", text: $name)
                    LabeledField(label: "Password", placeholder: "At least 8 characters",
                                 text: $password, isSecure: true)
                }
                .padding(.horizontal, 24)
            }

            PrimaryButton(title: "Continue", isEnabled: isValid, action: onContinue)
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
        }
    }
}

// MARK: - Your circle (who gets notified)

struct CircleStep: View {
    @Binding var parents: [ParentContact]
    var onContinue: () -> Void

    @State private var newName = ""

    private let suggestions: [(String, String)] = [
        ("Mom", "🌸"), ("Dad", "🧢"), ("Grandma", "🌷"), ("Uncle", "🎩"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Who's your circle?")
                            .font(.display(30, weight: .bold))
                            .foregroundStyle(Theme.ink)
                        Text("They see your green board, get nudged if you miss a check-in, and receive SOS alerts.")
                            .font(.display(15, weight: .medium))
                            .foregroundStyle(Theme.inkSecondary)
                    }
                    .padding(.top, 12)

                    privacyChip

                    VStack(spacing: 8) {
                        ForEach(parents) { parent in
                            HStack(spacing: 12) {
                                EmojiAvatar(emoji: parent.emoji, size: 42)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(parent.name)
                                        .font(.display(16, weight: .semibold))
                                        .foregroundStyle(Theme.ink)
                                    Text(parent.relation)
                                        .font(.display(13, weight: .medium))
                                        .foregroundStyle(Theme.inkSecondary)
                                }
                                Spacer()
                                Button {
                                    Haptics.tap()
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                        parents.removeAll { $0.id == parent.id }
                                    }
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(Theme.inkSecondary)
                                        .frame(width: 28, height: 28)
                                        .background(Circle().fill(Theme.canvas))
                                }
                                .buttonStyle(SquishyButtonStyle(scale: 0.8))
                            }
                            .padding(12)
                            .card(cornerRadius: 20)
                        }
                    }

                    suggestionChips
                }
                .padding(.horizontal, 24)
            }

            PrimaryButton(title: "Continue", isEnabled: !parents.isEmpty, action: onContinue)
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
        }
    }

    private var privacyChip: some View {
        HStack(spacing: 6) {
            Image(systemName: "lock.fill")
                .font(.system(size: 11, weight: .semibold))
            Text("Stored on this device only")
                .font(.display(13, weight: .semibold))
        }
        .foregroundStyle(Theme.sky)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(Capsule().fill(Theme.skySoft.opacity(0.4)))
    }

    private var suggestionChips: some View {
        HStack(spacing: 8) {
            ForEach(suggestions.filter { suggestion in
                !parents.contains { $0.name == suggestion.0 }
            }, id: \.0) { suggestion in
                Button {
                    Haptics.tap()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        parents.append(
                            ParentContact(name: suggestion.0, relation: "Family", emoji: suggestion.1)
                        )
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "plus")
                            .font(.system(size: 10, weight: .bold))
                        Text("\(suggestion.1) \(suggestion.0)")
                            .font(.display(13, weight: .semibold))
                    }
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, 13)
                    .padding(.vertical, 9)
                    .background(Capsule().fill(Theme.surface))
                }
                .buttonStyle(SquishyButtonStyle())
            }
        }
    }
}

// MARK: - Check-in schedule

struct ScheduleStep: View {
    @Binding var schedule: [ScheduledCheckIn]
    var onContinue: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("When will you\ncheck in?")
                            .font(.display(30, weight: .bold))
                            .foregroundStyle(Theme.ink)
                        Text("One tap at each time says “I'm good.” Miss one and we nudge you before anyone worries.")
                            .font(.display(15, weight: .medium))
                            .foregroundStyle(Theme.inkSecondary)
                    }
                    .padding(.top, 12)

                    VStack(spacing: 0) {
                        ForEach($schedule) { $slot in
                            HStack(spacing: 14) {
                                Toggle(isOn: $slot.isEnabled.animation(.spring(response: 0.35, dampingFraction: 0.8))) {
                                    Text(slot.label)
                                        .font(.display(16, weight: .semibold))
                                        .foregroundStyle(slot.isEnabled ? Theme.ink : Theme.inkSecondary)
                                }
                                .tint(Theme.lime)

                                DatePicker(
                                    "",
                                    selection: timeBinding($slot),
                                    displayedComponents: .hourAndMinute
                                )
                                .labelsHidden()
                                .disabled(!slot.isEnabled)
                                .opacity(slot.isEnabled ? 1 : 0.4)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)

                            if slot.id != schedule.last?.id {
                                Divider().padding(.leading, 16)
                            }
                        }
                    }
                    .card(cornerRadius: 24)
                }
                .padding(.horizontal, 24)
            }

            PrimaryButton(
                title: "Continue",
                isEnabled: schedule.contains(where: \.isEnabled),
                action: onContinue
            )
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
    }

    private func timeBinding(_ slot: Binding<ScheduledCheckIn>) -> Binding<Date> {
        Binding<Date>(
            get: {
                slot.wrappedValue.dateToday() ?? .now
            },
            set: { newDate in
                let parts = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                slot.wrappedValue.hour = parts.hour ?? 9
                slot.wrappedValue.minute = parts.minute ?? 0
            }
        )
    }
}

// MARK: - Permissions

struct PermissionsStep: View {
    @Environment(LocationService.self) private var location
    var onContinue: () -> Void

    @State private var notificationsRequested = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Two quick\npermissions")
                            .font(.display(30, weight: .bold))
                            .foregroundStyle(Theme.ink)
                        Text("Location is attached only when you check in or press SOS — never tracked in the background.")
                            .font(.display(15, weight: .medium))
                            .foregroundStyle(Theme.inkSecondary)
                    }
                    .padding(.top, 12)

                    permissionCard(
                        emoji: "📍",
                        title: "Location",
                        detail: "Stamped onto each check-in so your circle sees where you are.",
                        granted: location.isAuthorized,
                        buttonTitle: location.isAuthorized ? "Allowed" : "Allow"
                    ) {
                        location.requestPermission()
                    }

                    permissionCard(
                        emoji: "🔔",
                        title: "Notifications",
                        detail: "Gentle nudges when a check-in time arrives or slips by.",
                        granted: notificationsRequested,
                        buttonTitle: notificationsRequested ? "Done" : "Allow"
                    ) {
                        Permissions.requestNotifications()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            notificationsRequested = true
                        }
                    }
                }
                .padding(.horizontal, 24)
            }

            PrimaryButton(title: "Continue", action: onContinue)
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
        }
    }

    private func permissionCard(
        emoji: String, title: String, detail: String,
        granted: Bool, buttonTitle: String, action: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 14) {
            EmojiAvatar(emoji: emoji, size: 46, tint: Theme.canvas)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.display(16, weight: .bold))
                    .foregroundStyle(Theme.ink)
                Text(detail)
                    .font(.display(13, weight: .medium))
                    .foregroundStyle(Theme.inkSecondary)
            }

            Spacer()

            Button {
                Haptics.tap()
                action()
            } label: {
                HStack(spacing: 4) {
                    if granted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                    }
                    Text(buttonTitle)
                        .font(.display(14, weight: .bold))
                }
                .foregroundStyle(granted ? Theme.ink : .white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Capsule().fill(granted ? Theme.lime : Theme.ink))
            }
            .buttonStyle(SquishyButtonStyle())
        }
        .padding(14)
        .card(cornerRadius: 24)
    }
}
