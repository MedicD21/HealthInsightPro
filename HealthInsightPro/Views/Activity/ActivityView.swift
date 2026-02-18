import SwiftUI

struct ActivityView: View {
    @StateObject private var vm = ActivityViewModel()
    @EnvironmentObject var authService: AuthService

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        // Activity Rings Hero
                        ActivityRingsHero(vm: vm)
                        // Quick stats
                        ActivityQuickStats(vm: vm)
                        // TDEE Breakdown
                        TDEECard(vm: vm)
                        // Heart Rate
                        HeartRateCard(vm: vm)
                        // Workouts list
                        WorkoutsSection(vm: vm)
                    }
                    .padding(.horizontal, Constants.Layout.padding)
                    .padding(.bottom, 100)
                }
                .refreshable { await vm.load(userId: authService.currentUser!.id) }

                // FAB
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        FloatingAddButton(gradient: AppTheme.gradientBlue) {
                            vm.showLogWorkout = true
                        }
                        .padding(.trailing, 24)
                        .padding(.bottom, 90)
                    }
                }
            }
            .navigationTitle("Activity")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $vm.showLogWorkout) {
                LogWorkoutSheet(vm: vm)
            }
        }
        .task {
            if let uid = authService.currentUser?.id {
                await vm.load(userId: uid)
            }
        }
    }
}

// MARK: - Rings Hero
struct ActivityRingsHero: View {
    @ObservedObject var vm: ActivityViewModel

    var stepProgress: Double { (Double(vm.steps) / 10000.0).clamped01 }
    var calProgress: Double { (vm.activeCalories / 600.0).clamped01 }
    var activeProgress: Double { (Double(vm.activeMinutes) / 30.0).clamped01 }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(AppTheme.cardBackground)
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(AppTheme.borderSubtle, lineWidth: 1))

            HStack(spacing: 28) {
                TripleRingView(
                    outerProgress: stepProgress,
                    middleProgress: calProgress,
                    innerProgress: activeProgress,
                    size: 130
                )

                VStack(alignment: .leading, spacing: 14) {
                    ActivityRingStat(color: AppTheme.accentOrange, label: "Steps",
                                    value: vm.steps.asSteps, goal: "10k goal")
                    ActivityRingStat(color: AppTheme.accentGreen, label: "Active Cal",
                                    value: "\(Int(vm.activeCalories))", goal: "600 goal")
                    ActivityRingStat(color: AppTheme.accentBlue, label: "Exercise Min",
                                    value: "\(vm.activeMinutes)m", goal: "30m goal")
                }
                Spacer()
            }
            .padding(20)
        }
    }
}

struct ActivityRingStat: View {
    var color: Color; var label: String; var value: String; var goal: String
    var body: some View {
        HStack(spacing: 8) {
            Circle().fill(color).frame(width: 10, height: 10)
            VStack(alignment: .leading, spacing: 1) {
                Text(label).font(AppFont.caption()).foregroundColor(AppTheme.textSecondary)
                Text(value).font(AppFont.headline(.bold)).foregroundColor(AppTheme.textPrimary)
            }
            Spacer()
            Text(goal).font(AppFont.caption()).foregroundColor(AppTheme.textTertiary)
        }
    }
}

// MARK: - Quick Stats
struct ActivityQuickStats: View {
    @ObservedObject var vm: ActivityViewModel
    let cols = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        LazyVGrid(columns: cols, spacing: 12) {
            ActivityStatCard(icon: "figure.walk", color: AppTheme.accentBlue,
                             label: "Steps", value: vm.steps.asSteps)
            ActivityStatCard(icon: "location.fill", color: AppTheme.accentGreen,
                             label: "Distance",
                             value: vm.distanceKm > 0 ? String(format: "%.2f mi", ImperialUnits.kmToMiles(vm.distanceKm)) : "-- mi")
            ActivityStatCard(icon: "flame.fill", color: AppTheme.accentOrange,
                             label: "Active Cal", value: "\(Int(vm.activeCalories))")
            ActivityStatCard(icon: "timer", color: AppTheme.accent,
                             label: "Active Min", value: "\(vm.activeMinutes)m")
            ActivityStatCard(icon: "heart.fill", color: AppTheme.accentPink,
                             label: "Heart Rate",
                             value: vm.heartRate.map { "\(Int($0)) bpm" } ?? "-- bpm")
            ActivityStatCard(icon: "waveform.path.ecg", color: AppTheme.accentTeal,
                             label: "HRV",
                             value: vm.hrv.map { "\(Int($0)) ms" } ?? "-- ms")
        }
    }
}

