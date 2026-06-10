import SwiftUI

// MARK: - Invite codes (teen) — short-lived, tied to the trip

struct InviteStep: View {
    @Binding var codes: [InviteCode]
    let tripName: String
    var onContinue: () -> Void

    @State private var copiedID: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Invite your circle")
                            .font(.display(30, weight: .bold))
                            .foregroundStyle(Theme.ink)
                        Text("Codes are tied to “\(tripName.isEmpty ? "your trip" : tripName)” and expire in 24 hours — nobody random can pair with you.")
                            .font(.display(15, weight: .medium))
                            .foregroundStyle(Theme.inkSecondary)
                    }
                    .padding(.top, 12)

                    ForEach(codes) { invite in
                        inviteCard(invite)
                    }
                }
                .padding(.horizontal, 24)
            }

            PrimaryButton(title: "Continue", action: onContinue)
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
        }
        .onAppear {
            if codes.isEmpty {
                codes = [.generate(for: .friends), .generate(for: .parents)]
            }
        }
    }

    private func inviteCard(_ invite: InviteCode) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                EmojiAvatar(emoji: invite.audience.emoji, size: 44,
                            tint: invite.audience == .friends ? Theme.limeSoft : Theme.skySoft)
                VStack(alignment: .leading, spacing: 2) {
                    Text(invite.audience.title)
                        .font(.display(16, weight: .bold))
                        .foregroundStyle(Theme.ink)
                    Text(invite.audience.detail)
                        .font(.display(13, weight: .medium))
                        .foregroundStyle(Theme.inkSecondary)
                }
                Spacer()
            }

            HStack(spacing: 10) {
                Text(invite.displayCode)
                    .font(.system(size: 26, weight: .heavy, design: .monospaced))
                    .foregroundStyle(Theme.ink)
                    .kerning(2)
                    .frame(maxWidth: .infinity)
                    .frame(height: 58)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Theme.canvas)
                    )

                Button {
                    Haptics.success()
                    UIPasteboard.general.string = invite.code
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        copiedID = invite.id
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                        withAnimation { copiedID = nil }
                    }
                } label: {
                    Image(systemName: copiedID == invite.id ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(copiedID == invite.id ? Theme.ink : .white)
                        .frame(width: 58, height: 58)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(copiedID == invite.id ? Theme.lime : Theme.ink)
                        )
                        .symbolEffect(.bounce, value: copiedID == invite.id)
                }
                .buttonStyle(SquishyButtonStyle(scale: 0.88))
            }

            HStack {
                HStack(spacing: 5) {
                    Image(systemName: "clock")
                        .font(.system(size: 11, weight: .semibold))
                    Text("Expires in 24h")
                        .font(.display(12, weight: .semibold))
                }
                .foregroundStyle(Theme.amber)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Capsule().fill(Theme.amberSoft.opacity(0.6)))

                Spacer()

                ShareLink(item: "Join my trip “\(tripName)” on I'm Good — code \(invite.code) (expires in 24h)") {
                    HStack(spacing: 5) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Send link")
                            .font(.display(13, weight: .bold))
                    }
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Theme.canvas))
                }
                .buttonStyle(SquishyButtonStyle())
            }
        }
        .padding(16)
        .card(cornerRadius: 26)
    }
}

// MARK: - Dry run (teen) — see the whole loop work before the trip

struct DryRunStep: View {
    var onContinue: () -> Void

    private enum Phase { case pending, running, done }
    @State private var phases: [Phase] = [.pending, .pending, .pending]
    @State private var started = false

    private var allDone: Bool { phases.allSatisfy { $0 == .done } }

    private let steps: [(String, String, String)] = [
        ("✅", "Test check-in", "Location + battery attach, board flips green"),
        ("📳", "Test ping", "Your circle's phones buzz — right now"),
        ("🆘", "Test SOS (simulated)", "Alert path verified, nothing actually fires"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Dry run")
                    .font(.display(30, weight: .bold))
                    .foregroundStyle(Theme.ink)
                Text("Watch the whole loop work once before the trip — so the first real check-in is boring.")
                    .font(.display(15, weight: .medium))
                    .foregroundStyle(Theme.inkSecondary)
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)

            VStack(spacing: 10) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    stepRow(emoji: step.0, title: step.1, detail: step.2, phase: phases[index])
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 22)

