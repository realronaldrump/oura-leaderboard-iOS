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
    }
}

#Preview {
    ContentView()
        .environment(AppState())
}
