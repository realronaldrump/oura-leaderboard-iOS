import SwiftUI

// MARK: - Daily Content View

struct DailyContentView: View {
    @Environment(AppState.self) private var appState
    
    var body: some View {
        if appState.activeStats == nil {
            VStack(spacing: 12) {
                ProgressView()
                    .tint(Theme.accentCyan)
                Text("Syncing your data")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text("Pull to refresh if this takes more than a minute.")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textMuted)
            }
            .frame(maxWidth: .infinity)
            .glassCard()
        } else {
            LazyVStack(spacing: 24) {
                // Date Navigation
                DateNavigator()
                
                // Main Scores
                MainScoresSection()
                
                // Sleep Details
                SleepDetailsSection()
                
                // Heart Rate & HRV
                HeartRateSection()
                
                // Activity Details
                ActivityDetailsSection()
                
                // Score Contributors
                ScoreContributorsSection()
            }
        }
    }
}

// MARK: - Date Navigator

private struct DateNavigator: View {
    @Environment(AppState.self) private var appState
    
    private var currentDate: String {
        guard let day = appState.currentSleep?.day else { return "Today" }
        return formatDateDisplay(day)
    }
    
    var body: some View {
        HStack {
            Button {
                appState.goToPreviousDay()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(appState.canGoBack ? Theme.textPrimary : Theme.textMuted)
                    .frame(width: 40, height: 40)
                    .background(Theme.bgRaised)
                    .clipShape(Circle())
            }
            .disabled(!appState.canGoBack)
            
            Spacer()
            
            Text(currentDate)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
            
            Spacer()
            
            Button {
                appState.goToNextDay()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(appState.canGoForward ? Theme.textPrimary : Theme.textMuted)
                    .frame(width: 40, height: 40)
                    .background(Theme.bgRaised)
                    .clipShape(Circle())
            }
            .disabled(!appState.canGoForward)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Theme.bgRaised.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func formatDateDisplay(_ day: String) -> String {
        // Use static formatter instead of creating new instance each time
        guard let date = Formatters.date(fromDayKey: day) else { return day }
        
        let today = Calendar.current.startOfDay(for: Date())
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        let dateDay = Calendar.current.startOfDay(for: date)
        
        if dateDay == today {
            return "Today"
        } else if dateDay == yesterday {
            return "Yesterday"
        } else {
            return Formatters.displayDate.string(from: date)
        }
    }
}

// MARK: - Main Scores Section

private struct MainScoresSection: View {
    @Environment(AppState.self) private var appState
    
    var body: some View {
        VStack(spacing: 20) {
            Text("YOUR SCORES")
                .font(.system(size: 11, weight: .semibold))
                .tracking(1)
                .foregroundStyle(Theme.textMuted)
            
            HStack(spacing: 16) {
                VStack(spacing: 12) {
                    ScoreRingView(
                        score: appState.currentReadiness?.score,
                        label: "Readiness",
                        color: Theme.readinessColor,
                        size: 100
                    )
                    
                    // Mini chart
                    if let stats = appState.activeStats {
                        HistoryChartView(
                            data: stats.readiness.prefix(7).map { $0.score },
                            color: Theme.readinessColor,
                            height: 32
                        )
                        .frame(width: 80)
                    }
                }
                
                VStack(spacing: 12) {
                    ScoreRingView(
                        score: appState.currentSleep?.score,
                        label: "Sleep",
                        color: Theme.sleepColor,
                        size: 100
                    )
                    
                    if let stats = appState.activeStats {
                        HistoryChartView(
                            data: stats.sleep.prefix(7).map { $0.score },
                            color: Theme.sleepColor,
                            height: 32
                        )
                        .frame(width: 80)
                    }
                }
                
                VStack(spacing: 12) {
                    ScoreRingView(
                        score: appState.currentActivity?.score,
                        label: "Activity",
                        color: Theme.activityColor,
                        size: 100
                    )
                    
                    if let stats = appState.activeStats {
                        HistoryChartView(
                            data: stats.activity.prefix(7).map { $0.score },
                            color: Theme.activityColor,
                            height: 32
                        )
                        .frame(width: 80)
                    }
                }
            }
        }
        .glassCard()
    }
}

// MARK: - Sleep Details Section

private struct SleepDetailsSection: View {
    @Environment(AppState.self) private var appState
    
    private var session: SleepSession? { appState.currentSession }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "moon.stars.fill")
                    .foregroundStyle(Theme.sleepColor)
                Text("SLEEP DETAILS")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1)
                    .foregroundStyle(Theme.textMuted)
                Spacer()
            }
            
            // Primary metrics
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                SmallMetricCardView(
                    title: "Total Sleep",
                    value: formatDuration(session?.totalSleepDuration),
                    color: Theme.sleepColor
                )
                
                SmallMetricCardView(
                    title: "Time in Bed",
                    value: formatDuration(session?.timeInBed),
                    color: Theme.textPrimary
                )
                
                SmallMetricCardView(
                    title: "Bedtime",
                    value: formatTime(session?.bedtimeStart),
                    color: Theme.textPrimary
                )
                
                SmallMetricCardView(
                    title: "Wake Time",
                    value: formatTime(session?.bedtimeEnd),
                    color: Theme.textPrimary
                )
                
                SmallMetricCardView(
                    title: "Deep Sleep",
                    value: formatDuration(session?.deepSleepDuration),
                    color: Theme.deepSleep
                )
                
                SmallMetricCardView(
                    title: "REM Sleep",
                    value: formatDuration(session?.remSleepDuration),
                    color: Theme.remSleep
                )
                
                SmallMetricCardView(
                    title: "Efficiency",
                    value: session?.efficiency != nil ? "\(session!.efficiency!)%" : "--",
                    color: Theme.readinessColor
                )
                
                SmallMetricCardView(
                    title: "Latency",
                    value: formatDuration(session?.latency),
                    color: Theme.textSecondary
                )
            }
            
            // Sleep stages chart
            if let stats = appState.activeStats, !stats.session.isEmpty {
                SleepStagesChartView(sessions: Array(stats.session))
                    .padding(.top, 16)
            }
        }
        .glassCard()
    }
}

