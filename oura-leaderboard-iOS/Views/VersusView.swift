import SwiftUI

// MARK: - Versus View

struct VersusView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedUserA: Int = 0
    @State private var selectedUserB: Int = 1
    
    private var userA: UserProfile? {
        appState.profiles[safe: selectedUserA]
    }
    
    private var userB: UserProfile? {
        appState.profiles[safe: selectedUserB]
    }
    
    private var statsA: DailyStats? {
        guard let id = userA?.id else { return nil }
        return appState.dailyStats[id]
    }
    
    private var statsB: DailyStats? {
        guard let id = userB?.id else { return nil }
        return appState.dailyStats[id]
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // User Selectors
            VersusHeader()
            
            // AI Insights Button
            AIInsightsSection()
            
            // Comparison Groups
            ComparisonGroupsView(statsA: statsA, statsB: statsB)
        }
    }
}

// MARK: - Versus Header

private struct VersusHeader: View {
    @Environment(AppState.self) private var appState
    
    var body: some View {
        HStack {
            // User A
            if let profile = appState.profiles.first {
                UserAvatar(name: profile.displayName, color: Theme.accentGreen)
            }
            
            Spacer()
            
            // VS Badge
            ZStack {
                Circle()
                    .fill(Theme.bgElevated)
                    .frame(width: 48, height: 48)
                    .overlay(
                        Circle()
                            .stroke(Theme.borderDefault, lineWidth: 1)
                    )
                
                Text("VS")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
            }
            
            Spacer()
            
            // User B
            if let profile = appState.profiles[safe: 1] {
                UserAvatar(name: profile.displayName, color: Theme.accentPurple)
            }
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - User Avatar

private struct UserAvatar: View {
    let name: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 64, height: 64)
                    .overlay(
                        Circle()
                            .stroke(color.opacity(0.5), lineWidth: 2)
                    )
                
                Text(String(name.prefix(1)).uppercased())
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(color)
            }
            
            Text(name)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Theme.textPrimary)
        }
    }
}

// MARK: - AI Insights Section

private struct AIInsightsSection: View {
    @Environment(AppState.self) private var appState
    
    var body: some View {
        VStack(spacing: 16) {
            Button {
                Task {
                    await appState.generateAIBriefing()
                }
            } label: {
                HStack {
                    Image(systemName: "sparkles")
                    Text(appState.isGeneratingBriefing ? "Generating..." : "Generate AI Insights")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.primary)
            .disabled(appState.isGeneratingBriefing || appState.profiles.count < 2)
            
            // AI Briefing Display
            if let briefing = appState.aiBriefing {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundStyle(Theme.accentCyan)
                        Text("AI INSIGHTS")
                            .font(.system(size: 11, weight: .semibold))
                            .tracking(1)
                            .foregroundStyle(Theme.textMuted)
                    }
                    
                    Text(briefing)
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.textSecondary)
                        .lineSpacing(4)
                }
                .glassCard()
            }
        }
    }
}

// MARK: - Comparison Groups

private struct ComparisonGroupsView: View {
    let statsA: DailyStats?
    let statsB: DailyStats?
    
    private var sleepA: DailySleep? { statsA?.sleep.first }
    private var sleepB: DailySleep? { statsB?.sleep.first }
    private var readinessA: DailyReadiness? { statsA?.readiness.first }
    private var readinessB: DailyReadiness? { statsB?.readiness.first }
    private var activityA: DailyActivity? { statsA?.activity.first }
    private var activityB: DailyActivity? { statsB?.activity.first }
    private var sessionA: SleepSession? { statsA?.session.first }
    private var sessionB: SleepSession? { statsB?.session.first }
    
    var body: some View {
        VStack(spacing: 12) {
            // Readiness Group
            MetricComparisonGroupView(
                title: "Readiness",
                scoreA: readinessA?.score,
                scoreB: readinessB?.score,
                metrics: [
                    ComparisonMetric(label: "HRV Balance", valA: readinessA?.contributors.hrvBalance, valB: readinessB?.contributors.hrvBalance),
                    ComparisonMetric(label: "Resting HR", valA: readinessA?.contributors.restingHeartRate, valB: readinessB?.contributors.restingHeartRate),
                    ComparisonMetric(label: "Sleep Balance", valA: readinessA?.contributors.sleepBalance, valB: readinessB?.contributors.sleepBalance),
                    ComparisonMetric(label: "Recovery", valA: readinessA?.contributors.recoveryIndex, valB: readinessB?.contributors.recoveryIndex),
                ],
                defaultOpen: true
            )
            
            // Sleep Group
            MetricComparisonGroupView(
                title: "Sleep",
                scoreA: sleepA?.score,
                scoreB: sleepB?.score,
                metrics: [
                    ComparisonMetric(label: "Total Sleep", valA: sleepA?.contributors.totalSleep, valB: sleepB?.contributors.totalSleep),
                    ComparisonMetric(label: "Deep Sleep", valA: sleepA?.contributors.deepSleep, valB: sleepB?.contributors.deepSleep),
                    ComparisonMetric(label: "REM Sleep", valA: sleepA?.contributors.remSleep, valB: sleepB?.contributors.remSleep),
                    ComparisonMetric(label: "Efficiency", valA: sleepA?.contributors.efficiency, valB: sleepB?.contributors.efficiency),
                ]
            )
            
            // Activity Group
            MetricComparisonGroupView(
                title: "Activity",
                scoreA: activityA?.score,
                scoreB: activityB?.score,
                metrics: [
                    ComparisonMetric(label: "Steps", valA: activityA?.steps, valB: activityB?.steps, max: 15000),
                    ComparisonMetric(label: "Calories", valA: activityA?.activeCalories, valB: activityB?.activeCalories, max: 1000),
                ]
            )
            
            // Vitals Group
            MetricComparisonGroupView(
                title: "Vitals",
                metrics: [
                    ComparisonMetric(label: "HRV (ms)", valA: sessionA?.averageHrv, valB: sessionB?.averageHrv, max: 120),
                    ComparisonMetric(label: "Resting HR", valA: sessionA?.lowestHeartRate, valB: sessionB?.lowestHeartRate, inverse: true, max: 100),
                    ComparisonMetric(label: "Sleep Duration", valA: (sessionA?.totalSleepDuration ?? 0) / 60, valB: (sessionB?.totalSleepDuration ?? 0) / 60, unit: "min", max: 540),
                ]
            )
        }
    }
}

#Preview {
    ScrollView {
        VersusView()
            .padding()
    }
    .background(Theme.bgBase)
    .environment(AppState())
}
