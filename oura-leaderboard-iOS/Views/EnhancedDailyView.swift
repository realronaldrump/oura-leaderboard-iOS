import SwiftUI

// MARK: - Enhanced Daily Content View

struct EnhancedDailyContentView: View {
    @Environment(AppState.self) private var appState
    @State private var refreshTask: Task<Void, Never>?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Pull to refresh indicator
                RefreshControl()
                
                if appState.activeStats == nil {
                    LoadingView()
                        .padding(.top, 100)
                } else {
                    LazyVStack(spacing: 24) {
                        // Date Navigation
                        EnhancedDateNavigator()
                            .padding(.top, 12)
                        
                        // Main Scores
                        EnhancedMainScoresSection()
                        
                        // Sleep Details
                        EnhancedSleepDetailsSection()
                        
                        // Heart Rate & HRV
                        EnhancedHeartRateSection()
                        
                        // Activity Details
                        EnhancedActivityDetailsSection()
                        
                        // Score Contributors
                        EnhancedScoreContributorsSection()
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
            }
        }
        .refreshable {
            await refreshData()
        }
        .scrollIndicators(.hidden)
    }
    
    private func refreshData() async {
        appState.provideHapticFeedback(.light)
        await appState.refreshActiveProfile()
        appState.provideHapticFeedback(.success)
    }
}

// MARK: - Loading View

private struct LoadingView: View {
    @State private var rotation: Double = 0
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(Theme.bgRaised, lineWidth: 3)
                    .frame(width: 50, height: 50)
                
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [Theme.accentCyan, Theme.accentPurple]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(rotation))
                    .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: rotation)
            }
            
            Text("Syncing your data")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
            
            Text("This usually takes a few seconds")
                .font(.system(size: 14))
                .foregroundStyle(Theme.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .glassCard()
        .onAppear {
            rotation = 360
        }
    }
}

// MARK: - Refresh Control

private struct RefreshControl: View {
    @State private var refreshProgress: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            let pullProgress = min(max(0, geometry.frame(in: .global).minY - 100) / 100, 1)
            
            ZStack {
                Circle()
                    .stroke(Theme.bgRaised, lineWidth: 2)
                    .frame(width: 30, height: 30)
                    .opacity(pullProgress)
                
                Circle()
                    .trim(from: 0, to: pullProgress * 0.8)
                    .stroke(Theme.accentCyan, lineWidth: 2)
                    .frame(width: 30, height: 30)
                    .rotationEffect(.degrees(-90))
                    .opacity(pullProgress)
            }
            .scaleEffect(0.8 + (0.2 * pullProgress))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .onChange(of: pullProgress) { _, newValue in
                if newValue > 0.1 && newValue < 0.2 {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                }
            }
        }
        .frame(height: 0)
    }
}

// MARK: - Enhanced Date Navigator

private struct EnhancedDateNavigator: View {
    @Environment(AppState.self) private var appState
    @State private var showingDatePicker = false
    
    private var currentDate: String {
        let formatter = DateFormatter()
        
        let today = Calendar.current.startOfDay(for: Date())
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        let selectedDay = Calendar.current.startOfDay(for: appState.selectedDate)
        
        if selectedDay == today {
            return "Today"
        } else if selectedDay == yesterday {
            return "Yesterday"
        } else {
            formatter.dateFormat = "EEEE, MMM d"
            return formatter.string(from: appState.selectedDate)
        }
    }
    
