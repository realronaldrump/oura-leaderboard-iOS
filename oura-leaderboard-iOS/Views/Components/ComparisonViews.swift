import SwiftUI

// MARK: - Bi-Directional Bar

struct BiDirectionalBarView: View {
    let leftValue: Int
    let rightValue: Int
    var leftLabel: String? = nil
    var rightLabel: String? = nil
    let label: String
    var max: Int = 100
    var unit: String = ""
    var inverse: Bool = false  // If true, lower is better
    
    private var leftWins: Bool {
        inverse ? leftValue < rightValue : leftValue > rightValue
    }
    
    private var isTie: Bool {
        leftValue == rightValue
    }
    
    private var leftPercent: CGFloat {
        min(CGFloat(leftValue) / CGFloat(max), 1.0)
    }
    
    private var rightPercent: CGFloat {
        min(CGFloat(rightValue) / CGFloat(max), 1.0)
    }
    
    var body: some View {
        VStack(spacing: 4) {
            // Labels row
            HStack {
                Text("\(leftLabel ?? "\(leftValue)")\(unit.isEmpty ? "" : " \(unit)")")
                    .font(.system(size: 11, weight: leftWins && !isTie ? .bold : .regular, design: .monospaced))
                    .foregroundStyle(leftWins && !isTie ? Theme.accentGreen : Theme.textMuted)
                
                Spacer()
                
                Text(label.uppercased())
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(0.5)
                    .foregroundStyle(Theme.textPrimary)
                
                Spacer()
                
                Text("\(rightLabel ?? "\(rightValue)")\(unit.isEmpty ? "" : " \(unit)")")
                    .font(.system(size: 11, weight: !leftWins && !isTie ? .bold : .regular, design: .monospaced))
                    .foregroundStyle(!leftWins && !isTie ? Theme.accentPurple : Theme.textMuted)
            }
            
            // Bar
            GeometryReader { geo in
                let halfWidth = geo.size.width / 2
                
                ZStack {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Theme.bgElevated)
                        .frame(height: 8)
                    
                    // Center marker
                    Rectangle()
                        .fill(Theme.borderDefault.opacity(0.5))
                        .frame(width: 1, height: 8)
                    
                    HStack(spacing: 0) {
                        // Left bar (grows right-to-left from center)
                        HStack {
                            Spacer()
                            RoundedRectangle(cornerRadius: 4)
                                .fill(leftWins ? Theme.accentGreen : Theme.textMuted.opacity(0.3))
                                .frame(width: halfWidth * leftPercent, height: 8)
                        }
                        .frame(width: halfWidth)
                        
                        // Right bar (grows left-to-right from center)
                        HStack {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(!leftWins && !isTie ? Theme.accentPurple : Theme.textMuted.opacity(0.3))
                                .frame(width: halfWidth * rightPercent, height: 8)
                            Spacer()
                        }
                        .frame(width: halfWidth)
                    }
                }
            }
            .frame(height: 8)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Metric Comparison Group

struct MetricComparisonGroupView: View {
    let title: String
    var scoreA: Int? = nil
    var scoreB: Int? = nil
    let metrics: [ComparisonMetric]
    var defaultOpen: Bool = false
    
    @State private var isOpen: Bool
    
    init(title: String, scoreA: Int? = nil, scoreB: Int? = nil, metrics: [ComparisonMetric], defaultOpen: Bool = false) {
        self.title = title
        self.scoreA = scoreA
        self.scoreB = scoreB
        self.metrics = metrics
        self.defaultOpen = defaultOpen
        self._isOpen = State(initialValue: defaultOpen)
    }
    
    private var scoreAWins: Bool {
        (scoreA ?? 0) > (scoreB ?? 0)
    }
    
    private var scoreBWins: Bool {
        (scoreB ?? 0) > (scoreA ?? 0)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header button
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isOpen.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: isOpen ? "chevron.down" : "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Theme.textMuted)
                    
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    
                    Spacer()
                    
                    if scoreA != nil && scoreB != nil {
                        HStack(spacing: 8) {
                            Text("\(scoreA ?? 0)")
                                .font(.system(size: 14, weight: scoreAWins ? .bold : .regular, design: .monospaced))
                                .foregroundStyle(scoreAWins ? Theme.accentGreen : Theme.textMuted)
                            
                            Text("VS")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(Theme.textDim)
                            
                            Text("\(scoreB ?? 0)")
                                .font(.system(size: 14, weight: scoreBWins ? .bold : .regular, design: .monospaced))
                                .foregroundStyle(scoreBWins ? Theme.accentPurple : Theme.textMuted)
                        }
                    }
                }
                .padding(16)
                .background(Theme.bgElevated.opacity(0.5))
            }
            .buttonStyle(.plain)
            
            // Content
            if isOpen {
                VStack(spacing: 4) {
                    ForEach(metrics) { metric in
                        if let valA = metric.valA, let valB = metric.valB {
                            BiDirectionalBarView(
                                leftValue: valA,
                                rightValue: valB,
                                label: metric.label,
                                max: metric.max,
                                unit: metric.unit,
                                inverse: metric.inverse
                            )
                        }
                    }
                }
                .padding(16)
                .transition(.opacity.combined(with: .move(edge: .top)))
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

// MARK: - Comparison Metric

struct ComparisonMetric: Identifiable {
    let id = UUID()
    let label: String
    let valA: Int?
    let valB: Int?
    var unit: String = ""
    var inverse: Bool = false
    var max: Int = 100
}

// MARK: - Floating Orb View

struct FloatingOrbView: View {
    var size: CGFloat = 80
    var color: Color = Theme.accentCyan
    var delay: Double = 0
    
    @State private var offset: CGFloat = 0
    
    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [color.opacity(0.3), color.opacity(0.1), .clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: size / 2
                )
            )
            .frame(width: size, height: size)
            .blur(radius: size * 0.2)
            .offset(y: offset)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 6)
                    .repeatForever(autoreverses: true)
                    .delay(delay)
                ) {
                    offset = 20
                }
            }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 24) {
            BiDirectionalBarView(
                leftValue: 85,
                rightValue: 72,
                label: "Sleep Score",
                max: 100
            )
            
            MetricComparisonGroupView(
                title: "Readiness",
                scoreA: 85,
                scoreB: 78,
                metrics: [
                    ComparisonMetric(label: "Resting HR", valA: 85, valB: 72, max: 100),
                    ComparisonMetric(label: "HRV Balance", valA: 90, valB: 82, max: 100),
                    ComparisonMetric(label: "Sleep Balance", valA: 78, valB: 85, max: 100),
                ],
                defaultOpen: true
            )
        }
        .padding()
    }
    .background(Theme.bgBase)
}