            Spacer()

            VStack(spacing: 10) {
                if !allDone {
                    PrimaryButton(
                        title: started ? "Running…" : "Start dry run",
                        isEnabled: !started,
                        tint: Theme.lime, titleColor: Theme.ink
                    ) {
                        run()
                    }
                }
                PrimaryButton(title: allDone ? "Continue" : "Skip for now", isEnabled: true,
                              tint: allDone ? Theme.ink : Theme.surface,
                              titleColor: allDone ? .white : Theme.inkSecondary,
                              action: onContinue)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
    }

    private func stepRow(emoji: String, title: String, detail: String, phase: Phase) -> some View {
        HStack(spacing: 14) {
            EmojiAvatar(emoji: emoji, size: 46, tint: phase == .done ? Theme.limeSoft : Theme.canvas)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.display(16, weight: .bold))
                    .foregroundStyle(Theme.ink)
                Text(detail)
                    .font(.display(13, weight: .medium))
                    .foregroundStyle(Theme.inkSecondary)
            }

            Spacer()

            switch phase {
            case .pending:
                Circle()
                    .strokeBorder(Theme.ink.opacity(0.15), lineWidth: 2)
                    .frame(width: 24, height: 24)
            case .running:
                ProgressView()
                    .controlSize(.regular)
            case .done:
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(Theme.lime)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Theme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(phase == .running ? Theme.lime : .clear, lineWidth: 2)
                )
                .shadow(color: Theme.ink.opacity(0.05), radius: 10, y: 5)
        )
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: phase == .done)
    }

    private func run() {
        started = true
        Haptics.thump()
        for index in phases.indices {
            let start = Double(index) * 1.4
            DispatchQueue.main.asyncAfter(deadline: .now() + start) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    phases[index] = .running
                }
                Haptics.tap()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + start + 1.2) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.65)) {
                    phases[index] = .done
                }
                if index == phases.count - 1 {
                    Haptics.success()
                } else {
                    Haptics.thump()
                }
            }
        }
    }
}

// MARK: - Pairing (parent) — code boxes like the referral reference

struct PairStep: View {
    @Binding var code: String
    var onContinue: () -> Void

    @FocusState private var focused: Bool
    @State private var isLinked = false

    private var isComplete: Bool { code.count == 6 }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Pairing code")
                    .font(.display(30, weight: .bold))
                    .foregroundStyle(Theme.ink)
                Text("Enter the 6-character code from your teen's invite. Codes are short-lived and tied to their trip.")
                    .font(.display(15, weight: .medium))
                    .foregroundStyle(Theme.inkSecondary)
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)

            codeBoxes
                .padding(.horizontal, 24)
                .padding(.top, 28)
                .onTapGesture { focused = true }

            if isLinked {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 15))
                    Text("Linked to “Iberia by rail” ✓")
                        .font(.display(15, weight: .bold))
                }
                .foregroundStyle(Theme.ink)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Capsule().fill(Theme.lime))
                .frame(maxWidth: .infinity)
                .padding(.top, 24)
                .transition(.scale(scale: 0.8).combined(with: .opacity))
            }

            Spacer()

            PrimaryButton(title: isLinked ? "Continue" : "Link to trip", isEnabled: isComplete) {
                if isLinked {
                    onContinue()
                } else {
                    Haptics.success()
                    focused = false
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) {
                        isLinked = true
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
        .onAppear { focused = true }
    }

    private var codeBoxes: some View {
        ZStack {
            TextField("", text: $code)
                .focused($focused)
                .keyboardType(.asciiCapable)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .opacity(0.01)
                .onChange(of: code) { _, newValue in
                    let filtered = newValue.uppercased().filter { $0.isLetter || $0.isNumber }
                    code = String(filtered.prefix(6))
                    if code.count == 6 { Haptics.thump() }
                }

            HStack(spacing: 8) {
                ForEach(0..<6, id: \.self) { index in
                    let chars = Array(code)
                    let isActive = focused && index == code.count
                    Text(index < chars.count ? String(chars[index]) : "")
                        .font(.system(size: 26, weight: .heavy, design: .monospaced))
                        .foregroundStyle(Theme.ink)
                        .frame(maxWidth: .infinity)
                        .frame(height: 64)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Theme.surface)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .strokeBorder(isActive ? Theme.lime : Theme.ink.opacity(0.06),
                                                      lineWidth: isActive ? 2.5 : 1)
                                )
                                .shadow(color: Theme.ink.opacity(0.04), radius: 6, y: 3)
                        )
                }
            }
            .allowsHitTesting(false)
        }
    }
}