    var body: some View {
        HStack {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    appState.goToPreviousDay()
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(appState.canGoBack ? Theme.textPrimary : Theme.textDim)
                    .frame(width: 44, height: 44)
                    .background(Theme.bgRaised)
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 2)
            }
            .disabled(!appState.canGoBack)
            .scaleEffect(appState.canGoBack ? 1 : 0.9)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: appState.canGoBack)
            
            Spacer()
            
            Button {
                showingDatePicker.toggle()
                appState.provideHapticFeedback(.light)
            } label: {
                VStack(spacing: 4) {
                    Text(currentDate)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    
                    if Calendar.current.isDateInToday(appState.selectedDate) {
                        Text("TAP FOR CALENDAR")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(Theme.textMuted)
                            .tracking(0.5)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(Theme.bgRaised.opacity(0.5))
                .clipShape(Capsule())
            }
            .scaleEffect(showingDatePicker ? 0.95 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showingDatePicker)
            
            Spacer()
            
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    appState.goToNextDay()
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(appState.canGoForward ? Theme.textPrimary : Theme.textDim)
                    .frame(width: 44, height: 44)
                    .background(Theme.bgRaised)
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 2)
            }
            .disabled(!appState.canGoForward)
            .scaleEffect(appState.canGoForward ? 1 : 0.9)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: appState.canGoForward)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Theme.bgRaised.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .sheet(isPresented: $showingDatePicker) {
            @Bindable var bindableAppState = appState
            DatePickerSheet(selectedDate: $bindableAppState.selectedDate, availableDates: appState.availableDates)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Date Picker Sheet

private struct DatePickerSheet: View {
    @Binding var selectedDate: Date
    let availableDates: [Date]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                DatePicker("Select Date", selection: $selectedDate, in: dateRange, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .accentColor(Theme.accentCyan)
                    .padding()
                
                Spacer()
            }
            .background(Theme.bgBase)
            .navigationTitle("Select Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(Theme.accentCyan)
                }
            }
        }
    }
    
    private var dateRange: ClosedRange<Date> {
        let sortedDates = availableDates.sorted()
        let start = sortedDates.first ?? Date()
        let end = sortedDates.last ?? Date()
        return start...end
    }
}

// MARK: - Enhanced Main Scores Section

private struct EnhancedMainScoresSection: View {
    @Environment(AppState.self) private var appState
    @State private var selectedScore: ScoreType? = nil
    
    enum ScoreType: String, CaseIterable {
        case readiness = "Readiness"
        case sleep = "Sleep"
        case activity = "Activity"
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("YOUR SCORES")
                .font(.system(size: 12, weight: .semibold))
                .tracking(1.2)
                .foregroundStyle(Theme.textMuted)
            
            HStack(spacing: 20) {
                ForEach(ScoreType.allCases, id: \.self) { type in
                    ScoreCard(
                        type: type,
                        score: score(for: type),
                        isSelected: selectedScore == type,
                        trend: trend(for: type)
                    )
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            selectedScore = selectedScore == type ? nil : type
                            appState.provideHapticFeedback(.light)
                        }
                    }
                }
            }
            
            // Trend chart for selected score
            if let selected = selectedScore {
                ScoreTrendChart(type: selected)
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .scale.combined(with: .opacity)
                    ))
            }
        }
        .padding(20)
        .glassCard()
    }
    
    private func score(for type: ScoreType) -> Int? {
        switch type {
        case .readiness:
            return appState.currentReadiness?.score
        case .sleep:
            return appState.currentSleep?.score
        case .activity:
            return appState.currentActivity?.score
        }
    }
    
    private func trend(for type: ScoreType) -> [Int] {
        guard let stats = appState.activeStats else { return [] }
        let dates = Array(stats.availableDates.sorted(by: >).prefix(7))
        
        return dates.compactMap { date in
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let dateKey = formatter.string(from: date)
            
            guard let dayData = stats.getDayData(for: dateKey) else { return nil }
            
            switch type {
            case .readiness:
                return dayData.readiness?.score
            case .sleep:
                return dayData.sleep?.score
            case .activity:
                return dayData.activity?.score
            }
        }
    }
}

// MARK: - Score Card

private struct ScoreCard: View {
    let type: EnhancedMainScoresSection.ScoreType
    let score: Int?
    let isSelected: Bool
    let trend: [Int]
    
