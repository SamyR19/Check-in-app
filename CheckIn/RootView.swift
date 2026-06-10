import SwiftUI

struct RootView: View {
    @State private var selectedTab: AppTab = .explore
    @State private var showCheckIn = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Theme.canvas.ignoresSafeArea()

            Group {
                switch selectedTab {
                case .explore: ExploreView()
                case .saved: SavedView()
                case .activity: ActivityView()
                case .profile: ProfileView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .transition(.opacity.combined(with: .scale(scale: 0.985)))
            .id(selectedTab)

            FloatingTabBar(selection: $selectedTab) {
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
        .environment(AppModel())
}
