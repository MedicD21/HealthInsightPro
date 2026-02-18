import SwiftUI
import Charts

struct SleepView: View {
    @StateObject private var vm = SleepViewModel()
    @EnvironmentObject var authService: AuthService

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        // Sleep Score Hero
                        SleepScoreHero(vm: vm)
                        // Stage Breakdown
                        if let sleep = vm.lastNightSleep {
                            SleepStageCard(sleep: sleep)
                        }
                        // Week chart
                        SleepWeekChart(vm: vm)
                        // Averages
                        SleepAveragesCard(vm: vm)
                        // Log button
                        Button {
                            vm.showLogSleepSheet = true
                        } label: {
                            HStack {
                                Image(systemName: "moon.stars.fill")
                                Text("Log Sleep Manually")
                            }
                            .font(AppFont.headline())
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity).frame(height: 54)
                            .background(AppTheme.gradientYellow)
                            .cornerRadius(16)
                        }
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, Constants.Layout.padding)
                    .padding(.bottom, 100)
                }
                .refreshable { await vm.load(userId: authService.currentUser!.id) }
            }
            .navigationTitle("Sleep")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $vm.showLogSleepSheet) {
                LogSleepSheet(vm: vm)
            }
        }
        .task {
            if let uid = authService.currentUser?.id {
                await vm.load(userId: uid)
            }
        }
    }
}

// MARK: - Hero Score
struct SleepScoreHero: View {
    @ObservedObject var vm: SleepViewModel

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(AppTheme.cardBackground)
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(AppTheme.borderSubtle, lineWidth: 1))

            HStack(spacing: 24) {
                // Score ring
                ZStack {
                    RingProgressView(
                        progress: Double(vm.lastNightSleep?.overallScore ?? 0) / 100.0,
                        lineWidth: 14, size: 120,
                        gradient: AppTheme.gradientYellow,
                        backgroundColor: Color.white.opacity(0.06)
                    )
                    VStack(spacing: 2) {
                        Text("\(vm.lastNightSleep?.overallScore ?? 0)")
                            .font(.system(size: 32, weight: .black, design: .rounded))
                            .foregroundColor(AppTheme.textPrimary)
                        Text(vm.lastNightSleep?.scoreLabel ?? "–")
                            .font(AppFont.caption(.semibold))
                            .foregroundColor(AppTheme.accentYellow)
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Last Night")
                        .font(AppFont.caption(.semibold))
                        .foregroundColor(AppTheme.textSecondary)
                        .tracking(1)
                    if let sleep = vm.lastNightSleep {
                        SleepStat(icon: "moon.zzz.fill", color: AppTheme.accent,
                                  label: "Duration", value: sleep.durationString)
                        SleepStat(icon: "waveform.path.ecg", color: AppTheme.accentPink,
                                  label: "Deep Sleep", value: "\(sleep.deepSleepMinutes)m")
                        SleepStat(icon: "sparkles", color: AppTheme.accentPurple,
                                  label: "REM", value: "\(sleep.remSleepMinutes)m")
                        SleepStat(icon: "bolt.heart.fill", color: AppTheme.accentGreen,
                                  label: "Efficiency", value: "\(Int(sleep.efficiency * 100))%")
                    } else {
                        Text("No sleep data available")
                            .font(AppFont.subheadline())
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
                Spacer()
            }
            .padding(20)
        }
    }
}

struct SleepStat: View {
    var icon: String; var color: Color; var label: String; var value: String
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon).font(.caption).foregroundColor(color)
            Text(label).font(AppFont.caption()).foregroundColor(AppTheme.textSecondary)
            Spacer()
            Text(value).font(AppFont.caption(.bold)).foregroundColor(AppTheme.textPrimary)
        }
    }
}

// MARK: - Stage Breakdown Card
struct SleepStageCard: View {
    var sleep: SleepEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Sleep Stages").font(AppFont.headline(.bold)).foregroundColor(AppTheme.textPrimary)

            // Stage bars
            SleepStagebar(stage: .deepSleep,  minutes: sleep.deepSleepMinutes,  total: sleep.totalDurationMinutes)
            SleepStagebar(stage: .remSleep,   minutes: sleep.remSleepMinutes,   total: sleep.totalDurationMinutes)
            SleepStagebar(stage: .lightSleep, minutes: sleep.lightSleepMinutes, total: sleep.totalDurationMinutes)

            Divider().background(AppTheme.borderSubtle)

            // Legend
            HStack(spacing: 16) {
                ForEach([SleepStage.deepSleep, .remSleep, .lightSleep, .awake], id: \.self) { stage in
                    HStack(spacing: 4) {
                        Circle().fill(Color(hex: stage.color)).frame(width: 8, height: 8)
                        Text(stage.displayName).font(AppFont.caption()).foregroundColor(AppTheme.textSecondary)
                    }
                }
            }
        }
        .padding(Constants.Layout.padding)
        .cardStyle()
    }
}

struct SleepStagebar: View {
    var stage: SleepStage
    var minutes: Int
    var total: Int
    var progress: Double { total > 0 ? Double(minutes) / Double(total) : 0 }

