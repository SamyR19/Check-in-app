import SwiftUI

@main
struct CheckInApp: App {
    @State private var store: Store
    @State private var location = LocationService()
    /// Set by the screenshot UI tests via launch argument "-uiTestScreen <name>".
    private let testScreen: String?

    init() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        let screen = UserDefaults.standard.string(forKey: "uiTestScreen")
        testScreen = screen
        let store = Store()
        if let screen {
            Self.configure(store, for: screen)
        }
        _store = State(initialValue: store)
    }

    var body: some Scene {
        WindowGroup {
            content
                .environment(store)
                .environment(location)
                .preferredColorScheme(.light)
                .animation(.spring(response: 0.6, dampingFraction: 0.85), value: store.hasOnboarded)
        }
    }

    @ViewBuilder
    private var content: some View {
        if let testScreen {
            testView(testScreen)
        } else if store.hasOnboarded {
            RootView()
                .transition(.opacity.combined(with: .scale(scale: 1.02)))
        } else {
            OnboardingFlow()
                .transition(.opacity)
        }
    }

    // MARK: - Screenshot-test routing

    @ViewBuilder
    private func testView(_ screen: String) -> some View {
        switch screen {
        case "01-welcome": OnboardingFlow(initialStep: .welcome)
        case "02-signup": OnboardingFlow(initialStep: .signUp)
        case "03-role": OnboardingFlow(initialStep: .role)
        case "04-trip": OnboardingFlow(initialStep: .trip)
        case "05-schedule": OnboardingFlow(initialStep: .schedule)
        case "06-permissions": OnboardingFlow(initialStep: .permissions)
        case "07-invite": OnboardingFlow(initialStep: .invite)
        case "08-dryrun": OnboardingFlow(initialStep: .dryRun)
        case "09-pair": OnboardingFlow(initialRole: .parent, initialStep: .pair)
        case "10-expectations": OnboardingFlow(initialRole: .parent, initialStep: .expectations)
        case "11-parent-alerts": OnboardingFlow(initialRole: .parent, initialStep: .parentAlerts)
        case "12-teen-home": RootView()
        case "13-teen-trip": RootView(initialTab: .plan)
        case "14-teen-activity": RootView(initialTab: .activity)
        case "15-teen-profile": RootView(initialTab: .profile)
        case "16-checkin": ZStack { Theme.canvas.ignoresSafeArea(); CheckInSheet() }
        case "17-sos": SOSView()
        case "18-search": SearchView()
        case "19-parent-board": RootView()
        case "20-ping": ZStack { Theme.canvas.ignoresSafeArea(); PingSheet() }
        case "21-parent-profile": RootView(initialTab: .profile)
        default:
            OnboardingFlow()
        }
    }

    private static func configure(_ store: Store, for screen: String) {
        store.reset()
        let teenScreens = ["12-teen-home", "13-teen-trip", "14-teen-activity",
                           "15-teen-profile", "16-checkin", "17-sos", "18-search"]
        let parentScreens = ["19-parent-board", "20-ping", "21-parent-profile"]

        if teenScreens.contains(screen) {
            store.completeTeenOnboarding(
                profile: UserProfile(name: "Sam Rivera", email: "sam@icloud.com"),
                trip: Seed.defaultTrip,
                schedule: Seed.schedule,
                inviteCodes: [.generate(for: .friends), .generate(for: .parents)]
            )
        } else if parentScreens.contains(screen) {
            store.completeParentOnboarding(
                profile: UserProfile(name: "Alex Rivera", email: "alex@icloud.com"),
                pairingCode: "7KQ2MF"
            )
        }
    }
}
