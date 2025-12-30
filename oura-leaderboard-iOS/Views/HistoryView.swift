import SwiftUI
import Charts

// MARK: - History View

struct HistoryView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedMetric: HistoryMetric = .sleep
    @State private var selectedUser: String? = nil
    @State private var sortColumn: SortColumn = .date
    @State private var sortAscending = false
    
    private var allTimeData: [HistoryDataPoint] {
        var points: [HistoryDataPoint] = []
        
        for profile in appState.profiles {
            // Use regular stats if all-time not loaded
            let stats = appState.allTimeStats[profile.id] ?? appState.dailyStats[profile.id]
            guard let stats = stats else { continue }
            
            let data = selectedMetricData(from: stats)
            
            for item in data {
                if let score = item.score {
                    points.append(HistoryDataPoint(
                        id: UUID().uuidString,
                        userId: profile.id,
                        userName: profile.displayName,
                        day: item.day,
                        score: score
                    ))
                }
            }
        }
        
        return points
    }
    
    private func selectedMetricData(from stats: DailyStats) -> [(day: String, score: Int?)] {
        switch selectedMetric {
        case .readiness:
            return stats.readiness.map { ($0.day, $0.score) }
        case .sleep:
            return stats.sleep.map { ($0.day, $0.score) }
        case .activity:
            return stats.activity.map { ($0.day, $0.score) }
        }
    }
    
    private var filteredData: [HistoryDataPoint] {
        if let userId = selectedUser {
            return allTimeData.filter { $0.userId == userId }
        }
        return allTimeData
    }
    
    private var sortedData: [HistoryDataPoint] {
        filteredData.sorted { a, b in
            let result: Bool
            switch sortColumn {
            case .name:
                result = a.userName < b.userName
            case .date:
                result = a.day > b.day
            case .score:
                result = a.score > b.score
            }
            return sortAscending ? !result : result
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Filters
            HStack {
                // Metric Picker
                Menu {
                    ForEach(HistoryMetric.allCases, id: \.self) { metric in
                        Button {
                            selectedMetric = metric
                        } label: {
                            HStack {
                                Text(metric.rawValue)
                                if selectedMetric == metric {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedMetric.rawValue)
                            .font(.system(size: 14, weight: .medium))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10))
                    }
                    .foregroundStyle(metricColor)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(metricColor.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                // User Filter
                Menu {
                    Button {
                        selectedUser = nil
                    } label: {
                        HStack {
                            Text("All Users")
                            if selectedUser == nil {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                    
                    ForEach(appState.profiles) { profile in
                        Button {
                            selectedUser = profile.id
                        } label: {
                            HStack {
                                Text(profile.displayName)
                                if selectedUser == profile.id {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedUser == nil ? "All Users" : userName(for: selectedUser))
                            .font(.system(size: 14, weight: .medium))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10))
                    }
                    .foregroundStyle(Theme.textPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Theme.bgElevated)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                Spacer()
            }
            
            // Chart
            HistoryScatterChart(data: filteredData, color: metricColor)
                .frame(height: 200)
            
            // Table
            HistoryTable(
                data: sortedData,
                metricColor: metricColor,
                sortColumn: $sortColumn,
                sortAscending: $sortAscending
            )
            
            // Load all-time button
            if appState.allTimeStats.isEmpty {
                Button {
                    Task {
                        for profile in appState.profiles {
                            await appState.loadAllTimeStats(for: profile)
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "arrow.down.circle")
                        Text("Load All-Time History")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.secondary)
            }
        }
    }
    
    private var metricColor: Color {
        switch selectedMetric {
        case .readiness: return Theme.readinessColor
        case .sleep: return Theme.sleepColor
        case .activity: return Theme.activityColor
        }
    }
    
    private func userName(for id: String?) -> String {
        appState.profiles.first { $0.id == id }?.displayName ?? "Unknown"
    }
}

// MARK: - History Metric

enum HistoryMetric: String, CaseIterable {
    case readiness = "Readiness"
    case sleep = "Sleep"
    case activity = "Activity"
}

// MARK: - Sort Column

enum SortColumn {
    case name, date, score
}

// MARK: - History Data Point

struct HistoryDataPoint: Identifiable {
    let id: String
    let userId: String
    let userName: String
    let day: String
    let score: Int
}

// MARK: - History Scatter Chart

private struct HistoryScatterChart: View {
    let data: [HistoryDataPoint]
    let color: Color
    
    var body: some View {
        if data.isEmpty {
            ContentUnavailableView(
                "No history data",
                systemImage: "chart.dots.scatter",
                description: Text("Historical scores will appear here")
            )
        } else {
            Chart(data) { point in
                PointMark(
                    x: .value("Date", point.day),
                    y: .value("Score", point.score)
                )
                .foregroundStyle(color.opacity(0.7))
                .symbolSize(30)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: 7)) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Theme.borderSubtle)
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Theme.borderSubtle)
                    AxisValueLabel()
                        .foregroundStyle(Theme.textMuted)
                }
            }
            .chartYScale(domain: 0...100)
        }
    }
}

// MARK: - History Table

private struct HistoryTable: View {
    let data: [HistoryDataPoint]
    let metricColor: Color
    @Binding var sortColumn: SortColumn
    @Binding var sortAscending: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                SortableHeader(title: "User", column: .name, currentColumn: $sortColumn, ascending: $sortAscending)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                SortableHeader(title: "Date", column: .date, currentColumn: $sortColumn, ascending: $sortAscending)
                    .frame(width: 100)
                
                SortableHeader(title: "Score", column: .score, currentColumn: $sortColumn, ascending: $sortAscending)
                    .frame(width: 60)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.03))
            
            // Rows
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(data.prefix(50)) { point in
                        HStack {
                            Text(point.userName)
                                .font(.system(size: 13))
                                .foregroundStyle(Theme.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Text(formatDate(point.day))
                                .font(.system(size: 12))
                                .foregroundStyle(Theme.textMuted)
                                .frame(width: 100)
                            
                            Text("\(point.score)")
                                .font(.system(size: 13, weight: .medium, design: .monospaced))
                                .foregroundStyle(metricColor)
                                .frame(width: 60)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        
                        Divider()
                            .background(Theme.borderSubtle)
                    }
                }
            }
            .frame(maxHeight: 300)
        }
        .background(Theme.bgRaised)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Theme.borderSubtle, lineWidth: 1)
        )
    }
    
    private func formatDate(_ day: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: day) else { return day }
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
}

// MARK: - Sortable Header

private struct SortableHeader: View {
    let title: String
    let column: SortColumn
    @Binding var currentColumn: SortColumn
    @Binding var ascending: Bool
    
    var body: some View {
        Button {
            if currentColumn == column {
                ascending.toggle()
            } else {
                currentColumn = column
                ascending = false
            }
        } label: {
            HStack(spacing: 4) {
                Text(title.uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(currentColumn == column ? Theme.textPrimary : Theme.textMuted)
                
                if currentColumn == column {
                    Image(systemName: ascending ? "chevron.up" : "chevron.down")
                        .font(.system(size: 8))
                        .foregroundStyle(Theme.accent)
                }
            }
        }
    }
}

#Preview {
    ScrollView {
        HistoryView()
            .padding()
    }
    .background(Theme.bgBase)
    .environment(AppState())
}
