import SwiftUI

// MARK: - Metric Card (used throughout dashboard)
struct MetricCard: View {
    var title: String
    var value: String
    var unit: String = ""
    var icon: String
    var iconColor: Color
    var progress: Double? = nil
    var progressColor: Color = AppTheme.accentGreen
    var subtitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        Button(action: { action?() }) {
            VStack(alignment: .leading, spacing: 10) {
                // Header
                HStack(spacing: 8) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(iconColor.opacity(0.15))
                            .frame(width: 32, height: 32)
                        Image(systemName: icon)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(iconColor)
                    }
                    Text(title)
                        .font(AppFont.subheadline(.medium))
                        .foregroundColor(AppTheme.textSecondary)
                    Spacer()
                    if action != nil {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(AppTheme.textTertiary)
                    }
                }

                // Value
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text(value)
                        .font(AppFont.title1(.bold))
                        .foregroundColor(AppTheme.textPrimary)
                    if !unit.isEmpty {
                        Text(unit)
                            .font(AppFont.subheadline())
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }

                // Progress
                if let p = progress {
                    LinearProgressBar(progress: p, color: progressColor, height: 5)
                }

                // Subtitle
                if let sub = subtitle {
                    Text(sub)
                        .font(AppFont.caption())
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
            .padding(Constants.Layout.padding)
            .cardStyle()
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Wide Metric Card
struct WideMetricCard: View {
    var title: String
    var value: String
    var unit: String = ""
    var icon: String
    var gradient: LinearGradient
    var progress: Double? = nil
    var detail: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                if let d = detail {
                    Text(d)
                        .font(AppFont.caption(.semibold))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(.white.opacity(0.15))
                        .cornerRadius(8)
                }
            }
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(value)
                    .font(AppFont.bigNumber())
                    .foregroundColor(.white)
                Text(unit)
                    .font(AppFont.callout())
                    .foregroundColor(.white.opacity(0.7))
            }
            Text(title)
                .font(AppFont.subheadline())
                .foregroundColor(.white.opacity(0.7))

            if let p = progress {
                LinearProgressBar(progress: p, color: .white.opacity(0.9), height: 5,
                                  backgroundColor: .white.opacity(0.2))
            }
        }
        .padding(Constants.Layout.padding)
        .gradientCard(gradient)
    }
}

// MARK: - Score Badge
struct ScoreBadge: View {
    var score: Int
    var label: String
    var color: Color

    var statusLabel: String {
        switch score {
        case 80...100: return "Excellent"
        case 60...79:  return "Good"
        case 40...59:  return "Fair"
        default:       return "Poor"
        }
    }

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 64, height: 64)
                Text("\(score)")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundColor(color)
            }
            Text(label)
                .font(AppFont.caption(.semibold))
                .foregroundColor(AppTheme.textSecondary)
            Text(statusLabel)
                .font(AppFont.caption())
                .foregroundColor(color)
        }
    }
}

// MARK: - Macro Row
struct MacroRow: View {
    var label: String
    var consumed: Double
    var goal: Double
    var color: Color
    var unit: String = "g"

    var progress: Double { (consumed / max(1, goal)).clamped01 }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(AppFont.subheadline(.semibold))
                    .foregroundColor(AppTheme.textPrimary)
                Spacer()
                Text("\(Int(consumed))\(unit)")
                    .font(AppFont.subheadline(.bold))
                    .foregroundColor(color)
                Text("/ \(Int(goal))\(unit)")
                    .font(AppFont.caption())
                    .foregroundColor(AppTheme.textSecondary)
            }
            LinearProgressBar(progress: progress, color: color, height: 7)
        }
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    var title: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        HStack {
            Text(title)
                .font(AppFont.title3(.bold))
                .foregroundColor(AppTheme.textPrimary)
            Spacer()
            if let atitle = actionTitle, let ac = action {
                Button(atitle, action: ac)
                    .font(AppFont.subheadline(.semibold))
                    .foregroundColor(AppTheme.accent)
            }
        }
    }
}

// MARK: - Floating Add Button
struct FloatingAddButton: View {
    var action: () -> Void
    var gradient: LinearGradient = AppTheme.gradientPrimary

    var body: some View {
        Button(action: { HapticFeedback.medium(); action() }) {
            ZStack {
                Circle()
                    .fill(gradient)
                    .frame(width: 56, height: 56)
                    .shadow(color: AppTheme.accent.opacity(0.4), radius: 12, y: 4)
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
            }
        }
    }
}

// MARK: - Pill Tag
struct PillTag: View {
    var text: String
    var color: Color = AppTheme.accent

    var body: some View {
        Text(text)
            .font(AppFont.caption(.semibold))
            .foregroundColor(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .cornerRadius(20)
    }
}

// MARK: - Empty State
struct EmptyStateView: View {
    var icon: String
    var title: String
    var message: String
    var buttonTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(AppTheme.textTertiary)
            Text(title)
                .font(AppFont.headline())
                .foregroundColor(AppTheme.textPrimary)
            Text(message)
                .font(AppFont.subheadline())
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            if let bt = buttonTitle, let ac = action {
                Button(bt, action: ac)
                    .font(AppFont.headline())
                    .foregroundColor(.white)
                    .padding(.horizontal, 24).padding(.vertical, 12)
                    .background(AppTheme.gradientPrimary)
                    .cornerRadius(12)
            }
        }
        .padding()
    }
}
