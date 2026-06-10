import SwiftUI

struct RootView: View {
    @Environment(Store.self) private var store
    @State private var selectedTab: AppTab = .home
    @State private var showCenterAction = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Theme.canvas.ignoresSafeArea()

            Group {
                switch selectedTab {
                case .home:
                    if store.isParent {
                        ParentHomeView()
                    } else {
                        HomeView()
                    }
                case .plan: PlanView()
                case .activity: ActivityView()
                case .profile: ProfileView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .transition(.opacity.combined(with: .scale(scale: 0.985)))
            .id(selectedTab)

            FloatingTabBar(
                selection: $selectedTab,
                role: store.role,
                isCheckInDue: store.dueSlot != nil
            ) {
                showCenterAction = true
            }
            .padding(.bottom, 4)
        }
        .sheet(isPresented: $showCenterAction) {
            Group {
                if store.isParent {
                    PingSheet()
                } else {
                    CheckInSheet()
                }
            }
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