struct ActivityStatCard: View {
    var icon: String; var color: Color; var label: String; var value: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(color)
            Text(value)
                .font(AppFont.headline(.bold))
                .foregroundColor(AppTheme.textPrimary)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(AppFont.caption())
                .foregroundColor(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .cardStyle()
    }
}

// MARK: - TDEE Card
struct TDEECard: View {
    @ObservedObject var vm: ActivityViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Energy Breakdown (TDEE)")

            if let tdee = vm.tdeeBreakdown {
                VStack(spacing: 10) {
                    TDEERow(label: "Basal (BMR)", value: tdee.bmr, color: AppTheme.accent, total: tdee.total)
                    TDEERow(label: "NEAT (Activity)", value: tdee.neat, color: AppTheme.accentBlue, total: tdee.total)
                    TDEERow(label: "Thermic Effect (TEF)", value: tdee.tef, color: AppTheme.accentGreen, total: tdee.total)
                    TDEERow(label: "Exercise (EAT)", value: tdee.eat, color: AppTheme.accentOrange, total: tdee.total)
                    Divider().background(AppTheme.borderSubtle)
                    HStack {
                        Text("Total TDEE")
                            .font(AppFont.headline(.bold))
                            .foregroundColor(AppTheme.textPrimary)
                        Spacer()
                        Text("\(Int(tdee.total)) kcal")
                            .font(AppFont.headline(.bold))
                            .foregroundColor(AppTheme.accentOrange)
                    }
                }
            } else {
                Text("Loading energy data...")
                    .font(AppFont.subheadline())
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
        .padding(Constants.Layout.padding)
        .cardStyle()
    }
}

struct TDEERow: View {
    var label: String; var value: Double; var color: Color; var total: Double

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                HStack(spacing: 6) {
                    Circle().fill(color).frame(width: 8, height: 8)
                    Text(label).font(AppFont.subheadline()).foregroundColor(AppTheme.textSecondary)
                }
                Spacer()
                Text("\(Int(value)) kcal").font(AppFont.subheadline(.semibold)).foregroundColor(AppTheme.textPrimary)
            }
            LinearProgressBar(progress: total > 0 ? value / total : 0, color: color, height: 5)
        }
    }
}

// MARK: - Heart Rate Card
struct HeartRateCard: View {
    @ObservedObject var vm: ActivityViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Heart Health")
            HStack(spacing: 0) {
                HeartStatItem(icon: "heart.fill", color: AppTheme.accentPink,
                              label: "Resting HR",
                              value: vm.heartRate.map { "\(Int($0))" } ?? "--",
                              unit: "bpm")
                Divider().background(AppTheme.borderSubtle).frame(height: 50)
                HeartStatItem(icon: "waveform.path.ecg", color: AppTheme.accentTeal,
                              label: "HRV",
                              value: vm.hrv.map { "\(Int($0))" } ?? "--",
                              unit: "ms")
                Divider().background(AppTheme.borderSubtle).frame(height: 50)
                HeartStatItem(icon: "lungs.fill", color: AppTheme.accentBlue,
                              label: "VO2 Max",
                              value: vm.vo2max.map { String(format: "%.1f", $0 / 2.2046226218) } ?? "--",
                              unit: "ml/lb")
            }
        }
        .padding(Constants.Layout.padding)
        .cardStyle()
    }
}

