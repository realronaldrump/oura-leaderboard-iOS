import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState
    
    var body: some View {
        Group {
            if appState.activeProfile != nil {
                EnhancedDashboardView()
            } else {
                EnhancedLoginView()
            }
        }
        .background(Theme.bgBase)
        .task {
            // Load disk cache for instant UI, then refresh stale data
            await appState.bootstrap()
        }
    }
}

#Preview {
    ContentView()
        .environment(AppState())
}
