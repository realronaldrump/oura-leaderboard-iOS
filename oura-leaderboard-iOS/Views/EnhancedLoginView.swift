import SwiftUI

// MARK: - Enhanced Login View

struct EnhancedLoginView: View {
    @Environment(AppState.self) private var appState
    @State private var logoScale: CGFloat = 0.8
    @State private var contentOpacity: Double = 0
    
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
        GeometryReader { geometry in
            ZStack {
                // Background
                Theme.bgBase.ignoresSafeArea()
                
                // Animated gradient background
                AnimatedGradientBackground()
                    .ignoresSafeArea()
                
                // Floating orbs
                ForEach(0..<3) { index in
                    FloatingOrb(
                        size: orbSize(for: index),
                        color: orbColor(for: index),
                        delay: Double(index) * 2,
                        bounds: geometry.size
                    )
                }
                
                // Content
                VStack(spacing: 0) {
                    Spacer()
                    
                    // Logo and title
                    VStack(spacing: 24) {
                        // Animated logo
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Theme.accentCyan, Theme.accentPurple]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 120, height: 120)
                                .blur(radius: 20)
                                .scaleEffect(logoScale * 1.2)
                                .animation(.easeOut(duration: 2).repeatForever(autoreverses: true), value: logoScale)
                            
                            Image(systemName: "heart.circle.fill")
                                .font(.system(size: 80))
                                .foregroundStyle(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Theme.accentCyan, Theme.accentPurple]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .scaleEffect(logoScale)
                                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: logoScale)
                        }
                        
                        VStack(spacing: 12) {
                            Text("Oura Leaderboard")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundStyle(Theme.textPrimary)
                            
                            Text("Track, compare, and improve your health")
                                .font(.system(size: 18))
                                .foregroundStyle(Theme.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .opacity(contentOpacity)
                    .animation(.easeOut(duration: 0.8).delay(0.3), value: contentOpacity)
                    
                    Spacer()
                    
                    // Features list
                    VStack(spacing: 16) {
                        FeatureRow(
                            icon: "chart.line.uptrend.xyaxis",
                            title: "Track Your Progress",
                            description: "Monitor sleep, activity, and readiness scores",
                            color: Theme.sleepColor
                        )
                        
                        FeatureRow(
                            icon: "person.2.fill",
                            title: "Compare with Friends",
                            description: "See how you stack up in the leaderboard",
                            color: Theme.accentPurple
                        )
                        
                        FeatureRow(
                            icon: "brain.head.profile",
                            title: "AI Insights",
                            description: "Get personalized health recommendations",
                            color: Theme.accentCyan
                        )
                    }
                    .padding(.horizontal, 32)
                    .opacity(contentOpacity)
                    .animation(.easeOut(duration: 0.8).delay(0.5), value: contentOpacity)
                    
                    Spacer()
                    
                    // Connect button
                    VStack(spacing: 16) {
                        Button {
                            Task {
                                await appState.login()
                            }
                        } label: {
                            HStack {
                                Image(systemName: "link.circle.fill")
                                    .font(.system(size: 20))
                                Text("Connect Oura Ring")
                                    .font(.system(size: 17, weight: .semibold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Theme.accentCyan, Theme.accentPurple]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: Theme.accentCyan.opacity(0.3), radius: 12, x: 0, y: 6)
                        }
                        .disabled(appState.authStatus == .loading)
                        .scaleEffect(appState.authStatus == .loading ? 0.95 : 1)
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: appState.authStatus)
                        
                        if appState.authStatus == .loading {
                            HStack(spacing: 12) {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: Theme.accentCyan))
                                Text("Connecting...")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(Theme.textMuted)
                            }
                            .transition(.asymmetric(
                                insertion: .scale.combined(with: .opacity),
                                removal: .scale.combined(with: .opacity)
                            ))
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                    .opacity(contentOpacity)
                    .animation(.easeOut(duration: 0.8).delay(0.7), value: contentOpacity)
                    
                    // Footer
                    Text("By connecting, you agree to share your health data\nwithin this private application")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textDim)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.bottom, 32)
                        .opacity(contentOpacity)
                        .animation(.easeOut(duration: 0.8).delay(0.9), value: contentOpacity)
                }
            }
        }
        .alert("Login Error", isPresented: isShowingError) {
            Button("OK") {
                appState.errorMessage = nil
            }
        } message: {
            Text(appState.errorMessage ?? "Unknown error")
        }
        .onAppear {
            logoScale = 1
            contentOpacity = 1
        }
    }
    
    private func orbSize(for index: Int) -> CGFloat {
        switch index {
        case 0: return 200
        case 1: return 150
        default: return 100
        }
    }
    
    private func orbColor(for index: Int) -> Color {
        switch index {
        case 0: return Theme.accentCyan.opacity(0.3)
        case 1: return Theme.accentPurple.opacity(0.3)
        default: return Theme.accentGreen.opacity(0.3)
        }
    }
}

// MARK: - Animated Gradient Background

private struct AnimatedGradientBackground: View {
    @State private var gradientAngle: Double = 0
    
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Theme.bgBase,
                Theme.accentCyan.opacity(0.05),
                Theme.accentPurple.opacity(0.05),
                Theme.bgBase
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .hueRotation(.degrees(gradientAngle))
        .animation(.linear(duration: 20).repeatForever(autoreverses: true), value: gradientAngle)
        .onAppear {
            gradientAngle = 360
        }
    }
}

// MARK: - Floating Orb

private struct FloatingOrb: View {
    let size: CGFloat
    let color: Color
    let delay: Double
    let bounds: CGSize
    
    @State private var position: CGPoint = .zero

    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    gradient: Gradient(colors: [color, color.opacity(0.1)]),
                    center: .center,
                    startRadius: 0,
                    endRadius: size / 2
                )
            )
            .frame(width: size, height: size)
            .blur(radius: 10)
            .position(position)
            .onAppear {
                position = randomPosition()
                // Drift back and forth between two points forever - no
                // unbounded DispatchQueue recursion keeping the view alive
                withAnimation(
                    .easeInOut(duration: Double.random(in: 15...25))
                    .repeatForever(autoreverses: true)
                    .delay(delay)
                ) {
                    position = randomPosition()
                }
            }
    }

    private func randomPosition() -> CGPoint {
        // Guard against zero/small bounds during initial layout
        let minX = size / 2
        let maxX = Swift.max(bounds.width - size / 2, minX + 1)
        let minY = size / 2
        let maxY = Swift.max(bounds.height - size / 2, minY + 1)
        return CGPoint(
            x: CGFloat.random(in: minX...maxX),
            y: CGFloat.random(in: minY...maxY)
        )
    }
}

// MARK: - Feature Row

private struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    @State private var isVisible = false
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(color)
                .frame(width: 48, height: 48)
                .background(color.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.textMuted)
            }
            
            Spacer()
        }
        .opacity(isVisible ? 1 : 0)
        .offset(x: isVisible ? 0 : -20)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isVisible)
        .onAppear {
            withAnimation(.default.delay(0.1)) {
                isVisible = true
            }
        }
    }
}

#Preview {
    EnhancedLoginView()
        .environment(AppState())
        .preferredColorScheme(.dark)
}