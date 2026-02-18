import SwiftUI

// MARK: - Animated Ring Progress
struct RingProgressView: View {
    var progress: Double        // 0.0 – 1.0
    var lineWidth: CGFloat = 12
    var size: CGFloat = 80
    var gradient: LinearGradient = AppTheme.gradientPrimary
    var backgroundColor: Color = Color.white.opacity(0.08)
    var label: String? = nil
    var sublabel: String? = nil
    @State private var animatedProgress: Double = 0

    var body: some View {
        ZStack {
            // Track ring
            Circle()
                .stroke(backgroundColor, lineWidth: lineWidth)

            // Progress ring
            Circle()
                .trim(from: 0, to: animatedProgress.clamped01)
                .stroke(gradient, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: Constants.Animation.slow), value: animatedProgress)

            // Center content
            if let label = label {
                VStack(spacing: 1) {
                    Text(label)
                        .font(AppFont.headline(.bold))
                        .foregroundColor(AppTheme.textPrimary)
                    if let sub = sublabel {
                        Text(sub)
                            .font(AppFont.caption())
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { newValue in
            withAnimation(.easeOut(duration: Constants.Animation.standard)) {
                animatedProgress = newValue
            }
        }
    }
}

// MARK: - Triple Ring (Activity rings like Apple Watch)
struct TripleRingView: View {
    var outerProgress: Double
    var middleProgress: Double
    var innerProgress: Double
    var size: CGFloat = 120
    var lineWidth: CGFloat = 10
    var outerGradient: LinearGradient = AppTheme.gradientOrange
    var middleGradient: LinearGradient = AppTheme.gradientGreen
    var innerGradient: LinearGradient = AppTheme.gradientBlue
    @State private var animated = false

    var body: some View {
        ZStack {
            RingProgressView(progress: animated ? outerProgress : 0,
                             lineWidth: lineWidth, size: size,
                             gradient: outerGradient, backgroundColor: Color.white.opacity(0.08))
            RingProgressView(progress: animated ? middleProgress : 0,
                             lineWidth: lineWidth, size: size - lineWidth * 2.5,
                             gradient: middleGradient, backgroundColor: Color.white.opacity(0.08))
            RingProgressView(progress: animated ? innerProgress : 0,
                             lineWidth: lineWidth, size: size - lineWidth * 5,
                             gradient: innerGradient, backgroundColor: Color.white.opacity(0.08))
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { animated = true }
        }
    }
}

// MARK: - Score Gauge
struct ScoreGaugeView: View {
    var score: Int    // 0–100
    var label: String
    var color: Color
    var size: CGFloat = 70

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .trim(from: 0.15, to: 0.85)
                    .stroke(color.opacity(0.15), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(90 + 180 * 0.15))
                Circle()
                    .trim(from: 0.15, to: 0.15 + 0.7 * (Double(score) / 100.0))
                    .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(90 + 180 * 0.15))
                    .animation(.easeOut(duration: 0.8), value: score)
                VStack(spacing: 0) {
                    Text("\(score)")
                        .font(AppFont.title2(.bold))
                        .foregroundColor(AppTheme.textPrimary)
                }
            }
            .frame(width: size, height: size)
            Text(label)
                .font(AppFont.caption())
                .foregroundColor(AppTheme.textSecondary)
        }
    }
}

// MARK: - Linear Progress Bar
struct LinearProgressBar: View {
    var progress: Double
    var color: Color = AppTheme.accentGreen
    var height: CGFloat = 6
    var showLabel: Bool = false
    var label: String = ""
    var backgroundColor: Color = Color.white.opacity(0.08)
    @State private var animated: Double = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if showLabel {
                HStack {
                    Text(label)
                        .font(AppFont.caption())
                        .foregroundColor(AppTheme.textSecondary)
                    Spacer()
                    Text("\(Int(progress * 100))%")
                        .font(AppFont.caption(.semibold))
                        .foregroundColor(color)
                }
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(backgroundColor)
                        .frame(height: height)
                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(color)
                        .frame(width: geo.size.width * animated.clamped01, height: height)
                        .animation(.easeOut(duration: Constants.Animation.slow), value: animated)
                }
            }
            .frame(height: height)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { animated = progress }
        }
        .onChange(of: progress) { animated = $0 }
    }
}
