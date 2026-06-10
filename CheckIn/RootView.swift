import SwiftUI

struct RootView: View {
    @Environment(Store.self) private var store
    @State private var selectedTab: AppTab = .home
    @State private var showCheckIn = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Theme.canvas.ignoresSafeArea()

            Group {
                switch selectedTab {
                case .home: HomeView()
                case .plan: PlanView()
                case .activity: ActivityView()
                case .profile: ProfileView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .transition(.opacity.combined(with: .scale(scale: 0.985)))
            .id(selectedTab)

            FloatingTabBar(selection: $selectedTab, isCheckInDue: store.dueSlot != nil) {
                showCheckIn = true
            }
            .padding(.bottom, 4)
        }
        .sheet(isPresented: $showCheckIn) {
            CheckInSheet()
                .presentationDetents([.large])
                .presentationCornerRadius(32)
        }
    }
}

#Preview {
    RootView()
        .environment(Store())
        .environment(LocationService())
}
