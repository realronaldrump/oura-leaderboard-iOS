import SwiftUI
import Charts

// MARK: - Heart Rate Chart View

struct HeartRateChartView: View {
    let data: [HeartRate]
    var showLabels: Bool = false
    var height: CGFloat = 180

    private struct Summary {
        var points: [HeartRatePoint] = []
        var minBpm: Int?
        var maxBpm: Int?
        var avgBpm: Int?
    }

    /// Parse timestamps once and derive all stats in a single pass.
    /// (Previously each stat re-parsed the entire dataset.)
    private var summary: Summary {
        let points = data.compactMap { hr -> HeartRatePoint? in
            guard let date = Formatters.parseISO8601(hr.timestamp) else { return nil }
            return HeartRatePoint(date: date, bpm: hr.bpm, source: hr.source)
        }.sorted { $0.date < $1.date }

        var summary = Summary(points: points)
        if !points.isEmpty {
            let bpms = points.map(\.bpm)
            summary.minBpm = bpms.min()
            summary.maxBpm = bpms.max()
            summary.avgBpm = bpms.reduce(0, +) / bpms.count
        }
        return summary
    }

    var body: some View {
        let summary = summary

        VStack(alignment: .leading, spacing: 8) {
            if showLabels && !summary.points.isEmpty {
                HStack(spacing: 16) {
                    StatLabel(label: "Min", value: summary.minBpm, color: Theme.hrColor)
                    StatLabel(label: "Avg", value: summary.avgBpm, color: Theme.textPrimary)
                    StatLabel(label: "Max", value: summary.maxBpm, color: Theme.hrColor)
                    Spacer()
                }
            }

            if summary.points.isEmpty {
                ContentUnavailableView(
                    "No heart rate data",
                    systemImage: "heart.slash",
                    description: Text("Heart rate for this day will appear here")
                )
                .frame(height: height)
            } else {
                Chart {
                    ForEach(summary.points) { point in
                        LineMark(
                            x: .value("Time", point.date),
                            y: .value("BPM", point.bpm)
                        )
                        .foregroundStyle(Theme.hrColor)
                        .lineStyle(StrokeStyle(lineWidth: 1.5))
                    }

                    if let avg = summary.avgBpm {
                        RuleMark(y: .value("Average", avg))
                            .foregroundStyle(Theme.borderDefault)
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .hour, count: 4)) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Theme.borderSubtle)
                        AxisValueLabel(format: .dateTime.hour())
                            .foregroundStyle(Theme.textMuted)
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Theme.borderSubtle)
                        AxisValueLabel()
                            .foregroundStyle(Theme.textMuted)
                    }
                }
                .frame(height: height)
            }
        }
    }
}

// MARK: - Heart Rate Point

struct HeartRatePoint: Identifiable {
    let id = UUID()
    let date: Date
    let bpm: Int
    let source: String
}

// MARK: - Stat Label

private struct StatLabel: View {
    let label: String
    let value: Int?
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Text("\(label):")
                .font(.system(size: 11))
                .foregroundStyle(Theme.textSecondary)
            Text(value != nil ? "\(value!)" : "--")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(color)
        }
    }
}

// MARK: - HRV Chart View

struct HRVChartView: View {
    let sessions: [SleepSession]
    var days: Int = 30
    var height: CGFloat = 160
    
    // sessions arrive newest first; reverse for chronological left-to-right
    private var chartData: [HRVPoint] {
        sessions.prefix(days).reversed().compactMap { session -> HRVPoint? in
            guard let hrv = session.averageHrv else { return nil }
            return HRVPoint(day: String(session.day.suffix(5)), hrv: hrv)
        }
    }

    var body: some View {
        let chartData = chartData

        VStack(alignment: .leading, spacing: 8) {
            Text("HRV TREND (30 DAYS)")
                .font(.system(size: 11, weight: .semibold))
                .tracking(1)
                .foregroundStyle(Theme.textMuted)

            if chartData.isEmpty {
                ContentUnavailableView(
                    "No HRV data",
                    systemImage: "waveform.path.ecg",
                    description: Text("HRV trend will appear here")
                )
                .frame(height: height)
            } else {
                Chart(chartData) { point in
                    LineMark(
                        x: .value("Day", point.day),
                        y: .value("HRV", point.hrv)
                    )
                    .foregroundStyle(Theme.hrvColor)
                    .lineStyle(StrokeStyle(lineWidth: 2))

                    AreaMark(
                        x: .value("Day", point.day),
                        y: .value("HRV", point.hrv)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Theme.hrvColor.opacity(0.3), Theme.hrvColor.opacity(0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Theme.borderSubtle)
                        AxisValueLabel()
                            .foregroundStyle(Theme.textMuted)
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Theme.borderSubtle)
                        AxisValueLabel {
                            if let intValue = value.as(Int.self) {
                                Text("\(intValue) ms")
                                    .font(.system(size: 10))
                                    .foregroundStyle(Theme.textMuted)
                            }
                        }
                    }
                }
                .frame(height: height)
            }
        }
    }
}

