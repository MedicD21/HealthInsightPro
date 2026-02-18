import SwiftUI

// MARK: - App Theme (Bright OS inspired dark health aesthetic)
struct AppTheme {

    // MARK: Backgrounds
    static let background        = Color(hex: "#0A0A0F")
    static let backgroundSecondary = Color(hex: "#12121A")
    static let cardBackground    = Color(hex: "#1A1A26")
    static let cardBackgroundAlt = Color(hex: "#1E1E2E")
    static let surfaceElevated   = Color(hex: "#252538")

    // MARK: Accent / Brand
    static let accent            = Color(hex: "#6C63FF")   // Purple-blue primary
    static let accentGreen       = Color(hex: "#00E5A0")   // Neon green (nutrition)
    static let accentBlue        = Color(hex: "#3B9EFF")   // Bright blue (activity/water)
    static let accentOrange      = Color(hex: "#FF7A3B")   // Orange (calories/energy)
    static let accentPink        = Color(hex: "#FF4F8B")   // Pink (heart rate)
    static let accentYellow      = Color(hex: "#FFD23F")   // Yellow (sleep)
    static let accentTeal        = Color(hex: "#00D4CC")   // Teal (recovery)
    static let accentPurple      = Color(hex: "#A855F7")   // Purple (insights)

    // MARK: Gradients
    static let gradientPrimary = LinearGradient(
        colors: [Color(hex: "#6C63FF"), Color(hex: "#A855F7")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let gradientGreen = LinearGradient(
        colors: [Color(hex: "#00E5A0"), Color(hex: "#00B37A")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let gradientBlue = LinearGradient(
        colors: [Color(hex: "#3B9EFF"), Color(hex: "#1A6FCC")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let gradientOrange = LinearGradient(
        colors: [Color(hex: "#FF7A3B"), Color(hex: "#CC5522")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let gradientPink = LinearGradient(
        colors: [Color(hex: "#FF4F8B"), Color(hex: "#CC2060")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let gradientYellow = LinearGradient(
        colors: [Color(hex: "#FFD23F"), Color(hex: "#E5A800")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let gradientOnboarding = LinearGradient(
        colors: [Color(hex: "#0A0A0F"), Color(hex: "#1A1430"), Color(hex: "#0A0A0F")],
        startPoint: .top, endPoint: .bottom
    )

    // MARK: Text
    static let textPrimary       = Color.white
    static let textSecondary     = Color(hex: "#9B9BB8")
    static let textTertiary      = Color(hex: "#5C5C7A")
    static let textOnAccent      = Color.white

    // MARK: Borders
    static let borderSubtle      = Color(hex: "#2A2A40")
    static let borderMedium      = Color(hex: "#3A3A55")

    // MARK: Status
    static let success           = Color(hex: "#00E5A0")
    static let warning           = Color(hex: "#FFD23F")
    static let error             = Color(hex: "#FF4F8B")

    // MARK: Tab icons color by section
    static func colorFor(tab: MainTab) -> Color {
        switch tab {
        case .dashboard:  return accent
        case .nutrition:  return accentGreen
        case .activity:   return accentBlue
        case .sleep:      return accentYellow
        case .insights:   return accentTeal
        case .profile:    return textSecondary
        }
    }
}

// MARK: - Typography
struct AppFont {
    static func largeTitle(_ weight: Font.Weight = .bold) -> Font { .system(size: 34, weight: weight, design: .rounded) }
    static func title1(_ weight: Font.Weight = .bold)    -> Font { .system(size: 28, weight: weight, design: .rounded) }
    static func title2(_ weight: Font.Weight = .semibold) -> Font { .system(size: 22, weight: weight, design: .rounded) }
    static func title3(_ weight: Font.Weight = .semibold) -> Font { .system(size: 20, weight: weight, design: .rounded) }
    static func headline(_ weight: Font.Weight = .semibold) -> Font { .system(size: 17, weight: weight, design: .rounded) }
    static func body(_ weight: Font.Weight = .regular)   -> Font { .system(size: 16, weight: weight, design: .rounded) }
    static func callout(_ weight: Font.Weight = .regular) -> Font { .system(size: 15, weight: weight, design: .rounded) }
    static func subheadline(_ weight: Font.Weight = .regular) -> Font { .system(size: 14, weight: weight, design: .rounded) }
    static func footnote(_ weight: Font.Weight = .regular) -> Font { .system(size: 13, weight: weight, design: .rounded) }
    static func caption(_ weight: Font.Weight = .regular) -> Font { .system(size: 12, weight: weight, design: .rounded) }
    static func metric()  -> Font { .system(size: 36, weight: .bold, design: .rounded) }
    static func bigNumber() -> Font { .system(size: 48, weight: .black, design: .rounded) }
}

// MARK: - Main Tab enum
enum MainTab: Int, CaseIterable {
    case dashboard, nutrition, activity, sleep, insights, profile

    var title: String {
        switch self {
        case .dashboard:  return "Home"
        case .nutrition:  return "Nutrition"
        case .activity:   return "Activity"
        case .sleep:      return "Sleep"
        case .insights:   return "Insights"
        case .profile:    return "Profile"
        }
    }
    var icon: String {
        switch self {
        case .dashboard:  return "house.fill"
        case .nutrition:  return "fork.knife"
        case .activity:   return "figure.run"
        case .sleep:      return "moon.stars.fill"
        case .insights:   return "chart.bar.fill"
        case .profile:    return "person.fill"
        }
    }
}
