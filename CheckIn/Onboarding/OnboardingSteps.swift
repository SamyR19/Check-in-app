import SwiftUI

// MARK: - Sign up (mock Supabase auth: email or Apple/Google)

struct SignUpStep: View {
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
                VStack(alignment: .leading, spacing: 20) {
                    Text("Create your account")
                        .font(.display(30, weight: .bold))
                        .foregroundStyle(Theme.ink)
                        .padding(.top, 12)

                    VStack(spacing: 10) {
                        providerButton(icon: "apple.logo", title: "Continue with Apple",
                                       foreground: .white, background: Theme.ink) {
                            autofill(provider: "icloud.com")
                        }
                        providerButton(icon: "globe", title: "Continue with Google",
                                       foreground: Theme.ink, background: Theme.surface) {
                            autofill(provider: "gmail.com")
                        }
                    }

                    HStack(spacing: 12) {
                        Rectangle().fill(Theme.ink.opacity(0.08)).frame(height: 1)
                        Text("or")
                            .font(.display(13, weight: .semibold))
                            .foregroundStyle(Theme.inkSecondary)
                        Rectangle().fill(Theme.ink.opacity(0.08)).frame(height: 1)
                    }

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

    private func providerButton(
        icon: String, title: String, foreground: Color, background: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                Text(title)
                    .font(.display(16, weight: .bold))
            }
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                Capsule(style: .continuous)
                    .fill(background)
                    .shadow(color: Theme.ink.opacity(0.06), radius: 8, y: 4)
            )
        }
        .buttonStyle(SquishyButtonStyle(scale: 0.97))
    }

    /// Mock OAuth: fills the profile the way a provider callback would, then continues.
    private func autofill(provider: String) {
        if name.trimmingCharacters(in: .whitespaces).isEmpty { name = "Sam Rivera" }
        if email.isEmpty {
            let handle = name.lowercased().replacingOccurrences(of: " ", with: ".")
            email = "\(handle)@\(provider)"
        }
        if password.isEmpty { password = UUID().uuidString }
        onContinue()
    }
}

// MARK: - Role

struct RoleStep: View {
    @Binding var role: UserRole
    var onContinue: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Who are you?")
                    .font(.display(30, weight: .bold))
                    .foregroundStyle(Theme.ink)
                Text("Tapped an invite link? Your role is set automatically — this is just in case.")
                    .font(.display(15, weight: .medium))
                    .foregroundStyle(Theme.inkSecondary)
            }
            .padding(.top, 12)

            roleCard(
                .teen, emoji: "🎒", title: "I'm traveling",
                detail: "Set the trip, check in on schedule, and invite your circle."
            )
            roleCard(
                .parent, emoji: "🛡️", title: "I'm a parent or guardian",
                detail: "Pair with your teen's trip and follow the live board."
            )

            Spacer()
        }
        .padding(.horizontal, 24)
    }

    private func roleCard(_ value: UserRole, emoji: String, title: String, detail: String) -> some View {
        Button {
            Haptics.thump()
            role = value
            onContinue()
        } label: {
            HStack(spacing: 16) {
                EmojiAvatar(emoji: emoji, size: 54,
                            tint: value == .teen ? Theme.limeSoft : Theme.skySoft)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.display(18, weight: .bold))
                        .foregroundStyle(Theme.ink)
                    Text(detail)
                        .font(.display(13, weight: .medium))
                        .foregroundStyle(Theme.inkSecondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Theme.inkSecondary)
            }
            .padding(18)
            .card(cornerRadius: 26)
        }
        .buttonStyle(SquishyButtonStyle(scale: 0.97))
    }
}

// MARK: - Create the trip

struct TripStep: View {
    @Binding var name: String
    @Binding var destination: String
    @Binding var emoji: String
    @Binding var startDate: Date
    @Binding var endDate: Date
    var onContinue: () -> Void

    private let emojis = ["🚂", "✈️", "🏝️", "⛰️", "🚐", "🛶"]

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && !destination.trimmingCharacters(in: .whitespaces).isEmpty
            && endDate >= startDate
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Create the trip")
                        .font(.display(30, weight: .bold))
                        .foregroundStyle(Theme.ink)
                        .padding(.top, 12)

                    HStack(spacing: 8) {
                        ForEach(emojis, id: \.self) { item in
                            Button {
                                Haptics.tap()
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    emoji = item
                                }
                            } label: {
                                Text(item)
                                    .font(.system(size: 22))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 46)
                                    .background(
                                        RoundedRectangle(cornerRadius: 13, style: .continuous)
                                            .fill(emoji == item ? Theme.limeSoft : Theme.surface)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 13, style: .continuous)
                                                    .strokeBorder(emoji == item ? Theme.lime : .clear, lineWidth: 2)
                                            )
                                    )
                            }
                            .buttonStyle(SquishyButtonStyle(scale: 0.85))
                        }
                    }

                    LabeledField(label: "Trip name", placeholder: "Iberia by rail", text: $name)
                    LabeledField(label: "Destination", placeholder: "Portugal & Spain", text: $destination)

                    VStack(spacing: 0) {
                        datePickerRow(label: "Starts", selection: $startDate)
                        Divider().padding(.leading, 16)
                        datePickerRow(label: "Ends", selection: $endDate)
                    }
                    .card(cornerRadius: 22)
                }
                .padding(.horizontal, 24)
            }

            PrimaryButton(title: "Continue", isEnabled: isValid, action: onContinue)
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
        }
    }

    private func datePickerRow(label: String, selection: Binding<Date>) -> some View {
        HStack {
            Text(label)
                .font(.display(15, weight: .semibold))
                .foregroundStyle(Theme.ink)
            Spacer()
            DatePicker("", selection: selection, displayedComponents: .date)
                .labelsHidden()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
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

// MARK: - Permissions (prime first, then fire the OS prompt)

struct PermissionsStep: View {
    @Environment(LocationService.self) private var location
    var onContinue: () -> Void

    @State private var notificationsRequested = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Before iOS asks…")
                            .font(.display(30, weight: .bold))
                            .foregroundStyle(Theme.ink)
                        Text("You'll see two system prompts next. Here's exactly what each one is for — no surprises, no background tracking.")
                            .font(.display(15, weight: .medium))
                            .foregroundStyle(Theme.inkSecondary)
                    }
                    .padding(.top, 12)

                    permissionCard(
                        emoji: "📍",
                        title: "Location — only when you act",
                        detail: "Stamped onto check-ins and SOS, the moment you tap. Never silently, never 24/7.",
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