    var body: some View {
        HStack(spacing: 12) {
            Text(stage.displayName)
                .font(AppFont.caption(.semibold))
                .foregroundColor(AppTheme.textSecondary)
                .frame(width: 50, alignment: .leading)
            LinearProgressBar(progress: progress, color: Color(hex: stage.color), height: 10)
            Text(minutes.asMinutes)
                .font(AppFont.caption(.semibold))
                .foregroundColor(Color(hex: stage.color))
                .frame(width: 44, alignment: .trailing)
        }
    }
}

// MARK: - Week Chart
struct SleepWeekChart: View {
    @ObservedObject var vm: SleepViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "7-Day Sleep")

            if vm.sleepEntries.isEmpty {
                Text("No sleep data for this week")
                    .font(AppFont.subheadline())
                    .foregroundColor(AppTheme.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                // Simple bar chart using SwiftUI
                HStack(alignment: .bottom, spacing: 6) {
                    ForEach(vm.sleepEntries.prefix(7).reversed(), id: \.id) { entry in
                        VStack(spacing: 4) {
                            Text("\(Int(entry.totalDurationHours))h")
                                .font(AppFont.caption())
                                .foregroundColor(AppTheme.textTertiary)
                            RoundedRectangle(cornerRadius: 6)
                                .fill(AppTheme.accentYellow.opacity(0.7))
                                .frame(height: CGFloat(entry.totalDurationHours / 12.0) * 80)
                            Text(entry.startTime.dayOfWeek)
                                .font(AppFont.caption())
                                .foregroundColor(AppTheme.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 110)
                .padding(Constants.Layout.padding)
            }
        }
        .cardStyle()
    }
}

// MARK: - Averages Card
struct SleepAveragesCard: View {
    @ObservedObject var vm: SleepViewModel

    var body: some View {
        HStack(spacing: 0) {
            SleepAvgStat(label: "Avg Duration", value: String(format: "%.1fh", vm.avgSleepDuration), color: AppTheme.accentYellow)
            Divider().background(AppTheme.borderSubtle).frame(height: 50)
            SleepAvgStat(label: "Avg Score", value: "\(vm.avgSleepScore)", color: AppTheme.accentGreen)
            Divider().background(AppTheme.borderSubtle).frame(height: 50)
            SleepAvgStat(label: "Nights Logged", value: "\(vm.sleepEntries.count)", color: AppTheme.accent)
        }
        .padding(.vertical, 16)
        .cardStyle()
    }
}

struct SleepAvgStat: View {
    var label: String; var value: String; var color: Color
    var body: some View {
        VStack(spacing: 4) {
            Text(value).font(AppFont.title3(.bold)).foregroundColor(color)
            Text(label).font(AppFont.caption()).foregroundColor(AppTheme.textSecondary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Log Sleep Sheet
struct LogSleepSheet: View {
    @ObservedObject var vm: SleepViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                VStack(spacing: 24) {
                    VStack(spacing: 20) {
                        DatePickerRow(title: "Bedtime", selection: $vm.bedtime)
                        DatePickerRow(title: "Wake Time", selection: $vm.wakeTime)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Sleep Quality")
                                .font(AppFont.subheadline(.semibold))
                                .foregroundColor(AppTheme.textSecondary)
                            HStack {
                                Text("Poor")
                                    .font(AppFont.caption())
                                    .foregroundColor(AppTheme.textTertiary)
                                Slider(value: .init(get: { Double(vm.sleepQuality) }, set: { vm.sleepQuality = Int($0) }),
                                       in: 1...10, step: 1)
                                    .tint(AppTheme.accentYellow)
                                Text("Great")
                                    .font(AppFont.caption())
                                    .foregroundColor(AppTheme.textTertiary)
                            }
                            HStack {
                                Spacer()
                                Text("\(vm.sleepQuality) / 10")
                                    .font(AppFont.headline(.bold))
                                    .foregroundColor(AppTheme.accentYellow)
                                Spacer()
                            }
                        }
                        .padding(Constants.Layout.padding)
                        .cardStyle()
                    }
                    .padding(.horizontal)

                    Spacer()

                    Button {
                        Task { await vm.logSleep() }
                    } label: {
                        Text("Save Sleep").font(AppFont.headline()).foregroundColor(.white)
                            .frame(maxWidth: .infinity).frame(height: 56)
                            .background(AppTheme.gradientYellow).cornerRadius(16)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
                .padding(.top, 20)
            }
            .navigationTitle("Log Sleep")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundColor(AppTheme.accent)
                }
            }
        }
        .presentationDetents([.medium])
        .preferredColorScheme(.dark)
    }
}

struct DatePickerRow: View {
    var title: String
    @Binding var selection: Date

    var body: some View {
        HStack {
            Text(title)
                .font(AppFont.subheadline(.semibold))
                .foregroundColor(AppTheme.textPrimary)
            Spacer()
            DatePicker("", selection: $selection, displayedComponents: .hourAndMinute)
                .datePickerStyle(.compact)
                .colorScheme(.dark)
                .labelsHidden()
        }
        .padding(Constants.Layout.padding)
        .cardStyle()
    }
}
