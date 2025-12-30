import SwiftUI

// MARK: - Login View

struct LoginView: View {
    @Environment(AppState.self) private var appState
    
    private var isShowingError: Binding<Bool> {
        Binding(
            get: { appState.errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    appState.errorMessage = nil
                }
            }
        )
    }
    
    var body: some View {
        ZStack {
            // Background
            Theme.bgBase.ignoresSafeArea()
            
            // Gradient mesh background
            Theme.gradientMesh
                .opacity(0.5)
                .ignoresSafeArea()
            
            // Floating orbs
            FloatingOrbView(size: 200, color: Theme.accentCyan.opacity(0.3), delay: 0)
                .position(x: 50, y: 150)
            
            FloatingOrbView(size: 150, color: Theme.accentPurple.opacity(0.3), delay: 2)
                .position(x: UIScreen.main.bounds.width - 80, y: 250)
            
            FloatingOrbView(size: 100, color: Theme.accentGreen.opacity(0.3), delay: 4)
                .position(x: 100, y: UIScreen.main.bounds.height - 200)
            
            // Content
            VStack(spacing: 0) {
                Spacer()
                
                // Title
                VStack(spacing: 8) {
                    GradientText(text: "Davis Watches", font: .system(size: 36, weight: .bold))
                    Text("You Sleep")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                }
                .padding(.bottom, 16)
                
                // Subtitle
                Text("Me sees you when you is sleeping. Me sees when you's awake. Me knows if you sleeps bad or good but mine will always be worse for goodness sake")
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 40)
                
                // Existing profiles
                if !appState.profiles.isEmpty {
                    VStack(spacing: 12) {
                        Text("SELECT A PROFILE")
                            .font(.system(size: 11, weight: .semibold))
                            .tracking(1)
                            .foregroundStyle(Theme.textMuted)
                        
                        ForEach(appState.profiles) { profile in
                            ProfileRow(profile: profile) {
                                appState.switchProfile(profile.id)
                            } onDelete: {
                                appState.removeProfile(id: profile.id)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }
                
                // Connect button
                Button {
                    Task {
                        await appState.login()
                    }
                } label: {
                    HStack {
                        Image(systemName: "link.circle.fill")
                        Text("Connect Oura Ring")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.primary)
                .padding(.horizontal, 24)
                .disabled(appState.authStatus == .loading)
                
                if appState.authStatus == .loading {
                    ProgressView()
                        .tint(Theme.accent)
                        .padding(.top, 16)
                }
                
                Spacer()
                
                // Footer
                Text("By connecting, you agree to share your activity, sleep, and readiness scores within this private leaderboard application.")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textDim)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 32)
            }
        }
        .alert("Login Error", isPresented: isShowingError) {
            Button("OK") {
                appState.errorMessage = nil
            }
        } message: {
            Text(appState.errorMessage ?? "Unknown error")
        }
    }
}

// MARK: - Profile Row

private struct ProfileRow: View {
    let profile: UserProfile
    let onSelect: () -> Void
    let onDelete: () -> Void
    
    @State private var showDeleteConfirm = false
    
    var body: some View {
        HStack(spacing: 8) {
            Button(action: onSelect) {
                HStack {
                    Text(profile.displayName)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Theme.textPrimary)
                    
                    Spacer()
                    
                    if let lastUpdated = profile.lastUpdated {
                        Text(formatDate(lastUpdated))
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.textDim)
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.textMuted)
                }
                .padding(16)
                .background(Theme.bgRaised)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Theme.borderSubtle, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            
            Button {
                showDeleteConfirm = true
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.accentRose)
                    .frame(width: 44, height: 44)
                    .background(Theme.bgRaised)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Theme.borderSubtle, lineWidth: 1)
                    )
            }
            .alert("Delete Profile?", isPresented: $showDeleteConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    onDelete()
                }
            } message: {
                Text("This will remove \(profile.displayName) from the leaderboard.")
            }
        }
    }
    
    private func formatDate(_ isoString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: isoString) else { return "" }
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "MMM d"
        return displayFormatter.string(from: date)
    }
}

#Preview {
    LoginView()
        .environment(AppState())
}