// MARK: - HRV Point

struct HRVPoint: Identifiable {
    let id = UUID()
    let day: String
    let hrv: Int
}

// MARK: - Sleep Stages Chart

struct SleepStagesChartView: View {
    let sessions: [SleepSession]
    var days: Int = 14
    var height: CGFloat = 200
    
    // sessions arrive newest first; reverse for chronological left-to-right
    private var chartData: [SleepStageData] {
        sessions.prefix(days).reversed().map { session in
            SleepStageData(
                day: String(session.day.suffix(5)),
                deep: Double(session.deepSleepDuration ?? 0) / 3600,
                light: Double(session.lightSleepDuration ?? 0) / 3600,
                rem: Double(session.remSleepDuration ?? 0) / 3600,
                awake: Double(session.awakeTime ?? 0) / 3600
            )
        }
    }

    var body: some View {
        let chartData = chartData

        VStack(alignment: .leading, spacing: 8) {
            Text("SLEEP ARCHITECTURE (14 DAYS)")
                .font(.system(size: 11, weight: .semibold))
                .tracking(1)
                .foregroundStyle(Theme.textMuted)
            
            if chartData.isEmpty {
                ContentUnavailableView(
                    "No sleep data",
                    systemImage: "bed.double",
                    description: Text("Sleep stages will appear here")
                )
                .frame(height: height)
            } else {
                Chart(chartData) { data in
                    BarMark(
                        x: .value("Day", data.day),
                        y: .value("Hours", data.deep)
                    )
                    .foregroundStyle(Theme.deepSleep)
                    
                    BarMark(
                        x: .value("Day", data.day),
                        y: .value("Hours", data.light)
                    )
                    .foregroundStyle(Theme.lightSleep)
                    
                    BarMark(
                        x: .value("Day", data.day),
                        y: .value("Hours", data.rem)
                    )
                    .foregroundStyle(Theme.remSleep)
                    
                    BarMark(
                        x: .value("Day", data.day),
                        y: .value("Hours", data.awake)
                    )
                    .foregroundStyle(Theme.awake)
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel()
                            .foregroundStyle(Theme.textMuted)
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Theme.borderSubtle)
                        AxisValueLabel {
                            if let doubleValue = value.as(Double.self) {
                                Text("\(Int(doubleValue))h")
                                    .font(.system(size: 10))
                                    .foregroundStyle(Theme.textMuted)
                            }
                        }
                    }
                }
                .frame(height: height)
                
                // Legend
                HStack(spacing: 16) {
                    LegendItem(color: Theme.deepSleep, label: "Deep")
                    LegendItem(color: Theme.lightSleep, label: "Light")
                    LegendItem(color: Theme.remSleep, label: "REM")
                    LegendItem(color: Theme.awake, label: "Awake")
                }
                .padding(.top, 8)
            }
        }
    }
}

// MARK: - Sleep Stage Data

struct SleepStageData: Identifiable {
    let id = UUID()
    let day: String
    let deep: Double
    let light: Double
    let rem: Double
    let awake: Double
}

// MARK: - Legend Item

private struct LegendItem: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(Theme.textSecondary)
        }
    }
}

// MARK: - Mini History Chart (Sparkline)

struct HistoryChartView: View {
    let data: [Int?]
    let color: Color
    var height: CGFloat = 48
    
    // data arrives newest first; reverse for chronological left-to-right
    private var chartData: [ChartPoint] {
        data.prefix(7).reversed().enumerated().compactMap { index, score in
            guard let score = score else { return nil }
            return ChartPoint(index: index, value: score)
        }
    }
    
    var body: some View {
        if chartData.isEmpty {
            Rectangle()
                .fill(Theme.bgElevated)
                .frame(height: height)
        } else {
            Chart(chartData) { point in
                LineMark(
                    x: .value("Index", point.index),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(color)
                .lineStyle(StrokeStyle(lineWidth: 2))
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .frame(height: height)
        }
    }
}

private struct ChartPoint: Identifiable {
    let id = UUID()
    let index: Int
    let value: Int
}

#Preview {
    ScrollView {
        VStack(spacing: 24) {
            HeartRateChartView(data: [], showLabels: true)
                .glassCard()
            
            HRVChartView(sessions: [])
                .glassCard()
            
            SleepStagesChartView(sessions: [])
                .glassCard()
        }
        .padding()
    }
    .background(Theme.bgBase)
}
