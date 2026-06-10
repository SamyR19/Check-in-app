import SwiftUI

/// Multi-step onboarding: welcome → account → circle → schedule → permissions → finishing.
/// Top progress bar + back chevron styled after the reference screenshots.
struct OnboardingFlow: View {
    @Environment(Store.self) private var store

    enum Step: Int, CaseIterable {
        case welcome, account, circle, schedule, permissions, finishing
    }

    @State private var step: Step = .welcome

    // Collected along the way, committed to the store at the end.
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var parents: [ParentContact] = Seed.parents
    @State private var schedule: [ScheduledCheckIn] = Seed.schedule

    private var progress: CGFloat {
        // Welcome doesn't count; finishing shows full.
        switch step {
        case .welcome: 0
        case .account: 0.25
        case .circle: 0.5
        case .schedule: 0.75
        case .permissions: 0.92
        case .finishing: 1
        }
    }

    var body: some View {
        ZStack {
            Theme.canvas.ignoresSafeArea()

            VStack(spacing: 0) {
                if step != .welcome && step != .finishing {
                    progressHeader
                        .transition(.opacity)
                }

                Group {
                    switch step {
                    case .welcome:
                        WelcomeStep { advance(to: .account) }
                    case .account:
                        AccountStep(name: $name, email: $email, password: $password) {
                            advance(to: .circle)
                        }
                    case .circle:
                        CircleStep(parents: $parents) { advance(to: .schedule) }
                    case .schedule:
                        ScheduleStep(schedule: $schedule) { advance(to: .permissions) }
                    case .permissions:
                        PermissionsStep { advance(to: .finishing) }
                    case .finishing:
                        FinishingStep {
                            store.completeOnboarding(
                                profile: UserProfile(name: name, email: email),
                                parents: parents,
                                schedule: schedule
                            )
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .id(step)
            }
        }
    }

    private var progressHeader: some View {
        HStack(spacing: 14) {
            Button {
                Haptics.tap()
                goBack()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Theme.ink)
                    .frame(width: 38, height: 38)
            }
            .buttonStyle(SquishyButtonStyle(scale: 0.85))

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.ink.opacity(0.07))
                    Capsule()
                        .fill(Theme.lime)
                        .frame(width: max(12, proxy.size.width * progress))
                        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: progress)
                }
            }
            .frame(height: 7)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 14)
    }

    private func advance(to next: Step) {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
            step = next
        }
    }

    private func goBack() {
        guard let previous = Step(rawValue: step.rawValue - 1) else { return }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
            step = previous
        }
    }
}

// MARK: - Welcome

private struct WelcomeStep: View {
    var onContinue: () -> Void
    @State private var floatUp = false

    private let cards: [(String, Color)] = [
        ("✅", Theme.limeSoft), ("📍", Theme.skySoft), ("🔋", Theme.amberSoft),
        ("🧭", Color(hex: 0xE5DCFF)), ("🆘", Theme.dangerSoft), ("📸", Color(hex: 0xF1E3CD)),
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Tilted card grid, like the welcome-screen reference.
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 3), spacing: 14) {
                ForEach(Array(cards.enumerated()), id: \.offset) { index, card in
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(card.1)
                        .frame(height: 110)
                        .overlay(Text(card.0).font(.system(size: 38)))
                        .rotationEffect(.degrees(index.isMultiple(of: 2) ? -3 : 3))
                        .offset(y: floatUp ? (index.isMultiple(of: 2) ? -5 : 5) : 0)
                        .appearStagger(index)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 40)
            .onAppear {
                withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                    floatUp = true
                }
            }

            Spacer()

            VStack(alignment: .leading, spacing: 10) {
                Text("Turn “trust me”\ninto proof")
                    .font(.display(34, weight: .bold))
                    .foregroundStyle(Theme.ink)
                Text("One tap says you're good — with location and battery attached. Your family stops guessing.")
                    .font(.display(15, weight: .medium))
                    .foregroundStyle(Theme.inkSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .appearStagger(3)

            VStack(spacing: 10) {
                PrimaryButton(title: "Get started", tint: Theme.lime, titleColor: Theme.ink, action: onContinue)
                Button {
                    Haptics.tap()
                    onContinue()
                } label: {
                    Text("I already have an account")
                        .font(.display(15, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Capsule().fill(Theme.ink.opacity(0.05)))
                }
                .buttonStyle(SquishyButtonStyle(scale: 0.97))
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 16)
            .appearStagger(4)
        }
    }
}

// MARK: - Finishing setup

private struct FinishingStep: View {
    var onDone: () -> Void

    @State private var spinning = false
    @State private var shownBullets = 0

    private let bullets: [(String, String)] = [
        ("lock", "Your data is fully private"),
        ("iphone", "Everything stays on this device"),
        ("clock.badge.checkmark", "Your check-ins are ready"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Circle()
                .trim(from: 0, to: 0.72)
                .stroke(Theme.ink, style: StrokeStyle(lineWidth: 9, lineCap: .round))
                .frame(width: 72, height: 72)
                .background(
                    Circle().stroke(Theme.ink.opacity(0.1), lineWidth: 9)
                )
                .rotationEffect(.degrees(spinning ? 360 : 0))
                .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: spinning)

            Text("Finishing setup")
                .font(.display(34, weight: .bold))
                .foregroundStyle(Theme.ink)
                .padding(.top, 36)

            VStack(alignment: .leading, spacing: 22) {
                ForEach(Array(bullets.enumerated()), id: \.offset) { index, bullet in
                    HStack(spacing: 16) {
                        Image(systemName: bullet.0)
                            .font(.system(size: 19, weight: .medium))
                            .frame(width: 28)
                        Text(bullet.1)
                            .font(.display(19, weight: .medium))
                    }
                    .foregroundStyle(Theme.ink)
                    .opacity(shownBullets > index ? 1 : 0)
                    .offset(y: shownBullets > index ? 0 : 10)
                }
            }
            .padding(.top, 44)

            Spacer()
            Spacer()
        }
        .onAppear {
            spinning = true
            for index in bullets.indices {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.85).delay(0.5 + Double(index) * 0.55)) {
                    shownBullets = index + 1
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
                Haptics.success()
                onDone()
            }
        }
    }
}
