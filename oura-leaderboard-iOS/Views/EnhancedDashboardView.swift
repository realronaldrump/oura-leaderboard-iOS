import SwiftUI
import Foundation

// MARK: - Enhanced Dashboard View

struct EnhancedDashboardView: View {
    @Environment(AppState.self) private var appState
    @State private var showingProfileSwitcher = false
    @State private var selectedTab = 0
    
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
        NavigationStack {
            ZStack {
                Theme.bgBase.ignoresSafeArea()
                
                if appState.globalLoadingState.isLoading && appState.activeStats == nil {
                    EnhancedLoadingView()
                } else {
                    TabView(selection: $selectedTab) {
                        // Daily Tab
                        ScrollView {
                            LazyVStack(spacing: 24) {
                                HeroSection()
                                    .padding(.top, 12)
                                
                                EnhancedDailyContentView()
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 100)
                        }
                        .refreshable {
                            await appState.refreshActiveProfile()
                        }
                        .tag(0)
                        
                        // Versus Tab (if multiple users)
                        if appState.profiles.count > 1 {
                            ScrollView {
                                VersusContentView()
                                    .padding(.horizontal, 16)
                                    .padding(.bottom, 100)
                            }
                            .tag(1)
                        }
                        
                        // History Tab
                        ScrollView {
                            HistoryContentView()
                                .padding(.horizontal, 16)
                                .padding(.bottom, 100)
                        }
                        .tag(appState.profiles.count > 1 ? 2 : 1)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: selectedTab)
                }
                
                // Floating Tab Bar
                VStack {
                    Spacer()
                    FloatingTabBar(selectedTab: $selectedTab, hasMultipleProfiles: appState.profiles.count > 1)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    ProfileButton(showingProfileSwitcher: $showingProfileSwitcher)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    NotificationButton()
                }
            }
        }
        .sheet(isPresented: $showingProfileSwitcher) {
            ProfileSwitcherSheet()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .alert("Error", isPresented: isShowingError) {
            Button("OK") {
                appState.errorMessage = nil
            }
        } message: {
            Text(appState.errorMessage ?? "An error occurred")
        }
        .overlay(alignment: .top) {
            if appState.globalLoadingState.isLoading {
                SyncBanner()
            }
        }
        .task {
            if appState.activeProfile != nil && appState.activeStats == nil {
                await appState.refreshActiveProfile()
            }
        }
    }
}

// MARK: - Enhanced Loading View

private struct EnhancedLoadingView: View {
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 1
    
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                // Outer ring
                Circle()
                    .stroke(Theme.bgRaised, lineWidth: 4)
                    .frame(width: 80, height: 80)
                
                // Animated gradient ring
                Circle()
                    .trim(from: 0, to: 0.8)
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [
                                Theme.accentCyan,
                                Theme.accentPurple,
                                Theme.accentCyan
                            ]),
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(rotation))
                
                // Inner pulsing circle
                Circle()
                    .fill(Theme.accentCyan.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .scaleEffect(scale)
                    .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: scale)
            }
            
            VStack(spacing: 8) {
                Text("Syncing your health data")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                
                Text("This usually takes a few seconds")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.textMuted)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                rotation = 360
            }
            scale = 1.2
        }
    }
}

// MARK: - Hero Section

private struct HeroSection: View {
    @Environment(AppState.self) private var appState
    
    private var userName: String {
        appState.activeProfile?.displayName ?? "User"
    }
    
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return "Good morning"
        case 12..<17:
            return "Good afternoon"
        case 17..<22:
            return "Good evening"
        default:
            return "Good night"
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Text("\(greeting), \(userName)")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack {
                Text("Your health snapshot")
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.textSecondary)
                
                Spacer()
                
                if let lastSync = appState.lastSyncAt {
                    Label(timeAgo(from: lastSync), systemImage: "arrow.clockwise")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Theme.textMuted)
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Floating Tab Bar

private struct FloatingTabBar: View {
    @Binding var selectedTab: Int
    let hasMultipleProfiles: Bool
    @Environment(AppState.self) private var appState
    
    private var tabs: [(String, String)] {
        var items = [("house.fill", "Daily")]
        if hasMultipleProfiles {
            items.append(("person.2.fill", "Versus"))
        }
        items.append(("chart.line.uptrend.xyaxis", "History"))
        return items
    }
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                TabButton(
                    icon: tabs[index].0,
                    title: tabs[index].1,
                    isSelected: selectedTab == index
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selectedTab = index
                        appState.provideHapticFeedback(.selection)
                    }
                }
            }
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(Theme.bgRaised, lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
    }
}

// MARK: - Tab Button

private struct TabButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .symbolRenderingMode(isSelected ? .multicolor : .monochrome)
                
                Text(title)
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundStyle(isSelected ? Theme.accentCyan : Theme.textMuted)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                isSelected ? Theme.accentCyan.opacity(0.1) : Color.clear,
                in: RoundedRectangle(cornerRadius: 20)
            )
            .scaleEffect(isSelected ? 1.05 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
        }
    }
}

// MARK: - Profile Button