// MARK: - Expectations (parent) — the trust moment

struct ExpectationsStep: View {
    var onContinue: () -> Void

    private let sees: [(String, String)] = [
        ("✅", "Scheduled check-ins, with location + battery attached"),
        ("📍", "Their location — when they share it, or in an SOS"),
        ("📸", "An evening digest: one photo + one line"),
    ]

    private let doesNotSee: [(String, String)] = [
        ("🚫", "No silent 24/7 tracking — ever"),
        ("🔕", "No pings without their one-tap approval"),
        ("💬", "No messages, browsing, or anything else on their phone"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("What you'll see —\nand what you won't")
                            .font(.display(30, weight: .bold))
                            .foregroundStyle(Theme.ink)
                        Text("The limits are the point. Restraint is what makes them keep checking in.")
                            .font(.display(15, weight: .medium))
                            .foregroundStyle(Theme.inkSecondary)
                    }
                    .padding(.top, 12)

                    expectationGroup(title: "YOU'LL SEE", items: sees, tint: Theme.limeSoft)
                    expectationGroup(title: "YOU WON'T", items: doesNotSee, tint: Theme.dangerSoft)
                }
                .padding(.horizontal, 24)
            }

            PrimaryButton(title: "I understand", action: onContinue)
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
        }
    }

    private func expectationGroup(title: String, items: [(String, String)], tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.display(11, weight: .heavy))
                .foregroundStyle(Theme.inkSecondary)
                .kerning(1.2)

            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    HStack(spacing: 12) {
                        EmojiAvatar(emoji: item.0, size: 38, tint: tint)
                        Text(item.1)
                            .font(.display(14, weight: .semibold))
                            .foregroundStyle(Theme.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)

                    if index < items.count - 1 {
                        Divider().padding(.leading, 64)
                    }
                }
            }
            .card(cornerRadius: 24)
        }
    }
}

// MARK: - Alerts (parent) — primed notifications

struct ParentAlertsStep: View {
    var onContinue: () -> Void
    @State private var requested = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Turn on alerts")
                    .font(.display(30, weight: .bold))
                    .foregroundStyle(Theme.ink)
                Text("This is the one permission that matters for you — escalations and SOS only reach you if notifications are on.")
                    .font(.display(15, weight: .medium))
                    .foregroundStyle(Theme.inkSecondary)
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)

            HStack(spacing: 14) {
                EmojiAvatar(emoji: "🔔", size: 46, tint: Theme.canvas)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Notifications")
                        .font(.display(16, weight: .bold))
                        .foregroundStyle(Theme.ink)
                    Text("Missed check-in escalations · SOS alerts · evening digest")
                        .font(.display(13, weight: .medium))
                        .foregroundStyle(Theme.inkSecondary)
                }
                Spacer()
                Button {
                    Haptics.tap()
                    Permissions.requestNotifications()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        requested = true
                    }
                } label: {
                    HStack(spacing: 4) {
                        if requested {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                        }
                        Text(requested ? "Done" : "Allow")
                            .font(.display(14, weight: .bold))
                    }
                    .foregroundStyle(requested ? Theme.ink : .white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(requested ? Theme.lime : Theme.ink))
                }
                .buttonStyle(SquishyButtonStyle())
            }
            .padding(14)
            .card(cornerRadius: 24)
            .padding(.horizontal, 24)
            .padding(.top, 22)

            Spacer()

            PrimaryButton(title: "Continue", action: onContinue)
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
        }
    }
}