struct HeartStatItem: View {
    var icon: String; var color: Color; var label: String; var value: String; var unit: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 20)).foregroundColor(color)
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value).font(AppFont.title3(.bold)).foregroundColor(AppTheme.textPrimary)
                Text(unit).font(AppFont.caption()).foregroundColor(AppTheme.textSecondary)
            }
            Text(label).font(AppFont.caption()).foregroundColor(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Workouts Section
struct WorkoutsSection: View {
    @ObservedObject var vm: ActivityViewModel

    var body: some View {
        VStack(spacing: 12) {
            SectionHeader(title: "Recent Workouts")
            if vm.workouts.isEmpty {
                EmptyStateView(icon: "figure.run", title: "No workouts yet",
                               message: "Log a workout to see it here",
                               buttonTitle: "Log Workout") { vm.showLogWorkout = true }
            } else {
                VStack(spacing: 0) {
                    ForEach(vm.workouts.prefix(5)) { workout in
                        WorkoutRow(workout: workout)
                        Divider().background(AppTheme.borderSubtle)
                    }
                }
                .cardStyle()
            }
        }
    }
}

struct WorkoutRow: View {
    var workout: ActivityEntry

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(AppTheme.accentBlue.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: workout.activityType.icon)
                    .font(.system(size: 20))
                    .foregroundColor(AppTheme.accentBlue)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(workout.activityType.displayName)
                    .font(AppFont.subheadline(.semibold))
                    .foregroundColor(AppTheme.textPrimary)
                HStack(spacing: 8) {
                    Text(workout.startTime.shortDate).font(AppFont.caption()).foregroundColor(AppTheme.textSecondary)
                    Text("·")
                    Text("\(Int(workout.durationMinutes))m").font(AppFont.caption()).foregroundColor(AppTheme.textSecondary)
                    if let dist = workout.distanceString {
                        Text("·"); Text(dist).font(AppFont.caption()).foregroundColor(AppTheme.textSecondary)
                    }
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(workout.caloriesBurned))")
                    .font(AppFont.subheadline(.bold)).foregroundColor(AppTheme.accentOrange)
                Text("kcal").font(AppFont.caption()).foregroundColor(AppTheme.textSecondary)
            }
        }
        .padding(.horizontal, Constants.Layout.padding)
        .padding(.vertical, 10)
    }
}

// MARK: - Log Workout Sheet
struct LogWorkoutSheet: View {
    @ObservedObject var vm: ActivityViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        // Activity type picker
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Activity Type").font(AppFont.headline(.bold)).foregroundColor(AppTheme.textPrimary)
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                ForEach(ActivityType.allCases.prefix(12), id: \.self) { type in
                                    ActivityTypeCell(type: type, isSelected: vm.selectedActivityType == type) {
                                        vm.selectedActivityType = type
                                    }
                                }
                            }
                        }
                        .padding(Constants.Layout.padding)
                        .cardStyle()

                        // Duration
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("Duration").font(AppFont.subheadline(.semibold)).foregroundColor(AppTheme.textSecondary)
                                Spacer()
                                Text("\(Int(vm.workoutDurationMinutes)) min")
                                    .font(AppFont.headline(.bold)).foregroundColor(AppTheme.accentBlue)
                            }
                            Slider(value: $vm.workoutDurationMinutes, in: 5...180, step: 5)
                                .tint(AppTheme.accentBlue)
                        }
                        .padding(Constants.Layout.padding)
                        .cardStyle()

                        // Notes
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes").font(AppFont.subheadline(.semibold)).foregroundColor(AppTheme.textSecondary)
                            TextField("Optional notes...", text: $vm.workoutNotes, axis: .vertical)
                                .foregroundColor(AppTheme.textPrimary)
                                .font(AppFont.body())
                                .lineLimit(3...6)
                        }
                        .padding(Constants.Layout.padding)
                        .cardStyle()

                        Button {
                            Task { await vm.logWorkout() }
                            dismiss()
                        } label: {
                            Text("Log Workout").font(AppFont.headline()).foregroundColor(.white)
                                .frame(maxWidth: .infinity).frame(height: 56)
                                .background(AppTheme.gradientBlue).cornerRadius(16)
                        }
                        .padding(.bottom, 30)
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                }
            }
            .navigationTitle("Log Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundColor(AppTheme.accent)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct ActivityTypeCell: View {
    var type: ActivityType; var isSelected: Bool; var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: type.icon)
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? .white : AppTheme.textSecondary)
                Text(type.displayName)
                    .font(AppFont.caption(.semibold))
                    .foregroundColor(isSelected ? .white : AppTheme.textSecondary)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(AppTheme.cardBackgroundAlt)
            .cornerRadius(12)
            .overlay(
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppTheme.gradientBlue)
                    }
                }
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}