// MARK: - Heart Rate Section

private struct HeartRateSection: View {
    @Environment(AppState.self) private var appState
    
    private var session: SleepSession? { appState.currentSession }
    private var spo2: DailySpO2? { appState.currentSpo2 }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundStyle(Theme.hrColor)
                Text("HEART & HRV")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1)
                    .foregroundStyle(Theme.textMuted)
                Spacer()
            }
            
            // Metrics grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                SmallMetricCardView(
                    title: "Lowest HR",
                    value: session?.lowestHeartRate != nil ? "\(session!.lowestHeartRate!)" : "--",
                    unit: "bpm",
                    color: Theme.hrColor
                )
                
                SmallMetricCardView(
                    title: "Avg HR",
                    value: session?.averageHeartRate != nil ? "\(Int(session!.averageHeartRate!))" : "--",
                    unit: "bpm",
                    color: Theme.hrColor
                )
                
                SmallMetricCardView(
                    title: "HRV",
                    value: session?.averageHrv != nil ? "\(session!.averageHrv!)" : "--",
                    unit: "ms",
                    color: Theme.hrvColor
                )
            }
            
            SmallMetricCardView(
                title: "SpO2",
                value: spo2?.spo2Percentage?.average != nil ? "\(Int(spo2!.spo2Percentage!.average!))%" : "--",
                color: Theme.metricCyan
            )
            
            // Heart rate chart
            HeartRateChartView(data: appState.activeHeartRate, showLabels: true)
                .padding(.top, 8)
            
            // HRV trend
            if let stats = appState.activeStats, !stats.session.isEmpty {
                HRVChartView(sessions: Array(stats.session))
                    .padding(.top, 16)
            }
        }
        .glassCard()
    }
}

// MARK: - Activity Details Section

private struct ActivityDetailsSection: View {
    @Environment(AppState.self) private var appState
    
