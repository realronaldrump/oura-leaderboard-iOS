import SwiftUI

// MARK: - Contributors View

struct ContributorsView: View {
    let title: String
    let contributors: [ContributorItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .tracking(1)
                .foregroundStyle(Theme.textMuted)
            
            VStack(spacing: 12) {
                ForEach(contributors) { item in
                    ContributorRow(item: item)
                }
            }
        }
        .padding(16)
        .background(Theme.bgRaised)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Theme.borderSubtle, lineWidth: 1)
        )
    }
}

// MARK: - Contributor Item

struct ContributorItem: Identifiable {
    let id = UUID()
    let label: String
    let value: Int?
    let color: Color
}

// MARK: - Contributor Row

struct ContributorRow: View {
    let item: ContributorItem
    
    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text(item.label)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textSecondary)
                
                Spacer()
                
                Text(item.value != nil ? "\(item.value!)" : "--")
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary)
            }
            
            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Track
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white.opacity(0.05))
                        .frame(height: 4)
                    
                    // Fill
                    RoundedRectangle(cornerRadius: 2)
                        .fill(item.color)
                        .frame(width: geo.size.width * CGFloat(item.value ?? 0) / 100, height: 4)
                        .shadow(color: item.color.opacity(0.6), radius: 6)
                        .overlay(
                            // Shimmer effect placeholder
                            LinearGradient(
                                colors: [.clear, .white.opacity(0.2), .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 2))
                        )
                }
            }
            .frame(height: 4)
        }
    }
}

#Preview {
    ContributorsView(
        title: "Readiness Contributors",
        contributors: [
            ContributorItem(label: "Previous Night", value: 85, color: Theme.sleepColor),
            ContributorItem(label: "Sleep Balance", value: 72, color: Theme.sleepColor),
            ContributorItem(label: "HRV Balance", value: 90, color: Theme.hrvColor),
            ContributorItem(label: "Resting HR", value: 68, color: Theme.hrColor),
            ContributorItem(label: "Recovery Index", value: 78, color: Theme.readinessColor),
        ]
    )
    .padding()
    .background(Theme.bgBase)
}