    private var color: Color {
        switch type {
        case .readiness: return Theme.readinessColor
        case .sleep: return Theme.sleepColor
        case .activity: return Theme.activityColor
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(Theme.bgRaised, lineWidth: 8)
                    .frame(width: 90, height: 90)
                
                Circle()
                    .trim(from: 0, to: CGFloat(score ?? 0) / 100)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [color, color.opacity(0.7)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 90, height: 90)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: score)
                
                Text("\(score ?? 0)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
            }
            .scaleEffect(isSelected ? 1.1 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
            
            Text(type.rawValue.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(color)
                .tracking(0.5)
            
            // Mini trend
            if !trend.isEmpty {
                MiniTrendView(data: trend, color: color)
                    .frame(height: 20)
                    .opacity(isSelected ? 0.3 : 1)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Mini Trend View

private struct MiniTrendView: View {
    let data: [Int]
    let color: Color
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                guard !data.isEmpty else { return }
                
                let width = geometry.size.width
                let height = geometry.size.height
                let maxValue = data.max() ?? 100
                let minValue = data.min() ?? 0
                let range = maxValue - minValue
                
                for (index, value) in data.enumerated() {
                    let x = width * CGFloat(index) / CGFloat(data.count - 1)
                    let normalizedValue = CGFloat(value - minValue) / CGFloat(range)
                    let y = height * (1 - normalizedValue)
                    
                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(color, lineWidth: 2)
        }
    }
}

// MARK: - Score Trend Chart

private struct ScoreTrendChart: View {
    let type: EnhancedMainScoresSection.ScoreType
    @Environment(AppState.self) private var appState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(type.rawValue) Trend")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
            
            // Chart implementation here
            Rectangle()
                .fill(Theme.bgRaised)
                .frame(height: 120)
                .overlay(
                    Text("7-day trend chart")
                        .foregroundStyle(Theme.textMuted)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.top, 12)
    }
}

// MARK: - Enhanced Sleep Details Section

private struct EnhancedSleepDetailsSection: View {
    @Environment(AppState.self) private var appState
    @State private var expandedSection = false
    
    private var session: SleepSession? { appState.currentSession }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    expandedSection.toggle()
                    appState.provideHapticFeedback(.light)
                }
            } label: {
                HStack {
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Theme.sleepColor)
                    
                    Text("SLEEP DETAILS")
                        .font(.system(size: 12, weight: .semibold))
                        .tracking(1)
                        .foregroundStyle(Theme.textMuted)
                    
                    Spacer()
                    
                    Image(systemName: expandedSection ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.textMuted)
                }
            }
            
            // Primary metrics (always visible)
            HStack(spacing: 12) {
                MetricPill(
                    icon: "bed.double.fill",
                    title: "Total Sleep",
                    value: formatDuration(session?.totalSleepDuration),
                    color: Theme.sleepColor
                )
                
                MetricPill(
                    icon: "clock.fill",
                    title: "Efficiency",
                    value: session?.efficiency != nil ? "\(session!.efficiency!)%" : "--",
                    color: Theme.readinessColor
                )
            }
            
            if expandedSection {
                VStack(spacing: 12) {
                    // Additional metrics
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
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
                            title: "Latency",
                            value: formatDuration(session?.latency),
                            color: Theme.textSecondary
                        )
                    }
                    
                    // Sleep stages visualization
                    if session != nil {
                        SleepStagesVisualization(session: session!)
                            .padding(.top, 8)
                    }
                }
                .transition(.asymmetric(
                    insertion: .push(from: .top).combined(with: .opacity),
                    removal: .push(from: .bottom).combined(with: .opacity)
                ))
            }
        }
        .padding(20)
        .glassCard()
    }
}

// MARK: - Metric Pill

private struct MetricPill: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Theme.textMuted)
                
                Text(value)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
            }
            
            Spacer()
        }
        .padding(12)
        .background(Theme.bgRaised)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Sleep Stages Visualization

private struct SleepStagesVisualization: View {
    let session: SleepSession
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sleep Stages")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
            
            HStack(spacing: 8) {
                SleepStageBar(
                    stage: "Deep",
                    duration: session.deepSleepDuration ?? 0,
                    totalDuration: session.totalSleepDuration ?? 1,
                    color: Theme.deepSleep
                )
                
                SleepStageBar(
                    stage: "REM",
                    duration: session.remSleepDuration ?? 0,
                    totalDuration: session.totalSleepDuration ?? 1,
                    color: Theme.remSleep
                )
                
                SleepStageBar(
                    stage: "Light",
                    duration: session.lightSleepDuration ?? 0,
                    totalDuration: session.totalSleepDuration ?? 1,
                    color: Theme.lightSleep
                )
            }
        }
    }
}