    private var activity: DailyActivity? { appState.currentActivity }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundStyle(Theme.activityColor)
                Text("ACTIVITY")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1)
                    .foregroundStyle(Theme.textMuted)
                Spacer()
            }
            
            // Metrics grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                SmallMetricCardView(
                    title: "Steps",
                    value: activity != nil ? formatNumber(activity!.steps) : "--",
                    color: Theme.activityColor
                )
                
                SmallMetricCardView(
                    title: "Active Calories",
                    value: activity != nil ? formatNumber(activity!.activeCalories) : "--",
                    unit: "cal",
                    color: Theme.activityColor
                )
                
                SmallMetricCardView(
                    title: "Total Calories",
                    value: activity != nil ? formatNumber(activity!.totalCalories) : "--",
                    unit: "cal",
                    color: Theme.textPrimary
                )
                
                SmallMetricCardView(
                    title: "Walking Distance",
                    value: activity?.equivalentWalkingDistance != nil 
                        ? String(format: "%.1f", Double(activity!.equivalentWalkingDistance!) / 1609.34)
                        : "--",
                    unit: "mi",
                    color: Theme.textPrimary
                )
                
                SmallMetricCardView(
                    title: "High Activity",
                    value: formatDuration(activity?.highActivityTime),
                    color: Theme.accentRose
                )
                
                SmallMetricCardView(
                    title: "Medium Activity",
                    value: formatDuration(activity?.mediumActivityTime),
                    color: Theme.accentOrange
                )
            }
        }
        .glassCard()
    }
    
    private func formatNumber(_ num: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: num)) ?? "\(num)"
    }
}

// MARK: - Score Contributors Section

private struct ScoreContributorsSection: View {
    @Environment(AppState.self) private var appState
    
    var body: some View {
        VStack(spacing: 16) {
            // Readiness Contributors
            if let readiness = appState.currentReadiness {
                ContributorsView(
                    title: "Readiness Contributors",
                    contributors: readinessContributors(from: readiness.contributors)
                )
            }
            
            // Sleep Contributors
            if let sleep = appState.currentSleep {
                ContributorsView(
                    title: "Sleep Contributors",
                    contributors: sleepContributors(from: sleep.contributors)
                )
            }
        }
    }
    
    private func readinessContributors(from c: ReadinessContributors) -> [ContributorItem] {
        [
            ContributorItem(label: "Previous Night", value: c.previousNight, color: Theme.sleepColor),
            ContributorItem(label: "Sleep Balance", value: c.sleepBalance, color: Theme.sleepColor),
            ContributorItem(label: "HRV Balance", value: c.hrvBalance, color: Theme.hrvColor),
            ContributorItem(label: "Resting Heart Rate", value: c.restingHeartRate, color: Theme.hrColor),
            ContributorItem(label: "Recovery Index", value: c.recoveryIndex, color: Theme.readinessColor),
            ContributorItem(label: "Body Temperature", value: c.bodyTemperature, color: Theme.accentOrange),
            ContributorItem(label: "Activity Balance", value: c.activityBalance, color: Theme.activityColor),
        ].filter { $0.value != nil }
    }
    
    private func sleepContributors(from c: SleepContributors) -> [ContributorItem] {
        [
            ContributorItem(label: "Total Sleep", value: c.totalSleep, color: Theme.sleepColor),
            ContributorItem(label: "Deep Sleep", value: c.deepSleep, color: Theme.deepSleep),
            ContributorItem(label: "REM Sleep", value: c.remSleep, color: Theme.remSleep),
            ContributorItem(label: "Efficiency", value: c.efficiency, color: Theme.readinessColor),
            ContributorItem(label: "Restfulness", value: c.restfulness, color: Theme.textSecondary),
            ContributorItem(label: "Latency", value: c.latency, color: Theme.textSecondary),
            ContributorItem(label: "Timing", value: c.timing, color: Theme.textSecondary),
        ].filter { $0.value != nil }
    }
}

#Preview {
    ScrollView {
        DailyContentView()
            .padding()
    }
    .background(Theme.bgBase)
    .environment(AppState())
}
