import SwiftUI

@main
struct CheckInApp: App {
    @State private var store = Store()
    @State private var location = LocationService()

    init() {
        UIDevice.current.isBatteryMonitoringEnabled = true
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if store.hasOnboarded {
                    RootView()
                        .transition(.opacity.combined(with: .scale(scale: 1.02)))
                } else {
                    OnboardingFlow()
                        .transition(.opacity)
                }
            }
            .environment(store)
            .environment(location)
            .preferredColorScheme(.light)
            .animation(.spring(response: 0.6, dampingFraction: 0.85), value: store.hasOnboarded)
        }
    }
}