// MARK: - Sleep Stage Bar

private struct SleepStageBar: View {
    let stage: String
    let duration: Int
    let totalDuration: Int
    let color: Color
    
    private var percentage: Double {
        Double(duration) / Double(totalDuration)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            GeometryReader { geometry in
                ZStack(alignment: .bottom) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Theme.bgRaised)
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(color)
                        .frame(height: geometry.size.height * percentage)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: percentage)
                }
            }
            .frame(height: 80)
            
            Text(stage)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Theme.textMuted)
            
            Text(formatDuration(duration))
                .font(.system(size: 10))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Enhanced Heart Rate Section

private struct EnhancedHeartRateSection: View {
    @Environment(AppState.self) private var appState
    @State private var selectedMetric: HeartMetric = .heartRate
    
    enum HeartMetric: String, CaseIterable {
        case heartRate = "Heart Rate"
        case hrv = "HRV"
        case spo2 = "SpO2"
    }
    
    private var session: SleepSession? { appState.currentSession }
    private var spo2: DailySpO2? { appState.currentSpo2 }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "heart.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.hrColor)
                    .symbolEffect(.pulse, value: selectedMetric == .heartRate)
                
                Text("HEART & VITALS")
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(1)
                    .foregroundStyle(Theme.textMuted)
                
                Spacer()
                
                // Metric selector
                Menu {
                    ForEach(HeartMetric.allCases, id: \.self) { metric in
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                selectedMetric = metric
                                appState.provideHapticFeedback(.selection)
                            }
                        } label: {
                            Label(metric.rawValue, systemImage: icon(for: metric))
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(selectedMetric.rawValue)
                            .font(.system(size: 12, weight: .medium))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10))
                    }
                    .foregroundStyle(Theme.accentCyan)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Theme.accentCyan.opacity(0.1))
                    .clipShape(Capsule())
                }
            }
            
            // Metrics display
            switch selectedMetric {
            case .heartRate:
                HeartRateMetrics(session: session)
            case .hrv:
                HRVMetrics(session: session)
            case .spo2:
                SpO2Metrics(spo2: spo2)
            }
            
            // Chart
            if !appState.currentHeartRate.isEmpty {
                HeartRateChartView(data: appState.currentHeartRate, showLabels: true)
                    .frame(height: 180)
                    .padding(.top, 8)
            }
        }
        .padding(20)
        .glassCard()
    }
    
    private func icon(for metric: HeartMetric) -> String {
        switch metric {
        case .heartRate: return "heart.fill"
        case .hrv: return "waveform.path.ecg"
        case .spo2: return "lungs.fill"
        }
    }
}

// MARK: - Heart Rate Metrics

private struct HeartRateMetrics: View {
    let session: SleepSession?
    
    var body: some View {
        HStack(spacing: 12) {
            MetricCard(
                title: "Resting",
                value: session?.lowestHeartRate != nil ? "\(session!.lowestHeartRate!)" : "--",
                unit: "bpm",
                icon: "heart",
                color: Theme.hrColor
            )
            
            MetricCard(
                title: "Average",
                value: session?.averageHeartRate != nil ? "\(Int(session!.averageHeartRate!))" : "--",
                unit: "bpm",
                icon: "heart.circle",
                color: Theme.hrColor.opacity(0.8)
            )
        }
    }
}

// MARK: - HRV Metrics

private struct HRVMetrics: View {
    let session: SleepSession?
    
    var body: some View {
        HStack(spacing: 12) {
            MetricCard(
                title: "Average HRV",
                value: session?.averageHrv != nil ? "\(session!.averageHrv!)" : "--",
                unit: "ms",
                icon: "waveform.path.ecg",
                color: Theme.hrvColor
            )
            
        }
    }
}

// MARK: - SpO2 Metrics

private struct SpO2Metrics: View {
    let spo2: DailySpO2?
    
