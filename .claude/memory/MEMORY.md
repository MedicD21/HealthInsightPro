# Health Insight Pro - Project Memory

## Project Overview
- Native Swift iOS app (Health Insight Pro), clone of Bright OS health tracker
- Location: `c:\Users\DScha\OneDrive\Desktop\HealthInsightPro`
- Target: iOS 17+, SwiftUI, MVVM architecture

## Key Files
- Entry point: `HealthInsightPro/HealthInsightProApp.swift`
- Theme/colors: `HealthInsightPro/Utilities/Theme.swift`
- Supabase config: `HealthInsightPro/Utilities/Constants.swift` (URL + anonKey)
- DB schema: `supabase_schema.sql`

## Tech Stack
- SwiftUI + @MainActor ViewModels
- Apple Sign In (ASAuthorizationAppleIDCredential)
- HealthKit (steps, sleep, HR, calories, weight)
- Supabase Swift SDK v2.x (supabase-swift package)
- CryptoKit (SHA256 nonce for Apple Sign In)

## Design System
- Dark theme: `#0A0A0F` bg, `#1A1A26` cards
- Primary accent: `#6C63FF` purple
- Nutrition: `#00E5A0` green | Activity: `#3B9EFF` blue
- Sleep: `#FFD23F` yellow | Heart: `#FF4F8B` pink
- Rounded system font for all typography

## Architecture: AppRootView routing
1. Not authenticated → SignInView (Apple Sign In)
2. Authenticated + onboarding incomplete → OnboardingView (6 steps)
3. Authenticated + onboarding done → DashboardView (tab bar)

## User Preferences
- User wants to tweak the clone later — keep code clean and modular
- No auto-commits requested
