import SwiftUI

// MARK: - Metric Card View

struct MetricCardView: View {
    let title: String
    let value: String
    var unit: String? = nil
    var subtext: String? = nil
    var color: Color = Theme.textPrimary
    var icon: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.textMuted)
                
                Spacer()
                
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundStyle(value != "--" ? color : Theme.textMuted)
                }
            }
            
            Spacer()
            
            // Value
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundStyle(value != "--" ? color : Theme.textMuted)
                    .shadow(color: value != "--" ? color.opacity(0.4) : .clear, radius: 30)
                
                if let unit = unit, value != "--" {
                    Text(unit)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Theme.textMuted)
                }
            }
            
            // Subtext
            if let subtext = subtext {
                Text(subtext)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textDim)
            }
        }
        .padding(16)
        .frame(minHeight: 100)
        .background(Theme.bgRaised)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Theme.borderSubtle, lineWidth: 1)
        )
    }
}

// MARK: - Small Metric Card (for grids)

struct SmallMetricCardView: View {
    let title: String
    let value: String
    var unit: String? = nil
    var color: Color = Theme.textPrimary
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Theme.textMuted)
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .foregroundStyle(value != "--" ? color : Theme.textMuted)
                
                if let unit = unit, value != "--" {
                    Text(unit)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Theme.textMuted)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Theme.bgRaised)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Theme.borderSubtle, lineWidth: 1)
        )
    }
}

#Preview {
    VStack(spacing: 16) {
        MetricCardView(
            title: "Total Sleep",
            value: "7h 30m",
            color: Theme.sleepColor,
            icon: "moon.fill"
        )
        
        HStack(spacing: 12) {
            SmallMetricCardView(title: "Steps", value: "8,432", color: Theme.activityColor)
            SmallMetricCardView(title: "HRV", value: "45", unit: "ms", color: Theme.hrvColor)
        }
    }
    .padding()
    .background(Theme.bgBase)
}
