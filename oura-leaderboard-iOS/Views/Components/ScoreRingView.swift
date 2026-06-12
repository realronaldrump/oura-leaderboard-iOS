import SwiftUI

// MARK: - Score Ring View

struct ScoreRingView: View {
    let score: Int?
    let label: String
    let color: Color
    var size: CGFloat = 120
    var showGlow: Bool = true
    var animated: Bool = true
    
    @State private var animationProgress: CGFloat = 0

    private var displayScore: Int { score ?? 0 }
    private var strokeWidth: CGFloat { size * 0.06 }
    private var radius: CGFloat { (size - strokeWidth * 2) / 2 }
    private var circumference: CGFloat { radius * 2 * .pi }
    private var offset: CGFloat { circumference - (CGFloat(displayScore) / 100) * circumference }
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                // Background glow
                if showGlow {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [color.opacity(0.2), .clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: size * 0.6
                            )
                        )
                        .blur(radius: size * 0.15)
                        .opacity(displayScore > 70 ? 0.6 : 0.3)
                }
                
                // Track circle
                Circle()
                    .stroke(Color.white.opacity(0.08), lineWidth: strokeWidth)
                    .frame(width: size - strokeWidth, height: size - strokeWidth)
                
                // Progress arc
                Circle()
                    .trim(from: 0, to: animated ? animationProgress : CGFloat(displayScore) / 100)
                    .stroke(
                        color,
                        style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round)
                    )
                    .frame(width: size - strokeWidth, height: size - strokeWidth)
                    .rotationEffect(.degrees(-90))
                    .shadow(color: showGlow ? color.opacity(0.5) : .clear, radius: 10)
                
                // Score text
                Text(score != nil ? "\(displayScore)" : "--")
                    .font(.system(size: size * 0.28, weight: .bold, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary)
                    .contentTransition(.numericText())
                    .animation(.easeOut(duration: 0.6), value: displayScore)
                    .shadow(color: showGlow ? color.opacity(0.6) : .clear, radius: 20)
            }
            .frame(width: size, height: size)

            // Label
            Text(label.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .tracking(1.5)
                .foregroundStyle(Theme.textMuted)
        }
        .onAppear {
            updateProgress()
        }
        .onChange(of: score) { _, _ in
            updateProgress()
        }
    }

    private func updateProgress() {
        if animated {
            withAnimation(.easeOut(duration: 1.2)) {
                animationProgress = CGFloat(displayScore) / 100
            }
        } else {
            animationProgress = CGFloat(displayScore) / 100
        }
    }
}

// MARK: - Mini Score Orb (for hero section)

struct ScoreOrbView: View {
    let score: Int
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Outer ring
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [color.opacity(0.2), color.opacity(0.05)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 48
                        )
                    )
                    .frame(width: 96, height: 96)
                    .overlay(
                        Circle()
                            .stroke(color.opacity(0.4), lineWidth: 2)
                    )
                    .shadow(color: color.opacity(0.4), radius: 30)
                
                // Progress ring
                Circle()
                    .trim(from: 0, to: CGFloat(score) / 100)
                    .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 86, height: 86)
                    .rotationEffect(.degrees(-90))
                    .shadow(color: color, radius: 6)
                
                // Score
                Text("\(score)")
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundStyle(color)
            }
            
            Text(label.uppercased())
                .font(.system(size: 10, weight: .medium))
                .tracking(1)
                .foregroundStyle(Theme.textMuted)
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        HStack(spacing: 24) {
            ScoreRingView(score: 85, label: "Readiness", color: Theme.readinessColor)
            ScoreRingView(score: 72, label: "Sleep", color: Theme.sleepColor)
            ScoreRingView(score: 90, label: "Activity", color: Theme.activityColor)
        }
        
        HStack(spacing: 24) {
            ScoreOrbView(score: 85, label: "Readiness", color: Theme.readinessColor)
            ScoreOrbView(score: 72, label: "Sleep", color: Theme.sleepColor)
        }
    }
    .padding()
    .background(Theme.bgBase)
}