private struct ProfileButton: View {
    @Binding var showingProfileSwitcher: Bool
    @Environment(AppState.self) private var appState
    
    var body: some View {
        Button {
            showingProfileSwitcher = true
            appState.provideHapticFeedback(.light)
        } label: {
            HStack(spacing: 8) {
                // Profile avatar
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Theme.accentCyan, Theme.accentPurple]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 32, height: 32)
                    
                    Text(appState.activeProfile?.initials ?? "?")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                }
                
                if appState.profiles.count > 1 {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Theme.textMuted)
                }
            }
        }
    }
}

// MARK: - Notification Button

private struct NotificationButton: View {
    @State private var hasNotifications = false
    @Environment(AppState.self) private var appState
    
    var body: some View {
        Button {
            appState.provideHapticFeedback(.light)
            // Handle notifications
        } label: {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "bell")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Theme.textPrimary)
                
                if hasNotifications {
                    Circle()
                        .fill(Theme.accentRose)
                        .frame(width: 8, height: 8)
                        .offset(x: 4, y: -2)
                }
            }
        }
    }
}

// MARK: - Profile Switcher Sheet

private struct ProfileSwitcherSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var showingAddProfile = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(appState.profiles) { profile in
                        ProfileRow(
                            profile: profile,
                            isActive: profile.id == appState.activeProfileId
                        ) {
                            appState.switchProfile(profile.id)
                            appState.provideHapticFeedback(.success)
                            dismiss()
                        }
                    }
                    
                    // Add profile button
                    Button {
                        showingAddProfile = true
                        appState.provideHapticFeedback(.light)
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(Theme.accentCyan)
                            
                            Text("Add Another Profile")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(Theme.textPrimary)
                            
                            Spacer()
                        }
                        .padding()
                        .background(Theme.bgRaised)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
                .padding()
            }
            .background(Theme.bgBase)
            .navigationTitle("Switch Profile")
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
        .sheet(isPresented: $showingAddProfile) {
            AddProfileView()
        }
    }
}

// MARK: - Profile Row

private struct ProfileRow: View {
    let profile: UserProfile
    let isActive: Bool
    let onTap: () -> Void
    @State private var showingDeleteConfirmation = false
    @Environment(AppState.self) private var appState
    
    var body: some View {
        HStack {
            // Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Theme.accentCyan, Theme.accentPurple]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)
                
                Text(profile.initials)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(profile.displayName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                
                Text(profile.email ?? "No email")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.textMuted)
            }
            
            Spacer()
            
            if isActive {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(Theme.accentGreen)
            }
        }
        .padding()
        .background(isActive ? Theme.accentCyan.opacity(0.1) : Theme.bgRaised)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isActive ? Theme.accentCyan : Color.clear, lineWidth: 2)
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .contextMenu {
            Button {
                showingDeleteConfirmation = true
            } label: {
                Label("Remove Profile", systemImage: "trash")
            }
            .disabled(isActive)
        }
        .confirmationDialog(
            "Remove Profile",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Remove", role: .destructive) {
                appState.removeProfile(id: profile.id)
                appState.provideHapticFeedback(.warning)
            }
        } message: {
            Text("Are you sure you want to remove \(profile.displayName)?")
        }
    }
}

// MARK: - Add Profile View

private struct AddProfileView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()
                
                Image(systemName: "person.badge.plus")
                    .font(.system(size: 64))
                    .foregroundStyle(Theme.accentCyan)
                
                Text("Connect Another Oura Account")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                
                Text("Add another profile to compare health metrics and compete with friends or family members.")
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                Spacer()
                
                Button {
                    dismiss()
                    Task {
                        await appState.login()
                    }
                } label: {
                    HStack {
                        Image(systemName: "link.circle.fill")
                        Text("Connect Oura Account")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.primary)
                .padding(.horizontal, 24)
                
                Spacer()
            }
            .background(Theme.bgBase)
            .navigationTitle("Add Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(Theme.textMuted)
                }
            }
        }
    }
}

// MARK: - Sync Banner

private struct SyncBanner: View {
    @Environment(AppState.self) private var appState
    @State private var opacity: Double = 0
    
    var body: some View {
        HStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(0.8)
            
            Text(appState.globalLoadingState.message ?? "Syncing...")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Theme.accentCyan, Theme.accentPurple]),
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Theme.accentCyan.opacity(0.3), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .opacity(opacity)
        .animation(.easeInOut(duration: 0.3), value: opacity)
        .onAppear {
            opacity = 1
        }
        .transition(.asymmetric(
            insertion: .push(from: .top).combined(with: .opacity),
            removal: .push(from: .top).combined(with: .opacity)
        ))
    }
}

// MARK: - Versus Content View (Placeholder)

private struct VersusContentView: View {
    var body: some View {
        VStack {
            Text("Versus View")
                .font(.largeTitle)
                .foregroundStyle(Theme.textPrimary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - History Content View (Placeholder)

private struct HistoryContentView: View {
    var body: some View {
        VStack {
            Text("History View")
                .font(.largeTitle)
                .foregroundStyle(Theme.textPrimary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    EnhancedDashboardView()
        .environment(AppState())
        .preferredColorScheme(.dark)
}