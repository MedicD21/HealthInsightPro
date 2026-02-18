# Health Insight Pro

A comprehensive iOS health tracking app inspired by Bright OS, built with SwiftUI, Apple Sign In, HealthKit, and Supabase.

---

## Features

| Feature | Details |
|---|---|
| **Apple Sign In** | Secure, privacy-first authentication |
| **Onboarding** | 6-step personalized setup (goals, metrics, activity level, permissions) |
| **Dashboard** | Calorie ring, macros, insight scores, sleep & step summary |
| **Nutrition** | Meal logging, food search (300K+ items), barcode scan, image scan, recipes, meal plans |
| **Activity** | Steps, workouts, TDEE breakdown (BMR/NEAT/TEF/EAT), heart rate zones, VO2 max |
| **Sleep** | Sleep score (0-100), stage breakdown (Deep/REM/Light/Awake), 7-day trends |
| **Hydration** | Water tracking with quick-add presets and daily goal progress |
| **Weight** | Weight history chart, goal progress, BMI tracking |
| **Insights** | Recovery, Strain, Stress, Readiness scores — all computed from your data |
| **Journal** | Mood, energy, habits (meditation, alcohol, medication, sunlight), gratitude |
| **Profile** | Edit goals, view stats, Apple Health settings |
| **HealthKit** | Auto-syncs steps, calories, sleep, heart rate, weight, distance |
| **Supabase** | Real-time cloud sync with Row Level Security |

---

## Setup

### 1. Supabase
1. Create a project at [supabase.com](https://supabase.com)
2. Run `supabase_schema.sql` in the SQL Editor
3. Enable **Apple** as an Auth provider (Dashboard → Authentication → Providers)
4. Copy your **Project URL** and **anon key**

### 2. Configure the app
Open `HealthInsightPro/Utilities/Constants.swift` and replace:
```swift
static let url     = "YOUR_SUPABASE_URL"        // e.g. https://xxxx.supabase.co
static let anonKey = "YOUR_SUPABASE_ANON_KEY"   // your project anon key
```

### 3. Xcode Setup
1. Open `HealthInsightPro.xcodeproj` in Xcode 15+
2. Set your **Team** in Signing & Capabilities
3. Change the **Bundle ID** to your own (e.g. `com.yourname.healthinsightpro`)
4. Add these capabilities in Xcode:
   - **Sign In with Apple**
   - **HealthKit** (with Background Delivery)
   - **Push Notifications** (optional)
5. Let Xcode resolve the Supabase Swift Package (it fetches automatically)
6. Build and run on device (HealthKit requires a real device)

---

## Architecture

```
HealthInsightPro/
├── HealthInsightProApp.swift      # App entry, routing (Sign In → Onboarding → Main)
├── Utilities/
│   ├── Theme.swift                # Colors, gradients, fonts, tab enum
│   ├── Extensions.swift           # Color(hex:), View modifiers, Date helpers
│   └── Constants.swift            # Supabase config, goals, activity levels, health goals
├── Models/
│   ├── UserProfile.swift          # User + computed BMR/TDEE/BMI
│   ├── Nutrition.swift            # Macros, FoodItem, MealEntry, Recipe, MealPlan
│   ├── Sleep.swift                # SleepEntry, SleepStageSegment, SleepHabit
│   ├── Activity.swift             # ActivityEntry, DailyActivity, TDEE, HeartRate
│   └── HealthMetrics.swift        # WaterEntry, WeightEntry, InsightScores, JournalEntry
├── Services/
│   ├── SupabaseService.swift      # All DB operations (CRUD for every model)
│   ├── AuthService.swift          # Apple Sign In + Supabase Auth + session management
│   └── HealthKitService.swift     # Read steps/calories/sleep/HR/weight, write weight
├── ViewModels/                    # @MainActor ObservableObjects, async data loading
├── Views/
│   ├── Auth/SignInView.swift      # Sign in screen with Apple button + feature highlights
│   ├── Onboarding/                # 6-step onboarding flow
│   ├── Dashboard/DashboardView.swift  # Tab container + home screen
│   ├── Nutrition/NutritionView.swift  # Meal log, search, barcode, recipes
│   ├── Sleep/SleepView.swift      # Sleep score, stages, weekly chart
│   ├── Activity/ActivityView.swift    # Activity rings, TDEE, workouts, heart
│   ├── Water/WaterView.swift      # Hydration progress + quick-add
│   ├── Weight/WeightView.swift    # Weight chart + logging
│   ├── Insights/InsightsView.swift    # Recovery/Strain/Stress/Readiness
│   ├── Journal/JournalView.swift  # Mood, habits, notes, gratitude
│   ├── Profile/ProfileView.swift  # Stats, goals, settings, sign out
│   └── Components/                # Rings, progress bars, cards, metric views
```

---

## Design System

- **Dark theme** — near-black `#0A0A0F` background
- **Card backgrounds** — `#1A1A26` with subtle `#2A2A40` borders
- **Accent colors:**
  - Purple `#6C63FF` — primary brand
  - Neon green `#00E5A0` — nutrition
  - Blue `#3B9EFF` — activity/water
  - Orange `#FF7A3B` — calories/energy
  - Pink `#FF4F8B` — heart rate
  - Yellow `#FFD23F` — sleep
  - Teal `#00D4CC` — recovery/insights
- **Rounded system font** for all typography
- **Animated rings, progress bars, and pulse effects** throughout

---

## Customizing Goals

All goals can be tweaked in `Constants.swift`:
```swift
enum Defaults {
    static let calorieGoal: Double = 2000
    static let waterGoal: Double   = 2500   // ml
    static let stepGoal: Int       = 10000
    static let sleepGoal: Double   = 8.0    // hours
    static let proteinGoal: Double = 150    // g
    static let carbGoal: Double    = 250    // g
    static let fatGoal: Double     = 65     // g
}
```

---

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+
- Real device for HealthKit
- Supabase project (free tier works)

---

## Sources Referenced
- [Bright OS App Store](https://apps.apple.com/us/app/bright-os-all-in-one-health/id6466817237)
- [Bright OS Product Hunt](https://www.producthunt.com/products/bright-4)
- [Bright OS - Hunt Screens](https://huntscreens.com/en/products/bright-os)
