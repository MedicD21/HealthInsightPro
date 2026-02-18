import SwiftUI
import Foundation

// MARK: - Color from Hex
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - View modifiers
extension View {
    func cardStyle() -> some View {
        self
            .background(AppTheme.cardBackground)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppTheme.borderSubtle, lineWidth: 1)
            )
    }

    func glassCard() -> some View {
        self
            .background(.ultraThinMaterial)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppTheme.borderSubtle, lineWidth: 1)
            )
    }

    func gradientCard(_ gradient: LinearGradient) -> some View {
        self
            .background(gradient)
            .cornerRadius(16)
    }

    func sectionHeader() -> some View {
        self
            .font(AppFont.headline())
            .foregroundColor(AppTheme.textPrimary)
    }
}

// MARK: - Double helpers
extension Double {
    var formatted0: String { String(format: "%.0f", self) }
    var formatted1: String { String(format: "%.1f", self) }
    var formatted2: String { String(format: "%.2f", self) }
    var asCalories: String { "\(Int(self)) kcal" }
    var asGrams: String { "\(Int(self))g" }
    var asKg: String { String(format: "%.1f kg", self) }
    var asLbs: String { String(format: "%.1f lbs", self) }
    var asML: String { "\(Int(self)) ml" }
}

extension Int {
    var asCalories: String { "\(self) kcal" }
    var asMinutes: String {
        let h = self / 60; let m = self % 60
        return h > 0 ? "\(h)h \(m)m" : "\(m)m"
    }
    var asSteps: String {
        if self >= 1000 {
            return String(format: "%.1fk", Double(self) / 1000)
        }
        return "\(self)"
    }
}

// MARK: - Date helpers
extension Date {
    var startOfDay: Date { Calendar.current.startOfDay(for: self) }
    var endOfDay: Date {
        var comps = DateComponents(); comps.day = 1; comps.second = -1
        return Calendar.current.date(byAdding: comps, to: startOfDay) ?? self
    }
    var dayOfWeek: String {
        let f = DateFormatter(); f.dateFormat = "EEE"; return f.string(from: self)
    }
    var shortDate: String {
        let f = DateFormatter(); f.dateFormat = "MMM d"; return f.string(from: self)
    }
    var timeString: String {
        let f = DateFormatter(); f.timeStyle = .short; return f.string(from: self)
    }
    var iso8601: String {
        ISO8601DateFormatter().string(from: self)
    }
    static func from(iso8601 string: String) -> Date? {
        ISO8601DateFormatter().date(from: string)
    }

    func daysAgo(_ n: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -n, to: self) ?? self
    }
}

// MARK: - Progress clamp
extension CGFloat {
    var clamped01: CGFloat { Swift.min(1, Swift.max(0, self)) }
}
extension Double {
    var clamped01: Double { min(1.0, max(0.0, self)) }
    func clamped(min minVal: Double, max maxVal: Double) -> Double {
        Swift.min(maxVal, Swift.max(minVal, self))
    }
}

// MARK: - Imperial conversion helpers
enum ImperialUnits {
    private static let lbsPerKg = 2.2046226218
    private static let cmPerInch = 2.54
    private static let mlPerFluidOunce = 29.5735295625
    private static let milesPerKm = 0.6213711922
    private static let feetPerKm = 3280.839895

    static func kgToLbs(_ kg: Double) -> Double {
        kg * lbsPerKg
    }

    static func lbsToKg(_ lbs: Double) -> Double {
        lbs / lbsPerKg
    }

    static func cmToInches(_ cm: Double) -> Double {
        cm / cmPerInch
    }

    static func inchesToCm(_ inches: Double) -> Double {
        inches * cmPerInch
    }

    static func cmToFeetAndInchesString(_ cm: Double) -> String {
        feetAndInchesString(fromInches: cmToInches(cm))
    }

    static func feetAndInchesString(fromInches inches: Double) -> String {
        let roundedInches = max(0, Int(round(inches)))
        let feet = roundedInches / 12
        let remainderInches = roundedInches % 12
        return "\(feet)'\(remainderInches)\""
    }

    static func kmToMiles(_ km: Double) -> Double {
        km * milesPerKm
    }

    static func kmToFeet(_ km: Double) -> Double {
        km * feetPerKm
    }

    static func mlToFluidOunces(_ ml: Double) -> Double {
        ml / mlPerFluidOunce
    }

    static func fluidOuncesToMl(_ fluidOunces: Double) -> Double {
        fluidOunces * mlPerFluidOunce
    }
}

// MARK: - Haptic helpers
struct HapticFeedback {
    static func light()   { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
    static func medium()  { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
    static func heavy()   { UIImpactFeedbackGenerator(style: .heavy).impactOccurred() }
    static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    static func warning() { UINotificationFeedbackGenerator().notificationOccurred(.warning) }
    static func error()   { UINotificationFeedbackGenerator().notificationOccurred(.error) }
    static func selection() { UISelectionFeedbackGenerator().selectionChanged() }
}