    var body: some View {
        HStack(spacing: 12) {
            MetricCard(
                title: "Average SpO2",
                value: spo2?.spo2Percentage?.average != nil ? "\(Int(spo2!.spo2Percentage!.average!))%" : "--",
                unit: "",
                icon: "lungs",
                color: Theme.metricCyan
            )
            
            if let breathing = spo2?.breathingDisturbanceIndex {
                MetricCard(
                    title: "Breathing Index",
                    value: String(format: "%.1f", breathing),
                    unit: "",
                    icon: "wind",
                    color: Theme.metricCyan.opacity(0.8)
                )
            }
        }
    }
}

// MARK: - Metric Card

private struct MetricCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(color)
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.textMuted)
            }
            
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                
                if !unit.isEmpty {
                    Text(unit)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Theme.textMuted)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Theme.bgRaised)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Enhanced Activity Details Section

private struct EnhancedActivityDetailsSection: View {
    @Environment(AppState.self) private var appState
    @State private var showingActivityRings = false
    
    private var activity: DailyActivity? { appState.currentActivity }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "flame.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.activityColor)
                    .symbolEffect(.pulse, value: showingActivityRings)
                
                Text("ACTIVITY")
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(1)
                    .foregroundStyle(Theme.textMuted)
                
                Spacer()
                
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showingActivityRings.toggle()
                        appState.provideHapticFeedback(.light)
                    }
                } label: {
                    Image(systemName: showingActivityRings ? "circle.grid.3x3.fill" : "circle.grid.3x3")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.accentOrange)
                }
            }
            
            if showingActivityRings {
                ActivityRingsView(activity: activity)
                    .transition(.scale.combined(with: .opacity))
            }
            
            // Primary metrics
            HStack(spacing: 12) {
                ActivityMetricCard(
                    icon: "figure.walk",
                    value: activity != nil ? formatNumber(activity!.steps) : "--",
                    title: "Steps",
                    color: Theme.activityColor,
                    progress: Double(activity?.steps ?? 0) / 10000
                )
                
                ActivityMetricCard(
                    icon: "flame",
                    value: activity != nil ? "\(activity!.activeCalories)" : "--",
                    title: "Active Cal",
                    color: Theme.accentOrange,
                    progress: Double(activity?.activeCalories ?? 0) / 500
                )
            }
            
            // Activity breakdown
            if let act = activity {
                VStack(spacing: 8) {
                    ActivityBar(
                        title: "High Activity",
                        duration: act.highActivityTime ?? 0,
                        color: Theme.accentRose
                    )
                    
                    ActivityBar(
                        title: "Medium Activity",
                        duration: act.mediumActivityTime ?? 0,
                        color: Theme.accentOrange
                    )
                    
                    ActivityBar(
                        title: "Low Activity",
                        duration: act.lowActivityTime ?? 0,
                        color: Theme.accentOrange.opacity(0.7)
                    )
                }
                .padding(.top, 8)
            }
        }
        .padding(20)
        .glassCard()
    }
    
    private func formatNumber(_ num: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: num)) ?? "\(num)"
    }
}

// MARK: - Activity Rings View

private struct ActivityRingsView: View {
    let activity: DailyActivity?
    
    var body: some View {
        HStack(spacing: 20) {
            ActivityRing(
                progress: Double(activity?.steps ?? 0) / 10000,
                color: Theme.activityColor,
                icon: "figure.walk"
            )
            
            ActivityRing(
                progress: Double(activity?.activeCalories ?? 0) / 500,
                color: Theme.accentOrange,
                icon: "flame.fill"
            )
            
            ActivityRing(
                progress: Double(activity?.totalCalories ?? 0) / 2500,
                color: Theme.accentRose,
                icon: "bolt.fill"
            )
        }
        .padding(.vertical, 20)
    }
}

// MARK: - Activity Ring

private struct ActivityRing: View {
    let progress: Double
    let color: Color
    let icon: String
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 12)
            
            Circle()
                .trim(from: 0, to: min(progress, 1))
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [color, color.opacity(0.7)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: progress)
            
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(color)
        }
        .frame(width: 80, height: 80)
    }
}

