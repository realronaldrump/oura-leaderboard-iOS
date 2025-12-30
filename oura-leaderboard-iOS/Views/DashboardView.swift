import SwiftUI

// MARK: - Dashboard View

struct DashboardView: View {
    @Environment(AppState.self) private var appState
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bgBase.ignoresSafeArea()
                
                if appState.isLoading && appState.activeStats == nil {
                    LoadingView()
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            // Hero Section
                            HeroSection()
                            
                            // Main Content
                            VStack(spacing: 24) {
                                // View Mode Selector & Leaderboard (if multiple users)
                                if appState.leaderboardData.count > 1 {
                                    LeaderboardSection()
                                }
                                
                                // Daily Content
                                if appState.viewMode == .daily {
                                    DailyContentView()
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 100)
                        }
                    }
                    .refreshable {
                        if let profile = appState.activeProfile {
                            await appState.loadDataForProfile(profile)
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    GradientText(text: "Davis Watches You Sleep", font: .system(size: 14, weight: .semibold))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            Task { await appState.login() }
                        } label: {
                            Label("Add User", systemImage: "plus")
                        }
                        
                        Button {
                            appState.logout()
                        } label: {
                            Label("Switch Profile", systemImage: "person.2")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
            }
            .toolbarBackground(Theme.bgBase.opacity(0.9), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .task {
            // Load data for all profiles
            await appState.loadAllProfilesData()
        }
    }
}

// MARK: - Loading View

private struct LoadingView: View {
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .stroke(Theme.accentCyan.opacity(0.2), lineWidth: 2)
                    .frame(width: 64, height: 64)
                
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(Theme.accentCyan, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .frame(width: 64, height: 64)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: UUID())
                
                Circle()
                    .trim(from: 0, to: 0.5)
                    .stroke(Theme.accentPurple, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .frame(width: 64, height: 64)
                    .rotationEffect(.degrees(90))
                    .animation(.linear(duration: 1.5).repeatForever(autoreverses: false), value: UUID())
            }
            
            Text("Loading your data...")
                .font(.system(size: 16))
                .foregroundStyle(Theme.textSecondary)
        }
    }
}

// MARK: - Hero Section

private struct HeroSection: View {
    @Environment(AppState.self) private var appState
    
    private var userName: String {
        appState.activeProfile?.displayName ?? "there"
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Greeting
            VStack(spacing: 8) {
                Text("Welcome back, ")
                    .foregroundStyle(Theme.textSecondary)
                + Text(userName)
                    .foregroundStyle(Theme.accentCyan)
                
                Text("Your Health Today")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
            }
            .padding(.top, 20)
            
            // Score orbs
            HStack(spacing: 20) {
                if let score = appState.currentReadiness?.score {
                    ScoreOrbView(score: score, label: "Readiness", color: Theme.readinessColor)
                }
                if let score = appState.currentSleep?.score {
                    ScoreOrbView(score: score, label: "Sleep", color: Theme.sleepColor)
                }
                if let score = appState.currentActivity?.score {
                    ScoreOrbView(score: score, label: "Activity", color: Theme.activityColor)
                }
            }
            .padding(.bottom, 32)
        }
    }
}

// MARK: - Leaderboard Section

private struct LeaderboardSection: View {
    @Environment(AppState.self) private var appState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            VStack(alignment: .leading, spacing: 4) {
                Text("Daily Standings")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                
                Text("See how you compare against others.")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.textSecondary)
            }
            
            // View mode picker
            ViewModePicker()
            
            // Content based on mode
            switch appState.viewMode {
            case .daily:
                LeaderboardTableView()
            case .versus:
                VersusView()
            case .history:
                HistoryView()
            }
        }
    }
}

// MARK: - View Mode Picker

private struct ViewModePicker: View {
    @Environment(AppState.self) private var appState
    
    var body: some View {
        @Bindable var state = appState
        
        HStack(spacing: 4) {
            ForEach(ViewMode.allCases, id: \.self) { mode in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        state.viewMode = mode
                    }
                } label: {
                    Text(mode.rawValue)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(appState.viewMode == mode ? modeColor(mode) : Theme.textMuted)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            appState.viewMode == mode 
                                ? modeColor(mode).opacity(0.2)
                                : Color.clear
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding(4)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func modeColor(_ mode: ViewMode) -> Color {
        switch mode {
        case .daily: return Theme.accentCyan
        case .versus: return Theme.accentPurple
        case .history: return Theme.accentOrange
        }
    }
}

// MARK: - Leaderboard Table

private struct LeaderboardTableView: View {
    @Environment(AppState.self) private var appState
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("User")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("Ready")
                    .frame(width: 50)
                Text("Sleep")
                    .frame(width: 50)
                Text("Active")
                    .frame(width: 50)
                Text("Avg")
                    .frame(width: 40)
            }
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(Theme.textMuted)
            .textCase(.uppercase)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.03))
            
            // Rows
            ForEach(Array(appState.leaderboardData.enumerated()), id: \.element.id) { index, entry in
                LeaderboardRow(entry: entry, rank: index + 1)
            }
        }
        .background(Theme.bgRaised)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Theme.borderSubtle, lineWidth: 1)
        )
    }
}

// MARK: - Leaderboard Row

private struct LeaderboardRow: View {
    let entry: LeaderboardEntry
    let rank: Int
    
    var body: some View {
        HStack {
            // Rank & Name
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(rankColor)
                        .frame(width: 24, height: 24)
                    Text("\(rank)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(rank <= 3 ? .black : Theme.textMuted)
                }
                
                Text(entry.name)
                    .font(.system(size: 14, weight: entry.isCurrentUser ? .semibold : .regular))
                    .foregroundStyle(entry.isCurrentUser ? Theme.accentCyan : Theme.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Scores
            Text("\(entry.readiness)")
                .foregroundStyle(Theme.readinessColor)
                .frame(width: 50)
            
            Text("\(entry.sleep)")
                .foregroundStyle(Theme.sleepColor)
                .frame(width: 50)
            
            Text("\(entry.activity)")
                .foregroundStyle(Theme.activityColor)
                .frame(width: 50)
            
            Text("\(entry.average)")
                .fontWeight(.bold)
                .foregroundStyle(Theme.textPrimary)
                .frame(width: 40)
        }
        .font(.system(size: 13, design: .monospaced))
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(entry.isCurrentUser ? Theme.accentCyan.opacity(0.05) : Color.clear)
        .overlay(
            Rectangle()
                .fill(entry.isCurrentUser ? Theme.accentCyan : Color.clear)
                .frame(width: 2),
            alignment: .leading
        )
    }
    
    private var rankColor: Color {
        switch rank {
        case 1: return Color.yellow
        case 2: return Color.gray
        case 3: return Color.orange
        default: return Theme.bgElevated
        }
    }
}

#Preview {
    DashboardView()
        .environment(AppState())
}