// MARK: - Activity Metric Card

private struct ActivityMetricCard: View {
    let icon: String
    let value: String
    let title: String
    let color: Color
    let progress: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(color)
                
                Spacer()
                
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Theme.textMuted)
            }
            
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Theme.bgRaised)
                        .frame(height: 4)
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color)
                        .frame(width: geometry.size.width * min(progress, 1), height: 4)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: progress)
                }
            }
            .frame(height: 4)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Theme.bgRaised.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Activity Bar

private struct ActivityBar: View {
    let title: String
    let duration: Int
    let color: Color
    
    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Theme.textSecondary)
            
            Spacer()
            
            Text(formatDuration(duration))
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Theme.bgRaised.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Enhanced Score Contributors Section

private struct EnhancedScoreContributorsSection: View {
    @Environment(AppState.self) private var appState
    @State private var expandedContributor: ContributorType? = nil
    
    enum ContributorType: String, CaseIterable {
        case readiness = "Readiness"
        case sleep = "Sleep"
    }
    
    var body: some View {
        VStack(spacing: 16) {
            ForEach(ContributorType.allCases, id: \.self) { type in
                ContributorCard(
                    type: type,
                    isExpanded: expandedContributor == type,
                    contributors: contributors(for: type)
                )
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        expandedContributor = expandedContributor == type ? nil : type
                        appState.provideHapticFeedback(.light)
                    }
                }
            }
        }
    }
    
    private func contributors(for type: ContributorType) -> [ContributorItem] {
        switch type {
        case .readiness:
            guard let readiness = appState.currentReadiness else { return [] }
            return readinessContributors(from: readiness.contributors)
        case .sleep:
            guard let sleep = appState.currentSleep else { return [] }
            return sleepContributors(from: sleep.contributors)
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

// MARK: - Contributor Card

private struct ContributorCard: View {
    let type: EnhancedScoreContributorsSection.ContributorType
    let isExpanded: Bool
    let contributors: [ContributorItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(color)
                
                Text("\(type.rawValue) Contributors")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                
                Spacer()
                
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.textMuted)
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
            }
            
            if isExpanded {
                VStack(spacing: 8) {
                    ForEach(contributors, id: \.label) { contributor in
                        ContributorImpactRow(item: contributor)
                    }
                }
                .transition(.asymmetric(
                    insertion: .push(from: .top).combined(with: .opacity),
                    removal: .push(from: .bottom).combined(with: .opacity)
                ))
            }
        }
        .padding(16)
        .background(Theme.bgRaised.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var icon: String {
        switch type {
        case .readiness: return "gauge.with.dots.needle.bottom.50percent"
        case .sleep: return "moon.zzz.fill"
        }
    }
    
    private var color: Color {
        switch type {
        case .readiness: return Theme.readinessColor
        case .sleep: return Theme.sleepColor
        }
    }
}

// MARK: - Contributor Row

private struct ContributorImpactRow: View {
    let item: ContributorItem
    
    private var impact: String {
        guard let value = item.value else { return "" }
        if value > 10 { return "↑↑" }
        if value > 0 { return "↑" }
        if value < -10 { return "↓↓" }
        if value < 0 { return "↓" }
        return "—"
    }
    
    private var impactColor: Color {
        guard let value = item.value else { return Theme.textMuted }
        if value > 0 { return Theme.accentGreen }
        if value < 0 { return Theme.accentRose }
        return Theme.textMuted
    }
    
    var body: some View {
        HStack {
            Circle()
                .fill(item.color.opacity(0.2))
                .frame(width: 6, height: 6)
            
            Text(item.label)
                .font(.system(size: 13))
                .foregroundStyle(Theme.textSecondary)
            
            Spacer()
            
            HStack(spacing: 4) {
                Text(impact)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(impactColor)
                
                Text("\(abs(item.value ?? 0))")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Theme.bgBase.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    ScrollView {
        EnhancedDailyContentView()
    }
    .background(Theme.bgBase)
    .environment(AppState())
}
